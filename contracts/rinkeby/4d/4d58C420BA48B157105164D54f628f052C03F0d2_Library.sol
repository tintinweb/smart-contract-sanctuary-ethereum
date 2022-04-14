//SPDX-Licence-Identifier: MIT
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/access/Ownable.sol";

contract Library {

    mapping(address => string[]) contentID;

    constructor() {

    }

    function setContent(string memory _content)
     public
     returns(bool) {
        contentID[msg.sender].push(_content);
        return true;
    }

    function getContent()
    public
    view
    returns(string [] memory) {
        return contentID[msg.sender];
    }
}