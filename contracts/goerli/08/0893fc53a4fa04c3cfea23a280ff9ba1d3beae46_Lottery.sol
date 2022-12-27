//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
contract Lottery {
    address public owner;
    address payable[] public players;
    bool public lotteryInProgress;
    uint public lotteryId;
    mapping (uint => address payable) public lotteryHistory;
    constructor() {
        owner = msg.sender;
        lotteryId = 1;
    }
    function startLottery() public onlyowner{
        lotteryInProgress=true;
    }
    function alreadyEntered() private view returns(bool){
        for(uint i=0; i< players.length; i++){
            if(players[i]==msg.sender)
            return true;
        }
        return false;
    } 
    function enterLottery() public payable {
        require(lotteryInProgress,"No lottery event is currently in progress");
        require(msg.value > 0.5 ether, "Please deposit at least 0.5 Ether");
        require(msg.sender!=owner, "As owner, you can't enter the lottery");
        require(alreadyEntered()==false, "You have already entered in the Lottery");
        require(players.length<=10, "This lottery has maximum participation. Please wait for the next event");
        players.push(payable(msg.sender));
    }
    function getRandomNumber() private view returns (uint) {
        return uint(keccak256(abi.encodePacked( block.timestamp, block.difficulty, block.gaslimit)));
    }
    function pickWinner() public onlyowner {
        require(lotteryInProgress,"No lottery event is currently in progress");
        require(players.length>0, "can't pick winners without participants");
        uint index = getRandomNumber()%players.length;
        players[index].transfer(address(this).balance - 0.1 ether);
        lotteryHistory[lotteryId] = players[index];
        lotteryId++;       
        lotteryInProgress=false;
        players = new address payable[](0);
    }
    modifier onlyowner() {
      require(msg.sender == owner, "Only owner can call this function");
      _;
    }
    function getWinnerByLottery(uint lottery) public view returns (address payable) {
        return lotteryHistory[lottery];
    }
    function getBalance() public view returns (uint) {
        return address(this).balance/(10**18);
    }
    function numOfPlayers() public view returns (uint) {
        return players.length;
    }
    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }
}