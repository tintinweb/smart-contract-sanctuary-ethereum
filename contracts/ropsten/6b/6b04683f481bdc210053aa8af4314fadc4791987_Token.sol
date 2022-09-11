// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./ERC20.sol";

contract Token is ERC20 {

    address private owner;
    address private manager;

    modifier isOwner {
        require(msg.sender == owner, "not an owner");
        _;
    }

    constructor(uint _totalTokens) ERC20(_totalTokens) {
        owner = msg.sender;
    }

    function transfer(address to, uint noOfTokens) public isOwner override {
        super.transfer(to, noOfTokens);
    }

    function transferFrom(address from, address to, uint noOfTokens) public isOwner override {
        super.transferFrom(from,to,noOfTokens);
    }

    function setManager(address _manager) isOwner external {
        manager = _manager;
    }

    function getManager() external view returns (address){
        return manager;
    }

    function burn(address _owner, uint256 _noOfTokens) public {
        require(msg.sender == manager, "Not manager");
        require (balance(owner) > 0, "Invalid balance");
        emit Transfer(_owner, address(0), _noOfTokens);
        investorTokens[_owner] -= _noOfTokens;
        totalTokens -= _noOfTokens;
    }

}