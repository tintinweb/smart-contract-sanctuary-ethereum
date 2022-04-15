/**
 *Submitted for verification at Etherscan.io on 2022-04-15
*/

pragma solidity ^0.5.10;

contract Feng {
    event SendFlag(address addr);
    function getFlag() public {
        emit SendFlag(msg.sender);
    }
}