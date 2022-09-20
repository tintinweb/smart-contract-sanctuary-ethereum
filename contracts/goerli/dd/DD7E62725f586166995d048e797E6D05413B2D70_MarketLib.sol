// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

library MarketLib {
    ///EVENTS
    event MarketInitialized(uint256 marketId);
    event OpenDispute(address indexed creator);
    event CloseMarket(MarketLib.ResultType result);
    event Verify(
        address indexed verifier,
        uint256 power,
        uint256 verificationId,
        uint256 tokenId,
        bool side
    );
    event WithdrawReward(
        address indexed receiver,
        uint256 indexed rewardType,
        uint256 amount
    );
    event Predict(address indexed sender, bool side, uint256 amount);

    //STRUCTS
    /// @notice Market closing types
    enum ResultType {
        NULL,
        AWON,
        BWON,
        DRAW,
        INVALID
    }

    struct Verification {
        /// @notice Address of verifier
        address verifier;
        /// @notice Verficaton power
        uint256 power;
        /// @notice Token id used for verification
        uint256 tokenId;
        /// @notice Verification side (true - positive / false - negative)
        bool side;
        /// @notice Is reward + staked token withdrawn
        bool withdrawn;
    }

    struct Market {
        /// @notice Predctioons token pool for positive result
        uint256 sideA;
        /// @notice Predictions token pool for negative result
        uint256 sideB;
        /// @notice Verification power for positive result
        uint256 verifiedA;
        /// @notice Verification power for positive result
        uint256 verifiedB;
        /// @notice Dispute Creator address
        address disputeCreator;
        /// @notice End predictions unix timestamp
        uint64 endPredictionTimestamp;
        /// @notice Start verifications unix timestamp
        uint64 startVerificationTimestamp;
        /// @notice Market result
        ResultType result;
        /// @notice Wrong result confirmed by HG
        bool confirmed;
        /// @notice Dispute solved by HG
        bool solved;
    }

    /// FUNCTIONS
    /// @dev Checks if one side of the market is fully verified
    /// @param m Market info
    /// @return 0 true if verified
    function _isVerified(Market memory m) internal pure returns (bool) {
        return (((m.sideA <= m.verifiedB) && m.sideA != 0) || ((m.sideB <= m.verifiedA) && m.sideB != 0));
    }

    /// @notice Checks if one side of the market is fully verified
    /// @param m Market info
    /// @return 0 true if verified
    function isVerified(Market memory m) external pure returns (bool) {
        return _isVerified(m);
    }

    /// @notice Returns the maximum value(power) available for verification for side
    /// @param m Market info
    /// @param side Side of market (true/false)
    /// @return 0 Maximum amount to verify for side
    function maxAmountToVerifyForSide(Market memory m, bool side)
        external
        pure
        returns (uint256)
    {
        return (_maxAmountToVerifyForSide(m, side));
    }

    /// @dev Returns the maximum value(power) available for verification for side
    /// @param m Market info
    /// @param side Side of market (true/false)
    /// @return 0 Maximum amount to verify for side
    function _maxAmountToVerifyForSide(Market memory m, bool side)
        internal
        pure
        returns (uint256)
    {
        if (_isVerified(m)) {
            return 0;
        }

        if (side) {
            return m.sideB - m.verifiedA;
        } else {
            return m.sideA - m.verifiedB;
        }
    }

    ///@dev Returns prediction reward in ForeToken
    ///@param m Market Info
    ///@param pA Prediction contribution for side A
    ///@param pA Prediction contribution for side B
    ///@param feesSum Sum of all fees im perc
    ///@return toWithdraw amount to withdraw
    function calculatePredictionReward(
        Market memory m,
        uint256 pA,
        uint256 pB,
        uint256 feesSum
    ) internal pure returns (uint256 toWithdraw) {
        if(m.result == ResultType.INVALID){
            return pA+pB;
        }
        uint256 fullMarketSize = m.sideA + m.sideB;
        uint256 _marketSubFee = fullMarketSize -
            (fullMarketSize * feesSum) /
            10000;
        if (m.result == MarketLib.ResultType.DRAW) {
            toWithdraw = (_marketSubFee * (pA + pB)) / fullMarketSize;
        } else if (m.result == MarketLib.ResultType.AWON) {
            toWithdraw = (_marketSubFee * pA) / m.sideA;
        } else if (m.result == MarketLib.ResultType.BWON) {
            toWithdraw = (_marketSubFee * pB) / m.sideB;
        }
    }

    ///@notice Calculates Result for market
    ///@param m Market Info
    ///@return 0 Type of result
    function calculateMarketResult(Market memory m)
        external
        pure
        returns (ResultType)
    {
        return _calculateMarketResult(m);
    }

    ///@dev Calculates Result for market
    ///@param m Market Info
    ///@return 0 Type of result
    function _calculateMarketResult(Market memory m)
        internal
        pure
        returns (ResultType)
    {
        if(m.sideA == 0 || m.sideB == 0){
            return ResultType.INVALID;
        } else if (m.verifiedA == m.verifiedB) {
            return ResultType.DRAW;
        } else if (m.verifiedA > m.verifiedB) {
            return ResultType.AWON;
        } else {
            return ResultType.BWON;
        }
    }

    /// @notice initiates market
    /// @param market Market storage
    /// @param predictionsA Storage of predictionsA
    /// @param predictionsB Storage of predictionsB
    /// @param receiver Init prediction(s) creator
    /// @param amountA Init size of side A
    /// @param amountB Init size of side B
    /// @param endPredictionTimestamp End Prediction Unix Timestamp
    /// @param startVerificationTimestamp Start Verification Unix Timestamp
    /// @param tokenId mNFT token id
    function init(
        Market storage market,
        mapping(address => uint256) storage predictionsA,
        mapping(address => uint256) storage predictionsB,
        address receiver,
        uint256 amountA,
        uint256 amountB,
        uint64 endPredictionTimestamp,
        uint64 startVerificationTimestamp,
        uint256 tokenId
    ) external {
        market.endPredictionTimestamp = endPredictionTimestamp;
        market.startVerificationTimestamp = startVerificationTimestamp;
        if (amountA != 0) {
            _predict(
                market,
                predictionsA,
                predictionsB,
                amountA,
                true,
                receiver
            );
        }
        if (amountB != 0) {
            _predict(
                market,
                predictionsA,
                predictionsB,
                amountB,
                false,
                receiver
            );
        }

        emit MarketInitialized(tokenId);
    }

    /// @notice Add new prediction
    /// @param market Market storage
    /// @param predictionsA Storage of predictionsA
    /// @param predictionsB Storage of predictionsB
    /// @param amount Amount of ForeToken
    /// @param side Predicition side (true - positive result, false - negative result)
    /// @param receiver Prediction creator
    function predict(
        Market storage market,
        mapping(address => uint256) storage predictionsA,
        mapping(address => uint256) storage predictionsB,
        uint256 amount,
        bool side,
        address receiver
    ) external {
        _predict(market, predictionsA, predictionsB, amount, side, receiver);
    }

    /// @dev Add new prediction
    /// @param market Market storage
    /// @param predictionsA Storage of predictionsA
    /// @param predictionsB Storage of predictionsB
    /// @param amount Amount of ForeToken
    /// @param side Predicition side (true - positive result, false - negative result)
    /// @param receiver Prediction creator
    function _predict(
        Market storage market,
        mapping(address => uint256) storage predictionsA,
        mapping(address => uint256) storage predictionsB,
        uint256 amount,
        bool side,
        address receiver
    ) internal {
        if (amount == 0) {
            revert ("AmountCantBeZero");
        }

        MarketLib.Market memory m = market;

        if (block.timestamp >= m.endPredictionTimestamp) {
            revert ("PredictionPeriodIsAlreadyClosed");
        }

        if (side) {
            market.sideA += amount;
            predictionsA[receiver] += amount;
        } else {
            market.sideB += amount;
            predictionsB[receiver] += amount;
        }

        emit Predict(receiver, side, amount);
    }

    /// @dev Verifies the side with maximum available power
    /// @param market Market storage
    /// @param verifications Verifications array storage
    /// @param verifier Verification creator
    /// @param verificationPeriod Verification Period is sec
    /// @param power Power of vNFT
    /// @param tokenId vNFT token id
    /// @param side Marketd side (true - positive / false - negative);
    function _verify(
        Market storage market,
        Verification[] storage verifications,
        address verifier,
        uint256 verificationPeriod,
        uint256 power,
        uint256 tokenId,
        bool side
    ) internal {
        MarketLib.Market memory m = market;
        if (block.timestamp < m.startVerificationTimestamp) {
            revert ("VerificationHasNotStartedYet");
        }
        uint256 verificationEndTime = m.startVerificationTimestamp +
            verificationPeriod;
        if (block.timestamp > verificationEndTime) {
            revert ("VerificationAlreadyClosed");
        }

        if (side) {
            market.verifiedA += power;
        } else {
            market.verifiedB += power;
        }

        uint256 verifyId = verifications.length;

        verifications.push(Verification(verifier, power, tokenId, side, false));

        emit Verify(verifier, power, verifyId, tokenId, side);
    }

    /// @notice Verifies the side with maximum available power
    /// @param market Market storage
    /// @param verifications Verifications array storage
    /// @param verifier Verification creator
    /// @param verificationPeriod Verification Period is sec
    /// @param power Power of vNFT
    /// @param tokenId vNFT token id
    /// @param side Marketd side (true - positive / false - negative);
    function verify(
        Market storage market,
        Verification[] storage verifications,
        address verifier,
        uint256 verificationPeriod,
        uint256 power,
        uint256 tokenId,
        bool side
    ) external {
        MarketLib.Market memory m = market;
        uint256 powerAvailable = _maxAmountToVerifyForSide(m, side);
        if (powerAvailable == 0) {
            revert ("MarketIsFullyVerified");
        }
        if (power > powerAvailable) {
            power = powerAvailable;
        }
        _verify(
            market,
            verifications,
            verifier,
            verificationPeriod,
            power,
            tokenId,
            side
        );
    }

    /// @notice Opens a dispute
    /// @param market Market storage
    /// @param disputePeriod Dispute period in seconds
    /// @param verificationPeriod Verification Period in seconds
    /// @param creator Dispute creator
    function openDispute(
        Market storage market,
        uint256 disputePeriod,
        uint256 verificationPeriod,
        address creator
    ) external {
        Market memory m = market;

        if (
            block.timestamp <
            m.startVerificationTimestamp + verificationPeriod &&
            !_isVerified(m)
        ) {
            revert ("DisputePeriodIsNotStartedYet");
        }

        if (
            block.timestamp >=
            m.startVerificationTimestamp + verificationPeriod + disputePeriod
        ) {
            revert ("DisputePeriodIsEnded");
        }

        if (m.disputeCreator != address(0)) {
            revert ("DisputeAlreadyExists");
        }

        market.disputeCreator = creator;
        emit OpenDispute(creator);
    }

    /// @notice Resolves a dispute
    /// @param market Market storage
    /// @param result Result type
    /// @param highGuard High Guard address
    /// @param requester Function rerquester address
    /// @return receiverAddress Address receives dispute creration tokens
    function resolveDispute(
        Market storage market,
        MarketLib.ResultType result,
        address highGuard,
        address requester
    ) external returns (address receiverAddress) {
        if (highGuard != requester) {
            revert ("HighGuardOnly");
        }
        if (result == MarketLib.ResultType.NULL) {
            revert ("ResultCantBeNull");
        }
        MarketLib.Market memory m = market;
        if (m.disputeCreator == address(0)) {
            revert ("DisputePeriodIsNotStartedYet");
        }

        if (m.solved) {
            revert ("DisputeAlreadySolved");
        }

        market.solved = true;

        if (_calculateMarketResult(m) != result) {
            market.confirmed = true;
            return (m.disputeCreator);
        } else {
            return (requester);
        }
    }

    /// @notice Resolves a dispute
    /// @param market Market storage
    /// @param burnFee Burn fee
    /// @param verificationFee Verification Fee
    /// @param foundationFee Foundation Fee
    /// @param result Result type
    /// @return toBurn Token to burn
    /// @return toFoundation Token to foundation
    /// @return toHighGuard Token to HG
    /// @return toDisputeCreator Token to dispute creator
    /// @return disputeCreator Dispute creator address
    function closeMarket(
        Market storage market,
        uint256 burnFee,
        uint256 verificationFee,
        uint256 foundationFee,
        MarketLib.ResultType result
    )
        external
        returns (
            uint256 toBurn,
            uint256 toFoundation,
            uint256 toHighGuard,
            uint256 toDisputeCreator,
            address disputeCreator
        )
    {
        Market memory m = market;
        if (m.result != ResultType.NULL) {
            revert ("MarketIsClosed");
        }
        market.result = result;
        m.result = result;
        emit CloseMarket(m.result);

        uint256 fullMarketSize = m.sideA + m.sideB;
        toBurn = (fullMarketSize * burnFee) / 10000;
        uint256 toVerifiers = (fullMarketSize * verificationFee) / 10000;
        toFoundation = (fullMarketSize * foundationFee) / 10000;
        if (
            m.result ==  MarketLib.ResultType.INVALID
        ){
            return(0, 0, 0, 0, m.disputeCreator);
        }
        if (
            m.result == MarketLib.ResultType.DRAW &&
            m.disputeCreator != address(0) &&
            !m.confirmed
        ) {
            // draw with dispute rejected - result set to draw
            toBurn += toVerifiers / 2;
            toHighGuard = toVerifiers / 2;
        } else if (m.result == MarketLib.ResultType.DRAW && m.confirmed) {
            // dispute confirmed - result set to draw
            toHighGuard = toVerifiers / 2;
            toDisputeCreator = toVerifiers - toHighGuard;
            disputeCreator = m.disputeCreator;
        }
    }

    /// @notice Check market status before closing
    /// @param m Market info
    /// @param verificationPeriod Verification Period
    /// @param disputePeriod Dispute Period
    function beforeClosingCheck(
        Market memory m,
        uint256 verificationPeriod,
        uint256 disputePeriod
    ) external view {
        if (m.disputeCreator != address(0)) {
            revert ("DisputeNotSolvedYet");
        }

        uint256 disputePeriodEnds = m.startVerificationTimestamp +
            verificationPeriod +
            disputePeriod;
        if (block.timestamp < disputePeriodEnds) {
            revert ("DisputePeriodIsNotEndedYet");
        }
    }

    /// @notice Withdraws Prediction Reward
    /// @param m Market info
    /// @param feesSum Sum of all fees
    /// @param predictionWithdrawn Storage of withdraw statuses
    /// @param predictionsA PredictionsA of predictor
    /// @param predictionsB PredictionsB of predictor
    /// @param predictor Predictor address
    /// @return 0 Amount to withdraw(transfer)
    function withdrawPredictionReward(
        Market memory m,
        uint256 feesSum,
        mapping(address => bool) storage predictionWithdrawn,
        uint256 predictionsA,
        uint256 predictionsB,
        address predictor
    ) external returns (uint256) {
        if (m.result == MarketLib.ResultType.NULL) {
            revert ("MarketIsNotClosedYet");
        }
        if (predictionWithdrawn[predictor]) {
            revert ("AlreadyWithdrawn");
        }

        predictionWithdrawn[predictor] = true;

        uint256 toWithdraw = calculatePredictionReward(
            m,
            predictionsA,
            predictionsB,
            feesSum
        );
        if (toWithdraw == 0) {
            revert ("NothingToWithdraw");
        }

        emit WithdrawReward(predictor, 1, toWithdraw);

        return toWithdraw;
    }

    /// @notice Calculates Verification Reward
    /// @param m Market info
    /// @param v Verification info
    /// @param power Power of vNFT used for verification
    /// @param verificationFee Verification Fee
    /// @return toVerifier Amount of tokens for verifier
    /// @return toDisputeCreator Amount of tokens for dispute creator
    /// @return toHighGuard Amount of tokens for HG
    /// @return vNftBurn If vNFT need to be burned
    function calculateVerificationReward(
        Market memory m,
        Verification memory v,
        uint256 power,
        uint256 verificationFee
    )
        public
        pure
        returns (
            uint256 toVerifier,
            uint256 toDisputeCreator,
            uint256 toHighGuard,
            bool vNftBurn
        )
    {
        if (m.result == MarketLib.ResultType.DRAW || m.result == MarketLib.ResultType.INVALID || m.result == MarketLib.ResultType.NULL || v.withdrawn) {
            // draw - withdraw verifier token
            return (0, 0, 0, false);
        }

        uint256 verificatorsFees = ((m.sideA + m.sideB) * verificationFee) /
            10000;
        if (v.side == (m.result == MarketLib.ResultType.AWON)) {
            // verifier voted properly
            uint256 reward = (v.power * verificatorsFees) /
                (v.side ? m.verifiedA : m.verifiedB);
            return (reward, 0, 0, false);
        } else {
            // verifier voted wrong
            if (m.confirmed) {
                toDisputeCreator = power / 2;
                toHighGuard = power - toDisputeCreator;
            }
            return (0, toDisputeCreator, toHighGuard, true);
        }
    }



    /// @notice Withdraws Verification Reward
    /// @param m Market info
    /// @param v Verification info
    /// @param power Power of vNFT used for verification
    /// @param verificationFee Verification Fee
    /// @return toVerifier Amount of tokens for verifier
    /// @return toDisputeCreator Amount of tokens for dispute creator
    /// @return toHighGuard Amount of tokens for HG
    /// @return vNftBurn If vNFT need to be burned
    function withdrawVerificationReward(
        Market memory m,
        Verification memory v,
        uint256 power,
        uint256 verificationFee
    )
        external
        returns (
            uint256 toVerifier,
            uint256 toDisputeCreator,
            uint256 toHighGuard,
            bool vNftBurn
        )
    {
        if (m.result == MarketLib.ResultType.NULL) {
            revert ("MarketIsNotClosedYet");
        }

        if (v.withdrawn) {
            revert ("AlreadyWithdrawn");
        }

        (toVerifier, toDisputeCreator, toHighGuard, vNftBurn) = calculateVerificationReward(m, v, power, verificationFee);

        if(toVerifier!=0){
            emit WithdrawReward(v.verifier, 2, toVerifier);
        }
    }
}