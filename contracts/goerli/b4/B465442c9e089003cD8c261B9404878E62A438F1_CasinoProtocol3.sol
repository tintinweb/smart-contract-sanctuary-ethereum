//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// Casino (Protocol 3) by @artlu99
// based on Casino (Protocol 2) by @ori_pomerantz

contract CasinoProtocol3 {
    struct ProposedBet {
        address sideA;
        uint256 value;
        uint256 placedAt;
        bool accepted;
        uint256 randomA;
    } // struct ProposedBet

    struct AcceptedBet {
        address sideB;
        uint256 acceptedAt;
        uint256 hashB;
        uint256 randomB;
    } // struct AcceptedBet

    // Proposed bets, keyed by the commitmentA value
    mapping(uint256 => ProposedBet) public proposedBet;

    // Accepted bets, also keyed by commitmentA value
    mapping(uint256 => AcceptedBet) public acceptedBet;

    event BetProposed(uint256 indexed _commitmentA, uint256 value);

    event BetAccepted(uint256 indexed _commitmentA, address indexed _sideA);

    event SubmissionAcceptedA(uint256 indexed _commitmentA);

    event SubmissionAcceptedB(uint256 indexed _commitmentA);

    event BetSettled(
        uint256 indexed _commitmentA,
        address winner,
        address loser,
        uint256 value
    );

    // Called by sideA to start the process
    function proposeBet(uint256 _commitmentA) external payable {
        require(
            proposedBet[_commitmentA].value == 0,
            "there is already a bet on that commitment"
        );
        require(msg.value > 0, "you need to actually bet something");

        proposedBet[_commitmentA].sideA = msg.sender;
        proposedBet[_commitmentA].value = msg.value;
        proposedBet[_commitmentA].placedAt = block.timestamp;
        // accepted is false by default

        emit BetProposed(_commitmentA, msg.value);
    } // function proposeBet

    // Called by sideB to continue
    function acceptBet(uint256 _commitmentA, uint256 _commitmentB)
        external
        payable
    {
        require(
            !proposedBet[_commitmentA].accepted,
            "Bet has already been accepted"
        );
        require(
            proposedBet[_commitmentA].sideA != address(0),
            "Nobody made that bet"
        );
        require(
            msg.value == proposedBet[_commitmentA].value,
            "Need to bet the same amount as sideA"
        );

        acceptedBet[_commitmentA].sideB = msg.sender;
        acceptedBet[_commitmentA].acceptedAt = block.timestamp;
        acceptedBet[_commitmentA].hashB = _commitmentB;
        proposedBet[_commitmentA].accepted = true;

        emit BetAccepted(_commitmentA, proposedBet[_commitmentA].sideA);
    } // function acceptBet

    // Called by sideA to continue (asynchronously with submitB)
    function submitA(uint256 _randomA) external {
        uint256 _commitmentA = uint256(keccak256(abi.encodePacked(_randomA)));

        require(
            proposedBet[_commitmentA].value > 0,
            "SubmitA: Not a bet you placed or wrong value"
        );

        require(
            proposedBet[_commitmentA].accepted,
            "SubmitA: Bet has not been accepted yet"
        );

        require(
            proposedBet[_commitmentA].sideA == msg.sender,
            "SubmitA: Not a bet you placed or wrong value"
        );

        proposedBet[_commitmentA].randomA = _randomA;

        emit SubmissionAcceptedA(_commitmentA);
    }

    // Called by sideB to continue (asynchronously with submitA)
    function submitB(uint256 _commitmentA, uint256 _randomB) external {
        require(
            acceptedBet[_commitmentA].sideB == msg.sender,
            "SubmitB: Not a bet you placed or wrong value"
        );

        require(
            acceptedBet[_commitmentA].hashB ==
                uint256(keccak256(abi.encodePacked(_randomB))),
            "wrong value"
        );

        acceptedBet[_commitmentA].randomB = _randomB;

        emit SubmissionAcceptedB(_commitmentA);
    }

    // Called by either side to conclude the bet (caller pays gas)
    function reveal(uint256 _commitmentA) external {
        address payable _sideA = payable(proposedBet[_commitmentA].sideA);
        address payable _sideB = payable(acceptedBet[_commitmentA].sideB);

        require(
            proposedBet[_commitmentA].accepted,
            "Bet has not been accepted yet"
        );

        require(
            _sideA == msg.sender || _sideB == msg.sender,
            "reveal must be called by Proposer or Accepter"
        );

        require(
            acceptedBet[_commitmentA].randomB >= 0,
            "Random B not yet submitted"
        );

        require(
            proposedBet[_commitmentA].randomA >= 0,
            "Random A not yet submitted"
        );

        uint256 _agreedRandom = proposedBet[_commitmentA].randomA ^
            acceptedBet[_commitmentA].randomB;
        uint256 _value = proposedBet[_commitmentA].value;

        // Pay and emit an event
        if (_agreedRandom % 2 == 0) {
            // sideA wins
            _sideA.transfer(2 * _value);
            emit BetSettled(_commitmentA, _sideA, _sideB, _value);
        } else {
            // sideB wins
            _sideB.transfer(2 * _value);
            emit BetSettled(_commitmentA, _sideB, _sideA, _value);
        }

        // Cleanup
        delete proposedBet[_commitmentA];
        delete acceptedBet[_commitmentA];
    } // function reveal
} // contract Casino