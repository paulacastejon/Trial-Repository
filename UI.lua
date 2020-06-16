require "Sidebar"
require "RepairModals"

g_strLastAction = ""

function Initialize()
  InitializePrinterList()
end

function InitializePrinterList()
  local strPrinterList = Hy.strGetVariable("Project.PrinterList")
  Hy.ExecuteCommand("PrinterSettings.Printer.SetValues", strPrinterList)
  Hy.ExecuteCommand("PrinterSettings.Printer.SetItems", strPrinterList)
  SelectFirstPrinter(strPrinterList)
end

function strGetFirstOccurrence(strText, strSeparator)
  local nIndex = string.find(strText, strSeparator)
  if nIndex then return string.sub(strText, 1, nIndex - 1) else return strText end
end

function SelectFirstPrinter(strPrinterList)
  local strFirstPrinter = strGetFirstOccurrence(strPrinterList, ",")
  Hy.SetVariable("Project.Printer.Model", strFirstPrinter)
  SelectPrinter(strFirstPrinter)
end

function UpdateSettings()
  Hy.Log("UpdateSettings","UpdateSettings")
  g_strLastAction = "UpdateSettings"
  local oMaterial = Hy.oProject.oMaterial

  local oMenus = {}
  oMenus["BasicPrinterSettings"] = {"layerThickness", "extruderDiameter", "flowRate", "normalSpeed", "rapidSpeed", "skinSpeed", "firstLayerSpeed", "firstLayerThickness", "firstLayerFlowRate", "flowRateSupport", "retractionAmount", "retractionSpeed", "retractionLift"}
  oMenus["TemperatureSettings"] = {"nozzleTemperature", "bedTemperature", "chamberTemperature", "coolingTemperature"}
  oMenus["FDMSupportSettings"] = {"supportOverhangAngle", "supportInfill", "skirtLayers", "skirtOffset", "skirtWidth"}
  oMenus["InfillSettings"] = {"infillType", "infillBeforeWall", "infillOverlap", "wallOrder"} -- Project.Printer.InfillDensity and Project.Printer.ShellThickness are special variables, that's why they're not listed here

  for strMenuName, oProperties in pairs(oMenus) do
    for _, strProperty in pairs(oProperties) do
      local strValue = oMaterial:strGetProperty(strProperty)
      if strValue ~= "" then
        Hy.SetVariable("Project."..strProperty, strValue)
        Hy.ExecuteCommand(strMenuName.."."..strProperty..".SetDefault", strValue)
      end
    end
  end
end

function UpdateLayerThicknesses()
  local strLayerThicknessList = Hy.strGetVariable("Project.Printer.LayerThicknessList")
  Hy.ExecuteCommand("BasicPrinterSettings.layerThickness.SetValues", strLayerThicknessList)

  local strDefaultThickness = Hy.oProject.oMaterial:strGetProperty("layerThickness")
  Hy.SetVariable("Project.layerThickness", strDefaultThickness)
  UpdateLayerThickness(strDefaultThickness)
end

function UpdateLayerThickness(strValue)
  g_strLastAction = "UpdateLayerThickness"
  Hy.ExecuteCommand("Project.SetLayerThickness", strValue)
end

function SelectPrinter(strPrinterName)
  g_strLastAction = "SetPrinter"
  Hy.ExecuteCommand("Project.SetPrinter", strPrinterName)
end

function ProjectContentsChanged()
  if g_strLastAction == "SetPrinter" then
    local strMaterialList = Hy.strGetVariable("Project.Printer.MaterialList")
    UpdateMaterialList(strMaterialList)
    SelectFirstMaterial(strMaterialList)
  elseif g_strLastAction == "SetMaterial" then
    UpdateLayerThicknesses()
    UpdateSettings()
  end
end

function UpdateMaterialList(strMaterialList)
  Hy.ExecuteCommand("PrinterSettings.Material.SetValues", strMaterialList)
  Hy.ExecuteCommand("PrinterSettings.Material.SetItems", strMaterialList)
end

function SelectFirstMaterial(strMaterialList)
  local strFirstMaterial = strGetFirstOccurrence(strMaterialList, ",")
  Hy.SetVariable("Project.Printer.Material", strFirstMaterial)
  g_strLastAction = "SetMaterial"
  Hy.ExecuteCommand("Project.SetMaterial", strFirstMaterial)
end

function UpdateMaterialSetting(strProperty)
  local strValue = Hy.strGetVariable("Project." .. strProperty)
  Hy.ExecuteCommand("Project.OverrideMaterialProperty", strProperty, strValue)
end