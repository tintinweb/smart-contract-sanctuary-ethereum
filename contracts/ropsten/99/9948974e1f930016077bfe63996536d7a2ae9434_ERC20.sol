/**
 *Submitted for verification at Etherscan.io on 2022-06-21
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >= 0.5.0 < 0.9.0;

contract ERC20 {
    mapping(address => uint256) balances;

    uint256 _totalSupply;

    address public owner;

    constructor(uint256 total) {
        _totalSupply = total;
        balances[msg.sender] = _totalSupply;
        owner = msg.sender;
    }

    function totalSupply() public view returns(uint256) {
        return _totalSupply;
    }

    function balanceOf(address tokenOwner) public view returns(uint256) {
        return balances[tokenOwner];
    }

    // for finding owner address
    function ownerAddress() public view returns(address) {
        return owner;
    }

    function transfer(address reciever, uint quantity) public returns(bool) {
        require(quantity <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender] - quantity;
        balances[reciever] = balances[reciever] + quantity;

        // emit Transfer(msg.sender, reciever, quantity);

        return true;
    }
}