// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.18;

import "./ClaimerContract.sol";
import "./CollectorViews.sol";

error InvestmentTooLow();
error SelfReferralDetected();
error InvalidReferralAddress();

contract CollectorETH is CollectorViews {

    address public tokenDefiner;
    address public tokenAddress;
    address public bonusAddress;

    ClaimerContract public claimer;

    uint256 constant VESTING_TIME = 540 days;

    modifier onlyTokenDefiner() {
        require(
            msg.sender == tokenDefiner,
            "CollectorETH: INVALID_SENDER"
        );
        _;
    }

    modifier afterInvestmentPhase() {
        require(
            currentInvestmentDay() > INVESTMENT_DAYS,
            "CollectorETH: COLLECTOR_IN_PROGRESS"
        );
        _;
    }

    modifier afterSupplyGenerated() {
        require(
            g.generatedDays == fundedDays(),
            "CollectorETH: SUPPLY_NOT_GENERATED"
        );
        _;
    }

    modifier afterTokenProfitCreated() {
        require (
            g.generatedDays > 0 &&
            g.totalWeiContributed == 0,
            "CollectorETH: CREATE_TOKEN_PROFIT"
        );
        _;
    }

    constructor() {
        tokenDefiner = msg.sender;
        bonusAddress = msg.sender;
    }

    /** @dev Allows to define WISER token
      */
    function defineToken(
        address _tokenAddress
    )
        external
        onlyTokenDefiner
    {
        tokenAddress = _tokenAddress;
    }

    function defineBonus(
        address _bonusAddress
    )
        external
        onlyTokenDefiner
    {
        bonusAddress = _bonusAddress;
    }

    /** @dev Revokes access to define configs
      */
    function revokeAccess()
        external
        onlyTokenDefiner
    {
        tokenDefiner = address(0x0);
    }

    /** @dev Performs reservation of WISER tokens with ETH
      */
    function reserveWiser(
        uint8[] calldata _investmentDays,
        address _referralAddress
    )
        external
        payable
    {
        checkInvestmentDays(
            _investmentDays,
            currentInvestmentDay()
        );

        _reserveWiser(
            _investmentDays,
            _referralAddress,
            msg.sender,
            msg.value
        );
    }

    /** @notice Allows reservation of WISER tokens with other ERC20 tokens
      * @dev this will require this contract to be approved as spender
      */
    function reserveWiserWithToken(
        address _tokenAddress,
        uint256 _tokenAmount,
        uint256 _minExpected,
        uint8[] calldata _investmentDays,
        address _referralAddress
    )
        external
    {
        TokenERC20 _token = TokenERC20(
            _tokenAddress
        );

        _token.transferFrom(
            msg.sender,
            address(this),
            _tokenAmount
        );

        _token.approve(
            address(UNISWAP_ROUTER),
            _tokenAmount
        );

        address[] memory _path = preparePath(
            _tokenAddress
        );

        uint256[] memory amounts =
        UNISWAP_ROUTER.swapExactTokensForETH(
            _tokenAmount,
            _minExpected,
            _path,
            address(this),
            block.timestamp + 2 hours
        );

        checkInvestmentDays(
            _investmentDays,
            currentInvestmentDay()
        );

        _reserveWiser(
            _investmentDays,
            _referralAddress,
            msg.sender,
            amounts[1]
        );
    }

    function _reserveWiser(
        uint8[] memory _investmentDays,
        address _referralAddress,
        address _senderAddress,
        uint256 _senderValue
    )
        internal
    {
        if (_senderAddress == _referralAddress) {
            revert SelfReferralDetected();
        }

        if (isContract(_referralAddress) == true) {
            revert InvalidReferralAddress();
        }

        if (_senderValue < MIN_INVEST * _investmentDays.length) {
            revert InvestmentTooLow();
        }

        uint256 _investmentBalance = _referralAddress == address(0x0)
            ? _senderValue // no referral bonus
            : _senderValue * 1100 / 1000;

        uint256 _totalDays = _investmentDays.length;
        uint256 _dailyAmount = _investmentBalance / _totalDays;
        uint256 _leftOver = _investmentBalance % _totalDays;

        _addBalance(
            _senderAddress,
            _investmentDays[0],
            _dailyAmount + _leftOver
        );

        for (uint8 _i = 1; _i < _totalDays; _i++) {
            _addBalance(
                _senderAddress,
                _investmentDays[_i],
                _dailyAmount
            );
        }

        _trackInvestors(
            _senderAddress,
            _investmentBalance
        );

        originalInvestment[_senderAddress] += _senderValue;
        g.totalWeiContributed += _senderValue;

        if (_referralAddress == address(0x0)) {
            return;
        }

        _trackReferrals(
            _referralAddress,
            _senderValue
        );

        emit ReferralAdded(
            _referralAddress,
            _senderAddress,
            _senderValue
        );
    }

    /** @notice Allocates investors balance to specific day
      */
    function _addBalance(
        address _senderAddress,
        uint256 _investmentDay,
        uint256 _investmentBalance
    )
        internal
    {
        if (investorBalances[_senderAddress][_investmentDay] == 0) {
            investorAccounts[_investmentDay][investorAccountCount[_investmentDay]] = _senderAddress;
            investorAccountCount[_investmentDay]++;
        }

        investorBalances[_senderAddress][_investmentDay] += _investmentBalance;
        dailyTotalInvestment[_investmentDay] += _investmentBalance;

        emit WiseReservation(
            _senderAddress,
            _investmentDay,
            _investmentBalance
        );
    }

    /** @notice Tracks investorTotalBalance and uniqueInvestors
      * @dev used in _reserveWiser() internal function
      */
    function _trackInvestors(
        address _investorAddress,
        uint256 _value
    )
        internal
    {
        if (investorTotalBalance[_investorAddress] == 0) {
            uniqueInvestors[uniqueInvestorCount] = _investorAddress;
            uniqueInvestorCount++;
        }

        investorTotalBalance[_investorAddress] += _value;
    }

    /** @notice Tracks referralAmount and referralAccounts
      * @dev used in _reserveWiser() internal function
      */
    function _trackReferrals(
        address _referralAddress,
        uint256 _value
    )
        internal
    {
        if (referralAmount[_referralAddress] == 0) {
            referralAccounts[referralAccountCount] = _referralAddress;
            referralAccountCount++;
        }

        referralAmount[_referralAddress] += _value;
    }

    /** @notice Allows to generate supply for past funded days
      */
    function generateSupply()
        external
        afterInvestmentPhase
    {
        for (uint8 i = 1; i <= INVESTMENT_DAYS; i++) {

            if (dailyTotalSupply[i] > 0) continue;
            if (dailyTotalInvestment[i] == 0) continue;

            dailyTotalSupply[i] = DAILY_SUPPLY;
            g.totalTransferTokens += DAILY_SUPPLY;

            g.generatedDays++;

            emit GeneratedStaticSupply(
                i,
                DAILY_SUPPLY
            );
        }
    }

    /** @notice Pre-calculates amount of tokens each referrer will get
      * @dev must run this for all referrer addresses in batches
      * converts _referralAmount to _referralTokens based on dailyRatio
      */
    function prepareReferralBonuses(
        uint256 _referralBatchFrom,
        uint256 _referralBatchTo
    )
        external
        afterInvestmentPhase
        afterSupplyGenerated
    {
        require(
            _referralBatchFrom < _referralBatchTo,
            "CollectorETH: INVALID_REFERRAL_BATCH"
        );

        require(
            g.preparedReferrals < referralAccountCount,
            "CollectorETH: REFERRALS_ALREADY_PREPARED"
        );

        uint256 _totalRatio = g.totalTransferTokens / g.totalWeiContributed;

        for (uint256 i = _referralBatchFrom; i < _referralBatchTo; i++) {

            address _referralAddress = referralAccounts[i];
            uint256 _referralAmount = referralAmount[_referralAddress];

            if (_referralAmount == 0) continue;

            g.preparedReferrals++;
            referralAmount[_referralAddress] = 0;

            if (_referralAmount < MINIMUM_REFERRAL) continue;

            uint256 referralBonus = _getReferralAmount(
                _referralAmount,
                _totalRatio
            );

            g.totalReferralTokens += referralBonus;
            referralTokens[_referralAddress] = referralBonus;
        }
    }

    /** @notice Creates tokenProfit contract aka WISER contract
      * and forwards all collected funds for the governance
      * also mints all the supply and locks in vesting contract
      */
    function createTokenProfitContract(/*🦉*/)
        external
        afterInvestmentPhase
        afterSupplyGenerated
    {
        require(
            g.preparedReferrals == referralAccountCount,
            "CollectorETH: REFERRALS_NOT_READY"
        );

        require(
            address(claimer) == address(0x0),
            "CollectorETH: ALREADY_CREATED"
        );

        claimer = new ClaimerContract(
            address(this),
            VESTING_TIME,
            tokenAddress
        );

        uint256 tokensForRef = g.totalReferralTokens;
        uint256 collectedETH = g.totalWeiContributed;
        uint256 tokensToMint = g.totalTransferTokens + tokensForRef;

        uint256 tokensToGift = LIMIT_REFERRALS > tokensForRef
            ? LIMIT_REFERRALS - tokensForRef
            : 0;

        payable(tokenAddress).transfer(
            collectedETH
        );

        WiserToken(tokenAddress).mintSupply(
            address(claimer),
            tokensToMint
        );

        WiserToken(tokenAddress).mintSupply(
            bonusAddress,
            tokensToGift
        );

        WiserToken(tokenAddress).mintSupply(
            bonusAddress,
            WISER_FUNDRAISE
        );

        g.totalWeiContributed = 0;
        g.totalTransferTokens = 0;
        g.totalReferralTokens = 0;
    }

    /** @notice Allows to start vesting of purchased tokens
      * from investor and referrer perspectives address
      * @dev can be called after createTokenProfitContract()
      */
    function startMyVesting(/*⏳*/)
        external
        afterTokenProfitCreated
    {
        uint256 locked = _payoutInvestorAddress(
            msg.sender
        );

        uint256 opened = _payoutReferralAddress(
            msg.sender
        );

        if (locked + opened == 0) return;

        claimer.enrollAndScrape(
            msg.sender,
            locked,
            opened,
            VESTING_TIME
        );
    }

    /** @notice Returns minting amount for specific investor address
      * @dev aggregades investors tokens across all investment days
      */
    function _payoutInvestorAddress(
        address _investorAddress
    )
        internal
        returns (uint256 payoutAmount)
    {
        for (uint8 i = 1; i <= INVESTMENT_DAYS; i++) {

            uint256 balance = investorBalances[_investorAddress][i];

            if (balance == 0) continue;

            payoutAmount += balance
                * _calculateDailyRatio(i)
                / PRECISION_POINT;

            investorBalances[_investorAddress][i] = 0;
        }
    }

    /** @notice Returns minting amount for specific referrer address
      * @dev must be pre-calculated in prepareReferralBonuses()
      */
    function _payoutReferralAddress(
        address _referralAddress
    )
        internal
        returns (uint256)
    {
        uint256 payoutAmount = referralTokens[_referralAddress];

        if (referralTokens[_referralAddress] > 0) {
            referralTokens[_referralAddress] = 0;
        }

        return payoutAmount;
    }

    function requestRefund(
        address _investor
    )
        external
        returns (uint256 _amount)
    {
        require(
            g.totalWeiContributed > 0  &&
            originalInvestment[_investor] > 0 &&
            currentInvestmentDay() > INVESTMENT_DAYS + 10,
           "CollectorETH: REFUND_NOT_POSSIBLE"
        );

        _amount = originalInvestment[_investor];
        originalInvestment[_investor] = 0;
        g.totalTransferTokens = 0;

        payable(_investor).transfer(
            _amount
        );
    }
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.18;

import "./CollectorDeclaration.sol";

contract CollectorViews is CollectorDeclaration {

    /** @notice checks for callers investment amount on specific day (with bonus)
      * @return total amount invested across all investment days (with bonus)
      */
    function myInvestmentAmount(
        uint256 _investmentDay
    )
        external
        view
        returns (uint256)
    {
        return investorBalances[msg.sender][_investmentDay];
    }

    /** @notice checks for callers investment amount on each day (with bonus)
      * @return _myAllDays total amount invested across all days (with bonus)
      */
    function myInvestmentAmountAllDays()
        external
        view
        returns (uint256[51] memory _myAllDays)
    {
        for (uint256 i = 1; i <= INVESTMENT_DAYS; i++) {
            _myAllDays[i] = investorBalances[msg.sender][i];
        }
    }

    /** @notice checks for callers total investment amount (with bonus)
      * @return total amount invested across all investment days (with bonus)
      */
    function myTotalInvestmentAmount()
        external
        view
        returns (uint256)
    {
        return investorTotalBalance[msg.sender];
    }

    /** @notice checks for investors count on specific day
      * @return investors count for specific day
      */
    function investorsOnDay(
        uint256 _investmentDay
    )
        external
        view
        returns (uint256)
    {
        return dailyTotalInvestment[_investmentDay] > 0
            ? investorAccountCount[_investmentDay]
            : 0;
    }

    /** @notice checks for investors count on each day
      * @return _allInvestors array with investors count for each day
      */
    function investorsOnAllDays()
        external
        view
        returns (uint256[51] memory _allInvestors)
    {
        for (uint256 i = 1; i <= INVESTMENT_DAYS; i++) {
            _allInvestors[i] = dailyTotalInvestment[i] > 0
            ? investorAccountCount[i]
            : 0;
        }
    }

    /** @notice checks for investment amount on each day
      * @return _allInvestments array with investment amount for each day
      */
    function investmentsOnAllDays()
        external
        view
        returns (uint256[51] memory _allInvestments)
    {
        for (uint256 i = 1; i <= INVESTMENT_DAYS; i++) {
            _allInvestments[i] = dailyTotalInvestment[i];
        }
    }

    /** @notice checks for supply amount on each day
      * @return _allSupply array with supply amount for each day
      */
    function supplyOnAllDays()
        external
        view
        returns (uint256[51] memory _allSupply)
    {
        for (uint256 i = 1; i <= INVESTMENT_DAYS; i++) {
            _allSupply[i] = dailyTotalSupply[i];
        }
    }

    /** @notice shows current investment day
      */
    function currentInvestmentDay()
        public
        view
        returns (uint256)
    {
        return block.timestamp > INCEPTION_TIME
            ? (block.timestamp - INCEPTION_TIME) / SECONDS_IN_DAY + 1
            : 0;
    }

    function isContract(
        address _walletAddress
    )
        public
        view
        returns (bool)
    {
        uint32 size;
        assembly {
            size := extcodesize(
                _walletAddress
            )
        }
        return (size > 0);
    }

    /** @notice prepares path variable for uniswap to exchange tokens
      * @dev used in reserveWiserWithToken() swapExactTokensForETH call
      */
    function preparePath(
        address _tokenAddress
    )
        public
        pure
        returns
    (
        address[] memory _path
    ) {
        _path = new address[](2);
        _path[0] = _tokenAddress;
        _path[1] = WETH;
    }

    /** @notice checks that provided days are valid for investemnt
      * @dev used in reserveWise() and reserveWiseWithToken()
      */
    function checkInvestmentDays(
        uint8[] memory _investmentDays,
        uint256 _investmentDay
    )
        public
        pure
    {
        for (uint8 _i = 0; _i < _investmentDays.length; _i++) {
            require(
                _investmentDays[_i] >= _investmentDay,
                "CollectorViews: DAY_ALREADY_PASSED"
            );
            require(
                _investmentDays[_i] > 0 &&
                _investmentDays[_i] <= INVESTMENT_DAYS,
                "CollectorViews: INVALID_INVESTMENT_DAY"
            );
        }
    }

    /** @notice checks for invesments on all days
      * @dev used in createTokenProfitContract()
      */
    function fundedDays()
        public
        view
        returns (uint8 $fundedDays)
    {
        for (uint8 i = 1; i <= INVESTMENT_DAYS; i++) {
            if (dailyTotalInvestment[i] > 0) {
                $fundedDays++;
            }
        }
    }

    /** @notice WISER equivalent in ETH price calculation
      * @dev returned value has 100E18 precision point
      */
    function _calculateDailyRatio(
        uint256 _investmentDay
    )
        internal
        view
        returns (uint256)
    {
        uint256 dailyRatio = dailyTotalSupply[_investmentDay]
            * PRECISION_POINT
            / dailyTotalInvestment[_investmentDay];

        uint256 remainderCheck = dailyTotalSupply[_investmentDay]
            * PRECISION_POINT
            % dailyTotalInvestment[_investmentDay];

        return remainderCheck == 0
            ? dailyRatio
            : dailyRatio + 1;
    }

    /** @notice calculates referral bonus
      */
    function _getReferralAmount(
        uint256 _referralAmount,
        uint256 _ratio
    )
        internal
        pure
        returns (uint256)
    {
        return _referralAmount / REFERRAL_BONUS * _ratio;
    }
}

// SPDX-License-Identifier: --WISE--

pragma solidity =0.8.18;

import "./ClaimerHelper.sol";

contract ClaimerContract is ClaimerHelper {

    address public immutable collector;
    uint256 public immutable createTime;
    uint256 public immutable minimumTime;

    struct KeeperInfo {
        uint256 keeperRate;
        uint256 keeperTill;
        uint256 keeperInstant;
        uint256 keeperPayouts;
    }

    mapping(address => KeeperInfo) public keeperList;

    modifier onlyCollector() {
        require(
            msg.sender == collector,
            "ClaimerContract: INVALID_COLLECTOR"
        );
        _;
    }

    constructor(
        address _collector,
        uint256 _timeFrame,
        address _tokenAddress
    )
        ClaimerHelper(
            _tokenAddress
        )
    {
        if (_timeFrame == 0) {
            revert("ClaimerContract: INVALID_TIMEFRAME");
        }

        collector = _collector;
        createTime = getNow();
        minimumTime = _timeFrame;
    }

    function enrollRecipient(
        address _recipient,
        uint256 _tokensLocked, // -> contributed locked amount
        uint256 _tokensOpened, // -> referral opened amount
        uint256 _timeFrame
    )
        external
        onlyCollector
    {
        _enrollRecipient(
            _recipient,
            _tokensLocked,
            _tokensOpened,
            _timeFrame
        );
    }

    function _enrollRecipient(
        address _recipient,
        uint256 _tokensLocked,
        uint256 _tokensOpened,
        uint256 _timeFrame
    )
        private
    {
        require(
            keeperList[_recipient].keeperTill == 0,
            "ClaimerContract: RECIPIENT_ALREADY_ENROLLED"
        );

        _allocateTokens(
            _recipient,
            _tokensLocked,
            _tokensOpened,
            _timeFrame
        );
    }

    function _allocateTokens(
        address _recipient,
        uint256 _tokensLocked,
        uint256 _tokensOpened,
        uint256 _timeFrame
    )
        private
    {
        require(
            _timeFrame >= minimumTime,
            "ClaimerContract: INVALID_TIME_FRAME"
        );

        totalRequired = totalRequired
            + _tokensOpened
            + _tokensLocked;

        keeperList[_recipient].keeperTill = createTime
            + _timeFrame;

        keeperList[_recipient].keeperRate = _tokensLocked
            / _timeFrame;

        keeperList[_recipient].keeperInstant = _tokensLocked
            % _timeFrame
            + _tokensOpened;

        _checkBalance(
            totalRequired
        );

        emit recipientEnrolled(
            _recipient,
            _timeFrame,
            _tokensLocked,
            _tokensOpened
        );
    }

    function enrollAndScrape(
        address _recipient,
        uint256 _tokensLocked,
        uint256 _tokensOpened,
        uint256 _timeFrame
    )
        external
        onlyCollector
    {
        _enrollRecipient(
            _recipient,
            _tokensLocked,
            _tokensOpened,
            _timeFrame
        );

        _scrapeTokens(
            _recipient
        );
    }

    function scrapeMyTokens()
        external
    {
        _scrapeTokens(
            msg.sender
        );
    }

    function _scrapeTokens(
        address _recipient
    )
        private
    {
        uint256 scrapeAmount = availableBalance(
            _recipient
        );

        keeperList[_recipient].keeperPayouts += scrapeAmount;

        _safeScrape(
            _recipient,
            scrapeAmount
        );

        emit tokensScraped(
            _recipient,
            scrapeAmount,
            getNow()
        );
    }

    function availableBalance(
        address _recipient
    )
        public
        view
        returns (uint256 balance)
    {
        uint256 timeNow = getNow();
        uint256 timeMax = keeperList[_recipient].keeperTill;

        if (timeMax == 0) return 0;

        uint256 timePassed = timeNow > timeMax
            ? timeMax - createTime
            : timeNow - createTime;

        balance = keeperList[_recipient].keeperRate
            * timePassed
            + keeperList[_recipient].keeperInstant
            - keeperList[_recipient].keeperPayouts;
    }

    function lockedBalance(
        address _recipient
    )
        external
        view
        returns (uint256 balance)
    {
        uint256 timeNow = getNow();

        uint256 timeRemaining =
            keeperList[_recipient].keeperTill > timeNow ?
            keeperList[_recipient].keeperTill - timeNow : 0;

        balance = keeperList[_recipient].keeperRate
            * timeRemaining;
    }
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.18;

interface UniswapV2 {

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external
        returns (uint256[] memory amounts);
}

interface TokenERC20 {

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        external
        returns (bool success);

    function approve(
        address _spender,
        uint256 _value
    )
        external
        returns (bool success);
}

interface WiserToken {
    function mintSupply(
        address _to,
        uint256 _value
    )
        external
        returns (bool success);
}

contract CollectorDeclaration {

    UniswapV2 public constant UNISWAP_ROUTER = UniswapV2(
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    );

    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint256 constant INVESTMENT_DAYS = 50;
    uint256 constant REFERRAL_BONUS = 10;
    // uint256 constant SECONDS_IN_DAY = 86400;
    uint256 constant SECONDS_IN_DAY = 3600;
    uint256 constant PRECISION_POINT = 100E18;
    uint256 INCEPTION_TIME = block.timestamp;
    // uint256 constant INCEPTION_TIME = 1677628800;
    uint256 constant LIMIT_REFERRALS = 90000000E18;
    uint256 constant WISER_FUNDRAISE = 10000000E18;
    uint128 constant MINIMUM_REFERRAL = 10 ether;
    uint128 constant MIN_INVEST = 50000000 gwei;
    uint128 constant DAILY_SUPPLY = 18000000E18;

    struct Globals {
        uint64 generatedDays;
        uint64 preparedReferrals;
        uint256 totalTransferTokens;
        uint256 totalWeiContributed;
        uint256 totalReferralTokens;
    }

    Globals public g;

    mapping(uint256 => uint256) public dailyTotalSupply;
    mapping(uint256 => uint256) public dailyTotalInvestment;

    mapping(uint256 => uint256) public investorAccountCount;
    mapping(uint256 => mapping(uint256 => address)) public investorAccounts;
    mapping(address => mapping(uint256 => uint256)) public investorBalances;

    mapping(address => uint256) public referralAmount;
    mapping(address => uint256) public referralTokens;
    mapping(address => uint256) public investorTotalBalance;
    mapping(address => uint256) public originalInvestment;

    uint256 public referralAccountCount;
    uint256 public uniqueInvestorCount;

    mapping (uint256 => address) public uniqueInvestors;
    mapping (uint256 => address) public referralAccounts;

    event GeneratedStaticSupply(
        uint256 indexed investmentDay,
        uint256 staticSupply
    );

    event ReferralAdded(
        address indexed referral,
        address indexed referee,
        uint256 amount
    );

    event WiseReservation(
        address indexed sender,
        uint256 indexed investmentDay,
        uint256 amount
    );
}

// SPDX-License-Identifier: --BCOM--

pragma solidity =0.8.18;

contract ClaimerHelper {

    uint256 public totalRequired;
    address public immutable wiserToken;

    event recipientEnrolled(
        address indexed recipient,
        uint256 timeFrame,
        uint256 tokensLocked,
        uint256 tokensOpened
    );

    event tokensScraped(
        address indexed scraper,
        uint256 scrapedAmount,
        uint256 timestamp
    );

    constructor(
        address _wiserTokenAddress
    ) {
        if (_wiserTokenAddress == address(0x0)) {
            revert("ClaimerHelper: INVALID_TOKEN");
        }

        wiserToken = _wiserTokenAddress;
    }

    bytes4 private constant TRANSFER = bytes4(
        keccak256(
            bytes(
                "transfer(address,uint256)"
            )
        )
    );

    bytes4 private constant BALANCEOF = bytes4(
        keccak256(
            bytes(
                "balanceOf(address)"
            )
        )
    );

    function _safeScrape(
        address _to,
        uint256 _scrapeAmount
    )
        internal
    {
        totalRequired -= _scrapeAmount;

        (bool success, bytes memory data) = wiserToken.call(
            abi.encodeWithSelector(
                TRANSFER,
                _to,
                _scrapeAmount
            )
        );

        require(
            success && (
                abi.decode(
                    data, (bool)
                )
            ),
            "ClaimerHelper: TRANSFER_FAILED"
        );
    }

    function _checkBalance(
        uint256 _required
    )
        internal
    {
        (bool success, bytes memory data) = wiserToken.call(
            abi.encodeWithSelector(
                BALANCEOF,
                address(this)
            )
        );

        require(
            success && abi.decode(
                data, (uint256)
            ) >= _required,
            "ClaimerHelper: BALANCE_CHECK_FAILED"
        );
    }

    function getNow()
        public
        view
        returns (uint256 time)
    {
        time = block.timestamp;
    }
}