/**
 *Submitted for verification at Etherscan.io on 2022-04-24
*/

// File: contracts/PollenParams.sol

// This file is generated for the "mainnet" network
// by the 'generate-PollenAddresses_sol.js' script.
// Do not edit it directly - updates will be lost.
// SPDX-License-Identifier: MIT
pragma solidity >=0.6 <0.7.0;


/// @dev Network-dependant params (i.e. addresses, block numbers, etc..)
contract PollenParams {

    // Pollen contracts addresses
    address internal constant pollenDaoAddress = 0x99c0268759d26616AeC761c28336eccd72CCa39A;
    address internal constant plnTokenAddress = 0xF4db951000acb9fdeA6A9bCB4afDe42dd52311C7;
    address internal constant stemTokenAddress = 0xd12ABa72Cad68a63D9C5c6EBE5461fe8fA774B60;
    address internal constant rateQuoterAddress = 0xB7692BBC55C0a8B768E5b523d068B5552fbF7187;

    // STEM minting params
    uint32 internal constant mintStartBlock = 11565019; // Jan-01-2021 00:00:00 +UTC
    uint32 internal constant mintBlocks = 9200000; // ~ 46 months
    uint32 internal constant extraMintBlocks = 600000; // ~ 92 days

    // STEM vesting pools
    address internal constant rewardsPoolAddress = 0x99c0268759d26616AeC761c28336eccd72CCa39A;
    address internal constant foundationPoolAddress = 0x30dDD235bEd94fdbCDc197513a638D6CAa261EC7;
    address internal constant reservePoolAddress = 0xf8617006b4CD2db7385c1cb613885f1292e51b2e;
    address internal constant marketPoolAddress = 0x256d986bc1d994C36f412b9ED8A269314bA93bc9;
    address internal constant foundersPoolAddress = 0xd7Cc88bB603DceAFB5E8290d8188C8BF36fD742B;

    // Min STEM vesting rewarded by `PollenDAO.updateRewardPool()`
    uint256 internal constant minVestedStemRewarded = 2e4 * 1e18;

    // Default voting terms
    uint32 internal constant defaultVotingExpiryDelay = 12 * 3600;
    uint32 internal constant defaultExecutionOpenDelay = 6 * 3600;
    uint32 internal constant defaultExecutionExpiryDelay = 24 * 3600;
}

// File: contracts/interfaces/IPollenTypes.sol


pragma solidity >=0.6 <0.7.0;


/// @dev Definition of common types
interface IPollenTypes {
    /**
    * @notice Type for representing a proposal type
    */
    enum ProposalType {Invest, Divest}

    /**
    * @notice If the proposal be executed at any or limited market rate
    */
    enum OrderType {Market, Limit}

    /**
    * @notice If the asset amount or Pollen amount is fixed
    * (while the other amount will be updated according to the rate)
    */
    enum BaseCcyType {Asset, Pollen}

    /**
    * @notice Type for representing a token proposal status
    */
    enum ProposalStatus {Null, Submitted, Executed, Rejected, Passed, Pended, Expired}

    /**
    * @notice Type for representing the state of a vote on a proposal
    */
    enum VoterState {Null, VotedYes, VotedNo}

    /**
    * @notice Type for representing a token type
    */
    enum TokenType {ERC20}

    enum RewardKind {ForVoting, ForProposal, ForExecution, ForStateUpdate, ForPlnHeld}

    /// @dev Terms and parameters of a proposal
    struct Proposal {
        ProposalState state;
        ProposalParams params;
        ProposalTerms terms;
    }

    /// @dev Current (mutable) params of a proposal
    struct ProposalState {
        ProposalStatus status;
        uint96 yesVotes;
        uint96 noVotes;
    }

    /// @dev Derived terms (immutable params) of a proposal
    struct ProposalParams {
        uint32 votingOpen;
        uint32 votingExpiry;
        uint32 executionOpen;
        uint32 executionExpiry;
        uint32 snapshotId;
        uint96 passVotes; // lowest bit used for `isExclPools` flag
    }

    /// @dev Original terms (immutable params) of a proposal
    struct ProposalTerms {
        ProposalType proposalType;
        OrderType orderType;
        BaseCcyType baseCcyType;
        TokenType assetTokenType;
        uint8 votingTermsId; // must be 0 (reserved for upgrades)
        uint64 __reserved1; // reserved for upgrades
        address submitter;
        address executor;
        uint96 __reserved2;
        address assetTokenAddress;
        uint96 pollenAmount;
        uint256 assetTokenAmount;
    }

    /// @dev Data on user voting
    struct VoteData {
        VoterState state;
        uint96 votesNum;
    }

    /// @dev Proposal execution details
    struct Execution {
        uint32 timestamp;
        uint224 quoteCcyAmount;
    }

    /// @dev Voting terms
    struct VotingTerms {
        // If new proposals may be submitted with this terms
        bool isEnabled;
        // If Vesting Pools are excluded from voting and quorum
        bool isExclPools;
        // The quorum required to pass a proposal vote in % points
        uint8 quorum;
        // Seconds after proposal submission until voting expires
        uint32 votingExpiryDelay;
        // Seconds after proposal voting expires until execution opens
        uint32 executionOpenDelay;
        // Seconds after proposal execution opens until execution expires
        uint32 executionExpiryDelay;
    }

    /// @dev "Reward points" for members' actions
    struct RewardParams {
        uint16 forVotingPoints;
        uint16 forProposalPoints;
        uint16 forExecutionPoints;
        uint16 forStateUpdPoints;
        uint16 forPlnDayPoints;
        uint176 __reserved;
    }

    // @dev Data on rewards accruals for all members
    struct RewardTotals {
        uint32 lastAccumBlock;
        uint112 accStemPerPoint;
        uint112 totalPoints;
    }

    // @dev Data on a reward
    struct Reward {
        address member;
        RewardKind kind;
        uint256 points;
    }

    // @dev Data on rewards of a member
    struct MemberRewards {
        uint32 lastUpdateBlock;
        uint64 points;
        uint64 entitled;
        uint96 adjustment;
    }
}

// File: contracts/interfaces/IStemGrantor.sol

pragma solidity >=0.6 <0.7.0;
pragma experimental ABIEncoderV2;



/**
* @title IPollenDAO Interface
* @notice Interface for the Pollen DAO
*/
interface IStemGrantor is IPollenTypes {

    function getMemberPoints(address member) external view returns(uint256);

    function getMemberRewards(address member) external view  returns(MemberRewards memory);

    function getPendingStem(address member) external view returns(uint256);

    function getRewardTotals() external view  returns(RewardTotals memory);

    function withdrawRewards(address member) external;

    event PointsRewarded(address indexed member, RewardKind indexed kind, uint256 points);

    event RewardWithdrawal(address indexed member, uint256 amount);

    event StemAllocation(uint256 amount);
}

// File: contracts/lib/SafeUint.sol

pragma solidity >=0.6 <0.7.0;

library SafeUint {
    function safe112(uint256 n) internal pure returns(uint112) {
        require(n < 2**112, "SafeUint:UNSAFE_UINT112");
        return uint112(n);
    }

    function safe96(uint256 n) internal pure returns(uint96) {
        require(n < 2**96, "SafeUint:UNSAFE_UINT96");
        return uint96(n);
    }

    function safe64(uint256 n) internal pure returns(uint64) {
        require(n < 2**64, "SafeUint:UNSAFE_UINT64");
        return uint64(n);
    }

    function safe32(uint256 n) internal pure returns(uint32) {
        require(n < 2**32, "SafeUint:UNSAFE_UINT32");
        return uint32(n);
    }

    function safe16(uint256 n) internal pure returns(uint16) {
        require(n < 2**16, "SafeUint:UNSAFE_UINT16");
        return uint16(n);
    }

    function safe8(uint256 n) internal pure returns(uint8) {
        require(n < 256, "SafeUint:UNSAFE_UINT8");
        return uint8(n);
    }
}

// File: @openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/PollenDAO/StemGrantor.sol


pragma solidity >=0.6 <0.7.0;






/**
* @title StemGrantor Contract
* @notice STEM token reward distribution logic
*/
abstract contract StemGrantor is IStemGrantor {
    using SafeMath for uint256;
    using SafeUint for uint256;

    /**
    * @dev PollenDAO vests STEM tokens to the "Reward pool" for distribution between members
    * as rewards for members' actions.
    * Tokens distributed in proportion to accumulated "reward points" given to a member for
    * actions. The contract vest STEM tokens to a member when the latest "withdraws" them.
    *
    * STEM amount pending to be vested to a member is calculated as:
    *   pendingStem = alreadyEntitled + notYetEntitled                                    (3)
    *   alreadyEntitled = memberRewards.entitled                                          (4)
    *   notYetEntitled = forGivenPointsAmount - memberRewards.adjustment                  (5)
    *   forGivenPointsAmount = memberRewards.points * _rewardTotals.accStemPerPoint       (6)
    * ( memberRewards.entitled and _rewardTotals.accStemPerPoint are scaled for gas savings )
    *
    * Whenever some "reward points" are given to a member, the following happens:
    * 1. If it's the 1st reward in the block, STEM for all members get minted to the contract;
    * 2. `accStemPerPoint` gets updated (w/o yet accounting the new points - newly rewarded
    * points MUST not affect STEM distributions for the past blocks);
    * 2. STEM amount "not yet entitled" to the member up until now gets calculated;
    * 3. "pendingStem" amount is calculated, the value is stored in `memberRewards.entitled`;
    * 4. `memberRewards.points` gets increased by the newly rewarded "points" (affecting
    * distributions in the future).
    */

    // Reserved for possible storage structure changes
    uint256[50] private __gap;

    // Totals for all members
    RewardTotals private _rewardTotals;

    // Mapping from member address to member rewards data
    mapping(address => MemberRewards) private _membersRewards;

    function getMemberPoints(address member) public view override returns(uint256)
    {
        return _membersRewards[member].points;
    }

    function getMemberRewards(
        address member
    ) external view  override returns(MemberRewards memory) {
        return _membersRewards[member];
    }

    function getPendingStem(
        address member
    ) external view override returns(uint256 stemAmount)
    {
        MemberRewards memory memberRewards = _membersRewards[member];
        if (memberRewards.points == 0 && memberRewards.entitled == 0 ) return 0;

        uint256 pendingStem = _getPendingRewardStem();
        RewardTotals memory forecastedTotals = _rewardTotals;
        if (forecastedTotals.totalPoints != 0) {
            _computeRewardTotals(forecastedTotals, 0, pendingStem, block.number);
        }

        stemAmount = _computeMemberRewards(
            memberRewards,
            forecastedTotals.accStemPerPoint,
            0,
            block.number
        );
    }

    function getRewardTotals() external view  override returns(RewardTotals memory) {
        return _rewardTotals;
    }

    function withdrawRewards(address member) external override
    {
        (uint256 accStemPerPoint, ) = _updateRewardTotals(0);

        MemberRewards memory memberRewards = _membersRewards[member];
        uint256 stemAmount = _computeMemberRewards(
            memberRewards,
            accStemPerPoint,
            0,
            block.number
        );
        require(stemAmount != 0, "nothing to withdraw");
        _membersRewards[member] = memberRewards;

        _sendStemTo(member, stemAmount);
        emit RewardWithdrawal(member, stemAmount);
    }

    /**** Internal functions follow ****/

    // Inheriting contract must implement following 3 functions
    /// @dev Get amount of STEMs pending to be vested (sent) to the Rewards Pool
    function _getPendingRewardStem() internal view virtual returns (uint256 amount);
    /// @dev Withdraw pending STEMs to the Rewards Pool (once a block only)
    function _withdrawRewardStem() internal virtual returns(uint256 amount);
    /// @dev Send STEMs to a member (as a reward)
    function _sendStemTo(address member, uint256 amount) internal virtual;

    function _rewardMember(Reward memory reward) internal
    {
        (uint256 accStemPerPoint, bool isFirstGrant) = _updateRewardTotals(reward.points);
        _bookReward(reward, accStemPerPoint, isFirstGrant);
    }

    function _rewardMembers(Reward[2] memory rewards) internal
    {
        uint256 totalPoints = rewards[0].points + rewards[1].points;
        (uint256 accStemPerPoint, bool isFirstGrant) = _updateRewardTotals(totalPoints);
        _bookReward(rewards[0], accStemPerPoint, isFirstGrant);
        if (rewards[1].points != 0) {
            _bookReward(rewards[1], accStemPerPoint, isFirstGrant);
        }
    }

    /**** Private functions follow ****/

    function _updateRewardTotals(
        uint256 pointsToAdd
    ) private returns (uint256 accStemPerPoint, bool isFirstGrant)
    {
        uint256 stemToAdd = 0;
        RewardTotals memory totals = _rewardTotals;

        uint256 blockNow = block.number;
        {
            bool isNeverGranted = totals.accStemPerPoint == 0;
            bool isDistributable = (blockNow > totals.lastAccumBlock) && (// once a block
                (totals.totalPoints != 0) || // there are points to distribute between
                (isNeverGranted && pointsToAdd != 0) // it may be the 1st distribution
            );
            if (isDistributable) {
                stemToAdd = _withdrawRewardStem();
                if (stemToAdd != 0) emit StemAllocation(stemToAdd);
            }
        }

        isFirstGrant = _computeRewardTotals(totals, pointsToAdd, stemToAdd, blockNow);
        _rewardTotals = totals;
        accStemPerPoint = totals.accStemPerPoint;
    }

    function _bookReward(Reward memory reward, uint256 accStemPerPoint, bool isFirstGrant)
    private
    {
        MemberRewards memory memberRewards = _membersRewards[reward.member];

        uint256 pointsToAdd = reward.points;
        if (isFirstGrant) {
            memberRewards.points = (pointsToAdd + memberRewards.points).safe64();
            pointsToAdd = 0;
        }

        uint256 stemRewarded = _computeMemberRewards(
            memberRewards,
            accStemPerPoint,
            pointsToAdd,
            block.number
        );
        memberRewards.entitled = _stemToEntitledAmount(
            stemRewarded,
            uint256(memberRewards.entitled)
        );
        _membersRewards[reward.member] = memberRewards;

        emit PointsRewarded(reward.member, reward.kind, reward.points);
    }

    // Made `internal` for testing (call it from this contract only)
    function _computeRewardTotals(
        RewardTotals memory totals,
        uint256 pointsToAdd,
        uint256 stemToAdd,
        uint256 blockNow
    ) internal pure returns(bool isFirstGrant)
    {
        // Make sure, this function is NEVER called:
        // - for passed "accumulated" blocks
        //  i.e. `require(blockNow >= totals.lastAccumBlock)`
        // - to add STEM if no points have been yet rewarded
        //  i.e. `require(stemToAdd == 0 || totals.totalPoints != 0)`
        // - to add STEM for the 2nd time in a block ('pure|view' calls are OK)
        //  i.e. `require(stemToAdd == 0 || blockNow > totals.lastAccumBlock)`

        isFirstGrant = (totals.accStemPerPoint == 0) && (stemToAdd != 0);

        uint256 oldPoints = totals.totalPoints;
        if (pointsToAdd != 0) {
            totals.totalPoints = pointsToAdd.add(totals.totalPoints).safe112();
            if (isFirstGrant) oldPoints = pointsToAdd.add(oldPoints);
        }

        if (stemToAdd != 0) {
            uint256 accStemPerPoint = uint256(totals.accStemPerPoint).add(
                stemToAdd.mul(1e6).div(oldPoints) // divider can't be 0
            );
            totals.accStemPerPoint = accStemPerPoint.safe112();
            totals.lastAccumBlock = blockNow.safe32();
        }
    }

    // Made `internal` for testing (call it from this contract only)
    function _computeMemberRewards(
        MemberRewards memory memberRewards,
        uint256 accStemPerPoint,
        uint256 pointsToAdd,
        uint256 blockNow
    ) internal pure returns(uint256 stemAmount)
    {
        // Make sure, this function is NEVER called for "past" blocks
        // i.e. `require(blockNow >= memberRewards.lastUpdateBlock)

        stemAmount = _entitledAmountToStemAmount(memberRewards.entitled);
        memberRewards.entitled = 0;
        uint256 oldPoints = memberRewards.points;
        if (pointsToAdd != 0) {
            memberRewards.points = oldPoints.add(pointsToAdd).safe64();
        }

        memberRewards.lastUpdateBlock = blockNow.safe32();
        if (oldPoints != 0) {
            stemAmount = stemAmount.add(
                (accStemPerPoint.mul(oldPoints) / 1e6)
                .sub(memberRewards.adjustment)
            );
        }

        memberRewards.adjustment = (
            accStemPerPoint.mul(memberRewards.points) / 1e6
        ).safe96();
    }

    function _entitledAmountToStemAmount(
        uint64 entitled
    ) private pure returns(uint256 stemAmount) {
        stemAmount = uint256(entitled) * 1e6;
    }

    function _stemToEntitledAmount(
        uint256 stemAmount,
        uint256 prevEntitled
    ) private pure returns(uint64 entitledAmount) {
        uint256 _entitled = prevEntitled.add(stemAmount / 1e6);
        // Max amount is limited by ~18.45e6 STEM tokens (for a member)
        entitledAmount = _entitled < 2**64 ? uint64(_entitled) : 2*64 - 1;
    }
}

// File: contracts/interfaces/IPollenDAO.sol

pragma solidity >=0.6 <0.7.0;





/**
* @title IPollenDAO Interface
* @notice Interface for the Pollen DAO
*/
interface IPollenDAO is IPollenTypes, IStemGrantor {
    /**
    * @notice Returns the current version of the DAO
    * @return The current version of the Pollen DAO
    */
    function version() external pure returns (string memory);

    /**
    * @notice Get the Pollen token (proxy) contract address
    * @return The Pollen contract address
    */
    function getPollenAddress() external pure returns(address);

    /**
    * @notice Get the STEM token (proxy) contract address
    * @return The STEM contract address
    */
    function getStemAddress() external pure returns(address);

    /**
    * @notice Get the address of the RateQuoter contract
    * @return The RateQuoter (proxy) contract address
    */
    function getRateQuoterAddress() external pure returns(address);

    /**
    * @notice Get the price of PLN in ETH based on the price of assets held
    * Example: 0.0004 (expressed in ETH/PLN)  ==>  2500 PLN = 1 ETH
    * @return The price
    */
    function getPollenPrice() external returns(uint256);

    /**
    * @notice Get total proposal count
    * @return The total proposal count
    */
    function getProposalCount() external view returns(uint256);

    /**
    * @notice Get terms, params and the state for a proposal
    * @param proposalId The proposal ID
    * @return terms The terms
    * @return params The params
    * @return descriptionCid The CId of the proposal description
    */
    function getProposal(uint256 proposalId) external view returns(
        ProposalTerms memory terms,
        ProposalParams memory params,
        string memory descriptionCid
    );

    /**
    * @notice Get the state for a proposal
    * @param proposalId The proposal ID
    * @return state The state
    */
    function getProposalState(uint256 proposalId) external view returns(
        ProposalState memory state
    );

    /**
    * @notice Get the state and number of votes of a voter on a specified proposal
    * @param voter The voter address
    * @param proposalId The proposal ID
    * @return The state of the vote
    */
    function getVoteData(address voter, uint256 proposalId) external view returns(VoteData memory);

    /**
    * @notice Get the assets that the DAO holds
    * @return The set of asset token addresses
    */
    function getAssets() external view returns (address[] memory);

    /**
    * @notice Get (a set of) voting terms
    * @param termsId The ID of the voting terms
    * @return The (set of) voting terms
    */
    function getVotingTerms(uint256 termsId) external view returns(VotingTerms memory);

    /**
    * @notice Submit a proposal
    * @param proposalType The type of proposal (e.g., Invest, Divest)
    * @param orderType The type of order (e.g., Market, Limit)
    * @param baseCcyType The type of base currency (e.g., Asset, Pollen)
    * @param termsId The voting terms ID
    * @param assetTokenType The type of the asset token (e.g., ERC20)
    * @param assetTokenAddress The address of the asset token
    * @param assetTokenAmount The minimum (on invest) or exact (on divest) amount of the asset token to receive/pay
    * @param pollenAmount The exact (on invest) or minimum (on divest) amount of Pollen to be paid/received
    * @param executor The of the account that will execute the proposal (may be the same as msg.sender)
    * @param descriptionCid The IPFS CId of the proposal description
    */
    function submit(
        ProposalType proposalType,
        OrderType orderType,
        BaseCcyType baseCcyType,
        uint256 termsId,
        TokenType assetTokenType,
        address assetTokenAddress,
        uint256 assetTokenAmount,
        uint256 pollenAmount,
        address executor,
        string memory descriptionCid
    ) external;

    /**
    * @notice Vote on a proposal
    * @param proposalId The proposal ID
    * @param vote The yes/no vote
    */
    function voteOn(uint256 proposalId, bool vote) external;

    /**
    * @notice Execute a proposal
    * @param proposalId The proposal ID
    * @param data If provided, the message sender is called -
    * it must implement {IPollenCallee}
    */
    function execute(uint256 proposalId, bytes calldata data) external;

    /**
    * @notice Redeem Pollens for asset tokens
    * @param pollenAmount The amount of Pollens to redeem
    */
    function redeem(uint256 pollenAmount) external;

    /**
    * @notice Update the status of a proposal (and get a reward, if updated)
    * @param proposalId The ID of a proposal
    */
    function updateProposalStatus(uint256 proposalId) external;

    /**
    * @notice Update the Reward pool (and get a reward, if updated)
    */
    function updateRewardPool() external;

    /**
     * @notice Event emitted when an asset gets added to supported assets
     */
    event AssetAdded(address indexed asset);

    /**
     * @notice Event emitted when an asset gets removed from supported assets
     */
    event AssetRemoved(address indexed asset);

    /**
     * @notice Event emitted when a proposal is submitted
     */
    event Submitted(
        uint256 proposalId,
        ProposalType proposalType,
        address submitter,
        uint256 snapshotId
    );

    /**
     * @notice Event emitted when a proposal is voted on
     */
    event VotedOn(
        uint256 proposalId,
        address voter,
        bool vote,
        uint256 votes
    );

    /**
     * @notice Event emitted each time the PLN price is quoted
     */
    event PollenPrice(uint256 price);

    /**
     * @notice Event emitted when a proposal is executed
     * @param proposalId The proposal
     * @param amount The amount of Pollen (on invest) or asset token (on divest)
     */
    event Executed(
        uint256 proposalId,
        uint256 amount
    );

    /**
     * @notice Event emitted when Pollens are redeemed
     */
    event Redeemed(
        address sender,
        uint256 pollenAmount
    );

    /**
     * @notice Event emitted when a proposal status gets changed
     */
    event StatusChanged(
        uint proposalId,
        ProposalStatus newStatus,
        ProposalStatus oldStatus
    );

    /**
     * @notice Event emitted when (a set of) voting terms enabled or disabled
     */
    event VotingTermsSwitched(
        uint256 termsId,
        bool isEnabled
    );

    /**
     * @notice Event emitted when reward params get updated
     */
    event RewardParamsUpdated();

    /**
     * @notice Event emitted when new owner is set
     */
    event NewOwner(
        address newOwner,
        address oldOwner
    );
}

// File: contracts/interfaces/IPollenDaoAdmin.sol

pragma solidity >=0.6 <0.7.0;




/**
* @title IPollenDAO Interface - administration functions
* @notice Only the contract owner may call
*/
interface IPollenDaoAdmin is IPollenTypes {
    /**
    * @notice Initializes a new Pollen instance (proxy)
    * @dev May be run once only, the sender becomes the contract owner
    */
    function initialize() external;

    /**
    * @notice Set a new address to be the owner
    * (only the owner may call)
    * @param newOwner The address of the new owner
    */
    function setOwner(address newOwner) external;

    /**
    * @notice Add an asset to supported assets
    * (only the owner may call)
    * @param asset The address of the asset to be added
    */
    function addAsset(address asset) external;

    /**
    * @notice Remove an asset from supported assets
    * (only the owner may call)
    * @param asset The address of the asset to be removed
    */
    function removeAsset(address asset) external;

    function addVotingTerms(VotingTerms memory terms) external;

    function switchVotingTerms(uint256 termsId, bool isEnabled) external;

    function updatePlnWhitelist(
        address[] calldata accounts,
        bool whitelisted
    ) external;

    function updateRewardParams(RewardParams memory _rewardParams) external;
}

// File: contracts/interfaces/IMintableBurnable.sol

pragma solidity >=0.6 <0.7.0;


/**
* @title IMintableBurnable Interface - token minting/burning support
*/
interface IMintableBurnable {

    /**
     * @dev Mints tokens to the owner account.
     * Can only be called by the owner.
     * @param amount The amount of tokens to mint
     */
    function mint(uint256 amount) external;

    /**
     * @dev Destroys `amount` tokens from the caller.
     * @param amount The amount of tokens to mint
     */
    function burn(uint256 amount) external;

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's allowance.
     * Requirements: the caller must have allowance for `accounts`'s tokens of at least `amount`.
     */
    function burnFrom(address account, uint256 amount) external;
}

// File: contracts/interfaces/IWhitelist.sol


pragma solidity >=0.6 <0.7.0;


/**
* @title PollenDAO Pre-release Whitelist
* @notice A whitelist of users to prevent this release from being used on DEXs etc
* @author Quantafire (James Key)
*/
interface IWhitelist {

    /**
    * @notice Check if the address is whitelisted
    * @param account Addresses to check
    * @return Bool of whether _addr is whitelisted or not
    */
    function isWhitelisted(address account) external view returns (bool);

    /**
    * @notice Turn whitelisting on/off and add/remove whitelisted addresses.
    * Only the owner of the contract may call.
    * By default, whitelisting is disabled.
    * To enable whitelisting, add zero address to whitelisted addresses:
    * `updateWhitelist([address(0)], [true])`
    * @param accounts Addresses to add or remove
    * @param whitelisted `true` - to add, `false` - to remove addresses
    */
    function updateWhitelist(address[] calldata accounts, bool whitelisted) external;

    event Whitelist(address addr, bool whitelisted);
}

// File: contracts/interfaces/openzeppelin/IOwnable.sol


pragma solidity >=0.6 <0.7.0;


/**
* @title Interface for `Ownable` (and `OwnableUpgradeSafe`) from the "@openzeppelin" package(s)
*/
interface IOwnable {

    /**
     * @dev Emitted when the ownership is transferred from the `previousOwner` to the `newOwner`.
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() external view returns (address);

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the owner.
     */
    function transferOwnership(address newOwner) external;

    /**
     * @dev Leaves the contract without owner.
     * Can only be called by the owner.
     * It will not be possible to call `onlyOwner` functions anymore.
     */
    function renounceOwnership() external;
}

// File: contracts/interfaces/openzeppelin/ISnapshot.sol

pragma solidity >=0.6 <0.7.0;


/**
* @title ISnapshot - snapshot-support extension from the "@openzeppelin" package(s)
*/
interface ISnapshot {

    /**
     * @dev Emitted when a snapshot identified by `id` is created.
     */
    event Snapshot(uint256 id);

    /**
     * @dev Creates a new snapshot and returns its snapshot id.
     * Can only be called by the owner.
     */
    function snapshot() external returns (uint256);

    /**
     * @dev Retrieves the balance of `account` at the time `snapshotId` was created.
     */
    function balanceOfAt(address account, uint256 snapshotId) external view returns (uint256);

    /**
     * @dev Retrieves the total supply at the time `snapshotId` was created.
     */
    function totalSupplyAt(uint256 snapshotId) external view returns(uint256);
}

// File: @openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/interfaces/IPollen.sol

pragma solidity >=0.6 <0.7.0;







/**
* @title IPollen token Interface
*/
interface IPollen is IERC20, IOwnable, ISnapshot, IMintableBurnable, IWhitelist {
    /**
     * @notice Initializes the contract and sets the token name and symbol
     * @dev Sets the contract `owner` account to the deploying account
     */
    function initialize(string memory name, string memory symbol) external;
}

// File: contracts/interfaces/IPollenCallee.sol

pragma solidity >=0.6 <0.7.0;

/**
* @title IPollenCallee Interface
*/
interface IPollenCallee {
    function onExecute(address sender, uint amountIn, uint amountOut, bytes calldata data) external;
}

// File: contracts/interfaces/IRateQuoter.sol

pragma solidity >=0.6 <0.7.0;


/**
* @title IRateQuoter Interface
*/
interface IRateQuoter {

    /// @dev Only "Spot" for now
    enum RateTypes { Spot, Fixed }
    /// @dev if a rate is quoted against USD or ETH
    enum RateBase { Usd, Eth }
    /**
     * @dev if a rate is expressed in a number of ...
     * the base currency units for one quoted currency unit (i.e. "Direct"),
     * or the quoted currency units per one base currency unit (i.e. "Indirect")
     */
    enum QuoteType { Direct, Indirect }

    struct PriceFeed {
        address feed;
        address asset;
        RateBase base;
        QuoteType side;
        uint8 decimals;
        uint16 maxDelaySecs;
        // 0 - highest; default for now, as only one feed for an asset supported
        uint8 priority;
    }

    /**
     * @notice Initializes the contract and sets the token name and symbol.
     * Registers the deployer as the contract `owner`. Can be called once only.
     */
    function initialize() external;

    /**
     * @dev Return the latest price of the given base asset against given quote asset
     * from a highest priority possible feed, direct quotes (ETH/asset), default decimals
     * (it reverts if the rate is older then the RATE_DELAY_MAX_SECS)
     */
    function quotePrice(address asset) external returns (uint256 rate, uint256 updatedAt);

    /**
    * @dev
    */
    function getPriceFeedData(address asset) external view returns (PriceFeed memory);

    /**
    * @dev
    */
    function addPriceFeed(PriceFeed memory priceFeed) external;

    /**
    * @dev
    */
    function addPriceFeeds(PriceFeed[] memory priceFeeds) external;

    /**
    * @dev
    */
    function removePriceFeed(address feed) external;

    event PriceFeedAdded(address indexed asset, address feed);
    event PriceFeedRemoved(address asset);

    // TODO: Extend the IRateQuoter to support the following specs
    // function quotePriceExtended(
    //    address base,
    //    address quote,
    //    address feed,
    //    RateBase base,
    //    QuoteType side,
    //    uint256 decimals,
    //    uint256 maxDelay,
    //    bool forceUpdate
    // ) external returns (uint256 rate, uint256 timestamp);
}

// File: contracts/interfaces/IStemVesting.sol

pragma solidity >=0.6 <0.7.0;



/**
* @title STEM token Interface
*/
interface IStemVesting {

    /// @dev Params of a vesting pool
    struct StemVestingPool {
        bool isRestricted; // if `true`, the 'wallet' only may trigger withdrawal
        uint32 startBlock;
        uint32 endBlock;
        uint32 lastVestedBlock;
        uint128 perBlockStemScaled; // scaled (multiplied) by 1e6
    }

    /**
     * @notice Initializes the contract, sets the token name and symbol, creates vesting pools
     * @param foundationWallet The foundation wallet
     * @param reserveWallet The reserve wallet
     * @param foundersWallet The founders wallet
     * @param marketWallet The market wallet
     */
    function initialize(
        address foundationWallet,
        address reserveWallet,
        address foundersWallet,
        address marketWallet
    ) external;

    /**
     * @notice Returns params of a vesting pool
     * @param wallet The address of the pool' wallet
     * @return Vesting pool params
     */
    function getVestingPoolParams(address wallet) external view returns(StemVestingPool memory);

    /**
     * @notice Returns the amount of STEM pending to be vested to a pool
     * @param wallet The address of the pool' wallet
     * @return amount Pending STEM token amount
     */
    function getPoolPendingStem(address wallet) external view returns(uint256 amount);

    /**
     * @notice Withdraw pending STEM tokens to a pool
     * @param wallet The address of the pool' wallet
     * @return amount Withdrawn STEM token amount
     */
    function withdrawPoolStem(address wallet) external returns (uint256 amount);

    /// @dev New vesting pool registered
    event VestingPool(address indexed wallet);
    /// @dev STEM tokens mint to a pool
    event StemWithdrawal(address indexed wallet, uint256 amount);
}

// File: contracts/lib/AddressSet.sol

pragma solidity >=0.6 <0.7.0;

/**
* @title AddressSet Library
* @notice Library for representing a set of addresses
* @author gtlewis
*/
library AddressSet {
    /**
    * @notice Type for representing a set of addresses
    * @member elements The elements of the set, contains address 0x0 for deleted elements
    * @member indexes A mapping of the address to the index in the set, counted from 1 (rather than 0)
    */
    struct Set {
        address[] elements;
        mapping(address => uint256) indexes;
    }

    /**
    * @notice Add an element to the set (internal)
    * @param self The set
    * @param value The element to add
    * @return False if the element is already in the set or is address 0x0
    */
    function add(Set storage self, address value) internal returns (bool)
    {
        if (self.indexes[value] != 0 || value == address(0)) {
            return false;
        }

        self.elements.push(value);
        self.indexes[value] = self.elements.length;
        return true;
    }

    /**
    * @notice Remove an element from the set (internal)
    * @param self The set
    * @param value The element to remove
    * @return False if the element is not in the set
    */
    function remove(Set storage self, address value) internal returns (bool)
    {
        if (self.indexes[value] == 0) {
            return false;
        }

        delete(self.elements[self.indexes[value] - 1]);
        self.indexes[value] = 0;
        return true;
    }

    /**
    * @notice Returns true if an element is in the set (internal view)
    * @param self The set
    * @param value The element
    * @return True if the element is in the set
    */
    function contains(Set storage self, address value) internal view returns (bool)
    {
        return self.indexes[value] != 0;
    }
}

// File: contracts/lib/SafeMath96.sol

pragma solidity 0.6.12;

library SafeMath96 {

    function add(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        uint96 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function add(uint96 a, uint96 b) internal pure returns (uint96) {
        return add(a, b, "SafeMath96: addition overflow");
    }

    function sub(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function sub(uint96 a, uint96 b) internal pure returns (uint96) {
        return sub(a, b, "SafeMath96: subtraction overflow");
    }

    function fromUint(uint n, string memory errorMessage) internal pure returns (uint96) {
        require(n < 2**96, errorMessage);
        return uint96(n);
    }

    function fromUint(uint n) internal pure returns (uint96) {
        return fromUint(n, "SafeMath96: exceeds 96 bits");
    }
}

// File: contracts/lib/SafeMath32.sol

pragma solidity 0.6.12;

library SafeMath32 {

    function add(uint32 a, uint32 b, string memory errorMessage) internal pure returns (uint32) {
        uint32 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function add(uint32 a, uint32 b) internal pure returns (uint32) {
        return add(a, b, "SafeMath32: addition overflow");
    }

    function sub(uint32 a, uint32 b, string memory errorMessage) internal pure returns (uint32) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function sub(uint32 a, uint32 b) internal pure returns (uint32) {
        return sub(a, b, "SafeMath32: subtraction overflow");
    }

    function fromUint(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function fromUint(uint n) internal pure returns (uint32) {
        return fromUint(n, "SafeMath32: exceeds 32 bits");
    }
}

// File: @openzeppelin/contracts-ethereum-package/contracts/Initializable.sol

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// File: @openzeppelin/contracts-ethereum-package/contracts/utils/Address.sol

pragma solidity ^0.6.2;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// File: @openzeppelin/contracts-ethereum-package/contracts/token/ERC20/SafeERC20.sol

pragma solidity ^0.6.0;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: @openzeppelin/contracts-ethereum-package/contracts/utils/ReentrancyGuard.sol

pragma solidity ^0.6.0;


/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
contract ReentrancyGuardUpgradeSafe is Initializable {
    bool private _notEntered;


    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {


        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;

    }


    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }

    uint256[49] private __gap;
}

// File: contracts/PollenDAO_v1.sol


pragma solidity >=0.6 <0.7.0;





















/**
* @title PollenDAO Contract
* @notice The main Pollen DAO contract
*/
contract PollenDAO_v1 is
    Initializable,
    ReentrancyGuardUpgradeSafe,
    PollenParams,
    StemGrantor,
    IPollenDAO,
    IPollenDaoAdmin
{
    using AddressSet for AddressSet.Set;
    using SafeMath for uint256;
    using SafeUint for uint256;
    using SafeMath96 for uint96;
    using SafeMath32 for uint32;
    using SafeERC20 for IERC20;

    // Price of PLN for the 1st proposal, in ETH/PLN with 18 decimals
    uint256 internal constant plnInitialRate = 400e12; // 1ETH = 2500 PLN

    // "Points" for rewarding members (with STEM) for actions
    uint16 internal constant forVotingDefaultPoints = 100;
    uint16 internal constant forProposalDefaultPoints = 300;
    uint16 internal constant forExecutionDefaultPoints = 500;
    uint16 internal constant forStateUpdDefaultPoints = 10;
    uint16 internal constant forPlnDayDefaultPoints = 5;
    // TODO: implement maxForSingleMemberSharePercents limit
    uint16 internal constant maxForSingleMemberSharePercents = 20;

    // Default voting terms (see more in `PollenParams.sol`)
    uint8 internal constant defaultQuorum = 30;

    // Min and max allowed delays for voting terms
    uint256 internal constant minDelay = 60;
    uint256 internal constant maxDelay = 3600 * 24 * 365;

    // Reserved for possible storage structure changes
    uint256[50] private __gap;

    // The contract owner
    address private _owner;

    // The count of proposals
    uint32 private _proposalCount;

    // Number of voting terms sets
    uint16 private _votingTermsNum;

    // The set of assets that the DAO holds
    AddressSet.Set private _assets;

    /// @notice Member activity rewards params
    RewardParams public rewardParams;

    // mapping from voting terms ID to voting terms data
    mapping(uint256 => VotingTerms) internal _votingTerms;

    // Mapping from proposal ID to proposal data
    mapping(uint256 => Proposal) internal _proposals;

    /// @dev Mapping from proposal ID to description content Id
    mapping(uint256 => string) private _descriptionCids;

    // Mapping from proposal ID to proposal execution data
    mapping(uint256 => Execution) private _executions;

    // Mapping from member address and proposal ID to voting data
    mapping(address => mapping(uint256 => VoteData)) private _voteData;

    modifier onlyOwner() {
        require(_owner == msg.sender, "PollenDAO: unauthorised call");
        _;
    }

    modifier revertZeroAddress(address _address) {
        require(_address != address(0), "PollenDAO: invalid address");
        _;
    }

    /// @inheritdoc IPollenDaoAdmin
    function initialize() external override initializer {
        __ReentrancyGuard_init_unchained();
        _owner = msg.sender;
        _addVotingTerms(
            VotingTerms(
                true, // is enabled
                true, // do not count vesting pools' votes
                defaultQuorum,
                defaultVotingExpiryDelay,
                defaultExecutionOpenDelay,
                defaultExecutionExpiryDelay
            )
        );
        _initRewardParams(
            RewardParams(
                forVotingDefaultPoints,
                forProposalDefaultPoints,
                forExecutionDefaultPoints,
                forStateUpdDefaultPoints,
                forPlnDayDefaultPoints,
                0 // reserved
            )
        );
    }

    /// @inheritdoc IPollenDAO
    function version() external pure override returns (string memory) {
        return "v1";
    }

    /// @inheritdoc IPollenDAO
    function getPollenAddress() external pure override returns(address) {
        return address(_plnAddress());
    }

    /// @inheritdoc IPollenDAO
    function getStemAddress() external pure override returns(address) {
        return _stemAddress();
    }

    /// @inheritdoc IPollenDAO
    function getRateQuoterAddress() external pure override returns(address) {
        return _rateQuoterAddress();
    }

    /// @inheritdoc IPollenDAO
    function getPollenPrice() public override returns(uint256) {
        return _getPollenPrice();
    }

    /// @inheritdoc IPollenDAO
    function getProposalCount() external view override returns(uint256) {
        return _proposalCount;
    }

    /// @inheritdoc IPollenDAO
    function getProposal(uint proposalId) external view override returns (
        ProposalTerms memory terms,
        ProposalParams memory params,
        string memory descriptionCid
    ) {
        _validateProposalId(proposalId);
        terms = _proposals[proposalId].terms;
        params = _proposals[proposalId].params;
        descriptionCid = _descriptionCids[proposalId];
    }

    function getProposalState(
        uint256 proposalId
    ) external view override returns(ProposalState memory state) {
        _validateProposalId(proposalId);
        state = _proposals[proposalId].state;
    }

    /// @inheritdoc IPollenDAO
    function getVoteData(
        address voter,
        uint256 proposalId
    ) external view override returns(VoteData memory) {
        _validateProposalId(proposalId);
        return (_voteData[voter][proposalId]);
    }

    /// @inheritdoc IPollenDAO
    function getAssets() external view override returns (address[] memory) {
        return _assets.elements;
    }

    /// @inheritdoc IPollenDAO
    function getVotingTerms(
        uint256 termsId
    ) external view override returns(VotingTerms memory) {
        return _getTermSheet(termsId);
    }

    /// @inheritdoc IPollenDAO
    function submit(
        ProposalType proposalType,
        OrderType orderType,
        BaseCcyType baseCcyType,
        uint256 termsId,
        TokenType assetTokenType,
        address assetTokenAddress,
        uint256 assetTokenAmount,
        uint256 pollenAmount,
        address executor,
        string memory descriptionCid
    ) external override revertZeroAddress(assetTokenAddress) {
        require(
            IWhitelist(_plnAddress()).isWhitelisted(msg.sender),
            "PollenDAO: unauthorized"
        );
        require(proposalType <= ProposalType.Divest, "PollenDAO: invalid proposal type");
        require(orderType <= OrderType.Limit, "PollenDAO: invalid order type");
        require(baseCcyType <= BaseCcyType.Pollen, "PollenDAO: invalid base ccy type");
        require(assetTokenType == TokenType.ERC20, "PollenDAO: invalid asset type");
        require(_assets.contains(assetTokenAddress), "PollenDAO: unsupported asset");
        require(executor != address(0), "PollenDAO: invalid executor");
        {
            bool isAssetFixed = baseCcyType == BaseCcyType.Asset;
            bool isMarket = orderType == OrderType.Market;
            require(
                isAssetFixed ? assetTokenAmount != 0 : pollenAmount != 0,
                "PollenDAO: zero base amount"
            );
            require(
                isMarket || (isAssetFixed ? pollenAmount != 0 : assetTokenAmount != 0),
                "PollenDAO: invalid quoted amount"
            );
        }

        uint256 proposalId = _proposalCount;
        _proposalCount = (proposalId + 1).safe32();

        _proposals[proposalId].terms = ProposalTerms(
            proposalType,
            orderType,
            baseCcyType,
            assetTokenType,
            termsId.safe8(),
            0, // reserved
            msg.sender,
            executor,
            0, // reserved
            assetTokenAddress,
            pollenAmount.safe96(),
            assetTokenAmount
        );
        _descriptionCids[proposalId] = descriptionCid;

        uint256 snapshotId = 0;

        if (proposalId == 0) {
            uint32 expiry = now.safe32();
            _proposals[proposalId].params = ProposalParams(
                expiry,     // voting open
                expiry,     // voting expiry
                expiry,     // exec open
                expiry.add( // exec expiry
                    defaultExecutionExpiryDelay
                ),
                uint32(snapshotId),
                0           // no voting (zero passVotes)
            );
            _proposals[proposalId].state = ProposalState(ProposalStatus.Passed, 0, 0);
        } else {
            VotingTerms memory terms = _getTermSheet(termsId);
            require(terms.isEnabled, "PollenDAO: disabled terms");
            uint32 votingOpen = now.safe32();
            uint32 votingExpiry = votingOpen.add(terms.votingExpiryDelay);
            uint32 execOpen = votingExpiry.add(terms.executionOpenDelay);
            uint32 execExpiry = execOpen.add(terms.executionExpiryDelay);

            uint256 totalVotes;
            (snapshotId, totalVotes) = _takeSnapshot(terms.isExclPools);
            // The lowest bit encodes `terms.isExclPools` flag
            uint256 passVotes = (totalVotes.mul(terms.quorum) / 100) | 1;
            if (!terms.isExclPools) passVotes -= 1; // even, if pools included

            ProposalParams memory params = ProposalParams(
                votingOpen,
                votingExpiry,
                execOpen,
                execExpiry,
                snapshotId.safe32(),
                passVotes.safe96()
            );
            _proposals[proposalId].params = params;
            _proposals[proposalId].state = ProposalState(ProposalStatus.Submitted, 0, 0);

            uint256 senderVotes = _getVotesOfAt(msg.sender, snapshotId);
            if (senderVotes != 0) {
                _doVoteAndReward(proposalId, params, msg.sender, true, senderVotes);
            }
        }

        emit Submitted(proposalId, proposalType, msg.sender, snapshotId);
    }

    /// @inheritdoc IPollenDAO
    function voteOn(uint256 proposalId, bool vote) external override {
        _validateProposalId(proposalId);
        (ProposalStatus newStatus, ) = _updateProposalStatus(proposalId, ProposalStatus.Null);
        _revertWrongStatus(newStatus, ProposalStatus.Submitted);

        uint256 newVotes = _getVotesOfAt(msg.sender, _proposals[proposalId].params.snapshotId);
        require(newVotes != 0, "PollenDAO: no votes to vote with");

       _doVoteAndReward(proposalId, _proposals[proposalId].params, msg.sender, vote, newVotes);
    }

    /// @inheritdoc IPollenDAO
    function execute(uint256 proposalId, bytes calldata data) external override nonReentrant {
        _validateProposalId(proposalId);

        ProposalTerms memory terms = _proposals[proposalId].terms;
        require(terms.executor == msg.sender, "PollenDAO: unauthorized executor");

        (ProposalStatus newStatus,  ) = _updateProposalStatus(proposalId, ProposalStatus.Null);
        _revertWrongStatus(newStatus, ProposalStatus.Pended);

        IPollen pollen = IPollen(_plnAddress());
        uint256 pollenAmount;
        uint256 assetAmount;
        bool isPollenFixed = terms.baseCcyType == BaseCcyType.Pollen;
        {
            IRateQuoter rateQuoter = IRateQuoter(_rateQuoterAddress());
            // Ex.: assetRate = 0.001 ETH/DAI
            // (i.e., `ethers = assetAmount * assetRate`: 1 ETH = 1000 DAI * 0.001 ETH/DAI)
            (uint256 assetRate, ) = rateQuoter.quotePrice(terms.assetTokenAddress);
            // Ex.: plnRate   = 0.0004 ETH/PLN
            // (i.e., `ethers = plnAmount * plnRate`: 1 ETH = 2500 PLN * 0.0004 ETH/PLN)
            uint256 plnRate = _getPollenPrice();

            if (isPollenFixed) {
                pollenAmount = terms.pollenAmount;
                // Ex.: 2 DAI = 5 PLN * 0.0004 ETH/PLN / 0.001 ETH/DAI
                assetAmount = pollenAmount.mul(plnRate).div(assetRate);
            } else {
                assetAmount = terms.assetTokenAmount;
                // Ex.: 5 PLN = 2 DAI * 0.001 ETH/DAI / 0.0004 ETH/PLN
                pollenAmount = assetAmount.mul(assetRate).div(plnRate);
            }
        }

        bool isLimitOrder = terms.orderType == OrderType.Limit;
        if (terms.proposalType == ProposalType.Invest) {
            if (isLimitOrder) {
                if (isPollenFixed) {
                    if (terms.assetTokenAmount > assetAmount)
                        assetAmount = terms.assetTokenAmount;
                } else {
                    if (terms.pollenAmount < pollenAmount)
                        pollenAmount = terms.pollenAmount;
                }
            }

            // OK to send Pollen first as long as the asset received in the end
            pollen.mint(pollenAmount);
            pollen.transfer(msg.sender, pollenAmount);

            if (data.length > 0) {
                IPollenCallee(msg.sender).onExecute(msg.sender, assetAmount, pollenAmount, data);
            }

            IERC20(terms.assetTokenAddress)
            .safeTransferFrom(msg.sender, address(this), assetAmount);
        }
        else if (terms.proposalType == ProposalType.Divest) {
            if (isLimitOrder) {
                if (isPollenFixed) {
                    if (terms.assetTokenAmount < assetAmount)
                        assetAmount = terms.assetTokenAmount;
                } else {
                    if (terms.pollenAmount > pollenAmount)
                        pollenAmount = terms.pollenAmount;
                }
            }

            // OK to send assets first as long as Pollen burnt in the end
            IERC20(terms.assetTokenAddress).safeTransfer(msg.sender, assetAmount);

            if (data.length > 0) {
                IPollenCallee(msg.sender).onExecute(msg.sender, pollenAmount, assetAmount, data);
            }

            pollen.burnFrom(msg.sender, pollenAmount);
        } else {
            revert("unsupported proposal type");
        }

        uint256 quotedAmount = isPollenFixed ? assetAmount : pollenAmount;

        _executions[proposalId] = Execution(uint32(block.timestamp), uint224(quotedAmount));
        _updateProposalStatus(proposalId, ProposalStatus.Executed);

        emit Executed(proposalId, quotedAmount);

        {
            RewardParams memory p = rewardParams;
            Reward[2] memory rewards;
            rewards[0] = Reward(terms.submitter, RewardKind.ForProposal, p.forProposalPoints);
            rewards[1] = Reward(msg.sender, RewardKind.ForExecution, p.forExecutionPoints);
            _rewardMembers(rewards);
        }
    }

    /// @inheritdoc IPollenDAO
    function redeem(uint256 pollenAmount) external override nonReentrant {
        require(pollenAmount != 0, "PollenDAO: can't redeem zero");

        IPollen pollen = IPollen(_plnAddress());
        uint256 totalSupply = pollen.totalSupply();
        pollen.burnFrom(msg.sender, pollenAmount);

        // unbounded loop ignored
        for (uint256 i=0; i < _assets.elements.length; i++) {
            IERC20 asset = IERC20(_assets.elements[i]);
            if (address(asset) != address(0)) {
                uint256 assetBalance = asset.balanceOf(address(this));
                if (assetBalance == 0) {
                    continue;
                }
                uint256 assetAmount = assetBalance.mul(pollenAmount).div(totalSupply);
                asset.transfer(
                    msg.sender,
                    assetAmount > assetBalance ? assetBalance : assetAmount
                );
            }
        }

        emit Redeemed(
            msg.sender,
            pollenAmount
        );
    }

    /// @inheritdoc IPollenDAO
    function updateProposalStatus(uint256 proposalId) external override {
        (ProposalStatus newStatus,  ProposalStatus oldStatus) = _updateProposalStatus(
            proposalId,
            ProposalStatus.Null
        );
        if (oldStatus != newStatus) {
            RewardParams memory params = rewardParams;
            _rewardMember(Reward(msg.sender, RewardKind.ForStateUpdate, params.forStateUpdPoints));
        }
    }

    /// @inheritdoc IPollenDAO
    function updateRewardPool() external override nonReentrant {
        uint256 pendingStem = IStemVesting(_stemAddress()).getPoolPendingStem(address(this));
        if (pendingStem >= minVestedStemRewarded) {
            RewardParams memory params = rewardParams;
            _rewardMember(Reward(msg.sender, RewardKind.ForStateUpdate, params.forStateUpdPoints));
        }
    }

    /// @inheritdoc IPollenDaoAdmin
    function setOwner(address newOwner) external override onlyOwner revertZeroAddress(newOwner) {
        address oldOwner = _owner;
        _owner = newOwner;
        emit NewOwner(newOwner, oldOwner);
    }

    /// @inheritdoc IPollenDaoAdmin
    function addAsset(address asset) external override onlyOwner revertZeroAddress(asset) {
        require(!_assets.contains(asset), "PollenDAO: already added");
        require(_assets.add(asset));
        emit AssetAdded(asset);
    }

    /// @inheritdoc IPollenDaoAdmin
    function removeAsset(address asset) external override onlyOwner revertZeroAddress(asset) {
        require(_assets.contains(asset), "PollenDAO: unknown asset");
        require(IERC20(asset).balanceOf(address(this)) == 0, "PollenDAO: asset has balance");
        require(_assets.remove(asset));
        emit AssetRemoved(asset);
    }

    /// @inheritdoc IPollenDaoAdmin
    function addVotingTerms(VotingTerms memory terms) external override onlyOwner {
        _addVotingTerms(terms);
    }

    /// @inheritdoc IPollenDaoAdmin
    function switchVotingTerms(
        uint256 termsId,
        bool isEnabled
    ) external override onlyOwner {
        require(termsId < _votingTermsNum, "PollenDAO: invalid termsId");
        _votingTerms[termsId].isEnabled =  isEnabled;
        emit VotingTermsSwitched(termsId, isEnabled);
    }

    /// @inheritdoc IPollenDaoAdmin
    function updatePlnWhitelist(
        address[] calldata accounts,
        bool whitelisted
    ) external override onlyOwner {
        IWhitelist(_plnAddress()).updateWhitelist(accounts, whitelisted);
    }

    /// @inheritdoc IPollenDaoAdmin
    function updateRewardParams(RewardParams memory _rewardParams) external override onlyOwner
    {
        _initRewardParams(_rewardParams);
    }

    function preventUseWithoutProxy() external initializer {
        // Prevent using the contract w/o the proxy (potentially abusing)
        // To be called on the "implementation", not on the "proxy"
        // Does not revert the first call only
    }

    function _addVotingTerms(VotingTerms memory t) internal returns(uint termsId) {
        require(t.quorum <= 100, "PollenDAO: invalid quorum");
        require(
            t.votingExpiryDelay > minDelay &&
            t.executionOpenDelay > minDelay &&
            t.executionExpiryDelay > minDelay &&
            t.votingExpiryDelay < maxDelay &&
            t.executionOpenDelay < maxDelay &&
            t.executionExpiryDelay < maxDelay,
            "PollenDAO: invalid delays"
        );
        termsId = _votingTermsNum;
        _votingTerms[termsId] = t;
        _votingTermsNum = uint16(termsId) + 1;
        emit VotingTermsSwitched(termsId, t.isEnabled);
    }

    function _initRewardParams(RewardParams memory _rewardParams) internal {
        rewardParams = _rewardParams;
        emit RewardParamsUpdated();
    }

    function _updateProposalStatus(
        uint256 proposalId,
        ProposalStatus knownNewStatus
    ) internal returns(ProposalStatus newStatus, ProposalStatus oldStatus)
    {
        ProposalState memory state = _proposals[proposalId].state;
        oldStatus = state.status;
        if (knownNewStatus != ProposalStatus.Null) {
            newStatus = knownNewStatus;
        } else {
            ProposalParams memory params = _proposals[proposalId].params;
            newStatus = _computeProposalStatus(state, params, now);
        }
        if (oldStatus != newStatus) {
            _proposals[proposalId].state.status = newStatus;
            emit StatusChanged(proposalId, newStatus, oldStatus);
        }
    }

    function _computeProposalStatus(
        ProposalState memory state,
        ProposalParams memory params,
        uint256 timeNow
    ) internal pure returns (ProposalStatus) {
        /*
         * Possible proposal status transitions:
         *
         *      +-------------=>Passed-----+  // 1st proposal only
         *      |                          |
         * Null-+=>Submitted-+->Passed-----+->Pended----+=>Executed(end)
         *                   |             |            |
         *                   +->Rejected   +->Expired   +->Expired
         *                   |
         *                   +->Expired
         *
         * Transitions triggered by this function:
         * - Submitted->(Passed || Rejected || Expired)
         * - Passed->(Pended || Expired)
         * - Pended->Expired
         *
         * Transitions triggered by other functions:
         * - Null=>Passed , for the 1st proposal only, - by the function `submit`
         * - Null=>Submitted, except for the 1st proposal - by the function `submit`
         * - Pended=>Executed - by the function `execute`
         */

        ProposalStatus curStatus = state.status;

        if (
            curStatus == ProposalStatus.Submitted &&
            timeNow >= params.votingExpiry
        ) {
            if (
                (state.yesVotes > state.noVotes) &&
                (state.yesVotes >= params.passVotes)
            ) {
                curStatus = ProposalStatus.Passed;
            } else {
                return ProposalStatus.Rejected;
            }
        }

        if (curStatus == ProposalStatus.Passed) {
            if (timeNow >= params.executionExpiry) return ProposalStatus.Expired;
            if (timeNow >= params.executionOpen) return ProposalStatus.Pended;
        }

        if (
            curStatus == ProposalStatus.Pended &&
            timeNow >= params.executionExpiry
        ) return ProposalStatus.Expired;

        return curStatus;
    }

    function _doVoteAndReward(
        uint256 proposalId,
        ProposalParams memory params,
        address voter,
        bool vote,
        uint256 numOfVotes
    )
    private {
        bool isExclPools = (params.passVotes & 1) == 1;
        if (isExclPools) _revertOnPool(voter);

        bool isNewVote = _addVote(proposalId, voter, vote, numOfVotes);
        if (!isNewVote) return;

        RewardParams memory p = rewardParams;
        Reward[2] memory rewards;
        rewards[0] = Reward(voter, RewardKind.ForVoting, p.forVotingPoints);

        if (proposalId != 0 && p.forPlnDayPoints != 0) {
            uint256 plnBalance = _getPlnBalanceAt(voter, params.snapshotId);
            uint256 secs = params.votingOpen - _proposals[proposalId - 1].params.votingOpen;
            uint256 points = plnBalance.mul(p.forPlnDayPoints)
                .mul(secs)
                .div(86400) // per day
                .div(1e18); // PLN decimals
            rewards[1] = Reward(voter, RewardKind.ForPlnHeld, points);
        }

        _rewardMembers(rewards);
    }

    /**
    * @dev _addVote (private)
    * @param proposalId The proposal ID
    * @param voter The voter address
    * @param vote The yes/no vote
    * @param numOfVotes The number of votes
    */
    function _addVote(uint256 proposalId, address voter, bool vote, uint256 numOfVotes)
    private
    returns(bool isNewVote)
    {
        ProposalState memory proposalState = _proposals[proposalId].state;

        // if voter had already voted on the proposal, and if so what his vote was.
        VoteData memory prevVote =  _voteData[voter][proposalId];
        isNewVote = prevVote.state == VoterState.Null;

        // allows to change previous vote
        if (prevVote.state == VoterState.VotedYes) {
            proposalState.yesVotes = proposalState.yesVotes.sub(prevVote.votesNum);
        } else if (prevVote.state == VoterState.VotedNo) {
            proposalState.noVotes = proposalState.noVotes.sub(prevVote.votesNum);
        }

        VoteData memory newVote;
        newVote.votesNum = numOfVotes.safe96();
        if (vote) {
            proposalState.yesVotes = proposalState.yesVotes.add(newVote.votesNum);
            newVote.state = VoterState.VotedYes;
        } else {
            proposalState.noVotes = proposalState.noVotes.add(newVote.votesNum);
            newVote.state = VoterState.VotedNo;
        }

        _proposals[proposalId].state = proposalState;
        _voteData[voter][proposalId] = newVote;
        emit VotedOn(proposalId, voter, vote, newVote.votesNum);
    }

    // Declared `virtual` for tests only
    // This should be a view function but, because ratequoter isn't, it can't be
    function _getPollenPrice() internal virtual returns(uint256 price) {
        uint256 totalVal;
        uint256 plnBal = IERC20(_plnAddress()).totalSupply();
        if (plnBal != 0) {
            // TODO: cache the price and update only if it's outdated
            IRateQuoter rateQuoter = IRateQuoter(_rateQuoterAddress());
            for (uint i; i < _assets.elements.length; i++) {
                uint256 assetBal = IERC20(_assets.elements[i]).balanceOf(address(this));
                if (assetBal == 0) continue;
                (uint256 assetRate, ) = rateQuoter.quotePrice(_assets.elements[i]);
                totalVal = totalVal.add(assetRate.mul(assetBal));
            }
            price = totalVal == 0 ? 0 : totalVal.div(plnBal);
        } else {
            price = plnInitialRate;
        }
        emit PollenPrice(price);
    }

    function _sendStemTo(address member, uint256 amount) internal override {
        IERC20(_stemAddress()).safeTransfer(member, amount);
    }

    function _getPendingRewardStem() internal view override returns(uint256 amount) {
        amount = IStemVesting(_stemAddress()).getPoolPendingStem(address(this));
    }

    // Declared `virtual` for tests only
    function _withdrawRewardStem() internal virtual override returns(uint256 amount) {
        amount = IStemVesting(_stemAddress()).withdrawPoolStem(address(this));
    }

    // Declared `virtual` for tests only
    function _takeSnapshot(
        bool isExclPools
    ) internal virtual returns (uint256 snapshotId, uint256 totalVotes) {
        {
            IPollen stem = IPollen(_stemAddress());
            uint256 plnSnapId = IPollen(_plnAddress()).snapshot();
            uint256 stmSnapId = stem.snapshot();
            snapshotId = _encodeSnapshotId(plnSnapId, stmSnapId);
            totalVotes = stem.totalSupplyAt(stmSnapId);
        }
        {
            if (isExclPools && (totalVotes != 0)) {
                totalVotes = totalVotes
                .sub(_getVotesOfAt(foundationPoolAddress, snapshotId))
                .sub(_getVotesOfAt(reservePoolAddress, snapshotId))
                .sub(_getVotesOfAt(foundersPoolAddress, snapshotId));
                // Marketing Pool ignored
            }
        }
    }

    // Declared `virtual` for tests only
    function _getVotesOfAt(
        address member,
        uint256 snapshotId
    ) internal virtual view returns(uint) {
        ( , uint256 stmSnapId) = _decodeSnapshotId(snapshotId);
        return IPollen(_stemAddress()).balanceOfAt(member, stmSnapId);
    }

    // Made `virtual` for testing only
    function _getTotalVotesAt(uint256 snapshotId) internal view  virtual returns(uint256) {
        (, uint256 stmSnapId) = _decodeSnapshotId(snapshotId);
        return IPollen(_stemAddress()).totalSupplyAt(stmSnapId);
    }

    // Made `virtual` for testing only
    function _getPlnBalanceAt(
        address member,
        uint256 snapshotId
    ) internal view  virtual returns(uint256) {
        (uint256 plnSnapId, ) = _decodeSnapshotId(snapshotId);
        return IPollen(_plnAddress()).balanceOfAt(member, plnSnapId);
    }

    // Declared `virtual` for tests only
    function _revertOnPool(address account) internal pure virtual {
        require(
            account != foundationPoolAddress &&
            account != reservePoolAddress &&
            account != marketPoolAddress &&
            account != foundersPoolAddress,
            "PollenDAO: pools not allowed"
        );
    }

    function _validateProposalId(uint256 proposalId) private view {
        require(proposalId < _proposalCount, "PollenDAO: invalid proposal id");
    }

    function _getTermSheet(uint256 termsId) private view returns(VotingTerms memory terms) {
        terms = _votingTerms[termsId];
        require(terms.quorum != 0, "PollenDAO: invalid termsId");
    }

    function _encodeSnapshotId(
        uint plnSnapId,
        uint stmSnapId
    ) private pure returns(uint256) {
        // IDs are supposed to never exceed 16 bits (2**16 - 1)
        // If two IDs are equal, no encoding applied
        if (plnSnapId == stmSnapId) return plnSnapId;
        return (plnSnapId << 16) | stmSnapId;
    }

    function _decodeSnapshotId(
        uint256 encodedId
    ) private pure returns(uint256 plnSnapId, uint256 stmSnapId) {
        // see notes to `_encodeSnapshotId` function
        if ((encodedId & 0xFFFF0000) == 0) return (encodedId, encodedId);
        plnSnapId = encodedId >> 16;
        stmSnapId = encodedId & 0xFFFF;
    }

    function _revertWrongStatus(
        ProposalStatus status,
        ProposalStatus expectedStatus
    ) private pure {
        require(status == expectedStatus, "PollenDAO: wrong proposal status");
    }

    // @dev Declared "internal virtual" for tests only
    function _plnAddress() internal pure virtual returns(address) {
        return plnTokenAddress;
    }
    function _stemAddress() internal pure virtual returns(address) {
        return stemTokenAddress;
    }
    function _rateQuoterAddress() internal pure virtual returns(address) {
        return rateQuoterAddress;
    }
}