// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.19;

import "./WiseSecurityHelper.sol";

error NotWiseLendingSecurity();

contract WiseSecurity is WiseSecurityHelper {

    modifier onlyWiseLending() {
        if (msg.sender != address(WISE_LENDING)) {
            revert NotWiseLendingSecurity();
        }
        _;
    }

    constructor(
        address _lendingMaster,
        address _oracleHubAddress,
        address _wiseLendingAddress,
        address _positionNFTAddress
    )
        WiseSecurityDeclarations(
            _lendingMaster,
            _oracleHubAddress,
            _wiseLendingAddress,
            _positionNFTAddress
        )
    {}

    function getLiveDebtratioNormalPool(
        uint256 _nftId
    )
        external
        view
        returns (uint256)
    {
        return overallUSDBorrow(_nftId)
            * PRECISION_FACTOR_E18
            / overallUSDCollateralsWeighted(_nftId);
    }

    function setUnderlyingPoolTokensFromPoolToken(
        address _poolToken,
        address[] memory _underlyingTokens
    )
        onlyWiseLending
        external
    {
        underlyingPoolTokensFromPoolToken[_poolToken] = _underlyingTokens;
    }

    function checksLiquidation(
        uint256 _nftIdLiquidate,
        address _caller,
        address _tokenToPayback,
        uint256 _shareAmountToPay
    )
        external
        view
    {
        checkPositionLocked(
            _nftIdLiquidate,
            _caller
        );

        (
            uint256 weightedCollateralUSD,
            uint256 unweightedCollateralUSD

        ) = overallUSDCollateralsBoth(
            _nftIdLiquidate
        );

        uint256 borrowUSDTotal = overallUSDBorrow(
            _nftIdLiquidate
        );

        canLiquidate(
            borrowUSDTotal,
            weightedCollateralUSD
        );

        checkMaxShares(
            _nftIdLiquidate,
            _tokenToPayback,
            borrowUSDTotal,
            unweightedCollateralUSD,
            _shareAmountToPay
        );
    }

    function prepareCurvePools(
        address _poolToken,
        address _curvePool,
        address _curveMetaPool,
        curveSwapStruct memory _curveSwapStruct
    )
        onlyWiseLending
        external
    {
        curveFromPoolToken[_poolToken] = ICurve(
            _curvePool
        );

        curveMetaFromPoolToken[_poolToken] = ICurve(
            _curveMetaPool
        );

        curveSwapInfo[_poolToken] = _curveSwapStruct;

        uint256 tokenIndexForApprove = _curveSwapStruct.curvePoolTokenIndexFrom;
        IERC20(curveFromPoolToken[_poolToken].coins(tokenIndexForApprove)).approve(
            _curvePool,
            UINT256_MAX
        );

        tokenIndexForApprove = _curveSwapStruct.curveMetaPoolTokenIndexFrom;
        IERC20(curveMetaFromPoolToken[_poolToken].coins(tokenIndexForApprove)).approve(
            _curveMetaPool,
            UINT256_MAX
        );
    }

    function curveSecurityCheck(
        address _poolToken
    )
        onlyWiseLending
        external
    {
        ICurve curveLP = curveFromPoolToken[
            _poolToken
        ];

        if (curveLP == ZERO_CURVE) {
            return;
        }

        curveSwapStruct memory currentCurveSwapInfo = curveSwapInfo[
            _poolToken
        ];

        curveLP.exchange(
            {
                fromIndex: int128(uint128(currentCurveSwapInfo.curvePoolTokenIndexFrom)),
                toIndex: int128(uint128(currentCurveSwapInfo.curvePoolTokenIndexTo)),
                exactAmountFrom: currentCurveSwapInfo.curvePoolSwapAmount,
                minReceiveAmount: 0
            }
        );

        ICurve curveMeta = curveMetaFromPoolToken[
            _poolToken
        ];

        if (curveMeta == ZERO_CURVE) {
            return;
        }

        curveMeta.exchange(
            {
                fromIndex: int128(uint128(currentCurveSwapInfo.curveMetaPoolTokenIndexFrom)),
                toIndex: int128(uint128(currentCurveSwapInfo.curveMetaPoolTokenIndexTo)),
                exactAmountFrom: currentCurveSwapInfo.curveMetaPoolSwapAmount,
                minReceiveAmount: 0
            }
        );
    }

    function checksDeposit(
        uint256 _nftId,
        address _caller,
        address _poolToken,
        uint256 _amount
    )
        external
        view
    {
        checkPositionLocked(
            _nftId,
            _caller
        );

        if (checkHeartbeat(_poolToken) == false) {
            revert ChainlinkDead();
        }

        checkMaxDepositValue(
            _poolToken,
            _amount
        );
    }

    function checksWithdraw(
        uint256 _nftId,
        address _caller,
        address _poolToken,
        uint256 _amount
    )
        external
        view
    {
        checkPositionLocked(
            _nftId,
            _caller
        );

        if (checkHeartbeat(_poolToken) == false) {
            if (overallUSDBorrowNoHeartbeat(_nftId) > 0) {
                revert OpenBorrowPosition();
            }

            return;
        }

        if (WISE_LENDING.veryfiedIsolationPool(_caller) == true) {
            return;
        }

        if (WISE_LENDING.getCollateralState(_nftId, _poolToken) == false) {
            return;
        }

        checkBorrowLimit(
            _nftId,
            _poolToken,
            _amount
        );
    }

    function checksSolelyWithdraw(
        uint256 _nftId,
        address _caller,
        address _poolToken,
        uint256 _amount
    )
        external
        view
    {
        checkPositionLocked(
            _nftId,
            _caller
        );

        if (checkHeartbeat(_poolToken) == false) {

            if (overallUSDBorrowNoHeartbeat(_nftId) > 0) {
                revert OpenBorrowPosition();
            }

            return;
        }

        checkBorrowLimit(
            _nftId,
            _poolToken,
            _amount
        );
    }

    function checksBorrow(
        uint256 _nftId,
        address _caller,
        address _poolToken,
        uint256 _amount
    )
        external
        view
    {
        checkPositionLocked(
            _nftId,
            _caller
        );

        if (checkHeartbeat(_poolToken) == false) {
            revert ChainlinkDead();
        }

        checkTokenAllowed(
            _poolToken
        );

        if (WISE_LENDING.veryfiedIsolationPool(_caller) == true) {
            return;
        }

        _checkBorrowPossible(
            _nftId,
            _poolToken,
            _amount
        );
    }

    function checkPaybackLendingShares(
        uint256 _nftIdReceiver,
        uint256 _nftIdCaller,
        address _caller,
        address _poolToken,
        uint256 _amount
    )
        external
        view
    {
        checkPositionLocked(
            _nftIdReceiver,
            _caller
        );

        if (WISE_LENDING.getCollateralState(_nftIdCaller, _poolToken) == false) {
            return;
        }

        checkBorrowLimit(
            _nftIdCaller,
            _poolToken,
            _amount
        );
    }

    function checksCollateralizeDeposit(
        uint256 _nftIdCaller,
        address _caller,
        address _poolAddress
    )
        external
        view
    {
        if (checkHeartbeat(_poolAddress) == false) {
            revert ChainlinkDead();
        }

        checkOwnerPosition(
            _nftIdCaller,
            _caller
        );
    }

    function checksCollateralizeDepositForUser(
        address _caller,
        address _poolAddress
    )
        external
        view
    {
        onlyIsolationPool(
            _caller
        );

        if (checkHeartbeat(_poolAddress) == false) {
            revert ChainlinkDead();
        }
    }

    function checksDecollateralizeDeposit(
        uint256 _nftIdCaller,
        address _caller,
        address _poolToken
    )
        external
        view
    {
        checkOwnerPosition(
            _nftIdCaller,
            _caller
        );

        if (checkHeartbeat(_poolToken) == false) {
            revert ChainlinkDead();
        }
    }

    function checksRegistrationIsolationPool(
        uint256 _nftId,
        address _caller,
        address _isolationPool
    )
        external
        view
    {
        checkOwnerPosition(
            _nftId,
            _caller
        );

        checkRegister(
            _nftId
        );

        onlyIsolationPool(
            _isolationPool
        );
    }

    function checkBadDebt(
        uint256 _nftId
    )
        external
    {
        uint256 bareCollateral = overallUSDCollateralsBare(
            _nftId
        );

        uint256 totalBorrow = overallUSDBorrow(
            _nftId
        );

        if (totalBorrow < bareCollateral) {
            return;
        }

        uint256 diff = totalBorrow
            - bareCollateral;

        FEE_MANAGER.increaseTotalBadDebtLiquidation(
            diff
        );

        FEE_MANAGER.setBadDebtUserLiquidation(
            _nftId,
            diff
        );
    }

    function checkRegisteredForPool(
        uint256 _nftId,
        address _isolationPool
    )
        external
        view
    {
        if (WISE_LENDING.isolationPoolRegistered(_nftId, _isolationPool) == false) {
            revert NotRegistered();
        }
    }

        function overallLendingAPY(
        uint256 _nftId
    )
        external
        view
        returns (uint256)
    {
        uint256 len = WISE_LENDING.getPositionLendingTokenLength(
            _nftId
        );

        address token;
        uint256 shares;
        uint256 overallShares;
        uint256 weightedRate;

        for (uint8 i = 0; i < len; i++) {

            token = WISE_LENDING.getPositionLendingTokenByIndex(
                _nftId,
                i
            );

            shares = WISE_LENDING.getPositionLendingShares(
                _nftId,
                token
            );

            weightedRate += shares
                * getLendingRate(token);

            overallShares += shares;
        }

        return weightedRate
            / overallShares;
    }

    function overallBorrowAPY(
        uint256 _nftId
    )
        external
        view
        returns (uint256)
    {
        uint256 len = WISE_LENDING.getPositionBorrowTokenLength(
            _nftId
        );

        address token;
        uint256 shares;
        uint256 overallShares;
        uint256 weightedRate;

        for (uint8 i = 0; i < len; i++) {

            token = WISE_LENDING.getPositionBorrowTokenByIndex(
                _nftId,
                i
            );

            shares = WISE_LENDING.getPositionBorrowShares(
                _nftId,
                token
            );

            weightedRate += shares
                * getBorrowRate(token);

            overallShares += shares;
        }

        return weightedRate
            / overallShares;
    }

    function safeLimitPosition(
        uint256 _nftId
    )
        external
        view
        returns (uint256 safeLimit)
    {
        uint256 len = WISE_LENDING.getPositionLendingTokenLength(
            _nftId
        );

        uint256 i;
        address token;

        for (i = 0; i < len; i++) {

            token = WISE_LENDING.getPositionLendingTokenByIndex(
                _nftId,
                i
            );

            if (checkHeartbeat(token) == false) {
                continue;
            }

            safeLimit += WISE_LENDING.lendingPoolData(token).collateralFactor
                * WISE_LENDING.borrowPoolData(token).borrowPercentageCap
                * getCollateralOfTokenUSD(
                    _nftId,
                    token
                )
                / PRECISION_FACTOR_E36;
        }
    }

    function positionLockedHeartbeat(
        uint256 _nftId
    )
        external
        view
        returns (bool, address)
    {
        uint256 len = WISE_LENDING.getPositionLendingTokenLength(
            _nftId
        );

        uint256 i;
        address token;

        for (i = 0; i < len; i++) {

            token = WISE_LENDING.getPositionLendingTokenByIndex(
                _nftId,
                i
            );

            if (checkHeartbeat(token) == false) {
                return (true, token);
            }
        }

        return (false, ZERO_ADDRESS);
    }

    function maximumWithdrawToken(
        address _poolToken,
        uint256 _nftId
    )
        external
        view
        returns (uint256 tokenAmount, uint256 shares)
    {
        uint256 term = overallUSDBorrow(_nftId)
            * PRECISION_FACTOR_E36
            / WISE_LENDING.lendingPoolData(_poolToken).collateralFactor
            / WISE_LENDING.borrowPoolData(_poolToken).borrowPercentageCap;

        uint256 withdrawUSD = overallUSDCollateralsWeighted(_nftId)
            - term;

        tokenAmount = WISE_ORACLE.getTokensFromUSD(
            _poolToken,
            withdrawUSD
        );

        shares = WISE_LENDING.calculateLendingShares(
            _poolToken,
            tokenAmount
        );
    }

    function maximumBorrowToken(
        address _poolToken,
        uint256 _nftId
    )
        external
        view
        returns (uint256 tokenAmount, uint256 shares)
    {
        uint256 term = overallUSDCollateralsBare(_nftId)
            * WISE_LENDING.lendingPoolData(_poolToken).collateralFactor
            * WISE_LENDING.borrowPoolData(_poolToken).borrowPercentageCap
            / PRECISION_FACTOR_E36;

        uint256 borrowUSD = overallUSDBorrow(_nftId)
            - term;

        tokenAmount = WISE_ORACLE.getTokensFromUSD(
            _poolToken,
            borrowUSD
        );

        shares = WISE_LENDING.calculateLendingShares(
            _poolToken,
            tokenAmount
        );
    }

    function getPositionLendingAmount(
        uint256 _nftId,
        address _poolToken
    )
        external
        view
        returns (uint256)
    {
        return WISE_LENDING.cashoutAmount(
            _poolToken,
            WISE_LENDING.getPositionLendingShares(
                _nftId,
                _poolToken
            )
        );
    }

    function getPositionBorrowAmount(
        uint256 _nftId,
        address _poolToken
    )
        external
        view
        returns (uint256)
    {
        return WISE_LENDING.paybackAmount(
            _poolToken,
            WISE_LENDING.getPositionBorrowShares(
                _nftId,
                _poolToken
            )
        );
    }
}

// SPDX-License-Identifier: -- WISE --
pragma solidity =0.8.19;

import "./WiseSecurityDeclarations.sol";

abstract contract WiseSecurityHelper is WiseSecurityDeclarations {

    function overallUSDCollateralsBoth(
        uint256 _nftId
    )
        public
        view
        returns (uint256, uint256)
    {
        uint256 amount;
        uint256 weightedTotal;
        uint256 unweightedAmount;
        address tokenAddress;

        for (uint256 i = 0; i < WISE_LENDING.getPositionLendingTokenLength(_nftId); i++) {

            tokenAddress = WISE_LENDING.getPositionLendingTokenByIndex(
                _nftId,
                i
            );

            if (checkHeartbeat(tokenAddress) == false) {
                revert ChainlinkDead();
            }

            amount = getCollateralOfTokenUSD(
                _nftId,
                tokenAddress
            );

            weightedTotal += amount
                * WISE_LENDING.lendingPoolData(tokenAddress).collateralFactor
                / PRECISION_FACTOR_E18;

            unweightedAmount += amount;
        }

        return (weightedTotal, unweightedAmount);
    }

    function overallUSDCollateralsWeighted(
       uint256 _nftId
    )
        public
        view
        returns (uint256 weightedTotal)
    {
        address tokenAddress;

        for (uint256 i = 0; i < WISE_LENDING.getPositionLendingTokenLength(_nftId); i++) {

            tokenAddress = WISE_LENDING.getPositionLendingTokenByIndex(
                _nftId,
                i
            );

            if (checkHeartbeat(tokenAddress) == false) {
                revert ChainlinkDead();
            }

            weightedTotal += WISE_LENDING.lendingPoolData(tokenAddress).collateralFactor
                * getCollateralOfTokenUSD(
                    _nftId,
                    tokenAddress
                )
                / PRECISION_FACTOR_E18;
        }
    }

    function overallUSDCollateralsBare(
        uint256 _nftId
    )
        public
        view
        returns (uint256 amount)
    {
        for (uint256 i = 0; i < WISE_LENDING.getPositionLendingTokenLength(_nftId); i++) {

            amount += getCollateralOfTokenUSD(
                _nftId,
                WISE_LENDING.getPositionLendingTokenByIndex(
                    _nftId,
                    i
                )
            );
        }
    }

    /*
    function overallUSDCollateralsWeightedNoHeartbeat(
       address _user
    )
        public
        view
        returns (uint256 weightedTotal)
    {
        address tokenAddress;

        for (uint256 i = 0; i < WISE_LENDING.getPositionLendingTokenLength(_user); i++) {

            tokenAddress = WISE_LENDING.getPositionLendingTokenByIndex(
                _user,
                i
            );

            if (checkHeartbeat(tokenAddress) == false) {
                revert ChainlinkDead();
            }

            weightedTotal += WISE_LENDING.lendingPoolData(tokenAddress).collateralFactor
                * getCollateralOfTokenUSD(
                    _user,
                    tokenAddress
                )
                / PRECISION_FACTOR_E18;
        }
    }
    */

    function getCollateralOfTokenUSD(
        uint256 _nftId,
        address _poolToken
    )
        public
        view
        returns (uint256 usdCollateral)
    {
        usdCollateral = WISE_ORACLE.getTokensInUSD(
            _poolToken,
            WISE_LENDING.getPureCollateralAmount(
                _nftId,
                _poolToken
            )
        );

        if (WISE_LENDING.getCollateralState(_nftId, _poolToken)) {
            usdCollateral += getUSDCollateralShare(
                _nftId,
                _poolToken
            );
        }
    }

    function getUSDCollateralShare(
        uint256 _nftId,
        address _poolToken
    )
        public
        view
        returns (uint256)
    {
        uint256 amount = WISE_LENDING.cashoutAmount(
            _poolToken,
            WISE_LENDING.getPositionLendingShares(
                _nftId,
                _poolToken
            )
        );

        return WISE_ORACLE.getTokensInUSD(
            _poolToken,
            amount
        );
    }

    function overallUSDBorrowNoHeartbeat(
        uint256 _nftId
    )
        public
        view
        returns (uint256 buffer)
    {
        for (uint256 i = 0; i < WISE_LENDING.getPositionBorrowTokenLength(_nftId); i++) {

            buffer += getUSDBorrow(
                _nftId,
                WISE_LENDING.getPositionBorrowTokenByIndex(
                    _nftId,
                    i
                )
            );
        }
    }

    function overallUSDBorrow(
        uint256 _nftId
    )
        public
        view
        returns (uint256 buffer)
    {
        address tokenAddress;

        for (uint256 i = 0; i < WISE_LENDING.getPositionBorrowTokenLength(_nftId); i++) {

            tokenAddress = WISE_LENDING.getPositionBorrowTokenByIndex(
                _nftId,
                i
            );

            if (checkHeartbeat(tokenAddress) == false) {
                revert ChainlinkDead();
            }

            buffer += getUSDBorrow(
                _nftId,
                tokenAddress
            );
        }
    }

    function getUSDBorrow(
        uint256 _nftId,
        address _poolToken
    )
        public
        view
        returns (uint256)
    {
        uint256 amount = WISE_LENDING.paybackAmount(
            _poolToken,
            WISE_LENDING.getPositionBorrowShares(
                _nftId,
                _poolToken
            )
        );

        return WISE_ORACLE.getTokensInUSD(
            _poolToken,
            amount
        );
    }

    function checkTokenAllowed(
        address _poolAddress
    )
        public
        view
    {
        if (WISE_LENDING.borrowPoolData(_poolAddress).allowBorrow == false) {
            revert NotAllowedToBorrow();
        }
    }

    /**
     * @dev Check if chainLink feed was
     * updated within expected timeframe
     */
    function checkHeartbeat(
        address _poolToken
    )
        public
        view
        returns (bool)
    {
        bool returnBool = true;
        uint256 underlyingLength = underlyingPoolTokensFromPoolToken[_poolToken].length;

        if (underlyingLength == 0) {
            return _checkHeartBeat(
                _poolToken
            );
        }

        for (uint256 i = 0; i < underlyingLength; i++) {

            bool currentBool = _checkHeartBeat(
                underlyingPoolTokensFromPoolToken[_poolToken][i]
            );

            if (currentBool == false) {
                returnBool = false;
            }
        }

        return returnBool;
    }

    function _checkHeartBeat(
        address _poolToken
    )
        internal
        view
        returns (bool)
    {
        if (WISE_ORACLE.chainLinkIsDead(_poolToken) == true) {
            return false;
        }

        return true;
    }

    function checkPositionLocked(
        uint256 _nftId,
        address _caller
    )
        public
        view
    {
        if (WISE_LENDING.veryfiedIsolationPool(_caller) == true) {
            return;
        }

        if (WISE_LENDING.positionLocked(_nftId) == false) {
            return;
        }

        revert PositionLocked();
    }

    function onlyIsolationPool(
        address _poolAddress
    )
        public
        view
    {
        if (WISE_LENDING.veryfiedIsolationPool(_poolAddress) == false) {
            revert NonVerifiedPool();
        }
    }

    function checkOnlyMaster(
        address _caller
    )
        external
        view
    {
        if  (WISE_LENDING.lendingMaster() == _caller) {
            return;
        }

        revert NotMaster();
    }

    function checkMaxDepositValue(
        address _poolToken,
        uint256 _amount
    )
        public
        view
    {
        bool state = WISE_LENDING.maxDepositValueToken(_poolToken)
            < WISE_LENDING.getTotalBareToken(_poolToken)
            + WISE_LENDING.getPseudoTotalPool(_poolToken)
            + _amount;

        if (state == true) {
            revert DepositCapReached();
        }
    }

    function checkBorrowLimit(
        uint256 _nftId,
        address _poolToken,
        uint256 _amount
    )
        public
        view
    {
        uint256 borrowAmount = overallUSDBorrow(
            _nftId
        );

        if (borrowAmount == 0) {
            return;
        }

        uint256 withdrawValue = WISE_ORACLE.getTokensInUSD(
            _poolToken,
            _amount
        )
            * WISE_LENDING.lendingPoolData(_poolToken).collateralFactor
            / PRECISION_FACTOR_E18;

        bool state = (WISE_LENDING.borrowPoolData(_poolToken).borrowPercentageCap
            * overallUSDCollateralsWeighted(_nftId)
            / PRECISION_FACTOR_E18)
            - withdrawValue
            <= borrowAmount;

        if (state == true) {
            revert ResultsInBadDebt();
        }
    }

    function _checkBorrowPossible(
        uint256 _nftId,
        address _poolToken,
        uint256 _amount
    )
        internal
        view
    {
        uint256 borrowValue = WISE_ORACLE.getTokensInUSD(
            _poolToken,
            _amount
        );

        bool state = WISE_LENDING.borrowPoolData(_poolToken).borrowPercentageCap
            * overallUSDCollateralsWeighted(_nftId)
            / PRECISION_FACTOR_E18
            <= overallUSDBorrow(_nftId) + borrowValue;

        if (state == true) {
            revert NotEnoughCollateral();
        }
    }

    function checkRegister(
        uint256 _nftId
    )
        public
        view
    {
        if (overallUSDCollateralsWeighted(_nftId) > 0) {
            revert NotAllowedWiseSecurity();
        }

        if (WISE_LENDING.positionLocked(_nftId) == true) {
            revert NotAllowedWiseSecurity();
        }
    }

    function checkUnregister(
        uint256 _nftId,
        address _caller
    )
        public
        view
    {
        checkOwnerPosition(
            _nftId,
            _caller
        );

        if (overallUSDCollateralsWeighted(_nftId) > 0) {
            revert NotAllowedWiseSecurity();
        }

        if (overallUSDBorrow(_nftId) > 0) {
            revert NotAllowedWiseSecurity();
        }
    }

    function canLiquidate(
        uint256 _borrowUSDTotal,
        uint256 _weightedCollateralUSD
    )
        public
        pure
    {
        bool state = _weightedCollateralUSD > _borrowUSDTotal;

        if (state == true) {
            revert LiquidationDenied();
        }
    }

    function checkMaxShares(
        uint256 _nftId,
        address _tokenToPayback,
        uint256 _borrowUSDTotal,
        uint256 _unweightedCollateralUSD,
        uint256 _shareAmountToPay
    )
        public
        view
    {
        uint256 totalSharesUser = WISE_LENDING.getPositionBorrowShares(
            _nftId,
            _tokenToPayback
        );

        uint256 maxShares = checkBadDebtThreshold(_borrowUSDTotal, _unweightedCollateralUSD)
            ? totalSharesUser
            : totalSharesUser * MAX_LIQUIDATION_50 / PRECISION_FACTOR_E18;

        bool state = _shareAmountToPay <= maxShares;

        if (state == false) {
            revert TooManyShares();
        }
    }

    function checkBadDebtThreshold(
        uint256 _borrowUSDTotal,
        uint256 _unweightedCollateral
    )
        public
        pure
        returns (bool)
    {
        return _borrowUSDTotal * PRECISION_FACTOR_E18
            >= _unweightedCollateral * BAD_DEBT_THRESHOLD;
    }

    function checkOwnerPosition(
        uint256 _nftId,
        address _caller
    )
        public
        view
    {
        if (POSITION_NFTS.ownerOf(_nftId) != _caller) {
            revert NotOwner();
        }
    }

    // Maybe remove to save gas?
    /*
    function checkPositionExist(
        uint256 _nftId
    )
        public
        view
    {
        if (POSITION_NFTS.totalSupply() < _nftId) {
            revert NotExisting();
        }
    }
    */

    function getBorrowRate(
        address _poolToken
    )
        public
        view
        returns (uint256)
    {
        return WISE_LENDING.borrowPoolData(_poolToken).borrowRate;
    }

    function getLendingRate(
        address _poolToken
    )
        public
        view
        returns (uint256)
    {
        uint256 adjustedRate = getBorrowRate(_poolToken)
            * (PRECISION_FACTOR_E18 - WISE_LENDING.globalPoolData(_poolToken).poolFee)
            / PRECISION_FACTOR_E18;

        return adjustedRate
            * WISE_LENDING.getPseudoTotalBorrowAmount(_poolToken)
            / WISE_LENDING.getPseudoTotalPool(_poolToken);
    }
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.19;

import "../InterfaceHub/IERC20.sol";
import "../InterfaceHub/ICurve.sol";
import "../InterfaceHub/IPositionNFTs.sol";
import "../InterfaceHub/IWiseOracleHub.sol";
import "../InterfaceHub/IFeeManager.sol";
import "../InterfaceHub/IWiseLending.sol";

import "../FeeManager/FeeManager.sol";
import "../WiseLiquidation/WiseLiquidation.sol";

error NotMaster();
error NotAllowedWiseSecurity();
error ChainlinkDead();
error PositionLocked();
error ResultsInBadDebt();
error DepositCapReached();
error OnlyIsolationPool();
error NotEnoughCollateral();
error NotAllowedToBorrow();
error OpenBorrowPosition();
error NonVerifiedPool();
error NotOwner();
error NotExisting();
error NotRegistered();

contract WiseSecurityDeclarations {

    constructor(
        address _lendingMaster,
        address _oracleHubAddress,
        address _wiseLendingAddress,
        address _positionNFTAddress
    )
    {
        WiseLiquidation liquidationContract = new WiseLiquidation(
            _wiseLendingAddress,
            _oracleHubAddress,
            address(this)
        );

        FeeManager feeManagerContract = new FeeManager(
            _lendingMaster,
            _wiseLendingAddress,
            _oracleHubAddress,
            address(this),
            _positionNFTAddress
        );

        WISE_ORACLE = IWiseOracleHub(
            _oracleHubAddress
        );

        WISE_LENDING = IWiseLending(
            _wiseLendingAddress
        );

        FEE_MANAGER = IFeeManager(
            address(feeManagerContract)
        );

        WISE_LIQUIDATION = liquidationContract;

        POSITION_NFTS = IPositionNFTs(
            _positionNFTAddress
        );
    }

    IFeeManager public immutable FEE_MANAGER;
    IWiseLending public immutable WISE_LENDING;
    IPositionNFTs public immutable POSITION_NFTS;
    IWiseOracleHub public immutable WISE_ORACLE;

    ICurve constant ZERO_CURVE = ICurve(ZERO_ADDRESS);
    WiseLiquidation public immutable WISE_LIQUIDATION;

    uint256 constant MAX_LIQUIDATION_50 = 0.5 ether ;
    uint256 constant BAD_DEBT_THRESHOLD = 0.89 ether;
    uint256 constant UINT256_MAX = type(uint256).max;

    uint256 constant PRECISION_FACTOR_E18 = 1 ether;
    uint256 constant PRECISION_FACTOR_E36 = PRECISION_FACTOR_E18 * PRECISION_FACTOR_E18;

    address constant ZERO_ADDRESS = address(0);

    mapping(address => address[]) underlyingPoolTokensFromPoolToken;
    mapping(address => ICurve) public curveFromPoolToken;
    mapping(address => ICurve) public curveMetaFromPoolToken;
    mapping(address => curveSwapStruct) public curveSwapInfo;
}

// SPDX-License-Identifier: -- WISE --
pragma solidity =0.8.19;

import "./WiseLiquidationHelper.sol";

contract WiseLiquidation is WiseLiquidationHelper {

    constructor(
        address _lendingAddress,
        address _oracleHubAddress,
        address _wiseSecurityAddress
    )
        Declarations(
            _lendingAddress,
            _oracleHubAddress,
            _wiseSecurityAddress
        )
    {}

    function liquidatePartiallyFromTokens(
        uint256 _nftId,
        uint256 _nftIdLiquidator,
        address _tokenToPayback, // @todo rename
        address _tokenToRecieve, // @todo rename
        uint256 _shareAmountToPay
    )
        external
    {
        address caller = msg.sender;

        // @TODO: this is own function, be careful with duplicates
        _prepareBorrows(
            _nftId
        );

        // @TODO: this is own function, be careful with duplicates
        _prepareCollaterals(
            _nftId
        );

        WISE_SECURITY.checksLiquidation(
            _nftId,
            caller,
            _tokenToPayback,
            _shareAmountToPay
        );

        uint256 paybackAmount = WISE_LENDING.paybackAmount(
            _tokenToPayback,
            _shareAmountToPay
        );

        _coreLiquidation(
            _nftId,
            _nftIdLiquidator,
            caller,
            _tokenToPayback,
            _tokenToRecieve,
            paybackAmount,
            _shareAmountToPay,
            BASE_REWARD_LIQUIDATION_WISE_LENDING
        );

        emit LiquidatedPartiallyFromTokens(
            _nftId,
            caller,
            _tokenToPayback,
            _tokenToRecieve,
            _shareAmountToPay,
            block.timestamp
        );
    }

    function coreLiquidationIsolationPools(
        uint256 _nftId,
        uint256 _nftIdLiquidator,
        address _caller,
        address _tokenToPayback,
        address _tokenToRecieve,
        uint256 _paybackAmount,
        uint256 _shareAmountToPay
    )
        external
        returns (uint256 reveiveAmount)
    {
        WISE_SECURITY.onlyIsolationPool(
            msg.sender
        );

        reveiveAmount = _coreLiquidation(
            _nftId,
            _nftIdLiquidator,
            _caller,
            _tokenToPayback,
            _tokenToRecieve,
            _paybackAmount,
            _shareAmountToPay,
            BASE_REWARD_LIQUIDATION_ISOLATION_POOL
        );
    }
}

// SPDX-License-Identifier: -- WISE --
pragma solidity =0.8.19;

import "./FeeManagerHelper.sol";

contract FeeManager is FeeManagerHelper {

    constructor(
        address _multisig,
        address _wiseLendingAddress,
        address _oracleHubAddress,
        address _wiseSecurityAddress,
        address _positionNFTAddress
    )
        DeclarationsFeeManager(
            _multisig,
            _wiseLendingAddress,
            _oracleHubAddress,
            _wiseSecurityAddress,
            _positionNFTAddress
        )
    {}

    function setPoolFee(
        address _poolToken,
        uint256 _newFee
    )
        external
        onlyMultisig
    {
        if (_newFee > PRECISION_FACTOR_E18) {
            revert TooHighValue();
        }

        if (_newFee < PRECISION_FACTOR_E16) {
            revert TooLowValue();
        }

        WISE_LENDING.setPoolFee(
            _poolToken,
            _newFee
        );
    }

    function renounceIncentiveMaster(
        address _newIncentiveMaster
    )
        external
        onlyIncentiveMaster
    {
        renouncedIncentiveMaster = _newIncentiveMaster;
    }

    function claimNewIncentiveMaster()
        external
    {
        if (msg.sender != renouncedIncentiveMaster) {
            revert NotAllowed();
        }

        incentiveMaster = renouncedIncentiveMaster;
        renouncedIncentiveMaster = ZERO_ADDRESS;
    }

    function increaseIncentiveA(
        uint256 _value
    )
        external
        onlyIncentiveMaster
    {
        incentiveUSD[incentiveOwnerA] += _value;
    }

    function increaseIncentiveB(
        uint256 _value
    )
        external
        onlyIncentiveMaster
    {
        incentiveUSD[incentiveOwnerB] += _value;
    }

    function claimIncentivesBulk()
        external
    {
        for (uint8 i = 0; i < poolTokenAddresses.length; i++) {

            claimIncentives(
                poolTokenAddresses[i]
            );
        }
    }

    function claimIncentives(
        address _poolToken
    )
        public
    {
        address caller = msg.sender;

        _safeTransfer(
            _poolToken,
            caller,
            gatheredIncentiveToken[caller][_poolToken]
        );

        gatheredIncentiveToken[caller][_poolToken] = 0;
    }

    function approveWiseLending()
        external
    {
        for (uint8 i = 0 ; i < poolTokenAddresses.length; i++ ) {
            IERC20(poolTokenAddresses[i]).approve(
                address(WISE_LENDING),
                HUGE_AMOUNT
            );
        }
    }

    function changeIncentiveUSDA(
        address _newOwner
    )
        external
    {
        if (msg.sender != incentiveOwnerA) {
            revert NotAllowed();
        }

        incentiveUSD[_newOwner] = incentiveUSD[incentiveOwnerA];
        incentiveUSD[incentiveOwnerA] = 0;

        incentiveOwnerA = _newOwner;
    }

    function changeIncentiveUSDB(
        address _newOwner
    )
        external
    {
        if (msg.sender != incentiveOwnerB) {
            revert NotAllowed();
        }

        incentiveUSD[_newOwner] = incentiveUSD[incentiveOwnerB];
        incentiveUSD[incentiveOwnerB] = 0;

        incentiveOwnerB= _newOwner;
    }

    function addPoolTokenAddress(
        address _poolToken
    )
        external
        onlyWiseLending
    {
        poolTokenAddresses.push(_poolToken);

        poolTokenAdded[_poolToken] = true;

        emit PoolTokenAdded(
            _poolToken,
            block.timestamp
        );
    }

    function addPoolTokenAddressManual(
        address _poolToken
    )
        external
        onlyMultisig
    {
        if (poolTokenAdded[_poolToken] == true) {
            revert PoolAlreadyAdded();
        }

        poolTokenAddresses.push(_poolToken);

        poolTokenAdded[_poolToken] = true;

        emit PoolTokenAdded(
            _poolToken,
            block.timestamp
        );
    }

    function getNumberRegisteredPools()
        external
        view
        returns (uint256)
    {
        return poolTokenAddresses.length;
    }

    function removePoolTokenManual(
        address _poolToken
    )
        external
        onlyMultisig
    {
        uint256 len = poolTokenAddresses.length;
        uint256 lastEntry = len - 1;

        for (uint8 i = 0; i < len; i++) {

            if (_poolToken != poolTokenAddresses[i]) {

                continue;
            }

            poolTokenAddresses[i] = poolTokenAddresses[lastEntry];

            poolTokenAddresses.pop();

            poolTokenAdded[_poolToken] = false;

            break;
        }
    }

    function increaseTotalBadDebtLiquidation(
        uint256 _amount
    )
        external
        onlyWiseSecurity
    {
        _increaseTotalBadDebt(
            _amount
        );

        emit BadDebtIncreasedLiquidation(
            _amount,
            block.timestamp
        );
    }

    function setBadDebtUserLiquidation(
        uint256 _nftId,
        uint256 _amount
    )
        external
        onlyWiseSecurity
    {
        _setBadDebtUser(
            _nftId,
            _amount
        );

        emit SetBadDebtPosition(
            _nftId,
            _amount,
            block.timestamp
        );
    }

    function setBeneficial(
        address _user,
        address[] memory _poolTokens
    )
        external
        onlyMultisig
    {
        for (uint8 i = 0; i < _poolTokens.length; i++) {
            _setAllowedTokens(
                _user,
                _poolTokens[i],
                true
            );
        }

        emit SetBeneficial(
            _user,
            _poolTokens,
            block.timestamp
        );
    }

    function revokeBeneficial(
        address _user,
        address[] memory _poolTokens
    )
        external
        onlyMultisig
    {
        for (uint8 i = 0; i < _poolTokens.length; i++) {
            _setAllowedTokens(
                _user,
                _poolTokens[i],
                false
            );
        }

        emit RevokeBeneficial(
            _user,
            _poolTokens,
            block.timestamp
        );
    }

    function claimWiseFeesBulk()
        external
    {
        for(uint8 i = 0; i < poolTokenAddresses.length; i++) {
            claimWiseFees(
                poolTokenAddresses[i]
            );
        }
    }

    function claimWiseFees(
        address _poolToken
    )
        public
    {
        uint256 shares = WISE_LENDING.getPositionLendingShares(
            FEE_MASTER_NFT_ID,
            _poolToken
        );

        if (shares == 0) {
            return;
        }

        uint256 tokenAmount = WISE_LENDING.withdrawExactShares(
            FEE_MASTER_NFT_ID,
            _poolToken,
            shares
        );

        if (totalBadDebtUSD == 0) {

            tokenAmount = _distributeIncentives(
                tokenAmount,
                _poolToken
            );
        }

        _increaseFeeTokens(
            _poolToken,
            tokenAmount
        );

        emit ClaimedFeesWise(
            _poolToken,
            tokenAmount,
            block.timestamp
        );
    }

    function claimFeesBeneficial(
        address _poolToken,
        uint256 _amount
    )
        external
    {
        address caller = msg.sender;

        if (totalBadDebtUSD > 0) {
            revert ExistingBadDebt();
        }

        if (allowedTokens[caller][_poolToken] == false) {
            revert NotAllowed();
        }

        _decreaseFeeTokens(
            _poolToken,
            _amount
        );

        _safeTransfer(
            _poolToken,
            caller,
            _amount
        );

        emit ClaimedFeesBeneficial(
            caller,
            _poolToken,
            _amount,
            block.timestamp
        );
    }

    function payBackBadDebtForToken(
        uint256 _nftId,
        address _paybackToken,
        address _receivingToken,
        uint256 _shares
    )
        external
        returns (uint256 paybackAmount, uint256 receivingAmount)
    {
        address caller = msg.sender;

        updatePositionCurrentBadDebt(
            _nftId
        );

        if (badDebtPosition[_nftId] == 0) {
            return (0, 0);
        }

        paybackAmount = WISE_LENDING.paybackAmount(
            _paybackToken,
            _shares
        );

        _safeTransferFrom(
            _paybackToken,
            caller,
            address(this),
            paybackAmount
        );

        WISE_LENDING.corePaybackFeeMananger(
            _paybackToken,
            _nftId,
            paybackAmount,
            _shares
        );

        _updateUserBadDebt(
            _nftId
        );

        receivingAmount = getReceivingToken(
            _paybackToken,
            _receivingToken,
            paybackAmount
        );

        _decreaseFeeTokens(
            _receivingToken,
            receivingAmount
        );

        _safeTransfer(
            _receivingToken,
            caller,
            receivingAmount
        );

        emit PayedBackBadDebt(
            _nftId,
            caller,
            _paybackToken,
            _receivingToken,
            paybackAmount,
            block.timestamp
        );
    }

    function paybackBadDebtForFree(
        uint256 _nftId,
        address _paybackToken,
        uint256 _shares
    )
        external
        returns (uint256 paybackAmount)
    {
        address caller = msg.sender;

        updatePositionCurrentBadDebt(
            _nftId
        );

        if (badDebtPosition[_nftId] == 0) {
            return 0;
        }

        paybackAmount = WISE_LENDING.paybackAmount(
            _paybackToken,
            _shares
        );

        _safeTransferFrom(
            _paybackToken,
            caller,
            address(this),
            paybackAmount
        );

        WISE_LENDING.corePaybackFeeMananger(
            _paybackToken,
            _nftId,
            paybackAmount,
            _shares
        );

        _updateUserBadDebt(
            _nftId
        );

        emit PayedBackBadDebtFree(
            _nftId,
            caller,
            _paybackToken,
            paybackAmount,
            block.timestamp
        );
    }
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.19;

struct GlobalPoolEntry {
    uint256 totalPool;
    uint256 utilization;
    uint256 totalBareToken;
    uint256 poolFee;
}

struct BorrowPoolEntry {
    bool allowBorrow;
    uint256 pseudoTotalBorrowAmount;
    uint256 borrowPercentageCap;
    uint256 totalBorrowShares;
    uint256 borrowRate;
}

struct LendingPoolEntry {
    uint256 pseudoTotalPool;
    uint256 totalDepositShares;
    uint256 collateralFactor;
}

struct PoolEntry {
    uint256 totalPool;
    uint256 utilization;
    uint256 totalBareToken;
    uint256 poolFee;
}

interface IWiseLending {

    function borrowPoolData(
        address _poolToken
    )
        external
        view
        returns (BorrowPoolEntry memory);

    function lendingPoolData(
        address _poolToken
    )
        external
        view
        returns (LendingPoolEntry memory);

    function getPositionBorrowShares(
        uint256 _nftId,
        address _poolToken
    )
        external
        view
        returns (uint256);

    function getPureCollateralAmount(
        uint256 _nftId,
        address _poolToken
    )
        external
        view
        returns (uint256);

    function getCollateralState(
        uint256 _nftId,
        address _poolToken
    )
        external
        view
        returns (bool);

    function veryfiedIsolationPool(
        address _poolAddress
    )
        external
        view
        returns (bool);

    function positionLocked(
        uint256 _nftId
    )
        external
        view
        returns (bool);

    function getTotalBareToken(
        address _poolToken
    )
        external
        view
        returns (uint256);

    function maxDepositValueToken(
        address _poolToken
    )
        external
        view
        returns (uint256);

    function lendingMaster()
        external
        view
        returns (address);

    function isolationPoolRegistered(
        uint256 _nftId,
        address _isolationPool
    )
        external
        view
        returns (bool);

    function calculateLendingShares(
        address _poolToken,
        uint256 _amount
    )
        external
        view
        returns (uint256);

    function corePaybackLiquidation(
        address _poolToken,
        uint256 _nftId,
        uint256 _amount,
        uint256 _shares
    )
        external;

    function decreaseCollateralLiquidation(
        uint256 _nftId,
        address _poolToken,
        uint256 _amount
    )
        external;

    function decreaseTotalBareTokenLiquidation(
        address _poolToken,
        uint256 _amount
    )
        external;

    function positionPureCollateralAmount(
        uint256 _nftId,
        address _poolToken
    )
        external
        returns (uint256);

    function coreWithdrawLiquidation(
        address _poolToken,
        uint256 _nftId,
        uint256 _amount,
        uint256 _shares
    )
        external;

    function decreaseLendingSharesLiquidation(
        uint256 _nftId,
        address _poolToken,
        uint256 _shares
    )
        external;

    function increaseLendingSharesLiquidation(
        uint256 _nftId,
        address _poolToken,
        uint256 _shares
    )
        external;

    function addPositionLendingTokenDataLiquidation(
        uint256 _nftId,
        address _poolToken
    )
        external;

    function getTotalPool(
        address _poolToken
    )
        external
        view
        returns (uint256);

    function depositExactAmount(
        uint256 _nftId,
        address _poolToken,
        uint256 _amount,
        bool _collateralState
    )
        external
        returns (uint256);

    function withdrawOnBehalfExactAmount(
        uint256 _nftId,
        address _poolToken,
        uint256 _amount
    )
        external
        returns (uint256);

    function syncManually(
        address _poolToken
    )
        external;

    function withdrawOnBehalfExactShares(
        uint256 _nftId,
        address _poolToken,
        uint256 _shares
    )
        external
        returns (uint256);

    function borrowOnBehalfExactAmount(
        uint256 _nftId,
        address _poolToken,
        uint256 _amount
    )
        external
        returns (uint256);

    function solelyDepositExactAmount(
        uint256 _nftId,
        address _poolToken,
        uint256 _amount
    )
        external;

    function solelyWithdrawOnBehalfExactAmount(
        uint256 _nftId,
        address _poolToken,
        uint256 _amount
    )
        external;

    function paybackExactAmount(
        uint256 _nftId,
        address _poolToken,
        uint256 _amount
    )
        external
        returns (uint256);

    function paybackExactShares(
        uint256 _nftId,
        address _poolToken,
        uint256 _shares
    )
        external
        returns (uint256);

    function setPoolFee(
        address _poolToken,
        uint256 _newFee
    )
        external;

    function getPositionLendingShares(
        uint256 _nftId,
        address _poolToken
    )
        external
        view
        returns (uint256);

    function withdrawExactShares(
        uint256 _nftId,
        address _poolToken,
        uint256 _shares
    )
        external
        returns (uint256);

    function poolTokenAddresses()
        external
        returns (address[] memory);

    function corePaybackFeeMananger(
        address _poolToken,
        uint256 _nftId,
        uint256 _amount,
        uint256 _shares
    )
        external;

    function curveSecurityCheck(
        address _poolToken
    )
        external;

    function preparePool(
        address _poolToken
    )
        external;

    function getPositionBorrowTokenLength(
        uint256 _nftId
    )
        external
        view
        returns (uint256);

    function getPositionBorrowTokenByIndex(
        uint256 _nftId,
        uint256 _index
    )
        external
        view
        returns (address);

    function getPositionLendingTokenByIndex(
        uint256 _nftId,
        uint256 _index
    )
        external
        view
        returns (address);

    function getPositionLendingTokenLength(
        uint256 _nftId
    )
        external
        view
        returns (uint256);

    function globalPoolData(
        address _poolToken
    )
        external
        view
        returns (GlobalPoolEntry memory);


    function getGlobalBorrowAmount(
        address _token
    )
        external
        view
        returns (uint256);

    function getPseudoTotalBorrowAmount(
        address _token
    )
        external
        view
        returns (uint256);

    function getInitialBorrowAmountUser(
        address _user,
        address _token
    )
        external
        view
        returns (uint256);

    function getPseudoTotalPool(
        address _token
    )
        external
        view
        returns (uint256);

    function getInitialDepositAmountUser(
        address _user,
        address _token
    )
        external
        view
        returns (uint256);

    function getGlobalDepositAmount(
        address _token
    )
        external
        view
        returns (uint256);

    function paybackAmount(
        address _token,
        uint256 _shares
    )
        external
        view
        returns (uint256);

    function getPositionBorrowShares(
        address _user,
        address _token
    )
        external
        view
        returns (uint256);

    function getPositionLendingShares(
        address _user,
        address _token
    )
        external
        view
        returns (uint256);

    function cashoutAmount(
        address _token,
        uint256 _shares
    )
        external
        view
        returns (uint256);

    function getTotalDepositShares(
        address _token
    )
        external
        view
        returns (uint256);

    function getTotalBorrowShares(
        address _token
    )
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.19;

interface IFeeManager {

    function setBadDebtUserLiquidation(
        uint256 _nftId,
        uint256 _amount
    )
        external;

    function increaseTotalBadDebtLiquidation(
        uint256 _amount
    )
        external;

    function FEE_MASTER_NFT_ID()
        external
        returns (uint256);

    function addPoolTokenAddress(
        address _poolToken
    )
        external;
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.19;

interface IWiseOracleHub {

    function getTokensFromUSD(
        address _tokenAddress,
        uint256 _usdValue
    )
        external
        view
        returns (uint256);

    function getTokensInUSD(
        address _tokenAddress,
        uint256 _amount
    )
        external
        view
        returns (uint256);

    function chainLinkIsDead(
        address _tokenAddress
    )
        external
        view
        returns (bool);

    function getTokenUSDFiat(
        address _tokenAddress,
        uint256 _amount
    )
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.19;

interface IPositionNFTs {

    function ownerOf(
        uint256 _nftId
    )
        external
        view
        returns (address);

    function getOwner(
        uint256 _nftId
    )
        external
        view
        returns (address);


    function totalSupply()
        external
        view
        returns (uint256);

    function mintPosition()
        external;

    function tokenOfOwnerByIndex(
        address _owner,
        uint256 _index
    )
        external
        view
        returns (uint256);

    function mintPositionForUser(
        address _user
    )
        external
        returns (uint256);
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.19;

interface ICurve {

    function balanceOf(
        address _userAddress
    )
        external
        view
        returns (uint256);

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    )
        external
        view
        returns (uint256);

    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx
    )
        external
        view
        returns (uint256);

    function exchange(
        int128 fromIndex,
        int128 toIndex,
        uint256 exactAmountFrom,
        uint256 minReceiveAmount
    )
        external;

    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    )
        external;

    function remove_liquidity_one_coin(
        uint256 _burnAmount,
        int128 i,
        uint256 _minReceived
    )
        external;

    function coins(
        uint256 arg0
    )
        external
        view
        returns (address);

    function decimals()
        external
        view
        returns (uint8);

    function totalSupply()
        external
        view
        returns (uint256);

    function balances(
        uint256 arg0
    )
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.19;

interface IERC20 {

    function totalSupply()
        external
        view
        returns (uint256);

    function balanceOf(
        address _account
    )
        external
        view
        returns (uint256);

    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    )
        external
        returns (bool);

    function transfer(
        address _recipient,
        uint256 _amount
    )
        external
        returns (bool);

    function allowance(
        address owner,
        address spender
    )
        external
        view
        returns (uint256);

    function approve(
        address _spender,
        uint256 _amount
    )
        external;
        // returns (bool);

    function decimals()
        external
        view
        returns (uint8);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.19;

import './Declarations.sol';
import "../TransferHub/TransferHelper.sol";

abstract contract WiseLiquidationHelper is Declarations, TransferHelper {

    function _coreLiquidation(
        uint256 _nftId,
        uint256 _nftIdLiquidator,
        address _caller,
        address _tokenToPayback,
        address _tokenToRecieve,
        uint256 _paybackAmount,
        uint256 _shareAmountToPay,
        uint256 _baseRewardLiquidation
    )
        internal
        returns (uint256 receiveAmount)
    {
        uint256 paybackUSD = WISE_ORACLE.getTokensInUSD(
            _tokenToPayback,
            _paybackAmount
        );

        uint256 feeUSD = checkMaxFee(
            paybackUSD,
            _baseRewardLiquidation
        );

        uint256 collateralPercenage = calculateWishPercentage(
            _nftId,
            _tokenToRecieve,
            paybackUSD,
            feeUSD
        );

        if (collateralPercenage > PRECISION_FACTOR_E18) {
            revert CollateralTooSmall();
        }

        WISE_LENDING.corePaybackLiquidation(
            _tokenToPayback,
            _nftId,
            _paybackAmount,
            _shareAmountToPay
        );

        receiveAmount = _calculateReceiveAmount(
            _nftId,
            _nftIdLiquidator,
            _tokenToRecieve,
            collateralPercenage
        );

        WISE_SECURITY.checkBadDebt(
            _nftId
        );

        _safeTransferFrom(
            _tokenToPayback,
            _caller,
            address(WISE_LENDING),
            _paybackAmount
        );

        _safeTransferFrom(
            _tokenToRecieve,
            address(WISE_LENDING),
            _caller,
            receiveAmount
        );
    }

    function calculateWishPercentage( // @TODO prob percents going away
        uint256 _nftId,
        address _receiveTokens, // rename
        uint256 _paybackUSD,
        uint256 _feeUSD
    )
        public
        view
        returns (uint256)
    {
        return (_feeUSD + _paybackUSD)
            * PRECISION_FACTOR_E18
            / WISE_SECURITY.getCollateralOfTokenUSD(
                _nftId,
                _receiveTokens
            );
    }

    function _calculateReceiveAmount(
        uint256 _nftId,
        uint256 _nftIdLiquidator,
        address _receiveTokens,
        uint256 _removePercentage
    )
        internal
        returns (uint256 receiveAmount)
    {
        receiveAmount = _withdrawPureCollateralLiquidation(
            _nftId,
            _receiveTokens,
            _removePercentage
        );

        if (WISE_LENDING.getCollateralState(_nftId, _receiveTokens) == false) {
            return receiveAmount;
        }

        receiveAmount += _withdrawOrAllocateSharesLiquidation(
            _nftId,
            _nftIdLiquidator,
            _receiveTokens,
            _removePercentage
        );
    }

    function _withdrawPureCollateralLiquidation(
        uint256 _nftId,
        address _poolToken,
        uint256 _percentLiquidation
    )
        internal
        returns (uint256 transfereAmount)
    {
        transfereAmount = _percentLiquidation
            * WISE_LENDING.positionPureCollateralAmount(
                _nftId,
                _poolToken
            )
            / PRECISION_FACTOR_E18;

        WISE_LENDING.decreaseCollateralLiquidation(
            _nftId,
            _poolToken,
            transfereAmount
        );

        WISE_LENDING.decreaseTotalBareTokenLiquidation(
            _poolToken,
            transfereAmount
        );
    }

    function _withdrawOrAllocateSharesLiquidation(
        uint256 _nftId,
        uint256 _nftIdLiquidator,
        address _poolToken,
        uint256 _percantageWishCollat
    )
        internal
        returns (uint256)
    {
        (
            uint256 cashoutAmount,
            uint256 cashoutShares
        )
        = _getTokenCollateralAndShares(
            _nftId,
            _poolToken,
            _percantageWishCollat
        );

        uint256 totalPoolToken = WISE_LENDING.getTotalPool(
            _poolToken
        );

        //Case 1: Current Pool has enough Liquid tokens to pay out the liquidator
        if (_checkTotalPool(cashoutAmount, totalPoolToken)) {

            WISE_LENDING.coreWithdrawLiquidation(
                _poolToken,
                _nftId,
                cashoutAmount,
                cashoutShares
            );

            return cashoutAmount;
        }

        uint256 totalPoolInShares = _calcSharesFromTotalPool(
            _poolToken,
            totalPoolToken
        );

        uint256 shareDifference = cashoutShares - totalPoolInShares;

        WISE_LENDING.coreWithdrawLiquidation(
            _poolToken,
            _nftId,
            totalPoolToken,
            totalPoolInShares
        );

        WISE_LENDING.decreaseLendingSharesLiquidation(
            _nftId,
            _poolToken,
            shareDifference
        );

        WISE_LENDING.increaseLendingSharesLiquidation(
            _nftIdLiquidator,
            _poolToken,
            shareDifference
        );

        WISE_LENDING.addPositionLendingTokenDataLiquidation(
            _nftId,
            _poolToken
        );

        return totalPoolToken;
    }

    function _calcSharesFromTotalPool(
        address _poolToken,
        uint256 _totalPoolToken
    )
        internal
        view
        returns (uint256)
    {
        return _totalPoolToken
            * WISE_LENDING.getTotalDepositShares(_poolToken)
            / WISE_LENDING.getPseudoTotalPool(_poolToken);
    }

    function _checkTotalPool(
        uint256 _cashoutAmount,
        uint256 _totalPoolToken
    )
        internal
        pure
        returns (bool)
    {
        return _cashoutAmount <= _totalPoolToken;
    }

    function _getTokenCollateralAndShares(
        uint256 _nftId,
        address _poolToken,
        uint256 _percantageWishCollat
    )
        internal
        view
        returns (uint256, uint256)
    {
        uint256 userPortionShares = _percantageWishCollat
            * WISE_LENDING.getPositionLendingShares(
                _nftId,
                _poolToken
            )
            / PRECISION_FACTOR_E18;

        uint256 cashoutAmount = WISE_LENDING.cashoutAmount(
            _poolToken,
            userPortionShares
        );

        return (cashoutAmount, userPortionShares);
    }

    function checkMaxFee(
        uint256 _paybackUSD,
        uint256 _liquidationFee
    )
        public
        pure
        returns (uint256)
    {
        uint256 feeUSD = _paybackUSD
            * _liquidationFee
            / PRECISION_FACTOR_E18;

        return feeUSD < MAX_USD_LIQUIDATION_FEE
            ? feeUSD
            : MAX_USD_LIQUIDATION_FEE;
    }

    function _prepareCollaterals(
        uint256 _nftId
    )
        internal
    {
        for (uint256 i = 0; i < WISE_LENDING.getPositionLendingTokenLength(_nftId); i++) {

            address currentAddress = WISE_LENDING.getPositionLendingTokenByIndex(
                _nftId,
                i
            );

            WISE_LENDING.curveSecurityCheck(
                currentAddress
            );

            WISE_LENDING.preparePool(
                currentAddress
            );
        }
    }

    function _prepareBorrows(
        uint256 _nftId
    )
        internal
    {
        for (uint256 i = 0; i < WISE_LENDING.getPositionBorrowTokenLength(_nftId); i++) {

            address currentAddress = WISE_LENDING.getPositionBorrowTokenByIndex(
                _nftId,
                i
            );

            WISE_LENDING.curveSecurityCheck(
                currentAddress
            );

            WISE_LENDING.preparePool(
                currentAddress
            );
        }
    }
}

// SPDX-License-Identifier: -- WISE --
pragma solidity =0.8.19;

import "./DeclarationsFeeManager.sol";
import "../TransferHub/TransferHelper.sol";

abstract contract FeeManagerHelper is DeclarationsFeeManager, TransferHelper {

    // @TODO we have duplicate?
    function _prepareBorrows(
        uint256 _nftId
    )
        internal
    {
        for (uint256 i = 0; i < WISE_LENDING.getPositionBorrowTokenLength(_nftId); i++) {

            address currentAddress = WISE_LENDING.getPositionBorrowTokenByIndex(
                _nftId,
                i
            );

            WISE_LENDING.curveSecurityCheck(
                currentAddress
            );

            WISE_LENDING.preparePool(
                currentAddress
            );
        }
    }

    // @TODO we have duplicate?
    function _prepareCollaterals(
        uint256 _nftId
    )
        internal
    {
        for (uint256 i = 0; i < WISE_LENDING.getPositionLendingTokenLength(_nftId); i++) {

            address currentAddress = WISE_LENDING.getPositionLendingTokenByIndex(
                _nftId,
                i
            );

            WISE_LENDING.curveSecurityCheck(
                currentAddress
            );

            WISE_LENDING.preparePool(
                currentAddress
            );
        }
    }

    function _setBadDebtUser(
        uint256 _nftId,
        uint256 _amount
    )
        internal
    {
        badDebtPosition[_nftId] = _amount;
    }

    function _increaseTotalBadDebt(
        uint256 _amount
    )
        internal
    {
        totalBadDebtUSD += _amount;

        emit TotalBadDebtIncreased(
            _amount,
            block.timestamp
        );
    }

    function _decreaseTotalBadDebt(
        uint256 _amount
    )
        internal
    {
        totalBadDebtUSD -= _amount;

        emit TotalBadDebtDecreased(
            _amount,
            block.timestamp
        );
    }

    function _eraseBadDebtUser(
        uint256 _nftId
    )
        internal
    {
        badDebtPosition[_nftId] = 0;
    }

    function _updateUserBadDebt(
        uint256 _nftId
    )
        internal
    {
        uint256 currentBorrowUSD = WISE_SECURITY.overallUSDBorrow(
            _nftId
        );

        uint256 currentCollateralBareUSD = WISE_SECURITY.overallUSDCollateralsBare(
            _nftId
        );

        uint256 currentBadDebt = badDebtPosition[_nftId];

        if (currentBorrowUSD < currentCollateralBareUSD) {

            _eraseBadDebtUser(
                _nftId
            );

            _decreaseTotalBadDebt(
                currentBadDebt
            );

            emit UpdateBadDebtPosition(
                _nftId,
                0,
                block.timestamp
            );

            return;
        }

        uint256 newBadDebt = currentBorrowUSD
            - currentCollateralBareUSD;

        _setBadDebtUser(
            _nftId,
            newBadDebt
        );

        newBadDebt > currentBadDebt
            ? _increaseTotalBadDebt(newBadDebt - currentBadDebt)
            : _decreaseTotalBadDebt(currentBadDebt - newBadDebt);

        emit UpdateBadDebtPosition(
            _nftId,
            newBadDebt,
            block.timestamp
        );
    }

    function _increaseFeeTokens(
        address _poolToken,
        uint256 _amount
    )
        internal
    {
        feeTokens[_poolToken] += _amount;
    }

    function _decreaseFeeTokens(
        address _poolToken,
        uint256 _amount
    )
        internal
    {
        feeTokens[_poolToken] -= _amount;
    }

    function _setAllowedTokens(
        address _user,
        address _poolToken,
        bool _state
    )
        internal
    {
        allowedTokens[_user][_poolToken] = _state;
    }

    function getReceivingToken(
        address _paybackToken,
        address _receivingToken,
        uint256 _paybackAmount
    )
        public
        returns (uint256 receivingAmount)
    {
        uint256 paybackUSD = ORACLE_HUB.getTokensInUSD(
            _paybackToken,
            _paybackAmount
        );

        totalBadDebtUSD -= paybackUSD;

        receivingAmount = PAYBACK_INCENTIVE
            * ORACLE_HUB.getTokensFromUSD(
                _receivingToken,
                paybackUSD
            )
            / PRECISION_FACTOR_E18 ;
    }

    function updatePositionCurrentBadDebt(
        uint256 _nftId
    )
        public
    {
        _prepareCollaterals(
            _nftId
        );

        _prepareBorrows(
            _nftId
        );

        _updateUserBadDebt(
            _nftId
        );
    }

    function _distributeIncentives(
        uint256 _amount,
        address _poolToken
    )
        internal
        returns (uint256)
    {
        uint256 reduceAmount;

        if (incentiveUSD[incentiveOwnerA] != 0) {

            reduceAmount += _gatherIncentives(
                _poolToken,
                incentiveOwnerA,
                _amount
            );
        }

        if (incentiveUSD[incentiveOwnerB] != 0) {

            reduceAmount += _gatherIncentives(
                _poolToken,
                incentiveOwnerB,
                _amount
            );
        }

        return _amount - reduceAmount;
    }

    function _gatherIncentives(
        address _poolToken,
        address _incentiveOwner,
        uint256 _amount
    )
        internal
        returns (uint256 )
    {
        uint256 incentiveAmount = _amount
            * INCENTIVE_PORTION
            / WISE_LENDING.globalPoolData(_poolToken).poolFee;

        uint256 usdEquivalent = ORACLE_HUB.getTokensInUSD(
            _poolToken,
            incentiveAmount
        );

        uint256 openUSD = usdEquivalent < incentiveUSD[_incentiveOwner]
            ? usdEquivalent
            : incentiveUSD[_incentiveOwner];

        if (openUSD == usdEquivalent) {

            incentiveUSD[_incentiveOwner] -= usdEquivalent;
            gatheredIncentiveToken[_incentiveOwner][_poolToken] += incentiveAmount;

            return incentiveAmount;
        }

        incentiveAmount = ORACLE_HUB.getTokensFromUSD(
            _poolToken,
            openUSD
        );

        incentiveUSD[_incentiveOwner] = 0;
        gatheredIncentiveToken[_incentiveOwner][_poolToken] += incentiveAmount;

        return incentiveAmount;
    }
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.19;

import "../InterfaceHub/IERC20.sol";

contract TransferHelper {

    /**
     * @dev
     * Allows to execute transfer for a token
     */
    function _safeTransfer(
        address _token,
        address _to,
        uint256 _value
    )
        internal
    {
        IERC20 token = IERC20(
            _token
        );

        _callOptionalReturn(
            _token,
            abi.encodeWithSelector(
                token.transfer.selector,
                _to,
                _value
            )
        );
    }

    /**
     * @dev
     * Allows to execute transferFrom for a token
     */
    function _safeTransferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _value
    )
        internal
    {
        IERC20 token = IERC20(
            _token
        );

        _callOptionalReturn(
            _token,
            abi.encodeWithSelector(
                token.transferFrom.selector,
                _from,
                _to,
                _value
            )
        );
    }

    /**
     * @dev
     * Helper function to do the token call
     */
    function _callOptionalReturn(
        address _token,
        bytes memory _data
    )
        private
    {
        (
            bool success,
            bytes memory returndata
        ) = _token.call(_data);

        require(
            success,
            "TransferHelper: CALL_FAILED"
        );

        if (returndata.length > 0) {
            require(
                abi.decode(
                    returndata,
                    (bool)
                ),
                "TransferHelper: OPERATION_FAILED"
            );
        }
    }
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.19;

import "../InterfaceHub/IWiseLending.sol";
import "../InterfaceHub/IWiseSecurity.sol";
import "../InterfaceHub/IWiseOracleHub.sol";

error LiquidationDenied();
error TooManyShares();
error TransferFromFailed();
error TransferFailed();
error CollateralTooSmall();

contract Declarations {

    event LiquidatedPartiallyFromTokens(
        uint256 indexed nftId,
        address indexed liquidator,
        address tokenPayback,
        address tokenReceived,
        uint256 indexed shares,
        uint256 timestamp
    );

    uint256 constant PRECISION_FACTOR_E18 = 1 ether;
    uint256 constant MAX_LIQUIDATION_50 = 0.5 ether ;
    uint256 constant BAD_DEBT_THRESHOLD = 0.89 ether;
    uint256 constant public BASE_REWARD_LIQUIDATION_WISE_LENDING = 0.1 ether;
    uint256 constant public BASE_REWARD_LIQUIDATION_ISOLATION_POOL = 0.03 ether;
    uint256 constant public MAX_USD_LIQUIDATION_FEE = 500 ether;

    IWiseLending public immutable WISE_LENDING;
    IWiseSecurity public immutable WISE_SECURITY;
    IWiseOracleHub public immutable WISE_ORACLE;

    constructor(
        address _wiseLendingAddress,
        address _oracleHubAddress,
        address _wiseSecurityAddress
    ) {
        WISE_ORACLE = IWiseOracleHub(
            _oracleHubAddress
        );

        WISE_LENDING = IWiseLending(
            _wiseLendingAddress
        );

        WISE_SECURITY = IWiseSecurity(
            _wiseSecurityAddress
        );
    }
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.19;

import "../InterfaceHub/IERC20.sol";
import "../InterfaceHub/IWiseLending.sol";
import "../InterfaceHub/IFeeManager.sol";
import "../InterfaceHub/IWiseSecurity.sol";
import "../InterfaceHub/IPositionNFTs.sol";
import "../InterfaceHub/IWiseOracleHub.sol";

import "./FeeManagerEvents.sol";

error NotWiseLiquidation();
error AlreadySet();
error ExistingBadDebt();
error TransferFromFailedFeeManager();
error TransferFailedFeeManager();
error NotWiseLending();
error NotAllowed();
error NotIncentiveMaster();
error PoolAlreadyAdded();
error TooHighValue();
error TooLowValue();

contract DeclarationsFeeManager is FeeManagerEvents {

    modifier onlyWiseSecurity() {
        _onlyWiseSecurity();
        _;
    }

    modifier onlyWiseLending() {
        _onlyWiseLending();
        _;
    }

    modifier onlyMultisig {
        _onlyMultisig();
        _;
    }

    modifier onlyIncentiveMaster() {
        _onlyIncentiveMaster();
        _;
    }

    function _onlyIncentiveMaster()
        private
        view
    {
        if (msg.sender == incentiveMaster) {
            return;
        }

        revert NotIncentiveMaster();
    }

    function _onlyWiseSecurity()
        private
        view
    {
        if (msg.sender == address(WISE_SECURITY)) {
            return;
        }

        revert NotWiseLiquidation();
    }

    function _onlyWiseLending()
        private
        view
    {
        if (msg.sender == address(WISE_LENDING)) {
            return;
        }

        revert NotWiseLending();
    }

    function _onlyMultisig()
        private
        view
    {
        if (msg.sender == multisig) {
            return;
        }

        revert NotAllowed();
    }

    constructor(
        address _multisig,
        address _wiseLendingAddress,
        address _oracleHubAddress,
        address _wiseSecurityAddress,
        address _positionNFTAddress
    )
    {
        WISE_LENDING = IWiseLending(
            _wiseLendingAddress
        );

        ORACLE_HUB = IWiseOracleHub(
            _oracleHubAddress
        );

        WISE_SECURITY = IWiseSecurity(
            address(_wiseSecurityAddress)
        );

        POSITION_NFTS = IPositionNFTs(
            address(_positionNFTAddress)
        );

        POSITION_NFTS.mintPosition();

        FEE_MASTER_NFT_ID = POSITION_NFTS.tokenOfOwnerByIndex(
            address(this),
            0
        );

        multisig = _multisig;
        incentiveMaster = _multisig;

        incentiveOwnerA = 0xA7f676d112CA58a2e5045F22631A8388E9D7D8dE;
        incentiveOwnerB = 0x8f741ea9C9ba34B5B8Afc08891bDf53faf4B3FE7;

        incentiveUSD[incentiveOwnerA] = 220000 * PRECISION_FACTOR_E18;
        incentiveUSD[incentiveOwnerB] = 220000 * PRECISION_FACTOR_E18;
    }

    IWiseLending immutable public WISE_LENDING;
    IPositionNFTs immutable public POSITION_NFTS;
    IWiseSecurity immutable public WISE_SECURITY;
    IWiseOracleHub immutable public ORACLE_HUB;

    uint256 immutable public FEE_MASTER_NFT_ID;

    address public multisig;
    address public incentiveMaster;
    uint256 public totalBadDebtUSD;
    address[] public poolTokenAddresses;

    address public renouncedIncentiveMaster;

    address public incentiveOwnerA;
    address public incentiveOwnerB;

    mapping (uint256 => uint256) public badDebtPosition;
    mapping (address => uint256) public feeTokens;
    mapping (address => uint256) public incentiveUSD;
    mapping (address => bool) public poolTokenAdded;

    mapping (address => mapping (address => bool)) public allowedTokens;
    mapping (address => mapping (address => uint256)) public gatheredIncentiveToken;

    address constant ZERO_ADDRESS = address(0);

    uint256 constant PRECISION_FACTOR_E16 = 0.01 ether;
    uint256 constant PRECISION_FACTOR_E18 = 1 ether;
    uint256 constant HUGE_AMOUNT = type(uint256).max;
    uint256 constant public PAYBACK_INCENTIVE = 1.05 ether;
    uint256 constant public INCENTIVE_PORTION = 0.005 ether;
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.19;

struct curveSwapStruct {
    uint256 curvePoolTokenIndexFrom;
    uint256 curvePoolTokenIndexTo;
    uint256 curveMetaPoolTokenIndexFrom;
    uint256 curveMetaPoolTokenIndexTo;
    uint256 curvePoolSwapAmount;
    uint256 curveMetaPoolSwapAmount;
}

interface IWiseSecurity {

    function checkBadDebt(
        uint256 _nftId
    )
        external;

    function getCollateralOfTokenUSD(
        uint256 _nftId,
        address _poolToken
    )
        external
        view
        returns (uint256);

    function checksLiquidation(
        uint256 _nftIdLiquidate,
        address _caller,
        address _tokenToPayback,
        uint256 _shareAmountToPay
    )
        external
        view;

    function onlyIsolationPool(
        address _poolAddress
    )
        external
        view;

    function overallUSDBorrow(
        uint256 _nftId
    )
        external
        view
        returns (uint256);

    function overallUSDCollateralsBare(
        uint256 _nftId
    )
        external
        view
        returns (uint256 amount);

    function checkRegisteredForPool(
        uint256 _nftId,
        address _isolationPool
    )
        external
        view;

    function FEE_MANAGER()
        external
        returns (address);

    function WISE_LIQUIDATION()
        external
        returns (address);

    function curveSecurityCheck(
        address _poolAddress
    )
        external;

    function prepareCurvePools(
        address _poolToken,
        address _curvePool,
        address _curveMetaPool,
        curveSwapStruct memory _curveSwapStruct
    )
        external;

    function setUnderlyingPoolTokensFromPoolToken(
        address _poolToken,
        address[] memory _underlyingTokens
    )
        external;

    function checksDeposit(
        uint256 _nftId,
        address _caller,
        address _poolToken,
        uint256 _amount
    )
        external
        view;

    function checksWithdraw(
        uint256 _nftId,
        address _caller,
        address _poolToken,
        uint256 _amount
    )
        external
        view;

    function checksBorrow(
        uint256 _nftId,
        address _caller,
        address _poolToken,
        uint256 _amount
    )
        external
        view;

    function checksSolelyWithdraw(
        uint256 _nftId,
        address _caller,
        address _poolToken,
        uint256 _amount
    )
        external
        view;

    function checkOwnerPosition(
        uint256 _nftId,
        address _caller
    )
        external
        view;

    function checksCollateralizeDeposit(
        uint256 _nftIdCaller,
        address _caller,
        address _poolAddress
    )
        external
        view;

    function checksDecollateralizeDeposit(
        uint256 _nftIdCaller,
        address _caller,
        address _poolToken
    )
        external
        view;

    function checkBorrowLimit(
        uint256 _nftId,
        address _poolToken,
        uint256 _amount
    )
        external
        view;

    function checkPositionLocked(
        uint256 _nftId,
        address _caller
    )
        external
        view;

    function checkPaybackLendingShares(
        uint256 _nftIdReceiver,
        uint256 _nftIdCaller,
        address _caller,
        address _poolToken,
        uint256 _amount
    )
        external
        view;

    function checksRegistrationIsolationPool(
        uint256 _nftId,
        address _caller,
        address _isolationPool
    )
        external
        view;

    function checkUnregister(
        uint256 _nftId,
        address _caller
    )
        external
        view;

    function checkOnlyMaster(
        address _caller
    )
        external
        view;
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.19;

contract FeeManagerEvents {

    event PoolTokenAdded(
        address poolToken,
        uint256 timestamp
    );

    event BadDebtIncreasedLiquidation(
        uint256 amount,
        uint256 timestamp
    );

    event TotalBadDebtIncreased(
        uint256 amount,
        uint256 timestamp
    );

    event TotalBadDebtDecreased(
        uint256 amount,
        uint256 timestamp
    );

    event SetBadDebtPosition(
        uint256 nftId,
        uint256 amount,
        uint256 timestamp
    );

    event UpdateBadDebtPosition(
        uint256 nftId,
        uint256 newAmount,
        uint256 timestamp
    );

    event SetBeneficial(
        address user,
        address[] token,
        uint256 timestamp
    );

    event RevokeBeneficial(
        address user,
        address[] token,
        uint256 timestamp
    );

    event ClaimedFeesWise(
        address token,
        uint256 amount,
        uint256 timestamp
    );

    event ClaimedFeesBeneficial(
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 indexed timestamp
    );

    event PayedBackBadDebt(
        uint256 nftId,
        address indexed sender,
        address paybackToken,
        address receivingToken,
        uint256 indexed paybackAmount,
        uint256 timestamp
    );

    event PayedBackBadDebtFree(
        uint256 nftId,
        address indexed sender,
        address paybackToken,
        uint256 indexed paybackAmount,
        uint256 timestampp
    );
}