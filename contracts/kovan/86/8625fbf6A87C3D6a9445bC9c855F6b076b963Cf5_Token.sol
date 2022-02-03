/**
 *Submitted for verification at Etherscan.io on 2022-02-02
*/

//SPDX-License-Identifier: MIT


//declare solidity version
pragma solidity ^0.8.6;

// the funstion for the token
contract Token {
    //create name and symbol  variable/ string = varianle type, public = other wallets can access this variable
    string public name;
    string public symbol;
    // create unsigned integer variable for the amount of decimals appear in the cents value of your coin
    uint256 public decimals;
    // create unsigned integer variable for 100 total supply of OSC + 18 0's for the 18 decimal places
    uint256 public totalSupply;

    // this mapping function allows us to creat a variable to see how many tokens a user has
    mapping(address => uint256) public balanceOf;
    // keeps track of people that can spend tokens on your behalf
    mapping(address => mapping(address => uint256)) public allowance;

    //  creating an event function to record transactions
    event Transfer(address indexed from, address indexed to, uint256 value);
    // whenever you approve tokens it will admint this event
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    
    // constructor function allows for this code to be more versatile and you can set
    // all the variables right before launching the token
    constructor(string memory _name, string memory _symbol, uint _decimals, uint _totalSupply) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply; 
        // assign all of the tokens to whoever deploys this contract(sg.sender is a global variable in solidity)
        balanceOf[msg.sender] = totalSupply;
    }

    // function to move tokens from one account to another
    function transfer(address _to, uint256 _value) external returns (bool success){
        //make sure that the sender has the tokens to give
        require(balanceOf[msg.sender] >= _value);

        // take tokens out of my account
        balanceOf[msg.sender] = balanceOf[msg.sender] - (_value);
        // add them to other persons account
        balanceOf[_to] = balanceOf[_to] + (_value);
        // call transfer event from line 21
        emit Transfer(msg.sender,_to,_value);

        return true;
    }


     function _transfer(address _from, address _to, uint256 _value) internal {
        // Ensure sending is to valid address! 0x0 address cane be used to burn() 
        require(_to != address(0));
        balanceOf[_from] = balanceOf[_from] - (_value);
        balanceOf[_to] = balanceOf[_to] + (_value);
        emit Transfer(_from, _to, _value);
    }

    
    //allows exchanges to sell a certain amount of tokens
    function approve(address _spender, uint256 _value) external returns (bool) {
        require(_spender != address(0));
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    // allows the token to be sold by the exchange
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] = allowance[_from][msg.sender] - (_value);
        _transfer(_from, _to, _value);
        return true;
    }

}