// SPDX-License-Identifier: MIT

// NOTE: BankingNode.sol should only be created through the BNPLFactory contract to
// ensure compatibility of baseToken and minimum bond amounts. Before interacting,
// please ensure that the contract deployer was BNPLFactory.sol

pragma solidity ^0.8.0;

import "ERC20.sol";
import "Pausable.sol";
import "ReentrancyGuard.sol";
import "ILendingPool.sol";
import "ILendingPoolAddressesProvider.sol";
import "IAaveIncentivesController.sol";
import "UniswapV2Library.sol";
import "TransferHelper.sol";

//CUSTOM ERRORS

//occurs when trying to do privledged functions
error InvalidUser(address requiredUser);
//occurs when users try to add funds if node operator hasn't maintaioned enough pledged BNPL
error NodeInactive();
//occurs when trying to interact without being KYC's (if node requires it)
error KYCNotApproved();
//occurs when trying to pay loans that are completed or not started
error NoPrincipalRemaining();
//occurs when trying to swap/deposit/withdraw a zero
error ZeroInput();
//occurs if interest rate, loanAmount, or paymentInterval or is applied as 0
error InvalidLoanInput();
//occurs if trying to apply for a loan with >5 year loan length
error MaximumLoanDurationExceeded();
//occurs if user tries to withdraw collateral while loan is still ongoing
error LoanStillOngoing();
//edge case occurence if all BNPL is slashed, but there are still BNPL shares
error DonationRequired();
//occurs if operator tries to unstake while there are active loans
error ActiveLoansOngoing();
//occurs when trying to withdraw too much funds
error InsufficientBalance();
//occurs during swaps, if amount received is lower than minOut (slippage tolerance exceeded)
error InsufficentOutput();
//occurs if trying to approve a loan that has already started
error LoanAlreadyStarted();
//occurs if trying to approve a loan without enough collateral posted
error InsufficientCollateral();
//occurs when trying to slash a loan that is not yet considered defaulted
error LoanNotExpired();
//occurs is trying to slash an already slashed loan
error LoanAlreadySlashed();
//occurs if trying to withdraw staked BNPL where 7 day unbonding hasnt passed
error LoanStillUnbonding();
//occurs if trying to post baseToken as collateral
error InvalidCollateral();
//first deposit to prevent edge case must be at least 10M wei
error InvalidInitialDeposit();

contract BankingNode is ERC20("BNPL USD", "pUSD") {
    //Node specific variables
    address public operator;
    address public baseToken; //base liquidity token, e.g. USDT or USDC
    uint256 public gracePeriod;
    bool public requireKYC;

    //variables used for swaps, private to reduce contract size
    address private uniswapFactory;
    address private WETH;
    uint256 private incrementor;

    //constants set by factory
    address public BNPL;
    ILendingPoolAddressesProvider public lendingPoolProvider;
    address public immutable bnplFactory;
    //used by treasury can be private
    IAaveIncentivesController private aaveRewardController;
    address private treasury;

    //For loans
    mapping(uint256 => Loan) public idToLoan;
    uint256[] public pendingRequests;
    uint256[] public currentLoans;
    mapping(uint256 => uint256) defaultedLoans;
    uint256 public defaultedLoanCount;

    //For Staking, Slashing and Balances
    uint256 public accountsReceiveable;
    mapping(address => bool) public whitelistedAddresses;
    mapping(address => uint256) public unbondBlock;
    mapping(uint256 => address) public loanToAgent;
    uint256 public slashingBalance;
    mapping(address => uint256) public stakingShares;
    //can be private as there is a getter function for staking balance
    uint256 public totalStakingShares;

    uint256 public unbondingAmount;
    mapping(address => uint256) public unbondingShares;
    //can be private as there is getter function for unbonding balance
    uint256 private totalUnbondingShares;
    uint256 public timeCreated;

    //For Collateral in loans
    mapping(address => uint256) public collateralOwed;

    struct Loan {
        address borrower;
        bool interestOnly; //interest only or principal + interest
        uint256 loanStartTime; //unix timestamp of start
        uint256 loanAmount;
        uint256 paymentInterval; //unix interval of payment (e.g. monthly = 2,628,000)
        uint256 interestRate; //interest rate per peiod * 10000, e.g., 10% on a 12 month loan = : 0.1 * 10000 / 12 = 83
        uint256 numberOfPayments;
        uint256 principalRemaining;
        uint256 paymentsMade;
        address collateral;
        uint256 collateralAmount;
        bool isSlashed;
    }

    //EVENTS
    event LoanRequest(uint256 loanId, string message);
    event collateralWithdrawn(
        uint256 loanId,
        address collateral,
        uint256 collateralAmount
    );
    event approvedLoan(uint256 loanId);
    event loanPaymentMade(uint256 loanId);
    event loanRepaidEarly(uint256 loanId);
    event baseTokenDeposit(address user, uint256 amount);
    event baseTokenWithdrawn(address user, uint256 amount);
    event feesCollected(uint256 operatorFees, uint256 stakerFees);
    event baseTokensDonated(uint256 amount);
    event loanSlashed(uint256 loanId);
    event slashingSale(uint256 bnplSold, uint256 baseTokenRecovered);
    event bnplStaked(address user, uint256 bnplStaked);
    event unbondingInitiated(address user, uint256 unbondAmount);
    event bnplWithdrawn(address user, uint256 bnplWithdrawn);
    event KYCRequirementChanged(bool newStatus);

    constructor() {
        bnplFactory = msg.sender;
    }

    // MODIFIERS

    /**
     * Ensure a node is active for deposit, stake functions
     * Require KYC is also batched in
     */
    modifier ensureNodeActive() {
        address _operator = operator;
        if (msg.sender != bnplFactory && msg.sender != _operator) {
            if (getBNPLBalance(_operator) < 0x13DA329B6336471800000) {
                revert NodeInactive();
            }
            if (requireKYC && whitelistedAddresses[msg.sender] == false) {
                revert KYCNotApproved();
            }
        }
        _;
    }

    /**
     * Ensure that the loan has principal to be paid
     */
    modifier ensurePrincipalRemaining(uint256 loanId) {
        if (idToLoan[loanId].principalRemaining == 0) {
            revert NoPrincipalRemaining();
        }
        _;
    }

    /**
     * For operator only functions
     */
    modifier operatorOnly() {
        address _operator = operator;
        if (msg.sender != _operator) {
            revert InvalidUser(_operator);
        }
        _;
    }

    /**
     * Requires input value to be non-zero
     */
    modifier nonZeroInput(uint256 input) {
        if (input == 0) {
            revert ZeroInput();
        }
        _;
    }

    /**
     * Ensures collateral is not the baseToken
     */
    modifier nonBaseToken(address collateral) {
        if (collateral == baseToken) {
            revert InvalidCollateral();
        }
        _;
    }

    //STATE CHANGING FUNCTIONS

    /**
     * Called once by the factory at time of deployment
     */
    function initialize(
        address _baseToken,
        address _BNPL,
        bool _requireKYC,
        address _operator,
        uint256 _gracePeriod,
        address _lendingPoolProvider,
        address _WETH,
        address _aaveDistributionController,
        address _uniswapFactory
    ) external {
        //only to be done by factory, no need for error msgs in here as not used by users
        require(msg.sender == bnplFactory);
        baseToken = _baseToken;
        BNPL = _BNPL;
        requireKYC = _requireKYC;
        operator = _operator;
        gracePeriod = _gracePeriod;
        lendingPoolProvider = ILendingPoolAddressesProvider(
            _lendingPoolProvider
        );
        aaveRewardController = IAaveIncentivesController(
            _aaveDistributionController
        );
        WETH = _WETH;
        uniswapFactory = _uniswapFactory;
        treasury = address(0x27a99802FC48b57670846AbFFf5F2DcDE8a6fC29);
        timeCreated = block.timestamp;
        //decimal check on baseToken and aToken to make sure math logic on future steps
        require(
            ERC20(_baseToken).decimals() ==
                ERC20(
                    _getLendingPool().getReserveData(_baseToken).aTokenAddress
                ).decimals()
        );
    }

    /**
     * Request a loan from the banking node
     * Saves the loan with the operator able to approve or reject
     * Can post collateral if chosen, collateral accepted is anything that is accepted by aave
     * Collateral can not be the same token as baseToken
     */
    function requestLoan(
        uint256 loanAmount,
        uint256 paymentInterval,
        uint256 numberOfPayments,
        uint256 interestRate,
        bool interestOnly,
        address collateral,
        uint256 collateralAmount,
        address agent,
        string memory message
    )
        external
        ensureNodeActive
        nonBaseToken(collateral)
        returns (uint256 requestId)
    {
        if (
            loanAmount < 10000000 ||
            paymentInterval == 0 ||
            interestRate == 0 ||
            numberOfPayments == 0
        ) {
            revert InvalidLoanInput();
        }
        //157,680,000 seconds in 5 years
        if (paymentInterval * numberOfPayments > 157680000) {
            revert MaximumLoanDurationExceeded();
        }
        requestId = incrementor;
        incrementor++;
        pendingRequests.push(requestId);
        idToLoan[requestId] = Loan(
            msg.sender, //set borrower
            interestOnly,
            0, //start time initiated to 0
            loanAmount,
            paymentInterval, //interval of payments (e.g. Monthly)
            interestRate, //annualized interest rate per period * 10000 (e.g. 12 month loan 10% = 83)
            numberOfPayments,
            0, //initalize principalRemaining to 0
            0, //intialize paymentsMade to 0
            collateral,
            collateralAmount,
            false
        );
        //post the collateral if any
        if (collateralAmount > 0) {
            //update the collateral owed (interest accrued on collateral is given to lend)
            collateralOwed[collateral] += collateralAmount;
            TransferHelper.safeTransferFrom(
                collateral,
                msg.sender,
                address(this),
                collateralAmount
            );
            //deposit the collateral in AAVE to accrue interest
            _depositToLendingPool(collateral, collateralAmount);
        }
        //save the agent of the loan
        loanToAgent[requestId] = agent;

        emit LoanRequest(requestId, message);
    }

    /**
     * Withdraw the collateral from a loan
     * Loan must have no principal remaining (not approved, or payments finsihed)
     */
    function withdrawCollateral(uint256 loanId) external {
        Loan storage loan = idToLoan[loanId];
        address collateral = loan.collateral;
        uint256 amount = loan.collateralAmount;

        //must be the borrower or operator to withdraw, and loan must be either paid/not initiated
        if (msg.sender != loan.borrower) {
            revert InvalidUser(loan.borrower);
        }
        if (loan.principalRemaining > 0) {
            revert LoanStillOngoing();
        }

        //update the amounts
        collateralOwed[collateral] -= amount;
        loan.collateralAmount = 0;

        //no need to check if loan is slashed as collateral amont set to 0 on slashing
        _withdrawFromLendingPool(collateral, amount, loan.borrower);
        emit collateralWithdrawn(loanId, collateral, amount);
    }

    /**
     * Collect AAVE rewards to be sent to the treasury
     */
    function collectAaveRewards(address[] calldata assets) external {
        uint256 rewardAmount = aaveRewardController.getUserUnclaimedRewards(
            address(this)
        );
        address _treasuy = treasury;
        if (rewardAmount == 0) {
            revert ZeroInput();
        }
        //claim rewards to the treasury
        aaveRewardController.claimRewards(assets, rewardAmount, _treasuy);
        //no need for event as its a function that will only be used by treasury
    }

    /**
     * Collect the interest earnt on collateral posted to distribute to stakers
     * Collateral can not be the same as baseToken
     */
    function collectCollateralFees(address collateral)
        external
        nonBaseToken(collateral)
    {
        //get the aToken address
        ILendingPool lendingPool = _getLendingPool();
        address _bnpl = BNPL;
        uint256 feesAccrued = IERC20(
            lendingPool.getReserveData(collateral).aTokenAddress
        ).balanceOf(address(this)) - collateralOwed[collateral];
        //ensure there is collateral to collect inside of _swap
        lendingPool.withdraw(collateral, feesAccrued, address(this));
        //no slippage for small swaps
        _swapToken(collateral, _bnpl, 0, feesAccrued);
    }

    /*
     * Make a loan payment
     */
    function makeLoanPayment(uint256 loanId)
        external
        ensurePrincipalRemaining(loanId)
    {
        Loan storage loan = idToLoan[loanId];
        uint256 paymentAmount = getNextPayment(loanId);
        uint256 interestPortion = (loan.principalRemaining *
            loan.interestRate) / 10000;
        address _baseToken = baseToken;
        loan.paymentsMade++;
        //reduce accounts receiveable and loan principal if principal + interest payment
        bool finalPayment = loan.paymentsMade == loan.numberOfPayments;

        if (!loan.interestOnly) {
            uint256 principalPortion = paymentAmount - interestPortion;
            loan.principalRemaining -= principalPortion;
            accountsReceiveable -= principalPortion;
        } else {
            //interest only, principal change only on final payment
            if (finalPayment) {
                accountsReceiveable -= loan.principalRemaining;
                loan.principalRemaining = 0;
            }
        }
        //make payment
        TransferHelper.safeTransferFrom(
            _baseToken,
            msg.sender,
            address(this),
            paymentAmount
        );
        //deposit the tokens into AAVE on behalf of the pool contract, withholding 30% and the interest as baseToken
        _depositToLendingPool(
            _baseToken,
            paymentAmount - ((interestPortion * 3) / 10)
        );
        //remove if final payment
        if (finalPayment) {
            _removeCurrentLoan(loanId);
        }
        //increment the loan status

        emit loanPaymentMade(loanId);
    }

    /**
     * Repay remaining balance to save on interest cost
     * Payment amount is remaining principal + 1 period of interest
     */
    function repayEarly(uint256 loanId)
        external
        ensurePrincipalRemaining(loanId)
    {
        Loan storage loan = idToLoan[loanId];
        uint256 principalLeft = loan.principalRemaining;
        //make a payment of remaining principal + 1 period of interest
        uint256 interestAmount = (principalLeft * loan.interestRate) / 10000;
        uint256 paymentAmount = principalLeft + interestAmount;
        address _baseToken = baseToken;

        //update accounts
        accountsReceiveable -= principalLeft;
        loan.principalRemaining = 0;
        //increment the loan status to final and remove from current loans array
        loan.paymentsMade = loan.numberOfPayments;
        _removeCurrentLoan(loanId);

        //make payment
        TransferHelper.safeTransferFrom(
            _baseToken,
            msg.sender,
            address(this),
            paymentAmount
        );
        //deposit withholding 30% of the interest as fees
        _depositToLendingPool(
            _baseToken,
            paymentAmount - ((interestAmount * 3) / 10)
        );

        emit loanRepaidEarly(loanId);
    }

    /**
     * Converts the baseToken (e.g. USDT) 20% BNPL for stakers, and sends 10% to the Banking Node Operator
     * Slippage set to 0 here as they would be small purchases of BNPL
     */
    function collectFees() external {
        //requirement check for nonzero inside of _swap
        //33% to go to operator as baseToken
        address _baseToken = baseToken;
        address _bnpl = BNPL;
        address _operator = operator;
        uint256 _operatorFees = IERC20(_baseToken).balanceOf(address(this)) / 3;
        TransferHelper.safeTransfer(_baseToken, _operator, _operatorFees);
        //remainder (67%) is traded for staking rewards
        //no need for slippage on small trade
        uint256 _stakingRewards = _swapToken(
            _baseToken,
            _bnpl,
            0,
            IERC20(_baseToken).balanceOf(address(this))
        );
        emit feesCollected(_operatorFees, _stakingRewards);
    }

    /**
     * Deposit liquidity to the banking node in the baseToken (e.g. usdt) specified
     * Mints tokens, with check on decimals of base tokens
     */
    function deposit(uint256 _amount)
        external
        ensureNodeActive
        nonZeroInput(_amount)
    {
        //First deposit must be at least 10M wei to prevent initial attack
        if (getTotalAssetValue() == 0 && _amount < 10000000) {
            revert InvalidInitialDeposit();
        }
        //check the decimals of the baseTokens
        address _baseToken = baseToken;
        uint256 decimalAdjust = 1;
        uint256 tokenDecimals = ERC20(_baseToken).decimals();
        if (tokenDecimals != 18) {
            decimalAdjust = 10**(18 - tokenDecimals);
        }
        //get the amount of tokens to mint
        uint256 what = _amount * decimalAdjust;
        if (totalSupply() != 0) {
            //no need to decimal adjust here as total asset value adjusts
            //unable to deposit if getTotalAssetValue() == 0 and totalSupply() != 0, but this
            //should never occur as defaults will get slashed for some base token recovery
            what = (_amount * totalSupply()) / getTotalAssetValue();
        }
        //transfer tokens from the user and mint
        TransferHelper.safeTransferFrom(
            _baseToken,
            msg.sender,
            address(this),
            _amount
        );
        _mint(msg.sender, what);

        _depositToLendingPool(_baseToken, _amount);

        emit baseTokenDeposit(msg.sender, _amount);
    }

    /**
     * Withdraw liquidity from the banking node
     * To avoid need to decimal adjust, input _amount is in USDT(or equiv) to withdraw
     * , not BNPL USD to burn
     */
    function withdraw(uint256 _amount) external nonZeroInput(_amount) {
        uint256 userBaseBalance = getBaseTokenBalance(msg.sender);
        if (userBaseBalance < _amount) {
            revert InsufficientBalance();
        }
        //safe div, if _amount > 0, asset value always >0;
        uint256 what = (_amount * totalSupply()) / getTotalAssetValue();
        address _baseToken = baseToken;
        _burn(msg.sender, what);
        //non-zero revert with checked in "_withdrawFromLendingPool"
        _withdrawFromLendingPool(_baseToken, _amount, msg.sender);

        emit baseTokenWithdrawn(msg.sender, _amount);
    }

    /**
     * Stake BNPL into a node
     */
    function stake(uint256 _amount)
        external
        ensureNodeActive
        nonZeroInput(_amount)
    {
        address staker = msg.sender;
        //factory initial bond counted as operator
        if (msg.sender == bnplFactory) {
            staker = operator;
        }
        //calcualte the number of shares to give
        uint256 what = _amount;
        uint256 _totalStakingShares = totalStakingShares;
        if (_totalStakingShares > 0) {
            //edge case - if totalStakingShares != 0, but all bnpl has been slashed:
            //node will require a donation to work again
            uint256 totalStakedBNPL = getStakedBNPL();
            if (totalStakedBNPL == 0) {
                revert DonationRequired();
            }
            what = (_amount * _totalStakingShares) / totalStakedBNPL;
        }
        //collect the BNPL
        address _bnpl = BNPL;
        TransferHelper.safeTransferFrom(
            _bnpl,
            msg.sender,
            address(this),
            _amount
        );
        //issue the shares
        stakingShares[staker] += what;
        totalStakingShares += what;

        emit bnplStaked(msg.sender, _amount);
    }

    /**
     * Unbond BNPL from a node, input is the number shares (sBNPL)
     * Requires a 7 day unbond to prevent frontrun of slashing events or interest repayments
     * Operator can not unstake unless there are no loans active
     */
    function initiateUnstake(uint256 _amount) external nonZeroInput(_amount) {
        //operator cannot withdraw unless there are no active loans
        address _operator = operator;
        if (msg.sender == _operator && currentLoans.length > 0) {
            revert ActiveLoansOngoing();
        }
        uint256 stakingSharesUser = stakingShares[msg.sender];
        //require the user has enough
        if (stakingShares[msg.sender] < _amount) {
            revert InsufficientBalance();
        }
        //set the time of the unbond
        unbondBlock[msg.sender] = block.number;
        //get the amount of BNPL to issue back
        //safe div: if user staking shares >0, totalStakingShares always > 0
        uint256 what = (_amount * getStakedBNPL()) / totalStakingShares;
        //subtract the number of shares of BNPL from the user
        stakingShares[msg.sender] -= _amount;
        totalStakingShares -= _amount;
        //initiate as 1:1 for unbonding shares with BNPL sent
        uint256 _newUnbondingShares = what;
        uint256 _unbondingAmount = unbondingAmount;
        //update amount if there is a pool of unbonding
        if (_unbondingAmount != 0) {
            _newUnbondingShares =
                (what * totalUnbondingShares) /
                _unbondingAmount;
        }
        //add the balance to their unbonding
        unbondingShares[msg.sender] += _newUnbondingShares;
        totalUnbondingShares += _newUnbondingShares;
        unbondingAmount += what;

        emit unbondingInitiated(msg.sender, _amount);
    }

    /**
     * Withdraw BNPL from a bond once unbond period ends
     * Unbonding period is 46523 blocks (~7 days assuming a 13s avg. block time)
     */
    function unstake() external {
        uint256 _userAmount = unbondingShares[msg.sender];
        if (_userAmount == 0) {
            revert ZeroInput();
        }
        //assuming 13s block, 46523 blocks for 1 week
        if (block.number < unbondBlock[msg.sender] + 46523) {
            revert LoanStillUnbonding();
        }
        uint256 _unbondingAmount = unbondingAmount;
        uint256 _totalUnbondingShares = totalUnbondingShares;
        address _bnpl = BNPL;
        //safe div: if user amount > 0, then totalUnbondingShares always > 0
        uint256 _what = (_userAmount * _unbondingAmount) /
            _totalUnbondingShares;
        //update the balances
        unbondingShares[msg.sender] = 0;
        unbondingAmount -= _what;
        totalUnbondingShares -= _userAmount;

        //transfer the tokens to user
        TransferHelper.safeTransfer(_bnpl, msg.sender, _what);
        emit bnplWithdrawn(msg.sender, _what);
    }

    /**
     * Declare a loan defaulted and slash the loan
     * Can be called by anyone
     * Move BNPL to a slashing balance, to be sold in seperate function
     * minOut used for sale of collateral, if no collateral, put 0
     */
    function slashLoan(uint256 loanId, uint256 minOut)
        external
        ensurePrincipalRemaining(loanId)
    {
        //Step 1. load loan as local variable
        Loan storage loan = idToLoan[loanId];

        //Step 2. requirement checks: loan is ongoing and expired past grace period
        if (loan.isSlashed) {
            revert LoanAlreadySlashed();
        }
        if (block.timestamp <= getNextDueDate(loanId) + gracePeriod) {
            revert LoanNotExpired();
        }

        //Step 3, Check if theres any collateral to slash
        uint256 _collateralPosted = loan.collateralAmount;
        uint256 baseTokenOut = 0;
        address _baseToken = baseToken;
        if (_collateralPosted > 0) {
            //Step 3a. load local variables
            address _collateral = loan.collateral;

            //Step 3b. update the colleral owed and loan amounts
            collateralOwed[_collateral] -= _collateralPosted;
            loan.collateralAmount = 0;

            //Step 3c. withdraw collateral from aave
            _withdrawFromLendingPool(
                _collateral,
                _collateralPosted,
                address(this)
            );
            //Step 3d. sell collateral for baseToken
            baseTokenOut = _swapToken(
                _collateral,
                _baseToken,
                minOut,
                _collateralPosted
            );
            //Step 3e. deposit the recovered baseTokens to aave
            _depositToLendingPool(_baseToken, baseTokenOut);
        }
        //Step 4. calculate the amount to be slashed
        uint256 principalLost = loan.principalRemaining;
        //Check if there was a full recovery for the loan, if so
        if (baseTokenOut >= principalLost) {
            //return excess to the lender (if any)
            _withdrawFromLendingPool(
                _baseToken,
                baseTokenOut - principalLost,
                loan.borrower
            );
        }
        //slash loan only if losses are greater than recovered
        else {
            principalLost -= baseTokenOut;
            //safe div: principal > 0 => totalassetvalue > 0
            uint256 slashPercent = (1e12 * principalLost) /
                getTotalAssetValue();
            uint256 unbondingSlash = (unbondingAmount * slashPercent) / 1e12;
            uint256 stakingSlash = (getStakedBNPL() * slashPercent) / 1e12;
            //Step 5. deduct slashed from respective balances
            accountsReceiveable -= principalLost;
            slashingBalance += unbondingSlash + stakingSlash;
            unbondingAmount -= unbondingSlash;
        }

        //Step 6. remove loan from currentLoans and add to defaulted loans
        defaultedLoans[defaultedLoanCount] = loanId;
        defaultedLoanCount++;

        loan.isSlashed = true;
        _removeCurrentLoan(loanId);
        emit loanSlashed(loanId);
    }

    /**
     * Sell the slashing balance of BNPL to give to lenders as <aBaseToken>
     * Slashing sale moved to seperate function to simplify logic with minOut
     */
    function sellSlashed(uint256 minOut) external {
        //Step 1. load local variables
        address _baseToken = baseToken;
        address _bnpl = BNPL;
        uint256 _slashingBalance = slashingBalance;
        //Step 2. check there is a balance to sell
        if (_slashingBalance == 0) {
            revert ZeroInput();
        }
        //Step 3. sell the slashed BNPL for baseToken
        uint256 baseTokenOut = _swapToken(
            _bnpl,
            _baseToken,
            minOut,
            _slashingBalance
        );
        //Step 4. deposit baseToken received to aave and update slashing balance
        slashingBalance = 0;
        _depositToLendingPool(_baseToken, baseTokenOut);

        emit slashingSale(_slashingBalance, baseTokenOut);
    }

    /**
     * Donate baseToken for when debt is collected post default
     * BNPL can be donated by simply sending it to the contract
     */
    function donateBaseToken(uint256 _amount) external nonZeroInput(_amount) {
        //Step 1. load local variables
        address _baseToken = baseToken;
        //Step 2. collect the baseTokens
        TransferHelper.safeTransferFrom(
            _baseToken,
            msg.sender,
            address(this),
            _amount
        );
        //Step 3. deposit baseToken to aave
        _depositToLendingPool(_baseToken, _amount);

        emit baseTokensDonated(_amount);
    }

    //OPERATOR ONLY FUNCTIONS

    /**
     * Approve a pending loan request
     * Ensures collateral amount has been posted to prevent front run withdrawal
     */
    function approveLoan(uint256 loanId, uint256 requiredCollateralAmount)
        external
        operatorOnly
    {
        Loan storage loan = idToLoan[loanId];
        uint256 length = pendingRequests.length;
        uint256 loanSize = loan.loanAmount;
        address _baseToken = baseToken;

        if (getBNPLBalance(operator) < 0x13DA329B6336471800000) {
            revert NodeInactive();
        }
        //ensure the loan was never started and collateral enough
        if (loan.loanStartTime > 0) {
            revert LoanAlreadyStarted();
        }
        if (loan.collateralAmount < requiredCollateralAmount) {
            revert InsufficientCollateral();
        }

        //remove from loanRequests and add loan to current loans

        for (uint256 i = 0; i < length; i++) {
            if (loanId == pendingRequests[i]) {
                pendingRequests[i] = pendingRequests[length - 1];
                pendingRequests.pop();
                break;
            }
        }

        currentLoans.push(loanId);

        //add the principal remaining and start the loan

        loan.principalRemaining = loanSize;
        loan.loanStartTime = block.timestamp;
        accountsReceiveable += loanSize;
        //send the funds and update accounts (minus 0.5% origination fee)

        _withdrawFromLendingPool(
            _baseToken,
            (loanSize * 199) / 200,
            loan.borrower
        );
        //send the 0.25% origination fee to treasury and agent
        _withdrawFromLendingPool(_baseToken, loanSize / 400, treasury);
        _withdrawFromLendingPool(
            _baseToken,
            loanSize / 400,
            loanToAgent[loanId]
        );

        emit approvedLoan(loanId);
    }

    /**
     * Used to reject all current pending loan requests
     */
    function clearPendingLoans() external operatorOnly {
        pendingRequests = new uint256[](0);
    }

    /**
     * Whitelist or delist a given list of addresses
     * Only relevant on KYC nodes
     */
    function whitelistAddresses(
        address[] memory whitelistAddition,
        bool _status
    ) external operatorOnly {
        uint256 length = whitelistAddition.length;
        for (uint256 i; i < length; i++) {
            address newWhistelist = whitelistAddition[i];
            whitelistedAddresses[newWhistelist] = _status;
        }
    }

    /**
     * Updates the KYC Status of a node
     */
    function setKYC(bool _newStatus) external operatorOnly {
        requireKYC = _newStatus;
        emit KYCRequirementChanged(_newStatus);
    }

    //PRIVATE FUNCTIONS

    /**
     * Deposit token onto AAVE lending pool, receiving aTokens in return
     */
    function _depositToLendingPool(address tokenIn, uint256 amountIn) private {
        address _lendingPool = address(_getLendingPool());
        TransferHelper.safeApprove(tokenIn, _lendingPool, 0);
        TransferHelper.safeApprove(tokenIn, _lendingPool, amountIn);
        _getLendingPool().deposit(tokenIn, amountIn, address(this), 0);
    }

    /**
     * Withdraw token from AAVE lending pool, converting from aTokens to ERC20 equiv
     */
    function _withdrawFromLendingPool(
        address tokenOut,
        uint256 amountOut,
        address to
    ) private nonZeroInput(amountOut) {
        _getLendingPool().withdraw(tokenOut, amountOut, to);
    }

    /**
     * Get the latest AAVE Lending Pool contract
     */
    function _getLendingPool() private view returns (ILendingPool) {
        return ILendingPool(lendingPoolProvider.getLendingPool());
    }

    /**
     * Remove given loan from current loan list
     */
    function _removeCurrentLoan(uint256 loanId) private {
        for (uint256 i = 0; i < currentLoans.length; i++) {
            if (loanId == currentLoans[i]) {
                currentLoans[i] = currentLoans[currentLoans.length - 1];
                currentLoans.pop();
                return;
            }
        }
    }

    /**
     * Swaps given token, with path of length 3, tokenIn => WETH => tokenOut
     * Uses Sushiswap pairs only
     * Ensures slippage with minOut
     */
    function _swapToken(
        address tokenIn,
        address tokenOut,
        uint256 minOut,
        uint256 amountIn
    ) private returns (uint256 tokenOutput) {
        if (amountIn == 0) {
            revert ZeroInput();
        }
        //Step 1. load data to local variables
        address _uniswapFactory = uniswapFactory;
        address _weth = WETH;
        address pair1 = UniswapV2Library.pairFor(
            _uniswapFactory,
            tokenIn,
            _weth
        );
        address pair2 = UniswapV2Library.pairFor(
            _uniswapFactory,
            _weth,
            tokenOut
        );
        //if tokenIn = weth, only need to swap with pair2 with amountIn as input
        if (tokenIn == _weth) {
            pair1 = pair2;
            tokenOutput = amountIn;
        }
        //Step 2. transfer the tokens to first pair (pair 2 if tokenIn == weth)
        TransferHelper.safeTransfer(tokenIn, pair1, amountIn);
        //Step 3. Swap tokenIn to WETH (only if tokenIn != weth)
        if (tokenIn != _weth) {
            tokenOutput = _swap(tokenIn, _weth, amountIn, pair1, pair2);
        }
        //Step 4. Swap ETH for tokenOut
        tokenOutput = _swap(_weth, tokenOut, tokenOutput, pair2, address(this));
        //Step 5. Check slippage parameters
        if (minOut > tokenOutput) {
            revert InsufficentOutput();
        }
    }

    /**
     * Helper function for _swapToken
     * Modified from uniswap router to save gas, makes a single trade
     * with uniswap pair without needing address[] path or uit256[] amounts
     */
    function _swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        address pair,
        address to
    ) private returns (uint256 tokenOutput) {
        address _uniswapFactory = uniswapFactory;
        //Step 1. get the reserves of each token
        (uint256 reserveIn, uint256 reserveOut) = UniswapV2Library.getReserves(
            _uniswapFactory,
            tokenIn,
            tokenOut
        );
        //Step 2. get the tokens that will be received
        tokenOutput = UniswapV2Library.getAmountOut(
            amountIn,
            reserveIn,
            reserveOut
        );
        //Step 3. sort the tokens to pass IUniswapV2Pair
        (address token0, ) = UniswapV2Library.sortTokens(tokenIn, tokenOut);
        (uint256 amount0Out, uint256 amount1Out) = tokenIn == token0
            ? (uint256(0), tokenOutput)
            : (tokenOutput, uint256(0));
        //Step 4. make the trade
        IUniswapV2Pair(pair).swap(amount0Out, amount1Out, to, new bytes(0));
    }

    //VIEW ONLY FUNCTIONS

    /**
     * Get the total BNPL in the staking account
     * Given by (total BNPL of node) - (unbonding balance) - (slashing balance)
     */
    function getStakedBNPL() public view returns (uint256) {
        return
            IERC20(BNPL).balanceOf(address(this)) -
            unbondingAmount -
            slashingBalance;
    }

    /**
     * Gets the given users balance in baseToken
     */
    function getBaseTokenBalance(address user) public view returns (uint256) {
        uint256 _balance = balanceOf(user);
        if (totalSupply() == 0) {
            return 0;
        }
        return (_balance * getTotalAssetValue()) / totalSupply();
    }

    /**
     * Get the value of the BNPL staked by user
     * Given by (user's shares) * (total BNPL staked) / (total number of shares)
     */
    function getBNPLBalance(address user) public view returns (uint256 what) {
        uint256 _balance = stakingShares[user];
        uint256 _totalStakingShares = totalStakingShares;
        if (_totalStakingShares == 0) {
            what = 0;
        } else {
            what = (_balance * getStakedBNPL()) / _totalStakingShares;
        }
    }

    /**
     * Get the amount a user has that is being unbonded
     * Given by (user's unbonding shares) * (total unbonding BNPL) / (total unbonding shares)
     */
    function getUnbondingBalance(address user) external view returns (uint256) {
        uint256 _totalUnbondingShares = totalUnbondingShares;
        uint256 _userUnbondingShare = unbondingShares[user];
        if (_totalUnbondingShares == 0) {
            return 0;
        }
        return (_userUnbondingShare * unbondingAmount) / _totalUnbondingShares;
    }

    /**
     * Gets the next payment amount due
     * If loan is completed or not approved, returns 0
     */
    function getNextPayment(uint256 loanId) public view returns (uint256) {
        //if loan is completed or not approved, return 0
        Loan storage loan = idToLoan[loanId];
        if (loan.principalRemaining == 0) {
            return 0;
        }
        uint256 _interestRate = loan.interestRate;
        uint256 _loanAmount = loan.loanAmount;
        uint256 _numberOfPayments = loan.numberOfPayments;
        //check if it is an interest only loan
        if (loan.interestOnly) {
            //check if its the final payment
            if (loan.paymentsMade + 1 == _numberOfPayments) {
                //if final payment, then principal + final interest amount
                return _loanAmount + ((_loanAmount * _interestRate) / 10000);
            } else {
                //if not final payment, simple interest amount
                return (_loanAmount * _interestRate) / 10000;
            }
        } else {
            //principal + interest payments, payment given by the formula:
            //p : principal
            //i : interest rate per period
            //d : duration
            // p * (i * (1+i) ** d) / ((1+i) ** d - 1)
            uint256 numerator = _loanAmount *
                _interestRate *
                (10000 + _interestRate)**_numberOfPayments;
            uint256 denominator = (10000 + _interestRate)**_numberOfPayments -
                (10**(4 * _numberOfPayments));
            return numerator / (denominator * 10000);
        }
    }

    /**
     * Gets the next due date (unix timestamp) of a given loan
     * Returns 0 if loan is not a current loan or loan has already been paid
     */
    function getNextDueDate(uint256 loanId) public view returns (uint256) {
        //check that the loan has been approved and loan is not completed;
        Loan storage loan = idToLoan[loanId];
        if (loan.principalRemaining == 0) {
            return 0;
        }
        return
            loan.loanStartTime +
            ((loan.paymentsMade + 1) * loan.paymentInterval);
    }

    /**
     * Get the total assets (accounts receivable + aToken balance)
     * Only principal owed is counted as accounts receivable
     */
    function getTotalAssetValue() public view returns (uint256) {
        return
            IERC20(_getLendingPool().getReserveData(baseToken).aTokenAddress)
                .balanceOf(address(this)) + accountsReceiveable;
    }

    /**
     * Get number of pending requests
     */
    function getPendingRequestCount() external view returns (uint256) {
        return pendingRequests.length;
    }

    /**
     * Get the current number of active loans
     */
    function getCurrentLoansCount() external view returns (uint256) {
        return currentLoans.length;
    }

    /**
     * Get the total Losses occurred
     */
    function getTotalDefaultLoss() external view returns (uint256) {
        uint256 totalLosses = 0;
        for (uint256 i; i < defaultedLoanCount; i++) {
            Loan storage loan = idToLoan[defaultedLoans[i]];
            totalLosses += loan.principalRemaining;
        }
        return totalLosses;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC20.sol";
import "IERC20Metadata.sol";
import "Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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

pragma solidity ^0.8.0;

import "Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import {ILendingPoolAddressesProvider} from "ILendingPoolAddressesProvider.sol";
import {DataTypes} from "DataTypes.sol";

interface ILendingPool {
    /**
     * @dev Emitted on deposit()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address initiating the deposit
     * @param onBehalfOf The beneficiary of the deposit, receiving the aTokens
     * @param amount The amount deposited
     * @param referral The referral code used
     **/
    event Deposit(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint16 indexed referral
    );

    /**
     * @dev Emitted on withdraw()
     * @param reserve The address of the underlyng asset being withdrawn
     * @param user The address initiating the withdrawal, owner of aTokens
     * @param to Address that will receive the underlying
     * @param amount The amount to be withdrawn
     **/
    event Withdraw(
        address indexed reserve,
        address indexed user,
        address indexed to,
        uint256 amount
    );

    /**
     * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
     * @param reserve The address of the underlying asset being borrowed
     * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
     * initiator of the transaction on flashLoan()
     * @param onBehalfOf The address that will be getting the debt
     * @param amount The amount borrowed out
     * @param borrowRateMode The rate mode: 1 for Stable, 2 for Variable
     * @param borrowRate The numeric rate at which the user has borrowed
     * @param referral The referral code used
     **/
    event Borrow(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint256 borrowRateMode,
        uint256 borrowRate,
        uint16 indexed referral
    );

    /**
     * @dev Emitted on repay()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The beneficiary of the repayment, getting his debt reduced
     * @param repayer The address of the user initiating the repay(), providing the funds
     * @param amount The amount repaid
     **/
    event Repay(
        address indexed reserve,
        address indexed user,
        address indexed repayer,
        uint256 amount
    );

    /**
     * @dev Emitted on swapBorrowRateMode()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user swapping his rate mode
     * @param rateMode The rate mode that the user wants to swap to
     **/
    event Swap(address indexed reserve, address indexed user, uint256 rateMode);

    /**
     * @dev Emitted on setUserUseReserveAsCollateral()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user enabling the usage as collateral
     **/
    event ReserveUsedAsCollateralEnabled(
        address indexed reserve,
        address indexed user
    );

    /**
     * @dev Emitted on setUserUseReserveAsCollateral()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user enabling the usage as collateral
     **/
    event ReserveUsedAsCollateralDisabled(
        address indexed reserve,
        address indexed user
    );

    /**
     * @dev Emitted on rebalanceStableBorrowRate()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user for which the rebalance has been executed
     **/
    event RebalanceStableBorrowRate(
        address indexed reserve,
        address indexed user
    );

    /**
     * @dev Emitted on flashLoan()
     * @param target The address of the flash loan receiver contract
     * @param initiator The address initiating the flash loan
     * @param asset The address of the asset being flash borrowed
     * @param amount The amount flash borrowed
     * @param premium The fee flash borrowed
     * @param referralCode The referral code used
     **/
    event FlashLoan(
        address indexed target,
        address indexed initiator,
        address indexed asset,
        uint256 amount,
        uint256 premium,
        uint16 referralCode
    );

    /**
     * @dev Emitted when the pause is triggered.
     */
    event Paused();

    /**
     * @dev Emitted when the pause is lifted.
     */
    event Unpaused();

    /**
     * @dev Emitted when a borrower is liquidated. This event is emitted by the LendingPool via
     * LendingPoolCollateral manager using a DELEGATECALL
     * This allows to have the events in the generated ABI for LendingPool.
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param liquidatedCollateralAmount The amount of collateral received by the liiquidator
     * @param liquidator The address of the liquidator
     * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     **/
    event LiquidationCall(
        address indexed collateralAsset,
        address indexed debtAsset,
        address indexed user,
        uint256 debtToCover,
        uint256 liquidatedCollateralAmount,
        address liquidator,
        bool receiveAToken
    );

    /**
     * @dev Emitted when the state of a reserve is updated. NOTE: This event is actually declared
     * in the ReserveLogic library and emitted in the updateInterestRates() function. Since the function is internal,
     * the event will actually be fired by the LendingPool contract. The event is therefore replicated here so it
     * gets added to the LendingPool ABI
     * @param reserve The address of the underlying asset of the reserve
     * @param liquidityRate The new liquidity rate
     * @param stableBorrowRate The new stable borrow rate
     * @param variableBorrowRate The new variable borrow rate
     * @param liquidityIndex The new liquidity index
     * @param variableBorrowIndex The new variable borrow index
     **/
    event ReserveDataUpdated(
        address indexed reserve,
        uint256 liquidityRate,
        uint256 stableBorrowRate,
        uint256 variableBorrowRate,
        uint256 liquidityIndex,
        uint256 variableBorrowIndex
    );

    /**
     * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
     * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
     * @param asset The address of the underlying asset to deposit
     * @param amount The amount to be deposited
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /**
     * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
     * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
     * @param asset The address of the underlying asset to withdraw
     * @param amount The underlying amount to be withdrawn
     *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
     * @param to Address that will receive the underlying, same as msg.sender if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     * @return The final amount withdrawn
     **/
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);

    /**
     * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
     * already deposited enough collateral, or he was given enough allowance by a credit delegator on the
     * corresponding debt token (StableDebtToken or VariableDebtToken)
     * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
     *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
     * @param asset The address of the underlying asset to borrow
     * @param amount The amount to be borrowed
     * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     * @param onBehalfOf Address of the user who will receive the debt. Should be the address of the borrower itself
     * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
     * if he has been given credit delegation allowance
     **/
    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external;

    /**
     * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
     * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
     * @param rateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
     * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
     * user calling the function if he wants to reduce/remove his own debt, or the address of any other
     * other borrower whose debt should be removed
     * @return The final amount repaid
     **/
    function repay(
        address asset,
        uint256 amount,
        uint256 rateMode,
        address onBehalfOf
    ) external returns (uint256);

    /**
     * @dev Allows a borrower to swap his debt between stable and variable mode, or viceversa
     * @param asset The address of the underlying asset borrowed
     * @param rateMode The rate mode that the user wants to swap to
     **/
    function swapBorrowRateMode(address asset, uint256 rateMode) external;

    /**
     * @dev Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
     * - Users can be rebalanced if the following conditions are satisfied:
     *     1. Usage ratio is above 95%
     *     2. the current deposit APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too much has been
     *        borrowed at a stable rate and depositors are not earning enough
     * @param asset The address of the underlying asset borrowed
     * @param user The address of the user to be rebalanced
     **/
    function rebalanceStableBorrowRate(address asset, address user) external;

    /**
     * @dev Allows depositors to enable/disable a specific deposited asset as collateral
     * @param asset The address of the underlying asset deposited
     * @param useAsCollateral `true` if the user wants to use the deposit as collateral, `false` otherwise
     **/
    function setUserUseReserveAsCollateral(address asset, bool useAsCollateral)
        external;

    /**
     * @dev Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
     * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
     *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     **/
    function liquidationCall(
        address collateralAsset,
        address debtAsset,
        address user,
        uint256 debtToCover,
        bool receiveAToken
    ) external;

    /**
     * @dev Allows smartcontracts to access the liquidity of the pool within one transaction,
     * as long as the amount taken plus a fee is returned.
     * IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept into consideration.
     * For further details please visit https://developers.aave.com
     * @param receiverAddress The address of the contract receiving the funds, implementing the IFlashLoanReceiver interface
     * @param assets The addresses of the assets being flash-borrowed
     * @param amounts The amounts amounts being flash-borrowed
     * @param modes Types of the debt to open if the flash loan is not returned:
     *   0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
     *   1 -> Open debt at stable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
     *   2 -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
     * @param onBehalfOf The address  that will receive the debt in the case of using on `modes` 1 or 2
     * @param params Variadic packed params to pass to the receiver as extra information
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata modes,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    ) external;

    /**
     * @dev Returns the user account data across all the reserves
     * @param user The address of the user
     * @return totalCollateralETH the total collateral in ETH of the user
     * @return totalDebtETH the total debt in ETH of the user
     * @return availableBorrowsETH the borrowing power left of the user
     * @return currentLiquidationThreshold the liquidation threshold of the user
     * @return ltv the loan to value of the user
     * @return healthFactor the current health factor of the user
     **/
    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateralETH,
            uint256 totalDebtETH,
            uint256 availableBorrowsETH,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );

    function initReserve(
        address reserve,
        address aTokenAddress,
        address stableDebtAddress,
        address variableDebtAddress,
        address interestRateStrategyAddress
    ) external;

    function setReserveInterestRateStrategyAddress(
        address reserve,
        address rateStrategyAddress
    ) external;

    function setConfiguration(address reserve, uint256 configuration) external;

    /**
     * @dev Returns the configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The configuration of the reserve
     **/
    function getConfiguration(address asset)
        external
        view
        returns (DataTypes.ReserveConfigurationMap memory);

    /**
     * @dev Returns the configuration of the user across all the reserves
     * @param user The user address
     * @return The configuration of the user
     **/
    function getUserConfiguration(address user)
        external
        view
        returns (DataTypes.UserConfigurationMap memory);

    /**
     * @dev Returns the normalized income normalized income of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve's normalized income
     */
    function getReserveNormalizedIncome(address asset)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the normalized variable debt per unit of asset
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve normalized variable debt
     */
    function getReserveNormalizedVariableDebt(address asset)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the state and configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The state of the reserve
     **/
    function getReserveData(address asset)
        external
        view
        returns (DataTypes.ReserveData memory);

    function finalizeTransfer(
        address asset,
        address from,
        address to,
        uint256 amount,
        uint256 balanceFromAfter,
        uint256 balanceToBefore
    ) external;

    function getReservesList() external view returns (address[] memory);

    function getAddressesProvider()
        external
        view
        returns (ILendingPoolAddressesProvider);

    function setPause(bool val) external;

    function paused() external view returns (bool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

/**
 * @title LendingPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Aave Governance
 * @author Aave
 **/
interface ILendingPoolAddressesProvider {
    event MarketIdSet(string newMarketId);
    event LendingPoolUpdated(address indexed newAddress);
    event ConfigurationAdminUpdated(address indexed newAddress);
    event EmergencyAdminUpdated(address indexed newAddress);
    event LendingPoolConfiguratorUpdated(address indexed newAddress);
    event LendingPoolCollateralManagerUpdated(address indexed newAddress);
    event PriceOracleUpdated(address indexed newAddress);
    event LendingRateOracleUpdated(address indexed newAddress);
    event ProxyCreated(bytes32 id, address indexed newAddress);
    event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);

    function getMarketId() external view returns (string memory);

    function setMarketId(string calldata marketId) external;

    function setAddress(bytes32 id, address newAddress) external;

    function setAddressAsProxy(bytes32 id, address impl) external;

    function getAddress(bytes32 id) external view returns (address);

    function getLendingPool() external view returns (address);

    function setLendingPoolImpl(address pool) external;

    function getLendingPoolConfigurator() external view returns (address);

    function setLendingPoolConfiguratorImpl(address configurator) external;

    function getLendingPoolCollateralManager() external view returns (address);

    function setLendingPoolCollateralManager(address manager) external;

    function getPoolAdmin() external view returns (address);

    function setPoolAdmin(address admin) external;

    function getEmergencyAdmin() external view returns (address);

    function setEmergencyAdmin(address admin) external;

    function getPriceOracle() external view returns (address);

    function setPriceOracle(address priceOracle) external;

    function getLendingRateOracle() external view returns (address);

    function setLendingRateOracle(address lendingRateOracle) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

library DataTypes {
    // refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
    struct ReserveData {
        //stores the reserve configuration
        ReserveConfigurationMap configuration;
        //the liquidity index. Expressed in ray
        uint128 liquidityIndex;
        //variable borrow index. Expressed in ray
        uint128 variableBorrowIndex;
        //the current supply rate. Expressed in ray
        uint128 currentLiquidityRate;
        //the current variable borrow rate. Expressed in ray
        uint128 currentVariableBorrowRate;
        //the current stable borrow rate. Expressed in ray
        uint128 currentStableBorrowRate;
        uint40 lastUpdateTimestamp;
        //tokens addresses
        address aTokenAddress;
        address stableDebtTokenAddress;
        address variableDebtTokenAddress;
        //address of the interest rate strategy
        address interestRateStrategyAddress;
        //the id of the reserve. Represents the position in the list of the active reserves
        uint8 id;
    }

    struct ReserveConfigurationMap {
        //bit 0-15: LTV
        //bit 16-31: Liq. threshold
        //bit 32-47: Liq. bonus
        //bit 48-55: Decimals
        //bit 56: Reserve is active
        //bit 57: reserve is frozen
        //bit 58: borrowing is enabled
        //bit 59: stable rate borrowing enabled
        //bit 60-63: reserved
        //bit 64-79: reserve factor
        uint256 data;
    }

    struct UserConfigurationMap {
        uint256 data;
    }

    enum InterestRateMode {
        NONE,
        STABLE,
        VARIABLE
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

pragma experimental ABIEncoderV2;

import {IAaveDistributionManager} from "IAaveDistributionManager.sol";

interface IAaveIncentivesController is IAaveDistributionManager {
    event RewardsAccrued(address indexed user, uint256 amount);

    event RewardsClaimed(
        address indexed user,
        address indexed to,
        address indexed claimer,
        uint256 amount
    );

    event ClaimerSet(address indexed user, address indexed claimer);

    /**
     * @dev Whitelists an address to claim the rewards on behalf of another address
     * @param user The address of the user
     * @param claimer The address of the claimer
     */
    function setClaimer(address user, address claimer) external;

    /**
     * @dev Returns the whitelisted claimer for a certain address (0x0 if not set)
     * @param user The address of the user
     * @return The claimer address
     */
    function getClaimer(address user) external view returns (address);

    /**
     * @dev Configure assets for a certain rewards emission
     * @param assets The assets to incentivize
     * @param emissionsPerSecond The emission for each asset
     */
    function configureAssets(
        address[] calldata assets,
        uint256[] calldata emissionsPerSecond
    ) external;

    /**
     * @dev Called by the corresponding asset on any update that affects the rewards distribution
     * @param asset The address of the user
     * @param userBalance The balance of the user of the asset in the lending pool
     * @param totalSupply The total supply of the asset in the lending pool
     **/
    function handleAction(
        address asset,
        uint256 userBalance,
        uint256 totalSupply
    ) external;

    /**
     * @dev Returns the total of rewards of an user, already accrued + not yet accrued
     * @param user The address of the user
     * @return The rewards
     **/
    function getRewardsBalance(address[] calldata assets, address user)
        external
        view
        returns (uint256);

    /**
     * @dev Claims reward for an user to the desired address, on all the assets of the lending pool, accumulating the pending rewards
     * @param amount Amount of rewards to claim
     * @param to Address that will be receiving the rewards
     * @return Rewards claimed
     **/
    function claimRewards(
        address[] calldata assets,
        uint256 amount,
        address to
    ) external returns (uint256);

    /**
     * @dev Claims reward for an user on behalf, on all the assets of the lending pool, accumulating the pending rewards. The caller must
     * be whitelisted via "allowClaimOnBehalf" function by the RewardsAdmin role manager
     * @param amount Amount of rewards to claim
     * @param user Address to check and claim rewards
     * @param to Address that will be receiving the rewards
     * @return Rewards claimed
     **/
    function claimRewardsOnBehalf(
        address[] calldata assets,
        uint256 amount,
        address user,
        address to
    ) external returns (uint256);

    /**
     * @dev Claims reward for msg.sender, on all the assets of the lending pool, accumulating the pending rewards
     * @param amount Amount of rewards to claim
     * @return Rewards claimed
     **/
    function claimRewardsToSelf(address[] calldata assets, uint256 amount)
        external
        returns (uint256);

    /**
     * @dev returns the unclaimed rewards of the user
     * @param user the address of the user
     * @return the unclaimed user rewards
     */
    function getUserUnclaimedRewards(address user)
        external
        view
        returns (uint256);

    /**
     * @dev for backward compatibility with previous implementation of the Incentives controller
     */
    function REWARD_TOKEN() external view returns (address);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import {DistributionTypes} from "DistributionTypes.sol";

interface IAaveDistributionManager {
    event AssetConfigUpdated(address indexed asset, uint256 emission);
    event AssetIndexUpdated(address indexed asset, uint256 index);
    event UserIndexUpdated(
        address indexed user,
        address indexed asset,
        uint256 index
    );
    event DistributionEndUpdated(uint256 newDistributionEnd);

    /**
     * @dev Sets the end date for the distribution
     * @param distributionEnd The end date timestamp
     **/
    function setDistributionEnd(uint256 distributionEnd) external;

    /**
     * @dev Gets the end date for the distribution
     * @return The end of the distribution
     **/
    function getDistributionEnd() external view returns (uint256);

    /**
     * @dev for backwards compatibility with the previous DistributionManager used
     * @return The end of the distribution
     **/
    function DISTRIBUTION_END() external view returns (uint256);

    /**
     * @dev Returns the data of an user on a distribution
     * @param user Address of the user
     * @param asset The address of the reference asset of the distribution
     * @return The new index
     **/
    function getUserAssetData(address user, address asset)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the configuration of the distribution for a certain asset
     * @param asset The address of the reference asset of the distribution
     * @return The asset index, the emission per second and the last updated timestamp
     **/
    function getAssetData(address asset)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

library DistributionTypes {
    struct AssetConfigInput {
        uint104 emissionPerSecond;
        uint256 totalStaked;
        address underlyingAsset;
    }

    struct UserStakeInput {
        address underlyingAsset;
        uint256 stakedByUser;
        uint256 totalStaked;
    }
}

pragma solidity >=0.5.0;

import "IUniswapV2Pair.sol";

import "SafeMath.sol";

library UniswapV2Library {
    using SafeMath for uint256;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(abi.encodePacked(token0, token1)),
                            // hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f" // init code hash
                            //mainnet hash for sushiSwap:
                            hex"e18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303"
                        )
                    )
                )
            )
        );
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(
            pairFor(factory, tokenA, tokenB)
        ).getReserves();
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "UniswapV2Library: INSUFFICIENT_AMOUNT");
        require(
            reserveA > 0 && reserveB > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        uint256 numerator = reserveIn.mul(amountOut).mul(1000);
        uint256 denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(
        address factory,
        uint256 amountIn,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(
                factory,
                path[i],
                path[i + 1]
            );
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(
        address factory,
        uint256 amountOut,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(
                factory,
                path[i - 1],
                path[i]
            );
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.6.6;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: APPROVE_FAILED"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FAILED"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FROM_FAILED"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }
}