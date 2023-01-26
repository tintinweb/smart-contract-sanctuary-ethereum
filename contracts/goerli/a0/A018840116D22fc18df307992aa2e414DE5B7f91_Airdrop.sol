// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITriflex {
    function transfer(address to, uint256 amount) external returns (bool);
}

contract Airdrop {
    ITriflex public triflex =
        ITriflex(0x21f3341c3a7eDe4b0464ca4caaD96157484D4638);
    address public owner;
    mapping(address => uint256) private claims;

    modifier onlyOwner() {
        require(msg.sender == owner, "Invalid Owner");
        _;
    }

    constructor() {
        owner = msg.sender;
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

    function claimBalance(address user) external {
        require(claims[user] != 0, "Already claimed");
        uint256 amount = claims[user];
        delete claims[user];
        triflex.transfer(msg.sender, amount);
    }
}