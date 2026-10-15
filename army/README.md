# Army demonstrations: decisions as programs, Kai inside DDT's gates

Two ground-vehicle decisions for Army SBIR ARM26BX06-NV012 / STTR ARM26TX06-NV003, each a
Decision Program run end to end with Kai answering live over `POST /v1/decisions`. Every Kai
probability below is production kai-1.3's (weights `0834a74f…`, calibration
`cal_e23c27a1f768bff7`), recorded 2026-10-15 against `kai serve` on CPU with no network, and
reproduced the same day on api.hanzo.ai (`run.py`).

| | `jltv/` | `apu/` |
|---|---|---|
| Decision | JLTV powertrain: fielded diesel or eJLTV hybrid | Auxiliary power: integrated APU, battery pack or trailer genset |
| Evidence | `ltv.sysml`, a SysML v2 model whose every figure cites a public source (W1–C2 in its header) | DDT decision `DEC-SPH-0412`: charter, sealed thermal Evaluation Run, service bulletin, PLM BOM, DDT readiness verdict (values constructed) |
| Shows | SysML v2 elements as evidence; Kai reads each option's own status; break-evens; a recorded human hold | DDT's gate as the base verdict; constraints; break-evens; refresh that reruns only what a change reaches |

Each directory holds the program (`*@1.json`), `evidence.json`, the recorded run
(`recorded.json`: every node's output, Kai's full distributions, ranking, flips, gate rulings,
bias findings, revisions, the replay manifest and the package's SHA-256), and for `apu` the
changes it refreshes on (`changes/`), the `/v1/decisions` body of its program-scope questions
(`request.json`), the DDT Decision record the program is bound from (`ddt.json`) and the DDT
records a run files (`ddt.export.json`: one Evaluation Run with its input and output hashes, the
readiness ruling and bias findings, the Evidence read, Action drafts; never a Commitment).

## jltv: SysML v2 trade

| Kai question | diesel | hybrid |
|---|---|---|
| Fielded and in production, rather than a demonstrator? (each option reads its own status elements: `LTV::Diesel`; `LTV::Hybrid`, `LTV::maturity`) | P .734 | P .264 |

Selection: diesel, utility .60 against .40. It flips to the hybrid when the fuel-economy or the
field-capability weight rises from .20 to .40. Anchoring check on the decision brief: P .336,
not raised. The program manager's recorded hold: "the fuel gain is a company figure (O2); ask
for duty-cycle data." The brief and the hold are recorded examples, not model output.

## apu: readiness gate and refresh

| Run | DDT gate | Result | Kai | Steps run |
|---|---|---|---|---|
| Complete evidence | allow | A2 battery .640 > A3 genset .473 > A1 APU .147 | missing evidence .005, conflict .069, anchoring .121 | 10 of 10, 1.47 s |
| A2's thermal run withheld | deny | stopped; A2 fails qualification, A3 .875 leads | missing evidence .005 | 6 of 10, 1.30 s |
| Bulletin TSB-22 rev B: A2 end-of-life endurance 8.1 → 7.1 h, repair 3 → 6 h | allow | A3 .875; A2 fails the 8 h constraint | conflict .055 | 7 of 10, 1.40 s |

Break-evens in the first run: A2 holds until the silent-watch weight passes .284 (set .15), the
maintenance-burden weight falls below .205 (.35), the cost weight passes .505 (.20), or A2's
end-of-life endurance falls below 8.0 h, which the bulletin delivers. DDT's deterministic gate
and the program's constraints carried both changes; Kai's missing-evidence and conflict checks
stayed under their thresholds, the measured target of the Phase I evidence-reading work.

## Run

```bash
HANZO_API_KEY=... python3 army/run.py jltv
HANZO_API_KEY=... python3 army/run.py apu
```

`run.py` asks each Kai question of the program the way the runtime does (an option-scope
question once per option, reading that option's own evidence) and prints the answer beside the
recorded one.
