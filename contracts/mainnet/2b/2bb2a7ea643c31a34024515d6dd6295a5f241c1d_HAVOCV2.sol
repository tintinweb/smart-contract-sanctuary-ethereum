/**
 *Submitted for verification at Etherscan.io on 2022-08-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/**CRY 'HAVOC!', AND LET SLIP THE DOGS OF WAR!
   No fancy test pictures here, just straight up legit info in order to join the Havoc Movement and Anarchy Ecosystem
   OFFICIAL TELEGRAM: https://t.me/HAVOCERC_PORTAL
   OFFICIAL WEBSITE: www.havocv2.com
   OFFICIAL TWITTER: https://twitter.com/havoc_erc
   OFFICIAL MEDIUM: https://medium.com/@havocerc
*/

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

abstract contract Auth {
    address internal owner;

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!Owner"); _;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

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

interface DogsOfWar {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function process(uint256 gas) external;
    function cryHavoc(address shareholder) external;
    function changeReflection(address newReflection, string calldata newTicker) external;
}


contract LifeOnTheStreet is DogsOfWar {

    address _token;
    address public CHEWY;
    string public reflectionTicker;

    IDEXRouter router;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;
    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;

    uint256 public minPeriod = 30 minutes;
    uint256 public minDistribution = 0 * (10 ** 9);

    uint256 public currentIndex;
    bool initialized;

    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    modifier onlyToken() {
        require(msg.sender == _token); _;
    }

    constructor () {
        _token = msg.sender;
        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        CHEWY = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;
	reflectionTicker = "UNI";
    }
    
    receive() external payable {
        deposit();
    }

    function changeReflection(address newReflection, string calldata newTicker) external override onlyToken {
        CHEWY = newReflection;
	reflectionTicker = newTicker;
    }   

    function setDistributionCriteria(uint256 newMinPeriod, uint256 newMinDistribution) external override onlyToken {
        minPeriod = newMinPeriod;
        minDistribution = newMinDistribution;
    } 

    function setShare(address shareholder, uint256 amount) external override onlyToken {

        if(shares[shareholder].amount > 0){
            distributeDividend(shareholder);
        }

        if(amount > 0 && shares[shareholder].amount == 0){
            addShareholder(shareholder);
        }else if(amount == 0 && shares[shareholder].amount > 0){
            removeShareholder(shareholder);
        }

        totalShares = totalShares - (shares[shareholder].amount) + amount;
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function deposit() public payable override {

        uint256 balanceBefore = IERC20(CHEWY).balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(CHEWY);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = IERC20(CHEWY).balanceOf(address(this)) - balanceBefore;
        totalDividends = totalDividends + amount;
        dividendsPerShare = dividendsPerShare + (dividendsPerShareAccuracyFactor * amount / totalShares);
    }
    
    function process(uint256 gas) external override {
        uint256 shareholderCount = shareholders.length;

        if(shareholderCount == 0) { return; }

        uint256 iterations = 0;
        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        while(gasUsed < gas && iterations < shareholderCount) {

            if(currentIndex >= shareholderCount){ currentIndex = 0; }

            if(shouldDistribute(shareholders[currentIndex])){
                distributeDividend(shareholders[currentIndex]);
            }

            gasUsed = gasUsed + (gasLeft - gasleft());
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }
    
    function shouldDistribute(address shareholder) public view returns (bool) {
        return shareholderClaims[shareholder] + minPeriod < block.timestamp
                && getUnpaidEarnings(shareholder) > minDistribution;
    }

    function distributeDividend(address shareholder) internal {
        if(shares[shareholder].amount == 0){ return; }

        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){
            totalDistributed = totalDistributed + amount;
            IERC20(CHEWY).transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised + amount;
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }
    
    function cryHavoc(address shareholder) external override onlyToken {
        distributeDividend(shareholder);
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends - shareholderTotalExcluded;
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share * dividendsPerShare / dividendsPerShareAccuracyFactor;
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

}

contract HAVOCV2 is IERC20, Auth {

    address private WETH;
    address public CHEWY = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;
    string public reflectionTicker = "UNI";

    string private constant _name = "HAVOCV2";
    string private constant _symbol = "$HAVOCV2";
    uint8 private constant _decimals = 18;
    
    uint256 _totalSupply = 100 * 10**6 * (10 ** _decimals);
    uint256 public maxTx = 1 * 10**6 * (10 ** _decimals);
    uint256 public maxWallet = 2 * 10**6 * (10 ** _decimals);

    uint256 public swapThreshold = 1 * 10**5 * (10 ** _decimals);

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private cooldown;

    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    bool public antiBot = true;

    mapping (address => bool) private bots; 
    mapping (address => bool) public isFeeExempt;
    mapping (address => bool) public isTxLimitExempt;
    mapping (address => bool) public isDividendExempt;
    mapping (address => bool) public isWltExempt;

    uint256 public launchedAt;
    address private lpWallet = DEAD;

/**
 * PRE-LAUNCH taxes to tax snipers from deployment and LP pairing.
 */
    uint256 public buyFee = 10;
    uint256 public sellFee = 10;

    uint256 public toReflections = 20;
    uint256 public toLiquidity = 20;
    uint256 public toMarketing = 20;

    IDEXRouter public router;
    address public pair;
    address public factory;
    address private tokenOwner;
    address public campaignWallet = payable(0xBaC6A3636eC33FE1b3d380965386f190Bc957Ce4);
    address private whoLetTheDogsOut = payable(0x7Efa686efd1d689E7C6EEe6043569D9f5f5C570F);

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    bool public tradingOpen = false;
    
    LifeOnTheStreet public lifeOnTheStreet;

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor (
        address _owner        
    ) Auth(_owner) {
        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
            
        WETH = router.WETH();
        
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));
        
        _allowances[address(this)][address(router)] = type(uint256).max;

        lifeOnTheStreet = new LifeOnTheStreet();
        
        isFeeExempt[_owner] = true;
        isFeeExempt[campaignWallet] = true;
        isFeeExempt[whoLetTheDogsOut] = true;             

        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[whoLetTheDogsOut] = true;
        isDividendExempt[campaignWallet] = true;
        isDividendExempt[DEAD] = true;
        isDividendExempt[ZERO] = true;

        isTxLimitExempt[_owner] = true;
        isTxLimitExempt[pair] = true;
        isTxLimitExempt[DEAD] = true;
        isTxLimitExempt[ZERO] = true;
        isTxLimitExempt[campaignWallet] = true;
        isTxLimitExempt[whoLetTheDogsOut] = true;    

	    isWltExempt[_owner] = true;
    	isWltExempt[DEAD] = true;
    	isWltExempt[ZERO] = true;
    	isWltExempt[campaignWallet] = true;
    	isWltExempt[whoLetTheDogsOut] = true;

        _balances[_owner] = _totalSupply;
    
        emit Transfer(address(0), _owner, _totalSupply);
    }

    receive() external payable { }


    function setBots(address[] memory bots_) external onlyOwner {
        for (uint i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }

    function changeReflection(address newReflection, string calldata newTicker) external onlyOwner {
        lifeOnTheStreet.changeReflection(newReflection, newTicker);
        CHEWY = newReflection;
        reflectionTicker = newTicker;
    }

    //once enabled, cannot be reversed
    function openTrading() external onlyOwner {
        launchedAt = block.number;
        tradingOpen = true;
    }      

    function changeTotalFees(uint256 newBuyFee, uint256 newSellFee) external onlyOwner {

        buyFee = newBuyFee;
        sellFee = newSellFee;

        require(buyFee <= 10, "too high");
        require(sellFee <= 10, "too high");
    } 
    
    function changeFeeAllocation(uint256 newRewardFee, uint256 newLpFee, uint256 newMarketingFee) external onlyOwner {
        toReflections = newRewardFee;
        toLiquidity = newLpFee;
        toMarketing = newMarketingFee;
    }

    function changeTxLimit(uint256 newLimit) external onlyOwner {
        maxTx = newLimit;
    }

    function changeWalletLimit(uint256 newLimit) external onlyOwner {
        maxWallet  = newLimit;
    }
    function changeIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }
    
    function changeIsWltExempt(address holder, bool exempt) external onlyOwner {
        isWltExempt[holder] = exempt;
    }

    function changeIsTxLimitExempt(address holder, bool exempt) external onlyOwner {      
        isTxLimitExempt[holder] = exempt;
    }

    function setCampaignWallet(address payable newCampaignWallet) external onlyOwner {
        campaignWallet = payable(newCampaignWallet);
    }

    function setLpWallet(address newLpWallet) external onlyOwner {
        lpWallet = newLpWallet;
    }    

    function setOwnerWallet(address payable newOwnerWallet) external onlyOwner {
        tokenOwner = newOwnerWallet;
    }     

    function changeSwapBackSettings(bool enableSwapBack, uint256 newSwapBackLimit) external onlyOwner {
        swapAndLiquifyEnabled  = enableSwapBack;
        swapThreshold = newSwapBackLimit;
    }

    function setDistributionCriteria(uint256 newMinPeriod, uint256 newMinDistribution) external onlyOwner {
        lifeOnTheStreet.setDistributionCriteria(newMinPeriod, newMinDistribution);        
    }

    function delBot(address notbot) external onlyOwner {
        bots[notbot] = false;
    }

    function _setIsDividendExempt(address holder, bool exempt) internal {
        require(holder != address(this) && holder != pair);
        isDividendExempt[holder] = exempt;
        if(exempt){
            lifeOnTheStreet.setShare(holder, 0);
        }else{
            lifeOnTheStreet.setShare(holder, _balances[holder]);
        }
    }

    function setIsDividendExempt(address holder, bool exempt) external onlyOwner {
        _setIsDividendExempt(holder, exempt);
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply - balanceOf(DEAD) - balanceOf(ZERO);
    }

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
        return _transfer(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }

        return _transfer(sender, recipient, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        if (sender!= owner && recipient!= owner) require(tradingOpen, "Trading not active");
        require(!bots[sender] && !bots[recipient]);

        if(inSwapAndLiquify){ return _basicTransfer(sender, recipient, amount); }

        require(amount <= maxTx || isTxLimitExempt[sender], "tx");

        if(!isTxLimitExempt[recipient] && antiBot)
        {
            require(_balances[recipient] + amount <= maxWallet || isWltExempt[sender], "wallet");
        }



        if(msg.sender != pair && !inSwapAndLiquify && swapAndLiquifyEnabled && _balances[address(this)] >= swapThreshold){ swapBack(); }

        _balances[sender] = _balances[sender] - amount;
        
        uint256 finalAmount = !isFeeExempt[sender] && !isFeeExempt[recipient] ? takeFee(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient] + finalAmount;

        // Dividend tracker
        if(!isDividendExempt[sender]) {
            try lifeOnTheStreet.setShare(sender, _balances[sender]) {} catch {}
        }

        if(!isDividendExempt[recipient]) {
            try lifeOnTheStreet.setShare(recipient, _balances[recipient]) {} catch {} 
        }

        emit Transfer(sender, recipient, finalAmount);
        return true;
    }    

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }  
    
    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        
        uint256 feeApplicable = pair == recipient ? sellFee : buyFee;
        uint256 feeAmount = amount * feeApplicable / 100;

        _balances[address(this)] = _balances[address(this)] + feeAmount;
        emit Transfer(sender, address(this), feeAmount);

        return amount - feeAmount;
    }
    
    function swapTokensForEth(uint256 tokenAmount) private {

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        approve(address(this), tokenAmount);

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            lpWallet,
            block.timestamp
        );
    }

    function swapBack() internal lockTheSwap {
    
        uint256 tokenBalance = _balances[address(this)]; 
        uint256 tokensForLiquidity = tokenBalance * toLiquidity / 60 / 2;     
        uint256 amountToSwap = tokenBalance - tokensForLiquidity;

        swapTokensForEth(amountToSwap);

        uint256 totalEthBalance = address(this).balance;
        uint256 ethForCHEWY = totalEthBalance * toReflections / 60;
        uint256 ethForCampaignWallet = totalEthBalance * toMarketing / 60;
        uint256 ethForLiquidity = totalEthBalance * toLiquidity / 60 / 2;
      
        if (totalEthBalance > 0){
            payable(campaignWallet).transfer(ethForCampaignWallet);
        }
        
        try lifeOnTheStreet.deposit{value: ethForCHEWY}() {} catch {}
        
        if (tokensForLiquidity > 0){
            addLiquidity(tokensForLiquidity, ethForLiquidity);
        }
    }

    function manualSwapBack() external onlyOwner {
        swapBack();
    }

    function clearStuckEth() external onlyOwner {
        uint256 contractETHBalance = address(this).balance;
        if(contractETHBalance > 0){          
            payable(campaignWallet).transfer(contractETHBalance);
        }
    }

    function manualProcessGas(uint256 manualGas) external onlyOwner {
        lifeOnTheStreet.process(manualGas);
    }

    function checkPendingReflections(address shareholder) external view returns (uint256) {
        return lifeOnTheStreet.getUnpaidEarnings(shareholder);
    }

    function milkbone() external {
        lifeOnTheStreet.cryHavoc(msg.sender);
    }
}
/**Covah's story:

   Covah was a simple, loyal pet in a happy home. Cared for and loved by
   his retiree owner, fed well and free to roam. Life was good... until 
   it wasn't.

   His owner was a hardworking, good-hearted human who believed in the 
   order and safety offered by centralization, believed that the wolves 
   that run the system had the people's best interest at heart. He 
   invested in company stocks, saved years' worth of income set aside in 
   a 401k for his golden years. When he retired, he was certain he had 
   enough to live out his remaining years in peace and relative ease.

   ... wrong.


   The shady criminals on Wall Street saw how easy it was to buy 
   influence from politicians, so they hatched a devious scheme to steal 
   common peoples money out of the stock market. Through multiple 
   "strategies", they corrupted and perverted the concept of a fair 
   market. They geared everything towards taking as much money from the 
   poors as possible, destroying companies by synthetically shorting the 
   prices into oblivion all while gleefully stealing the money of honest, 
   gullible, people like Covah's owner.

   Covah's owner watched his investments die, and any hopes of a 
   peaceful, happy retirement die with them. He slowly stopped smiling. 
   Stopped smiling. Every day became a struggle just to feed himself, 
   though he never let Covah go hungry.


   Covah saw the change in his owner-friend and grew sad.. seeing that 
   Covah never went unfed, but his spirit was crushed.


   One day while looking through Reddit, Covah found the truth. He read 
   countless examples of how the vile bastards in control were stealing 
   everyone's money and blowing it on yachts, cocaine, hookers, private 
   jets, and trips to the Caymans. He was LIVID.

   It was on. It was time to break these crooks and their thieving 
   system. Flipping the script, he went from being a passive, happy-go-
   lucky pooch to match his new outlook and name: Havoc. He vowed to burn 
   it all down. He helped his master move what little funds he had left 
   to somewhere the bastards couldn't mess with, into the cryptoverse.

   Havoc had to navigate the huge amount of complete scum that permeated 
   the decentralized blockchain, the scammers, thieves, rug-artists, and 
   dishonest devs had already begun to plague the space as well. Covah 
   believes the biggest movers are probably from Wall Street or 
   governments who are trying to cause as much loss for believers as 
   possible so they can enforce centralized control on the blockchain.

   Havoc made his token with one goal in mind: BREAK THE SYSTEM

   "Cry Havoc, and let slip the dogs of war!"

   Because make no mistake, this is a war. A war for the right to control 
   our own finances and future. To not have the greedy, self-serving, 
   evil pricks take everything from us. Expose the lies. Expose the 
   enemies.
*/