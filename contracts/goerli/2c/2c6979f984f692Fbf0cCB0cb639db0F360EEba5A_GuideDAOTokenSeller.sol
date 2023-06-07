/**
 *Submitted for verification at Etherscan.io on 2023-06-07
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IMintableTo {
    function mintTo(address to) external;
}

contract GuideDAOTokenSeller {
    address public owner;
    IMintableTo public token;
    uint public price;

    constructor(IMintableTo _token, uint _price) {
        owner = msg.sender;
        token = _token;
        price = _price;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not an owner!");
        _;
    }

    function setOwner(address _owner) public onlyOwner {
        owner = _owner;
    }

    function setToken(IMintableTo _token) public onlyOwner {
        token = _token;
    }

    function setPrice(uint _price) public onlyOwner {
        price = _price;
    }

    function withdraw() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function buy() external payable {
        require(msg.value >= price, "Too little money!");
        token.mintTo(msg.sender);
    }
}