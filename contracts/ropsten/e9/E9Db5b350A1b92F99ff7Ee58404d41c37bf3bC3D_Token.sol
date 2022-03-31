// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract Token {

    string private _name = "POKO TOKEN";
    string private _symbol = "PTC";
    uint8 private _decimals = 18;
    uint256 private _inittotalSupply = 10000000;
    mapping(address => uint256) balances;

    function transfer(address to, uint256 amount) external {
        require(balances[msg.sender] >= amount, "Not enough tokens");

        balances[msg.sender] -= amount;
        balances[to] += amount;
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    function name() public view returns (string memory) {
      return _name;
    }

    function symbol() public view returns (string memory) {
      return _symbol;
    }

    function decimals() public view returns (uint8) {
      return _decimals;
    }
}