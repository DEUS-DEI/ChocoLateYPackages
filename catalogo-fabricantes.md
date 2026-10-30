# Catalogo de fabricantes

Generado por `vendor_catalog.ps1` el 2026-10-08 12:17 UTC. Fabricantes: Mozilla, Cloudflare, GitHub, Google, Amazon, Cursor (Anysphere), Fenix (Corey Butler).

**Columnas anadidas el 2026-10-30, a mano**; el resto de cada fila es del 2026-10-08. Desde entonces `vendor_catalog.ps1` las genera solo: al volver a guardar el informe con `-OutFile catalogo-fabricantes.md` salen igual, con los datos de ese dia.

- **winget**: el paquete del producto en el indice de winget y su version en el indice del 2026-10-30.
- **Descarga**: el formato de lo que el fabricante publica para Windows (archivos del release de GitHub o pagina de descarga).
- **Se puede (choco)** y **Se puede (winget)**: `ya`, ya hay paquete (`ya (?)`: hay uno que se llama como el repositorio y puede ser otro programa; `ya: <id>`: lo hay, aunque la columna Chocolatey, del 2026-10-08, no lo sepa); `si`, se podria hacer; `no (...)`, no se puede o no tiene sentido, y por que; `preparado`, lo deja listo este repositorio para winget (README, seccion "winget").

Chocolatey instala cualquier formato (msi, exe, zip, tar.gz, 7z...). winget solo admite msi, exe, msix y zip, la instalacion tiene que ser desatendida y no puede pasar por un script. Una extension de `gh`, una biblioteca o un complemento de otro programa no se empaqueta. En la tabla del indice de winget, la columna Chocolatey es del 2026-10-30.

Resumen de los 177 actuales: en Chocolatey, 56 ya tienen paquete, 93 se podrian hacer y 28 no; en winget, 49 ya estan, 3 los prepara este repositorio, 77 se podrian hacer y 48 no.

## Actuales

| Fabricante | Producto | Canal | Version | Fecha | Chocolatey | En este repo | Instalar | Nota | winget | Descarga | Se puede (choco) | Se puede (winget) |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Mozilla | Firefox | estable | 157.0.1 |  | firefox 157.0.1 |  | firefox |  | Mozilla.Firefox 157.0.1 | exe, msi | ya | ya |
| Mozilla | Firefox Beta | beta | 158.0b5 |  | firefox-beta 153.0.5-beta (atrasado) |  | firefox-beta |  | Mozilla.Firefox.Beta.MSIX 160.0.2.0 | exe, msi | ya | ya |
| Mozilla | Firefox Developer Edition | dev | 158.0b5 |  | firefox-dev 158.0.4-beta |  | firefox-dev |  | Mozilla.Firefox.DeveloperEdition 156.0 | exe, msi | ya | ya |
| Mozilla | Firefox ESR | esr | 140.17.0esr |  | firefoxesr 140.17.0 |  | firefox-esr |  | Mozilla.Firefox.ESR 153.4.0 | exe, msi | ya | ya |
| Mozilla | Firefox Nightly | nightly | 159.0a1 |  | firefox-nightly 159.0.1.2026100716-alpha |  | firefox-nightly |  | Mozilla.Firefox.Nightly.MSIX 161.2610.2809.0 | exe, msi | ya | ya |
| Mozilla | geckodriver | estable | v0.37.1 | 2026-07-20 | selenium-gecko-driver 0.37.1 |  |  |  | Mozilla.GeckoDriver 0.37.1 | zip | ya | ya |
| Mozilla | grcov | estable | v0.10.8 | 2026-09-11 | - |  |  |  | - | zip | si | si |
| Mozilla | Mozilla VPN | estable | v2.39.0 | 2026-07-22 | - |  | mozilla-vpn |  | Mozilla.VPN 2.40.1 | msi | si | ya |
| Mozilla | MozillaBuild | estable | 4.2.1 |  | mozillabuild 4.2.1 |  |  |  | - | exe | ya | si |
| Mozilla | mozregression | estable | 7.5.0 | 2026-10-02 | - |  |  |  | Mozilla.mozregression 7.3 | exe | si | ya |
| Mozilla | sccache | estable | v0.18.0 | 2026-09-14 | sccache 0.17.0 (atrasado) |  |  |  | Mozilla.sccache 0.18.0 | zip | ya | ya |
| Mozilla | Thunderbird | estable | 157.0.1 |  | thunderbird 157.0.1 |  | thunderbird |  | Mozilla.Thunderbird 159.0 | exe, msi | ya | ya |
| Mozilla | Thunderbird Beta | beta | 158.0b5 |  | thunderbird-mozilla 158.0.0-beta3 (atrasado) | actual; sustituye a thunderbird-beta | thunderbird-beta |  | Mozilla.Thunderbird.Beta.MSIX 148.0.6 | exe, msi | ya | preparado: Mozilla.Thunderbird.Beta (el MSIX esta parado en 148) |
| Mozilla | Thunderbird Daily | nightly | 159.0a1 |  | thunderbird-nightly 159.0.1.2026100210-alpha | actual; sustituye a thunderbird-daily | thunderbird-daily |  | - | exe, msi | ya | no (todas las builds se llaman igual en Windows) |
| Mozilla | Thunderbird ESR | esr | 140.17.0esr |  | - |  | thunderbird-esr |  | Mozilla.Thunderbird.ESR 153.6.0 | exe, msi | ya: thunderbirdesr | ya |
| Mozilla | Thunderbolt | estable | v0.1.107 | 2026-07-13 | - |  |  |  | - | exe, msi | si | si |
| Mozilla | mozilla/autograph-experiments |  | v1.0.2 | 2025-12-18 | - |  |  |  | - | zip | no (cliente de pruebas) | no (cliente de pruebas) |
| Mozilla | mozilla/cargo-vet |  | v0.10.0 | 2024-10-03 | - |  |  |  | - | zip | si | si |
| Mozilla | mozilla/dump_syms |  | v2.3.9 | 2026-08-14 | - |  |  |  | - | zip | si | si |
| Mozilla | mozilla/reliost |  | v0.2.5 | 2026-05-02 | - |  |  |  | - | zip | si | si |
| Mozilla | mozilla/rust-code-analysis |  | v0.0.25 | 2023-01-13 | - |  |  | sin versiones desde 2023 | - | zip | si | si |
| Mozilla | mozilla/stmo-cli |  | 0.12.0 | 2026-10-06 | - |  |  |  | - | zip | si | si |
| Mozilla | mozilla-ai/cq |  | cli/v0.18.0 | 2026-10-05 | - |  |  |  | - | zip | si | si |
| Mozilla | mozilla-ai/llamafile-builder |  | v0.1.2 | 2026-05-15 | - |  |  |  | - | zip | si | si |
| Mozilla | mozilla-platform-ops/fleetbench |  | v0.4.6 | 2026-07-30 | - |  |  |  | - | exe | si | si |
| Cloudflare | cfssl | estable | v1.7.1 | 2026-10-06 | - |  |  |  | - | exe | si | si |
| Cloudflare | cf-terraforming | estable | v0.29.0 | 2026-09-02 | - |  |  |  | - | tar.gz | si | no (tar.gz) |
| Cloudflare | Cloudflare WARP | beta | 2026.8.2033.1 | 2026-09-30 | cloudflare-warp-pre 2026.8.2033.1-pre | actual; sustituye a warp-beta | warp-beta |  | - | msi | ya | preparado: Cloudflare.Warp.Beta |
| Cloudflare | Cloudflare WARP | estable | 2026.8.2100.0 | 2026-10-07 | warp 2026.7.1376 (atrasado) |  | warp |  | Cloudflare.Warp 26.8.2115.0 | msi | ya | ya |
| Cloudflare | cloudflared | estable | 2026.10.0 | 2026-10-05 | cloudflared 2026.10.0 |  | cloudflared |  | Cloudflare.cloudflared 2026.10.5 | msi, exe | ya | ya |
| Cloudflare | flarectl | estable | v0.119.0 |  | flarectl 0.119.0 | actual |  |  | - | tar.gz | ya | no (tar.gz) |
| Cloudflare | workerd | estable | v1.20261008.1 | 2026-10-08 | - |  |  |  | - | gz | si | no (gz) |
| Cloudflare | Wrangler | estable | 4.148.0 |  | - |  |  |  | - | npm | si (con Node.js) | no (solo npm) |
| Cloudflare | cloudflare/gokey |  | v0.2.1 | 2026-03-31 | - |  |  |  | - | exe | si | si |
| Cloudflare | cloudflare/logshare |  | v1.4.2 | 2018-04-11 | - |  |  | sin versiones desde 2018 | - | exe | si | si |
| Cloudflare | cloudflare/networkquality-rs |  | v0.3.0 | 2026-09-25 | - |  |  |  | - | zip | si | si |
| Cloudflare | cloudflare/pint |  | v0.89.1 | 2026-10-08 | - |  |  |  | - | tar.gz | si | no (tar.gz) |
| Cloudflare | cloudflare/ssh-log-cli |  | v0.1.1 | 2022-04-13 | - |  |  | sin versiones desde 2022 | - | zip | si | si |
| Cloudflare | cloudflare/tf-migrate |  | v1.1.0 | 2026-07-14 | - |  |  |  | - | zip | si | si |
| Cloudflare | cloudflare/workerskv.gui |  | v0.0.2 | 2021-07-26 | - |  |  | sin versiones desde 2021 | - | msi | si | si |
| GitHub | CodeQL CLI | estable | v2.27.2 | 2026-10-07 | codeql 2.27.2 |  |  |  | - | zip | ya | si |
| GitHub | Dependabot CLI | estable | v1.94.0 | 2026-10-07 | dependabot 1.93.0 (atrasado) |  |  |  | - | zip | ya | si |
| GitHub | Git Credential Manager | estable | v3.0.1 | 2026-10-06 | - |  | gcm |  | Git.GCM 3.0.1 | exe | si (los de Chocolatey son de la version antigua) | ya |
| GitHub | Git LFS | estable | v3.8.0 | 2026-08-28 | git-lfs 3.8.0 |  | git-lfs |  | GitHub.GitLFS 3.8.0 | exe | ya | ya |
| GitHub | GitHub Actions Runner | estable | v2.338.0 | 2026-10-06 | - |  |  |  | - | zip | si | si |
| GitHub | GitHub CLI (gh) | estable | v2.102.0 | 2026-09-30 | gh 2.102.0 |  | gh |  | GitHub.cli 2.103.3 | msi, zip | ya | ya |
| GitHub | GitHub Copilot CLI | estable | v1.0.93 | 2026-10-07 | github-copilot-cli 1.0.91 (atrasado) |  |  |  | GitHub.Copilot 1.0.105 | zip | ya | ya |
| GitHub | GitHub Desktop | beta | 3.6.7-beta3 | 2026-10-07 | github-desktop-pre 3.6.7-beta2 (atrasado) | actual; sustituye a github-desktop-beta | github-desktop-beta |  | GitHub.GitHubDesktop.Beta 3.5.5-beta2 | exe, msi | ya | ya (iba atrasado; lo actualiza este repo) |
| GitHub | GitHub Desktop | estable | 3.6.6 | 2026-09-15 | github-desktop 3.6.6 |  | github-desktop |  | GitHub.GitHubDesktop 3.6.10 | exe, msi | ya | ya |
| GitHub | GitHub Enterprise Importer (gei) | estable | v1.34.0 | 2026-10-07 | - |  |  |  | - | exe | si | si |
| GitHub | GitHub MCP Server | estable | v2.0.2 | 2026-10-08 | github-mcp-server 1.14.0 (atrasado) |  |  |  | - | zip | ya | si |
| GitHub | git-sizer | estable | v1.5.0 | 2021-11-16 | git-sizer 1.5.0 |  |  | sin versiones desde 2021 | GitHub.git-sizer 1.5.0 | zip | ya | ya |
| GitHub | smimesign | estable | v0.2.0-rc1 | 2021-10-04 | smimesign 0.2.0 |  |  | sin versiones desde 2021 | GitHub.smimesign 0.2.0-rc1 | zip | ya | ya |
| GitHub | actions/actions-sync |  | v202606241747 | 2026-06-24 | - |  |  |  | - | tar.gz | si | no (tar.gz) |
| GitHub | cli/gh-webhook |  | v0.2.0 | 2025-10-21 | - |  |  |  | - | exe | no (extension de gh: `gh extension install`) | no (extension de gh: `gh extension install`) |
| GitHub | dependabot/git-shim |  | v1.5.0 | 2023-04-05 | - |  |  | sin versiones desde 2023 | - | zip | no (pieza interna de Dependabot) | no (pieza interna de Dependabot) |
| GitHub | github/app |  | v1.1.27 | 2026-10-07 | - |  |  |  | GitHub.CopilotApp 1.1.33 | exe, msi | ya: github-copilot-app | ya |
| GitHub | github/codeql-action-sync-tool |  | 1.0.15 | 2025-09-16 | - |  |  |  | - | tar.gz | si | no (tar.gz) |
| GitHub | github/computer-use-plugin |  | v0.1.94 | 2026-10-07 | - |  |  |  | - | zip | no (complemento de Copilot) | no (complemento de Copilot) |
| GitHub | github/copilot-language-server-release |  | 1.551.2 | 2026-09-28 | - |  |  |  | - | zip | no (lo descargan los editores) | no (lo descargan los editores) |
| GitHub | github/gh-actions-importer |  | v1.3.6 | 2023-10-04 | - |  |  | sin versiones desde 2023 | - | exe | no (extension de gh: `gh extension install`) | no (extension de gh: `gh extension install`) |
| GitHub | github/gh-actions-lock |  | v0.1.6 | 2026-07-28 | - |  |  |  | - | exe | no (extension de gh: `gh extension install`) | no (extension de gh: `gh extension install`) |
| GitHub | github/gh-ado2gh |  | v1.34.0 | 2026-10-07 | - |  |  |  | - | exe | no (extension de gh: `gh extension install`) | no (extension de gh: `gh extension install`) |
| GitHub | github/gh-aw |  | v0.89.21 | 2026-09-23 | - |  |  |  | - | exe | no (extension de gh: `gh extension install`) | no (extension de gh: `gh extension install`) |
| GitHub | github/gh-bbs2gh |  | v1.34.0 | 2026-10-07 | - |  |  |  | - | exe | no (extension de gh: `gh extension install`) | no (extension de gh: `gh extension install`) |
| GitHub | github/gh-combine |  | v0.0.32 | 2025-10-08 | - |  |  |  | - | exe | no (extension de gh: `gh extension install`) | no (extension de gh: `gh extension install`) |
| GitHub | github/gh-elm |  | v1.0.0 | 2026-09-01 | - |  |  |  | - | exe | no (extension de gh: `gh extension install`) | no (extension de gh: `gh extension install`) |
| GitHub | github/gh-es |  | v3.22.0 | 2026-10-01 | - |  |  |  | - | exe | no (extension de gh: `gh extension install`) | no (extension de gh: `gh extension install`) |
| GitHub | github/gh-gl2gh |  | v1.34.0 | 2026-10-07 | - |  |  |  | - | exe | no (extension de gh: `gh extension install`) | no (extension de gh: `gh extension install`) |
| GitHub | github/gh-runtime-cli |  | v0.0.11 | 2026-04-08 | - |  |  |  | - | exe | no (extension de gh: `gh extension install`) | no (extension de gh: `gh extension install`) |
| GitHub | github/gh-skyline |  | v0.1.9 | 2026-05-22 | - |  |  |  | - | exe | no (extension de gh: `gh extension install`) | no (extension de gh: `gh extension install`) |
| GitHub | github/gh-stack |  | v0.2.0 | 2026-10-02 | - |  |  |  | - | exe | no (extension de gh: `gh extension install`) | no (extension de gh: `gh extension install`) |
| GitHub | github/mdbook-asciinema |  | v0.5.0 | 2026-04-16 | - |  |  |  | - | zip | si | si |
| GitHub | githubnext/ado-aw |  | v0.53.0 | 2026-10-06 | - |  |  |  | - | exe | si | si |
| Google | Android Studio | estable | 2026.2.1 |  | androidstudio 2025.2.3.9 (atrasado) |  |  |  | Google.AndroidStudio 2026.2.2.8 | exe | ya | ya |
| Google | Chrome Remote Desktop Host | estable | (ultima) | 2026-10-01 | chrome-remote-desktop-host 154.0.8037.40 |  | chrome-remote-desktop |  | Google.ChromeRemoteDesktopHost 154.0.8037.40 | msi | ya | ya |
| Google | Gemini CLI | estable | 0.63.0 |  | gemini-cli 0.27.2 (atrasado) |  |  |  | - | npm | ya | no (solo npm) |
| Google | Go | estable | go1.27.1 |  | golang 1.27.1 |  | go |  | GoLang.Go 1.27.0 | msi | ya | ya |
| Google | Google Chrome | beta | 156.0.8078.17 |  | googlechromebeta 120.0.6099.56-beta (atrasado) |  | chrome-beta |  | Google.Chrome.Beta 158.0.8127.2 | msi, exe | ya | ya |
| Google | Google Chrome | canary | 157.0.8092.0 |  | - |  |  |  | Google.Chrome.Canary 159.0.8129.0 | msi, exe | ya: googlechromecanary | ya |
| Google | Google Chrome | dev | 157.0.8081.0 |  | - |  | chrome-dev |  | Google.Chrome.Dev 158.0.8117.2 | msi, exe | ya: googlechromedev | ya |
| Google | Google Chrome | estable | 156.0.8078.12 |  | googlechrome 156.0.8078.12 |  | chrome |  | Google.Chrome 156.0.8078.48 | msi, exe | ya | ya |
| Google | Google Cloud CLI | estable | 588.0.0 |  | gcloudsdk 587.0.0 (atrasado) |  | gcloud |  | Google.CloudSDK 591.0.0 | exe | ya | ya |
| Google | Google Credential Provider for Windows | estable | (ultima) | 2026-10-02 | - |  | gcpw |  | Google.CredentialProviderForWindows 150.0.7871.100 | msi | si | ya |
| Google | Google Drive | estable | (ultima) | 2026-10-07 | googledrive 132.0.0 |  | drive |  | Google.GoogleDrive 132.0.0.0 | exe | ya | ya |
| Google | Google Earth Pro | estable | (ultima) | 2026-08-20 | googleearthpro 7.3.6.20250917 |  | earth-pro |  | Google.EarthPro 7.3.7.1327 | exe | ya | ya |
| Google | bazelbuild/bazel |  | 9.3.0 | 2026-10-07 | bazel 10.0.0-rc1 (?) |  |  |  | Bazel.Bazel 9.3.0 | exe, zip | ya (?) | ya |
| Google | bazelbuild/bazelisk |  | v1.29.0 | 2026-04-27 | bazelisk 1.29.0 (?) |  |  |  | Bazel.Bazelisk 1.29.0 | exe | ya (?) | ya |
| Google | bazelbuild/bazel-toolchains |  | v5.1.3-rc1 | 2023-12-21 | - |  |  |  | - | exe | si | si |
| Google | bazelbuild/bazel-watcher |  | v0.33.0 | 2026-08-26 | - |  |  |  | - | exe | si | si |
| Google | bazelbuild/java_tools |  | java_v21.0 | 2026-08-24 | - |  |  |  | - | zip | no (piezas que descarga Bazel) | no (piezas que descarga Bazel) |
| Google | bazelbuild/rules_rust |  | 0.74.0 | 2026-08-28 | - |  |  |  | - | exe | no (lo descarga Bazel) | no (lo descarga Bazel) |
| Google | google/addlicense |  | v1.2.0 | 2025-08-13 | - |  |  |  | - | zip | si | si |
| Google | google/agi |  | v3.3.3 | 2025-01-20 | - |  |  |  | - | msi, zip | si | si |
| Google | google/android-emulator-hypervisor-driver |  | v2.2 | 2024-04-02 | - |  |  |  | - | zip | si | no (se instala con un script) |
| Google | google/bindiff |  | v8 | 2023-09-25 | - |  |  | sin versiones desde 2023 | - | msi | si | si |
| Google | google/binexport |  | v12-20240417-ghidra_11.0.3 | 2024-04-17 | - |  |  |  | - | zip | no (complemento de IDA Pro y Ghidra) | no (complemento de IDA Pro y Ghidra) |
| Google | google/brotli |  | v1.2.0 | 2025-10-27 | - |  |  |  | Google.Brotli 1.2.1 | zip | si | ya |
| Google | google/dawn |  | v20261007.202641 | 2026-10-08 | - |  |  |  | - | tar.gz | no (biblioteca) | no (biblioteca) |
| Google | google/EtwToPprof |  | v0.3 | 2021-08-26 | - |  |  | sin versiones desde 2021 | - | exe | si | si |
| Google | google/filament |  | v1.77.2 | 2026-09-28 | - |  |  |  | - | tar.gz | no (biblioteca) | no (biblioteca) |
| Google | google/flatbuffers |  | v25.12.19-2026-02-06-03fffb2 | 2026-02-06 | - |  |  |  | Google.flatbuffers 25.12.19 | zip | ya: flatc (atrasado) | ya |
| Google | google/gapid |  | v1.6.1 | 2019-08-02 | - |  |  | sin versiones desde 2019 | - | msi, zip | si | si |
| Google | google/gce-tcb-verifier |  | v0.3.1 | 2025-03-01 | - |  |  |  | - | tar.gz | si | no (tar.gz) |
| Google | google/gke-policy-automation |  | v1.4.8 | 2026-09-04 | - |  |  |  | - | zip | si | si |
| Google | google/gn-language-server |  | v1.16.0 | 2026-09-02 | - |  |  |  | - | exe | no (lo instala la extension del editor) | no (lo instala la extension del editor) |
| Google | google/go-containerregistry |  | v0.22.1 | 2026-09-04 | go-containerregistry 0.22.1 (?) |  |  |  | - | tar.gz | ya (?) | no (tar.gz) |
| Google | google/go-jsonnet |  | v0.22.0 | 2026-03-24 | - |  |  |  | - | tar.gz | si | no (tar.gz) |
| Google | google/google-java-format |  | v1.37.0 | 2026-10-01 | - |  |  |  | - | exe | si | si |
| Google | google/go-tpm-tools |  | v0.4.10 | 2026-09-17 | - |  |  |  | - | zip | si | si |
| Google | google/idaidle |  | v0.9 | 2026-07-17 | - |  |  |  | - | zip | no (complemento de IDA Pro) | no (complemento de IDA Pro) |
| Google | google/import-mailbox-to-gmail |  | v2.0 | 2026-02-16 | - |  |  |  | - | exe | si | si |
| Google | google/keep-sorted |  | v0.10.0 | 2026-08-20 | - |  |  |  | - | exe | si | si |
| Google | google/magika |  | cli/v1.1.0 | 2026-04-24 | - |  |  |  | Google.Magika 1.1.0 | zip | si | ya |
| Google | google/mtail |  | v3.0.8 | 2024-08-08 | - |  |  |  | - | tar.gz | si | no (tar.gz) |
| Google | google/osv-scanner |  | v2.6.0 | 2026-09-14 | osv-scanner 1.6.2 (?) |  |  |  | Google.OSVScanner 2.7.0 | exe | ya (?) | ya |
| Google | google/perfetto |  | v58.2 | 2026-08-24 | - |  |  |  | Google.Perfetto 59.1 | zip | si | ya |
| Google | google/sam |  | v0.1.0-rc.9 | 2026-10-07 | sam 2021.12.02-r2 (?) |  |  |  | - | zip | ya (?) | si |
| Google | google/scientific_dart |  | artifacts-v0.2.0 | 2026-09-28 | - |  |  |  | - | dll | no (bibliotecas DLL) | no (bibliotecas DLL) |
| Google | google/sec-gemini |  | cli/sec-gemini-v0.0.4 | 2025-06-27 | - |  |  |  | - | zip | si | si |
| Google | google/sentencepiece |  | v0.2.2 | 2026-07-12 | - |  |  |  | - | 7z | no (biblioteca) | no (biblioteca) |
| Google | google/spatial-media |  | v2.1 | 2018-08-27 | - |  |  | sin versiones desde 2018 | - | zip | si | si |
| Google | google/webbundle |  | webbundle-cli-v0.4.1 | 2022-11-30 | - |  |  | sin versiones desde 2022 | - | zip | si | si |
| Google | google/yamlfmt |  | v0.21.0 | 2026-01-05 | - |  |  |  | - | tar.gz | si | no (tar.gz) |
| Google | GoogleChrome/ripunzip |  | v2.0.4 | 2025-12-04 | - |  |  |  | - | zip | si | si |
| Google | google-gemini/gemini-api-cli |  | v0.4.0 | 2026-09-30 | - |  |  |  | - | zip | si | si |
| Amazon | Amazon Corretto 21 (JDK) | estable | 21.0.12.12.1 | 2026-10-01 | corretto21jdk 21.0.12.81 |  | corretto-21 |  | Amazon.Corretto.21.JDK 21.0.13.0 | msi | ya | ya |
| Amazon | Amazon Corretto 25 (JDK) | estable | 25.0.4.10.1 | 2026-10-01 | corretto25jdk 25.0.1.81 |  | corretto-25 |  | Amazon.Corretto.25.JDK 25.0.5.0 | msi | ya | ya |
| Amazon | AWS CDK | estable | 2.1145.0 |  | - |  |  |  | - | npm | si (con Node.js) | no (solo npm) |
| Amazon | AWS CLI | estable | 2.37.10 |  | awscli 2.37.10 |  | aws-cli |  | Amazon.AWSCLI 2.39.1 | msi | ya | ya |
| Amazon | AWS SAM CLI | estable | v1.167.0 | 2026-10-06 | awssamcli 1.145.0 (atrasado) |  | sam-cli |  | Amazon.SAM-CLI 1.170.0 | msi | ya | ya |
| Amazon | AWS Session Manager Plugin | estable | 1.2.835.0 |  | awscli-session-manager 1.2.835 |  | session-manager-plugin |  | Amazon.SessionManagerPlugin 1.2.896.0 | exe | ya | ya |
| Amazon | Kiro | estable | 1.2.37 | 2026-10-05 | kiro 1.2.37 |  | kiro |  | Amazon.Kiro 1.4.62 | exe | ya | ya |
| Amazon | aws/amazon-documentdb-odbc-driver |  | v1.0.0 | 2023-02-01 | - |  |  | sin versiones desde 2023 | - | exe | si | si |
| Amazon | aws/amazon-ec2-instance-selector |  | v3.1.3 | 2025-12-22 | - |  |  |  | - | exe, tar.gz | si | si |
| Amazon | aws/amazon-ec2-metadata-mock |  | v1.13.0 | 2025-02-13 | - |  |  |  | - | exe, zip | si | si |
| Amazon | aws/aperf |  | v1.3.0 | 2026-09-05 | - |  |  |  | - | tar.gz | si | no (tar.gz) |
| Amazon | aws/aws-advanced-odbc-wrapper |  | 1.3.1 | 2026-09-08 | - |  |  |  | - | msi | si | si |
| Amazon | aws/aws-codedeploy-agent |  | v2.1.0 | 2026-09-09 | - |  |  |  | - | msi | si | si |
| Amazon | aws/aws-mysql-odbc |  | 1.2.1 | 2026-09-03 | - |  |  |  | - | msi | si | si |
| Amazon | aws/aws-pgsql-odbc |  | 1.0.2 | 2026-01-20 | - |  |  |  | - | msi | si | si |
| Amazon | aws/aws-xray-dotnet-agent |  | v2.10.0-beta.1 | 2021-05-10 | - |  |  | sin versiones desde 2021 | - | msi | si | si |
| Amazon | aws/lightsailctl |  | v1.0.8 | 2026-05-19 | - |  |  |  | - | zip | si | si |
| Amazon | awslabs/aidlc-workflows |  | v2.11.0 | 2026-10-08 | - |  |  |  | - | exe | si | si |
| Amazon | awslabs/amazon-emr-on-eks-custom-image-cli |  | v1.06 | 2024-09-25 | - |  |  |  | - | msi | si | si |
| Amazon | awslabs/amazon-timestream-connector-prometheus |  | v1.3.2 | 2025-02-25 | - |  |  |  | - | tar.gz | si | no (tar.gz) |
| Amazon | awslabs/amazon-timestream-odbc-driver |  | v2.1.4 | 2026-09-25 | - |  |  |  | - | exe | si | si |
| Amazon | awslabs/attribution-gen |  | v0.0.4 | 2025-02-07 | - |  |  |  | - | zip | si | si |
| Amazon | awslabs/aws-cloudformation-template-builder |  | v0.2.0 | 2020-10-27 | - |  |  | sin versiones desde 2020 | - | zip | si | si |
| Amazon | awslabs/aws-cloudformation-template-formatter |  | v1.1.3 | 2023-02-02 | - |  |  | sin versiones desde 2023 | - | zip | si | si |
| Amazon | awslabs/aws-iotsitewise-odbc-driver |  | v2.0.0 | 2025-07-30 | - |  |  |  | - | exe | si | si |
| Amazon | awslabs/aws-kubernetes-migration-factory |  | v1.1.0 | 2023-02-11 | - |  |  | sin versiones desde 2023 | - | exe | si | si |
| Amazon | awslabs/clencli |  | 0.3.6 | 2021-05-14 | - |  |  | sin versiones desde 2021 | - | exe | si | si |
| Amazon | awslabs/codeknit |  | v0.6.0 | 2026-09-14 | - |  |  |  | - | zip | si | si |
| Amazon | awslabs/diagram-as-code |  | v0.24 | 2026-08-26 | - |  |  |  | - | zip | si | si |
| Amazon | awslabs/dynein |  | v0.3.0 | 2024-06-21 | - |  |  |  | - | zip | si | si |
| Amazon | awslabs/eks-node-viewer |  | v0.7.4 | 2025-04-24 | - |  |  |  | - | exe | si | si |
| Amazon | awslabs/elasticache-cluster-config-net |  | v1.0 | 2014-07-30 | - |  |  | sin versiones desde 2014 | - | msi, zip | si | si |
| Amazon | awslabs/ferret-scan |  | v2.5.3 | 2026-10-07 | - |  |  |  | - | exe | si | si |
| Amazon | awslabs/filemoverexpress |  | 1.1.0 | 2026-09-24 | - |  |  |  | - | exe | si | si |
| Amazon | awslabs/iam-policy-autopilot |  | 0.3.0 | 2026-08-18 | iam-policy-autopilot 0.3.0 (?) |  |  |  | - | zip | ya (?) | si |
| Amazon | awslabs/kinesis-agent-windows |  | v1.2.10.2 | 2023-10-21 | - |  |  |  | - | msi | si | si |
| Amazon | awslabs/kinesis-hot-shard-advisor |  | v0.13 | 2025-01-21 | - |  |  |  | - | exe | si | si |
| Amazon | awslabs/kubectl-connect |  | v0.1.0 | 2024-04-19 | - |  |  |  | - | zip | si | si |
| Amazon | awslabs/llrt |  | v0.9.0-beta | 2026-09-06 | llrt 0.9.0-beta (?) |  |  |  | Amazon.LLRT 0.8.1-beta | zip | ya (?) | ya |
| Amazon | awslabs/protonizer |  | 0.4.0 | 2023-06-28 | - |  |  | sin versiones desde 2023 | - | zip | si | si |
| Amazon | awslabs/serverless-rules |  | v0.3.5 | 2026-02-20 | - |  |  |  | - | zip | no (complemento de tflint) | no (complemento de tflint) |
| Amazon | awslabs/ssosync |  | v2.9.0 | 2026-09-28 | - |  |  |  | - | zip | si | si |
| Amazon | awslabs/staticwebsite-cli |  | v0.1.6 | 2023-12-12 | - |  |  |  | - | zip | si | si |
| Amazon | awslabs/windows-web-app-migration-assistant |  | 0.2 | 2020-01-03 | - |  |  | sin versiones desde 2020 | - | zip | si | no (son scripts de PowerShell) |
| Amazon | kirodotdev/KiroCrew |  | v0.7.2 | 2026-09-29 | - |  |  |  | - | exe | si | si |
| Cursor (Anysphere) | Cursor | estable | 3.23.23 |  | cursoride 3.23.23 |  | cursor |  | Anysphere.Cursor 3.20.14 | exe | ya | ya |
| Cursor (Anysphere) | anysphere/ripgrep |  | 15.1.0-cursor5 | 2026-04-02 | ripgrep 15.2.0 (?) |  |  |  | - | zip | no (version de ripgrep para Cursor) | no (version de ripgrep para Cursor) |
| Fenix (Corey Butler) | Fenix Web Server | estable | v2.0.0 | 2014-04-08 | fenix-web-server 2.0.0.20260926 | actual; sustituye a fenix-web-server-beta, fenix-web-server-pre |  | sin versiones desde 2014 | - | zip | ya | preparado: CoreyButler.FenixWebServer (a mano) |
| Fenix (Corey Butler) | Fenix Web Server | pre | 3.0.0-rc.13 | 2019-09-17 | fenix-web-server 3.0.0-rc13-20261004 | actual; sustituye a fenix-web-server-beta, fenix-web-server-pre |  | sin versiones desde 2019 | - | exe | ya | no (su instalador espera a que se acepte un aviso) |
| Fenix (Corey Butler) | NVM for Windows | estable | v2.0.1 | 2026-10-02 | nvm 1.2.2.20251229 (atrasado) |  |  |  | CoreyButler.NVMforWindows 1.2.2 | exe, zip | ya | ya |
| Fenix (Corey Butler) | coreybutler/tapfmt |  | 1.0.1 | 2022-12-23 | - |  |  | sin versiones desde 2022 | - | zip, tar.gz | si | si |

## Descontinuados

| Fabricante | Producto | Canal | Version | Fecha | Chocolatey | En este repo | Instalar | Nota | winget | Descarga | Se puede (choco) | Se puede (winget) |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Mozilla | mozilla/DeepSpeech |  | v0.9.3 | 2020-12-10 | - |  |  | repositorio archivado | - | - | no (descontinuado) | no (descontinuado) |
| Mozilla | mozilla/tofino |  | v0.2.0 | 2016-11-11 | - |  |  | repositorio archivado | - | - | no (descontinuado) | no (descontinuado) |
| Mozilla | mozilla-platform-ops/quarantine-worker |  | v1.0.0 | 2018-06-15 | - |  |  | repositorio archivado | - | - | no (descontinuado) | no (descontinuado) |
| Mozilla | MozillaSecurity/virgo |  | v0.3.1 | 2019-07-18 | - |  |  | repositorio archivado | - | - | no (descontinuado) | no (descontinuado) |
| Mozilla | mozilla-services/hoverpad |  | 1.7 | 2017-02-22 | - |  |  | repositorio archivado | - | - | no (descontinuado) | no (descontinuado) |
| Mozilla | mozilla-services/userplex |  | v1.0.4 | 2020-09-09 | - |  |  | repositorio archivado | - | - | no (descontinuado) | no (descontinuado) |
| Cloudflare | cloudflare/cfrpki |  | v1.5.10 | 2023-04-28 | - |  |  | repositorio archivado | - | - | no (descontinuado) | no (descontinuado) |
| Cloudflare | cloudflare/gortr |  | v0.15.0 | 2024-02-29 | - |  |  | repositorio archivado | - | - | no (descontinuado) | no (descontinuado) |
| Cloudflare | cloudflare/Stout |  | v1.3.2 | 2018-03-27 | - |  |  | repositorio archivado | - | - | no (descontinuado) | no (descontinuado) |
| Cloudflare | cloudflare/unsee |  | v0.9.2 | 2018-04-19 | - |  |  | repositorio archivado | - | - | no (descontinuado) | no (descontinuado) |
| Cloudflare | cloudflare/wrangler-legacy |  | v1.21.0 | 2023-02-21 | - |  |  | repositorio archivado | - | - | no (descontinuado) | no (descontinuado) |
| GitHub | Atom | estable | v1.60.0 | 2022-03-08 | atom 1.60.0 |  |  | GitHub lo retiro en diciembre de 2022; repositorio archivado | GitHub.Atom 1.60.0 | exe | ya (descontinuado) | ya (descontinuado) |
| GitHub | hub | estable | v2.14.2 | 2020-03-05 | hub 2.14.2 |  |  | sustituido por GitHub CLI (gh); sin versiones desde 2020 | GitHub.hub 2.14.2 | zip | ya (descontinuado) | ya (descontinuado) |
| GitHub | actions/gh-actions-cache |  | v1.0.4 | 2023-10-30 | - |  |  | repositorio archivado | - | - | no (descontinuado) | no (descontinuado) |
| GitHub | atom/squeegpg-native |  | v0.0.1 | 2018-03-14 | - |  |  | repositorio archivado | - | - | no (descontinuado) | no (descontinuado) |
| GitHub | github/gh-autofix |  | v0.2.8 | 2024-10-15 | - |  |  | repositorio archivado | - | - | no (descontinuado) | no (descontinuado) |
| GitHub | github/gh-classroom |  | v0.1.17 | 2026-01-09 | - |  |  | repositorio archivado | - | - | no (descontinuado) | no (descontinuado) |
| GitHub | github/gh-copilot |  | v1.2.0 | 2025-10-30 | - |  |  | repositorio archivado | - | - | no (descontinuado) | no (descontinuado) |
| GitHub | github/gh-models |  | v0.0.25 | 2025-08-04 | - |  |  | repositorio archivado | - | - | no (descontinuado) | no (descontinuado) |
| GitHub | github/gh-net |  | v0.12.4 | 2022-09-15 | - |  |  | repositorio archivado | - | - | no (descontinuado) | no (descontinuado) |
| GitHub | github/gh-projects |  | v2.5.1 | 2023-05-17 | - |  |  | repositorio archivado | - | - | no (descontinuado) | no (descontinuado) |
| GitHub | github/gh-valet |  | v0.1.19 | 2023-01-05 | - |  |  | repositorio archivado | - | - | no (descontinuado) | no (descontinuado) |
| GitHub | github/github-artifact-exporter |  | v2.0.2 | 2021-08-09 | - |  |  | repositorio archivado | - | - | no (descontinuado) | no (descontinuado) |
| GitHub | github/homebrew-gh |  | v0.5.2 | 2020-01-29 | - |  |  | repositorio archivado | - | - | no (descontinuado) | no (descontinuado) |
| GitHub | github/vulcanizer |  | v0.14.4 | 2024-12-30 | - |  |  | repositorio archivado | - | tar.gz | no (descontinuado) | no (descontinuado) |
| Google | google/acme |  | 1.1.1 | 2016-12-05 | - |  |  | repositorio archivado | - | - | no (descontinuado) | no (descontinuado) |
| Google | google/agi-dev-releases |  | v3.3.3-dev-20241220 | 2024-12-20 | - |  |  | repositorio archivado | - | - | no (descontinuado) | no (descontinuado) |
| Google | google/cloud-print-connector |  | v1.16 | 2018-04-03 | - |  |  | repositorio archivado | - | - | no (descontinuado) | no (descontinuado) |
| Google | google/cloudprober |  | v0.11.3 | 2021-09-01 | - |  |  | repositorio archivado | - | - | no (descontinuado) | no (descontinuado) |
| Google | google/containerdbg |  | v0.0.10 | 2023-05-21 | - |  |  | repositorio archivado | - | tar.gz | no (descontinuado) | no (descontinuado) |
| Google | google/gapid-dev-releases |  | v1.7.0-dev-20200211 | 2020-02-11 | - |  |  | repositorio archivado | - | - | no (descontinuado) | no (descontinuado) |
| Google | google/gemma-journey |  | v0.0.3 | 2025-05-08 | - |  |  | repositorio archivado | - | - | no (descontinuado) | no (descontinuado) |
| Google | google/gfbuild-amber |  | github/google/gfbuild-amber/0c514a34280aaf303f6b625b0285513be8cf2d8e | 2021-08-12 | - |  |  | repositorio archivado | - | - | no (descontinuado) | no (descontinuado) |
| Google | google/gfbuild-angle |  | github/google/gfbuild-angle/f810e998993290f049bbdad4fae975e4867100ad | 2022-02-01 | - |  |  | repositorio archivado | - | - | no (descontinuado) | no (descontinuado) |
| Google | google/gfbuild-SPIRV-Tools |  | github/google/gfbuild-SPIRV-Tools/06f114d482143bd3c2fae6c8d8174a39521b09ce | 2021-07-01 | - |  |  | repositorio archivado | - | - | no (descontinuado) | no (descontinuado) |
| Google | google/gfbuild-swiftshader |  | github/google/gfbuild-swiftshader/8f075627d16bdd2a8d861e9d81df541f5cf68e2e | 2021-06-23 | - |  |  | repositorio archivado | - | - | no (descontinuado) | no (descontinuado) |
| Google | google/google-drive-shell-extension |  | v1.8.56.0 | 2015-08-13 | - |  |  | repositorio archivado | - | - | no (descontinuado) | no (descontinuado) |
| Google | google/guetzli |  | v1.0.1 | 2017-03-21 | - |  |  | repositorio archivado | - | - | no (descontinuado) | no (descontinuado) |
| Google | google/IdleWakeups |  | v0.1.0 | 2022-01-24 | - |  |  | repositorio archivado | - | - | no (descontinuado) | no (descontinuado) |
| Google | google/log4jscanner |  | v0.5.0 | 2022-05-25 | - |  |  | repositorio archivado | - | - | no (descontinuado) | no (descontinuado) |
| Google | google/sawbuck |  | release-0.6.8.0 | 2016-04-21 | - |  |  | repositorio archivado | - | - | no (descontinuado) | no (descontinuado) |
| Amazon | aws/copilot-cli |  | v1.34.1 | 2025-04-10 | - |  |  | repositorio archivado | Amazon.CopilotCLI 1.34.1 | - | no (descontinuado) | ya (descontinuado) |
| Amazon | aws/porting-assistant-dotnet-client |  | v2.9 | 2023-05-04 | - |  |  | repositorio archivado | - | - | no (descontinuado) | no (descontinuado) |
| Amazon | awslabs/amazon-qldb-shell |  | v2.0.2 | 2022-11-07 | - |  |  | repositorio archivado | - | - | no (descontinuado) | no (descontinuado) |
| Amazon | awslabs/aws-simple-ec2-cli |  | v0.12.0 | 2025-01-06 | - |  |  | repositorio archivado | - | - | no (descontinuado) | no (descontinuado) |
| Amazon | awslabs/aws-solutions-assembler |  | v0.14.0 | 2020-07-31 | - |  |  | repositorio archivado | - | - | no (descontinuado) | no (descontinuado) |
| Amazon | awslabs/eksdemo |  | v0.18.2 | 2025-02-14 | - |  |  | repositorio archivado | - | tar.gz | no (descontinuado) | no (descontinuado) |
| Amazon | awslabs/fargatecli |  | 0.3.2 | 2019-09-05 | - |  |  | repositorio archivado | - | - | no (descontinuado) | no (descontinuado) |

## Indice de winget

| Fabricante | Instalar | Version | Chocolatey | Se puede (choco) |
| :--- | :--- | :--- | :--- | :--- |
| Mozilla | Mozilla.CrashFirefoxIntentionally | 1 | - | si |
| Mozilla | Mozilla.Firefox | 157.0.1 | firefox 159.0.0 | ya |
| Mozilla | Mozilla.Firefox.Beta.MSIX | 153.0.11 | firefox-beta 153.0.5-beta | ya |
| Mozilla | Mozilla.Firefox.DeveloperEdition | 156.0 | firefox-dev 160.0.2-beta | ya |
| Mozilla | Mozilla.Firefox.DeveloperEdition.MSIX | 158.0.5.0 | firefox-dev 160.0.2-beta | ya |
| Mozilla | Mozilla.Firefox.ESR | 153.4.0 | firefoxesr 153.6.0 | ya |
| Mozilla | Mozilla.Firefox.ESR.MSIX | 153.4.0 | firefoxesr 153.6.0 | ya |
| Mozilla | Mozilla.Firefox.MSIX | 157.0.1 | firefox 159.0.0 | ya |
| Mozilla | Mozilla.Firefox.Nightly.MSIX | 159.2610.709.0 | firefox-nightly 161.0.1.2026102909-alpha | ya |
| Mozilla | Mozilla.Firefox.Unbranded.Beta | 147.0b1 | - | si |
| Mozilla | Mozilla.Flowstate | 106.0a1 | - | si |
| Mozilla | Mozilla.GeckoDriver | 0.37.1 | selenium-gecko-driver 0.37.1 | ya |
| Mozilla | Mozilla.jsshell | 147.0.3 | jsshell 86.0 | ya (atrasado) |
| Mozilla | Mozilla.llamafile | 0.10.6 | - | si |
| Mozilla | Mozilla.mozregression | 7.3 | - | si |
| Mozilla | Mozilla.Nimbus.CLI | 148.0.1 | - | si |
| Mozilla | Mozilla.Nimbus.FML | 148.0.1 | - | si |
| Mozilla | Mozilla.opus-tools | 0.2 | opus-tools 0.2.0.20221010 | ya |
| Mozilla | Mozilla.ProfileManager | 1.0 | - | si |
| Mozilla | Mozilla.sccache | 0.18.0 | sccache 0.19.0 | ya |
| Mozilla | Mozilla.SeaMonkey | 2.53.24 | seamonkey 2.53.24 | ya |
| Mozilla | Mozilla.Thunderbird | 157.0.1 | thunderbird 159.0.0 | ya |
| Mozilla | Mozilla.Thunderbird.Beta.MSIX | 148.0.6 | thunderbird-mozilla 160.0.0-beta2 | ya (este repositorio) |
| Mozilla | Mozilla.Thunderbird.ESR | 153.4.0 | thunderbirdesr 153.6.0 | ya |
| Mozilla | Mozilla.Thunderbird.ESR.MSIX | 153.4.0 | thunderbirdesr 153.6.0 | ya |
| Mozilla | Mozilla.Thunderbird.MSIX | 157.0.1 | thunderbird 159.0.0 | ya |
| Mozilla | Mozilla.VPN | 2.39.0 | - | si |
| Mozilla | Mozilla.XULRunner | 41.0.2 | - | no (Mozilla lo retiro en 2015) |
| Cloudflare | Cloudflare.cloudflared | 2026.10.0 | cloudflared 2026.10.5 | ya |
| Cloudflare | Cloudflare.Warp | 26.8.2100.0 | warp 2026.8.2115 | ya |
| GitHub | GitHub.Atom | 1.60.0 | atom 1.60.0 | ya (descontinuado) |
| GitHub | GitHub.Atom.Beta | 1.61.0-beta0 | - | no (descontinuado) |
| GitHub | GitHub.ClassroomAssistant | 2.0.4 | - | si |
| GitHub | GitHub.cli | 2.102.0 | gh 2.103.3 | ya |
| GitHub | GitHub.Copilot | v1.0.93 | github-copilot-cli 1.0.104 | ya |
| GitHub | GitHub.Copilot.modernization.agent | 1.0.74 | - | si |
| GitHub | GitHub.Copilot.Prerelease | v1.0.78-3 | - | si |
| GitHub | GitHub.CopilotApp | 1.1.27 | github-copilot-app 1.1.33 | ya |
| GitHub | GitHub.GitHubDesktop | 3.6.6 | github-desktop 3.6.7 | ya |
| GitHub | GitHub.GitHubDesktop.Beta | 3.5.5-beta2 | github-desktop-pre 3.6.10-beta1 | ya (este repositorio) |
| GitHub | GitHub.GitLFS | 3.8.0 | git-lfs 3.8.1 | ya |
| GitHub | GitHub.git-sizer | 1.5.0 | git-sizer 1.5.0 | ya |
| GitHub | GitHub.hub | 2.14.2 | hub 2.14.2 | ya (descontinuado) |
| GitHub | GitHub.smimesign | 0.2.0 | smimesign 0.2.0 | ya |
| Google | Google.AdsEditor | 14.13.4.0 | - | si |
| Google | Google.AndroidCLI | 1.0.16500706 | - | si |
| Google | Google.AndroidGPUInspector | 3.3.3 | - | si |
| Google | Google.AndroidStudio | 2026.2.1.8 | androidstudio 2025.2.3.9 | ya |
| Google | Google.AndroidStudio.Beta | 2026.2.1.7 | - | si |
| Google | Google.AndroidStudio.Canary | 2026.2.2.3 | - | si |
| Google | Google.Antigravity | 2.21.1 | antigravity 2.28.1 | ya |
| Google | Google.AntigravityCLI | 1.3.1 | antigravity-cli 1.4.10 | ya |
| Google | Google.AntigravityIDE | 2.5.5 | antigravity-ide 2.6.0 | ya |
| Google | Google.Brotli | 1.2.0 | - | si |
| Google | Google.Chrome | 155.0.8059.40 | googlechrome 157.0.8103.27 | ya |
| Google | Google.Chrome.Beta | 156.0.8078.17 | googlechromebeta 120.0.6099.56-beta | ya (atrasado) |
| Google | Google.Chrome.Beta.EXE | 156.0.8078.4 | googlechromebeta 120.0.6099.56-beta | ya (atrasado) |
| Google | Google.Chrome.Canary | 157.0.8091.0 | googlechromecanary 159.0.8130-canary | ya |
| Google | Google.Chrome.Dev | 157.0.8081.0 | googlechromedev 158.0.8117.2-dev | ya |
| Google | Google.Chrome.Dev.EXE | 157.0.8081.0 | googlechromedev 158.0.8117.2-dev | ya |
| Google | Google.Chrome.EXE | 155.0.8059.40 | googlechrome 157.0.8103.27 | ya |
| Google | Google.ChromeOSReadinessToolBundle | 1.0.4.0 | - | si |
| Google | Google.ChromeRemoteDesktopHost | 154.0.8037.40 | chrome-remote-desktop-host 154.0.8037.40 | ya |
| Google | Google.CloudSDK | 588.0.0 | gcloudsdk 590.0.1 | ya |
| Google | Google.ContainerTools.Skaffold | 2.25.0 | skaffold 2.25.0 | ya |
| Google | Google.CredentialProviderForWindows | 150.0.7871.100 | - | si |
| Google | Google.DartSDK | 3.13.4 | dart-sdk 3.13.7 | ya |
| Google | Google.EarthPro | 7.3.7.1327 | googleearthpro 7.3.6.20250917 | ya |
| Google | Google.FirebaseCLI | 20.18.2 | - | si |
| Google | Google.flatbuffers | 25.12.19 | flatc 1.12.0 | ya (atrasado) |
| Google | Google.GeminiDesktop | 1.14.0 | gemini-desktop 1.16.0 | ya |
| Google | Google.GoogleDesktop | 5.9.1005.12335 | - | no (Google lo retiro en 2011) |
| Google | Google.GoogleDrive | 132.0.0.0 | googledrive 133.0.2 | ya |
| Google | Google.GoogleUpdater | 156.0.8067.0 | - | no (lo instalan Chrome y los demas programas de Google) |
| Google | Google.GoogleWebDesigner | 14.3.2.0 | google-web-designer 5.0.4.0226 | ya |
| Google | Google.IAPDesktop | 2.50.1825 | - | si |
| Google | Google.JapaneseIME | 3.34.6260.0 | googlejapaneseinput 1.3.24.20141007 | ya (atrasado) |
| Google | Google.Libwebp | 1.6.0 | webp 1.0.0 | ya (atrasado) |
| Google | Google.Magika | 1.1.0 | - | si |
| Google | Google.OSVScanner | 2.6.0 | osv-scanner 1.6.2 | ya (atrasado) |
| Google | Google.Perfetto | 58.2 | - | si |
| Google | Google.Picasa | 3.9.136.200 | - | no (Google lo retiro en 2016) |
| Google | Google.Pinyin | 2.7.25.128 | google-pinyin 1.0 | ya |
| Google | Google.PlatformTools | 37.0.1 | adb 37.0.0 | ya |
| Google | Google.PlayGames | 156.0.8067.0 | - | si |
| Google | Google.Protobuf | 36.0 | protoc 36.2.0 | ya |
| Google | Google.QuickShare | 1.0.2697.0 | - | si |
| Google | Google.Talk | 1.0.0.105 | - | no (Google lo retiro) |
| Google | Google.UIforETW | 1.59 | uiforetw 1.59 | ya |
| Google | Google.VPNByGoogleOne | 1.9.0.6 | - | no (Google lo retiro en 2024) |
| Google | Google.WorkspaceCLI | 0.22.5 | - | si |
| Google | Google.WorkspaceSyncForMicrosoftOutlook | 4.3.99.0 | google-workspace-sync 4.3.53.0 | ya |
| Amazon | Amazon.AppStream | 1.4.0 | amazon-appstream 1.1.294 | ya |
| Amazon | Amazon.AthenaODBCDriver.1 | 1.3.7.10001 | - | si |
| Amazon | Amazon.AthenaODBCDriver.2 | 2.4.0.0 | - | si |
| Amazon | Amazon.AWSCLI | 2.37.10 | awscli 2.39.1 | ya |
| Amazon | Amazon.AWSCloudHSM.CLI | 5.18.0 | - | si |
| Amazon | Amazon.AWSCloudHSM.JCE | 5.18.0 | - | si |
| Amazon | Amazon.AWSCloudHSM.KSP | 5.18.0 | - | si |
| Amazon | Amazon.AWSCloudHSM.PKCS11 | 5.18.0 | - | si |
| Amazon | Amazon.AWSVPNClient | 6.1.1 | - | si |
| Amazon | Amazon.Chime | 5.23.32138 | amazon-chime 5.23.31911 | ya |
| Amazon | Amazon.CloudWatchAgent | 1.4.37929 | - | si |
| Amazon | Amazon.CopilotCLI | 1.34.1 | - | no (descontinuado) |
| Amazon | Amazon.Corretto.11.JDK | 11.0.32.12 | corretto11jdk 11.0.33.10 | ya |
| Amazon | Amazon.Corretto.17.JDK | 17.0.20.12 | corretto17jdk 17.0.21.11 | ya |
| Amazon | Amazon.Corretto.18.JDK | 18.0.2.9 | - | no tiene sentido (sin soporte del fabricante) |
| Amazon | Amazon.Corretto.19.JDK | 19.0.2.7 | - | no tiene sentido (sin soporte del fabricante) |
| Amazon | Amazon.Corretto.20.JDK | 20.0.2.10 | - | no tiene sentido (sin soporte del fabricante) |
| Amazon | Amazon.Corretto.21.JDK | 21.0.12.12 | corretto21jdk 21.0.13.11 | ya |
| Amazon | Amazon.Corretto.22.JDK | 22.0.2.9 | - | no tiene sentido (sin soporte del fabricante) |
| Amazon | Amazon.Corretto.23.JDK | 23.0.2.7 | - | no tiene sentido (sin soporte del fabricante) |
| Amazon | Amazon.Corretto.24.JDK | 24.0.2.12 | - | no tiene sentido (sin soporte del fabricante) |
| Amazon | Amazon.Corretto.25.JDK | 25.0.4.10 | corretto25jdk 25.0.5.10 | ya |
| Amazon | Amazon.Corretto.26.JDK | 26.0.2.11 | - | si |
| Amazon | Amazon.Corretto.8.JDK | 1.8.0.504 | corretto8jdk 8.512.9.1 | ya |
| Amazon | Amazon.Corretto.8.JRE | 1.8.0.504 | corretto8jre 8.512.9.1 | ya |
| Amazon | Amazon.EC2Launch | 2.5.2.0 | - | si |
| Amazon | Amazon.Games | 3.0.9700.3 | - | si |
| Amazon | Amazon.Kindle | 2.9.1.71006 | kindle 2.9.71006 | ya |
| Amazon | Amazon.KindlePreviewer | 3.107.0 | kindlepreviewer 3.82.0 | ya |
| Amazon | Amazon.Kiro | 1.2.37 | kiro 1.4.62 | ya |
| Amazon | Amazon.LLRT | 0.8.1-beta | llrt 0.9.0-beta | ya |
| Amazon | Amazon.Music | 9.4.0.2386 | amazon-music 9.5.2.2478 | ya |
| Amazon | Amazon.NoSQLWorkbench | 3.20.3 | nosql-workbench 3.20.2 | ya |
| Amazon | Amazon.OpenSearch.ODBC | 1.1.0.1 | - | si |
| Amazon | Amazon.Quick | 1.1.3753 | - | si |
| Amazon | Amazon.Redshift.ODBC.v1 | 1.5.20.1024 | redshift-odbc 1.5.16.1019 | ya |
| Amazon | Amazon.Redshift.ODBC.v2 | 2.2.4.0 | - | si |
| Amazon | Amazon.SAM-CLI | 1.167.0 | awssamcli 1.145.0 | ya |
| Amazon | Amazon.SendToKindle | 1.1.1.260 | sendtokindle 1.1.1.253 | ya |
| Amazon | Amazon.SessionManagerPlugin | 1.2.835.0 | awscli-session-manager 1.2.896 | ya |
| Amazon | Amazon.SSMAgent | 3.3.5226.0 | - | si |
| Amazon | Amazon.WorkspacesClient | 5.34.1.2887 | amazon-workspaces 5.36.0.3628 | ya |
| Cursor (Anysphere) | Anysphere.Cursor | 3.19.7 | cursoride 3.27.22 | ya |
| Fenix (Corey Butler) | CoreyButler.NVMforWindows | 1.2.2 | nvm 1.2.2.20251229 | ya |

