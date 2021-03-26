Param(
      [Object[]]$Filename,
      [String]$Desc,
      [String]$RecordId
     )

[xml]$doc = New-Object System.Xml.XmlDocument;
$map = $doc.CreateElement("Map"); 
$node = $doc.CreateElement("SortCode");
$node.InnerText = $RecordId;
$map.AppendChild($node);
$node = $doc.CreateElement("Description");
$node.InnerText = $Desc;
$map.AppendChild($node);
$node = $doc.CreateElement("Schema");
$node.InnerText = (Get-ChildItem -File $Filename).BaseName;
$map.AppendChild($node);
$node = $doc.CreateElement("SortOrder");
$node.InnerText = "AFILENAME ASC,PRCRECNO ASC";
$map.AppendChild($node);
$node = $doc.CreateElement("DisplayFields");
$innerText = ""
$inputXml = [XML](Get-Content $Filename);
ForEach($column in $inputXml.root.'information_schema.columns') {
   If ($column.field -notmatch "(?:AFILENAME|UNUSED|PRCRECNO|CRLFSEQ)") {
      $innerText += "$($column.field), ";
   }
}
$innerText = $innerText.Remove($innerText.Length - 2);
$node.InnerText = $innerText;
$map.AppendChild($node);
$doc.AppendChild($map);
$doc.InnerXml | Add-Content "Map.xml";
