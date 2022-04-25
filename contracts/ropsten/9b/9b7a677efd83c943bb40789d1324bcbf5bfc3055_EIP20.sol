/**
 *Submitted for verification at Etherscan.io on 2022-04-25
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

contract EIP20  {

    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    /*
    NOTE:
    The following variables are OPTIONAL vanities. One does not have to include them.
    They allow one to customise the token contract & in no way influences the core functionality.
    Some wallets/interfaces might not even bother to look at this information.
    */
    string public name;                   //fancy name: eg Simon Bucks
    uint8 public decimals;                //How many decimals to show.
    string public symbol;                 //An identifier: eg SBX
    address public owner;
    uint256 public totalSupply;
    
     event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    constructor()  {
		totalSupply = 1000000000000000000000000;
        balances[msg.sender] = totalSupply;               // Give the creator all initial tokens
        name = "Blockchain School for Management Token";                                   // Set the name for display purposes
        decimals = 18;                            // Amount of decimals for display purposes
        symbol = "BSM";                               // Set the symbol for display purposes
        owner = msg.sender;
    }

    function transfer(address _destinatariodeTokens, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value,"no tienes tantos tokens");
        balances[msg.sender] -= _value;
        balances[_destinatariodeTokens] += _value;
        emit Transfer(msg.sender, _destinatariodeTokens, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 allowances = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowances >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;

            allowed[_from][msg.sender] -= _value;
        
        emit Transfer(_from, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
	
	function burn(uint256 _tokensaEliminar) public returns(bool success) {
         require(msg.sender == owner, "only owner");
         require(balances[msg.sender] >= _tokensaEliminar);
        totalSupply -= _tokensaEliminar;
         balances[msg.sender] -= _tokensaEliminar;
        return true;
    }
    
	function mint(uint256 _nuevosTokens) internal returns(bool success) {
        totalSupply += _nuevosTokens;
        balances[msg.sender] += _nuevosTokens;
        emit Transfer(address(0), msg.sender, _nuevosTokens); 
        return true;
    }

    function buyToken () public payable {
        uint newTokens = msg.value * 100;  // 0.01 ethers = 1 token
       require(newTokens >= 10000000000000000, "not enough gas");  //minimum buy 0.01 tokens
       mint(newTokens);
    }

    receive () external payable  {   //   receive() external payable {
       buyToken();
    }
	
    /*function mint(uint256 _nuevosTokens) internal returns(bool success) {
        require(msg.sender == owner, "only owner");
        totalSupply += _nuevosTokens;
        balances[msg.sender] += _nuevosTokens;
        return true;
    }
    receive () external payable  {   //   receive() external payable {
        totalSupply += 1000000000000000000;
        balances[msg.sender] += 1000000000000000000;
    }*/
    
}


//0xd67ca60c7afe87b8a7dd427409e36cdd24a700c8