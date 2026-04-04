---
title: Downloads
---
# Latest Build Artifacts

This page provides a stable link to the latest artifacts from the last successful build on the `main` branch.
Artifact information is loaded from the [GitHub Releases API](https://docs.github.com/en/rest/releases/releases#get-a-release-by-tag-name).

<div id="build-info">
  <p id="loading-msg">&#9203; Loading latest build information from GitHub&hellip;</p>

  <div id="build-details" style="display:none">
    <blockquote>
      <strong>Latest Build:</strong>
      Run <a id="run-link" href="#">#<span id="run-number"></span></a>
      &nbsp;|&nbsp;
      <strong>Commit:</strong> <a id="commit-link" href="#"><span id="commit-sha"></span></a>
      &nbsp;|&nbsp;
      <strong>Published:</strong> <span id="run-date"></span>
    </blockquote>

    <h2>Platform Launchers</h2>
    <table>
      <thead>
        <tr>
          <th>Platform</th>
          <th>Architecture</th>
          <th>Format</th>
          <th>Download</th>
        </tr>
      </thead>
      <tbody id="artifacts-table"></tbody>
    </table>

    <blockquote>
      &#8505;&#65039; <strong>Note:</strong> The <code>.run</code> files are self-extracting shell scripts for
      Linux and macOS. The <code>.bat</code> file is a self-extracting batch script for Windows.
      All launchers include a bundled JRE — no Java installation required.
    </blockquote>
  </div>

  <div id="error-msg" style="display:none">
    <p>&#9888;&#65039; Could not load artifact information automatically.</p>
    <p>
      Please visit the
      <a href="https://github.com/peterkir/jpmcli/releases/tag/latest-main">
        latest-main release page
      </a>
      and download artifacts manually.
    </p>
  </div>
</div>

<script>
(function () {
  'use strict';

  var REPO        = 'peterkir/jpmcli';
  var RELEASE_TAG = 'latest-main';

  /* Human-readable metadata for every artifact produced by the build workflow */
  var ARTIFACT_META = [
    { name: 'jpm-linux-amd64.run',     platform: 'Linux',   arch: 'x86_64 (amd64)',   fmt: '.run'  },
    { name: 'jpm-linux-aarch64.run',   platform: 'Linux',   arch: 'aarch64 (ARM)',     fmt: '.run'  },
    { name: 'jpm-macos-amd64.run',     platform: 'macOS',   arch: 'x86_64 (Intel)',   fmt: '.run'  },
    { name: 'jpm-macos-aarch64.run',   platform: 'macOS',   arch: 'aarch64 (Apple Silicon)', fmt: '.run' },
    { name: 'jpm-windows-amd64.bat',   platform: 'Windows', arch: 'x86_64 (amd64)',   fmt: '.bat'  }
  ];

  function esc(str) {
    var d = document.createElement('div');
    d.appendChild(document.createTextNode(String(str)));
    return d.innerHTML;
  }

  function fetchJSON(url) {
    return fetch(url).then(function (r) {
      if (!r.ok) { throw new Error('HTTP ' + r.status + ' for ' + url); }
      return r.json();
    });
  }

  function loadArtifacts() {
    var releaseUrl = 'https://api.github.com/repos/' + REPO +
      '/releases/tags/' + RELEASE_TAG;

    fetchJSON(releaseUrl)
      .then(function (release) {
        renderPage(release, release.assets || []);
      })
      .catch(function (err) {
        console.error('Failed to load artifacts:', err);
        document.getElementById('loading-msg').style.display = 'none';
        document.getElementById('error-msg').style.display = 'block';
      });
  }

  function renderPage(release, assets) {
    var releaseLabel = release.name || release.tag_name || RELEASE_TAG;
    var releaseTime  = release.published_at || release.created_at;
    var headSha      = release.target_commitish || '';

    document.getElementById('run-link').href           = release.html_url;
    document.getElementById('run-number').textContent  = releaseLabel;
    document.getElementById('commit-link').href        = 'https://github.com/' + REPO + '/commit/' + headSha;
    document.getElementById('commit-sha').textContent  = headSha ? String(headSha).substring(0, 12) : 'n/a';
    document.getElementById('run-date').textContent    = releaseTime ? new Date(releaseTime).toUTCString() : 'n/a';

    var byName = {};
    assets.forEach(function (a) { byName[a.name] = a; });

    var tbody = document.getElementById('artifacts-table');

    ARTIFACT_META.forEach(function (meta) {
      var asset        = byName[meta.name];
      var downloadCell = asset
        ? '<a href="' + esc(asset.browser_download_url) + '">\u2b07 Download</a>'
        : '<em>not available</em>';

      var row = document.createElement('tr');
      row.innerHTML =
        '<td>' + esc(meta.platform) + '</td>' +
        '<td>' + esc(meta.arch)     + '</td>' +
        '<td><code>' + esc(meta.fmt) + '</code></td>' +
        '<td>' + downloadCell + '</td>';
      tbody.appendChild(row);
    });

    document.getElementById('loading-msg').style.display   = 'none';
    document.getElementById('build-details').style.display = 'block';
  }

  loadArtifacts();
}());
</script>

<sup>last edit: {{ 'now' | date: "%Y%m%d-%H%M%S" }}</sup>
