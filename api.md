# Tubelib Programmers Interface


Tubelib supports:
- StackItem exchange via tubes and
- wireless data communication between nodes.


## 1. StackItem exchange 

Tubes represent connections between two nodes, so that it is irrelevant
if the receiving node is nearby or far away, connected via tubes.

For StackItem exchange we have to distinguish the following roles:
- client: An acting node calling push/pull functions
- server: An addressed node typically with inventory, to be worked on


## 2. Data communication

For the data communication an addressing method based on node numbers is used. 
Each registered node gets a unique number with 4 figures (or more if needed).
The numbers are stored in a storage list. That means, a new node, placed on 
the same position gets the same number as the previously placed node on that 
position.

The communication supports two services:
- send_message: Send a message to one or more nodes without response
- send_request: Send a messages to exactly one node and request a response


## 3. API funtions

Before a node can take part on ItemStack exchange or data communication
it has to be registered once via:
- tubelib.register_node(name, add_names, node_definition)

Each node shall call:
- tubelib.add_node(pos, name) when it was placed and
- tubelib.remove_node(pos) when it was dug.

For StackItem exchange the following functions exist:
- tubelib.pull_items(pos, side)
- tubelib.push_items(pos, side, items)
- tubelib.unpull_items(pos, side, items)

For data communication the following functions exist:
- tubelib.send_message(numbers, placer_name, clicker_name, topic, payload)
- tubelib.send_request(number, placer_name, clicker_name, topic, payload)


## 4. Examples

Tubelib includes the following example nodes which can be used for study
and as templates for own projects:

- pusher.lua: 		a simple client pushing/pulling items
- blackhole.lua:	a simple server client, makes all items disappear
- button.lua:		a simple communication node, only sending messages
- lamp.lua:         a simple communication node, only receiving messages


## 5. Further information

The complete API is located in the file 
![command.lua](https://github.com/joe7575/Minetest-Tubelib/blob/master/command.lua). 
This file gives more information to each API function and is recommended for further study.

