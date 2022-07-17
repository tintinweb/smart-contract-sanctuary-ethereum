/**
 *Submitted for verification at Etherscan.io on 2022-07-17
*/

pragma solidity >= 0.4.22 < 0.7.0;

contract Storage{
    address public owner;
    uint public storedData;
    constructor() public {
        owner = msg.sender;
    }

    function set(uint data) public {
        require(owner == msg.sender);
        storedData = data;
    }
}