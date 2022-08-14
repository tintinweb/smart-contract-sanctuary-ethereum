// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./LiquidityPool.sol";
import "./SpaceCoin.sol";

contract Router {
  SpaceCoin public immutable spc;
  LiquidityPool public immutable lp;

  event RouterDeployed();
  event RouterAddLiquidity(uint256 spcIn, uint256 ethIn);
  event RouterRemoveLiquidity(uint256 spcOut, uint256 ethOut);
  event RouterSwapedEthForSpc(uint256 ethIn, uint256 spcOut);
  event RouterSwapedSpcForEth(uint256 spcIn, uint256 ethOut);

  error RouterLowerThanMinAmount();
  error RouterEthTransferFailed();
  error RouterQuoteInsufficientAmount();
  error RouterQuoteInsufficientLiquidity();
  error RouterInsufficientSpcAmount();
  error RouterInsufficientEthAmount();
  error RouterInsufficientLiquidity();
  error RouterExpired();

  modifier ensure(uint256 deadline) {
    if (block.timestamp >= deadline) revert RouterExpired();
    _;
  }

  constructor(address _spc, address _lp) {
    spc = SpaceCoin(_spc);
    lp = LiquidityPool(payable(_lp));
    emit RouterDeployed();
  }

  function addLiquidity(
    uint256 spcMinAmount,
    uint256 ethMinAmount,
    uint256 spcAmountDesired,
    uint256 deadline
  ) public payable ensure(deadline) {
    uint256 ethAmountDesired = msg.value;
    (uint256 spcAmount, uint256 ethAmount) = _addLiquidity(
      spcMinAmount,
      ethMinAmount,
      spcAmountDesired,
      ethAmountDesired
    );

    spc.transferFrom(msg.sender, address(lp), spcAmount);
    _ethTransfer(address(lp), ethAmount, "");

    lp.mint(msg.sender);
    emit RouterAddLiquidity(spcAmount, ethAmount);

    uint256 ethReminder = msg.value - ethAmount;
    if (ethReminder > 0) _ethTransfer(msg.sender, ethReminder, "");
  }

  function removeLiquidity(
    uint256 lpTokens,
    uint256 spcMinAmount,
    uint256 ethMinAmount,
    uint256 deadline
  ) public ensure(deadline) {
    lp.transferFrom(msg.sender, address(lp), lpTokens);
    (uint256 spcAmount, uint256 ethAmount) = lp.burn(msg.sender);
    if (spcAmount < spcMinAmount) revert RouterInsufficientSpcAmount();
    if (ethAmount < ethMinAmount) revert RouterInsufficientEthAmount();

    emit RouterRemoveLiquidity(spcAmount, ethAmount);
  }

  function swapEthForSpc(uint256 minSpcOut, uint256 deadline)
    public
    payable
    ensure(deadline)
  {
    (uint256 spcReserves, uint256 ethReserves) = lp.getReserves();
    if (spcReserves == 0 || ethReserves == 0)
      revert RouterInsufficientLiquidity();
    uint256 ethAmountIn = msg.value;

    uint256 spcOut = _getSpcAmountOut(ethAmountIn, ethReserves, spcReserves);
    if (spcOut < minSpcOut) revert RouterLowerThanMinAmount();

    _ethTransfer(address(lp), ethAmountIn, "swapDeposit()");

    lp.swapEthForSpc(spcOut, msg.sender);
    emit RouterSwapedEthForSpc(ethAmountIn, spcOut);
  }

  function swapSpcForEth(
    uint256 spcIn,
    uint256 minEthOut,
    uint256 deadline
  ) public ensure(deadline) {
    (uint256 spcReserves, uint256 ethReserves) = lp.getReserves();
    if (spcReserves == 0 || ethReserves == 0)
      revert RouterInsufficientLiquidity();

    uint256 ethOut = _getEthAmountOut(spcIn, ethReserves, spcReserves);
    if (ethOut < minEthOut) revert RouterLowerThanMinAmount();

    spc.transferFrom(msg.sender, address(lp), spcIn);

    lp.swapSpcForEth(ethOut, msg.sender);
    emit RouterSwapedSpcForEth(spcIn, ethOut);
  }

  function _ethTransfer(
    address to,
    uint256 value,
    bytes memory _calldata
  ) private {
    (bool success, ) = payable(to).call{value: value}(
      abi.encodePacked(bytes4(keccak256(_calldata)))
    );
    if (!success) revert RouterEthTransferFailed();
  }

  function _getSpcAmountOut(
    uint256 ethAmountIn,
    uint256 ethReserves,
    uint256 spcReserves
  ) private pure returns (uint256) {
    uint256 ethAmountInFeeDeducted = (99 * ethAmountIn) / 100;
    uint256 k = spcReserves * ethReserves;
    uint256 newSpcReserve = k / (ethReserves + ethAmountInFeeDeducted);

    return spcReserves - newSpcReserve;
  }

  function _getEthAmountOut(
    uint256 spcAmountIn,
    uint256 ethReserves,
    uint256 spcReserves
  ) private pure returns (uint256) {
    uint256 spcAmountInFeeDeducted = (99 * spcAmountIn) / 100;
    uint256 k = spcReserves * ethReserves;
    uint256 newEthReserve = k / (spcReserves + spcAmountInFeeDeducted);

    return ethReserves - newEthReserve;
  }

  function _addLiquidity(
    uint256 spcMinAmount,
    uint256 ethMinAmount,
    uint256 spcAmountDesired,
    uint256 ethAmountDesired
  ) private view returns (uint256 spcAmount, uint256 ethAmount) {
    (uint256 spcReserves, uint256 ethReserves) = lp.getReserves();

    if (spcReserves == 0) {
      // setting initial reserve following the ICO 1:5 ratio
      uint256 ethOpitmalAmount = spcAmountDesired / 5;

      require(
        ethOpitmalAmount <= ethAmountDesired,
        "Router: eth amount higher than desired"
      );
      (spcAmount, ethAmount) = (spcAmountDesired, ethOpitmalAmount);
    } else {
      uint256 ethOpitmalAmount = _quote(
        spcAmountDesired,
        spcReserves,
        ethReserves
      );
      if (ethOpitmalAmount <= ethAmountDesired) {
        require(
          ethOpitmalAmount >= ethMinAmount,
          "Router: eth amount less than minimum"
        );
        (spcAmount, ethAmount) = (spcAmountDesired, ethOpitmalAmount);
      } else {
        uint256 spcOpitimalAmount = _quote(
          ethAmountDesired,
          ethReserves,
          spcReserves
        );
        require(
          spcOpitimalAmount >= spcMinAmount,
          "Router: spc amount less than minimum"
        );
        (spcAmount, ethAmount) = (spcOpitimalAmount, ethAmountDesired);
      }
    }
  }

  function _quote(
    uint256 amountA,
    uint256 reserveA,
    uint256 reserveB
  ) private pure returns (uint256) {
    if (amountA == 0) revert RouterQuoteInsufficientAmount();
    if (reserveA == 0 && reserveB == 0)
      revert RouterQuoteInsufficientLiquidity();

    return (amountA * reserveB) / reserveA; // returns amountB
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract LiquidityPool is ERC20 {
  ERC20 public immutable spc;
  uint256 public constant MINIMUM_LIQUIDITY = 10**3;

  uint256 public spcReserve;
  uint256 public ethReserve;
  uint256 public kLast;

  event LPDeployed(address lp);
  event LPMintedTokens(address to, uint256 amount);
  event LPBurnedTokens(address to, uint256 amount);
  event LPUpdatedReserves(uint256 spc, uint256 eth);
  event LPSwapedEthForSpc(uint256 ethIn, uint256 spcOut);
  event LPSwapedSpcForEth(uint256 spcIn, uint256 ethOut);

  error LPInsufficientOutputAmount();
  error LPInsufficientLiquidity();
  error LPInsufficientLiquidityMinted();
  error LPInsufficientLiquidityBurned();
  error LPInvalidTo();
  error LPInvalidEthDeposit();
  error LPInvalidSpcDeposit();
  error LPEthTransferFailed();
  error LPLocked();
  error LPk();

  uint256 private unlocked = 1;
  modifier lock() {
    if (unlocked == 0) revert LPLocked();
    unlocked = 0;
    _;
    unlocked = 1;
  }

  constructor(address _spc) ERC20("LiquidityPoolSPC", "spcLP") {
    spc = ERC20(_spc);
    emit LPDeployed(address(this));
  }

  receive() external payable {}

  fallback() external payable {}

  function swapDeposit() external payable {
    ethReserve += msg.value;
  }

  function getReserves()
    public
    view
    returns (uint256 _spcReserve, uint256 _ethReserve)
  {
    _spcReserve = spcReserve;
    _ethReserve = ethReserve;
  }

  function mint(address to) external lock {
    uint256 spcBalance = spc.balanceOf(address(this));
    uint256 ethBalance = address(this).balance;
    (uint256 _spcReserve, uint256 _ethReserve) = getReserves();

    uint256 spcAmount = spcBalance - _spcReserve;
    uint256 ethAmount = ethBalance - _ethReserve;

    uint256 liquidity;
    uint256 _totalSupply = totalSupply();

    if (_totalSupply == 0) {
      liquidity = _sqrt(spcAmount * ethAmount) - MINIMUM_LIQUIDITY;
      _mint(address(1), MINIMUM_LIQUIDITY);
    } else {
      uint256 spcLiquidity = (spcAmount * _totalSupply) / _spcReserve;
      uint256 ethLiquidity = (ethAmount * _totalSupply) / _ethReserve;
      liquidity = spcLiquidity > ethLiquidity ? ethLiquidity : spcLiquidity;
    }
    if (liquidity == 0) revert LPInsufficientLiquidityMinted();

    _mint(to, liquidity);

    _update(spcBalance, ethBalance);
    kLast = spcBalance * ethBalance;

    emit LPMintedTokens(to, liquidity);
  }

  function burn(address to)
    external
    lock
    returns (uint256 spcAmount, uint256 ethAmount)
  {
    uint256 spcBalance = spc.balanceOf(address(this));
    uint256 ethBalance = address(this).balance;
    uint256 lpTokens = balanceOf(address(this));
    uint256 _totalSupply = totalSupply();

    spcAmount = (lpTokens * spcBalance) / _totalSupply;
    ethAmount = (lpTokens * ethBalance) / _totalSupply;
    if (spcAmount == 0 && ethAmount == 0)
      revert LPInsufficientLiquidityBurned();

    _burn(address(this), lpTokens);

    spc.transfer(to, spcAmount);
    _ethTransfer(to, ethAmount);

    spcBalance = spc.balanceOf(address(this));
    ethBalance = address(this).balance;

    _update(spcBalance, ethBalance);
    kLast = spcBalance * ethBalance;
    emit LPBurnedTokens(to, lpTokens);
  }

  function swapEthForSpc(uint256 spcOut, address to) external lock {
    if (spcOut == 0) revert LPInsufficientOutputAmount();
    if (to == address(this) || to == address(spc)) revert LPInvalidTo();

    (uint256 _spcReserve, uint256 _ethReserve) = getReserves();
    if (spcOut > _spcReserve) revert LPInsufficientLiquidity();

    spc.transfer(to, spcOut);

    uint256 ethAmountIn = _ethReserve - (kLast / _spcReserve);
    if (ethAmountIn == 0) revert LPInvalidEthDeposit();
    uint256 spcBalance = spc.balanceOf(address(this));

    if (spcOut >= _spcReserve - (kLast / _ethReserve)) revert LPk(); // 1% fee

    emit LPSwapedEthForSpc(ethAmountIn, spcOut);
    _update(spcBalance, _ethReserve);
  }

  function swapSpcForEth(uint256 ethOut, address to) external lock {
    if (ethOut == 0) revert LPInsufficientOutputAmount();
    if (to == address(this) || to == address(spc)) revert LPInvalidTo();

    (uint256 _spcReserve, uint256 _ethReserve) = getReserves();
    if (ethOut > _ethReserve) revert LPInsufficientLiquidity();

    _ethTransfer(to, ethOut);

    uint256 spcBalance = spc.balanceOf(address(this));
    uint256 spcAmountIn = spcBalance - _spcReserve;

    if (spcAmountIn == 0) revert LPInvalidSpcDeposit();
    uint256 ethBalance = _ethReserve - ethOut;

    if (ethOut >= _ethReserve - (kLast / spcBalance)) revert LPk(); // 1% fee

    emit LPSwapedSpcForEth(spcAmountIn, ethOut);
    _update(spcBalance, ethBalance);
  }

  function _update(uint256 spcBalance, uint256 ethBalance) private {
    spcReserve = spcBalance;
    ethReserve = ethBalance;

    emit LPUpdatedReserves(spcReserve, ethReserve);
  }

  function _ethTransfer(address to, uint256 amount) private {
    (bool success, ) = payable(to).call{value: amount}("");
    if (!success) revert LPEthTransferFailed();
  }

  function _sqrt(uint256 y) private pure returns (uint256 z) {
    if (y > 3) {
      z = y;
      uint256 x = y / 2 + 1;
      while (x < z) {
        z = x;
        x = (y / x + x) / 2;
      }
    } else if (y != 0) {
      z = 1;
    }
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./SpaceCoinICO.sol";

contract SpaceCoin is ERC20 {
  address public immutable ico;
  address public immutable owner;
  address public immutable treasury;

  bool public taxing = false;

  error Unauthorized();

  event TokenDeployed(address owner, address treasury);
  event TaxEnabled();
  event TaxDisabled();

  constructor(address _treasury) ERC20("SpaceCoin", "SPC") {
    SpaceCoinICO _ico = new SpaceCoinICO(msg.sender, address(this), _treasury);

    ico = address(_ico);
    owner = msg.sender;
    treasury = _treasury;

    _mint(_treasury, 500_000 * 10**decimals());
    _transfer(_treasury, ico, 150_000 * 10**decimals());

    emit TokenDeployed(owner, treasury);
  }

  function toggleTax() external {
    if (msg.sender != owner) revert Unauthorized();
    taxing = !taxing;

    if (taxing) {
      emit TaxEnabled();
    } else {
      emit TaxDisabled();
    }
  }

  function transfer(address to, uint256 amount)
    public
    virtual
    override
    returns (bool)
  {
    uint256 discountedAmount = _transferFeeDeduction(msg.sender, amount);
    _transfer(msg.sender, to, discountedAmount);

    return true;
  }

  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) public virtual override returns (bool) {
    _spendAllowance(from, msg.sender, amount);

    uint256 discountedAmount = _transferFeeDeduction(from, amount);
    _transfer(from, to, discountedAmount);

    return true;
  }

  function _transferFeeDeduction(address from, uint256 amount)
    internal
    virtual
    returns (uint256)
  {
    if (!taxing) return amount;

    uint256 fee = (amount / 100) * 2; // 2% tax
    _transfer(from, treasury, fee);

    return amount - fee;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

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
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
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
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./SpaceCoin.sol";

contract SpaceCoinICO {
  uint256 public constant MAX_ETH_BALANCE = 30_000 ether;
  address public immutable spcContract;
  address private immutable owner;
  address private immutable treasury;

  uint256 private totalFunded;
  bool public icoEnded = false;

  Phase public currentPhase;
  bool public paused = false;

  mapping(address => bool) public allowlist;
  mapping(address => uint256) public balance;

  enum Phase {
    SEED,
    GENERAL,
    OPEN
  }

  event IcoDeployed();
  event AddedToAllowlist(address[] investors);
  event RemovedFromAllowlist(address[] investor);
  event PhaseAdvanced(Phase newPhase);
  event Paused(bool paused);
  event Contribution(address investor, uint256 amount);
  event Redeem(address to, uint256 amount);
  event IcoWithdraw(address to, uint256 time);

  error Unauthorized();
  error IcoPaused();
  error IcoLimit();
  error IndividualLimit();
  error NoBalance();
  error NoSpcBalance();
  error IcoOpenPhaseRequired();
  error IcoWithdrawFailed();
  error IcoMaxFundingRequired();

  constructor(
    address _owner,
    address _spcContract,
    address _treasury
  ) {
    spcContract = _spcContract;
    owner = _owner;
    treasury = _treasury;
    currentPhase = Phase.SEED;

    emit IcoDeployed();
  }

  modifier onlyOwner() {
    if (msg.sender != owner) revert Unauthorized();
    _;
  }

  modifier checkIcoBalance() {
    if (currentPhase == Phase.SEED) {
      if (totalFunded + msg.value > MAX_ETH_BALANCE / 2) revert IcoLimit();
    }

    if (totalFunded + msg.value > MAX_ETH_BALANCE) revert IcoLimit();
    _;
  }

  modifier checkIcoPhase() {
    uint256 callerLimit = (balance[msg.sender] + msg.value);

    if (currentPhase == Phase.SEED) {
      if (!allowlist[msg.sender]) revert Unauthorized();
      if (callerLimit > 1_500 ether) revert IndividualLimit();
    }

    if (currentPhase == Phase.GENERAL) {
      if (callerLimit > 1_000 ether) revert IndividualLimit();
    }
    _;
  }

  function addToAllowlist(address[] memory investors) external onlyOwner {
    for (uint256 i = 0; i < investors.length; i++) {
      allowlist[investors[i]] = true;
    }

    emit AddedToAllowlist(investors);
  }

  function removeFromAllowlist(address[] memory investors) external onlyOwner {
    for (uint256 i = 0; i < investors.length; i++) {
      allowlist[investors[i]] = false;
    }
    emit RemovedFromAllowlist(investors);
  }

  function togglePaused() external onlyOwner {
    paused = !paused;
    emit Paused(paused);
  }

  function nextPhase(Phase _nextPhase) external onlyOwner {
    if (_nextPhase > currentPhase) {
      currentPhase = _nextPhase;
      emit PhaseAdvanced(_nextPhase);
    }
  }

  function contribute() external payable checkIcoBalance checkIcoPhase {
    if (paused) revert IcoPaused();

    balance[msg.sender] += msg.value;
    totalFunded += msg.value;
    emit Contribution(msg.sender, msg.value);

    if (currentPhase == Phase.OPEN) redeemToken();
  }

  function withdrawToTreasury() external onlyOwner {
    if (address(this).balance == 0) revert NoBalance();

    (bool success, ) = treasury.call{value: address(this).balance}("");
    if (!success) revert IcoWithdrawFailed();

    emit IcoWithdraw(treasury, block.timestamp);
  }

  function redeemToken() public {
    if (currentPhase != Phase.OPEN) revert IcoOpenPhaseRequired();
    if (balance[msg.sender] == 0) revert NoSpcBalance();

    uint256 tokensEarned = balance[msg.sender] * 5;
    SpaceCoin _token = SpaceCoin(spcContract);

    balance[msg.sender] = 0;

    _token.transfer(msg.sender, tokensEarned);
    emit Redeem(msg.sender, tokensEarned);
  }
}