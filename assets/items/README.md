# Item art pipeline

Equipment UI resolves artwork from each item's `art_id`.

Place one of these files here:

- `<art_id>.png`
- `<art_id>.webp`
- `<art_id>.svg`

The same asset is reused by Inventory, item detail, Vault, and Forge. If no matching file exists, the UI uses the shared reliquary placeholder.

Generated IDs are stable by equipment family/grade, while Legendary/Mythic items use `legend_<effect>`. The item schema also carries `art_variant` for future alternate treatments without changing save identity.
