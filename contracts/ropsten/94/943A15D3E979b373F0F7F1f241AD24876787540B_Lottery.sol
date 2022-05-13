/**
 *Submitted for verification at Etherscan.io on 2022-05-13
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Lottery {

    // Var
    address public owner;
    address payable[] public players;
    uint amountTicket = 0.1 ether;
    uint public totalAmoutContract;
    uint public totalAmoutWinner;
    uint public lotteryCounter = 1;
    mapping(uint => address payable) public Lotterys;
    mapping(uint => uint) public LotterysAmount;

    enum StateLottery {
        Start, End
    }
    StateLottery public stateLottery; 

    // Modifier
    modifier onlyOwner() {
        require(owner == msg.sender, "Only owner !");
        _;
    }

    // Event
    event winnerEvent(address addressWinner, uint amountWinner);

    // Function
    constructor() {
        owner = payable(msg.sender);
        stateLottery = StateLottery.Start;
    }

    function startLottery() public {
        stateLottery = StateLottery.Start;
    }

    function getWinner(uint _lotteryCounter) public view returns(address payable) {
        return Lotterys[_lotteryCounter];
    }
    function getWinnerAmount(uint _lotteryCounter) public view returns(uint) {
        return LotterysAmount[_lotteryCounter];
    }

    function getPlayers() public view returns(address payable[] memory) {
        return players;
    }

    function buyTicket() public payable {
        require(msg.value == amountTicket, "Price ticket is invalid !");
        require(stateLottery == StateLottery.Start, "State lottery is invalid !");
        
        players.push(payable(msg.sender));
    }
    
    function randomNumber() private view returns(uint) {
        return uint(keccak256(abi.encodePacked(owner, block.timestamp)));
    }

    function winner() public onlyOwner {
        require(stateLottery == StateLottery.Start, "State lottery is invalid !");
        uint index = randomNumber() % players.length;
        
        totalAmoutWinner = ((address(this).balance)*90)/100;
        totalAmoutContract = ((address(this).balance)*10)/100;
        players[index].transfer(totalAmoutWinner);
        payable(owner).transfer(totalAmoutContract);

        //emit winnerEvent(players[index], totalAmoutWinner);

        Lotterys[lotteryCounter] = players[index];
        LotterysAmount[lotteryCounter] = totalAmoutWinner;
        lotteryCounter++;

        totalAmoutContract = 0;
        totalAmoutWinner = 0;
        players = new address payable[](0);

        stateLottery = StateLottery.End;
    }

}