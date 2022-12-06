// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IFeeClaimer} from '../interfaces/IFeeClaimer.sol';
import {IERC20} from '../interfaces/IERC20.sol';

/**
 * @title AaveParaswapFeeClaimer
 * @author BGD Labs
 * @dev Helper contract that allows claiming paraswap partner fee to the collector on the respective network.
 */
contract AaveParaswapFeeClaimer {
  address public aaveCollector;
  IFeeClaimer public paraswapFeeClaimer;

  /**
   * @dev initializes the collector so that the respective treasury receives the rewards
   */
  function initialize(address _aaveCollector, IFeeClaimer _paraswapFeeClaimer)
    public
  {
    require(
      address(_paraswapFeeClaimer) != address(0),
      'PARASWAP_FEE_CLAIMER_REQUIRED'
    );
    require(_aaveCollector != address(0), 'COLLECTOR_REQUIRED');
    require(aaveCollector == address(0), 'ALREADY_INITIALIZED');
    aaveCollector = _aaveCollector;
    paraswapFeeClaimer = _paraswapFeeClaimer;
  }

  /**
   * @dev returns claimable balance for a specified asset
   * @param asset The asset to fetch claimable balance of
   */
  function getClaimable(address asset) public view returns (uint256) {
    return paraswapFeeClaimer.getBalance(IERC20(asset), address(this));
  }

  /**
   * @dev returns claimable balances for specified assets
   * @param assets The assets to fetch claimable balances of
   */
  function batchGetClaimable(address[] memory assets)
    public
    view
    returns (uint256[] memory)
  {
    return paraswapFeeClaimer.batchGetBalance(assets, address(this));
  }

  /**
   * @dev withdraws a single asset to the collector
   * @notice will revert when there's nothing to claim
   * @param asset The asset to claim rewards of
   */
  function claimToCollector(IERC20 asset) external {
    paraswapFeeClaimer.withdrawAllERC20(asset, aaveCollector);
  }

  /**
   * @dev withdraws all asset to the collector
   * @notice will revert when there's nothing to claim on a single supplied asset
   * @param assets The assets to claim rewards of
   */
  function batchClaimToCollector(address[] memory assets) external {
    paraswapFeeClaimer.batchWithdrawAllERC20(assets, aaveCollector);
  }
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
  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

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

// SPDX-License-Identifier: ISC
pragma solidity ^0.8.0;

import {IERC20} from './IERC20.sol';

interface IFeeClaimer {
  /**
   * @notice register partner's, affiliate's and PP's fee
   * @dev only callable by AugustusSwapper contract
   * @param _account account address used to withdraw fees
   * @param _token token address
   * @param _fee fee amount in token
   */
  function registerFee(
    address _account,
    IERC20 _token,
    uint256 _fee
  ) external;

  /**
   * @notice claim partner share fee in ERC20 token
   * @dev transfers ERC20 token balance to the caller's account
   *      the call will fail if withdrawer have zero balance in the contract
   * @param _token address of the ERC20 token
   * @param _recipient address
   * @return true if the withdraw was successfull
   */
  function withdrawAllERC20(IERC20 _token, address _recipient)
    external
    returns (bool);

  /**
   * @notice batch claim whole balance of fee share amount
   * @dev transfers ERC20 token balance to the caller's account
   *      the call will fail if withdrawer have zero balance in the contract
   * @param _tokens list of addresses of the ERC20 token
   * @param _recipient address of recipient
   * @return true if the withdraw was successfull
   */
  function batchWithdrawAllERC20(address[] calldata _tokens, address _recipient)
    external
    returns (bool);

  /**
   * @notice claim some partner share fee in ERC20 token
   * @dev transfers ERC20 token amount to the caller's account
   *      the call will fail if withdrawer have zero balance in the contract
   * @param _token address of the ERC20 token
   * @param _recipient address
   * @return true if the withdraw was successfull
   */
  function withdrawSomeERC20(
    IERC20 _token,
    uint256 _tokenAmount,
    address _recipient
  ) external returns (bool);

  /**
   * @notice batch claim some amount of fee share in ERC20 token
   * @dev transfers ERC20 token balance to the caller's account
   *      the call will fail if withdrawer have zero balance in the contract
   * @param _tokens address of the ERC20 tokens
   * @param _tokenAmounts array of amounts
   * @param _recipient destination account addresses
   * @return true if the withdraw was successfull
   */
  function batchWithdrawSomeERC20(
    IERC20[] calldata _tokens,
    uint256[] calldata _tokenAmounts,
    address _recipient
  ) external returns (bool);

  /**
   * @notice compute unallocated fee in token
   * @param _token address of the ERC20 token
   * @return amount of unallocated token in fees
   */
  function getUnallocatedFees(IERC20 _token) external view returns (uint256);

  /**
   * @notice returns unclaimed fee amount given the token
   * @dev retrieves the balance of ERC20 token fee amount for a partner
   * @param _token address of the ERC20 token
   * @param _partner account address of the partner
   * @return amount of balance
   */
  function getBalance(IERC20 _token, address _partner)
    external
    view
    returns (uint256);

  /**
   * @notice returns unclaimed fee amount given the token in batch
   * @dev retrieves the balance of ERC20 token fee amount for a partner in batch
   * @param _tokens list of ERC20 token addresses
   * @param _partner account address of the partner
   * @return _fees array of the token amount
   */
  function batchGetBalance(address[] calldata _tokens, address _partner)
    external
    view
    returns (uint256[] memory _fees);
}