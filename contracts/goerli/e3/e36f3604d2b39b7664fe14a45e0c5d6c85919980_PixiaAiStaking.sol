/**
 *Submitted for verification at Etherscan.io on 2023-02-13
*/

//SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/introspection/IERC165.sol
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

/*
 * █▀█ █ ▀▄▀ █ ▄▀█   ▄▀█ █
 * █▀▀ █ █░█ █ █▀█   █▀█ █
 *
 * https://Pixia.Ai
 * https://t.me/PixiaAi
 * https://twitter.com/PixiaAi
*/


pragma solidity ^0.8.17;

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

// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.17;

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}

// File: @openzeppelin/contracts/interfaces/IERC721.sol

// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.17;

// File: @openzeppelin/contracts/utils/math/SafeMath.sol

// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.17;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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

// File: @openzeppelin/contracts/utils/Context.sol

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.17;

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

// File: @openzeppelin/contracts/access/Ownable.sol

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.17;

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.17;

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
    event Transfer(
        address indexed from, 
        address indexed to, 
        uint256 value
    );

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(
        address account
    ) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(
        address owner, 
        address spender
    ) external view returns (uint256);

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
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

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

    function getAmountsOut(
        uint256 amountIn,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);

    function getAmountsIn(
        uint256 amountOut, 
        address[] calldata path
    ) external view returns (uint256[] memory amounts);
}

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol

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

abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

interface IStaking {
    function addRewards(uint256 amount) external;
}

contract feeHandler is Ownable, ReentrancyGuard {

    IUniswapV2Router02 public router;
    address stakingContract;

    constructor() {
        router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        stakingContract = msg.sender;
    }

    function swapTokensForETH(
        IERC20 token,
        uint256 tokenAmount,
        address wallet
    ) public nonReentrant {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = router.WETH();

        if (token.allowance(address(this), address(router)) < tokenAmount) {
            token.approve(address(router), type(uint256).max);
        }

        if(address(token) != router.WETH()){
            // make the swap
            router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                tokenAmount,
                0, // accept any amount of ETH
                path,
                wallet,
                block.timestamp
            );
        }
    }

    function sendRewards(IERC20 token) public {
        uint256 amount = token.balanceOf(address(this));

        if (token.allowance(address(this), address(stakingContract)) < amount) {
            token.approve(address(stakingContract), type(uint256).max);
        }

        IStaking(stakingContract).addRewards(amount);
    }

    function swapDepositTokenForRewardToken (IERC20 deposit, IERC20 reward, uint256 tokenAmount) public nonReentrant {
        address[] memory path = new address[](3);
        path[0] = address(deposit);
        path[1] = router.WETH();
        path[2] = address(reward);

        if (deposit.allowance(address(this), address(router)) < tokenAmount) {
            deposit.approve(address(router), type(uint256).max);
        }

        if(address(deposit) != router.WETH()){
            // make the swap
            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                tokenAmount,
                0, // accept any amount of ETH
                path,
                address(this),
                block.timestamp
            );
        }

        address[] memory pathOne = new address[](2);
        path[0] = address(deposit);
        path[1] = address(reward);

        if(address(deposit) == router.WETH()){
             // make the swap
            router.swapExactTokensForTokens(
                tokenAmount,
                0, // accept any amount of ETH
                pathOne,
                address(this),
                block.timestamp
            );
        }
    }

    function updateRouter(IUniswapV2Router02 newRouter) public onlyOwner {
        router = newRouter;
    }

    function claimStuckedTokens(IERC20 token, address wallet) public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(wallet, balance);
    }

    function claimEther(address wallet) external onlyOwner {
        (bool sent, ) = wallet.call{value: address(this).balance}("");
        require(sent, "eth transfer fail");
    }

    receive() external payable {}
}

interface IWETH {
    function withdraw(uint) external;
}


// File: stakeing.sol

pragma solidity 0.8.17;

contract PixiaAiStaking is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    /**
     *
     * @dev User reflects the info of each user
     *
     * @param {total_invested} how many tokens the user staked
     * @param {lastPayout} time at which last claim was done
     * @param {depositTime} Time of last deposit
     * @param {totalClaimed} Total claimed by the user
     *
     */
    struct UserLocked {
        uint256 total_invested;
        uint256 lastPayout;
        uint256 depositTime;
        uint256 totalClaimed;
    }

    struct UserUnlocked {
        uint256 total_invested;
        uint256 lastPayout;
        uint256 depositTime;
        uint256 totalClaimed;
    }

    /**
     *
     * @dev PoolInfo reflects the info of each pools
     *
     * To improve precision, we provide APY with an additional zero. So if APY is 12%, we provide
     * 120 as input.lockPeriodInDays would be the number of days which the claim is locked. So if we want to
     * lock claim for 1 month, lockPeriodInDays would be 30.
     * Keep in mind that APY represent in terms of tokens not actual USD value. example -- if token A is staked (avg value 0.02 cents)
     * and reward token is token B (avg price 0.01 cents), having apy of 12% will generate 12 tokens B on 100 tokenA being staked.
     * if token B is more valuable than stake token, then there actual apy in USD terms could much higher than showing.
     * if we take token A (0.02 cents avg price) staked with 12% then he will be able to make 12 usdt over a year. (actual apy in terms of $value he get is 600%)
     * @param {depositToken} Token which will be deposited to the pool
     * @param {rewardToken} Token which will be distributed as reward
     * @param {apy} Percentage of yield produced by the pool
     * @param {totalDeposit} Total deposit in the pool
     * @param {lockupPeriodInDays} Total lock for initial deposit (for staked token);
     *
     */
    struct LockedPool {
        IERC20 depositToken;
        IERC20 rewardToken;
        uint256 Ddecimals;
        uint256 Rdecimals;
        uint256 apy;
        uint256 lockPeriodInDays;
        uint256 totalDeposit;
        uint256 startDate;
        uint256 availableRewards;
    }

    struct UnlockedPool {
        IERC20 depositToken;
        IERC20 rewardToken;
        uint256 Ddecimals;
        uint256 Rdecimals;
        uint256 apy;
        uint256 lockPeriodInDays;
        uint256 totalDeposit;
        uint256 startDate;
        uint256 availableRewards;
        uint256 cooldownPeriod;
        uint256 feeToBreakCooldown;
    }

    uint256 public rewardFee;
    uint256 public rewardMultiplier;
    uint16 public rewardDistributionOfLockedPool;
    uint16 public rewardDistributionOfUnlockedPool;


    IERC721 public NFT;
    uint256[] public indexedTokens;
    mapping(uint256 => bool) public isIndexed;
    mapping(uint256 => address) public stakerAddress;
    mapping(address => uint256) public totalNFTStaked;

    mapping(address => UserLocked) public usersLocked;
    mapping(address => UserUnlocked) public usersUnlocked;
    mapping(address => bool) public isAdmin;


    LockedPool public lockedPoolInfo;
    UnlockedPool public unlockedPoolInfo;
    uint256 public minSwapAmount;

    address public feeWallet;
    feeHandler public feeHandle;
    bool isLocked;
    address public WETHContract;

    event lockStaked(address indexed addr, uint256 amount);
    event unlockStaked(address indexed addr, uint256 amount);
    event lockClaimed(address indexed addr, uint256 amount);
    event unlockClaimed(address indexed addr, uint256 amount);
    event nftStakedByUser (address indexed addr, uint256 tokenID);
    event nftUnstakedByUser (address indexed addr, uint256 tokenID);

    constructor(
        address _depositToken,
        uint256 _depositTokenDecimals,
        address _rewardToken,
        uint256 _rewardTokenDecimals,
        uint256 _apyOfLockedPool,
        uint256 _lockPeriod,
        uint256 _apyOfUnlockedPool,
        uint16 _lockedDistribution,
        uint16 _unlockedDistribution,
        uint256 _cooldownPeriod, // Of Unlocked Pool,
        uint16 _feeToBreakCooldown // Of Unlocked Pool

    ) {
        // Multiplier Is the Booster Effect
        // Examples: 
        // For 1, NFT Boosters are 1x, 1.1x, 1.2x, 1.3x, 1.4x, etc...
        // For 10, NFT Boosters are 1x, 2x, 3x, 4x, 5x, etc...
        // For 100, NFT Boosters are 1x, 11x, 22x, 33x, 44x, etc...
        rewardMultiplier = 1;
        

        NFT = IERC721(0xf8e81D47203A594245E36C48e151709F0C19fBe8); // NFT Collection Smart Contract allowed to stake NFTs from

        isAdmin[msg.sender] = true; // The deployer wallet is an Admin.
        isAdmin[address(0x123)] = true; // This address is set as Admin to support the Owner (Owner can remove admin anytime).

        rewardFee = 3; // Fee applied to the rewards in percent %
        feeWallet = address(0x123); // Address to receive Reward Fee in ETH

        feeHandle = new feeHandler(); // Contract managing fees
        minSwapAmount = 100e18; // Min tokens in wei before swap (this represent 100 tokens with 18 decimals)
        WETHContract = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6; // WETH token address (Mainnet WETH: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2 / Testnet WETH: 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6)


        lockedPoolInfo.depositToken = IERC20(_depositToken);
        lockedPoolInfo.rewardToken = IERC20(_rewardToken);
        lockedPoolInfo.Rdecimals = _rewardTokenDecimals;
        lockedPoolInfo.Ddecimals = _depositTokenDecimals;
        lockedPoolInfo.apy = _apyOfLockedPool;
        lockedPoolInfo.lockPeriodInDays = _lockPeriod;
        lockedPoolInfo.totalDeposit = 0;
        lockedPoolInfo.startDate = block.timestamp;
        lockedPoolInfo.availableRewards = 0;


        unlockedPoolInfo.depositToken= IERC20(_depositToken);
        unlockedPoolInfo.rewardToken= IERC20(_rewardToken);
        unlockedPoolInfo.Rdecimals = _rewardTokenDecimals;
        unlockedPoolInfo.Ddecimals = _depositTokenDecimals;
        unlockedPoolInfo.apy= _apyOfUnlockedPool;
        unlockedPoolInfo.lockPeriodInDays= 0;
        unlockedPoolInfo.totalDeposit= 0;
        unlockedPoolInfo.startDate= block.timestamp;
        unlockedPoolInfo.availableRewards= 0;
        unlockedPoolInfo.cooldownPeriod= _cooldownPeriod; // Cooldown Period for Unlocked Pool in hours
        unlockedPoolInfo.feeToBreakCooldown= _feeToBreakCooldown; // Tax applied for withdrawing Unlocked Tokens Before Cooldown Period Ends


        updateRewardDistribution(_lockedDistribution, _unlockedDistribution);
    }

    receive() external payable {

    }

    // The updateAPY function will update the APYs (Make sure users claim pending rewards, else that will be update reward amount accordingly to new APY.
    // APY is relative between deposit token and reward token, not USD values.
    function updateAPY(uint256 _apyOfLockedPool, uint256 _apyOfUnlockedPool)
        public
        
    {
        require (isAdmin[msg.sender], "Only admin can make changes");
        lockedPoolInfo.apy = _apyOfLockedPool;
        unlockedPoolInfo.apy = _apyOfUnlockedPool;
    }

    // update Lock Period For Locked pool
    function updateLockPeriod(uint256 _newLockPeriod) public onlyOwner {
        lockedPoolInfo.lockPeriodInDays = _newLockPeriod;
    }

    // Add rewards using function, else rewards won't be counted.
    function addRewards(uint256 amount) external {

        uint256 rewardOfLockedPool = amount.mul(rewardDistributionOfLockedPool).div(
            100
        );
        uint256 rewardOfUnlockedPool = amount.mul(rewardDistributionOfUnlockedPool).div(
            100
        );

        lockedPoolInfo.rewardToken.transferFrom(
            msg.sender,
            address(this),
            rewardOfLockedPool
        );
        lockedPoolInfo.availableRewards += rewardOfLockedPool;

        unlockedPoolInfo.rewardToken.transferFrom(
            msg.sender,
            address(this),
            rewardOfUnlockedPool
        );
        unlockedPoolInfo.availableRewards += rewardOfUnlockedPool;
    }

    /**
     *
     * @dev depsoit tokens to Locked staking 
     * @param {_amount} Amount to be staked
     * @return {bool} Status of stake
     *
     */
    function stakeLocked(uint256 _amount) external returns (bool) {
        bool success = lockedPoolInfo.depositToken.transferFrom(
            msg.sender,
            address(this),
            _amount
        );
        require(success, "Token : Transfer failed");

        _stake(msg.sender, _amount, 0);

        return true;
    }

    function _stake(
        address _sender,
        uint256 _amount,
        uint256 _nftAmount
    ) internal {
        UserLocked storage user = usersLocked[msg.sender];
        LockedPool storage pool = lockedPoolInfo;

        _claimLocked(msg.sender);

        user.total_invested = user.total_invested.add(_amount);
        pool.totalDeposit = pool.totalDeposit.add(_amount);
        uint256 amount = totalNFTStaked[_sender];
        totalNFTStaked[_sender] = amount.add(_nftAmount);

        user.lastPayout = block.timestamp;
        user.depositTime = block.timestamp;

        emit lockStaked(_sender, _amount);
    }

    /**
     *
     * @dev depsoit tokens to Unlocked staking
     * @param {_amount} Amount to be staked
     * @return {bool} Status of stake
     *
     */
    function stakeUnlocked(uint256 _amount) external returns (bool) {
        bool success = unlockedPoolInfo.depositToken.transferFrom(
            msg.sender,
            address(this),
            _amount
        );
        require(success, "Token : Transfer failed");

        _ustake(msg.sender, _amount, 0);

        return true;
    }

    function _ustake(
        address _sender,
        uint256 _amount,
        uint256 _nftAmount
    ) internal {
        UserUnlocked storage user = usersUnlocked[msg.sender];
        UnlockedPool storage pool = unlockedPoolInfo;

        _claimUnlocked(msg.sender);

        user.total_invested = user.total_invested.add(_amount);
        pool.totalDeposit = pool.totalDeposit.add(_amount);
        uint256 amount = totalNFTStaked[_sender];
        totalNFTStaked[_sender] = amount.add(_nftAmount);

        user.lastPayout = block.timestamp;
        user.depositTime = block.timestamp;

        emit unlockStaked(_sender, _amount);
    }

    // user can increase there lock time, once prev locktime passes
    function relock() external nonReentrant {
        UserLocked storage user = usersLocked[msg.sender];
        LockedPool storage pool = lockedPoolInfo;
        require(
            block.timestamp >=
                user.depositTime.add(pool.lockPeriodInDays.mul(1 days)),
            "Initial Lock is already active yet"
        );
        _claimLocked (msg.sender);
        user.depositTime = block.timestamp;
    }

    // unlock pool user can move tokens to lockedpool
    function lockUnlock(uint256 amount) external nonReentrant {
        //update the unlocked pool
        UserUnlocked storage user = usersUnlocked[msg.sender];
        UnlockedPool storage pool = unlockedPoolInfo;
        user.total_invested = user.total_invested.sub(amount);
        pool.totalDeposit = pool.totalDeposit.sub(amount);
        // updateLockedPool;
        UserLocked storage userL = usersLocked[msg.sender];
        LockedPool storage poolL = lockedPoolInfo;
        if (userL.total_invested == 0){
            userL.lastPayout = block.timestamp;
        }
        if (userL.total_invested > 0){
            _claimLocked(msg.sender);
        }
        poolL.totalDeposit = poolL.totalDeposit.add(amount);
        userL.total_invested = userL.total_invested.add(amount);
        userL.depositTime = block.timestamp;

    }

    function _stakeNFT(uint256 tokenID) private {
        require(NFT.ownerOf(tokenID) == msg.sender, "You don't own this NFT");
        NFT.transferFrom(msg.sender, address(this), tokenID);
        stakerAddress[tokenID] = msg.sender;  
            if (!isIndexed[tokenID]) {
                isIndexed[tokenID] = true;
                indexedTokens.push(tokenID);
            }

        totalNFTStaked[msg.sender] += 1;

    }

   function _unStakeNFT(uint256 tokenID) private {
    require(stakerAddress[tokenID] == msg.sender, "You haven't staked this NFT");
            stakerAddress[tokenID] = address(0);
            totalNFTStaked[msg.sender] -= 1;
            NFT.transferFrom(address(this), msg.sender, tokenID);
            
   } 

   // Returns the NFT ID's array of users
     function getStakedNFTIdOfUser(address _staker)
        external
        view
        virtual
        returns (uint256[] memory _tokensStaked)
    {
        uint256[] memory _indexedTokens = indexedTokens;
        bool[] memory _isStakerToken = new bool[](_indexedTokens.length);
        uint256 indexedTokenCount = _indexedTokens.length;
        uint256 stakerTokenCount = 0;

        for (uint256 i = 0; i < indexedTokenCount; i++) {
            _isStakerToken[i] = stakerAddress[_indexedTokens[i]] == _staker;
            if (_isStakerToken[i]) stakerTokenCount += 1;
        }

        _tokensStaked = new uint256[](stakerTokenCount);
        uint256 count = 0;
        for (uint256 i = 0; i < indexedTokenCount; i++) {
            if (_isStakerToken[i]) {
                _tokensStaked[count] = _indexedTokens[i];
                count += 1;
            }
        }

    }

    function stakeMultipleNFT(uint256[] calldata tokenIDs) external {
        for (uint256 i = 0; i < tokenIDs.length; i++) {
            _stakeNFT(tokenIDs[i]);
            emit nftStakedByUser(msg.sender, tokenIDs[i]);
        }
    }

    function unStakeMultipleNFT(uint256[] calldata tokenIDs) external {
        for (uint256 i = 0; i < tokenIDs.length; i++) {
            _unStakeNFT(tokenIDs[i]);
            emit nftUnstakedByUser(msg.sender, tokenIDs[i]);
        }
    }

    // The Compound function allows to reinvest the rewards into the staking pool
    // Only supported for pools which have same deposit and reward token
    function Compound (bool locked) external nonReentrant {
        if (locked) {
            LockedPool storage pool = lockedPoolInfo;

            if (pool.rewardToken == pool.depositToken) {
                uint256 amount = _payout(msg.sender, true);

                if (amount <= pool.availableRewards) {
                    lockedPoolInfo.availableRewards -= amount;
                    _stake(msg.sender, amount, 0);
                }
            }
        }

        if (!locked) {
            UnlockedPool storage pool = unlockedPoolInfo;

            if (pool.rewardToken == pool.depositToken) {
                uint256 amount = _payout(msg.sender, true);

                if (amount <= pool.availableRewards) {
                    lockedPoolInfo.availableRewards -= amount;
                    _stake(msg.sender, amount, 0);
                }
            }
        }
    }

    /**
     *
     * @dev claim Reward tokens From Locked staking
     * @return {bool} Status of claim
     *
     */
    function claimLocked() public nonReentrant returns (bool) {
        _claimLocked(msg.sender);

        return true;
    }

    /**
     *
     * @dev claim Reward tokens From Unlocked staking
     * @return {bool} Status of claim
     *
     */
    function claimUnlocked() public nonReentrant returns (bool) {
        _claimUnlocked(msg.sender);
        return true;
    }

    // Withdraw tokens from Locked [locked timeperiod must have been passed]
    // Lockup period reset when user stake again
    function withdrawLocked(uint256 _amount) external {
        UserLocked storage user = usersLocked[msg.sender];
        LockedPool storage pool = lockedPoolInfo;

        require(user.total_invested >= _amount, "You don't have enough funds");
        require(
            block.timestamp >=
                user.depositTime.add(pool.lockPeriodInDays.mul(1 days)),
            "Initial deposit in locked state"
        );

        _claimLocked(msg.sender);

        pool.totalDeposit = pool.totalDeposit.sub(_amount);
        user.total_invested = user.total_invested.sub(_amount);

        safeTransfer(pool.depositToken, msg.sender, _amount);
    }

    // Withdraw tokens from Unlocked
    function withdrawUnlocked(uint256 _amount) external returns (bool) {
        UserUnlocked storage user = usersUnlocked[msg.sender];
        UnlockedPool storage pool = unlockedPoolInfo;
        require(user.total_invested >= _amount, "You don't have enough funds");
        uint256 cooldownFee;

        if(block.timestamp < user.depositTime.add(pool.cooldownPeriod.mul(1 hours))) {
            cooldownFee = _amount.mul(pool.feeToBreakCooldown).div(100);
            safeTransfer(pool.depositToken, address(feeHandle), cooldownFee);

            uint256 swapAmount = pool.depositToken.balanceOf(address(feeHandle));

            if(address(pool.depositToken) == address(pool.rewardToken)) {
                feeHandle.sendRewards(pool.
                depositToken);
            }

            if(address(pool.depositToken) != address(pool.rewardToken)) {
                if(swapAmount > minSwapAmount) {
                    feeHandle.swapDepositTokenForRewardToken(pool.depositToken, pool.rewardToken, swapAmount);
                    feeHandle.sendRewards(pool.rewardToken);
                }
            }
        }

        _claimUnlocked(msg.sender);

        pool.totalDeposit = pool.totalDeposit.sub(_amount);
        user.total_invested = user.total_invested.sub(_amount);

        safeTransfer(pool.depositToken, msg.sender, _amount - cooldownFee);

        return true;
    }

    // Internal functions //
    function _claimLocked(address _addr) internal {
        UserLocked storage user = usersLocked[_addr];
        uint256 amount = _payout(_addr, true);

        if (amount <= lockedPoolInfo.availableRewards) {

            lockedPoolInfo.availableRewards -= amount;

            uint256 fees = amount.mul(rewardFee).div(100);
            IERC20 token = lockedPoolInfo.rewardToken;

            if (address(token) != address(WETHContract)) {

                if (fees > 0) {
                    safeTransfer(token, address(feeHandle), fees);
                }

                safeTransfer(lockedPoolInfo.rewardToken, _addr, amount - fees);
            }

            if (address(token) == address(WETHContract)) {
                IWETH(WETHContract).withdraw(amount); // Convert WETH to ETH

                if (fees > 0) {
                    sendToWallet(feeWallet,fees);
                }

                sendToWallet(_addr, amount-fees);
            }

            if (token.balanceOf(address(feeHandle)) > minSwapAmount) {
                    feeHandle.swapTokensForETH(
                    token,
                    token.balanceOf(address(feeHandle)),
                    feeWallet
                );
            }

            user.lastPayout = block.timestamp;

            user.totalClaimed = user.totalClaimed.add(amount);
        }

        emit lockClaimed(_addr, amount);
    }

    function _claimUnlocked(address _addr) internal {
        UserUnlocked storage user = usersUnlocked[_addr];

        uint256 amount = _payout(_addr, false);
        if (amount <= unlockedPoolInfo.availableRewards) {

            unlockedPoolInfo.availableRewards -= amount;

            uint256 fees = amount.mul(rewardFee).div(100);
            IERC20 token = lockedPoolInfo.rewardToken;

            if (address(token) != address(WETHContract)) {

                if (fees > 0) {
                    safeTransfer(token, address(feeHandle), fees);
                }

                safeTransfer(lockedPoolInfo.rewardToken, _addr, amount - fees);
            }

            if (address(token) == address(WETHContract)) {
                IWETH(WETHContract).withdraw(amount); //Conver weth to eth

                if (fees > 0) {
                    sendToWallet(feeWallet,fees);
                }

                sendToWallet(_addr, amount-fees);
            }

            if (token.balanceOf(address(feeHandle)) > minSwapAmount) {
                    feeHandle.swapTokensForETH(
                    token,
                    token.balanceOf(address(feeHandle)),
                    feeWallet
                );
            }

            user.lastPayout = block.timestamp;

            user.totalClaimed = user.totalClaimed.add(amount);
        }

        emit unlockClaimed(_addr, amount);
    }

    // Check upcoming reward amount
    function _payout(address _addr, bool locked)
        public
        view
        returns (uint256 value) {

        if (locked) {
            UserLocked storage user = usersLocked[_addr];
            LockedPool storage pool = lockedPoolInfo;
            uint256 from = user.lastPayout > user.depositTime
                ? user.lastPayout
                : user.depositTime;
            uint256 to = block.timestamp;

            if (from < to) {
                value = value.add(
                    user.total_invested.mul(to.sub(from)).mul(pool.apy).div(
                        365 days * 1000
                    )
                );

                if(address(pool.rewardToken) == WETHContract){
                    value = value.div(1000);
                }

                if (address(pool.rewardToken) != WETHContract){
                uint256 amt;
                uint256 nftAmount;
                uint256 baseMultiplierAmount;
                    if (pool.Rdecimals > pool.Ddecimals){
                        amt = pool.Rdecimals - pool.Ddecimals;
                        value = value.mul(10**amt);

                        nftAmount = totalNFTStaked[_addr];
                        baseMultiplierAmount = value.mul(rewardMultiplier).div(10).mul(nftAmount);

                        value = value.add(baseMultiplierAmount);
                    }

                    if (pool.Ddecimals > pool.Rdecimals) {
                        amt = pool.Ddecimals - pool.Rdecimals;
                        value = value.div(10**amt);

                        nftAmount = totalNFTStaked[_addr];
                        baseMultiplierAmount = value.mul(rewardMultiplier).div(10).mul(nftAmount);

                        value = value.add(baseMultiplierAmount);
                    }
                }
            }
        }

        if (!locked) {
            UserUnlocked storage user = usersUnlocked[msg.sender];
            UnlockedPool storage pool = unlockedPoolInfo;
            uint256 from = user.lastPayout > user.depositTime
                ? user.lastPayout
                : user.depositTime;
            uint256 to = block.timestamp;

            if (from < to) {
                value = value.add(
                    user.total_invested.mul(to.sub(from)).mul(pool.apy).div(
                        365 days * 1000
                    )
                );

                if(address(pool.rewardToken) == WETHContract){
                    value = value.div(1000);
                }

                if (address(pool.rewardToken) != WETHContract){
                uint256 amt;
                uint256 nftAmount;
                uint256 baseMultiplierAmount;

                    if (pool.Rdecimals > pool.Ddecimals){
                        amt = pool.Rdecimals - pool.Ddecimals;
                        value = value.mul(10**amt);

                        nftAmount = totalNFTStaked[_addr];
                        baseMultiplierAmount = value.mul(rewardMultiplier).div(10).mul(nftAmount);

                        value = value.add(baseMultiplierAmount);
                            
                    }

                    if (pool.Ddecimals > pool.Rdecimals) {
                        amt = pool.Ddecimals - pool.Rdecimals;
                        value = value.div(10**amt);

                        nftAmount = totalNFTStaked[_addr];
                        baseMultiplierAmount = value.mul(rewardMultiplier).div(10).mul(nftAmount);

                        value = value.add(baseMultiplierAmount);
                    }
                }
            }
        }

        return value;
    }

    // Internal function
    function safeTransfer(
        IERC20 _token,
        address _to,
        uint256 _amount
    ) internal {
        uint256 Bal = _token.balanceOf(address(this));
        if (_amount > Bal) {
            _token.transfer(_to, Bal);
        } else {
            _token.transfer(_to, _amount);
        }
    }

    // Claim ether from payament handler
    function claimETHFromFeeHandler(address wallet) external onlyOwner {
        feeHandle.claimEther(wallet);
    }

    // claim stucked ether from contract
    function claimETH(address wallet) external onlyOwner {
        sendToWallet(wallet, address(this).balance);
    }

    // Claim stucked tokens from payment handler
    function claimedStuckedTokenFromFeeHandler(address token, address wallet)
        external
        onlyOwner
    {
        feeHandle.claimStuckedTokens(IERC20(token), wallet);
    }

    function sendToWallet(address wallet, uint256 amount) private {
        (bool success, ) = wallet.call{value: amount}("");
        require(success, "eth transfer failed");
    }

    // The updateMultiplier function allow to change the NFT boost multiplier.
    function updateMultiplier(uint256 _newMultiplier)
        external
    {
        require (isAdmin[msg.sender], "Only admin can make changes");
        rewardMultiplier = _newMultiplier;
    }

    // The addOrRemoveAdmin function allow to add or remove an Admin.
    function addOrRemoveAdmin(address add, bool value) external onlyOwner {
        isAdmin[add] = value;
    }

    // The updateNFT function allow to change NFT collection smart contract address.
    function updateNFT(IERC721 _newNFT) external onlyOwner {
        NFT = _newNFT;
    }

    // The updateRouter function allow to change router address.
    function updateRouter(IUniswapV2Router02 newAddress) external onlyOwner {
        feeHandle.updateRouter(newAddress);
    }

    function updateMinSwap(uint256 amount) external  {
        require (isAdmin[msg.sender], "Only admin can make changes");
        minSwapAmount = amount;
    }

    //  The updateRewardDistribution function update the reaward distribution of locked and unlocked staking (Can't be more than 100%).
    function updateRewardDistribution(uint16 distributionOfLockedPool, uint16 distributionOfUnlockedPool)
        public
    {
        require (isAdmin[msg.sender], "Only admin can make changes");
        require (distributionOfLockedPool + distributionOfUnlockedPool == 100, "sum of locked and unlocked should be 100");
        rewardDistributionOfLockedPool = distributionOfLockedPool;
        rewardDistributionOfUnlockedPool = distributionOfUnlockedPool;
    }

    //  The getApy function return the value of APY for Locked and Unlocked staking.
    function getApy(bool isLockedPool) public view returns (uint256) {
        if (isLockedPool == true) {
            return lockedPoolInfo.apy;
        } else {
            return unlockedPoolInfo.apy;
        }
    }

    function updateFeeWallet (address reward) external onlyOwner {
        feeWallet = reward;
    }
}