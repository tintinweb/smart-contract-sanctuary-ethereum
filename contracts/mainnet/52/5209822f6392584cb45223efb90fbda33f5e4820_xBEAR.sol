/**
 *Submitted for verification at Etherscan.io on 2022-03-08
*/

/**
 *    xBEAR       BEARBUCKS.FINANCE        T.ME/BEARBUCKS
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

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    constructor() {
        _status = _NOT_ENTERED;
    }
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

contract xBEAR is IERC20, Auth, ReentrancyGuard {
    using SafeMath for uint256;

    uint256 public constant MASK = type(uint128).max;
    address BASE = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    address DEAD_NON_CHECKSUM = 0x000000000000000000000000000000000000dEaD;
    address WBEAR = 0xd11a3EdaC587faa6bD870683114F5Aa08499f187;
    address TREASURY = 0xdbc85dF60C8E6cF056FF418EdCA44Be368da85D5;
    IERC20 wbear = IERC20(WBEAR);

    address XBEAR;
    IERC20 xbear;

    string constant _name = "Staked Wrapped Bear Bucks";
    string constant _symbol = "xBEAR";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 1000000000 * (10 ** _decimals);

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) public isDisabledExempt;
    mapping (address => bool) public isFeeExempt;
    mapping (address => bool) public isDividendExempt;
    mapping (address => bool) public _isFree;

    bool public isFeeOnTransferEnabled = false;

    mapping (address => bool) public automatedMarketMakerPairs;

    IDEXRouter public router;
    address public pair;

    DividendDistributor distributor;
    address public distributorAddress;

    bool public tradingEnabled = false;

    bool public canEmergencySweep = true;
    bool public hasEmergencySweeped = false;
    bool public paused = false;
    bool public safetyChecks = false;

    constructor () Auth(msg.sender) {
        XBEAR = address(this);
        xbear = IERC20(XBEAR);

        address _router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        router = IDEXRouter(_router);
        pair = IDEXFactory(router.factory()).createPair(WETH, XBEAR);
        _allowances[XBEAR][address(router)] = _totalSupply;
        WETH = router.WETH();
        distributor = new DividendDistributor(_router, msg.sender);
        distributorAddress = address(distributor);

        isDisabledExempt[msg.sender] = true;
        isFeeExempt[msg.sender] = true;
        isDividendExempt[pair] = true;
        isDividendExempt[XBEAR] = true;
        isDividendExempt[DEAD] = true;

        approve(XBEAR, _totalSupply);
        approve(WBEAR, _totalSupply);
        approve(_router, _totalSupply);
        approve(address(pair), _totalSupply);
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), XBEAR, _totalSupply);
    }

    function isTreasury(address account) public view returns (bool) {
        return account == TREASURY;
    }

    modifier onlyTreasury() {
        require(isTreasury(msg.sender), "!TREASURY"); _;
    }

    modifier onlyOwnerOrTreasury() {
        require(isOwner(msg.sender) || isTreasury(msg.sender), "!OWNER && !TREASURY"); _;
    }

    function mint(
        uint256 _amount
    ) external nonReentrant {
        require(!hasEmergencySweeped, "This contract is no longer in use");
        require(!paused, "This contract is paused");
        if (safetyChecks) {
            require(wbear.balanceOf(msg.sender) >= _amount, "Your wBEAR balance is too low");
            require(wbear.allowance(msg.sender, XBEAR) >= _amount, "xBEAR allowance is too low");
        }
        require(_totalSupply >= _amount, "The amount exceeds the supply");
        bool _transfer = wbear.transferFrom(msg.sender, XBEAR, _amount);
        require(_transfer, "Failed to receive tokens");
        _transferFrom(XBEAR, msg.sender, _amount);
    }

    function redeem(
        uint256 _amount
    ) external nonReentrant {
        require(!hasEmergencySweeped, "This contract is no longer in use");
        require(!paused, "This contract is paused");
        if (safetyChecks) {
            require(_balances[msg.sender] >= _amount, "Your xBEAR balance is too low");
            require(_allowances[msg.sender][XBEAR] >= _amount, "xBEAR allowance is too low");
        }
        require(wbear.balanceOf(XBEAR) >= _amount, "The contract wBEAR balance is too low");
        bool _transfer = _transferFrom(msg.sender, XBEAR, _amount);
        require(_transfer, "Failed to send tokens");
        wbear.transfer(msg.sender, _amount);
    }

    function depositRewards() external payable onlyTreasury {
        if (msg.value > 0) {
            try distributor.deposit{value: msg.value}() {} catch {}
        }
    }

    function disableEmergencySweeping() external onlyOwner {
        require(!hasEmergencySweeped, "This contract is no longer in use");
        canEmergencySweep = false;
    }

    function emergencySweepCustom(
        address _to,
        uint256 _amount,
        bool _disable
    ) external onlyOwner {
        require(!hasEmergencySweeped, "This contract is no longer in use");
        require(canEmergencySweep, "Emergency sweeping has been disabled");
        wbear.transfer(_to, _amount);
        if (_disable) {
            hasEmergencySweeped = true;
        }
    }

    function emergencySweepFull(
        address _to
    ) external onlyOwner {
        require(!hasEmergencySweeped, "This contract is no longer in use");
        require(canEmergencySweep, "Emergency sweeping has been disabled");
        wbear.transfer(_to, wbear.balanceOf(XBEAR));
        hasEmergencySweeped = true;
    }

    function togglePaused(
        bool _paused
    ) external onlyOwner {
        paused = _paused;
    }

    function toggleSafetyChecks(
        bool _safetyChecks
    ) external onlyOwner {
        safetyChecks = _safetyChecks;
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
        require(tradingEnabled, "Trading is currently disabled");
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
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
    
    function Sweep() external onlyOwner {
        uint256 balance = XBEAR.balance;
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

    function changeBEAR(
        address _WBEAR,
        bool _approve
    ) external onlyOwner {
        WBEAR = _WBEAR;
        wbear = IERC20(_WBEAR);
        if (_approve) {
            approve(WBEAR, _totalSupply);
        }
    }

    function changeTREASURY(
        address _TREASURY
    ) external onlyOwnerOrTreasury {
        TREASURY = _TREASURY;
    }

    function changeRouterPairDistributor(
        address _router,
        bool _setWETH
    ) external onlyOwner {
        router = IDEXRouter(_router);
        pair = IDEXFactory(router.factory()).createPair(WETH, XBEAR);
        _allowances[XBEAR][address(router)] = _totalSupply;
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
        uint256 _contractBalance = IERC20(_token).balanceOf(XBEAR);
        _sent = IERC20(_token).transfer(_to, _contractBalance);
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

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function changeRouterVersion(
        address _router
    ) external onlyOwner returns (address _pair) {
        IDEXRouter _uniswapV2Router = IDEXRouter(_router);

        _pair = IDEXFactory(_uniswapV2Router.factory()).getPair(XBEAR, _uniswapV2Router.WETH());
        if (_pair == address(0)) {
            _pair = IDEXFactory(_uniswapV2Router.factory()).createPair(XBEAR, _uniswapV2Router.WETH());
        }
        pair = _pair;

        router = _uniswapV2Router;
        _allowances[XBEAR][address(router)] = _totalSupply;
    }
}