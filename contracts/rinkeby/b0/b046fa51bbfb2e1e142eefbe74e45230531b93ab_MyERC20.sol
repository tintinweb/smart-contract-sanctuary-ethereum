// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

//Source: https://ethereum.org/en/developers/tutorials/understand-the-erc-20-token-smart-contract/

contract MyERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping(address => uint256) private _balances;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _total
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _total;
        _balances[msg.sender] = _total;
    }

    function balanceOf(address tokenOwner) public view returns (uint256) {
        return _balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens) public {
        require(numTokens <= _balances[msg.sender]);
        _balances[msg.sender] = _balances[msg.sender] - numTokens;
        _balances[receiver] = _balances[receiver] + numTokens;
    }
}