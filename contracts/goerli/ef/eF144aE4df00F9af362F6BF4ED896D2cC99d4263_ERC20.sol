/**
 *Submitted for verification at Etherscan.io on 2022-10-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Swap(address indexed from, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IUniswapV2Router {
  function getAmountsOut(uint256 amountIn, address[] memory path)
    external
    view
    returns (uint256[] memory amounts);
  
  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
    ) external;

  function WETH() external pure returns (address);
}

interface IUniswapV2Pair {
  function token0() external view returns (address);
  function token1() external view returns (address);
  function swap(
    uint256 amount0Out,
    uint256 amount1Out,
    address to,
    bytes calldata data
  ) external;
}

interface IUniswapV2Factory {
  function getPair(address token0, address token1) external returns (address);
}


interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

contract ERC20 is IERC20, IERC20Metadata {

    address private constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    address private _owner;

    address payable development;
    address payable marketing;

    constructor(string memory name_, string memory symbol_, uint256 totalSupply_, uint8 decimals_, address payable development_, address payable marketing_) {
        _name = name_;
        _symbol = symbol_;
        _totalSupply = totalSupply_;
        _owner = msg.sender;
        _decimals = decimals_;
        development = development_;
        marketing = marketing_;
        _balances[_owner] = totalSupply_;
    }

    receive() external payable {
        // allow receive ETH
    }

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

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = msg.sender;
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _swap(uint256 _amountIn) internal virtual {
        
        uint256 _toSwap = _amountIn / 2;

        uint256 _allowance_ = _allowances[address(this)][UNISWAP_V2_ROUTER];

        _approve(address(this), UNISWAP_V2_ROUTER, _allowance_ + (_toSwap * 2));

        uint256 contract_balance = _balances[address(this)];

        _balances[address(this)] = contract_balance + _toSwap;

        address[] memory path;

        path = new address[](2);

        path[0] = address(this);
        path[1] = IUniswapV2Router(UNISWAP_V2_ROUTER).WETH();

        uint256 amountOut = getAmountOutMin(_toSwap);

        IUniswapV2Router(UNISWAP_V2_ROUTER).swapExactTokensForETHSupportingFeeOnTransferTokens(_toSwap, 0, path, address(this), block.timestamp + 360);

        emit Swap(address(this), _toSwap);

        _split(amountOut);

        _taxes(_toSwap);

    }

    function getAmountOutMin(uint256 _amountIn) internal virtual returns (uint256) {

        address[] memory path;

        path = new address[](2);
        path[0] = address(this);
        path[1] = IUniswapV2Router(UNISWAP_V2_ROUTER).WETH();

        uint256[] memory amountOutMins = IUniswapV2Router(UNISWAP_V2_ROUTER).getAmountsOut(_amountIn, path);

        return amountOutMins[path.length -1];
        
    }

    function _taxes(uint256 amount_) internal virtual {
        unchecked {
            _balances[development] += (40 * amount_) / 100;
            _balances[marketing] += (60 * amount_) / 100;
        }
    }

    function _split(uint256 amount_) internal virtual {
        require(development.send((40 * amount_) / 100), "Transfer failed");
        require(marketing.send((60 * amount_) / 100), "Transfer failed");
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

        uint256 tax = (10 * amount) / 100;

        uint256 net = 0;

        if (from == _owner || from == address(this)) {
            net = amount;
        }
        else {
            net = amount - tax;
            _swap(tax);
        }

        unchecked {
            _balances[from] = fromBalance - amount;
            _balances[to] += net;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {

        require(account != address(0), "ERC20: mint to the zero address");
        require(msg.sender == _owner, "Must be moderator");
        
        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        require(msg.sender == _owner, "Must be moderator");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            _totalSupply -= amount;
        }

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