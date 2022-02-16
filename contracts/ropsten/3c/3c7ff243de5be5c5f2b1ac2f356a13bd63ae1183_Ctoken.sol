/**
 *Submitted for verification at Etherscan.io on 2022-02-16
*/

pragma solidity ^0.4.20;

contract Ctoken{	
	address public owner;//定义代币所有者  
	string public tokenName;//用来存储代币的名字
	uint public initialSupply;//用来存储初始发行量
	uint public sellPrice = 1 finney;//指定卖出代币的价格，1finney=1代币
	uint public buyPrice = 1 finney;//指定购买代币的价格，1finney=1代币
	mapping (address => uint) public balance;//映射变量，用来存储某账户地址下的代币余额
	mapping (address => bool) public AccountState;//映射变量，用来存储某账户地址的状态（查看是否被冻结）
	event Transfer(address _to,uint256 _value);//定义事件

//定义函数修改器，只有代币所有者才能执行
	modifier onlyOwner{ 
	    if(msg.sender != owner){
		    revert();
    	}
    	else{
	    	_;
	    }
	}


//更改代币所有者函数
	function changeOwner(address newOwner) public onlyOwner{
		owner = newOwner;
	}

//合约的构造函数，部署合约时调用，用来让调用者指定一些初始化参数
	function Ctoken(uint _initialSupply,string _tokenName,address _tokenOwner) public payable{
		if (_tokenOwner != 0){
	    	owner = _tokenOwner;
		}
		initialSupply = _initialSupply;
		balance[owner] = initialSupply;
		tokenName = _tokenName;
		
		}

//回滚函数	
	function ()private payable{}

//代币增发函数	
	function mintToken(address target,uint256 send_Amount) public onlyOwner{
		if(target !=0){
			balance[target] += send_Amount;
			initialSupply += send_Amount;
		}
		else{
			revert();
		}
	}
		
//冻结账户函数
	function freezingAccount(address freezingTarget,bool accountState)public onlyOwner{
		if(freezingTarget !=0){
			AccountState[freezingTarget]=accountState;
		}
	}
		
//转账函数
	function transfer(address transfer_to,uint256 transferValue)public {
		if(AccountState[msg.sender]){
			revert();
		}
		if(balance[msg.sender]<transferValue){
			revert();
				
		}
		if(transferValue<0){
			revert ();
		}
		
		balance[msg.sender] -= transferValue;
		balance[transfer_to] += transferValue;
			
	}
		
//卖出代币函数
	function sell(uint sellAmount) public returns(uint revenue){
		if(AccountState[msg.sender]){
			revert();
		}
		if(balance[msg.sender]<sellAmount){
			revert();
		}
		if(sellAmount<0){
			revert();
		}
		balance[owner] += sellAmount;
		balance[msg.sender] -= sellAmount;
		revenue = sellAmount * sellPrice;
		if(msg.sender.send(revenue)){
			return revenue;
		}
		else{
			revert();
		}
	}

//购买代币函数
	function buy() public payable{
		if(AccountState[msg.sender]){
			revert();
		}
		if(balance[owner]<msg.value/buyPrice){
			revert();
		}
		balance[owner] -= msg.value/buyPrice;
		balance[msg.sender] += msg.value/buyPrice;
	}
        
}