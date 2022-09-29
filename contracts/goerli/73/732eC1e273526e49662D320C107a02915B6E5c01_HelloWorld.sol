// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract HelloWorld {
    string public name = "wangjin";
    uint256 public age = 24;

    constructor(string memory _name) payable {
        name = _name;
    }

    function setName(address payable to, uint256 amount) public {
        (bool success, )  = to.call{value: amount}("");
        require(success, "recover ETH falied");
    }
}