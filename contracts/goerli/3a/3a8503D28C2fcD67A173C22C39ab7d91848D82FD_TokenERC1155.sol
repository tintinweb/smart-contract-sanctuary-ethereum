// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "./interfaces/IService.sol";
import "./interfaces/ITokenERC1155.sol";
import "./interfaces/IToken.sol";
import "./interfaces/ITGE.sol";
import "./interfaces/IPool.sol";
import "./interfaces/registry/IRegistry.sol";
import "./libraries/ExceptionsLibrary.sol";

import "./interfaces/IPausable.sol";

/// @title Company (Pool) Token
/// @dev An expanded ERC20 contract, based on which tokens of various types are issued. At the moment, the protocol provides for 2 types of tokens: Governance, which must be created simultaneously with the pool, existing for the pool only in the singular and participating in voting, and Preference, which may be several for one pool and which do not participate in voting in any way.
contract TokenERC1155 is ERC1155SupplyUpgradeable, ITokenERC1155 {
    /// @dev Service address
    IService public service;

    string public symbol;

    mapping(uint256 => string) private _tokenURIs;

    mapping(uint256 => uint256) public cap;

    uint256 lastTokenId;

    /// @dev Pool address
    address public pool;

    /// @dev Token type
    IToken.TokenType public tokenType;

    /// @dev Preference token name
    string public name;

    /// @dev Preference token description, allows up to 5000 characters, for others - ""
    string public description;

    /// @dev List of all TGEs
    mapping(uint256 => address[]) public tgeList;

    /// @dev Total Vested tokens for all TGEs
    mapping(uint256 => uint256) private totalVested;

    /// @dev List of all TGEs with locked tokens
    mapping(uint256 => address[]) private tgeWithLockedTokensList;

    /// @dev Total amount of tokens reserved for the minting protocol fee
    mapping(uint256 => uint256) private totalProtocolFeeReserved;

    // INITIALIZER AND CONSTRUCTOR

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Token creation, can only be started once. At the same time, the TGE contract, which sells the created token, is necessarily simultaneously deployed and receives an entry in the Registry. For the Governance token, the Name field for the ERC20 standard is taken from the trademark of the Pool contract to which the deployed token belongs. For Preference tokens, you can set an arbitrary value of the Name field.
     * @param _service Service
     * @param _pool Pool
     * @param _info Token info struct
     * @param _primaryTGE Primary tge address
     */
    function initialize(
        IService _service,
        address _pool,
        IToken.TokenInfo memory _info,
        address _primaryTGE
    ) external initializer {
        __ERC1155Supply_init();
        name = _info.name;
        symbol = _info.symbol;
        description = _info.description;
        lastTokenId = 1;
        tgeList[lastTokenId].push(_primaryTGE);
        tgeWithLockedTokensList[lastTokenId].push(_primaryTGE);
        tokenType = _info.tokenType;
        service = _service;
        pool = _pool;
    }

    // RESTRICTED FUNCTIONS

    /**
     * @dev Minting of new tokens. Only the TGE or Vesting contract can mint tokens, there is no other way to get an additional issue. If the user who is being minted does not have tokens, they are sent to delegation on his behalf.
     * @param to Recipient
     * @param tokenId tokenId
     * @param amount Amount of tokens
     */
    function mint(
        address to,
        uint256 tokenId,
        uint256 amount
    ) external override(ITokenERC1155) onlyTGEOrVesting {
        // Mint tokens
        _mint(to, tokenId, amount, "");
    }

    /**
     * @dev Burn token
     * @param from Target
     * @param tokenId tokenId
     * @param amount Amount of tokens
     */
    function burn(
        address from,
        uint256 tokenId,
        uint256 amount
    ) public override(ITokenERC1155) whenPoolNotPaused onlyTGEOrVesting {
        // Check that sender is valid
        require(
            service.registry().typeOf(msg.sender) ==
                IRecordsRegistry.ContractType.TGE ||
                msg.sender == from,
            ExceptionsLibrary.INVALID_USER
        );

        // Burn tokens
        _burn(from, tokenId, amount);
    }

    /**
     * @dev Add TGE to TGE archive list
     * @param tge TGE address
     */
    function addTGE(address tge, uint256 tokenId) external onlyTGEFactory {
        tgeList[tokenId].push(tge);
        tgeWithLockedTokensList[tokenId].push(tge);
    }

    /**
     * @dev Set amount of tokens to  Total Vested tokens for all TGEs
     * @param amount amount of tokens
     */
    function setTGEVestedTokens(
        uint256 amount,
        uint256 tokenId
    ) external onlyTGEOrVesting {
        totalVested[tokenId] = amount;
    }

    /**
     * @dev Set tokenid cap
     * @param _tokenId tokenId
     * @param _cap cap
     */
    function setTokenIdCap(
        uint256 _tokenId,
        uint256 _cap
    ) external onlyTGEFactory {
        cap[_tokenId] = _cap;
    }

    /**
     * @dev Set amount of tokens to Total amount of tokens reserved for the minting protocol fee
     * @param amount amount of tokens
     */
    function setProtocolFeeReserved(
        uint256 amount,
        uint256 tokenId
    ) external onlyTGE {
        totalProtocolFeeReserved[tokenId] = amount;
    }

    /**
     * @dev Set amount of tokens to Total amount of tokens reserved for the minting protocol fee
     * @param tokenId tokenId
     * @param tokenURI tokenURI
     */
    function setURI(uint256 tokenId, string memory tokenURI) external onlyTGE {
        _setURI(tokenId, tokenURI);
    }

    // // PUBLIC VIEW FUNCTIONS

    /**
     * @dev Return decimals
     * @return Decimals
     */
    function decimals() public pure returns (uint8) {
        return 0;
    }

    /**
     * @dev The given getter returns the total balance of the address that is not locked for transfer, taking into account all the TGEs with which this token was distributed. Is the difference.
     * @param account Account address
     * @param tokenId tokenId
     * @return Unlocked balance of account
     */
    function unlockedBalanceOf(
        address account,
        uint256 tokenId
    ) public view returns (uint256) {
        // Get total account balance
        uint256 balance = balanceOf(account, tokenId);

        // Iterate through TGE With Locked Tokens List to get locked balance
        address[] memory _tgeWithLockedTokensList = tgeWithLockedTokensList[
            tokenId
        ];
        uint256 totalLocked = 0;
        for (uint256 i; i < _tgeWithLockedTokensList.length; i++) {
            totalLocked += ITGE(_tgeWithLockedTokensList[i]).lockedBalanceOf(
                account
            );
        }

        // Return difference
        return balance - totalLocked;
    }

    /**
     * @dev Return if pool had a successful TGE
     * @return Is any TGE successful
     */
    function isPrimaryTGESuccessful(
        uint256 tokenId
    ) external view returns (bool) {
        return (ITGE(tgeList[tokenId][0]).state() == ITGE.State.Successful);
    }

    /**
     * @dev Return list of pool's TGEs
     * @return TGE list
     */
    function getTGEList(
        uint256 tokenId
    ) external view returns (address[] memory) {
        return tgeList[tokenId];
    }

    /**
     * @dev Return list of pool's TGEs with locked tokens
     * @return TGE list
     */

    function getTgeWithLockedTokensList(
        uint256 tokenId
    ) external view returns (address[] memory) {
        return tgeWithLockedTokensList[tokenId];
    }

    /**
     * @dev Return list of pool's TGEs
     * @return TGE list
     */
    function lastTGE(uint256 tokenId) external view returns (address) {
        return tgeList[tokenId][tgeList[tokenId].length - 1];
    }

    /**
     * @dev Getter returns the sum of all tokens that belong to a specific address, but are in vesting in TGE contracts associated with this token
     * @return Total vesting tokens
     */
    function getTotalTGEVestedTokens(
        uint256 tokenId
    ) public view returns (uint256) {
        return totalVested[tokenId];
    }

    /**
     * @dev Getter returns the sum of all tokens reserved for the minting protocol fee
     * @return Total vesting tokens
     */
    function getTotalProtocolFeeReserved(
        uint256 tokenId
    ) public view returns (uint256) {
        return totalProtocolFeeReserved[tokenId];
    }

    /**
     * @dev Getter returns the sum of all tokens that was minted or reserved for mint
     * @return Total vesting tokens
     */
    function totalSupplyWithReserves(
        uint256 tokenId
    ) public view returns (uint256) {
        uint256 _totalSupplyWithReserves = totalSupply(tokenId) +
            getTotalTGEVestedTokens(tokenId) +
            getTotalProtocolFeeReserved(tokenId);

        return _totalSupplyWithReserves;
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        return _tokenURIs[tokenId];
    }

    function isERC1155() external pure returns (bool) {
        return true;
    }

    function getURIList(
        uint256 limit,
        uint offset
    ) external view returns (string[] memory) {
        string[] memory result = new string[](limit);
        for (uint i = 0; i < limit && i <= lastTokenId; i++)
            result[i] = _tokenURIs[offset + i + 1];
        return result;
    }

    // INTERNAL FUNCTIONS

    /**
     * @dev Transfer tokens from a given user.
     * Check to make sure that transfer amount is less or equal
     * to least amount of unlocked tokens for any proposal that user might have voted for.
     * @param from User address
     * @param to Recipient address
     * @param amount Amount of tokens
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    ) internal whenPoolNotPaused {
        // Execute transfer
        super._safeTransferFrom(from, to, tokenId, amount, "");
    }

    function transfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    ) external override whenPoolNotPaused {
        // Execute transfer
        _transfer(from, to, tokenId, amount);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        if (from != address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                // Update list of TGEs with locked tokens
                _updateTgeWithLockedTokensList(ids[i]);

                // Check that locked tokens are not transferred
                require(
                    amounts[i] <= unlockedBalanceOf(from, ids[i]),
                    ExceptionsLibrary.LOW_UNLOCKED_BALANCE
                );
                service.registry().log(
                    msg.sender,
                    address(this),
                    0,
                    abi.encodeWithSelector(
                        ITokenERC1155.transfer.selector,
                        from,
                        to,
                        ids[i],
                        amounts[i]
                    )
                );
            }
        }
    }

    /**
     * @dev Sets `tokenURI` as the tokenURI of `tokenId`.
     */
    function _setURI(uint256 tokenId, string memory tokenURI) internal {
        _tokenURIs[tokenId] = tokenURI;
        emit URI(uri(tokenId), tokenId);
    }

    // PRIVATE FUNCTIONS

    /**
     * @dev Updates tgeWithLockedTokensList. Removes TGE from list, if transfer is unlocked
     */
    function _updateTgeWithLockedTokensList(uint256 tokenId) private {
        address[] memory _tgeWithLockedTokensList = tgeWithLockedTokensList[
            tokenId
        ];
        for (uint256 i; i < _tgeWithLockedTokensList.length; i++) {
            // Check if transfer is unlocked
            if (ITGE(_tgeWithLockedTokensList[i]).transferUnlocked()) {
                // Remove tge from tgeWithLockedTokensList when transfer is unlocked
                tgeWithLockedTokensList[tokenId][i] = tgeWithLockedTokensList[
                    tokenId
                ][tgeWithLockedTokensList[tokenId].length - 1];
                tgeWithLockedTokensList[tokenId].pop();
            }
        }
    }

    // MODIFIERS

    modifier onlyPool() {
        require(msg.sender == pool, ExceptionsLibrary.NOT_POOL);
        _;
    }

    modifier onlyTGEFactory() {
        require(
            msg.sender == address(service.tgeFactory()),
            ExceptionsLibrary.NOT_TGE_FACTORY
        );
        _;
    }

    modifier onlyTGE() {
        require(
            service.registry().typeOf(msg.sender) ==
                IRecordsRegistry.ContractType.TGE,
            ExceptionsLibrary.NOT_TGE
        );
        _;
    }

    modifier onlyTGEOrVesting() {
        bool isTGE = service.registry().typeOf(msg.sender) ==
            IRecordsRegistry.ContractType.TGE;
        bool isVesting = address(service.vesting()) == msg.sender;
        require(isTGE || isVesting, ExceptionsLibrary.NOT_TGE);
        _;
    }

    modifier whenPoolNotPaused() {
        require(!IPausable(pool).paused(), ExceptionsLibrary.SERVICE_PAUSED);
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerableUpgradeable is IAccessControlUpgradeable {
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
interface IAccessControlUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (governance/utils/IVotes.sol)
pragma solidity ^0.8.0;

/**
 * @dev Common interface for {ERC20Votes}, {ERC721Votes}, and other {Votes}-enabled contracts.
 *
 * _Available since v4.5._
 */
interface IVotesUpgradeable {
    /**
     * @dev Emitted when an account changes their delegate.
     */
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /**
     * @dev Emitted when a token transfer or delegate change results in changes to a delegate's number of votes.
     */
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    /**
     * @dev Returns the current amount of votes that `account` has.
     */
    function getVotes(address account) external view returns (uint256);

    /**
     * @dev Returns the amount of votes that `account` had at the end of a past block (`blockNumber`).
     */
    function getPastVotes(address account, uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the total supply of votes available at the end of a past block (`blockNumber`).
     *
     * NOTE: This value is the sum of all available votes, which is not necessarily the sum of all delegated votes.
     * Votes that have not been delegated are still part of total supply, even though they would not participate in a
     * vote.
     */
    function getPastTotalSupply(uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the delegate that `account` has chosen.
     */
    function delegates(address account) external view returns (address);

    /**
     * @dev Delegates votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) external;

    /**
     * @dev Delegates votes from signer to `delegatee`.
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

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
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155Upgradeable.sol";
import "./IERC1155ReceiverUpgradeable.sol";
import "./extensions/IERC1155MetadataURIUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC1155Upgradeable, IERC1155MetadataURIUpgradeable {
    using AddressUpgradeable for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    function __ERC1155_init(string memory uri_) internal onlyInitializing {
        __ERC1155_init_unchained(uri_);
    }

    function __ERC1155_init_unchained(string memory uri_) internal onlyInitializing {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/extensions/ERC1155Supply.sol)

pragma solidity ^0.8.0;

import "../ERC1155Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 *
 * Useful for scenarios where Fungible and Non-fungible tokens have to be
 * clearly identified. Note: While a totalSupply of 1 might mean the
 * corresponding is an NFT, there is no guarantees that no other token with the
 * same id are not going to be minted.
 */
abstract contract ERC1155SupplyUpgradeable is Initializable, ERC1155Upgradeable {
    function __ERC1155Supply_init() internal onlyInitializing {
    }

    function __ERC1155Supply_init_unchained() internal onlyInitializing {
    }
    mapping(uint256 => uint256) private _totalSupply;

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return ERC1155SupplyUpgradeable.totalSupply(id) > 0;
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                uint256 amount = amounts[i];
                uint256 supply = _totalSupply[id];
                require(supply >= amount, "ERC1155: burn amount exceeds totalSupply");
                unchecked {
                    _totalSupply[id] = supply - amount;
                }
            }
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155Upgradeable.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURIUpgradeable is IERC1155Upgradeable {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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

pragma solidity 0.8.17;

import "./ITGE.sol";

import "./governor/IGovernanceSettings.sol";

interface ICustomProposal {}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IInvoice {
    struct InvoiceCore {
        uint256 amount;
        address unitOfAccount;
        uint256 expirationBlock;
        string description;
        address[] whitelist;
    }
    struct InvoiceInfo {
        InvoiceCore core;
        uint256 invoiceId;
        address createdBy;
        bool isPaid;
        bool isCanceled;
    }

    enum InvoiceState {
        None,
        Active,
        Paid,
        Expired,
        Canceled
    }

    function createInvoice(address pool, InvoiceCore memory core) external;

    function payInvoice(address pool, uint256 invoiceId) external payable;

    function cancelInvoice(address pool, uint256 invoiceId) external;

    function setInvoiceCanceled(address pool, uint256 invoiceId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IPausable {
    function paused() external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IToken.sol";
import "./registry/IRegistry.sol";
import "./registry/ICompaniesRegistry.sol";

import "./governor/IGovernor.sol";
import "./governor/IGovernanceSettings.sol";
import "./governor/IGovernorProposals.sol";

interface IPool is IGovernorProposals {
    function initialize(ICompaniesRegistry.CompanyInfo memory companyInfo_) external;

    function setNewOwnerWithSettings(
        address owner_,
        string memory trademark_,
        IGovernanceSettings.NewGovernanceSettings memory governanceSettings_
    ) external;

    function propose(
        address proposer,
        uint256 proposalType,
        IGovernor.ProposalCoreData memory core,
        IGovernor.ProposalMetaData memory meta
    ) external returns (uint256 proposalId);

    function setToken(address token_, IToken.TokenType tokenType_) external;

    function setProposalIdToTGE(address tge) external;

    function cancelProposal(uint256 proposalId) external;

    function setSettings(
        IGovernanceSettings.NewGovernanceSettings memory governanceSettings_,
        address[] memory secretary,
        address[] memory executor
    ) external;

    function owner() external view returns (address);

    function isDAO() external view returns (bool);

    function trademark() external view returns (string memory);

    function getGovernanceToken() external view returns (IToken);

    function tokenExists(IToken token_) external view returns (bool);

    function tokenTypeByAddress(
        address token_
    ) external view returns (IToken.TokenType);

    function isValidProposer(address account) external view returns (bool);

    function isPoolSecretary(address account) external view returns (bool);

    function isLastProposalIdByTypeActive(
        uint256 type_
    ) external view returns (bool);

    function validateGovernanceSettings(
        IGovernanceSettings.NewGovernanceSettings memory settings
    ) external pure;

    function getPoolSecretary() external view returns (address[] memory);

    function getPoolExecutor() external view returns (address[] memory);

    function setCompanyInfo(
        uint256 _jurisdiction,
        uint256 _entityType,
        string memory _ein,
        string memory _dateOfIncorporation,
        string memory _OAuri
    ) external;

    function castVote(uint256 proposalId, bool support) external;

    function executeProposal(uint256 proposalId) external;

    function customTxByOwner(
        address target,
        uint256 value,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/IAccessControlEnumerableUpgradeable.sol";
import "./ITGE.sol";
import "./ICustomProposal.sol";
import "./registry/IRecordsRegistry.sol";
import "./registry/ICompaniesRegistry.sol";
import "./registry/IRegistry.sol";
import "./IToken.sol";
import "./IInvoice.sol";
import "./IVesting.sol";
import "./ITokenFactory.sol";
import "./ITGEFactory.sol";
import "./IPool.sol";
import "./governor/IGovernanceSettings.sol";

interface IService is IAccessControlEnumerableUpgradeable {
    function ADMIN_ROLE() external view returns (bytes32);

    function WHITELISTED_USER_ROLE() external view returns (bytes32);

    function SERVICE_MANAGER_ROLE() external view returns (bytes32);

    function EXECUTOR_ROLE() external view returns (bytes32);

    function createPool(
        ICompaniesRegistry.CompanyInfo memory companyInfo
    ) external;

    function addProposal(uint256 proposalId) external;

    function addEvent(
        IRecordsRegistry.EventType eventType,
        uint256 proposalId,
        string calldata metaHash
    ) external;

    function setProtocolCollectedFee(
        address _token,
        uint256 _protocolTokenFee
    ) external;

    function registry() external view returns (IRegistry);

    function vesting() external view returns (IVesting);

    function tokenFactory() external view returns (ITokenFactory);

    function tgeFactory() external view returns (ITGEFactory);

    function invoice() external view returns (IInvoice);

    function protocolTreasury() external view returns (address);

    function protocolTokenFee() external view returns (uint256);

    function getMinSoftCap() external view returns (uint256);

    function getProtocolTokenFee(
        uint256 amount
    ) external view returns (uint256);

    function getProtocolCollectedFee(
        address token_
    ) external view returns (uint256);

    function poolBeacon() external view returns (address);

    function tgeBeacon() external view returns (address);

    function tokenBeacon() external view returns (address);

    function tokenERC1155Beacon() external view returns (address);

    function customProposal() external view returns (ICustomProposal);

    function validateTGEInfo(
        ITGE.TGEInfo calldata info,
        uint256 cap,
        uint256 totalSupply,
        IToken.TokenType tokenType
    ) external view;

    function getPoolAddress(
        ICompaniesRegistry.CompanyInfo memory info
    ) external view returns (address);

    function paused() external view returns (bool);

    function addInvoiceEvent(
        address pool,
        uint256 invoiceId
    ) external returns (uint256);

    function purchasePool(
        uint256 jurisdiction,
        uint256 entityType,
        string memory trademark,
        IGovernanceSettings.NewGovernanceSettings memory governanceSettings
    ) external payable;

    function transferPurchasedPoolByService(
        address newowner,
        uint256 jurisdiction,
        uint256 entityType,
        string memory trademark,
        IGovernanceSettings.NewGovernanceSettings memory governanceSettings
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IToken.sol";
import "./ITokenERC1155.sol";
import "./IVesting.sol";

interface ITGE {
    struct TGEInfo {
        uint256 price;
        uint256 hardcap;
        uint256 softcap;
        uint256 minPurchase;
        uint256 maxPurchase;
        uint256 duration;
        IVesting.VestingParams vestingParams;
        address[] userWhitelist;
        address unitOfAccount;
        uint256 lockupDuration;
        uint256 lockupTVL;
    }

    function initialize(
        address _service,
        address _token,
        uint256 _tokenId,
        string memory _uri,
        TGEInfo calldata _info,
        uint256 _protocolFee
    ) external;

    enum State {
        Active,
        Failed,
        Successful
    }

    function token() external view returns (address);

    function tokenId() external view returns (uint256);

    function state() external view returns (State);

    function getInfo() external view returns (TGEInfo memory);

    function transferUnlocked() external view returns (bool);

    function purchaseOf(address user) external view returns (uint256);

    function redeemableBalanceOf(address user) external view returns (uint256);

    function lockedBalanceOf(address account) external view returns (uint256);

    function getEnd() external view returns (uint256);

    function totalPurchased() external view returns (uint256);

    function isERC1155TGE() external view returns (bool);

    function purchase(uint256 amount) external payable;

    function transferFunds() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./ITGE.sol";
import "./IToken.sol";
import "./governor/IGovernanceSettings.sol";

interface ITGEFactory {
    function createSecondaryTGE(
        address token,
        ITGE.TGEInfo calldata tgeInfo,
        IToken.TokenInfo calldata tokenInfo,
        string memory metadataURI
    ) external;

    function createSecondaryTGEERC1155(
        address token,
        uint256 tokenId,
        string memory uri,
        ITGE.TGEInfo calldata tgeInfo,
        IToken.TokenInfo calldata tokenInfo,
        string memory metadataURI
    ) external;

    function createPrimaryTGE(
        address poolAddress,
        IToken.TokenInfo memory tokenInfo,
        ITGE.TGEInfo memory tgeInfo,
        string memory metadataURI,
        IGovernanceSettings.NewGovernanceSettings memory governanceSettings_,
        address[] memory secretary,
        address[] memory executor
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/utils/IVotesUpgradeable.sol";
import "./IService.sol";

interface IToken is IVotesUpgradeable, IERC20Upgradeable {
    struct TokenInfo {
        TokenType tokenType;
        string name;
        string symbol;
        string description;
        uint256 cap;
        uint8 decimals;
    }

    enum TokenType {
        None,
        Governance,
        Preference
    }

    function initialize(
        IService service_,
        address pool_,
        TokenInfo memory info,
        address primaryTGE_
    ) external;

    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;

    function cap() external view returns (uint256);

    function unlockedBalanceOf(address account) external view returns (uint256);

    function pool() external view returns (address);

    function service() external view returns (IService);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function tokenType() external view returns (TokenType);

    function lastTGE() external view returns (address);

    function getTGEList() external view returns (address[] memory);

    function isPrimaryTGESuccessful() external view returns (bool);

    function addTGE(address tge) external;

    function setTGEVestedTokens(uint256 amount) external;

    function setProtocolFeeReserved(uint256 amount) external;

    function getTotalTGEVestedTokens() external view returns (uint256);

    function getTotalProtocolFeeReserved() external view returns (uint256);

    function totalSupplyWithReserves() external view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "./IService.sol";
import "./IToken.sol";

interface ITokenERC1155 is IERC1155Upgradeable {
    function initialize(
        IService service_,
        address pool_,
        IToken.TokenInfo memory info,
        address primaryTGE_
    ) external;

    function mint(address to, uint256 tokenId, uint256 amount) external;

    function burn(address from, uint256 tokenId, uint256 amount) external;

    function cap(uint256 tokenId) external view returns (uint256);

    function unlockedBalanceOf(
        address account,
        uint256 tokenId
    ) external view returns (uint256);

    function pool() external view returns (address);

    function service() external view returns (IService);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function tokenType() external view returns (IToken.TokenType);

    function lastTGE(uint256 tokenId) external view returns (address);

    function getTGEList(
        uint256 tokenId
    ) external view returns (address[] memory);

    function isPrimaryTGESuccessful(
        uint256 tokenId
    ) external view returns (bool);

    function addTGE(address tge, uint256 tokenId) external;

    function setTGEVestedTokens(uint256 amount, uint256 tokenId) external;

    function setProtocolFeeReserved(uint256 amount, uint256 tokenId) external;

    function getTotalTGEVestedTokens(
        uint256 tokenId
    ) external view returns (uint256);

    function getTotalProtocolFeeReserved(
        uint256 tokenId
    ) external view returns (uint256);

    function totalSupplyWithReserves(
        uint256 tokenId
    ) external view returns (uint256);

    function setURI(uint256 tokenId, string memory tokenURI) external;

    function setTokenIdCap(uint256 _tokenId, uint256 _cap) external;

    function transfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IToken.sol";
import "./ITokenERC1155.sol";

interface ITokenFactory {
    function createToken(
        address pool,
        IToken.TokenInfo memory info,
        address primaryTGE
    ) external returns (address token);

    function createTokenERC1155(
        address pool,
        IToken.TokenInfo memory info,
        address primaryTGE
    ) external returns (address token);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IVesting {
    struct VestingParams {
        uint256 vestedShare;
        uint256 cliff;
        uint256 cliffShare;
        uint256 spans;
        uint256 spanDuration;
        uint256 spanShare;
        uint256 claimTVL;
        address[] resolvers;
    }

    function vest(address to, uint256 amount) external;

    function cancel(address tge, address account) external;

    function validateParams(
        VestingParams memory params
    ) external pure returns (bool);

    function vested(
        address tge,
        address account
    ) external view returns (uint256);

    function totalVested(address tge) external view returns (uint256);

    function vestedBalanceOf(
        address tge,
        address account
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IGovernanceSettings {
    /**
     * @notice Governance settings
     * @param proposalThreshold_ Proposal threshold
     * @param quorumThreshold_ Quorum threshold
     * @param decisionThreshold_ Decision threshold
     * @param votingDuration_ Voting duration
     * @param transferValueForDelay_ Transfer value for delay
     * @param executionDelays_ List of execution delays for all proposal types
     */
    struct NewGovernanceSettings {
        uint256 proposalThreshold;
        uint256 quorumThreshold;
        uint256 decisionThreshold;
        uint256 votingDuration;
        uint256 transferValueForDelay;
        uint256[4] executionDelays;
        uint256 votingStartDelay;
    }

    function setGovernanceSettings(
        NewGovernanceSettings memory settings
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../../interfaces/registry/IRecordsRegistry.sol";

interface IGovernor {
    /**
     * @dev Struct with proposal core data
     * @param targets Targets
     * @param values ETH values
     * @param callDatas Call datas to pass in .call() to target
     * @param quorumThreshold Quorum threshold (as percents)
     * @param decisionThreshold Decision threshold (as percents)
     * @param executionDelay Execution delay after successful voting (blocks)
     */
    struct ProposalCoreData {
        address[] targets;
        uint256[] values;
        bytes[] callDatas;
        uint256 quorumThreshold;
        uint256 decisionThreshold;
        uint256 executionDelay;
    }

    /**
     * @dev Struct with proposal metadata
     * @param proposalType Proposal type
     * @param description Description
     * @param metaHash Metadata hash
     */
    struct ProposalMetaData {
        IRecordsRegistry.EventType proposalType;
        string description;
        string metaHash;
    }

    function proposalState(uint256 proposalId)
        external
        view
        returns (uint256 state);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../IService.sol";

interface IGovernorProposals {
    function service() external view returns (IService);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../ITGE.sol";
import "../IToken.sol";

interface ICompaniesRegistry {
    struct CompanyInfo {
        uint256 jurisdiction;
        uint256 entityType;
        string ein;
        string dateOfIncorporation;
        uint256 fee;
    }

    function lockCompany(
        uint256 jurisdiction,
        uint256 entityType
    ) external returns (CompanyInfo memory);

    function createCompany(
        CompanyInfo calldata info
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IRecordsRegistry {
    // Directory
    enum ContractType {
        None,
        Pool,
        GovernanceToken,
        PreferenceToken,
        TGE
    }

    enum EventType {
        None,
        Transfer,
        TGE,
        GovernanceSettings
    }

    /**
     * @dev Contract information structure
     * @param addr Contract address
     * @param contractType Contract type
     * @param description Contract description
     */
    struct ContractInfo {
        address addr;
        ContractType contractType;
        string description;
    }

    /**
     * @dev Proposal information structure
     * @param pool Pool address
     * @param proposalId Proposal ID
     * @param description Proposal description
     */
    struct ProposalInfo {
        address pool;
        uint256 proposalId;
        string description;
    }

    /**
     * @dev Event information structure
     * @param eventType Event type
     * @param pool Pool address
     * @param eventContract Address of the Event contract
     * @param proposalId Proposal ID
     * @param metaHash Hash value of event metadata
     */
    struct Event {
        EventType eventType;
        address pool;
        address eventContract;
        uint256 proposalId;
        string metaHash;
    }

    function addContractRecord(
        address addr,
        ContractType contractType,
        string memory description
    ) external returns (uint256 index);

    function addProposalRecord(
        address pool,
        uint256 proposalId
    ) external returns (uint256 index);

    function addEventRecord(
        address pool,
        EventType eventType,
        address eventContract,
        uint256 proposalId,
        string calldata metaHash
    ) external returns (uint256 index);

    function typeOf(address addr) external view returns (ContractType);

     
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./ICompaniesRegistry.sol";
import "./ITokensRegistry.sol";
import "./IRecordsRegistry.sol";
import "../IService.sol";

interface IRegistry is ITokensRegistry, ICompaniesRegistry, IRecordsRegistry {
    function service() external view returns (IService);

    function COMPANIES_MANAGER_ROLE() external view returns (bytes32);

    function hasRole(
        bytes32 role,
        address account
    ) external view returns (bool);

    function log(
        address sender,
        address receiver,
        uint256 value, 
        bytes memory data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface ITokensRegistry {
    function isTokenWhitelisted(address token) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

library ExceptionsLibrary {
    string public constant ADDRESS_ZERO = "ADDRESS_ZERO";
    string public constant INCORRECT_ETH_PASSED = "INCORRECT_ETH_PASSED";
    string public constant NO_COMPANY = "NO_COMPANY";
    string public constant INVALID_TOKEN = "INVALID_TOKEN";
    string public constant NOT_POOL = "NOT_POOL";
    string public constant NOT_TGE = "NOT_TGE";
    string public constant NOT_Registry = "NOT_Registry";
    string public constant NOT_POOL_OWNER = "NOT_POOL_OWNER";
    string public constant NOT_SERVICE_OWNER = "NOT_SERVICE_OWNER";
    string public constant IS_DAO = "IS_DAO";
    string public constant NOT_DAO = "NOT_DAO";
    string public constant NOT_WHITELISTED = "NOT_WHITELISTED";
    string public constant NOT_SERVICE = "NOT_SERVICE";
    string public constant WRONG_STATE = "WRONG_STATE";
    string public constant TRANSFER_FAILED = "TRANSFER_FAILED";
    string public constant CLAIM_NOT_AVAILABLE = "CLAIM_NOT_AVAILABLE";
    string public constant NO_LOCKED_BALANCE = "NO_LOCKED_BALANCE";
    string public constant LOCKUP_TVL_REACHED = "LOCKUP_TVL_REACHED";
    string public constant HARDCAP_OVERFLOW = "HARDCAP_OVERFLOW";
    string public constant MAX_PURCHASE_OVERFLOW = "MAX_PURCHASE_OVERFLOW";
    string public constant HARDCAP_OVERFLOW_REMAINING_SUPPLY =
        "HARDCAP_OVERFLOW_REMAINING_SUPPLY";
    string public constant HARDCAP_AND_PROTOCOL_FEE_OVERFLOW_REMAINING_SUPPLY =
        "HARDCAP_AND_PROTOCOL_FEE_OVERFLOW_REMAINING_SUPPLY";
    string public constant MIN_PURCHASE_UNDERFLOW = "MIN_PURCHASE_UNDERFLOW";
    string public constant LOW_UNLOCKED_BALANCE = "LOW_UNLOCKED_BALANCE";
    string public constant ZERO_PURCHASE_AMOUNT = "ZERO_PURCHASE_AMOUNTs";
    string public constant NOTHING_TO_REDEEM = "NOTHING_TO_REDEEM";
    string public constant RECORD_IN_USE = "RECORD_IN_USE";
    string public constant INVALID_EIN = "INVALID_EIN";
    string public constant VALUE_ZERO = "VALUE_ZERO";
    string public constant ALREADY_SET = "ALREADY_SET";
    string public constant VOTING_FINISHED = "VOTING_FINISHED";
    string public constant ALREADY_EXECUTED = "ALREADY_EXECUTED";
    string public constant ACTIVE_TGE_EXISTS = "ACTIVE_TGE_EXISTS";
    string public constant INVALID_VALUE = "INVALID_VALUE";
    string public constant INVALID_CAP = "INVALID_CAP";
    string public constant INVALID_HARDCAP = "INVALID_HARDCAP";
    string public constant ONLY_POOL = "ONLY_POOL";
    string public constant ETH_TRANSFER_FAIL = "ETH_TRANSFER_FAIL";
    string public constant TOKEN_TRANSFER_FAIL = "TOKEN_TRANSFER_FAIL";
    string public constant SERVICE_PAUSED = "SERVICE_PAUSED";
    string public constant INVALID_PROPOSAL_TYPE = "INVALID_PROPOSAL_TYPE";
    string public constant EXECUTION_FAILED = "EXECUTION_FAILED";
    string public constant INVALID_USER = "INVALID_USER";
    string public constant NOT_LAUNCHED = "NOT_LAUNCHED";
    string public constant LAUNCHED = "LAUNCHED";
    string public constant VESTING_TVL_REACHED = "VESTING_TVL_REACHED";
    string public constant WRONG_TOKEN_ADDRESS = "WRONG_TOKEN_ADDRESS";
    string public constant GOVERNANCE_TOKEN_EXISTS = "GOVERNANCE_TOKEN_EXISTS";
    string public constant THRESHOLD_NOT_REACHED = "THRESHOLD_NOT_REACHED";
    string public constant UNSUPPORTED_TOKEN_TYPE = "UNSUPPORTED_TOKEN_TYPE";
    string public constant ALREADY_VOTED = "ALREADY_VOTED";
    string public constant ZERO_VOTES = "ZERO_VOTES";
    string public constant ACTIVE_GOVERNANCE_SETTINGS_PROPOSAL_EXISTS =
        "ACTIVE_GOVERNANCE_SETTINGS_PROPOSAL_EXISTS";
    string public constant EMPTY_ADDRESS = "EMPTY_ADDRESS";
    string public constant NOT_VALID_PROPOSER = "NOT_VALID_PROPOSER";
    string public constant SHARES_SUM_EXCEEDS_ONE = "SHARES_SUM_EXCEEDS_ONE";
    string public constant NOT_RESOLVER = "NOT_RESOLVER";
    string public constant NOT_REGISTRY = "NOT_REGISTRY";
    string public constant INVALID_TARGET = "INVALID_TARGET";
    string public constant NOT_TGE_FACTORY = "NOT_TGE_FACTORY";
    string public constant WRONG_AMOUNT = "WRONG_AMOUNT";
    string public constant WRONG_BLOCK_NUMBER = "WRONG_BLOCK_NUMBER";
    string public constant NOT_VALID_EXECUTOR = "NOT_VALID_EXECUTOR";
    string public constant POOL_PAUSED = "POOL_PAUSED";
    string public constant NOT_INVOICE_MANAGER = "NOT_INVOICE_MANAGER";
     string public constant WRONG_RESOLVER = "WRONG_RESOLVER";
}