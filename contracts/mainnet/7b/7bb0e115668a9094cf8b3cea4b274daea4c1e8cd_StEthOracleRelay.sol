// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../IOracleRelay.sol";
import "./IStEthPriceFeed.sol";
import "../../lending/IVaultController.sol";
import "../IOracleMaster.sol";

/// @title Oracle that wraps a chainlink oracle
/// @notice The oracle returns (chainlinkPrice) * mul / div
contract StEthOracleRelay is IOracleRelay {
  IStEthPriceFeed private immutable _priceFeed;
  IVaultController public constant VC = IVaultController(0x4aaE9823Fb4C70490F1d802fC697F3ffF8D5CbE3);

  IOracleMaster public _oracle;

  uint256 public immutable _multiply;
  uint256 public immutable _divide;

  /// @notice all values set at construction time
  /// @param  feed_address address of curve feed
  /// @param mul numerator of scalar
  /// @param div denominator of scalar
  constructor(
    address feed_address,
    uint256 mul,
    uint256 div
  ) {
    _priceFeed = IStEthPriceFeed(feed_address);
    _multiply = mul;
    _divide = div;
    _oracle = IOracleMaster(VC.getOracleMaster());
  }

  /// @notice the current reported value of the oracle
  /// @return the current value
  /// @dev implementation in getLastSecond
  function currentValue() external view override returns (uint256) {
    return getLastSecond();
  }

  ///@notice get the price in USD terms, after having converted from ETH terms
  function getLastSecond() private view returns (uint256) {

    (uint256 currentPrice, bool isSafe) = _priceFeed.current_price();
    require(isSafe, "Curve Oracle: Not Safe");

    uint256 ethPrice = _oracle.getLivePrice(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    currentPrice = (currentPrice * ethPrice) / 1e18;


    require(currentPrice > 0, "Curve: px < 0");
    uint256 scaled = (uint256(currentPrice) * _multiply) / _divide;
    return scaled;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/// @title OracleRelay Interface
/// @notice Interface for interacting with OracleRelay
interface IOracleRelay {
  // returns  price with 18 decimals
  function currentValue() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IStEthPriceFeed {
  function initialize(
    uint256 max_safe_price_difference,
    address stable_swap_oracle_address,
    address curve_pool_address,
    address admin
  ) external;

  function safe_price() external view returns (uint256, uint256);

  function current_price() external view returns (uint256, bool);

  function update_safe_price() external returns (uint256);

  function fetch_safe_price(uint256 max_age) external returns (uint256, uint256);

  function set_admin(address admin) external;

  function set_max_safe_price_difference(uint256 max_safe_price_difference) external;

  function admin() external view returns (address);

  function max_safe_price_difference() external view returns (uint256);

  function safe_price_value() external view returns (uint256);

  function safe_price_timestamp() external view returns (uint256);

  function curve_pool_address() external view returns (address);

  function stable_swap_oracle_address() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

// @title VaultController Events
/// @notice interface which contains any events which the VaultController contract emits
interface VaultControllerEvents {
  event InterestEvent(uint64 epoch, uint192 amount, uint256 curve_val);
  event NewProtocolFee(uint256 protocol_fee);
  event RegisteredErc20(address token_address, uint256 LTVe4, address oracle_address, uint256 liquidationIncentivee4);
  event UpdateRegisteredErc20(
    address token_address,
    uint256 LTVe4,
    address oracle_address,
    uint256 liquidationIncentivee4
  );
  event NewVault(address vault_address, uint256 vaultId, address vaultOwner);
  event RegisterOracleMaster(address oracleMasterAddress);
  event RegisterCurveMaster(address curveMasterAddress);
  event BorrowUSDi(uint256 vaultId, address vaultAddress, uint256 borrowAmount);
  event RepayUSDi(uint256 vaultId, address vaultAddress, uint256 repayAmount);
  event Liquidate(uint256 vaultId, address asset_address, uint256 usdi_to_repurchase, uint256 tokens_to_liquidate);
}

/// @title VaultController Interface
/// @notice extends VaultControllerEvents
interface IVaultController is VaultControllerEvents {
  // initializer
  function initialize() external;

  // view functions

  function tokensRegistered() external view returns (uint256);

  function vaultsMinted() external view returns (uint96);

  function lastInterestTime() external view returns (uint64);

  function totalBaseLiability() external view returns (uint192);

  function interestFactor() external view returns (uint192);

  function protocolFee() external view returns (uint192);

  function vaultAddress(uint96 id) external view returns (address);

  function vaultIDs(address wallet) external view returns (uint96[] memory);

  function amountToSolvency(uint96 id) external view returns (uint256);

  function vaultLiability(uint96 id) external view returns (uint192);

  function vaultBorrowingPower(uint96 id) external view returns (uint192);

  function tokensToLiquidate(uint96 id, address token) external view returns (uint256);

  function checkVault(uint96 id) external view returns (bool);

  struct VaultSummary {
    uint96 id;
    uint192 borrowingPower;
    uint192 vaultLiability;
    address[] tokenAddresses;
    uint256[] tokenBalances;
  }

  function vaultSummaries(uint96 start, uint96 stop) external view returns (VaultSummary[] memory);

  // interest calculations
  function calculateInterest() external returns (uint256);

  // vault management business
  function mintVault() external returns (address);

  function liquidateVault(
    uint96 id,
    address asset_address,
    uint256 tokenAmount
  ) external returns (uint256);

  function borrowUsdi(uint96 id, uint192 amount) external;

  function borrowUSDIto(
    uint96 id,
    uint192 amount,
    address target
  ) external;

  function borrowUSDCto(
    uint96 id,
    uint192 usdc_amount,
    address target
  ) external;

  function repayUSDi(uint96 id, uint192 amount) external;

  function repayAllUSDi(uint96 id) external;

  // admin
  function pause() external;

  function unpause() external;

  function getOracleMaster() external view returns (address);

  function registerOracleMaster(address master_oracle_address) external;

  function getCurveMaster() external view returns (address);

  function registerCurveMaster(address master_curve_address) external;

  function changeProtocolFee(uint192 new_protocol_fee) external;

  function registerErc20(
    address token_address,
    uint256 LTV,
    address oracle_address,
    uint256 liquidationIncentive
  ) external;

  function registerUSDi(address usdi_address) external;

  function updateRegisteredErc20(
    address token_address,
    uint256 LTV,
    address oracle_address,
    uint256 liquidationIncentive
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/// @title OracleMaster Interface
/// @notice Interface for interacting with OracleMaster
interface IOracleMaster {
  // calling function
  function getLivePrice(address token_address) external view returns (uint256);
  // admin functions
  function setRelay(address token_address, address relay_address) external;
}