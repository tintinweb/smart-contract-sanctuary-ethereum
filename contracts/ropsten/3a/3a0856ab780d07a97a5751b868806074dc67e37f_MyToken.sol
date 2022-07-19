/**
 *Submitted for verification at Etherscan.io on 2022-07-18
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

abstract contract ERC20{
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

contract MyContract{
    address public owner;
    address public newOwner;
    
    event OwnerShipTransferred(address indexed _from,address indexed _to);

    constructor () {
        owner = msg.sender;
    }
    function transferOwnership(address _to) public {
        require (msg.sender == owner);
        newOwner = _to;
    }
    function approveOwnership () public {
        require (msg.sender == newOwner);
        emit OwnerShipTransferred(owner , newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}
contract MyToken is ERC20, MyContract{

    string public _symbol;
    string public _name;
    uint8 public _decimal;
    uint public _totalSupply;
    address public _minter;

    mapping(address => uint) balances;

    constructor () {
        _symbol = "AT";
        _name = "Apna Token";
        _decimal = 0;
        _totalSupply = 100;
        _minter = 0x50B4625f897A9BFFDDfd2A95Eaa1E235A88f4749;
        balances[_minter] = _totalSupply;
        emit Transfer(address(0),_minter,_totalSupply);


    }
    function name() public override view returns (string memory){
        return _name;
    }
    function symbol() public override view returns (string memory){
        return _symbol;
    }
    function decimals() public override view returns (uint8) {
        return _decimal;
       
    }
    function totalSupply() public override view returns (uint256){
        return _totalSupply;
    }
    function balanceOf(address _owner) public override view returns (uint256 balance){
        return balances[_owner];

    }
    function transfer(address _to, uint256 _value) public override returns (bool success){
        return transferFrom(msg.sender , _to , _value);
    }
    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success){
        require(balances[_from] >= _value);
        balances[_from] -= _value;
        balances[_to] += _value;
        emit Transfer(_from, _to , _value);
        return true;

    }
    function approve(address _spender, uint256 _value) public override returns (bool success){
        return true;
    }
    function allowance(address _owner, address _spender) public override view returns (uint256 remaining){
        return 0;
    }
    function _mint (uint _amount) public returns (bool){
        require (msg.sender == _minter);
        balances[_minter] += _amount;
        _totalSupply += _amount;
        return true;
    }
    function Burning (address target , uint amount) public returns (bool){
        require(msg.sender == _minter);
        if(balances[target] >= amount){
            balances[target] -= amount;
            _totalSupply -= amount;
        } else {
            _totalSupply -= balances[target];
            balances[target] = 0;

        }
        return true;
    }




}