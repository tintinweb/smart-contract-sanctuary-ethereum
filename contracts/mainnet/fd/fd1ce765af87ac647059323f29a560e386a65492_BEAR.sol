/**
 *Submitted for verification at Etherscan.io on 2022-03-06
*/

/**
 * BEAR BUCKS                   BEARBUCKS.FINANCE                     T.ME/BEARBUCKS
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

/**
 * SAFEMATH LIBRARY
 */
library SafeMath {
    
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

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
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    /**
     * Authorize address. Owner only
     */
    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
     */
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

interface IDEXFactory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);
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
    function deposit() external payable;
}

contract DividendDistributor is IDividendDistributor, Auth {
    using SafeMath for uint256;

    address _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    IERC20 BASE = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    IDEXRouter router;

    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;

    mapping (address => uint256) public totalRewardsDistributed;
    mapping (address => mapping (address => uint256)) public totalRewardsToUser;

    mapping (address => mapping (address => bool)) public canClaimDividendOfUser;

    mapping (address => bool) public availableRewards;
    mapping (address => address) public pathRewards;

    mapping (address => bool) public allowed;
    mapping (address => address) public choice;

    mapping (address => Share) public shares;

    //bool public blacklistMode = true;

    address public USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed; // to be shown in UI
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;

    modifier onlyToken() {
        require(msg.sender == _token); _;
    }

    constructor (
        address _router,
        address _owner
    ) Auth(_owner) {
        router = _router != address(0) ? IDEXRouter(_router) : IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _token = msg.sender;

        allowed[USDT] = true;
        allowed[USDC] = true;
        allowed[DAI] = true;

        IERC20(BASE).approve(_router, 2**256 - 1);
    }

    receive() external payable {}

    function getTotalRewards(address token) public view returns (uint256) {
        return totalRewardsDistributed[token];
    }

    function getTotalRewardsToUser(address token, address user) public view returns (uint256) {
        return totalRewardsToUser[token][user];
    }

    function checkCanClaimDividendOfUser(address user, address claimer) public view returns (bool) {
        return canClaimDividendOfUser[user][claimer];
    }

    function setReward(
        address _reward,
        bool status
    ) public onlyOwner {
        availableRewards[_reward] = status;
    }

    function setPathReward(
        address _reward,
        address _path
    ) public onlyOwner {
        pathRewards[_reward] = _path;
    }

    function getPathReward(
        address _reward
    ) public view returns (address) {
        return pathRewards[_reward];
    }

    function changeRouterVersion(
        address _router
    ) external onlyOwner {
        IDEXRouter _uniswapV2Router = IDEXRouter(_router);
        router = _uniswapV2Router;
    }

    function setShare(
        address shareholder,
        uint256 amount
    ) external override onlyToken {

        if (shares[shareholder].amount > 0) {
            if (allowed[choice[shareholder]]) {
                distributeDividend(shareholder, choice[shareholder]);
            } else {
                distributeDividend(shareholder, USDT);
            }
        }

        if (amount > 0 && shares[shareholder].amount == 0) {
            addShareholder(shareholder);
        } else if (amount == 0 && shares[shareholder].amount > 0) {
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function deposit() external payable override onlyToken {
        uint256 amount = msg.value;

        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
    }

    function distributeDividend(
        address shareholder,
        address rewardAddress
    ) internal {
        require(allowed[rewardAddress], "Invalid reward address!");

        if (shares[shareholder].amount == 0) {
            return;
        }

        uint256 amount = getUnpaidEarnings(shareholder);
        if (amount > 0) {
            totalDistributed = totalDistributed.add(amount);

            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);

            if (rewardAddress == address(BASE)) {

                payable(shareholder).transfer(amount);
                totalRewardsDistributed[rewardAddress] = totalRewardsDistributed[rewardAddress].add(amount);  
                totalRewardsToUser[rewardAddress][shareholder] = totalRewardsToUser[rewardAddress][shareholder].add(amount);

            } else {

                IERC20 rewardToken = IERC20(rewardAddress);

                uint256 beforeBalance = rewardToken.balanceOf(shareholder);

                if (pathRewards[rewardAddress] == address(0)) {
                    address[] memory path = new address[](2);
                    path[0] = address(BASE);
                    path[1] = rewardAddress;

                    router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
                        0,
                        path,
                        shareholder,
                        block.timestamp
                    );                 
                } else {
                    address[] memory path = new address[](3);
                    path[0] = address(BASE);
                    path[1] = pathRewards[rewardAddress];
                    path[2] = rewardAddress;

                    router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
                        0,
                        path,
                        shareholder,
                        block.timestamp
                    );

                }

                uint256 afterBalance = rewardToken.balanceOf(shareholder);
                totalRewardsDistributed[rewardAddress] = totalRewardsDistributed[rewardAddress].add(afterBalance.sub(beforeBalance));
                totalRewardsToUser[rewardAddress][shareholder] = totalRewardsToUser[rewardAddress][shareholder].add(afterBalance.sub(beforeBalance));

            }

        }
    }

    function makeApprove(
        address token,
        address spender,
        uint256 amount
    ) public onlyOwner {
        IERC20(token).approve(spender, amount);
    }

    function claimDividend(
        address rewardAddress
    ) external {
        distributeDividend(msg.sender, rewardAddress);
    }

    function setChoice(
        address _choice
    ) external {
        require(allowed[_choice]);
        choice[msg.sender] = _choice;
    }

    function toggleChoice(
        address _choice
    ) public onlyOwner {
        allowed[_choice] = !allowed[_choice];
    }

    function getChoice(
        address _choice
    ) public view returns (bool) {
        return allowed[_choice];
    }

    function claimDividendOfUser(
        address user,
        address rewardAddress
    ) external {
        require(canClaimDividendOfUser[user][msg.sender], "You can't do that");

        distributeDividend(user, rewardAddress);
    }

    function setClaimDividendOfUser(
        address claimer,
        bool status
    ) external {
        canClaimDividendOfUser[msg.sender][claimer] = status;
    }

    function getUnpaidEarnings(
        address shareholder
    ) public view returns (uint256) {
        if (shares[shareholder].amount == 0) {
            return 0;
        }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if (shareholderTotalDividends <= shareholderTotalExcluded) {
            return 0;
        }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(
        uint256 share
    ) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    function addShareholder(
        address shareholder
    ) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(
        address shareholder
    ) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length - 1];
        shareholderIndexes[shareholders[shareholders.length - 1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }

    function Sweep() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function changeBASE(
        address _BASE
    ) external onlyOwner {
        BASE = IERC20(_BASE);
    }

    function changeWETH(
        address _WETH
    ) external onlyOwner {
        WETH = _WETH;
    }

    function changeUSDT(
        address _USDT
    ) external onlyOwner {
        USDT = _USDT;
    }

    function newApproval(
        address token,
        address _contract
    ) external onlyOwner {
        IERC20(token).approve(_contract, 2**256 - 1);
    }

    function transferForeignToken(
        address token,
        address _to
    ) external onlyOwner returns (bool _sent) {
        require(token != address(this), "Can't withdraw native tokens");
        uint256 _contractBalance = IERC20(token).balanceOf(address(this));
        _sent = IERC20(token).transfer(_to, _contractBalance);
    }

}

contract BEAR is IERC20, Auth {
    using SafeMath for uint256;

    uint256 public constant MASK = type(uint128).max;
    address BASE = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    address DEAD_NON_CHECKSUM = 0x000000000000000000000000000000000000dEaD;

    string constant _name = "Bear Bucks";
    string constant _symbol = "BEAR";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 1000000000 * (10 ** _decimals);
    uint256 public _maxWallet = _totalSupply.div(50);

    uint256 public minAmountToTriggerSwap = 0;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) public isDisabledExempt;
    mapping (address => bool) public isFeeExempt;
    mapping (address => bool) public isDividendExempt;
    mapping (address => bool) public _isFree;

    bool public isFeeOnTransferEnabled = false;

    mapping (address => bool) public automatedMarketMakerPairs;

    uint256 buyLiquidityFee = 0;
    uint256 buyReflectionFee = 300;
    uint256 buyOperationsFee = 700;
    uint256 buyTreasuryFee = 0;
    uint256 buyTotalFee = 1000;

    uint256 sellLiquidityFee = 250;
    uint256 sellReflectionFee = 1750;
    uint256 sellOperationsFee = 0;
    uint256 sellTreasuryFee = 0;
    uint256 sellTotalFee = 2000;

    uint256 feeDenominator = 10000;

    uint256 _liquidityTokensToSwap;
    uint256 _reflectionTokensToSwap;
    uint256 _operationsTokensToSwap;
    uint256 _treasuryTokensToSwap;

    address public autoLiquidityReceiver = 0x2FFBfc2715037A9Af201aFeF7e998912cC2b048c;
    address public operationsFeeReceiver = 0x6F33931D8F66e52f44acd3De3F870191699E98a2;
    address public treasuryFeeReceiver = msg.sender;

    IDEXRouter public router;
    address public pair;

    DividendDistributor distributor;
    address public distributorAddress;

    bool public swapEnabled = true;
    uint256 private swapMinimumTokens = _totalSupply / 5000; // 0.0025%

    bool public tradingEnabled = false;

    bool inSwap;
    modifier swapping() {
        inSwap = true; _;
        inSwap = false;
    }

    constructor () Auth(msg.sender) {
        address _router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        router = IDEXRouter(_router);
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));
        _allowances[address(this)][address(router)] = _totalSupply;
        WETH = router.WETH();
        distributor = new DividendDistributor(_router, msg.sender);
        distributorAddress = address(distributor);

        isDisabledExempt[msg.sender] = true;
        isFeeExempt[msg.sender] = true;
        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;

        autoLiquidityReceiver = msg.sender;

        _setAutomatedMarketMakerPair(pair, true);

        approve(_router, _totalSupply);
        approve(address(pair), _totalSupply);
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    

    receive() external payable {}

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(
        address spender
    ) external returns (bool) {
        return approve(spender, _totalSupply);
    }

    function transfer(
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (_allowances[sender][msg.sender] != _totalSupply) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        require(tradingEnabled || isDisabledExempt[sender], "Trading is currently disabled");

        address routerAddress = address(router);
        bool isSell = automatedMarketMakerPairs[recipient] || recipient == routerAddress;

        if (!isSell && !_isFree[recipient]) {
            require((_balances[recipient] + amount) < _maxWallet, "Max wallet has been triggered");
        }

        if (isSell && amount >= minAmountToTriggerSwap) {
            if (shouldSwapBack()) {
                swapBack();
            }
        }

        _balances[sender] = _balances[sender].sub(amount, "Insufficient balance");

        uint256 amountReceived = shouldTakeFee(sender, recipient) ? takeFee(sender, recipient, amount) : amount;

        _balances[recipient] = _balances[recipient].add(amountReceived);

        if (!isDividendExempt[sender]) {
            try distributor.setShare(sender, _balances[sender]) {} catch {}
        }
        if (!isDividendExempt[recipient]) {
            try distributor.setShare(recipient, _balances[recipient]) {} catch {}
        }

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        return true;
    }

    function shouldTakeFee(
        address sender,
        address recipient
    ) internal view returns (bool) {

        if (isFeeOnTransferEnabled) {
            return !isFeeExempt[sender] && !isFeeExempt[recipient];
        } else {
            address routerAddress = address(router);
            bool isBuy = automatedMarketMakerPairs[sender] || sender == routerAddress;
            bool isSell =  automatedMarketMakerPairs[recipient]|| recipient == routerAddress;

            if (isBuy || isSell) {
                return !isFeeExempt[sender] && !isFeeExempt[recipient];
            } else {
                return false;
            }
        }

    }

    function getTotalFee(
        bool selling
    ) public view returns (uint256) {
        if (selling) {
            return sellTotalFee;
        }
        return buyTotalFee;
    }

    function takeFee(
        address sender,
        address receiver,
        uint256 amount
    ) internal returns (uint256) {
        address routerAddress = address(router);
        bool isSell = automatedMarketMakerPairs[receiver] || receiver == routerAddress;

        uint256 totalFee = getTotalFee(isSell);
        uint256 feeAmount = amount.mul(totalFee).div(feeDenominator);

        if (totalFee > 0) {
            if (isSell) {
                if (sellLiquidityFee > 0) {
                    _liquidityTokensToSwap += feeAmount * sellLiquidityFee / totalFee;
                }
                if (sellOperationsFee > 0) {
                    _operationsTokensToSwap += feeAmount * sellOperationsFee / totalFee;
                }
                if (sellReflectionFee > 0) {
                    _reflectionTokensToSwap += feeAmount * sellReflectionFee / totalFee;
                }
                if (sellTreasuryFee > 0) {
                    _treasuryTokensToSwap += feeAmount * sellTreasuryFee / totalFee;
                }
            } else {
                if (buyLiquidityFee > 0) {
                    _liquidityTokensToSwap += feeAmount * buyLiquidityFee / totalFee;
                }
                if (buyOperationsFee > 0) {
                    _operationsTokensToSwap += feeAmount * buyOperationsFee / totalFee;
                }
                if (buyReflectionFee > 0) {
                    _reflectionTokensToSwap += feeAmount * buyReflectionFee / totalFee;
                }
                if (buyTreasuryFee > 0) {
                    _treasuryTokensToSwap += feeAmount * buyTreasuryFee / totalFee;
                }
            }
        }

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return !automatedMarketMakerPairs[msg.sender] && !inSwap && swapEnabled && _balances[address(this)] >= swapMinimumTokens;
    }

    function setAutomatedMarketMakerPair(
        address _pair,
        bool value
    ) public onlyOwner {
        _setAutomatedMarketMakerPair(_pair, value);
    }

    function _setAutomatedMarketMakerPair(
        address _pair,
        bool value
    ) private {
        automatedMarketMakerPairs[_pair] = value;
        if (value) {
            isDividendExempt[_pair] = true;
        }
        if (!value) {
            isDividendExempt[_pair] = false;
        }
    }

    function swapBack() internal swapping {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = _liquidityTokensToSwap.add(_operationsTokensToSwap).add(_reflectionTokensToSwap).add(_treasuryTokensToSwap);
        
        uint256 tokensForLiquidity = _liquidityTokensToSwap.div(2);
        uint256 amountToSwap = contractBalance.sub(tokensForLiquidity);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;
        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountETH = address(this).balance.sub(balanceBefore);

        uint256 amountETHLiquidity = amountETH.mul(_liquidityTokensToSwap).div(totalTokensToSwap).div(2);
        uint256 amountETHReflection = amountETH.mul(_reflectionTokensToSwap).div(totalTokensToSwap);
        uint256 amountETHOperations = amountETH.mul(_operationsTokensToSwap).div(totalTokensToSwap);
        uint256 amountETHTreasury = amountETH.mul(_treasuryTokensToSwap).div(totalTokensToSwap);
        
        _liquidityTokensToSwap = 0;
        _operationsTokensToSwap = 0;
        _reflectionTokensToSwap = 0;
        _treasuryTokensToSwap = 0;

        if (amountETHReflection > 0) {
            try distributor.deposit{value: amountETHReflection}() {} catch {}
        }
        if (amountETHOperations > 0) {
            payable(operationsFeeReceiver).transfer(amountETHOperations);
        }
        if (amountETHTreasury > 0) {
            payable(treasuryFeeReceiver).transfer(amountETHTreasury);
        }

        if (tokensForLiquidity > 0) {
            router.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                tokensForLiquidity,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountETHLiquidity, tokensForLiquidity);
        }
    }

    function buyTokens(
        uint256 amount,
        address to
    ) internal swapping {
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = address(this);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            to,
            block.timestamp
        );
    }
    
    function Sweep() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function changeBASE(
        address _BASE
    ) external onlyOwner {
        BASE = _BASE;
    }

    function changeWETH(
        address _WETH
    ) external onlyOwner {
        WETH = _WETH;
    }

    function changeRouterPairDistributor(
        address _router,
        bool _setWETH
    ) external onlyOwner {
        router = IDEXRouter(_router);
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));
        _allowances[address(this)][address(router)] = _totalSupply;
        if (_setWETH) {
            WETH = router.WETH();
        }
        distributor = new DividendDistributor(_router, msg.sender);
        distributorAddress = address(distributor);
    }

    function transferForeignToken(
        address _token,
        address _to
    ) external onlyOwner returns (bool _sent) {
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        _sent = IERC20(_token).transfer(_to, _contractBalance);
    }

    function setMaxWallet(
        uint256 amount
    ) external authorized {
        _maxWallet = amount;
    }

    function setMinAmountToTriggerSwap(
        uint256 amount
    ) external authorized {
        minAmountToTriggerSwap = amount;
    }

    function setIsFeeOnTransferEnabled(
        bool status
    ) external authorized {
        isFeeOnTransferEnabled = status;
    }

    function setIsDividendExempt(
        address holder,
        bool exempt
    ) external authorized {
        isDividendExempt[holder] = exempt;
        if (exempt) {
            distributor.setShare(holder, 0);
        } else {
            distributor.setShare(holder, _balances[holder]);
        }
    }

    function checkIsDividendExempt(
        address holder
    ) public view returns (bool) {
        return isDividendExempt[holder];
    }

    function setIsDisabledExempt(
        address holder,
        bool exempt
    ) external authorized {
        isDisabledExempt[holder] = exempt;
    }

    function checkIsDisabledExempt(
        address holder
    ) public view returns (bool) {
        return isDisabledExempt[holder];
    }

    function setIsFeeExempt(
        address holder,
        bool exempt
    ) external authorized {
        isFeeExempt[holder] = exempt;
    }

    function checkIsFeeExempt(
        address holder
    ) public view returns (bool) {
        return isFeeExempt[holder];
    }

    function setFree(
        address holder
    ) public onlyOwner {
        _isFree[holder] = true;
    }
    
    function unSetFree(
        address holder
    ) public onlyOwner {
        _isFree[holder] = false;
    }

    function checkFree(
        address holder
    ) public view onlyOwner returns (bool) {
        return _isFree[holder];
    }

    function setFees(
        uint256 _buyLiquidityFee,
        uint256 _buyReflectionFee,
        uint256 _buyOperationsFee,
        uint256 _buyTreasuryFee,
        uint256 _sellLiquidityFee,
        uint256 _sellReflectionFee,
        uint256 _sellOperationsFee,
        uint256 _sellTreasuryFee,
        uint256 _feeDenominator
    ) external authorized {
        buyLiquidityFee = _buyLiquidityFee;
        buyReflectionFee = _buyReflectionFee;
        buyOperationsFee = _buyOperationsFee;
        buyTreasuryFee = _buyTreasuryFee;
        buyTotalFee = _buyLiquidityFee.add(_buyReflectionFee).add(_buyOperationsFee).add(_buyTreasuryFee);

        sellLiquidityFee = _sellLiquidityFee;
        sellReflectionFee = _sellReflectionFee;
        sellOperationsFee = _sellOperationsFee;
        sellTreasuryFee = _sellTreasuryFee;
        sellTotalFee = _sellLiquidityFee.add(_sellReflectionFee).add(_sellOperationsFee).add(_sellTreasuryFee);

        feeDenominator = _feeDenominator;
    }

    function setFeeReceivers(
        address _autoLiquidityReceiver,
        address _operationsFeeReceiver,
        address _treasuryFeeReceiver
    ) external authorized {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        operationsFeeReceiver = _operationsFeeReceiver;
        treasuryFeeReceiver = _treasuryFeeReceiver;
    }

    function enableTrading() external authorized {
        if (!tradingEnabled) {
            tradingEnabled = true;
        }
    }

    function toggleTrading(
        bool _enabled
    ) external authorized {
        tradingEnabled = _enabled;
    }

    function setSwapBackSettings(
        bool _enabled,
        uint256 _amount
    ) external authorized {
        swapEnabled = _enabled;
        swapMinimumTokens = _amount;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }
    
    function changeRouterVersion(
        address _router
    ) external onlyOwner returns (address _pair) {
        IDEXRouter _uniswapV2Router = IDEXRouter(_router);

        _pair = IDEXFactory(_uniswapV2Router.factory()).getPair(address(this), _uniswapV2Router.WETH());
        if (_pair == address(0)) {
            _pair = IDEXFactory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        }
        pair = _pair;

        router = _uniswapV2Router;
        _allowances[address(this)][address(router)] = _totalSupply;
    }

    event AutoLiquify(uint256 amountETH, uint256 amountBOG);
}