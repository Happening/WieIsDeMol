Db = require 'db'
Plugin = require 'plugin'
Timer = require 'timer'
Event = require 'event'

candidates = {
	1:
		name: "Ajouad"
		full: "Ajouad El Miloudi"
	2:
		name: "Carolina"
		full: "Carolina Dijkhuizen"
	3:
		name: "Chris"
		full: "Chris Zegers"
	4:
		name: "Evelien"
		full: "Evelien Bosch-Gademan"
	5:
		name: "Margriet"
		full: "Margriet van der Linden"
	6:
		name: "Marlijn"
		full: "Marlijn Weerdenburg"
	7:
		name: "Martine"
		full: "Martine Sandifort"
	8:
		name: "Pieter"
		full: "Pieter Derks"
		out: true
	9:
		name: "Rik"
		full: "Rik van de Westelaken"
	10:
		name: "Viktor"
		full: "Viktor Brand"
}


week = 3600*24*7
getNext = (start) ->
	prevWeekNum = 0 | ((Plugin.time() - start) / week)
	start + (prevWeekNum+1) * week


exports.onInstall = exports.onUpgrade = update = !->
	# set the counter to 0 on plugin installation
	start = 1420140600
	Timer.cancel()

	Db.shared.set 'candidates', candidates

	time = Plugin.time()
	if time < start + week*12-5
		next = getNext start
		vote = getNext start-3600
		Timer.set (next-time)*1000, 'showStarts'
		Timer.set (vote-time)*1000, 'reminder'

	Db.shared.set 'next', next

	# check votes
	for userId in Plugin.userIds()
		votes = Db.personal(userId).get('votes')
		return if !votes
		cnt = 0
		change = false
		for candId of votes
			if !candidates[candId] or candidates[candId].out
				delete votes[candId]
				change = true
			else
				cnt++

		if change
			Db.personal(userId).set 'votes', votes


objEmpty = (o) ->
	for x of o
		return false
	true

exports.showStarts = !->

	update()

	time = 0|Plugin.time()

	voteAll = {}
	for candId,cand of candidates when !cand.out
		voteAll[candId] = true

	for userId in Plugin.userIds()
		votes = Db.personal(userId).get('votes')
		updateScores userId, if votes and !objEmpty(votes) then votes else voteAll

	# dummy user that is used to allocate scores to new users
	updateScores 0, voteAll


exports.onJoin = (userId) !->
	# This is a little overkill, but what we want to do is initialize the user to vote for everybody:
	update()

	# Copy scores from dummy user.
	Db.shared.forEach 'scores', (cand) !->
		cand.set userId, cand.peek(0)


updateScores = (userId,votes) !->
	cnt = 0
	cnt++ for candId of votes
	weight = 0|(100/cnt)
	for candId of votes
		Db.shared.incr 'scores', candId, userId, weight
	Db.backend.set 'log', Plugin.time(), userId, votes


exports.reminder = !->
	Event.create
		unit: "mol"
		text: "'Wie is de Mol' in 1 hour! Have you updated your suspicions?"


exports.client_set = (candId,newVal) !->
	Db.personal().set 'votes', candId, newVal


exports.client_saveNote = (candId,v) !->
	Db.personal().set 'notes', candId, v

