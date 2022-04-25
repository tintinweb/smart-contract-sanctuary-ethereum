// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/ILoanProvider.sol";
import "../interfaces/IPool.sol";
import "../interfaces/IAaveProtocolDataProvider.sol";
import "../interfaces/ICErc20.sol";
import "../interfaces/ICEth.sol";

contract Compound is ILoanProvider, Ownable {
  address public constant NATIVE_ASSET =
    0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  address public teleporter;

  // ERC20 asset => to ctoken map
  mapping(address => address) public cTokenMap;

  constructor(address _teleporter) {
    teleporter = _teleporter;
  }

  function setTeleporter(address _teleporter) external onlyOwner {
    teleporter = _teleporter;
  }

  function addCTokenMapping(address _token, address _ctoken) external onlyOwner {
    cTokenMap[_token] = _ctoken;
  }

  /**
   * @dev Deposit native/ERC20_Token.
   * @param _asset token address to deposit.
   * @param _amount token amount to deposit.
   */
  function depositOnBehalf(
    address _asset,
    uint256 _amount,
    address _onBehalfOf
  ) public override {
    address ctokenAddr = cTokenMap[_asset];
    require(ctokenAddr != address(0), "No mapping!");
    if (_asset == NATIVE_ASSET) {
      ICEth ctoken = ICEth(ctokenAddr);
      ctoken.mint{value: _amount}();
      uint256 cbal = ctoken.balanceOf(address(this));
      ctoken.transfer(_onBehalfOf, cbal);
    } else {
      IERC20(_asset).approve(ctokenAddr, _amount);
      ICErc20 ctoken = ICErc20(ctokenAddr);
      ctoken.mint(_amount);
      uint256 cbal = ctoken.balanceOf(address(this));
      ctoken.transfer(_onBehalfOf, cbal);
    }
  }

  /**
   * @notice Withdraw native/ERC20_Token.
   * @param _asset token address to withdraw.
   * @param _amount token amount to withdraw.
   * @dev requires prior ERC20 'approve' of cToken.
   * This function works around by transfering the control of the collateral receipt
   * to this contract.
   */
  function withdrawOnBehalf(
    address _asset,
    uint256 _amount,
    address _onBehalfOf
  ) public override {
    IGenCToken cToken = IGenCToken(cTokenMap[_asset]);
    require(address(cToken) != address(0), "No mapping!");
    cToken.transferFrom(_onBehalfOf, address(this), _amount);
    cToken.redeemUnderlying(_amount);
    if (_asset == NATIVE_ASSET) {
      teleporter.call{value: address(this).balance}("");
    } else {
      IERC20(_asset).transfer(teleporter, _amount);
    }
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
    //TODO
  }

  /**
   * @dev Payback borrowed ETH/ERC20_Token.
   * @param _asset token address to payback.
   * @param _amount token amount to payback.
   * @dev requires prior ERC20 'approve'.
   */
  function paybackOnBehalf(
    address _asset,
    uint256 _amount,
    address _onBehalfOf
  ) public override {
    address ctokenAddr = cTokenMap[_asset];

    // Check that ctoken address is set-up in mapping.
    require(ctokenAddr != address(0), "No mapping!");

    if (_asset == NATIVE_ASSET) {
      ICEth ctoken = ICEth(ctokenAddr);
      ctoken.repayBorrowBehalf{value: _amount}(_onBehalfOf);    
    } else {
      IERC20(_asset).approve(ctokenAddr, _amount);
      ICErc20 ctoken = ICErc20(ctokenAddr);
      ctoken.repayBorrowBehalf(_onBehalfOf, _amount);  
    }
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
  ) external view override returns (uint256 collateral, uint256 debt) {
    address ctokenCollateralAddr = cTokenMap[_collateralAsset];
    address ctokenDebtAddr = cTokenMap[_debtAssset];
    require(
      ctokenCollateralAddr != address(0) && ctokenDebtAddr != address(0),
      "No mapping!"
    );
    uint256 cTokenCollateralBal = IGenCToken(ctokenCollateralAddr).balanceOf(
      user
    );
    uint256 exRate = IGenCToken(ctokenCollateralAddr).exchangeRateStored();
    collateral = (exRate * cTokenCollateralBal) / 1e18;
    debt = IGenCToken(ctokenDebtAddr).borrowBalanceStored(user);
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

interface IPool {
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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IGenCToken.sol";

interface ICErc20 is IGenCToken {
  function mint(uint256) external returns (uint256);

  function repayBorrow(uint256 repayAmount) external returns (uint256);

  function repayBorrowBehalf(address borrower, uint256 repayAmount) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IGenCToken.sol";

interface ICEth is IGenCToken {
  function mint() external payable;

  function repayBorrow() external payable;

  function repayBorrowBehalf(address borrower) external payable;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IGenCToken is IERC20 {
  function redeem(uint256) external returns (uint256);

  function redeemUnderlying(uint256) external returns (uint256);

  function borrow(uint256 borrowAmount) external returns (uint256);

  function exchangeRateCurrent() external returns (uint256);

  function exchangeRateStored() external view returns (uint256);

  function borrowRatePerBlock() external view returns (uint256);

  function supplyRatePerBlock() external view returns (uint256);

  function balanceOfUnderlying(address owner) external returns (uint256);

  function borrowBalanceCurrent(address account) external returns (uint256);

  function borrowBalanceStored(address account) external view returns (uint256);
}