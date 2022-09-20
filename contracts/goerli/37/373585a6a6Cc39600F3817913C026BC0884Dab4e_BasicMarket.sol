// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../../IForeProtocol.sol";
import "../../../verifiers/IForeVerifiers.sol";
import "../../config/IProtocolConfig.sol";
import "../../config/IMarketConfig.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./library/MarketLib.sol";

contract BasicMarket
{

    /// @notice Market hash (ipfs hash without first 2 bytes)
    bytes32 public marketHash;

    /// @notice Market token id
    uint256 public marketId;

   /// @notice Protocol
    IForeProtocol public protocol;

    /// @notice Factory
    address public factory;

    /// @notice Protocol config
    IProtocolConfig public protocolConfig;

    /// @notice Market config
    IMarketConfig public marketConfig;

    /// @notice Verifiers NFT
    IForeVerifiers public foreVerifiers;

    /// @notice Fore Token
    IERC20Burnable public foreToken;

    /// @notice Market info
    MarketLib.Market internal _market;

    /// @notice Positive result predictions amount of address
    mapping(address => uint256) public predictionsA;

    /// @notice Negative result predictions amount of address
    mapping(address => uint256) public predictionsB;

    /// @notice Is prediction reward withdrawn for address
    mapping(address => bool) public predictionWithdrawn;

    /// @notice Verification info for verificatioon id
    MarketLib.Verification[] public verifications;

    bytes32 public disputeMessage;

    /// @notice Verification array size
    function verificationHeight() external view returns (uint256) {
        return verifications.length;
    }

    constructor() {
        factory = msg.sender;
    }

    /// @notice Returns market info
    function marketInfo() external view returns(MarketLib.Market memory){
        return _market;
    }

    /// @notice Initialization function
    /// @param mHash _market hash
    /// @param receiver _market creator nft receiver
    /// @param amountA initial prediction for side A
    /// @param amountB initial prediction for side B
    /// @param endPredictionTimestamp End Prediction Timestamp
    /// @param startVerificationTimestamp Start Verification Timestamp
    /// @param tokenId _market creator token id (ForeMarkets)
    /// @dev Possible to call only via the factory
    function initialize(
        bytes32 mHash,
        address receiver,
        uint256 amountA,
        uint256 amountB,
        address protocolAddress,
        uint64 endPredictionTimestamp,
        uint64 startVerificationTimestamp,
        uint64 tokenId
    ) external {
        if (msg.sender != address(factory)) {
            revert("BasicMarket: Only Factory");
        }

        protocol = IForeProtocol(protocolAddress);
        protocolConfig = IProtocolConfig(protocol.config());
        marketConfig = IMarketConfig(protocolConfig.marketConfig());
        foreToken = IERC20Burnable(protocol.foreToken());
        foreVerifiers = IForeVerifiers(protocol.foreVerifiers());

        marketHash = mHash;
        MarketLib.init(
            _market,
            predictionsA,
            predictionsB,
            receiver,
            amountA,
            amountB,
            endPredictionTimestamp,
            startVerificationTimestamp,
            tokenId
        );
        marketId = tokenId;

    }

    /// @notice Add new prediction
    /// @param amount Amount of ForeToken
    /// @param side Predicition side (true - positive result, false - negative result)
    function predict(uint256 amount, bool side) external {
        foreToken.transferFrom(msg.sender, address(this), amount);
        MarketLib.predict(
            _market,
            predictionsA,
            predictionsB,
            amount,
            side,
            msg.sender
        );
    }

    ///@notice Doing new verification
    ///@param tokenId vNFT token id
    ///@param side side of verification
    function verify(uint256 tokenId, bool side) external {
        if(
            foreVerifiers.ownerOf(tokenId)!= msg.sender){
            revert ("BasicMarket: Incorrect owner");
        }

        MarketLib.Market memory m = _market;

        if(m.sideA == 0 || m.sideB == 0){
            _closeMarket(MarketLib.ResultType.INVALID);
            return;
        }

        (uint256 verificationPeriod,) = marketConfig
            .periods();

        foreVerifiers.transferFrom(msg.sender, address(this), tokenId);

        MarketLib.verify(
            _market,
            verifications,
            msg.sender,
            verificationPeriod,
            foreVerifiers.powerOf(tokenId),
            tokenId,
            side
        );
    }

    /// @notice Opens dispute
    function openDispute(bytes32 messageHash) external {
        MarketLib.Market memory m = _market;
        if(m.sideA == 0 || m.sideB == 0){
            _closeMarket(MarketLib.ResultType.INVALID);
            return;
        }
        (
            uint256 disputePrice,
            uint256 disputePeriod,
            uint256 verificationPeriod,
            ,
            ,
            ,
        ) = marketConfig.config();
        foreToken.transferFrom(msg.sender, address(this), disputePrice);
        disputeMessage = messageHash;
        MarketLib.openDispute(
            _market,
            disputePeriod,
            verificationPeriod,
            msg.sender
        );
    }

    ///@notice Resolves Dispute
    ///@param result Dipsute result type
    ///@dev Only HighGuard
    function resolveDispute(MarketLib.ResultType result) external {
        address highGuard = protocolConfig.highGuard();
        address receiver = MarketLib.resolveDispute(
            _market,
            result,
            highGuard,
            msg.sender
        );
        foreToken.transfer(receiver, marketConfig.disputePrice());
        _closeMarket(result);
    }


    ///@dev Closes market
    ///@param result Market close result type
    ///Is not best optimized becouse of deep stack
    function _closeMarket(MarketLib.ResultType result) private {
        (uint256 burnFee, uint256 foundationFee, , ) = marketConfig.fees();
        (
            uint256 toBurn,
            uint256 toFoundation,
            uint256 toHighGuard,
            uint256 toDisputeCreator,
            address disputeCreator
        ) = MarketLib.closeMarket(
                _market,
                burnFee,
                marketConfig.verificationFee(),
                foundationFee,
                result
            );
        if (toBurn != 0) {
            foreToken.burn(toBurn);
        }
        if (toFoundation != 0) {
            foreToken.transfer(protocolConfig.foundationWallet(), toFoundation);
        }
        if (toHighGuard != 0) {
            foreToken.transfer(protocolConfig.highGuard(), toHighGuard);
        }
        if (toDisputeCreator != 0) {
            foreToken.transfer(disputeCreator, toDisputeCreator);
        }
    }

    ///@notice Closes _market
    function closeMarket() external {
        MarketLib.Market memory m = _market;
        if(m.sideA == 0 || m.sideB == 0){
            _closeMarket(MarketLib.ResultType.INVALID);
            return;
        }
        (uint256 verificationPeriod, uint256 disputePeriod) = marketConfig
            .periods();
        MarketLib.beforeClosingCheck(m, verificationPeriod, disputePeriod);
        _closeMarket(MarketLib.calculateMarketResult(m));
    }

    ///@notice Returns prediction reward in ForeToken
    ///@dev Returns full available amount to withdraw(Deposited fund + reward of winnings - Protocol fees)
    ///@param predictor Predictior address
    ///@return 0 Amount to withdraw
    function calculatePredictionReward(address predictor)
        external
        view
        returns (uint256)
    {
        if(predictionWithdrawn[predictor]) return(0);
        MarketLib.Market memory m = _market;
        return (
            MarketLib.calculatePredictionReward(
                m,
                predictionsA[predictor],
                predictionsB[predictor],
                marketConfig.feesSum()
            )
        );
    }

    ///@notice Withdraw prediction rewards
    ///@dev predictor Predictor Address
    ///@param predictor Predictor address
    function withdrawPredictionReward(address predictor) external {
        MarketLib.Market memory m = _market;
        uint256 toWithdraw = MarketLib.withdrawPredictionReward(
            m,
            marketConfig.feesSum(),
            predictionWithdrawn,
            predictionsA[predictor],
            predictionsB[predictor],
            predictor
        );
        foreToken.transfer(predictor, toWithdraw);
    }

    ///@notice Calculates Verification Reward
    ///@param verificationId Id of Verification
    function calculateVerificationReward(uint256 verificationId) external view returns(uint256 toVerifier, uint256 toDisputeCreator, uint256 toHighGuard, bool vNftBurn){
        MarketLib.Market memory m = _market;
        MarketLib.Verification memory v = verifications[verificationId];
        uint256 power = foreVerifiers.powerOf(
            verifications[verificationId].tokenId
        );
        (toVerifier, toDisputeCreator, toHighGuard, vNftBurn) =  MarketLib.calculateVerificationReward(m, v, power, marketConfig.verificationFee());
    }

    ///@notice Withdrawss Verification Reward
    ///@param verificationId Id of verification
    ///@param withdrawAsTokens If true witdraws tokens, false - withraws power
    function withdrawVerificationReward(uint256 verificationId, bool withdrawAsTokens) external {
        MarketLib.Market memory m = _market;
        MarketLib.Verification memory v = verifications[verificationId];
        uint256 power = foreVerifiers.powerOf(
            verifications[verificationId].tokenId
        );
        (
            uint256 toVerifier,
            uint256 toDisputeCreator,
            uint256 toHighGuard,
            bool vNftBurn
        ) = MarketLib.withdrawVerificationReward(
                m,
                v,
                power,
                marketConfig.verificationFee()
            );
        verifications[verificationId].withdrawn = true;
        if (toVerifier != 0) {
            if(withdrawAsTokens){
                foreToken.transferFrom(
                    address(this),
                    v.verifier,
                    toVerifier
                );
            }
            else{
                foreVerifiers.increasePower(v.tokenId, toVerifier);
                foreToken.transferFrom(
                    address(this),
                    address(foreVerifiers),
                    toVerifier
                );
            }
        }
        if (toDisputeCreator != 0) {
            foreToken.transferFrom(
                address(this),
                m.disputeCreator,
                toDisputeCreator
            );
            foreToken.transferFrom(
                address(this),
                protocolConfig.highGuard(),
                toHighGuard
            );
            foreToken.burn(power - toDisputeCreator - toHighGuard);
        }

        if (vNftBurn) {
            foreVerifiers.burn(v.tokenId);
        } else {
            foreVerifiers.transferFrom(address(this), v.verifier, v.tokenId);
        }
    }

    ///@notice Withdraw Market Creators Reward
    function marketCreatorFeeWithdraw() external {
        MarketLib.Market memory m = _market;
        uint256 tokenId = marketId;

        require(protocol.ownerOf(tokenId)==msg.sender,"BasicMarket: Only Market Creator");

        if (m.result == MarketLib.ResultType.NULL) {
            revert ("MarketIsNotClosedYet");
        }

        protocol.burn(tokenId);

        uint256 toWithdraw = ((m.sideA + m.sideB) *
            marketConfig.marketCreatorFee()) / 10000;
        foreToken.transfer(msg.sender, toWithdraw);

        emit MarketLib.WithdrawReward(msg.sender, 3, toWithdraw);
    }
}

interface IERC20Burnable is IERC20 {
    function burnFrom(address account, uint256 amount) external;
    function burn(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IForeProtocol is IERC721 {
    function allMarketLength() external view returns (uint256);

    function allMarkets(uint256) external view returns (address);

    function burn(uint256 tokenId) external;

    function buyPower(uint256 id, uint256 amount) external;

    function config() external view returns (address);

    function market(bytes32 mHash) external view returns(address);

    function createMarket(
        bytes32 marketHash,
        address creator,
        address receiver,
        address marketAddress
    ) external returns(uint256);

    function foreToken() external view returns (address);

    function foreVerifiers() external view returns (address);

    function isForeMarket(address market) external view returns (bool);

    function isForeOperator(address addr) external view returns (bool);

    function mintVerifier(address receiver) external;

    event MarketCreated(
        address indexed factory,
        address indexed creator,
        bytes32 marketHash,
        address market,
        uint256 marketIdx
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IForeVerifiers is IERC721{
    function decreasePower(uint256 id, uint256 amount) external;

    function protocol() external view returns (address);

    function height() external view returns (uint256);

    function increasePower(uint256 id, uint256 amount) external;

    function mintWithPower(address to, uint256 amount) external;

    function initialPowerOf(uint256 id) external view returns(uint256);

    function powerOf(uint256 id) external view returns (uint256);

    function burn(uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


interface IProtocolConfig {
    function marketConfig() external view returns (address);

    function foreToken() external view returns (address);

    function foreVerifiers() external view returns (address);

    function foundationWallet() external view returns (address);

    function highGuard() external view returns (address);

    function marketplace() external view returns (address);

    function owner() external view returns (address);

    function renounceOwnership() external;

    function revenueWallet() external view returns (address);

    function verifierMintPrice() external view returns (uint256);

    function marketCreationPrice() external view returns (uint256);

    function addresses() external view returns(address, address, address, address, address, address, address);

    function roleAddresses() external view returns(address, address, address);

    function isFactoryWhitelisted(address adr) external view returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IMarketConfig {
    function burnFee() external view returns (uint256);

    function config()
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
    );

    function fees()
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
    );

    function periods()
        external
        view
        returns (
            uint256,
            uint256
    );

    function disputePeriod() external view returns (uint256);

    function disputePrice() external view returns (uint256);

    function feesSum() external view returns (uint256);

    function foundationFee() external view returns (uint256);

    function marketCreatorFee() external view returns (uint256);

    function verificationFee() external view returns (uint256);

    function verificationPeriod() external view returns (uint256);
}

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}