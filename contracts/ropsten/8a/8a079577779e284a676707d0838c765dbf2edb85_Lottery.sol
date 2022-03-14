// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./ERC20.sol";

contract Lottery is ERC20 {
    uint256 public ticketPrice;  
    address private admin;
    address[] public players;
    uint public startTime;
    uint public limitTimeDay; // in days;
    uint public limitTime;     // in sec;
    uint256 public soldTicketLimit;
    uint256 public ticketSold;  // in units;
    bool public onGame = false; 
    uint256 public episod = 0;

    constructor() ERC20("Be$tLuck", "B$L") {
        admin = msg.sender;
    }

    event Sell(address _buyer, uint256 _ticketCount);

    event WeHaveAWinner(address _winner);

    mapping(address => uint256) public winners;

    function startGame(uint256 _numberOfTickets, uint256 _ticketPrice, uint _limitTimeDay, uint256 _soldTicketLimit) public {
        require(!onGame);
        require(msg.sender == admin);
        episod++;
        ticketPrice = _ticketPrice;
        limitTimeDay = _limitTimeDay;
        totalSupply = _numberOfTickets;
        soldTicketLimit = _soldTicketLimit;
        balanceOf[address(this)] = _numberOfTickets;
        onGame = true;
        startTime = block.timestamp;
        limitTime = startTime + limitTimeDay * 1 days;
    }

    function multiply(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function buyTicket(uint256 _numberOfTickets) public payable {
        require(onGame, "There is no actual lottery now.");
        require(msg.value == multiply(_numberOfTickets, ticketPrice), "Not enaught or too much ethers");      
        require(transfer(msg.sender, _numberOfTickets), "transfer failed");
        ticketSold += _numberOfTickets;
        for (uint i = 0; i < _numberOfTickets; i++) {
            players.push(msg.sender);
        }
        emit Sell(msg.sender, _numberOfTickets);
    }

    function letsPlayTheGame() public {
        uint nowTime = block.timestamp;
        require((ticketSold == totalSupply) || ((ticketSold >= soldTicketLimit) && (nowTime >= limitTime)));      
        address winner = players[random(players.length)]; 
        emit WeHaveAWinner(winner);
        winners[winner] = episod;
        onGame =false;
        burnOldTickets();
        payable(admin).transfer(address(this).balance);
    }

    function stopTheGame() public payable {
        uint nowTime = block.timestamp;
        require((nowTime > limitTime) && (ticketSold < soldTicketLimit));
        for (uint i = 0; i < players.length; i++) {
            payable(players[i]).transfer(ticketPrice);
            // players[i].call.value(ticketPrice).gas("20317");
        }
        onGame =false;
    }

    function random(uint256 _playersCount) private view returns (uint256) {
        // uint256 sender = uint256(uint160(address(_sender)));
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)))%(_playersCount-1);
    }

    function burnOldTickets() private {
        balanceOf[msg.sender] = 0;
        totalSupply = 0;
    }
}