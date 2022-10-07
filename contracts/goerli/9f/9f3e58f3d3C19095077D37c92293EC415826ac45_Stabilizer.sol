// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7;

import "../Sweep/ISweep.sol";
import "../Common/ERC20/IERC20Metadata.sol";
import "../Sweep/ISweepAMOMinter.sol";
import "../AMOs/IAMM.sol";
import "../Common/Owned.sol";

contract Stabilizer is Owned {
  uint public protocol_spread;
  uint public junior_percentage;
  uint public junior_limit;
  uint public junior_deposit;
  uint public junior_withdraw;
  uint public junior_tranche;
  uint public junior_profits;
  uint public sweep_borrowed;
  uint public current_asset_value;
  uint public ratio;

  bool public open = true;

  address public banker;
  address public asset;
  address public treasury;

  ISweep public SWEEP;
  IERC20Metadata public USD;
  ISweepAMOMinter public minter;
  IAMM public amm;

  uint public missing_decimals;
  uint private constant PRECISION = 1e6;

  uint public constant SECONDS_PER_DAY = 60 * 60 * 24;
  uint public timelock;
  uint public timelock_days;

  constructor(
    address _creator_address,
    address _banker,
    address _sweep_address,
    address _usdc_address,
    address _minter_address,
    address _amm_address,
    address _asset_address,
    address _treasury_address,
    uint    _timelock_days,
    uint    _junior_percentage,
    uint    _junior_limit,
    uint    _protocol_spread
  ) Owned(_creator_address) {
    banker = _banker;

    SWEEP = ISweep(_sweep_address);
    USD = IERC20Metadata(_usdc_address);

    minter = ISweepAMOMinter(_minter_address);
    amm = IAMM(_amm_address);
    treasury = _treasury_address;
    asset = _asset_address;

    timelock_days = _timelock_days * SECONDS_PER_DAY;
    missing_decimals = SWEEP.decimals() - USD.decimals();

    junior_limit = _junior_limit;
    junior_percentage = _junior_percentage;
    ratio = (100*PRECISION - junior_percentage) * PRECISION / junior_percentage;

    protocol_spread = _protocol_spread;
  }

  // MODIFIERS //

  modifier onlyBanker() {
    require(msg.sender == banker, "Only Banker");
    _;
  }

  modifier isOpen(){
    require(open, "stabilizer is closed");
    _;
  }

  // EXTERNAL ACTIONS //

  function deposit(uint256 amount) external onlyBanker isOpen {
    require(junior_deposit + amount <= junior_limit, "cannot exceed junior amount limit");
    junior_deposit += amount;
    USD.transferFrom(msg.sender, address(this), amount);
  }

  function rescue() external onlyBanker isOpen {
    uint amount = junior_deposit;
    junior_deposit = 0;
    USD.transfer(address(msg.sender), amount);
  }

  function invest() external onlyBanker isOpen {
    require(junior_deposit > 0, "there is nothing to invest in the junior deposits");
    uint sweep_price = SWEEP.amm_price();
    uint target_price = SWEEP.target_price();
    require(sweep_price > target_price, "Sweep Price should be bigger than the Target Price");

    timelock = block.timestamp + timelock_days;

    // Update senior/junior deposits //
    uint junior_investment = junior_deposit;
    uint senior_investment = getSeniorValue(junior_investment);
    junior_tranche += junior_investment;
    junior_deposit = 0;

    // Mint Sweep //
    uint max_sweep_in = (getSweepsFromUSD(senior_investment, sweep_price) * 11/10);

    minter.mintSweepForAMO(address(amm), max_sweep_in);

    // Swap Sweep for USD //
    uint used_sweep = amm.swapExactOutput(
      address(SWEEP),
      address(USD),
      3000,
      senior_investment,
      max_sweep_in
    );

    sweep_borrowed += used_sweep;
    uint sweep_balance = SWEEP.balanceOf(address(this));
    SWEEP.increaseAllowance(address(minter), sweep_balance);
    minter.burnSweepFromAMO(address(amm), sweep_balance);

    // Send the investment to the asset
    uint total_investment = senior_investment + junior_investment;
    USD.transfer(address(asset), total_investment);
  }

  function payback(uint amount) external {
    uint sweep_price = SWEEP.amm_price();
    uint target_price = SWEEP.target_price();
    require(sweep_price <= target_price, "Sweep Price should be less than the Target Price");

    // get the usd back
    USD.transferFrom(address(asset), address(this), amount);

    // send the protocol spread to the treasury
    uint treasury_amount = (amount * (protocol_spread/100)) / PRECISION;
    amount -= treasury_amount;
    USD.transfer(treasury, treasury_amount);

    // repay the senior tranche debt if necessary
    if(sweep_borrowed > 0) {
      // calculate the total sweep we can buy with the usd amount
      uint sweep_available = getSweepsFromUSD(amount, sweep_price);

      if(sweep_available > sweep_borrowed) {
        // if we can buy MORE sweep than required to cover the senior debt
        // swap exactly the amount required to pay the debt
        // burn the necessary sweep to pay the senior debt
        USD.transfer(address(amm), amount);
        uint swapped_usd = amm.swapExactOutput(address(USD), address(SWEEP), 3000, sweep_borrowed, amount);

        // calculates the usd amount after paying the debt
        amount -= swapped_usd;
        // cancels the senior tranche debt
        sweep_borrowed = 0;
        // set the stabilizer as closed for new deposits/investments
        open = false;
      } else {
        // if we can buy LESS sweep than required to cover the senior debt
        // swap the entire input usd amount
        uint usd_repayment = getUSDFromSweep(sweep_available, sweep_price);

        USD.transfer(address(amm), usd_repayment);
        uint swapped_sweep = amm.swapExactInput(address(USD), address(SWEEP), 3000, usd_repayment);
        // reduces the total borrowed sweep (senior tranche)
        sweep_borrowed -= swapped_sweep;

        // the usd amount after paying the debt is zero
        amount = 0;
      }

      amm.refreshTargetPrice(sweep_price);

      // burn all the exchanged sweeps
      uint sweep_balance = SWEEP.balanceOf(address(this));

      SWEEP.increaseAllowance(address(minter), sweep_balance);
      minter.burnSweepFromAMO(address(amm), sweep_balance);
    }

    // leaves the withdraw availability in a variable
    // only this amount can be taken by the banker (junior)
    // it only increases after the senior tranche debt has been paid out
    junior_withdraw += amount;
  }

  // allows the withdrawal of the junior_withdrawal
  // which only contains the waterfall amount after repayments
  function withdraw() external onlyBanker {
    require(block.timestamp > timelock, "you have to wait the for timelock before withdrawal");
    require(junior_withdraw > 0, "nothing to withdraw");

    uint amount = junior_withdraw;
    junior_profits += junior_withdraw;
    junior_withdraw = 0;
    USD.transfer(banker, amount);
  }


  // INTERNAL HELPERS //

  function getSeniorValue(uint junior) internal view returns(uint) {
    return ratio * junior / PRECISION;
  }

  function getSweepsFromUSD(uint amount, uint price) internal view returns(uint) {
    return (10 ** missing_decimals) * amount * PRECISION / price;
  }

  function getUSDFromSweep(uint amount, uint price) internal view returns(uint) {
    return amount * price / (PRECISION * (10 ** missing_decimals));
  }


  // GETTERS //

  // amount that can be invested
  function getInvestableValue() external view returns(uint) {
    return getSeniorValue(junior_deposit) + junior_deposit;
  }

  // amount that was already invested
  function getInvestedValue() external view returns(uint) {
    return getSeniorValue(junior_tranche) + junior_tranche;
  }

  // signed int return with the % below or above investment
  function getJuniorProfit() external view returns(int) {
    return int((junior_profits * 100 / junior_tranche) - (100 * (10**6)));
  }


  // SETTERS //

  function setCurrentAssetValue(uint _asset_value) external onlyBanker {
    current_asset_value = _asset_value;
  }

  function setProtocolSpread(uint _protocol_spread) external onlyOwner {
    protocol_spread = _protocol_spread;
  }

  function setTimelock(uint256 _timelock) external onlyOwner {
    timelock = _timelock;
  }

  function setTimelockDays(uint256 _timelock_days) external onlyOwner {
    timelock_days = _timelock_days * SECONDS_PER_DAY;
  }

  function reopen() external onlyOwner {
    open = true;
  }

  // complex => if we make this dynamic, one part of the investment can be
  // done with X ratio and other part can have Y ratio.
  // function setJuniorPercentage(uint _new_percentage_value) external onlyBanker {
  //   junior_percentage = _new_percentage_value;
  // }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.11;

// MAY need to be updated
interface ISweepAMOMinter {
  function SWEEP() external view returns(address);
  function acceptOwnership() external;
  function addAMO(address amo_address, bool sync_too) external;
  function allAMOAddresses() external view returns(address[] memory);
  function allAMOsLength() external view returns(uint256);
  function amos(address) external view returns(bool);
  function amos_array(uint256) external view returns(address);
  function burnSweepFromAMO(address amo, uint256 sweep_amount) external;
  function collatDollarBalance() external view returns(uint256);
  function collatDollarBalanceStored() external view returns(uint256);
  function collat_borrow_cap() external view returns(int256);
  function collat_borrowed_balances(address) external view returns(int256);
  function collat_borrowed_sum() external view returns(int256);
  function collateral_address() external view returns(address);
  function collateral_token() external view returns(address);
  function correction_offsets_amos(address, uint256) external view returns(int256);
  function custodian_address() external view returns(address);
  function dollarBalances() external view returns(uint256 sweep_val_e18, uint256 collat_val_e18);
  function refreshTargetPrice(uint _price) external;

  function sweepDollarBalanceStored() external view returns(uint256);
  function sweepTrackedAMO(address amo_address) external view returns(int256);
  function sweepTrackedGlobal() external view returns(int256);
  function sweep_mint_balances(address) external view returns(int256);
  function sweep_mint_cap() external view returns(int256);
  function sweep_mint_sum() external view returns(int256);
  function mintSweepForAMO(address destination_amo, uint256 sweep_amount) external;
  function missing_decimals() external view returns(uint256);
  function nominateNewOwner(address _owner) external;
  function nominatedOwner() external view returns(address);

  function owner() external view returns(address);
  function pool() external view returns(address);
  function recoverERC20(address tokenAddress, uint256 tokenAmount) external;
  function removeAMO(address amo_address, bool sync_too) external;
  function setAMOCorrectionOffsets(address amo_address, int256 sweep_e18_correction, int256 collat_e18_correction) external;
  function setCustodian(address _custodian_address) external;
  function setSweepMintCap(uint256 _sweep_mint_cap) external;
  function setSweepPool(address _pool_address) external;
  function setTimelock(address new_timelock) external;
  function syncDollarBalances() external;
  function timelock_address() external view returns(address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.11;
pragma experimental ABIEncoderV2;

interface IAMM {
    function swapExactInput(address _tokenA, address _tokenB, uint24 _fee_tier, uint256 _amountAtoB) external returns (uint256);
    function swapExactOutput(address _tokenA, address _tokenB, uint24 _fee_tier, uint256 amountOut, uint256 amountInMaximum) external returns(uint256);
    function refreshTargetPrice(uint _price) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.11;

interface ISweep {
  function DEFAULT_ADMIN_ADDRESS() external view returns (address);
  function DEFAULT_ADMIN_ROLE() external view returns (bytes32);
  function addAMOMinter(address minter_address ) external;
  function allowance(address owner, address spender ) external view returns (uint256);
  function approve(address spender, uint256 amount ) external returns (bool);
  function balanceOf(address account ) external view returns (uint256);
  function burn(uint256 amount ) external;
  function burnFrom(address account, uint256 amount ) external;
  function creator_address() external view returns (address);
  function decimals() external view returns (uint8);
  function decreaseAllowance(address spender, uint256 subtractedValue ) external returns (bool);
  function eth_usd_consumer_address() external view returns (address);
  function eth_usd_price() external view returns (uint256);
  function sweep_eth_oracle_address() external view returns (address);
  function sweep_info() external view returns (uint256, uint256, uint256, uint256, uint256);
  function amo_minter_addresses(address ) external view returns (bool);
  function amm_price() external view returns (uint256);
  function genesis_supply() external view returns (uint256);
  function getRoleAdmin(bytes32 role ) external view returns (bytes32);
  function getRoleMember(bytes32 role, uint256 index ) external view returns (address);
  function getRoleMemberCount(bytes32 role ) external view returns (uint256);
  function globalCollateralValue() external view returns (uint256);
  function mintPrice() external view returns (uint256);
  function redeemPrice() external view returns (uint256);
  function grantRole(bytes32 role, address account ) external;
  function hasRole(bytes32 role, address account ) external view returns (bool);
  function increaseAllowance(address spender, uint256 addedValue ) external returns (bool);
  function last_call_time() external view returns (uint256);
  function minting_fee() external view returns (uint256);
  function name() external view returns (string memory);
  function owner_address() external view returns (address);
  function minter_burn_from(address b_address, uint256 b_amount ) external;
  function minter_mint(address m_address, uint256 m_amount ) external;
  function price_band() external view returns (uint256);
  function target_price() external view returns (uint256);
  function redemption_fee() external view returns (uint256);
  function removeAMOMinter(address minter_address ) external;
  function renounceRole(bytes32 role, address account ) external;
  function refreshTargetPrice(uint _amm_price) external;
  function revokeRole(bytes32 role, address account ) external;
  function setPriceTarget(uint256 _new_price_target ) external;
  function setETHUSDOracle(address _eth_usd_consumer_address ) external;
  function setUniswapOracle(address _uniswap_oracle_address ) external;
  function setMintingFee(uint256 min_fee ) external;
  function setOwner(address _owner_address ) external;
  function setMintPrice(uint256 _new_mint_price ) external;
  function setRedeemPrice(uint256 _new_redeem_price ) external;
  function setRedemptionFee(uint256 red_fee ) external;
  function setTimelock(address new_timelock ) external;
  function symbol() external view returns (string memory);
  function timelock_address() external view returns (address);
  function toggleMint() external;
  function totalSupply() external view returns (uint256);
  function transfer(address recipient, uint256 amount ) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount ) external returns (bool);
  function weth_address() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.11;

// https://docs.synthetix.io/contracts/Owned
contract Owned {
    address public owner;
    address public nominatedOwner;

    constructor (address _owner) public {
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only the contract owner may perform this action");
        _;
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

import "../Context.sol";
import "../../Utils/Math/SafeMath.sol";

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
pragma solidity >=0.6.11;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}