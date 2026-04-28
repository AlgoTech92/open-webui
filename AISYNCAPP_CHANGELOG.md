## AiSyncApp Changelog

All modifications to the open-webui codebase for AiSyncApp integration.

---

### Change #3: Integrate Open Computer Use MCP (Visual UI + Backend)

**Date:** 2025-04-28  
**Author:** AiSyncApp Bot  
**Purpose:** Add visual Computer Use features (browser viewer, file previews, sub-agent dashboard) and connect to upstream MCP server on Coolify

**Files Added:**
- `computer-use-init/tools/computer_use_tools.py` — MCP client tool (points to upstream MCP server via COMPUTER_USE_ORCHESTRATOR_URL env var)
- `computer-use-init/functions/computer_link_filter.py` — System prompt injection + file preview links
- `computer-use-init/init.sh` — Auto-install script for tools/filters at startup

**Files Modified:**
- `computer-use-init/tools/computer_use_tools.py` — Updated Valves to read ORCHESTRATOR_URL and MCP_API_KEY from environment variables (points to Coolify-deployed MCP server)

**Rollback:**
```bash
# Remove the computer-use-init directory
rm -rf computer-use-init/

# Note: Tools/filters installed by init.sh will need to be removed manually via Open WebUI UI
# (Workspace → Tools → Delete "ai_computer_use", Workspace → Functions → Delete "computer_use_filter")
```

**Verification:**
1. Set env vars: `COMPUTER_USE_ORCHESTRATOR_URL=https://ur-coolify-domain.com:8081` and `COMPUTER_USE_MCP_API_KEY=ur-key`
2. Start AiSyncApp — init.sh auto-installs the tool + filter
3. Chat with any model — Computer Use tools appear (bash, create_file, sub_agent, etc.)
4. Browser viewer, file previews, and sub-agent dashboard are now available!

---

### Change #2: Add Qdrant, n8n, Supabase Integration Fields
**Date:** 2024-04-28  
**Author:** AiSyncapp Team (via Hermes Agent)  
**File:** `backend/open_webui/models/models.py`  
**Status:** ✅ APPLIED

### What Changed
Added AiSyncapp-specific fields to the `ModelMeta` Pydantic model class:
- `domain: Optional[str]` - Vertical/domain (e.g., "real-estate", "medical")
- `skills: Optional[list[str]]` - List of skill tags
- `hourly_rate: Optional[int]` - Pricing in dollars
- `bio: Optional[str]` - AI Employee bio
- `experience_level: Optional[str]` - "junior", "senior", "principal"
- `is_ai_employee: Optional[bool]` - Flag to identify AI Employees

### Why
The `Model` table in open-webui maps perfectly to AiSyncapp's "AI Employees" concept. These fields enable storing domain, skills, pricing, and other employee-specific metadata in the existing `meta` JSON field.

### Rollback Instructions
1. Open `backend/open_webui/models/models.py`
2. Find lines between `# === AISYNCAPP MODIFICATION START ===` and `# === AISYNCAPP MODIFICATION END ===`
3. Delete everything between (and including) those comment blocks
4. The file will be restored to original open-webui state

### Compatibility
- ✅ All fields are Optional with defaults (backward compatible)
- ✅ `extra='allow'` is preserved in model_config
- ✅ No changes to database schema (uses existing JSON field)

---

## How to Apply These Changes

### Option A: Download Modified Files (Recommended for non-git users)
1. I will provide the full file path after each change
2. You download that file from this environment
3. Replace the same file in your local open-webui repo

### Option B: Manual Copy-Paste
1. Open the changelog entry above
2. Copy the described changes
3. Apply manually to your local repo

---

## File Transfer Instructions

After each change, I will provide:
- ✅ The **exact file path** in my environment
- ✅ A **verification command** to confirm the change
- ✅ The **rollback steps** if needed

---

## Change #2: Add Integration Fields (Qdrant, n8n, Supabase)
**Date:** 2024-04-28  
**Author:** AiSyncapp Team (via Hermes Agent)  
**File:** `backend/open_webui/models/models.py`  
**Status:** ✅ APPLIED

### What Changed
Added integration fields to `ModelMeta` (within the same modification block as Change #1):
- `qdrant_collection_id: Optional[str]` - Links to self-hosted Qdrant vector collection
- `n8n_onboarding_workflow_id: Optional[str]` - Triggers n8n workflow when hired
- `supabase_profile_table: Optional[str]` - Supabase table for contracts/audit logs

### Why
Connects each AI Employee to the AiSyncapp infrastructure stack. Enables RAG via Qdrant, automated onboarding via n8n, and data persistence via Supabase.

### Rollback Instructions
Same as Change #1: Remove the entire block between `# === AISYNCAPP MODIFICATION START ===` and `# === AISYNCAPP MODIFICATION END ===`.

### Compatibility
- ✅ Fields are Optional with defaults
- ✅ Stored in existing `meta` JSON field
- ✅ No database schema changes

---

**Next Change:** TBD (Frontend rebrand? User role modifications? Waiting for user direction)
