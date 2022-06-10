// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.14;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/IValidatorShare.sol";
import "./interfaces/IValidatorRegistry.sol";
import "./interfaces/IStakeManager.sol";
import "./interfaces/IJMS.sol";

contract JMS is IJMS, ERC20, Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address private validatorRegistry;
    address private stakeManager;
    IERC20 private polygonERC20;

    address public override treasury;
    uint8 public override feePercent;

    struct Compound {
        bool isActive;
        uint256 minReward;
        uint256 minRestake;
    }

    Compound public compoundConfig;

    /// @notice Mapping of all user ids with withdraw requests.
    mapping(address => WithdrawalRequest[]) private userWithdrawalRequests;

    /**
     * @param _validatorRegistry - Address of the validator registry
     * @param _stakeManager - Address of the stake manager
     * @param _polygonERC20 - Address of matic token on Ethereum
     * @param _treasury - Address of the treasury
     */

    constructor(
        address _validatorRegistry,
        address _stakeManager,
        address _polygonERC20,
        address _treasury
    ) ERC20("Jamon Matic Stake", "JSM") {
        validatorRegistry = _validatorRegistry;
        stakeManager = _stakeManager;
        treasury = _treasury;
        polygonERC20 = IERC20(_polygonERC20);
        compoundConfig.isActive = true;
        compoundConfig.minReward = 2 ether;
        compoundConfig.minRestake = 1 ether;

        feePercent = 10;
        polygonERC20.safeApprove(stakeManager, type(uint256).max);
    }

    ////////////////////////////////////////////////////////////
    /////                                                    ///
    /////             ***Staking Contract Interactions***    ///
    /////                                                    ///
    ////////////////////////////////////////////////////////////

    /**
     * @dev Send funds to JMS contract and mints JMS to msg.sender
     * @notice Requires that msg.sender has approved _amount of MATIC to this contract
     * @param _amount - Amount of MATIC sent from msg.sender to this contract
     * @return minted Amount of JMS shares generated
     */
    function submit(uint256 _amount)
        external
        override
        whenNotPaused
        nonReentrant
        returns (uint256 minted)
    {
        require(_amount > 0, "Invalid amount");
        polygonERC20.safeTransferFrom(msg.sender, address(this), _amount);
        minted = helper_delegate_to_mint(msg.sender, _amount);
        if (compoundConfig.isActive) {
            _doCompound();
        }
    }

    /**
     * @dev Stores user's request to withdraw into WithdrawalRequest struct
     * @param _amount - Amount of JMS that is requested to withdraw
     */
    function requestWithdraw(uint256 _amount)
        external
        override
        whenNotPaused
        nonReentrant
    {
        require(_amount > 0, "Invalid amount");

        (uint256 totalAmount2WithdrawInMatic, , ) = convertJMSToMatic(_amount);

        _burn(msg.sender, _amount);

        uint256 leftAmount2WithdrawInMatic = totalAmount2WithdrawInMatic;
        uint256 totalDelegated = getTotalStakeAcrossAllValidators();

        require(
            totalDelegated >= totalAmount2WithdrawInMatic,
            "Too much to withdraw"
        );

        uint256[] memory validators = IValidatorRegistry(validatorRegistry)
            .getValidators();
        uint256 preferredValidatorId = IValidatorRegistry(validatorRegistry)
            .preferredWithdrawalValidatorId();
        uint256 currentIdx = 0;
        for (; currentIdx < validators.length; ++currentIdx) {
            if (preferredValidatorId == validators[currentIdx]) break;
        }

        while (leftAmount2WithdrawInMatic > 0) {
            uint256 validatorId = validators[currentIdx];

            address validatorShare = IStakeManager(stakeManager)
                .getValidatorContract(validatorId);
            (uint256 validatorBalance, ) = getTotalStake(
                IValidatorShare(validatorShare)
            );

            uint256 amount2WithdrawFromValidator = (validatorBalance <=
                leftAmount2WithdrawInMatic)
                ? validatorBalance
                : leftAmount2WithdrawInMatic;

            IValidatorShare(validatorShare).sellVoucher_new(
                amount2WithdrawFromValidator,
                type(uint256).max
            );

            userWithdrawalRequests[msg.sender].push(
                WithdrawalRequest(
                    IValidatorShare(validatorShare).unbondNonces(address(this)),
                    IStakeManager(stakeManager).epoch() +
                        IStakeManager(stakeManager).withdrawalDelay(),
                    validatorShare
                )
            );

            leftAmount2WithdrawInMatic -= amount2WithdrawFromValidator;
            currentIdx = currentIdx + 1 < validators.length
                ? currentIdx + 1
                : 0;
        }
        if (compoundConfig.isActive) {
            _doCompound();
        }
        emit RequestWithdraw(msg.sender, _amount, totalAmount2WithdrawInMatic);
    }

    /**
     * @dev Claims tokens from validator share and sends them to the
     * address if the request is in the userWithdrawalRequests
     * @param _idx - User withdrawal request array index
     */
    function claimWithdrawal(uint256 _idx)
        external
        override
        whenNotPaused
        nonReentrant
    {
        _claimWithdrawal(msg.sender, _idx);
        if (compoundConfig.isActive) {
            _doCompound();
        }
    }

    function doCompound() external whenNotPaused nonReentrant {
        _doCompound();
    }

    function withdrawRewards(uint256 _validatorId)
        public
        override
        whenNotPaused
        returns (uint256)
    {
        address validatorShare = IStakeManager(stakeManager)
            .getValidatorContract(_validatorId);

        uint256 balanceBeforeRewards = polygonERC20.balanceOf(address(this));
        IValidatorShare(validatorShare).withdrawRewards();
        uint256 rewards = polygonERC20.balanceOf(address(this)) -
            balanceBeforeRewards;

        emit WithdrawRewards(_validatorId, rewards);
        return rewards;
    }

    function stakeRewardsAndDistributeFees(uint256 _validatorId)
        external
        override
        whenNotPaused
        onlyOwner
    {
        require(
            IValidatorRegistry(validatorRegistry).validatorIdExists(
                _validatorId
            ),
            "Doesn't exist in validator registry"
        );

        address validatorShare = IStakeManager(stakeManager)
            .getValidatorContract(_validatorId);

        uint256 rewards = polygonERC20.balanceOf(address(this));

        require(rewards > 0, "Reward is zero");

        uint256 treasuryFees = (rewards * feePercent) / 100;

        if (treasuryFees > 0) {
            polygonERC20.safeTransfer(treasury, treasuryFees);
            emit DistributeFees(treasury, treasuryFees);
        }

        uint256 amountStaked = rewards - treasuryFees;
        IValidatorShare(validatorShare).buyVoucher(amountStaked, 0);

        emit StakeRewards(_validatorId, amountStaked);
    }

    /**
     * @dev Migrate the staked tokens to another validaor
     */
    function migrateDelegation(
        uint256 _fromValidatorId,
        uint256 _toValidatorId,
        uint256 _amount
    ) external override whenNotPaused onlyOwner {
        require(
            IValidatorRegistry(validatorRegistry).validatorIdExists(
                _fromValidatorId
            ),
            "From validator id does not exist in our registry"
        );
        require(
            IValidatorRegistry(validatorRegistry).validatorIdExists(
                _toValidatorId
            ),
            "To validator id does not exist in our registry"
        );

        IStakeManager(stakeManager).migrateDelegation(
            _fromValidatorId,
            _toValidatorId,
            _amount
        );

        emit MigrateDelegation(_fromValidatorId, _toValidatorId, _amount);
    }

    /**
     * @dev Flips the pause state
     */
    function togglePause() external override onlyOwner {
        paused() ? _unpause() : _pause();
    }

    ////////////////////////////////////////////////////////////
    /////                                                    ///
    /////            ***Helpers & Utilities***               ///
    /////                                                    ///
    ////////////////////////////////////////////////////////////

    function helper_delegate_to_mint(address deposit_sender, uint256 _amount)
        internal
        returns (uint256)
    {
        (uint256 amountToMint, , ) = convertMaticToJMS(_amount);

        _mint(deposit_sender, amountToMint);
        emit Submit(deposit_sender, _amount);

        uint256 preferredValidatorId = IValidatorRegistry(validatorRegistry)
            .preferredDepositValidatorId();
        address validatorShare = IStakeManager(stakeManager)
            .getValidatorContract(preferredValidatorId);
        IValidatorShare(validatorShare).buyVoucher(_amount, 0);

        emit Delegate(preferredValidatorId, _amount);
        return amountToMint;
    }

    function _doCompound() internal {
        uint256 preferredValidatorId = IValidatorRegistry(validatorRegistry)
            .preferredDepositValidatorId();
        address validatorShare = IStakeManager(stakeManager)
            .getValidatorContract(preferredValidatorId);
        uint256 pending = IValidatorShare(validatorShare).getLiquidRewards(
            address(this)
        );
        if (pending > compoundConfig.minReward) {
            IValidatorShare(validatorShare).withdrawRewards();
        }
        uint256 rewards = polygonERC20.balanceOf(address(this));
        if (rewards > compoundConfig.minRestake) {
            uint256 treasuryFees = (rewards * feePercent) / 100;
            if (treasuryFees > 0) {
                polygonERC20.safeTransfer(treasury, treasuryFees);
                emit DistributeFees(treasury, treasuryFees);
            }

            uint256 amountStaked = rewards - treasuryFees;
            IValidatorShare(validatorShare).buyVoucher(amountStaked, 0);
            emit StakeRewards(preferredValidatorId, amountStaked);
        }
    }

    /**
     * @dev Claims tokens from validator share and sends them to the
     * address if the request is in the userWithdrawalRequests
     * @param _to - Address of the withdrawal request owner
     * @param _idx - User withdrawal request array index
     */
    function _claimWithdrawal(address _to, uint256 _idx)
        internal
        returns (uint256)
    {
        uint256 amountToClaim = 0;
        uint256 balanceBeforeClaim = polygonERC20.balanceOf(address(this));
        WithdrawalRequest[] storage userRequests = userWithdrawalRequests[_to];
        WithdrawalRequest memory userRequest = userRequests[_idx];
        require(
            IStakeManager(stakeManager).epoch() >= userRequest.requestEpoch,
            "Not able to claim yet"
        );

        IValidatorShare(userRequest.validatorAddress).unstakeClaimTokens_new(
            userRequest.validatorNonce
        );

        // swap with the last item and pop it.
        userRequests[_idx] = userRequests[userRequests.length - 1];
        userRequests.pop();

        amountToClaim =
            polygonERC20.balanceOf(address(this)) -
            balanceBeforeClaim;

        polygonERC20.safeTransfer(_to, amountToClaim);

        emit ClaimWithdrawal(_to, _idx, amountToClaim);
        return amountToClaim;
    }

    /**
     * @dev Function that converts arbitrary JMS to Matic
     * @param _balance - Balance in JMS
     * @return Balance in Matic, totalShares and totalPooledMATIC
     */
    function convertJMSToMatic(uint256 _balance)
        public
        view
        override
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 totalShares = totalSupply();
        totalShares = totalShares == 0 ? 1 : totalShares;

        uint256 totalPooledMATIC = getTotalPooledMatic();
        totalPooledMATIC = totalPooledMATIC == 0 ? 1 : totalPooledMATIC;

        uint256 balanceInMATIC = (_balance * (totalPooledMATIC)) / totalShares;

        return (balanceInMATIC, totalShares, totalPooledMATIC);
    }

    /**
     * @dev Function that converts arbitrary Matic to JMS
     * @param _balance - Balance in Matic
     * @return Balance in JMS, totalShares and totalPooledMATIC
     */
    function convertMaticToJMS(uint256 _balance)
        public
        view
        override
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 totalShares = totalSupply();
        totalShares = totalShares == 0 ? 1 : totalShares;

        uint256 totalPooledMatic = getTotalPooledMatic();
        totalPooledMatic = totalPooledMatic == 0 ? 1 : totalPooledMatic;

        uint256 balanceInJMS = (_balance * totalShares) / totalPooledMatic;

        return (balanceInJMS, totalShares, totalPooledMatic);
    }

    ////////////////////////////////////////////////////////////
    /////                                                    ///
    /////                 ***Setters***                      ///
    /////                                                    ///
    ////////////////////////////////////////////////////////////

    /**
     * @dev Function that sets fee percent
     * @notice Callable only by manager
     * @param _feePercent - Fee percent (10 = 10%)
     */
    function setFeePercent(uint8 _feePercent) external override onlyOwner {
        require(_feePercent <= 100, "_feePercent must not exceed 100");

        feePercent = _feePercent;

        emit SetFeePercent(_feePercent);
    }

    function setTreasury(address _address) external override onlyOwner {
        treasury = _address;

        emit SetTreasury(_address);
    }

    function setCompound(
        bool _set,
        uint256 _minReward,
        uint256 _minRestake
    ) external onlyOwner {
        require(_minReward >= 1 ether  && _minRestake >= 1 gwei, "invalid mins");
        compoundConfig.isActive = _set;
        compoundConfig.minReward = _minReward;
        compoundConfig.minRestake = _minRestake;
    }

    function setValidatorRegistry(address _address)
        external
        override
        onlyOwner
    {
        validatorRegistry = _address;

        emit SetValidatorRegistry(_address);
    }

    ////////////////////////////////////////////////////////////
    /////                                                    ///
    /////                 ***Getters***                      ///
    /////                                                    ///
    ////////////////////////////////////////////////////////////
    /**
     * @dev API for getting total stake of this contract from validatorShare
     * @param _validatorShare - Address of validatorShare contract
     * @return Total stake of this contract and MATIC -> share exchange rate
     */
    function getTotalStake(IValidatorShare _validatorShare)
        public
        view
        override
        returns (uint256, uint256)
    {
        return _validatorShare.getTotalStake(address(this));
    }

    /**
     * @dev Helper function for that returns current epoch on stake manager
     * @return Current epoch
     */
    function currentEpoch() external view returns (uint256) {
        return IStakeManager(stakeManager).epoch();
    }

    /**
     * @dev Helper function for that returns total pooled MATIC
     * @return Total pooled MATIC
     */
    function getTotalStakeAcrossAllValidators()
        public
        view
        override
        returns (uint256)
    {
        uint256 totalStake;
        uint256[] memory validators = IValidatorRegistry(validatorRegistry)
            .getValidators();
        for (uint256 i = 0; i < validators.length; ++i) {
            address validatorShare = IStakeManager(stakeManager)
                .getValidatorContract(validators[i]);
            (uint256 currValidatorShare, ) = getTotalStake(
                IValidatorShare(validatorShare)
            );

            totalStake += currValidatorShare;
        }

        return totalStake;
    }

    /**
     * @dev Function that calculates total pooled Matic
     * @return Total pooled Matic
     */
    function getTotalPooledMatic() public view override returns (uint256) {
        uint256 totalStaked = getTotalStakeAcrossAllValidators();
        return totalStaked;
    }

    /**
     * @dev Retrieves all withdrawal requests initiated by the given address
     * @param _address - Address of an user
     * @return userWithdrawalRequests array of user withdrawal requests
     */
    function getUserWithdrawalRequests(address _address)
        external
        view
        override
        returns (WithdrawalRequest[] memory)
    {
        return userWithdrawalRequests[_address];
    }

    /**
     * @dev Retrieves shares amount of a given withdrawal request
     * @param _address - Address of an user
     * @return _idx index of the withdrawal request
     */
    function getSharesAmountOfUserWithdrawalRequest(
        address _address,
        uint256 _idx
    ) external view override returns (uint256) {
        WithdrawalRequest memory userRequest = userWithdrawalRequests[_address][
            _idx
        ];
        IValidatorShare validatorShare = IValidatorShare(
            userRequest.validatorAddress
        );
        IValidatorShare.DelegatorUnbond memory unbond = validatorShare
            .unbonds_new(address(this), userRequest.validatorNonce);

        return unbond.shares;
    }

    function getPendingRewards() external view returns (uint256) {
        uint256 preferredValidatorId = IValidatorRegistry(validatorRegistry)
            .preferredDepositValidatorId();
        address validatorShare = IStakeManager(stakeManager)
            .getValidatorContract(preferredValidatorId);
        return IValidatorShare(validatorShare).getLiquidRewards(address(this));
    }

    function getPendingRewardsAtValidator(uint256 _validatorId)
        external
        view
        returns (uint256)
    {
        address validatorShare = IStakeManager(stakeManager)
            .getValidatorContract(_validatorId);
        return IValidatorShare(validatorShare).getLiquidRewards(address(this));
    }

    function getContracts()
        external
        view
        override
        returns (
            address _stakeManager,
            address _polygonERC20,
            address _validatorRegistry
        )
    {
        _stakeManager = stakeManager;
        _polygonERC20 = address(polygonERC20);
        _validatorRegistry = validatorRegistry;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IValidatorShare.sol";
import "./IValidatorRegistry.sol";

/// @title JMS interface.
interface IJMS is IERC20 {
	struct WithdrawalRequest {
		uint256 validatorNonce;
		uint256 requestEpoch;
		address validatorAddress;
	}

	function treasury() external view returns (address);

	function feePercent() external view returns (uint8);

	function submit(uint256 _amount) external returns (uint256);

	function requestWithdraw(uint256 _amount) external;

	function claimWithdrawal(uint256 _idx) external;

	function withdrawRewards(uint256 _validatorId) external returns (uint256);

	function stakeRewardsAndDistributeFees(uint256 _validatorId) external;

	function migrateDelegation(
		uint256 _fromValidatorId,
		uint256 _toValidatorId,
		uint256 _amount
	) external;

	function togglePause() external;

	function convertJMSToMatic(uint256 _balance)
		external
		view
		returns (
			uint256,
			uint256,
			uint256
		);

	function convertMaticToJMS(uint256 _balance)
		external
		view
		returns (
			uint256,
			uint256,
			uint256
		);

	function setFeePercent(uint8 _feePercent) external;

	function setValidatorRegistry(address _address) external;

	function setTreasury(address _address) external;

	function getUserWithdrawalRequests(address _address)
		external
		view
		returns (WithdrawalRequest[] memory);

	function getSharesAmountOfUserWithdrawalRequest(
		address _address,
		uint256 _idx
	) external view returns (uint256);

	function getTotalStake(IValidatorShare _validatorShare)
		external
		view
		returns (uint256, uint256);

	function getTotalStakeAcrossAllValidators() external view returns (uint256);

	function getTotalPooledMatic() external view returns (uint256);

	function getContracts()
		external
		view
		returns (
			address _stakeManager,
			address _polygonERC20,
			address _validatorRegistry
		);

	event Submit(address indexed _from, uint256 _amount);
	event Delegate(uint256 indexed _validatorId, uint256 _amountDelegated);
	event RequestWithdraw(
		address indexed _from,
		uint256 _amountJMS,
		uint256 _amountMatic
	);
	event ClaimWithdrawal(
		address indexed _from,
		uint256 indexed _idx,
		uint256 _amountClaimed
	);
	event WithdrawRewards(uint256 indexed _validatorId, uint256 _rewards);
	event StakeRewards(uint256 indexed _validatorId, uint256 _amountStaked);
	event DistributeFees(address indexed _address, uint256 _amount);
	event MigrateDelegation(
		uint256 indexed _fromValidatorId,
		uint256 indexed _toValidatorId,
		uint256 _amount
	);
	event SetFeePercent(uint8 _feePercent);
	event SetTreasury(address _address);
	event SetValidatorRegistry(address _address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/// @title polygon stake manager interface.
/// @notice User to interact with the polygon stake manager.
interface IStakeManager {
	/// @notice Request unstake a validator.
	/// @param validatorId validator id.
	function unstake(uint256 validatorId) external;

	/// @notice Get the validator id using the user address.
	/// @param user user that own the validator in our case the validator contract.
	/// @return return the validator id
	function getValidatorId(address user) external view returns (uint256);

	/// @notice get the validator contract used for delegation.
	/// @param validatorId validator id.
	/// @return return the address of the validator contract.
	function getValidatorContract(uint256 validatorId)
		external
		view
		returns (address);

	/// @notice Withdraw accumulated rewards
	/// @param validatorId validator id.
	function withdrawRewards(uint256 validatorId) external;

	/// @notice Get validator total staked.
	/// @param validatorId validator id.
	function validatorStake(uint256 validatorId)
		external
		view
		returns (uint256);

	/// @notice Allows to unstake the staked tokens on the stakeManager.
	/// @param validatorId validator id.
	function unstakeClaim(uint256 validatorId) external;

	/// @notice Allows to migrate the staked tokens to another validator.
	/// @param fromValidatorId From validator id.
	/// @param toValidatorId To validator id.
	/// @param amount amount in Matic.
	function migrateDelegation(
		uint256 fromValidatorId,
		uint256 toValidatorId,
		uint256 amount
	) external;

	/// @notice Returns a withdrawal delay.
	function withdrawalDelay() external view returns (uint256);

	/// @notice Transfers amount from delegator
	function delegationDeposit(
		uint256 validatorId,
		uint256 amount,
		address delegator
	) external returns (bool);

	function epoch() external view returns (uint256);

	enum Status {
		Inactive,
		Active,
		Locked,
		Unstaked
	}

	struct Validator {
		uint256 amount;
		uint256 reward;
		uint256 activationEpoch;
		uint256 deactivationEpoch;
		uint256 jailTime;
		address signer;
		address contractAddress;
		Status status;
		uint256 commissionRate;
		uint256 lastCommissionUpdate;
		uint256 delegatorsReward;
		uint256 delegatedAmount;
		uint256 initialRewardPerStake;
	}

	function validators(uint256 _index)
		external
		view
		returns (Validator memory);

	// TODO: Remove it and use stakeFor instead
	function createValidator(uint256 _validatorId) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/// @title IValidatorRegistry
/// @notice Node validator registry interface
interface IValidatorRegistry {
    function addValidator(uint256 _validatorId) external;

    function removeValidator(uint256 _validatorId) external;

    function setPreferredDepositValidatorId(uint256 _validatorId) external;

    function setPreferredWithdrawalValidatorId(uint256 _validatorId) external;

    function togglePause() external;

    function preferredDepositValidatorId() external view returns (uint256);

    function preferredWithdrawalValidatorId() external view returns (uint256);

    function validatorIdExists(uint256 _validatorId)
        external
        view
        returns (bool);

    function getStakeManager() external view returns (address _stakeManager);

    function getValidatorId(uint256 _index) external view returns (uint256);

    function getValidators() external view returns (uint256[] memory);

    event AddValidator(uint256 indexed _validatorId);
    event RemoveValidator(uint256 indexed _validatorId);
    event SetPreferredDepositValidatorId(uint256 indexed _validatorId);
    event SetPreferredWithdrawalValidatorId(uint256 indexed _validatorId);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IValidatorShare {
    struct DelegatorUnbond {
        uint256 shares;
        uint256 withdrawEpoch;
    }

    function minAmount() external view returns (uint256);

    function unbondNonces(address _address) external view returns (uint256);

    function validatorId() external view returns (uint256);

    function delegation() external view returns (bool);

    function buyVoucher(uint256 _amount, uint256 _minSharesToMint)
        external
        returns (uint256);

    function sellVoucher_new(uint256 claimAmount, uint256 maximumSharesToBurn)
        external;

    function unstakeClaimTokens_new(uint256 unbondNonce) external;

    function restake() external returns (uint256, uint256);

    function withdrawRewards() external;

    function getTotalStake(address user)
        external
        view
        returns (uint256, uint256);

    function getLiquidRewards(address user) external view returns (uint256);

    function unbonds_new(address _address, uint256 _unbondNonce)
        external
        view
        returns (DelegatorUnbond memory);
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

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
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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