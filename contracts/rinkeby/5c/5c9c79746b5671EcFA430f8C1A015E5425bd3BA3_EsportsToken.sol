// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../access/Operatable.sol";
import "../interfaces/IUniswapAmm.sol";
import "./AntiBotHelper.sol";
import "./FeeHelper.sol";

/**
 * @dev Governace token in Metaverse game project
 *
 */
contract EsportsToken is AntiBotHelper, FeeHelper, ERC20, Operatable {
    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint256 constant MAX_SUPPLY = 10000000000 ether;

    address private _marketingWallet;
    address private _marketingToken;
    bool private _inSwap;
    bool private _swapEnabled = true;
    uint256 private _thresholdAmount = 1000 ether; // Threshold amount of accumlated tax until swap to marketing token
    IUniswapV2Router02 private _swapRouter;

    event SwapToMarketingTokenSucceed(
        address indexed marketingToken,
        address indexed to,
        uint256 amountIn,
        uint256 amountOut
    );
    event SwapToMarketingTokenFailed(
        address indexed marketingToken,
        address indexed to,
        uint256 amount
    );

    modifier lockTheSwap() {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    constructor(string memory name_, string memory symbol_)
        ERC20(name_, symbol_)
    {
        _marketingWallet = _msgSender();
    }

    function mint(uint256 amount) external onlyOperator {
        _mint(_msgSender(), amount);
    }

    function mint(address account, uint256 amount) external onlyOperator {
        _mint(account, amount);
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
    function _mint(address account, uint256 amount) internal virtual override {
        super._mint(account, amount);
        _afterTokenTransfer(address(0), account, amount);
    }

    function burn(uint256 amount) external {
        _burn(_msgSender(), amount);
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
    function _burn(address account, uint256 amount) internal virtual override {
        super._burn(account, amount);
        _afterTokenTransfer(account, address(0), amount);
    }

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
    ) internal virtual {
        require(!_blacklist[from] && !_blacklist[to], "blacklisted account");

        // Check max tx limit
        require(
            _excludedFromTxLimit[from] ||
                _excludedFromTxLimit[to] ||
                amount <= _txLimit,
            "Tx amount limited"
        );

        // Check max wallet amount limit
        require(
            _excludedFromHoldLimit[to] || balanceOf(to) <= _holdLimit,
            "Receiver hold limited"
        );

        require(totalSupply() <= MAX_SUPPLY, "Exceeds MAX_SUPPLY");
    }

    function setSwapRouter(address newSwapRouter) external onlyOwner {
        require(newSwapRouter != address(0), "Invalid swap router");

        _swapRouter = IUniswapV2Router02(newSwapRouter);
    }

    function viewSwapRouter() external view returns (address) {
        return address(_swapRouter);
    }

    function enableSwap(bool flag) external onlyOwner {
        _swapEnabled = flag;
    }

    function swapEnabled() external view returns (bool) {
        return _swapEnabled;
    }

    function setMarketingWallet(address wallet) external onlyOwner {
        require(wallet != address(0), "Invalid marketing wallet");
        _marketingWallet = wallet;
    }

    function viewMarketingWallet() external view returns (address) {
        return _marketingWallet;
    }

    function setMarketingToken(address token) external onlyOwner {
        _marketingToken = token;
    }

    function viewMarketingToken() external view returns (address) {
        return _marketingToken;
    }

    /**
     * @dev Set threshold amount to be swapped to the marketing token
     * Too small value will cause sell tx happens in every tx
     */
    function setThresholdAmount(uint256 amount) external onlyOwner {
        require(amount > 0, "Invalid threshold");
        _thresholdAmount = amount;
    }

    function viewThresholdAmount() external view returns (uint256) {
        return _thresholdAmount;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(amount > 0, "Zero transfer");

        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is uniswap pair.
        uint256 contractTokenBalance = balanceOf(address(this));

        // indicates if fee should be deducted from transfer
        (bool feeApplied, TX_CASE txCase) = shouldFeeApplied(from, to);

        // Swap and liquify also triggered when the tx needs to have fee
        if (
            !_inSwap &&
            feeApplied &&
            _swapEnabled &&
            contractTokenBalance >= _thresholdAmount
        ) {
            swapToMarketingToken(_thresholdAmount);
        }

        //transfer amount, it will take tax, burn fee
        _tokenTransfer(from, to, amount, feeApplied, txCase);
    }

    // this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool feeApplied,
        TX_CASE txCase
    ) private {
        if (feeApplied) {
            uint16 marketingFee = _tokenFees[txCase].marketingFee;
            uint16 burnFee = _tokenFees[txCase].burnFee;

            uint256 burnFeeAmount = (amount * burnFee) / 10000;
            uint256 marketingFeeAmount = (amount * marketingFee) / 10000;

            if (burnFeeAmount > 0) {
                _burn(sender, burnFeeAmount);
                amount -= burnFeeAmount;
            }
            if (marketingFeeAmount > 0) {
                super._transfer(sender, address(this), marketingFeeAmount);
                _afterTokenTransfer(sender, address(this), marketingFeeAmount);
                amount -= marketingFeeAmount;
            }
        }
        if (amount > 0) {
            super._transfer(sender, recipient, amount);
            _afterTokenTransfer(sender, recipient, amount);
        }
    }

    /**
     * @dev Swap token accumlated in this contract to the marketing token
     * 
     * According to the marketing token

     * - when marketing token is ETH, swapToETH function is called
     * - when marketing token is another token, swapToToken is called

     */
    function swapToMarketingToken(uint256 amount) private lockTheSwap {
        if (isETH(_marketingToken)) {
            swapToETH(amount, payable(_marketingWallet));
        } else {
            swapToToken(_marketingToken, amount, _marketingWallet);
        }
    }

    function swapToToken(
        address token,
        uint256 amount,
        address to
    ) private {
        // generate the uniswap pair path of token -> busd
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = token;

        _approve(address(this), address(_swapRouter), amount);

        // capture the target address's current BNB balance.
        uint256 balanceBefore = IERC20(_marketingToken).balanceOf(to);

        // make the swap
        try
            _swapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amount,
                0, // accept any amount of tokens
                path,
                to,
                block.timestamp + 300
            )
        {
            uint256 amountOut = IERC20(_marketingToken).balanceOf(to) -
                balanceBefore;
            emit SwapToMarketingTokenSucceed(
                _marketingToken,
                to,
                amount,
                amountOut
            );
        } catch (
            bytes memory /* lowLevelData */
        ) {
            emit SwapToMarketingTokenFailed(_marketingToken, to, amount);
        }
    }

    function swapToETH(uint256 amount, address payable to) private {
        // generate the uniswap pair path of token -> busd
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _swapRouter.WETH();

        _approve(address(this), address(_swapRouter), amount);

        // capture the target address's current BNB balance.
        uint256 balanceBefore = to.balance;

        // make the swap
        try
            _swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
                amount,
                0, // accept any amount of BNB
                path,
                to,
                block.timestamp + 300
            )
        {
            // how much BNB did we just swap into?
            uint256 amountOut = to.balance - balanceBefore;
            emit SwapToMarketingTokenSucceed(
                _marketingToken,
                to,
                amount,
                amountOut
            );
        } catch (
            bytes memory /* lowLevelData */
        ) {
            // how much BNB did we just swap into?
            emit SwapToMarketingTokenFailed(_marketingToken, to, amount);
        }
    }

    function isETH(address token) internal pure returns (bool) {
        return (token == address(0) || token == ETH_ADDRESS);
    }
}

// SPDX-License-Identifier: MIT

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
    constructor () {
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
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
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

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
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
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
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
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
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an operator) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the operator account will be the one that deploys the contract. This
 * can later be changed with {transferOperator}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOperator`, which can be applied to your functions to restrict their use to
 * the operator.
  * 
  * It is recommended to use with Operator.sol to set permissions per specific functions
 */
abstract contract Operatable is Context {
    address private _operator;

    event OperatorTransferred(address indexed previousOperator, address indexed newOperator);

    /**
     * @dev Initializes the contract setting the deployer as the initial operator.
     */
    constructor() {
        _transferOperator(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the operator.
     */
    modifier onlyOperator() {
        _checkOperator();
        _;
    }

    /**
     * @dev Returns the address of the current operator.
     */
    function operator() public view virtual returns (address) {
        return _operator;
    }

    /**
     * @dev Throws if the sender is not the operator.
     */
    function _checkOperator() internal view virtual {
        require(operator() == _msgSender(), "Operatable: caller is not the operator");
    }

    /**
     * @dev Leaves the contract without operator. It will not be possible to call
     * `onlyOperator` functions anymore. Can only be called by the current operator.
     *
     * NOTE: Renouncing operator will leave the contract without an operator,
     * thereby removing any functionality that is only available to the operator.
     */
    function renounceOperator() public virtual onlyOperator {
        _transferOperator(address(0));
    }

    /**
     * @dev Transfers operator of the contract to a new account (`newOperator`).
     * Can only be called by the current operator.
     */
    function transferOperator(address newOperator) public virtual onlyOperator {
        require(newOperator != address(0), "Ownable: new operator is the zero address");
        _transferOperator(newOperator);
    }

    /**
     * @dev Transfers operator of the contract to a new account (`newOperator`).
     * Internal function without access restriction.
     */
    function _transferOperator(address newOperator) internal virtual {
        address oldOperator = _operator;
        _operator = newOperator;
        emit OperatorTransferred(oldOperator, newOperator);
    }
}

// SPDX-License-Identifier: MIT

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol

pragma solidity ^0.8.4;

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @notice Anti-Bot Helper
 * Blacklis feature
 * Max TX Amount feature
 * Max Wallet Amount feature
 */
contract AntiBotHelper is Ownable {
    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address private constant ZERO = address(0);

    uint256 public constant MAX_TX_AMOUNT_MIN_LIMIT = 100 ether;
    uint256 public constant MAX_WALLET_AMOUNT_MIN_LIMIT = 1000 ether;

    mapping(address => bool) internal _excludedFromTxLimit;
    mapping(address => bool) internal _excludedFromHoldLimit;
    mapping(address => bool) internal _blacklist;

    uint256 internal _txLimit = 100000 ether;
    uint256 internal _holdLimit = 10000000 ether;

    constructor() {
        _excludedFromTxLimit[_msgSender()] = true;
        _excludedFromTxLimit[DEAD] = true;
        _excludedFromTxLimit[ZERO] = true;
        _excludedFromTxLimit[address(this)] = true;

        _excludedFromHoldLimit[_msgSender()] = true;
        _excludedFromHoldLimit[DEAD] = true;
        _excludedFromHoldLimit[ZERO] = true;
        _excludedFromHoldLimit[address(this)] = true;
    }

    /**
     * @notice Blacklist the account
     * @dev Only callable by owner
     */
    function blacklistAccount(address account, bool flag) external onlyOwner {
        _blacklist[account] = flag;
    }

    /**
     * @notice Check if the account is included in black list
     * @param account: the account to be checked
     */
    function blacklisted(address account) external view returns (bool) {
        return _blacklist[account];
    }

    /**
     * @notice Exclude / Include the account from max tx limit
     * @dev Only callable by owner
     */
    function excludeFromTxLimit(address account, bool flag) external onlyOwner {
        _excludedFromTxLimit[account] = flag;
    }

    /**
     * @notice Check if the account is excluded from max tx limit
     * @param account: the account to be checked
     */
    function excludedFromTxLimit(address account) external view returns (bool) {
        return _excludedFromTxLimit[account];
    }

    /**
     * @notice Exclude / Include the account from max wallet limit
     * @dev Only callable by owner
     */
    function excludeFromHoldLimit(address account, bool flag)
        external
        onlyOwner
    {
        _excludedFromHoldLimit[account] = flag;
    }

    /**
     * @notice Check if the account is excluded from max wallet limit
     * @param account: the account to be checked
     */
    function excludedFromHoldLimit(address account)
        external
        view
        returns (bool)
    {
        return _excludedFromHoldLimit[account];
    }

    /**
     * @notice Set anti whales limit configuration
     * @param txLimit: max amount of token in a transaction
     * @param holdLimit: max amount of token can be kept in a wallet
     * @dev Only callable by owner
     */
    function setAntiWhalesConfiguration(uint256 txLimit, uint256 holdLimit)
        external
        onlyOwner
    {
        require(txLimit >= MAX_TX_AMOUNT_MIN_LIMIT, "Max tx amount too small");
        require(
            holdLimit >= MAX_WALLET_AMOUNT_MIN_LIMIT,
            "Max wallet amount too small"
        );
        _txLimit = txLimit;
        _holdLimit = holdLimit;
    }

    function viewHoldLimit() external view returns (uint256) {
        return _holdLimit;
    }

    function viewTxLimit() external view returns (uint256) {
        return _txLimit;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @notice Tax Helper
 * Marketing fee
 * Burn fee
 * Fee in buy/sell/transfer separately
 */
contract FeeHelper is Ownable {
    enum TX_CASE {
        TRANSFER,
        BUY,
        SELL
    }

    struct TokenFee {
        uint16 marketingFee;
        uint16 burnFee;
    }

    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address private constant ZERO = address(0);

    mapping(TX_CASE => TokenFee) internal _tokenFees;
    mapping(address => bool) internal _excludedFromTax;
    mapping(address => bool) internal _isSelfPair;

    constructor() {
        _excludedFromTax[_msgSender()] = true;
        _excludedFromTax[DEAD] = true;
        _excludedFromTax[ZERO] = true;
        _excludedFromTax[address(this)] = true;

        _tokenFees[TX_CASE.TRANSFER].marketingFee = 0;
        _tokenFees[TX_CASE.TRANSFER].burnFee = 0;

        _tokenFees[TX_CASE.BUY].marketingFee = 800;
        _tokenFees[TX_CASE.BUY].burnFee = 200;

        _tokenFees[TX_CASE.SELL].marketingFee = 800;
        _tokenFees[TX_CASE.SELL].burnFee = 200;
    }

    /**
     * @notice Update fee in the token
     * @param feeCase: which case the fee is for: transfer / buy / sell
     * @param marketingFee: fee percent for marketing
     * @param burnFee: fee percent for burning
     */
    function setFee(
        TX_CASE feeCase,
        uint16 marketingFee,
        uint16 burnFee
    ) external onlyOwner {
        require(marketingFee + burnFee <= 10000, "Overflow");
        _tokenFees[feeCase].marketingFee = marketingFee;
        _tokenFees[feeCase].burnFee = burnFee;
    }

    /**
     * @notice Exclude / Include the account from fee
     * @dev Only callable by owner
     */
    function excludeFromTax(address account, bool flag) external onlyOwner {
        _excludedFromTax[account] = flag;
    }

    /**
     * @notice Check if the account is excluded from the fees
     * @param account: the account to be checked
     */
    function excludedFromTax(address account) external view returns (bool) {
        return _excludedFromTax[account];
    }

    function viewFees(TX_CASE feeCase) external view returns (TokenFee memory) {
        return _tokenFees[feeCase];
    }

    /**
     * @notice Check if fee should be applied
     */
    function shouldFeeApplied(address from, address to)
        internal
        view
        returns (bool feeApplied, TX_CASE txCase)
    {
        // Sender or receiver is excluded from fee
        if (_excludedFromTax[from] || _excludedFromTax[to]) {
            feeApplied = false;
            txCase = TX_CASE.TRANSFER; // second param is default one becuase it would not be used in this case
        }
        // Buying tokens
        else if (_isSelfPair[from]) {
            TokenFee memory buyFee = _tokenFees[TX_CASE.BUY];
            feeApplied = (buyFee.marketingFee + buyFee.burnFee) > 0;
            txCase = TX_CASE.BUY;
        }
        // Selling tokens
        else if (_isSelfPair[to]) {
            TokenFee memory sellFee = _tokenFees[TX_CASE.SELL];
            feeApplied = (sellFee.marketingFee + sellFee.burnFee) > 0;
            txCase = TX_CASE.SELL;
        }
        // Transferring tokens
        else {
            TokenFee memory transferFee = _tokenFees[TX_CASE.TRANSFER];
            feeApplied = (transferFee.marketingFee + transferFee.burnFee) > 0;
            txCase = TX_CASE.TRANSFER;
        }
    }

    /**
     * @notice Include / Exclude lp address in self pairs
     */
    function includeInSelfPair(address lpAddress, bool flag)
        external
        onlyOwner
    {
        _isSelfPair[lpAddress] = flag;
    }

    /**
     * @notice Check if the lp address is self pair
     */
    function isSelfPair(address lpAddress) external view returns (bool) {
        return _isSelfPair[lpAddress];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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