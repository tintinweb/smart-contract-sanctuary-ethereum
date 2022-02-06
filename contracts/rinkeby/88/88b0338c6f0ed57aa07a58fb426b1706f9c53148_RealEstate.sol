/**
 *Submitted for verification at Etherscan.io on 2022-02-05
*/

pragma solidity >=0.8.0 < 0.9.0;


contract RealEstate{

    
    address payable mainowner=payable(msg.sender);
    address [] investors;
    address payable user;

   
    uint256 _total;
    uint256 amount;
    uint256 public Tokens_offered;
    uint256 public income;
      
    uint256 public accumulation;
    uint256 public Token_Price;
    uint256 public Rent_per_Day;
    uint256  public StartTime;
    uint256 public EndTime;
    uint256 blocksperday;
    uint public decimals;
    
    string public constant name = "Matteo";
    string public constant symbol = "LRNZ";
    



 
    string public apartment_name;
    string public apartment_symbol;

    mapping(address=>uint256) public balances;
    

    
   constructor(string memory _propertyID, string memory _propertysymbol, uint256 total) {
        balances[msg.sender]=total;
        apartment_name=_propertyID;
        apartment_symbol=_propertysymbol;
        accumulation=0;
        decimals = 18;
        investors.push(msg.sender);
        _total=total;
        
    }


    function offerprice (uint256 _price) public{
        Token_Price=_price;
        
    }
    
    function buytokens() public payable{                 // You have to set the price in WEI
        amount=Token_Price*msg.value;
        balances[msg.sender]+=msg.value;
        balances[mainowner] -= msg.value;
        mainowner.transfer(amount);
            
        investors.push(msg.sender);        
    }

    function rentperday_(uint256 price) public{
        require(msg.sender==mainowner);
        Rent_per_Day=price;
        StartTime=block.timestamp;
    }
    
    function getTime () public view returns(uint256 time){
        return block.timestamp;
    }

   
    function _topay() public view returns(uint256 time){
        return (block.timestamp - StartTime)/60/60/24*Rent_per_Day;
    }

    function payrent() public payable{
        accumulation += msg.value;
    
    }
    function withdraw() public payable{
        if (balances[msg.sender]>0)
        income=balances[msg.sender]*accumulation/_total;
        user=payable(msg.sender);
        user.transfer(income);
        accumulation -= income;
       
        
    }
    
    function getinvestors() public view returns (address[] memory){
        return investors;

    }


}