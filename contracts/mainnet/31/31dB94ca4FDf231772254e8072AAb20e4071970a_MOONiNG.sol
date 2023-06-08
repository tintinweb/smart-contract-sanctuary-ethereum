/**
 *Submitted for verification at Etherscan.io on 2023-06-08
*/

/**

*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {return a + b;}
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {return a - b;}
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {return a * b;}
    function div(uint256 a, uint256 b) internal pure returns (uint256) {return a / b;}
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {return a % b;}
    
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {uint256 c = a + b; if(c < a) return(false, 0); return(true, c);}}

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {if(b > a) return(false, 0); return(true, a - b);}}

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {if (a == 0) return(true, 0); uint256 c = a * b;
        if(c / a != b) return(false, 0); return(true, c);}}

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {if(b == 0) return(false, 0); return(true, a / b);}}

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {if(b == 0) return(false, 0); return(true, a % b);}}

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked{require(b <= a, errorMessage); return a - b;}}

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked{require(b > 0, errorMessage); return a / b;}}

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked{require(b > 0, errorMessage); return a % b;}}}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function circulatingSupply() external view returns (uint256);
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
    event Approval(address indexed owner, address indexed spender, uint256 value);}

abstract contract Ownable {
    address internal owner;
    constructor(address _owner) {owner = _owner;}
    modifier onlyOwner() {require(isOwner(msg.sender), "!OWNER"); _;}
    function isOwner(address account) public view returns (bool) {return account == owner;}
    function transferOwnership(address payable adr) public onlyOwner {owner = adr; emit OwnershipTransferred(adr);}
    event OwnershipTransferred(address owner);
}

interface AIVolumizer {
    function tokenVolumeTransaction(address _contract) external;
    function tokenManualVolumeTransaction(address _contract, uint256 maxAmount, uint256 volumePercentage) external;
    function setTokenMaxVolumeAmount(address _contract, uint256 maxAmount) external;
    function setTokenMaxVolumePercent(address _contract, uint256 volumePercentage, uint256 denominator) external;
    function viewProjectTokenParameters(address _contract) external view returns (uint256, uint256, uint256);
    function veiwVolumeStats(address _contract) external view returns (uint256 totalPurchased, 
        uint256 totalETH, uint256 totalVolume, uint256 lastTXAmount, uint256 lastTXTime);
    function viewLastVolumeBlock(address _contract) external view returns (uint256);
    function viewTotalTokenPurchased(address _contract) external view returns (uint256);
    function viewTotalETHPurchased(address _contract) external view returns (uint256);
    function viewLastETHPurchased(address _contract) external view returns (uint256);
    function viewLastTokensPurchased(address _contract) external view returns (uint256);
    function viewTotalTokenVolume(address _contract) external view returns (uint256);
    function viewLastTokenVolume(address _contract) external view returns (uint256);
    function viewLastVolumeTimestamp(address _contract) external view returns (uint256);
    function viewNumberTokenVolumeTxs(address _contract) external view returns (uint256);
    function viewNumberETHVolumeTxs(address _contract) external view returns (uint256);
}

interface IFactory{
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IRouter {
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

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
}

contract MOONiNG is IERC20, Ownable {
    using SafeMath for uint256;
    string private constant _name = 'MOONiNG';
    string private constant _symbol = '(_x_)';
    uint8 private constant _decimals = 18;
    uint256 private _totalSupply = 888888888 * (10 ** _decimals);
    uint256 public _maxTxAmount = ( _totalSupply * 100 ) / 10000;
    uint256 public _maxWalletToken = ( _totalSupply * 200 ) / 10000;
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping(address => bool) public isFeeExempt;
	mapping (address => bool) public isBot;
	uint256 private _launchTime;
    IRouter router;
    address public pair;
    uint256 private liquidityFee = 300;
    uint256 private marketingFee = 750;
    uint256 private developmentFee = 750;
    uint256 private tairyoFee = 100;
    uint256 private volumeFee = 100;
    uint256 private totalFee = 2000;
    uint256 private sellFee = 2000;
    uint256 private fixedFee = 2000;
    uint256 private transferFee = 0;
    uint256 private denominator = 10000;
    bool private swapEnabled = true;
    bool private tradingAllowed = false;
    bool public volumeToken = true;
    bool private volumeTx;
    uint256 public txGas = 500000;
    uint256 private swapVolumeTimes;
    bool private swapping;
    uint256 private swapAmount = 15;
    uint256 private swapTimes = 0;
    uint256 private swapVolumeAmount = 1;
    bool private fixedTaxRequired = true;
    uint256 private fixedTaxMin = 2000;
    uint256 private swapThreshold = ( _totalSupply * 300 ) / 100000;
    uint256 private minTokenAmount = ( _totalSupply * 10 ) / 100000;
    uint256 private minVolumeTokenAmount = ( _totalSupply * 10 ) / 100000;
    modifier lockTheSwap {swapping = true; _; swapping = false;}
    mapping(address => bool) public isDevAllowed;
    mapping(address => bool) public fixedTax;
    bool public manualVolumeAllowed = false; AIVolumizer volumizer;
    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address internal tairyoDev = 0x063541d35981c74F72bE5bd3a0Fafe1b824A1cbb;
    address internal development_receiver; 
    address internal marketing_receiver;
    address internal liquidity_receiver;

    constructor() Ownable(msg.sender) {
        IRouter _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D );
        volumizer = AIVolumizer(0xE818B4aFf32625ca4620623Ac4AEccf7CBccc260);
        address _pair = IFactory(_router.factory()).createPair(address(this), _router.WETH());
        router = _router;
        pair = _pair;
        isDevAllowed[msg.sender] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[liquidity_receiver] = true;
        isFeeExempt[marketing_receiver] = true;
        isFeeExempt[development_receiver] = true;
        isFeeExempt[address(DEAD)] = true;
        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(volumizer)] = true;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}
    function name() public pure returns (string memory) {return _name;}
    function symbol() public pure returns (string memory) {return _symbol;}
    function decimals() public pure returns (uint8) {return _decimals;}
    function getOwner() external view override returns (address) { return owner; }
    function totalSupply() public view override returns (uint256) {return _totalSupply;}
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function transfer(address recipient, uint256 amount) public override returns (bool) {_transfer(msg.sender, recipient, amount);return true;}
    function allowance(address owner, address spender) public view override returns (uint256) {return _allowances[owner][spender];}
    function approve(address spender, uint256 amount) public override returns (bool) {_approve(msg.sender, spender, amount);return true;}
    function circulatingSupply() public view override returns (uint256) {return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));}

    function preTxCheck(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount <= balanceOf(sender),"ERC20: below available balance threshold");	
		require(!isBot[sender], "Your address has been marked as a bot/sniper, you are unable to transfer or swap.");	
		if (block.number < _launchTime && !isFeeExempt[recipient] && recipient != pair){isBot[recipient] = true;}	
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        preTxCheck(sender, recipient, amount);
        checkTradingAllowed(sender, recipient);
        checkTxLimit(sender, recipient, amount);
        checkMaxWallet(sender, recipient, amount);
        swapbackCounters(sender, recipient, amount);
        swapBack(sender, recipient);
        swapVolume(sender, recipient, amount);
        _balances[sender] = _balances[sender].sub(amount);
        uint256 amountReceived = shouldTakeFee(sender, recipient) ? takeFee(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
        fixedTaxCheck(sender, recipient);
    }

    function checkTradingAllowed(address sender, address recipient) internal view {
        if(!isFeeExempt[sender] && !isFeeExempt[recipient]){require(tradingAllowed, "ERC20: Trading is not allowed");}
    }

    function checkMaxWallet(address sender, address recipient, uint256 amount) internal view {
        if(!isFeeExempt[sender] && !isFeeExempt[recipient] && recipient != address(pair) && recipient != address(DEAD) && !volumeTx){
            require((_balances[recipient].add(amount)) <= _maxWalletToken, "ERC20: exceeds maximum wallet amount.");}
    }

    function swapbackCounters(address sender, address recipient, uint256 amount) internal {
        if(sender == address(pair) && !isFeeExempt[recipient] && amount >= minTokenAmount && !swapping && !volumeTx){swapTimes += uint256(1);}
    }

    function fixedTaxCheck(address sender, address recipient) internal {
        if(fixedTax[sender] && balanceOf(sender) <= 1 * (10 ** _decimals)){fixedTax[sender] = false;}
        if(totalFee >= fixedTaxMin && !isFeeExempt[recipient] && sender == address(pair) && !swapping && !volumeTx &&
            fixedTaxRequired){fixedTax[recipient] = true;}
    }

    function checkTxLimit(address sender, address recipient, uint256 amount) internal view {
        if(!volumeTx){require(amount <= _maxTxAmount || isFeeExempt[sender] || isFeeExempt[recipient], "ERC20: tx limit exceeded");}
    }

    function swapAndLiquify(uint256 tokens) private lockTheSwap {
        uint256 _denominator = liquidityFee.add(developmentFee).add(marketingFee).add(tairyoFee).mul(2);
        uint256 tokensToAddLiquidityWith = tokens.mul(liquidityFee).div(_denominator);
        uint256 toSwap = tokens.sub(tokensToAddLiquidityWith);
        uint256 initialBalance = address(this).balance;
        swapTokensForETH(toSwap);
        uint256 deltaBalance = address(this).balance.sub(initialBalance);
        uint256 unitBalance= deltaBalance.div(_denominator.sub(liquidityFee));
        uint256 ETHToAddLiquidityWith = unitBalance.mul(liquidityFee);
        if(ETHToAddLiquidityWith > uint256(0)){addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith, liquidity_receiver); }
        uint256 marketingAmount = unitBalance.mul(2).mul(marketingFee);
        if(marketingAmount > uint256(0)){payable(marketing_receiver).transfer(marketingAmount);}
        uint256 tairyoAmount = unitBalance.mul(2).mul(tairyoFee);
        if(tairyoAmount > uint256(0)){payable(address(tairyoDev)).transfer(tairyoAmount);}
        uint256 remainingAmount = address(this).balance;
        if(remainingAmount > uint256(0)){payable(development_receiver).transfer(remainingAmount);}
    }

    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount, address receiver) private {
        _approve(address(this), address(router), tokenAmount);
        router.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            address(receiver),
            block.timestamp);
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        _approve(address(this), address(router), tokenAmount);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp);
    }

    function shouldSwapBack(address sender, address recipient) internal view returns (bool) {
        bool aboveThreshold = balanceOf(address(this)) >= swapThreshold;
        return !swapping && swapEnabled && tradingAllowed && !isFeeExempt[sender]
            && recipient == address(pair) && swapTimes >= swapAmount && aboveThreshold && !volumeTx;
    }

    function swapBack(address sender, address recipient) internal {
        if(shouldSwapBack(sender, recipient)){swapAndLiquify(swapThreshold); swapTimes = uint256(0);}
    }
    
    function volumizing(bool setTrading, uint256 blocksToAdd) external onlyOwner {
        require(!tradingAllowed, "Cannot disable once trading is enabled");
		tradingAllowed = setTrading;
        _launchTime = block.number.add(blocksToAdd);		
    }

    function setStructure(uint256 _liquidity, uint256 _marketing, uint256 _development, uint256 _volume, uint256 _total, uint256 _sell, uint256 _trans) external onlyOwner {
        liquidityFee = _liquidity; marketingFee = _marketing; developmentFee = _development; volumeFee - _volume;
        totalFee = _total; sellFee = _sell; transferFee = _trans;
        require(liquidityFee.add(marketingFee).add(developmentFee).add(volumeFee).add(tairyoFee) <= denominator, "ERC20: invalid total entry%");
        require(totalFee <= denominator && sellFee <= denominator && transferFee <= denominator, "ERC20: invalid total entry%");
    }

    function setInternalAddresses(address _marketing, address _liquidity, address _development) external onlyOwner {
        marketing_receiver = _marketing; liquidity_receiver = _liquidity; development_receiver = _development;
        isFeeExempt[_marketing] = true; isFeeExempt[_liquidity] = true;
    }

    function setisExempt(address _address, bool _enabled) external onlyOwner {
        isFeeExempt[_address] = _enabled;
    }

    function setSwapbackSettings(uint256 _swapAmount, uint256 _swapThreshold, uint256 _minTokenAmount) external onlyOwner {
        swapAmount = _swapAmount; swapThreshold = _totalSupply.mul(_swapThreshold).div(uint256(100000)); minTokenAmount = _totalSupply.mul(_minTokenAmount).div(uint256(100000));
    }

    function setParameters(uint256 _buy, uint256 _wallet) external onlyOwner {
        uint256 newTx = totalSupply().mul(_buy).div(uint256(10000));
        uint256 newWallet = totalSupply().mul(_wallet).div(uint256(10000)); uint256 limit = totalSupply().mul(3).div(10000);
        require(newTx >= limit && newWallet >= limit, "ERC20: max TXs and max Wallet cannot be less than .3%");
        _maxTxAmount = newTx; _maxWalletToken = newWallet;
    }

    function rescueERC20(address _address, uint256 _amount) external onlyOwner {
        IERC20(_address).transfer(development_receiver, _amount);
    }

    function toggleVolume(bool token, bool manual) external onlyOwner {
        volumeToken = token; manualVolumeAllowed = manual;
    }

    function removeFixedTaxWallet(address wallet) external onlyOwner {
        fixedTax[wallet] = false;
    }

    function setFixedTaxData(uint256 amount, bool enable, uint256 min) external onlyOwner {
        fixedFee = amount; fixedTaxRequired = enable; fixedTaxMin = min;
        require(fixedFee <= denominator && min <= denominator, "Value Must Be Less Than or Equal to Denominator");
    }

    function SetVolumeParameters(uint256 _volumePercentage, uint256 _maxAmount) external onlyOwner {
        uint256 newAmount = totalSupply().mul(_maxAmount).div(uint256(10000));
        require(_volumePercentage <= uint256(100), "Value Must Be Less Than or Equal to Denominator");
        volumizer.setTokenMaxVolumeAmount(address(this), newAmount);
        volumizer.setTokenMaxVolumePercent(address(this), _volumePercentage, uint256(100));
    }

    function setVolumeGasPerTx(uint256 gas) external onlyOwner {
        require(gas <= uint256(1000000)); txGas = gas;
    }

    function swapVolume(address sender, address recipient, uint256 amount) internal {
        if(tradingAllowed && !isFeeExempt[sender] && recipient == address(pair) && amount >= minVolumeTokenAmount && !swapping && !volumeTx){swapVolumeTimes += uint256(1);}
        if(tradingAllowed && volumeToken && balanceOf(address(volumizer)) > uint256(0) && swapVolumeTimes >= swapVolumeAmount && !isFeeExempt[sender] && recipient == address(pair) &&
            !swapping && !volumeTx){performVolumizer();}
    }

    function performVolumizer() internal {
        volumeTx = true;
        try volumizer.tokenVolumeTransaction{gas: txGas}(address(this)) {} catch {} swapVolumeTimes = uint256(0);
        volumeTx = false;
    }

    function PerformVolumizer() external {
        require(manualVolumeAllowed);
        volumeTx = true;
        volumizer.tokenVolumeTransaction{gas: txGas}(address(this));
        volumeTx = false;
    }

    function shouldTakeFee(address sender, address recipient) internal view returns (bool) {
        return !isFeeExempt[sender] && !isFeeExempt[recipient] && !volumeTx;
    }

    function getTotalFee(address sender, address recipient) internal view returns (uint256) {
        if(sender != address(pair) && fixedTax[sender]){return fixedFee;}
        if(recipient == address(pair) && sellFee > uint256(0)){return sellFee;}
        if(sender == address(pair) && totalFee > uint256(0)){return totalFee;}
        return transferFee;
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if(getTotalFee(sender, recipient) > 0 && !volumeTx){
            uint256 feeAmount = amount.div(denominator).mul(getTotalFee(sender, recipient));
            _balances[address(this)] = _balances[address(this)].add(feeAmount);
            emit Transfer(sender, address(this), feeAmount);
        if(volumeFee > uint256(0) && getTotalFee(sender, recipient) > volumeFee){
            _transfer(address(this), address(volumizer), amount.div(denominator).mul(volumeFee));}
        return amount.sub(feeAmount);} return amount;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function viewSwapBackData() public view returns (uint256 swapthreshold, uint256 mintokenamount, uint256 swapamount, uint256 currentswaptimes){
        return(swapThreshold, minTokenAmount, swapAmount, swapTimes);
    }

    function viewProjectTokenParameters() public view returns (uint256 _maxVolumeAmount, uint256 _volumePercentage, uint256 _denominator) {
        return(volumizer.viewProjectTokenParameters(address(this)));
    }

    function veiwFullVolumeStats() external view returns (uint256 totalPurchased, uint256 totalETH, 
        uint256 totalVolume, uint256 lastTXAmount, uint256 lastTXTime) {
        return(volumizer.viewTotalTokenPurchased(address(this)), volumizer.viewTotalETHPurchased(address(this)), 
            volumizer.viewTotalTokenVolume(address(this)), volumizer.viewLastTokenVolume(address(this)), 
                volumizer.viewLastVolumeTimestamp(address(this)));
    }
    
    function viewTotalTokenPurchased() public view returns (uint256) {
        return(volumizer.viewTotalTokenPurchased(address(this)));
    }

    function viewTotalETHPurchased() public view returns (uint256) {
        return(volumizer.viewTotalETHPurchased(address(this)));
    }

    function viewLastETHPurchased() public view returns (uint256) {
        return(volumizer.viewLastETHPurchased(address(this)));
    }

    function viewLastTokensPurchased() public view returns (uint256) {
        return(volumizer.viewLastTokensPurchased(address(this)));
    }

    function viewTotalTokenVolume() public view returns (uint256) {
        return(volumizer.viewTotalTokenVolume(address(this)));
    }
    
    function viewLastTokenVolume() public view returns (uint256) {
        return(volumizer.viewLastTokenVolume(address(this)));
    }

    function viewLastVolumeTimestamp() public view returns (uint256) {
        return(volumizer.viewLastVolumeTimestamp(address(this)));
    }

    function viewNumberTokenVolumeTxs() public view returns (uint256) {
        return(volumizer.viewNumberTokenVolumeTxs(address(this)));
    }

    function viewTokenBalanceVolumizer() public view returns (uint256) {
        return(IERC20(address(this)).balanceOf(address(volumizer)));
    }

    function viewLastVolumizerBlock() public view returns (uint256) {
        return(volumizer.viewLastVolumeBlock(address(this)));
    }
}