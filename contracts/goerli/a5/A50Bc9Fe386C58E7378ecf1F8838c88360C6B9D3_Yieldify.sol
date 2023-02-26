/**
 *Submitted for verification at Etherscan.io on 2023-02-26
*/

// File: Libraries.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IPancakeFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IPancakeRouter {
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

    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getamountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getamountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getamountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getamountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
       function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);
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

abstract contract Ownable {
    address internal _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address currentAccount = msg.sender;
        _owner = currentAccount;
        emit OwnershipTransferred(address(0), currentAccount);
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
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


pragma solidity ^0.8.4;
contract Treasury{
    address token;
    IPancakeRouter router;
    IBEP20 Stablecoin;
    constructor(address USDToken_,address router_){
        router=IPancakeRouter(router_);
        Stablecoin=IBEP20(USDToken_);
        token=msg.sender;
    }




    function transferStablecoin(address to,uint amount) external{
        require(msg.sender==token);
        Stablecoin.transfer(to,amount);
    }
    function swapForToken(address to, uint amount) external{
        require(msg.sender==token);
        Stablecoin.approve(address(router),amount);
        address[] memory path = new address[](2);
        path[1] = token;
        path[0] = address(Stablecoin);

        router.swapExactTokensForTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
        IBEP20(token).transfer(to,IBEP20(token).balanceOf(address(this)));
    }

        




}

contract Yieldify is IBEP20, Ownable {


    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => bool) public excluded;
    mapping(address => bool) public excludedFromStaking;
    mapping(address => bool) public automatedMarketMakers;

    //Token Info

    string public constant name = "Yieldify";
    string public constant symbol = "SYP";
    uint8 public constant decimals = 9;
    uint256 public constant InitialSupply=10**9 * 10**decimals;
    uint256 public totalSupply=0; //Total supply gets updated with each transfer


    uint256 private constant DistributionMultiplier = 2**64;
    uint256 public profitPerShare;
    uint256 public totalShares;
    uint256 public totalPayouts;
    mapping(address => uint256) private alreadyPaidShares;
    mapping(address => uint256) private toBePaid;
    mapping(address => address) public referrer;
    mapping(address => uint256) public totalPayout;
    mapping(address=> bool) public authorized;
    Treasury public treasury;
    uint256 public taxes = 60;
    uint accumulatedYieldToken;
    uint LastYieldTimestamp;
    bool public swapAndLiquifyDisabled;

    uint256 public LaunchTimestamp = type(uint256).max;

    address private _pancakePairAddress;
    IPancakeRouter private _pancakeRouter;
 
    //MainNet
    address private constant PancakeRouter =
        //0x10ED43C718714eb63d5aA57B78B54704E256024E;//Mainnet
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;//Testnet
    IBEP20 private Stablecoin=
     //IBEP20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);//Mainnet
     IBEP20(0x07865c6E87B9F70255377e024ace6630C1Eaa37F);//Testnet
    address public FeeDistributor;



    event OnAddAMM(address AMM, bool Add);
    event OnChangeFeeDistributor(address newWallet);
    event OnSwitchSwapAndLiquify(bool Disabled);
    event OnExcludeFromStaking(address addr, bool exclude);
    event OnExclude(address addr, bool exclude);
    event OnSetLaunchTimestamp(uint256 timestamp);
    event OnAuthorize(address account, bool flag);
    event OnAddReferer(address account, address referrer_);
    event OnClaim(address account, uint amount);

    bool _lock;
    modifier Lock() {
        require(!_lock);
        _lock = true;
        _;
        _lock = false;
    }
    bool _inSwap;
    modifier lockTheSwap() {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    constructor() {
        treasury=new Treasury(address(Stablecoin),PancakeRouter);
        _pancakeRouter = IPancakeRouter(PancakeRouter);
        _pancakePairAddress = IPancakeFactory(_pancakeRouter.factory())
            .createPair(address(this), address(Stablecoin));
        excluded[address(0xdead)] = true;
        automatedMarketMakers[_pancakePairAddress] = true;

        excludedFromStaking[_pancakePairAddress] = true;
        excludedFromStaking[address(this)] = true;
        excludedFromStaking[address(0xdead)] = true;

        _addToken(msg.sender, InitialSupply);
        emit Transfer(address(0), msg.sender, totalSupply);

        FeeDistributor = msg.sender;
        excluded[FeeDistributor] = true;
        excluded[msg.sender] = true;
        excluded[address(treasury)]=true;
        excluded[address(this)] = true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(sender != address(0), "from zero");
        require(recipient != address(0), "to zero");

        if (_inSwap || excluded[sender] || excluded[recipient]) {
            _feelessTransfer(sender, recipient, amount);
            return;
        }

        require(block.timestamp >= LaunchTimestamp, "trading not yet enabled");
        _regularTransfer(sender, recipient, amount);
    }

    function _regularTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(balanceOf[sender] >= amount, "exceeds balance");
        bool isSwap = automatedMarketMakers[sender]||automatedMarketMakers[recipient];
        generateYield();
        if (
            (sender != _pancakePairAddress) &&
            (!swapAndLiquifyDisabled)
        ) {
            _swapContractToken();
        }
        if(isSwap)
            _transferTaxed(sender, recipient, amount);
        else{
            _feelessTransfer(sender,recipient,amount);
        }
    }

    function _transferTaxed(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        uint256 totalTaxedToken = (amount * taxes) / 1000;
        uint256 taxedAmount = amount - totalTaxedToken;

        _removeToken(sender, amount);
        _addToken(address(this), totalTaxedToken);
        emit Transfer(sender, address(this),totalTaxedToken);
        _addToken(recipient, taxedAmount);
        emit Transfer(sender, recipient, taxedAmount);
    }

    function _feelessTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(balanceOf[sender] >= amount, ">balance");
        _removeToken(sender, amount);
        _addToken(recipient, amount);

        emit Transfer(sender, recipient, amount);
    }
 
    function _handleDividents(address currentAccount) private returns(uint claimDividents){
        uint256 referrerDividents;
        (claimDividents, referrerDividents)=getDividents(currentAccount);

        require(claimDividents > 0, "Nothing to claim");
        toBePaid[currentAccount] = 0;

        address currentReferrer=
            referrer[currentAccount]==address(0)
                ?FeeDistributor
                :referrer[currentAccount];
        toBePaid[currentReferrer]+=referrerDividents;

        alreadyPaidShares[currentAccount] = profitPerShare * getShares(currentAccount);
        totalPayout[currentAccount]+=claimDividents;
        totalPayouts+=claimDividents;
    }


    function claimFor(address account) external onlyOwner Lock{
        _claim(account);
    }

    function claim() external Lock {
        _claim(msg.sender);
    }
    function _claim(address account) private{
        uint dividents=_handleDividents(account);
        treasury.transferStablecoin(account,dividents);
        emit OnClaim(account,dividents);
    }
    event OnSetTaxes(uint newTaxes);
    function setTaxes(uint newTaxes) external onlyOwner{
        require (newTaxes <= 100,"Taxes can be max 10%");
        taxes=newTaxes;
        emit OnSetTaxes(taxes);

    }
    function authorize(address account, bool flag) external onlyOwner{
        authorized[account]=flag;
        emit OnAuthorize(account,flag);
    }

    function addReferer(address account, address referrer_) external{
        address msgSender=msg.sender;
        require(msgSender==account||authorized[msgSender]);
        require(account!=referrer_,"can't refer yourself");
        referrer[account]=referrer_;
        emit OnAddReferer(account,referrer_);
    } 
    function compound() external Lock{
        address currentAccount=msg.sender;
        uint dividents=_handleDividents(currentAccount);
        uint tokenBefore=balanceOf[currentAccount];
        treasury.swapForToken(currentAccount,dividents);
        uint newToken=balanceOf[currentAccount]-tokenBefore;
        uint bonusAmount=newToken*2/100;
        _addToken(address(this),bonusAmount);
        emit Transfer(address(0),currentAccount,bonusAmount);
    }




    function _addToken(address addr, uint256 amount) private {
        totalSupply+=amount;
        uint256 newAmount = balanceOf[addr] + amount;
        if (excludedFromStaking[addr]) {
            balanceOf[addr] = newAmount;
            return;
        }
        totalShares += amount;
        uint256 payment = _newDividentsOf(addr);
        alreadyPaidShares[addr] = profitPerShare * newAmount;
        toBePaid[addr] += payment;
        balanceOf[addr] = newAmount;
    }

    function _removeToken(address addr, uint256 amount) private {
        totalSupply-=amount;
        uint256 newAmount = balanceOf[addr] - amount;
        if (excludedFromStaking[addr]) {
            balanceOf[addr] = newAmount;
            return;
        }

        uint256 payment = _newDividentsOf(addr);
        balanceOf[addr] = newAmount;
        alreadyPaidShares[addr] = profitPerShare * getShares(addr);
        toBePaid[addr] += payment;
        totalShares -= amount;
    }

    function _newDividentsOf(address staker) private view returns (uint256) {
        uint256 fullPayout = profitPerShare * getShares(staker);
        if (fullPayout <= alreadyPaidShares[staker]) return 0;
        return
            (fullPayout - alreadyPaidShares[staker]) / DistributionMultiplier;
    }

    function _distributeStake(uint256 AmountWei) private {
        if (AmountWei == 0) return;
        if (totalShares == 0) {
            treasury.transferStablecoin(FeeDistributor,AmountWei);
        } else {
            profitPerShare += ((AmountWei * DistributionMultiplier) /
                totalShares);
        }
    }
    event OnAddFunds(uint amount);
    event OnAddFundsTo(address account, uint amount);
    function AddFunds(uint amount) external  Lock {
        Stablecoin.transferFrom(msg.sender,address(treasury),amount);
        _distributeStake(amount);
        emit OnAddFunds(amount);
    }

    function AddFundsTo(address account, uint amount) external Lock {
        Stablecoin.transferFrom(msg.sender,address(treasury),amount);
        toBePaid[account] += amount;
        emit OnAddFundsTo(account, amount);
    }

    function generateYield() public{
        uint timestamp=block.timestamp;
        uint timePassed=timestamp-LastYieldTimestamp;
        if(timePassed==0) return;
        LastYieldTimestamp=timestamp;
        uint yield;
        uint timeSinceLaunch=timestamp-LaunchTimestamp;
        if(timeSinceLaunch<365 days)
            yield=333;
        else if(timeSinceLaunch<730)
            yield=222;
        else if(timeSinceLaunch<1095)
            yield=111;
        else if(timeSinceLaunch<1460)
            yield=77;
        else yield=55;

        uint yieldToken=totalShares*yield*timePassed/(365 days*100);
        _addToken(address(this),yieldToken);
        accumulatedYieldToken+=yieldToken;
    }


    function _swapContractToken()
        private
        lockTheSwap
    {
        uint256 contractBalance = balanceOf[address(this)];
        if(contractBalance<(balanceOf[_pancakePairAddress]/500)) return;
        uint256 tokenForDevelopment=contractBalance-accumulatedYieldToken;
        accumulatedYieldToken=0;

        uint USDTokenBefore=Stablecoin.balanceOf(address(treasury));
        _swapTokenForStablecoin(contractBalance);
        uint newUSDToken=Stablecoin.balanceOf(address(treasury))-USDTokenBefore;
        uint DevUSDToken=newUSDToken*tokenForDevelopment/contractBalance;
        _distributeStake(newUSDToken-DevUSDToken);
        treasury.transferStablecoin(FeeDistributor,DevUSDToken);
    }

    function _swapTokenForStablecoin(uint256 amount) private {
        _approve(address(this), address(_pancakeRouter), amount);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = address(Stablecoin);

        _pancakeRouter.swapExactTokensForTokens(
            amount,
            0,
            path,
            address(treasury),
            block.timestamp
        );
    }




    function getShares(address addr) public view returns (uint256) {
        if (excludedFromStaking[addr]) return 0;
        return balanceOf[addr];
    }


    function getDividents(address addr) public view returns(uint256 claimableDividents, uint256 referDividents){
        uint totalDividents=_newDividentsOf(addr) + toBePaid[addr];
        if(referrer[addr]==address(0))
            claimableDividents= totalDividents*87/100;
        claimableDividents= totalDividents*9/10;
        referDividents=totalDividents-claimableDividents;
    }



    function AddAMM(address AMMPairAddress, bool Add)
        external
        onlyOwner
    {
        require(AMMPairAddress != _pancakePairAddress, "can't change Pancake");
        if (Add) {
            if (!excludedFromStaking[AMMPairAddress])
                SetStakingExcluded(AMMPairAddress, true);
            automatedMarketMakers[AMMPairAddress] = true;
        } else {
            automatedMarketMakers[AMMPairAddress] = false;
        }
        emit OnAddAMM(AMMPairAddress, Add);
    }

    function ChangeFeeDistributor(address newDistributor)
        external
        onlyOwner
    {
        FeeDistributor = newDistributor;
        emit OnChangeFeeDistributor(newDistributor);
    }

    function SwitchSwapAndLiquify(bool disabled) external onlyOwner {
        swapAndLiquifyDisabled = disabled;
        emit OnSwitchSwapAndLiquify(disabled);
    }


    function TriggerLiquify()
        external
        onlyOwner
    {
        _swapContractToken( );
    }

    function SetStakingExcluded(address addr, bool exclude) public onlyOwner {
        uint256 shares;
        if (exclude) {
            require(!excludedFromStaking[addr]);
            uint256 newDividents = _newDividentsOf(addr);
            shares = getShares(addr);
            excludedFromStaking[addr] = true;
            totalShares -= shares;
            alreadyPaidShares[addr] = shares * profitPerShare;
            toBePaid[addr] += newDividents;
        } else _includeToStaking(addr);
        emit OnExcludeFromStaking(addr, exclude);
    }

    function IncludeMeToStaking() external {
        _includeToStaking(msg.sender);
    }

    function _includeToStaking(address addr) private {
        require(excludedFromStaking[addr]);
        excludedFromStaking[addr] = false;
        uint256 shares = getShares(addr);
        totalShares += shares;
        alreadyPaidShares[addr] = shares * profitPerShare;

    }

    function SetExcludedStatus(address account, bool flag) external onlyOwner {
        require(
            account != address(this) && account!=address(treasury)&& account != address(0xdead),
            "can't Include"
        );
        excluded[account] = flag;
        emit OnExclude(account, flag);
    }



    function Launch() external {
        SetupLaunchTimestamp(block.timestamp);
    }

    function SetupLaunchTimestamp(uint256 timestamp) public onlyOwner {
        require(block.timestamp < LaunchTimestamp);

        LaunchTimestamp = timestamp;
        LastYieldTimestamp=timestamp;
        emit OnSetLaunchTimestamp(timestamp);
    }

    function WithdrawStrandedToken(address strandedToken) external onlyOwner {
        require(
            (strandedToken != _pancakePairAddress) &&
                strandedToken != address(this)
        );
        IBEP20 token = IBEP20(strandedToken);
        token.transfer(FeeDistributor, token.balanceOf(address(this)));
    }
    uint TreasuryLockTime= 26 weeks;
    function claimTreasury(uint amount) external onlyOwner{
        require(block.timestamp>LaunchTimestamp+TreasuryLockTime,"Locked");
        treasury.transferStablecoin(msg.sender,amount);
    }
    function lockTreasury(uint totalTime) external onlyOwner{
        require(totalTime>TreasuryLockTime);
        TreasuryLockTime=totalTime;
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount)
        external
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0));
        require(spender != address(0));

        allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = allowance[sender][msg.sender];
        require(currentAllowance >= amount);

        _approve(sender, msg.sender, currentAllowance - amount);
        return true;
    }

    // IBEP20 - Helpers
    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            allowance[msg.sender][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool)
    {
        uint256 currentAllowance = allowance[msg.sender][spender];
        require(currentAllowance >= subtractedValue);

        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }
}