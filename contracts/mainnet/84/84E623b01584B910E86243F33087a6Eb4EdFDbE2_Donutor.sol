/**
 *Submitted for verification at Etherscan.io on 2023-02-13
*/

//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

contract Donutor {

    address payable owner;

    struct Comment {
        address from;
        string name;
        string text;
        uint256 at;
    }

    mapping(address => Comment[]) public comments;

    constructor() {
        owner = payable(msg.sender);
    }

    function getComments(address _to) public view returns (Comment[] memory) {
        return comments[_to];
    }

    function donate(address payable _to, string memory _name, string memory _text) public payable {
        require(msg.value >= 0, "Not enough tokens");

        uint amount = msg.value / 20;

        _to.transfer(amount * 19);
        owner.transfer(amount);

        comments[_to].push(Comment(msg.sender, _name, _text, block.timestamp));
    }
}