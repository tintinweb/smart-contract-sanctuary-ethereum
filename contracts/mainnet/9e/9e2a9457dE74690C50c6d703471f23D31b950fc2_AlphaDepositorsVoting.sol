pragma solidity 0.8.19;

import "ISafeBox.sol";
import "IERC20.sol";

contract AlphaDepositorsVoting {
  // safebox addresses
  ISafeBox public constant SAFEBOX_ETH =
    ISafeBox(0xeEa3311250FE4c3268F8E684f7C87A82fF183Ec1);
  ISafeBox public constant SAFEBOX_USDT =
    ISafeBox(0x020eDC614187F9937A1EfEeE007656C6356Fb13A);
  ISafeBox public constant SAFEBOX_USDC =
    ISafeBox(0x08bd64BFC832F1C2B3e07e634934453bA7Fa2db2);
  ISafeBox public constant SAFEBOX_DAI =
    ISafeBox(0xee8389d235E092b2945fE363e97CDBeD121A0439);

  uint256 public constant PRECISION = 1e18;

  address private constant VESPER = 0xeCe0f32840280aD0069Dd89Ad97Ad6dF1bB0fF2A; // vesper contract address
  address private constant VESPER_DELEGATE = 0x938CC8D098aDE035D88A0842EF408076594706D0; // address to delegate vote from vesper contract to

  struct SafeBoxInfo {
    ISafeBox safeBox;
    uint256 price;
  }

  SafeBoxInfo[4] public safeBoxInfos;

  constructor() {
    // prices as of Mar 9, 11.08AM UTC
    safeBoxInfos[0] = SafeBoxInfo(SAFEBOX_ETH, 1528.93e18);
    safeBoxInfos[1] = SafeBoxInfo(SAFEBOX_USDT, 1e18);
    safeBoxInfos[2] = SafeBoxInfo(SAFEBOX_USDC, 1e18);
    safeBoxInfos[3] = SafeBoxInfo(SAFEBOX_DAI, 1e18);
  }

  /// @dev this function calculates each user total voting power return with precision  = 1e18
  /// calculate by sum of how much user deposit in these 4 safeboxes (ETH, USDC, USDT, DAI) in $ value
  // NOTE: snapshot ETH price @1528.93 and USDC, USDT, DAI @1.
  function balanceOf(address _account) external view returns (uint256 balance) {
    // 1. for loop each safebox token address
    // 2. $value = safebox_balance * ctoken_exchange_rate_stored * price / 10 ** token_decimals
    // 3. sum all of $ value

    require(_account != VESPER, 'delegated');
    if (_account == VESPER_DELEGATE) {
        _account = VESPER;  // use the voting power of the delegator
    } 

    for (uint256 i; i < safeBoxInfos.length; ++i) {
      ICToken cToken = safeBoxInfos[i].safeBox.cToken();
      address underlying = cToken.underlying();
      uint256 underlyingDecimals = IERC20(underlying).decimals();

      balance +=
        (ISafeBox(safeBoxInfos[i].safeBox).balanceOf(_account) *
          cToken.exchangeRateStored() *
          safeBoxInfos[i].price) /
        PRECISION /
        10**underlyingDecimals;
    }
  }
}

pragma solidity 0.8.19;

import "ICToken.sol";

interface ISafeBox {
  function balanceOf(address) external view returns (uint256);

  function cToken() external view returns (ICToken);
}

pragma solidity 0.8.19;

interface ICToken {
  function underlying() external view returns (address);

  function exchangeRateStored() external view returns (uint256);
}

pragma solidity 0.8.19;

interface IERC20 {
  function decimals() external view returns (uint256);
}