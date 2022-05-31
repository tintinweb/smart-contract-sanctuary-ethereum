/**
 *Submitted for verification at Etherscan.io on 2022-05-31
*/

pragma solidity ^0.8.0;

contract EESTECContract {

    string public message;

    mapping(address => bool) public owners;

    constructor() {
        owners[0xad30f9229B1Da39393a9D7ba68952ffF5A65C6Ff] = true;
        owners[0x56626849deB2412622902bC00F40f2750d981079] = true;
        owners[0xDdbf41eE8A441A42F7D80521E6Db3Fd2270b17c2] = true;
        owners[0x1E80524175C9a739f3954e09Dc8d3b281A0B5cAB] = true;
        owners[0x0b308Df1441dA3E364D97E0570cbB527AEA18D2F] = true;
        owners[0x5E36ee824ee289368d4d7B220D16e70641a24a0A] = true;
    }

    function UpdateMessage(string memory newMessage) public {
        require(owners[msg.sender] == true, "Not an owner! :P");
        message = newMessage;
        return;
    }
    
    function AddOwner(address newOwner) public {
        require(owners[msg.sender] == true, "Not an owner! :P");
        owners[newOwner] = true;
    }
}