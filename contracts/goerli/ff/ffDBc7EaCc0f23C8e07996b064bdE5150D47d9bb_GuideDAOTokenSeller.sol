/**
 *Submitted for verification at Etherscan.io on 2023-06-11
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract GuideDAOTokenSeller {
    address public owner;
    address public token;
    uint public price;

    constructor(address _token, uint _price) {
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

    function setToken(address _token) public onlyOwner {
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
        (bool result, ) = token.call(
            abi.encodeWithSignature("mintTo(address)", tx.origin)
        );
        require(result, "Faild");
    }
}