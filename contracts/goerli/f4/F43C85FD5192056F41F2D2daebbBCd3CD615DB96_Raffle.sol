//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Raffle {
    /* main features ti respect in this contract : 
        1- users who wanna participate must pay an entrancy price = 5$ BUSD
        2- after reaching 21 players we should pick a random winner from the 21 players
        3- the process of re-launching the game should be automated
        4- the winner must pay a fee of 25% in order to be able to withdraw his funds gained in the lottery
        5- we gonna use 3 main functions :
            - function enterRaffle() {} : anyone who pays the entry 5$ BUSD
            - function pickWinner() {} : automatically pick the winner after reaching 21 players 
            - function withdrawFunds() {} : the winner can withdraw funds if he pays 25% in fees to the smart contract
    */

    // State varibale that we can change and they are stored with the smart contract on the blockchain
    uint256 public entryPrice = 0.003 ether;
    address payable[] private players;

    // a mapping to track each user entry
    mapping(address => uint256) public playerToNumberOfEntry;

    // game varibales
    address public winnerAddress;

    //setting the random number variable
    uint256 private randomNumber;

    //setting the amount to transfer to the winner
    uint256 public fundsGained;

    // function that generate a random number using the blocktimestamp
    function setRandomNumber() private returns (uint256) {
        uint256 _randomNumber = uint256(
            keccak256(
                abi.encodePacked(msg.sender, block.timestamp, randomNumber)
            )
        );
        randomNumber = _randomNumber;
        return _randomNumber;
    }

    // function that calculate the number of how much an address occurs in an array
    function addressNumberOccured(
        address _address
    ) public view returns (uint256) {
        uint256 counter = 0;
        for (uint256 i = 0; i < players.length; i++) {
            if (_address == players[i]) {
                counter = counter + 1;
            }
        }
        return counter;
    }

    // main functions of the raffle game
    function enterGame() public payable {
        require(msg.value == entryPrice, "Entry price is not correct!");
        players.push(payable(msg.sender));
        uint256 _counter = addressNumberOccured(msg.sender);
        playerToNumberOfEntry[msg.sender] = _counter;
    }

    function pickWinner() public returns (address) {
        require(players.length > 4, "Number of players is still too low!");
        require(address(this).balance > 0, "Not enough balance!");
        uint256 RANDOM_NUMBER = setRandomNumber();
        uint256 winnerIndex = RANDOM_NUMBER % players.length;
        winnerAddress = players[winnerIndex];
        return players[winnerIndex];
    }

    function withdrawFunds() public {
        require(msg.sender == winnerAddress, "You are not the winner!");
        uint256 amountToTransfer = (address(this).balance * 3) / 4;
        payable(msg.sender).transfer(amountToTransfer);
        players = new address payable[](0);
        fundsGained = amountToTransfer;
    }

    // functions to view or get data
    function getNumberOfPlayers() public view returns (uint256) {
        return players.length;
    }

    function getWinner() public view returns (address) {
        return winnerAddress;
    }
}