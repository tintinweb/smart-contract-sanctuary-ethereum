/**
 *Submitted for verification at Etherscan.io on 2022-02-01
*/

pragma solidity >=0.7.0 < 0.9.0;

contract RealEstate{

    address payable mainowner;
    address[] investors;
    address renter;
    uint256 amount;
    
    

    uint256 StartDate;
    uint256 EndDate;
    uint256 accumulation;
    uint256 totalsupply;
    uint256 public Token_Price;
    uint256 public Rent_per_Day;
    uint256  StartTime;
    uint256 blocksperday;
    uint256 topay;



 
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

    function tokenPrice_(uint256 _price) public {
        require(msg.sender==mainowner);
        Token_Price=_price;
   }
    
    function rentperday_(uint256 price) public{
        require(msg.sender==mainowner);
        Rent_per_Day=price;
        StartTime=block.number;
    }
    
    function buytokens(address payable beneficiary) payable public {
        require(beneficiary==mainowner);
        beneficiary.transfer(msg.value);
        balances[mainowner] -= msg.value;

    }

    function transfer(address _to, uint256 _tokens) public {
        require(msg.sender==mainowner);
        require(balances[msg.sender]>=_tokens,"Insufficient funds");
        balances[msg.sender] -= _tokens;
        balances[_to] +=_tokens;
        investors.push(_to);
        
    }

    function payrent(uint256 _topay) public payable{
        require(msg.sender==renter);
        topay=((block.number - StartTime)/blocksperday * Rent_per_Day);
        require(topay==_topay);
        accumulation+=_topay;
     
    }   
    function withdraw(uint amount) payable public{
        for (uint256 i=0; i<investors.length; i++){
            if (msg.sender==investors[i]) {
            uint256 _amount = accumulation * balances[msg.sender] / totalsupply;
            amount=_amount;
            (msg.sender).transfer(amount);
            }
        }
      
    }      
    
}