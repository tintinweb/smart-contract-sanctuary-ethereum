//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TWD is ERC20 {
    constructor() ERC20("Taiwan Dollar", "TWD") {
        _mint(msg.sender, 1_000_000 * 1e18);
    }
}

contract USD is ERC20 {
    constructor() ERC20("US Dollar", "USD") {
        _mint(msg.sender, 1_000_000 * 1e18);
    }
}

contract USDC is ERC20 {
    constructor() ERC20("USD Coin", "USDC") {
        _mint(msg.sender, 1_000_00 * 1e18);
    }
}

contract AMM {
    address private token0;
    address private token1;
    mapping(address => bool) public validTokens;
    mapping(address => uint256) public totalTokens;
    // k = totalToken0 * totalToken1
    uint256 public k;
    // stores the shareholding of liquidity pool - precision of 6 decimal places
    uint256 public constant PRECISION = 1_000_000;

    event AddLiquidity(
        address indexed token0,
        address indexed token1,
        uint256 amountToken0,
        uint256 amountToken1
    );

    constructor(address _token0, address _token1) {
        validTokens[_token0] = true;
        validTokens[_token1] = true;
        token0 = _token0;
        token1 = _token1;
    }

    function addLiquidity(
        address _token0,
        address _token1,
        uint256 _amountToken0,
        uint256 _amountToken1
    ) external {
        // require user to have sufficient balance of both token0 and token1
        require(validTokens[_token0] && validTokens[_token1], "not_valid");
        require(
            ERC20(token0).balanceOf(msg.sender) >= _amountToken0 &&
                ERC20(token1).balanceOf(msg.sender) >= _amountToken1,
            "INSUFFICIENT_AMOUNT"
        );
        //require user to have approved both token0 and token1
        require(
            ERC20(token0).allowance(msg.sender, address(this)) >=
                _amountToken0 &&
                ERC20(token1).allowance(msg.sender, address(this)) >=
                _amountToken1,
            "INSUFFICIENT_ALLOWANCE"
        );

        totalTokens[token0] += _amountToken0;
        totalTokens[token1] += _amountToken1;

        k = totalTokens[token0] * totalTokens[token1];

        ERC20(token0).transferFrom(msg.sender, address(this), _amountToken0);
        ERC20(token1).transferFrom(msg.sender, address(this), _amountToken1);

        emit AddLiquidity(_token0, _token1, _amountToken0, _amountToken1);
    }

    function getPoolDetails()
        external
        view
        returns (
            address,
            address,
            string memory,
            string memory,
            uint256,
            uint256
        )
    {
        return (
            token0,
            token1,
            ERC20(token0).symbol(),
            ERC20(token1).symbol(),
            ERC20(token0).balanceOf(address(this)),
            ERC20(token1).balanceOf(address(this))
        );
    }

    function getPrice(address _tokenA) external view returns (uint256) {
        // price with 6 decimals
        require(validTokens[_tokenA], "not_valid");
        uint256 decimals = 1_000_000;
        address _tokenB = _tokenA == token0 ? token1 : token0;
        return (totalTokens[_tokenB] / totalTokens[_tokenA]) * decimals;
    }

    // get the token0 estimated amount after depositing token1
    function getSwapTokenBEstimateGivenTokenA(
        address _tokenA,
        uint256 _amountTokenA
    ) public view returns (uint256 amountTokenB) {
        // ensure amountToken0 is valid
        require(_amountTokenA > 0 && validTokens[_tokenA], "INVALID_AMOUNT");
        address _tokenB = _tokenA == token0 ? token1 : token0;
        uint256 tokenABefore = totalTokens[_tokenA];
        uint256 tokenBBefore = totalTokens[_tokenB];
        uint256 tokenAAfter = tokenABefore + _amountTokenA;
        amountTokenB = tokenBBefore - k / tokenAAfter;

        // if k/ tokenAAfter==0, amountTokenB will be depleted
        if (amountTokenB == tokenBBefore) amountTokenB--;
    }

    function swapTokenA(address _tokenA, uint256 _amountTokenA)
        external
        returns (uint256 _amountTokenB)
    {
        require(validTokens[_tokenA], "not_valid");
        address _tokenB = _tokenA == token0 ? token1 : token0;
        require(
            ERC20(_tokenA).balanceOf(msg.sender) >= _amountTokenA,
            "INSUFFICIENT_AMOUNT"
        );
        require(
            ERC20(_tokenA).allowance(msg.sender, address(this)) >=
                _amountTokenA,
            "INSUFFICIENT_ALLOWANCE"
        );

        _amountTokenB = getSwapTokenBEstimateGivenTokenA(
            _tokenA,
            _amountTokenA
        );
        require(_amountTokenB < totalTokens[_tokenB], "INSUFFICIENT_LIQUIDITY");
        // adjust totalToken0 and totalToken1
        totalTokens[_tokenA] += _amountTokenA;
        totalTokens[_tokenB] -= _amountTokenB;

        ERC20(_tokenA).transferFrom(msg.sender, address(this), _amountTokenA);
        ERC20(_tokenB).transfer(msg.sender, _amountTokenB);
    }
}

contract Exchange is ERC20 {
    // EOA maps to token maps to balances
    mapping(address => mapping(address => uint256)) balances;
    // EOA maps to token maps to leverageBalances
    mapping(address => uint256) leverageBalances;
    uint256 public constant MAX_LEVERAGE = 10;
    mapping(address => mapping(address => address)) tokensToPool;
    //address array to store the number of pools created
    address[] public pools;
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        address indexed pool,
        uint256 poolCount
    );

    constructor() ERC20("vUSDC", "vUSDC") {}

    // initial deposit
    function deposit(address token, uint256 amount) external {
        require(token != address(0), "invalid_address");
        require(
            ERC20(token).balanceOf(msg.sender) >= amount,
            "insufficient_amount"
        );
        //require user to have approved both token0 and token1
        require(
            ERC20(token).allowance(msg.sender, address(this)) >= amount,
            "insufficient_allowance"
        );
        balances[msg.sender][token] += amount;
        leverageBalances[msg.sender] += amount * MAX_LEVERAGE;
        ERC20(token).transferFrom(msg.sender, address(this), amount);
        // mint vUSDC to this account
        _mint(address(this), amount * MAX_LEVERAGE);
    }

    function retrieveAllPools() external view returns (address[] memory) {
        return pools;
    }

    // example: create a tokenA/vUSDC pool
    function createPool(
        address tokenA,
        uint256 amountA,
        uint256 amountBWithLeverage
    ) external returns (address poolAddress) {
        require(tokenA != address(0), "INVALID_ADDRESS");

        require(
            tokensToPool[tokenA][address(this)] == address(0),
            "pool_exists"
        );
        ERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
        require(
            amountBWithLeverage <= leverageBalances[msg.sender],
            "insufficient_fund"
        );

        // create new pool for tokenA and tokenB
        bytes memory bytecode = abi.encodePacked(
            type(AMM).creationCode,
            abi.encode(tokenA, address(this))
        );
        bytes32 salt = keccak256(abi.encodePacked(tokenA, address(this)));
        assembly {
            poolAddress := create2(0, add(bytecode, 32), mload(bytecode), salt)
            if iszero(extcodesize(poolAddress)) {
                revert(0, 0)
            }
        }
        // register the pool
        tokensToPool[tokenA][address(this)] = poolAddress;
        tokensToPool[address(this)][tokenA] = poolAddress;
        pools.push(poolAddress);

        //update vUSDC balance and tokenA
        ERC20(tokenA).approve(poolAddress, amountA);
        ERC20.approve(poolAddress, amountBWithLeverage);
        leverageBalances[msg.sender] -= amountBWithLeverage;
        balances[msg.sender][tokenA] -= amountA;

        AMM(poolAddress).addLiquidity(
            tokenA,
            address(this),
            amountA,
            amountBWithLeverage
        );

        emit PoolCreated(tokenA, address(this), poolAddress, pools.length);
    }

    function getTokenBGivenTokenALeverage(
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 leverage
    ) public view returns (address poolAdd, uint256 amountB) {
        require(leverage <= 10 && leverage >= 1, "max_leverage_reached");
        require(tokenA != tokenB, "tokens_cannot_be_the_same");
        require(
            tokenA != address(0) && tokenB != address(0),
            "address_invalid"
        );
        require(amountA > 0, "invalid_amount");
        uint256 leverageAmountA = amountA * leverage;
        require(
            leverageAmountA <= leverageBalances[msg.sender],
            "insufficient fund"
        );
        poolAdd = tokensToPool[tokenA][tokenB];
        require(poolAdd != address(0), "pool_not_initialized");
        (, , , , uint256 balanceA, uint256 balanceB) = AMM(poolAdd)
            .getPoolDetails();
        require(balanceA > 0 && balanceB > 0, "pool_not_active");

        amountB = AMM(poolAdd).getSwapTokenBEstimateGivenTokenA(
            tokenA,
            leverageAmountA
        );
        return (poolAdd, amountB);
    }

    function swapTokenGivenVUSDC(address tokenA, uint256 amountA)
        external
        returns (uint256 amountB)
    {
        require(tokenA != address(0), "invalid_address");
        require(amountA > 0, "invalid_amount");
        address poolAdd = tokensToPool[tokenA][address(this)];
        require(poolAdd != address(0), "pool_does_not_exist");
        //swap tokens from VUSD to tokenA
        amountB = AMM(poolAdd).swapTokenA(address(this), amountA);
        require(amountB > 0, "transfer_failed");
    }

    function getRemainingVUSDC() external view returns (uint256) {
        return leverageBalances[msg.sender];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

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
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
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
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
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