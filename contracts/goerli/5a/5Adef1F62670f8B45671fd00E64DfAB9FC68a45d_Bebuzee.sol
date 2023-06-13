/**
 *Submitted for verification at Etherscan.io on 2023-06-13
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

// Library

abstract contract Ownable {
    
    // DATA

    address private _owner;

    // MAPPING

    mapping(address => bool) internal authorizations;

    // MODIFIER

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    modifier authorized() {
        _checkAuthorization();
        _;
    }
    
    // CONSTRUCTOR

    constructor() {
        _transferOwnership(msg.sender);
        authorizations[msg.sender] = true;
    }

    // EVENT

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // FUNCTION

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
    }

    function _checkAuthorization() internal view virtual {
        require(isAuthorized(msg.sender), "Ownable: caller is not an authorized account");
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// Interface

interface IERC20 {
    
    //EVENT 

    event Transfer(address indexed from, address indexed to, uint256 value);
    
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // FUNCTION

    function name() external view returns (string memory);
    
    function symbol() external view returns (string memory);
    
    function decimals() external view returns (uint8);
    
    function totalSupply() external view returns (uint256);
    
    function balanceOf(address account) external view returns (uint256);
    
    function transfer(address to, uint256 amount) external returns (bool);
    
    function allowance(address owner, address spender) external view returns (uint256);
    
    function approve(address spender, uint256 amount) external returns (bool);
    
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface IFactory {

    // FUNCTION

    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IRouter {

    // FUNCTION

    function WETH() external pure returns (address);
        
    function factory() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external;
    
    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external payable;

    function addLiquidityETH(address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
}

// Token

contract Bebuzee is Ownable, IERC20 {

    // DATA

    struct Ratios {
        uint256 operation;
        uint256 liquidity;
        uint256 marketing;
        uint256 team;
    }

    string private constant NAME = "Bebuzee";
    string private constant SYMBOL = "XBZ";

    uint8 private constant DECIMALS = 18;

    uint256 private _totalSupply;
    
    uint256 public constant FEEDENOMINATOR = 10_000;
    uint256 public constant BUYFEETOTAL = 40;
    uint256 public constant SELLFEETOTAL = 40;
    uint256 public constant TRANSFERFEETOTAL = 40;

    uint256 public operationFeeCollected = 0;
    uint256 public liquidityFeeCollected = 0;
    uint256 public marketingFeeCollected = 0;
    uint256 public teamFeeCollected = 0;
    uint256 public totalFeeCollected = 0;
    uint256 public operationFeeRedeemed = 0;
    uint256 public liquidityFeeRedeemed = 0;
    uint256 public marketingFeeRedeemed = 0;
    uint256 public teamFeeRedeemed = 0;
    uint256 public totalFeeRedeemed = 0;
    uint256 public minSwap = 100 ether;

    bool private constant ISBEBUZEE = true;

    bool public isFeeActive = false;
    bool public isFeeLocked = false;
    bool public isSwapEnabled = false;
    bool public inSwap = false;

    address public constant ZERO = address(0);
    address public constant DEAD = address(0xdead);

    address public pair;

    address public operationReceiver = 0x31979D47a0698FfF8122365641E6F12992119a0b;
    address public liquidityReceiver = 0x31979D47a0698FfF8122365641E6F12992119a0b;
    address public marketingReceiver = 0x31979D47a0698FfF8122365641E6F12992119a0b;
    address public teamReceiver = 0x31979D47a0698FfF8122365641E6F12992119a0b;

    Ratios public buyFeeRatios = Ratios({ operation: 6000, liquidity: 2000, marketing: 1000, team: 1000 });
    Ratios public sellFeeRatios = Ratios({ operation: 6000, liquidity: 2000, marketing: 1000, team: 1000 });
    Ratios public transferFeeRatios = Ratios({ operation: 6000, liquidity: 2000, marketing: 1000, team: 1000 });

    IRouter public router;

    // MAPPING

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public isExcludeFromFees;

    // MODIFIER

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    // CONSTRUCTOR

    constructor() Ownable () {
        _mint(msg.sender, 100_000_000_000 ether);

        router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        pair = IFactory(router.factory()).createPair(address(this), router.WETH());
    }

    // EVENT

    event UpdateRouter(address oldRouter, address newRouter, uint256 timestamp);

    event UpdateMinSwap(uint256 oldMinSwap, uint256 newMinSwap, uint256 timestamp);

    event UpdateFeeActive(bool oldStatus, bool newStatus, uint256 timestamp);

    event UpdateSwapEnabled(bool oldStatus, bool newStatus, uint256 timestamp);

    event UpdateLiquifyEnabled(bool oldStatus, bool newStatus, uint256 timestamp);

    event RedeemLiquidity(uint256 amountToken, uint256 amountETH, uint256 liquidity, uint256 timestamp);

    event UpdateOperationReceiver(address oldOperationReceiver, address newOperationReceiver, uint256 timestamp);
    
    event UpdateLiquidityReceiver(address oldLiquidityReceiver, address newLiquidityReceiver, uint256 timestamp);
    
    event UpdateMarketingReceiver(address oldMarketingReceiver, address newMarketingReceiver, uint256 timestamp);

    event UpdateTeamReceiver(address oldTeamReceiver, address newTeamReceiver, uint256 timestamp);

    event AutoRedeem(uint256 operationFeeDistribution, uint256 liquidityFeeDistribution, uint256 marketingFeeDistribution, uint256 teamFeeDistribution, uint256 amountToRedeem, uint256 timestamp);

    event EtherTransfer(address beneficiary, uint256 amount);

    // FUNCTION

    /* General */

    receive() external payable {}

    function finalizePresale() external authorized {
        require(!isFeeActive, "Finalize Presale: Fee already active.");
        require(!isSwapEnabled, "Finalize Presale: Swap already enabled.");
        isFeeActive = true;
        isSwapEnabled = true;
    }

    function lockFees() external authorized {
        require(!isFeeLocked, "Lock Fees: All fees were already locked.");
        isFeeLocked = true;
    }

    function redeemAllOperationFee() external {
        uint256 amountToRedeem = operationFeeCollected - operationFeeRedeemed;
        
        _redeemOperationFee(amountToRedeem);
    }

    function redeemPartialOperationFee(uint256 amountToRedeem) external {
        require(amountToRedeem <= operationFeeCollected - operationFeeRedeemed, "Redeem Partial Operation Fee: Insufficient operation fee collected.");
        
        _redeemOperationFee(amountToRedeem);
    }

    function _redeemOperationFee(uint256 amountToRedeem) internal swapping { 
        operationFeeRedeemed += amountToRedeem;
        totalFeeRedeemed += amountToRedeem;
 
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), amountToRedeem);

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToRedeem,
            0,
            path,
            operationReceiver,
            block.timestamp
        );
    }

    function redeemAllLiquidityFee() external {
        uint256 amountToRedeem = liquidityFeeCollected - liquidityFeeRedeemed;
        
        _redeemLiquidityFee(amountToRedeem);
    }

    function redeemPartialLiquidityFee(uint256 amountToRedeem) external {
        require(amountToRedeem <= liquidityFeeCollected - liquidityFeeRedeemed, "Redeem Partial Liquidity Fee: Insufficient liquidity fee collected.");
        
        _redeemLiquidityFee(amountToRedeem);
    }

    function _redeemLiquidityFee(uint256 amountToRedeem) internal swapping returns (uint256) {   
        require(msg.sender != liquidityReceiver, "Redeem Liquidity Fee: Liquidity receiver cannot call this function.");
        uint256 initialBalance = address(this).balance;
        uint256 firstLiquidityHalf = amountToRedeem / 2;
        uint256 secondLiquidityHalf = amountToRedeem - firstLiquidityHalf;

        liquidityFeeRedeemed += amountToRedeem;
        totalFeeRedeemed += amountToRedeem;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), amountToRedeem);

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            firstLiquidityHalf,
            0,
            path,
            address(this),
            block.timestamp
        );
        
        (, , uint256 liquidity) = router.addLiquidityETH{
            value: address(this).balance - initialBalance
        }(
            address(this),
            secondLiquidityHalf,
            0,
            0,
            liquidityReceiver,
            block.timestamp + 1_200
        );

        return liquidity;
    }

    function redeemAllMarketingFee() external {
        uint256 amountToRedeem = marketingFeeCollected - marketingFeeRedeemed;
        
        _redeemMarketingFee(amountToRedeem);
    }

    function redeemPartialMarketingFee(uint256 amountToRedeem) external {
        require(amountToRedeem <= marketingFeeCollected - marketingFeeRedeemed, "Redeem Partial Marketing Fee: Insufficient marketing fee collected.");
        
        _redeemMarketingFee(amountToRedeem);
    }

    function _redeemMarketingFee(uint256 amountToRedeem) internal swapping { 
        marketingFeeRedeemed += amountToRedeem;
        totalFeeRedeemed += amountToRedeem;
 
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), amountToRedeem);

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToRedeem,
            0,
            path,
            marketingReceiver,
            block.timestamp
        );
    }

    function redeemAllTeamFee() external {
        uint256 amountToRedeem = teamFeeCollected - teamFeeRedeemed;
        
        _redeemTeamFee(amountToRedeem);
    }

    function redeemPartialTeamFee(uint256 amountToRedeem) external {
        require(amountToRedeem <= teamFeeCollected - teamFeeRedeemed, "Redeem Partial Team Fee: Insufficient team fee collected.");
        
        _redeemTeamFee(amountToRedeem);
    }

    function _redeemTeamFee(uint256 amountToRedeem) internal swapping {   
        teamFeeRedeemed += amountToRedeem;
        totalFeeRedeemed += amountToRedeem;
 
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), amountToRedeem);

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToRedeem,
            0,
            path,
            teamReceiver,
            block.timestamp
        );
    }

    /* Airdrop */

    function dropDifferentSpecificTokens(
        IERC20 token,
        address[] memory recipients,
        uint256[] memory amount
    ) external returns (bool) {   
        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0));
            require(IERC20(token).transfer(recipients[i], amount[i]));
        }
        return true;
    }

    function dropSimilarSpecificTokens(
        IERC20 token,
        address[] memory recipients,
        uint256 amount
    ) external returns (bool) {
        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0));
            require(IERC20(token).transfer(recipients[i], amount));
        }
        return true;
    }

    function dropDifferentSpecificEther(
        address[] memory recipients,
        uint256[] memory amount
    ) public payable returns (bool) {
        uint256 total = 0;
        for(uint256 j = 0; j < amount.length; j++) {
            total = total + amount[j];
        }

        require(total <= msg.value, "Amount sent to be dropped is too low than total airdrop.");
        require(recipients.length == amount.length, "The length of recipient array is not equal to the length of native token airdrop array.");

        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "Cannot transfer the airdrop native token to zero address.");
            payable(recipients[i]).transfer(amount[i]);
            emit EtherTransfer(recipients[i], amount[i]);
        }
        return true;
    }

    function dropSimilarSpecificEther(
        address[] memory recipients,
        uint256 amount
    ) public payable returns (bool) {
        uint256 total = amount * recipients.length;
        require(total <= msg.value, "Amount sent to be dropped is too low than total airdrop.");
        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "Cannot transfer the airdrop native token to zero address.");
            payable(recipients[i]).transfer(amount);
            emit EtherTransfer(recipients[i], amount);
        }
        return true;
    }

    /* Check */

    function isBebuzee() external pure returns (bool) {
        return ISBEBUZEE;
    }

    function circulatingSupply() external view returns (uint256) {
        return totalSupply() - balanceOf(DEAD) - balanceOf(ZERO);
    }

    /* Update */

    function updateRouter(address newRouter) external authorized {
        require(address(router) != newRouter, "Update Router: This is the current router address.");
        address oldRouter = address(router);
        router = IRouter(newRouter);
        emit UpdateRouter(oldRouter, newRouter, block.timestamp);
        pair = IFactory(router.factory()).createPair(address(this), router.WETH());
    }

    function updateMinSwap(uint256 newMinSwap) external authorized {
        require(minSwap != newMinSwap, "Update Min Swap: This is the current value of min swap.");
        uint256 oldMinSwap = minSwap;
        minSwap = newMinSwap;
        emit UpdateMinSwap(oldMinSwap, newMinSwap, block.timestamp);
    }

    function updateBuyFeeRatios(uint256 newOperationFee, uint256 newLiquidityFee, uint256 newMarketingFee, uint256 newTeamFee) external authorized {
        require(!isFeeLocked, "Update Buy Fee Ratio: All buy fee ratios were locked and cannot be updated.");
        require(newOperationFee + newLiquidityFee + newMarketingFee + newTeamFee == 10_000, "Update Buy Fee Ratio: Total fee ratios should be 100%.");
        buyFeeRatios = Ratios({ operation: newOperationFee, liquidity: newLiquidityFee, marketing: newMarketingFee, team: newTeamFee });
    }

    function updateSellFeeRatios(uint256 newOperationFee, uint256 newLiquidityFee, uint256 newMarketingFee, uint256 newTeamFee) external authorized {
        require(!isFeeLocked, "Update Sell Fee Ratio: All Sell fee ratios were locked and cannot be updated.");
        require(newOperationFee + newLiquidityFee + newMarketingFee + newTeamFee == 10_000, "Update Sell Fee Ratio: Total fee ratios should be 100%.");
        sellFeeRatios = Ratios({ operation: newOperationFee, liquidity: newLiquidityFee, marketing: newMarketingFee, team: newTeamFee });
    }

    function updateTransferFeeRatios(uint256 newOperationFee, uint256 newLiquidityFee, uint256 newMarketingFee, uint256 newTeamFee) external authorized {
        require(!isFeeLocked, "Update Transfer Fee Ratio: All Transfer fee ratios were locked and cannot be updated.");
        require(newOperationFee + newLiquidityFee + newMarketingFee + newTeamFee == 10_000, "Update Transfer Fee Ratio: Total fee ratios should be 100%.");
        transferFeeRatios = Ratios({ operation: newOperationFee, liquidity: newLiquidityFee, marketing: newMarketingFee, team: newTeamFee });
    }

    function updateFeeActive(bool newStatus) external authorized {
        require(isFeeActive != newStatus, "Update Fee Active: This is the current state for the fee.");
        bool oldStatus = isFeeActive;
        isFeeActive = newStatus;
        emit UpdateFeeActive(oldStatus, newStatus, block.timestamp);
    }

    function updateSwapEnabled(bool newStatus) external authorized {
        require(isSwapEnabled != newStatus, "Update Swap Enabled: This is the current state for the swap.");
        bool oldStatus = isSwapEnabled;
        isSwapEnabled = newStatus;
        emit UpdateSwapEnabled(oldStatus, newStatus, block.timestamp);
    }

    function updateOperationReceiver(address newOperationReceiver) external authorized {
        require(operationReceiver != newOperationReceiver, "Update Operation Receiver: This is the current operation receiver address.");
        address oldOperationReceiver = operationReceiver;
        operationReceiver = newOperationReceiver;
        emit UpdateOperationReceiver(oldOperationReceiver, newOperationReceiver, block.timestamp);
    }

    function updateLiquidityReceiver(address newLiquidityReceiver) external authorized {
        require(liquidityReceiver != newLiquidityReceiver, "Update Liquidity Receiver: This is the current liquidity receiver address.");
        address oldLiquidityReceiver = liquidityReceiver;
        liquidityReceiver = newLiquidityReceiver;
        emit UpdateLiquidityReceiver(oldLiquidityReceiver, newLiquidityReceiver, block.timestamp);
    }

    function updateMarketingReceiver(address newMarketingReceiver) external authorized {
        require(marketingReceiver != newMarketingReceiver, "Update Marketing Receiver: This is the current marketing receiver address.");
        address oldMarketingReceiver = marketingReceiver;
        marketingReceiver = newMarketingReceiver;
        emit UpdateMarketingReceiver(oldMarketingReceiver, newMarketingReceiver, block.timestamp);
    }

    function updateteamReceiver(address newTeamReceiver) external authorized {
        require(teamReceiver != newTeamReceiver, "Update Team Receiver: This is the current team receiver address.");
        address oldTeamReceiver = teamReceiver;
        teamReceiver = newTeamReceiver;
        emit UpdateTeamReceiver(oldTeamReceiver, newTeamReceiver, block.timestamp);
    }

    function setExcludeFromFees(address user, bool status) external authorized {
        require(isExcludeFromFees[user] != status, "Set Exclude From Fees: This is the current state for this address.");
        isExcludeFromFees[user] = status;
    }

    /* Fee */

    function takeBuyFee(address from, uint256 amount) internal swapping returns (uint256) {
        uint256 feeAmount = amount * BUYFEETOTAL / FEEDENOMINATOR;
        uint256 newAmount = amount - feeAmount;
        tallyBuyFee(from, feeAmount);
        return newAmount;
    }

    function takeSellFee(address from, uint256 amount) internal swapping returns (uint256) {
        uint256 feeAmount = amount * SELLFEETOTAL / FEEDENOMINATOR;
        uint256 newAmount = amount - feeAmount;
        tallySellFee(from, feeAmount);
        return newAmount;
    }

    function takeTransferFee(address from, uint256 amount) internal swapping returns (uint256) {
        uint256 feeAmount = amount * TRANSFERFEETOTAL / FEEDENOMINATOR;
        uint256 newAmount = amount - feeAmount;
        tallyTransferFee(from, feeAmount);
        return newAmount;
    }

    function tallyBuyFee(address from, uint256 fee) internal swapping {
        uint256 collectOperation = fee * buyFeeRatios.operation / FEEDENOMINATOR;
        uint256 collectLiquidity = fee * buyFeeRatios.liquidity / FEEDENOMINATOR;
        uint256 collectMarketing = fee * buyFeeRatios.marketing / FEEDENOMINATOR;
        uint256 collectTeam = fee - collectOperation - collectLiquidity - collectMarketing;
        tallyCollection(collectOperation, collectLiquidity, collectMarketing, collectTeam, fee);
        
        _balances[from] -= fee;
        _balances[address(this)] += fee;
    }

    function tallySellFee(address from, uint256 fee) internal swapping {
        uint256 collectOperation = fee * sellFeeRatios.operation / FEEDENOMINATOR;
        uint256 collectLiquidity = fee * sellFeeRatios.liquidity / FEEDENOMINATOR;
        uint256 collectMarketing = fee * sellFeeRatios.marketing / FEEDENOMINATOR;
        uint256 collectTeam = fee - collectOperation - collectLiquidity - collectMarketing;
        tallyCollection(collectOperation, collectLiquidity, collectMarketing, collectTeam, fee);
        
        _balances[from] -= fee;
        _balances[address(this)] += fee;
    }

    function tallyTransferFee(address from, uint256 fee) internal swapping {
        uint256 collectOperation = fee * transferFeeRatios.operation / FEEDENOMINATOR;
        uint256 collectLiquidity = fee * transferFeeRatios.liquidity / FEEDENOMINATOR;
        uint256 collectMarketing = fee * transferFeeRatios.marketing / FEEDENOMINATOR;
        uint256 collectTeam = fee - collectOperation - collectLiquidity - collectMarketing;
        tallyCollection(collectOperation, collectLiquidity, collectMarketing, collectTeam, fee);
        
        _balances[from] -= fee;
        _balances[address(this)] += fee;
    }

    function tallyCollection(uint256 collectOperation, uint256 collectLiquidity, uint256 collectMarketing, uint256 collectTeam, uint256 amount) internal swapping {
        operationFeeCollected += collectOperation;
        liquidityFeeCollected += collectLiquidity;
        marketingFeeCollected += collectMarketing;
        teamFeeCollected += collectTeam;
        totalFeeCollected += amount;
    }

    function autoRedeem(uint256 amountToRedeem) public swapping returns (uint256) {  
        require(msg.sender != liquidityReceiver, "Auto Redeem: Cannot use liquidity receiver to trigger this.");
        uint256 operationToRedeem = operationFeeCollected - operationFeeRedeemed;
        uint256 liquidityToRedeem = liquidityFeeCollected - liquidityFeeRedeemed;
        uint256 marketingToRedeem = marketingFeeCollected - marketingFeeRedeemed;
        uint256 totalToRedeem = totalFeeCollected - totalFeeRedeemed;

        uint256 initialBalance = address(this).balance;
        uint256 operationFeeDistribution = amountToRedeem * operationToRedeem / totalToRedeem;
        uint256 liquidityFeeDistribution = amountToRedeem * liquidityToRedeem / totalToRedeem;
        uint256 marketingFeeDistribution = amountToRedeem * marketingToRedeem / totalToRedeem;
        uint256 teamFeeDistribution = amountToRedeem - operationFeeDistribution - liquidityFeeDistribution - marketingFeeDistribution;
        uint256 firstLiquidityHalf = liquidityFeeDistribution / 2;
        uint256 secondLiquidityHalf = liquidityFeeDistribution - firstLiquidityHalf;
        uint256 redeemAmount = amountToRedeem;

        operationFeeRedeemed += operationFeeDistribution;
        liquidityFeeRedeemed += liquidityFeeDistribution;
        marketingFeeRedeemed += marketingFeeDistribution;
        teamFeeRedeemed += teamFeeDistribution;
        totalFeeRedeemed += amountToRedeem;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), redeemAmount);
    
        emit AutoRedeem(operationFeeDistribution, liquidityFeeDistribution, marketingFeeDistribution, teamFeeDistribution, redeemAmount, block.timestamp);

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            operationFeeDistribution,
            0,
            path,
            operationReceiver,
            block.timestamp
        );

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            firstLiquidityHalf,
            0,
            path,
            address(this),
            block.timestamp
        );
        
        (, , uint256 liquidity) = router.addLiquidityETH{
            value: address(this).balance - initialBalance
        }(
            address(this),
            secondLiquidityHalf,
            0,
            0,
            liquidityReceiver,
            block.timestamp + 1_200
        );

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            marketingFeeDistribution,
            0,
            path,
            marketingReceiver,
            block.timestamp
        );

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            teamFeeDistribution,
            0,
            path,
            teamReceiver,
            block.timestamp
        );
        
        return liquidity;
    }

    /* Buyback */

    function triggerZeusBuyback(uint256 amount) external authorized {
        buyTokens(amount, DEAD);
    }

    function buyTokens(uint256 amount, address to) internal swapping {
        require(msg.sender != DEAD, "Buy Tokens: Dead address cannot call this function.");
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(this);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: amount
        }(0, path, to, block.timestamp);
    }

    /* ERC20 Standard */

    function name() external view virtual override returns (string memory) {
        return NAME;
    }
    
    function symbol() external view virtual override returns (string memory) {
        return SYMBOL;
    }
    
    function decimals() external view virtual override returns (uint8) {
        return DECIMALS;
    }
    
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    
    function transfer(address to, uint256 amount) external virtual override returns (bool) {
        address provider = msg.sender;
        return _transfer(provider, to, amount);
    }
    
    function allowance(address provider, address spender) public view virtual override returns (uint256) {
        return _allowances[provider][spender];
    }
    
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address provider = msg.sender;
        _approve(provider, spender, amount);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 amount) external virtual override returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        return _transfer(from, to, amount);
    }
    
    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        address provider = msg.sender;
        _approve(provider, spender, allowance(provider, spender) + addedValue);
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        address provider = msg.sender;
        uint256 currentAllowance = allowance(provider, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(provider, spender, currentAllowance - subtractedValue);
        }

        return true;
    }
    
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        unchecked {
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);
    }

    function _approve(address provider, address spender, uint256 amount) internal virtual {
        require(provider != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[provider][spender] = amount;
        emit Approval(provider, spender, amount);
    }
    
    function _spendAllowance(address provider, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(provider, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(provider, spender, currentAllowance - amount);
            }
        }
    }

    /* Additional */

    function _basicTransfer(address from, address to, uint256 amount ) internal returns (bool) {
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);
        return true;
    }
    
    /* Overrides */
 
    function _transfer(address from, address to, uint256 amount) internal virtual returns (bool) {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (inSwap || isExcludeFromFees[from]) {
            return _basicTransfer(from, to, amount);
        }

        if (from != pair && isSwapEnabled && totalFeeCollected - totalFeeRedeemed >= minSwap) {
            autoRedeem(minSwap);
        }

        uint256 newAmount = amount;

        if (isFeeActive && !isExcludeFromFees[from]) {
            newAmount = _beforeTokenTransfer(from, to, amount);
        }

        require(_balances[from] >= newAmount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = _balances[from] - newAmount;
            _balances[to] += newAmount;
        }

        emit Transfer(from, to, newAmount);

        return true;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal swapping virtual returns (uint256) {
        if (from == pair && BUYFEETOTAL > 0) {
            return takeBuyFee(from, amount);
        }
        if (to == pair && SELLFEETOTAL > 0) {
            return takeSellFee(from, amount);
        }
        if (from != pair && to != pair && TRANSFERFEETOTAL > 0) {
            return takeTransferFee(from, amount);
        }
        return amount;
    }
}