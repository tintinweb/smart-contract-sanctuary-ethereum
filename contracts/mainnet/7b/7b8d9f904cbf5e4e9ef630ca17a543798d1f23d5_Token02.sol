/**
 *Submitted for verification at Etherscan.io on 2022-10-23
*/

// Website - http://redeemthecurse.com/ 
// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

// Interfaces
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

        event Swap(
            address indexed sender,
            uint amount0In,
            uint amount1In,
            uint amount0Out,
            uint amount1Out,
            address indexed to
        );
        event Sync(uint112 reserve0, uint112 reserve1);

        function factory() external view returns (address);
        function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    }

    interface IUniswapV2Factory {
        function createPair(address tokenA, address tokenB) external returns (address pair);
    }

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

    abstract contract Ownable {
        address private _owner;

        event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

        constructor() { _transferOwnership(msg.sender); }

        function owner() public view virtual returns (address) { return _owner; }

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
        
        modifier onlyOwner() {
            require(owner() == msg.sender, "Ownable: caller is not the owner");
            _;
        }
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
        function allowance(address owner, address spender) public view virtual override returns (uint256) { return _allowances[owner][spender]; }

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
                _approve(sender, msg.sender, currentAllowance - amount);
            }
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

    contract Token02 is ERC20, Ownable {

        IUniswapV2Router02 public immutable uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address public immutable uniswapV2Pair;
        address public constant deadAddress = address(0xdead);

        bool private _swapping;
        bool private _isBuy;
        uint256 private _launchTime;

        address private MarketingWallet = msg.sender;
        address public _Deployer = msg.sender;
        
        uint256 public maxTransactionAmount;
        uint256 public swapTokensAtAmount;
        uint256 public maxWallet;
            
        bool public limitsInEffect = true;
        bool public tradingActive = false;

        mapping(address => bool) public isBot;
        mapping(address => uint256) private _holderLastTransferTimestamp;
        bool public transferDelayEnabled = true;
        
        uint256 public buyTotalFees = 4;
        uint256 public buyMarketingFee = 4;
        uint256 public buyBurnFee = 0;
        uint256 public sellTotalFees = 10;
        uint256 public sellMarketingFee = 5;
        uint256 public sellBurnFee = 5;

        uint256 public tokensForMarketing;
        uint256 public tokensForBurn;
        uint256 public HOUR = 3600;
        
        mapping (address => bool) private _isExcludedFromFees;
        mapping (address => bool) public _isExcludedMaxTransactionAmount;
        mapping (address => bool) public pair;

        mapping(address => uint256) lastTX;
        mapping(address => uint256) stakeTime;
        mapping(address => uint256) userStake;
        mapping(address => bool) nonJeet;
        uint256 private userTokens;

        event MarketingWalletUpdated(address indexed newWallet, address indexed oldWallet);

        constructor() ERC20("The Curse", "REDEEM") {
            
            uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
            _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

            uint256 totalSupply = 10000000 * (10 ** 9);
            
            maxTransactionAmount = totalSupply * 2 / 100; // 2% maxTransactionAmountTxn
            maxWallet = totalSupply * 3 / 100; // 3% maxWallet
            swapTokensAtAmount = totalSupply * 5 / 10000; // 0.05% swap wallet

            _isExcludedFromFees[msg.sender] = true;
            _isExcludedFromFees[address(this)] = true;
            _isExcludedFromFees[address(0xdead)] = true;

            _isExcludedMaxTransactionAmount[msg.sender] = true;
            _isExcludedMaxTransactionAmount[address(this)] = true;
            _isExcludedMaxTransactionAmount[address(0xdead)] = true;
            _isExcludedMaxTransactionAmount[address(uniswapV2Router)] = true;
            _isExcludedMaxTransactionAmount[address(uniswapV2Pair)] = true;

            _mint(msg.sender, totalSupply);
        }

        receive() external payable { }

        // View
            function isExcludedFromFees(address account) public view returns(bool) { return _isExcludedFromFees[account]; }
            function getNonJeetStatus() public view returns(bool) { return nonJeet[msg.sender]; }
            function getMyTax() public view returns(uint256) { return _getFees(msg.sender); }
            function getMyStake() public view returns(uint256) { return userStake[msg.sender]; }

            function getMyStakeTime() public view returns(uint256) {
                if(block.timestamp - stakeTime[msg.sender] == block.timestamp){ return 0; }
                else{ return block.timestamp - stakeTime[msg.sender]; }
            }

        // Public
            function deposit() public {
                uint256 v = balanceOf(msg.sender);
                    userStake[msg.sender] += v;
                    stakeTime[msg.sender] = block.timestamp;
                    userTokens += v;
                    super._transfer(msg.sender, address(this), v);
            }

            function withdraw() public {
                require(userStake[msg.sender] != 0, "User has no tokens");
                require(stakeTime[msg.sender] - block.timestamp > (HOUR * 16), "Dont be a jeet");
                    uint256 v = userStake[msg.sender];
                    userStake[msg.sender] = 0;
                    stakeTime[msg.sender] = 0;
                    nonJeet[msg.sender] = true;
                    userTokens -= v;
                    super._transfer(address(this), msg.sender, v);
            }

            function emergencyWithdraw() public {
                require(userStake[msg.sender] != 0, "User has no tokens");
                    uint256 v = userStake[msg.sender];
                    userStake[msg.sender] = 0;
                    stakeTime[msg.sender] = 0;
                    userTokens -= v;
                    super._transfer(address(this), msg.sender, v);
            }

        // Owner
            function setNonJeet(address u, bool s) public onlyOwner{ nonJeet[u] = s; }
            function excludeFromFees(address account, bool excluded) public onlyOwner { _isExcludedFromFees[account] = excluded; }

            function setAutomatedMarketMakerPair(address p, bool value) public onlyOwner {
                require(p != uniswapV2Pair, "The pair cannot be removed");
                _setAutomatedMarketMakerPair(p, value);
            }

            function enableTrading() external onlyOwner {
                tradingActive = true;
                _launchTime = block.timestamp + 2;
            }
        
            function removeLimits() external onlyOwner returns (bool) {
                limitsInEffect = false;
                return true;
            }

            function disableTransferDelay() external onlyOwner returns (bool) {
                transferDelayEnabled = false;
                return true;
            }

            function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner returns (bool) {
                require(newAmount >= totalSupply() / 100000, "Swap amount cannot be lower than 0.001% total supply.");
                require(newAmount <= totalSupply() * 5 / 1000, "Swap amount cannot be higher than 0.5% total supply.");
                swapTokensAtAmount = newAmount;
                return true;
            }
            
            function updateMaxTxnAmount(uint256 newNum) external onlyOwner {
                require(newNum >= (totalSupply() * 1 / 1000) / 1e18, "Cannot set maxTransactionAmount lower than 0.1%");
                maxTransactionAmount = newNum * 1e18;
            }

            function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
                require(newNum >= (totalSupply() * 5 / 1000)/1e18, "Cannot set maxWallet lower than 0.5%");
                maxWallet = newNum * 1e18;
            }
            
            function excludeFromMaxTransaction(address updAds, bool isEx) public onlyOwner {
                _isExcludedMaxTransactionAmount[updAds] = isEx;
            }

            function updateMarketingWallet(address newWallet) external onlyOwner {
                emit MarketingWalletUpdated(newWallet, MarketingWallet);
                MarketingWallet = newWallet;
            }
        
            function addBots(address[] memory bots) public onlyOwner() {
                for (uint i = 0; i < bots.length; i++) {
                    if (bots[i] != uniswapV2Pair && bots[i] != address(uniswapV2Router)) {
                        isBot[bots[i]] = true;
                    }
                }
            }
            
            function removeBots(address[] memory bots) public onlyOwner() {
                for (uint i = 0; i < bots.length; i++) { isBot[bots[i]] = false; }
            }

        // Internal
            function _setAutomatedMarketMakerPair(address p, bool value) private { pair[p] = value; }

            function _transfer(address from, address to, uint256 amount) internal override {
                require(from != address(0), "ERC20: transfer from the zero address");
                require(to != address(0), "ERC20: transfer to the zero address");
                require(!isBot[from], "Your address has been marked as a bot/sniper, you are unable to transfer or swap.");
                
                if (amount == 0) { super._transfer(from, to, 0); return; }
                if (block.timestamp < _launchTime) isBot[to] = true;

                if (limitsInEffect) {
                    if (from != owner() && to != owner() && to != address(0) && to != address(0xdead) && !_swapping) {
                        if (!tradingActive) { require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading is not active."); }
    
                        if (transferDelayEnabled){
                            if (to != owner() && to != address(uniswapV2Router) && to != address(uniswapV2Pair)){
                                require(_holderLastTransferTimestamp[tx.origin] < block.number);
                                _holderLastTransferTimestamp[tx.origin] = block.number;
                            }
                        }
                        
                        // On buy
                        if (pair[from] && !_isExcludedMaxTransactionAmount[to]) {
                            require(amount <= maxTransactionAmount, "Buy transfer amount exceeds the maxTransactionAmount.");
                            require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
                        }
                        
                        // On sell
                        else if (pair[to] && !_isExcludedMaxTransactionAmount[from]) {
                            require(amount <= maxTransactionAmount, "Sell transfer amount exceeds the maxTransactionAmount.");
                        }
                        else if (!_isExcludedMaxTransactionAmount[to]){
                            require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
                        }
                    }
                }
                
                uint256 contractTokenBalance = balanceOf(address(this)) - userTokens;
                bool canSwap = contractTokenBalance >= swapTokensAtAmount;

                if (canSwap && !_swapping && !pair[from] && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
                    _swapping = true;
                    swapBack();
                    _swapping = false;
                }

                bool takeFee = !_swapping;

                if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) takeFee = false;
                
                uint256 buyFees = 0;
                uint256 sellFees = 0;
                
                if (takeFee) { // On sell
                    if (pair[to] && sellTotalFees > 0){
                        _isBuy = false;
                        uint256 f = _getFees(from);
                        sellFees = (amount * f) / 100;
                        tokensForMarketing += sellFees * 75 / 100;
                        tokensForBurn += sellFees - tokensForMarketing;
                        super._transfer(from, address(this), sellFees);
                        _burn(address(this), tokensForBurn);
                        tokensForBurn = 0;
                        amount -= sellFees;
                    } // on buy
                    else if(pair[from] && buyTotalFees > 0) {
                        _isBuy = true;
                        buyFees = (amount * buyTotalFees) / 100;
                        tokensForMarketing += buyFees;
                        super._transfer(from, address(this), buyFees);
                        amount -= buyFees;
                    }
                } 
                
                if(pair[from]){ lastTX[to] = block.timestamp; }
                if(pair[to]){
                    lastTX[from] = block.timestamp;
                    if(nonJeet[from]){ nonJeet[from] = false; }
                }
                
                super._transfer(from, to, amount);
            }

            function _getFees(address u) internal view returns (uint256){
                if(nonJeet[u]){ return 4; }
                else{
                    uint256 mult;
                    uint256 base = 20;
                    uint256 hold = block.timestamp - lastTX[u];
                    if(hold == block.timestamp){ mult = 0; }
                    else{ mult = hold / (HOUR * 2); }
                    if(base - mult < 6){ return 6; }
                    else{ return base - mult; }
                }
            }

            function _swapTokensForEth(uint256 tokenAmount) private {
                address[] memory path = new address[](2);
                    path[0] = address(this);
                    path[1] = uniswapV2Router.WETH();
                _approve(address(this), address(uniswapV2Router), tokenAmount);

                uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                    tokenAmount,
                    0,
                    path,
                    address(this),
                    block.timestamp
                );
            }
            
            function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
                _approve(address(this), address(uniswapV2Router), tokenAmount);

                uniswapV2Router.addLiquidityETH{value: ethAmount}(
                    address(this),
                    tokenAmount,
                    0,
                    0,
                    owner(),
                    block.timestamp
                );
            }

            function swapBack() private {
                uint256 contractBalance = balanceOf(address(this)) - userTokens;
                bool success;
                if(contractBalance == 0) {return;}
                if(contractBalance > swapTokensAtAmount * 20){ contractBalance = swapTokensAtAmount * 20; }
                uint256 tokenLP = contractBalance / 3;
                uint256 spot = address(this).balance;

                _swapTokensForEth(contractBalance - tokenLP); 

                uint256 spot2 = address(this).balance - spot;
                require(spot2 != 0, "Nothing gained from swap");
                uint256 LPETH = spot2 / 2;

                _addLiquidity(tokenLP, LPETH);

                tokensForMarketing = 0;
                (success,) = address(MarketingWallet).call{value: address(this).balance}("");
            }
    }