/**
 *Submitted for verification at Etherscan.io on 2022-03-17
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >= 0.8.1 < 0.9.0;

contract ERC20 {
    uint public totalSupply;
    mapping(address => uint) private balances;
    mapping(address => mapping(address => uint)) private allowance;
    mapping(address => bool) private owners;

    constructor(uint _totalSupply, address[] memory _owners) {
        totalSupply = _totalSupply;
        for(uint i = 0; i < _owners.length; i++) {
            owners[_owners[i]] = true;
            balances[_owners[i]] = totalSupply/_owners.length;
        }
    }

    modifier isOwner() {
        require(owners[msg.sender], "Need owners access");
        _;
    }

    function tranfer(address _to, uint amount) external isOwner {
        require(!(balances[msg.sender] > amount), "Insufficient balance");

        balances[msg.sender] -= amount;
        balances[_to] += amount;
    }

    function approve(address spender, uint amount) external isOwner{
        allowance[msg.sender][spender] = amount;
    }

    function tranferFrom(address sender, address to, uint amount) external {
        require(allowance[sender][msg.sender] > amount, "Insufficient balance");
        allowance[sender][msg.sender] -= amount;
        balances[sender] -= amount;
        balances[to] += amount;
    }

    function balanceOf(address _balanceOf) external view returns(uint256) {
        return balances[_balanceOf];
    }

    function getAllowance(address owner, address spender) external view returns(uint256) {
        return allowance[owner][spender];
    }
}

// ["0x5B38Da6a701c568545dCfcB03FcB875f56beddC4", "0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2"]