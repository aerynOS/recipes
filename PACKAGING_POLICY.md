<!--
# SPDX-FileCopyrightText: 2026 aerynOS Developers
# SPDX-License-Identifier: MPL-2.0
-->

# aerynOS Package Addition Policy

| Field | Value |
|-------|-------|
| **Version** | 1.1 |
| **Status** | Active |
| **Owner** | aerynOS Staff |
| **Created** | 05 Aug 2026 |
| **Last Modified** | 08 Aug 2026 |

This document defines the criteria for software to be an acceptable addition to the aerynOS recipes repository. All package requests will be evaluated against these criteria.

## Definitions

**aerynOS Recipes Repository**: The primary repository containing package recipes that are built into `.stone` packages for distribution. This repository maintains stricter acceptance criteria than any future source-only repositories.

**Package**: Software added to the aerynOS repository with accompanying metadata and build instructions.

**Packagers**: Community members who create, improve, and maintain package recipes in the repository. This includes Trusted Contributors and Trusted Maintainers.

**Project Steward**: [Ermo](https://github.com/ermo), the individual who provides overall direction and leadership for the aerynOS project.

**aerynOS Staff or Staff**: Specific individuals working on the aerynOS project under the explicit direction of the Project Steward. In the context of this Package Addition Policy, Staff have hold responsibility for formal approval or rejection of package requests.

**Team**: The combination of Staff, Trusted Maintainers, and Trusted Contributors. Team members support packaging, review, and other project work in accordance with established policies.

**Trusted Contributors**: Community members who have demonstrated they work within set guidelines.

**Trusted Maintainers**: Community members who have shown further initiative through packaging, feedback, and review work.

**Users**: End users who install and use aerynOS and its packages.

## Purpose

aerynOS is committed to offering a curated, reliable, and well-maintained set of packages that align with our vision as a versatile Linux distribution. This policy ensures that decisions about repository package additions and removals are consistent, transparent, and made in the best interest of the community.

This policy serves three groups within the aerynOS community. People often work across these roles.

### Users

Users would like to see their favourite software packages available in aerynOS. This policy helps them understand how to formally request a package and what information to provide. It also explains why a request might be rejected, with reference to specific acceptance criteria rather than subjective opinion.

### Packagers

Packagers create, improve, and maintain recipes in the repository. This includes Trusted Contributors and Trusted Maintainers who package software, provide feedback, and request changes in line with our set standards. This policy helps Packagers focus their effort on package requests that have been accepted, so they do not waste work on software that would never be accepted. It also lets Packagers self-triage when a package clearly fails acceptance criteria without needing to wait for Staff input.

### Staff

The aerynOS Staff oversee the repository and make the final decisions on what packages will be added. This policy streamlines triage by evaluating requests against defined acceptance criteria instead of debating each one from scratch.

It reduces unsolicited pull requests for packages that would never be accepted and saves review effort for all involved. Decisions remain consistent and defensible because rejections reference written acceptance criteria rather than personal judgement.

### Broader Benefits

We hope this policy builds community trust through a transparent, documented process. We want it to serve as an onboarding resource for new Packagers learning what makes a good candidate for addition to the repository.

Decisions will create a historic record against specific criteria, serving as a reference for future requests. The policy anchors decisions to consistent principles to prevent scope drift. During the alpha phase, packager time is scarce, so this policy ensures that effort is directed toward packages with the highest impact and lowest risk.

## Acceptance Criteria

### 1. Licensing

Software must use a license compatible with aerynOS's commitment to free and open-source software. We reference the SPDX license list ([https://spdx.org/licenses/](https://spdx.org/licenses/)) for accepted licenses. Examples include:

- GPL (v2, v3, AGPL variants)
- MIT / X11
- Apache 2.0
- BSD (2-Clause, 3-Clause)
- LGPL
- MPL
- ISC

Software with proprietary, non-redistributable, or source-available only licenses will be rejected from the primary recipes repository. Software with unclear licensing will require clarification from the requester before consideration.

Future alternative repositories may have different acceptance criteria for licensing, subject to separate policies.

### 2. Explicitly Redistributable

The source must be freely redistributable without restriction. Software that requires end-user license agreements imposing additional terms will be rejected.

Software that requires account creation or login to access source or binaries will also be rejected. Non-standard redistribution permissions fall under the same rule unless explicit permission from upstream is documented.

### 3. Software Age and Stability

Preference is given to software that demonstrates a minimum of 6 months since first stable release. Regular maintenance and updates are expected, with at least one release within the past year. Clear versioning and release notes should be available.

Exceptionally popular or security-critical software may be considered earlier at the discretion of aerynOS Staff.

### 4. Stack Complexity

We avoid introducing unnecessary complexity into the software stack. Requests will be evaluated for several factors:

- Does this require many new dependencies that are not already packaged?
- Does the build process integrate cleanly with aerynOS tooling and stateless approach?
- Does introducing a new language ecosystem, such as a new scripting language runtime, have strong justification?

### 5. Value to aerynOS

Software should provide clear value to aerynOS Users. Value may come from filling gaps in commonly-used categories of software, offering a better alternative to existing options, or being specifically requested by multiple Users. Accessibility or inclusion features are also valued.

Software that is niche, highly-specialised, or primarily useful for testing will be deprioritised or rejected.

### 6. Maintenance Burden

Maintenance burden is a consideration for all packages entering the repository. This assessment becomes even more important during the alpha phase, where the packager team is still growing.

We consider whether the software is likely to require frequent updates, such as rapidly evolving projects. We also consider whether a maintainer from the community has offered to maintain the package long-term.

Finally, we assess whether the package aligns with the Team's capacity and expertise. Packages that would require unsustainable maintenance may be declined.

## Dependencies and Approval

When a package is approved for addition to the repository, any new dependencies required for that package are also assumed to be approved. This allows the packaging workflow to proceed without separate approval steps for transitive dependencies.

For packagers, one pull request should be created for the approved package. Each new dependency introduced should be added in a separate commit within that pull request. This keeps the history clear and makes reviewing PRs easier.

For clarity, packages submitted for PR that have not been approved via a [package addition request](https://github.com/aerynOS/recipes/issues/new?template=request_new_package.yaml) can be rejected or deferred until such request is made and approved.

**Example Structure:**

```
Single PR with multiple commits
Commit 1: "libfoo: Add at vXX.XX"
Commit 2: "libbar: Add at vYY.YY"
Commit 3: "package: Add at vZZ.ZZ"
```

## Packaging Standards

All packages must follow the aerynOS packaging guidelines, available at [https://aerynos.dev/packaging/](https://aerynos.dev/packaging/). These standards cover recipe structure, build workflows, metadata requirements, and quality expectations.

Pull requests and commits must follow the documented submission format. Reviews will check compliance with these standards. Pull requests that do not meet the guidelines will see Team members request changes. These changes must be effectuated for the request to be accepted.

## Rejection Policy

The aerynOS Staff reserves the right to permanently reject a package request without further discussion in certain situations:

- The package clearly fails one or more of the listed acceptance criteria.
- The package request duplicates existing package functionality.
- The package is jugded to pose security or legal risks to aerynOS.

Existing or expired package requests will not be re-evaluated under new policy changes. This prevents an unmanageable backlog from accumulating whenever policies evolve.

Rejected issues will be closed with a label (package: rejected) and a comment explaining which criteria was not met.

## Exceptions

The aerynOS Staff may make exceptions to this policy in specific cases. Security-critical updates or patches qualify. Packages that align with aerynOS's strategic direction despite minor policy gaps may also be considered. Special circumstances discussed and agreed upon by the aerynOS Staff could also be considered by exception.

Exceptions must be publicly justified when approved.

## How This Policy Is Enforced

1. When you open a Package Request issue, the aerynOS Staff or Trusted Maintainers will evaluate it against this policy.
2. If the software fails any policy criteria, the issue will be rejected with a reference to the specific section above.
3. Approved requests will be labelled package: approved and become available for packagers to implement.
4. Changes to this policy will be communicated through Zulip, GitHub Discussions, and blog posts.

## Revision history

| Version | Changelog |
|-------|-------|
| 1.0 | Initial policy document |
| 1.1 | Add clarity submitting PR's without a Package Addition Request could lead to rejection of said PR |
