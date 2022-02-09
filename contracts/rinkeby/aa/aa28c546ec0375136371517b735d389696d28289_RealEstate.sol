/**
 *Submitted for verification at Etherscan.io on 2022-02-08
*/

pragma solidity >=0.8.0 < 0.9.0;

contract RealEstate{

    
    address payable mainowner=payable(msg.sender);
    address payable user;
    uint256 _total;
    uint256 amount;
    uint256 tokens;

    address[] investors;
    

    uint256 withdraw_amount;
    
      
    uint256 public accumulation;
    uint256 public Token_Price;
    uint256 public Rent_per_Second;
    uint256  public StartTime;

    
    
    string public apartment_name;
    string public apartment_symbol;

    mapping(address=>uint256) public balances;
    mapping(address=>uint256) public income;

    event Investor(address who, uint amount , uint time);
    event Deposit(address issuer,uint amount,uint time);
    event Withdraw(address _recipient,uint _amount,uint time);
    
    

   constructor(string memory _propertyID, string memory _propertysymbol, uint256 total) {
        balances[msg.sender]=total;
        apartment_name=_propertyID;
        apartment_symbol=_propertysymbol;
        _total=total;
        income[msg.sender]=0;
        
    }

    function offerprice (uint256 _price) public{                   //This must be in WEI
        require(msg.sender==mainowner,"You are not allowed");
        Token_Price=_price;                             
        
    }
    
    function buytokens() public payable{                           //This has to be converted in ethereum
        tokens=msg.value/Token_Price;       
        balances[msg.sender]+=tokens;
        balances[mainowner] -= tokens;
        mainowner.transfer(msg.value);
        investors.push(msg.sender);
         
        emit Investor(msg.sender,tokens,block.timestamp);              
               
    }

    function rent_per_second(uint256 price) public{                //has to be set in WEI
        require(msg.sender==mainowner);
        Rent_per_Second=price;
        StartTime=block.timestamp;
    }
    
    function getTime () public view returns(uint256 time){
        return block.timestamp;
    }

   
    function _topay() public view returns(uint256 time){
        return (block.timestamp - StartTime)*Rent_per_Second;
    }

    function payrent() public payable{

        uint256 minAmount = (block.timestamp - StartTime)*Rent_per_Second;
        require (msg.value >= minAmount,"Not enough funds");
        uint256 moneyToReturn = msg.value - minAmount; 
        if(moneyToReturn >0){
        user=payable(msg.sender);
        user.transfer(moneyToReturn);        
        accumulation += (minAmount);       
        }
        else {(accumulation+=msg.value);
        }
                
        emit Deposit(msg.sender,minAmount,block.timestamp);
      
    
    }

    function withdraw(address payable _to) public{
       
        if (balances[_to]>0)
        withdraw_amount=balances[_to]*accumulation/_total;
        income[_to]+=withdraw_amount;
        _to.transfer(withdraw_amount);       
        accumulation -= withdraw_amount;        
        emit Withdraw(_to,withdraw_amount,block.timestamp);
              
    }
    
}