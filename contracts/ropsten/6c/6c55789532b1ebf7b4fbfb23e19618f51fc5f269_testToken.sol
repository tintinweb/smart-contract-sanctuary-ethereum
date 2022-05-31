/**
 *Submitted for verification at Etherscan.io on 2022-05-31
*/

pragma solidity 0.6.1;

contract testToken {
    string public name = "TestToken2";
    string public symbol = "TTN";
    uint8 public decimals = 2;
    mapping (address => uint256) public balances;
    uint256 public totalSupply;
    event Transfer(address indexed from, address indexed to, uint256 value);

    function balanceOf (address owner) public view returns (uint256) {
        return balances[owner];
    }

    function transfer(address to, uint256 value) public returns (bool) {
        balances[msg.sender] -= value;
        balances[to] += value;
        emit Transfer(msg.sender, to, value);
    }

    function _mint(address account, uint256 value) public {
        totalSupply += value;
        balances[account] += value;
        emit Transfer(address(0), account, value);
    }
}