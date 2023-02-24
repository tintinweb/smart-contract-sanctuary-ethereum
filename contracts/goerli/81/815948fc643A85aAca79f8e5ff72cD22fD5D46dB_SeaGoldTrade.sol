/**
 *Submitted for verification at Etherscan.io on 2023-02-24
*/

/**
 *Submitted for verification at Etherscan.io on 2023-02-23
*/

/**
 *Submitted for verification at Etherscan.io on 2023-02-23
*/

// SPDX-License-Identifier: UNLICENSED
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

interface BuyBack {
    function getRewardsBL(uint256 amount)
        external
        view
        returns (uint256 totalBuyerRewards, uint256 sellerTradingRewards);

    function getRewardsAL(uint256 amount)
        external
        view
        returns (uint256 totalBuyerRewards, uint256 sellerTradingRewards);
}

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface RoyaltyRegistry {
    function getRoyaltyInfo(address _contractAddress)
        external
        view
        returns (
            bool,
            uint256,
            address,
            bool
        );
}

contract SeaGoldTrade is Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    address public SeaGoldToken;
    address public WETHtoken;
    uint256 public MinimumETHbalance;
    address public TreasuryAddress;
    address public royaltyRegistry;

    uint256 public test1;
    uint256 public test2;
    uint256 public test3;
    uint256 public test4;

    constructor(
        address _buyBackAddress,
        address _buyBackFeesAuthority,
        address _tokenAddress,
        address _seaGoldToken,
        address _royaltyRegistry
    ) {
        buyBackFee = 2 * 1e18;
        deci = 18;
        buyBackAddress = _buyBackAddress;
        buyBackFeesAuthority = _buyBackFeesAuthority;
        betaLaunched = false;
        tokenAddress = _tokenAddress;
        seaGoldToken = _seaGoldToken;
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = 0x9631967f7f37b0f6605FfB16006D2505DaFBAdEc;
        royaltyRegistry = _royaltyRegistry;
        MinimumETHbalance = 2 * 1e18;
        WETHtoken = 0x36ed7A4fd0101FB9F16a94070744FFc8b4e92364;
        TreasuryAddress = 0x80Aa595c83430288E3A75F4D03bE15b72385420F;
    }

    uint256 public buyBackFee;
    uint256 deci;
    address public buyBackFeesAuthority;
    address public buyBackAddress;
    bool public betaLaunched;
    address public tokenAddress;
    address public seaGoldToken;
    mapping(address => bool) blackListedAddresses;
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
    }

    royaltyInf royinf;

    receive() external payable {}

    function updatebuyBackFeesAuthority(address _buyBackFeesAuthority)
        public
        onlyOwner
    {
        buyBackFeesAuthority = _buyBackFeesAuthority;
    }

    function addToBlackListedAddresses(address[] memory _accounts)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _accounts.length; i++) {
            blackListedAddresses[_accounts[i]] = true;
        }
    }

    function removeFromBlackListedAddresses(address _account) public onlyOwner {
        blackListedAddresses[_account] = false;
    }

    function updateBetaLaunched(bool _betaLaunched) public onlyOwner {
        betaLaunched = _betaLaunched;
    }

    function updateSeaGoldTOken(address _tokenAddress) public onlyOwner {
        seaGoldToken = _tokenAddress;
    }

    function setbuyBackFee(uint256 _buyBackFee) public {
        require(msg.sender == buyBackFeesAuthority, "Not a authorized person");
        buyBackFee = _buyBackFee * 1e18;
    }

    function updateToken(address _tokenAddress) public onlyOwner {
        tokenAddress = _tokenAddress;
    }

    function updatebuyBackAddress(address payable _buyBackAddress)
        public
        onlyOwner
    {
        buyBackAddress = _buyBackAddress;
    }

    function updateMinimumETHbalance(uint256 _MinimumETHbalance)
        public
        onlyOwner
    {
        MinimumETHbalance = _MinimumETHbalance;
    }

    function updateTokenAddress(address _tokenAddress) public onlyOwner {
        SeaGoldToken = _tokenAddress;
    }

    function updateTreasuryAddress(address _treasuryAddress) public onlyOwner {
        TreasuryAddress = _treasuryAddress;
    }

    function updatePairAddress(address _pairAddress) public onlyOwner {
        uniswapV2Pair = _pairAddress;
    }

    function updateRouterAddress(address _routerAddress) public onlyOwner {
        uniswapV2Router = IUniswapV2Router02(_routerAddress);
    }

    function acceptBId(
        address bidaddr,
        uint256 amount,
        uint256 tokenId,
        uint256 nooftoken,
        uint256 nftType,
        address _conAddr
    ) public {
        // require(
        //     blackListedAddresses[msg.sender] == false &&
        //         blackListedAddresses[bidaddr] == false,
        //     "User BlackListed"
        // );

        // IERC20 t = IERC20(tokenAddress);
        // uint256 approveValue = t.allowance(bidaddr, address(this));
        // uint256 balance = t.balanceOf(bidaddr);
        // require(approveValue >= amount, "Insufficient Approved");
        // require(balance >= amount, "Insufficient Balance");

        // salestruct.user = bidaddr;
        // salestruct.amount = amount;
        // salestruct.seller = msg.sender;
        // salestruct.tokenId = tokenId;
        // salestruct.nftType = nftType;
        // salestruct.nooftoken = nooftoken;
        // salestruct.conAddr = _conAddr;

        // (
        //     uint256 netamount,
        //     uint256 adminfees,
        //     uint256 royalty
        // ) = calculaterewardsAndRoyaltyBid(
        //         salestruct.user,
        //         salestruct.amount,
        //         salestruct.seller,
        //         salestruct.conAddr
        //     );

        // require(
        //     adminfees + royalty + netamount <= salestruct.amount,
        //     "Amount is not equal"
        // );
        // RoyaltyRegistry royReg = RoyaltyRegistry(royaltyRegistry);
        // (royinf.status, royinf.royPercentage, royinf.royAddress,) = royReg
        //     .getRoyaltyInfo(_conAddr);
        // if (royinf.status) {
        //     if (
        //         blackListedAddresses[royinf.royAddress] == false &&
        //         royinf.royPercentage > 0 &&
        //         royinf.royAddress != 0x0000000000000000000000000000000000000000
        //     ) {
        //         t.transferFrom(salestruct.user, royinf.royAddress, royalty);
        //     }
        // }

        // t.transferFrom(salestruct.user, address(this), adminfees);
        // t.transferFrom(salestruct.user, salestruct.seller, netamount);
        // t.withdraw(adminfees);

        // uint256 contractBalanceETH = address(this).balance;
        // if (contractBalanceETH >= MinimumETHbalance) {
            // buyback();
       // }

        // transferNft(
        //     salestruct.conAddr,
        //     salestruct.tokenId,
        //     salestruct.user,
        //     salestruct.nftType,
        //     salestruct.nooftoken,
        //     msg.sender
        // );
    }

    function saleToken(
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
        // require(blackListedAddresses[msg.sender] == false, "User BlackListed");
        // require(msg.value >= totalamount, "Invalid calculation");
        // for (uint256 i = 0; i < from.length; i++) {
        //     if (blackListedAddresses[from[i]] == false) {
        //         salestruct.user = msg.sender;
        //         salestruct.amount = amount[i];
        //         salestruct.nonce = nonce[i];
        //         salestruct.signature = signature[i];
        //         salestruct.seller = from[i];
        //         salestruct.tokenId = tokenId[i];
        //         salestruct.nftType = nftType[i];
        //         salestruct.nooftoken = nooftoken[i];
        //         salestruct.conAddr = _conAddr[i];

        //         (uint256 netamount, , uint256 roy) = calculaterewardsAndRoyalty(
        //             salestruct.user,
        //             salestruct.amount,
        //             salestruct.nonce,
        //             salestruct.signature,
        //             salestruct.seller,
        //             salestruct.conAddr
        //         );

        //         uint256 contractBalanceETH = address(this).balance;
        //         if (contractBalanceETH >= MinimumETHbalance) {
                    // buyback();
                // }
                // payable(salestruct.seller).transfer(netamount);
                // RoyaltyRegistry royReg = RoyaltyRegistry(royaltyRegistry);
                // (
                //     royinf.status,
                //     royinf.royPercentage,
                //     royinf.royAddress,
                // ) = royReg.getRoyaltyInfo(salestruct.conAddr);

                // if (royinf.status) {
                //     if (
                //         blackListedAddresses[royinf.royAddress] == false &&
                //         royinf.royPercentage > 0 &&
                //         royinf.royAddress !=
                //         0x0000000000000000000000000000000000000000
                //     ) {
                //         payable(royinf.royAddress).transfer(roy);
                //     }
                // }

                // transferNft(
                //     salestruct.conAddr,
                //     salestruct.tokenId,
                //     msg.sender,
                //     salestruct.nftType,
                //     salestruct.nooftoken,
                //     salestruct.seller
                // );
           // }
       // }
    }

    function calculaterewardsAndRoyaltyBid(
        address buyer,
        uint256 amount,
        address seller,
        address _contractAddress
    )
        internal
        returns (
            uint256 netamount,
            uint256 roy,
            uint256 _adminfee
        )
    {
        BuyBack buybackCont = BuyBack(buyBackAddress);

        RoyaltyRegistry royReg = RoyaltyRegistry(royaltyRegistry);
        (, royinf.royPercentage, ,) = royReg.getRoyaltyInfo(_contractAddress);

        salestruct.user = buyer;
        salestruct.royaltyPer = royinf.royPercentage;
        salestruct.amount = amount;
        salestruct.seller = seller;

        (_adminfee, netamount, roy) = calc(
            amount,
            buyBackFee,
            salestruct.royaltyPer
        );
        require(netamount + roy + _adminfee <= amount, "Invalid calc");

        (uint256 totalBuyerRewards, uint256 totalSellerRewards) = buybackCont
            .getRewardsAL(salestruct.amount);

        if (betaLaunched == false) {
            (totalBuyerRewards, totalSellerRewards) = buybackCont.getRewardsBL(
                salestruct.amount
            );
        }

        IERC20 seagoldtoken = IERC20(seaGoldToken);
        seagoldtoken.transfer(salestruct.seller, totalSellerRewards);
        seagoldtoken.transfer(salestruct.user, totalBuyerRewards);

        return (netamount, roy, _adminfee);
    }

    function calculaterewardsAndRoyalty(
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
            uint256 roy,
            uint256 _adminfee
        )
    {
        bytes32 message = prefixed(keccak256(abi.encodePacked(seller, nonce)));
        require(recoverSigner(message, signature) == seller, "wrong signature");
        BuyBack buybackCont = BuyBack(buyBackAddress);

        RoyaltyRegistry royReg = RoyaltyRegistry(royaltyRegistry);
        (, royinf.royPercentage, ,) = royReg.getRoyaltyInfo(_contractAddress);

        salestruct.user = buyer;
        salestruct.royaltyPer = royinf.royPercentage;
        salestruct.amount = amount;
        salestruct.seller = seller;

        (_adminfee, netamount, roy) = calc(
            amount,
            buyBackFee,
            salestruct.royaltyPer
        );
        require(netamount + roy + _adminfee <= amount, "Invalid calc");
        (uint256 totalBuyerRewards, uint256 totalSellerRewards) = buybackCont
            .getRewardsAL(salestruct.amount);

        if (betaLaunched == false) {
            (totalBuyerRewards, totalSellerRewards) = buybackCont.getRewardsBL(
                salestruct.amount
            );
        }

        IERC20 seagoldtoken = IERC20(seaGoldToken);
        seagoldtoken.transfer(salestruct.seller, totalSellerRewards);
        seagoldtoken.transfer(salestruct.user, totalBuyerRewards);
        return (netamount, roy, _adminfee);
    }

    function transferNft(
        address _conAddr,
        uint256 tokenId,
        address to,
        uint256 nftType,
        uint256 nooftoken,
        address nftowner
    ) public {
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

    function buyback() private {
        uint256 contractBalanceETH = address(this).balance;
        uint256 SwapBalanceETH = contractBalanceETH - (1 * 1e18);
        if (betaLaunched == true) {
            payable(TreasuryAddress).transfer(SwapBalanceETH);
        } else {
            swapETHForTokens(SwapBalanceETH);
        }
    }

    function swapETHForTokens(uint256 amount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = WETHtoken;
        path[1] = SeaGoldToken;

        // make the swap
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: amount
        }(
            0, // accept any amount of Tokens
            path,
            address(this),
            block.timestamp.add(300)
        );
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
        uint256 _serviceValue,
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
        uint256 fee = pERCent(amount, _serviceValue);
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

    function safeWithDraweth(uint256 _amount, address payable addr)
    public
    onlyOwner
    {
        addr.transfer(_amount);
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
}