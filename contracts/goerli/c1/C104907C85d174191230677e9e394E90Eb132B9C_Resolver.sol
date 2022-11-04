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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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

error ZeroAddressNotAllowed();

/// @title IResolver
/// @author Chain Labs
/// @notice Interface of Resolver contract
interface IResolver {
    function calculateFee(uint256 _schmintExecuted, address _owner)
        external
        view
        returns (uint256 _fee, address _feeReceiver);

    function isActive() external view returns (bool);

    function ops() external view returns (address);

    function setupInputResolver()
        external
        view
        returns (
            address,
            address,
            address,
            address
        );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "./ResolverStorage.sol";
import "./IResolver.sol";

/// @title Resolver
/// @author Chain Labs
/// @notice Resolver that helps store necessary state variables that are shared across schedulers
contract Resolver is OwnableUpgradeable, ResolverStorage {
    /// @notice initialize contract
    /// @dev using it to support resolver address
    /// @param _fee fee per schmint
    /// @param _complimentarySchmints complimentary number of schmints per scheduler
    /// @param _simplrController simplr controller address
    /// @param _simplrFeeReceiver simplr fee receiver address
    /// @param _seat Simplr Early Access Token address
    /// @param _ops gelato's OPS address
    /// @param _safeFactory gnosis safe factory address
    /// @param _singleton gnosis safe singleton address
    /// @param _fallbackHandler default fall back handler
    function initialize(
        uint256 _fee,
        uint256 _complimentarySchmints,
        address _simplrController,
        address payable _simplrFeeReceiver,
        address _seat,
        address _ops,
        address _safeFactory,
        address _singleton,
        address _fallbackHandler
    ) external initializer {
        if (
            _simplrController == address(0) ||
            _simplrFeeReceiver == address(0) ||
            _ops == address(0) ||
            _safeFactory == address(0) ||
            _singleton == address(0) ||
            _fallbackHandler == address(0)
        ) {
            revert ZeroAddressNotAllowed();
        }

        __Ownable_init();
        isActive = true;
        fee = _fee;
        complimentarySchmints = _complimentarySchmints;
        simplrController = _simplrController;
        simplrFeeReceiver = _simplrFeeReceiver;
        seat = _seat;
        ops = _ops;
        safeFactory = _safeFactory;
        singleton = _singleton;
        fallbackHandler = _fallbackHandler;
    }

    /// @notice get inputs for setup of scheduler
    /// @return _ops address of gelato's OPs
    /// @return _safeFactory address of gnosis safe factory
    /// @return _singleton address of gnosis safe singleton address
    /// @return _fallbackHandler address of default fallback handler
    function setupInputResolver()
        external
        view
        returns (
            address _ops,
            address _safeFactory,
            address _singleton,
            address _fallbackHandler
        )
    {
        return (ops, safeFactory, singleton, fallbackHandler);
    }

    /// @notice calculate schmint fee to be transferred to simplr
    /// @param _schmintExecuted number of schmints already executed
    /// @param _owner address of owner of scheduler, to check if the owner holds seat or not
    /// @return _fee amount of fee to be transferred
    /// @return _feeReceiver address of fee receiver
    function calculateFee(uint256 _schmintExecuted, address _owner)
        external
        view
        returns (uint256 _fee, address _feeReceiver)
    {
        // check if seat exists and owner holds seat
        if (
            seat != address(0) && IERC721Upgradeable(seat).balanceOf(_owner) > 0
        ) {
            // if owner holds seat, charge no fee
            return (0, address(0));
        }
        // check if executed schmint is under complimentary schmints
        if (_schmintExecuted <= complimentarySchmints) {
            // if under complimentary schmints, charge no fee
            return (0, address(0));
        }
        // charge flat fee
        return (fee, simplrFeeReceiver);
    }

    /// @notice acitvate/deactivate schmint system
    /// @param _isActive true - activate schmint || false - deactivate schmint
    function toggleActivation(bool _isActive) external onlyOwner {
        isActive = _isActive;
        emit ActivationToggled(_isActive);
    }

    /// @notice set new fee
    /// @dev only owner can invoke
    /// @param _newFee new fee
    function setFee(uint256 _newFee) external onlyOwner {
        fee = _newFee;
        emit SchmintFeeUpdated(_newFee);
    }

    /// @notice set new limit of complimentary executed schmints
    /// @dev only owner can invoke
    /// @param _newComplimentarySchmints new number of complimentary executed schmints
    function setComplimentarySchmints(uint256 _newComplimentarySchmints)
        external
        onlyOwner
    {
        complimentarySchmints = _newComplimentarySchmints;
        emit ComplimentarySchmintUpdated(_newComplimentarySchmints);
    }

    /// @notice set new address of simplr controller
    /// @dev only owner can invoke
    /// @param _newSimplrController new simplr controller address
    function setSimplrController(address _newSimplrController)
        external
        onlyOwner
    {
        simplrController = _newSimplrController;
        emit SimplrControllerUpdated(_newSimplrController);
    }

    /// @notice set new simplr fee receiver
    /// @dev only owner can invoke
    /// @param _newSimplrFeeReceiver new simplr fee receiver
    function setSimplrFeeReceiver(address payable _newSimplrFeeReceiver)
        external
        onlyOwner
    {
        simplrFeeReceiver = _newSimplrFeeReceiver;
        emit SimplrFeeReceiverUpdated(_newSimplrFeeReceiver);
    }

    /// @notice set new SEAT address
    /// @dev only owner can invoke
    /// @param _seat new simplr early access token
    function setSeat(address _seat) external onlyOwner {
        seat = _seat;
        emit SeatUpdated(_seat);
    }

    /// @notice set new OPs address
    /// @dev only owner can invoke
    /// @param _ops new OPs address
    function setOps(address _ops) external onlyOwner {
        ops = _ops;
        emit OPsUpdated(_ops);
    }

    /// @notice set new gnosis safe factory address
    /// @dev only owner can invoke
    /// @param _safeFactory new safe factory address
    function setSafeFactory(address _safeFactory) external onlyOwner {
        safeFactory = _safeFactory;
        emit SafeFactoryUpdated(_safeFactory);
    }

    /// @notice set new gnosis safe singleton address
    /// @dev only owner can invoke
    /// @param _singleton new gnosis safe singleton address
    function setSingleton(address _singleton) external onlyOwner {
        singleton = _singleton;
        emit SafeSingletonUpdated(_singleton);
    }

    /// @notice set new default fallback handler
    /// @dev only owner can invoke
    /// @param _fallbackHandler new default fallback handler
    function setFallbackHandler(address _fallbackHandler) external onlyOwner {
        fallbackHandler = _fallbackHandler;
        emit DefaultCallbackHandlerUpdated(_fallbackHandler);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title ResolverStorage
/// @author Chain Labs
/// @notice Storage contract of Resolver to support upgradeablity
contract ResolverStorage {
    /// @notice logs the activation status of resolver
    /// @dev emitted when schmint activation state is changed
    /// @param _isActive state of schminting
    event ActivationToggled(bool _isActive);

    /// @notice logs the new schminting fee
    /// @dev emitted when the schmint fee is updated
    /// @param _newFee new schminting fee
    event SchmintFeeUpdated(uint256 _newFee);

    /// @notice logs new complimentary schmints allowed per scheduler
    /// @dev emitted when number of complimentary schmints is updated
    /// @param _newComplimentarySchmints number of complimentary schmint
    event ComplimentarySchmintUpdated(uint256 _newComplimentarySchmints);

    /// @notice logs new simplr controller address
    /// @dev emitted when simplr controller address is updated
    /// @param _newSimplrController new simplr controller address
    event SimplrControllerUpdated(address indexed _newSimplrController);
    
    /// @notice logs new simplr fee receiver address
    /// @dev emitted when simplr fee receiver is updated
    /// @param _newSimplrFeeReceiver new simplr fee receiver
    event SimplrFeeReceiverUpdated(address indexed _newSimplrFeeReceiver);

    /// @notice logs new seat address
    /// @dev emitted when seat address is updated
    /// @param _seat new seat address
    event SeatUpdated(address indexed _seat);

    /// @notice logs new ops address
    /// @dev emitted when ops address is updated
    /// @param _ops new ops address
    event OPsUpdated(address indexed _ops);

    /// @notice logs new safe factory address
    /// @dev emitted when safe factory address is updated
    /// @param _safeFactory new safe factory address
    event SafeFactoryUpdated(address indexed _safeFactory);

    /// @notice logs new safe singleton address
    /// @dev emitted when safe singleton address is updated
    /// @param _singleton new safe singleton address
    event SafeSingletonUpdated(address indexed _singleton);

    /// @notice logs new default fallback handler
    /// @dev emitted when default fall back handler is updated
    /// @param _fallbackHandler new default fall back handler address
    event DefaultCallbackHandlerUpdated(address indexed _fallbackHandler);

    /// @notice fee charged per successful schmint
    /// @return fee amount
    uint256 public fee;

    /// @notice address of simplr controller multi-sg
    /// @return simplr controller address
    address public simplrController;

    /// @notice address of simplr fee receiver multi-sig
    /// @return simplr fee receiver address
    address payable public simplrFeeReceiver;

    /// @notice address of simplr early access token
    /// @return seat address
    address public seat;

    /// @notice address of gelato's OPs
    /// @return ops address
    address public ops;

    /// @notice address of gnosis safe factory
    /// @return gnosis safe factory
    address public safeFactory;

    /// @notice address of gnosis safe singleton
    /// @return gnosis safe singleton address
    address public singleton;

    /// @notice address of default fallback handler
    /// @return fallbackHandler default fallback handler address
    address public fallbackHandler;

    /// @notice checks if the schminting active or not
    /// @return isActive flag that shows if the schminting is active or not
    bool public isActive; // is the schminting allowed or not

    /// @notice number of complimentary schmints allowed per scheduler
    /// @return complimentarySchmints number of complimentary schmints allowed per scheduler
    uint256 public complimentarySchmints;

    // upgradeable safe guard
    uint256[50] private __gap;
}