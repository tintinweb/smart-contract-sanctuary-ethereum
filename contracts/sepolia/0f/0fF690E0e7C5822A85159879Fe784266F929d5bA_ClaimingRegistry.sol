// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "./libraries/DecimalsConverter.sol";
import "./libraries/SafeMath.sol";

import "./interfaces/IContractsRegistry.sol";
import "./interfaces/IClaimingRegistry.sol";
import "./interfaces/IPolicyBook.sol";
import "./interfaces/IPolicyRegistry.sol";
import "./interfaces/IPolicyBookRegistry.sol";
import "./interfaces/ILeveragePool.sol";
import "./interfaces/ICapitalPool.sol";
import "./interfaces/IClaimVoting.sol";
import "./interfaces/IDemandBook.sol";
import "./interfaces/ICompoundPool.sol";
import "./interfaces/IRewardPool.sol";
import "./interfaces/IDEINNFTStaking.sol";
import "./interfaces/helpers/IPriceFeed.sol";

import "./abstract/AbstractDependant.sol";
import "./Globals.sol";

contract ClaimingRegistry is IClaimingRegistry, Initializable, AbstractDependant {
    using SafeMath for uint256;
    using Math for uint256;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 constant MAX_CLAIM_WITHDRAWAL_REQUESTS = 300;

    uint256 internal constant ANONYMOUS_VOTE_DURATION = 10 minutes;
    uint256 internal constant EXPOSE_VOTE_DURATION = 20 minutes;

    uint256 internal constant PRIVATE_CLAIM_DURATION = 1 hours;
    uint256 internal constant VIEW_VERDICT_DURATION = 2 hours;

    uint256 internal constant APPEAL_SLOT_DURATION = 3 hours;

    IERC20Metadata public stblToken;
    IERC20Metadata public deinToken;
    IDEINNFTStaking public deinNFTStaking;

    IPolicyRegistry public policyRegistry;
    ICapitalPool public capitalPool;
    IClaimVoting public claimVoting;
    IPolicyBookRegistry public policyBookRegistry;
    IDemandBook public demandBook;
    ICompoundPool public compoundPool;
    IRewardPool public rewardPool;
    IPriceFeed public priceFeed;

    address internal policyBookAdminAddress;

    uint256 public stblDecimals;

    // claim management
    uint256 private _claimIndex;
    mapping(uint256 => ClaimInfo) public override claimInfo; // claimIndex -> ClaimInfo

    EnumerableSet.UintSet internal _allClaims; // claimIndexes
    mapping(address => EnumerableSet.UintSet) internal _myClaims; // claimer -> claimIndexes
    mapping(address => mapping(uint256 => EnumerableSet.UintSet)) internal _bookClaims; // book -> demandIndex (0 if policy) -> claimIndexes

    mapping(address => mapping(uint256 => mapping(address => uint256))) internal _claimsToIndex; // book -> demandIndex (0 if policy) -> claimer -> claimIndex

    // claim withdraw
    EnumerableSet.UintSet internal _claimsToRefund;
    mapping(uint256 => ClaimWithdrawalInfo) public claimWithdrawalInfo; // claimIndex -> ClaimWithdrawalInfo

    event ClaimPending(uint256 indexed claimIndex, ClaimProvenance claimProvenance);
    event AppealPending(uint256 indexed claimIndex, ClaimProvenance claimProvenance);
    event ClaimCalculated(uint256 indexed claimIndex, ClaimStatus claimStatus);
    event RefundRequested(address indexed claimer, uint256 refundAmount);
    event RefundWithdrawn(address indexed claimer, uint256 refundAmount);

    modifier onlyClaimVoting() {
        require(address(claimVoting) == msg.sender, "CR: Caller is not CV");
        _;
    }

    modifier onlyAdmin() {
        require(policyBookAdminAddress == msg.sender, "CR: Caller is not PBA");
        _;
    }

    modifier withExistingClaim(uint256 claimIndex) {
        require(_claimExists(claimIndex), "CR: This claim doesn't exist");
        _;
    }

    function __ClaimingRegistry_init() external initializer {
        _claimIndex = 1;
    }

    function setDependencies(IContractsRegistry _contractsRegistry)
        external
        override
        onlyInjectorOrZero
    {
        policyRegistry = IPolicyRegistry(_contractsRegistry.getPolicyRegistryContract());
        policyBookAdminAddress = _contractsRegistry.getPolicyBookAdminContract();
        capitalPool = ICapitalPool(_contractsRegistry.getCapitalPoolContract());
        policyBookRegistry = IPolicyBookRegistry(
            _contractsRegistry.getPolicyBookRegistryContract()
        );
        claimVoting = IClaimVoting(_contractsRegistry.getClaimVotingContract());
        stblToken = IERC20Metadata(_contractsRegistry.getUSDTContract());
        deinToken = IERC20Metadata(_contractsRegistry.getDEINContract());
        demandBook = IDemandBook(_contractsRegistry.getDemandBookContract());
        compoundPool = ICompoundPool(_contractsRegistry.getCompoundPoolContract());
        rewardPool = IRewardPool(_contractsRegistry.getRewardPoolContract());
        deinNFTStaking = IDEINNFTStaking(_contractsRegistry.getDEINNFTStakingContract());
        priceFeed = IPriceFeed(_contractsRegistry.getPriceFeedContract());

        stblDecimals = stblToken.decimals();
    }

    // ********** GETTERS ENUMERABLE ********** //
    function _claimExists(uint256 claimIndex) internal view returns (bool) {
        return _allClaims.contains(claimIndex);
    }

    function getClaimIndex(ClaimProvenance calldata claimProvenance)
        external
        view
        override
        returns (uint256)
    {
        return
            _claimsToIndex[claimProvenance.bookAddress][claimProvenance.demandIndex][
                claimProvenance.claimer
            ];
    }

    function getClaimToRefundAtIndex(uint256 index) external view returns (uint256) {
        return _claimsToRefund.at(index);
    }

    // ********** GETTERS STORAGE ********** //
    /// @notice returns anonymous voting duration
    function anonymousVotingDuration() external pure override returns (uint256) {
        return ANONYMOUS_VOTE_DURATION;
    }

    /// @notice returns the whole voting duration
    function votingDuration() external pure override returns (uint256) {
        return ANONYMOUS_VOTE_DURATION.tryAdd(EXPOSE_VOTE_DURATION);
    }

    /// @notice returns the stored claim status {PENDING, ACCEPTED, DENIED, REJECTED, EXPIRED}
    function getClaimStatus(uint256 claimIndex) external view override returns (ClaimStatus) {
        return claimInfo[claimIndex].claimStatus;
    }

    /// @notice returns the calculated claim status {VOTING, EXPOSURE, REVEAL, ACCEPTED, DENIED, REJECTED, EXPIRED}
    function _getClaimPublicStatus(uint256 claimIndex)
        internal
        view
        returns (ClaimPublicStatus claimPublicStatus)
    {
        if (claimInfo[claimIndex].claimStatus == ClaimStatus.PENDING) {
            if (isClaimAnonymouslyVotable(claimIndex)) {
                return ClaimPublicStatus.VOTING;
            } else if (isClaimExposablyVotable(claimIndex)) {
                return ClaimPublicStatus.EXPOSURE;
            } else if (_isClaimAwaitingCalculation(claimIndex)) {
                return ClaimPublicStatus.REVEAL;
            }
        } else if (claimInfo[claimIndex].claimStatus == ClaimStatus.ACCEPTED) {
            return ClaimPublicStatus.ACCEPTED;
        } else if (claimInfo[claimIndex].claimStatus == ClaimStatus.DENIED) {
            return ClaimPublicStatus.DENIED;
        } else if (claimInfo[claimIndex].claimStatus == ClaimStatus.REJECTED) {
            return ClaimPublicStatus.REJECTED;
        } else if (claimInfo[claimIndex].claimStatus == ClaimStatus.EXPIRED) {
            return ClaimPublicStatus.EXPIRED;
        }
    }

    function getClaimProvenance(uint256 claimIndex)
        external
        view
        override
        returns (ClaimProvenance memory)
    {
        return claimInfo[claimIndex].claimProvenance;
    }

    function getClaimDateStart(uint256 claimIndex)
        external
        view
        override
        returns (uint256 dateStart)
    {
        dateStart = claimInfo[claimIndex].dateStart;
    }

    function getClaimDateEnd(uint256 claimIndex) external view override returns (uint256 dateEnd) {
        dateEnd = claimInfo[claimIndex].dateEnd;
    }

    function getClaimAmounts(uint256 claimIndex)
        external
        view
        override
        returns (
            uint256 claimAmount,
            uint256 lockedAmount,
            uint256 rewardAmount
        )
    {
        claimAmount = claimInfo[claimIndex].claimAmount;
        lockedAmount = claimInfo[claimIndex].lockedAmount;
        rewardAmount = claimInfo[claimIndex].rewardAmount;
    }

    function isClaimAppeal(uint256 claimIndex) external view override returns (bool) {
        return claimInfo[claimIndex].appeal;
    }

    // ********** GETTERS PROCESS ********** //
    function isClaimAnonymouslyVotable(uint256 claimIndex)
        public
        view
        override
        withExistingClaim(claimIndex)
        returns (bool)
    {
        return
            claimInfo[claimIndex].claimStatus == ClaimStatus.PENDING &&
            block.timestamp < claimInfo[claimIndex].dateStart.tryAdd(ANONYMOUS_VOTE_DURATION);
    }

    function isClaimExposablyVotable(uint256 claimIndex)
        public
        view
        override
        withExistingClaim(claimIndex)
        returns (bool)
    {
        return
            claimInfo[claimIndex].claimStatus == ClaimStatus.PENDING &&
            block.timestamp > claimInfo[claimIndex].dateStart.tryAdd(ANONYMOUS_VOTE_DURATION) &&
            block.timestamp <
            claimInfo[claimIndex].dateStart.tryAdd(ANONYMOUS_VOTE_DURATION).tryAdd(
                EXPOSE_VOTE_DURATION
            );
    }

    function _isClaimAwaitingCalculation(uint256 claimIndex)
        internal
        view
        withExistingClaim(claimIndex)
        returns (bool)
    {
        return
            claimInfo[claimIndex].claimStatus == ClaimStatus.PENDING &&
            block.timestamp >
            claimInfo[claimIndex].dateStart.tryAdd(ANONYMOUS_VOTE_DURATION).tryAdd(
                EXPOSE_VOTE_DURATION
            );
    }

    function _canCalculateClaim(uint256 claimIndex, address calculator)
        internal
        view
        withExistingClaim(claimIndex)
        returns (bool)
    {
        return
            claimInfo[claimIndex].claimProvenance.claimer == calculator ||
            block.timestamp >
            claimInfo[claimIndex]
                .dateStart
                .tryAdd(ANONYMOUS_VOTE_DURATION)
                .tryAdd(EXPOSE_VOTE_DURATION)
                .tryAdd(PRIVATE_CLAIM_DURATION);
    }

    function _isClaimCalculationExpired(uint256 claimIndex)
        internal
        view
        withExistingClaim(claimIndex)
        returns (bool)
    {
        return
            claimInfo[claimIndex].claimStatus == ClaimStatus.PENDING &&
            block.timestamp >
            claimInfo[claimIndex]
                .dateStart
                .tryAdd(ANONYMOUS_VOTE_DURATION)
                .tryAdd(EXPOSE_VOTE_DURATION)
                .tryAdd(VIEW_VERDICT_DURATION);
    }

    function isClaimResolved(uint256 claimIndex)
        public
        view
        override
        withExistingClaim(claimIndex)
        returns (bool)
    {
        return claimInfo[claimIndex].claimStatus != ClaimStatus.PENDING;
    }

    // ********** GETTERS COUNT ********** //
    function allClaimsCount() public view returns (uint256) {
        return _allClaims.length();
    }

    function myClaimsCount(address claimer) public view returns (uint256) {
        return _myClaims[claimer].length();
    }

    /// @dev if bookAddress if a Policy, demandIndex = 0
    /// @dev if bookAddress if a Demand, demandIndex is the index of choosen demand
    function _bookClaimsCount(address bookAddress, uint256 demandIndex)
        internal
        view
        returns (uint256)
    {
        return _bookClaims[bookAddress][demandIndex].length();
    }

    function claimsToRefundCount() public view override returns (uint256) {
        return _claimsToRefund.length();
    }

    // ********** GETTERS LIST ********** //
    /// @dev use with allClaimsCount() if listOption == ALL
    /// @dev use with myClaimsCount() if listOption == MINE
    function getListClaims(
        uint256 offset,
        uint256 limit,
        ListOption listOption
    ) external view returns (PublicClaimInfo[] memory publicClaimInfo) {
        uint256 count;
        if (listOption == ListOption.ALL) {
            count = allClaimsCount();
        } else if (listOption == ListOption.MINE) {
            count = myClaimsCount(msg.sender);
        }

        uint256 to = (offset.add(limit)).min(count).max(offset);

        publicClaimInfo = new PublicClaimInfo[](to.uncheckedSub(offset));

        for (uint256 i = offset; i < to; i = uncheckedInc(i)) {
            uint256 claimIndex;
            if (listOption == ListOption.ALL) {
                claimIndex = _allClaims.at(i);
            } else if (listOption == ListOption.MINE) {
                claimIndex = _myClaims[msg.sender].at(i);
            }

            uint256 newIndex = i.uncheckedSub(offset);
            ClaimInfo memory info = claimInfo[claimIndex];

            publicClaimInfo[newIndex].claimIndex = claimIndex;
            publicClaimInfo[newIndex].claimProvenance = info.claimProvenance;
            publicClaimInfo[newIndex].evidenceURI = info.evidenceURI;
            publicClaimInfo[newIndex].dateStart = info.dateStart;
            publicClaimInfo[newIndex].appeal = info.appeal;
            ClaimPublicStatus claimPublicStatus = _getClaimPublicStatus(claimIndex);
            publicClaimInfo[newIndex].claimPublicStatus = claimPublicStatus;
            publicClaimInfo[newIndex].claimAmount = info.claimAmount;

            if (claimPublicStatus == ClaimPublicStatus.VOTING) {
                publicClaimInfo[newIndex].timeRemaining = info
                    .dateStart
                    .tryAdd(ANONYMOUS_VOTE_DURATION)
                    .trySub(block.timestamp);
                publicClaimInfo[newIndex].canVote = claimVoting.canVote(claimIndex, msg.sender);
            } else if (claimPublicStatus == ClaimPublicStatus.EXPOSURE) {
                publicClaimInfo[newIndex].timeRemaining = info
                    .dateStart
                    .tryAdd(ANONYMOUS_VOTE_DURATION)
                    .tryAdd(EXPOSE_VOTE_DURATION)
                    .trySub(block.timestamp);
                publicClaimInfo[newIndex].canExpose = claimVoting.canExpose(
                    claimIndex,
                    msg.sender
                );
            } else if (claimPublicStatus == ClaimPublicStatus.REVEAL) {
                publicClaimInfo[newIndex].timeRemaining = info
                    .dateStart
                    .tryAdd(ANONYMOUS_VOTE_DURATION)
                    .tryAdd(EXPOSE_VOTE_DURATION)
                    .tryAdd(VIEW_VERDICT_DURATION)
                    .trySub(block.timestamp);

                publicClaimInfo[newIndex].revealPriorityTimeRemaining = info
                    .dateStart
                    .tryAdd(ANONYMOUS_VOTE_DURATION)
                    .tryAdd(EXPOSE_VOTE_DURATION)
                    .tryAdd(PRIVATE_CLAIM_DURATION)
                    .trySub(block.timestamp);

                publicClaimInfo[newIndex].canCalculate = _canCalculateClaim(
                    claimIndex,
                    msg.sender
                );
                if (publicClaimInfo[newIndex].canCalculate) {
                    publicClaimInfo[newIndex].calculationReward = _getRewardForCalculation(
                        claimIndex
                    );
                }
            } else if (claimPublicStatus == ClaimPublicStatus.ACCEPTED) {
                publicClaimInfo[newIndex].claimRefund = info.claimRefund;
                publicClaimInfo[newIndex].votesCount = claimVoting.getVotesCount(claimIndex);
                (
                    publicClaimInfo[newIndex].repartitionYES,
                    publicClaimInfo[newIndex].repartitionNO
                ) = claimVoting.getRepartition(claimIndex);
            } else if (claimPublicStatus == ClaimPublicStatus.DENIED) {
                publicClaimInfo[newIndex].timeRemaining = info
                    .dateEnd
                    .tryAdd(APPEAL_SLOT_DURATION)
                    .trySub(block.timestamp);
                publicClaimInfo[newIndex].votesCount = claimVoting.getVotesCount(claimIndex);
                (
                    publicClaimInfo[newIndex].repartitionYES,
                    publicClaimInfo[newIndex].repartitionNO
                ) = claimVoting.getRepartition(claimIndex);
            } else if (claimPublicStatus == ClaimPublicStatus.EXPIRED) {
                publicClaimInfo[newIndex].canWithdrawLocked = _canWithdrawLockedAmount(
                    claimIndex,
                    msg.sender
                );
            }
        }
    }

    // ********** ADMIN LOGIC ********** //
    /// @notice Update Image Uri in case it contains material that is ilegal or offensive
    /// @dev Only the owner of the PolicyBookAdmin can erase/update evidenceUri
    /// @param claimIndex Claim Index that is going to be updated
    /// @param newEvidenceURI New evidence uri. It can be blank.
    function updateImageUriOfClaim(uint256 claimIndex, string calldata newEvidenceURI)
        external
        override
        onlyAdmin
    {
        claimInfo[claimIndex].evidenceURI = newEvidenceURI;
    }

    // ********** SUBMIT LOGIC ********** //
    /// @notice this function carries all conditions to be able to claim
    function canClaim(ClaimProvenance calldata claimProvenance)
        public
        view
        override
        returns (bool)
    {
        uint256 claimIndex =
            _claimsToIndex[claimProvenance.bookAddress][claimProvenance.demandIndex][
                claimProvenance.claimer
            ];
        return
            _isBookActive(claimProvenance) &&
            (!_claimExists(claimIndex) ||
                (claimInfo[claimIndex].claimStatus == ClaimStatus.EXPIRED &&
                    !claimInfo[claimIndex].appeal) ||
                (claimInfo[claimIndex].claimStatus != ClaimStatus.PENDING &&
                    !canAppeal(claimProvenance) &&
                    _bookStartTime(claimProvenance) > claimInfo[claimIndex].dateStart) ||
                (claimInfo[claimIndex].claimStatus == ClaimStatus.REJECTED));
    }

    /// @notice this function carries all conditions to be able to appeal
    function canAppeal(ClaimProvenance calldata claimProvenance)
        public
        view
        override
        returns (bool)
    {
        uint256 claimIndex =
            _claimsToIndex[claimProvenance.bookAddress][claimProvenance.demandIndex][
                claimProvenance.claimer
            ];
        return
            (_isBookActive(claimProvenance) &&
                _bookStartTime(claimProvenance) < claimInfo[claimIndex].dateStart &&
                claimInfo[claimIndex].claimStatus == ClaimStatus.EXPIRED &&
                claimInfo[claimIndex].appeal) ||
            (claimInfo[claimIndex].claimStatus == ClaimStatus.DENIED &&
                block.timestamp < claimInfo[claimIndex].dateEnd.tryAdd(APPEAL_SLOT_DURATION));
    }

    /// @notice submit claim happens on PBF or DB
    /// @dev here is creation of claim/appeal instance
    function submitClaim(
        ClaimProvenance calldata claimProvenance,
        string calldata evidenceURI,
        uint256 cover,
        bool isAppeal
    ) external override {
        require(
            policyBookRegistry.isPolicyBook(msg.sender) || msg.sender == address(demandBook),
            "CR: Not an allowed contract"
        );
        require(cover > 0, "CR: Claimer has no coverage");

        uint256 lockedAmount =
            priceFeed.howManyDEINsInUSDT(
                DecimalsConverter.convertFrom18(cover.uncheckedDiv(100), stblDecimals)
            );

        claimInfo[_claimIndex].claimProvenance = claimProvenance;
        claimInfo[_claimIndex].evidenceURI = evidenceURI;
        claimInfo[_claimIndex].dateStart = block.timestamp;
        claimInfo[_claimIndex].appeal = isAppeal;
        claimInfo[_claimIndex].claimAmount = cover;
        claimInfo[_claimIndex].lockedAmount = lockedAmount;

        _allClaims.add(_claimIndex);
        _myClaims[claimProvenance.claimer].add(_claimIndex);
        _bookClaims[claimProvenance.bookAddress][claimProvenance.demandIndex].add(_claimIndex);
        _claimsToIndex[claimProvenance.bookAddress][claimProvenance.demandIndex][
            claimProvenance.claimer
        ] = _claimIndex;

        _claimIndex = _claimIndex.add(1);

        deinToken.transferFrom(claimProvenance.claimer, address(this), lockedAmount);

        if (!isAppeal) {
            emit ClaimPending(_claimIndex, claimProvenance);
        } else if (isAppeal) {
            emit AppealPending(_claimIndex, claimProvenance);
        }
    }

    // ********** REVEAL LOGIC ********** //
    /// @dev there are 2 conditions to calculate a claim
    /// @dev - voting period is over
    /// @dev - if the calculator is not claimer, is the private calculation period over (3 days)
    function calculateResult(uint256 claimIndex) external override {
        require(
            _isClaimAwaitingCalculation(claimIndex) && _canCalculateClaim(claimIndex, msg.sender),
            "CV: Cannot calculate"
        );

        _rewardForCalculation(claimIndex, msg.sender);
        _resolveClaim(claimIndex);

        emit ClaimCalculated(claimIndex, claimInfo[claimIndex].claimStatus);
    }

    /// @dev when resolving the claim, we get results from ClaimVoting voting instance
    /// @dev if claim expired or no votes => EXPIRED
    /// @dev if quorum not reached => REJECTED
    /// @dev if not expired nor rejected, we check approval percentage => if claim ACCEPTED or DENIED // if appeal ACCEPTED or REJECTED
    function _resolveClaim(uint256 claimIndex) internal {
        bool isAppeal = claimInfo[claimIndex].appeal;

        uint256 totalLocked = deinNFTStaking.totalLocked();

        (uint256 totalStakedVoted, uint256 votedYesPercentage, uint256 claimRefund) =
            claimVoting.resolveVoting(claimIndex);

        if (totalStakedVoted == 0 || _isClaimCalculationExpired(claimIndex)) {
            _expireClaim(claimIndex);
        } else if (totalStakedVoted < totalLocked.mul(QUORUM).uncheckedDiv(PERCENTAGE_100)) {
            _rejectClaim(claimIndex, false);
        } else {
            if (votedYesPercentage >= APPROVAL_PERCENTAGE) {
                _acceptClaim(claimIndex, claimRefund);
            } else {
                if (!isAppeal) {
                    _rejectClaim(claimIndex, true);
                } else {
                    _rejectClaim(claimIndex, false);
                }
            }
        }
    }

    /// @dev we get rewardAmount from RewardPool and ClaimingRegistry receives the tokens
    /// @dev the reward will be paid from this rebalancing
    /// @dev this rewardAmount is then used to calculate the reward for each voters
    function _acceptClaim(uint256 claimIndex, uint256 claimRefund) internal {
        claimInfo[claimIndex].dateEnd = block.timestamp;
        claimInfo[claimIndex].claimRefund = claimRefund;
        claimInfo[claimIndex].claimStatus = ClaimStatus.ACCEPTED;

        uint256 rewardAmount = rewardPool.rebalanceVoteReward(claimIndex);
        claimInfo[claimIndex].rewardAmount = rewardAmount;

        _requestClaimWithdrawal(claimIndex);
    }

    /// @dev we get rewardAmount from RewardPool and ClaimingRegistry does not receive the tokens
    /// @dev the reward will be paid with lockedAmount already present in ClaimingRegistry
    /// @dev this rewardAmount is then used to calculate the reward for each voters
    function _rejectClaim(uint256 claimIndex, bool isDenied) internal {
        claimInfo[claimIndex].dateEnd = block.timestamp;
        if (isDenied) {
            claimInfo[claimIndex].claimStatus = ClaimStatus.DENIED;
        } else {
            claimInfo[claimIndex].claimStatus = ClaimStatus.REJECTED;
        }

        uint256 rewardAmount = rewardPool.rebalanceVoteReward(claimIndex);
        uint256 lockedAmount = claimInfo[claimIndex].lockedAmount;
        claimInfo[claimIndex].lockedAmount = 0;
        claimInfo[claimIndex].rewardAmount = rewardAmount;
        if (rewardAmount < lockedAmount) {
            deinToken.transfer(address(rewardPool), lockedAmount.sub(rewardAmount));
        }

        _commitClaim(claimIndex, false);
    }

    function _expireClaim(uint256 claimIndex) internal {
        claimInfo[claimIndex].dateEnd = block.timestamp;
        claimInfo[claimIndex].claimStatus = ClaimStatus.EXPIRED;
        _commitClaim(claimIndex, false);
    }

    function _commitClaim(uint256 claimIndex, bool isWithdrawn) internal {
        address bookAddress = claimInfo[claimIndex].claimProvenance.bookAddress;
        uint256 demandIndex = claimInfo[claimIndex].claimProvenance.demandIndex;
        address claimer = claimInfo[claimIndex].claimProvenance.claimer;

        if (claimInfo[claimIndex].claimProvenance.provenance == Provenance.POLICY) {
            if (isWithdrawn) {
                IPolicyBook(bookAddress).commitWithdrawnClaim(claimer); // ACCEPTED & withrawn
            } else {
                IPolicyBook(bookAddress).commitClaim(
                    claimer,
                    claimInfo[claimIndex].dateEnd,
                    claimInfo[claimIndex].claimStatus // DENIED, REJECTED, EXPIRED
                );
            }
        } else if (claimInfo[claimIndex].claimProvenance.provenance == Provenance.DEMAND) {
            if (isWithdrawn) {
                demandBook.commitWithdrawnClaim(demandIndex); // ACCEPTED & withrawn
            }
        }
    }

    // ********** REFUND LOGIC ********** //
    function getClaimWithdrawalStatus(uint256 claimIndex) public view returns (WithdrawalStatus) {
        if (claimWithdrawalInfo[claimIndex].readyToWithdrawDate == 0) {
            return WithdrawalStatus.NONE;
        }
        if (block.timestamp < claimWithdrawalInfo[claimIndex].readyToWithdrawDate) {
            return WithdrawalStatus.PENDING;
        }
        return WithdrawalStatus.READY;
    }

    /// @notice fetches the pending claims amounts which is before awaiting for calculation by 24 hrs
    /// @dev use it with claimsToRefundCount
    /// @return totalClaimsAmount uint256 collect claim amounts from pending claims
    function getAllPendingClaimsAmount(
        bool isRebalancing,
        uint256 limit,
        address bookAddress
    ) public view override returns (uint256 totalClaimsAmount) {
        WithdrawalStatus _currentStatus;
        uint256 claimIndex;

        for (uint256 i = 0; i < limit; i = uncheckedInc(i)) {
            claimIndex = _claimsToRefund.at(i);
            _currentStatus = getClaimWithdrawalStatus(claimIndex);

            if (_currentStatus == WithdrawalStatus.NONE) {
                continue;
            }

            ///@dev exclude all ready request until before ready to withdraw date by 24 hrs
            /// + 1 hr (spare time for transaction execution time)
            if (
                isRebalancing &&
                block.timestamp >=
                claimWithdrawalInfo[claimIndex].readyToWithdrawDate.sub(
                    ICapitalPool(capitalPool).rebalanceDuration().tryAdd(60 * 60)
                )
            ) {
                totalClaimsAmount = totalClaimsAmount.add(claimInfo[claimIndex].claimRefund);
            } else if (!isRebalancing) {
                if (bookAddress != address(0)) {
                    if (bookAddress != claimInfo[claimIndex].claimProvenance.bookAddress) continue;
                }

                totalClaimsAmount = totalClaimsAmount.add(claimInfo[claimIndex].claimRefund);
            }
        }
    }

    function _requestClaimWithdrawal(uint256 claimIndex) internal {
        bool committed = claimWithdrawalInfo[claimIndex].committed;
        uint256 claimRefund = claimInfo[claimIndex].claimRefund;
        ClaimProvenance memory _provenance = claimInfo[claimIndex].claimProvenance;

        // liquidate part or full claim amount in case there is not enough fund in the pool
        if (_provenance.provenance == Provenance.POLICY) {
            IPolicyBook _policyBook = IPolicyBook(_provenance.bookAddress);
            // execlude the approved amount in usdt

            uint256 poolLiquidity =
                _policyBook.totalLiquidity().sub(
                    getAllPendingClaimsAmount(
                        false,
                        claimsToRefundCount(),
                        _provenance.bookAddress
                    )
                );

            // add the claim refund in case auto second withdraw request because it includes in pending claim
            if (committed) {
                poolLiquidity = poolLiquidity.add(claimRefund);
            }

            if (poolLiquidity < claimRefund) {
                compoundPool.liquidate(
                    _provenance.bookAddress,
                    _provenance.claimer,
                    claimRefund.uncheckedSub(poolLiquidity)
                );
                claimRefund = poolLiquidity;
                claimInfo[claimIndex].claimRefund = poolLiquidity;
                // for first withdraw request with no liquidty in the pool
                if (claimRefund == 0) {
                    _commitClaim(claimIndex, true);
                }
            }
        }

        if (claimRefund > 0) {
            require(_claimsToRefund.length() < MAX_CLAIM_WITHDRAWAL_REQUESTS, "CR: Limit reached");
            _claimsToRefund.add(claimIndex);
            uint256 readyToWithdrawDate = block.timestamp.tryAdd(capitalPool.getWithdrawPeriod());

            claimWithdrawalInfo[claimIndex] = ClaimWithdrawalInfo(readyToWithdrawDate, committed);

            emit RefundRequested(
                claimInfo[claimIndex].claimProvenance.claimer,
                claimInfo[claimIndex].claimRefund
            );
        }
    }

    function withdrawClaim(uint256 claimIndex) external override {
        address claimer = claimInfo[claimIndex].claimProvenance.claimer;
        require(
            getClaimWithdrawalStatus(claimIndex) == WithdrawalStatus.READY,
            "CR: Withdrawal is not ready"
        );

        uint256 claimRefundConverted =
            DecimalsConverter.convertFrom18(claimInfo[claimIndex].claimRefund, stblDecimals);

        bool takeCommission = claimer != msg.sender;

        uint256 actualAmount =
            capitalPool.fundClaim(
                claimInfo[claimIndex].claimProvenance,
                claimRefundConverted,
                takeCommission
            );

        claimRefundConverted = claimRefundConverted.sub(actualAmount);

        if (!claimWithdrawalInfo[claimIndex].committed) {
            _commitClaim(claimIndex, true);
            claimWithdrawalInfo[claimIndex].committed = true;
        }

        if (claimRefundConverted == 0) {
            claimInfo[claimIndex].claimRefund = 0;
            _claimsToRefund.remove(claimIndex);
            delete claimWithdrawalInfo[claimIndex];
        } else {
            claimInfo[claimIndex].claimRefund = DecimalsConverter.convertTo18(
                claimRefundConverted,
                stblDecimals
            );
            _requestClaimWithdrawal(claimIndex);
        }

        _transferLockedAmount(claimIndex, claimer, claimInfo[claimIndex].lockedAmount);

        emit RefundWithdrawn(
            msg.sender,
            DecimalsConverter.convertTo18(actualAmount, stblDecimals)
        );
    }

    /// @notice used in script to automatically refund the claims that are not whitdrawn by claimer
    /// @dev use with claimsToRefundCount()
    function claimsToRefundMannually(uint256 limit)
        external
        view
        returns (bool isTherePendingClaims)
    {
        for (uint256 i = 0; i < limit; i = uncheckedInc(i)) {
            uint256 claimIndex = _claimsToRefund.at(i);
            if (
                claimWithdrawalInfo[claimIndex].readyToWithdrawDate.tryAdd(1 weeks) <
                block.timestamp
            ) {
                return true;
            }
        }
    }

    // ********** BOOK LOGIC ********** //
    function _isBookActive(ClaimProvenance memory claimProvenance)
        internal
        view
        returns (bool isActive)
    {
        if (claimProvenance.provenance == Provenance.POLICY) {
            isActive = policyRegistry.isPolicyActive(
                claimProvenance.claimer,
                claimProvenance.bookAddress
            );
        } else if (claimProvenance.provenance == Provenance.DEMAND) {
            isActive = demandBook.isDemandActive(
                claimProvenance.claimer,
                claimProvenance.demandIndex
            );
        }
    }

    function _bookStartTime(ClaimProvenance memory claimProvenance)
        internal
        view
        returns (uint256 startTime)
    {
        if (claimProvenance.provenance == Provenance.POLICY) {
            startTime = policyRegistry.policyStartTime(
                claimProvenance.claimer,
                claimProvenance.bookAddress
            );
        } else if (claimProvenance.provenance == Provenance.DEMAND) {
            startTime = demandBook.demandStartTime(claimProvenance.demandIndex);
        }
    }

    function _endActiveBook(ClaimProvenance calldata claimProvenance) internal {
        if (claimProvenance.provenance == Provenance.POLICY) {
            IPolicyBook(claimProvenance.bookAddress).endActivePolicy(claimProvenance.claimer);
        } else if (claimProvenance.provenance == Provenance.DEMAND) {
            demandBook.endActiveDemand(claimProvenance.demandIndex);
        }
    }

    /// @notice this function carries all conditions to be able to buy a new book
    /// @notice if can buy, there is no revert
    /// @notice and if there is a not ended previous one, it ends it
    function canBuyNewBook(ClaimProvenance calldata claimProvenance) external override {
        require(msg.sender == claimProvenance.bookAddress, "CR: Not allowed");

        uint256 claimIndex =
            _claimsToIndex[claimProvenance.bookAddress][claimProvenance.demandIndex][
                claimProvenance.claimer
            ];
        bool previousEnded = !_isBookActive(claimProvenance);

        require(
            (!_claimExists(claimIndex)) ||
                (previousEnded &&
                    (claimInfo[claimIndex].claimStatus != ClaimStatus.PENDING ||
                        (claimInfo[claimIndex].claimStatus == ClaimStatus.DENIED &&
                            !canAppeal(claimProvenance)))),
            "CR: Claim is pending"
        );

        if (!previousEnded) {
            _endActiveBook(claimProvenance);
        }
    }

    /// @notice this function is used in PolicyRegistry
    function getBookStatus(ClaimProvenance calldata claimProvenance)
        external
        view
        override
        returns (BookStatus bookStatus)
    {
        if (canClaim(claimProvenance)) {
            bookStatus = BookStatus.CAN_CLAIM;
        } else if (canAppeal(claimProvenance)) {
            bookStatus = BookStatus.CAN_APPEAL;
        }
    }

    function hasProcedureOngoing(address bookAddress, uint256 demandIndex)
        external
        view
        override
        returns (bool)
    {
        if (bookAddress == address(demandBook)) {
            if (
                _hasProcedureOngoing(
                    bookAddress,
                    demandIndex,
                    _bookClaimsCount(bookAddress, demandIndex)
                )
            ) {
                return true;
            }
        }
        ///@notice disable leveraging
        // else if (policyBookRegistry.isLeveragePool(bookAddress)) {
        //     ILeveragePool userLeveragePool = ILeveragePool(bookAddress);
        //     address[] memory _coveragePools =
        //         userLeveragePool.listleveragedCoveragePools(
        //             0,
        //             userLeveragePool.countleveragedCoveragePools()
        //         );
        //     for (uint256 i = 0; i < _coveragePools.length; i = uncheckedInc(i)) {
        //         if (
        //             _hasProcedureOngoing(
        //                 _coveragePools[i],
        //                 0,
        //                 _bookClaimsCount(_coveragePools[i], 0)
        //             )
        //         ) {
        //             return true;
        //         }
        //     }
        // }
        else {
            if (_hasProcedureOngoing(bookAddress, 0, _bookClaimsCount(bookAddress, 0))) {
                return true;
            }
        }

        return false;
    }

    function _hasProcedureOngoing(
        address bookAddress,
        uint256 demandIndex,
        uint256 limit
    ) internal view returns (bool hasProcedure) {
        for (uint256 i = 0; i < limit; i = uncheckedInc(i)) {
            uint256 claimIndex = _bookClaims[bookAddress][demandIndex].at(i);
            hasProcedure = _isClaimOnProcedure(claimIndex);
        }
    }

    function isPolicyOnProcedure(address policyBookAddress, address userAddress)
        external
        view
        override
        returns (bool isOnProcedure)
    {
        uint256 claimIndex = _claimsToIndex[policyBookAddress][0][userAddress];
        if (claimIndex != 0 && _isClaimOnProcedure(claimIndex)) {
            return true;
        }
    }

    function _isClaimOnProcedure(uint256 claimIndex) internal view returns (bool isOnProcedure) {
        ClaimStatus claimStatus = claimInfo[claimIndex].claimStatus;
        if (
            !(_isClaimCalculationExpired(claimIndex) || // has expired
                claimStatus == ClaimStatus.REJECTED || // has been rejected
                (claimStatus == ClaimStatus.DENIED &&
                    block.timestamp >
                    claimInfo[claimIndex].dateEnd.tryAdd(APPEAL_SLOT_DURATION)) || // had been denied and cannot appeal
                (claimStatus == ClaimStatus.ACCEPTED &&
                    getClaimWithdrawalStatus(claimIndex) == WithdrawalStatus.NONE)) // has been accepted and withdrawn
        ) {
            return true;
        }
    }

    // ********** LOCKED DEIN LOGIC ********** //
    function _canWithdrawLockedAmount(uint256 claimIndex, address user)
        internal
        view
        returns (bool)
    {
        return
            claimInfo[claimIndex].claimProvenance.claimer == user &&
            claimInfo[claimIndex].claimStatus == ClaimStatus.EXPIRED;
    }

    /// @notice claimer can withdraw locked amount manually when the claim has been EXPIRED
    /// @notice if claim is ACCEPTED, the locked amount is automatically withdrawn to claimer at withdrawing claim
    function withdrawLockedAmount(uint256 claimIndex) external override {
        require(_canWithdrawLockedAmount(claimIndex, msg.sender), "CR: Cannot withdraw DEIN");

        _transferLockedAmount(claimIndex, msg.sender, claimInfo[claimIndex].lockedAmount);
    }

    /// @notice when someone calculate the claim, he gets a reward from locked amount
    function _rewardForCalculation(uint256 claimIndex, address calculator) internal {
        uint256 reward = _getRewardForCalculation(claimIndex);
        _transferLockedAmount(claimIndex, calculator, reward);
    }

    function _getRewardForCalculation(uint256 claimIndex) internal view returns (uint256) {
        uint256 lockedAmount = claimInfo[claimIndex].lockedAmount;
        uint256 timeElapsed =
            claimInfo[claimIndex]
                .dateStart
                .tryAdd(ANONYMOUS_VOTE_DURATION)
                .tryAdd(EXPOSE_VOTE_DURATION)
                .tryAdd(PRIVATE_CLAIM_DURATION);

        if (block.timestamp > timeElapsed) {
            timeElapsed = block.timestamp.trySub(timeElapsed);
        } else {
            timeElapsed = timeElapsed.trySub(block.timestamp);
        }

        return
            Math.min(
                lockedAmount,
                lockedAmount
                    .mul(timeElapsed.mul(CALCULATION_REWARD_PER_DAY.uncheckedDiv(1 days)))
                    .uncheckedDiv(PERCENTAGE_100)
            );
    }

    function _transferLockedAmount(
        uint256 claimIndex,
        address receiver,
        uint256 amount
    ) internal {
        claimInfo[claimIndex].lockedAmount = claimInfo[claimIndex].lockedAmount.sub(amount);
        deinToken.transfer(receiver, amount);
    }

    function rewardForVoting(address voter, uint256 amount) external override onlyClaimVoting {
        deinToken.transfer(voter, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

uint256 constant SECONDS_IN_THE_YEAR = 365 * 24 * 60 * 60; // 365 days * 24 hours * 60 minutes * 60 seconds
uint256 constant SECONDS_IN_THE_MONTH = 30 * 24 * 60 * 60; // 30 days * 24 hours * 60 minutes * 60 seconds
uint256 constant DAYS_IN_THE_YEAR = 365;
uint256 constant MAX_INT = type(uint256).max;

uint256 constant DECIMALS18 = 10**18;

uint256 constant INITIAL_STAKED_AMOUNT = 100 * DECIMALS18;
uint256 constant INITIAL_STAKED_AMOUNT_LP = 1 * DECIMALS18;

uint256 constant PRECISION = 10**25;
uint256 constant PERCENTAGE_100 = 100 * PRECISION;

uint256 constant CUSTOM_PRECISION = 10**7;

uint256 constant BLOCKS_PER_DAY = 7200;
uint256 constant BLOCKS_PER_MONTH = BLOCKS_PER_DAY * 30;
uint256 constant BLOCKS_PER_YEAR = BLOCKS_PER_DAY * 365;

uint256 constant APY_TOKENS = DECIMALS18;

uint256 constant ACTIVE_REWARD_PERCENTAGE = 80 * PRECISION;
uint256 constant CLOSED_REWARD_PERCENTAGE = 1 * PRECISION;

uint256 constant DEFAULT_REBALANCING_THRESHOLD = 10**23;

uint256 constant EPOCH_DAYS_AMOUNT = 7;

// ClaimVoting ClaimingRegistry
uint256 constant APPROVAL_PERCENTAGE = 66 * PRECISION;
uint256 constant PENALTY_THRESHOLD = 11 * PRECISION;
uint256 constant QUORUM = 10 * PRECISION;
uint256 constant CALCULATION_REWARD_PER_DAY = PRECISION;
uint256 constant PERCENTAGE_50 = 50 * PRECISION;
uint256 constant PENALTY_PERCENTAGE = 10 * PRECISION;
uint256 constant UNEXPOSED_PERCENTAGE = 1 * PRECISION;

// PolicyBook
uint256 constant MINUMUM_COVERAGE = 100 * DECIMALS18; // 100 STBL
uint256 constant ANNUAL_COVERAGE_TOKENS = MINUMUM_COVERAGE * 10; // 1000 STBL

uint256 constant PREMIUM_DISTRIBUTION_EPOCH = 1 days;
uint256 constant MAX_PREMIUM_DISTRIBUTION_EPOCHS = 90;
// policy
uint256 constant EPOCH_DURATION = 1 weeks;
uint256 constant MAXIMUM_EPOCHS = SECONDS_IN_THE_YEAR / EPOCH_DURATION;
uint256 constant MAXIMUM_EPOCHS_FOR_COMPOUND_LIQUIDITY = 5; //5 epoch
uint256 constant VIRTUAL_EPOCHS = 1;
// demand
uint256 constant DEMAND_EPOCH_DURATION = 1 days;
uint256 constant DEMAND_MAXIMUM_EPOCHS = SECONDS_IN_THE_YEAR / DEMAND_EPOCH_DURATION;
uint256 constant MINIMUM_EPOCHS = SECONDS_IN_THE_MONTH / DEMAND_EPOCH_DURATION;

uint256 constant PERIOD_DURATION = 30 days;
uint256 constant MAX_WITHDRAWAL_REQUESTS = 200;

enum Networks {ETH, BSC, POL}

/// @dev unchecked increment
function uncheckedInc(uint256 i) pure returns (uint256) {
    unchecked {return i + 1;}
}

/// @dev unchecked decrement
function uncheckedDec(uint256 i) pure returns (uint256) {
    unchecked {return i - 1;}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.7;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * COPIED FROM https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.5/contracts/utils/math/SafeMath.sol
 * customize try functions to return one value which is uint256 instead of return tupple
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
    function tryAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return 0;
            return c;
        }
    }

    function uncheckedAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {return a + b;}
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            if (b > a) return 0;
            return a - b;
        }
    }

    function uncheckedSub(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {return a - b;}
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return 0;
            uint256 c = a * b;
            if (c / a != b) return 0;
            return c;
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            if (b == 0) return 0;
            return a / b;
        }
    }

    function uncheckedDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {return a / b;}
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            if (b == 0) return 0;
            return a % b;
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
pragma solidity ^0.8.7;

import "../libraries/SafeMath.sol";

/// @notice the intention of this library is to be able to easily convert
///     one amount of tokens with N decimal places
///     to another amount with M decimal places
library DecimalsConverter {
    using SafeMath for uint256;

    function convert(
        uint256 amount,
        uint256 baseDecimals,
        uint256 destinationDecimals
    ) internal pure returns (uint256) {
        if (baseDecimals > destinationDecimals) {
            amount = amount.uncheckedDiv(10**(baseDecimals.uncheckedSub(destinationDecimals)));
        } else if (baseDecimals < destinationDecimals) {
            amount = amount.mul(10**(destinationDecimals.uncheckedSub(baseDecimals)));
        }

        return amount;
    }

    function convertTo18(uint256 amount, uint256 baseDecimals) internal pure returns (uint256) {
        if (baseDecimals == 18) return amount;
        return convert(amount, baseDecimals, 18);
    }

    function convertFrom18(uint256 amount, uint256 destinationDecimals)
        internal
        pure
        returns (uint256)
    {
        if (destinationDecimals == 18) return amount;
        return convert(amount, 18, destinationDecimals);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IPolicyBookFabric.sol";
import "./IClaimingRegistry.sol";
import "./IPolicyBookFacade.sol";

interface IPolicyBook {
    enum WithdrawalStatus {NONE, PENDING, READY, EXPIRED}

    enum Operator {ADD, SUB}

    struct PolicyHolder {
        uint256 coverTokens;
        uint256 startEpochNumber;
        uint256 endEpochNumber;
        uint256 paid;
        uint256 protocolFee;
    }

    struct WithdrawalInfo {
        uint256 withdrawalAmountDEINx;
        uint256 withdrawalAmountSTBL;
        uint256 readyToWithdrawDate;
        bool withdrawalAllowed;
    }

    struct BuyPolicyParameters {
        address buyer; // who is transferring funds
        address holder; // who owns coverage
        uint256 epochsNumber; // period policy will cover
        uint256 coverTokens; // amount paid for the coverage
        uint256 pendingWithdrawalAmount; // pending Withdrawal Amount
        uint256 deployedCompoundedLiquidity; // used compound liquidity in the policy
        uint256 compoundLiquidity; // available compound liquidity for the pool
        uint256 distributorFee; // distributor fee (commission). It can't be greater than PROTOCOL_PERCENTAGE
        address distributor; // if it was sold buy a whitelisted distributor, it is distributor address to receive fee (commission)
    }

    function policyHolders(address _holder)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    function policyBookFacade() external view returns (IPolicyBookFacade);

    function stblDecimals() external view returns (uint256);

    function READY_TO_WITHDRAW_PERIOD() external view returns (uint256);

    function whitelisted() external view returns (bool);

    function epochStartTime() external view returns (uint256);

    function lastDistributionEpoch() external view returns (uint256);

    function lastPremiumDistributionEpoch() external view returns (uint256);

    function lastPremiumDistributionAmount() external view returns (int256);

    function epochAmounts(uint256 _epochNo) external view returns (uint256);

    function premiumDistributionDeltas(uint256 _epochNo) external view returns (int256);

    // @TODO: should we let DAO to change contract address?
    /// @notice Returns address of contract this PolicyBook covers, access: ANY
    /// @return _contract is address of covered contract
    function insuranceContractAddress() external view returns (address _contract);

    /// @notice Returns type of contract this PolicyBook covers, access: ANY
    /// @return _type is type of contract
    function contractType() external view returns (IPolicyBookFabric.ContractType _type);

    function totalLiquidity() external view returns (uint256);

    function totalCoverTokens() external view returns (uint256);

    function withdrawalsInfo(address _userAddr)
        external
        view
        returns (
            uint256 _withdrawalAmountDEIN,
            uint256 _withdrawalAmountSTBL,
            uint256 _readyToWithdrawDate,
            bool _withdrawalAllowed
        );

    function __PolicyBook_init(
        address _policyBookFacadeAddress,
        IPolicyBookFabric.ContractType _contractType,
        string calldata _description,
        string calldata _projectSymbol
    ) external;

    function whitelist(bool _whitelisted) external;

    function getEpoch(uint256 time) external view returns (uint256);

    /// @notice get STBL equivalent
    function convertDEINXToSTBL(uint256 _amount) external view returns (uint256);

    /// @notice get DEINX equivalent
    function convertSTBLToDEINX(uint256 _amount) external view returns (uint256);

    /// @notice submits new claim of the policy book
    function submitClaimAndInitializeVoting(
        address policyHolder,
        string calldata evidenceURI,
        bool appeal
    ) external;

    /// @notice updates info on claim when not accepted
    function commitClaim(
        address claimer,
        uint256 claimEndTime,
        IClaimingRegistry.ClaimStatus status
    ) external;

    function commitWithdrawnClaim(address claimer) external;

    /// @notice Let user to buy policy by supplying stable coin, access: ANY
    function buyPolicy(BuyPolicyParameters memory parameters) external returns (uint256);

    /// @notice end active policy from ClaimingRegistry in case of a new bought policy
    function endActivePolicy(address _holder) external;

    function updateEpochsInfo() external;

    /// @notice Let eligible contracts add liqiudity for another user by supplying stable coin
    /// @param _liquidityHolderAddr is address of address to assign cover
    /// @param _liqudityAmount is amount of stable coin tokens to secure
    function addLiquidityFor(address _liquidityHolderAddr, uint256 _liqudityAmount) external;

    /// @notice Let user to add liquidity by supplying stable coin, access: ANY
    /// @param _liquidityBuyerAddr address the one that transfer funds
    /// @param _liquidityHolderAddr address the one that owns liquidity
    /// @param _liquidityAmount uint256 amount to be added on behalf the sender
    /// @param _lock uint256 locking period for staking
    function addLiquidity(
        address _liquidityBuyerAddr,
        address _liquidityHolderAddr,
        uint256 _liquidityAmount,
        uint256 _lock
    ) external returns (uint256);

    function getWithdrawalStatus(address _userAddr) external view returns (WithdrawalStatus);

    function requestWithdrawal(
        uint256 _tokensToWithdraw,
        uint256 _availableSTBLBalance,
        uint256 _pendingWithdrawalAmount,
        address _user
    ) external;

    // function requestWithdrawalWithPermit(
    //     uint256 _tokensToWithdraw,
    //     uint8 _v,
    //     bytes32 _r,
    //     bytes32 _s
    // ) external;

    function unlockTokens() external;

    /// @notice Let user to withdraw deposited liqiudity, access: ANY
    function withdrawLiquidity(address sender)
        external
        returns (uint256 _tokensToWithdraw, uint256 _stblTokensToWithdraw);

    ///@notice for doing defi hard rebalancing, access: policyBookFacade
    function updateLiquidity(uint256 _newLiquidity) external;

    function migrateHashedName(string memory newName) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../Globals.sol";

interface IContractsRegistry {
    function getAMMRouterContract() external view returns (address);

    function getAMMDEINToETHPairContract() external view returns (address);

    function getPriceFeedContract() external view returns (address);

    function getWETHContract() external view returns (address);

    function getUSDTContract() external view returns (address);

    function getBMIContract() external view returns (address);

    function getDEINContract() external view returns (address);

    function getPolicyBookRegistryContract() external view returns (address);

    function getPolicyBookFabricContract() external view returns (address);

    function getBMICoverStakingContract() external view returns (address);

    function getBMITreasury() external view returns (address);

    function getDEINCoverStakingContract() external view returns (address);

    function getBMICoverStakingViewContract() external view returns (address);

    function getDEINTreasuryContract() external view returns (address);

    function getRewardsGeneratorContract() external view returns (address);

    function getDEINRewardsGeneratorContract() external view returns (address);

    function getLiquidityBridgeContract() external view returns (address);

    function getClaimingRegistryContract() external view returns (address);

    function getPolicyRegistryContract() external view returns (address);

    function getLiquidityRegistryContract() external view returns (address);

    function getClaimVotingContract() external view returns (address);

    function getRewardPoolContract() external view returns (address);

    function getCompoundPoolContract() external view returns (address);

    function getLeveragePortfolioViewContract() external view returns (address);

    function getCapitalPoolContract() external view returns (address);

    function getPolicyBookAdminContract() external view returns (address);

    function getPolicyQuoteContract() external view returns (address);

    function getBMIStakingContract() external view returns (address);

    function getDEINStakingContract() external view returns (address);

    function getDEINStakingViewContract() external view returns (address);

    function getDEINNFTStakingContract() external view returns (address);

    function getSTKBMIContract() external view returns (address);

    function getStkBMIStakingContract() external view returns (address);

    function getLiquidityMiningStakingETHContract() external view returns (address);

    function getLiquidityMiningStakingUSDTContract() external view returns (address);

    function getReputationSystemContract() external view returns (address);

    function getDefiProtocol1Contract() external view returns (address);

    function getAaveLendPoolAddressProvdierContract() external view returns (address);

    function getAaveATokenContract() external view returns (address);

    function getDefiProtocol2Contract() external view returns (address);

    function getCompoundCTokenContract() external view returns (address);

    function getCompoundComptrollerContract() external view returns (address);

    function getDefiProtocol3Contract() external view returns (address);

    function getYearnVaultContract() external view returns (address);

    function getYieldGeneratorContract() external view returns (address);

    function getShieldMiningContract() external view returns (address);

    function getDemandBookContract() external view returns (address);

    function getDemandBookLiquidityContract() external view returns (address);

    function getSwapEventContract() external view returns (address);

    function getVestingContract() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IPolicyBookFabric.sol";

interface IClaimingRegistry {
    enum Provenance {POLICY, DEMAND}
    enum BookStatus {UNCLAIMABLE, CAN_CLAIM, CAN_APPEAL}

    enum ClaimStatus {PENDING, ACCEPTED, DENIED, REJECTED, EXPIRED}
    enum ClaimPublicStatus {VOTING, EXPOSURE, REVEAL, ACCEPTED, DENIED, REJECTED, EXPIRED}

    enum WithdrawalStatus {NONE, PENDING, READY}

    enum ListOption {ALL, MINE}

    struct ClaimInfo {
        ClaimProvenance claimProvenance;
        string evidenceURI;
        uint256 dateStart;
        uint256 dateEnd;
        bool appeal;
        ClaimStatus claimStatus;
        uint256 claimAmount;
        uint256 claimRefund;
        uint256 lockedAmount;
        uint256 rewardAmount;
    }

    struct PublicClaimInfo {
        uint256 claimIndex;
        ClaimProvenance claimProvenance;
        string evidenceURI;
        uint256 dateStart;
        bool appeal;
        ClaimPublicStatus claimPublicStatus;
        uint256 claimAmount;
        uint256 claimRefund;
        uint256 timeRemaining;
        uint256 revealPriorityTimeRemaining;
        bool canVote;
        bool canExpose;
        bool canCalculate;
        bool canWithdrawLocked;
        uint256 calculationReward;
        uint256 votesCount;
        uint256 repartitionYES;
        uint256 repartitionNO;
    }

    struct ClaimProvenance {
        Provenance provenance;
        address claimer;
        address bookAddress; // policy address or DemandBook address
        uint256 demandIndex; // in case it's a demand
    }

    struct ClaimWithdrawalInfo {
        uint256 readyToWithdrawDate;
        bool committed;
    }

    function claimInfo(uint256 claimIndex)
        external
        view
        returns (
            ClaimProvenance memory claimProvenance,
            string memory evidenceURI,
            uint256 dateStart,
            uint256 dateEnd,
            bool appeal,
            ClaimStatus claimStatus,
            uint256 claimAmount,
            uint256 lockedAmount,
            uint256 claimRefund,
            uint256 rewardAmount
        );

    /// @notice returns anonymous voting duration
    function anonymousVotingDuration() external view returns (uint256);

    /// @notice returns the whole voting duration
    function votingDuration() external view returns (uint256);

    /// @notice returns claim index
    function getClaimIndex(ClaimProvenance calldata claimProvenance)
        external
        view
        returns (uint256);

    /// @notice returns current status of a claim
    function getClaimStatus(uint256 claimIndex) external view returns (ClaimStatus claimStatus);

    /// @notice returns claim provenance
    function getClaimProvenance(uint256 claimIndex) external view returns (ClaimProvenance memory);

    /// @notice returns claim start date
    function getClaimDateStart(uint256 claimIndex) external view returns (uint256 dateStart);

    /// @notice returns claim end date
    function getClaimDateEnd(uint256 claimIndex) external view returns (uint256 dateEnd);

    /// @notice returns claim amounts
    function getClaimAmounts(uint256 claimIndex)
        external
        view
        returns (
            uint256 claimAmount,
            uint256 lockedAmount,
            uint256 rewardAmount
        );

    function isClaimAppeal(uint256 claimIndex) external view returns (bool);

    function isClaimAnonymouslyVotable(uint256 claimIndex) external view returns (bool);

    function isClaimExposablyVotable(uint256 claimIndex) external view returns (bool);

    function isClaimResolved(uint256 claimIndex) external view returns (bool);

    function claimsToRefundCount() external view returns (uint256);

    function updateImageUriOfClaim(uint256 claimIndex, string calldata newEvidenceURI) external;

    function canClaim(ClaimProvenance calldata claimProvenance) external view returns (bool);

    function canAppeal(ClaimProvenance calldata claimProvenance) external view returns (bool);

    function submitClaim(
        ClaimProvenance calldata claimProvenance,
        string calldata evidenceURI,
        uint256 cover,
        bool isAppeal
    ) external;

    function calculateResult(uint256 claimIndex) external;

    function getAllPendingClaimsAmount(
        bool isRebalancing,
        uint256 limit,
        address bookAddress
    ) external view returns (uint256 totalClaimsAmount);

    function withdrawClaim(uint256 claimIndex) external;

    function canBuyNewBook(ClaimProvenance calldata claimProvenance) external;

    function getBookStatus(ClaimProvenance memory claimProvenance)
        external
        view
        returns (BookStatus);

    function hasProcedureOngoing(address bookAddress, uint256 demandIndex)
        external
        view
        returns (bool);

    function isPolicyOnProcedure(address policyBookAddress, address userAddress)
        external
        view
        returns (bool isOnProcedure);

    function withdrawLockedAmount(uint256 claimIndex) external;

    function rewardForVoting(address voter, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IPolicyBookFacade.sol";
import "./IClaimingRegistry.sol";

interface ICapitalPool {
    struct PremiumFactors {
        uint256 epochsNumber;
        uint256 premiumPrice;
        uint256 vStblOfCP;
        uint256 poolUtilizationRation;
        uint256 premiumPerDeployment;
        uint256 userLeveragePoolsCount;
        IPolicyBookFacade policyBookFacade;
    }

    enum PoolType {COVERAGE, LEVERAGE, DEMAND}

    function virtualUsdtAccumulatedBalance() external view returns (uint256);

    function liquidityCushionBalance() external view returns (uint256);

    ///@notice disable leveraging
    /// @notice distributes the policybook premiums into pools (CP, LP)
    /// @dev distributes the balances acording to the established percentages
    /// @param _stblAmount amount hardSTBL ingressed into the system
    function addPolicyHoldersHardSTBL(uint256 _stblAmount) external;

    /// @notice distributes the hardSTBL from the coverage providers
    /// @dev emits PoolBalancedUpdated event
    /// @param _stblAmount amount hardSTBL ingressed into the system
    function addCoverageProvidersHardSTBL(uint256 _stblAmount) external;

    /// @notice distributes the hardSTBL from the leverage providers
    /// @dev emits PoolBalancedUpdated event
    /// @param _stblAmount amount hardSTBL ingressed into the system
    function addLeverageProvidersHardSTBL(uint256 _stblAmount) external;

    /// @notice distributes the hardSTBL from the demand liquidity providers
    /// @dev emits PoolBalancedUpdated event
    /// @param _stblAmount amount hardSTBL ingressed into the system
    function addDemandProvidersHardSTBL(uint256 _stblAmount) external;

    /// @notice add instant withdawal amount from defi protocol to the hardSTBL
    /// @param _stblAmount amount hardSTBL returned to the system
    /// @param _accumaltedAmount amount hardstable of defi interest returned to the dein treasury
    function addWithdrawalHardSTBL(uint256 _stblAmount, uint256 _accumaltedAmount) external;

    /// @notice rebalances pools acording to v2 specification and dao enforced policies
    /// @dev  emits PoolBalancesUpdated
    function rebalanceLiquidityCushion() external;

    /// @notice Fullfils policybook claims by transfering the balance to claimer
    /// @param claimProvenance, address of the claimer recieving the withdraw and book provenance
    /// @param _claimAmount uint256 amount to be withdrawn
    function fundClaim(
        IClaimingRegistry.ClaimProvenance calldata claimProvenance,
        uint256 _claimAmount,
        bool takeCommission
    ) external returns (uint256);

    /// @notice Withdraws liquidity from a specific policbybook to the user
    /// @param _sender, address of the user beneficiary of the withdraw
    /// @param _stblAmount uint256 amount to be withdrawn
    /// @param _isLeveragePool bool wether the pool is ULP or CP(policybook)
    function withdrawLiquidity(
        address _sender,
        uint256 _stblAmount,
        bool _isLeveragePool
    ) external returns (uint256);

    /// @notice Withdraws liquidity from a specific policbybook to the user
    /// @param _sender, address of the user beneficiary of the withdraw
    /// @param _stblAmount uint256 amount to be withdrawn
    function withdrawDemandLiquidity(address _sender, uint256 _stblAmount)
        external
        returns (uint256 _actualAmount);

    function rebalanceDuration() external view returns (uint256);

    function getWithdrawPeriod() external view returns (uint256);

    function canRequestWithdraw(uint256 amount) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IPolicyBookFabric.sol";

interface IPolicyBookRegistry {
    struct PolicyBookStats {
        string symbol;
        address insuredContract;
        IPolicyBookFabric.ContractType contractType;
        uint256 maxCapacity;
        uint256 availableCompoundLiquidity;
        uint256 totalSTBLLiquidity;
        uint256 totalLeveragedLiquidity;
        uint256 APY;
        uint256 estMonthlyCost_UR;
        uint256 estMonthlyCost_CUR;
        bool whitelisted;
    }

    function policyBooksByInsuredAddress(address insuredContract) external view returns (address);

    function policyBookFacades(address facadeAddress) external view returns (address);

    /// @notice Adds PolicyBook to registry, access: PolicyFabric
    function add(
        address[] calldata insuredContracts,
        IPolicyBookFabric.ContractType contractType,
        address policyBook,
        address facadeAddress
    ) external;

    function updateInsuranceContract(
        address _policyBook,
        address _currentInsuranceContract,
        address _newInsuranceAddress
    ) external;

    ///@notice remove leverage pool before dein release, to be removed before release
    ////@dev migration function
    function removeLeveragePool() external;

    function whitelist(address policyBookAddress, bool whitelisted) external;

    /// @notice returns required allowances for the policybooks
    function getPoliciesPrices(
        address[] calldata policyBooks,
        uint256[] calldata epochsNumbers,
        uint256[] calldata coversTokens
    ) external view returns (uint256[] memory _durations, uint256[] memory _allowances);

    /// @notice Checks if provided address is a PolicyBook
    function isPolicyBook(address policyBook) external view returns (bool);

    /// @notice Checks if provided address is a policyBookFacade
    function isPolicyBookFacade(address _facadeAddress) external view returns (bool);

    /// @notice Checks if provided address is a user leverage pool
    function isLeveragePool(address policyBookAddress) external view returns (bool);

    /// @notice Returns number of registered PolicyBooks with certain contract type
    function countByType(IPolicyBookFabric.ContractType contractType)
        external
        view
        returns (uint256);

    /// @notice Returns number of registered PolicyBooks, access: ANY
    function count() external view returns (uint256);

    function countByTypeWhitelisted(IPolicyBookFabric.ContractType contractType)
        external
        view
        returns (uint256);

    function countWhitelisted() external view returns (uint256);

    /// @notice Listing registered PolicyBooks with certain contract type, access: ANY
    /// @return _policyBooksArr is array of registered PolicyBook addresses with certain contract type
    function listByType(
        IPolicyBookFabric.ContractType contractType,
        uint256 offset,
        uint256 limit
    ) external view returns (address[] memory _policyBooksArr);

    /// @notice Listing registered PolicyBooks, access: ANY
    /// @return _policyBooksArr is array of registered PolicyBook addresses
    function list(uint256 offset, uint256 limit)
        external
        view
        returns (address[] memory _policyBooksArr);

    function listByTypeWhitelisted(
        IPolicyBookFabric.ContractType contractType,
        uint256 offset,
        uint256 limit
    ) external view returns (address[] memory _policyBooksArr);

    function listWhitelisted(uint256 offset, uint256 limit)
        external
        view
        returns (address[] memory _policyBooksArr);

    /// @notice Listing registered PolicyBooks with stats and certain contract type, access: ANY
    function listWithStatsByType(
        IPolicyBookFabric.ContractType contractType,
        uint256 offset,
        uint256 limit
    ) external view returns (address[] memory _policyBooksArr, PolicyBookStats[] memory _stats);

    /// @notice Listing registered PolicyBooks with stats, access: ANY
    function listWithStats(uint256 offset, uint256 limit)
        external
        view
        returns (address[] memory _policyBooksArr, PolicyBookStats[] memory _stats);

    function listWithStatsByTypeWhitelisted(
        IPolicyBookFabric.ContractType contractType,
        uint256 offset,
        uint256 limit
    ) external view returns (address[] memory _policyBooksArr, PolicyBookStats[] memory _stats);

    function listWithStatsWhitelisted(uint256 offset, uint256 limit)
        external
        view
        returns (address[] memory _policyBooksArr, PolicyBookStats[] memory _stats);

    /// @notice Getting stats from policy books, access: ANY
    /// @param policyBooks is list of PolicyBooks addresses
    function stats(address[] calldata policyBooks)
        external
        view
        returns (PolicyBookStats[] memory _stats);

    /// @notice Return existing Policy Book contract, access: ANY
    /// @param insuredContract is contract address to lookup for created IPolicyBook
    function policyBookFor(address insuredContract) external view returns (address);

    /// @notice Getting stats from policy books, access: ANY
    /// @param insuredContracts is list of insuredContracts in registry
    function statsByInsuredContracts(address[] calldata insuredContracts)
        external
        view
        returns (PolicyBookStats[] memory _stats);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IPolicyBookFabric.sol";
import "./IClaimingRegistry.sol";

interface IPolicyRegistry {
    struct PolicyInfo {
        uint256 coverAmount;
        uint256 premium;
        uint256 startTime;
        uint256 endTime;
    }

    struct PolicyUserInfo {
        string symbol;
        address insuredContract;
        IPolicyBookFabric.ContractType contractType;
        uint256 coverTokens;
        uint256 startTime;
        uint256 endTime;
        uint256 paid;
        PolicyStatus policyStatus;
    }

    enum PolicyStatus {VALID, EXPIRED, ENDED, CLAIMING}

    function STILL_CLAIMABLE_FOR() external view returns (uint256);

    /// @notice Returns the number of the policy for the user, access: ANY
    /// @param _userAddr Policy holder address
    /// @return the number of police in the array
    function getPoliciesLength(address _userAddr) external view returns (uint256);

    /// @notice Shows whether the user has a policy, access: ANY
    /// @param _userAddr Policy holder address
    /// @param _policyBookAddr Address of policy book
    /// @return true if user has policy in specific policy book
    function policyExists(address _userAddr, address _policyBookAddr) external view returns (bool);

    /// @notice Returns information about current policy, access: ANY
    /// @param _userAddr Policy holder address
    /// @param _policyBookAddr Address of policy book
    /// @return true if user has valid policy in specific policy book
    function isPolicyValid(address _userAddr, address _policyBookAddr)
        external
        view
        returns (bool);

    /// @notice Returns information about current policy, access: ANY
    /// @param _userAddr Policy holder address
    /// @param _policyBookAddr Address of policy book
    /// @return true if user has active policy in specific policy book
    function isPolicyActive(address _userAddr, address _policyBookAddr)
        external
        view
        returns (bool);

    /// @notice returns current policy start time or zero
    function policyStartTime(address _userAddr, address _policyBookAddr)
        external
        view
        returns (uint256);

    /// @notice returns current policy end time or zero
    function policyEndTime(address _userAddr, address _policyBookAddr)
        external
        view
        returns (uint256);

    /// @notice Returns the array of the policy itself , access: ANY
    /// @param _userAddr Policy holder address
    /// @param _isActive If true, then returns an array with information about active policies, if false, about inactive
    /// @return _policiesCount is the number of police in the array
    /// @return _policyBooksArr is the array of policy books addresses
    /// @return _policies is the array of policies
    /// @return _policyStatuses parameter will show which button to display on the dashboard
    function getPoliciesInfo(
        address _userAddr,
        bool _isActive,
        uint256 _offset,
        uint256 _limit
    )
        external
        view
        returns (
            uint256 _policiesCount,
            address[] memory _policyBooksArr,
            PolicyInfo[] memory _policies,
            IClaimingRegistry.BookStatus[] memory _policyStatuses
        );

    function getPolicyInfo(address _userAddr, address _policyAddr)
        external
        view
        returns (PolicyInfo memory _policyInfo);

    /// @notice Getting stats from users of policy books, access: ANY
    function getUsersInfo(address[] calldata _users, address[] calldata _policyBooks)
        external
        view
        returns (PolicyUserInfo[] memory _stats);

    function getPoliciesArr(address _userAddr) external view returns (address[] memory _arr);

    /// @notice Adds a new policy to the list , access: ONLY POLICY BOOKS
    /// @param _userAddr is the user's address
    /// @param _coverAmount is the number of insured tokens
    /// @param _premium is the name of PolicyBook
    /// @param _durationDays is the number of days for which the insured
    function addPolicy(
        address _userAddr,
        uint256 _coverAmount,
        uint256 _premium,
        uint256 _durationDays
    ) external;

    /// @notice Removes the policy book from the list, access: ONLY POLICY BOOKS
    /// @param _userAddr is the user's address
    function removePolicy(address _userAddr) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IPolicyBookFabric.sol";
import "./IClaimingRegistry.sol";
import "./IPolicyBookFacade.sol";

interface ILeveragePool {
    struct LevFundsFactors {
        uint256 netMPL;
        uint256 netMPLn;
        address policyBookAddr;
    }

    enum WithdrawalStatus {NONE, PENDING, READY, EXPIRED}

    struct WithdrawalInfo {
        uint256 withdrawalAmountDEINx;
        uint256 withdrawalAmountSTBL;
        uint256 readyToWithdrawDate;
        bool withdrawalAllowed;
    }

    struct DEINMultiplierFactors {
        uint256 poolMultiplier;
        uint256 leverageProvided;
        uint256 multiplier;
    }

    function targetUR() external view returns (uint256);

    function d_ProtocolConstant() external view returns (uint256);

    function a1_ProtocolConstant() external view returns (uint256);

    function a2_ProtocolConstant() external view returns (uint256);

    function max_ProtocolConstant() external view returns (uint256);

    /// @return uint256 the amount of vStable stored in the pool
    function totalLiquidity() external view returns (uint256);

    /// @notice Returns type of contract this PolicyBook covers, access: ANY
    /// @return _type is type of contract
    function contractType() external view returns (IPolicyBookFabric.ContractType _type);

    function READY_TO_WITHDRAW_PERIOD() external view returns (uint256);

    function epochStartTime() external view returns (uint256);

    function withdrawalsInfo(address _userAddr)
        external
        view
        returns (
            uint256 _withdrawalAmountDEIN,
            uint256 _withdrawalAmountSTBL,
            uint256 _readyToWithdrawDate,
            bool _withdrawalAllowed
        );

    function __UserLeveragePool_init(
        IPolicyBookFabric.ContractType _contractType,
        string calldata _description,
        string calldata _projectSymbol
    ) external;

    /// @notice deploy lStable from leverage pool using 2 formulas: access by policybook.
    function deployLeverageStableToCoveragePools() external returns (uint256);

    /// @notice set the threshold % for re-evaluation of the lStable provided across all Coverage pools : access by owner
    /// @param threshold uint256 is the reevaluatation threshold
    function setRebalancingThreshold(uint256 threshold) external;

    /// @notice set the protocol constant : access by owner
    /// @param _targetUR uint256 target utitlization ration
    /// @param _d_ProtocolConstant uint256 D protocol constant
    /// @param  _a1_ProtocolConstant uint256 A1 protocol constant
    /// @param  _a2_ProtocolConstant uint256 A2 protocol constant
    /// @param _max_ProtocolConstant uint256 the max % included
    function setProtocolConstant(
        uint256 _targetUR,
        uint256 _d_ProtocolConstant,
        uint256 _a1_ProtocolConstant,
        uint256 _a2_ProtocolConstant,
        uint256 _max_ProtocolConstant
    ) external;

    /// @notice add the portion of 80% of premium to user leverage pool where the leverage provide lstable : access policybook
    /// add the 20% of premium + portion of 80% of premium where reisnurance pool participate in coverage pools (vStable)  : access policybook
    /// @param epochsNumber uint256 the number of epochs which the policy holder will pay a premium for
    /// @param  premiumAmount uint256 the premium amount which is a portion of 80% of the premium
    function addPremium(uint256 epochsNumber, uint256 premiumAmount) external;

    /// @notice Used to get a list of coverage pools which get leveraged , use with count()
    /// @return _coveragePools a list containing policybook addresses
    function listleveragedCoveragePools(uint256 offset, uint256 limit)
        external
        view
        returns (address[] memory _coveragePools);

    /// @notice get count of coverage pools which get leveraged
    function countleveragedCoveragePools() external view returns (uint256);

    function updateLiquidity(uint256 _lostLiquidity) external;

    function forceUpdateDEINCoverStakingRewardMultiplier() external;

    function getEpoch(uint256 time) external view returns (uint256);

    /// @notice get STBL equivalent
    function convertDEINXToSTBL(uint256 _amount) external view returns (uint256);

    /// @notice get DEINX equivalent
    function convertSTBLToDEINX(uint256 _amount) external view returns (uint256);

    /// @notice function to get precise current cover and liquidity
    function getNewCoverAndLiquidity()
        external
        view
        returns (
            uint256 newTotalCoverTokens,
            uint256 newTotalLiquidity,
            uint256 availableCompoundLiquidity
        );

    function updateEpochsInfo() external;

    function secondsToEndCurrentEpoch() external view returns (uint256);

    /// @notice Let user to add liquidity by supplying stable coin, access: ANY
    /// @param _liquidityAmount is amount of stable coin tokens to secure
    /// @param _lock locking period
    function addLiquidity(uint256 _liquidityAmount, uint256 _lock) external;

    function getAvailableDEINXWithdrawableAmount(address _userAddr)
        external
        view
        returns (uint256);

    function getWithdrawalStatus(address _userAddr) external view returns (WithdrawalStatus);

    function requestWithdrawalWithPermit(
        uint256 _tokensToWithdraw,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    function requestWithdrawal(uint256 _tokensToWithdraw) external;

    function unlockTokens() external;

    /// @notice Let user to withdraw deposited liqiudity, access: ANY
    function withdrawLiquidity() external;

    function getAPY() external view returns (uint256);

    function whitelisted() external view returns (bool);

    function whitelist(bool _whitelisted) external;

    /// @notice set max total liquidity for the pool
    /// @param _maxCapacities uint256 the max total liquidity
    function setMaxCapacities(uint256 _maxCapacities) external;

    /// @notice Getting number stats, access: ANY
    /// @return _maxCapacities is a max liquidity of the pool
    /// @return _availableCompoundLiquidity is becuase to follow the same function in policy book
    /// @return _totalSTBLLiquidity is PolicyBook's liquidity
    /// @return _totalLeveragedLiquidity is becuase to follow the same function in policy book
    /// @return _annualProfitYields is its APY
    /// @return _estMonthlyCost_UR is becuase to follow the same function in policy book
    /// @return _estMonthlyCost_CUR is becuase to follow the same function in policy book
    function numberStats()
        external
        view
        returns (
            uint256 _maxCapacities,
            uint256 _availableCompoundLiquidity,
            uint256 _totalSTBLLiquidity,
            uint256 _totalLeveragedLiquidity,
            uint256 _annualProfitYields,
            uint256 _estMonthlyCost_UR,
            uint256 _estMonthlyCost_CUR
        );

    /// @notice Getting info, access: ANY
    /// @return _symbol is the symbol of PolicyBook (deinXCover)
    /// @return _insuredContract is an addres of insured contract
    /// @return _contractType is becuase to follow the same function in policy book
    /// @return _whitelisted is a state of whitelisting
    function info()
        external
        view
        returns (
            string memory _symbol,
            address _insuredContract,
            IPolicyBookFabric.ContractType _contractType,
            bool _whitelisted
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

interface IClaimVoting {
    enum VoteStatus {ANONYMOUS, EXPOSED, CLOSED}
    enum VotePublicStatus {ANONYMOUS, EXPOSED, TO_RECEIVE, CLOSED}
    enum ListOption {VOTED, AWAITING}

    struct Voting {
        uint256 voteCount;
        uint256 votedAverageWithdrawalAmount;
        uint256 totalStakedVoted;
        uint256 votedYesTotalPower;
        uint256 votedNoTotalPower;
        uint256 votedYesPercentage;
    }

    struct VoteInfo {
        uint256 claimIndex;
        address voter;
        string encryptedVote;
        bytes32 finalHash;
        uint256 votingReputation;
        EnumerableSet.UintSet tokenIDs;
        VoteStatus voteStatus;
        uint256 suggestedAmount;
    }

    struct VotePublicInfo {
        uint256 voteIndex;
        uint256 claimIndex;
        uint256 votingReputation;
        uint256 claimAmount;
        VotePublicStatus votePublicStatus;
        uint256 suggestedAmount;
        uint256 timeRemaining;
        uint256 deinReward;
        uint256 deinPenalty;
        uint256 newReputation;
    }

    function getVotesCount(uint256 claimIndex) external view returns (uint256 countVoteOnClaim);

    function getRepartition(uint256 claimIndex)
        external
        view
        returns (uint256 yesPercentage, uint256 noPercentage);

    function canUnlock(uint256 tokenID, address user) external view returns (bool);

    function canVote(uint256 claimIndex, address voter) external view returns (bool);

    function canExpose(uint256 claimIndex, address voter) external view returns (bool);

    function canReceive(uint256 claimIndex, address voter) external view returns (bool);

    /// @notice anonymously vote
    function anonymouslyVoteBatch(
        uint256[] calldata claimIndexes,
        bytes32[] calldata finalHashes,
        string[] calldata encryptedVotes,
        uint256[] calldata tokenIDs
    ) external;

    /// @notice expose vote
    function exposeVoteBatch(
        uint256[] calldata claimIndexes,
        uint256[] calldata suggestedAmounts,
        bytes32[] calldata hashedSignaturesOfClaims,
        bool[] calldata isConfirmed
    ) external;

    /// @notice resolve voting, only access by ClaimingRegistry
    function resolveVoting(uint256 claimIndex)
        external
        returns (
            uint256 totalStakedVoted,
            uint256 votedYesPercentage,
            uint256 claimRefund
        );

    /// @notice receive vote results
    function receiveVoteResultBatch(uint256[] calldata claimIndexes) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IClaimingRegistry.sol";

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

interface IDemandBook {
    struct DemandInfo {
        address demander;
        address protocol;
        uint256 coverageAmount;
        uint256 depositedLiquidity; // total deposited liquidity
        uint256 currentLiquidity; // total deposited liquidity minus lost amount in case of liquidity withdrawal, refund claim and defi loss
        uint256 premiumAmount; // premiumAmount = rewardAmount + protocolFeeAmount
        uint256 protocolFeeAmount;
        bool isPremiumWithdrawn;
        uint256 epochAmount; // in days
        uint256 creationTime;
        uint256 startTime;
        uint256 endTime;
    }

    struct PublicDemandInfo {
        uint256 demandIndex;
        address demander;
        address protocol;
        uint256 coverageAmount;
        uint256 currentLiquidity;
        uint256 premiumAmount; // premiumAmount = rewardAmount + protocolFeeAmount
        uint256 rewardAmount;
        uint256 epochAmount;
        uint256 creationTime;
        uint256 startTime;
        uint256 endTime;
        DemandStatus status;
        uint256 time;
    }

    enum ListOption {ALL, CREATED, INVESTED}
    enum DemandStatus {OPEN, PENDING, CLOSED, ACTIVE, ENDED} // ACTIVE = VALID + EXPIRED

    function OPEN_PERIOD() external view returns (uint256);

    function PENDING_PERIOD() external view returns (uint256);

    function STILL_CLAIMABLE_FOR() external view returns (uint256);

    function demandExists(uint256 demandIndex) external view returns (bool);

    function demandInfo(uint256 demandIndex)
        external
        view
        returns (
            address demander,
            address protocol,
            uint256 coverageAmount,
            uint256 depositedLiquidity,
            uint256 currentLiquidity,
            uint256 premiumAmount,
            uint256 protocolFeeAmount,
            bool isPremiumWithdrawn,
            uint256 epochAmount,
            uint256 creationTime,
            uint256 startTime,
            uint256 endTime
        );

    function getDemandAmountInfo(uint256 demandIndex)
        external
        view
        returns (
            uint256 coverageAmount,
            uint256 depositedLiquidity,
            uint256 currentLiquidity,
            uint256 premiumAmount,
            uint256 protocolFeeAmount,
            uint256 rewardAmount
        );

    function getDemandDemanderInfo(uint256 demandIndex)
        external
        view
        returns (address demander, bool isPremiumWithdrawn);

    function isDemandActive(address demander, uint256 demandIndex) external view returns (bool);

    function getDemandStatus(uint256 demandIndex) external view returns (DemandStatus status);

    function getDemandIndex(address _demander, address _protocol) external view returns (uint256);

    function demandStartTime(uint256 demandIndex) external view returns (uint256);

    function countAllDemands() external view returns (uint256);

    function countAllValidatedDemands() external view returns (uint256);

    function countCreatedDemands(address _demander) external view returns (uint256);

    function countInvestedDemands(address _provider) external view returns (uint256);

    function listValidatedDemands(uint256 offset, uint256 limit)
        external
        view
        returns (uint256[] memory _demandIndexesArr);

    function getListDemands(
        uint256 offset,
        uint256 limit,
        ListOption listOption
    ) external view returns (PublicDemandInfo[] memory publicDemandInfo);

    function createDemand(
        address _protocol,
        uint256 _coverageAmount,
        uint256 _premiumAmount,
        uint256 _epochAmount
    ) external;

    function updateLiquidity(
        uint256 demandIndex,
        address _provider,
        uint256 _liquidityAmount,
        bool _isAddedLiquidity,
        bool _nullCurrentLiquidity
    ) external;

    function updateLiquidity(uint256 demandIndex, uint256 _liquidityLoss) external;

    function validateDemand(uint256 demandIndex) external;

    function forceValidateDemand(uint256 demandIndex) external;

    function updatePremium(uint256 demandIndex) external;

    function getClaimApprovalAmount(uint256 demandIndex) external view returns (uint256);

    function submitClaimAndInitializeVoting(uint256 demandIndex, string calldata evidenceURI)
        external;

    function submitClaimAndInitializeVotingWithPermit(
        uint256 demandIndex,
        string calldata _evidenceURI,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    function submitAppealAndInitializeVoting(uint256 demandIndex, string calldata evidenceURI)
        external;

    function submitAppealAndInitializeVotingWithPermit(
        uint256 demandIndex,
        string calldata _evidenceURI,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    function commitWithdrawnClaim(uint256 demandIndex) external;

    function endActiveDemand(uint256 demandIndex) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface ICompoundPool {
    function getCompoundLiquidity() external view returns (uint256);

    function poolsUsage(address _policyBook) external view returns (uint256);

    function getCompoundLiquidityForPool(address _policyBookAddress)
        external
        view
        returns (uint256);

    function deployLiquidity(address _policyBook, uint256 _amount) external;

    function undeployLiquidity(address _policyBook, uint256 _amount) external;

    function canWithdraw(uint256 _withdrawAmount, bool isLPToken) external view returns (bool);

    function getDEINLPTokenPrice() external view returns (uint256);

    function liquidate(
        address _policyBook,
        address claimer,
        uint256 liquidationAmount
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../interfaces/IContractsRegistry.sol";

abstract contract AbstractDependant {
    /// @dev keccak256(AbstractDependant.setInjector(address)) - 1
    bytes32 private constant _INJECTOR_SLOT =
        0xd6b8f2e074594ceb05d47c27386969754b6ad0c15e5eb8f691399cd0be980e76;

    modifier onlyInjectorOrZero() {
        address _injector = injector();

        require(_injector == address(0) || _injector == msg.sender, "Dependant: Not an injector");
        _;
    }

    function setInjector(address _injector) external onlyInjectorOrZero {
        bytes32 slot = _INJECTOR_SLOT;

        assembly {
            sstore(slot, _injector)
        }
    }

    /// @dev has to apply onlyInjectorOrZero() modifier
    function setDependencies(IContractsRegistry) external virtual;

    function injector() public view returns (address _injector) {
        bytes32 slot = _INJECTOR_SLOT;

        assembly {
            _injector := sload(slot)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../interfaces/IClaimingRegistry.sol";

interface IRewardPool {
    function rebalanceStakingPools() external;

    function rebalanceVoteReward(uint256 claimIndex) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

interface IDEINNFTStaking {
    function isLocked(uint256[] calldata tokenIDs, address user) external view returns (bool);

    function totalLocked() external view returns (uint256);

    function getUserLockedNFTs(address user) external view returns (uint256[] memory _tokenIDs);

    function lockNFT(uint256 tokenID) external;

    function unlockNFT(uint256 tokenID) external;

    function applyPenalty(address user, uint256 penalty) external;

    function removeLockedNFT(address user, uint256 tokenID) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IPriceFeed {
    enum Token {DEIN, ETH}

    function howManyDEINsInUSDT(uint256 usdtAmount) external view returns (uint256);

    function howManyUSDTsInDEIN(uint256 deinAmount) external view returns (uint256);

    function howManyETHsInUSDT(uint256 usdtAmount) external view returns (uint256);

    function howManyUSDTsInETH(uint256 ethAmount) external view returns (uint256);

    function updateTokensPrice() external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
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
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

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
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
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
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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

        /// @solidity memory-safe-assembly
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
     * @dev Returns the number of values in the set. O(1).
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

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../Globals.sol";

interface IPolicyBookFabric {
    /// @dev update getContractTypes() in RewardGenerator each time this enum is modified
    enum ContractType {CONTRACT, STABLECOIN, SERVICE, EXCHANGE, VARIOUS, CUSTODIAN}

    /// @notice Create new Policy Book contract, access: ANY
    ///@notice disable SM //address _shieldMiningToken
    /// @param _insuranceContracts is Contracts to create policy book for
    /// @param _insuranceContractsNetworks is network of the insurance contract
    /// @param _contractType is Contract to create policy book for
    /// @param _description is bmiXCover token desription for this policy book
    /// @param _projectSymbol replaces x in bmiXCover token symbol
    /// @param _initialDeposit is an amount user deposits on creation (addLiquidity())
    /// @return _policyBook is address of created contract
    function create(
        address[] calldata _insuranceContracts,
        Networks[] calldata _insuranceContractsNetworks,
        ContractType _contractType,
        string calldata _description,
        string calldata _projectSymbol,
        uint256 _initialDeposit
    ) external returns (address);

    function createLeveragePools(
        ContractType _contractType,
        string calldata _description,
        string calldata _projectSymbol
    ) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IPolicyBook.sol";
import "./IPolicyBookFabric.sol";
import "./ILeveragePool.sol";

import "../Globals.sol";

interface IPolicyBookFacade {
    struct InsuranceContract {
        Networks networkId;
        address insuranceContract;
    }

    function policyBook() external view returns (IPolicyBook);

    function userLiquidity(address account) external view returns (uint256);

    /// @notice leverage funds deployed by user leverage pool
    function LUuserLeveragePool(address userLeveragePool) external view returns (uint256);

    /// @notice total leverage funds deployed to the pool sum of (VUreinsurnacePool,LUreinsurnacePool,LUuserLeveragePool)
    function totalLeveragedLiquidity() external view returns (uint256);

    function userleveragedMPL() external view returns (uint256);

    function rebalancingThreshold() external view returns (uint256);

    function currentPricingModel() external view returns (uint256);

    /// @notice policyBookFacade initializer
    /// @param pbProxy polciybook address upgreadable cotnract.
    function __PolicyBookFacade_init(
        address[] calldata _insuranceContract,
        Networks[] calldata _insuranceContractsNetworks,
        address pbProxy,
        address liquidityProvider,
        uint256 initialDeposit
    ) external;

    function updateInsuranceContracts(
        Networks _network,
        address currentInsuranceAddress,
        address _newInsuranceAddress
    ) external;

    /// @notice Let user to buy policy by supplying stable coin, access: ANY
    /// @param _epochsNumber period policy will cover
    /// @param _coverTokens amount paid for the coverage
    function buyPolicy(uint256 _epochsNumber, uint256 _coverTokens) external;

    /// @param _holder who owns coverage
    /// @param _epochsNumber period policy will cover
    /// @param _coverTokens amount paid for the coverage
    function buyPolicyFor(
        address _holder,
        uint256 _epochsNumber,
        uint256 _coverTokens
    ) external;

    /// @param _epochsNumber period policy will cover
    /// @param _coverTokens amount paid for the coverage
    /// @param _distributor if it was sold buy a whitelisted distributor, it is distributor address to receive fee (commission)
    function buyPolicyFromDistributor(
        uint256 _epochsNumber,
        uint256 _coverTokens,
        address _distributor
    ) external;

    /// @param _buyer who is buying the coverage
    /// @param _epochsNumber period policy will cover
    /// @param _coverTokens amount paid for the coverage
    /// @param _distributor if it was sold buy a whitelisted distributor, it is distributor address to receive fee (commission)
    function buyPolicyFromDistributorFor(
        address _buyer,
        uint256 _epochsNumber,
        uint256 _coverTokens,
        address _distributor
    ) external;

    function addLiquidityFor(
        address _liquidityHolderAddr,
        uint256 _liquidityAmount,
        uint256 _lock
    ) external;

    /// @notice Let user to add liquidity by supplying stable coin and stake it,
    /// @dev access: ANY
    function addLiquidity(uint256 _liquidityAmount, uint256 _lock) external;

    /// @notice Let user to withdraw deposited liqiudity, access: ANY
    function withdrawLiquidity() external;

    /// @notice submits new claim of the policy book
    function submitClaimAndInitializeVoting(string calldata evidenceURI) external;

    function submitClaimAndInitializeVotingWithPermit(
        string calldata evidenceURI,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    /// @notice submits new appeal claim of the policy book
    function submitAppealAndInitializeVoting(string calldata evidenceURI) external;

    function submitAppealAndInitializeVotingWithPermit(
        string calldata evidenceURI,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    function getAvailableDEINXWithdrawableAmount(address _userAddr)
        external
        view
        returns (uint256);

    function getPremiumDistributionEpoch() external view returns (uint256);

    function getPremiumsDistribution(uint256 lastEpoch, uint256 currentEpoch)
        external
        view
        returns (
            int256 currentDistribution,
            uint256 distributionEpoch,
            uint256 newTotalLiquidity
        );

    /// @notice forces an update of RewardsGenerator multiplier
    function forceUpdateDEINCoverStakingRewardMultiplier() external;

    /// @notice view function to get precise policy price
    /// @param _holder the address of the holder
    /// @param _epochsNumber is number of epochs to cover
    /// @param _coverTokens is number of tokens to cover
    /// @param newTotalCoverTokens is number of total tokens cover
    /// @param newTotalLiquidity is number of total liquidity
    /// @param _availableCompoundLiquidity the available CompoundLiquidity for the pool
    /// @param _deployedCompoundedLiquidity the deployed amount from compound liquidity for the cover
    /// @return totalSeconds is number of seconds to cover
    /// @return totalPrice is the policy price which will pay by the buyer
    function getPolicyPrice(
        address _holder,
        uint256 _epochsNumber,
        uint256 _coverTokens,
        uint256 newTotalCoverTokens,
        uint256 newTotalLiquidity,
        uint256 _availableCompoundLiquidity,
        uint256 _deployedCompoundedLiquidity
    ) external view returns (uint256 totalSeconds, uint256 totalPrice);

    function getPolicyPrice(uint256 _epochsNumber, uint256 _coverTokens)
        external
        view
        returns (uint256 totalSeconds, uint256 totalPrice);

    function secondsToEndCurrentEpoch() external view returns (uint256);

    /// @notice deploy leverage funds (RP lStable, ULP lStable)
    /// @param  deployedAmount uint256 the deployed amount to be added or substracted from the total liquidity
    function deployLeverageFundsAfterRebalance(uint256 deployedAmount) external;

    ///@dev in case ur changed of the pools by commit a claim or policy expired
    function reevaluateProvidedLeverageStable() external;

    /// @notice set the MPL for the leverage pool
    /// @param _leveragePoolMPL uint256 value of the user leverage MPL
    function setMPLs(uint256 _leveragePoolMPL) external;

    /// @notice sets the rebalancing threshold value
    /// @param _newRebalancingThreshold uint256 rebalancing threshhold value
    function setRebalancingThreshold(uint256 _newRebalancingThreshold) external;

    /// @notice sets current pricing model
    /// @param _currentPricingModel uint256 is the pricing model index applied to the pool
    function setPricingModel(uint256 _currentPricingModel) external;

    /// @notice returns how many DEIN tokens needs to approve in order to submit a claim
    function getClaimApprovalAmount(address user) external view returns (uint256);

    /// @notice upserts a withdraw request
    /// @dev prevents adding a request if an already pending or ready request is open.
    /// @param _tokensToWithdraw uint256 amount of tokens to withdraw
    function requestWithdrawal(uint256 _tokensToWithdraw) external;

    function requestWithdrawalWithPermit(
        uint256 _tokensToWithdraw,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    function listUserLeveragePools(uint256 offset, uint256 limit)
        external
        view
        returns (address[] memory _userLeveragePools);

    function countUserLeveragePools() external view returns (uint256);

    /// @notice function to get precise current cover, liquidity ,  available Compounded Liquidity
    function getNewCoverAndLiquidity()
        external
        view
        returns (
            uint256 newTotalCoverTokens,
            uint256 newTotalLiquidity,
            uint256 availableCompoundLiquidity
        );

    function getAPY() external view returns (uint256);

    /// @notice Getting user stats, access: ANY
    function userStats(address _user) external view returns (IPolicyBook.PolicyHolder memory);

    /// @notice Getting number stats, access: ANY
    /// @return _maxCapacities is a max token amount that a user can buy
    /// @return _availableCompoundLiquidity the available CompoundLiquidity for the pool which increases the pool capacity
    /// @return _totalSTBLLiquidity is PolicyBook's liquidity
    /// @return _totalLeveragedLiquidity is PolicyBook's leveraged liquidity
    /// @return _annualProfitYields is its APY
    /// @return _estMonthlyCost_UR is estimate monthly cost percentage of cover tokens that is required to be paid for 1 month of insurance based on UR
    /// @return _estMonthlyCost_CUR is estimate monthly cost percentage of cover tokens that is required to be paid for 1 month of insurance based on CUR
    function numberStats()
        external
        view
        returns (
            uint256 _maxCapacities,
            uint256 _availableCompoundLiquidity,
            uint256 _totalSTBLLiquidity,
            uint256 _totalLeveragedLiquidity,
            uint256 _annualProfitYields,
            uint256 _estMonthlyCost_UR,
            uint256 _estMonthlyCost_CUR
        );

    /// @notice Getting info, access: ANY
    /// @return _symbol is the symbol of PolicyBook (deinXCover)
    /// @return _insuredContract is an addres of insured contract
    /// @return _contractType is a type of insured contract
    /// @return _whitelisted is a state of whitelisting
    function info()
        external
        view
        returns (
            string memory _symbol,
            address _insuredContract,
            IPolicyBookFabric.ContractType _contractType,
            bool _whitelisted
        );

    function listInsuranceContracts()
        external
        view
        returns (InsuranceContract[] memory _insuranceContracts);

    function countInsuranceContracts() external view returns (uint256);

    ///@notice migrate insurance contracts from single state to a list ,to be removed before release
    /// migrate pricing modelfrom bool state to index of pricing model
    ///@dev migration function
    function migrate() external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

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