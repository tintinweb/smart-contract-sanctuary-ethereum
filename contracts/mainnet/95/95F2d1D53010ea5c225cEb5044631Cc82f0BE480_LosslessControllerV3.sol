// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./Interfaces/ILosslessERC20.sol";
import "./Interfaces/ILosslessGovernance.sol";
import "./Interfaces/ILosslessStaking.sol";
import "./Interfaces/ILosslessReporting.sol";
import "./Interfaces/IProtectionStrategy.sol";

/// @title Lossless Controller Contract
/// @notice The controller contract is in charge of the communication and senstive data among all Lossless Environment Smart Contracts
contract LosslessControllerV3 is ILssController, Initializable, ContextUpgradeable, PausableUpgradeable {
    
    // IMPORTANT!: For future reference, when adding new variables for following versions of the controller. 
    // All the previous ones should be kept in place and not change locations, types or names.
    // If thye're modified this would cause issues with the memory slots.

    address override public pauseAdmin;
    address override public admin;
    address override public recoveryAdmin;

    // --- V2 VARIABLES ---

    address override public guardian;
    mapping(ILERC20 => Protections) private tokenProtections;

    struct Protection {
        bool isProtected;
        ProtectionStrategy strategy;
    }

    struct Protections {
        mapping(address => Protection) protections;
    }

    // --- V3 VARIABLES ---

    ILssStaking override public losslessStaking;
    ILssReporting override public losslessReporting;
    ILssGovernance override public losslessGovernance;

    struct LocksQueue {
        mapping(uint256 => ReceiveCheckpoint) lockedFunds;
        uint256 touchedTimestamp;
        uint256 first;
        uint256 last;
    }

    struct TokenLockedFunds {
        mapping(address => LocksQueue) queue;
    }

    mapping(ILERC20 => TokenLockedFunds) private tokenScopedLockedFunds;
    
    struct ReceiveCheckpoint {
        uint256 amount;
        uint256 timestamp;
        uint256 cummulativeAmount;
    }
    
    uint256 public constant HUNDRED = 1e2;
    uint256 override public dexTranferThreshold;
    uint256 override public settlementTimeLock;

    mapping(address => bool) override public dexList;
    mapping(address => bool) override public whitelist;
    mapping(address => bool) override public blacklist;

    struct TokenConfig {
        uint256 tokenLockTimeframe;
        uint256 proposedTokenLockTimeframe;
        uint256 changeSettlementTimelock;
        uint256 emergencyMode;
    }

    mapping(ILERC20 => TokenConfig) tokenConfig;

    // --- MODIFIERS ---

    /// @notice Avoids execution from other than the Recovery Admin
    modifier onlyLosslessRecoveryAdmin() {
        require(msg.sender == recoveryAdmin, "LSS: Must be recoveryAdmin");
        _;
    }

    /// @notice Avoids execution from other than the Lossless Admin
    modifier onlyLosslessAdmin() {
        require(msg.sender == admin, "LSS: Must be admin");
        _;
    }

    /// @notice Avoids execution from other than the Pause Admin
    modifier onlyPauseAdmin() {
        require(msg.sender == pauseAdmin, "LSS: Must be pauseAdmin");
        _;
    }

    // --- V2 MODIFIERS ---

    modifier onlyGuardian() {
        require(msg.sender == guardian, "LOSSLESS: Must be Guardian");
        _;
    }

    // --- V3 MODIFIERS ---

    /// @notice Avoids execution from other than the Lossless Admin or Lossless Environment
    modifier onlyLosslessEnv {
        require(msg.sender == address(losslessStaking)   ||
                msg.sender == address(losslessReporting) || 
                msg.sender == address(losslessGovernance),
                "LSS: Lss SC only");
        _;
    }

    // --- VIEWS ---

    /// @notice This function will return the contract version 
    function getVersion() external pure returns (uint256) {
        return 3;
    }

        // --- V2 VIEWS ---

    function isAddressProtected(ILERC20 _token, address _protectedAddress) public view returns (bool) {
        return tokenProtections[_token].protections[_protectedAddress].isProtected;
    }

    function getProtectedAddressStrategy(ILERC20 _token, address _protectedAddress) external view returns (address) {
        require(isAddressProtected(_token, _protectedAddress), "LSS: Address not protected");
        return address(tokenProtections[_token].protections[_protectedAddress].strategy);
    }

    // --- ADMINISTRATION ---

    function pause() override public onlyPauseAdmin  {
        _pause();
    }    
    
    function unpause() override public onlyPauseAdmin {
        _unpause();
    }

    /// @notice This function sets a new admin
    /// @dev Only can be called by the Recovery admin
    /// @param _newAdmin Address corresponding to the new Lossless Admin
    function setAdmin(address _newAdmin) override public onlyLosslessRecoveryAdmin {
        require(_newAdmin != admin, "LERC20: Cannot set same address");
        emit AdminChange(_newAdmin);
        admin = _newAdmin;
    }

    /// @notice This function sets a new recovery admin
    /// @dev Only can be called by the previous Recovery admin
    /// @param _newRecoveryAdmin Address corresponding to the new Lossless Recovery Admin
    function setRecoveryAdmin(address _newRecoveryAdmin) override public onlyLosslessRecoveryAdmin {
        require(_newRecoveryAdmin != recoveryAdmin, "LERC20: Cannot set same address");
        emit RecoveryAdminChange(_newRecoveryAdmin);
        recoveryAdmin = _newRecoveryAdmin;
    }

    /// @notice This function sets a new pause admin
    /// @dev Only can be called by the Recovery admin
    /// @param _newPauseAdmin Address corresponding to the new Lossless Recovery Admin
    function setPauseAdmin(address _newPauseAdmin) override public onlyLosslessRecoveryAdmin {
        require(_newPauseAdmin != pauseAdmin, "LERC20: Cannot set same address");
        emit PauseAdminChange(_newPauseAdmin);
        pauseAdmin = _newPauseAdmin;
    }


    // --- V3 SETTERS ---

    /// @notice This function sets the timelock for tokens to change the settlement period
    /// @dev Only can be called by the Lossless Admin
    /// @param _newTimelock Timelock in seconds
    function setSettlementTimeLock(uint256 _newTimelock) override public onlyLosslessAdmin {
        require(_newTimelock != settlementTimeLock, "LSS: Cannot set same value");
        settlementTimeLock = _newTimelock;
        emit NewSettlementTimelock(settlementTimeLock);
    }

    /// @notice This function sets the transfer threshold for Dexes
    /// @dev Only can be called by the Lossless Admin
    /// @param _newThreshold Timelock in seconds
    function setDexTransferThreshold(uint256 _newThreshold) override public onlyLosslessAdmin {
        require(_newThreshold != dexTranferThreshold, "LSS: Cannot set same value");
        dexTranferThreshold = _newThreshold;
        emit NewDexThreshold(dexTranferThreshold);
    }
    
    /// @notice This function removes or adds an array of dex addresses from the whitelst
    /// @dev Only can be called by the Lossless Admin, only Lossless addresses 
    /// @param _dexList List of dex addresses to add or remove
    /// @param _value True if the addresses are bieng added, false if removed
    function setDexList(address[] calldata _dexList, bool _value) override public onlyLosslessAdmin {
        for(uint256 i = 0; i < _dexList.length;) {

            address adr = _dexList[i];
            require(!blacklist[adr], "LSS: An address is blacklisted");

            dexList[adr] = _value;

            if (_value) {
                emit NewDex(adr);
            } else {
                emit DexRemoval(adr);
            }

            unchecked{i++;}
        }
    }

    /// @notice This function removes or adds an array of addresses from the whitelst
    /// @dev Only can be called by the Lossless Admin, only Lossless addresses 
    /// @param _addrList List of addresses to add or remove
    /// @param _value True if the addresses are bieng added, false if removed
    function setWhitelist(address[] calldata _addrList, bool _value) override public onlyLosslessAdmin {
        for(uint256 i = 0; i < _addrList.length;) {

            address adr = _addrList[i];
            require(!blacklist[adr], "LSS: An address is blacklisted");

            whitelist[adr] = _value;

            if (_value) {
                emit NewWhitelistedAddress(adr);
            } else {
                emit WhitelistedAddressRemoval(adr);
            }

            unchecked{i++;}
        }
    }

    /// @notice This function adds an address to the blacklist
    /// @dev Only can be called by the Lossless Admin, and from other Lossless Contracts
    /// The address gets blacklisted whenever a report is created on them.
    /// @param _adr Address corresponding to be added to the blacklist mapping
    function addToBlacklist(address _adr) override public onlyLosslessEnv {
        blacklist[_adr] = true;
        emit NewBlacklistedAddress(_adr);
    }

    /// @notice This function removes an address from the blacklist
    /// @dev Can only be called from other Lossless Contracts, used mainly in Lossless Governance
    /// @param _adr Address corresponding to be removed from the blacklist mapping
    function resolvedNegatively(address _adr) override public onlyLosslessEnv {
        blacklist[_adr] = false;
        emit AccountBlacklistRemoval(_adr);
    }
    
    /// @notice This function sets the address of the Lossless Staking contract
    /// @param _adr Address corresponding to the Lossless Staking contract
    function setStakingContractAddress(ILssStaking _adr) override public onlyLosslessAdmin {
        require(address(_adr) != address(0), "LERC20: Cannot be zero address");
        require(_adr != losslessStaking, "LSS: Cannot set same value");
        losslessStaking = _adr;
        emit NewStakingContract(_adr);
    }

    /// @notice This function sets the address of the Lossless Reporting contract
    /// @param _adr Address corresponding to the Lossless Reporting contract
    function setReportingContractAddress(ILssReporting _adr) override public onlyLosslessAdmin {
        require(address(_adr) != address(0), "LERC20: Cannot be zero address");
        require(_adr != losslessReporting, "LSS: Cannot set same value");
        losslessReporting = _adr;
        emit NewReportingContract(_adr);
    }

    /// @notice This function sets the address of the Lossless Governance contract
    /// @param _adr Address corresponding to the Lossless Governance contract
    function setGovernanceContractAddress(ILssGovernance _adr) override public onlyLosslessAdmin {
        require(address(_adr) != address(0), "LERC20: Cannot be zero address");
        require(_adr != losslessGovernance, "LSS: Cannot set same value");
        losslessGovernance = _adr;
        emit NewGovernanceContract(_adr);
    }

    /// @notice This function starts a new proposal to change the SettlementPeriod
    /// @param _token to propose the settlement change period on
    /// @param _seconds Time frame that the recieved funds will be locked
    function proposeNewSettlementPeriod(ILERC20 _token, uint256 _seconds) override public {

        TokenConfig storage config = tokenConfig[_token];

        require(msg.sender == _token.admin(), "LSS: Must be Token Admin");
        require(config.changeSettlementTimelock <= block.timestamp, "LSS: Time lock in progress");
        config.changeSettlementTimelock = block.timestamp + settlementTimeLock;
        config.proposedTokenLockTimeframe = _seconds;
        emit NewSettlementPeriodProposal(_token, _seconds);
    }

    /// @notice This function executes the new settlement period after the timelock
    /// @param _token to set time settlement period on
    function executeNewSettlementPeriod(ILERC20 _token) override public {

        TokenConfig storage config = tokenConfig[_token];

        require(msg.sender == _token.admin(), "LSS: Must be Token Admin");
        require(config.proposedTokenLockTimeframe != 0, "LSS: New Settlement not proposed");
        require(config.changeSettlementTimelock <= block.timestamp, "LSS: Time lock in progress");
        config.tokenLockTimeframe = config.proposedTokenLockTimeframe;
        config.proposedTokenLockTimeframe = 0; 
        emit SettlementPeriodChange(_token, config.tokenLockTimeframe);
    }

    /// @notice This function activates the emergency mode
    /// @dev When a report gets generated for a token, it enters an emergency state globally.
    /// The emergency period will be active for one settlement period.
    /// During this time users can only transfer settled tokens
    /// @param _token Token on which the emergency mode must get activated
    function activateEmergency(ILERC20 _token) override external onlyLosslessEnv {
        tokenConfig[_token].emergencyMode = block.timestamp;
        emit EmergencyActive(_token);
    }

    /// @notice This function deactivates the emergency mode
    /// @param _token Token on which the emergency mode will be deactivated
    function deactivateEmergency(ILERC20 _token) override external onlyLosslessEnv {
        tokenConfig[_token].emergencyMode = 0;
        emit EmergencyDeactivation(_token);
    }

   // --- GUARD ---

    // @notice Set a guardian contract.
    // @dev Guardian contract must be trusted as it has some access rights and can modify controller's state.
    function setGuardian(address _newGuardian) override external onlyLosslessAdmin whenNotPaused {
        require(_newGuardian != address(0), "LSS: Cannot be zero address");
        emit GuardianSet(guardian, _newGuardian);
        guardian = _newGuardian;
    }

    // @notice Sets protection for an address with the choosen strategy.
    // @dev Strategies are verified in the guardian contract.
    // @dev This call is initiated from a strategy, but guardian proxies it.
    function setProtectedAddress(ILERC20 _token, address _protectedAddress, ProtectionStrategy _strategy) override external onlyGuardian whenNotPaused {
        Protection storage protection = tokenProtections[_token].protections[_protectedAddress];
        protection.isProtected = true;
        protection.strategy = _strategy;
        emit NewProtectedAddress(_token, _protectedAddress, address(_strategy));
    }

    // @notice Remove the protection from the address.
    // @dev Strategies are verified in the guardian contract.
    // @dev This call is initiated from a strategy, but guardian proxies it.
    function removeProtectedAddress(ILERC20 _token, address _protectedAddress) override external onlyGuardian whenNotPaused {
        require(isAddressProtected(_token, _protectedAddress), "LSS: Address not protected");
        delete tokenProtections[_token].protections[_protectedAddress];
        emit RemovedProtectedAddress(_token, _protectedAddress);
    }

    function _getLatestOudatedCheckpoint(LocksQueue storage queue) private view returns (uint256, uint256) {
        uint256 lower = queue.first;
        uint256 upper = queue.last;
        uint256 currentTimestamp = block.timestamp;
        uint256 center = queue.first;
        ReceiveCheckpoint memory cp = queue.lockedFunds[queue.last];
        ReceiveCheckpoint memory lowestCp = queue.lockedFunds[queue.first];

        while (upper > lower) {
            center = upper - ((upper - lower) >> 1); // ceil, avoiding overflow
            cp = queue.lockedFunds[center];
            if (cp.timestamp == currentTimestamp) {
                return (cp.cummulativeAmount, center + 1);
            } else if (cp.timestamp < currentTimestamp) {
                lowestCp = cp;
                lower = center;
            }  else {
                upper = center - 1;
                center = upper;
            }
        }

        if (lowestCp.timestamp < currentTimestamp) {
            if (cp.timestamp < lowestCp.timestamp) {
                return (cp.cummulativeAmount, center);
            } else {
                return (lowestCp.cummulativeAmount, lower);
            }
        } else {
            return (0, center);
        }
    }

    /// @notice This function will calculate the available amount that an address has to transfer. 
    /// @param _token Address corresponding to the token being held
    /// @param account Address to get the available amount
    function _getAvailableAmount(ILERC20 _token, address account) private returns (uint256 amount) {
        LocksQueue storage queue = tokenScopedLockedFunds[_token].queue[account];
        ReceiveCheckpoint storage cp = queue.lockedFunds[queue.last];
        (uint256 outdatedCummulative, uint256 newFirst) = _getLatestOudatedCheckpoint(queue);
        queue.first = newFirst;

        require(cp.cummulativeAmount >= outdatedCummulative, "LSS: Transfers limit reached");
        cp.cummulativeAmount = cp.cummulativeAmount - outdatedCummulative;
        return _token.balanceOf(account) - cp.cummulativeAmount;
    }

    // LOCKs & QUEUES

    /// @notice This function add transfers to the lock queues
    /// @param _checkpoint timestamp of the transfer
    /// @param _recipient Address to add the locks
    function _enqueueLockedFunds(ReceiveCheckpoint memory _checkpoint, address _recipient) private {
        LocksQueue storage queue;

        queue = tokenScopedLockedFunds[ILERC20(msg.sender)].queue[_recipient];

        uint256 lastItem = queue.last;
        ReceiveCheckpoint storage lastCheckpoint = queue.lockedFunds[lastItem];

        if (lastCheckpoint.timestamp < _checkpoint.timestamp) {
            // Most common scenario where the item goes at the end of the queue
            _checkpoint.cummulativeAmount = _checkpoint.amount + lastCheckpoint.cummulativeAmount;
            queue.lockedFunds[lastItem + 1] = _checkpoint;
            queue.last += 1;

        } else {
            // Second most common scenario where the timestamps are the same 
            // or new one is smaller than the latest one.
            // So the amount adds up.
            lastCheckpoint.amount += _checkpoint.amount;
            lastCheckpoint.cummulativeAmount += _checkpoint.amount;
        } 

        if (queue.first == 0) {
            queue.first += 1;
        }
    }

    // --- REPORT RESOLUTION ---

    /// @notice This function retrieves the funds of the reported account
    /// @param _addresses Array of addreses to retrieve the locked funds
    /// @param _token Token to retrieve the funds from
    /// @param _reportId Report Id related to the incident
    function retrieveBlacklistedFunds(address[] calldata _addresses, ILERC20 _token, uint256 _reportId) override public onlyLosslessEnv returns(uint256){
        uint256 totalAmount = losslessGovernance.getAmountReported(_reportId);
        
        _token.transferOutBlacklistedFunds(_addresses);
                
        (uint256 reporterReward, uint256 losslessReward, uint256 committeeReward, uint256 stakersReward) = losslessReporting.getRewards();

        uint256 toLssStaking = totalAmount * stakersReward / HUNDRED;
        uint256 toLssReporting = totalAmount * reporterReward / HUNDRED;
        uint256 toLssGovernance = totalAmount - toLssStaking - toLssReporting;

        require(_token.transfer(address(losslessStaking), toLssStaking), "LSS: Staking retrieval failed");
        require(_token.transfer(address(losslessReporting), toLssReporting), "LSS: Reporting retrieval failed");
        require(_token.transfer(address(losslessGovernance), toLssGovernance), "LSS: Governance retrieval failed");

        return totalAmount - toLssStaking - toLssReporting - (totalAmount * (committeeReward + losslessReward) / HUNDRED);
    }


    /// @notice This function will lift the locks after a certain amount
    /// @dev The condition to lift the locks is that their checkpoint should be greater than the set amount
    /// @param _availableAmount Unlocked Amount
    /// @param _account Address to lift the locks
    /// @param _amount Amount to lift
    function _removeUsedUpLocks (uint256 _availableAmount, address _account, uint256 _amount) private {
        LocksQueue storage queue;
        ILERC20 token = ILERC20(msg.sender);
        queue = tokenScopedLockedFunds[token].queue[_account];
        require(queue.touchedTimestamp + tokenConfig[token].tokenLockTimeframe <= block.timestamp, "LSS: Transfers limit reached");
        uint256 amountLeft = _amount - _availableAmount;
        ReceiveCheckpoint storage cp = queue.lockedFunds[queue.last];
        cp.cummulativeAmount -= amountLeft;
        queue.touchedTimestamp = block.timestamp;

        ReceiveCheckpoint storage firstCp = queue.lockedFunds[queue.first];
        // Consume all used up settled tokens
        if (firstCp.timestamp < block.timestamp) {
            firstCp.cummulativeAmount = 0;
        }
    }

    // --- BEFORE HOOKS ---

    /// @notice This function evaluates if the transfer can be made
    /// @param _sender Address sending the funds
    /// @param _recipient Address recieving the funds
    /// @param _amount Amount to be transfered
    function _evaluateTransfer(address _sender, address _recipient, uint256 _amount) private returns (bool) {
        ILERC20 token = ILERC20(msg.sender);

        uint256 settledAmount = _getAvailableAmount(token, _sender);
        
        TokenConfig storage config = tokenConfig[token];

        if (_amount > settledAmount) {
            require(config.emergencyMode + config.tokenLockTimeframe < block.timestamp,
                    "LSS: Emergency mode active, cannot transfer unsettled tokens");
            if (dexList[_recipient]) {
                require(_amount - settledAmount <= dexTranferThreshold,
                        "LSS: Cannot transfer over the dex threshold");
            } else { 
                _removeUsedUpLocks(settledAmount, _sender, _amount);
            }
        }

        ReceiveCheckpoint memory newCheckpoint = ReceiveCheckpoint(_amount, block.timestamp + config.tokenLockTimeframe, 0);
        _enqueueLockedFunds(newCheckpoint, _recipient);
        return true;
    }

    /// @notice If address is protected, transfer validation rules have to be run inside the strategy.
    /// @dev isTransferAllowed reverts in case transfer can not be done by the defined rules.
    function beforeTransfer(address _sender, address _recipient, uint256 _amount) override external {
        ILERC20 token = ILERC20(msg.sender);
        if (tokenProtections[token].protections[_sender].isProtected) {
            tokenProtections[token].protections[_sender].strategy.isTransferAllowed(msg.sender, _sender, _recipient, _amount);
        }

        require(!blacklist[_sender], "LSS: You cannot operate");
        
        if (tokenConfig[token].tokenLockTimeframe != 0) {
            _evaluateTransfer(_sender, _recipient, _amount);
        }
    }

    /// @notice If address is protected, transfer validation rules have to be run inside the strategy.
    /// @dev isTransferAllowed reverts in case transfer can not be done by the defined rules.
    function beforeTransferFrom(address _msgSender, address _sender, address _recipient, uint256 _amount) override external {
        ILERC20 token = ILERC20(msg.sender);

        if (tokenProtections[token].protections[_sender].isProtected) {
            tokenProtections[token].protections[_sender].strategy.isTransferAllowed(msg.sender, _sender, _recipient, _amount);
        }

        require(!blacklist[_msgSender], "LSS: You cannot operate");
        require(!blacklist[_sender], "LSS: Sender is blacklisted");

        if (tokenConfig[token].tokenLockTimeframe != 0) {
            _evaluateTransfer(_sender, _recipient, _amount);
        }

    }

    // The following before hooks are in place as a placeholder for future products.
    // Also to preserve legacy LERC20 compatibility
    
    function beforeMint(address _to, uint256 _amount) override external {}

    function beforeApprove(address _sender, address _spender, uint256 _amount) override external {}

    function beforeBurn(address _account, uint256 _amount) override external {}

    function beforeIncreaseAllowance(address _msgSender, address _spender, uint256 _addedValue) override external {}

    function beforeDecreaseAllowance(address _msgSender, address _spender, uint256 _subtractedValue) override external {}


    // --- AFTER HOOKS ---
    // * After hooks are deprecated in LERC20 but we have to keep them
    //   here in order to support legacy LERC20.

    function afterMint(address _to, uint256 _amount) external {}

    function afterApprove(address _sender, address _spender, uint256 _amount) external {}

    function afterBurn(address _account, uint256 _amount) external {}

    function afterTransfer(address _sender, address _recipient, uint256 _amount) external {}

    function afterTransferFrom(address _msgSender, address _sender, address _recipient, uint256 _amount) external {}

    function afterIncreaseAllowance(address _sender, address _spender, uint256 _addedValue) external {}

    function afterDecreaseAllowance(address _sender, address _spender, uint256 _subtractedValue) external {}
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
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILERC20 {
    function name() external view returns (string memory);
    function admin() external view returns (address);
    function getAdmin() external view returns (address);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _account) external view returns (uint256);
    function transfer(address _recipient, uint256 _amount) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint256);
    function approve(address _spender, uint256 _amount) external returns (bool);
    function transferFrom(address _sender, address _recipient, uint256 _amount) external returns (bool);
    function increaseAllowance(address _spender, uint256 _addedValue) external returns (bool);
    function decreaseAllowance(address _spender, uint256 _subtractedValue) external returns (bool);
    
    function transferOutBlacklistedFunds(address[] calldata _from) external;
    function setLosslessAdmin(address _newAdmin) external;
    function transferRecoveryAdminOwnership(address _candidate, bytes32 _keyHash) external;
    function acceptRecoveryAdminOwnership(bytes memory _key) external;
    function proposeLosslessTurnOff() external;
    function executeLosslessTurnOff() external;
    function executeLosslessTurnOn() external;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event NewAdmin(address indexed _newAdmin);
    event NewRecoveryAdminProposal(address indexed _candidate);
    event NewRecoveryAdmin(address indexed _newAdmin);
    event LosslessTurnOffProposal(uint256 _turnOffDate);
    event LosslessOff();
    event LosslessOn();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ILosslessERC20.sol";
import "./ILosslessStaking.sol";
import "./ILosslessReporting.sol";
import "./ILosslessController.sol";

interface ILssGovernance {
    function LSS_TEAM_INDEX() external view returns(uint256);
    function TOKEN_OWNER_INDEX() external view returns(uint256);
    function COMMITEE_INDEX() external view returns(uint256);
    function committeeMembersCount() external view returns(uint256);
    function walletDisputePeriod() external view returns(uint256);
    function losslessStaking() external view returns (ILssStaking);
    function losslessReporting() external view returns (ILssReporting);
    function losslessController() external view returns (ILssController);
    function isCommitteeMember(address _account) external view returns(bool);
    function getIsVoted(uint256 _reportId, uint256 _voterIndex) external view returns(bool);
    function getVote(uint256 _reportId, uint256 _voterIndex) external view returns(bool);
    function isReportSolved(uint256 _reportId) external view returns(bool);
    function reportResolution(uint256 _reportId) external view returns(bool);
    function getAmountReported(uint256 _reportId) external view returns(uint256);
    
    function setDisputePeriod(uint256 _timeFrame) external;
    function addCommitteeMembers(address[] memory _members) external;
    function removeCommitteeMembers(address[] memory _members) external;
    function losslessVote(uint256 _reportId, bool _vote) external;
    function tokenOwnersVote(uint256 _reportId, bool _vote) external;
    function committeeMemberVote(uint256 _reportId, bool _vote) external;
    function resolveReport(uint256 _reportId) external;
    function proposeWallet(uint256 _reportId, address wallet) external;
    function rejectWallet(uint256 _reportId) external;
    function retrieveFunds(uint256 _reportId) external;
    function retrieveCompensation() external;
    function claimCommitteeReward(uint256 _reportId) external;
    function setCompensationAmount(uint256 _amount) external;
    function losslessClaim(uint256 _reportId) external;

    event NewCommitteeMembers(address[] _members);
    event CommitteeMembersRemoval(address[] _members);
    event LosslessTeamPositiveVote(uint256 indexed _reportId);
    event LosslessTeamNegativeVote(uint256 indexed _reportId);
    event TokenOwnersPositiveVote(uint256 indexed _reportId);
    event TokenOwnersNegativeVote(uint256 indexed _reportId);
    event CommitteeMemberPositiveVote(uint256 indexed _reportId, address indexed _member);
    event CommitteeMemberNegativeVote(uint256 indexed _reportId, address indexed _member);
    event ReportResolve(uint256 indexed _reportId, bool indexed _resolution);
    event WalletProposal(uint256 indexed _reportId, address indexed _wallet);
    event CommitteeMemberClaim(uint256 indexed _reportId, address indexed _member, uint256 indexed _amount);
    event CommitteeMajorityReach(uint256 indexed _reportId, bool indexed _result);
    event NewDisputePeriod(uint256 indexed _newPeriod);
    event WalletRejection(uint256 indexed _reportId);
    event FundsRetrieval(uint256 indexed _reportId, uint256 indexed _amount);
    event CompensationRetrieval(address indexed _wallet, uint256 indexed _amount);
    event LosslessClaim(ILERC20 indexed _token, uint256 indexed _reportID, uint256 indexed _amount);
    event NewCompensationPercentage(uint256 indexed _compensationPercentage);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ILosslessERC20.sol";
import "./ILosslessGovernance.sol";
import "./ILosslessReporting.sol";
import "./ILosslessController.sol";

interface ILssStaking {
  function stakingToken() external returns(ILERC20);
  function losslessReporting() external returns(ILssReporting);
  function losslessController() external returns(ILssController);
  function losslessGovernance() external returns(ILssGovernance);
  function stakingAmount() external returns(uint256);
  function getVersion() external pure returns (uint256);
  function getIsAccountStaked(uint256 _reportId, address _account) external view returns(bool);
  function getStakerCoefficient(uint256 _reportId, address _address) external view returns (uint256);
  function stakerClaimableAmount(uint256 _reportId) external view returns (uint256);
  
  function pause() external;
  function unpause() external;
  function setLssReporting(ILssReporting _losslessReporting) external;
  function setStakingToken(ILERC20 _stakingToken) external;
  function setLosslessGovernance(ILssGovernance _losslessGovernance) external;
  function setStakingAmount(uint256 _stakingAmount) external;
  function stake(uint256 _reportId) external;
  function stakerClaim(uint256 _reportId) external;

  event NewStake(ILERC20 indexed _token, address indexed _account, uint256 indexed _reportId, uint256 _amount);
  event StakerClaim(address indexed _staker, ILERC20 indexed _token, uint256 indexed _reportID, uint256 _amount);
  event NewStakingAmount(uint256 indexed _newAmount);
  event NewStakingToken(ILERC20 indexed _newToken);
  event NewReportingContract(ILssReporting indexed _newContract);
  event NewGovernanceContract(ILssGovernance indexed _newContract);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ILosslessERC20.sol";
import "./ILosslessGovernance.sol";
import "./ILosslessStaking.sol";
import "./ILosslessController.sol";

interface ILssReporting {
  function reporterReward() external returns(uint256);
  function losslessReward() external returns(uint256);
  function stakersReward() external returns(uint256);
  function committeeReward() external returns(uint256);
  function reportLifetime() external view returns(uint256);
  function reportingAmount() external returns(uint256);
  function reportCount() external returns(uint256);
  function stakingToken() external returns(ILERC20);
  function losslessController() external returns(ILssController);
  function losslessGovernance() external returns(ILssGovernance);
  function getVersion() external pure returns (uint256);
  function getRewards() external view returns (uint256 _reporter, uint256 _lossless, uint256 _committee, uint256 _stakers);
  function report(ILERC20 _token, address _account) external returns (uint256);
  function reporterClaimableAmount(uint256 _reportId) external view returns (uint256);
  function getReportInfo(uint256 _reportId) external view returns(address _reporter,
        address _reportedAddress,
        address _secondReportedAddress,
        uint256 _reportTimestamps,
        ILERC20 _reportTokens,
        bool _secondReports,
        bool _reporterClaimStatus);
  
  function pause() external;
  function unpause() external;
  function setStakingToken(ILERC20 _stakingToken) external;
  function setLosslessGovernance(ILssGovernance _losslessGovernance) external;
  function setReportingAmount(uint256 _reportingAmount) external;
  function setReporterReward(uint256 _reward) external;
  function setLosslessReward(uint256 _reward) external;
  function setStakersReward(uint256 _reward) external;
  function setCommitteeReward(uint256 _reward) external;
  function setReportLifetime(uint256 _lifetime) external;
  function secondReport(uint256 _reportId, address _account) external;
  function reporterClaim(uint256 _reportId) external;
  function retrieveCompensation(address _adr, uint256 _amount) external;

  event ReportSubmission(ILERC20 indexed _token, address indexed _account, uint256 indexed _reportId, uint256 _amount);
  event SecondReportSubmission(ILERC20 indexed _token, address indexed _account, uint256 indexed _reportId);
  event NewReportingAmount(uint256 indexed _newAmount);
  event NewStakingToken(ILERC20 indexed _token);
  event NewGovernanceContract(ILssGovernance indexed _adr);
  event NewReporterReward(uint256 indexed _newValue);
  event NewLosslessReward(uint256 indexed _newValue);
  event NewStakersReward(uint256 indexed _newValue);
  event NewCommitteeReward(uint256 indexed _newValue);
  event NewReportLifetime(uint256 indexed _newValue);
  event ReporterClaim(address indexed _reporter, uint256 indexed _reportId, uint256 indexed _amount);
  event CompensationRetrieve(address indexed _adr, uint256 indexed _amount);
}

pragma solidity ^0.8.0;

interface ProtectionStrategy {
    function isTransferAllowed(address token, address sender, address recipient, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
pragma solidity ^0.8.0;

import "./ILosslessERC20.sol";
import "./ILosslessGovernance.sol";
import "./ILosslessStaking.sol";
import "./ILosslessReporting.sol";
import "./IProtectionStrategy.sol";

interface ILssController {
    // function getLockedAmount(ILERC20 _token, address _account)  returns (uint256);
    // function getAvailableAmount(ILERC20 _token, address _account) external view returns (uint256 amount);
    function retrieveBlacklistedFunds(address[] calldata _addresses, ILERC20 _token, uint256 _reportId) external returns(uint256);
    function whitelist(address _adr) external view returns (bool);
    function dexList(address _dexAddress) external returns (bool);
    function blacklist(address _adr) external view returns (bool);
    function admin() external view returns (address);
    function pauseAdmin() external view returns (address);
    function recoveryAdmin() external view returns (address);
    function guardian() external view returns (address);
    function losslessStaking() external view returns (ILssStaking);
    function losslessReporting() external view returns (ILssReporting);
    function losslessGovernance() external view returns (ILssGovernance);
    function dexTranferThreshold() external view returns (uint256);
    function settlementTimeLock() external view returns (uint256);
    
    function pause() external;
    function unpause() external;
    function setAdmin(address _newAdmin) external;
    function setRecoveryAdmin(address _newRecoveryAdmin) external;
    function setPauseAdmin(address _newPauseAdmin) external;
    function setSettlementTimeLock(uint256 _newTimelock) external;
    function setDexTransferThreshold(uint256 _newThreshold) external;
    function setDexList(address[] calldata _dexList, bool _value) external;
    function setWhitelist(address[] calldata _addrList, bool _value) external;
    function addToBlacklist(address _adr) external;
    function resolvedNegatively(address _adr) external;
    function setStakingContractAddress(ILssStaking _adr) external;
    function setReportingContractAddress(ILssReporting _adr) external; 
    function setGovernanceContractAddress(ILssGovernance _adr) external;
    function proposeNewSettlementPeriod(ILERC20 _token, uint256 _seconds) external;
    function executeNewSettlementPeriod(ILERC20 _token) external;
    function activateEmergency(ILERC20 _token) external;
    function deactivateEmergency(ILERC20 _token) external;
    function setGuardian(address _newGuardian) external;
    function removeProtectedAddress(ILERC20 _token, address _protectedAddresss) external;
    function beforeTransfer(address _sender, address _recipient, uint256 _amount) external;
    function beforeTransferFrom(address _msgSender, address _sender, address _recipient, uint256 _amount) external;
    function beforeApprove(address _sender, address _spender, uint256 _amount) external;
    function beforeIncreaseAllowance(address _msgSender, address _spender, uint256 _addedValue) external;
    function beforeDecreaseAllowance(address _msgSender, address _spender, uint256 _subtractedValue) external;
    function beforeMint(address _to, uint256 _amount) external;
    function beforeBurn(address _account, uint256 _amount) external;
    function setProtectedAddress(ILERC20 _token, address _protectedAddress, ProtectionStrategy _strategy) external;

    event AdminChange(address indexed _newAdmin);
    event RecoveryAdminChange(address indexed _newAdmin);
    event PauseAdminChange(address indexed _newAdmin);
    event GuardianSet(address indexed _oldGuardian, address indexed _newGuardian);
    event NewProtectedAddress(ILERC20 indexed _token, address indexed _protectedAddress, address indexed _strategy);
    event RemovedProtectedAddress(ILERC20 indexed _token, address indexed _protectedAddress);
    event NewSettlementPeriodProposal(ILERC20 indexed _token, uint256 _seconds);
    event SettlementPeriodChange(ILERC20 indexed _token, uint256 _proposedTokenLockTimeframe);
    event NewSettlementTimelock(uint256 indexed _timelock);
    event NewDexThreshold(uint256 indexed _newThreshold);
    event NewDex(address indexed _dexAddress);
    event DexRemoval(address indexed _dexAddress);
    event NewWhitelistedAddress(address indexed _whitelistAdr);
    event WhitelistedAddressRemoval(address indexed _whitelistAdr);
    event NewBlacklistedAddress(address indexed _blacklistedAddres);
    event AccountBlacklistRemoval(address indexed _adr);
    event NewStakingContract(ILssStaking indexed _newAdr);
    event NewReportingContract(ILssReporting indexed _newAdr);
    event NewGovernanceContract(ILssGovernance indexed _newAdr);
    event EmergencyActive(ILERC20 indexed _token);
    event EmergencyDeactivation(ILERC20 indexed _token);
}