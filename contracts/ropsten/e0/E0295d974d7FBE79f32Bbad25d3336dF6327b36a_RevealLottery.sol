//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CommitRevealBase {
    uint256 public commitDeadline;
    uint256 public revealDeadline;
    bytes32 private randomSeed;
    mapping(address => bytes32) public sealedRandomShards;

    function getRandomSeed() internal view returns (bytes32) {
        require(
            block.timestamp > revealDeadline,
            "Random Seed not finalized yet"
        );
        return randomSeed;
    }

    function commit(bytes32 _sealedRandomShard) internal {
        require(block.timestamp < commitDeadline, "Commit phase closed.");
        sealedRandomShards[msg.sender] = _sealedRandomShard;
    }

    function reveal(uint256 _randomShard) public {
        require(block.timestamp >= commitDeadline, "Still in commit phase.");
        require(block.timestamp < revealDeadline, "Reveal phase closed.");

        bytes32 sealedRandomShard = seal(_randomShard);
        require(
            sealedRandomShard == sealedRandomShards[msg.sender],
            "Invalid Random Shard provided!"
        );

        randomSeed = keccak256(abi.encode(randomSeed, _randomShard));
    }

    // Helper view function to seal a given _randomShard
    function seal(uint256 _randomShard) public view returns (bytes32) {
        return keccak256(abi.encode(msg.sender, _randomShard));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CommitRevealBase.sol";

/// The RevealLottery Implements a lottery using a commit / reveal technique to pick the winner
/// When entrants buy into the lottery, they must submit a random hash along with their funds.
/// At the end, they must reveal what they submitted, and that will be used in a Seed to determine the winner.
/// Chance of winning lottery increases linearly with amount sent to the playLottery endpoint
contract RevealLottery is CommitRevealBase {
    /// The winner of this lottery
    address payable public winner;

    /// Has the lottery Ended?
    bool ended;

    /// A map of entrants to how much they put into the lottery
    mapping(address => uint256) entrantsToPayments;

    /// An array of all entrants
    address payable[] public entrants;

    /// Total amount taken in this lottery
    uint256 public totalLottoAmount;

    /// Duration of lottery commit phase
    uint public constant COMMIT_DURATION = 900;

    /// Duration of lottery reveal phase
    uint public constant REVEAL_DURATION = 900;

    /// Minimum buy-in to partake in the lottery
    uint256 public constant TICKET_PRICE = 0.01 ether;

    /// The function lottoEnd has already been called.
    error LottoEndAlreadyCalled();

    /// The lottery has ended
    error LottoAlreadyEnded();

    /// Need to pay more to enter lottery
    error NotEnoughFunds();

    /// You are not the winner
    error NotAWinner();

    // Events that will be emitted on changes.
    event LottoParticipantAdded(address bidder, uint256 amount);
    event PrizeClaimed(address winner, uint256 amount);
    event PickingWinner();

    /// Create a simple lottory with commit and reveal phases.
    constructor() {
        commitDeadline = block.timestamp + COMMIT_DURATION;
        revealDeadline = commitDeadline + REVEAL_DURATION;
    }

    /// Play the lottery with the value sent together with this transaction
    /// Can optionally provide a sealedRandomShard to contribute to the final randomness of picking the winner
    function playLottery(bytes32 sealedRandomShard) external payable {
        commit(sealedRandomShard);

        if (msg.value < TICKET_PRICE) revert NotEnoughFunds();

        entrantsToPayments[msg.sender] += msg.value;
        entrants.push(payable(msg.sender));
        totalLottoAmount += msg.value;

        emit LottoParticipantAdded(msg.sender, msg.value);
    }

    /// Declares the winner
    function declareWinner() public {
        bytes32 randomSeed = getRandomSeed();
        emit PickingWinner();

        // map random seed to a random point x in an uint space of 0 to totalLottoAmount - 1
        uint256 x = uint256(randomSeed) % totalLottoAmount;
        // Segment the space by the size of payment from each player
        uint256 i;
        for (i = 0; i < entrants.length; i++) {
            // for each segment, see if the random point x fall into the segment
            uint256 segment = entrantsToPayments[entrants[i]];
            if (x < segment) {
                break;
            }
            x -= segment;
        }

        winner = entrants[i];
        ended = true;
    }

    /// Claim the lottery prize if you are the winner
    function claimPrize() public {
        if (!ended || msg.sender != winner) revert NotAWinner();

        emit PrizeClaimed(msg.sender, totalLottoAmount);
        winner.transfer(totalLottoAmount);
    }
}