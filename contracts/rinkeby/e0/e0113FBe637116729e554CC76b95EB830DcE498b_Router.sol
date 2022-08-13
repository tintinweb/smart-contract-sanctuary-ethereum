// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Pool.sol";
import "./SpaceCoin.sol";

contract Router {
    SpaceCoin private spaceCoin;
    Pool private pool;

    constructor(SpaceCoin _spaceCoin, Pool _pool) {
        spaceCoin = _spaceCoin;
        pool = _pool;
    }

    function addLiquidity(address _to, uint256 _ethAmount, uint256 _spcAmount, uint256 _ethAmountMin, uint256 _spcAmountMin) external payable {
        require(msg.value > 0 && _ethAmount == msg.value, "Router: Send the right amount of ETH");
        require(spaceCoin.balanceOf(_to) >= _spcAmount, "Router: Send the right amount of SPC tokens");

        /// lets calculate the amount of tokens required
        uint256 ethTransferAmount;
        uint256 spcTransferAmount;

        uint256 reserveETH = pool.reserveETH();
        uint256 reserveSPC = pool.reserveSPC();

        if (reserveETH == 0 && reserveSPC == 0) {
            ethTransferAmount = _ethAmount;
            spcTransferAmount = _spcAmount;
        } 
        else {
            uint256 amountSPCOptimal = _calculateExpectedAmount(_ethAmount, reserveETH, reserveSPC);

            if (amountSPCOptimal <= _spcAmount) {
                require(amountSPCOptimal >= _spcAmountMin, 'Router: Not enought SPC tokens to make LP');

                ethTransferAmount = _ethAmount;
                spcTransferAmount = amountSPCOptimal;
            } 
            else {
                uint256 amountETHOptimal = _calculateExpectedAmount(_spcAmount, reserveSPC, reserveETH);
                assert(amountETHOptimal <= _ethAmount);
                require(amountETHOptimal >= _ethAmountMin, 'Router: Not enought ETH to make LP');

                ethTransferAmount = amountETHOptimal;
                spcTransferAmount = _spcAmount;
            }
        }

        bool spcSuccess = spaceCoin.transferFrom(_to, address(pool), spcTransferAmount);
        require(spcSuccess, "Router: Failed to transfer tokens");

        /// lets mint the lp
        pool.mint{value: ethTransferAmount}(_to);
    }

    function removeLiquidity(address _to) external {
        /// check lp provider balance
        uint256 lpAmount = pool.balanceOf(_to);
        require(lpAmount > 0, "Router: No LP tokens available to burn");

        bool lpSuccess = pool.transferFrom(_to, address(pool), lpAmount);
        require(lpSuccess, "Router: Failed to transfer tokens");

        /// lets return their underlying tokens + any fees earned
        pool.burn(_to);
    }

    /// we swapt tokens according to a max slippage amount
    /// calculate slippage
    /// price impact = ((actual amount - expected amount)/expected amount) * 100
    function swapTokens(address _to, uint256 _ethAmountIN, uint256 _spcAmountIN, uint256 _amountOutMin) external payable {
        uint256 reserveETH = pool.reserveETH();
        uint256 reserveSPC = pool.reserveSPC();
        uint256 actualAmountOut;

        require(_ethAmountIN == 0 && _spcAmountIN > 0 || _ethAmountIN > 0 && _spcAmountIN == 0, "Router: You can only choose 1 token to swap");

        /// will receive ETH
        if(_spcAmountIN > 0) {
            require(spaceCoin.balanceOf(_to) > _spcAmountIN, "Router: Don't have enough SPC tokens");

            bool spcSuccess = spaceCoin.transferFrom(_to, address(pool), _spcAmountIN);
            require(spcSuccess, "Router: Failed to transfer tokens");

            /// check for min amounts
            actualAmountOut = _calculateActualAmount(_spcAmountIN, reserveSPC, reserveETH);
            require(actualAmountOut >= _amountOutMin, 'Router: Not enough ETH tokens to receive');

            pool.swap(_to, 0, _spcAmountIN);
        }

        /// will receive SPC
        else if(_ethAmountIN > 0) {
            require(_ethAmountIN == msg.value, "Pool: Wrong eth amount");

            /// check for min amounts
            actualAmountOut = _calculateActualAmount(_ethAmountIN, reserveETH, reserveSPC);
            require(actualAmountOut >= _amountOutMin, 'Router: Not enough SPC tokens to receive');
            
            pool.swap{value: msg.value}(_to, _ethAmountIN, 0);
        }
    }

    function _calculateActualAmount(uint256 _amountA, uint256 _reserveA, uint256 _reserveB) public view returns (uint amountB) {
        require(_amountA > 0, 'Router: Enter the right amountA');
        require(_reserveA > 0 && _reserveB > 0, 'Router: No liquidity available');

        uint256 feePerSwap = pool.feePerSwap();

        uint256 k = _reserveA * _reserveB;
        uint256 _reserveBNEW = k / (_reserveA + _amountA);

        uint256 netAmount = _reserveB - _reserveBNEW;
        uint256 feeAmount = (feePerSwap * netAmount) / 100;

        amountB = netAmount - feeAmount;
    }

    function _calculateExpectedAmount(uint256 _amountA, uint256 _reserveA, uint256 _reserveB) public pure returns (uint amountB) {
        require(_amountA > 0, 'Router: Enter the right amountA');
        require(_reserveA > 0 && _reserveB > 0, 'Router: No liquidity available');

        amountB = _amountA * _reserveB / _reserveA;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./SpaceCoin.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Pool is ERC20 {
    uint112 public reserveETH;
    uint112 public reserveSPC;
    uint32 public blockTimestampLast;
    
    uint32 public constant feePerSwap = 1;

    SpaceCoin private spaceCoin;

    constructor(SpaceCoin _spaceCoin) ERC20("SPC-ETH Pool", "SPC-ETH") {
        spaceCoin = _spaceCoin;
    }

    /// add liquidity
    /// pair token owner mint his lp tokens
    function mint(address _to) external payable {
        uint256 liquidity;
        uint256 LPtotalSupply = totalSupply();

        uint256 ethBalance = reserveETH + msg.value;
        uint256 spcBalance = spaceCoin.balanceOf(address(this));

        uint256 ethAmount = msg.value;
        uint256 spcAmount = spcBalance - reserveSPC;

        if (LPtotalSupply == 0) {
            liquidity = sqrt(ethAmount * spcAmount);
        } 
        else {
            liquidity = min(
                (ethAmount * LPtotalSupply) / reserveETH, 
                (spcAmount * LPtotalSupply) / reserveSPC
            );
        }

        require(liquidity > 0, "Pool: Add more liquidity to mint LP tokens");

        _mint(_to, liquidity);
        _update(ethBalance, spcBalance);

        emit Mint(_to, ethAmount, spcAmount);
    }

    /// remove liquidity
    /// the LP token holder redeems for underlying assets
    function burn(address _to) external {
        uint256 liquidity = balanceOf(address(this));
        uint256 LPtotalSupply = totalSupply();

        uint256 ethBalance = reserveETH;
        uint256 spcBalance = spaceCoin.balanceOf(address(this));

        uint256 ethAmount = (ethBalance * liquidity) / LPtotalSupply;
        uint256 spcAmount = (spcBalance * liquidity) / LPtotalSupply;

        require(ethAmount > 0 && spcAmount > 0, "Pool: No liquidity to be burned");

        _burn(address(this), liquidity);

        (bool ethSuccess, ) = _to.call{value: ethAmount}("");
        bool spcSuccess = spaceCoin.transfer(_to, spcAmount);

        require(ethSuccess && spcSuccess, "Pool: Failed to transfer tokens");

        ethBalance = ethBalance - ethAmount;
        spcBalance = spaceCoin.balanceOf(address(this));

        _update(ethBalance, spcBalance);

        emit Burn(_to, ethAmount, ethAmount);
    }

    /// here we charge 1% fee for swapping
    /// ethAmountIN = msg.value that comes from the router
    /// formula example: x * y = k
        /// xORG * yORG = k
        /// xORG = ETHreserve; yORG = SPCreserve; k = constant (ETHreserve*SPCreserve)
        /// yNEW = k/xORG
            /// userAmount = yORG - yNEW
        /// xNEW = k/yORG
            /// userAmount = xORG - xNEW
    function swap(address _to, uint256 ethAmountIN, uint256 spcAmountIN) external payable {
        require(ethAmountIN > 0 && spcAmountIN == 0 || spcAmountIN > 0 && ethAmountIN == 0, "Pool: Set swaps amount");
        require(reserveETH > ethAmountIN && reserveSPC > spcAmountIN, "Pool: Not enough liquidity");

        uint256 ethAmountOUT;
        uint256 spcAmountOUT;

        uint256 ethBalance = reserveETH;
        uint256 spcBalance = reserveSPC;

        /// x * y = k
        uint256 xORG = ethBalance;
        uint256 yORG = spcBalance;
        uint256 k = xORG * yORG;

        /// we swap ETH for SPC example below
            /// 10 ETH * 50 SPC = 500
            /// the user adds 1 ETH to the swap
            /// 11 * yNEW = 500
            /// yNEW = 500/11
            /// yNEW = 45.45
            /// amountSPC = yORG - yNEW
            /// amountSPC = 50 - 45.45
            /// amountSPC = 4.55
            /// then take the fees ;-)
        if(ethAmountIN > 0) {
            require(ethAmountIN == msg.value, "Pool: Wrong eth amount");
            ethAmountOUT = 0;

            uint256 yNEW = k / (xORG + ethAmountIN);

            uint256 netSPC = yORG - yNEW;
            uint256 feeSPC = (feePerSwap * netSPC) / 100;

            spcAmountOUT = netSPC - feeSPC;

            bool spcSuccess = spaceCoin.transfer(_to, spcAmountOUT);
            require(spcSuccess, "Pool: Failed to transfer tokens");

            ethBalance = ethBalance + ethAmountIN;
        }

        /// we swap SPC for ETH
        else if(spcAmountIN > 0) {
            spcAmountOUT = 0;

            uint256 xNEW = k / (yORG + spcAmountIN);

            uint256 netETH = xORG - xNEW;
            uint256 feeETH = (feePerSwap * netETH) / 100;

            ethAmountOUT = netETH - feeETH;

            (bool ethSuccess, ) = _to.call{value: ethAmountOUT}("");
            require(ethSuccess, "Pool: Failed to transfer tokens");

            ethBalance = (ethBalance + feeETH) - ethAmountOUT;
        }

        spcBalance = spaceCoin.balanceOf(address(this));

        /// lets verify that the user really deposited tokens to the pool
        uint256 verifyETHAmountIn;
        if(address(this).balance > reserveETH - ethAmountOUT) {
            verifyETHAmountIn = address(this).balance - (reserveETH - ethAmountOUT);
        }
        else {
            verifyETHAmountIn = 0;
        }

        uint256 verifySPCAmountIn;
        if(spcBalance > reserveSPC - spcAmountOUT) {
            verifySPCAmountIn = spcBalance - (reserveSPC - spcAmountOUT);
        }
        else {
            verifySPCAmountIn = 0;
        }

        require(verifyETHAmountIn > 0 || verifySPCAmountIn > 0, 'Pool: Deposit tokens to swap');

        /// lets verify k is still valid
        uint256 balanceETHAdjusted = (address(this).balance * 100) - (ethAmountIN * 1);
        uint256 balanceSPCAdjusted = (spcBalance * 100) - (spcAmountIN * 1);

        require(balanceETHAdjusted * balanceSPCAdjusted >= uint256(reserveETH) * uint256(reserveSPC) * (100**2), 'Pool: K is not valid');

        _update(ethBalance, spcBalance);

        emit TokenSwap(_to, ethAmountIN, spcAmountIN, ethAmountOUT, spcAmountOUT);
    }

    function _update(uint256 ethBalance, uint256 spcBalance) private {
        require(ethBalance <= type(uint112).max && spcBalance <= type(uint112).max, 'Pool: Overflow');

        reserveETH = uint112(ethBalance);
        reserveSPC = uint112(spcBalance);

        blockTimestampLast = uint32(block.timestamp % 2**32);

        emit Update(reserveETH, reserveSPC);
    }

    /// babylonian method
    function sqrt(uint256 y) internal pure returns (uint256 z) {
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

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    event Mint(address indexed addressMint, uint256 ethAmount, uint256 spcAmount);
    event Burn(address indexed addressBurn, uint256 ethAmount, uint256 spcAmount);
    event TokenSwap(address indexed addressTraded, uint256 ethAmountIN, uint256 spcAmountIN, uint256 ethAmountOUT, uint256 spcAmountOUT);
    event Update(uint112 reserveETH, uint112 reserveSPC);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SpaceCoin is ERC20 {
    uint256 public constant MAX_SUPPLY = 500_000 * 10**18;
    uint256 public constant ICO_SUPPLY = 150_000 * 10**18;
    uint256 public constant TREASURY_SUPPLY = 350_000 * 10**18;

    bool public isTaxEnable = false;
    uint256 public constant TAX_PERCENTAGE = 2;

    address public treasuryAddress;
    address public icoAddress;

    /// used to block non-owners from calling some functions
    address public owner;
    modifier onlyOwner() {
        require(msg.sender == owner, "SpaceCoin: Not owner");
        _;
    }

    /// set the ICO contract address and the treasury address
    /// mint tokens and send them to the ICO contract
    /// set the contract owner
    constructor(address _icoAddress, address _treasuryAddress) ERC20("SpaceCoin", "SPC") {
        owner = msg.sender;
        icoAddress = _icoAddress;
        treasuryAddress = _treasuryAddress;

        _mint(_icoAddress, ICO_SUPPLY);
        _mint(_treasuryAddress, TREASURY_SUPPLY);
    }

    /// override transfer functions to charge the tax fee 
    /// send that fee to the treasury wallet
    function _transfer(address _from, address _to, uint256 _amount) internal virtual override {
        if(isTaxEnable) {
            uint256 taxAmount = (_amount * TAX_PERCENTAGE) / 100;
            _amount = _amount - taxAmount;
            super._transfer(_from, treasuryAddress, taxAmount);
        }

        super._transfer(_from, _to, _amount);
    }

    /// enable/disable the tax fee on transfers
    function enableDisableTax() external onlyOwner {
        isTaxEnable = !isTaxEnable;
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