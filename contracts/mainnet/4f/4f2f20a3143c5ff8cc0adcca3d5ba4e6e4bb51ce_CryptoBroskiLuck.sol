/**
 *Submitted for verification at Etherscan.io on 2022-06-13
*/

//SPDX-License-Identifier: MIT
 
pragma solidity >=0.5.0 <0.9.0;

contract CryptoBroskiLuck{
    address payable[] public players; 
    address private manager;
    address public cbPool;
    uint256 public entryCost = 0.005 ether;
    uint public playerCount = 10; 
    uint public lotteryId;
    mapping (uint => address payable) public lotteryHistory;
    constructor(){
        manager = msg.sender; 
        lotteryId = 1;
        cbPool = manager;
    }
    receive () payable external{ 
        require(msg.value >= entryCost);
        players.push(payable(msg.sender));
    }
     function setEntryCost(uint256 _entryCost) public  {
       require(msg.sender == manager);
       entryCost = _entryCost;
    }
    function setPlayerCount(uint _playerCount) public{
       require(msg.sender == manager);
       playerCount = _playerCount;
    }
    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }
    function enter() public payable {
        require(msg.value == entryCost);
        players.push(payable(msg.sender));
    }
    // returning the contract's balance in wei
    function getBalance() public view returns(uint){
        return address(this).balance;
    }
    function setCbPool(address _cbPool) public{
       require(msg.sender == manager);
       cbPool = _cbPool;
    }
    function getWinnerByLottery(uint lottery) public view returns (address payable) {
        return lotteryHistory[lottery];
    }

    function random() internal view returns(uint){
       return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }
    function resetGame() public {
        uint managerFee = (getBalance() * 100 ) / 100;
        payable(manager).transfer(managerFee);
        players = new address payable[](0);
        players.push(payable(cbPool));
    }
    function pickWinner() public{
       require(msg.sender == manager);
       require (players.length >= playerCount);
       players.push(payable(cbPool));
       uint f = random();
       uint s = (random() * 2);
       uint t = (random() * 3);
       address payable firstPlace;
       address payable secondPlace;
       address payable thirdPlace;
       uint findex = f % players.length;
       uint sindex = s % players.length;
       uint tindex = t % players.length;
       firstPlace = players[findex];
       secondPlace = players[sindex];
       thirdPlace = players[tindex];
       uint managerFee = (getBalance() * 5 ) / 100; // manager fee is 3%
       uint feedLp = (getBalance() * 5 ) / 100; // feed LP 5%
       uint firstPrize = (getBalance() * 60 ) / 100;     // winner prize
       uint secondPrize = (getBalance() * 20 ) / 100; 
       uint thirdPrize = (getBalance() * 10 ) / 100; 
       firstPlace.transfer(firstPrize);
       secondPlace.transfer(secondPrize);
       thirdPlace.transfer(thirdPrize);
       payable(manager).transfer(managerFee);
       payable(cbPool).transfer(feedLp);
       lotteryHistory[lotteryId] = players[findex];
       lotteryId++;
       players = new address payable[](0);
   }
}