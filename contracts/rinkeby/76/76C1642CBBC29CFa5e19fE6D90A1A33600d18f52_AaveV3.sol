// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/ILoanProvider.sol";
import "../interfaces/IAaveV3Pool.sol";
import "../interfaces/IAaveProtocolDataProvider.sol";

contract AaveV3 is ILoanProvider, Ownable {
  address public constant NATIVE_ASSET =
    0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
  
  IAaveV3Pool public aavePool;
  IAaveProtocolDataProvider public dataProvider;

  address public teleporter;

  // ERC20 asset => to atoken map
  mapping(address => address) public aTokenMap;

  // ERC20 asset => to debt token map
  mapping(address => address) public debtTokenMap;

  constructor(
    address _teleporter,
    address _aavePool,
    address _dataProvider
  ) {
    teleporter = _teleporter;
    aavePool = IAaveV3Pool(_aavePool);
    dataProvider = IAaveProtocolDataProvider(_dataProvider);
  }

  function setTeleporter(address _teleporter) external onlyOwner {
    teleporter = _teleporter;
  }

  function setAavePool(address _aavePool) external onlyOwner {
    aavePool = IAaveV3Pool(_aavePool);
  }

  function setDataProvider(address _dataProvider) external onlyOwner {
    dataProvider = IAaveProtocolDataProvider(_dataProvider);
  }

  function addATokenMapping(address _token, address _atoken) external onlyOwner {
    aTokenMap[_token] = _atoken;
  }

  function addDebtTokenMapping(address _token, address _debtToken) external onlyOwner {
    debtTokenMap[_token] = _debtToken;
  }

  /**
   * @dev Deposit ETH/ERC20_Token.
   * @param _asset token address to deposit.
   * @param _amount token amount to deposit.
   */
  function depositOnBehalf(
    address _asset,
    uint256 _amount,
    address _onBehalfOf
  ) public override {
    IERC20(_asset).approve(address(aavePool), _amount);
    aavePool.supply(_asset, _amount, _onBehalfOf, 0);
  }

  /**
   * @dev Withdraw ETH/ERC20_Token.
   * @param _asset token address to withdraw.
   * @param _amount token amount to withdraw.
   * @dev requires prior ERC20 'approve' of aTokens
   */
  function withdrawOnBehalf(
    address _asset,
    uint256 _amount,
    address _onBehalfOf
  ) public override {
    IERC20 aToken = IERC20(aTokenMap[_asset]);
    aToken.transferFrom(_onBehalfOf, address(this), _amount);
    aavePool.withdraw(_asset, _amount, teleporter);
  }

  /**
   * @dev Borrow ETH/ERC20_Token.
   * @param _asset token address to borrow.
   * @param _amount token amount to borrow.
   * @dev requires user premission
   */
  function borrowOnBehalf(
    address _asset,
    uint256 _amount,
    address _onBehalfOf
  ) public override {
    aavePool.borrow(_asset, _amount, 2, 0, _onBehalfOf);
    IERC20 token = IERC20(_asset);
    token.transfer(_onBehalfOf, _amount);
  }

  /**
   * @dev Payback borrowed ETH/ERC20_Token.
   * @param _asset token address to payback.
   * @param _amount token amount to payback.
   * @dev requires _amount ERC20 balance transferred to adddress(this).
   */
  function paybackOnBehalf(
    address _asset,
    uint256 _amount,
    address _onBehalfOf
  ) public override {
    IERC20(_asset).approve(address(aavePool), _amount);
    aavePool.repay(_asset, _amount, 2, _onBehalfOf);
  }

  /**
   * @dev Returns the collateral and debt balance.
   * @param _collateralAsset address
   * @param _debtAssset address
   * @param user address
   */
  function getPairBalances(
    address _collateralAsset,
    address _debtAssset,
    address user
  ) external override view returns (uint256 collateral, uint256 debt) {
    (collateral, , , , , , , , ) = dataProvider.getUserReserveData(
      _collateralAsset,
      user
    );
    (, , debt, , , , , , ) = dataProvider.getUserReserveData(_debtAssset, user);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ILoanProvider {
  function depositOnBehalf(
    address _asset,
    uint256 _amount,
    address _onBehalfOf
  ) external;

  function withdrawOnBehalf(
    address _asset,
    uint256 _amount,
    address _onBehalfOf
  ) external;

  function paybackOnBehalf(
    address _asset,
    uint256 _amount,
    address _onBehalfOf
  ) external;

  function borrowOnBehalf(
    address _asset,
    uint256 _amount,
    address _onBehalfOf
  ) external;

  function getPairBalances(
    address _collateralAsset,
    address _debtAssset,
    address user
  ) external view returns (uint256 collateral, uint256 debt);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAaveV3Pool {
  function supply(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external returns (uint256);

  function borrow(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    uint16 referralCode,
    address onBehalfOf
  ) external;

  function repay(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    address onBehalfOf
  ) external returns (uint256);

  function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAaveProtocolDataProvider {
function getUserReserveData(address asset, address user)
  external
  view
  returns (
    uint256 currentATokenBalance,
    uint256 currentStableDebt,
    uint256 currentVariableDebt,
    uint256 principalStableDebt,
    uint256 scaledVariableDebt,
    uint256 stableBorrowRate,
    uint256 liquidityRate,
    uint40 stableRateLastUpdated,
    bool usageAsCollateralEnabled
  );
}

// SPDX-License-Identifier: MIT
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