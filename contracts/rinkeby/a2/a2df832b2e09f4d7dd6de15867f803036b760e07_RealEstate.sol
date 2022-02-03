/**
 *Submitted for verification at Etherscan.io on 2022-02-03
*/

pragma solidity >=0.7.0 < 0.9.0;

contract RealEstate{

    address[] investors;
    address renter;
    address payable mainowner=payable(0xcd6D93C666B21073345ACcdAeEf29461ec745DAF);
    
    uint256 amount;
    uint8 decimals;

    
    

    uint256 StartDate;
    uint256 EndDate;
    uint256 accumulation;
    uint256 totalsupply;
    uint256 public Token_Price;
    uint256 public Rent_per_Day;
    uint256  StartTime;
    uint256 blocksperday;
    uint public topay;



 
    string public apartment_name;
    string public apartment_symbol;

    mapping(address=>uint256) public balances;
   
    
    constructor(string memory _propertyID, string memory _propertysymbol) {
        balances[mainowner]=100;
        totalsupply=100;
        apartment_name=_propertyID;
        apartment_symbol=_propertysymbol;
        investors.push(mainowner);
        accumulation=0;
        blocksperday = 60*60*24/15;
    }

    function tokenPrice_(uint _price) public {
        Token_Price=_price;
   }
    
    
    function buytokens() payable public {
        
        mainowner.transfer(msg.value);
        balances[mainowner] -= msg.value*Token_Price;
        balances[msg.sender]+=msg.value*Token_Price;
        investors.push(msg.sender);

    }

    function rentperday_(uint price) public{
        require(msg.sender==mainowner);
        Rent_per_Day=price;
        StartTime=block.number;
    }


    function payrent() public payable{
        require(msg.sender==renter);
        topay=((block.number - StartTime)/blocksperday * Rent_per_Day);
        require(msg.value==topay,"insufficient funds");
        accumulation += topay;
     
    }   

}