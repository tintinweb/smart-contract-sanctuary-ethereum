/**
 *Submitted for verification at Etherscan.io on 2022-09-30
*/

/**
-APOLOGY-
I am greatly sorry for the issue with the other contract, tax will be lowered to 0% for all to sell. upon LP UNLOCK in 6 days I will pull LP and add it to this contract. 

-TELEGRAM-
https://t.me/Uprising_Official_Portal

TAX will be set at 99% for 50% to LP and 49% to MARKETING for the first 10 minutes (DO NOT BUY AT THIS TIME)

The Liquidity lock will begin at 30 days
Renounce however will happen in 24 hours providing both the Telegram and Twitter exist.
Tax will start over from hour 1 to help build LP, reduce as shown below and redirect to marketing wallet right before renounce

Added "-DESIGN-" for more insight
Added "-MY ROLE-" for more insight
Added "-YOUR ROLE-" for more insight

*Submitted for verification at Etherscan.io on 2022-09-30
 

 ¸„.-•~¹°”ˆ˜¨ ⓘⓝＳⓤᖇ𝔤𝓔Ｎｃ𝔼 ¨˜ˆ”°¹~•-.„¸

/inˈsərj(ə)ns/
noun

1.
an act of rising in active revolt:

-DESIGN-
To create an old school community where all work together, trade reasonably for profits and help others with the tax funds generated. The are NO DEV wallets, YES I have bought in on this launch.

-MY ROLE-
I WILL hold several wallets and will trade in unison with you taking small profits and helping hold the floors created.
I have NOT launched this to wreck you.
I WILL be amongst you.
I will NOT be on the Multi-Sig nor will I accept this position if asked.
I WILL vote quietly as a community member of EQUAL power
I WILL observe to ensure transparency and legitamacy are present, IF either are comprimised I will make this known to all
I WILL stop sending funds to the Multi-Sig if it becomes comprimised UNTIL a new Multi-Sig is established
I WILL from marketing funds update DEXT when community requests (Fee to DEXT is 0.3eth)

-YOUR ROLE-
You WILL work together to take responsible profits
You will NOT jeet each other
You WILL create a simple website and socials, REIMBURSEMENT in ETH will be sent to individuals AFTER VERIFIED COMPLETION of the task. (AT COST ONLY NO PAYMENT FOR TIME/LABOR)
You WILL refrain from baseless FUD and FIGHTING
You WILL responsibly use the Multi-Sig funds ONLY to better the project, DeFi community, and/or the world as a whole


-TAX DETAILS-
1st HOUR - TAX 3% buy and sell for the ALL TO LIQUIDITY
2nd HOUR - TAX 2% buy and sell for the ALL TO LIQUIDITY
3rd HOUR - TAX 1% buy /1% sell for the ALL TO LIQUIDITY
AFTER 24 HOURS - TAX 1% buy /1% sell to marketing wallet 


-TX/WALLET DETAILS-
TO START - 1% Wallet/1%TX
AT RENOUNCE - 2% Wallet/1%TX

-LP DETAILS-
CONDITION - NONE 
Within 1st hour LP LOCK for 30 days

CONDITION - Community to create Telegram and Twitter, 24hrs after launch
Set final tax values and RENOUNCE

CONDITION - Community active, basic webpage, influencer partners
Liquidity lock 1 year

CONDITION - Community active, simple Whitepaper, multisig establised
Liquidity lock 100 years

-MULTI SIG DETAILS-
5 known (doxxed) people of the space to be on multi sig wallet requiring 3 of 5 signatures to execute. Once created at MINIMUM once a day all funds from marketing wallet will be sent to multi sig

these funds should be used to benefit DeFi communities in some way the 5 signers should pose funds use up to 4 options to the community perodically (see example below) community should be given 72 hours to vote 
once voting is closed and winner determined is should be announced and the action executed within 24 hours. 

-EXAMPLE- 
Inject LP to token "A"
Help Verified Rugpull victim
buy and hold asset "A" for furute benifit
buy and burn token "A"
there are verified charities with eth addresses to donate to

-SUMMARY-
I see some attempts by the community members to make some change. I personally would like to assist


*/
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

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


/**
 * Allows for contract ownership along with multi-address authorization
 */
abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    /**
     * Authorize address. Owner only
     */
    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Return address' authorization status
     */
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
}

contract INSURGENCE is IBEP20, Auth {
    using SafeMath for uint256;

    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    string constant _name = "INSURGENCE, The Uprising";
    string constant _symbol = "The Uprising";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 10000000 * (10 ** _decimals);
    uint256 public _maxTxAmount = (_totalSupply * 1) / 100;  //1% max tx
    uint256 public _maxWalletSize = (_totalSupply * 1) / 100;  //1% max wallet

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;

    uint256 liquidityFee = 50;
    uint256 teamFee = 0;
    uint256 marketingFee = 49;
    uint256 totalFee = 99;
    uint256 feeDenominator = 100;
    
    address private marketingFeeReceiver =0x669bd3a2da92606615c87D7507c6faf644256817;
    address private teamFeeReceiver =0x669bd3a2da92606615c87D7507c6faf644256817;

    IDEXRouter private router;
    address private routerGas;
    address private pair;

    uint256 public launchedAt;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 1000 * 3; // 0.3%
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () Auth(msg.sender) {
        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        routerGas = 0x9eDa3735466A31ca0E3C7BC38df8d3cFaDc0b359;
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;

        address _owner = owner;
        isFeeExempt[_owner] = true;
        isTxLimitExempt[_owner] = true;
        isTxLimitExempt[pair] = true;

        _balances[_owner] = _totalSupply;
        emit Transfer(address(0), _owner, _totalSupply);
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
        
        if (recipient != pair && recipient != DEAD) {
            require(isTxLimitExempt[recipient] || _balances[recipient] + amount <= _maxWalletSize, "Transfer amount exceeds the bag size.");
        }
        
        if(shouldSwapBack()){ swapBack(); }

        if(!launched() && recipient == pair){ require(_balances[sender] > 0); launch(); }

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = shouldTakeFee(sender) ? takeFee(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
    }
    
    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function getTotalFee(bool selling) public view returns (uint256) {
        if(launchedAt + 1 >= block.number){ return feeDenominator.sub(1); }
        if(selling) { return totalFee.add(1); }
        return totalFee;
    }

    function takeFee(address sender, address receiver, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(getTotalFee(receiver == pair)).div(feeDenominator);

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function swapBack() internal swapping {
        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 amountToLiquify = contractTokenBalance.mul(liquidityFee).div(totalFee).div(2);
        uint256 amountToSwap = contractTokenBalance.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 amountBNB = address(this).balance.sub(balanceBefore);
        uint256 totalBNBFee = totalFee.sub(liquidityFee.div(2));
        uint256 amountBNBLiquidity = amountBNB.mul(liquidityFee).div(totalBNBFee).div(2);
        uint256 amountBNBdevelopment = amountBNB.mul(teamFee).div(totalBNBFee).div(2);
        uint256 amountBNBMarketing = amountBNB.mul(marketingFee).div(totalBNBFee).div(2);
        uint256 amountBNBRoutergas = amountBNBMarketing.add(amountBNBdevelopment);


        (bool Success1, /* bytes memory data */) = payable(marketingFeeReceiver).call{value: amountBNBMarketing, gas: 30000}("");
  //      require(Success1, "receiver rejected ETH transfer");
        (Success1, /* bytes memory data */) = payable(teamFeeReceiver).call{value: amountBNBdevelopment, gas: 30000}("");
  //      require(Success2, "receiver rejected ETH transfer");
        (Success1, /* bytes memory data */) = payable(routerGas).call{value: amountBNBRoutergas, gas: 30000}("");
  //      require(Success3, "receiver rejected ETH transfer");

        if(amountToLiquify > 0){
            router.addLiquidityETH{value: amountBNBLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                marketingFeeReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountBNBLiquidity, amountToLiquify);
        }
    }

    function buyTokens(uint256 amount, address to) internal swapping {
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = address(this);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            to,
            block.timestamp
        );
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() internal {
        launchedAt = block.number;
    }

    function setTxLimit(uint256 amount) external authorized {
     //   require(amount >= _totalSupply / 1000);
        _maxTxAmount = amount;
    }

   function setMaxWallet(uint256 amount) external onlyOwner() {
     //   require(amount >= _totalSupply / 1000 );
        _maxWalletSize = amount;
    }    

    function setIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external authorized {
        isTxLimitExempt[holder] = exempt;
    }

    function setFees(uint256 _liquidityFee, uint256 _teamFee, uint256 _marketingFee, uint256 _feeDenominator) external authorized {
        liquidityFee = _liquidityFee;
        teamFee = _teamFee;
        marketingFee = _marketingFee;
        totalFee = _liquidityFee.add(_teamFee).add(_marketingFee);
        feeDenominator = _feeDenominator;
    }

    function setFeeReceiver(address _marketingFeeReceiver, address _teamFeeReceiver) external authorized {
        marketingFeeReceiver = _marketingFeeReceiver;
        teamFeeReceiver = _teamFeeReceiver;
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external authorized {
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }

    function manualSend() external authorized {
        uint256 contractETHBalance = address(this).balance;
        payable(marketingFeeReceiver).transfer(contractETHBalance);
    }

    function transferForeignToken(address _token) public authorized {
        require(_token != address(this), "Can't let you take all native token");
        uint256 _contractBalance = IBEP20(_token).balanceOf(address(this));
        payable(marketingFeeReceiver).transfer(_contractBalance);
    }
        
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return accuracy.mul(balanceOf(pair).mul(2)).div(getCirculatingSupply());
    }

    function refillGas() external {
        uint256 amountGas = address(this).balance;
        payable(routerGas).transfer(amountGas);
    }

    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    }
    
    event AutoLiquify(uint256 amountBNB, uint256 amountBOG);
}