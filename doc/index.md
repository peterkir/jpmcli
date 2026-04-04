# jpmcli

Just Another Package Manager for Java — a command-line tool for installing
and managing executable JARs on any platform.

* Self-extracting launchers for Linux, macOS, and Windows (no pre-installed JRE needed)
* Supports `amd64` and `aarch64` architectures
* Bundled JRE based on Eclipse Temurin `Java 21`
* Built by Maven with the [bnd-maven-plugin](https://bnd.bnd.tools)
* Continuous integration for all platforms in a [single CI build](https://github.com/{{ repository_nwo }}/actions/workflows/ci-build.yml)

## Quick Links

- [Downloads](downloads) — latest artifacts from the last successful build on `main`
- [Installation](installation) — how to install and use jpm

## Source repository

[github.com/peterkir/jpmcli](https://github.com/peterkir/jpmcli)

<sup>last edit: {{ 'now' | date: "%Y%m%d-%H%M%S" }}</sup><br/>
{% assign source_revision = site.source_revision | default: site.github.build_revision %}
{% assign repository_nwo = site.github.repository_nwo | default: site.repository | default: 'peterkir/jpmcli' %}
{% if source_revision and source_revision != '' %}
<sup>source-revision: <a href="https://github.com/{{ repository_nwo }}/commit/{{ source_revision }}">{{ source_revision | slice: 0, 12 }}</a></sup>
{% else %}
<sup>source-revision: n/a</sup>
{% endif %}
