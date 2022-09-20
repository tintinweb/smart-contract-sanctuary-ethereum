// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

contract MyToken5 {
    ////////////////State Variables///////////////////////
 address private  admin;
 string public constant name = "Shahid Afridi";
 string public constant symbol = "SA";
 uint256 public totalSupply = 100 * 10 ** 8;
 uint256 public immutable decimals; 
 ////////////////////////////////Events//////////////////////////////

    event Transfer(address indexed recipient, address indexed to, uint256 amount);
    event Allowance(address indexed from, address indexed to, uint256 amount);
    
    //////////////////////Mappings///////////////////////

    mapping(address=>uint256) private balances;
    mapping(address=>mapping(address=>uint256)) private allowed;

    constructor() {
        admin = msg.sender;
        balances[msg.sender] = totalSupply;
        decimals = 8;
    } 

///////////////////////////Modifier///////////////////

    modifier onlyAdmin() {
        require(msg.sender == admin,"You are not allowed to do that");
        _;
    }

    /////////////////////Main Functions///////////////////////////

    function transfer(address reciever, uint256 amount) public returns(bool){
        require(balances[msg.sender] >= amount,"You dont have enough tokens to transfer");
        require(reciever != address(0),"This address does not exist");
        balances[msg.sender] -= amount;
        balances[reciever] += amount;

        emit Transfer(msg.sender,reciever,amount);
        return true;
    }

    function approval(address _spender, uint256 _value) public returns(bool success) {
         allowed[msg.sender][_spender] = _value;
         
         emit Allowance(msg.sender,_spender,_value);
         return true;
    } 

    function transferFrom(address _from, address _to, uint256 _value) public returns(bool success) {
        uint256 allowedTokens = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowedTokens>=_value);
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);
        return true;
    }


    ////////////////View Functions//////////////////////


    
    function allowance(address _owner, address _spender) public view returns(uint256){
       return allowed[_owner][_spender];
    }

    
    function balanceOf(address user) public view returns(uint256){
        return balances[user];
    }


}