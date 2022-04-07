pragma solidity ^0.7.0;

contract TrollFasoMarket {

   address public owner;
   mapping (address => uint) private fasoAmountInGramsByOwner;

   event PastoPurchased(uint amount, address buyerAddress);

   constructor(uint initialAmountInGrams) {
      owner = msg.sender;
      fasoAmountInGramsByOwner[address(this)] = initialAmountInGrams;
   }

   function getAvailableStockToBuyInGrams() public view returns (uint) {
      return fasoAmountInGramsByOwner[address(this)];
   }

   function addToAvailableStock(uint amountInGrams) public {
      require(msg.sender == owner, "Only the owner can add more faso");
      fasoAmountInGramsByOwner[address(this)] += amountInGrams;
   }

   function buy(uint amountInGrams) public payable {
      require(msg.value >= amountInGrams * 0.01 ether, "Payment is not enough for the requested amount of faso. Price is 0.01ETH per gram.");
      require(fasoAmountInGramsByOwner[address(this)] >= amountInGrams, "Not enough faso in stock :(");
      fasoAmountInGramsByOwner[address(this)] -= amountInGrams;
      fasoAmountInGramsByOwner[msg.sender] += amountInGrams;
      emit PastoPurchased(amountInGrams, msg.sender);
   }
}