"""Validate and install item art; never alters source pixels. Run --help for usage."""
import argparse,json,re,shutil,xml.etree.ElementTree as ET
from pathlib import Path
from PIL import Image

def install(source,art_id,variant,destination,replace=False):
    if any(not re.fullmatch(r'[A-Za-z0-9_-]{1,96}',x) for x in (art_id,variant)):
        raise ValueError('IDs must use letters, digits, underscore or hyphen')
    source=Path(source); ext=source.suffix.lower()
    if ext not in ('.png','.webp','.svg') or source.stat().st_size>4*1024*1024:
        raise ValueError('Use PNG, WebP or SVG up to 4 MiB')
    if ext=='.svg':
        raw=source.read_text()
        if '<!DOCTYPE' in raw or '<!ENTITY' in raw:raise ValueError('External XML declarations are unsupported')
        root=ET.fromstring(raw)
        bounds=root.get('viewBox','').replace(',',' ').split()
        dimensions=[float(x) for x in bounds[2:]] if len(bounds)==4 else []
        for attr in ('width','height'):
            value=root.get(attr,'')
            if value and not value.endswith('%'):dimensions.append(float(value.removesuffix('px')))
        if not dimensions or any(not 0<x<=1024 for x in dimensions):raise ValueError('SVG bounds must be positive and at most 1024')
        for node in root.iter():
            if node.tag.split('}')[-1] in ('script','foreignObject','image','style'):raise ValueError('SVG must be self-contained vector art')
            for key,value in node.attrib.items():
                if key.startswith('on') or key.endswith('href') and not value.startswith('#'):raise ValueError('External SVG reference')
                if 'url(' in value and not re.fullmatch(r'url\(#[A-Za-z0-9_-]+\)',value):raise ValueError('External SVG URL')
    else:
        with Image.open(source) as img:
            if max(img.size)>1024 or min(img.size)<16:raise ValueError('Art dimensions must be between 16 and 1024 px')
            img.verify()
    destination=Path(destination);destination.mkdir(parents=True,exist_ok=True)
    manifest_path=destination/'manifest.json'
    data=json.loads(manifest_path.read_text()) if manifest_path.exists() else {'version':1,'items':{}}
    filename=f'{art_id}_{variant}{ext}';target=destination/filename
    if (variant in data['items'].get(art_id,{}) or target.exists()) and not replace:raise ValueError('Art already exists; use --replace after reviewing it')
    shutil.copyfile(source,target)
    data['items'].setdefault(art_id,{})[variant]=filename
    temporary=manifest_path.with_suffix('.tmp');temporary.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n');temporary.replace(manifest_path)
    return target

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source');parser.add_argument('art_id');parser.add_argument('--variant',default='default')
    parser.add_argument('--destination',default=str(Path(__file__).resolve().parents[1]/'assets/items'))
    parser.add_argument('--replace',action='store_true')
    args=parser.parse_args()
    print(install(args.source,args.art_id,args.variant,args.destination,args.replace))
