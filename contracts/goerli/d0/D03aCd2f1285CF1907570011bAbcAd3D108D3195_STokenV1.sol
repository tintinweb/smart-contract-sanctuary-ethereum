// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "IERC20Metadata.sol";
import "Context.sol";
import "Pausable.sol";
import "Deployerable.sol";
import "Roles.sol";

/// @title STokenV1
/// @author Stobox Technologies Inc.
/// @notice Smart Contract of security token. Version 2.0
/// @dev STokenV1 is ERC20-token with additional restrictions and abilities
contract STokenV1 is Context, IERC20Metadata, Pausable, Deployerable, Roles {
    /// @notice Struct that contains all information about address of user.
    struct PersonalInfo {
        //user's wallet, appointed at the moment when user is whitelisted.
        //default value - address(0)
        address userAddress;
        //true - if address is whitelisted, otherwise - false.
        bool whitelisted;
        //true - if address has individual Secondary limit, otherwise - false.
        bool hasOwnSecondaryLimit;
        //true - if address has individual Transaction Count limit, otherwise - false.
        bool hasOwnTransactionCountLimit;
        //value of individual Secondary limit(if exists), default - 0
        uint256 individualSecondaryTradingLimit;
        //value of individual Transaction Count limit(if exists), default - 0
        uint256 individualTransactionCountLimit;
        //the total amount of all tokens ever sent by the user(address)
        uint256 outputAmount;
        //the total number of all transfers ever made by user(address)
        uint256 transactionCount;
        //dynamic array of arrays of 2 elements([0]:timestamp, [1]:blocked amount)
        uint256[2][] personalLockUps;
    }

    /// @dev service struct to get whole necessary data of User in function `getUserData()`
    ///      without this struct contract get the error:
    ///      {CompilerError: Stack too deep. Try compiling with `--via-ir` (cli) or the equivalent
    ///      `viaIR: true` (standard JSON) while enabling the optimizer.
    ///      Otherwise, try removing local variables.}
    struct ActualUserInfo {
        address userAddress;
        uint256 userBalance;
        uint256 userLockedBalance;
        bool isWhitelisted;
        uint256 leftSecondaryLimit;
        uint256 setSecondaryLimit;
        uint256 leftTransactions;
        uint256 setTransactionLimit;
        uint256 outputAmount;
        uint256 transactionCount;
        uint256[2][] lockUps;
    }

    mapping(address => uint256) private _balances;
    // mapping address of user => to its struct PersonalInfo
    mapping(address => PersonalInfo) private userData;
    mapping(address => mapping(address => uint256)) private _allowances;

    /// @notice oficial corporate wallet of the Company, to which tokens are minted and then distributed
    address private _corporateTreasury;

    /// @notice flag true - whitelist turned on, otherwise - turn off
    bool public _isEnabledWhitelist;

    /// @notice flag true - Secondary limit turned on, otherwise - turn off
    bool public _isEnabledSecondaryTradingLimit;

    /// @notice flag true - Transaction count limit turned on, otherwise - turn off
    bool public _isEnabledTransactionCountLimit;

    /// @notice The number of decimals used to get its user representation.
    ///         For example, if `decimals` equals `2`, a balance of `505` tokens should
    ///         be displayed to a user as `5.05` (`505 / 10 ** 2`).
    ///         Security Token has to have decimals = `0`
    ///         Common ERC20-Tokens usually opt for a value of 18, imitating the
    ///         relationship between Ether and Wei.
    uint8 private _decimals;

    /// @notice Total amount of emited tokens
    uint256 private _totalSupply;

    /// @notice secondary trading limit which is used for every address without individual limit
    /// (when flag `_isEnabledSecondaryTradingLimit` is true)
    uint256 private _defaultSecondaryTradingLimit;

    /// @notice transaction count limit which is used for every address without individual limit
    /// (when flag `_isEnabledTransactionCountLimit` is true)
    uint256 private _defaultTransactionCountLimit;

    /// @notice integer = 2**256 - 1
    uint256 private MAX_UINT = type(uint256).max;

    string private _name;
    string private _symbol;

    /// @notice Event emitted when `creator` whitelists `_account`
    event Whitelisted(address creator, address indexed _account);

    /// @notice Event emitted when 'creator' removes `_account` from whitelist
    event DeWhitelisted(address creator, address indexed _account);

    /// @notice Event emited when 'creator' locks `lockedAmount` of tokens
    /// on the address of `tokensOwner` until `timestampToUnlock` will come
    event LockTokens(
        address creator,
        address tokensOwner,
        uint256 timestampToUnlock,
        uint256 lockedAmount
    );

    /// @notice Event emited when locked tokens unlock
    event UnlockTokens(
        address tokensOwner,
        uint256 timestampWhenUnlocked,
        uint256 unlockedAmount
    );

    modifier onlyWhitelisted(address _account) {
        if (_isEnabledWhitelist) {
            require(
                userData[_account].whitelisted,
                "STokenV1: Not whitelisted address"
            );
        }
        _;
    }

    /// @dev in constructor, except that the values вЂ‹вЂ‹of important variables will be set,
    /// will be executed next actions:
    /// * whitelisted msg.sender(deployer of the contract),
    /// * whitelisted all addresses which will be granted roles (superAdmin,
    ///   financialManager, complianceOfficer, masterManager)
    /// * corporateTreasury will be whitelisted and it will be assigned maximum
    ///   secondary trading & transaction count limits (2**256 - 1)
    /// * financialManager will be approved to make unlimited transactions from corporateTreasury
    constructor(
        //checking of all addresses to grant roles if they have NTT

        //official corporate wallet, where tokens will be minted
        address corporateTreasury_,
        //address of Super Admin, who will have rights to assign roles (see contract {Roles})
        address _superAdmin,
        //list of addresses which will be assigned important roles (see contract {Roles}):
        //address[0] - financialManager
        //address[1] - complianceOfficer
        //address[2] - masterManager
        address[3] memory _managers,
        //flag determines whether the whitelist is enabled
        bool isEnabledWhitelist_,
        //flag determines whether the SecondaryTradingLimit is enabled
        bool isEnabledSecondaryTradingLimit_,
        //flag determines whether the TransactionCountLimit is enabled
        bool isEnabledTransactionCountLimit_,
        //name of token
        string memory name_,
        //symbol of token
        string memory symbol_,
        //value of decimals for token. For security token must be `0`
        uint8 decimals_,
        //default value of Secondary Limit
        uint256 defaultSecondaryTradingLimit_,
        //default value of Transaction Count Limit
        uint256 defaultTransactionCountLimit_
    ) Roles(_superAdmin, _managers[0], _managers[1], _managers[2]) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _corporateTreasury = corporateTreasury_;
        _isEnabledWhitelist = isEnabledWhitelist_;
        _isEnabledSecondaryTradingLimit = isEnabledSecondaryTradingLimit_;
        _isEnabledTransactionCountLimit = isEnabledTransactionCountLimit_;
        _defaultSecondaryTradingLimit = defaultSecondaryTradingLimit_;
        _defaultTransactionCountLimit = defaultTransactionCountLimit_;

        _addAddressToWhitelist(_msgSender());
        _addAddressToWhitelist(_superAdmin);
        _addAddressToWhitelist(_managers[0]);
        _addAddressToWhitelist(_managers[1]);
        _addAddressToWhitelist(_managers[2]);
        _addAddressToWhitelist(_corporateTreasury);
        _setSecondaryTradingLimitFor(_corporateTreasury, MAX_UINT);
        _setTransactionCountLimitFor(_corporateTreasury, MAX_UINT);
        _approve(_corporateTreasury, _managers[0], MAX_UINT);
    }

    /// @notice Function for first minting of tokens. Mints `_initialEmission` to `_corporateTreasury`
    /// @dev Allowed only for Deployer (see contract Deployerable)
    /// @param _initialEmission amount of tokens to mint
    function initialMint(uint256 _initialEmission) external onlyDeployer {
        _mint(_corporateTreasury, _initialEmission);
    }

    /// @notice Pauses all functions of contract which have modifier `whenNotPaused`
    /// @dev Allowed only for SuperAdmin
    function pauseContract() external onlySuperAdmin {
        _pause();
    }

    /// @notice Unpauses all functions of contract
    /// @dev Allowed only for SuperAdmin
    function unpauseContract() external onlySuperAdmin {
        _unpause();
    }

    /// @notice Moves the the corporate official wallet to another
    ///         address with all necessary changes such as:
    ///         moving the whole balance of tokens, setting proper limits for old and new treasuries
    ///         giving rights fo Financial Manager(s) to use new corporate wallet.
    /// @dev Allowed only for SuperAdmin.
    ///      `_newTreasury` can not be zero-address
    /// @param _newTreasury new address of the wallet to set.
    function replacementOfCorporateTreasury(address _newTreasury)
        external
        onlySuperAdmin
    {
        require(
            _newTreasury != address(0),
            "STokenV1: Corporate Treasury can not be zero address"
        );

        address oldTreasury = corporateTreasury();
        uint256 treasuryBalance = balanceOf(oldTreasury);

        //whitelisting of the address of new Treasury
        _addAddressToWhitelist(_newTreasury);

        //moves the whole balance of tokens from old Treasury to the new one
        _transfer(oldTreasury, _newTreasury, treasuryBalance);

        //checks if the balance of tokens was successfully moved
        require(
            balanceOf(oldTreasury) == 0 &&
                balanceOf(_newTreasury) == treasuryBalance,
            "STokenV1: balance of Treasury was not transfered to new Corporate Treasury"
        );

        //resets the limits(secondary trading and transction count) of
        //old Treasury to the default values
        userData[oldTreasury].hasOwnSecondaryLimit = false;
        userData[oldTreasury].hasOwnTransactionCountLimit = false;

        //sets the address of new Treasury as the proper parameter of smart contract
        _corporateTreasury = _newTreasury;

        //sets the maximum limits for the new Treasury (2**256-1)
        _setSecondaryTradingLimitFor(_newTreasury, MAX_UINT);
        _setTransactionCountLimitFor(_newTreasury, MAX_UINT);

        //takes away right from all Financial Managers to transfer tokens from old Treasury and
        //gives them the right for unlimited transfers from the new Treasury
        address[] memory fmList = getListOfFinancialManagers();
        for (uint256 i = 0; i < fmList.length; i++) {
            _approve(oldTreasury, fmList[i], 0);
            _approve(_corporateTreasury, fmList[i], MAX_UINT);
        }

        //removing of the address of old Treasury from whitelist
        _removeAddressFromWhitelist(oldTreasury);
    }

    /// @notice Toggle of checking whitelist, turns it on or off
    /// @dev Allowed only for SuperAdmin.
    ///      When `_isEnabledWhitelist` false, all whitelisted addresses do not lose status true-whitelisted,
    ///      but contract just doesn't check if the address whitelisted.
    /// @param _value set `true`, if you want to turn on checking of whitelist, otherwise - set `false`
    function toggleWhitelist(bool _value) external onlySuperAdmin {
        _isEnabledWhitelist = _value;
    }

    /// @notice Toggle of checking TransactionCount limit, turns it on or off
    /// @dev Allowed only for SuperAdmin.
    ///      When `_isEnabledTransactionCountLimit` false, all values
    ///      of limits(default limit or individual limits of addresses) stay saved,
    ///      but contract just doesn't check TransactionCount limit at all.
    /// @param _value set `true`, if you want to turn on checking of limit, otherwise - set `false`
    function toggleTransactionCount(bool _value) external onlySuperAdmin {
        _isEnabledTransactionCountLimit = _value;
    }

    /// @notice Toggle of checking SecondaryTrading limit, turns it on or off
    /// @dev Allowed only for SuperAdmin.
    ///      When `_isEnabledSecondaryTradingLimit` false, all values
    ///      of limits(default limit or individual limits of addresses) stay saved,
    ///      but contract just doesn't check SecondaryTrading limit at all.
    /// @param _value set `true`, if you want to turn on checking of limit, otherwise - set `false`
    function toggleSecondaryTradingLimit(bool _value) external onlySuperAdmin {
        _isEnabledSecondaryTradingLimit = _value;
    }

    /// @notice Adds `_address` to whitelist
    /// @dev Allowed only for ComplianceOfficer.
    ///      Function blocked when contract is paused.
    ///      Emits event {Whitelisted}
    /// @param _address to add to whitelist
    function addAddressToWhitelist(address _address)
        external
        whenNotPaused
        onlyComplianceOfficer
    {
        _addAddressToWhitelist(_address);
    }

    /// @notice Adds array of addresses (`_bundleAddresses`) to whitelist
    /// @dev Allowed only for ComplianceOfficer.
    ///      Function blocked when contract is paused.
    ///      Emits event {Whitelisted} for all addresses of array
    /// @param _bundleAddresses array of addresses to add to whitelist
    function addAddressToWhitelist(address[] memory _bundleAddresses)
        external
        whenNotPaused
        onlyComplianceOfficer
    {
        for (uint256 i = 0; i < _bundleAddresses.length; i++) {
            address ad = _bundleAddresses[i];
            _addAddressToWhitelist(ad);
        }
    }

    /// @notice Removes `_address` from whitelist
    /// @dev Allowed only for ComplianceOfficer.
    ///      Function blocked when contract is paused.
    ///      Emits event {DeWhitelisted}
    /// @param _address to remove from whitelist
    function removeAddressFromWhitelist(address _address)
        external
        whenNotPaused
        onlyComplianceOfficer
    {
        _removeAddressFromWhitelist(_address);
    }

    /// @notice Removes array of addresses (`_bundleAddresses`) from whitelist
    /// @dev Allowed only for ComplianceOfficer.
    ///      Function blocked when contract is paused.
    ///      Emits event {DeWhitelisted} for all addresses of array
    /// @param _bundleAddresses array of addresses to remove from whitelist
    function removeAddressFromWhitelist(address[] memory _bundleAddresses)
        external
        whenNotPaused
        onlyComplianceOfficer
    {
        for (uint256 i = 0; i < _bundleAddresses.length; i++) {
            address ad = _bundleAddresses[i];
            _removeAddressFromWhitelist(ad);
        }
    }

    /// @notice Sets the value of `_defaultSecondaryTradingLimit`.
    /// @dev Allowed only for ComplianceOfficer.
    ///      Function blocked when contract is paused.
    /// @param _newLimit the value of limit to set
    function setDefaultSecondaryTradingLimit(uint256 _newLimit)
        external
        whenNotPaused
        onlyComplianceOfficer
    {
        _defaultSecondaryTradingLimit = _newLimit;
    }

    /// @notice Sets the value of `_defaultTransactionCountLimit`.
    /// @dev Allowed only for ComplianceOfficer.
    ///      Function blocked when contract is paused.
    /// @param _newLimit the value of limit to set
    function setDefaultTransactionCountLimit(uint256 _newLimit)
        external
        whenNotPaused
        onlyComplianceOfficer
    {
        _defaultTransactionCountLimit = _newLimit;
    }

    /// @notice Sets the value of `individualSecondaryTradingLimit` for `_account` as `_newLimit`
    /// @dev Allowed only for ComplianceOfficer.
    ///      Function blocked when contract is paused.
    /// @param _account address to set new `individualSecondaryTradingLimit`
    /// @param _newLimit the value of limit to set
    function setSecondaryTradingLimitFor(address _account, uint256 _newLimit)
        external
        whenNotPaused
        onlyComplianceOfficer
    {
        _setSecondaryTradingLimitFor(_account, _newLimit);
    }

    /// @notice Sets the value of `individualSecondaryTradingLimit` for
    ///         each address from array of addresses `_bundleAccounts` as `_newLimit`
    /// @dev Allowed only for ComplianceOfficer.
    ///      Function blocked when contract is paused.
    /// @param _bundleAccounts array of addresses to set new `individualSecondaryTradingLimit`
    /// @param _newLimit the value of limit to set
    function setSecondaryTradingLimitFor(
        address[] memory _bundleAccounts,
        uint256 _newLimit
    ) external whenNotPaused onlyComplianceOfficer {
        _bundlesLoop(_bundleAccounts, _newLimit, _setSecondaryTradingLimitFor);
    }

    /// @notice Sets the value of `individualSecondaryTradingLimit` for
    ///         each address from array of addresses `_bundleAccounts` as
    ///         the value from array of numbers `_bundleNewLimits`
    /// @dev Allowed only for ComplianceOfficer.
    ///      Function blocked when contract is paused.
    ///      Address => value set according to indexes of arrays:
    ///      [0]indexed address will have [0]indexed value of limit,
    ///      [1]indexed address will have [1]indexed value of limit and so on
    /// @param _bundleAccounts array of addresses to set new `individualSecondaryTradingLimit`
    /// @param _bundleNewLimits array of the values of limit to set.
    function setSecondaryTradingLimitFor(
        address[] memory _bundleAccounts,
        uint256[] memory _bundleNewLimits
    ) external whenNotPaused onlyComplianceOfficer {
        _bundlesLoop(
            _bundleAccounts,
            _bundleNewLimits,
            _setSecondaryTradingLimitFor
        );
    }

    /// @notice Sets the value of `individualTransactionCountLimit` for `_account` as `_newLimit`
    /// @dev Allowed only for ComplianceOfficer.
    ///      Function blocked when contract is paused.
    /// @param _account address to set new `individualTransactionCountLimit`
    /// @param _newLimit the value of limit to set
    function setTransactionCountLimitFor(address _account, uint256 _newLimit)
        external
        whenNotPaused
        onlyComplianceOfficer
    {
        _setTransactionCountLimitFor(_account, _newLimit);
    }

    /// @notice Sets the value of `individualTransactionCountLimit` for
    ///         each address from array of addresses `_bundleAccounts` as `_newLimit`
    /// @dev Allowed only for ComplianceOfficer.
    ///      Function blocked when contract is paused.
    /// @param _bundleAccounts array of addresses to set new `individualTransactionCountLimit`
    /// @param _newLimit the value of limit to set
    function setTransactionCountLimitFor(
        address[] memory _bundleAccounts,
        uint256 _newLimit
    ) external whenNotPaused onlyComplianceOfficer {
        _bundlesLoop(_bundleAccounts, _newLimit, _setTransactionCountLimitFor);
    }

    /// @notice Sets the value of `individualTransactionCountLimit` for
    ///         each address from array of addresses `_bundleAccounts` as
    ///         the value from array of numbers `_bundleNewLimits`
    /// @dev Allowed only for ComplianceOfficer.
    ///      Function blocked when contract is paused.
    ///      Address => value set according to indexes of arrays:
    ///      [0]indexed address will have [0]indexed value of limit,
    ///      [1]indexed address will have [1]indexed value of limit and so on
    /// @param _bundleAccounts array of addresses to set new `individualTransactionCountLimit`
    /// @param _bundleNewLimits array of the values of limit to set.
    function setTransactionCountLimitFor(
        address[] memory _bundleAccounts,
        uint256[] memory _bundleNewLimits
    ) external whenNotPaused onlyComplianceOfficer {
        _bundlesLoop(
            _bundleAccounts,
            _bundleNewLimits,
            _setTransactionCountLimitFor
        );
    }

    /// @notice After calling this function the {_defaultSecondaryTradingLimit}
    ///         will apply to `_account` instead of its {individualSecondaryTradingLimit} (if it was)
    /// @dev Allowed only for ComplianceOfficer.
    ///      Function blocked when contract is paused.
    ///      Function just changes flag {hasOwnSecondaryLimit} to `false` for the `_account`
    ///      and contract will ignore value which is set in the parametr {individualSecondaryTradingLimit}
    /// @param _account address to reset limit to default
    function resetSecondaryTradingLimitToDefault(address _account)
        external
        whenNotPaused
        onlyComplianceOfficer
    {
        userData[_account].hasOwnSecondaryLimit = false;
    }

    /// @notice After calling this function the {_defaultSecondaryTradingLimit}
    ///         will apply to addresses from array `_accountsToReset`
    ///         instead of there {individualSecondaryTradingLimit} (if they had it)
    /// @dev Allowed only for ComplianceOfficer.
    ///
    /// @param _accountsToReset array of addresses to reset limit to default
    function resetSecondaryTradingLimitToDefault(
        address[] memory _accountsToReset
    ) external whenNotPaused onlyComplianceOfficer {
        for (uint256 i = 0; i < _accountsToReset.length; i++) {
            userData[_accountsToReset[i]].hasOwnSecondaryLimit = false;
        }
    }

    /// @notice After calling this function the {_defaultTransactionCountLimit}
    ///         will apply to `_account` instead of its {individualTransactionCountLimit} (if it was)
    /// @dev Allowed only for ComplianceOfficer.
    ///      Function blocked when contract is paused.
    ///      Function just changes flag {hasOwnTransactionCountLimit} to `false` for the `_account`
    ///      and contract will ignore value which is set in the parametr {individualTransactionCountLimit}
    /// @param _account address to reset limit to default
    function resetTransactionCountLimitToDefalt(address _account)
        external
        whenNotPaused
        onlyComplianceOfficer
    {
        userData[_account].hasOwnTransactionCountLimit = false;
    }

    /// @notice After calling this function the {_defaultSecondaryTradingLimit}
    ///         will apply to addresses from array `_accountsToReset`
    ///         instead of there {individualTransactionCountLimit} (if they had it)
    /// @dev Allowed only for ComplianceOfficer.
    ///      Function blocked when contract is paused.
    ///      Function just changes flag {hasOwnTransactionCountLimit} to `false`
    ///      for the addresses from `_accountsToReset`
    ///      and contract will ignore value which is set in
    ///      the parametr {individualTransactionCountLimit} for each account from array
    /// @param _accountsToReset array of addresses to reset limit to default
    function resetTransactionCountLimitToDefalt(
        address[] memory _accountsToReset
    ) external whenNotPaused onlyComplianceOfficer {
        for (uint256 i = 0; i < _accountsToReset.length; i++) {
            userData[_accountsToReset[i]].hasOwnTransactionCountLimit = false;
        }
    }

    /// @notice Mints `_amount` of tokens to the address `_to`
    /// @dev Allowed only for MasterManager
    /// @param _to address to mint on it tokens
    /// @param _amount amount of tokens to mint
    function mint(address _to, uint256 _amount) external onlyMasterManager {
        _mint(_to, _amount);
    }

    /// @notice Burns `_amount` of tokens from the address `_from`
    /// @dev Allowed only for MasterManager
    /// @param _from address to burn tokens from
    /// @param _amount amount of tokens to burn
    function burn(address _from, uint256 _amount) external onlyMasterManager {
        _burn(_from, _amount);
    }

    /// @notice Burns `_amount` of tokens from all addresses of the array of addresses `_bundleFrom`
    /// @dev Allowed only for MasterManager
    /// @param _bundleFrom array of addresses to burn tokens from
    /// @param _amount amount of tokens to burn from each address of the array
    function burn(address[] memory _bundleFrom, uint256 _amount)
        external
        onlyMasterManager
    {
        _bundlesLoop(_bundleFrom, _amount, _burn);
    }

    /// @notice Burns amounts of tokens from the array `_bundleAmounts`
    ///         from the addresses of the array of addresses `_bundleFrom`
    /// @dev Allowed only for MasterManager
    ///      Address => value burnt according to indexes of arrays:
    ///      from [0]indexed address will be burnt [0]indexed amount of tokens,
    ///      from [1]indexed address will be burnt [1]indexed amount of tokens and so on
    /// @param _bundleFrom array of addresses to burn tokens from
    /// @param _bundleAmounts array of amounts of tokens to burn
    function burn(address[] memory _bundleFrom, uint256[] memory _bundleAmounts)
        external
        onlyMasterManager
    {
        _bundlesLoop(_bundleFrom, _bundleAmounts, _burn);
    }

    /// @notice Burns whole balance of tokens from the address `_from`
    /// @dev Allowed only for MasterManager
    /// @param _from address to burn tokens from
    function redemption(address _from)
        external
        onlyMasterManager
        returns (bool)
    {
        uint256 amountToBurn = balanceOf(_from);
        _burn(_from, amountToBurn);
        return true;
    }

    /// @notice Burns whole balance of tokens from all addresses of the array of addresses `_bundleFrom`
    /// @dev Allowed only for MasterManager
    /// @param _bundleFrom array of addresses to burn tokens from
    function redemption(address[] memory _bundleFrom)
        external
        onlyMasterManager
        returns (bool)
    {
        for (uint256 i = 0; i < _bundleFrom.length; i++) {
            uint256 amountToBurn = balanceOf(_bundleFrom[i]);
            _burn(_bundleFrom[i], amountToBurn);
        }
        return true;
    }

    /// @notice This function can move `_amount` of tokens from
    ///         any `_from` address to any whitelisted `_to` address
    /// @dev Allowed only for MasterManager.
    ///      Addresses `_from` and `_to` can not be zero-addresses.
    /// @param _from address from which tokens will be transfered
    /// @param _to address where tokens will be transfered
    /// @param _amount of tokens to transfer
    function transferFunds(
        address _from,
        address _to,
        uint256 _amount
    ) external onlyMasterManager onlyWhitelisted(_to) {
        require(
            _from != address(0),
            "STokenV1: transfer from the zero address"
        );
        require(_to != address(0), "STokenV1: transfer to the zero address");

        uint256 fromBalance = _balances[_from];
        require(
            fromBalance >= _amount,
            "STokenV1: transfer amount exceeds balance"
        );
        unchecked {
            _balances[_from] = fromBalance - _amount;
            _balances[_to] += _amount;
        }
        emit Transfer(_from, _to, _amount);
    }

    /// @notice This function can release ERC20-tokens `_tokensToWithdraw`, which
    ///         got stuck in this smart contract (were transferred here by the mistake)
    /// @dev Allowed only for SuperAdmin.
    ///      Transfers all balance of stuck `_tokensToWithdraw` from
    ///      this contract to {_corporateTreasury} wallet
    /// @param _tokensToWithdraw address of ERC20-token to withdraw
    function withdrawStuckTokens(address _tokensToWithdraw)
        external
        onlySuperAdmin
    {
        address from = address(this);
        uint256 amount = IERC20(_tokensToWithdraw).balanceOf(from);
        IERC20(_tokensToWithdraw).transfer(_corporateTreasury, amount);
    }

    /// @notice Transfers `_amount` of tokens from {_corporateTreasury} to `_to` address
    /// @dev Allowed only for FinancialManager.
    ///      Function blocked when contract is paused.
    ///      To be able to call this function FinancialManager has
    ///      to be given unlimited {approve} from {_corporateTreasury}
    /// @param _to address which will receive tokens
    /// @param _amount amount of tokens to transfer
    /// @return true if function passed successfully
    function transferFromTreasuryToInvestor(address _to, uint256 _amount)
        external
        whenNotPaused
        onlyFinancialManager
        returns (bool)
    {
        transferFrom(_corporateTreasury, _to, _amount);
        return true;
    }

    /// @notice Transfers `_amount` of tokens from {_corporateTreasury} to
    ///         all addresses from array of addresses `_bundleTo`
    /// @dev Allowed only for FinancialManager.
    ///      Function blocked when contract is paused.
    ///      To be able to call this function FinancialManager has
    ///      to be given unlimited {approve} from {_corporateTreasury}
    /// @param _bundleTo array of addresses which will receive tokens
    /// @param _amount amount of tokens to transfer
    /// @return true if function passed successfully
    function transferFromTreasuryToInvestor(
        address[] memory _bundleTo,
        uint256 _amount
    ) external whenNotPaused onlyFinancialManager returns (bool) {
        _bundlesLoop(_corporateTreasury, _bundleTo, _amount, _transfer);
        return true;
    }

    /// @notice Transfers amounts from array `_bundleAmounts` of tokens from {_corporateTreasury}
    ///          to all addresses from array of addresses `_bundleTo`
    /// @dev Allowed only for FinancialManager.
    ///      Function blocked when contract is paused.
    ///      To be able to call this function FinancialManager has
    ///      to be given unlimited {approve} from {_corporateTreasury}
    ///      Address => value are transferred according to indexes of arrays:
    ///      [0]indexed amount of tokens will be transferred to [0]indexed address,
    ///      [1]indexed amount of tokens will be transferred to [1]indexed address and so on
    /// @param _bundleTo array of addresses which will receive tokens
    /// @param _bundleAmounts array of amounts of tokens to transfer
    /// @return true if function passed successfully
    function transferFromTreasuryToInvestor(
        address[] memory _bundleTo,
        uint256[] memory _bundleAmounts
    ) external whenNotPaused onlyFinancialManager returns (bool) {
        _bundlesLoop(_corporateTreasury, _bundleTo, _bundleAmounts, _transfer);
        return true;
    }

    /// @notice Transfers `_amount` of tokens from {_corporateTreasury} to `_to` address
    ///         and at one time locks these tokens for the `_daysToLock` quantity of days
    /// @dev Allowed only for FinancialManager.
    ///      Function blocked when contract is paused.
    ///      To be able to call this function FinancialManager has
    ///      to be given unlimited {approve} from {_corporateTreasury}
    ///      The proper pair of data: ([0]timestamp when tokens can be unlocked & [1]`_amount`)
    ///      is written to the parametr of account: {personalLockUps}
    /// @param _to address which will receive tokens and on which they will be locked
    /// @param _amount amount of tokens to transfer & lock
    /// @param _daysToLock the quantity of days you want to lock tokens for
    /// @return true if function passed successfully
    function transferFromTreasuryLockedTokens(
        address _to,
        uint256 _amount,
        uint256 _daysToLock
    ) external whenNotPaused onlyFinancialManager returns (bool) {
        _lockAndTransfer(_corporateTreasury, _to, _amount, _daysToLock);
        return true;
    }

    /// @notice Transfers `_amount` of tokens from {_corporateTreasury} to addresses
    ///         from array of addresses `_bundleTo`
    ///         and at one time locks these tokens for the `_daysToLock` quantity of days
    /// @dev Allowed only for FinancialManager.
    ///      Function blocked when contract is paused.
    ///      To be able to call this function FinancialManager has
    ///      to be given unlimited {approve} from {_corporateTreasury}
    ///      The proper pair of data: (timestamp when tokens can be unlocked & `_amount`)
    ///      is written to the parametr of account: {personalLockUps} for each account from the array
    /// @param _bundleTo array of addresses which will receive tokens and on which they will be locked
    /// @param _amount amount of tokens to transfer & lock
    /// @param _daysToLock the quantity of days you want to lock tokens for
    /// @return true if function passed successfully
    function transferFromTreasuryLockedTokens(
        address[] memory _bundleTo,
        uint256 _amount,
        uint256 _daysToLock
    ) external whenNotPaused onlyFinancialManager returns (bool) {
        for (uint256 i = 0; i < _bundleTo.length; i++) {
            _lockAndTransfer(
                _corporateTreasury,
                _bundleTo[i],
                _amount,
                _daysToLock
            );
        }
        return true;
    }

    /// @notice Transfers amount of tokens from array `_bundleAmounts` from {_corporateTreasury}
    ///         to addresses from array of addresses `_bundleTo`
    ///         and at one time locks these tokens for the `_daysToLock` quantity of days
    /// @dev Allowed only for FinancialManager.
    ///      Function blocked when contract is paused.
    ///      To be able to call this function FinancialManager has
    ///      to be given unlimited {approve} from {_corporateTreasury}
    ///      The proper pair of data: (timestamp when tokens can be unlocked & proper
    ///      amount from `_bundleAmounts`) is written to
    ///      the parametr of account: {personalLockUps} for each account from the array
    ///      Address => value transferred and locked according to indexes of arrays:
    ///      to [0]indexed address will be transferred and locked [0]indexed amount of tokens,
    ///      to [1]indexed address will be transferred and locked [1]indexed amount of tokens and so on
    /// @param _bundleTo array of addresses which will receive tokens and on which they will be locked
    /// @param _bundleAmounts array of amounts of tokens to transfer & lock
    /// @param _daysToLock the quantity of days you want to lock tokens for
    /// @return true if function passed successfully
    function transferFromTreasuryLockedTokens(
        address[] memory _bundleTo,
        uint256[] memory _bundleAmounts,
        uint256 _daysToLock
    ) external whenNotPaused onlyFinancialManager returns (bool) {
        _equalArrays(_bundleTo, _bundleAmounts);
        for (uint256 i = 0; i < _bundleTo.length; i++) {
            _lockAndTransfer(
                _corporateTreasury,
                _bundleTo[i],
                _bundleAmounts[i],
                _daysToLock
            );
        }
        return true;
    }

    /// @notice Locks `_amountToLock` of tokens on `_account` address
    ///         for the `_daysToLock` quantity of days
    /// @dev Allowed only for FinancialManager.
    ///      Function blocked when contract is paused.
    ///      The proper pair of data: ([0]timestamp when tokens can be unlocked & [1]`_amountToLock`)
    ///      is written to the parametr of account: {personalLockUps}
    ///      Function checks the opportunity to lock `_amountToLock`=> see
    ///      comments to function {_checkAmountToLock} to know how is it checked.
    ///      And lock `_amountToLock` of tokens or the whole available balance of `_account`.
    /// @param _account address on which tokens will be locked
    /// @param _amountToLock amount of tokens to lock
    /// @param _daysToLock the quantity of days you want to lock tokens for
    /// @return true if function passed successfully
    function lockUpTokensOnAddress(
        address _account,
        uint256 _amountToLock,
        uint256 _daysToLock
    ) external whenNotPaused onlyFinancialManager returns (bool) {
        _lockTokens(
            _account,
            _checkAmountToLock(_account, _amountToLock),
            _daysToLock
        );
        return true;
    }

    /// @notice Locks `_amountToLock` of tokens on account from the array of
    ///         addresses `_bundleTo` for the `_daysToLock` quantity of days
    /// @dev Allowed only for FinancialManager.
    ///      Function blocked when contract is paused.
    ///      The proper pair of data: ([0]timestamp when tokens can be unlocked & [1]`_amountToLock`)
    ///      is written to the parametr of account: {personalLockUps} for each account from the array
    ///      Function checks the opportunity to lock `_amountToLock`=> see
    ///      comments to function {_checkAmountToLock} to know how is it checked.
    ///      And lock `_amountToLock` of tokens or the whole available balance of account from `_bundleTo`.
    /// @param _bundleTo array of addresses on which tokens will be locked
    /// @param _amountToLock amount of tokens to lock
    /// @param _daysToLock the quantity of days you want to lock tokens for
    /// @return true if function passed successfully
    function lockUpTokensOnAddress(
        address[] memory _bundleTo,
        uint256 _amountToLock,
        uint256 _daysToLock
    ) external whenNotPaused onlyFinancialManager returns (bool) {
        for (uint256 i = 0; i < _bundleTo.length; i++) {
            _lockTokens(
                _bundleTo[i],
                _checkAmountToLock(_bundleTo[i], _amountToLock),
                _daysToLock
            );
        }
        return true;
    }

    /// @notice Locks amount of tokens from `_bundleAmounts` on account from the array of
    ///         addresses `_bundleTo` for the `_daysToLock` quantity of days
    /// @dev Allowed only for FinancialManager.
    ///      Function blocked when contract is paused.
    ///      The proper pair of data: ([0]timestamp when tokens can be unlocked & [1]locked amount of token)
    ///      is written to the parametr of account: {personalLockUps} for each account from the array
    ///      Function checks the opportunity to lock `_amountToLock`=> see
    ///      comments to function {_checkAmountToLock} to know how is it checked.
    ///      And lock amount from `_bundleAmounts` of tokens or the
    ///      whole available balance of account from `_bundleTo`.
    ///      Address => value locked according to indexes of arrays:
    ///      on [0]indexed address will be locked [0]indexed amount of tokens,
    ///      on [1]indexed address will be locked [1]indexed amount of tokens and so on
    /// @param _bundleTo array of addresses on which tokens will be locked
    /// @param _bundleAmounts array of amounts of tokens to lock
    /// @param _daysToLock the quantity of days you want to lock tokens for
    /// @return true if function passed successfully
    function lockUpTokensOnAddress(
        address[] memory _bundleTo,
        uint256[] memory _bundleAmounts,
        uint256 _daysToLock
    ) external whenNotPaused onlyFinancialManager returns (bool) {
        _equalArrays(_bundleTo, _bundleAmounts);
        for (uint256 i = 0; i < _bundleTo.length; i++) {
            _lockTokens(
                _bundleTo[i],
                _checkAmountToLock(_bundleTo[i], _bundleAmounts[i]),
                _daysToLock
            );
        }
        return true;
    }

    /// @notice Checks is `_address` whitelisted
    /// @return true if `_address` whitelisted and false, if not
    function isWhitelistedAddress(address _address)
        external
        view
        returns (bool)
    {
        return userData[_address].whitelisted;
    }

    /// @notice Returns the personal data of `_account`
    ///         returns the array with next data of this account:
    /// *userAddress,
    /// *whole user Balance of tokens,
    /// *amount of Locked tokens of user,
    /// *is address whitelisted(true/false),
    /// *left Secondary Limit for account (user can spend yet),
    /// *SecondaryLimit which is set for this account,
    /// *left Transaction Limit for account (user can spend yet),
    /// *TransactionCountLimit which is set for this account,
    /// *outputAmount of tokens,
    /// *transactionCount of transfers,
    /// *personalLockUps - array of arrays of 2 elements([0]:timestamp, [1]:blocked amount)
    function getUserData(address _account)
        external
        view
        returns (ActualUserInfo memory)
    {
        ActualUserInfo memory actualInfo;
        actualInfo = ActualUserInfo(
            _account,
            balanceOf(_account),
            getAmountOfLockedTokens(_account),
            userData[_account].whitelisted,
            getAllowedToTransfer(_account),
            secondaryTradingLimitOf(_account),
            getLeftTransactionCountLimit(_account),
            transactionCountLimitOf(_account),
            userData[_account].outputAmount,
            userData[_account].transactionCount,
            userData[_account].personalLockUps
        );

        return actualInfo;
    }

    /// @notice Grant Financial Manager role to `_address`
    /// @dev Requirements:caller must have SuperAdmin role
    ///      May emit a {RoleGranted} event.
    ///      `_address` is given unlimited {approve} from
    ///      {_corporateTreasury}
    /// @param _address address to grant Manager role
    function addFinancialManager(address _address)
        external
        override
        onlySuperAdmin
    {
        _grantRole(FINANCIAL_MANAGER_ROLE, _address);
        _approve(_corporateTreasury, _address, MAX_UINT);
    }

    /// @notice Revokes Financial Manager role from `_address`
    /// @dev If `_address` had been revoked Financial Manager role, emits a {RoleRevoked} event
    ///      Requirements:the caller must have SuperAdmin role
    ///      Revokes allowance to transfer tokens from Treasury for `_address`
    /// @param _address address to revoke Manager role from it
    function removeFinancialManager(address _address)
        external
        override
        onlySuperAdmin
    {
        _revokeRole(FINANCIAL_MANAGER_ROLE, _address);
        _approve(_corporateTreasury, _address, 0);
    }

    /// @notice Returns the name of the token.
    function name() public view returns (string memory) {
        return _name;
    }

    /// @notice Returns the symbol of the token, usually a shorter version of the name.
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /// @notice Returns the number of decimals of token
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /// @notice Returns the amount of tokens in existence.
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /// @notice Returns the amount of tokens owned by `_account`.
    function balanceOf(address _account) public view returns (uint256) {
        return _balances[_account];
    }

    /// @notice Returns the value of the default Secondary Trading limit
    function defaultSecondaryTradingLimit() public view returns (uint256) {
        return _defaultSecondaryTradingLimit;
    }

    /// @notice Returns the value of the default Transaction Count limit
    function defaultTransactionCountLimit() public view returns (uint256) {
        return _defaultTransactionCountLimit;
    }

    /// @notice Returns the address of the official corporate wallet
    function corporateTreasury() public view returns (address) {
        return _corporateTreasury;
    }

    /// @notice Returns the array of pairs of locked tokens and their timestamps to
    ///         be unlocked for the `_account`
    /// @dev Array of arrays of 2 elements([0]:timestamp, [1]:blocked amount)
    function getListOfLockUps(address _account)
        public
        view
        returns (uint256[2][] memory)
    {
        return userData[_account].personalLockUps;
    }

    /// @notice Returns the whole value of all locked tokens on the `_account`
    /// @dev Function gets the list of all LockUps on the `_account` (see {getListOfLockUps}),
    ///      loops through the pairs, checks whether the
    ///      required timestamp has not yet arrived and if not - adds the amounts
    /// @param _account address to find out locked amount of tokens
    /// @return (the) sum of amounts of locked tokens of all lockUps on this address
    function getAmountOfLockedTokens(address _account)
        public
        view
        returns (uint256)
    {
        uint256 result = 0;
        uint256[2][] memory lockUps = getListOfLockUps(_account);
        uint256 len = lockUps.length;

        if (len == 0) {
            return result;
        } else {
            for (uint256 i = 0; i < len; i++) {
                if (lockUps[i][0] >= block.timestamp) {
                    result += lockUps[i][1];
                }
            }
            return result;
        }
    }

    /// @notice Returns the value of amount of tokens which `_account`
    ///         can spend(transfer) this moment
    /// @dev Function takes two numbers: {_availableBalance} & {_availableLimit}
    ///      and compaire them.
    ///      {_availableBalance} - subtracts from the total balance value of lockUps
    ///      {_availableLimit} - returns currently available limit for this address
    ///      Then returns the smaller value.
    function getAllowedToTransfer(address _account)
        public
        view
        returns (uint256 result)
    {
        _availableBalance(_account) < _availableLimit(_account)
            ? result = _availableBalance(_account)
            : result = _availableLimit(_account);
    }

    /// @notice Returns the available number of transfers `_account` can do yet
    /// @dev The function gets two values:
    ///      {transactionCountLimitOf} - the current limit of transfers for the `_account`
    ///      {PersonalInfo.transactionCount} - the number of transfers which `_account` already has made.
    ///      Function returns the substraction: (current limit - made transfers) or revert
    ///      with proper message, if the `_account` doesn't have avalaible limit.
    /// @param _account address to find out its limit
    function getLeftTransactionCountLimit(address _account)
        public
        view
        returns (uint256)
    {
        uint256 limit = transactionCountLimitOf(_account);
        require(
            userData[_account].transactionCount < limit,
            "STokenV1: This account has no available Transaction Count Limit"
        );
        return limit - userData[_account].transactionCount;
    }

    /// @notice Returns the value of the Secondary Trading limit that applies to this '_account'
    /// @dev The function makes several steps of verification:
    ///      * Checks if the control of Secondary Limits turned on:
    ///        the flag {_isEnabledSecondaryTradingLimit}
    ///        is false - returns {MAX_UINT}
    ///        is true:
    ///
    ///          * Checks if the `_account` {hasOwnSecondaryLimit}:
    ///            if true - returns PersonalInfo.individualSecondaryTradingLimit of `_account`
    ///            if false - returns {_defaultSecondaryTradingLimit}
    /// @param _account address to find out the value of its current Secondary Trading limit
    function secondaryTradingLimitOf(address _account)
        public
        view
        returns (uint256)
    {
        if (_isEnabledSecondaryTradingLimit) {
            if (userData[_account].hasOwnSecondaryLimit) {
                return userData[_account].individualSecondaryTradingLimit;
            } else {
                return _defaultSecondaryTradingLimit;
            }
        }
        return MAX_UINT;
    }

    /// @notice Returns the value of the Transaction Count limit that applies to this '_account'
    /// @dev The function makes several steps of verification:
    ///      * Checks if the control of Transaction Count limit turned on:
    ///        the flag {_isEnabledTransactionCountLimit}
    ///        is false - returns {MAX_UINT}
    ///        is true:
    ///
    ///          * Checks if the `_account` {hasOwnTransactionCountLimit}:
    ///            if true - returns PersonalInfo.individualTransactionCountLimit of `_account`
    ///            if false - returns {_defaultTransactionCountLimit}
    /// @param _account address to find out the value of its current Transaction Count limit
    function transactionCountLimitOf(address _account)
        public
        view
        returns (uint256)
    {
        if (_isEnabledTransactionCountLimit) {
            if (userData[_account].hasOwnTransactionCountLimit) {
                return userData[_account].individualTransactionCountLimit;
            } else {
                return _defaultTransactionCountLimit;
            }
        }
        return MAX_UINT;
    }

    /// @notice Updates the lockUps of the `_account` according to timestamps.
    ///         If the time to unlock certain amount of tokens has come,
    ///         it makes these tokens "free".
    /// @dev Function loops through the array of pairs with data about locked tokens:
    ///      {PersonalInfo.personalLockUps}
    ///      If the [0]indexed parametr of pair (timestamp to unlock) is less then current
    ///      timestamp - {block.timestamp} => it will be deleted from the array
    ///      and the [1]indexed amount of tokens will be unlocked in such a way
    ///      and Event {UnlockTokens} emits.
    ///      Otherwise - this pair is passed and tokens stay locked.
    /// @param _account address to update its LockUps
    /// @return true if function passed successfully
    function updateDataOfLockedTokensOf(address _account)
        public
        returns (bool)
    {
        uint256[2][] storage lockUps = userData[_account].personalLockUps;
        uint256 len = lockUps.length;
        if (len == 0) {
            return true;
        } else {
            for (uint256 i = 0; i < len; i++) {
                if (lockUps[i][0] < block.timestamp) {
                    lockUps[i] = lockUps[len - 1];
                    lockUps.pop();
                    len = lockUps.length;

                    emit UnlockTokens(_account, block.timestamp, lockUps[i][1]);
                }
            }
            return true;
        }
    }

    /// @notice Moves `_amount` of tokens from the caller's account to `_to` address.
    /// @dev Emits a {Transfer} event.
    ///      Function blocked when contract is paused.
    ///      Function has a number of checks and conditions - see {_transfer} internal function.
    /// @return true if function passed successfully
    function transfer(address _to, uint256 _amount)
        public
        whenNotPaused
        returns (bool)
    {
        address owner = _msgSender();
        _transfer(owner, _to, _amount);
        return true;
    }

    /// @notice Moves `_amount` of tokens from the caller's account to each address
    ///         from array of  addresses `_bundleTo`.
    /// @dev Emits a {Transfer} event for each transfer of this multi-sending function.
    ///      Function blocked when contract is paused.
    ///      Function has a number of checks and conditions - see {_transfer} internal function.
    /// @param _bundleTo array of addresses which will get tokens
    /// @return true if function passed successfully
    function transfer(address[] memory _bundleTo, uint256 _amount)
        public
        whenNotPaused
        returns (bool)
    {
        address owner = _msgSender();
        _bundlesLoop(owner, _bundleTo, _amount, _transfer);
        return true;
    }

    /// @notice Moves `_amount` of tokens from the array of amounts `_bundleAmounts` from
    ///         the caller's account to each address
    ///         from array of  addresses `_bundleTo`.
    /// @dev Emits a {Transfer} event for each transfer of this multi-sending function.
    ///      Function blocked when contract is paused.
    ///      Function has a number of checks and conditions - see {_transfer} internal function.
    ///      Address => value transferred according to indexes of arrays:
    ///      to [0]indexed address will be sent [0]indexed amount of tokens,
    ///      to [1]indexed address will be sent [1]indexed amount of tokens and so on
    /// @param _bundleTo array of addresses which will get tokens
    /// @param _bundleAmounts array of amounts to transfer
    /// @return true if function passed successfully
    function transfer(
        address[] memory _bundleTo,
        uint256[] memory _bundleAmounts
    ) public whenNotPaused returns (bool) {
        address owner = _msgSender();
        _bundlesLoop(owner, _bundleTo, _bundleAmounts, _transfer);
        return true;
    }

    /// @dev Returns the remaining number of tokens that `_spender` will be
    ///      allowed to spend on behalf of `_owner` through {transferFrom}. This is
    ///      zero by default.
    ///      This value changes when {approve} or {transferFrom} are called.
    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256)
    {
        return _allowances[_owner][_spender];
    }

    /// @notice Sets `_amount` as the allowance of `_spender` over the caller's tokens.
    ///         Returns a boolean value indicating whether the operation succeeded.
    /// @dev IMPORTANT: Beware that changing an allowance with this method brings the risk
    ///      that someone may use both the old and the new allowance by unfortunate
    ///      transaction ordering. One possible solution to mitigate this race
    ///      condition is to first reduce the spender's allowance to 0 and set the
    ///      desired value afterwards.
    ///
    ///      Function blocked when contract is paused.
    ///      Emits an {Approval} event.
    ///      Function has a number of checks and conditions - see {_approve} internal function.
    function approve(address _spender, uint256 _amount)
        public
        whenNotPaused
        returns (bool)
    {
        address owner = _msgSender();
        _approve(owner, _spender, _amount);
        return true;
    }

    /// @notice Moves `_amount` of tokens from `_from` to `_to` using the allowance mechanism.
    ///         `_amount` is then deducted from the caller's allowance.
    ///         Returns a boolean value indicating whether the operation succeeded.
    /// @dev Function blocked when contract is paused.
    ///      Emits a {Transfer} event.
    ///      Function has a number of checks and conditions - see:
    ///      {_transfer} & {_spendAllowance} internal function.
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) public whenNotPaused returns (bool) {
        address spender = _msgSender();
        _spendAllowance(_from, spender, _amount);
        _transfer(_from, _to, _amount);
        return true;
    }

    /// @notice Increases the allowance granted to `_spender` by the caller.
    /// @dev This is an alternative to {approve} that can be used as a mitigation for
    ///      problems described in {approve}.
    ///      Function blocked when contract is paused.
    ///      Emits an {Approval} event indicating the updated allowance.
    ///      Function has a number of checks and conditions - see {_approve} internal function.
    ///      Requirements:
    ///      `spender` cannot be the zero address.
    function increaseAllowance(address _spender, uint256 _addedValue)
        public
        whenNotPaused
        returns (bool)
    {
        address owner = _msgSender();
        _approve(owner, _spender, allowance(owner, _spender) + _addedValue);
        return true;
    }

    /// @notice Decreases the allowance granted to `_spender` by the caller.
    /// @dev This is an alternative to {approve} that can be used as a mitigation for
    ///      problems described in {approve}.
    ///      Function blocked when contract is paused.
    ///      Emits an {Approval} event indicating the updated allowance.
    ///      Function has a number of checks and conditions - see {_approve} internal function.
    ///      Requirements:
    ///      `_spender` cannot be the zero address.
    ///      `_spender` must have allowance for the caller of at least `subtractedValue`.
    function decreaseAllowance(address _spender, uint256 _subtractedValue)
        public
        whenNotPaused
        returns (bool)
    {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, _spender);
        require(
            currentAllowance >= _subtractedValue,
            "STokenV1: decreased allowance below zero"
        );
        unchecked {
            _approve(owner, _spender, currentAllowance - _subtractedValue);
        }

        return true;
    }

    /// @dev Moves `_amount` of tokens from `_from` to `_to`.
    ///      Emits a {Transfer} event
    ///      Requirements:
    ///      * `_from` cannot be the zero address and has to be whitelisted
    ///      * `_to` cannot be the zero address and has to be whitelisted.
    ///      * `_from` must have a balance of at least `amount`.
    ///      Function checks limits, balance of `_from` address => see {_beforeTokenTransfer}
    ///      Function updates DataOfLockedTokens for `_from` address => see {_afterTokenTransfer}
    function _transfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal onlyWhitelisted(_from) onlyWhitelisted(_to) {
        require(
            _from != address(0),
            "STokenV1: transfer from the zero address"
        );
        require(_to != address(0), "STokenV1: transfer to the zero address");

        _beforeTokenTransfer(_from, _amount);

        uint256 fromBalance = _balances[_from];
        require(
            fromBalance >= _amount,
            "STokenV1: transfer amount exceeds balance"
        );
        unchecked {
            _balances[_from] = fromBalance - _amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[_to] += _amount;
        }

        emit Transfer(_from, _to, _amount);

        _afterTokenTransfer(_from);
    }

    /// @dev Creates `_amount` tokens and assigns them to `_account`, increasing
    ///      the total supply.
    ///      Emits a {Transfer} event with `from` set to the zero address.
    ///      Requirements:
    ///      `_account` cannot be the zero address and has to be whitelisted.
    function _mint(address _account, uint256 _amount)
        internal
        onlyWhitelisted(_account)
    {
        require(_account != address(0), "STokenV1: mint to the zero address");

        _totalSupply += _amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[_account] += _amount;
        }
        emit Transfer(address(0), _account, _amount);
    }

    /// @dev Destroys `_amount` tokens from `_account`, reducing the total supply.
    ///      Emits a {Transfer} event with `to` set to the zero address.
    ///      Requirements:
    ///      * `_account` cannot be the zero address.
    ///      * `_account` must have at least `_amount` tokens.
    function _burn(address _account, uint256 _amount) internal {
        require(_account != address(0), "STokenV1: burn from the zero address");

        uint256 accountBalance = _balances[_account];
        require(
            accountBalance >= _amount,
            "STokenV1: burn amount exceeds balance"
        );
        unchecked {
            _balances[_account] = accountBalance - _amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= _amount;
        }

        emit Transfer(_account, address(0), _amount);
    }

    /// @dev Sets `_amount` as the allowance of `_spender` over the `_owner` s tokens.
    ///      This internal function is equivalent to `approve`, and can be used to
    ///      e.g. set automatic allowances for certain subsystems, etc.
    ///      Emits an {Approval} event.
    ///      Requirements:
    ///      *`_owner` cannot be the zero address and has to be whitelisted.
    ///      *`_spender` cannot be the zero address and has to be whitelisted.
    function _approve(
        address _owner,
        address _spender,
        uint256 _amount
    ) internal onlyWhitelisted(_owner) onlyWhitelisted(_spender) {
        require(
            _owner != address(0),
            "STokenV1: approve from the zero address"
        );
        require(
            _spender != address(0),
            "STokenV1: approve to the zero address"
        );

        _allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }

    /// @dev Updates `_owner` s allowance for `_spender` based on spent `_amount`.
    ///      Does not update the allowance amount in case of infinite allowance.
    ///      Revert if not enough allowance is available.
    ///      Might emit an {Approval} event.
    function _spendAllowance(
        address _owner,
        address _spender,
        uint256 _amount
    ) internal {
        uint256 currentAllowance = allowance(_owner, _spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= _amount,
                "STokenV1: insufficient allowance"
            );
            unchecked {
                _approve(_owner, _spender, currentAllowance - _amount);
            }
        }
    }

    /// @dev This hook is called before any transfer of tokens(except minting & burning).
    ///      Increases the {PersonalInfo.outputAmount} of `_from` account by `_amount`
    ///      Increases the counter of transactions of `_from` account
    ///      by 1 ({PersonalInfo.transactionCount})
    ///      Requirements:
    ///      *available Transaction Count Limit of `_from` has to be > 0
    ///      *{_availableLimit} of `_from` account cannot be less then `_amount` to transfer
    ///      *{_availableBalance} of `_from` account cannot be less then `_amount` to transfer
    function _beforeTokenTransfer(address _from, uint256 _amount) internal {
        require(
            getLeftTransactionCountLimit(_from) > 0,
            "STokenV1: Available limit of transactions exceeded."
        );

        require(
            _availableLimit(_from) >= _amount,
            "STokenV1: Amount you want to transfer exceeds your Secondary Trading limit."
        );

        require(
            _availableBalance(_from) >= _amount,
            "STokenV1: transfer amount exceeds balance or you try to transfer locked tokens."
        );

        userData[_from].outputAmount += _amount;
        userData[_from].transactionCount++;
    }

    /// @dev This hook is called after any transfer of tokens(except minting & burning).
    ///      Updates(actualize) PersonalInfo.personalLockUps of `_from`
    ///      account => see {updateDataOfLockedTokensOf}
    function _afterTokenTransfer(address _from) internal {
        updateDataOfLockedTokensOf(_from);
    }

    /// @dev Returns currently available Secondary Trading limit of `_account`:
    ///      calculates difference between the current limit of `_account` and
    ///      the amount already sent by this address
    function _availableLimit(address _account) internal view returns (uint256) {
        uint256 limit = secondaryTradingLimitOf(_account);
        require(
            userData[_account].outputAmount < limit,
            "STokenV1: This account has no available Secondary Trading Limit"
        );

        return limit - userData[_account].outputAmount;
    }

    /// @dev Returns currently available amount of tokens to use (transfer) by `_account`:
    ///      calculates the difference between the whole balance of tokens and
    ///      locked tokens on the `_account`
    function _availableBalance(address _account)
        internal
        view
        returns (uint256)
    {
        return balanceOf(_account) - getAmountOfLockedTokens(_account);
    }

    /// @dev Whitelists the `_address`:
    ///      - adds the address to the {PersonalInfo.userAddress}
    ///      - sets the value `true` for {PersonalInfo.whitelisted}
    ///      Emits {Whitelisted} event.
    function _addAddressToWhitelist(address _address) internal {
        userData[_address].userAddress = _address;
        userData[_address].whitelisted = true;
        emit Whitelisted(_msgSender(), _address);
    }

    /// @dev Dewhitelists the `_address`:
    ///      - sets the value `false` for {PersonalInfo.whitelisted}
    ///      Emits {DeWhitelisted} event.
    function _removeAddressFromWhitelist(address _address) internal {
        userData[_address].whitelisted = false;
        emit DeWhitelisted(_msgSender(), _address);
    }

    /// @dev Sets the `_newLimit` as Individual Secondary Trading Limit for `_account`:
    ///      - sets the value `true` for {PersonalInfo.hasOwnSecondaryLimit}
    ///      - sets the value `_newLimit` for {PersonalInfo.individualSecondaryTradingLimit}
    function _setSecondaryTradingLimitFor(address _account, uint256 _newLimit)
        internal
    {
        userData[_account].hasOwnSecondaryLimit = true;
        userData[_account].individualSecondaryTradingLimit = _newLimit;
    }

    /// @dev Sets the `_newLimit` as Individual Transaction Count Limit for `_account`:
    ///      - sets the value `true` for {PersonalInfo.hasOwnTransactionCountLimit}
    ///      - sets the value `_newLimit` for {PersonalInfo.individualTransactionCountLimit}
    function _setTransactionCountLimitFor(address _account, uint256 _newLimit)
        internal
    {
        userData[_account].hasOwnTransactionCountLimit = true;
        userData[_account].individualTransactionCountLimit = _newLimit;
    }

    /// @dev Checks what amount to lock on `_account`:
    ///      compare {_availableBalance} of `_account` and `_amountToLock`
    ///      and returns the less value.
    ///      This function does not allow to lock tockens which `_account` does not have
    ///      on its balance yet, in other words, to get a "negative balance" for `_account`
    function _checkAmountToLock(address _account, uint256 _amountToLock)
        internal
        view
        returns (uint256 resultedAmount)
    {
        _availableBalance(_account) > _amountToLock
            ? resultedAmount = _amountToLock
            : resultedAmount = _availableBalance(_account);
    }

    /// @dev locks `_amount` of tokens on `_account` for `_daysToLock` quantity of days:
    ///      Adds the pair ([0]timestemp when tokens can be unlocked, [1] `_amount`) to the
    ///      array {PersonalInfo.personalLockUps}
    ///      Emits {LockTokens} event.
    function _lockTokens(
        address _account,
        uint256 _amount,
        uint256 _daysToLock
    ) internal {
        uint256[2] memory lockedPair;
        // Calculates the timstamp, when tokens can be unlocked:
        // interprets a function parameter in days `_daysToLock`
        // into Unix Timestamp( in seconds since JAN 01 1970)
        lockedPair[0] = block.timestamp + (_daysToLock * 1 days);
        lockedPair[1] = _amount;

        userData[_account].personalLockUps.push(lockedPair);
        emit LockTokens(_msgSender(), _account, lockedPair[0], _amount);
    }

    /// @dev Helping function for {transferFromTreasuryLockedTokens}
    ///      to combine two actions: {_lockTokens} & {_transfer}
    function _lockAndTransfer(
        address _from,
        address _to,
        uint256 _amount,
        uint256 _daysToLock
    ) internal {
        _lockTokens(_to, _amount, _daysToLock);
        _transfer(_from, _to, _amount);
    }

    /// @dev Helpful function to check if the length of input arrays are equal.
    function _equalArrays(
        address[] memory _addresses,
        uint256[] memory _amounts
    ) internal pure {
        require(
            _addresses.length == _amounts.length,
            "STokenV1: Arrays of addresses and according values have different quantity of elements"
        );
    }

    // Helping functions {_bundlesLoop} serves for using for-loops for arrays in
    // many multi-transaction functions of the contract.
    // They contain the logic how should interact with each other
    // inputed parameters to correctly pass through the loop.
    // The value from first array has to match the other value or
    // the values from second array according to the indexes.
    // One of inputed parameters is internal function, which
    // is executed in the loop too.

    function _bundlesLoop(
        address[] memory _bundleAddress,
        uint256 _amount,
        function(address, uint256) internal _foo
    ) internal {
        for (uint256 i = 0; i < _bundleAddress.length; i++) {
            _foo(_bundleAddress[i], _amount);
        }
    }

    function _bundlesLoop(
        address _accountFrom,
        address[] memory _bundleAddress,
        uint256 _amount,
        function(address, address, uint256) internal _foo
    ) internal {
        for (uint256 i = 0; i < _bundleAddress.length; i++) {
            _foo(_accountFrom, _bundleAddress[i], _amount);
        }
    }

    function _bundlesLoop(
        address[] memory _bundleAddress,
        uint256[] memory _bundleAmounts,
        function(address, uint256) internal _foo
    ) internal {
        _equalArrays(_bundleAddress, _bundleAmounts);
        for (uint256 i = 0; i < _bundleAddress.length; i++) {
            _foo(_bundleAddress[i], _bundleAmounts[i]);
        }
    }

    function _bundlesLoop(
        address _accountFrom,
        address[] memory _bundleAddress,
        uint256[] memory _bundleAmounts,
        function(address, address, uint256) internal _foo
    ) internal {
        _equalArrays(_bundleAddress, _bundleAmounts);
        for (uint256 i = 0; i < _bundleAddress.length; i++) {
            _foo(_accountFrom, _bundleAddress[i], _bundleAmounts[i]);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";

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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (a deployer) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the deployer account will be the one that deploys the contract. This
 * can later be changed with {transferDeployership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyDeployer`, which can be applied to your functions to restrict their use to
 * the deployer.
 */
abstract contract Deployerable is Context {
    address private _deployer;

    event DeployershipTransferred(
        address indexed previousDeployer,
        address indexed newDeployer
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial deployer.
     */
    constructor() {
        _transferDeployership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the deployer.
     */
    modifier onlyDeployer() {
        _checkDeployer();
        _;
    }

    /**
     * @dev Returns the address of the current deployer.
     */
    function deployer() public view virtual returns (address) {
        return _deployer;
    }

    /**
     * @dev Throws if the sender is not the deployer.
     */
    function _checkDeployer() internal view virtual {
        require(
            deployer() == _msgSender(),
            "Deployerable: caller is not the deployer"
        );
    }

    /**
     * @dev Leaves the contract without deployer. It will not be possible to call
     * `onlyDeployer` functions anymore. Can only be called by the current deployer.
     *
     * NOTE: Renouncing deployership will leave the contract without an deployer,
     * thereby removing any functionality that is only available to the deployer.
     */
    function renounceDeployership() public virtual onlyDeployer {
        _transferDeployership(address(0));
    }

    /**
     * @dev Transfers deployership of the contract to a new account (`newDeployer`).
     * Internal function without access restriction.
     */
    function _transferDeployership(address newDeployer) internal virtual {
        address oldDeployer = _deployer;
        _deployer = newDeployer;
        emit DeployershipTransferred(oldDeployer, newDeployer);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "AccessControlEnumerable.sol";

/// @title Roles
/// @author Stobox Technologies Inc.
/// @notice A contract for assigning and managing roles when interacting with a security token
contract Roles is AccessControlEnumerable {
    bytes32 public constant FINANCIAL_MANAGER_ROLE =
        keccak256("FINANCIAL_MANAGER_ROLE");
    bytes32 public constant COMPLIANCE_OFFICER_ROLE =
        keccak256("COMPLIANCE_OFFICER_ROLE");
    bytes32 public constant MASTER_MANAGER_ROLE =
        keccak256("MASTER_MANAGER_ROLE");

    /*Modifiers that check that an account has a specific role. Revert
     * with a standardized message including the required role.
     * The format of the revert reason is given by the following regular expression:
     * /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */

    /// @dev Modifier that checks that an account has SuperAdmin role.
    ///      Reverts with a standardized message, which upper described.
    modifier onlySuperAdmin() {
        _checkRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _;
    }

    /// @dev Modifier that checks that an account has Financial Manager role.
    ///      Reverts with a standardized message, which upper described.
    modifier onlyFinancialManager() {
        _checkRole(FINANCIAL_MANAGER_ROLE, _msgSender());
        _;
    }

    /// @dev Modifier that checks that an account has Complience Officer role.
    ///      Reverts with a standardized message, which upper described.
    modifier onlyComplianceOfficer() {
        _checkRole(COMPLIANCE_OFFICER_ROLE, _msgSender());
        _;
    }

    /// @dev Modifier that checks that an account has Master Manager role.
    ///      Reverts with a standardized message, which upper described.
    modifier onlyMasterManager() {
        _checkRole(MASTER_MANAGER_ROLE, _msgSender());
        _;
    }

    constructor(
        address _superAdminAddress,
        address _financialManager,
        address _complianceOfficer,
        address _masterManager
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, _superAdminAddress);
        _grantRole(FINANCIAL_MANAGER_ROLE, _financialManager);
        _grantRole(COMPLIANCE_OFFICER_ROLE, _complianceOfficer);
        _grantRole(MASTER_MANAGER_ROLE, _masterManager);

        _setRoleAdmin(FINANCIAL_MANAGER_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(COMPLIANCE_OFFICER_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(MASTER_MANAGER_ROLE, DEFAULT_ADMIN_ROLE);
    }

    //Functions to add proper role to `address`

    /// @notice Grant SuperAdmin role to `_address`
    /// @dev Requirements:caller must have SuperAdmin role
    ///      May emit a {RoleGranted} event
    /// @param _address address to grant SuperAdmin role
    function addSuperAdmin(address _address) external onlySuperAdmin {
        _grantRole(DEFAULT_ADMIN_ROLE, _address);
    }

    /// @notice Grant Financial Manager role to `_address`
    /// @dev Requirements:caller must have SuperAdmin role
    ///      May emit a {RoleGranted} event.
    ///      Additionaly, to be able to perform its functions `_address` has
    ///      to be given unlimited {approve} from
    ///      {_corporateTreasury}(look cotract SToken)
    /// @param _address address to grant Manager role
    function addFinancialManager(address _address)
        external
        virtual
        onlySuperAdmin
    {
        _grantRole(FINANCIAL_MANAGER_ROLE, _address);
    }

    /// @notice Grant Conplience Officer role to `_address`
    /// @dev Requirements:caller must have SuperAdmin role
    ///      May emit a {RoleGranted} event
    /// @param _address address to grant Manager role
    function addComplianceOfficer(address _address) external onlySuperAdmin {
        _grantRole(COMPLIANCE_OFFICER_ROLE, _address);
    }

    /// @notice Grant Master Manager role to `_address`
    /// @dev Requirements:caller must have SuperAdmin role
    ///      May emit a {RoleGranted} event
    /// @param _address address to grant Manager role
    function addMasterManager(address _address) external onlySuperAdmin {
        _grantRole(MASTER_MANAGER_ROLE, _address);
    }

    //Functions to remove proper role from `address`

    /// @notice Revokes SuperAdmin role from the calling account
    /// @dev If the calling account had been revoked SuperAdmin role,
    ///      emits a {RoleRevoked} event
    ///      Requirements: the caller must be SuperAdmin
    function renounceSuperAdmin() external onlySuperAdmin {
        renounceRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @notice Revokes Financial Manager role from `_address`
    /// @dev If `_address` had been revoked Financial Manager role, emits a {RoleRevoked} event
    ///      Requirements:the caller must have SuperAdmin role
    /// @param _address address to revoke Manager role from it
    function removeFinancialManager(address _address)
        external
        virtual
        onlySuperAdmin
    {
        _revokeRole(FINANCIAL_MANAGER_ROLE, _address);
    }

    /// @notice Revokes Compliance Officer role from `_address`
    /// @dev If `_address` had been revoked Compliance Officer role, emits a {RoleRevoked} event
    ///      Requirements:the caller must have SuperAdmin role
    /// @param _address address to revoke Manager role from it
    function removeComplianceOfficer(address _address) external onlySuperAdmin {
        _revokeRole(COMPLIANCE_OFFICER_ROLE, _address);
    }

    /// @notice Revokes Master Manager role from `_address`
    /// @dev If `_address` had been revoked Master Manager role, emits a {RoleRevoked} event
    ///      Requirements:the caller must have SuperAdmin role
    /// @param _address address to revoke Manager role from it
    function removeMasterManager(address _address) external onlySuperAdmin {
        _revokeRole(MASTER_MANAGER_ROLE, _address);
    }

    //Functions to get the list of addresses, which have proper role.

    /// @notice Returns the list of addresses, which have SuperAdmin role
    function getListOfSuperAdmins() external view returns (address[] memory) {
        return _getListOfRoleOwners(DEFAULT_ADMIN_ROLE);
    }

    /// @notice Returns the list of addresses, which have Financial Managerper role
    function getListOfFinancialManagers()
        public
        view
        returns (address[] memory)
    {
        return _getListOfRoleOwners(FINANCIAL_MANAGER_ROLE);
    }

    /// @notice Returns the list of addresses, which have Compliance Officer role
    function getListOfComplianceOfficer()
        public
        view
        returns (address[] memory)
    {
        return _getListOfRoleOwners(COMPLIANCE_OFFICER_ROLE);
    }

    /// @notice Returns the list of addresses, which have Master Managerper role
    function getListOfMasterManagers() public view returns (address[] memory) {
        return _getListOfRoleOwners(MASTER_MANAGER_ROLE);
    }

    //Functions to check if `address` has proper role

    /// @notice Checks if `_address` has SuperAdmin role
    /// @param _address address to check if it has SuperAdmin role
    /// @return true if checking was successful, otherwise return false
    function isSuperAdmin(address _address) public view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _address);
    }

    /// @notice Checks if `_address` has Financial Manager role
    /// @param _address address to check if it has Financial Manager role
    /// @return true if checking was successful, otherwise return false
    function isFinancialManager(address _address) public view returns (bool) {
        return hasRole(FINANCIAL_MANAGER_ROLE, _address);
    }

    /// @notice Checks if `_address` has Compliance Officer role
    /// @param _address address to check if it has Compliance Officer role
    /// @return true if checking was successful, otherwise return false
    function isComplianceOfficer(address _address) public view returns (bool) {
        return hasRole(COMPLIANCE_OFFICER_ROLE, _address);
    }

    /// @notice Checks if `_address` has Master Manager role
    /// @param _address address to check if it has Master Manager role
    /// @return true if checking was successful, otherwise return false
    function isMasterManager(address _address) public view returns (bool) {
        return hasRole(MASTER_MANAGER_ROLE, _address);
    }

    /// @dev Creates list of addresses with necessary `_role`
    /// Internal function without restrictions
    function _getListOfRoleOwners(bytes32 _role)
        internal
        view
        returns (address[] memory)
    {
        uint256 len = getRoleMemberCount(_role);
        address[] memory resultedList = new address[](len);

        for (uint256 i = 0; i < len; i++) {
            resultedList[i] = getRoleMember(_role, i);
        }
        return resultedList;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "IAccessControlEnumerable.sol";
import "AccessControl.sol";
import "EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "IAccessControl.sol";
import "Context.sol";
import "Strings.sol";
import "ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

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
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
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
        return _values(set._inner);
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