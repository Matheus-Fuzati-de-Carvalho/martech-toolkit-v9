// includes/data.js
const v = dataform.projectConfig.vars;

module.exports = {
  project_id: dataform.projectConfig.defaultDatabase,
  
  // --- Datasets (Schemas) ---
  silver_schema: v.silver_schema || "TRUSTED",
  refined_schema: v.refined_schema || "REFINED",
  quality_schema: v.quality_schema || "QUALITY",
  
  // --- Fontes Brutas (Raw) ---
  raw_ga4_project: v.raw_ga4_project || dataform.projectConfig.defaultDatabase,
  raw_ga4_dataset: v.raw_ga4_dataset || "RAW_SRC_GA4_EXTERNAL",
  
  raw_ads_project: v.raw_ads_project || dataform.projectConfig.defaultDatabase,
  raw_ads_dataset: v.raw_ads_dataset || "RAW_SRC_ADS_EXTERNAL",
  raw_ads_table: v.raw_ads_table || "ad_CampaignBasicStats_987654321", // Tabela fixa p/ demo
  
  // --- Nomenclatura das Tabelas (Opcional, mas mantido p/ flexibilidade v8) ---
  tab_ft_ga4: v.tab_ft_ga4 || "FT_SIL_GA4_EVENTS",
  tab_ft_ads: v.tab_ft_ads || "FT_SIL_ADS_PERFORMANCE",
  tab_dm_mkt: v.tab_dm_mkt || "DM_GOLD_MARKETING_PERFORMANCE",
  tab_dm_retail: v.tab_dm_retail || "DM_GOLD_RETAIL_CUBE",
  
  // --- Parâmetros de Execução ---
  lookback_days: v.lookback_days || "3",
  
  // --- Controle de Flavor (Sabor) ---
  // Permite rodar apenas as tags específicas
  enable_marketing: ["marketing", "full"].includes(v.flavor || "full"),
  enable_retail: ["retail", "full"].includes(v.flavor || "full"),
  enable_quality: ["quality", "full", "marketing", "retail"].includes(v.flavor || "full")
};