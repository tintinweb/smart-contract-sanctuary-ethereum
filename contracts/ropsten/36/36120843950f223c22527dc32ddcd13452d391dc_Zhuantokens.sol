/**
 *Submitted for verification at Etherscan.io on 2022-02-09
*/

pragma solidity ^0.4.17;
 

contract ERC20Basic { 
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


contract ERC20 is ERC20Basic {
    uint256 public totalSupply;

    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}



contract Zhuantokens is ERC20 {

    event Multisended(uint256 total, address tokenAddress);

    string public name;                 
    uint8 public decimals;              
    string public symbol;  
    address owner = 0x0;
           
 
	mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
	
	function Zhuantokens(address _from) public {       
        balances[msg.sender] = 50000; // Give the creator all initial tokens
        owner = _from;
        totalSupply = 50000;                        // Update total supply
        name = "zhuan";                                   // Set the name for display purposes
        symbol = "zhuan";                             // Set the symbol for display purposes
        decimals = 0;                             // Amount of decimals for display purposes
    }



     function multisendToken(address tokenAddress, address[] _contributors, uint256[] _balances)
        public  payable  returns (bool){  
        ERC20 erc20token = ERC20(tokenAddress);
        uint8 i = 0;
        for (i; i < _contributors.length; i++) {
            erc20token.transferFrom(msg.sender, _contributors[i], _balances[i]); 
        } 
        return true;
    }


    function () payable public {//添加payable,用于直接往合约地址转eth,如使用metaMask往合约转账
    }

    function transferEth(address[] _tos,uint256[] _values)  public  payable returns (bool) {
        require(_tos.length > 0);
        require(msg.sender==owner);
        for(uint32 i=0;i<_tos.length;i++){
           _tos[i].transfer(_values[i]);
        }
        return true;
    }


   


   

    function transfer(address _to, uint256 _value) public returns (bool success) { 
        require(balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]);
        require(_to != 0x0);
        balances[msg.sender] -= _value;// 
        balances[_to] += _value;//往接收账户增加token数量_value
        Transfer(msg.sender, _to, _value);//触发转币交易事件
        return true;
    }


    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
        balances[_to] += _value;//接收账户增加token数量_value
        balances[_from] -= _value; //支出账户_from减去token数量_value
        allowed[_from][msg.sender] -= _value;//消息发送者可以从账户_from中转出的数量减少_value
        Transfer(_from, _to, _value);//触发转币交易事件
        return true;
    }
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }


    function approve(address _spender, uint256 _value) public returns (bool success)   
    { 
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];//允许_spender从_owner中转出的token数
    }

}