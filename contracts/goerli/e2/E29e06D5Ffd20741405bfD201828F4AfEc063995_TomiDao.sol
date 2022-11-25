/**
 *Submitted for verification at Etherscan.io on 2022-11-25
*/

// SPDX-License-Identifier: BSD-3-Clause

pragma solidity 0.8.7;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

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

contract Context {
  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.
  constructor ()  { }

  function _msgSender() internal view returns (address payable) {
    return payable(msg.sender);
  }

  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor ()  {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

library SafeMath {
  /**
   * @dev Returns the addition of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `+` operator.
   *
   * Requirements:
   * - Addition cannot overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Returns the multiplication of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `*` operator.
   *
   * Requirements:
   * - Multiplication cannot overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts with custom message when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint256);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory);

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address);

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
  function allowance(address _owner, address spender) external view returns (uint256);

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
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  struct emissionCriteria{
        // tomi mints before auction first 2 weeks of NFT Minting
       uint256 beforeAuctionBuyer;
       uint256 beforeAuctionTomi;
       uint256 beforeAuctionMarketing;

        // tomi mints after two weeks // auction everyday of NFT Minting
       uint256 afterAuctionBuyer;
       uint256 afterAuctionTomi;
       uint256 afterAuctionMarketing;

       // booleans for checks of minting
       bool mintAllowed;

       // Mining Criteria and checks
       bool miningAllowed;
       uint8 poolPercentage;
       uint8 tomiPercentage;
   }
  
  function updateEmissions(emissionCriteria calldata emissions_) external;
  function updateMarketingWallet(address newAddress) external;
  function updateTomiWallet(address newAddress) external;
  function changeBlockState(address newAddress) external;

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
    function getApproved(uint256 tokenId) external view returns (address operator);

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
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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

    function totalSupply() external view returns (uint256);

}
contract TomiDAOEvents {
    /// @notice An event emitted when a new proposal is created
    event ProposalCreated(
        uint256 id,
        address proposer,
        uint256 startBlock,
        uint256 endBlock,
        string description,
        string title
    );
    event ProposalCreatedForEmissionUpdate(
        uint256 id,
        address proposer,
        address[] targets,
        uint256[] values,
        uint256 startBlock,
        uint256 endBlock,
        string description,
        string title
    );

    event ProposalCreatedWithRequirements(
        uint256 id,
        address proposer,
        address[] targets,
        uint256[] values,
        uint256 startBlock,
        uint256 endBlock,
        uint256 proposalThreshold,
        uint256 quorumVotes,
        string description,
        string title
    );

    /// @notice An event emitted when a vote has been cast on a proposal
    /// @param voter The address which casted a vote
    /// @param proposalId The proposal id which was voted on
    /// @param support Support value for the vote. 0=against, 1=for, 2=abstain
    /// @param votes Number of votes which were cast by the voter
    /// @param reason The reason given for the vote by the voter
    event VoteCast(address indexed voter, uint256 proposalId, uint8 support, uint256 votes, string reason);

    /// @notice An event emitted when a proposal has been canceled
    event ProposalCanceled(uint256 id);

    /// @notice An event emitted when a proposal has been queued in the TomiDAOExecutor
    event ProposalQueued(uint256 id, uint256 eta);

    /// @notice An event emitted when a proposal has been executed in the TomiDAOExecutor
    event ProposalExecuted(uint256 id);

    /// @notice An event emitted when a proposal has been vetoed by vetoAddress
    event ProposalVetoed(uint256 id);

    /// @notice An event emitted when the voting delay is set
    event VotingDelaySet(uint256 oldVotingDelay, uint256 newVotingDelay);

    /// @notice An event emitted when the voting period is set
    event VotingPeriodSet(uint256 oldVotingPeriod, uint256 newVotingPeriod);

    /// @notice Emitted when implementation is changed
    event NewImplementation(address oldImplementation, address newImplementation);

    /// @notice Emitted when proposal threshold basis points is set
    event ProposalThresholdBPSSet(uint256 oldProposalThresholdBPS, uint256 newProposalThresholdBPS);

    /// @notice Emitted when quorum votes basis points is set
    event QuorumVotesBPSSet(uint256 oldQuorumVotesBPS, uint256 newQuorumVotesBPS);

    /// @notice Emitted when pendingAdmin is changed
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /// @notice Emitted when pendingAdmin is accepted, which means admin is updated
    event NewAdmin(address oldAdmin, address newAdmin);

    /// @notice Emitted when vetoer is changed
    event NewVetoer(address oldVetoer, address newVetoer);

    event TransferTokens(address sender, address recipient, uint256 amount);
}

interface TomiTokenLike {
    function getPriorVotes(address account, uint256 blockNumber) external view returns (uint96);

    function totalSupply() external view returns (uint96);
    function balanceOf(address owner) external view returns (uint256 balance);
}

contract tomiStates{

    /// @notice Vetoer who has the ability to veto any proposal
    address public vetoer;

    // usdt token
    using TransferHelper for IERC20;
    // goerli tokens
    IERC20 public usdToken = IERC20(0x7eBDA8DDBd2De8d719662654347bDfc507327DB4);
    IERC20 public wethToken = IERC20(0x7eBDA8DDBd2De8d719662654347bDfc507327DB4);
    IERC20 public tomiToken = IERC20(0xC8cDEEB67d553466861E53a0f5A009bd756Ad140);
    
    // @notice The address of the Tomi tokens
    IERC721 public tomiNFT;
    // funds collecting wallet
    address public fundingWallet = address(0x7Ef8E5643424bed763dD1BdE66d4b2f79F9EDcd8);

    // initial fee for proposal
    uint256 public initialfee = 100 * 10**26;

    /// @notice The delay before voting on a proposal may take place, once proposed, in blocks
    uint256 public votingDelay;

    /// @notice The duration of voting on a proposal, in blocks
    uint256 public votingPeriod;

    /// @notice The basis point number of votes required in order for a voter to become a proposer. *DIFFERS from GovernerBravo
    uint256 public proposalThresholdBPS;

    /// @notice The basis point number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed. *DIFFERS from GovernerBravo
    uint256 public quorumVotesBPS;

    /// @notice The total number of proposals
    uint256 public proposalCount;

    /// @notice The address of the Tomi tokens
    TomiTokenLike public Tomi;

    /// @notice The official record of all proposals ever proposed
    mapping(uint256 => Proposal) public proposals;
    /// @notice The official record of all proposals ever proposed
    mapping(uint256 => ProposalEmission) public proposalsEmission;
    /// @notice The official record of all proposals ever proposed
    mapping(uint256 => ProposalWalletUpdate) public proposalMarektWalletUpdate;
    mapping(uint256 => ProposalWalletUpdate) public proposalTomiWalletUpdate;
    mapping(uint256 => ProposalWalletUpdate) public proposalBlockWalletUpdate;

    /// @notice The latest proposal for each proposer
    mapping(address => uint256) public latestProposalIds;

    /**  uniswap v2 router to calculate the token's reward on run-time
      *   usd balance equalent token
      */
    IUniswapV2Router02 public uniswapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    
    struct emissionCriteria{
        // tomi mints before auction first 2 weeks of NFT Minting
       uint256 beforeAuctionBuyer;
       uint256 beforeAuctionTomi;
       uint256 beforeAuctionMarketing;

        // tomi mints after two weeks // auction everyday of NFT Minting
       uint256 afterAuctionBuyer;
       uint256 afterAuctionTomi;
       uint256 afterAuctionMarketing;

       // booleans for checks of minting
       bool mintAllowed;

       // Mining Criteria and checks
       bool miningAllowed;
       uint8 poolPercentage;
       uint8 tomiPercentage;
    }

    struct Proposal {
        /// @notice Unique id for looking up a proposal
        uint256 id;
        /// @notice Creator of the proposal
        address proposer;
        /// @notice The number of votes needed to create a proposal at the time of proposal creation. *DIFFERS from GovernerBravo
        uint256 proposalThreshold;
        /// @notice The number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed at the time of proposal creation. *DIFFERS from GovernerBravo
        uint256 quorumVotes;
        /// @notice The timestamp that the proposal will be available for execution, set once the vote succeeds
        uint256 eta;
        /// @notice the ordered list of target addresses for calls to be made
        address[] targets;
        /// @notice The ordered list of values (i.e. msg.value) to be passed to the calls to be made
        uint256[] values;
        /// @notice The block at which voting begins: holders must delegate their votes prior to this block
        uint256 startBlock;
        /// @notice The block at which voting ends: votes must be cast prior to this block
        uint256 endBlock;
        /// @notice Current number of votes in favor of this proposal
        uint256 forVotes;
        /// @notice Current number of votes in opposition to this proposal
        uint256 againstVotes;
        /// @notice Current number of votes for abstaining for this proposal
        uint256 abstainVotes;
        /// @notice Flag marking whether the proposal has been canceled
        bool canceled;
        /// @notice Flag marking whether the proposal has been vetoed
        bool vetoed;
        /// @notice Flag marking whether the proposal has been executed
        bool executed;
        /// @notice Receipts of ballots for the entire set of voters
        mapping(address => Receipt) receipts; 
        // NFT ids
        uint256[] nftId;
        // function Id
        uint256 functionId;
    }

    struct ProposalEmission {
        /// @notice Unique id for looking up a proposal
        uint256 id;
        /// @notice Creator of the proposal
        address proposer;
        /// @notice The number of votes needed to create a proposal at the time of proposal creation. *DIFFERS from GovernerBravo
        uint256 proposalThreshold;
        /// @notice The number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed at the time of proposal creation. *DIFFERS from GovernerBravo
        uint256 quorumVotes;
        uint256 startBlock;
        /// @notice The block at which voting ends: votes must be cast prior to this block
        uint256 endBlock;
        /// @notice Current number of votes in favor of this proposal
        uint256 forVotes;
        /// @notice Current number of votes in opposition to this proposal
        uint256 againstVotes;
        /// @notice Current number of votes for abstaining for this proposal
        uint256 abstainVotes;
        /// @notice Flag marking whether the proposal has been canceled
        bool canceled;
        /// @notice Flag marking whether the proposal has been vetoed
        bool vetoed;
        /// @notice Flag marking whether the proposal has been executed
        bool executed;
        /// @notice Receipts of ballots for the entire set of voters
        mapping(address => Receipt) receipts; 
        // NFT ids
        uint256[] nftId;
        // function Id
        uint256 functionId;
        // change emission
        IERC20.emissionCriteria emission;
        // address marketWallet;
    }

    struct ProposalWalletUpdate {
        /// @notice Unique id for looking up a proposal
        uint256 id;
        /// @notice Creator of the proposal
        address proposer;
        /// @notice The number of votes needed to create a proposal at the time of proposal creation. *DIFFERS from GovernerBravo
        uint256 proposalThreshold;
        /// @notice The number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed at the time of proposal creation. *DIFFERS from GovernerBravo
        uint256 quorumVotes;
        uint256 startBlock;
        /// @notice The block at which voting ends: votes must be cast prior to this block
        uint256 endBlock;
        /// @notice Current number of votes in favor of this proposal
        uint256 forVotes;
        /// @notice Current number of votes in opposition to this proposal
        uint256 againstVotes;
        /// @notice Current number of votes for abstaining for this proposal
        uint256 abstainVotes;
        /// @notice Flag marking whether the proposal has been canceled
        bool canceled;
        /// @notice Flag marking whether the proposal has been vetoed
        bool vetoed;
        /// @notice Flag marking whether the proposal has been executed
        bool executed;
        /// @notice Receipts of ballots for the entire set of voters
        mapping(address => Receipt) receipts; 
        // NFT ids
        uint256[] nftId;
        // function Id
        uint256 functionId;
        // change emission
        address wallet;
    }

    /// @notice Ballot receipt record for a voter
    struct Receipt {
        /// @notice Whether or not a vote has been cast
        bool hasVoted;
        /// @notice Whether or not the voter supports the proposal or abstains
        uint8 support;
        /// @notice The number of votes the voter had, which were cast
        uint96 votes;
        /// @notice Whether or not a vote has been cast by the id
        uint256 nftId;
    }

    /// @notice Possible states that a proposal may be in
    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        // Queued,
        // Expired,
        Executed,
        Vetoed
    }
}

contract TomiDao is tomiStates, Ownable, TomiDAOEvents {
   
    using SafeMath for uint256;
   
    mapping(uint256 => bool) nftUsed;
    // voting nfts
    mapping(uint256 => uint256) nftVoted;
    //  iterations
    uint256 iteration = 1;
    // nfts require
    uint256 nftAmountrequired = 1;

    AggregatorV3Interface internal priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);

    struct ProposalTemp {
        uint256 totalSupply;
        uint256 proposalThreshold;
        uint256 latestProposalId;
        uint256 startBlock;
        uint256 endBlock;
    }

    struct Proposaltype{
      uint qourumVotes;
      uint consesusVotes;
      uint votingPeriod;
      string name;
    }

    mapping(uint => Proposaltype) public porposalCriteria;
    mapping(uint => uint) public transactionState;

    constructor(){
        porposalCriteria[1] = Proposaltype(50, 51, 14 days, "updateEmissions");
        porposalCriteria[2] = Proposaltype(50, 51, 14 days, "updateMarketingWallet");
        porposalCriteria[3] = Proposaltype(50, 51, 14 days, "updateTomiWallet");
        porposalCriteria[4] = Proposaltype(10, 75, 7 days, "changeBlockState");
    }
    
    function proposeChangeEmissionsWithEth(string memory description, uint256[] memory nftId, string memory title, uint8 functionId, IERC20.emissionCriteria calldata emissions_) public payable returns (uint256) {
        require(msg.value>=priceOfUSDinETH(),"Send Correct Ether value");
        require(nftId.length == nftAmountrequired, "poposal already created against these NFTs");
        proposalCount++;

        ProposalTemp memory temp;
        temp.totalSupply = tomiNFT.totalSupply();
        // temp.proposalThreshold = bps2Uint(proposalThresholdBPS, temp.totalSupply);
        
        ProposalEmission storage newProposal = proposalsEmission[proposalCount];
        for(uint8 i; i<nftId.length; i++){
            require(nftUsed[nftId[i]] != true, "poposal already created against these NFTs");
            newProposal.nftId[i] = nftId[i];
        }
        temp.latestProposalId = latestProposalIds[msg.sender];
        {
            if (temp.latestProposalId != 0) {
                checkPreviousLiveProposals(temp.latestProposalId);
            }
        }
        temp.startBlock = block.number + votingDelay;
        temp.endBlock = temp.startBlock.add(porposalCriteria[functionId].votingPeriod);
        newProposal.id = proposalCount;
        newProposal.proposer = msg.sender;
        newProposal.proposalThreshold = temp.proposalThreshold;
        // newProposal.quorumVotes = bps2Uint(quorumVotesBPS, temp.totalSupply);
        newProposal.startBlock = temp.startBlock;
        newProposal.endBlock = temp.endBlock;
        newProposal.functionId = functionId;
        newProposal.emission = emissions_;

        latestProposalIds[newProposal.proposer] = newProposal.id;
        emit ProposalCreated(proposalCount, msg.sender, newProposal.startBlock, newProposal.endBlock, description, title);
        return newProposal.id;
    }
                
    function proposeChangeMarketingWalletEth(string memory description, uint256[] memory nftId, string memory title, uint8 functionId, address marketWallet) public payable returns (uint256) {
        require(msg.value>=priceOfUSDinETH(),"Send Correct Ether value");
        require(nftId.length == nftAmountrequired, "poposal already created against these NFTs");
        proposalCount++;
    
        ProposalTemp memory temp;
        temp.totalSupply = tomiNFT.totalSupply();
        // temp.proposalThreshold = bps2Uint(proposalThresholdBPS, temp.totalSupply);
        
        ProposalWalletUpdate storage newProposal = proposalMarektWalletUpdate[proposalCount];
        for(uint8 i; i<nftId.length; i++){
            require(nftUsed[nftId[i]] != true, "poposal already created against these NFTs");
            newProposal.nftId[i] = nftId[i];
        }
        temp.latestProposalId = latestProposalIds[msg.sender];
        {
            if (temp.latestProposalId != 0) {
                checkPreviousLiveProposals(temp.latestProposalId);
            }
        }
        temp.startBlock = block.number + votingDelay;
        temp.endBlock = temp.startBlock.add(porposalCriteria[functionId].votingPeriod);
        newProposal.id = proposalCount;
        newProposal.proposer = msg.sender;
        newProposal.proposalThreshold = temp.proposalThreshold;
        // newProposal.quorumVotes = bps2Uint(quorumVotesBPS, temp.totalSupply);
        newProposal.startBlock = temp.startBlock;
        newProposal.endBlock = temp.endBlock;
        newProposal.functionId = functionId;
        newProposal.wallet = marketWallet;

        latestProposalIds[newProposal.proposer] = newProposal.id;
        emit ProposalCreated(proposalCount, msg.sender, newProposal.startBlock, newProposal.endBlock, description, title);
        return newProposal.id;
    }

    function proposeChangeTomiWalletEth(string memory description, uint256[] memory nftId, string memory title, uint8 functionId, address tomiWallet) public payable returns (uint256) {
        require(msg.value>=priceOfUSDinETH(),"Send Correct Ether value");
        require(nftId.length == nftAmountrequired, "poposal already created against these NFTs");
        proposalCount++;
    
        ProposalTemp memory temp;
        temp.totalSupply = tomiNFT.totalSupply();
        // temp.proposalThreshold = bps2Uint(proposalThresholdBPS, temp.totalSupply);
        
        ProposalWalletUpdate storage newProposal = proposalTomiWalletUpdate[proposalCount];
        for(uint8 i; i<nftId.length; i++){
            require(nftUsed[nftId[i]] != true, "poposal already created against these NFTs");
            newProposal.nftId[i] = nftId[i];
        }
        temp.latestProposalId = latestProposalIds[msg.sender];
        {
            if (temp.latestProposalId != 0) {
                checkPreviousLiveProposals(temp.latestProposalId);
            }
        }
        temp.startBlock = block.number + votingDelay;
        temp.endBlock = temp.startBlock.add(porposalCriteria[functionId].votingPeriod);
        newProposal.id = proposalCount;
        newProposal.proposer = msg.sender;
        newProposal.proposalThreshold = temp.proposalThreshold;
        // newProposal.quorumVotes = bps2Uint(quorumVotesBPS, temp.totalSupply);
        newProposal.startBlock = temp.startBlock;
        newProposal.endBlock = temp.endBlock;
        newProposal.functionId = functionId;
        newProposal.wallet = tomiWallet;

        latestProposalIds[newProposal.proposer] = newProposal.id;
        emit ProposalCreated(proposalCount, msg.sender, newProposal.startBlock, newProposal.endBlock, description, title);
        return newProposal.id;
    }

    function proposeBlockTomiWalletEth(string memory description, uint256[] memory nftId, string memory title, uint8 functionId, address blockWallet) public payable returns (uint256) {
        require(msg.value>=priceOfUSDinETH(),"Send Correct Ether value");
        require(nftId.length == nftAmountrequired, "poposal already created against these NFTs");
        proposalCount++;
    
        ProposalTemp memory temp;
        temp.totalSupply = tomiNFT.totalSupply();
        // temp.proposalThreshold = bps2Uint(proposalThresholdBPS, temp.totalSupply);
        
        ProposalWalletUpdate storage newProposal = proposalBlockWalletUpdate[proposalCount];
        for(uint8 i; i<nftId.length; i++){
            require(nftUsed[nftId[i]] != true, "poposal already created against these NFTs");
            newProposal.nftId[i] = nftId[i];
        }
        temp.latestProposalId = latestProposalIds[msg.sender];
        {
            if (temp.latestProposalId != 0) {
                checkPreviousLiveProposals(temp.latestProposalId);
            }
        }
        temp.startBlock = block.number + votingDelay;
        temp.endBlock = temp.startBlock.add(porposalCriteria[functionId].votingPeriod);
        newProposal.id = proposalCount;
        newProposal.proposer = msg.sender;
        newProposal.proposalThreshold = temp.proposalThreshold;
        // newProposal.quorumVotes = bps2Uint(quorumVotesBPS, temp.totalSupply);
        newProposal.startBlock = temp.startBlock;
        newProposal.endBlock = temp.endBlock;
        newProposal.functionId = functionId;
        newProposal.wallet = blockWallet;

        latestProposalIds[newProposal.proposer] = newProposal.id;
        emit ProposalCreated(proposalCount, msg.sender, newProposal.startBlock, newProposal.endBlock, description, title);
        return newProposal.id;
    }

    function checkPreviousLiveProposals(uint256 id) internal view {
        ProposalState proposersLatestProposalState = state(id);
                require(
                    proposersLatestProposalState != ProposalState.Active,
                    'TomiDAO::propose: one live proposal per proposer, found an already active proposal'
                );
                require(
                    proposersLatestProposalState != ProposalState.Pending,
                    'TomiDAO::propose: one live proposal per proposer, found an already pending proposal'
                );
    }

    /**
     * @notice Gets the state of a proposal
     * @param proposalId The id of the proposal
     * @return Proposal state
     */
    function state(uint256 proposalId) public view returns (ProposalState) {
        require(proposalCount >= proposalId, 'TomiDAO::state: invalid proposal id');
        // Proposal storage proposal = proposals[proposalId];
        ProposalEmission storage proposal = proposalsEmission[proposalId];
        if (proposal.vetoed) {
            return ProposalState.Vetoed;
        } else if (proposal.canceled) {
            return ProposalState.Canceled;
        } else if (block.number <= proposal.startBlock) {
            return ProposalState.Pending;
        } else if (block.number <= proposal.endBlock) {
            return ProposalState.Active;
        } else if (proposal.forVotes <= proposal.againstVotes || proposal.forVotes < proposal.quorumVotes) {
            return ProposalState.Defeated;
        } else if (proposal.executed) {
            return ProposalState.Executed;
        } else {
            return ProposalState.Succeeded;
        }
    }

    /**
     * @notice Cast a vote for a proposal
     * @param proposalId The id of the proposal to vote on
     * @param support The support value for the vote. 0=against, 1=for, 2=abstain
     * @param nftId The id of NFT for vote
     */
    function castVote(uint256 proposalId, uint8 support, uint256 nftId) external {
        emit VoteCast(msg.sender, proposalId, support, castVoteInternal(msg.sender, proposalId, support, nftId), '');
    }

    /**
     * @notice Internal function that caries out voting logic
     * @param voter The voter that is casting their vote
     * @param proposalId The id of the proposal to vote on
     * @param support The support value for the vote. 0=against, 1=for, 2=abstain
     * @return votes The number of votes cast
     */
    function castVoteInternal(
        address voter,
        uint256 proposalId,
        uint8 support,
        uint256 nftId
    ) internal returns (uint96 votes) {
        require(state(proposalId) == ProposalState.Active, 'TomiDAO::castVoteInternal: voting is closed');
        require(support <= 2, 'TomiDAO::castVoteInternal: invalid vote type');
        Proposal storage proposal = proposals[proposalId];
        Receipt storage receipt = proposal.receipts[voter];
        require(receipt.hasVoted == false, 'TomiDAO::castVoteInternal: voter already voted');
        require(receipt.nftId != nftId, "this nft has already voted");
        require(nftVoted[nftId] != iteration, "this nft has already voted");

        /// @notice: Unlike GovernerBravo, votes are considered from the block the proposal was created in order to normalize quorumVotes and proposalThreshold metrics
        votes = Tomi.getPriorVotes(voter, proposal.startBlock - votingDelay);

        if (support == 0) {
            proposal.againstVotes = proposal.againstVotes + votes;
        } else if (support == 1) {
            proposal.forVotes = proposal.forVotes + votes;
        } else if (support == 2) {
            proposal.abstainVotes = proposal.abstainVotes + votes;
        }

        receipt.hasVoted = true;
        receipt.support = support;
        receipt.votes = votes;
        receipt.nftId = nftId;
        nftVoted[nftId] = iteration;
        return votes;
    }

    // initialfee = 100 * 10**26;
    function processUsdTokenPayments() internal {
        uint256 fee = initialfee.div(10**18);
        require(usdToken.allowance(_msgSender(), address(this)) >= fee, "send required amount to propose");
        
        TransferHelper.safeTransferFrom(address(usdToken),_msgSender(),fundingWallet, fee);

    //    emit TransferTokens(_msgSender(), fundingWallet, initialfee);
    }
    
    // initialfee = 100 * 10**26;
    function processTomiTokenPayments() internal {
        address[] memory path;
        path[0] = address(usdToken);
        path[1] = address(wethToken);
        path[2] = address(tomiToken);

        uint[] memory fee = priceOfToken(initialfee.div(10**8), path);
        require(usdToken.allowance(_msgSender(), address(this)) >= fee[2], "send required amount to propose");
        
        TransferHelper.safeTransferFrom(address(usdToken),_msgSender(),fundingWallet, fee[2]);

    //    emit TransferTokens(_msgSender(), fundingWallet, initialfee);
    }

    function priceOfToken(uint256 amount, address[] memory path) public view returns (uint[] memory amounts){
        amounts =  uniswapRouter.getAmountsOut(amount, path);
        return amounts;
    }

    function priceOfUSDinETH() public view returns(uint ) {
        return initialfee.div(getLatestPrice());
    }

    // latest Eth Price
    function getLatestPrice() public view  returns(uint) {
        (/*uint80 roundID*/,int price, /*uint startedAt*/,
        /*uint timeStamp*/,/*uint80 answeredInRound*/) = priceFeed.latestRoundData();
        
        return uint(price);
    }

    function veto(uint256 proposalId) external {
        require(vetoer != address(0), 'TomiDAO::veto: veto power burned');
        require(msg.sender == vetoer, 'TomiDAO::veto: only vetoer');
        require(state(proposalId) != ProposalState.Executed, 'TomiDAO::veto: cannot veto executed proposal');

        Proposal storage proposal = proposals[proposalId];
                
        for(uint8 i = 0; i<proposal.nftId.length; i++){
           nftUsed[proposal.nftId[i]] = false;
        }
        iteration++;
        proposal.vetoed = true;
        transactionState[proposalId] = uint(ProposalState.Vetoed);

        emit ProposalVetoed(proposalId);
    }



    function ExtraMethod() public view returns(uint, uint, Proposaltype memory){
        Proposaltype memory pc = porposalCriteria[1];
        // return pc;
        uint a = (400 * pc.qourumVotes) .div(100);
        uint b  = (a.mul(pc.consesusVotes)).div(100);
        return(a,b, pc);
    }

    function execute(uint256 proposalId) external {
        require(
            state(proposalId) == ProposalState.Succeeded || state(proposalId) == ProposalState.Defeated,
            "TomiDAO::execute: proposal can only be executed if it has succeeded"
        );

        // ProposalEmission storage proposal = proposalsEmission[proposalId];

        ProposalEmission storage proposal = proposalsEmission[proposalId];

        require(block.timestamp >= proposal.endBlock, "Proposal is Active");
        // check vote count and qourum here


        Proposaltype memory pc = porposalCriteria[proposal.functionId];

        // pc.consesusVotes
        uint currentQourum = (tomiNFT.totalSupply().mul(pc.qourumVotes)).div(100);
        uint currentRequiredPercentage  = (currentQourum.mul(pc.consesusVotes)).div(100);

        require(proposal.forVotes >= currentRequiredPercentage, "pc.consesusVotes Consensus required to execute this proposal");

        proposal.executed = true;

        for(uint8 i = 0; i<proposal.nftId.length; i++){
           nftUsed[proposal.nftId[i]] = false;
        }
        iteration++;
        proposal.functionId;

        transactionState[proposalId] = uint(ProposalState.Executed);

        IERC20.emissionCriteria memory proposalEmission = proposal.emission;

        emit ProposalExecuted(proposalId);
        return tomiToken.updateEmissions(proposalEmission);
    }

    function executeWallets(uint256 proposalId) external {
        require(
            state(proposalId) == ProposalState.Succeeded || state(proposalId) == ProposalState.Defeated,
            "TomiDAO::execute: proposal can only be executed if it has succeeded"
        );

        // ProposalEmission storage proposal = proposalsEmission[proposalId];

        ProposalWalletUpdate storage proposal = proposalMarektWalletUpdate[proposalId];

        require(block.timestamp >= proposal.endBlock, "Proposal is Active");
        // check vote count and qourum here
        // require(state(proposalId))

        Proposaltype memory pc = porposalCriteria[proposal.functionId];

        // pc.consesusVotes
        uint currentQourum = (tomiNFT.totalSupply().mul(pc.qourumVotes)).div(100);
        uint currentRequiredPercentage  = (currentQourum.mul(pc.consesusVotes)).div(100);

        require(proposal.forVotes >= currentRequiredPercentage, "pc.consesusVotes Consensus required to execute this proposal");

        proposal.executed = true;

        for(uint8 i = 0; i<proposal.nftId.length; i++){
           nftUsed[proposal.nftId[i]] = false;
        }
        iteration++;
        proposal.functionId;

        transactionState[proposalId] = uint(ProposalState.Executed);
        uint functionId = proposal.functionId;
    
        if(functionId == 2){
            tomiToken.updateMarketingWallet(proposal.wallet);
        }else if(functionId == 3){
            tomiToken.updateTomiWallet(proposal.wallet);
        }else if(functionId == 4){
            tomiToken.changeBlockState(proposal.wallet);
        }else {
            require(false, "wrong function id call");
        }

        emit ProposalExecuted(proposalId);
        // TODO
        // return tomiToken.updateEmissions(proposalEmission);
    }

    function cancel(uint256 proposalId) external {
        require(state(proposalId) != ProposalState.Executed, "TomiDAO::cancel: cannot cancel executed proposal");

        Proposal storage proposal = proposals[proposalId];
        require(msg.sender == proposal.proposer, "NounsDAO::cancel: proposer above threshold");
        for(uint8 i = 0; i<proposal.nftId.length; i++){
           nftUsed[proposal.nftId[i]] = false;
        }
        iteration++;

        proposal.canceled = true;
        
        transactionState[proposalId] = uint(ProposalState.Canceled);

        emit ProposalCanceled(proposalId);
    }

    function addMoreProposalType(uint index, uint qourumVotes, uint consesusVotes, uint votingPeriod, string memory name) public onlyOwner {
              porposalCriteria[index] = Proposaltype(qourumVotes, consesusVotes, votingPeriod, name);
    }

    function _setVetoer(address newVetoer) public onlyOwner{
        require(msg.sender == vetoer, 'TomiDAO::_setVetoer: vetoer only');
        emit NewVetoer(vetoer, newVetoer);
        vetoer = newVetoer;
    }

    function _burnVetoPower() public onlyOwner{
        require(msg.sender == vetoer, 'TomiDAO::_burnVetoPower: vetoer only');

        _setVetoer(address(0));
    }
}