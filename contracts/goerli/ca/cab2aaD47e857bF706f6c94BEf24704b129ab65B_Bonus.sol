// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
/*
      /$$$$$$            /$$$$$$$   /$$$$$$   /$$$$$$
     /$$__  $$          | $$__  $$ /$$__  $$ /$$__  $$
    | $$  \__/ /$$   /$$| $$  \ $$| $$  \ $$| $$  \ $$
    |  $$$$$$ | $$  | $$| $$  | $$| $$$$$$$$| $$  | $$
     \____  $$| $$  | $$| $$  | $$| $$__  $$| $$  | $$
     /$$  \ $$| $$  | $$| $$  | $$| $$  | $$| $$  | $$
    |  $$$$$$/|  $$$$$$/| $$$$$$$/| $$  | $$|  $$$$$$/
     \______/  \______/ |_______/ |__/  |__/ \______/

*/
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./interfaces/IBonus.sol";
import "./access-control/SuAccessControlAuthenticated.sol";

contract Bonus is IBonus, SuAccessControlAuthenticated {
    mapping(address => NFTInfo) public nftInfo;
    mapping(address => UserInfo) public userInfo;
    mapping(address => CommunityAdminInfo) public communityAdminInfo;
    mapping(address => AdminInfo) public adminInfo;

    function initialize(address _accessControlSingleton, address defaultAdmin) public initializer {
        __SuAuthenticated_init(_accessControlSingleton);
        adminInfo[defaultAdmin].isAdmin = true;
    }

    function _getLevelByXP(uint256 xp) internal pure returns (uint16) {
        if (xp < 1000) return 1;
        if (xp < 2000) return 2;
        if (xp < 3200) return 3;
        if (xp < 4600) return 4;
        if (xp < 6200) return 5;
        if (xp < 8000) return 6;
        if (xp < 10000) return 7;
        if (xp < 12200) return 8;
        if (xp < 14700) return 9;

        if (xp < 17500) return 10;
        if (xp < 20600) return 11;
        if (xp < 24320) return 12;
        if (xp < 28784) return 13;
        if (xp < 34140) return 14;
        if (xp < 40567) return 15;
        if (xp < 48279) return 16;
        if (xp < 57533) return 17;
        if (xp < 68637) return 18;
        if (xp < 81961) return 19;

        if (xp < 97949) return 20;
        if (xp < 117134) return 21;
        if (xp < 140156) return 22;
        if (xp < 167782) return 23;
        if (xp < 200933) return 24;
        if (xp < 240714) return 25;
        if (xp < 288451) return 26;
        if (xp < 345735) return 27;
        if (xp < 414475) return 28;
        if (xp < 496963) return 29;

        if (xp < 595948) return 30;
        if (xp < 714730) return 31;
        if (xp < 857268) return 32;
        if (xp < 1028313) return 33;
        if (xp < 1233567) return 34;
        if (xp < 1479871) return 35;
        if (xp < 1775435) return 36;
        if (xp < 2130111) return 37;
        if (xp < 2555722) return 38;
        if (xp < 3066455) return 39;

        if (xp < 3679334) return 40;
        if (xp < 4414788) return 41;
        if (xp < 5297332) return 42;
        if (xp < 6356384) return 43;
        if (xp < 7627246) return 44;
        if (xp < 9152280) return 45;
        if (xp < 10982320) return 46;
        if (xp < 13178368) return 47;
        if (xp < 15813625) return 48;
        if (xp < 18975933) return 49;

        if (xp < 22770702) return 50;
        if (xp < 27324424) return 51;
        if (xp < 32788890) return 52;
        if (xp < 39346249) return 53;
        if (xp < 47215079) return 54;
        if (xp < 56657675) return 55;
        if (xp < 67988790) return 56;
        if (xp < 81586128) return 57;
        if (xp < 97902933) return 58;
        if (xp < 117483099) return 59;

        if (xp < 140979298) return 60;
        if (xp < 169174736) return 61;
        if (xp < 203009261) return 62;
        if (xp < 243610691) return 63;
        if (xp < 292332407) return 64;
        if (xp < 350798466) return 65;
        if (xp < 420957736) return 66;
        if (xp < 505148860) return 67;
        if (xp < 606178208) return 68;
        if (xp < 727413425) return 69;

        if (xp < 872895685) return 70;
        if (xp < 1047474397) return 71;
        if (xp < 1256968851) return 72;
        if (xp < 1508362195) return 73;
        if (xp < 1810034207) return 74;
        if (xp >= 1810034207) return 75;

        return 1;
    }

    function getLevel(address user) public view override returns (uint16) {
        return _getLevelByXP(userInfo[user].xp);
    }

    function setAdmin(address admin, bool isAdmin) public onlyRole(DAO_ROLE) override {
        adminInfo[admin].isAdmin = isAdmin;
    }

    function setCommunityAdmin(address communityAdmin, uint256 xpLimit, uint16 levelLimit) public override {
        require(adminInfo[msg.sender].isAdmin, "Need admin rights");
        communityAdminInfo[communityAdmin].xpLimit = xpLimit;
        communityAdminInfo[communityAdmin].levelLimit = levelLimit;
    }

    function setNftInfo(address nft, uint256 allocation, uint256 donationBonusRatio) public override {
        require(adminInfo[msg.sender].isAdmin, "Need admin rights");
        nftInfo[nft].allocation = allocation;
        nftInfo[nft].donationBonusRatio = donationBonusRatio;
    }

    function setUserInfo(address user, uint256 allocation, uint256 donationBonusRatio) public override {
        require(adminInfo[msg.sender].isAdmin, "Need admin rights");
        userInfo[user].allocation = allocation;
        userInfo[user].donationBonusRatio = donationBonusRatio;
    }

    function distributeXp(address user, uint256 xp) public override {
        require(communityAdminInfo[msg.sender].levelLimit > 0, "Need communityAdmin rights");
        require(
            xp <= communityAdminInfo[msg.sender].xpLimit,
            "XP to distribute shouldn't be more than admin xpLimit"
        );

        communityAdminInfo[msg.sender].xpLimit = communityAdminInfo[msg.sender].xpLimit - xp;
        userInfo[user].xp = userInfo[user].xp + xp;

        uint16 newUserLevel = _getLevelByXP(userInfo[user].xp);
        require(
            newUserLevel <= communityAdminInfo[msg.sender].levelLimit,
            "User level should be less than admin levelLimit"
        );
    }

    function getAllocation(address user) public view override returns (uint256) {
        return userInfo[user].allocation;
    }

    function getNftAllocation(address nft) public view override returns (uint256) {
        return nftInfo[nft].allocation;
    }


    function getBonus(address user) public view override returns (uint256) {
        return userInfo[user].donationBonusRatio;
    }

    function getNftBonus(address nft) public view override returns (uint256) {
        return nftInfo[nft].donationBonusRatio;
    }

    /**
     * Returns true/false whether this NFT with tokenId tokens can be transfer
     */
    function isTokenTransferable(address nft, address from, address to, uint256 tokenId) external view returns (bool) {
        return false;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IBonus {
    /**
     * @notice Info for each nft.
     * `allocation` User allocation
     * `donationBonusRatio` Bonus during distribution
    **/
    struct NFTInfo {
        uint256 allocation;
        uint256 donationBonusRatio;
    }

    /**
     * @notice Info of each user.
     * `xp` The amount of XP.
     * `allocation` User allocation
     * `donationBonusRatio` Bonus during distribution
    **/
    struct UserInfo {
        uint256 xp;
        uint256 allocation;
        uint256 donationBonusRatio;
    }

    /**
     * @notice Info of each admin (Can setup communityAdmin)
     * `isAdmin` Boolean if it's admin
    **/
    struct AdminInfo {
        bool isAdmin;
    }

    /**
     * @notice Info of each community admin (Can distribute XP).
     * `xpLimit` The amount of XP that admin can distribute over other users
     * `levelLimit` Admins can't distribute tokens so that (user level > levelLimit)
    **/
    struct CommunityAdminInfo {
        uint256 xpLimit;
        uint16 levelLimit;
    }

    /**
     * @notice Set allocation and donationBonusRatio for NFT
     * `isAdmin` Address of admin
    **/
    function setNftInfo(address nft, uint256 allocation, uint256 donationBonusRatio) external;

    /**
     * @notice Set allocation and donationBonusRatio for user
     * `isAdmin` Address of admin
    **/
    function setUserInfo(address user, uint256 allocation, uint256 donationBonusRatio) external;

    /**
     * @notice Get user level according to constant distribution. Max value: 65535
     * `user` Address of user
    **/
    function getLevel(address user) external view returns ( uint16 );

    /**
     * @notice Add or remove new admin
     * `isAdmin` Address of admin
    **/
    function setAdmin(address admin, bool isAdmin) external;

    /**
     * @notice Set new community admin parameters
     * `admin` Address of admin
     * `xpLimit` The amount of XP that admin can distribute over other users
     * `levelLimit` Admins can't distribute tokens so that (user level >= levelLimit)
    **/
    function setCommunityAdmin(address admin, uint256 xpLimit, uint16 levelLimit) external;

    /**
     * @notice Admin can give xp points to user
     * `user` Address of user
     * `xp` The amount of XP that admin want to give user (xp <= admin.xpLimit && levelAfter(user) <= admin.levelLimit)
    **/
    function distributeXp(address user, uint256 xp) external;

    /**
     * @notice Get user allocation
     * `user` Address of user
    **/
    function getAllocation(address user) external view returns ( uint256 );

    /**
     * @notice Get user bonus reward for donation
     * `user` Address of user
    **/
    function getBonus(address user) external view returns ( uint256 );

    /**
     * @notice Get nft allocation
     * `user` Address of user
    **/
    function getNftAllocation(address nft) external view returns ( uint256 );

    /**
     * @notice Get nft bonus reward for donation
     * `user` Address of nft
    **/
    function getNftBonus(address nft) external view returns ( uint256 );

    function isTokenTransferable(address nft, address from, address to, uint256 tokenId) external view returns (bool);
}

// SPDX-License-Identifier: BSL 1.1

pragma solidity >=0.7.6;

import "../interfaces/ISuAccessControl.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

/**
 * @title SuAuthenticated
 * @dev other contracts should inherit to be authenticated
 */
abstract contract SuAccessControlAuthenticated is Initializable, ISuAccessControl, ContextUpgradeable {
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 public constant DAO_ROLE = 0x00;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant COMMUNITY_ADMIN_ROLE = keccak256("COMMUNITY_ADMIN_ROLE");

    /// @dev the address of SuAccessControlSingleton - it should be one for all contract that inherits SuAuthenticated
    ISuAccessControl public ACCESS_CONTROL_SINGLETON;

    error OnlyRoleError(bytes32 role, address msgSender);

    /// @dev should be passed in constructor
    function __SuAuthenticated_init(address _accessControlSingleton) internal onlyInitializing {
        ACCESS_CONTROL_SINGLETON = ISuAccessControl(_accessControlSingleton);
    }

    modifier onlyRole(bytes32 role) {
        if (!hasRole(role, msg.sender)) revert OnlyRoleError(role, msg.sender);
        _;
    }

    function hasRole(bytes32 role, address account) public view virtual returns (bool) {
        return ACCESS_CONTROL_SINGLETON.hasRole(role, account);
    }

    function getRoleAdmin(bytes32 role) public view virtual returns (bytes32) {
        return ACCESS_CONTROL_SINGLETON.getRoleAdmin(role);
    }


    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return ACCESS_CONTROL_SINGLETON.supportsInterface(interfaceId);
    }
    //============================interfaces sugar============================


    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
pragma solidity >=0.7.6;

/**
 * @dev External interface of oz AccessControl and ERC165 detection, need to help to resolve circle dependency.
 */
interface ISuAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

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