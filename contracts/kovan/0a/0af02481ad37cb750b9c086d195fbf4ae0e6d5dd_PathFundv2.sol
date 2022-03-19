/**
 *Submitted for verification at Etherscan.io on 2022-03-19
*/

//SPDX-License-Identifier: KK
/* o/

 /$$$$$$$             /$$     /$$       /$$$$$$$$                        /$$
| $$__  $$           | $$    | $$      | $$_____/                       | $$
| $$  \ $$ /$$$$$$  /$$$$$$  | $$$$$$$ | $$    /$$   /$$ /$$$$$$$   /$$$$$$$
| $$$$$$$/|____  $$|_  $$_/  | $$__  $$| $$$$$| $$  | $$| $$__  $$ /$$__  $$
| $$____/  /$$$$$$$  | $$    | $$  \ $$| $$__/| $$  | $$| $$  \ $$| $$  | $$
| $$      /$$__  $$  | $$ /$$| $$  | $$| $$   | $$  | $$| $$  | $$| $$  | $$
| $$     |  $$$$$$$  |  $$$$/| $$  | $$| $$   |  $$$$$$/| $$  | $$|  $$$$$$$
|__/      \_______/   \___/  |__/  |__/|__/    \______/ |__/  |__/ \_______/                                                                            
Written by Katowice (@Katerina_978)  
*/
pragma solidity 0.8.0;
//interfaces
interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
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
// contracts
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}
contract Ownable is Context {
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
    function getTime() public view returns (uint256) {
        return block.timestamp;
    }
}
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    constructor (string memory name_, string memory symbol_) {
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        return true;
    }
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
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}
contract PathFundv2 is ERC20, Ownable {
//custom
    IUniswapV2Router02 public uniswapV2Router;
//bool
    bool public swapAndLiquifyEnabled = true;
    bool public sendToMarketing = true;
    bool public sendToDevelopment = true;
    bool public sendToBuyBack = true;
    bool public sendToLiq = true;
    bool public marketActive = false; 
    bool public maxWalletActive = false;
    bool public blockMultiBuys = false;
    bool public limitSells = false;
    bool public limitBuys = false;
    bool public feeStatus = true;
    bool public buyFeeStatus = true;
    bool public sellFeeStatus = true;
    bool public onlyTransfers = false;
    bool public blacklistActive = true;
    bool private isInternalTransaction = false;
//address
    address public uniswapV2Pair;
    address public marketingAddress = 0xA68cb5A1bc9f6397Cb13f806a87858FC5e9c8236;
    address public developmentAddress = 0x98B102DF4ACEd6Fd4d3c6cAf8e3aEBaE9d340068;
    address public buybackAddress = 0xcc7163EC7da906D02eB348a26bE0C8f9F8462385;
    address public LPtokenReciver = 0x00F65796aB084131c809eB5aA44461739d2bD8b3;
    address public airDropAddress;
//uint
    uint public total_supply;
    uint public buyMarketingFee = 2;
    uint public sellMarketingFee= 2;
    uint public buyDevelopmentFee= 2;
    uint public sellDevelopmentFee= 2;
    uint public buyLiqFee= 3;
    uint public sellLiqFee= 3;
    uint public buyBuyBackFee= 2;
    uint public sellBuyBackFee= 2;
    uint public totalBuyFee = buyMarketingFee + buyDevelopmentFee + buyLiqFee + buyBuyBackFee;
    uint public totalSellFee = sellMarketingFee + sellDevelopmentFee + sellLiqFee + sellBuyBackFee;
    uint public maxBuyTxAmount = 300000*10**9; 
    uint public maxSellTxAmount = 300000_0*10**9;
    uint public maxWallet = 3000000*10**9; 
    uint public minimumTokensBeforeSwap = 60000*10**9;
    uint public tokensToSwap = minimumTokensBeforeSwap; 
    uint public intervalSecondsForSwap = 120;
    uint public secMultiBuy;
    uint private startTimeForSwap;
    uint private marketActiveAt;
    uint private lenBlacklist;
    uint private lenPremarket;
    uint private lenExcludedFee;

//struct
    struct userData {uint lastBuyTime;}
//mapping & list
    mapping (address => bool) public blacklistAddress;
    address[] public listBlackListAddress;
    mapping (address => bool) public premarketUser;
    address[] public listPremarketUser;
    mapping (address => bool) public excludedFromFees;
    address[] public listExcludedFromFees;
    mapping (address => bool) public automatedMarketMakerPairs;
    mapping (address => userData) public userLastTradeData;
//event
    event MarketingCollected(uint256 amount);
    event DevelopmentCollected(uint256 amount);
    event LiquidityAdded(uint256 bnbAmount, uint256 tokenAmount);
    event BuyBackCollected (uint256 amount);
// constructor
    constructor() ERC20("PathFundv2", "PATH") {
        total_supply = 100_000_000 * 10 ** decimals();
        // set gvars
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        //spawn pair
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());
        // mappings
        excludedFromFees[marketingAddress] = true;
        excludedFromFees[developmentAddress] = true;
        excludedFromFees[buybackAddress] = true;
        excludedFromFees[address(this)] = true;
        excludedFromFees[owner()] = true;
        premarketUser[owner()] = true;
        automatedMarketMakerPairs[uniswapV2Pair] = true;
        _mint(msg.sender, total_supply); // mint is used only here
    }
    // accept bnb for autoswap
    receive() external payable {}

// utility functions
      function kkAirDrop(address[] memory _address, uint256[] memory _amount) external { 
        require(msg.sender == owner() || msg.sender == airDropAddress); 
        for(uint i=0; i< _amount.length; i++){
            address adr = _address[i];
            uint amnt = _amount[i] *10**decimals();
            super._transfer(msg.sender, adr, amnt); 
        }
    }

    function setairDropAddress(address adr) public onlyOwner { 
        airDropAddress = adr;  
    }

    function updateUniswapV2Router(address newRouterAddress, bool create, address pair) external onlyOwner {
        uniswapV2Router = IUniswapV2Router02(newRouterAddress);
        if(create) {
            address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
                .createPair(address(this), uniswapV2Router.WETH());
            uniswapV2Pair = _uniswapV2Pair;
            automatedMarketMakerPairs[uniswapV2Pair] = true;
        } else {
            uniswapV2Pair = pair;
            automatedMarketMakerPairs[uniswapV2Pair] = true;
        }
    }
    function transferForeignToken(address _token, address _to, uint _value) external onlyOwner returns(bool _sent){
        if(_value == 0) {
            _value = IERC20(_token).balanceOf(address(this));
        } 
        _sent = IERC20(_token).transfer(_to, _value);
    }
    function sweep() external onlyOwner {
        uint balance = address(this).balance;
        payable(owner()).transfer(balance);
    }
//switch functions
    function switchMarketActive(bool _state, bool _onlytransfers) external onlyOwner {
        marketActive = _state;
        if(_state) {
            marketActiveAt = block.timestamp;
            onlyTransfers = _onlytransfers;
        }
        else{
            onlyTransfers = _onlytransfers;
        }
    }
    function switchBlockMultiBuys(bool _state, uint sec) external onlyOwner {
        blockMultiBuys = _state;
        if(_state){secMultiBuy = sec;}
        
    }
    function switchLimitSells(bool _state) external onlyOwner {
        limitSells = _state;
    }
    function switchLimitBuys(bool _state) external onlyOwner {
        limitBuys = _state;
    }
//set functions
    function setsendFee(bool marketing, bool development, bool liq, bool bback) external onlyOwner {
        sendToMarketing = marketing;
        sendToLiq = liq;
        sendToDevelopment = development;
        sendToBuyBack = bback;
    }

    function setFeesAddress(address marketing, address development, address lptokRec, address bback) public onlyOwner {
        marketingAddress = marketing;
        developmentAddress = development;
        buybackAddress = bback;
        LPtokenReciver = lptokRec;
        excludedFromFees[developmentAddress] = true;
        excludedFromFees[marketingAddress] = true;
        excludedFromFees[buybackAddress] = true;
    }
    function setbuybackAddress(address _adr) external onlyOwner {
        buybackAddress = _adr;
        excludedFromFees[buybackAddress] = true;
    }
    function setmarketingAddress(address _adr) external onlyOwner {
        marketingAddress = _adr;
        excludedFromFees[marketingAddress] = true;
    }
    function setdevelopmentAddress(address _adr) external onlyOwner {
        developmentAddress = _adr;
        excludedFromFees[developmentAddress] = true;
    }
    function setLPtokenReciver(address _adr) external onlyOwner {
        LPtokenReciver = _adr;
    }
    function betterTransferOwnership(address newowner) public onlyOwner {
        require(newowner != owner());
        excludedFromFees[owner()] = false;
        premarketUser[owner()] = false;
        transferOwnership(newowner);
        excludedFromFees[newowner] = true;
        premarketUser[newowner] = true;
        emit OwnershipTransferred(owner(), newowner);
    }
    function setMaxSellTxAmount(uint _value) external onlyOwner {
        require(_value >= ( total_supply * 1 /1000) /(10**decimals()), "MaxSell Tx too low");
        maxSellTxAmount = _value*10**decimals();
    }
    function setMaxBuyTxAmount(uint _value) external onlyOwner {
        require(_value >= ( total_supply * 1 /1000) /(10**decimals()), "MaxBuy Tx too low");
        maxBuyTxAmount = _value*10**decimals();
    }
    function setMaxWallet(bool status, uint max) external onlyOwner {
        require(max >=  (total_supply * 5 /1000)/(10**decimals()), "MaxWallet too low");
        maxWalletActive = status;
        maxWallet = max*10**decimals();
    }
    function setFee(bool is_buy, uint marketing, uint development, uint liq, uint buyback) public onlyOwner {
        uint totFee = marketing+development+liq;
        require(totFee <= 45, "Fee too high!" );
        if(is_buy) {
            buyDevelopmentFee = development;
            buyMarketingFee = marketing;
            buyLiqFee = liq;
            buyBuyBackFee = buyback;
            totalBuyFee = buyMarketingFee + buyDevelopmentFee + buyLiqFee + buyBuyBackFee;
        } else {
            sellDevelopmentFee = development;
            sellMarketingFee = marketing;
            sellLiqFee = liq;
            sellLiqFee = buyback;
            totalSellFee = sellMarketingFee + sellDevelopmentFee + sellLiqFee + sellLiqFee;
        }
    }
    function setFeeStatus(bool buy, bool sell, bool _state) external onlyOwner {
        feeStatus = _state;
        buyFeeStatus = buy;
        sellFeeStatus = sell;
    }
    function setSwapAndLiquify(bool _state, uint _intervalSecondsForSwap, uint _minimumTokensBeforeSwap, uint _tokensToSwap) public onlyOwner {
        swapAndLiquifyEnabled = _state;
        intervalSecondsForSwap = _intervalSecondsForSwap;
        minimumTokensBeforeSwap = _minimumTokensBeforeSwap*10**decimals();
        tokensToSwap = _tokensToSwap*10**decimals();
    }
    function set_allFees(uint bbback, uint sbback, uint bMarketing, uint sMarketing, uint bDevelopment, uint sDevelopment, uint bLiq, uint sLiq) public onlyOwner {
        require(bMarketing+bDevelopment+bLiq+bbback <= 45 && sMarketing+sDevelopment+sLiq+sbback <= 45, "Fee too high!" );
        setFee(true, bMarketing, bDevelopment, bLiq, bbback);
        setFee(false, sMarketing, sDevelopment, sLiq, sbback);
    }
    function set_maxLimits(uint maxbuy, uint maxsell, uint maxWall) public onlyOwner {
        require(maxbuy >= (total_supply * 1 /1000)/(10**decimals()) && maxsell >= (total_supply * 1 /1000)/(10**decimals()), "MaxTx buy and/or sell too low!");
        require(maxWall >= (total_supply * 5 /1000)/(10**decimals()), "MaxWallet too low!");
        maxBuyTxAmount = maxbuy*10**decimals();
        maxSellTxAmount = maxsell*10**decimals();
        maxWallet = maxWall*10**decimals();
    }
    function disableBlacklistState() external onlyOwner {
        // there is no coming back after disabling blacklist.
        blacklistActive = false;
    }
// mappings functions
    function editPremarketUser(address _target, bool _status) external onlyOwner {
        premarketUser[_target] = _status;
        if(_status){
            listPremarketUser.push(_target);
            lenPremarket+=1;
        }else{
            uint idx = findIndex(listPremarketUser, _target);
            delete listPremarketUser[idx];
            lenPremarket-=1;
        }
    }
    function editExcludedFromFees(address _target, bool _status) external onlyOwner {
        excludedFromFees[_target] = _status;
        if(_status){
            listExcludedFromFees.push(_target);
            lenExcludedFee+=1;
        }else{
            uint idx = findIndex(listExcludedFromFees, _target);
            delete listExcludedFromFees[idx];
            lenExcludedFee-=1;
        }
    }
    function excludeMultipleAccountsFromFees(address[] memory accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            excludedFromFees[accounts[i]] = excluded;
            if(excluded){
                listExcludedFromFees.push(accounts[i]);
                lenExcludedFee+=1;
            }else{
                uint idx = findIndex(listExcludedFromFees, accounts[i]);
                delete listExcludedFromFees[idx];
                lenExcludedFee-=1;
            }
        }
    }
    function editAutomatedMarketMakerPairs(address _target, bool _status) external onlyOwner {
        automatedMarketMakerPairs[_target] = _status;
    }
    function blacklistAccount(address _target, bool _status) external onlyOwner {
        blacklistAddress[_target] = _status;
        if(_status){
            listBlackListAddress.push(_target);
            lenBlacklist += 1;
        }
        else{
            uint idx = findIndex(listBlackListAddress, _target);
            delete listBlackListAddress[idx];
            lenBlacklist-=1;
        }
    }
    function blacklistMultipleAccounts(address[] calldata _targets, bool _state) external onlyOwner {
        for(uint256 i = 0; i < _targets.length; i++) {
            blacklistAddress[_targets[i]] = _state;
            if(_state){
                listBlackListAddress.push(_targets[i]);
                lenBlacklist += 1;
            }else{
                uint idx = findIndex(listBlackListAddress, _targets[i]);
                delete listBlackListAddress[idx];
                lenBlacklist-=1;
            }
        }
    }
// operational functions
    function swapTokensForEth(uint256 tokenAmount) private {
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
    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            LPtokenReciver,
            block.timestamp
        );
    }
    modifier FastTx() {
        isInternalTransaction = true;
        _;
        isInternalTransaction = false;
    }
    function distributeLiquifiedToken(uint tokenToLiq) private{
    // fees redistribution
        uint256 caBalance = address(this).balance;
        //liquidity add
        if(sendToLiq){
            uint256 liqPart = (caBalance * sellLiqFee / totalSellFee);
            addLiquidity(tokenToLiq, liqPart/2);
            emit LiquidityAdded(liqPart/2, tokenToLiq);
        }
        //marketing
        if(sendToMarketing) {
            uint256 marketingPart = caBalance * sellMarketingFee / totalSellFee;
            (bool success,) = address(marketingAddress).call{value: marketingPart}("");
            if(success) {
                emit MarketingCollected(marketingPart);
            }
        }
        //development
        if(sendToDevelopment) {
            uint256 developmentPart = caBalance * sellDevelopmentFee / totalSellFee;
            (bool success,) = address(developmentAddress).call{value: developmentPart}("");
            if(success) {
                emit DevelopmentCollected(developmentPart);
            }
        }
        //buyback
        if(sendToBuyBack) {
            uint256 buybackPart = caBalance * sellBuyBackFee / totalSellFee;
            (bool success,) = address(buybackAddress).call{value: buybackPart}("");
            if(success) {
                emit BuyBackCollected(buybackPart);
            }
        }
    }
    function swapAndLiquify(uint256 amount) private FastTx {
        uint256 tokenToLiq = ((tokensToSwap * sellLiqFee) / totalSellFee)/2; 
        swapTokensForEth(amount - tokenToLiq);
        distributeLiquifiedToken(tokenToLiq);
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        uint trade_type = 0;
        bool overMinimumTokenBalance = balanceOf(address(this)) >= minimumTokensBeforeSwap;

    // market status flag
        if(!marketActive) {
            if(onlyTransfers){
                require(trade_type == 0);
            }else{
                require(premarketUser[from],"cannot trade before the market opening");}
        }
    // normal transaction
        if(!isInternalTransaction) {
        // tx limits
            //buy
            if(automatedMarketMakerPairs[from]) {
                trade_type = 1;
                // limits
                if(!excludedFromFees[to]) {
                    // tx limit
                    if(limitBuys) {
                        require(amount <= maxBuyTxAmount, "maxBuyTxAmount Limit Exceeded");
                    }
                    // multi-buy limit
                    if(blockMultiBuys) {
                        require(userLastTradeData[to].lastBuyTime + secMultiBuy <= block.timestamp,"Multi-buy orders disabled.");
                        userLastTradeData[to].lastBuyTime = block.timestamp;
                    }
                }
            }
            //sell
            else if(automatedMarketMakerPairs[to]) {
                trade_type = 2;
                // marketing auto-bnb
                if (swapAndLiquifyEnabled && balanceOf(uniswapV2Pair) > 0) {
                    if (overMinimumTokenBalance && startTimeForSwap + intervalSecondsForSwap <= block.timestamp) {
                        startTimeForSwap = block.timestamp;
                        // sell to bnb
                        swapAndLiquify(tokensToSwap);
                    }
                }
                // limits
                if(!excludedFromFees[from]) {
                    // tx limit
                    if(limitSells) {
                    require(amount <= maxSellTxAmount, "maxSellTxAmount Limit Exceeded");
                    }
                }
            }
            
        // maxWallet
            if(maxWalletActive) {
                if(!excludedFromFees[from] && !excludedFromFees[to] && (trade_type == 1 || trade_type == 0)) {
                    require(amount + balanceOf(to) <= maxWallet, "maxWallet Limit Exceeded");
                }
            }
        // fees management
            if(feeStatus) {
                if(blacklistActive) {
                    if(trade_type == 0 || trade_type == 2) {
                        require(!blacklistAddress[from],"your account is locked");
                    }
                }
                // buy
                if(trade_type == 1 && buyFeeStatus && !excludedFromFees[to]) {
                	uint txFees = amount * totalBuyFee / 100;
                	amount -= txFees;
                    super._transfer(from, address(this), txFees);
                }
                //sell
                if(trade_type == 2 && sellFeeStatus && !excludedFromFees[from]) {
                	uint txFees = amount * totalSellFee / 100;
                	amount -= txFees;
                    super._transfer(from, address(this), txFees);
                }
                // no wallet to wallet tax
            }
        }

        super._transfer(from, to, amount);
    }
    function findIndex(address[] memory aList, address indexToFind) private pure returns(uint){
        for(uint i=0; i<aList.length; i++){
            if(aList[i] == indexToFind){
                return i;
            }
        }revert("can't delete an address from a list if it doesn't exist");
    }
    function retunList_blacklist() public view returns(address[] memory){
        address[] memory l_adrs = new address[](lenBlacklist);
        l_adrs = listBlackListAddress;
        return l_adrs;
    }
    function retunList_premarket() public view returns(address[] memory){
        address[] memory l_adrs = new address[](lenPremarket);
        l_adrs = listPremarketUser;
        return l_adrs;
    }
    function retunList_excludedFee() public view returns(address[] memory){
        address[] memory l_adrs = new address[](lenExcludedFee);
        l_adrs = listExcludedFromFees;
        return l_adrs;
    }

    function isThisFrom_KKteam() public pure returns(bool) {
        //heheboi.gif
        return true;
    }
}