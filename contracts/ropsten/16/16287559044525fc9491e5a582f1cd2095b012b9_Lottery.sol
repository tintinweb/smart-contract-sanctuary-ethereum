/**
 *Submitted for verification at Etherscan.io on 2022-05-19
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;


contract Lottery {

    // var
    address public owner;
    address payable[] public players; // 0x0001 0x00002 0x00003
    address public test;
    uint amountTicket = 100000000000000000;  // wei
    uint public totalAmountContract;
    uint public totalAmountwinner;
    uint public lotteryCounter = 1;

    mapping(uint => address) public Lotterys;
    mapping(uint => uint) public LotteryAmount;

    enum StateLottery {
        Start, End
    }
    StateLottery public stateLottery;

    // modifier
    modifier onlyOwner() {
        require(owner == msg.sender, "You are not owner !");
        _;
    }

        

    // event
    //event winnerEvent(address addressWinner, uint amountWinner);

    // function
    constructor() {
        owner = payable(msg.sender);
        stateLottery = StateLottery.Start;
    }

    function startLottery() public {
        stateLottery = StateLottery.Start;
    }

    function getWinner(uint _lotteryCounter) public view returns(address) {
        return Lotterys[_lotteryCounter];
    }

    function getWinnerAmount(uint _lotteryCounter) public view returns(uint) {
        return LotteryAmount[_lotteryCounter];
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

        totalAmountContract = ((address(this).balance)*10)/100;
        totalAmountwinner = ((address(this).balance)*90)/100;

        payable(owner).transfer(totalAmountContract);
        players[index].transfer(totalAmountwinner);

        Lotterys[lotteryCounter] = players[index];
        LotteryAmount[lotteryCounter] = totalAmountwinner;
        lotteryCounter++;

        totalAmountContract = 0;
        totalAmountwinner = 0;
        players = new address payable[](0);

        stateLottery = StateLottery.End;
    }


}