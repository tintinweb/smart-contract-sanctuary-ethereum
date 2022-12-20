/**
 *Submitted for verification at Etherscan.io on 2022-12-20
*/

// SPDX-License-Identifier: MIT

/*

 ██████╗ █████╗ ███████╗██╗  ██╗███████╗██╗      ██████╗ ██╗    ██╗    
██╔════╝██╔══██╗██╔════╝██║  ██║██╔════╝██║     ██╔═══██╗██║    ██║    
██║     ███████║███████╗███████║█████╗  ██║     ██║   ██║██║ █╗ ██║    
██║     ██╔══██║╚════██║██╔══██║██╔══╝  ██║     ██║   ██║██║███╗██║    
╚██████╗██║  ██║███████║██║  ██║██║     ███████╗╚██████╔╝╚███╔███╔╝    
 ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝     ╚══════╝ ╚═════╝  ╚══╝╚══╝     
                                                                       
███╗   ███╗ ██████╗ ███╗   ██╗███████╗██╗   ██╗                        
████╗ ████║██╔═══██╗████╗  ██║██╔════╝╚██╗ ██╔╝                        
██╔████╔██║██║   ██║██╔██╗ ██║█████╗   ╚████╔╝                         
██║╚██╔╝██║██║   ██║██║╚██╗██║██╔══╝    ╚██╔╝                          
██║ ╚═╝ ██║╚██████╔╝██║ ╚████║███████╗   ██║                           
╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝   ╚═╝                           
                                                                       
██╗███╗   ██╗██╗   ██╗                                                 
██║████╗  ██║██║   ██║                                                 
██║██╔██╗ ██║██║   ██║                                                 
██║██║╚██╗██║██║   ██║                                                 
██║██║ ╚████║╚██████╔╝                                                 
╚═╝╚═╝  ╚═══╝ ╚═════╝                                                  
                                                                                                                                           
*/

pragma solidity ^0.8.10;

// interface IPCSFactory   : Interface of PancakeSwap ROuter

interface IPCSFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

// interface IPCSRouter  : Interface of PancakeSwap ROuter

interface IPCSRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

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
            uint256 _liquedity
        );

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

// interface IBEP20 : IBEP20 BEP20 Token Interface which would be used in calling token contract
interface IBEP20 {
    function totalSupply() external view returns (uint256); //Total Supply of Token

    function decimals() external view returns (uint8); // Decimal of TOken

    function symbol() external view returns (string memory); // Symbol of Token

    function name() external view returns (string memory); // Name of Token

    function balanceOf(address account) external view returns (uint256); // Balance of TOken

    //Transfer token from one address to another

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    // Get allowance to the spacific users

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    // Give approval to spend token to another addresses

    function approve(address spender, uint256 amount) external returns (bool);

    // Transfer token from one address to another

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    //Trasfer Event
    event Transfer(address indexed from, address indexed to, uint256 value);

    //Approval Event
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// This contract helps to add Owners
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 
 */
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(msg.sender);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// Interface IRewardDistributor : Interface that is used by  Reward Distributor

interface IRewardDistributor {
    function setDistributionStandard(
        uint256 _minPeriod,
        uint256 _minDistribution
    ) external;

    function setShare(address shareholder, uint256 amount) external;

    function depositBNB() external payable;

    function process(uint256 gas) external;

    function claimReward(address _user) external;

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

// RewardDistributor : It distributes reward amoung holders

contract RewardDistributor is IRewardDistributor {
    address public _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    IBEP20 public BUSD = IBEP20(0xCEC4a43eBB02f9B80916F1c718338169d6d5C1F0);
    IPCSRouter public router;

    address[] public shareholders;
    mapping(address => uint256) public shareholderIndexes;
    mapping(address => uint256) public shareholderClaims;

    mapping(address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalRewards;
    uint256 public override totalDistributed;
    uint256 public rewardsPerShare;
    uint256 public rewardsPerShareAccuracyFactor = 10**36;

    uint256 public minPeriod = 1 minutes;
    uint256 public minDistribution = 1 * (10**BUSD.decimals());

    uint256 currentIndex;

    bool initialized;
    modifier initializer() {
        require(!initialized);
        _;
        initialized = true;
    }

    modifier onlyToken() {
        require(msg.sender == _token);
        _;
    }

    constructor(address _router) {
        _token = msg.sender;
        router = IPCSRouter(_router);
    }

    function setDistributionStandard(
        uint256 _minPeriod,
        uint256 _minDistribution
    ) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

    function setShare(address shareholder, uint256 amount)
        external
        override
        onlyToken
    {
        if (shares[shareholder].amount > 0) {
            distributeReward(shareholder);
        }

        if (amount > 0 && shares[shareholder].amount == 0) {
            addShareholder(shareholder);
        } else if (amount == 0 && shares[shareholder].amount > 0) {
            removeShareholder(shareholder);
        }

        totalShares = totalShares + (shares[shareholder].amount) + (amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeRewards(
            shares[shareholder].amount
        );
    }

    function depositBNB() external payable override onlyToken {
        uint256 balanceBefore = BUSD.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(BUSD);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: msg.value
        }(0, path, address(this), block.timestamp);

        uint256 amount = BUSD.balanceOf(address(this)) - (balanceBefore);

        totalRewards = totalRewards + (amount);
        rewardsPerShare =
            rewardsPerShare +
            ((rewardsPerShareAccuracyFactor * amount) / (totalShares));
    }

    function process(uint256 gas) external override onlyToken {
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
                distributeReward(shareholders[currentIndex]);
            }

            gasUsed = gasUsed + (gasLeft - (gasleft()));
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

    //This function distribute the amounts
    function distributeReward(address shareholder) internal {
        if (shares[shareholder].amount == 0) {
            return;
        }

        uint256 amount = getUnpaidEarnings(shareholder);
        if (amount > 0) {
            totalDistributed = totalDistributed + (amount);
            BUSD.transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised =
                shares[shareholder].totalRealised +
                (amount);
            shares[shareholder].totalExcluded = getCumulativeRewards(
                shares[shareholder].amount
            );
        }
    }

    function claimReward(address _user) external override {
        distributeReward(_user);
    }

    function getPaidEarnings(address shareholder)
        public
        view
        override
        returns (uint256)
    {
        return shares[shareholder].totalRealised;
    }

    function getUnpaidEarnings(address shareholder)
        public
        view
        override
        returns (uint256)
    {
        if (shares[shareholder].amount == 0) {
            return 0;
        }

        uint256 shareholderTotalRewards = getCumulativeRewards(
            shares[shareholder].amount
        );
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if (shareholderTotalRewards <= shareholderTotalExcluded) {
            return 0;
        }

        return shareholderTotalRewards - (shareholderTotalExcluded);
    }

    function getCumulativeRewards(uint256 share)
        internal
        view
        returns (uint256)
    {
        return (share * rewardsPerShare) / (rewardsPerShareAccuracyFactor);
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
}

// main contract of Token
contract Cashflow_Money_Inu is IBEP20, Ownable {
    string private constant _name = "Cashflow Money Inu"; // Name
    string private constant _symbol = "CashflowInu"; // Symbol
    uint8 private constant _decimals = 18;
    uint256 private constant _totalSupply = 1_000_000_00 * 10**_decimals; //Token Decimals
    uint256 public maxHoldAmount = _totalSupply / 100;

    address public BUSD = 0xCEC4a43eBB02f9B80916F1c718338169d6d5C1F0; // Reward Token
    address private constant DEAD = address(0xdead); //Dead Address
    address private constant ZERO = address(0); //Zero Address

    IPCSRouter public router; //Router
    address public pcsPair; //Pair
    address public liquedityReceiver;
    address public marketFeeReceiver;
    address public devFeeReceiver;

    uint256 public totalBuyFee = 10; //Total Buy Fee
    uint256 public totalSellFee = 10; //Total Sell Fee
    uint256 public feeDivider = 100; // Fee deniminator

    RewardDistributor public distributor;
    uint256 public distributorGas = 500000;

    uint256 _liquedityBuyFee = 2; // 2% on Buying
    uint256 _reflectionBuyFee = 5; // 9% on Buying
    uint256 _marketBuyFee = 2; // 1% on Buying
    uint256 _devBuyFee = 1; // 0% on Buying

    uint256 _liqueditySellFee = 2; // 2% on Selling
    uint256 _reflectionSellFee = 5; // 9% on Selling
    uint256 _marketSellFee = 2; // 1% on Selling
    uint256 _devSellFee = 1; // 0% on Selling

    uint256 public _liquedityFeeCounter;
    uint256 public _reflectionFeeCounter;
    uint256 public _marketFeeCounter;
    uint256 public _devFeeCounter;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isRewardExempt;
    mapping(address => bool) public isLimitExempt;

    bool public enableSwap = true;
    uint256 public swapLimit = 2000 * (10**_decimals);

    bool inSwap;

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    event AutoLiquify(uint256 amountBNB, uint256 amountBOG);

    // intializing the addresses

    constructor() {
        // address _router = 0x10ED43C718714eb63d5aA57B78B54704E256024E; //mainnet
        address _router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; //testnet
        liquedityReceiver = msg.sender;
        marketFeeReceiver = address(0x8C95B3ff914c344496fc38397Baed2cF30FAA2df);
        devFeeReceiver = address(0x6dd3b40B3a3d1BaAE3e4d84D19d77Dc7802f4A5c);

        router = IPCSRouter(_router);
        pcsPair = IPCSFactory(router.factory()).createPair(
            address(this),
            router.WETH()
        );
        distributor = new RewardDistributor(_router);

        isRewardExempt[address(this)] = true;
        isRewardExempt[pcsPair] = true;
        isRewardExempt[DEAD] = true;

        isFeeExempt[owner()] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[liquedityReceiver] = true;
        isFeeExempt[marketFeeReceiver] = true;
        isFeeExempt[devFeeReceiver] = true;

        isLimitExempt[owner()] = true;
        isLimitExempt[address(this)] = true;
        isLimitExempt[pcsPair] = true;

        _balances[owner()] = _totalSupply;

        emit Transfer(address(0), owner(), _totalSupply);
    }

    receive() external payable {}

    // totalSupply() : Shows total Supply of token

    function totalSupply() external pure override returns (uint256) {
        return _totalSupply;
    }

    //decimals() : Shows decimals of token

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    // symbol() : Shows symbol of function

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    // name() : Shows name of Token

    function name() external pure override returns (string memory) {
        return _name;
    }

    // balanceOf() : Shows balance of the spacific user

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    //allowance()  : Shows allowance of the address from another address

    function allowance(address holder, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[holder][spender];
    }

    // approve() : This function gives allowance of token from one address to another address
    //  ****     : Allowance is checked in TransferFrom() function.

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    // transfer() : Transfers tokens  to another address

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        return _transfer(msg.sender, recipient, amount);
    }

    // transferFrom() : Transfers token from one address to another address by utilizing allowance

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (_allowances[sender][msg.sender] != _totalSupply) {
            _allowances[sender][msg.sender] =
                _allowances[sender][msg.sender] -
                amount;
        }

        return _transfer(sender, recipient, amount);
    }

    // _transfer() :   called by external transfer and transferFrom function

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        if (inSwap) {
            return _simpleTransfer(sender, recipient, amount);
        }

        if (shouldSwap()) {
            swapBack();
        }

        _balances[sender] = _balances[sender] - amount;

        uint256 amountReceived;
        if (
            isFeeExempt[sender] ||
            isFeeExempt[recipient] ||
            (sender != pcsPair && recipient != pcsPair)
        ) {
            amountReceived = amount;
        } else {
            uint256 feeAmount;
            if (sender == pcsPair) {
                feeAmount = (amount * totalBuyFee) / (feeDivider);
                amountReceived = amount - (feeAmount);
                _takeFee(sender, feeAmount);
                setBuyFeeCount(amount);
            }
            if (recipient == pcsPair) {
                feeAmount = (amount * totalSellFee) / (feeDivider);
                amountReceived = amount - (feeAmount);
                _takeFee(sender, feeAmount);
                setSellFeeCount(amount);
            }
        }

        if (!isLimitExempt[recipient]) {
            require(
                balanceOf(recipient) + amountReceived <= maxHoldAmount,
                "Max Hold Limit exceeds"
            );
        }

        _balances[recipient] = _balances[recipient] + (amountReceived);

        if (!isRewardExempt[sender]) {
            try distributor.setShare(sender, _balances[sender]) {} catch {}
        }
        if (!isRewardExempt[recipient]) {
            try
                distributor.setShare(recipient, _balances[recipient])
            {} catch {}
        }

        try distributor.process(distributorGas) {} catch {}

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    // _simpleTransfer() : Transfer basic token account to account

    function _simpleTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _balances[sender] = _balances[sender] - amount;

        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    // _takeFee() : This function get calls internally to take fee

    function _takeFee(address sender, uint256 feeAmount) internal {
        _balances[address(this)] = _balances[address(this)] + feeAmount;
        emit Transfer(sender, address(this), feeAmount);
    }

    function setBuyFeeCount(uint256 _amount) internal {
        _liquedityFeeCounter += (_amount * _liquedityBuyFee) / (feeDivider);
        _reflectionFeeCounter += (_amount * _reflectionBuyFee) / (feeDivider);
        _marketFeeCounter += (_amount * _marketBuyFee) / (feeDivider);
        _devFeeCounter += (_amount * _devBuyFee) / (feeDivider);
    }

    function setSellFeeCount(uint256 _amount) internal {
        _liquedityFeeCounter += (_amount * _liqueditySellFee) / (feeDivider);
        _reflectionFeeCounter += (_amount * _reflectionSellFee) / (feeDivider);
        _marketFeeCounter += (_amount * _marketSellFee) / (feeDivider);
        _devFeeCounter += (_amount * _devSellFee) / (feeDivider);
    }

    //shouldSwap() : To check swap should be done or not

    function shouldSwap() internal view returns (bool) {
        return (msg.sender != pcsPair &&
            !inSwap &&
            enableSwap &&
            _balances[address(this)] >= swapLimit);
    }

    //Swapback() : To swap and liqufy the token

    function swapBack() internal swapping {
        uint256 totalFee = _liquedityFeeCounter +
            (_reflectionFeeCounter) +
            (_marketFeeCounter) +
            (_devFeeCounter);

        uint256 amountToLiquify = ((swapLimit * _liquedityFeeCounter) /
            (totalFee)) / 2;

        uint256 amountToSwap = swapLimit - (amountToLiquify);
        _allowances[address(this)][address(router)] = _totalSupply;

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

        uint256 amountBNB = address(this).balance - (balanceBefore);

        uint256 totalBNBFee = totalFee - (_liquedityFeeCounter / (2));

        uint256 amountBNBForLiqudity = ((amountBNB * _liquedityFeeCounter) /
            totalBNBFee) / 2;
        uint256 amountBNBForReflection = (amountBNB * _reflectionFeeCounter) /
            (totalBNBFee);

        uint256 amountBNBForMarket = (amountBNB * _marketFeeCounter) /
            (totalBNBFee);

        uint256 amountBNBForDev = (amountBNB * _devFeeCounter) / (totalBNBFee);

        if (amountBNBForReflection > 0) {
            try
                distributor.depositBNB{value: amountBNBForReflection}()
            {} catch {}
        }
        if (amountBNBForReflection > 0) {
            payable(marketFeeReceiver).transfer(amountBNBForMarket);
        }
        if (amountBNBForReflection > 0) {
            payable(devFeeReceiver).transfer(amountBNBForDev);
        }
        if (amountToLiquify > 0) {
            router.addLiquidityETH{value: amountBNBForLiqudity}(
                address(this),
                amountToLiquify,
                0,
                0,
                liquedityReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountBNBForLiqudity, amountToLiquify);
        }

        _liquedityFeeCounter = 0;
        _reflectionFeeCounter = 0;
        _marketFeeCounter = 0;
        _devFeeCounter = 0;
    }

    // claimReward() : Function that claims divident manually

    function claimReward() external {
        distributor.claimReward(msg.sender);
    }

    // getPaidReward() :Function shows paid Rewards of the user

    function getPaidReward(address shareholder) public view returns (uint256) {
        return distributor.getPaidEarnings(shareholder);
    }

    // getUnpaidReward() : Function shows unpaid rewards of the user

    function getUnpaidReward(address shareholder)
        external
        view
        returns (uint256)
    {
        return distributor.getUnpaidEarnings(shareholder);
    }

    // getTotalDistributedReward(): Shows total distributed Reward

    function getTotalDistributedReward() external view returns (uint256) {
        return distributor.totalDistributed();
    }

    // setFeeExempt() : Function that Set Holders Fee Exempt
    //   ***          : It add user in fee exempt user list
    //   ***          : Owner & Authoized user Can set this

    function setFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    // setRewardExempt() : Set Holders Reward Exempt
    //      ***          : Function that add user in reward exempt user list
    //      ***          : Owner & Authoized user Can set this

    function setRewardExempt(address holder, bool exempt) external onlyOwner {
        require(holder != address(this) && holder != pcsPair);
        isRewardExempt[holder] = exempt;
        if (exempt) {
            distributor.setShare(holder, 0);
        } else {
            distributor.setShare(holder, _balances[holder]);
        }
    }

    // setBuyFee() : Function that set Buy Fee of token
    //   ***       : Owner & Authoized user Can set the fees

    function setBuyFee(
        uint256 _liquedityFee,
        uint256 _reflectionFee,
        uint256 _marketFee,
        uint256 _devFee,
        uint256 _feeDivider
    ) public onlyOwner {
        _liquedityBuyFee = _liquedityFee;
        _reflectionBuyFee = _reflectionFee;
        _marketBuyFee = _marketFee;
        _devBuyFee = _devFee;
        totalBuyFee = _liquedityFee + _reflectionFee + _marketFee + _devFee;
        feeDivider = _feeDivider;
        require(
            totalBuyFee <= (feeDivider * 15) / (100),
            "Can't be greater than 15%"
        );
    }

    // setSellFee() : Function that set Sell Fee
    //    ***       : Owner & Authoized user Can set the fees

    function setSellFee(
        uint256 _liquedityFee,
        uint256 _reflectionFee,
        uint256 _marketFee,
        uint256 _devFee,
        uint256 _feeDivider
    ) public onlyOwner {
        _liqueditySellFee = _liquedityFee;
        _reflectionSellFee = _reflectionFee;
        _marketSellFee = _marketFee;
        _devSellFee = _devFee;
        totalSellFee =
            _liquedityFee +
            (_reflectionFee) +
            (_marketFee) +
            (_devFee);
        feeDivider = _feeDivider;
        require(
            totalSellFee <= (feeDivider * 15) / (100),
            "Can't be greater than 15%"
        );
    }

    // setFeeReceivers() : Function to  set the addresses of Receivers
    //    ***            : Owner & Authoized user Can set the receivers

    function setFeeReceivers(
        address _liquedityReceiver,
        address _marketFeeReceiver,
        address _devFeeReceiver
    ) external onlyOwner {
        liquedityReceiver = _liquedityReceiver;
        marketFeeReceiver = _marketFeeReceiver;
        devFeeReceiver = _devFeeReceiver;
    }

    // setSwapBack() : Function that enable of disable swapping functionality of token while transfer
    //     ***       : Swap Limit can be changed through this function
    //     ***       : Owner & Authoized user Can set the swapBack

    function setSwapBack(bool _enabled, uint256 _amount) external onlyOwner {
        enableSwap = _enabled;
        swapLimit = _amount;
    }

    // setDistributionStandard() : Function that set distribution standerd on which distributor works
    //      ***                  : Owner & Authoized user Can set the standerd of distributor

    function setDistributionStandard(
        uint256 _minPeriod,
        uint256 _minDistribution
    ) external onlyOwner {
        distributor.setDistributionStandard(_minPeriod, _minDistribution);
    }

    //setDistributorSetting() : Function that set changes the distribution gas fee which is used in distributor
    //        ***             : Owner & Authoized user Can set the this amount

    function setDistributorSetting(uint256 gas) external onlyOwner {
        require(gas < 750000, "Gas must be lower than 750000");
        distributorGas = gas;
    }

    // setIsLimitExempt() : Function that sets or remove user from holding limit

    function setIsLimitExempt(address holder, bool exempt) external onlyOwner {
        isLimitExempt[holder] = exempt;
    }
}