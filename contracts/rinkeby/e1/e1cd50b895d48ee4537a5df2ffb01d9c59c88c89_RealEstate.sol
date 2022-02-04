/**
 *Submitted for verification at Etherscan.io on 2022-02-04
*/

pragma solidity >=0.8.0 < 0.9.0;


contract RealEstate{

    
    address payable mainowner=payable(msg.sender);
    address [] investors;
    address payable user;

    
    
    uint256 amount;
    uint256 public Tokens_offered;
    uint256 income;
      
    uint256 public accumulation;
    uint256 public Token_Price;
    uint256 public Rent_per_Day;
    uint256  public StartTime;
    uint256 public EndTime;
    uint256 public quantity;
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
        decimals = 0;
        investors.push(msg.sender);
        
    }


    function offertokens(uint _amount, uint _price) public{
        Token_Price=_price;
        Tokens_offered=_amount;
    }
    
    function buytokens(uint256 tokens) payable public {
        balances[msg.sender]+=tokens;
        balances[mainowner] -= tokens;
        mainowner.transfer(msg.value);
        investors.push(msg.sender);
    }

    function rentperday_(uint price) public{
        require(msg.sender==mainowner);
        Rent_per_Day=price;
        StartTime=block.timestamp;
    }
    function getTime () public view returns(uint256 time){
        return block.timestamp;
    }

   
    function _topay() public view returns(uint256 time){
        return (block.timestamp - StartTime)/60/60/24;
    }

    function payrent() public payable{
        accumulation += msg.value;
    
    }
    function withdraw() public payable{
        if (balances[msg.sender]>0)
        income=balances[msg.sender]*accumulation/100;
        user=payable(msg.sender);
        user.transfer(income);
        accumulation -= income;
       
        
    }
    
    function getinvestors() public view returns (address[] memory){
        return investors;

    }


}