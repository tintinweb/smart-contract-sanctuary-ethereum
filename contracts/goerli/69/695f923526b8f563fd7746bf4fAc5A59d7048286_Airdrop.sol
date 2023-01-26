// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Airdrop {
    address public triflex;
    address public owner;
    mapping(address => uint256) private claims;

    modifier onlyOwner() {
        require(msg.sender == owner, "Invalid Owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function setTriflex(address _triflex) external onlyOwner {
        triflex = _triflex;
    }

    function revokeOwner() external onlyOwner {
        owner = address(0);
    }

    function storeClaims(address[] memory _users, uint256[] memory _balances)
        external
        onlyOwner
    {
        require(_users.length == _balances.length, "Invalid input values");
        for (uint256 i = 0; i < _users.length; i++) {
            require(claims[_users[i]] == 0, "Already added");
            claims[_users[i]] = _balances[i];
        }
    }

    function claimBalance(address user) external returns (uint256 balance) {
        require(msg.sender == triflex, "Invalid triflex call");
        require(claims[user] != 0, "Already claimed");
        balance = claims[user];
        delete claims[user];
    }
}