# QArcade Open-Core License Strategy

Status: proposed architecture subject to legal and ownership review.

## 1. Proposed structure

QArcade should use explicit directory-level licensing rather than a single
repository-wide license:

| Layer | Intended treatment |
|---|---|
| Qilin reusable engine, runtime integration, developer tools, tests, and infrastructure | Apache License 2.0 |
| Clearly separable open educational documentation and demos | Apache-2.0 for software; optionally CC BY 4.0 or CC BY-SA 4.0 for non-code content after review |
| Official games, levels, missions, curriculum, artwork, audio, and premium experiences | Reserved/proprietary or separately licensed |
| Hardware designs and manufacturing materials | Reserved initially; later choose a hardware-specific license per artifact |
| Names, logos, trade dress, and official-product identity | Reserved trademark/brand rights |
| Third-party components | Their original licenses, notices, and attribution requirements |

The root `LICENSE` is a map. It does not grant rights in every repository file.
`LICENSE-CODE` contains Apache-2.0; `LICENSE-CONTENT` and `LICENSE-HARDWARE`
record that those categories are currently reserved. The nearest
`LICENSE_SCOPE.md` provides controlling directory guidance, while a specific
file license takes precedence.

## 2. Initial ownership model

The first open-core release uses an allowlist:

- QArcade accepts and maintains reusable framework contributions in approved
  Apache-2.0 paths.
- Contributors retain copyright and submit qualifying code contributions
  under Apache-2.0 section 5 unless separately agreed.
- Game/content and hardware contributions require advance agreement on
  ownership and license; merely opening a pull request does not place them in
  the code license.
- Third-party code is never presented as QArcade-owned merely because it is
  stored inside an Apache-scoped directory.
- Historical student/team game work remains outside the new license scope
  until every relevant right is documented.

## 3. Component decisions

### Apache-2.0

Use for Qilin framework code, preview/build/release tools, tests, bootstrap
scripts, CI configuration, and tightly coupled technical documentation.

Benefits include commercial usability, an explicit patent grant, contributor
terms, and compatibility with upstream Apache-2.0 MicroQiskit. Costs include
notice/modification obligations and the need to maintain a precise content
boundary inside mixed cartridges.

### Creative Commons

After review, use CC BY 4.0 when broad reuse of standalone tutorials,
curriculum, diagrams, or media is desired with attribution. Consider CC BY-SA
4.0 when adaptations should remain similarly licensed. Do not use a Creative
Commons license for software or hardware designs merely for convenience.

Trade-off: CC BY maximizes educational reuse, while CC BY-SA can preserve a
commons but complicates combination with differently licensed curricula.
Neither protects commercial differentiation as strongly as reserved content.

### Proprietary/reserved content

Use for official games, premium curriculum, levels, missions, art, audio,
commercial bundles, and other differentiating experiences unless a specific
release is deliberately designated as an open demo.

Trade-off: reservation protects product differentiation but reduces community
remixing and requires a clear contributor agreement before accepting outside
content.

### Hardware

Keep current hardware documents reserved until the project distinguishes:

- tutorial/documentation copyright;
- enclosure/CAD design rights;
- PCB and schematic rights;
- BOM facts and third-party part documentation;
- manufacturing know-how;
- safety and regulatory representations; and
- QArcade brand/trade-dress rights.

Then evaluate CERN-OHL, Solderpad, another hardware license, or proprietary
terms per artifact. An open design license can grow the maker ecosystem;
reserved manufacturing files can support commercial differentiation. Either
choice needs warranty, safety, and official-brand disclaimers.

## 4. Historical games

For the initial phase, exclude these directories from the root Apache-2.0
scope:

```text
1Quescape_wsLu/
2QPong_FetainerTW/
4QTower_LeoYuchaoWilly/
5QShooter_wsLu/
```

Also reserve standalone examples until reviewed. Exclusion does not override
existing licenses: the qShooter MIT license remains effective for material it
actually covers, and all third-party grants remain intact.

When a game is reviewed, record its authors, source history, third-party
assets, exact code/content split, and chosen license. It may then become an
open demo, remain proprietary, or use split code/content terms.

## 5. Release model

Maintain the historical repository for provenance, but publish audience-
appropriate packages:

1. **Engine SDK:** only verified Apache-2.0 framework paths, license, NOTICE,
   and necessary technical documentation.
2. **Open demo:** Engine SDK plus a deliberately licensed example with clear
   code/content markings.
3. **Official product:** engine plus separately licensed official games,
   curriculum, hardware materials, and brand assets under commercial terms.

For a university course, distribute the Engine SDK or an open-demo package
rather than presenting the entire mixed repository as open source.

## 6. Expansion gates

Do not add a directory to an open license scope until:

- all contributors and copyright owners are identified;
- third-party sources and versions are recorded;
- required notices are present;
- code, content, hardware, and brand boundaries are stated;
- the chosen license is compatible with embedded material; and
- a maintainer has approved the corresponding `LICENSE_SCOPE.md` change.

Formal contributor agreements, trademark guidelines, commercial content
terms, and hardware terms remain future legal work.
