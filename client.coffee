Form = require 'form'
Db = require 'db'
Dom = require 'dom'
Icon = require 'icon'
Modal = require 'modal'
Obs = require 'obs'
Plugin = require 'plugin'
Page = require 'page'
Server = require 'server'
Ui = require 'ui'
Time = require 'time'
{tr} = require 'i18n'
Colors = Plugin.colors()

exports.render = ->

	selO = Db.personal.ref 'votes'
	candsO = Db.shared.ref 'candidates'

	if (candId2 = 0|Page.state.get(0)) and (cand = candsO.get(candId2))
		scores = Db.shared.get('scores', candId2) || {}
		img = (if cand.out then 'o' else 'c')+candId2+'.jpg'
		Dom.div !->
			Dom.style
				Box: "middle"
				marginBottom: "15px"
			Dom.div !->
				Dom.style
					width: '120px'
					height: '80px'
					backgroundImage: "url(#{Plugin.resourceUri img})"
					borderRadius: "4px"
					backgroundSize: 'cover'
					backgroundPosition: "50% 50%"
			Dom.div !->
				Dom.style
					textAlign: 'center'
					Flex: true
				Dom.h1 cand.full
				Dom.text if cand.out
					tr "Eliminated"
				else if selO.get(candId2)
					tr "One of your suspects"
				else
					tr "Not a suspect"

		Ui.list !->
			Dom.h3 tr 'Suspicion points'
			Plugin.users.iterate (user) !->
				Ui.item !->
					if (0|user.key())==Plugin.userId()
						Dom.style fontWeight: 'bold'
					Ui.avatar Plugin.userAvatar(user.key())
					Dom.div !->
						Dom.style
							marginLeft: '10px'
							Flex: true
						Dom.text user.get('name')
					Dom.div !->
						Dom.style
							fontSize: '150%'
						Dom.text scores[user.key()]||0
			, (user) -> [-(scores[user.key()]||0), user.get('name')]

		Ui.list !->
			Dom.h3 tr 'Your notes'
			Form.text
				value: Db.personal.get('notes',candId2)
				text: tr 'suspicions'
				onSave: (v) !->
					Server.sync 'saveNote', candId2, v, !->
						Db.personal.set 'notes', candId2, v
		return

	Dom.style padding: 0
	if next = (Db.shared.get 'next')
		Dom.div !->
			Dom.style
				backgroundColor: Colors.highlight
				color: Colors.highlightText
				padding: '6px'
				textAlign: 'center'
			Time.deltaText next, [
				37*60*60, 24*60*60, "%1 day|s"
				60*60, 60*60, "%1 hour|s"
				40, 60, "%1 minute|s"
				-Infinity, 100, "Just seconds"
			]
			Dom.text tr " left to finalize your suspicions for this week"

	selCntO = selO.count()
		
	cols = Math.max(2,0|Page.width()/140)
	perc = (100/cols)+'%'

	candsO.iterate (cand) !->
		candId = cand.key()
		Dom.div !->
			out = cand.get('out')

			img = (if out then 'o' else 'c')+candId+'.jpg'
			Dom.style
				width: perc
				height: 0
				paddingTop: perc
				backgroundImage: 'url(' + Plugin.resourceUri(img) + ')'
				backgroundSize: 'cover'
				backgroundPosition: '50% 50%'
				display: 'inline-block'
				position: 'relative'
				overflow: 'hidden'

			Dom.div !->
				Dom.style
					position: 'absolute'
					padding: '7px 12px 7px 9px'
					left: 0
					borderTopRightRadius: '5px'
					bottom: 0
					color: 'white'
					backgroundColor: 'rgba(0,0,0,0.7)'
					border: '1px solid rgba(255,255,255,0.2)'
				Icon.render
					data: "info"
					color: 'white'
					style: marginRight: '4px', verticalAlign: "top"
					size: 18
				Dom.text cand.get("name")
			
				Dom.onTap !->
					Page.nav [candId]

			return if out

			Dom.onTap !->
				newVal = if selO.peek(candId) then null else true
				Server.sync 'set', candId, newVal, !->
					selO.set candId, newVal

			Obs.observe !->
				if sel = selO.get(candId)

					Dom.img !->
						Dom.prop src: Plugin.resourceUri('fingerprint.png')
						Dom.style
							position: 'absolute'
							right: 0
							bottom: 0
							width: '40px'
							height: '50px'

					Dom.div !->
						Dom.style
							textAlign: 'center'
							position: 'absolute'
							right: 0
							width: '35px'
							bottom: '3%'
							color: 'white'
						Dom.text Math.floor(100/selCntO.get())
				
	, (cand) -> [(if cand.get('out') then 1 else 0), cand.get('name')]

