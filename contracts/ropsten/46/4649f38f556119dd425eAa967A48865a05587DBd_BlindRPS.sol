// SPDX-License-Identifier: MIT
// by Hwakyeom Kim(=just-do-halee)

pragma solidity ^0.8.7;

import "./Hand.sol";
import "./State.sol";


contract BlindRPS {
   using HandFn for Hand;
   using StateFn for State;

    constructor() payable {}

    struct Player {
        State state;
        Hand hand;
        uint256 betAmount;
    }

    function playerReset(Player storage player) private {
        player.state.reset();
        player.hand.reset();
        player.betAmount = 0x0;
    }

    mapping(address => Player) players;

    event PlayerDisplay(address playerAddr, address roomAddr, string state, string hand, uint256 betAmount, address competitor);
    event RecordResult(uint256 timestamp, address addr, string result, uint256 plusAmount, uint256 minusAmount);

    function getPlayerDisplay(address addr) private view returns (string memory state, string memory hand, uint256 betAmount, address competitor) {
        Player storage player = players[addr];

        state = player.state.toString();
        hand = player.hand.toString();
        betAmount = player.betAmount;
        competitor = player.state.competitor;
    }

    function getPlayer(address addr) isValidPlayerAddr(addr) 
    external
    view
    returns (string memory state, string memory hand, uint256 betAmount, address competitor) {
        (state, hand, betAmount, competitor) = getPlayerDisplay(addr);
    }

    function destroyRoom() isSenderState(StateKind.PENDING)
    external {
        Player storage owner = players[msg.sender];
        require(
            owner.state.competitor == address(0x0),
            "Something Is Wrong."
        );
        
        payable(msg.sender).transfer(owner.betAmount);
        playerReset(owner);
    }

    function createRoom(uint256 encryptedCard) isSenderState(StateKind.NONE)
    external
    payable {
        address roomAddr = msg.sender;

        players[roomAddr] = Player({
            state: State({
                kind: StateKind.PENDING,
                competitor: address(0x0),
                timestamp: block.timestamp
            }),
            betAmount: msg.value,
            hand: Hand({
                card: Card.ROCK,
                encryptedCard: encryptedCard
            })
        });
        
        (string memory state, string memory hand, uint256 betAmount, address competitor) = getPlayerDisplay(roomAddr);
        emit PlayerDisplay(roomAddr, roomAddr, state, hand, betAmount, competitor);
    }

    function joinRoom(
        Card card,
        address roomAddr
    ) isSenderState(StateKind.NONE) isValidCard(card) isValidPlayerAddr(roomAddr) isRoomFull(roomAddr)
    external
    payable {
        address ownerAddr = roomAddr;
        address participantAddr = msg.sender;

        Player storage participant = players[participantAddr];
        Player storage owner = players[ownerAddr];

        require(
            msg.value >= owner.betAmount,
            "Not Enough BetAmount."
            );

        // participant

        participant.hand.card = card;
        participant.betAmount = msg.value;
        participant.state.competitor = ownerAddr;
        participant.state.kind = StateKind.EXPECTING;
        participant.state.timestamp = block.timestamp;

        // owner
        
        owner.state.competitor = participantAddr;
        owner.state.kind = StateKind.CONCERN;
        owner.state.timestamp = block.timestamp;

        (string memory state, string memory hand, uint256 betAmount, address competitor) = getPlayerDisplay(participantAddr);
        emit PlayerDisplay(participantAddr, ownerAddr, state, hand, betAmount, competitor);
    }

    function urgeOwner()
    external
    returns (bool) {
        
        address participantAddr = msg.sender;
        Player storage participant = players[msg.sender];

        require(
            participant.state.kind == StateKind.EXPECTING,
            "You Are Not a Participant."
        );

        address ownerAddr = participant.state.competitor;
        Player storage owner = players[ownerAddr];

        require(
            owner.state.kind == StateKind.CONCERN,
            "Something Is Wrong."
        );

        if ((block.timestamp - owner.state.timestamp) > 3 days) {

            uint256 totalBetAmount = owner.betAmount + participant.betAmount;

            payable(msg.sender).transfer(totalBetAmount);
            emit RecordResult(block.timestamp, participantAddr, "win", totalBetAmount, participant.betAmount);
            emit RecordResult(block.timestamp, ownerAddr, "lose", 0, owner.betAmount);

            playerReset(owner);
            playerReset(participant);

            return true;
        } else {
            return false;
        }
    }

    function aproveParticipant(
        Card card,
        uint128 password
    ) isSenderState(StateKind.CONCERN) isValidCard(card) isValidCardPassword(msg.sender, card, password)
    external {

        address ownerAddr = msg.sender;
        Player storage owner = players[ownerAddr];

        owner.hand.card = card; // verified

        address participantAddr = owner.state.competitor;
        Player storage participant = players[participantAddr];

        Result ownerWin = owner.hand.isWinning(participant.hand.card);

        uint256 totalBetAmount = owner.betAmount + participant.betAmount;
        uint256 timestamp = block.timestamp;

        string memory winStr = "win";
        string memory loseStr = "lose";
        string memory drawStr = "draw";

        if (ownerWin == Result.WIN) {
            
            payable(ownerAddr).transfer(totalBetAmount);
            emit RecordResult(timestamp, ownerAddr, winStr, totalBetAmount, owner.betAmount);
            emit RecordResult(timestamp, participantAddr, loseStr, 0, participant.betAmount);

        } else if (ownerWin == Result.LOSE) {

            payable(participantAddr).transfer(totalBetAmount);
            emit RecordResult(timestamp, participantAddr, winStr, totalBetAmount, participant.betAmount);
            emit RecordResult(timestamp, ownerAddr, loseStr, 0, owner.betAmount);

        } else {

            payable(ownerAddr).transfer(owner.betAmount);
            payable(participantAddr).transfer(participant.betAmount);
            emit RecordResult(timestamp, ownerAddr, drawStr, 0, 0);
            emit RecordResult(timestamp, participantAddr, drawStr, 0, 0);

        }

        playerReset(owner);
        playerReset(participant);

        
    }

    function testEncrypt(Card card, uint128 password) public pure returns (uint256) {
        return Hand({
            card: card,
            encryptedCard: 0
        }).encrypt(password);
    }


    modifier isValidCardPassword (address playerAddr, Card card, uint128 password) {
        require(
            players[playerAddr].hand.decrypt(card, password) == true,
            "Invalid Card And Password."
        );
        _;
    }

    modifier isRoomFull (address roomAddr) {
        require(
            players[roomAddr].state.kind == StateKind.PENDING,
            "The room is full."
        );
        _;
    }

    modifier isSenderState (StateKind kind) {
        require(
            players[msg.sender].state.kind == kind,
            "Please finish the game first."
        );
        _;
    }

    modifier isValidCard (Card card) {
        require(
            (card == Card.ROCK) ||
            (card == Card.PAPER) ||
            (card == Card.SCISSORS),
            "Unexpected Card Kind."
        );
        _;
    }

    modifier isValidPlayerAddr (address addr) {
        require(
            players[addr].state.kind != StateKind.NONE,
            "Invalid Current Player Address."
            );
        _;
    }
}