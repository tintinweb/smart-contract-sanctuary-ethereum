/**
 *Submitted for verification at Etherscan.io on 2022-09-15
*/

// SPDX-License-Identifier: GPL-3.0
 
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)
pragma solidity ^0.8.0;
 
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
 
// File: @openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol
 
 
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)
 
pragma solidity ^0.8.0;
 
 
/**
* @dev Implementation of the {IERC721Receiver} interface.
*
* Accepts all token transfers.
* Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
*/
contract ERC721Holder is IERC721Receiver {
   /**
    * @dev See {IERC721Receiver-onERC721Received}.
    *
    * Always returns `IERC721Receiver.onERC721Received.selector`.
    */
   function onERC721Received(
       address,
       address,
       uint256,
       bytes memory
   ) public virtual override returns (bytes4) {
       return this.onERC721Received.selector;
   }
}
 
// File: @openzeppelin/contracts/utils/introspection/IERC165.sol
 
 
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
 
// File: @openzeppelin/contracts/token/ERC721/IERC721.sol
 
 
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)
 
pragma solidity ^0.8.0;
 
 
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
 
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol
 
 
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
 
// File: @openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol
 
 
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
 
// File: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol
 
 
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)
 
pragma solidity ^0.8.2;
 
 
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
 
// File: @openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol
 
 
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
 
// File: @openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol
 
 
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)
 
pragma solidity ^0.8.0;
 
 
 
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
 
// File: @openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol
 
 
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)
 
pragma solidity ^0.8.0;
 
 
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
 
   function __ReentrancyGuard_init() internal onlyInitializing {
       __ReentrancyGuard_init_unchained();
   }
 
   function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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
 
   /**
    * @dev This empty reserved space is put in place to allow future versions to add new
    * variables without shifting down storage in the inheritance chain.
    * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    */
   uint256[49] private __gap;
}
 
 
/// @title Interface for Player Zero Token
pragma solidity ^0.8.6;
 
abstract contract PLAYERZEROTOKEN is IERC721  {
 function mintToken() external virtual;
 function totalSupply() external view virtual returns (uint256);
}
 
/// @title Interface for Player Zero Auction
pragma solidity ^0.8.6;
 
interface PlayerZeroAuction {
 
   event AuctionCreated(uint256 indexed currentToken, uint256 startTime, uint256 endTime);
 
   event AuctionBid(uint256 indexed currentToken, address sender, uint256 value, bool extended);
 
   event AuctionExtended(uint256 indexed currentToken, uint256 endTime);
 
   event AuctionSettled(uint256 indexed currentToken, address winner, uint256 amount);
 
   event AuctionTimeBufferUpdated(uint256 timeBuffer);
 
   event AuctionReservePriceUpdated(uint256 reservePrice);
 
   event AuctionMinBidIncrementPercentageUpdated(uint256 minBidIncrementPercentage);
 
   function settleAuction() external;
 
   function settleCurrentAndCreateNewAuction() external;
 
   function createBid(uint256 token) external payable;
 
   function setTimeBuffer(uint256 timeBuffer) external;
 
   function setReservePrice(uint256 reservePrice) external;
 
   function setMinBidIncrementPercentage(uint8 minBidIncrementPercentage) external;
}
 
/// @title IWETH
pragma solidity ^0.8.6;
 
interface IWETH {
   function deposit() external payable;
 
   function withdraw(uint256 wad) external;
 
   function transfer(address to, uint256 value) external returns (bool);
}
 
// LICENSE
// PlayerZeroAuction.sol is a modified version of Zora's AuctionHouse.sol:
// https://github.com/ourzora/auction-house/blob/54a12ec1a6cf562e49f0a4917990474b11350a2d/contracts/AuctionHouse.sol
//
// PlayerZeroAuction.sol source code Copyright Zora licensed under the GPL-3.0 license.
// With modifications by PlayerZero.
 
/// @title The PlayerZero Auction House
contract PlayerZeroAuctionHouse is PlayerZeroAuction, ReentrancyGuardUpgradeable, OwnableUpgradeable, ERC721Holder {
   // The PlayerZero ERC721 token contract
   PLAYERZEROTOKEN public playerzero;
 
   // The status of the auction
   bool public auctionStatus;
 
   // The address of the WETH contract
   address public weth;
 
   // The address of the admin wallet
   address public adminWallet;
 
   // The minimum amount of time left in an auction after a new bid is created
   uint256 public timeBuffer;
 
   // The minimum price accepted in an auction
   uint256 public reservePrice;
 
   // The minimum percentage difference between the last bid amount and the current bid
   uint8 public minBidIncrementPercentage;
 
   // The duration of a single auction
   uint256 public duration;
 
   // ID for the Player Zero (ERC721 token ID)
   uint256 public currentToken;
 
   // The current highest bid amount
   uint256 public amount;
 
   // The time that the auction started
   uint256 public startTime;
 
   // The time that the auction is scheduled to end
   uint256 public endTime;
 
   // The address of the current highest bid
   address payable  public bidder;
 
   // Whether or not the auction has been settled
   bool public settled;
 
   // The address of the winning bid based on any token
   mapping(uint256 => address) public getWinningBidders;
 
   // The amount of the winning bid based on any token
   mapping(uint256 => uint256) public getWinningAmount;
 
   /**
    * @notice Initialize the auction house and base contracts,
    * @dev This function can only be called once.
    */
   function initialize(
       PLAYERZEROTOKEN _playerzero,
       address _weth,
       address _adminWallet,
       uint256 _timeBuffer,
       uint256 _reservePrice,
       uint8 _minBidIncrementPercentage,
       uint256 _duration
   ) external initializer {
       __ReentrancyGuard_init();
       __Ownable_init();
       auctionStatus = false;
       playerzero = _playerzero;
       weth = _weth;
       adminWallet = _adminWallet;
       timeBuffer = _timeBuffer;
       reservePrice = _reservePrice;
       minBidIncrementPercentage = _minBidIncrementPercentage;
       duration = _duration;
   }
 
   ///////////////////////////
   // BIDDING FUNCTIONALITY //
   ///////////////////////////
 
   /**
    * @notice Create a bid for a Token, with a given amount.
    * @dev This contract only accepts payment in ETH.
    */
   function createBid(uint256 token) external payable override nonReentrant {
 
       require(currentToken == token, "Token not up for auction");
       require(block.timestamp < endTime, "Auction expired");
       require(msg.value >= reservePrice, "Must send at least reservePrice");
       require(
           msg.value >= amount + ((amount * minBidIncrementPercentage) / 100),
           "Must send more than last bid by minBidIncrementPercentage amount"
       );
 
       address payable lastBidder = bidder;
 
       // Refund the last bidder, if applicable
       if (lastBidder != address(0)) {
           _safeTransferETHWithFallback(lastBidder, amount);
       }
 
       amount = msg.value;
       bidder = payable(msg.sender);
 
       // Extend the auction if the bid was received within `timeBuffer` of the auction end time
       bool extended = endTime - block.timestamp < timeBuffer;
       if (extended) {
           endTime = block.timestamp + timeBuffer;
       }
 
       emit AuctionBid(currentToken, msg.sender, msg.value, extended);
 
       if (extended) {
           emit AuctionExtended(currentToken, endTime);
       }
   }
 
   ////////////////////////////
   // EXTERNAL FUNCTIONALITY //
   ////////////////////////////
 
 
   /**
    * @notice Settle the current auction.
    * @dev This function can only be called when the contract is off and by  owner.
    */
   function settleAuction() external override nonReentrant onlyOwner {
       require(!auctionStatus, "Auction is on");
       _settleAuction();
   }
 
   /**
    * @notice create an current auction.
    * @dev This function can only be called when the contract is off and by owner
    */
   function createAuction() external nonReentrant onlyOwner {
       require(!auctionStatus, "Auction is on");
       _createAuction();
       auctionStatus = true;
   }
 
   /**
    * @notice Settle the current auction, mint a new Token, and put it up for auction.
    * @dev This function can only be called when the contract is on.
    */
   function settleCurrentAndCreateNewAuction() external override nonReentrant {
       require(auctionStatus, "Auction is not on");
       _settleAuction();
       _createAuction();
   }
 
   /**
    * @notice Calls total supply on token contract
    */
   function getNextTokenID() external view returns (uint256) {
       return playerzero.totalSupply();
   }
 
   /**
    * @notice Calls total supply on token contract and subtracts 1 for current auction
    */
   function getCurrentTokenID() external view returns (uint256) {
       return playerzero.totalSupply() - 1;
   }
 
   /**
    * @notice Calls Remaing time of the current auction
    */
   function getRemainingTime() external view returns (uint256) {
       return endTime - block.timestamp;
   }
 
   /**
    * @notice Calls block timestamp
    */
   function getBockTimestamp() external view returns (uint256) {
       return block.timestamp;
   }
 
   ////////////////////////////
   // INTERNAL FUNCTIONALITY //
   ////////////////////////////
 
   /**
    * @notice Create an auction.
    * @dev Store the auction details in the `auction` state variable and emit an AuctionCreated event.
    */
   function _createAuction() internal {
       currentToken = playerzero.totalSupply();
       playerzero.mintToken();
       startTime = block.timestamp;
       endTime = startTime + duration;
       amount =  0;
       bidder =  payable(0);
       settled = false;
       emit AuctionCreated(currentToken, startTime, endTime);
   }
 
   /**
    * @notice Settle an auction, finalizing the bid and paying out to the owner.
    */
   function _settleAuction() internal {
       require(startTime != 0, "Auction hasn't begun");
       require(!settled, "Auction has already been settled");
       require(block.timestamp >= endTime, "Auction hasn't completed");
 
       settled = true;
      
 
       if (bidder == address(0)) {
           playerzero.transferFrom(address(this), adminWallet, currentToken);
       } else {
           playerzero.transferFrom(address(this), bidder, currentToken);
           getWinningBidders[currentToken] = bidder;
       }
 
       if (amount > 0) {
           _safeTransferETHWithFallback(adminWallet, amount);
           getWinningAmount[currentToken] = amount;
       }
 
       emit AuctionSettled(currentToken, bidder, amount);
   }
 
   /**
    * @notice Transfer ETH. If the ETH transfer fails, wrap the ETH and try send it as WETH.
    */
   function _safeTransferETHWithFallback(address to, uint256 value) internal {
       if (!_safeTransferETH(to, value)) {
           IWETH(weth).deposit{ value: value }();
           IERC20(weth).transfer(to, value);
       }
   }
 
   /**
    * @notice Transfer ETH and return the success status.
    * @dev This function only forwards 30,000 gas to the callee.
    */
   function _safeTransferETH(address to, uint256 value) internal returns (bool) {
       (bool success, ) = to.call{ value: value, gas: 30_000 }(new bytes(0));
       return success;
   }
 
   /////////////////////////
   // ADMIN FUNCTIONALITY //
   /////////////////////////
 
   /**
    * @notice turns off the Player Zero auction house.
    * @dev This function can only be called by the owner when the
    * contract is on. While no new auctions can be started when the contract is on,
    * anyone can settle an ongoing auction.
    */
   function stopAuction() external onlyOwner {
       require(auctionStatus, "Auction is not on");
       auctionStatus = false;
   }
 
   /**
    * @notice turns on the Player Zero auction house.
    * @dev This function can only be called by the owner when the
    * contract is not on. If required, this function will start a new auction.
    */
   function startAuction() external onlyOwner {
       require(!auctionStatus, "Auction is on");
       _createAuction();
       auctionStatus = true;
   }
 
   /**
    * @notice Set the auction time buffer.
    * @dev Only callable by the owner.
    */
   function setTimeBuffer(uint256 _timeBuffer) external override onlyOwner {
       timeBuffer = _timeBuffer;
 
       emit AuctionTimeBufferUpdated(_timeBuffer);
   }
 
   /**
    * @notice Set the auction reserve price.
    * @dev Only callable by the owner.
    */
   function setReservePrice(uint256 _reservePrice) external override onlyOwner {
       reservePrice = _reservePrice;
 
       emit AuctionReservePriceUpdated(_reservePrice);
   }
 
   /**
    * @notice Set the admin wallet.
    * @dev Only callable by the owner.
    */
   function setAdminWallet(address _wallet) external onlyOwner {
       adminWallet = _wallet;
   }
 
   /**
    * @notice Set the auction minimum bid increment percentage.
    * @dev Only callable by the owner.
    */
   function setMinBidIncrementPercentage(uint8 _minBidIncrementPercentage) external override onlyOwner {
       minBidIncrementPercentage = _minBidIncrementPercentage;
 
       emit AuctionMinBidIncrementPercentageUpdated(_minBidIncrementPercentage);
   }
 
}