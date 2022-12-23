// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9; // because of uni|cake swap

import "./HedgeFund.sol";
import "./interfaces/IFundFactory.sol";
import "./tokens/eFund.sol";

/* 
    ERR MSG ABBREVIATION
CE0 : Hard cap must be bigger than soft cap
CE1 : Invalid argument: Value sended must be <= hardCap

*/
contract FundFactory is IFundFactory {
    function createFund(HedgeFundInfo calldata _hedgeFundInfo)
        external
        payable
        override
        returns (address)
    {
        require(_hedgeFundInfo.hardCap > _hedgeFundInfo.softCap, "CE0");

        require(msg.value <= _hedgeFundInfo.hardCap, "CE1");

        HedgeFund newFund = new HedgeFund(_hedgeFundInfo);

        payable(address(newFund)).transfer(msg.value);

        return address(newFund);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IHedgeFund.sol";
import "./FundFactory.sol";
import "./interfaces/IFundTrade.sol";
import "./libraries/MathPercentage.sol";
import "./EFundPlatform.sol";
import "./structs/HedgeFundInfo.sol";

struct SwapInfo {
    address from;
    address to;
    uint256 amountFrom;
    uint256 amountTo;
    uint256 timeStamp;
    uint256 block;
}

// library TradeLibrary {
//     function swapAllTokensIntoETH(UniswapV2Router02 router, address[] memory tokens, address to) public {
//         for (uint256 i; i < tokens.length; i++) {
//             address[] memory path = _createPath(
//                 tokens[i],
//                 router.WETH()
//             );

//             uint256 amountIn = IERC20(tokens[i]).balanceOf(
//                 address(this)
//             );

//             if (amountIn == 0) continue;

//             boughtTokenAddresses[i].deletgatecall(abi.encodeWithSignature("approve(address,uint256)",address(router),amountIn );

//             router.swapExactTokensForETH(
//                 amountIn,
//                 0,
//                 path,
//                 address(this),
//                 block.timestamp + depositTXDeadlineSeconds
//             );

//             delete boughtTokenAddresses[i];
//         }
//     }
// }

contract HedgeFund is IHedgeFund, IFundTrade {
    event NewDeposit(
        address indexed _depositOwner,
        uint256 indexed _id,
        uint256 indexed _depositAmount
    );

    event FundStatusChanged(uint256 _newStatus);

    event DepositWithdrawedBeforeActiveState(
        address indexed _depositOwner,
        uint256 indexed _amount
    );

    event TokensSwap(
        address indexed _tokenFrom,
        address indexed _tokenTo,
        uint256 _amountFrom,
        uint256 indexed _amountTo
    );

    event DepositsWitdrawed(
        address indexed _depositor,
        uint256 indexed _amount
    );

    DepositInfo[] private _deposits;

    SwapInfo[] private _swapsInfo;

    mapping(address => uint256) public userDeposits;

    address payable[] private _boughtTokenAddresses;

    address payable[] private _allowedTokenAddresses;

    FundStatus public fundStatus;

    IERC20 public immutable eFundToken;

    EFundPlatform public immutable eFundPlatform;

    IUniswapV2Router02 public immutable router;

    uint256 private immutable _minimalDepositAmount;

    uint256 public immutable fundCreatedAt;

    uint256 private immutable _fundCanBeStartedMinimumAt;

    uint256 private immutable _softCap;

    uint256 private immutable _hardCap;

    uint256 private immutable _managerCollateral;

    address payable public immutable fundManager;

    uint256 public immutable fundDurationMonths;

    uint256 private immutable _profitFee;

    uint256 private _fundStartTimestamp;

    uint256 public baseBalance;

    uint256 public endBalance;

    uint256 public originalEndBalance;

    uint256 public lockedFundProfit; // in eth|bnb

    bool public fundProfitWitdrawed;

    mapping(address => bool) private _isTokenBought; // this 2 mappings are needed to not iterate through arrays (that can be very big)

    mapping(address => bool) private _isTokenAllowed;

    uint256 private constant _DEPOSIT_TX_DEADLINE_SECONDS = 30 * 60; // 30 minutes  (time after which deposit TX will revert)

    uint256 private constant _MONTH_DURATION = 30 days;

    /* 
        NP - You have not permissions to this action
        SA - Fund should be in an Active state
        SO - Fund should be in an Opened state
        SC - Fund should be in a Completed state
    */
    function _onlyForFundManager() private view {
        require(msg.sender == fundManager || msg.sender == address(this), "NP");
    }

    function _onlyInActiveState() private view {
        require(fundStatus == FundStatus.ACTIVE, "SA");
    }

    function _onlyInOpenedState() private view {
        require(fundStatus == FundStatus.OPENED, "SO");
    }

    function _onlyInCompletedState() private view {
        require(fundStatus == FundStatus.COMPLETED, "SC");
    }

    /* 
        ID - Invalid duration
    */
    constructor(HedgeFundInfo memory _hedgeFundInfo) {
        require(_validateDuration(_hedgeFundInfo.duration), "ID");

        router = IUniswapV2Router02(_hedgeFundInfo.swapRouterContract);
        eFundToken = IERC20(_hedgeFundInfo.eFundTokenContract);
        eFundPlatform = EFundPlatform(_hedgeFundInfo.eFundPlatform);

        fundManager = _hedgeFundInfo.managerAddress;
        fundStatus = FundStatus.OPENED;
        fundDurationMonths = _hedgeFundInfo.duration;
        _softCap = _hedgeFundInfo.softCap;
        _hardCap = _hedgeFundInfo.hardCap;
        _allowedTokenAddresses = _hedgeFundInfo.allowedTokenAddresses;
        fundCreatedAt = block.timestamp;
        _fundCanBeStartedMinimumAt =
            block.timestamp +
            _hedgeFundInfo.minTimeUntilFundStart;
        _minimalDepositAmount = _hedgeFundInfo.minimalDepostitAmount;
        _managerCollateral = _hedgeFundInfo.managerCollateral;
        _profitFee = _hedgeFundInfo.profitFee;

        for (uint256 i; i < _hedgeFundInfo.allowedTokenAddresses.length; i++)
            _isTokenAllowed[_hedgeFundInfo.allowedTokenAddresses[i]] = true;
    }

    function getFundInfo()
        public
        view
        returns (
            address _fundManager,
            uint256 _fundStartTimestamp,
            uint256 _minDepositAmount,
            uint256 _fundCanBeStartedAt,
            uint256 _fundDurationInMonths,
            uint256 _profitFee,
            FundStatus _fundStatus,
            uint256 _currentBalance,
            uint256 _managerCollateral,
            uint256 _hardCap,
            uint256 _softCap,
            DepositInfo[] memory _deposits
        )
    // uint256 _investorsAmount
    {
        return (
            fundManager,
            _fundStartTimestamp,
            _minimalDepositAmount,
            _fundCanBeStartedMinimumAt,
            fundDurationMonths,
            _profitFee,
            fundStatus,
            address(this).balance,
            _managerCollateral,
            _hardCap,
            _softCap,
            _deposits
        );
    }

    function getAllDeposits() public view returns (DepositInfo[] memory) {
        return _deposits;
    }

    function getAllSwaps() public view returns (SwapInfo[] memory) {
        return _swapsInfo;
    }

    /// @notice get end time of the fund
    function getEndTime() external view override returns (uint256) {
        return _getEndTime();
    }

    function getBoughtTokensAddresses()
        public
        view
        returns (address payable[] memory)
    {
        return _boughtTokenAddresses;
    }

    function getAllowedTokensAddresses()
        public
        view
        returns (address payable[] memory)
    {
        return _allowedTokenAddresses;
    }

    /* 
        CS - Fund cannot be started at that moment
    */
    function setFundStatusActive() external override {
        _onlyForFundManager();
        _onlyInOpenedState();
        require(_fundCanBeStartedMinimumAt < block.timestamp, "CS");

        _updateFundStatus(FundStatus.ACTIVE);
        baseBalance = _currentBalanceWithoutManagerCollateral();
        _fundStartTimestamp = block.timestamp;

        emit FundStatusChanged(uint256(fundStatus));
    }

    /*
        NF - Fund is didn`t finish yet
    */
    function setFundStatusCompleted() external override {
        _onlyInActiveState();
        require(block.timestamp > _getEndTime(), "NF"); // commented for testing

        _swapAllTokensIntoETH();

        _updateFundStatus(FundStatus.COMPLETED);

        // dosent count manager collateral
        originalEndBalance = _currentBalanceWithoutManagerCollateral();

        int256 totalFundFeePercentage;

        if (originalEndBalance < baseBalance) {
            totalFundFeePercentage = eFundPlatform.NO_PROFIT_FUND_FEE();
        } else {
            totalFundFeePercentage = int256(_profitFee);
        }

        lockedFundProfit = uint256(
            MathPercentage.calculateNumberFromPercentage(
                MathPercentage.translsatePercentageFromBase(
                    totalFundFeePercentage,
                    100
                ),
                int256(originalEndBalance)
            )
        );

        if (originalEndBalance - lockedFundProfit < baseBalance) {
            // cannot pay all investemnts - so manager collateral counts too
            endBalance = _currentBalance();
        } else {
            endBalance = _currentBalanceWithoutManagerCollateral();
        }

        eFundPlatform.closeFund();

        emit FundStatusChanged(uint256(fundStatus));
    }

    /*
        FS - Fund should be started
    */
    function _swapAllTokensIntoETH() private {
        for (uint256 i; i < _boughtTokenAddresses.length; i++) {
            address[] memory path = _createPath(
                _boughtTokenAddresses[i],
                router.WETH()
            );

            uint256 amountIn = IERC20(_boughtTokenAddresses[i]).balanceOf(
                address(this)
            );

            if (amountIn == 0) continue;

            IERC20(_boughtTokenAddresses[i]).approve(address(router), amountIn);

            router.swapExactTokensForETH(
                amountIn,
                0,
                path,
                address(this),
                block.timestamp + _DEPOSIT_TX_DEADLINE_SECONDS
            );

            delete _boughtTokenAddresses[i];
        }
    }

    /// @notice make deposit into hedge fund. Default min is 0.1 ETH and max is 100 ETH in eFund equivalent
    /*
        TL - Transaction value is less then minimum deposit amout
        MO - Max cap is overflowed. Try to send lower value

    */
    function makeDeposit() external payable override {
        _onlyInOpenedState();
        require(msg.value >= _minimalDepositAmount, "TL");

        require(
            _currentBalanceWithoutManagerCollateral() + msg.value <= _hardCap,
            "MO"
        );

        DepositInfo memory deposit = DepositInfo(
            payable(msg.sender),
            msg.value
        );

        userDeposits[msg.sender] = userDeposits[msg.sender] + msg.value;

        _deposits.push(deposit);

        eFundPlatform.onDepositMade(msg.sender);
    }

    /// @notice withdraw your deposits before trading period is started
    /*
        CW - Cannot withdraw fund now
        ND - You have no deposits in this fund
    */
    function withdrawDepositsBeforeFundStarted() external override {
        _onlyInOpenedState();
        require(block.timestamp > _fundCanBeStartedMinimumAt, "CW");

        require(userDeposits[msg.sender] != 0, "ND");
        uint256 totalDepositsAmount = userDeposits[msg.sender];

        userDeposits[msg.sender] = 0;

        _withdraw(DepositInfo(payable(msg.sender), totalDepositsAmount));

        emit DepositWithdrawedBeforeActiveState(
            msg.sender,
            totalDepositsAmount
        );
    }

    /*
        ND - Address has no deposits in this fund
    */
    function withdrawDepositsOf(address payable _of) external override {
        _onlyInCompletedState();

        require(userDeposits[_of] != 0, "ND");

        uint256 totalDepositsAmount = userDeposits[_of];

        userDeposits[_of] = 0;

        _withdraw(DepositInfo(_of, totalDepositsAmount));

        emit DepositsWitdrawed(_of, totalDepositsAmount);
    }

    /* 
        B0 - Balance is 0, nothing to withdraw
        C0 - Can withdraw only after all depositst were withdrawed
        PW - Fund profit is already withdrawed
    */
    /// @dev withdraw manager and platform profits
    function withdrawFundProfit() external override {
        _onlyInCompletedState();
        require(!fundProfitWitdrawed, "PW");
        require(_currentBalance() > 0, "B0");

        fundProfitWitdrawed = true;

        uint256 platformFee;
        uint256 managerProfit;

        if (baseBalance >= originalEndBalance) {
            platformFee = lockedFundProfit;
        } else {
            // otherwise
            platformFee = uint256(
                MathPercentage.calculateNumberFromPercentage(
                    MathPercentage.translsatePercentageFromBase(
                        100 -
                            eFundPlatform.calculateManagerRewardPercentage(
                                fundManager
                            ),
                        100
                    ),
                    int256(lockedFundProfit)
                )
            );
        }

        // if manager > 0 means that fund was succeed and manager take some profit from it
        managerProfit = lockedFundProfit - platformFee;

        // send fee to eFundPlatform
        if (_currentBalance() >= platformFee)
            payable(address(eFundPlatform)).transfer(platformFee);

        // sending the rest to the fund manager
        if (managerProfit > 0 && _currentBalance() >= managerProfit) {
            fundManager.transfer(managerProfit);
        }

        // withdraw manager collaterall
        // if originalEndBalance == endBalance - manager collateral doesnt included into endBalance
        if (
            managerProfit > 0 &&
            originalEndBalance == endBalance &&
            _currentBalance() >= _managerCollateral
        ) {
            fundManager.transfer(_managerCollateral);
        }
    }

    /*  ERR MSG ABBREVIATION

        P0 : Path must be >= 2
        T0 : Trading with not allowed tokens
        T1 : You must to own {tokenFrom} first
        T2 : Output amount is lower then {amountOutMin}
    */
    function swapERC20ToERC20(
        address[] calldata path,
        uint256 amountIn,
        uint256 amountOutMin
    ) external override {
        _onlyForFundManager();
        _onlyInActiveState();
        require(path.length >= 2, "P0");

        address tokenFrom = path[0];
        address tokenTo = path[path.length - 1];

        for (uint256 i; i < path.length; i++) {
            require(
                _allowedTokenAddresses.length == 0
                    ? true // if empty array specified, all tokens are valid for trade
                    : _isTokenAllowed[path[i]],
                "T0"
            );
            require(_isTokenBought[tokenFrom], "T1");
        }

        // how much {tokenTo} we can buy with {tokenFrom} token
        uint256 amountOut = router.getAmountsOut(amountIn, path)[
            path.length - 1
        ];

        require(amountOut >= amountOutMin, "T2");

        IERC20(tokenFrom).approve(address(router), amountIn);

        uint256[] memory amounts = router.swapExactTokensForTokens(
            amountIn,
            amountOut,
            path,
            address(this),
            block.timestamp + _DEPOSIT_TX_DEADLINE_SECONDS
        );

        if (!_isTokenBought[tokenTo]) {
            _boughtTokenAddresses.push(payable(tokenTo));
            _isTokenBought[tokenTo] = true;
        }

        _onTokenSwapAction(
            tokenFrom,
            tokenTo,
            amountIn,
            amounts[path.length - 1]
        );
    }

    /*
        NO - You need to own {tokenFrom} first
        OL - Output amount is lower then {amountOutMin}
    */
    function swapERC20ToETH(
        address payable tokenFrom,
        uint256 amountIn,
        uint256 amountOutMin
    ) external override {
        _onlyForFundManager();
        _onlyInActiveState();
        require(_isTokenBought[tokenFrom], "NO");

        address[] memory path = _createPath(tokenFrom, router.WETH());

        // how much {tokenTo} we can buy with ether
        uint256 amountOut = router.getAmountsOut(amountIn, path)[1];

        require(amountOut >= amountOutMin, "OL");

        IERC20(tokenFrom).approve(address(router), amountIn);

        uint256[] memory amounts = router.swapExactTokensForETH(
            amountIn,
            amountOut,
            path,
            address(this),
            block.timestamp + _DEPOSIT_TX_DEADLINE_SECONDS
        );

        _onTokenSwapAction(path[0], path[1], amountIn, amounts[1]);
    }

    /*
        IA - Insufficient amount of ETH
        NA - Trading with not allowed tokens
        OL - Output amount is lower then {amountOutMin}
    */
    function swapETHToERC20(
        address payable tokenTo,
        uint256 amountIn,
        uint256 amountOutMin
    ) external override {
        _onlyForFundManager();
        _onlyInActiveState();
        require(amountIn < _currentBalanceWithoutManagerCollateral(), "IA");

        require(
            _allowedTokenAddresses.length == 0
                ? true // if empty array specified, all tokens are valid for trade
                : _isTokenAllowed[tokenTo],
            "NA"
        );

        address[] memory path = _createPath(router.WETH(), tokenTo);

        // how much {tokenTo} we can buy with ether
        uint256 amountOut = router.getAmountsOut(amountIn, path)[1];

        require(amountOut >= amountOutMin, "OL");
        uint256[] memory amounts = router.swapETHForExactTokens{
            value: amountIn
        }(
            amountOut,
            path,
            address(this),
            block.timestamp + _DEPOSIT_TX_DEADLINE_SECONDS
        );

        if (!_isTokenBought[tokenTo]) {
            _boughtTokenAddresses.push(tokenTo);
            _isTokenBought[tokenTo] = true;
        }
        _onTokenSwapAction(path[0], path[1], amountIn, amounts[1]);
    }

    function _withdraw(DepositInfo memory info) private {
        if (fundStatus == FundStatus.OPENED) {
            // if opened - it`s withdrawDepositsBeforeFundStarted call
            info.depositOwner.transfer(info.depositAmount);
            return;
        }

        info.depositOwner.transfer(
            uint256(
                MathPercentage.calculateNumberFromPercentage(
                    MathPercentage.calculateNumberFromNumberPercentage(
                        int256(info.depositAmount),
                        int256(baseBalance)
                    ),
                    int256(endBalance - lockedFundProfit)
                )
            )
        );
    }

    /// @return balance of current fund without managerCollateral
    function _currentBalanceWithoutManagerCollateral()
        private
        view
        returns (uint256)
    {
        return _currentBalance() - _managerCollateral;
    }

    function _currentBalance() private view returns (uint256) {
        return address(this).balance;
    }

    function _updateFundStatus(FundStatus newFundStatus) private {
        fundStatus = newFundStatus;
    }

    function _getEndTime() private view returns (uint256) {
        return _fundStartTimestamp + (fundDurationMonths * _MONTH_DURATION);
    }

    function _onTokenSwapAction(
        address _tokenFrom,
        address _tokenTo,
        uint256 _amountFrom,
        uint256 _amountTo
    ) private {
        emit TokensSwap(_tokenFrom, _tokenTo, _amountFrom, _amountTo);

        _swapsInfo.push(
            SwapInfo(
                _tokenFrom,
                _tokenTo,
                _amountFrom,
                _amountTo,
                block.timestamp,
                block.number
            )
        );
    }

    /// @dev create path array for uni|cake|etc.. swap
    function _createPath(address tokenFrom, address tokenTo)
        private
        pure
        returns (address[] memory)
    {
        address[] memory path = new address[](2);

        path[0] = tokenFrom;
        path[1] = tokenTo;

        return path;
    }

    // validate hedge fund active state duration. Only valid: 0(testing),1,2,3,6 months
    function _validateDuration(uint256 _d) private pure returns (bool) {
        return _d == 0 || _d == 1 || _d == 2 || _d == 3 || _d == 6;
    }

    // Functions to receive Ether
    receive() external payable {}

    fallback() external payable {}

    enum FundStatus {
        OPENED,
        ACTIVE,
        COMPLETED
    }

    struct DepositInfo {
        address payable depositOwner;
        uint256 depositAmount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IHedgeFund.sol";
import "../structs/HedgeFundInfo.sol";

interface IFundFactory {
    function createFund(HedgeFundInfo calldata _hedgeFundInfo)
        external
        payable
        returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract EFundERC20 is ERC20 {
    constructor() ERC20("eFund", "EF") {
        _mint(msg.sender, 10**18);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./FundFactory.sol";
import "./HedgeFund.sol";
import "./structs/HedgeFundInfo.sol";

contract EFundPlatform {
    event ClaimHolderRewardSuccessfully(
        address indexed recipient,
        uint256 indexed ethReceived,
        uint256 indexed nextAvailableClaimDate
    );

    HedgeFund[] private _funds;

    mapping(address => HedgeFund[]) private _managerFunds;

    mapping(address => HedgeFund[]) private _investorFunds;

    FundFactory public immutable fundFactory;

    IERC20 public immutable eFund;

    mapping(address => bool) public isFund;

    mapping(address => FundManagerActivityInfo) public managerFundActivity;

    mapping(address => mapping(address => bool)) public isInvestorOf;

    mapping(address => uint256) public nextAvailableRewardClaimDate;

    mapping(address => bool) public isExcludedFromReward;

    uint256 public constant REWARD_CYCLE_BLOCK = 7 days;

    uint256 public constant SILVER_PERIOD_START = 3 * 30 days; // 3 months

    uint256 public constant GOLD_PERIOD_START = 6 * 30 days; // 6 months

    uint256 public constant PERCENTAGE_BASE = 100;

    int256 public constant BRONZE_PERIOD_REWARD_PERCENTAGE = 10; // 10%

    int256 public constant SILVER_PERIOD_REWARD_PERCENTAGE = 20; // 20%

    int256 public constant GOLD_PERIOD_REWARD_PERCENTAGE = 30; // 30%

    int256 public constant NO_PROFIT_FUND_FEE = 3; // 3% - takes only when fund manager didnt made any profit of the fund

    uint256
        public constant MAXIMUM_MINIMAL_DEPOSIT_AMOUNT_FROM_HARD_CAP_PERCENTAGE =
        10;

    uint256 public constant MINIMUM_PROFIT_FEE = 1; // 1%

    uint256 public constant MAXIMUM_PROFIT_FEE = 10; // 10%

    uint256 public constant MINIMUM_TIME_UNTIL_FUND_START = 0 days;

    uint256 public constant MAXIMUM_TIME_UNTIL_FUND_START = 10 days;

    uint256 public immutable minimalManagerCollateral;

    uint256 public immutable softCap;

    uint256 public immutable hardCap;

    modifier onlyForFundContract() {
        require(isFund[msg.sender], "Caller address is not a fund");
        _;
    }

    constructor(
        address _fundFactory,
        address _efundToken,
        uint256 _softCap,
        uint256 _hardCap,
        uint256 _managerMinimalCollateral
    ) {
        require(
            _fundFactory != address(0),
            "Invalid fundFactory address provided"
        );
        require(
            _efundToken != address(0),
            "Invalid eFund token address provided"
        );
        require(_hardCap > _softCap, "Hard cap must be bigger than soft cap");
        require(
            _managerMinimalCollateral < _hardCap,
            "Minumal manager collateral cannot be >= hardCap"
        );

        hardCap = _hardCap;
        softCap = _softCap;

        minimalManagerCollateral = _managerMinimalCollateral;

        fundFactory = FundFactory(_fundFactory);
        eFund = IERC20(_efundToken);
    }

    function getPlatformData()
        public
        view
        returns (
            uint256 _softCap,
            uint256 _hardCap,
            uint256 _minimumTimeUntillFundStart,
            uint256 _maximumTimeUntillFundStart,
            uint256 _minimumProfitFee,
            uint256 _maximumProfitFee,
            uint256 _minimalManagerCollateral
        )
    {
        return (
            softCap,
            hardCap,
            MINIMUM_TIME_UNTIL_FUND_START,
            MAXIMUM_TIME_UNTIL_FUND_START,
            MINIMUM_PROFIT_FEE,
            MAXIMUM_PROFIT_FEE,
            minimalManagerCollateral
        );
    }

    function createFund(
        address payable _swapRouter,
        uint256 _fundDurationInMonths,
        uint256 _softCap,
        uint256 _hardCap,
        uint256 _profitFee,
        uint256 _minimalDepositAmount,
        uint256 _minTimeUntilFundStart,
        address payable[] memory _allowedTokens
    ) public payable returns (address) {
        require(_hardCap > _softCap, "Hard cap must be bigger than soft cap");

        require(
            _hardCap <= hardCap && _softCap >= softCap,
            "HardCap values is outside the platform default caps"
        );

        require(
            _minimalDepositAmount > 0 &&
                _minimalDepositAmount <=
                _hardCap -
                    MAXIMUM_MINIMAL_DEPOSIT_AMOUNT_FROM_HARD_CAP_PERCENTAGE,
            "Invalid minimalDepositAmount"
        );

        require(
            msg.value >= minimalManagerCollateral && msg.value < _hardCap,
            "value must be < hard cap and > than minimum manager collateral"
        );

        require(
            _profitFee >= MINIMUM_PROFIT_FEE &&
                _profitFee <= MAXIMUM_PROFIT_FEE,
            "Manager fee value is outside the manager fee gap"
        );

        require(
            _minTimeUntilFundStart >= MINIMUM_TIME_UNTIL_FUND_START &&
                _minTimeUntilFundStart <= MAXIMUM_TIME_UNTIL_FUND_START,
            "MinTimeUntillFundStart value is outside the fundStart gap"
        );

        address newFundAddress = fundFactory.createFund{value: msg.value}(
            HedgeFundInfo(
                _swapRouter,
                payable(address(eFund)),
                payable(address(this)),
                _softCap,
                _hardCap,
                _profitFee,
                _minimalDepositAmount,
                _minTimeUntilFundStart,
                payable(msg.sender),
                _fundDurationInMonths,
                msg.value,
                _allowedTokens
            )
        );

        _funds.push(HedgeFund(payable(newFundAddress)));
        _managerFunds[msg.sender].push(HedgeFund(payable(newFundAddress)));
        isFund[newFundAddress] = true;

        if (!managerFundActivity[msg.sender].isValue)
            managerFundActivity[msg.sender] = FundManagerActivityInfo(
                0,
                0,
                0,
                true
            );
    }

    function getTopRelevantFunds(uint256 _topAmount)
        public
        view
        returns (HedgeFund[] memory)
    {
        if (_funds.length == 0) return _funds;

        if (_topAmount >= _funds.length) _topAmount = _funds.length;

        HedgeFund[] memory fundsCopy = new HedgeFund[](_funds.length);

        for (uint256 i = 0; i < _funds.length; i++) fundsCopy[i] = _funds[i];

        HedgeFund[] memory relevantFunds = new HedgeFund[](_topAmount);

        for (uint256 i = 0; i < fundsCopy.length; i++) {
            for (uint256 j = 0; j < fundsCopy.length - i - 1; j++) {
                if (
                    managerFundActivity[fundsCopy[j].fundManager()]
                        .successCompletedFunds >
                    managerFundActivity[fundsCopy[j + 1].fundManager()]
                        .successCompletedFunds &&
                    address(fundsCopy[j]).balance >
                    address(fundsCopy[j + 1]).balance
                ) {
                    HedgeFund temp = fundsCopy[j + 1];
                    fundsCopy[j + 1] = fundsCopy[j];
                    fundsCopy[j] = temp;
                }
            }
        }

        uint256 j = _funds.length - 1;

        for (uint256 i = 0; i < _topAmount; i++) {
            relevantFunds[i] = fundsCopy[j];
            j--;
        }

        return relevantFunds;
    }

    function getManagerFunds(address _manager)
        public
        view
        returns (HedgeFund[] memory)
    {
        return _managerFunds[_manager];
    }

    function getInvestorFunds(address _investor)
        public
        view
        returns (HedgeFund[] memory)
    {
        return _investorFunds[_investor];
    }

    function getAllFunds() public view returns (HedgeFund[] memory) {
        return _funds;
    }

    function getCurrentEthBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function onDepositMade(address _depositorAddress)
        public
        onlyForFundContract
    {
        if (isInvestorOf[_depositorAddress][msg.sender]) return; // fund is already added to list of invested funds

        isInvestorOf[_depositorAddress][msg.sender] = true;
        _investorFunds[_depositorAddress].push(HedgeFund(payable(msg.sender)));
    }

    function closeFund() public onlyForFundContract {
        HedgeFund fund = HedgeFund(payable(msg.sender)); // sender is a contract
        require(fund.getEndTime() < block.timestamp, "Fund is not completed");

        address managerAddresss = fund.fundManager();

        uint256 _curActivity = managerFundActivity[managerAddresss]
            .fundActivityMonths;

        managerFundActivity[managerAddresss].fundActivityMonths =
            _curActivity +
            fund.fundDurationMonths();

        managerFundActivity[managerAddresss].completedFunds =
            managerFundActivity[managerAddresss].completedFunds +
            1;

        managerFundActivity[managerAddresss].successCompletedFunds =
            managerFundActivity[managerAddresss].successCompletedFunds +
            (fund.originalEndBalance() > fund.baseBalance() ? 1 : 0);
    }

    function claimHolderReward() public {
        require(
            nextAvailableRewardClaimDate[msg.sender] <= block.timestamp,
            "Error: next available not reached"
        );
        require(
            eFund.balanceOf(msg.sender) > 0,
            "Error: must own eFundToken to claim reward"
        );

        uint256 reward = calculateHolderReward(msg.sender);

        // update rewardCycleBlock
        nextAvailableRewardClaimDate[msg.sender] =
            block.timestamp +
            REWARD_CYCLE_BLOCK;

        (bool sent, ) = address(msg.sender).call{value: reward}("");

        require(sent, "Error: Cannot withdraw reward");

        emit ClaimHolderRewardSuccessfully(
            msg.sender,
            reward,
            nextAvailableRewardClaimDate[msg.sender]
        );
    }

    function calculateHolderReward(address ofAddress)
        public
        view
        returns (uint256 reward)
    {
        uint256 _totalSupply = eFund.totalSupply() -
            eFund.balanceOf(address(this)) -
            eFund.balanceOf(address(0));

        return
            _calculateHolderReward(
                eFund.balanceOf(address(ofAddress)),
                address(this).balance,
                _totalSupply
            );
    }

    function calculateManagerRewardPercentage(address _address)
        public
        view
        returns (int256)
    {
        require(
            managerFundActivity[_address].isValue,
            "Address is not a fund manager"
        );

        return
            _calculateManagerRewardPercentage(
                managerFundActivity[_address].fundActivityMonths
            );
    }

    function _calculateHolderReward(
        uint256 currentBalance,
        uint256 currentBNBPool,
        uint256 totalSupply
    ) private pure returns (uint256) {
        uint256 reward = (currentBNBPool * currentBalance) / totalSupply;
        return reward;
    }

    function _excludeFromReward(address _address) private {
        isExcludedFromReward[_address] = true;
    }

    function _calculateManagerRewardPercentage(uint256 _duration)
        private
        pure
        returns (int256)
    {
        if (_duration < SILVER_PERIOD_START)
            return BRONZE_PERIOD_REWARD_PERCENTAGE;
        if (_duration < GOLD_PERIOD_START)
            return SILVER_PERIOD_REWARD_PERCENTAGE;
        return GOLD_PERIOD_REWARD_PERCENTAGE;
    }

    // Functions to receive Ether
    receive() external payable {}

    fallback() external payable {}

    struct FundManagerActivityInfo {
        uint256 fundActivityMonths;
        uint256 completedFunds;
        uint256 successCompletedFunds;
        bool isValue;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IFundTrade {
    /// @notice swaps ERC20 token to another ERC20 token
    /// @param path trade path
    /// @param amountIn amount of {tokenFrom}
    /// @param amountOutMin minimal amount of {tokenTo} that expected to be received
    function swapERC20ToERC20(
        address[] calldata path,
        uint256 amountIn,
        uint256 amountOutMin
    ) external;

    function swapERC20ToETH(
        address payable tokenFrom,
        uint256 amountIn,
        uint256 amountOutMin
    ) external;

    function swapETHToERC20(
        address payable tokenTo,
        uint256 amountIn,
        uint256 amountOutMin
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IHedgeFund {
    function makeDeposit() external payable;

    function withdrawDepositsOf(address payable _of) external;

    function withdrawDepositsBeforeFundStarted() external;

    function setFundStatusActive() external;

    function setFundStatusCompleted() external;

    function getEndTime() external view returns (uint256);

    function withdrawFundProfit() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library MathPercentage {
    int256 public constant PERCENTAGE_BASE = 100000;

    function calculateNumberFromNumberPercentage(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        return (a * PERCENTAGE_BASE) / b;
    }

    function calculateNumberFromPercentage(int256 p, int256 all)
        internal
        pure
        returns (int256)
    {
        return (all * p) / PERCENTAGE_BASE;
    }

    function translsatePercentageFromBase(int256 p, uint256 pBase)
        internal
        pure
        returns (int256)
    {
        return (p * PERCENTAGE_BASE) / int256(pBase);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

struct HedgeFundInfo {
    address payable swapRouterContract;
    address payable eFundTokenContract;
    address payable eFundPlatform;
    uint256 softCap;
    uint256 hardCap;
    uint256 profitFee;
    uint256 minimalDepostitAmount;
    uint256 minTimeUntilFundStart;
    address payable managerAddress;
    uint256 duration;
    uint256 managerCollateral;
    address payable[] allowedTokenAddresses;
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

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

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

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
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
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
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
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
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
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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