// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Ownable.sol";
import "IERC20.sol";
import "BankingNode.sol";
import "TransferHelper.sol";

contract BNPLFactory is Ownable {
    mapping(address => address) operatorToNode;
    address[] public bankingNodesList;
    IERC20 public immutable BNPL;
    address public immutable lendingPoolAddressesProvider;
    address public immutable WETH;
    address public immutable uniswapFactory;
    mapping(address => bool) approvedBaseTokens;
    address public aaveDistributionController;

    //Constuctor
    constructor(
        IERC20 _BNPL,
        address _lendingPoolAddressesProvider,
        address _WETH,
        address _aaveDistributionController,
        address _uniswapFactory
    ) {
        BNPL = _BNPL;
        lendingPoolAddressesProvider = _lendingPoolAddressesProvider;
        WETH = _WETH;
        aaveDistributionController = _aaveDistributionController;
        uniswapFactory = _uniswapFactory;
    }

    //STATE CHANGING FUNCTIONS

    /**
     * Creates a new banking node
     */
    function createNewNode(
        IERC20 _baseToken,
        bool _requireKYC,
        uint256 _gracePeriod
    ) external returns (address node) {
        //collect the BNPL
        BNPL.transferFrom(msg.sender, address(this), 2000000 * 10**18);
        //require base token to be approve
        require(approvedBaseTokens[address(_baseToken)]);
        //create a new node
        bytes memory bytecode = type(BankingNode).creationCode;
        bytes32 salt = keccak256(
            abi.encodePacked(_baseToken, _requireKYC, _gracePeriod)
        );
        assembly {
            node := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        BankingNode(node).initialize(
            address(_baseToken),
            BNPL,
            _requireKYC,
            msg.sender,
            _gracePeriod,
            lendingPoolAddressesProvider,
            WETH,
            aaveDistributionController,
            uniswapFactory
        );
        BNPL.approve(node, 2000000 * 10**18);
        BankingNode(node).stake(2000000 * 10**18);
        bankingNodesList.push(msg.sender);
        operatorToNode[msg.sender] = node;
    }

    //ONLY OWNER FUNCTIONS

    /**
     * Whitelist a base token for banking nodes(e.g. USDC)
     */
    function whitelistToken(address _baseToken) external onlyOwner {
        approvedBaseTokens[_baseToken] = true;
    }

    //GETTOR FUNCTIONS

    /**
     * Get node address of a operator
     */
    function getNode(address _operator) external view returns (address) {
        return operatorToNode[_operator];
    }

    /**
     * Get number of current nodes
     */
    function bankingNodeCount() external view returns (uint256) {
        return bankingNodesList.length;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Context.sol";

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
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

import "ERC20.sol";
import "ILendingPool.sol";
import "ILendingPoolAddressesProvider.sol";
import "IAaveIncentivesController.sol";
import "UniswapV2Library.sol";
import "TransferHelper.sol";

contract BankingNode is ERC20("BNPL USD", "bUSD") {
    address public operator;

    ERC20 public baseToken; //base liquidity token, e.g. USDT or USDC
    uint256 public incrementor;
    uint256 public gracePeriod;
    bool requireKYC;

    address public treasury;

    address public uniswapFactory;
    IAaveIncentivesController public aaveRewardController;
    ILendingPoolAddressesProvider public lendingPoolProvider;
    address public WETH;
    address public immutable factory;

    //For loans
    mapping(uint256 => Loan) idToLoan;
    uint256[] public pendingRequests;
    uint256[] public currentLoans;
    uint256[] public defaultedLoans;

    //For Staking, Slashing and Balances
    uint256 public accountsReceiveable;
    mapping(address => bool) public whitelistedAddresses;
    mapping(address => uint256) public stakingShares;
    mapping(address => uint256) lastStakeTime;
    mapping(address => uint256) unbondingShares;

    //For Collateral
    mapping(address => uint256) collateralOwed;
    uint256 public unbondingAmount;
    uint256 public totalUnbondingShares;
    uint256 public totalStakingShares;
    uint256 public slashingBalance;
    IERC20 public BNPL;

    struct Loan {
        address borrower;
        bool interestOnly; //interest only or principal + interest
        uint256 loanStartTime; //unix timestamp of start
        uint256 loanAmount;
        uint256 paymentInterval; //unix interval of payment (e.g. monthly = 2,628,000)
        uint256 interestRate; //interest rate * 10000, e.g., 10%: 0.1 * 10000 = 1000
        uint256 numberOfPayments;
        uint256 principalRemaining;
        uint256 paymentsMade;
        address collateral;
        uint256 collateralAmount;
    }

    //EVENTS
    event LoanRequest(uint256 loanId);
    event collateralWithdrawn(
        uint256 loanId,
        address collateral,
        uint256 collateralAmount
    );
    event approvedLoan(uint256 loanId, address borrower);
    event loanPaymentMade(uint256 loanId);
    event loanRepaidEarly(uint256 loanId);
    event baseTokenDeposit(address user, uint256 amount);
    event baseTokenWithdrawn(address user, uint256 amount);
    event feesCollected(uint256 operatorFees, uint256 stakerFees);
    event baseTokensDonated(uint256 amount);
    event aaveRewardsCollected(uint256 amount);
    event slashingSale(uint256 bnplSold, uint256 baseTokenRecovered);

    constructor() {
        factory = msg.sender;
    }

    //STATE CHANGING FUNCTIONS

    /**
     * Called once by the factory at time of deployment
     */
    function initialize(
        address _baseToken,
        IERC20 _BNPL,
        bool _requireKYC,
        address _operator,
        uint256 _gracePeriod,
        address _lendingPoolProvider,
        address _WETH,
        address _aaveDistributionController,
        address _uniswapFactory
    ) external {
        //only to be done by factory
        require(
            msg.sender == factory,
            "Set up can only be done through BNPL Factory"
        );
        baseToken = ERC20(_baseToken);
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
        //decimal check on baseToken and aToken to make sure math logic on future steps
        ILendingPool lendingPool = _getLendingPool();
        ERC20 aToken = ERC20(
            lendingPool.getReserveData(address(baseToken)).aTokenAddress
        );
        uniswapFactory = _uniswapFactory;
        treasury = address(0x27a99802FC48b57670846AbFFf5F2DcDE8a6fC29);
        require(baseToken.decimals() == aToken.decimals());
    }

    /**
     * Request a loan from the banking node
     */
    function requestLoan(
        uint256 loanAmount,
        uint256 paymentInterval,
        uint256 numberOfPayments,
        uint256 interestRate,
        bool interestOnly,
        address collateral,
        uint256 collateralAmount,
        string memory message
    ) external returns (uint256 requestId) {
        //bank node must be active
        require(
            getBNPLBalance(operator) >= 1500000 * 10**18,
            "Banking node is currently not active"
        );
        requestId = incrementor;
        incrementor++;
        pendingRequests.push(requestId);
        idToLoan[requestId] = Loan(
            msg.sender,
            interestOnly,
            0,
            loanAmount,
            paymentInterval, //interval of payments (e.g. Monthly)
            interestRate, //annualized interest rate
            numberOfPayments,
            0, //initalize principalRemaining to 0
            0, //intialize paymentsMade to 0
            collateral,
            collateralAmount
        );

        //post the collateral if any
        if (collateralAmount > 0) {
            //update the collateral owed (interest accrued on collateral is given to lend)
            collateralOwed[collateral] += collateralAmount;
            //collect the collateral
            IERC20 bond = IERC20(collateral);
            bond.transferFrom(msg.sender, address(this), collateralAmount);
            //deposit the collateral in AAVE to accrue interest
            ILendingPool lendingPool = ILendingPool(
                lendingPoolProvider.getLendingPool()
            );
            bond.approve(address(lendingPool), collateralAmount);
            lendingPool.deposit(
                address(bond),
                collateralAmount,
                address(this),
                0
            );
        }
        emit LoanRequest(requestId);
    }

    /**
     * Withdraw the collateral from a loan
     */
    function withdrawCollateral(uint256 loanId) public {
        //must be the borrower or operator to withdraw, and loan must be either paid/not initiated
        require(msg.sender == idToLoan[loanId].borrower);
        require(idToLoan[loanId].principalRemaining == 0);

        ILendingPool lendingPool = _getLendingPool();
        lendingPool.withdraw(
            idToLoan[loanId].collateral,
            idToLoan[loanId].collateralAmount,
            idToLoan[loanId].borrower
        );
        //update the amounts
        collateralOwed[idToLoan[loanId].collateral] -= idToLoan[loanId]
            .collateralAmount;
        idToLoan[loanId].collateralAmount = 0;

        emit collateralWithdrawn(
            loanId,
            idToLoan[loanId].collateral,
            idToLoan[loanId].collateralAmount
        );
    }

    /**
     * Collect AAVE rewards and distribute to lenders
     */
    function collectAaveRewards(address[] calldata assets) external {
        uint256 rewardAmount = aaveRewardController.getRewardsBalance(
            assets,
            address(this)
        );
        require(rewardAmount > 0);
        uint256 rewards = aaveRewardController.claimRewards(
            assets,
            rewardAmount,
            address(this)
        );
        _swapToken(
            aaveRewardController.REWARD_TOKEN(),
            address(BNPL),
            0,
            rewards
        );
        emit aaveRewardsCollected(rewardAmount);
    }

    /**
     * Collect the interest earnt on collateral to distribute to stakers
     */
    function collectCollateralFees(address collateral) external {
        //get the aToken address
        ILendingPool lendingPool = _getLendingPool();
        IERC20 aToken = IERC20(
            lendingPool.getReserveData(collateral).aTokenAddress
        );
        uint256 feesAccrued = aToken.balanceOf(address(this)) -
            collateralOwed[collateral];
        //ensure there is collateral to collect
        require(feesAccrued > 0);
        lendingPool.withdraw(collateral, feesAccrued, address(this));

        _swapToken(collateral, address(BNPL), 0, feesAccrued);
    }

    /*
     * Make a loan payment
     */
    function makeLoanPayment(uint256 loanId) external {
        //check the loan has outstanding payments
        require(
            idToLoan[loanId].principalRemaining != 0,
            "No payments are required for this loan"
        );
        uint256 paymentAmount = getNextPayment(loanId);
        uint256 interestRatePerPeriod = (idToLoan[loanId].interestRate *
            idToLoan[loanId].paymentInterval) / 31536000;
        uint256 interestPortion = (idToLoan[loanId].principalRemaining *
            interestRatePerPeriod) / 10000;
        //reduce accounts receiveable and loan principal if principal + interest payment
        if (!idToLoan[loanId].interestOnly) {
            uint256 principalPortion = paymentAmount - interestPortion;
            idToLoan[loanId].principalRemaining -= principalPortion;
            accountsReceiveable -= principalPortion;
        } else {
            //if interest only, check if it was the final payment
            if (
                idToLoan[loanId].paymentsMade + 1 ==
                idToLoan[loanId].numberOfPayments
            ) {
                accountsReceiveable -= idToLoan[loanId].principalRemaining;
                idToLoan[loanId].principalRemaining = 0;
            }
        }
        //make payment
        baseToken.transferFrom(msg.sender, address(this), paymentAmount);
        //get the latest lending pool address
        ILendingPool lendingPool = _getLendingPool();
        //deposit the tokens into AAVE on behalf of the pool contract, withholding 30% and the interest as baseToken
        uint256 interestWithheld = ((interestPortion * 3) / 10);
        baseToken.approve(
            address(lendingPool),
            paymentAmount - interestWithheld
        );
        lendingPool.deposit(
            address(baseToken),
            paymentAmount - interestWithheld,
            address(this),
            0
        );
        //increment the loan status
        idToLoan[loanId].paymentsMade++;
        //check if it was the final payment
        if (
            idToLoan[loanId].paymentsMade == idToLoan[loanId].numberOfPayments
        ) {
            _removeCurrentLoan(loanId);
        }
        emit loanPaymentMade(loanId);
    }

    /**
     * Repay remaining balance to save on interest cost
     * Payment amount is remaining principal + 1 period of interest
     */
    function repayEarly(uint256 loanId) external {
        //check the loan has outstanding payments
        require(
            idToLoan[loanId].principalRemaining != 0,
            "No payments are required for this loan"
        );
        uint256 interestRatePerPeriod = (idToLoan[loanId].interestRate *
            idToLoan[loanId].paymentInterval) / 31536000;
        //make a payment of remaining principal + 1 period of interest
        uint256 interestAmount = (idToLoan[loanId].principalRemaining *
            (interestRatePerPeriod)) / 10000;
        uint256 paymentAmount = (idToLoan[loanId].principalRemaining +
            interestAmount);
        //make payment
        baseToken.transferFrom(msg.sender, address(this), paymentAmount);

        uint256 interestWithheld = ((interestAmount * 3) / 10);

        ILendingPool lendingPool = _getLendingPool();
        //deposit the tokens into AAVE on behalf of the pool contract
        baseToken.approve(
            address(lendingPool),
            paymentAmount - interestWithheld
        );
        lendingPool.deposit(
            address(baseToken),
            paymentAmount - interestWithheld,
            address(this),
            0
        );
        //update accounts
        accountsReceiveable -= idToLoan[loanId].principalRemaining;
        idToLoan[loanId].principalRemaining = 0;
        //increment the loan status to final and remove from current loans array
        idToLoan[loanId].paymentsMade = idToLoan[loanId].numberOfPayments;
        _removeCurrentLoan(loanId);

        emit loanRepaidEarly(loanId);
    }

    /**
     * Converts the baseToken (e.g. USDT) 20% BNPL for stakers, and sends 10% to the Banking Node Operator
     * Slippage set to 0 here as they would be small purchases of BNPL
     */
    function collectFees() external {
        //check there are tokens to swap
        require(
            baseToken.balanceOf(address(this)) > 0,
            "There are no rewards to collect"
        );
        //33% to go to operator as baseToken
        uint256 operatorFees = (baseToken.balanceOf(address(this))) / 3;
        baseToken.transfer(operator, operatorFees);
        //remainder (67%) is traded for staking rewards
        uint256 stakingRewards = _swapToken(
            address(baseToken),
            address(BNPL),
            0,
            baseToken.balanceOf(address(this))
        );
        emit feesCollected(operatorFees, stakingRewards);
    }

    /**
     * Deposit liquidity to the banking node
     */
    function deposit(uint256 _amount) public {
        //KYC requirement / whitelist check
        if (requireKYC) {
            require(
                whitelistedAddresses[msg.sender],
                "You must first complete the KYC process"
            );
        }
        //bank node must be active
        require(
            getBNPLBalance(operator) >= 1500000 * 10**18,
            "Banking node is currently not active"
        );
        //check the decimals of the
        uint256 decimalAdjust = 1;
        if (baseToken.decimals() != 18) {
            decimalAdjust = 10**(18 - baseToken.decimals());
        }
        //get the amount of tokens to mint
        uint256 what = _amount * decimalAdjust;
        if (totalSupply() != 0) {
            what = (_amount * totalSupply()) / getTotalAssetValue();
        }
        _mint(msg.sender, what);
        //transfer tokens from the user
        TransferHelper.safeTransferFrom(
            address(baseToken),
            msg.sender,
            address(this),
            _amount
        );
        //get the latest lending pool address
        ILendingPool lendingPool = _getLendingPool();
        //deposit the tokens into AAVE on behalf of the pool contract
        baseToken.approve(address(lendingPool), _amount);
        lendingPool.deposit(address(baseToken), _amount, address(this), 0);

        emit baseTokenDeposit(msg.sender, _amount);
    }

    /**
     * Withdraw liquidity from the banking node
     * To avoid need to decimal adjust, input _amount is in USDT(or equiv) to withdraw
     * , not BNPL USD to burn
     */
    function withdraw(uint256 _amount) external {
        uint256 what = (_amount * totalSupply()) / getTotalAssetValue();
        _burn(msg.sender, what);
        //get the latest lending pool address;
        ILendingPool lendingPool = _getLendingPool();
        //withdraw the tokens to the user
        lendingPool.withdraw(address(baseToken), _amount, msg.sender);

        emit baseTokenWithdrawn(msg.sender, _amount);
    }

    /**
     * Stake BNPL into a node
     */
    function stake(uint256 _amount) external {
        //require a non-zero deposit
        require(_amount > 0, "Cannot deposit 0");
        //KYC requirement / whitelist check
        if (requireKYC) {
            require(
                whitelistedAddresses[msg.sender],
                "Your address is has not completed KYC requirements"
            );
        }
        //require bankingNode to be active (operator must have 2M BNPL staked)
        if (msg.sender != factory && msg.sender != operator) {
            require(
                getBNPLBalance(operator) >= 1500000 * 10**18,
                "Banking node is currently not active"
            );
        }
        address staker = msg.sender;
        //factory initial bond counted as operator
        if (msg.sender == factory) {
            staker = operator;
        }
        //set the time of the stake
        lastStakeTime[staker] = block.timestamp;
        //calcualte the number of shares to give
        uint256 what = 0;
        if (totalStakingShares == 0) {
            what = _amount;
        } else {
            what =
                (_amount * totalStakingShares) /
                (BNPL.balanceOf(address(this)) -
                    unbondingAmount -
                    slashingBalance);
        }
        //collect the BNPL
        BNPL.transferFrom(msg.sender, address(this), _amount);
        //issue the shares
        stakingShares[staker] += what;
        totalStakingShares += what;
    }

    /**
     * Unbond BNPL from a node, input is the number shares (sBNPL)
     * Requires a 7 day unbond to prevent frontrun of slashing events or interest repayments
     */
    function initiateUnstake(uint256 _amount) external {
        //operator cannot withdraw unless there are no active loans
        if (msg.sender == operator) {
            require(
                currentLoans.length == 0,
                "Operator can not unbond if there are active loans"
            );
        }
        //require its a non-zero withdraw
        require(_amount > 0, "Cannot unbond 0");
        //require the user has enough
        require(
            stakingShares[msg.sender] >= _amount,
            "You do not have a large enough balance"
        );
        //get the amount of BNPL to issue back
        uint256 what = (_amount *
            (BNPL.balanceOf(address(this)) -
                unbondingAmount -
                slashingBalance)) / totalStakingShares;
        //subtract the number of shares of BNPL from the user
        stakingShares[msg.sender] -= _amount;
        totalStakingShares -= _amount;
        //initiate as 1:1 for unbonding shares with BNPL sent
        uint256 newUnbondingShares = what;
        //update amount if there is a pool of unbonding
        if (unbondingAmount != 0) {
            newUnbondingShares =
                (what * totalUnbondingShares) /
                unbondingAmount;
        }
        //add the balance to their unbonding
        unbondingShares[msg.sender] += newUnbondingShares;
        totalUnbondingShares += newUnbondingShares;
        unbondingAmount += what;
    }

    /**
     * Withdraw BNPL from a bond once unbond period ends
     */
    function unstake() external {
        //require a 45,000 block gap (~7 day) gap since the last deposit
        require(block.timestamp >= lastStakeTime[msg.sender] + 45000);
        uint256 what = unbondingShares[msg.sender];
        //transfer the tokens to user
        BNPL.transfer(msg.sender, what);
        //update the balances
        unbondingShares[msg.sender] = 0;
        unbondingAmount -= what;
    }

    /**
     * Declare a loan defaulted and slash the loan
     * Can be called by anyone
     * Move BNPL to a slashing balance, to be market sold in seperate function to prevent minOut failure
     * minOut used for slashing sale, if no collateral, put 0
     */
    function slashLoan(uint256 loanId, uint256 minOut) external {
        //require that the given due date and grace period have expired
        require(block.timestamp > getNextDueDate(loanId) + gracePeriod);
        //check that the loan has remaining payments
        require(idToLoan[loanId].principalRemaining != 0);
        //get slash % with 10,000 multiplier
        uint256 slashPercent = (10000 * idToLoan[loanId].principalRemaining) /
            getTotalAssetValue();
        uint256 unbondingSlash = (unbondingAmount * slashPercent) / 10000;
        uint256 stakingSlash = ((BNPL.balanceOf(address(this)) -
            slashingBalance -
            unbondingAmount) * slashPercent) / 10000;
        //slash both staked and bonded balances
        slashingBalance += unbondingSlash + stakingSlash;
        unbondingAmount -= unbondingSlash;
        stakingSlash -= stakingSlash;
        defaultedLoans.push(loanId);
        //sell collateral if any
        if (idToLoan[loanId].collateralAmount != 0) {
            _swapToken(
                idToLoan[loanId].collateral,
                address(baseToken),
                minOut,
                idToLoan[loanId].collateralAmount
            );
            //update collateral info
            idToLoan[loanId].collateralAmount = 0;
        }
    }

    /**
     * Sell the slashing balance for BNPL to give to lenders as aUSD
     */
    function sellSlashed(uint256 minOut) external {
        //ensure there is a balance to sell
        require(slashingBalance > 0);
        //As BNPL-ETH Pair is the most liquid, goes BNPL > ETH > baseToken
        uint256 baseTokenOut = _swapToken(
            address(BNPL),
            address(baseToken),
            minOut,
            slashingBalance
        );
        slashingBalance = 0;
        //deposit the baseToken into AAVE
        ILendingPool lendingPool = _getLendingPool();
        baseToken.approve(address(lendingPool), baseTokenOut);
        lendingPool.deposit(address(baseToken), baseTokenOut, address(this), 0);

        emit slashingSale(slashingBalance, baseTokenOut);
    }

    /**
     * Donate baseToken for when debt is collected post default
     */

    function donateBaseToken(uint256 _amount) external {
        require(_amount > 0);
        baseToken.transferFrom(msg.sender, address(this), _amount);
        //add donation to AAVE
        ILendingPool lendingPool = _getLendingPool();
        baseToken.approve(address(lendingPool), _amount);
        lendingPool.deposit(address(baseToken), _amount, address(this), 0);

        emit baseTokensDonated(_amount);
    }

    //PRIVATE FUNCTIONS

    /**
     * Get the latest AAVE Lending Pool contract
     */

    function _getLendingPool() private view returns (ILendingPool) {
        return ILendingPool(lendingPoolProvider.getLendingPool());
    }

    /**
     * Remove current Loan
     */
    function _removeCurrentLoan(uint256 loanId) private {
        for (uint256 i = 0; i < currentLoans.length; i++) {
            if (loanId == currentLoans[i]) {
                currentLoans[i] = currentLoans[currentLoans.length - 1];
                currentLoans.pop();
            }
        }
    }

    /**
     * Swaps token for BNPL, as BNPL-ETH is the only liquid pair, always goes through x > ETH > x
     */
    function _swapToken(
        address tokenIn,
        address tokenOut,
        uint256 minOut,
        uint256 amountIn
    ) private returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = WETH;
        path[2] = tokenOut;
        uint256[] memory amounts = UniswapV2Library.getAmountsOut(
            uniswapFactory,
            amountIn,
            path
        );
        //ensure slippage
        require(amounts[amounts.length - 1] >= minOut, "Insufficient outout");
        TransferHelper.safeTransfer(
            tokenIn,
            UniswapV2Library.pairFor(uniswapFactory, path[0], path[1]),
            amounts[0]
        );
        _swap(amounts, path, address(this));
        return amounts[amounts.length - 1];
    }

    // **** SWAP ****
    // Copied directly from UniswapV2Router
    // requires the initial amount to have already been sent to the first pair
    function _swap(
        uint256[] memory amounts,
        address[] memory path,
        address _to
    ) internal virtual {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = UniswapV2Library.sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) = input == token0
                ? (uint256(0), amountOut)
                : (amountOut, uint256(0));
            address to = i < path.length - 2
                ? UniswapV2Library.pairFor(factory, output, path[i + 2])
                : _to;
            IUniswapV2Pair(UniswapV2Library.pairFor(factory, input, output))
                .swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    //OPERATOR ONLY FUNCTIONS

    /**
     * Approve a pending loan request
     * Ensures collateral amount has been posted to prevent front run withdrawal
     */
    function approveLoan(uint256 loanId, uint256 requiredCollateralAmount)
        external
    {
        require(msg.sender == operator);
        //check node is active
        require(
            getBNPLBalance(operator) >= 1500000 * 10**18,
            "Banking node is currently not active"
        );
        //ensure the loan was never started
        require(idToLoan[loanId].loanStartTime == 0);
        //ensure the collateral is still posted
        require(idToLoan[loanId].collateralAmount == requiredCollateralAmount);

        //remove from loanRequests and add loan to current loans
        for (uint256 i = 0; i < pendingRequests.length; i++) {
            if (loanId == pendingRequests[i]) {
                pendingRequests[i] = pendingRequests[
                    pendingRequests.length - 1
                ];
                pendingRequests.pop();
            }
        }
        currentLoans.push(loanId);

        //add the principal remaining and start the loan
        idToLoan[loanId].principalRemaining = idToLoan[loanId].loanAmount;
        idToLoan[loanId].loanStartTime = block.timestamp;

        //send the funds and update accounts (minus 0.25% origination fee)
        accountsReceiveable += idToLoan[loanId].loanAmount;
        ILendingPool lendingPool = _getLendingPool();
        lendingPool.withdraw(
            address(baseToken),
            (idToLoan[loanId].loanAmount * 199) / 200,
            idToLoan[loanId].borrower
        );
        //send the origination fee to treasury and agent
        lendingPool.withdraw(
            address(baseToken),
            (idToLoan[loanId].loanAmount * 1) / 400,
            treasury
        );

        emit approvedLoan(loanId, idToLoan[loanId].borrower);
    }

    /**
     * Used to reject all current pending loan requests
     */
    function clearPendingLoans() external {
        require(address(msg.sender) == operator);
        pendingRequests = new uint256[](0);
    }

    /**
     * Whitelist a given list of addresses
     */
    function whitelistAddresses(address whitelistAddition) external {
        require(address(msg.sender) == operator);
        whitelistedAddresses[whitelistAddition] = true;
    }

    //VIEW ONLY FUNCTIONS

    /**
     * Gets the given users balance in baseToken
     */
    function getBaseTokenBalance(address user) public view returns (uint256) {
        if (totalSupply() == 0) {
            return 0;
        }
        return (balanceOf(user) * getTotalAssetValue()) / totalSupply();
    }

    /**
     * Get the value of the BNPL staked by user
     */
    function getBNPLBalance(address user) public view returns (uint256 what) {
        uint256 balance = stakingShares[user];
        if (balance == 0 || totalStakingShares == 0) {
            what = 0;
        } else {
            what =
                (balance *
                    (BNPL.balanceOf(address(this)) -
                        unbondingAmount -
                        slashingBalance)) /
                totalStakingShares;
        }
    }

    /**
     * Get the amount a user has that is being unbonded
     */
    function getUnbondingBalance(address user) external view returns (uint256) {
        return (unbondingShares[user] * unbondingAmount) / totalUnbondingShares;
    }

    /**
     * Gets the next payment amount due
     * If loan is completed or not approved, returns 0
     */
    function getNextPayment(uint256 loanId) public view returns (uint256) {
        //if loan is completed or not approved, return 0
        if (idToLoan[loanId].principalRemaining == 0) {
            return 0;
        }
        // interest rate per period (31536000 seconds in a year)
        uint256 interestRatePerPeriod = (idToLoan[loanId].interestRate *
            idToLoan[loanId].paymentInterval) / 31536000;
        //check if it is an interest only loan
        if (idToLoan[loanId].interestOnly) {
            //check if its the final payment
            if (
                idToLoan[loanId].paymentsMade + 1 ==
                idToLoan[loanId].numberOfPayments
            ) {
                //if final payment, then principal + final interest amount
                return
                    idToLoan[loanId].loanAmount +
                    ((idToLoan[loanId].loanAmount * interestRatePerPeriod) /
                        10000);
            } else {
                //if not final payment, simple interest amount
                return
                    (idToLoan[loanId].loanAmount * interestRatePerPeriod) /
                    10000;
            }
        } else {
            //principal + interest payments, payment given by the formula:
            //p : principal
            //i : interest rate per period
            //d : duration
            // p * (i * (1+i) ** d) / ((1+i) ** d - 1)
            uint256 numerator = idToLoan[loanId].loanAmount *
                interestRatePerPeriod *
                (10000 + interestRatePerPeriod) **
                    idToLoan[loanId].numberOfPayments;
            uint256 denominator = (10000 + interestRatePerPeriod) **
                idToLoan[loanId].numberOfPayments -
                (10**(4 * idToLoan[loanId].numberOfPayments));
            uint256 adjustment = 10000;
            return numerator / (denominator * adjustment);
        }
    }

    /**
     * Gets the next due date (unix timestamp) of a given loan
     * Returns 0 if loan is not a current loan or loan has alreadyt been paid
     */
    function getNextDueDate(uint256 loanId) public view returns (uint256) {
        //check that the loan has been approved and loan is not completed;
        if (idToLoan[loanId].principalRemaining == 0) {
            return 0;
        }
        return
            idToLoan[loanId].loanStartTime +
            ((idToLoan[loanId].paymentsMade + 1) *
                idToLoan[loanId].paymentInterval);
    }

    /**
     * Get the total assets (accounts receivable + aToken balance)
     * Only principal owed is counted as accounts receivable
     */
    function getTotalAssetValue() public view returns (uint256) {
        ILendingPool lendingPool = _getLendingPool();
        IERC20 aToken = IERC20(
            lendingPool.getReserveData(address(baseToken)).aTokenAddress
        );
        return accountsReceiveable + aToken.balanceOf(address(this));
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
                            hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f" // init code hash
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