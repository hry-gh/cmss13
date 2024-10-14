/datum/internet_media

/datum/internet_media/proc/get_media(url)
	RETURN_TYPE(/datum/media_response)

/datum/internet_media/yt_dlp

/datum/internet_media/yt_dlp/get_media(url)
	var/ytdl = CONFIG_GET(string/invoke_youtubedl)
	if(!ytdl)
		return

	if(findtext(url, ":") && !findtext(url, GLOB.is_http_protocol))
		return

	var/list/output = world.shelleo("[ytdl] --geo-bypass --format \"bestaudio\[ext=mp3]/best\[ext=mp4]\[height<=360]/bestaudio\[ext=m4a]/bestaudio\[ext=aac]\" --dump-single-json --no-playlist -- \"[shell_url_scrub(url)]\"")
	var/errorlevel = output[SHELLEO_ERRORLEVEL]
	var/stdout = output[SHELLEO_STDOUT]
	var/stderr = output[SHELLEO_STDERR]

	if(errorlevel)
		CRASH("Youtube-dl URL retrieval FAILED: [stderr]")

	var/data

	try
		data = json_decode(stdout)
	catch(var/exception/e)
		CRASH("Youtube-dl JSON parsing FAILED: [e]: [stdout]")
		return

	return new /datum/media_response(data["url"], data["title"], data["start_time"], data["end_time"])

/datum/internet_media/cobalt

/datum/internet_media/cobalt/get_media(url)
	var/static/headers
	if(!headers)
		headers = list(
			"Accept" = "application/json",
			"Content-Type" = "application/json",
		)

		var/auth_key = CONFIG_GET(string/cobalt_api_key)
		if(auth_key)
			headers["Authorization"] = "Api-Key [auth_key]"

		headers = json_encode(headers)

	var/body = json_encode(list(
		"url" = url,
		"downloadMode" = "audio",
		"filenameStyle" = "nerdy"
	))

	var/response_raw = rustg_http_request_blocking(RUSTG_HTTP_METHOD_POST, CONFIG_GET(string/cobalt_base_api), body, headers, null)
	var/list/response
	try
		response = json_decode(response_raw)
		if(!("body" in response))
			CRASH("Failed to perform cobalt.tools API request: Response lacks body.")
		response = json_decode(response["body"])
	catch
		CRASH("Failed to perform cobalt.tools API request: Failed to decode response.")

	var/static/list/valid_status = list("redirect", "tunnel")
	var/status = response["status"]
	if(!(status in valid_status))
		CRASH("Failed to perform cobalt.tools API request: [json_encode(response)]")
	return new /datum/media_response(response["url"])

/datum/media_response
	var/url
	var/title
	var/start_time
	var/end_time

/datum/media_response/New(url, title, start_time, end_time)
	src.url = url
	src.title = title
	src.start_time = start_time
	src.end_time = end_time

/datum/media_response/proc/get_list()
	return list("url" = url, "title" = title, "start_time" = start_time, "end_time" = end_time)
