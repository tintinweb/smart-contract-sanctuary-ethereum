// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "./interfaces/IRestrictedIndexPool.sol";
import "./interfaces/IWETH.sol";
import "./lib/SafeMath.sol";
import "./lib/TransferHelper.sol";

contract UniBurn {
  using SafeMath for uint256;
  using TransferHelper for address;

  IERC20 public constant defi5LP =
    IERC20(0x8dCBa0B75c1038c4BaBBdc0Ff3bD9a8f6979Dd13);
  IERC20 public constant cc10LP =
    IERC20(0x2701eA55b8B4f0FE46C15a0F560e9cf0C430f833);
  IERC20 public constant fffLP =
    IERC20(0x9A60F0A46C1485D4BDA7750AdB0dB1b17Aa48A33);
  IWETH public constant weth =
    IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

  IRestrictedIndexPool public constant defi5 =
    IRestrictedIndexPool(0xfa6de2697D59E88Ed7Fc4dFE5A33daC43565ea41);
  IRestrictedIndexPool public constant cc10 =
    IRestrictedIndexPool(0x17aC188e09A7890a1844E5E65471fE8b0CcFadF3);
  IRestrictedIndexPool public constant fff =
    IRestrictedIndexPool(0xaBAfA52D3d5A2c18A4C1Ae24480D22B831fC0413);

  struct PoolData {
    uint96 supply;
    uint72 ethBalance;
    uint88 poolBalance;
  }

  PoolData public fffData =
    PoolData(
      uint96(133274619446277226138),
      uint72(11392283886319598494),
      uint88(1664883434767400933503)
    );

  PoolData public defi5Data =
    PoolData(
      uint96(205228556349547851201),
      uint72(5759526907677680378),
      uint88(8924373539359521982012)
    );

  PoolData public cc10Data =
    PoolData(
      uint96(993232546416253583380),
      uint72(25711183462534811),
      uint88(74090838958998997067316924)
    );

  function _redeem(
    IRestrictedIndexPool pool,
    IERC20 pair,
    PoolData storage info
  ) internal {
    uint256 lpBalance = pair.balanceOf(msg.sender);
    require(lpBalance > 0, "ERR_NULL_AMOUNT");
    address(pair).safeTransferFrom(msg.sender, address(0), lpBalance);

    uint256 supply = uint256(info.supply);
    uint256 ethBalance = uint256(info.ethBalance);
    uint256 poolBalance = uint256(info.poolBalance);

    uint256 ethValue = ethBalance.mul(lpBalance) / supply;
    uint256 poolValue = poolBalance.mul(lpBalance) / supply;

    // We don't need to do a safe cast because safemath prevents
    // overflow and the original values are within size range
    info.ethBalance = uint72(ethBalance.sub(ethValue));
    info.poolBalance = uint88(poolBalance.sub(poolValue));
    info.supply = uint96(supply.sub(lpBalance));

    pool.exitPoolTo(msg.sender, poolValue);
    address(msg.sender).safeTransferETH(ethValue);
  }

  receive() external payable {}

  function burnWETH() external {
    weth.withdraw(weth.balanceOf(address(this)));
  }

  function redeemFFFLP() external {
    _redeem(fff, fffLP, fffData);
  }

  function redeemDEFI5LP() external {
    _redeem(defi5, defi5LP, defi5Data);
  }

  function redeemCC10LP() external {
    _redeem(cc10, cc10LP, cc10Data);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";

interface IRestrictedIndexPool is IERC20 {
  event LOG_EXIT(
    address indexed caller,
    address indexed tokenOut,
    uint256 tokenAmountOut
  );

  struct Record {
    bool bound;
    bool ready;
    uint40 lastDenormUpdate;
    uint96 denorm;
    uint96 desiredDenorm;
    uint8 index;
    uint256 balance;
  }

  function initialize(address _lpBurn, address _pair) external;

  function exitPool(uint256 poolAmountIn, uint256[] calldata minAmountsOut)
    external;

  function exitPoolTo(address to, uint256 poolAmountIn) external;

  function redeemAll() external;

  function isPublicSwap() external view returns (bool);

  function getSwapFee()
    external
    view
    returns (
      uint256 /* swapFee */
    );

  function getExitFee()
    external
    view
    returns (
      uint256 /* exitFee */
    );

  function getController() external view returns (address);

  function getExitFeeRecipient() external view returns (address);

  function isBound(address t) external view returns (bool);

  function getNumTokens() external view returns (uint256);

  function getCurrentTokens() external view returns (address[] memory tokens);

  function getCurrentDesiredTokens()
    external
    view
    returns (address[] memory tokens);

  function getDenormalizedWeight(address token)
    external
    view
    returns (
      uint256 /* denorm */
    );

  function getTokenRecord(address token)
    external
    view
    returns (Record memory record);

  function getTotalDenormalizedWeight() external view returns (uint256);

  function getBalance(address token) external view returns (uint256);

  function getUsedBalance(address token) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "./IERC20.sol";

interface IWETH is IERC20 {
  function deposit() external payable;

  function withdraw(uint256) external;
}

pragma solidity >=0.6.0;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
  function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require((z = x + y) >= x, "ds-math-add-overflow");
  }

  function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require((z = x - y) <= x, "ds-math-sub-underflow");
  }

  function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

/************************************************************************************************
Originally from https://github.com/Uniswap/uniswap-lib/blob/master/contracts/libraries/TransferHelper.sol

This source code has been modified from the original, which was copied from the github repository
at commit hash cfedb1f55864dcf8cc0831fdd8ec18eb045b7fd1.

Subject to the MIT license
*************************************************************************************************/

library TransferHelper {
  function safeApproveMax(address token, address to) internal {
    safeApprove(token, to, type(uint256).max);
  }

  function safeUnapprove(address token, address to) internal {
    safeApprove(token, to, 0);
  }

  function safeApprove(
    address token,
    address to,
    uint256 value
  ) internal {
    // bytes4(keccak256(bytes("approve(address,uint256)")));
    (bool success, bytes memory data) =
      token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "TH:SA");
  }

  function safeTransfer(
    address token,
    address to,
    uint256 value
  ) internal {
    // bytes4(keccak256(bytes("transfer(address,uint256)")));
    (bool success, bytes memory data) =
      token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "TH:ST");
  }

  function safeTransferFrom(
    address token,
    address from,
    address to,
    uint256 value
  ) internal {
    // bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));
    (bool success, bytes memory data) =
      token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
    require(
      success && (data.length == 0 || abi.decode(data, (bool))),
      "TH:STF"
    );
  }

  function safeTransferETH(address to, uint256 value) internal {
    (bool success, ) = to.call{ value: value }("");
    require(success, "TH:STE");
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface IERC20 {
  event Approval(address indexed src, address indexed dst, uint256 amt);
  event Transfer(address indexed src, address indexed dst, uint256 amt);

  function symbol() external view returns (string memory);

  function name() external view returns (string memory);

  function decimals() external view returns (uint8);

  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);
}