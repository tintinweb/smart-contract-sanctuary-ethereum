/**
 *Submitted for verification at Etherscan.io on 2022-10-16
*/

//SPDX-License-Identifier: MIT
// Do Your Own Research ser. (SAFU)
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

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

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

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

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

contract DoYourOwnResearch is ERC20, Ownable{
    using Address for address payable;
    
    IRouter public router;
    address public pair;
    
    bool private swapping;
    bool public swapEnabled;
    bool public tradingEnabled;

    uint256 public genesis_block;
    uint256 public deadblocks = 0;
    
    uint256 public swapThreshold = 1_000 * 10e18;
    uint256 public maxTxAmount = 20_200 * 10**18;
    uint256 public maxWalletAmount = 20_200 * 10**18;
    
    address public marketingWallet = 0x1a9E49F4b09D05Cf3f4fc868ff3F7d064FC715cB;
    address public developerWallet = 0x1a9E49F4b09D05Cf3f4fc868ff3F7d064FC715cB;
    
    struct Taxes {
        uint256 marketing;
        uint256 liquidity; 
        uint256 developer;
    }
    
    Taxes public taxes = Taxes(4,0,0);
    Taxes public sellTaxes = Taxes(4,0,0);
    uint256 public totTax = 4;
    uint256 public totSellTax = 4;
    
    mapping (address => bool) public excludedFromFees;
    mapping (address => bool) public isBot;
    
    modifier inSwap() {
        if (!swapping) {
            swapping = true;
            _;
            swapping = false;
        }
    }
        
    constructor() ERC20("DoYourOwnResearch", "DYOR") {
        _mint(msg.sender, 1e6 * 10**decimals());
        excludedFromFees[msg.sender] = true;

        IRouter _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IFactory(_router.factory())
            .createPair(address(this), _router.WETH());

        router = _router;
        pair = _pair;
        excludedFromFees[address(this)] = true;
        excludedFromFees[marketingWallet] = true;
        excludedFromFees[developerWallet] = true;
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal override {
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!isBot[sender] && !isBot[recipient], "You can't transfer tokens");
                
        
        if(!excludedFromFees[sender] && !excludedFromFees[recipient] && !swapping){
            require(tradingEnabled, "Trading not active yet");
            if(genesis_block + deadblocks > block.number){
                if(recipient != pair) isBot[recipient] = true;
                if(sender != pair) isBot[sender] = true;
            }
            require(amount <= maxTxAmount, "You are exceeding maxTxAmount");
            if(recipient != pair){
                require(balanceOf(recipient) + amount <= maxWalletAmount, "You are exceeding maxWalletAmount");
            }
        }

        uint256 fee;

        if (swapping || excludedFromFees[sender] || excludedFromFees[recipient]) fee = 0;
        
        else{
            if(recipient == pair) fee = amount * totSellTax / 100;
            else fee = amount * totTax / 100;
        }

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
    
            uint256 marketingAmt = unitBalance * 2 * sellTaxes.marketing;
            if(marketingAmt > 0){
                payable(marketingWallet).sendValue(marketingAmt);
            }
            
            uint256 developerAmt = unitBalance * 2 * sellTaxes.developer;
            if(developerAmt > 0){
                payable(developerWallet).sendValue(developerAmt);
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
            developerWallet,
            block.timestamp
        );
    }

    function setSwapEnabled(bool state) external onlyOwner {
        swapEnabled = state;
    }

    function setSwapThreshold(uint256 new_amount) external onlyOwner {
        swapThreshold = new_amount;
    }

    function enableTrading(uint256 numOfDeadBlocks) external onlyOwner {
        require(!tradingEnabled, "Trading already active");
        tradingEnabled = true;
        swapEnabled = true;
        genesis_block = block.number;
        deadblocks = numOfDeadBlocks;
    }

    function setTaxes(uint256 _marketing, uint256 _liquidity, uint256 _developer) external onlyOwner{
        taxes = Taxes(_marketing, _liquidity, _developer);
        totTax = _marketing + _liquidity + _developer;
    }

    function setSellTaxes(uint256 _marketing, uint256 _liquidity, uint256 _developer) external onlyOwner{
        sellTaxes = Taxes(_marketing, _liquidity, _developer);
        totSellTax = _marketing + _liquidity + _developer;
    }
    
    function updateMarketingWallet(address newWallet) external onlyOwner{
        marketingWallet = newWallet;
    }
    
    function updateDeveloperWallet(address newWallet) external onlyOwner{
        developerWallet = newWallet;
    }

    function updateRouterAndPair(IRouter _router, address _pair) external onlyOwner{
        router = _router;
        pair = _pair;
    }

    function addBot(address account) external onlyOwner{
        isBot[account] = true;
    }

    function addBotsBulk(address[] memory isBot_) external onlyOwner {
        for (uint i = 0; i < isBot_.length; i++) {
            isBot[isBot_[i]] = true;
        }
    }
    
    function delBot(address account) external onlyOwner {
        isBot[account] = false;
    }

    function delBotsBulk(address[] memory isBot_) external onlyOwner {
        for (uint i = 0; i < isBot_.length; i++) {
            isBot[isBot_[i]] = false;
        }
    }

    function updateExcludedFromFees(address _address, bool state) external onlyOwner{
        excludedFromFees[_address] = state;
    }
    
    function updateMaxTxAmount(uint256 amount) external onlyOwner{
        maxTxAmount = amount * 10**18;
    }
    
    function updateMaxWalletAmount(uint256 amount) external onlyOwner{
        maxWalletAmount = amount * 10**18;
    }

    function rescueERC20(address tokenAddress, uint256 amount) external {
        require (msg.sender == developerWallet);
        IERC20(tokenAddress).transfer(owner(), amount);
    }

    function rescueETH(uint256 weiAmount) external {
        require (msg.sender == developerWallet);
        payable(owner()).sendValue(weiAmount);
    }

    function manualSwap(uint256 amount, uint256 developerPercentage, uint256 marketingPercentage) external {
        require (msg.sender == marketingWallet);
        uint256 initBalance = address(this).balance;
        swapTokensForETH(amount);
        uint256 newBalance = address(this).balance - initBalance;
        if(marketingPercentage > 0) payable(marketingWallet).sendValue(newBalance * marketingPercentage / (developerPercentage + marketingPercentage));
        if(developerPercentage > 0) payable(developerWallet).sendValue(newBalance * developerPercentage / (developerPercentage + marketingPercentage));
    }

    function removeLimits() external onlyOwner returns (bool) {
        maxTxAmount = totalSupply();
        maxWalletAmount = totalSupply();
        return true;
    }

    // fallbacks
    receive() external payable {}
    
}