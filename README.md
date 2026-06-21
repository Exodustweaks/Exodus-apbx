<div align="center">

# EXODUS TWEAKS

### Playbooks da comunidade AME com suporte ao Windows 10

[![Site](https://img.shields.io/badge/Site-ExodusTweaks-red?style=for-the-badge&logo=vercel&logoColor=white)](https://exodus-apbx.vercel.app/)
[![GitHub](https://img.shields.io/badge/GitHub-Exodus--apbx-black?style=for-the-badge&logo=github)](https://github.com/Exodustweaks/Exodus-apbx)
[![License](https://img.shields.io/badge/License-GPLv3-blue?style=for-the-badge)](LICENSE)
[![Windows](https://img.shields.io/badge/Windows-10%20%7C%2011-green?style=for-the-badge&logo=windows)]()
[![AME](https://img.shields.io/badge/AME%20Wizard-Compatible-orange?style=for-the-badge)](https://github.com/Ameliorated-LLC/trusted-uninstaller-cli)

</div>

---

## O que e?

Playbooks `.apbx` da comunidade AME (AtlasOS, ReviOS, RapidOS, etc.) modificados por **kelvenapk** para adicionar **suporte nativo ao Windows 10** (Build 19041+). Scripts internos identicos aos originais.

> Modificacao unica: compatibilidade com Win 10. Nenhum codigo malicioso adicionado.

## Playbooks Disponiveis

| Playbook | Categoria | Versao | Download | Codigo |
|----------|-----------|--------|----------|--------|
| **AtlasOS** | Performance/Gaming | v0.5.1 RC2 | [Baixar](https://raw.githubusercontent.com/Exodustweaks/Exodus-apbx/main/playbooks/AtlasOS%20v0.5.1%20RC2.apbx) | [Codigo](https://github.com/Exodustweaks/Exodus-apbx/tree/main/codigo%20dos%20playbooks/AtlasOS%20v0.5.1%20RC2) |
| **AtmosphereOS** | Gaming | latest | [Baixar](https://raw.githubusercontent.com/Exodustweaks/Exodus-apbx/main/playbooks/AtmosphereOS.apbx) | [Codigo](https://github.com/Exodustweaks/Exodus-apbx/tree/main/codigo%20dos%20playbooks/AtmosphereOS) |
| **AtomPlayBook** | Leve | v0.0.5 | [Baixar](https://github.com/Exodustweaks/Exodus-apbx/releases/latest) | [Codigo](https://github.com/Exodustweaks/Exodus-apbx/tree/main/codigo%20dos%20playbooks/AtomPlayBook.v0.0.5) |
| **Eternity OS** | Gaming/Performance | v1.4 | [Baixar](https://raw.githubusercontent.com/Exodustweaks/Exodus-apbx/main/playbooks/Eternity.v1.4.apbx) | [Codigo](https://github.com/Exodustweaks/Exodus-apbx/tree/main/codigo%20dos%20playbooks/Eternity.v1.4) |
| **FSOS-XR6.3** | Performance/Gaming | 6.3 | [Baixar](https://github.com/Exodustweaks/Exodus-apbx/releases/latest) | [Codigo](https://github.com/Exodustweaks/Exodus-apbx/tree/main/codigo%20dos%20playbooks/FSOS-XR6.3) |
| **NovaOS** | Gaming | V4 | [Baixar](https://raw.githubusercontent.com/Exodustweaks/Exodus-apbx/main/playbooks/NovaOS-V4.apbx) | [Codigo](https://github.com/Exodustweaks/Exodus-apbx/tree/main/codigo%20dos%20playbooks/NovaOS-V4) |
| **PeakOS** | Performance | v1.0.2 | [Baixar](https://raw.githubusercontent.com/Exodustweaks/Exodus-apbx/main/playbooks/PeakOS%20V1.0.2.apbx) | [Codigo](https://github.com/Exodustweaks/Exodus-apbx/tree/main/codigo%20dos%20playbooks/PeakOS%20V1.0.2) |
| **RapidOS** | Privacy/Performance | latest | [Baixar](https://raw.githubusercontent.com/Exodustweaks/Exodus-apbx/main/playbooks/RapidOS.apbx) | [Codigo](https://github.com/Exodustweaks/Exodus-apbx/tree/main/codigo%20dos%20playbooks/RapidOS) |
| **RaxOS** | Gaming | latest | [Baixar](https://raw.githubusercontent.com/Exodustweaks/Exodus-apbx/main/playbooks/RaxOS.apbx) | [Codigo](https://github.com/Exodustweaks/Exodus-apbx/tree/main/codigo%20dos%20playbooks/RaxOS) |
| **ReviOS** | Privacy/Performance | 26.04 | [Baixar](https://raw.githubusercontent.com/Exodustweaks/Exodus-apbx/main/playbooks/Revi-PB-26.04.apbx) | [Codigo](https://github.com/Exodustweaks/Exodus-apbx/tree/main/codigo%20dos%20playbooks/Revi-PB-26.04) |
| **SapphireOS** | Performance/Gaming | latest | [Baixar](https://raw.githubusercontent.com/Exodustweaks/Exodus-apbx/main/playbooks/SapphireOS.apbx) | [Codigo](https://github.com/Exodustweaks/Exodus-apbx/tree/main/codigo%20dos%20playbooks/SapphireOS) |
| **SOS** | Leve | 0.2.3 | [Baixar](https://raw.githubusercontent.com/Exodustweaks/Exodus-apbx/main/playbooks/SOS%200.2.3.apbx) | [Codigo](https://github.com/Exodustweaks/Exodus-apbx/tree/main/codigo%20dos%20playbooks/SOS%200.2.3) |
| **XOS** | Gaming | v0.445 | [Baixar](https://raw.githubusercontent.com/Exodustweaks/Exodus-apbx/main/playbooks/XOS%20v0.445.apbx) | [Codigo](https://github.com/Exodustweaks/Exodus-apbx/tree/main/codigo%20dos%20playbooks/XOS%20v0.445) |

> **AtomPlayBook** e **FSOS-XR6.3** excedem 100MB e estao na pasta [Releases](https://github.com/Exodustweaks/Exodus-apbx/releases/latest).

## Como Usar

1. **Instale o AME Wizard Beta**
   ```
   winget install AmelioratedLLC.TrustedUninstallerCLI
   ```
   Ou baixe direto: [AME Wizard Beta](https://github.com/Ameliorated-LLC/trusted-uninstaller-cli/releases/tag/0.8.4)

2. **Desative o Windows Defender** temporariamente (falso positivo)

3. **Baixe** o playbook desejado

4. **Execute o AME Beta** e carregue o arquivo `.apbx`

5. **Reinicie** o PC apos a aplicacao

## Suporte

| Sistema | Status |
|---------|--------|
| Windows 10 Build 19041+ (21H2/22H2) | Compativel |
| Windows 11 | Compativel |
| Home & Pro | Compativel |

## Por que o Antivirus Detecta?

Arquivos `.apbx` modificam configuracoes profundas do Windows. Qualquer ferramenta que faca isso e sinalizada automaticamente. Isso ocorre com **AtlasOS oficial**, **ReviOS oficial** e todos os projetos AME. E um **falso positivo**.

**O que fazer:**
- Desative o Defender antes de aplicar
- Execute como Administrador
- Crie ponto de restauracao antes

## Estrutura do Repositorio

```
Exodus-apbx/
├── index.html              # Site oficial
├── playbooks/              # Playbooks .apbx para download
├── codigo dos playbooks/   # Codigo fonte de cada playbook
├── aviso.png               # Imagem de aviso
├── .gitattributes          # Configuracao Git LFS
└── LICENSE                 # GPLv3
```

## Contribuicao

1. Fork o repositorio
2. Crie uma branch (`git checkout -b feature/nova-feature`)
3. Commit suas mudancas (`git commit -m 'Adiciona nova feature'`)
4. Push para a branch (`git push origin feature/nova-feature`)
5. Abra um Pull Request

## Contato

- **Site**: [exodus-apbx.vercel.app](https://exodus-apbx.vercel.app/)
- **GitHub**: [Exodustweaks/Exodus-apbx](https://github.com/Exodustweaks/Exodus-apbx)
- **Issues**: [Reportar Bug](https://github.com/Exodustweaks/Exodus-apbx/issues)

---

<div align="center">

**Modificado por [kelvenapk](https://github.com/kelvenapk)** | **13 Playbooks** | **Win 10 + 11** | **100% Gratuito**

</div>
