// SPDX-License-Identifier: MIT


pragma solidity 0.6.6;

import "./WithdrawableNoModifiers.sol";
import "./Utils.sol";
import "./ILyfeblocNetwork.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./ILyfeblocReserve.sol";
import "./ILyfeblocDao.sol";
import "./ILyfeblocFeeHandler.sol";
import "./ILyfeblocReserve.sol";
import "./ILyfeblocStorage.sol";
import "./ILyfeblocMatchingEngine.sol";
import "./IGasHelper.sol";








/**
 *   @title LyfeblocNetwork main contract
 *   Interacts with contracts:
 *       LyfeblocDao: to retrieve fee data
 *       LyfeblocFeeHandler: accumulates and distributes trade fees
 *       LyfeblocMatchingEngine: parse user hint and run reserve matching algorithm
 *       LyfeblocStorage: store / access reserves, token listings and contract addresses
 *       LyfeblocReserve(s): query rate and trade
 */
contract LyfeblocNetwork is WithdrawableNoModifiers, Utils, ILyfeblocNetwork, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct NetworkFeeData {
        uint64 expiryTimestamp;
        uint16 feeBps;
    }

    /// @notice Stores work data for reserves (either for token -> eth, or eth -> token)
    /// @dev Variables are in-place, ie. reserve with addresses[i] has id of ids[i], offers rate of rates[i], etc.
    /// @param addresses List of reserve addresses selected for the trade
    /// @param ids List of reserve ids, to be used for LyfeblocTrade event
    /// @param rates List of rates that were offered by the reserves
    /// @param isFeeAccountedFlags List of reserves requiring users to pay network fee
    /// @param isEntitledRebateFlags List of reserves eligible for rebates
    /// @param splitsBps List of proportions of trade amount allocated to the reserves.
    ///     If there is only 1 reserve, then it should have a value of 10000 bps
    /// @param srcAmounts Source amount per reserve.
    /// @param decimals Token decimals. Src decimals when for src -> eth, dest decimals when eth -> dest
    struct ReservesData {
        ILyfeblocReserve[] addresses;
        bytes32[] ids;
        uint256[] rates;
        bool[] isFeeAccountedFlags;
        bool[] isEntitledRebateFlags;
        uint256[] splitsBps;
        uint256[] srcAmounts;
        uint256 decimals;
    }

    /// @notice Main trade data structure, is initialised and used for the entire trade flow
    /// @param input Initialised when initTradeInput is called. Stores basic trade info
    /// @param tokenToEth Stores information about reserves that were selected for src -> eth side of trade
    /// @param ethToToken Stores information about reserves that were selected for eth -> dest side of trade
    /// @param tradeWei Trade amount in ether wei, before deducting fees.
    /// @param networkFeeWei Network fee in ether wei. For t2t trades, it can go up to 200% of networkFeeBps
    /// @param platformFeeWei Platform fee in ether wei
    /// @param networkFeeBps Network fee bps determined by kLyfeblocDao, or default value
    /// @param numEntitledRebateReserves No. of reserves that are eligible for rebates
    /// @param feeAccountedBps Proportion of this trade that fee is accounted to, in BPS. Up to 2 * BPS
    struct TradeData {
        TradeInput input;
        ReservesData tokenToEth;
        ReservesData ethToToken;
        uint256 tradeWei;
        uint256 networkFeeWei;
        uint256 platformFeeWei;
        uint256 networkFeeBps;
        uint256 numEntitledRebateReserves;
        uint256 feeAccountedBps; // what part of this trade is fee paying. for token -> token - up to 200%
    }

    struct TradeInput {
        address payable trader;
        IERC20 src;
        uint256 srcAmount;
        IERC20 dest;
        address payable destAddress;
        uint256 maxDestAmount;
        uint256 minConversionRate;
        address platformWallet;
        uint256 platformFeeBps;
    }

    uint256 internal constant PERM_HINT_GET_RATE = 1 << 255; // for backwards compatibility
    uint256 internal constant DEFAULT_NETWORK_FEE_BPS = 25; // till we read value from LyfeblocDao
    uint256 internal constant MAX_APPROVED_PROXIES = 2; // limit number of proxies that can trade here

    ILyfeblocFeeHandler internal lyfeblocFeeHandler;
    ILyfeblocDao internal lyfeblocDao;
    ILyfeblocMatchingEngine internal lyfeblocMatchingEngine;
    ILyfeblocStorage internal lyfeblocStorage;
    IGasHelper internal gasHelper;

    NetworkFeeData internal networkFeeData; // data is feeBps and expiry timestamp
    uint256 internal maxGasPriceValue = 50 * 1000 * 1000 * 1000; // 50 gwei
    bool internal isEnabled = false; // is network enabled

    mapping(address => bool) internal lyfeblocProxyContracts;

    event EtherReceival(address indexed sender, uint256 amount);
    event LyfeblocFeeHandlerUpdated(ILyfeblocFeeHandler newLyfeblocFeeHandler);
    event LyfeblocMatchingEngineUpdated(ILyfeblocMatchingEngine newLyfeblocMatchingEngine);
    event GasHelperUpdated(IGasHelper newGasHelper);
    event LyfeblocDaoUpdated(ILyfeblocDao newLyfeblocDao);
    event LyfeblocNetworkParamsSet(uint256 maxGasPrice, uint256 negligibleRateDiffBps);
    event LyfeblocNetworkSetEnable(bool isEnabled);
    event LyfeblocProxyAdded(address lyfeblocProxy);
    event LyfeblocProxyRemoved(address lyfeblocProxy);

    event ListedReservesForToken(
        IERC20 indexed token,
        address[] reserves,
        bool add
    );

    constructor(address _admin, ILyfeblocStorage _lyfeblocStorage)
        public
        WithdrawableNoModifiers(_admin)
    {
        updateNetworkFee(now, DEFAULT_NETWORK_FEE_BPS);
        lyfeblocStorage = _lyfeblocStorage;
    }

    receive() external payable {
        emit EtherReceival(msg.sender, msg.value);
    }

    /// @notice Backward compatible function
    /// @notice Use token address ETH_TOKEN_ADDRESS for ether
    /// @dev Trade from src to dest token and sends dest token to destAddress
    /// @param trader Address of the taker side of this trade
    /// @param src Source token
    /// @param srcAmount Amount of src tokens in twei
    /// @param dest Destination token
    /// @param destAddress Address to send tokens to
    /// @param maxDestAmount A limit on the amount of dest tokens in twei
    /// @param minConversionRate The minimal conversion rate. If actual rate is lower, trade reverts
    /// @param walletId Platform wallet address for receiving fees
    /// @param hint Advanced instructions for running the trade 
    /// @return destAmount Amount of actual dest tokens in twei
    function tradeWithHint(
        address payable trader,
        ERC20 src,
        uint256 srcAmount,
        ERC20 dest,
        address payable destAddress,
        uint256 maxDestAmount,
        uint256 minConversionRate,
        address payable walletId,
        bytes calldata hint
    ) external payable returns (uint256 destAmount) {
        TradeData memory tradeData = initTradeInput({
            trader: trader,
            src: src,
            dest: dest,
            srcAmount: srcAmount,
            destAddress: destAddress,
            maxDestAmount: maxDestAmount,
            minConversionRate: minConversionRate,
            platformWallet: walletId,
            platformFeeBps: 0
        });

        return trade(tradeData, hint);
    }

    /// @notice Use token address ETH_TOKEN_ADDRESS for ether
    /// @dev Trade from src to dest token and sends dest token to destAddress
    /// @param trader Address of the taker side of this trade
    /// @param src Source token
    /// @param srcAmount Amount of src tokens in twei
    /// @param dest Destination token
    /// @param destAddress Address to send tokens to
    /// @param maxDestAmount A limit on the amount of dest tokens in twei
    /// @param minConversionRate The minimal conversion rate. If actual rate is lower, trade reverts
    /// @param platformWallet Platform wallet address for receiving fees
    /// @param platformFeeBps Part of the trade that is allocated as fee to platform wallet. Ex: 1000 = 10%
    /// @param hint Advanced instructions for running the trade 
    /// @return destAmount Amount of actual dest tokens in twei
    function tradeWithHintAndFee(
        address payable trader,
        IERC20 src,
        uint256 srcAmount,
        IERC20 dest,
        address payable destAddress,
        uint256 maxDestAmount,
        uint256 minConversionRate,
        address payable platformWallet,
        uint256 platformFeeBps,
        bytes calldata hint
    ) external payable override returns (uint256 destAmount) {
        TradeData memory tradeData = initTradeInput({
            trader: trader,
            src: src,
            dest: dest,
            srcAmount: srcAmount,
            destAddress: destAddress,
            maxDestAmount: maxDestAmount,
            minConversionRate: minConversionRate,
            platformWallet: platformWallet,
            platformFeeBps: platformFeeBps
        });

        return trade(tradeData, hint);
    }

    /// @notice Can be called only by LyfeblocStorage
    /// @dev Allow or prevent to trade token -> eth for a reserve
    /// @param reserve The reserve address
    /// @param token Token address
    /// @param add If true, then give reserve token allowance, otherwise set zero allowance
    function listTokenForReserve(
        address reserve,
        IERC20 token,
        bool add
    ) external override {
        require(msg.sender == address(lyfeblocStorage), "only lyfeblocStorage");

        if (add) {
            token.safeApprove(reserve, MAX_ALLOWANCE);
            setDecimals(token);
        } else {
            token.safeApprove(reserve, 0);
        }
    }

    /// @notice Can be called only by operator
    /// @dev Allow or prevent to trade token -> eth for list of reserves
    ///      Useful for migration to new network contract
    ///      Call storage to get list of reserves supporting token -> eth
    /// @param token Token address
    /// @param startIndex start index in reserves list
    /// @param endIndex end index in reserves list (can be larger)
    /// @param add If true, then give reserve token allowance, otherwise set zero allowance
    function listReservesForToken(
        IERC20 token,
        uint256 startIndex,
        uint256 endIndex,
        bool add
    ) external {
        onlyOperator();

        if (startIndex > endIndex) {
            // no need to do anything
            return;
        }

        address[] memory reserves = lyfeblocStorage.getReserveAddressesPerTokenSrc(
            token, startIndex, endIndex
        );

        if (reserves.length == 0) {
            // no need to do anything
            return;
        }

        for(uint i = 0; i < reserves.length; i++) {
            if (add) {
                token.safeApprove(reserves[i], MAX_ALLOWANCE);
                setDecimals(token);
            } else {
                token.safeApprove(reserves[i], 0);
            }
        }

        emit ListedReservesForToken(token, reserves, add);
    }

    function setContracts(
        ILyfeblocFeeHandler _lyfeblocFeeHandler,
        ILyfeblocMatchingEngine _lyfeblocMatchingEngine,
        IGasHelper _gasHelper
    ) external virtual {
        onlyAdmin();

        if (lyfeblocFeeHandler != _lyfeblocFeeHandler) {
            lyfeblocFeeHandler = _lyfeblocFeeHandler;
            emit LyfeblocFeeHandlerUpdated(_lyfeblocFeeHandler);
        }

        if (lyfeblocMatchingEngine != _lyfeblocMatchingEngine) {
            lyfeblocMatchingEngine = _lyfeblocMatchingEngine;
            emit LyfeblocMatchingEngineUpdated(_lyfeblocMatchingEngine);
        }

        if ((_gasHelper != IGasHelper(0)) && (_gasHelper != gasHelper)) {
            gasHelper = _gasHelper;
            emit GasHelperUpdated(_gasHelper);
        }

        lyfeblocStorage.setContracts(address(_lyfeblocFeeHandler), address(_lyfeblocMatchingEngine));
        require(_lyfeblocFeeHandler != ILyfeblocFeeHandler(0));
        require(_lyfeblocMatchingEngine != ILyfeblocMatchingEngine(0));
    }

    function setLyfeblocDaoContract(ILyfeblocDao _lyfeblocDao) external {
        // enable setting null lyfeblocDao address
        onlyAdmin();
        if (lyfeblocDao != _lyfeblocDao) {
            lyfeblocDao = _lyfeblocDao;
            lyfeblocStorage.setLyfeblocDaoContract(address(_lyfeblocDao));
            emit LyfeblocDaoUpdated(_lyfeblocDao);
        }
    }

    function setParams(uint256 _maxGasPrice, uint256 _negligibleRateDiffBps) external {
        onlyAdmin();
        maxGasPriceValue = _maxGasPrice;
        lyfeblocMatchingEngine.setNegligibleRateDiffBps(_negligibleRateDiffBps);
        emit LyfeblocNetworkParamsSet(maxGasPriceValue, _negligibleRateDiffBps);
    }

    function setEnable(bool enable) external {
        onlyAdmin();

        if (enable) {
            require(lyfeblocFeeHandler != ILyfeblocFeeHandler(0));
            require(lyfeblocMatchingEngine != ILyfeblocMatchingEngine(0));
            require(lyfeblocStorage.isLyfeblocProxyAdded());
        }

        isEnabled = enable;

        emit LyfeblocNetworkSetEnable(isEnabled);
    }

    /// @dev No. of lyfeblocProxies is capped
    function addLyfeblocProxy(address lyfeblocProxy) external virtual {
        onlyAdmin();
        lyfeblocStorage.addLyfeblocProxy(lyfeblocProxy, MAX_APPROVED_PROXIES);
        require(lyfeblocProxy != address(0));
        require(!lyfeblocProxyContracts[lyfeblocProxy]);

       lyfeblocProxyContracts[lyfeblocProxy] = true;

        emit LyfeblocProxyAdded(lyfeblocProxy);
    }

    function removeLyfeblocProxy(address lyfeblocProxy) external virtual {
        onlyAdmin();

        lyfeblocStorage.removeLyfeblocProxy(lyfeblocProxy);

        require(lyfeblocProxyContracts[lyfeblocProxy]);

        lyfeblocProxyContracts[lyfeblocProxy] = false;

        emit LyfeblocProxyRemoved(lyfeblocProxy);
    }

    /// @dev gets the expected rates when trading src -> dest token, with / without fees
    /// @param src Source token
    /// @param dest Destination token
    /// @param srcQty Amount of src tokens in twei
    /// @param platformFeeBps Part of the trade that is allocated as fee to platform wallet. Ex: 1000 = 10%
    /// @param hint Advanced instructions for running the trade 
    /// @return rateWithNetworkFee Rate after deducting network fee but excluding platform fee
    /// @return rateWithAllFees = actual rate. Rate after accounting for both network and platform fees
    function getExpectedRateWithHintAndFee(
        IERC20 src,
        IERC20 dest,
        uint256 srcQty,
        uint256 platformFeeBps,
        bytes calldata hint
    )
        external
        view
        override
        returns (
            uint256 rateWithNetworkFee,
            uint256 rateWithAllFees
        )
    {
        if (src == dest) return (0, 0);

        TradeData memory tradeData = initTradeInput({
            trader: payable(address(0)),
            src: src,
            dest: dest,
            srcAmount: (srcQty == 0) ? 1 : srcQty,
            destAddress: payable(address(0)),
            maxDestAmount: 2**255,
            minConversionRate: 0,
            platformWallet: payable(address(0)),
            platformFeeBps: platformFeeBps
        });

        tradeData.networkFeeBps = getNetworkFee();

        uint256 destAmount;
        (destAmount, rateWithNetworkFee) = calcRatesAndAmounts(tradeData, hint);

        rateWithAllFees = calcRateFromQty(
            tradeData.input.srcAmount,
            destAmount,
            tradeData.tokenToEth.decimals,
            tradeData.ethToToken.decimals
        );
    }

    /// @notice Backward compatible API
    /// @dev Gets the expected and slippage rate for exchanging src -> dest token
    /// @dev worstRate is hardcoded to be 3% lower of expectedRate
    /// @param src Source token
    /// @param dest Destination token
    /// @param srcQty Amount of src tokens in twei
    /// @return expectedRate for a trade after deducting network fee. 
    /// @return worstRate for a trade. Calculated to be expectedRate * 97 / 100
    function getExpectedRate(
        ERC20 src,
        ERC20 dest,
        uint256 srcQty
    ) external view returns (uint256 expectedRate, uint256 worstRate) {
        if (src == dest) return (0, 0);
        uint256 qty = srcQty & ~PERM_HINT_GET_RATE;

        TradeData memory tradeData = initTradeInput({
            trader: payable(address(0)),
            src: src,
            dest: dest,
            srcAmount: (qty == 0) ? 1 : qty,
            destAddress: payable(address(0)),
            maxDestAmount: 2**255,
            minConversionRate: 0,
            platformWallet: payable(address(0)),
            platformFeeBps: 0
        });

        tradeData.networkFeeBps = getNetworkFee();

        (, expectedRate) = calcRatesAndAmounts(tradeData, "");

        worstRate = (expectedRate * 97) / 100; // backward compatible formula
    }

    /// @notice Returns some data about the network
    /// @param negligibleDiffBps Negligible rate difference (in basis pts) when searching best rate
    /// @param networkFeeBps Network fees to be charged (in basis pts)
    /// @param expiryTimestamp Timestamp for which networkFeeBps will expire,
    ///     and needs to be updated by calling lyfeblocDao contract / set to default
    function getNetworkData()
        external
        view
        override
        returns (
            uint256 negligibleDiffBps,
            uint256 networkFeeBps,
            uint256 expiryTimestamp
        )
    {
        (networkFeeBps, expiryTimestamp) = readNetworkFeeData();
        negligibleDiffBps = lyfeblocMatchingEngine.getNegligibleRateDiffBps();
        return (negligibleDiffBps, networkFeeBps, expiryTimestamp);
    }

    function getContracts()
        external
        view
        returns (
            ILyfeblocFeeHandler lyfeblocFeeHandlerAddress,
            ILyfeblocDao lyfeblocDaoAddress,
            ILyfeblocMatchingEngine lyfeblocMatchingEngineAddress,
            ILyfeblocStorage lyfeblocStorageAddress,
            IGasHelper gasHelperAddress,
            ILyfeblocNetworkProxy[] memory lyfeblocProxyAddresses
        )
    {
        return (
            lyfeblocFeeHandler,
            lyfeblocDao,
            lyfeblocMatchingEngine,
            lyfeblocStorage,
            gasHelper,
            lyfeblocStorage.getLyfeblocProxies()
        );
    }

    /// @notice returns the max gas price allowable for trades
    function maxGasPrice() external view override returns (uint256) {
        return maxGasPriceValue;
    }

    /// @notice returns status of the network. If disabled, trades cannot happen.
    function enabled() external view override returns (bool) {
        return isEnabled;
    }

    /// @notice Gets network fee from the lyfeblocDao (or use default).
    ///     For trade function, so that data can be updated and cached.
    /// @dev Note that this function can be triggered by anyone, so that
    ///     the first trader of a new epoch can avoid incurring extra gas costs
    function getAndUpdateNetworkFee() public returns (uint256 networkFeeBps) {
        uint256 expiryTimestamp;

        (networkFeeBps, expiryTimestamp) = readNetworkFeeData();

        if (expiryTimestamp < now && lyfeblocDao != ILyfeblocDao(0)) {
            (networkFeeBps, expiryTimestamp) = lyfeblocDao.getLatestNetworkFeeDataWithCache();
            updateNetworkFee(expiryTimestamp, networkFeeBps);
        }
    }

    /// @notice Calculates platform fee and reserve rebate percentages for the trade.
    ///     Transfers eth and rebate wallet data to lyfeblocFeeHandler
    function handleFees(TradeData memory tradeData) internal {
        uint256 sentFee = tradeData.networkFeeWei + tradeData.platformFeeWei;
        //no need to handle fees if total fee is zero
        if (sentFee == 0)
            return;

        // update reserve eligibility and rebate percentages
        (
            address[] memory rebateWallets,
            uint256[] memory rebatePercentBps
        ) = calculateRebates(tradeData);

        // send total fee amount to fee handler with reserve data
        lyfeblocFeeHandler.handleFees{value: sentFee}(
            ETH_TOKEN_ADDRESS,
            rebateWallets,
            rebatePercentBps,
            tradeData.input.platformWallet,
            tradeData.platformFeeWei,
            tradeData.networkFeeWei
        );
    }

    function updateNetworkFee(uint256 expiryTimestamp, uint256 feeBps) internal {
        require(expiryTimestamp < 2**64, "expiry overflow");
        require(feeBps < BPS / 2, "fees exceed BPS");

        networkFeeData.expiryTimestamp = uint64(expiryTimestamp);
        networkFeeData.feeBps = uint16(feeBps);
    }

    /// @notice Use token address ETH_TOKEN_ADDRESS for ether
    /// @dev Do one trade with each reserve in reservesData, verifying network balance 
    ///    as expected to ensure reserves take correct src amount
    /// @param src Source token
    /// @param dest Destination token
    /// @param destAddress Address to send tokens to
    /// @param reservesData reservesData to trade
    /// @param expectedDestAmount Amount to be transferred to destAddress
    /// @param srcDecimals Decimals of source token
    /// @param destDecimals Decimals of destination token
    function doReserveTrades(
        IERC20 src,
        IERC20 dest,
        address payable destAddress,
        ReservesData memory reservesData,
        uint256 expectedDestAmount,
        uint256 srcDecimals,
        uint256 destDecimals
    ) internal virtual {

        if (src == dest) {
            // eth -> eth, need not do anything except for token -> eth: transfer eth to destAddress
            if (destAddress != (address(this))) {
                (bool success, ) = destAddress.call{value: expectedDestAmount}("");
                require(success, "send dest qty failed");
            }
            return;
        }

        tradeAndVerifyNetworkBalance(
            reservesData,
            src,
            dest,
            srcDecimals,
            destDecimals
        );

        if (destAddress != address(this)) {
            // for eth -> token / token -> token, transfer tokens to destAddress
            dest.safeTransfer(destAddress, expectedDestAmount);
        }
    }

    /// @dev call trade from reserves and verify balances
    /// @param reservesData reservesData to trade
    /// @param src Source token of trade
    /// @param dest Destination token of trade
    /// @param srcDecimals Decimals of source token
    /// @param destDecimals Decimals of destination token
    function tradeAndVerifyNetworkBalance(
        ReservesData memory reservesData,
        IERC20 src,
        IERC20 dest,
        uint256 srcDecimals,
        uint256 destDecimals
    ) internal
    {
        // only need to verify src balance if src is not eth
        uint256 srcBalanceBefore = (src == ETH_TOKEN_ADDRESS) ? 0 : getBalance(src, address(this));
        uint256 destBalanceBefore = getBalance(dest, address(this));

        for(uint256 i = 0; i < reservesData.addresses.length; i++) {
            uint256 callValue = (src == ETH_TOKEN_ADDRESS) ? reservesData.srcAmounts[i] : 0;
            require(
                reservesData.addresses[i].trade{value: callValue}(
                    src,
                    reservesData.srcAmounts[i],
                    dest,
                    address(this),
                    reservesData.rates[i],
                    true
                ),
                "reserve trade failed"
            );

            uint256 balanceAfter;
            if (src != ETH_TOKEN_ADDRESS) {
                // verify src balance only if it is not eth
                balanceAfter = getBalance(src, address(this));
                // verify correct src amount is taken
                if (srcBalanceBefore >= balanceAfter && srcBalanceBefore - balanceAfter > reservesData.srcAmounts[i]) {
                    revert("reserve takes high amount");
                }
                srcBalanceBefore = balanceAfter;
            }

            // verify correct dest amount is received
            uint256 expectedDestAmount = calcDstQty(
                reservesData.srcAmounts[i],
                srcDecimals,
                destDecimals,
                reservesData.rates[i]
            );
            balanceAfter = getBalance(dest, address(this));
            if (balanceAfter < destBalanceBefore || balanceAfter - destBalanceBefore < expectedDestAmount) {
                revert("reserve returns low amount");
            }
            destBalanceBefore = balanceAfter;
        }
    }

    /// @notice Use token address ETH_TOKEN_ADDRESS for ether
    /// @dev Trade API for lyfeblocNetwork
    /// @param tradeData Main trade data object for trade info to be stored
    function trade(TradeData memory tradeData, bytes memory hint)
        internal
        virtual
        nonReentrant
        returns (uint256 destAmount)
    {
        tradeData.networkFeeBps = getAndUpdateNetworkFee();

        validateTradeInput(tradeData.input);

        uint256 rateWithNetworkFee;
        (destAmount, rateWithNetworkFee) = calcRatesAndAmounts(tradeData, hint);

        require(rateWithNetworkFee > 0, "trade invalid, if hint involved, try parseHint API");
        require(rateWithNetworkFee < MAX_RATE, "rate > MAX_RATE");
        require(rateWithNetworkFee >= tradeData.input.minConversionRate, "rate < min rate");

        uint256 actualSrcAmount;

        if (destAmount > tradeData.input.maxDestAmount) {
            // notice tradeData passed by reference and updated
            destAmount = tradeData.input.maxDestAmount;
            actualSrcAmount = calcTradeSrcAmountFromDest(tradeData);
        } else {
            actualSrcAmount = tradeData.input.srcAmount;
        }

        // token -> eth
        doReserveTrades(
            tradeData.input.src,
            ETH_TOKEN_ADDRESS,
            address(this),
            tradeData.tokenToEth,
            tradeData.tradeWei,
            tradeData.tokenToEth.decimals,
            ETH_DECIMALS
        );

        // eth -> token
        doReserveTrades(
            ETH_TOKEN_ADDRESS,
            tradeData.input.dest,
            tradeData.input.destAddress,
            tradeData.ethToToken,
            destAmount,
            ETH_DECIMALS,
            tradeData.ethToToken.decimals
        );

        handleChange(
            tradeData.input.src,
            tradeData.input.srcAmount,
            actualSrcAmount,
            tradeData.input.trader
        );

        handleFees(tradeData);

        emit LyfeblocTrade({
            src: tradeData.input.src,
            dest: tradeData.input.dest,
            ethWeiValue: tradeData.tradeWei,
            networkFeeWei: tradeData.networkFeeWei,
            customPlatformFeeWei: tradeData.platformFeeWei,
            t2eIds: tradeData.tokenToEth.ids,
            e2tIds: tradeData.ethToToken.ids,
            t2eSrcAmounts: tradeData.tokenToEth.srcAmounts,
            e2tSrcAmounts: tradeData.ethToToken.srcAmounts,
            t2eRates: tradeData.tokenToEth.rates,
            e2tRates: tradeData.ethToToken.rates
        });

        if (gasHelper != IGasHelper(0)) {
            (bool success, ) = address(gasHelper).call(
                abi.encodeWithSignature(
                    "freeGas(address,address,address,uint256,bytes32[],bytes32[])",
                    tradeData.input.platformWallet,
                    tradeData.input.src,
                    tradeData.input.dest,
                    tradeData.tradeWei,
                    tradeData.tokenToEth.ids,
                    tradeData.ethToToken.ids
                )
            );
            // remove compilation warning
            success;
        }

        return (destAmount);
    }

    /// @notice If user maxDestAmount < actual dest amount, actualSrcAmount will be < srcAmount
    /// Calculate the change, and send it back to the user
    function handleChange(
        IERC20 src,
        uint256 srcAmount,
        uint256 requiredSrcAmount,
        address payable trader
    ) internal {
        if (requiredSrcAmount < srcAmount) {
            // if there is "change" send back to trader
            if (src == ETH_TOKEN_ADDRESS) {
                (bool success, ) = trader.call{value: (srcAmount - requiredSrcAmount)}("");
                require(success, "Send change failed");
            } else {
                src.safeTransfer(trader, (srcAmount - requiredSrcAmount));
            }
        }
    }

    function initTradeInput(
        address payable trader,
        IERC20 src,
        IERC20 dest,
        uint256 srcAmount,
        address payable destAddress,
        uint256 maxDestAmount,
        uint256 minConversionRate,
        address payable platformWallet,
        uint256 platformFeeBps
    ) internal view returns (TradeData memory tradeData) {
        tradeData.input.trader = trader;
        tradeData.input.src = src;
        tradeData.input.srcAmount = srcAmount;
        tradeData.input.dest = dest;
        tradeData.input.destAddress = destAddress;
        tradeData.input.maxDestAmount = maxDestAmount;
        tradeData.input.minConversionRate = minConversionRate;
        tradeData.input.platformWallet = platformWallet;
        tradeData.input.platformFeeBps = platformFeeBps;

        tradeData.tokenToEth.decimals = getDecimals(src);
        tradeData.ethToToken.decimals = getDecimals(dest);
    }

    /// @notice This function does all calculations to find trade dest amount without accounting 
    ///        for maxDestAmount. Part of this process includes:
    ///        - Call lyfeblocMatchingEngine to parse hint and get an optional reserve list to trade.
    ///        - Query reserve rates and call vMatchingEngine to use best reserve.
    ///        - Calculate trade values and fee values.
    ///     This function should set all TradeData information so that it can be later used without 
    ///         any ambiguity
    /// @param tradeData Main trade data object for trade info to be stored
    /// @param hint Advanced user instructions for the trade 
    function calcRatesAndAmounts(TradeData memory tradeData, bytes memory hint)
        internal
        view
        returns (uint256 destAmount, uint256 rateWithNetworkFee)
    {
        validateFeeInput(tradeData.input, tradeData.networkFeeBps);

        // token -> eth: find best reserves match and calculate wei amount
        tradeData.tradeWei = calcDestQtyAndMatchReserves(
            tradeData.input.src,
            ETH_TOKEN_ADDRESS,
            tradeData.input.srcAmount,
            tradeData,
            tradeData.tokenToEth,
            hint
        );

        require(tradeData.tradeWei <= MAX_QTY, "Trade wei > MAX_QTY");
        if (tradeData.tradeWei == 0) {
            return (0, 0);
        }

        // calculate fees
        tradeData.platformFeeWei = (tradeData.tradeWei * tradeData.input.platformFeeBps) / BPS;
        tradeData.networkFeeWei =
            (((tradeData.tradeWei * tradeData.networkFeeBps) / BPS) * tradeData.feeAccountedBps) /
            BPS;

        assert(tradeData.tradeWei >= (tradeData.networkFeeWei + tradeData.platformFeeWei));

        // eth -> token: find best reserves match and calculate trade dest amount
        uint256 actualSrcWei = tradeData.tradeWei -
            tradeData.networkFeeWei -
            tradeData.platformFeeWei;

        destAmount = calcDestQtyAndMatchReserves(
            ETH_TOKEN_ADDRESS,
            tradeData.input.dest,
            actualSrcWei,
            tradeData,
            tradeData.ethToToken,
            hint
        );

        tradeData.networkFeeWei =
            (((tradeData.tradeWei * tradeData.networkFeeBps) / BPS) * tradeData.feeAccountedBps) /
            BPS;

        rateWithNetworkFee = calcRateFromQty(
            tradeData.input.srcAmount * (BPS - tradeData.input.platformFeeBps) / BPS,
            destAmount,
            tradeData.tokenToEth.decimals,
            tradeData.ethToToken.decimals
        );
    }

    /// @notice Get trading reserves, source amounts, and calculate dest qty
    /// Store information into tradeData
    function calcDestQtyAndMatchReserves(
        IERC20 src,
        IERC20 dest,
        uint256 srcAmount,
        TradeData memory tradeData,
        ReservesData memory reservesData,
        bytes memory hint
    ) internal view returns (uint256 destAmount) {
        if (src == dest) {
            return srcAmount;
        }

        ILyfeblocMatchingEngine.ProcessWithRate processWithRate;

        // get reserve list from lyfeblocMatchingEngine
        (reservesData.ids, reservesData.splitsBps, processWithRate) =
            lyfeblocMatchingEngine.getTradingReserves(
            src,
            dest,
            (tradeData.input.src != ETH_TOKEN_ADDRESS) && (tradeData.input.dest != ETH_TOKEN_ADDRESS),
            hint
        );
        bool areAllReservesListed;
        (areAllReservesListed, reservesData.isFeeAccountedFlags, reservesData.isEntitledRebateFlags, reservesData.addresses)
            = lyfeblocStorage.getReservesData(reservesData.ids, src, dest);

        if(!areAllReservesListed) {
            return 0;
        }

        require(reservesData.ids.length == reservesData.splitsBps.length, "bad split array");
        require(reservesData.ids.length == reservesData.isFeeAccountedFlags.length, "bad fee array");
        require(reservesData.ids.length == reservesData.isEntitledRebateFlags.length, "bad rebate array");
        require(reservesData.ids.length == reservesData.addresses.length, "bad addresses array");

        // calculate src trade amount per reserve and query rates
        // set data in reservesData struct
        uint256[] memory feesAccountedDestBps = calcSrcAmountsAndGetRates(
            reservesData,
            src,
            dest,
            srcAmount,
            tradeData
        );

        // if matching engine requires processing with rate data. call doMatch and update reserve list
        if (processWithRate == ILyfeblocMatchingEngine.ProcessWithRate.Required) {
            uint256[] memory selectedIndexes = lyfeblocMatchingEngine.doMatch(
                src,
                dest,
                reservesData.srcAmounts,
                feesAccountedDestBps,
                reservesData.rates
            );

            updateReservesList(reservesData, selectedIndexes);
        }

        // calculate dest amount and fee paying data of this part (t2e or e2t)
        destAmount = validateTradeCalcDestQtyAndFeeData(src, reservesData, tradeData);
    }

    /// @notice Calculates source amounts per reserve. Does get rate call
    function calcSrcAmountsAndGetRates(
        ReservesData memory reservesData,
        IERC20 src,
        IERC20 dest,
        uint256 srcAmount,
        TradeData memory tradeData
    ) internal view returns (uint256[] memory feesAccountedDestBps) {
        uint256 numReserves = reservesData.ids.length;
        uint256 srcAmountAfterFee;
        uint256 destAmountFeeBps;

        if (src == ETH_TOKEN_ADDRESS) {
            // @notice srcAmount is after deducting fees from tradeWei
            // @notice using tradeWei to calculate fee so eth -> token symmetric to token -> eth
            srcAmountAfterFee = srcAmount - 
                (tradeData.tradeWei * tradeData.networkFeeBps / BPS);
        } else { 
            srcAmountAfterFee = srcAmount;
            destAmountFeeBps = tradeData.networkFeeBps;
        }

        reservesData.srcAmounts = new uint256[](numReserves);
        reservesData.rates = new uint256[](numReserves);
        feesAccountedDestBps = new uint256[](numReserves);

        // iterate reserve list. validate data. calculate srcAmount according to splits and fee data.
        for (uint256 i = 0; i < numReserves; i++) {
            require(
                reservesData.splitsBps[i] > 0 && reservesData.splitsBps[i] <= BPS,
                "invalid split bps"
            );

            if (reservesData.isFeeAccountedFlags[i]) {
                reservesData.srcAmounts[i] = srcAmountAfterFee * reservesData.splitsBps[i] / BPS;
                feesAccountedDestBps[i] = destAmountFeeBps;
            } else {
                reservesData.srcAmounts[i] = (srcAmount * reservesData.splitsBps[i]) / BPS;
            }

            // get rate with calculated src amount
            reservesData.rates[i] = reservesData.addresses[i].getConversionRate(
                src,
                dest,
                reservesData.srcAmounts[i],
                block.number
            );
        }
    }

    function calculateRebates(TradeData memory tradeData)
        internal
        view
        returns (address[] memory rebateWallets, uint256[] memory rebatePercentBps)
    {
        rebateWallets = new address[](tradeData.numEntitledRebateReserves);
        rebatePercentBps = new uint256[](tradeData.numEntitledRebateReserves);
        if (tradeData.numEntitledRebateReserves == 0) {
            return (rebateWallets, rebatePercentBps);
        }

        uint256 index;
        bytes32[] memory rebateReserveIds = new bytes32[](tradeData.numEntitledRebateReserves);

        // token -> eth
        index = createRebateEntitledList(
            rebateReserveIds,
            rebatePercentBps,
            tradeData.tokenToEth,
            index,
            tradeData.feeAccountedBps
        );

        // eth -> token
        createRebateEntitledList(
            rebateReserveIds,
            rebatePercentBps,
            tradeData.ethToToken,
            index,
            tradeData.feeAccountedBps
        );

        rebateWallets = lyfeblocStorage.getRebateWalletsFromIds(rebateReserveIds);
    }

    function createRebateEntitledList(
        bytes32[] memory rebateReserveIds,
        uint256[] memory rebatePercentBps,
        ReservesData memory reservesData,
        uint256 index,
        uint256 feeAccountedBps
    ) internal pure returns (uint256) {
        uint256 _index = index;

        for (uint256 i = 0; i < reservesData.isEntitledRebateFlags.length; i++) {
            if (reservesData.isEntitledRebateFlags[i]) {
                rebateReserveIds[_index] = reservesData.ids[i];
                rebatePercentBps[_index] = (reservesData.splitsBps[i] * BPS) / feeAccountedBps;
                _index++;
            }
        }
        return _index;
    }

    /// @dev Checks a trade input validity, including correct src amounts
    /// @param input Trade input structure
    function validateTradeInput(TradeInput memory input) internal view
    {
        require(isEnabled, "network disabled");
        require(lyfeblocProxyContracts[msg.sender], "bad sender");
        require(tx.gasprice <= maxGasPriceValue, "gas price");
        require(input.srcAmount <= MAX_QTY, "srcAmt > MAX_QTY");
        require(input.srcAmount != 0, "0 srcAmt");
        require(input.destAddress != address(0), "dest add 0");
        require(input.src != input.dest, "src = dest");

        if (input.src == ETH_TOKEN_ADDRESS) {
            require(msg.value == input.srcAmount); // lyfeblocProxy issues message here
        } else {
            require(msg.value == 0); // lyfeblocProxy issues message here
            // funds should have been moved to this contract already.
            require(input.src.balanceOf(address(this)) >= input.srcAmount, "no tokens");
        }
    }

    /// @notice Gets the network fee from lyfeblocDao (or use default). View function for getExpectedRate
    function getNetworkFee() internal view returns (uint256 networkFeeBps) {
        uint256 expiryTimestamp;
        (networkFeeBps, expiryTimestamp) = readNetworkFeeData();

        if (expiryTimestamp < now && lyfeblocDao != ILyfeblocDao(0)) {
            (networkFeeBps, expiryTimestamp) = lyfeblocDao.getLatestNetworkFeeData();
        }
    }

    function readNetworkFeeData() internal view returns (uint256 feeBps, uint256 expiryTimestamp) {
        feeBps = uint256(networkFeeData.feeBps);
        expiryTimestamp = uint256(networkFeeData.expiryTimestamp);
    }

    /// @dev Checks fee input validity, including correct src amounts
    /// @param input Trade input structure
    /// @param networkFeeBps Network fee in bps.
    function validateFeeInput(TradeInput memory input, uint256 networkFeeBps) internal pure {
        require(input.platformFeeBps < BPS, "platformFee high");
        require(input.platformFeeBps + networkFeeBps + networkFeeBps < BPS, "fees high");
    }

    /// @notice Update reserve data with selected reserves from lyfeblocMatchingEngine
    function updateReservesList(ReservesData memory reservesData, uint256[] memory selectedIndexes)
        internal
        pure
    {
        uint256 numReserves = selectedIndexes.length;

        require(numReserves <= reservesData.addresses.length, "doMatch: too many reserves");

        ILyfeblocReserve[] memory reserveAddresses = new ILyfeblocReserve[](numReserves);
        bytes32[] memory reserveIds = new bytes32[](numReserves);
        uint256[] memory splitsBps = new uint256[](numReserves);
        bool[] memory isFeeAccountedFlags = new bool[](numReserves);
        bool[] memory isEntitledRebateFlags = new bool[](numReserves);
        uint256[] memory srcAmounts = new uint256[](numReserves);
        uint256[] memory rates = new uint256[](numReserves);

        // update participating resevres and all data (rates, srcAmounts, feeAcounted etc.)
        for (uint256 i = 0; i < numReserves; i++) {
            reserveAddresses[i] = reservesData.addresses[selectedIndexes[i]];
            reserveIds[i] = reservesData.ids[selectedIndexes[i]];
            splitsBps[i] = reservesData.splitsBps[selectedIndexes[i]];
            isFeeAccountedFlags[i] = reservesData.isFeeAccountedFlags[selectedIndexes[i]];
            isEntitledRebateFlags[i] = reservesData.isEntitledRebateFlags[selectedIndexes[i]];
            srcAmounts[i] = reservesData.srcAmounts[selectedIndexes[i]];
            rates[i] = reservesData.rates[selectedIndexes[i]];
        }

        // update values
        reservesData.addresses = reserveAddresses;
        reservesData.ids = reserveIds;
        reservesData.splitsBps = splitsBps;
        reservesData.isFeeAccountedFlags = isFeeAccountedFlags;
        reservesData.isEntitledRebateFlags = isEntitledRebateFlags;
        reservesData.rates = rates;
        reservesData.srcAmounts = srcAmounts;
    }

    /// @notice Verify split values bps and reserve ids,
    ///     then calculate the destQty from srcAmounts and rates
    /// @dev Each split bps must be in range (0, BPS]
    /// @dev Total split bps must be 100%
    /// @dev Reserve ids must be increasing
    function validateTradeCalcDestQtyAndFeeData(
        IERC20 src,
        ReservesData memory reservesData,
        TradeData memory tradeData
    ) internal pure returns (uint256 totalDestAmount) {
        uint256 totalBps;
        uint256 srcDecimals = (src == ETH_TOKEN_ADDRESS) ? ETH_DECIMALS : reservesData.decimals;
        uint256 destDecimals = (src == ETH_TOKEN_ADDRESS) ? reservesData.decimals : ETH_DECIMALS;
        
        for (uint256 i = 0; i < reservesData.addresses.length; i++) {
            if (i > 0 && (uint256(reservesData.ids[i]) <= uint256(reservesData.ids[i - 1]))) {
                return 0; // ids are not in increasing order
            }
            totalBps += reservesData.splitsBps[i];

            uint256 destAmount = calcDstQty(
                reservesData.srcAmounts[i],
                srcDecimals,
                destDecimals,
                reservesData.rates[i]
            );
            if (destAmount == 0) {
                return 0;
            }
            totalDestAmount += destAmount;

            if (reservesData.isFeeAccountedFlags[i]) {
                tradeData.feeAccountedBps += reservesData.splitsBps[i];

                if (reservesData.isEntitledRebateFlags[i]) {
                    tradeData.numEntitledRebateReserves++;
                }
            }
        }

        if (totalBps != BPS) {
            return 0;
        }
    }

    /// @notice Recalculates tradeWei, network and platform fees, and actual source amount needed for the trade
    /// in the event actualDestAmount > maxDestAmount
    function calcTradeSrcAmountFromDest(TradeData memory tradeData)
        internal
        pure
        virtual
        returns (uint256 actualSrcAmount)
    {
        uint256 weiAfterDeductingFees;
        if (tradeData.input.dest != ETH_TOKEN_ADDRESS) {
            weiAfterDeductingFees = calcTradeSrcAmount(
                tradeData.tradeWei - tradeData.platformFeeWei - tradeData.networkFeeWei,
                ETH_DECIMALS,
                tradeData.ethToToken.decimals,
                tradeData.input.maxDestAmount,
                tradeData.ethToToken
            );
        } else {
            weiAfterDeductingFees = tradeData.input.maxDestAmount;
        }

        // reverse calculation, because we are working backwards
        uint256 newTradeWei =
            (weiAfterDeductingFees * BPS * BPS) /
            ((BPS * BPS) -
                (tradeData.networkFeeBps *
                tradeData.feeAccountedBps +
                tradeData.input.platformFeeBps *
                BPS));
        tradeData.tradeWei = minOf(newTradeWei, tradeData.tradeWei);
        // recalculate network and platform fees based on tradeWei
        tradeData.networkFeeWei =
            (((tradeData.tradeWei * tradeData.networkFeeBps) / BPS) * tradeData.feeAccountedBps) /
            BPS;
        tradeData.platformFeeWei = (tradeData.tradeWei * tradeData.input.platformFeeBps) / BPS;

        if (tradeData.input.src != ETH_TOKEN_ADDRESS) {
            actualSrcAmount = calcTradeSrcAmount(
                tradeData.input.srcAmount,
                tradeData.tokenToEth.decimals,
                ETH_DECIMALS,
                tradeData.tradeWei,
                tradeData.tokenToEth
            );
        } else {
            actualSrcAmount = tradeData.tradeWei;
        }

        assert(actualSrcAmount <= tradeData.input.srcAmount);
    }

    /// @notice Recalculates srcAmounts and stores into tradingReserves, given the new destAmount.
    ///     Uses the original proportion of srcAmounts and rates to determine new split destAmounts,
    ///     then calculate the respective srcAmounts
    /// @dev Due to small rounding errors, will fallback to current src amounts if new src amount is greater
    function calcTradeSrcAmount(
        uint256 srcAmount,
        uint256 srcDecimals,
        uint256 destDecimals,
        uint256 destAmount,
        ReservesData memory reservesData
    ) internal pure returns (uint256 newSrcAmount) {
        uint256 totalWeightedDestAmount;
        for (uint256 i = 0; i < reservesData.srcAmounts.length; i++) {
            totalWeightedDestAmount += reservesData.srcAmounts[i] * reservesData.rates[i];
        }

        uint256[] memory newSrcAmounts = new uint256[](reservesData.srcAmounts.length);
        uint256 destAmountSoFar;
        uint256 currentSrcAmount;
        uint256 destAmountSplit;

        for (uint256 i = 0; i < reservesData.srcAmounts.length; i++) {
            currentSrcAmount = reservesData.srcAmounts[i];
            require(destAmount * currentSrcAmount * reservesData.rates[i] / destAmount == 
                    currentSrcAmount * reservesData.rates[i], 
                "multiplication overflow");
            destAmountSplit = i == (reservesData.srcAmounts.length - 1)
                ? (destAmount - destAmountSoFar)
                : (destAmount * currentSrcAmount * reservesData.rates[i]) /
                    totalWeightedDestAmount;
            destAmountSoFar += destAmountSplit;

            newSrcAmounts[i] = calcSrcQty(
                destAmountSplit,
                srcDecimals,
                destDecimals,
                reservesData.rates[i]
            );
            if (newSrcAmounts[i] > currentSrcAmount) {
                // revert back to use current src amounts
                return srcAmount;
            }

            newSrcAmount += newSrcAmounts[i];
        }
        // new src amounts are used only when all of them aren't greater then current srcAmounts
        reservesData.srcAmounts = newSrcAmounts;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;

import "./IERC20.sol";

interface IGasHelper {
    function freeGas(
        address platformWallet,
        IERC20 src,
        IERC20 dest,
        uint256 tradeWei,
        bytes32[] calldata t2eReserveIds,
        bytes32[] calldata e2tReserveIds
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;


import "./ILyfeblocStorage.sol";


interface ILyfeblocMatchingEngine {
    enum ProcessWithRate {NotRequired, Required}

    function setNegligibleRateDiffBps(uint256 _negligibleRateDiffBps) external;

    function setLyfeblocStorage(ILyfeblocStorage _LyfeblocStorage) external;

    function getNegligibleRateDiffBps() external view returns (uint256);

    function getTradingReserves(
        IERC20 src,
        IERC20 dest,
        bool isTokenToToken,
        bytes calldata hint
    )
        external
        view
        returns (
            bytes32[] memory reserveIds,
            uint256[] memory splitValuesBps,
            ProcessWithRate processWithRate
        );

    function doMatch(
        IERC20 src,
        IERC20 dest,
        uint256[] calldata srcAmounts,
        uint256[] calldata feesAccountedDestBps,
        uint256[] calldata rates
    ) external view returns (uint256[] memory reserveIndexes);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;

import "./IERC20.sol";
import "./ILyfeblocNetworkProxy.sol";
import "./ILyfeblocReserve.sol";





interface ILyfeblocStorage {
    enum ReserveType {NONE, FPR, APR, BRIDGE, UTILITY, CUSTOM, ORDERBOOK, LAST}

    function addLyfeblocProxy(address LyfeblocProxy, uint256 maxApprovedProxies)
        external;

    function removeLyfeblocProxy(address LyfeblocProxy) external;

    function setContracts(address _LyfeblocFeeHandler, address _LyfeblocMatchingEngine) external;

    function setLyfeblocDaoContract(address _LyfeblocDao) external;

    function getReserveId(address reserve) external view returns (bytes32 reserveId);

    function getReserveIdsFromAddresses(address[] calldata reserveAddresses)
        external
        view
        returns (bytes32[] memory reserveIds);

    function getReserveAddressesFromIds(bytes32[] calldata reserveIds)
        external
        view
        returns (address[] memory reserveAddresses);

    function getReserveIdsPerTokenSrc(IERC20 token)
        external
        view
        returns (bytes32[] memory reserveIds);

    function getReserveAddressesPerTokenSrc(IERC20 token, uint256 startIndex, uint256 endIndex)
        external
        view
        returns (address[] memory reserveAddresses);

    function getReserveIdsPerTokenDest(IERC20 token)
        external
        view
        returns (bytes32[] memory reserveIds);

    function getReserveAddressesByReserveId(bytes32 reserveId)
        external
        view
        returns (address[] memory reserveAddresses);

    function getRebateWalletsFromIds(bytes32[] calldata reserveIds)
        external
        view
        returns (address[] memory rebateWallets);

    function getLyfeblocProxies() external view returns (ILyfeblocNetworkProxy[] memory);

    function getReserveDetailsByAddress(address reserve)
        external
        view
        returns (
            bytes32 reserveId,
            address rebateWallet,
            ReserveType resType,
            bool isFeeAccountedFlag,
            bool isEntitledRebateFlag
        );

    function getReserveDetailsById(bytes32 reserveId)
        external
        view
        returns (
            address reserveAddress,
            address rebateWallet,
            ReserveType resType,
            bool isFeeAccountedFlag,
            bool isEntitledRebateFlag
        );

    function getFeeAccountedData(bytes32[] calldata reserveIds)
        external
        view
        returns (bool[] memory feeAccountedArr);

    function getEntitledRebateData(bytes32[] calldata reserveIds)
        external
        view
        returns (bool[] memory entitledRebateArr);

    function getReservesData(bytes32[] calldata reserveIds, IERC20 src, IERC20 dest)
        external
        view
        returns (
            bool areAllReservesListed,
            bool[] memory feeAccountedArr,
            bool[] memory entitledRebateArr,
            ILyfeblocReserve[] memory reserveAddresses);

    function isLyfeblocProxyAdded() external view returns (bool);
}

// SPDX-License-Identifier: MIT


pragma solidity 0.6.6;

import "./IERC20.sol";

interface ILyfeblocReserve {
    function trade(
        IERC20 srcToken,
        uint256 srcAmount,
        IERC20 destToken,
        address payable destAddress,
        uint256 conversionRate,
        bool validate
    ) external payable returns (bool);

    function getConversionRate(
        IERC20 src,
        IERC20 dest,
        uint256 srcQty,
        uint256 blockNumber
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;

import "./IERC20.sol";

interface ILyfeblocFeeHandler {
    event RewardPaid(address indexed staker, uint256 indexed epoch, IERC20 indexed token, uint256 amount);
    event RebatePaid(address indexed rebateWallet, IERC20 indexed token, uint256 amount);
    event PlatformFeePaid(address indexed platformWallet, IERC20 indexed token, uint256 amount);
    event KncBurned(uint256 kncTWei, IERC20 indexed token, uint256 amount);

    function handleFees(
        IERC20 token,
        address[] calldata eligibleWallets,
        uint256[] calldata rebatePercentages,
        address platformWallet,
        uint256 platformFee,
        uint256 networkFee
    ) external payable;

    function claimReserveRebate(address rebateWallet) external returns (uint256);

    function claimPlatformFee(address platformWallet) external returns (uint256);

    function claimStakerReward(
        address staker,
        uint256 epoch
    ) external returns(uint amount);
}

// SPDX-License-Identifier: MIT


pragma solidity 0.6.6;

import "./IEpochUtils.sol";

interface ILyfeblocDao is IEpochUtils {
    event Voted(address indexed staker, uint indexed epoch, uint indexed campaignID, uint option);

    function getLatestNetworkFeeDataWithCache()
        external
        returns (uint256 feeInBps, uint256 expiryTimestamp);

    function getLatestBRRDataWithCache()
        external
        returns (
            uint256 burnInBps,
            uint256 rewardInBps,
            uint256 rebateInBps,
            uint256 epoch,
            uint256 expiryTimestamp
        );

    function handleWithdrawal(address staker, uint256 penaltyAmount) external;

    function vote(uint256 campaignID, uint256 option) external;

    function getLatestNetworkFeeData()
        external
        view
        returns (uint256 feeInBps, uint256 expiryTimestamp);

    function shouldBurnRewardForEpoch(uint256 epoch) external view returns (bool);

    /**
     * @dev  return staker's reward percentage in precision for a past epoch only
     *       fee handler should call this function when a staker wants to claim reward
     *       return 0 if staker has no votes or stakes
     */
    function getPastEpochRewardPercentageInPrecision(address staker, uint256 epoch)
        external
        view
        returns (uint256);

    /**
     * @dev  return staker's reward percentage in precision for the current epoch
     *       reward percentage is not finalized until the current epoch is ended
     */
    function getCurrentEpochRewardPercentageInPrecision(address staker)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;

import "./SafeMath.sol";
import "./Address.sol";
import "./IERC20.sol";


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;

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
contract ReentrancyGuard {
    bool private _notEntered;

    constructor () internal {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;
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
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;

import "./IERC20.sol";

interface ILyfeblocNetwork {
    event LyfeblocTrade(
        IERC20 indexed src,
        IERC20 indexed dest,
        uint256 ethWeiValue,
        uint256 networkFeeWei,
        uint256 customPlatformFeeWei,
        bytes32[] t2eIds,
        bytes32[] e2tIds,
        uint256[] t2eSrcAmounts,
        uint256[] e2tSrcAmounts,
        uint256[] t2eRates,
        uint256[] e2tRates
    );

    function tradeWithHintAndFee(
        address payable trader,
        IERC20 src,
        uint256 srcAmount,
        IERC20 dest,
        address payable destAddress,
        uint256 maxDestAmount,
        uint256 minConversionRate,
        address payable platformWallet,
        uint256 platformFeeBps,
        bytes calldata hint
    ) external payable returns (uint256 destAmount);

    function listTokenForReserve(
        address reserve,
        IERC20 token,
        bool add
    ) external;

    function enabled() external view returns (bool);

    function getExpectedRateWithHintAndFee(
        IERC20 src,
        IERC20 dest,
        uint256 srcQty,
        uint256 platformFeeBps,
        bytes calldata hint
    )
        external
        view
        returns (
            uint256 expectedRateAfterNetworkFee,
            uint256 expectedRateAfterAllFees
        );

    function getNetworkData()
        external
        view
        returns (
            uint256 negligibleDiffBps,
            uint256 networkFeeBps,
            uint256 expiryTimestamp
        );

    function maxGasPrice() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;

import "./IERC20.sol";

/**
 * @title Lyfebloc utility file
 * mostly shared constants and rate calculation helpers
 * inherited by most of Lyfebloc contracts.
 * previous utils implementations are for previous solidity versions.
 */
contract Utils {
    IERC20 internal constant ETH_TOKEN_ADDRESS = IERC20(
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
    );
    uint256 internal constant PRECISION = (10**18);
    uint256 internal constant MAX_QTY = (10**28); // 10B tokens
    uint256 internal constant MAX_RATE = (PRECISION * 10**7); // up to 10M tokens per eth
    uint256 internal constant MAX_DECIMALS = 18;
    uint256 internal constant ETH_DECIMALS = 18;
    uint256 constant BPS = 10000; // Basic Price Steps. 1 step = 0.01%
    uint256 internal constant MAX_ALLOWANCE = uint256(-1); // token.approve inifinite

    mapping(IERC20 => uint256) internal decimals;

    function getUpdateDecimals(IERC20 token) internal returns (uint256) {
        if (token == ETH_TOKEN_ADDRESS) return ETH_DECIMALS; // save storage access
        uint256 tokenDecimals = decimals[token];
        // moreover, very possible that old tokens have decimals 0
        // these tokens will just have higher gas fees.
        if (tokenDecimals == 0) {
            tokenDecimals = token.decimals();
            decimals[token] = tokenDecimals;
        }

        return tokenDecimals;
    }

    function setDecimals(IERC20 token) internal {
        if (decimals[token] != 0) return; //already set

        if (token == ETH_TOKEN_ADDRESS) {
            decimals[token] = ETH_DECIMALS;
        } else {
            decimals[token] = token.decimals();
        }
    }

    /// @dev get the balance of a user.
    /// @param token The token type
    /// @return The balance
    function getBalance(IERC20 token, address user) internal view returns (uint256) {
        if (token == ETH_TOKEN_ADDRESS) {
            return user.balance;
        } else {
            return token.balanceOf(user);
        }
    }

    function getDecimals(IERC20 token) internal view returns (uint256) {
        if (token == ETH_TOKEN_ADDRESS) return ETH_DECIMALS; // save storage access
        uint256 tokenDecimals = decimals[token];
        // moreover, very possible that old tokens have decimals 0
        // these tokens will just have higher gas fees.
        if (tokenDecimals == 0) return token.decimals();

        return tokenDecimals;
    }

    function calcDestAmount(
        IERC20 src,
        IERC20 dest,
        uint256 srcAmount,
        uint256 rate
    ) internal view returns (uint256) {
        return calcDstQty(srcAmount, getDecimals(src), getDecimals(dest), rate);
    }

    function calcSrcAmount(
        IERC20 src,
        IERC20 dest,
        uint256 destAmount,
        uint256 rate
    ) internal view returns (uint256) {
        return calcSrcQty(destAmount, getDecimals(src), getDecimals(dest), rate);
    }

    function calcDstQty(
        uint256 srcQty,
        uint256 srcDecimals,
        uint256 dstDecimals,
        uint256 rate
    ) internal pure returns (uint256) {
        require(srcQty <= MAX_QTY, "srcQty > MAX_QTY");
        require(rate <= MAX_RATE, "rate > MAX_RATE");

        if (dstDecimals >= srcDecimals) {
            require((dstDecimals - srcDecimals) <= MAX_DECIMALS, "dst - src > MAX_DECIMALS");
            return (srcQty * rate * (10**(dstDecimals - srcDecimals))) / PRECISION;
        } else {
            require((srcDecimals - dstDecimals) <= MAX_DECIMALS, "src - dst > MAX_DECIMALS");
            return (srcQty * rate) / (PRECISION * (10**(srcDecimals - dstDecimals)));
        }
    }

    function calcSrcQty(
        uint256 dstQty,
        uint256 srcDecimals,
        uint256 dstDecimals,
        uint256 rate
    ) internal pure returns (uint256) {
        require(dstQty <= MAX_QTY, "dstQty > MAX_QTY");
        require(rate <= MAX_RATE, "rate > MAX_RATE");

        //source quantity is rounded up. to avoid dest quantity being too low.
        uint256 numerator;
        uint256 denominator;
        if (srcDecimals >= dstDecimals) {
            require((srcDecimals - dstDecimals) <= MAX_DECIMALS, "src - dst > MAX_DECIMALS");
            numerator = (PRECISION * dstQty * (10**(srcDecimals - dstDecimals)));
            denominator = rate;
        } else {
            require((dstDecimals - srcDecimals) <= MAX_DECIMALS, "dst - src > MAX_DECIMALS");
            numerator = (PRECISION * dstQty);
            denominator = (rate * (10**(dstDecimals - srcDecimals)));
        }
        return (numerator + denominator - 1) / denominator; //avoid rounding down errors
    }

    function calcRateFromQty(
        uint256 srcAmount,
        uint256 destAmount,
        uint256 srcDecimals,
        uint256 dstDecimals
    ) internal pure returns (uint256) {
        require(srcAmount <= MAX_QTY, "srcAmount > MAX_QTY");
        require(destAmount <= MAX_QTY, "destAmount > MAX_QTY");

        if (dstDecimals >= srcDecimals) {
            require((dstDecimals - srcDecimals) <= MAX_DECIMALS, "dst - src > MAX_DECIMALS");
            return ((destAmount * PRECISION) / ((10**(dstDecimals - srcDecimals)) * srcAmount));
        } else {
            require((srcDecimals - dstDecimals) <= MAX_DECIMALS, "src - dst > MAX_DECIMALS");
            return ((destAmount * PRECISION * (10**(srcDecimals - dstDecimals))) / srcAmount);
        }
    }

    function minOf(uint256 x, uint256 y) internal pure returns (uint256) {
        return x > y ? y : x;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;

import "./PermissionGroupsNoModifiers.sol";
import "./IERC20.sol";


contract WithdrawableNoModifiers is PermissionGroupsNoModifiers {
    constructor(address _admin) public PermissionGroupsNoModifiers(_admin) {}

    event EtherWithdraw(uint256 amount, address sendTo);
    event TokenWithdraw(IERC20 token, uint256 amount, address sendTo);

    /// @dev Withdraw Ethers
    function withdrawEther(uint256 amount, address payable sendTo) external {
        onlyAdmin();
        (bool success, ) = sendTo.call{value: amount}("");
        require(success);
        emit EtherWithdraw(amount, sendTo);
    }

    /// @dev Withdraw all IERC20 compatible tokens
    /// @param token IERC20 The address of the token contract
    function withdrawToken(
        IERC20 token,
        uint256 amount,
        address sendTo
    ) external {
        onlyAdmin();
        token.transfer(sendTo, amount);
        emit TokenWithdraw(token, amount, sendTo);
    }
}

// SPDX-License-Identifier: MIT




pragma solidity 0.6.6;


interface IERC20 {
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function approve(address _spender, uint256 _value) external returns (bool success);

    function transfer(address _to, uint256 _value) external returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function decimals() external view returns (uint8 digits);

    function totalSupply() external view returns (uint256 supply);
}


// to support backward compatible contract name -- so function signature remains same
abstract contract ERC20 is IERC20 {

}

// SPDX-License-Identifier: MIT


pragma solidity 0.6.6;


contract PermissionGroupsNoModifiers {
    address public admin;
    address public pendingAdmin;
    mapping(address => bool) internal operators;
    mapping(address => bool) internal alerters;
    address[] internal operatorsGroup;
    address[] internal alertersGroup;
    uint256 internal constant MAX_GROUP_SIZE = 50;

    event AdminClaimed(address newAdmin, address previousAdmin);
    event AlerterAdded(address newAlerter, bool isAdd);
    event OperatorAdded(address newOperator, bool isAdd);
    event TransferAdminPending(address pendingAdmin);

    constructor(address _admin) public {
        require(_admin != address(0), "admin 0");
        admin = _admin;
    }

    function getOperators() external view returns (address[] memory) {
        return operatorsGroup;
    }

    function getAlerters() external view returns (address[] memory) {
        return alertersGroup;
    }

    function addAlerter(address newAlerter) public {
        onlyAdmin();
        require(!alerters[newAlerter], "alerter exists"); // prevent duplicates.
        require(alertersGroup.length < MAX_GROUP_SIZE, "max alerters");

        emit AlerterAdded(newAlerter, true);
        alerters[newAlerter] = true;
        alertersGroup.push(newAlerter);
    }

    function addOperator(address newOperator) public {
        onlyAdmin();
        require(!operators[newOperator], "operator exists"); // prevent duplicates.
        require(operatorsGroup.length < MAX_GROUP_SIZE, "max operators");

        emit OperatorAdded(newOperator, true);
        operators[newOperator] = true;
        operatorsGroup.push(newOperator);
    }

    /// @dev Allows the pendingAdmin address to finalize the change admin process.
    function claimAdmin() public {
        require(pendingAdmin == msg.sender, "not pending");
        emit AdminClaimed(pendingAdmin, admin);
        admin = pendingAdmin;
        pendingAdmin = address(0);
    }

    function removeAlerter(address alerter) public {
        onlyAdmin();
        require(alerters[alerter], "not alerter");
        delete alerters[alerter];

        for (uint256 i = 0; i < alertersGroup.length; ++i) {
            if (alertersGroup[i] == alerter) {
                alertersGroup[i] = alertersGroup[alertersGroup.length - 1];
                alertersGroup.pop();
                emit AlerterAdded(alerter, false);
                break;
            }
        }
    }

    function removeOperator(address operator) public {
        onlyAdmin();
        require(operators[operator], "not operator");
        delete operators[operator];

        for (uint256 i = 0; i < operatorsGroup.length; ++i) {
            if (operatorsGroup[i] == operator) {
                operatorsGroup[i] = operatorsGroup[operatorsGroup.length - 1];
                operatorsGroup.pop();
                emit OperatorAdded(operator, false);
                break;
            }
        }
    }

    /// @dev Allows the current admin to set the pendingAdmin address
    /// @param newAdmin The address to transfer ownership to
    function transferAdmin(address newAdmin) public {
        onlyAdmin();
        require(newAdmin != address(0), "new admin 0");
        emit TransferAdminPending(newAdmin);
        pendingAdmin = newAdmin;
    }

    /// @dev Allows the current admin to set the admin in one tx. Useful initial deployment.
    /// @param newAdmin The address to transfer ownership to.
    function transferAdminQuickly(address newAdmin) public {
        onlyAdmin();
        require(newAdmin != address(0), "admin 0");
        emit TransferAdminPending(newAdmin);
        emit AdminClaimed(newAdmin, admin);
        admin = newAdmin;
    }

    function onlyAdmin() internal view {
        require(msg.sender == admin, "only admin");
    }

    function onlyAlerter() internal view {
        require(alerters[msg.sender], "only alerter");
    }

    function onlyOperator() internal view {
        require(operators[msg.sender], "only operator");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;

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
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;

import "./IERC20.sol";

interface ILyfeblocNetworkProxy {

    event ExecuteTrade(
        address indexed trader,
        IERC20 src,
        IERC20 dest,
        address destAddress,
        uint256 actualSrcAmount,
        uint256 actualDestAmount,
        address platformWallet,
        uint256 platformFeeBps
    );

    /// @notice backward compatible
    function tradeWithHint(
        ERC20 src,
        uint256 srcAmount,
        ERC20 dest,
        address payable destAddress,
        uint256 maxDestAmount,
        uint256 minConversionRate,
        address payable walletId,
        bytes calldata hint
    ) external payable returns (uint256);

    function tradeWithHintAndFee(
        IERC20 src,
        uint256 srcAmount,
        IERC20 dest,
        address payable destAddress,
        uint256 maxDestAmount,
        uint256 minConversionRate,
        address payable platformWallet,
        uint256 platformFeeBps,
        bytes calldata hint
    ) external payable returns (uint256 destAmount);

    function trade(
        IERC20 src,
        uint256 srcAmount,
        IERC20 dest,
        address payable destAddress,
        uint256 maxDestAmount,
        uint256 minConversionRate,
        address payable platformWallet
    ) external payable returns (uint256);

    /// @notice backward compatible
    /// @notice Rate units (10 ** 18) => destQty (twei) / srcQty (twei) * 10 ** 18
    function getExpectedRate(
        ERC20 src,
        ERC20 dest,
        uint256 srcQty
    ) external view returns (uint256 expectedRate, uint256 worstRate);

    function getExpectedRateAfterFee(
        IERC20 src,
        IERC20 dest,
        uint256 srcQty,
        uint256 platformFeeBps,
        bytes calldata hint
    ) external view returns (uint256 expectedRate);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;

interface IEpochUtils {
    function epochPeriodInSeconds() external view returns (uint256);

    function firstEpochStartTimestamp() external view returns (uint256);

    function getCurrentEpochNumber() external view returns (uint256);

    function getEpochNumber(uint256 timestamp) external view returns (uint256);
}