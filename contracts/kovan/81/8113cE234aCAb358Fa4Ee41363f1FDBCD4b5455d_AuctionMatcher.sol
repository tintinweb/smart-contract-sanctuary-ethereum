// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

contract AuctionMatcher {
    address public owner;
    address public matcher;

    event OwnershipTransferred(address previousOwner, address newOwner);

    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    modifier onlyMatcher() {
        require(matcher == tx.origin);
        _;
    }

    constructor(address _matcher) {
        owner = msg.sender;
        matcher = _matcher;
    }

    function setMatcher(address _matcher) public onlyOwner {
        matcher = _matcher;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));

        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    function isMatcher() public onlyMatcher {}
}