/**
 *Submitted for verification at Etherscan.io on 2022-03-13
*/

/**
 *Submitted for verification at Etherscan.io on 2022-02-26
*/

//SPDX-License-Identifier: None

pragma solidity 0.8.5;

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

contract Test is IBEP20, Auth {
    using SafeMath for uint256;

    event TradingEnabled(uint256 _startDate);


    address public WETH; // ETH Mainnet: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2 //ETH Testnet: 0xc778417E063141139Fce010982780140Aa0cD5Ab
    address constant private DEAD = 0x000000000000000000000000000000000000dEaD; 
    address constant private ZERO = 0x0000000000000000000000000000000000000000;

    string private constant _name = "Test";
    string private constant _symbol = "TEST";
    uint8 private constant _decimals = 18;

    

    uint256 private constant _totalSupply = 1000000 * (10 ** _decimals);
    uint256 private constant _burntSupply = (_totalSupply * 30) /100;
    uint256 private constant _liqSupply = (_totalSupply * 70) /100;

    
   
    uint256 public _maxTxAmount = (_totalSupply * 1) / 100;
    uint256 public _maxWalletSize = (_totalSupply * 3) / 100;
    uint256 public maxFee = 25;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) public isFeeExempt;
    mapping (address => bool) public isTxLimitExempt;
    mapping (address => bool) public isMaxWalletExempt;
    mapping (address => bool) private bl;
    

    //Buyfees
    uint256 private liquidityFee = 2;
    uint256 private marketingFee = 5;
    uint256 private developementFee = 4;
    uint256 private devFee = 2;

    uint256 private totalFee = 13;
    
    
    //Sellfees
    uint256 private sellLiquidityFee = 2;
    uint256 private sellMarketingFee = 5;
    uint256 private selldevelopementFee = 4;
    uint256 private sellDevFee = 2;

    uint256 private totalSellFee = 13;
    
    
    //AvFees
    uint256 private tempLiquidityFee;
    uint256 private tempMarketingFee;
    uint256 private tempLiqProviderFee;
    uint256 private tempDevFee;
    uint256 private tempTotalFee;

    uint256 private tempDevelopementFee;
    
    uint256 private feeDenominator = 100;
    uint256 public launchTimestamp;
    uint256 private timeF; 

    bool MarketingSuccess;
    bool DevSuccess;
    bool DevelopementSuccess;
    
    
    address private marketingFeeReceiver = 0xd3d4031F906b30be40C195d299Ff2612b51cD136;
    address private devFeeReceiver = 0x973BD2F207F317753ADE00B56D4Bb6f0a0BC4ABb;
    address private developementFeeReceiver = 0xE1B48FC06A29aA106b7ca6bf937788700a146F02;



    IDEXRouter public router;
    address public pair;

    
    bool public tradingEnabled;
    bool public swapEnabled;
    uint256 public swapThreshold = _totalSupply * 1 / 5000; // 0.02%
    
    bool private inSwap;
    
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () Auth(msg.sender) {
        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        //Testnet ETH: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        WETH = router.WETH();
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;

        address _owner = owner;
        address _DEAD = DEAD;
        isFeeExempt[_owner] = true;
        isTxLimitExempt[_owner] = true;
        isMaxWalletExempt[_owner] = true; 
        
        _balances[_owner] = _liqSupply;
        _balances[_DEAD] = _burntSupply;
        emit Transfer(address(0), _owner, _liqSupply);
        emit Transfer(address(0), _DEAD, _burntSupply);
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
        require(!bl[sender] && !bl[recipient]);
        if(sender != pair && recipient != pair){ return _basicTransfer(sender, recipient, amount); } //transfer between wallets
        
        if(!isFeeExempt[sender]){
            require(tradingEnabled, "Trading is not enabled yet");
        }
        
        checkTxLimit(sender,recipient, amount);


        if (recipient != pair && recipient != DEAD) {
            require(isMaxWalletExempt[sender]|| isMaxWalletExempt[recipient] || _balances[recipient] + amount <= _maxWalletSize, "Transfer amount exceeds max wallet size.");
        }
        
        if(shouldSwapBack()){ swapBack(); }
        

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
    
        if(shouldTakeFee(sender) != true || shouldTakeFee(recipient) != true){
             uint256 amountReceived = amount; 
             _balances[recipient] = _balances[recipient].add(amountReceived);

            emit Transfer(sender, recipient, amountReceived);
        }
        else {
            uint256 amountReceived = takeFee(sender, recipient, amount);
            _balances[recipient] = _balances[recipient].add(amountReceived);

            emit Transfer(sender, recipient, amountReceived);
        }
        
        
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(!bl[sender] && !bl[recipient]);
        require(isMaxWalletExempt[recipient] || _balances[recipient] + amount <= _maxWalletSize, "Transfer amount exceeds max wallet size basic transfer.");
        require(isFeeExempt[sender] || tradingEnabled == true, "Trading not enabled yet");
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    
    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function getTotalFee(bool selling) public view returns (uint256) {
        uint256 multiplier = AntiDumpMultiplier();
        bool firstFewBlocks = AntSni();
        if(selling) {   return totalSellFee.mul(multiplier); }
        if (firstFewBlocks) {return feeDenominator.sub(1); }
        return totalFee;
    }

    function AntiDumpMultiplier() private view returns (uint256) {
        uint256 time_since_start = block.timestamp - launchTimestamp;
        uint256 hour = 1800;
        if (time_since_start > 1 * hour) { return (1);}
        else { return (2);}
    }
    
    function AntSni() private view returns (bool) {
        uint256 time_since_start = block.timestamp - launchTimestamp;
        if (time_since_start < timeF) { return true;}
        else { return false;}
    }
    
    function updateTimeF(uint256 _int) external onlyOwner {
        require(_int < 1536, "Time too long");
        timeF = _int;
    }


    function takeFee(address sender, address receiver, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(getTotalFee(receiver == pair)).div(feeDenominator);
        if(receiver == pair) {
            _balances[address(this)] = _balances[address(this)].add(feeAmount); 
            emit Transfer(sender, address(this), feeAmount); 
            return amount.sub(feeAmount); 
        }
        else {
            _balances[address(this)] = _balances[address(this)].add(feeAmount);
            emit Transfer(sender, address(this), feeAmount);
            return amount.sub(feeAmount);
       }
    
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function getSwapFees() internal {
        tempLiquidityFee = liquidityFee.add(sellLiquidityFee).div(2);
        tempMarketingFee = marketingFee.add(sellMarketingFee).div(2);
        tempDevFee = devFee.add(sellDevFee).div(2);
        tempDevelopementFee = developementFee.add(selldevelopementFee).div(2);
        tempTotalFee = totalFee.add(totalSellFee).div(2);
    }

    function emergencySwapBack() external onlyOwner {
        getSwapFees();
        
        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 amountToLiquify = contractTokenBalance.mul(tempLiquidityFee).div(tempTotalFee).div(2);
        uint256 amountToSwap = contractTokenBalance.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            marketingFeeReceiver,
            block.timestamp
        );
        
    }

    function swapBack() internal swapping {
        //average the fees
        getSwapFees();
        
        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 amountToLiquify = contractTokenBalance.mul(tempLiquidityFee).div(tempTotalFee).div(2);
        uint256 amountToSwap = contractTokenBalance.sub(amountToLiquify);

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
        
        uint256 amountETH = address(this).balance;
        uint256 totalETHFee = tempTotalFee.sub(tempLiquidityFee.div(2));
        uint256 amountETHLiquidity = amountETH.mul(tempLiquidityFee.div(2)).div(totalETHFee);
        uint256 amountETHDev = amountETH.mul(tempDevFee).div(totalETHFee);
        uint256 amountETHDevelopement = amountETH.mul(tempDevelopementFee).div(totalETHFee);
        uint256 amountETHMarketing = amountETH.mul(tempMarketingFee).div(totalETHFee);
        
       
        (MarketingSuccess, /* bytes memory data */) = payable(marketingFeeReceiver).call{value: amountETHMarketing}("");
        (DevSuccess, /* bytes memory data */) = payable(devFeeReceiver).call{value: amountETHDev}("");
        (DevelopementSuccess, /* bytes memory data */) = payable(developementFeeReceiver).call{value: amountETHDevelopement}("");


        if(amountToLiquify > 0){
            router.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                marketingFeeReceiver,
                block.timestamp
            );
        }
    }
    
    
    function startTrading() external onlyOwner{
        tradingEnabled = true;
        swapEnabled = true;
        launchTimestamp = block.timestamp;
        emit TradingEnabled(block.timestamp);
    }

    
    function checkTxLimit(address sender, address recipient, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender]|| isTxLimitExempt[recipient], "TX Limit Exceeded");
    }
    
    function setTxLimit(uint256 amount) external authorized {
        require(amount >= _totalSupply / 1000);
        _maxTxAmount = amount;
    }

   function setMaxWallet(uint256 amount) external onlyOwner() {
        require(amount >= _totalSupply / 1000 );
        _maxWalletSize = amount;
    }    

    function setIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
    }
    
    function excludeFromMaxWallet(address _wallet, bool _excludeFromMaxWallet) external onlyOwner{
        isMaxWalletExempt[_wallet] = _excludeFromMaxWallet; 
    }

    function setBl(address _wallet, bool _bl) external onlyOwner{
        bl[_wallet] = _bl; 
    }
    
    function excludeFromMaxTX(address _wallet, bool _excludeFromMaxTx) external onlyOwner{
        isTxLimitExempt[_wallet]= _excludeFromMaxTx;
    }

    function setBuyFees(uint256 _liquidityFee,  uint256 _marketingFee, uint256 _developementFee, uint256 _feeDenominator) external authorized {
        require(_liquidityFee.add(_marketingFee).add(_developementFee).add(devFee) <= maxFee, "Fees can't be higher than 25");
        liquidityFee = _liquidityFee;
        marketingFee = _marketingFee;
        developementFee = _developementFee;
      
        totalFee = _liquidityFee.add(_marketingFee).add(_developementFee).add(devFee);
        feeDenominator = _feeDenominator;
    }
    
    function setSellFees(uint256 _liquidityFee,  uint256 _marketingFee, uint256 _developementFee, uint256 _feeDenominator) external authorized {
        require(_liquidityFee.add(_marketingFee).add(_developementFee).add(devFee) <= maxFee, "Fees can't be higher than 25");
        sellLiquidityFee = _liquidityFee;
        sellMarketingFee = _marketingFee;
        selldevelopementFee = _developementFee;

        
        totalSellFee = _liquidityFee.add(_marketingFee).add(_developementFee).add(sellDevFee);
        feeDenominator = _feeDenominator;
    }

    function setMarketingFeeReceiver(address _marketingFeeReceiver) external authorized {
        marketingFeeReceiver = _marketingFeeReceiver;
    }



    function setdevelopementFeeReceiver(address _developementFeeReceiver) external authorized {
        marketingFeeReceiver = _developementFeeReceiver;
    }
    

    function setSwapBackSettings(bool _enabled, uint256 _amount) external authorized {
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }
    

    function manualSend() external authorized {
        uint256 contractETHBalance = address(this).balance;
        payable(marketingFeeReceiver).transfer(contractETHBalance);
    }

    function transferERC20(address _token, uint _amount) public authorized {
        require(_amount <= IBEP20(_token).balanceOf(address(this)), "Can't transfer more than the balance");
        IBEP20(_token).transfer(marketingFeeReceiver, _amount);
    }
        
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }
    


}