const p = dataform.projectConfig.vars;

module.exports = {
  project_id: dataform.projectConfig.defaultDatabase,
  // Datasets
  raw_ga4: p.raw_ga4 || "raw_ga4",
  raw_ads: p.raw_ads || "raw_ads",
  silver_schema: p.silver_schema || "martech_silver",
  gold_schema: p.gold_schema || "martech_gold",
  // Nomes de Tabelas
  raw_ads_table: p.raw_ads_table || "ad_CampaignBasicStats_987654321",
  tab_slv_ga4: p.tab_slv_ga4 || "slv_ga4_events",
  tab_slv_ads: p.tab_slv_ads || "slv_ads_performance",
  tab_gld_mkt: p.tab_gld_mkt || "fct_marketing_performance",
  tab_gld_retail: p.tab_gld_retail || "fct_retail_media_cube",
  // Flavors
  enable_marketing: ["marketing", "full"].includes(p.flavor || "full"),
  enable_retail_media: ["retail_media", "full"].includes(p.flavor || "full")
};