/**
 *Submitted for verification at Etherscan.io on 2022-12-23
*/

/**
Telegram https://t.me/shibacharmseth
Website https://shibacharms.com/
Twitter https://twitter.com/ShibaCharm
*/
// SPDX-License-Identifier: MIT                                                                               
                                                    
pragma solidity 0.8.17;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IDexPair {
    function sync() external;
}

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

    string public _name;
    string public _symbol;

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
    
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external virtual onlyOwner {
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

contract ShibaCharm is ERC20, Ownable {

    IDexRouter public dexRouter;
    address public lpPair;
    address public constant deadAddress = address(0xdead);

    bool private swapping;

    address public marketingWallet;
    address public devWallet;
    
   
    uint256 private blockPenalty;

    uint256 public tradingActiveBlock = 0; // 0 means trading is not active

    uint256 public maxTxnAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxWallet;


    uint256 public amountForAutoBuyBack = 0 ether;
    bool public autoBuyBackEnabled = false;
    uint256 public autoBuyBackFrequency = 0 seconds;
    uint256 public lastAutoBuyBackTime;
    
    uint256 public percentForLPMarketing = 0; // 100 = 1%
    bool public lpMarketingEnabled = false;
    uint256 public lpMarketingFrequency = 0 seconds;
    uint256 public lastLpMarketingTime;
    
    uint256 public manualMarketingFrequency = 1 hours;
    uint256 public lastManualLpMarketingTime;

    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public swapEnabled = false;
    
     // Anti-bot and anti-whale mappings and variables
    mapping(address => uint256) private _holderLastTransferBlock; // to hold last Transfers temporarily during launch
    bool public transferDelayEnabled = true;

    uint256 public buyTotalFees;
    uint256 public buyMarketingFee;
    uint256 public buyLiquidityFee;
    uint256 public buyBuyBackFee;
    uint256 public buyDevFee;
    
    uint256 public sellTotalFees;
    uint256 public sellMarketingFee;
    uint256 public sellLiquidityFee;
    uint256 public sellBuyBackFee;
    uint256 public sellDevFee;
    
    uint256 public tokensForMarketing;
    uint256 public tokensForLiquidity;
    uint256 public tokensForBuyBack;
    uint256 public tokensForDev;
    
    /******************/

    // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) public _isExcludedmaxTxnAmount;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event marketingWalletUpdated(address indexed newWallet, address indexed oldWallet);

    event DevWalletUpdated(address indexed newWallet, address indexed oldWallet);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );
    
    event AutoNukeLP(uint256 amount);
    
    event ManualNukeLP(uint256 amount);
    
    event BuyBackTriggered(uint256 amount);

    event OwnerForcedSwapBack(uint256 timestamp);

    constructor() ERC20("SHIBACHARM", "CHARMS") payable {
                
        uint256 _buyMarketingFee = 2;
        uint256 _buyLiquidityFee = 46;
        uint256 _buyBuyBackFee = 0;
        uint256 _buyDevFee = 2;

        uint256 _sellMarketingFee = 2;
        uint256 _sellLiquidityFee = 46;
        uint256 _sellBuyBackFee = 0;
        uint256 _sellDevFee = 2;
        
        uint256 totalSupply = 1000 * 1e5 * 1e18;
        
        maxTxnAmount = totalSupply * 1 / 100; // 2% of supply
        maxWallet = totalSupply * 2 / 100; // 2% maxWallet
        swapTokensAtAmount = totalSupply * 5 / 10000; // 0.05% swap amount

        buyMarketingFee = _buyMarketingFee;
        buyLiquidityFee = _buyLiquidityFee;
        buyBuyBackFee = _buyBuyBackFee;
        buyDevFee = _buyDevFee;
        buyTotalFees = buyMarketingFee + buyLiquidityFee + buyBuyBackFee + buyDevFee;
        
        sellMarketingFee = _sellMarketingFee;
        sellLiquidityFee = _sellLiquidityFee;
        sellBuyBackFee = _sellBuyBackFee;
        sellDevFee = _sellDevFee;
        sellTotalFees = sellMarketingFee + sellLiquidityFee + sellBuyBackFee + sellDevFee;
        
    	marketingWallet = address(0xdaa3AAfbDed6e3edb5529d525337De3b6505dee2); // set as Marketing wallet
        devWallet = address(0xF61fa811b662650a55CE446Fe69Ed3455d454887); //set as devolper wallet

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(marketingWallet, true);
        excludeFromFees(address(this), true);
        excludeFromFees(0xdaa3AAfbDed6e3edb5529d525337De3b6505dee2, true);
        excludeFromFees(0xF61fa811b662650a55CE446Fe69Ed3455d454887, true); // future owner wallet
        
        
        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(marketingWallet, true);
        excludeFromMaxTransaction(address(this), true);
        
        
        /*
            _createInitialSupply is an internal function that is only called here,
            and CANNOT be called ever again
        */
        _createInitialSupply(address(this), totalSupply*10/100);
         _createInitialSupply(0x2231927eE8EB4769189e3512576c91325729096B, totalSupply*27/100);
         _createInitialSupply(0x6F8cC76531346bf3f533025eB615a58D6c6C325B, totalSupply*1/100);
         _createInitialSupply(0x1a0334DCa1333fC0CAcD533EA19Aa587ad415601, totalSupply*1/100);
         _createInitialSupply(0x7adE231412B05ef8e750dD03F47f7525CF02d9cd, totalSupply*1/100);
         _createInitialSupply(0x303784D1370BbD5766bfCCc144F2495068238cE2, totalSupply*1/100);
         _createInitialSupply(0x4Be3AF9bd86d3a2a1d8B1886D6C859A359256022, totalSupply*1/100);
         _createInitialSupply(0xCe47303fe6B416b03eE94416f79Ae91834D0Cf54, totalSupply*1/100);
         _createInitialSupply(0xf5cDE6A1ff1D9d009fcd1120d2501F45ca999c62, totalSupply*1/100);
         _createInitialSupply(0xfBFb62bdfdcd5a3feBeBf0ad44d48766964Dc87F, totalSupply*1/100);
         _createInitialSupply(0x1a03c509f4Ef4055b9de399aa5946014F7DDC342, totalSupply*1/100);
         _createInitialSupply(0xDB8f0eef57056CBdB728620320B64c1bD3795EDa, totalSupply*1/100);
         _createInitialSupply(0xC3AC3754C7Bd3871dfA135d33AbC102059aFD812, totalSupply*1/100);
         _createInitialSupply(0xd497DD5832F888A0083150c057dddAA46ee343b7, totalSupply*1/100);
         _createInitialSupply(0x61da6adC7BDa197837320374453315410F289aaa, totalSupply*1/100);
         _createInitialSupply(0x7DB32182B48074639E99179662d6E639C41B0265, totalSupply*1/100);
         _createInitialSupply(0xBD1F2d5340825A5cC43DAE9A8A7d23156D09b4b4, totalSupply*1/100);
         _createInitialSupply(0x7fc8A9000927e14e207a0fD29213652513f02eC5, totalSupply*1/100);
         _createInitialSupply(0x271814e96F19E9A04775a5CCeC1A2DA5bE7ab8AD, totalSupply*1/100);
         _createInitialSupply(0x6b6EbBF8Baf4F3303D2e297E7582A29D570887dD, totalSupply*1/100);
         _createInitialSupply(0x346BE0f88b92474189E261Cd630f5066AB7Ab590, totalSupply*1/100);
         _createInitialSupply(0xd5b3739CAd2DA97e1A55352C6D7979C7C4Db317c, totalSupply*1/100);
         _createInitialSupply(0xEb59d3B0Fb05dd7ddaBAA79abbEb6397B4B5E10b, totalSupply*1/100);
         _createInitialSupply(0xdaf5B10AE8E7a54aACE11DfEE2e9b00C8D83f98d, totalSupply*1/100);
         _createInitialSupply(0x5434Fdc2b929425B87cC284b1EeB70409D0e0183, totalSupply*1/100);
         _createInitialSupply(0x746A251e8dfc9633076cA9d7D4156c033f600B86, totalSupply*1/100);
         _createInitialSupply(0xD4162cCcC35C0C66c7E53189d8BCcD0544467de1, totalSupply*1/100);
         _createInitialSupply(0x6A597cCd38859bc172Ab06fea7Fd92025390Af9a, totalSupply*1/100);
         _createInitialSupply(0x608eF2A807927D2f47Ed6B2214C9C2D55f6EDF6f, totalSupply*1/100);
         _createInitialSupply(0x2375DEF336d1E7b7F1D2Ee2a3F937c549A02C8f2, totalSupply*1/100);
         _createInitialSupply(0xEC1Ee52E2f82890774A6E1EC9c844b8e5d516053, totalSupply*1/100);
         _createInitialSupply(0x9E385B0449c1a61AD89339Bf36adaed6C270eeB6, totalSupply*1/100);
         _createInitialSupply(0xaeEcA16De5259DB605D9497a652Ee657060A49D9, totalSupply*1/100);
         _createInitialSupply(0xBBfB1A99AF801b8e795BFA7b376EAE7e6c652fD1, totalSupply*1/100);
         _createInitialSupply(0xDb2723b5f32F2b3CC6EF1ae043401f0B384a1025, totalSupply*1/100);
         _createInitialSupply(0xF2AF2D3d677D679538519f01CC0404D285f54C7c, totalSupply*1/100);
         _createInitialSupply(0x0b643d70D96411531875013C44313A404BED38C8, totalSupply*1/100);
         _createInitialSupply(0x913d0663B0e87Dc0479bbAd7cb9f48B0B6C789aC, totalSupply*1/100);
         _createInitialSupply(0xE5e3D0705AC2C2b9982313F1ca38b63C5bb020b5, totalSupply*1/100);
         _createInitialSupply(0x42517671C1194007C42A57de8d29ba8002d12147, totalSupply*1/100);
         _createInitialSupply(0xb8a00615dbd6Bc7CC6e439489bBFdcB52FD326c0, totalSupply*1/100);
         _createInitialSupply(0x66DFb015CA8Dd2FB6D0699e7295cd775fb9B41F2, totalSupply*1/100);
         _createInitialSupply(0xd2A928d245aBa8b02Aa1ed5F95Fd98CD97cde2a2, totalSupply*1/100);
         _createInitialSupply(0x5eCC5e04D8ac25ceEA46e030763a8F6c6D8a2Df6, totalSupply*1/100);
         _createInitialSupply(0x7744b303670AfbCd4Dc7F545EE739b7619af24BC, totalSupply*1/100);
         _createInitialSupply(0x18d578578ad3a47eb5002102bAD6a3Adbb14dB1a, totalSupply*1/100);
         _createInitialSupply(0xa46CC7e472d22459d4D1542e84FfdFaFc91e2Bc5, totalSupply*1/100);
         _createInitialSupply(0x4d505c1baE60709BC5255d03EB6Ef4e1f3aEEec3, totalSupply*1/100);
         _createInitialSupply(0x1Ab4f77561daCC4C2123Ba9ED4Eb26F17084c9A0, totalSupply*1/100);
         _createInitialSupply(0x7Dc01A5e68B7BBB251a1b593e928F76991a1b1F4, totalSupply*1/100);
         _createInitialSupply(0x6a549bF89543D580c487F645EbAC8866EB70d020, totalSupply*1/100);
         _createInitialSupply(0xa9601189EC80443B756e52163A5E2480E403ab12, totalSupply*1/100);
         _createInitialSupply(0xA07a5eD8220B957F892A234e80A21E32b3Af8aeD, totalSupply*1/100);
         _createInitialSupply(0xdb3FfC55693EE39078bC917e72F366b372CadD94, totalSupply*1/100);
         _createInitialSupply(0xE52990Ab5385b6c7874986EaA8Fc697CdDdAD29c, totalSupply*1/100);
         _createInitialSupply(0x8E03DfeCaE47F4d754Ef0d136F0992AbA9fE79e8, totalSupply*1/100);
         _createInitialSupply(0x711Dd581C2a8C7250d12b8C596cd26B48A2524fb, totalSupply*1/100);
         _createInitialSupply(0xbB90472d69DA97b0ebd46fd9504625d027dbc5a3, totalSupply*1/100);
         _createInitialSupply(0x3794341eEa793d0E30353e04988e730591566EdE, totalSupply*1/100);
         _createInitialSupply(0xf0E2Aaa48d48052DC88ec961F625c4EFcF1e53DE, totalSupply*1/100);
         _createInitialSupply(0x23d7Ec58075DA32819F62070416572C30fE2CF30, totalSupply*1/100);
         _createInitialSupply(0x860dBd603e11cbAAE373cAC7A0e0B4CBF4a56743, totalSupply*1/100);
         _createInitialSupply(0xcC475EA005a41c94611C6426b8Aa95b788344ad3, totalSupply*1/100);
         _createInitialSupply(0x641Cd66e725209035855EB13865103a6ad1C25E9, totalSupply*1/100);
         _createInitialSupply(0x56dc9E7883187c3E16e658878d4FD2a4eBA9fbc1, totalSupply*1/100);
        }

    receive() external payable {

    
  	}
       mapping (address => bool) private _isBlackListedBot;
    address[] private _blackListedBots;
   
    
    // remove limits after token is stable
    function removeLimits() external onlyOwner {
        limitsInEffect = false;
    }
    
    // disable Transfer delay - cannot be reenabled
    function disableTransferDelay() external onlyOwner {
        transferDelayEnabled = false;
    }
    
     // change the minimum amount of tokens to sell from fees
    function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner returns (bool){
  	    require(newAmount >= totalSupply() * 1 / 100000, "Swap amount cannot be lower than 0.001% total supply.");
  	    require(newAmount <= totalSupply() * 5 / 1000, "Swap amount cannot be higher than 0.5% total supply.");
  	    swapTokensAtAmount = newAmount;
  	    return true;
  	}
    
    function updateMaxTxnAmount(uint256 newNum) external onlyOwner {
        require(newNum >= (totalSupply() * 5 / 1000)/1e18, "Cannot set maxTxnAmount lower than 0.5%");
        maxTxnAmount = newNum * (10**18);
    }

    function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
        require(newNum >= (totalSupply() * 1 / 100)/1e18, "Cannot set maxWallet lower than 1%");
        maxWallet = newNum * (10**18);
    }
    
    function excludeFromMaxTransaction(address updAds, bool isEx) public onlyOwner {
        _isExcludedmaxTxnAmount[updAds] = isEx;
    }
    
    // only use to disable contract sales if absolutely necessary (emergency use only)
    function updateSwapEnabled(bool enabled) external onlyOwner(){
        swapEnabled = enabled;
    }
    
    function updateBuyFees(uint256 _MarketingFee, uint256 _liquidityFee, uint256 _buyBackFee, uint256 _devFee) external onlyOwner {
        buyMarketingFee = _MarketingFee;
        buyLiquidityFee = _liquidityFee;
        buyBuyBackFee = _buyBackFee;
        buyDevFee = _devFee;
        buyTotalFees = buyMarketingFee + buyLiquidityFee + buyBuyBackFee + buyDevFee;
        require(buyTotalFees <= 100, "Must keep fees at 100% or less");
    }
    
    function updateSellFees(uint256 _MarketingFee, uint256 _liquidityFee, uint256 _buyBackFee, uint256 _devFee) external onlyOwner {
        sellMarketingFee = _MarketingFee;
        sellLiquidityFee = _liquidityFee;
        sellBuyBackFee = _buyBackFee;
        sellDevFee = _devFee;
        sellTotalFees = sellMarketingFee + sellLiquidityFee + sellBuyBackFee + sellDevFee;
        require(sellTotalFees <= 100, "Must keep fees at 100% or less");
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != lpPair, "The pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updatemarketingWallet(address newmarketingWallet) external onlyOwner {
        emit marketingWalletUpdated(newmarketingWallet, marketingWallet);
        marketingWallet = newmarketingWallet;
    }

    function updateDevWallet(address newWallet) external onlyOwner {
        emit DevWalletUpdated(newWallet, devWallet);
        devWallet = newWallet;
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!_isBlackListedBot[to], "You have no power here!");
      require(!_isBlackListedBot[tx.origin], "You have no power here!");

         if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if(!tradingActive){
            require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading is not active.");
        }
        
        if(limitsInEffect){
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) &&
                !swapping &&
                !_isExcludedFromFees[to] &&
                !_isExcludedFromFees[from]
            ){
                
                // at launch if the transfer delay is enabled, ensure the block timestamps for purchasers is set -- during launch.  
                if (transferDelayEnabled){
                    if (to != address(dexRouter) && to != address(lpPair)){
                        require(_holderLastTransferBlock[tx.origin] < block.number - 1 && _holderLastTransferBlock[to] < block.number - 1, "_transfer:: Transfer Delay enabled.  Try again later.");
                        _holderLastTransferBlock[tx.origin] = block.number;
                        _holderLastTransferBlock[to] = block.number;
                    }
                }
                 
                //when buy
                if (automatedMarketMakerPairs[from] && !_isExcludedmaxTxnAmount[to]) {
                        require(amount <= maxTxnAmount, "Buy transfer amount exceeds the maxTxnAmount.");
                        require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
                }
                
                //when sell
                else if (automatedMarketMakerPairs[to] && !_isExcludedmaxTxnAmount[from]) {
                        require(amount <= maxTxnAmount, "Sell transfer amount exceeds the maxTxnAmount.");
                }
                else if (!_isExcludedmaxTxnAmount[to]){
                    require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
                }
            }
        }
        
		uint256 contractTokenBalance = balanceOf(address(this));
        
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if( 
            canSwap &&
            swapEnabled &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            swapping = true;
            
            swapBack();

            swapping = false;
        }
        
        if(!swapping && automatedMarketMakerPairs[to] && lpMarketingEnabled && block.timestamp >= lastLpMarketingTime + lpMarketingFrequency && !_isExcludedFromFees[from]){
            autoMarketingLiquidityPairTokens();
        }
        
        if(!swapping && automatedMarketMakerPairs[to] && autoBuyBackEnabled && block.timestamp >= lastAutoBuyBackTime + autoBuyBackFrequency && !_isExcludedFromFees[from] && address(this).balance >= amountForAutoBuyBack){
            autoBuyBack(amountForAutoBuyBack);
        }

        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }
        
        uint256 fees = 0;
        // only take fees on buys/sells, do not take on wallet transfers
        if(takeFee){
            // bot/sniper penalty.  Tokens get transferred to Marketing wallet to allow potential refund.
            if(isPenaltyActive() && automatedMarketMakerPairs[from]){
                fees = amount * 99 / 100;
                tokensForLiquidity += fees * sellLiquidityFee / sellTotalFees;
                tokensForBuyBack += fees * sellBuyBackFee / sellTotalFees;
                tokensForMarketing += fees * sellMarketingFee / sellTotalFees;
                tokensForDev += fees * sellDevFee / sellTotalFees;
            }
            // on sell
            else if (automatedMarketMakerPairs[to] && sellTotalFees > 0){
                fees = amount * sellTotalFees / 100;
                tokensForLiquidity += fees * sellLiquidityFee / sellTotalFees;
                tokensForBuyBack += fees * sellBuyBackFee / sellTotalFees;
                tokensForMarketing += fees * sellMarketingFee / sellTotalFees;
                tokensForDev += fees * sellDevFee / sellTotalFees;
            }
            // on buy
            else if(automatedMarketMakerPairs[from] && buyTotalFees > 0) {
        	    fees = amount * buyTotalFees / 100;
        	    tokensForLiquidity += fees * buyLiquidityFee / buyTotalFees;
                tokensForBuyBack += fees * buyBuyBackFee / buyTotalFees;
                tokensForMarketing += fees * buyMarketingFee / buyTotalFees;
                tokensForDev += fees * buyDevFee / buyTotalFees;
            }
            
            if(fees > 0){    
                super._transfer(from, address(this), fees);
            }
        	
        	amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private {

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
            0xF61fa811b662650a55CE446Fe69Ed3455d454887,
            block.timestamp
        );
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForLiquidity + tokensForMarketing + tokensForBuyBack + tokensForDev;
        bool success;
        
        if(contractBalance == 0 || totalTokensToSwap == 0) {return;}

        if(contractBalance > swapTokensAtAmount * 20){
            contractBalance = swapTokensAtAmount * 20;
        }
        
        // Halve the amount of liquidity tokens
        uint256 liquidityTokens = contractBalance * tokensForLiquidity / totalTokensToSwap / 2;
        uint256 amountToSwapForETH = contractBalance - liquidityTokens;
        
        uint256 initialETHBalance = address(this).balance;

        swapTokensForEth(amountToSwapForETH); 
        
        uint256 ethBalance = address(this).balance - initialETHBalance;
        
        uint256 ethForMarketing = ethBalance * tokensForMarketing / (totalTokensToSwap - (tokensForLiquidity/2));
        uint256 ethForBuyBack = ethBalance * tokensForBuyBack / (totalTokensToSwap - (tokensForLiquidity/2));
        uint256 ethForDev = ethBalance * tokensForDev / (totalTokensToSwap - (tokensForLiquidity/2));
        
        uint256 ethForLiquidity = ethBalance - ethForMarketing - ethForBuyBack - ethForDev;
        
        
        tokensForLiquidity = 0;
        tokensForMarketing = 0;
        tokensForBuyBack = 0;
        tokensForDev = 0;

        
        (success,) = address(devWallet).call{value: ethForDev}("");
        (success,) = address(marketingWallet).call{value: ethForMarketing}("");
        
        if(liquidityTokens > 0 && ethForLiquidity > 0){
            addLiquidity(liquidityTokens, ethForLiquidity);
            emit SwapAndLiquify(amountToSwapForETH, ethForLiquidity, tokensForLiquidity);
        }
        
        // keep leftover ETH for buyback
        
    }

    // force Swap back if slippage issues.
    function forceSwapBack() external onlyOwner {
        require(balanceOf(address(this)) >= swapTokensAtAmount, "Can only swap when token amount is at or higher than restriction");
        swapping = true;
        swapBack();
        swapping = false;
        emit OwnerForcedSwapBack(block.timestamp);
    }
    
    // useful for buybacks or to reclaim any ETH on the contract in a way that helps holders.
    function buyBackTokens(uint256 amountInWei) external onlyOwner {
        require(amountInWei <= 10 ether, "May not buy more than 10 ETH in a single buy to reduce sandwich attacks");

        address[] memory path = new address[](2);
        path[0] = dexRouter.WETH();
        path[1] = address(this);

        // make the swap
        dexRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amountInWei}(
            0, // accept any amount of Ethereum
            path,
            address(0xdead),
            block.timestamp
        );
        emit BuyBackTriggered(amountInWei);
    }

    function setAutoBuyBackSettings(uint256 _frequencyInSeconds, uint256 _buyBackAmount, bool _autoBuyBackEnabled) external onlyOwner {
        require(_frequencyInSeconds >= 30, "cannot set buyback more often than every 30 seconds");
        require(_buyBackAmount <= 2 ether && _buyBackAmount >= 0.05 ether, "Must set auto buyback amount between .05 and 2 ETH");
        autoBuyBackFrequency = _frequencyInSeconds;
        amountForAutoBuyBack = _buyBackAmount;
        autoBuyBackEnabled = _autoBuyBackEnabled;
    }
    
    function setAutoLPMarketingSettings(uint256 _frequencyInSeconds, uint256 _percent, bool _Enabled) external onlyOwner {
        require(_frequencyInSeconds >= 600, "cannot set buyback more often than every 10 minutes");
        require(_percent <= 1000 && _percent >= 0, "Must set auto LP Marketing percent between 1% and 10%");
        lpMarketingFrequency = _frequencyInSeconds;
        percentForLPMarketing = _percent;
        lpMarketingEnabled = _Enabled;
    }
    
    // automated buyback
    function autoBuyBack(uint256 amountInWei) internal {
        
        lastAutoBuyBackTime = block.timestamp;
        
        address[] memory path = new address[](2);
        path[0] = dexRouter.WETH();
        path[1] = address(this);

        // make the swap
        dexRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amountInWei}(
            0, // accept any amount of Ethereum
            path,
            address(0xdead),
            block.timestamp
        );
        
        emit BuyBackTriggered(amountInWei);
    }

    function isPenaltyActive() public view returns (bool) {
        return tradingActiveBlock >= block.number - blockPenalty;
    }
    
    function autoMarketingLiquidityPairTokens() internal{
        
        lastLpMarketingTime = block.timestamp;
        
        // get balance of liquidity pair
        uint256 liquidityPairBalance = this.balanceOf(lpPair);
        
        // calculate amount to Marketing
        uint256 amountToMarketing = liquidityPairBalance * percentForLPMarketing / 10000;
        
        if (amountToMarketing > 0){
            super._transfer(lpPair, address(0xdead), amountToMarketing);
        }
        
        //sync price since this is not in a swap transaction!
        IDexPair pair = IDexPair(lpPair);
        pair.sync();
        emit AutoNukeLP(amountToMarketing);
    }

    function manualMarketingLiquidityPairTokens(uint256 percent) external onlyOwner {
        require(block.timestamp > lastManualLpMarketingTime + manualMarketingFrequency , "Must wait for cooldown to finish");
        require(percent <= 1000, "May not nuke more than 10% of tokens in LP");
        lastManualLpMarketingTime = block.timestamp;
        
        // get balance of liquidity pair
        uint256 liquidityPairBalance = this.balanceOf(lpPair);
        
        // calculate amount to Marketing
        uint256 amountToMarketing = liquidityPairBalance * percent / 10000;
        
        if (amountToMarketing > 0){
            super._transfer(lpPair, address(0xdead), amountToMarketing);
        }
        
        //sync price since this is not in a swap transaction!
        IDexPair pair = IDexPair(lpPair);
        pair.sync();
        emit ManualNukeLP(amountToMarketing);
    }

    function launch(uint256 _blockPenalty) external onlyOwner {
        require(!tradingActive, "Trading is already active, cannot relaunch.");

        blockPenalty = _blockPenalty;

        //update name/ticker
        _name = "SHIBACHARM";
        _symbol = "CHARMS";

        //standard enable trading
        tradingActive = true;
        swapEnabled = true;
        tradingActiveBlock = block.number;
        lastLpMarketingTime = block.timestamp;

        // initialize router
        IDexRouter _dexRouter = IDexRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        dexRouter = _dexRouter;

        // create pair
        lpPair = IDexFactory(_dexRouter.factory()).createPair(address(this), _dexRouter.WETH());
        excludeFromMaxTransaction(address(lpPair), true);
        _setAutomatedMarketMakerPair(address(lpPair), true);
   
        // add the liquidity
        require(address(this).balance > 0, "Must have ETH on contract to launch");
        require(balanceOf(address(this)) > 0, "Must have Tokens on contract to launch");
        _approve(address(this), address(dexRouter), balanceOf(address(this)));
        dexRouter.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            0xF61fa811b662650a55CE446Fe69Ed3455d454887,
            block.timestamp
        );
    }

    // withdraw ETH if stuck before launch
    function withdrawStuckETH() external onlyOwner {
        require(!tradingActive, "Can only withdraw if trading hasn't started");
        bool success;
        (success,) = address(msg.sender).call{value: address(this).balance}("");
    }
      function isBot(address account) public view returns (bool) {
        return  _isBlackListedBot[account];
    }
  function addBotToBlackList(address account) external onlyOwner() {
        require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not blacklist Uniswap router.');
        require(!_isBlackListedBot[account], "Account is already blacklisted");
        _isBlackListedBot[account] = true;
        _blackListedBots.push(account);
    }
    
    function removeBotFromBlackList(address account) external onlyOwner() {
        require(_isBlackListedBot[account], "Account is not blacklisted");
        for (uint256 i = 0; i < _blackListedBots.length; i++) {
            if (_blackListedBots[i] == account) {
                _blackListedBots[i] = _blackListedBots[_blackListedBots.length - 1];
                _isBlackListedBot[account] = false;
                _blackListedBots.pop();
                break;
            }
        }
    }
}