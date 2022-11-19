/**
 *Submitted for verification at Etherscan.io on 2022-11-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract assignmentToken {
    // TODO: specify `MAXSUPPLY`, declare `minter` and `supply`
    uint256 _supply = 50000;
    uint256 constant _maxSupply = 1000000;
    // Defining minter as variable
    address public _minter;

    // TODO: specify event to be emitted on transfer
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    // TODO: specify event to be emitted on approval
    event Approval(
    address indexed _spender,
    address indexed _owner,
    uint256 _value
  );

    event MintershipTransfer(
        address indexed previousMinter,
        address indexed newMinter
    );

    // TODO: create mapping for balances
    mapping(address => uint256) public balances;

    // TODO: create mapping for allowances
    mapping(address => mapping(address=>uint256)) public allowances;

    constructor() {
        // TODO: set sender's balance to total supply
        _minter = msg.sender;
        balances[msg.sender] = _supply;
    }

    function totalSupply() public view returns (uint256) {
        // TODO: return total supply
        return _supply;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        // TODO: return the balance of _owner
        return balances[_owner];
    }

    function mint(address _receiver, uint256 _value) public returns (bool) {
        // TODO: mint tokens by updating receiver's balance and total supply
        // NOTE: total supply must not exceed `MAXSUPPLY`
        // require(_value + _supply <= _maxSupply);
        require(_supply <= _maxSupply);
        require(msg.sender == _minter);
        balances[_receiver] += _value;
        _supply += _value;
        emit Transfer(msg.sender, _receiver, _value);
        return true;
    }

    function burn(uint256 _value) public returns (bool) {
        // TODO: burn tokens by sending tokens to `address(0)`
        // NOTE: must have enough balance to burn
        require(balances[msg.sender] >= _value);
        _supply -= _value;
        balances[msg.sender] -= _value;
        emit Transfer(msg.sender, address(0), _value);
        return true;
    }

    function transferMintership(address newMinter) public returns (bool) {
        // TODO: transfer mintership to newminter
        // NOTE: only incumbent minter can transfer mintership
        // NOTE: should emit `MintershipTransfer` event
        require(msg.sender == _minter);
        _minter = newMinter;
        emit MintershipTransfer(msg.sender, newMinter);
        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        // TODO: transfer `_value` tokens from sender to `_to`
        // NOTE: sender needs to have enough tokens
        // NOTE: transfer value needs to be sufficient to cover fee
        require(balances[msg.sender] >= _value);
        require(_value >= 1);
        balances[msg.sender] -= _value;
        balances[_to] += (_value - 1);
        balances[_minter] += 1;
        emit Transfer(msg.sender, _to, (_value-1));
        emit Transfer(msg.sender, _minter, 1);
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
        require(_value >= 1);
        require(balances[_from] >= _value);
        require(allowances[_from][msg.sender] >= _value);
        balances[_from] -= _value;
        balances[_to] += (_value - 1);
        balances[_minter] += 1;
        allowances[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value-1);
        emit Transfer(_from, _minter, 1);
        return true;
    }

    function approve(address _owner, address _spender, uint256 _value) public returns (bool) {
        // TODO: allow `_spender` to spend `_value` on sender's behalf
        // NOTE: if an allowance already exists, it should be overwritten
        allowances[msg.sender][_spender] = _value;
        emit Approval(_owner, _spender, _value);
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