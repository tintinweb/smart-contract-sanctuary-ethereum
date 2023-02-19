/**
 *Submitted for verification at Etherscan.io on 2023-02-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Bet {
    event Deposit(address indexed sender, uint256 amount, uint256 balance);
    event BetPaid(address winner, uint256 total_pot);

    address public bettor;
    uint256 public bettor_val;
    string public betDetails;
    address public taker;
    uint256 public taker_val;
    uint256 public days_til_end;
    address[] public players;
    address[] public approval;
    uint256 public endDate;
    uint256 public total_pot;
    uint256 public atStake;
    

    mapping(address => uint256) public isPlayer;
    mapping(address => bool) public isOwner;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }
//units are in Wei

    receive() external payable onlyOwner {
        
        require ((msg.value == bettor_val) || (msg.value == taker_val), "check bet amount");
        isPlayer[msg.sender] = msg.value;
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    constructor(
        address _bettor,
        uint256 _bettor_val,
        string memory _betDetails,
        address _taker,
        uint256 _taker_val,
        uint256 _days_til_end     
    ) payable {
        bettor = _bettor;
        bettor_val = _bettor_val;
        betDetails = _betDetails;
        taker = _taker;
        taker_val = _taker_val;
        days_til_end = _days_til_end;
        players.push(bettor);
        players.push(taker);
        isOwner[bettor] = true;
        isOwner[taker] = true;
        endDate = block.timestamp + (60*60*24 * days_til_end);
        atStake = bettor_val + taker_val;
    }

    // the loser or arbitor must approve FIRST!!!  winner should verify approval is filled.  the second approver gets the money

    function payUp(address _outcome) public onlyOwner {
        total_pot = isPlayer[bettor] + isPlayer[taker];

        if (
            (_outcome == bettor) &&
            (approval.length == 1) &&
            (approval[0] != _outcome)
        ) {
            (bool sent, ) = bettor.call{value: total_pot}("");
            require(sent, "Failed to send Ether");
            emit BetPaid(_outcome, total_pot);
        } else if (
            (_outcome == taker) &&
            (approval.length == 1) &&
            (approval[0] != _outcome)
        ) {
            (bool sent, ) = taker.call{value: total_pot}("");
            require(sent, "Failed to send Ether");
            emit BetPaid(_outcome, total_pot);
        } else {
            approval.push(_outcome);
        }
    }

    // anyone can revert the bets after the time is up

    function revertBets() public {
        if (block.timestamp > endDate) {
            (bool bettor_sent, ) = bettor.call{value: isPlayer[bettor]}("");
            require(bettor_sent, "Failed to send Ether");
            (bool taker_sent, ) = taker.call{value: isPlayer[taker]}("");
            require(taker_sent, "Failed to send Ether");
        }
    }
}

contract BetFactory {
    Bet[] public bets_array;

    function createBet(
        address _bettor,
        uint256 _bettor_val,
        string memory _betDetails,
        address _taker,
        uint256 _taker_val,
        uint256 _days_til_end      
    ) public payable {
        Bet bet = (new Bet)(
            _bettor,
            _bettor_val,
            _betDetails,
            _taker,
            _taker_val,
            _days_til_end
        );
        bets_array.push(bet);
    }

    receive() external payable {}

    function getBet(uint256 _index)
        public
        view
        returns (
            address bettor,
            uint256 bettor_val,
            string memory betDetails,
            address taker,
            uint256 taker_val,
            uint256 days_til_end
        )
    {
        Bet bet = bets_array[_index];
        return (
            bet.bettor(),
            bet.bettor_val(),
            bet.betDetails(),
            bet.taker(),
            bet.taker_val(),
            bet.days_til_end()
        );
    }
}