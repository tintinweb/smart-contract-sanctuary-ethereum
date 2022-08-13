/**
 *Submitted for verification at Etherscan.io on 2022-08-13
*/

//SPDX-License-Identifier: MIT 

pragma solidity ^0.8.0;

contract Lottery{

    address public owner;
    address public admin;
    address public addressToRecieveFee;
    address payable[] public players;
    address [] public winners;
    uint256 public percentageFee;
    uint256 public pricePerTicketUSD;
    uint256 public entriesCount;
    uint256 public prizePool;
    uint256 public amountWon;

    constructor(address _owner) {
        owner = _owner;
        admin = _owner;
        addressToRecieveFee = _owner;
        pricePerTicketUSD = 5;
        percentageFee = 2;
        entriesCount = 0;
    }


    function lottery() public {
        owner = msg.sender;
    }

    //to call the enter function we add them to players
    function enter() public payable{
        //each player is compelled to add a certain ETH to join
        require(msg.value > .001 ether);
        players.push(payable(msg.sender));
        entriesCount++;
        prizePool += msg.value;
    }

    function random() private view returns(uint){
        return  uint (keccak256(abi.encode(block.timestamp, players)));
    }

    function pickWinner() public onlyOwner{
        uint index = random() % players.length;
        amountWon = (prizePool * (100 - percentageFee)) / 100;
        payable (players[index]).transfer(amountWon);
        winners.push(players[index]);

        //empties the old lottery
        resetLottery();

    }
    
    function resetLottery() public onlyOwner{
        players = new address payable [](0);
        entriesCount=0;
        amountWon = 0;
        prizePool = 0;
    }

    function setPercentageFee(uint256 _percentageFee) public onlyAdmin {
        percentageFee = _percentageFee;
    }

    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }

    modifier onlyAdmin() {
        require(
            msg.sender == admin || msg.sender == owner,
            "Only an admin level user can call this function"
        );
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

}