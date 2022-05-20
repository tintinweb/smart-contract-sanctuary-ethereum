//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./AffinityDistributor.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapRouter02.sol";

/**
 * Contract: SafeAffinity
 *
 *  This Contract Awards SafeVault and SafeEarn to holders
 *  weighted by how much SafeAffinity you hold
 *
 *  Transfer Fee:  8%
 *  Buy Fee:       8%
 *  Sell Fee:     20%
 *
 *  Fees Go Toward:
 *  43.75% SafeVault Distribution
 *  43.75% SafeEarn Distribution
 *  8.75% Burn
 *  3.75% Marketing
 */
contract SafeAffinity is IERC20, Context, Ownable {
    using SafeMath for uint256;
    using SafeMath for uint8;
    using Address for address;

    // token data
    string constant _name = "MyAutostakingTest";
    string constant _symbol = "MAT ";
    uint8 constant _decimals = 9;
    // 1 Trillion Max Supply
    uint256 _totalSupply = 1 * 10**12 * (10**_decimals);
    uint256 public _maxTxAmount = _totalSupply.div(200); // 0.5% or 5 Billion
    // balances
    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;
    // exemptions
    mapping(address => bool) isFeeExempt;
    mapping(address => bool) isTxLimitExempt;
    mapping(address => bool) isDividendExempt;
    // fees
    uint256 public burnFee = 175;
    uint256 public reflectionFee = 1750;
    uint256 public marketingFee = 75;
    // total fees
    uint256 totalFeeSells = 2000;
    uint256 totalFeeBuys = 800;
    uint256 feeDenominator = 10000;
    // Marketing Funds Receiver
    address public marketingFeeReceiver =
        0xD8f9c299b13584757109a7C37Adbb897CEb7207F;
    // minimum bnb needed for distribution
    uint256 public minimumToDistribute = 1 * 10**17;
    // Pancakeswap V2 Router
    IUniswapV2Router02 router;
    address public pair;
    bool public allowTransferToMarketing = true;
    // gas for distributor
    AffinityDistributor public distributor;
    uint256 distributorGas = 500000;
    // in charge of swapping
    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply.div(30); // 0.03% = 300 Million
    // true if our threshold decreases with circulating supply
    bool public canChangeSwapThreshold = false;
    uint256 public swapThresholdPercentOfCirculatingSupply = 300;
    bool inSwap;
    bool isDistributing;
    // false to stop the burn
    bool burnEnabled = true;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }
    modifier distributing() {
        isDistributing = true;
        _;
        isDistributing = false;
    }
    // Uniswap Router V2
    // address private _dexRouter = 0x10ED43C718714eb63d5aA57B78B54704E256024E; //for bsc
    address private _dexRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    // initialize some stuff
    constructor() {
        // claimEarnDividend
        // Pancakeswap V2 Router
        router = IUniswapV2Router02(_dexRouter);
        // Liquidity Pool Address for BNB -> Vault
        pair = IUniswapV2Factory(router.factory()).createPair(
            router.WETH(),
            address(this)
        );
        _allowances[address(this)][address(router)] = _totalSupply;
        // our dividend Distributor
        distributor = new AffinityDistributor(_dexRouter, address(this));
        // exempt deployer and contract from fees
        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;
        // exempt important addresses from TX limit
        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[marketingFeeReceiver] = true;
        isTxLimitExempt[address(distributor)] = true;
        isTxLimitExempt[address(this)] = true;
        // exempt this important addresses  from receiving Rewards
        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        // approve router of total supply
        approve(_dexRouter, _totalSupply);
        approve(address(pair), _totalSupply);
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function balanceOfBNB() public view returns (uint256) {
        return address(this).balance;
    }

    function allowance(address holder, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[holder][spender];
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
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

    function internalApprove() private {
        _allowances[address(this)][address(router)] = _totalSupply;
        _allowances[address(this)][address(pair)] = _totalSupply;
    }

    /** Approve Total Supply */
    function approveMax(address spender) external returns (bool) {
        return approve(spender, _totalSupply);
    }

    /** Transfer Function */
    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        return _transferFrom(msg.sender, recipient, amount);
    }

    /** Transfer Function */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (_allowances[sender][msg.sender] != _totalSupply) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]
                .sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    /** Internal Transfer */
    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        // make standard checks
        require(recipient != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        // check if we have reached the transaction limit
        require(
            amount <= _maxTxAmount || isTxLimitExempt[sender],
            "TX Limit Exceeded"
        );
        // whether transfer succeeded
        bool success;
        // amount of tokens received by recipient
        uint256 amountReceived;
        // if we're in swap perform a basic transfer
        if (inSwap || isDistributing) {
            (amountReceived, success) = handleTransferBody(
                sender,
                recipient,
                amount
            );
            emit Transfer(sender, recipient, amountReceived);
            return success;
        }

        // limit gas consumption by splitting up operations
        if (shouldSwapBack()) {
            swapBack();
            (amountReceived, success) = handleTransferBody(
                sender,
                recipient,
                amount
            );
        } else if (shouldReflectAndDistribute()) {
            reflectAndDistribute();
            (amountReceived, success) = handleTransferBody(
                sender,
                recipient,
                amount
            );
        } else {
            (amountReceived, success) = handleTransferBody(
                sender,
                recipient,
                amount
            );
            try distributor.process(distributorGas) {} catch {}
        }

        emit Transfer(sender, recipient, amountReceived);
        return success;
    }

    /** Takes Associated Fees and sets holders' new Share for the Safemoon Distributor */
    function handleTransferBody(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (uint256, bool) {
        // subtract balance from sender
        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );
        // amount receiver should receive
        uint256 amountReceived = shouldTakeFee(sender)
            ? takeFee(recipient, amount)
            : amount;
        // add amount to recipient
        _balances[recipient] = _balances[recipient].add(amountReceived);
        // set shares for distributors
        if (!isDividendExempt[sender]) {
            distributor.setShare(sender, _balances[sender]);
        }
        if (!isDividendExempt[recipient]) {
            distributor.setShare(recipient, _balances[recipient]);
        }
        // return the amount received by receiver
        return (amountReceived, true);
    }

    /** False if sender is Fee Exempt, True if not */
    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    /** Takes Proper Fee (8% buys / transfers, 20% on sells) and stores in contract */
    function takeFee(address receiver, uint256 amount)
        internal
        returns (uint256)
    {
        uint256 feeAmount = amount.mul(getTotalFee(receiver == pair)).div(
            feeDenominator
        );
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        return amount.sub(feeAmount);
    }

    /** True if we should swap from Vault => BNB */
    function shouldSwapBack() internal view returns (bool) {
        return
            msg.sender != pair &&
            !inSwap &&
            swapEnabled &&
            _balances[address(this)] >= swapThreshold;
    }

    /**
     *  Swaps SafeAffinity for BNB if threshold is reached and the swap is enabled
     *  Burns 20% of SafeAffinity in Contract
     *  Swaps The Rest For BNB
     */
    function swapBack() private swapping {
        // path from token -> BNB
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        // tokens allocated to burning
        uint256 burnAmount = swapThreshold.mul(burnFee).div(totalFeeSells);
        // burn tokens
        burnTokens(burnAmount);
        // how many are left to swap with
        uint256 swapAmount = swapThreshold.sub(burnAmount);
        // swap tokens for BNB
        try
            router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                swapAmount,
                0,
                path,
                address(this),
                block.timestamp
            )
        {} catch {
            return;
        }

        // Tell The Blockchain
        emit SwappedBack(swapAmount, burnAmount);
    }

    function shouldReflectAndDistribute() private view returns (bool) {
        return
            msg.sender != pair &&
            !isDistributing &&
            swapEnabled &&
            address(this).balance >= minimumToDistribute;
    }

    function reflectAndDistribute() private distributing {
        bool success;
        bool successful;
        uint256 amountBNBMarketing;
        uint256 amountBNBReflection;
        // allocate bnb
        if (allowTransferToMarketing) {
            amountBNBMarketing = address(this).balance.mul(marketingFee).div(
                totalFeeSells
            );
            amountBNBReflection = address(this).balance.sub(amountBNBMarketing);
            // fund distributors
            (success, ) = payable(address(distributor)).call{
                value: amountBNBReflection,
                gas: 26000
            }("");
            distributor.deposit();
            // transfer to marketing
            if (allowTransferToMarketing) {
                (successful, ) = payable(marketingFeeReceiver).call{
                    value: amountBNBMarketing,
                    gas: 26000
                }("");
            }
        } else {
            amountBNBReflection = address(this).balance;
            // fund distributors
            (success, ) = payable(address(distributor)).call{
                value: amountBNBReflection,
                gas: 26000
            }("");
            distributor.deposit();
        }
        emit FundDistributors(amountBNBReflection, amountBNBMarketing);
    }

    /** Removes Tokens From Circulation */
    function burnTokens(uint256 tokenAmount) private returns (bool) {
        if (!burnEnabled) {
            return false;
        }
        // update balance of contract
        _balances[address(this)] = _balances[address(this)].sub(
            tokenAmount,
            "cannot burn this amount"
        );
        // update Total Supply
        _totalSupply = _totalSupply.sub(
            tokenAmount,
            "total supply cannot be negative"
        );
        // approve Router for total supply
        internalApprove();
        // change Swap Threshold if we should
        if (canChangeSwapThreshold) {
            swapThreshold = _totalSupply.div(
                swapThresholdPercentOfCirculatingSupply
            );
        }
        // emit Transfer to Blockchain
        emit Transfer(address(this), address(0), tokenAmount);
        return true;
    }

    /** Claim Your Vault Rewards Early */
    function claimVaultDividend() external returns (bool) {
        distributor.claimVAULTDividend(msg.sender);
        return true;
    }

    /** Claim Your Earn Rewards Manually */
    function claimEarnDividend() external returns (bool) {
        distributor.claimEarnDividend(msg.sender);
        return true;
    }

    /** Manually Depsoits To The Earn or Vault Contract */
    function manuallyDeposit() external returns (bool) {
        distributor.deposit();
        return true;
    }

    /** Is Holder Exempt From Fees */
    function getIsFeeExempt(address holder) public view returns (bool) {
        return isFeeExempt[holder];
    }

    /** Is Holder Exempt From Earn Dividends */
    function getIsDividendExempt(address holder) public view returns (bool) {
        return isDividendExempt[holder];
    }

    /** Is Holder Exempt From Transaction Limit */
    function getIsTxLimitExempt(address holder) public view returns (bool) {
        return isTxLimitExempt[holder];
    }

    /** Get Fees for Buying or Selling */
    function getTotalFee(bool selling) public view returns (uint256) {
        if (selling) {
            return totalFeeSells;
        }
        return totalFeeBuys;
    }

    /** Sets Various Fees */
    function setFees(
        uint256 _burnFee,
        uint256 _reflectionFee,
        uint256 _marketingFee,
        uint256 _buyFee
    ) external onlyOwner {
        burnFee = _burnFee;
        reflectionFee = _reflectionFee;
        marketingFee = _marketingFee;
        totalFeeSells = _burnFee.add(_reflectionFee).add(_marketingFee);
        totalFeeBuys = _buyFee;
        require(_buyFee <= 1000);
        require(totalFeeSells < feeDenominator / 2);
    }

    /** Set Exemption For Holder */
    function setIsFeeAndTXLimitExempt(
        address holder,
        bool feeExempt,
        bool txLimitExempt
    ) external onlyOwner {
        require(holder != address(0));
        isFeeExempt[holder] = feeExempt;
        isTxLimitExempt[holder] = txLimitExempt;
    }

    /** Set Holder To Be Exempt From Earn Dividends */
    function setIsDividendExempt(address holder, bool exempt)
        external
        onlyOwner
    {
        require(holder != address(this) && holder != pair);
        isDividendExempt[holder] = exempt;
        if (exempt) {
            distributor.setShare(holder, 0);
        } else {
            distributor.setShare(holder, _balances[holder]);
        }
    }

    /** Set Settings related to Swaps */
    function setSwapBackSettings(
        bool _swapEnabled,
        uint256 _swapThreshold,
        bool _canChangeSwapThreshold,
        uint256 _percentOfCirculatingSupply,
        bool _burnEnabled,
        uint256 _minimumBNBToDistribute
    ) external onlyOwner {
        swapEnabled = _swapEnabled;
        swapThreshold = _swapThreshold;
        canChangeSwapThreshold = _canChangeSwapThreshold;
        swapThresholdPercentOfCirculatingSupply = _percentOfCirculatingSupply;
        burnEnabled = _burnEnabled;
        minimumToDistribute = _minimumBNBToDistribute;
    }

    /** Set Criteria For SafeAffinity Distributor */
    function setDistributionCriteria(
        uint256 _minPeriod,
        uint256 _minDistribution,
        uint256 _bnbToTokenThreshold
    ) external onlyOwner {
        distributor.setDistributionCriteria(
            _minPeriod,
            _minDistribution,
            _bnbToTokenThreshold
        );
    }

    /** Should We Transfer To Marketing */
    function setAllowTransferToMarketing(
        bool _canSendToMarketing,
        address _marketingFeeReceiver
    ) external onlyOwner {
        allowTransferToMarketing = _canSendToMarketing;
        marketingFeeReceiver = _marketingFeeReceiver;
    }

    /** Updates The Pancakeswap Router */
    function setDexRouter(address nRouter) external onlyOwner {
        require(nRouter != _dexRouter);
        _dexRouter = nRouter;
        router = IUniswapV2Router02(nRouter);
        address _uniswapV2Pair = IUniswapV2Factory(router.factory()).createPair(
            address(this),
            router.WETH()
        );
        pair = _uniswapV2Pair;
        _allowances[address(this)][address(router)] = _totalSupply;
        distributor.updatePancakeRouterAddress(nRouter);
    }

    /** Set Address For SafeAffinity Distributor */
    function setDistributor(address payable newDistributor) external onlyOwner {
        require(
            newDistributor != address(distributor),
            "Distributor already has this address"
        );
        distributor = AffinityDistributor(newDistributor);
        emit SwappedDistributor(newDistributor);
    }

    /** Swaps SafeAffinity and SafeVault Addresses in case of migration */
    function setTokenAddresses(address nSafeEarn, address nSafeVault)
        external
        onlyOwner
    {
        distributor.setSafeEarnAddress(nSafeEarn);
        distributor.setSafeVaultAddress(nSafeVault);
        emit SwappedTokenAddresses(nSafeEarn, nSafeVault);
    }

    /** Deletes the entire bag from sender */
    function deleteBag(uint256 nTokens) external returns (bool) {
        // make sure you are burning enough tokens
        require(nTokens > 0);
        // if the balance is greater than zero
        require(
            _balances[msg.sender] >= nTokens,
            "user does not own enough tokens"
        );
        // remove tokens from sender
        _balances[msg.sender] = _balances[msg.sender].sub(
            nTokens,
            "cannot have negative tokens"
        );
        // remove tokens from total supply
        _totalSupply = _totalSupply.sub(
            nTokens,
            "total supply cannot be negative"
        );
        // approve Router for the new total supply
        internalApprove();
        // set share in distributor
        distributor.setShare(msg.sender, _balances[msg.sender]);
        // tell blockchain
        emit Transfer(msg.sender, address(0), nTokens);
        return true;
    }

    // Events
    event SwappedDistributor(address newDistributor);
    event SwappedBack(uint256 tokensSwapped, uint256 amountBurned);
    event SwappedTokenAddresses(address newSafeEarn, address newSafeVault);
    event FundDistributors(uint256 reflectionAmount, uint256 marketingAmount);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IAffinityDistributor.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IUniswapRouter02.sol";

/** Distributes SafeVault and SafeEarn To Holders Varied on Weight */
contract AffinityDistributor is IAffinityDistributor {
    using SafeMath for uint256;
    using Address for address;

    // SafeVault Contract
    address _token;
    // Share of SafeVault
    struct Share {
        uint256 amount;
        uint256 totalExcludedVault;
        uint256 totalRealisedVault;
        uint256 totalExcludedEarn;
        uint256 totalRealisedEarn;
    }
    // SafeEarn contract address
    address SafeEarn = 0xc778417E063141139Fce010982780140Aa0cD5Ab; //weth on rinkeby
    //0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; //wbnb on bsc testnet
    // SafeVault
    address SafeVault;

    // Pancakeswap Router
    IUniswapV2Router02 router;
    // shareholder fields
    address[] shareholders;
    mapping(address => uint256) shareholderIndexes;
    mapping(address => uint256) shareholderClaims;
    mapping(address => Share) public shares;
    // shares math and fields
    uint256 public totalShares;
    uint256 public totalDividendsEARN;
    uint256 public dividendsPerShareEARN;

    uint256 public totalDividendsVAULT;
    uint256 public dividendsPerShareVAULT;

    uint256 public dividendsPerShareAccuracyFactor = 10**36;
    // distributes twice per day
    uint256 public minPeriod = 4 hours;
    // auto claim
    uint256 public minAutoPeriod = 1 hours;
    // 20,000 Minimum Distribution
    uint256 public minDistribution = 2 * 10**4;
    // BNB Needed to Swap to SafeAffinity
    uint256 public swapToTokenThreshold = 5 * (10**18);
    // current index in shareholder array
    uint256 currentIndexEarn;
    // current index in shareholder array
    uint256 currentIndexVault;

    bool earnsTurnPurchase = false;
    bool earnsTurnDistribute = true;

    modifier onlyToken() {
        require(msg.sender == _token);
        _;
    }

    constructor(address _router, address _myToken) {
        router = _router != address(0)
            ? IUniswapV2Router02(_router)
            : IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        _token = msg.sender;
        SafeVault = _myToken;
    }

    function setDistributionCriteria(
        uint256 _minPeriod,
        uint256 _minDistribution,
        uint256 _bnbToTokenThreshold
    ) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
        swapToTokenThreshold = _bnbToTokenThreshold;
    }

    function setShare(address shareholder, uint256 amount)
        external
        override
        onlyToken
    {
        if (shares[shareholder].amount > 0) {
            distributeVaultDividend(shareholder);
            distributeEarnDividend(shareholder);
        }

        if (amount > 0 && shares[shareholder].amount == 0) {
            addShareholder(shareholder);
        } else if (amount == 0 && shares[shareholder].amount > 0) {
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcludedVault = getCumulativeVaultDividends(
            shares[shareholder].amount
        );
        shares[shareholder].totalExcludedEarn = getCumulativeEarnDividends(
            shares[shareholder].amount
        );
    }

    function deposit() external override onlyToken {
        if (address(this).balance < swapToTokenThreshold) return;

        if (earnsTurnPurchase) {
            uint256 balanceBefore = IERC20(SafeEarn).balanceOf(address(this));

            address[] memory path = new address[](2);
            path[0] = router.WETH();
            path[1] = SafeEarn;

            try
                router.swapExactETHForTokensSupportingFeeOnTransferTokens{
                    value: swapToTokenThreshold
                }(0, path, address(this), block.timestamp.add(30))
            {} catch {
                return;
            }

            uint256 amount = IERC20(SafeEarn).balanceOf(address(this)).sub(
                balanceBefore
            );

            totalDividendsEARN = totalDividendsEARN.add(amount);
            dividendsPerShareEARN = dividendsPerShareEARN.add(
                dividendsPerShareAccuracyFactor.mul(amount).div(totalShares)
            );
            earnsTurnPurchase = false;
        } else {
            uint256 balanceBefore = IERC20(SafeVault).balanceOf(address(this));

            address[] memory path = new address[](2);
            path[0] = router.WETH();
            path[1] = SafeVault;

            try
                router.swapExactETHForTokensSupportingFeeOnTransferTokens{
                    value: swapToTokenThreshold
                }(0, path, address(this), block.timestamp.add(30))
            {} catch {
                return;
            }

            uint256 amount = IERC20(SafeVault).balanceOf(address(this)).sub(
                balanceBefore
            );

            totalDividendsVAULT = totalDividendsVAULT.add(amount);
            dividendsPerShareVAULT = dividendsPerShareVAULT.add(
                dividendsPerShareAccuracyFactor.mul(amount).div(totalShares)
            );
            earnsTurnPurchase = true;
        }
    }

    function process(uint256 gas) external override onlyToken {
        uint256 shareholderCount = shareholders.length;

        if (shareholderCount == 0) {
            return;
        }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        earnsTurnDistribute = !earnsTurnDistribute;
        uint256 iterations = 0;

        if (earnsTurnDistribute) {
            while (gasUsed < gas && iterations < shareholderCount) {
                if (currentIndexEarn >= shareholderCount) {
                    currentIndexEarn = 0;
                }

                if (shouldDistributeEarn(shareholders[currentIndexEarn])) {
                    distributeEarnDividend(shareholders[currentIndexEarn]);
                }

                gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
                gasLeft = gasleft();
                currentIndexEarn++;
                iterations++;
            }
        } else {
            while (gasUsed < gas && iterations < shareholderCount) {
                if (currentIndexVault >= shareholderCount) {
                    currentIndexVault = 0;
                }

                if (shouldDistributeVault(shareholders[currentIndexVault])) {
                    distributeVaultDividend(shareholders[currentIndexVault]);
                }

                gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
                gasLeft = gasleft();
                currentIndexVault++;
                iterations++;
            }
        }
    }

    function processManually() external override returns (bool) {
        uint256 shareholderCount = shareholders.length;

        if (shareholderCount == 0) {
            return false;
        }

        uint256 iterations = 0;
        uint256 index = 0;

        while (iterations < shareholderCount) {
            if (index >= shareholderCount) {
                index = 0;
            }

            if (shouldDistributeVault(shareholders[index])) {
                distributeVaultDividend(shareholders[index]);
            }
            index++;
            iterations++;
        }
        return true;
    }

    function shouldDistributeVault(address shareholder)
        internal
        view
        returns (bool)
    {
        return
            shareholderClaims[shareholder] + minPeriod < block.timestamp &&
            getUnpaidVaultEarnings(shareholder) > minDistribution;
    }

    function shouldDistributeEarn(address shareholder)
        internal
        view
        returns (bool)
    {
        return
            shareholderClaims[shareholder] + minPeriod < block.timestamp &&
            getUnpaidEarnEarnings(shareholder) > minDistribution;
    }

    function distributeVaultDividend(address shareholder) internal {
        if (shares[shareholder].amount == 0) {
            return;
        }

        uint256 amount = getUnpaidVaultEarnings(shareholder);
        if (amount > 0) {
            bool success = IERC20(SafeVault).transfer(shareholder, amount);
            if (success) {
                shareholderClaims[shareholder] = block.timestamp;
                shares[shareholder].totalRealisedVault = shares[shareholder]
                    .totalRealisedVault
                    .add(amount);
                shares[shareholder]
                    .totalExcludedVault = getCumulativeVaultDividends(
                    shares[shareholder].amount
                );
            }
        }
    }

    function distributeEarnDividend(address shareholder) internal {
        if (shares[shareholder].amount == 0) {
            return;
        }

        uint256 amount = getUnpaidEarnEarnings(shareholder);
        if (amount > 0) {
            bool success = IERC20(SafeEarn).transfer(shareholder, amount);
            if (success) {
                shareholderClaims[shareholder] = block.timestamp;
                shares[shareholder].totalRealisedEarn = shares[shareholder]
                    .totalRealisedEarn
                    .add(amount);
                shares[shareholder]
                    .totalExcludedEarn = getCumulativeEarnDividends(
                    shares[shareholder].amount
                );
            }
        }
    }

    function claimEarnDividend(address claimer) external override onlyToken {
        require(
            shareholderClaims[claimer] + minAutoPeriod < block.timestamp,
            "must wait at least the minimum auto withdraw period"
        );
        distributeEarnDividend(claimer);
    }

    function claimVAULTDividend(address claimer) external override onlyToken {
        require(
            shareholderClaims[claimer] + minAutoPeriod < block.timestamp,
            "must wait at least the minimum auto withdraw period"
        );
        distributeVaultDividend(claimer);
    }

    function getUnpaidVaultEarnings(address shareholder)
        public
        view
        returns (uint256)
    {
        if (shares[shareholder].amount == 0) {
            return 0;
        }

        uint256 shareholderTotalDividends = getCumulativeVaultDividends(
            shares[shareholder].amount
        );
        uint256 shareholderTotalExcluded = shares[shareholder]
            .totalExcludedVault;

        if (shareholderTotalDividends <= shareholderTotalExcluded) {
            return 0;
        }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getUnpaidEarnEarnings(address shareholder)
        public
        view
        returns (uint256)
    {
        if (shares[shareholder].amount == 0) {
            return 0;
        }

        uint256 shareholderTotalDividends = getCumulativeEarnDividends(
            shares[shareholder].amount
        );
        uint256 shareholderTotalExcluded = shares[shareholder]
            .totalExcludedEarn;

        if (shareholderTotalDividends <= shareholderTotalExcluded) {
            return 0;
        }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeVaultDividends(uint256 share)
        internal
        view
        returns (uint256)
    {
        return
            share.mul(dividendsPerShareVAULT).div(
                dividendsPerShareAccuracyFactor
            );
    }

    function getCumulativeEarnDividends(uint256 share)
        internal
        view
        returns (uint256)
    {
        return
            share.mul(dividendsPerShareEARN).div(
                dividendsPerShareAccuracyFactor
            );
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
        delete shareholderIndexes[shareholder];
    }

    /** Updates the Address of the PCS Router */
    function updatePancakeRouterAddress(address pcsRouter)
        external
        override
        onlyToken
    {
        router = IUniswapV2Router02(pcsRouter);
    }

    /** New Vault Address */
    function setSafeVaultAddress(address newSafeVault)
        external
        override
        onlyToken
    {
        SafeVault = newSafeVault;
    }

    /** New Earn Address */
    function setSafeEarnAddress(address newSafeEarn)
        external
        override
        onlyToken
    {
        SafeEarn = newSafeEarn;
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
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

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IUniswapV2Router01 {
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

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
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

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IAffinityDistributor {
    function setDistributionCriteria(
        uint256 _minPeriod,
        uint256 _minDistribution,
        uint256 _bnbToSafemoonThreshold
    ) external;

    function setShare(address shareholder, uint256 amount) external;

    function deposit() external;

    function process(uint256 gas) external;

    function processManually() external returns (bool);

    function claimEarnDividend(address sender) external;

    function claimVAULTDividend(address sender) external;

    function updatePancakeRouterAddress(address pcs) external;

    function setSafeEarnAddress(address nSeth) external;

    function setSafeVaultAddress(address nSeth) external;
}