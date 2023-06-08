// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../../delegation/DelegationManager.sol";
import "../ITssGroupManager.sol";
import "../TssStakingSlashing.sol";


/**
 * @title The primary entry- and exit-point for funds into and out.
 * @notice This contract is for managing investments in different strategies. The main
 * functionalities are:
 * - adding and removing investment strategies that any delegator can invest into
 * - enabling deposit of assets into specified investment delegation(s)
 * - enabling removal of assets from specified investment delegation(s)
 * - recording deposit of ETH into settlement layer
 * - recording deposit for securing
 * - slashing of assets for permissioned strategies
 */
contract TssDelegationManager is DelegationManager {


    address public stakingSlash;
    address public tssGroupManager;

    uint256 public minStakeAmount;


    /**
     * @param _delegation The delegation contract.
     * @param _delegationSlasher The primary slashing contract.
     */
    constructor(IDelegation _delegation, IDelegationSlasher _delegationSlasher)
    DelegationManager(_delegation, _delegationSlasher)
    {
        _disableInitializers();
    }

    function initializeT(
        address _stakingSlashing,
        address _tssGroupManager,
        uint256 _minStakeAmount,
        address initialOwner
    ) public initializer {
        DOMAIN_SEPARATOR = keccak256(abi.encode(DOMAIN_TYPEHASH, bytes("Mantle"), block.chainid, address(this)));
        _transferOwnership(initialOwner);
        stakingSlash = _stakingSlashing;
        tssGroupManager = _tssGroupManager;
        minStakeAmount = _minStakeAmount;
    }


    modifier onlyStakingSlash() {
        require(msg.sender == stakingSlash, "contract call is not staking slashing");
        _;
    }

    function setStakingSlash(address _address) public onlyOwner {
        stakingSlash = _address;
    }

    function setMinStakeAmount(uint256 _amount) public onlyOwner {
        minStakeAmount = _amount;
    }

    function setTssGroupManager(address _addr) public onlyOwner {
        tssGroupManager = _addr;
    }

    /**
     * @notice Slashes the shares of a 'frozen' operator (or a staker delegated to one)
     * @param slashedAddress is the frozen address that is having its shares slashed
     * @param delegationIndexes is a list of the indices in `investorStrats[msg.sender]` that correspond to the strategies
     * for which `msg.sender` is withdrawing 100% of their shares
     * @param recipient The slashed funds are withdrawn as tokens to this address.
     * @dev delegationShares are removed from `investorStrats` by swapping the last entry with the entry to be removed, then
     * popping off the last entry in `investorStrats`. The simplest way to calculate the correct `delegationIndexes` to input
     * is to order the strategies *for which `msg.sender` is withdrawing 100% of their shares* from highest index in
     * `investorStrats` to lowest index
     */
    function slashShares(
        address slashedAddress,
        address recipient,
        IDelegationShare[] calldata delegationShares,
        IERC20[] calldata tokens,
        uint256[] calldata delegationIndexes,
        uint256[] calldata shareAmounts
    )
        external
        override
        whenNotPaused
        onlyStakingSlash
        nonReentrant
    {

        uint256 delegationIndex;
        uint256 strategiesLength = delegationShares.length;
        for (uint256 i = 0; i < strategiesLength;) {
            // the internal function will return 'true' in the event the delegation contract was
            // removed from the slashedAddress's array of strategies -- i.e. investorStrats[slashedAddress]
            if (_removeShares(slashedAddress, delegationIndexes[delegationIndex], delegationShares[i], shareAmounts[i])) {
                unchecked {
                    ++delegationIndex;
                }
            }

            // withdraw the shares and send funds to the recipient
            delegationShares[i].withdraw(recipient, tokens[i], shareAmounts[i]);

            // increment the loop
            unchecked {
                ++i;
            }
        }

        // modify delegated shares accordingly, if applicable
        delegation.decreaseDelegatedShares(slashedAddress, delegationShares, shareAmounts);
    }

    function queueWithdrawal(
        uint256[] calldata delegationIndexes,
        IDelegationShare[] calldata delegationShares,
        IERC20[] calldata tokens,
        uint256[] calldata shares,
        WithdrawerAndNonce calldata withdrawerAndNonce,
        bool undelegateIfPossible
    )
    external
    virtual
    override
    whenNotPaused
    onlyNotFrozen(msg.sender)
    nonReentrant
    returns (bytes32)
    {
        revert("TssDelegationManager: queueWithdrawal is disabled ");
    }


    function isCanOperator(address _addr, IDelegationShare delegationShare) external returns (bool)  {
        if (delegation.isOperator(_addr)) {
            uint256 share = delegation.operatorShares(_addr, delegationShare);
            uint256 balance = delegationShare.sharesToUnderlying(share);
            if (balance > minStakeAmount) {
                return true;
            }
        }
        return false;
    }

    function depositInto(IDelegationShare delegationShare, IERC20 token, uint256 amount, address sender)
    external
    onlyNotFrozen(sender)
    nonReentrant
    whitelistOnly(address(delegationShare))
    onlyStakingSlash
    returns (uint256 shares)
    {
        shares = _depositInto(sender, delegationShare, token, amount);
    }

    function queueWithdrawal(
        address sender,
        uint256[] calldata delegationIndexes,
        IDelegationShare[] calldata delegationShares,
        IERC20[] calldata tokens,
        uint256[] calldata shares,
        WithdrawerAndNonce calldata withdrawerAndNonce
    )
    external
    whenNotPaused
    onlyNotFrozen(sender)
    onlyStakingSlash
    nonReentrant
    returns (bytes32)
    {
        require(
            withdrawerAndNonce.nonce == numWithdrawalsQueued[sender],
            "InvestmentManager.queueWithdrawal: provided nonce incorrect"
        );
        require(delegationShares.length == 1, "only tss delegation share");
        require(shares.length == 1,"only tss delegation share");
        // increment the numWithdrawalsQueued of the sender
        unchecked {
            ++numWithdrawalsQueued[sender];
        }
        address operator = delegation.delegatedTo(sender);

        _checkMinStakeAmount(sender, delegationShares[0], shares[0]);

        // modify delegated shares accordingly, if applicable
        delegation.decreaseDelegatedShares(sender, delegationShares, shares);

        // the internal function will return 'true' in the event the delegation contrat was
        // removed from the depositor's array of strategies -- i.e. investorStrats[depositor]
        _removeShares(sender, delegationIndexes[0], delegationShares[0], shares[0]);

        // copy arguments into struct and pull delegation info
        QueuedWithdrawal memory queuedWithdrawal = QueuedWithdrawal({
            delegations: delegationShares,
            tokens: tokens,
            shares: shares,
            depositor: sender,
            withdrawerAndNonce: withdrawerAndNonce,
            delegatedAddress: operator
        });

        // calculate the withdrawal root
        bytes32 withdrawalRoot = calculateWithdrawalRoot(queuedWithdrawal);

        //update storage in mapping of queued withdrawals
        queuedWithdrawals[withdrawalRoot] = WithdrawalStorage({
            /**
             * @dev We add `REASONABLE_STAKES_UPDATE_PERIOD` to the current time here to account for the fact that it may take some time for
             * the operator's stake to be updated on all the middlewares. New tasks created between now at this 'initTimestamp' may still
             * subject the `msg.sender` to slashing!
             */
            initTimestamp: uint32(block.timestamp + REASONABLE_STAKES_UPDATE_PERIOD),
            withdrawer: withdrawerAndNonce.withdrawer,
            unlockTimestamp: QUEUED_WITHDRAWAL_INITIALIZED_VALUE
        });

        address staker = sender;
        // If the `msg.sender` has withdrawn all of their funds in this transaction, then they can choose to also undelegate
        /**
         * Checking that `investorStrats[msg.sender].length == 0` is not strictly necessary here, but prevents reverting very late in logic,
         * in the case that 'undelegate' is set to true but the `msg.sender` still has active deposits.
         */
        if (investorDelegations[staker].length == 0) {
            _undelegate(staker);
        }

        emit WithdrawalQueued(staker, withdrawerAndNonce.withdrawer, operator, withdrawalRoot);

        return withdrawalRoot;
    }


    function startQueuedWithdrawalWaitingPeriod(bytes32 withdrawalRoot, address sender, uint32 stakeInactiveAfter) external onlyStakingSlash {
        require(
            queuedWithdrawals[withdrawalRoot].unlockTimestamp == QUEUED_WITHDRAWAL_INITIALIZED_VALUE,
            "InvestmentManager.startQueuedWithdrawalWaitingPeriod: Withdrawal stake inactive claim has already been made"
        );
        require(
            queuedWithdrawals[withdrawalRoot].withdrawer == sender,
            "InvestmentManager.startQueuedWithdrawalWaitingPeriod: Sender is not the withdrawer"
        );
        require(
            block.timestamp > queuedWithdrawals[withdrawalRoot].initTimestamp,
            "InvestmentManager.startQueuedWithdrawalWaitingPeriod: Stake may still be subject to slashing based on new tasks. Wait to set stakeInactiveAfter."
        );
        //they can only unlock after a withdrawal waiting period or after they are claiming their stake is inactive
        queuedWithdrawals[withdrawalRoot].unlockTimestamp = max((uint32(block.timestamp) + WITHDRAWAL_WAITING_PERIOD), stakeInactiveAfter);
    }

    function completeQueuedWithdrawal(address sender, QueuedWithdrawal calldata queuedWithdrawal, bool receiveAsTokens)
        external
        whenNotPaused
        // check that the address that the staker *was delegated to* – at the time that they queued the withdrawal – is not frozen
        onlyNotFrozen(queuedWithdrawal.delegatedAddress)
        nonReentrant
        onlyStakingSlash
    {
        // find the withdrawalRoot
        bytes32 withdrawalRoot = calculateWithdrawalRoot(queuedWithdrawal);
        // copy storage to memory
        WithdrawalStorage memory withdrawalStorageCopy = queuedWithdrawals[withdrawalRoot];

        // verify that the queued withdrawal actually exists
        require(
            withdrawalStorageCopy.unlockTimestamp != 0,
            "InvestmentManager.completeQueuedWithdrawal: withdrawal does not exist"
        );

        require(
            uint32(block.timestamp) >= withdrawalStorageCopy.unlockTimestamp
                || (queuedWithdrawal.delegatedAddress == address(0)),
            "InvestmentManager.completeQueuedWithdrawal: withdrawal waiting period has not yet passed and depositor was delegated when withdrawal initiated"
        );

        // TODO: add testing coverage for this
        require(
            sender == queuedWithdrawal.withdrawerAndNonce.withdrawer,
            "InvestmentManager.completeQueuedWithdrawal: only specified withdrawer can complete a queued withdrawal"
        );

        // reset the storage slot in mapping of queued withdrawals
        delete queuedWithdrawals[withdrawalRoot];

        // store length for gas savings
        uint256 strategiesLength = queuedWithdrawal.delegations.length;
        // if the withdrawer has flagged to receive the funds as tokens, withdraw from strategies
        if (receiveAsTokens) {
            // actually withdraw the funds
            for (uint256 i = 0; i < strategiesLength;) {
                // tell the delegation to send the appropriate amount of funds to the depositor
                queuedWithdrawal.delegations[i].withdraw(
                    withdrawalStorageCopy.withdrawer, queuedWithdrawal.tokens[i], queuedWithdrawal.shares[i]
                );
                unchecked {
                    ++i;
                }
            }
        } else {
            // else increase their shares
            for (uint256 i = 0; i < strategiesLength;) {
                _addShares(withdrawalStorageCopy.withdrawer, queuedWithdrawal.delegations[i], queuedWithdrawal.shares[i]);
                unchecked {
                    ++i;
                }
            }
        }

        emit WithdrawalCompleted(queuedWithdrawal.depositor, withdrawalStorageCopy.withdrawer, withdrawalRoot);
    }

    function getWithdrawNonce(address staker) external view onlyStakingSlash returns (uint256) {
        return numWithdrawalsQueued[staker];
    }

    function getDelegationShares(address staker,IDelegationShare delegationShare) external view onlyStakingSlash returns (uint256) {
        return investorDelegationShares[staker][delegationShare];
    }

    function _checkMinStakeAmount(address sender,IDelegationShare delegationShare, uint256 shares) internal {
        address operator = delegation.delegatedTo(sender);
        // check if the operator is still mpc node, if the remaining shares meet the mini requirement
        if (delegation.isDelegated(sender)){
            if (ITssGroupManager(tssGroupManager).memberExistActive(operator)){
                require(!TssStakingSlashing(stakingSlash).isJailed(operator),"the operator is not in jail status");
                uint256 rest= delegation.operatorShares(operator, delegationShare) - shares;
                uint256 balance = delegationShare.sharesToUnderlying(rest);
                if (ITssGroupManager(tssGroupManager).isTssGroupUnJailMembers(operator)) {
                    require(balance > minStakeAmount,"unable withdraw due to operator's rest shares smaller than mini requirement");
                }
            }
        }
    }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "./interfaces/IDelegation.sol";
import "./DelegationManagerStorage.sol";
import "./WhiteListBase.sol";
/**
 * @title The primary entry- and exit-point for funds into and out.
 * @author Layr Labs, Inc.
 * @notice This contract is for managing investments in different strategies. The main
 * functionalities are:
 * - adding and removing investment strategies that any delegator can invest into
 * - enabling deposit of assets into specified investment delegation(s)
 * - enabling removal of assets from specified investment delegation(s)
 * - recording deposit of ETH into settlement layer
 * - recording deposit for securing
 * - slashing of assets for permissioned strategies
 */
abstract contract DelegationManager is
    Initializable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    DelegationManagerStorage,
    WhiteList
{
    using SafeERC20 for IERC20;

    /**
     * @notice Value to which `initTimestamp` and `unlockTimestamp` to is set to indicate a withdrawal is queued/initialized,
     * but has not yet had its waiting period triggered
     */
    uint32 internal constant QUEUED_WITHDRAWAL_INITIALIZED_VALUE = type(uint32).max;

    /**
     * @notice Emitted when a new withdrawal is queued by `depositor`.
     * @param depositor Is the staker who is withdrawing funds.
     * @param withdrawer Is the party specified by `staker` who will be able to complete the queued withdrawal and receive the withdrawn funds.
     * @param delegatedAddress Is the party who the `staker` was delegated to at the time of creating the queued withdrawal
     * @param withdrawalRoot Is a hash of the input data for the withdrawal.
     */
    event WithdrawalQueued(
        address indexed depositor, address indexed withdrawer, address indexed delegatedAddress, bytes32 withdrawalRoot
    );

    /// @notice Emitted when a queued withdrawal is completed
    event WithdrawalCompleted(address indexed depositor, address indexed withdrawer, bytes32 withdrawalRoot);

    modifier onlyNotFrozen(address staker) {
        require(
            !delegationSlasher.isFrozen(staker),
            "DelegationManager.onlyNotFrozen: staker has been frozen and may be subject to slashing"
        );
        _;
    }

    modifier onlyFrozen(address staker) {
        require(delegationSlasher.isFrozen(staker), "DelegationManager.onlyFrozen: staker has not been frozen");
        _;
    }

    /**
     * @param _delegation The delegation contract.
     * @param _delegationSlasher The primary slashing contract.
     */
    constructor(IDelegation _delegation, IDelegationSlasher _delegationSlasher)
        DelegationManagerStorage(_delegation, _delegationSlasher)
    {
        _disableInitializers();
    }

    // EXTERNAL FUNCTIONS

    /**
     * @notice Initializes the investment manager contract. Sets the `pauserRegistry` (currently **not** modifiable after being set),
     * and transfers contract ownership to the specified `initialOwner`.
     * @param initialOwner Ownership of this contract is transferred to this address.
     */
    function initialize(address initialOwner)
        external
        initializer
    {
        DOMAIN_SEPARATOR = keccak256(abi.encode(DOMAIN_TYPEHASH, bytes("Mantle"), block.chainid, address(this)));
        _transferOwnership(initialOwner);
    }

    /**
     * @notice Deposits `amount` of `token` into the specified `delegationShare`, with the resultant shares credited to `depositor`
     * @param delegationShare is the specified delegation contract where investment is to be made,
     * @param token is the denomination in which the investment is to be made,
     * @param amount is the amount of token to be invested in the delegation contract by the depositor
     * @dev The `msg.sender` must have previously approved this contract to transfer at least `amount` of `token` on their behalf.
     * @dev Cannot be called by an address that is 'frozen' (this function will revert if the `msg.sender` is frozen).
     */
    function depositInto(IDelegationShare delegationShare, IERC20 token, uint256 amount)
        external
        onlyNotFrozen(msg.sender)
        nonReentrant
        whitelistOnly(address(delegationShare))
        returns (uint256 shares)
    {
        shares = _depositInto(msg.sender, delegationShare, token, amount);
    }

    /**
     * @notice Called by a staker to undelegate entirely. The staker must first withdraw all of their existing deposits
     * (through use of the `queueWithdrawal` function), or else otherwise have never deposited prior to delegating.
     */
    function undelegate() external {
        _undelegate(msg.sender);
    }

    /**
     * @notice Called by a staker to queue a withdraw in the given token and shareAmount from each of the respective given strategies.
     * @dev Stakers will complete their withdrawal by calling the 'completeQueuedWithdrawal' function.
     * User shares are decreased in this function, but the total number of shares in each delegation contract remains the same.
     * The total number of shares is decremented in the 'completeQueuedWithdrawal' function instead, which is where
     * the funds are actually sent to the user through use of the strategies' 'withdrawal' function. This ensures
     * that the value per share reported by each delegation contract will remain consistent, and that the shares will continue
     * to accrue gains during the enforced WITHDRAWAL_WAITING_PERIOD.
     * @param delegationIndexes is a list of the indices in `investorStrats[msg.sender]` that correspond to the strategies
     * for which `msg.sender` is withdrawing 100% of their shares
     * @dev strategies are removed from `investorStrats` by swapping the last entry with the entry to be removed, then
     * popping off the last entry in `investorStrats`. The simplest way to calculate the correct `delegationIndexes` to input
     * is to order the strategies *for which `msg.sender` is withdrawing 100% of their shares* from highest index in
     * `investorStrats` to lowest index
     */
    function queueWithdrawal(
        uint256[] calldata delegationIndexes,
        IDelegationShare[] calldata delegationShares,
        IERC20[] calldata tokens,
        uint256[] calldata shares,
        WithdrawerAndNonce calldata withdrawerAndNonce,
        bool undelegateIfPossible
    )
        external
        virtual
        whenNotPaused
        onlyNotFrozen(msg.sender)
        nonReentrant
        returns (bytes32)
    {
        require(
            withdrawerAndNonce.nonce == numWithdrawalsQueued[msg.sender],
            "DelegationManager.queueWithdrawal: provided nonce incorrect"
        );
        // increment the numWithdrawalsQueued of the sender
        unchecked {
            ++numWithdrawalsQueued[msg.sender];
        }

        uint256 delegationIndex;

        // modify delegated shares accordingly, if applicable
        delegation.decreaseDelegatedShares(msg.sender, delegationShares, shares);

        for (uint256 i = 0; i < delegationShares.length;) {
            // the internal function will return 'true' in the event the delegation contrat was
            // removed from the depositor's array of strategies -- i.e. investorStrats[depositor]
            if (_removeShares(msg.sender, delegationIndexes[delegationIndex], delegationShares[i], shares[i])) {
                unchecked {
                    ++delegationIndex;
                }
            }

            //increment the loop
            unchecked {
                ++i;
            }
        }

        // fetch the address that the `msg.sender` is delegated to
        address delegatedAddress = delegation.delegatedTo(msg.sender);

        // copy arguments into struct and pull delegation info
        QueuedWithdrawal memory queuedWithdrawal = QueuedWithdrawal({
            delegations: delegationShares,
            tokens: tokens,
            shares: shares,
            depositor: msg.sender,
            withdrawerAndNonce: withdrawerAndNonce,
            delegatedAddress: delegatedAddress
        });

        // calculate the withdrawal root
        bytes32 withdrawalRoot = calculateWithdrawalRoot(queuedWithdrawal);

        //update storage in mapping of queued withdrawals
        queuedWithdrawals[withdrawalRoot] = WithdrawalStorage({
            /**
             * @dev We add `REASONABLE_STAKES_UPDATE_PERIOD` to the current time here to account for the fact that it may take some time for
             * the operator's stake to be updated on all the middlewares. New tasks created between now at this 'initTimestamp' may still
             * subject the `msg.sender` to slashing!
             */
            initTimestamp: uint32(block.timestamp + REASONABLE_STAKES_UPDATE_PERIOD),
            withdrawer: withdrawerAndNonce.withdrawer,
            unlockTimestamp: QUEUED_WITHDRAWAL_INITIALIZED_VALUE
        });

        // If the `msg.sender` has withdrawn all of their funds in this transaction, then they can choose to also undelegate
        /**
         * Checking that `investorStrats[msg.sender].length == 0` is not strictly necessary here, but prevents reverting very late in logic,
         * in the case that 'undelegate' is set to true but the `msg.sender` still has active deposits.
         */
        if (undelegateIfPossible && investorDelegations[msg.sender].length == 0) {
            _undelegate(msg.sender);
        }

        emit WithdrawalQueued(msg.sender, withdrawerAndNonce.withdrawer, delegatedAddress, withdrawalRoot);

        return withdrawalRoot;
    }

    /*
    *
    * @notice The withdrawal flow is:
    * - Depositor starts a queued withdrawal, setting the receiver of the withdrawn funds as withdrawer
    * - Withdrawer then waits for the queued withdrawal tx to be included in the chain, and then sets the stakeInactiveAfter. This cannot
    *   be set when starting the queued withdrawal, as it is there may be transactions the increase the tasks upon which the stake is active
    *   that get mined before the withdrawal.
    * - The withdrawer completes the queued withdrawal after the stake is inactive or a withdrawal fraud proof period has passed,
    *   whichever is longer. They specify whether they would like the withdrawal in shares or in tokens.
    */
    function startQueuedWithdrawalWaitingPeriod(bytes32 withdrawalRoot, uint32 stakeInactiveAfter) external virtual {
        require(
            queuedWithdrawals[withdrawalRoot].unlockTimestamp == QUEUED_WITHDRAWAL_INITIALIZED_VALUE,
            "DelegationManager.startQueuedWithdrawalWaitingPeriod: Withdrawal stake inactive claim has already been made"
        );
        require(
            queuedWithdrawals[withdrawalRoot].withdrawer == msg.sender,
            "DelegationManager.startQueuedWithdrawalWaitingPeriod: Sender is not the withdrawer"
        );
        require(
            block.timestamp > queuedWithdrawals[withdrawalRoot].initTimestamp,
            "DelegationManager.startQueuedWithdrawalWaitingPeriod: Stake may still be subject to slashing based on new tasks. Wait to set stakeInactiveAfter."
        );
        //they can only unlock after a withdrawal waiting period or after they are claiming their stake is inactive
        queuedWithdrawals[withdrawalRoot].unlockTimestamp = max((uint32(block.timestamp) + WITHDRAWAL_WAITING_PERIOD), stakeInactiveAfter);
    }

    /**
     * @notice Used to complete the specified `queuedWithdrawal`. The function caller must match `queuedWithdrawal.withdrawer`
     * @param queuedWithdrawal The QueuedWithdrawal to complete.
     * @param receiveAsTokens If true, the shares specified in the queued withdrawal will be withdrawn from the specified strategies themselves
     * and sent to the caller, through calls to `queuedWithdrawal.delegations[i].withdraw`. If false, then the shares in the specified strategies
     * will simply be transferred to the caller directly.
     */
    function completeQueuedWithdrawal(QueuedWithdrawal calldata queuedWithdrawal, bool receiveAsTokens)
        external
        whenNotPaused
        // check that the address that the staker *was delegated to* – at the time that they queued the withdrawal – is not frozen
        onlyNotFrozen(queuedWithdrawal.delegatedAddress)
        nonReentrant
    {
        // find the withdrawalRoot
        bytes32 withdrawalRoot = calculateWithdrawalRoot(queuedWithdrawal);
        // copy storage to memory
        WithdrawalStorage memory withdrawalStorageCopy = queuedWithdrawals[withdrawalRoot];

        // verify that the queued withdrawal actually exists
        require(
            withdrawalStorageCopy.unlockTimestamp != 0,
            "DelegationManager.completeQueuedWithdrawal: withdrawal does not exist"
        );

        require(
            uint32(block.timestamp) >= withdrawalStorageCopy.unlockTimestamp
                || (queuedWithdrawal.delegatedAddress == address(0)),
            "DelegationManager.completeQueuedWithdrawal: withdrawal waiting period has not yet passed and depositor was delegated when withdrawal initiated"
        );

        // TODO: add testing coverage for this
        require(
            msg.sender == queuedWithdrawal.withdrawerAndNonce.withdrawer,
            "DelegationManager.completeQueuedWithdrawal: only specified withdrawer can complete a queued withdrawal"
        );

        // reset the storage slot in mapping of queued withdrawals
        delete queuedWithdrawals[withdrawalRoot];

        // store length for gas savings
        uint256 strategiesLength = queuedWithdrawal.delegations.length;
        // if the withdrawer has flagged to receive the funds as tokens, withdraw from strategies
        if (receiveAsTokens) {
            // actually withdraw the funds
            for (uint256 i = 0; i < strategiesLength;) {
                // tell the delegation to send the appropriate amount of funds to the depositor
                queuedWithdrawal.delegations[i].withdraw(
                    withdrawalStorageCopy.withdrawer, queuedWithdrawal.tokens[i], queuedWithdrawal.shares[i]
                );
                unchecked {
                    ++i;
                }
            }
        } else {
            // else increase their shares
            for (uint256 i = 0; i < strategiesLength;) {
                _addShares(withdrawalStorageCopy.withdrawer, queuedWithdrawal.delegations[i], queuedWithdrawal.shares[i]);
                unchecked {
                    ++i;
                }
            }
        }

        emit WithdrawalCompleted(queuedWithdrawal.depositor, withdrawalStorageCopy.withdrawer, withdrawalRoot);
    }

    /**
     * @notice Slashes the shares of a 'frozen' operator (or a staker delegated to one)
     * @param slashedAddress is the frozen address that is having its shares slashed
     * @param delegationIndexes is a list of the indices in `investorStrats[msg.sender]` that correspond to the strategies
     * for which `msg.sender` is withdrawing 100% of their shares
     * @param recipient The slashed funds are withdrawn as tokens to this address.
     * @dev delegationShares are removed from `investorStrats` by swapping the last entry with the entry to be removed, then
     * popping off the last entry in `investorStrats`. The simplest way to calculate the correct `delegationIndexes` to input
     * is to order the strategies *for which `msg.sender` is withdrawing 100% of their shares* from highest index in
     * `investorStrats` to lowest index
     */
    function slashShares(
        address slashedAddress,
        address recipient,
        IDelegationShare[] calldata delegationShares,
        IERC20[] calldata tokens,
        uint256[] calldata delegationIndexes,
        uint256[] calldata shareAmounts
    )
        external
        virtual
        whenNotPaused
        onlyOwner
        onlyFrozen(slashedAddress)
        nonReentrant
    {
        uint256 delegationIndex;
        uint256 strategiesLength = delegationShares.length;
        for (uint256 i = 0; i < strategiesLength;) {
            // the internal function will return 'true' in the event the delegation contract was
            // removed from the slashedAddress's array of strategies -- i.e. investorStrats[slashedAddress]
            if (_removeShares(slashedAddress, delegationIndexes[delegationIndex], delegationShares[i], shareAmounts[i])) {
                unchecked {
                    ++delegationIndex;
                }
            }

            // withdraw the shares and send funds to the recipient
            delegationShares[i].withdraw(recipient, tokens[i], shareAmounts[i]);

            // increment the loop
            unchecked {
                ++i;
            }
        }

        // modify delegated shares accordingly, if applicable
        delegation.decreaseDelegatedShares(slashedAddress, delegationShares, shareAmounts);
    }

    /**
     * @notice Slashes an existing queued withdrawal that was created by a 'frozen' operator (or a staker delegated to one)
     * @param recipient The funds in the slashed withdrawal are withdrawn as tokens to this address.
     */
    function slashQueuedWithdrawal(address recipient, QueuedWithdrawal calldata queuedWithdrawal)
        external
        whenNotPaused
        onlyOwner
        nonReentrant
    {
        // find the withdrawalRoot
        bytes32 withdrawalRoot = calculateWithdrawalRoot(queuedWithdrawal);

        // verify that the queued withdrawal actually exists
        require(
            queuedWithdrawals[withdrawalRoot].unlockTimestamp != 0,
            "DelegationManager.slashQueuedWithdrawal: withdrawal does not exist"
        );

        // verify that *either* the queued withdrawal has been successfully challenged, *or* the `depositor` has been frozen
        require(
            queuedWithdrawals[withdrawalRoot].withdrawer == address(0) || delegationSlasher.isFrozen(queuedWithdrawal.depositor),
            "DelegationManager.slashQueuedWithdrawal: withdrawal has not been successfully challenged or depositor is not frozen"
        );

        // reset the storage slot in mapping of queued withdrawals
        delete queuedWithdrawals[withdrawalRoot];

        uint256 strategiesLength = queuedWithdrawal.delegations.length;
        for (uint256 i = 0; i < strategiesLength;) {
            // tell the delegation contract to send the appropriate amount of funds to the recipient
            queuedWithdrawal.delegations[i].withdraw(recipient, queuedWithdrawal.tokens[i], queuedWithdrawal.shares[i]);
            unchecked {
                ++i;
            }
        }
    }

    // INTERNAL FUNCTIONS

    /**
     * @notice This function adds `shares` for a given `delegationShare` to the `depositor` and runs through the necessary update logic.
     * @dev In particular, this function calls `delegation.increaseDelegatedShares(depositor, delegationShare, shares)` to ensure that all
     * delegated shares are tracked, increases the stored share amount in `investorStratShares[depositor][delegationShare]`, and adds `delegationShare`
     * to the `depositor`'s list of strategies, if it is not in the list already.
     */
    function _addShares(address depositor, IDelegationShare delegationShare, uint256 shares) internal {
        // sanity check on `shares` input
        require(shares != 0, "DelegationManager._addShares: shares should not be zero!");

        // if they dont have existing shares of this delegation contract, add it to their strats
        if (investorDelegationShares[depositor][delegationShare] == 0) {
            require(
                investorDelegations[depositor].length <= MAX_INVESTOR_DELEGATION_LENGTH,
                "DelegationManager._addShares: deposit would exceed MAX_INVESTOR_DELEGATION_LENGTH"
            );
            investorDelegations[depositor].push(delegationShare);
        }

        // add the returned shares to their existing shares for this delegation contract
        investorDelegationShares[depositor][delegationShare] += shares;

        // if applicable, increase delegated shares accordingly
        delegation.increaseDelegatedShares(depositor, delegationShare, shares);
    }

    /**
     * @notice Internal function in which `amount` of ERC20 `token` is transferred from `msg.sender` to the InvestmentDelegation-type contract
     * `delegationShare`, with the resulting shares credited to `depositor`.
     * @return shares The amount of *new* shares in `delegationShare` that have been credited to the `depositor`.
     */
    function _depositInto(address depositor, IDelegationShare delegationShare, IERC20 token, uint256 amount)
        internal
        returns (uint256 shares)
    {

        // transfer tokens from the sender to the delegation contract
        token.safeTransferFrom(depositor, address(delegationShare), amount);

        // deposit the assets into the specified delegation contract and get the equivalent amount of shares in that delegation contract
        shares = delegationShare.deposit(depositor, token, amount);

        // add the returned shares to the depositor's existing shares for this delegation contract
        _addShares(depositor, delegationShare, shares);

        return shares;
    }

    /**
     * @notice Decreases the shares that `depositor` holds in `delegationShare` by `shareAmount`.
     * @dev If the amount of shares represents all of the depositor`s shares in said delegation contract,
     * then the delegation contract is removed from investorStrats[depositor] and 'true' is returned. Otherwise 'false' is returned.
     */
    function _removeShares(address depositor, uint256 delegationIndex, IDelegationShare delegationShare, uint256 shareAmount)
        internal
        returns (bool)
    {
        // sanity check on `shareAmount` input
        require(shareAmount != 0, "DelegationManager._removeShares: shareAmount should not be zero!");

        //check that the user has sufficient shares
        uint256 userShares = investorDelegationShares[depositor][delegationShare];


        require(shareAmount <= userShares, "DelegationManager._removeShares: shareAmount too high");
        //unchecked arithmetic since we just checked this above
        unchecked {
            userShares = userShares - shareAmount;
        }

        // subtract the shares from the depositor's existing shares for this delegation contract
        investorDelegationShares[depositor][delegationShare] = userShares;
        // if no existing shares, remove is from this investors strats

        if (userShares == 0) {
            // remove the delegation contract from the depositor's dynamic array of strategies
            _removeDelegationFromInvestorDelegations(depositor, delegationIndex, delegationShare);

            // return true in the event that the delegation contract was removed from investorStrats[depositor]
            return true;
        }
        // return false in the event that the delegation contract was *not* removed from investorStrats[depositor]
        return false;
    }

    /**
     * @notice Removes `delegationShare` from `depositor`'s dynamic array of strategies, i.e. from `investorStrats[depositor]`
     * @dev the provided `delegationIndex` input is optimistically used to find the delegation contract quickly in the list. If the specified
     * index is incorrect, then we revert to a brute-force search.
     */
    function _removeDelegationFromInvestorDelegations(address depositor, uint256 delegationIndex, IDelegationShare delegationShare) internal {
        // if the delegation contract matches with the delegation contract index provided
        if (investorDelegations[depositor][delegationIndex] == delegationShare) {
            // replace the delegation contract with the last delegation contract in the list
            investorDelegations[depositor][delegationIndex] =
            investorDelegations[depositor][investorDelegations[depositor].length - 1];
        } else {
            //loop through all of the strategies, find the right one, then replace
            uint256 delegationLength = investorDelegations[depositor].length;

            for (uint256 j = 0; j < delegationLength;) {
                if (investorDelegations[depositor][j] == delegationShare) {
                    //replace the delegation contract with the last delegation contract in the list
                    investorDelegations[depositor][j] = investorDelegations[depositor][investorDelegations[depositor].length - 1];
                    break;
                }
                unchecked {
                    ++j;
                }
            }
        }

        // pop off the last entry in the list of strategies
        investorDelegations[depositor].pop();
    }

    /**
     * @notice If the `depositor` has no existing shares, then they can `undelegate` themselves.
     * This allows people a "hard reset" in their relationship after withdrawing all of their stake.
     */
    function _undelegate(address depositor) internal {
        require(investorDelegations[depositor].length == 0, "InvestmentManager._undelegate: depositor has active deposits");
        delegation.undelegate(depositor);
    }

    function max(uint32 x, uint32 y) internal pure returns (uint32) {
        return x > y ? x : y;
    }

    // VIEW FUNCTIONS

    /**
     * @notice Used to check if a queued withdrawal can be completed. Returns 'true' if the withdrawal can be immediately
     * completed, and 'false' otherwise.
     * @dev This function will revert if the specified `queuedWithdrawal` does not exist
     */
    function canCompleteQueuedWithdrawal(QueuedWithdrawal calldata queuedWithdrawal) external view returns (bool) {
        // find the withdrawalRoot
        bytes32 withdrawalRoot = calculateWithdrawalRoot(queuedWithdrawal);

        // verify that the queued withdrawal actually exists
        require(
            queuedWithdrawals[withdrawalRoot].unlockTimestamp != 0,
            "DelegationManager.canCompleteQueuedWithdrawal: withdrawal does not exist"
        );

        if (delegationSlasher.isFrozen(queuedWithdrawal.delegatedAddress)) {
            return false;
        }

        return (
            uint32(block.timestamp) >= queuedWithdrawals[withdrawalRoot].unlockTimestamp
                || (queuedWithdrawal.delegatedAddress == address(0))
        );
    }

    /**
     * @notice Get all details on the depositor's investments and corresponding shares
     * @return (depositor's strategies, shares in these strategies)
     */
    function getDeposits(address depositor) external view returns (IDelegationShare[] memory, uint256[] memory) {
        uint256 delegationLength = investorDelegations[depositor].length;
        uint256[] memory shares = new uint256[](delegationLength);

        for (uint256 i = 0; i < delegationLength;) {
            shares[i] = investorDelegationShares[depositor][investorDelegations[depositor][i]];
            unchecked {
                ++i;
            }
        }
        return (investorDelegations[depositor], shares);
    }

    /// @notice Simple getter function that returns `investorStrats[staker].length`.
    function investorDelegationLength(address staker) external view returns (uint256) {
        return investorDelegations[staker].length;
    }

    /// @notice Returns the keccak256 hash of `queuedWithdrawal`.
    function calculateWithdrawalRoot(QueuedWithdrawal memory queuedWithdrawal) public pure returns (bytes32) {
        return (
            keccak256(
                abi.encode(
                    queuedWithdrawal.delegations,
                    queuedWithdrawal.tokens,
                    queuedWithdrawal.shares,
                    queuedWithdrawal.depositor,
                    queuedWithdrawal.withdrawerAndNonce,
                    queuedWithdrawal.delegatedAddress
                )
            )
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.9.0;

interface ITssGroupManager {
    enum MemberStatus {
        unJail,
        jail
    }

    struct TssMember {
        bytes         publicKey;
        address       nodeAddress;
        MemberStatus  status;
    }

    function setTssGroupMember(uint256 _threshold, bytes[] memory _batchPublicKey) external;
    function setGroupPublicKey(bytes memory _publicKey, bytes memory _groupPublicKey) external;
    function getTssGroupInfo() external returns (uint256, uint256, bytes memory, bytes[] memory);
    function getTssInactiveGroupInfo() external returns (uint256, uint256, bytes[] memory);
    function memberJail(bytes memory _publicKey) external;
    function memberUnJail(bytes memory _publicKey) external;
    function removeMember(bytes memory _publicKey) external;
    function getTssGroupUnJailMembers() external returns (address[] memory);
    function getTssGroupMembers() external returns (bytes[] memory);
    function getTssMember(bytes memory _publicKey) external returns (TssMember memory);
    function memberExistActive(bytes memory _publicKey) external returns (bool);
    function memberExistInActive(bytes memory _publicKey) external returns (bool);
    function inActiveIsEmpty() external returns (bool);
    function verifySign(bytes32 _message, bytes memory _sig) external returns (bool);
    function publicKeyToAddress (bytes memory publicKey) external returns (address);
    function isTssGroupUnJailMembers(address _addr) external returns (bool);
    function memberExistActive(address _addr) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

import {DelegationShareBase} from "../delegation/DelegationShareBase.sol";
import {DelegationCallbackBase} from "../delegation/DelegationCallbackBase.sol";
import {IDelegationManager} from "../delegation/interfaces/IDelegationManager.sol";
import {IDelegationShare} from "../delegation/interfaces/IDelegation.sol";
import {IDelegation} from "../delegation/interfaces/IDelegation.sol";
import {CrossDomainEnabled} from "../../libraries/bridge/CrossDomainEnabled.sol";
import {ITssRewardContract} from "../../L2/predeploys/iTssRewardContract.sol";
import {TssDelegationManager} from "./delegation/TssDelegationManager.sol";
import {TssDelegation} from "./delegation/TssDelegation.sol";
import {WhiteList} from "../delegation/WhiteListBase.sol";

import "./ITssGroupManager.sol";
import "./ITssStakingSlashing.sol";

contract TssStakingSlashing is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    IStakingSlashing,
    DelegationShareBase,
    DelegationCallbackBase,
    CrossDomainEnabled
{
    enum SlashType {
        uptime,
        animus
    }

    struct SlashMsg {
        uint256 batchIndex;
        address jailNode;
        address[] tssNodes;
        SlashType slashType;
    }
    // tss group contract address
    address public tssGroupContract;
    //tss delegation manager address
    address public tssDelegationManagerContract;
    //tss delegation address
    address public tssDelegationContract;
    // storage operator infos (key:staker address)
    mapping(address => bytes) public operators;

    // slashing parameter settings
    // record the quit request
    address[] public quitRequestList;
    // slashing amount of type uptime and animus (0:uptime, 1:animus)
    uint256[2] public slashAmount;
    // record the slash operate (map[batchIndex] -> (map[staker] -> slashed))
    mapping(uint256 => mapping(address => bool)) slashRecord;
    //EOA address
    address public regulatoryAccount;
    //msg sender => withdraw event
    mapping(address => bytes32) public withdrawalRoots;
    //msg sender => withdrawal
    mapping(address => IDelegationManager.QueuedWithdrawal) public withdrawals;
    //operator => stakers
    mapping(address => address[]) public stakers;
    //staker => operator
    mapping(address => address) public delegators;
    //operator => claimer
    mapping(address => address) public operatorClaimers;
    //claimer => operator
    mapping(address => address) public claimerOperators;
    bool public isSetParam;


    /**
     * @notice slash tssnode
     * @param 0 slashed address
     * @param 1 slash type
     */
    event Slashing(address, SlashType);

    event WithdrawQueue(address,uint256);

    constructor()  CrossDomainEnabled(address(0)) {
        _disableInitializers();
    }

    /**
     * @notice initializes the contract setting and the deployer as the initial owner
     * @param _mantleToken mantle token contract address
     * @param _tssGroupContract address tss group manager contract address
     */
    function initialize(address _mantleToken,
        address _tssGroupContract,
        address _delegationManager,
        address _delegation,
        address _l1messenger,
        address _regulatoryAccount
        ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        underlyingToken = IERC20(_mantleToken);
        tssGroupContract = _tssGroupContract;
        tssDelegationManagerContract = _delegationManager;
        tssDelegationContract = _delegation;
        //initialize delegation
        delegationManager = IDelegationManager(_delegationManager);
        delegation = IDelegation(_delegation);
        messenger = _l1messenger;
        regulatoryAccount = _regulatoryAccount;
    }

    /**
     * @notice change the mantle token and tssGroup contract address
     * @param _token the erc20 mantle token contract address
     */
    function setTokenAddress(address _token) public onlyOwner {
        require(_token != address(0),"Invalid address");
        underlyingToken = IERC20(_token);
    }

    function setTssGroupAddress(address _tssGroup) public onlyOwner{
        require(_tssGroup != address(0),"Invalid address");
        tssGroupContract = _tssGroup;
    }

    function setRegulatoryAccount(address _account) public onlyOwner {
        require(_account != address(0),"Invalid address");
        regulatoryAccount = _account;
    }

    function setPublicKey(bytes calldata _pubKey) public nonReentrant {
        require(delegation.isOperator(msg.sender),"msg sender has not registered operator");
        operators[msg.sender] = _pubKey;

    }

    function setClaimer(
        address _operator,
        address _claimer
    ) external {
        require(msg.sender == _operator, "msg sender is diff with operator address");
        require(delegation.isOperator(msg.sender), "msg sender is not registered operator");
        require(claimerOperators[_claimer] == address(0), "the claimer has been used");
        if (operatorClaimers[_operator] != address(0)) {
            delete claimerOperators[operatorClaimers[_operator]];
        }
        operatorClaimers[_operator] = _claimer;
        claimerOperators[_claimer] = _operator;

        bytes memory message = abi.encodeWithSelector(
            ITssRewardContract.setClaimer.selector,
            _operator,
            _claimer
        );
        // send call data into L2, hardcode address
        sendCrossDomainMessage(
            address(0x4200000000000000000000000000000000000020),
            2000000,
            message
        );
    }

    /**
     * @notice set the slashing params (0 -> uptime , 1 -> animus)
     * @param _slashAmount the amount to be deducted for each type
     */
    function setSlashingParams(uint256[2] calldata _slashAmount)
        public
        onlyOwner
    {
        require(_slashAmount[1] > _slashAmount[0], "invalid param slashAmount, animus <= uptime");

        for (uint256 i = 0; i < 2; i++) {
            require(_slashAmount[i] > 0, "invalid amount");
            slashAmount[i] = _slashAmount[i];
        }
        isSetParam = true;
    }

    /**
     * @notice set the slashing params (0 -> uptime, 1 -> animus)
     */
    function getSlashingParams() public view returns (uint256[2] memory) {
        return slashAmount;
    }

    /**
     * @notice send quit request for the next election
     */
    function quitRequest() public nonReentrant {

        require(delegation.operatorShares(msg.sender, this) > 0, "do not have deposit");
        // when not in consensus period
        require(
            ITssGroupManager(tssGroupContract).memberExistInActive(operators[msg.sender]) ||
                ITssGroupManager(tssGroupContract).memberExistActive(operators[msg.sender]),
            "not at the inactive group or active group"
        );
        // is active member
        for (uint256 i = 0; i < quitRequestList.length; i++) {
            require(quitRequestList[i] != msg.sender, "already in quitRequestList");
        }
        quitRequestList.push(msg.sender);
    }

    /**
     * @notice return the quit list
     */
    function getQuitRequestList() public view returns (address[] memory) {
        return quitRequestList;
    }

    /**
     * @notice clear the quit list
     */
    function clearQuitRequestList() public onlyOwner {
        delete quitRequestList;
    }

    /**
     * @notice verify the slash message then slash
     * @param _messageBytes the message that abi encode by type SlashMsg
     * @param _sig the signature of the hash keccak256(_messageBytes)
     */
    function slashing(bytes calldata _messageBytes, bytes calldata _sig) public nonReentrant {
        SlashMsg memory message = abi.decode(_messageBytes, (SlashMsg));
        // verify tss member state not at jailed status
        require(!isJailed(message.jailNode), "the node already jailed");

        // have not slash before
        require(!slashRecord[message.batchIndex][message.jailNode], "already slashed");
        slashRecord[message.batchIndex][message.jailNode] = true;

        require(
            ITssGroupManager(tssGroupContract).verifySign(keccak256(_messageBytes), _sig),
            "signer not tss group pub key"
        );

        // slash tokens
        slash(message);
        emit Slashing(message.jailNode, message.slashType);
    }

    /**
     * @notice slash the staker and distribute rewards to voters
     * @param message the message about the slash infos
     */
    function slash(SlashMsg memory message) internal {
        // slashing params check
        require(isSetParam,"have not set the slash amount");
        bytes memory jailNodePubKey = operators[message.jailNode];
        if (message.slashType == SlashType.uptime) {
            // jail and transfer deposits
            ITssGroupManager(tssGroupContract).memberJail(jailNodePubKey);
            transformDeposit(message.jailNode, 0);
        } else if (message.slashType == SlashType.animus) {
            // remove the member and transfer deposits
            ITssGroupManager(tssGroupContract).memberJail(jailNodePubKey);
            transformDeposit(message.jailNode, 1);
        } else {
            revert("err type for slashing");
        }

    }

    /**
     * @notice distribute rewards to voters
     * @param deduction address of the punished
     * @param slashType the type to punished
     */
    function transformDeposit(
        address deduction,
        uint256 slashType
    ) internal {
        uint256 deductedAmountShare;

        uint256 totalBalance = _tokenBalance();

        require(
            (delegation.operatorShares(deduction, this) * totalBalance) / totalShares >= slashAmount[slashType],
            "do not have enought shares"
        );
        // record total penalty
        deductedAmountShare = (slashAmount[slashType] * totalShares) / totalBalance;

        uint256 operatorShare = delegation.operatorShares(deduction, this);

        IDelegationShare[] memory delegationShares = new IDelegationShare[](1);
        delegationShares[0] = this;

        uint256[] memory delegationShareIndexes = new uint256[](1);
        delegationShareIndexes[0] = 0;


        IERC20[] memory tokens = new IERC20[](1);
        tokens[0] = underlyingToken;

        address[] memory stakerS = stakers[deduction];
        for (uint256 i = 0; i < stakerS.length; i++){
            uint256 share = shares(stakerS[i]);
            uint256[] memory shareAmounts = new uint256[](1);
            shareAmounts[0] = deductedAmountShare * share / operatorShare;
            TssDelegationManager(tssDelegationManagerContract).slashShares(stakerS[i], regulatoryAccount, delegationShares,tokens, delegationShareIndexes, shareAmounts);
        }

    }

    /**
     * @notice set tss node status unjail
     */
    function unJail() public {
        // slashing params check
        require(isSetParam, "have not set the slash amount");

        uint256 totalBalance = _tokenBalance();

        require((delegation.operatorShares(msg.sender, this) * totalBalance) / totalShares >= slashAmount[1], "Insufficient balance");
        ITssGroupManager(tssGroupContract).memberUnJail(operators[msg.sender]);
    }


    /**
     * @notice get the slash record
     * @param batchIndex the index of batch
     * @param user address of the staker
     */
    function getSlashRecord(uint256 batchIndex, address user) public view returns (bool) {
        return slashRecord[batchIndex][user];
    }

    /**
     * @notice check the tssnode status
     * @param user address of the staker
     */
    function isJailed(address user) public returns (bool) {
        ITssGroupManager.TssMember memory tssMember = ITssGroupManager(tssGroupContract)
            .getTssMember(operators[user]);
        require(tssMember.publicKey.length == 64, "tss member not exist");
        return tssMember.status == ITssGroupManager.MemberStatus.jail;
    }

    function isCanOperator(address _addr) public returns (bool) {
        return TssDelegationManager(tssDelegationManagerContract).isCanOperator(_addr, this);
    }

    function deposit(uint256 amount) public returns (uint256) {
       uint256 shares = TssDelegationManager(tssDelegationManagerContract).depositInto(this, underlyingToken, amount, msg.sender);
       return shares;
    }

    function withdraw() external {
        require(delegation.isDelegated(msg.sender),"not delegator");

        require(
            withdrawalRoots[msg.sender] == bytes32(0),
            "msg sender already request withdraws"
        );

        uint256[] memory delegationIndexes = new uint256[](1);
        delegationIndexes[0] = 0;
        IDelegationShare[] memory delegationShares = new IDelegationShare[](1);
        delegationShares[0] = this;
        IERC20[] memory tokens = new IERC20[](1);
        tokens[0] = underlyingToken;
        uint256[] memory sharesA = new uint256[](1);
        sharesA[0] = shares(msg.sender);
        uint256 nonce = TssDelegationManager(tssDelegationManagerContract).getWithdrawNonce(msg.sender);
        IDelegationManager.WithdrawerAndNonce memory withdrawerAndNonce = IDelegationManager.WithdrawerAndNonce({
            withdrawer: msg.sender,
            nonce: SafeCast.toUint96(nonce)
        });
        address operator = delegation.delegatedTo(msg.sender);

        IDelegationManager.QueuedWithdrawal memory queuedWithdrawal = IDelegationManager.QueuedWithdrawal({
            delegations: delegationShares,
            tokens: tokens,
            shares: sharesA,
            depositor: msg.sender,
            withdrawerAndNonce: withdrawerAndNonce,
            delegatedAddress: operator
        });
        withdrawals[msg.sender] = queuedWithdrawal;
        bytes32 withdrawRoot = TssDelegationManager(tssDelegationManagerContract).queueWithdrawal(msg.sender,delegationIndexes,delegationShares,tokens,sharesA,withdrawerAndNonce);
        withdrawalRoots[msg.sender] = withdrawRoot;
        emit WithdrawQueue(msg.sender, sharesA[0]);
    }

    function startWithdraw() external {
        require(
            withdrawalRoots[msg.sender] != bytes32(0),
            "msg sender must request withdraw first"
        );
        bytes32 withdrawRoot = withdrawalRoots[msg.sender];
        TssDelegationManager(tssDelegationManagerContract).startQueuedWithdrawalWaitingPeriod(withdrawRoot,msg.sender,0);
    }

    function canCompleteQueuedWithdrawal() external returns (bool) {

        require(
            withdrawalRoots[msg.sender] != bytes32(0),
            "msg sender did not request withdraws"
        );
        IDelegationManager.QueuedWithdrawal memory queuedWithdrawal = withdrawals[msg.sender];
        return delegationManager.canCompleteQueuedWithdrawal(queuedWithdrawal);
    }

    function completeWithdraw() external {

        require(
            withdrawalRoots[msg.sender] != bytes32(0),
            "msg sender did not request withdraws"
        );
        IDelegationManager.QueuedWithdrawal memory queuedWithdrawal = withdrawals[msg.sender];
        require(delegationManager.canCompleteQueuedWithdrawal(queuedWithdrawal),"The waiting period has not yet passed");
        TssDelegationManager(tssDelegationManagerContract).completeQueuedWithdrawal(msg.sender, queuedWithdrawal, true);
        delete withdrawalRoots[msg.sender];
        delete withdrawals[msg.sender];
    }

    function registerAsOperator(bytes calldata _pubKey) external {
        TssDelegation(tssDelegationContract).registerAsOperator(this, msg.sender);
        setPublicKey(_pubKey);
    }

    function delegateTo(address _operator) external {
        TssDelegation(tssDelegationContract).delegateTo(_operator, msg.sender);
    }


    function onDelegationReceived(
        address delegator,
        address operator,
        IDelegationShare[] memory delegationShares,
        uint256[] memory investorShares
    )external override onlyDelegation {
        uint256 delegationLength = delegationShares.length;
        require(delegationLength == 1,"delegation only for tss");
        require(investorShares.length == 1,"delegation share only for tss");
        require(address(delegationShares[0]) == address(this),"must use current contract");
        if (delegators[delegator] == address(0)) {
            delegators[delegator] = operator;
            stakers[operator].push(delegator);
        }
    }

    function onDelegationWithdrawn(
        address delegator,
        address operator,
        IDelegationShare[] memory delegationShares,
        uint256[] memory investorShares
    ) external override onlyDelegation {
        uint256 delegationLength = delegationShares.length;
        require(delegationLength == 1,"delegation only for tss");
        require(investorShares.length == 1,"delegation share only for tss");
        require(address(delegationShares[0]) == address(this),"must use current contract");
        if (TssDelegationManager(tssDelegationManagerContract).getDelegationShares(delegator, delegationShares[0]) == investorShares[0]){
            address[] memory staker = stakers[operator];
            for (uint256 j = 0; j < staker.length; j++) {
                if (staker[j] == delegator) {
                    stakers[operator][j] = stakers[operator][staker.length -1];
                    stakers[operator].pop();
                    delete delegators[delegator];
                }
            }
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./interfaces/IDelegationManager.sol";
import "./interfaces/IDelegationShare.sol";
import "./interfaces/IDelegation.sol";
import "./interfaces/IDelegationSlasher.sol";

/**
 * @title Storage variables for the `InvestmentManager` contract.
 * @author Layr Labs, Inc.
 * @notice This storage contract is separate from the logic to simplify the upgrade process.
 */
abstract contract DelegationManagerStorage is IDelegationManager {
    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");
    /// @notice The EIP-712 typehash for the deposit struct used by the contract
    bytes32 public constant DEPOSIT_TYPEHASH =
        keccak256("Deposit(address strategy,address token,uint256 amount,uint256 nonce,uint256 expiry)");
    /// @notice EIP-712 Domain separator
    bytes32 public DOMAIN_SEPARATOR;
    // staker => number of signed deposit nonce (used in depositIntoStrategyOnBehalfOf)
    mapping(address => uint256) public nonces;
    /**
     * @notice When a staker undelegates or an operator deregisters, their stake can still be slashed based on tasks/services created
     * within `REASONABLE_STAKES_UPDATE_PERIOD` of the present moment. In other words, this is the lag between undelegation/deregistration
     * and the staker's/operator's funds no longer being slashable due to misbehavior *on a new task*.
     */
    uint256 public constant REASONABLE_STAKES_UPDATE_PERIOD = 30 seconds;

    // fixed waiting period for withdrawals
    // TODO: set this to a proper interval for production
    uint32 public constant WITHDRAWAL_WAITING_PERIOD = 10 seconds;

    // maximum length of dynamic arrays in `investorStrats` mapping, for sanity's sake
    uint8 internal constant MAX_INVESTOR_DELEGATION_LENGTH = 32;

    // delegation system contracts
    IDelegation public immutable delegation;
    IDelegationSlasher public immutable delegationSlasher;

    // staker => IDelegationShare => number of shares which they currently hold
    mapping(address => mapping(IDelegationShare => uint256)) public investorDelegationShares;
    // staker => array of DelegationShare in which they have nonzero shares
    mapping(address => IDelegationShare[]) public investorDelegations;
    // hash of withdrawal inputs, aka 'withdrawalRoot' => timestamps & address related to the withdrawal
    mapping(bytes32 => WithdrawalStorage) public queuedWithdrawals;
    // staker => cumulative number of queued withdrawals they have ever initiated. only increments (doesn't decrement)
    mapping(address => uint256) public numWithdrawalsQueued;

    constructor(IDelegation _delegation, IDelegationSlasher _delegationSlasher) {
        delegation = _delegation;
        delegationSlasher = _delegationSlasher;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract WhiteList is OwnableUpgradeable {
    modifier whitelistOnly(address checkAddr) {
        if (!whitelist[checkAddr]) {
            revert("NOT_IN_WHITELIST");
        }
        _;
    }

    mapping(address => bool) public whitelist;

    /**
     * @notice Add to whitelist
     */
    function addToWhitelist(address[] calldata toAddAddresses) external onlyOwner {
        for (uint i = 0; i < toAddAddresses.length; i++) {
            whitelist[toAddAddresses[i]] = true;
        }
    }

    /**
     * @notice Remove from whitelist
     */
    function removeFromWhitelist(address[] calldata toRemoveAddresses) external onlyOwner {
        for (uint i = 0; i < toRemoveAddresses.length; i++) {
            delete whitelist[toRemoveAddresses[i]];
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IDelegationCallback.sol";

/**
 * @title Interface for the primary delegation contract.
 * @notice See the `Delegation` contract itself for implementation details.
 */
interface IDelegation {
    enum DelegationStatus {
        UNDELEGATED,
        DELEGATED
    }

    /**
     * @notice This will be called by an operator to register itself as an operator that stakers can choose to delegate to.
     * @param dt is the `DelegationTerms` contract that the operator has for those who delegate to them.
     * @dev An operator can set `dt` equal to their own address (or another EOA address), in the event that they want to split payments
     * in a more 'trustful' manner.
     * @dev In the present design, once set, there is no way for an operator to ever modify the address of their DelegationTerms contract.
     */
    function registerAsOperator(IDelegationCallback dt) external;

    /**
     *  @notice This will be called by a staker to delegate its assets to some operator.
     *  @param operator is the operator to whom staker (msg.sender) is delegating its assets
     */
    function delegateTo(address operator) external;

    /**
     * @notice Delegates from `staker` to `operator`.
     * @dev requires that r, vs are a valid ECSDA signature from `staker` indicating their intention for this action
     */
    function delegateToSignature(address staker, address operator, uint256 expiry, bytes32 r, bytes32 vs) external;

    /**
     * @notice Undelegates `staker` from the operator who they are delegated to.
     * @notice Callable only by the InvestmentManager
     * @dev Should only ever be called in the event that the `staker` has no active deposits.
     */
    function undelegate(address staker) external;

    /// @notice returns the address of the operator that `staker` is delegated to.
    function delegatedTo(address staker) external view returns (address);

    /// @notice returns the delegationCallback of the `operator`, which may mediate their interactions with stakers who delegate to them.
    function delegationCallback(address operator) external view returns (IDelegationCallback);

    /// @notice returns the total number of shares in `DelegationShare` that are delegated to `operator`.
    function operatorShares(address operator, IDelegationShare delegationShare) external view returns (uint256);

    /// @notice Returns 'true' if `staker` *is* actively delegated, and 'false' otherwise.
    function isDelegated(address staker) external view returns (bool);

    /// @notice Returns 'true' if `staker` is *not* actively delegated, and 'false' otherwise.
    function isNotDelegated(address staker) external returns (bool);

    /// @notice Returns if an operator can be delegated to, i.e. it has called `registerAsOperator`.
    function isOperator(address operator) external view returns (bool);

    /**
     * @notice Increases the `staker`'s delegated shares in `delegationShare` by `shares`, typically called when the staker has further deposits.
     * @dev Callable only by the DelegationManager
     */
    function increaseDelegatedShares(address staker, IDelegationShare delegationShare, uint256 shares) external;

    /**
     * @notice Decreases the `staker`'s delegated shares in `delegationShare` by `shares, typically called when the staker withdraws
     * @dev Callable only by the DelegationManager
     */
    function decreaseDelegatedShares(address staker, IDelegationShare delegationShare, uint256 shares) external;

    /// @notice Version of `decreaseDelegatedShares` that accepts an array of inputs.
    function decreaseDelegatedShares(
        address staker,
        IDelegationShare[] calldata delegationShares,
        uint256[] calldata shares
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT

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
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Minimal interface for an `IDelegationShares` contract.
 * @notice Custom `DelegationShares` implementations may expand extensively on this interface.
 */
interface IDelegationShare {
    /**
     * @notice Used to deposit tokens into this DelegationShares
     * @param token is the ERC20 token being deposited
     * @param amount is the amount of token being deposited
     * @dev This function is only callable by the delegationManager contract. It is invoked inside of the delegationManager's
     * `depositInto` function, and individual share balances are recorded in the delegationManager as well.
     * @return newShares is the number of new shares issued at the current exchange ratio.
     */
    function deposit(address depositor, IERC20 token, uint256 amount) external returns (uint256);

    /**
     * @notice Used to withdraw tokens from this DelegationLedger, to the `depositor`'s address
     * @param token is the ERC20 token being transferred out
     * @param amountShares is the amount of shares being withdrawn
     * @dev This function is only callable by the delegationManager contract. It is invoked inside of the delegationManager's
     * other functions, and individual share balances are recorded in the delegationManager as well.
     */
    function withdraw(address depositor, IERC20 token, uint256 amountShares) external;

    /**
     * @notice Used to convert a number of shares to the equivalent amount of underlying tokens for this strategy.
     * @notice In contrast to `sharesToUnderlyingView`, this function **may** make state modifications
     * @param amountShares is the amount of shares to calculate its conversion into the underlying token
     * @dev Implementation for these functions in particular may vary signifcantly for different strategies
     */
    function sharesToUnderlying(uint256 amountShares) external returns (uint256);

    /**
     * @notice Used to convert an amount of underlying tokens to the equivalent amount of shares in this ledger.
     * @notice In contrast to `underlyingToSharesView`, this function **may** make state modifications
     * @param amountUnderlying is the amount of `underlyingToken` to calculate its conversion into ledger shares
     * @dev Implementation for these functions in particular may vary signifcantly for different ledgers
     */
    function underlyingToShares(uint256 amountUnderlying) external view returns (uint256);

    /**
     * @notice convenience function for fetching the current underlying value of all of the `user`'s shares in
     * this ledger. In contrast to `userUnderlyingView`, this function **may** make state modifications
     */
    function userUnderlying(address user) external returns (uint256);

     /**
     * @notice Used to convert a number of shares to the equivalent amount of underlying tokens for this ledger.
     * @notice In contrast to `sharesToUnderlying`, this function guarantees no state modifications
     * @param amountShares is the amount of shares to calculate its conversion into the underlying token
     * @dev Implementation for these functions in particular may vary signifcantly for different ledgers
     */
    function sharesToUnderlyingView(uint256 amountShares) external view returns (uint256);

    /**
     * @notice Used to convert an amount of underlying tokens to the equivalent amount of shares in this ledger.
     * @notice In contrast to `underlyingToShares`, this function guarantees no state modifications
     * @param amountUnderlying is the amount of `underlyingToken` to calculate its conversion into ledger shares
     * @dev Implementation for these functions in particular may vary signifcantly for different ledgers
     */
    function underlyingToSharesView(uint256 amountUnderlying) external view returns (uint256);

    /**
     * @notice convenience function for fetching the current underlying value of all of the `user`'s shares in
     * this ledger. In contrast to `userUnderlying`, this function guarantees no state modifications
     */
    function userUnderlyingView(address user) external view returns (uint256);

    /// @notice The underyling token for shares in this DelegationShares
    function underlyingToken() external view returns (IERC20);

    /// @notice The total number of extant shares in thie InvestmentStrategy
    function totalShares() external view returns (uint256);

    /// @notice Returns either a brief string explaining the strategy's goal & purpose, or a link to metadata that explains in more detail.
    function explanation() external view returns (string memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./IDelegationShare.sol";
import "./IDelegationSlasher.sol";
import "./IDelegation.sol";

/**
 * @title Interface for the primary entrypoint for funds.
 * @author Layr Labs, Inc.
 * @notice See the `DelegationManager` contract itself for implementation details.
 */
interface IDelegationManager {
    // used for storing details of queued withdrawals
    struct WithdrawalStorage {
        uint32 initTimestamp;
        uint32 unlockTimestamp;
        address withdrawer;
    }

    // packed struct for queued withdrawals
    struct WithdrawerAndNonce {
        address withdrawer;
        uint96 nonce;
    }

    /**
     * Struct type used to specify an existing queued withdrawal. Rather than storing the entire struct, only a hash is stored.
     * In functions that operate on existing queued withdrawals -- e.g. `startQueuedWithdrawalWaitingPeriod` or `completeQueuedWithdrawal`,
     * the data is resubmitted and the hash of the submitted data is computed by `calculateWithdrawalRoot` and checked against the
     * stored hash in order to confirm the integrity of the submitted data.
     */
    struct QueuedWithdrawal {
        IDelegationShare[] delegations;
        IERC20[] tokens;
        uint256[] shares;
        address depositor;
        WithdrawerAndNonce withdrawerAndNonce;
        address delegatedAddress;
    }

    /**
     * @notice Deposits `amount` of `token` into the specified `DelegationShare`, with the resultant shares credited to `depositor`
     * @param delegationShare is the specified shares record where investment is to be made,
     * @param token is the ERC20 token in which the investment is to be made,
     * @param amount is the amount of token to be invested in the delegationShare by the depositor
     */
    function depositInto(IDelegationShare delegationShare, IERC20 token, uint256 amount)
        external
        returns (uint256);

    /// @notice Returns the current shares of `user` in `delegationShare`
    function investorDelegationShares(address user, IDelegationShare delegationShare) external view returns (uint256 shares);

    /**
     * @notice Get all details on the depositor's investments and corresponding shares
     * @return (depositor's delegationShare record, shares in these DelegationShare contract)
     */
    function getDeposits(address depositor) external view returns (IDelegationShare[] memory, uint256[] memory);

    /// @notice Simple getter function that returns `investorDelegations[staker].length`.
    function investorDelegationLength(address staker) external view returns (uint256);

    /**
     * @notice Called by a staker to queue a withdraw in the given token and shareAmount from each of the respective given strategies.
     * @dev Stakers will complete their withdrawal by calling the 'completeQueuedWithdrawal' function.
     * User shares are decreased in this function, but the total number of shares in each delegation strategy remains the same.
     * The total number of shares is decremented in the 'completeQueuedWithdrawal' function instead, which is where
     * the funds are actually sent to the user through use of the delegation strategies' 'withdrawal' function. This ensures
     * that the value per share reported by each strategy will remain consistent, and that the shares will continue
     * to accrue gains during the enforced WITHDRAWAL_WAITING_PERIOD.
     * @param delegationShareIndexes is a list of the indices in `investorDelegationShare[msg.sender]` that correspond to the delegation strategies
     * for which `msg.sender` is withdrawing 100% of their shares
     * @dev strategies are removed from `delegationShare` by swapping the last entry with the entry to be removed, then
     * popping off the last entry in `delegationShares`. The simplest way to calculate the correct `delegationShareIndexes` to input
     * is to order the strategies *for which `msg.sender` is withdrawing 100% of their shares* from highest index in
     * `delegationShares` to lowest index
     */
    function queueWithdrawal(
        uint256[] calldata delegationShareIndexes,
        IDelegationShare[] calldata delegationShares,
        IERC20[] calldata tokens,
        uint256[] calldata shareAmounts,
        WithdrawerAndNonce calldata withdrawerAndNonce,
        bool undelegateIfPossible
    )
        external returns(bytes32);

    function startQueuedWithdrawalWaitingPeriod(
        bytes32 withdrawalRoot,
        uint32 stakeInactiveAfter
    ) external;

    /**
     * @notice Used to complete the specified `queuedWithdrawal`. The function caller must match `queuedWithdrawal.withdrawer`
     * @param queuedWithdrawal The QueuedWithdrawal to complete.
     * @param receiveAsTokens If true, the shares specified in the queued withdrawal will be withdrawn from the specified delegation strategies themselves
     * and sent to the caller, through calls to `queuedWithdrawal.strategies[i].withdraw`. If false, then the shares in the specified delegation strategies
     * will simply be transferred to the caller directly.
     */
    function completeQueuedWithdrawal(
        QueuedWithdrawal calldata queuedWithdrawal,
        bool receiveAsTokens
    )
        external;

    /**
     * @notice Slashes the shares of 'frozen' operator (or a staker delegated to one)
     * @param slashedAddress is the frozen address that is having its shares slashes
     * @param delegationShareIndexes is a list of the indices in `investorStrats[msg.sender]` that correspond to the strategies
     * for which `msg.sender` is withdrawing 100% of their shares
     * @param recipient The slashed funds are withdrawn as tokens to this address.
     * @dev strategies are removed from `investorStrats` by swapping the last entry with the entry to be removed, then
     * popping off the last entry in `investorStrats`. The simplest way to calculate the correct `strategyIndexes` to input
     * is to order the strategies *for which `msg.sender` is withdrawing 100% of their shares* from highest index in
     * `investorStrats` to lowest index
     */
    function slashShares(
        address slashedAddress,
        address recipient,
        IDelegationShare[] calldata delegationShares,
        IERC20[] calldata tokens,
        uint256[] calldata delegationShareIndexes,
        uint256[] calldata shareAmounts
    )
        external;

    function slashQueuedWithdrawal(
        address recipient,
        QueuedWithdrawal calldata queuedWithdrawal
    )
        external;

    /**
     * @notice Used to check if a queued withdrawal can be completed. Returns 'true' if the withdrawal can be immediately
     * completed, and 'false' otherwise.
     * @dev This function will revert if the specified `queuedWithdrawal` does not exist
     */
    function canCompleteQueuedWithdrawal(
        QueuedWithdrawal calldata queuedWithdrawal
    )
        external
        returns (bool);

    /// @notice Returns the keccak256 hash of `queuedWithdrawal`.
    function calculateWithdrawalRoot(
        QueuedWithdrawal memory queuedWithdrawal
    )
        external
        pure
        returns (bytes32);

    /// @notice Returns the single, central Delegation contract
    function delegation() external view returns (IDelegation);

    /// @notice Returns the single, central DelegationSlasher contract
    function delegationSlasher() external view returns (IDelegationSlasher);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/**
 * @title Interface for the primary 'slashing' contract for EigenLayr.
 * @author Layr Labs, Inc.
 * @notice See the `Slasher` contract itself for implementation details.
 */
interface IDelegationSlasher {
    /**
     * @notice Gives the `contractAddress` permission to slash the funds of the caller.
     * @dev Typically, this function must be called prior to registering for a middleware.
     */
    function allowToSlash(address contractAddress) external;

    /// @notice Called by a contract to revoke its ability to slash `operator`, once `unbondedAfter` is reached.
    function revokeSlashingAbility(address operator, uint32 unbondedAfter) external;

    /**
     * @notice Used for 'slashing' a certain operator.
     * @param toBeFrozen The operator to be frozen.
     * @dev Technically the operator is 'frozen' (hence the name of this function), and then subject to slashing pending a decision by a human-in-the-loop.
     * @dev The operator must have previously given the caller (which should be a contract) the ability to slash them, through a call to `allowToSlash`.
     */
    function freezeOperator(address toBeFrozen) external;

    /**
     * @notice Used to determine whether `staker` is actively 'frozen'. If a staker is frozen, then they are potentially subject to
     * slashing of their funds, and cannot cannot deposit or withdraw from the investmentManager until the slashing process is completed
     * and the staker's status is reset (to 'unfrozen').
     * @return Returns 'true' if `staker` themselves has their status set to frozen, OR if the staker is delegated
     * to an operator who has their status set to frozen. Otherwise returns 'false'.
     */
    function isFrozen(address staker) external view returns (bool);

    /// @notice Returns true if `slashingContract` is currently allowed to slash `toBeSlashed`.
    function canSlash(address toBeSlashed, address slashingContract) external view returns (bool);

    /// @notice Returns the UTC timestamp until which `slashingContract` is allowed to slash the `operator`.
    function bondedUntil(address operator, address slashingContract) external view returns (uint32);

    /**
     * @notice Removes the 'frozen' status from each of the `frozenAddresses`
     * @dev Callable only by the contract owner (i.e. governance).
     */
    function resetFrozenStatus(address[] calldata frozenAddresses) external;

    /**
     * @notice Used to give global slashing permission to `contracts`.
     * @dev Callable only by the contract owner (i.e. governance).
     */
    function addGloballyPermissionedContracts(address[] calldata contracts) external;

    /**
     * @notice Used to revoke global slashing permission from `contracts`.
     * @dev Callable only by the contract owner (i.e. governance).
     */
    function removeGloballyPermissionedContracts(address[] calldata contracts) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

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
pragma solidity ^0.8.9;

import "./IDelegationShare.sol";

/**
 * @title Abstract interface for a contract that helps structure the delegation relationship.
 * @notice The gas budget provided to this contract in calls from contracts is limited.
 */
//TODO: discuss if we can structure the inputs of these functions better
interface IDelegationCallback {
    function payForService(IERC20 token, uint256 amount) external payable;

    function onDelegationReceived(
        address delegator,
        address operator,
        IDelegationShare[] memory delegationShares,
        uint256[] memory investorShares
    ) external;

    function onDelegationWithdrawn(
        address delegator,
        address operator,
        IDelegationShare[] memory delegationShares,
        uint256[] memory investorShares
    ) external;
}

// SPDX-License-Identifier: MIT

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "./interfaces/IDelegationManager.sol";

/**
 * @title Base implementation of `IDelegationShare` interface, designed to be inherited from by more complex strategies.
 * @author Layr Labs, Inc.
 * @notice Simple, basic, "do-nothing" DelegationShare that holds a single underlying token and returns it on withdrawals.
 * Implements minimal versions of the IDelegationShare functions, this contract is designed to be inherited by
 * more complex delegation contracts, which can then override its functions as necessary.
 */
abstract contract DelegationShareBase is Initializable, PausableUpgradeable, IDelegationShare {
    using SafeERC20 for IERC20;

    /// @notice DelegationManager contract
    IDelegationManager public delegationManager;

    /// @notice The underyling token for shares in this DelegationShare
    IERC20 public underlyingToken;

    /// @notice The total number of extant shares in the DelegationShare
    uint256 public totalShares;

    event Deposit(address depositor, address token, uint256 amount);

    event Withdraw(address depositor, address token, uint256 amount);

    /// @notice Simply checks that the `msg.sender` is the `DelegationManager`, which is an address stored immutably at construction.
    modifier onlyDelegationManager() {
        require(msg.sender == address(delegationManager), "DelegationShareBase.onlyDelegationManager");
        _;
    }

    /**
     * @notice Used to deposit tokens into this DelegationShare
     * @param token is the ERC20 token being deposited
     * @param amount is the amount of token being deposited
     * @dev This function is only callable by the DelegationManager contract. It is invoked inside of the delegationManager's
     * `depositIntoStrategy` function, and individual share balances are recorded in the delegationManager as well.
     * @return newShares is the number of new shares issued at the current exchange ratio.
     */
    function deposit(address depositor, IERC20 token, uint256 amount)
        external
        virtual
        override
        whenNotPaused
        onlyDelegationManager
        returns (uint256 newShares)
    {
        require(token == underlyingToken, "DelegationShareBase.deposit: Can only deposit underlyingToken");

        /**
         * @notice calculation of newShares *mirrors* `underlyingToShares(amount)`, but is different since the balance of `underlyingToken`
         * has already been increased due to the `delegationManager` transferring tokens to this delegation contract prior to calling this function
         */
        uint256 priorTokenBalance = _tokenBalance() - amount;
        if (priorTokenBalance == 0 || totalShares == 0) {
            newShares = amount;
        } else {
            newShares = (amount * totalShares) / priorTokenBalance;
        }

        totalShares += newShares;
        emit Deposit(depositor, address(token), amount);
        return newShares;
    }

    /**
     * @notice Used to withdraw tokens from this DelegationShare, to the `depositor`'s address
     * @param token is the ERC20 token being transferred out
     * @param amountShares is the amount of shares being withdrawn
     * @dev This function is only callable by the delegationManager contract. It is invoked inside of the delegationManager's
     * other functions, and individual share balances are recorded in the delegationManager as well.
     */
    function withdraw(address depositor, IERC20 token, uint256 amountShares)
        external
        virtual
        override
        whenNotPaused
        onlyDelegationManager
    {
        require(token == underlyingToken, "DelegationShareBase.withdraw: Can only withdraw the strategy token");
        require(
            amountShares <= totalShares,
            "DelegationShareBase.withdraw: amountShares must be less than or equal to totalShares"
        );
        // copy `totalShares` value prior to decrease
        uint256 priorTotalShares = totalShares;
        // Decrease `totalShares` to reflect withdrawal. Unchecked arithmetic since we just checked this above.
        unchecked {
            totalShares -= amountShares;
        }
        /**
         * @notice calculation of amountToSend *mirrors* `sharesToUnderlying(amountShares)`, but is different since the `totalShares` has already
         * been decremented
         */
        uint256 amountToSend;
        if (priorTotalShares == amountShares) {
            amountToSend = _tokenBalance();
        } else {
            amountToSend = (_tokenBalance() * amountShares) / priorTotalShares;
        }
        underlyingToken.safeTransfer(depositor, amountToSend);
        emit Withdraw(depositor, address(token), amountToSend);
    }

    /**
     * @notice Currently returns a brief string explaining the strategy's goal & purpose, but for more complex
     * strategies, may be a link to metadata that explains in more detail.
     */
    function explanation() external pure virtual override returns (string memory) {
        // return "Base DelegationShare implementation to inherit from for more complex implementations";
        return "Mantle token DelegationShare implementation for submodules as an example";
    }

    /**
     * @notice Used to convert a number of shares to the equivalent amount of underlying tokens for this strategy.
     * @notice In contrast to `sharesToUnderlying`, this function guarantees no state modifications
     * @param amountShares is the amount of shares to calculate its conversion into the underlying token
     * @dev Implementation for these functions in particular may vary signifcantly for different strategies
     */
    function sharesToUnderlyingView(uint256 amountShares) public view virtual override returns (uint256) {
        if (totalShares == 0) {
            return amountShares;
        } else {
            return (_tokenBalance() * amountShares) / totalShares;
        }
    }

    /**
     * @notice Used to convert a number of shares to the equivalent amount of underlying tokens for this strategy.
     * @notice In contrast to `sharesToUnderlyingView`, this function **may** make state modifications
     * @param amountShares is the amount of shares to calculate its conversion into the underlying token
     * @dev Implementation for these functions in particular may vary signifcantly for different strategies
     */
    function sharesToUnderlying(uint256 amountShares) public view virtual override returns (uint256) {
        return sharesToUnderlyingView(amountShares);
    }

    /**
     * @notice Used to convert an amount of underlying tokens to the equivalent amount of shares in this strategy.
     * @notice In contrast to `underlyingToShares`, this function guarantees no state modifications
     * @param amountUnderlying is the amount of `underlyingToken` to calculate its conversion into strategy shares
     * @dev Implementation for these functions in particular may vary signifcantly for different strategies
     */
    function underlyingToSharesView(uint256 amountUnderlying) public view virtual returns (uint256) {
        uint256 tokenBalance = _tokenBalance();
        if (tokenBalance == 0 || totalShares == 0) {
            return amountUnderlying;
        } else {
            return (amountUnderlying * totalShares) / tokenBalance;
        }
    }

    /**
     * @notice Used to convert an amount of underlying tokens to the equivalent amount of shares in this strategy.
     * @notice In contrast to `underlyingToSharesView`, this function **may** make state modifications
     * @param amountUnderlying is the amount of `underlyingToken` to calculate its conversion into strategy shares
     * @dev Implementation for these functions in particular may vary signifcantly for different strategies
     */
    function underlyingToShares(uint256 amountUnderlying) external view virtual returns (uint256) {
        return underlyingToSharesView(amountUnderlying);
    }

    /**
     * @notice convenience function for fetching the current underlying value of all of the `user`'s shares in
     * this strategy. In contrast to `userUnderlying`, this function guarantees no state modifications
     */
    function userUnderlyingView(address user) external view virtual returns (uint256) {
        return sharesToUnderlyingView(shares(user));
    }

    /**
     * @notice convenience function for fetching the current underlying value of all of the `user`'s shares in
     * this strategy. In contrast to `userUnderlyingView`, this function **may** make state modifications
     */
    function userUnderlying(address user) external virtual returns (uint256) {
        return sharesToUnderlying(shares(user));
    }

    /**
     * @notice convenience function for fetching the current total shares of `user` in this strategy, by
     * querying the `delegationManager` contract
     */
    function shares(address user) public view virtual returns (uint256) {
        return IDelegationManager(delegationManager).investorDelegationShares(user, IDelegationShare(address(this)));
    }

    /// @notice Internal function used to fetch this contract's current balance of `underlyingToken`.
    // slither-disable-next-line dead-code
    function _tokenBalance() internal view virtual returns (uint256) {
        return underlyingToken.balanceOf(address(this));
    }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IDelegationCallback.sol";
import "./interfaces/IDelegation.sol";

/**
 * @title Base implementation of `IInvestmentStrategy` interface, designed to be inherited from by more complex strategies.
 * @notice Simple, basic, "do-nothing" InvestmentStrategy that holds a single underlying token and returns it on withdrawals.
 * Implements minimal versions of the IInvestmentStrategy functions, this contract is designed to be inherited by
 * more complex investment strategies, which can then override its functions as necessary.
 */
abstract contract DelegationCallbackBase is Initializable, PausableUpgradeable, IDelegationCallback {
    /// @notice DelegationManager contract
    IDelegation public delegation;

    /// @notice Simply checks that the `msg.sender` is the `DelegationManager`, which is an address stored immutably at construction.
    modifier onlyDelegation() {
        require(msg.sender == address(delegation), "DelegationShareBase.onlyDelegationManager");
        _;
    }

    function payForService(IERC20 token, uint256 amount) external payable {}

    function onDelegationWithdrawn(
        address delegator,
        IDelegationShare[] memory investorDelegationShares,
        uint256[] memory investorShares
    ) external {}

    function onDelegationReceived(
        address delegator,
        IDelegationShare[] memory investorDelegationShares,
        uint256[] memory investorShares
    ) external {}
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.9.0;

/* Interface Imports */
import { ICrossDomainMessenger } from "./ICrossDomainMessenger.sol";

/**
 * @title CrossDomainEnabled
 * @dev Helper contract for contracts performing cross-domain communications
 *
 * Compiler used: defined by inheriting contract
 */
contract CrossDomainEnabled {
    /*************
     * Variables *
     *************/

    // Messenger contract used to send and recieve messages from the other domain.
    address public messenger;

    /***************
     * Constructor *
     ***************/

    /**
     * @param _messenger Address of the CrossDomainMessenger on the current layer.
     */
    constructor(address _messenger) {
        messenger = _messenger;
    }

    /**********************
     * Function Modifiers *
     **********************/

    /**
     * Enforces that the modified function is only callable by a specific cross-domain account.
     * @param _sourceDomainAccount The only account on the originating domain which is
     *  authenticated to call this function.
     */
    modifier onlyFromCrossDomainAccount(address _sourceDomainAccount) {
        require(
            msg.sender == address(getCrossDomainMessenger()),
            "BVM_XCHAIN: messenger contract unauthenticated"
        );

        require(
            getCrossDomainMessenger().xDomainMessageSender() == _sourceDomainAccount,
            "BVM_XCHAIN: wrong sender of cross-domain message"
        );

        _;
    }

    /**********************
     * Internal Functions *
     **********************/

    /**
     * Gets the messenger, usually from storage. This function is exposed in case a child contract
     * needs to override.
     * @return The address of the cross-domain messenger contract which should be used.
     */
    function getCrossDomainMessenger() internal virtual returns (ICrossDomainMessenger) {
        return ICrossDomainMessenger(messenger);
    }

    /**q
     * Sends a message to an account on another domain
     * @param _crossDomainTarget The intended recipient on the destination domain
     * @param _message The data to send to the target (usually calldata to a function with
     *  `onlyFromCrossDomainAccount()`)
     * @param _gasLimit The gasLimit for the receipt of the message on the target domain.
     */
    function sendCrossDomainMessage(
        address _crossDomainTarget,
        uint32 _gasLimit,
        bytes memory _message
    ) internal {
        // slither-disable-next-line reentrancy-events, reentrancy-benign
        getCrossDomainMessenger().sendMessage(_crossDomainTarget, _message, _gasLimit);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title ITssRewardContract
 */

interface ITssRewardContract {
    /**********
     * Events *
     **********/

    event DistributeTssReward(
        uint256 lastBatchTime,
        uint256 batchTime,
        uint256 amount,
        address[] tssMembers
    );

    event DistributeTssRewardByBlock(
        uint256   blockStartHeight,
        uint32     length,
        uint256    amount,
        address[] tssMembers
    );

    event Claim(
        address owner,
        uint256 amount
    );

    /********************
     * Public Functions *
     ********************/

    /**
     * @dev Query total undistributed balance.
     * @return Amount of undistributed rewards.
     */
    function queryReward() external view returns (uint256);

    /**
     * @dev Auto distribute reward to tss members.
     * @param _blockStartHeight L2 rollup batch block start height.
     * @param _length Rollup batch length.
     * @param _tssMembers Tss member address array.
     */
    function claimReward(uint256 _blockStartHeight, uint32 _length, uint256 _batchTime, address[] calldata _tssMembers) external;

    /**
     * @dev clear contract(canonical).
     */
    function withdraw() external;

    /**
     * @dev Claim reward and withdraw
     */
    function claim() external;

    /**
     * @dev default claimer == staker, if staker is multi-signature address,must set claimer
     * @param _staker the address of staker
     * @param _claimer the address for staker to claim reward
     */
    function setClaimer(address _staker, address _claimer) external;

    /**
     * @dev Initiate a request to claim
     */
    function requestClaim() external returns (bool);

    /**
     * @dev Query the remaining time required to claim
     */
    function queryClaimTime() external returns (uint256);

    function setSccAddr(address sccAddr) external;

    function setStakeSlashAddr(address ssAddr) external;

    function setSendAmountPerYear(uint256) external;

    function setWaitingTime(uint256) external;

}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.9.0;

interface IStakingSlashing {

    // tx
    function setTokenAddress(address) external;
    function setTssGroupAddress(address) external;
    function setRegulatoryAccount(address) external;
    function setClaimer(address, address) external;
    function setSlashingParams(uint256[2] calldata) external;
    function setPublicKey(bytes calldata) external;
    function quitRequest() external;
    function clearQuitRequestList() external;
    function slashing(bytes calldata, bytes calldata) external;
    function unJail() external;

    // query
    function getSlashingParams() external view returns (uint256[2] memory);
    function getQuitRequestList() external view returns (address[] memory);
    function getSlashRecord(uint256, address) external view returns (bool);
    function isJailed(address) external returns (bool);
    function isCanOperator(address) external returns (bool);

    //fund
    function deposit(uint256 amount) external returns (uint256);
    function withdraw() external;
    function completeWithdraw() external;
    function startWithdraw() external;
    function canCompleteQueuedWithdrawal() external returns (bool);

    //delegation
    function registerAsOperator(bytes calldata) external;
    function delegateTo(address) external;




}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../../delegation/Delegation.sol";
import "../../delegation/WhiteListBase.sol";


/**
 * @title The primary delegation contract.
 * @notice  This is the contract for delegation. The main functionalities of this contract are
 * - for enabling any staker to register as a delegate and specify the delegation terms it has agreed to
 * - for enabling anyone to register as an operator
 * - for a registered staker to delegate its stake to the operator of its agreed upon delegation terms contract
 * - for a staker to undelegate its assets
 * - for anyone to challenge a staker's claim to have fulfilled all its obligation before undelegation
 */
contract TssDelegation is Delegation {


    address public stakingSlash;




    // INITIALIZING FUNCTIONS
    constructor(IDelegationManager _delegationManager)
    Delegation(_delegationManager)
    {
        _disableInitializers();
    }


    function initializeT(
        address _stakingSlashing,
        address initialOwner
    ) external initializer {
        DOMAIN_SEPARATOR = keccak256(abi.encode(DOMAIN_TYPEHASH, bytes("Mantle"), block.chainid, address(this)));
        stakingSlash = _stakingSlashing;
         _transferOwnership(initialOwner);
    }

    modifier onlyStakingSlash() {
        require(msg.sender == stakingSlash, "contract call is not staking slashing");
        _;
    }

    function setStakingSlash(address _address) public onlyOwner {
        stakingSlash = _address;
    }

    function registerAsOperator(IDelegationCallback dt, address sender) external whitelistOnly(sender) onlyStakingSlash {

        require(
            address(delegationCallback[sender]) == address(0),
            "Delegation.registerAsOperator: Delegate has already registered"
        );
        // store the address of the delegation contract that the operator is providing.
        delegationCallback[sender] = dt;
        _delegate(sender, sender);
        emit RegisterOperator(address(dt), sender);
    }

    function delegateTo(address operator, address staker) external onlyStakingSlash whenNotPaused {
        _delegate(staker, operator);
    }


}

// SPDX-License-Identifier: MIT

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
pragma solidity >0.5.0 <0.9.0;

/**
 * @title ICrossDomainMessenger
 */
interface ICrossDomainMessenger {
    /**********
     * Events *
     **********/

    event SentMessage(
        address indexed target,
        address sender,
        bytes message,
        uint256 messageNonce,
        uint256 gasLimit
    );
    event RelayedMessage(bytes32 indexed msgHash);
    event FailedRelayedMessage(bytes32 indexed msgHash);

    /*************
     * Variables *
     *************/

    function xDomainMessageSender() external view returns (address);

    /********************
     * Public Functions *
     ********************/

    /**
     * Sends a cross domain message to the target messenger.
     * @param _target Target contract address.
     * @param _message Message to send to the target.
     * @param _gasLimit Gas limit for the provided message.
     */
    function sendMessage(
        address _target,
        bytes calldata _message,
        uint32 _gasLimit
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "./DelegationStorage.sol";
import "./DelegationSlasher.sol";
import "./WhiteListBase.sol";
/**
 * @title The primary delegation contract.
 * @notice  This is the contract for delegation. The main functionalities of this contract are
 * - for enabling any staker to register as a delegate and specify the delegation terms it has agreed to
 * - for enabling anyone to register as an operator
 * - for a registered staker to delegate its stake to the operator of its agreed upon delegation terms contract
 * - for a staker to undelegate its assets
 * - for anyone to challenge a staker's claim to have fulfilled all its obligation before undelegation
 */
abstract contract Delegation is Initializable, OwnableUpgradeable, PausableUpgradeable, WhiteList, DelegationStorage {
    /// @notice Simple permission for functions that are only callable by the InvestmentManager contract.
    modifier onlyDelegationManager() {
        require(msg.sender == address(delegationManager), "onlyDelegationManager");
        _;
    }

    // INITIALIZING FUNCTIONS
    constructor(IDelegationManager _delegationManager)
        DelegationStorage(_delegationManager)
    {
        _disableInitializers();
    }

    /// @dev Emitted when a low-level call to `delegationTerms.onDelegationReceived` fails, returning `returnData`
    event OnDelegationReceivedCallFailure(IDelegationCallback indexed delegationTerms, bytes32 returnData);

    /// @dev Emitted when a low-level call to `delegationTerms.onDelegationWithdrawn` fails, returning `returnData`
    event OnDelegationWithdrawnCallFailure(IDelegationCallback indexed delegationTerms, bytes32 returnData);

    event RegisterOperator(address delegationCallback, address register);

    event DelegateTo(address delegatior, address operator);

    event DecreaseDelegatedShares(address delegatedShare, address operator, uint256 share);

    event IncreaseDelegatedShares(address delegatedShare, address operator, uint256 share);

    function initialize(address initialOwner)
        external
        initializer
    {
        DOMAIN_SEPARATOR = keccak256(abi.encode(DOMAIN_TYPEHASH, bytes("Mantle"), block.chainid, address(this)));
        _transferOwnership(initialOwner);
    }

    // PERMISSION FUNCTIONS
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // EXTERNAL FUNCTIONS
    /**
     * @notice This will be called by an operator to register itself as an operator that stakers can choose to delegate to.
     * @param dt is the `DelegationTerms` contract that the operator has for those who delegate to them.
     * @dev An operator can set `dt` equal to their own address (or another EOA address), in the event that they want to split payments
     * in a more 'trustful' manner.
     * @dev In the present design, once set, there is no way for an operator to ever modify the address of their DelegationTerms contract.
     */
    function registerAsOperator(IDelegationCallback dt) external whitelistOnly(msg.sender) {
        require(
            address(delegationCallback[msg.sender]) == address(0),
            "Delegation.registerAsOperator: Delegate has already registered"
        );
        // store the address of the delegation contract that the operator is providing.
        delegationCallback[msg.sender] = dt;
        _delegate(msg.sender, msg.sender);
        emit RegisterOperator(address(dt),msg.sender);
    }

    /**
     *  @notice This will be called by a staker to delegate its assets to some operator.
     *  @param operator is the operator to whom staker (msg.sender) is delegating its assets
     */
    function delegateTo(address operator) external whenNotPaused {
        _delegate(msg.sender, operator);
    }

    /**
     * @notice Delegates from `staker` to `operator`.
     * @dev requires that r, vs are a valid ECSDA signature from `staker` indicating their intention for this action
     */
    function delegateToSignature(address staker, address operator, uint256 expiry, bytes32 r, bytes32 vs)
        external
        whenNotPaused
    {
        require(expiry == 0 || expiry >= block.timestamp, "delegation signature expired");
        // calculate struct hash, then increment `staker`'s nonce
        // EIP-712 standard
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, staker, operator, nonces[staker]++, expiry));
        bytes32 digestHash = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash));
        //check validity of signature

        address recoveredAddress = ECDSA.recover(digestHash, r, vs);

        require(recoveredAddress == staker, "Delegation.delegateToBySignature: sig not from staker");
        _delegate(staker, operator);
    }

    /**
     * @notice Undelegates `staker` from the operator who they are delegated to.
     * @notice Callable only by the InvestmentManager
     * @dev Should only ever be called in the event that the `staker` has no active deposits.
     */
    function undelegate(address staker) external onlyDelegationManager {
        delegationStatus[staker] = DelegationStatus.UNDELEGATED;
        delegatedTo[staker] = address(0);
    }

    /**
     * @notice Increases the `staker`'s delegated shares in `strategy` by `shares, typically called when the staker has further deposits
     * @dev Callable only by the InvestmentManager
     */
    function increaseDelegatedShares(address staker, IDelegationShare delegationShare, uint256 shares)
        external
        onlyDelegationManager
    {
        //if the staker is delegated to an operator
        if (isDelegated(staker)) {
            address operator = delegatedTo[staker];

            // add strategy shares to delegate's shares
            operatorShares[operator][delegationShare] += shares;

            //Calls into operator's delegationTerms contract to update weights of individual staker
            IDelegationShare[] memory investorDelegations = new IDelegationShare[](1);
            uint256[] memory investorShares = new uint[](1);
            investorDelegations[0] = delegationShare;
            investorShares[0] = shares;

            // call into hook in delegationCallback contract
            IDelegationCallback dt = delegationCallback[operator];
            _delegationReceivedHook(dt, staker, operator, investorDelegations, investorShares);
            emit IncreaseDelegatedShares(address(delegationShare), operator, shares);
        }
    }

    /**
     * @notice Decreases the `staker`'s delegated shares in `strategy` by `shares, typically called when the staker withdraws
     * @dev Callable only by the InvestmentManager
     */
    function decreaseDelegatedShares(address staker, IDelegationShare delegationShare, uint256 shares)
        external
        onlyDelegationManager
    {
        //if the staker is delegated to an operator
        if (isDelegated(staker)) {
            address operator = delegatedTo[staker];

            // subtract strategy shares from delegate's shares
            operatorShares[operator][delegationShare] -= shares;

            //Calls into operator's delegationCallback contract to update weights of individual staker
            IDelegationShare[] memory investorDelegationShares = new IDelegationShare[](1);
            uint256[] memory investorShares = new uint[](1);
            investorDelegationShares[0] = delegationShare;
            investorShares[0] = shares;

            // call into hook in delegationCallback contract
            IDelegationCallback dt = delegationCallback[operator];
            _delegationWithdrawnHook(dt, staker, operator, investorDelegationShares, investorShares);
            emit DecreaseDelegatedShares(address(delegationShare), operator, shares);
        }
    }

    /// @notice Version of `decreaseDelegatedShares` that accepts an array of inputs.
    function decreaseDelegatedShares(
        address staker,
        IDelegationShare[] calldata strategies,
        uint256[] calldata shares
    )
        external
        onlyDelegationManager
    {
        if (isDelegated(staker)) {
            address operator = delegatedTo[staker];

            // subtract strategy shares from delegate's shares
            uint256 stratsLength = strategies.length;
            for (uint256 i = 0; i < stratsLength;) {
                operatorShares[operator][strategies[i]] -= shares[i];
                emit DecreaseDelegatedShares(address(strategies[i]), operator, shares[i]);
                unchecked {
                    ++i;
                }
            }

            // call into hook in delegationCallback contract
            IDelegationCallback dt = delegationCallback[operator];
            _delegationWithdrawnHook(dt, staker, operator, strategies, shares);
        }
    }

    // INTERNAL FUNCTIONS

    /**
     * @notice Makes a low-level call to `dt.onDelegationReceived(staker, strategies, shares)`, ignoring reverts and with a gas budget
     * equal to `LOW_LEVEL_GAS_BUDGET` (a constant defined in this contract).
     * @dev *If* the low-level call fails, then this function emits the event `OnDelegationReceivedCallFailure(dt, returnData)`, where
     * `returnData` is *only the first 32 bytes* returned by the call to `dt`.
     */
    function _delegationReceivedHook(
        IDelegationCallback dt,
        address staker,
        address operator,
        IDelegationShare[] memory delegationShares,
        uint256[] memory shares
    )
        internal
    {
        /**
         * We use low-level call functionality here to ensure that an operator cannot maliciously make this function fail in order to prevent undelegation.
         * In particular, in-line assembly is also used to prevent the copying of uncapped return data which is also a potential DoS vector.
         */
        // format calldata
        (bool success, bytes memory returnData) = address(dt).call{gas: LOW_LEVEL_GAS_BUDGET}(
            abi.encodeWithSelector(IDelegationCallback.onDelegationReceived.selector, staker, operator, delegationShares, shares)
        );

        // if the call fails, we emit a special event rather than reverting
        if (!success) {
            emit OnDelegationReceivedCallFailure(dt, returnData[0]);
        }
    }

    /**
     * @notice Makes a low-level call to `dt.onDelegationWithdrawn(staker, strategies, shares)`, ignoring reverts and with a gas budget
     * equal to `LOW_LEVEL_GAS_BUDGET` (a constant defined in this contract).
     * @dev *If* the low-level call fails, then this function emits the event `OnDelegationReceivedCallFailure(dt, returnData)`, where
     * `returnData` is *only the first 32 bytes* returned by the call to `dt`.
     */
    function _delegationWithdrawnHook(
        IDelegationCallback dt,
        address staker,
        address operator,
        IDelegationShare[] memory delegationShares,
        uint256[] memory shares
    )
        internal
    {
        /**
         * We use low-level call functionality here to ensure that an operator cannot maliciously make this function fail in order to prevent undelegation.
         * In particular, in-line assembly is also used to prevent the copying of uncapped return data which is also a potential DoS vector.
         */

        (bool success, bytes memory returnData) = address(dt).call{gas: LOW_LEVEL_GAS_BUDGET}(
            abi.encodeWithSelector(IDelegationCallback.onDelegationWithdrawn.selector, staker, operator, delegationShares, shares)
        );

        // if the call fails, we emit a special event rather than reverting
        if (!success) {
            emit OnDelegationWithdrawnCallFailure(dt, returnData[0]);
        }
    }

    /**
     * @notice Internal function implementing the delegation *from* `staker` *to* `operator`.
     * @param staker The address to delegate *from* -- this address is delegating control of its own assets.
     * @param operator The address to delegate *to* -- this address is being given power to place the `staker`'s assets at risk on services
     * @dev Ensures that the operator has registered as a delegate (`address(dt) != address(0)`), verifies that `staker` is not already
     * delegated, and records the new delegation.
     */
    function _delegate(address staker, address operator) internal {

        IDelegationCallback dt = delegationCallback[operator];
        require(
            address(dt) != address(0), "Delegation._delegate: operator has not yet registered as a delegate"
        );
        require(isNotDelegated(staker), "Delegation._delegate: staker has existing delegation");

        // checks that operator has not been frozen
        IDelegationSlasher slasher = delegationManager.delegationSlasher();
        require(!slasher.isFrozen(operator), "Delegation._delegate: cannot delegate to a frozen operator");
        // record delegation relation between the staker and operator
        delegatedTo[staker] = operator;

        // record that the staker is delegated
        delegationStatus[staker] = DelegationStatus.DELEGATED;
        // retrieve list of strategies and their shares from investment manager
        (IDelegationShare[] memory delegationShares, uint256[] memory shares) = delegationManager.getDeposits(staker);

        // add strategy shares to delegate's shares
        uint256 delegationLength = delegationShares.length;
        for (uint256 i = 0; i < delegationLength;) {
            // update the share amounts for each of the operator's strategies
            operatorShares[operator][delegationShares[i]] += shares[i];
            unchecked {
                ++i;
            }
        }
        // call into hook in delegationCallback contract
        _delegationReceivedHook(dt, staker, operator, delegationShares, shares);
        emit DelegateTo(staker, operator);
    }

    // VIEW FUNCTIONS

    /// @notice Returns 'true' if `staker` *is* actively delegated, and 'false' otherwise.
    function isDelegated(address staker) public view returns (bool) {
        return (delegationStatus[staker] == DelegationStatus.DELEGATED);
    }

    /// @notice Returns 'true' if `staker` is *not* actively delegated, and 'false' otherwise.
    function isNotDelegated(address staker) public view returns (bool) {
        return (delegationStatus[staker] == DelegationStatus.UNDELEGATED);
    }

    /// @notice Returns if an operator can be delegated to, i.e. it has called `registerAsOperator`.
    function isOperator(address operator) external view returns (bool) {
        return (address(delegationCallback[operator]) != address(0));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "./interfaces/IDelegationSlasher.sol";
import "./interfaces/IDelegation.sol";
import "./interfaces/IDelegationManager.sol";

/**
 * @title The primary 'slashing' contract.
 * @notice This contract specifies details on slashing. The functionalities are:
 * - adding contracts who have permission to perform slashing,
 * - revoking permission for slashing from specified contracts,
 * - calling investManager to do actual slashing.
 */
abstract contract DelegationSlasher is Initializable, OwnableUpgradeable, PausableUpgradeable, IDelegationSlasher {
    // ,DSTest
    /// @notice The central InvestmentManager contract
    IDelegationManager public immutable investmentManager;
    /// @notice The Delegation contract
    IDelegation public immutable delegation;
    // contract address => whether or not the contract is allowed to slash any staker (or operator)
    mapping(address => bool) public globallyPermissionedContracts;
    // user => contract => the time before which the contract is allowed to slash the user
    mapping(address => mapping(address => uint32)) public bondedUntil;
    // staker => if their funds are 'frozen' and potentially subject to slashing or not
    mapping(address => bool) internal frozenStatus;

    uint32 internal constant MAX_BONDED_UNTIL = type(uint32).max;

    event GloballyPermissionedContractAdded(address indexed contractAdded);
    event GloballyPermissionedContractRemoved(address indexed contractRemoved);
    event OptedIntoSlashing(address indexed operator, address indexed contractAddress);
    event SlashingAbilityRevoked(address indexed operator, address indexed contractAddress, uint32 unbondedAfter);
    event OperatorSlashed(address indexed slashedOperator, address indexed slashingContract);
    event FrozenStatusReset(address indexed previouslySlashedAddress);

    constructor(IDelegationManager _investmentManager, IDelegation _delegation) {
        investmentManager = _investmentManager;
        delegation = _delegation;
        _disableInitializers();
    }

    // EXTERNAL FUNCTIONS
    function initialize(
        address initialOwner
    ) external initializer {
        _transferOwnership(initialOwner);
        // add InvestmentManager & Delegation to list of permissioned contracts
        _addGloballyPermissionedContract(address(investmentManager));
        _addGloballyPermissionedContract(address(delegation));
    }

    /**
     * @notice Gives the `contractAddress` permission to slash the funds of the caller.
     * @dev Typically, this function must be called prior to registering for a middleware.
     */
    function allowToSlash(address contractAddress) external {
        _optIntoSlashing(msg.sender, contractAddress);
    }

    /*
     TODO: we still need to figure out how/when to appropriately call this function
     perhaps a registry can safely call this function after an operator has been deregistered for a very safe amount of time (like a month)
    */
    /// @notice Called by a contract to revoke its ability to slash `operator`, once `unbondedAfter` is reached.
    function revokeSlashingAbility(address operator, uint32 unbondedAfter) external {
        _revokeSlashingAbility(operator, msg.sender, unbondedAfter);
    }

    /**
     * @notice Used for 'slashing' a certain operator.
     * @param toBeFrozen The operator to be frozen.
     * @dev Technically the operator is 'frozen' (hence the name of this function), and then subject to slashing pending a decision by a human-in-the-loop.
     * @dev The operator must have previously given the caller (which should be a contract) the ability to slash them, through a call to `allowToSlash`.
     */
    function freezeOperator(address toBeFrozen) external whenNotPaused {
        require(
            canSlash(toBeFrozen, msg.sender),
            "Slasher.freezeOperator: msg.sender does not have permission to slash this operator"
        );
        _freezeOperator(toBeFrozen, msg.sender);
    }

    /**
     * @notice Used to give global slashing permission to `contracts`.
     * @dev Callable only by the contract owner (i.e. governance).
     */
    function addGloballyPermissionedContracts(address[] calldata contracts) external onlyOwner {
        for (uint256 i = 0; i < contracts.length;) {
            _addGloballyPermissionedContract(contracts[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Used to revoke global slashing permission from `contracts`.
     * @dev Callable only by the contract owner (i.e. governance).
     */
    function removeGloballyPermissionedContracts(address[] calldata contracts) external onlyOwner {
        for (uint256 i = 0; i < contracts.length;) {
            _removeGloballyPermissionedContract(contracts[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Removes the 'frozen' status from each of the `frozenAddresses`
     * @dev Callable only by the contract owner (i.e. governance).
     */
    function resetFrozenStatus(address[] calldata frozenAddresses) external onlyOwner {
        for (uint256 i = 0; i < frozenAddresses.length;) {
            _resetFrozenStatus(frozenAddresses[i]);
            unchecked {
                ++i;
            }
        }
    }

    // INTERNAL FUNCTIONS
    function _optIntoSlashing(address operator, address contractAddress) internal {
        //allow the contract to slash anytime before a time VERY far in the future
        bondedUntil[operator][contractAddress] = MAX_BONDED_UNTIL;
        emit OptedIntoSlashing(operator, contractAddress);
    }

    function _revokeSlashingAbility(address operator, address contractAddress, uint32 unbondedAfter) internal {
        if (bondedUntil[operator][contractAddress] == MAX_BONDED_UNTIL) {
            //contractAddress can now only slash operator before unbondedAfter
            bondedUntil[operator][contractAddress] = unbondedAfter;
            emit SlashingAbilityRevoked(operator, contractAddress, unbondedAfter);
        }
    }

    function _addGloballyPermissionedContract(address contractToAdd) internal {
        if (!globallyPermissionedContracts[contractToAdd]) {
            globallyPermissionedContracts[contractToAdd] = true;
            emit GloballyPermissionedContractAdded(contractToAdd);
        }
    }

    function _removeGloballyPermissionedContract(address contractToRemove) internal {
        if (globallyPermissionedContracts[contractToRemove]) {
            globallyPermissionedContracts[contractToRemove] = false;
            emit GloballyPermissionedContractRemoved(contractToRemove);
        }
    }

    function _freezeOperator(address toBeFrozen, address slashingContract) internal {
        if (!frozenStatus[toBeFrozen]) {
            frozenStatus[toBeFrozen] = true;
            emit OperatorSlashed(toBeFrozen, slashingContract);
        }
    }

    function _resetFrozenStatus(address previouslySlashedAddress) internal {
        if (frozenStatus[previouslySlashedAddress]) {
            frozenStatus[previouslySlashedAddress] = false;
            emit FrozenStatusReset(previouslySlashedAddress);
        }
    }

    // VIEW FUNCTIONS
    /**
     * @notice Used to determine whether `staker` is actively 'frozen'. If a staker is frozen, then they are potentially subject to
     * slashing of their funds, and cannot cannot deposit or withdraw from the investmentManager until the slashing process is completed
     * and the staker's status is reset (to 'unfrozen').
     * @return Returns 'true' if `staker` themselves has their status set to frozen, OR if the staker is delegated
     * to an operator who has their status set to frozen. Otherwise returns 'false'.
     */
    function isFrozen(address staker) external view returns (bool) {
        if (frozenStatus[staker]) {
            return true;
        } else if (delegation.isDelegated(staker)) {
            address operatorAddress = delegation.delegatedTo(staker);
            return (frozenStatus[operatorAddress]);
        } else {
            return false;
        }
    }

    /// @notice Returns true if `slashingContract` is currently allowed to slash `toBeSlashed`.
    function canSlash(address toBeSlashed, address slashingContract) public view returns (bool) {
        if (globallyPermissionedContracts[slashingContract]) {
            return true;
        } else if (block.timestamp < bondedUntil[toBeSlashed][slashingContract]) {
            return true;
        } else {
            return false;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./interfaces/IDelegationManager.sol";
import "./interfaces/IDelegationCallback.sol";
import "./interfaces/IDelegation.sol";

/**
 * @title Storage variables for the `Delegation` contract.
 * @author Layr Labs, Inc.
 * @notice This storage contract is separate from the logic to simplify the upgrade process.
 */
abstract contract DelegationStorage is IDelegation {
    /// @notice Gas budget provided in calls to DelegationTerms contracts
    uint256 internal constant LOW_LEVEL_GAS_BUDGET = 1e5;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH =
        keccak256("Delegation(address delegator,address operator,uint256 nonce,uint256 expiry)");

    /// @notice EIP-712 Domain separator
    bytes32 public DOMAIN_SEPARATOR;

    /// @notice The InvestmentManager contract
    IDelegationManager public immutable delegationManager;

    // operator => investment strategy => total number of shares delegated to them
    mapping(address => mapping(IDelegationShare => uint256)) public operatorShares;

    // operator => delegation terms contract
    mapping(address => IDelegationCallback) public delegationCallback;

    // staker => operator
    mapping(address => address) public delegatedTo;

    // staker => whether they are delegated or not
    mapping(address => IDelegation.DelegationStatus) public delegationStatus;

    // delegator => number of signed delegation nonce (used in delegateToBySignature)
    mapping(address => uint256) public nonces;

    constructor(IDelegationManager _investmentManager) {
        delegationManager = _investmentManager;
    }
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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