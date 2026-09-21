"""Original deterministic mono PCM music for Cathedral Reborn. No samples/providers.

Run from the repository root. Tracks share a D minor palette with the cathedral,
with different rhythmic density for elites, the awakened boss and victory.
"""
from array import array
from math import sin, pi, exp, tanh
from pathlib import Path
import random
import wave

RATE = 16000


def make_track(name, bpm, notes, intensity):
    beat = 60 / bpm
    duration = beat * 32
    buffer = [0.0] * int(RATE * duration)
    rng = random.Random(281)
    for step in range(64):
        start = step * beat / 2
        note = notes[(step // 8) % len(notes)]
        freq = 440 * 2 ** ((note - 69) / 12)
        for j in range(int(RATE * beat * 1.8)):
            t = j / RATE
            phase = 2 * pi * freq * t
            tone = (sin(phase) + .25 * sin(phase * 2.003)) * exp(-t * 4) * min(1, t * 65)
            drum = 0.0
            if step % 4 == 0:
                drum = sin(2 * pi * (57 * t + 10 * (1 - exp(-t * 30)))) * exp(-t * 15) * .42
            elif intensity > .5:
                drum = rng.uniform(-1, 1) * exp(-t * 65) * .12
            value = tone * (.22 if step % 2 == 0 else .12) + drum * intensity
            buffer[(int(start * RATE) + j) % len(buffer)] += value
    pcm = array('h', (int(tanh(x) * 23000) for x in buffer))
    path = Path('assets/audio') / (name + '.wav')
    with wave.open(str(path), 'wb') as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(RATE)
        out.writeframes(pcm.tobytes())
    print(path, len(pcm) / RATE)


if __name__ == '__main__':
    make_track('elite_music', 104, [50, 53, 48, 45], .7)
    make_track('boss_awakened', 132, [38, 41, 44, 45], 1.0)
    make_track('victory_music', 84, [62, 65, 69, 74], .15)
