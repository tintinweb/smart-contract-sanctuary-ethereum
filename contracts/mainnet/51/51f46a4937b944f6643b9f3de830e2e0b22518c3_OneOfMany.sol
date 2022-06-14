/**
 *Submitted for verification at Etherscan.io on 2022-06-13
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
 
abstract contract Ownable {
    address internal owner;
    address private _previousOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!YOU ARE NOT THE OWNER"); _;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }
}
 
interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
 
interface IDEXRouter {
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

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
}

contract OneOfMany is IBEP20, Ownable {
 
    address RWRD = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
 
    string constant _name = "One Of Many";
    string constant _symbol = "OOM";
    uint8 constant _decimals = 9;
 
    uint256 _totalSupply = 1_000_000_000_000_000 * (10 ** _decimals);
    uint256 public _maxTxAmount = _totalSupply / 100 * 1; // 1%
    uint256 public _maxWallet = _totalSupply / 100 * 3; // 3%
 
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    
    struct Holder {
        uint256 tokenAmount;
    }
    struct Winner {
        address winner;
        uint256 totalAmountWon;
        uint256 timesWon;
        uint256 time;
        uint256 amountBNB;
        uint256 bought;
        bool won;
    }

    address[] holders;
    Winner[] winner;
    mapping (address => uint256) holderIndexes;
    mapping (address => Holder) _holder;
    mapping (address => Winner) _winner;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isLotteryExempt;
    mapping (address => bool) isTxLimitExempt;
 
    uint256 lotteryFee = 5;
    uint256 liquidityFee = 1;
    uint256 marketingFee = 4;
    uint256 totalFee = 10;
 
    address public marketingFeeReceiver = msg.sender;

    uint256 public liquidityUnlockTime;
    uint256 public totalLPBNB;

    bool _removingLiquidity;
    bool _addingLiquidity;
    bool _tradingEnabled;

    uint256 public totalLotteryBNB;
    uint256 lotteryPercentage = 50;
    uint256 lastLottery=block.timestamp;
    uint256 lotteryMinPeriod = 1 hours;
    uint256 lotteryMinBalance = _totalSupply/1000;
    address lastLotteryWinner;
    
    uint256 targetLiquidity = 25;
    uint256 targetLiquidityDenominator = 100;
 
    IDEXRouter public router;
    address public pair;
    uint256 private _nonce;
 
    address private _dexRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D ;
 
    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 200; // 0.05%
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }
 
    constructor () Ownable(msg.sender) {
        router = IDEXRouter(_dexRouter);
        pair = IDEXFactory(router.factory()).createPair(router.WETH(), address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;
 
        isFeeExempt[msg.sender] = true;
        isTxLimitExempt[msg.sender] = true;

        isFeeExempt[address(this)] = true;
        isTxLimitExempt[address(this)] = true;

        isLotteryExempt[msg.sender] = true;
        isLotteryExempt[DEAD] = true;
        isLotteryExempt[pair] = true;
        isLotteryExempt[address(this)] = true;
 
        _balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }
 
    receive() external payable { }
 
    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
 
    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
 
    function approveMax(address spender) external returns (bool) {
        return approve(spender, _totalSupply);
    }
 
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
 
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != _totalSupply){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - (amount);
        }
        _transfer(sender, recipient, amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) private{
        require(sender != address(0) && recipient != address(0), "Cannot be zero address.");

        bool isIncluded = sender == pair || recipient == pair;
        bool isExcluded = isFeeExempt[sender] || isFeeExempt[recipient] || _addingLiquidity || _removingLiquidity;
        if (isExcluded) {
            _transferExcluded(sender, recipient, amount);
            } else{require(_tradingEnabled);
            if(isIncluded){
            transferIncluded(sender, recipient, amount);
            } else{_transferExcluded(sender, recipient, amount);
                }
            }
    }
 
    function transferIncluded(address sender, address recipient, uint256 amount) private {
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }
 
        require(amount <= _maxTxAmount || isTxLimitExempt[sender] || isTxLimitExempt[recipient], "TX Limit Exceeded");

        if(sender == pair){
            require(balanceOf(recipient) + amount <= _maxWallet || isTxLimitExempt[sender] || isTxLimitExempt[recipient], "Wallet Limit Exceeded");
        }

        if(shouldSwapBack()){ swapBack(); }
        if(shouldSendLottery()){sendLotteryReward();}

        _balances[sender] = _balances[sender] - (amount);
 
        uint256 amountReceived =takeFee(sender, amount);
 
        _balances[recipient] = _balances[recipient] + (amountReceived);

        if(!isLotteryExempt[sender]){setHolder(sender, _balances[sender]);}
        if(!isLotteryExempt[recipient]){setHolder(recipient, _balances[recipient]); _winner[recipient].bought+=amountReceived;}
 
        emit Transfer(sender, recipient, amountReceived);
    }

    function _transferExcluded(address sender, address recipient, uint256 amount) private {
        _balances[sender] = _balances[sender] - (amount);
        _balances[recipient] = _balances[recipient] + (amount);

        if(!isLotteryExempt[sender]){setHolder(sender, _balances[sender]);}
        if(!isLotteryExempt[recipient]){setHolder(recipient, _balances[recipient]);}
        
        emit Transfer(sender, recipient, amount);
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal {
        _balances[sender] = _balances[sender] - (amount);
        _balances[recipient] = _balances[recipient]+(amount);
        emit Transfer(sender, recipient, amount);
    }
 
    function setHolder(address account, uint256 amount) internal { 
        if(amount > 0 && _holder[account].tokenAmount == 0){
            addHolder(account);
        }else if(amount == 0 && _holder[account].tokenAmount > 0){
            removeHolder(account);
        }
        _holder[account].tokenAmount = amount;
    }

    function addHolder(address holder) internal {
        holderIndexes[holder] = holders.length;
        holders.push(holder);
    }
 
    function removeHolder(address holder) internal {
        holders[holderIndexes[holder]] = holders[holders.length-1];
        holderIndexes[holders[holders.length-1]] = holderIndexes[holder];
        holders.pop();
    }
 
    function takeFee(address sender, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount * (totalFee) / (100);
 
        _balances[address(this)] = _balances[address(this)] + (feeAmount);
        emit Transfer(sender, address(this), feeAmount);
 
        return amount - (feeAmount);
    }
 
    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    } 

    function shouldSendLottery() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && lastLottery + lotteryMinPeriod <= block.timestamp
        && totalLotteryBNB > 0;
    }  
 
    function swapBack() internal swapping {
        uint256 contractBalance = balanceOf(address(this));
        uint256 amountToLiquify = contractBalance * (liquidityFee) / (totalFee) / (2);
        uint256 amountToSwap = contractBalance - (amountToLiquify);
 
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        uint256 balanceBefore = address(this).balance;
 
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );
 
        uint256 amountBNB = address(this).balance - (balanceBefore);
 
        uint256 totalBNBFee = totalFee - (liquidityFee / (2));
 
        uint256 amountBNBLiquidity = amountBNB * (liquidityFee) / (totalBNBFee) / (2);
        uint256 amountBNBMarketing = amountBNB * (marketingFee) / (totalBNBFee);
        uint256 amountBNBLottery = amountBNB * (lotteryFee) / (totalBNBFee);
 
        payable(marketingFeeReceiver).transfer(amountBNBMarketing);
        totalLotteryBNB+=amountBNBLottery;
        addLiquidity(amountToLiquify, amountBNBLiquidity);
    }

    function addLiquidity(uint256 tokenAmount, uint256 amountWei) private {
        totalLPBNB+=amountWei;
        _addingLiquidity = true;
        router.addLiquidityETH{value: amountWei}(
            // Liquidity Tokens are sent from contract, NOT OWNER!
            address(this),
            tokenAmount,
            0,
            0,
            // contract receives CAKE-LP, NOT OWNER!
            address(this),
            block.timestamp
        );
        _addingLiquidity = false;
    }
    function _removeLiquidityPercent(uint8 percent) private {
        IBEP20 lpToken = IBEP20(pair);
        uint256 amount = lpToken.balanceOf(address(this)) * percent / 100;
        lpToken.approve(address(router), amount);
        _removingLiquidity = true;
        router.removeLiquidityETHSupportingFeeOnTransferTokens(
            address(this),
            amount,
            0,
            0,
            // Receiver address
            address(this),
            block.timestamp
        );
        _removingLiquidity = false;
    }

    function swapBNBtoRWRD(address winningAddress, uint256 amount) private {
    
    address[] memory path = new address[](2);
    path[0] = address(router.WETH());
    path[1] = address(RWRD);

    router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(0, path, winningAddress, block.timestamp);
    }

    function random() private view returns (uint) {
        uint r = uint(uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _nonce))) % holders.length);
        return r;
    }

    function sendLotteryReward() private returns (bool) {
        uint rand = random();
        while(_winner[holders[rand]].bought< lotteryMinBalance){
            rand = random();
        }
        address payable winningAddress = payable(holders[rand]);
        uint256 amountWei = totalLotteryBNB * lotteryPercentage / 100;
        swapBNBtoRWRD(winningAddress, amountWei);
        totalLotteryBNB-=amountWei;
        lastLottery = block.timestamp;
        lastLotteryWinner = winningAddress;
        addWinner(winningAddress, amountWei);
        return true;
    }

    function addWinner(address account, uint256 amountWei) private returns (bool){
        _winner[account].winner=account;
        _winner[account].totalAmountWon+=amountWei;
        _winner[account].timesWon++;
        _winner[account].time=block.timestamp;
        _winner[account].amountBNB=amountWei;
        _winner[account].won=true;
        _winner[account].bought == 0;
        winner.push(_winner[account]);
        return true;
    }

    function checkIfIWon(address holder) external view returns(bool won, uint256 amountWon, uint256 timesWon){
        amountWon = _winner[holder].totalAmountWon;
        won = _winner[holder].won;
        timesWon = _winner[holder].timesWon;
        return (won,amountWon,timesWon);
    }

    function checkLastWinner() external view returns(address lastWinner, uint256 amountWon, uint256 time){
        lastWinner = lastLotteryWinner;
        amountWon = _winner[lastLotteryWinner].amountBNB;
        time = _winner[lastLotteryWinner].time;
        return (lastWinner,amountWon,time);
    }

    function checkTimeUntilLottery() external view returns(uint256){
        uint256 nextLottery = lastLottery + lotteryMinPeriod;
        uint256 secondsUntilNext = nextLottery - block.timestamp;
        return secondsUntilNext>0?secondsUntilNext:0;
    }

    function checkNextPrizeAmount() external view returns(uint256){
        uint256 nextPrize=totalLotteryBNB * lotteryPercentage / 100;
        return nextPrize;
    }

    function setLotterySettings(address newReward, uint256 minPeriod, uint256 percentage, uint256 minBalance_base1000) external onlyOwner{
        require(percentage >= 25, "Cannot set percentage below 25%");
        require(percentage <= 100, "Cannot set percentage over 100%");
        require(isContract(newReward), "Address is a wallet, not a contract.");
        require(newReward != address(this), "Cannot set reward token as this token due to Router limitations.");
        RWRD = newReward;
        lotteryMinPeriod = minPeriod;
        lotteryPercentage = percentage;
        lotteryMinBalance = minBalance_base1000 * _totalSupply / 2000;
    }

    function setPresaleAddress(address presaler) external onlyOwner{
        isFeeExempt[presaler] = true;
        isTxLimitExempt[presaler] = true;
        isLotteryExempt[presaler] = true;
    }

    function ownerEnableTrading() public onlyOwner {
        require(!_tradingEnabled);
        _tradingEnabled=true;
    }
 
    function setTxLimit_Base1000(uint256 amount) external onlyOwner {
        require(amount >= _totalSupply / 1000);
        _maxTxAmount = amount;
    }
    
    function setWalletLimit_Base1000(uint256 amount) external onlyOwner {
        require(amount >= _totalSupply / 1000);
        _maxWallet = amount;
    }

    function ownerReleaseLPFromFees() public onlyOwner {
        require(block.timestamp>=liquidityUnlockTime);
        uint256 oldBNB=address(this).balance;
        _removeLiquidityPercent(100);
        uint256 newBNB=address(this).balance-oldBNB;
        require(newBNB>oldBNB);
    }

    function ownerRemoveLPPercentFromFees(uint8 LPPercent) public onlyOwner {
        require(block.timestamp>=liquidityUnlockTime);
        require(LPPercent<=20);
        uint256 oldBNB=address(this).balance;
        _removeLiquidityPercent(LPPercent);
        uint256 newBNB=address(this).balance-oldBNB;
        require(newBNB>oldBNB);
    }

    function ownerLockLP(uint256 _days) public onlyOwner {
        require(liquidityUnlockTime == 0);
        uint256 lockTime = _days * 1 days;
        liquidityUnlockTime=block.timestamp+lockTime;
    }

    function ownerExtendLPLock(uint256 _days) public onlyOwner {
        require(_days <= 60 days);
        uint256 lockTime = _days * 1 days;
        liquidityUnlockTime+=lockTime;
    }
 
    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }
 
    function setIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }

    function setIsLotteryExempt(address holder, bool exempt) external onlyOwner {
        isLotteryExempt[holder] = exempt;
    }
 
    function setFees(uint256 _liquidityFee, uint256 _marketingFee, uint256 _lotteryFee) external onlyOwner {
        liquidityFee = _liquidityFee;
        marketingFee = _marketingFee;
        lotteryFee = _lotteryFee;
        totalFee = _lotteryFee + (_liquidityFee) + (_marketingFee);
        require(totalFee <= 33);
    }
 
    function setFeeReceivers(address _marketingFeeReceiver) external onlyOwner {
        marketingFeeReceiver = _marketingFeeReceiver;
    }
 
    function setSwapBackSettings(bool _enabled, uint256 _amount) external onlyOwner {
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }
 
    function setTargetLiquidity(uint256 _target, uint256 _denominator) external onlyOwner {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
    }
 
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply - (balanceOf(DEAD)) - (balanceOf(address(0)));
    }
 
    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return accuracy * (balanceOf(pair) * (2)) / (getCirculatingSupply());
    }
 
    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    }

    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
    // Transfer stuck bnb balance from contract to owner wallet
    function ClearStuckBalance() external onlyOwner {
        uint256 contractBalance = address(this).balance;
        payable(msg.sender).transfer(contractBalance);
    }
    // Transfer stuck tokens to owner wallet, native token is not allowed
    function transferForeignToken(address _token) public onlyOwner {
        require(_token != address(this), "Can't let you take all native token");
        uint256 _contractBalance = IBEP20(_token).balanceOf(address(this));
        payable(msg.sender).transfer(_contractBalance);
    }

    function getWinners() external view returns(address[] memory holderAddress, uint256[] memory BNBAmount, uint256[] memory time){
        holderAddress = new address[](winner.length);
        BNBAmount = new uint256[](winner.length);
        time = new uint256[](winner.length);

        for(uint i=0; i < winner.length; i++){
            holderAddress[i] = winner[i].winner;
            BNBAmount[i] = winner[i].amountBNB;
            time[i] = winner[i].time;
        }
        return (holderAddress,BNBAmount,time);
    }
}