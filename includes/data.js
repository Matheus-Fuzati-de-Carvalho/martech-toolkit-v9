// includes/data.js
const v = dataform.projectConfig.vars;

// Se v.silver_schema não existir, ele usa o fallback. 
// Mas no Workflow, o Terraform garante que ele exista.
const silver_schema = v.silver_schema || "martech_silver";
const gold_schema = v.gold_schema || "martech_gold";

module.exports = {
  project_id: dataform.projectConfig.defaultDatabase,
  // Datasets
  raw_ga4: v.raw_ga4 || "raw_ga4",
  raw_ads: v.raw_ads || "raw_ads",
  silver_schema: silver_schema,
  gold_schema: gold_schema,
  // Tabelas
  tab_slv_ga4: v.tab_slv_ga4 || "slv_ga4_events",
  tab_slv_ads: v.tab_slv_ads || "slv_ads_performance",
  tab_gld_mkt: v.tab_gld_mkt || "fct_marketing_performance",
  tab_gld_retail: v.tab_gld_retail || "fct_retail_media_cube",
  // Injeção da tabela bruta de Ads
  raw_ads_table: v.raw_ads_table || "ad_CampaignBasicStats_987654321",
  
  enable_marketing: ["marketing", "full"].includes(v.flavor || "full"),
  enable_retail_media: ["retail_media", "full"].includes(v.flavor || "full")
};