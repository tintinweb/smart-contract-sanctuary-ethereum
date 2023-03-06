// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/*
Hitchens UnorderedKeySet v0.93

Library for managing CRUD operations in dynamic key sets.

https://github.com/rob-Hitchens/UnorderedKeySet

Copyright (c), 2019, Rob Hitchens, the MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

THIS SOFTWARE IS NOT TESTED OR AUDITED. DO NOT USE FOR PRODUCTION.
*/

library HitchensUnorderedKeySetLib {
    struct Set {
        mapping(bytes32 => uint) keyPointers;
        bytes32[] keyList;
    }

    function insert(Set storage self, bytes32 key) internal {
        require(key != 0x0, "UnorderedKeySet(100) - Key cannot be 0x0");
        require(!exists(self, key), "UnorderedKeySet(101) - Key already exists in the set.");
        self.keyList.push(key);
        self.keyPointers[key] = self.keyList.length - 1;
    }

    function remove(Set storage self, bytes32 key) internal {
        require(exists(self, key), "UnorderedKeySet(102) - Key does not exist in the set.");
        bytes32 keyToMove = self.keyList[count(self) - 1];
        uint rowToReplace = self.keyPointers[key];
        self.keyPointers[keyToMove] = rowToReplace;
        self.keyList[rowToReplace] = keyToMove;
        delete self.keyPointers[key];
        self.keyList.pop();
    }

    function count(Set storage self) internal view returns (uint) {
        return (self.keyList.length);
    }

    function exists(Set storage self, bytes32 key) internal view returns (bool) {
        if (self.keyList.length == 0) return false;
        return self.keyList[self.keyPointers[key]] == key;
    }

    function keyAtIndex(Set storage self, uint index) internal view returns (bytes32) {
        return self.keyList[index];
    }

    function nukeSet(Set storage self) public {
        delete self.keyList;
    }
}

contract HitchensUnorderedKeySet {
    using HitchensUnorderedKeySetLib for HitchensUnorderedKeySetLib.Set;
    HitchensUnorderedKeySetLib.Set set;

    event LogUpdate(address sender, string action, bytes32 key);

    function exists(bytes32 key) public view returns (bool) {
        return set.exists(key);
    }

    function insert(bytes32 key) public {
        set.insert(key);
        emit LogUpdate(msg.sender, "insert", key);
    }

    function remove(bytes32 key) public {
        set.remove(key);
        emit LogUpdate(msg.sender, "remove", key);
    }

    function count() public view returns (uint) {
        return set.count();
    }

    function keyAtIndex(uint index) public view returns (bytes32) {
        return set.keyAtIndex(index);
    }
}

//SPDX-License-Identifier: MIT

// Dev notes
// use nested mappings for post staker stake relations
// use up to 3 indexed parameters in events to better log them and make them more readable for the frontend afterwards
// revisit the gas efficiency => try to reduce the amount of storage variables / make them constant or immutable

// Complex data structures with key handling via library: https://medium.com/robhitchens/solidity-crud-epilogue-e563e794fde
// Respective GitHub Repo: https://github.com/rob-Hitchens/UnorderedKeySet

pragma solidity ^0.8.8;

import "./HitchensUnorderedKeySet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error PostCurate__PostCreationAndStakingIsNotEnabled();
error PostCurate__PostAlreadyExists(bytes32 postId);
error PostCurate__InsufficientTokenBalance();
error PostCurate__PostDoesNotExists(bytes32 _postId);
error PostCurate__StakeAmountMustBeGreaterZero();
error PostCurate__NotEnoughStakingDaysLeft();
error PostCurate__BountyAmountMustBeGreaterOrEqualZero();
error PostCurate__StakeRedeemPeriodHasNotPassed();
error PostCurate__NoRewardsBeforePostCreation();
error PostCurate__NoStakesOnThisPostByAddress();
error PostCurate__RequestedAddressHasNoStakeOnThisPost(bytes32 _postId);
error PostCurate__LessThanMinimumDaysEntered(uint256 _time);
error PostCurate__MoreThanMaximumDaysEntered();
error PostCurate__FeesMustNotBeHigher100Percent(uint256 amountAfterFeesBasisPoints);
error PostCurate__StakeAmountMustBeGreaterThresholdStake();
error PostCurate__AmountMustBeGreaterOrEqualZero();
error PostCurate__RewardAreaIsZeroOrLess(uint256 rewardArea);
error WithdrawingFundsError();

contract PostCurate {
    // Library
    using HitchensUnorderedKeySetLib for HitchensUnorderedKeySetLib.Set;
    HitchensUnorderedKeySetLib.Set private s_postSet;
    mapping(bytes32 => Post) private s_Posts;

    enum PostCurateState {
        OFF,
        ON
    }

    uint256 private s_withdrawableFees;
    uint256 private immutable i_secondsPerDay = 24 * 60 * 60;
    uint256 private i_minimumDays = 1;
    uint256 private i_maximumDays = 7;
    uint256 private s_baseFee; // base fee in basis points
    uint256 private s_thresholdStake;
    address private s_nativeTokenAddress;
    address private s_owner;
    PostCurateState private s_postCurateState;
    IERC20 private erc20Token;

    // structs
    struct Stake {
        uint256 amount; // amount of tokens staked
        uint256 stakeTimestamp; // timestamp of the stake addition
    }
    struct Staker {
        HitchensUnorderedKeySetLib.Set stakeSet;
        mapping(bytes32 => Stake) stakes;
    }
    struct Post {
        HitchensUnorderedKeySetLib.Set stakerSet;
        uint256 stakedTokens; // amount of tokens staked to this post
        uint256 bountyTokens; // amount of bounty tokens on this post
        uint256 creationTimestamp; // timestamp of the creation date
        uint256 redeemTimestamp; // timestamp of the redeem date
        uint256 stakingDays; // set the amount of days for which tokens should be staked
        address postCreator; // address that created the post
        mapping(bytes32 => Staker) stakers;
    }

    event PostCreated(
        bytes32 indexed postId,
        address indexed staker,
        uint256 indexed stake,
        uint256 bounty
    );
    event StakedToPost(
        bytes32 indexed postId,
        address indexed staker,
        uint256 indexed stake,
        uint256 bounty
    );
    event StakeAndBountyCollectedFromPost(
        bytes32 indexed postId,
        address indexed staker,
        uint256 indexed stake,
        uint256 bounty
    );
    event PostDeleted(bytes32 indexed postId, uint256 indexed timeStamp);
    event TransferredOwnership(address indexed oldAddress, address indexed newAddress);
    event ChangedBaseFee(uint256 indexed s_baseFee, uint256 indexed _baseFee);
    event ChangedThresholdStake(
        uint256 indexed oldThresholdStake,
        uint256 indexed newThresholdStake
    );
    event ChangedPostCurateState(uint256 indexed state);

    constructor(address _nativeTokenAddress, uint256 _baseFee, uint256 _thresholdStake) {
        s_owner = msg.sender;
        s_baseFee = _baseFee; // base Fee for 1 day post duration
        s_nativeTokenAddress = _nativeTokenAddress; // contract address of the native token to be considered as staking token
        s_thresholdStake = _thresholdStake;
        s_postCurateState = PostCurateState.ON;
        erc20Token = IERC20(_nativeTokenAddress);
    }

    modifier onlyOwner() {
        require(s_owner == msg.sender);
        _;
    }

    // Post Management Functions (State Changes)
    //@notice: create a new post. Post must not exist and creator must own more tokens than he wants to use for staking + bounty
    function createNewPost(
        bytes32 _postId,
        uint256 _stakeAmount,
        uint256 _bountyAmount,
        uint256 _stakingDays
    ) public payable {
        // post creation must be enabled
        if (uint(s_postCurateState) != 1) {
            revert PostCurate__PostCreationAndStakingIsNotEnabled();
        }
        // check if post already exists
        if (s_postSet.exists(_postId)) {
            revert PostCurate__PostAlreadyExists(_postId);
        }
        // check if msg.sender owns enogh tokens to stake them
        if (erc20Token.balanceOf(msg.sender) < (_stakeAmount + _bountyAmount)) {
            revert PostCurate__InsufficientTokenBalance();
        }
        // stakeAmount must be more than zero
        if (!(_stakeAmount > 0)) {
            revert PostCurate__StakeAmountMustBeGreaterZero();
        }
        if (_stakeAmount < s_thresholdStake) {
            revert PostCurate__StakeAmountMustBeGreaterThresholdStake();
        }
        // bountyAmount must be more than zero
        if (!(_bountyAmount >= 0)) {
            revert PostCurate__BountyAmountMustBeGreaterOrEqualZero();
        }
        // stakingDays must be more or equal 1
        if (_stakingDays < i_minimumDays) {
            revert PostCurate__LessThanMinimumDaysEntered(_stakingDays);
        }
        // stakingDays must be less or equal 7
        if (_stakingDays > i_maximumDays) {
            revert PostCurate__MoreThanMaximumDaysEntered();
        }

        s_postSet.insert(_postId);
        Post storage p = s_Posts[_postId];
        p.postCreator = msg.sender;
        p.creationTimestamp = block.timestamp;
        p.stakingDays = _stakingDays;
        p.redeemTimestamp = p.creationTimestamp + (p.stakingDays * i_secondsPerDay);

        stakeToPost(_postId, _stakeAmount, _bountyAmount);

        emit PostCreated(_postId, msg.sender, _stakeAmount, _bountyAmount);
    }

    // stake to existing post
    function stakeToPost(
        bytes32 _postId,
        uint256 _stakeAmount,
        uint256 _bountyAmount
    ) public payable {
        // post creation must be enabled
        if (uint(s_postCurateState) != 1) {
            revert PostCurate__PostCreationAndStakingIsNotEnabled();
        }
        if (!(s_postSet.exists(_postId))) {
            revert PostCurate__PostDoesNotExists(_postId);
        }
        if (_stakeAmount <= 0) {
            revert PostCurate__StakeAmountMustBeGreaterZero();
        }
        if (_stakeAmount < s_thresholdStake) {
            revert PostCurate__StakeAmountMustBeGreaterThresholdStake();
        }
        if (getRestStakingSecondsOfPost(_postId) < i_secondsPerDay) {
            revert PostCurate__NotEnoughStakingDaysLeft();
        }
        uint256 transferAmount = _stakeAmount + _bountyAmount;
        if (erc20Token.balanceOf(msg.sender) < (transferAmount)) {
            revert PostCurate__InsufficientTokenBalance();
        }
        bool transferSuccess = erc20Token.transferFrom(msg.sender, address(this), transferAmount);
        if (transferSuccess) {
            Post storage p = s_Posts[_postId];
            uint256 restStakingSecondsOfPost = getRestStakingSecondsOfPost(_postId);
            uint256 amountAfterFees = getAmountAfterFees(_stakeAmount, restStakingSecondsOfPost);
            uint256 bountyAmountAfterFees = getAmountAfterFees(
                _bountyAmount,
                restStakingSecondsOfPost
            );
            p.stakedTokens = p.stakedTokens + amountAfterFees;
            p.bountyTokens = p.bountyTokens + bountyAmountAfterFees;
            s_withdrawableFees = s_withdrawableFees + (_stakeAmount - amountAfterFees);
            s_withdrawableFees = s_withdrawableFees + (_bountyAmount - bountyAmountAfterFees);

            bytes32 stakerId = addressToBytes32(msg.sender);
            if (!(p.stakerSet.exists(stakerId))) {
                p.stakerSet.insert(stakerId);
            }

            Staker storage staker = p.stakers[stakerId];
            uint256 stakeCount = uint256(staker.stakeSet.count() + 1);
            bytes32 stakeId = bytes32(stakeCount);
            staker.stakeSet.insert(stakeId);
            Stake storage stake = staker.stakes[stakeId];
            stake.amount = amountAfterFees;
            stake.stakeTimestamp = block.timestamp;

            emit StakedToPost(_postId, msg.sender, _stakeAmount, _bountyAmount);
        }
    }

    // withdraw stake after redeemTimestamp has passed
    function withdrawStakeFromPost(bytes32 _postId) public {
        if (!(s_postSet.exists(_postId))) {
            revert PostCurate__PostDoesNotExists(_postId);
        }
        // check if msg.sender has a stake on the post
        if (!(getNumberOfStakesOnPostOfAddress(_postId, msg.sender) > 0)) {
            revert PostCurate__RequestedAddressHasNoStakeOnThisPost(_postId);
        }
        // check if redeem date has passed
        if (!(uint256(block.timestamp) > getRedeemTimestampOfPost(_postId))) {
            revert PostCurate__StakeRedeemPeriodHasNotPassed();
        }
        uint256 bountyOnPost = getRewardsOfAddressOnPost(
            _postId,
            msg.sender,
            getRedeemTimestampOfPost(_postId)
        );
        uint256 stakeOnPost = getStakeOnPostOfAddress(_postId, msg.sender);
        uint256 transferAmount = bountyOnPost + stakeOnPost;
        erc20Token.approve(address(this), transferAmount);
        bool transferSuccess = erc20Token.transferFrom(address(this), msg.sender, transferAmount);
        if (transferSuccess) {
            Post storage p = s_Posts[_postId];
            p.stakedTokens = getStakedTokenAmountOnPost(_postId) - stakeOnPost;
            p.bountyTokens = getBountyTokenAmountOnPost(_postId) - bountyOnPost;

            // Remove staker and stakes from post
            bytes32 stakerId = addressToBytes32(msg.sender);
            Staker storage staker = p.stakers[stakerId];
            // Remove stakes
            uint256 stakes = getNumberOfStakesOnPostOfAddress(_postId, msg.sender);
            for (uint256 i = 1; i <= stakes; i++) {
                staker.stakeSet.remove(bytes32(i));
                delete staker.stakes[bytes32(i)];
            }
            // Remove staker
            p.stakerSet.remove(stakerId);
            delete p.stakers[stakerId];

            emit StakeAndBountyCollectedFromPost(_postId, msg.sender, stakeOnPost, bountyOnPost);

            if (
                (getStakedTokenAmountOnPost(_postId) <= 0) &&
                (getBountyTokenAmountOnPost(_postId) <= 0) &&
                (getStakerAmountOnPost(_postId) <= 0)
            ) {
                deletePost(_postId);
            }
        }
    }

    //@notice: Delete Post (internal function call)
    function deletePost(bytes32 _postId) internal {
        if (!(s_postSet.exists(_postId))) {
            revert PostCurate__PostDoesNotExists(_postId);
        }
        // check if redeem date has passed
        if (!(uint256(block.timestamp) > getRedeemTimestampOfPost(_postId))) {
            revert PostCurate__StakeRedeemPeriodHasNotPassed();
        }
        s_postSet.remove(_postId);
        delete s_Posts[_postId];

        emit PostDeleted(_postId, block.timestamp);
    }

    // Environmental Parameter State Change Functions
    //@notice: transfers ownership of the contract
    function transferOwnership(address _newOwner) public onlyOwner {
        s_owner = _newOwner;
        emit TransferredOwnership(msg.sender, s_owner);
    }

    //@notice: changes the baseFee, used in the getFeeForStake function
    function setBaseFee(uint256 _baseFee) public onlyOwner {
        if (_baseFee < 0) {
            emit ChangedBaseFee(s_baseFee, 0);
            s_baseFee = 0;
        } else if (_baseFee > 5000) {
            emit ChangedBaseFee(s_baseFee, 5000);
            s_baseFee = 5000;
        } else {
            emit ChangedBaseFee(s_baseFee, _baseFee);
            s_baseFee = _baseFee;
        }
    }

    //@notice: changes the thresholdStake to have set a minimum of tokens necessary to stake to a post
    function setThresholdStake(uint256 _thresholdStake) public onlyOwner {
        if (_thresholdStake < 0) {
            emit ChangedThresholdStake(s_thresholdStake, 0);
            s_thresholdStake = 0;
        } else {
            emit ChangedThresholdStake(s_thresholdStake, _thresholdStake);
            s_thresholdStake = _thresholdStake;
        }
    }

    //@notice: enable new post creation and staking on platform
    function enablePostCurate() public {
        emit ChangedPostCurateState(1);
        s_postCurateState = PostCurateState.ON;
    }

    //@notice: disable new post creation and staking on platform
    function disablePostCurate() public {
        emit ChangedPostCurateState(0);
        s_postCurateState = PostCurateState.OFF;
    }

    //@notice: Withdraw collected fees in the smart contract
    function withdrawFees() public onlyOwner {
        bool transferSuccess = erc20Token.transferFrom(
            address(this),
            msg.sender,
            s_withdrawableFees
        );
        if (!transferSuccess) {
            revert WithdrawingFundsError();
        }
    }

    // Get Functions
    // get staker amount on post
    function getStakerAmountOnPost(bytes32 _postId) public view returns (uint256) {
        return uint256(s_Posts[_postId].stakerSet.count());
    }

    function getStakerIdByIndexOnPost(
        bytes32 _postId,
        uint256 _stakerIndex
    ) public view returns (address) {
        return bytes32ToAddress(s_Posts[_postId].stakerSet.keyAtIndex(_stakerIndex));
    }

    function getStakerIdByIndexOnPostBytes(
        bytes32 _postId,
        uint256 _stakerIndex
    ) public view returns (bytes32) {
        return s_Posts[_postId].stakerSet.keyAtIndex(_stakerIndex);
    }

    // get staked tokens amount on post
    function getStakedTokenAmountOnPost(bytes32 _postId) public view returns (uint256) {
        return uint256(s_Posts[_postId].stakedTokens);
    }

    // get bounty tokens amount on post
    function getBountyTokenAmountOnPost(bytes32 _postId) public view returns (uint256) {
        return uint256(s_Posts[_postId].bountyTokens);
    }

    // get redeem timestamp
    function getRedeemTimestampOfPost(bytes32 _postId) public view returns (uint256) {
        return s_Posts[_postId].redeemTimestamp;
    }

    // get creation timestamp
    function getCreationTimestampOfPost(bytes32 _postId) public view returns (uint256) {
        return s_Posts[_postId].creationTimestamp;
    }

    function getPostCreator(bytes32 _postId) public view returns (address) {
        return s_Posts[_postId].postCreator;
    }

    function getWithdrawableFees() public view onlyOwner returns (uint256) {
        return s_withdrawableFees;
    }

    //@notice: calculate the amount of fees in base points to be paid by the staker
    //@notice: provide _time in seconds
    function getFeeForStake(uint256 _time) public view returns (uint256) {
        if (_time < (i_minimumDays * i_secondsPerDay)) {
            revert PostCurate__LessThanMinimumDaysEntered(_time);
        }
        // _time must be less or equal 7
        if (_time > (i_maximumDays * i_secondsPerDay)) {
            revert PostCurate__MoreThanMaximumDaysEntered();
        }

        uint256 feePoints = 100;
        if (_time >= (7 * i_secondsPerDay)) {
            feePoints = 43;
        } else if (_time >= (6 * i_secondsPerDay)) {
            feePoints = 46;
        } else if (_time >= (5 * i_secondsPerDay)) {
            feePoints = 50;
        } else if (_time >= (4 * i_secondsPerDay)) {
            feePoints = 55;
        } else if (_time >= (3 * i_secondsPerDay)) {
            feePoints = 62;
        } else if (_time >= (2 * i_secondsPerDay)) {
            feePoints = 74;
        }
        uint256 fees = ((feePoints * ((_time * 100) / i_secondsPerDay)) * s_baseFee) / (100 * 100);
        return fees;
    }

    //calculate amount after fees
    //@notice: provide _time in seconds
    function getAmountAfterFees(uint256 _amount, uint256 _time) public view returns (uint256) {
        if (_amount < 0) {
            revert PostCurate__AmountMustBeGreaterOrEqualZero();
        }
        if (_time < (i_minimumDays * i_secondsPerDay)) {
            revert PostCurate__LessThanMinimumDaysEntered(_time);
        }
        // _time must be less or equal 7
        if (_time > (i_maximumDays * i_secondsPerDay)) {
            revert PostCurate__MoreThanMaximumDaysEntered();
        }
        uint256 amountAfterFeesBasisPoints = (100 * 100 - getFeeForStake(_time));
        if (amountAfterFeesBasisPoints < 0) {
            revert PostCurate__FeesMustNotBeHigher100Percent(amountAfterFeesBasisPoints);
        }
        return ((_amount * amountAfterFeesBasisPoints) / (100 * 100));
    }

    // get amount of stakes on post of address
    function getNumberOfStakesOnPostOfAddress(
        bytes32 _postId,
        address _stakerAddress
    ) public view returns (uint256) {
        return uint256(s_Posts[_postId].stakers[addressToBytes32(_stakerAddress)].stakeSet.count());
    }

    // get amount tokens staked on a given post for a given staker address
    function getStakeOnPostOfAddress(
        bytes32 _postId,
        address _stakerAddress
    ) public view returns (uint256) {
        uint256 n_stakes = getNumberOfStakesOnPostOfAddress(_postId, _stakerAddress);
        if (n_stakes <= 0) {
            return 0;
        } else {
            uint256 stake = 0;
            for (uint256 i = 1; i <= n_stakes; i++) {
                stake =
                    stake +
                    s_Posts[_postId]
                        .stakers[addressToBytes32(_stakerAddress)]
                        .stakes[bytes32(i)]
                        .amount;
            }
            return stake;
        }
    }

    function getRewardsOfAddressOnPost(
        bytes32 _postId,
        address _stakerAddress,
        uint256 _timeStamp
    ) public view returns (uint256) {
        if (!(s_postSet.exists(_postId))) {
            revert PostCurate__PostDoesNotExists(_postId);
        }
        if (_timeStamp < getCreationTimestampOfPost(_postId)) {
            revert PostCurate__NoRewardsBeforePostCreation();
        }
        if (getNumberOfStakesOnPostOfAddress(_postId, _stakerAddress) <= 0) {
            revert PostCurate__NoStakesOnThisPostByAddress();
        }
        Post storage p = s_Posts[_postId];
        uint256 rewardArea = 0; // sum of all individual stakes times the time they have been staked
        uint256 stakerStakeArea = 0; // sum of all stakes times the time they have been staked for the _stakerAddress
        uint256 t = getRedeemTimestampOfPost(_postId);
        if (_timeStamp < t) {
            t = _timeStamp;
        }
        for (uint256 i = 0; i < getStakerAmountOnPost(_postId); i++) {
            bytes32 stakerId = p.stakerSet.keyAtIndex(i);
            Staker storage staker = p.stakers[stakerId];
            uint256 stakeCount = staker.stakeSet.count();
            for (uint256 j = 1; j <= stakeCount; j++) {
                Stake storage stake = staker.stakes[bytes32(j)];
                uint256 stakerStakeArea_i = (stake.amount) * ((t - stake.stakeTimestamp));
                rewardArea = rewardArea + stakerStakeArea_i;
                if (bytes32ToAddress(stakerId) == _stakerAddress) {
                    stakerStakeArea = stakerStakeArea + stakerStakeArea_i;
                }
            }
        }
        if (rewardArea <= 0) {
            revert PostCurate__RewardAreaIsZeroOrLess(rewardArea);
        }
        return
            (((stakerStakeArea * 10000) / rewardArea) *
                getBountyTokenAmountOnPost(_postId) *
                (((t - getCreationTimestampOfPost(_postId)) * 10000) /
                    (getRedeemTimestampOfPost(_postId) - getCreationTimestampOfPost(_postId)))) /
            (10000 * 10000);
    }

    function getNativeTokenAddress() public view returns (address) {
        return s_nativeTokenAddress;
    }

    function getBaseFee() public view returns (uint256) {
        return s_baseFee;
    }

    function getThresholdStake() public view returns (uint256) {
        return s_thresholdStake;
    }

    function getPostIdByIndex(uint256 _postIndex) public view returns (string memory) {
        return bytes32ToString(s_postSet.keyAtIndex(_postIndex));
    }

    function getPostIdByIndexBytes(uint256 _postIndex) public view returns (bytes32) {
        return s_postSet.keyAtIndex(_postIndex);
    }

    function getPostAmount() public view returns (uint256) {
        return uint256(s_postSet.count());
    }

    function getRestStakingSecondsOfPost(bytes32 _postId) public view returns (uint256) {
        if (getRedeemTimestampOfPost(_postId) <= block.timestamp) {
            return 0;
        } else {
            return uint256(getRedeemTimestampOfPost(_postId) - block.timestamp);
        }
    }

    function getMinimumDays() public view returns (uint256) {
        return i_minimumDays;
    }

    function getMaximumDays() public view returns (uint256) {
        return i_maximumDays;
    }

    function getPostCurateState() public view returns (PostCurateState) {
        return s_postCurateState;
    }

    // Conversion Functions
    function addressToBytes32(address a) public pure returns (bytes32) {
        return bytes32(uint(uint160(a)));
    }

    function bytes32ToAddress(bytes32 b) public pure returns (address) {
        return address(uint160(uint(b)));
    }

    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
        assembly {
            result := mload(add(source, 32))
        }
    }

    function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
        uint8 i = 0;
        while (i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }
}