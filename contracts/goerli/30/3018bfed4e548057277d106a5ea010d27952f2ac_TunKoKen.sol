/**
 *Submitted for verification at Etherscan.io on 2023-01-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TunKoKen{
    string public name; //full name token
    string public symbol; //symbol token
    uint8 public decimals; //decimal a token
    uint256 public totalSupply; //all token supply
    address public minter;

    mapping(address => uint256) public balanceOf; //keep address(uint256) balanceOf[address]
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);// event transfer
    event Approval(address indexed owner, address indexed spender, uint256 value);// event approval

    constructor(){
        name = "TunKoKen";
        symbol = "TKK";
        decimals = 18;
        totalSupply = 1000 * (10 ** uint256(decimals));
        balanceOf[msg.sender] = totalSupply;
        minter = msg.sender;
    }

    function transfer (address _to, uint256 _value) public returns(bool) { // function for transfer 
        require(_to != address(0),"Cann't transfer to address 0."); //no way to transfer address(0)
        require(balanceOf[msg.sender]>= _value && _value > 0,"Not enough balance."); // check value
        balanceOf[msg.sender] -= _value; 
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value); // tracking transfer
        return(true);
    }
    function approve (address _spender, uint256 _value) public returns (bool){
        require(_spender != address(0),"Can't approve to address 0.");
        require(balanceOf[msg.sender] >= _value && _value > 0,"Not enough balance");
        allowance[msg.sender][_spender] = _value; //approve msg.sender approve value for spender
        emit Approval(msg.sender, _spender, _value); // tracking approve
        return(true);
    }
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool){
        require(_from != address(0),"Can't transfer from address 0.");
        require(_to != address(0), "Can't approve to address 0.");
        require(balanceOf[_from] <= _value,"Not enough balance (from)");
        require(balanceOf[_to] <= _value,"Not enough balance (to)");
        allowance[_from][msg.sender] -= _value;
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        return(true);
    }
    function mint(address _to, uint256 _value) public {
        require(msg.sender == minter, "Only minter can mint new token!.");
        require(_value > 0,"Can't mint 0.");
        totalSupply += _value;
        balanceOf[_to]+= _value;
        emit Transfer(address(0), _to, _value);
    }
}