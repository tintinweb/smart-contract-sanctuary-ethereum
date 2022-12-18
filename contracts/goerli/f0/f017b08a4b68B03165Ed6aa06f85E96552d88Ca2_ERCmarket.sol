/**
 *Submitted for verification at Etherscan.io on 2022-12-17
*/

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
     * by making the `nonReentrant` function external, and making it call a
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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// File: Interfaces/IWETH.sol


pragma solidity 0.8.17;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 wad) external;

    function totalSupply() external view returns (uint256);

    function approve(address guy, uint256 wad) external returns (bool);

    function transfer(address dst, uint256 wad) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

// File: market-v2.sol


pragma solidity 0.8.17;






contract ERCmarket is Ownable, ReentrancyGuard {
    /*
    to do
    -way to transfer to contractv2
    
    //need to add fees accrued to timestamp fx
    -increase accounthealthdec to 1e18?
    -avoid stack too deep by replacing local variables with structs
    -assign struct to memory to avoid stack too deep error
    https://medium.com/1milliondevs/compilererror-stack-too-deep-try-removing-local-variables-solved-a6bcecc16231
*/
    event Log(string func, address indexed user, uint256 amount, uint256 total);
    event Liquidation(
        string func,
        address indexed account,
        uint256 erasedDebt,
        uint256 liquidatedCollat
    );

    struct AccountInfo {
        mapping(address => uint256) depositedAmount;
        mapping(address => uint256) pendingDepositAmount;
        mapping(address => uint256) pendingWithdrawl;
        mapping(address => uint256) borrowedAmount;
        mapping(address => uint256) pendingRewards;
        mapping(address => uint256) pendingFees;
        uint256 debtIndex;
        uint256 depositIndex;
        uint256 pendingCREEK;
    }

    mapping(address => AccountInfo) public users;

    uint256[] public compoundingTimestampArray;
    uint256 public compoundingInterval;
    uint256 public utilToAPM;

    //token => amount
    //need to subtract from _pendingfees/rewards when settled
    mapping(address => uint256) public pendingFees;
    mapping(address => uint256) public pendingRewards;
    mapping(address => uint256) public totalFeesPaid;
    mapping(address => uint256) public totalRewardsDistributed;

    //timestamp => token => amount
    mapping(uint256 => mapping(address => uint256)) public intervalBorrowAPR;
    mapping(uint256 => mapping(address => uint256)) public intervalSupplyAPR;
    bool public distributeFees;

    //token => timestamp => amount
    mapping(address => mapping(uint256 => uint256))
        public intervalBorrowCREEKAPR;
    mapping(address => mapping(uint256 => uint256))
        public intervalSupplyCREEKAPR;
    mapping(address => uint256) public borrowCREEKperInterval;
    mapping(address => uint256) public supplyCREEKperInterval;
    uint256 public CREEKendTimestamp;

    mapping(address => uint256) public totalSupplied;
    mapping(address => uint256) public intervalSupplied;
    mapping(uint256 => mapping(address => uint256))
        public tokenSuppliedTimestamp;

    mapping(address => uint256) public totalBorrowed;
    mapping(address => uint256) public intervalFeesAccrued;
    mapping(uint256 => mapping(address => uint256))
        public tokenBorrowedTimestamp;

    //total protocol profit
    mapping(address => uint256) public totalIncome;
    mapping(uint256 => mapping(address => uint256))
        public tokenRewardsAmtTimestamp;
    mapping(address => uint256) public profitWithdrawn;

    mapping(address => uint256) public extraTokenSent;

    address public exchange;
    AggregatorV3Interface internal priceFeedtokenA;
    AggregatorV3Interface internal priceFeedtokenB;
    address public immutable tokenA;
    address public immutable tokenB;
    address public immutable wbera;
    address public immutable CREEK;
    mapping(address => uint256) public tokenPrice;
    uint256 public minBorrowValue;
    mapping(address => uint256) public minBorrowAmount;
    uint256 public priceDecimals = 1e8;
    uint256 public tokenDecimals = 1e18;

    // % * 10,000. 150% = 1.5 => 15,000
    uint256 public collatPercent;
    uint256 public accountHealthDec = 1e3;
    mapping(address => uint256) public liquidationRevenue;
    uint256 public APRdecimals = 1e18;
    address public treasury;
    bool public withdrawEnabledBool;
    bool public paused;

    constructor(
        address _tokenA,
        address _tokenB,
        address _wbera,
        AggregatorV3Interface _pricefeedA,
        AggregatorV3Interface _pricefeedB,
        address _CREEK,
        address _treasury,
        uint256 _collatPercent,
        address _exchange
    ) {
        treasury = _treasury;
        collatPercent = _collatPercent;
        tokenA = _tokenA;
        tokenB = _tokenB;
        wbera = _wbera;
        priceFeedtokenA = _pricefeedA;
        priceFeedtokenB = _pricefeedB;
        CREEK = _CREEK;
        exchange = _exchange;
        paused = false;
        distributeFees = true;
        withdrawEnabledBool = true;
        compoundingTimestampArray.push(block.timestamp - 1 minutes);
        compoundingTimestampArray.push(block.timestamp);
        compoundingInterval = 30 minutes;
        // 0.3 * APRdecimals / 365 / 24 / 60= 570776255708
        utilToAPM = 570776255708;
        tokenPrice[tokenA] = 1500 * priceDecimals;
        tokenPrice[tokenB] = 1 * priceDecimals;

        minBorrowValue = 500 * priceDecimals;
        minBorrowAmount[tokenA] =
            (minBorrowValue * tokenDecimals) /
            tokenPrice[tokenA];
        minBorrowAmount[tokenB] =
            (minBorrowValue * tokenDecimals) /
            tokenPrice[tokenB];
    }

    modifier whenNotPaused() {
        require(!paused, "Pool is paused");
        _;
    }

    modifier withdrawEnabled() {
        require(withdrawEnabledBool, "Withdraws not enabled");
        _;
    }

    fallback() external payable {
        revert("fallback called");
    }

    receive() external payable {}

    function togglePause() external onlyOwner {
        paused = !paused;
    }

    function toggleWithdraws() external onlyOwner {
        withdrawEnabledBool = !withdrawEnabledBool;
    }

    function toggleFeeDistribution() external onlyOwner {
        distributeFees = !distributeFees;
    }

    function setCollatPercent(uint256 _percent) external onlyOwner {
        collatPercent = _percent;
    }

    function setMinBorrowValue(uint256 _valueNoDec) external onlyOwner {
        minBorrowValue = _valueNoDec * priceDecimals;
    }

    function setCompoundingInterval(uint256 _intervalInMinutes)
        external
        onlyOwner
    {
        compoundingInterval = _intervalInMinutes * 1 minutes;
    }

    function setUtilToAPY(uint256 _ratioTimes100) external onlyOwner {
        utilToAPM = (_ratioTimes100 * 10**16) / 365 / 24 / 60;
    }

    function withdrawProfits(address _token, uint256 _amount)
        external
        onlyOwner
    {
        IERC20(_token).transfer(msg.sender, _amount);
        profitWithdrawn[_token] += _amount;
    }

    function withdrawExtraCREEK(uint256 _amount) external onlyOwner {
        IERC20(CREEK).transfer(treasury, _amount);
    }

    function setCREEKincentive(
        uint256 _tokenAsupplyCREEK,
        uint256 _tokenBsupplyCREEK,
        uint256 _tokenAborrowCREEK,
        uint256 _tokenBborrowCREEK,
        uint256 _expiresInIntervals
    ) external onlyOwner {
        uint256 total = _tokenAborrowCREEK +
            _tokenBborrowCREEK +
            _tokenAsupplyCREEK +
            _tokenAsupplyCREEK;
        require(
            IERC20(CREEK).transferFrom(treasury, address(this), total),
            "CREEK transfer error"
        );

        updateTimeArray();
        CREEKendTimestamp =
            (_expiresInIntervals * compoundingInterval) +
            compoundingTimestampArray[compoundingTimestampArray.length - 1];

        borrowCREEKperInterval[address(tokenA)] =
            _tokenAborrowCREEK /
            _expiresInIntervals;
        borrowCREEKperInterval[address(tokenB)] =
            _tokenBborrowCREEK /
            _expiresInIntervals;
        supplyCREEKperInterval[address(tokenA)] =
            _tokenAsupplyCREEK /
            _expiresInIntervals;
        supplyCREEKperInterval[address(tokenB)] =
            _tokenBsupplyCREEK /
            _expiresInIntervals;
    }

    function getLength() public view returns (uint256) {
        return compoundingTimestampArray.length;
    }

    function getUserData(address _user)
        public
        view
        returns (
            uint256 _tokenAdeposited,
            uint256 _tokenBdeposited,
            uint256 _tokenApendingDeposit,
            uint256 _tokenBpendingDeposit,
            uint256 _tokenApendingWithdrawl,
            uint256 _tokenBpendingWithdrawl,
            uint256 _tokenAborrowed,
            uint256 _tokenBborrowed,
            uint256 _tokenApendingRewards,
            uint256 _tokenBpendingRewards,
            uint256 _tokenApendingFees,
            uint256 _tokenBpendingFees
        )
    {
        AccountInfo storage userInfo_ = users[_user];
        _tokenAdeposited = userInfo_.depositedAmount[tokenA];
        _tokenBdeposited = userInfo_.depositedAmount[tokenB];
        _tokenApendingDeposit = userInfo_.pendingDepositAmount[tokenA];
        _tokenBpendingDeposit = userInfo_.pendingDepositAmount[tokenB];
        _tokenApendingWithdrawl = userInfo_.pendingWithdrawl[tokenA];
        _tokenBpendingWithdrawl = userInfo_.pendingWithdrawl[tokenB];
        _tokenAborrowed = userInfo_.borrowedAmount[tokenA];
        _tokenBborrowed = userInfo_.borrowedAmount[tokenB];
        _tokenApendingRewards = userInfo_.pendingRewards[tokenA];
        _tokenBpendingRewards = userInfo_.pendingRewards[tokenB];
        _tokenApendingFees = userInfo_.pendingFees[tokenA];
        _tokenBpendingFees = userInfo_.pendingFees[tokenB];
    }

    function getMarketData()
        public
        view
        returns (
            uint256 _pendingFeesA,
            uint256 _pendingFeesB,
            uint256 _pendingRewardsA,
            uint256 _pendingRewardsB,
            uint256 _totalFeesPaidA,
            uint256 _totalFeesPaidB,
            uint256 _totalRewardsDistributedA,
            uint256 _totalRewardsDistributedB,
            uint256 _totalSuppliedA,
            uint256 _totalSuppliedB,
            uint256 _totalBorrowedA,
            uint256 _totalBorrowedB,
            uint256 _totalIncomeA,
            uint256 _totalIncomeB
        )
    {
        _pendingFeesA = pendingFees[tokenA];
        _pendingFeesB = pendingFees[tokenB];
        _pendingRewardsA = pendingRewards[tokenA];
        _pendingRewardsB = pendingRewards[tokenB];
        _totalFeesPaidA = totalFeesPaid[tokenA];
        _totalFeesPaidB = totalFeesPaid[tokenB];
        _totalRewardsDistributedA = totalRewardsDistributed[tokenA];
        _totalRewardsDistributedB = totalRewardsDistributed[tokenB];
        _totalSuppliedA = totalSupplied[tokenA];
        _totalSuppliedB = totalSupplied[tokenB];
        _totalBorrowedA = totalBorrowed[tokenA];
        _totalBorrowedB = totalBorrowed[tokenB];
        _totalIncomeA = totalIncome[tokenA];
        _totalIncomeB = totalIncome[tokenB];
    }

    function updateTokenPrice() public {
        (, int256 intpriceA, , , ) = priceFeedtokenA.latestRoundData();
        (, int256 intpriceB, , , ) = priceFeedtokenB.latestRoundData();
        tokenPrice[tokenA] = uint256(intpriceA);
        tokenPrice[tokenB] = uint256(intpriceB);
        minBorrowAmount[tokenA] =
            (minBorrowValue * tokenDecimals) /
            uint256(intpriceA);
        minBorrowAmount[tokenB] =
            (minBorrowValue * tokenDecimals) /
            uint256(intpriceB);
    }

    function updateTimeArray() public {
        updateTokenPrice();
        uint256 lastTimeStamp_ = compoundingTimestampArray[
            compoundingTimestampArray.length - 1
        ];
        while (block.timestamp >= lastTimeStamp_ + compoundingInterval) {
            compoundingTimestampArray.push(
                lastTimeStamp_ + compoundingInterval
            );
            lastTimeStamp_ = compoundingTimestampArray[
                compoundingTimestampArray.length - 1
            ];

            tokenSuppliedTimestamp[lastTimeStamp_][tokenA] = totalSupplied[
                tokenA
            ];
            tokenSuppliedTimestamp[lastTimeStamp_][tokenB] = totalSupplied[
                tokenB
            ];
            tokenBorrowedTimestamp[lastTimeStamp_][tokenA] = totalBorrowed[
                tokenA
            ];
            tokenBorrowedTimestamp[lastTimeStamp_][tokenB] = totalBorrowed[
                tokenB
            ];

            uint256 intervalTokenABorrowAPR_;
            uint256 intervalTokenBBorrowAPR_;

            (
                intervalTokenABorrowAPR_,
                intervalTokenBBorrowAPR_
            ) = recalculateBorrowAPR();

            intervalBorrowAPR[lastTimeStamp_][
                tokenA
            ] = intervalTokenABorrowAPR_;
            intervalBorrowAPR[lastTimeStamp_][
                tokenB
            ] = intervalTokenBBorrowAPR_;

            pendingFees[tokenA] +=
                (totalBorrowed[tokenA] * intervalTokenABorrowAPR_) /
                APRdecimals;
            pendingFees[tokenB] +=
                (totalBorrowed[tokenB] * intervalTokenBBorrowAPR_) /
                APRdecimals;

            uint256 tokenAIncome_;
            uint256 tokenBIncome_;
            uint256 intervalTokenASupplyAPR_;
            uint256 intervalTokenBSupplyAPR_;
            (
                intervalTokenASupplyAPR_,
                intervalTokenBSupplyAPR_,
                tokenAIncome_,
                tokenBIncome_
            ) = recalculateSupplyAPR();

            intervalSupplyAPR[lastTimeStamp_][
                tokenA
            ] = intervalTokenASupplyAPR_;
            intervalSupplyAPR[lastTimeStamp_][
                tokenB
            ] = intervalTokenBSupplyAPR_;
            pendingRewards[tokenA] +=
                (totalSupplied[tokenA] * intervalTokenASupplyAPR_) /
                APRdecimals;
            pendingRewards[tokenB] +=
                (totalSupplied[tokenB] * intervalTokenBSupplyAPR_) /
                APRdecimals;

            totalIncome[tokenA] += tokenAIncome_;
            totalIncome[tokenB] += tokenBIncome_;
            tokenRewardsAmtTimestamp[lastTimeStamp_][tokenA] = tokenAIncome_;
            tokenRewardsAmtTimestamp[lastTimeStamp_][tokenB] = tokenBIncome_;

            setCREEKAPR(lastTimeStamp_);

            totalSupplied[tokenA] += intervalSupplied[tokenA];
            totalSupplied[tokenB] += intervalSupplied[tokenB];
            intervalSupplied[tokenA] = 0;
            intervalSupplied[tokenB] = 0;

            intervalFeesAccrued[tokenA] = 0;
            intervalFeesAccrued[tokenB] = 0;
        }
    }

    function setCREEKAPR(uint256 _lastTimeStamp) internal {
        if (_lastTimeStamp <= CREEKendTimestamp) {
            (
                intervalBorrowCREEKAPR[address(tokenA)][_lastTimeStamp],
                intervalBorrowCREEKAPR[address(tokenB)][_lastTimeStamp],
                intervalSupplyCREEKAPR[address(tokenA)][_lastTimeStamp],
                intervalSupplyCREEKAPR[address(tokenB)][_lastTimeStamp]
            ) = recalculateCREEKAPR();
        }
    }

    function getAccountHealth(address _user, address _token)
        public
        view
        returns (uint256 tokenHealth)
    {
        AccountInfo storage userInfo_ = users[_user];
        if (userInfo_.borrowedAmount[_token] == 0) {
            return 1000000000;
        }
        address collat_ = (_token == tokenA ? tokenB : tokenA);
        (uint256 newTokenFees_, ) = reconcileUserDebt(_user, _token);
        (uint256 newCollatRewards_, ) = reconcileUserDeposit(_user, collat_);
        // uint256 tokenPrice_;
        // uint256 collatPrice_;
        // (, int256 intpriceA, , , ) = priceFeedtokenA.latestRoundData();
        // (, int256 intpriceB, , , ) = priceFeedtokenB.latestRoundData();

        uint256 tokenBorrowValue_ = ((userInfo_.borrowedAmount[_token] +
            userInfo_.pendingFees[_token] +
            newTokenFees_ +
            todaysFees(_user, _token)) * tokenPrice[_token]) / priceDecimals;
        uint256 tokenDepositedValue_ = ((userInfo_.depositedAmount[collat_] +
            userInfo_.pendingRewards[collat_] +
            newCollatRewards_) * tokenPrice[collat_]) / priceDecimals;

        tokenHealth =
            ((tokenDepositedValue_ * 10000 * accountHealthDec) /
                tokenBorrowValue_) /
            collatPercent;
    }

    function exchangeUserCollat(
        // address _user,
        address _collatToken,
        address _debtToken,
        // uint256 _debtAmt,
        uint256 _collatAmt
    ) internal returns (uint256) {
        uint256 recieveAmt_;

        recieveAmt_ =
            (_collatAmt * tokenPrice[_collatToken]) /
            tokenPrice[_debtToken];

        IERC20(_collatToken).transfer(exchange, _collatAmt);
        IERC20(_debtToken).transferFrom(exchange, address(this), recieveAmt_);
        return recieveAmt_;
    }

    function liquidate(address _user, address _position)
        external
        whenNotPaused
    {
        updateTokenPrice();
        updateTimeArray();
        uint256 tokenHealth_ = getAccountHealth(_user, _position);
        address collat_ = (_position == tokenA ? tokenB : tokenA);
        require(tokenHealth_ < accountHealthDec, "Acc is healthy");

        uint256 protocolProfit_;
        uint256 totProfit_;
        AccountInfo storage userInfo_ = users[_user];

        reconcileSenderDebt(_user);
        reconcileSenderDeposit(_user);

        uint256 recievedAmt_ = exchangeUserCollat(
            // _user,
            collat_,
            _position,
            // userInfo_.borrowedAmount[_position] +
            //     userInfo_.pendingFees[_position],
            userInfo_.depositedAmount[collat_] +
                userInfo_.pendingRewards[collat_]
        );

        if (
            recievedAmt_ >
            userInfo_.borrowedAmount[_position] +
                userInfo_.pendingFees[_position]
        ) {
            totProfit_ =
                recievedAmt_ -
                userInfo_.borrowedAmount[_position] +
                userInfo_.pendingFees[_position];
            protocolProfit_ = (totProfit_ * 85) / 100;
        }
        liquidationRevenue[_position] += protocolProfit_;
        IERC20(_position).transfer(msg.sender, totProfit_ - protocolProfit_);

        emit Liquidation(
            "Position liquidated",
            _user,
            userInfo_.borrowedAmount[_position],
            userInfo_.depositedAmount[collat_]
        );

        totalBorrowed[_position] -= userInfo_.borrowedAmount[_position];
        totalSupplied[collat_] -= userInfo_.depositedAmount[collat_];
        //need to alter totalIncome[_position] too potentially
        //most likely not bc the liquidation profit is calculated
        //after subtrating pending fees

        userInfo_.depositedAmount[collat_] = 0;
        userInfo_.pendingRewards[collat_] = 0;
        userInfo_.borrowedAmount[_position] = 0;
        userInfo_.pendingFees[_position] = 0;
    }

    function recalculateCREEKAPR()
        public
        view
        returns (
            uint256 _tokenAborrowAPR,
            uint256 _tokenBborrowAPR,
            uint256 _tokenAsupplyAPR,
            uint256 _tokenBsupplyAPR
        )
    {
        if (totalBorrowed[tokenA] != 0) {
            _tokenAborrowAPR =
                (borrowCREEKperInterval[address(tokenA)] * APRdecimals) /
                totalBorrowed[tokenA];
        }
        if (totalBorrowed[tokenB] != 0) {
            _tokenBborrowAPR =
                (borrowCREEKperInterval[address(tokenB)] * APRdecimals) /
                totalBorrowed[tokenB];
        }

        if (totalSupplied[tokenA] != 0) {
            _tokenAsupplyAPR =
                (supplyCREEKperInterval[address(tokenA)] * APRdecimals) /
                totalSupplied[tokenA];
        }
        if (totalSupplied[tokenB] != 0)
            _tokenBsupplyAPR =
                (supplyCREEKperInterval[address(tokenB)] * APRdecimals) /
                totalSupplied[tokenB];
    }

    function recalculateBorrowAPR()
        public
        view
        returns (uint256 _tokenA1bAPR, uint256 _tokenB1bAPR)
    {
        if (totalSupplied[tokenA] != 0) {
            _tokenA1bAPR =
                (utilToAPM * totalBorrowed[tokenA] * compoundingInterval) /
                totalSupplied[tokenA] /
                1 minutes;
        }
        if (totalSupplied[tokenB] != 0) {
            _tokenB1bAPR =
                (utilToAPM * totalBorrowed[tokenB] * compoundingInterval) /
                totalSupplied[tokenB] /
                1 minutes;
        }
    }

    function recalculateSupplyAPR()
        public
        view
        returns (
            uint256 _tokenAspyAPR,
            uint256 _tokenBspyAPR,
            uint256 _tokenAIncome,
            uint256 _tokenBIncome
        )
    {
        uint256 timeStamp_ = compoundingTimestampArray[
            compoundingTimestampArray.length - 1
        ];
        uint256 previousTimeStamp_ = compoundingTimestampArray[
            compoundingTimestampArray.length - 2
        ];

        uint256 tokenArevenue_ = ((totalBorrowed[tokenA] *
            intervalBorrowAPR[timeStamp_][tokenA]) / APRdecimals) +
            intervalFeesAccrued[tokenA];
        uint256 tokenBrevenue_ = ((totalBorrowed[tokenB] *
            intervalBorrowAPR[timeStamp_][tokenB]) / APRdecimals) +
            intervalFeesAccrued[tokenB];

        _tokenAIncome = tokenArevenue_ / 2;
        _tokenBIncome = tokenBrevenue_ / 2;

        if (totalSupplied[tokenA] != 0) {
            _tokenAspyAPR =
                (tokenRewardsAmtTimestamp[previousTimeStamp_][tokenA] *
                    APRdecimals) /
                totalSupplied[tokenA];
        }
        if (totalSupplied[tokenB] != 0) {
            _tokenBspyAPR =
                (tokenRewardsAmtTimestamp[previousTimeStamp_][tokenB] *
                    APRdecimals) /
                totalSupplied[tokenB];
        }
    }

    function newUser() internal returns (bool _isnew) {
        AccountInfo storage userInfo_ = users[msg.sender];
        if (
            userInfo_.depositedAmount[tokenA] == 0 &&
            userInfo_.pendingDepositAmount[tokenA] == 0 &&
            userInfo_.depositedAmount[tokenB] == 0 &&
            userInfo_.pendingDepositAmount[tokenB] == 0
        ) {
            updateTimeArray();
            userInfo_.depositIndex = compoundingTimestampArray.length - 1;
            userInfo_.debtIndex = compoundingTimestampArray.length - 1;
            return (true);
        }
        if (
            userInfo_.borrowedAmount[tokenA] == 0 &&
            userInfo_.borrowedAmount[tokenB] == 0
        ) {
            updateTimeArray();
            userInfo_.debtIndex = compoundingTimestampArray.length - 1;
        }

        return (false);
    }

    function reconcileUserDebt(address _user, address _token)
        public
        view
        returns (uint256 _tokenFees, uint256 _CREEKrewards)
    {
        uint256 lastIndex_ = compoundingTimestampArray.length - 1;
        uint256 lastTimeStamp_ = compoundingTimestampArray[lastIndex_];
        AccountInfo storage userInfo_ = users[_user];
        uint256 debtIndex_ = userInfo_.debtIndex;

        while (debtIndex_ <= lastIndex_) {
            _tokenFees += ((userInfo_.borrowedAmount[_token] *
                intervalBorrowAPR[compoundingTimestampArray[debtIndex_]][
                    _token
                ]) / APRdecimals);
            _CREEKrewards += ((userInfo_.borrowedAmount[_token] *
                intervalBorrowCREEKAPR[_token][
                    compoundingTimestampArray[debtIndex_]
                ]) / APRdecimals);
            debtIndex_++;
        }

        (
            uint256 tokenABorrowAPR_,
            uint256 tokenBBorrowAPR_
        ) = recalculateBorrowAPR();

        uint256 tokenAPR_ = (
            _token == tokenA ? tokenABorrowAPR_ : tokenBBorrowAPR_
        );

        while (block.timestamp >= lastTimeStamp_ + compoundingInterval) {
            _tokenFees += ((userInfo_.borrowedAmount[_token] * tokenAPR_) /
                APRdecimals);
            lastTimeStamp_ += compoundingInterval;
        }
    }

    function reconcileUserDeposit(address _user, address _token)
        public
        view
        returns (uint256 _tokenRewards, uint256 _CREEKrewards)
    {
        uint256 lastIndex_ = compoundingTimestampArray.length - 1;
        uint256 lastTimeStamp_ = compoundingTimestampArray[lastIndex_];
        AccountInfo storage userInfo_ = users[_user];
        uint256 depositIndex_ = userInfo_.depositIndex;
        uint256 depositAmount_ = userInfo_.depositedAmount[_token];
        uint256 pendingDepositAmount_ = userInfo_.pendingDepositAmount[_token];

        while (depositIndex_ <= lastIndex_) {
            _tokenRewards += ((depositAmount_ *
                intervalSupplyAPR[compoundingTimestampArray[depositIndex_]][
                    _token
                ]) / APRdecimals);
            _CREEKrewards += ((depositAmount_ *
                intervalSupplyCREEKAPR[_token][
                    compoundingTimestampArray[depositIndex_]
                ]) / APRdecimals);

            depositAmount_ += pendingDepositAmount_;
            pendingDepositAmount_ = 0;
            depositIndex_++;
        }

        (
            uint256 tokenASupplyAPR_,
            uint256 tokenBSupplyAPR_,
            ,

        ) = recalculateSupplyAPR();

        uint256 supplyAPR_ = (
            _token == tokenA ? tokenASupplyAPR_ : tokenBSupplyAPR_
        );

        while (block.timestamp >= lastTimeStamp_ + compoundingInterval) {
            _tokenRewards += (depositAmount_ * supplyAPR_) / APRdecimals;
            lastTimeStamp_ += compoundingInterval;
        }
    }

    // function reconcileUserInterest(address _user)
    //     public
    //     view
    //     returns (
    //         uint256 _tokenArewards,
    //         uint256 _tokenBrewards,
    //         uint256 _tokenAfees,
    //         uint256 _tokenBfees // uint256 totalPULSrewards
    //     )
    // {
    //     uint256 lastIndex_ = compoundingTimestampArray.length - 1;
    //     uint256 lastTimeStamp_ = compoundingTimestampArray[lastIndex_];
    //     AccountInfo storage userInfo_ = users[_user];
    //     uint256 entryIndex_ = userInfo_.entryIndex;
    //     uint256 skipInterval = 0;

    //     // uint256 userBorrowPULS;
    //     // uint256 userSupplyPULS;

    //     while (entryIndex_ <= lastIndex_) {
    //         _tokenAfees += ((userInfo_.borrowedAmount[tokenA] *
    //             intervalBorrowAPR[compoundingTimestampArray[entryIndex_]][
    //                 tokenA
    //             ]) / APRdecimals);
    //         _tokenBfees += ((userInfo_.borrowedAmount[tokenB] *
    //             intervalBorrowAPR[compoundingTimestampArray[entryIndex_]][
    //                 tokenB
    //             ]) / APRdecimals);

    //         // userBorrowPULS += ((userTokenAborrowed *
    //         //     _intervalBorrowPULSAPR[address(_tokenA)][
    //         //         _compoundingTimestampArray[userIndex]
    //         //     ]) / APRdecimals);
    //         // userBorrowPULS += ((userTokenBborrowed *
    //         //     _intervalBorrowPULSAPR[address(_tokenB)][
    //         //         _compoundingTimestampArray[userIndex]
    //         //     ]) / APRdecimals);

    //         if (skipInterval != 0) {
    //             _tokenArewards +=
    //                 (userInfo_.depositedAmount[tokenA] *
    //                     intervalSupplyAPR[
    //                         compoundingTimestampArray[entryIndex_]
    //                     ][tokenA]) /
    //                 APRdecimals;

    //             _tokenBrewards +=
    //                 (userInfo_.depositedAmount[tokenB] *
    //                     intervalSupplyAPR[
    //                         compoundingTimestampArray[entryIndex_]
    //                     ][tokenB]) /
    //                 APRdecimals;
    //         }

    //         // userSupplyPULS += ((userTokenAdeposited *
    //         //     _intervalSupplyPULSAPR[address(_tokenA)][
    //         //         _compoundingTimestampArray[userIndex + 1]
    //         //     ]) / APRdecimals);
    //         // userSupplyPULS += ((userTokenBdeposited *
    //         //     _intervalSupplyPULSAPR[address(_tokenB)][
    //         //         _compoundingTimestampArray[userIndex + 1]
    //         //     ]) / APRdecimals);

    //         entryIndex_++;
    //         skipInterval += 1;
    //     }

    //     (
    //         uint256 tokenABorrowAPR_,
    //         uint256 tokenBBorrowAPR_
    //     ) = recalculateBorrowAPR();

    //     (
    //         uint256 tokenASupplyAPR_,
    //         uint256 tokenBSupplyAPR_,
    //         ,

    //     ) = recalculateSupplyAPR();

    //     while (block.timestamp >= lastTimeStamp_ + compoundingInterval) {
    //         _tokenAfees +=
    //             (userInfo_.borrowedAmount[tokenA] * tokenABorrowAPR_) /
    //             APRdecimals;
    //         _tokenBfees +=
    //             (userInfo_.borrowedAmount[tokenB] * tokenBBorrowAPR_) /
    //             APRdecimals;

    //         _tokenArewards +=
    //             (userInfo_.depositedAmount[tokenA] * tokenASupplyAPR_) /
    //             APRdecimals;
    //         _tokenBrewards +=
    //             (userInfo_.depositedAmount[tokenB] * tokenBSupplyAPR_) /
    //             APRdecimals;

    //         lastTimeStamp_ += compoundingInterval;
    //     }

    //     // totalPULSrewards = userBorrowPULS + userSupplyPULS;
    // }

    function reconcileSenderDebt(address _user) internal {
        updateTimeArray();
        (uint256 userTokenAfees_, uint256 tokenACREEK_) = reconcileUserDebt(
            _user,
            tokenA
        );
        (uint256 userTokenBfees_, uint256 tokenBCREEK_) = reconcileUserDebt(
            _user,
            tokenB
        );
        users[_user].pendingFees[tokenA] += userTokenAfees_;
        users[_user].pendingFees[tokenB] += userTokenBfees_;
        users[_user].pendingCREEK += (tokenACREEK_ + tokenBCREEK_);
        users[_user].debtIndex = compoundingTimestampArray.length - 1;
    }

    function reconcileSenderDeposit(address _user) internal {
        updateTimeArray();
        if (users[_user].depositIndex < compoundingTimestampArray.length - 1) {
            (
                uint256 userTokenArewards_,
                uint256 tokenACREEK_
            ) = reconcileUserDeposit(_user, tokenA);
            (
                uint256 userTokenBrewards_,
                uint256 tokenBCREEK_
            ) = reconcileUserDeposit(_user, tokenB);
            users[_user].depositedAmount[tokenA] += users[_user]
                .pendingDepositAmount[tokenA];
            users[_user].depositedAmount[tokenB] += users[_user]
                .pendingDepositAmount[tokenB];
            users[_user].pendingDepositAmount[tokenA] = 0;
            users[_user].pendingDepositAmount[tokenB] = 0;
            users[_user].pendingRewards[tokenA] += userTokenArewards_;
            users[_user].pendingRewards[tokenB] += userTokenBrewards_;
            users[_user].pendingCREEK += (tokenACREEK_ + tokenBCREEK_);
            users[_user].depositIndex = compoundingTimestampArray.length - 1;
        }
    }

    // function reconcileSenderInterest(address _user) internal {
    //     updateTimeArray();
    //     (
    //         uint256 userTokenArewards_,
    //         uint256 userTokenBrewards_,
    //         uint256 userTokenAfees_,
    //         uint256 userTokenBfees_
    //     ) = reconcileUserInterest(_user);

    //     users[_user].pendingFees[tokenA] += userTokenAfees_;
    //     users[_user].pendingFees[tokenB] += userTokenBfees_;
    //     users[_user].entryIndex = compoundingTimestampArray.length - 1;
    //     users[_user].pendingRewards[tokenA] += userTokenArewards_;
    //     users[_user].pendingRewards[tokenB] += userTokenBrewards_;
    //}

    function todaysFees(address _user, address _token)
        public
        view
        returns (uint256 _todaysFeesAmt)
    {
        (
            uint256 recentTokenABorrowAPR_,
            uint256 recentTokenBBorrowAPR_
        ) = recalculateBorrowAPR();

        uint256 recentAPR_ = (
            _token == tokenA ? recentTokenABorrowAPR_ : recentTokenBBorrowAPR_
        );

        _todaysFeesAmt =
            (users[_user].borrowedAmount[_token] * recentAPR_) /
            APRdecimals;
    }

    function _depositToken(address _token, uint256 _amount) internal {
        updateTokenPrice();
        if (_token == wbera) {
            IWETH(wbera).deposit{value: msg.value}();
            users[msg.sender].pendingDepositAmount[wbera] += msg.value;
            intervalSupplied[_token] += msg.value;
            emit Log(
                "token deposited",
                msg.sender,
                msg.value,
                users[msg.sender].pendingDepositAmount[_token]
            );
        } else {
            IERC20(_token).transferFrom(msg.sender, address(this), _amount);
            users[msg.sender].pendingDepositAmount[_token] += _amount;
            intervalSupplied[_token] += _amount;
            emit Log(
                "token deposited",
                msg.sender,
                _amount,
                users[msg.sender].pendingDepositAmount[_token]
            );
        }
    }

    function _initiateWithdraw(address _token, uint256 _amount) internal {
        updateTokenPrice();
        address debtToken_ = (_token == tokenA ? tokenB : tokenA);
        AccountInfo storage userInfo_ = users[msg.sender];

        uint256 userBorrowedAmt_ = userInfo_.borrowedAmount[debtToken_] +
            userInfo_.pendingFees[debtToken_];
        uint256 userDepositedAmt_ = (
            distributeFees
                ? userInfo_.depositedAmount[_token] +
                    userInfo_.pendingRewards[_token]
                : userInfo_.depositedAmount[_token]
        );

        require(_amount <= userDepositedAmt_, "Withdraw > balance");

        if (userDepositedAmt_ - _amount == 0) {
            require(userBorrowedAmt_ == 0, "Repay entire debt first");
        } else {
            require(
                (userBorrowedAmt_ * tokenPrice[debtToken_] * collatPercent) /
                    10000 <=
                    (userDepositedAmt_ - _amount) * tokenPrice[_token],
                "Repay some debt first"
            );
        }

        uint256 supplyWithdrawn_;

        if (_amount <= userInfo_.depositedAmount[_token]) {
            userInfo_.depositedAmount[_token] -= _amount;
            supplyWithdrawn_ = _amount;
        } else {
            uint256 interestWithdraw_ = _amount -
                userInfo_.depositedAmount[_token];
            supplyWithdrawn_ = userInfo_.depositedAmount[_token];
            userInfo_.depositedAmount[_token] = 0;
            userInfo_.pendingRewards[_token] -= interestWithdraw_;
            // pendingRewards[_token] -= interestWithdraw_;
        }
        if (totalSupplied[_token] >= supplyWithdrawn_) {
            totalSupplied[_token] -= supplyWithdrawn_;
        } else {
            revert("Try back in one epoch");
        }

        userInfo_.pendingWithdrawl[_token] += _amount;

        // require(
        //     IERC20(_token).transfer(msg.sender, _amount),
        //     "Token transfer Err"
        // );
    }

    function _borrowToken(address _token, uint256 _amount) internal {
        updateTokenPrice();
        address collatToken_ = (_token == tokenA ? tokenB : tokenA);
        AccountInfo storage userInfo_ = users[msg.sender];

        uint256 userCollatValue_ = ((userInfo_.depositedAmount[collatToken_] +
            userInfo_.pendingRewards[collatToken_] +
            userInfo_.pendingDepositAmount[collatToken_]) *
            tokenPrice[collatToken_]);
        uint256 userWantValue_ = ((userInfo_.borrowedAmount[_token] +
            userInfo_.pendingFees[_token] +
            _amount) * tokenPrice[_token]);

        require(
            userWantValue_ / tokenDecimals >= minBorrowValue,
            "Min borrow amt not met"
        );
        require(
            (userWantValue_ * collatPercent) / 10000 <= userCollatValue_,
            "Not enough collateral"
        );
        userInfo_.borrowedAmount[_token] += _amount;
        totalBorrowed[_token] += _amount;
        if (_token == wbera) {
            IWETH(wbera).withdraw(_amount);
            payable(msg.sender).transfer(_amount);
        } else {
            IERC20(_token).transfer(msg.sender, _amount);
        }
    }

    function _repayToken(
        address _token,
        uint256 _amount,
        uint256 _newTokenDebt,
        uint256 _userDebt
    ) internal {
        updateTokenPrice();
        AccountInfo storage userInfo_ = users[msg.sender];

        if (_token == wbera) {
            IWETH(wbera).deposit{value: msg.value}();
        } else {
            IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        }

        if (_amount <= userInfo_.borrowedAmount[_token]) {
            require(
                minBorrowAmount[_token] <=
                    userInfo_.borrowedAmount[_token] - _amount,
                "Debt left is below min borrow amt"
            );
            // require(
            //     IERC20(_token).transferFrom(msg.sender, address(this), _amount),
            //     "Token transfer err"
            // );
            uint256 principle = _amount -
                (userInfo_.pendingFees[_token] + _newTokenDebt);
            totalBorrowed[_token] -= principle;
            intervalFeesAccrued[_token] += _newTokenDebt;
            userInfo_.borrowedAmount[_token] -= principle;
            userInfo_.pendingFees[_token] = 0;
        } else {
            require(_amount >= _userDebt, "Not enough to pay all interest");
            // require(
            //     IERC20(_token).transferFrom(msg.sender, address(this), _amount),
            //     "Token transfer err"
            // );
            extraTokenSent[_token] += _amount - _userDebt;
            totalFeesPaid[_token] += (userInfo_.pendingFees[_token] +
                _newTokenDebt);
            intervalFeesAccrued[_token] += _newTokenDebt;
            // pendingFees[_token] -= userInfo_.pendingFees[_token];
            totalBorrowed[_token] -= userInfo_.borrowedAmount[_token];
            userInfo_.borrowedAmount[_token] = 0;
            userInfo_.pendingFees[_token] = 0;
        }
    }

    function depositToken(address _token, uint256 _amount)
        public
        payable
        whenNotPaused
        nonReentrant
    {
        require(_token == tokenA || _token == tokenB, "Invalid token");
        if (!newUser()) {
            reconcileSenderDeposit(msg.sender);
        }
        if (_token == wbera) {
            _depositToken(_token, msg.value);
        } else {
            _depositToken(_token, _amount);
        }
    }

    function initiateWithdraw(address _token, uint256 _amount)
        public
        whenNotPaused
        withdrawEnabled
        nonReentrant
    {
        require(_token == tokenA || _token == tokenB, "Invalid token");
        if (!newUser()) {
            reconcileSenderDeposit(msg.sender);
        }
        _initiateWithdraw(_token, _amount);
    }

    function withdrawToken(address _token)
        public
        whenNotPaused
        withdrawEnabled
        nonReentrant
    {
        updateTimeArray();
        require(_token == tokenA || _token == tokenB, "Invalid token");
        require(
            users[msg.sender].depositIndex <
                compoundingTimestampArray.length - 1,
            "try after 1 epoch"
        );
        require(
            users[msg.sender].pendingWithdrawl[_token] != 0,
            "pending withdrawl = 0"
        );
        uint256 amount_ = users[msg.sender].pendingWithdrawl[_token];
        users[msg.sender].pendingWithdrawl[_token] = 0;
        if (_token == wbera) {
            IWETH(wbera).withdraw(amount_);
            payable(msg.sender).transfer(amount_);
        } else {
            IERC20(_token).transfer(msg.sender, amount_);
        }
    }

    function borrowToken(address _token, uint256 _amount)
        public
        payable
        whenNotPaused
        nonReentrant
    {
        require(_token == tokenA || _token == tokenB, "Invalid token");
        if (!newUser()) {
            reconcileSenderDeposit(msg.sender);
            reconcileSenderDebt(msg.sender);
        }
        _borrowToken(_token, _amount);
    }

    function repayToken(address _token, uint256 _amount)
        public
        payable
        whenNotPaused
        nonReentrant
    {
        require(_token == tokenA || _token == tokenB, "Invalid token");
        if (!newUser()) {
            reconcileSenderDebt(msg.sender);
        }
        uint256 newTokenDebt_ = todaysFees(msg.sender, _token);
        uint256 userDebt_ = (users[msg.sender].borrowedAmount[_token] +
            users[msg.sender].pendingFees[_token] +
            newTokenDebt_);
        _repayToken(_token, _amount, newTokenDebt_, userDebt_);
    }

    function claimCREEK() public whenNotPaused nonReentrant {
        uint256 amount_ = users[msg.sender].pendingCREEK;
        users[msg.sender].pendingCREEK = 0;
        IERC20(CREEK).transfer(msg.sender, amount_);
    }
}