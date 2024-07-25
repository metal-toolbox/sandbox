#!/usr/bin/env -S awk -f

BEGIN {
	PADDING = 32
	RESET = "\033[0m"
	GREEN = "\033[32m"
	LIGHTGREEN = "\033[92m"
	YELLOW = "\033[33m"
	ITALLIC = "\033[3m"
	messageArrayLength = 0

	printf "\nUsage:\n"
	printf "  %smake %s<targets>%s\n\n", YELLOW, GREEN, RESET
	printf "Targets:\n"
}

/^[a-zA-Z\-\\_0-9%]+:/ {
	helpCommand = substr($1, 0, index($1, ":")-1)
	printf "  %s%-*s %s%s%s\n", YELLOW, PADDING, helpCommand, GREEN, messageArray[0], RESET
	for (i = 1; i < messageArrayLength; i++) {
		printf "   %-*s-%s%s%s%s\n", PADDING, "", LIGHTGREEN, ITALLIC, messageArray[i], RESET
	}
	messageArrayLength = 0
}

{
	helpMessage = match($0, /^## (.*)/)
	if (helpMessage) {
		helpMessage = substr($0, RSTART + 3, RLENGTH)
		messageArray[messageArrayLength++] = helpMessage
	}
}