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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

pragma solidity ^0.8.0;

interface IgetPrice {
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint8 _fee
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut,
        uint8 _fee
    ) external pure returns (uint256 amountIn);
}

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;


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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;
    uint256 internal _totalSupply;
    string internal _name;
    string internal _symbol;
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }  
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }
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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }
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
    function _mint(uint256 amount) public virtual {
        require(msg.sender != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), msg.sender, amount);

        _totalSupply += amount;
        _balances[msg.sender] += amount;
        emit Transfer(address(0), msg.sender, amount);

        _afterTokenTransfer(address(0), msg.sender, amount);
    }
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
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}


pragma solidity ^0.8.0;

//TODO: Add events

contract poolToken is ERC20{
    IERC20 private _token1;
    IERC20 private _token2;
    uint8 private _fee;

    constructor(
        address _token1address,
        address _token2address,
        uint8 fee,
        string memory name_,
        string memory symbol_
    ) ERC20(name_, symbol_) {
        _token1 = IERC20(_token1address);
        _token2 = IERC20(_token2address);
        _fee = fee;
    }

    //START VIEW FUNCTIONS
    function viewToken1() public view virtual returns (address) {
        return address(_token1);
    }

    function viewToken2() public view virtual returns (address) {
        return address(_token2);
    }

    function viewFee() public view virtual returns (uint8) {
        return _fee;
    }

    function getPrice() public view returns (uint256 price) {
        price =
            _token1.balanceOf(address(this)) /
            _token2.balanceOf(address(this));
    }

    function getDepositReqsFromToken1(uint256 token1amount)
        public
        view
        returns (uint256)
    {
        uint256 token2amount = token1amount / getPrice();
        return token2amount;
    }

    function getDepositReqsFromToken2(uint256 token2amount)
        public
        view
        returns (uint256 token1amount)
    {
        return token2amount * getPrice();
    }

    function reviewSwap(
        uint256 amountIn,
        address tokenIn,
        address tokenOut
    ) public view returns (uint256 amountOut) {
        IERC20 _tokenIn = IERC20(tokenIn);
        IERC20 _tokenOut = IERC20(tokenOut);
        uint256 token1Balance = _tokenIn.balanceOf(address(this));
        uint256 token2Balance = _tokenOut.balanceOf(address(this));
        amountOut = getAmountOut(amountIn, token1Balance, token2Balance, _fee);
        return amountOut;
    }


    /// @dev END VIEW FUNCTIONS

    /// @notice minimumDeposit is the first thing that happens
    /// @notice tokens deposited in minimumDeposit are permanently locked
    function init(uint256 token1amount, uint256 token2amount) public returns (bool) {
        require(_totalSupply == 0, "Already has liquidity");
        require(_token1.transferFrom(msg.sender, address(this), token1amount));
        require(_token2.transferFrom(msg.sender, address(this), token2amount));
        uint256 liquidityMinted = token1amount;
        _mint(liquidityMinted);
        return true;
    }

    /// @dev token2amount is derived from getPrice and token1amount
    function mintFromToken1amount(uint256 token1amount) public returns (bool) {
        uint256 token2amount = token1amount / getPrice();
        require(_token1.transferFrom(msg.sender, address(this), token1amount));
        require(_token2.transferFrom(msg.sender, address(this), token2amount));
        uint256 liquidityMinted = (token1amount * _totalSupply) /
            _token1.balanceOf(address(this));
        _mint(liquidityMinted);
        return true;
    }

    function mintFromToken2amount(uint256 token2amount) public returns (bool) {
        uint256 token1amount = token2amount * getPrice();
        require(_token1.transferFrom(msg.sender, address(this), token1amount));
        require(_token2.transferFrom(msg.sender, address(this), token2amount));
        uint256 liquidityMinted = (token1amount * _totalSupply) /
            _token1.balanceOf(address(this));
        _mint(liquidityMinted);
        return true;
    }
    
    function mintExactLPtokens(uint256 _mintAmount) public returns (bool) {
        uint256 token1amount = (_mintAmount *
            _token1.balanceOf(address(this))) / _totalSupply;
        uint256 token2amount = token1amount / getPrice();
        require(_token1.transferFrom(msg.sender, address(this), token1amount));
        require(_token2.transferFrom(msg.sender, address(this), token2amount));
        _mint(_mintAmount);
        return true;
    }

    /// @notice it is impossible to withdraw 100% of liquidity
    function withdraw(uint256 token1amount) public returns (bool) {
        uint256 token2amount = token1amount / getPrice();
        uint256 liquidityBurnt = (token1amount * _totalSupply) /
            _token1.balanceOf(address(this));
        require(_balances[msg.sender] >= liquidityBurnt);
        require(_totalSupply - liquidityBurnt > 0);
        _balances[msg.sender] -= liquidityBurnt;
        _totalSupply -= liquidityBurnt;
        require(_token1.transfer(msg.sender, token1amount));
        require(_token2.transfer(msg.sender, token2amount));
        _burn(msg.sender, liquidityBurnt);
        return true;
    }

    function swap(
        uint256 amountIn,
        address tokenIn,
        address tokenOut
    ) public returns (bool) {
        IERC20 _tokenIn = IERC20(tokenIn);
        IERC20 _tokenOut = IERC20(tokenOut);
        uint256 token1Balance = _tokenIn.balanceOf(address(this));
        uint256 token2Balance = _tokenOut.balanceOf(address(this));
        uint256 amountOut = getAmountOut(
            amountIn,
            token1Balance,
            token2Balance,
            _fee
        );
        _tokenIn.transferFrom(msg.sender, address(this), amountIn);
        _tokenOut.transfer(msg.sender, amountOut);
        return (true);
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint8 fee
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "Input must be greater than 0");
        require(reserveIn > 0 && reserveOut > 0, "Not enough liquidity");
        uint16 adjustedFee = uint16(1000 - uint16(fee));
        uint256 amountInWithFee = amountIn * adjustedFee;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = (reserveIn * 1000) + amountInWithFee;
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut,
        uint8 fee
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        uint16 adjustedFee = uint16(1000 - uint16(fee));
        uint256 numerator = reserveIn * amountOut * 1000;
        uint256 denominator = (reserveOut - amountOut) * adjustedFee;
        amountIn = (numerator / denominator) + 1;
    }
}