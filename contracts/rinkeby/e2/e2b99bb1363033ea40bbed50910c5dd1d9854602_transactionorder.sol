/**
 *Submitted for verification at Etherscan.io on 2022-07-11
*/

/**
 *Submitted for verification at Etherscan.io on 2021-01-27
*/

/**
 *Submitted for verification at Etherscan.io on 2021-01-27
*/

pragma solidity 0.5.10 ;
 
 contract transactionorder{
     
    uint256 public purchaseQuantity;
    uint256 public Price;
    address public Owner;
   
    event BuyEv(address buyer, uint256 _Price, uint256 _quantity);
    event PriceChangeEv(address _owner, uint256 _Price);
    
 modifier onlyOwner(){
    require(msg.sender == Owner);
    _;
    
    }

    constructor()public{
        Owner = msg.sender;
        Price = 5;
    }
    
    function Buy()payable public returns(uint256){
        purchaseQuantity = msg.value/Price;
        emit BuyEv(msg.sender,Price, purchaseQuantity);
        return Price;
    }
    
    function Setprice(uint256 newPrice) public onlyOwner{
         Price = newPrice;
         emit PriceChangeEv(Owner, Price);
        }
}