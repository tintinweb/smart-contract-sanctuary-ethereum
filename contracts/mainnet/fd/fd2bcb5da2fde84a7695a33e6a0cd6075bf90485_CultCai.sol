/**
 *Submitted for verification at Etherscan.io on 2022-11-15
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

// Interfaces
    interface IERC20 {
        function totalSupply() external view returns (uint256);
        function balanceOf(address account) external view returns (uint256);
        function transfer(address recipient, uint256 amount) external returns (bool);
        function allowance(address owner, address spender) external view returns (uint256);
        function approve(address spender, uint256 amount) external returns (bool);
        function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
        event Transfer(address indexed from, address indexed to, uint256 value);
        event Approval(address indexed owner, address indexed spender, uint256 value);
    }

    interface IERC20Metadata is IERC20 {
        function name() external view returns (string memory);
        function symbol() external view returns (string memory);
        function decimals() external view returns (uint8);
    }

    interface IUniswapV2Pair {
        function name() external pure returns (string memory);
        function symbol() external pure returns (string memory);
        function decimals() external pure returns (uint8);
        function totalSupply() external view returns (uint);
        function balanceOf(address owner) external view returns (uint);
        function allowance(address owner, address spender) external view returns (uint);
        function approve(address spender, uint value) external returns (bool);
        function transfer(address to, uint value) external returns (bool);
        function transferFrom(address from, address to, uint value) external returns (bool);
        function factory() external view returns (address);
        function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
        event Swap(address indexed sender, uint amount0In, uint amount1In, uint amount0Out, uint amount1Out, address indexed to);
        event Sync(uint112 reserve0, uint112 reserve1);
        event Approval(address indexed owner, address indexed spender, uint value);
        event Transfer(address indexed from, address indexed to, uint value);
    }

    interface IUniswapV2Factory {
        function createPair(address tokenA, address tokenB) external returns (address pair);
    }

    interface IUniswapV2Router01 {
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
    }

    interface IUniswapV2Router02 is IUniswapV2Router01 {
        function swapExactTokensForETHSupportingFeeOnTransferTokens(
            uint amountIn, 
            uint amountOutMin, 
            address[] calldata path, 
            address to, 
            uint deadline
        ) external;
    }

// Contracts
    contract ERC20 is IERC20, IERC20Metadata {
        mapping(address => uint256) private _balances;
        mapping(address => mapping(address => uint256)) private _allowances;

        uint256 private _totalSupply;
        string private _name;
        string private _symbol;

        constructor(string memory name_, string memory symbol_) {
            _name = name_;
            _symbol = symbol_;
        }

        function name() public view virtual override returns (string memory) { return _name; }
        function symbol() public view virtual override returns (string memory) { return _symbol; }
        function decimals() public view virtual override returns (uint8) { return 9; }
        function totalSupply() public view virtual override returns (uint256) { return _totalSupply; }
        function balanceOf(address account) public view virtual override returns (uint256) { return _balances[account]; }
        function allowance(address o, address s) public view virtual override returns (uint256) { return _allowances[o][s]; }

        function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
            _transfer(msg.sender, recipient, amount);
            return true;
        }

        function approve(address spender, uint256 amount) public virtual override returns (bool) {
            _approve(msg.sender, spender, amount);
            return true;
        }

        function transferFrom(address sender, address recipient, uint256 amount ) public virtual override returns (bool) {
            uint256 currentAllowance = _allowances[sender][msg.sender];
            if (currentAllowance != type(uint256).max) {
                require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
                _approve(sender, msg.sender, currentAllowance - amount);}
            _transfer(sender, recipient, amount);
            return true;
        }

        function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
            _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
            return true;
        }

        function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
            uint256 currentAllowance = _allowances[msg.sender][spender];
            require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
            _approve(msg.sender, spender, currentAllowance - subtractedValue);
            return true;
        }

        function _transfer(address sender, address recipient, uint256 amount) internal virtual {
            require(sender != address(0), "ERC20: transfer from the zero address");
            require(recipient != address(0), "ERC20: transfer to the zero address");
            uint256 senderBalance = _balances[sender];
            require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
            _balances[sender] = senderBalance - amount;
            _balances[recipient] += amount;
            emit Transfer(sender, recipient, amount);
        }

        function _mint(address account, uint256 amount) internal virtual {
            require(account != address(0), "ERC20: mint to the zero address");
            _totalSupply += amount;
            _balances[account] += amount;
            emit Transfer(address(0), account, amount);
        }

        function _burn(address account, uint256 amount) internal virtual {
            require(account != address(0), "ERC20: burn from the zero address");
            uint256 accountBalance = _balances[account];
            require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
            _balances[account] = accountBalance - amount;
            _totalSupply = _totalSupply - amount;
            emit Transfer(account, address(0), amount);
        }

        function _approve(address owner, address spender, uint256 amount) internal virtual {
            require(owner != address(0), "ERC20: approve from the zero address");
            require(spender != address(0), "ERC20: approve to the zero address");
            _allowances[owner][spender] = amount;
            emit Approval(owner, spender, amount);
        }
    }

    contract CultCai is ERC20 {
        IUniswapV2Router02 public immutable uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address public immutable uniswapV2Pair;
        address public constant deadAddress = address(0xdead);

        bool private _swapping;
        uint256 private _launchTime;

        address private MarketingWallet = msg.sender;
        address private _devWallet = msg.sender;
        address public _deployer = msg.sender;

        address private _airdropWallet;
        uint256 private _airdropPercent;
        
        uint256 public maxTXAMT;
        uint256 public swapTokensAtAmount;
        uint256 public maxWallet;
            
        bool public limitsInEffect = true;
        bool public tradingActive = false;

        mapping(address => bool) public isBot;
        
        uint256 public swapTotalFees = 3;
        uint256 public tokensForSwap;

        uint256 public minTokenSub;
        uint256 public VIPTokenSub;
        uint256 public heldSubTokens;
        
        mapping(address => bool) _isExcludedFromFees;
        mapping(address => bool) _isExcludedMaxTX;
        mapping(address => bool) _isExcludedMaxWallet;
        mapping(address => bool) pair;

        mapping(string => uint256) subValue;
        mapping(string => uint256) subTime;

        event Subscription(string indexed UID, uint256 indexed time, uint256 indexed subVal);

        constructor() ERC20("CultCai", "CULTCAI") {
            uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
                pair[address(uniswapV2Pair)] = true;

            uint256 totalSupply = 100000000 * (10 ** 9);
            
            maxTXAMT = (totalSupply * 1) / 100; // 1%
            maxWallet = (totalSupply * 3) / 100; // 3%
            swapTokensAtAmount = totalSupply * 5 / 10000; // 0.05%

            _isExcludedFromFees[msg.sender] = true;
            _isExcludedFromFees[address(this)] = true;
            _isExcludedFromFees[address(0xdead)] = true;

            _isExcludedMaxTX[msg.sender] = true;
            _isExcludedMaxTX[address(this)] = true;
            _isExcludedMaxTX[address(0xdead)] = true;
            _isExcludedMaxTX[address(uniswapV2Router)] = true;
            _isExcludedMaxTX[address(uniswapV2Pair)] = true;

            _isExcludedMaxWallet[msg.sender] = true;
            _isExcludedMaxWallet[address(this)] = true;
            _isExcludedMaxWallet[address(0xdead)] = true;
            _isExcludedMaxWallet[address(uniswapV2Router)] = true;
            _isExcludedMaxWallet[address(uniswapV2Pair)] = true;

            _mint(msg.sender, totalSupply);
        }

        receive() external payable { }

        // View
            function isExcludedFromFees(address u) public view returns(bool){ return _isExcludedFromFees[u]; }
            function isExcludedFromMaxWallet(address u) public view returns(bool){ return _isExcludedMaxWallet[u]; }
            function isExcludedFromMaxTX(address u) public view returns(bool){ return _isExcludedMaxTX[u]; }

            function getSubData(string memory i) public view returns(uint256,uint256){
                require(subTime[i] != 0, "User not subscribed");
                return(subTime[i], subValue[i]);
            }

        // Public
            function subscribe(string memory UID, uint256 amount) public {
                require(balanceOf(msg.sender) >= amount);
                uint256 adv = (amount * _airdropPercent) / 100;
                super._transfer(msg.sender, _airdropWallet, adv);
                uint256 bv = amount - adv;
                super._burn(msg.sender, bv);
                    subTime[UID] = block.timestamp;
                    subValue[UID] = amount;
                emit Subscription(UID, amount, block.timestamp);
            }

        // Owner
            function setAutomatedMarketMakerPair(address p, bool value) public onlyDev {
                require(p != uniswapV2Pair, "The pair cannot be removed");
                    pair[p] = value;
            }

            function enableTrading() external onlyDev {
                tradingActive = true;
                _launchTime = block.timestamp + 2;
            }
        
            function updateSwapTokensAtAmount(uint256 newAmount) external onlyDev returns (bool) {
                require(newAmount >= totalSupply() / 100000, "Swap amount cannot be lower than 0.001% total supply.");
                require(newAmount <= totalSupply() * 5 / 1000, "Swap amount cannot be higher than 0.5% total supply.");
                swapTokensAtAmount = newAmount;
                return true;
            }
            
            function updateMaxTxnAmount(uint256 newNum) external onlyDev {
                require(newNum >= (totalSupply() / 1000), "Cannot set maxTXAMT lower than 0.1%");
                maxTXAMT = newNum * (10 ** 9);
            }

            function updateMaxWalletAmount(uint256 newNum) external onlyDev {
                require(newNum >= (totalSupply() * 5 / 1000), "Cannot set maxWallet lower than 0.5%");
                maxWallet = newNum * (10 ** 9);
            }

            function updateSwapTax(uint256 v) public onlyDev{
                require(v <= 10);
                    swapTotalFees = v;
            }
 
            function removeLimits() external onlyDev { limitsInEffect = false; }
            function excludeFromFees(address u, bool s) public onlyDev { _isExcludedFromFees[u] = s; }
            function excludeFromMaxTX(address u, bool s) public onlyDev { _isExcludedMaxTX[u] = s; }
            function updateMarketingWallet(address w) external onlyDev { MarketingWallet = w; }
            function setAirdropPercent(uint256 v) public onlyDev { require(v <= 100); _airdropPercent = v; }

            function setAirdropWallet(address u) public onlyDev { 
                _airdropWallet = u; 
                _isExcludedFromFees[u] = true;
                _isExcludedMaxTX[u] = true;
            }

            function setAuthWallet(address u, bool s) public onlyDev {
                _isExcludedFromFees[u] = s;
                _isExcludedMaxTX[u] = s;
            }

            function updateDevWallet(address u) public {
                require(msg.sender == _devWallet);
                    _devWallet = u;
            }

            function modBot(address bot, bool s) public onlyDev {
                require(bot != uniswapV2Pair && bot != address(uniswapV2Router));
                    isBot[bot] = s;
            }
            
            function transferOwner(address o) public onlyDev {
                require(o != address(0) && o != address(0xdead));
                    _deployer = o;
            }

            function gibsTendies(address t) public onlyDev{
                require(t != address(this), "Bad Dev! No tendies!");
                if(t == address(0)){ payable(msg.sender).transfer(address(this).balance); }
                else{ IERC20(t).transfer(msg.sender, IERC20(t).balanceOf(address(this))); }
            }

        // Internal
            function _transfer(address from, address to, uint256 amount) internal override {
                require(from != address(0) && to != address(0), "zero address transfer");
                require(!isBot[from], "Bad Robot!");
                if(amount == 0) { super._transfer(from, to, 0); return; }
                if(block.timestamp < _launchTime) { isBot[to] = true; }

                if(limitsInEffect) {
                    if(from != _deployer && to != _deployer && to != address(0) && to != address(0xdead) && !_swapping) {
                        if(!tradingActive){ require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading is not active."); }
    
                        if(pair[from] && !_isExcludedMaxTX[to]) {
                            require(amount <= maxTXAMT, "Max transaction exceeded");
                            require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
                        } else if(pair[to] && !_isExcludedMaxTX[from]) { require(amount <= maxTXAMT, "Max transaction exceeded"); 
                        } else if(!_isExcludedMaxTX[to]){ require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded"); }
                    }
                }
                
                uint256 contractTokenBalance = balanceOf(address(this));
                bool canSwap = contractTokenBalance >= swapTokensAtAmount;

                if(canSwap && !_swapping && !pair[from] && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
                    _swapping = true;
                    swapBack();
                    _swapping = false;
                }

                bool takeFee = !_swapping;
                if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) takeFee = false;
                
                uint256 buyFees = 0;
                uint256 sellFees = 0;
                
                if(takeFee) { // On sell
                    if(pair[to] && swapTotalFees > 0){
                        sellFees = (amount * swapTotalFees) / 100;
                        tokensForSwap += sellFees;
                        super._transfer(from, address(this), sellFees);
                        amount -= sellFees;
                    } else if(pair[from] && swapTotalFees > 0) {
                        buyFees = (amount * swapTotalFees) / 100;
                        tokensForSwap += buyFees;
                        super._transfer(from, address(this), buyFees);
                        amount -= buyFees;
                    }
                }   super._transfer(from, to, amount);
            }

            function _swapTokensForEth(uint256 tokenAmount) private {
                address[] memory path = new address[](2);
                    path[0] = address(this);
                    path[1] = uniswapV2Router.WETH();
                _approve(address(this), address(uniswapV2Router), tokenAmount);

                uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                    tokenAmount, 0, path, address(this), block.timestamp
                );
            }
            
            function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
                _approve(address(this), address(uniswapV2Router), tokenAmount);

                uniswapV2Router.addLiquidityETH{value: ethAmount}(
                    address(this), tokenAmount, 0, 0, _deployer, block.timestamp
                );
            }

            function swapBack() private {
                uint256 contractBalance = balanceOf(address(this));
                if(contractBalance == 0) {return;}
                if(contractBalance > swapTokensAtAmount * 20){ contractBalance = swapTokensAtAmount * 20; }
                uint256 tokenLP = contractBalance / 5;
                uint256 spot = address(this).balance;
                    _swapTokensForEth(contractBalance - tokenLP); 
                uint256 spot2 = address(this).balance - spot;
                require(spot2 != 0, "Nothing gained from swap");

                uint256 LPETH = spot2 / 4;
                    _addLiquidity(tokenLP, LPETH);
                tokensForSwap = 0;

                uint256 devFee = address(this).balance / 10;
                bool successDEV;
                uint256 mktFee = address(this).balance - devFee;
                bool successMKT;
                (successMKT,) = address(MarketingWallet).call{value: mktFee}("");
                (successDEV,) = address(_devWallet).call{value: devFee}("");
            }

            modifier onlyDev() { require(msg.sender == _deployer); _;}
    }