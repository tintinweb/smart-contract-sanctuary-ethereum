/**
 *Submitted for verification at Etherscan.io on 2022-05-07
*/

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol

pragma solidity >=0.6.2;


interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

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
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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

// File: @openzeppelin/contracts/interfaces/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/interfaces/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;


// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: KittPad.sol


pragma solidity ^0.8.4;






interface IKittPad {
  function depositRewardsEth() external payable;

  function getShares(address wallet) external view returns (uint256);

  function getBoostNfts(address wallet)
    external
    view
    returns (uint256[] memory);
}

contract KittPad is IKittPad, Ownable {
  using SafeMath for uint256;

  struct Reward {
    mapping(address => uint256) totalExcluded; // excluded reward
    mapping(address => uint256) totalRealised;
    uint256 totalRealisedForNft;
    uint256 totalExcludedForNft;
    uint256 lastClaim; // used for boosting logic
  }

  struct Share {
    uint256 amount;
    uint256 amountBase;
    uint256 stakedTime;
    uint256 nftStakedTime;
    uint256[] nftBoostTokenIds;
  }

  uint256 public minSecondsBeforeUnstake = 43200;
  uint256 public minSecondsBeforeUnstakeNFT = 2592000; // 30 days
  address public shareholderToken;
  address public nftBoosterToken;
  uint256 public nftBoostPercentage = 2; // 2% boost per NFT staked
  uint256 public maxNftsCanBoost = 10;
  uint256 public totalStakedUsers;
  uint256 public totalSharesBoosted;
  uint256 public totalNftStaked;
  uint256 public totalSharesDeposited; // will only be actual deposited tokens without handling any reflections or otherwise
  IUniswapV2Router02 router;

  // amount of shares a user has
  mapping(address => Share) shares;
  // reward information per user
  mapping(address => Reward) public rewards;
  // staker list
  address[] public stakers;
  uint256 public totalRewardsEth;
  mapping(address => uint256) totalRewardsToken;
  mapping(address => uint256) rewardsPerShareToken;
  address[] public prTokenList;
  uint256 public totalDistributed;
  uint256 public rewardsEthPerNft;

  uint256 public constant ACC_FACTOR = 10**36;
  
  constructor(
    address _shareholderToken,
    address _nftToken
  ) {
    shareholderToken = _shareholderToken;
    nftBoosterToken = _nftToken;
  }

  function getPrTokenList() external view returns(address[] memory){
    return prTokenList;
  }

  function stake(uint256 amount) external {
    _stake(msg.sender, amount);
  }

  function stakeNFT(uint256[] memory nftTokenIds) external {
    address shareholder = msg.sender;
    require(nftTokenIds.length > 0, "You should stake NFTs more than one.");
    if (shares[shareholder].nftBoostTokenIds.length > 0)
      distributeRewardForNft(shareholder);
    IERC721 nftContract = IERC721(nftBoosterToken);
    for (uint256 i = 0; i < nftTokenIds.length; i++) {
      nftContract.transferFrom(shareholder, address(this), nftTokenIds[i]);
      shares[shareholder].nftBoostTokenIds.push(nftTokenIds[i]);
    }
    shares[shareholder].nftStakedTime = block.timestamp;
    totalNftStaked = totalNftStaked.add(nftTokenIds.length);
    rewards[shareholder].totalExcludedForNft = getCumulativeRewardsEth(
      shares[shareholder].nftBoostTokenIds.length
    );
  }

  function unstakeNFT(uint256[] memory nftTokenIds) external {
    address shareholder = msg.sender;
    require(
      shares[shareholder].nftBoostTokenIds.length > 0 &&
        (nftTokenIds.length == 0 || nftTokenIds.length <= shares[shareholder].nftBoostTokenIds.length),
      "you can only unstake if you have some staked"
    );
    require(
      block.timestamp > shares[shareholder].nftStakedTime + minSecondsBeforeUnstakeNFT,
      "must be staked for minimum time and at least one block if no min"
    );

    if (shares[shareholder].nftBoostTokenIds.length > 0)
      distributeRewardForNft(shareholder);
    IERC721 nftContract = IERC721(nftBoosterToken);
    if (nftTokenIds.length == 0) {
      uint i;
      for (i = 0; i < shares[shareholder].nftBoostTokenIds.length; i++) {
        nftContract.transferFrom(address(this), shareholder, shares[shareholder].nftBoostTokenIds[i]);
      }
      delete shares[shareholder].nftBoostTokenIds;
    } 
    else {
      for (uint256 i = 0; i < nftTokenIds.length; i++) {
        uint256 j;
        for (j = 0; j < shares[shareholder].nftBoostTokenIds.length; j++) {
          if (nftTokenIds[i] == shares[shareholder].nftBoostTokenIds[j]) {
            break;
          }
        }
        require(j < shares[shareholder].nftBoostTokenIds.length, "Wrong id.");
        if (j == shares[shareholder].nftBoostTokenIds.length - 1)
          shares[shareholder].nftBoostTokenIds.pop();
        else {
          shares[shareholder].nftBoostTokenIds[j] = shares[shareholder]
            .nftBoostTokenIds[shares[shareholder].nftBoostTokenIds.length - 1];
          shares[shareholder].nftBoostTokenIds.pop();
        }
        nftContract.transferFrom(address(this), shareholder, nftTokenIds[i]);
      }
    }
    rewards[shareholder].totalExcludedForNft = getCumulativeRewardsEth(
      shares[shareholder].nftBoostTokenIds.length
    );
    totalNftStaked = totalNftStaked.sub(nftTokenIds.length);
  }

  function _stake(address shareholder, uint256 amount) private {
    if (shares[shareholder].amount > 0) {
      for (uint256 i = 0; i < prTokenList.length; i++) {
        address rwdToken = prTokenList[i];
        distributeReward(shareholder, rwdToken);
      }
    }

    IERC20 shareContract = IERC20(shareholderToken);
    uint256 stakeAmount = amount == 0
      ? shareContract.balanceOf(shareholder)
      : amount;
    uint256 sharesBefore = shares[shareholder].amount;

    // for compounding we will pass in this contract override flag and assume the tokens
    // received by the contract during the compounding process are already here, therefore
    // whatever the amount is passed in is what we care about and leave it at that. If a normal
    // staking though by a user, transfer tokens from the user to the contract.
    uint256 finalBaseAdded = stakeAmount;

    uint256 shareBalanceBefore = shareContract.balanceOf(address(this));
    shareContract.transferFrom(shareholder, address(this), stakeAmount);
    finalBaseAdded = shareContract.balanceOf(address(this)).sub(
      shareBalanceBefore
    );

    uint256 finalBoostedAmount = shares[shareholder].amountBase.add(finalBaseAdded);

    totalSharesDeposited = totalSharesDeposited.add(finalBaseAdded);
    totalSharesBoosted = totalSharesBoosted.sub(shares[shareholder].amount).add(
        finalBoostedAmount
      );
    shares[shareholder].amountBase += finalBaseAdded;
    shares[shareholder].amount = finalBoostedAmount;
    shares[shareholder].stakedTime = block.timestamp;
    if (sharesBefore == 0 && shares[shareholder].amount > 0) {
      totalStakedUsers++;
    }
    for (uint256 i = 0; i < prTokenList.length; i++) {
      address rwdToken = prTokenList[i];
      rewards[shareholder].totalExcluded[rwdToken] = getCumulativeRewardsToken(
        shares[shareholder].amount,
        rwdToken
      );
    }
    stakers.push(shareholder);
  }

  function _unstake(
    address account,
    uint256 boostedAmount
  ) private {
    require(
      shares[account].amount > 0 &&
        (boostedAmount == 0 || boostedAmount <= shares[account].amount),
      "you can only unstake if you have some staked"
    );
    require(
      block.timestamp > shares[account].stakedTime + minSecondsBeforeUnstake,
      "must be staked for minimum time and at least one block if no min"
    );
    
    for (uint256 i = 0; i < prTokenList.length; i++) {
      address rewardsToken = prTokenList[i];
      distributeReward(account, rewardsToken);
    }

    IERC20 shareContract = IERC20(shareholderToken);
    uint256 boostedAmountToUnstake = boostedAmount == 0
      ? shares[account].amount
      : boostedAmount;

    uint256 baseAmount = boostedAmountToUnstake;

    if (boostedAmount == 0) {
      totalStakedUsers--;
    }

    shareContract.transfer(account, baseAmount);

    totalSharesDeposited = totalSharesDeposited.sub(baseAmount);
    totalSharesBoosted = totalSharesBoosted.sub(boostedAmountToUnstake);
    shares[account].amountBase -= baseAmount;
    shares[account].amount -= boostedAmountToUnstake;
    for (uint256 i = 0; i < prTokenList.length; i++) {
      address tkAddr = prTokenList[i];
      rewards[account].totalExcluded[tkAddr] = getCumulativeRewardsToken(
        shares[account].amount,
        tkAddr
      );
    }
  }

  function unstake(uint256 boostedAmount) external {
    _unstake(msg.sender, boostedAmount);
  }

  function depositRewardsEth() external payable override {
    require(msg.value > 0, "value must be greater than 0");
    require(
      totalNftStaked > 0,
      "must be shares deposited to be rewarded rewards"
    );

    uint256 amount = msg.value;

    totalRewardsEth = totalRewardsEth.add(amount);
    rewardsEthPerNft = rewardsEthPerNft.add(
      ACC_FACTOR.mul(amount).div(totalNftStaked)
    );
  }

  function depositRewardsToken(address tokenAddr, uint256 amount) external {
    require(amount > 0, "value must be greater than 0");
    require(
      totalSharesBoosted > 0,
      "must be shares deposited to be rewarded rewards"
    );

    // transfer token from sender to this contract
    IERC20 rewardsToken = IERC20(tokenAddr);
    rewardsToken.transferFrom(msg.sender, address(this), amount);

    // register project token to the list
    if (totalRewardsToken[tokenAddr] == 0) prTokenList.push(tokenAddr);
    // accumulate reward token amount
    totalRewardsToken[tokenAddr] = totalRewardsToken[tokenAddr].add(amount);

    // calculate rewarding factor
    rewardsPerShareToken[tokenAddr] = rewardsPerShareToken[tokenAddr].add(
      ACC_FACTOR.mul(amount).div(totalSharesBoosted)
    );
  }

  function distributeRewardForNft(address shareholder) internal {
    uint256 earnedRewards = getUnpaidEth(shareholder);
    if (earnedRewards == 0)
      return;
    rewards[shareholder].totalRealisedForNft = rewards[shareholder].totalRealisedForNft.add(earnedRewards);
    rewards[shareholder].totalExcludedForNft = getCumulativeRewardsEth(shares[shareholder].nftBoostTokenIds.length);
    uint256 balanceBefore = address(this).balance;
    (bool sent, ) = payable(shareholder).call{ value: earnedRewards }("");
    require(sent, "ETH was not successfully sent");
    require(
      address(this).balance >= balanceBefore - earnedRewards,
      "only take proper amount from contract"
    );
  }

  function distributeReward(
    address shareholder,
    address rewardsToken
  ) internal {
    // require(
    //   block.timestamp > rewards[shareholder].lastClaim,
    //   'can only claim once per block'
    // );
    if (shares[shareholder].amount == 0) {
      return;
    }

    uint256 amount = getUnpaidToken(shareholder, rewardsToken);
    if (amount == 0) return;

    rewards[shareholder].totalRealised[rewardsToken] = rewards[shareholder]
      .totalRealised[rewardsToken]
      .add(amount);
    rewards[shareholder].totalExcluded[rewardsToken] = getCumulativeRewardsToken(shares[shareholder].amount, rewardsToken);
    rewards[shareholder].lastClaim = block.timestamp;

    if (amount > 0) {
      totalDistributed = totalDistributed.add(amount);
      IERC20 rwdt = IERC20(rewardsToken);
      rwdt.transfer(shareholder, amount);
    }
  }

  function totalClaimed(address rewardsToken) external view returns(uint256) {
    return rewards[msg.sender].totalRealised[rewardsToken];
  }

  function totalClaimedEth() external view returns(uint256) {
    return rewards[msg.sender].totalRealisedForNft;
  }

  function claimRewardForKD(address rewardsToken) external {
    distributeReward(msg.sender, rewardsToken);
  }

  function claimRewardForNft() external {
    distributeRewardForNft(msg.sender);
  }

  function getUnpaidEth(address shareholder)
    public
    view
    returns (uint256)
  {
    if (shares[shareholder].nftBoostTokenIds.length == 0) return 0;

    uint256 earnedRewards = getCumulativeRewardsEth(
      shares[shareholder].nftBoostTokenIds.length
    );
    uint256 rewardsExcluded = rewards[shareholder].totalExcludedForNft;
    if (earnedRewards <= rewardsExcluded) {
      return 0;
    }

    return earnedRewards.sub(rewardsExcluded);
  }

  function getUnpaidToken(address shareholder, address tokenAddr)
    public
    view
    returns (uint256)
  {
    if (shares[shareholder].amount == 0) {
      return 0;
    }

    uint256 earnedRewards = getCumulativeRewardsToken(
      shares[shareholder].amount,
      tokenAddr
    );
    uint256 rewardsExcluded = rewards[shareholder].totalExcluded[tokenAddr];
    if (earnedRewards <= rewardsExcluded) {
      return 0;
    }

    return earnedRewards.sub(rewardsExcluded);
  }

  function getCumulativeRewardsToken(uint256 share, address tokenAddr)
    internal
    view
    returns (uint256)
  {
    return share.mul(rewardsPerShareToken[tokenAddr]).div(ACC_FACTOR);
  }

  function getCumulativeRewardsEth(uint256 share)
    internal
    view
    returns (uint256)
  {
    return share.mul(rewardsEthPerNft).div(ACC_FACTOR);
  }

  function getBaseShares(address user) external view returns (uint256) {
    return shares[user].amountBase;
  }

  function getShares(address user) external view override returns (uint256) {
    return shares[user].amount;
  }

  function getBoostNfts(address user)
    public
    view
    override
    returns (uint256[] memory)
  {
    return shares[user].nftBoostTokenIds;
  }

  function setShareholderToken(address _token) external onlyOwner {
    shareholderToken = _token;
  }

  function setMinSecondsBeforeUnstake(uint256 _seconds) external onlyOwner {
    minSecondsBeforeUnstake = _seconds;
  }

  function setMinSecondsBeforeUnstakeNft(uint256 _seconds) external onlyOwner {
    minSecondsBeforeUnstakeNFT = _seconds;
  }

  function setNftBoosterToken(address _nft) external onlyOwner {
    nftBoosterToken = _nft;
  }

  function setNftBoostPercentage(uint256 _percentage) external onlyOwner {
    nftBoostPercentage = _percentage;
  }

  function setMaxNftsToBoost(uint256 _amount) external onlyOwner {
    maxNftsCanBoost = _amount;
  }

  function unstakeAll() public onlyOwner {
    if (stakers.length == 0) return;
    for (uint256 i = 0; i < stakers.length; i++) {
      if (shares[stakers[i]].amount <= 0) continue;
      _unstake(stakers[i], 0);
    }
    delete stakers;
  }

  function withdrawAll() external onlyOwner {
    unstakeAll();
    IERC20 shareContract = IERC20(shareholderToken);
    uint256 amount = shareContract.balanceOf(address(this));
    shareContract.transfer(owner(), amount);
    amount = address(this).balance;
    payable(owner()).call{ value: amount, gas: 30000 }("");
  }

  receive() external payable {}
}