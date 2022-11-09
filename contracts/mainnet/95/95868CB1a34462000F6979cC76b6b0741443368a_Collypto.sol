// SPDX-License-Identifier: copyleft-next-0.3.1
// Collypto Contract v1.0.0
pragma solidity ^0.8.17 < 0.9.0;

/**
 * @dev Interface of the complete ERC-20 standard with all events, required
 * functions, and optional functions, as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Standard transfer event emitted when `amount` tokens are moved from
     * one account at `from` to another account at `to`
     */
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /**
     * @dev Standard approval event emitted when an allowance has been modified
     * to `amount` for the account at `spender` to spend on behalf of the
     * account at `owner`
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    /**
     * @dev Returns the name of the token
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token
     */
    function symbol() external view returns (string memory);
    
    /**
     * @dev Returns the number of decimals the token uses
     */
    function decimals() external view returns (uint8);
    
    /**
     * @dev Returns the total token supply
     */   
    function totalSupply() external view returns (uint256);
    
    /**
     * @dev Returns the balance of the account at `owner`
     */ 
    function balanceOf(address owner) external view returns (uint256);
    
    /**
     * @dev Transfers `amount` tokens from the operator's account to the
     * account at `to`
     */    
    function transfer(address to, uint256 amount) external returns (bool);
    
    /**
     * @dev Transfers `amount` tokens from the account at `from` to the account
     * at `to`
     */        
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool); 

    /**
     * @dev Allows the account at `spender` to withdraw from the operator's
     * account multiple times, up to a total of `amount` tokens
     */      
    function approve(address spender, uint256 amount) external returns (bool);
    
    /**
     * @dev Returns the amount which the account at `spender` is still allowed
     * to withdraw from the account at `owner`
     */     
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);   
}

/**
 * @title Collypto
 * @author Matthew McKnight - Collypto Technologies, Inc.
 * @notice This contract contains all core Collypto features that are available
 * on the Ethereum blockchain. 
 * @dev This contract is the implementation of Collypto's ERC-20 contract and
 * extended functions.
 * 
 * OVERVIEW
 * We have followed general best practices of OpenZeppelin and Solidity,
 * including operation reversion on failure, allowance support functions and
 * events, and an upgradable contract structure that utilizes an initializer
 * function instead of a constructor. In addition to the required and verified
 * versions of standard ERC-20 operations and extended operations, we have also
 * included functionality for minting and burning tokens, freezing and
 * unfreezing tokens, locking and unlocking Ethereum accounts, pausing and
 * unpausing this contract, and forcibly transferring tokens, in addition to
 * our other enhanced management and ownership operations. We have also
 * included a complete user status model that represents the off-chain status
 * of an address owner in our internal systems, as well as operations to allow
 * us to update the user status of Ethereum accounts and provide public
 * visibility of Ethereum account status.
 *
 * VERIFIED OPERATIONS ({verifiedTransfer}, {verifiedTransferFrom},
 * {verifiedApprove}, {verifiedIncreaseAllowance}, {verifiedDecreaseAllowance})
 * In addition to implementing all required ERC-20 functions and extended
 * functions, Collypto also provides users with "verified" versions of all
 * public token operations. Any call to one of these functions requires the
 * recipient (or target address) to be in the "Verified" status (corresponding
 * to a medallion account), otherwise the operation will revert.
 *
 * UTILITY OPERATIONS ({updateUserStatus}, {forceTransfer}, {freeze},
 * {unfreeze}, {lock}, {unlock}, {mint}, {burn})
 * The Collypto contract contains eight utility operations that correspond to
 * stratified sets of operator classes used to conduct transactions through the
 * multiplexed access controls of our management contract account. These
 * functions will only by utilized by authorized systems and representatives of
 * Collypto Technologies and will never be available to the public.
 *
 * USER STATUS ({updateUserStatus})
 * Collypto maintains a {UserStatus} record for every possible Ethereum account
 * in the {_userStatuses} mapping, and each corresponding {UserStatus} record
 * contains exactly two properties: {status} and {info}. The {status} value of
 * a {UserStatus} record defaults to "Unknown", and the {info} value defaults
 * to an empty string. 
 * 
 * We refer to a user's primary verified Ethereum account as their "medallion",
 * and upon receiving a request for verification from a user, we will update
 * the {status} value of their Medallion address to "Pending" as we conduct the
 * address validation and customer verification process. When the user has
 * completed our KYC verification process and they have verified ownership of
 * their Medallion address, we will change the {status} value of its
 * corresponding {UserStatus} record to "Verified", and we will change the
 * {info} value of its {UserStatus} record to a string in the format
 * {'creationDate':'yyyy-MM-dd','expirationDate':'yyyy-MM-dd','message':''},
 * where {creationDate} and {expirationDate} are dates represented as strings
 * in ISO 8601 standard date format.
 * 
 * The value of {creationDate} represents the original issue date of the
 * account owner's medallion certification, the value of {expirationDate}
 * represents the last day the medallion will be valid before its owner will
 * need to reverify their identity, and {message} is an optional property that
 * we can use to send an on-chain message to the owner of any Ethereum account.
 * Users may register other non-medallion Ethereum accounts in our off-chain
 * internal systems, but those accounts will remain in the "Unknown" {status},
 * and the value of their {info} property will remain an empty string.
 * {creationDate} and {expirationDate} properties will never be included in the
 * {info} value of non-medallion accounts.
 *
 * In addition to the verification model, we have also included functionality
 * to mark accounts as "Suspect" or "Blacklisted" if they are implicated in
 * criminal activity, government sanctions, or other violations of our Terms of
 * Service. Our internal blacklist will contain both Ethereum addresses and
 * known malicious actors, and Ethereum accounts with a {status} of
 * "Blacklisted" will automatically be locked and unable to send tokens,
 * receive tokens, or perform allowance operations.
 *
 * FORCE TRANSFER ({forceTransfer})
 * The {forceTransfer} function allows us to forcibly transfer credits (that
 * were stolen or fraudulently obtained) from a malicious actor's Ethereum
 * account back to the Ethereum account of a victim without corrupting the
 * collateralization state of our system.
 * 
 * FREEZE/UNFREEZE ({freeze}, {unfreeze})
 * In addition to the standard {_balances} mapping for Ethereum account token
 * balances, we also include the {_frozenBalances} property which is used to
 * represent the total frozen tokens in a user's Ethereum account. The total
 * frozen tokens will never exceed the Ethereum account balance. This
 * functionality allows us to freeze a specified amount of credits during an
 * investigation or government sanction, and it facilitates the "Limited
 * Freeze" feature of our Virtual Cold Storage (VCS) service for verified
 * users. Frozen tokens can only be unfrozen by our management account, which
 * provides an additional layer of security to traditional cold storage.
 * 
 * LOCK/UNLOCK ({lock}, {unlock})
 * As an additional security feature, we maintain the {_lockedAddresses}
 * mapping for both blacklisted accounts and the "Complete Lock" feature of our
 * VCS service for verified users. Locking an Ethereum account prevents it from
 * sending tokens, receiving tokens, or performing allowance operations. The
 * lock feature allows us to provide the "Complete Lock" feature of our VCS
 * service for verified users (in addition to its application for blacklisted
 * Ethereum accounts). As with frozen tokens, locked accounts can only be
 * unlocked by our management account, which provides an additional layer of
 * security to traditional cold storage.
 *
 * MINT/BURN ({mint}, {burn})
 * We have implemented standard mint and burn functions with {Transfer} events
 * to and from the zero address in addition to their respective {Mint} and
 * {Burn} events. Tokens will only be minted and burned by our management
 * account, and uncollateralized tokens will never enter circulation. Both mint
 * and burn operations may be conducted on any target account, rather than a
 * hard-coded vault account, which allows us the flexibility to change our
 * vault location without requiring an update to this contract. Minted tokens
 * are always unfrozen by default, and frozen tokens cannot be burned without
 * first being unfrozen.
 *
 * CONTRACT MANAGEMENT
 * Instead of utilizing a traditional ownership model, Collypto utilizes a
 * stratified management structure for contract management operations and the
 * transfer of management power in the event of an update or compromise of our
 * management contract.
 * 
 * MANAGEMENT OPERATIONS ({pause}, {unpause}, {addManager}, {removeManager})
 * In addition to the utility operations listed previously, this contract
 * contains four management operations that facilitate disaster recovery and
 * allow us to securely update our management contract. These functions will
 * only be utilized by authorized systems and representatives of Collypto
 * Technologies and will never be available to the public.
 * 
 * PAUSE/UNPAUSE ({pause}, {unpause})
 * This contract includes functionality to pause and unpause all non-view user
 * transactions. This is essential in the event of a security breach and allows
 * us to mitigate the damage that could otherwise be caused by a malicious
 * actor or institution. Any majority key compromise of our management contract
 * that is Category 3 or above would require us to pause the contract to
 * rectify the situation and reverse all malicious transactions. The running
 * state of this contract is maintained in the {_isRunning} Boolean property,
 * which defaults to "false" until the contract is initialized.
 * 
 * SECURE MANAGEMENT TRANSFER ({addManager}, {removeManager})
 * In order to allow our management contract to be upgradable, this contract
 * includes functions to add and remove a single manager address from the
 * {_managerAddresses} array (the manager list). These functions can only be
 * called by a management account, which includes the Master address
 * (maintained in the {_ownerAddress} property of this contract). The Master
 * address cannot be updated or removed by a standard management account.
 * 
 * Management transfers utilize the {addManager} and {removeManager} functions
 * to ensure that the new management account address is added to the manager
 * list before the old one is removed, and a manager account cannot remove
 * itself from the manager list. This means that, unlike the traditional
 * ownership model, it is impossible for our team or systems to accidentally
 * lose control of this contract by accidentally typing in the wrong address
 * value for the new management contract account. With the exception of
 * contract updates, the manager list will only ever contain a single address
 * value stored at {_managerAddresses[0]} (the management contract address) for
 * support operations.
 * 
 * CONTRACT OWNERSHIP
 * Collypto maintains an additional layer of security beyond the level of our
 * management account, and that is the Master address maintained in the
 * {_ownerAddress} property of this contract. In addition to being able to
 * conduct management operations, the Master address can also conduct three
 * additional operations to initialize this contract and provide recourse for
 * disaster recovery (up to and including a Category 1 breach). These functions
 * will only by utilized by authorized systems and representatives of Collypto
 * Technologies and will never be available to the public.
 * 
 * PURGE MANAGERS ({purgeManagers})
 * In the event that the majority of Prime keys that control the management
 * contract are compromised, the Master account can be used to purge all
 * management addresses from the manager list using the {purgeManagers}
 * function. At this point, we would need to deploy a new instance of the
 * management contract, and we would then use the Master account to add the
 * management contract address to the manager list. 
 * 
 * CONTRACT "TERMINATION" ({terminateContract})
 * In the event that the Master key itself is compromised, it can still be used
 * to call the {terminateContract} function, which clears the manager list,
 * resets the value of {_ownerAddress} (the Master address) to the zero
 * address, resets the value of {_isInitialized} to "false", and pauses the
 * contract. At this point, we would need to use the Admin account to update
 * this contract with a new value for the {_ownerAddress} (the address of the
 * new Master account), and we would need to use the new Master account to
 * reinitialize this contract with a new address for the updated management
 * contract.
 * 
 * CONTRACT INITIALIZATION ({initialize})
 * As previously stated, this contract is upgradable, and its storage model is
 * compliant with OpenZeppelin upgradable contract requirements. The storage
 * model of this contract has been optimized for our solution requirements, and
 * this contract utilizes an initializer function, rather than a constructor,
 * to define its name, symbol, owner, and management address. The
 * initialization state of this contract is maintained in the {_isInitialized}
 * Boolean property, which defaults to "false" until this contract is
 * initialized. The initialization counter of this contract is maintained in
 * the {_initializationIndex} property, which allows us to track how many times
 * it has been updated and defaults to zero until this contract is first
 * initialized.
 */
contract Collypto is IERC20 {
    /**
     * @dev Enumeration containing all valid values of the {status} property
     * that can be assigned in the {UserStatus} record of an Ethereum account
     */
    enum Statuses { Unknown, Pending, Verified, Suspect, Blacklisted }

    /**
     * @dev Struct that allows us to maintain on-chain user status records for
     * verification, internal investigations, and blacklisting
     */
    struct UserStatus {
        Statuses status; // Defaults to "Unknown" (zero value)
        string info; // Defaults to empty string value
    }

    /**
     * @dev Mapping of all Ethereum account balances (in slivers) (indexed by
     * account address)
     */
    mapping(address => uint256) private _balances;

    /**
     * @dev Mapping of all frozen balances (in slivers) (indexed by Ethereum
     * account address)
     */    
    mapping(address => uint256) private _frozenBalances;

    /**
     * @dev Mapping of all allowances (in slivers) (indexed by owner and
     * spender Ethereum account address)
     */
    mapping(address => mapping(address => uint256)) private _allowances;

    /**
     * @dev Mapping of the lock state of all Ethereum accounts (indexed by
     * account address)
     */
    mapping(address => bool) private _lockedAddresses;

    /**
     * @dev Mapping of {UserStatus} records of all Ethereum accounts (indexed
     * by account address)
     */    
    mapping(address => UserStatus) private _userStatuses;
    
    /// @dev Current address of the Master account
    address private _ownerAddress;

    /// @dev Current list of management account addresses (the manager list)
    address[2] private _managerAddresses;

    /**
     * @dev Total supply of credits (in slivers) that currently exists on the
     * Ethereum blockchain
     */
    uint256 private _totalSupply;

    /// @dev Name of the token defined in this contract
    string private _name;

    /// @dev Ticker symbol for the token defined in this contract
    string private _symbol;

    /// @dev Running state of this contract (defaults to "false")
    bool private _isRunning;

    /// @dev Initialization state of this contract (defaults to "false")
    bool private _isInitialized;

    /// @dev Initialization index of this contract (defaults to zero)
    uint256 private _initializationIndex;

    /**
     * @dev Utility event emitted when the {UserStatus} record of the Ethereum
     * account at `owner` is updated to contain a {status} value of `status`
     * and an {info} value of `info`
     */      
    event UpdateUserStatus(
        address indexed owner,
        Statuses status,
        string info
    );

    /**
     * @dev Utility event emitted when `amount` slivers are forcibly moved from
     * the Ethereum account at `from` to the account at `to`
     */      
    event ForceTransfer(
        address indexed from,
        address indexed to,
        uint256 amount
    );

    /**
     * @dev Utility event emitted when `amount` slivers are frozen in the
     * Ethereum account at `owner`
     */   
    event Freeze(address indexed owner, uint256 amount);

    /**
     * @dev Utility event emitted when `amount` slivers are unfrozen in the
     * Ethereum account at `owner`
     */   
    event Unfreeze(address indexed owner, uint256 amount);

    /**
     * @dev Utility event emitted when the Ethereum account at `owner` is
     * locked
     */   
    event Lock(address indexed owner);

    /**
     * @dev Utility event emitted when the Ethereum account at `owner` is
     * unlocked
     */  
    event Unlock(address indexed owner);
    
    /**
     * @dev Utility event emitted when `amount` slivers are minted in the
     * Ethereum account at `owner`
     */      
    event Mint(address indexed owner, uint256 amount);

    /**
     * @dev Utility event emitted when `amount` slivers are burned in the
     * Ethereum account at `owner`
     */
    event Burn(address indexed owner, uint256 amount);
    
    /// @dev Management event emitted when this contract is paused
    event Pause();

    /// @dev Management event emitted when this contract is unpaused
    event Unpause();

    /**
     * @dev Management event emitted when the manager account at `newManager`
     * is added to the manager list
     */      
    event AddManager(address indexed newManager);

    /**
     * @dev Management event emitted when the manager account at
     * `removedManager` is removed from the manager list
     */    
    event RemoveManager(address indexed removedManager);
    
    /**
     * @dev Ownership event emitted when all management addresses are purged
     * from the manager list
     */      
    event PurgeManagers();

    /**
     * @dev Ownership event emitted when this contract is initialized where
     * `index` is the total number of times the logic contract has been
     * initialized
     */
    event Initialize(uint256 index);

    /**
     * @dev Modifier that determines if this contract is currently running and
     * reverts on "false"
     */       
    modifier isRunning {
        // This contract must be running
        require(
            _isRunning,
            "Collypto is not accepting transactions at this time"
        );
        _;
    }

    /**
     * @dev Modifier that determines if an address belongs to a management
     * account or the Master account and reverts on "false"
     */
    modifier onlyManager {
        // Operator address must match one of the management addresses or the
        // address of the Master account
        require(
            (msg.sender == _managerAddresses[0]) || 
            (msg.sender == _managerAddresses[1]) || 
            (msg.sender == _ownerAddress)
        );
        _;
    }

    /**
     * @dev Modifier that determines if an address belongs to the Master
     * account and reverts on "false"
     */    
    modifier onlyOwner {
        // Operator address must match the address of the Master account
        require((msg.sender == _ownerAddress));
        _;
    }

    /**
     * @notice Initializes this contract with the input values provided 
     * @dev This is a restricted ownership function and can only be called by
     * an operator using the Master account, otherwise, it will revert. Once
     * initialization is complete, an instance of this contract cannot be
     * reinitialized.
     * @param name_ The name of the token defined in this contract
     * @param symbol_ The ticker symbol of the token defined in this contract
     * @param managerAddress The initial management address value that will be
     * assigned to {_managerAddresses[0]}
     * @return success A Boolean value indicating that initialization was
     * successful
     */
    function initialize(
        string memory name_, 
        string memory symbol_, 
        address managerAddress
    )
        public
        returns (bool success)
    {
        // An instance of this contract can be initialized only once
        require(_initializationIndex == 0);

        // Assign current Master address
        _ownerAddress = 0x6334C976B8C4600Cb9b5A16Fe576eacBdf7289e3;
        
        // Initialization must be conducted by an operator using the Master
        // account
        require(msg.sender == _ownerAddress);

        _name = name_;
        _symbol = symbol_;

        // First manager list slot is initialized to the address provided
        _managerAddresses[0] = managerAddress;
        
        // Second manager list slot is initialized to the zero address ("empty"
        // value)
        _managerAddresses[1] = address(0);
        
        // Increment initialization index for future contract upgrades
        _initializationIndex++;

        _isInitialized = true;
        _isRunning = true;

        emit Initialize(_initializationIndex);

        return true;
    }

    /**
     * @notice Returns the current initialization index of the contract
     * @dev As with other view functions, this operation can be conducted
     * regardless of the current running state of this contract.
     * @return index The total number of times this contract has been
     * initialized
     */
    function initializationIndex() public view returns (uint256 index) {
        return _initializationIndex;
    }

    /**
     * @notice Returns a Boolean value indicating whether this contract has
     * been initialized
     * @dev As with other view functions, this operation can be conducted
     * regardless of the current running state of this contract.
     * @return initialized A Boolean value indicating whether this contract has
     * been initialized
     */
    function isInitialized() public view returns (bool initialized) {
        return _isInitialized;
    }

    /**
     * @notice Returns a Boolean value indicating whether this contract is
     * currently paused
     * @dev As with other view functions, this operation can be conducted
     * regardless of the current running state of this contract.
     * @return paused A Boolean value indicating whether this contract is
     * currently paused
     */
    function isPaused() public view returns (bool paused) {
        return !_isRunning;
    }    

    /**
     * @notice Returns the name of the token defined by this contract
     * @dev As with other view functions, this operation can be conducted
     * regardless of the current running state of this contract.
     * @return tokenName The name of the token defined by this contract
     */
    function name() public view returns (string memory tokenName) {
        return _name;
    }

    /**
     * @notice Returns the ticker symbol of the token defined by this contract
     * @dev As with other view functions, this operation can be conducted
     * regardless of the current running state of this contract.
     * @return tokenSymbol The ticker symbol of the token defined by this
     * contract
     */
    function symbol() public view returns (string memory tokenSymbol) {
        return _symbol;
    }

    /**
     * @notice Returns the number of decimals used by this token
     * @dev As a pure function, this operation can be conducted regardless of
     * the current running state of this contract. The smallest unit of
     * Collypto is the "sliver", which is one quintillionth of a credit.
     * @return totalDecimals The number of decimals used by this token 
     */   
    function decimals() public pure returns (uint8 totalDecimals) {
        return 18;
    }

    /**
     * @notice Returns the total supply of credits (in slivers) that currently
     * exists on the Ethereum blockchain
     * @dev As with other view functions, this operation can be conducted
     * regardless of the current running state of this contract.
     * @return supply The total supply of credits (in slivers) that currently
     * exists on the Ethereum blockchain
     */
    function totalSupply() public view returns (uint256 supply) {
        return _totalSupply;
    }    
  
    /**
     * @notice Returns the total credit balance (in slivers) of the Ethereum
     * account at `owner`
     * @dev As with other view functions, this operation can be conducted
     * regardless of the current running state of this contract. 
     * @param owner The address of the Ethereum account whose balance is being
     * requested
     * @return balance The total credit balance (in slivers) of the {owner}
     * account
     */
    function balanceOf(address owner) public view returns (uint256 balance) {
        return _balances[owner];
    }

    /**
     * @notice Returns the frozen credit balance (in slivers) of the Ethereum
     * account at `owner`
     * @dev As with other view functions, this operation can be conducted
     * regardless of the current running state of this contract.          
     * @param owner The address of the Ethereum account whose frozen balance is
     * being requested
     * @return frozenBalance The frozen credit balance (in slivers) of the
     * {owner} account
     */ 
    function frozenBalanceOf(address owner)
        public
        view
        returns (uint256 frozenBalance)
    {

        return _frozenBalances[owner];
    } 

    /** 
     * @notice Returns the available credit balance (in slivers) of the
     * Ethereum account at `owner` 
     * @dev As with other view functions, this operation can be conducted
     * regardless of the current running state of this contract. 
     * @param owner The address of the Ethereum account whose available balance
     * is being requested
     * @return availableBalance The available credit balance (in slivers) of
     * the {owner} account
     */
    function availableBalanceOf(address owner)
        public
        view
        returns (uint256 availableBalance)
    {
        return _balances[owner] - _frozenBalances[owner];
    }

    /**
     * @notice Returns the current allowance of credits (in slivers) that
     * the Ethereum account at `spender` is authorized to transfer on behalf of
     * the Ethereum account at `owner`
     * @dev As with other view functions, this operation can be conducted
     * regardless of the current running state of this contract.
     * @param owner The address of the authorizing Ethereum account
     * @param spender The address of the authorized Ethereum account
     * @return remaining The total allowance of credits (in slivers) that the
     * {spender} account may spend on behalf of the {owner} account
     */
    function allowance(address owner, address spender)
        public
        view
        returns (uint256 remaining)
    {
        return _allowances[owner][spender];
    }

    /**
     * @notice Returns the {UserStatus} record of the Ethereum account at
     * `owner`
     * @dev As with other view functions, this operation can be conducted
     * regardless of the current running state of this contract. 
     * @param owner The address of the Ethereum account whose {UserStatus}
     * record is being requested
     * @return status The {status} value of the {UserStatus} record of the
     * {owner} account
     * @return info The {info} value of the {UserStatus} record of the
     * {owner} account
     */
    function userStatusOf(address owner)
        public
        view
        returns (Statuses status, string memory info)
    {
        return (_userStatuses[owner].status, _userStatuses[owner].info);
    }

    /**
     * @notice Returns a Boolean value indicating whether the Ethereum account
     * at `targetAddress` is currently locked.
     * @dev Locked accounts cannot send tokens, receive tokens, or conduct
     * allowance operations. As with other view functions, this operation can
     * be conducted regardless of the current running state of this contract.
     * @param targetAddress The address of the target Ethereum account
     * @return locked A Boolean value indicating whether the target Ethereum
     * account is locked
     */
    function isLocked(address targetAddress)
        public
        view
        returns (bool locked)
    {
        return _lockedAddresses[targetAddress];
    }

    /**
     * @notice Returns a Boolean value indicating whether the Ethereum account
     * at `targetAddress` has a {status} value of "Unknown"
     * @dev As with other view functions, this operation can be conducted
     * regardless of the current running state of this contract. "Unknown" is
     * the default {status} value of all Ethereum accounts.
     * @param targetAddress The address of the target Ethereum account
     * @return unknown A Boolean value indicating whether the target Ethereum
     * account has a {status} value of "Unknown"
     */    
    function isUnknown(address targetAddress)
        public
        view
        returns (bool unknown)
    {
        return _userStatuses[targetAddress].status == Statuses.Unknown;
    }

    /**
     * @notice Returns a Boolean value indicating whether the Ethereum account
     * at `targetAddress` has a {status} value of "Verified"
     * @dev As with other view functions, this operation can be conducted
     * regardless of the current running state of this contract. "Verified" is
     * the {status} of all medallion accounts. Only medallion accounts can
     * conduct verified user operations.
     * @param targetAddress The address of the target Ethereum account
     * @return verified A Boolean value indicating whether the target Ethereum
     * account has a {status} value of "Verified"
     */    
    function isVerified(address targetAddress)
        public
        view
        returns (bool verified)
    {
        return _userStatuses[targetAddress].status == Statuses.Verified;
    }

    /**
     * @notice Returns a Boolean value indicating whether the Ethereum account
     * at `targetAddress` has a {status} value of "Blacklisted"
     * @dev As with other view functions, this operation can be conducted
     * regardless of the current running state of this contract. Blacklisted
     * accounts can only conduct view operations.
     * @param targetAddress The address of the target Ethereum account
     * @return blacklisted A Boolean value indicating whether the target
     * Ethereum account has a {status} value of "Blacklisted"
     */   
    function isBlacklisted(address targetAddress)
        public
        view
        returns (bool blacklisted)
    {
        return _userStatuses[targetAddress].status == Statuses.Blacklisted;
    }
    
    /**
     * @notice Returns a Boolean value indicating whether the Ethereum account
     * at `targetAddress` has a {status} value of "Suspect"
     * @dev As with other view functions, this operation can be conducted
     * regardless of the current running state of this contract. Suspected
     * accounts can still conduct all non-verified (standard) user operations.
     * @param targetAddress The address of the target Ethereum account
     * @return suspect A Boolean value indicating whether the target Ethereum
     * account has a {status} value of "Suspect"
     */       
    function isSuspect(address targetAddress)
        public
        view
        returns (bool suspect)
    {
        return _userStatuses[targetAddress].status == Statuses.Suspect;
    }

    /**
     * @notice Returns a Boolean value indicating whether the Ethereum account
     * at `targetAddress` has a {status} value of "Pending"
     * @dev As with other view functions, this operation can be conducted
     * regardless of the current running state of this contract. Accounts will
     * only be moved to "Pending" {status} prior to completion of the medallion
     * verification process.
     * @param targetAddress The address of the target Ethereum account
     * @return pending A Boolean value indicating whether the target Ethereum
     * account has a {status} value of "Pending"
     */      
    function isPending(address targetAddress)
        public
        view
        returns (bool pending)
    {
        return _userStatuses[targetAddress].status == Statuses.Pending;
    }

    /**
     * @notice Returns a Boolean value indicating whether the Ethereum account
     * at `targetAddress` is a manager account (includes the Master account)
     * @dev As with other view functions, this operation can be conducted
     * regardless of the current running state of this contract.
     * @param targetAddress The address of the target Ethereum account
     * @return manager A Boolean value indicating whether the target Ethereum
     * account is a manager account
     */      
    function isManager(address targetAddress)
        public
        view
        returns (bool manager)
    {
        if (targetAddress == address(0)) {
            return false;
        } else if (
            (targetAddress == _managerAddresses[0]) ||
            (targetAddress == _managerAddresses[1]) ||
            (targetAddress == _ownerAddress)
        ) {
            return true;
        }

        return false;
    }

    /**
     * @notice Returns a Boolean value indicating whether the Ethereum account
     * at `targetAddress` is the Master account
     * @dev As with other view functions, this operation can be conducted
     * regardless of the current running state of this contract.
     * @param targetAddress The address of the target Ethereum account
     * @return owner A Boolean value indicating whether the target Ethereum
     * account is the Master account
     */      
    function isOwner(address targetAddress)
        public
        view
        returns (bool owner)
    {
        if (targetAddress == address(0)) {
            return false;
        } else if (targetAddress == _ownerAddress) {
            return true;
        }

        return false;
    }

    /**
     * @notice Moves `amount` slivers from the operator's Ethereum account to
     * the Ethereum account at `to` and emits a {Transfer} event
     * @dev Per ERC-20 requirements, transfers of 0 credits are treated as
     * normal transfers and emit the {Transfer} event. This operation will
     * revert if the operator's Ethereum account or the {to} account is
     * blacklisted or locked or if any input arguments violate rules in the
     * {_transfer} function. Standard transfers cannot be conducted when this
     * contract is paused.
     * @param to The address of the recipient's Ethereum account
     * @param amount The total amount of credits (in slivers) to be transferred
     * @return success A Boolean value indicating that the transfer was
     * successful
     */
    function transfer(address to, uint256 amount) 
        public
        isRunning
        returns (bool success)
    {
        address from = msg.sender;        
        
        // Cannot transfer from a blacklisted address
        require(!isBlacklisted(from), "ERROR: Unauthorized");
        
        // Cannot transfer to a blacklisted address
        require(!isBlacklisted(to), "ERROR: Blacklisted recipient");
        
        // Cannot transfer from a locked address
        require(!isLocked(from), "ERROR: Sender is locked");
        
        // Cannot transfer to a locked address
        require(!isLocked(to), "ERROR: Recipient is locked");

        _transfer(from, to, amount);

        return true;
    }

    /**
     * @notice Moves `amount` slivers from the operator's Ethereum account to
     * the Ethereum account at `to` (if the recipient is verified) and emits a
     * {Transfer} event
     * @dev Per ERC-20 requirements, transfers of 0 credits are treated as
     * normal transfers and emit the {Transfer} event. This operation will
     * revert if the operator's Ethereum account or the {to} account is
     * blacklisted or locked, the {to} account is unverified, or if any input
     * arguments violate rules in the {_transfer} function. Verified transfers
     * cannot be conducted when this contract is paused.
     * @param to The address of the recipient's Ethereum account
     * @param amount The total amount of credits (in slivers) to be transferred
     * @return success A Boolean value indicating that the transfer was
     * successful
     */
    function verifiedTransfer(address to, uint256 amount)
        public
        isRunning
        returns (bool success)
    {
        address from = msg.sender;
        
        // Cannot transfer from a blacklisted address
        require(!isBlacklisted(from), "ERROR: Unauthorized");
        
        // Cannot transfer to a blacklisted address
        require(!isBlacklisted(to), "ERROR: Blacklisted recipient");
        
        // Cannot conduct a verified transfer to an unverified address
        require(isVerified(to), "ERROR: Unverified recipient");
        
        // Cannot transfer from a locked address
        require(!isLocked(from), "ERROR: Sender is locked");
        
        // Cannot transfer to a locked address
        require(!isLocked(to), "ERROR: Recipient is locked");

        _transfer(from, to, amount);

        return true;
    }

   /**
     * @notice Moves `amount` slivers from the Ethereum account at `from` to
     * the Ethereum account at `to`, emits a {Transfer} event, and emits an
     * {Approval} event to track the updated allowance of the operator
     * @dev Per ERC-20 requirements, transfers of 0 credits are treated as
     * normal transfers and emit the {Transfer} event. This operation will
     * revert if the operator's Ethereum account, the {from} account, or the
     * {to} account is blacklisted or locked or if any input arguments violate
     * rules in the {_spendAllowance} or {_transfer} functions. Standard
     * transfers cannot be conducted when this contract is paused.
     * @param from The address of the sender's Ethereum account
     * @param to The address of the recipient's Ethereum account
     * @param amount The total amount of credits (in slivers) to be transferred
     * @return success A Boolean value indicating that the transfer was
     * successful
     */
    function transferFrom(address from, address to, uint256 amount)
        public
        isRunning
        returns (bool success)
    {
        address spender = msg.sender;
        
        // Cannot initiate a verified transfer using a blacklisted address
        require(!isBlacklisted(spender), "ERROR: Unauthorized");
        
        // Cannot conduct a verified transfer from a blacklisted address
        require(!isBlacklisted(from), "ERROR: Blacklisted sender");
        
        // Cannot conduct a verified transfer to a blacklisted address
        require(!isBlacklisted(to), "ERROR: Blacklisted recipient");
        
        // Cannot initiate transfer from a locked address
        require(!isLocked(spender), "ERROR: Spender is locked");
        
        // Cannot transfer from a locked address
        require(!isLocked(from), "ERROR: Sender is locked");
        
        // Cannot transfer to a locked address
        require(!isLocked(to), "ERROR: Recipient is locked");
        
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);

        return true;
    }

   /**
     * @notice Moves `amount` slivers from the Ethereum account at `from` to
     * the Ethereum account at `to` (if the recipient is verified), emits a
     * {Transfer} event, and emits an {Approval} event to track the updated
     * allowance value of the operator
     * @dev Per ERC-20 requirements, transfers of 0 credits are treated as
     * normal transfers and emit the {Transfer} event. This operation will
     * revert if the operator's Ethereum account, the {from} account, or the
     * {to} account is blacklisted or locked, the {to} account is unverified,
     * or if any input arguments violate rules in the {_spendAllowance} or
     * {_transfer} functions. Verified transfers cannot be conducted when this
     * contract is paused.
     * @param from The address of the sender's Ethereum account
     * @param to The address of the recipient's Ethereum account
     * @param amount The total amount of credits (in slivers) to be transferred
     * @return success A Boolean value indicating that the transfer was
     * successful
     */
    function verifiedTransferFrom(address from, address to, uint256 amount)
        public
        isRunning
        returns (bool success)
    {
        address spender = msg.sender;
       
        // Cannot initiate a verified transfer using a blacklisted address
        require(!isBlacklisted(spender), "ERROR: Unauthorized");
        
        // Cannot conduct a verified transfer from a blacklisted address
        require(!isBlacklisted(from), "ERROR: Blacklisted sender");
        
        // Cannot conduct a verified transfer to a blacklisted address
        require(!isBlacklisted(to), "ERROR: Blacklisted recipient");
        
        // Cannot conduct a verified transfer to an unverified address
        require(isVerified(to), "ERROR: Unverified recipient");
        
        // Cannot initiate transfer from a locked address
        require(!isLocked(spender), "ERROR: Spender is locked");
        
        // Cannot transfer from a locked address
        require(!isLocked(from), "ERROR: Sender is locked");
        
        // Cannot transfer to a locked address
        require(!isLocked(to), "ERROR: Recipient is locked");

        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);

        return true;
    }    

    /**
     * @notice Authorizes the Ethereum account at `spender` to transfer up to
     * `amount` slivers from the operator's Ethereum account to any other
     * Ethereum account or accounts of the spender's choosing (up to the
     * allowance limit) and emits an {Approval} event
     * @dev This operation will revert if the operator's Ethereum account or
     * the {spender} account is blacklisted. Approvals cannot be conducted when
     * this contract is paused. Approvals for the MAX uint256 value of slivers
     * are considered infinite and will not be decremented automatically during
     * subsequent authorized transfers.
     * @param spender The address of the authorized Ethereum account
     * @param amount The allowance of credits (in slivers) to be authorized for
     * transfer by the {spender} account
     * @return success A Boolean value indicating that the allowance has been
     * updated successfully
     */
    function approve(address spender, uint256 amount)
        public
        isRunning
        returns (bool success)
    {
        address owner = msg.sender;
        
        // Cannot approve transactions from a blacklisted address
        require(!isBlacklisted(owner), "ERROR: Unauthorized");
        
        // Cannot approve transactions for a blacklisted address
        require(!isBlacklisted(spender), "ERROR: Blacklisted spender");

        _approve(owner, spender, amount);
        
        return true;
    }

    /**
     * @notice Authorizes the Ethereum account at `spender` (if verified) to
     * transfer up to `amount` slivers from the operator's Ethereum account to
     * any Ethereum account or accounts of the spender's choosing (up to the
     * allowance limit) and emits an {Approval} event
     * @dev This operation will revert if the operator's Ethereum account or
     * the {spender} account is blacklisted or if the {spender} account is
     * unverified. Verified approvals cannot be conducted when this contract is
     * paused. Approvals for the MAX uint256 value of slivers are considered
     * infinite and will not be decremented automatically during subsequent
     * authorized transfers.
     * @param spender The address of the authorized Ethereum account
     * @param amount The allowance of credits (in slivers) to be authorized for
     * transfer by the {spender} account
     * @return success A Boolean value indicating that the allowance has been
     * updated successfully
     */
    function verifiedApprove(address spender, uint256 amount)
        public
        isRunning
        returns (bool success)
    {
        address owner = msg.sender;   
        
        // Cannot approve transactions from a blacklisted address
        require(!isBlacklisted(owner), "ERROR: Unauthorized");
        
        // Cannot approve transactions for a blacklisted address
        require(!isBlacklisted(spender), "ERROR: Blacklisted spender");
        
        // Spender address must be verified.
        require(isVerified(spender), "ERROR: Unverified spender");

        _approve(owner, spender, amount);
        
        return true;
    }

    /**
     * @notice Authorizes the Ethereum account at `spender` to transfer up to
     * `addedValue` additional slivers from the operator's Ethereum account to
     * any Ethereum account or accounts of the spender's choosing (up to the
     * updated allowance limit) and emits an {Approval} event
     * @dev This operation will revert if the operator's Ethereum account or
     * the {spender} account is blacklisted or if the resulting allowance value
     * would be larger than the MAX uint256 value. Allowance increases cannot
     * be conducted when this contract is paused.
     * @param spender The address of the authorized Ethereum account
     * @param addedValue The amount of credits (in slivers) to be added to the
     * allowance of the {spender} account
     * @return success A Boolean value indicating that the allowance has been
     * updated successfully
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        isRunning
        returns (bool success)
    {
        address owner = msg.sender;
        
        // Cannot increase allowance from a blacklisted address
        require(!isBlacklisted(owner), "ERROR: Unauthorized");
        
        // Cannot increase allowance for a blacklisted address
        require(!isBlacklisted(spender), "ERROR: Blacklisted spender");
        
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        
        return true;
    }

    /**
     * @notice Authorizes the Ethereum account at `spender` (if verified) to
     * transfer up to `addedValue` additional slivers from the operator's
     * Ethereum account to any Ethereum account or accounts of the spender's
     * choosing (up to the updated allowance limit) and emits an {Approval}
     * event
     * @dev This operation will revert if the operator's Ethereum account or
     * the {spender} account is blacklisted, if the resulting allowance value
     * would be larger than the MAX uint256 value, or if the {spender} account
     * is unverified. Verified allowance increases cannot be conducted when
     * this contract is paused.
     * @param spender The address of the authorized Ethereum account
     * @param addedValue The amount of credits (in slivers) to be added to the
     * allowance of the {spender} account
     * @return success A Boolean value indicating that the allowance has been
     * updated successfully
     */
    function verifiedIncreaseAllowance(address spender, uint256 addedValue)
        public
        isRunning
        returns (bool success)
    {
        address owner = msg.sender;     
        
        // Cannot increase allowance from a blacklisted address
        require(!isBlacklisted(owner), "ERROR: Unauthorized");
        
        // Cannot increase allowance for a blacklisted address
        require(!isBlacklisted(spender), "ERROR: Blacklisted spender");
        
        // Spender address must be verified
        require(isVerified(spender), "ERROR: Unverified spender");
        
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        
        return true;
    }

    /**
     * @notice Removes `subtractedValue` slivers from the allowance of
     * the Ethereum account at `spender` for the operator's Ethereum account
     * and emits an {Approval} event
     * @dev This operation will revert if the operator's Ethereum account or
     * the {spender} account is blacklisted or if the resulting allowance value
     * would be negative. Allowance decreases cannot be conducted when this
     * contract is paused.
     * @param spender The address of the authorized Ethereum account
     * @param subtractedValue The amount of credits (in slivers) to be removed
     * from the allowance of the {spender} account
     * @return success A Boolean value indicating that the allowance has been
     * updated successfully
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        isRunning
        returns (bool success)
    {
        address owner = msg.sender;        
        
        // Cannot decrease allowance from a blacklisted address
        require(!isBlacklisted(owner), "ERROR: Unauthorized");
        
        // Cannot decrease allowance for a blacklisted address
        require(!isBlacklisted(spender), "ERROR: Blacklisted spender");
        
        uint256 currentAllowance = allowance(owner, spender);
        
        // Cannot decrease allowance below zero
        require(currentAllowance >= subtractedValue);
        
        _approve(owner, spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @notice Removes `subtractedValue` slivers from the allowance of
     * the Ethereum account at `spender` (if verified) for the operator's
     * Ethereum account and emits an {Approval} event
     * @dev This operation will revert if the operator's Ethereum account or
     * the {spender} account is blacklisted, if the resulting allowance value
     * would be negative, or if the {spender} account is unverified. Verified
     * allowance decreases cannot be conducted when this contract is paused.
     * @param spender The address of the authorized Ethereum account
     * @param subtractedValue The amount of credits (in slivers) to be removed
     * from the allowance of the {spender} account
     * @return success A Boolean value indicating that the allowance has been
     * updated successfully
     */
    function verifiedDecreaseAllowance(
        address spender, 
        uint256 subtractedValue
    )
        public
        isRunning
        returns (bool success)
    {
        address owner = msg.sender;

        // Cannot decrease allowance from a blacklisted address
        require(!isBlacklisted(owner), "ERROR: Unauthorized");
        
        // Cannot decrease allowance for a blacklisted address
        require(!isBlacklisted(spender), "ERROR: Blacklisted spender");
        
        // Spender address must be verified
        require(isVerified(spender), "ERROR: Unverified spender");
        
        uint256 currentAllowance = allowance(owner, spender);
        
        // Cannot decrease allowance below zero
        require(currentAllowance >= subtractedValue);
        
        _approve(owner, spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @notice Updates the {UserStatus} record of the Ethereum account at
     * `targetAddress` to contain a {status} value of `status` and an {info}
     * value of `info` and emits an {UpdateUserStatus} event
     * @dev This is a restricted utility function and can be conducted
     * regardless of the current running state of this contract. {status} may
     * be any value in the {Statuses} enumeration, and {info} should be
     * provided in the format {creationDate: "yyyy-MM-dd", expirationDate:
     * "yyyy-MM-dd", message: ""}, where all properties are optional, and
     * {creationDate} and {expirationDate} are dates represented as strings in
     * ISO 8601 standard date format. {creationDate} and {expirationDate} will
     * only be included in Ethereum medallion accounts in the "Verified"
     * status, and {message} may be included in the {info} property of any
     * Ethereum account that we need to send an on-chain message.
     *
     * This operation will revert if the provided value of {status} does not
     * correspond to a valid {Statuses} value. Updating the {status} of an
     * address to "Blacklisted" will automatically lock the corresponding
     * Ethereum account, and it will need to be unlocked (in addition to
     * unblacklisted) in order to restore its ability to conduct transactions
     * and allowance operations.
     * @param targetAddress The address of the Ethereum account to be updated
     * @param status The {status} value to be assigned to the {UserStatus}
     * record of the target Ethereum account
     * @param info The {info} value to be assigned to the {UserStatus} record
     * of the target Ethereum account
     * @return success A Boolean value indicating that the provided {status}
     * and {info} were successfully assigned to the {UserStatus} record of the
     * target Ethereum account
     */
    function updateUserStatus(
        address targetAddress,
        Statuses status,
        string memory info
    )
        public
        onlyManager 
        returns (bool success)
    {
        if (
            (status == Statuses.Blacklisted) &&
            !isLocked(targetAddress)
        ) {
            _lock(targetAddress);
        }

        _userStatuses[targetAddress] = UserStatus({
            status: status,
            info: info            
        });

        emit UpdateUserStatus(targetAddress, status, info);

        return true;
    }

    /**
     * @notice Moves `amount` slivers from the Ethereum account at `from` to
     * the Ethereum account at `to` (regardless of user or account status) and
     * emits a {ForceTransfer} event. In the event that `amount` is greater
     * than the available balance of the account at `to`, the entire available
     * balance will be transferred.
     * @dev This is a restricted utility function and can be conducted
     * regardless of the current running state of this contract. This operation
     * will revert if the {from} account has an available balance of less than
     * the provided {amount}. Force transfers can be conducted regardless of
     * the current running state of this contract.
     * @param from The address of the sender's Ethereum account
     * @param to The address of the recipient's Ethereum account
     * @param amount The amount of credits (in slivers) to be transferred
     * @return success A Boolean value indicating that the transfer was
     * successful
     */
    function forceTransfer(address from, address to, uint256 amount)
        public
        onlyManager
        returns (bool success)
    {       
        uint256 availableBalance = availableBalanceOf(from);

        // Transfer all slivers in the account if {amount} is greater than the
        // available account balance
        if(amount > availableBalance) {
            amount = availableBalance;
        }

        _balances[from] -= amount;
        _balances[to] += amount;

        emit ForceTransfer(from, to, amount);

        return true;
    }

    /**
     * @notice Freezes `amount` slivers in the Ethereum account at
     * `targetAddress` and emits a {Freeze} event
     * @dev This is a restricted utility function and can be conducted
     * regardless of the current running state of this contract. In the event
     * that the {amount} value is greater than the available balance of the
     * Ethereum account at {targetAddress}, the entire balance of that account
     * will be frozen.
     * @param targetAddress The address of the Ethereum account where credits
     * will be frozen
     * @param amount The total number of credits (in slivers) to be frozen
     * @return success A Boolean value indicating that the provided {amount} of
     * credits (in slivers) was succesfully frozen
     */
    function freeze(address targetAddress, uint256 amount)
        public
        onlyManager
        returns (bool success)
    {       
        uint256 availableBalance = availableBalanceOf(targetAddress);
        
        // Freeze all tokens if available balance is less than or equal to
        // target amount, otherwise, just increase the frozen balance by the
        // amount
        if (availableBalance <= amount) {
            _frozenBalances[targetAddress] = _balances[targetAddress];
        } else {
            _frozenBalances[targetAddress] += amount;
        }

        emit Freeze(
            targetAddress, 
            availableBalance - availableBalanceOf(targetAddress)
        );

        return true;
    }

    /**
     * @notice Unfreezes `amount` slivers in the Ethereum account at
     * `targetAddress` and emits an {Unfreeze} event
     * @dev This is a restricted utility function and can be conducted
     * regardless of the current running state of this contract. In the event
     * that the {amount} value is greater than the frozen balance of the
     * Ethereum account at {targetAddress}, the entire balance of that account
     * will be unfrozen.
     * @param targetAddress The address of the Ethereum account where credits
     * will be unfrozen
     * @param amount The total number of credits (in slivers) to be unfrozen
     * @return success A Boolean value indicating that the provided {amount}
     * of credits (in slivers) was succesfully unfrozen
     */    
    function unfreeze(address targetAddress, uint256 amount)
        public
        onlyManager
        returns (bool success)
    {
        uint256 frozenBalance = _frozenBalances[targetAddress];

        // Unfreeze all tokens if frozen balance is less than or equal to
        // target amount, otherwise, reduce the frozen balance by the amount
        if (frozenBalance <= amount) {
            _frozenBalances[targetAddress] = 0;
        } else {
            _frozenBalances[targetAddress] -= amount;
        }

        emit Unfreeze(
            targetAddress,
            frozenBalance - _frozenBalances[targetAddress]
        );

        return true;
    }

    /**
     * @notice Locks the Ethereum account at `targetAddress`
     * @dev This is a restricted utility function and can be conducted
     * regardless of the current running state of this contract. This operation
     * will revert if {targetAddress} violates any of the rules in the {_lock}
     * function.
     * @param targetAddress The address of the Ethereum account to be locked
     * @return success A Boolean value indicating that the Ethereum account was
     * successfully locked
     */
    function lock(address targetAddress)
        public
        onlyManager
        returns (bool success)
    {
        return _lock(targetAddress);
    }

    /**
     * @notice Unlocks the Ethereum account at `targetAddress`
     * @dev This is a restricted utility function and can be conducted
     * regardless of the current running state of this contract. This operation
     * will revert if {targetAddress} violates any of the rules in the
     * {_unlock} function.
     * @param targetAddress The address of the Ethereum account to be unlocked
     * @return success A Boolean value indicating that the Ethereum account was
     * successfully unlocked
     */
    function unlock(address targetAddress)
        public
        onlyManager
        returns (bool success)
    {
        return _unlock(targetAddress);
    }

    /**
     * @notice Mints `amount` slivers in the Ethereum account at
     * `targetAddress` and emits both {Mint} and {Transfer} events (per ERC-20
     * specifications)
     * @dev This is a restricted utility function and can be conducted
     * regardless of the current running state of this contract. This operation
     * will revert if {amount} would cause the value of {_totalSupply} to
     * exceed the MAX uint256 value.
     * @param targetAddress The address of the Ethereum account where credits
     * will be minted
     * @param amount The total number of credits (in slivers) to be minted
     * @return success A Boolean value indicating that the provided {amount} of
     * credits (in slivers) was successfully minted
     */
    function mint(address targetAddress, uint256 amount)
        public
        onlyManager
        returns (bool success)
    {   
        _totalSupply += amount;
        
        unchecked {
            _balances[targetAddress] += amount;   
        }

        emit Mint(targetAddress, amount);
        emit Transfer(address(0), targetAddress, amount);

        return true;
    }

    /**
     * @notice Burns `amount` slivers in the Ethereum account at
     * `targetAddress` and emits both {Burn} and {Transfer} events (per ERC-20
     * specifications)
     * @dev This is a restricted utility function and can be conducted
     * regardless of the current running state of this contract. This operation
     * will revert if the {amount} value is greater than the available balance
     * of the Ethereum account at {targetAddress}.
     * @param targetAddress The address of the Ethereum account where credits
     * will be burned
     * @param amount The total number of credits (in slivers) to be burned
     * @return success A Boolean value indicating that the provided {amount} of
     * credits (in slivers) was successfully burned
     */
    function burn(address targetAddress, uint256 amount)
        public
        onlyManager
        returns (bool success)
    {        
        // Amount of credits (in slivers) specified cannot be greater than the
        // available balance of the target address
        require((amount <= availableBalanceOf(targetAddress)));
        
        unchecked {
            _totalSupply -= amount;
            _balances[targetAddress] -= amount;   
        }

        emit Burn(targetAddress, amount);
        emit Transfer(targetAddress, address(0), amount);

        return true;
    }

    /**
     * @notice Pauses this contract, blocking all standard user operations
     * until this contract is resumed
     * @dev This is a restricted management function and can be conducted
     * only when this contract is running.
     * @return success A Boolean value indicating that this contract has been
     * successfully paused
     */
    function pause() public onlyManager returns (bool success) {
        // This contract must be running to continue
        require(_isRunning);

        _isRunning = false;

        emit Pause();

        return true;
    }

    /**
     * @notice Unpauses this contract, unblocking all standard user operations
     * @dev This is a restricted management function and can be conducted
     * only when this contract is not running.   
     * @return success A Boolean value indicating that this contract has been
     * successfully unpaused
     */
    function unpause() public onlyManager returns (bool success) {
        // This contract must be paused to continue
        require(!_isRunning);        
        
        _isRunning = true;
        
        emit Unpause();

        return true;
    }

    /**
     * @notice Adds `managerAddress` to the manager list and emits an
     * {AddManager} event
     * @dev This is a restricted management function and can be conducted
     * regardless of the current running state of this contract. This operation
     * will revert if an operator attempts to add the Master address or a
     * redundant address to the manager list, and it will also revert if the
     * manager list already contains two manager addresses.
     * @return success A Boolean value indicating that the new manager address
     * has been successfully added to the manager list
     */
    function addManager(address managerAddress)
        public
        onlyManager
        returns (bool success)
    {
        // Cannot add the Master address to the manager list
        require((_ownerAddress != managerAddress));

        // Cannot add redundant addresses to the manager list
        require(_managerAddresses[0] != managerAddress);
        require(_managerAddresses[1] != managerAddress);
        
        if (_managerAddresses[0] == address(0)) {
            _managerAddresses[0] = managerAddress;
        } else if(_managerAddresses[1] == address(0)) {
            _managerAddresses[1] = managerAddress;
        } else {
            // Manager list is full
            revert();
        }
        
        emit AddManager(managerAddress);

        return true;
    }

    /**
     * @notice Removes `managerAddress` from the manager list and emits a
     * {RemoveManager} event
     * @dev This is a restricted management function and can be conducted
     * regardless of the current running state of this contract. Upon removal
     * of a secondary manager address, the remaining manager address will be
     * moved to {_managerAddresses[0]}, allowing all {onlyManager} checks to be
     * conducted in O(1) time on a standard manager address (not the Master
     * address). This operation will revert if an operator attempts to remove
     * the Master address, if the manager list is empty, or if the provided
     * manager address is not found in the manager list.
     * @return success A Boolean value indicating that the provided manager
     * address has been successfully removed from the manager list
     */
    function removeManager(address managerAddress)
        public
        onlyManager
        returns (bool success)
    {
        // An operator cannot remove their own address from the manager list
        require((msg.sender != managerAddress));
        
        // Cannot remove manager status from the Master address
        require((_ownerAddress != managerAddress));
        
        if (_managerAddresses[0] == managerAddress) {
            // Keep a single manager address at the front of the manager list
            _managerAddresses[0] = _managerAddresses[1];
            _managerAddresses[1] = address(0);
        } else if (_managerAddresses[1] == managerAddress) {
            _managerAddresses[1] = address(0);
        }       
        else {
            // There is no manager with the address provided
            revert();
        }
        
        emit RemoveManager(managerAddress);

        return true;
    }

    /** 
     * @notice Removes all managers from the manager list and emits a
     * {PurgeManagers} event
     * @dev This is a restricted ownership function and can be conducted
     * regardless of the current running state of this contract.
     * @return success A Boolean value indicating that all manager addresses
     * were successfully purged (set to the zero address) from the manager list
     */
    function purgeManagers() public onlyOwner returns (bool success) {
        _managerAddresses[0] = _managerAddresses[1] = address(0);

        emit PurgeManagers();

        return true;
    }

    /**
     * @notice Removes all manager addresses from the manager list, resets the
     * Master address to the zero address, pauses this contract, resets 
     * {_isInitialized} to false, and emits a {Pause} event
     * @dev This is a restricted ownership function and can be conducted
     * regardless of the current running state of this contract.     
     * @return success A Boolean value indicating that the manager list has
     * been purged, the Master address has been cleared (set to the zero
     * address), {_isInitialized} has been set to "false", and this contract
     * has been paused
     */
    function terminateContract() public onlyOwner returns (bool success) {
        _ownerAddress =
        _managerAddresses[0] =
        _managerAddresses[1] =
        address(0);

        _isRunning = false;
        _isInitialized = false;
        
        emit Pause();

        return true;
    }    

    /**
     * @dev This function moves `amount` slivers from the operator's Ethereum
     * account at `from` to the recipient's Ethereum account at `to` and emits
     * a {Transfer} event. This operation will revert if the account at `from`
     * has an available balance of less than `amount` slivers.
     * @param from The address of the sender's Ethereum account
     * @param to The address of the recipient's Ethereum account
     * @param amount The amount of credits (in slivers) to be transferred
     */
    function _transfer(address from, address to, uint256 amount) internal {        
        // Transfer amount cannot exceed available balance
        require((availableBalanceOf(from) >= amount));

        _balances[from] -= amount;
        _balances[to] += amount;

        emit Transfer(from, to, amount);
    }
    
    /**
     * @dev This function authorizes the Ethereum account at `spender` to
     * transfer up to `amount` slivers from the Ethereum account at `owner` to
     * any Ethereum account or accounts of the spender's choosing (up to the
     * allowance limit) and emits an {Approval} event. Approvals for the MAX
     * uint256 value of slivers are considered infinite and will not be
     * decremented automatically during subsequent authorized transfers.
     * @param owner The address of the authorizing Ethereum account
     * @param spender The address of the authorized Ethereum account
     * @param amount The allowance of credits (in slivers) to be authorized for
     * transfer by the {spender} account
     */
    function _approve(address owner, address spender, uint256 amount)
        internal 
    {
        _allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }
    
    /**
     * @dev This function removes `amount` slivers from the allowance of the
     * Ethereum account at `spender` that it would be authorized to transfer on
     * behalf of the Ethereum account at `owner` and emits an {Approval} event.
     * This operation will revert if `amount` is greater than the current
     * allowance of the account at `spender` and will exit without effect if
     * the current allowance of the account at `spender` is the MAX uint256
     * value.
     * @param owner The address of the authorizing Ethereum account
     * @param spender The address of the authorized Ethereum account
     * @param amount The amount of credits (in slivers) to be removed from the
     * allowance of the {spender} account
     */
    function _spendAllowance(address owner, address spender, uint256 amount)
        internal
    {
        uint256 currentAllowance = allowance(owner, spender);
        
        if (currentAllowance != type(uint256).max) {
            // Current allowance must be greater than or equal to the
            // transaction amount
            require(currentAllowance >= amount);

            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }
    
    /**
     * @dev This function locks the Ethereum account at `targetAddress` and
     * emits a {Lock} event. This operation will revert if `targetAddress` is
     * already locked.
     * @param targetAddress The address of the Ethereum account to be locked
     * @return success A Boolean value indicating that the Ethereum account was
     * successfully locked
     */
    function _lock(address targetAddress) internal returns (bool success) {  
        // Cannot lock an address that is already locked
        require(!_lockedAddresses[targetAddress]);

        _lockedAddresses[targetAddress] = true;
        
        emit Lock(targetAddress);

        return true;
    }

    /**
     * @dev This function unlocks the Ethereum account at `targetAddress` and
     * emits an {Unlock} event. This operation will revert if `targetAddress`
     * is already unlocked.
     * @param targetAddress The address of the Ethereum account to be unlocked
     * @return success A Boolean value indicating that the Ethereum account was
     * successfully unlocked
     */
    function _unlock(address targetAddress) internal returns (bool success) {    
        // Cannot unlock an address that is already unlocked
        require(_lockedAddresses[targetAddress]);
 
        _lockedAddresses[targetAddress] = false;

        emit Unlock(targetAddress);

        return true;
    }
}