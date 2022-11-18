/**
 *Submitted for verification at Etherscan.io on 2022-11-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract Moon {
    // TODO: specify `MAXSUPPLY`, declare `minter` and `supply`
    uint MAXSUPPLY = 1000000e18;
    address minter;
    uint256 supply;
    uint256 fee;

    // TODO: specify event to be emitted on transfer
    event Transfer(
        address indexed _from, 
        address indexed _to, 
        uint256 _amount);
    // TODO: specify event to be emitted on approval
    event Approve(
        address indexed _owner, 
        address indexed _spender, 
        uint256 _amount);

    event MintershipTransfer(
        address indexed previousMinter,
        address indexed newMinter
    );

    // TODO: create mapping for balances
    mapping(address=>uint) balances;
    // TODO: create mapping for allowances
    mapping(address=>mapping(address=>uint256)) allowances;

    constructor() {
        // TODO: set sender's balance to total supply
        minter = msg.sender;
        mint(minter,50000e18);
        supply = 50000e18;
        fee = 1e18;
    }

    function totalSupply() public view returns (uint256) {
        // TODO: return total supply
        return supply;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        // TODO: return the balance of _owner
        return balances[_owner];
    }

    function mint(address receiver, uint256 amount) public returns (bool) {
        // TODO: mint tokens by updating receiver's balance and total supply
        // NOTE: total supply must not exceed `MAXSUPPLY`
        require(msg.sender==minter);
        require(supply+amount<=MAXSUPPLY);
        supply += amount;
        balances[receiver] += amount;
        emit Transfer(address(0), msg.sender, amount);
        return true;
    }

    function burn(uint256 amount) public returns (bool) {
        // TODO: burn tokens by sending tokens to `address(0)`
        // NOTE: must have enough balance to burn
        require(balances[msg.sender]>=amount);
        supply -= amount;
        balances[msg.sender] -= amount;
        emit Transfer(msg.sender, address(0), amount);
        return true;
    }

    function transferMintership(address newMinter) public returns (bool) {
        // TODO: transfer mintership to newminter
        // NOTE: only incumbent minter can transfer mintership
        // NOTE: should emit `MintershipTransfer` event
        require(msg.sender==minter);
        minter = newMinter;
        emit MintershipTransfer(msg.sender, newMinter);
        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        // TODO: transfer `_value` tokens from sender to `_to`
        // NOTE: sender needs to have enough tokens
        // NOTE: transfer value needs to be sufficient to cover fee
        require(balances[msg.sender]>=_value);
        require(_value>=fee);
        balances[msg.sender] -= _value;
        balances[_to] += _value - fee;
        balances[minter] += fee;
        emit Transfer(msg.sender, _to, _value-fee);
        emit Transfer(msg.sender, minter, fee);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool) {
        // TODO: transfer `_value` tokens from `_from` to `_to`
        // NOTE: `_from` needs to have enough tokens and to have allowed sender to spend on his behalf
        // NOTE: transfer value needs to be sufficient to cover fee
        require(allowances[_from][msg.sender] >= _value);
        require(balances[_from]>=_value);
        require(_value>=fee);
        balances[_from] -= _value;
        balances[_to] += _value - fee;
        balances[minter] += fee;
        emit Transfer(_from, _to, _value-fee);
        emit Transfer(_from, minter, fee);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        // TODO: allow `_spender` to spend `_value` on sender's behalf
        // NOTE: if an allowance already exists, it should be overwritten
        allowances[msg.sender][_spender] = _value;
        return true;
    }

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256 remaining)
    {
        // TODO: return how much `_spender` is allowed to spend on behalf of `_owner`
        return allowances[_owner][_spender];
    }
}