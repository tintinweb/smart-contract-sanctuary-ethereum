// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract Lottery {
    
    uint256 public constant ticketPrice = 1 ether;
    uint256 public constant maxTickets = 100;               // maximum tickets per lottery
    uint256 public constant ticketCommission = 0.1 ether;   // commition per ticket 
    uint256 public constant duration = 30 minutes;          // The duration set for the lottery 
    
    uint256 public expiration;                              // Timeout in case That the lottery was not carried out.
    address public lotteryOperator;                         // the crator of the lottery
    uint256 public operatorTotlaCommission = 0;             // the total commission balance
    
    mapping (address => uint256) winnings;          // maps the winners to there winnings
    address[] public tickets;                              //array of purchased Tickets
    
    
    // modifier to check if caller is the lottery operator
    modifier isOperator() {
        require( (msg.sender == lotteryOperator) , "Caller is not the lottery operator");
        _;
    }
    
    // modifier to check if caller is a winner
    modifier isWinner() {
        require(IsWinner(), "Caller is not a winner");
        _;
    }
    
    constructor()
    {
        lotteryOperator = msg.sender;
        expiration = block.timestamp + duration;
    }
    
    function BuyTickets() public payable
    {
        require(msg.value % ticketPrice == 0, "the value must be multiple of 1 Ether");
        uint256 numOfTicketsToBuy = msg.value / ticketPrice;
        
        require(numOfTicketsToBuy <= RemainingTickets(), "Not enough tickets available.");
        
        for (uint i = 0; i < numOfTicketsToBuy; i++)
        {
            tickets.push(msg.sender);
        }
    }
    
    function DrawWinnerTicket() public isOperator
    {
        require(tickets.length > 0, "No tickets were purchased");
        
        bytes32 blockHash = blockhash(block.number - tickets.length);
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, blockHash)));
        uint256 winingTicket =  randomNumber % tickets.length;
        
        address winner = tickets[winingTicket];
        winnings[winner] += ( tickets.length * (ticketPrice - ticketCommission) );
        operatorTotlaCommission += ( tickets.length * ticketCommission );
        delete tickets;
        expiration = block.timestamp + duration;
    }
    
    function WithdrawWinnings() public isWinner
    {
        address payable winner = payable(msg.sender);
        uint256 reward2Transfer = winnings[winner];
        winnings[winner] = 0;
        
        winner.transfer(reward2Transfer);
    }
    
    function RefundAll() public
    {
        require(block.timestamp >= expiration, "the lottery not expired yet");
        
        for (uint i = 0; i < tickets.length; i++)
        {
            address payable to = payable(tickets[i]);
            tickets[i] = address(0);
            to.transfer(ticketPrice);
        }
        delete tickets;
    }
    
    function WithdrowCommission() public isOperator
    {
        address payable operator = payable(msg.sender);
        
        uint256 commission2Transfer = operatorTotlaCommission;
         operatorTotlaCommission = 0;
        
        operator.transfer(commission2Transfer);
    }
    
    function IsWinner() public view returns(bool)
    {
        return winnings[msg.sender] > 0;
    }
    
    function CurrentWinningReward() public view returns(uint256)
    {
        return tickets.length * ticketPrice;
    }
    
    function RemainingTickets() public view returns(uint256)
    {
        return maxTickets - tickets.length;
    }    
}