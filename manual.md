# Tubelib Library

## Hints for Admins and Players

Tubelib is little useful for itself, it makes only sense with extensions such as tubelib_addons1.

But Tubelib provides the following basic blocks:

### Tubes
Tubes allow the item exchange between two blocks. Forks are not possible. You have to use chests or other inventory blocks as hubs to build more complex structures. The maximum length of one tube is 48 blocks.
Tubes for itself are passive. For item exchange you have to use a pulling/pushing block in addition.

### Pusher
The Pusher is able to pull one item out of one inventory block and pushing it into another inventory block by means of the tubes.
It the source block is empty or the destination block full, the Pusher goes for some seconds into STANDBY state.

### Distributor
The Distributor works as filter and pusher. It allows to divide and distribute incoming items into 4 tube channels.
The channels can be switched on/off and individually configured with up to 6 items. The filter passes the configured
items and restrains all others. To increase the throughput, one item can be added several times to a filter.
An unconfigured but activated filter allows to pass up to 6 remaining items.

### Button/Switch
The Button/Switch is a simple communication block for the Tubelib wireless communication.
This block can be configured as button and switch. For the button configuration different switching
times from 2 to 16 seconds are possible. The Button/Switch block has to be configured with the destination
number of the receiving block (e.g. Lamp). This block allows to configure several receivers by means or their numbers.

### Lamp
The Lamp is a receiving block, showing its destination/communication number via "infotext".
The Lamp can be switched on/off by means of right mouse button (use function) or by means of messages commands
from a Button/Switch or any other command sending block.


