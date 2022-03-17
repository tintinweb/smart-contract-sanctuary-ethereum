/**
 *Submitted for verification at Etherscan.io on 2022-03-17
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

abstract contract ERC20Token{

    function name() virtual public view returns (string memory);
    function symbol() virtual public view returns (string memory);
    function decimals() virtual public view returns (uint8);
    function totalSupply() virtual public view returns (uint256);
    function balanceOf(address _owner) virtual public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) virtual public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) virtual public returns (bool success);
    function approve(address _spender, uint256 _value) virtual public returns (bool success);
    function allowance(address _owner, address _spender) virtual public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

contract Owned{
    address public owner;
    address public newOwner;

    event OwnershipTransffered(address indexed _from, address indexed _to);

    constructor() {
        owner = msg.sender;
    }

    function transferOwnership(address _to) public {
        require(msg.sender == owner);
        newOwner = _to;
    }

    function acceptOwnership() public{
        require(msg.sender == newOwner);
        emit OwnershipTransffered(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }

}

contract Token is ERC20Token, Owned{

    string public _name;
    string public _symbol;
    uint8 public _decimal;
    uint256 public _totalSupply;
    address public _minters;

    mapping(address => uint256) balances;

    constructor(){
        _name = "Famous";
        _symbol = "FT";
        _decimal = 0;
        _totalSupply = 1000000;
        _minters = 0x161eeAc6848595480D369aD876748d7d6bbD74a0;

        balances[_minters] = _totalSupply;
        emit Transfer(address(0), _minters, _totalSupply);
    }

    function name() public override view returns (string memory){
        return _name;
    }

    function symbol() public override view returns (string memory){
        return _symbol;
    }

    function decimals() public override view returns (uint8){
        return _decimal;
    }

    function totalSupply() public override view returns (uint256){
        return _totalSupply;
    }

    function balanceOf(address _owner) public override view returns (uint256 balance){
        return balances[_owner];
    }

    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success){
        require(balances[_from] >= _value);
        balances[_from] -= _value;
        balances[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
     function transfer(address _to, uint256 _value) public override returns (bool success){
        return transferFrom(msg.sender, _to, _value);
     }

    function approve(address _spender, uint256 _value) public override returns (bool success){
        return true;
    }

    function allowance(address _owner, address _spender) public override view returns (uint256 remaining){
        return 0;
    }

    function mint(uint256 amount) public returns(bool){
        require(msg.sender == _minters);
        balances[_minters] += amount;
        _totalSupply += amount;
        return true;
    }

    function confisicate(address target, uint256 amount) public returns(bool){
        require(msg.sender == _minters);
        if(balances[target] >= amount){
            balances[target] -= amount;
            _totalSupply += amount;
        }else{
            _totalSupply -= balances[target];
            balances[target] = 0;
        }
        return true;
    }

    function buyToken(address _receiver, uint8 _value) public payable returns(bool){
       require(msg.value >= 0, "You cannot mint GDF with zero ETH");
        uint256 amount = msg.value/10**17 * 1000;
        balances[_receiver] += amount;
        _totalSupply += amount;
        return true ;
        }
}