// Captura as variáveis do workflow_settings.yaml ou usa o padrão Magalu
const raw_ga4_dataset = dataform.projectConfig.vars.raw_ga4_dataset || "raw_ga4";
const raw_ads_dataset = dataform.projectConfig.vars.raw_ads_dataset || "raw_ads";
const raw_ads_table = dataform.projectConfig.vars.raw_ads_table || "ad_CampaignBasicStats_987654321";
const flavor = dataform.projectConfig.vars.flavor || "full";

module.exports = {
  project_id: dataform.projectConfig.defaultDatabase,
  raw_ga4: raw_ga4_dataset,
  raw_ads: raw_ads_dataset,
  raw_ads_table: raw_ads_table,
  enable_marketing: ["marketing", "full"].includes(flavor),
  enable_retail_media: ["retail_media", "full"].includes(flavor)
};