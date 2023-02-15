/**
 *Submitted for verification at Etherscan.io on 2023-02-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
   
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
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
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
            unchecked {
                _approve(sender, _msgSender(), currentAllowance - amount);
            }
        }

        _transfer(sender, recipient, amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

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

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
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

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract AlphaIntelligence is ERC20, Ownable {
    uint256 public  wilsonBuyFee  = 1;
    uint256 public  wilsonSellFee = 1;

    uint256 public  marketingBuyFee  = 2;
    uint256 public  marketingSellFee = 2;

    uint256 public treasuryBuyFee  = 2;
    uint256 public treasurySellFee = 2;

    uint256 private _totalBuyFee  = 5;
    uint256 private _totalSellFee = 5;

    address public wilsonWallet = 0x882A35de9b236EDa98A58B6602603cF71cC7Ae0c;
    address public marketingWallet = 0xAC7eA75c0f4Fd54D2DBc4f3B65332613E8Aba6Ab;
    address public treasuryWallet = 0xa981c08812e2Dd6421147895B2803A46e8bdf48F;

    IUniswapV2Router02 public uniswapV2Router;
    address public  uniswapV2Pair;
    
    address private DEAD = 0x000000000000000000000000000000000000dEaD;

    uint8 constant private _decimals = 18;
    uint256 public swapTokensAtAmount;
    bool    public swapEnabled = true;
    bool    public swapWithLimit;
    bool    private swapping;
    bool    public tradingEnabled = false;

    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) public automatedMarketMakerPairs;

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event UpdateBuyFees(uint256 treasuryBuyFee, uint256 marketingBuyFee, uint256 wilsonBuyFee);
    event UpdateSellFees(uint256 treasurySellFee, uint256 marketingSellFee, uint256 wilsonSellFee);
    event MarketingWalletUpdated(address indexed newMarketingWallet);
    event WilsonWalletUpdated(address indexed newWilsonWallet);
    event TreasuryWalletUpdated(address indexed newTreasuryWallet);
    event TradingEnabled(bool enabled);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 bnbReceived, uint256 tokensIntoLiqudity);
    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);

    constructor () ERC20("Alpha Intelligence", "$AI") 
    {   
                                                               
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); //PCS Router 0x10ED43C718714eb63d5aA57B78B54704E256024E
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair   = _uniswapV2Pair;

        _approve(address(this), address(uniswapV2Router), type(uint256).max);

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[DEAD] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[marketingWallet] = true;
        _isExcludedFromFees[treasuryWallet] = true;
        _isExcludedFromFees[wilsonWallet] = true;
        
        _mint(owner(), 1e8 * (10 ** 18));
        swapTokensAtAmount = totalSupply() / 5000;
    }

    receive() external payable {

  	}

    function Claim(address token) external onlyOwner {
        if (token == address(0x0)) {
            payable(msg.sender).transfer(address(this).balance);
            return;
        }
        IERC20 ERC20token = IERC20(token);
        uint256 balance = ERC20token.balanceOf(address(this));
        ERC20token.transfer(msg.sender, balance);
    }

    function updateUniswapV2Router(address newAddress) external onlyOwner {
        require(newAddress != address(uniswapV2Router), "The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
        address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Pair = _uniswapV2Pair;
    }
 
    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

   
    function excludeFromFees(address account) external onlyOwner {
        require(_isExcludedFromFees[account] != true, "Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = true;

        emit ExcludeFromFees(account, true);
    }

    function includeInFees(address account) external onlyOwner {
        require(_isExcludedFromFees[account] != false, "Account is already the value of 'included'");
        _isExcludedFromFees[account] = false;

        emit ExcludeFromFees(account, false);
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function updateBuyFees(uint256 _treasuryBuyFee, uint256 _wilsonBuyFee, uint256 _marketingBuyFee) external onlyOwner {
        require(
            _treasuryBuyFee + _wilsonBuyFee +  _marketingBuyFee <= 9,
            "Fees must be less than 10%"
        );
        treasuryBuyFee = _treasuryBuyFee;
        marketingBuyFee = _marketingBuyFee;
        wilsonBuyFee = _wilsonBuyFee;

        _totalBuyFee   = treasuryBuyFee + marketingBuyFee + wilsonBuyFee;
        emit UpdateBuyFees(_treasuryBuyFee, _wilsonBuyFee, _marketingBuyFee);
    }

    function updateSellFees(uint256 _treasurySellFee, uint256 _wilsonSellFee, uint256 _marketingSellFee) external onlyOwner {
        require(
            _treasurySellFee + _wilsonSellFee + _marketingSellFee <= 9,
            "Fees must be less than 10%"
        );
        treasurySellFee = _treasurySellFee;
        wilsonSellFee = _wilsonSellFee;
        marketingSellFee = _marketingSellFee;

        _totalSellFee   = treasurySellFee + wilsonSellFee + marketingSellFee;
        emit UpdateSellFees(_treasurySellFee, _wilsonSellFee, _marketingSellFee);
    }


    function changeWilsonWallet(address _wilsonWallet) external onlyOwner {
        require(_wilsonWallet != address(0), "Operation wallet cannot be zero address");
        wilsonWallet = _wilsonWallet;
        emit WilsonWalletUpdated(_wilsonWallet);
    }
    

    function changeMarketingWallet(address _marketingWallet) external onlyOwner {
        require(_marketingWallet != address(0), "Reward wallet cannot be zero address");
        marketingWallet = _marketingWallet;
        emit MarketingWalletUpdated(_marketingWallet);
    }

     function changeTreasuryWallet(address _treasuryWallet) external onlyOwner {
        require(_treasuryWallet != address(0), "Reward wallet cannot be zero address");
        treasuryWallet = _treasuryWallet;
        emit TreasuryWalletUpdated(_treasuryWallet);
    }

   
    function enableTrading() external onlyOwner {
        require(!tradingEnabled, "Trading is already enabled");
        require(balanceOf(uniswapV2Pair) > 0, "Liquidity must be added first");
        tradingEnabled = true;
        emit TradingEnabled(true);
    }


    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal  override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
       
        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (!_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            require(tradingEnabled == true, "Trading is not enabled yet");
        }

		uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if( swapEnabled && 
            canSwap &&
            !swapping &&
            automatedMarketMakerPairs[to] &&
            _totalBuyFee + _totalSellFee > 0
        ) {
            swapping = true;

            if (swapWithLimit) {
                contractTokenBalance = swapTokensAtAmount;
            }

            uint256 totalFee = _totalBuyFee + _totalSellFee;
            uint256 treasuryShare = treasuryBuyFee + treasurySellFee;
            uint256 wilsonShare = wilsonBuyFee + wilsonSellFee;
            uint256 marketingShare = marketingBuyFee + marketingSellFee;
            
            if(contractTokenBalance > 0 && totalFee >= 0) {
                uint256 initialBalance = address(this).balance;

                address[] memory path = new address[](2);
                path[0] = address(this);
                path[1] = uniswapV2Router.WETH();

                uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                    contractTokenBalance,
                    0,
                    path,
                    address(this),
                    block.timestamp);
                
                uint256 newBalance = address(this).balance - initialBalance;

                if(treasuryShare > 0) {
                    uint256 treasuryAmount = newBalance * treasuryShare / totalFee;
                    payable(treasuryWallet).transfer(treasuryAmount);
                }

                if(wilsonShare > 0) {
                    uint256 wilsonAmount = newBalance * wilsonShare / totalFee;
                    payable(wilsonWallet).transfer(wilsonAmount);
                }

                if(marketingShare > 0) {
                    uint256 marketingAmount = newBalance * marketingShare / totalFee;
                    payable(marketingWallet).transfer(marketingAmount);
                }
            }         

            swapping = false;
        }

        bool takeFee = !swapping;

        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if(takeFee && (from == uniswapV2Pair || to == uniswapV2Pair)) {
            uint256 _totalFees;
            if(from == uniswapV2Pair) {
                _totalFees = _totalBuyFee;
            } 
            else if(to == uniswapV2Pair){
                _totalFees = _totalSellFee;
            }
        	uint256 fees = amount * _totalFees / 100;
        	
        	amount = amount - fees;
            
            if(fees > 0) {
                super._transfer(from, address(this), fees);
            }
        }

        super._transfer(from, to, amount);

    }

    
    function setSwapEnabled(bool _swapEnabled) external onlyOwner {
        require(
            swapEnabled != _swapEnabled, 
            "Swap is already set to that state"
        );
        swapEnabled = _swapEnabled;
    }

    function setSwapTokensAtAmount(uint256 newAmount) external onlyOwner {
        require(
            newAmount > totalSupply() / 1_000_000, 
            "New Amount must more than 0.0001% of total supply"
        );
        swapTokensAtAmount = newAmount;
    }

    function setSwapWithLimit(bool _swapWithLimit) external onlyOwner {
        require(
            swapWithLimit != _swapWithLimit, 
            "Swap with limit is already set to that state"
        );
        swapWithLimit = _swapWithLimit;
    }

   
    function multiSendTokens(address[] memory accounts, uint256[] memory amounts) external onlyOwner {
        require(accounts.length == amounts.length, "Lengths do not match.");
        for (uint8 i = 0; i < accounts.length; i++) {
            require(balanceOf(msg.sender) >= amounts[i]);
            super._transfer(msg.sender , accounts[i], amounts[i]*10**_decimals);
        }
    }
      
}