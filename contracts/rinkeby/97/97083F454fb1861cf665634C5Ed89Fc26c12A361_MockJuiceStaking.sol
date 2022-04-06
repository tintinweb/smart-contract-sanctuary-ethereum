// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.10;

import "../interfaces/IPriceOracle.sol";
import "../JuiceStaking.sol";

contract MockJuiceStaking is JuiceStaking {
    using EnumerableSet for EnumerableSet.AddressSet;

    function getPriceOracle(address addr) public view returns (IPriceOracle) {
        return priceOracles[addr];
    }

    function hasRegisteredToken(address addr) public view returns (bool) {
        return registeredTokens.contains(addr);
    }

    struct TokenOracleTuple {
        address token;
        address oracle;
    }

    function getRegisteredTokensAndOracles()
        public
        view
        returns (TokenOracleTuple[] memory)
    {
        TokenOracleTuple[] memory tokensAndOracles = new TokenOracleTuple[](
            registeredTokens.length()
        );
        for (uint256 i = 0; i < registeredTokens.length(); i++) {
            address token = registeredTokens.at(i);
            tokensAndOracles[i] = TokenOracleTuple({
                token: token,
                oracle: address(priceOracles[token])
            });
        }
        return tokensAndOracles;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.10;

interface IPriceOracle {
    /// @notice Gets the decimals used in `latestAnswer()`.
    function decimals() external view returns (uint8);

    /// @notice Gets the price change data for exact roundId (i.e. an identifier for single historical price change in the Oracle)
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

    /// @notice Gets the latest price change data.
    /// @dev Intentionally the same name and return values as the Chainlink aggregator interface (https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.4/interfaces/AggregatorV3Interface.sol).
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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.10;

import "./interfaces/IJuiceStaking.sol";
import "./JuiceStakerDelegateEIP712Util.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { SignatureCheckerUpgradeable as SignatureChecker } from "@openzeppelin/contracts-upgradeable/utils/cryptography/SignatureCheckerUpgradeable.sol";
import { ECDSAUpgradeable as ECDSA } from "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import { EnumerableSetUpgradeable as EnumerableSet } from "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "./interfaces/IPriceOracle.sol";
import { StakingParam } from "./interfaces/IJuiceStakerActions.sol";

contract JuiceStaking is
    IJuiceStaking,
    ERC20Upgradeable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    JuiceStakerDelegateEIP712Util
{
    // decimals synced with Chainlink pricefeed decimals
    uint8 private constant DECIMALS = 8;

    /// used in StakePosition.amount calculations to retain good enough precision in intermediate price math
    uint256 private constant INTERNAL_TOKEN_AMOUNT_MULTIPLIER = 1e16;

    /// this struct is used in contract storage, so it's been optimized to fit in uint128
    struct OraclePosition {
        /// downcasted from the value range of block.timestamp, which overflows uint64 in distant enough future
        uint64 timestamp;
        /// downcasted from the value range of uint80, but original value increments sequentially on every price update
        /// in single oracle, so overflow is improbable
        uint64 roundId;
    }

    /// this struct is memory-only so no need to optimize the layout
    struct OracleAnswer {
        uint80 roundId;
        uint256 price;
        uint256 timestamp;
    }

    struct StakePosition {
        /// The price position from Oracle when position was opened.
        OraclePosition pricePosition;
        /// The balance of Juice staked into this position. Long positions are negative, shorts are positive.
        int128 juiceBalance;
    }

    struct Stake {
        uint128 unstakedBalance;
        mapping(address => StakePosition) tokenStake;
    }

    struct TokenSignal {
        uint128 totalLongs;
        uint128 totalShorts;
    }

    mapping(address => Stake) internal stakes;
    mapping(address => TokenSignal) internal tokenSignals;

    struct AggregateSignal {
        uint128 totalVolume;
        int128 netSentiment;
        /// the percentage of long positions in signal (`W_{longs}` in lite paper)
        uint128 totalLongSentiment;
        /// the sum of weighted net sentiments (i.e. the total sum of longTokenSignals.longTokenWeight)
        uint128 sumWeightedNetSentiment;
    }

    AggregateSignal internal aggregatedSignal;

    AggregateTokenSignal internal aggregateTokenSignal;

    mapping(address => IPriceOracle) internal priceOracles;
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet internal registeredTokens;

    IJuiceSignalAggregator public signalAggregator;

    bytes32 public domainSeparatorV4;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() public initializer {
        __ERC20_init("Vanilla Juice", "JUICE");
        __UUPSUpgradeable_init();
        __Ownable_init();
        __Pausable_init();
        domainSeparatorV4 = hashDomainSeparator(
            "Vanilla Juice",
            "1",
            block.chainid,
            address(this)
        );
    }

    /// @inheritdoc ERC20Upgradeable
    function decimals() public pure override returns (uint8) {
        return DECIMALS;
    }

    /// @inheritdoc IJuiceOwnerActions
    function updatePriceOracles(
        address[] calldata tokens,
        IPriceOracle[] calldata oracles
    ) external override onlyOwner {
        if (tokens.length != oracles.length) {
            revert TokenOracleMismatch(tokens.length, oracles.length);
        }
        for (uint256 i = 0; i < oracles.length; i++) {
            if (address(oracles[i]) == address(0)) {
                // checking the return value here saves us 200 gas (per EIP-1283)
                if (registeredTokens.remove(tokens[i])) {
                    delete priceOracles[tokens[i]];
                }
                continue;
            }
            uint8 actualDecimals = oracles[i].decimals();
            if (actualDecimals != DECIMALS) {
                revert OracleDecimalMismatch(DECIMALS, actualDecimals);
            }
            priceOracles[tokens[i]] = oracles[i];
            registeredTokens.add(tokens[i]);
        }
    }

    /// @inheritdoc IJuiceOwnerActions
    function mintJuice(address[] calldata targets, uint256[] calldata amounts)
        external
        onlyOwner
    {
        if (targets.length != amounts.length) {
            revert MintTargetMismatch(targets.length, amounts.length);
        }

        for (uint256 i = 0; i < targets.length; i++) {
            address target = targets[i];
            _mint(target, amounts[i]);
        }
    }

    /// @inheritdoc IJuiceOwnerActions
    function authorizeSignalAggregator(IJuiceSignalAggregator aggregator)
        external
        onlyOwner
    {
        signalAggregator = aggregator;
        if (address(aggregator) != address(0)) {
            aggregator.signalUpdated(aggregateTokenSignal);
        }
    }

    /// @inheritdoc IJuiceStaking
    function unstakedBalanceOf(address user) external view returns (uint256) {
        return stakes[user].unstakedBalance;
    }

    function latestPrice(address token)
        internal
        view
        returns (
            OracleAnswer memory answer,
            bool priceFound,
            IPriceOracle oracle
        )
    {
        IPriceOracle priceOracle = priceOracles[token];
        if (address(priceOracle) == address(0)) {
            return (OracleAnswer(0, 0, 0), false, priceOracle);
        }
        return (latestAnswer(priceOracle), true, priceOracle);
    }

    function getRoundData(IPriceOracle oracle, uint80 roundId)
        internal
        view
        returns (OracleAnswer memory)
    {
        (, int256 answer, , uint256 updatedAt, ) = oracle.getRoundData(roundId);
        return
            OracleAnswer({
                roundId: roundId,
                price: uint256(answer),
                timestamp: updatedAt
            });
    }

    function stakeAmount(
        IPriceOracle oracle,
        OraclePosition memory pricePosition,
        uint256 juiceStake,
        OracleAnswer memory current
    ) internal view returns (uint128) {
        // only check for front-running if the priceoracle has updated after the position was opened
        if (current.roundId > pricePosition.roundId) {
            OracleAnswer memory priceAfter = getRoundData(
                oracle,
                pricePosition.roundId + 1
            );
            // if the position was opened in the same block (equal timestamps) but before the price change, let's use
            // the price _after_ the position was opened to mitigate the front-running by tx reordering
            if (priceAfter.timestamp == pricePosition.timestamp) {
                return
                    uint128(
                        (juiceStake * INTERNAL_TOKEN_AMOUNT_MULTIPLIER) /
                            priceAfter.price
                    );
            }
            // otherwise, just proceed normally to computing the staked token amount using the price _before_ the position was opened
        }

        OracleAnswer memory priceBefore = getRoundData(
            oracle,
            pricePosition.roundId
        );
        return
            uint128(
                (juiceStake * INTERNAL_TOKEN_AMOUNT_MULTIPLIER) /
                    priceBefore.price
            );
    }

    /// @inheritdoc IJuiceStaking
    function currentStake(address user, address token)
        external
        view
        returns (
            uint256 juiceStake,
            uint256 juiceValue,
            uint256 currentPrice,
            bool sentiment
        )
    {
        StakePosition memory stake = stakes[user].tokenStake[token];
        bool oracleFound;
        IPriceOracle oracle;
        OracleAnswer memory currentAnswer;
        // if stake position was opened before price oracle was removed, their value will equal the original stake
        // oracleFound is therefore checked before calculating the juiceValue for both long and short positions
        (currentAnswer, oracleFound, oracle) = latestPrice(token);
        currentPrice = currentAnswer.price;

        if (stake.juiceBalance == 0) {
            // no stake for the token, return early
            return (0, 0, currentAnswer.price, false);
        }
        sentiment = stake.juiceBalance < 0;
        if (sentiment) {
            juiceStake = uint256(int256(-stake.juiceBalance));
            juiceValue = oracleFound
                ? computeJuiceValue(
                    stakeAmount(
                        oracle,
                        stake.pricePosition,
                        juiceStake,
                        currentAnswer
                    ),
                    currentPrice
                )
                : juiceStake;
        } else {
            juiceStake = uint256(int256(stake.juiceBalance));
            if (oracleFound) {
                int256 shortPositionValue = (2 * stake.juiceBalance) -
                    int256(
                        computeJuiceValue(
                            stakeAmount(
                                oracle,
                                stake.pricePosition,
                                juiceStake,
                                currentAnswer
                            ),
                            currentPrice
                        )
                    );
                if (shortPositionValue > 0) {
                    juiceValue = uint256(shortPositionValue);
                } else {
                    juiceValue = 0;
                }
            } else {
                juiceValue = juiceStake;
            }
        }
    }

    /// @inheritdoc IJuiceStakerActions
    function deposit(uint256 amount) external override whenNotPaused {
        doDeposit(amount, msg.sender);
    }

    function doDeposit(uint256 amount, address depositor) internal {
        uint256 currentBalance = balanceOf(depositor);
        if (currentBalance < amount) {
            revert InsufficientJUICE(amount, currentBalance);
        }

        stakes[depositor].unstakedBalance += uint128(amount);

        _transfer(depositor, address(this), amount);
        emit JUICEDeposited(depositor, amount);
    }

    /// @inheritdoc IJuiceStakerActions
    function withdraw(uint256 amount) external override whenNotPaused {
        doWithdraw(amount, msg.sender);
    }

    function doWithdraw(uint256 amount, address staker) internal {
        Stake storage stake = stakes[staker];
        if (stake.unstakedBalance < amount) {
            revert InsufficientJUICE(amount, stake.unstakedBalance);
        }
        stake.unstakedBalance -= uint128(amount);
        _transfer(address(this), staker, amount);
        emit JUICEWithdrawn(staker, amount);
    }

    /// @inheritdoc IJuiceStakerActions
    function modifyStakes(StakingParam[] calldata stakingParams)
        external
        override
        whenNotPaused
    {
        doModifyStakes(stakingParams, msg.sender);
    }

    function normalizedAggregateSignal()
        external
        view
        returns (AggregateTokenSignal memory)
    {
        return aggregateTokenSignal;
    }

    function normalizeTokenSignals(
        address[] memory tokens,
        uint256[] memory weights,
        uint256 length,
        AggregateSignal memory totals
    ) internal {
        LongTokenSignal[] memory longTokens = new LongTokenSignal[](length);
        LongTokenSignal[] storage storedLongTokens = aggregateTokenSignal
            .longTokens;
        for (uint256 i = 0; i < longTokens.length; i++) {
            uint96 weight = uint96(
                (totals.totalLongSentiment * weights[i]) /
                    totals.sumWeightedNetSentiment
            );

            // do rounding
            if (weight % 100 > 50) {
                weight += (100 - (weight % 100));
            } else {
                weight -= (weight % 100);
            }
            if (storedLongTokens.length == i) {
                storedLongTokens.push(
                    LongTokenSignal({ token: tokens[i], weight: weight / 100 })
                );
            } else {
                storedLongTokens[i] = LongTokenSignal({
                    token: tokens[i],
                    weight: weight / 100
                });
            }
        }
        uint256 arrayItemsToRemove = storedLongTokens.length - length;
        while (arrayItemsToRemove > 0) {
            storedLongTokens.pop();
            arrayItemsToRemove--;
        }
    }

    function doModifyStakes(
        StakingParam[] calldata stakingParams,
        address staker
    ) internal {
        Stake storage stake = stakes[staker];
        int256 juiceSupplyDiff = 0;
        int256 volumeDiff = 0;
        int256 sentimentDiff = 0;
        for (uint256 i = 0; i < stakingParams.length; i++) {
            StakingParam calldata param = stakingParams[i];
            TokenSignal storage tokenSignal = tokenSignals[param.token];
            (uint128 longsBefore, uint128 shortsBefore) = (
                tokenSignal.totalLongs,
                tokenSignal.totalShorts
            );
            juiceSupplyDiff += removeStake(
                param.token,
                stake,
                tokenSignal,
                staker
            );
            addStake(param, tokenSignal, staker);
            volumeDiff += (int256(
                uint256(tokenSignal.totalLongs + tokenSignal.totalShorts)
            ) - int256(uint256(longsBefore + shortsBefore)));
            sentimentDiff += ((int256(uint256(tokenSignal.totalLongs)) -
                int256(uint256(longsBefore))) -
                (int256(uint256(tokenSignal.totalShorts)) -
                    int256(uint256(shortsBefore))));
        }
        if (juiceSupplyDiff > 0) {
            _mint(address(this), uint256(juiceSupplyDiff));
        } else if (juiceSupplyDiff < 0) {
            _burn(address(this), uint256(-juiceSupplyDiff));
        }

        doUpdateAggregateSignal(volumeDiff, sentimentDiff);
    }

    function doUpdateAggregateSignal(int256 volumeDiff, int256 sentimentDiff)
        internal
    {
        AggregateSignal storage totals = aggregatedSignal;

        if (volumeDiff < 0) {
            totals.totalVolume -= uint128(uint256(-volumeDiff));
        } else {
            totals.totalVolume += uint128(uint256(volumeDiff));
        }

        totals.netSentiment += int128(sentimentDiff);

        uint256 longWeight = totals.netSentiment > 0
            ? (10000 * uint256(int256(totals.netSentiment))) /
                uint256(totals.totalVolume)
            : 0;
        totals.totalLongSentiment = uint128(longWeight);

        uint256 initialLength = registeredTokens.length();
        address[] memory longTokens = new address[](initialLength);
        uint256[] memory longWeights = new uint256[](initialLength);
        uint256 longTokenCount = 0;
        uint256 totalWeightedLongs = 0;
        if (totals.totalVolume > 0) {
            for (uint256 i = 0; i < longTokens.length; i++) {
                address token = registeredTokens.at(i);
                TokenSignal memory tokenSignal = tokenSignals[token];
                if (tokenSignal.totalLongs <= tokenSignal.totalShorts) {
                    continue;
                }
                (uint256 totalLongs, uint256 totalShorts) = (
                    tokenSignal.totalLongs,
                    tokenSignal.totalShorts
                );

                uint256 V_x = totalLongs + totalShorts;
                uint256 N_x = totalLongs - totalShorts;

                uint256 weighted_x = (N_x * V_x) / uint256(totals.totalVolume);

                longTokens[longTokenCount] = token;
                longWeights[longTokenCount] = weighted_x;

                longTokenCount++;
                totalWeightedLongs += weighted_x;
            }
        }
        totals.sumWeightedNetSentiment = uint128(totalWeightedLongs);
        // normalize and set token signal
        normalizeTokenSignals(longTokens, longWeights, longTokenCount, totals);

        if (address(signalAggregator) != address(0)) {
            signalAggregator.signalUpdated(aggregateTokenSignal);
        }
    }

    function latestAnswer(IPriceOracle priceOracle)
        internal
        view
        returns (OracleAnswer memory)
    {
        (uint80 roundId, int256 answer, , uint256 timestamp, ) = priceOracle
            .latestRoundData();
        return OracleAnswer(roundId, uint256(answer), timestamp);
    }

    function asOraclePosition(OracleAnswer memory answer)
        internal
        view
        returns (OraclePosition memory)
    {
        return
            OraclePosition({
                timestamp: uint64(block.timestamp),
                roundId: uint64(answer.roundId)
            });
    }

    function addStake(
        StakingParam memory param,
        TokenSignal storage tokenSignal,
        address staker
    ) internal {
        if (param.amount == 0) {
            // amount 0 means that stake has been removed
            return;
        }

        IPriceOracle priceOracle = priceOracles[param.token];
        if (address(priceOracle) == address(0)) {
            revert InvalidToken(param.token);
        }

        Stake storage stake = stakes[staker];
        if (stake.unstakedBalance < param.amount) {
            // limit the amount to the unstaked balance
            param.amount = stake.unstakedBalance;
        }

        stake.unstakedBalance -= param.amount;
        OracleAnswer memory answer = latestAnswer(priceOracle);

        if (param.sentiment) {
            stake.tokenStake[param.token] = StakePosition({
                pricePosition: asOraclePosition(answer),
                juiceBalance: -int128(int256(uint256(param.amount)))
            });
            tokenSignal.totalLongs += param.amount;
        } else {
            stake.tokenStake[param.token] = StakePosition({
                pricePosition: asOraclePosition(answer),
                juiceBalance: int128(int256(uint256(param.amount)))
            });
            tokenSignal.totalShorts += param.amount;
        }
        emit StakeAdded(
            staker,
            param.token,
            param.sentiment,
            answer.price,
            -int128(int256(uint256(param.amount)))
        );
    }

    function computeJuiceValue(uint128 tokenAmount, uint256 tokenPrice)
        internal
        pure
        returns (uint256)
    {
        // because Solidity rounds numbers towards zero, we add one to the tokenAmount to make sure that
        // removing the stake with the same tokenPrice refunds the exact same amount of JUICE back
        return
            ((tokenAmount + 1) * tokenPrice) / INTERNAL_TOKEN_AMOUNT_MULTIPLIER;
    }

    function removeStake(
        address token,
        Stake storage storedStakes,
        TokenSignal storage tokenSignal,
        address staker
    ) internal returns (int256 juiceSupplyDiff) {
        int128 currentJuiceBalance = storedStakes
            .tokenStake[token]
            .juiceBalance;
        if (currentJuiceBalance == 0) {
            // nothing to remove, but not reverting to make parent function implementation simpler
            return 0;
        }

        IPriceOracle priceOracle = priceOracles[token];
        if (address(priceOracle) == address(0)) {
            storedStakes.tokenStake[token] = StakePosition({
                pricePosition: OraclePosition(0, 0),
                juiceBalance: 0
            });
            if (currentJuiceBalance < 0) {
                storedStakes.unstakedBalance += uint128(
                    uint256(int256(-currentJuiceBalance))
                );
            } else {
                storedStakes.unstakedBalance += uint128(
                    uint256(int256(currentJuiceBalance))
                );
            }
            return 0;
        }

        OracleAnswer memory answer = latestAnswer(priceOracle);

        uint256 juiceRefund;
        if (currentJuiceBalance < 0) {
            uint256 juiceAmount = uint256(int256(-currentJuiceBalance));
            uint256 positionValue = computeJuiceValue(
                stakeAmount(
                    priceOracle,
                    storedStakes.tokenStake[token].pricePosition,
                    juiceAmount,
                    answer
                ),
                answer.price
            );
            juiceRefund = positionValue;
            juiceSupplyDiff = int256(positionValue) + currentJuiceBalance;
            tokenSignal.totalLongs -= uint128(juiceAmount);
        } else {
            uint256 juiceAmount = uint256(int256(currentJuiceBalance));
            uint256 positionValue = computeJuiceValue(
                stakeAmount(
                    priceOracle,
                    storedStakes.tokenStake[token].pricePosition,
                    juiceAmount,
                    answer
                ),
                answer.price
            );
            int256 shortPositionValue = (2 * currentJuiceBalance) -
                int256(positionValue);
            if (shortPositionValue > 0) {
                juiceRefund = uint256(shortPositionValue);
                juiceSupplyDiff =
                    int256(shortPositionValue) -
                    currentJuiceBalance;
            } else {
                juiceRefund = 0;
                juiceSupplyDiff = -currentJuiceBalance;
            }
            tokenSignal.totalShorts -= uint128(juiceAmount);
        }
        storedStakes.tokenStake[token] = StakePosition({
            pricePosition: OraclePosition(0, 0),
            juiceBalance: 0
        });
        storedStakes.unstakedBalance += uint128(juiceRefund);

        emit StakeRemoved(
            staker,
            token,
            currentJuiceBalance < 0,
            answer.price,
            int256(juiceRefund)
        );
    }

    modifier onlyValidPermission(
        SignedPermission calldata permission,
        bytes32 hash
    ) {
        if (block.timestamp > permission.data.deadline) {
            revert PermissionExpired();
        }
        if (permission.data.sender == address(0)) {
            revert InvalidSender();
        }

        uint256 currentNonce = permissionNonces[permission.data.sender];
        if (currentNonce != permission.data.nonce) {
            revert InvalidNonce();
        }
        permissionNonces[permission.data.sender] = currentNonce + 1;

        bytes32 EIP712TypedHash = ECDSA.toTypedDataHash(
            domainSeparatorV4,
            hash
        );
        bool isSignatureValid = SignatureChecker.isValidSignatureNow(
            permission.data.sender,
            EIP712TypedHash,
            permission.signature
        );
        if (!isSignatureValid) {
            revert InvalidSignature();
        }
        _;
    }

    /// @inheritdoc IJuiceStakerDelegateActions
    function delegateDeposit(
        uint256 amount,
        SignedPermission calldata permission
    )
        external
        whenNotPaused
        onlyValidPermission(permission, hashDeposit(amount, permission.data))
    {
        doDeposit(amount, permission.data.sender);
    }

    /// @inheritdoc IJuiceStakerDelegateActions
    function delegateModifyStakes(
        StakingParam[] calldata stakingParams,
        SignedPermission calldata permission
    )
        external
        whenNotPaused
        onlyValidPermission(
            permission,
            hashModifyStakes(stakingParams, permission.data)
        )
    {
        doModifyStakes(stakingParams, permission.data.sender);
    }

    /// @inheritdoc IJuiceStakerDelegateActions
    function delegateWithdraw(
        uint256 amount,
        SignedPermission calldata permission
    )
        external
        whenNotPaused
        onlyValidPermission(permission, hashWithdraw(amount, permission.data))
    {
        doWithdraw(amount, permission.data.sender);
    }

    /// @inheritdoc IJuiceOwnerActions
    function emergencyPause(bool pauseStaking) external onlyOwner {
        if (pauseStaking) {
            _pause();
        } else {
            _unpause();
        }
    }

    /// @inheritdoc ERC20Upgradeable
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "JUICE is temporarily disabled");
    }

    /// @inheritdoc UUPSUpgradeable
    function _authorizeUpgrade(address implementation)
        internal
        override
        onlyOwner
    {
        /// verify that only owner is allowed to upgrade
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.10;

import "./IJuiceStakerActions.sol";
import "./IJuiceOwnerActions.sol";
import "./IJuiceStakerDelegateActions.sol";

struct LongTokenSignal {
    /// the long token address
    address token;
    /// the long token weight percentage rounded to nearest integer (0-100)
    uint96 weight;
}
struct AggregateTokenSignal {
    /// all long tokens in aggregate signal
    LongTokenSignal[] longTokens;
}

interface IJuiceStaking is
    IJuiceStakerActions,
    IJuiceOwnerActions,
    IJuiceStakerDelegateActions
{
    /// @notice Gets the current unstaked balance for `user`.
    /// @param user The staker.
    /// @return unstakedJUICE The current unstaked balance.
    function unstakedBalanceOf(address user)
        external
        view
        returns (uint256 unstakedJUICE);

    /// @notice Gets the current token stake position for user and token.
    /// @param user The staker.
    /// @param token The token.
    /// @return juiceStake The amount of Juice originally staked.
    /// @return juiceValue The current Juice value of this stake position.
    /// @return currentPrice The current price oracle value for the token. If price = 0, there is no price oracle for the token.
    /// @return sentiment True if the stake is long, false if short.
    function currentStake(address user, address token)
        external
        view
        returns (
            uint256 juiceStake,
            uint256 juiceValue,
            uint256 currentPrice,
            bool sentiment
        );

    /// @notice Gets the current aggregate signal
    function normalizedAggregateSignal()
        external
        view
        returns (AggregateTokenSignal memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.10;

import { StakingParam } from "./interfaces/IJuiceStakerActions.sol";
import { Permission } from "./interfaces/IJuiceStakerDelegateActions.sol";

abstract contract JuiceStakerDelegateEIP712Util {
    /// @notice as defined in EIP-712
    string private constant EIP712DOMAIN_SIG =
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)";

    string private constant PERMISSION_SIG =
        "Permission(address sender,uint deadline,uint nonce)";
    string private constant DEPOSIT_SIG =
        "Deposit(uint amount,Permission permission)";
    string private constant WITHDRAW_SIG =
        "Withdraw(uint amount,Permission permission)";
    string private constant STAKE_SIG =
        "Stake(address token,uint128 amount,bool sentiment)";
    string private constant MODIFY_STAKES_SIG =
        "ModifyStakes(Stake[] stakes,Permission permission)";
    bytes32 private constant STAKE_SIGHASH = keccak256(bytes(STAKE_SIG));

    /// @notice Contains the latest permission nonces for each Staker, for replay attack protection.
    mapping(address => uint256) internal permissionNonces;

    /// @dev The standard EIP-712 domain separator.
    function hashDomainSeparator(
        string memory name,
        string memory version,
        uint256 chainId,
        address verifyingContract
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(bytes(EIP712DOMAIN_SIG)),
                    keccak256(bytes(name)),
                    keccak256(bytes(version)),
                    chainId,
                    verifyingContract
                )
            );
    }

    function hashPermission(Permission calldata permission)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    keccak256(bytes(PERMISSION_SIG)),
                    permission.sender,
                    permission.deadline,
                    permission.nonce
                )
            );
    }

    function hashDeposit(uint256 amount, Permission calldata permission)
        public
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    keccak256(abi.encodePacked(DEPOSIT_SIG, PERMISSION_SIG)),
                    amount,
                    hashPermission(permission)
                )
            );
    }

    function hashWithdraw(uint256 amount, Permission calldata permission)
        public
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    keccak256(abi.encodePacked(WITHDRAW_SIG, PERMISSION_SIG)),
                    amount,
                    hashPermission(permission)
                )
            );
    }

    /// @dev uses precomputed STAKE_SIGHASH because this function is called in a loop from `hashModifyStakes`
    function hashStake(StakingParam calldata param)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    STAKE_SIGHASH,
                    param.token,
                    param.amount,
                    param.sentiment
                )
            );
    }

    function hashModifyStakes(
        StakingParam[] calldata params,
        Permission calldata permission
    ) public pure returns (bytes32) {
        // no array.map in Solidity so intermediate memory array is needed for transforming params into struct hashes
        bytes32[] memory stakeHashes = new bytes32[](params.length);
        for (uint256 i = 0; i < params.length; i++) {
            stakeHashes[i] = hashStake(params[i]);
        }

        return
            keccak256(
                abi.encode(
                    // the order of signatures matters, after the main struct are all the nested structs in alphabetical order (as stated in EIP-712)
                    keccak256(
                        abi.encodePacked(
                            MODIFY_STAKES_SIG,
                            PERMISSION_SIG,
                            STAKE_SIG
                        )
                    ),
                    // array arguments are simply concatenated, so use encodePacked instead of encode
                    keccak256(abi.encodePacked(stakeHashes)),
                    hashPermission(permission)
                )
            );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
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
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
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
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
        __ERC1967Upgrade_init_unchained();
        __UUPSUpgradeable_init_unchained();
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
    uint256[50] private __gap;
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
        __Context_init_unchained();
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/SignatureChecker.sol)

pragma solidity ^0.8.0;

import "./ECDSAUpgradeable.sol";
import "../AddressUpgradeable.sol";
import "../../interfaces/IERC1271Upgradeable.sol";

/**
 * @dev Signature verification helper: Provide a single mechanism to verify both private-key (EOA) ECDSA signature and
 * ERC1271 contract signatures. Using this instead of ECDSA.recover in your contract will make them compatible with
 * smart contract wallets such as Argent and Gnosis.
 *
 * Note: unlike ECDSA signatures, contract signature's are revocable, and the outcome of this function can thus change
 * through time. It could return true at block N and false at block N+1 (or the opposite).
 *
 * _Available since v4.1._
 */
library SignatureCheckerUpgradeable {
    function isValidSignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (address recovered, ECDSAUpgradeable.RecoverError error) = ECDSAUpgradeable.tryRecover(hash, signature);
        if (error == ECDSAUpgradeable.RecoverError.NoError && recovered == signer) {
            return true;
        }

        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271Upgradeable.isValidSignature.selector, hash, signature)
        );
        return (success && result.length == 32 && abi.decode(result, (bytes4)) == IERC1271Upgradeable.isValidSignature.selector);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.10;

/// The parameter object for setting stakes.
struct StakingParam {
    /// The address of the target asset i.e. the ERC-20 token.
    address token;
    /// The new amount of JUICE at stake. Zeroing removes the stake.
    uint128 amount;
    /// True if this is a long position, false if it's a short position.
    bool sentiment;
}

interface IJuiceStakerActions {
    /// @notice Deposits JUICE tokens to be used in staking. Moves `amount` of JUICE from user's balance to
    /// staking contract's balance.
    /// @param amount The deposited amount. If it exceeds user's balance, tx reverts with `InsufficientJUICE` error.
    function deposit(uint256 amount) external;

    /// @notice Modifies the user's token stakes.
    /// @param stakes The array of StakingParams which are processed in order.
    function modifyStakes(StakingParam[] calldata stakes) external;

    /// @notice Withdraws JUICE tokens from the staking contract. Moves `amount` of JUICE from the contract's balance to
    /// user's balance.
    /// @param amount The withdrawn amount. If it exceeds user's unstaked balance, tx reverts with `InsufficientJUICE` error.
    function withdraw(uint256 amount) external;

    /// @notice Emitted on successful deposit()
    /// @param user The user who made the deposit
    /// @param amount The deposited JUICE amount
    event JUICEDeposited(address indexed user, uint256 amount);

    /// @notice Emitted on successful withdraw()
    /// @param user The user who made the withdraw
    /// @param amount The withdrawn JUICE amount
    event JUICEWithdrawn(address indexed user, uint256 amount);

    /// @notice Emitted when adding to a staked token amount.
    /// @param user The staker
    /// @param token The staked token
    /// @param sentiment True if this is a long stake.
    /// @param price The token price.
    /// @param unstakedDiff The unstaked JUICE difference (negative when staking)
    event StakeAdded(
        address indexed user,
        address indexed token,
        bool sentiment,
        uint256 price,
        int256 unstakedDiff
    );

    /// @notice Emitted when unstaking from a token stake.
    /// @param user The staker
    /// @param token The staked token
    /// @param sentiment True if this is a long stake.
    /// @param price The token price.
    /// @param unstakedDiff The unstaked JUICE difference (positive when unstaking)
    event StakeRemoved(
        address indexed user,
        address indexed token,
        bool sentiment,
        uint256 price,
        int256 unstakedDiff
    );

    /// @notice Thrown if the StakeData.token is not supported (i.e. couldn't resolve a price feed for it, or it's on the unsafelist).
    error InvalidToken(address token);

    /// @notice Thrown when
    /// 1) deposited amount exceeds the balance, or
    /// 2) withdrawn amount exceeds the unstaked JUICE balance.
    error InsufficientJUICE(uint256 expected, uint256 actual);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.10;

import "./IPriceOracle.sol";
import "./IJuiceSignalAggregator.sol";

/// @notice Function implementations must ensure that only the contract owner is authorized to execute them.
interface IJuiceOwnerActions {
    /// @notice Authorizes the tokens and their respective price oracles for staking.
    /// @param tokens The token addresses.
    /// @param oracles The price oracle addresses for the token (i.e. value of `tokens[x]` in a matching array index `x`).
    function updatePriceOracles(
        address[] calldata tokens,
        IPriceOracle[] calldata oracles
    ) external;

    /// @notice Mints new JUICE for specified recipients.
    /// @param recipients The JUICE recipients.
    /// @param amounts The minted amounts for the respective recipient (i.e. value of `recipients[x]` in a matching array index `x`).
    function mintJuice(
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external;

    /// @notice Pauses all staking and JUICE ERC-20 activity.
    /// @param pauseStaking True if pausing, false if unpausing.
    function emergencyPause(bool pauseStaking) external;

    /// @notice Sets the new JUICE signal aggregator.
    /// @dev Will call the aggregator with the latest signal
    /// @param aggregator if non-zero, registers the new aggregator address - otherwise unregisters the existing one
    function authorizeSignalAggregator(IJuiceSignalAggregator aggregator)
        external;

    /// @notice Thrown if the owner calls `setPriceOracles` with different sized arrays
    error TokenOracleMismatch(uint256 tokensLength, uint256 oraclesLength);

    /// @notice Thrown if the price oracle has unexpected decimal count
    error OracleDecimalMismatch(uint8 expected, uint8 actual);

    /// @notice Thrown if the owner calls `mintJuice` with different sized arrays
    error MintTargetMismatch(uint256 targetLength, uint256 amountLength);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.10;

import { StakingParam } from "./IJuiceStakerActions.sol";

struct Permission {
    address sender;
    uint256 deadline;
    uint256 nonce;
}

struct SignedPermission {
    Permission data;
    bytes signature;
}

interface IJuiceStakerDelegateActions {
    /// @notice Thrown when SignedPermission.data.sender == address(0)
    error InvalidSender();

    /// @notice Thrown when SignedPermission.data.nonce doesn't match the latest nonce value for the SignedPermission.data.sender
    error InvalidNonce();

    /// @notice Thrown if block.timestamp > SignedPermission.data.deadline
    error PermissionExpired();

    /// @notice Thrown if the address recovered from the SignedPermission.signature doesn't match the SignedPermission.data.sender
    error InvalidSignature();

    /// @notice Deposits JUICE tokens to be used in staking on behalf of permitter
    /// @param amount The deposited amount. If it exceeds permitter's balance, tx reverts with `InsufficientJUICE` error.
    /// @param permission The EIP-712 v4 signed permission object for the deposit operation.
    function delegateDeposit(
        uint256 amount,
        SignedPermission calldata permission
    ) external;

    /// @notice Modifies the permitter's token stakes.
    /// @param stakes The array of StakingParams which are processed in order.
    /// @param permission The EIP-712 v4 signed permission object for the modifyStakes operation.
    function delegateModifyStakes(
        StakingParam[] calldata stakes,
        SignedPermission calldata permission
    ) external;

    /// @notice Withdraws JUICE tokens from the staking contract. Moves `amount` of JUICE from the contract's balance to
    /// permitter's balance.
    /// @param amount The withdrawn amount. If it exceeds permitter's unstaked balance, tx reverts with `InsufficientJUICE` error.
    /// @param permission The EIP-712 v4 signed permission object for the withdraw operation.
    function delegateWithdraw(
        uint256 amount,
        SignedPermission calldata permission
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.10;

import { AggregateTokenSignal } from "./IJuiceStaking.sol";

/// @notice The implementation must only accept calls from authorized token sources.
interface IJuiceSignalAggregator {
    /// @notice Let's the aggregator know that aggregate signal has been updated.
    /// @param tokenSignal the latest signal
    function signalUpdated(AggregateTokenSignal memory tokenSignal) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
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
// OpenZeppelin Contracts v4.4.1 (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
        __ERC1967Upgrade_init_unchained();
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlotUpgradeable.BooleanSlot storage rollbackTesting = StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            _functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271Upgradeable {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}