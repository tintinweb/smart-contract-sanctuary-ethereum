/**
 *Submitted for verification at Etherscan.io on 2023-03-06
*/

// SPDX-License-Identifier: MIT
//
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        ██████████████                                        ██████████████
//        ██████████████          ▄▄████████████████▄▄         ▐█████████████▌
//        ██████████████    ▄█████████████████████████████▄    ██████████████
//         ██████████▀   ▄█████████████████████████████████   ██████████████▌
//          ██████▀   ▄██████████████████████████████████▀  ▄███████████████
//           ███▀   ██████████████████████████████████▀   ▄████████████████
//            ▀▀  ████████████████████████████████▀▀   ▄█████████████████▌
//              █████████████████████▀▀▀▀▀▀▀      ▄▄███████████████████▀
//             ██████████████████▀    ▄▄▄█████████████████████████████▀
//            ████████████████▀   ▄█████████████████████████████████▀  ██▄
//          ▐███████████████▀  ▄██████████████████████████████████▀   █████▄
//          ██████████████▀  ▄█████████████████████████████████▀   ▄████████
//         ██████████████▀   ███████████████████████████████▀   ▄████████████
//        ▐█████████████▌     ▀▀▀▀████████████████████▀▀▀▀      █████████████▌
//        ██████████████                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████

pragma solidity ^0.8.10;

// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
}

// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
        bool isTopLevelCall = _setInitializedVersion(1);
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
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !Address.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

// OpenZeppelin Contracts v4.4.1 (utils/Create2.sol)

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(
        uint256 amount,
        bytes32 salt,
        bytes memory bytecode
    ) internal returns (address) {
        address addr;
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
        return addr;
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(
        bytes32 salt,
        bytes32 bytecodeHash,
        address deployer
    ) internal pure returns (address) {
        bytes32 _data = keccak256(abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash));
        return address(uint160(uint256(_data)));
    }
}

//
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        ██████████████                                        ██████████████
//        ██████████████          ▄▄████████████████▄▄         ▐█████████████▌
//        ██████████████    ▄█████████████████████████████▄    ██████████████
//         ██████████▀   ▄█████████████████████████████████   ██████████████▌
//          ██████▀   ▄██████████████████████████████████▀  ▄███████████████
//           ███▀   ██████████████████████████████████▀   ▄████████████████
//            ▀▀  ████████████████████████████████▀▀   ▄█████████████████▌
//              █████████████████████▀▀▀▀▀▀▀      ▄▄███████████████████▀
//             ██████████████████▀    ▄▄▄█████████████████████████████▀
//            ████████████████▀   ▄█████████████████████████████████▀  ██▄
//          ▐███████████████▀  ▄██████████████████████████████████▀   █████▄
//          ██████████████▀  ▄█████████████████████████████████▀   ▄████████
//         ██████████████▀   ███████████████████████████████▀   ▄████████████
//        ▐█████████████▌     ▀▀▀▀████████████████████▀▀▀▀      █████████████▌
//        ██████████████                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████

//
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        ██████████████                                        ██████████████
//        ██████████████          ▄▄████████████████▄▄         ▐█████████████▌
//        ██████████████    ▄█████████████████████████████▄    ██████████████
//         ██████████▀   ▄█████████████████████████████████   ██████████████▌
//          ██████▀   ▄██████████████████████████████████▀  ▄███████████████
//           ███▀   ██████████████████████████████████▀   ▄████████████████
//            ▀▀  ████████████████████████████████▀▀   ▄█████████████████▌
//              █████████████████████▀▀▀▀▀▀▀      ▄▄███████████████████▀
//             ██████████████████▀    ▄▄▄█████████████████████████████▀
//            ████████████████▀   ▄█████████████████████████████████▀  ██▄
//          ▐███████████████▀  ▄██████████████████████████████████▀   █████▄
//          ██████████████▀  ▄█████████████████████████████████▀   ▄████████
//         ██████████████▀   ███████████████████████████████▀   ▄████████████
//        ▐█████████████▌     ▀▀▀▀████████████████████▀▀▀▀      █████████████▌
//        ██████████████                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████

/// @dev A library for validating signatures from ZeroEx
library Signatures {
  /// @dev Allowed signature types.
  enum SignatureType {
    EIP712
  }

  /// @dev Encoded EC signature.
  struct Signature {
    // How to validate the signature.
    SignatureType signatureType;
    // EC Signature data.
    uint8 v;
    // EC Signature data.
    bytes32 r;
    // EC Signature data.
    bytes32 s;
  }
}

library Entitlements {
  uint256 private constant _ENTITLEMENT_TYPEHASH =
    uint256(
      keccak256(
        abi.encodePacked(
          "Entitlement(",
          "address beneficialOwner,",
          "address operator,",
          "address vaultAddress,",
          "uint32 assetId,",
          "uint32 expiry",
          ")"
        )
      )
    );

  /// ---- STRUCTS -----
  struct Entitlement {
    /// @notice the beneficial owner address this entitlement applies to. This address will also be the signer.
    address beneficialOwner;
    /// @notice the operating contract that can change ownership during the entitlement period.
    address operator;
    /// @notice the contract address for the vault that contains the underlying assets
    address vaultAddress;
    /// @notice the assetId of the asset or assets within the vault
    uint32 assetId;
    /// @notice the block timestamp after which the asset is free of the entitlement
    uint32 expiry;
  }

  function getEntitlementStructHash(Entitlement memory entitlement)
    internal
    pure
    returns (bytes32)
  {
    // TODO: Hash in place to save gas.
    return
      keccak256(
        abi.encode(
          _ENTITLEMENT_TYPEHASH,
          entitlement.beneficialOwner,
          entitlement.operator,
          entitlement.vaultAddress,
          entitlement.assetId,
          entitlement.expiry
        )
      );
  }
}

//
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        ██████████████                                        ██████████████
//        ██████████████          ▄▄████████████████▄▄         ▐█████████████▌
//        ██████████████    ▄█████████████████████████████▄    ██████████████
//         ██████████▀   ▄█████████████████████████████████   ██████████████▌
//          ██████▀   ▄██████████████████████████████████▀  ▄███████████████
//           ███▀   ██████████████████████████████████▀   ▄████████████████
//            ▀▀  ████████████████████████████████▀▀   ▄█████████████████▌
//              █████████████████████▀▀▀▀▀▀▀      ▄▄███████████████████▀
//             ██████████████████▀    ▄▄▄█████████████████████████████▀
//            ████████████████▀   ▄█████████████████████████████████▀  ██▄
//          ▐███████████████▀  ▄██████████████████████████████████▀   █████▄
//          ██████████████▀  ▄█████████████████████████████████▀   ▄████████
//         ██████████████▀   ███████████████████████████████▀   ▄████████████
//        ▐█████████████▌     ▀▀▀▀████████████████████▀▀▀▀      █████████████▌
//        ██████████████                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████

// Modified version of : OpenZeppelin Contracts v4.4.1 (proxy/beacon/BeaconProxy.sol)

// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

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
     * This function does not return to its internal call site, it will return directly to the external caller.
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
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
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
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

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

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

/// @title HookBeaconProxy a proxy contract that points to an implementation provided by a Beacon
/// @dev This contract implements a proxy that gets the implementation address for each call from a {UpgradeableBeacon}.
///
/// The beacon address is stored in storage slot `uint256(keccak256('eip1967.proxy.beacon')) - 1`, so that it doesn't
/// conflict with the storage layout of the implementation behind the proxy.
///
/// This is an extension of the OpenZeppelin beacon proxy, however differs in that it is initializeable, which means
/// it is usable with Create2.
contract HookBeaconProxy is Proxy, ERC1967Upgrade {
  /// @dev  The constructor is empty in this case because the proxy is initializeable
  constructor() {}

  bytes32 constant _INITIALIZED_SLOT =
    bytes32(uint256(keccak256("initializeable.beacon.version")) - 1);
  bytes32 constant _INITIALIZING_SLOT =
    bytes32(uint256(keccak256("initializeable.beacon.initializing")) - 1);

  ///
  /// @dev Triggered when the contract has been initialized or reinitialized.
  ///
  event Initialized(uint8 version);

  /// @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
  /// `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
  modifier initializer() {
    bool isTopLevelCall = _setInitializedVersion(1);
    if (isTopLevelCall) {
      StorageSlot.getBooleanSlot(_INITIALIZING_SLOT).value = true;
    }
    _;
    if (isTopLevelCall) {
      StorageSlot.getBooleanSlot(_INITIALIZING_SLOT).value = false;
      emit Initialized(1);
    }
  }

  function _setInitializedVersion(uint8 version) private returns (bool) {
    // If the contract is initializing we ignore whether _initialized is set in order to support multiple
    // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
    // of initializers, because in other contexts the contract may have been reentered.
    if (StorageSlot.getBooleanSlot(_INITIALIZING_SLOT).value) {
      require(
        version == 1 && !Address.isContract(address(this)),
        "contract is already initialized"
      );
      return false;
    } else {
      require(
        StorageSlot.getUint256Slot(_INITIALIZED_SLOT).value < version,
        "contract is already initialized"
      );
      StorageSlot.getUint256Slot(_INITIALIZED_SLOT).value = version;
      return true;
    }
  }

  /// @dev Initializes the proxy with `beacon`.
  ///
  /// If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon. This
  /// will typically be an encoded function call, and allows initializing the storage of the proxy like a Solidity
  /// constructor.
  ///
  /// Requirements:
  ///
  ///- `beacon` must be a contract with the interface {IBeacon}.
  ///
  function initializeBeacon(address beacon, bytes memory data)
    public
    initializer
  {
    assert(
      _BEACON_SLOT == bytes32(uint256(keccak256("eip1967.proxy.beacon")) - 1)
    );
    _upgradeBeaconToAndCall(beacon, data, false);
  }

  ///
  /// @dev Returns the current implementation address of the associated beacon.
  ///
  function _implementation() internal view virtual override returns (address) {
    return IBeacon(_getBeacon()).implementation();
  }
}

library BeaconSalts {
  // keep functions internal to prevent the need for library linking
  // and to reduce gas costs
  bytes32 internal constant ByteCodeHash =
    bytes32(0x9efc74de3a03a3f44d619e7f315880536876e16273d5fdee7b22fd4c1620f1d5);

  function soloVaultSalt(address nftAddress, uint256 tokenId)
    internal
    pure
    returns (bytes32)
  {
    return keccak256(abi.encode(nftAddress, tokenId));
  }

  function multiVaultSalt(address nftAddress) internal pure returns (bytes32) {
    return keccak256(abi.encode(nftAddress));
  }
}

//
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        ██████████████                                        ██████████████
//        ██████████████          ▄▄████████████████▄▄         ▐█████████████▌
//        ██████████████    ▄█████████████████████████████▄    ██████████████
//         ██████████▀   ▄█████████████████████████████████   ██████████████▌
//          ██████▀   ▄██████████████████████████████████▀  ▄███████████████
//           ███▀   ██████████████████████████████████▀   ▄████████████████
//            ▀▀  ████████████████████████████████▀▀   ▄█████████████████▌
//              █████████████████████▀▀▀▀▀▀▀      ▄▄███████████████████▀
//             ██████████████████▀    ▄▄▄█████████████████████████████▀
//            ████████████████▀   ▄█████████████████████████████████▀  ██▄
//          ▐███████████████▀  ▄██████████████████████████████████▀   █████▄
//          ██████████████▀  ▄█████████████████████████████████▀   ▄████████
//         ██████████████▀   ███████████████████████████████▀   ▄████████████
//        ▐█████████████▌     ▀▀▀▀████████████████████▀▀▀▀      █████████████▌
//        ██████████████                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████

//
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        ██████████████                                        ██████████████
//        ██████████████          ▄▄████████████████▄▄         ▐█████████████▌
//        ██████████████    ▄█████████████████████████████▄    ██████████████
//         ██████████▀   ▄█████████████████████████████████   ██████████████▌
//          ██████▀   ▄██████████████████████████████████▀  ▄███████████████
//           ███▀   ██████████████████████████████████▀   ▄████████████████
//            ▀▀  ████████████████████████████████▀▀   ▄█████████████████▌
//              █████████████████████▀▀▀▀▀▀▀      ▄▄███████████████████▀
//             ██████████████████▀    ▄▄▄█████████████████████████████▀
//            ████████████████▀   ▄█████████████████████████████████▀  ██▄
//          ▐███████████████▀  ▄██████████████████████████████████▀   █████▄
//          ██████████████▀  ▄█████████████████████████████████▀   ▄████████
//         ██████████████▀   ███████████████████████████████▀   ▄████████████
//        ▐█████████████▌     ▀▀▀▀████████████████████▀▀▀▀      █████████████▌
//        ██████████████                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████

//
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        ██████████████                                        ██████████████
//        ██████████████          ▄▄████████████████▄▄         ▐█████████████▌
//        ██████████████    ▄█████████████████████████████▄    ██████████████
//         ██████████▀   ▄█████████████████████████████████   ██████████████▌
//          ██████▀   ▄██████████████████████████████████▀  ▄███████████████
//           ███▀   ██████████████████████████████████▀   ▄████████████████
//            ▀▀  ████████████████████████████████▀▀   ▄█████████████████▌
//              █████████████████████▀▀▀▀▀▀▀      ▄▄███████████████████▀
//             ██████████████████▀    ▄▄▄█████████████████████████████▀
//            ████████████████▀   ▄█████████████████████████████████▀  ██▄
//          ▐███████████████▀  ▄██████████████████████████████████▀   █████▄
//          ██████████████▀  ▄█████████████████████████████████▀   ▄████████
//         ██████████████▀   ███████████████████████████████▀   ▄████████████
//        ▐█████████████▌     ▀▀▀▀████████████████████▀▀▀▀      █████████████▌
//        ██████████████                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████

/// @title Generic Hook Vault-a vault designed to contain a single asset to be used as escrow.
/// @author Jake [email protected]
/// @custom:coauthor Regynald [email protected]
///
/// @notice The Vault holds an asset on behalf of the owner. The owner is able to post this
/// asset as collateral to other protocols by signing a message, called an "entitlement", that gives
/// a specific account the ability to change the owner.
///
/// The vault can work with multiple assets via the assetId, where the asset or set of assets covered by
/// each segment is granted an individual id.
/// Every asset must be identified by an assetId to comply with this interface, even if the vault only contains
/// one asset.
///
/// ENTITLEMENTS -
///     (1) only one entitlement can be placed at a time.
///     (2) entitlements must expire, but can also be cleared by the entitled party
///     (3) if an entitlement expires, the current beneficial owner gains immediate sole control over the
///        asset
///     (4) the entitled entity can modify the beneficial owner of the asset, but cannot withdrawal.
///     (5) the beneficial owner cannot modify the beneficial owner while an entitlement is in place
///
interface IHookVault is IERC165 {
  /// @notice emitted when an entitlement is placed on an asset
  event EntitlementImposed(
    uint32 assetId,
    address entitledAccount,
    uint32 expiry,
    address beneficialOwner
  );

  /// @notice emitted when an entitlement is cleared from an asset
  event EntitlementCleared(uint256 assetId, address beneficialOwner);

  /// @notice emitted when the beneficial owner of an asset changes
  /// @dev it is not required that this event is emitted when an entitlement is
  /// imposed that also modifies the beneficial owner.
  event BeneficialOwnerSet(
    uint32 assetId,
    address beneficialOwner,
    address setBy
  );

  /// @notice emitted when an asset is added into the vault
  event AssetReceived(
    address owner,
    address sender,
    address contractAddress,
    uint32 assetId
  );

  /// @notice Emitted when `beneficialOwner` enables `approved` to manage the `assetId` asset.
  event Approval(
    address indexed beneficialOwner,
    address indexed approved,
    uint32 indexed assetId
  );

  /// @notice emitted when an asset is withdrawn from the vault
  event AssetWithdrawn(uint32 assetId, address to, address beneficialOwner);

  /// @notice Withdrawal an unencumbered asset from this vault
  /// @param assetId the asset to remove from the vault
  function withdrawalAsset(uint32 assetId) external;

  /// @notice setBeneficialOwner updates the current address that can claim the asset when it is free of entitlements.
  /// @param assetId the id of the subject asset to impose the entitlement
  /// @param newBeneficialOwner the account of the person who is able to withdrawal when there are no entitlements.
  function setBeneficialOwner(uint32 assetId, address newBeneficialOwner)
    external;

  /// @notice Add an entitlement claim to the asset held within the contract
  /// @param operator the operator to entitle
  /// @param expiry the duration of the entitlement
  /// @param assetId the id of the asset within the vault
  /// @param v sig v
  /// @param r sig r
  /// @param s sig s
  function imposeEntitlement(
    address operator,
    uint32 expiry,
    uint32 assetId,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  /// @notice Allows the beneficial owner to grant an entitlement to an asset within the contract
  /// @dev this function call is signed by the sender per the EVM, so we know the entitlement is authentic
  /// @param entitlement The entitlement to impose onto the contract
  function grantEntitlement(Entitlements.Entitlement calldata entitlement)
    external;

  /// @notice Allows the entitled address to release their claim on the asset
  /// @param assetId the id of the asset to clear
  function clearEntitlement(uint32 assetId) external;

  /// @notice Removes the active entitlement from a vault and returns the asset to the beneficial owner
  /// @param receiver the intended receiver of the asset
  /// @param assetId the Id of the asset to clear
  function clearEntitlementAndDistribute(uint32 assetId, address receiver)
    external;

  /// @notice looks up the current beneficial owner of the asset
  /// @param assetId the referenced asset
  /// @return the address of the beneficial owner of the asset
  function getBeneficialOwner(uint32 assetId) external view returns (address);

  /// @notice checks if the asset is currently stored in the vault
  /// @param assetId the referenced asset
  /// @return true if the asset is currently within the vault, false otherwise
  function getHoldsAsset(uint32 assetId) external view returns (bool);

  /// @notice the contract address of the vaulted asset
  /// @param assetId the referenced asset
  /// @return the contract address of the vaulted asset
  function assetAddress(uint32 assetId) external view returns (address);

  /// @notice looks up the current operator of an entitlement on an asset
  /// @param assetId the id of the underlying asset
  function getCurrentEntitlementOperator(uint32 assetId)
    external
    view
    returns (bool, address);

  /// @notice Looks up the expiration timestamp of the current entitlement
  /// @dev returns the 0 if no entitlement is set
  /// @return the block timestamp after which the entitlement expires
  function entitlementExpiration(uint32 assetId) external view returns (uint32);

  /// @notice Gives permission to `to` to impose an entitlement upon `assetId`
  ///
  /// @dev Only a single account can be approved at a time, so approving the zero address clears previous approvals.
  ///   * Requirements:
  ///
  /// -  The caller must be the beneficial owner
  /// - `tokenId` must exist.
  ///
  /// Emits an {Approval} event.
  function approveOperator(address to, uint32 assetId) external;

  /// @dev Returns the account approved for `tokenId` token.
  ///
  /// Requirements:
  ///
  /// - `assetId` must exist.
  ///
  function getApprovedOperator(uint32 assetId) external view returns (address);
}

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/// @title Hook ERC-721 Vault interface
/// @author Jake [email protected]
/// @custom:coauthor Regynald [email protected]
///
/// @dev the IHookERC721 vault is an extension of the standard IHookVault
/// specifically designed to hold and receive ERC721 Tokens.
///
/// FLASH LOAN -
///     (1) beneficial owners are able to borrow the vaulted asset for a single function call
///     (2) to borrow the asset, they must implement and deploy a {IERC721FlashLoanReceiver}
///         contract, and then call the flashLoan method.
///     (3) At the end of the flashLoan, we ensure the asset is still owned by the vault.
interface IHookERC721Vault is IHookVault, IERC721Receiver {
  /// @notice emitted after an asset is flash loaned by its beneficial owner.
  /// @dev only one asset can be flash loaned at a time, and that asset is
  /// denoted by the tokenId emitted.
  event AssetFlashLoaned(address owner, uint256 tokenId, address flashLoanImpl);

  /// @notice the tokenID of the underlying ERC721 token;
  function assetTokenId(uint32 assetId) external view returns (uint256);

  /// @notice flashLoans the vaulted asset to another contract for use and return to the vault. Only the owner
  /// may perform the flashloan
  /// @dev the flashloan receiver can perform arbitrary logic, but must approve the vault as an operator
  /// before returning.
  /// @param receiverAddress the contract which implements the {IERC721FlashLoanReceiver} interface to utilize the
  /// asset while it is loaned out
  /// @param params calldata params to forward to the receiver
  function flashLoan(
    uint32 assetId,
    address receiverAddress,
    bytes calldata params
  ) external;
}

/// @title HookERC721Factory-factory for instances of the hook vault
/// @author Jake [email protected]
/// @custom:coauthor Regynald [email protected]
///
/// @notice The Factory creates a specific vault for ERC721s.
interface IHookERC721VaultFactory {
  event ERC721VaultCreated(
    address nftAddress,
    uint256 tokenId,
    address vaultAddress
  );

  /// @notice emitted when a new MultiVault is deployed by the protocol
  /// @param nftAddress the address of the nft contract that may be deposited into the new vault
  /// @param vaultAddress address of the newly deployed vault
  event ERC721MultiVaultCreated(address nftAddress, address vaultAddress);

  /// @notice gets the address of a vault for a particular ERC-721 token
  /// @param nftAddress the contract address for the ERC-721
  /// @param tokenId the tokenId for the ERC-721
  /// @return the address of a {IERC721Vault} if one exists that supports the particular ERC-721, or the null address otherwise
  function getVault(address nftAddress, uint256 tokenId)
    external
    view
    returns (IHookERC721Vault);

  /// @notice gets the address of a multi-asset vault for a particular ERC-721 contract, if one exists
  /// @param nftAddress the contract address for the ERC-721
  /// @return the address of the {IERC721Vault} multi asset vault, or the null address if one does not exist
  function getMultiVault(address nftAddress)
    external
    view
    returns (IHookERC721Vault);

  /// @notice deploy a multi-asset vault if one has not already been deployed
  /// @param nftAddress the contract address for the ERC-721 to be supported by the vault
  /// @return the address of the newly deployed {IERC721Vault} multi asset vault
  function makeMultiVault(address nftAddress)
    external
    returns (IHookERC721Vault);

  /// @notice creates a vault for a specific tokenId. If there
  /// is a multi-vault in existence which supports that address
  /// the address for that vault is returned as a new one
  /// does not need to be made.
  /// @param nftAddress the contract address for the ERC-721
  /// @param tokenId the tokenId for the ERC-721
  function findOrCreateVault(address nftAddress, uint256 tokenId)
    external
    returns (IHookERC721Vault);

  /// @notice make a new vault that can contain a single asset only
  /// @dev the only valid asset id in this vault is = 0
  /// @param nftAddress the address of the underlying nft contract
  /// @param tokenId the individual token that can be deposited into this vault
  function makeSoloVault(address nftAddress, uint256 tokenId)
    external
    returns (IHookERC721Vault);
}

//
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        ██████████████                                        ██████████████
//        ██████████████          ▄▄████████████████▄▄         ▐█████████████▌
//        ██████████████    ▄█████████████████████████████▄    ██████████████
//         ██████████▀   ▄█████████████████████████████████   ██████████████▌
//          ██████▀   ▄██████████████████████████████████▀  ▄███████████████
//           ███▀   ██████████████████████████████████▀   ▄████████████████
//            ▀▀  ████████████████████████████████▀▀   ▄█████████████████▌
//              █████████████████████▀▀▀▀▀▀▀      ▄▄███████████████████▀
//             ██████████████████▀    ▄▄▄█████████████████████████████▀
//            ████████████████▀   ▄█████████████████████████████████▀  ██▄
//          ▐███████████████▀  ▄██████████████████████████████████▀   █████▄
//          ██████████████▀  ▄█████████████████████████████████▀   ▄████████
//         ██████████████▀   ███████████████████████████████▀   ▄████████████
//        ▐█████████████▌     ▀▀▀▀████████████████████▀▀▀▀      █████████████▌
//        ██████████████                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████

// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

/// @title A covered call instrument
/// @author Jake [email protected]
/// @custom:coauthor Regynald [email protected]
///
/// @notice This contract implements a "Covered Call Option". A call option gives the holder the right, but not
/// the obligation to purchase an asset at a fixed time in the future (the expiry) for a fixed price (the strike).
///
///
/// This call option implementation here is similar to a "european" call option because the asset can
/// only be purchased at the expiration. The call option is "covered"  because the underlying
/// asset, must be held in escrow within a IHookVault for the entire duration of the option.
///
/// There are three phases to the call option:
///
/// (1) WRITING:
/// The owner of the NFT can mint an option by calling the "mint" function using the parameters of the subject ERC-721;
/// specifying additionally their preferred strike price and expiration. An "instrument nft" is minted to the writer's
/// address, where the holder of this ERC-721 will receive the economic benefit of holding the option.
///
/// (2) SALE:
/// The sale occurs outside of the context of this contract; however, the ZeroEx market contracts are pre-approved to
/// transfer the tokens. By Selling the instrument NFT, the writer earns a "premium" for selling their option. The
/// option may be sold and re-sold multiple times.
///
/// (3) SETTLEMENT:
/// One day prior to the expiration, and auction begins. People are able to call bid() for more than the strike price to
/// place a bid. If, at settlement, the high bid is greater than the strike, (b-strike) is transferred to the holder
/// of the instrument NFT, the strike price is transferred to the writer. The high bid is transferred to the holder of
/// the option.
interface IHookCoveredCall is IERC721Metadata {
  /// @notice emitted when a new call option is successfully minted with a specific underlying vault
  event CallCreated(
    address writer,
    address vaultAddress,
    uint256 assetId,
    uint256 optionId,
    uint256 strikePrice,
    uint256 expiration
  );

  /// @notice emitted when a call option is settled
  event CallSettled(uint256 optionId, bool claimable);

  /// @notice emitted when a call option is reclaimed
  event CallReclaimed(uint256 optionId);

  /// @notice emitted when a expired call option is burned
  event ExpiredCallBurned(uint256 optionId);

  /// @notice emitted when a call option settlement auction gets and accepts a new bid
  /// @param bidder the account placing the bid that is now the high bidder
  /// @param bidAmount the amount of wei bid
  /// @param optionId the option for the underlying that was bid on
  event Bid(uint256 optionId, uint256 bidAmount, address bidder);

  /// @notice emitted when an option owner claims their proceeds
  /// @param optionId the option the claim is on
  /// @param to the option owner making the claim
  /// @param amount the amount of the claim distributed
  event CallProceedsDistributed(uint256 optionId, address to, uint256 amount);

  /// @notice Mints a new call option for a particular "underlying" ERC-721 NFT with a given strike price and expiration
  /// @param tokenAddress the contract address of the ERC-721 token that serves as the underlying asset for the call
  /// option
  /// @param tokenId the tokenId of the underlying ERC-721 token
  /// @param strikePrice the strike price for the call option being written
  /// @param expirationTime time the timestamp after which the option will be expired
  function mintWithErc721(
    address tokenAddress,
    uint256 tokenId,
    uint128 strikePrice,
    uint32 expirationTime
  ) external returns (uint256);

  /// @notice Mints a new call option for the assets deposited in a particular vault given strike price and expiration.
  /// @param vaultAddress the contract address of the vault currently holding the call option
  /// @param assetId the id of the asset within the vault
  /// @param strikePrice the strike price for the call option being written
  /// @param expirationTime time the timestamp after which the option will be expired
  /// @param signature the signature used to place the entitlement onto the vault
  function mintWithVault(
    address vaultAddress,
    uint32 assetId,
    uint128 strikePrice,
    uint32 expirationTime,
    Signatures.Signature calldata signature
  ) external returns (uint256);

  /// @notice Mints a new call option for the assets deposited in a particular vault given strike price and expiration.
  /// That vault must already have a registered entitlement for this contract with the an expiration equal to {expirationTime}
  /// @param vaultAddress the contract address of the vault currently holding the call option
  /// @param assetId the id of the asset within the vault
  /// @param strikePrice the strike price for the call option being written
  /// @param expirationTime time the timestamp after which the option will be expired
  function mintWithEntitledVault(
    address vaultAddress,
    uint32 assetId,
    uint128 strikePrice,
    uint32 expirationTime
  ) external returns (uint256);

  /// @notice Bid in the settlement auction for an option. The paid amount is the bid,
  /// and the bidder is required to escrow this amount until either the auction ends or another bidder bids higher
  ///
  /// The bid must be greater than the strike price
  /// @param optionId the optionId corresponding to the settlement to bid on.
  function bid(uint256 optionId) external payable;

  /// @notice view function to get the current high settlement bid of an option, or 0 if there is no high bid
  /// @param optionId of the option to check
  function currentBid(uint256 optionId) external view returns (uint128);

  /// @notice view function to get the current high bidder for an option settlement auction, or the null address if no
  /// high bidder exists
  /// @param optionId of the option to check
  /// @return address of the account for the current high bidder, or the null address if there is none
  function currentBidder(uint256 optionId) external view returns (address);

  /// @notice Allows the writer to reclaim an entitled asset. This is only possible when the writer holds the option
  /// nft and calls this function.
  /// @dev Allows the writer to reclaim a NFT if they also hold the option NFT.
  /// @param optionId the option being reclaimed.
  /// @param returnNft true if token should be withdrawn from vault, false to leave token in the vault.
  function reclaimAsset(uint256 optionId, bool returnNft) external;

  /// @notice Looks up the latest optionId that covers a particular asset, if one exists. This option may be already settled.
  /// @dev getOptionIdForAsset
  /// @param vault the address of the hook vault that holds the covered asset
  /// @param assetId the id of the asset to check
  /// @return the optionId, if one exists or 0 otherwise
  function getOptionIdForAsset(address vault, uint32 assetId)
    external
    view
    returns (uint256);

  /// @notice Permissionlessly settle an expired option when the option expires in the money, distributing
  /// the proceeds to the Writer, Holder, and Bidder as follows:
  ///
  /// WRITER (who originally called mint() and owned underlying asset) - receives the `strike`
  /// HOLDER (ownerOf(optionId)) - receives `b-strike`
  /// HIGH BIDDER (call.highBidder) - becomes ownerOf NFT, pays `bid`.
  ///
  /// @dev the return nft param allows the underlying asset to remain in its vault. This saves gas
  /// compared to first distributing it and then re-depositing it. No royalties or other payments
  /// are subtracted from the distribution amounts.
  ///
  /// @param optionId of the option to settle.
  function settleOption(uint256 optionId) external;

  /// @notice Allows anyone to burn the instrument NFT for an expired option.
  /// @param optionId of the option to burn.
  function burnExpiredOption(uint256 optionId) external;

  /// @notice allows the option owner to claim proceeds if the option was settled
  /// by another account. The option NFT is burned after settlement.
  /// @dev this mechanism prevents the proceeds from being sent to an account
  /// temporarily custodying the option asset.
  /// @param optionId the option to claim and burn.
  function claimOptionProceeds(uint256 optionId) external;
}

//
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        ██████████████                                        ██████████████
//        ██████████████          ▄▄████████████████▄▄         ▐█████████████▌
//        ██████████████    ▄█████████████████████████████▄    ██████████████
//         ██████████▀   ▄█████████████████████████████████   ██████████████▌
//          ██████▀   ▄██████████████████████████████████▀  ▄███████████████
//           ███▀   ██████████████████████████████████▀   ▄████████████████
//            ▀▀  ████████████████████████████████▀▀   ▄█████████████████▌
//              █████████████████████▀▀▀▀▀▀▀      ▄▄███████████████████▀
//             ██████████████████▀    ▄▄▄█████████████████████████████▀
//            ████████████████▀   ▄█████████████████████████████████▀  ██▄
//          ▐███████████████▀  ▄██████████████████████████████████▀   █████▄
//          ██████████████▀  ▄█████████████████████████████████▀   ▄████████
//         ██████████████▀   ███████████████████████████████▀   ▄████████████
//        ▐█████████████▌     ▀▀▀▀████████████████████▀▀▀▀      █████████████▌
//        ██████████████                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████

// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

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

/// @title HookProtocol configuration and access control repository
/// @author Jake [email protected]
/// @custom:coauthor Regynald [email protected]
///
/// @dev it is critically important that the particular protocol implementation
/// is correct as, if it is not, all assets contained within protocol contracts
/// can be easily compromised.
interface IHookProtocol is IAccessControl {
  /// @notice the address of the deployed CoveredCallFactory used by the protocol
  function coveredCallContract() external view returns (address);

  /// @notice the address of the deployed VaultFactory used by the protocol
  function vaultContract() external view returns (address);

  /// @notice callable function that reverts when the protocol is paused
  function throwWhenPaused() external;

  /// @notice the standard weth address on this chain
  /// @dev these are values for popular chains:
  /// mainnet: 0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2
  /// kovan: 0xd0a1e359811322d97991e03f863a0c30c2cf029c
  /// ropsten: 0xc778417e063141139fce010982780140aa0cd5ab
  /// rinkeby: 0xc778417e063141139fce010982780140aa0cd5ab
  /// @return the weth address
  function getWETHAddress() external view returns (address);

  /// @notice get a configuration flag with a specific key for a collection
  /// @param collectionAddress the collection for which to lookup a configuration flag
  /// @param conf the config identifier for the configuration flag
  /// @return the true or false value of the config
  function getCollectionConfig(address collectionAddress, bytes32 conf)
    external
    view
    returns (bool);
}

interface IWETH {
  function deposit() external payable;

  function withdraw(uint256 wad) external;

  function transfer(address to, uint256 value) external returns (bool);
}

//
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        ██████████████                                        ██████████████
//        ██████████████          ▄▄████████████████▄▄         ▐█████████████▌
//        ██████████████    ▄█████████████████████████████▄    ██████████████
//         ██████████▀   ▄█████████████████████████████████   ██████████████▌
//          ██████▀   ▄██████████████████████████████████▀  ▄███████████████
//           ███▀   ██████████████████████████████████▀   ▄████████████████
//            ▀▀  ████████████████████████████████▀▀   ▄█████████████████▌
//              █████████████████████▀▀▀▀▀▀▀      ▄▄███████████████████▀
//             ██████████████████▀    ▄▄▄█████████████████████████████▀
//            ████████████████▀   ▄█████████████████████████████████▀  ██▄
//          ▐███████████████▀  ▄██████████████████████████████████▀   █████▄
//          ██████████████▀  ▄█████████████████████████████████▀   ▄████████
//         ██████████████▀   ███████████████████████████████▀   ▄████████████
//        ▐█████████████▌     ▀▀▀▀████████████████████▀▀▀▀      █████████████▌
//        ██████████████                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████

/// @notice roles on the hook protocol that can be read by other contract
/// @dev new roles here should be initialized in the constructor of the protocol
abstract contract PermissionConstants {
  /// ----- ROLES --------

  /// @notice the allowlister is able to enable and disable projects to mint instruments
  bytes32 public constant ALLOWLISTER_ROLE = keccak256("ALLOWLISTER_ROLE");

  /// @notice the pauser is able to start and pause various components of the protocol
  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

  /// @notice the vault upgrader role is able to upgrade the implementation for all vaults
  bytes32 public constant VAULT_UPGRADER = keccak256("VAULT_UPGRADER");

  /// @notice the call upgrader role is able to upgrade the implementation of the covered call options
  bytes32 public constant CALL_UPGRADER = keccak256("CALL_UPGRADER");

  /// @notice the market configuration role allows the actor to make changes to how the market operates
  bytes32 public constant MARKET_CONF = keccak256("MARKET_CONF");

  /// @notice the collection configuration role allows the actor to make changes the collection
  /// configs on the protocol contract
  bytes32 public constant COLLECTION_CONF = keccak256("COLLECTION_CONF");
}

//
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        ██████████████                                        ██████████████
//        ██████████████          ▄▄████████████████▄▄         ▐█████████████▌
//        ██████████████    ▄█████████████████████████████▄    ██████████████
//         ██████████▀   ▄█████████████████████████████████   ██████████████▌
//          ██████▀   ▄██████████████████████████████████▀  ▄███████████████
//           ███▀   ██████████████████████████████████▀   ▄████████████████
//            ▀▀  ████████████████████████████████▀▀   ▄█████████████████▌
//              █████████████████████▀▀▀▀▀▀▀      ▄▄███████████████████▀
//             ██████████████████▀    ▄▄▄█████████████████████████████▀
//            ████████████████▀   ▄█████████████████████████████████▀  ██▄
//          ▐███████████████▀  ▄██████████████████████████████████▀   █████▄
//          ██████████████▀  ▄█████████████████████████████████▀   ▄████████
//         ██████████████▀   ███████████████████████████████▀   ▄████████████
//        ▐█████████████▌     ▀▀▀▀████████████████████▀▀▀▀      █████████████▌
//        ██████████████                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████

// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Burnable.sol)

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
}

// OpenZeppelin Contracts (last updated v4.5.0) (utils/Base64.sol)

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
}

//
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        ██████████████                                        ██████████████
//        ██████████████          ▄▄████████████████▄▄         ▐█████████████▌
//        ██████████████    ▄█████████████████████████████▄    ██████████████
//         ██████████▀   ▄█████████████████████████████████   ██████████████▌
//          ██████▀   ▄██████████████████████████████████▀  ▄███████████████
//           ███▀   ██████████████████████████████████▀   ▄████████████████
//            ▀▀  ████████████████████████████████▀▀   ▄█████████████████▌
//              █████████████████████▀▀▀▀▀▀▀      ▄▄███████████████████▀
//             ██████████████████▀    ▄▄▄█████████████████████████████▀
//            ████████████████▀   ▄█████████████████████████████████▀  ██▄
//          ▐███████████████▀  ▄██████████████████████████████████▀   █████▄
//          ██████████████▀  ▄█████████████████████████████████▀   ▄████████
//         ██████████████▀   ███████████████████████████████▀   ▄████████████
//        ▐█████████████▌     ▀▀▀▀████████████████████▀▀▀▀      █████████████▌
//        ██████████████                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████

library HookStrings {
  
  /// @dev toAsciiString creates a hex encoding of an
  /// address as a string to use in the preview NFT.
  function toAsciiString(address x) internal pure returns (string memory) {
    bytes memory s = new bytes(40);
    for (uint256 i = 0; i < 20; i++) {
      bytes1 b = bytes1(uint8(uint256(uint160(x)) / (2**(8 * (19 - i)))));
      bytes1 hi = bytes1(uint8(b) / 16);
      bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
      s[2 * i] = char(hi);
      s[2 * i + 1] = char(lo);
    }
    return string(s);
  }

  function char(bytes1 b) internal pure returns (bytes1) {
    if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
    else return bytes1(uint8(b) + 0x57);
  }

  function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
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
}

//
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        █████████████▌                                        ▐█████████████
//        ██████████████                                        ██████████████
//        ██████████████          ▄▄████████████████▄▄         ▐█████████████▌
//        ██████████████    ▄█████████████████████████████▄    ██████████████
//         ██████████▀   ▄█████████████████████████████████   ██████████████▌
//          ██████▀   ▄██████████████████████████████████▀  ▄███████████████
//           ███▀   ██████████████████████████████████▀   ▄████████████████
//            ▀▀  ████████████████████████████████▀▀   ▄█████████████████▌
//              █████████████████████▀▀▀▀▀▀▀      ▄▄███████████████████▀
//             ██████████████████▀    ▄▄▄█████████████████████████████▀
//            ████████████████▀   ▄█████████████████████████████████▀  ██▄
//          ▐███████████████▀  ▄██████████████████████████████████▀   █████▄
//          ██████████████▀  ▄█████████████████████████████████▀   ▄████████
//         ██████████████▀   ███████████████████████████████▀   ▄████████████
//        ▐█████████████▌     ▀▀▀▀████████████████████▀▀▀▀      █████████████▌
//        ██████████████                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████
//        █████████████▌                                        ██████████████

/// @dev This contract implements some ERC721 / for hook instruments.
library TokenURI {
  function _generateMetadataERC721(
    address underlyingTokenAddress,
    uint256 underlyingTokenId,
    uint256 instrumentStrikePrice,
    uint256 instrumentExpiration,
    uint256 transfers
  ) internal pure returns (string memory) {
    return
      string(
        abi.encodePacked(
          '"expiration": ',
          HookStrings.toString(instrumentExpiration),
          ', "underlying_address": "',
          HookStrings.toAsciiString(underlyingTokenAddress),
          '", "underlying_tokenId": ',
          HookStrings.toString(underlyingTokenId),
          ', "strike_price": ',
          HookStrings.toString(instrumentStrikePrice),
          ', "transfer_index": ',
          HookStrings.toString(transfers)
        )
      );
  }

  /// @dev this is a basic tokenURI based on the loot contract for an ERC721
  function tokenURIERC721(
    uint256 instrumentId,
    address underlyingAddress,
    uint256 underlyingTokenId,
    uint256 instrumentExpiration,
    uint256 instrumentStrike,
    uint256 transfers
  ) public view returns (string memory) {
    string memory json = Base64.encode(
      bytes(
        string(
          abi.encodePacked(
            '{"name": "Option ID ',
            HookStrings.toString(instrumentId),
            '",',
            _generateMetadataERC721(
              underlyingAddress,
              underlyingTokenId,
              instrumentStrike,
              instrumentExpiration,
              transfers
            ),
            ', "description": "Option Instrument NFT on Hook: the NFT-native call options protocol. Learn more at https://hook.xyz", "image": "https://option-images-hook.s3.amazonaws.com/nft/live_0x',
            HookStrings.toAsciiString(address(this)),
            "_",
            HookStrings.toString(instrumentId),
            '.png" }'
          )
        )
      )
    );
    return string(abi.encodePacked("data:application/json;base64,", json));
  }
}

/// @dev This contract implements some ERC721 / for hook instruments.
abstract contract HookInstrumentERC721 is ERC721Burnable {
  using Counters for Counters.Counter;
  mapping(uint256 => Counters.Counter) private _transfers;
  bytes4 private constant ERC_721 = bytes4(keccak256("ERC721"));

  /// @dev the contact address for a marketplace to pre-approve
  address public _preApprovedMarketplace = address(0);

  /// @dev hook called after the ERC721 is transferred,
  /// which allows us to increment the counters.
  function _afterTokenTransfer(
    address, // from
    address, // to
    uint256 tokenId
  ) internal override {
    // increment the counter for the token
    _transfers[tokenId].increment();
  }

  ///
  /// @dev See {IERC721-isApprovedForAll}.
  /// this extension ensures that any operator contract located
  /// at {_approvedMarketpace} is considered approved internally
  /// in the ERC721 contract
  ///
  function isApprovedForAll(address owner, address operator)
    public
    view
    virtual
    override
    returns (bool)
  {
    return
      operator == _preApprovedMarketplace ||
      super.isApprovedForAll(owner, operator);
  }

  constructor(string memory instrumentType)
    ERC721(makeInstrumentName(instrumentType), "INST")
  {}

  function makeInstrumentName(string memory z)
    internal
    pure
    returns (string memory)
  {
    return string(abi.encodePacked("Hook ", z, " instrument"));
  }

  /// @notice the number of times the token has been transferred
  /// @dev this count can be used by overbooks to invalidate orders after a
  /// token has been transferred, preventing stale order execution by
  /// malicious parties
  function getTransferCount(uint256 optionId) external view returns (uint256) {
    return _transfers[optionId].current();
  }

  /// @notice getter for the address holding the underlying asset
  function getVaultAddress(uint256 optionId)
    public
    view
    virtual
    returns (address);

  /// @notice getter for the assetId of the underlying asset within a vault
  function getAssetId(uint256 optionId) public view virtual returns (uint32);

  /// @notice getter for the option strike price
  function getStrikePrice(uint256 optionId)
    external
    view
    virtual
    returns (uint256);

  /// @notice getter for the options expiration. After this time the
  /// option is invalid
  function getExpiration(uint256 optionId)
    external
    view
    virtual
    returns (uint256);

  /// @dev this is the OpenSea compatible collection - level metadata URI.
  function contractUri(uint256 optionId) external view returns (string memory) {
    return
      string(
        abi.encodePacked(
          "token.hook.xyz/option-contract/",
          HookStrings.toAsciiString(address(this)),
          "/",
          HookStrings.toString(optionId)
        )
      );
  }

  ///
  /// @dev See {IERC721-tokenURI}.
  ///
  function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
  {
    bytes4 class = _underlyingClass(tokenId);
    if (class == ERC_721) {
      IHookERC721Vault vault = IHookERC721Vault(getVaultAddress(tokenId));
      uint32 assetId = getAssetId(tokenId);
      address underlyingAddress = vault.assetAddress(assetId);
      uint256 underlyingTokenId = vault.assetTokenId(assetId);
      // currently nothing in the contract depends on the actual underlying metadata uri
      // IERC721 underlyingContract = IERC721(underlyingAddress);
      uint256 instrumentStrikePrice = this.getStrikePrice(tokenId);
      uint256 instrumentExpiration = this.getExpiration(tokenId);
      uint256 transfers = _transfers[tokenId].current();
      return
        TokenURI.tokenURIERC721(
          tokenId,
          underlyingAddress,
          underlyingTokenId,
          instrumentExpiration,
          instrumentStrikePrice,
          transfers
        );
    }
    return "Invalid underlying asset";
  }

  /// @dev returns an internal identifier for the underlying type contained within
  /// the vault to determine what the instrument is on
  ///
  /// this class evaluation relies on the interfaceId of the underlying asset
  ///
  function _underlyingClass(uint256 optionId)
    internal
    view
    returns (bytes4)
  {
    if (
      ERC165Checker.supportsInterface(
        getVaultAddress(optionId),
        type(IHookERC721Vault).interfaceId
      )
    ) {
      return ERC_721;
    } else {
      revert("_underlying-class: Unsupported underlying type");
    }
  }
}

/// @title HookCoveredCallImplV1 an implementation of covered calls on Hook
/// @author Jake [email protected]
/// @custom:coauthor Regynald [email protected]
/// @notice See {IHookCoveredCall}.
/// @dev In the context of a single call option, the role of the writer is non-transferrable.
/// @dev This contract is intended to be an implementation referenced by a proxy
contract HookCoveredCallImplV1 is
  IHookCoveredCall,
  HookInstrumentERC721,
  ReentrancyGuard,
  Initializable,
  PermissionConstants
{
  using Counters for Counters.Counter;

  /// @notice The metadata for each covered call option stored within the protocol
  /// @param writer The address of the writer that created the call option
  /// @param expiration The expiration time of the call option
  /// @param assetId the asset id of the underlying within the vault
  /// @param vaultAddress the address of the vault holding the underlying asset
  /// @param strike The strike price to exercise the call option
  /// @param bid is the current high bid in the settlement auction
  /// @param highBidder is the address that made the current winning bid in the settlement auction
  /// @param settled a flag that marks when a settlement action has taken place successfully. Once this flag is set, ETH should not
  /// be sent from the contract related to this particular option
  struct CallOption {
    address writer;
    uint32 expiration;
    uint32 assetId;
    address vaultAddress;
    uint128 strike;
    uint128 bid;
    address highBidder;
    bool settled;
  }

  /// --- Storage

  /// @dev holds the current ID for the last minted option. The optionId also serves as the tokenId for
  /// the associated option instrument NFT.
  Counters.Counter private _optionIds;

  /// @dev the address of the factory in the Hook protocol that can be used to generate ERC721 vaults
  IHookERC721VaultFactory private _erc721VaultFactory;

  /// @dev the address of the deployed hook protocol contract, which has permissions and access controls
  IHookProtocol private _protocol;

  /// @dev storage of all existing options contracts.
  mapping(uint256 => CallOption) public optionParams;

  /// @dev storage of current call active call option for a specific asset
  /// mapping(vaultAddress => mapping(assetId => CallOption))
  // the call option is is referenced via the optionID stored in optionParams
  mapping(IHookVault => mapping(uint32 => uint256)) public assetOptions;

  /// @dev mapping to store the amount of eth in wei that may
  /// be claimed by the current ownerOf the option nft.
  mapping(uint256 => uint256) public optionClaims;

  /// @dev the address of the token contract permitted to serve as underlying assets for this
  /// instrument.
  address public allowedUnderlyingAddress;

  /// @dev the address of WETH on the chain where this contract is deployed
  address public weth;

  /// @dev this is the minimum duration of an option created in this contract instance
  uint256 public minimumOptionDuration;

  /// @dev this is the minimum amount of the current bid that the new bid
  /// must exceed the current bid by in order to be considered valid.
  /// This amount is expressed in basis points (i.e. 1/100th of 1%)
  uint256 public minBidIncrementBips;

  /// @dev this is the amount of time before the expiration of the option
  /// that the settlement auction will begin.
  uint256 public settlementAuctionStartOffset;

  /// @dev this is a flag that can be set to pause this particular
  /// instance of the call option contract.
  /// NOTE: settlement auctions are still enabled in
  /// this case because pausing the market should not change the
  /// financial situation for the holder of the options.
  bool public marketPaused;

  /// @dev Emitted when the market is paused or unpaused
  /// @param paused true if paused false otherwise
  event MarketPauseUpdated(bool paused);

  /// @dev Emitted when the bid increment is updated
  /// @param bidIncrementBips the new bid increment amount in bips
  event MinBidIncrementUpdated(uint256 bidIncrementBips);

  /// @dev emitted when the settlement auction start offset is updated
  /// @param startOffset new number of seconds from expiration when the start offset begins
  event SettlementAuctionStartOffsetUpdated(uint256 startOffset);

  /// @dev emitted when the minimum duration for an option is changed
  /// @param optionDuration new minimum length of an option in seconds.
  event MinOptionDurationUpdated(uint256 optionDuration);

  /// --- Constructor
  // the constructor cannot have arguments in proxied contracts.
  constructor() HookInstrumentERC721("Call") {}

  /// @notice Initializes the specific instance of the instrument contract.
  /// @dev Because the deployed contract is proxied, arguments unique to each deployment
  /// must be passed in an individual initializer. This function is like a constructor.
  /// @param protocol the address of the Hook protocol (which contains configurations)
  /// @param nftContract the address for the ERC-721 contract that can serve as underlying instruments
  /// @param hookVaultFactory the address of the ERC-721 vault registry
  /// @param preApprovedMarketplace the address of the contract which will automatically approved
  /// to transfer option ERC721s owned by any account when they're minted
  function initialize(
    address protocol,
    address nftContract,
    address hookVaultFactory,
    address preApprovedMarketplace
  ) public initializer {
    _protocol = IHookProtocol(protocol);
    _erc721VaultFactory = IHookERC721VaultFactory(hookVaultFactory);
    weth = _protocol.getWETHAddress();
    _preApprovedMarketplace = preApprovedMarketplace;
    allowedUnderlyingAddress = nftContract;
    /// increment the optionId such that id=0 can be treated as the null value
    _optionIds.increment();

    /// Initialize basic configuration.
    /// Even though these are defaults, we cannot set them in the constructor because
    /// each instance of this contract will need to have the storage initialized
    /// to read from these values (this is the implementation contract pointed to by a proxy)
    minimumOptionDuration = 1 days;
    minBidIncrementBips = 50;
    settlementAuctionStartOffset = 1 days;
    marketPaused = false;
  }

  /// ---- Option Writer Functions ---- //

  /// @dev See {IHookCoveredCall-mintWithVault}.
  function mintWithVault(
    address vaultAddress,
    uint32 assetId,
    uint128 strikePrice,
    uint32 expirationTime,
    Signatures.Signature calldata signature
  ) external nonReentrant whenNotPaused returns (uint256) {
    IHookVault vault = IHookVault(vaultAddress);
    require(
      allowedUnderlyingAddress == vault.assetAddress(assetId),
      "mWV-token not allowed"
    );
    require(vault.getHoldsAsset(assetId), "mWV-asset not in vault");
    require(
      _allowedVaultImplementation(
        vaultAddress,
        allowedUnderlyingAddress,
        assetId
      ),
      "mWV-can only mint with protocol vaults"
    );
    // the beneficial owner is the only one able to impose entitlements, so
    // we need to require that they've done so here.
    address writer = vault.getBeneficialOwner(assetId);

    require(
      msg.sender == writer || msg.sender == vault.getApprovedOperator(assetId),
      "mWV-called by someone other than the owner or operator"
    );

    vault.imposeEntitlement(
      address(this),
      expirationTime,
      assetId,
      signature.v,
      signature.r,
      signature.s
    );

    return
      _mintOptionWithVault(writer, vault, assetId, strikePrice, expirationTime);
  }

  /// @dev See {IHookCoveredCall-mintWithEntitledVault}.
  function mintWithEntitledVault(
    address vaultAddress,
    uint32 assetId,
    uint128 strikePrice,
    uint32 expirationTime
  ) external nonReentrant whenNotPaused returns (uint256) {
    IHookVault vault = IHookVault(vaultAddress);

    require(
      allowedUnderlyingAddress == vault.assetAddress(assetId),
      "mWEV-token not allowed"
    );
    require(vault.getHoldsAsset(assetId), "mWEV-asset must be in vault");
    (bool active, address operator) = vault.getCurrentEntitlementOperator(
      assetId
    );
    require(
      active && operator == address(this),
      "mWEV-call contract not operator"
    );

    require(
      expirationTime == vault.entitlementExpiration(assetId),
      "mWEV-entitlement expiration different"
    );
    require(
      _allowedVaultImplementation(
        vaultAddress,
        allowedUnderlyingAddress,
        assetId
      ),
      "mWEV-only protocol vaults allowed"
    );

    // the beneficial owner owns the asset so
    // they should receive the option.
    address writer = vault.getBeneficialOwner(assetId);

    require(
      writer == msg.sender || vault.getApprovedOperator(assetId) == msg.sender,
      "mWEV-only owner or operator may mint"
    );

    return
      _mintOptionWithVault(writer, vault, assetId, strikePrice, expirationTime);
  }

  /// @dev See {IHookCoveredCall-mintWithErc721}.
  function mintWithErc721(
    address tokenAddress,
    uint256 tokenId,
    uint128 strikePrice,
    uint32 expirationTime
  ) external nonReentrant whenNotPaused returns (uint256) {
    address tokenOwner = IERC721(tokenAddress).ownerOf(tokenId);
    require(
      allowedUnderlyingAddress == tokenAddress,
      "mWE7-token not on allowlist"
    );

    require(
      msg.sender == tokenOwner ||
        IERC721(tokenAddress).isApprovedForAll(tokenOwner, msg.sender) ||
        IERC721(tokenAddress).getApproved(tokenId) == msg.sender,
      "mWE7-caller not owner or operator"
    );

    // NOTE: we can mint the option since our contract is approved
    // this is to ensure additionally that the msg.sender isn't a unexpected address
    require(
      IERC721(tokenAddress).isApprovedForAll(tokenOwner, address(this)) ||
        IERC721(tokenAddress).getApproved(tokenId) == address(this),
      "mWE7-not approved operator"
    );

    // FIND OR CREATE HOOK VAULT, SET AN ENTITLEMENT
    IHookERC721Vault vault = _erc721VaultFactory.findOrCreateVault(
      tokenAddress,
      tokenId
    );

    uint32 assetId = 0;
    if (
      address(vault) ==
      Create2.computeAddress(
        BeaconSalts.multiVaultSalt(tokenAddress),
        BeaconSalts.ByteCodeHash,
        address(_erc721VaultFactory)
      )
    ) {
      // If the vault is a multi-vault, it requires that the assetId matches the
      // tokenId, instead of having a standard assetI of 0
      assetId = uint32(tokenId);
    }

    uint256 optionId = _mintOptionWithVault(
      tokenOwner,
      IHookVault(vault),
      assetId,
      strikePrice,
      expirationTime
    );

    // transfer the underlying asset into our vault, passing along the entitlement. The entitlement specified
    // here will be accepted by the vault because we are also simultaneously tendering the asset.
    IERC721(tokenAddress).safeTransferFrom(
      tokenOwner,
      address(vault),
      tokenId,
      abi.encode(tokenOwner, address(this), expirationTime)
    );

    // make sure that the vault actually has the asset.
    require(
      IERC721(tokenAddress).ownerOf(tokenId) == address(vault),
      "mWE7-asset not in vault"
    );

    return optionId;
  }

  /// @notice internal use function to record the option and mint it
  /// @dev the vault is completely unchecked here, so the caller must ensure the vault is created,
  /// has a valid entitlement, and has the asset inside it
  /// @param writer the writer of the call option, usually the current owner of the underlying asset
  /// @param vault the address of the IHookVault which contains the underlying asset
  /// @param assetId the id of the underlying asset
  /// @param strikePrice the strike price for this current option, in ETH
  /// @param expirationTime the time after which the option will be considered expired
  function _mintOptionWithVault(
    address writer,
    IHookVault vault,
    uint32 assetId,
    uint128 strikePrice,
    uint32 expirationTime
  ) private returns (uint256) {
    // NOTE: The settlement auction always occurs one day before expiration
    require(
      expirationTime > block.timestamp + minimumOptionDuration,
      "_mOWV-expires sooner than min duration"
    );

    // verify that, if there is a previous option on this asset, it has already settled.
    uint256 prevOptionId = assetOptions[vault][assetId];
    if (prevOptionId != 0) {
      require(
        optionParams[prevOptionId].settled,
        "_mOWV-previous option must be settled"
      );
    }

    // generate the next optionId
    _optionIds.increment();
    uint256 newOptionId = _optionIds.current();

    // save the option metadata
    optionParams[newOptionId] = CallOption({
      writer: writer,
      vaultAddress: address(vault),
      assetId: assetId,
      strike: strikePrice,
      expiration: expirationTime,
      bid: 0,
      highBidder: address(0),
      settled: false
    });

    // send the option NFT to the underlying token owner.
    _safeMint(writer, newOptionId);

    // If msg.sender and tokenOwner are different accounts, approve the msg.sender
    // to transfer the option NFT as it already had the right to transfer the underlying NFT.
    if (msg.sender != writer) {
      _approve(msg.sender, newOptionId);
    }

    assetOptions[vault][assetId] = newOptionId;

    emit CallCreated(
      writer,
      address(vault),
      assetId,
      newOptionId,
      strikePrice,
      expirationTime
    );

    return newOptionId;
  }

  // --- Bidder Functions

  modifier biddingEnabled(uint256 optionId) {
    CallOption memory call = optionParams[optionId];
    require(call.expiration > block.timestamp, "bE-expired");
    require(
      (call.expiration - settlementAuctionStartOffset) <= block.timestamp,
      "bE-bidding starts on last day"
    );
    require(!call.settled, "bE-already settled");
    _;
  }

  /// @dev method to verify that a particular vault was created by the protocol's vault factory
  /// @param vaultAddress location where the vault is deployed
  /// @param underlyingAddress address of underlying asset
  /// @param assetId id of the asset within the vault
  function _allowedVaultImplementation(
    address vaultAddress,
    address underlyingAddress,
    uint32 assetId
  ) internal view returns (bool) {
    // First check if the multiVault is the one to save a bit of gas
    // in the case the user is optimizing for gas savings (by using MultiVault)
    if (
      vaultAddress ==
      Create2.computeAddress(
        BeaconSalts.multiVaultSalt(underlyingAddress),
        BeaconSalts.ByteCodeHash,
        address(_erc721VaultFactory)
      )
    ) {
      return true;
    }

    try IHookERC721Vault(vaultAddress).assetTokenId(assetId) returns (
      uint256 _tokenId
    ) {
      if (
        vaultAddress ==
        Create2.computeAddress(
          BeaconSalts.soloVaultSalt(underlyingAddress, _tokenId),
          BeaconSalts.ByteCodeHash,
          address(_erc721VaultFactory)
        )
      ) {
        return true;
      }
    } catch (bytes memory) {
      return false;
    }

    return false;
  }

  /// @dev See {IHookCoveredCall-bid}.
  function bid(uint256 optionId)
    external
    payable
    nonReentrant
    biddingEnabled(optionId)
  {
    uint128 bidAmt = uint128(msg.value);
    CallOption storage call = optionParams[optionId];

    if (msg.sender == call.writer) {
      /// handle the case where an option writer bids on
      /// an underlying asset that they owned. In this case, as they would be
      /// the recipient of the spread after the auction, they are able to bid
      /// paying only the difference between their bid and the strike.
      bidAmt += call.strike;
    }

    require(
      bidAmt >= call.bid + ((call.bid * minBidIncrementBips) / 10000),
      "b-must overbid by minBidIncrementBips"
    );
    require(bidAmt > call.strike, "b-bid is lower than the strike price");

    _returnBidToPreviousBidder(call);

    // set the new bidder
    call.bid = bidAmt;
    call.highBidder = msg.sender;

    // the new high bidder is the beneficial owner of the asset.
    // The beneficial owner must be set here instead of with a settlement
    // because otherwise the writer will be able to remove the asset from the vault
    // between the expiration and the settlement call, effectively stealing the asset.
    IHookVault(call.vaultAddress).setBeneficialOwner(call.assetId, msg.sender);

    // emit event
    emit Bid(optionId, bidAmt, msg.sender);
  }

  function _returnBidToPreviousBidder(CallOption storage call) internal {
    uint256 unNormalizedHighBid = call.bid;
    if (call.highBidder == call.writer) {
      unNormalizedHighBid -= call.strike;
    }

    // return current bidder's money
    if (unNormalizedHighBid > 0) {
      _safeTransferETHWithFallback(call.highBidder, unNormalizedHighBid);
    }
  }

  /// @dev See {IHookCoveredCall-currentBid}.
  function currentBid(uint256 optionId) external view returns (uint128) {
    return optionParams[optionId].bid;
  }

  /// @dev See {IHookCoveredCall-currentBidder}.
  function currentBidder(uint256 optionId) external view returns (address) {
    return optionParams[optionId].highBidder;
  }

  // ----- END OF OPTION FUNCTIONS ---------//

  /// @dev See {IHookCoveredCall-settleOption}.
  function settleOption(uint256 optionId) external nonReentrant {
    CallOption storage call = optionParams[optionId];
    require(call.highBidder != address(0), "s-bid must be won by someone");
    require(call.expiration < block.timestamp, "s-option must be expired");
    require(!call.settled, "s-the call cannot already be settled");

    uint256 spread = call.bid - call.strike;

    address optionOwner = ownerOf(optionId);

    // set settled to prevent an additional attempt to settle the option
    optionParams[optionId].settled = true;

    // If the option writer is the high bidder they don't receive the strike because they bid on the spread.
    if (call.highBidder != call.writer) {
      // send option writer the strike price
      _safeTransferETHWithFallback(call.writer, call.strike);
    }

    bool claimable = false;
    if (msg.sender == optionOwner) {
      // send option holder their earnings
      _safeTransferETHWithFallback(optionOwner, spread);

      // burn nft
      _burn(optionId);
    } else {
      optionClaims[optionId] = spread;
      claimable = true;
    }
    emit CallSettled(optionId, claimable);
  }

  /// @dev See {IHookCoveredCall-reclaimAsset}.
  function reclaimAsset(uint256 optionId, bool returnNft)
    external
    nonReentrant
  {
    CallOption storage call = optionParams[optionId];
    require(msg.sender == call.writer, "rA-only writer");
    require(!call.settled, "rA-option settled");
    require(call.writer == ownerOf(optionId), "rA-writer must own");
    require(call.expiration > block.timestamp, "rA-option expired");

    // burn the option NFT
    _burn(optionId);

    // settle the option
    call.settled = true;

    if (call.highBidder != address(0)) {
      // return current bidder's money
      if (call.highBidder == call.writer) {
        // handle the case where the writer is reclaiming as option they were the high bidder of
        _safeTransferETHWithFallback(call.highBidder, call.bid - call.strike);
      } else {
        _safeTransferETHWithFallback(call.highBidder, call.bid);
      }

      // if we have a bid, we may have set the bidder, so make sure to revert it here.
      IHookVault(call.vaultAddress).setBeneficialOwner(
        call.assetId,
        call.writer
      );
    }

    if (returnNft) {
      // Because the call is not expired, we should be able to reclaim the asset from the vault
      IHookVault(call.vaultAddress).clearEntitlementAndDistribute(
        call.assetId,
        call.writer
      );
    } else {
      IHookVault(call.vaultAddress).clearEntitlement(call.assetId);
    }

    emit CallReclaimed(optionId);
  }

  /// @dev See {IHookCoveredCall-burnExpiredOption}.
  function burnExpiredOption(uint256 optionId)
    external
    nonReentrant
    whenNotPaused
  {
    CallOption storage call = optionParams[optionId];

    require(block.timestamp > call.expiration, "bEO-option expired");

    require(!call.settled, "bEO-option settled");

    require(call.highBidder == address(0), "bEO-option has bids");

    // burn the option NFT
    _burn(optionId);

    // settle the option
    call.settled = true;

    emit ExpiredCallBurned(optionId);
  }

  /// @dev See {IHookCoveredCall-claimOptionProceeds}
  function claimOptionProceeds(uint256 optionId) external nonReentrant {
    address optionOwner = ownerOf(optionId);
    require(msg.sender == optionOwner, "cOP-owner only");
    uint256 claim = optionClaims[optionId];
    delete optionClaims[optionId];
    if (claim != 0) {
      _burn(optionId);
      emit CallProceedsDistributed(optionId, optionOwner, claim);
      _safeTransferETHWithFallback(optionOwner, claim);
    }
  }

  //// ---- Administrative Fns.

  // forward to protocol-level pauseability
  modifier whenNotPaused() {
    require(!marketPaused, "market paused");
    _protocol.throwWhenPaused();
    _;
  }

  modifier onlyMarketController() {
    require(
      _protocol.hasRole(MARKET_CONF, msg.sender),
      "caller needs MARKET_CONF"
    );
    _;
  }

  /// @dev configures the minimum duration for a newly minted option. Options must be at
  /// least this far away in the future.
  /// @param newMinDuration is the minimum option duration in seconds
  function setMinOptionDuration(uint256 newMinDuration)
    public
    onlyMarketController
  {
    require(settlementAuctionStartOffset < newMinDuration);
    minimumOptionDuration = newMinDuration;
    emit MinOptionDurationUpdated(newMinDuration);
  }

  /// @dev set the minimum overage, in bips, for a new bid compared to the current bid.
  /// @param newBidIncrement the minimum bid increment in basis points (1/100th of 1%)
  function setBidIncrement(uint256 newBidIncrement)
    public
    onlyMarketController
  {
    require(newBidIncrement < 20 * 100);
    minBidIncrementBips = newBidIncrement;
    emit MinBidIncrementUpdated(newBidIncrement);
  }

  /// @dev set the settlement auction start offset. Settlement auctions begin at this time prior to expiration.
  /// @param newSettlementStartOffset in seconds (i.e. block.timestamp increments)
  function setSettlementAuctionStartOffset(uint256 newSettlementStartOffset)
    public
    onlyMarketController
  {
    require(newSettlementStartOffset < minimumOptionDuration);
    settlementAuctionStartOffset = newSettlementStartOffset;
    emit SettlementAuctionStartOffsetUpdated(newSettlementStartOffset);
  }

  /// @dev sets a paused / unpaused state for the market corresponding to this contract
  /// @param paused should the market be set to paused or unpaused
  function setMarketPaused(bool paused) public onlyMarketController {
    require(marketPaused == !paused, "sMP-must change");
    marketPaused = paused;
    emit MarketPauseUpdated(paused);
  }

  //// ------------------------- NFT RELATED FUNCTIONS ------------------------------- ////
  //// These functions are overrides needed by the HookInstrumentNFT library in order   ////
  //// to generate the NFT view for the project.                                       ////

  /// @dev see {IHookCoveredCall-getVaultAddress}.
  function getVaultAddress(uint256 optionId)
    public
    view
    override
    returns (address)
  {
    return optionParams[optionId].vaultAddress;
  }

  /// @dev see {IHookCoveredCall-getOptionIdForAsset}
  function getOptionIdForAsset(address vault, uint32 assetId)
    external
    view
    returns (uint256)
  {
    return assetOptions[IHookVault(vault)][assetId];
  }

  /// @dev see {IHookCoveredCall-getAssetId}.
  function getAssetId(uint256 optionId) public view override returns (uint32) {
    return optionParams[optionId].assetId;
  }

  /// @dev see {IHookCoveredCall-getStrikePrice}.
  function getStrikePrice(uint256 optionId)
    public
    view
    override
    returns (uint256)
  {
    return optionParams[optionId].strike;
  }

  /// @dev see {IHookCoveredCall-getExpiration}.
  function getExpiration(uint256 optionId)
    public
    view
    override
    returns (uint256)
  {
    return optionParams[optionId].expiration;
  }

  //// ----------------------------- ETH TRANSFER UTILITIES --------------------------- ////

  /// @notice Transfer ETH. If the ETH transfer fails, wrap the ETH and try send it as WETH.
  /// @dev this transfer failure could occur if the transferee is a malicious contract
  /// so limiting the gas and persisting on fail helps prevent the impact of these calls.
  function _safeTransferETHWithFallback(address to, uint256 amount) internal {
    if (!_safeTransferETH(to, amount)) {
      IWETH(weth).deposit{value: amount}();
      IWETH(weth).transfer(to, amount);
    }
  }

  /// @notice Transfer ETH and return the success status.
  /// @dev This function only forwards 30,000 gas to the callee.
  /// this prevents malicious contracts from causing the next bidder to run out of gas,
  /// which would prevent them from bidding successfully
  function _safeTransferETH(address to, uint256 value) internal returns (bool) {
    (bool success, ) = to.call{value: value, gas: 30_000}(new bytes(0));
    return success;
  }
}