/**
 *Submitted for verification at Etherscan.io on 2022-08-29
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

abstract contract ERC20_STD {

    function name() public view virtual returns (string memory);
    function symbol() public view virtual returns (string memory);
    function decimals() public view virtual returns (uint8);
    function totalSupply() public view virtual returns (uint256);
    function balanceOf(address _owner) public view virtual returns (uint256 balance);
    function transfer(address _to, uint256 _value) public virtual returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) virtual public returns (bool success);
    function approve(address _spender, uint256 _value) public virtual returns (bool success);
    function allowance(address _owner, address _spender) public view virtual returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}


contract OwnerShip {

    address public contractOwner; 
    address public newOwner;

    constructor() { 
        contractOwner = msg.sender;
    }

    function changeOwnership( address _to ) public {
        require( msg.sender == contractOwner, 'only contract owner can make changes');
        require( _to != address(0));
        newOwner = _to;
    }

    function acceptOwnership() public {
        require( msg.sender == newOwner, 'only assigned newOwner can accept');
        contractOwner = msg.sender;
        newOwner = address(0); 
    }
}


contract RareCaskHolding_v1 is ERC20_STD, OwnerShip {

    string public _name;
    string public _symbol;
    uint8 public _decimals;
    uint256 public _totalSupply; 
    uint16 public _expiryYear;
    string public _companyName;

    mapping( address => uint256 ) tokenBalances;
    mapping( address => mapping(address => uint256)) allowed; 

    address public _minter; 

    constructor( address setMinter ) {
        _name = 'Alpha Gold';
        _symbol = 'AACG';
        _decimals = 2;
        _totalSupply = 1000000;
        _minter = setMinter;
        _expiryYear = 2024;
        _companyName = "Fundnel.";
        tokenBalances[ _minter ] = _totalSupply;
    }


    function name() public view override returns (string memory) {
        return _name;
    }
    function symbol() public view override returns (string memory) {
        return _symbol;
    }
    function decimals() public view override returns (uint8) {
        return _decimals;
    }
    function totalSupply() public view override returns (uint256) {
        return _totalSupply; 
    }

    function companyName() public view returns (string memory) {
        return _companyName;
    }

    function expiryYear() public view returns (uint16) {
        return _expiryYear;
    }

    function balanceOf(address _owner) public view override returns (uint256 balance) {
        return tokenBalances[ _owner ]; 
    }
    function transfer(address _to, uint256 _value) public override returns (bool success) {
        require( tokenBalances[msg.sender] >= _value );
        require( _to != address(0));

        tokenBalances[msg.sender] -= _value;
        tokenBalances[_to] += _value; 

        emit Transfer( msg.sender, _to, _value);
        return true; 

    }
    function transferFrom(address _from, address _to, uint256 _value) override public returns (bool success){
        require( tokenBalances[ _from ] >= _value, 'must have enough token'   );
       
        require( allowed[_from][ msg.sender] >= _value, 'limit exceeded');

        tokenBalances[_from] -= _value;
        tokenBalances[ _to ] += _value; 
        allowed[_from][msg.sender] = allowed[_from][msg.sender] - _value;
    
        emit Transfer( _from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public override returns (bool) {

        require( tokenBalances[msg.sender] >= _value, 'Owner must have enough tokens');
        

        allowed[msg.sender][_spender] = _value; 

        return true;

    }
    function allowance(address _owner, address _spender) public view override returns (uint256 remaining) {
    
        return allowed[_owner][_spender]; 
    }
}