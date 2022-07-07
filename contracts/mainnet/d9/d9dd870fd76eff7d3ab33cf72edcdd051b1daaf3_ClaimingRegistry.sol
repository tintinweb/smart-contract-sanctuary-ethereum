// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./libraries/DecimalsConverter.sol";

import "./interfaces/IContractsRegistry.sol";
import "./interfaces/IClaimingRegistry.sol";
import "./interfaces/IPolicyBook.sol";
import "./interfaces/IPolicyRegistry.sol";
import "./interfaces/IPolicyBookRegistry.sol";
import "./interfaces/ILeveragePortfolio.sol";
import "./interfaces/ICapitalPool.sol";
import "./interfaces/IClaimVoting.sol";

import "./abstract/AbstractDependant.sol";
import "./Globals.sol";

contract ClaimingRegistry is IClaimingRegistry, Initializable, AbstractDependant {
    using SafeMath for uint256;
    using Math for uint256;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 internal constant ANONYMOUS_VOTING_DURATION = 1 weeks;
    uint256 internal constant EXPOSE_VOTE_DURATION = 1 weeks;

    uint256 internal constant PRIVATE_CLAIM_DURATION = 3 days;
    uint256 internal constant VIEW_VERDICT_DURATION = 10 days;
    uint256 public constant READY_TO_WITHDRAW_PERIOD = 8 days;

    IPolicyRegistry public policyRegistry;
    address public claimVotingAddress;

    mapping(address => EnumerableSet.UintSet) internal _myClaims; // claimer -> claim indexes

    mapping(address => mapping(address => uint256)) internal _allClaimsToIndex; // book -> claimer -> index

    mapping(uint256 => ClaimInfo) internal _allClaimsByIndexInfo; // index -> info

    EnumerableSet.UintSet internal _pendingClaimsIndexes;
    EnumerableSet.UintSet internal _allClaimsIndexes;

    uint256 private _claimIndex;

    address internal policyBookAdminAddress;

    ICapitalPool public capitalPool;

    // claim withdraw
    EnumerableSet.UintSet internal _withdrawClaimRequestIndexList;
    mapping(uint256 => ClaimWithdrawalInfo) public override claimWithdrawalInfo; // index -> info
    //reward withdraw
    EnumerableSet.AddressSet internal _withdrawRewardRequestVoterList;
    mapping(address => RewardWithdrawalInfo) public override rewardWithdrawalInfo; // address -> info
    IClaimVoting public claimVoting;
    IPolicyBookRegistry public policyBookRegistry;
    mapping(address => EnumerableSet.UintSet) internal _policyBookClaims; // book -> index
    ERC20 public stblToken;
    uint256 public stblDecimals;

    event AppealPending(address claimer, address policyBookAddress, uint256 claimIndex);
    event ClaimPending(address claimer, address policyBookAddress, uint256 claimIndex);
    event ClaimAccepted(
        address claimer,
        address policyBookAddress,
        uint256 claimAmount,
        uint256 claimIndex
    );
    event ClaimRejected(address claimer, address policyBookAddress, uint256 claimIndex);
    event ClaimExpired(address claimer, address policyBookAddress, uint256 claimIndex);
    event AppealRejected(address claimer, address policyBookAddress, uint256 claimIndex);
    event WithdrawalRequested(
        address _claimer,
        uint256 _claimRefundAmount,
        uint256 _readyToWithdrawDate
    );
    event ClaimWithdrawn(address _claimer, uint256 _claimRefundAmount);
    event RewardWithdrawn(address _voter, uint256 _rewardAmount);

    modifier onlyClaimVoting() {
        require(
            claimVotingAddress == msg.sender,
            "ClaimingRegistry: Caller is not a ClaimVoting contract"
        );
        _;
    }

    modifier onlyPolicyBookAdmin() {
        require(
            policyBookAdminAddress == msg.sender,
            "ClaimingRegistry: Caller is not a PolicyBookAdmin"
        );
        _;
    }

    modifier withExistingClaim(uint256 index) {
        require(claimExists(index), "ClaimingRegistry: This claim doesn't exist");
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
        claimVotingAddress = _contractsRegistry.getClaimVotingContract();
        policyBookAdminAddress = _contractsRegistry.getPolicyBookAdminContract();
        capitalPool = ICapitalPool(_contractsRegistry.getCapitalPoolContract());
        policyBookRegistry = IPolicyBookRegistry(
            _contractsRegistry.getPolicyBookRegistryContract()
        );
        claimVoting = IClaimVoting(_contractsRegistry.getClaimVotingContract());
        stblToken = ERC20(_contractsRegistry.getUSDTContract());
        stblDecimals = stblToken.decimals();
    }

    function _isClaimAwaitingCalculation(uint256 index)
        internal
        view
        withExistingClaim(index)
        returns (bool)
    {
        return (_allClaimsByIndexInfo[index].status == ClaimStatus.PENDING &&
            _allClaimsByIndexInfo[index].dateSubmitted.add(votingDuration(index)) <=
            block.timestamp);
    }

    function _isClaimAppealExpired(uint256 index)
        internal
        view
        withExistingClaim(index)
        returns (bool)
    {
        return (_allClaimsByIndexInfo[index].status == ClaimStatus.REJECTED_CAN_APPEAL &&
            _allClaimsByIndexInfo[index].dateEnded.add(policyRegistry.STILL_CLAIMABLE_FOR()) <=
            block.timestamp);
    }

    function _isClaimExpired(uint256 index) internal view withExistingClaim(index) returns (bool) {
        return (_allClaimsByIndexInfo[index].status == ClaimStatus.PENDING &&
            _allClaimsByIndexInfo[index].dateSubmitted.add(validityDuration(index)) <=
            block.timestamp);
    }

    function anonymousVotingDuration(uint256 index)
        public
        view
        override
        withExistingClaim(index)
        returns (uint256)
    {
        return ANONYMOUS_VOTING_DURATION;
    }

    function votingDuration(uint256 index) public view override returns (uint256) {
        return anonymousVotingDuration(index).add(EXPOSE_VOTE_DURATION);
    }

    function validityDuration(uint256 index)
        public
        view
        override
        withExistingClaim(index)
        returns (uint256)
    {
        return votingDuration(index).add(VIEW_VERDICT_DURATION);
    }

    function anyoneCanCalculateClaimResultAfter(uint256 index)
        public
        view
        override
        returns (uint256)
    {
        return votingDuration(index).add(PRIVATE_CLAIM_DURATION);
    }

    function canCalculateClaim(uint256 index, address calculator)
        external
        view
        override
        returns (bool)
    {
        // TODO invert order condition to prevent duplicate storage hits
        return
            canClaimBeCalculatedByAnyone(index) ||
            _allClaimsByIndexInfo[index].claimer == calculator;
    }

    function canBuyNewPolicy(address buyer, address policyBookAddress) external override {
        require(msg.sender == policyBookAddress, "ClaimingRegistry: Not allowed");

        bool previousEnded = !policyRegistry.isPolicyActive(buyer, policyBookAddress);
        uint256 index = _allClaimsToIndex[policyBookAddress][buyer];

        require(
            (previousEnded &&
                (!claimExists(index) ||
                    (!_pendingClaimsIndexes.contains(index) &&
                        claimStatus(index) != ClaimStatus.REJECTED_CAN_APPEAL))) ||
                (!previousEnded && !claimExists(index)),
            "PB: Claim is pending"
        );

        if (!previousEnded) {
            IPolicyBook(policyBookAddress).endActivePolicy(buyer);
        }
    }

    function canWithdrawLockedBMI(uint256 index) public view returns (bool) {
        return
            (_allClaimsByIndexInfo[index].status == ClaimStatus.EXPIRED) ||
            (_allClaimsByIndexInfo[index].status == ClaimStatus.ACCEPTED &&
                _withdrawClaimRequestIndexList.contains(index) &&
                getClaimWithdrawalStatus(index) == WithdrawalStatus.EXPIRED &&
                !policyRegistry.isPolicyActive(
                    _allClaimsByIndexInfo[index].claimer,
                    _allClaimsByIndexInfo[index].policyBookAddress
                ));
    }

    function getClaimWithdrawalStatus(uint256 index)
        public
        view
        override
        returns (WithdrawalStatus)
    {
        if (claimWithdrawalInfo[index].readyToWithdrawDate == 0) {
            return WithdrawalStatus.NONE;
        }

        if (block.timestamp < claimWithdrawalInfo[index].readyToWithdrawDate) {
            return WithdrawalStatus.PENDING;
        }

        if (
            block.timestamp >=
            claimWithdrawalInfo[index].readyToWithdrawDate.add(READY_TO_WITHDRAW_PERIOD)
        ) {
            return WithdrawalStatus.EXPIRED;
        }

        return WithdrawalStatus.READY;
    }

    function getRewardWithdrawalStatus(address voter)
        public
        view
        override
        returns (WithdrawalStatus)
    {
        if (rewardWithdrawalInfo[voter].readyToWithdrawDate == 0) {
            return WithdrawalStatus.NONE;
        }

        if (block.timestamp < rewardWithdrawalInfo[voter].readyToWithdrawDate) {
            return WithdrawalStatus.PENDING;
        }

        if (
            block.timestamp >=
            rewardWithdrawalInfo[voter].readyToWithdrawDate.add(READY_TO_WITHDRAW_PERIOD)
        ) {
            return WithdrawalStatus.EXPIRED;
        }

        return WithdrawalStatus.READY;
    }

    function hasProcedureOngoing(address poolAddress) external view override returns (bool) {
        if (policyBookRegistry.isUserLeveragePool(poolAddress)) {
            ILeveragePortfolio userLeveragePool = ILeveragePortfolio(poolAddress);
            address[] memory _coveragePools =
                userLeveragePool.listleveragedCoveragePools(
                    0,
                    userLeveragePool.countleveragedCoveragePools()
                );

            for (uint256 i = 0; i < _coveragePools.length; i++) {
                if (
                    _hasProcedureOngoing(
                        _coveragePools[i],
                        getPolicyBookClaimsCount(_coveragePools[i])
                    )
                ) {
                    return true;
                }
            }
        } else {
            if (_hasProcedureOngoing(poolAddress, getPolicyBookClaimsCount(poolAddress))) {
                return true;
            }
        }
        return false;
    }

    function getPolicyBookClaimsCount(address policyBookAddress) internal view returns (uint256) {
        return _policyBookClaims[policyBookAddress].length();
    }

    function _hasProcedureOngoing(address policyBookAddress, uint256 limit)
        internal
        view
        returns (bool hasProcedure)
    {
        for (uint256 i = 0; i < limit; i++) {
            uint256 index = _policyBookClaims[policyBookAddress].at(i);
            ClaimStatus status = claimStatus(index);
            address claimer = _allClaimsByIndexInfo[index].claimer;
            if (
                !(status == ClaimStatus.EXPIRED || // has expired
                    status == ClaimStatus.REJECTED || // has been rejected || appeal expired
                    (status == ClaimStatus.ACCEPTED &&
                        getClaimWithdrawalStatus(index) == WithdrawalStatus.NONE) || // has been accepted and withdrawn or has withdrawn locked BMI at policy end
                    (status == ClaimStatus.ACCEPTED &&
                        getClaimWithdrawalStatus(index) == WithdrawalStatus.EXPIRED &&
                        !policyRegistry.isPolicyActive(claimer, policyBookAddress))) // has been accepted and never withdrawn but cannot request withdraw anymore
            ) {
                return true;
            }
        }
    }

    function submitClaim(
        address claimer,
        address policyBookAddress,
        string calldata evidenceURI,
        uint256 cover,
        bool appeal
    ) external override onlyClaimVoting returns (uint256 _newClaimIndex) {
        uint256 index = _allClaimsToIndex[policyBookAddress][claimer];
        ClaimStatus status =
            _myClaims[claimer].contains(index) ? claimStatus(index) : ClaimStatus.CAN_CLAIM;
        bool active = policyRegistry.isPolicyActive(claimer, policyBookAddress);

        /* (1) a new claim or a claim after rejected appeal (policy has to be active)
         * (2) a regular appeal (appeal should not be expired)
         * (3) a new claim cycle after expired appeal or a NEW policy when OLD one is accepted
         *     (PB shall not allow user to buy new policy when claim is pending or REJECTED_CAN_APPEAL)
         *     (policy has to be active)
         */
        require(
            (!appeal && active && status == ClaimStatus.CAN_CLAIM) ||
                (appeal && status == ClaimStatus.REJECTED_CAN_APPEAL) ||
                (!appeal && active && status == ClaimStatus.EXPIRED) ||
                (!appeal &&
                    active &&
                    (status == ClaimStatus.REJECTED ||
                        (policyRegistry.policyStartTime(claimer, policyBookAddress) >
                            _allClaimsByIndexInfo[index].dateSubmitted &&
                            status == ClaimStatus.ACCEPTED))) ||
                (!appeal &&
                    active &&
                    status == ClaimStatus.ACCEPTED &&
                    !_withdrawClaimRequestIndexList.contains(index)),
            "ClaimingRegistry: The claimer can't submit this claim"
        );

        if (appeal) {
            _allClaimsByIndexInfo[index].status = ClaimStatus.REJECTED;
        }

        _myClaims[claimer].add(_claimIndex);

        _allClaimsToIndex[policyBookAddress][claimer] = _claimIndex;
        _policyBookClaims[policyBookAddress].add(_claimIndex);

        _allClaimsByIndexInfo[_claimIndex] = ClaimInfo(
            claimer,
            policyBookAddress,
            evidenceURI,
            block.timestamp,
            0,
            appeal,
            ClaimStatus.PENDING,
            cover,
            0
        );

        _pendingClaimsIndexes.add(_claimIndex);
        _allClaimsIndexes.add(_claimIndex);

        _newClaimIndex = _claimIndex++;

        if (!appeal) {
            emit ClaimPending(claimer, policyBookAddress, _newClaimIndex);
        } else {
            emit AppealPending(claimer, policyBookAddress, _newClaimIndex);
        }
    }

    function claimExists(uint256 index) public view override returns (bool) {
        return _allClaimsIndexes.contains(index);
    }

    function claimSubmittedTime(uint256 index) public view override returns (uint256) {
        return _allClaimsByIndexInfo[index].dateSubmitted;
    }

    function claimEndTime(uint256 index) public view override returns (uint256) {
        return _allClaimsByIndexInfo[index].dateEnded;
    }

    function isClaimAnonymouslyVotable(uint256 index) external view override returns (bool) {
        return (_pendingClaimsIndexes.contains(index) &&
            _allClaimsByIndexInfo[index].dateSubmitted.add(anonymousVotingDuration(index)) >
            block.timestamp);
    }

    function isClaimExposablyVotable(uint256 index) external view override returns (bool) {
        if (!_pendingClaimsIndexes.contains(index)) {
            return false;
        }

        uint256 dateSubmitted = _allClaimsByIndexInfo[index].dateSubmitted;
        uint256 anonymousDuration = anonymousVotingDuration(index);

        return (dateSubmitted.add(anonymousDuration.add(EXPOSE_VOTE_DURATION)) > block.timestamp &&
            dateSubmitted.add(anonymousDuration) < block.timestamp);
    }

    function isClaimVotable(uint256 index) external view override returns (bool) {
        return (_pendingClaimsIndexes.contains(index) &&
            _allClaimsByIndexInfo[index].dateSubmitted.add(votingDuration(index)) >
            block.timestamp);
    }

    function canClaimBeCalculatedByAnyone(uint256 index) public view override returns (bool) {
        return
            _allClaimsByIndexInfo[index].status == ClaimStatus.PENDING &&
            _allClaimsByIndexInfo[index].dateSubmitted.add(
                anyoneCanCalculateClaimResultAfter(index)
            ) <=
            block.timestamp;
    }

    function isClaimPending(uint256 index) external view override returns (bool) {
        return _pendingClaimsIndexes.contains(index);
    }

    function countPolicyClaimerClaims(address claimer) external view override returns (uint256) {
        return _myClaims[claimer].length();
    }

    function countPendingClaims() external view override returns (uint256) {
        return _pendingClaimsIndexes.length();
    }

    function countClaims() external view override returns (uint256) {
        return _allClaimsIndexes.length();
    }

    /// @notice Gets the the claim index for for the users claim at an indexed position
    /// @param claimer address of of the user
    /// @param orderIndex uint256, numeric value for index
    /// @return uint256
    function claimOfOwnerIndexAt(address claimer, uint256 orderIndex)
        external
        view
        override
        returns (uint256)
    {
        return _myClaims[claimer].at(orderIndex);
    }

    function pendingClaimIndexAt(uint256 orderIndex) external view override returns (uint256) {
        return _pendingClaimsIndexes.at(orderIndex);
    }

    function claimIndexAt(uint256 orderIndex) external view override returns (uint256) {
        return _allClaimsIndexes.at(orderIndex);
    }

    function claimIndex(address claimer, address policyBookAddress)
        external
        view
        override
        returns (uint256)
    {
        return _allClaimsToIndex[policyBookAddress][claimer];
    }

    function isClaimAppeal(uint256 index) external view override returns (bool) {
        return _allClaimsByIndexInfo[index].appeal;
    }

    function policyStatus(address claimer, address policyBookAddress)
        external
        view
        override
        returns (ClaimStatus)
    {
        if (!policyRegistry.isPolicyActive(claimer, policyBookAddress)) {
            return ClaimStatus.UNCLAIMABLE;
        }

        uint256 index = _allClaimsToIndex[policyBookAddress][claimer];

        if (!_myClaims[claimer].contains(index)) {
            return ClaimStatus.CAN_CLAIM;
        }

        ClaimStatus status = claimStatus(index);
        bool newPolicyBought =
            policyRegistry.policyStartTime(claimer, policyBookAddress) >
                _allClaimsByIndexInfo[index].dateSubmitted;

        if (
            status == ClaimStatus.REJECTED ||
            status == ClaimStatus.EXPIRED ||
            (newPolicyBought && status == ClaimStatus.ACCEPTED)
        ) {
            return ClaimStatus.CAN_CLAIM;
        }

        return status;
    }

    function claimStatus(uint256 index) public view override returns (ClaimStatus) {
        if (_isClaimAppealExpired(index)) {
            return ClaimStatus.REJECTED;
        }
        if (_isClaimExpired(index)) {
            return ClaimStatus.EXPIRED;
        }
        if (_isClaimAwaitingCalculation(index)) {
            return ClaimStatus.AWAITING_CALCULATION;
        }

        return _allClaimsByIndexInfo[index].status;
    }

    function claimOwner(uint256 index) external view override returns (address) {
        return _allClaimsByIndexInfo[index].claimer;
    }

    /// @notice Gets the policybook address of a claim with a certain index
    /// @param index uint256, numeric index value
    /// @return address
    function claimPolicyBook(uint256 index) external view override returns (address) {
        return _allClaimsByIndexInfo[index].policyBookAddress;
    }

    /// @notice gets the full claim information at a particular index.
    /// @param index uint256, numeric index value
    /// @return _claimInfo ClaimInfo
    function claimInfo(uint256 index)
        external
        view
        override
        withExistingClaim(index)
        returns (ClaimInfo memory _claimInfo)
    {
        _claimInfo = ClaimInfo(
            _allClaimsByIndexInfo[index].claimer,
            _allClaimsByIndexInfo[index].policyBookAddress,
            _allClaimsByIndexInfo[index].evidenceURI,
            _allClaimsByIndexInfo[index].dateSubmitted,
            _allClaimsByIndexInfo[index].dateEnded,
            _allClaimsByIndexInfo[index].appeal,
            claimStatus(index),
            _allClaimsByIndexInfo[index].claimAmount,
            _allClaimsByIndexInfo[index].claimRefund
        );
    }

    /// @notice fetches the pending claims amounts which is before awaiting for calculation by 24 hrs
    /// @dev use it with getWithdrawClaimRequestIndexListCount
    /// @return _totalClaimsAmount uint256 collect claim amounts from pending claims
    function getAllPendingClaimsAmount(uint256 _limit)
        external
        view
        override
        returns (uint256 _totalClaimsAmount)
    {
        WithdrawalStatus _currentStatus;
        uint256 index;

        for (uint256 i = 0; i < _limit; i++) {
            index = _withdrawClaimRequestIndexList.at(i);
            _currentStatus = getClaimWithdrawalStatus(index);

            if (
                _currentStatus == WithdrawalStatus.NONE ||
                _currentStatus == WithdrawalStatus.EXPIRED
            ) {
                continue;
            }

            ///@dev exclude all ready request until before ready to withdraw date by 24 hrs
            /// + 1 hr (spare time for transaction execution time)
            if (
                block.timestamp >=
                claimWithdrawalInfo[index].readyToWithdrawDate.sub(
                    ICapitalPool(capitalPool).rebalanceDuration().add(60 * 60)
                )
            ) {
                _totalClaimsAmount = _totalClaimsAmount.add(
                    _allClaimsByIndexInfo[index].claimRefund
                );
            }
        }
    }

    /// @dev use it with getWithdrawRewardRequestVoterListCount
    function getAllPendingRewardsAmount(uint256 _limit)
        external
        view
        override
        returns (uint256 _totalRewardsAmount)
    {
        WithdrawalStatus _currentStatus;
        address voter;

        for (uint256 i = 0; i < _limit; i++) {
            voter = _withdrawRewardRequestVoterList.at(i);
            _currentStatus = getRewardWithdrawalStatus(voter);

            if (
                _currentStatus == WithdrawalStatus.NONE ||
                _currentStatus == WithdrawalStatus.EXPIRED
            ) {
                continue;
            }

            ///@dev exclude all ready request until before ready to withdraw date by 24 hrs
            /// + 1 hr (spare time for transaction execution time)
            if (
                block.timestamp >=
                rewardWithdrawalInfo[voter].readyToWithdrawDate.sub(
                    ICapitalPool(capitalPool).rebalanceDuration().add(60 * 60)
                )
            ) {
                _totalRewardsAmount = _totalRewardsAmount.add(
                    rewardWithdrawalInfo[voter].rewardAmount
                );
            }
        }
    }

    function getWithdrawClaimRequestIndexListCount() external view override returns (uint256) {
        return _withdrawClaimRequestIndexList.length();
    }

    function getWithdrawRewardRequestVoterListCount() external view override returns (uint256) {
        return _withdrawRewardRequestVoterList.length();
    }

    /// @notice gets the claiming balance from a list of claim indexes
    /// @param _claimIndexes uint256[], list of claimIndexes
    /// @return uint256
    function getClaimableAmounts(uint256[] memory _claimIndexes)
        external
        view
        override
        returns (uint256)
    {
        uint256 _acumulatedClaimAmount;
        for (uint256 i = 0; i < _claimIndexes.length; i++) {
            _acumulatedClaimAmount = _acumulatedClaimAmount.add(
                _allClaimsByIndexInfo[i].claimAmount
            );
        }
        return _acumulatedClaimAmount;
    }

    function getBMIRewardForCalculation(uint256 index) external view override returns (uint256) {
        uint256 lockedBMIs = claimVoting.lockedBMIAmount(index);
        uint256 timeElapsed =
            claimSubmittedTime(index).add(anyoneCanCalculateClaimResultAfter(index));

        if (canClaimBeCalculatedByAnyone(index)) {
            timeElapsed = block.timestamp.sub(timeElapsed);
        } else {
            timeElapsed = timeElapsed.sub(block.timestamp);
        }

        return
            Math.min(
                lockedBMIs,
                lockedBMIs.mul(timeElapsed.mul(CALCULATION_REWARD_PER_DAY.div(1 days))).div(
                    PERCENTAGE_100
                )
            );
    }

    function _modifyClaim(uint256 index, ClaimStatus status) internal {
        address claimer = _allClaimsByIndexInfo[index].claimer;
        address policyBookAddress = _allClaimsByIndexInfo[index].policyBookAddress;
        uint256 claimAmount = _allClaimsByIndexInfo[index].claimAmount;

        if (status == ClaimStatus.ACCEPTED) {
            _allClaimsByIndexInfo[index].status = ClaimStatus.ACCEPTED;
            _requestClaimWithdrawal(claimer, index);

            emit ClaimAccepted(claimer, policyBookAddress, claimAmount, index);
        } else if (status == ClaimStatus.EXPIRED) {
            _allClaimsByIndexInfo[index].status = ClaimStatus.EXPIRED;

            emit ClaimExpired(claimer, policyBookAdminAddress, index);
        } else if (!_allClaimsByIndexInfo[index].appeal) {
            _allClaimsByIndexInfo[index].status = ClaimStatus.REJECTED_CAN_APPEAL;

            emit ClaimRejected(claimer, policyBookAddress, index);
        } else {
            _allClaimsByIndexInfo[index].status = ClaimStatus.REJECTED;
            delete _allClaimsToIndex[policyBookAddress][claimer];
            _policyBookClaims[policyBookAddress].remove(index);

            emit AppealRejected(claimer, policyBookAddress, index);
        }

        _allClaimsByIndexInfo[index].dateEnded = block.timestamp;

        _pendingClaimsIndexes.remove(index);

        IPolicyBook(_allClaimsByIndexInfo[index].policyBookAddress).commitClaim(
            claimer,
            block.timestamp,
            _allClaimsByIndexInfo[index].status // ACCEPTED, REJECTED_CAN_APPEAL, REJECTED, EXPIRED
        );
    }

    function acceptClaim(uint256 index, uint256 amount) external override onlyClaimVoting {
        require(_isClaimAwaitingCalculation(index), "ClaimingRegistry: The claim is not awaiting");
        _allClaimsByIndexInfo[index].claimRefund = amount;
        _modifyClaim(index, ClaimStatus.ACCEPTED);
    }

    function rejectClaim(uint256 index) external override onlyClaimVoting {
        require(_isClaimAwaitingCalculation(index), "ClaimingRegistry: The claim is not awaiting");

        _modifyClaim(index, ClaimStatus.REJECTED);
    }

    function expireClaim(uint256 index) external override onlyClaimVoting {
        require(_isClaimExpired(index), "ClaimingRegistry: The claim is not expired");

        _modifyClaim(index, ClaimStatus.EXPIRED);
    }

    /// @notice Update Image Uri in case it contains material that is ilegal
    ///         or offensive.
    /// @dev Only the owner of the PolicyBookAdmin can erase/update evidenceUri.
    /// @param claim_Index Claim Index that is going to be updated
    /// @param _newEvidenceURI New evidence uri. It can be blank.
    function updateImageUriOfClaim(uint256 claim_Index, string calldata _newEvidenceURI)
        external
        override
        onlyPolicyBookAdmin
    {
        _allClaimsByIndexInfo[claim_Index].evidenceURI = _newEvidenceURI;
    }

    function requestClaimWithdrawal(uint256 index) external override {
        require(
            claimStatus(index) == IClaimingRegistry.ClaimStatus.ACCEPTED,
            "ClaimingRegistry: Claim is not accepted"
        );
        address claimer = _allClaimsByIndexInfo[index].claimer;
        require(msg.sender == claimer, "ClaimingRegistry: Not allowed to request");
        address policyBookAddress = _allClaimsByIndexInfo[index].policyBookAddress;
        require(
            policyRegistry.isPolicyActive(claimer, policyBookAddress) &&
                policyRegistry.policyStartTime(claimer, policyBookAddress) <
                _allClaimsByIndexInfo[index].dateEnded,
            "ClaimingRegistry: The policy is expired"
        );
        require(
            getClaimWithdrawalStatus(index) == WithdrawalStatus.NONE ||
                getClaimWithdrawalStatus(index) == WithdrawalStatus.EXPIRED,
            "ClaimingRegistry: The claim is already requested"
        );
        _requestClaimWithdrawal(claimer, index);
    }

    function _requestClaimWithdrawal(address claimer, uint256 index) internal {
        _withdrawClaimRequestIndexList.add(index);
        uint256 _readyToWithdrawDate = block.timestamp.add(capitalPool.getWithdrawPeriod());
        bool _committed = claimWithdrawalInfo[index].committed;
        claimWithdrawalInfo[index] = ClaimWithdrawalInfo(_readyToWithdrawDate, _committed);

        emit WithdrawalRequested(
            claimer,
            _allClaimsByIndexInfo[index].claimRefund,
            _readyToWithdrawDate
        );
    }

    function requestRewardWithdrawal(address voter, uint256 rewardAmount)
        external
        override
        onlyClaimVoting
    {
        require(
            getRewardWithdrawalStatus(voter) == WithdrawalStatus.NONE ||
                getRewardWithdrawalStatus(voter) == WithdrawalStatus.EXPIRED,
            "ClaimingRegistry: The reward is already requested"
        );
        _requestRewardWithdrawal(voter, rewardAmount);
    }

    function _requestRewardWithdrawal(address voter, uint256 rewardAmount) internal {
        _withdrawRewardRequestVoterList.add(voter);
        uint256 _readyToWithdrawDate = block.timestamp.add(capitalPool.getWithdrawPeriod());
        rewardWithdrawalInfo[voter] = RewardWithdrawalInfo(rewardAmount, _readyToWithdrawDate);

        emit WithdrawalRequested(voter, rewardAmount, _readyToWithdrawDate);
    }

    function withdrawClaim(uint256 index) public virtual {
        address claimer = _allClaimsByIndexInfo[index].claimer;
        require(claimer == msg.sender, "ClaimingRegistry: Not the claimer");
        require(
            getClaimWithdrawalStatus(index) == WithdrawalStatus.READY,
            "ClaimingRegistry: Withdrawal is not ready"
        );

        address policyBookAddress = _allClaimsByIndexInfo[index].policyBookAddress;

        uint256 claimRefundConverted =
            DecimalsConverter.convertFrom18(
                _allClaimsByIndexInfo[index].claimRefund,
                stblDecimals
            );

        uint256 _actualAmount =
            capitalPool.fundClaim(claimer, claimRefundConverted, policyBookAddress);

        claimRefundConverted = claimRefundConverted.sub(_actualAmount);

        if (!claimWithdrawalInfo[index].committed) {
            IPolicyBook(policyBookAddress).commitWithdrawnClaim(msg.sender);
            claimWithdrawalInfo[index].committed = true;
        }

        if (claimRefundConverted == 0) {
            _allClaimsByIndexInfo[index].claimRefund = 0;
            _withdrawClaimRequestIndexList.remove(index);
            delete claimWithdrawalInfo[index];
        } else {
            _allClaimsByIndexInfo[index].claimRefund = DecimalsConverter.convertTo18(
                claimRefundConverted,
                stblDecimals
            );
            _requestClaimWithdrawal(claimer, index);
        }

        claimVoting.transferLockedBMI(index, claimer);

        emit ClaimWithdrawn(
            msg.sender,
            DecimalsConverter.convertTo18(_actualAmount, stblDecimals)
        );
    }

    function withdrawReward() public {
        require(
            getRewardWithdrawalStatus(msg.sender) == WithdrawalStatus.READY,
            "ClaimingRegistry: Withdrawal is not ready"
        );

        uint256 rewardAmountConverted =
            DecimalsConverter.convertFrom18(
                rewardWithdrawalInfo[msg.sender].rewardAmount,
                stblDecimals
            );

        uint256 _actualAmount = capitalPool.fundReward(msg.sender, rewardAmountConverted);

        rewardAmountConverted = rewardAmountConverted.sub(_actualAmount);

        if (rewardAmountConverted == 0) {
            rewardWithdrawalInfo[msg.sender].rewardAmount = 0;
            _withdrawRewardRequestVoterList.remove(msg.sender);
            delete rewardWithdrawalInfo[msg.sender];
        } else {
            rewardWithdrawalInfo[msg.sender].rewardAmount = DecimalsConverter.convertTo18(
                rewardAmountConverted,
                stblDecimals
            );

            _requestRewardWithdrawal(msg.sender, rewardWithdrawalInfo[msg.sender].rewardAmount);
        }

        emit RewardWithdrawn(
            msg.sender,
            DecimalsConverter.convertTo18(_actualAmount, stblDecimals)
        );
    }

    function withdrawLockedBMI(uint256 index) public virtual {
        address claimer = _allClaimsByIndexInfo[index].claimer;
        require(claimer == msg.sender, "ClaimingRegistry: Not the claimer");

        require(
            canWithdrawLockedBMI(index),
            "ClaimingRegistry: Claim is not expired or can still be withdrawn"
        );

        address policyBookAddress = _allClaimsByIndexInfo[index].policyBookAddress;
        if (claimStatus(index) == ClaimStatus.ACCEPTED) {
            IPolicyBook(policyBookAddress).commitWithdrawnClaim(claimer);
            _withdrawClaimRequestIndexList.remove(index);
            delete claimWithdrawalInfo[index];
        }

        claimVoting.transferLockedBMI(index, claimer);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";

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
            amount = amount.div(10**(baseDecimals - destinationDecimals));
        } else if (baseDecimals < destinationDecimals) {
            amount = amount.mul(10**(destinationDecimals - baseDecimals));
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
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

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
    }

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
            IClaimingRegistry.ClaimStatus[] memory _policyStatuses
        );

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
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./IPolicyBookFabric.sol";

interface IPolicyBookRegistry {
    struct PolicyBookStats {
        string symbol;
        address insuredContract;
        IPolicyBookFabric.ContractType contractType;
        uint256 maxCapacity;
        uint256 totalSTBLLiquidity;
        uint256 totalLeveragedLiquidity;
        uint256 stakedSTBL;
        uint256 APY;
        uint256 annualInsuranceCost;
        uint256 bmiXRatio;
        bool whitelisted;
    }

    function policyBooksByInsuredAddress(address insuredContract) external view returns (address);

    function policyBookFacades(address facadeAddress) external view returns (address);

    /// @notice Adds PolicyBook to registry, access: PolicyFabric
    function add(
        address insuredContract,
        IPolicyBookFabric.ContractType contractType,
        address policyBook,
        address facadeAddress
    ) external;

    function whitelist(address policyBookAddress, bool whitelisted) external;

    /// @notice returns required allowances for the policybooks
    function getPoliciesPrices(
        address[] calldata policyBooks,
        uint256[] calldata epochsNumbers,
        uint256[] calldata coversTokens
    ) external view returns (uint256[] memory _durations, uint256[] memory _allowances);

    /// @notice Buys a batch of policies
    function buyPolicyBatch(
        address[] calldata policyBooks,
        uint256[] calldata epochsNumbers,
        uint256[] calldata coversTokens
    ) external;

    /// @notice Checks if provided address is a PolicyBook
    function isPolicyBook(address policyBook) external view returns (bool);

    /// @notice Checks if provided address is a policyBookFacade
    function isPolicyBookFacade(address _facadeAddress) external view returns (bool);

    /// @notice Checks if provided address is a user leverage pool
    function isUserLeveragePool(address policyBookAddress) external view returns (bool);

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
pragma solidity ^0.7.4;

import "./IPolicyBook.sol";
import "./IPolicyBookFabric.sol";
import "./ILeveragePortfolio.sol";

interface IPolicyBookFacade {
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

    function policyBook() external view returns (IPolicyBook);

    function userLiquidity(address account) external view returns (uint256);

    /// @notice forces an update of RewardsGenerator multiplier
    function forceUpdateBMICoverStakingRewardMultiplier() external;

    /// @notice view function to get precise policy price
    /// @param _epochsNumber is number of epochs to cover
    /// @param _coverTokens is number of tokens to cover
    /// @param _buyer address of the user who buy the policy
    /// @return totalSeconds is number of seconds to cover
    /// @return totalPrice is the policy price which will pay by the buyer
    function getPolicyPrice(
        uint256 _epochsNumber,
        uint256 _coverTokens,
        address _buyer
    )
        external
        view
        returns (
            uint256 totalSeconds,
            uint256 totalPrice,
            uint256 pricePercentage
        );

    function secondsToEndCurrentEpoch() external view returns (uint256);

    /// @notice virtual funds deployed by reinsurance pool
    function VUreinsurnacePool() external view returns (uint256);

    /// @notice leverage funds deployed by reinsurance pool
    function LUreinsurnacePool() external view returns (uint256);

    /// @notice leverage funds deployed by user leverage pool
    function LUuserLeveragePool(address userLeveragePool) external view returns (uint256);

    /// @notice total leverage funds deployed to the pool sum of (VUreinsurnacePool,LUreinsurnacePool,LUuserLeveragePool)
    function totalLeveragedLiquidity() external view returns (uint256);

    function userleveragedMPL() external view returns (uint256);

    function reinsurancePoolMPL() external view returns (uint256);

    function rebalancingThreshold() external view returns (uint256);

    function safePricingModel() external view returns (bool);

    /// @notice policyBookFacade initializer
    /// @param pbProxy polciybook address upgreadable cotnract.
    function __PolicyBookFacade_init(
        address pbProxy,
        address liquidityProvider,
        uint256 initialDeposit
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

    /// @notice Let user to add liquidity by supplying stable coin, access: ANY
    /// @param _liquidityAmount is amount of stable coin tokens to secure
    function addLiquidity(uint256 _liquidityAmount) external;

    /// @notice Let user to add liquidity by supplying stable coin, access: ANY
    /// @param _user the one taht add liquidity
    /// @param _liquidityAmount is amount of stable coin tokens to secure
    function addLiquidityFromDistributorFor(address _user, uint256 _liquidityAmount) external;

    function addLiquidityAndStakeFor(
        address _liquidityHolderAddr,
        uint256 _liquidityAmount,
        uint256 _stakeSTBLAmount
    ) external;

    /// @notice Let user to add liquidity by supplying stable coin and stake it,
    /// @dev access: ANY
    function addLiquidityAndStake(uint256 _liquidityAmount, uint256 _stakeSTBLAmount) external;

    /// @notice Let user to withdraw deposited liqiudity, access: ANY
    function withdrawLiquidity() external;

    /// @notice deploy leverage funds (RP lStable, ULP lStable)
    /// @param  deployedAmount uint256 the deployed amount to be added or substracted from the total liquidity
    /// @param leveragePool whether user leverage or reinsurance leverage
    function deployLeverageFundsAfterRebalance(
        uint256 deployedAmount,
        ILeveragePortfolio.LeveragePortfolio leveragePool
    ) external;

    /// @notice deploy virtual funds (RP vStable)
    /// @param  deployedAmount uint256 the deployed amount to be added to the liquidity
    function deployVirtualFundsAfterRebalance(uint256 deployedAmount) external;

    ///@dev in case ur changed of the pools by commit a claim or policy expired
    function reevaluateProvidedLeverageStable() external;

    /// @notice set the MPL for the user leverage and the reinsurance leverage
    /// @param _userLeverageMPL uint256 value of the user leverage MPL
    /// @param _reinsuranceLeverageMPL uint256  value of the reinsurance leverage MPL
    function setMPLs(uint256 _userLeverageMPL, uint256 _reinsuranceLeverageMPL) external;

    /// @notice sets the rebalancing threshold value
    /// @param _newRebalancingThreshold uint256 rebalancing threshhold value
    function setRebalancingThreshold(uint256 _newRebalancingThreshold) external;

    /// @notice sets the rebalancing threshold value
    /// @param _safePricingModel bool is pricing model safe (true) or not (false)
    function setSafePricingModel(bool _safePricingModel) external;

    /// @notice returns how many BMI tokens needs to approve in order to submit a claim
    function getClaimApprovalAmount(address user) external view returns (uint256);

    /// @notice upserts a withdraw request
    /// @dev prevents adding a request if an already pending or ready request is open.
    /// @param _tokensToWithdraw uint256 amount of tokens to withdraw
    function requestWithdrawal(uint256 _tokensToWithdraw) external;

    function listUserLeveragePools(uint256 offset, uint256 limit)
        external
        view
        returns (address[] memory _userLeveragePools);

    function countUserLeveragePools() external view returns (uint256);

    /// @notice Getting info, access: ANY
    /// @return _symbol is the symbol of PolicyBook (bmiXCover)
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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

interface IPolicyBookFabric {
    enum ContractType {CONTRACT, STABLECOIN, SERVICE, EXCHANGE, VARIOUS}

    /// @notice Create new Policy Book contract, access: ANY
    /// @param _contract is Contract to create policy book for
    /// @param _contractType is Contract to create policy book for
    /// @param _description is bmiXCover token desription for this policy book
    /// @param _projectSymbol replaces x in bmiXCover token symbol
    /// @param _initialDeposit is an amount user deposits on creation (addLiquidity())
    /// @return _policyBook is address of created contract
    function create(
        address _contract,
        ContractType _contractType,
        string calldata _description,
        string calldata _projectSymbol,
        uint256 _initialDeposit,
        address _shieldMiningToken
    ) external returns (address);

    function createLeveragePools(
        address _insuranceContract,
        ContractType _contractType,
        string calldata _description,
        string calldata _projectSymbol
    ) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./IPolicyBookFabric.sol";
import "./IClaimingRegistry.sol";
import "./IPolicyBookFacade.sol";

interface IPolicyBook {
    enum WithdrawalStatus {NONE, PENDING, READY, EXPIRED}

    struct PolicyHolder {
        uint256 coverTokens;
        uint256 startEpochNumber;
        uint256 endEpochNumber;
        uint256 paid;
        uint256 reinsurancePrice;
    }

    struct WithdrawalInfo {
        uint256 withdrawalAmount;
        uint256 readyToWithdrawDate;
        bool withdrawalAllowed;
    }

    struct BuyPolicyParameters {
        address buyer;
        address holder;
        uint256 epochsNumber;
        uint256 coverTokens;
        uint256 distributorFee;
        address distributor;
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

    function setPolicyBookFacade(address _policyBookFacade) external;

    function EPOCH_DURATION() external view returns (uint256);

    function stblDecimals() external view returns (uint256);

    function READY_TO_WITHDRAW_PERIOD() external view returns (uint256);

    function whitelisted() external view returns (bool);

    function epochStartTime() external view returns (uint256);

    // @TODO: should we let DAO to change contract address?
    /// @notice Returns address of contract this PolicyBook covers, access: ANY
    /// @return _contract is address of covered contract
    function insuranceContractAddress() external view returns (address _contract);

    /// @notice Returns type of contract this PolicyBook covers, access: ANY
    /// @return _type is type of contract
    function contractType() external view returns (IPolicyBookFabric.ContractType _type);

    function totalLiquidity() external view returns (uint256);

    function totalCoverTokens() external view returns (uint256);

    // /// @notice return MPL for user leverage pool
    // function userleveragedMPL() external view returns (uint256);

    // /// @notice return MPL for reinsurance pool
    // function reinsurancePoolMPL() external view returns (uint256);

    // function bmiRewardMultiplier() external view returns (uint256);

    function withdrawalsInfo(address _userAddr)
        external
        view
        returns (
            uint256 _withdrawalAmount,
            uint256 _readyToWithdrawDate,
            bool _withdrawalAllowed
        );

    function __PolicyBook_init(
        address _insuranceContract,
        IPolicyBookFabric.ContractType _contractType,
        string calldata _description,
        string calldata _projectSymbol
    ) external;

    function whitelist(bool _whitelisted) external;

    function getEpoch(uint256 time) external view returns (uint256);

    /// @notice get STBL equivalent
    function convertBMIXToSTBL(uint256 _amount) external view returns (uint256);

    /// @notice get BMIX equivalent
    function convertSTBLToBMIX(uint256 _amount) external view returns (uint256);

    /// @notice submits new claim of the policy book
    function submitClaimAndInitializeVoting(string calldata evidenceURI) external;

    /// @notice submits new appeal claim of the policy book
    function submitAppealAndInitializeVoting(string calldata evidenceURI) external;

    /// @notice updates info on claim when not accepted
    function commitClaim(
        address claimer,
        uint256 claimEndTime,
        IClaimingRegistry.ClaimStatus status
    ) external;

    /// @notice withdraw the claim after requested
    function commitWithdrawnClaim(address claimer) external;

    /// @notice function to get precise current cover and liquidity
    function getNewCoverAndLiquidity()
        external
        view
        returns (uint256 newTotalCoverTokens, uint256 newTotalLiquidity);

    /// @notice Let user to buy policy by supplying stable coin, access: ANY
    /// @param _buyer who is transferring funds
    /// @param _holder who owns coverage
    /// @param _epochsNumber period policy will cover
    /// @param _coverTokens amount paid for the coverage
    /// @param _distributorFee distributor fee (commission). It can't be greater than PROTOCOL_PERCENTAGE
    /// @param _distributor if it was sold buy a whitelisted distributor, it is distributor address to receive fee (commission)
    function buyPolicy(
        address _buyer,
        address _holder,
        uint256 _epochsNumber,
        uint256 _coverTokens,
        uint256 _distributorFee,
        address _distributor
    ) external returns (uint256, uint256);

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
    /// @param _stakeSTBLAmount uint256 the staked amount if add liq and stake
    function addLiquidity(
        address _liquidityBuyerAddr,
        address _liquidityHolderAddr,
        uint256 _liquidityAmount,
        uint256 _stakeSTBLAmount
    ) external returns (uint256);

    function getAvailableBMIXWithdrawableAmount(address _userAddr) external view returns (uint256);

    function getWithdrawalStatus(address _userAddr) external view returns (WithdrawalStatus);

    function requestWithdrawal(uint256 _tokensToWithdraw, address _user) external;

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

    function getAPY() external view returns (uint256);

    /// @notice Getting user stats, access: ANY
    function userStats(address _user) external view returns (PolicyHolder memory);

    /// @notice Getting number stats, access: ANY
    /// @return _maxCapacities is a max token amount that a user can buy
    /// @return _buyPolicyCapacity new capacity which is a max token amount that a user can buy including withdraw amount
    /// @return _totalSTBLLiquidity is PolicyBook's liquidity
    /// @return _totalLeveragedLiquidity is PolicyBook's leveraged liquidity
    /// @return _stakedSTBL is how much stable coin are staked on this PolicyBook
    /// @return _annualProfitYields is its APY
    /// @return _annualInsuranceCost is percentage of cover tokens that is required to be paid for 1 year of insurance
    function numberStats()
        external
        view
        returns (
            uint256 _maxCapacities,
            uint256 _buyPolicyCapacity,
            uint256 _totalSTBLLiquidity,
            uint256 _totalLeveragedLiquidity,
            uint256 _stakedSTBL,
            uint256 _annualProfitYields,
            uint256 _annualInsuranceCost,
            uint256 _bmiXRatio
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

interface ILeveragePortfolio {
    enum LeveragePortfolio {USERLEVERAGEPOOL, REINSURANCEPOOL}
    struct LevFundsFactors {
        uint256 netMPL;
        uint256 netMPLn;
        address policyBookAddr;
    }

    function targetUR() external view returns (uint256);

    function d_ProtocolConstant() external view returns (uint256);

    function a_ProtocolConstant() external view returns (uint256);

    function max_ProtocolConstant() external view returns (uint256);

    /// @notice deploy lStable from user leverage pool or reinsurance pool using 2 formulas: access by policybook.
    /// @param leveragePoolType LeveragePortfolio is determine the pool which call the function
    function deployLeverageStableToCoveragePools(LeveragePortfolio leveragePoolType)
        external
        returns (uint256);

    /// @notice deploy the vStable from RP in v2 and for next versions it will be from RP and LP : access by policybook.
    function deployVirtualStableToCoveragePools() external returns (uint256);

    /// @notice set the threshold % for re-evaluation of the lStable provided across all Coverage pools : access by owner
    /// @param threshold uint256 is the reevaluatation threshold
    function setRebalancingThreshold(uint256 threshold) external;

    /// @notice set the protocol constant : access by owner
    /// @param _targetUR uint256 target utitlization ration
    /// @param _d_ProtocolConstant uint256 D protocol constant
    /// @param  _a1_ProtocolConstant uint256 A1 protocol constant
    /// @param _max_ProtocolConstant uint256 the max % included
    function setProtocolConstant(
        uint256 _targetUR,
        uint256 _d_ProtocolConstant,
        uint256 _a1_ProtocolConstant,
        uint256 _max_ProtocolConstant
    ) external;

    /// @notice calc M factor by formual M = min( abs((1/ (Tur-UR))*d) /a, max)
    /// @param poolUR uint256 utitilization ratio for a coverage pool
    /// @return uint256 M facotr
    //function calcM(uint256 poolUR) external returns (uint256);

    /// @return uint256 the amount of vStable stored in the pool
    function totalLiquidity() external view returns (uint256);

    /// @notice add the portion of 80% of premium to user leverage pool where the leverage provide lstable : access policybook
    /// add the 20% of premium + portion of 80% of premium where reisnurance pool participate in coverage pools (vStable)  : access policybook
    /// @param epochsNumber uint256 the number of epochs which the policy holder will pay a premium for
    /// @param  premiumAmount uint256 the premium amount which is a portion of 80% of the premium
    function addPolicyPremium(uint256 epochsNumber, uint256 premiumAmount) external;

    /// @notice Used to get a list of coverage pools which get leveraged , use with count()
    /// @return _coveragePools a list containing policybook addresses
    function listleveragedCoveragePools(uint256 offset, uint256 limit)
        external
        view
        returns (address[] memory _coveragePools);

    /// @notice get count of coverage pools which get leveraged
    function countleveragedCoveragePools() external view returns (uint256);

    function updateLiquidity(uint256 _lostLiquidity) external;

    function forceUpdateBMICoverStakingRewardMultiplier() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

interface IContractsRegistry {
    function getAMMRouterContract() external view returns (address);

    function getAMMBMIToETHPairContract() external view returns (address);

    function getAMMBMIToUSDTPairContract() external view returns (address);

    function getSushiSwapMasterChefV2Contract() external view returns (address);

    function getWrappedTokenContract() external view returns (address);

    function getUSDTContract() external view returns (address);

    function getBMIContract() external view returns (address);

    function getPriceFeedContract() external view returns (address);

    function getPolicyBookRegistryContract() external view returns (address);

    function getPolicyBookFabricContract() external view returns (address);

    function getBMICoverStakingContract() external view returns (address);

    function getBMICoverStakingViewContract() external view returns (address);

    function getBMITreasury() external view returns (address);

    function getRewardsGeneratorContract() external view returns (address);

    function getBMIUtilityNFTContract() external view returns (address);

    function getNFTStakingContract() external view returns (address);

    function getLiquidityBridgeContract() external view returns (address);

    function getClaimingRegistryContract() external view returns (address);

    function getPolicyRegistryContract() external view returns (address);

    function getLiquidityRegistryContract() external view returns (address);

    function getClaimVotingContract() external view returns (address);

    function getReinsurancePoolContract() external view returns (address);

    function getLeveragePortfolioViewContract() external view returns (address);

    function getCapitalPoolContract() external view returns (address);

    function getPolicyBookAdminContract() external view returns (address);

    function getPolicyQuoteContract() external view returns (address);

    function getBMIStakingContract() external view returns (address);

    function getSTKBMIContract() external view returns (address);

    function getStkBMIStakingContract() external view returns (address);

    function getVBMIContract() external view returns (address);

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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./IPolicyBookFabric.sol";

interface IClaimingRegistry {
    enum ClaimStatus {
        CAN_CLAIM,
        UNCLAIMABLE,
        PENDING,
        AWAITING_CALCULATION,
        REJECTED_CAN_APPEAL,
        REJECTED,
        ACCEPTED,
        EXPIRED
    }

    struct ClaimInfo {
        address claimer;
        address policyBookAddress;
        string evidenceURI;
        uint256 dateSubmitted;
        uint256 dateEnded;
        bool appeal;
        ClaimStatus status;
        uint256 claimAmount;
        uint256 claimRefund;
    }

    struct ClaimWithdrawalInfo {
        uint256 readyToWithdrawDate;
        bool committed;
    }

    struct RewardWithdrawalInfo {
        uint256 rewardAmount;
        uint256 readyToWithdrawDate;
    }

    enum WithdrawalStatus {NONE, PENDING, READY, EXPIRED}

    function claimWithdrawalInfo(uint256 index)
        external
        view
        returns (uint256 readyToWithdrawDate, bool committed);

    function rewardWithdrawalInfo(address voter)
        external
        view
        returns (uint256 rewardAmount, uint256 readyToWithdrawDate);

    /// @notice returns anonymous voting duration
    function anonymousVotingDuration(uint256 index) external view returns (uint256);

    /// @notice returns the whole voting duration
    function votingDuration(uint256 index) external view returns (uint256);

    /// @notice returns the whole voting duration + view verdict duration
    function validityDuration(uint256 index) external view returns (uint256);

    /// @notice returns how many time should pass before anyone could calculate a claim result
    function anyoneCanCalculateClaimResultAfter(uint256 index) external view returns (uint256);

    function canCalculateClaim(uint256 index, address calculator) external view returns (bool);

    /// @notice check if a user can buy new policy of specified PolicyBook and end the active one if there is
    function canBuyNewPolicy(address buyer, address policyBookAddress) external;

    /// @notice returns withdrawal status of requested claim
    function getClaimWithdrawalStatus(uint256 index) external view returns (WithdrawalStatus);

    /// @notice returns withdrawal status of requested reward
    function getRewardWithdrawalStatus(address voter) external view returns (WithdrawalStatus);

    /// @notice returns true if there is ongoing claiming procedure
    function hasProcedureOngoing(address poolAddress) external view returns (bool);

    /// @notice submits new PolicyBook claim for the user
    function submitClaim(
        address user,
        address policyBookAddress,
        string calldata evidenceURI,
        uint256 cover,
        bool appeal
    ) external returns (uint256);

    /// @notice returns true if the claim with this index exists
    function claimExists(uint256 index) external view returns (bool);

    /// @notice returns claim submition time
    function claimSubmittedTime(uint256 index) external view returns (uint256);

    /// @notice returns claim end time or zero in case it is pending
    function claimEndTime(uint256 index) external view returns (uint256);

    /// @notice returns true if the claim is anonymously votable
    function isClaimAnonymouslyVotable(uint256 index) external view returns (bool);

    /// @notice returns true if the claim is exposably votable
    function isClaimExposablyVotable(uint256 index) external view returns (bool);

    /// @notice returns true if claim is anonymously votable or exposably votable
    function isClaimVotable(uint256 index) external view returns (bool);

    /// @notice returns true if a claim can be calculated by anyone
    function canClaimBeCalculatedByAnyone(uint256 index) external view returns (bool);

    /// @notice returns true if this claim is pending or awaiting
    function isClaimPending(uint256 index) external view returns (bool);

    /// @notice returns how many claims the holder has
    function countPolicyClaimerClaims(address user) external view returns (uint256);

    /// @notice returns how many pending claims are there
    function countPendingClaims() external view returns (uint256);

    /// @notice returns how many claims are there
    function countClaims() external view returns (uint256);

    /// @notice returns a claim index of it's claimer and an ordinal number
    function claimOfOwnerIndexAt(address claimer, uint256 orderIndex)
        external
        view
        returns (uint256);

    /// @notice returns pending claim index by its ordinal index
    function pendingClaimIndexAt(uint256 orderIndex) external view returns (uint256);

    /// @notice returns claim index by its ordinal index
    function claimIndexAt(uint256 orderIndex) external view returns (uint256);

    /// @notice returns current active claim index by policybook and claimer
    function claimIndex(address claimer, address policyBookAddress)
        external
        view
        returns (uint256);

    /// @notice returns true if the claim is appealed
    function isClaimAppeal(uint256 index) external view returns (bool);

    /// @notice returns current status of a claim
    function policyStatus(address claimer, address policyBookAddress)
        external
        view
        returns (ClaimStatus);

    /// @notice returns current status of a claim
    function claimStatus(uint256 index) external view returns (ClaimStatus);

    /// @notice returns the claim owner (claimer)
    function claimOwner(uint256 index) external view returns (address);

    /// @notice returns the claim PolicyBook
    function claimPolicyBook(uint256 index) external view returns (address);

    /// @notice returns claim info by its index
    function claimInfo(uint256 index) external view returns (ClaimInfo memory _claimInfo);

    function getAllPendingClaimsAmount(uint256 _limit)
        external
        view
        returns (uint256 _totalClaimsAmount);

    function getAllPendingRewardsAmount(uint256 _limit)
        external
        view
        returns (uint256 _totalRewardsAmount);

    function getClaimableAmounts(uint256[] memory _claimIndexes) external view returns (uint256);

    function getBMIRewardForCalculation(uint256 index) external view returns (uint256);

    /// @notice marks the user's claim as Accepted
    function acceptClaim(uint256 index, uint256 amount) external;

    /// @notice marks the user's claim as Rejected
    function rejectClaim(uint256 index) external;

    /// @notice marks the user's claim as Expired
    function expireClaim(uint256 index) external;

    /// @notice Update Image Uri in case it contains material that is ilegal
    ///         or offensive.
    /// @dev Only the owner of the PolicyBookAdmin can erase/update evidenceUri.
    /// @param claim_Index Claim Index that is going to be updated
    /// @param _newEvidenceURI New evidence uri. It can be blank.
    function updateImageUriOfClaim(uint256 claim_Index, string calldata _newEvidenceURI) external;

    function requestClaimWithdrawal(uint256 index) external;

    function requestRewardWithdrawal(address voter, uint256 rewardAmount) external;

    function getWithdrawClaimRequestIndexListCount() external view returns (uint256);

    function getWithdrawRewardRequestVoterListCount() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/EnumerableSet.sol";

import "./IClaimingRegistry.sol";

interface IClaimVoting {
    enum VoteStatus {
        ANONYMOUS_PENDING,
        AWAITING_EXPOSURE,
        EXPIRED,
        EXPOSED_PENDING,
        AWAITING_RECEPTION,
        MINORITY,
        MAJORITY,
        REJECTED
    }

    struct VotingResult {
        uint256 withdrawalAmount;
        uint256 lockedBMIAmount;
        uint256 reinsuranceTokensAmount;
        uint256 votedAverageWithdrawalAmount;
        uint256 votedYesStakedStkBMIAmountWithReputation;
        uint256 votedNoStakedStkBMIAmountWithReputation;
        uint256 allVotedStakedStkBMIAmount;
        uint256 votedYesPercentage;
        EnumerableSet.UintSet voteIndexes;
    }

    struct VotingInst {
        uint256 claimIndex;
        bytes32 finalHash;
        string encryptedVote;
        address voter;
        uint256 voterReputation;
        uint256 suggestedAmount;
        uint256 stakedStkBMIAmount;
        bool accept;
        VoteStatus status;
    }

    struct MyClaimInfo {
        uint256 index;
        address policyBookAddress;
        string evidenceURI;
        bool appeal;
        uint256 claimAmount;
        IClaimingRegistry.ClaimStatus finalVerdict;
        uint256 finalClaimAmount;
        uint256 bmiCalculationReward;
    }

    struct PublicClaimInfo {
        uint256 claimIndex;
        address claimer;
        address policyBookAddress;
        string evidenceURI;
        bool appeal;
        uint256 claimAmount;
        uint256 time;
    }

    struct AllClaimInfo {
        PublicClaimInfo publicClaimInfo;
        IClaimingRegistry.ClaimStatus finalVerdict;
        uint256 finalClaimAmount;
        uint256 bmiCalculationReward;
    }

    struct MyVoteInfo {
        AllClaimInfo allClaimInfo;
        string encryptedVote;
        uint256 suggestedAmount;
        VoteStatus status;
        uint256 time;
    }

    struct VotesUpdatesInfo {
        uint256 bmiReward;
        uint256 stblReward;
        int256 reputationChange;
        int256 stakeChange;
    }

    function voteResults(uint256 voteIndex)
        external
        view
        returns (
            uint256 bmiReward,
            uint256 stblReward,
            int256 reputationChange,
            int256 stakeChange
        );

    /// @notice starts the voting process
    function initializeVoting(
        address claimer,
        string calldata evidenceURI,
        uint256 coverTokens,
        bool appeal
    ) external;

    function isToReceive(uint256 claimIndex, address user) external view returns (bool);

    /// @notice returns true if the user has no PENDING votes
    function canUnstake(address user) external view returns (bool);

    /// @notice returns true if the user has no awaiting reception votes
    function canVote(address user) external view returns (bool);

    /// @notice returns number of vote on a claim
    function countVoteOnClaim(uint256 claimIndex) external view returns (uint256);

    /// @notice returns amount of bmi locked for FE
    function lockedBMIAmount(uint256 claimIndex) external view returns (uint256);

    /// @notice returns how many votes the user has
    function countVotes(address user) external view returns (uint256);

    /// @notice returns status of the vote
    function voteStatus(uint256 index) external view returns (VoteStatus);

    /// @notice returns a list of claims that are votable for msg.sender
    function whatCanIVoteFor(uint256 offset, uint256 limit)
        external
        returns (uint256 _claimsCount, PublicClaimInfo[] memory _votablesInfo);

    /// @notice returns info list of ALL claims
    function allClaims(uint256 offset, uint256 limit)
        external
        view
        returns (AllClaimInfo[] memory _allClaimsInfo);

    /// @notice returns info list of claims of msg.sender
    function myClaims(uint256 offset, uint256 limit)
        external
        view
        returns (MyClaimInfo[] memory _myClaimsInfo);

    /// @notice returns info list of claims that are voted by msg.sender
    function myVotes(uint256 offset, uint256 limit)
        external
        view
        returns (MyVoteInfo[] memory _myVotesInfo, VotesUpdatesInfo[] memory _myVotesUpdatesInfo);

    /// @notice anonymously votes (result used later in exposeVote())
    /// @notice the claims have to be PENDING, the voter can vote only once for a specific claim
    /// @param claimIndexes are the indexes of the claims the voter is voting on
    ///     (each one is unique for each claim and appeal)
    /// @param finalHashes are the hashes produced by the encryption algorithm.
    ///     They will be verified onchain in expose function
    /// @param encryptedVotes are the AES encrypted values that represent the actual vote
    function anonymouslyVoteBatch(
        uint256[] calldata claimIndexes,
        bytes32[] calldata finalHashes,
        string[] calldata encryptedVotes
    ) external;

    /// @notice exposes votes of anonymous votings
    /// @notice the vote has to be voted anonymously prior
    /// @param claimIndexes are the indexes of the claims to expose votes for
    /// @param suggestedClaimAmounts are the actual vote values.
    ///     They must match the decrypted values in anonymouslyVoteBatch function
    /// @param hashedSignaturesOfClaims are the validation data needed to construct proper finalHashes
    /// @param isConfirmed is true, vote is taken into account, if false, vote is rejected from calculation
    function exposeVoteBatch(
        uint256[] calldata claimIndexes,
        uint256[] calldata suggestedClaimAmounts,
        bytes32[] calldata hashedSignaturesOfClaims,
        bool[] calldata isConfirmed
    ) external;

    /// @notice calculates results of votes on a claim
    function calculateResult(uint256 claimIndex) external;

    /// @notice distribute rewards and slash penalties
    function receiveVoteResultBatch(uint256[] calldata claimIndexes) external;

    function transferLockedBMI(uint256 claimIndex, address claimer) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./IPolicyBookFacade.sol";

interface ICapitalPool {
    struct PremiumFactors {
        uint256 epochsNumber;
        uint256 premiumPrice;
        uint256 vStblDeployedByRP;
        uint256 vStblOfCP;
        uint256 poolUtilizationRation;
        uint256 premiumPerDeployment;
        uint256 userLeveragePoolsCount;
        IPolicyBookFacade policyBookFacade;
    }

    enum PoolType {COVERAGE, LEVERAGE, REINSURANCE}

    function virtualUsdtAccumulatedBalance() external view returns (uint256);

    function liquidityCushionBalance() external view returns (uint256);

    /// @notice distributes the policybook premiums into pools (CP, ULP , RP)
    /// @dev distributes the balances acording to the established percentages
    /// @param _stblAmount amount hardSTBL ingressed into the system
    /// @param _epochsNumber uint256 the number of epochs which the policy holder will pay a premium for
    /// @param _protocolFee uint256 the amount of protocol fee earned by premium
    function addPolicyHoldersHardSTBL(
        uint256 _stblAmount,
        uint256 _epochsNumber,
        uint256 _protocolFee
    ) external returns (uint256);

    /// @notice distributes the hardSTBL from the coverage providers
    /// @dev emits PoolBalancedUpdated event
    /// @param _stblAmount amount hardSTBL ingressed into the system
    function addCoverageProvidersHardSTBL(uint256 _stblAmount) external;

    /// @notice distributes the hardSTBL from the leverage providers
    /// @dev emits PoolBalancedUpdated event
    /// @param _stblAmount amount hardSTBL ingressed into the system
    function addLeverageProvidersHardSTBL(uint256 _stblAmount) external;

    /// @notice distributes the hardSTBL from the reinsurance pool
    /// @dev emits PoolBalancedUpdated event
    /// @param _stblAmount amount hardSTBL ingressed into the system
    function addReinsurancePoolHardSTBL(uint256 _stblAmount) external;

    /// @notice rebalances pools acording to v2 specification and dao enforced policies
    /// @dev  emits PoolBalancesUpdated
    function rebalanceLiquidityCushion() external;

    /// @notice Fullfils policybook claims by transfering the balance to claimer
    /// @param _claimer, address of the claimer recieving the withdraw
    /// @param _claimAmount uint256 amount to be withdrawn
    /// @param _policyBookAddress address of the policybook
    function fundClaim(
        address _claimer,
        uint256 _claimAmount,
        address _policyBookAddress
    ) external returns (uint256);

    /// @notice Fullfils policybook claims by transfering the balance to claimer
    /// @param _voter, address of the voter recieving the withdraw
    /// @param _rewardAmount uint256 amount to of the reward
    function fundReward(address _voter, uint256 _rewardAmount) external returns (uint256);

    /// @notice Withdraws liquidity from a specific policbybook to the user
    /// @param _sender, address of the user beneficiary of the withdraw
    /// @param _stblAmount uint256 amount to be withdrawn
    /// @param _isLeveragePool bool wether the pool is ULP or CP(policybook)
    function withdrawLiquidity(
        address _sender,
        uint256 _stblAmount,
        bool _isLeveragePool
    ) external returns (uint256);

    function rebalanceDuration() external view returns (uint256);

    function getWithdrawPeriod() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

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
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

uint256 constant SECONDS_IN_THE_YEAR = 365 * 24 * 60 * 60; // 365 days * 24 hours * 60 minutes * 60 seconds
uint256 constant DAYS_IN_THE_YEAR = 365;
uint256 constant MAX_INT = type(uint256).max;

uint256 constant DECIMALS18 = 10**18;

uint256 constant PRECISION = 10**25;
uint256 constant PERCENTAGE_100 = 100 * PRECISION;

uint256 constant BLOCKS_PER_DAY = 6450;
uint256 constant BLOCKS_PER_YEAR = BLOCKS_PER_DAY * 365;

uint256 constant APY_TOKENS = DECIMALS18;

uint256 constant PROTOCOL_PERCENTAGE = 20 * PRECISION;

uint256 constant DEFAULT_REBALANCING_THRESHOLD = 10**23;

uint256 constant EPOCH_DAYS_AMOUNT = 7;

// ClaimVoting ClaimingRegistry
uint256 constant APPROVAL_PERCENTAGE = 66 * PRECISION;
uint256 constant PENALTY_THRESHOLD = 11 * PRECISION;
uint256 constant QUORUM = 10 * PRECISION;
uint256 constant CALCULATION_REWARD_PER_DAY = PRECISION;
uint256 constant PERCENTAGE_50 = 50 * PRECISION;

// PolicyBook
uint256 constant MINUMUM_COVERAGE = 100 * DECIMALS18; // 100 STBL
uint256 constant ANNUAL_COVERAGE_TOKENS = MINUMUM_COVERAGE * 10; // 1000 STBL

uint256 constant PREMIUM_DISTRIBUTION_EPOCH = 1 days;
uint256 constant MAX_PREMIUM_DISTRIBUTION_EPOCHS = 90;

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
 * As of v3.0.0, only sets of type `address` (`AddressSet`) and `uint256`
 * (`UintSet`) are supported.
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
        mapping (bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

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
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
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
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
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
        return address(uint256(_at(set._inner, index)));
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol) {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
     *
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
     *
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
     *
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 * 
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 * 
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}