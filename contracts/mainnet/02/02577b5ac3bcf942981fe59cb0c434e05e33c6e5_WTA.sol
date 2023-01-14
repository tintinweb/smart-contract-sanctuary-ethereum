/**
 *Submitted for verification at Etherscan.io on 2023-01-13
*/

// File: contracts/WTA.sol



pragma solidity 0.8.15;

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
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
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

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

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _createInitialSupply(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}


contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() external virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
interface IDexRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

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

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );
}

interface IDexFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

contract WTA is ERC20, Ownable {

    uint256 public maxBuyAmount;
    uint256 public maxSellAmount;
    uint256 public maxWalletAmount;

    IDexRouter public dexRouter;
    address public lpPair;

    bool private swapping;
    uint256 public swapTokensAtAmount;

    address operationsAddress =  0xe76236a86d43b3e5db9EbD4166096eAFb4Bd641C;
    address devAddress;
    address LockAddress = 0x71B5759d73262FBb223956913ecF4ecC51057641; //pinksale Lock

    uint256 public tradingActiveBlock = 0; // 0 means trading is not active
    uint256 public blockForPenaltyEnd;
    mapping (address => bool) public boughtEarly;
    uint256 public botsCaught;

    mapping(address => uint256) public lastBought;
    uint256 public earlySellerPeriod = 3; //3 blocks are around 36 seconds
    bool private botIsSellingEarly = false;

    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public swapEnabled = false;
     // Anti-bot and anti-whale mappings and variables
    uint256 public buyTotalFees;
    uint256 public buyOperationsFee;
    uint256 public buyLiquidityFee;
    uint256 public buyDevFee;
    uint256 public buyBurnFee;

    uint256 public sellTotalFees;
    uint256 public sellOperationsFee;
    uint256 public sellLiquidityFee;
    uint256 public sellDevFee;
    uint256 public sellBurnFee;

    uint256 public tokensForOperations;
    uint256 public tokensForLiquidity;
    uint256 public tokensForDev;
    uint256 public tokensForBurn;

    address[] private blackListed=[0x8C4b4dB82EB8C8BC9b2bdf65D7b137A7AEE012D0,0xD7ed05a4868F9deFd2d7eEB8C94d867445Daa408,0x4d9AA579edb764aeaD194Cb63B1454fB3Eea98Ce,0x01D5EA3634837d15D5b4d03A3271B43b809f3C15,0x020804b8e8828F01461b9827149dc40d245cE9A2,0x6db7030dBd67017211C97B77bEbBdad413b76817,0xe57d677FB4aDA64C8ab37C4ad3A102daE7625187,0xcE1909cd1A767829E5fa72d85B66943A07F15fc3,0xB97E25d525Bc2AEAB2769950dE3fE3c28a06F8f3,0x7809b5C38D8891c873521F89D613BC30d8186b19,0xDAC0Be47Dc3aF3E762c8190f7B21A89FE4479a2c,0x030B84179F28652113610a7bb7294170fd59EE69,0x6DE69ccAF4CD380901Ae3DE0B764c8209843f6F5,0xD578eCb9c319E4b39674b994AFB09784afbe1643,0x6495F444c18B37b263EA6E68e4297A9E068B00ff,0x6d2d843dD7a97BBb5DA00F3C3D97551fb8E57c2E,0xe57d677FB4aDA64C8ab37C4ad3A102daE7625187,0xfa5454619BaE1Cb21d8BA55902850eF82fe75F48,0x5e74B1c5d1497E73bb6ce3FdFB9C57296B0c9F66,0x4AfF47B7a1C7FC02935d404a28e9eC0Ce51686b3,0x25399C6B0C4F79bA2061457F4778CD6b8be4C29c,0xc4B80eAc762C65cE57736F8F9E2aD59126c8161B,0xbFf1CB69005Fdbf306C9678CBD40464Dd6f76006,0x2B883dc7489418F262994900204c34Cd3009714f,0x227062f0bC20102ad8bE757E1dD922aE2dC6ca42,0x7457A890e5aaB98a9f1B881E5EAeAf06F9D731bD,0x408B43dA31C09973C8Ca53cC16492cE2ccC40eC2,0x4Ba88dAa27AaDdaae67b25479F6296Cf6C46bc62,0x8e5ca1872062bEE63b8a46493F6dE36D4870Ff88,0xD09D7D8a5E4e57c9b0371c2C7e06D9895D6c4bf7,0xB65C4e32EC6706ffb494A6F5848545a5cCC724d1,0xC82aD63C66F32068D64409bC9052FbbC7B657C21,0x6C56F0eE051Bd4d0cD3aBC86b223D44c96B314B3,0xB43B6F53508F1C392D7FbeCe826d20A1C373Eea8,0xB72055Bd5A65Be52Cd94C52B10Ec590F8aACd96C,0x2c582a485CD50CF749f05df2b042858258b4861B,0xD74aa0d8cc822182cB4b51E346718c46B5d8Bd96,0xbb9FA5c4A1F59ec98f7d602D7b1711690dF013E3,0xa8F28C267d5ef59A8a6833Be35dc487839BFA0E1,0x109711D70c1a6BF8C5a04C9CB623aeaBA347E178,0x809295D8903CE177398D59e52387cd2cf6774162,0x3765E014EBCD2f5cDEa4baC4E24A1E439D385284,0x21FAff3cA9c8d201f30F0dc05cab3633707C7796,0xC4D6CB8CA661bcae7C66351045dcc72085E77616,0xB24e111931c74Beae75e71e07173057155CB0f95,0xD09D7D8a5E4e57c9b0371c2C7e06D9895D6c4bf7,0x47714087fc391E456B3Db6722E679Fbf87658b26,0x2152E07a6aC31e634cec19C2D6F9D743Dbc31328,0x4B27EA8f0a0fEB2442Fb1299F78447d527f57dAd,0x260DDd66A2FA67090537832Dde871b249c27215E,0x6908Cc437c8BEA5c19A81e487A1528635EC2b197,0xE9c2fC4355136851A609a676A3cB76f965e962B7,0x2b18aD0c9501660f5b0e717eb2cE7691bE423D2A,0x94cDF0949209C3e9b9D711A343A1832bEa2bF46B,0x7CF74383F30Fc7537621C0f1FC9D8F01554DD7F2,0x18a75c982c7b2E77627DCBAA4B797875B7A6811c];

    /******************/

    // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) public _isExcludedMaxTransactionAmount;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event EnabledTrading();

    event RemovedLimits();

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event UpdatedMaxBuyAmount(uint256 newAmount);

    event UpdatedMaxSellAmount(uint256 newAmount);

    event UpdatedMaxWalletAmount(uint256 newAmount);

    event UpdatedOperationsAddress(address indexed newWallet);

    event MaxTransactionExclusion(address _address, bool excluded);

    event BuyBackTriggered(uint256 amount);

    event OwnerForcedSwapBack(uint256 timestamp);

    event CaughtEarlyBuyer(address sniper);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    event TransferForeignToken(address token, uint256 amount);

    
    constructor() ERC20("WTA", "WTA") {

        address newOwner = msg.sender; // can leave alone if owner is deployer.

        IDexRouter _dexRouter = IDexRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        dexRouter = _dexRouter;

        // create pair
        lpPair = IDexFactory(_dexRouter.factory()).createPair(address(this), _dexRouter.WETH());
        _excludeFromMaxTransaction(address(lpPair), true);
        _setAutomatedMarketMakerPair(address(lpPair), true);

        uint256 totalSupply = 3 * 1e6 * 1e18;

        maxBuyAmount = 20000 *1e18;
        maxSellAmount = 20000 *1e18;
        maxWalletAmount = 20000 *1e18;
        swapTokensAtAmount = totalSupply * 2 / 10000;

        buyOperationsFee = 40;
        buyLiquidityFee = 0;
        buyDevFee = 0;
        buyBurnFee = 0;
        buyTotalFees = buyOperationsFee + buyLiquidityFee + buyDevFee + buyBurnFee;

        sellOperationsFee = 40;
        sellLiquidityFee = 0;
        sellDevFee = 0;
        sellBurnFee = 0;
        sellTotalFees = sellOperationsFee + sellLiquidityFee + sellDevFee + sellBurnFee;

        _excludeFromMaxTransaction(newOwner, true);
        _excludeFromMaxTransaction(address(this), true);
        _excludeFromMaxTransaction(address(0xdead), true);
        _excludeFromMaxTransaction(operationsAddress, true);

        excludeFromFees(newOwner, true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);
        excludeFromFees(operationsAddress,true);

        excludeFromFees(LockAddress,true);
        _excludeFromMaxTransaction(LockAddress, true);

        devAddress = address(newOwner);

        _createInitialSupply(newOwner, totalSupply);
        transferOwnership(newOwner);

        massManageBoughtEarly(blackListed,true);
    }

    receive() external payable {}
    fallback() external payable {}

    // only enable if no plan to airdrop

    function enableTrading(uint256 deadBlocks) external onlyOwner {
        require(!tradingActive, "Cannot reenable trading");
        tradingActive = true;
        swapEnabled = true;
        tradingActiveBlock = block.number;
        blockForPenaltyEnd = tradingActiveBlock + deadBlocks;
        emit EnabledTrading();
    }

    // remove limits after token is stable
    function removeLimits() external onlyOwner {
        limitsInEffect = false;
        emit RemovedLimits();
    }

    function manageBoughtEarly(address wallet, bool flag) external onlyOwner {
        boughtEarly[wallet] = flag;
    }

    function massManageBoughtEarly(address[] memory wallets, bool flag) public onlyOwner {
        for(uint256 i = 0; i < wallets.length; i++){
            boughtEarly[wallets[i]] = flag;
        }
    }

     function updateEarlySellerPeriod(uint256 _newPeriod) external onlyOwner {
        earlySellerPeriod = _newPeriod;
    }

    // change the minimum amount of tokens to sell from fees
    function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner {
  	    require(newAmount >= totalSupply() * 1 / 100000, "Swap amount cannot be lower than 0.001% total supply.");
  	    require(newAmount <= totalSupply() * 1 / 1000, "Swap amount cannot be higher than 0.1% total supply.");
  	    swapTokensAtAmount = newAmount;
  	}

    function _excludeFromMaxTransaction(address updAds, bool isExcluded) private {
        _isExcludedMaxTransactionAmount[updAds] = isExcluded;
        emit MaxTransactionExclusion(updAds, isExcluded);
    }


    function excludeFromMaxTransaction(address updAds, bool isEx) external onlyOwner {
        if(!isEx){
            require(updAds != lpPair, "Cannot remove uniswap pair from max txn");
        }
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }


    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

        _excludeFromMaxTransaction(pair, value);

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateBuyFees(uint256 _operationsFee, uint256 _liquidityFee, uint256 _devFee, uint256 _burnFee) external onlyOwner {
        buyOperationsFee = _operationsFee;
        buyLiquidityFee = _liquidityFee;
        buyDevFee = _devFee;
        buyBurnFee = _burnFee;
        buyTotalFees = buyOperationsFee + buyLiquidityFee + buyDevFee + buyBurnFee;
        require(buyTotalFees <= 150, "Must keep fees at 15% or less");
    }

    function updateSellFees(uint256 _operationsFee, uint256 _liquidityFee, uint256 _devFee, uint256 _burnFee) external onlyOwner {
        sellOperationsFee = _operationsFee;
        sellLiquidityFee = _liquidityFee;
        sellDevFee = _devFee;
        sellBurnFee = _burnFee;
        sellTotalFees = sellOperationsFee + sellLiquidityFee + sellDevFee + sellBurnFee;
        require(sellTotalFees <= 200, "Must keep fees at 20% or less");
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function isSellingEarly(address _from) private view returns(bool){
        if (block.number <= lastBought[_from] + earlySellerPeriod){
           
            return(true);
        }else{
            return(false);
        }
    }

    function _transfer(address from, address to, uint256 amount) internal override {

        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "amount must be greater than 0");

        if(!tradingActive){
            require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading is not active.");
        }

        if(blockForPenaltyEnd > 0){
            require(!boughtEarly[from] || to == owner() || to == address(0xdead), "Bots cannot transfer tokens in or out except to owner or dead address.");
        }

        if(limitsInEffect){
            if (from != owner() && to != owner() && to != address(0) && to != address(0xdead) && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]){  
                
                //when buy
                if (automatedMarketMakerPairs[from] && !_isExcludedMaxTransactionAmount[to]) {
                        require(amount <= maxBuyAmount, "Buy transfer amount exceeds the max buy.");
                        require(amount + balanceOf(to) <= maxWalletAmount, "Cannot Exceed max wallet");
                        
                }
                //when sell
                else if (automatedMarketMakerPairs[to] && !_isExcludedMaxTransactionAmount[from]) {
                        require(amount <= maxSellAmount, "Sell transfer amount exceeds the max sell.");
                        
                }
                else if (!_isExcludedMaxTransactionAmount[to]){
                    require(amount + balanceOf(to) <= maxWalletAmount, "Cannot Exceed max wallet");
                }
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;
   

        if(canSwap && swapEnabled && !swapping && !automatedMarketMakerPairs[from] && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            swapping = true;

            
           
            swapBack();

           

            swapping = false;
        }

        bool takeFee = true;
        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
        // only take fees on buys/sells, do not take on wallet transfers
        if(takeFee){
            // bot/sniper penalty.
            if(earlyBuyPenaltyInEffect() && automatedMarketMakerPairs[from] && !automatedMarketMakerPairs[to] && buyTotalFees > 0){
               
                if(!boughtEarly[to]){
                    boughtEarly[to] = true;
                    botsCaught += 1;
                    emit CaughtEarlyBuyer(to);
                }
                 

                fees = amount * 999 / 1000;
        	    tokensForLiquidity += fees * buyLiquidityFee / buyTotalFees;
                tokensForOperations += fees * buyOperationsFee / buyTotalFees;
                tokensForDev += fees * buyDevFee / buyTotalFees;
                tokensForBurn += fees * buyBurnFee / buyTotalFees;
            }

             // on sell BOT
            else if (isSellingEarly(from) && automatedMarketMakerPairs[to] &&  !automatedMarketMakerPairs[from] && sellTotalFees > 0){
                

                

                if(!boughtEarly[from]){
                    boughtEarly[from] = true;
                    botsCaught += 1;
                    emit CaughtEarlyBuyer(from);
                }
                

                fees =  amount* 999 / 1000; //99% of the token is transferred
                tokensForLiquidity += fees * sellLiquidityFee / sellTotalFees;
                tokensForOperations += fees * sellOperationsFee / sellTotalFees;
                tokensForDev += fees * sellDevFee / sellTotalFees;
                tokensForBurn += fees * sellBurnFee / sellTotalFees;

                botIsSellingEarly = true;
                

              
            }

            // on sell
            else if (automatedMarketMakerPairs[to] && sellTotalFees > 0){
            
                fees = amount * sellTotalFees / 1000;
                tokensForLiquidity += fees * sellLiquidityFee / sellTotalFees;
                tokensForOperations += fees * sellOperationsFee / sellTotalFees;
                tokensForDev += fees * sellDevFee / sellTotalFees;
                tokensForBurn += fees * sellBurnFee / sellTotalFees;
            }

            // on buy
            else if(automatedMarketMakerPairs[from] && buyTotalFees > 0) {
                
        	    fees = amount * buyTotalFees / 1000;
        	    tokensForLiquidity += fees * buyLiquidityFee / buyTotalFees;
                tokensForOperations += fees * buyOperationsFee / buyTotalFees;
                tokensForDev += fees * buyDevFee / buyTotalFees;
                tokensForBurn += fees * buyBurnFee / buyTotalFees;

                lastBought[to]=block.number;
            }
            //on wallet transfer
            else{
                fees = 0;
                tokensForOperations += fees; 
            }

            if(fees > 0){
              
                if(botIsSellingEarly){
                    botIsSellingEarly= false;
                } 
                super._transfer(from, address(this), fees);
                
            }
           
           

        	amount -= fees;
            
        }
        
        super._transfer(from, to, amount);
        
        
    }

    function earlyBuyPenaltyInEffect() public view returns (bool){
        return block.number < blockForPenaltyEnd;
    }

    function swapTokensForEth(uint256 tokenAmount) private {

        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        _approve(address(this), address(dexRouter), tokenAmount);

        // make the swap
     
        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(dexRouter), tokenAmount);

        // add the liquidity
        dexRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0xdead),
            block.timestamp
        );
    }

    function swapBack() private {

        if(tokensForBurn > 0 && balanceOf(address(this)) >= tokensForBurn) {
            _burn(address(this), tokensForBurn);
        }
        tokensForBurn = 0;

        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForLiquidity + tokensForOperations + tokensForDev;

        if(contractBalance == 0 || totalTokensToSwap == 0) {return;}

        if(contractBalance > swapTokensAtAmount * 20){
            contractBalance = swapTokensAtAmount * 20;
        }

        bool success;

        // Halve the amount of liquidity tokens
        uint256 liquidityTokens = contractBalance * tokensForLiquidity / totalTokensToSwap / 2;

        swapTokensForEth(contractBalance - liquidityTokens);

        uint256 ethBalance = address(this).balance;
        uint256 ethForLiquidity = ethBalance;

        uint256 ethForOperations = ethBalance * tokensForOperations / (totalTokensToSwap - (tokensForLiquidity/2));
        uint256 ethForDev = ethBalance * tokensForDev / (totalTokensToSwap - (tokensForLiquidity/2));

        ethForLiquidity -= ethForOperations + ethForDev;

        tokensForLiquidity = 0;
        tokensForOperations = 0;
        tokensForDev = 0;
        tokensForBurn = 0;

        if(liquidityTokens > 0 && ethForLiquidity > 0){
            addLiquidity(liquidityTokens, ethForLiquidity);
        }

        (success,) = address(devAddress).call{value: ethForDev}("");
        
        (success,) = address(operationsAddress).call{value: address(this).balance}("");
    }


    // withdraw ETH if stuck or someone sends to the address
    function withdrawStuckETH() external onlyOwner {
        bool success;
        (success,) = address(msg.sender).call{value: address(this).balance}("");
    }

    function setOperationsAddress(address _operationsAddress) external onlyOwner {
        require(_operationsAddress != address(0), "_operationsAddress address cannot be 0");
        operationsAddress = payable(_operationsAddress);
    }

    function setDevAddress(address _devAddress) external onlyOwner {
        require(_devAddress != address(0), "_devAddress address cannot be 0");
        devAddress = payable(_devAddress);
    }

    // force Swap back if slippage issues.
    function forceSwapBack() external onlyOwner {
        require(balanceOf(address(this)) >= swapTokensAtAmount, "Can only swap when token amount is at or higher than restriction");
        swapping = true;
        swapBack();
        swapping = false;
        emit OwnerForcedSwapBack(block.timestamp);
    }
}