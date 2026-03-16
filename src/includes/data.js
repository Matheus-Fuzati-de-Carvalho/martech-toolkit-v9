const project_id = dataform.projectConfig.defaultDatabase;
const flavor = dataform.projectConfig.vars.flavor || "full";

module.exports = {
  project_id,
  raw_ga4: dataform.projectConfig.vars.raw_ga4_dataset,
  raw_ads: dataform.projectConfig.vars.raw_ads_dataset,
  raw_ads_table: dataform.projectConfig.vars.raw_ads_table,

  // Ativação baseada no Flavor
  enable_marketing: ["marketing", "full"].includes(flavor),
  enable_retail_media: ["retail_media", "full"].includes(flavor)
};