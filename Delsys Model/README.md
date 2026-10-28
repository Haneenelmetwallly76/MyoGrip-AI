# Prosthetic Decoder Bundle
Input: raw EMG chunk (n,12) @2000Hz — أو أي جهاز عبر feed(chunk, src_fs, src_ch).
Pipeline: adapter -> 4-band envelope -> mu-law -> per-patient scaler -> student (adapted) -> SLDA probs -> MC confidence -> causal vote K=7.
Output dict: {class, name, conf, kin[22], force[6], smoothed, action}.
الأرقام المثبتة: raw 63.02 | few-shot 79.67 | full-stack 81.38 | safe-mode 84.81@43.6% | latency worst 297.97ms.
مريض جديد: شغّل src/adapt.py few_shot_arrays على نوافذ المعايرة، بعدين احفظ profile (scaler+SLDA+protos+weights).
