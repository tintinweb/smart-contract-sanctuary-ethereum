// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./FloorPricePrediction.sol";

contract FloorPricePredictionV2 is FloorPricePrediction {
    mapping(address => uint256) public _referralFunds; // per referrer
    mapping(address => address) public _referrers; // newUser => referrer
    uint256 public referralRewardRatio; //10 = 1%

    function setReferralRewardRatio(uint256 _referralRewardRatio) external onlyAdmin {
        referralRewardRatio = _referralRewardRatio;
    }

    function _checkBetRequirements(address market, uint256 intervalSeconds) internal {
        // BMG: Bet amount must be greater than minBetAmount
        require(msg.value >= minBetAmount, "BMG");
        // IVMI: Invalid market and interval
        require(_isValidMarketAndInterval(market, intervalSeconds), "IVMI");
        // BGT: Before genesis timestamp
        require(block.timestamp >= markets[market].periods[intervalSeconds].genesisTimestamp, "BGT");
    }

    function _handleReferralsWithReferrer(address _referrer) internal {
        if (_referrers[msg.sender] != address(0)) {
            // already have referrer
            address referrer = _referrers[msg.sender];
            uint256 reward = (msg.value * referralRewardRatio) / 1000;
            _referralFunds[referrer] += reward;
            emit Referral(msg.sender, referrer, reward, false);
        } else if (_referrer != address(0)) {
            // no referrer record
            // CRB: Cannot refer back
            // CRS: Cannot refer self
            require(_referrers[_referrer] != msg.sender, "CRB");
            require(msg.sender != _referrer, "CRS");
            _referrers[msg.sender] = _referrer;
            uint256 reward = (msg.value * referralRewardRatio) / 1000;
            _referralFunds[_referrer] += reward;
            emit Referral(msg.sender, _referrer, reward, true);
        }
    }

    function claimReferralRewards() external nonReentrant notContract {
        uint256 reward = _referralFunds[msg.sender];
        if (reward > 0) {
            _referralFunds[msg.sender] = 0;
            _safeTransfer(address(msg.sender), reward);
        }
        emit ClaimReferralRewards(msg.sender, reward);
    }

    function _safeBet(
        address market,
        uint256 intervalSeconds,
        bool isBear
    ) internal {
        uint256 epoch = _getCurrentEpoch(market, intervalSeconds);
        Period storage p = markets[market].periods[intervalSeconds];
        if (isBear) {
            p.rounds[epoch].bearAmount += msg.value;
        } else {
            p.rounds[epoch].bullAmount += msg.value;
        }

        Bet memory bet;
        bet.isBear = isBear;
        bet.amount = msg.value;
        p.ledger[epoch][msg.sender].push(bet);

        treasuryAmount += _calculateFee(msg.value);

        emit NewBet(
            msg.sender,
            msg.value,
            market,
            intervalSeconds,
            p.lockIntervalSeconds,
            epoch,
            p.genesisTimestamp + (epoch * p.lockIntervalSeconds),
            p.genesisTimestamp + (epoch * p.lockIntervalSeconds) + intervalSeconds,
            isBear,
            p.ledger[epoch][msg.sender].length - 1
        );
    }

    function betWithReferrer(
        address market,
        uint256 intervalSeconds,
        bool isBear,
        address referrer
    ) public payable whenNotPaused(market) nonReentrant notContract {
        _checkBetRequirements(market, intervalSeconds);
        _handleReferralsWithReferrer(referrer);
        _safeBet(market, intervalSeconds, isBear);
    }

    event Referral(address indexed newUser, address indexed referrer, uint256 reward, bool indexed isNewReferral);
    event ClaimReferralRewards(address indexed referrer, uint256 amount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./interfaces/INftPriceOracle.sol";
import "./interfaces/IFloorPricePrediction.sol";

/**
 * @title FloorPricePrediction
 */
contract FloorPricePrediction is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable, IFloorPricePrediction {
    INftPriceOracle public oracle;
    address public adminAddress; // address of the admin
    uint256 public minBetAmount; // minimum betting amount (denominated in wei)
    uint256 public treasuryFee; // treasury rate (e.g. 200 = 2%, 150 = 1.50%)
    uint256 public treasuryAmount; // accumulated treasury amount

    mapping(address => Market) public markets;
    address[] public nftsContracts;

    function _onlyAdmin() internal view {
        // NA: Not Admin
        require(msg.sender == adminAddress, "NA");
    }

    modifier onlyAdmin() {
        _onlyAdmin();
        _;
    }

    function _whenNotPaused(address market) internal view {
        require(!markets[market].paused, "Pausable: paused");
    }

    modifier notContract() {
        // CNA: contract not allowed
        require(!_isContract(msg.sender), "CNA");
        // PCNA: Proxy contract not allowed
        require(msg.sender == tx.origin, "PCNA");
        _;
    }

    modifier whenNotPaused(address market) {
        _whenNotPaused(market);
        _;
    }

    /**
     * @notice initializer
     * @param params: PredictionParams with initializing params
     */
    function initialize(PredictionParams memory params) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        oracle = INftPriceOracle(params._oracleAddress);
        adminAddress = params._adminAddress;
        minBetAmount = params._minBetAmount;
        treasuryFee = params._treasuryFee;
        for (uint i = 0; i < params._nftContracts.length; i++) {
            nftsContracts.push(params._nftContracts[i]);
            Market storage m = markets[params._nftContracts[i]];
            m.nftContract = params._nftContracts[i];
            for (uint j = 0; j < params._intervals.length; j++) {
                m.intervals.push(params._intervals[j]);
                Period storage p = m.periods[params._intervals[j].intervalSeconds];
                p.intervalSeconds = params._intervals[j].intervalSeconds;
                p.lockIntervalSeconds = params._intervals[j].lockIntervalSeconds;
                p.genesisTimestamp = params._genesisTimestamp;
            }
        }
    }

    /**
     * @notice Bet bear position
     * @param market: nft contract address
     * @param intervalSeconds: round interval in seconds
     */
    function betBear(address market, uint256 intervalSeconds)
        external
        payable
        whenNotPaused(market)
        nonReentrant
        notContract
    {
        // BMG: Bet amount must be greater than minBetAmount
        require(msg.value >= minBetAmount, "BMG");
        // IVMI: Invalid market and interval
        require(_isValidMarketAndInterval(market, intervalSeconds), "IVMI");
        // BGT: Before genesis timestamp
        require(block.timestamp >= markets[market].periods[intervalSeconds].genesisTimestamp, "BGT");

        uint256 amount = msg.value;
        uint256 epoch = _getCurrentEpoch(market, intervalSeconds);
        Period storage p = markets[market].periods[intervalSeconds];
        Round storage r = p.rounds[epoch];
        r.bearAmount += amount;

        Bet memory bet;
        bet.isBear = true;
        bet.amount = amount;
        p.ledger[epoch][msg.sender].push(bet);
        uint256 nth = p.ledger[epoch][msg.sender].length - 1;
        (, uint256 lockTimestamp, uint256 closeTimestamp) = _getEpochTimestamps(
            p.genesisTimestamp,
            p.lockIntervalSeconds,
            p.intervalSeconds,
            epoch
        );
        treasuryAmount += _calculateFee(amount);

        emit NewBet(
            msg.sender,
            amount,
            market,
            intervalSeconds,
            p.lockIntervalSeconds,
            epoch,
            lockTimestamp,
            closeTimestamp,
            true,
            nth
        );
    }

    /**
     * @notice Bet bull position
     * @param market: nft contract address
     * @param intervalSeconds: round interval in seconds
     */
    function betBull(address market, uint256 intervalSeconds)
        external
        payable
        whenNotPaused(market)
        nonReentrant
        notContract
    {
        // BMG: Bet amount must be greater than minBetAmount
        require(msg.value >= minBetAmount, "BMG");
        // IVMI: Invalid market and interval
        require(_isValidMarketAndInterval(market, intervalSeconds), "IVMI");
        // BGT: Before genesis timestamp
        require(block.timestamp >= markets[market].periods[intervalSeconds].genesisTimestamp, "BGT");

        uint256 amount = msg.value;
        uint256 epoch = _getCurrentEpoch(market, intervalSeconds);
        Period storage p = markets[market].periods[intervalSeconds];
        Round storage r = p.rounds[epoch];
        r.bullAmount += amount;

        Bet memory bet;
        bet.isBear = false;
        bet.amount = amount;
        p.ledger[epoch][msg.sender].push(bet);
        uint256 nth = p.ledger[epoch][msg.sender].length - 1;
        (, uint256 lockTimestamp, uint256 closeTimestamp) = _getEpochTimestamps(
            p.genesisTimestamp,
            p.lockIntervalSeconds,
            p.intervalSeconds,
            epoch
        );
        treasuryAmount += _calculateFee(amount);

        emit NewBet(msg.sender, amount, market, intervalSeconds, p.lockIntervalSeconds, epoch, lockTimestamp, closeTimestamp, false, nth);
    }

    /**
     * @notice Claim reward for an array of betInfos
     * @param betInfos: array of betInfos
     */
    function claim(BetInfo[] memory betInfos) external nonReentrant notContract {
        uint256 reward; // Initializes reward
        for (uint256 i = 0; i < betInfos.length; i++) {
            BetInfo memory info = betInfos[i];
            Period storage p = markets[info.market].periods[info.intervalSeconds];
            Round memory r = p.rounds[info.epoch];
            (, r.lockTimestamp, r.closeTimestamp) = _getEpochTimestamps(
                p.genesisTimestamp,
                p.lockIntervalSeconds,
                p.intervalSeconds,
                info.epoch
            );

            if (block.timestamp < r.closeTimestamp) {
                continue;
            }

            bool lockPriceVerified;
            bool closePriceVerified;
            (lockPriceVerified, r.lockPrice) = oracle.getNftPriceByOracleId(
                info.market,
                info.lockPriceOracleId,
                r.lockTimestamp
            );
            (closePriceVerified, r.closePrice) = oracle.getNftPriceByOracleId(
                info.market,
                info.closePriceOracleId,
                r.closeTimestamp
            );
            // IO: Invalid oracleId
            require(lockPriceVerified && closePriceVerified, "IO");

            Bet storage bet = p.ledger[info.epoch][msg.sender][info.nth];
            if (!_claimable(r, bet)) continue;
            uint addedReward = _calculateRewards(r.bullAmount, r.bearAmount, r.closePrice, r.lockPrice, bet.amount);
            reward += addedReward;
            bet.claimed = true;
            emit Claim(msg.sender, addedReward, info.market, info.intervalSeconds, info.epoch, info.nth);
        }
        if (reward > 0) {
            _safeTransfer(address(msg.sender), reward);
        }
    }

    /// EXTERNAL VIEW ///

    /**
     * @notice Get rounds and bets data
     * @param user: pass user address when getting certain user's bets
     * @param market: nft contract address
     * @param intervalSeconds: round interval in seconds
     * @param cursor: cursor for pagination
     * @param size: size
     * @return rounds rounds data
     * @return userRoundBets user's bet in each round
     * @return nextCursor next cursor
     */
    function getRounds(
        address user,
        address market,
        uint256 intervalSeconds,
        uint256 cursor,
        uint256 size
    )
        external
        view
        returns (
            Round[] memory rounds,
            Bet[][] memory userRoundBets,
            uint256 nextCursor
        )
    {
        // BGT: Before genesis timestamp
        require(block.timestamp >= markets[market].periods[intervalSeconds].genesisTimestamp, "BGT");

        uint256 _cursor = cursor == 0 ? _getCurrentEpoch(market, intervalSeconds) : cursor;
        uint256 length = size > _cursor ? _cursor : size;
        rounds = new Round[](length);
        userRoundBets = new Bet[][](length);
        for (uint i = 0; i < length; i++) {
            Period storage p = markets[market].periods[intervalSeconds];
            rounds[i] = p.rounds[_cursor - i];
            rounds[i].epoch = _cursor - i;
            (rounds[i].startTimestamp, rounds[i].lockTimestamp, rounds[i].closeTimestamp) = _getEpochTimestamps(
                p.genesisTimestamp,
                p.lockIntervalSeconds,
                p.intervalSeconds,
                rounds[i].epoch
            );
            if (block.timestamp >= rounds[i].lockTimestamp) {
                rounds[i].lockPrice = oracle.getNftPriceByTimestamp(market, rounds[i].lockTimestamp);
            }
            if (block.timestamp >= rounds[i].closeTimestamp) {
                rounds[i].closePrice = oracle.getNftPriceByTimestamp(market, rounds[i].closeTimestamp);
            }
            if (user != address(0)) {
                Bet[] memory _userBets = markets[market].periods[intervalSeconds].ledger[_cursor - i][user];
                userRoundBets[i] = new Bet[](_userBets.length);
                for (uint j = 0; j < _userBets.length; j++) {
                    userRoundBets[i][j] = _userBets[j];
                }
            }
        }
        nextCursor = _cursor - length < 0 ? 0 : _cursor - length;
    }

    /// EXTERNAL NON-VIEW FOR ADMIN ///

    /**
     * @notice Claim all rewards in treasury
     * @param houseWinRounds: The round that closePrice is equal to lockPrice. Neither bull wins nor bear wins then house wins.
     * @dev Callable by admin
     */
    function claimTreasury(RoundInfo[] calldata houseWinRounds) external nonReentrant onlyAdmin {
        uint256 currentTreasuryAmount = treasuryAmount;
        treasuryAmount = 0;
        for (uint256 i = 0; i < houseWinRounds.length; i++) {
            RoundInfo memory info = houseWinRounds[i];
            Market storage m = markets[info.market];
            Period storage p = m.periods[info.intervalSeconds];
            Round storage r = markets[info.market].periods[info.intervalSeconds].rounds[info.epoch];
            (, r.lockTimestamp, r.closeTimestamp) = _getEpochTimestamps(
                p.genesisTimestamp,
                p.lockIntervalSeconds,
                p.intervalSeconds,
                info.epoch
            );
            if (!r.houseWinClaimed) {
                (bool lockPriceVerified, uint256 lockPrice) = oracle.getNftPriceByOracleId(
                    info.market,
                    info.lockPriceOracleId,
                    r.lockTimestamp
                );
                (bool closePriceVerified, uint256 closePrice) = oracle.getNftPriceByOracleId(
                    info.market,
                    info.closePriceOracleId,
                    r.closeTimestamp
                );
                if (lockPriceVerified && closePriceVerified && (lockPrice == closePrice)) {
                    uint256 totalAmount = r.bullAmount + r.bearAmount;
                    currentTreasuryAmount += (totalAmount * (10000 - treasuryFee)) / 10000;
                }
                r.houseWinClaimed = true;
            }
        }
        _safeTransfer(adminAddress, currentTreasuryAmount);
        emit TreasuryClaim(currentTreasuryAmount);
    }

    /**
     * @notice Set minBetAmount
     * @param _minBetAmount: minimum bet amount
     * @dev Callable by admin
     */

    function setMinBetAmount(uint256 _minBetAmount) external onlyAdmin {
        // BAMS0: minBetAmount must be superior to 0
        require(_minBetAmount != 0, "BAMS0");
        minBetAmount = _minBetAmount;

        emit NewMinBetAmount(minBetAmount);
    }

    /**
     * @notice Set treasury fee
     * @param _treasuryFee: treasury fee rate (e.g. 200 = 2%, 150 = 1.50%)
     * @dev Callable by admin
     */
    function setTreasuryFee(uint256 _treasuryFee) external onlyAdmin {
        treasuryFee = _treasuryFee;

        emit NewTreasuryFee(treasuryFee);
    }

    /**
     * @notice Set oracle contract address
     * @param _oracleAddress: oracle contract address
     */
    function setOracleAddress(address _oracleAddress) external onlyAdmin {
        oracle = INftPriceOracle(_oracleAddress);
        emit NewOracle(_oracleAddress);
    }

    /**
     * @notice Set admin address
     * @param _adminAddress:  address of the admin
     * @dev Callable by owner
     */
    function setAdmin(address _adminAddress) external onlyAdmin {
        // CBZA: Cannot be zero address
        require(_adminAddress != address(0), "CBZA");
        adminAddress = _adminAddress;

        emit NewAdminAddress(_adminAddress);
    }

    /**
     * @notice Add nft collection to prediction
     * @param _nftContract: nft contract address
     * @param _intervals: time intervals of new market
     * @param _genesisTimestamp: genesis time of new market
     * @dev Callable by admin
     */
    function addNewMarketOrPeriod(
        address _nftContract,
        Interval[] calldata _intervals,
        uint256 _genesisTimestamp,
        bool newMarket
    ) external onlyAdmin {
        Market storage m = markets[_nftContract];
        if (newMarket) {
            // ME:market existed
            require(!_isExistingMarket(_nftContract), "ME");

            nftsContracts.push(_nftContract);
            m.nftContract = _nftContract;
        }

        for (uint i = 0; i < _intervals.length; i++) {
            // PE: period existed
            require(!_isExistingPeriodInMarket(_nftContract, _intervals[i].intervalSeconds), "PE");

            m.intervals.push(_intervals[i]);
            Period storage p = m.periods[_intervals[i].intervalSeconds];
            p.intervalSeconds = _intervals[i].intervalSeconds;
            p.lockIntervalSeconds = _intervals[i].lockIntervalSeconds;
            p.genesisTimestamp = _genesisTimestamp;
        }

        if (newMarket) {
            emit NewMarket(_nftContract, _intervals, _genesisTimestamp);
        } else {
            emit NewPeriodInMarket(_nftContract, _intervals, _genesisTimestamp);
        }
    }

    /**
     * @notice Pause certain market from betting
     * @param _market: nft contract address
     * @dev Callable by admin
     */
    function pauseMarket(address _market) external onlyAdmin {
        markets[_market].paused = true;
        emit MarketPause(_market);
    }

    /**
     * @notice Unpause certain market to recover betting
     * @param _market: nft contract address
     * @dev Callable by admin
     */
    function unpauseMarket(address _market) external onlyAdmin {
        markets[_market].paused = false;
        emit MarketUnpause(_market);
    }

    /// INTERNAL ///

    /**
     * @notice Returns true if `account` is a contract.
     * @param account: account address
     */
    function _isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @notice Check if the given nft address exists in market list
     * @param _market: nft contract address
     * @return bool whether the market exists in market list
     */
    function _isExistingMarket(address _market) internal view returns (bool) {
        return markets[_market].nftContract != address(0);
    }

    function _isExistingPeriodInMarket(address _market, uint256 _intervalSeconds) internal view returns (bool) {
        return markets[_market].periods[_intervalSeconds].intervalSeconds == _intervalSeconds;
    }

    /**
     * @notice Check if the given nft address and intervalSeconds has initialized
     * @param _market: nft contract address
     * @param _intervalSeconds: intervalSeconds
     * @return bool whether the market and interval exists
     */
    function _isValidMarketAndInterval(address _market, uint256 _intervalSeconds) internal view returns (bool) {
        return _isExistingMarket(_market) && markets[_market].periods[_intervalSeconds].intervalSeconds != 0;
    }

    /**
     * @notice Calculate treasury fee of a bet amount
     * @param amount: bet amount
     * @return fee treasury fee amount
     */
    function _calculateFee(uint256 amount) internal view returns (uint256 fee) {
        return (amount * treasuryFee) / 10000;
    }

    /**
     * @notice Calculate reward amount with given bull/bear amount, lock/close price and bet amount
     * @param bullAmount: sum of betting bull amount
     * @param bearAmount: sum of betting bear amount
     * @param closePrice: close price of a round
     * @param lockPrice: lock price of a round
     * @param betAmount: amount of the bet
     * @return uint256 anount of reward
     */
    function _calculateRewards(
        uint256 bullAmount,
        uint256 bearAmount,
        uint256 closePrice,
        uint256 lockPrice,
        uint256 betAmount
    ) internal view returns (uint256) {
        uint256 totalAmount = bullAmount + bearAmount;
        if (closePrice > lockPrice) {
            return (betAmount * totalAmount * (10000 - treasuryFee)) / 10000 / bullAmount;
        }
        return (betAmount * totalAmount * (10000 - treasuryFee)) / 10000 / bearAmount;
    }

    /**
     * @notice Get current epoch by market and period
     * Current timestamp must be within the epoch
     * @param market: nft contract address
     * @param intervalSeconds: round interval in seconds
     * @return epoch round count
     */
    function _getCurrentEpoch(address market, uint256 intervalSeconds) internal view virtual returns (uint256 epoch) {
        epoch =
            (block.timestamp - markets[market].periods[intervalSeconds].genesisTimestamp) /
            markets[market].periods[intervalSeconds].lockIntervalSeconds +
            1;
    }

    /**
     * @notice Calculate start/lock/close timestamps from given epoch
     * @param genesisTimestamp: nft contract address
     * @param lockIntervalSeconds: lock interval in seconds
     * @param intervalSeconds: time interval in seconds
     * @param epoch: round count
     * @return startTimestamp start time of the epoch
     * @return lockTimestamp lock time of the epoch
     * @return closeTimestamp close time of the epoch
     */
    function _getEpochTimestamps(
        uint256 genesisTimestamp,
        uint256 lockIntervalSeconds,
        uint256 intervalSeconds,
        uint256 epoch
    )
        internal
        pure
        virtual
        returns (
            uint256 startTimestamp,
            uint256 lockTimestamp,
            uint256 closeTimestamp
        )
    {
        startTimestamp = genesisTimestamp + ((epoch - 1) * lockIntervalSeconds);
        lockTimestamp = genesisTimestamp + (epoch * lockIntervalSeconds);
        closeTimestamp = genesisTimestamp + (epoch * lockIntervalSeconds) + intervalSeconds;
    }

    /**
     * @notice Get the claimable stats of specific round and user bet
     * @param round: round data
     * @param bet: bet data
     */
    function _claimable(Round memory round, Bet memory bet) internal pure virtual returns (bool) {
        if (round.lockPrice == round.closePrice || bet.claimed == true) {
            return false;
        }
        return
            bet.amount != 0 &&
            ((round.closePrice > round.lockPrice && bet.isBear == false) ||
                (round.closePrice < round.lockPrice && bet.isBear == true));
    }

    /**
     * @notice Transfer ether in a safe way
     * @param to: address to transfer ether to
     * @param value: ether amount to transfer (in wei)
     */
    function _safeTransfer(address to, uint256 value) internal {
        (bool success, ) = to.call{ value: value }("");
        // STF: TransferHelper: safe transfer failed
        require(success, "STF");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INftPriceOracle {
    function getNftPriceByTimestamp(address _nftContract, uint256 _timestamp) external view returns (uint256 price);

    function getNftPriceByOracleId(
        address _nftContract,
        uint256 _oracleId,
        uint256 _roundTimestamp
    ) external view returns (bool verified, uint256 price);

    function getOracleIdByTimestamp(address _nftContract, uint256 _timestamp) external view returns (uint256 oracleId);
}

/************
@title INFTOracle interface
@notice Interface for NFT price oracle.*/
interface INFTOracle {
    /* CAUTION: Price uint is ETH based (WEI, 18 decimals) */
    // get asset price
    function getAssetPrice(address _nftContract) external view returns (uint256);

    // get latest timestamp
    function getLatestTimestamp(address _nftContract) external view returns (uint256);

    // get previous price with _back rounds
    function getPreviousPrice(address _nftContract, uint256 _numOfRoundBack) external view returns (uint256);

    // get previous timestamp with _back rounds
    function getPreviousTimestamp(address _nftContract, uint256 _numOfRoundBack) external view returns (uint256);

    function setAssetData(address _nftContract, uint256 _price) external;

    function setPause(address _nftContract, bool val) external;

    function setTwapInterval(uint256 _twapInterval) external;

    function getPriceFeedLength(address _nftContract) external view returns (uint256 length);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFloorPricePrediction {
    struct Round {
        uint256 epoch;
        uint256 startTimestamp;
        uint256 lockTimestamp;
        uint256 closeTimestamp;
        uint256 lockPrice;
        uint256 closePrice;
        uint256 bullAmount;
        uint256 bearAmount;
        bool houseWinClaimed;
    }

    struct RoundInfo {
        address market;
        uint256 intervalSeconds;
        uint256 epoch;
        uint256 lockPriceOracleId;
        uint256 closePriceOracleId;
    }

    struct Bet {
        bool isBear;
        bool claimed; // default false
        uint256 amount;
    }

    struct BetInfo {
        address market;
        uint256 intervalSeconds;
        uint256 lockIntervalSeconds;
        uint256 epoch;
        uint256 nth;
        uint256 lockPriceOracleId;
        uint256 closePriceOracleId;
    }

    struct Interval {
        uint256 intervalSeconds;
        uint256 lockIntervalSeconds;
    }

    struct OracleIds {
        uint256 lockPriceOracleId;
        uint256 closePriceOracleId;
    }

    struct Period {
        uint256 currentEpoch;
        uint256 intervalSeconds;
        uint256 genesisTimestamp;
        uint256 lockIntervalSeconds;
        mapping(uint256 => mapping(address => Bet[])) ledger;
        mapping(uint256 => Round) rounds;
    }

    struct Market {
        address nftContract;
        bool paused;
        mapping(uint256 => Period) periods; // intervalSeconds => Period
        Interval[] intervals;
    }

    struct PredictionParams {
        address _oracleAddress;
        address _adminAddress;
        uint256 _minBetAmount;
        uint256 _treasuryFee;
        uint256 _genesisTimestamp;
        address[] _nftContracts;
        Interval[] _intervals;
    }

    event NewBet(
        address indexed sender,
        uint256 amount,
        address indexed market,
        uint256 indexed intervalSeconds,
        uint256 lockIntervalSeconds,
        uint256 epoch,
        uint256 lockTimestamp,
        uint256 closeTimestamp,
        bool isBear,
        uint256 nth
    );
    event Claim(
        address indexed sender,
        uint256 indexed amount,
        address indexed market,
        uint256 period,
        uint256 epoch,
        uint256 nth
    );
    event TreasuryClaim(uint256 amount);
    event NewMinBetAmount(uint256 minBetAmount);
    event NewTreasuryFee(uint256 treasuryFee);
    event NewOracle(address oracle);
    event NewAdminAddress(address admin);
    event NewMarket(address market, Interval[] intervals, uint256 genesisTimestamps);
    event NewPeriodInMarket(address market, Interval[] intervals, uint256 genesisTimestamps);
    event MarketPause(address market);
    event MarketUnpause(address market);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}