pragma solidity ^0.6.0;

contract SelfDestructible {
    function selfDestruct() public {
        selfdestruct(payable(msg.sender));
    }
}