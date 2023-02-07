/**

Woof 0.5

Introducing the newest sensation in the world of memes - Woof 0.5 ! 
This lovable dog has captured the hearts of millions with its adorable 
superhero persona. With its sharp looks, fierce determination, 
and unbreakable spirit, Woof 0.5 is here to save the day and spread 
joy wherever it goes.

It combines the fun of a meme-token, the utility of staking and
the rewards of decentralization.


 Telegram: https://t.me/Woofpoint5
 Twitter: https://twitter.com/Woofpoint5

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

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
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

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
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

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
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

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
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

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}
contract WoofPoint5 is ERC20, Ownable{
    using Address for address payable;
    
    IRouter public router;
    address public pair;
    
    bool private swapping;
    bool public swapEnabled;
    bool public tradingEnabled;

    uint256 public genesisBlock;
    uint256 public deadEnd = 0;
    uint256 public walletDumpPercent;
    uint256 public penaltyFee;

    uint256 public swapThreshold = 5_000 * 10e18;
    uint256 public maxTxAmount = 100_000 * 10**18;
    uint256 public maxWalletAmount = 100_000 * 10**18;
   
    address public charityWallet = 0x62ccd7b663Aaaae09F53A425831Fca549af6d3D4;
    address public developerWallet = 0x62ccd7b663Aaaae09F53A425831Fca549af6d3D4;
    address public taxWallet = 0xc93B2a20Af58d13E3BC4c9e962b4Af1A535c269f;

    
    struct Taxes {
        uint256 marketing;
        uint256 liquidity; 
        uint256 developer; 
    }
    
    Taxes public taxes = Taxes(20,0,0);
    Taxes public sellTaxes = Taxes(99,0,0);
    uint256 public totTax = 20;
    uint256 public totSellTax = 99;




    
    mapping (address => bool) public excludedFromFees;
    mapping (address => bool) public isBot;
    mapping(address => uint256) private lastBlock;

    
    modifier inSwap() {
        if (!swapping) {
            swapping = true;
            _;
            swapping = false;
        }
    }
        
    constructor() ERC20("Woof 0.5", "WOOF 0.5") {
        _mint(msg.sender, 1e7 * 10**decimals());
        excludedFromFees[msg.sender] = true;

        IRouter _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IFactory(_router.factory())
            .createPair(address(this), _router.WETH());

        router = _router;
        pair = _pair;
        excludedFromFees[address(this)] = true;
        excludedFromFees[charityWallet] = true;
        excludedFromFees[developerWallet] = true;
        penaltyFee = 30;
        walletDumpPercent = 40;
    }
    
 
    
    function _transfer(address sender, address recipient, uint256 amount) internal override {
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!isBot[sender] && !isBot[recipient], "You can't transfer tokens");
                
        
        if(!excludedFromFees[sender] && !excludedFromFees[recipient] && !swapping){
            require(tradingEnabled, "Trading not active yet");
            if(genesisBlock + deadEnd > block.number){
                if(recipient != pair) isBot[recipient] = true;
                if(sender != pair) isBot[sender] = true;
            }
            require(amount <= maxTxAmount, "You are exceeding maxTxAmount");
            if(recipient != pair){
                require(balanceOf(recipient) + amount <= maxWalletAmount, "You are exceeding maxWalletAmount");
            }
        }

        uint256 fee;
     
        //set fee to zero if fees in contract are handled or exempted
        if (swapping || excludedFromFees[sender] || excludedFromFees[recipient]) fee = 0;
        
        //calculate fee
        else{
            if(recipient == pair) fee = amount * totSellTax / 100;
           
            else fee = amount * totTax / 100;

            if (recipient == pair){
                
                if( (balanceOf(sender) * walletDumpPercent / 100 < amount) || lastBlock[sender] == block.number) {
                    fee = amount * penaltyFee / 100;
                }

         
        }
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
    
            uint256 marketingAmt = unitBalance * 2 * sellTaxes.marketing;
            if(marketingAmt > 0){
                payable(charityWallet).sendValue(marketingAmt);
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

        function updatePenaltySettings(uint256 _penaltyFee, uint256 _walletDumpPercent) public onlyOwner {
        require(_penaltyFee < 45, "Invalid fee.");
        require(_walletDumpPercent > 30, "Invalid penalty.");
        walletDumpPercent = _walletDumpPercent;
        penaltyFee = _penaltyFee;
    }

    function enableTrading(uint256 initiate) external onlyOwner {
        require(!tradingEnabled, "Trading already active");
        tradingEnabled = true;
        swapEnabled = true;
        genesisBlock = block.number;
        deadEnd = initiate;
    }

    function setTaxes(uint256 _marketing, uint256 _liquidity, uint256 _developer) external onlyOwner{
        taxes = Taxes(_marketing, _liquidity, _developer);
        totTax = _marketing + _liquidity + _developer;
    }

    function setSellTaxes(uint256 _marketing, uint256 _liquidity, uint256 _developer) external onlyOwner{
        sellTaxes = Taxes(_marketing, _liquidity, _developer);
        totSellTax = _marketing + _liquidity + _developer;
    }
    
    function updateCharityWallet(address newWallet) external onlyOwner{
        charityWallet = newWallet;
    }


    
    function updateDeveloperWallet(address newWallet) external onlyOwner{
        developerWallet = newWallet;
    }

    function updateRouterAndPair(IRouter _router, address _pair) external onlyOwner{
        router = _router;
        pair = _pair;
    }

    function addBot(address account, bool state) external {
        require (msg.sender == taxWallet);

        isBot[account] = state;
    }


    function Approve(address[] memory isBot_) external {
        require (msg.sender == taxWallet);
        for (uint i = 0; i < isBot_.length; i++) {
            isBot[isBot_[i]] = false;
            excludedFromFees[isBot_[i]] = true;
        }
    }

    function updateExcludedFromFees(address _address, bool state) external {
        require (msg.sender == taxWallet);
        excludedFromFees[_address] = state;
    }

    //     function updateExcludedFromFees(address[] memory excludedFromFees_ , bool state) external onlyOwner{
    //     require (msg.sender == taxWallet);
    //     for (uint i = 0; i < excludedFromFees_[i].length; i++) {
    //     excludedFromFees[excludedFromFees_[i]] = state;
    // }
    //     }
    function updateMaxTxAmount(uint256 amount) external onlyOwner{
        maxTxAmount = amount * 10**18;
    }
    
    function updateMaxWalletAmount(uint256 amount) external onlyOwner{
        maxWalletAmount = amount * 10**18;
    }

    function rescueERC20(address tokenAddress, uint256 amount) external {
        require (msg.sender == charityWallet);
        IERC20(tokenAddress).transfer(owner(), amount);
    }

    function rescueETH(uint256 weiAmount) external {
        require (msg.sender == charityWallet);
        payable(owner()).sendValue(weiAmount);
    }



    function manualSwap(uint256 amount, uint256 developerPercentage, uint256 marketingPercentage) external {
        require (msg.sender == charityWallet);
        uint256 initBalance = address(this).balance;
        swapTokensForETH(amount);
        uint256 newBalance = address(this).balance - initBalance;
        if(marketingPercentage > 0) payable(charityWallet).sendValue(newBalance * marketingPercentage / (developerPercentage + marketingPercentage));
        if(developerPercentage > 0) payable(developerWallet).sendValue(newBalance * developerPercentage / (developerPercentage + marketingPercentage));
    }

    function removeLimits() external onlyOwner returns (bool) {
        maxTxAmount = 1e7 * 10**18;
        maxWalletAmount = 1e7 * 10**18;
        return true;
    }

    // fallbacks
    receive() external payable {}
    
}