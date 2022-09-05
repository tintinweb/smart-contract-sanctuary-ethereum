// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.16;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";

import "./SafeTransferLib.sol";
import "./FixedPointMathLib.sol";
import "./IMigrator.sol";
import "./IUniswapV2Router02.sol";
import "./IQuoter.sol";
import "./ILp.sol";

contract UniswapV2GovLPVaultMigrator is IMigrator, ReentrancyGuard, Ownable {
  using SafeTransferLib for address;
  using FixedPointMathLib for uint256;
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  /* ========== CONSTANT ========== */
  address public constant WETH9 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

  /* ========== STATE VARIABLES ========== */
  IUniswapV2Router02 public router;
  IQuoter public quoter;

  mapping(address => bool) public tokenVaultOK;

  /* ========== EVENTS ========== */
  event WhitelistTokenVault(address tokenVault, bool whitelisted);
  event Execute(uint256 returnedETH, uint256 returnedBaseToken);

  /* ========== ERRORS ========== */
  error UniswapV2GovLPVaultMigrator_OnlyWhitelistedTokenVault();

  /* ========== CONSTRUCTOR ========== */
  constructor(IUniswapV2Router02 _router, IQuoter _quoter) {
    router = _router;
    quoter = _quoter;
  }

  /* ========== MODIFIERS ========== */

  modifier onlyWhitelistedTokenVault(address caller) {
    if (!tokenVaultOK[caller]) {
      revert UniswapV2GovLPVaultMigrator_OnlyWhitelistedTokenVault();
    }
    _;
  }

  /* ========== ADMIN FUNCTIONS ========== */
  function whitelistTokenVault(address _tokenVault, bool _isOk) external onlyOwner {
    tokenVaultOK[_tokenVault] = _isOk;

    emit WhitelistTokenVault(_tokenVault, _isOk);
  }

  /* ========== EXTERNAL FUNCTIONS ========== */
  function execute(bytes calldata _data) external onlyWhitelistedTokenVault(msg.sender) nonReentrant {
    address lpToken = abi.decode(_data, (address));
    address baseToken = address(ILp(lpToken).token0()) != address(WETH9)
      ? address(ILp(lpToken).token0())
      : address(ILp(lpToken).token1());

    uint256 liquidity = IERC20(lpToken).balanceOf(address(this));
    IERC20(lpToken).safeApprove(address(router), liquidity);
    router.removeLiquidityETH(baseToken, liquidity, 0, 0, address(this), block.timestamp);
    uint256 returnedETH = address(this).balance;
    uint256 returnedBaseToken = IERC20(baseToken).balanceOf(address(this));

    msg.sender.safeTransferETH(returnedETH);
    IERC20(baseToken).safeTransfer(msg.sender, returnedBaseToken);

    emit Execute(returnedETH, returnedBaseToken);
  }

  function getAmountOut(bytes calldata _data) public returns (uint256) {
    (address lpToken, uint256 stakeAmount) = abi.decode(_data, (address, uint256));
    address baseToken = address(ILp(lpToken).token0()) != address(WETH9)
      ? address(ILp(lpToken).token0())
      : address(ILp(lpToken).token1());

    (uint112 reserve0, uint112 reserve1, ) = ILp(lpToken).getReserves();
    (uint112 baseTokenReserve, uint112 ethReserve) = address(ILp(lpToken).token0()) != address(WETH9)
      ? (reserve0, reserve1)
      : (reserve1, reserve0);

    uint256 ratio = stakeAmount.divWadDown(ILp(lpToken).totalSupply());
    uint256 baseTokenLiquidity = uint256(baseTokenReserve).mulWadDown(ratio);
    uint256 ethLiquidity = uint256(ethReserve).mulWadDown(ratio);

    uint256 amountOut = quoter.quoteExactInputSingle(baseToken, WETH9, 0, baseTokenLiquidity, 0);

    uint256 totalEth = amountOut.add(ethLiquidity);
    return totalEth;
  }

  function getApproximatedExecutionRewards(bytes calldata) external returns (uint256) {
    // no execution reward from this pool
    return 0;
  }

  /// @dev Fallback function to accept ETH.
  receive() external payable {}
}