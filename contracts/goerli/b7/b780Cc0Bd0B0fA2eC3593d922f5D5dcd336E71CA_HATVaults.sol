// SPDX-License-Identifier: MIT
// Disclaimer https://github.com/hats-finance/hats-contracts/blob/main/DISCLAIMER.md

pragma solidity 0.8.14;

import "./vaults/Claim.sol";
import "./vaults/Deposit.sol";
import "./vaults/Params.sol";
import "./vaults/Pool.sol";
import "./vaults/Swap.sol";
import "./vaults/Getters.sol";
import "./vaults/Withdraw.sol";


/// @title Manage all Hats.finance vaults
/// Hats.finance is a proactive bounty protocol for white hat hackers and
/// auditors, where projects, community members, and stakeholders incentivize
/// protocol security and responsible disclosure.
/// Hats create scalable vaults using the project’s own token. The value of the
/// bounty increases with the success of the token and project.
/// This project is open-source and can be found on:
/// https://github.com/hats-finance/hats-contracts
contract HATVaults is Claim, Deposit, Params, Pool, Swap, Getters, Withdraw {
    /**
    * @notice initialize -
    * @param _hatGovernance The governance address.
    * Some of the contracts functions are limited only to governance:
    * addPool, setPool, dismissClaim, approveClaim, setHatVestingParams,
    * setVestingParams, setRewardsSplit
    * @param _swapToken the token that part of a payout will be swapped for
    * and burned - this would typically be HATs
    * @param _whitelistedRouters initial list of whitelisted routers allowed to
    * be used to swap tokens for HAT token.
    * @param _tokenLockFactory Address of the token lock factory to be used
    *        to create a vesting contract for the approved claim reporter.
    */
    constructor(
        address _hatGovernance,
        address _swapToken,
        address[] memory _whitelistedRouters,
        ITokenLockFactory _tokenLockFactory
    ) {
        _transferOwnership(_hatGovernance);
        swapToken = ERC20Burnable(_swapToken);

        for (uint256 i = 0; i < _whitelistedRouters.length; i++) {
            whitelistedRouters[_whitelistedRouters[i]] = true;
        }
        tokenLockFactory = _tokenLockFactory;
        generalParameters = GeneralParameters({
            hatVestingDuration: 90 days,
            hatVestingPeriods: 90,
            withdrawPeriod: 11 hours,
            safetyPeriod: 1 hours,
            setMaxBountyDelay: 2 days,
            withdrawRequestEnablePeriod: 7 days,
            withdrawRequestPendingPeriod: 7 days,
            claimFee: 0
        });
        arbitrator = _hatGovernance;
        challengePeriod = 3 days;
        challengeTimeOutPeriod = 5 weeks;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./Base.sol";

contract Claim is Base {
    using SafeERC20 for IERC20;

    /**
    * @notice emit an event that includes the given _descriptionHash
    * This can be used by the claimer as evidence that she had access to the information at the time of the call
    * if a claimFee > 0, the caller must send claimFee Ether for the claim to succeed
    * @param _descriptionHash - a hash of an ipfs encrypted file which describes the claim.
    */
    function logClaim(string memory _descriptionHash) external payable {
        if (generalParameters.claimFee > 0) {
            if (msg.value < generalParameters.claimFee)
                revert NotEnoughFeePaid();
            // solhint-disable-next-line indent
            payable(owner()).transfer(msg.value);
        }
        emit LogClaim(msg.sender, _descriptionHash);
    }

    /**
    * @notice Called by a committee to submit a claim for a bounty.
    * The submitted claim needs to be approved or dismissed by the Hats governance.
    * This function should be called only on a safety period, where withdrawals are disabled.
    * Upon a call to this function by the committee the pool withdrawals will be disabled
    * until the Hats governance will approve or dismiss this claim.
    * @param _pid The pool id
    * @param _beneficiary The submitted claim's beneficiary
    * @param _bountyPercentage The submitted claim's bug requested reward percentage
    */
    function submitClaim(uint256 _pid,
        address _beneficiary,
        uint256 _bountyPercentage,
        string calldata _descriptionHash)
    external
    onlyCommittee(_pid)
    noActiveClaims(_pid)
    {
        if (_beneficiary == address(0)) revert BeneficiaryIsZero();
        // require we are in safetyPeriod
        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp % (generalParameters.withdrawPeriod + generalParameters.safetyPeriod) <
        generalParameters.withdrawPeriod) revert NotSafetyPeriod();
        if (_bountyPercentage > bountyInfos[_pid].maxBounty)
            revert BountyPercentageHigherThanMaxBounty();
        uint256 claimId = uint256(keccak256(abi.encodePacked(_pid, block.number, nonce++)));
        claims[claimId] = Claim({
            pid: _pid,
            beneficiary: _beneficiary,
            bountyPercentage: _bountyPercentage,
            committee: msg.sender,
            // solhint-disable-next-line not-rely-on-time
            createdAt: block.timestamp,
            isChallenged: false
        });
        activeClaims[_pid] = claimId;
        emit SubmitClaim(
            _pid,
            claimId,
            msg.sender,
            _beneficiary,
            _bountyPercentage,
            _descriptionHash
        );
    }

    /**
    * @notice Called by a the arbitrator to challenge a claim
    * This will pause the vault for withdrawals until the claim is resolved
    * @param _claimId The id of the claim
    */

    function challengeClaim(uint256 _claimId) external onlyArbitrator {
        Claim storage claim = claims[_claimId];
        if (claim.beneficiary == address(0))
            revert NoActiveClaimExists();
        if (block.timestamp > claim.createdAt + challengeTimeOutPeriod)
            revert ChallengePeriodEnded();
        claim.isChallenged = true;
    }

    /**
    * @notice Approve a claim for a bounty submitted by a committee, and transfer bounty to hacker and committee.
    * callable by the  arbitrator, if isChallenged == true
    * Callable by anyone after challengePeriod is passed and isChallenged == false
    * @param _claimId The claim ID
    * @param _bountyPercentage The percentage of the vault's balance that will be send as a bounty.
    * The value for _bountyPercentage will be ignored if the caller is not the arbitrator
    */
    function approveClaim(uint256 _claimId, uint256 _bountyPercentage) external nonReentrant {
        Claim storage claim = claims[_claimId];
        if (claim.beneficiary == address(0)) revert NoActiveClaimExists();
        if (claim.isChallenged) {
            if (msg.sender != arbitrator) revert ClaimCanOnlyBeApprovedAfterChallengePeriodOrByArbitrator();
            claim.bountyPercentage = _bountyPercentage;
        } else {
            if (block.timestamp <= claim.createdAt + challengePeriod) revert ClaimCanOnlyBeApprovedAfterChallengePeriodOrByArbitrator();
        }

        uint256 pid = claim.pid;
        address tokenLock;
        BountyInfo storage bountyInfo = bountyInfos[pid];
        IERC20 lpToken = poolInfos[pid].lpToken;

        ClaimBounty memory claimBounty = calcClaimBounty(pid, claim.bountyPercentage);

        poolInfos[pid].balance -=
            claimBounty.hacker +
            claimBounty.hackerVested +
            claimBounty.committee +
            claimBounty.swapAndBurn +
            claimBounty.hackerHatVested +
            claimBounty.governanceHat;

        if (claimBounty.hackerVested > 0) {
            //hacker gets part of bounty to a vesting contract
            tokenLock = tokenLockFactory.createTokenLock(
                address(lpToken),
                0x000000000000000000000000000000000000dEaD, //this address as owner, so it can do nothing.
                claim.beneficiary,
                claimBounty.hackerVested,
                // solhint-disable-next-line not-rely-on-time
                block.timestamp, //start
                // solhint-disable-next-line not-rely-on-time
                block.timestamp + bountyInfo.vestingDuration, //end
                bountyInfo.vestingPeriods,
                0, //no release start
                0, //no cliff
                ITokenLock.Revocability.Disabled,
                false
            );
            lpToken.safeTransfer(tokenLock, claimBounty.hackerVested);
        }

        lpToken.safeTransfer(claim.beneficiary, claimBounty.hacker);
        lpToken.safeTransfer(claim.committee, claimBounty.committee);
        //storing the amount of token which can be swap and burned so it could be swapAndBurn in a separate tx.
        swapAndBurns[pid] += claimBounty.swapAndBurn;
        governanceHatRewards[pid] += claimBounty.governanceHat;
        hackersHatRewards[claim.beneficiary][pid] += claimBounty.hackerHatVested;
        // emit event before deleting the claim object, bcause we want to read beneficiary and bountyPercentage
        emit ApproveClaim(pid,
            _claimId,
            msg.sender,
            claim.beneficiary,
            claim.bountyPercentage,
            tokenLock,
            claimBounty);

        delete activeClaims[pid];
        delete claims[_claimId];
    }

    /**
    * @notice Dismiss a claim for a bounty submitted by a committee.
    * Called either by the arbitrator, or by anyone if the claim is over 5 weeks old.
    * @param _claimId The claim ID
    */
    function dismissClaim(uint256 _claimId) external {
        Claim storage claim = claims[_claimId];
        uint256 pid = claim.pid;
        // solhint-disable-next-line not-rely-on-time
        if (!(msg.sender == arbitrator && claim.isChallenged) &&
            (claim.createdAt + challengeTimeOutPeriod > block.timestamp))
            revert OnlyCallableByArbitratorOrAfterChallengeTimeOutPeriod();
        if (claim.beneficiary == address(0)) revert NoActiveClaimExists();
        delete activeClaims[pid];
        delete claims[_claimId];
        emit DismissClaim(pid, _claimId);
    }


    function calcClaimBounty(uint256 _pid, uint256 _bountyPercentage)
    public
    view
    returns(ClaimBounty memory claimBounty) {
        uint256 totalSupply = poolInfos[_pid].balance;
        if (totalSupply == 0) revert PoolBalanceIsZero();
        if (_bountyPercentage > bountyInfos[_pid].maxBounty)
            revert BountyPercentageHigherThanMaxBounty();
        uint256 totalBountyAmount = totalSupply * _bountyPercentage;
        claimBounty.hackerVested =
        totalBountyAmount * bountyInfos[_pid].bountySplit.hackerVested
        / (HUNDRED_PERCENT * HUNDRED_PERCENT);
        claimBounty.hacker =
        totalBountyAmount * bountyInfos[_pid].bountySplit.hacker
        / (HUNDRED_PERCENT * HUNDRED_PERCENT);
        claimBounty.committee =
        totalBountyAmount * bountyInfos[_pid].bountySplit.committee
        / (HUNDRED_PERCENT * HUNDRED_PERCENT);
        claimBounty.swapAndBurn =
        totalBountyAmount * bountyInfos[_pid].bountySplit.swapAndBurn
        / (HUNDRED_PERCENT * HUNDRED_PERCENT);
        claimBounty.governanceHat =
        totalBountyAmount * bountyInfos[_pid].bountySplit.governanceHat
        / (HUNDRED_PERCENT * HUNDRED_PERCENT);
        claimBounty.hackerHatVested =
        totalBountyAmount * bountyInfos[_pid].bountySplit.hackerHatVested
        / (HUNDRED_PERCENT * HUNDRED_PERCENT);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./Base.sol";

contract Deposit is Base {
    using SafeERC20 for IERC20;

    /**
    * @notice Deposit tokens to pool
    * Caller must have set an allowance first
    * @param _pid The pool id
    * @param _amount Amount of pool's token to deposit.
    **/
    function deposit(uint256 _pid, uint256 _amount) external nonReentrant {
        if (!poolInfos[_pid].committeeCheckedIn)
            revert CommitteeNotCheckedInYet();
        if (poolDepositPause[_pid]) revert DepositPaused();
        if (!poolInitialized[_pid]) revert PoolMustBeInitialized();
        
        //clear withdraw request
        withdrawEnableStartTime[_pid][msg.sender] = 0;
        PoolInfo storage pool = poolInfos[_pid];
        uint256 lpSupply = pool.balance;
        uint256 balanceBefore = pool.lpToken.balanceOf(address(this));

        pool.lpToken.safeTransferFrom(msg.sender, address(this), _amount);

        uint256 transferredAmount = pool.lpToken.balanceOf(address(this)) - balanceBefore;

        if (transferredAmount == 0) revert AmountToDepositIsZero();

        pool.balance += transferredAmount;

        // create new shares (and add to the user and the pool's shares) that are the relative part of the user's new deposit
        // out of the pool's total supply, relative to the previous total shares in the pool
        uint256 addedUserShares;
        if (pool.totalShares == 0) {
            addedUserShares = transferredAmount;
        } else {
            addedUserShares = pool.totalShares * transferredAmount / lpSupply;
        }

        pool.rewardController.updateRewardPool(_pid, msg.sender, addedUserShares, true, true);

        userShares[_pid][msg.sender] += addedUserShares;
        pool.totalShares += addedUserShares;

        emit Deposit(msg.sender, _pid, _amount, transferredAmount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./Base.sol";

contract Params is Base {

    function setFeeSetter(address _newFeeSetter) external onlyOwner {
        feeSetter = _newFeeSetter;
        emit SetFeeSetter(_newFeeSetter);
    }

    /**
    * @notice Set new committee address. Can be called by existing committee if it had checked in, or
    * by the governance otherwise.
    * @param _pid pool id
    * @param _committee new committee address
    */
    function setCommittee(uint256 _pid, address _committee)
    external {
        if (_committee == address(0)) revert CommitteeIsZero();
        //governance can update committee only if committee was not checked in yet.
        if (msg.sender == owner() && committees[_pid] != msg.sender) {
            if (poolInfos[_pid].committeeCheckedIn)
                revert CommitteeAlreadyCheckedIn();
        } else {
            if (committees[_pid] != msg.sender) revert OnlyCommittee();
        }

        committees[_pid] = _committee;

        emit SetCommittee(_pid, _committee);
    }

   /**
     * @notice setArbitrator - called by hats governance to set arbitrator
     * @param _arbitrator New arbitrator.
    */
    function setArbitrator(address _arbitrator) external onlyOwner {
        arbitrator = _arbitrator;
        emit SetArbitrator(_arbitrator);
    }

    /**
    * @notice setWithdrawRequestParams - called by hats governance to set withdraw request params
    * @param _withdrawRequestPendingPeriod - the time period where the withdraw request is pending.
    * @param _withdrawRequestEnablePeriod - the time period where the withdraw is enable for a withdraw request.
    */
    function setWithdrawRequestParams(uint256 _withdrawRequestPendingPeriod, uint256  _withdrawRequestEnablePeriod)
    external
    onlyOwner {
        if (90 days < _withdrawRequestPendingPeriod)
            revert WithdrawRequestPendingPeriodTooLong();
        if (6 hours > _withdrawRequestEnablePeriod)
            revert WithdrawRequestEnabledPeriodTooShort();
        generalParameters.withdrawRequestPendingPeriod = _withdrawRequestPendingPeriod;
        generalParameters.withdrawRequestEnablePeriod = _withdrawRequestEnablePeriod;
        emit SetWithdrawRequestParams(_withdrawRequestPendingPeriod, _withdrawRequestEnablePeriod);
    }

    /**
     * @notice Called by hats governance to set fee for submitting a claim to any vault
     * @param _fee claim fee in ETH
    */
    function setClaimFee(uint256 _fee) external onlyOwner {
        generalParameters.claimFee = _fee;
        emit SetClaimFee(_fee);
    }

    function setChallengePeriod(uint256 _challengePeriod) external onlyOwner {
        challengePeriod = _challengePeriod;
        emit SetChallengePeriod(_challengePeriod);
    }

    function setChallengeTimeOutPeriod(uint256 _challengeTimeOutPeriod) external onlyOwner {
        challengeTimeOutPeriod = _challengeTimeOutPeriod;
        emit SetChallengeTimeOutPeriod(_challengeTimeOutPeriod);
    }

    /**
     * @notice setWithdrawSafetyPeriod - called by hats governance to set Withdraw Period
     * @param _withdrawPeriod withdraw enable period
     * @param _safetyPeriod withdraw disable period
    */
    function setWithdrawSafetyPeriod(uint256 _withdrawPeriod, uint256 _safetyPeriod) external onlyOwner {
        if (1 hours > _withdrawPeriod) revert WithdrawPeriodTooShort();
        if (_safetyPeriod > 6 hours) revert SafetyPeriodTooLong();
        generalParameters.withdrawPeriod = _withdrawPeriod;
        generalParameters.safetyPeriod = _safetyPeriod;
        emit SetWithdrawSafetyPeriod(_withdrawPeriod, _safetyPeriod);
    }

    /**
    * @notice setVestingParams - set pool vesting params for rewarding claim reporter with the pool token
    * @param _pid pool id
    * @param _duration duration of the vesting period
    * @param _periods the vesting periods
    */
    function setVestingParams(uint256 _pid, uint256 _duration, uint256 _periods) external onlyOwner {
        if (_duration >= 120 days) revert VestingDurationTooLong();
        if (_periods == 0) revert VestingPeriodsCannotBeZero();
        if (_duration < _periods) revert VestingDurationSmallerThanPeriods();
        bountyInfos[_pid].vestingDuration = _duration;
        bountyInfos[_pid].vestingPeriods = _periods;
        emit SetVestingParams(_pid, _duration, _periods);
    }

    /**
    * @notice setHatVestingParams - set vesting params for rewarding claim reporters with rewardToken, for all pools
    * the function can be called only by governance.
    * @param _duration duration of the vesting period
    * @param _periods the vesting periods
    */
    function setHatVestingParams(uint256 _duration, uint256 _periods) external onlyOwner {
        if (_duration >= 180 days) revert VestingDurationTooLong();
        if (_periods == 0) revert VestingPeriodsCannotBeZero();
        if (_duration < _periods) revert VestingDurationSmallerThanPeriods();
        generalParameters.hatVestingDuration = _duration;
        generalParameters.hatVestingPeriods = _periods;
        emit SetHatVestingParams(_duration, _periods);
    }

    /**
    * @notice Set the pool token bounty split upon an approval
    * The function can be called only by governance.
    * @param _pid The pool id
    * @param _bountySplit The bounty split
    */
    function setBountySplit(uint256 _pid, BountySplit memory _bountySplit)
    external
    onlyOwner noActiveClaims(_pid) noSafetyPeriod {
        validateSplit(_bountySplit);
        bountyInfos[_pid].bountySplit = _bountySplit;
        emit SetBountySplit(_pid, _bountySplit);
    }

    /**
    * @notice Set the timelock delay for setting the max bounty
    * (the time between setPendingMaxBounty and setMaxBounty)
    * @param _delay The delay time
    */
    function setMaxBountyDelay(uint256 _delay)
    external
    onlyOwner {
        if (_delay < 2 days) revert DelayTooShort();
        generalParameters.setMaxBountyDelay = _delay;
        emit SetMaxBountyDelay(_delay);
    }

    function setRouterWhitelistStatus(address _router, bool _isWhitelisted) external onlyOwner {
        whitelistedRouters[_router] = _isWhitelisted;
        emit RouterWhitelistStatusChanged(_router, _isWhitelisted);
    }

    function setPoolWithdrawalFee(uint256 _pid, uint256 _newFee) external onlyFeeSetter {
        if (_newFee > MAX_FEE) revert PoolWithdrawalFeeTooBig();
        poolInfos[_pid].withdrawalFee = _newFee;
        emit SetPoolWithdrawalFee(_pid, _newFee);
    }

    /**
       * @notice committeeCheckIn - committee check in.
    * deposit is enable only after committee check in
    * @param _pid pool id
    */
    function committeeCheckIn(uint256 _pid) external onlyCommittee(_pid) {
        poolInfos[_pid].committeeCheckedIn = true;
        emit CommitteeCheckedIn(_pid);
    }

    /**
   * @notice Set pending request to set pool max bounty.
    * The function can be called only by the pool committee.
    * Cannot be called if there are claims that have been submitted.
    * Max bounty should be less than or equal to `HUNDRED_PERCENT`
    * @param _pid The pool id
    * @param _maxBounty The maximum bounty percentage that can be paid out
    */
    function setPendingMaxBounty(uint256 _pid, uint256 _maxBounty)
    external
    onlyCommittee(_pid) noActiveClaims(_pid) {
        if (_maxBounty > HUNDRED_PERCENT)
            revert MaxBountyCannotBeMoreThanHundredPercent();
        pendingMaxBounty[_pid].maxBounty = _maxBounty;
        // solhint-disable-next-line not-rely-on-time
        pendingMaxBounty[_pid].timestamp = block.timestamp;
        emit SetPendingMaxBounty(_pid, _maxBounty, pendingMaxBounty[_pid].timestamp);
    }

    /**
   * @notice Set the pool max bounty to the already pending max bounty.
   * The function can be called only by the pool committee.
   * Cannot be called if there are claims that have been submitted.
   * Can only be called if there is a max bounty pending approval, and the time delay since setting the pending max bounty
   * had passed.
   * Max bounty should be less than `HUNDRED_PERCENT`
   * @param _pid The pool id
 */
    function setMaxBounty(uint256 _pid)
    external
    onlyCommittee(_pid) noActiveClaims(_pid) {
        if (pendingMaxBounty[_pid].timestamp == 0) revert NoPendingMaxBounty();
        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp - pendingMaxBounty[_pid].timestamp <
            generalParameters.setMaxBountyDelay)
            revert DelayPeriodForSettingMaxBountyHadNotPassed();
        bountyInfos[_pid].maxBounty = pendingMaxBounty[_pid].maxBounty;
        delete pendingMaxBounty[_pid];
        emit SetMaxBounty(_pid, bountyInfos[_pid].maxBounty);
    }

    function setRewardController(uint256 _pid, IRewardController _newRewardController) public onlyOwner {
        poolInfos[_pid].rewardController = _newRewardController;
        emit SetRewardController(_pid, _newRewardController);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./Base.sol";

contract Pool is Base {

    /**
    * @notice Add a new pool. Can be called only by governance.
    * @param _lpToken The pool's token
    * @param _committee The pool's committee addres
    * @param _maxBounty The pool's max bounty.
    * @param _bountySplit The way to split the bounty between the hacker, committee and governance.
        Each entry is a number between 0 and `HUNDRED_PERCENT`.
        Total splits should be equal to `HUNDRED_PERCENT`.
        Bounty must be specified for the hacker (direct or vested in pool's token).
    * @param _descriptionHash the hash of the pool description.
    * @param _bountyVestingParams vesting params for the bounty
    *        _bountyVestingParams[0] - vesting duration
    *        _bountyVestingParams[1] - vesting periods
    */

    function addPool(
        address _lpToken,
        address _committee,
        IRewardController _rewardController,
        uint256 _maxBounty,
        BountySplit memory _bountySplit,
        string memory _descriptionHash,
        uint256[2] memory _bountyVestingParams,
        bool _isPaused,
        bool _isInitialized
    ) 
    external 
    onlyOwner 
    {
        if (_bountyVestingParams[0] > 120 days)
            revert VestingDurationTooLong();
        if (_bountyVestingParams[1] == 0) revert VestingPeriodsCannotBeZero();
        if (_bountyVestingParams[0] < _bountyVestingParams[1])
            revert VestingDurationSmallerThanPeriods();
        if (_committee == address(0)) revert CommitteeIsZero();
        if (_lpToken == address(0)) revert LPTokenIsZero();
        if (_maxBounty > HUNDRED_PERCENT)
            revert MaxBountyCannotBeMoreThanHundredPercent();
            
        validateSplit(_bountySplit);

        uint256 poolId = poolInfos.length;

        poolInfos.push(PoolInfo({
            committeeCheckedIn: false,
            lpToken: IERC20(_lpToken),
            totalShares: 0,
            balance: 0,
            withdrawalFee: 0,
            rewardController: _rewardController
        }));

        bountyInfos[poolId] = BountyInfo({
            maxBounty: _maxBounty,
            bountySplit: _bountySplit,
            vestingDuration: _bountyVestingParams[0],
            vestingPeriods: _bountyVestingParams[1]
        });

        committees[poolId] = _committee;
        poolDepositPause[poolId] = _isPaused;
        poolInitialized[poolId] = _isInitialized;

        emit AddPool(poolId,
            _lpToken,
            _committee,
            _rewardController,
            _descriptionHash,
            _maxBounty,
            _bountySplit,
            _bountyVestingParams[0],
            _bountyVestingParams[1]);
    }

    /**
    * @notice change the information for a pool
    * ony calleable by the owner of the contract
    * @param _pid the pool id
    * @param _visible is this pool visible in the UI
    * @param _depositPause pause pool deposit (default false).
    * This parameter can be used by the UI to include or exclude the pool
    * @param _descriptionHash the hash of the pool description.
    */
    function setPool(
        uint256 _pid,
        bool _visible,
        bool _depositPause,
        string memory _descriptionHash
    ) external onlyOwner {
        if (poolInfos.length <= _pid) revert PoolDoesNotExist();

        poolDepositPause[_pid] = _depositPause;

        emit SetPool(_pid, _visible, _depositPause, _descriptionHash);
    }
    /**
    * @notice set the flag that the pool is initialized to true
    * ony calleable by the owner of the contract
    * @param _pid the pool id
    */
    function setPoolInitialized(uint256 _pid) external onlyOwner {
        if (poolInfos.length <= _pid) revert PoolDoesNotExist();

        poolInitialized[_pid] = true;
    }

    /**
    * @notice set the shares of users in a pool
    * only calleable by the owner, and only when a pool is not initialized
    * This function is used for migrating older pool data to this new contract
    */
    function setShares(
        uint256 _pid,
        uint256 _rewardPerShare,
        uint256 _balance,
        address[] memory _accounts,
        uint256[] memory _shares,
        uint256[] memory _rewardDebts)
    external onlyOwner {
        if (poolInfos.length <= _pid) revert PoolDoesNotExist();
        if (poolInitialized[_pid]) revert PoolMustNotBeInitialized();
        if (_accounts.length != _shares.length ||
            _accounts.length != _rewardDebts.length)
            revert SetSharesArraysMustHaveSameLength();

        PoolInfo storage pool = poolInfos[_pid];
        pool.balance = _balance;

        for (uint256 i = 0; i < _accounts.length; i++) {
            userShares[_pid][_accounts[i]] = _shares[i];
            pool.totalShares += _shares[i];
        }

        pool.rewardController.setShares(_pid, _rewardPerShare, _accounts, _rewardDebts);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./Base.sol";

contract Swap is Base {
    using SafeERC20 for ERC20Burnable;

    /**
    * @notice Swap pool's token to swapToken.
    * Send to beneficiary and governance their HATs rewards.
    * Burn the rest of swapToken.
    * Only governance is authorized to call this function.
    * @param _pid the pool id
    * @param _beneficiary beneficiary
    * @param _amountOutMinimum minimum output of swapToken at swap
    * @param _routingContract routing contract to call for the swap
    * @param _routingPayload payload to send to the _routingContract for the swap
    **/
    function swapBurnSend(uint256 _pid,
        address _beneficiary,
        uint256 _amountOutMinimum,
        address _routingContract,
        bytes calldata _routingPayload)
    external
    onlyOwner {
        uint256 amountToSwapAndBurn = swapAndBurns[_pid];
        uint256 amountForHackersHatRewards = hackersHatRewards[_beneficiary][_pid];
        uint256 amount = amountToSwapAndBurn + amountForHackersHatRewards + governanceHatRewards[_pid];
        if (amount == 0) revert AmountToSwapIsZero();
        swapAndBurns[_pid] = 0;
        governanceHatRewards[_pid] = 0;
        hackersHatRewards[_beneficiary][_pid] = 0;
        uint256 hatsReceived = swapTokenForHAT(amount, poolInfos[_pid].lpToken, _amountOutMinimum, _routingContract, _routingPayload);
        uint256 burntHats = hatsReceived * amountToSwapAndBurn / amount;
        if (burntHats > 0) {
            swapToken.burn(burntHats);
        }
        emit SwapAndBurn(_pid, amount, burntHats);

        address tokenLock;
        uint256 hackerReward = hatsReceived * amountForHackersHatRewards / amount;
        if (hackerReward > 0) {
            // hacker gets her reward via vesting contract
            tokenLock = tokenLockFactory.createTokenLock(
                address(swapToken),
                0x000000000000000000000000000000000000dEaD, //this address as owner, so it can do nothing.
                _beneficiary,
                hackerReward,
                // solhint-disable-next-line not-rely-on-time
                block.timestamp, //start
                // solhint-disable-next-line not-rely-on-time
                block.timestamp + generalParameters.hatVestingDuration, //end
                generalParameters.hatVestingPeriods,
                0, // no release start
                0, // no cliff
                ITokenLock.Revocability.Disabled,
                true
            );
            swapToken.safeTransfer(tokenLock, hackerReward);
        }
        emit SwapAndSend(_pid, _beneficiary, amount, hackerReward, tokenLock);
        swapToken.safeTransfer(owner(), hatsReceived - hackerReward - burntHats);
    }

    function swapTokenForHAT(uint256 _amount,
        IERC20 _token,
        uint256 _amountOutMinimum,
        address _routingContract,
        bytes calldata _routingPayload)
    internal
    returns (uint256 swapTokenReceived)
    {
        if (address(_token) == address(swapToken)) {
            return _amount;
        }
        if (!whitelistedRouters[_routingContract])
            revert RoutingContractNotWhitelisted();
        if (!_token.approve(_routingContract, _amount))
            revert TokenApproveFailed();
        uint256 balanceBefore = swapToken.balanceOf(address(this));

        // solhint-disable-next-line avoid-low-level-calls
        (bool success,) = _routingContract.call(_routingPayload);
        if (!success) revert SwapFailed();
        swapTokenReceived = swapToken.balanceOf(address(this)) - balanceBefore;
        if (swapTokenReceived < _amountOutMinimum)
            revert AmountSwappedLessThanMinimum();
            
        if (!_token.approve(address(_routingContract), 0))
            revert TokenApproveResetFailed();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./Base.sol";

contract Getters is Base {
    function getNumberOfPools() external view returns (uint256) {
        return poolInfos.length;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./Base.sol";

contract Withdraw is Base {
    using SafeERC20 for IERC20;

    /**
    * @notice Submit a request to withdraw funds from pool # `_pid`.
    * The request will only be approved if the last action was a deposit or withdrawal or in case the last action was a withdraw request,
    * that the pending period (of `generalParameters.withdrawRequestPendingPeriod`) had ended and the withdraw enable period (of `generalParameters.withdrawRequestEnablePeriod`)
    * had also ended.
    * @param _pid The pool ID
    **/
    function withdrawRequest(uint256 _pid) external nonReentrant {
        // require withdraw to be at least withdrawRequestEnablePeriod+withdrawRequestPendingPeriod since last withdrawwithdrawRequest
        // unless there's been a deposit or withdraw since, in which case withdrawRequest is allowed immediately
        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp <
            withdrawEnableStartTime[_pid][msg.sender] +
                generalParameters.withdrawRequestEnablePeriod)
            revert PendingWithdrawRequestExists();
        // set the withdrawRequests time to be withdrawRequestPendingPeriod from now
        // solhint-disable-next-line not-rely-on-time
        withdrawEnableStartTime[_pid][msg.sender] = block.timestamp + generalParameters.withdrawRequestPendingPeriod;
        emit WithdrawRequest(_pid, msg.sender, withdrawEnableStartTime[_pid][msg.sender]);
    }

    /**
    * @notice Withdraw user's requested share from the pool.
    * The withdrawal will only take place if the user has submitted a withdraw request, and the pending period of
    * `generalParameters.withdrawRequestPendingPeriod` had passed since then, and we are within the period where
    * withdrawal is enabled, meaning `generalParameters.withdrawRequestEnablePeriod` had not passed since the pending period
    * had finished.
    * @param _pid The pool id
    * @param _shares Amount of shares user wants to withdraw
    **/
    function withdraw(uint256 _pid, uint256 _shares) external nonReentrant {
        checkWithdrawAndResetWithdrawEnableStartTime(_pid);
        PoolInfo storage pool = poolInfos[_pid];

        if (userShares[_pid][msg.sender] < _shares) revert NotEnoughUserBalance();

        pool.rewardController.updateRewardPool(_pid, msg.sender, _shares, false, true);

        if (_shares > 0) {
            userShares[_pid][msg.sender] -= _shares;
            uint256 amountToWithdraw = (_shares * pool.balance) / pool.totalShares;
            uint256 fee = amountToWithdraw * pool.withdrawalFee / HUNDRED_PERCENT;
            pool.balance -= amountToWithdraw;
            pool.totalShares -= _shares;
            safeWithdrawPoolToken(pool.lpToken, amountToWithdraw, fee);
        }

        emit Withdraw(msg.sender, _pid, _shares);
    }

    /**
    * @notice Withdraw all user's pool share without claim for reward.
    * The withdrawal will only take place if the user has submitted a withdraw request, and the pending period of
    * `generalParameters.withdrawRequestPendingPeriod` had passed since then, and we are within the period where
    * withdrawal is enabled, meaning `generalParameters.withdrawRequestEnablePeriod` had not passed since the pending period
    * had finished.
    * @param _pid The pool id
    **/
    function emergencyWithdraw(uint256 _pid) external nonReentrant {
        checkWithdrawAndResetWithdrawEnableStartTime(_pid);

        PoolInfo storage pool = poolInfos[_pid];
        uint256 currentUserShares = userShares[_pid][msg.sender];
        if (currentUserShares == 0) revert UserSharesMustBeGreaterThanZero();

        pool.rewardController.updateRewardPool(_pid, msg.sender, currentUserShares, false, false);

        uint256 factoredBalance = (currentUserShares * pool.balance) / pool.totalShares;
        uint256 fee = (factoredBalance * pool.withdrawalFee) / HUNDRED_PERCENT;

        pool.totalShares -= currentUserShares;
        pool.balance -= factoredBalance;
        userShares[_pid][msg.sender] = 0;
        
        safeWithdrawPoolToken(pool.lpToken, factoredBalance, fee);

        emit EmergencyWithdraw(msg.sender, _pid, factoredBalance);
    }

    // @notice Checks that the sender can perform a withdraw at this time
    // and also sets the withdrawRequest to 0
    function checkWithdrawAndResetWithdrawEnableStartTime(uint256 _pid)
        internal
        noActiveClaims(_pid)
        noSafetyPeriod
    {
        // check that withdrawRequestPendingPeriod had passed
        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp < withdrawEnableStartTime[_pid][msg.sender] ||
        // check that withdrawRequestEnablePeriod had not passed and that the
        // last action was withdrawRequest (and not deposit or withdraw, which
        // reset withdrawRequests[_pid][msg.sender] to 0)
        // solhint-disable-next-line not-rely-on-time
            block.timestamp >
                withdrawEnableStartTime[_pid][msg.sender] +
                generalParameters.withdrawRequestEnablePeriod)
            revert InvalidWithdrawRequest();
        // if all is ok and withdrawal can be made - reset withdrawRequests[_pid][msg.sender] so that another withdrawRequest
        // will have to be made before next withdrawal
        withdrawEnableStartTime[_pid][msg.sender] = 0;
    }

    function safeWithdrawPoolToken(IERC20 _lpToken, uint256 _totalAmount, uint256 _fee)
        internal
    {
        if (_fee > 0) {
            _lpToken.safeTransfer(owner(), _fee);
        }
        _lpToken.safeTransfer(msg.sender, _totalAmount - _fee);
    }
}

// SPDX-License-Identifier: MIT
// Disclaimer https://github.com/hats-finance/hats-contracts/blob/main/DISCLAIMER.md

pragma solidity 0.8.14;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "../tokenlock/TokenLockFactory.sol";
import "../interfaces/IRewardController.sol";

// Errors:
// Only committee
error OnlyCommittee();
// Active claim exists
error ActiveClaimExists();
// Safety period
error SafetyPeriod();
// Beneficiary is zero
error BeneficiaryIsZero();
// Not safety period
error NotSafetyPeriod();
// Bounty percentage is higher than the max bounty
error BountyPercentageHigherThanMaxBounty();
// Withdraw request pending period must be <= 3 months
error WithdrawRequestPendingPeriodTooLong();
// Withdraw request enabled period must be >= 6 hour
error WithdrawRequestEnabledPeriodTooShort();
// Only callable by arbitrator or after challenge timeout period
error OnlyCallableByArbitratorOrAfterChallengeTimeOutPeriod();
// No active claim exists
error NoActiveClaimExists();
// Withdraw period must be >= 1 hour
error WithdrawPeriodTooShort();
// Safety period must be <= 6 hours
error SafetyPeriodTooLong();
// Not enough fee paid
error NotEnoughFeePaid();
// Vesting duration is too long
error VestingDurationTooLong();
// Vesting periods cannot be zero
error VestingPeriodsCannotBeZero();
// Vesting duration smaller than periods
error VestingDurationSmallerThanPeriods();
// Delay is too short
error DelayTooShort();
// No pending max bounty
error NoPendingMaxBounty();
// Delay period for setting max bounty had not passed
error DelayPeriodForSettingMaxBountyHadNotPassed();
// Committee is zero
error CommitteeIsZero();
// Committee already checked in
error CommitteeAlreadyCheckedIn();
// Pool does not exist
error PoolDoesNotExist();
// Amount to swap is zero
error AmountToSwapIsZero();
// Pending withdraw request exists
error PendingWithdrawRequestExists();
// Deposit paused
error DepositPaused();
// Amount to deposit is zero
error AmountToDepositIsZero();
// Pool balance is zero
error PoolBalanceIsZero();
// Total bounty split % should be `HUNDRED_PERCENT`
error TotalSplitPercentageShouldBeHundredPercent();
// Withdraw request is invalid
error InvalidWithdrawRequest();
// Token approve failed
error TokenApproveFailed();
// Wrong amount received
error AmountSwappedLessThanMinimum();
// Max bounty cannot be more than `HUNDRED_PERCENT`
error MaxBountyCannotBeMoreThanHundredPercent();
// LP token is zero
error LPTokenIsZero();
// Only fee setter
error OnlyFeeSetter();
// Fee must be less than or equal to 2%
error PoolWithdrawalFeeTooBig();
// Token approve reset failed
error TokenApproveResetFailed();
// Pool must not be initialized
error PoolMustNotBeInitialized();
// Pool must be initialized
error PoolMustBeInitialized();
// Set shares arrays must have same length
error SetSharesArraysMustHaveSameLength();
// Committee not checked in yet
error CommitteeNotCheckedInYet();
// Not enough user balance
error NotEnoughUserBalance();
// User shares must be greater than 0
error UserSharesMustBeGreaterThanZero();
// Swap was not successful
error SwapFailed();
// Routing contract must be whitelisted
error RoutingContractNotWhitelisted();
// Only arbitrator
error OnlyArbitrator();
// Claim can only be approved if challenge period is over, or if the
// caller is the arbitrator
error ClaimCanOnlyBeApprovedAfterChallengePeriodOrByArbitrator();
// Bounty split must include hacker payout
error BountySplitMustIncludeHackerPayout();
error ChallengePeriodEnded();


contract Base is Ownable, ReentrancyGuard {
    // Parameters that apply to all the vaults
    using SafeERC20 for IERC20;
    using SafeERC20 for ERC20Burnable;
    
    struct GeneralParameters {
        uint256 hatVestingDuration;
        uint256 hatVestingPeriods;
        // withdraw enable period. safetyPeriod starts when finished.
        uint256 withdrawPeriod;
        // withdraw disable period - time for the committee to gather and decide on actions,
        // withdrawals are not possible in this time. withdrawPeriod starts when finished.
        uint256 safetyPeriod;
        // period of time after withdrawRequestPendingPeriod where it is possible to withdraw
        // (after which withdrawal is not possible)
        uint256 withdrawRequestEnablePeriod;
        // period of time that has to pass after withdraw request until withdraw is possible
        uint256 withdrawRequestPendingPeriod;
        uint256 setMaxBountyDelay;
        uint256 claimFee;  //claim fee in ETH
    }

    // Info of each pool.
    struct PoolInfo {
        bool committeeCheckedIn;
        IERC20 lpToken;
        // total amount of LP tokens in pool
        uint256 balance;
        uint256 totalShares;
        // fee to take from withdrawals to governance
        uint256 withdrawalFee;
        
        IRewardController rewardController;
    }

    // Info of each pool's bounty policy.
    struct BountyInfo {
        BountySplit bountySplit;
        uint256 maxBounty;
        uint256 vestingDuration;
        uint256 vestingPeriods;
    }

    // How to divide the bounties for each pool, in percentages (out of `HUNDRED_PERCENT`)
    struct BountySplit {
        //the percentage of the total bounty to reward the hacker via vesting contract
        uint256 hackerVested;
        //the percentage of the total bounty to reward the hacker
        uint256 hacker;
        // the percentage of the total bounty to be sent to the committee
        uint256 committee;
        // the percentage of the total bounty to be swapped to HATs and then burned
        uint256 swapAndBurn;
        // the percentage of the total bounty to be swapped to HATs and sent to governance
        uint256 governanceHat;
        // the percentage of the total bounty to be swapped to HATs and sent to the hacker via vesting contract
        uint256 hackerHatVested;
    }

    // How to divide a bounty for a claim that has been approved, in amounts of pool's tokens
    struct ClaimBounty {
        uint256 hacker;
        uint256 hackerVested;
        uint256 committee;
        uint256 swapAndBurn;
        uint256 hackerHatVested;
        uint256 governanceHat;
    }

    // Info of a claim for a bounty payout that has been submitted by a committee
    struct Claim {
        uint256 pid;
        address beneficiary;
        uint256 bountyPercentage;
        // the address of the committee at the time of the submittal, so that this committee will
        // be payed their share of the bounty in case the committee changes before claim approval
        address committee;
        uint256 createdAt;
        bool isChallenged;
    }

    struct PendingMaxBounty {
        uint256 maxBounty;
        uint256 timestamp;
    }

    uint256 public constant HUNDRED_PERCENT = 10000;
    uint256 public constant MAX_FEE = 200; // Max fee is 2%

    // PARAMETERS FOR ALL VAULTS
    // time during which a claim can be challenged by the arbitrator
    uint256 public challengePeriod;
    // time after which a challenged claim is automatically dismissed
    uint256 public challengeTimeOutPeriod;
    // a struct with parameters for all vaults
    GeneralParameters public generalParameters;
    // rewardController determines how many rewards each pool gets in the incentive program
    ITokenLockFactory public tokenLockFactory;
    // feeSetter sets the withdrawal fee
    address public feeSetter;
    // address of the arbitrator - which can dispute claims and override the committee's decisions
    address public arbitrator;
    // the token into which a part of the the bounty will be swapped-into-and-burnt - this will
    // typically be HATs
    ERC20Burnable public swapToken;
    mapping(address => bool) public whitelistedRouters;
    uint256 internal nonce;

    // PARAMETERS PER VAULT
    PoolInfo[] public poolInfos;
    // Info of each pool.
    // poolId -> committee address
    mapping(uint256 => address) public committees;
    // Info of each user that stakes LP tokens. poolId => user address => shares
    mapping(uint256 => mapping(address => uint256)) public userShares;
    // poolId -> BountyInfo
    mapping(uint256 => BountyInfo) public bountyInfos;
    // poolId -> PendingMaxBounty
    mapping(uint256 => PendingMaxBounty) public pendingMaxBounty;
    // poolId -> claimId
    mapping(uint256 => uint256) public activeClaims;
    // poolId -> isPoolInitialized
    mapping(uint256 => bool) public poolInitialized;
    // poolID -> isPoolPausedForDeposit
    mapping(uint256 => bool) public poolDepositPause;
    // Time of when last withdraw request pending period ended, or 0 if last action was deposit or withdraw
    // poolId -> (address -> requestTime)
    mapping(uint256 => mapping(address => uint256)) public withdrawEnableStartTime;

    // PARAMETERS PER CLAIM
    // claimId -> Claim
    mapping(uint256 => Claim) public claims;
    // poolId -> amount
    mapping(uint256 => uint256) public swapAndBurns;
    // hackerAddress -> (pid -> amount)
    mapping(address => mapping(uint256 => uint256)) public hackersHatRewards;
    // poolId -> amount
    mapping(uint256 => uint256) public governanceHatRewards;

    event LogClaim(address indexed _claimer, string _descriptionHash);
    event SubmitClaim(
        uint256 indexed _pid,
        uint256 _claimId,
        address _committee,
        address indexed _beneficiary,
        uint256 indexed _bountyPercentage,
        string _descriptionHash
    );
    event ApproveClaim(
        uint256 indexed _pid,
        uint256 indexed _claimId,
        address indexed _committee,
        address _beneficiary,
        uint256 _bountyPercentage,
        address _tokenLock,
        ClaimBounty _claimBounty
    );
    event DismissClaim(uint256 indexed _pid, uint256 indexed _claimId);
    event Deposit(address indexed user,
        uint256 indexed pid,
        uint256 amount,
        uint256 transferredAmount
    );
    event SetFeeSetter(address indexed _newFeeSetter);
    event SetCommittee(uint256 indexed _pid, address indexed _committee);
    event SetChallengePeriod(uint256 _challengePeriod);
    event SetChallengeTimeOutPeriod(uint256 _challengeTimeOutPeriod);
    event SetArbitrator(address indexed _arbitrator);
    event SetWithdrawRequestParams(
        uint256 indexed _withdrawRequestPendingPeriod,
        uint256 indexed _withdrawRequestEnablePeriod
    );
    event SetClaimFee(uint256 _fee);
    event SetWithdrawSafetyPeriod(uint256 indexed _withdrawPeriod, uint256 indexed _safetyPeriod);
    event SetVestingParams(
        uint256 indexed _pid,
        uint256 indexed _duration,
        uint256 indexed _periods
    );
    event SetHatVestingParams(uint256 indexed _duration, uint256 indexed _periods);
    event SetBountySplit(uint256 indexed _pid, BountySplit _bountySplit);
    event SetMaxBountyDelay(uint256 indexed _delay);
    event RouterWhitelistStatusChanged(address indexed _router, bool _status);
    event SetPoolWithdrawalFee(uint256 indexed _pid, uint256 _newFee);
    event CommitteeCheckedIn(uint256 indexed _pid);
    event SetPendingMaxBounty(uint256 indexed _pid, uint256 _maxBounty, uint256 _timeStamp);
    event SetMaxBounty(uint256 indexed _pid, uint256 _maxBounty);
    event SetRewardController(uint256 indexed _pid, IRewardController indexed _newRewardController);
    event AddPool(
        uint256 indexed _pid,
        address indexed _lpToken,
        address _committee,
        IRewardController _rewardController,
        string _descriptionHash,
        uint256 _maxBounty,
        BountySplit _bountySplit,
        uint256 _bountyVestingDuration,
        uint256 _bountyVestingPeriods
    );
    event SetPool(
        uint256 indexed _pid,
        bool indexed _registered,
        bool _depositPause,
        string _descriptionHash
    );
    event SwapAndBurn(
        uint256 indexed _pid,
        uint256 indexed _amountSwapped,
        uint256 indexed _amountBurned
    );
    event SwapAndSend(
        uint256 indexed _pid,
        address indexed _beneficiary,
        uint256 indexed _amountSwapped,
        uint256 _amountReceived,
        address _tokenLock
    );
    event WithdrawRequest(
        uint256 indexed _pid,
        address indexed _beneficiary,
        uint256 indexed _withdrawEnableTime
    );
    event Withdraw(address indexed user, uint256 indexed pid, uint256 shares);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    modifier onlyFeeSetter() {
        if (feeSetter != msg.sender) revert OnlyFeeSetter();
        _;
    }

    modifier onlyCommittee(uint256 _pid) {
        if (committees[_pid] != msg.sender) revert OnlyCommittee();
        _;
    }

    modifier onlyArbitrator() {
        if (arbitrator != msg.sender) revert OnlyArbitrator();
        _;
    }

    modifier noSafetyPeriod() {
        //disable withdraw for safetyPeriod (e.g 1 hour) after each withdrawPeriod(e.g 11 hours)
        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp %
        (generalParameters.withdrawPeriod + generalParameters.safetyPeriod) >=
            generalParameters.withdrawPeriod) revert SafetyPeriod();
        _;
    }

    modifier noActiveClaims(uint256 _pid) {
        if (activeClaims[_pid] != 0) revert ActiveClaimExists();
        _;
    }

    function validateSplit(BountySplit memory _bountySplit) internal pure {
        if (_bountySplit.hacker + _bountySplit.hackerVested == 0) 
            revert BountySplitMustIncludeHackerPayout();

        if (_bountySplit.hackerVested +
            _bountySplit.hacker +
            _bountySplit.committee +
            _bountySplit.swapAndBurn +
            _bountySplit.governanceHat +
            _bountySplit.hackerHatVested != HUNDRED_PERCENT)
            revert TotalSplitPercentageShouldBeHundredPercent();
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "./CloneFactory.sol";
import "./ITokenLock.sol";
import "./ITokenLockFactory.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


/**
 * @title TokenLockFactory
*  a factory of TokenLock contracts.
 *
 * This contract receives funds to make the process of creating TokenLock contracts
 * easier by distributing them the initial tokens to be managed.
 */
contract TokenLockFactory is CloneFactory, ITokenLockFactory, Ownable {
    // -- State --

    address public masterCopy;

    // -- Events --

    event MasterCopyUpdated(address indexed masterCopy);

    event TokenLockCreated(
        address indexed contractAddress,
        bytes32 indexed initHash,
        address indexed beneficiary,
        address token,
        uint256 managedAmount,
        uint256 startTime,
        uint256 endTime,
        uint256 periods,
        uint256 releaseStartTime,
        uint256 vestingCliffTime,
        ITokenLock.Revocability revocable,
        bool canDelegate
    );

    /**
     * Constructor.
     * @param _masterCopy Address of the master copy to use to clone proxies
     */
    // solhint-disable-next-line func-visibility
    constructor(address _masterCopy) {
        setMasterCopy(_masterCopy);
    }

    // -- Factory --
    /**
     * @notice Creates and fund a new token lock wallet using a minimum proxy
     * @param _token token to time lock
     * @param _owner Address of the contract owner
     * @param _beneficiary Address of the beneficiary of locked tokens
     * @param _managedAmount Amount of tokens to be managed by the lock contract
     * @param _startTime Start time of the release schedule
     * @param _endTime End time of the release schedule
     * @param _periods Number of periods between start time and end time
     * @param _releaseStartTime Override time for when the releases start
     * @param _revocable Whether the contract is revocable
     * @param _canDelegate Whether the contract should call delegate
     */
    function createTokenLock(
        address _token,
        address _owner,
        address _beneficiary,
        uint256 _managedAmount,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _periods,
        uint256 _releaseStartTime,
        uint256 _vestingCliffTime,
        ITokenLock.Revocability _revocable,
        bool _canDelegate
    ) external override returns(address contractAddress) {
        // Create contract using a minimal proxy and call initializer
        bytes memory initializer = abi.encodeWithSignature(
            "initialize(address,address,address,uint256,uint256,uint256,uint256,uint256,uint256,uint8,bool)",
            _owner,
            _beneficiary,
            _token,
            _managedAmount,
            _startTime,
            _endTime,
            _periods,
            _releaseStartTime,
            _vestingCliffTime,
            _revocable,
            _canDelegate
        );

        contractAddress = deployProxyPrivate(initializer,
        _beneficiary,
        _token,
        _managedAmount,
        _startTime,
        _endTime,
        _periods,
        _releaseStartTime,
        _vestingCliffTime,
        _revocable,
        _canDelegate);
    }

    /**
     * @notice Sets the masterCopy bytecode to use to create clones of TokenLock contracts
     * @param _masterCopy Address of contract bytecode to factory clone
     */
    function setMasterCopy(address _masterCopy) public override onlyOwner {
        require(_masterCopy != address(0), "MasterCopy cannot be zero");
        masterCopy = _masterCopy;
        emit MasterCopyUpdated(_masterCopy);
    }

    //this private function is to handle stack too deep issue
    function  deployProxyPrivate(
        bytes memory _initializer,
        address _beneficiary,
        address _token,
        uint256 _managedAmount,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _periods,
        uint256 _releaseStartTime,
        uint256 _vestingCliffTime,
        ITokenLock.Revocability _revocable,
        bool _canDelegate
    ) private returns (address contractAddress) {

        contractAddress = createClone(masterCopy);

        Address.functionCall(contractAddress, _initializer);

        emit TokenLockCreated(
            contractAddress,
            keccak256(_initializer),
            _beneficiary,
            _token,
            _managedAmount,
            _startTime,
            _endTime,
            _periods,
            _releaseStartTime,
            _vestingCliffTime,
            _revocable,
            _canDelegate
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;


interface IRewardController {
    function setShares(
        uint256 _pid,
        uint256 _rewardPerShare,
        address[] memory _accounts,
        uint256[] memory _rewardDebts)
    external;

    function updateRewardPool(
        uint256 _pid,
        address _user,
        uint256 _sharesChange,
        bool _isDeposit,
        bool _claimReward
    ) external;

    function setAllocPoint(uint256 _pid, uint256 _allocPoint) external;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

/*
The MIT License (MIT)
Copyright (c) 2018 Murray Software, LLC.
Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:
The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
// solhint-disable max-line-length
// solhint-disable no-inline-assembly

contract CloneFactory {

    function createClone(address target) internal returns (address result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            result := create(0, clone, 0x37)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITokenLock {
    enum Revocability { NotSet, Enabled, Disabled }

    // -- Balances --

    function currentBalance() external view returns (uint256);

    // -- Time & Periods --

    function currentTime() external view returns (uint256);

    function duration() external view returns (uint256);

    function sinceStartTime() external view returns (uint256);

    function amountPerPeriod() external view returns (uint256);

    function periodDuration() external view returns (uint256);

    function currentPeriod() external view returns (uint256);

    function passedPeriods() external view returns (uint256);

    // -- Locking & Release Schedule --

    function availableAmount() external view returns (uint256);

    function vestedAmount() external view returns (uint256);

    function releasableAmount() external view returns (uint256);

    function totalOutstandingAmount() external view returns (uint256);

    function surplusAmount() external view returns (uint256);

    // -- Value Transfer --

    function release() external;

    function withdrawSurplus(uint256 _amount) external;

    function revoke() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./ITokenLock.sol";

interface ITokenLockFactory {
    // -- Factory --
    function setMasterCopy(address _masterCopy) external;

    function createTokenLock(
        address _token,
        address _owner,
        address _beneficiary,
        uint256 _managedAmount,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _periods,
        uint256 _releaseStartTime,
        uint256 _vestingCliffTime,
        ITokenLock.Revocability _revocable,
        bool _canDelegate
    ) external returns(address contractAddress);
}