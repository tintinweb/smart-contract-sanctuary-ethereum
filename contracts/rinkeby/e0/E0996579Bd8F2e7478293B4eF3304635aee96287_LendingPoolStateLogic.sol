// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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
pragma solidity 0.8.13;

import "./libraries/types.sol";

enum Tranche {
  JUNIOR,
  SENIOR
}

struct LoanRegistrationParams {
  uint256 repaymentDate;
  uint256 principal;
  uint256 lateFee;
  uint256 timeDisbursed;
  uint256 dailyRate;
  address borrowerAddress;
  string purpose;
  string description;
}

struct PoolUpdateParams {
  uint256[] updatedLoanIDs;
  Loan[] loansToUpdate;
  uint256 totalLoanValue;
  uint256 numLoansUpdated;
  uint256 updatedSeniorObligation;
  bool isLastUpdate;
}

enum LoanStatus {
  REGISTERED,
  ACTIVE,
  DISBURSED,
  CLOSED,
  DEFAULTED,
  FAILED_TO_DISBURSE
}

struct Loan {
  uint256 globalLoanID;
  uint256 repaymentDate;
  uint256 principal;
  uint256 amountRepaid;
  uint256 lateFee;
  uint256 disbursementDate;
  uint256 actualTimeDisbursed;
  uint256 dailyRate;
  address borrower;
  LoanBalances balances;
  LoanStatus status;
}

interface ILendingPool {
  function init(address _jCopToken, address _sCopToken) external;

  function registerLoan(LoanRegistrationParams calldata _loanParams) external;

  function payLoan(uint256 _loanID, uint256 _amount) external;

  function disburseLoan(uint256 _loanID) external;

  function deposit(Tranche _tranche, uint256 _amount) external;

  function withdraw(Tranche _tranche, uint256 _amount) external;

  function update(PoolUpdateParams memory _updateParams) external;

  function activateLoan(uint256 _loanID) external;

  function getPoolUpdateParams(uint256 _numLoans) external view returns (PoolUpdateParams memory);

  function getData()
    external
    view
    returns (
      LendingPoolStateData memory,
      LendingPoolConstraints memory,
      address
    );

  function getLoan(uint256 _loanID) external view returns (Loan memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {LendingPoolStateData, LendingPoolConstraints} from "./types.sol";
import {Tranche} from "../ILendingPool.sol";
import {DSMath} from "../../library/DSMath.sol";
import {IToken} from "../../tokens/IToken.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

library LendingPoolStateLogic {
  using DSMath for uint256;

  function activate(LendingPoolStateData storage _self) public {
    if (!_self.isPoolActive) {
      _self.isPoolActive = true;
    }
  }

  function getReservePercentage(LendingPoolStateData memory _self) public view returns (uint256) {
    uint256 totalValue = _getTotalValue(_self);
    require(_self.baseTokenAddress != address(0), "base token address is missing");
    address lpAddress = address(this);
    uint256 reserves = (ERC20(_self.baseTokenAddress)).balanceOf(lpAddress);
    return reserves.wdiv(totalValue);
  }

  function getExchangeRate(LendingPoolStateData memory _self, Tranche _tranche) public pure returns (uint256) {
    return _tranche == Tranche.JUNIOR ? _self.jCopTokenPrice : _self.sCopTokenPrice;
  }

  function validateAfterDisbursement(
    LendingPoolStateData memory _self,
    LendingPoolConstraints memory _constraints,
    uint256 _amountDisbursed
  ) public view {
    _self.totalLoanValue += _amountDisbursed;
    uint256 reservePercentage = getReservePercentage(_self);
    satisfiesMinReserve(_constraints, reservePercentage);
    satisfiesMaxPoolSize(_constraints, _self.totalLoanValue);
  }

  function validateAfterDeposit(LendingPoolStateData memory _self, LendingPoolConstraints memory _constraints)
    public
    view
  {
    uint256 reservePercentage = getReservePercentage(_self);
    satisfiesMaxReserve(_constraints, _self, reservePercentage);
    satisfiesMinUnderwritten(_self, _constraints);
  }

  function satisfiesMinUnderwritten(LendingPoolStateData memory _self, LendingPoolConstraints memory _constraints)
    public
    view
  {
    uint256 poolValue = _getTotalValue(_self);
    require(_self.juniorValue.wdiv(poolValue) >= _constraints.minUnderwritten, "insufficient junior tranche value");
  }

  function satisfiesMaxPoolSize(LendingPoolConstraints memory _constraints, uint256 _poolValue) public pure {
    require(_poolValue < _constraints.maxPoolSize, "pool size too large");
  }

  function satisfiesMinReserve(LendingPoolConstraints memory _constraints, uint256 _lpReservePercentage) public pure {
    require(_lpReservePercentage >= _constraints.minReservePercentage, "cannot be below pool minReserve");
  }

  function satisfiesMaxReserve(
    LendingPoolConstraints memory _constraints,
    LendingPoolStateData memory _selfData,
    uint256 _reservePercentage
  ) public view {
    if (_selfData.isPoolActive) {
      require(_reservePercentage <= _constraints.maxReservePercentage, "cannot be above maxReserve");
    } else {
      require(
        _getTotalValue(_selfData) < _constraints.maxReservePercentage.wmul(_constraints.maxPoolSize),
        "cannot be above maxReserve"
      );
    }
  }

  function _getTotalValue(LendingPoolStateData memory _self) internal view returns (uint256) {
    uint256 poolLoanValue = _self.totalLoanValue;
    uint256 poolReserve = _getPoolReserves(_self);
    return poolLoanValue.add(poolReserve);
  }

  function _getPoolReserves(LendingPoolStateData memory _self) internal view returns (uint256) {
    ERC20 baseToken = ERC20(_self.baseTokenAddress);
    return (baseToken.balanceOf(address(this)));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

struct LendingPoolConstraints {
  uint256 minReservePercentage;
  uint256 maxReservePercentage;
  uint256 minUnderwritten;
  uint256 maxPoolSize;
}

struct LendingPoolStateData {
  uint256 dailySeniorYield;
  uint256 seniorObligation;
  uint256 juniorValue;
  uint256 seniorValue;
  uint256 sCopTokenPrice;
  uint256 jCopTokenPrice;
  uint256 lastUpdatedAt;
  uint256 totalLoanValue;
  uint256 lastUpdatedLoanIdx;
  bool isPoolActive;
  bool isUpdating;
  address baseTokenAddress;
  address jCopTokenAddress;
  address sCopTokenAddress;
}

struct LoanBalances {
  uint256 outstanding;
  uint256 fee;
  uint256 late;
  uint256 balance;
  uint256 netValue;
}

// SPDX-License-Identifier: MIT
pragma solidity >0.4.13;

library DSMath {
  function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require((z = x + y) >= x, "ds-math-add-overflow");
  }

  function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require((z = x - y) <= x, "ds-math-sub-underflow");
  }

  function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
  }

  function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
    return x <= y ? x : y;
  }

  function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
    return x >= y ? x : y;
  }

  function imin(int256 x, int256 y) internal pure returns (int256 z) {
    return x <= y ? x : y;
  }

  function imax(int256 x, int256 y) internal pure returns (int256 z) {
    return x >= y ? x : y;
  }

  uint256 constant WAD = 10**18;
  uint256 constant RAY = 10**27;

  function toWAD(uint256 a) internal pure returns (uint256 b) {
    b = a * WAD;
  }

  //rounds to zero if x*y < WAD / 2
  function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    z = add(mul(x, y), WAD / 2) / WAD;
  }

  //rounds to zero if x*y < WAD / 2
  function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    z = add(mul(x, y), RAY / 2) / RAY;
  }

  //rounds to zero if x*y < WAD / 2
  function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
    z = add(mul(x, WAD), y / 2) / y;
  }

  //rounds to zero if x*y < RAY / 2
  function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
    z = add(mul(x, RAY), y / 2) / y;
  }

  // This famous algorithm is called "exponentiation by squaring"
  // and calculates x^n with x as fixed-point and n as regular unsigned.
  //
  // It's O(log n), instead of O(n) for naive repeated multiplication.
  //
  // These facts are why it works:
  //
  //  If n is even, then x^n = (x^2)^(n/2).
  //  If n is odd,  then x^n = x * x^(n-1),
  //   and applying the equation for even x gives
  //    x^n = x * (x^2)^((n-1) / 2).
  //
  //  Also, EVM division is flooring and
  //    floor[(n-1) / 2] = floor[n / 2].
  //
  function rpow(uint256 x, uint256 n) internal pure returns (uint256 z) {
    z = n % 2 != 0 ? x : RAY;

    for (n /= 2; n != 0; n /= 2) {
      x = rmul(x, x);

      if (n % 2 != 0) {
        z = rmul(z, x);
      }
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IToken is IERC20 {
  function burnTokens(address _owner, uint256 _amount) external;

  function mintTokens(address _to, uint256 _amount) external;

  function transferContractOwner(address _newOwner) external;
}