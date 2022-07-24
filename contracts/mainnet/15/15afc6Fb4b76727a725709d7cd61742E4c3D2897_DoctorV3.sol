// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

//import "hardhat/console.sol";
import "./Randomness.sol";
import "openzeppelin-solidity/contracts/utils/math/Math.sol";


interface IMahin {
    // Coincidence that we get access to the last element of the Piece struct, the uint8, like this.
    function pieces(uint256) view external returns (string memory, uint8);
    function totalSupply() external view returns (uint256);
    function tokenByIndex(uint256 index) external view returns (uint256);
    function diagnose(uint256 tokenId) external;
}


// The NFT contract itself inherits from `Randomness` - thus include it's own random generator.
// However, it also allows a custom contract to be installed to replace the builtin logic.
//
// This is the current replacement contract. It:
//  - Fixes the broken randomness values.
//  - Considers the mint date in its logic.
//  - Is able to apy a reward.
//
// The reward is funded by the Project Mahin treasury in exchange, and paid for triggering
// the diagnosis function. Through this mechanism, the diagnosis process becomes autonomous
// by way of economic incentives.
//
// Calling `requestRoll` locks in the caller as the recipient of the payment for X blocks.
// After X blocks, anyone may call `applyRoll` to earn the fee.
//
// The contract is funded manually by the Project Treasury. The payment amount increases
// as time since the last roll increases.
contract DoctorV3 is Randomness, Ownable {
    IMahin public nft;

    event DiagnosedDoctor(
        uint256 indexed tokenId
    );

    // For how long the reward is locked to the requestRoll() caller.
    uint public rewardLockDuration = 3600;

    // By default, the reward given is 0.8 ether per year.
    uint public rewardPeriodLength = 3600 * 24 * 365;
    uint public rewardPeriodAmount = 0.8 ether;

    // If the reward is currently locked and to who
    address public rewardLockedTo;
    uint public rewardLockedAt;

    constructor(VRFConfig memory vrfConfig, IMahin _nft)
        Randomness(vrfConfig, 1634164223)  // date of last roll: 0x0feb6ad6c6433f2293c283c882f7670c59fddf04e2c75671f719fafefed45273
    {
        nft = _nft;
    }

    function _totalSupply() public view override returns (uint256) {
        return nft.totalSupply();
    }

    function _tokenByIndex(uint256 index) public view override returns (uint256) {
        return nft.tokenByIndex(index);
    }

    function _isDisabled() public pure override returns (bool) {
        return false;
    }

    function onDiagnosed(uint256 tokenId) internal override {
        // Prevent repeat diagnosis. Is a no-op in principal
        (string memory ___, uint8 state) = nft.pieces(tokenId);
        if (state == 1) {
            emit DiagnosedDoctor(tokenId);
            //console.log(' - REPEAT HIT - ');
            return;
        }

        nft.diagnose(tokenId);
    }

    /////////////// Reward logic /////////////////////

    // Allow funding
    receive() external payable {}

    function requestRoll(bool useFallback) public override {
        // If a roll is already scheduled, requestRoll() is a noop. So we first have to
        // ensure no roll is active, such that a reward lock cannot be overwritten.
        if (isRolling()) {
            return;
        }

        // Request a roll
        super.requestRoll(useFallback);

        // Lock the reward to the given user.
        rewardLockedTo = msg.sender;
        rewardLockedAt = block.timestamp;
    }

    function applyRoll() public override {
        applyRollExtended(false);
    }

    // Callers can set noPayout=true if they do not seek a reward.
    function applyRollExtended(bool noPayout) public {
        // Figure out who would be receiving the reward.
        address rewardRecipient;
        uint rewardAmountTargetTime;

        // Ideally, the person who called `requestRoll` will be paid - as long as they don't
        // wait too long. We can't let them "grieve" by refusing to complete the process.
        if (rewardLockedTo != address(0) && (block.timestamp - rewardLockedAt < rewardLockDuration)) {
            rewardRecipient = rewardLockedTo;

            // The caller gains nothing by delaying the call to `applyRoll`.
            // Their reward is determined based on the time `requestRoll` was called.
            rewardAmountTargetTime = rewardLockedAt;
        }

        else {
            // After a certain number of blocks, we will give the reward to whoever calls
            // `applyRoll` to complete the process, even if they were not the ones who called
            // `requestRoll`. This prevents grieving. The reward amount now continues to grow
            // again until someone finds this incentive to be large enough.
            rewardRecipient = msg.sender;
            rewardAmountTargetTime = block.timestamp;
        }

        // Figure out the reward amount. Do this before we "applyRoll()" so that the amount is based
        // on the last roll timestamp still.
        uint256 rewardAmount = getRewardAmount(rewardAmountTargetTime);

        // This will fail if we are not rolling right now.
        super.applyRoll();

        // Pay out ETH
        if (!noPayout) {
            payable(rewardRecipient).transfer(rewardAmount);
        }
    }

    function getRewardAmount(uint256 rewardAmountTargetTime) public view returns (uint256) {
        // Determine how much ETH to pay out
        uint256 rewardPeriod = rewardAmountTargetTime - lastRollAppliedTime;
        uint256 rewardAmount = Math.min(
            address(this).balance,
            (rewardPeriod * rewardPeriodAmount  / rewardPeriodLength)
        );

//        console.log("rewardAmountTargetTime", rewardAmountTargetTime);
//        console.log("lastCompletedRollTime", lastCompletedRollTime);
//        console.log("rewardPeriod", rewardPeriod);
//        console.log("balance", address(this).balance);
//        console.log("rewardAmount", rewardAmount);
//        console.log("--------");

        return rewardAmount;
    }

    /////////////// Admin functions /////////////////////

    function setPerSecondProbability(uint _probabilityPerSecond) public onlyOwner {
        probabilityPerSecond = _probabilityPerSecond;
    }

    function setLastRollTime(uint timestamp) public onlyOwner {
        lastRollAppliedTime = timestamp;
        lastRollRequestedTime = timestamp;
    }

    function setRewardLockDuration(uint256 newDuration) public onlyOwner {
        rewardLockDuration = newDuration;
    }

    function setRewardPeriodLength(uint256 newLength) public onlyOwner {
        rewardPeriodLength = newLength;
    }

    function setRewardPeriodAmount(uint256 newAmount) public onlyOwner {
        rewardPeriodAmount = newAmount;
    }

    function setMintDateRegistry(MintDateRegistry r) public onlyOwner {
        registry = r;
    }

    function withdraw() public onlyOwner {
        address payable owner = payable(owner());
        owner.transfer(address(this).balance);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//import "hardhat/console.sol";
import "./ABDKMath64x64.sol";
import "./ChainlinkVRF.sol";
import "openzeppelin-solidity/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "openzeppelin-solidity/contracts/utils/math/Math.sol";
import "./Roles.sol";
import "./MintDateRegistry.sol";


interface IERC721Adapter {
    function _totalSupply() external view returns (uint256);
    function _tokenByIndex(uint256 index) external view  returns (uint256);
    function _isDisabled() external view returns (bool);
}

abstract contract Randomness is ChainlinkVRF, IERC721Adapter {
    using SafeMath for uint256;

    // Configuration Chainlink VRF
    struct VRFConfig {
        address coordinator;
        address token;
        bytes32 keyHash;
        uint256 price;
    }

    event RollInProgress(
        int128 probability
    );

    event RollComplete();

    // 0.0000000008468506% - This has been pre-calculated to amount to 12.5% over 10 years.
    // Previously, when our project runtime was 5 years, it was 8468506.
    uint probabilityPerSecond                  = 4234253;
    // Previously, probabilityPerSecond was 0.0000000008468506%, based on a 5 year runtime.
    // Tokens which where already affected by the previously larger randomness, now will use:
    uint backAdjustedProbabilityPerSecond      = 3985026;
    uint public constant denominator           = 10000000000000000; // 100%

    uint256 randomSeedBlock = 0;

    uint256 public lastRollRequestedTime = 0;
    uint256 public currentRollRequestedTime = 0;

    // This does not affect randomness; we track the time though, it affects the payout amount
    // in DoctorV3. The payout intervals can deviate from the probability intervals, as the former
    // may need to pay additional incentives to achieve an "apply" call.
    uint256 public lastRollAppliedTime = 0;

    bytes32 chainlinkRequestId = 0;
    uint256 chainlinkRandomNumber = 0;
    bytes32 internal chainlinkKeyHash;
    uint256 internal chainlinkFee;

    MintDateRegistry registry;

    constructor(
        VRFConfig memory config,
        uint initRollTime
    ) ChainlinkVRF(config.coordinator, config.token) {
        chainlinkFee = config.price;
        chainlinkKeyHash = config.keyHash;

        lastRollAppliedTime = initRollTime;
        lastRollRequestedTime = initRollTime;
    }

    // Will return the probability of a (non-)diagnosis for an individual NFT, assuming the roll will happen at
    // `timestamp`. This will be based on the last time a roll happened, targeting a certain total probability
    // over the period the project is running.
    // Will return 0.80 to indicate that the probability of a diagnosis is 20%.
    function getProbabilityForDuration(uint256 secondsSinceLastRoll, bool backAdjusted) public view returns (int128 probability) {
        // Say we want totalProbability = 20% over the course of the project's runtime.
        // If we roll 12 times, what should be the probability of each roll so they compound to 20%?
        //    (1 - x) ** 12 = (1 - 20%)
        // Or generalized:
        //    (1 - x) ** numTries = (1 - totalProbability)
        // Solve by x:
        //     x = 1 - (1 - totalProbability) ** (1/numTries)
        //

        // We use the 64.64 fixed point math library here. More info about this kind of math in Solidity:
        // https://medium.com/hackernoon/10x-better-fixed-point-math-in-solidity-32441fd25d43
        // https://ethereum.stackexchange.com/questions/83785/what-fixed-or-float-point-math-libraries-are-available-in-solidity

        uint256 _p;
        if (backAdjusted) {
            _p = backAdjustedProbabilityPerSecond;
        } else {
            _p = probabilityPerSecond;
        }

        // We already pre-calculated the probability for a 1-second interval
        int128 _denominator = ABDKMath64x64.fromUInt(denominator);
        int128 _probabilityPerSecond = ABDKMath64x64.fromUInt(_p);

        // From the *probability per second* number, calculate the probability for this dice roll based on
        // the number of seconds since the last roll. randomNumber must be larger than this.
        probability = ABDKMath64x64.pow(
        // Convert from our fraction using our denominator, to a 64.64 fixed point number
            ABDKMath64x64.div(
            // reverse-probability of x: (1-x)
                ABDKMath64x64.sub(
                    _denominator,
                    _probabilityPerSecond
                ),
                _denominator
            ),
            secondsSinceLastRoll
        );

        // `randomNumber / (2**64)` would now give us the random number as a 10-base decimal number.
        // To show it in Solidity, which does not support non-integers, we could multiply to shift the
        // decimal point, for example:
        //    console.log("randomNumber",
        //      uint256(ABDKMath64x64.toUInt(
        //        ABDKMath64x64.mul(randomNumber, ABDKMath64x64.fromUInt(1000000))
        //      ))
        //    );
    }

    // The probability when rolling at `timestamp`. Wraps when a roll is requested (even if not yet applied).
    function getProbability(uint256 timestamp) public view returns (int128 probability) {
        uint256 secondsSinceLastRoll = timestamp.sub(Math.max(currentRollRequestedTime, lastRollRequestedTime));
        return getProbabilityForDuration(secondsSinceLastRoll, false);
    }

    // The probability when rolling now. Wraps when a roll is requested (even if not yet applied).
    function rollProbability() public view returns (int128 probability) {
        return getProbability(block.timestamp);
    }

    // Anyone can roll, but the beneficiary is incentivized to do so.
    //
    // # When using Chainlink VRF:
    // Make sure you have previously funded the contract with LINK. Since anyone can start a request at
    // any time, do not prefund the contract; send the tokens when you want to enable a roll.
    //
    // # When using the blockhash-based fallback method:
    // A future block is picked, whose hash will provide the randomness.
    // We accept as low-impact that a miner mining this block could withhold it. A user seed/reveal system
    // to counteract miner withholding introduces too much complexity (need to penalize users etc).
    function requestRoll(bool useFallback) public virtual {
        require(!this._isDisabled(), "rng-disabled");

        // If a roll is already scheduled, do nothing.
        if (isRolling()) { return; }

        if (useFallback) {
            // Two blocks from now, the block hash will provide the randomness to decide the outcome
            randomSeedBlock = block.number + 2;
        }
        else {
            chainlinkRequestId = requestRandomness(chainlinkKeyHash, chainlinkFee, block.timestamp);
        }

        emit RollInProgress(getProbability(block.timestamp));
        currentRollRequestedTime = block.timestamp;
    }

    // Callback: randomness is returned from Chainlink VRF
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        require(requestId == chainlinkRequestId, "invalid-request");
        chainlinkRandomNumber = randomness;
    }

    // Apply the results of the roll (run the randomness function, update NFTs).
    //
    // When using the block-hash based fallback randomness function:
    // If this is not called within 250 odd blocks, the hash of that block will no longer be accessible to us.
    // The roller thus has a possible reason *not* to call apply(), if the outcome is not as they desire.
    // We counteract this as follows:
    // - We consider an incomplete roll as a completed (which did not cause a state chance) for purposes of the
    //   compound probability. That is, you cannot increase the chance of any of the NFTs being diagnosed, you
    //   can only prevent it from happening. A caller looking to manipulate a roll would presumably desire a
    //   diagnosis, as they otherwise would simply do nothing.
    // - We counteract grieving (the repeated calling of pre-roll without calling apply, thus resetting the
    //   probability of a diagnosis) by letting anyone call `apply`, and emitting an event on `preroll`, to make
    //   it easy to watch for that.
    //
    // When using Chainlink VRF:
    //
    // In case we do not get a response from Chainlink within 2 hours, this can be called.
    //
    function applyRoll() public virtual {
        require(isRolling(), "no-roll");

        bytes32 randomness;

        // Roll was started using the fallback random method based on the block hash
        if (randomSeedBlock > 0) {
            require(block.number > randomSeedBlock, "too-early");
            randomness = blockhash(randomSeedBlock);

            // The seed block is no longer available. We act as if the roll led to zero diagnoses.
            if (randomness <= 0) {
                resetRoll();
                return;
            }
        }

        // Roll was started using Chainlink VRF
        else {
            // No response from Chainlink
            if (chainlinkRandomNumber == 0 && block.timestamp - currentRollRequestedTime > 2 hours) {
                resetRoll();
                return;
            }

            require(chainlinkRandomNumber > 0, "too-early");
            randomness = bytes32(chainlinkRandomNumber);
        }

        _applyRandomness(randomness);
        lastRollAppliedTime = block.timestamp;

        // Set the last roll time, which "consumes" parts of the total probability for a diagnosis
        lastRollRequestedTime = currentRollRequestedTime;

        resetRoll();
    }

    function _applyRandomness(bytes32 randomness) internal {
        int128 defaultProbability = getProbabilityForDuration(currentRollRequestedTime - lastRollRequestedTime, false);
        uint256 cutOffDate = block.timestamp - 3600*24*365*10;   // 5 year life span. probability is tuned to this value
        bool hasRegistry = address(registry) != address(0);

        for (uint i=0; i<this._totalSupply(); i++) {
            uint256 tokenId = this._tokenByIndex(i);

            // After a time, this token can no longer be diagnosed - it reached it's life span.
            uint256 mintDate = 0;
            if (hasRegistry) {
                mintDate = registry.getMintDateForToken(tokenId);
            }
            if (mintDate > 0 && mintDate < cutOffDate) {
                continue;
            }
            if (mintDate > 0 && mintDate >= currentRollRequestedTime) {
                // was minted after roll was requested
                continue;
            }

            // For each token, mix in the token id to get a new random number
            bytes32 hash = keccak256(abi.encodePacked(randomness, tokenId));

            // Now we want to convert the token hash to a number between 0 and 1.
            // - 64.64-bit fixed point is a int128  which represents the fraction `{int128}/(64**2)`.
            // - Thus, the lowest 64 bits of the int128 are essentially what is after the decimal point -
            //   the fractional part of the number.
            // - So taking only the lowest 64 bits from a token hash essentially gives us a random number
            //   between 0 and 1.

            // block hash is 256 bits - shift the left-most 64 bits into the right-most position, essentially
            // giving us a 64-bit number. Stored as an int128, this represents a fractional value between 0 and 1
            // in the format used by the 64.64 - fixed point library.

            int128 randomNumber = int128(uint128(uint256(hash) >> 192));
//            console.log("-----------");
//            console.log("RANDOMNUMBER", uint256(int256(randomNumber)));

            int256 finalProbability;

            // If this token was minted *after* the last roll, adjust the probability by the non-active period.
            if (mintDate > 0 && mintDate > lastRollRequestedTime) {
                finalProbability = getProbabilityForDuration(currentRollRequestedTime - mintDate, false);
                //console.log("NEW MINT");
            } else {
                finalProbability = defaultProbability;
            }

            // These tokens have experienced random generator runs with accelerated probability, since initially
            // we are only planning for the project to run for 5 years, and so were applying the randomness w/
            // a higher chance per roll than now that we are targeting 10 years.
            uint256 hardcodedUpgradeDate = 1634164223;   // date of last roll: 0x0feb6ad6c6433f2293c283c882f7670c59fddf04e2c75671f719fafefed45273
            if (mintDate > 0 && mintDate < hardcodedUpgradeDate) {
                finalProbability = getProbabilityForDuration(currentRollRequestedTime - lastRollRequestedTime, true);
                //console.log("GENESIS MINT");
            }

//            console.log("PROBABILITY ", uint256(int256(finalProbability)));
//            console.log("DEFAULT     ", uint256(int256(defaultProbability)));


            if (randomNumber > finalProbability) {
                //console.log(" - HIT - ");
                onDiagnosed(tokenId);
            }
        }
    }

    function resetRoll() internal {
        randomSeedBlock = 0;
        chainlinkRequestId = 0;
        chainlinkRandomNumber = 0;
        currentRollRequestedTime = 0;
        emit RollComplete();
    }

    function isRolling() public view returns (bool) {
        return (randomSeedBlock > 0) || (chainlinkRequestId > 0);
    }

    function onDiagnosed(uint256 tokenId) internal virtual;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: BSD-4-Clause
/*
 * ABDK Math 64.64 Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */
pragma solidity ^0.8.0;

/**
 * Smart contract library of mathematical functions operating with signed
 * 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
 * basically a simple fraction whose numerator is signed 128-bit integer and
 * denominator is 2^64.  As long as denominator is always the same, there is no
 * need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
 * represented by int128 type holding only the numerator.
 */
library ABDKMath64x64 {
    /*
     * Minimum value signed 64.64-bit fixed point number may have.
     */
    int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

    /*
     * Maximum value signed 64.64-bit fixed point number may have.
     */
    int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    /**
     * Convert signed 256-bit integer number into signed 64.64-bit fixed point
     * number.  Revert on overflow.
     *
     * @param x signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
    function fromInt (int256 x) internal pure returns (int128) {
    unchecked {
        require (x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF);
        return int128 (x << 64);
    }
    }

    /**
     * Convert signed 64.64 fixed point number into signed 64-bit integer number
     * rounding down.
     *
     * @param x signed 64.64-bit fixed point number
   * @return signed 64-bit integer number
   */
    function toInt (int128 x) internal pure returns (int64) {
    unchecked {
        return int64 (x >> 64);
    }
    }

    /**
     * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
     * number.  Revert on overflow.
     *
     * @param x unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
    function fromUInt (uint256 x) internal pure returns (int128) {
    unchecked {
        require (x <= 0x7FFFFFFFFFFFFFFF);
        return int128 (int256 (x << 64));
    }
    }

    /**
     * Convert signed 64.64 fixed point number into unsigned 64-bit integer
     * number rounding down.  Revert on underflow.
     *
     * @param x signed 64.64-bit fixed point number
   * @return unsigned 64-bit integer number
   */
    function toUInt (int128 x) internal pure returns (uint64) {
    unchecked {
        require (x >= 0);
        return uint64 (uint128 (x >> 64));
    }
    }

    /**
     * Convert signed 128.128 fixed point number into signed 64.64-bit fixed point
     * number rounding down.  Revert on overflow.
     *
     * @param x signed 128.128-bin fixed point number
   * @return signed 64.64-bit fixed point number
   */
    function from128x128 (int256 x) internal pure returns (int128) {
    unchecked {
        int256 result = x >> 64;
        require (result >= MIN_64x64 && result <= MAX_64x64);
        return int128 (result);
    }
    }

    /**
     * Convert signed 64.64 fixed point number into signed 128.128 fixed point
     * number.
     *
     * @param x signed 64.64-bit fixed point number
   * @return signed 128.128 fixed point number
   */
    function to128x128 (int128 x) internal pure returns (int256) {
    unchecked {
        return int256 (x) << 64;
    }
    }

    /**
     * Calculate x + y.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
    function add (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
        int256 result = int256(x) + y;
        require (result >= MIN_64x64 && result <= MAX_64x64);
        return int128 (result);
    }
    }

    /**
     * Calculate x - y.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
    function sub (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
        int256 result = int256(x) - y;
        require (result >= MIN_64x64 && result <= MAX_64x64);
        return int128 (result);
    }
    }

    /**
     * Calculate x * y rounding down.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
    function mul (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
        int256 result = int256(x) * y >> 64;
        require (result >= MIN_64x64 && result <= MAX_64x64);
        return int128 (result);
    }
    }

    /**
     * Calculate x * y rounding towards zero, where x is signed 64.64 fixed point
     * number and y is signed 256-bit integer number.  Revert on overflow.
     *
     * @param x signed 64.64 fixed point number
   * @param y signed 256-bit integer number
   * @return signed 256-bit integer number
   */
    function muli (int128 x, int256 y) internal pure returns (int256) {
    unchecked {
        if (x == MIN_64x64) {
            require (y >= -0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF &&
            y <= 0x1000000000000000000000000000000000000000000000000);
            return -y << 63;
        } else {
            bool negativeResult = false;
            if (x < 0) {
                x = -x;
                negativeResult = true;
            }
            if (y < 0) {
                y = -y; // We rely on overflow behavior here
                negativeResult = !negativeResult;
            }
            uint256 absoluteResult = mulu (x, uint256 (y));
            if (negativeResult) {
                require (absoluteResult <=
                    0x8000000000000000000000000000000000000000000000000000000000000000);
                return -int256 (absoluteResult); // We rely on overflow behavior here
            } else {
                require (absoluteResult <=
                    0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
                return int256 (absoluteResult);
            }
        }
    }
    }

    /**
     * Calculate x * y rounding down, where x is signed 64.64 fixed point number
     * and y is unsigned 256-bit integer number.  Revert on overflow.
     *
     * @param x signed 64.64 fixed point number
   * @param y unsigned 256-bit integer number
   * @return unsigned 256-bit integer number
   */
    function mulu (int128 x, uint256 y) internal pure returns (uint256) {
    unchecked {
        if (y == 0) return 0;

        require (x >= 0);

        uint256 lo = (uint256 (int256 (x)) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
        uint256 hi = uint256 (int256 (x)) * (y >> 128);

        require (hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        hi <<= 64;

        require (hi <=
            0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo);
        return hi + lo;
    }
    }

    /**
     * Calculate x / y rounding towards zero.  Revert on overflow or when y is
     * zero.
     *
     * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
    function div (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
        require (y != 0);
        int256 result = (int256 (x) << 64) / y;
        require (result >= MIN_64x64 && result <= MAX_64x64);
        return int128 (result);
    }
    }

    /**
     * Calculate x / y rounding towards zero, where x and y are signed 256-bit
     * integer numbers.  Revert on overflow or when y is zero.
     *
     * @param x signed 256-bit integer number
   * @param y signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
    function divi (int256 x, int256 y) internal pure returns (int128) {
    unchecked {
        require (y != 0);

        bool negativeResult = false;
        if (x < 0) {
            x = -x; // We rely on overflow behavior here
            negativeResult = true;
        }
        if (y < 0) {
            y = -y; // We rely on overflow behavior here
            negativeResult = !negativeResult;
        }
        uint128 absoluteResult = divuu (uint256 (x), uint256 (y));
        if (negativeResult) {
            require (absoluteResult <= 0x80000000000000000000000000000000);
            return -int128 (absoluteResult); // We rely on overflow behavior here
        } else {
            require (absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
            return int128 (absoluteResult); // We rely on overflow behavior here
        }
    }
    }

    /**
     * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
     * integer numbers.  Revert on overflow or when y is zero.
     *
     * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
    function divu (uint256 x, uint256 y) internal pure returns (int128) {
    unchecked {
        require (y != 0);
        uint128 result = divuu (x, y);
        require (result <= uint128 (MAX_64x64));
        return int128 (result);
    }
    }

    /**
     * Calculate -x.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
    function neg (int128 x) internal pure returns (int128) {
    unchecked {
        require (x != MIN_64x64);
        return -x;
    }
    }

    /**
     * Calculate |x|.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
    function abs (int128 x) internal pure returns (int128) {
    unchecked {
        require (x != MIN_64x64);
        return x < 0 ? -x : x;
    }
    }

    /**
     * Calculate 1 / x rounding towards zero.  Revert on overflow or when x is
     * zero.
     *
     * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
    function inv (int128 x) internal pure returns (int128) {
    unchecked {
        require (x != 0);
        int256 result = int256 (0x100000000000000000000000000000000) / x;
        require (result >= MIN_64x64 && result <= MAX_64x64);
        return int128 (result);
    }
    }

    /**
     * Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
     *
     * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
    function avg (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
        return int128 ((int256 (x) + int256 (y)) >> 1);
    }
    }

    /**
     * Calculate geometric average of x and y, i.e. sqrt (x * y) rounding down.
     * Revert on overflow or in case x * y is negative.
     *
     * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
    function gavg (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
        int256 m = int256 (x) * int256 (y);
        require (m >= 0);
        require (m <
            0x4000000000000000000000000000000000000000000000000000000000000000);
        return int128 (sqrtu (uint256 (m)));
    }
    }

    /**
     * Calculate x^y assuming 0^0 is 1, where x is signed 64.64 fixed point number
     * and y is unsigned 256-bit integer number.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
   * @param y uint256 value
   * @return signed 64.64-bit fixed point number
   */
    function pow (int128 x, uint256 y) internal pure returns (int128) {
    unchecked {
        bool negative = x < 0 && y & 1 == 1;

        uint256 absX = uint128 (x < 0 ? -x : x);
        uint256 absResult;
        absResult = 0x100000000000000000000000000000000;

        if (absX <= 0x10000000000000000) {
            absX <<= 63;
            while (y != 0) {
                if (y & 0x1 != 0) {
                    absResult = absResult * absX >> 127;
                }
                absX = absX * absX >> 127;

                if (y & 0x2 != 0) {
                    absResult = absResult * absX >> 127;
                }
                absX = absX * absX >> 127;

                if (y & 0x4 != 0) {
                    absResult = absResult * absX >> 127;
                }
                absX = absX * absX >> 127;

                if (y & 0x8 != 0) {
                    absResult = absResult * absX >> 127;
                }
                absX = absX * absX >> 127;

                y >>= 4;
            }

            absResult >>= 64;
        } else {
            uint256 absXShift = 63;
            if (absX < 0x1000000000000000000000000) { absX <<= 32; absXShift -= 32; }
            if (absX < 0x10000000000000000000000000000) { absX <<= 16; absXShift -= 16; }
            if (absX < 0x1000000000000000000000000000000) { absX <<= 8; absXShift -= 8; }
            if (absX < 0x10000000000000000000000000000000) { absX <<= 4; absXShift -= 4; }
            if (absX < 0x40000000000000000000000000000000) { absX <<= 2; absXShift -= 2; }
            if (absX < 0x80000000000000000000000000000000) { absX <<= 1; absXShift -= 1; }

            uint256 resultShift = 0;
            while (y != 0) {
                require (absXShift < 64);

                if (y & 0x1 != 0) {
                    absResult = absResult * absX >> 127;
                    resultShift += absXShift;
                    if (absResult > 0x100000000000000000000000000000000) {
                        absResult >>= 1;
                        resultShift += 1;
                    }
                }
                absX = absX * absX >> 127;
                absXShift <<= 1;
                if (absX >= 0x100000000000000000000000000000000) {
                    absX >>= 1;
                    absXShift += 1;
                }

                y >>= 1;
            }

            require (resultShift < 64);
            absResult >>= 64 - resultShift;
        }
        int256 result = negative ? -int256 (absResult) : int256 (absResult);
        require (result >= MIN_64x64 && result <= MAX_64x64);
        return int128 (result);
    }
    }

    /**
     * Calculate sqrt (x) rounding down.  Revert if x < 0.
     *
     * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
    function sqrt (int128 x) internal pure returns (int128) {
    unchecked {
        require (x >= 0);
        return int128 (sqrtu (uint256 (int256 (x)) << 64));
    }
    }

    /**
     * Calculate binary logarithm of x.  Revert if x <= 0.
     *
     * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
    function log_2 (int128 x) internal pure returns (int128) {
    unchecked {
        require (x > 0);

        int256 msb = 0;
        int256 xc = x;
        if (xc >= 0x10000000000000000) { xc >>= 64; msb += 64; }
        if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
        if (xc >= 0x10000) { xc >>= 16; msb += 16; }
        if (xc >= 0x100) { xc >>= 8; msb += 8; }
        if (xc >= 0x10) { xc >>= 4; msb += 4; }
        if (xc >= 0x4) { xc >>= 2; msb += 2; }
        if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

        int256 result = msb - 64 << 64;
        uint256 ux = uint256 (int256 (x)) << uint256 (127 - msb);
        for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
            ux *= ux;
            uint256 b = ux >> 255;
            ux >>= 127 + b;
            result += bit * int256 (b);
        }

        return int128 (result);
    }
    }

    /**
     * Calculate natural logarithm of x.  Revert if x <= 0.
     *
     * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
    function ln (int128 x) internal pure returns (int128) {
    unchecked {
        require (x > 0);

        return int128 (int256 (
                uint256 (int256 (log_2 (x))) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF >> 128));
    }
    }

    /**
     * Calculate binary exponent of x.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
    function exp_2 (int128 x) internal pure returns (int128) {
    unchecked {
        require (x < 0x400000000000000000); // Overflow

        if (x < -0x400000000000000000) return 0; // Underflow

        uint256 result = 0x80000000000000000000000000000000;

        if (x & 0x8000000000000000 > 0)
            result = result * 0x16A09E667F3BCC908B2FB1366EA957D3E >> 128;
        if (x & 0x4000000000000000 > 0)
            result = result * 0x1306FE0A31B7152DE8D5A46305C85EDEC >> 128;
        if (x & 0x2000000000000000 > 0)
            result = result * 0x1172B83C7D517ADCDF7C8C50EB14A791F >> 128;
        if (x & 0x1000000000000000 > 0)
            result = result * 0x10B5586CF9890F6298B92B71842A98363 >> 128;
        if (x & 0x800000000000000 > 0)
            result = result * 0x1059B0D31585743AE7C548EB68CA417FD >> 128;
        if (x & 0x400000000000000 > 0)
            result = result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8 >> 128;
        if (x & 0x200000000000000 > 0)
            result = result * 0x10163DA9FB33356D84A66AE336DCDFA3F >> 128;
        if (x & 0x100000000000000 > 0)
            result = result * 0x100B1AFA5ABCBED6129AB13EC11DC9543 >> 128;
        if (x & 0x80000000000000 > 0)
            result = result * 0x10058C86DA1C09EA1FF19D294CF2F679B >> 128;
        if (x & 0x40000000000000 > 0)
            result = result * 0x1002C605E2E8CEC506D21BFC89A23A00F >> 128;
        if (x & 0x20000000000000 > 0)
            result = result * 0x100162F3904051FA128BCA9C55C31E5DF >> 128;
        if (x & 0x10000000000000 > 0)
            result = result * 0x1000B175EFFDC76BA38E31671CA939725 >> 128;
        if (x & 0x8000000000000 > 0)
            result = result * 0x100058BA01FB9F96D6CACD4B180917C3D >> 128;
        if (x & 0x4000000000000 > 0)
            result = result * 0x10002C5CC37DA9491D0985C348C68E7B3 >> 128;
        if (x & 0x2000000000000 > 0)
            result = result * 0x1000162E525EE054754457D5995292026 >> 128;
        if (x & 0x1000000000000 > 0)
            result = result * 0x10000B17255775C040618BF4A4ADE83FC >> 128;
        if (x & 0x800000000000 > 0)
            result = result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB >> 128;
        if (x & 0x400000000000 > 0)
            result = result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9 >> 128;
        if (x & 0x200000000000 > 0)
            result = result * 0x10000162E43F4F831060E02D839A9D16D >> 128;
        if (x & 0x100000000000 > 0)
            result = result * 0x100000B1721BCFC99D9F890EA06911763 >> 128;
        if (x & 0x80000000000 > 0)
            result = result * 0x10000058B90CF1E6D97F9CA14DBCC1628 >> 128;
        if (x & 0x40000000000 > 0)
            result = result * 0x1000002C5C863B73F016468F6BAC5CA2B >> 128;
        if (x & 0x20000000000 > 0)
            result = result * 0x100000162E430E5A18F6119E3C02282A5 >> 128;
        if (x & 0x10000000000 > 0)
            result = result * 0x1000000B1721835514B86E6D96EFD1BFE >> 128;
        if (x & 0x8000000000 > 0)
            result = result * 0x100000058B90C0B48C6BE5DF846C5B2EF >> 128;
        if (x & 0x4000000000 > 0)
            result = result * 0x10000002C5C8601CC6B9E94213C72737A >> 128;
        if (x & 0x2000000000 > 0)
            result = result * 0x1000000162E42FFF037DF38AA2B219F06 >> 128;
        if (x & 0x1000000000 > 0)
            result = result * 0x10000000B17217FBA9C739AA5819F44F9 >> 128;
        if (x & 0x800000000 > 0)
            result = result * 0x1000000058B90BFCDEE5ACD3C1CEDC823 >> 128;
        if (x & 0x400000000 > 0)
            result = result * 0x100000002C5C85FE31F35A6A30DA1BE50 >> 128;
        if (x & 0x200000000 > 0)
            result = result * 0x10000000162E42FF0999CE3541B9FFFCF >> 128;
        if (x & 0x100000000 > 0)
            result = result * 0x100000000B17217F80F4EF5AADDA45554 >> 128;
        if (x & 0x80000000 > 0)
            result = result * 0x10000000058B90BFBF8479BD5A81B51AD >> 128;
        if (x & 0x40000000 > 0)
            result = result * 0x1000000002C5C85FDF84BD62AE30A74CC >> 128;
        if (x & 0x20000000 > 0)
            result = result * 0x100000000162E42FEFB2FED257559BDAA >> 128;
        if (x & 0x10000000 > 0)
            result = result * 0x1000000000B17217F7D5A7716BBA4A9AE >> 128;
        if (x & 0x8000000 > 0)
            result = result * 0x100000000058B90BFBE9DDBAC5E109CCE >> 128;
        if (x & 0x4000000 > 0)
            result = result * 0x10000000002C5C85FDF4B15DE6F17EB0D >> 128;
        if (x & 0x2000000 > 0)
            result = result * 0x1000000000162E42FEFA494F1478FDE05 >> 128;
        if (x & 0x1000000 > 0)
            result = result * 0x10000000000B17217F7D20CF927C8E94C >> 128;
        if (x & 0x800000 > 0)
            result = result * 0x1000000000058B90BFBE8F71CB4E4B33D >> 128;
        if (x & 0x400000 > 0)
            result = result * 0x100000000002C5C85FDF477B662B26945 >> 128;
        if (x & 0x200000 > 0)
            result = result * 0x10000000000162E42FEFA3AE53369388C >> 128;
        if (x & 0x100000 > 0)
            result = result * 0x100000000000B17217F7D1D351A389D40 >> 128;
        if (x & 0x80000 > 0)
            result = result * 0x10000000000058B90BFBE8E8B2D3D4EDE >> 128;
        if (x & 0x40000 > 0)
            result = result * 0x1000000000002C5C85FDF4741BEA6E77E >> 128;
        if (x & 0x20000 > 0)
            result = result * 0x100000000000162E42FEFA39FE95583C2 >> 128;
        if (x & 0x10000 > 0)
            result = result * 0x1000000000000B17217F7D1CFB72B45E1 >> 128;
        if (x & 0x8000 > 0)
            result = result * 0x100000000000058B90BFBE8E7CC35C3F0 >> 128;
        if (x & 0x4000 > 0)
            result = result * 0x10000000000002C5C85FDF473E242EA38 >> 128;
        if (x & 0x2000 > 0)
            result = result * 0x1000000000000162E42FEFA39F02B772C >> 128;
        if (x & 0x1000 > 0)
            result = result * 0x10000000000000B17217F7D1CF7D83C1A >> 128;
        if (x & 0x800 > 0)
            result = result * 0x1000000000000058B90BFBE8E7BDCBE2E >> 128;
        if (x & 0x400 > 0)
            result = result * 0x100000000000002C5C85FDF473DEA871F >> 128;
        if (x & 0x200 > 0)
            result = result * 0x10000000000000162E42FEFA39EF44D91 >> 128;
        if (x & 0x100 > 0)
            result = result * 0x100000000000000B17217F7D1CF79E949 >> 128;
        if (x & 0x80 > 0)
            result = result * 0x10000000000000058B90BFBE8E7BCE544 >> 128;
        if (x & 0x40 > 0)
            result = result * 0x1000000000000002C5C85FDF473DE6ECA >> 128;
        if (x & 0x20 > 0)
            result = result * 0x100000000000000162E42FEFA39EF366F >> 128;
        if (x & 0x10 > 0)
            result = result * 0x1000000000000000B17217F7D1CF79AFA >> 128;
        if (x & 0x8 > 0)
            result = result * 0x100000000000000058B90BFBE8E7BCD6D >> 128;
        if (x & 0x4 > 0)
            result = result * 0x10000000000000002C5C85FDF473DE6B2 >> 128;
        if (x & 0x2 > 0)
            result = result * 0x1000000000000000162E42FEFA39EF358 >> 128;
        if (x & 0x1 > 0)
            result = result * 0x10000000000000000B17217F7D1CF79AB >> 128;

        result >>= uint256 (int256 (63 - (x >> 64)));
        require (result <= uint256 (int256 (MAX_64x64)));

        return int128 (int256 (result));
    }
    }

    /**
     * Calculate natural exponent of x.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
    function exp (int128 x) internal pure returns (int128) {
    unchecked {
        require (x < 0x400000000000000000); // Overflow

        if (x < -0x400000000000000000) return 0; // Underflow

        return exp_2 (
            int128 (int256 (x) * 0x171547652B82FE1777D0FFDA0D23A7D12 >> 128));
    }
    }

    /**
     * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
     * integer numbers.  Revert on overflow or when y is zero.
     *
     * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return unsigned 64.64-bit fixed point number
   */
    function divuu (uint256 x, uint256 y) private pure returns (uint128) {
    unchecked {
        require (y != 0);

        uint256 result;

        if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            result = (x << 64) / y;
        else {
            uint256 msb = 192;
            uint256 xc = x >> 192;
            if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
            if (xc >= 0x10000) { xc >>= 16; msb += 16; }
            if (xc >= 0x100) { xc >>= 8; msb += 8; }
            if (xc >= 0x10) { xc >>= 4; msb += 4; }
            if (xc >= 0x4) { xc >>= 2; msb += 2; }
            if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

            result = (x << 255 - msb) / ((y - 1 >> msb - 191) + 1);
            require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

            uint256 hi = result * (y >> 128);
            uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

            uint256 xh = x >> 192;
            uint256 xl = x << 64;

            if (xl < lo) xh -= 1;
            xl -= lo; // We rely on overflow behavior here
            lo = hi << 128;
            if (xl < lo) xh -= 1;
            xl -= lo; // We rely on overflow behavior here

            assert (xh == hi >> 128);

            result += xl / y;
        }

        require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return uint128 (result);
    }
    }

    /**
     * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
     * number.
     *
     * @param x unsigned 256-bit integer number
   * @return unsigned 128-bit integer number
   */
    function sqrtu (uint256 x) private pure returns (uint128) {
    unchecked {
        if (x == 0) return 0;
        else {
            uint256 xx = x;
            uint256 r = 1;
            if (xx >= 0x100000000000000000000000000000000) { xx >>= 128; r <<= 64; }
            if (xx >= 0x10000000000000000) { xx >>= 64; r <<= 32; }
            if (xx >= 0x100000000) { xx >>= 32; r <<= 16; }
            if (xx >= 0x10000) { xx >>= 16; r <<= 8; }
            if (xx >= 0x100) { xx >>= 8; r <<= 4; }
            if (xx >= 0x10) { xx >>= 4; r <<= 2; }
            if (xx >= 0x8) { r <<= 1; }
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1; // Seven iterations should be enough
            uint256 r1 = x / r;
            return uint128 (r < r1 ? r : r1);
        }
    }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LinkTokenInterface.sol";
import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";


// See VRFConsumerBase.sol and VRFRequestIDBase.sol from Chainlink.
abstract contract ChainlinkVRF {
    using SafeMath for uint256;

    /**
     * @notice fulfillRandomness handles the VRF response.
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual;

    /**
     * @notice requestRandomness initiates a request for VRF output given _seed
     */
    function requestRandomness(bytes32 _keyHash, uint256 _fee, uint256 _seed)  internal returns (bytes32 requestId)
    {
        LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, _seed));
        // This is the seed passed to VRFCoordinator. The oracle will mix this with
        // the hash of the block containing this request to obtain the seed/input
        // which is finally passed to the VRF cryptographic machinery.
        uint256 vRFSeed  = makeVRFInputSeed(_keyHash, _seed, address(this), nonces[_keyHash]);
        // nonces[_keyHash] must stay in sync with
        // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
        // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
        // This provides protection against the user repeating their input seed,
        // which would result in a predictable/duplicate output, if multiple such
        // requests appeared in the same block.
        nonces[_keyHash] = nonces[_keyHash].add(1);
        return makeRequestId(_keyHash, vRFSeed);
    }

    LinkTokenInterface immutable internal LINK;
    address immutable private vrfCoordinator;

    // Nonces for each VRF key from which randomness has been requested.
    //
    // Must stay in sync with VRFCoordinator[_keyHash][this]
    mapping(bytes32 /* keyHash */ => uint256 /* nonce */) private nonces;

    /**
     * @param _vrfCoordinator address of VRFCoordinator contract
     * @param _link address of LINK token contract
     *
     * @dev https://docs.chain.link/docs/link-token-contracts
     */
    constructor(address _vrfCoordinator, address _link) {
        vrfCoordinator = _vrfCoordinator;
        LINK = LinkTokenInterface(_link);
    }

    // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
    // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
    // the origin of the call
    function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
        require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
        fulfillRandomness(requestId, randomness);
    }

    /**
   * @notice returns the seed which is actually input to the VRF coordinator
   */
    function makeVRFInputSeed(bytes32 _keyHash, uint256 _userSeed, address _requester, uint256 _nonce) internal pure returns (uint256)
    {
        return  uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
    }

    /**
     * @notice Returns the id for this request
     */
    function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/utils/Context.sol";

/**
 * @dev Uses the Ownable class and adds a second role called the minter.
 *
 * Owner: Can upload tokens, withdraw lost tokens, config ipfs hashes etc. Can also mint tokens.
     Can set the other roles.
 * Minter: Can only mint tokens.
 * Doctor: If set, can diagnose pieces. Replaces the builtin rand gen.
 */
abstract contract Roles is Context, Ownable {
    address private _minter;
    address private _doctor;

    /**
     * @dev Initializes the contract setting the deployer as the initial minter.
     */
    constructor () {
        address msgSender = _msgSender();
        _minter = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current minter.
     */
    function minter() public view returns (address) {
        return _minter;
    }

    /**
     * @dev Returns the address of the doctor.
     */
    function doctor() public view returns (address) {
        return _doctor;
    }

    /**
     * @dev Throws if called by any account other than the minter.
     */
    modifier onlyMinter() {
        require(_minter == _msgSender(), "not minter");
        _;
    }

    /**
     * @dev Throws if called by any account other than the doctor.
     */
    modifier onlyDoctor() {
        require(_doctor == _msgSender(), "not doctor");
        _;
    }

    /**
     * @dev Throws if called by any account other than the minter or the owner.
     */
    modifier onlyMinterOrOwner() {
        require(_minter == _msgSender() || owner() == _msgSender(), "not minter or owner");
        _;
    }

    /**
     * @dev Transfers the minter role of the contract to a new account (`newMinter`).
     * Can only be called by the owner.
     */
    function setMinter(address newMinter) public virtual onlyOwner {
        require(newMinter != address(0), "zero address");
        _minter = newMinter;
    }

    /**
     * @dev Assigns the doctor role, replacing the builtin rng.
     */
    function setDoctor(address newDoctor) public virtual onlyOwner {
        require(newDoctor != address(0), "zero address");
        _doctor = newDoctor;
    }
}

// SPDX-License-Identifier: MIT

// The random generator (DoctorV2) is programmed to linearly increase the odds of a diagnosis
// since the last time it was triggered; the speed with which the odds increase is calibrated
// to accumulate to the total desired probability over the 5-year period.
//
// However, only minted pieces can be diagnosed. Because the initial mint did not sell out,
// if we stopped diagnosis 5 years after project launch, a piece minted one year after launch
// would never be exposed to the full odds we are targeting.
//
// For this reason, we are now adding a registry that keeps track of the mint date. The new
// minting contracts will write these dates, for previously minted pieces, we set the date
// manually. Now that we know the date each piece was minted, a new random generator contract
// can ensure that diagnoses for a piece stop once the five year period has passed.
//
// This process is not entirely accurate. For example, if the randomness generator is "charged"
// with, say, 1-month's odds (i.e. it was last run 1 month ago), then in theory those odds
// should not apply to a token minted today. However, we don't feel it necessary to address this.
// The final odds don't have to be exact; in fact, it feels more true to the spirit of this
// project if the actual odds are *not* mathematically precise.

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "openzeppelin-solidity/contracts/utils/structs/EnumerableSet.sol";

contract MintDateRegistry {

    using EnumerableSet for EnumerableSet.AddressSet;

    address public owner;
    EnumerableSet.AddressSet writers;

    // The initial launch date; we use this as a fallback, and thus do not need to set any values
    // for tokens minted close to launch.
    // https://etherscan.io/tx/0x7426c36fccc7562eafa5e76f0709f9d51d08296f4b76754c5f99810d42dd25c6
    uint256 defaultMintDate = 1616634003;

    mapping(uint256 => uint256) public _mintDateByToken;

    constructor(){
        owner = msg.sender;
    }

    function getMintDateForToken(uint256 tokenId) public view returns (uint256) {
        uint256 date = _mintDateByToken[tokenId];
        if (date > 0) {
            return date;
        }
        return defaultMintDate;
    }

    function setMintDateForToken(uint256 tokenId, uint256 mintDate) public onlyWriter {
        _mintDateByToken[tokenId] = mintDate;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;
    }

    function addWriter(address writer) public onlyOwner {
        writers.add(writer);
    }

    function removeWriter(address writer) public onlyOwner {
        writers.remove(writer);
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "not owner");
        _;
    }

    modifier onlyWriter() {
        require(owner == msg.sender || writers.contains(msg.sender), "not writer");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
    function allowance(address owner, address spender) external view returns (uint256 remaining);
    function approve(address spender, uint256 value) external returns (bool success);
    function balanceOf(address owner) external view returns (uint256 balance);
    function decimals() external view returns (uint8 decimalPlaces);
    function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);
    function increaseApproval(address spender, uint256 subtractedValue) external;
    function name() external view returns (string memory tokenName);
    function symbol() external view returns (string memory tokenSymbol);
    function totalSupply() external view returns (uint256 totalTokensIssued);
    function transfer(address to, uint256 value) external returns (bool success);
    function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success);
    function transferFrom(address from, address to, uint256 value) external returns (bool success);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}