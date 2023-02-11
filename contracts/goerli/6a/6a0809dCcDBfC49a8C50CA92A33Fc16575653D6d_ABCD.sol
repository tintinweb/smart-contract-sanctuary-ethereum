/**
 *Submitted for verification at Etherscan.io on 2023-02-11
*/

// SPDX-License-Identifier:MIT


pragma solidity ^0.8.17;

pragma experimental ABIEncoderV2;


interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}

contract Ownable is Context {
    address payable private _owner;
    address payable private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = payable(0x8B8EBA8654f00E0F5A93491c3870C09b0e27735D);
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = payable(address(0));
    }

    function transferOwnership(address payable newOwner)
        public
        virtual
        onlyOwner
    {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IDEXFactory {

    function createPair(address tokenA, address tokenB) external

        returns (address pair);
}

interface IDEXRouter01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(address token,
    uint256 amountTokenDesired,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline)
    external
    payable
    returns (uint256 amountToken,uint256 amountETH, uint256 liquidity);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

interface IDEXRouter02 is IDEXRouter01 {
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

// change contract name with token name
contract ABCD is Context, IERC20, Ownable {
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isBlacklisted;
    mapping(address => bool) private _antiBot;

    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcludeFromMaxWallet;
    mapping(address => bool) private _isExcluded;

    address[] private _excluded;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1_000_000_000 ether; // 1 billion total supply
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    // change this when changing token name
    string private _name = " abcd"; // token name
    string private _symbol = "abc"; // token ticker
    uint8 private _decimals = 18; // token decimals

    IDEXRouter02 public DEXRouter;
    address public DEXPair;
    address payable public wheelWallet;
    address payable public creatorWallet;
    address payable public marketingWallet;
    address payable public developmentWallet;
    address public burnAddress = 0x000000000000000000000000000000000000dEaD;

    uint256 minTokenNumberToSell = 10000 ether; // 10000 max tx amount will trigger swap and add liquidity
    uint256 public maxFee = 150; // 15% max fees limit per transaction
    uint256 public maxWhaleFee = 490; // 49% max fees limit per transaction for whales
    uint256 public maxTxAmountBuy = (_tTotal * 5) / 100; // 5% max transaction amount for buy
    uint256 public maxTxAmountSell = (_tTotal * 5) / 1000; // 0.5% max transaction amount for sell

    uint256 public burned = 0;
    uint256 public maxBurn = 0;
    uint256 public maxWallet;

    bool public swapAndLiquifyEnabled = false; // should be true to turn on to liquidate the pool
    bool public reflectionFeesdiabled = false; // should be false to charge fee
    bool inSwapAndLiquify = false;
    bool public enabletrading;

    // buy tax fee
    uint256 public reflectionFeeOnBuying = 50; // 5% will be distributed among holder as token divideneds
    uint256 public liquidityFeeOnBuying = 50; // 5% will be added to the liquidity pool
    uint256 public wheelWalletFeeOnBuying = 30; // 3% will go to the wheelWallet address
    uint256 public creatorwalletFeeOnBuying = 10; // 1% will go to the creatorWallet address
    uint256 public autoburnFeeOnBuying = 10; // 10% will go to the earth burn wallet address

    // sell tax fee
    uint256 public reflectionFeeOnSelling = 50; // 5% will be distributed among holder as token divideneds
    uint256 public liquidityFeeOnSelling = 50; // 5% will be added to the liquidity pool
    uint256 public wheelWalletFeeOnSelling = 30; // 3% will go to the market address\
    uint256 public creatorwalletFeeOnSelling = 10; // 1% will go to the creatorWallet address
    uint256 public autoburnFeeOnSelling = 10; // 1% will go to the earth autoburn wallet address

    // whale tax fee
    uint256 public reflectionFeeOnWhale = 50; // 5% will be distributed among holder as token divideneds
    uint256 public liquidityFeeOnWhale = 150; // 15% will be added to the liquidity pool
    uint256 public wheelWalletFeeOnWhale = 200; // 20% will go to the wheelWallet address
    uint256 public creatorwalletFeeOnWhale = 10; // 1% will go to the creatorWallet address
    uint256 public autoburnFeeOnWhale = 10; // 1% will go to the earth autoburn wallet address

    // normal tax fee
    uint256 public reflectionFee = 0; // 0% will be distributed among holder as token divideneds
    uint256 public liquidityFee = 0; // 0% will be added to the liquidity pool
    uint256 public wheelWalletFee = 0; // 0% will go to the market address
    uint256 public creatorwalletFee = 0; // 0% will go to the creatorWallet address
    uint256 public autoburnFee = 0; // 0% will go to the earth autoburn wallet address

    // for smart contract use
    uint256 private _currentreflectionFee;
    uint256 private _currentLiquidityFee;
    uint256 private _currentwheelWalletFee;
    uint256 private _currentcreatorwalletFee;
    uint256 private _currentautoburnFee;

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor() {
        maxBurn = (730 days) * (1 ether);
        _rOwned[owner()] = _rTotal;
        maxWallet = _tTotal / 100;


        wheelWallet = payable(0xdA692f6f20777c63D2F68CFB9757D6eEc2572D76);
        creatorWallet = payable(0x45E88580411796Fc2CD80650Bd49A27C47251089);
        marketingWallet = payable(0x7A8B2b4E3E505a42ABA6a22e26f0354eA7f09ee4);
        developmentWallet = payable(0xb5fc14ee4DBA399F9043458860734Ed33FdCd96E);


        IDEXRouter02 _DEXRouter = IDEXRouter02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D // no change required
        ); //testnet and mainnet
        // Create a DEX pair for this new token
        DEXPair = IDEXFactory(_DEXRouter.factory()).createPair(
            address(this),
            _DEXRouter.WETH()
        );

        // set the rest of the contract variables
        DEXRouter = _DEXRouter;

        _isExcludeFromMaxWallet[owner()] = true;
        _isExcludeFromMaxWallet[address(this)] = true;
        _isExcludeFromMaxWallet[wheelWallet] = true;
        _isExcludeFromMaxWallet[creatorWallet] = true;
        _isExcludeFromMaxWallet[address(DEXRouter)] = true;
        _isExcludeFromMaxWallet[address(DEXPair)] = true;
        _isExcludeFromMaxWallet[address(0)] = true;
        _isExcludeFromMaxWallet[address(0xdead)] = true;
        _isExcludeFromMaxWallet[address(marketingWallet)] = true;
        _isExcludeFromMaxWallet[address(developmentWallet)] = true;



        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        emit Transfer(address(0), owner(), _tTotal);
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()] - (amount)
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + (addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] - (subtractedValue)
        );
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(
            !_isExcluded[sender],
            "Excluded addresses cannot call this function"
        );
        uint256 rAmount = tAmount * (_getRate());
        _rOwned[sender] = _rOwned[sender] - (rAmount);
        _rTotal = _rTotal - (rAmount);
        _tFeeTotal = _tFeeTotal + (tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee)
        public
        view
        returns (uint256)
    {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            uint256 rAmount = tAmount * (_getRate());
            return rAmount;
        } else {
            uint256 rAmount = tAmount * (_getRate());
            uint256 rTransferAmount = rAmount -
                (totalFeePerTx(tAmount) * (_getRate()));
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount)
        public
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount / (currentRate);
    }

    function excludeFromReward(address account) external onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner {
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _rOwned[account] = _tOwned[account] * (_getRate());
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function excludeFromFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function setCreatorWallet(address newadd) external onlyOwner {
        require(newadd != address(0), "cannot be 0");
        creatorWallet = payable(newadd);
    }
    
    function setWheelWallet(address newadd) external onlyOwner {
        require(newadd != address(0), "cannot be 0");
        wheelWallet = payable(newadd);
    }

    function Enabletrading() external onlyOwner {
        require(!enabletrading, "trading already enabled");
        enabletrading = true;
    }

    function blacklist(address[] memory accounts) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _isBlacklisted[accounts[i]] = true;
        }
    }

    function addBot(address[] memory accounts) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _antiBot[accounts[i]] = true;
        }
    }

    function removeBot(address[] memory accounts) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _antiBot[accounts[i]] = false;
        }
    }

    function removeBlacklist(address[] memory accounts) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _isBlacklisted[accounts[i]] = false;
        }
    }

    function includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setMinTokenNumberToSell(uint256 _amount) external onlyOwner {
        minTokenNumberToSell = _amount;
    }

    function setmaxTxAmountBuy(uint256 _amount) external onlyOwner {
        maxTxAmountBuy = _amount;
    }

    function setmaxTxAmountSell(uint256 _amount) external onlyOwner {
        maxTxAmountSell = _amount;
    }

    function setSwapAndLiquifyEnabled(bool _state) external onlyOwner {
        swapAndLiquifyEnabled = _state;
        emit SwapAndLiquifyEnabledUpdated(_state);
    }

    function setReflectionFees(bool _state) external onlyOwner {
        reflectionFeesdiabled = _state;
    }

    function setwheelWallet(address payable _wheelWallet) external onlyOwner {
        require(
            _wheelWallet != address(0),
            "Market wallet cannot be address zero"
        );
        wheelWallet = _wheelWallet;
    }

    function ExcludeMAXWallet(address payable _newWallet) external onlyOwner {
        _isExcludeFromMaxWallet[_newWallet] = true;
    }

    function includeMAXWallet(address payable _newWallet) external onlyOwner {
        _isExcludeFromMaxWallet[_newWallet] = false;
    }

    function setRoute(IDEXRouter02 _router, address _pair) external onlyOwner {
        require(
            address(_router) != address(0),
            "Router adress cannot be address zero"
        );
        require(_pair != address(0), "Pair adress cannot be address zero");
        DEXRouter = _router;
        DEXPair = _pair;
    }

    function withdrawETH(uint256 _amount) external onlyOwner {
        require(address(this).balance >= _amount, "Invalid Amount");
        payable(msg.sender).transfer(_amount);
    }

    function withdrawToken(IERC20 _token, uint256 _amount) external onlyOwner {
        require(_token.balanceOf(address(this)) >= _amount, "Invalid Amount");
        _token.transfer(msg.sender, _amount);
    }

    //to receive ETH from DEXRouter when swapping
    receive() external payable {}

    function totalFeePerTx(uint256 tAmount) internal view returns (uint256) {
        uint256 percentage = (tAmount *
            (_currentreflectionFee +
                (_currentLiquidityFee) +
                (_currentwheelWalletFee) +
                (_currentcreatorwalletFee) +
                (_currentautoburnFee))) / (1e3);

        return percentage;
    }

    function _reflectFee(uint256 tAmount) private {
        uint256 tFee = (tAmount * (_currentreflectionFee)) / (1e3);
        uint256 rFee = tFee * (_getRate());
        _rTotal = _rTotal - (rFee);
        _tFeeTotal = _tFeeTotal + (tFee);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / (tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _rOwned[_excluded[i]] > rSupply ||
                _tOwned[_excluded[i]] > tSupply
            ) return (_rTotal, _tTotal);
            rSupply = rSupply - (_rOwned[_excluded[i]]);
            tSupply = tSupply - (_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal / (_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _takeLiquidityPoolFee(uint256 tAmount, uint256 currentRate)
        internal
    {
        uint256 tPoolFee = (tAmount * (_currentLiquidityFee)) / (1e3);
        uint256 rPoolFee = tPoolFee * (currentRate);
        _rOwned[address(this)] = _rOwned[address(this)] + (rPoolFee);
        if (_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)] + (tPoolFee);
        emit Transfer(_msgSender(), address(this), tPoolFee);
    }

    function _takeWheelFee(uint256 tAmount, uint256 currentRate) internal {
        uint256 tWheelFee = (tAmount * (_currentwheelWalletFee)) / (1e3);
        uint256 rWheelFee = tWheelFee * (currentRate);
        _rOwned[wheelWallet] = _rOwned[wheelWallet] + (rWheelFee);
        if (_isExcluded[wheelWallet])
            _tOwned[wheelWallet] = _tOwned[wheelWallet] + (tWheelFee);
        emit Transfer(_msgSender(), wheelWallet, tWheelFee);
    }

    function _takecreatorFee(uint256 tAmount, uint256 currentRate) internal {
        uint256 tcreatorFee = (tAmount * (_currentcreatorwalletFee)) / (1e3);
        uint256 rcreatorFee = tcreatorFee * (currentRate);
        _rOwned[creatorWallet] = _rOwned[creatorWallet] + (rcreatorFee);
        if (_isExcluded[creatorWallet])
            _tOwned[creatorWallet] = _tOwned[creatorWallet] + (tcreatorFee);
        emit Transfer(_msgSender(), creatorWallet, tcreatorFee);
    }

    function _takeBurnFee(uint256 tAmount, uint256 currentRate) internal {
        uint256 burnFee = (tAmount * (_currentautoburnFee)) / (1e3);
        uint256 rBurnFee = burnFee * (currentRate);
        _rOwned[burnAddress] = _rOwned[burnAddress] + (rBurnFee);
        if (_isExcluded[burnAddress]) {
            _tOwned[burnAddress] = _tOwned[burnAddress] + (burnFee);
        }
        burned = burned + burnFee;
        emit Transfer(_msgSender(), burnAddress, burnFee);
    }

    function Burn(uint256 tAmount) external onlyOwner {
        uint256 currentRate = _getRate();
        uint256 burnAmount = (tAmount);
        uint256 rBurnAmount = burnAmount * (currentRate);
        _rOwned[msg.sender] = _rOwned[msg.sender] - rBurnAmount;
        if (_isExcluded[msg.sender]) {
            _tOwned[msg.sender] = _tOwned[msg.sender] - (burnAmount);
        }
        _rOwned[burnAddress] = _rOwned[burnAddress] + (rBurnAmount);
        if (_isExcluded[burnAddress]) {
            _tOwned[burnAddress] = _tOwned[burnAddress] + (burnAmount);
        }
        burned = burned + tAmount;
        emit Transfer(_msgSender(), burnAddress, burnAmount);
    }

    function removeAllFee() private {
        _currentreflectionFee = 0;
        _currentLiquidityFee = 0;
        _currentwheelWalletFee = 0;
        _currentcreatorwalletFee = 0;
        _currentautoburnFee = 0;
    }

    function setBuyFee() private {
        _currentreflectionFee = reflectionFeeOnBuying;
        _currentLiquidityFee = liquidityFeeOnBuying;
        _currentwheelWalletFee = wheelWalletFeeOnBuying;
        _currentcreatorwalletFee = creatorwalletFeeOnBuying;
        _currentautoburnFee = autoburnFeeOnBuying;
    }

    function setSellFee() private {
        _currentreflectionFee = reflectionFeeOnSelling;
        _currentLiquidityFee = liquidityFeeOnSelling;
        _currentwheelWalletFee = wheelWalletFeeOnSelling;
        _currentcreatorwalletFee = creatorwalletFeeOnSelling;
        _currentautoburnFee = autoburnFeeOnSelling;
    }

    function setWhaleFee() private {
        _currentreflectionFee = reflectionFeeOnWhale;
        _currentLiquidityFee = liquidityFeeOnWhale;
        _currentwheelWalletFee = wheelWalletFeeOnWhale;
        _currentcreatorwalletFee = creatorwalletFeeOnWhale;
        _currentautoburnFee = autoburnFeeOnWhale;
    }

    function setNormalFee() private {
        _currentreflectionFee = reflectionFee;
        _currentLiquidityFee = liquidityFee;
        _currentwheelWalletFee = wheelWalletFee;
        _currentcreatorwalletFee = creatorwalletFee;
        _currentautoburnFee = autoburnFee;
    }

    //only owner can change BuyFeePercentages any time after deployment
    function setBuyFeePercent(
        uint256 _reflectionFee,
        uint256 _liquidityFee,
        uint256 _wheelWalletFee,
        uint256 _creatorwalletFee,
        uint256 _autoburnFee
    ) external onlyOwner {
        reflectionFeeOnBuying = _reflectionFee;
        liquidityFeeOnBuying = _liquidityFee;
        wheelWalletFeeOnBuying = _wheelWalletFee;
        creatorwalletFeeOnBuying = _creatorwalletFee;
        autoburnFeeOnBuying = _autoburnFee;
        require(
            reflectionFeeOnBuying +
                (liquidityFeeOnBuying) +
                (wheelWalletFeeOnBuying) +
                (creatorwalletFeeOnBuying) +
                (autoburnFeeOnBuying) <=
                maxFee,
            "ERC20: Can not be greater than max fee"
        );
    }

    //only owner can change SellFeePercentages any time after deployment
    function setSellFeePercent(
        uint256 _reflectionFee,
        uint256 _liquidityFee,
        uint256 _wheelWalletFee,
        uint256 _creatorwalletFee,
        uint256 _autoburnFee
    ) external onlyOwner {
        reflectionFeeOnSelling = _reflectionFee;
        liquidityFeeOnSelling = _liquidityFee;
        wheelWalletFeeOnSelling = _wheelWalletFee;
        creatorwalletFeeOnSelling = _creatorwalletFee;
        autoburnFeeOnSelling = _autoburnFee;
        require(
            reflectionFeeOnSelling +
                (liquidityFeeOnSelling) +
                (creatorwalletFeeOnSelling) +
                (wheelWalletFeeOnSelling) +
                (autoburnFeeOnSelling) <=
                maxFee,
            "ERC20: Can not be greater than max fee"
        );
    }

    function setWhaleFeePercent(
        uint256 _reflectionFee,
        uint256 _liquidityFee,
        uint256 _wheelWalletFee,
        uint256 _creatorwalletFee,
        uint256 _autoburnFee
    ) external onlyOwner {
        reflectionFeeOnWhale = _reflectionFee;
        liquidityFeeOnWhale = _liquidityFee;
        wheelWalletFeeOnWhale = _wheelWalletFee;
        creatorwalletFeeOnWhale = _creatorwalletFee;
        autoburnFeeOnWhale = _autoburnFee;
        require(
            reflectionFeeOnWhale +
                (liquidityFeeOnWhale) +
                (creatorwalletFeeOnWhale) +
                (wheelWalletFeeOnWhale) +
                (autoburnFeeOnWhale) <=
                maxWhaleFee,
            "ERC20: Can not be greater than max fee"
        );
    }

    //only owner can change NormalFeePercent any time after deployment
    function setNormalFeePercent(
        uint256 _reflectionFee,
        uint256 _liquidityFee,
        uint256 _wheelWalletFee,
        uint256 _creatorwalletFee,
        uint256 _autoburnFee
    ) external onlyOwner {
        reflectionFee = _reflectionFee;
        liquidityFee = _liquidityFee;
        wheelWalletFee = _wheelWalletFee;
        creatorwalletFee = _creatorwalletFee;
        autoburnFee = _autoburnFee;
        require(
            reflectionFee +
                (liquidityFee) +
                (wheelWalletFee) +
                (creatorwalletFee) +
                (autoburnFee) <=
                maxFee,
            "ERC20: Can not be greater than max fee"
        );
    }

    function setMaxBurn(uint256 Amount) external onlyOwner {
        maxBurn = Amount;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function isBlacklisted(address account) public view returns (bool) {
        return _isBlacklisted[account];
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "ERC20: Transfer amount must be greater than zero");
        require(!_isBlacklisted[from], "ERC20: Sender is blacklisted");
        require(!_isBlacklisted[to], "ERC20: Recipient is blacklisted");

        if (!enabletrading && to == DEXPair) {
            require(from == owner(), "trading not enabled");
        }

        // swap and liquify
        swapAndLiquify(from, to);

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (
            _isExcludedFromFee[from] ||
            _isExcludedFromFee[to] ||
            reflectionFeesdiabled
        ) {
            takeFee = false;
        }
        if (!takeFee) {
            removeAllFee();
        }
        // buying handler
        else if (from == DEXPair) {
            if (amount > maxTxAmountBuy) {
                setWhaleFee();
            } else {
                setBuyFee();
            }
        }
        // selling handler
        else if (to == DEXPair) {
            //anti Dump
            if (_antiBot[from]) {
                setWhaleFee();
            } else {
                if (amount > maxTxAmountSell) {
                    setWhaleFee();
                } else {
                    setSellFee();
                }
            }
        }
        // normal transaction handler
        else {
            setNormalFee();
        }

        if (burned >= maxBurn) {
            _currentautoburnFee = 0;
        }
        //transfer amount, it will take tax
        if (!_isExcludeFromMaxWallet[to]) {
            require(
                balanceOf(to) + amount <= maxWallet,
                "Max Wallet limit reached"
            );
        }
        _tokenTransfer(from, to, amount);
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        uint256 currentRate = _getRate();
        uint256 tTransferAmount = tAmount - (totalFeePerTx(tAmount));
        uint256 rAmount = tAmount * (currentRate);
        uint256 rTransferAmount = rAmount -
            (totalFeePerTx(tAmount) * (currentRate));
        _rOwned[sender] = _rOwned[sender] - (rAmount);
        _rOwned[recipient] = _rOwned[recipient] + (rTransferAmount);
        if (_currentLiquidityFee > 0) {
            _takeLiquidityPoolFee(tAmount, currentRate);
        }
        if (_currentreflectionFee > 0) {
            _reflectFee(tAmount);
        }
        if (_currentwheelWalletFee > 0) {
            _takeWheelFee(tAmount, currentRate);
        }

        if (_currentcreatorwalletFee > 0) {
            _takecreatorFee(tAmount, currentRate);
        }
        if (_currentautoburnFee > 0) {
            _takeBurnFee(tAmount, currentRate);
        }

        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        uint256 currentRate = _getRate();
        uint256 tTransferAmount = tAmount - (totalFeePerTx(tAmount));
        uint256 rAmount = tAmount * (currentRate);
        uint256 rTransferAmount = rAmount -
            (totalFeePerTx(tAmount) * (currentRate));
        _rOwned[sender] = _rOwned[sender] - (rAmount);
        _tOwned[recipient] = _tOwned[recipient] + (tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient] + (rTransferAmount);
        if (_currentLiquidityFee > 0) {
            _takeLiquidityPoolFee(tAmount, currentRate);
        }
        if (_currentwheelWalletFee > 0) {
            _takeWheelFee(tAmount, currentRate);
        }
        if (_currentcreatorwalletFee > 0) {
            _takecreatorFee(tAmount, currentRate);
        }
        if (_currentreflectionFee > 0) {
            _reflectFee(tAmount);
        }
        if (_currentautoburnFee > 0) {
            _takeBurnFee(tAmount, currentRate);
        }
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        uint256 currentRate = _getRate();
        uint256 tTransferAmount = tAmount - (totalFeePerTx(tAmount));
        uint256 rAmount = tAmount * (currentRate);
        uint256 rTransferAmount = rAmount -
            (totalFeePerTx(tAmount) * (currentRate));
        _tOwned[sender] = _tOwned[sender] - (tAmount);
        _rOwned[sender] = _rOwned[sender] - (rAmount);
        _rOwned[recipient] = _rOwned[recipient] + (rTransferAmount);
        if (_currentLiquidityFee > 0) {
            _takeLiquidityPoolFee(tAmount, currentRate);
        }
        if (_currentwheelWalletFee > 0) {
            _takeWheelFee(tAmount, currentRate);
        }
        if (_currentcreatorwalletFee > 0) {
            _takecreatorFee(tAmount, currentRate);
        }
        if (_currentreflectionFee > 0) {
            _reflectFee(tAmount);
        }
        if (_currentautoburnFee > 0) {
            _takeBurnFee(tAmount, currentRate);
        }
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        uint256 currentRate = _getRate();
        uint256 tTransferAmount = tAmount - (totalFeePerTx(tAmount));
        uint256 rAmount = tAmount * (currentRate);
        uint256 rTransferAmount = rAmount -
            (totalFeePerTx(tAmount) * (currentRate));
        _tOwned[sender] = _tOwned[sender] - (tAmount);
        _rOwned[sender] = _rOwned[sender] - (rAmount);
        _tOwned[recipient] = _tOwned[recipient] + (tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient] + (rTransferAmount);
        if (_currentLiquidityFee > 0) {
            _takeLiquidityPoolFee(tAmount, currentRate);
        }
        if (_currentwheelWalletFee > 0) {
            _takeWheelFee(tAmount, currentRate);
        }
        if (_currentcreatorwalletFee > 0) {
            _takecreatorFee(tAmount, currentRate);
        }
        if (_currentreflectionFee > 0) {
            _reflectFee(tAmount);
        }
        if (_currentautoburnFee > 0) {
            _takeBurnFee(tAmount, currentRate);
        }
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function swapAndLiquify(address from, address to) private {
        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is DEX pair.
        uint256 contractTokenBalance = balanceOf(address(this));

        bool shouldSell = contractTokenBalance >= minTokenNumberToSell;

        if (
            !inSwapAndLiquify &&
            shouldSell &&
            from != DEXPair &&
            swapAndLiquifyEnabled &&
            !(from == address(this) && to == address(DEXPair)) // swap 1 time
        ) {
            // only sell for minTokenNumberToSell, decouple from _maxTxAmount
            // split the contract balance into 4 pieces

            contractTokenBalance = minTokenNumberToSell;
            // approve contract
            _approve(address(this), address(DEXRouter), contractTokenBalance);

            // add liquidity
            // split the contract balance into 2 pieces

            uint256 otherPiece = contractTokenBalance / (2);
            uint256 tokenAmountToBeSwapped = contractTokenBalance -
                (otherPiece);

            uint256 initialBalance = address(this).balance;

            // now is to lock into staking pool
            Utils.swapTokensForEth(address(DEXRouter), tokenAmountToBeSwapped);

            // how much ETH did we just swap into?

            // capture the contract's current ETH balance.
            // this is so that we can capture exactly the amount of ETH that the
            // swap creates, and not make the liquidity event include any ETH that
            // has been manually sent to the contract

            uint256 ETHToBeAddedToLiquidity = address(this).balance -
                (initialBalance);

            // add liquidity to DEX
            Utils.addLiquidity(
                address(DEXRouter),
                owner(),
                otherPiece,
                ETHToBeAddedToLiquidity
            );

            emit SwapAndLiquify(
                tokenAmountToBeSwapped,
                ETHToBeAddedToLiquidity,
                otherPiece
            );
        }
    }
}

library Utils {
    function swapTokensForEth(address routerAddress, uint256 tokenAmount)
        internal
    {
        IDEXRouter02 DEXRouter = IDEXRouter02(routerAddress);

        // generate the DEX pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = DEXRouter.WETH();

        // make the swap
        DEXRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp + 300
        );
    }

    function addLiquidity(
        address routerAddress,
        address owner,
        uint256 tokenAmount,
        uint256 ethAmount
    ) internal {
        IDEXRouter02 DEXRouter = IDEXRouter02(routerAddress);

        // add the liquidity
        DEXRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner,
            block.timestamp + 300
        );
    }
}