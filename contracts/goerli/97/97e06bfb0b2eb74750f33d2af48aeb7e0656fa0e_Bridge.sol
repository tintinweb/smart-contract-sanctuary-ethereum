/**
 *Submitted for verification at Etherscan.io on 2023-01-22
*/

pragma solidity 0.8.17;

contract Bridge {
   
   event BridgeEvent(address val1, int256 val2, bool val3);

   function bridgeFunction(int256 val2, bool val3) public {
       emit BridgeEvent(msg.sender, val2, val3);
   }

}