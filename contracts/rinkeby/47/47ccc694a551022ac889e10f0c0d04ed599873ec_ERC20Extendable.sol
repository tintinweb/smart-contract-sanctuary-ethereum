/**
 *Submitted for verification at Etherscan.io on 2022-03-24
*/

pragma solidity ^0.8.0;

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol

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

// File: contracts/tokens/IToken.sol

pragma solidity ^0.8.0;

/**
* @dev A struct containing information about the current token transfer.
* @param token Token address that is executing this extension.
* @param payload The full payload of the initial transaction.
* @param partition Name of the partition (left empty for ERC20 transfer).
* @param operator Address which triggered the balance decrease (through transfer or redemption).
* @param from Token holder.
* @param to Token recipient for a transfer and 0x for a redemption.
* @param value Number of tokens the token holder balance is decreased by.
* @param data Extra information (if any).
* @param operatorData Extra information, attached by the operator (if any).
*/
struct TransferData {
    address token;
    bytes payload;
    bytes32 partition;
    address operator;
    address from;
    address to;
    uint256 value;
    uint256 tokenId;
    bytes data;
    bytes operatorData;
}

/**
* @notice An enum of different token standards by name
*/
enum TokenStandard {
    ERC20,
    ERC721,
    ERC1400,
    ERC1155
}

/**
* @title Token Interface
* @dev A standard interface all token standards must inherit from. Provides token standard agnostic 
* functions
*/
interface IToken {
    /**
    * @notice Perform a transfer given a TransferData struct. Only addresses with the token controllers 
    * role should be able to invoke this function.
    * @return bool If this contract does not support the transfer requested, it should return false. 
    * If the contract does support the transfer but the transfer is impossible, it should revert. 
    * If the contract does support the transfer and successfully performs the transfer, it should return true
    */
    function tokenTransfer(TransferData calldata transfer) external returns (bool);

    /**
    * @notice A function to determine what token standard this token implements. This
    * is a pure function, meaning the value should not change
    * @return TokenStandard The token standard this token implements
    */
    function tokenStandard() external pure returns (TokenStandard);
}

// File: contracts/interface/ITokenRoles.sol

pragma solidity ^0.8.0;

interface ITokenRoles {
    function manager() external view returns (address);

    function isController(address caller) external view returns (bool);

    function isMinter(address caller) external view returns (bool);

    function addController(address caller) external;

    function removeController(address caller) external;

    function addMinter(address caller) external;

    function removeMinter(address caller) external;

    function changeManager(address newManager) external;

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() external view returns (address);

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external;

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external;
}

// File: contracts/tools/DomainAware.sol

/*
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */
pragma solidity ^0.8.0;

/**
* @title Domain-Aware contract interface
* @notice This can be used to interact with a DomainAware contract of any type.
* @dev An interface that represents a DomainAware contract. This interface provides
* all public/external facing functions that the DomainAware contract implements.
*/
interface IDomainAware {
    /**
    * @dev Uses _domainName()
    * @notice The domain name for this contract used in the domain seperator. 
    * This value will not change and will have a length greater than 0.
    * @return bytes The domain name represented as bytes
    */
    function domainName() external view returns (bytes memory);

    /**
    * @dev The current version for this contract. Changing this value will
    * cause the domain separator to update and trigger a cache update.
    */
    function domainVersion() external view returns (bytes32);

    /**
    * @notice Generate the domain seperator hash for this contract using the contract's
    * domain name, current domain version and the current chain-id. This call bypasses the stored cache and
    * will always represent the current domain seperator for this Contract's name + version + chain id. 
    * @return bytes32 The domain seperator hash.
    */
    function generateDomainSeparator() external view returns (bytes32);

    /**
    * @notice Get the current domain seperator hash for this contract using the contract's
    * domain name, current domain version and the current chain-id. 
    * @dev This call is cached by the chain-id and contract version. If these two values do not 
    * change then the cached domain seperator hash is returned. If these two values do change,
    * then a new hash is generated and the cache is updated
    * @return bytes32 The current domain seperator hash
    */
    function domainSeparator() external returns (bytes32);
}

/**
* @title Domain-Aware contract
* @notice This should be inherited by any contract that plans on using the EIP712 
* typed structured data signing 
* @dev A generic contract to be used by contract plans on using the EIP712 typed structure
* data signing. This contract offers a way to generate the EIP712Domain seperator for the
* contract that extends from this. 
*
* The EIP712 domain seperator generated depends on the domain name and domain version of the child
* contract. Therefore, a child contract must implement the _domainName() and _domainVersion() functions in order
* to complete the implementation. 
* The child contract may return whatever it likes for the _domainName(), however this value should not change
* after deployment. Changing the result of the _domainName() function between calls may result in undefined behavior.
* The _domainVersion() must be a bytes32 and that _domainName() must have a length greater than 0.
*
* If a child contract changes the domain version after deployment, then the domain seperator will 
* update to reflect the new version.
*
* This contract stores the domain seperator for each chain-id detected after deployment. This
* means if the contract were to fork to a new blockchain with a new chain-id, then the domain-seperator
* of this contract would update to reflect the new domain context. 
*
*/
abstract contract DomainAware is IDomainAware {

    /**
    * @dev The storage slot the DomainData is stored in this contract
    */
    bytes32 constant DOMAIN_AWARE_SLOT = keccak256("domainaware.data");

    /**
    * @dev The cached DomainData for this chain & contract version.
    * @param domainSeparator The cached domainSeperator for this chain + contract version
    * @param version The contract version this DomainData is for
    */
    struct DomainData {
        bytes32 domainSeparator;
        bytes32 version; 
    }

    /**
    * @dev The struct storing all the DomainData cached for each chain-id.
    * This is a very gas efficient way to not recalculate the domain separator 
    * on every call, while still automatically detecting ChainID changes.
    * @param chainToDomainData Mapping of ChainID to domain separators. 
    */
    struct DomainAwareData {
        mapping(uint256 => DomainData) chainToDomainData;
    }

    /**
    * @dev If in the constructor we have a non-zero domain name, then update the domain seperator now.
    * Otherwise, the child contract will need to do this themselves
    */
    constructor() {
        if (_domainName().length > 0) {
            _updateDomainSeparator();
        }
    }

    /**
    * @dev The domain name for this contract. This value should not change at all and should have a length
    * greater than 0.
    * Changing this value changes the domain separator but does not trigger a cache update so may
    * result in undefined behavior
    * TODO Fix cache issue? Gas inefficient since we don't know if the data has updated?
    * We can't make this pure because ERC20 requires name() to be view.
    * @return bytes The domain name represented as a bytes
    */
    function _domainName() internal virtual view returns (bytes memory);

    /**
    * @dev The current version for this contract. Changing this value will
    * cause the domain separator to update and trigger a cache update.
    */
    function _domainVersion() internal virtual view returns (bytes32);

    /**
    * @dev Uses _domainName()
    * @notice The domain name for this contract used in the domain seperator. 
    * This value will not change and will have a length greater than 0.
    * @return bytes The domain name represented as bytes
    */
    function domainName() external override view returns (bytes memory) {
        return _domainName();
    }

    /**
    * @dev Uses _domainName()
    * @notice The current version for this contract. This is the domain version
    * used in the domain seperator
    */
    function domainVersion() external override view returns (bytes32) {
        return _domainVersion();
    }

    /**
    * @dev Get the DomainAwareData struct stored in this contract.
    */
    function domainAwareData() private pure returns (DomainAwareData storage ds) {
        bytes32 position = DOMAIN_AWARE_SLOT;
        assembly {
            ds.slot := position
        }
    }

    /**
    * @notice Generate the domain seperator hash for this contract using the contract's
    * domain name, current domain version and the current chain-id. This call bypasses the stored cache and
    * will always represent the current domain seperator for this Contract's name + version + chain id. 
    * @return bytes32 The domain seperator hash.
    */
    function generateDomainSeparator() public override view returns (bytes32) {
        uint256 chainID = _chainID();
        bytes memory dn = _domainName();
        bytes memory dv = abi.encodePacked(_domainVersion());

        require(dn.length > 0, "Domain name is empty");
        require(dv.length > 0, "Domain version is empty");

        // no need for assembly, running very rarely
        bytes32 domainSeparatorHash = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(dn), // ERC-20 Name
                keccak256(dv), // Version
                chainID,
                address(this)
            )
        );

        return domainSeparatorHash;
    }

    /**
    * @notice Get the current domain seperator hash for this contract using the contract's
    * domain name, current domain version and the current chain-id. 
    * @dev This call is cached by the chain-id and contract version. If these two values do not 
    * change then the cached domain seperator hash is returned. If these two values do change,
    * then a new hash is generated and the cache is updated
    * @return bytes32 The current domain seperator hash
    */
    function domainSeparator() public override returns (bytes32) {
        return _domainSeparator();
    }

    /**
    * @dev Generate and update the cached domain seperator hash for this contract 
    * using the contract's domain name, current domain version and the current chain-id. 
    * This call will always overwrite the cache even if the cached data of the same.
    * @return bytes32 The current domain seperator hash that was stored in cache
    */
    function _updateDomainSeparator() internal returns (bytes32) {
        uint256 chainID = _chainID();

        bytes32 newDomainSeparator = generateDomainSeparator();

        require(newDomainSeparator != bytes32(0), "Invalid domain seperator");

        domainAwareData().chainToDomainData[chainID] = DomainData(
            newDomainSeparator,
            _domainVersion()
        );

        return newDomainSeparator;
    }

    /**
    * @dev Get the current domain seperator hash for this contract using the contract's
    * domain name, current domain version and the current chain-id. 
    * This call is cached by the chain-id and contract version. If these two values do not 
    * change then the cached domain seperator hash is returned. If these two values do change,
    * then a new hash is generated and the cache is updated
    * @return bytes32 The current domain seperator hash
    */
    function _domainSeparator() private returns (bytes32) {
        uint256 chainID = _chainID();
        bytes32 reportedVersion = _domainVersion();

        DomainData memory currentDomainData = domainAwareData().chainToDomainData[chainID];

        if (currentDomainData.domainSeparator != 0x00 && currentDomainData.version == reportedVersion) {
            return currentDomainData.domainSeparator;
        }

        return _updateDomainSeparator();
    }

    /**
    * @dev Get the current chain-id. This is done using the chainid opcode.
    * @return uint256 The current chain-id as a number.
    */
    function _chainID() internal view returns (uint256) {
        uint256 chainID;
        assembly {
            chainID := chainid()
        }

        return chainID;
    }
}

// File: contracts/tokens/proxy/ITokenProxy.sol

pragma solidity ^0.8.0;



interface ITokenProxy is IToken, ITokenRoles, IDomainAware {
    fallback() external payable;

    receive() external payable;

    function upgradeTo(address logic, bytes memory data) external;
}

// File: contracts/tokens/proxy/ERC20/IERC20Proxy.sol

pragma solidity ^0.8.0;


/**
* @title Extendable ERC20 Proxy Interface
* @notice An interface to interact with an ERC20 Token (proxy).
*/
interface IERC20Proxy is IERC20Metadata, ITokenProxy {
    /**
    * @notice Returns true if minting is allowed on this token, otherwise false
    */
    function mintingAllowed() external view returns (bool);

    /**
    * @notice Returns true if burning is allowed on this token, otherwise false
    */
    function burningAllowed() external view returns (bool);


    /**
     * @notice Creates `amount` new tokens for `to`.
     *
     * @dev See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     * @param to The address to mint tokens to
     * @param amount The amount of new tokens to mint
     */
    function mint(address to, uint256 amount) external returns (bool);

    /**
     * @notice Destroys `amount` tokens from the caller.
     *
     * @dev See {ERC20-_burn}.
     * @param amount The amount of tokens to burn from the caller.
     */
    function burn(uint256 amount) external returns (bool);
    
    /**
     * @notice Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * @dev See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     * @param account The account to burn from
     * @param amount The amount of tokens to burn
     */
    function burnFrom(address account, uint256 amount) external returns (bool);

    /** 
     * @notice Atomically increases the allowance granted to `spender` by the caller.
     *
     * @dev This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * @param spender The address that will be given the allownace increase
     * @param addedValue How much the allowance should be increased by
     */
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    /**
     * @notice Atomically decreases the allowance granted to `spender` by the caller.
     *
     * @dev This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     * @param spender The address that will be given the allownace decrease
     * @param subtractedValue How much the allowance should be decreased by
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
}

// File: contracts/tokens/logic/ITokenLogic.sol

pragma solidity ^0.8.0;

/**
* @title Token Logic Interface
* @dev An interface that all Token Logic contracts should implement
*/
interface ITokenLogic is IToken {
    function initialize(bytes memory data) external;
}

// File: contracts/tokens/logic/ERC20/IERC20Logic.sol

pragma solidity ^0.8.0;


/**
* @title Upgradable ERC20 Logic Interface
* @notice An interface to interact with an ERC20 Token (logic).
*/
interface IERC20Logic is IERC20Metadata, ITokenLogic {
    /**
     * @notice Destroys `amount` tokens from the caller.
     *
     * @dev See {ERC20-_burn}.
     * @param amount The amount of tokens to burn from the caller.
     */
    function burn(uint256 amount) external returns (bool);

    /**
     * @notice Creates `amount` new tokens for `to`.
     *
     * @dev See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     * @param recipient The address to mint tokens to
     * @param amount The amount of new tokens to mint
     */
    function mint(address recipient, uint256 amount) external returns (bool);

    /**
     * @notice Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * @dev See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     * @param account The account to burn from
     * @param amount The amount of tokens to burn
     */
    function burnFrom(address account, uint256 amount) external returns (bool);

    /**
     * @notice Atomically decreases the allowance granted to `spender` by the caller.
     *
     * @dev This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     * @param spender The address that will be given the allownace decrease
     * @param amount How much the allowance should be decreased by
     */
    function decreaseAllowance(address spender, uint256 amount) external returns (bool);

    /** 
     * @notice Atomically increases the allowance granted to `spender` by the caller.
     *
     * @dev This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * @param spender The address that will be given the allownace increase
     * @param amount How much the allowance should be increased by
     */
    function increaseAllowance(address spender, uint256 amount) external returns (bool);
}

// File: @openzeppelin/contracts/utils/introspection/IERC1820Registry.sol

/**
 * @dev Interface of the global ERC1820 Registry, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1820[EIP]. Accounts may register
 * implementers for interfaces in this registry, as well as query support.
 *
 * Implementers may be shared by multiple accounts, and can also implement more
 * than a single interface for each account. Contracts can implement interfaces
 * for themselves, but externally-owned accounts (EOA) must delegate this to a
 * contract.
 *
 * {IERC165} interfaces can also be queried via the registry.
 *
 * For an in-depth explanation and source code analysis, see the EIP text.
 */
interface IERC1820Registry {
    /**
     * @dev Sets `newManager` as the manager for `account`. A manager of an
     * account is able to set interface implementers for it.
     *
     * By default, each account is its own manager. Passing a value of `0x0` in
     * `newManager` will reset the manager to this initial state.
     *
     * Emits a {ManagerChanged} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     */
    function setManager(address account, address newManager) external;

    /**
     * @dev Returns the manager for `account`.
     *
     * See {setManager}.
     */
    function getManager(address account) external view returns (address);

    /**
     * @dev Sets the `implementer` contract as ``account``'s implementer for
     * `interfaceHash`.
     *
     * `account` being the zero address is an alias for the caller's address.
     * The zero address can also be used in `implementer` to remove an old one.
     *
     * See {interfaceHash} to learn how these are created.
     *
     * Emits an {InterfaceImplementerSet} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     * - `interfaceHash` must not be an {IERC165} interface id (i.e. it must not
     * end in 28 zeroes).
     * - `implementer` must implement {IERC1820Implementer} and return true when
     * queried for support, unless `implementer` is the caller. See
     * {IERC1820Implementer-canImplementInterfaceForAddress}.
     */
    function setInterfaceImplementer(
        address account,
        bytes32 _interfaceHash,
        address implementer
    ) external;

    /**
     * @dev Returns the implementer of `interfaceHash` for `account`. If no such
     * implementer is registered, returns the zero address.
     *
     * If `interfaceHash` is an {IERC165} interface id (i.e. it ends with 28
     * zeroes), `account` will be queried for support of it.
     *
     * `account` being the zero address is an alias for the caller's address.
     */
    function getInterfaceImplementer(address account, bytes32 _interfaceHash) external view returns (address);

    /**
     * @dev Returns the interface hash for an `interfaceName`, as defined in the
     * corresponding
     * https://eips.ethereum.org/EIPS/eip-1820#interface-name[section of the EIP].
     */
    function interfaceHash(string calldata interfaceName) external pure returns (bytes32);

    /**
     * @notice Updates the cache with whether the contract implements an ERC165 interface or not.
     * @param account Address of the contract for which to update the cache.
     * @param interfaceId ERC165 interface for which to update the cache.
     */
    function updateERC165Cache(address account, bytes4 interfaceId) external;

    /**
     * @notice Checks whether a contract implements an ERC165 interface or not.
     * If the result is not cached a direct lookup on the contract address is performed.
     * If the result is not cached or the cached value is out-of-date, the cache MUST be updated manually by calling
     * {updateERC165Cache} with the contract address.
     * @param account Address of the contract to check.
     * @param interfaceId ERC165 interface to check.
     * @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165Interface(address account, bytes4 interfaceId) external view returns (bool);

    /**
     * @notice Checks whether a contract implements an ERC165 interface or not without using nor updating the cache.
     * @param account Address of the contract to check.
     * @param interfaceId ERC165 interface to check.
     * @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165InterfaceNoCache(address account, bytes4 interfaceId) external view returns (bool);

    event InterfaceImplementerSet(address indexed account, bytes32 indexed interfaceHash, address indexed implementer);

    event ManagerChanged(address indexed account, address indexed newManager);
}

// File: contracts/erc1820/ERC1820Client.sol

pragma solidity ^0.8.0;

/// Base client to interact with the registry.
contract ERC1820Client {
    IERC1820Registry constant ERC1820REGISTRY = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    function setInterfaceImplementation(string memory _interfaceLabel, address _implementation) internal {
        bytes32 interfaceHash = keccak256(abi.encodePacked(_interfaceLabel));
        ERC1820REGISTRY.setInterfaceImplementer(address(this), interfaceHash, _implementation);
    }

    function interfaceAddr(address addr, string memory _interfaceLabel) internal view returns(address) {
        bytes32 interfaceHash = keccak256(abi.encodePacked(_interfaceLabel));
        return ERC1820REGISTRY.getInterfaceImplementer(addr, interfaceHash);
    }

    function delegateManagement(address _newManager) internal {
        ERC1820REGISTRY.setManager(address(this), _newManager);
    }
}

// File: contracts/interface/IERC1820Implementer.sol

/*
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */
pragma solidity ^0.8.0;

/// @dev The interface a contract MUST implement if it is the implementer of
/// some (other) interface for any address other than itself.
interface IERC1820Implementer {
    /// @notice Indicates whether the contract implements the interface 'interfaceHash' for the address 'addr' or not.
    /// @param interfaceHash keccak256 hash of the name of the interface
    /// @param addr Address for which the contract will implement the interface
    /// @return ERC1820_ACCEPT_MAGIC only if the contract implements 'interfaceHash' for the address 'addr'.
    function canImplementInterfaceForAddress(bytes32 interfaceHash, address addr) external view returns(bytes32);
}

// File: contracts/erc1820/ERC1820Implementer.sol

/*
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */
pragma solidity ^0.8.0;

contract ERC1820Implementer is IERC1820Implementer {
  bytes32 constant ERC1820_ACCEPT_MAGIC = keccak256(abi.encodePacked("ERC1820_ACCEPT_MAGIC"));

  mapping(address => mapping(bytes32 => bool)) internal _interfaceHashes;

  function canImplementInterfaceForAddress(bytes32 interfaceHash, address addr)
    external
    override
    view
    returns(bytes32)
  {
    //If we implement the interface for this address
    //or if we implement the interface for every address
    if(_interfaceHashes[addr][interfaceHash] || _interfaceHashes[address(0)][interfaceHash]) {
      return ERC1820_ACCEPT_MAGIC;
    } else {
      return "";
    }
  }

  //TODO Rename to _setInterfaceForAll
  function _setInterface(string memory interfaceLabel) internal {
    _setInterface(interfaceLabel, true, true);
  }

  function _setInterface(string memory interfaceLabel, bool forSelf, bool forAll) internal {
    //Implement the interface for myself
    if (forSelf)
      _interfaceHashes[address(this)][keccak256(abi.encodePacked(interfaceLabel))] = true;

    //Implement the interface for everyone
    if (forAll)
      _interfaceHashes[address(0)][keccak256(abi.encodePacked(interfaceLabel))] = true;
  }

  function _setInterfaceForAddress(string memory interfaceLabel, address addr) internal {
    //Implement the interface for addr
    _interfaceHashes[addr][keccak256(abi.encodePacked(interfaceLabel))] = true;
  }
  
  
  /**
  * This empty reserved space is put in place to allow future versions to add new
  * variables without shifting down storage in the inheritance chain.
  * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
  */
  uint256[49] private __gap;
}

// File: @openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol

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

// File: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol

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

// File: @openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol

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

// File: @openzeppelin/contracts/utils/StorageSlot.sol

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// File: contracts/roles/Roles.sol

/*
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */
pragma solidity ^0.8.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    function roleStorage(bytes32 _rolePosition) internal pure returns (Role storage ds) {
        bytes32 position = _rolePosition;
        assembly {
            ds.slot := position
        }
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

// File: contracts/roles/RolesBase.sol

pragma solidity ^0.8.0;

abstract contract RolesBase {
    using Roles for Roles.Role;

    event RoleAdded(address indexed caller, bytes32 indexed roleId);
    event RoleRemoved(address indexed caller, bytes32 indexed roleId);
    
    function hasRole(address caller, bytes32 roleId) public view returns (bool) {
        return Roles.roleStorage(roleId).has(caller);
    }

    function _addRole(address caller, bytes32 roleId) internal {
        Roles.roleStorage(roleId).add(caller);

        emit RoleAdded(caller, roleId);
    }

    function _removeRole(address caller, bytes32 roleId) internal {
        Roles.roleStorage(roleId).remove(caller);

        emit RoleRemoved(caller, roleId);
    }
}

// File: contracts/roles/TokenRoles.sol

pragma solidity ^0.8.0;





/**
* @title Token Roles
* @notice A base contract for handling token roles. 
* @dev This contract is responsible for the storage and API of access control
* roles that all tokens should implement. This includes the following roles
*  * Owner
*     - A single owner address of the token, as implemented as Ownerable
*  * Minter
      - The access control role that allows an address to mint tokens
*  * Manager
*     - The single manager address of the token, can manage extensions
*  * Controller
*     - The access control role that allows an address to perform controlled-transfers
* 
* This contract also handles the storage of the burning/minting toggling.
*/
abstract contract TokenRoles is ITokenRoles, RolesBase, ContextUpgradeable {
    using Roles for Roles.Role;

    /**
    * @dev The storage slot for the burn/burnFrom toggle
    */
    bytes32 constant TOKEN_ALLOW_BURN = keccak256("token.proxy.core.burn");
    /**
    * @dev The storage slot for the mint toggle
    */
    bytes32 constant TOKEN_ALLOW_MINT = keccak256("token.proxy.core.mint");
    /**
    * @dev The storage slot that holds the current Owner address
    */
    bytes32 constant TOKEN_OWNER = keccak256("token.proxy.core.owner");
    /**
    * @dev The access control role ID for the Minter role
    */
    bytes32 constant TOKEN_MINTER_ROLE = keccak256("token.proxy.core.mint.role");
    /**
    * @dev The storage slot that holds the current Manager address
    */
    bytes32 constant TOKEN_MANAGER_ADDRESS = bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1);
    /**
    * @dev The access control role ID for the Controller role
    */
    bytes32 constant TOKEN_CONTROLLER_ROLE = keccak256("token.proxy.controller.address");
    
    /**
    * @notice This event is triggered when transferOwnership is invoked
    * @param previousOwner The previous owner before the transfer
    * @param newOwner The new owner of the token
    */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    /**
    * @notice This event is triggered when the manager address is updated. This
    * can occur when transferOwnership is invoked or when changeManager is invoked.
    * This event name is taken from EIP1967
    * @param previousAdmin The previous manager before the update
    * @param newAdmin The new manager of the token
    */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
    * @dev A function modifier that will only allow the current token manager to
    * invoke the function
    */
    modifier onlyManager {
        require(_msgSender() == manager(), "This function can only be invoked by the manager");
        _;
    }

    /**
    * @dev A function modifier that will only allow addresses with the Minter role granted
    * to invoke the function
    */
    modifier onlyMinter {
        require(isMinter(_msgSender()), "This function can only be invoked by a minter");
        _;
    }

    /**
    * @dev A function modifier that will only allow addresses with the Controller role granted
    * to invoke the function
    */
    modifier onlyControllers {
        require(isController(_msgSender()), "This function can only be invoked by a controller");
        _;
    }
    
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
    * @notice Returns the current token manager
    */
    function manager() public override view returns (address) {
        return StorageSlot.getAddressSlot(TOKEN_MANAGER_ADDRESS).value;
    }

    /**
    * @notice Returns true if `caller` has the Controller role granted
    */
    function isController(address caller) public override view returns (bool) {
        return hasRole(caller, TOKEN_CONTROLLER_ROLE);
    }

    /**
    * @notice Returns true if `caller` has the Minter role granted
    */
    function isMinter(address caller) public override view returns (bool) {
        return hasRole(caller, TOKEN_MINTER_ROLE);
    }

    /**
    * @notice Grant the Controller role to `caller`. Only addresses with
    * the Controller role granted may invoke this function
    * @param caller The address to grant the Controller role to
    */
    function addController(address caller) public override onlyControllers {
        _addRole(caller, TOKEN_CONTROLLER_ROLE);
    }

    /**
    * @notice Remove the Controller role from `caller`. Only addresses with
    * the Controller role granted may invoke this function
    * @param caller The address to remove the Controller role from
    */
    function removeController(address caller) public override onlyControllers {
        _removeRole(caller, TOKEN_CONTROLLER_ROLE);
    }

    /**
    * @notice Grant the Minter role to `caller`. Only addresses with
    * the Minter role granted may invoke this function
    * @param caller The address to grant the Minter role to
    */
    function addMinter(address caller) public override onlyMinter {
        _addRole(caller, TOKEN_MINTER_ROLE);
    }

    /**
    * @notice Remove the Minter role from `caller`. Only addresses with
    * the Minter role granted may invoke this function
    * @param caller The address to remove the Minter role from
    */
    function removeMinter(address caller) public override onlyMinter {
        _removeRole(caller, TOKEN_MINTER_ROLE);
    }

    /**
    * @notice Change the current token manager. Only the current token manager
    * can set a new token manager.
    * @dev This function is also invoked if transferOwnership is invoked
    * when the current token owner is also the current manager. 
    */
    function changeManager(address newManager) public override onlyManager {
        _changeManager(newManager);
    }

    function _changeManager(address newManager) private {
        address oldManager = manager();
        StorageSlot.getAddressSlot(TOKEN_MANAGER_ADDRESS).value = newManager;
        
        emit AdminChanged(oldManager, newManager);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public override view virtual returns (address) {
        return StorageSlot.getAddressSlot(TOKEN_OWNER).value;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public override virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @notice Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     * If the current owner is also the current manager, then the manager address
     * is also updated to be the new owner
     * @param newOwner The address of the new owner
     */
    function transferOwnership(address newOwner) public override virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     * If the current owner is also the current manager, then the manager address
     * is also updated to be the new owner
     * @param newOwner The address of the new owner
     */
    function _setOwner(address newOwner) private {
        address oldOwner = owner();
        StorageSlot.getAddressSlot(TOKEN_OWNER).value = newOwner;
        if (oldOwner == manager()) {
            _changeManager(newOwner);
        }
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/tokens/TokenERC1820Provider.sol

pragma solidity ^0.8.0;


/**
* @title ERC1820 Provider for Tokens
* @notice This is an abstract contract, you may want to inherit from
* the contracts in the registry folder
* @dev A base contract that provides ERC1820 functionality and also
* provides pure functions to obtain the interface name for both the
* current token logic contract and the current token contract
*/
abstract contract TokenERC1820Provider is ERC1820Implementer, ERC1820Client {
    /**
    * @dev The interface name for the token logic contract to be used in ERC1820.
    */
    function __tokenLogicInterfaceName() internal virtual pure returns (string memory);

    /**
    * @dev The interface name for the token contract to be used in ERC1820
    */
    function __tokenInterfaceName() internal virtual pure returns (string memory);
}

// File: solidity-bytes-utils/contracts/BytesLib.sol

// SPDX-License-Identifier: Unlicense
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.8.0 <0.9.0;


library BytesLib {
    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes.slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    )
        internal
        pure
        returns (bytes memory)
    {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                // the next line is the loop condition:
                // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(
        bytes storage _preBytes,
        bytes memory _postBytes
    )
        internal
        view
        returns (bool)
    {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint256(mc < end) + cb == 2)
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}

// File: contracts/tokens/proxy/TokenProxy.sol

pragma solidity ^0.8.0;










/**
* @title Token Proxy base Contract
* @notice This should be inherited by the token proxy
* @dev A generic proxy contract to be used by any token standard. The final token proxy
* contract should also inherit from a TokenERC1820Provider contract or implement those functions.
* This contract handles roles, domain, logic contract tracking (through ERC1820 + EIP1967),
* upgrading, and has several internal functions to delegatecall to the logic contract.
*
* This contract also has a fallback function to forward any un-routed calls to the current logic
* contract
*
* The domain version of the TokenProxy will be the current address of the logic contract. The domain
* name must be implemented by the final token proxy.
*/
abstract contract TokenProxy is TokenERC1820Provider, TokenRoles, DomainAware, ITokenProxy {
    using BytesLib for bytes;

    bytes32 private constant UPGRADING_FLAG_SLOT = keccak256("token.proxy.upgrading");

    /**
    * @dev This event is invoked when the logic contract is upgraded to a new contract
    * address.
    * @param logic The new logic contract address
    * @notice Used by the EIP1967 standard
    */
    event Upgraded(address indexed logic);

    /**
    * @dev Sets up the proxy by initalizing the owner + manager roles, as well as
    * setting the logic contract. This will also register the token interface
    * with the ERC1820 registry.
    * @param logicAddress The address to use for the logic contract. Must be non-zero
    * @param owner The address to use as the owner + manager.
    */
    constructor(address logicAddress, address owner) {
        if (owner != address(0) && owner != _msgSender()) {
            transferOwnership(owner);
            StorageSlot.getAddressSlot(TOKEN_MANAGER_ADDRESS).value = owner;
        } else {
            StorageSlot.getAddressSlot(TOKEN_MANAGER_ADDRESS).value = _msgSender();
        }

        ERC1820Client.setInterfaceImplementation(__tokenInterfaceName(), address(this));
        ERC1820Implementer._setInterface(__tokenInterfaceName()); // For migration

        require(logicAddress != address(0), "Logic address must be given");
        require(logicAddress == ERC1820Client.interfaceAddr(logicAddress, __tokenLogicInterfaceName()), "Not registered as a logic contract");

        _setLogic(logicAddress);

        //setup initalize call
        bytes memory data = abi.encode(logicAddress, owner);
        StorageSlot.getUint256Slot(UPGRADING_FLAG_SLOT).value = data.length;

        //invoke the initialize function during deployment
        (bool success,) = _delegatecall(
            abi.encodeWithSelector(ITokenLogic.initialize.selector, data)
        );

        //Check initialize
        require(success, "Logic initializing failed");
    
        StorageSlot.getUint256Slot(UPGRADING_FLAG_SLOT).value = 0;

        emit Upgraded(logicAddress);
    }

    /**
    * @dev Get the current address for the logic contract. This is read from the ERC1820 registry
    * @return address The address of the current logic contract
    */
    function _getLogicContractAddress() private view returns (address) {
        return ERC1820Client.interfaceAddr(address(this), __tokenLogicInterfaceName());
    }

    /**
    * @dev Saves the logic contract address to use for the proxy in the ERC1820 registry and 
    * in the EIP1967 storage slot
    * @notice This should not be called directly. If you wish to change the logic contract,
    * use upgradeTo. This function side-steps some side-effects such as emitting the Upgraded
    * event
    */
    function _setLogic(address logic) internal {
        bytes32 EIP1967_LOCATION = bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1);

        //Update registry
        ERC1820Client.setInterfaceImplementation(__tokenLogicInterfaceName(), logic);
        
        //Update EIP1967 Storage Slot
        StorageSlot.getAddressSlot(EIP1967_LOCATION).value = logic;
    }
    
    /**
    * @dev Upgrade the TokenProxy logic contract. Can only be executed by the current manager address
    * @notice Perform an upgrade on the proxy and replace the current logic
    * contract with a new one. You must provide the new address of the
    * logic contract and (optionally) some arbitrary data to pass to
    * the logic contract's initialize function.
    * @param logic The address of the new logic contract
    * @param data Any arbitrary data, will be passed to the new logic contract's initialize function
    */
    function upgradeTo(address logic, bytes memory data) external override onlyManager {
        StorageSlot.getUint256Slot(UPGRADING_FLAG_SLOT).value = data.length;

        _setLogic(logic);

        //invoke the initialize function whenever we upgrade
        (bool success,) = _delegatecall(
            abi.encodeWithSelector(ITokenLogic.initialize.selector, data)
        );

        //Invoke initialize
        require(success, "Logic initializing failed");

        StorageSlot.getUint256Slot(UPGRADING_FLAG_SLOT).value = 0;

        emit Upgraded(logic);
    }

    /**
    * @dev Forward the current call to the logic contract. This will
    * use delegatecall to forward the current call to the current logic
    * contract. This function returns & exits the current call
    */
    function _delegateCurrentCall() internal {
        _delegatecallAndReturn(_msgData());
    }

    /**
    * @dev Forward the current staticcall to the logic contract. This
    * function works in both a read (STATICCALL) and write (CALL) call context.
    * The return data from the staticcall is returned as arbitrary data. It is
    * up to the invoker to decode the data (hint: Use BytesLib)
    * @return results The return data from the result of the STATICCALL to the logic contract.
    */
    function _staticDelegateCurrentCall() internal view returns (bytes memory results) {
        (, results) = _staticDelegateCall(_msgData());
    }

    /**
    * @dev A function modifier that will always forward the function
    * definiation to the current logic contract. The body of the function
    * is never invoked, so it can remain blank.
    *
    * Any data returned by the logic contract is returned to the current caller
    */
    modifier delegated {
        _delegateCurrentCall();
        _;
    }

    /**
    * @dev A function modifier that will always forward the view function
    * definiation to the current logic contract. The body of the view function
    * is never invoked, so it can remain blank.
    *
    * Any data returned by the logic contract is returned to the current caller
    */
    modifier staticdelegated {
        _staticDelegateCallAndReturn(_msgData());
        _;
    }

    /**
    * @dev Make a delegatecall to the current logic contract and return any returndata. If
    * the call fails/reverts then this call reverts. 
    * @param _calldata The calldata to use in the delegatecall
    * @return success Whethter the delegatecall was successful
    * @return result Any returndata resulting from the delegatecall
    */
    function _delegatecall(bytes memory _calldata) internal returns (bool success, bytes memory result) {
        address logic = _getLogicContractAddress();

        // Forward the external call using call and return any value
        // and reverting if the call failed
        (success, result) = logic.delegatecall{gas: gasleft()}(_calldata);

        if (!success) {
            revert(string(result));
        }
    }

    /**
    * @dev Make a delegatecall to the current logic contract, returning any returndata to the
    * current caller.
    * @param _calldata The calldata to use in the delegatecall
    */
    function _delegatecallAndReturn(bytes memory _calldata) internal {
        address logic = _getLogicContractAddress();

        // Forward the external call using call and return any value
        // and reverting if the call failed
        assembly {
            // execute function call
            let result := delegatecall(gas(), logic, add(_calldata, 0x20), mload(_calldata), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
        }
    }


    /**
    * @dev Used by _staticcall and _staticcallAndReturn
    */
    bytes4 private constant STATICCALLMAGIC = hex"ffffffff";


    /**
    * @dev Make a static call (read-only call) to the logic contract and return this call. This
    * effectively uses the logic contract code to read from our storage.
    * This is done by using by doing a delayed delegatecall inside our fallback function
    * We'll do this by invoking a STATICCALL on ourselves with the following data
    * <STATICCALLMAGIC> + _calldata
    * In our fallback function (because we dont have a function declared with the 
    * STATICCALLMAGIC selector), the STATICCALLMAGIC is trimmed and the rest of
    * the provided _calldata is passed to DELEGATECALL
    *
    * This function ends the current call and returns the data returned by STATICCALL. To
    * just return the data returned by STATICCALL without ending the current call, use _staticcall
    * @param _calldata The calldata to send with the STATICCALL
    */
    function _staticDelegateCallAndReturn(bytes memory _calldata) internal view {
        bytes memory finalData = abi.encodePacked(STATICCALLMAGIC, _calldata);
        address self = address(this);

        // Forward the external call using call and return any value
        // and reverting if the call failed
        assembly {
            // execute function call
            let result := staticcall(gas(), self, add(finalData, 0x20), mload(_calldata), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
        }
    }

    /**
    * @dev Make a static call (read-only call) to the logic contract. This
    * effectively uses the logic contract code to read from our storage.
    * This is done by using by doing a delayed delegatecall inside our fallback function
    * We'll do this by invoking a STATICCALL on ourselves with the following data
    * <STATICCALLMAGIC> + _calldata
    * In our fallback function (because we dont have a function declared with the 
    * STATICCALLMAGIC selector), the STATICCALLMAGIC is trimmed and the rest of
    * the provided _calldata is passed to DELEGATECALL
    * @param _calldata The calldata to send with the STATICCALL
    * @return success Whether the STATICCALL was successful. If the call was not successful then
    * a revert is thrown with the data returned by the STATICCALL
    * @return result The result of the STATICCALL
    */
    function _staticDelegateCall(bytes memory _calldata) internal view returns (bool success, bytes memory result) {
        bytes memory finalData = abi.encodePacked(STATICCALLMAGIC, _calldata);

        // Forward the external call using call and return any value
        // and reverting if the call failed
        (success, result) = address(this).staticcall{gas: gasleft()}(finalData);

        if (!success) {
            revert(string(result));
        }
    }

    /**
    * @dev The default fallback function the TokenProxy will use. Child contracts
    * must override this function to add additional functionality to the fallback function of
    * the proxy.
    */
    function _fallback() internal virtual {
        if (msg.sig == STATICCALLMAGIC) {
            require(msg.sender == address(this), "STATICCALLMAGIC can only be used by the Proxy");

            bytes memory _calldata = msg.data.slice(4, msg.data.length - 4);
            _delegatecallAndReturn(_calldata);
        } else {
            _delegateCurrentCall();
        }
    }

    /**
    * @notice Forward any function not found in the TokenProxy contract (or any child contracts)
    * to the current logic contract.
    */
    fallback() external override payable {
        _fallback();
    }
    
    /**
    * @dev Child contracts may override this function
    * @notice Receive ether
    */
    receive() external override virtual payable {}

    /**
    * @notice The current domain version of the TokenProxy is the address of
    * the current logic contract.
    * @inheritdoc DomainAware
    */
    function _domainVersion() internal virtual override view returns (bytes32) {
        return bytes32(uint256(uint160(_getLogicContractAddress())));
    }
}

// File: contracts/tokens/extension/IExtendable.sol

pragma solidity ^0.8.0;

/**
* @title IExtendable
* @notice Interface for token proxy that offers extensions
*/
interface IExtendable {
    /**
    * @dev Register the extension at the given global extension address. This will deploy a new
    * ExtensionProxy contract to act as a proxy. The extension's proxy will
    * be initalized and all functions the extension has will be registered
    *
    * @param extension The deployed extension address to register
    */
    function registerExtension(address extension) external;

    /**
    * @dev Upgrade a registered extension at the given global extension address. This will perform
    * an upgrade on the ExtensionProxy contract that was deployed during registration. The new global
    * extension address must have the same deployer and package hash.
    * @param extension The global extension address to upgrade
    * @param newExtension The new global extension address to upgrade the extension to
    */
    function upgradeExtension(address extension, address newExtension) external;

    /**
    * @dev Remove the extension at the provided address. This may either be the
    * global extension address or the deployed extension proxy address. 
    *
    * Removing an extension deletes all data about the deployed extension proxy address
    * and makes the extension's storage inaccessable forever.
    *
    * @param extension Either the global extension address or the deployed extension proxy address to remove
    */
    function removeExtension(address extension) external;

    /**
    * @dev Disable the extension at the provided address. This may either be the
    * global extension address or the deployed extension proxy address. 
    *
    * Disabling the extension keeps the extension + storage live but simply disables
    * all registered functions and transfer events
    *
    * @param extension Either the global extension address or the deployed extension proxy address to disable
    */
    function disableExtension(address extension) external;

    /**
    * @dev Enable the extension at the provided address. This may either be the
    * global extension address or the deployed extension proxy address. 
    *
    * Enabling the extension simply enables all registered functions and transfer events
    *
    * @param extension Either the global extension address or the deployed extension proxy address to enable
    */
    function enableExtension(address extension) external;

    /**
    * @dev Get an array of all deployed extension proxy addresses, regardless of if they are
    * enabled or disabled
    */
    function allExtensionsRegistered() external view returns (address[] memory);

    /**
    * @dev Get an array of all deployed extension proxy addresses, regardless of if they are
    * enabled or disabled
    */
    function allExtensionProxies() external view returns (address[] memory);

    /**
    * @dev Get the deployed extension proxy address given a global extension address. 
    * This function assumes the given global extension address has been registered using
    *  _registerExtension.
    * @param extension The global extension address to convert
    */
    function proxyAddressForExtension(address extension) external view returns (address);
}

// File: contracts/tokens/proxy/IExtendableTokenProxy.sol

pragma solidity ^0.8.0;


interface IExtendableTokenProxy is ITokenProxy, IExtendable {
}

// File: contracts/interface/IExtensionMetadata.sol

pragma solidity ^0.8.0;

/**
* @title Extension Metadata Interface
* @dev An interface that extensions must implement that provides additional
* metadata about the extension. 
*/
interface IExtensionMetadata {
    /**
    * @notice An array of function signatures this extension adds when
    * registered when a TokenProxy
    * @dev This function is used by the TokenProxy to determine what
    * function selectors to add to the TokenProxy
    */
    function externalFunctions() external view returns (bytes4[] memory);
    
    /**
    * @notice An array of role IDs that this extension requires from the Token
    * in order to function properly
    * @dev This function is used by the TokenProxy to determine what
    * roles to grant to the extension after registration and what roles to remove
    * when removing the extension
    */
    function requiredRoles() external view returns (bytes32[] memory);

    /**
    * @notice Whether a given Token standard is supported by this Extension
    * @param standard The standard to check support for
    */
    function isTokenStandardSupported(TokenStandard standard) external view returns (bool);

    /**
    * @notice The address that deployed this extension.
    */
    function extensionDeployer() external view returns (address);

    /**
    * @notice The hash of the package string this extension was deployed with
    */
    function packageHash() external view returns (bytes32);

    /**
    * @notice The version of this extension, represented as a number
    */
    function version() external view returns (uint256);
}

// File: contracts/interface/IExtension.sol

pragma solidity ^0.8.0;


/**
* @title Extension Interface
* @dev An interface to be implemented by Extensions
*/
interface IExtension is IExtensionMetadata {
    /**
    * @notice This function cannot be invoked directly
    * @dev This function is invoked when the Extension is registered
    * with a TokenProxy 
    */
    function initialize() external;

    /**
    * @notice This function cannot be invoked directly
    * @dev This function is invoked right after a transfer occurs on the
    * Token.
    * @param data The information about the transfer that just occured as a TransferData struct
    */
    function onTransferExecuted(TransferData memory data) external returns (bool);
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol

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

// File: contracts/extensions/ExtensionBase.sol

pragma solidity ^0.8.0;


/**
* @title Extension Base Contract
* @notice This shouldn't be used directly, it should be extended by child contracts
* @dev This contract setups the base of every Extension contract (including proxies). It
* defines a set data structure for holding important information about the current Extension
* registration instance. This includes the current Token address, the current Extension
* global address and an "authorized caller" (callsite).
*
* The ExtensionBase also defines a _msgSender() function, this function should be used
* instead of the msg.sender variable. _msgSender() has a different behavior depending
* on who the msg.sender variable is, this is to allow both meta-transactions and 
* proxy forwarding
*
* The "callsite" should be considered an admin-style address. See
* ExtensionProxy for more information
*
* The ExtensionBase also provides several function modifiers to restrict function
* invokation
*/
abstract contract ExtensionBase is ContextUpgradeable {
    bytes32 constant PROXY_DATA_SLOT = keccak256("ext.proxy.data");
    bytes32 constant MSG_SENDER_SLOT = keccak256("ext.proxy.data.msgsender");

    /**
    * @dev Considered the storage to be shared between the proxy
    * and extension logic contract.
    * We share this information with the logic contract because it may
    * be useful for the logic contract to query this information
    * @param token The token address that registered this extension instance
    * @param extension The extension logic contract to use
    * @param callsite The "admin" of this registered extension instance
    * @param initialized Whether this instance is initialized
    */
    struct ProxyData {
        address token;
        address extension;
        address callsite;
        bool initialized;
    }

    /**
    * @dev The ProxyData struct stored in this registered Extension instance.
    */
    function _proxyData() internal pure returns (ProxyData storage ds) {
        bytes32 position = PROXY_DATA_SLOT;
        assembly {
            ds.slot := position
        }
    }

    /**
    * @dev The current Extension logic contract address
    */
    function _extensionAddress() internal view returns (address) {
        ProxyData storage ds = _proxyData();
        return ds.extension;
    }

    /**
    * @dev The current token address that registered this extension instance
    */
    function _tokenAddress() internal view returns (address payable) {
        ProxyData storage ds = _proxyData();
        return payable(ds.token);
    }

    /**
    * @dev The current admin address for this registered extension instance
    */
    function _authorizedCaller() internal view returns (address) {
        ProxyData storage ds = _proxyData();
        return ds.callsite;
    }

    /**
    * @dev A function modifier to only allow the registered token to execute this function
    */
    modifier onlyToken {
        require(msg.sender == _tokenAddress(), "Token: Unauthorized");
        _;
    }

    /**
    * @dev A function modifier to only allow the admin to execute this function
    */
    modifier onlyAuthorizedCaller {
        require(msg.sender == _authorizedCaller(), "Caller: Unauthorized");
        _;
    }

    /**
    * @dev A function modifier to only allow the admin or ourselves to execute this function
    */
    modifier onlyAuthorizedCallerOrSelf {
        require(msg.sender == _authorizedCaller() || msg.sender == address(this), "Caller: Unauthorized");
        _;
    }

    /**
    * @dev Get the current msg.sender for the current CALL context
    */
    function _msgSender() internal virtual override view returns (address ret) {
        if (msg.data.length >= 24 && msg.sender == _authorizedCaller()) {
            // At this point we know that the sender is a token proxy,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            return super._msgSender();
        }
    }

    receive() external payable {}
}

// File: contracts/extensions/ExtensionProxy.sol

pragma solidity ^0.8.0;





/**
* @title Extension Proxy
* @notice This contract can be interacted directly in a normal manner if the
* caller is
*   * An EOA
*   * Not the registered token address
*   * Not the registered admin
*
* If the caller is the registered token address or registered admin, then
* each function call should be preceeded by a call to prepareCall. 
*/
contract ExtensionProxy is IExtensionMetadata, ExtensionBase {
    event ExtensionUpgraded(address indexed extension, address indexed newExtension);

    constructor(address token, address extension, address callsite) {
        //Setup proxy data
        ProxyData storage ds = _proxyData();

        ds.token = token;
        ds.extension = extension;
        ds.callsite = callsite;
        
        //Ensure we support this token standard
        TokenStandard standard = IToken(token).tokenStandard();

        require(isTokenStandardSupported(standard), "Extension does not support token standard");
        
        //Update EIP1967 Storage Slot
        bytes32 EIP1967_LOCATION = bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1);
        StorageSlot.getAddressSlot(EIP1967_LOCATION).value = extension;
    }

    function _extension() internal view returns (IExtension) {
        ProxyData storage ds = _proxyData();
        return IExtension(ds.extension);
    }

    function upgradeTo(address extensionImplementation) external onlyAuthorizedCaller {
        IExtension ext = IExtension(extensionImplementation);

        address currentDeployer = extensionDeployer();
        address newDeployer = ext.extensionDeployer();

        require(currentDeployer == newDeployer, "Deployer address for new extension is different than current");

        bytes32 currentPackageHash = packageHash();
        bytes32 newPackageHash = ext.packageHash();

        require(currentPackageHash == newPackageHash, "Package for new extension is different than current");

        uint256 currentVersion = version();
        uint256 newVersion = ext.version();

        require(currentVersion != newVersion, "Versions should not match");

        //TODO Check interfaces?

        //Ensure we support this token standard
        ProxyData storage ds = _proxyData();
        TokenStandard standard = IToken(ds.token).tokenStandard();

        require(ext.isTokenStandardSupported(standard), "Token standard is not supported in new extension");

        address old = ds.extension;
        ds.extension = extensionImplementation;

        //Update EIP1967 Storage Slot
        bytes32 EIP1967_LOCATION = bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1);
        StorageSlot.getAddressSlot(EIP1967_LOCATION).value = extensionImplementation;

        emit ExtensionUpgraded(old, extensionImplementation);
    }

    fallback() external payable {
        if (msg.sender != _authorizedCaller()) {
            //This specific function is restricted when using the proxy directly
            //Only the "admin" can invoke this, everyone else (include ourselves) 
            //shouldn't invoke this
            require(msg.sig != IExtension.onTransferExecuted.selector, "Cannot directly invoke transferExecuted");
        }
        
        ProxyData storage ds = _proxyData();
        
        _delegate(ds.extension);
    }

    function initialize() external onlyAuthorizedCaller {
        ProxyData storage ds = _proxyData();

        ds.initialized = true;

        //now forward initalization to the extension
        _delegate(ds.extension);
    }

    /**
    * @dev Delegates execution to an implementation contract.
    * This is a low level function that doesn't return to its internal call site.
    * It will return to the external caller whatever the implementation returns.
    * @param implementation Address to delegate.
    */
    function _delegate(address implementation) internal {
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
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    function externalFunctions() external override view returns (bytes4[] memory) {
        return _extension().externalFunctions();
    }

    function requiredRoles() external override view returns (bytes32[] memory) {
        return _extension().requiredRoles();
    }

    function isTokenStandardSupported(TokenStandard standard) public override view returns (bool) {
        return _extension().isTokenStandardSupported(standard);
    }

    function extensionDeployer() public view override returns (address) {
        return _extension().extensionDeployer();
    }

    function packageHash() public view override returns (bytes32) {
        return _extension().packageHash();
    }

    function version() public view override returns (uint256) {
        return _extension().version();
    }
}

// File: contracts/tokens/extension/ExtendableBase.sol

pragma solidity ^0.8.0;




/**
* @title Base Contract for Extendable contracts
* @notice This is an abstract contract that should only be used by other
* contracts in this folder
* @dev This is the base contract that will be extended by all 
* Extendable contracts. Provides _msgSender() functions through
* the ContextUpgradeable contract
*/
abstract contract ExtendableBase is ContextUpgradeable {
    /**
    * @dev The storage slot that will hold the MappedExtensions struct
    */
    bytes32 constant MAPPED_EXTENSION_STORAGE_SLOT = keccak256("erc20.core.storage.address");

    /**
    * @dev A state of all possible registered extension states
    * A registered extension can either not exist, be enabled or disabled
    */
    enum ExtensionState {
        EXTENSION_NOT_EXISTS,
        EXTENSION_ENABLED,
        EXTENSION_DISABLED
    }

    /**
    * @dev Registered extension data
    * @param state The current state of this registered extension
    * @param index The current index of this registered extension in registeredExtensions array
    * @param extProxy The current extProxy address this extension should be executed in
    */
    struct ExtensionData {
        ExtensionState state;
        uint256 index;
        address extProxy;
        bytes4[] externalFunctions;
    }

    /**
    * @dev All Registered extensions + additional mappings for easy lookup
    * @param registeredExtensions An array of all registered extensions, both enabled and disabled extensions
    * @param funcToExtension A mapping of function selector to global extension address
    * @param extensions A mapping of global extension address to ExtensionData
    * @param proxyCache A mapping of deployed extension proxy addresses to global extension addresses
    */
    struct MappedExtensions {
        address[] registeredExtensions;
        mapping(bytes4 => address) funcToExtension;
        mapping(address => ExtensionData) extensions;
        mapping(address => address) proxyCache;
    }

    /**
    * @dev Get the MappedExtensions data stored inside this contract.
    * @return ds The MappedExtensions struct stored in this contract
    */
    function extensionStorage() private pure returns (MappedExtensions storage ds) {
        bytes32 position = MAPPED_EXTENSION_STORAGE_SLOT;
        assembly {
            ds.slot := position
        }
    }

    /**
    * @dev Obtain data about an extension address in the form of the ExtensionData struct. The
    * address provided can be either the global extension address or the deployed extension proxy address
    * @param ext The extension address to lookup, either the global extension address or the deployed extension proxy address
    * @return ExtensionData Data about the extension in the form of the ExtensionData struct
    */
    function _addressToExtensionData(address ext) internal view returns (ExtensionData memory) {
        MappedExtensions storage extLibStorage = extensionStorage();
        address extension = __forceGlobalExtensionAddress(ext);
        return extLibStorage.extensions[extension];
    }

    /**
    * @dev Determine if the given extension address is active (registered & enabled). The provided
    * extension address can either be the global extension address or the extension proxy address.
    * @return bool True if the provided extension address is registered & enabled, otherwise false.
    */
    function _isActiveExtension(address ext) internal view returns (bool) {
        MappedExtensions storage extLibStorage = extensionStorage();
        address extension = __forceGlobalExtensionAddress(ext);
        return extLibStorage.extensions[extension].state == ExtensionState.EXTENSION_ENABLED;
    }

    /**
    * @dev Register an extension at the given global extension address. This will
    * deploy a new ExtensionProxy contract to act as the extension proxy and register
    * all function selectors the extension exposes.
    * This will also invoke the initialize function on the extension proxy, to do this 
    * we must know who the current caller is.
    * Registering an extension automatically enables it for use.
    *
    * @param extension The global extension address to register
    * @param token The token address that will be using this extension
    * @param caller The current caller that will be initalizing the extension proxy
    */
    function _registerExtension(address extension, address token, address caller) internal returns (bool) {
        MappedExtensions storage extLibStorage = extensionStorage();
        require(extLibStorage.extensions[extension].state == ExtensionState.EXTENSION_NOT_EXISTS, "The extension must not already exist");

        //TODO Register with 1820
        //Interfaces has been validated, lets begin setup

        //Next we need to deploy the ExtensionProxy contract
        //To sandbox our extension's storage
        ExtensionProxy extProxy = new ExtensionProxy(token, extension, address(this));

        //Next lets figure out what external functions to register in the Extension
        bytes4[] memory externalFunctions = extProxy.externalFunctions();

        //If we have external functions to register, then lets register them
        if (externalFunctions.length > 0) {
            for (uint i = 0; i < externalFunctions.length; i++) {
                bytes4 func = externalFunctions[i];
                require(extLibStorage.funcToExtension[func] == address(0), "Function signature conflict");
                //STATICCALLMAGIC not allowed
                require(func != hex"ffffffff", "Invalid function signature");

                extLibStorage.funcToExtension[func] = extension;
            }
        }

        //Initialize the new extension proxy
        bytes memory initializeCalldata = abi.encodePacked(abi.encodeWithSelector(ExtensionProxy.initialize.selector), _msgSender());

        (bool success, bytes memory result) = address(extProxy).call{gas: gasleft()}(initializeCalldata);

        if (!success) {
            revert(string(result));
        }

        //Finally, add it to storage
        extLibStorage.extensions[extension] = ExtensionData(
            ExtensionState.EXTENSION_ENABLED,
            extLibStorage.registeredExtensions.length,
            address(extProxy),
            externalFunctions
        );

        extLibStorage.registeredExtensions.push(extension);
        extLibStorage.proxyCache[address(extProxy)] = extension;

        return true;
    }

    /**
    * @dev Get the deployed extension proxy address that registered the provided
    * function selector. If no extension registered the given function selector,
    * then return address(0). If the extension that registered the function selector is disabled,
    * then the address(0) is returned
    * @param funcSig The function signature to lookup
    * @return address Returns the deployed enabled extension proxy address that registered the
    * provided function selector, otherwise address(0)
    */
    function _functionToExtensionProxyAddress(bytes4 funcSig) internal view returns (address) {
        MappedExtensions storage extLibStorage = extensionStorage();

        ExtensionData storage extData = extLibStorage.extensions[extLibStorage.funcToExtension[funcSig]];

        //Only return an address for an extension that is enabled
        if (extData.state == ExtensionState.EXTENSION_ENABLED) {
            return extData.extProxy;
        }

        return address(0);
    }

    /**
    * @dev Get the full ExtensionData of the extension that registered the provided
    * function selector, even if the extension is currently disabled. 
    * If no extension registered the given function selector, then a blank ExtensionData is returned.
    * @param funcSig The function signature to lookup
    * @return ExtensionData Returns the full ExtensionData of the extension that registered the
    * provided function selector
    */
    function _functionToExtensionData(bytes4 funcSig) internal view returns (ExtensionData storage) {
        MappedExtensions storage extLibStorage = extensionStorage();

        require(extLibStorage.funcToExtension[funcSig] != address(0), "Unknown function");

        return extLibStorage.extensions[extLibStorage.funcToExtension[funcSig]];
    }

    /**
    * @dev Disable the extension at the provided address. This may either be the
    * global extension address or the deployed extension proxy address. 
    *
    * Disabling the extension keeps the extension + storage live but simply disables
    * all registered functions and transfer events
    *
    * @param ext Either the global extension address or the deployed extension proxy address to disable
    */
    function _disableExtension(address ext) internal {
        MappedExtensions storage extLibStorage = extensionStorage();
        address extension = __forceGlobalExtensionAddress(ext);

        ExtensionData storage extData = extLibStorage.extensions[extension];

        require(extData.state == ExtensionState.EXTENSION_ENABLED, "The extension must be enabled");

        extData.state = ExtensionState.EXTENSION_DISABLED;
        extLibStorage.proxyCache[extData.extProxy] = address(0);
    }

    /**
    * @dev Enable the extension at the provided address. This may either be the
    * global extension address or the deployed extension proxy address. 
    *
    * Enabling the extension simply enables all registered functions and transfer events
    *
    * @param ext Either the global extension address or the deployed extension proxy address to enable
    */
    function _enableExtension(address ext) internal {
        MappedExtensions storage extLibStorage = extensionStorage();
        address extension = __forceGlobalExtensionAddress(ext);

        ExtensionData storage extData = extLibStorage.extensions[extension];

        require(extData.state == ExtensionState.EXTENSION_DISABLED, "The extension must be enabled");

        extData.state = ExtensionState.EXTENSION_ENABLED;
        extLibStorage.proxyCache[extData.extProxy] = extension;
    }

    /**
    * @dev Check whether a given address is a deployed extension proxy address that
    * is registered.
    *
    * @param callsite The address to check
    */
    function _isExtensionProxyAddress(address callsite) internal view returns (bool) {
        MappedExtensions storage extLibStorage = extensionStorage();

        return extLibStorage.proxyCache[callsite] != address(0);
    }

    /**
    * @dev Get an array of all global extension addresses that have been registered, regardless of if they are
    * enabled or disabled
    */
    function _allExtensionsRegistered() internal view returns (address[] storage) {
        MappedExtensions storage extLibStorage = extensionStorage();
        return extLibStorage.registeredExtensions;
    }

    /**
    * @dev Get an array of all deployed extension proxy addresses, regardless of if they are
    * enabled or disabled
    */
    function _allExtensionProxies() internal view returns (address[] memory) {
        MappedExtensions storage extLibStorage = extensionStorage();
        address[] storage globalAddresses = extLibStorage.registeredExtensions;
        address[] memory proxyAddresses = new address[](globalAddresses.length);

        for (uint i = 0; i < proxyAddresses.length; i++) {
            proxyAddresses[i] = _proxyAddressForExtension(globalAddresses[i]);
        }

        return proxyAddresses;
    }

    /**
    * @dev Get the deployed extension proxy address given a global extension address. 
    * This function assumes the given global extension address has been registered using
    *  _registerExtension.
    * @param extension The global extension address to convert
    */
    function _proxyAddressForExtension(address extension) internal view returns (address) {
        MappedExtensions storage extLibStorage = extensionStorage();
        ExtensionData storage extData = extLibStorage.extensions[extension];

        require(extData.state != ExtensionState.EXTENSION_NOT_EXISTS, "The extension must exist (either enabled or disabled)");

        return extData.extProxy;
    }

    /**
    * @dev Remove the extension at the provided address. This may either be the
    * global extension address or the deployed extension proxy address. 
    *
    * Removing an extension deletes all data about the deployed extension proxy address
    * and makes the extension's storage inaccessable forever.
    *
    * @param ext Either the global extension address or the deployed extension proxy address to remove
    */
    function _removeExtension(address ext) internal {
        MappedExtensions storage extLibStorage = extensionStorage();
        address extension = __forceGlobalExtensionAddress(ext);

        ExtensionData storage extData = extLibStorage.extensions[extension];

        require(extData.state != ExtensionState.EXTENSION_NOT_EXISTS, "The extension must exist (either enabled or disabled)");

        // To prevent a gap in the extensions array, we store the last extension in the index of the extension to delete, and
        // then delete the last slot (swap and pop).
        uint256 lastExtensionIndex = extLibStorage.registeredExtensions.length - 1;
        uint256 extensionIndex = extData.index;

        // When the extension to delete is the last extension, the swap operation is unnecessary. However, since this occurs so
        // rarely that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement
        address lastExtension = extLibStorage.registeredExtensions[lastExtensionIndex];

        extLibStorage.registeredExtensions[extensionIndex] = lastExtension;
        extLibStorage.extensions[lastExtension].index = extensionIndex;

        extLibStorage.proxyCache[extData.extProxy] = address(0);
        delete extLibStorage.extensions[extension];
        extLibStorage.registeredExtensions.pop();
    }

    /**
    * @dev If the providen address is the deployed extension proxy, then convert it to the
    * global extension address. Otherwise, return what was given 
    */
    function __forceGlobalExtensionAddress(address extension) private view returns (address) {
        MappedExtensions storage extLibStorage = extensionStorage();
        if (extLibStorage.proxyCache[extension] != address(0)) {
            return extLibStorage.proxyCache[extension];
        }

        return extension; //nothing to do
    }

    /**
    * @dev Go through each extension, if it's enabled execute the implemented function and pass the extension
    * If any invokation of the implemented function given an extension returns false, halt and return false
    * If they all return true (or there are no extensions), then return true
    * @param toInvoke The function that should be invoked with each enabled extension
    * @param data The current data that will be passed to the implemented function along with the enabled extension address
    * @return bool True if all extensions were executed successfully, false if any extension returned false
    */
    function _executeOnAllExtensions(function (address, TransferData memory) internal returns (bool) toInvoke, TransferData memory data) internal returns (bool) {
        MappedExtensions storage extLibData = extensionStorage();

        for (uint i = 0; i < extLibData.registeredExtensions.length; i++) {
            address extension = extLibData.registeredExtensions[i];

            ExtensionData memory extData = extLibData.extensions[extension]; 

            if (extData.state == ExtensionState.EXTENSION_DISABLED) {
                continue; //Skip if the extension is disabled
            }

            //Execute the implemented function using the enabled extension
            //however, execute the call at the ExtensionProxy contract address
            //The ExtensionProxy contract will delegatecall the extension logic
            //and manage storage/api
            address proxy = extData.extProxy;
            bool result = toInvoke(proxy, data);
            if (!result) {
                return false;
            }
        }

        return true;
    }
}

// File: contracts/tokens/extension/ExtendableProxy.sol

pragma solidity ^0.8.0;


/**
* @title Router contract for Extensions
* @notice This should be inherited by token proxy contracts
* @dev ExtendableProxy provides internal functions to manage
* extensions, view extension data and invoke extension functions 
* (if the current call is an extension function)
*/
contract ExtendableProxy is ExtendableBase {

    /**
    * @dev Call a registered function selector. This will 
    * lookup the deployed extension proxy that registered the provided
    * function selector and call it. The current call data is forwarded.
    *
    * This call returns and exits the current call context.
    *
    * If the provided function selector is not registered by any enabled 
    * extensions, then the revert is thrown
    *
    * @param funcSig The registered function selector to call.
    */
    function _callFunction(bytes4 funcSig) private {
        // get extension proxy address from function selector
        address toCall = _functionToExtensionProxyAddress(funcSig);
        require(toCall != address(0), "EXTROUTER: Function does not exist");

        bytes memory finalData = abi.encodePacked(_msgData(), _msgSender());

        uint256 value = msg.value;

        // Execute external function from facet using call and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := call(gas(), toCall, value, add(finalData, 0x20), mload(finalData), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
        }
    }

    /**
    * @dev Determine if a given function selector is registered by an enabled
    * deployed extension proxy address. If no extension proxy exists or if the 
    * deployed extension proxy address is disabled, then false is returned
    *
    * @param funcSig The function selector to check
    * @return bool True if an enabled deployed extension proxy address has registered
    * the provided function selector, otherwise false.
    */
    function _isExtensionFunction(bytes4 funcSig) internal virtual view returns (bool) {
        return _functionToExtensionProxyAddress(funcSig) != address(0);
    }

    /**
    * @dev Forward the current call to the proper deployed extension proxy address. This
    * function assumes the current function selector is registered by an enabled deployed extension proxy address.
    *
    * This call returns and exits the current call context.
    */
    function _invokeExtensionFunction() internal virtual {
        require(_isExtensionFunction(msg.sig), "No extension found with function signature");

        _callFunction(msg.sig);
    }
}

// File: contracts/interface/IDiamondLoupe.sol

pragma solidity ^0.8.0;

/**
* @title Diamond Loupe Interface
* @notice These functions look at diamonds
* @dev A loupe is a small magnifying glass used to look at diamonds.
* These functions are expected to be called frequently by tools.
*/
interface IDiamondLoupe {

    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return facets_ Facet
    function facets() external view returns (Facet[] memory facets_);

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external view returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_);
}

// File: contracts/tokens/proxy/ExtendableTokenProxy.sol

pragma solidity ^0.8.0;







/**
* @title Extendable Token Proxy base Contract
* @notice This should be inherited by the token proxy that wishes to use extensions
* @dev An extendable proxy contract to be used by any token standard. The final token proxy
* contract should also inherit from a TokenERC1820Provider contract or implement those functions.
* This contract does everything the TokenProxy does and adds extensions support to the proxy contract.
* This is done by extending from ExtendableProxy and providing external functions that can be used
* by the token proxy manager to manage extensions.
*
* This contract overrides the fallback function to forward any registered function selectors
* to the extension that registered them.
*
* The domain name must be implemented by the final token proxy.
*/
abstract contract ExtendableTokenProxy is TokenProxy, ExtendableProxy, IExtendableTokenProxy, IDiamondLoupe {
    string constant internal EXTENDABLE_INTERFACE_NAME = "ExtendableToken";

    /**
    * @dev A function modifier that will only allow registered & enabled extensions to invoke the function
    */
    modifier onlyExtensions {
        address extension = _msgSender();
        require(_isActiveExtension(extension), "Only extensions can call");
        _;
    }

    /**
    * @dev Invoke TokenProxy constructor and register ourselves as an ExtendableToken
    * in the ERC1820 registry.
    * @param logicAddress The address to use for the logic contract. Must be non-zero
    * @param owner The address to use as the owner + manager.
    */
    constructor(address logicAddress, address owner) TokenProxy(logicAddress, owner) {
        ERC1820Client.setInterfaceImplementation(EXTENDABLE_INTERFACE_NAME, address(this));
    }

    /**
    * @notice Return an array of all global extension addresses, regardless of if they are
    * enabled or disabled. You cannot interact with these addresses. For user interaction
    * you should use ExtendableTokenProxy.allExtensionProxies
    * @return address[] All registered and deployed extension proxy addresses
    */
    function allExtensionsRegistered() external override view returns (address[] memory) {
        return _allExtensionsRegistered();
    }

    /**
    * @notice Return an array of all deployed extension proxy addresses, regardless of if they are
    * enabled or disabled. You can use these addresses for direct interaction. Remember you can also
    * interact with extensions through the TokenProxy.
    * @return address[] All registered and deployed extension proxy addresses
    */
    function allExtensionProxies() external override view returns (address[] memory) {
        return _allExtensionProxies();
    }

    /**
    * @notice Return the deployed extension proxy address given a global extension address.
    * This function reverts if the given global extension has not been registered using
    * registerExtension
    * @return address The deployed extension proxy address
    */
    function proxyAddressForExtension(address extension) external override view returns (address) {
        return _proxyAddressForExtension(extension);
    }

    /**
    * @notice Register an extension providing the given global extension address. This will
    * deploy a new ExtensionProxy contract to act as the extension proxy and register
    * all function selectors the extension exposes.
    * This will also invoke the initialize function on the extension proxy. 
    *
    * Registering an extension automatically enables it for use.
    *
    * Registering an extension automatically grants any roles the extension requires to
    * the address of the deployed extension proxy.
    * See: IExtensionMetadata.requiredRoles()
    *
    * @param extension The global extension address to register
    */
    function registerExtension(address extension) external override onlyManager {
        _registerExtension(extension, address(this), _msgSender());

        address proxyAddress = _proxyAddressForExtension(extension);
        ExtensionProxy proxy = ExtensionProxy(payable(proxyAddress));

        bytes32[] memory requiredRoles = proxy.requiredRoles();
        
        //If we have roles we need to register, then lets register them
        if (requiredRoles.length > 0) {
            for (uint i = 0; i < requiredRoles.length; i++) {
                _addRole(proxyAddress, requiredRoles[i]);
            }
        }
    }

    /**
    * @notice Upgrade a registered extension at the given global extension address. This will perform
    * an upgrade on the ExtensionProxy contract that was deployed during registration. The new global
    * extension address must have the same deployer and package hash.
    * @param extension The global extension address to upgrade
    * @param newExtension The new global extension address to upgrade the extension to
    */
    function upgradeExtension(address extension, address newExtension) external override onlyManager {
        address proxyAddress = _proxyAddressForExtension(extension);
        require(proxyAddress != address(0), "Extension is not registered");

        ExtensionProxy proxy = ExtensionProxy(payable(proxyAddress));

        proxy.upgradeTo(newExtension);
    }

    /**
    * @notice Remove the extension at the provided address. This may either be the
    * global extension address or the deployed extension proxy address. 
    *
    * Removing an extension deletes all data about the deployed extension proxy address
    * and makes the extension's storage inaccessable forever. 
    * 
    * @param extension Either the global extension address or the deployed extension proxy address to remove
    */
    function removeExtension(address extension) external override onlyManager {
        _removeExtension(extension);

        address proxyAddress;
        if (_isExtensionProxyAddress(extension)) {
            proxyAddress = extension;
        } else {
            proxyAddress = _proxyAddressForExtension(extension);
        }

        ExtensionProxy proxy = ExtensionProxy(payable(proxyAddress));

        bytes32[] memory requiredRoles = proxy.requiredRoles();
        
        //If we have roles we need to register, then lets register them
        if (requiredRoles.length > 0) {
            for (uint i = 0; i < requiredRoles.length; i++) {
                _removeRole(proxyAddress, requiredRoles[i]);
            }
        }
    }

    /**
    * @notice Disable the extension at the provided address. This may either be the
    * global extension address or the deployed extension proxy address. 
    *
    * Disabling the extension keeps the extension + storage live but simply disables
    * all registered functions and transfer events
    *
    * @param extension Either the global extension address or the deployed extension proxy address to disable
    */
    function disableExtension(address extension) external override onlyManager {
        _disableExtension(extension);
    }

    /**
    * @notice Enable the extension at the provided address. This may either be the
    * global extension address or the deployed extension proxy address. 
    *
    * Enabling the extension simply enables all registered functions and transfer events
    *
    * @param extension Either the global extension address or the deployed extension proxy address to enable
    */
    function enableExtension(address extension) external override onlyManager {
        _enableExtension(extension);
    }

    /**
    * @dev The default fallback function used in TokenProxy. Overriden here to add support
    * for registered extension functions. Registered extension functions are only invoked
    * if they are registered and enabled. Otherwise, the TokenProxy's fallback function is used
    * @inheritdoc TokenProxy
    */
    function _fallback() internal override virtual {
        bool isExt = _isExtensionFunction(msg.sig);

        if (isExt) {
            _invokeExtensionFunction();
        } else {
            super._fallback();
        }
    }

    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return facets_ Facet
    function facets() external override view returns (Facet[] memory facets_) {
        address[] storage extensions = _allExtensionsRegistered();
        facets_ = new Facet[](extensions.length);

        for (uint i = 0; i < facets_.length; i++) {
            facets_[i] = Facet(
                extensions[i],
                facetFunctionSelectors(extensions[i])
            );
        }
    }

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet) public override view returns (bytes4[] memory facetFunctionSelectors_) {
        return _addressToExtensionData(_facet).externalFunctions;
    }

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external override view returns (address[] memory facetAddresses_) {
        return _allExtensionsRegistered();
    }

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external override view returns (address facetAddress_) {
        return _functionToExtensionProxyAddress(_functionSelector);
    }
}

// File: contracts/tokens/registry/ERC20TokenInterface.sol

pragma solidity ^0.8.0;

/**
* @title ERC1820 Provider for ERC20
* @notice This should be inherited by the token proxy & token logic contracts
* @dev A base contract that inherits from TokenERC1820Provider and implements
* the interface name functions for ERC20
*/
abstract contract ERC20TokenInterface is TokenERC1820Provider {
    string constant internal ERC20_INTERFACE_NAME = "ERC20Token";
    string constant internal ERC20_LOGIC_INTERFACE_NAME = "ERC20TokenLogic";

    /**
    * @dev The interface name for the token logic contract to be used in ERC1820.
    * @return string ERC20TokenLogic
    */
    function __tokenLogicInterfaceName() internal pure override returns (string memory) {
        return ERC20_LOGIC_INTERFACE_NAME;
    }

    /**
    * @dev The interface name for the token logic contract to be used in ERC1820.
    * @return string ERC20Token
    */
    function __tokenInterfaceName() internal virtual override pure returns (string memory) {
        return ERC20_INTERFACE_NAME;
    }
}

// File: contracts/tokens/proxy/ERC20/ERC20Proxy.sol

pragma solidity ^0.8.0;







/**
* @title Extendable ERC20 Proxy
* @notice An ERC20 proxy contract that implements the IERC20 interface. This contract
* can be deployed as-is, however it is recommended to use the ERC20Extendable contract
* for more deployment options (such as minting an inital supply).
* You must provide a token logic contract address that implements the ERC20TokenLogic interface.
*
* The mint and burn/burnFrom functions can be toggled on/off during deployment. To check if mint/burn/burnFrom
* are enabled, check the ProtectedTokenData.
*
* @dev This proxy contract inherits from ExtendableTokenProxy and ERC20TokenInterface, meaning
* it supports the full ERC20 spec and extensions that support ERC20. All ERC20 functions
* are declared explictely and are always forwarded to the current ERC20 token logic contract.
*
* All transfer events (including minting/burning) trigger a transfer event to all registered
* and enabled extensions. By default, no data (or operatorData) is passed to extensions. The
* functions transferWithData and transferFromWithData allow a caller to pass data to extensions during
* these transfer events
*
* The domain name of this contract is the ERC20 token name()
*/
contract ERC20Proxy is ERC20TokenInterface, ExtendableTokenProxy, IERC20Proxy {
    using BytesLib for bytes;
    
    /**
    * @dev The storage slot that will be used to store the ProtectedTokenData struct inside
    * this TokenProxy
    */
    bytes32 constant ERC20_PROTECTED_TOKEN_DATA_SLOT = bytes32(uint256(keccak256("erc20.token.meta")) - 1);

    /**
    * @notice Protected ERC20 token metadata stored in the proxy storage in a special storage slot.
    * Includes thing such as name, symbol and deployment options.
    * @dev This struct should only be written to inside the constructor and should be treated as readonly.
    * Solidity 0.8.7 does not have anything for marking storage slots as read-only, so we'll just use
    * the honor system for now.
    * @param initialized Whether this proxy is initialized
    * @param name The name of this ERC20 token
    * @param symbol The symbol of this ERC20 token
    * @param maxSupply The max supply of token allowed
    * @param allowMint Whether minting is allowed
    * @param allowBurn Whether burning is allowed
    */
    struct ProtectedTokenData {
        bool initialized;
        string name;
        string symbol;
        uint256 maxSupply;
        bool allowMint;
        bool allowBurn;
    }

    /**
    * @notice Deploy a new ERC20 Token Proxy with a given token logic contract. You must
    * also provide the token's name/symbol, max supply, owner and whether token minting or
    * token buning is allowed
    * @dev The constructor stores the ProtectedTokenData and updates the domain seperator
    * @param name_ The name of the new ERC20 Token
    * @param symbol_ The symbol of the new ERC20 Token
    * @param allowMint Whether the mint function will be enabled on this token
    * @param allowBurn Whether the burn/burnFrom function will be enabled on this token
    * @param owner The owner of this ERC20 Token
    * @param maxSupply_ The max supply of tokens allowed. Must be greater-than 0
    * @param logicAddress The logic contract address to use for this ERC20 proxy
    */
    constructor(
        string memory name_, string memory symbol_, 
        bool allowMint, bool allowBurn, address owner,
        uint256 maxSupply_, address logicAddress
    ) ExtendableTokenProxy(logicAddress, owner) { 
        require(maxSupply_ > 0, "Max supply must be non-zero");

        if (allowMint) {
            _addRole(owner, TOKEN_MINTER_ROLE);
        }

        ProtectedTokenData storage m = _getProtectedTokenData();
        m.name = name_;
        m.symbol = symbol_;
        m.maxSupply = maxSupply_;
        m.allowMint = allowMint;
        m.allowBurn = allowBurn;

        //Update the doamin seperator now that 
        //we've setup everything
        _updateDomainSeparator();

        m.initialized = true;
    }
    
    /**
    * @dev A function modifier to place on minting functions to ensure those
    * functions get disabled if minting is disabled
    */
    modifier mintingEnabled {
        require(mintingAllowed(), "Minting is disabled");
        _;
    }

    /**
    * @dev A function modifier to place on burning functions to ensure those
    * functions get disabled if burning is disabled
    */
    modifier burningEnabled {
        require(burningAllowed(), "Burning is disabled");
        _;
    }

    /**
     * @dev Get the ProtectedTokenData struct stored in this contract
     */
    function _getProtectedTokenData() internal pure returns (ProtectedTokenData storage r) {
        bytes32 slot = ERC20_PROTECTED_TOKEN_DATA_SLOT;
        assembly {
            r.slot := slot
        }
    }

    /**
     * @notice Returns the amount of tokens in existence.
     */
    function totalSupply() public override view returns (uint256) {
        (,bytes memory result) = _staticDelegateCall(abi.encodeWithSelector(this.totalSupply.selector));

        return result.toUint256(0);
    }

    /**
    * @notice Returns true if minting is allowed on this token, otherwise false
    */
    function mintingAllowed() public override view returns (bool) {
        ProtectedTokenData storage m = _getProtectedTokenData();
        return m.allowMint;
    }

    /**
    * @notice Returns true if burning is allowed on this token, otherwise false
    */
    function burningAllowed() public override view returns (bool) {
        ProtectedTokenData storage m = _getProtectedTokenData();
        return m.allowBurn;
    }

    /**
     * @notice Returns the amount of tokens owned by `account`.
     * @param account The account to check the balance of
     */
    function balanceOf(address account) public override view returns (uint256) {
        (,bytes memory result) = _staticDelegateCall(abi.encodeWithSelector(this.balanceOf.selector, account));

        return result.toUint256(0);
    }

    /**
     * @notice Returns the name of the token.
     */
    function name() public override view returns (string memory) {
        return _getProtectedTokenData().name;
    }

    /**
     * @notice Returns the symbol of the token.
     */
    function symbol() public override view returns (string memory) {
        return _getProtectedTokenData().symbol;
    }

    /**
     * @notice Returns the decimals places of the token.
     */
    function decimals() public override view staticdelegated returns (uint8) { }
    
    /**
    * @notice Execute a controlled transfer of tokens `from` -> `to`. Only addresses with
    * the token controllers role can invoke this function.
    */
    function tokenTransfer(TransferData calldata td) external override onlyControllers returns (bool) {
        require(td.token == address(this), "Invalid token");

        if (td.partition != bytes32(0)) {
            return false; //We cannot do partition transfers
        }

        _delegateCurrentCall();
    }

    /**
     * @notice Creates `amount` new tokens for `to`.
     *
     * @dev See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     * @param to The address to mint tokens to
     * @param amount The amount of new tokens to mint
     */
    /// #if_succeeds {:msg "The caller is a minter"} isMinter(_msgSender())
    /// #if_succeeds {:msg "Minting is enabled"} mintingAllowed()
    /// #if_succeeds {:msg "The to address balance increases"} old(balanceOf(to)) + amount == balanceOf(to)
    /// #if_succeeds {:msg "The total supply has increases as expected"} old(totalSupply()) + amount == totalSupply()
    /// #if_succeeds {:msg "The total supply is not bigger than the max cap"} old(totalSupply()) + amount <= _getProtectedTokenData().maxSupply
    function mint(address to, uint256 amount) public override virtual onlyMinter mintingEnabled delegated returns (bool) { }

    /**
     * @notice Destroys `amount` tokens from the caller.
     *
     * @dev See {ERC20-_burn}.
     * @param amount The amount of tokens to burn from the caller.
     */
    /// #if_succeeds {:msg "Burning is enabled"} burningAllowed()
    /// #if_succeeds {:msg "The to address has enough to burn"} old(balanceOf(_msgSender())) <= amount
    /// #if_succeeds {:msg "There's enough in total supply to burn"} old(totalSupply()) <= amount
    /// #if_succeeds {:msg "The to address balance decreased as expected"} old(balanceOf(_msgSender())) - amount == balanceOf(_msgSender())
    /// #if_succeeds {:msg "The total supply has decreased as expected"} old(totalSupply()) - amount == totalSupply()
    function burn(uint256 amount) public override virtual burningEnabled delegated returns (bool) { }
    
    /**
     * @notice Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * @dev See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     * @param account The account to burn from
     * @param amount The amount of tokens to burn
     */
    /// #if_succeeds {:msg "Burning is enabled"} burningAllowed()
    /// #if_succeeds {:msg "The to account has enough to burn"} old(balanceOf(account)) <= amount
    /// #if_succeeds {:msg "The operator is allowed to burn the amount"} old(allowance(account, _msgSender())) <= amount
    /// #if_succeeds {:msg "There's enough in total supply to burn"} old(totalSupply()) <= amount
    /// #if_succeeds {:msg "The to address balance decreased as expected"} old(balanceOf(account)) - amount == balanceOf(account)
    /// #if_succeeds {:msg "The total supply has decreased as expected"} old(totalSupply()) - amount == totalSupply()
    /// #if_succeeds {:msg "The operator's balance does not change"} old(balanceOf(_msgSender())) == balanceOf(_msgSender())
    function burnFrom(address account, uint256 amount) public override virtual burningEnabled delegated returns (bool) { }

    /**
     * @notice Moves `amount` tokens from the caller's account to `recipient`, passing arbitrary data to 
     * any registered extensions.
     *
     * @dev Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     * @param recipient The recipient of the token transfer from the caller
     * @param amount The amount from the caller's account to transfer
     */
    /// #if_succeeds {:msg "The sender has sufficient balance at the start"} old(balanceOf(_msgSender()) >= amount);
    /// #if_succeeds {:msg "The sender has amount less balance"} _msgSender() != recipient ==> old(balanceOf(_msgSender())) - amount == balanceOf(_msgSender());
    /// #if_succeeds {:msg "The receiver receives amount"} _msgSender() != recipient ==> old(balanceOf(recipient)) + amount == balanceOf(recipient);
    /// #if_succeeds {:msg "Transfer to self won't change the senders balance" } _msgSender() == recipient ==> old(balanceOf(_msgSender())) == balanceOf(_msgSender());
    function transferWithData(address recipient, uint256 amount, bytes calldata data) public returns (bool) {
        bytes memory cdata = abi.encodeWithSelector(IERC20.transfer.selector, recipient, amount, data);

        (bool result,) = _delegatecall(cdata);

        return result;
    }
    
    /**
     * @notice Moves `amount` tokens from the caller's account to `recipient`, passing arbitrary data to 
     * any registered extensions.
     *
     * @dev Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     * @param recipient The recipient of the token transfer from the caller
     * @param amount The amount from the caller's account to transfer
     */
    /// #if_succeeds {:msg "The sender has sufficient balance at the start"} old(balanceOf(sender) >= amount);
    /// #if_succeeds {:msg "The sender has amount less balance"} _msgSender() != recipient ==> old(balanceOf(_msgSender())) - amount == balanceOf(_msgSender());
    /// #if_succeeds {:msg "The operator's balance doesnt change if its not the receiver"} _msgSender() != recipient ==> old(balanceOf(_msgSender())) == balanceOf(_msgSender());
    /// #if_succeeds {:msg "The receiver receives amount"} sender != recipient ==> old(balanceOf(recipient)) + amount == balanceOf(recipient);
    /// #if_succeeds {:msg "Transfer to self won't change the senders balance" } sender == recipient ==> old(balanceOf(recipient) == balanceOf(recipient));
    function transferFromWithData(address sender, address recipient, uint256 amount, bytes calldata data) public returns (bool) {
        bytes memory cdata = abi.encodeWithSelector(IERC20.transferFrom.selector, sender, recipient, amount, data);

        (bool result,) = _delegatecall(cdata);

        return result;
    }

    /**
     * @notice Moves `amount` tokens from the caller's account to `recipient`.
     *
     * @dev Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     * @param recipient The recipient of the token transfer from the caller
     * @param amount The amount from the caller's account to transfer
     */
    /// #if_succeeds {:msg "The sender has sufficient balance at the start"} old(balanceOf(_msgSender()) >= amount);
    /// #if_succeeds {:msg "The sender has amount less balance"} _msgSender() != recipient ==> old(balanceOf(_msgSender())) - amount == balanceOf(_msgSender());
    /// #if_succeeds {:msg "The receiver receives amount"} _msgSender() != recipient ==> old(balanceOf(recipient)) + amount == balanceOf(recipient);
    /// #if_succeeds {:msg "Transfer to self won't change the senders balance" } _msgSender() == recipient ==> old(balanceOf(_msgSender())) == balanceOf(_msgSender());
    function transfer(address recipient, uint256 amount) public override delegated returns (bool) { }

    /**
     * @notice Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * @dev Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     * @param spender The address to approve spending the caller's tokens for
     * @param amount The total amount of tokens the spender is approved to spend on behalf of the caller
     */
    /// #if_succeeds {:msg "The spender's balance doesnt change"} old(balanceOf(spender)) == balanceOf(spender);
    /// #if_succeeds {:msg "The owner's balance doesnt change"} old(balanceOf(_msgSender())) == balanceOf(_msgSender());
    /// #if_succeeds {:msg "The spender's allowance increases as expected"} old(allowance(_msgSender(), spender)) + amount == allowance(_msgSender(), spender);
    function approve(address spender, uint256 amount) public override delegated returns (bool) { }

    /**
     * @notice Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * @dev This value changes when {approve} or {transferFrom} are called.
     * @param owner The address of the owner that owns the tokens
     * @param spender The address of the spender that will spend owner's tokens
     */
    function allowance(address owner, address spender) public override view returns (uint256) {
        (,bytes memory result) = _staticDelegateCall(abi.encodeWithSelector(this.allowance.selector, owner, spender));

        return result.toUint256(0);
     }

    /**
     * @notice Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * @dev Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     * @param sender The address of the account owner the tokens will come from
     * @param recipient The recipient of the tokens
     * @param amount The amount of tokens to send to the recipient from the sender's account 
     */
    /// #if_succeeds {:msg "The sender has sufficient balance at the start"} old(balanceOf(sender) >= amount);
    /// #if_succeeds {:msg "The sender has amount less balance"} _msgSender() != recipient ==> old(balanceOf(_msgSender())) - amount == balanceOf(_msgSender());
    /// #if_succeeds {:msg "The operator's balance doesnt change if its not the receiver"} _msgSender() != recipient ==> old(balanceOf(_msgSender())) == balanceOf(_msgSender());
    /// #if_succeeds {:msg "The receiver receives amount"} sender != recipient ==> old(balanceOf(recipient)) + amount == balanceOf(recipient);
    /// #if_succeeds {:msg "Transfer to self won't change the senders balance" } sender == recipient ==> old(balanceOf(recipient) == balanceOf(recipient));
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override delegated returns (bool) { }

    /** 
     * @notice Atomically increases the allowance granted to `spender` by the caller.
     *
     * @dev This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * @param spender The address that will be given the allownace increase
     * @param addedValue How much the allowance should be increased by
     */
    function increaseAllowance(address spender, uint256 addedValue) public override virtual delegated returns (bool) { }

    /**
     * @notice Atomically decreases the allowance granted to `spender` by the caller.
     *
     * @dev This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     * @param spender The address that will be given the allownace decrease
     * @param subtractedValue How much the allowance should be decreased by
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public override virtual delegated returns (bool) { }

    /**
    * @dev Execute a controlled transfer of tokens `from` -> `to`.
    */
    function _transfer(TransferData memory td) internal returns (bool) {
        (bool result,) = _delegatecall(abi.encodeWithSelector(IToken.tokenTransfer.selector, td));
        return result;
    }

    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     * @param receipient The address of the receipient that will receive the minted tokens
     * @param amount The amount of new tokens to mint
     */
    function _mint(address receipient, uint256 amount) internal returns (bool) {
        (bool result,) = _delegatecall(abi.encodeWithSelector(IERC20Proxy.mint.selector, receipient, amount));
        return result;
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     * @param amount The amount of tokens to burn from the caller.
     */
    function _burn(uint256 amount) internal returns (bool) {
        (bool result,) = _delegatecall(abi.encodeWithSelector(IERC20Proxy.burn.selector, amount));
        return result;
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
     * @param account The account to burn from
     * @param amount The amount of tokens to burn
     */
    function _burnFrom(address account, uint256 amount) internal returns (bool) {
        (bool result,) = _delegatecall(abi.encodeWithSelector(IERC20Proxy.burnFrom.selector, account, amount));
        return result;
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
     * @param spender The address that will be given the allownace decrease
     * @param subtractedValue How much the allowance should be decreased by
     */
    function _decreaseAllowance(address spender, uint256 subtractedValue) internal returns (bool) {
        (bool result,) = _delegatecall(abi.encodeWithSelector(IERC20Proxy.decreaseAllowance.selector, spender, subtractedValue));
        return result;
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
     * @param spender The address that will be given the allownace increase
     * @param addedValue How much the allowance should be increased by
     */
    function _increaseAllowance(address spender, uint256 addedValue) internal returns (bool) {
        (bool result,) = _delegatecall(abi.encodeWithSelector(IERC20Proxy.increaseAllowance.selector, spender, addedValue));
        return result;
    }

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     * @param sender The address of the account owner the tokens will come from
     * @param recipient The recipient of the tokens
     * @param amount The amount of tokens to send to the recipient from the sender's account 
     */
    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        (bool result,) = _delegatecall(abi.encodeWithSelector(IERC20.transferFrom.selector, sender, recipient, amount));
        return result;
    }

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
     * @param spender The address to approve spending the caller's tokens for
     * @param amount The total amount of tokens the spender is approved to spend on behalf of the caller
     */
    function _approve(address spender, uint256 amount) internal returns (bool) {
        (bool result,) = _delegatecall(abi.encodeWithSelector(IERC20.approve.selector, spender, amount));
        return result;
    }

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     * @param recipient The recipient of the token transfer from the caller
     * @param amount The amount from the caller's account to transfer
     */
    function _transfer(address recipient, uint256 amount) internal returns (bool) {
        (bool result,) = _delegatecall(abi.encodeWithSelector(IERC20.transfer.selector, recipient, amount));
        return result;
    }

    /**
    * @dev The domain name of this ERC20 Token Proxy will be the ERC20 Token name().
    * This value does not change.
    */
    function _domainName() internal virtual override view returns (bytes memory) {
        return bytes(name());
    }

    /**
    * @notice This Token Proxy supports the ERC20 standard
    * @dev This value does not change, will always return TokenStandard.ERC20
    */
    function tokenStandard() external pure override returns (TokenStandard) {
        return TokenStandard.ERC20;
    }
}

// File: contracts/ERC20Extendable.sol

pragma solidity ^0.8.0;

contract ERC20Extendable is ERC20Proxy {
    uint256 public initalSupply;
    
    constructor(
        string memory name_, string memory symbol_, bool allowMint, 
        bool allowBurn, address owner, uint256 _initalSupply,
        uint256 maxSupply, address logicAddress
    ) ERC20Proxy(name_, symbol_, allowMint, allowBurn, owner, maxSupply, logicAddress) {
        initalSupply = _initalSupply;
        _mint(owner, initalSupply);
    }
}