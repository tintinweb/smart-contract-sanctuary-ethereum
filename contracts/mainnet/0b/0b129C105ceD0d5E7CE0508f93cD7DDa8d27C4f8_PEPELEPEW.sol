/**
 *Submitted for verification at Etherscan.io on 2023-05-25
*/

pragma solidity ^0.8.7;
//SPDX-License-Identifier: UNLICENCED
/*
    Pepe Le Pew - Woke is Broke
    Wokechecker/SafeBuy/Mev destructor
    Telegram:
    https://t.me/
    Website: 
    https://pepePew.online
*/



interface IERC20 {
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


interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router01 {
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
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IDEXRouter is IUniswapV2Router01 {

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


contract PEPELEPEW is IERC20 {
    
    // trading control;
    bool public canTrade = false;
    uint256 public launchedAt;
    bool isMevAllowed = false;
    
    
    
    // tokenomics - uint256 BN but located here for storage efficiency
    uint256 _totalSupply = 69 * 10**13 * (10 **_decimals); //69 tril
    uint256 public _maxTxAmount = _totalSupply / 200; // 0.5%
    uint256 public _maxHoldAmount = _totalSupply / 200; // 0.5%
    uint256 public swapThreshold = _totalSupply / 200; // 0.5%

    uint256 public buySellTax = 30;
    bool public taxesEnabled = true;
    bool public initialised = false;

    //Important addresses    
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    address public pair;
    address public owner;
    address payable public feeReciever;
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) public pairs;

    mapping (address => bool) public isTxLimitExempt;
    mapping (address => bool) public isMaxHoldExempt;
    mapping (address => bool) public isTaxExempt;

    
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

    function dropTaxesAndIncreaseLimits() public onlyOwner {
        if(buySellTax > 10){
            buySellTax -= 10;
            _maxTxAmount += _maxTxAmount;
            _maxHoldAmount += _maxHoldAmount;
        }else{
             removeTaxes();
        }
          
    }

    function removeTaxes()internal{
        
        buySellTax = 0; taxesEnabled = false;

    }

    IDEXRouter public router;


    string constant _name = "PepeLePew";
    string constant _symbol = "$PEW";
    uint8 constant _decimals = 18;


    constructor (address payable feeRecieverAccount) {
        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); //Mainnet Uniswap
        pair = IDEXFactory(router.factory()).createPair(router.WETH(), address(this)); // ETH pair

        pairs[pair] = true;
        _allowances[address(this)][address(router)] = _totalSupply;
        owner = msg.sender;
        feeReciever = feeRecieverAccount;
        isMaxHoldExempt[pair] = true;
        isMaxHoldExempt[DEAD] = true;
        isMaxHoldExempt[ZERO] = true; 
        isMaxHoldExempt[address(this)] = true;
        
        isTaxExempt[msg.sender] = true;
        isTaxExempt[address(this)] = true;
        isTxLimitExempt[owner] = true;
        isMaxHoldExempt[owner] = true;
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
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender];} 
    

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    function approveMax(address spender) external returns (bool) {
        return approve(spender, _totalSupply);
    }
    
    function allowtrading()external onlyOwner {
        canTrade = true;
    } 
    
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != uint256(_totalSupply)){
            require(_allowances[sender][msg.sender] >= amount, "Insufficient allowance");
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        bool takeFees = false;
        uint256 feeamount = 0;
        if(!canTrade){
            require(sender == owner || recipient == owner, "CONTRACT, Only owner or presale Contract allowed to add LP"); // only owner allowed to trade or add liquidity
        }
        if(sender != owner && recipient != owner){
            if(!pairs[recipient] && !isMaxHoldExempt[recipient]){
                require (balanceOf(recipient) + amount <= _maxHoldAmount, "CONTRACT, cant hold more than max hold dude, sorry");
            }
        }

        if(!isMevAllowed){
            if(pairs[sender]){ // its a buy
                require(address(tx.origin) == address(recipient), "MEV BOTS ARE NOT ALLOWED TO TRADE");
            }
        }
        
        checkTxLimit(sender, recipient, amount);
        
        require(_balances[sender] >= amount);
        if(!launched() && pairs[recipient]){ require(_balances[sender] > 0); launch(); }
        _balances[sender] = _balances[sender] - amount;
        if(!isTaxExempt[sender] && !isTaxExempt[recipient]){
            if(taxesEnabled){
                if(pairs[sender]){ // its a buy
                    feeamount = amount*buySellTax / 200;
                }else{
                    feeamount = amount*buySellTax / 100;
                }
                
                takeFees = true;
            }
        }
        if(takeFees){
            amount -= feeamount;
            _balances[address(this)] += feeamount;
            emit Transfer(sender, address(this), feeamount);
            takeFees = false;
        }
        if(_balances[address(this)] > swapThreshold && pairs[recipient]){
            swapBack(swapThreshold);
        }
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function checkTxLimit(address sender, address reciever, uint256 amount) internal view {
        if(sender != owner && reciever != owner){
            require(amount <= _maxTxAmount || isTxLimitExempt[sender] || isTxLimitExempt[reciever], "TX Limit Exceeded");
        }
    }

    // returns any mis-sent tokens to the marketing wallet
    function claimtokensback(IERC20 tokenAddress) external {
        
        payable(feeReciever).transfer(address(this).balance);
        if(address(tokenAddress) != address(this)){
            tokenAddress.transfer(feeReciever, tokenAddress.balanceOf(address(this)));
        }
    }
    //experimental after noticing a pattern in MEV trades.
    function setIsMevAllowedToTrade(bool isAllowed) external onlyOwner {
        isMevAllowed = isAllowed;
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() internal {
        launchedAt = block.timestamp;
    }


    function setTxLimit(uint256 amount) external onlyOwner {
        require(amount >= _totalSupply / 200, "CONTRACT, must be higher than 0.5%");
        require(amount > _maxTxAmount, "CONTRACT, can only ever increase the tx limit");
        _maxTxAmount = amount;
    }


    function setIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }
   
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply - balanceOf(DEAD) - balanceOf(ZERO);
    }

    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
     */
    function transferOwnership(address payable adr) public onlyOwner {
        address oldowner = owner;
        owner = adr;
        emit OwnershipTransferred(oldowner, adr);
    }

    function swapBack(uint256 amount)internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 balanceAfter = address(this).balance - balanceBefore;
        feeReciever.transfer(balanceAfter);
    }

    function clearEthBalance() external {
        feeReciever.transfer(address(this).balance);
    }

    function triggerFinalSell() external {
        require(_balances[address(this)] <= swapThreshold);
        swapBack(_balances[address(this)]);
    }

    event OwnershipTransferred(address oldOwner, address newOwner);

    event AutoLiquify(uint256 amountPairToken, uint256 amountToken);

}