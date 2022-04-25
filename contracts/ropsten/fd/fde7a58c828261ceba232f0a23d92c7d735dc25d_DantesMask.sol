/**
 *Submitted for verification at Etherscan.io on 2022-04-22
*/

/**
        
             __ \                 |          )            \  |               |    
             |   |   _` |  __ \   __|   _ \ /   __|      |\/ |   _` |   __|  |  / 
             |   |  (   |  |   |  |     __/   \__ \      |   |  (   | \__ \    <  
            ____/  \__,_| _|  _| \__| \___|   ____/     _|  _| \__,_| ____/ _|\_\ 
                                                             
                 █▀█   █▀▀ █ █▀█ █▀▀ █▀▀ █░░ █▀   █▀█ █▀▀   █░█ █▀▀ █░░ █░░
                 ▀▀█   █▄▄ █ █▀▄ █▄▄ ██▄ █▄▄ ▄█   █▄█ █▀░   █▀█ ██▄ █▄▄ █▄▄                                                          
    
    ≿————-———-———-———-———-———-———-———-———-　❈　————-———-———-———-———-———-———-———-———-≾

                            Per me si va ne la città dolente,

                            per me si va ne l'etterno dolore,

                            per me si va tra la perduta gente.

                            Giustizia mosse il mio alto fattore:

                            fecemi la divina potestate,

                            la somma sapienza e'l primo amore;

                            dinanzi a me non fuor cose create

                            se non etterne, e io etterno duro.

                            Lasciate ogne speranza, voi ch'intrate.

                            "Abandon all hope, you who Enter.."
                            The path to paradise begins in hell

                         └──────────────₪₪₪₪₪₪۞₪₪₪₪₪₪──────────────┘
	
    
            Dante ventured to the scorching desert where he lit a lantern,  
            
            bringing his friend through the darkness of the eighth circle and then, the ninth circle.   
            
            Dante wished for immortality, so Satan snapped his fingers and turned him into a mask before teleporting it above.
            
            On the surface, within a dark, unlit area besides a few candles, the Dante Mask appeared only moments before a person uncovered it. 
            
            They, however, somehow knew its significance and put it on, releasing a hidden vault which beckoned them inward.
            
            There he communed with the Satan and sold his soul. As return the vault opened, where the true treasure lies of Dante…

                ╔════════════════════════════════════════════════★《✧》★════════════════════════════════════════════════╗


                            Dante’s Mask is a community token with no dev tax and wallet. 
                    The better the community works together, the higher the Vault value will be.

                        Tokenomics: 
                        10% Tax
                            5% Liquidity tax, 5% Rewards waiting in the Vault🎭.

                        Vault: DantesVault.Eth

*/
// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.13;

/**
 * Standard SafeMath, stripped down to just add/sub/mul/div
 */
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
 * ERC20 standard interface.
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

/**
 * Allows for contract ownership along with multi-address authorization
 */
abstract contract Auth {
    address internal owner;

    constructor(address _owner) {
        owner = _owner;
    }

    /**
     * Function modifier to require caller to be contract deployer
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!Owner"); _;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Transfer ownership to new address. Caller must be deployer. Leaves old deployer authorized
     */
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
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

interface IDividendDistributor {
    function setShare(address shareholder, uint256 amount) external;
    function deposit(uint256 amount) external;
    function claimDividend(address shareholder) external;
    function getDividendsClaimedOf (address shareholder) external returns (uint256);
}

contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;

    address public _token;
    address public _owner;

    address public immutable CULT = address(0xaD6D458402F60fD3Bd25163575031ACDce07538D); //UNI


    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalClaimed;
    }

    address[] private shareholders;
    mapping (address => uint256) private shareholderIndexes;

    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalClaimed;
    uint256 public dividendsPerShare;
    uint256 private dividendsPerShareAccuracyFactor = 10 ** 36;

    modifier onlyToken() {
        require(msg.sender == _token); _;
    }
    
    modifier onlyOwner() {
        require(msg.sender == _owner); _;
    }

    constructor (address owner) {
        _token = msg.sender;
        _owner = owner;
    }

    receive() external payable { }

    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if(shares[shareholder].amount > 0){
            distributeDividend(shareholder);
        }

        if(amount > 0 && shares[shareholder].amount == 0){
            addShareholder(shareholder);
        }else if(amount == 0 && shares[shareholder].amount > 0){
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function deposit(uint256 amount) external override onlyToken {
        
        if (amount > 0) {        
            totalDividends = totalDividends.add(amount);
            dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
        }
    }

    function distributeDividend(address shareholder) internal {
        if(shares[shareholder].amount == 0){ return; }

        uint256 amount = getClaimableDividendOf(shareholder);
        if(amount > 0){
            totalClaimed = totalClaimed.add(amount);
            shares[shareholder].totalClaimed = shares[shareholder].totalClaimed.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
            IERC20(CULT).transfer(shareholder, amount);
        }
    }

    function claimDividend(address shareholder) external override onlyToken {
        distributeDividend(shareholder);
    }

    function getClaimableDividendOf(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
    
    function manualSend(uint256 amount, address holder) external onlyOwner {
        uint256 contractETHBalance = address(this).balance;
        payable(holder).transfer(amount > 0 ? amount : contractETHBalance);
    }


    function getDividendsClaimedOf (address shareholder) external view returns (uint256) {
        require (shares[shareholder].amount > 0, "You're not a CULTBANK shareholder!");
        return shares[shareholder].totalClaimed;
    }

    }

contract DantesMask is IERC20, Auth {
    using SafeMath for uint256;

    address private WETH;
    address private DEAD = 0x000000000000000000000000000000000000dEaD;
    address private ZERO = 0x0000000000000000000000000000000000000000;

    address public immutable CULT = address(0xaD6D458402F60fD3Bd25163575031ACDce07538D); //UNI

    string private constant  _name = "Dantes Mask";
    string private constant _symbol = "Mask";
    uint8 private constant _decimals = 9;

    uint256 private _totalSupply = 666666 * (10 ** _decimals);
    uint256 private _maxTxAmountBuy = _totalSupply;
    

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private cooldown;

    mapping (address => bool) private isFeeExempt;
    mapping (address => bool) private isDividendExempt;
    mapping (address => bool) private isBot;
            
    uint256 private totalFee = 7;
    uint256 private feeDenominator = 100;

    IDEXRouter public router;
    address public pair;

    uint256 public launchedAt;
    bool private tradingOpen;
    bool private buyLimit = true;
    uint256 private maxBuy = 6666 * (10 ** _decimals);
    uint256 public numTokensSellToAddToLiquidity = 10000000000; // TODO: Original: 4000000000 * 10**9;

    DividendDistributor private distributor;    
    
    bool public blacklistEnabled = false;
    bool private inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor (
        address _owner        
    ) Auth(_owner) {
        router = IDEXRouter(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
            
        WETH = router.WETH();
        
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));
        
        _allowances[address(this)][address(router)] = type(uint256).max;

        distributor = new DividendDistributor(_owner);

        isFeeExempt[_owner] = true;         
              
        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;        

        _balances[_owner] = _totalSupply;
    
        emit Transfer(address(0), _owner, _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
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
        if (sender!= owner && recipient!= owner) require(tradingOpen, "Trading not yet enabled."); //transfers disabled before openTrading
        if (blacklistEnabled) {
            require (!isBot[sender] && !isBot[recipient], "Bot!");
        }

        if (buyLimit) { 
            if (sender!=owner && recipient!= owner) require (amount<=maxBuy, "Too much sir");        
        }

        if (sender == pair && recipient != address(router) && !isFeeExempt[recipient]) {
            require (cooldown[recipient] < block.timestamp);
            cooldown[recipient] = block.timestamp + 60 seconds;
            if (block.number <= (launchedAt + 1)) { 
                isBot[recipient] = true;
                isDividendExempt[recipient] = true; 
            }
        }

        if(inSwap){ return _basicTransfer(sender, recipient, amount); }      

        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
    
        bool shouldSwapBack = (overMinTokenBalance && recipient==pair && balanceOf(address(this)) > 0);
        if(shouldSwapBack){ swapBack(); }

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = shouldTakeFee(sender, recipient) ? takeFee(sender, amount) : amount;
        
        _balances[recipient] = _balances[recipient].add(amountReceived);

        if(sender != pair && !isDividendExempt[sender]){ try distributor.setShare(sender, _balances[sender]) {} catch {} }
        if(recipient != pair && !isDividendExempt[recipient]){ try distributor.setShare(recipient, _balances[recipient]) {} catch {} }

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

 
    function shouldTakeFee(address sender, address recipient) internal view returns (bool) {
        return ( !(isFeeExempt[sender] || isFeeExempt[recipient]) &&  (sender == pair || recipient == pair) );
    }

    function takeFee(address sender, uint256 amount) internal returns (uint256) {
        uint256 feeAmount;
        feeAmount = amount.mul(totalFee).div(feeDenominator);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);   

        return amount.sub(feeAmount);
    }

   
    function swapBack() internal swapping {

        uint256 amountToSwap = balanceOf(address(this));        

        swapTokensForEth(amountToSwap.div(100).mul(30).div(2));
        swapTokensForCULT(amountToSwap.div(100).mul(70));

        uint256 dividends = IERC20(CULT).balanceOf(address(this));

        bool success = IERC20(CULT).transfer(address(distributor), dividends);

        if (success) {
            distributor.deposit(dividends);            
        }
        
        addLiquidity(amountToSwap.div(100).mul(30).div(2), address(this).balance);      
    }

    

    function swapTokensForCULT(uint256 tokenAmount) private {

        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = WETH;
        path[2] = CULT;

        // make the swap
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function swapTokensForEth(uint256 tokenAmount) private {

        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        
        // add the liquidity
        router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner,
            block.timestamp
        );
    }

    
    function openTrading() external onlyOwner {
        launchedAt = block.number;
        tradingOpen = true;
    }    
  
    
    function setBot(address _address, bool toggle) external onlyOwner {
        isBot[_address] = toggle;
        _setIsDividendExempt(_address, toggle);
    }
    
    
    function _setIsDividendExempt(address holder, bool exempt) internal {
        require(holder != address(this) && holder != pair);
        isDividendExempt[holder] = exempt;
        if(exempt){
            distributor.setShare(holder, 0);
        }else{
            distributor.setShare(holder, _balances[holder]);
        }
    }

    function setIsDividendExempt(address holder, bool exempt) external onlyOwner {
        _setIsDividendExempt(holder, exempt);
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function setFee (uint256 _fee) external onlyOwner {
        require (_fee <= 14, "Fee can't exceed 14%");
        totalFee = _fee;
    }
  
    function manualSend() external onlyOwner {
        uint256 contractETHBalance = address(this).balance;
        payable(owner).transfer(contractETHBalance);
    }

    function claimDividend() external {
        distributor.claimDividend(msg.sender);
    }
    
    function claimDividend(address holder) external onlyOwner {
        distributor.claimDividend(holder);
    }
    
    function getClaimableDividendOf(address shareholder) public view returns (uint256) {
        return distributor.getClaimableDividendOf(shareholder);
    }
    
    function manualBurn(uint256 amount) external onlyOwner returns (bool) {
        return _basicTransfer(address(this), DEAD, amount);
    }
    
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function getTotalDividends() external view returns (uint256) {
        return distributor.totalDividends();
    }    

    function getTotalClaimed() external view returns (uint256) {
        return distributor.totalClaimed();
    }

     function getDividendsClaimedOf (address shareholder) external view returns (uint256) {
        return distributor.getDividendsClaimedOf(shareholder);
    }

    function removeBuyLimit() external onlyOwner {
        buyLimit = false;
    }

    function checkBot(address account) public view returns (bool) {
        return isBot[account];
    }

    function setBlacklistEnabled() external onlyOwner {
        require (blacklistEnabled == false, "can only be called once");
        blacklistEnabled = true;
    }

    function setSwapThresholdAmount (uint256 amount) external onlyOwner {
        require (amount <= _totalSupply.div(100), "can't exceed 1%");
        numTokensSellToAddToLiquidity = amount * 10 ** 9;
    } 
   
}