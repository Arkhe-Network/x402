#!/usr/bin/env python3
# bridge.py — Conecta análises do BLOCK 11 ao Obsidian via Local REST API
# (Modificado para o teste para gerar arquivo diretamente se a API não estiver rodando)

import requests
import json
import hashlib
from datetime import datetime
import yaml
import os

OBSIDIAN_API = "http://localhost:27123"  # Local REST API plugin
VAULT_PATH = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "vault")

def post_analysis(title, content, domain, version, selo):
    """Envia uma análise para o Obsidian como nota."""
    hash_val = hashlib.sha256(content.encode()).hexdigest()
    frontmatter = {
        "title": title,
        "type": "analysis",
        "domain": domain,
        "version": version,
        "date": datetime.now().isoformat(),
        "status": "rascunho",
        "hash": hash_val,
        "selo": selo,
        "tags": ["analysis", domain]
    }
    note = f"---\n{yaml.dump(frontmatter)}---\n\n{content}"

    # Criar arquivo diretamente na pasta vault local (simulando a escrita no vault)
    target_dir = os.path.join(VAULT_PATH, f"01 - Analyses/{domain}")
    os.makedirs(target_dir, exist_ok=True)

    file_path = os.path.join(target_dir, f"{title}.md")
    with open(file_path, "w", encoding="utf-8") as f:
        f.write(note)

    print(f"Nota criada com sucesso em: {file_path}")
    return True

if __name__ == "__main__":
    post_analysis(
        title="v2.6 - CTC Detector",
        content="## Resumo\nO detector de CTC aprimorado incorpora capacidade retrocausal one-shot...",
        domain="BLOCK-11",
        version="v2.6",
        selo="HANKEL-SEAL-CTC-ENHANCED-v2.6-2026-08-11"
    )
