// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

// extends
import "./interfaces/IController.sol";
import "./shared/SpoolOwnable.sol";
import "./shared/Constants.sol";

// libraries
import "./external/@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "./libraries/Hash.sol";

// other imports
import "./interfaces/ISpool.sol";
import "./interfaces/IRiskProviderRegistry.sol";
import "./interfaces/IBaseStrategy.sol";
import "./interfaces/IVault.sol";
import "./interfaces/vault/IVaultDetails.sol";
import "./vault/VaultNonUpgradableProxy.sol";
import "./external/@openzeppelin/security/Pausable.sol";

/**
 * @notice Implementation of the {IController} interface.
 *
 * @dev
 * This implementation joins the various contracts of the Spool
 * system together to allow the creation of new vaults in the system
 * as well as allow the Spool to validate that its incoming requests
 * are indeed from a vault in the system.
 *
 * The contract can be thought of as the central point of contract
 * for assessing the validity of data in the system (i.e. supported strategy, vault etc.).
 */
contract Controller is IController, SpoolOwnable, BaseConstants, Pausable {
    using SafeERC20 for IERC20;

    /* ========== CONSTANTS ========== */

    /// @notice Maximum vault creator fee - 20%
    uint256 public constant MAX_VAULT_CREATOR_FEE = 20_00;

    /// @notice Maximum vault creator fee if the creator is the Spool DAO - 60%
    uint256 public constant MAX_DAO_VAULT_CREATOR_FEE = 60_00;

    /// @notice Maximum number of vault strategies
    uint256 public constant MAX_VAULT_STRATEGIES = 18;

    /// @notice Minimum vault risk tolerance
    int8 public constant MIN_RISK_TOLERANCE = -10;

    /// @notice Maximum vault risk tolerance
    int8 public constant MAX_RISK_TOLERANCE = 10;

    /* ========== STATE VARIABLES ========== */

    /// @notice The central Spool contract
    ISpool public immutable spool;
    
    /// @notice The risk provider registry
    IRiskProviderRegistry public immutable riskRegistry;

    /// @notice vault implementation address
    address public immutable vaultImplementation;

    /// @notice The list of strategies supported by the system
    address[] public override strategies;

    /// @notice Hash of strategies list
    bytes32 public strategiesHash;

    /// @notice The total vaults created in the system
    uint256 public totalVaults;
    
    /// @notice Recipient address of emergency withdrawn funds
    address public emergencyRecipient;

    /// @notice Whether the specified token is supported as an underlying token for a vault
    mapping(IERC20 => bool) public override supportedUnderlying;

    /// @notice Whether the particular vault address is valid
    mapping(address => bool) public override validVault;

    /// @notice Whether the particular strategy address is valid
    mapping(address => bool) public override validStrategy;

    /// @notice Whether the address is the emergency withdrawer
    mapping(address => bool) public isEmergencyWithdrawer;

    /// @notice Whether the address is the pauser
    mapping(address => bool) public isPauser;

    /// @notice Whether the address is the unpauser
    mapping(address => bool) public isUnpauser;

    /**
     * @notice Sets the contract initial values.
     *
     * @dev It performms certain pre-conditional validations to ensure the contract
     * has been initialized properly, such as that both addresses are valid.
     *
     * Ownership of the contract beyond deployment should be transferred to
     * the Spool DAO to avoid centralization of control.
     * 
     * @param _spoolOwner the spool owner contract that owns this contract
     * @param _riskRegistry the risk provider registry contract
     * @param _spool the spool contract
     * @param _vaultImplementation vault implementation contract address
     */
    constructor(
        ISpoolOwner _spoolOwner,
        IRiskProviderRegistry _riskRegistry,
        ISpool _spool,
        address _vaultImplementation
    ) 
        SpoolOwnable(_spoolOwner)
    {
        require(
            _riskRegistry != IRiskProviderRegistry(address(0)) &&
            _spool != ISpool(address(0)) &&
            _vaultImplementation != address(0),
            "Controller::constructor: Risk Provider, Spool or Vault Implementation addresses cannot be 0"
        );

        riskRegistry = _riskRegistry;
        spool = _spool;
        vaultImplementation = _vaultImplementation;

        _updateStrategiesHash(strategies);
    }

    /* ========== VIEWS ========== */

    /**
     * @dev Throws if controller is paused.
     */
    function checkPaused() external view whenNotPaused {}

    /**
     * @notice Returns all strategy contract addresses.
     *
     * @return array of strategy addresses
     */
    function getAllStrategies()
        external
        view
        override
        returns (address[] memory)
    {
        return strategies;
    }

    /**
     * @notice Returns the amount of strategies registered
     *
     * @return strategies count
     */
    function getStrategiesCount() external override view returns(uint8) {
        return uint8(strategies.length);
    }

    /**
     * @notice hash strategies list, verify hash matches to storage hash.
     *
     * @dev
     *
     * Requirements:
     *
     * - hash of input matches hash in storage
     *
     * @param _strategies list of strategies to check
     */
    function verifyStrategies(address[] calldata _strategies) external override view {
        require(Hash.sameStrategies(_strategies, strategiesHash), "Controller::verifyStrategies: Incorrect strategies");
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
    * @notice Stops the controller.
     */
    function pause() onlyPauser external {
        _pause();
    }

    /**
     * @notice Resumes the controller.
     */
    function unpause() onlyUnpauser external {
        _unpause();
    }

    /**
     * @notice Allows the creation of a new vault.
     *
     * @dev
     * The vault creator is immediately set as the allocation provider as well as
     * reward token setter. These traits are all transferrable and should be transferred
     * to another person beyond creation.
     *
     * Emits a {VaultCreated} event indicating the address of the vault. Parameters cannot
     * be emitted due to reaching the stack limit and should instead be fetched from the
     * vault directly.
     *
     * Requirements:
     *
     * - the underlying currency must be supported by the system
     * - the strategies and proportions must be equal in length
     * - the sum of the strategy proportions must be 100%
     * - the strategies must all be supported by the system
     * - the strategies must be unique
     * - the underlying asset of the strategies must match the desired one
     * - the fee of the vault owner must not exceed 20% in basis points,
     *   or 60% if creator is the Spool DAO
     * - the risk provider must exist in the risk provider registry
     * - the risk tolerance of the vault must be within the [-10, 10] range
     *
     * @param details details of the vault to be created (see VaultDetails)
     *
     * @return vault address of the newly created vault 
     */
    function createVault(
        VaultDetails calldata details
    ) external returns (address vault) {
        require(
            details.creator != address(0),
            "Controller::createVault: Missing vault creator"
        );
        require(
            supportedUnderlying[IERC20(details.underlying)],
            "Controller::createVault: Unsupported currency"
        );
        require(
            details.strategies.length > 0 && details.strategies.length <= MAX_VAULT_STRATEGIES,
            "Controller::createVault: Invalid number of strategies"
        );
        require(
            details.strategies.length == details.proportions.length,
            "Controller::createVault: Improper setup"
        );

        uint256 total;
        for (uint256 i = 0; i < details.strategies.length; i++) {
            // check if all strategies are unique
            for (uint256 j = i+1; j < details.strategies.length; j++) {
                require(details.strategies[i] != details.strategies[j], "Controller::createVault: Strategies not unique");
            }

            require(
                validStrategy[details.strategies[i]],
                "Controller::createVault: Unsupported strategy"
            );
            IBaseStrategy strategy = IBaseStrategy(details.strategies[i]);

            require(
                strategy.underlying() == IERC20(details.underlying),
                "Controller::createVault: Incorrect currency for strategy"
            );

            total += details.proportions[i];
        }

        require(
            total == FULL_PERCENT,
            "Controller::createVault: Improper allocations"
        );

        require(
            details.vaultFee <= MAX_VAULT_CREATOR_FEE ||
            // Spool DAO can set higher vault owner fee
            (details.vaultFee <= MAX_DAO_VAULT_CREATOR_FEE && isSpoolOwner()),
            "Controller::createVault: High owner fee"
        );

        require(
            riskRegistry.isProvider(details.riskProvider),
            "Controller::createVault: Invalid risk provider"
        );

        require(
            details.riskTolerance >= MIN_RISK_TOLERANCE &&
            details.riskTolerance <= MAX_RISK_TOLERANCE,
            "Controller::createVault: Incorrect Risk Tolerance"
        );

        vault = _createVault(details);

        validVault[vault] = true;
        totalVaults++;

        _emitVaultCreated(vault, details);
    }

    /**
     * @notice Emit event with vault details on creation
     * @param vault Vault address
     * @param details Vault details
     */
    function _emitVaultCreated(address vault, VaultDetails calldata details) private {
        emit VaultCreated(
            vault,
            details.underlying,
            details.strategies,
            details.proportions,
            details.vaultFee,
            details.riskProvider,
            details.riskTolerance
        );
    }

    /**
     * @notice Allows the creation of a new vault.
     *
     * @dev
     * Creates an instance of the Vault proxy contract and returns the address to the Controller.
     *
     * @param vaultDetails details of the vault to be created (see VaultDetails)
     * @return vault Address of newly created vault 
     */
    function _createVault(
        VaultDetails calldata vaultDetails
    ) private returns (address vault) {
        vault = address(
            new VaultNonUpgradableProxy(
                vaultImplementation,
                _getVaultImmutables(vaultDetails)
            )
        );

        IVault(vault).initialize(_getVaultInitializable(vaultDetails));
    }

    /**
     * @notice Return new vault immutable values
     *
     * @param vaultDetails details of the vault to be created
     * @return Vault immutable values
     */
    function _getVaultImmutables(VaultDetails calldata vaultDetails) private pure returns (VaultImmutables memory) {
        return VaultImmutables(
            IERC20(vaultDetails.underlying),
            vaultDetails.riskProvider,
            vaultDetails.riskTolerance
        );
    }

    /**
     * @notice Return new vault initializable values
     *
     * @param vaultDetails details of the vault to be created
     * @return New vault initializable values
     */
    function _getVaultInitializable(VaultDetails calldata vaultDetails) private pure returns (VaultInitializable memory) {
        return VaultInitializable(
            vaultDetails.name,
            vaultDetails.creator,
            vaultDetails.vaultFee,
            vaultDetails.strategies,
            vaultDetails.proportions
        );
    }

    /**
     * @notice Allows a user to claim their reward drip rewards across multiple vaults
     * in a single transaction.
     *
     * @dev
     * Requirements:
     *
     * - the caller must have rewards in all the vaults specified
     * - the vaults must be valid vaults in the Spool system
     *
     * @param vaults vaults for which to claim rewards for
     */
    function getRewards(IVault[] calldata vaults) external {
        IVault vault;
        for (uint256 i = 0; i < vaults.length; i++) {
            vault = vaults[i];
            if (!validVault[address(vault)]) {
                emit VaultInvalid(address(vault));
                continue;
            }
            vaults[i].getActiveRewards(msg.sender);
        }
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
     * @notice transfer vault underlying tokens to the Spool contact, from a user.
     *
     * @dev
     * Users of multiple vaults can choose to set allowance for the underlying token to this contract only, and then 
     * interact with any vault without having to set allowance to each vault induvidually.
     *
     * Requirements:
     *
     * - the caller must be a vault
     * - user (transferFrom address) must have given enough allowance to this contract 
     * - user (transferFrom address) must have enough tokens to transfer
     *
     * @param transferFrom address to transfer the tokens from (user address from vault)
     * @param amount amount of underlying tokens to transfer to the Spool
     */
    function transferToSpool(address transferFrom, uint256 amount) external override onlyVault {
        IVault(msg.sender).underlying().safeTransferFrom(transferFrom, address(spool), amount);
    }

    /**
     * @notice Allows a new strategy to be added to the Spool system.
     *
     * @dev
     * Emits a {StrategyAdded} event indicating the newly added strategy
     * and whether it is multi-collateral.
     *
     * Requirements:
     *
     * - the caller must be the contract owner (Spool DAO)
     * - the provided strategies must either be all valid or an empty array
     * - the strategy must not have already been added
     * 
     * @param strategy the strategy to add to the system
     * @param allStrategies All valid strategies in the system
     */
    function addStrategy(
        address strategy,
        address[] memory allStrategies
    )
        external
        onlyOwner
        validStrategiesOrEmpty(allStrategies)
    {
        require(
            !validStrategy[strategy],
            "Controller::addStrategy: Strategy already registered"
        );

        validStrategy[strategy] = true;

        IERC20 underlying = IBaseStrategy(strategy).underlying();
        supportedUnderlying[underlying] = true;

        spool.addStrategy(strategy);

        strategies.push(strategy);

        // update strategies hash
        // update can happen using stored strategies or provided ones
        if (allStrategies.length == 0) {
            _updateStrategiesHash(strategies);
        } else {
            allStrategies = _addStrategy(allStrategies, strategy);
            _updateStrategiesHash(allStrategies);
        }

        emit StrategyAdded(strategy);
    }

    /**
     * @notice Add a strategy
     * @param currentStrategies Array of current strategies
     * @param strategy Address of the strategy to add
     * @return Array with the given strategy added
     */
    function _addStrategy(address[] memory currentStrategies, address strategy) private pure returns(address[] memory) {
        address[] memory newStrategies = new address[](currentStrategies.length + 1);
        for(uint256 i = 0; i < currentStrategies.length; i++) {
            newStrategies[i] = currentStrategies[i];
        }

        newStrategies[newStrategies.length - 1] = strategy;

        return newStrategies;
    }

    /**
     * @notice Allows an existing strategy to be removed from the Spool system,
     * withdrawing and liquidating any actively deployed funds in the strategy.
     *
     * @dev
     * Withdrawn funds are sent to the `emergencyRecipient` address. If the address is 0
     * Funds will be sent to the caller of this function. 
     *
     * Emits a {StrategyRemoved} event indicating the removed strategy.
     *
     * Requirements:
     *
     * - the caller must be the emergency withdrawer
     * - the strategy must already exist in the contract
     * - the provided strategies array must be vaild or empty
     *
     * @param strategy the strategy to remove from the system
     * @param skipDisable flag to skip execution of strategy specific disable (e.g cleanup tasks) function.
     * @param data strategy specific data required to withdraw the funds from the strategy 
     * @param allStrategies current valid strategies or empty array
     */
    function removeStrategyAndWithdraw(
        address strategy,
        bool skipDisable,
        uint256[] calldata data,
        address[] calldata allStrategies
    )
        external
        onlyEmergencyWithdrawer
    {
        _removeStrategy(strategy, skipDisable, allStrategies);
        _emergencyWithdraw(strategy, data);
    }

    /**
     * @notice Allows an existing strategy to be removed from the Spool system.
     *
     * @dev
     *
     * Emits a {StrategyRemoved} event indicating the removed strategy.
     *
     * Requirements:
     *
     * - the caller must be the emergency withdrawer
     * - the strategy must already exist in the contract
     * - the provided strategies array must be vaild or empty
     *
     * @param strategy the strategy to remove from the system
     * @param skipDisable flag to skip execution of strategy specific disable (e.g cleanup tasks) function.
     * @param allStrategies current valid strategies or empty array
     */
    function removeStrategy(
        address strategy,
        bool skipDisable,
        address[] calldata allStrategies
    )
        external
        onlyEmergencyWithdrawer
    {
        _removeStrategy(strategy, skipDisable, allStrategies);
    }

    /**
     * @notice Withdraws and liquidates any actively deployed funds from already removed strategy.
     *
     * @dev
     * Withdrawn funds are sent to the `emergencyRecipient` address. If the address is 0
     * Funds will be sent to the caller of this function. 
     *
     * Requirements:
     *
     * - the caller must be the emergency withdrawer
     * - the strategy must already be removed
     *
     * @param strategy the strategy to remove from the system
     * @param data strategy specific data required to withdraw the funds from the strategy 
     */
    function emergencyWithdraw(
        address strategy,
        uint256[] calldata data
    ) 
        external
        onlyEmergencyWithdrawer
    {
        require(
            !validStrategy[strategy],
            "VaultRegistry::removeStrategy: Strategy should not be valid"
        );

        _emergencyWithdraw(strategy, data);
    }

    /**
     * @notice Allows an existing strategy to be removed from the Spool system.
     *
     * @dev
     *
     * Emits a {StrategyRemoved} event indicating the removed strategy.
     *
     * Requirements:
     *
     * - the strategy must already exist in the contract
     * - the provided strategies array must be vaild or empty
     *
     * @param strategy the strategy to remove from the system
     * @param skipDisable flag to skip execution of strategy specific disable (e.g cleanup tasks) function.
     * @param allStrategies current valid strategies or empty array
     */
    function _removeStrategy(
        address strategy,
        bool skipDisable,
        address[] calldata allStrategies
    )
        private
        validStrategiesOrEmpty(allStrategies)
    {
        require(
            validStrategy[strategy],
            "Controller::removeStrategy: Strategy is not registered"
        );

        spool.disableStrategy(strategy, skipDisable);

        validStrategy[strategy] = false;

        // update strategies storage array and hash
        // update can happen using strategies from storage or from calldata
        if (allStrategies.length == 0) {
            _removeStrategyStorage(strategy);
        } else {
            _removeStrategyCalldata(allStrategies, strategy);
        }

        emit StrategyRemoved(strategy);
    }

    /**
     * @notice Remove strategy from storage array and update the strategies hash
     *
     * @param strategy strategy address to remove
     */
    function _removeStrategyStorage(address strategy) private {
        uint256 lastEntry = strategies.length - 1;
        for (uint256 i = 0; i < lastEntry; i++) {
            if (strategies[i] == strategy) {
                strategies[i] = strategies[lastEntry];
                break;
            }
        }

        strategies.pop();

        _updateStrategiesHash(strategies);
    }

    /**
     * @notice Remove strategy from storage array using calldata array and update the strategies hash
     * @dev Should significantly lower the cost of removing a strategy
     *
     * @param allStrategies current valid strategies stored in calldata
     * @param strategy strategy address to remove
     */
    function _removeStrategyCalldata(address[] calldata allStrategies, address strategy) private {
        uint256 lastEntry = allStrategies.length - 1;
        address[] memory newStrategies = allStrategies[0:lastEntry];

        for (uint256 i = 0; i < lastEntry; i++) {
            if (allStrategies[i] == strategy) {
                strategies[i] = allStrategies[lastEntry];
                newStrategies[i] = allStrategies[lastEntry];
                break;
            }
        }

        strategies.pop();

        _updateStrategiesHash(newStrategies);
    }

    /**
     * @notice Liquidating all actively deployed funds within a strategy after it was disabled.
     *
     * @param strategy strategy to withdraw from
     * @param data data to perform the withdrawal
     */
    function _emergencyWithdraw(
        address strategy,
        uint256[] calldata data
    )
        private
    {
        spool.emergencyWithdraw(
            strategy,
            _getEmergencyRecipient(),
            data
        );

        emit EmergencyWithdrawStrategy(strategy);
    }

    /**
     * @notice Returns address to send the emergency whithdrawn funds
     * @dev if the address is not defined assets are sent to the caller address
     * @param _emergencyRecipient Emergency recipient address
     */
    function _getEmergencyRecipient() private view returns(address _emergencyRecipient) {
        _emergencyRecipient = emergencyRecipient;

        if (_emergencyRecipient == address(0)) {
            _emergencyRecipient = msg.sender;
        }
    }

    /**
     * @notice Execute strategy disable function after it was removed.
     *
     * @dev
     * Requirements:
     *
     * - the caller must be the emergency withdrawer
     *
     * @param strategy strategy to execute disable
     */
    function runDisableStrategy(address strategy)
        external
        onlyEmergencyWithdrawer
    {
        require(
            !validStrategy[strategy],
            "Controller::runDisableStrategy: Strategy is still valid"
        );

        spool.runDisableStrategy(strategy);
        emit DisableStrategy(strategy);
    }

    /**
     * @notice Add or remove the emergency withdrawer right
     *
     * @dev
     * Requirements:
     *
     * - the caller must be the contract owner (Spool DAO)
     * @param user Address for which to set the role
     * @param _isEmergencyWithdrawer Flag to set the role to
     */
    function setEmergencyWithdrawer(address user, bool _isEmergencyWithdrawer) external onlyOwner {
        isEmergencyWithdrawer[user] = _isEmergencyWithdrawer;
        emit EmergencyWithdrawerUpdated(user, _isEmergencyWithdrawer);
    }

    /**
    * @notice Add or remove the pauser role
     *
     * @dev
     * Requirements:
     *
     * - the caller must be the contract owner (Spool DAO)
     * @param user Address for which to set the role
     * @param _set Flag to set the role to
     */
    function setPauser(address user, bool _set) external onlyOwner {
        isPauser[user] = _set;
        emit PauserUpdated(user, _set);
    }

    /**
     * @notice Add or remove the unpauser role
     *
     * @dev
     * Requirements:
     *
     * - the caller must be the contract owner (Spool DAO)
     * @param user Address for which to set the role
     * @param _set Flag to set the role to
     */
    function setUnpauser(address user, bool _set) external onlyOwner {
        isUnpauser[user] = _set;
        emit UnpauserUpdated(user, _set);
    }

    /**
     * @notice Set the emergency withdraw recipient
     *
     * @dev
     * Requirements:
     *
     * - the caller must be the contract owner (Spool DAO)
     * @param _emergencyRecipient Flag to set the role to
     */
    function setEmergencyRecipient(address _emergencyRecipient) external onlyOwner {
        emergencyRecipient = _emergencyRecipient;
        emit EmergencyRecipientUpdated(_emergencyRecipient);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    /**
     * @notice Following strategies change, update the strategies hash in storage.
     *
     * @param _strategies addresses of all valid strategies
     */
    function _updateStrategiesHash(address[] memory _strategies) private {
        strategiesHash = Hash.hashStrategies(_strategies);
    }

    /**
     * @notice Verify caller is a valid vault contact
     *
     * @dev
     * Only callable from onlyVault modifier.
     *
     * Requirements:
     *
     * - msg.sender is contained in validVault address mapping
     */
    function _onlyVault() private view {
        require(
            validVault[msg.sender],
            "Controller::_onlyVault: Can only be invoked by vault"
        );
    }

    /**
     * @notice Ensures that the caller is the emergency withdrawer
     */
    function _onlyEmergencyWithdrawer() private view {
        require(
            isEmergencyWithdrawer[msg.sender] || isSpoolOwner(),
            "Controller::_onlyEmergencyWithdrawer: Can only be invoked by the emergency withdrawer"
        );
    }

    /**
     * @notice Ensures the provided strategies are correct
     * @dev Allow if array of strategies is empty
     * @param _strategies Array of strategies to verify
     */
    function _validStrategiesOrEmpty(address[] memory _strategies) private view {
        require(
            _strategies.length == 0 ||
            Hash.sameStrategies(_strategies, strategiesHash),
            "Controller::_validStrategiesOrEmpty: Strategies do not match"
        );
    }

    /**
    * @notice Ensures that the caller is the pauser
     */
    function _onlyPauser() private view {
        require(
            isPauser[msg.sender] || isSpoolOwner(),
            "Controller::_onlyPauser: Can only be invoked by pauser"
        );
    }

    /**
     * @notice Ensures that the caller is the unpauser
     */
    function _onlyUnpauser() private view {
        require(
            isUnpauser[msg.sender] || isSpoolOwner(),
            "Controller::_onlyUnpauser: Can only be invoked by unpauser"
        );
    }

    /* ========== MODIFIERS ========== */

    /**
     * @notice Throws if called by a non-valid vault
     */
    modifier onlyVault() {
        _onlyVault();
        _;
    }

    /**
     * @notice Throws if the caller is not emergency withdraw
     */
    modifier onlyEmergencyWithdrawer() {
        _onlyEmergencyWithdrawer();
        _;
    }

    /**
     * @notice Throws if the strategies are not valid or empty array
     * @param allStrategies Array of strategies
     */
    modifier validStrategiesOrEmpty(address[] memory allStrategies) {
        _validStrategiesOrEmpty(allStrategies);
        _;
    }

    /**
     * @notice Throws if the calling user is not pauser
     */
    modifier onlyPauser() {
        _onlyPauser();
        _;
    }

    /**
     * @notice Throws if the calling user is not unpauser
     */
    modifier onlyUnpauser() {
        _onlyUnpauser();
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "../external/@openzeppelin/token/ERC20/IERC20.sol";
import "./ISwapData.sol";

interface IBaseStrategy {
    function underlying() external view returns (IERC20);

    function getStrategyBalance() external view returns (uint128);

    function getStrategyUnderlyingWithRewards() external view returns(uint128);

    function process(uint256[] calldata, bool, SwapData[] calldata) external;

    function processReallocation(uint256[] calldata, ProcessReallocationData calldata) external returns(uint128);

    function processDeposit(uint256[] calldata) external;

    function fastWithdraw(uint128, uint256[] calldata, SwapData[] calldata) external returns(uint128);

    function claimRewards(SwapData[] calldata) external;

    function emergencyWithdraw(address recipient, uint256[] calldata data) external;

    function initialize() external;

    function disable() external;
}

struct ProcessReallocationData {
    uint128 sharesToWithdraw;
    uint128 optimizedShares;
    uint128 optimizedWithdrawnAmount;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "../external/@openzeppelin/token/ERC20/IERC20.sol";

interface IController {
    /* ========== FUNCTIONS ========== */

    function strategies(uint256 i) external view returns (address);

    function validStrategy(address strategy) external view returns (bool);

    function validVault(address vault) external view returns (bool);

    function getStrategiesCount() external view returns(uint8);

    function supportedUnderlying(IERC20 underlying)
        external
        view
        returns (bool);

    function getAllStrategies() external view returns (address[] memory);

    function verifyStrategies(address[] calldata _strategies) external view;

    function transferToSpool(
        address transferFrom,
        uint256 amount
    ) external;

    function checkPaused() external view;

    /* ========== EVENTS ========== */

    event EmergencyWithdrawStrategy(address indexed strategy);
    event EmergencyRecipientUpdated(address indexed recipient);
    event EmergencyWithdrawerUpdated(address indexed withdrawer, bool set);
    event PauserUpdated(address indexed user, bool set);
    event UnpauserUpdated(address indexed user, bool set);
    event VaultCreated(address indexed vault, address underlying, address[] strategies, uint256[] proportions,
        uint16 vaultFee, address riskProvider, int8 riskTolerance);
    event StrategyAdded(address strategy);
    event StrategyRemoved(address strategy);
    event VaultInvalid(address vault);
    event DisableStrategy(address strategy);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "../external/@openzeppelin/token/ERC20/IERC20.sol";

interface IRiskProviderRegistry {
    /* ========== FUNCTIONS ========== */

    function isProvider(address provider) external view returns (bool);

    function getRisk(address riskProvider, address strategy) external view returns (uint8);

    function getRisks(address riskProvider, address[] memory strategies) external view returns (uint8[] memory);

    /* ========== EVENTS ========== */

    event RiskAssessed(address indexed provider, address indexed strategy, uint8 riskScore);
    event ProviderAdded(address provider);
    event ProviderRemoved(address provider);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "./spool/ISpoolExternal.sol";
import "./spool/ISpoolReallocation.sol";
import "./spool/ISpoolDoHardWork.sol";
import "./spool/ISpoolStrategy.sol";
import "./spool/ISpoolBase.sol";

/// @notice Utility Interface for central Spool implementation
interface ISpool is ISpoolExternal, ISpoolReallocation, ISpoolDoHardWork, ISpoolStrategy, ISpoolBase {}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

interface ISpoolOwner {
    function isSpoolOwner(address user) external view returns(bool);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

/**
 * @notice Strict holding information how to swap the asset
 * @member slippage minumum output amount
 * @member path swap path, first byte represents an action (e.g. Uniswap V2 custom swap), rest is swap specific path
 */
struct SwapData {
    uint256 slippage; // min amount out
    bytes path; // 1st byte is action, then path 
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "./vault/IVaultRestricted.sol";
import "./vault/IVaultIndexActions.sol";
import "./vault/IRewardDrip.sol";
import "./vault/IVaultBase.sol";
import "./vault/IVaultImmutable.sol";

interface IVault is IVaultRestricted, IVaultIndexActions, IRewardDrip, IVaultBase, IVaultImmutable {}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

interface ISpoolBase {
    /* ========== FUNCTIONS ========== */

    function getCompletedGlobalIndex() external view returns(uint24);

    function getActiveGlobalIndex() external view returns(uint24);

    function isMidReallocation() external view returns (bool);

    /* ========== EVENTS ========== */

    event ReallocationTableUpdated(
        uint24 indexed index,
        bytes32 reallocationTableHash
    );

    event ReallocationTableUpdatedWithTable(
        uint24 indexed index,
        bytes32 reallocationTableHash,
        uint256[][] reallocationTable
    );
    
    event DoHardWorkCompleted(uint24 indexed index);

    event SetAllocationProvider(address actor, bool isAllocationProvider);
    event SetIsDoHardWorker(address actor, bool isDoHardWorker);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

interface ISpoolDoHardWork {
    /* ========== EVENTS ========== */

    event DoHardWorkStrategyCompleted(address indexed strat, uint256 indexed index);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "../ISwapData.sol";

interface ISpoolExternal {
    /* ========== FUNCTIONS ========== */

    function deposit(address strategy, uint128 amount, uint256 index) external;

    function withdraw(address strategy, uint256 vaultProportion, uint256 index) external;

    function fastWithdrawStrat(address strat, address underlying, uint256 shares, uint256[] calldata slippages, SwapData[] calldata swapData) external returns(uint128);

    function redeem(address strat, uint256 index) external returns (uint128, uint128);

    function redeemUnderlying(uint128 amount) external;

    function redeemReallocation(address[] calldata vaultStrategies, uint256 depositProportions, uint256 index) external;

    function removeShares(address[] calldata vaultStrategies, uint256 vaultProportion) external returns(uint128[] memory);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

interface ISpoolReallocation {
    event StartReallocation(uint24 indexed index);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

interface ISpoolStrategy {
    /* ========== FUNCTIONS ========== */

    function getUnderlying(address strat) external returns (uint128);
    
    function getVaultTotalUnderlyingAtIndex(address strat, uint256 index) external view returns(uint128);

    function addStrategy(address strat) external;

    function disableStrategy(address strategy, bool skipDisable) external;

    function runDisableStrategy(address strategy) external;

    function emergencyWithdraw(
        address strat,
        address withdrawRecipient,
        uint256[] calldata data
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "../../external/@openzeppelin/token/ERC20/IERC20.sol";

interface IRewardDrip {
    /* ========== STRUCTS ========== */

    // The reward configuration struct, containing all the necessary data of a typical Synthetix StakingReward contract
    struct RewardConfiguration {
        uint32 rewardsDuration;
        uint32 periodFinish;
        uint192 rewardRate; // rewards per second multiplied by accuracy
        uint32 lastUpdateTime;
        uint224 rewardPerTokenStored;
        mapping(address => uint256) userRewardPerTokenPaid;
        mapping(address => uint256) rewards;
    }

    /* ========== FUNCTIONS ========== */

    function getActiveRewards(address account) external;
    function tokenBlacklist(IERC20 token) view external returns(bool);

    /* ========== EVENTS ========== */
    
    event RewardPaid(IERC20 token, address indexed user, uint256 reward);
    event RewardAdded(IERC20 indexed token, uint256 amount, uint256 duration);
    event RewardExtended(IERC20 indexed token, uint256 amount, uint256 leftover, uint256 duration, uint32 periodFinish);
    event RewardRemoved(IERC20 indexed token);
    event PeriodFinishUpdated(IERC20 indexed token, uint32 periodFinish);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "./IVaultDetails.sol";

interface IVaultBase {
    /* ========== FUNCTIONS ========== */

    function initialize(VaultInitializable calldata vaultInitializable) external;

    /* ========== STRUCTS ========== */

    struct User {
        uint128 instantDeposit; // used for calculating rewards
        uint128 activeDeposit; // users deposit after deposit process and claim
        uint128 owed; // users owed underlying amount after withdraw has been processed and claimed
        uint128 withdrawnDeposits; // users withdrawn deposit, used to calculate performance fees
        uint128 shares; // users shares after deposit process and claim
    }

    /* ========== EVENTS ========== */

    event Claimed(address indexed member, uint256 claimAmount);
    event Deposit(address indexed member, uint256 indexed index, uint256 amount);
    event Withdraw(address indexed member, uint256 indexed index, uint256 shares);
    event WithdrawFast(address indexed member, uint256 shares);
    event StrategyRemoved(uint256 i, address strategy);
    event TransferVaultOwner(address owner);
    event LowerVaultFee(uint16 fee);
    event UpdateName(string name);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

struct VaultDetails {
    address underlying;
    address[] strategies;
    uint256[] proportions;
    address creator;
    uint16 vaultFee;
    address riskProvider;
    int8 riskTolerance;
    string name;
}

struct VaultInitializable {
    string name;
    address owner;
    uint16 fee;
    address[] strategies;
    uint256[] proportions;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "../../external/@openzeppelin/token/ERC20/IERC20.sol";

struct VaultImmutables {
    IERC20 underlying;
    address riskProvider;
    int8 riskTolerance;
}

interface IVaultImmutable {
    /* ========== FUNCTIONS ========== */

    function underlying() external view returns (IERC20);

    function riskProvider() external view returns (address);

    function riskTolerance() external view returns (int8);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

interface IVaultIndexActions {

    /* ========== STRUCTS ========== */

    struct IndexAction {
        uint128 depositAmount;
        uint128 withdrawShares;
    }

    struct LastIndexInteracted {
        uint128 index1;
        uint128 index2;
    }

    struct Redeem {
        uint128 depositShares;
        uint128 withdrawnAmount;
    }

    /* ========== EVENTS ========== */

    event VaultRedeem(uint indexed globalIndex);
    event UserRedeem(address indexed member, uint indexed globalIndex);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

interface IVaultRestricted {
    /* ========== FUNCTIONS ========== */
    
    function reallocate(
        address[] calldata vaultStrategies,
        uint256 newVaultProportions,
        uint256 finishedIndex,
        uint24 activeIndex
    ) external returns (uint256[] memory, uint256);

    function payFees(uint256 profit) external returns (uint256 feesPaid);

    /* ========== EVENTS ========== */

    event Reallocate(uint24 indexed index, uint256 newProportions);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

/**
 * @notice Library to provide utils for hashing and hash compatison of Spool related data
 */
library Hash {
    function hashReallocationTable(uint256[][] memory reallocationTable) internal pure returns(bytes32) {
        return keccak256(abi.encode(reallocationTable));
    }

    function hashStrategies(address[] memory strategies) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked(strategies));
    }

    function sameStrategies(address[] memory strategies1, address[] memory strategies2) internal pure returns(bool) {
        return hashStrategies(strategies1) == hashStrategies(strategies2);
    }

    function sameStrategies(address[] memory strategies, bytes32 strategiesHash) internal pure returns(bool) {
        return hashStrategies(strategies) == strategiesHash;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "../external/@openzeppelin/token/ERC20/IERC20.sol";

/// @title Common Spool contracts constants
abstract contract BaseConstants {
    /// @dev 2 digits precision
    uint256 internal constant FULL_PERCENT = 100_00;

    /// @dev Accuracy when doing shares arithmetics
    uint256 internal constant ACCURACY = 10**30;
}

/// @title Contains USDC token related values
abstract contract USDC {
    /// @notice USDC token contract address
    IERC20 internal constant USDC_ADDRESS = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "../interfaces/ISpoolOwner.sol";

/// @title Logic to help check whether the caller is the Spool owner
abstract contract SpoolOwnable {
    /// @notice Contract that checks if address is Spool owner
    ISpoolOwner internal immutable spoolOwner;

    /**
     * @notice Sets correct initial values
     * @param _spoolOwner Spool owner contract address
     */
    constructor(ISpoolOwner _spoolOwner) {
        require(
            address(_spoolOwner) != address(0),
            "SpoolOwnable::constructor: Spool owner contract address cannot be 0"
        );

        spoolOwner = _spoolOwner;
    }

    /**
     * @notice Checks if caller is Spool owner
     * @return True if caller is Spool owner, false otherwise
     */
    function isSpoolOwner() internal view returns(bool) {
        return spoolOwner.isSpoolOwner(msg.sender);
    }


    /// @notice Checks and throws if caller is not Spool owner
    function _onlyOwner() private view {
        require(isSpoolOwner(), "SpoolOwnable::onlyOwner: Caller is not the Spool owner");
    }

    /// @notice Checks and throws if caller is not Spool owner
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "../external/@openzeppelin/proxy/Proxy.sol";
import "../interfaces/vault/IVaultImmutable.sol";
import "../interfaces/vault/IVaultDetails.sol";

/**
 * @notice This contract is a non-upgradable proxy for Spool vault implementation.
 *
 * @dev
 * It is used to lower the gas cost of vault creation.
 * The contract holds vault specific immutable variables.
 */
contract VaultNonUpgradableProxy is Proxy, IVaultImmutable {
    /* ========== STATE VARIABLES ========== */

    /// @notice The address of vault implementation
    address public immutable vaultImplementation;

    /// @notice Vault underlying asset
    IERC20 public override immutable underlying;

    /// @notice Vault risk provider address
    address public override immutable riskProvider;

    /// @notice A number from -10 to 10 indicating the risk tolerance of the vault
    int8 public override immutable riskTolerance;

    /* ========== CONSTRUCTOR ========== */
    
    /**
     * @notice Sets the vault specific immutable values.
     *
     * @param _vaultImplementation implementation contract address of the vault
     * @param vaultImmutables vault immutable values
     */
    constructor(
        address _vaultImplementation,
        VaultImmutables memory vaultImmutables
    ) {
        vaultImplementation = _vaultImplementation;
        underlying = vaultImmutables.underlying;
        riskProvider = vaultImmutables.riskProvider;
        riskTolerance = vaultImmutables.riskTolerance;
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
     * @notice Return contract address of vault implementation.
     *
     * @return vault implementation contract address
     */
    function _implementation() internal view override returns (address) {
        return vaultImplementation;
    }
}