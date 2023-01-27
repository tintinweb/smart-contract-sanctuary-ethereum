// SPDX-License-Identifier: MIT

pragma solidity =0.8.17;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

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

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

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
        return 9;
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
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

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

interface IDexFactory {
    function createPair(address tokenA, address tokenB) external returns (address _pair);
}

interface IDexRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract SpikeInu is ERC20, Ownable {
    using SafeMath for uint256;

    bool public swapBackEnabled;
    bool private _swapping;

    uint256 private _swapTokensAtAmnt;
    uint256 public maxWalletAmnt;
    
    uint256 public buyFee;
    uint256 public sellFee;

    uint256 private _tokensForFees;

    address payable private _feeAddress;
    address private _pair;

    IDexRouter private _router;

    mapping (address => bool) private _excludedFees;

    mapping (address => bool) private _automatedMarketMakerPairs;

    constructor() ERC20("Spike Inu", "SPIKE") payable {
        uint256 tSupply = 1000000000 ether;
        maxWalletAmnt = tSupply * 2 / 100;
        _swapTokensAtAmnt = tSupply * 5 / 10000;
        buyFee = 5;
        sellFee = 5;
        _feeAddress = payable(owner());
        _router = IDexRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(_router), type(uint).max);
        _pair = IDexFactory(_router.factory()).createPair(address(this), _router.WETH());
        _approve(address(this), address(_pair), type(uint).max);
        IERC20(_pair).approve(address(_router), type(uint).max);
        _automatedMarketMakerPairs[address(_pair)] = true;
        _excludedFees[owner()] = true;
        _excludedFees[address(this)] = true;
        _excludedFees[address(0xdead)] = true;
        _mint(owner(), tSupply * 10 / 100);
        _mint(address(this), tSupply * 90 / 100);
        swapBackEnabled = true;
    }

    receive() external payable {}
    fallback() external payable {}

    function launch() external onlyOwner {
        _router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
    }

    function updateSwapBackEnabled(bool isEnabled) external onlyOwner {
        swapBackEnabled = isEnabled;
    }
    
    function updateSwapTokensAtAmnt(uint256 newAmnt) external onlyOwner {
  	    _swapTokensAtAmnt = newAmnt;
  	}
    
    function updateMaxWalletAmnt(uint256 newAmnt) external onlyOwner {
  	    maxWalletAmnt = newAmnt;
  	}

    function updateFeeAddress(address feeAddress) external onlyOwner {
        require(feeAddress != address(0), "address cannot be 0");
        _feeAddress = payable(feeAddress);
        _excludedFees[_feeAddress] = true;
    }

    function updateBuyFee(uint256 _fee) external onlyOwner {
        require(_fee <= 12);
        buyFee = _fee;
    }

    function updateSellFee(uint256 _fee) external onlyOwner {
        require(_fee <= 12);
        sellFee = _fee;
    }

    function excludeFromFees(address account, bool excluded) external onlyOwner {
        _excludedFees[account] = excluded;
    }

    function rescueStuckETH() external onlyOwner {
        bool success;
        (success,) = address(_msgSender()).call{value: address(this).balance}("");
    }

    function rescueStuckTokens(address tokenAddress) external onlyOwner {
        require(tokenAddress != address(this), "Cannot withdraw self");
        require(IERC20(tokenAddress).balanceOf(address(this)) > 0, "No tokens");
        uint amount = IERC20(tokenAddress).balanceOf(address(this));
        IERC20(tokenAddress).transfer(_msgSender(), amount);
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "ERC20: Transfer from the address(0) address");
        require(to != address(0), "ERC20: Transfer to the address(0) address");
        require(amount > 0, "ERC20: Transfer amount must be greater than address(0)");
        if(_excludedFees[from] || _excludedFees[to]) {
            super._transfer(from, to, amount);
            return;
        }
        uint256 fees = 0;
        if (_automatedMarketMakerPairs[to] && sellFee > 0) { // sell
            fees = amount * sellFee / 100;
            _tokensForFees += fees * sellFee / sellFee;
        } else if(_automatedMarketMakerPairs[from] && buyFee > 0) { // buy
            require((balanceOf(to) + amount) <= maxWalletAmnt);
        	fees = amount * buyFee / 100;
            _tokensForFees += fees * buyFee / buyFee;
        }
        uint256 contractBalance = balanceOf(address(this));
        bool canSwap = contractBalance >= _swapTokensAtAmnt;
        if(canSwap && swapBackEnabled && !_swapping && _automatedMarketMakerPairs[to]) {
            _swapping = true;
            _swapBackETH(contractBalance);
            _swapping = false;
        }
        if(fees > 0) super._transfer(from, address(this), fees);
        amount -= fees;
        super._transfer(from, to, amount);
    }

    function _swapBackETH(uint256 contractBalance) internal {
        bool success;
        if(_tokensForFees == 0) return;
        if(contractBalance > _swapTokensAtAmnt * 5) contractBalance = _swapTokensAtAmnt * 5;
        _swapTokensForETH(contractBalance);
        _tokensForFees = 0;
        uint256 ethBalance = address(this).balance;
        if(ethBalance > 0) (success, ) = _feeAddress.call{value: ethBalance}("");
    }

    function _swapTokensForETH(uint256 tokenAmount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _router.WETH();
        _approve(address(this), address(_router), tokenAmount);
        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount, 
            0,
            path, 
            address(this), 
            block.timestamp
        );
    }
}