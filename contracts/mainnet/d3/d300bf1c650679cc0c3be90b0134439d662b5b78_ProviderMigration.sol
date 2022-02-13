pragma solidity ^0.8.10;

import "@openzeppelin/contracts/utils/Context.sol";
import "./Uniswap/IUniswapV2Pair.sol";
import "./Uniswap/IUniswapV2Router.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Uniswap/UniswapV2Library.sol";
import "@labrysio/aurox-contracts/contracts/Provider/Provider.sol";
import "./IProviderMigration.sol";

import "hardhat/console.sol";

contract ProviderMigration is Context, Ownable, IProviderMigration {
  IUniswapV2Router public UniswapRouter =
    IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

  IUniswapV2Pair public immutable LPToken_V1;
  IERC20 public immutable UrusToken_V1;
  IERC20 public immutable WETH;

  IERC20 public UrusToken_V2;
  IUniswapV2Pair public LPToken_V2;
  Provider public ProviderContract;

  uint256 public createdLPTokenTotal;
  uint256 public tokenBalanceTotal;
  bool public positionsClosed;

  address[] public users;
  mapping(address => uint256) public balances;

  constructor(
    address wethAddress,
    address lpTokenV1Address,
    address urusTokenV1Address,
    address ownerAddress
  ) {
    LPToken_V1 = IUniswapV2Pair(lpTokenV1Address);
    UrusToken_V1 = IERC20(urusTokenV1Address);

    WETH = IERC20(wethAddress);

    transferOwnership(ownerAddress);
  }

  function setUrusV2Token(IERC20 _UrusToken_V2) external override onlyOwner {
    UrusToken_V2 = _UrusToken_V2;

    emit SetUrusV2Address(address(_UrusToken_V2));
  }

  function setProviderV2(Provider _ProviderContract)
    external
    override
    onlyOwner
  {
    ProviderContract = _ProviderContract;

    emit SetProviderV2Address(address(_ProviderContract));
  }

  function getUsers() external view override returns (address[] memory) {
    return users;
  }

  receive() external payable {}

  function addTokens(uint256 _amount) external override returns (bool) {
    require(_amount > 0, "User must be depositing more than 0 tokens");
    require(positionsClosed == false, "LP Position has already been closed");

    // If this is the first time they are adding tokens, add the user to the users array
    if (balances[_msgSender()] == 0) {
      users.push(_msgSender());
    }

    balances[_msgSender()] += _amount;
    tokenBalanceTotal += _amount;

    LPToken_V1.transferFrom(_msgSender(), address(this), _amount);

    emit TokensAdded(_msgSender(), _amount);

    return true;
  }

  function withdrawETH() external override onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }

  function withdraw(IERC20 Token) external override onlyOwner {
    require(
      Token.transfer(owner(), Token.balanceOf(address(this))),
      "Transferring ERC20 Token failed"
    );
  }

  function _applySlippage(uint256 _value) private pure returns (uint256) {
    return (_value * 9) / 10;
  }

  function returnUsersLPShare(address user)
    public
    view
    override
    returns (uint256 share)
  {
    require(
      address(LPToken_V2) != address(0x0),
      "New position hasn't been created yet"
    );

    uint256 balance = balances[user];

    // (balance / total) * NewTotal
    share = ((balance * 1 ether) / tokenBalanceTotal);
  }

  function returnUsersLPTokenAmount(address user)
    public
    view
    override
    returns (uint256 amount)
  {
    uint256 share = returnUsersLPShare(user);

    amount = (share * createdLPTokenTotal) / 1 ether;
  }

  function removeUserFromArray(address _user) private {
    uint8 index;

    // Interate over each user to find the matching one
    for (uint256 i = 0; i < users.length; i++) {
      if (users[i] == _user) {
        index = uint8(i);
        break;
      }
    }
    // If the user is found update the array
    if (users.length > 1) {
      users[index] = users[users.length - 1];
    }
    // Remove last item
    users.pop();
  }

  function distributeTokens(Provider.MigrateArgs[] memory migrateArgs)
    external
    override
    onlyOwner
  {
    require(
      address(LPToken_V2) != address(0x0),
      "New position hasn't been created yet"
    );
    require(users.length > 0, "No users left to migrate");

    uint256 totalTransferAmount;

    // Distribute new position to all users
    for (uint256 i = 0; i < migrateArgs.length; i++) {
      address user = migrateArgs[i]._user;

      require(
        balances[user] > 0,
        "Can't distribute tokens for 0 balance users"
      );

      // Pass in the migrateArgs and replace the _amount for each item. This is cheaper than reassigning the array with the _amount field added in.
      uint256 claimableAmount = returnUsersLPTokenAmount(user);

      migrateArgs[i]._amount = claimableAmount;

      totalTransferAmount += claimableAmount;

      balances[user] = 0;

      removeUserFromArray(user);
    }

    LPToken_V2.approve(address(ProviderContract), totalTransferAmount);

    ProviderContract.migrateUsersLPPositions(migrateArgs);

    emit TokensDistributed(migrateArgs);
  }

  function closePositions() external override onlyOwner returns (bool status) {
    require(positionsClosed == false, "LP Position has already been closed");
    uint256 totalLiquidity = LPToken_V1.balanceOf(address(this));

    require(totalLiquidity > 0, "No liquidity to close positions with");

    positionsClosed = true;

    // Get the total supply
    uint256 totalSupply = LPToken_V1.totalSupply();

    (uint112 reserve0, uint112 reserve1, ) = LPToken_V1.getReserves();

    // userLiquidity * reserves / totalSupply
    uint256 liquidityValue0 = (totalLiquidity * reserve0) / totalSupply;
    uint256 liquidityValue1 = (totalLiquidity * reserve1) / totalSupply;

    LPToken_V1.approve(address(UniswapRouter), totalLiquidity);

    UniswapRouter.removeLiquidityETH(
      address(UrusToken_V1),
      totalLiquidity,
      // Apply 10% slippage
      // Minimum amount of URUS
      _applySlippage(liquidityValue0),
      // Minimum amount of ETH
      _applySlippage(liquidityValue1),
      address(this),
      // Deadline is now + 300 seconds
      block.timestamp + 300
    );

    emit ClosePositions();

    return true;
  }

  function createNewPosition() external override onlyOwner {
    uint256 urusBalance = UrusToken_V2.balanceOf(address(this));

    UrusToken_V2.approve(address(UniswapRouter), urusBalance);

    UniswapRouter.addLiquidityETH{ value: address(this).balance }(
      address(UrusToken_V2),
      urusBalance,
      _applySlippage(urusBalance),
      _applySlippage(address(this).balance),
      address(this),
      block.timestamp + 300
    );

    address LPToken_V2Address = UniswapV2Library.pairFor(
      UniswapRouter.factory(),
      address(UrusToken_V2),
      address(WETH)
    );

    LPToken_V2 = IUniswapV2Pair(LPToken_V2Address);

    createdLPTokenTotal = LPToken_V2.balanceOf(address(this));

    emit NewPositionCreated(LPToken_V2Address, createdLPTokenTotal);
  }
}

// SPDX-License-Identifier: MIT

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

// Stub file for the uniswap V2 pair so that the latest version of solidity can be used
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IUniswapV2Pair is IERC20 {
  function burn(address to) external returns (uint256 amount0, uint256 amount1);

  function getReserves()
    external
    view
    returns (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    );
}

// interface IUniswapV2Pair {
//   event Approval(address indexed owner, address indexed spender, uint value);
//   event Transfer(address indexed from, address indexed to, uint value);

//   function name() external pure returns (string memory);
//   function symbol() external pure returns (string memory);
//   function decimals() external pure returns (uint8);
//   function totalSupply() external view returns (uint);
//   function balanceOf(address owner) external view returns (uint);
//   function allowance(address owner, address spender) external view returns (uint);

//   function approve(address spender, uint value) external returns (bool);
//   function transfer(address to, uint value) external returns (bool);
//   function transferFrom(address from, address to, uint value) external returns (bool);

//   function DOMAIN_SEPARATOR() external view returns (bytes32);
//   function PERMIT_TYPEHASH() external pure returns (bytes32);
//   function nonces(address owner) external view returns (uint);

//   function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

//   event Mint(address indexed sender, uint amount0, uint amount1);
//   event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
//   event Swap(
//       address indexed sender,
//       uint amount0In,
//       uint amount1In,
//       uint amount0Out,
//       uint amount1Out,
//       address indexed to
//   );
//   event Sync(uint112 reserve0, uint112 reserve1);

//   function MINIMUM_LIQUIDITY() external pure returns (uint);
//   function factory() external view returns (address);
//   function token0() external view returns (address);
//   function token1() external view returns (address);
//
//   function price0CumulativeLast() external view returns (uint);
//   function price1CumulativeLast() external view returns (uint);
//   function kLast() external view returns (uint);

//   function mint(address to) external returns (uint liquidity);
//   function burn(address to) external returns (uint amount0, uint amount1);
//   function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
//   function skim(address to) external;
//   function sync() external;
// }

pragma solidity >=0.6.2;

interface IUniswapV2Router {
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

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

library UniswapV2Library {
  // returns sorted token addresses, used to handle return values from pairs sorted in this order
  function sortTokens(address tokenA, address tokenB)
    internal
    pure
    returns (address token0, address token1)
  {
    require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
    (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
  }

  // calculates the CREATE2 address for a pair without making any external calls
  function pairFor(
    address factory,
    address tokenA,
    address tokenB
  ) internal pure returns (address pair) {
    (address token0, address token1) = sortTokens(tokenA, tokenB);
    pair = address(
      uint160(
        uint256(
          keccak256(
            abi.encodePacked(
              hex"ff",
              factory,
              keccak256(abi.encodePacked(token0, token1)),
              hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f" // init code hash
            )
          )
        )
      )
    );
  }
}

pragma solidity 0.8.10;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../StakingMaster/IStakingMaster.sol";
import "./IProvider.sol";
import "./EpochHelpers.sol";
import "./RewardHelpers.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "hardhat/console.sol";

contract Provider is
    IProvider,
    Context,
    ReentrancyGuard,
    EpochHelpers,
    RewardHelpers
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 private UniSwapToken;

    IERC20 private AuroxToken;

    IStakingMaster private StakingMasterContract;

    address public migrationContractAddress;

    // For storing user details
    mapping(address => UserDetails) public userInvestments;

    // If the user accidentally transfers ETH into the contract, revert the transfer
    fallback() external payable {
        revert("Cannot send ether to this contract");
    }

    // Events for the various actions
    event AddLiquidity(address indexed _from, uint256 _amount);

    event RemoveLiquidity(address indexed _from, uint256 _amount);

    event ClaimRewards(
        address indexed _from,
        uint256 _amount,
        bool indexed _sendRewardsToStaking
    );

    constructor(
        address _uniSwapTokenAddress,
        address _auroxTokenAddress,
        address _stakingMaster,
        uint256 _epochStart,
        address _migrationContractAddress
    ) {
        epochStart = _epochStart;
        UniSwapToken = IERC20(_uniSwapTokenAddress);
        AuroxToken = IERC20(_auroxTokenAddress);
        StakingMasterContract = IStakingMaster(_stakingMaster);

        migrationContractAddress = _migrationContractAddress;
    }

    // Return the users total investment amount
    function returnUsersInvestmentTotal(address _user)
        public
        view
        override
        returns (uint256)
    {
        EpochInvestmentDetails memory latestInvestmentDetails = userInvestments[
            _user
        ].epochTotals[userInvestments[_user].lastEpochUpdate];
        // Return the users investment total based on the epoch they edited last
        uint256 investmentTotal = _returnEpochAmountIncludingCurrentTotal(
            latestInvestmentDetails
        );
        return (investmentTotal);
    }

    // Returns a user's epoch totals for a given epoch
    function returnUsersEpochTotals(uint256 epoch, address _user)
        public
        view
        override
        returns (
            uint256 shareTotal,
            uint256 currentInvestmentTotal,
            uint256 allPrevInvestmentTotals
        )
    {
        EpochInvestmentDetails memory investmentDetails = userInvestments[_user]
            .epochTotals[epoch];
        return (
            investmentDetails.shareTotal,
            investmentDetails.currentInvestmentTotal,
            investmentDetails.allPrevInvestmentTotals
        );
    }

    function returnEpochShare(uint256 _amount, uint256 currentEpoch)
        public
        returns (uint256 share)
    {
        uint256 secondsToEpochEnd = _getSecondsToEpochEnd(currentEpoch);

        return _amount.mul(secondsToEpochEnd).div(epochLength);
    }

    function _updateUserDetailsAndEpochAmounts(
        address _userAddress,
        uint256 _amount
    ) internal {
        // Get the current epoch
        uint256 currentEpoch = _returnEpochToTimestamp(block.timestamp);

        UserDetails storage currentUser = userInvestments[_userAddress];

        if (currentUser.lastEpochUpdate == 0) {
            // Set the epoch for grabbing values to be this epoch.
            currentUser.lastLiquidityAddedEpochReference = currentEpoch;

            // Update when they last claimed to now, so they can't claim rewards for past epochs
            currentUser.lastClaimedTimestamp = block.timestamp;
        }

        uint256 usersTotal = _returnEpochAmountIncludingCurrentTotal(
            currentUser.epochTotals[currentUser.lastEpochUpdate]
        );
        // If they havent had an amount in the liquidity provider reset their boost reward, so they don't unexpectedly have a 100% boost reward immediately
        if (usersTotal == 0) {
            // TODO potentially a problem
            // Breaking tests when removed
            currentUser.lastEpochLiquidityWithdrawn = currentEpoch;

            // If they've claimed all rewards for their past investments, reset their last claimed timestamp to prevent them from looping uselessly
            uint256 lastClaimedEpoch = _returnEpochToTimestamp(
                currentUser.lastClaimedTimestamp
            );
            if (lastClaimedEpoch > currentUser.lastEpochUpdate) {
                currentUser.lastClaimedTimestamp = block.timestamp;
            }
        }

        // Normalise the epoch share as amount * secondsToEpochEnd / epochlength;
        uint256 epochShare = returnEpochShare(_amount, currentEpoch);

        // If the user hasn't added to the current epoch, carry over their investment total into the current epoch totals and update the reference for grabbing up to date user totals
        if (currentUser.lastEpochUpdate < currentEpoch) {
            // The pulled forward user's total investment amount
            uint256 allPrevInvestmentTotals = currentUser
                .epochTotals[currentUser.lastEpochUpdate]
                .allPrevInvestmentTotals;

            // Add the allPrevInvestmentTotals to the currentInvestmentTotal to reflect the new overall investment total
            uint256 pulledForwardTotal = allPrevInvestmentTotals.add(
                currentUser
                    .epochTotals[currentUser.lastEpochUpdate]
                    .currentInvestmentTotal
            );

            // Update the investment total by pulling forward the total amount from when the user last added liquidity
            currentUser
                .epochTotals[currentEpoch]
                .allPrevInvestmentTotals = pulledForwardTotal;

            // Update when liquidity was added last
            currentUser.lastEpochUpdate = currentEpoch;
        }

        // Update the share total for the current epoch

        currentUser.epochTotals[currentEpoch].shareTotal = currentUser
            .epochTotals[currentEpoch]
            .shareTotal
            .add(epochShare);

        // Update the user's currentInvestmentTotal to include the added amount
        currentUser
            .epochTotals[currentEpoch]
            .currentInvestmentTotal = currentUser
            .epochTotals[currentEpoch]
            .currentInvestmentTotal
            .add(_amount);

        /* Do the same calculations but add it to the overall totals not the users */

        // If the investment total hasn't been carried over into the "new" epoch
        if (lastEpochUpdate < currentEpoch) {
            // The pulled forward everyone's total amount
            uint256 allPrevInvestmentTotals = epochAmounts[lastEpochUpdate]
                .allPrevInvestmentTotals;

            // The total pulled forward amount, including investments made on that epoch.
            uint256 overallPulledForwardTotal = allPrevInvestmentTotals.add(
                epochAmounts[lastEpochUpdate].currentInvestmentTotal
            );

            // Update the current epoch investment total to have the pulled forward totals from all other epochs.
            epochAmounts[currentEpoch]
                .allPrevInvestmentTotals = overallPulledForwardTotal;

            // Update the lastEpochUpdate value
            lastEpochUpdate = currentEpoch;
        }

        // Update the share total for everyone to include the additional amount
        epochAmounts[currentEpoch].shareTotal = epochAmounts[currentEpoch]
            .shareTotal
            .add(epochShare);

        // Update the current investment total for everyone
        epochAmounts[currentEpoch].currentInvestmentTotal = epochAmounts[
            currentEpoch
        ].currentInvestmentTotal.add(_amount);
    }

    function addLiquidity(uint256 _amount) external override nonReentrant {
        require(block.timestamp > epochStart, "Epoch one hasn't started yet");
        require(_amount != 0, "Cannot add a 0 amount");

        require(
            UniSwapToken.allowance(_msgSender(), address(this)) >= _amount,
            "Allowance of Provider not large enough for the required amount"
        );
        // Require the user to have enough balance for the transfer amount
        require(
            UniSwapToken.balanceOf(_msgSender()) >= _amount,
            "Balance of the sender not large enough for the required amount"
        );

        UniSwapToken.safeTransferFrom(_msgSender(), address(this), _amount);

        _updateUserDetailsAndEpochAmounts(_msgSender(), _amount);

        emit AddLiquidity(_msgSender(), _amount);
    }

    function applyEpochRewardBonus(
        uint256 _epochBonusMultiplier,
        uint256 _epochRewards
    ) private pure returns (uint256) {
        if (_epochBonusMultiplier > 10) {
            _epochBonusMultiplier = 10;
        }

        return
            _epochRewards.add(_epochRewards.mul(_epochBonusMultiplier).div(10));
    }

    function saveMigrationUserDetails(
        MigrateArgs calldata migrateArgs,
        uint256 currentEpoch
    ) private {
        UserDetails storage currentUser = userInvestments[migrateArgs._user];

        // Set all the epoch tracking values
        currentUser.lastEpochUpdate = currentEpoch;

        currentUser.lastClaimedTimestamp = block.timestamp;

        currentUser.lastEpochLiquidityWithdrawn = currentEpoch;

        currentUser.lastLiquidityAddedEpochReference = currentEpoch;

        currentUser.bonusRewardMultiplier = migrateArgs._bonusRewardMultiplier;

        // Calculate the epoch share for the user
        uint256 epochShare = returnEpochShare(
            migrateArgs._amount,
            currentEpoch
        );

        // Update this specific users total
        currentUser.epochTotals[currentEpoch].shareTotal = epochShare;

        currentUser
            .epochTotals[currentEpoch]
            .currentInvestmentTotal = migrateArgs._amount;

        // Update the totals for all the users
        epochAmounts[currentEpoch].shareTotal = epochAmounts[currentEpoch]
            .shareTotal
            .add(epochShare);

        epochAmounts[currentEpoch].currentInvestmentTotal = epochAmounts[
            currentEpoch
        ].currentInvestmentTotal.add(migrateArgs._amount);
    }

    function migrateUsersLPPositions(MigrateArgs[] calldata allMigrateArgs)
        external
        override
    {
        // TODO Double checking with giorgi
        require(block.timestamp > epochStart, "Epoch one hasn't started yet");

        require(
            _msgSender() == migrationContractAddress,
            "Provider: Only the migration contract can call this function"
        );

        uint256 currentEpoch = _returnEpochToTimestamp(block.timestamp);
        uint256 transferTotal;

        for (uint8 i = 0; i < allMigrateArgs.length; i++) {
            transferTotal += allMigrateArgs[i]._amount;
            saveMigrationUserDetails(allMigrateArgs[i], currentEpoch);
        }

        lastEpochUpdate = currentEpoch;

        UniSwapToken.transferFrom(
            migrationContractAddress,
            address(this),
            transferTotal
        );
    }

    function returnAllClaimableRewardAmounts(address _user)
        public
        view
        override
        returns (
            uint256 rewardTotal,
            uint256 lastLiquidityAddedEpochReference,
            uint256 lastEpochLiquidityWithdrawn
        )
    {
        UserDetails storage currentUser = userInvestments[_user];

        // If the user has no investments return 0
        if (currentUser.lastEpochUpdate == 0) {
            return (0, 0, 0);
        }

        uint256 currentEpoch = _returnEpochToTimestamp(block.timestamp);

        // uint256 rewardTotal;

        // The last epoch they claimed from, to seed the start of the for-loop
        uint256 lastEpochClaimed = _returnEpochToTimestamp(
            currentUser.lastClaimedTimestamp
        );

        // To hold the users total in a given epoch
        uint256 usersEpochTotal;

        // To hold the overall total in a given epoch
        uint256 overallEpochTotal;

        // Reference to grab the user's latest epoch totals
        uint256 lastLiquidityAddedEpochReference = currentUser
            .lastLiquidityAddedEpochReference;

        // Reference to grab the overall epoch totals
        uint256 overallLastLiquidityAddedEpochReference = lastLiquidityAddedEpochReference;

        uint256 lastEpochLiquidityWithdrawn = currentUser
            .lastEpochLiquidityWithdrawn;

        for (uint256 epoch = lastEpochClaimed; epoch <= currentEpoch; epoch++) {
            // If the user withdrew liquidity in this epoch, update their reference for when they last withdrew liquidity
            if (currentUser.epochTotals[epoch].withdrewLiquidity) {
                lastEpochLiquidityWithdrawn = epoch;
            }

            // If the user did invest in this epoch, then their total investment amount is allTotals + shareAmount
            if (currentUser.epochTotals[epoch].shareTotal != 0) {
                // Update the reference for where to find values
                if (lastLiquidityAddedEpochReference != epoch) {
                    lastLiquidityAddedEpochReference = epoch;
                }
                // Update the user's total to include the share amount, as they invested in this epoch
                usersEpochTotal = _returnEpochAmountIncludingShare(
                    currentUser.epochTotals[epoch]
                );
            } else {
                // Prevent this statement executing multiple times by only executing it after the epoch reference is updated or if the value hasn't been set yet
                if (
                    epoch == lastLiquidityAddedEpochReference.add(1) ||
                    usersEpochTotal == 0
                ) {
                    usersEpochTotal = _returnEpochAmountIncludingCurrentTotal(
                        currentUser.epochTotals[
                            lastLiquidityAddedEpochReference
                        ]
                    );
                }
            }

            // If no rewards to be claimed for the current epoch, skip this loop
            if (usersEpochTotal == 0) continue;

            // If any user added amounts during this epoch, then update the overall total to include their share totals
            if (epochAmounts[epoch].shareTotal != 0) {
                // Update the reference of where to find an epoch total
                if (overallLastLiquidityAddedEpochReference != epoch) {
                    overallLastLiquidityAddedEpochReference = epoch;
                }
                // Set the overall epoch total to include the share
                overallEpochTotal = _returnEpochAmountIncludingShare(
                    epochAmounts[epoch]
                );
            } else {
                // Prevent this statement executing multiple times by only executing it after the epoch reference is updated or if the value hasn't been set yet
                if (
                    epoch == overallLastLiquidityAddedEpochReference.add(1) ||
                    overallEpochTotal == 0
                ) {
                    overallEpochTotal = _returnEpochAmountIncludingCurrentTotal(
                        epochAmounts[overallLastLiquidityAddedEpochReference]
                    );
                }
            }

            // Calculate the reward share for the epoch
            uint256 epochRewardShare = _calculateRewardShareForEpoch(
                epoch,
                currentEpoch,
                lastEpochClaimed,
                currentUser.lastClaimedTimestamp,
                usersEpochTotal,
                overallEpochTotal
            );

            // TODO this could be incorrect
            uint256 epochsCompleteWithoutWithdrawal = 0;

            if (lastEpochLiquidityWithdrawn < epoch) {
                epochsCompleteWithoutWithdrawal = epoch.sub(
                    lastEpochLiquidityWithdrawn
                );
            }

            if (epoch != currentEpoch) {
                epochRewardShare = applyEpochRewardBonus(
                    // Add the bonus reward multiplier to the reward multiplier
                    epochsCompleteWithoutWithdrawal.add(
                        currentUser.bonusRewardMultiplier
                    ),
                    epochRewardShare
                );
            }

            rewardTotal = rewardTotal.add(epochRewardShare);
        }

        return (
            rewardTotal,
            lastLiquidityAddedEpochReference,
            lastEpochLiquidityWithdrawn
        );
    }

    function claimRewards(bool _sendRewardsToStaking, uint256 stakeDuration)
        public
        override
        nonReentrant
    {
        UserDetails storage currentUser = userInvestments[_msgSender()];

        // require the user to actually have an investment amount
        require(
            currentUser.lastEpochUpdate > 0,
            "User has no rewards to claim, as they have never added liquidity"
        );

        (
            uint256 allClaimableAmounts,
            uint256 lastLiquidityAddedEpochReference,
            uint256 lastEpochLiquidityWithdrawn
        ) = returnAllClaimableRewardAmounts(_msgSender());

        // If the user has never added liquidity, simply return and don't update any details onchain
        if (lastLiquidityAddedEpochReference == 0) {
            return;
        }

        currentUser
            .lastLiquidityAddedEpochReference = lastLiquidityAddedEpochReference;

        currentUser.lastEpochLiquidityWithdrawn = lastEpochLiquidityWithdrawn;

        // Update their last claim to now
        currentUser.lastClaimedTimestamp = block.timestamp;

        // Return if no rewards to claim. Don't revert otherwise the user's details won't update to now and they will continually loop over epoch's that contain no rewards.
        if (allClaimableAmounts == 0) {
            return;
        }

        if (_sendRewardsToStaking) {
            // Return a valid stake for the user
            address usersStake = StakingMasterContract
                .returnValidUsersProviderStake(_msgSender());

            // If the stake is valid add the amount to it
            if (usersStake != address(0)) {
                StakingMasterContract.addToStake(
                    usersStake,
                    allClaimableAmounts
                );
                // Otherwise create a new stake for the user
            } else {
                StakingMasterContract.createStaking(
                    allClaimableAmounts,
                    stakeDuration,
                    _msgSender()
                );
            }
            // If not sending the rewards to staking simply sends the rewards back to the user
        } else {
            AuroxToken.safeTransferFrom(
                address(AuroxToken),
                _msgSender(),
                allClaimableAmounts
            );
        }

        emit ClaimRewards(
            _msgSender(),
            allClaimableAmounts,
            _sendRewardsToStaking
        );
    }

    function removeLiquidity(uint256 _amount) public override nonReentrant {
        UserDetails storage currentUser = userInvestments[_msgSender()];

        // The epoch the user last added liquidity, this will give the latest version of their total amounts

        EpochInvestmentDetails
            storage usersLastAddedLiquidityEpochInvestmentDetails = currentUser
                .epochTotals[currentUser.lastEpochUpdate];

        // Calculate the user's total based on when they last added liquidity

        uint256 usersTotal = _returnEpochAmountIncludingCurrentTotal(
            usersLastAddedLiquidityEpochInvestmentDetails
        );

        // Ensure the user has enough amount to deduct the balance
        require(
            usersTotal >= _amount,
            "User doesn't have enough balance to withdraw the amount"
        );

        uint256 currentEpoch = _returnEpochToTimestamp(block.timestamp);

        // The users investment details for the current epoch
        EpochInvestmentDetails
            storage usersCurrentEpochInvestmentDetails = currentUser
                .epochTotals[currentEpoch];

        /* Calculate how much to remove from the user's share total if they have invested in the same epoch they are removing from */

        // How many seconds they can claim from the current epoch
        uint256 claimSecondsForPulledLiquidity = _returnClaimSecondsForPulledLiquidity(
                currentUser.lastClaimedTimestamp,
                currentEpoch
            );

        // How much the _amount is claimable since epoch start or when they last claimed rewards
        uint256 claimAmountOnPulledLiquidity = _amount
            .mul(claimSecondsForPulledLiquidity)
            .div(epochLength);

        // In the very rare case that they have no claim to the pulled liquidity, set the value to 1. This negates issues in the claim rewards function
        if (claimAmountOnPulledLiquidity == 0) {
            claimAmountOnPulledLiquidity = 1;
        }

        // If they have a share total in this epoch, then deduct it from the overall total and add the new calculated share total
        if (usersCurrentEpochInvestmentDetails.shareTotal != 0) {
            epochAmounts[currentEpoch].shareTotal = epochAmounts[currentEpoch]
                .shareTotal
                .sub(usersCurrentEpochInvestmentDetails.shareTotal);
        }

        // NOTE: They lose the reward amount they've earnt on a share total. If they add liqudiity and pull in same epoch they lose rewards earnt on the share total.
        usersCurrentEpochInvestmentDetails
            .shareTotal = claimAmountOnPulledLiquidity;

        // If they haven't updated in this epoch. Pull the total forward minus the amount
        if (currentUser.lastEpochUpdate != currentEpoch) {
            // Update the overall total to refelct the updated amount
            usersCurrentEpochInvestmentDetails
                .allPrevInvestmentTotals = usersTotal.sub(_amount);

            // Update when it was last updated
            currentUser.lastEpochUpdate = currentEpoch;
        } else {
            // If there isn't enough in the allPrevInvestmentTotal for the subtracted amount
            if (
                usersLastAddedLiquidityEpochInvestmentDetails
                    .allPrevInvestmentTotals < _amount
            ) {
                // Update the amount so it deducts the allPrevAmount
                uint256 usersRemainingAmount = _amount.sub(
                    usersLastAddedLiquidityEpochInvestmentDetails
                        .allPrevInvestmentTotals
                );

                // Set the prev investment total to 0
                usersCurrentEpochInvestmentDetails.allPrevInvestmentTotals = 0;

                // Deduct from the currentInvestmentTotal the remaining _amount
                usersCurrentEpochInvestmentDetails
                    .currentInvestmentTotal = usersLastAddedLiquidityEpochInvestmentDetails
                    .currentInvestmentTotal
                    .sub(usersRemainingAmount);
            } else {
                // Subtract from their allPrevInvestmentTotal the amount to deduct and then update the user's total on the current epoch to be the new amounts
                usersCurrentEpochInvestmentDetails
                    .allPrevInvestmentTotals = usersLastAddedLiquidityEpochInvestmentDetails
                    .allPrevInvestmentTotals
                    .sub(_amount);

                // Pull forward the current investment total
                usersCurrentEpochInvestmentDetails
                    .currentInvestmentTotal = usersLastAddedLiquidityEpochInvestmentDetails
                    .currentInvestmentTotal;
            }
        }

        // Update when the user last withdrew liquidity
        // currentUser.lastEpochLiquidityWithdrawn = currentEpoch;
        usersCurrentEpochInvestmentDetails.withdrewLiquidity = true;

        // Update the share total
        epochAmounts[currentEpoch].shareTotal = epochAmounts[currentEpoch]
            .shareTotal
            .add(claimAmountOnPulledLiquidity);
        // If the epoch amounts for this epoch haven't been updated
        if (lastEpochUpdate != currentEpoch) {
            uint256 overallEpochTotal = _returnEpochAmountIncludingCurrentTotal(
                epochAmounts[lastEpochUpdate]
            );

            // Update the overall total to refelct the updated amount
            epochAmounts[currentEpoch]
                .allPrevInvestmentTotals = overallEpochTotal.sub(_amount);

            // Update when it was last updated
            lastEpochUpdate = currentEpoch;
        } else {
            // If there isnt enough in the total investment totals for the amount
            if (epochAmounts[currentEpoch].allPrevInvestmentTotals < _amount) {
                // Update the amount so it deducts the allPrevAmount
                uint256 overallRemainingAmount = _amount.sub(
                    epochAmounts[currentEpoch].allPrevInvestmentTotals
                );

                // Set the prev investment total to 0
                epochAmounts[currentEpoch].allPrevInvestmentTotals = 0;

                // Deduct from the currentInvestmentTotal the remaining _amount
                epochAmounts[currentEpoch]
                    .currentInvestmentTotal = epochAmounts[currentEpoch]
                    .currentInvestmentTotal
                    .sub(overallRemainingAmount);
            } else {
                // Subtract from their allPrevInvestmentTotal the amount to deduct and then update the user's total on the current epoch to be the new amounts
                epochAmounts[currentEpoch]
                    .allPrevInvestmentTotals = epochAmounts[currentEpoch]
                    .allPrevInvestmentTotals
                    .sub(_amount);

                // Pull forward the current investment total
                epochAmounts[currentEpoch]
                    .currentInvestmentTotal = epochAmounts[currentEpoch]
                    .currentInvestmentTotal;
            }
        }

        // If the user is withdrawing in the first day of the epoch, then they get penalised no rewards
        if (returnIfInFirstDayOfEpoch(currentEpoch)) {
            UniSwapToken.safeTransfer(_msgSender(), _amount);
        } else {
            // Transfer 90% of the _amount to the user
            UniSwapToken.safeTransfer(_msgSender(), _amount.mul(9).div(10));
            // Transfer 10% to the burn address
            UniSwapToken.safeTransfer(
                0x0000000000000000000000000000000000000001,
                _amount.div(10)
            );
        }

        emit RemoveLiquidity(_msgSender(), _amount);
    }
}

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@labrysio/aurox-contracts/contracts/Provider/Provider.sol";

interface IProviderMigration {
  /// @notice To set the address for teh Urus V2 contract
  /// @param urusV2Address  The updated address
  event SetUrusV2Address(address urusV2Address);

  /// @notice To set the address for the Provider V2 contract
  /// @param providerV2Address  The updated address
  event SetProviderV2Address(address providerV2Address);

  /// @notice The event emitted when tokens are added into the migration contract
  /// @param user  The user who added tokens
  /// @param amount  The amount of tokens
  event TokensAdded(address indexed user, uint256 amount);

  /// @notice The emitted event when the new LP tokens are created and the admin calls the distributeTokens function with the given array of arguments.
  /// @notice Emitting the array of arguments instead of each one to reduce gas, this will reduce our ability to index and filter events but an external script will resolve this.
  /// @param migrateArgs  The user who added tokens
  event TokensDistributed(Provider.MigrateArgs[] migrateArgs);

  /// @notice Emitted event when the LP tokens held by the contract are burnt by Uniswap and the underlying collateral is returned
  event ClosePositions();

  /// @notice Emitted event when the new LP position is created
  event NewPositionCreated(address newPairAddress, uint256 newTokenTotal);

  /// @notice For setting the address for the URUS V2 token
  /// @param _UrusToken_V2  The Urus V2 token
  function setUrusV2Token(IERC20 _UrusToken_V2) external;

  /// @notice For setting the address for the Provider V2 contract
  /// @param _ProviderContract  The Provider V2 contract
  function setProviderV2(Provider _ProviderContract) external;

  /// @notice For returning all the user's who have added tokens to the migration contract
  /// @return Users  All the users
  function getUsers() external view returns (address[] memory);

  /// @notice Allows a user to add tokens into the migration contract
  /// @param _amount  The amount to add to the contract
  /// @return Status  If the operation was successful
  function addTokens(uint256 _amount) external returns (bool);

  /// @notice Allows the deployer to withdraw all ETH from the contract
  function withdrawETH() external;

  /// @notice Allows the deployer to withdraw the total of a specific token that is held by the contract
  /// @param Token  The token to withdraw amounts for
  function withdraw(IERC20 Token) external;

  /// @notice This is to be called after the LP positions held by the contract have been closed. This will take the same amount of ETH returned from the original position and with the new URUS V2 tokens it will create a new position of the same value.
  function createNewPosition() external;

  /// @notice For returning the percentage of the total amount that is claimable by the user
  /// @param user  The user to return the percentage for
  function returnUsersLPShare(address user)
    external
    view
    returns (uint256 share);

  /// @notice For returning the amount claimable by the user in the new URUS V2 position
  /// @param user  The user to return the amount for
  function returnUsersLPTokenAmount(address user)
    external
    view
    returns (uint256 amount);

  /// @notice This is to be called once the new position has been created and it needs to be distributed amount users. This function also calls for a bonusMultiplier to be passed in for each user. This is the additional bonus the user will receive once they're migrated to Provider V2
  /// @param migrateArgs  All the migration arguments for the users
  function distributeTokens(Provider.MigrateArgs[] memory migrateArgs) external;

  /// @notice This is to be called when enough liquidity is locked up in the contract, all the LP tokens held by the contract will be burnt through the Uniswap remove liquidity function
  /// @param status Whether the operation was successful
  function closePositions() external returns (bool status);
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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

pragma solidity 0.8.10;

interface IStakingMaster {
    /**
        @dev The struct containing all of a stakes data
     */
    struct Staking {
        uint256 investedAmount;
        uint256 stakeEndTime;
        uint256 interestRate;
        uint256 lastUpdate;
        bool compounded;
        // The amount they add in at the start, un-modified
        uint256 rawInvestedAmount;
        uint256 stakeStartTime;
        bool providerStake;
        uint256 released;
        bool poolRewardsClaimed;
        uint256 totalLocked;
    }

    /**
        @dev Returns a given user's total stake value across all the user's stakes, including all interest earnt up until now.
        @param _user The user to return the value for
        @return The users total stake value
     */
    function returnUsersTotalStakeValue(address _user)
        external
        view
        returns (uint256);

    /**
        @dev Creates a new stake for the user. It calculates their projected interest based on the parameters and stores it in a TokenVesting contract that vests their total amount over 2 weeks once their stake is complete. It also creates a struct containing all the relevant stake details.
        @param _amount The amount the user will be staking (in ether)
        @param _duration The duration of the stake (in months)
        @param _recipient The address of the user that will be receiving the stake rewards
     */
    function createStaking(
        uint256 _amount,
        uint256 _duration,
        address _recipient
    ) external;

    /**
        @dev Adds to a user's pre-existing stake. This can only be triggered by the Provider Contract, i.e; when a user is re-investing their rewards from the Provider Contract.
        @param _stakingAddress The address of the stake
        @param _amount The additional amount to stake
     */
    function addToStake(address _stakingAddress, uint256 _amount) external;

    /**
        @dev Claim rewards for a given stake. This releases the allowed amount from the Vesting contract and also returns them pool rewards. This can only be called when a stake is complete and by the _recipient of the stake only.
        @param _stakingAddress The address of the stake
     */
    function claimRewards(address _stakingAddress) external;

    /**
        @dev Close the given stake, this can only happen when a stake is incomplete and User wishes to close the stake early. This function calculates their penalised amount for withdrawing early and stores it in the StakingMaster contract as the pool reward. It then transfers their allowed amount back to the user.
        @param _stakingAddress The address of the stake
     */
    function closeStake(address _stakingAddress) external;

    /* Helpers */

    /**
        @dev Returns a given stakes state
        @param _stakingAddress The address of the stake

        @return currentStakeValue The current value of the stake, including interest up until now
        @return stakeEndTime When the stake will finish
        @return interestRate The interest rate of the stake
        @return lastUpdate When the stake last had value added to it, or when it was created (if no additional value has been added to the stake)
        @return compounding Whether the stake is compounding
        @return rawInvestedAmount The User's invested amount (excluding interest)
        @return stakeStartTime When the stake was created
     */
    function returnStakeState(address _stakingAddress)
        external
        view
        returns (
            uint256 currentStakeValue,
            uint256 stakeEndTime,
            uint256 interestRate,
            uint256 lastUpdate,
            bool compounding,
            uint256 rawInvestedAmount,
            uint256 stakeStartTime
        );

    /**
        @dev Returns a given user's stakes
        @param _user The user to return stakes for

        @return usersStakes An array containing the addreses of all the user's created stakes
     */
    function returnUsersStakes(address _user)
        external
        view
        returns (address[] memory usersStakes);

    /**
        @dev Returns the given stake value corresponding to the stake address

        @return _stakingAddress The staking address to return the value for
     */
    function returnCurrentStakeValue(address _stakingAddress)
        external
        view
        returns (uint256);

    /**
        @dev Returns a user's staking address if the stake is in progress and was created by the provider contract. Function intended to be called by the provider contract when the user is claiming rewards and intending them to be sent to a Staking contract
        @param _user The user to return valid stakes for

        @return The valid stake address
     */
    function returnValidUsersProviderStake(address _user)
        external
        view
        returns (address);

    /**
        @dev Returns a stakes claimable rewards, 

        @param _stakingAddress The stake to return the claimable rewards for

        @return The claimable amount
     */
    function returnStakesClaimableRewards(address _stakingAddress)
        external
        view
        returns (uint256);

    /**
        @dev Returns a stakes claimable pool rewards

        @param _stakingAddress The stake to return the claimable pool rewards for

        @return The claimable pool reward amount
     */
    function returnStakesClaimablePoolRewards(address _stakingAddress)
        external
        view
        returns (uint256);
}

pragma solidity 0.8.10;

import "./EpochHelpers.sol";

interface IProvider {
    struct UserDetails {
        uint256 lastLiquidityAddedEpochReference;
        // A number representing when the user last updated the epoch amounts
        uint256 lastEpochUpdate;
        // A timestamp representing when the user last claimed rewards
        uint256 lastClaimedTimestamp;
        // A number representing the epoch that liquidity was last drawn from
        uint256 lastEpochLiquidityWithdrawn;
        // A number representing the extra reward multiplier for V1 migrators
        uint256 bonusRewardMultiplier;
        // The mapping of epochs to investment details
        mapping(uint256 => EpochHelpers.EpochInvestmentDetails) epochTotals;
    }

    struct MigrateArgs {
        address _user;
        uint256 _amount;
        uint256 _bonusRewardMultiplier;
    }

    /**
        @dev This function allows the migration contract to re-create LP positions for users. This function will iterate over all the migration arguments and at the end transfer the total amount into the LP contract.
        @param allMigrateArgs All the users, their amounts and additional bonus rewards
     */
    function migrateUsersLPPositions(MigrateArgs[] calldata allMigrateArgs)
        external;

    /**
        @dev Returns the current user's investment total in the provider
        @param _user The user's address to return the total for
        @return The user's stake total
     */
    function returnUsersInvestmentTotal(address _user)
        external
        view
        returns (uint256);

    /**
        @dev The various investment values for a user based on a given epoch

        @param epoch The given epoch to return the values for
        @param _user The user to return totals for

        @return shareTotal The user's proportional share total based on when they invested into the epoch
        @return currentInvestmentTotal The user's raw investment total for the given epoch
        @return allPrevInvestmentTotals The sum of all amounts made into the Provider contract at the current epoch's time
     */
    function returnUsersEpochTotals(uint256 epoch, address _user)
        external
        view
        returns (
            uint256 shareTotal,
            uint256 currentInvestmentTotal,
            uint256 allPrevInvestmentTotals
        );

    /**
        @dev This function adds the liquidity to the provider contract and does all the work for the storage of epoch data, updating of totals, aggregating currentInvestmentTotal's and adding to the overall totals.

        @param _amount The amount of liquidity to add
     */
    function addLiquidity(uint256 _amount) external;

    /**
        @dev This function returns the available amount to claim for the given user.

        @param _user The address of the user to return the claimable amounts for
        @return rewardTotal The reward total to return
        @return lastLiquidityAddedEpochReference The last epoch where the user added liquidity
     */
    function returnAllClaimableRewardAmounts(address _user)
        external
        view
        returns (
            uint256 rewardTotal,
            uint256 lastLiquidityAddedEpochReference,
            uint256 lastEpochLiquidityWithdrawn
        );

    /**
        @dev This functions claims all available rewards for the user, it looks through all epoch's since when they last claimed rewards and calculates the sum of their rewards to claim

        @param _sendRewardsToStaking Whether the rewards are to be sent into a staking contract
        @param stakeDuration The duration of the stake to be created
     */
    function claimRewards(bool _sendRewardsToStaking, uint256 stakeDuration)
        external;

    /**
        @dev This function removes the specified amount from the user's total and sends their tokens back to the user. The user will be penalised 10% if withdrawing outside of the first day in any givene poch

        @param _amount The amount to withdraw
     */
    function removeLiquidity(uint256 _amount) external;
}

pragma solidity 0.8.10;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract EpochHelpers {
    using SafeMath for uint256;

    struct EpochInvestmentDetails {
        // Sum of all normalised epoch values
        uint256 shareTotal;
        // Sum of all liquidity amounts from the previous epochs
        uint256 allPrevInvestmentTotals;
        // Sum of all liquidity amounts, excluding amounts from the current epoch. This is so the share amounts aren't included twice.
        uint256 currentInvestmentTotal;
        // Boolean to hold whether liquidity was withdrawn in this epoch
        bool withdrewLiquidity;
    }

    uint256 internal epochStart;
    uint256 internal epochLength = 14 days;

    // For storing overall details
    mapping(uint256 => EpochInvestmentDetails) public epochAmounts;

    function _returnEpochAmountIncludingShare(
        EpochInvestmentDetails memory epochInvestmentDetails
    ) internal pure returns (uint256) {
        return
            epochInvestmentDetails.allPrevInvestmentTotals.add(
                epochInvestmentDetails.shareTotal
            );
    }

    function _returnEpochAmountIncludingCurrentTotal(
        EpochInvestmentDetails memory epochInvestmentDetails
    ) internal view returns (uint256) {
        return
            epochInvestmentDetails.allPrevInvestmentTotals.add(
                epochInvestmentDetails.currentInvestmentTotal
            );
    }

    function returnGivenEpochEndTime(uint256 epoch)
        public
        view
        returns (uint256)
    {
        return epochStart.add(epochLength.mul(epoch));
    }

    function returnGivenEpochStartTime(uint256 epoch)
        public
        view
        returns (uint256)
    {
        return epochStart.add(epochLength.mul(epoch.sub(1)));
    }

    function returnCurrentEpoch() public view returns (uint256) {
        return block.timestamp.sub(epochStart).div(epochLength).add(1);
    }

    function _returnEpochToTimestamp(uint256 timestamp)
        public
        view
        returns (uint256)
    {
        // ((timestamp - epochStart) / epochLength) + 1;
        // Add 1 to the end because it will round down the remainder value
        return timestamp.sub(epochStart).div(epochLength).add(1);
    }

    function _getSecondsToEpochEnd(uint256 currentEpoch)
        public
        view
        returns (uint256)
    {
        // Add to the epoch start date the duration of the current epoch + 1 * the epoch length.
        // Then subtract the block.timestamp to get the duration to the next epoch
        // epochStart + (currentEpoch * epochLength) - block.timestamp
        uint256 epochEndTime = epochStart.add(currentEpoch.mul(epochLength));
        // Prevent a math underflow by returning 0 if the given epoch is complete
        if (epochEndTime < block.timestamp) {
            return 0;
        } else {
            return epochEndTime.sub(block.timestamp);
        }
    }

    // The actual epoch rewards are 750 per week. But that shouldn't affect this
    // If claiming from an epoch that is in-progress you would get a proportion anyway
    function returnTotalRewardForEpoch(uint256 epoch)
        public
        pure
        returns (uint256)
    {
        // If the epoch is greater than or equal to 10 return 600 as the reward. This prevents a safemath underflow
        if (epoch >= 10) {
            return 600 ether;
        }
        // 1500 - (epoch * 100)
        uint256 rewardTotal = uint256(1500 ether).sub(
            uint256(100 ether).mul(epoch.sub(1))
        );

        return rewardTotal;
    }

    function returnIfInFirstDayOfEpoch(uint256 currentEpoch)
        public
        view
        returns (bool)
    {
        uint256 secondsToEpochEnd = _getSecondsToEpochEnd(currentEpoch);
        // The subtraction overflows the the currentEpoch value passed in isn't the current epoch and a future epoch
        uint256 secondsToEpochStart = epochLength.sub(secondsToEpochEnd);

        // If the seconds to epoch start is less than 1 day then true
        if (secondsToEpochStart <= 1 days) {
            return true;
        } else {
            return false;
        }
    }
}

pragma solidity 0.8.10;

import "./EpochHelpers.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract RewardHelpers is EpochHelpers {
    using SafeMath for uint256;

    uint256 public lastEpochUpdate = 1;

    // Function to calculate rewards over a year (26 epochs)
    function returnCurrentAPY() public view returns (uint256) {
        uint256 currentEpoch = returnCurrentEpoch();
        uint256 totalReward;
        // Checks if there is epochs that have rewards that aren't equal to 600
        if (currentEpoch < 10) {
            // The amount of epochs where the rewards aren't equal to 600
            uint256 epochLoops = uint256(10).sub(currentEpoch);
            // Iterate over each epoch to grab rewards for each of those epochs
            for (
                uint256 i = currentEpoch;
                i < epochLoops.add(currentEpoch);
                i++
            ) {
                uint256 epochReward = returnTotalRewardForEpoch(i);
                totalReward = totalReward.add(epochReward);
            }
            // Add in $600 rewards for every epoch where the rewards are equal to 600
            totalReward = totalReward.add(
                uint256(600 ether).mul(uint256(26).sub(epochLoops))
            );
        } else {
            // Every epoch has rewards equal to $600
            totalReward = uint256(600 ether).mul(26);
        }

        // The overall total for all users
        uint256 overallEpochTotal = _returnEpochAmountIncludingCurrentTotal(
            epochAmounts[lastEpochUpdate]
        );

        // If 0 for the epoch total, set it to 1
        if (overallEpochTotal == 0) {
            overallEpochTotal = 1 ether;
        }
        uint256 totalAPY = totalReward.mul(1 ether).div(overallEpochTotal);

        return totalAPY;
    }

    function _returnClaimSecondsForPulledLiquidity(
        uint256 lastClaimedTimestamp,
        uint256 currentEpoch
    ) public view returns (uint256) {
        uint256 lastClaimedEpoch = _returnEpochToTimestamp(
            lastClaimedTimestamp
        );

        uint256 claimSecondsForPulledLiquidity;

        if (lastClaimedEpoch == currentEpoch) {
            // If they've claimed in this epoch, they should only be able to claim from when they last claimed to now
            return
                claimSecondsForPulledLiquidity = block.timestamp.sub(
                    lastClaimedTimestamp
                );
        } else {
            // If they haven't claimed in this epoch, then the claim seconds are from when the epoch start to now
            uint256 secondsToEpochEnd = _getSecondsToEpochEnd(currentEpoch);

            return epochLength.sub(secondsToEpochEnd);
        }
    }

    // Returns the seconds that a user can claim rewards for in any given epoch
    function _returnEpochClaimSeconds(
        uint256 epoch,
        uint256 currentEpoch,
        uint256 lastEpochClaimed,
        uint256 lastClaimedTimestamp
    ) public view returns (uint256) {
        // If the given epoch is the current epoch
        if (epoch == currentEpoch) {
            // If the user claimed rewards in this epoch, the claim seconds would be the block.timestamp - lastClaimedtimestamp
            if (lastEpochClaimed == currentEpoch) {
                return block.timestamp.sub(lastClaimedTimestamp);
            }
            // If the user hasn't claimed in this epoch, the claim seconds is the timestamp - startOfEpoch
            uint256 givenEpochStartTime = returnGivenEpochStartTime(epoch);

            return block.timestamp.sub(givenEpochStartTime);
            // If the user last claimed in the given epoch, but it isn't the current epoch
        } else if (lastEpochClaimed == epoch) {
            // The claim seconds is the end of the given epoch - the lastClaimed timestmap
            uint256 givenEpochEndTime = returnGivenEpochEndTime(epoch);
            // If they've already claimed rewards in this epoch, calculate their claim seconds as the difference between that timestamp and now.

            return givenEpochEndTime.sub(lastClaimedTimestamp);
        }

        // Return full length of epoch if it isn't the current epoch and the user hasn't previously claimed in this epoch.
        return epochLength;
    }

    function _returnRewardAmount(
        uint256 usersInvestmentTotal,
        uint256 overallInvestmentTotal,
        uint256 secondsToClaim,
        uint256 totalReward
    ) public view returns (uint256) {
        // Calculate the total epoch reward share as: totalReward * usersInvestmentTotal / overallEpochTotal
        uint256 totalEpochRewardShare = totalReward
            .mul(usersInvestmentTotal)
            .div(overallInvestmentTotal);

        // Calculate the proportional reward share as totalEpochRewardShare * secondsToClaim / epochLength
        uint256 proportionalRewardShare = totalEpochRewardShare
            .mul(secondsToClaim)
            .div(epochLength);
        // totalReward * (usersInvestmentTotal / overallEpochTotal) * (secondsToClaim / epochLength)

        return proportionalRewardShare;
    }

    function _calculateRewardShareForEpoch(
        uint256 epoch,
        uint256 currentEpoch,
        uint256 lastEpochClaimed,
        uint256 lastClaimedTimestamp,
        uint256 usersInvestmentTotal,
        uint256 overallInvestmentTotal
    ) internal view returns (uint256) {
        // If the last claimed timestamp is the same epoch as the epoch passed in
        uint256 claimSeconds = _returnEpochClaimSeconds(
            epoch,
            currentEpoch,
            lastEpochClaimed,
            lastClaimedTimestamp
        );

        // Total rewards in the given epoch
        uint256 totalEpochRewards = returnTotalRewardForEpoch(epoch);

        return
            _returnRewardAmount(
                usersInvestmentTotal,
                overallInvestmentTotal,
                claimSeconds,
                totalEpochRewards
            );
    }
}

// SPDX-License-Identifier: MIT

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
     * by making the `nonReentrant` function external, and make it call a
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

// SPDX-License-Identifier: MIT

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