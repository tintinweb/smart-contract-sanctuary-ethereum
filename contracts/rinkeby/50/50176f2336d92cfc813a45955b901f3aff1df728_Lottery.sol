/**
 *Submitted for verification at Etherscan.io on 2022-02-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;


interface IPrices {
    function latestAnswer() external view returns(int256);
}

/**
 * @title Lottery
 * @dev Play some Lottery
 */
contract Lottery {
    address public owner;
    address payable[] public currentPlayers;
    uint public lotteryId;
    uint public numPlayers = 11;

    address[3] private contractPricesAddress = [0xc751E86208F0F8aF2d5CD0e29716cA7AD98B5eF5, 0xECe365B379E1dD183B20fc5f022230C044d51404, 0xE96C4407597CD507002dF88ff6E0008AB41266Ee];


    // set the lottery cost and fees
    uint256 private lotteryPrice = 0.01 ether;
    uint ownerPercentage = 10;

    // List of Winners
    mapping (uint => address payable) public lotteryHistory;

    // Random Number on ChainLink
    bytes32 internal keyHash;
    uint256 internal fee;
    
    uint256 public randomResult;

   
    constructor() 
    {
     
        owner = msg.sender;
        lotteryId = 1;
    }

    function getCoinPrice(address contract_addr) public view onlyOwner returns (int256) {
        return IPrices(contract_addr).latestAnswer();
    }

    function aggregatePrices() private view onlyOwner returns(bytes memory) {
        bytes memory encoded;
        for(uint i=0; i < contractPricesAddress.length; i++)
        {
            encoded = bytes.concat(encoded, abi.encodePacked(getCoinPrice(contractPricesAddress[i])));
        }
        return encoded;
    }
    
     modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function enterGame() public payable {
        require(msg.value == lotteryPrice, "Please check the cost of lottery and send the correct ammount.");

        // Add the player to lottery and cast to be a payable address
        currentPlayers.push(payable(msg.sender));

        if (currentPlayers.length == numPlayers){
            pickWinner();
        }

    }

    function playgame() public payable {
        enterGame();
    }

    /**
    Generates a Random number using, block difficulty, timestamp, and the price of 3 different cryptocoins as seed.
     */
    function generateRandomNumber() private view returns(uint) {
        bytes memory aggregatedPrices = aggregatePrices();
        return uint(keccak256(abi.encodePacked(owner, block.difficulty, block.timestamp, aggregatedPrices)));
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function getPlayers() public view returns(address payable[] memory) {
        return currentPlayers;
    }

    function pickWinner() public payable onlyOwner {
        //make sure that we have enought players
        require(currentPlayers.length > 5, "Not enough players in the lottery");
        randomResult = generateRandomNumber();

        uint index = randomResult % currentPlayers.length;
        address payable winner = currentPlayers[index];

        // Make Payments
        winner.transfer(getBalance()*(100-ownerPercentage)/100);
        payable(owner).transfer(getBalance()*ownerPercentage/100);
 
        // Save Lottery info
        lotteryHistory[lotteryId] = winner;
        resetContract();

    }

    function setOwnerPercentage(uint newPercentage) public onlyOwner {
        ownerPercentage = newPercentage;
    }

    function resetContract() public onlyOwner {
        currentPlayers = new address payable[](0);
        lotteryId++;
    }
  

    function getLotteryPrice() public view returns(uint256) {
        return lotteryPrice;
    }

    function setLotteryPrice(uint256 newValue) external onlyOwner {
        lotteryPrice = newValue;
    }

    function setNumPlayers(uint newNumPlayers) external onlyOwner {
        numPlayers = newNumPlayers;
    }
    function withDraw(uint256 value) external onlyOwner {
        payable(owner).transfer(value);
    }

    function withDrawAll() external onlyOwner {
        payable(owner).transfer(getBalance());
    }
}