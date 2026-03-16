const project_id = dataform.projectConfig.defaultDatabase;

// Lista de fontes baseada no Sabor (Flavor)
const flavor = dataform.projectConfig.vars.flavor || "full";

const modules = {
  ga4_silver: true,
  ads_silver: true,
  marketing_gold: ["marketing", "full"].includes(flavor),
  retail_media_gold: ["retail_media", "full"].includes(flavor)
};

module.exports = { 
    project_id, 
    modules,
    schemas: {
        silver: "martech_silver",
        gold: "martech_gold"
    }
};