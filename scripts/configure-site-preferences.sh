foswiki_root="/var/www/foswiki"
site_preferences="$foswiki_root/data/Main/SitePreferences.txt"

if test ! -f $site_preferences; then
  echo "ERROR: SitePreferences not found" 1>&2
  exit 1
fi

echo "configuring site preferences"

if ! grep -q "GENERATED BY VAGRANT" $site_preferences; then
  cp $site_preferences /tmp

cat <<"HERE" > $site_preferences
%META:TOPICINFO{author="BaseUserMapping_999" comment="" date="1610441987" format="1.1" version="1"}%
---+!! %TOPIC%

<!-- GENERATED BY VAGRANT -->

   * Set WIKILOGOIMG = %PUBURLPATH%/%SYSTEMWEB%/ProjectLogos/foswiki-logo.svg
   * Set WIKILOGOALT = Powered by Foswiki, The Free and Open Source Wiki
   * Set WIKILOGOURL = %SCRIPTURLPATH{"view"}%/%USERSWEB%/%HOMETOPIC%
   * Set FAVICON = %PUBURLPATH%/%SYSTEMWEB%/ProjectLogos/favicon.ico

<verbatim>
   * Set NEWTOPICLINKSYMBOL = ?
   * Set NEWLINKFORMAT = <a href='#newtopic' class='foswikiNewLink foswikiDialogLink' data-topictitle='%ENCODE{$text}%'>$text</a>
</verbatim>

---++ Document Graphics

   * Set Y = %JQICON{"fa-check" class="fa-fw" style="color:#4CAF50;font-size:1.2em"}%
   * Set O = %JQICON{"fa-circle-o" class="fa-fw" style="color:#FF5722;font-size:1.2em"}%
   * Set X = %JQICON{"fa-times" class="fa-fw" style="color:#FF5722;font-size:1.2em"}%
   * Set NO = %JQICON{"fa-ban" class="fa-fw" style="color:#FF5722;font-size:1.1em"}%
   * Set H = %JQICON{"fa-question-circle" class="fa-fw" style="color:#2196F3;font-size:1.2em"}%
   * Set S = %JQICON{"fa-star" class="fa-fw" style="color:#FF5722;font-size:1.2em"}%
   * Set I = %JQICON{"fa-lightbulb-o" class="fa-fw" style="color:#2196F3;font-size:1.2em"}%
   * Set M = %JQICON{"fa-arrow-right" class="fa-fw" style="color:#4CAF50;font-size:1.2em"}%
   * Set Q = %JQICON{"fa-question-circle-o" class="fa-fw" style="color:#2196F3;font-size:1.2em"}%
   * Set T = %JQICON{"fa-lightbulb-o" class="fa-fw" style="color:#FFC107;font-size:1.2em"}%
   * Set P = %JQICON{"fa-pencil" class="fa-fw" style="color:#795548;font-size:1.2em"}%
   * Set N = <img src="%ICONURLPATH{new}%" alt="NEW" title="NEW" width="30" height="16" />
   * Set U = <img src="%ICONURLPATH{updated}%" alt="UPDATED" title="UPDATED" width="55" height="16" />

---++ Finalisation

   * Set FINALPREFERENCES = ATTACHFILESIZELIMIT, PREVIEWBGIMAGE, WIKITOOLNAME, WIKIHOMEURL, ALLOWROOTCHANGE, DENYROOTCHANGE, DOCWEB, WIKIWEBMASTER, WIKIWEBMASTERNAME, WIKIAGENTEMAIL, WIKIAGENTNAME

%META:PREFERENCE{name="ALLOWTOPICCHANGE" title="ALLOWTOPICCHANGE" type="Set" value="AdminUser"}%
%META:PREFERENCE{name="PERMSET_CHANGE" title="PERMSET_CHANGE" type="Local" value="nobody"}%
HERE
fi

while [[ $# -gt 0 ]]; do
  param=$1
  shift

  if [[ $param == -* ]]; then
    key=${param/-/}
    val=$1
    shift

    #echo "... $key=$val"
    su nginx <<HERE
    sed -i "/^   \* Set $key = .*/d;/GENERATED BY VAGRANT/a \ \ \ * Set $key = $val" $site_preferences 
HERE

  else
    echo "unknown param '$param'"
    shift
  fi
done

