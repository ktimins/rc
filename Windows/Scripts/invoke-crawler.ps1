$url = 'https://manybooks.net/sites/default/'
$Script:maxLinks = 200
$Script:maxLevels = 3
$Script:numberLinks = 0
$Script:linksVisited = @()
Function CrawlLink($site, $level)
{
   Try
   {
      $request = Invoke-WebRequest $site
         $content = $request.Content
         $domain = ($site.Replace("http://","").Replace("https://","")).Split('/')[0]
         $start = 0
         $end = 0
         $start = $content.IndexOf("<a ", $end)
         while($start -ge 0)
         {
            if($start -ge 0)
            {
# Get the position of of the beginning of the link. The +6 is to go past the href="
               $start = $content.IndexOf("href=", $start) + 6
                  if($start -ge 6)
                  {
                     $end = $content.IndexOf("""", $start)
                        $end2 = $content.IndexOf("'", $start)
                        if($end2 -lt $end -and $end2 -ne -1)
                        {
                           $end = $end2
                        }
                     if($end -ge $start)
                     {
                        $link = $content.Substring($start, $end - $start)
# Handle case where link is relative
                           if($link.StartsWith("/"))
                           {
                              $link = $site.Split('/')[0] + "//" + $domain + $link
                           }
                        if($Script:numberLinks -le $Script:maxLinks -and $level -le $Script:maxLevels)
                        {
                           if(($Script:linksVisited -notcontains $link) -and $link.StartsWith("http:"))
                           {
                              $Script:numberLinks++
                                 Write-Host $Script:numberLinks"["$level"] - "$link -BackgroundColor Blue -ForegroundColor White
                                 $Script:linksVisited += $link
                                 CrawlLink $link ([int]($level+1))
                           }
                        }
                     }
                  }
            }
            $start = $content.IndexOf("<a ", $end)
         }
   }
   Catch [system.exception]
   {
   }
}
CrawlLink $url 0
