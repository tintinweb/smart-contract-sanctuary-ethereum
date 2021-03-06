pragma solidity ^0.4.24;
  contract SafeMath {
  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  function safeSub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }
  function safeAdd(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }
  }
  contract Ownership is SafeMath {
	address public fundWallet;
	modifier onlyFundWallet {
        require(msg.sender == fundWallet);
        _;
    }
	function changeFundWallet(address newFundWallet) external onlyFundWallet {
        require(newFundWallet != address(0));
        fundWallet = newFundWallet;
    }

	}    
  	contract Token { // ERC20 standard
		function balanceOf(address _owner) public  view returns (uint256 balance);
		function transfer(address _to, uint256 _value) public  returns (bool success);
		function transferFrom(address _from, address _to, uint256 _value) public  returns (bool success);
		function approve(address _spender, uint256 _value)  returns (bool success);
		function allowance(address _owner, address _spender) public  view returns (uint256 remaining);
		event Transfer(address indexed _from, address indexed _to, uint256 _value);
		event Approval(address indexed _owner, address indexed _spender, uint256 _value);
	}
	
  contract STCListing is Ownership {
	string public name = "STC Listing";
	bool public enable = true;
	uint256 public count =0 ;
	
	// MAPPING
	mapping (uint256 => Sendvalue) public recivedEther;
		
	  // EVENTS
    event Recived(address indexed participant,uint256 amountEther);
	event SendBack(address indexed participant,uint256 amountEther);  
	event UsedValue(address indexed participant,uint256 beforeUsed,uint256 afterUsed);  
	event Withdraw(uint256 amountEther);
	 
	// TYPES
	struct Sendvalue { // tokensPerEth
		address sender;
		uint256 value;
	}		
	 // CONSTRUCTOR
	function STCListing() public  {
        fundWallet = msg.sender;
    }

	
	function getLowerSend() public  view returns (address _sender, uint256 _value)  {	
	    if (count <1){return (address(0),0);}
		uint256 k =1;	
		uint256 index;		
		for (index = 1; index <= count; index++){
				if (recivedEther[k].value > recivedEther[index].value){
					k=index;
				}		
			} 
		return (recivedEther[k].sender , recivedEther[k].value);			
	}
	function getMaxSend() public  view returns (address _sender, uint256 _value) {	
	    if (count <1){return (address(0),0);}
		uint256 k =1;	
		uint256 index;			
		for (index = 1; index <= count; index++){
				if (recivedEther[k].value < recivedEther[index].value){
					k=index;
				}		
			}
		return (recivedEther[k].sender , recivedEther[k].value);			
	}
	function sumBalance() public  view returns (uint256 _value) {	
	    if (count <1){return 0;}
		uint256 k =1;	
		uint256 _balance = 0;
		uint256 index;			
		for (index = 1; index <= count; index++){
				_balance = safeAdd(_balance,recivedEther[index].value);
			}
		return _balance;			
	}	
	function usedvalue() public  view returns (uint256 _value) {
	    uint256 _sumSend = sumBalance();
		return safeSub(_sumSend,this.balance);
	}
	function removeused() external onlyFundWallet {	
	   require(count >0);
	   uint256 _sumSend = sumBalance();
	   uint256 _used = safeSub(_sumSend,this.balance);
	   uint256 _notused = this.balance;
	   uint256 _vector = safeMul((_sumSend / _notused),1000000000000000000);
	   uint256 index;	
	  	for (index = 1; index <= count; index++){
			if(recivedEther[index].value>0) {			
				uint256 _beforereduce = recivedEther[index].value;	
				 
				recivedEther[index].value = safeMul(recivedEther[index].value,_vector ) / 1000000000000000000;	
				UsedValue(recivedEther[index].sender, _beforereduce,recivedEther[index].value);	
			}			
		}			
	}		
	function sendRestBack() external onlyFundWallet {
		require(count >0);
		uint256 index;	
		for (index = 1; index <= count; index++){	
			uint256 _forsendback = recivedEther[index].value;			
			if(this.balance >= recivedEther[index].value) {
				recivedEther[index].value = 0;
				recivedEther[index].sender.transfer(_forsendback);	
				SendBack(recivedEther[index].sender,_forsendback);	
			}		
		}
	}
	
	
	function removeLiquidity(uint256 amount) external onlyFundWallet {
        require(amount <= this.balance);
        fundWallet.transfer(amount);
		Withdraw(amount);
    }	
	function stop() external onlyFundWallet {
        enable = false;
    }
	function start() external onlyFundWallet {
        enable = true;
    }
	function() payable {
		require(tx.origin == msg.sender);
		require(enable);
		require(msg.value>0);
		count =	safeAdd(count,1);		
		recivedEther[count] = Sendvalue(msg.sender,msg.value);
		Recived(msg.sender,msg.value);
	}
	function claimTokens(address _token) external onlyFundWallet {
			require(_token != address(0));
			Token token = Token(_token);
			uint256 balance = token.balanceOf(this);
			token.transfer(fundWallet, balance);
	}	 
  }