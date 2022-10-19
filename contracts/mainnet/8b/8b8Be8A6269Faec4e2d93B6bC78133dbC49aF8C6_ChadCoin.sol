/**
 *Submitted for verification at Etherscan.io on 2022-10-19
*/

/*
$CHAD is here to give back power to the people.
A movement of enthusiast who share the same values and follow the same dreams.

Important links 

Website: https://www.chadcoin.xyz

Telegram: https://t.me/chadcoinportal

Medium: https://medium.com/@Chadcoin

Twitter: twitter.com/chadcoinxyz

*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

library Address {
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IDEXPair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IDEXRouter {
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

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

contract DividendDistributor {

    address _mainToken;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }
    IERC20 TOKEN;
    address ETH;
    IDEXRouter router;

    address[] public shareholders;
    mapping (address => uint256) public shareholderIndexes;
    mapping (address => uint256) public shareholderClaims;

    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;

    uint256 public minPeriod = 1 hours;
    uint256 public minDistribution = 1000000 * (10 ** 9);
    uint256 public gas = 500000;
    
    uint256 currentIndex;

    bool initialized;
    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    modifier onlyToken() {
        require(msg.sender == _mainToken || _mainToken == address(0)); _;
    }

    constructor (address routerAddress, address _reflectionToken) {
        router = IDEXRouter(routerAddress);
        TOKEN = IERC20(_reflectionToken);
        ETH = router.WETH();
        _mainToken = msg.sender;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution, uint256 _gas) external onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
        gas = _gas;
    }

    function setShare(address shareholder, uint256 amount) external onlyToken {
        if(amount > 0 && shares[shareholder].amount == 0){
            addShareholder(shareholder);
        }else if(amount == 0 && shares[shareholder].amount > 0){
            removeShareholder(shareholder);
        }
        
        if(shares[shareholder].amount > 0){
            distributeDividend(shareholder);
        }
        
        totalShares = (totalShares - shares[shareholder].amount) + amount;
        shares[shareholder].amount = amount;
        
        shares[shareholder].totalExcluded = getCumulativeDividends(amount);
    }

    function deposit() external payable {
        bool native = address(TOKEN) == address(0);
        uint256 balanceBefore = native ? address(this).balance : TOKEN.balanceOf(address(this));

        if (!native) {
            address[] memory path = new address[](2);
            path[0] = ETH;
            path[1] = address(TOKEN);

            router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
                0,
                path,
                address(this),
                block.timestamp
            );
        }

        uint256 amount = native ? msg.value : TOKEN.balanceOf(address(this)) - balanceBefore;

        totalDividends = totalDividends + amount;
        dividendsPerShare = dividendsPerShare + (dividendsPerShareAccuracyFactor * amount) / totalShares;
    }

    function process() public onlyToken {
        uint256 shareholderCount = shareholders.length;

        if(shareholderCount == 0) { return; }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;

        while(gasUsed < gas && iterations < shareholderCount) {
            if(currentIndex >= shareholderCount){
                currentIndex = 0;
            }
            
            if(shouldDistribute(shareholders[currentIndex])){
                distributeDividend(shareholders[currentIndex]);
            }

            gasUsed = gasUsed + (gasLeft - gasleft());
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }

    function shouldDistribute(address shareholder) internal view returns (bool) {
        return shareholderClaims[shareholder] + minPeriod < block.timestamp
                && getUnpaidEarnings(shareholder) > minDistribution;
    }
    
    function getClaimTime(address shareholder) external view returns (uint256) {
        if (shareholderClaims[shareholder] + minPeriod <= block.timestamp)
            return 0;
        else
            return (shareholderClaims[shareholder] + minPeriod) - block.timestamp;
    }

    function distributeDividend(address shareholder) internal {
        if(shares[shareholder].amount == 0){ return; }
        
        uint256 unpaidEarnings = getUnpaidEarnings(shareholder);
        if(unpaidEarnings > 0){
            uint256 previousExcluded = shares[shareholder].totalExcluded;

            totalDistributed += unpaidEarnings;
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised += unpaidEarnings;
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);

            if(address(TOKEN) == address(0)) {
                (bool sent, ) = shareholder.call{value: unpaidEarnings}("");
                if (!sent) {
                    totalDistributed -= unpaidEarnings;
                    shares[shareholder].totalRealised -= unpaidEarnings;
                    shares[shareholder].totalExcluded = previousExcluded;
                }
            } else {
                TOKEN.transfer(shareholder, unpaidEarnings);
            }
        }
    }

    function claimDividend(address shareholder) external onlyToken {
        distributeDividend(shareholder);
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends - shareholderTotalExcluded;
    }
    
    function getPaidDividends(address shareholder) external view returns (uint256) {
        return shares[shareholder].totalRealised;
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        if(share == 0){ return 0; }
        return (share * dividendsPerShare) / dividendsPerShareAccuracyFactor;
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function countShareholders() external view returns (uint256) {
        return shareholders.length;
    }
    
    function getTotalRewarded() external view returns (uint256) {
        return totalDistributed;
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
}

interface IAntiSnipe {
  function setTokenOwner(address owner, address pair) external;

  function onPreTransferCheck(
    address sender,
    address from,
    address to,
    uint256 amount
  ) external returns (bool checked);
}

contract ChadCoin is IERC20, Ownable {
    using Address for address;
    
    address constant DEAD = 0x000000000000000000000000000000000000dEaD;

    string constant _name = "ChadCoin";
    string constant _symbol = "CHAD";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 1_000_000_000 * (10 ** _decimals);

    uint256 _maxTxAmount = 10; //1%
    uint256 _maxWalletSize = 20; //2%

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => uint256) lastSell;
    mapping (address => uint256) lastSellAmount;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isDividendExempt;
    mapping (address => bool) isTxLimitExempt;

    uint256 marketingFee = 20;
    uint256 marketingSellFee = 30;
    uint256 communityAwardFee = 0;
    uint256 communityAwardSellFee = 10;
    uint256 USDCRewardFee = 20;
    uint256 USDCRewardSellFee = 20;
    uint256 liquidityFee = 10;
    uint256 liquiditySellFee = 10;
    uint256 totalBuyFee = marketingFee + USDCRewardFee + liquidityFee + communityAwardFee;
    uint256 totalSellFee = marketingSellFee + USDCRewardSellFee + liquiditySellFee + communityAwardSellFee;
    uint256 feeDenominator = 1000;

    uint256 antiDumpTax = 200;
    uint256 antiDumpPeriod = 30 minutes;
    uint256 antiDumpThreshold = 21;
    bool antiDumpReserve0 = true;

    address public constant liquidityReceiver = DEAD;
    address payable public immutable marketingReceiver;
    address payable public immutable communityReceiver;

    uint256 targetLiquidity = 10;
    uint256 targetLiquidityDenominator = 100;

    DividendDistributor public rewards;
    bool public autoProcess = false;

    IDEXRouter public immutable router;
    
    address constant routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    mapping (address => bool) liquidityPools;
    mapping (address => bool) liquidityProviders;

    address public pair;

    uint256 public launchedAt;
    uint256 public launchedTime;
    uint256 public deadBlocks;
    bool startBullRun = false;
 
    IAntiSnipe public antisnipe;
    bool public protectionEnabled = true;
    bool public protectionDisabled = false;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 400; //0.25%
    uint256 public swapMinimum = _totalSupply / 10000; //0.01%
    uint256 public maxSwapPercent = 75;

    uint256 public unlocksAt;
    address public locker;

    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor (address _liquidityProvider, address _marketingWallet, address _communityWallet) {
        marketingReceiver = payable(_marketingWallet);
        communityReceiver = payable(_communityWallet);

        router = IDEXRouter(routerAddress);
        _allowances[_liquidityProvider][routerAddress] = type(uint256).max;
        _allowances[address(this)][routerAddress] = type(uint256).max;
        
        isFeeExempt[_liquidityProvider] = true;
        liquidityProviders[_liquidityProvider] = true;

        isDividendExempt[_liquidityProvider] = true;
        isDividendExempt[routerAddress] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;
        isDividendExempt[address(0)] = true;

        isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[_liquidityProvider] = true;
        isTxLimitExempt[routerAddress] = true;

        rewards = new DividendDistributor(routerAddress, 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        isDividendExempt[address(rewards)] = true;

        _balances[_liquidityProvider] = _totalSupply;
        emit Transfer(address(0), _liquidityProvider, _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure returns (uint8) { return _decimals; }
    function symbol() external pure returns (string memory) { return _symbol; }
    function name() external pure returns (string memory) { return _name; }
    function getOwner() external view returns (address) { return owner(); }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below address(0)");
        unchecked {
            _approve(msg.sender, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the address(0) address");
        require(spender != address(0), "ERC20: approve to the address(0) address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(_balances[sender] >= amount, "ERC20: transfer amount exceeds balance");
        require(amount > 0, "No tokens transferred");
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        if(inSwap){ return _basicTransfer(sender, recipient, amount); }

        checkTxLimit(sender, amount);
        
        if (!liquidityPools[recipient] && recipient != DEAD) {
            if (!isTxLimitExempt[recipient]) checkWalletLimit(recipient, amount);
        }

        if(!launched()){ require(liquidityProviders[sender] || liquidityProviders[recipient], "Contract not launched yet."); }

        if(!liquidityPools[sender] && shouldTakeFee(sender) && _balances[sender] - amount == 0) {
            amount -= 1;
        }

        _balances[sender] -= amount;

        uint256 amountReceived = shouldTakeFee(sender) && shouldTakeFee(recipient) ? takeFee(sender, recipient, amount) : amount;
        
        if(shouldSwapBack(sender, recipient)){ if (amount > 0) swapBack(amount); }
        
        if(recipient != DEAD)
            _balances[recipient] += amountReceived;
        else
            _totalSupply -= amountReceived;
            
        if (launched() && protectionEnabled && shouldTakeFee(sender))
            antisnipe.onPreTransferCheck(msg.sender, sender, recipient, amount);

        if(!isDividendExempt[sender]){ try rewards.setShare(sender, _balances[sender]) {} catch {} }
        if(!isDividendExempt[recipient]){ try rewards.setShare(recipient, _balances[recipient]) {} catch {} }
        if(autoProcess) { try rewards.process() {} catch {} }

        emit Transfer(sender, (recipient != DEAD ? recipient : address(0)), amountReceived);
        return true;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }
    
    function checkWalletLimit(address recipient, uint256 amount) internal view {
        uint256 walletLimit = getMaximumWallet();
        require(_balances[recipient] + amount <= walletLimit, "Transfer amount exceeds the bag size.");
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= getTransactionLimit() || isTxLimitExempt[sender], "TX Limit Exceeded");
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function getTotalFee(bool selling) public view returns (uint256) {
        if(launchedAt + deadBlocks > block.number){ return feeDenominator - 1; }
        return (selling ? totalSellFee : totalBuyFee);
    }

    function checkImpactEstimate(uint256 amount) public view returns (uint256) {
        (uint112 reserve0, uint112 reserve1,) = IDEXPair(pair).getReserves();
        return amount * 1000 / ((antiDumpReserve0 ? reserve0 : reserve1) + amount);
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = 0;
        if(liquidityPools[recipient] && antiDumpTax > 0) {
            uint256 impactEstimate = checkImpactEstimate(amount);
            
            if (block.timestamp > lastSell[sender] + antiDumpPeriod) {
                lastSell[sender] = block.timestamp;
                lastSellAmount[sender] = 0;
            }
            
            lastSellAmount[sender] += impactEstimate;
            
            if (lastSellAmount[sender] >= antiDumpThreshold) {
                feeAmount = ((amount * totalSellFee * antiDumpTax) / 100) / feeDenominator;
            }
        }

        if (feeAmount == 0)
            feeAmount = (amount * getTotalFee(liquidityPools[recipient])) / feeDenominator;

        _balances[address(this)] += feeAmount;
        emit Transfer(sender, address(this), feeAmount);

        return amount - feeAmount;
    }

    function shouldSwapBack(address sender, address recipient) internal view returns (bool) {
        return !liquidityPools[sender]
        && !isFeeExempt[sender]
        && !inSwap
        && swapEnabled
        && liquidityPools[recipient]
        && _balances[address(this)] >= swapMinimum &&
        totalBuyFee + totalSellFee > 0;
    }

    function swapBack(uint256 amount) internal swapping {
        uint256 totalFee = totalBuyFee + totalSellFee;
        uint256 amountToSwap = amount - (amount * maxSwapPercent / 100) < swapThreshold ? amount * maxSwapPercent / 100 : swapThreshold;
        if (_balances[address(this)] < amountToSwap) amountToSwap = _balances[address(this)];
        
        uint256 dynamicLiquidityFee = isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : liquidityFee + liquiditySellFee;
        uint256 amountToLiquify = ((amountToSwap * dynamicLiquidityFee) / totalFee) / 2;
        amountToSwap -= amountToLiquify;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        
        //Guaranteed swap desired to prevent trade blockages
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 contractBalance = address(this).balance;
        uint256 totalETHFee = totalFee - dynamicLiquidityFee / 2;

        uint256 amountLiquidity = (contractBalance * dynamicLiquidityFee) / totalETHFee / 2;
        uint256 amountRewards = (contractBalance * (USDCRewardFee + USDCRewardSellFee)) / totalETHFee;
        uint256 amountCommunity = (contractBalance * (communityAwardFee + communityAwardSellFee)) / totalETHFee;
        uint256 amountMarketing = contractBalance - (amountLiquidity + amountRewards + amountCommunity);

        if(amountToLiquify > 0) {
            //Guaranteed swap desired to prevent trade blockages, return values ignored
            router.addLiquidityETH{value: amountLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                liquidityReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountLiquidity, amountToLiquify);
        }
        
        if (amountMarketing > 0) {
            (bool sentMarketing, ) = marketingReceiver.call{value: amountMarketing}("");
            if(!sentMarketing) {
                //Failed to transfer to marketing wallet
            }
        }

        if (amountRewards > 0)
            try rewards.deposit{value: amountRewards}() {} catch {}
            
        if (amountCommunity > 0) {
            (bool sentCommunity, ) = communityReceiver.call{value: amountCommunity}("");
            if(!sentCommunity) {
                //Failed to transfer to community wallet
            }
        }

    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply - (balanceOf(DEAD) + balanceOf(address(0)));
    }

    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return (accuracy * balanceOf(pair)) / getCirculatingSupply();
    }

    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    }

    function transferOwnership(address newOwner) public virtual override onlyOwner {
        require(owner() == _msgSender(), "Caller is not authorized");
        isFeeExempt[owner()] = false;
        isTxLimitExempt[owner()] = false;
        liquidityProviders[owner()] = false;
        _allowances[owner()][routerAddress] = 0;
        super.transferOwnership(newOwner);
    }

    function lockContract() external onlyOwner {
        require(locker == address(0), "Contract already locked");
        unlocksAt = block.timestamp + 14 days;
        locker = owner();
        super.renounceOwnership();
    }

    function unlockContract() external {
        require(locker != address(0) && (msg.sender == locker || liquidityProviders[msg.sender]), "Caller is not authorized");
        require(unlocksAt <= block.timestamp, "Contract still locked");
        super.transferOwnership(locker);
        locker = address(0);
        unlocksAt = 0;
    }

    function renounceOwnership() public virtual override onlyOwner {
        isFeeExempt[owner()] = false;
        isTxLimitExempt[owner()] = false;
        liquidityProviders[owner()] = false;
        _allowances[owner()][routerAddress] = 0;
        super.renounceOwnership();
    }

    function _checkOwner() internal view virtual override {
        require(owner() != address(0) && (owner() == _msgSender() || liquidityProviders[_msgSender()]), "Ownable: caller is not authorized");
    }

    function setProtectionEnabled(bool _protect) external onlyOwner {
        if (_protect)
            require(!protectionDisabled, "Protection disabled");
        protectionEnabled = _protect;
        emit ProtectionToggle(_protect);
    }
    
    function setProtection(address _protection, bool _call) external onlyOwner {
        if (_protection != address(antisnipe)){
            require(!protectionDisabled, "Protection disabled");
            antisnipe = IAntiSnipe(_protection);
        }
        if (_call)
            antisnipe.setTokenOwner(address(this), pair);
        
        emit ProtectionSet(_protection);
    }
    
    function disableProtection() external onlyOwner {
        protectionDisabled = true;
        emit ProtectionDisabled();
    }
    
    function setLiquidityProvider(address _provider, bool _set) external onlyOwner {
        require(_provider != pair && _provider != routerAddress, "Can't alter trading contracts in this manner.");
        isFeeExempt[_provider] = _set;
        liquidityProviders[_provider] = _set;
        isTxLimitExempt[_provider] = _set;
        isDividendExempt[_provider] = _set;
        emit LiquidityProviderSet(_provider, _set);
    }

    function getPoolStatistics() external view returns (uint256 totalClaimed, uint256 holders) {
        totalClaimed = rewards.getTotalRewarded();
        holders = rewards.countShareholders();
    }
    
    function getWalletStatistics(address wallet) external view returns (uint256 pending, uint256 claimed) {
	    pending = rewards.getUnpaidEarnings(wallet);
	    claimed = rewards.getPaidDividends(wallet);
	}

    function resetShares(address shareholder) external onlyOwner {
        if(!isDividendExempt[shareholder]){ rewards.setShare(shareholder, _balances[shareholder]); }
        else rewards.setShare(shareholder, 0);
    }

    function setIsDividendExempt(address holder, bool exempt) external onlyOwner {
        require(holder != address(this) && !liquidityPools[holder] && holder != owner());
        isDividendExempt[holder] = exempt;
        if(exempt){
            rewards.setShare(holder, 0);
        }else{
            rewards.setShare(holder, _balances[holder]);
        }
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution, uint256 gas) external onlyOwner {
        require(gas < 750000);
        rewards.setDistributionCriteria(_minPeriod, _minDistribution, gas);
    }

    function setAntiDumpTax(uint256 _tax, uint256 _period, uint256 _threshold, bool _reserve0) external onlyOwner {
        require(_threshold >= 10 && _tax <= 300 && (_tax == 0 || _tax >= 100) && _period <= 1 hours, "Parameters out of bounds");
        antiDumpTax = _tax;
        antiDumpPeriod = _period;
        antiDumpThreshold = _threshold;
        antiDumpReserve0 = _reserve0;
        emit AntiDumpTaxSet(_tax, _period, _threshold);
    }

    function launch(uint256 _deadBlocks) external payable onlyOwner {
        require(launchedAt == 0 && _deadBlocks < 7);
        require(msg.value > 0, "Insufficient funds");
        uint256 toLP = msg.value;

        IDEXFactory factory = IDEXFactory(router.factory());
        address ETH = router.WETH();

        pair = factory.getPair(ETH, address(this));
        if(pair == address(0))
            pair = factory.createPair(ETH, address(this));

        liquidityPools[pair] = true;
        isDividendExempt[pair] = true;
        isFeeExempt[address(this)] = true;
        liquidityProviders[address(this)] = true;

        router.addLiquidityETH{value: toLP}(address(this),balanceOf(address(this)),0,0,msg.sender,block.timestamp);

        deadBlocks = _deadBlocks;
        launchedAt = block.number;
        launchedTime = block.timestamp;
        emit TradingLaunched();
    }

    function setAutoProcess(bool _enabled) external onlyOwner {
        autoProcess = _enabled;
    }

    function setTxLimit(uint256 thousandths) external onlyOwner {
        require(thousandths > 0 , "Transaction limits too low");
        _maxTxAmount = thousandths;
        emit TransactionLimitSet(getTransactionLimit());
    }

    function getTransactionLimit() public view returns (uint256) {
        if(!launched()) return 0;
        return getCirculatingSupply() * _maxTxAmount / 1000;
    }
    
    function setMaxWallet(uint256 thousandths) external onlyOwner() {
        require(thousandths > 1, "Wallet limits too low");
        _maxWalletSize = thousandths;
        emit MaxWalletSet(getMaximumWallet());
    }

    function getMaximumWallet() public view returns (uint256) {
        if(!launched()) return 0;
        return getCirculatingSupply() * _maxWalletSize / 1000;
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        require(holder != address(0), "Invalid address");
        isFeeExempt[holder] = exempt;
        emit FeeExemptSet(holder, exempt);
    }

    function setIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        require(holder != address(0), "Invalid address");
        isTxLimitExempt[holder] = exempt;
        emit TrasactionLimitExemptSet(holder, exempt);
    }

    function setFees(uint256 _rewardsFee, uint256 _rewardsSellFee, uint256 _liquidityFee, uint256 _liquiditySellFee, uint256 _marketingFee, uint256 _marketingSellFee, uint256 _communityFee, uint256 _communitySellFee, uint256 _feeDenominator) external onlyOwner {
        require(((_liquidityFee + _liquiditySellFee) / 2) * 2 == _liquidityFee, "Liquidity fee total must be an even number due to rounding");
        USDCRewardFee = _rewardsFee;
        USDCRewardSellFee = _rewardsSellFee;
        liquidityFee = _liquidityFee;
        liquiditySellFee = _liquiditySellFee;
        marketingFee = _marketingFee;
        marketingSellFee = _marketingSellFee;
        communityAwardFee = _communityFee;
        communityAwardSellFee = _communitySellFee;
        totalBuyFee = _rewardsFee + _liquidityFee + _marketingFee + _communityFee;
        totalSellFee = _rewardsSellFee + _liquiditySellFee + _marketingSellFee + _communitySellFee;
        feeDenominator = _feeDenominator;
        require(totalBuyFee + totalSellFee <= feeDenominator / 5, "Fees too high");
        emit FeesSet(totalBuyFee, totalSellFee, feeDenominator);
    }

    function setSwapBackSettings(bool _enabled, uint256 _denominator, uint256 _denominatorMin) external onlyOwner {
        require(_denominator > 0 && _denominatorMin > 0, "Denominators must be greater than 0");
        swapEnabled = _enabled;
        swapMinimum = _totalSupply / _denominatorMin;
        swapThreshold = _totalSupply / _denominator;
        emit SwapSettingsSet(swapMinimum, swapThreshold, swapEnabled);
    }

    function setTargetLiquidity(uint256 _target, uint256 _denominator) external onlyOwner {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
        emit TargetLiquiditySet(_target * 100 / _denominator);
    }

    function addLiquidityPool(address _pool, bool _enabled) external onlyOwner {
        require(_pool != address(0), "Invalid address");
        liquidityPools[_pool] = _enabled;
        emit LiquidityPoolSet(_pool, _enabled);
    }

	function airdrop(address[] calldata _addresses, uint256[] calldata _amount) external onlyOwner
    {
        require(_addresses.length == _amount.length, "Array lengths don't match");
        bool previousSwap = swapEnabled;
        swapEnabled = false;
        //This function may run out of gas intentionally to prevent partial airdrops
        for (uint256 i = 0; i < _addresses.length; i++) {
            require(!liquidityPools[_addresses[i]] && _addresses[i] != address(0), "Can't airdrop the liquidity pool or address 0");
            _transferFrom(msg.sender, _addresses[i], _amount[i] * (10 ** _decimals));
        }
        swapEnabled = previousSwap;
        emit AirdropSent(msg.sender);
    }

    event AutoLiquify(uint256 amount, uint256 amountToken);
    event ProtectionSet(address indexed protection);
    event ProtectionDisabled();
    event LiquidityProviderSet(address indexed provider, bool isSet);
    event TradingLaunched();
    event TransactionLimitSet(uint256 limit);
    event MaxWalletSet(uint256 limit);
    event FeeExemptSet(address indexed wallet, bool isExempt);
    event TrasactionLimitExemptSet(address indexed wallet, bool isExempt);
    event FeesSet(uint256 totalBuyFees, uint256 totalSellFees, uint256 denominator);
    event SwapSettingsSet(uint256 minimum, uint256 maximum, bool enabled);
    event LiquidityPoolSet(address indexed pool, bool enabled);
    event AirdropSent(address indexed from);
    event AntiDumpTaxSet(uint256 rate, uint256 period, uint256 threshold);
    event TargetLiquiditySet(uint256 percent);
    event ProtectionToggle(bool isEnabled);
}