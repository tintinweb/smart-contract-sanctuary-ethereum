/**
 *Submitted for verification at Etherscan.io on 2023-03-11
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract WinIT {
    // contract owner
    address public owner = msg.sender;
    // total number of bets
    uint public bets_count;

    enum BetStatus { OPEN, CLOSED }
    enum ParticipantStatus { BET, NOT_BET }

    struct Participant {
        uint id;
        address wallet_address;
        ParticipantStatus status;
    }

    struct Bet {
        bytes20 id;
        uint256 amount;
        uint number_of_participants;
        uint number_of_bets_placed;
        uint created_at;
        uint closed_at;
        BetStatus status;
        address judge;
        mapping(uint => Participant) participants;
    }

    // list of bets
    mapping(bytes20 => Bet) public bets;

    event BetCreation(
        bytes20 _bet_id,
        uint256 _bet_amount,
        uint _created_at,
        BetStatus _status,
        address _judge,
        address[] _participants
    );

    event BetPlaced(
        bytes20 _betId,
        address _punter,
        uint256 _amount
    );

    event BetClosed(
        bytes20 _betId,
        BetStatus _status,
        address[] _winners,
        uint256 _amount
    );

    // creates a new bet pool
    function createBet(uint256 _amount, address _judge, address[] memory _participants) public returns(bytes20){
         // requires minimum bet amount of 5€
        require(_amount>=3e15);
        // requires minimum 2 to 10 participants
        require(_participants.length > 1 && _participants.length <= 10);
        // requires judge to not be a participant
        require(!isAddressInParticipants(_judge, _participants));

        // increments total number of bets
        bets_count++;
        // sets bet unique id
        bytes20 _id = generateUniqueId(msg.sender);

        // sets bet id
        bets[_id].id = _id;
        // sets bet amount allowed
        bets[_id].amount = _amount;
        // sets number os participants
        bets[_id].number_of_participants = _participants.length;
        // sets number of bets placed (initialized as 0)
        bets[_id].number_of_bets_placed = 0;
        // sets bet creation date
        bets[_id].created_at = block.timestamp;
        // sets bet closed date
        bets[_id].created_at = 0;
        // sets bet status (initialized as 'OPEN')
        bets[_id].status = BetStatus.OPEN;
        // sets bet judge 
        bets[_id].judge = _judge;

        // sets bet participants
        for (uint i=0; i < _participants.length; i++) {
            // sets participant id
            bets[_id].participants[i].id = i+1;
            // sets participant wallet address
            bets[_id].participants[i].wallet_address = _participants[i];
            // sets participant status (initialized as 'NOT_BET')
            bets[_id].participants[i].status = ParticipantStatus.NOT_BET;
        }

        // emits BetCreation event
        emit BetCreation(
            _id,
            _amount,
            bets[_id].created_at,
            BetStatus.OPEN,
            _judge,
            _participants);

        return _id;
    }

    // returns bet information
    function getBetInfo(bytes20 _id) public view returns(uint256, uint, uint, BetStatus, address, address[] memory) {
        // requires valid id
        require(bets[_id].id == _id);

        address[] memory participants;

        // sets the array of participants wallet addresses
        for (uint i=0; i < bets[_id].number_of_participants; i++) {
            participants[i] = bets[_id].participants[i+1].wallet_address;
        }

        return(
            bets[_id].amount,
            bets[_id].created_at,
            bets[_id].closed_at,
            bets[_id].status,
            bets[_id].judge,
            participants
        );
    }

    // returns participant status 
    function getParticipantStatus(bytes20 _id, address _participant_address) public view returns(ParticipantStatus status) {
        // requires valid id
        require(bets[_id].id == _id);

        for (uint i=1; i <= bets[_id].number_of_participants; i++) {
            if (bets[_id].participants[i].wallet_address == _participant_address) {
                return(
                    bets[_id].participants[i].status
                );
            }
        }
    } 

    // places a bet 
    function placeBet(bytes20 _id) public payable returns(bool) {
        // requires valid id
        require(bets[_id].id == _id);
        // requires given amount equal to bet amount
        require(msg.value == bets[_id].amount);
        // requires bet status equal to 'OPEN'
        require(bets[_id].status == BetStatus.OPEN);
        // requires punter to be in bets list
        require(isParticipantInBet(_id, msg.sender));

        uint participant_id = getParticipantId(_id, msg.sender);

        // requires valid participant id
        require(participant_id > 0);
        // requires punter to not have placed a bet 
        require(bets[_id].participants[participant_id].status == ParticipantStatus.NOT_BET);
        // requires number of bets placed less than number of participants
        require(bets[_id].number_of_bets_placed < bets[_id].number_of_participants);

        // transfers fee to contract owner
        transferFee(msg.value, owner);

        // increments number of bets placed
        bets[_id].number_of_bets_placed++;
        // sets punter status to 'BET'
        bets[_id].participants[participant_id].status = ParticipantStatus.BET;
        
        // emits BetPlaced event
        emit BetPlaced(_id, msg.sender, msg.value);

        return true;
    }

    // closes a bet
    function closeBet(bytes20 _id, address[] memory _winners) public returns(bool) {
        // requires valid id
        require(bets[_id].id == _id);
        // requires number of winners to be 1 up to 10
        require(_winners.length >= 1 && _winners.length <= bets[_id].number_of_bets_placed);
        // requires bet status to be OPEN
        require(bets[_id].status == BetStatus.OPEN);
        // requires function caller to be the bet's judge
        require(msg.sender == bets[_id].judge);
        // requires number of bets placed to be 1 ou more
        require(bets[_id].number_of_bets_placed > 0);
        // requires list of winners to be valid
        require(checkWinners(_id, _winners));

        // bet amount minus owner's fee (1%)
        uint bet_amount = bets[_id].amount - (bets[_id].amount/100);
        // bet total amount
        uint total_amount = calculateTotalAmount(bet_amount, bets[_id].number_of_bets_placed);

        // requires contract balance to be equal bigger than total amount
        require(address(this).balance >= total_amount);
        
        // transfer fee to bet judge
        transferFee(total_amount, msg.sender);
        // total amount to transfer minus judge's fee (1%)
        uint amount_to_transfer = total_amount - (total_amount/100);

        // bet type 'ONE_WINNER' scenario
        if(_winners.length == 1) {
            // converts winner address to payable
            address payable winner = payable(_winners[0]);
            // transfers amount to winner
            winner.transfer(amount_to_transfer);
        } 

        // bet type 'SHARED' scenario
        if(_winners.length > 1) {
            // cicle to transfer shared amount to each winner
            for (uint i=0; i<bets[_id].number_of_bets_placed; i++) {
                // converts winner address to payable
                address payable winner = payable(_winners[i]);
                // transfer amount divide by number of bets placed to winner
                winner.transfer(amount_to_transfer / bets[_id].number_of_bets_placed);
            }
        }

        // sets bet status to CLOSED
        bets[_id].status = BetStatus.CLOSED;
        // sets bet closed date
        bets[_id].closed_at = block.timestamp;
        
        // emits BetClosed event
        emit BetClosed(_id, bets[_id].status, _winners, amount_to_transfer);

        return true;
    }

// ------------------------- INTERNAL FUNCTIONS ------------------------------------------------------

    // verifies winners
    function checkWinners(bytes20 _id, address[] memory _winners) internal view returns(bool) {
        // checks each winner 
        for (uint i=1; i<=bets[_id].number_of_bets_placed; i++) {
            // requires winner to be a participant in bet
            require(isParticipantInBet(_id, _winners[i]));
            // winner did not bet scenario
            if (bets[_id].participants[getParticipantId(_id, _winners[i])].status != ParticipantStatus.BET) {
                // not valid
                return false;
            }     
        }
        // valid
        return true;
    }

    // transfers fee
    function transferFee(uint _amount, address _address) internal {
        // converts address to payable
        address payable receiver = payable(_address);
        // transfers fee (1%)
        receiver.transfer(_amount/100);
    }

    // calculates total amount
    function calculateTotalAmount(uint x, uint y) internal pure returns(uint) {
        require(x > 0 && y > 0);
        uint256 amount = x * y;
        return(amount);
    }

    // verifies if address is in participants list
    function isAddressInParticipants(address _address, address[] memory _participants) internal pure returns(bool) {
        for (uint i=0; i<_participants.length; i++) {
            if(_participants[i] == _address) {
                return true;
            }
        }
        return false;
    }

    // verifies if participant address is in bet
    function isParticipantInBet(bytes20 _bet_id, address _participant) internal view returns(bool) {
        for (uint i=1; i <= bets[_bet_id].number_of_participants; i++) {
            if (bets[_bet_id].participants[i].wallet_address == _participant) {
                return true;
            }
        }
        return false;
    }

    // returns participant id
    function getParticipantId(bytes20 _bet_id, address _participant) internal view returns(uint) {
        for (uint i=1; i <= bets[_bet_id].number_of_participants; i++) {
            if (bets[_bet_id].participants[i].wallet_address == _participant) {
                return i;
            }
        }
        return 0;
    }

    // generates unique id
    function generateUniqueId(address _address) internal view returns(bytes20) {
        return(bytes20(keccak256(abi.encodePacked(_address, bets_count))));
    } 
}