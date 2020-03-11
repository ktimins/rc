Param(
      [Object[]]$Excel
     )

   $igName = $Excel[3]."File";

   [xml]$doc = New-Object System.Xml.XmlDocument;
   $dec = $doc.CreateXmlDeclaration("1.0", "utf-8", "yes");
   $doc.AppendChild($dec) | Out-Null;
   $root = $doc.CreateElement("root"); 

   $i = 1;
   ForEach($object in $Excel) {
      if ([Bool]($object."Internal Field Name")) {
         $isc = $doc.CreateElement("information_schema.columns");
         $node = $doc.CreateElement("seq");
         $node.InnerText = $i;
         $isc.AppendChild($node) | Out-Null;
         $node = $doc.CreateElement("field");
         $node.InnerText = $object."Internal Field Name";
         $isc.AppendChild($node) | Out-Null;
         $node = $doc.CreateElement("data_type");
         $node.InnerText = "char";
         $isc.AppendChild($node) | Out-Null;
         $node = $doc.CreateElement("length");
         $node.InnerText = $object."Field Length In Bytes";
         $isc.AppendChild($node) | Out-Null;
         $node = $doc.CreateElement("description");
         $node.InnerText = $Object."Field Text Description";
         $isc.AppendChild($node) | Out-Null;
         $root.AppendChild($isc) | Out-Null;
         $i++;
      }
   }

$doc.AppendChild($root) | Out-Null;

$doc.Save("Z:\$igName.xml");

Return $doc.InnerXml;
