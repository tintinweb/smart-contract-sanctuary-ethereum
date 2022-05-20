// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IMarketRegistry.sol";
import "./interfaces/IUserManager.sol";
import "./interfaces/IUToken.sol";

/**
 * @title BaseUnionMember Contract
 * @dev This contract has the basic functions of Union member.
 */
abstract contract BaseUnionMember {
    IMarketRegistry public immutable marketRegistry;
    IUserManager public immutable userManager;
    IUToken public immutable uToken;
    IERC20 public immutable unionToken;
    IERC20 public immutable underlyingToken;

    /**
     *  @dev Constructor
     *  @param _marketRegistry Union's MarketRegistry contract address
     *  @param _unionToken UNION token address
     *  @param _underlyingToken Underlying asset address
     */
    constructor(address _marketRegistry, address _unionToken, address _underlyingToken) {
        (address _uToken, address _userManager) = IMarketRegistry(_marketRegistry).tokens(_underlyingToken);
        marketRegistry = IMarketRegistry(_marketRegistry);
        userManager = IUserManager(_userManager);
        uToken = IUToken(_uToken);
        unionToken = IERC20(_unionToken);
        underlyingToken = IERC20(_underlyingToken);
    }

    /**
     *  @dev Return member's status
     *  @return Member's status
     */
    function isMember() public view returns (bool) {
        return userManager.checkIsMember(address(this));
    }

    /**
     *  @dev Register to become a Union member
     */
    function _registerMember() internal {
        uint256 newMemberFee = userManager.newMemberFee();
        unionToken.approve(address(userManager), newMemberFee);
        userManager.registerMember(address(this));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IMarketRegistry.sol";
import "./interfaces/IUserManager.sol";
import "./BaseUnionMember.sol";


/**
 * @title UnionVoucher Contract
 * @dev This contract has all the functions of Union voucher role.
 */
abstract contract UnionVoucher is BaseUnionMember{
    /**
     *  @dev Get all the addresses the user vouched for
     *  @return List of ddresses the user vouched for
     */
    function getBorrowerAddresses() public view returns (address[] memory) {
        return userManager.getBorrowerAddresses(address(this));
    }
    
    /**
     *  @dev Get user's staking amount
     *  @return Staking amount (in wei)
     */
    function getStakerBalance() public view returns (uint256) {
        return userManager.getStakerBalance(address(this));
    }

    /**
     *  @dev Set the vouching amount for another user
     *  @param account Recipient address
     *  @param amount Amount to vouch for (in wei)
     */
    function _updateTrust(address account, uint256 amount) internal {
        userManager.updateTrust(account, amount);
    }

    /**
     *  @dev Stop vouching for another one
     *  @param staker Voucher's address
     *  @param borrower Recipient address
     */
    function _cancelVouch(address staker, address borrower) internal {
        userManager.cancelVouch(staker, borrower);
    }

    /**
     *  @dev Deposit to Union
     *  @param amount Amount to stake (in wei)
     */
    function _stake(uint256 amount) internal {
        underlyingToken.approve(address(userManager), amount);
        userManager.stake(amount);
    }

    /**
     *  @dev Withdraw from Union
     *  @param amount Amount to unstake (in wei)
     */
    function _unstake(uint256 amount) internal {
        userManager.unstake(amount);
    }

    /**
     *  @dev Claim the rewarded UNION tokens
     */
    function _withdrawRewards() internal {
        userManager.withdrawRewards();
    }
    
    /**
     *  @dev Write off voucher's bad debt
     *  @param borrower Borrower's address
     *  @param amount Amount of debt to write off (in wei)
     */
    function _debtWriteOff(address borrower, uint256 amount) internal {
        userManager.debtWriteOff(borrower, amount);
    } 
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @title MarketRegistry Interface
 * @dev Registering and managing all the lending markets.
 */
interface IMarketRegistry {
    function getUTokens() external view returns (address[] memory);

    function getUserManagers() external view returns (address[] memory);

    /**
     *  @dev Returns the market address of the token
     *  @return The market address
     */
    function tokens(address token) external view returns (address, address);

    function createUToken(
        address token,
        address assetManager,
        uint256 originationFee,
        uint256 globalMaxLoan,
        uint256 maxBorrow,
        uint256 minLoan,
        uint256 maxLateBlock,
        address interestRateModel
    ) external returns (address);

    function createUserManager(
        address assetManager,
        address unionToken,
        address stakingToken,
        address creditLimitModel,
        address inflationIndexModel,
        address comptroller
    ) external returns (address);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 *  @title UToken Interface
 *  @dev Union members can borrow and repay thru this component.
 */
interface IUToken {
    /**
     *  @dev Returns the remaining amount that can be borrowed from the market.
     *  @return Remaining total amount
     */
    function getRemainingDebtCeiling() external view returns (uint256);

    /**
     *  @dev Get the borrowed principle
     *  @param account Member address
     *  @return Borrowed amount
     */
    function getBorrowed(address account) external view returns (uint256);

    /**
     *  @dev Get the last repay block
     *  @param account Member address
     *  @return Block number
     */
    function getLastRepay(address account) external view returns (uint256);

    /**
     *  @dev Get member interest index
     *  @param account Member address
     *  @return Interest index
     */
    function getInterestIndex(address account) external view returns (uint256);

    /**
     *  @dev Check if the member's loan is overdue
     *  @param account Member address
     *  @return Check result
     */
    function checkIsOverdue(address account) external view returns (bool);

    /**
     *  @dev Get the borrowing interest rate per block
     *  @return Borrow rate
     */
    function borrowRatePerBlock() external view returns (uint256);

    /**
     *  @dev Get the origination fee
     *  @param amount Amount to be calculated
     *  @return Handling fee
     */
    function calculatingFee(uint256 amount) external view returns (uint256);

    /**
     *  @dev Calculating member's borrowed interest
     *  @param account Member address
     *  @return Interest amount
     */
    function calculatingInterest(address account) external view returns (uint256);

    /**
     *  @dev Get a member's current owed balance, including the principle and interest but without updating the user's states.
     *  @param account Member address
     *  @return Borrowed amount
     */
    function borrowBalanceView(address account) external view returns (uint256);

    /**
     *  @dev Change loan origination fee value
     *  Accept claims only from the admin
     *  @param originationFee_ Fees deducted for each loan transaction
     */
    function setOriginationFee(uint256 originationFee_) external;

    /**
     *  @dev Update the market debt ceiling to a fixed amount, for example, 1 billion DAI etc.
     *  Accept claims only from the admin
     *  @param debtCeiling_ The debt limit for the whole system
     */
    function setDebtCeiling(uint256 debtCeiling_) external;

    /**
     *  @dev Update the max loan size
     *  Accept claims only from the admin
     *  @param maxBorrow_ Max loan amount per user
     */
    function setMaxBorrow(uint256 maxBorrow_) external;

    /**
     *  @dev Update the minimum loan size
     *  Accept claims only from the admin
     *  @param minBorrow_ Minimum loan amount per user
     */
    function setMinBorrow(uint256 minBorrow_) external;

    /**
     *  @dev Change loan overdue duration, based on the number of blocks
     *  Accept claims only from the admin
     *  @param overdueBlocks_ Maximum late repayment block. The number of arrivals is a default
     */
    function setOverdueBlocks(uint256 overdueBlocks_) external;

    /**
     *  @dev Change to a different interest rate model
     *  Accept claims only from the admin
     *  @param newInterestRateModel New interest rate model address
     */
    function setInterestRateModel(address newInterestRateModel) external;

    function setReserveFactor(uint256 reserveFactorMantissa_) external;

    function supplyRatePerBlock() external returns (uint256);

    function accrueInterest() external returns (bool);

    function balanceOfUnderlying(address owner) external returns (uint256);

    function mint(uint256 mintAmount) external;

    function redeem(uint256 redeemTokens) external;

    function redeemUnderlying(uint256 redeemAmount) external;

    function addReserves(uint256 addAmount) external;

    function removeReserves(address receiver, uint256 reduceAmount) external;

    /**
     *  @dev Borrowing from the market
     *  Accept claims only from the member
     *  Borrow amount must in the range of creditLimit, minLoan, debtCeiling and not overdue
     *  @param amount Borrow amount
     */
    function borrow(uint256 amount) external;

    /**
     *  @dev Repay the loan
     *  Accept claims only from the member
     *  Updated member lastPaymentEpoch only when the repayment amount is greater than interest
     *  @param amount Repay amount
     */
    function repayBorrow(uint256 amount) external;

    /**
     *  @dev Repay the loan
     *  Accept claims only from the member
     *  Updated member lastPaymentEpoch only when the repayment amount is greater than interest
     *  @param borrower Borrower address
     *  @param amount Repay amount
     */
    function repayBorrowBehalf(address borrower, uint256 amount) external;

    /**
     *  @dev Update borrower overdue info
     *  @param account Borrower address
     */
    function updateOverdueInfo(address account) external;

    /**
     *  @dev debt write off
     *  @param borrower Borrower address
     *  @param amount WriteOff amount
     */
    function debtWriteOff(address borrower, uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @title UserManager Interface
 * @dev Manages the Union members credit lines, and their vouchees and borrowers info.
 */
interface IUserManager {
    /**
     *  @dev Check if the account is a valid member
     *  @param account Member address
     *  @return Address whether is member
     */
    function checkIsMember(address account) external view returns (bool);

    /**
     *  @dev Get member borrowerAddresses
     *  @param account Member address
     *  @return Address array
     */
    function getBorrowerAddresses(address account) external view returns (address[] memory);

    /**
     *  @dev Get member stakerAddresses
     *  @param account Member address
     *  @return Address array
     */
    function getStakerAddresses(address account) external view returns (address[] memory);

    /**
     *  @dev Get member backer asset
     *  @param account Member address
     *  @param borrower Borrower address
     *  @return Trust amount, vouch amount, and locked stake amount
     */
    function getBorrowerAsset(address account, address borrower)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    /**
     *  @dev Get member stakers asset
     *  @param account Member address
     *  @param staker Staker address
     *  @return Vouch amount and lockedStake
     */
    function getStakerAsset(address account, address staker)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    /**
     *  @dev Get the member's available credit line
     *  @param account Member address
     *  @return Limit
     */
    function getCreditLimit(address account) external view returns (int256);

    function totalStaked() external view returns (uint256);

    function totalFrozen() external view returns (uint256);

    function newMemberFee() external view returns (uint256);

    function getFrozenCoinAge(address staker, uint256 pastBlocks) external view returns (uint256);

    /**
     *  @dev Add a new member
     *  Accept claims only from the admin
     *  @param account Member address
     */
    function addMember(address account) external;

    
    function withdrawRewards() external;

    /**
     *  @dev Update the trust amount for exisitng members.
     *  @param borrower Borrower address
     *  @param trustAmount Trust amount
     */
    function updateTrust(address borrower, uint256 trustAmount) external;

    /**
     *  @dev Apply for membership, and burn UnionToken as application fees
     *  @param newMember New member address
     */
    function registerMember(address newMember) external;

    /**
     *  @dev Stop vouch for other member.
     *  @param staker Staker address
     *  @param account Account address
     */
    function cancelVouch(address staker, address account) external;

    /**
     *  @dev Change the credit limit model
     *  Accept claims only from the admin
     *  @param newCreditLimitModel New credit limit model address
     */
    function setCreditLimitModel(address newCreditLimitModel) external;

    /**
     *  @dev Get the user's locked stake from all his backed loans
     *  @param staker Staker address
     *  @return LockedStake
     */
    function getTotalLockedStake(address staker) external view returns (uint256);

    /**
     *  @dev Get staker's defaulted / frozen staked token amount
     *  @param staker Staker address
     *  @return Frozen token amount
     */
    function getTotalFrozenAmount(address staker) external view returns (uint256);

    /**
     *  @dev Update userManager locked info
     *  @param borrower Borrower address
     *  @param amount Borrow or repay amount(Including previously accrued interest)
     *  @param isBorrow True is borrow, false is repay
     */
    function updateLockedData(
        address borrower,
        uint256 amount,
        bool isBorrow
    ) external;

    /**
     *  @dev Get the user's deposited stake amount
     *  @param account Member address
     *  @return Deposited stake amount
     */
    function getStakerBalance(address account) external view returns (uint256);

    /**
     *  @dev Stake
     *  @param amount Amount
     */
    function stake(uint256 amount) external;

    /**
     *  @dev Unstake
     *  @param amount Amount
     */
    function unstake(uint256 amount) external;

    /**
     *  @dev Update total frozen
     *  @param account borrower address
     *  @param isOverdue account is overdue
     */
    function updateTotalFrozen(address account, bool isOverdue) external;

    function batchUpdateTotalFrozen(address[] calldata account, bool[] calldata isOverdue) external;

    /**
     *  @dev Repay user's loan overdue, called only from the lending market
     *  @param account User address
     *  @param lastRepay Last repay block number
     */
    function repayLoanOverdue(
        address account,
        address token,
        uint256 lastRepay
    ) external;

    function debtWriteOff(address borrower, uint256 amount) external;

    function getVouchingAmount(address staker, address borrower) external view returns (uint256);    
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@unioncredit/v1-sdk/contracts/UnionVoucher.sol";

contract UnionQuest is Context, ERC165, IERC1155MetadataURI, Ownable, UnionVoucher {
    using Address for address;

    uint256 private constant SPEED_DIVISOR = 10;
    uint256 private constant SKILL_INCREASE_DIVISOR = 10;
    uint256 private constant TRUST_MODIFIER = 0.01 ether;
    uint256 private constant MIN_SKILL = 1;
    uint256 private constant MAX_SKILL = 3;

    struct ItemType {
        string name;
        string description;
        string symbol;
        uint256 stake;
        uint256[] toolIds;
    }

    struct Recipe {
        uint256[] inputIds;
        uint256[] inputQuantities;
        uint256 output;
    }

    struct Player {
        int256 startX;
        int256 startY;
        int256 endX;
        int256 endY;
        uint256 startTimestamp;
    }

    ItemType[] private itemTypes;
    Recipe[] private recipes;

    mapping(address => Player) private players;
    mapping(address => mapping(uint256 => uint256)) private skills;
    mapping(uint256 => mapping(address => uint256)) private _balances;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    event AddItemType(uint256 _index, ItemType _itemType);
    event AddRecipe(uint256 _index, Recipe _recipe);
    event Move(address account, int256 x, int256 y);
    event IncreaseSkill(address indexed account, uint256 id, uint256 value);

    constructor(
        address _marketRegistry,
        address _unionToken,
        address _underlyingToken
    ) BaseUnionMember(_marketRegistry, _unionToken, _underlyingToken) {}

    function uri(uint256 id) external view virtual override returns (string memory) {
        ItemType storage item = itemTypes[id];

        return
            string(
                abi.encodePacked('data:text/plain,{"name":"', item.name, '", "description":"', item.description, '"}')
            );
    }

    function balanceOf(address account, uint256 id) public view virtual override returns (uint256 balance) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");

        balance = _balances[id][account];

        Player storage player = players[account];

        uint256 tileItem = getItem(player.endX, player.endY);
        if (id == tileItem && hasTool(account, tileItem)) {
            int256 vX = player.endX - player.startX;
            int256 vY = player.endY - player.startY;

            uint256 distanceNeeded = uint256(sqrt(vX * vX + vY * vY));
            uint256 distanceTravelled = (block.timestamp - player.startTimestamp) / SPEED_DIVISOR;

            if (distanceTravelled >= distanceNeeded) {
                uint256 skillIncrease = (block.timestamp - (player.startTimestamp + distanceNeeded * SPEED_DIVISOR)) /
                    SKILL_INCREASE_DIVISOR;

                balance += skillIncrease * skills[_msgSender()][tileItem] + (skillIncrease * skillIncrease) / 2;
            }
        }
    }

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

    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        Player storage player = players[from];
        _move(_msgSender(), player.endX, player.endY);

        uint256 fromBalance = _balances[id][from];

        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

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

        Player storage player = players[from];
        _move(_msgSender(), player.endX, player.endY);

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

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        address operator = _msgSender();

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        address operator = _msgSender();

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
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
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function addItemTypes(ItemType[] memory _itemTypes) external onlyOwner {
        for (uint256 i; i < _itemTypes.length; i++) {
            itemTypes.push(_itemTypes[i]);
            emit AddItemType(itemTypes.length - 1, _itemTypes[i]);
        }
    }

    function addRecipes(Recipe[] memory _recipes) external onlyOwner {
        for (uint256 i; i < _recipes.length; i++) {
            recipes.push(_recipes[i]);
            emit AddRecipe(recipes.length - 1, _recipes[i]);
        }
    }

    function stake(uint256 amount) external onlyOwner {
        _stake(amount);
    }

    function unstake(uint256 amount) external onlyOwner {
        _unstake(amount);
    }

    function updateTrust(address borrower_) external {
        Player storage player = players[borrower_];
        _move(_msgSender(), player.endX, player.endY);

        uint256 totalSkill;
        for (uint256 i = MIN_SKILL; i < MAX_SKILL; i++) {
            totalSkill += skills[borrower_][i];
        }

        _updateTrust(borrower_, totalSkill * TRUST_MODIFIER);
    }

    function move(int256 x, int256 y) external {
        _move(_msgSender(), x, y);
    }

    function hasTool(address account, uint256 id) private view returns (bool) {
        for (uint256 i; i < itemTypes[id].toolIds.length; i++) {
            if (balanceOf(account, itemTypes[id].toolIds[i]) > 0) {
                return true;
            }
        }

        return false;
    }

    function _move(
        address account,
        int256 x,
        int256 y
    ) internal {
        Player storage player = players[account];

        int256 vX = player.endX - player.startX;
        int256 vY = player.endY - player.startY;

        uint256 distanceNeeded = uint256(sqrt(vX * vX + vY * vY));
        uint256 distanceTravelled = (block.timestamp - player.startTimestamp) / SPEED_DIVISOR;
        if (distanceTravelled < distanceNeeded) {
            player.startX += (vX * int256(distanceTravelled)) / int256(distanceNeeded);
            player.startY += (vY * int256(distanceTravelled)) / int256(distanceNeeded);
        } else {
            player.startX = player.endX;
            player.startY = player.endY;

            uint256 tileItem = getItem(player.endX, player.endY);
            if (hasTool(account, tileItem)) {
                uint256 skillIncrease = (block.timestamp - (player.startTimestamp + distanceNeeded * SPEED_DIVISOR)) /
                    SKILL_INCREASE_DIVISOR;

                _mint(
                    account,
                    tileItem,
                    skillIncrease * skills[account][tileItem] + (skillIncrease * skillIncrease) / 2,
                    ""
                );

                skills[account][tileItem] += skillIncrease;

                emit IncreaseSkill(account, tileItem, skillIncrease);
            }
        }

        player.endX = x;
        player.endY = y;
        player.startTimestamp = block.timestamp;

        emit Move(_msgSender(), x, y);
    }

    function buy(uint256 id, uint256 amount) external {
        ItemType storage item = itemTypes[id];

        require(item.stake > 0, "Item stake not set");

        Player storage player = players[_msgSender()];
        _move(_msgSender(), player.endX, player.endY);

        IERC20(underlyingToken).transferFrom(_msgSender(), address(this), item.stake * amount);
        _mint(_msgSender(), id, amount, "");
    }

    function sell(uint256 id, uint256 amount) external {
        ItemType storage item = itemTypes[id];

        require(item.stake > 0, "Item stake not set");

        Player storage player = players[_msgSender()];
        _move(_msgSender(), player.endX, player.endY);

        _burn(_msgSender(), id, amount);
        IERC20(underlyingToken).transfer(_msgSender(), item.stake * amount);
    }

    function craft(uint256 recipeId) external {
        Recipe storage recipe = recipes[recipeId];
        Player storage player = players[_msgSender()];

        _move(_msgSender(), player.endX, player.endY);
        for (uint256 i; i < recipe.inputIds.length; i++) {
            _burn(_msgSender(), recipe.inputIds[i], recipe.inputQuantities[i]);
        }

        _mint(_msgSender(), recipe.output, 1, "");
    }

    function sqrt(int256 x) private pure returns (int256 y) {
        int256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    function getItem(int256 x, int256 y) private pure returns (uint256) {
        if ((x == 0 && y == 0) || x > 10 || x < -9 || y > 10 || y < -9) {
            return 0;
        }

        uint256 res = uint256(keccak256(abi.encode(x, y))) % 5;
        if (res < 2) {
            return 0;
        } else if (res < 4) {
            return 1;
        }

        return 2;
    }
}