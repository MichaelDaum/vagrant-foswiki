echo "configuring SolrPlugin"

foswiki_root="/var/www/foswiki"

echo "... downloading microsoft core fonts"
update-ms-fonts -q
fc-cache -f



echo "... configuring AutoTemplatePlugin"
su nginx <<HERE
cd $foswiki_root
./tools/configure -save -set {Plugins}{AutoTemplatePlugin}{ViewTemplateRules}="{
  'ChangePassword' => 'ChangePasswordView',
  'ResetPassword' => 'ResetPasswordView',
  'ChangeEmailAddress' => 'ChangeEmailAddressView',
  'UserRegistration' => 'UserRegistrationView',
  'WebAtom' => 'WebAtomView',
  'WebChanges' => 'WebChangesView',
  'SiteChanges' => 'SiteChangesView',
  'WebCreateNewTopic' => 'WebCreateNewTopicView',
  'WebRss' => 'WebRssView',
  'WebTopicList' => 'WebTopicListView',
  'WebIndex' => 'WebIndexView',
  'WikiGroups' => 'WikiGroupsView',
  'WikiUsers' => 'SolrWikiUsersView',
  'WebSearchAdvanced' => 'SolrSearchView',
  'WebSearch' => 'SolrSearchView',
}"
HERE

#(
#echo "... indexing foswiki"
#
#su nginx <<HERE
#  cd $foswiki_root/tools
#  ./solrindex
#HERE
#
#) >/dev/null
