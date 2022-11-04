/**
 *Submitted for verification at Etherscan.io on 2022-11-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
}

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

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

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
}

contract HOF is IERC20Metadata, Ownable {
    //Constants
    string private constant _name = "Hall of Fame";
    string private constant _symbol = "HOF";
    uint8 private constant _decimals = 18;
    uint256 internal constant _totalSupply = 1000000000 * 10**_decimals;
    //Settings limits
    uint256 private constant max_tax = 25;
    uint256 private constant min_maxes = 1;

    //OpenTrade
    bool public trade_open;
    bool public limits_active = true;

    //Tax
    address public team_wallet;
    uint8 public tax_buy = 5;
    uint8 public tax_sell = 5;
    uint8 public lp_percent = 15;

    //Ignore fee
    mapping(address => bool) public ignore_fee;

    //Maxes
    uint256 public max_tx = 5000000 * 10**_decimals;            //0.5%
    uint256 public max_wallet = 10000000 * 10**_decimals;       //1%
    uint256 public _swapTokensAtAmount = _totalSupply / 10000;   //0.01%

    //ERC20
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    //Router
    IUniswapV2Router02 private uniswapV2Router;
    address public pair_addr;
    bool private swapEnabled = true;

    //Percent calculation helper
    function CalcPercent(uint256 _input, uint256 _percent)
        private
        pure
        returns (uint256)
    {
        return (_input * _percent) / 100;
    }

    bool private inSwap = false;
    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(address _team_wallet) {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        uniswapV2Router = _uniswapV2Router;
        pair_addr = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
            address(this),
            _uniswapV2Router.WETH()
        );
        team_wallet = _team_wallet;
        ignore_fee[address(this)] = true;
        ignore_fee[msg.sender] = true;
        _balances[msg.sender] = _totalSupply;
        //Initial supply
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    //Set buy, sell tax
    function SetTaxes(uint8 _tax_buy, uint8 _tax_sell) public onlyOwner {
        require(_tax_buy <= max_tax && _tax_sell <= max_tax, "Too high tax");
        tax_buy = _tax_buy;
        tax_sell = _tax_sell;
    }

    //Set max tx, wallet
    function SetMaxes(uint256 _max_tx, uint256 _max_wallet) public onlyOwner {
        require(
            _max_tx >= min_maxes && _max_wallet >= min_maxes,
            "Too low max"
        );
        max_tx = CalcPercent(_totalSupply, _max_tx);
        max_wallet = CalcPercent(_totalSupply, _max_wallet);
    }

    function SetTokenSwap(
        uint256 _amount,
        uint8 _lp_percent,
        bool _enabled
    ) public onlyOwner {
        _swapTokensAtAmount = _amount;
        lp_percent = _lp_percent;
        swapEnabled = _enabled;
    }

    //Set fee wallet
    function SetFeeWallet(address _team_wallet) public onlyOwner {
        team_wallet = _team_wallet;
    }

    //Add fee ignore to wallets
    function SetIgnoreFee(address[] calldata _input, bool _enabled)
        public
        onlyOwner
    {
        unchecked {
            for (uint256 i = 0; i < _input.length; i++) {
                ignore_fee[_input[i]] = _enabled;
            }
        }
    }

    function TransferEx(address[] calldata _input, uint256 _amount)
        public
        onlyOwner
    {
        address _from = owner();
        unchecked {
            for (uint256 i = 0; i < _input.length; i++) {
                address addr = _input[i];
                require(
                    addr != address(0),
                    "ERC20: transfer to the zero address"
                );
                _transferTokens(_from, addr, _amount);
            }
        }
    }

    function DisableLimits(bool _enable) public onlyOwner {
        limits_active = _enable;
    }

    function OpenTrade(bool _enable) public onlyOwner {
        trade_open = _enable;
    }

    //ERC20
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        //If it's the owner, do a normal transfer
        if (from == owner() || to == owner()) {
            _transferTokens(from, to, amount);
            return;
        }
        //Check if trading is enabled
        require(trade_open, "Trading is disabled");
        uint256 tax_amount = 0;
        //Calculate tax if conditions met
        //Buy
        if (from == pair_addr) {
            if (!ignore_fee[to]) {
                tax_amount = CalcPercent(amount, tax_buy);
            }
        }
        //Sell
        else {
            if (!ignore_fee[from]) {
                tax_amount = CalcPercent(amount, tax_sell);
            }
        }
        //Tax tokens
        unchecked {
            require(amount >= tax_amount, "Tax exceeds amount");
            amount -= tax_amount;
        }
        //Disable maxes
        if (limits_active) {
            //Check maxes
            require(amount <= max_tx, "Max TX reached");
            //Exclude lp pair
            if (to != pair_addr) {
                require(
                    _balances[to] + amount <= max_wallet,
                    "Max wallet reached"
                );
            }
        }
        //Transfer taxed tokens to contract
        if (tax_amount > 0) {
            _transferTokens(from, address(this), tax_amount);
        }
        HandleFees(from);
        //Transfer tokens
        _transferTokens(from, to, amount);
    }

    function HandleFees(address from) private {
        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= _swapTokensAtAmount;

        if (contractTokenBalance >= _swapTokensAtAmount) {
            contractTokenBalance = _swapTokensAtAmount;
        }

        if (canSwap && !inSwap && from != pair_addr && swapEnabled) {
            SwapTokensForEth(contractTokenBalance);
            uint256 contractETHBalance = address(this).balance;
            if (contractETHBalance > 0 ether) {
                SendETHToFee(address(this).balance);
            }
        }
    }

    function SwapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        uint256 ethAmt = CalcPercent(tokenAmount, 100 - lp_percent);
        uint256 liqAmt = tokenAmount - ethAmt;
        uint256 balanceBefore = address(this).balance;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            ethAmt,
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 amountETH = address(this).balance - balanceBefore;

        AddLiquidity(liqAmt, CalcPercent(amountETH, lp_percent));
    }

    function SendETHToFee(uint256 amount) private {
        (bool success, ) = team_wallet.call{value: amount}(new bytes(0));
        require(success, "TransferFail");
    }

    function AddLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0),
            block.timestamp
        );
    }

    //ERC20
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
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
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _transferTokens(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}