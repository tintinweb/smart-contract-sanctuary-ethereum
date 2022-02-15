pragma solidity ^0.8.4;

import "../AavePool.sol";
import "../interfaces/IAavePool.sol";
import "../interfaces/Aave/IAaveGovernanceV2.sol";

contract AaveVoteResolver {
    function checker(AavePool aavePool, IAaveGovernanceV2 aaveGovernance)
        external
        view
        returns (bool canExec, bytes memory execPayload)
    {
        uint256 counts = aaveGovernance.getProposalsCount();
        for (uint256 i = 0; i <= counts; i++) {
            (
                uint256 totalVotes,
                uint256 proposalStartBlock,
                uint128 highestBid,
                uint64 endTime,
                bool support,
                bool voted,
                address highestBidder
            ) = aavePool.bids(i);
            IAaveGovernanceV2.ProposalWithoutVotes memory p = aaveGovernance.getProposalById(i);
            canExec =
                p.endBlock > block.number &&
                !p.executed &&
                !p.canceled &&
                !voted &&
                block.timestamp > endTime;
            execPayload = abi.encodeWithSelector(AavePool.vote.selector, i);
            if (canExec) break;
        }
    }
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IAaveGovernanceV2} from "./interfaces/Aave/IAaveGovernanceV2.sol";
import {IGovernanceStrategy} from "./interfaces/Aave/IGovernanceStrategy.sol";
import {IExecutorWithTimelock} from "./interfaces/Aave/IExecutorWithTimelock.sol";
import "./interfaces/IAavePool.sol";
import "./interfaces/IWrapperToken.sol";
import "./interfaces/Aave/IStakedAave.sol";
import "./interfaces/IERC20Details.sol";
import "./interfaces/IBribeExecutor.sol";
import "./BribePoolBase.sol";

////////////////////////////////////////////////////////////////////////////////////////////
///
/// @title AavePool
/// @author [email protected]
/// @notice
///
////////////////////////////////////////////////////////////////////////////////////////////

contract AavePool is BribePoolBase, IAavePool, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeCast for uint256;

    /// @dev share scale
    uint256 private constant SHARE_SCALE = 1e12;

    /// @dev maximum claim iterations
    uint64 internal constant MAX_CLAIM_ITERATIONS = 10;

    /// @dev fee precision
    uint64 internal constant FEE_PRECISION = 10000;

    /// @dev fee percentage share is 16%
    uint128 internal constant FEE_PERCENTAGE = 1600;

    /// @dev seconds per block
    uint64 internal constant secondPerBlock = 13;

    /// @dev aave governance
    IAaveGovernanceV2 public immutable aaveGovernance;

    /// @dev bidders will bid with bidAsset e.g. usdc
    IERC20 public immutable bidAsset;

    /// @dev bribe token
    IERC20 public immutable bribeToken;

    /// @dev aave token
    IERC20 public immutable aaveToken;

    /// @dev stkAave token
    IERC20 public immutable stkAaveToken;

    /// @dev aave wrapper token
    IWrapperToken public immutable wrapperAaveToken;

    /// @dev stkAave wrapper token
    IWrapperToken public immutable wrapperStkAaveToken;

    /// @dev feeReceipient address to send received fees to
    address public feeReceipient;

    /// @dev pending rewards to be distributed
    uint128 internal pendingRewardToBeDistributed;

    /// @dev fees received
    uint128 public feesReceived;

    /// @dev asset index
    AssetIndex public assetIndex;

    /// @dev bribre reward config
    BribeReward public bribeRewardConfig;

    /// @dev bid id to bid information
    mapping(uint256 => Bid) public bids;

    /// @dev blocked proposals
    mapping(uint256 => bool) public blockedProposals;

    /// @dev proposal id to bid information
    mapping(uint256 => uint256) internal bidIdToProposalId;

    /// @dev user info
    mapping(address => UserInfo) internal users;

    constructor(
        address bribeToken_,
        address aaveToken_,
        address stkAaveToken_,
        address bidAsset_,
        address aave_,
        address feeReceipient_,
        IWrapperToken wrapperAaveToken_,
        IWrapperToken wrapperStkAaveToken_,
        BribeReward memory rewardConfig_
    ) BribePoolBase() {
        require(bribeToken_ != address(0), "BRIBE_TOKEN");
        require(aaveToken_ != address(0), "AAVE_TOKEN");
        require(stkAaveToken_ != address(0), "STKAAVE_TOKEN");
        require(aave_ != address(0), "AAVE_GOVERNANCE");
        require(address(bidAsset_) != address(0), "BID_ASSET");
        require(feeReceipient_ != address(0), "FEE_RECEIPIENT");
        require(address(wrapperAaveToken_) != address(0), "AAVE_WRAPPER");
        require(address(wrapperStkAaveToken_) != address(0), "STK_WRAPPER");

        bribeToken = IERC20(bribeToken_);
        aaveToken = IERC20(aaveToken_);
        stkAaveToken = IERC20(stkAaveToken_);
        aaveGovernance = IAaveGovernanceV2(aave_);
        bidAsset = IERC20(bidAsset_);
        bribeRewardConfig = rewardConfig_;
        feeReceipient = feeReceipient_;

        // initialize wrapper tokens
        wrapperAaveToken_.initialize(aaveToken_);
        wrapperStkAaveToken_.initialize(stkAaveToken_);

        wrapperAaveToken = wrapperAaveToken_;
        wrapperStkAaveToken = wrapperStkAaveToken_;
    }

    /// @notice deposit
    /// @param asset either Aave or stkAave
    /// @param recipient address to mint the receipt tokens
    /// @param amount amount of tokens to deposit
    /// @param claim claim stk aave rewards from Aave
    function deposit(
        IERC20 asset,
        address recipient,
        uint128 amount,
        bool claim
    ) external override whenNotPaused nonReentrant {
        if (asset == aaveToken) {
            _deposit(asset, wrapperAaveToken, recipient, amount, claim);
        } else {
            _deposit(stkAaveToken, wrapperStkAaveToken, recipient, amount, claim);
        }
    }

    /// @notice withdraw
    /// @param asset either Aave or stkAave
    /// @param recipient address to mint the receipt tokens
    /// @param amount amount of tokens to deposit
    /// @param claim claim stk aave rewards from Aave
    function withdraw(
        IERC20 asset,
        address recipient,
        uint128 amount,
        bool claim
    ) external override nonReentrant {
        if (asset == aaveToken) {
            _withdraw(asset, wrapperAaveToken, recipient, amount, claim);
        } else {
            _withdraw(stkAaveToken, wrapperStkAaveToken, recipient, amount, claim);
        }
    }

    /// @dev vote to `proposalId` with `support` option
    /// @param proposalId proposal id
    function vote(uint256 proposalId) external nonReentrant {
        Bid storage currentBid = bids[proposalId];

        require(currentBid.endTime > 0, "INVALID_PROPOSAL");
        require(currentBid.endTime < block.timestamp, "BID_ACTIVE");

        distributeRewards(proposalId);

        IAaveGovernanceV2(aaveGovernance).submitVote(proposalId, currentBid.support);

        emit Vote(proposalId, msg.sender, currentBid.support, block.timestamp);
    }

    /// @dev place a bid after check AaveGovernance status
    /// @param bidder bidder address
    /// @param proposalId proposal id
    /// @param amount amount of bid assets
    /// @param support the suport for the proposal
    function bid(
        address bidder,
        uint256 proposalId,
        uint128 amount,
        bool support
    ) external override whenNotPaused nonReentrant {
        IAaveGovernanceV2.ProposalState state = IAaveGovernanceV2(aaveGovernance).getProposalState(
            proposalId
        );
        require(
            state == IAaveGovernanceV2.ProposalState.Pending ||
                state == IAaveGovernanceV2.ProposalState.Active,
            "INVALID_PROPOSAL_STATE"
        );

        require(blockedProposals[proposalId] == false, "PROPOSAL_BLOCKED");

        Bid storage currentBid = bids[proposalId];
        address prevHighestBidder = currentBid.highestBidder;
        uint128 currentHighestBid = currentBid.highestBid;
        uint128 newHighestBid;

        // new bid
        if (prevHighestBidder == address(0)) {
            uint64 endTime = uint64(_getAuctionExpiration(proposalId));
            currentBid.endTime = endTime;
            currentBid.totalVotes = votingPower(proposalId);
            currentBid.proposalStartBlock = IAaveGovernanceV2(aaveGovernance)
                .getProposalById(proposalId)
                .startBlock;
        }

        require(currentBid.endTime > block.timestamp, "BID_ENDED");
        require(currentBid.totalVotes > 0, "INVALID_VOTING_POWER");

        // if bidder == currentHighestBidder increase the bid amount
        if (prevHighestBidder == bidder) {
            bidAsset.safeTransferFrom(msg.sender, address(this), amount);

            newHighestBid = currentHighestBid + amount;
        } else {
            require(amount > currentHighestBid, "LOW_BID");

            bidAsset.safeTransferFrom(msg.sender, address(this), amount);

            // refund to previous highest bidder
            if (prevHighestBidder != address(0)) {
                pendingRewardToBeDistributed -= currentHighestBid;
                bidAsset.safeTransfer(prevHighestBidder, currentHighestBid);
            }

            newHighestBid = amount;
        }

        // write the new bid info to storage
        pendingRewardToBeDistributed += amount;
        currentBid.highestBid = newHighestBid;
        currentBid.support = support;
        currentBid.highestBidder = bidder;

        emit HighestBidIncreased(
            proposalId,
            prevHighestBidder,
            bidder,
            msg.sender,
            newHighestBid,
            support
        );
    }

    /// @dev refund bid for a cancelled proposal ONLY if it was not voted on
    /// @param proposalId proposal id
    function refund(uint256 proposalId) external nonReentrant {
        IAaveGovernanceV2.ProposalState state = IAaveGovernanceV2(aaveGovernance).getProposalState(
            proposalId
        );

        require(state == IAaveGovernanceV2.ProposalState.Canceled, "PROPOSAL_ACTIVE");

        Bid storage currentBid = bids[proposalId];
        uint128 highestBid = currentBid.highestBid;
        address highestBidder = currentBid.highestBidder;

        // we do not refund if no high bid or if the proposal has been voted on
        if (highestBid == 0 || currentBid.voted) return;

        // reset the bid proposal state
        delete bids[proposalId];

        // refund the bid money
        pendingRewardToBeDistributed -= highestBid;
        bidAsset.safeTransfer(highestBidder, highestBid);

        emit Refund(proposalId, highestBidder, highestBid);
    }

    /// @dev distribute rewards for the proposal
    /// @notice called in children's vote function (after bidding process ended)
    /// @param proposalId id of proposal to distribute rewards fo
    function distributeRewards(uint256 proposalId) public {
        Bid storage currentBid = bids[proposalId];

        // ensure that the bidding period has ended
        require(block.timestamp > currentBid.endTime, "BID_ACTIVE");

        if (currentBid.voted) return;

        uint128 highestBid = currentBid.highestBid;
        uint128 feeAmount = _calculateFeeAmount(highestBid);

        // reduce pending reward
        pendingRewardToBeDistributed -= highestBid;
        assetIndex.bidIndex += (highestBid - feeAmount);
        feesReceived += feeAmount;
        currentBid.voted = true;
        // rewrite the highest bid minus fee
        // set and increase the bid id
        bidIdToProposalId[assetIndex.bidId] = proposalId;
        assetIndex.bidId += 1;

        emit RewardDistributed(proposalId, highestBid);
    }

    /// @dev withdrawFees withdraw fees
    /// Enables ONLY the fee receipient to withdraw the pool accrued fees
    function withdrawFees() external override nonReentrant returns (uint256 feeAmount) {
        require(msg.sender == feeReceipient, "ONLY_RECEIPIENT");

        feeAmount = feesReceived;

        if (feeAmount > 0) {
            feesReceived = 0;
            bidAsset.safeTransfer(feeReceipient, feeAmount);
        }

        emit WithdrawFees(address(this), feeAmount, block.timestamp);
    }

    /// @dev get reward amount for user specified by `user`
    /// @param user address of user to check balance of
    function rewardBalanceOf(address user)
        external
        view
        returns (
            uint256 totalPendingBidReward,
            uint256 totalPendingStkAaveReward,
            uint256 totalPendingBribeReward
        )
    {
        uint256 userAaveBalance = wrapperAaveToken.balanceOf(user);
        uint256 userStkAaveBalance = wrapperStkAaveToken.balanceOf(user);
        uint256 pendingBribeReward = _userPendingBribeReward(
            userAaveBalance + userStkAaveBalance,
            users[user].bribeLastRewardPerShare,
            _calculateBribeRewardPerShare(_calculateBribeRewardIndex())
        );

        uint256 pendingBidReward;

        uint256 currentBidRewardCount = assetIndex.bidId;

        if (userAaveBalance > 0) {
            pendingBidReward += _calculateUserPendingBidRewards(
                wrapperAaveToken,
                user,
                users[user].aaveLastBidId,
                currentBidRewardCount
            );
        }

        if (userStkAaveBalance > 0) {
            pendingBidReward += _calculateUserPendingBidRewards(
                wrapperStkAaveToken,
                user,
                users[user].stkAaveLastBidId,
                currentBidRewardCount
            );
        }

        totalPendingBidReward = users[user].totalPendingBidReward + pendingBidReward;
        (uint128 rewardsToReceive, ) = _stkAaveRewardsToReceive();

        totalPendingStkAaveReward =
            users[user].totalPendingStkAaveReward +
            _userPendingstkAaveRewards(
                user,
                users[user].stkAaveLastRewardPerShare,
                _calculateStkAaveRewardPerShare(rewardsToReceive),
                wrapperStkAaveToken
            );
        totalPendingBribeReward = users[user].totalPendingBribeReward + pendingBribeReward;
    }

    /// @dev claimReward for msg.sender
    /// @param to address to send the rewards to
    /// @param executor An external contract to call with
    /// @param data data to call the executor contract
    /// @param claim claim stk aave rewards from Aave
    function claimReward(
        address to,
        IBribeExecutor executor,
        bytes calldata data,
        bool claim
    ) external whenNotPaused nonReentrant {
        // accrue rewards for both stkAave and Aave token balances
        _accrueRewards(msg.sender, claim);

        UserInfo storage _currentUser = users[msg.sender];

        uint128 pendingBid = _currentUser.totalPendingBidReward;
        uint128 pendingStkAaveReward = _currentUser.totalPendingStkAaveReward;
        uint128 pendingBribeReward = _currentUser.totalPendingBribeReward;

        unchecked {
            // reset the reward calculation
            _currentUser.totalPendingBidReward = 0;
            _currentUser.totalPendingStkAaveReward = 0;
            // update lastStkAaveRewardBalance
            assetIndex.lastStkAaveRewardBalance -= pendingStkAaveReward;
        }

        if (pendingBid > 0) {
            bidAsset.safeTransfer(to, pendingBid);
        }

        if (pendingStkAaveReward > 0 && claim) {
            // claim stk aave rewards
            IStakedAave(address(stkAaveToken)).claimRewards(to, pendingStkAaveReward);
        }

        if (pendingBribeReward > 0 && bribeToken.balanceOf(address(this)) > pendingBribeReward) {
            _currentUser.totalPendingBribeReward = 0;

            if (address(executor) != address(0)) {
                bribeToken.safeTransfer(address(executor), pendingBribeReward);
                executor.execute(msg.sender, pendingBribeReward, data);
            } else {
                require(to != address(0), "INVALID_ADDRESS");
                bribeToken.safeTransfer(to, pendingBribeReward);
            }
        }

        emit RewardClaim(
            msg.sender,
            pendingBid,
            pendingStkAaveReward,
            pendingBribeReward,
            block.timestamp
        );
    }

    /// @dev block a proposalId from used in the pool
    /// @param proposalId proposalId
    function blockProposalId(uint256 proposalId) external onlyOwner {
        require(blockedProposals[proposalId] == false, "PROPOSAL_INACTIVE");
        Bid storage currentBid = bids[proposalId];

        // check if the propoal has already been voted on
        require(currentBid.voted == false, "BID_DISTRIBUTED");

        blockedProposals[proposalId] = true;

        uint128 highestBid = currentBid.highestBid;

        // check if the proposalId has any bids
        // if there is any current highest bidder
        // and the reward has not been distributed refund the bidder
        if (highestBid > 0) {
            pendingRewardToBeDistributed -= highestBid;
            address highestBidder = currentBid.highestBidder;
            // reset the bids
            delete bids[proposalId];
            bidAsset.safeTransfer(highestBidder, highestBid);
        }

        emit BlockProposalId(proposalId, block.timestamp);
    }

    /// @dev unblock a proposalId from used in the pool
    /// @param proposalId proposalId
    function unblockProposalId(uint256 proposalId) external onlyOwner {
        require(blockedProposals[proposalId] == true, "PROPOSAL_ACTIVE");

        blockedProposals[proposalId] = false;

        emit UnblockProposalId(proposalId, block.timestamp);
    }

    /// @dev returns the pool voting power for a proposal
    /// @param proposalId proposalId to fetch pool voting power
    function votingPower(uint256 proposalId) public view returns (uint256 power) {
        IAaveGovernanceV2.ProposalWithoutVotes memory proposal = IAaveGovernanceV2(aaveGovernance)
            .getProposalById(proposalId);
        address governanceStrategy = IAaveGovernanceV2(aaveGovernance).getGovernanceStrategy();
        power = IGovernanceStrategy(governanceStrategy).getVotingPowerAt(
            address(this),
            proposal.startBlock
        );
    }

    /// @dev getPendingRewardToBeDistributed returns the pending reward to be distributed
    /// minus fees
    function getPendingRewardToBeDistributed() external view returns (uint256 pendingReward) {
        pendingReward =
            pendingRewardToBeDistributed -
            _calculateFeeAmount(pendingRewardToBeDistributed);
    }

    /// @notice pause pool actions
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice unpause pool actions
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice setFeeRecipient
    /// @param newReceipient new fee receipeitn
    function setFeeRecipient(address newReceipient) external onlyOwner {
        require(newReceipient != address(0), "INVALID_RECIPIENT");

        feeReceipient = newReceipient;

        emit UpdateFeeRecipient(address(this), newReceipient);
    }

    /// @notice setStartTimestamp
    /// @param startTimestamp when to start distributing rewards
    /// @param rewardPerSecond reward to distribute per second
    function setStartTimestamp(uint64 startTimestamp, uint128 rewardPerSecond) external onlyOwner {
        require(startTimestamp > block.timestamp, "INVALID_START_TIMESTAMP");
        if (bribeRewardConfig.endTimestamp != 0) {
            require(startTimestamp < bribeRewardConfig.endTimestamp, "HIGH_TIMESTAMP");
        }

        _updateBribeRewardIndex();

        uint64 oldTimestamp = bribeRewardConfig.startTimestamp;
        bribeRewardConfig.startTimestamp = startTimestamp;

        _setRewardPerSecond(rewardPerSecond);

        emit SetBribeRewardStartTimestamp(oldTimestamp, startTimestamp);
    }

    /// @notice setEndTimestamp
    /// @param endTimestamp end of bribe rewards
    function setEndTimestamp(uint64 endTimestamp) external onlyOwner {
        require(endTimestamp > block.timestamp, "INVALID_END_TIMESTAMP");
        require(endTimestamp > bribeRewardConfig.startTimestamp, "LOW_TIMESTAMP");

        _updateBribeRewardIndex();

        uint64 oldTimestamp = bribeRewardConfig.endTimestamp;
        bribeRewardConfig.endTimestamp = endTimestamp;

        emit SetBribeRewardEndTimestamp(oldTimestamp, endTimestamp);
    }

    /// @notice setEndTimestamp
    /// @param rewardPerSecond amount of rewards to distribute per second
    function setRewardPerSecond(uint128 rewardPerSecond) public onlyOwner {
        _updateBribeRewardIndex();
        _setRewardPerSecond(rewardPerSecond);
    }

    function _setRewardPerSecond(uint128 rewardPerSecond) internal {
        require(rewardPerSecond > 0, "INVALID_REWARD_SECOND");

        uint128 oldReward = bribeRewardConfig.rewardAmountDistributedPerSecond;

        bribeRewardConfig.rewardAmountDistributedPerSecond = rewardPerSecond;

        emit SetBribeRewardPerSecond(oldReward, rewardPerSecond);
    }

    /// @notice withdrawRemainingBribeReward
    /// @dev there is a 30 days window period after endTimestamp where a user can claim
    /// rewards before it can be reclaimed by Bribe
    function withdrawRemainingBribeReward() external onlyOwner {
        require(bribeRewardConfig.endTimestamp != 0, "INVALID_END_TIMESTAMP");
        require(block.timestamp > bribeRewardConfig.endTimestamp + 30 days, "GRACE_PERIOD");

        uint256 remaining = bribeToken.balanceOf(address(this));

        bribeToken.safeTransfer(address(this), remaining);

        emit WithdrawRemainingReward(remaining);
    }

    /// Create proposal on Aave
    /// @dev Creates a Proposal (needs to be validated by the Proposal Validator)
    /// @param executor The ExecutorWithTimelock contract that will execute the proposal
    /// @param targets list of contracts called by proposal's associated transactions
    /// @param values list of value in wei for each propoposal's associated transaction
    /// @param signatures list of function signatures (can be empty) to be used when created the callData
    /// @param calldatas list of calldatas: if associated signature empty, calldata ready, else calldata is arguments
    /// @param withDelegatecalls boolean, true = transaction delegatecalls the taget, else calls the target
    /// @param ipfsHash IPFS hash of the proposal
    function createProposal(
        IExecutorWithTimelock executor,
        address[] calldata targets,
        uint256[] calldata values,
        string[] calldata signatures,
        bytes[] calldata calldatas,
        bool[] calldata withDelegatecalls,
        bytes32 ipfsHash
    ) external onlyOwner returns (uint256 proposalId) {
        proposalId = aaveGovernance.create(
            executor,
            targets,
            values,
            signatures,
            calldatas,
            withDelegatecalls,
            ipfsHash
        );

        emit CreatedProposal(proposalId);
    }

    /// @dev  _calculateFeeAmount calculate the fee percentage share
    function _calculateFeeAmount(uint128 amount) internal pure returns (uint128 feeAmount) {
        feeAmount = (amount * FEE_PERCENTAGE) / FEE_PRECISION;
    }

    struct NewUserRewardInfoLocalVars {
        uint256 pendingBidReward;
        uint256 pendingstkAaveReward;
        uint256 pendingBribeReward;
        uint256 newUserAaveBidId;
        uint256 newUserStAaveBidId;
    }

    /// @dev _accrueRewards accrue rewards for an address
    /// @param user address to accrue rewards for
    /// @param claim claim pending stk aave rewards
    function _accrueRewards(address user, bool claim) internal {
        require(user != address(0), "INVALID_ADDRESS");

        UserInfo storage _user = users[user];

        NewUserRewardInfoLocalVars memory userRewardVars;

        uint256 userAaveBalance = wrapperAaveToken.balanceOf(user);
        uint256 userStkAaveBalance = wrapperStkAaveToken.balanceOf(user);
        uint256 total = userAaveBalance + userStkAaveBalance;

        // update bribe reward index
        _updateBribeRewardIndex();

        if (total > 0) {
            // calculate updated bribe rewards
            userRewardVars.pendingBribeReward = _userPendingBribeReward(
                total,
                _user.bribeLastRewardPerShare,
                assetIndex.bribeRewardPerShare
            );
        }

        if (userAaveBalance > 0) {
            // calculate pendingBidRewards
            uint256 reward;
            (userRewardVars.newUserAaveBidId, reward) = _userPendingBidRewards(
                assetIndex.bidIndex,
                wrapperAaveToken,
                user,
                users[user].aaveLastBidId
            );
            userRewardVars.pendingBidReward += reward;
        }

        if (claim) {
            _updateStkAaveStakeReward();
        }

        if (userStkAaveBalance > 0) {
            // calculate pendingBidRewards
            uint256 reward;
            (userRewardVars.newUserStAaveBidId, reward) = _userPendingBidRewards(
                assetIndex.bidIndex,
                wrapperStkAaveToken,
                user,
                users[user].stkAaveLastBidId
            );
            userRewardVars.pendingBidReward += reward;

            // distribute stkAaveTokenRewards to the user too
            userRewardVars.pendingstkAaveReward = _userPendingstkAaveRewards(
                user,
                users[user].stkAaveLastRewardPerShare,
                assetIndex.stkAaveRewardPerShare,
                wrapperStkAaveToken
            );
        }

        // write to storage
        _user.totalPendingBribeReward += userRewardVars.pendingBribeReward.toUint128();
        _user.totalPendingBidReward += userRewardVars.pendingBidReward.toUint128();
        _user.totalPendingStkAaveReward += userRewardVars.pendingstkAaveReward.toUint128();
        _user.stkAaveLastRewardPerShare = assetIndex.stkAaveRewardPerShare;
        _user.bribeLastRewardPerShare = assetIndex.bribeRewardPerShare;
        _user.aaveLastBidId = userRewardVars.newUserAaveBidId.toUint128();
        _user.stkAaveLastBidId = userRewardVars.newUserStAaveBidId.toUint128();

        emit RewardAccrue(
            user,
            userRewardVars.pendingBidReward,
            userRewardVars.pendingstkAaveReward,
            userRewardVars.pendingBribeReward,
            block.timestamp
        );
    }

    /// @dev deposit governance token
    /// @param asset asset to withdraw
    /// @param receiptToken asset wrapper token
    /// @param recipient address to award the receipt tokens
    /// @param amount amount to deposit
    /// @param claim claim pending stk aave rewards
    /// @notice emit {Deposit} event
    function _deposit(
        IERC20 asset,
        IWrapperToken receiptToken,
        address recipient,
        uint128 amount,
        bool claim
    ) internal {
        require(amount > 0, "INVALID_AMOUNT");

        // accrue user pending rewards
        _accrueRewards(recipient, claim);

        asset.safeTransferFrom(msg.sender, address(this), amount);

        // performs check that recipient != address(0)
        receiptToken.mint(recipient, amount);

        emit Deposit(asset, recipient, amount, block.timestamp);
    }

    /// @dev withdraw governance token
    /// @param asset asset to withdraw
    /// @param receiptToken asset wrapper token
    /// @param recipient address to award the receipt tokens
    /// @param amount amount to withdraw
    /// @param claim claim pending stk aave rewards
    function _withdraw(
        IERC20 asset,
        IWrapperToken receiptToken,
        address recipient,
        uint128 amount,
        bool claim
    ) internal {
        require(amount > 0, "INVALID_AMOUNT");
        require(receiptToken.balanceOf(msg.sender) >= amount, "INVALID_BALANCE");

        // claim pending bid rewards only
        _accrueRewards(msg.sender, claim);

        // burn tokens
        receiptToken.burn(msg.sender, amount);

        // send back tokens
        asset.safeTransfer(recipient, amount);

        emit Withdraw(asset, msg.sender, amount, block.timestamp);
    }

    /// @dev _calculateBribeRewardIndex
    function _calculateBribeRewardIndex() internal view returns (uint256 amount) {
        if (
            bribeRewardConfig.startTimestamp == 0 ||
            bribeRewardConfig.startTimestamp > block.timestamp
        ) return 0;

        uint64 startTimestamp = (bribeRewardConfig.startTimestamp >
            assetIndex.bribeLastRewardTimestamp)
            ? bribeRewardConfig.startTimestamp
            : assetIndex.bribeLastRewardTimestamp;

        uint256 endTimestamp;

        if (bribeRewardConfig.endTimestamp == 0) {
            endTimestamp = block.timestamp;
        } else {
            endTimestamp = block.timestamp > bribeRewardConfig.endTimestamp
                ? bribeRewardConfig.endTimestamp
                : block.timestamp;
        }

        if (endTimestamp > startTimestamp) {
            amount =
                (endTimestamp - startTimestamp) *
                bribeRewardConfig.rewardAmountDistributedPerSecond;
        }
    }

    /// @dev _updateBribeRewardIndex
    function _updateBribeRewardIndex() internal {
        uint256 newRewardAmount = _calculateBribeRewardIndex();

        assetIndex.bribeLastRewardTimestamp = block.timestamp.toUint64();
        assetIndex.bribeRewardIndex += newRewardAmount.toUint128();
        assetIndex.bribeRewardPerShare = _calculateBribeRewardPerShare(newRewardAmount).toUint128();

        emit AssetReward(bribeToken, assetIndex.bribeRewardIndex, block.timestamp);
    }

    /// @dev _calculateBribeRewardPerShare
    /// @param newRewardAmount additional reward
    function _calculateBribeRewardPerShare(uint256 newRewardAmount)
        internal
        view
        returns (uint256 newBribeRewardPerShare)
    {
        uint256 increaseSharePrice;
        if (newRewardAmount > 0) {
            increaseSharePrice = ((newRewardAmount * SHARE_SCALE) / _totalSupply());
        }

        newBribeRewardPerShare = assetIndex.bribeRewardPerShare + increaseSharePrice;
    }

    /// @dev _userPendingBribeReward
    /// @param userBalance user aave + stkAave balance
    /// @param userLastPricePerShare user last price per share
    /// @param currentBribeRewardPerShare current reward per share
    function _userPendingBribeReward(
        uint256 userBalance,
        uint256 userLastPricePerShare,
        uint256 currentBribeRewardPerShare
    ) internal pure returns (uint256 pendingReward) {
        if (userBalance > 0 && currentBribeRewardPerShare > 0) {
            pendingReward = ((userBalance * (currentBribeRewardPerShare - userLastPricePerShare)) /
                SHARE_SCALE).toUint128();
        }
    }

    /// @dev _totalSupply current total supply of tokens
    function _totalSupply() internal view returns (uint256) {
        return wrapperAaveToken.totalSupply() + wrapperStkAaveToken.totalSupply();
    }

    /// @dev returns the user bid reward share
    /// @param receiptToken wrapper token
    /// @param user user
    /// @param userLastBidId user last bid id
    function _userPendingBidRewards(
        uint128 currentBidIndex,
        IWrapperToken receiptToken,
        address user,
        uint128 userLastBidId
    ) internal view returns (uint256 accrueBidId, uint256 totalPendingReward) {
        if (currentBidIndex == 0) return (0, 0);

        uint256 currentBidRewardCount = assetIndex.bidId;

        if (userLastBidId == currentBidRewardCount) return (currentBidRewardCount, 0);

        accrueBidId = (currentBidRewardCount - userLastBidId) <= MAX_CLAIM_ITERATIONS
            ? currentBidRewardCount
            : userLastBidId + MAX_CLAIM_ITERATIONS;

        totalPendingReward = _calculateUserPendingBidRewards(
            receiptToken,
            user,
            userLastBidId,
            accrueBidId
        );
    }

    /// @dev _calculateUserPendingBidRewards
    /// @param receiptToken wrapper token
    /// @param user user
    /// @param userLastBidId user last bid id
    /// @param maxRewardId maximum bid id to accrue rewards to
    function _calculateUserPendingBidRewards(
        IWrapperToken receiptToken,
        address user,
        uint256 userLastBidId,
        uint256 maxRewardId
    ) internal view returns (uint256 totalPendingReward) {
        for (uint256 i = userLastBidId; i < maxRewardId; i++) {
            uint256 proposalId = bidIdToProposalId[i];
            Bid storage _bid = bids[proposalId];
            uint128 highestBid = _bid.highestBid;
            // only calculate if highest bid is available and it has been distributed
            if (highestBid > 0 && _bid.voted) {
                uint256 amount = receiptToken.getDepositAt(user, _bid.proposalStartBlock);
                if (amount > 0) {
                    // subtract fee from highest bid
                    totalPendingReward +=
                        (amount * (highestBid - _calculateFeeAmount(highestBid))) /
                        _bid.totalVotes;
                }
            }
        }
    }

    /// @dev update the stkAAve aave reward index
    function _updateStkAaveStakeReward() internal {
        (uint128 rewardsToReceive, uint256 newBalance) = _stkAaveRewardsToReceive();
        if (rewardsToReceive == 0) return;

        assetIndex.rewardIndex += rewardsToReceive;
        assetIndex.stkAaveRewardPerShare = _calculateStkAaveRewardPerShare(rewardsToReceive);
        assetIndex.lastStkAaveRewardBalance = newBalance;

        emit AssetReward(aaveToken, assetIndex.rewardIndex, block.timestamp);
    }

    /// @dev _calculateStkAaveRewardPerShare
    /// @param rewardsToReceive amount of aave rewards to receive
    function _calculateStkAaveRewardPerShare(uint256 rewardsToReceive)
        internal
        view
        returns (uint128 newRewardPerShare)
    {
        uint256 increaseRewardSharePrice;
        if (rewardsToReceive > 0) {
            increaseRewardSharePrice = ((rewardsToReceive * SHARE_SCALE) /
                wrapperStkAaveToken.totalSupply());
        }

        newRewardPerShare = (assetIndex.stkAaveRewardPerShare + increaseRewardSharePrice)
            .toUint128();
    }

    /// @dev _stkAaveRewardsToReceive
    function _stkAaveRewardsToReceive()
        internal
        view
        returns (uint128 rewardsToReceive, uint256 newBalance)
    {
        newBalance = IStakedAave(address(stkAaveToken)).getTotalRewardsBalance(address(this));
        rewardsToReceive = newBalance.toUint128() - assetIndex.lastStkAaveRewardBalance.toUint128();
    }

    /// @dev get the user stkAave aave reward share
    /// @param user user address
    /// @param userLastPricePerShare userLastPricePerShare
    /// @param currentStkAaveRewardPerShare the latest reward per share
    /// @param receiptToken stak aave wrapper token
    function _userPendingstkAaveRewards(
        address user,
        uint128 userLastPricePerShare,
        uint128 currentStkAaveRewardPerShare,
        IWrapperToken receiptToken
    ) internal view returns (uint256 pendingReward) {
        uint256 userBalance = receiptToken.balanceOf(user);

        if (userBalance > 0 && currentStkAaveRewardPerShare > 0) {
            uint128 rewardDebt = ((userBalance * userLastPricePerShare) / SHARE_SCALE).toUint128();
            pendingReward = (((userBalance * currentStkAaveRewardPerShare) / SHARE_SCALE) -
                rewardDebt).toUint128();
        }
    }

    /// @dev get auction expiration of `proposalId`
    /// @param proposalId proposal id
    function _getAuctionExpiration(uint256 proposalId) internal view returns (uint256) {
        IAaveGovernanceV2.ProposalWithoutVotes memory proposal = IAaveGovernanceV2(aaveGovernance)
            .getProposalById(proposalId);
        return block.timestamp + (proposal.endBlock - block.number) * secondPerBlock - 1 hours;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IAavePool {
    struct AssetIndex {
        // tracks the last stkAave aave reward balance
        uint256 lastStkAaveRewardBalance;
        // tracks the total Aave reward for stkAave holders
        uint128 rewardIndex;
        // bribe reward index;
        uint128 bribeRewardIndex;
        // bribe reward last timestamp
        uint64 bribeLastRewardTimestamp;
        // bid id
        uint64 bidId;
        // tracks the total bid reward
        // share to be distributed
        uint128 bidIndex;
        // tracks the reward per share
        uint128 bribeRewardPerShare;
        // tracks the reward per share
        uint128 stkAaveRewardPerShare;
    }

    struct BribeReward {
        uint128 rewardAmountDistributedPerSecond;
        uint64 startTimestamp;
        uint64 endTimestamp;
    }

    struct UserInfo {
        // stkaave reward index
        uint128 stkAaveLastRewardPerShare;
        // bribe reward index
        uint128 bribeLastRewardPerShare;
        // reward from the bids in the bribe pool
        uint128 totalPendingBidReward;
        // tracks aave reward from the stk aave pool
        uint128 totalPendingStkAaveReward;
        // tracks bribe distributed to the user
        uint128 totalPendingBribeReward;
        // tracks the last user bid id for aave deposit
        uint128 aaveLastBidId;
        // tracks the last user bid id for stkAave deposit
        uint128 stkAaveLastBidId;
    }

    /// @dev proposal bid info
    struct Bid {
        uint256 totalVotes;
        uint256 proposalStartBlock;
        uint128 highestBid;
        uint64 endTime;
        bool support;
        bool voted;
        address highestBidder;
    }

    /// @dev emitted on deposit
    event Deposit(IERC20 indexed token, address indexed user, uint256 amount, uint256 timestamp);

    /// @dev emitted on user reward accrue
    event AssetReward(IERC20 indexed asset, uint256 totalAmountAccrued, uint256 timestamp);

    /// @dev emitted on user reward accrue
    event RewardAccrue(
        address indexed user,
        uint256 pendingBidReward,
        uint256 pendingStkAaveReward,
        uint256 pendingBribeReward,
        uint256 timestamp
    );

    event Withdraw(IERC20 indexed token, address indexed user, uint256 amount, uint256 timestamp);

    event RewardClaim(
        address indexed user,
        uint256 pendingBid,
        uint256 pendingReward,
        uint256 pendingBribeReward,
        uint256 timestamp
    );

    event RewardDistributed(uint256 proposalId, uint256 amount);

    event HighestBidIncreased(
        uint256 indexed proposalId,
        address indexed prevHighestBidder,
        address indexed highestBidder,
        address sender,
        uint256 highestBid,
        bool support
    );

    event BlockProposalId(uint256 indexed proposalId, uint256 timestamp);

    event UnblockProposalId(uint256 indexed proposalId, uint256 timestamp);

    event UpdateDelayPeriod(uint256 delayperiod, uint256 timestamp);

    /// @dev emitted on vote
    event Vote(uint256 indexed proposalId, address user, bool support, uint256 timestamp);

    /// @dev emitted on Refund
    event Refund(uint256 indexed proposalId, address bidder, uint256 bidAmount);

    /// @dev emitted on Unclaimed rewards
    event UnclaimedRewards(address owner, uint256 amount);

    /// @dev emitted on setEndTimestamp
    event SetBribeRewardEndTimestamp(uint256 oldTimestamp, uint256 endTimestamp);

    /// @dev emitted on setRewardPerSecond
    event SetBribeRewardPerSecond(uint256 oldRewardPerSecond, uint256 newRewardPerSecond);

    /// @dev emitted on withdrawRemainingReward
    event WithdrawRemainingReward(uint256 amount);

    /// @dev emmitted on setStartTimestamp
    event SetBribeRewardStartTimestamp(uint256 oldTimestamp, uint256 endTimestamp);

    /// @dev emitted on setFeeRecipient
    event UpdateFeeRecipient(address sender, address receipient);

    /// @dev emitted on createProposal
    event CreatedProposal(uint256 proposalId);

    function deposit(
        IERC20 asset,
        address recipient,
        uint128 amount,
        bool claim
    ) external;

    function withdraw(
        IERC20 asset,
        address recipient,
        uint128 amount,
        bool claim
    ) external;

    function bid(
        address bidder,
        uint256 proposalId,
        uint128 amount,
        bool support
    ) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;
pragma abicoder v2;

import {IExecutorWithTimelock} from "./IExecutorWithTimelock.sol";

interface IAaveGovernanceV2 {
    enum ProposalState {
        Pending,
        Canceled,
        Active,
        Failed,
        Succeeded,
        Queued,
        Expired,
        Executed
    }

    struct Vote {
        bool support;
        uint248 votingPower;
    }

    struct Proposal {
        uint256 id;
        address creator;
        IExecutorWithTimelock executor;
        address[] targets;
        uint256[] values;
        string[] signatures;
        bytes[] calldatas;
        bool[] withDelegatecalls;
        uint256 startBlock;
        uint256 endBlock;
        uint256 executionTime;
        uint256 forVotes;
        uint256 againstVotes;
        bool executed;
        bool canceled;
        address strategy;
        bytes32 ipfsHash;
        mapping(address => Vote) votes;
    }

    struct ProposalWithoutVotes {
        uint256 id;
        address creator;
        IExecutorWithTimelock executor;
        address[] targets;
        uint256[] values;
        string[] signatures;
        bytes[] calldatas;
        bool[] withDelegatecalls;
        uint256 startBlock;
        uint256 endBlock;
        uint256 executionTime;
        uint256 forVotes;
        uint256 againstVotes;
        bool executed;
        bool canceled;
        address strategy;
        bytes32 ipfsHash;
    }

    /**
     * @dev emitted when a new proposal is created
     * @param id Id of the proposal
     * @param creator address of the creator
     * @param executor The ExecutorWithTimelock contract that will execute the proposal
     * @param targets list of contracts called by proposal's associated transactions
     * @param values list of value in wei for each propoposal's associated transaction
     * @param signatures list of function signatures (can be empty) to be used when created the callData
     * @param calldatas list of calldatas: if associated signature empty, calldata ready, else calldata is arguments
     * @param withDelegatecalls boolean, true = transaction delegatecalls the taget, else calls the target
     * @param startBlock block number when vote starts
     * @param endBlock block number when vote ends
     * @param strategy address of the governanceStrategy contract
     * @param ipfsHash IPFS hash of the proposal
     **/
    event ProposalCreated(
        uint256 id,
        address indexed creator,
        IExecutorWithTimelock indexed executor,
        address[] targets,
        uint256[] values,
        string[] signatures,
        bytes[] calldatas,
        bool[] withDelegatecalls,
        uint256 startBlock,
        uint256 endBlock,
        address strategy,
        bytes32 ipfsHash
    );

    /**
     * @dev emitted when a proposal is canceled
     * @param id Id of the proposal
     **/
    event ProposalCanceled(uint256 id);

    /**
     * @dev emitted when a proposal is queued
     * @param id Id of the proposal
     * @param executionTime time when proposal underlying transactions can be executed
     * @param initiatorQueueing address of the initiator of the queuing transaction
     **/
    event ProposalQueued(uint256 id, uint256 executionTime, address indexed initiatorQueueing);
    /**
     * @dev emitted when a proposal is executed
     * @param id Id of the proposal
     * @param initiatorExecution address of the initiator of the execution transaction
     **/
    event ProposalExecuted(uint256 id, address indexed initiatorExecution);
    /**
     * @dev emitted when a vote is registered
     * @param id Id of the proposal
     * @param voter address of the voter
     * @param support boolean, true = vote for, false = vote against
     * @param votingPower Power of the voter/vote
     **/
    event VoteEmitted(uint256 id, address indexed voter, bool support, uint256 votingPower);

    event GovernanceStrategyChanged(address indexed newStrategy, address indexed initiatorChange);

    event VotingDelayChanged(uint256 newVotingDelay, address indexed initiatorChange);

    event ExecutorAuthorized(address executor);

    event ExecutorUnauthorized(address executor);

    /**
     * @dev Creates a Proposal (needs Proposition Power of creator > Threshold)
     * @param executor The ExecutorWithTimelock contract that will execute the proposal
     * @param targets list of contracts called by proposal's associated transactions
     * @param values list of value in wei for each propoposal's associated transaction
     * @param signatures list of function signatures (can be empty) to be used when created the callData
     * @param calldatas list of calldatas: if associated signature empty, calldata ready, else calldata is arguments
     * @param withDelegatecalls if true, transaction delegatecalls the taget, else calls the target
     * @param ipfsHash IPFS hash of the proposal
     **/
    function create(
        IExecutorWithTimelock executor,
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        bool[] memory withDelegatecalls,
        bytes32 ipfsHash
    ) external returns (uint256);

    /**
     * @dev Cancels a Proposal,
     * either at anytime by guardian
     * or when proposal is Pending/Active and threshold no longer reached
     * @param proposalId id of the proposal
     **/
    function cancel(uint256 proposalId) external;

    /**
     * @dev Queue the proposal (If Proposal Succeeded)
     * @param proposalId id of the proposal to queue
     **/
    function queue(uint256 proposalId) external;

    /**
     * @dev Execute the proposal (If Proposal Queued)
     * @param proposalId id of the proposal to execute
     **/
    function execute(uint256 proposalId) external payable;

    /**
     * @dev Function allowing msg.sender to vote for/against a proposal
     * @param proposalId id of the proposal
     * @param support boolean, true = vote for, false = vote against
     **/
    function submitVote(uint256 proposalId, bool support) external;

    /**
     * @dev Function to register the vote of user that has voted offchain via signature
     * @param proposalId id of the proposal
     * @param support boolean, true = vote for, false = vote against
     * @param v v part of the voter signature
     * @param r r part of the voter signature
     * @param s s part of the voter signature
     **/
    function submitVoteBySignature(
        uint256 proposalId,
        bool support,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Set new GovernanceStrategy
     * Note: owner should be a timelocked executor, so needs to make a proposal
     * @param governanceStrategy new Address of the GovernanceStrategy contract
     **/
    function setGovernanceStrategy(address governanceStrategy) external;

    /**
     * @dev Set new Voting Delay (delay before a newly created proposal can be voted on)
     * Note: owner should be a timelocked executor, so needs to make a proposal
     * @param votingDelay new voting delay in seconds
     **/
    function setVotingDelay(uint256 votingDelay) external;

    /**
     * @dev Add new addresses to the list of authorized executors
     * @param executors list of new addresses to be authorized executors
     **/
    function authorizeExecutors(address[] memory executors) external;

    /**
     * @dev Remove addresses to the list of authorized executors
     * @param executors list of addresses to be removed as authorized executors
     **/
    function unauthorizeExecutors(address[] memory executors) external;

    /**
     * @dev Let the guardian abdicate from its priviledged rights
     **/
    function __abdicate() external;

    /**
     * @dev Getter of the current GovernanceStrategy address
     * @return The address of the current GovernanceStrategy contracts
     **/
    function getGovernanceStrategy() external view returns (address);

    /**
     * @dev Getter of the current Voting Delay (delay before a created proposal can be voted on)
     * Different from the voting duration
     * @return The voting delay in seconds
     **/
    function getVotingDelay() external view returns (uint256);

    /**
     * @dev Returns whether an address is an authorized executor
     * @param executor address to evaluate as authorized executor
     * @return true if authorized
     **/
    function isExecutorAuthorized(address executor) external view returns (bool);

    /**
     * @dev Getter the address of the guardian, that can mainly cancel proposals
     * @return The address of the guardian
     **/
    function getGuardian() external view returns (address);

    /**
     * @dev Getter of the proposal count (the current number of proposals ever created)
     * @return the proposal count
     **/
    function getProposalsCount() external view returns (uint256);

    /**
     * @dev Getter of a proposal by id
     * @param proposalId id of the proposal to get
     * @return the proposal as ProposalWithoutVotes memory object
     **/
    function getProposalById(uint256 proposalId)
        external
        view
        returns (ProposalWithoutVotes memory);

    /**
     * @dev Getter of the Vote of a voter about a proposal
     * Note: Vote is a struct: ({bool support, uint248 votingPower})
     * @param proposalId id of the proposal
     * @param voter address of the voter
     * @return The associated Vote memory object
     **/
    function getVoteOnProposal(uint256 proposalId, address voter)
        external
        view
        returns (Vote memory);

    /**
     * @dev Get the current state of a proposal
     * @param proposalId id of the proposal
     * @return The current state if the proposal
     **/
    function getProposalState(uint256 proposalId) external view returns (ProposalState);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;
pragma abicoder v2;

interface IGovernanceStrategy {
    /**
     * @dev Returns the Proposition Power of a user at a specific block number.
     * @param user Address of the user.
     * @param blockNumber Blocknumber at which to fetch Proposition Power
     * @return Power number
     **/
    function getPropositionPowerAt(address user, uint256 blockNumber)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the total supply of Outstanding Proposition Tokens
     * @param blockNumber Blocknumber at which to evaluate
     * @return total supply at blockNumber
     **/
    function getTotalPropositionSupplyAt(uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the total supply of Outstanding Voting Tokens
     * @param blockNumber Blocknumber at which to evaluate
     * @return total supply at blockNumber
     **/
    function getTotalVotingSupplyAt(uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the Vote Power of a user at a specific block number.
     * @param user Address of the user.
     * @param blockNumber Blocknumber at which to fetch Vote Power
     * @return Vote number
     **/
    function getVotingPowerAt(address user, uint256 blockNumber) external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;
pragma abicoder v2;

import {IAaveGovernanceV2} from "./IAaveGovernanceV2.sol";

interface IExecutorWithTimelock {
    /**
     * @dev emitted when a new pending admin is set
     * @param newPendingAdmin address of the new pending admin
     **/
    event NewPendingAdmin(address newPendingAdmin);

    /**
     * @dev emitted when a new admin is set
     * @param newAdmin address of the new admin
     **/
    event NewAdmin(address newAdmin);

    /**
     * @dev emitted when a new delay (between queueing and execution) is set
     * @param delay new delay
     **/
    event NewDelay(uint256 delay);

    /**
     * @dev emitted when a new (trans)action is Queued.
     * @param actionHash hash of the action
     * @param target address of the targeted contract
     * @param value wei value of the transaction
     * @param signature function signature of the transaction
     * @param data function arguments of the transaction or callData if signature empty
     * @param executionTime time at which to execute the transaction
     * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
     **/
    event QueuedAction(
        bytes32 actionHash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 executionTime,
        bool withDelegatecall
    );

    /**
     * @dev emitted when an action is Cancelled
     * @param actionHash hash of the action
     * @param target address of the targeted contract
     * @param value wei value of the transaction
     * @param signature function signature of the transaction
     * @param data function arguments of the transaction or callData if signature empty
     * @param executionTime time at which to execute the transaction
     * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
     **/
    event CancelledAction(
        bytes32 actionHash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 executionTime,
        bool withDelegatecall
    );

    /**
     * @dev emitted when an action is Cancelled
     * @param actionHash hash of the action
     * @param target address of the targeted contract
     * @param value wei value of the transaction
     * @param signature function signature of the transaction
     * @param data function arguments of the transaction or callData if signature empty
     * @param executionTime time at which to execute the transaction
     * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
     * @param resultData the actual callData used on the target
     **/
    event ExecutedAction(
        bytes32 actionHash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 executionTime,
        bool withDelegatecall,
        bytes resultData
    );

    /**
     * @dev Getter of the current admin address (should be governance)
     * @return The address of the current admin
     **/
    function getAdmin() external view returns (address);

    /**
     * @dev Getter of the current pending admin address
     * @return The address of the pending admin
     **/
    function getPendingAdmin() external view returns (address);

    /**
     * @dev Getter of the delay between queuing and execution
     * @return The delay in seconds
     **/
    function getDelay() external view returns (uint256);

    /**
     * @dev Returns whether an action (via actionHash) is queued
     * @param actionHash hash of the action to be checked
     * keccak256(abi.encode(target, value, signature, data, executionTime, withDelegatecall))
     * @return true if underlying action of actionHash is queued
     **/
    function isActionQueued(bytes32 actionHash) external view returns (bool);

    /**
     * @dev Checks whether a proposal is over its grace period
     * @param governance Governance contract
     * @param proposalId Id of the proposal against which to test
     * @return true of proposal is over grace period
     **/
    function isProposalOverGracePeriod(IAaveGovernanceV2 governance, uint256 proposalId)
        external
        view
        returns (bool);

    /**
     * @dev Getter of grace period constant
     * @return grace period in seconds
     **/
    function GRACE_PERIOD() external view returns (uint256);

    /**
     * @dev Getter of minimum delay constant
     * @return minimum delay in seconds
     **/
    function MINIMUM_DELAY() external view returns (uint256);

    /**
     * @dev Getter of maximum delay constant
     * @return maximum delay in seconds
     **/
    function MAXIMUM_DELAY() external view returns (uint256);

    /**
     * @dev Function, called by Governance, that queue a transaction, returns action hash
     * @param target smart contract target
     * @param value wei value of the transaction
     * @param signature function signature of the transaction
     * @param data function arguments of the transaction or callData if signature empty
     * @param executionTime time at which to execute the transaction
     * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
     **/
    function queueTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 executionTime,
        bool withDelegatecall
    ) external returns (bytes32);

    /**
     * @dev Function, called by Governance, that cancels a transaction, returns the callData executed
     * @param target smart contract target
     * @param value wei value of the transaction
     * @param signature function signature of the transaction
     * @param data function arguments of the transaction or callData if signature empty
     * @param executionTime time at which to execute the transaction
     * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
     **/
    function executeTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 executionTime,
        bool withDelegatecall
    ) external payable returns (bytes memory);

    /**
     * @dev Function, called by Governance, that cancels a transaction, returns action hash
     * @param target smart contract target
     * @param value wei value of the transaction
     * @param signature function signature of the transaction
     * @param data function arguments of the transaction or callData if signature empty
     * @param executionTime time at which to execute the transaction
     * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
     **/
    function cancelTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 executionTime,
        bool withDelegatecall
    ) external returns (bytes32);
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IWrapperToken is IERC20Upgradeable {
    function mint(address, uint256) external;

    function burn(address, uint256) external;

    function getAccountSnapshot(address user)
        external
        view
        returns (uint256[] memory, uint256[] memory);

    function getDepositAt(address user, uint256 blockNumber) external view returns (uint256 amount);

    function initialize(address underlying_) external;

    /// @dev emitted on update account snapshot
    event UpdateSnapshot(
        address indexed user,
        uint256 oldValue,
        uint256 newValue,
        uint256 timestamp
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStakedAave is IERC20 {
    function claimRewards(address to, uint256 amount) external;

    function getTotalRewardsBalance(address staker) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IERC20Details {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IBribeExecutor {
    function execute(
        address user,
        uint256 amount,
        bytes calldata data
    ) external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "./interfaces/Bribe/IBribeMultiAssetPool.sol";
import "./interfaces/IFeeDistributor.sol";

////////////////////////////////////////////////////////////////////////////////////////////
///
/// @title BribePoolBase
/// @author [email protected]
/// @notice
///
////////////////////////////////////////////////////////////////////////////////////////////

abstract contract BribePoolBase is IBribeMultiAssetPool, IFeeDistributor, Ownable, Multicall {
    constructor() Ownable() {}

    /// @notice Call wrapper that performs `ERC20.permit` on `token`.
    //  Parameters can be used front-run the permit and the user's permit will fail (due to nonce or other revert)
    //     if part of a batch this could be used to grief once as the second call would not need the permit
    function permitToken(
        IERC20Permit token,
        address from,
        address to,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        token.permit(from, to, amount, deadline, v, r, s);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Multicall.sol)

pragma solidity ^0.8.0;

import "./Address.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract Multicall {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        return results;
    }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBribeMultiAssetPool {}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFeeDistributor {
    ////
    /// fee distribution interface to be implemented
    /// by all pools so that they conform to the
    /// fee Distributor implementation
    ///

    event WithdrawFees(address indexed sender, uint256 feesReceived, uint256 timestamp);

    function withdrawFees() external returns (uint256 feeAmount);
}