/**
 *Submitted for verification at Etherscan.io on 2022-11-08
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.15;

/**
 * Interface for a Mixin expressing a modular requirement to be used by the
 * `GuardMixinManager`, determining whether a token can be minted, burned, or
 * transferred by a particular operator, from a particular sender (`from` is
 * address 0 iff the token is being minted), to a particular recipient (`to` is
 * address 0 iff the token is being burned).
 */
interface IGuardMixin {
    /**
     * @return True iff the transaction is allowed
     * @param token Address of the token being minted/burned/transferred
     * @param operator Transaction msg.sender
     * @param from Token sender
     * @param to Token recipient
     * @param value amount (ERC20) or tokenId (ERC721)
     */
    function isAllowed(
        address token,
        address operator,
        address from,
        address to,
        uint256 value // amount (ERC20) or tokenId (ERC721)
    ) external view returns (bool);
}

/**
 * Interface for a Guard that governs whether a token can be minted, burned, or
 * transferred by a particular operator, from a particular sender (`from` is
 * address 0 iff the token is being minted), to a particular recipient (`to` is
 * address 0 iff the token is being burned).
 */
interface IGuard {
    /**
     * @return True iff the transaction is allowed
     * @param operator Transaction msg.sender
     * @param from Token sender
     * @param to Token recipient
     * @param value Amount (ERC20) or token ID (ERC721)
     */
    function isAllowed(
        address operator,
        address from,
        address to,
        uint256 value // amount (ERC20) or tokenId (ERC721)
    ) external view returns (bool);
}

/**
 * Interface for `GuardMixinManager`, a Guard aggregating modular transaction
 * requirements ("Mixins").
 */
interface IGuardMixinManager is IGuard {
    event DefaultMixinsUpdated(address indexed token, address[] mixins);
    event ModuleDefaultMixinsUpdated(
        address indexed token,
        address indexed module,
        bool allowed
    );
    event ModuleCustomMixinsUpdated(
        address indexed token,
        address indexed module,
        address[] mixins
    );

    /**
     * @return Address of the Mixin in the `index` position of the list of
     * default Mixins for the token.
     * @param token Address of the token
     * @param index Index in the list of default Mixins
     * @dev The Solidity compiler generates an automatic getter for this
     * `address => address[]` mapping (token address => array of default Mixin
     * addresses) that takes the _index_ of the address array as a second
     * parameter. Use `defaultMixins[token]` to access the whole array of
     * default Mixin addresses.
     */
    function defaultMixins(address token, uint256 index)
        external
        view
        returns (address);

    /**
     * @return True iff the module is allowed for a given token AND subject to
     * default Mixins
     * @param token Address of the token
     * @param module Address of the module
     */
    function modulesDefaultMixins(address token, address module)
        external
        view
        returns (bool);

    /**
     * @return Address of the Mixin in the `index` position of the list of
     * Mixins applied to a particular module given a particular token
     * @param token Address of the token
     * @param module Address of the module
     * @param index Index in the list of Mixins applied to the module
     * @dev The Solidity compiler generates an automatic getter for this
     * `address => address => address[]` mapping (token address => module
     * address => array of Mixin addresses customized for that module) that
     * takes the _index_ of the address array as a third parameter. Use
     * `modulesCustomMixins[token][module]` to access the whole array of Mixin
     * addresses applied to the module.
     */
    function modulesCustomMixins(
        address token,
        address module,
        uint256 index
    ) external view returns (address);

    /**
     * @return An array of the addresses of the Mixins to be applied to
     * transactions of a particular token originating from a particular module.
     * If an empty array is returned, then the module is not allowed to call
     * transactions for that token.
     * @param token Address of the token
     * @param module Address of the module
     */
    function moduleRequirements(address token, address module)
        external
        view
        returns (address[] memory);

    /**
     * Updates whether a module is allowed to call transactions for a given
     * token, subject to the token's default Mixins.
     *
     * Emits a `ModuleDefaultMixinsUpdated` event iff a change was made.
     *
     * Requirements:
     * - The caller must be the token owner.
     * - The GuardMixinManager's settings must be unlocked.
     * @param token Address of the token
     * @param module Address of the module
     * @param allowed True if the module should be allowed to call token
     * transactions subject to the conditions in the token's default Mixins.
     * False if the module should not be allowed, or if the module should
     * instead be subject to the conditions of a custom list of Mixins.
     */
    function updateModule(
        address token,
        address module,
        bool allowed
    ) external;

    /**
     * Updates the list of Mixins expressing the conditions to be applied to any allowed module by default.
     *
     * Emits a `DefaultMixinsUpdated` event.
     *
     * Requirements:
     * - The caller must be the token owner.
     * - The GuardMixinManager's settings must be unlocked.
     * @param token Address of the token
     * @param mixins_ Array of addresses of the Mixins to be applied by
     * default. This replaces the current list of default Mixins (instead of
     * adding to it).
     */
    function updateDefaultMixins(address token, address[] calldata mixins_)
        external;

    /**
     * Updates the list of Mixins to apply to the specific module (instead of
     * the default Mixins).
     *
     * Emits a `ModuleCustomMixinsUpdated` event.
     *
     * Requirements:
     * - The caller must be the token owner.
     * - The GuardMixinManager's settings must be unlocked.
     * @param token Address of the token
     * @param module Address of the module
     * @param mixins_ Array of addresses of the Mixins to be applied to the
     * specific module (instead of the default mixins). This replaces the
     * current list of default Mixins (instead of adding to it). Passing in an
     * empty array will cause the module to use the default Mixins if
     * `modulesDefaultMixins` is true, or will disallow the module if
     * `modulesDefaultMixins` is false.
     */
    function updateModuleMixins(
        address token,
        address module,
        address[] calldata mixins_
    ) external;
}

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}

interface IBatcher {
    function batchOperator() external view returns (address);
}

/**
 * Mixin giving the token (i.e. club/collective) owner the ability to lock
 * certain Guard functions (such as `updateConfig`) via the `canEditSettings`
 * modifier.
 */
abstract contract LockableSettings {
    // The address of the Batcher allowed to edit settings
    address public batcher;
    // token => locked
    mapping(address => bool) public hasLockedSettings;

    event SettingsLocked(address indexed token);

    constructor(address _batcher) {
        batcher = _batcher;
    }

    /**
     * Check whether token settings can be edited
     */
    modifier canEditSettings(address token) {
        _isOwnerOfAndSettingsUnlocked(token);
        _;
    }

    /**
     * Check that the caller is the token owner (or the token owner calling a
     * batch transaction) and settings are unlocked.
     *
     * Requirements:
     * - Settings must be unlocked.
     * - The caller must be the owner or the batcher (operated by the
     * owner).
     * @param token Address of token
     */
    function _isOwnerOfAndSettingsUnlocked(address token) internal view {
        require(
            !hasLockedSettings[token] &&
                (msg.sender == Ownable(token).owner() ||
                    (msg.sender == batcher &&
                        IBatcher(msg.sender).batchOperator() ==
                        Ownable(token).owner())),
            "LockableSettings: cannot edit"
        );
    }

    /**
     * Enable a token to irreversibly lock their settings to further changes.
     * Locking settings does not impact locks of the token's guards or
     * potential configurations of other used guard managers.
     * @param token Address of token
     */
    function lockSettings(address token) public canEditSettings(token) {
        hasLockedSettings[token] = true;
        emit SettingsLocked(token);
    }
}

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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

interface IOwner {
    function owner() external view returns (address);
}

/**
 * Utility for use by any module or guard that needs to check if an address is
 * the owner of the TokenEnforceable (ERC20Club or ERC721Collective)
 */

abstract contract TokenOwnerChecker {
    /**
     * Only proceed if msg.sender owns TokenEnforceable contract
     * @param token TokenEnforceable whose owner to check
     */
    modifier onlyTokenOwner(address token) {
        _onlyTokenOwner(token);
        _;
    }

    function _onlyTokenOwner(address token) internal view {
        require(
            msg.sender == IOwner(token).owner(),
            "TokenOwnerChecker: Caller not token owner"
        );
    }
}

interface ITokenRecoverable {
    // Events for token recovery (ERC20) and (ERC721)
    event TokenRecoveredERC20(
        address indexed recipient,
        address indexed erc20,
        uint256 amount
    );
    event TokenRecoveredERC721(
        address indexed recipient,
        address indexed erc721,
        uint256 tokenId
    );

    /**
     * Allows the owner of an ERC20Club or ERC721Collective to return
     * any ERC20 tokens erroneously sent to the contract.
     *
     * Emits a `TokenRecoveredERC20` event.
     *
     * Requirements:
     * - The caller must be the (Club or Collective) token contract owner.
     * ERC20 token(s) (directly or via e.g. a module)
     * @param recipient Address that erroneously sent the ERC20 token(s)
     * @param erc20 Erroneously-sent ERC20 token to recover
     * @param amount Amount to recover
     */
    function recoverERC20(
        address recipient,
        address erc20,
        uint256 amount
    ) external;

    /**
     * Allows the owner of an ERC20Club or ERC721Collective to return
     * any ERC721 tokens erroneously sent to the contract.
     *
     * Emits a `TokenRecoveredERC721` event.
     *
     * Requirements:
     * - The caller must be the (Club or Collective) token contract owner.
     * ERC721 token (directly or via e.g. a module)
     * @param recipient Address that erroneously sent the ERC721 token
     * @param erc721 Erroneously-sent ERC721 token to recover
     * @param tokenId The tokenId to recover
     */
    function recoverERC721(
        address recipient,
        address erc721,
        uint256 tokenId
    ) external;
}

abstract contract TokenRecoverable is TokenOwnerChecker, ITokenRecoverable {
    // Using safeTransfer since interacting with other ERC20s
    using SafeERC20 for IERC20;

    address public admin;

    constructor(address _admin) {
        admin = _admin;
    }

    modifier isAdmin() {
        require(msg.sender == admin, "TokenRecoverable: Caller not admin");
        _;
    }

    /**
     * Only allows a syndicate address to access any ERC20 tokens erroneously sent to the contract.
     *
     * Emits a `TokenRecoveredERC20` event.
     *
     * Requirements:
     * - None
     * @param recipient Address that erroneously sent the ERC20 token(s)
     * @param erc20 Erroneously-sent ERC20 token to recover
     * @param amount Amount to recover
     */
    function recoverERC20(
        address recipient,
        address erc20,
        uint256 amount
    ) external isAdmin {
        IERC20(erc20).safeTransfer(recipient, amount);
        emit TokenRecoveredERC20(recipient, erc20, amount);
    }

    /**
     * Only allows a syndicate address to access any ERC721 tokens erroneously sent to the contract.
     *
     * Emits a `TokenRecoveredERC721` event.
     *
     * Requirements:
     * - None
     * @param recipient Address that erroneously sent the ERC721 token
     * @param erc721 Erroneously-sent ERC721 token to recover
     * @param tokenId The tokenId to recover
     */
    function recoverERC721(
        address recipient,
        address erc721,
        uint256 tokenId
    ) external isAdmin {
        IERC721(erc721).transferFrom(address(this), recipient, tokenId);
        emit TokenRecoveredERC721(recipient, erc721, tokenId);
    }
}

/**
 * A Guard that aggregates modular transaction requirements ("Mixins").
 */
contract GuardMixinManager is
    IGuardMixinManager,
    LockableSettings,
    TokenRecoverable
{
    // Token address => addresses of Mixins to apply to all allowed modules
    // subject to default Mixins
    mapping(address => address[]) public defaultMixins;

    // Token address => module address => true if the module is allowed AND
    // subject to default Mixins
    mapping(address => mapping(address => bool)) public modulesDefaultMixins;

    // Token address => module address => addresses of Mixins to apply to the
    // specific module (instead of the default Mixins), or an empty array if
    // the module does not have a custom list of Mixins to apply
    mapping(address => mapping(address => address[]))
        public modulesCustomMixins;

    constructor(address _batcher, address admin)
        LockableSettings(_batcher)
        TokenRecoverable(admin)
    {}

    /**
     * @return An array of the addresses of the Mixins to be applied to
     * transactions of a particular token originating from a particular module.
     * If an empty array is returned, then the module is not allowed to call
     * transactions for that token.
     * @param token Address of the token
     * @param module Address of the module
     */
    function moduleRequirements(address token, address module)
        public
        view
        returns (address[] memory)
    {
        if (modulesCustomMixins[token][module].length > 0) {
            return modulesCustomMixins[token][module];
        } else if (modulesDefaultMixins[token][module]) {
            return defaultMixins[token];
        }

        return new address[](0);
    }

    /**
     * Updates whether a module is allowed to call transactions for a given
     * token, subject to the token's default Mixins.
     *
     * Emits a `ModuleDefaultMixinsUpdated` event iff a change was made.
     *
     * Requirements:
     * - The caller must be the token owner.
     * - The GuardMixinManager's settings must be unlocked.
     * @param token Address of the token
     * @param module Address of the module
     * @param allowed True if the module should be allowed to call token
     * transactions subject to the conditions in the token's default Mixins.
     * False if the module should not be allowed, or if the module should
     * instead be subject to the conditions of a custom list of Mixins.
     */
    function updateModule(
        address token,
        address module,
        bool allowed
    ) external canEditSettings(token) {
        if (modulesDefaultMixins[token][module] != allowed) {
            modulesDefaultMixins[token][module] = allowed;
            emit ModuleDefaultMixinsUpdated(token, module, allowed);
        }
    }

    /**
     * Updates the list of Mixins expressing the conditions to be applied to any allowed module by default.
     *
     * Emits a `DefaultMixinsUpdated` event.
     *
     * Requirements:
     * - The caller must be the token owner.
     * - The GuardMixinManager's settings must be unlocked.
     * @param token Address of the token
     * @param mixins_ Array of addresses of the Mixins to be applied by
     * default. This replaces the current list of default Mixins (instead of
     * adding to it).
     */
    function updateDefaultMixins(address token, address[] calldata mixins_)
        external
        canEditSettings(token)
    {
        defaultMixins[token] = mixins_;
        emit DefaultMixinsUpdated(token, mixins_);
    }

    /**
     * Updates the list of Mixins to apply to the specific module (instead of
     * the default Mixins).
     *
     * Emits a `ModuleCustomMixinsUpdated` event.
     *
     * Requirements:
     * - The caller must be the token owner.
     * - The GuardMixinManager's settings must be unlocked.
     * @param token Address of the token
     * @param module Address of the module
     * @param mixins_ Array of addresses of the Mixins to be applied to the
     * specific module (instead of the default mixins). This replaces the
     * current list of default Mixins (instead of adding to it). Passing in an
     * empty array will cause the module to use the default Mixins if
     * `modulesDefaultMixins` is true, or will disallow the module if
     * `modulesDefaultMixins` is false.
     */
    function updateModuleMixins(
        address token,
        address module,
        address[] calldata mixins_
    ) external canEditSettings(token) {
        modulesCustomMixins[token][module] = mixins_;
        emit ModuleCustomMixinsUpdated(token, module, mixins_);
    }

    /**
     * @return True iff the transaction by a particular operator, from a
     * particular sender (`from` is address 0 iff the token is being minted),
     * to a particular recipient (`to` is address 0 iff the token is being
     * burned) is allowed by ALL applicable Mixins. False otherwise.
     * @param operator Transaction msg.sender
     * @param from Token sender
     * @param to Token recipient
     * @param value Amount (ERC20) or token ID (ERC721)
     */
    function isAllowed(
        address operator,
        address from,
        address to,
        uint256 value
    ) external view override returns (bool) {
        address[] memory mixins_ = moduleRequirements(msg.sender, operator);

        if (mixins_.length != 0) {
            uint256 length = mixins_.length;
            for (uint256 i = 0; i < length; ) {
                if (
                    !IGuardMixin(mixins_[i]).isAllowed(
                        msg.sender,
                        operator,
                        from,
                        to,
                        value
                    )
                ) {
                    return false;
                }
                unchecked {
                    ++i;
                }
            }

            return true;
        }

        return false;
    }

    /** This function is called for all messages sent to this contract (there
     * are no other functions). Sending Ether to this contract will cause an
     * exception, because the fallback function does not have the `payable`
     * modifier.
     * Source: https://docs.soliditylang.org/en/v0.8.9/contracts.html?highlight=fallback#fallback-function
     */
    fallback() external {
        revert("GuardMixinManager: non-existent function");
    }
}