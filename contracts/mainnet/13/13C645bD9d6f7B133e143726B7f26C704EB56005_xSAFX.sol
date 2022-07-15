/**
 *Submitted for verification at Etherscan.io on 2022-07-15
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

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

abstract contract Ownable {
    address internal owner;
    constructor(address _owner) {
        owner = _owner;
    }
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER");
        _;
    }
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }
    function transferOwnership(address payable _ownerNew) external onlyOwner {
        owner = _ownerNew;
        emit OwnershipTransferred(_ownerNew);
    }
    event OwnershipTransferred(address _ownerNew);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IWETH {
    function withdraw(uint wad) external;
}

interface IRewardManager {
    function setShare(address _wallet, uint256 _amount) external;
    function depositRewards() external payable;
}

contract RewardManager is IRewardManager, Ownable {
    address _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    IERC20 public weth = IERC20(WETH);
    IWETH public wethContract = IWETH(WETH);

    address[] private _wallets;
    mapping (address => uint256) private _walletIndexes;

    mapping (address => uint256) public totalRewardsDistributed;
    mapping (address => mapping (address => uint256)) public totalRewardsToUser;

    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalRewards;
    uint256 public totalDistributed;
    uint256 public rewardsPerShare;
    uint256 public constant rpsPrecision = 10 ** 36;

    modifier onlyToken() {
        require(msg.sender == _token);
        _;
    }

    constructor (address _owner) Ownable(_owner) {
        _token = msg.sender;
    }

    receive() external payable {}

    function setShare(address _wallet, uint256 _amount) external override onlyToken {
        if (shares[_wallet].amount > 0) _claimRewards(_wallet, address(0));

        if (_amount > 0 && shares[_wallet].amount == 0) {
            _walletIndexes[_wallet] = _wallets.length;
            _wallets.push(_wallet);
        } else if (_amount == 0 && shares[_wallet].amount > 0) {
            _wallets[_walletIndexes[_wallet]] = _wallets[_wallets.length - 1];
            _walletIndexes[_wallets[_wallets.length - 1]] = _walletIndexes[_wallet];
            _wallets.pop();
        }

        totalShares = totalShares - shares[_wallet].amount + _amount;
        shares[_wallet].amount = _amount;
        shares[_wallet].totalExcluded = shares[_wallet].amount * rewardsPerShare / rpsPrecision;
    }

    function depositRewards() external payable override onlyToken {
        totalRewards = totalRewards + msg.value;
        rewardsPerShare = rewardsPerShare + (rpsPrecision * msg.value / totalShares);
    }

    function _claimRewards(address _wallet, address _reward) private {
        require(_reward == address(0) || _reward == WETH, "Invalid reward address!");
        if (shares[_wallet].amount == 0) return;

        uint256 amount = getUnclaimedRewards(_wallet);
        if (amount > 0) {
            totalDistributed = totalDistributed + amount;
            shares[_wallet].totalRealised = shares[_wallet].totalRealised + amount;
            shares[_wallet].totalExcluded = shares[_wallet].amount * rewardsPerShare / rpsPrecision;
            if (_reward == address(0)) {
                payable(_wallet).call{value: amount}("");
                totalRewardsDistributed[_reward] = totalRewardsDistributed[_reward] + amount;
                totalRewardsToUser[_reward][_wallet] = totalRewardsToUser[_reward][_wallet] + amount;
            } else {
                wethContract.withdraw(amount);
                weth.transfer(_wallet, amount);
                totalRewardsDistributed[_reward] = totalRewardsDistributed[_reward] + amount;
                totalRewardsToUser[_reward][_wallet] = totalRewardsToUser[_reward][_wallet] + amount;
            }
        }
    }

    function claimRewards(address _reward) external {
        _claimRewards(msg.sender, _reward);
    }

    function getUnclaimedRewards(address _wallet) public view returns (uint256) {
        if (shares[_wallet].amount == 0) return 0;
        uint256 walletTotalRewards = shares[_wallet].amount * rewardsPerShare / rpsPrecision;
        uint256 walletTotalExcluded = shares[_wallet].totalExcluded;
        return walletTotalRewards <= walletTotalExcluded ? 0 : walletTotalRewards - walletTotalExcluded;
    }

    function getTotalRewards(address token) external view returns (uint256) {
        return totalRewardsDistributed[token];
    }

    function getTotalRewardsToUser(address token, address user) external view returns (uint256) {
        return totalRewardsToUser[token][user];
    }

    function transferERC(address _erc20Address) external onlyOwner {
        require(_erc20Address != WETH, "Can't withdraw WETH");
        IERC20 _erc20 = IERC20(_erc20Address);
        _erc20.transfer(msg.sender, _erc20.balanceOf(address(this)));
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

contract xSAFX is IERC20, Ownable, ReentrancyGuard {
    string public constant _name = "Staked SAFX";
    string public constant _symbol = "xSAFX";
    uint8 public constant _decimals = 9;

    uint256 public constant _totalSupply = 1_000_000_000 * (10 ** _decimals);

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) public noReward;

    address public SAFX = 0x0654b7f747c9Ee9F5Fb5EbA443E9FE64F1fA77ef;
    IERC20 public safx = IERC20(SAFX);

    address public XSAFX;
    IERC20 public xsafx;

    address public pair;

    RewardManager manager;

    bool public stakingLive = false;

    bool public canChangeSAFX = true;
    bool public canPause = true;
    bool public paused = false;

    mapping (address => bool) private _depositors;

    constructor () Ownable(msg.sender) {
        XSAFX = address(this);
        xsafx = IERC20(XSAFX);

        pair = IDEXFactory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f).createPair(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, XSAFX);
        manager = new RewardManager(msg.sender);

        noReward[pair] = true;
        noReward[XSAFX] = true;
        noReward[0x000000000000000000000000000000000000dEaD] = true;
    
        _depositors[msg.sender] = true;

        approve(XSAFX, _totalSupply);
        approve(SAFX, _totalSupply);
        _balances[XSAFX] = _totalSupply;
        emit Transfer(address(0), XSAFX, _totalSupply);
    }

    receive() external payable {}

    function isDepositor(address account) public view returns (bool) {
        return _depositors[account];
    }

    modifier onlyDepositor() {
        require(isDepositor(msg.sender), "!DEPOSITOR");
        _;
    }

    function stake(uint256 _amount) external nonReentrant {
        require(!paused, "This contract is paused");
        require(safx.balanceOf(msg.sender) >= _amount, "Your SAFX balance is too low");
        require(safx.allowance(msg.sender, XSAFX) >= _amount, "SAFX allowance is too low");
        require(_totalSupply >= _amount, "The amount exceeds the supply");
        bool _transfer = safx.transferFrom(msg.sender, XSAFX, _amount);
        require(_transfer, "Failed to receive tokens");
        _transferFrom(XSAFX, msg.sender, _amount);
    }

    function unstake(uint256 _amount) external nonReentrant {
        require(!paused, "This contract is paused");
        require(_balances[msg.sender] >= _amount, "Your xSAFX balance is too low");
        require(_allowances[msg.sender][XSAFX] >= _amount, "xSAFX allowance is too low");
        require(safx.balanceOf(XSAFX) >= _amount, "The contract SAFX balance is too low");
        bool _transfer = _transferFrom(msg.sender, XSAFX, _amount);
        require(_transfer, "Failed to send tokens");
        safx.transfer(msg.sender, _amount);
    }

    function depositRewards() external payable onlyDepositor {
        if (msg.value > 0) try manager.depositRewards{value: msg.value}() {} catch {}
    }

    function changeDepositor(address _depositor, bool _value) external onlyOwner {
        _depositors[_depositor] = _value;
    }

    function disableCanPause() external onlyOwner {
        require(canPause, "Already disabled");
        canPause = false;
    }

    function setPaused(bool _paused) external onlyOwner {
        if (_paused == false) require(canPause, "Invalid permissions");
        paused = _paused;
    }

    function totalSupply() external pure override returns (uint256) {
        return _totalSupply;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function name() external pure override returns (string memory) {
        return _name;
    }

    function getOwner() external view override returns (address) {
        return owner;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address holder, address spender) external view override returns (uint256) {
        return _allowances[holder][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, _totalSupply);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != _totalSupply) {
            require(_allowances[sender][msg.sender] >= amount, "Insufficient allowance");
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) private returns (bool) {
        require(stakingLive, "Staking not live");
        require(_balances[sender] >= amount, "Insufficient balance");
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;

        if (!noReward[sender]) try manager.setShare(sender, _balances[sender]) {} catch {}
        if (!noReward[recipient]) try manager.setShare(recipient, _balances[recipient]) {} catch {}

        emit Transfer(sender, recipient, amount);
        return true;
    }

    function disableCanChangeSAFX() external onlyOwner {
        require(canChangeSAFX, "Already disabled");
        canChangeSAFX = false;
    }

    function changeSAFX(address _SAFX) external onlyOwner {
        require(canChangeSAFX, "Invalid permissions");
        SAFX = _SAFX;
        safx = IERC20(_SAFX);
        approve(_SAFX, _totalSupply);
    }

    function setNoReward(address _wallet, bool _value) external onlyOwner {
        noReward[_wallet] = _value;
        manager.setShare(_wallet, _value ? 0 : _balances[_wallet]);
    }

    function fetchNoReward(address _wallet) public view returns (bool) {
        return noReward[_wallet];
    }

    function enableStaking() external onlyOwner {
        stakingLive = true;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply - balanceOf(0x000000000000000000000000000000000000dEaD) - balanceOf(0x0000000000000000000000000000000000000000);
    }

    function transferETH() external onlyOwner {
        payable(msg.sender).call{value: SAFX.balance}("");
    }

    function transferERC(address _erc20Address) external onlyOwner {
        require(_erc20Address != SAFX, "Can't withdraw SAFX");
        require(_erc20Address != XSAFX, "Can't withdraw xSAFX");
        IERC20 _erc20 = IERC20(_erc20Address);
        _erc20.transfer(msg.sender, _erc20.balanceOf(SAFX));
    }
}