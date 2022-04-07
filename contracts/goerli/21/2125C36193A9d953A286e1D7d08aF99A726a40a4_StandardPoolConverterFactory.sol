// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;
import "./StandardPoolConverter.sol";
import "../../interfaces/IConverter.sol";
import "../../interfaces/ITypedConverterFactory.sol";
import "../../../token/interfaces/IDSToken.sol";

/**
 * @dev StandardPoolConverter Factory
 */
contract StandardPoolConverterFactory is ITypedConverterFactory {
    /**
     * @dev returns the converter type the factory is associated with
     */
    function converterType() external pure override returns (uint16) {
        return 3;
    }

    /**
     * @dev creates a new converter with the given arguments and transfers the ownership to the caller
     */
    function createConverter(
        IConverterAnchor anchor,
        IContractRegistry registry,
        uint32 maxConversionFee
    ) external virtual override returns (IConverter) {
        IConverter converter = new StandardPoolConverter(IDSToken(address(anchor)), registry, maxConversionFee);
        converter.transferOwnership(msg.sender);

        return converter;
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "../../ConverterVersion.sol";
import "../../interfaces/IConverter.sol";
import "../../interfaces/IConverterAnchor.sol";
import "../../interfaces/IConverterUpgrader.sol";

import "../../../utility/MathEx.sol";
import "../../../utility/ContractRegistryClient.sol";
import "../../../utility/Time.sol";

import "../../../token/interfaces/IDSToken.sol";
import "../../../token/ReserveToken.sol";

import "../../../INetworkSettings.sol";

/**
 * @dev This contract is a specialized version of the converter, which is optimized for a liquidity pool that has 2
 * reserves with 50%/50% weights
 */
contract StandardPoolConverter is ConverterVersion, IConverter, ContractRegistryClient, ReentrancyGuard, Time {
    using SafeMath for uint256;
    using ReserveToken for IReserveToken;
    using SafeERC20 for IERC20;
    using MathEx for *;

    uint256 private constant MAX_UINT128 = 2**128 - 1;
    uint256 private constant MAX_UINT112 = 2**112 - 1;
    uint256 private constant MAX_UINT32 = 2**32 - 1;
    uint256 private constant AVERAGE_RATE_PERIOD = 10 minutes;

    uint256 private _reserveBalances;
    uint256 private _reserveBalancesProduct;
    IReserveToken[] private _reserveTokens;
    mapping(IReserveToken => uint256) private _reserveIds;

    IConverterAnchor private _anchor; // converter anchor contract
    uint32 private _maxConversionFee; // maximum conversion fee, represented in ppm, 0...1000000
    uint32 private _conversionFee; // current conversion fee, represented in ppm, 0...maxConversionFee

    // average rate details:
    // bits 0...111 represent the numerator of the rate between reserve token 0 and reserve token 1
    // bits 111...223 represent the denominator of the rate between reserve token 0 and reserve token 1
    // bits 224...255 represent the update-time of the rate between reserve token 0 and reserve token 1
    // where `numerator / denominator` gives the worth of one reserve token 0 in units of reserve token 1
    uint256 private _averageRateInfo;

    /**
     * @dev triggered after liquidity is added
     */
    event LiquidityAdded(
        address indexed provider,
        IReserveToken indexed reserveToken,
        uint256 amount,
        uint256 newBalance,
        uint256 newSupply
    );

    /**
     * @dev triggered after liquidity is removed
     */
    event LiquidityRemoved(
        address indexed provider,
        IReserveToken indexed reserveToken,
        uint256 amount,
        uint256 newBalance,
        uint256 newSupply
    );

    /**
     * @dev initializes a new StandardPoolConverter instance
     */
    constructor(
        IConverterAnchor anchor,
        IContractRegistry registry,
        uint32 maxConversionFee
    ) public ContractRegistryClient(registry) validAddress(address(anchor)) validConversionFee(maxConversionFee) {
        _anchor = anchor;
        _maxConversionFee = maxConversionFee;
    }

    // ensures that the converter is active
    modifier active() {
        _active();

        _;
    }

    // error message binary size optimization
    function _active() private view {
        require(isActive(), "ERR_INACTIVE");
    }

    // ensures that the converter is not active
    modifier inactive() {
        _inactive();

        _;
    }

    // error message binary size optimization
    function _inactive() private view {
        require(!isActive(), "ERR_ACTIVE");
    }

    // validates a reserve token address - verifies that the address belongs to one of the reserve tokens
    modifier validReserve(IReserveToken reserveToken) {
        _validReserve(reserveToken);

        _;
    }

    // error message binary size optimization
    function _validReserve(IReserveToken reserveToken) private view {
        require(_reserveIds[reserveToken] != 0, "ERR_INVALID_RESERVE");
    }

    // validates conversion fee
    modifier validConversionFee(uint32 fee) {
        _validConversionFee(fee);

        _;
    }

    // error message binary size optimization
    function _validConversionFee(uint32 fee) private pure {
        require(fee <= PPM_RESOLUTION, "ERR_INVALID_CONVERSION_FEE");
    }

    // validates reserve weight
    modifier validReserveWeight(uint32 weight) {
        _validReserveWeight(weight);

        _;
    }

    // error message binary size optimization
    function _validReserveWeight(uint32 weight) private pure {
        require(weight == PPM_RESOLUTION / 2, "ERR_INVALID_RESERVE_WEIGHT");
    }

    /**
     * @dev returns the converter type
     */
    function converterType() public pure virtual override returns (uint16) {
        return 3;
    }

    /**
     * @dev checks whether or not the converter version is 28 or higher
     */
    function isV28OrHigher() external pure returns (bool) {
        return true;
    }

    /**
     * @dev returns the converter anchor
     */
    function anchor() external view override returns (IConverterAnchor) {
        return _anchor;
    }

    /**
     * @dev returns the maximum conversion fee (in units of PPM)
     */
    function maxConversionFee() external view override returns (uint32) {
        return _maxConversionFee;
    }

    /**
     * @dev returns the current conversion fee (in units of PPM)
     */
    function conversionFee() external view override returns (uint32) {
        return _conversionFee;
    }

    /**
     * @dev returns the average rate info
     */
    function averageRateInfo() external view returns (uint256) {
        return _averageRateInfo;
    }

    /**
     * @dev deposits ether
     *
     * Requirements:
     *
     * - can only be used if the converter has an ETH reserve
     */
    receive() external payable override(IConverter) validReserve(ReserveToken.NATIVE_TOKEN_ADDRESS) {}

    /**
     * @dev returns true if the converter is active, false otherwise
     */
    function isActive() public view virtual override returns (bool) {
        return _anchor.owner() == address(this);
    }

    /**
     * @dev transfers the anchor ownership
     *
     * Requirements:
     *
     * - the new owner needs to accept the transfer
     * - can only be called by the converter upgrader while the upgrader is the owner
     *
     * note that prior to version 28, you should use 'transferAnchorOwnership' instead
     */
    function transferAnchorOwnership(address newOwner) public override ownerOnly only(CONVERTER_UPGRADER) {
        _anchor.transferOwnership(newOwner);
    }

    /**
     * @dev accepts ownership of the anchor after an ownership transfer
     *
     * Requirements:
     *
     * - most converters are also activated as soon as they accept the anchor ownership
     * - the caller must be the owner of the contract
     *
     * note that prior to version 28, you should use 'acceptTokenOwnership' instead
     */
    function acceptAnchorOwnership() public virtual override ownerOnly {
        require(_reserveTokens.length == 2, "ERR_INVALID_RESERVE_COUNT");

        _anchor.acceptOwnership();

        _syncReserveBalances(0);

        emit Activation(converterType(), _anchor, true);
    }

    /**
     * @dev updates the current conversion fee
     *
     * Requirements:
     *
     * - the caller must be the owner of the contract
     */
    function setConversionFee(uint32 fee) external override ownerOnly {
        require(fee <= _maxConversionFee, "ERR_INVALID_CONVERSION_FEE");

        emit ConversionFeeUpdate(_conversionFee, fee);

        _conversionFee = fee;
    }

    /**
     * @dev transfers reserve balances to a new converter during an upgrade
     *
     * Requirements:
     *
     * - can only be called by the converter upgrader which should have been set at its owner
     */
    function transferReservesOnUpgrade(address newConverter)
        external
        override
        nonReentrant
        ownerOnly
        only(CONVERTER_UPGRADER)
    {
        uint256 reserveCount = _reserveTokens.length;
        for (uint256 i = 0; i < reserveCount; ++i) {
            IReserveToken reserveToken = _reserveTokens[i];

            reserveToken.safeTransfer(newConverter, reserveToken.balanceOf(address(this)));

            _syncReserveBalance(reserveToken);
        }
    }

    /**
     * @dev upgrades the converter to the latest version
     *
     * Requirements:
     *
     * - the caller must be the owner of the contract
     *
     * note that the owner needs to call acceptOwnership on the new converter after the upgrade
     */
    function upgrade() external ownerOnly {
        IConverterUpgrader converterUpgrader = IConverterUpgrader(_addressOf(CONVERTER_UPGRADER));

        // trigger de-activation event
        emit Activation(converterType(), _anchor, false);

        transferOwnership(address(converterUpgrader));
        converterUpgrader.upgrade(version);
        acceptOwnership();
    }

    /**
     * @dev executed by the upgrader at the end of the upgrade process to handle custom pool logic
     */
    function onUpgradeComplete() external override nonReentrant ownerOnly only(CONVERTER_UPGRADER) {
        (uint256 reserveBalance0, uint256 reserveBalance1) = _loadReserveBalances(1, 2);
        _reserveBalancesProduct = reserveBalance0 * reserveBalance1;
    }

    /**
     * @dev returns the number of reserve tokens
     *
     * note that prior to version 17, you should use 'connectorTokenCount' instead
     */
    function reserveTokenCount() public view override returns (uint16) {
        return uint16(_reserveTokens.length);
    }

    /**
     * @dev returns the array of reserve tokens
     */
    function reserveTokens() external view override returns (IReserveToken[] memory) {
        return _reserveTokens;
    }

    /**
     * @dev defines a new reserve token for the converter
     *
     * Requirements:
     *
     * - the caller must be the owner of the contract
     * - the converter must be inactive
     */
    function addReserve(IReserveToken token, uint32 weight)
        external
        virtual
        override
        ownerOnly
        inactive
        validExternalAddress(address(token))
        validReserveWeight(weight)
    {
        require(address(token) != address(_anchor) && _reserveIds[token] == 0, "ERR_INVALID_RESERVE");
        require(reserveTokenCount() < 2, "ERR_INVALID_RESERVE_COUNT");

        _reserveTokens.push(token);
        _reserveIds[token] = _reserveTokens.length;
    }

    /**
     * @dev returns the reserve's weight
     */
    function reserveWeight(IReserveToken reserveToken) external view validReserve(reserveToken) returns (uint32) {
        return PPM_RESOLUTION / 2;
    }

    /**
     * @dev returns the balance of a given reserve token
     */
    function reserveBalance(IReserveToken reserveToken) public view override returns (uint256) {
        uint256 reserveId = _reserveIds[reserveToken];
        require(reserveId != 0, "ERR_INVALID_RESERVE");

        return _reserveBalance(reserveId);
    }

    /**
     * @dev returns the balances of both reserve tokens
     */
    function reserveBalances() public view returns (uint256, uint256) {
        return _loadReserveBalances(1, 2);
    }

    /**
     * @dev syncs all stored reserve balances
     */
    function syncReserveBalances() external {
        _syncReserveBalances(0);
    }

    /**
     * @dev calculates the accumulated network fee and transfers it to the network fee wallet
     */
    function processNetworkFees() external nonReentrant {
        (uint256 reserveBalance0, uint256 reserveBalance1) = _processNetworkFees(0);
        _reserveBalancesProduct = reserveBalance0 * reserveBalance1;
    }

    /**
     * @dev calculates the accumulated network fee and transfers it to the network fee wallet
     */
    function _processNetworkFees(uint256 value) private returns (uint256, uint256) {
        _syncReserveBalances(value);
        (uint256 reserveBalance0, uint256 reserveBalance1) = _loadReserveBalances(1, 2);
        (ITokenHolder wallet, uint256 fee0, uint256 fee1) = _networkWalletAndFees(reserveBalance0, reserveBalance1);
        reserveBalance0 -= fee0;
        reserveBalance1 -= fee1;

        _setReserveBalances(1, 2, reserveBalance0, reserveBalance1);

        _reserveTokens[0].safeTransfer(address(wallet), fee0);
        _reserveTokens[1].safeTransfer(address(wallet), fee1);

        return (reserveBalance0, reserveBalance1);
    }

    /**
     * @dev returns the reserve balances of the given reserve tokens minus their corresponding fees
     */
    function _baseReserveBalances(IReserveToken[] memory baseReserveTokens) private view returns (uint256[2] memory) {
        uint256 reserveId0 = _reserveIds[baseReserveTokens[0]];
        uint256 reserveId1 = _reserveIds[baseReserveTokens[1]];
        (uint256 reserveBalance0, uint256 reserveBalance1) = _loadReserveBalances(reserveId0, reserveId1);
        (, uint256 fee0, uint256 fee1) = _networkWalletAndFees(reserveBalance0, reserveBalance1);

        return [reserveBalance0 - fee0, reserveBalance1 - fee1];
    }

    /**
     * @dev converts a specific amount of source tokens to target tokens
     *
     * Requirements:
     *
     * - the caller must be the bancor network contract
     */
    function convert(
        IReserveToken sourceToken,
        IReserveToken targetToken,
        uint256 sourceAmount,
        address trader,
        address payable beneficiary
    ) external payable override nonReentrant only(BANCOR_NETWORK) returns (uint256) {
        require(sourceToken != targetToken, "ERR_SAME_SOURCE_TARGET");

        return _doConvert(sourceToken, targetToken, sourceAmount, trader, beneficiary);
    }

    /**
     * @dev returns the conversion fee for a given target amount
     */
    function _calculateFee(uint256 targetAmount) private view returns (uint256) {
        return targetAmount.mul(_conversionFee) / PPM_RESOLUTION;
    }

    /**
     * @dev returns the conversion fee taken from a given target amount
     */
    function _calculateFeeInv(uint256 targetAmount) private view returns (uint256) {
        return targetAmount.mul(_conversionFee).div(PPM_RESOLUTION - _conversionFee);
    }

    /**
     * @dev loads the stored reserve balance for a given reserve id
     */
    function _reserveBalance(uint256 reserveId) private view returns (uint256) {
        return _decodeReserveBalance(_reserveBalances, reserveId);
    }

    /**
     * @dev loads the stored reserve balances
     */
    function _loadReserveBalances(uint256 sourceId, uint256 targetId) private view returns (uint256, uint256) {
        require((sourceId == 1 && targetId == 2) || (sourceId == 2 && targetId == 1), "ERR_INVALID_RESERVES");

        return _decodeReserveBalances(_reserveBalances, sourceId, targetId);
    }

    /**
     * @dev stores the stored reserve balance for a given reserve id
     */
    function _setReserveBalance(uint256 reserveId, uint256 balance) private {
        require(balance <= MAX_UINT128, "ERR_RESERVE_BALANCE_OVERFLOW");

        uint256 otherBalance = _decodeReserveBalance(_reserveBalances, 3 - reserveId);
        _reserveBalances = _encodeReserveBalances(balance, reserveId, otherBalance, 3 - reserveId);
    }

    /**
     * @dev stores the stored reserve balances
     */
    function _setReserveBalances(
        uint256 sourceId,
        uint256 targetId,
        uint256 sourceBalance,
        uint256 targetBalance
    ) private {
        require(sourceBalance <= MAX_UINT128 && targetBalance <= MAX_UINT128, "ERR_RESERVE_BALANCE_OVERFLOW");

        _reserveBalances = _encodeReserveBalances(sourceBalance, sourceId, targetBalance, targetId);
    }

    /**
     * @dev syncs the stored reserve balance for a given reserve with the real reserve balance
     */
    function _syncReserveBalance(IReserveToken reserveToken) private {
        uint256 reserveId = _reserveIds[reserveToken];

        _setReserveBalance(reserveId, reserveToken.balanceOf(address(this)));
    }

    /**
     * @dev syncs all stored reserve balances, excluding a given amount of ether from the ether reserve balance (if relevant)
     */
    function _syncReserveBalances(uint256 value) private {
        IReserveToken _reserveToken0 = _reserveTokens[0];
        IReserveToken _reserveToken1 = _reserveTokens[1];
        uint256 balance0 = _reserveToken0.balanceOf(address(this)) - (_reserveToken0.isNativeToken() ? value : 0);
        uint256 balance1 = _reserveToken1.balanceOf(address(this)) - (_reserveToken1.isNativeToken() ? value : 0);

        _setReserveBalances(1, 2, balance0, balance1);
    }

    /**
     * @dev helper, dispatches the Conversion event
     */
    function _dispatchConversionEvent(
        IReserveToken sourceToken,
        IReserveToken targetToken,
        address trader,
        uint256 sourceAmount,
        uint256 targetAmount,
        uint256 feeAmount
    ) private {
        emit Conversion(sourceToken, targetToken, trader, sourceAmount, targetAmount, int256(feeAmount));
    }

    /**
     * @dev returns the expected amount and expected fee for converting one reserve to another
     */
    function targetAmountAndFee(
        IReserveToken sourceToken,
        IReserveToken targetToken,
        uint256 sourceAmount
    ) public view virtual override active returns (uint256, uint256) {
        uint256 sourceId = _reserveIds[sourceToken];
        uint256 targetId = _reserveIds[targetToken];

        (uint256 sourceBalance, uint256 targetBalance) = _loadReserveBalances(sourceId, targetId);

        return _targetAmountAndFee(sourceToken, targetToken, sourceBalance, targetBalance, sourceAmount);
    }

    /**
     * @dev returns the expected amount and expected fee for converting one reserve to another
     */
    function _targetAmountAndFee(
        IReserveToken, /* sourceToken */
        IReserveToken, /* targetToken */
        uint256 sourceBalance,
        uint256 targetBalance,
        uint256 sourceAmount
    ) private view returns (uint256, uint256) {
        uint256 targetAmount = _crossReserveTargetAmount(sourceBalance, targetBalance, sourceAmount);

        uint256 fee = _calculateFee(targetAmount);

        return (targetAmount - fee, fee);
    }

    /**
     * @dev returns the required amount and expected fee for converting one reserve to another
     */
    function sourceAmountAndFee(
        IReserveToken sourceToken,
        IReserveToken targetToken,
        uint256 targetAmount
    ) public view virtual active returns (uint256, uint256) {
        uint256 sourceId = _reserveIds[sourceToken];
        uint256 targetId = _reserveIds[targetToken];

        (uint256 sourceBalance, uint256 targetBalance) = _loadReserveBalances(sourceId, targetId);

        uint256 fee = _calculateFeeInv(targetAmount);

        uint256 sourceAmount = _crossReserveSourceAmount(sourceBalance, targetBalance, targetAmount.add(fee));

        return (sourceAmount, fee);
    }

    /**
     * @dev converts a specific amount of source tokens to target tokens and returns the amount of tokens received
     * (in units of the target token)
     */
    function _doConvert(
        IReserveToken sourceToken,
        IReserveToken targetToken,
        uint256 sourceAmount,
        address trader,
        address payable beneficiary
    ) private returns (uint256) {
        // update the recent average rate
        _updateRecentAverageRate();

        uint256 sourceId = _reserveIds[sourceToken];
        uint256 targetId = _reserveIds[targetToken];

        (uint256 sourceBalance, uint256 targetBalance) = _loadReserveBalances(sourceId, targetId);

        // get the target amount minus the conversion fee and the conversion fee
        (uint256 targetAmount, uint256 fee) = _targetAmountAndFee(
            sourceToken,
            targetToken,
            sourceBalance,
            targetBalance,
            sourceAmount
        );

        // ensure that the trade gives something in return
        require(targetAmount != 0, "ERR_ZERO_TARGET_AMOUNT");

        // ensure that the trade won't deplete the reserve balance
        assert(targetAmount < targetBalance);

        // ensure that the input amount was already deposited
        uint256 actualSourceBalance = sourceToken.balanceOf(address(this));
        if (sourceToken.isNativeToken()) {
            require(msg.value == sourceAmount, "ERR_ETH_AMOUNT_MISMATCH");
        } else {
            require(msg.value == 0 && actualSourceBalance.sub(sourceBalance) >= sourceAmount, "ERR_INVALID_AMOUNT");
        }

        // sync the reserve balances
        _setReserveBalances(sourceId, targetId, actualSourceBalance, targetBalance - targetAmount);

        // transfer funds to the beneficiary in the to reserve token
        targetToken.safeTransfer(beneficiary, targetAmount);

        // dispatch the conversion event
        _dispatchConversionEvent(sourceToken, targetToken, trader, sourceAmount, targetAmount, fee);

        // dispatch rate updates
        _dispatchTokenRateUpdateEvents(sourceToken, targetToken, actualSourceBalance, targetBalance - targetAmount);

        return targetAmount;
    }

    /**
     * @dev returns the recent average rate of 1 token in the other reserve token units
     */
    function recentAverageRate(IReserveToken token) external view validReserve(token) returns (uint256, uint256) {
        // get the recent average rate of reserve 0
        uint256 rate = _calcRecentAverageRate(_averageRateInfo);

        uint256 rateN = _decodeAverageRateN(rate);
        uint256 rateD = _decodeAverageRateD(rate);

        if (token == _reserveTokens[0]) {
            return (rateN, rateD);
        }

        return (rateD, rateN);
    }

    /**
     * @dev updates the recent average rate if needed
     */
    function _updateRecentAverageRate() private {
        uint256 averageRateInfo1 = _averageRateInfo;
        uint256 averageRateInfo2 = _calcRecentAverageRate(averageRateInfo1);
        if (averageRateInfo1 != averageRateInfo2) {
            _averageRateInfo = averageRateInfo2;
        }
    }

    /**
     * @dev returns the recent average rate of 1 reserve token 0 in reserve token 1 units
     */
    function _calcRecentAverageRate(uint256 averageRateInfoData) private view returns (uint256) {
        // get the previous average rate and its update-time
        uint256 prevAverageRateT = _decodeAverageRateT(averageRateInfoData);
        uint256 prevAverageRateN = _decodeAverageRateN(averageRateInfoData);
        uint256 prevAverageRateD = _decodeAverageRateD(averageRateInfoData);

        // get the elapsed time since the previous average rate was calculated
        uint256 currentTime = _time();
        uint256 timeElapsed = currentTime.sub(prevAverageRateT);

        // if the previous average rate was calculated in the current block, the average rate remains unchanged
        if (timeElapsed == 0) {
            return averageRateInfoData;
        }

        // get the current rate between the reserves
        (uint256 currentRateD, uint256 currentRateN) = reserveBalances();

        // if the previous average rate was calculated a while ago or never, the average rate is equal to the current rate
        if (timeElapsed >= AVERAGE_RATE_PERIOD || prevAverageRateT == 0) {
            (currentRateN, currentRateD) = MathEx.reducedRatio(currentRateN, currentRateD, MAX_UINT112);
            return _encodeAverageRateInfo(currentTime, currentRateN, currentRateD);
        }

        uint256 x = prevAverageRateD.mul(currentRateN);
        uint256 y = prevAverageRateN.mul(currentRateD);

        // since we know that timeElapsed < AVERAGE_RATE_PERIOD, we can avoid using SafeMath:
        uint256 newRateN = y.mul(AVERAGE_RATE_PERIOD - timeElapsed).add(x.mul(timeElapsed));
        uint256 newRateD = prevAverageRateD.mul(currentRateD).mul(AVERAGE_RATE_PERIOD);

        (newRateN, newRateD) = MathEx.reducedRatio(newRateN, newRateD, MAX_UINT112);

        return _encodeAverageRateInfo(currentTime, newRateN, newRateD);
    }

    /**
     * @dev increases the pool's liquidity and mints new shares in the pool to the caller and returns the amount of pool
     * tokens issued
     */
    function addLiquidity(
        IReserveToken[] memory reserves,
        uint256[] memory reserveAmounts,
        uint256 minReturn
    ) external payable nonReentrant active returns (uint256) {
        _verifyLiquidityInput(reserves, reserveAmounts, minReturn);

        // if one of the reserves is ETH, then verify that the input amount of ETH is equal to the input value of ETH
        require(
            (!reserves[0].isNativeToken() || reserveAmounts[0] == msg.value) &&
                (!reserves[1].isNativeToken() || reserveAmounts[1] == msg.value),
            "ERR_ETH_AMOUNT_MISMATCH"
        );

        // if the input value of ETH is larger than zero, then verify that one of the reserves is ETH
        if (msg.value > 0) {
            require(_reserveIds[ReserveToken.NATIVE_TOKEN_ADDRESS] != 0, "ERR_NO_ETH_RESERVE");
        }

        // save a local copy of the pool token
        IDSToken poolToken = IDSToken(address(_anchor));

        // get the total supply
        uint256 totalSupply = poolToken.totalSupply();

        uint256[2] memory prevReserveBalances;
        uint256[2] memory newReserveBalances;

        // process the network fees and get the reserve balances
        (prevReserveBalances[0], prevReserveBalances[1]) = _processNetworkFees(msg.value);

        uint256 amount;
        uint256[2] memory newReserveAmounts;

        // calculate the amount of pool tokens to mint for the caller
        // and the amount of reserve tokens to transfer from the caller
        if (totalSupply == 0) {
            amount = MathEx.geometricMean(reserveAmounts);
            newReserveAmounts[0] = reserveAmounts[0];
            newReserveAmounts[1] = reserveAmounts[1];
        } else {
            (amount, newReserveAmounts) = _addLiquidityAmounts(
                reserves,
                reserveAmounts,
                prevReserveBalances,
                totalSupply
            );
        }

        uint256 newPoolTokenSupply = totalSupply.add(amount);
        for (uint256 i = 0; i < 2; i++) {
            IReserveToken reserveToken = reserves[i];
            uint256 reserveAmount = newReserveAmounts[i];
            require(reserveAmount > 0, "ERR_ZERO_TARGET_AMOUNT");
            assert(reserveAmount <= reserveAmounts[i]);

            // transfer each one of the reserve amounts from the user to the pool
            if (!reserveToken.isNativeToken()) {
                // ETH has already been transferred as part of the transaction
                reserveToken.safeTransferFrom(msg.sender, address(this), reserveAmount);
            } else if (reserveAmounts[i] > reserveAmount) {
                // transfer the extra amount of ETH back to the user
                reserveToken.safeTransfer(msg.sender, reserveAmounts[i] - reserveAmount);
            }

            // save the new reserve balance
            newReserveBalances[i] = prevReserveBalances[i].add(reserveAmount);

            emit LiquidityAdded(msg.sender, reserveToken, reserveAmount, newReserveBalances[i], newPoolTokenSupply);

            // dispatch the `TokenRateUpdate` event for the pool token
            emit TokenRateUpdate(address(poolToken), address(reserveToken), newReserveBalances[i], newPoolTokenSupply);
        }

        // set the reserve balances
        _setReserveBalances(1, 2, newReserveBalances[0], newReserveBalances[1]);

        // set the reserve balances product
        _reserveBalancesProduct = newReserveBalances[0] * newReserveBalances[1];

        // verify that the equivalent amount of tokens is equal to or larger than the user's expectation
        require(amount >= minReturn, "ERR_RETURN_TOO_LOW");

        // issue the tokens to the user
        poolToken.issue(msg.sender, amount);

        // return the amount of pool tokens issued
        return amount;
    }

    /**
     * @dev get the amount of pool tokens to mint for the caller and the amount of reserve tokens to transfer from
     * the caller
     */
    function _addLiquidityAmounts(
        IReserveToken[] memory, /* reserves */
        uint256[] memory amounts,
        uint256[2] memory balances,
        uint256 totalSupply
    ) private pure returns (uint256, uint256[2] memory) {
        uint256 index = amounts[0].mul(balances[1]) < amounts[1].mul(balances[0]) ? 0 : 1;
        uint256 amount = _fundSupplyAmount(totalSupply, balances[index], amounts[index]);

        uint256[2] memory newAmounts = [
            _fundCost(totalSupply, balances[0], amount),
            _fundCost(totalSupply, balances[1], amount)
        ];

        return (amount, newAmounts);
    }

    /**
     * @dev decreases the pool's liquidity and burns the caller's shares in the pool and returns the amount of each
     * reserve token granted for the given amount of pool tokens
     */
    function removeLiquidity(
        uint256 amount,
        IReserveToken[] memory reserves,
        uint256[] memory minReturnAmounts
    ) external nonReentrant active returns (uint256[] memory) {
        // verify the user input
        bool inputRearranged = _verifyLiquidityInput(reserves, minReturnAmounts, amount);

        // save a local copy of the pool token
        IDSToken poolToken = IDSToken(address(_anchor));

        // get the total supply BEFORE destroying the user tokens
        uint256 totalSupply = poolToken.totalSupply();

        // destroy the user tokens
        poolToken.destroy(msg.sender, amount);

        uint256 newPoolTokenSupply = totalSupply.sub(amount);

        uint256[2] memory prevReserveBalances;
        uint256[2] memory newReserveBalances;

        // process the network fees and get the reserve balances
        (prevReserveBalances[0], prevReserveBalances[1]) = _processNetworkFees(0);

        uint256[] memory reserveAmounts = _removeLiquidityReserveAmounts(amount, totalSupply, prevReserveBalances);

        for (uint256 i = 0; i < 2; i++) {
            IReserveToken reserveToken = reserves[i];
            uint256 reserveAmount = reserveAmounts[i];
            require(reserveAmount >= minReturnAmounts[i], "ERR_ZERO_TARGET_AMOUNT");

            // save the new reserve balance
            newReserveBalances[i] = prevReserveBalances[i].sub(reserveAmount);

            // transfer each one of the reserve amounts from the pool to the user
            reserveToken.safeTransfer(msg.sender, reserveAmount);

            emit LiquidityRemoved(msg.sender, reserveToken, reserveAmount, newReserveBalances[i], newPoolTokenSupply);

            // dispatch the `TokenRateUpdate` event for the pool token
            emit TokenRateUpdate(address(poolToken), address(reserveToken), newReserveBalances[i], newPoolTokenSupply);
        }

        // set the reserve balances
        _setReserveBalances(1, 2, newReserveBalances[0], newReserveBalances[1]);

        // set the reserve balances product
        _reserveBalancesProduct = newReserveBalances[0] * newReserveBalances[1];

        if (inputRearranged) {
            uint256 tempReserveAmount = reserveAmounts[0];
            reserveAmounts[0] = reserveAmounts[1];
            reserveAmounts[1] = tempReserveAmount;
        }

        // return the amount of each reserve token granted for the given amount of pool tokens
        return reserveAmounts;
    }

    /**
     * @dev given the amount of one of the reserve tokens to add liquidity of, returns the required amount of each one
     * of the other reserve tokens since an empty pool can be funded with any list of non-zero input amounts
     *
     * Requirements:
     *
     * - this function assumes that the pool is not empty (has already been funded)
     */
    function addLiquidityCost(
        IReserveToken[] memory reserves,
        uint256 index,
        uint256 amount
    ) external view returns (uint256[] memory) {
        uint256 totalSupply = IDSToken(address(_anchor)).totalSupply();
        uint256[2] memory baseBalances = _baseReserveBalances(reserves);
        uint256 supplyAmount = _fundSupplyAmount(totalSupply, baseBalances[index], amount);

        uint256[] memory reserveAmounts = new uint256[](2);
        reserveAmounts[0] = _fundCost(totalSupply, baseBalances[0], supplyAmount);
        reserveAmounts[1] = _fundCost(totalSupply, baseBalances[1], supplyAmount);

        return reserveAmounts;
    }

    /**
     * @dev returns the amount of pool tokens entitled for given amounts of reserve tokens
     *
     * Requirements:
     *
     * - since an empty pool can be funded with any list of non-zero input amounts, this function assumes that the pool
     * is not empty (has already been funded)
     */
    function addLiquidityReturn(IReserveToken[] memory reserves, uint256[] memory amounts)
        external
        view
        returns (uint256)
    {
        uint256 totalSupply = IDSToken(address(_anchor)).totalSupply();
        uint256[2] memory baseBalances = _baseReserveBalances(reserves);
        (uint256 amount, ) = _addLiquidityAmounts(reserves, amounts, baseBalances, totalSupply);

        return amount;
    }

    /**
     * @dev returns the amount of each reserve token entitled for a given amount of pool tokens
     */
    function removeLiquidityReturn(uint256 amount, IReserveToken[] memory reserves)
        external
        view
        returns (uint256[] memory)
    {
        uint256 totalSupply = IDSToken(address(_anchor)).totalSupply();
        uint256[2] memory baseBalances = _baseReserveBalances(reserves);

        return _removeLiquidityReserveAmounts(amount, totalSupply, baseBalances);
    }

    /**
     * @dev verifies that a given array of tokens is identical to the converter's array of reserve tokens
     * note that we take this input in order to allow specifying the corresponding reserve amounts in any order and that
     * this function rearranges the input arrays according to the converter's array of reserve tokens
     */
    function _verifyLiquidityInput(
        IReserveToken[] memory reserves,
        uint256[] memory amounts,
        uint256 amount
    ) private view returns (bool) {
        require(_validReserveAmounts(amounts) && amount > 0, "ERR_ZERO_AMOUNT");

        uint256 reserve0Id = _reserveIds[reserves[0]];
        uint256 reserve1Id = _reserveIds[reserves[1]];

        if (reserve0Id == 2 && reserve1Id == 1) {
            IReserveToken tempReserveToken = reserves[0];
            reserves[0] = reserves[1];
            reserves[1] = tempReserveToken;

            uint256 tempReserveAmount = amounts[0];
            amounts[0] = amounts[1];
            amounts[1] = tempReserveAmount;

            return true;
        }

        require(reserve0Id == 1 && reserve1Id == 2, "ERR_INVALID_RESERVE");

        return false;
    }

    /**
     * @dev checks whether or not both reserve amounts are larger than zero
     */
    function _validReserveAmounts(uint256[] memory amounts) private pure returns (bool) {
        return amounts[0] > 0 && amounts[1] > 0;
    }

    /**
     * @dev returns the amount of each reserve token entitled for a given amount of pool tokens
     */
    function _removeLiquidityReserveAmounts(
        uint256 amount,
        uint256 totalSupply,
        uint256[2] memory balances
    ) private pure returns (uint256[] memory) {
        uint256[] memory reserveAmounts = new uint256[](2);
        reserveAmounts[0] = _liquidateReserveAmount(totalSupply, balances[0], amount);
        reserveAmounts[1] = _liquidateReserveAmount(totalSupply, balances[1], amount);

        return reserveAmounts;
    }

    /**
     * @dev dispatches token rate update events for the reserve tokens and the pool token
     */
    function _dispatchTokenRateUpdateEvents(
        IReserveToken sourceToken,
        IReserveToken targetToken,
        uint256 sourceBalance,
        uint256 targetBalance
    ) private {
        // save a local copy of the pool token
        IDSToken poolToken = IDSToken(address(_anchor));

        // get the total supply of pool tokens
        uint256 poolTokenSupply = poolToken.totalSupply();

        // dispatch token rate update event for the reserve tokens
        emit TokenRateUpdate(address(sourceToken), address(targetToken), targetBalance, sourceBalance);

        // dispatch token rate update events for the pool token
        emit TokenRateUpdate(address(poolToken), address(sourceToken), sourceBalance, poolTokenSupply);
        emit TokenRateUpdate(address(poolToken), address(targetToken), targetBalance, poolTokenSupply);
    }

    function _encodeReserveBalance(uint256 balance, uint256 id) private pure returns (uint256) {
        assert(balance <= MAX_UINT128 && (id == 1 || id == 2));
        return balance << ((id - 1) * 128);
    }

    function _decodeReserveBalance(uint256 balances, uint256 id) private pure returns (uint256) {
        assert(id == 1 || id == 2);
        return (balances >> ((id - 1) * 128)) & MAX_UINT128;
    }

    function _encodeReserveBalances(
        uint256 balance0,
        uint256 id0,
        uint256 balance1,
        uint256 id1
    ) private pure returns (uint256) {
        return _encodeReserveBalance(balance0, id0) | _encodeReserveBalance(balance1, id1);
    }

    function _decodeReserveBalances(
        uint256 balances,
        uint256 id0,
        uint256 id1
    ) private pure returns (uint256, uint256) {
        return (_decodeReserveBalance(balances, id0), _decodeReserveBalance(balances, id1));
    }

    function _encodeAverageRateInfo(
        uint256 averageRateT,
        uint256 averageRateN,
        uint256 averageRateD
    ) private pure returns (uint256) {
        assert(averageRateT <= MAX_UINT32 && averageRateN <= MAX_UINT112 && averageRateD <= MAX_UINT112);
        return (averageRateT << 224) | (averageRateN << 112) | averageRateD;
    }

    function _decodeAverageRateT(uint256 averageRateInfoData) private pure returns (uint256) {
        return averageRateInfoData >> 224;
    }

    function _decodeAverageRateN(uint256 averageRateInfoData) private pure returns (uint256) {
        return (averageRateInfoData >> 112) & MAX_UINT112;
    }

    function _decodeAverageRateD(uint256 averageRateInfoData) private pure returns (uint256) {
        return averageRateInfoData & MAX_UINT112;
    }

    /**
     * @dev returns the largest integer smaller than or equal to the square root of a given value
     */
    function _floorSqrt(uint256 x) private pure returns (uint256) {
        return x > 0 ? MathEx.floorSqrt(x) : 0;
    }

    function _crossReserveTargetAmount(
        uint256 sourceReserveBalance,
        uint256 targetReserveBalance,
        uint256 sourceAmount
    ) private pure returns (uint256) {
        require(sourceReserveBalance > 0 && targetReserveBalance > 0, "ERR_INVALID_RESERVE_BALANCE");

        return targetReserveBalance.mul(sourceAmount) / sourceReserveBalance.add(sourceAmount);
    }

    function _crossReserveSourceAmount(
        uint256 sourceReserveBalance,
        uint256 targetReserveBalance,
        uint256 targetAmount
    ) private pure returns (uint256) {
        require(sourceReserveBalance > 0, "ERR_INVALID_RESERVE_BALANCE");
        require(targetAmount < targetReserveBalance, "ERR_INVALID_AMOUNT");

        if (targetAmount == 0) {
            return 0;
        }

        return (sourceReserveBalance.mul(targetAmount) - 1) / (targetReserveBalance - targetAmount) + 1;
    }

    function _fundCost(
        uint256 supply,
        uint256 balance,
        uint256 amount
    ) private pure returns (uint256) {
        require(supply > 0, "ERR_INVALID_SUPPLY");
        require(balance > 0, "ERR_INVALID_RESERVE_BALANCE");

        // special case for 0 amount
        if (amount == 0) {
            return 0;
        }

        return (amount.mul(balance) - 1) / supply + 1;
    }

    function _fundSupplyAmount(
        uint256 supply,
        uint256 balance,
        uint256 amount
    ) private pure returns (uint256) {
        require(supply > 0, "ERR_INVALID_SUPPLY");
        require(balance > 0, "ERR_INVALID_RESERVE_BALANCE");

        // special case for 0 amount
        if (amount == 0) {
            return 0;
        }

        return amount.mul(supply) / balance;
    }

    function _liquidateReserveAmount(
        uint256 supply,
        uint256 balance,
        uint256 amount
    ) private pure returns (uint256) {
        require(supply > 0, "ERR_INVALID_SUPPLY");
        require(balance > 0, "ERR_INVALID_RESERVE_BALANCE");
        require(amount <= supply, "ERR_INVALID_AMOUNT");

        // special case for 0 amount
        if (amount == 0) {
            return 0;
        }

        // special case for liquidating the entire supply
        if (amount == supply) {
            return balance;
        }

        return amount.mul(balance) / supply;
    }

    /**
     * @dev returns the network wallet and fees
     */
    function _networkWalletAndFees(uint256 reserveBalance0, uint256 reserveBalance1)
        private
        view
        returns (
            ITokenHolder,
            uint256,
            uint256
        )
    {
        uint256 prevPoint = _floorSqrt(_reserveBalancesProduct);
        uint256 currPoint = _floorSqrt(reserveBalance0 * reserveBalance1);

        if (prevPoint >= currPoint) {
            return (ITokenHolder(address(0)), 0, 0);
        }

        (ITokenHolder networkFeeWallet, uint32 networkFee) = INetworkSettings(_addressOf(NETWORK_SETTINGS))
            .networkFeeParams();
        uint256 n = (currPoint - prevPoint) * networkFee;
        uint256 d = currPoint * PPM_RESOLUTION;

        return (networkFeeWallet, reserveBalance0.mul(n).div(d), reserveBalance1.mul(n).div(d));
    }

    /**
     * @dev deprecated since version 28, backward compatibility - use only for earlier versions
     */
    function token() external view override returns (IConverterAnchor) {
        return _anchor;
    }

    /**
     * @dev deprecated, backward compatibility
     */
    function transferTokenOwnership(address newOwner) external override ownerOnly {
        transferAnchorOwnership(newOwner);
    }

    /**
     * @dev deprecated, backward compatibility
     */
    function acceptTokenOwnership() public override ownerOnly {
        acceptAnchorOwnership();
    }

    /**
     * @dev deprecated, backward compatibility
     */
    function connectors(IReserveToken reserveToken)
        external
        view
        override
        returns (
            uint256,
            uint32,
            bool,
            bool,
            bool
        )
    {
        uint256 reserveId = _reserveIds[reserveToken];
        if (reserveId != 0) {
            return (_reserveBalance(reserveId), PPM_RESOLUTION / 2, false, false, true);
        }
        return (0, 0, false, false, false);
    }

    /**
     * @dev deprecated, backward compatibility
     */
    function connectorTokens(uint256 index) external view override returns (IReserveToken) {
        return _reserveTokens[index];
    }

    /**
     * @dev deprecated, backward compatibility
     */
    function connectorTokenCount() external view override returns (uint16) {
        return reserveTokenCount();
    }

    /**
     * @dev deprecated, backward compatibility
     */
    function getConnectorBalance(IReserveToken reserveToken) external view override returns (uint256) {
        return reserveBalance(reserveToken);
    }

    /**
     * @dev deprecated, backward compatibility
     */
    function getReturn(
        IReserveToken sourceToken,
        IReserveToken targetToken,
        uint256 sourceAmount
    ) external view returns (uint256, uint256) {
        return targetAmountAndFee(sourceToken, targetToken, sourceAmount);
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IConverterAnchor.sol";

import "../../utility/interfaces/IOwned.sol";

import "../../token/interfaces/IReserveToken.sol";

/**
 * @dev Converter interface
 */
interface IConverter is IOwned {
    function converterType() external pure returns (uint16);

    function anchor() external view returns (IConverterAnchor);

    function isActive() external view returns (bool);

    function targetAmountAndFee(
        IReserveToken sourceToken,
        IReserveToken targetToken,
        uint256 sourceAmount
    ) external view returns (uint256, uint256);

    function convert(
        IReserveToken sourceToken,
        IReserveToken targetToken,
        uint256 sourceAmount,
        address trader,
        address payable beneficiary
    ) external payable returns (uint256);

    function conversionFee() external view returns (uint32);

    function maxConversionFee() external view returns (uint32);

    function reserveBalance(IReserveToken reserveToken) external view returns (uint256);

    receive() external payable;

    function transferAnchorOwnership(address newOwner) external;

    function acceptAnchorOwnership() external;

    function setConversionFee(uint32 fee) external;

    function addReserve(IReserveToken token, uint32 weight) external;

    function transferReservesOnUpgrade(address newConverter) external;

    function onUpgradeComplete() external;

    // deprecated, backward compatibility
    function token() external view returns (IConverterAnchor);

    function transferTokenOwnership(address newOwner) external;

    function acceptTokenOwnership() external;

    function reserveTokenCount() external view returns (uint16);

    function reserveTokens() external view returns (IReserveToken[] memory);

    function connectors(IReserveToken reserveToken)
        external
        view
        returns (
            uint256,
            uint32,
            bool,
            bool,
            bool
        );

    function getConnectorBalance(IReserveToken connectorToken) external view returns (uint256);

    function connectorTokens(uint256 index) external view returns (IReserveToken);

    function connectorTokenCount() external view returns (uint16);

    /**
     * @dev triggered when the converter is activated
     */
    event Activation(uint16 indexed converterType, IConverterAnchor indexed anchor, bool indexed activated);

    /**
     * @dev triggered when a conversion between two tokens occurs
     */
    event Conversion(
        IReserveToken indexed sourceToken,
        IReserveToken indexed targetToken,
        address indexed trader,
        uint256 sourceAmount,
        uint256 targetAmount,
        int256 conversionFee
    );

    /**
     * @dev triggered when the rate between two tokens in the converter changes
     *
     * note that the event might be dispatched for rate updates between any two tokens in the converter
     */
    event TokenRateUpdate(address indexed token1, address indexed token2, uint256 rateN, uint256 rateD);

    /**
     * @dev triggered when the conversion fee is updated
     */
    event ConversionFeeUpdate(uint32 prevFee, uint32 newFee);
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "./IConverter.sol";
import "./IConverterAnchor.sol";
import "../../utility/interfaces/IContractRegistry.sol";

/**
 * @dev Typed Converter Factory interface
 */
interface ITypedConverterFactory {
    function converterType() external pure returns (uint16);

    function createConverter(
        IConverterAnchor anchor,
        IContractRegistry registry,
        uint32 maxConversionFee
    ) external returns (IConverter);
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../converter/interfaces/IConverterAnchor.sol";
import "../../utility/interfaces/IOwned.sol";

/**
 * @dev DSToken interface
 */
interface IDSToken is IConverterAnchor, IERC20 {
    function issue(address recipient, uint256 amount) external;

    function destroy(address recipient, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
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

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

contract ConverterVersion {
    // note that the version is defined as is for backward compatibility with older converters

    // solhint-disable-next-line const-name-snakecase
    uint16 public constant version = 47;
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "../../utility/interfaces/IOwned.sol";

/**
 * @dev Converter Anchor interface
 */
interface IConverterAnchor is IOwned {

}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

/**
 * @dev Converter Upgrader interface
 */
interface IConverterUpgrader {
    function upgrade(bytes32 version) external;

    function upgrade(uint16 version) external;
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

/**
 * @dev This library provides a set of complex math operations.
 */
library MathEx {
    uint256 private constant MAX_EXP_BIT_LEN = 4;
    uint256 private constant MAX_EXP = 2**MAX_EXP_BIT_LEN - 1;
    uint256 private constant MAX_UINT256 = uint256(-1);

    /**
     * @dev returns the largest integer smaller than or equal to the square root of a positive integer
     */
    function floorSqrt(uint256 num) internal pure returns (uint256) {
        uint256 x = num / 2 + 1;
        uint256 y = (x + num / x) / 2;
        while (x > y) {
            x = y;
            y = (x + num / x) / 2;
        }
        return x;
    }

    /**
     * @dev returns the smallest integer larger than or equal to the square root of a positive integer
     */
    function ceilSqrt(uint256 num) internal pure returns (uint256) {
        uint256 x = floorSqrt(num);

        return x * x == num ? x : x + 1;
    }

    /**
     * @dev computes the product of two given ratios
     */
    function productRatio(
        uint256 xn,
        uint256 yn,
        uint256 xd,
        uint256 yd
    ) internal pure returns (uint256, uint256) {
        uint256 n = mulDivC(xn, yn, MAX_UINT256);
        uint256 d = mulDivC(xd, yd, MAX_UINT256);
        uint256 z = n > d ? n : d;
        if (z > 1) {
            return (mulDivC(xn, yn, z), mulDivC(xd, yd, z));
        }
        return (xn * yn, xd * yd);
    }

    /**
     * @dev computes a reduced-scalar ratio
     */
    function reducedRatio(
        uint256 n,
        uint256 d,
        uint256 max
    ) internal pure returns (uint256, uint256) {
        (uint256 newN, uint256 newD) = (n, d);
        if (newN > max || newD > max) {
            (newN, newD) = normalizedRatio(newN, newD, max);
        }
        if (newN != newD) {
            return (newN, newD);
        }
        return (1, 1);
    }

    /**
     * @dev computes "scale * a / (a + b)" and "scale * b / (a + b)".
     */
    function normalizedRatio(
        uint256 a,
        uint256 b,
        uint256 scale
    ) internal pure returns (uint256, uint256) {
        if (a <= b) {
            return accurateRatio(a, b, scale);
        }
        (uint256 y, uint256 x) = accurateRatio(b, a, scale);
        return (x, y);
    }

    /**
     * @dev computes "scale * a / (a + b)" and "scale * b / (a + b)", assuming that "a <= b".
     */
    function accurateRatio(
        uint256 a,
        uint256 b,
        uint256 scale
    ) internal pure returns (uint256, uint256) {
        uint256 maxVal = MAX_UINT256 / scale;
        if (a > maxVal) {
            uint256 c = a / (maxVal + 1) + 1;
            a /= c; // we can now safely compute `a * scale`
            b /= c;
        }
        if (a != b) {
            uint256 newN = a * scale;
            uint256 newD = unsafeAdd(a, b); // can overflow
            if (newD >= a) {
                // no overflow in `a + b`
                uint256 x = roundDiv(newN, newD); // we can now safely compute `scale - x`
                uint256 y = scale - x;
                return (x, y);
            }
            if (newN < b - (b - a) / 2) {
                return (0, scale); // `a * scale < (a + b) / 2 < MAX_UINT256 < a + b`
            }
            return (1, scale - 1); // `(a + b) / 2 < a * scale < MAX_UINT256 < a + b`
        }
        return (scale / 2, scale / 2); // allow reduction to `(1, 1)` in the calling function
    }

    /**
     * @dev computes the nearest integer to a given quotient without overflowing or underflowing.
     */
    function roundDiv(uint256 n, uint256 d) internal pure returns (uint256) {
        return n / d + (n % d) / (d - d / 2);
    }

    /**
     * @dev returns the average number of decimal digits in a given list of positive integers
     */
    function geometricMean(uint256[] memory values) internal pure returns (uint256) {
        uint256 numOfDigits = 0;
        uint256 length = values.length;
        for (uint256 i = 0; i < length; ++i) {
            numOfDigits += decimalLength(values[i]);
        }
        return uint256(10)**(roundDivUnsafe(numOfDigits, length) - 1);
    }

    /**
     * @dev returns the number of decimal digits in a given positive integer
     */
    function decimalLength(uint256 x) internal pure returns (uint256) {
        uint256 y = 0;
        for (uint256 tmpX = x; tmpX > 0; tmpX /= 10) {
            ++y;
        }
        return y;
    }

    /**
     * @dev returns the nearest integer to a given quotient
     *
     * note the computation is overflow-safe assuming that the input is sufficiently small
     */
    function roundDivUnsafe(uint256 n, uint256 d) internal pure returns (uint256) {
        return (n + d / 2) / d;
    }

    /**
     * @dev returns the largest integer smaller than or equal to `x * y / z`
     */
    function mulDivF(
        uint256 x,
        uint256 y,
        uint256 z
    ) internal pure returns (uint256) {
        (uint256 xyh, uint256 xyl) = mul512(x, y);

        // if `x * y < 2 ^ 256`
        if (xyh == 0) {
            return xyl / z;
        }

        // assert `x * y / z < 2 ^ 256`
        require(xyh < z, "ERR_OVERFLOW");

        uint256 m = mulMod(x, y, z); // `m = x * y % z`
        (uint256 nh, uint256 nl) = sub512(xyh, xyl, m); // `n = x * y - m` hence `n / z = floor(x * y / z)`

        // if `n < 2 ^ 256`
        if (nh == 0) {
            return nl / z;
        }

        uint256 p = unsafeSub(0, z) & z; // `p` is the largest power of 2 which `z` is divisible by
        uint256 q = div512(nh, nl, p); // `n` is divisible by `p` because `n` is divisible by `z` and `z` is divisible by `p`
        uint256 r = inv256(z / p); // `z / p = 1 mod 2` hence `inverse(z / p) = 1 mod 2 ^ 256`
        return unsafeMul(q, r); // `q * r = (n / p) * inverse(z / p) = n / z`
    }

    /**
     * @dev returns the smallest integer larger than or equal to `x * y / z`
     */
    function mulDivC(
        uint256 x,
        uint256 y,
        uint256 z
    ) internal pure returns (uint256) {
        uint256 w = mulDivF(x, y, z);
        if (mulMod(x, y, z) > 0) {
            require(w < MAX_UINT256, "ERR_OVERFLOW");
            return w + 1;
        }
        return w;
    }

    /**
     * @dev returns the value of `x * y` as a pair of 256-bit values
     */
    function mul512(uint256 x, uint256 y) private pure returns (uint256, uint256) {
        uint256 p = mulModMax(x, y);
        uint256 q = unsafeMul(x, y);
        if (p >= q) {
            return (p - q, q);
        }
        return (unsafeSub(p, q) - 1, q);
    }

    /**
     * @dev returns the value of `2 ^ 256 * xh + xl - y`, where `2 ^ 256 * xh + xl >= y`
     */
    function sub512(
        uint256 xh,
        uint256 xl,
        uint256 y
    ) private pure returns (uint256, uint256) {
        if (xl >= y) {
            return (xh, xl - y);
        }
        return (xh - 1, unsafeSub(xl, y));
    }

    /**
     * @dev returns the value of `(2 ^ 256 * xh + xl) / pow2n`, where `xl` is divisible by `pow2n`
     */
    function div512(
        uint256 xh,
        uint256 xl,
        uint256 pow2n
    ) private pure returns (uint256) {
        uint256 pow2nInv = unsafeAdd(unsafeSub(0, pow2n) / pow2n, 1); // `1 << (256 - n)`
        return unsafeMul(xh, pow2nInv) | (xl / pow2n); // `(xh << (256 - n)) | (xl >> n)`
    }

    /**
     * @dev returns the inverse of `d` modulo `2 ^ 256`, where `d` is congruent to `1` modulo `2`
     */
    function inv256(uint256 d) private pure returns (uint256) {
        // approximate the root of `f(x) = 1 / x - d` using the newton–raphson convergence method
        uint256 x = 1;
        for (uint256 i = 0; i < 8; ++i) {
            x = unsafeMul(x, unsafeSub(2, unsafeMul(x, d))); // `x = x * (2 - x * d) mod 2 ^ 256`
        }
        return x;
    }

    /**
     * @dev returns `(x + y) % 2 ^ 256`
     */
    function unsafeAdd(uint256 x, uint256 y) private pure returns (uint256) {
        return x + y;
    }

    /**
     * @dev returns `(x - y) % 2 ^ 256`
     */
    function unsafeSub(uint256 x, uint256 y) private pure returns (uint256) {
        return x - y;
    }

    /**
     * @dev returns `(x * y) % 2 ^ 256`
     */
    function unsafeMul(uint256 x, uint256 y) private pure returns (uint256) {
        return x * y;
    }

    /**
     * @dev returns `x * y % (2 ^ 256 - 1)`
     */
    function mulModMax(uint256 x, uint256 y) private pure returns (uint256) {
        return mulmod(x, y, MAX_UINT256);
    }

    /**
     * @dev returns `x * y % z`
     */
    function mulMod(
        uint256 x,
        uint256 y,
        uint256 z
    ) private pure returns (uint256) {
        return mulmod(x, y, z);
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "./Owned.sol";
import "./Utils.sol";
import "./interfaces/IContractRegistry.sol";

/**
 * @dev This is the base contract for ContractRegistry clients.
 */
contract ContractRegistryClient is Owned, Utils {
    bytes32 internal constant CONTRACT_REGISTRY = "ContractRegistry";
    bytes32 internal constant BANCOR_NETWORK = "BancorNetwork";
    bytes32 internal constant CONVERTER_FACTORY = "ConverterFactory";
    bytes32 internal constant CONVERSION_PATH_FINDER = "ConversionPathFinder";
    bytes32 internal constant CONVERTER_UPGRADER = "BancorConverterUpgrader";
    bytes32 internal constant CONVERTER_REGISTRY = "BancorConverterRegistry";
    bytes32 internal constant CONVERTER_REGISTRY_DATA = "BancorConverterRegistryData";
    bytes32 internal constant BNT_TOKEN = "BNTToken";
    bytes32 internal constant BANCOR_X = "BancorX";
    bytes32 internal constant BANCOR_X_UPGRADER = "BancorXUpgrader";
    bytes32 internal constant LIQUIDITY_PROTECTION = "LiquidityProtection";
    bytes32 internal constant NETWORK_SETTINGS = "NetworkSettings";

    // address of the current contract registry
    IContractRegistry private _registry;

    // address of the previous contract registry
    IContractRegistry private _prevRegistry;

    // only the owner can update the contract registry
    bool private _onlyOwnerCanUpdateRegistry;

    /**
     * @dev verifies that the caller is mapped to the given contract name
     */
    modifier only(bytes32 contractName) {
        _only(contractName);
        _;
    }

    // error message binary size optimization
    function _only(bytes32 contractName) internal view {
        require(msg.sender == _addressOf(contractName), "ERR_ACCESS_DENIED");
    }

    /**
     * @dev initializes a new ContractRegistryClient instance
     */
    constructor(IContractRegistry initialRegistry) internal validAddress(address(initialRegistry)) {
        _registry = IContractRegistry(initialRegistry);
        _prevRegistry = IContractRegistry(initialRegistry);
    }

    /**
     * @dev updates to the new contract registry
     */
    function updateRegistry() external {
        // verify that this function is permitted
        require(msg.sender == owner() || !_onlyOwnerCanUpdateRegistry, "ERR_ACCESS_DENIED");

        // get the new contract registry
        IContractRegistry newRegistry = IContractRegistry(_addressOf(CONTRACT_REGISTRY));

        // verify that the new contract registry is different and not zero
        require(newRegistry != _registry && address(newRegistry) != address(0), "ERR_INVALID_REGISTRY");

        // verify that the new contract registry is pointing to a non-zero contract registry
        require(newRegistry.addressOf(CONTRACT_REGISTRY) != address(0), "ERR_INVALID_REGISTRY");

        // save a backup of the current contract registry before replacing it
        _prevRegistry = _registry;

        // replace the current contract registry with the new contract registry
        _registry = newRegistry;
    }

    /**
     * @dev restores the previous contract registry
     */
    function restoreRegistry() external ownerOnly {
        // restore the previous contract registry
        _registry = _prevRegistry;
    }

    /**
     * @dev restricts the permission to update the contract registry
     */
    function restrictRegistryUpdate(bool restrictOwnerOnly) public ownerOnly {
        // change the permission to update the contract registry
        _onlyOwnerCanUpdateRegistry = restrictOwnerOnly;
    }

    /**
     * @dev returns the address of the current contract registry
     */
    function registry() public view returns (IContractRegistry) {
        return _registry;
    }

    /**
     * @dev returns the address of the previous contract registry
     */
    function prevRegistry() external view returns (IContractRegistry) {
        return _prevRegistry;
    }

    /**
     * @dev returns whether only the owner can update the contract registry
     */
    function onlyOwnerCanUpdateRegistry() external view returns (bool) {
        return _onlyOwnerCanUpdateRegistry;
    }

    /**
     * @dev returns the address associated with the given contract name
     */
    function _addressOf(bytes32 contractName) internal view returns (address) {
        return _registry.addressOf(contractName);
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

/*
    Time implementing contract
*/
contract Time {
    /**
     * @dev returns the current time
     */
    function _time() internal view virtual returns (uint256) {
        return block.timestamp;
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "./interfaces/IReserveToken.sol";

import "./SafeERC20Ex.sol";

/**
 * @dev This library implements ERC20 and SafeERC20 utilities for reserve tokens, which can be either ERC20 tokens or ETH
 */
library ReserveToken {
    using SafeERC20 for IERC20;
    using SafeERC20Ex for IERC20;

    // the address that represents an ETH reserve
    IReserveToken public constant NATIVE_TOKEN_ADDRESS = IReserveToken(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    /**
     * @dev returns whether the provided token represents an ERC20 or ETH reserve
     */
    function isNativeToken(IReserveToken reserveToken) internal pure returns (bool) {
        return reserveToken == NATIVE_TOKEN_ADDRESS;
    }

    /**
     * @dev returns the balance of the reserve token
     */
    function balanceOf(IReserveToken reserveToken, address account) internal view returns (uint256) {
        if (isNativeToken(reserveToken)) {
            return account.balance;
        }

        return toIERC20(reserveToken).balanceOf(account);
    }

    /**
     * @dev transfers a specific amount of the reserve token
     */
    function safeTransfer(
        IReserveToken reserveToken,
        address to,
        uint256 amount
    ) internal {
        if (amount == 0) {
            return;
        }

        if (isNativeToken(reserveToken)) {
            payable(to).transfer(amount);
        } else {
            toIERC20(reserveToken).safeTransfer(to, amount);
        }
    }

    /**
     * @dev transfers a specific amount of the reserve token from a specific holder using the allowance mechanism
     *
     * note that the function ignores a reserve token which represents an ETH reserve
     */
    function safeTransferFrom(
        IReserveToken reserveToken,
        address from,
        address to,
        uint256 amount
    ) internal {
        if (amount == 0 || isNativeToken(reserveToken)) {
            return;
        }

        toIERC20(reserveToken).safeTransferFrom(from, to, amount);
    }

    /**
     * @dev ensures that the spender has sufficient allowance
     *
     * note that this function ignores a reserve token which represents an ETH reserve
     */
    function ensureApprove(
        IReserveToken reserveToken,
        address spender,
        uint256 amount
    ) internal {
        if (isNativeToken(reserveToken)) {
            return;
        }

        toIERC20(reserveToken).ensureApprove(spender, amount);
    }

    /**
     * @dev utility function that converts an IReserveToken to an IERC20
     */
    function toIERC20(IReserveToken reserveToken) private pure returns (IERC20) {
        return IERC20(address(reserveToken));
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "./utility/interfaces/ITokenHolder.sol";

interface INetworkSettings {
    function networkFeeParams() external view returns (ITokenHolder, uint32);

    function networkFeeWallet() external view returns (ITokenHolder);

    function networkFee() external view returns (uint32);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

/**
 * @dev Owned interface
 */
interface IOwned {
    function owner() external view returns (address);

    function transferOwnership(address newOwner) external;

    function acceptOwnership() external;
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

/**
 * @dev This contract is used to represent reserve tokens, which are tokens that can either be regular ERC20 tokens or
 * native ETH (represented by the NATIVE_TOKEN_ADDRESS address)
 *
 * Please note that this interface is intentionally doesn't inherit from IERC20, so that it'd be possible to effectively
 * override its balanceOf() function in the ReserveToken library
 */
interface IReserveToken {

}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "./interfaces/IOwned.sol";

/**
 * @dev This contract provides support and utilities for contract ownership.
 */
contract Owned is IOwned {
    address private _owner;
    address private _newOwner;

    /**
     * @dev triggered when the owner is updated
     */
    event OwnerUpdate(address indexed prevOwner, address indexed newOwner);

    /**
     * @dev initializes a new Owned instance
     */
    constructor() public {
        _owner = msg.sender;
    }

    // allows execution by the owner only
    modifier ownerOnly() {
        _ownerOnly();

        _;
    }

    // error message binary size optimization
    function _ownerOnly() private view {
        require(msg.sender == _owner, "ERR_ACCESS_DENIED");
    }

    /**
     * @dev allows transferring the contract ownership
     *
     * Requirements:
     *
     * - the caller must be the owner of the contract
     *
     * note the new owner still needs to accept the transfer
     */
    function transferOwnership(address newOwner) public override ownerOnly {
        require(newOwner != _owner, "ERR_SAME_OWNER");

        _newOwner = newOwner;
    }

    /**
     * @dev used by a new owner to accept an ownership transfer
     */
    function acceptOwnership() public override {
        require(msg.sender == _newOwner, "ERR_ACCESS_DENIED");

        emit OwnerUpdate(_owner, _newOwner);

        _owner = _newOwner;
        _newOwner = address(0);
    }

    /**
     * @dev returns the address of the current owner
     */
    function owner() public view override returns (address) {
        return _owner;
    }

    /**
     * @dev returns the address of the new owner candidate
     */
    function newOwner() external view returns (address) {
        return _newOwner;
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Utilities & Common Modifiers
 */
contract Utils {
    uint32 internal constant PPM_RESOLUTION = 1000000;

    // verifies that a value is greater than zero
    modifier greaterThanZero(uint256 value) {
        _greaterThanZero(value);

        _;
    }

    // error message binary size optimization
    function _greaterThanZero(uint256 value) internal pure {
        require(value > 0, "ERR_ZERO_VALUE");
    }

    // validates an address - currently only checks that it isn't null
    modifier validAddress(address addr) {
        _validAddress(addr);

        _;
    }

    // error message binary size optimization
    function _validAddress(address addr) internal pure {
        require(addr != address(0), "ERR_INVALID_ADDRESS");
    }

    // ensures that the portion is valid
    modifier validPortion(uint32 _portion) {
        _validPortion(_portion);

        _;
    }

    // error message binary size optimization
    function _validPortion(uint32 _portion) internal pure {
        require(_portion > 0 && _portion <= PPM_RESOLUTION, "ERR_INVALID_PORTION");
    }

    // validates an external address - currently only checks that it isn't null or this
    modifier validExternalAddress(address addr) {
        _validExternalAddress(addr);

        _;
    }

    // error message binary size optimization
    function _validExternalAddress(address addr) internal view {
        require(addr != address(0) && addr != address(this), "ERR_INVALID_EXTERNAL_ADDRESS");
    }

    // ensures that the fee is valid
    modifier validFee(uint32 fee) {
        _validFee(fee);

        _;
    }

    // error message binary size optimization
    function _validFee(uint32 fee) internal pure {
        require(fee <= PPM_RESOLUTION, "ERR_INVALID_FEE");
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

/**
 * @dev Contract Registry interface
 */
interface IContractRegistry {
    function addressOf(bytes32 contractName) external view returns (address);
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

/**
 * @dev Extends the SafeERC20 library with additional operations
 */
library SafeERC20Ex {
    using SafeERC20 for IERC20;

    /**
     * @dev ensures that the spender has sufficient allowance
     */
    function ensureApprove(
        IERC20 token,
        address spender,
        uint256 amount
    ) internal {
        if (amount == 0) {
            return;
        }

        uint256 allowance = token.allowance(address(this), spender);
        if (allowance >= amount) {
            return;
        }

        if (allowance > 0) {
            token.safeApprove(spender, 0);
        }
        token.safeApprove(spender, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
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

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "../../token/interfaces/IReserveToken.sol";

import "./IOwned.sol";

/**
 * @dev Token Holder interface
 */
interface ITokenHolder is IOwned {
    receive() external payable;

    function withdrawTokens(
        IReserveToken reserveToken,
        address payable to,
        uint256 amount
    ) external;

    function withdrawTokensMultiple(
        IReserveToken[] calldata reserveTokens,
        address payable to,
        uint256[] calldata amounts
    ) external;
}