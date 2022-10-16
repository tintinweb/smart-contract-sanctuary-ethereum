/**
 *Submitted for verification at Etherscan.io on 2022-10-16
*/

pragma solidity ^0.8.17;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

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
    event Burn(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

abstract contract Auth {
    address internal owner;
    mapping(address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER");
        _;
    }

    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED");
        _;
    }

    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    function transferOwnership(address adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address liqPair);
}

interface IDEXRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

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

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract DGROW is IERC20, Auth {
    address DEAD = 0x000000000000000000000000000000000000dEaD;

    string _name = "Degen Grow";
    string _symbol = "DGROW";
    uint8 constant _zeros = 6;
    uint8 _decimals = 18;
    uint8 constant _maxTx = 30;
    uint8 constant _maxWallet = 50;
    uint256 _totalSupply = 1 * 10**_zeros * 10**_decimals;

    uint256 public _maxTxAmount = (_totalSupply * _maxTx) / 1000;
    uint256 public _maxWalletToken = (_totalSupply * _maxWallet) / 1000;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;

    mapping(address => bool) isFeeExempt;
    mapping(address => bool) isTxLimitExempt;
    mapping(address => bool) isWalletLimitExempt;

    uint256 public burnFee = 2;
    uint256 public feeDenominator = 100;

    IDEXRouter public Irouter02;
    address public liqPair;

    bool public tradingLive = false;
    uint256 private launchedAt;
    uint256 private deadBlocks;

    bool public limitsEnabled = true;
    bool public swapEnabled = true;
    bool inSwap;

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() Auth(msg.sender) {
        Irouter02 = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        liqPair = IDEXFactory(Irouter02.factory()).createPair(
            Irouter02.WETH(),
            address(this)
        );

        _allowances[address(this)][address(Irouter02)] = type(uint256).max;

        isFeeExempt[msg.sender] = true;
        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[DEAD] = true;
        isWalletLimitExempt[msg.sender] = true;
        isWalletLimitExempt[address(this)] = true;
        isWalletLimitExempt[DEAD] = true;
        isWalletLimitExempt[liqPair] = true;

        _approve(owner, address(Irouter02), type(uint256).max);
        _approve(address(this), address(Irouter02), type(uint256).max);
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function getOwner() external view override returns (address) {
        return owner;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address holder, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[holder][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(
        address sender,
        address spender,
        uint256 amount
    ) private {
        require(sender != address(0), "ERC20: Zero Address");
        require(spender != address(0), "ERC20: Zero Address");
        _allowances[sender][spender] = amount;
        emit Approval(sender, spender, amount);
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] =
                _allowances[sender][msg.sender] -
                amount;
        }
        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        if (inSwap) {
            return _basicTransfer(from, to, amount);
        }

        if (!authorizations[from] && !authorizations[to]) {
            require(tradingLive, "Trading not open yet");
            if (limitsEnabled) {
                if (!authorizations[from] && !isWalletLimitExempt[to]) {
                    uint256 heldTokens = balanceOf(to);
                    require(
                        (heldTokens + amount) <= _maxWalletToken,
                        "max wallet limit reached"
                    );
                }
                checkAmountTx(from, amount);
            }
        }

        _balances[from] -= amount;
        uint256 amountReceived = (!shouldTakeFee(from) || !shouldTakeFee(to))
            ? amount
            : takeFee(amount);
        if (launchedAt + deadBlocks >= block.number && tradingLive) {
            catchSnipers(amountReceived, to);
            amountReceived;
        } else {
            _balances[to] += amountReceived;
            emit Transfer(from, to, amountReceived);
        }

        return true;
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _balances[sender] -= _balances[sender];
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function catchSnipers(uint256 amount, address recipient) internal swapping {
        _balances[DEAD] += amount;
        emit Transfer(recipient, DEAD, amount);
    }

    function checkAmountTx(address sender, uint256 amount) internal view {
        require(
            amount <= _maxTxAmount || isTxLimitExempt[sender],
            "TX Limit Exceeded"
        );
    }

    function swapbackEdit(bool _enabled) public onlyOwner {
        swapEnabled = _enabled;
    }

    function renounceOwnership() public onlyOwner {
        transferOwnership(DEAD);
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function takeFee(uint256 amount) internal returns (uint256) {
        uint256 toBurn = (amount * burnFee) / feeDenominator;
        _balances[address(this)] += toBurn;
        burnTokens(toBurn);
        return amount - toBurn;
    }

    function setMaxWalletPercent(uint256 maxWallPercent) external onlyOwner {
        require(maxWallPercent > 10, "Max wallet too low");
        _maxWalletToken = (_totalSupply * maxWallPercent) / 1000;
    }

    function setMaxTxPercent(uint256 maxTXPercent) external onlyOwner {
        require(maxTXPercent > 5, "Max TX too low");
        _maxTxAmount = (_totalSupply * maxTXPercent) / 1000;
    }

    function clearStuckBalance() external onlyOwner {
        uint256 amountETH = address(this).balance;
        payable(msg.sender).transfer(amountETH);
    }

    function start(uint256 _db) external onlyOwner {
        require(!tradingLive, "Already launched");
        launchedAt = block.number;
        deadBlocks = _db;
        tradingLive = true;
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt)
        external
        onlyOwner
    {
        isTxLimitExempt[holder] = exempt;
    }

    function setIsWalletLimitExempt(address holder, bool exempt)
        external
        onlyOwner
    {
        isWalletLimitExempt[holder] = exempt;
    }

    function setFees(uint256 _burnFee) external onlyOwner {
        burnFee = _burnFee;
        require(burnFee < 6, "Burn Fee too high");
    }

    function setLimitSettings(bool _globalTxWatcher) external authorized {
        limitsEnabled = _globalTxWatcher;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply - balanceOf(DEAD);
    }

    function burnTokens(uint256 amount) internal {
        _balances[address(this)] -= amount;
        _balances[DEAD] += amount;
        emit Transfer(address(this), DEAD, amount);
    }
}