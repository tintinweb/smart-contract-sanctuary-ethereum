// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../_external/Ownable.sol";
import "./ICurveMaster.sol";
import "./ICurveSlave.sol";
import "../lending/IVaultController.sol";

/// @title Curve Master
/// @notice Curve master keeps a record of CurveSlave contracts and links it with an address
/// @dev all numbers should be scaled to 1e18. for instance, number 5e17 represents 50%
contract CurveMaster is ICurveMaster, Ownable {
  // mapping of token to address
  mapping(address => address) public _curves;

  address public _vaultControllerAddress;
  IVaultController private _VaultController;

  /// @notice gets the return value of curve labled token_address at x_value
  /// @param token_address the key to lookup the curve with in the mapping
  /// @param x_value the x value to pass to the slave
  /// @return y value of the curve
  function getValueAt(address token_address, int256 x_value) external view override returns (int256) {
    require(_curves[token_address] != address(0x0), "token not enabled");
    ICurveSlave curve = ICurveSlave(_curves[token_address]);
    int256 value = curve.valueAt(x_value);
    require(value != 0, "result must be nonzero");
    return value;
  }

  /// @notice set the VaultController addr in order to pay interest on curve setting
  /// @param vault_master_address address of vault master
  function setVaultController(address vault_master_address) external override onlyOwner {
    _vaultControllerAddress = vault_master_address;
    _VaultController = IVaultController(vault_master_address);
  }

  function vaultControllerAddress() external view override returns (address) {
    return _vaultControllerAddress;
  }

  ///@notice setting a new curve should pay interest
  function setCurve(address token_address, address curve_address) external override onlyOwner {
    if (address(_VaultController) != address(0)) {
      _VaultController.calculateInterest();
    }
    _curves[token_address] = curve_address;
  }

  /// @notice special function that does not calculate interest, used for deployment et al
  function forceSetCurve(address token_address, address curve_address) external override onlyOwner {
    _curves[token_address] = curve_address;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./Context.sol";

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
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
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
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is zero addr");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/// @title CurveMaster Interface
/// @notice Interface for interacting with CurveMaster
interface ICurveMaster {
  function vaultControllerAddress() external view returns (address);

  function getValueAt(address curve_address, int256 x_value) external view returns (int256);

  function setVaultController(address vault_master_address) external;

  function setCurve(address token_address, address curve_address) external;

  function forceSetCurve(address token_address, address curve_address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/// @title CurveSlave Interface
/// @notice Interface for interacting with CurveSlaves
interface ICurveSlave {
  function valueAt(int256 x_value) external view returns (int256);
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
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}