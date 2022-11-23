/**
 *Submitted for verification at Etherscan.io on 2022-11-23
*/

// SPDX-License-Identifier: GPL-3.0

/*

Kasih keterangan website dan cara main

*/


pragma solidity >=0.7.0 <0.9.0;

contract Decentralized_Competition {
    uint256 public constant ticketPrice = 0.01 ether;
	uint256 public constant minRewards = 0.1 ether; // competition reward below this number, every participant will get full refund
    uint256 public constant duration = 3 days; // competition duration

    uint256 public expiration; // timeout in case That the competition was not carried out.
    address payable public CompetitionOwner; // the creator
    address public theWinner; // the winner of the competition

    address payable public PoolPlatformFee =
        payable(address(0x7FF9aE5F8ab0af2b6Bee60be9a4EB5f48604323D));


    mapping(address => uint256) winnings; // maps the winners
    address[] public tickets; //array of purchased tickets

    mapping (address => Property) public participant;

    struct Property {
        uint256 total_ticket; 
        uint256 total_paid;
        bool withdraw_refund;
        bool participant_list;     		
    }
	
    // modifier to check if caller is the competition owner or deployer
    modifier isOwner() {
        require(
            (msg.sender == CompetitionOwner),
            "caller is not the competition owner"
        );
        _;
    }

    // modifier to check if caller is a winner
    modifier isWinner() {
        require(IsWinner(), "caller is not a winner");
        _;
    }

    constructor() {
        CompetitionOwner = payable (msg.sender);
        expiration = block.timestamp + duration;
    }

    // return all the tickets
    function getTickets() public view returns (address[] memory) {
        return tickets;
    }

    function BuyTickets() public payable {
        require(msg.value >= ticketPrice, "not enough coin available.");
        require(block.timestamp <= expiration,"competition is expired.");
        require(msg.sender!= CompetitionOwner , "competition owner cannot buy tickets");

        uint256 paid = msg.value;
        address beneficiary = msg.sender;
		
        uint256 num = msg.value / ticketPrice;
        uint256 numOfTickets;

			if( num == 1) {  
				 numOfTickets = 1;
			  } else if ( num == 3 ) {
				 numOfTickets = 6;
			  } else if ( num == 6 ) {
				 numOfTickets = 20;      
			  } else if ( num == 10 ) {
				 numOfTickets = 40;
			  } else if ( num == 15 ) {
				 numOfTickets = 65;
			  } 

        for (uint256 i = 0; i < numOfTickets; i++) {
            tickets.push(msg.sender);			
        }
                
        participant[beneficiary].total_ticket += numOfTickets;
        participant[beneficiary].total_paid += paid;
		participant[beneficiary].withdraw_refund = false;
		participant[beneficiary].participant_list = true;
    }

    function DrawWinner() public {
        address check = msg.sender;
        require(tickets.length > 0, "No tickets were purchased");
        require(block.timestamp >= expiration, "competition is ongoing");
        require(address(this).balance > minRewards, "competition reward below minimum requirement");
        require(participant[check].participant_list == true, "you are not participant in this competition");

        bytes32 blockHash = blockhash(block.number - tickets.length);
        uint256 randomNumber = uint256(
            keccak256(abi.encodePacked(block.timestamp, blockHash))
        );
        uint256 winningTicket = randomNumber % tickets.length;

        address winner = tickets[winningTicket];

        theWinner = winner;

		winnings[winner] = address(this).balance * 975 / 1000;
        
		uint256 OwnerFee = address(this).balance * 20 / 1000; // 2% competition owner fee
		uint256 PlatformFee = address(this).balance * 5 / 1000; // 0.5% platform fee
		
        address payable winner_ = payable(winner);

        winner_.transfer(winnings[winner]); // transfer to winner
        CompetitionOwner.transfer(OwnerFee); // transfer to competition owner	
        PoolPlatformFee.transfer(PlatformFee); // transfer to platform owner
        
        delete tickets;
    } 

    function Refund() public {
		address payable refunder = payable(msg.sender);
        require(block.timestamp >= expiration, "competition is ongoing");
        require(address(this).balance < minRewards, "competition above minimum reward");
        require(participant[refunder].withdraw_refund == false, "you have withdrawed refund");
        require(participant[refunder].participant_list == true, "you are not participant in this competition");
		
		refunder.transfer(participant[refunder].total_paid);
		participant[refunder].withdraw_refund = true;
    }

    function IsWinner() public view returns (bool) {
        return winnings[msg.sender] > 0;
    }

    function FundRaised() public view returns (uint256) {
        return address(this).balance;
    }

    function WinnerReward() public view returns (uint256) {
        return address(this).balance * 975 / 1000;
    }
}