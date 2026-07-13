# Snippet: Adicionar no método execute_tool e no mapa de comandos manuais (handle_manual)
# Não é um script Python completo
"""
elif tool_name == "spawn_subagent":
    purpose = arguments.get("purpose")
    tools = arguments.get("tools", [])
    result = self.mcp.call_tool("spawn_subagent", {"purpose": purpose, "tools": tools})
    console.print(f"[green]✅ Subagente criado: {result.get('id')} (propósito: {purpose})[/green]")

elif tool_name == "list_subagents":
    result = self.mcp.call_tool("list_subagents", {})
    console.print("[bold blue]📋 Subagentes ativos:[/bold blue]")
    for sub in result.get("subagents", []):
        console.print(f"   - {sub['id']} ({sub['purpose']}) - {'ativo' if sub['is_active'] else 'inativo'}")

elif tool_name == "terminate_subagent":
    sub_id = arguments.get("id")
    result = self.mcp.call_tool("terminate_subagent", {"id": sub_id})
    console.print(f"[green]✅ Subagente {sub_id} terminado[/green]")

elif tool_name == "execute_subagent":
    sub_id = arguments.get("id")
    task = arguments.get("task")
    result = self.mcp.call_tool("execute_subagent", {"id": sub_id, "task": task})
    console.print(f"[green]✅ Tarefa executada no subagente {sub_id}: atestado {result.get('attestation_id')}[/green]")

# Adicionar no mapa de comandos manuais (handle_manual)
elif "spawn" in user_input and "subagent" in user_input:
    purpose = user_input.split("spawn")[1].strip().split()[0] if len(user_input.split()) > 1 else "default"
    self.execute_tool("spawn_subagent", {"purpose": purpose})

elif "list" in user_input and "subagent" in user_input:
    self.execute_tool("list_subagents", {})

elif "terminate" in user_input and "subagent" in user_input:
    parts = user_input.split()
    if len(parts) > 1:
        sub_id = parts[1]
        self.execute_tool("terminate_subagent", {"id": sub_id})
"""
