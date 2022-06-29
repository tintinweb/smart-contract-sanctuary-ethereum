//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract Lottery {
    event TicketPurchased(address who);
    event WinnerPicked(address who, uint256 reward);
    
    uint256 private immutable i_ticketPrice;
    uint256 private immutable i_endTime;
    
    address[] players;
    
    constructor() {
        i_ticketPrice = 1e18; //1000000000000000000 = 1 ETH
        i_endTime = block.number + 180;
    }

    function buyTicket() external payable {
        require(block.timestamp <= i_endTime, "Lottery has ended");
        require(msg.value == i_ticketPrice, "Wrong purchase");
        
        players.push(msg.sender); 

        emit TicketPurchased(msg.sender);
    }

    function pickWinner() external {
        require(block.timestamp > i_endTime);

        uint256 winnerIndex =  uint256(keccak256(abi.encodePacked(block.timestamp, players.length, block.number))) % players.length;
        address payable winner = payable(players[winnerIndex]);
        uint256 reward = address(this).balance;

        (bool sucess, ) = winner.call{value: reward}("");

        require(sucess, "Reward transfer failed");

        emit WinnerPicked(winner, reward);
    
    }

    function getTicketPrice() external view returns(uint256) {
        return i_ticketPrice;
    }

    function getEndTime() external view returns(uint256) {
        return i_endTime;
    }

    function getPlayers() external view returns(address[] memory) {
        return players;
    }

}