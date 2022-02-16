//SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "../interfaces/IRouter.sol";
import "../interfaces/IStaking.sol";
import "../pancake-swap/libraries/TransferHelper.sol";

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

//import "hardhat/console.sol";

contract PresalePublicTest is Context, ReentrancyGuard, VRFConsumerBase {
    uint256 private constant DENOMINATOR = 100;
    uint256[9] private POOL_WEIGHT = [
        50,
        100,
        250,
        550,
        1200,
        1900,
        2600,
        7000,
        15000
    ];

    IStaking public immutable STAKING;

    PresaleInfo public generalInfo;
    VestingInfo public vestingInfo;
    PresaleDexInfo public dexInfo;
    IntermediateVariables public intermediate;
    VotingParams public votingParams;

    bool private requested;
    uint256 private random;
    bytes32 private keyHash;
    uint256 private fee;
    uint256 private tokenMagnitude;

    address[] private tier1;
    address[] private tier2;
    address[] private tier3;

    enum Rounds {
        MOON,
        DIAMOND,
        PAPER
    }

    //mapping(uint256 => RoundInfo) public rounds;
    mapping(Rounds => mapping(uint256 => uint256)) public roundTokenAllocation; //round => (level => token amount)
    mapping(uint256 => uint256) public levelsCounter;
    mapping(address => Investor) public registerLevels;
    mapping(address => Investment) public investments; // total wei invested per address
    mapping(address => bool) public lotteryWhitelist;

    mapping(address => bool) private _voteSent;

    struct PresaleInfo {
        address creator;
        address tokenAddress;
        address paymentToken;
        uint256 tokenPrice;
        uint256 hardCap;
        uint256 softCap;
        uint256 openTime;
        uint256 closeTime;
        address unsoldTokenToAddress;
        address feeReceiver;
    }

    struct PresaleDexInfo {
        address dex;
        uint256 listingPrice;
        uint256 lpTokensLockDurationInDays;
        uint8 liquidityPercentageAllocation;
        uint256 liquidityAllocationTime;
    }

    struct VestingInfo {
        uint8 vestingPerc1;
        uint8 vestingPerc2;
        uint256 vestingPeriod;
    }

    struct IntermediateVariables {
        Votes votes;
        bool initialized;
        bool withdrawedFunds;
        uint256 closeTimeVoting;
        address lpAddress;
        uint256 lpAmount;
        uint256 lpUnlockTime;
        //uint256 beginingAmount;
        uint256 tokensForSaleLeft;
        uint256 tokensForLiquidityLeft;
        uint256 raisedAmount;
        uint256 feePercent;
    }

    struct Investment {
        uint256 amountEth;
        uint256 amountTokens;
        uint256 amountClaimed;
    }

    struct Votes {
        uint256 yes;
        uint256 no;
    }

    struct VotingParams {
        uint256 minimum;
        //uint256 duration;
        uint256 threshold;
    }

    struct Investor {
        uint256 level;
        bool lock;
    }

    modifier timing() {
        require(
            generalInfo.closeTime > block.timestamp &&
                block.timestamp >= generalInfo.openTime,
            "TIME"
        );
        _;
    }

    modifier liquidityAdded() {
        require(intermediate.lpAddress != address(0), "LIQ");
        _;
    }

    modifier onlyPresaleCreator() {
        require(_msgSender() == generalInfo.creator, "CREATOR");
        _;
    }

    modifier initialized() {
        require(intermediate.initialized, "INIT");
        _;
    }

    constructor(
        address staking,
        address _VRFCoordinator,
        address _LINK_ADDRESS,
        bytes32 _keyHash,
        uint256 _fee,
        PresaleInfo memory _info,
        PresaleDexInfo memory _dexInfo,
        VestingInfo memory _vestInfo
    ) VRFConsumerBase(_VRFCoordinator, _LINK_ADDRESS) {
        require(
            _info.openTime >= block.timestamp + 2 weeks + 48 hours &&
                _info.openTime + 9 hours <= _info.closeTime &&
                _info.closeTime < _dexInfo.liquidityAllocationTime,
            "TIME"
        );
        require(
            _info.softCap <= _info.hardCap &&
                _info.hardCap >= _info.tokenPrice &&
                _dexInfo.listingPrice > 0 &&
                _info.tokenPrice > 0 &&
                _dexInfo.lpTokensLockDurationInDays > 0 &&
                _dexInfo.liquidityPercentageAllocation > 0 &&
                _vestInfo.vestingPerc1 + _vestInfo.vestingPerc2 <=
                DENOMINATOR &&
                _vestInfo.vestingPeriod > 0,
            "AMOUNTS"
        );
        require(
            _info.creator != address(0) &&
                _info.unsoldTokenToAddress != address(0) &&
                _dexInfo.dex != address(0) &&
                _info.tokenAddress != address(0) &&
                staking != address(0) &&
                _info.feeReceiver != address(0),
            "ADDRESSES"
        );

        keyHash = _keyHash;
        fee = _fee;
        STAKING = IStaking(staking);

        votingParams = VotingParams(
            (10**10) * (10**18),
            /* 2 weeks, */
            2 * (10**5)
        );

        tokenMagnitude = 10**IERC20Metadata(_info.tokenAddress).decimals();

        intermediate.closeTimeVoting = block.timestamp + 2 weeks;
        intermediate.tokensForSaleLeft =
            (_info.hardCap * tokenMagnitude) /
            _info.tokenPrice;
        /* intermediate.beginingAmount =
            (_info.hardCap * tokenMagnitude) /
            _info.tokenPrice; */
        intermediate.tokensForLiquidityLeft =
            (_info.hardCap *
                _dexInfo.liquidityPercentageAllocation *
                tokenMagnitude) /
            (DENOMINATOR * _dexInfo.listingPrice);

        generalInfo = _info;
        dexInfo = _dexInfo;
        vestingInfo = _vestInfo;
    }

    function initialize() external nonReentrant onlyPresaleCreator {
        require(!intermediate.initialized, "ONCE");
        intermediate.initialized = true;
        intermediate.closeTimeVoting = block.timestamp + 5 minutes;
        generalInfo.openTime = intermediate.closeTimeVoting + 9 minutes;
        generalInfo.closeTime = generalInfo.openTime + 15 minutes;
        dexInfo.liquidityAllocationTime = generalInfo.closeTime + 1 minutes;
        TransferHelper.safeTransferFrom(
            generalInfo.tokenAddress,
            generalInfo.creator,
            address(this),
            intermediate.tokensForSaleLeft + intermediate.tokensForLiquidityLeft
        );
        TransferHelper.safeTransferFrom(
            address(LINK),
            generalInfo.creator,
            address(this),
            fee
        );
    }

    function setFeePerc(uint256 perc) external {
        require(_msgSender() == generalInfo.feeReceiver && perc < DENOMINATOR);
        intermediate.feePercent = perc;
    }

    function vote(bool yes) external initialized {
        require(intermediate.closeTimeVoting >= block.timestamp, "TIME");
        address sender = _msgSender();
        (uint256 level, uint256 amount, , , , , , , ) = STAKING.stakeForUser(
            sender,
            0
        );
        amount /= votingParams.minimum;
        require(level > 0 && !_voteSent[sender] && amount > 0, "WRONG LEVEL");

        _voteSent[sender] = true;
        if (yes) intermediate.votes.yes += amount;
        else intermediate.votes.no += amount;
    }

    function register() external initialized {
        require(
            intermediate.votes.yes >=
                intermediate.votes.no + votingParams.threshold,
            "NOT PASSED"
        );
        uint256 currentTime = block.timestamp;
        require(
            generalInfo.openTime <= currentTime + 7 minutes &&
                generalInfo.openTime >= currentTime + 2 minutes,
            "TIME"
        );
        address sender = _msgSender();
        (uint256 level, , , , bool lock30, bool lock90, , , ) = STAKING
            .stakeForUser(sender, 0);
        require(level > 0 && registerLevels[sender].level == 0, "WRONG LEVEL");

        lock30 = lock30 || lock90;
        registerLevels[sender] = Investor(level, lock30);
        levelsCounter[level]++;
        if ((level > 0 && level < 4) && lock30) levelsCounter[10 + level]++;

        if (level == 1) tier1.push(sender);
        if (level == 2) tier2.push(sender);
        if (level == 3) tier3.push(sender);
    }

    function invest(uint256 payAmount)
        external
        payable
        timing
        nonReentrant
        initialized
    {
        if (!requested && LINK.balanceOf(address(this)) >= fee) {
            requested = true;
            requestRandomness(keyHash, fee);
        }
        if (random > 0) expand();
        address sender1 = _msgSender();
        Investor memory sender = registerLevels[sender1];
        Investment storage investor = investments[sender1];
        uint256 currentTime = block.timestamp;
        payAmount = (generalInfo.paymentToken == address(0))
            ? msg.value
            : payAmount;
        require(payAmount > 0);

        uint256 investmentFee;
        if (intermediate.feePercent > 0) {
            investmentFee = (payAmount * intermediate.feePercent) / DENOMINATOR;
            payAmount -= investmentFee;
        }

        uint256 tokenAmount;
        Rounds round;

        if (currentTime <= generalInfo.openTime + 3 minutes) {
            //MOON ROUND
            require(sender.level > 3 && sender.level < 10, "Not available");
            if (roundTokenAllocation[Rounds.MOON][10] == 0)
                _getTokenAllocation(Rounds.MOON);

            round = Rounds.MOON;
        } else if (
            currentTime >= generalInfo.openTime + 5 minutes &&
            currentTime <= generalInfo.openTime + 8 minutes
        ) {
            //DIAMOND ROUND
            require(
                (sender.level > 3 && sender.level < 10) || sender.lock,
                "Not available"
            );
            if (sender.level > 0 && sender.level < 4) {
                require(lotteryWhitelist[sender1], "LOOSE");
            }
            if (roundTokenAllocation[Rounds.DIAMOND][10] == 0)
                _getTokenAllocation(Rounds.DIAMOND);

            round = Rounds.DIAMOND;
        } else if (currentTime >= generalInfo.openTime + 10 minutes) {
            //PAPER ROUND
            require(sender.level > 0 && sender.level < 10, "Not available");
            if (sender.level > 0 && sender.level < 4) {
                require(lotteryWhitelist[sender1], "LOOSE");
            }
            if (roundTokenAllocation[Rounds.PAPER][10] == 0)
                _getTokenAllocation(Rounds.PAPER);

            round = Rounds.PAPER;
        } else revert("REST");

        tokenAmount = _getTokenAmount(payAmount);

        require(
            roundTokenAllocation[round][sender.level] >= tokenAmount &&
                intermediate.tokensForSaleLeft >= tokenAmount &&
                tokenAmount > 0
        );

        roundTokenAllocation[round][sender.level] -= tokenAmount;
        intermediate.tokensForSaleLeft -= tokenAmount;
        investor.amountEth += payAmount;
        investor.amountTokens += tokenAmount;
        intermediate.raisedAmount += payAmount;

        if (generalInfo.paymentToken != address(0)) {
            TransferHelper.safeTransferFrom(
                generalInfo.paymentToken,
                sender1,
                address(this),
                payAmount
            );
            if (investmentFee > 0) {
                TransferHelper.safeTransferFrom(
                    generalInfo.paymentToken,
                    sender1,
                    generalInfo.feeReceiver,
                    investmentFee
                );
            }
        } else if (investmentFee > 0) {
            TransferHelper.safeTransferETH(
                generalInfo.feeReceiver,
                investmentFee
            );
        }
    }

    function addLiquidity()
        external
        nonReentrant
        onlyPresaleCreator
        initialized
    {
        uint256 currentTime = block.timestamp;
        require(
            intermediate.raisedAmount >= generalInfo.softCap &&
                currentTime >= dexInfo.liquidityAllocationTime
        );

        IRouter router = IRouter(dexInfo.dex);
        IFactory factory = IFactory(router.factory());

        uint256 paymentAmount = (intermediate.raisedAmount *
            dexInfo.liquidityPercentageAllocation) / DENOMINATOR;
        uint256 tokenAmount = (paymentAmount * tokenMagnitude) /
            dexInfo.listingPrice;
        require(
            paymentAmount > 0 &&
                tokenAmount > intermediate.tokensForLiquidityLeft
        );
        /* intermediate.raisedAmount -= paymentAmount;
        intermediate.tokensForLiquidityLeft -= tokenAmount; */

        TransferHelper.safeApprove(
            generalInfo.tokenAddress,
            dexInfo.dex,
            tokenAmount
        );

        uint256 amountEth;
        uint256 amountToken;

        intermediate.lpUnlockTime =
            currentTime +
            dexInfo.lpTokensLockDurationInDays *
            1 minutes;
        if (generalInfo.paymentToken == address(0)) {
            (amountToken, amountEth, intermediate.lpAmount) = router
                .addLiquidityETH{value: paymentAmount}(
                generalInfo.tokenAddress,
                tokenAmount,
                0,
                0,
                address(this),
                currentTime
            );

            intermediate.lpAddress = factory.getPair(
                router.WETH(),
                generalInfo.tokenAddress
            );
        } else {
            TransferHelper.safeApprove(
                generalInfo.paymentToken,
                dexInfo.dex,
                paymentAmount
            );

            (amountEth, amountToken, intermediate.lpAmount) = router
                .addLiquidity(
                    generalInfo.paymentToken,
                    generalInfo.tokenAddress,
                    paymentAmount,
                    tokenAmount,
                    0,
                    0,
                    address(this),
                    currentTime
                );

            intermediate.lpAddress = factory.getPair(
                generalInfo.paymentToken,
                generalInfo.tokenAddress
            );
        }

        intermediate.raisedAmount -= amountEth;
        intermediate.tokensForLiquidityLeft -= amountToken;
    }

    function claimTokens() external nonReentrant liquidityAdded initialized {
        address sender = _msgSender();
        Investment storage investor = investments[sender];
        require(
            investor.amountTokens > 0 &&
                investor.amountClaimed < investor.amountTokens
        );

        if (
            (vestingInfo.vestingPerc1 == 0 && vestingInfo.vestingPerc2 == 0) ||
            vestingInfo.vestingPeriod == 0
        ) {
            investor.amountClaimed = investor.amountTokens;
            TransferHelper.safeTransfer(
                generalInfo.tokenAddress,
                sender,
                investor.amountTokens
            );
        } else {
            uint256 amount = (investor.amountTokens *
                vestingInfo.vestingPerc1) / DENOMINATOR;
            uint256 beginingTime = intermediate.lpUnlockTime -
                dexInfo.lpTokensLockDurationInDays *
                1 days;
            uint256 numOfParts = (block.timestamp - beginingTime) /
                vestingInfo.vestingPeriod;
            uint256 part = (investor.amountTokens * vestingInfo.vestingPerc2) /
                DENOMINATOR;

            amount += numOfParts * part;
            amount -= investor.amountClaimed;
            require(amount > 0, "0");
            investor.amountClaimed += amount;

            TransferHelper.safeTransfer(
                generalInfo.tokenAddress,
                sender,
                amount
            );
        }
    }

    function claimRaisedFunds()
        external
        nonReentrant
        onlyPresaleCreator
        liquidityAdded
        initialized
    {
        require(!intermediate.withdrawedFunds);
        intermediate.withdrawedFunds = true;

        address sender = _msgSender();
        uint256 unsoldTokensAmount = intermediate.tokensForSaleLeft +
            intermediate.tokensForLiquidityLeft;

        if (unsoldTokensAmount > 0) {
            TransferHelper.safeTransfer(
                generalInfo.tokenAddress,
                generalInfo.unsoldTokenToAddress,
                unsoldTokensAmount
            );
        }

        if (generalInfo.paymentToken == address(0)) {
            TransferHelper.safeTransferETH(sender, intermediate.raisedAmount);
        } else
            TransferHelper.safeTransfer(
                generalInfo.paymentToken,
                sender,
                intermediate.raisedAmount
            );
    }

    //UNSUCCESSFUL SCENARIO----------------------------------------
    function withdrawInvestment() external nonReentrant initialized {
        require(
            block.timestamp > generalInfo.closeTime &&
                intermediate.lpAddress == address(0) &&
                intermediate.raisedAmount < generalInfo.softCap
        );

        address sender = _msgSender();
        uint256 investmentAmount = investments[sender].amountEth;
        require(investmentAmount > 0);

        delete (investments[sender]);

        if (generalInfo.paymentToken == address(0))
            TransferHelper.safeTransferETH(sender, investmentAmount);
        else
            TransferHelper.safeTransfer(
                generalInfo.paymentToken,
                sender,
                investmentAmount
            );
    }

    function withdrawTokens()
        external
        nonReentrant
        onlyPresaleCreator
        initialized
    {
        require(
            block.timestamp > generalInfo.closeTime &&
                intermediate.lpAddress == address(0) &&
                intermediate.raisedAmount < generalInfo.softCap
        );

        uint256 amount = IERC20(generalInfo.tokenAddress).balanceOf(
            address(this)
        );
        require(amount > 0);
        TransferHelper.safeTransfer(
            generalInfo.tokenAddress,
            generalInfo.creator,
            amount
        );
    }

    //-------------------------------------------------------------

    //TODO: rewrite fulfillRandomness() func to avoid out of gas
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        random = randomness;
        /* uint256 i;
        uint256 index;
        uint256 n = (levelsCounter[1] * 15) / DENOMINATOR;
        for (i; i < n; i++) {
            index = uint256(keccak256(abi.encode(randomness, i)));
            index = (index % n) + 1;
            while (lotteryWhitelist[tier1[index]] && index < tier1.length)
                index++;
            lotteryWhitelist[tier1[index]] = true;
        }

        n = (levelsCounter[2] * 35) / DENOMINATOR;
        for (i = 0; i < n; i++) {
            index = uint256(keccak256(abi.encode(randomness, i)));
            index = (index % n) + 1;
            while (lotteryWhitelist[tier2[index]] && index < tier2.length)
                index++;
            lotteryWhitelist[tier2[index]] = true;
        }

        n = (levelsCounter[3] * 80) / DENOMINATOR;
        for (i = 0; i < n; i++) {
            index = uint256(keccak256(abi.encode(randomness, i)));
            index = (index % n) + 1;
            while (lotteryWhitelist[tier3[index]] && index < tier3.length)
                index++;
            lotteryWhitelist[tier3[index]] = true;
        } */
        /* uint256 one = (levelsCounter[1] * 15) / DENOMINATOR;
        uint256 two = (levelsCounter[2] * 35) / DENOMINATOR;
        uint256 three = (levelsCounter[3] * 80) / DENOMINATOR;
        uint256[] memory randomValues1 = expand(randomness, one);
        uint256[] memory randomValues2 = expand(randomness, two);
        uint256[] memory randomValues3 = expand(randomness, three);

        uint256 i;
        uint256 index;
        for (i; i < randomValues1.length; i++) {
            index = (randomValues1[i] % one) + 1;
            while (lotteryWhitelist[tier1[index]]) index++;
            lotteryWhitelist[tier1[index]] = true;
        }
        for (i = 0; i < randomValues2.length; i++) {
            index = (randomValues2[i] % two) + 1;
            while (lotteryWhitelist[tier2[index]]) index++;
            lotteryWhitelist[tier2[index]] = true;
        }
        for (i = 0; i < randomValues3.length; i++) {
            index = (randomValues3[i] % two) + 1;
            while (lotteryWhitelist[tier3[index]]) index++;
            lotteryWhitelist[tier3[index]] = true;
        } */
    }

    function expand() private {
        uint256 i;
        uint256 index;
        uint256 n = (levelsCounter[1] * 15) / DENOMINATOR;
        for (i; i < n; i++) {
            index = uint256(keccak256(abi.encode(random, i)));
            index = (index % n) + 1;
            while (lotteryWhitelist[tier1[index]] && index < tier1.length)
                index++;
            lotteryWhitelist[tier1[index]] = true;
        }

        n = (levelsCounter[2] * 35) / DENOMINATOR;
        for (i = 0; i < n; i++) {
            index = uint256(keccak256(abi.encode(random, i)));
            index = (index % n) + 1;
            while (lotteryWhitelist[tier2[index]] && index < tier2.length)
                index++;
            lotteryWhitelist[tier2[index]] = true;
        }

        n = (levelsCounter[3] * 80) / DENOMINATOR;
        for (i = 0; i < n; i++) {
            index = uint256(keccak256(abi.encode(random, i)));
            index = (index % n) + 1;
            while (lotteryWhitelist[tier3[index]] && index < tier3.length)
                index++;
            lotteryWhitelist[tier3[index]] = true;
        }

        random = 0;
    }

    function _getTokenAllocation(Rounds _round) private {
        uint256 totalShares;
        uint256 eachPoolShare;
        uint256 i;

        if (_round == Rounds.MOON) {
            //set flag
            roundTokenAllocation[Rounds.MOON][10] = 1;

            for (i = 4; i < 10; i++)
                totalShares +=
                    (levelsCounter[i] * POOL_WEIGHT[i - 1]) /
                    DENOMINATOR;

            eachPoolShare = intermediate.tokensForSaleLeft / totalShares;

            for (i = 4; i < 10; i++)
                roundTokenAllocation[Rounds.MOON][i] =
                    ((eachPoolShare * POOL_WEIGHT[i - 1]) / DENOMINATOR) *
                    levelsCounter[i];
        } else if (_round == Rounds.DIAMOND) {
            //set flag
            roundTokenAllocation[Rounds.DIAMOND][10] = 1;

            for (i = 1; i < 10; i++) {
                if (i > 0 && i < 4) {
                    totalShares +=
                        (levelsCounter[10 + i] * POOL_WEIGHT[i - 1]) /
                        DENOMINATOR;
                } else
                    totalShares +=
                        (levelsCounter[i] * POOL_WEIGHT[i - 1]) /
                        DENOMINATOR;
            }

            eachPoolShare = intermediate.tokensForSaleLeft / totalShares;

            for (i = 1; i < 10; i++) {
                if (i > 0 && i < 4) {
                    roundTokenAllocation[Rounds.DIAMOND][i] =
                        ((eachPoolShare * POOL_WEIGHT[i - 1]) / DENOMINATOR) *
                        levelsCounter[i + 10];
                } else
                    roundTokenAllocation[Rounds.DIAMOND][i] =
                        ((eachPoolShare * POOL_WEIGHT[i - 1]) / DENOMINATOR) *
                        levelsCounter[i];
            }
        } else if (_round == Rounds.PAPER) {
            //set flag
            roundTokenAllocation[Rounds.PAPER][10] = 1;

            for (i = 1; i < 10; i++) {
                totalShares +=
                    (levelsCounter[i] * POOL_WEIGHT[i - 1]) /
                    DENOMINATOR;
            }

            eachPoolShare = intermediate.tokensForSaleLeft / totalShares;

            for (i = 1; i < 10; i++) {
                roundTokenAllocation[Rounds.PAPER][i] =
                    ((eachPoolShare * POOL_WEIGHT[i - 1]) / DENOMINATOR) *
                    levelsCounter[i];
            }
        }
    }

    function _getTokenAmount(uint256 _weiAmount)
        private
        view
        returns (uint256)
    {
        return (_weiAmount * tokenMagnitude) / generalInfo.tokenPrice;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IRouter {
    function factory() external view returns (address);

    function WETH() external view returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );
}

interface IFactory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


interface IStaking{
    
    
    function stakeForUser(address user, uint256 lockUp) external
        returns (
            uint256 level,
            uint256 totalStakedForUser,
            bool first_lock,
            bool second_lock,
            bool third_lock,
            bool fourth_lock,
            uint256 amountLock,
            uint256 rewardTaken,
            uint256 enteredAt
        );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(
            success,
            "TransferHelper::safeTransferETH: ETH transfer failed"
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/LinkTokenInterface.sol";

import "./VRFRequestIDBase.sol";

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {
  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 private constant USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(bytes32 _keyHash, uint256 _fee) internal returns (bytes32 requestId) {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface internal immutable LINK;
  address private immutable vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 => uint256) /* keyHash */ /* nonce */
    private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(address _vrfCoordinator, address _link) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VRFRequestIDBase {
  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  ) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

// SPDX-License-Identifier: MIT
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