/**
 *Submitted for verification at Etherscan.io on 2023-02-05
*/

// SPDX-License-Identifier: MIT

/*

 Name : Redfeg-AI
 Symbol : Redfeg-AI
 Total supply : 10 000 000 000 000
 Decimals : 18
   
 Twitter: https://twitter.com/Red_Feg
 Webiste: https://www.redfeg.net
 Telegram: https://t.me/RedFegAIERC

 🦍

*/

pragma solidity 0.8.17;

library Address{
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);

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

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
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

    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
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
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}


interface IFactory02 {
    event PairCreated(address indexed token0, address indexed token1, address lpPair, uint);
    function getPair(address tokenA, address tokenB) external view returns (address lpPair);
    function createPair(address tokenA, address tokenB) external returns (address lpPair);
}

interface IPair02 {
    function factory() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function sync() external;
}

interface IRouter01 {
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
    function swapExactETHForTokens(
        uint amountOutMin, 
        address[] calldata path, 
        address to, uint deadline
    ) external payable returns (uint[] memory amounts);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IRouter02 is IRouter01 {
    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
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
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

contract RedfegAI is ERC20, Ownable {
   
    using Address for address payable;

    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) private _isExcludedFromMaxSellLimit;
    mapping (address => bool) private _isExcludedFromMaxWalletLimit;


    uint8 public burnFee = 0;
    uint8 public teamFee = 4;
    uint8 public marketingFee = 4;
    uint8 public totalFees;


    IRouter02 public dexRouter;
    address public dexPair;
    
    bool private _inSwapAndLiquify;
    
    uint256 public maxSellLimit = 100_000_000_000 *10**18; // 1%
    uint256 public maxWalletLimit = 200_000_000_000 *10**18; // 2%
    uint256 public swapThreshold =  500_000_000 *10**18; // 0.005%

    // CoolDown system
    mapping(address => uint256) private _lastTimeTx;
    bool public coolDownEnabled = true;
    uint32 public coolDownTime = 60 seconds;

    // All known liquidity pools 
    mapping (address => bool) public automatedMarketMakerPairs;

    bool public tradingEnabled = false;

    address payable public marketingWallet = payable(0x8B5B8d403D75281505d002b392F8C4D6F470407e); 
    address payable public teamWallet = payable(0x7a06ad7AF13E7669B95b3b5b079171D21E2EAd28); 

    address constant private  DEAD = 0x000000000000000000000000000000000000dEaD;

    modifier lockTheSwap {
        _inSwapAndLiquify = true;
        _;
        _inSwapAndLiquify = false;
    }

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeFromMaxSellLimit(address indexed account, bool isExcluded);
    event ExcludeFromMaxWalletLimit(address indexed account, bool isExcluded);

    event AddAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event Router02Updated(address indexed newAddress, address indexed oldAddress);

    event TeamWalletUpdated(address indexed newWallet, address indexed oldWallet);
    event MarketingWalletUpdated(address indexed newWallet, address indexed oldWallet);

    event Burnt(uint256 amount);

    event CoolDownUpdated(bool state,uint32 timeInSeconds);

    event TradingEnabled();

    event FeesUpdated(uint8 newBurnFee, uint8 newTeamfee, uint8 newMarketingFee);
    event MaxSellLimitUpdated(uint256 amount);
    event MaxWalletLimitUpdated(uint256 amount);
    event SwapThresholdUpdated(uint256 amount);

    event Swap(
        uint256 tokensSwapped,
        uint256 ethReceived
    );

    constructor() ERC20("Redfeg-AI", "Redfeg-AI") {

        _mint(_msgSender(), 10_000_000_000_000 * 10**18);
        totalFees = burnFee + teamFee + marketingFee;

        dexRouter = IRouter02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        dexPair = IFactory02(dexRouter.factory())
            .createPair(address(this), dexRouter.WETH());

        _setAutomatedMarketMakerPair(dexPair, true);
        excludeFromAllFeesAndLimits(owner(),true);
        excludeFromAllFeesAndLimits(address(this),true);
        excludeFromAllFeesAndLimits(DEAD,true);

    }

    function excludeFromAllFeesAndLimits(address account, bool excluded) public onlyOwner {
        excludeFromFees(account,excluded);
        excludeFromMaxSellLimit(account,excluded);
        excludeFromMaxWalletLimit(account,excluded);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "REDFEG: Account has already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeFromMaxSellLimit(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromMaxSellLimit[account] != excluded, "REDFEG: Account has already the value of 'excluded'");
        _isExcludedFromMaxSellLimit[account] = excluded;

        emit ExcludeFromMaxSellLimit(account, excluded);
    }

    function excludeFromMaxWalletLimit(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromMaxWalletLimit[account] != excluded, "REDFEG: Account has already the value of 'excluded'");
        _isExcludedFromMaxWalletLimit[account] = excluded;

        emit ExcludeFromMaxWalletLimit(account, excluded);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != dexPair, "REDFEG: The main pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "REDFEG: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        _isExcludedFromMaxSellLimit[pair] = value;
        _isExcludedFromMaxWalletLimit[pair] = value;

        emit AddAutomatedMarketMakerPair(pair, value);
    }

    function updateCooldown(bool state, uint32 timeInSeconds) external onlyOwner{
        require(timeInSeconds <= 3600, "REDFEG: The cooldown must be lower or equals to 3600 seconds");
         coolDownTime = timeInSeconds * 1 seconds;
         coolDownEnabled = state;
         emit CoolDownUpdated(state,timeInSeconds);
    }

    function updateV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(dexRouter), "REDFEG: The router has already that address");
        emit Router02Updated(newAddress, address(dexRouter));
        dexRouter = IRouter02(newAddress);
        dexPair = IFactory02(dexRouter.factory())
            .createPair(address(this), dexRouter.WETH());

        _setAutomatedMarketMakerPair(dexPair, true);
    }

    function setFees(uint8 newBurnFee, uint8 newTeamFee, uint8 newMarketingFee) external onlyOwner {
        uint8 newTotalFees = newBurnFee + newTeamFee + newMarketingFee;
        require(newTotalFees <= 20 ,"REDFEG: Total fees must be lower than 20%");
        // Swap and distribute now, because the distribution will change
        require(!_inSwapAndLiquify, "Contract is already swapping");
        if(tradingEnabled) _swapAndDistribute(balanceOf(address(this)));
        burnFee = newBurnFee;
        teamFee = newTeamFee;
        marketingFee = newMarketingFee;
        totalFees = newTotalFees;
        emit FeesUpdated(newBurnFee,newTeamFee,newMarketingFee);
    }

    function setMaxSellLimit(uint256 amount) external onlyOwner {
        require(amount >= totalSupply()/1000/10**18, "REDFEG: Amount must be greater than 0.1% of the total supply"); 
        maxSellLimit = amount *10**18;
        emit MaxSellLimitUpdated(maxSellLimit);
    }

        function setMaxWalletLimit(uint256 amount) external onlyOwner {
        require(amount >= totalSupply()/1000/10**18, "REDFEG: Amount must be greater than 0.1% of the total supply"); 
        maxWalletLimit = amount *10**18;
        emit MaxWalletLimitUpdated(maxWalletLimit);
    }

    function setSwapThreshold(uint256 amount) external onlyOwner {
        require(amount <= totalSupply()/100/10**18, "REDFEG: Amount must be lower than 1% of the total supply");
        swapThreshold = amount *10**18;
        emit SwapThresholdUpdated(swapThreshold);
    }

    function setTeamWallet(address payable newWallet) external onlyOwner {
        require(newWallet != teamWallet, "REDFEG: The cex wallet has already this address");
        emit TeamWalletUpdated(newWallet,teamWallet);
        teamWallet = newWallet;
    }

    function setMarketingWallet(address payable newWallet) external onlyOwner {
        require(newWallet != marketingWallet, "REDFEG: The marketing wallet has already this address");
        emit MarketingWalletUpdated(newWallet,marketingWallet);
        marketingWallet = newWallet;
    }

    function enableTrading() external onlyOwner {
        require(!tradingEnabled,"REDFEG: Trading is already enabled");
        tradingEnabled = true;
        emit TradingEnabled();
    }

    function burn(uint256 amount) external returns (bool) {
        _transfer(_msgSender(), DEAD, amount);
        emit Burnt(amount);
        return true;
    }

    receive() external payable {

    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "REDFEG: Transfer from the zero address");
        require(to != address(0), "REDFEG: Transfer to the zero address");
        require(amount >= 0, "REDFEG: Transfer amount must be greater or equals to zero");

        bool isBuyTransfer = automatedMarketMakerPairs[from];
        bool isSellTransfer = automatedMarketMakerPairs[to];

        // Only owner can trade before trading is enabled
        if(!tradingEnabled) {
            require(owner() == from || owner() == to, "REDFEG: Trading is not enabled");
        }

        if(!_inSwapAndLiquify && tradingEnabled) {
            if(isSellTransfer && from != address(dexRouter) && !_isExcludedFromMaxSellLimit[from])
                require(amount <= maxSellLimit, "REDFEG: Amount exceeds the maxSellTxLimit");
            else if(!isSellTransfer && !isBuyTransfer && !_isExcludedFromMaxWalletLimit[to] && from != owner())
                require(balanceOf(to) + amount <= maxWalletLimit, "REDFEG: Amount exceeds the maxWalletLimit.");
            }

        bool takeFee = tradingEnabled && !_inSwapAndLiquify && (isBuyTransfer || isSellTransfer);
        // All transfers submitted to the tax, are subject to the cooldown system as well
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) takeFee = false;
        else {
            if(coolDownEnabled && !isBuyTransfer){
                uint256 timePassed = block.timestamp - _lastTimeTx[from];
                require(timePassed >= coolDownTime, "REDFEG: The cooldown is not finished, please retry the transfer later");
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapThreshold;

        if (
            canSwap &&
            !_inSwapAndLiquify&&
            !automatedMarketMakerPairs[from] && // not during buying
            tradingEnabled
        ) {
            _swapAndDistribute(swapThreshold);
        }

        uint256 amountWithoutFees = amount;
        if(takeFee) {
            amountWithoutFees = amount - amount * totalFees / 100;
            uint256 burnAmount = 0;
            if(isBuyTransfer){
                if(!_isExcludedFromMaxWalletLimit[to]) require(balanceOf(to) + amountWithoutFees <= maxWalletLimit, "REDFEG: Amount exceeds the maxWalletLimit.");
                if(coolDownEnabled) _lastTimeTx[to] = block.timestamp;
            }
            if(burnFee > 0) {
                burnAmount = amount * burnFee / 100;
                super._transfer(from,DEAD,burnAmount);
            }

            if(amount != amountWithoutFees + burnAmount) super._transfer(from, address(this), amount - amountWithoutFees - burnAmount);
        }
        super._transfer(from, to, amountWithoutFees);

    }

    function _swapAndDistribute(uint256 totalTokens) private lockTheSwap {
        if(totalFees - burnFee > 0) {
        uint256 initialBalance = address(this).balance;

        // Swap tokens for ETH
        _swapTokensForETH(totalTokens);

        uint8 feePercent = totalFees - burnFee;
        
        uint256 newBalance = address(this).balance - initialBalance;
        uint256 teamAmount = newBalance *  teamFee / feePercent ;
        uint256 marketingAmount = newBalance - teamAmount;
        teamWallet.sendValue(teamAmount);
        marketingWallet.sendValue(marketingAmount);

        emit Swap(totalTokens, newBalance);
        }
    }

    function _swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        _approve(address(this), address(dexRouter), tokenAmount);

        // make the swap
        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function swapAndDistribute(uint256 amount) public onlyOwner {
        require(tradingEnabled, "REDFEG: Trading must be enabled");        
        require(!_inSwapAndLiquify, "REDFEG: Contract is already swapping");
        require(amount > 0, "REDFEG: Amount must be greater than 0");
        uint256 contractTokenBalance = balanceOf(address(this));
        require(contractTokenBalance >= amount, "REDFEG: Not enough tokens to swap");

        _swapAndDistribute(amount);
        
    } 
    // To distribute airdrops easily
    function batchTokensTransfer(address[] calldata _holders, uint256[] calldata _amounts) external onlyOwner {
        require(_holders.length <= 200);
        require(_holders.length == _amounts.length);
            for (uint i = 0; i < _holders.length; i++) {
              if (_holders[i] != address(0)) {
                super._transfer(_msgSender(), _holders[i], _amounts[i]);
            }
        }
    }

    function withdrawStuckETH(address payable to) external onlyOwner {
        require(address(this).balance > 0, "REDFEG: There are no ETH in the contract");
        to.sendValue(address(this).balance);
    } 

    function withdrawStuckBEP20Tokens(address token, address to) external onlyOwner {
        require(token != address(this), "REDFEG: You are not allowed to get REDFEG tokens from the contract");
        require(IERC20(token).balanceOf(address(this)) > 0, "REDFEG: There are no tokens in the contract");
        require(IERC20(token).transfer(to, IERC20(token).balanceOf(address(this))));
    }

    function getCirculatingSupply() external view returns (uint256) {
        return totalSupply() - balanceOf(DEAD) - balanceOf(address(0));
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function isExcludedFromMaxSellLimit(address account) public view returns(bool) {
        return _isExcludedFromMaxSellLimit[account];
    }

    function isExcludedFromMaxWalletLimit(address account) public view returns(bool) {
        return _isExcludedFromMaxWalletLimit[account];
    }
  
}