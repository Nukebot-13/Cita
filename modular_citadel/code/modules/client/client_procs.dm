/client/New()
	. = ..()
	mentor_datum_set()

/client/proc/citadel_client_procs(href_list)
	if(href_list["mentor_msg"])
		if(CONFIG_GET(flag/mentors_mobname_only))
			var/mob/M = locate(href_list["mentor_msg"])
			cmd_mentor_pm(M,null)
		else
			cmd_mentor_pm(href_list["mentor_msg"],null)
		return TRUE

	//Mentor Follow
	if(href_list["mentor_follow"])
		var/mob/living/M = locate(href_list["mentor_follow"])

		if(istype(M))
			mentor_follow(M)
		return TRUE

	if(href_list["mentor_unfollow"])
		var/mob/living/M = locate(href_list["mentor_follow"])
		if(M && mentor_datum.following == M)
			mentor_unfollow()
		return TRUE

/client/proc/mentor_datum_set(admin)
	mentor_datum = GLOB.mentor_datums[ckey]
	if(!mentor_datum && check_rights_for(src, R_ADMIN,0)) // admin with no mentor datum?let's fix that
		new /datum/mentors(ckey)
	if(mentor_datum)
		if(!check_rights_for(src, R_ADMIN,0) && !admin)
			GLOB.mentors |= src // don't add admins to this list too.
		mentor_datum.owner = src
		add_mentor_verbs()
		mentor_memo_output("Show")

/client/proc/is_mentor() // admins are mentors too.
	if(mentor_datum || check_rights_for(src, R_ADMIN,0))
		return TRUE

/client/verb/togglerightclickstuff()
	set category = "OOC"
	set name = "Toggle Rightclick"
	set desc = "Did the context menu get stuck on or off? Press this button."

	show_popup_menus = !show_popup_menus
	to_chat(src, "<span class='notice'>The right-click context menu is now [show_popup_menus ? "enabled" : "disabled"].</span>")

/client/var/forumlinklimit = 0
/client/verb/linkforumaccount()
	set category = "OOC"
	set name = "Link Forum Account"
	set desc = "Validates your byond account to your forum account. Required to post on the forums."

	if (forumlinklimit > world.time + 100)
		to_chat(src, {"<span class="userdanger">Please wait 10 game seconds between forums link attempts.</span>"})
		return

	forumlinklimit = world.time

	if (!SSdbcore.Connect())
		to_chat(src, {"<span class="danger">No connection to the database.</span>"})
		return

	if  (IsGuestKey(ckey))
		to_chat(src, {"<span class="danger">Guests can not link accounts.</span>"})

	var/token = generate_account_link_token()

	var/datum/db_query/query_set_token = SSdbcore.NewQuery("INSERT INTO feedback.byond_oauth_tokens (`token`, `key`) VALUES (:token, :key)", list("token" = token, "key" = key))
	if(!query_set_token.Execute())
		to_chat(src, {"<span class="danger">Unknown error #3.</span>"})
		qdel(query_set_token)
		return

	qdel(query_set_token)

	to_chat(src, {"Now opening a window to login to your forum account, Your account will automatically be linked the moment you log in. If this window doesn't load, Please go to <a href="https://tgstation13.org/phpBB/linkbyondaccount.php?token=[token]">https://citadel-station.net/forum/linkbyondaccount.php?token=[token]</a> This link will expire in 30 minutes."})
	src << link("https://citadel-station.net/forum/linkbyondaccount.php?token=[token]")

/client/proc/generate_account_link_token()
	var/static/entropychain
	if (!entropychain)
		if (fexists("data/entropychain.txt"))
			entropychain = file2text("entropychain.txt")
		else
			entropychain = "LOL THERE IS NO ENTROPY #HEATDEATH"
	else if (prob(rand(1,15)))
		text2file("data/entropychain.txt", entropychain)

	#define RANDOM_STRING "SHA2(CONCAT(RAND(),UUID(),?,RAND(),UUID()), 512)"
	#define RANDOM_STRING_ARGS "[entropychain][GUID()][rand()*rand(999999)][world.time][GUID()][rand()*rand(999999)][world.timeofday][GUID()][rand()*rand(999999)][world.realtime][GUID()][rand()*rand(999999)][time2text(world.timeofday)][GUID()][rand()*rand(999999)][world.tick_usage][computer_id][address][ckey][key][GUID()][rand()*rand(999999)]"
	var/datum/db_query/query_get_token = SSdbcore.NewQuery("SELECT [RANDOM_STRING], [RANDOM_STRING]", list(RANDOM_STRING_ARGS, RANDOM_STRING_ARGS))

	if(!query_get_token.Execute())
		to_chat(src, {"<span class="danger">Unknown error #1.</span>"})
		qdel(query_get_token)
		return

	if(!query_get_token.NextRow())
		to_chat(src, {"<span class="danger">Unknown error #2.</span>"})
		qdel(query_get_token)
		return

	. = query_get_token.item[1]

	entropychain = "[query_get_token.item[2]]"


