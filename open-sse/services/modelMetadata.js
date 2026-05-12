/**
 * Model metadata including context window sizes
 */

// Static fallback metadata
const STATIC_MODEL_METADATA = {
  // Anthropic Claude
  "anthropic/claude-opus-4": { contextWindow: 200000, tier: "large" },
  "anthropic/claude-sonnet-4": { contextWindow: 200000, tier: "large" },
  "anthropic/claude-haiku-4": { contextWindow: 200000, tier: "medium" },
  "anthropic/claude-3-5-sonnet-20241022": { contextWindow: 200000, tier: "large" },
  "anthropic/claude-3-5-haiku-20241022": { contextWindow: 200000, tier: "medium" },
  "anthropic/claude-3-opus-20240229": { contextWindow: 200000, tier: "large" },
  "anthropic/claude-3-sonnet-20240229": { contextWindow: 200000, tier: "large" },
  "anthropic/claude-3-haiku-20240307": { contextWindow: 200000, tier: "medium" },

  // OpenAI
  "openai/gpt-4": { contextWindow: 8192, tier: "small" },
  "openai/gpt-4-turbo": { contextWindow: 128000, tier: "large" },
  "openai/gpt-4o": { contextWindow: 128000, tier: "large" },
  "openai/gpt-4o-mini": { contextWindow: 128000, tier: "medium" },
  "openai/gpt-3.5-turbo": { contextWindow: 16385, tier: "small" },
  "openai/o1": { contextWindow: 200000, tier: "large" },
  "openai/o1-mini": { contextWindow: 128000, tier: "medium" },

  // Google
  "google/gemini-2.0-flash-exp": { contextWindow: 1000000, tier: "large" },
  "google/gemini-1.5-pro": { contextWindow: 2000000, tier: "large" },
  "google/gemini-1.5-flash": { contextWindow: 1000000, tier: "large" },
  "google/gemini-pro": { contextWindow: 32000, tier: "medium" },
};

// Runtime cache with TTL
let cachedMetadata = null;
let cacheTimestamp = 0;
const CACHE_TTL_MS = 24 * 60 * 60 * 1000; // 24 hours

/**
 * Get model metadata (from cache or static fallback)
 * @param {string} modelStr - Model string (provider/model format)
 * @returns {{ contextWindow: number, tier: string } | null}
 */
export function getModelMetadata(modelStr) {
  const metadata = cachedMetadata || STATIC_MODEL_METADATA;
  return metadata[modelStr] || null;
}

/**
 * Filter models by minimum context window requirement
 * @param {string[]} models - Array of model strings
 * @param {number} requiredContext - Required context size in tokens
 * @returns {string[]} Filtered models that can handle the context
 */
export function filterModelsByContext(models, requiredContext) {
  if (!requiredContext || requiredContext <= 0) return models;

  const filtered = models.filter(modelStr => {
    const metadata = getModelMetadata(modelStr);
    if (!metadata) return true; // Keep unknown models
    return metadata.contextWindow >= requiredContext;
  });

  // If all filtered out, return original (fallback to trying anyway)
  return filtered.length > 0 ? filtered : models;
}

/**
 * Estimate context size from request body
 * @param {Object} body - Request body with messages
 * @returns {number} Estimated token count
 */
export function estimateContextSize(body) {
  if (!body?.messages || !Array.isArray(body.messages)) return 0;

  let totalChars = 0;
  for (const msg of body.messages) {
    if (msg.content) {
      if (typeof msg.content === "string") {
        totalChars += msg.content.length;
      } else if (Array.isArray(msg.content)) {
        for (const part of msg.content) {
          if (part.type === "text" && part.text) {
            totalChars += part.text.length;
          }
        }
      }
    }
  }

  // Rough estimate: 1 token ≈ 4 characters
  return Math.ceil(totalChars / 4);
}

/**
 * Fetch OpenAI models metadata
 * @param {string} apiKey - OpenAI API key
 * @returns {Promise<Object>} Model metadata map
 */
async function fetchOpenAIModels(apiKey) {
  try {
    const response = await fetch("https://api.openai.com/v1/models", {
      headers: { "Authorization": `Bearer ${apiKey}` }
    });
    if (!response.ok) return {};

    const data = await response.json();
    const metadata = {};

    for (const model of data.data || []) {
      const id = model.id;
      let contextWindow = 8192;
      let tier = "small";

      if (id.includes("gpt-4o")) {
        contextWindow = 128000;
        tier = id.includes("mini") ? "medium" : "large";
      } else if (id.includes("gpt-4-turbo") || id.includes("gpt-4-1106")) {
        contextWindow = 128000;
        tier = "large";
      } else if (id.includes("o1")) {
        contextWindow = id.includes("mini") ? 128000 : 200000;
        tier = id.includes("mini") ? "medium" : "large";
      } else if (id.includes("gpt-3.5")) {
        contextWindow = 16385;
        tier = "small";
      }

      metadata[`openai/${id}`] = { contextWindow, tier };
    }

    return metadata;
  } catch (error) {
    console.warn("[ModelMetadata] Failed to fetch OpenAI models:", error.message);
    return {};
  }
}

/**
 * Fetch Google/Gemini models metadata
 * @param {string} apiKey - Google API key
 * @returns {Promise<Object>} Model metadata map
 */
async function fetchGoogleModels(apiKey) {
  try {
    const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models?key=${apiKey}`);
    if (!response.ok) return {};

    const data = await response.json();
    const metadata = {};

    for (const model of data.models || []) {
      const name = model.name.replace("models/", "");
      const contextWindow = model.inputTokenLimit || 32000;

      let tier = "medium";
      if (contextWindow >= 1000000) tier = "large";
      else if (contextWindow < 100000) tier = "small";

      metadata[`google/${name}`] = { contextWindow, tier };
    }

    return metadata;
  } catch (error) {
    console.warn("[ModelMetadata] Failed to fetch Google models:", error.message);
    return {};
  }
}

/**
 * Refresh model metadata cache from provider APIs
 * @param {Object} credentials - API credentials { openaiKey, anthropicKey, googleKey }
 * @returns {Promise<void>}
 */
export async function refreshModelMetadata(credentials = {}) {
  try {
    const now = Date.now();

    // Skip if cache is still fresh
    if (cachedMetadata && (now - cacheTimestamp) < CACHE_TTL_MS) {
      return;
    }

    console.log("[ModelMetadata] Refreshing model metadata...");

    // Fetch from providers in parallel
    const [openaiData, googleData] = await Promise.all([
      credentials.openaiKey ? fetchOpenAIModels(credentials.openaiKey) : Promise.resolve({}),
      credentials.googleKey ? fetchGoogleModels(credentials.googleKey) : Promise.resolve({})
    ]);

    // Merge with static fallback
    cachedMetadata = {
      ...STATIC_MODEL_METADATA,
      ...openaiData,
      ...googleData
    };

    cacheTimestamp = now;
    console.log("[ModelMetadata] Cache refreshed with", Object.keys(cachedMetadata).length, "models");
  } catch (error) {
    console.warn("[ModelMetadata] Refresh failed:", error.message);
    // Keep using static fallback
  }
}

/**
 * Initialize model metadata (call on startup)
 * @param {Object} credentials - API credentials
 */
export async function initModelMetadata(credentials = {}) {
  await refreshModelMetadata(credentials);

  // Schedule periodic refresh (24h)
  setInterval(() => {
    refreshModelMetadata(credentials).catch(err =>
      console.warn("[ModelMetadata] Periodic refresh failed:", err.message)
    );
  }, CACHE_TTL_MS);
}
