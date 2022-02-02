//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// The RevealLottery Implements a lottery using a commit / reveal technique to pick the winner
/// When entrants buy into the lottery, they must submit a random hash along with their funds.
/// At the end, they must reveal what they submitted, and that will be used in a Seed to determine the winner.
/// Chance of winning lottery increases linearly with amount sent to the playLottery endpoint
contract RevealLottery {
    /// The winner of this lottery
    address payable public winner;

    /// Has the lottery Ended?
    bool ended;

    /// A map of entrants to how much they put into the lottery
    mapping(address => uint256) entrantsToPayments;

    /// An array of all entrants
    address payable[] public entrants;

    /// When the lottery ends
    uint public commitEndTime;

    /// When the random shard reveal time ends
    uint public revealEndTime;

    /// Total amount taken in this lottery
    uint public totalLottoAmount;

    /// Duration of lottery commit phase
    uint public constant COMMIT_DURATION = 900;

    /// Duration of lottery reveal phase
    uint public constant REVEAL_DURATION = 900;

    /// Minimum buy-in to partake in the lottery
    uint256 public constant TICKET_PRICE = 0.01 ether;

    /// Final random seed to determine the winner.
    bytes32 public randomSeed;

    /// A map of entrants to their sealed random shard.
    mapping(address => bytes32) entrantsToSealedRandomShards;

    /// The function lottoEnd has already been called.
    error LottoEndAlreadyCalled();

    /// The lottery has ended
    error LottoAlreadyEnded();

    /// Need to pay more to enter lottery
    error NotEnoughFunds();

    /// You are not the winner
    error NotAWinner();

    // Events that will be emitted on changes.
    event LottoParticipantAdded(address bidder, uint amount);
    event PrizeClaimed(address winner, uint amount);
    event PickingWinner();

    /// Create a simple lottory with commit and reveal phases.
    /// Commit Phase: every participant deposit play fund and commit a sealed random shard into the state store
    /// Reveal Phase: every participant reveal the previously commited randanm shard which becomes a part of the random seed for drawing the finanl winner
    constructor() {
        commitEndTime = block.timestamp + COMMIT_DURATION;
        revealEndTime = commitEndTime + REVEAL_DURATION;
    }

    /// Play the lottery with the value sent together with this transaction
    /// Can optionally provide a sealedRandomShard to contribute to the final randomness of picking the winner
    function playLottery(bytes32 sealedRandomShard) external payable {
        if (block.timestamp > commitEndTime)
            revert LottoAlreadyEnded();

        if (msg.value < TICKET_PRICE)
            revert NotEnoughFunds();

        entrantsToPayments[msg.sender] += msg.value;
        entrantsToSealedRandomShards[msg.sender] = sealedRandomShard;
        entrants.push(payable(msg.sender));
        totalLottoAmount += msg.value;

        emit LottoParticipantAdded(msg.sender, msg.value);
    }

    /// (Optionally) Reveal the previously commited sealed random shard to contribute to the randomness of picking the winner
    function reveal(uint randomShard) public {
        require(block.timestamp > commitEndTime, "Still in commit phase.");
        require(block.timestamp <= revealEndTime, "Reveal phase closed.");

        bytes32 sealedRandomShard = seal(randomShard);
        require(
            sealedRandomShard == entrantsToSealedRandomShards[msg.sender],
            "Invalid Random Shard provided!"
        );

        randomSeed = keccak256(abi.encode(randomSeed, randomShard));
    }

    /// Declares the winner
    function declareWinner() public {
        require(block.timestamp > revealEndTime, "Random Seed not finalized yet");
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
        if (!ended || msg.sender != winner)
            revert NotAWinner();

        emit PrizeClaimed(msg.sender, totalLottoAmount);
        winner.transfer(totalLottoAmount);
    }

    /// Helper view function to seal a given randomShard
    function seal(uint256 randomShard) public view returns (bytes32) {
        return keccak256(abi.encode(msg.sender, randomShard));
    }
}