pragma solidity ^0.7.0;

contract FasoTroll {

   address public owner;
   mapping (address => uint) public fasoTrollInGrams;

   constructor() {
      owner = msg.sender;
      fasoTrollInGrams[address(this)] = 100000;
   }

   function getBalanceOfFaso() public view returns (uint) {
      return fasoTrollInGrams[address(this)];
   }

   function addFaso(uint grams) public {
      require(msg.sender == owner, "Only the owner can add more faso");
      fasoTrollInGrams[address(this)] += grams;
   }

   function buyFaso(uint grams) public payable {
      require(msg.value >= grams * 0.1 ether, "Faso price is 0.1 ETH per gram");
      require(fasoTrollInGrams[address(this)] >= grams, "Not enough faso in stock :(");
      fasoTrollInGrams[address(this)] -= grams;
      fasoTrollInGrams[msg.sender] += grams;
   }
}