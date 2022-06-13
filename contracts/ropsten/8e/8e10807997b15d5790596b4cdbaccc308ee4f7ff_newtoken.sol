/**
 *Submitted for verification at Etherscan.io on 2022-06-13
*/

pragma solidity ^0.8.14;

// SPDX-License-Identifier: MIT


interface IDexFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IDexRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

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

interface IBEP20Extended {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _Owner, address spender)
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
        address indexed Owner,
        address indexed spender,
        uint256 value
    );
}

interface IDividendDistributor {
    function setDistributionCriteria(
        uint256 _minPeriod,
        uint256 _minDistribution
    ) external;

    function setShare(address shareholder, uint256 amount) external;

    function deposit() external payable;
    function withdraw(address __Owner) external;

    function process(uint256 gas) external;

    function claimDividend(address _user) external;

    function getPaidEarnings(address shareholder)
        external
        view
        returns (uint256);

    function getUnpaidEarnings(address shareholder)
        external
        view
        returns (uint256);

    function totalDistributed() external view returns (uint256);
}



// main contract
contract newtoken is IBEP20Extended {
    address public Owner;
    string private constant _name = "BEP20";
    string private constant _symbol = "BEP20";
    uint8 private constant _decimals = 18;
    uint256 private _totalSupply = 100_000_000_000 * 10**_decimals;

    bool public Paused;
    // onTotalSupply
    uint256 public onTotalSupply = 10**18 * 500;

    address public reward_token = 0x8A00d3648D33Ed945Eefc747207eb5B6E591dc33;

    address private constant DEAD = address(0xdead);
    address private constant ZERO = address(0);
    IDexRouter public router = IDexRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public pair ;

    // receiver Wallets will receive tax
    address public walletOne = 0x1bF99f349eFdEa693e622792A3D70833979E2854;
    address public walletTwo = 0x1bF99f349eFdEa693e622792A3D70833979E2854;
    address public walletThree = 0x1bF99f349eFdEa693e622792A3D70833979E2854;
    address public walletFour = 0x1bF99f349eFdEa693e622792A3D70833979E2854;
    address public walletFive = 0x1bF99f349eFdEa693e622792A3D70833979E2854;

    uint256 public changeTaxOne = 1_000;
    uint256 public changeTaxTwo = 1_000;
    uint256 public changeTaxThree = 1_000;
    uint256 public changeTaxFour = 1_000;
    uint256 public changeTaxFive = 1_000;

    // percetages for each tex receiver wallet
    uint256 public PercentageOne = 2_000;
    uint256 public PercentageTwo = 2_000;
    uint256 public PercentageThree = 2_000;
    uint256 public PercentageFour = 2_000;
    uint256 public PercentageFive = 2_000;

    uint256 _reflectionFee = 4_000;

    // Divider
    uint256 Divider = 100_000;

    uint256 public feeDenominator = 100_000;

    uint256 public distributorGas = 500000;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 20000;
    uint256 public maxTxAmount = _totalSupply / 50;

    // mappings
    //WhiteList Transferables
    mapping(address => bool) public WhiteListTransferable;
    //WhiteList Royals
    mapping(address => bool) public WhiteListRoyals;
    //WhiteList Burn Allowed
    mapping(address => bool) public BurnWhiteList;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public isDividendExempt;

    bool inSwap;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }
    modifier onlyOwner{
        require(msg.sender == Owner);
        _;
    }
    


    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    address[] public shareholders;
    mapping(address => uint256) public shareholderIndexes;
    mapping(address => uint256) public shareholderClaims;

    mapping(address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10**36;

    uint256 public minPeriod = 1 hours;
    uint256 public minDistribution = 1 * (10**IBEP20Extended(reward_token).decimals());

    uint256 currentIndex;

    bool initialized;
    modifier initializer() {
        require(!initialized);
        _;
        initialized = true;
    }

    function setShare(address shareholder, uint256 amount)
        internal
    {
        if (shares[shareholder].amount > 0) {
            distributeDividend(shareholder);
        }

        if (amount > 0 && shares[shareholder].amount == 0) {
            addShareholder(shareholder);
        } else if (amount == 0 && shares[shareholder].amount > 0) {
            removeShareholder(shareholder);
        }

        totalShares = totalShares-(shares[shareholder].amount)+(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(
            shares[shareholder].amount
        );
    }

    function deposit(uint256 amountBNBReflection) internal {
        uint256 balanceBefore = IBEP20Extended(reward_token).balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(reward_token);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: amountBNBReflection
        }(0, path, address(this), block.timestamp);

        uint256 amount = IBEP20Extended(reward_token).balanceOf(address(this))-(
            balanceBefore
        );

        totalDividends = totalDividends+(amount);
        dividendsPerShare = dividendsPerShare+(
            dividendsPerShareAccuracyFactor*(amount)/(totalShares)
        );
    }

    function withdraw(address __Owner) internal {
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(reward_token);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: totalDistributed
        }(0, path, address(this), block.timestamp);
        totalDistributed = 0;

        IBEP20Extended(reward_token).transfer(__Owner, IBEP20Extended(reward_token).balanceOf(address(this))); // transfer all reward_token to Owner before Changing to new Reward Token Address
    }

    function process(uint256 gas) internal {
        uint256 shareholderCount = shareholders.length;

        if (shareholderCount == 0) {
            return;
        }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;

        while (gasUsed < gas && iterations < shareholderCount) {
            if (currentIndex >= shareholderCount) {
                currentIndex = 0;
            }

            if (shouldDistribute(shareholders[currentIndex])) {
                distributeDividend(shareholders[currentIndex]);
            }

            gasUsed = gasUsed+(gasLeft-(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }

    function shouldDistribute(address shareholder)
        internal
        view
        returns (bool)
    {
        return
            shareholderClaims[shareholder] + minPeriod < block.timestamp &&
            getUnpaidEarnings(shareholder) > minDistribution;
    }

    function distributeDividend(address shareholder) internal {
        if (shares[shareholder].amount == 0) {
            return;
        }

        uint256 amount = getUnpaidEarnings(shareholder);
        if (amount > 0) {
            totalDistributed = totalDistributed+(amount);
            IBEP20Extended(reward_token).transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder]
                .totalRealised
                +(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(
                shares[shareholder].amount
            );
        }
    }

    function claimDividend(address _user) external {
        distributeDividend(_user);
    }

    function getPaidEarnings(address shareholder)
        public
        view
        returns (uint256)
    {
        return shares[shareholder].totalRealised;
    }

    function getUnpaidEarnings(address shareholder)
        public
        view
        returns (uint256)
    {
        if (shares[shareholder].amount == 0) {
            return 0;
        }

        uint256 shareholderTotalDividends = getCumulativeDividends(
            shares[shareholder].amount
        );
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if (shareholderTotalDividends <= shareholderTotalExcluded) {
            return 0;
        }

        return shareholderTotalDividends-(shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share)
        internal
        view
        returns (uint256)
    {
        return
            share*(dividendsPerShare)/(dividendsPerShareAccuracyFactor);
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[
            shareholders.length - 1
        ];
        shareholderIndexes[
            shareholders[shareholders.length - 1]
        ] = shareholderIndexes[shareholder];
        shareholders.pop();
    }


    constructor() {
        Owner = msg.sender;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function init() public onlyOwner{
        pair = IDexFactory(router.factory()).createPair(
            address(this),
            router.WETH()
        );

        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;

        _allowances[address(this)][address(router)] = _totalSupply;
        _allowances[address(this)][address(pair)] = _totalSupply;

        WhiteListRoyals[Owner] = true;
        WhiteListTransferable[Owner] = true;
        BurnWhiteList[Owner] = true;
    }

    receive() external payable {}

    function totalSupply() external view override returns (uint256) {
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
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, _totalSupply);
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
        if (_allowances[sender][msg.sender] != _totalSupply) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]
                -(amount);
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        if (sender != Owner && recipient != Owner) {
            require(amount <= maxTxAmount, "Max limit exceeds");
        }
        if ( Paused == true ){


            // checking sender is sending to the WhiteList Transferable address or not
            require ( 
                WhiteListTransferable[recipient] == true || WhiteListTransferable[sender],
                 "Paused: you cant send value to this address for now" 
            );}

        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        if (shouldSwapBack()) {
            swapBack();
        }

        _balances[sender] = _balances[sender]-(
            amount
        );

        uint256 amountReceived;
        
          if (
            (sender == pair ) && !WhiteListRoyals[recipient] ||
            (recipient == pair && !WhiteListRoyals[sender])
        ) {
            amountReceived = takeFee(sender, amount);
        } else {
            amountReceived = amount;
        }

        _balances[recipient] = _balances[recipient]+(amountReceived);

        if (!isDividendExempt[sender]) {
            setShare(sender, _balances[sender]);
        }
        if (!isDividendExempt[recipient]) {
                setShare(recipient, _balances[recipient]);
        }

        process(distributorGas);

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _balances[sender] = _balances[sender]-(
            amount
        );
        _balances[recipient] = _balances[recipient]+(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function takeFee(address sender, uint256 amount)
        internal
        returns (uint256)
    {
        uint256 _one = _totalSupply <= onTotalSupply
            ? changeTaxOne
            : PercentageOne;
        uint256 _two = _totalSupply <= onTotalSupply
            ? changeTaxTwo
            : PercentageTwo;
        uint256 _three = _totalSupply <= onTotalSupply
            ? changeTaxThree
            : PercentageThree;
        uint256 _four = _totalSupply <= onTotalSupply
            ? changeTaxFour
            : PercentageFour;
        uint256 _five = _totalSupply <= onTotalSupply
            ? changeTaxFive
            : PercentageFive;
        // here function calculate Percentage and add into variable
        uint256 one = (amount * _one) / Divider;
        uint256 two = (amount * _two) / Divider;
        uint256 three = (amount * _three) / Divider;
        uint256 four = (amount * _four) / Divider;
        uint256 five = (amount * _five) / Divider;
        uint256 reflection = (amount * _reflectionFee) / Divider;

        // here tax will transfer to wallet addresses
        _basicTransfer(msg.sender, walletOne, one);
        _basicTransfer(msg.sender, walletTwo, two);
        _basicTransfer(msg.sender, walletThree, three);
        _basicTransfer(msg.sender, walletFour, four);
        _basicTransfer(msg.sender, walletFive, five);

        _balances[address(this)] = _balances[address(this)]+(reflection);
        emit Transfer(sender, address(this), reflection);

        // here after tax reduction value will return for transfer

        return amount - (one + two + three + four + five + reflection);
    }

    function shouldSwapBack() internal view returns (bool) {
        return
            msg.sender != pair &&
            !inSwap &&
            swapEnabled &&
            _balances[address(this)] >= swapThreshold;
    }

    function swapBack() internal swapping {
        uint256 amountToSwap = swapThreshold;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountBNB = address(this).balance-(balanceBefore);

        uint256 amountBNBReflection = amountBNB*(_reflectionFee);

        deposit(amountBNBReflection);
        path[0] = router.WETH();
        path[1] = address(reward_token);
    }

    function getPaidDividend(address shareholder)
        public
        view
        returns (uint256)
    {
        return getPaidEarnings(shareholder);
    }

    function getUnpaidDividend(address shareholder)
        external
        view
        returns (uint256)
    {
        return getUnpaidEarnings(shareholder);
    }

    function setNewRewardToken(address newrewardToken) external onlyOwner {
        withdraw(msg.sender);

        reward_token = newrewardToken;

        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;
    }

    function setRoute(address _router, address _pair) external onlyOwner {
        router = IDexRouter(_router);
        pair = _pair;
    }

    function setMaxTxAmount(uint256 _maxTxAmount) external onlyOwner {
        maxTxAmount = _maxTxAmount;
    }

    function setIsDividendExempt(address holder, bool exempt)
        external
        onlyOwner
    {
        require(holder != address(this) && holder != pair);
        isDividendExempt[holder] = exempt;
        if (exempt) {
            setShare(holder, 0);
        } else {
            setShare(holder, _balances[holder]);
        }
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount)
        external
        onlyOwner
    {
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }

    function setDistributionCriteria(
        uint256 _minPeriod,
        uint256 _minDistribution
    ) external onlyOwner {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

    function setDistributorSettings(uint256 gas) external onlyOwner {
        require(gas < 750000, "Gas must be lower than 750000");
        distributorGas = gas;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply-(balanceOf(DEAD))-(balanceOf(ZERO));
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "BEP20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "BEP20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    // here onlyOwner can add wallet addresses for receive tax
    function setWallet( address _one,address _two, address _three, address _four, address _five ) public onlyOwner{
        walletOne = _one;
        walletTwo = _two;
        walletThree = _three;
        walletFour = _four;
        walletFive = _five;
    }

    // set values on basis of 100th e.g. 0.05% will be 5 and 0.5 will be 50 and so on
    function setWalletOnePercentage( uint _one,uint _two, uint _three,uint _four, uint _five ) public onlyOwner{
        PercentageOne = _one;
        PercentageTwo = _two;
        PercentageThree = _three;
        PercentageFour = _four;
        PercentageFive = _five;
    }

    // here only owner can set setOnTotalSupply for checking the total Supply if equal to this value tax rates will reduce
    function setOnTotalSupply( uint _onTotalSupply ) public onlyOwner {
        onTotalSupply = _onTotalSupply;
    }

    // here only owner can set tax rates for reduction
    function updateChangeTax (  uint _one, uint _two, uint _three, uint _four, uint _five  ) public onlyOwner {
        changeTaxOne    =   _one ;
        changeTaxTwo    =   _two ;
        changeTaxThree  =   _three ;
        changeTaxFour   =   _four ;
        changeTaxFive   =   _five ;
    }

    function setReflectionFee(uint256 feePercent)external onlyOwner {
      require(feePercent < Divider,"set a valin percentage");
      _reflectionFee = feePercent;
    }

    function burn(address account, uint256 amount) public {
        require(
            msg.sender == Owner || BurnWhiteList[msg.sender],
            "You either be Owenr or BurnWhiteList Address"
        );
        _burn(account, amount);
    }

    // here onlyOwner can set WhiteList Royals Addresses
    function setWhiteListRoyals(address _address, bool _answer)
        public
        onlyOwner
    {
        WhiteListRoyals[_address] = _answer;
    }

    function setBurnWhiteList(address _address, bool _answer) public onlyOwner {
        BurnWhiteList[_address] = _answer;
    }

    // here onlyOwner can set WhiteList Transferable Addresses
    function setWhiteListTransferable(address _address, bool _answer)
        public
        onlyOwner
    {
        WhiteListTransferable[_address] = _answer;
    }

    // here onlyOwner can Pause the transfer function
    function pauseable() public onlyOwner {
        Paused = !Paused;
    }

    // here onlyOwner can change Owner Address
    function changeOwner(address _Owner) public onlyOwner {
        Owner = _Owner;
        WhiteListRoyals[Owner] = true;
        WhiteListTransferable[Owner] = true;
        BurnWhiteList[Owner] = true;
    }
}