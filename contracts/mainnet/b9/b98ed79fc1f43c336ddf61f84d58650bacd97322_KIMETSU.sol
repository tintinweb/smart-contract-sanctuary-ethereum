/**
 *Submitted for verification at Etherscan.io on 2022-10-07
*/

/**
 
Kimetsu 鬼滅 👹

Telegram: https://t.me/KimetsuETH

Website: https://kimestueth.com

*/

// SPDX-License-Identifier: Unlicense
pragma solidity =0.8.17;

interface ERC20 {
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
    constructor(address _owner) {
        owner = _owner;
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "Owner-restricted function");
         _;
    }    
    function renounceOwnership() public onlyOwner {
        owner = address(0);
        emit OwnershipTransferred(address(0));
    }  
    event OwnershipTransferred(address owner);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract KIMETSU  is ERC20, Ownable {

    string constant _name = unicode"Kimetsu 鬼滅";
    string constant _symbol = "KIMETSU";
    uint8 constant _decimals = 9;

    uint256 constant _totalSupply = 1_000_000 * (10 ** _decimals);

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    bool public tradingOpened = false;

    mapping (address => bool) markedSniper;
    bool antiBotActive = false;
    uint256 finalDeadBlock;    
    
    mapping (address => uint256) lastTxBlock;
    uint256 constant txCooldownBlocks = 1;
    
    uint256 public maxTxAmount = 2 * _totalSupply / 100; // 2%
    uint256 public maxWalletAmount = 3 * _totalSupply / 100; // 2%

    mapping (address => bool) isFeeExempt;

    uint256 public finalFeeTimestamp;
    uint256 constant public finalFeePercent = 6; // 
    uint256 constant public startingFeePercent = 10; //
    uint256 constant public feeDenominator = 100;

    address payable immutable public projectFeeReceiver = payable(msg.sender);

    address constant routerAdress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;               
    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address constant ZERO = address(0x0);

    IDEXRouter public immutable router;
    address immutable public pair;

    uint256 immutable public swapThreshold = _totalSupply / 1_000; // 0.1%
    bool inSwap;

    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () Ownable(msg.sender) {
        router = IDEXRouter(routerAdress);
        pair = IDEXFactory(router.factory()).createPair(router.WETH(), address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;

        address _owner = owner;        
        _balances[_owner] = _totalSupply;
        emit Transfer(address(0), _owner, _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external pure returns (uint256) { return _totalSupply; }
    function decimals() external pure returns (uint8) { return _decimals; }
    function symbol() external pure returns (string memory) { return _symbol; }
    function name() external pure returns (string memory) { return _name; }
    function getOwner() external view returns (address) { return owner; }
    function balanceOf(address account) public view returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            uint256 currentAllowance = _allowances[sender][msg.sender];
            require(currentAllowance >= amount, "Insufficient Allowance");
            unchecked{
                _allowances[sender][msg.sender] -= amount;
            }
        }
        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(inSwap || sender == projectFeeReceiver || recipient == projectFeeReceiver){
            return _basicTransfer(sender, recipient, amount);
        }
        else if(amount == 0){
            return _basicTransfer(sender, recipient, 0);
        }

        // Pre-trader check
        require(tradingOpened, "Trading disabled");

        // Sniper check
        require(!markedSniper[sender], "Snipers can't trade");     

        // Max tx/wallet check
        if (recipient != DEAD && recipient != ZERO) {            
            require(amount <= maxTxAmount, "Excessive transfer amount");
            require(recipient == pair || _balances[recipient] + amount <= maxWalletAmount, 
                "Excessive receiver token holdings");
        }           
        
        // Trade cooldown check
        require(block.number - lastTxBlock[tx.origin] >= txCooldownBlocks, "Transactions too frequent"); 
        lastTxBlock[tx.origin] = block.number;

        if((shouldMarkSniper(sender, recipient))){
              markedSniper[recipient] = true;
        }                        
        else if(shouldSwapBack(sender)){
            swapBack();             
        }
        
        uint256 balanceSender = _balances[sender];
        require(balanceSender >= amount, "Insufficient Balance");
        unchecked{
            _balances[sender] -= amount;
        }

        uint256 amountReceived = shouldTakeFee(sender, recipient) ? takeFee(sender, amount) : amount;
        _balances[recipient] += amountReceived;

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        uint256 balanceSender = _balances[sender];
        require(balanceSender >= amount, "Insufficient Balance");
        unchecked{
            _balances[sender] -= amount;
        }
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function shouldMarkSniper(address sender, address recipient) internal view returns (bool) {
        return antiBotActive && sender == pair && block.number <= finalDeadBlock && 
         recipient != address(this) && recipient != routerAdress && recipient != pair;
    }

    function shouldTakeFee(address sender, address recipient) internal view returns (bool) {
        return !(isFeeExempt[sender] || isFeeExempt[recipient]);
    }

    function takeFee(address sender, uint256 amount) internal returns (uint256) {
        uint256 feeAmount;
        if(block.timestamp < finalFeeTimestamp){
            feeAmount = amount * startingFeePercent / feeDenominator;
        }else{
            feeAmount = amount * finalFeePercent / feeDenominator;
        }                       
        _balances[address(this)] += feeAmount;
        emit Transfer(sender, address(this), feeAmount);        
        return amount - feeAmount;
    }

    function shouldSwapBack(address sender) internal view returns (bool) {
        return sender != pair && _balances[address(this)] >= swapThreshold;
    }

    function swapBack() internal swapping {
        uint256 tokenBalance = _balances[address(this)];
        uint256 tokensToSwap = tokenBalance >= maxTxAmount ? maxTxAmount : tokenBalance;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokensToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        unchecked{
            uint256 amountETH = address(this).balance - balanceBefore;            
            (bool success,)  = projectFeeReceiver.call{value: amountETH, gas: 30000}(""); success;
        }
    }

    function openTrading(uint256 numdeadBlocks, uint256 finalFeeDelayMinutes, bool _antiBotActive) external onlyOwner {
        require(!tradingOpened, "Trading already enabled");
        tradingOpened = true;
        antiBotActive = _antiBotActive;
        finalFeeTimestamp = block.timestamp + finalFeeDelayMinutes * 60;
        finalDeadBlock = block.number + numdeadBlocks;
    }
    
    function setMaxAmount(uint256 _maxWalletAmount) external onlyOwner {
        require(_maxWalletAmount >= _totalSupply / 100, "MaxWalletAmount needs to be higher than 1% of total supply");
        maxWalletAmount = _maxWalletAmount;
    }
    
    function setMaxTx(uint256 _maxTxAmount) external onlyOwner {
        require(_maxTxAmount >= _totalSupply / 100, "MaxTxAmount needs to be higher than 1% of total supply");
        maxTxAmount = _maxTxAmount;
    }

    function removeLimits() external onlyOwner {
        maxWalletAmount = type(uint256).max;
        maxTxAmount = type(uint256).max;
    }

    function excludeFromFee(address account, bool excluded) external onlyOwner {
        isFeeExempt[account] = excluded;
    }  

    function excludeMultipleFromFee(address[] calldata accounts, bool excluded) external onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            isFeeExempt[accounts[i]] = excluded;
        }
    }

    function markSniper(address account) external onlyOwner {
        require(account != routerAdress && account != address(this) && account != pair, "Invalid sniper");
        markedSniper[account] = true;
    }
    
    function unmarkSniper(address account) external onlyOwner {       
        markedSniper[account] = false;
    }

    function clearStuckTokenBalance() external {
        require(msg.sender == projectFeeReceiver, "Deployer-restricted function");
        swapBack();                    
    }

    function clearStuckETHBalance() external {
        projectFeeReceiver.transfer(address(this).balance);
    }

    
}