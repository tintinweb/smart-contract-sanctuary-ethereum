// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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
    uint256[49] private __gap;
}

contract NFTCustomRulesV1 is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    enum ClubFlag {
        COMMON,
        CUSTOM
    }

    mapping(uint256 => ClubFlag) clubFlags;
    mapping(address => bool) commonNFTWhitelist;
    mapping(uint256 => mapping(address => bool)) customNFTWhitelist;
    mapping(address => bool) addressBlacklist;
    mapping(address => mapping(uint256 => bool)) tokenIdBlacklist;

    address[] private commonNFTs;
    address[] private addressBlack;
    mapping(uint256 => address[]) private customNFTs;
    mapping(address => uint256[]) private tokenIdBlacks;
    
    function initialize() external initializer {
        commonNFTWhitelist[address(0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB)] = true;
        commonNFTWhitelist[address(0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D)] = true;
        commonNFTWhitelist[address(0x60E4d786628Fea6478F785A6d7e704777c86a7c6)] = true;
        commonNFTWhitelist[address(0x49cF6f5d44E70224e2E23fDcdd2C053F30aDA28B)] = true;
        commonNFTWhitelist[address(0x23581767a106ae21c074b2276D25e5C3e136a68b)] = true;
        commonNFTWhitelist[address(0xED5AF388653567Af2F388E6224dC7C4b3241C544)] = true;
        commonNFTWhitelist[address(0x8a90CAb2b38dba80c64b7734e58Ee1dB38B8992e)] = true;
        commonNFTWhitelist[address(0xbCe3781ae7Ca1a5e050Bd9C4c77369867eBc307e)] = true;
        commonNFTWhitelist[address(0x7Bd29408f11D2bFC23c34f18275bBf23bB716Bc7)] = true;
        commonNFTWhitelist[address(0x7D8820FA92EB1584636f4F5b8515B5476B75171a)] = true;
        commonNFTWhitelist[address(0x79FCDEF22feeD20eDDacbB2587640e45491b757f)] = true;
        commonNFTWhitelist[address(0x6728d91abACdbac2f326baa384513a523C21b80a)] = true;
        commonNFTWhitelist[address(0xd3605059c3cE9fACf625Fa72D727508B7b7F280F)] = true;
        commonNFTWhitelist[address(0x1A92f7381B9F03921564a437210bB9396471050C)] = true;
        commonNFTWhitelist[address(0x306b1ea3ecdf94aB739F1910bbda052Ed4A9f949)] = true;
        commonNFTWhitelist[address(0xe785E82358879F061BC3dcAC6f0444462D4b5330)] = true;
        commonNFTWhitelist[address(0x75E95ba5997Eb235F40eCF8347cDb11F18ff640B)] = true;
        commonNFTWhitelist[address(0x248139aFB8d3A2e16154FbE4Fb528A3a214fd8E7)] = true;
        commonNFTWhitelist[address(0xdeDf88899D7c9025F19C6c9F188DEb98D49CD760)] = true;
        commonNFTWhitelist[address(0x19b86299c21505cdf59cE63740B240A9C822b5E4)] = true;
        commonNFTWhitelist[address(0x80336Ad7A747236ef41F47ed2C7641828a480BAA)] = true;
        commonNFTWhitelist[address(0xcAACE84B015330C0Ab4BD003F6fa0B84ec6C64ac)] = true;
        commonNFTWhitelist[address(0xCa7cA7BcC765F77339bE2d648BA53ce9c8a262bD)] = true;
        commonNFTWhitelist[address(0x960b7a6BCD451c9968473f7bbFd9Be826EFd549A)] = true;
        commonNFTWhitelist[address(0x57a204AA1042f6E66DD7730813f4024114d74f37)] = true;
        commonNFTWhitelist[address(0x2acAb3DEa77832C09420663b0E1cB386031bA17B)] = true;
        commonNFTWhitelist[address(0x0c2E57EFddbA8c768147D1fdF9176a0A6EBd5d83)] = true;
        commonNFTWhitelist[address(0xf61F24c2d93bF2dE187546B14425BF631F28d6dC)] = true;
        commonNFTWhitelist[address(0x160C404B2b49CBC3240055CEaEE026df1e8497A0)] = true;
        commonNFTWhitelist[address(0x123b30E25973FeCd8354dd5f41Cc45A3065eF88C)] = true;
        commonNFTWhitelist[address(0x1CB1A5e65610AEFF2551A50f76a87a7d3fB649C6)] = true;
        commonNFTWhitelist[address(0xb4d06d46A8285F4EC79Fd294F78a881799d8cEd9)] = true;
        commonNFTWhitelist[address(0x40Cf6a63C35B6886421988871F6b74cC86309940)] = true;
        commonNFTWhitelist[address(0x4Db1f25D3d98600140dfc18dEb7515Be5Bd293Af)] = true;
        commonNFTWhitelist[address(0xaaD35C2DadbE77f97301617D82e661776c891Fa9)] = true;
        commonNFTWhitelist[address(0xfE8C6d19365453D26af321D0e8c910428c23873F)] = true;
        commonNFTWhitelist[address(0x9df8Aa7C681f33E442A0d57B838555da863504f3)] = true;
        commonNFTWhitelist[address(0xC1ad47aeb274157E24A5f01B5857830aeF962843)] = true;
        commonNFTWhitelist[address(0x3903d4fFaAa700b62578a66e7a67Ba4cb67787f9)] = true;
        commonNFTWhitelist[address(0xa5C0Bd78D1667c13BFB403E2a3336871396713c5)] = true;
        commonNFTWhitelist[address(0xF4Eac65bbC94E3bE2E3674992c31781032a6d793)] = true;
        commonNFTWhitelist[address(0x09233d553058c2F42ba751C87816a8E9FaE7Ef10)] = true;
        commonNFTWhitelist[address(0x582048C4077a34E7c3799962F1F8C5342a3F4b12)] = true;
        commonNFTWhitelist[address(0x9a38DEC0590aBC8c883d72E52391090e948DdF12)] = true;
        commonNFTWhitelist[address(0xDA60730E1feAa7D8321f62fFb069eDd869E57D02)] = true;
        commonNFTWhitelist[address(0x7AB2352b1D2e185560494D5e577F9D3c238b78C5)] = true;
        commonNFTWhitelist[address(0x8d609Bd201bEaea7DccbfbD9c22851e23Da68691)] = true;
        commonNFTWhitelist[address(0xBd3531dA5CF5857e7CfAA92426877b022e612cf8)] = true;
        commonNFTWhitelist[address(0x684E4ED51D350b4d76A3a07864dF572D24e6dC4c)] = true;
        commonNFTWhitelist[address(0x5a0121A0A21232eC0D024dAb9017314509026480)] = true;
        commonNFTWhitelist[address(0x42069ABFE407C60cf4ae4112bEDEaD391dBa1cdB)] = true;
        commonNFTWhitelist[address(0xc99c679C50033Bbc5321EB88752E89a93e9e83C5)] = true;
        commonNFTWhitelist[address(0xd1258DB6Ac08eB0e625B75b371C023dA478E94A9)] = true;
        commonNFTWhitelist[address(0x845a007D9f283614f403A24E3eB3455f720559ca)] = true;
        commonNFTWhitelist[address(0x3A2C64e82f31E70aaf02849bc1e0952A610b95F3)] = true;
        commonNFTWhitelist[address(0xE405EA33148a2b6FCbA3125b469dF87229a08d5A)] = true;
        commonNFTWhitelist[address(0xa3AEe8BcE55BEeA1951EF834b99f3Ac60d1ABeeB)] = true;
        commonNFTWhitelist[address(0xCcc441ac31f02cD96C153DB6fd5Fe0a2F4e6A68d)] = true;
        commonNFTWhitelist[address(0x6EFc003D3F3658383F06185503340C2Cf27A57b6)] = true;
        commonNFTWhitelist[address(0x6FEFb647395e680339bADC84dC774E3CA8bCA7B9)] = true;
        commonNFTWhitelist[address(0x39223e2596bF8E1dE3894f66947cacc614C24A2f)] = true;
        commonNFTWhitelist[address(0x3903d4fFaAa700b62578a66e7a67Ba4cb67787f9)] = true;
        commonNFTWhitelist[address(0xEdB61f74B0d09B2558F1eeb79B247c1F363Ae452)] = true;
        commonNFTWhitelist[address(0x39ee2c7b3cb80254225884ca001F57118C8f21B6)] = true;
        commonNFTWhitelist[address(0x740c178e10662bBb050BDE257bFA318dEfE3cabC)] = true;
        commonNFTWhitelist[address(0xba30E5F9Bb24caa003E9f2f0497Ad287FDF95623)] = true;
        commonNFTWhitelist[address(0x9378368ba6b85c1FbA5b131b530f5F5bEdf21A18)] = true;
        commonNFTWhitelist[address(0xc5B52253f5225835cc81C52cdb3d6A22bc3B0c93)] = true;
        commonNFTWhitelist[address(0xF24Bf668Aa087990f1d40aBAbF841456E771913c)] = true;
        commonNFTWhitelist[address(0x59468516a8259058baD1cA5F8f4BFF190d30E066)] = true;
        commonNFTWhitelist[address(0xB852c6b5892256C264Cc2C888eA462189154D8d7)] = true;
        commonNFTWhitelist[address(0xa0DcF49D64dC1Ff060B8A5a6138B758c00B43e26)] = true;
        commonNFTWhitelist[address(0x249aeAa7fA06a63Ea5389b72217476db881294df)] = true;
        commonNFTWhitelist[address(0x4Ef3D9EaB34783995bc394d569845585aC805Ef8)] = true;
        commonNFTWhitelist[address(0xe21EBCD28d37A67757B9Bc7b290f4C4928A430b1)] = true;
        commonNFTWhitelist[address(0xE6d48bF4ee912235398b96E16Db6F310c21e82CB)] = true;
        commonNFTWhitelist[address(0x2a48420D75777aF4c99970C0ED3C25effD1C08be)] = true;
        commonNFTWhitelist[address(0x2b9FD4D651414e51c9bA56aE1add36bb71cCa24B)] = true;
        commonNFTWhitelist[address(0x1485297e942ce64E0870EcE60179dFda34b4C625)] = true;
        commonNFTWhitelist[address(0x705B9DBD0D5607BEAFe12E2fB74d64268d3bA35F)] = true;
        commonNFTWhitelist[address(0x32dDbb0fC65BB53E1f7D6Dc1c2a713e9A695B75b)] = true;
        commonNFTWhitelist[address(0x394E3d3044fC89fCDd966D3cb35Ac0B32B0Cda91)] = true;
        commonNFTWhitelist[address(0xaCF63E56fd08970b43401492a02F6F38B6635C91)] = true;
        commonNFTWhitelist[address(0xFFc1131dDA0299b804C97c436bC8cFeA019e00a0)] = true;
        commonNFTWhitelist[address(0x1254F3c0968ef1adA5D2ee32f1A047f2D51f1e4A)] = true;
        commonNFTWhitelist[address(0x0825F050E9B021A0E9de8CB1fb10b6C9F41e834C)] = true;
        commonNFTWhitelist[address(0x809D8f2B12454FC07408d2479cf6DC701ecD5a9f)] = true;
        commonNFTWhitelist[address(0xCcc441ac31f02cD96C153DB6fd5Fe0a2F4e6A68d)] = true;

        __Ownable_init();
        __ReentrancyGuard_init();
    }

    function setNewClubInfo(uint256 _targetClubNum, ClubFlag _flag, address[] memory _customWhitelist, bool[] memory _status) public onlyOwner {
        clubFlags[_targetClubNum] = _flag;
        if (_flag == ClubFlag.CUSTOM) {
            for(uint256 i; i < _customWhitelist.length; i++) {
                customNFTWhitelist[_targetClubNum][_customWhitelist[i]] = _status[i];
                if (_status[i]) {
                    customNFTs[_targetClubNum].push(_customWhitelist[i]);
                }
            }
        }
    }

    function setNewClubInfos(uint256[] memory _targetClubNums, ClubFlag[] memory _flags, address[][] memory _customWhitelists, bool[][] memory _statuses) external onlyOwner {
        for(uint256 i; i < _targetClubNums.length; i++) {
            setNewClubInfo(_targetClubNums[i], _flags[i], _customWhitelists[i], _statuses[i]);
        }
    }

    function setCommonWhitelist(address[] memory _commonWhitelist, bool[] memory _status) external onlyOwner {
        for(uint256 i; i < _commonWhitelist.length; i++) {
            commonNFTWhitelist[_commonWhitelist[i]] = _status[i];
            if ( _status[i]) {
                commonNFTs.push(_commonWhitelist[i]);
            }
        }
    }

    function setAddrBlacklist(address[] memory _blacklist, bool[] memory _status) external onlyOwner {
        for(uint256 i; i < _blacklist.length; i++) {
            addressBlacklist[_blacklist[i]] = _status[i];
            if ( _status[i]) {
                addressBlack.push(_blacklist[i]);
            }
        }
    }

    function setTokenIdBlacklist(address[] memory _nfts, uint256[] memory _tokenIds, bool[] memory _status) external onlyOwner {
        for(uint256 i; i < _nfts.length; i++) {
            tokenIdBlacklist[_nfts[i]][_tokenIds[i]] = _status[i];
            if ( _status[i]) {
                tokenIdBlacks[_nfts[i]].push(_tokenIds[i]);
            }
        }
    }

    function getCommonNFTs() public view returns(address[] memory){
        return commonNFTs;
    }

    function getAddressBlack() public view returns(address[] memory){
        return addressBlack;
    }

    function getCustomNFTs(uint256 _targetClubNum) public view returns(address[] memory){
        return customNFTs[_targetClubNum];
    }

    function getTokenIdBlacks(address _nfts) public view returns(uint256[] memory){
        return tokenIdBlacks[_nfts];
    }

    function isAllowedJoin(address _account, uint256 _targetClubNum, bytes memory _condition) external view returns(bool, string memory) {
        if (addressBlacklist[_account]) {
            return (false, "NFTCustomRulesV1: Account is banned");
        }

        (address _targetNFT, uint256 _tokenId) = abi.decode(_condition, (address, uint256));

        if (tokenIdBlacklist[_targetNFT][_tokenId]) {
            return (false, "NFTCustomRulesV1: TokenId is banned");
        }

        if (IERC721(_targetNFT).ownerOf(_tokenId) != _account) {
            return (false, "NFTCustomRulesV1: TargetNFT Does Not Belong to User");
        }

        if (clubFlags[_targetClubNum] == ClubFlag.CUSTOM && !customNFTWhitelist[_targetClubNum][_targetNFT]) {
            return (false, "NFTCustomRulesV1: (Custom) TargetNFT Not Allowed");
        } else if (clubFlags[_targetClubNum] == ClubFlag.COMMON && !commonNFTWhitelist[_targetNFT]) {
            return (false, "NFTCustomRulesV1: (Common) TargetNFT Not Allowed");
        }
        
        return (true, "");
    }

    function isAllowedBounty(address _account, uint256 _targetClubNum) external view returns(bool, string memory) {
        _targetClubNum;

        if (addressBlacklist[_account]) {
            return (false, "NFTCustomRulesV1: Account is banned");
        }

        return (true, "");
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}