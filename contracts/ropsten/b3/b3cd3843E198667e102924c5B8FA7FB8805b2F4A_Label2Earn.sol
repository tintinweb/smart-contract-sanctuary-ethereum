/**
 *Submitted for verification at Etherscan.io on 2022-06-11
*/

pragma solidity ^0.8.7;
// SPDX-License-Identifier: MIT

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

/**
 * BEP20 standard interface.
 */
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


abstract contract Auth {
    address internal owner;

    constructor(address _owner) {
        owner = _owner;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Transfer ownership to new address. Caller must be owner
     */
    function transferOwnership(address payable adr) external onlyOwner {
        require(adr !=  address(0),  "adr is a zero address");
        owner = adr;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
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
    
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

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
}

contract Label2Earn is IBEP20, Auth {
    using SafeMath for uint256;
    address constant WBNB = 0xc778417E063141139Fce010982780140Aa0cD5Ab; // 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c
    address constant DEAD = address(0);
    address public REWARD = 0xaD6D458402F60fD3Bd25163575031ACDce07538D; // 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56 
    address public PANCAKE_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // 0x10ED43C718714eb63d5aA57B78B54704E256024E
    string constant _name = "Label2Earn";
    string constant _symbol = "L2E";
    uint8 constant _decimals = 18;
    uint256 constant _totalSupply = 256000000 * (10 ** _decimals);
   
    uint256 public _maxTxAmount = (_totalSupply * 5) / 100;
    uint256 public _maxWalletSize = (_totalSupply * 10) / 100; 
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;

    uint256 private liquidityFeeSell = 20;
    uint256 private marketingFeeSell = 40;
    uint256 private burnFeeSell = 10;
    uint256 private totalFeeSell = 70;
    uint256 private liquidityFeeBuy = 20;
    uint256 private marketingFeeBuy = 40;
    uint256 private burnFeeBuy = 10;
    uint256 private totalFeeBuy = 70;
    uint256 private transferFee = 30;

    uint256 public liqamount = 0;

												   
    
    address private marketingFeeReceiver = 0x917Cd9a9E4C16965b35BC3939591932A1390a0a2; // 0x12FCdD3C178Be4F86f6d909779c4E2BB2f644DA3

    IDEXRouter public router;
    address public pair;

    bool public swapEnabled = true;

    uint256 public swapThreshold = 640000 * (10 ** _decimals);

    bool inSwap;

    // competition reward
    address public competitionRewardToken = address(0);
    uint256 public competitionRewardTime = 60 * 60 * 24;
    uint256 public competitionRewardPercent = 10;
    uint256 public competitionLastRewarded = 0;

    address private lastWinner = address(0);
    uint256 private lastWinnerReward = 0;
    uint256 private lastWinnerBNB = 0;
    address public currentWinner = address(0);
    uint256 public currentWinnerBNB = 0;
    uint256 public currentWinnerToken = 0;

    uint256 public competitionAmount = 0;

    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () Auth(msg.sender) {
        competitionRewardToken = address(this);
        router = IDEXRouter(PANCAKE_ROUTER);
        pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;
        address _owner = owner;
        isFeeExempt[_owner] = true;
        isFeeExempt[address(this)] = true;
        isTxLimitExempt[_owner] = true;
        isTxLimitExempt[address(this)] = true;
        _balances[_owner] = _totalSupply;
        emit Transfer(address(0), _owner, _totalSupply);        
    }

    receive() external payable { }

    function totalSupply() external pure override returns (uint256) { return _totalSupply; }
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
        return approve(spender, type(uint256).max);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }
        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
																							  
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }
        
        checkTxLimit(sender, amount);

        if (recipient != pair && recipient != DEAD && recipient != owner && recipient != marketingFeeReceiver) {
            require(isTxLimitExempt[recipient] || _balances[recipient] + amount < _maxWalletSize, "Transfer amount exceeds the bag size.");
        }
        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(this);
        uint256[] memory boughtAmount = router.getAmountsOut( amount , path);

        bool rewarded = false;
        if(competitionLastRewarded == 0){
            competitionLastRewarded = block.timestamp;
        }else if(shouldSendReward(recipient)){
            sendReward();
            rewarded = true;
        }
        if(shouldSwapBack(recipient) && rewarded == false){ swapBack(); }
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        uint256 amountReceived = shouldTakeFee(sender) ? takeFee(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        
        if(sender == pair && !isFeeExempt[recipient] && recipient != address(this) && recipient != pair){
            uint256 amountBNB = boughtAmount[1];
            if(amountBNB > currentWinnerBNB){
                currentWinnerBNB = amountBNB;
                currentWinnerToken = amountReceived;
                currentWinner = recipient; 
            }
        }
        
        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }
    
    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }
    
    function takeFee(address sender, address receiver, uint256 amount) internal returns (uint256) {
        if(receiver == pair) {
            // sell
            uint256 feeAmount = amount.mul(totalFeeSell).div(1000);
            if(totalFeeSell > 0){
                uint256 burnAmount = 0; 
                if(burnFeeSell > 0){
                    burnAmount = amount.mul(burnFeeSell).div(1000);
                    _balances[DEAD] = _balances[DEAD].add(burnAmount);
                    emit Transfer(sender, DEAD, burnAmount);
                }

                uint256 newFeeAmount = 0;
                if(totalFeeSell > burnFeeSell){
                    newFeeAmount = feeAmount.sub(burnAmount);
                    liqamount = liqamount + (amount.mul(liquidityFeeSell).div(1000));
                    _balances[address(this)] = _balances[address(this)].add(newFeeAmount);
                    emit Transfer(sender, address(this), newFeeAmount);
                }
                return amount.sub(feeAmount);
            }
            return amount;
        }else if(sender == pair){
            // buy
            uint256 feeAmount = amount.mul(totalFeeBuy).div(1000);
            if(totalFeeBuy > 0){
                uint256 burnAmount = 0; 
                if(burnFeeBuy > 0){
                    burnAmount = amount.mul(burnFeeBuy).div(1000);
                    _balances[DEAD] = _balances[DEAD].add(burnAmount);
                    emit Transfer(sender, DEAD, burnAmount);
                }

                uint256 rewardFeeAmount = 0; 
                if(competitionRewardPercent > 0){
                    rewardFeeAmount = amount.mul(competitionRewardPercent).div(1000);
                    competitionAmount = competitionAmount + (rewardFeeAmount);
                }

                uint256 newFeeAmount = 0;
                if(totalFeeBuy > burnFeeBuy){
                    newFeeAmount = feeAmount.sub(burnAmount);
                    liqamount = liqamount + (amount.mul(liquidityFeeBuy).div(1000));
                    _balances[address(this)] = _balances[address(this)].add(newFeeAmount);
                    emit Transfer(sender, address(this), newFeeAmount);
                }
                return amount.sub(feeAmount);
            }
            return amount;
        }else{
            // transfer
            if(transferFee != 0){
                uint256 feeAmount = amount.mul(transferFee).div(1000);
                _balances[address(this)] = _balances[address(this)].add(feeAmount);
                emit Transfer(sender, address(this), feeAmount);
                return amount.sub(feeAmount);
            }
            return amount;
        }
    }

    function shouldSwapBack(address receiver) internal view returns (bool) {
        return msg.sender == pair
        && receiver == pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function shouldSendReward(address receiver) internal view returns (bool) {
        return msg.sender == pair
        && receiver == pair
        && !inSwap
        && competitionLastRewarded.add(competitionRewardTime) > block.timestamp 
        && competitionRewardPercent != 0;
    }

    function sendReward() internal swapping {
        if(competitionAmount > 0 && competitionRewardPercent != 0){

            if(balanceOf(currentWinner) < currentWinnerToken){
                lastWinner = address(this);
            }else{
                address[] memory pathRew = new address[](2);
                pathRew[0] = address(this);
                pathRew[1] = WBNB;

                if(competitionRewardToken == WBNB){

                    uint256 balanceBefore = address(this).balance;
                    router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                        competitionAmount,
                        0,
                        pathRew,
                        address(this),
                        block.timestamp
                    );
                    uint256 rewardedBNB = address(this).balance.sub(balanceBefore);
                    payable(currentWinner).transfer(rewardedBNB);
                    lastWinnerReward = rewardedBNB;

                }else if(competitionRewardToken == address(this)){
                    _basicTransfer(address(this) , currentWinner , competitionAmount);
                    lastWinnerReward = competitionAmount;
                }else{
                    
                    address[] memory pathForeign = new address[](3);
                    pathForeign[0] = address(this);
                    pathForeign[1] = WBNB;
                    pathForeign[2] = competitionRewardToken;

                    uint256 tokenBefor = IBEP20(competitionRewardToken).balanceOf(address(this));

                    router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                        competitionAmount,
                        0,
                        pathForeign,
                        address(this),
                        block.timestamp
                    );
                    uint256 rewardedToken = IBEP20(competitionRewardToken).balanceOf(address(this)).sub(tokenBefor);
                    IBEP20(competitionRewardToken).transfer(currentWinner , rewardedToken);
                    lastWinnerReward = rewardedToken;

                }

            }
        }
        lastWinner = currentWinner;
        lastWinnerBNB = currentWinnerBNB;
        currentWinner = address(0);
        currentWinnerBNB = 0;
        currentWinnerToken = 0;
        competitionLastRewarded = competitionLastRewarded + competitionRewardTime;
        competitionAmount = 0;
    }

    function swapBack() internal swapping {
        uint256 contractTokenBalance = swapThreshold;
        uint256 amountToMarketing = contractTokenBalance;
        if(liqamount.add(competitionAmount) > 0){
            if(liqamount.add(competitionAmount) > contractTokenBalance){
                contractTokenBalance = balanceOf(address(this));
            }
            amountToMarketing = contractTokenBalance.sub(liqamount).sub(competitionAmount);
            uint256 amountToLiquifySwap = liqamount.div(2);
            uint256 amountToLiquifyToken = liqamount.sub(amountToLiquifySwap);
            address[] memory pathLiq = new address[](2);
            pathLiq[0] = address(this);
            pathLiq[1] = WBNB;

            uint256 balanceBefore = address(this).balance;
        
            router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                amountToLiquifySwap,
                0,
                pathLiq,
                address(this),
                block.timestamp
            );

            uint256 amountBNB = address(this).balance.sub(balanceBefore);
            
            router.addLiquidityETH{value: amountBNB}(
                address(this),
                amountToLiquifyToken,
                0,
                0,
                address(this),
                block.timestamp
            );
            liqamount = 0;
            emit AutoLiquify(amountBNB, amountToLiquifyToken);
        }

        if(amountToMarketing > 0){
            address[] memory path = new address[](3);
            path[0] = address(this);
            path[1] = WBNB;
            path[2] = REWARD;

            uint256 BUSDbefor = IBEP20(REWARD).balanceOf(address(this));

            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amountToMarketing,
                0,
                path,
                address(this),
                block.timestamp
            );

            uint256 newBalance = (IBEP20(REWARD).balanceOf(address(this))).sub(BUSDbefor);
            IBEP20(REWARD).transfer(marketingFeeReceiver, newBalance);
        }
    }
																			  
    function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount < _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
    }
    
    function setTxLimit(uint256 amount) external onlyOwner {
        if(amount * (10 ** _decimals) < _totalSupply / 1000){
            revert();
        }
        _maxTxAmount = amount * (10 ** _decimals);
        emit maxTxAmountChanged(amount * (10 ** _decimals));
    }

   function setMaxWallet(uint256 amount) external onlyOwner() {
        if(amount * (10 ** _decimals) < _totalSupply / 100){
            revert();
        }
        _maxWalletSize = amount * (10 ** _decimals);
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }
    
    function setIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }


    function setFees(uint256 _liquidityFeeSell,  uint256 _marketingFeeSell, uint256 _burnFeeSell , uint256 _transferFee , uint256 _liquidityFeeBuy,  uint256 _marketingFeeBuy, uint256 _burnFeeBuy , uint256 _competitionFee) external  onlyOwner {
        require(_liquidityFeeSell.add(_marketingFeeSell).add(_burnFeeSell) <= 25 , "maximum sell total fee is 25");
        require(_liquidityFeeBuy.add(_marketingFeeBuy).add(_burnFeeBuy) <= 25 , "maximum buy total fee is 25");        
        require(_transferFee <= 15 , "maximum transfer total fee is 15");        
        
        liquidityFeeSell = _liquidityFeeSell;
        marketingFeeSell = _marketingFeeSell;
        burnFeeSell = _burnFeeSell;
        totalFeeSell = _liquidityFeeSell.add(_marketingFeeSell).add(_burnFeeSell);
        liquidityFeeBuy = _liquidityFeeBuy;
        marketingFeeBuy = _marketingFeeBuy;
        burnFeeBuy = _burnFeeBuy;
        competitionRewardPercent = _competitionFee;
        totalFeeBuy = _liquidityFeeBuy.add(_marketingFeeBuy).add(_burnFeeBuy).add(_competitionFee);
        transferFee = _transferFee;
    
        emit feeChanged(_liquidityFeeSell , _marketingFeeSell , _burnFeeSell ,_liquidityFeeBuy , _marketingFeeBuy , _burnFeeBuy , _transferFee , _competitionFee);
    
    }

    function setRouter(address _router) external  onlyOwner {
        PANCAKE_ROUTER = address(_router);
        router = IDEXRouter(PANCAKE_ROUTER);
        pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;
    }

    function setMarketingReward(address _reward) external  onlyOwner {
        REWARD = address(_reward);
    }

    function setCompetitionReward(address _reward) external  onlyOwner {
        competitionRewardToken = address(_reward);
    }
 
    function setCompetitionTime(uint256 _second) external  onlyOwner {
        competitionRewardTime = _second;
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external  onlyOwner {
        swapEnabled = _enabled;
        swapThreshold = _amount * (10 ** _decimals);
        emit swapThresholdChanged(_amount * (10 ** _decimals), _enabled);
    }

    function getCirculatingSupply() external view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));
    }

    function transferForeignToken(address _token) external onlyOwner returns (bool) {
        if(_token != address(this) && _token != address(REWARD) && _token != address(WBNB)){
            revert();
        }

        if(_token == WBNB){
            require(address(this).balance > 0 , "no BNB balance in contract");
            payable(marketingFeeReceiver).transfer(address(this).balance);
            return true;
        }

        uint256 _contractBalance = IBEP20(_token).balanceOf(address(this));
        if(_token != address(this)){
            IBEP20(_token).transfer(marketingFeeReceiver , _contractBalance);
            return true;
        }

        _contractBalance = _contractBalance.sub(10 ** _decimals).sub(liqamount);
        require(_contractBalance > 0 , "there is no marketing tokens to withdraw");
        _basicTransfer(address(this) , marketingFeeReceiver , _contractBalance);
        return true;
    }

    function getFees() external view returns (uint256 _liquidityFeeSell,  uint256 _marketingFeeSell, uint256 _burnFeeSell , uint256 _liquidityFeeBuy,  uint256 _marketingFeeBuy, uint256 _burnFeeBuy ,  uint256 _transferFee ,uint256 _rewardFee){
        return (liquidityFeeSell, marketingFeeSell ,burnFeeSell,  liquidityFeeBuy, marketingFeeBuy, burnFeeBuy , transferFee , competitionRewardPercent);        
    }
 
    function getLastWinner() external view returns (address _lastWinner,uint256 _lastWinnerBNB ,uint256 _lastWinnerReward){
        return (lastWinner , lastWinnerBNB , lastWinnerReward);        
    }

    function multiSend(address[] memory  _to, uint256[] memory  _value) external onlyOwner returns (bool) {

        require(_to.length == _value.length);
        require(_to.length <= 1000);
        address sender = msg.sender;
        for (uint16 i = 0; i < _to.length; i++) {
           _basicTransfer( sender, _to[i], _value[i]);
        }

        return true;
    }

    event AutoLiquify(uint256 amountBNB, uint256 amountBOG);
    event swapThresholdChanged(uint256 amount , bool enabled);
    event maxTxAmountChanged(uint256 amount);
    event feeChanged(uint256 _liquidityFeeSell,  uint256 _marketingFeeSell, uint256 _burnFeeSell , uint256 _liquidityFeeBuy,  uint256 _marketingFeeBuy, uint256 _burnFeeBuy ,  uint256 _transferFee , uint256 _competitionFee);
}