---
title: "P2P Mafia in the browser: development with AI agents"
date: 2026-08-26
lastmod: 2026-08-26
description: "How I made Police Raid - an online game without a backend - and what I learned from experiments with AI agents"
tags: ["Development history"]
---

Police Raid started with two goals: ship a web version of an online social deduction game, and try different AI agents in practice, outside my usual stack.

[View →](https://sprkweb.github.io/police-raid/)

[GitHub repo →](https://github.com/sprkweb/police-raid)

{{< table-of-contents >}}

My friends and I used to play [Mindnight](https://store.steampowered.com/app/667870/MINDNIGHT) - a variation of "Mafia" with modified rules. But it had its drawbacks:
- Required installation: you couldn't play on your phone or quickly access it from your browser;
- The game died: player count dropped to zero, and support was discontinued.

I wanted to make my own version: convenient, independent, and accessible at any time, even if we decided to play once a year.

## Brief rules

The game is for 5-8 players. Two teams: the police must identify moles working for the mafia (in Mindnight, agents identified hackers). Unlike Mafia, no one votes anyone out. During development, I learned that Mindnight was based on the rules of the tabletop game The Resistance, which in turn was based on Mafia.

There are five rounds per match. Each round, everyone votes to select a team they consider safe (without moles). The police on the chosen team conduct a raid on the mafia, but a mole can sabotage it. The police must successfully complete 3 out of 5 raids, while the moles must sabotage 3.

## Architecture

To avoid relying on a VPS for a project with infrequent play, I abandoned the traditional backend in favor of a P2P architecture: the game is pure frontend, with all logic running in the browser.

One player becomes the host. Their tab acts as the game server and the sole source of truth: it verifies rules and player actions, controls bots, and broadcasts state to other players - only what they should see. The downsides you have to live with: you have to trust the host, and the game ends if they disconnect.

P2P communication between browsers can be achieved via WebRTC. The main problem with this idea is the initial handshake (signaling) without a backend. Manually exchanging base64 strings with SDP packets via messengers is possible, but this is inconvenient. So I decided to implement signaling via a public server, which was hidden behind the interface in the code for easy replacement. This abstraction quickly proved itself: the first implementation used [PeerJS](https://github.com/peers/peerjs), but it later turned out that its default servers are inaccessible from Russia without a VPN. Thanks to the interface, I easily migrated connection setup to [@metered-ca/realtime](https://www.metered.ca/tools/openrelay/webrtc-library/): like PeerJS, they provide free servers for signaling and TURN, allowing connections even behind NATs and firewalls.

## First version

I created the first version using [Google Jules](https://jules.google.com) - it was interesting to poke at it. The service is positioned as an autonomous asynchronous agent that runs in the background while you're busy with other tasks. In practice, it's an agent inside a cloud virtual machine: it executes tasks on prompts, and can be scheduled: for example, every day at 9:00, run the command "find one bug and fix it."

Google is not known for its coding models, but Jules handled the first version: based on the architecture and rules description, I had a working online game up and running in just one evening. The UI turned out simple and utilitarian, but I didn't give it any specific interface requirements.

{{< img "first-version.png" "Screenshot of the first version" >}}

## Interface

The next step was to immerse players in the atmosphere of a police raid and make the controls intuitive.

My main requirement for the interface was a **circle of player icons** as the central element of the game, where all the action unfolds. Player icons are a *visual anchor* that people perceive as other characters. Why this is necessary:
1. It's easier to immerse yourself in the game when each player has a visual image, not just text on a list.
2. It's easier to keep the big picture in mind and calculate team combinations within this circle.
3. You can interact directly with players: for example, when choosing a team, click directly on the desired players.
4. Everything important is located in the focal center, between the characters. It displays key information and possible actions: for example, the discussion timer, team voting, and raid results.
5. There is no first or last player in the circle; everyone is initially equal.

I wanted the visual style to be dark blue: we're on a nighttime police raid. All the in-game text should also be stylized and contribute to the atmosphere.

I wanted a completely different look for the game, not an iterative improvement on the existing one. This required the insights of independent AIs without access to the codebase. I was also interested in trying out different models. So I decided to conduct an experiment:
1. I ask several models for interface prototypes based on the game rules, focusing on atmosphere and UX.
2. I choose the best option.
3. I tell the model where improvements are needed.
4. I take this HTML file to the agent so it can skin the UI onto the game.

First, I tried two random models from Battle Mode on [arena.ai](https://arena.ai/). I got `mistral-medium-3.5` and the anonymous model `kivine`. I also requested prototypes from Gemini 3.1 Pro via Jules and from Claude Opus 5 High via Cursor.

Mistral delivered a simple and play-it-safe style, without any "police" elements. The layout is a bit rough and I could not even open voting or raid screens.
{{< img "mistral-version.png" "Screenshot of the Mistral version" >}}

The version by kivine is very high-quality work; it immediately feels like an advanced model. The AI went all out on the tactical-console look - even a bit over the top for my taste. There is a circle of players, but only at the discussion phase.
{{< img "kivine-version.png" "Screenshot of the kivine version" >}}

Jules' version (model - Gemini 3.1 Pro), like Mistral, is very simple: no thematic styling, except for the neon highlighting of some text. There's a player circle, but the layout is a bit wonky.
{{< img "jules-version.png" "Screenshot of the Jules version" >}}

Cursor's version (model - Claude Opus 5 High) perfectly captures the atmosphere: the agent added yellow and black barrier tape, the glow of police lights in the corner of the screen, and thematic text. The model forgot about the player circle.
{{< img "opus-version.png" "Screenshot of the Claude Opus version" >}}

I liked the Opus version in Cursor the most in terms of style. With a few additional prompts, we added a player circle and removed unnecessary elements and visual noise. After some refinement, it formed the basis of the current interface, which I then ported to the game using the same Cursor.

{{< img "final-version.png" "Screenshot of the final version" >}}

## Takeaways about AI agents

When developing with AI agents, the biggest bottleneck is often the human who must guide the model, monitor its actions, and verify the results.

I'd like to share what helped me get the most out of my agents, so they work better with minimal oversight and tweaks on my part.

1. Of course, **good models**

    Google Jules handled the first version well, but it quickly became clear that it would be difficult to work with. I had to constantly supervise it, spell out every error, babysit - it was easier and faster to write everything myself.

    So, I then switched development to Cursor cloud agents. Their Grok 4.6 model feels just as good as Claude Opus: it picks things up immediately and executes it competently. The cheapest Pro subscription at $20 gives a surprisingly large amount of tokens: I spent only 17% of my monthly limit on the entire game in three weeks.

2. **Cloud agents**

    Unlike local agents, cloud agents don't require security monitoring or approval for potentially dangerous actions. They operate in an isolated environment, so they can run whatever is required and independently complete tasks from start to finish.

3. **Writing all non-obvious requirements in AGENTS.md**

    For example, the "police" tone of interface text or the host's role in a P2P architecture. If similar notes need to be made to the agent when implementing two different tasks, it might be worth writing these down in [AGENTS.md](https://github.com/sprkweb/police-raid/blob/main/AGENTS.md).

4. **Self-testing tools for the agent**

    I wrote commands for linting, building, and running tests in [AGENTS.md](https://github.com/sprkweb/police-raid/blob/main/AGENTS.md#setup--testing) and required that everything be covered by tests. Cloud agents can launch an MCP browser and take screenshots, so I also wrote instructions for manual testing. With all these tools, the agent can check everything itself and delivers me working results.

5. **Voice prompt input**

    For example, using [Wispr Flow](https://wisprflow.ai/). When I type by hand, the text is more structured, but also shorter. Recording spoken language provides much more context and detail; the AI better understands my vision of the result and more often produces what I want.

## What's next

Now that the game itself is ready, I'm excited about developing advanced bots with the mindset of experienced players. The original game didn't have this, and it will be more interesting to play with these bots. I plan to write more about the algorithm in another article once the final version of the bots is released.