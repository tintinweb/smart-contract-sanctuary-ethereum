// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
// errors
error Lottery__WinnerNotPicked();

contract Lottery{
    address public owner;
    address payable[] public s_players;
    uint256 private  immutable i_entredFee = 0.01 ether;
    uint256 public lotteryId;
    mapping(uint256=> address payable) public lotteryHistory;

    /*Modifier*/
    modifier onlyOwner(){
        require(msg.sender == owner, "Only owner can call");
        _;
    }

    constructor() {
        owner = msg.sender;
        lotteryId = 1;
    }

    /*view/pure functions  */
    function getWinnerByLottery(uint256 _lotteryId) public view returns(address payable) {
        return lotteryHistory[_lotteryId];
    }
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
    function getPlayers() public view  returns(address payable[] memory){
        return  s_players;
    }
    function enter() public  payable {
        require(msg.value > i_entredFee, "The Min amount is 0.01 ether");
        s_players.push(payable(msg.sender));
    }
    function random() public  view returns(uint){
        return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp, s_players )));
    } 
    function pickedWinner() public payable onlyOwner{
        uint winnerIndex = random() % s_players.length;
        address payable  winner= s_players[winnerIndex];
        (bool success, ) = winner.call{value: address(this).balance}("");
        if (!success) {
            revert Lottery__WinnerNotPicked();
        }
        lotteryId++;
        lotteryHistory[lotteryId] = s_players[winnerIndex];

        // reset the state of the contract
        s_players = new address payable[](0);
    }
}