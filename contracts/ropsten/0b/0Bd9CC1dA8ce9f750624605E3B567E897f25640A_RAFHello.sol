/**
 *Submitted for verification at Etherscan.io on 2022-04-03
*/

pragma solidity >=0.7.0 <0.9.0;

contract RAFHello {

    mapping(address => uint8) public owners;

    string public message;

    constructor() {
        owners[0x50e4861837b3CA72C7Caa04954aD593D4c2850d8] = 1;
        owners[0x5E36ee824ee289368d4d7B220D16e70641a24a0A] = 1;
    }

    function updateMessage(string memory _newMessage) public {
        require(owners[msg.sender]==1, "Not an owner");
        message = _newMessage;
        return;
    }

}