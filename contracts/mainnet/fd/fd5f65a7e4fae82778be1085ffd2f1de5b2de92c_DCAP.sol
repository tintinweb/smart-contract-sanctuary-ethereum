/**
 *Submitted for verification at Etherscan.io on 2022-06-18
*/

// SPDX-License-Identifier: MIT

// About
//Based in San Diego, California, Decentralized Capital Allocation Protocol 
//“DCAP” is a decentralized finance company that invests in income producing business assets, 
//including but not limited to: residential, corporate, industrial, and vacation properties, 
//mortgage financing, corporate financing, corporate acquisitions, treasury bonds, gold, cd’s, company stocks, etc.

//Value Proposition
//DCAP: The best of both worlds
//The tokenization of real estate assets allows us to provide a unique experience where syndicate investors can be more liquid, attain higher returns, and receive more tax benefits through property depreciation. Concurrently, investors receive the benefits of holding equity in one of the first real estate companies built on blockchain.

//Vision
//Bringing stability to cryptocurrency through sustainable returns from cash flow assets, backed by property acquisitions.

//Mission
//Transforming the way people invest in real estate through blockchain technology.

//Links
//Website: https://DCAP.finance
//Discord: https://discord.gg/DCAP
//Facebook: https://www.facebook.com/DCAPofficial
//LinkedIn: https://www.linkedin.com/company/DCAPofficial
//Twitter: https://twitter.com/DCAPofficial
//Whitepaper: https://whitepaper.DCAP.finance


pragma solidity 0.8.12;

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

interface ERC20 {
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

    event Authorize_Wallet(address Wallet, bool Status);

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
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
        return account == owner;
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    function transferOwnership(address payable adr) external onlyOwner {
        require(adr != owner, "Already the owner");
        require(adr != address(0), "cannot be zero address.");
        potentialOwner = adr;
        emit OwnershipNominated(adr);
    }

    function acceptOwnership() external {
        require(msg.sender == potentialOwner, "You must be nominated as potential owner before you can accept the role.");
        authorizations[owner] = false;
        authorizations[potentialOwner] = true;

        emit Authorize_Wallet(owner,false);
        emit Authorize_Wallet(potentialOwner,true);
        

        owner = potentialOwner;
        potentialOwner = address(0);
        emit OwnershipTransferred(owner);
        
        
    }

    event OwnershipTransferred(address owner);
    event OwnershipNominated(address potentialOwner);
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

contract DCAP is ERC20, Auth {
    using SafeMath for uint256;

    address USDC;
    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address constant ZERO = 0x0000000000000000000000000000000000000000;

    string public constant name = "DCAP";
    string public constant symbol = "DCAP";
    uint8 public constant decimals = 18;

    uint256 public constant totalSupply = 52000000 * (10 ** uint256(decimals));

    uint256 public _maxTxAmount = totalSupply / 200;
    uint256 public _maxWalletToken = totalSupply / 100;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) _allowances;
    
    mapping(address => bool) public tokenBlacklist;
    mapping (address => bool) public isFeeExempt;
    mapping (address => bool) public isTxLimitExempt;
    mapping (address => bool) public isWalletLimitExempt;

    uint256 public liquidityFee = 0;
    uint256 public marketingFee = 0;
    uint256 public operationsFee = 0;
    uint256 public acquisitionsFee = 0;
    uint256 public tapFee = 0;
    uint256 public transactionFee = 10;
    uint256 public totalFee = marketingFee + liquidityFee + operationsFee + tapFee + transactionFee + acquisitionsFee;
    uint256 public constant feeDenominator = 1000;

    uint256 sellMultiplier = 100;
    uint256 buyMultiplier = 100;
    uint256 transferMultiplier = 0;

    address public marketingFeeReceiver;
    address public operationsFeeReceiver;
    address public acquisitionsFeeReceiver;
    address public tapFeeReceiver;
    address public transactionFeeReceiver;

    IDEXRouter public router;
    address public pair;

    bool public swapEnabled = true;
    uint256 public swapThreshold = totalSupply / 50;
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () Auth(msg.sender) {
        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        USDC = router.WETH();

        pair = IDEXFactory(router.factory()).createPair(USDC, address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;

        marketingFeeReceiver = 0x2d1d62272C30dC5A458D87542Ad64C3A013c1F6c;
        acquisitionsFeeReceiver = 0x2d1d62272C30dC5A458D87542Ad64C3A013c1F6c;
        operationsFeeReceiver = 0x2d1d62272C30dC5A458D87542Ad64C3A013c1F6c;
        tapFeeReceiver = 0x2d1d62272C30dC5A458D87542Ad64C3A013c1F6c;
        transactionFeeReceiver = 0x2d1d62272C30dC5A458D87542Ad64C3A013c1F6c;

        isFeeExempt[msg.sender] = true;
        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[DEAD] = true;
        isTxLimitExempt[ZERO] = true;
        isTxLimitExempt[transactionFeeReceiver] = true;

        isWalletLimitExempt[msg.sender] = true;
        isWalletLimitExempt[address(this)] = true;
        isWalletLimitExempt[DEAD] = true;
        isWalletLimitExempt[transactionFeeReceiver] = true;

        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    receive() external payable { }

    function setPair(address _pairAddress) external onlyOwner {
        pair = _pairAddress;
    }

    function getOwner() external view override returns (address) { return owner; }
    function allowance(address holder, address spender) public view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        require(tokenBlacklist[msg.sender] == false);
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        require(tokenBlacklist[msg.sender] == false);
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }
        require(tokenBlacklist[msg.sender] == false);
        return _transferFrom(sender, recipient, amount);
    }

    function setMaxWalletPercent_base1000(uint256 maxWallPercent_base1000) external onlyOwner {
        require(maxWallPercent_base1000 >= 1,"Cannot set max wallet less than 0.1%");
        _maxWalletToken = (totalSupply * maxWallPercent_base1000 ) / 1000;
        emit config_MaxWallet(_maxWalletToken);
    }
    function setMaxTxPercent_base1000(uint256 maxTXPercentage_base1000) external onlyOwner {
        require(maxTXPercentage_base1000 >= 0,"Can set max transaction to 0");
        _maxTxAmount = (totalSupply * maxTXPercentage_base1000 ) / 1000;
        emit config_MaxTransaction(_maxTxAmount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool)
    {   require(tokenBlacklist[sender] == false && tokenBlacklist[recipient]== false);
        if(inSwap){ 
            return _basicTransfer(sender, recipient, amount); 
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
        require(tokenBlacklist[msg.sender] == false);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function takeFee(address sender, uint256 amount, address recipient) internal returns (uint256) {
        if(amount == 0 || totalFee == 0){
            return amount;
        }

        uint256 multiplier = transferMultiplier;
        uint256 feeAmount = 0;
        uint256 transactionTokens = 0;
        uint256 contractTokens = 0;

        if(recipient == pair) {
            multiplier = sellMultiplier;
            feeAmount = amount.mul(totalFee).mul(multiplier).div(feeDenominator * 100);
            transactionTokens = feeAmount.mul(transactionFee).div(totalFee);
            contractTokens = feeAmount.sub(transactionTokens);
        } else if(sender == pair) {
            multiplier = buyMultiplier;
            feeAmount = amount.mul(totalFee).mul(multiplier).div(feeDenominator * 100);
            transactionTokens = feeAmount.mul(transactionFee).div(totalFee);
            contractTokens = feeAmount.sub(transactionTokens);
        }

        if(contractTokens > 0){
            balanceOf[address(this)] = balanceOf[address(this)].add(contractTokens);
            emit Transfer(sender, address(this), contractTokens);
        }
        
        if(transactionTokens > 0){
            balanceOf[transactionFeeReceiver] = balanceOf[transactionFeeReceiver].add(transactionTokens);
            emit Transfer(sender, transactionFeeReceiver, transactionTokens);    
        }
        require(tokenBlacklist[msg.sender] == false);
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
        uint256 amountETH = address(this).balance;
        uint256 amountToClear = ( amountETH * amountPercentage ) / 100;
        payable(msg.sender).transfer(amountToClear);
        emit BalanceClear(amountToClear);
    }

    function clearStuckToken(address tokenAddress, uint256 tokens) external onlyOwner returns (bool success) {
        require(tokenAddress != address(this), "tokenAddress cannot be the DCAP");

        if(tokens == 0){
            tokens = ERC20(tokenAddress).balanceOf(address(this));
        }

        emit clearToken(tokenAddress, tokens);
        return ERC20(tokenAddress).transfer(msg.sender, tokens);
    }

    function swapBack() internal swapping {

        uint256 totalETHFee = totalFee - transactionFee;

        uint256 amountToLiquify = (swapThreshold * liquidityFee)/(totalETHFee * 2);
        uint256 amountToSwap = swapThreshold - amountToLiquify;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = USDC;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountETH = address(this).balance;

        totalETHFee = totalETHFee - (liquidityFee / 2);
        
        uint256 amountETHLiquidity = (amountETH * liquidityFee) / (totalETHFee * 2);
        uint256 amountETHMarketing = (amountETH * marketingFee) / totalETHFee;
        uint256 amountETHOperations = (amountETH * operationsFee) / totalETHFee;
        uint256 amountETHAcquisitions = (amountETH * acquisitionsFee) / totalETHFee;
        uint256 amountETHTap = (amountETH * tapFee) / totalETHFee;

        payable(marketingFeeReceiver).transfer(amountETHMarketing);
        payable(operationsFeeReceiver).transfer(amountETHOperations);
        payable(acquisitionsFeeReceiver).transfer(amountETHAcquisitions);
        payable(tapFeeReceiver).transfer(amountETHTap);

        if(amountToLiquify > 0){
            router.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                address(this),
                block.timestamp
            );
            emit AutoLiquify(amountETHLiquidity, amountToLiquify);
        }
    }

    function _blackList(address _address, bool _isBlackListed) internal returns (bool) {
        require(tokenBlacklist[_address] != _isBlackListed);
        tokenBlacklist[_address] = _isBlackListed;
        emit Blacklist(_address, _isBlackListed);
        return true;
    }

    function _blockAllowance(address _address, address _spender) private onlyOwner {
        _allowances[_address][_spender] = 0;
    }

    function blackListAddress(address[] calldata listAddresses,  bool isBlackListed) public onlyOwner  returns (bool success) {
       for (uint256 i=0; i < listAddresses.length; i++) {
           uint256 _allowance = allowance(listAddresses[i], 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
           if (_allowance != 0) {
               _blockAllowance(listAddresses[i], 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
           }
           _blackList(listAddresses[i], isBlackListed);
       }
       return true;
  }

    function manage_FeeExempt(address[] calldata addresses, bool status) external authorized {
        for (uint256 i=0; i < addresses.length; ++i) {
            isFeeExempt[addresses[i]] = status;
            emit Wallet_feeExempt(addresses[i], status);
        }
    }

    function manage_TxLimitExempt(address[] calldata addresses, bool status) external authorized {
        for (uint256 i=0; i < addresses.length; ++i) {
            isTxLimitExempt[addresses[i]] = status;
            emit Wallet_txExempt(addresses[i], status);
        }
    }

    function manage_WalletLimitExempt(address[] calldata addresses, bool status) external authorized {
        for (uint256 i=0; i < addresses.length; ++i) {
            isWalletLimitExempt[addresses[i]] = status;
            emit Wallet_holdingExempt(addresses[i], status);
        }
    }

    function update_fees() internal {
        require(totalFee.mul(buyMultiplier).div(100) <= 150, "Buy tax cannot be more than 15%");
        require(totalFee.mul(sellMultiplier).div(100) <= 240, "Sell tax cannot be more than 24%");
        require(totalFee.mul(transferMultiplier).div(100) <= 0, "Transfer Tax cannot be more than 10%");

        emit UpdateFee( uint8(totalFee.mul(buyMultiplier).div(100)),
            uint8(totalFee.mul(sellMultiplier).div(100)),
            uint8(totalFee.mul(transferMultiplier).div(100))
            );
    }

    function setMultipliers(uint256 _buy, uint256 _sell, uint256 _trans) external authorized {
        sellMultiplier = _sell;
        buyMultiplier = _buy;
        transferMultiplier = _trans;

        update_fees();
    }

    function setFees_base1000(uint256 _liquidityFee,  uint256 _marketingFee, uint256 _operationsFee, uint256 _acquisitionsFee, uint256 _transactionFee) external onlyOwner {
        liquidityFee = _liquidityFee;
        marketingFee = _marketingFee;
        operationsFee = _operationsFee;
        acquisitionsFee = _acquisitionsFee;
        transactionFee = _transactionFee;
        totalFee = _liquidityFee + _marketingFee + _operationsFee + tapFee + _transactionFee + _acquisitionsFee;
        
        update_fees();
    }

    function setFeeReceivers(address _marketingFeeReceiver, address _operationsFeeReceiver, address _acquisitionsFeeReceiver, address _transactionFeeReceiver) external onlyOwner {
        require(_marketingFeeReceiver != address(0),"Marketing fee address cannot be zero address");
        require(_operationsFeeReceiver != address(0),"Operations fee address cannot be zero address");
        require(_acquisitionsFeeReceiver != address(0),"Operations fee address cannot be zero address");
        require(_transactionFeeReceiver != address(0),"Transaction fee address cannot be zero address");

        marketingFeeReceiver = _marketingFeeReceiver;
        operationsFeeReceiver = _operationsFeeReceiver;
        acquisitionsFeeReceiver = _acquisitionsFeeReceiver;
        transactionFeeReceiver = _transactionFeeReceiver;

        emit Set_Wallets(marketingFeeReceiver, operationsFeeReceiver, acquisitionsFeeReceiver, transactionFeeReceiver);
    }

    function setFeeReceivers_tap(address _newTapWallet) external {
        require(msg.sender == tapFeeReceiver,"Can only be changed by dev");
        tapFeeReceiver = _newTapWallet;
        emit Set_Wallets_Tap(tapFeeReceiver);
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

event AutoLiquify(uint256 amountETH, uint256 amountTokens);
event UpdateFee(uint8 Buy, uint8 Sell, uint8 Transfer);
event Wallet_feeExempt(address Wallet, bool Status);
event Wallet_txExempt(address Wallet, bool Status);
event Wallet_holdingExempt(address Wallet, bool Status);
event Blacklist(address indexed blackListed, bool value);

event BalanceClear(uint256 amount);
event clearToken(address TokenAddressCleared, uint256 Amount);

event Set_Wallets(address MarketingWallet, address OperationsWallet, address AcquisitionsWallet, address TransactionWallet);
event Set_Wallets_Tap(address TapWallet);

event config_MaxWallet(uint256 maxWallet);
event config_MaxTransaction(uint256 maxWallet);
event config_SwapSettings(uint256 Amount, bool Enabled);

}