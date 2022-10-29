/**
 *Submitted for verification at Etherscan.io on 2022-10-28
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

interface IERC20Token {
    function transfer(address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function allowance(address, address) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract Lottery {
    uint256 public ticketPrice = 20*1e18; //0.05% supply
    uint256 public maxTickets = 50; // maximum tickets per lottery
    uint256 public duration = 30 minutes; // The duration set for the lottery
    uint256 public constant maxTicketsForWallet = 5; // maximum tickets owned by one wallet
    uint256 public expiration; // Timeout in case That the lottery was not carried out.
    address public lotteryOperator; // the creator of the lottery
    address public lastWinner; // the last winner of the lottery
    uint256 public lastWinnerAmount; // the last winner amount of the lottery
    bool public lotteryOpen = false;
    address internal LotteryToken    = 0x4F7f1740009655f9BD5f4e2Abd370fd898752246; //WEEN

    mapping(address => uint256) public winnings; // maps the winners to there winnings
    mapping(address => uint256) public ticketsOwned; // maps the owners
    address[] public tickets; //array of purchased Tickets

    // modifier to check if caller is the lottery operator
    modifier isOperator() {
        require(
            (msg.sender == lotteryOperator),
            "Caller is not the lottery operator"
        );
        _;
    }

    // modifier to check if caller is a winner
    modifier isWinner() {
        require(IsWinner(), "Caller is not a winner");
        _;
    }

    constructor() {
        lotteryOperator = msg.sender;
        expiration = block.timestamp + duration;
    }

    // return all the tickets
    function getTickets() public view returns (address[] memory) {
        return tickets;
    }

    function getWinningsForAddress(address addr) public view returns (uint256) {
        return winnings[addr];
    }

    function BuyTickets(uint256 amountTickets) public  {
        require(
            LotteryOpen(),
            "Lottery closed."
        );

        require(
            amountTickets <= RemainingTickets(),
            "Not enough tickets available."
        );

        require(
            amountTickets <= maxTicketsForWallet,
            "Max tickets reached."
        );

        require(
            ticketsOwned[msg.sender] <= maxTicketsForWallet,
            "Max tickets for one wallet reached."
        ); 

        _sendLotteryTokenToContract(amountTickets*ticketPrice);
        ticketsOwned[msg.sender]+=amountTickets;
        for (uint256 i = 0; i < amountTickets; i++) {
            tickets.push(msg.sender);
        }
    }

    function DrawWinnerTicket() public isOperator {
        require(tickets.length > 0, "No tickets were purchased");
        uint256 amountWon= IERC20Token(LotteryToken).balanceOf(address(this));

        bytes32 blockHash = blockhash(block.number - tickets.length);
        uint256 randomNumber = uint256(
            keccak256(abi.encodePacked(block.timestamp, blockHash))
        );
        uint256 winningTicket = randomNumber % tickets.length;

        address winner = tickets[winningTicket];
        lastWinner = winner;
        winnings[winner] += (amountWon - amountWon/10);
        lastWinnerAmount = winnings[winner];
 
        delete tickets;
        expiration = block.timestamp + duration;
        
        
        
        _sendLotteryTokenFromContract(payable(winner),amountWon - amountWon/10); 
        _sendLotteryTokenFromContract(payable(lotteryOperator),amountWon/10); 

        
    }

    function restartDraw() public isOperator {
        require(tickets.length == 0, "Cannot Restart Draw as Draw is in play");

        delete tickets;
        expiration = block.timestamp + duration;
    }


    function RefundAll() public {
        require(block.timestamp >= expiration, "the lottery not expired yet");

        for (uint256 i = 0; i < tickets.length; i++) {
            address payable to = payable(tickets[i]);
            tickets[i] = address(0);
            to.transfer(ticketPrice);
        }
        delete tickets;
    }



    function SetLotteryStatus(bool isOpened) public isOperator {
        lotteryOpen= isOpened;
    }

    function SetTicketPrice(uint256 price) public isOperator {
        ticketPrice= price *1e18;
    }

    function SetMaxTickets(uint256 max) public isOperator {
        maxTickets= max * 1e18;
    }

    function SetRoundDuration(uint256 min) public isOperator {
        duration = min;
    }


    function IsWinner() public view returns (bool) {
        return winnings[msg.sender] > 0;
    }

    function CurrentWinningReward() public view returns (uint256) {
        return tickets.length * ticketPrice;
    }

    function RemainingTickets() public view returns (uint256) {
        return maxTickets - tickets.length;
    }

    function LotteryOpen() public view returns (bool) {
        return lotteryOpen;
    }

    function _sendLotteryTokenFromContract(address payable _to, uint _amount) internal isOperator {
        require(IERC20Token(LotteryToken).balanceOf(address(this)) >= _amount,
            "Contract balance too low");
        IERC20Token(LotteryToken).transfer(_to, _amount);
    }

    function _sendLotteryTokenToContract(uint _amount) public{
        require(IERC20Token(LotteryToken).balanceOf(msg.sender) >= _amount,
            "Sender balance too low !");
        IERC20Token(LotteryToken).transferFrom(msg.sender, address(this), _amount);
       
    }
}