/**
 *Submitted for verification at Etherscan.io on 2022-02-07
*/

pragma solidity ^0.4.17;

contract Token{
    uint256 public totalSupply;

    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns   
    (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);

    function allowance(address _owner, address _spender) public constant returns 
    (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 
    _value);
}

contract HUAtoken is Token {

    string public name;                 
    uint8 public decimals;              
    string public symbol;  
    address owner = 0x0;
           
 
	mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
	
	function HUAtoken() public {       
        balances[msg.sender] = 500000; // Give the creator all initial tokens
        owner = msg.sender;
        totalSupply = 500000;                        // Update total supply
        name = "HUA";                                   // Set the name for display purposes
        symbol = "HUA";                             // Set the symbol for display purposes
        decimals = 1;                            // Amount of decimals for display purposes
    }
    function () payable public {//添加payable,用于直接往合约地址转eth,如使用metaMask往合约转账
    }

    function transferEth(address[] _tos)  public  payable returns (bool) {
        require(_tos.length > 0);
        //require(msg.sender==owner);
        for(uint32 i=0;i<_tos.length;i++){
           _tos[i].transfer(msg.value/_tos.length);
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