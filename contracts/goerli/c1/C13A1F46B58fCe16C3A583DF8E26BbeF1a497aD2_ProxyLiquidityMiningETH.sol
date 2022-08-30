// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.15;
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./ProxyLiquidityMining.sol";

contract ProxyLiquidityMiningETH is ProxyLiquidityMining {
    using SafeERC20 for IERC20;

    constructor(
        address router_,
        address _DFI,
        address _secondToken,
        address _pair,
        uint256 _admin_speed
    ) ProxyLiquidityMining(router_, _DFI, _secondToken, _pair, _admin_speed) {}

    /**
     * @notice Add liquidity to the pool
     * User will need to approve this proxy to spend their at least
     * "amountDFIDesired" amount first
     * @param amountDFIDesired maximum amount of DFI to be deposited into DFI-ETH pool (required by UniswapV2Router02)
     * @param amountDFIMin minimum amount of DFI to be deposited into DFI-ETH pool (required by UniswapV2Router02)
     * @param amountETHMin minimum amount of ETH/WETH to be deposited into DFI-ETH pool (required by UniswapV2Router02)
     * @param deadline the deadline required by UniswapV2Router02
     */
    function addLiquidityETH(
        uint256 amountDFIDesired,
        uint256 amountDFIMin,
        uint256 amountETHMin,
        uint256 deadline
    )
        external
        payable
        nonReentrant
        returns (
            uint256 amountDFI,
            uint256 amountETH,
            uint256 liquidity
        )
    {
        beforeHook(msg.sender);
        DFI.safeTransferFrom(msg.sender, address(this), amountDFIDesired);
        // amountDFI: actual amount of DFI sent to the pair
        // amountETH: actual amount of WETH sent to the pair
        (amountDFI, amountETH, liquidity) = router.addLiquidityETH{
            value: msg.value
        }(
            address(DFI),
            amountDFIDesired,
            amountDFIMin,
            amountETHMin,
            address(this),
            deadline
        );
        _addLiquidity(msg.sender, liquidity);
        uint256 returnDFI = amountDFIDesired - amountDFI;
        uint256 returnETH = msg.value - amountETH;
        if (returnDFI > 0) DFI.safeTransfer(msg.sender, returnDFI);
        if (returnETH > 0) {
            (bool sent, ) = payable(msg.sender).call{value: returnETH}("");
            require(sent, "Failed to return redundant Ether back to user");
        }
        emit LIQUIDITY_ADDED(msg.sender, liquidity);
    }

    /**
     * @notice remove liquidity from the pool, user is going to receive
     * their share of DFI + ETH from the DFI-ETH  pool and DFI rewards thanks to liquidity mining
     * @param liquidity the amount of LP tokens that is going to be unstaked
     * @param amountDFIMin the minimum DFI tokens that is going to be returned to staker (from the Uniswap DFI-ETH pool)
     * @param amountETHMin minimum ETH that is going to be returned to staker (from the Uniswap DFI-ETH pool)
     * @param deadline the deadline for this action to be performed
     */
    function removeLiquidityETH(
        uint256 liquidity,
        uint256 amountDFIMin,
        uint256 amountETHMin,
        uint256 deadline
    ) external nonReentrant returns (uint256 amountDFI, uint256 amountETH) {
        require(
            stakingMap[msg.sender] >= liquidity,
            "User does not have enough liquidity"
        );
        beforeHook(msg.sender);
        _removeLiquidity(msg.sender, liquidity);
        _claimRewards(msg.sender);
        // router will send "liquidity" LP tokens back to the pool
        // for burning
        (amountDFI, amountETH) = router.removeLiquidityETH(
            address(DFI),
            liquidity,
            amountDFIMin,
            amountETHMin,
            msg.sender,
            deadline
        );
        emit LIQUIDITY_REMOVED(msg.sender, liquidity);
    }

    /**
     * @notice remove liquidity from the pool without claiming rewards
     */
    function removeLiquidityETHWithoutClaimingRewards(
        uint256 liquidity,
        uint256 amountDFIMin,
        uint256 amountETHMin,
        uint256 deadline
    ) external nonReentrant returns (uint256 amountDFI, uint256 amountETH) {
        require(
            stakingMap[msg.sender] >= liquidity,
            "User does not have enough liquidity"
        );
        beforeHook(msg.sender);
        _removeLiquidity(msg.sender, liquidity);
        // router will send "liquidity" LP tokens back to the pool
        // for burning
        (amountDFI, amountETH) = router.removeLiquidityETH(
            address(DFI),
            liquidity,
            amountDFIMin,
            amountETHMin,
            msg.sender,
            deadline
        );
        emit LIQUIDITY_REMOVED(msg.sender, liquidity);
    }

    /**
     * @notice remove liquidity in emergency
     */
    function removeLiquidityETHInEmergency(
        uint256 liquidity,
        uint256 amountDFIMin,
        uint256 amountETHMin,
        uint256 deadline
    ) external nonReentrant returns (uint256 amountDFI, uint256 amountETH) {
        require(emergency, "Not in emergency mode yet");
        require(
            stakingMap[msg.sender] >= liquidity,
            "User does not have enough liquidity"
        );
        _removeLiquidity(msg.sender, liquidity);
        // router will send "liquidity" LP tokens back to the pool
        // for burning
        (amountDFI, amountETH) = router.removeLiquidityETH(
            address(DFI),
            liquidity,
            amountDFIMin,
            amountETHMin,
            msg.sender,
            deadline
        );
        emit LIQUIDITY_REMOVED(msg.sender, liquidity);
    }

    /**
     * @notice main purpose is to allow the router to pay back ETH to this contract
     * when the ratio of DFI/ETH deposited is not ideal
     */
    receive() external payable {}
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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.15;
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./LiquidityMiningLogic.sol";

contract ProxyLiquidityMining is LiquidityMiningLogic, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IUniswapV2Router02 public immutable router;
    IERC20 public immutable secondToken;
    IERC20 public immutable pair;

    constructor(
        address router_,
        address _DFI,
        address _secondToken,
        address _pair,
        uint256 _admin_speed
    ) LiquidityMiningLogic(_DFI, _admin_speed) {
        router = IUniswapV2Router02(router_);
        secondToken = IERC20(_secondToken);
        pair = IERC20(_pair);
        IERC20(_DFI).safeApprove(router_, MAX_INT);
        IERC20(_secondToken).safeApprove(router_, MAX_INT);
        IERC20(_pair).safeApprove(router_, MAX_INT);
    }

    /**
     * @notice Add liquidity to the pool
     * User will need to approve this proxy to spend their at least
     * "amountDFIDesired" amount and "amountsecondTokenDesired" amount first
     * @param amountDFIDesired maximum amount of DFI to be deposited into DFI-secondToken pool (required by UniswapV2Router02)
     * @param amountsecondTokenDesired maximum amount of secondToken to be deposited into DFI-secondToken pool (required by UniswapV2Router02)
     * @param amountDFIMin minimum amount of DFI to be deposited into DFI-secondToken pool (required by UniswapV2Router02)
     * @param amountsecondTokenMin minimum amount of secondToken to be deposited into DFI-secondToken pool (required by UniswapV2Router02)
     * @param deadline the deadline required by UniswapV2Router02
     */
    function addLiquidity(
        uint256 amountDFIDesired,
        uint256 amountsecondTokenDesired,
        uint256 amountDFIMin,
        uint256 amountsecondTokenMin,
        uint256 deadline
    )
        external
        nonReentrant
        returns (
            uint256 amountDFI,
            uint256 amountsecondToken,
            uint256 liquidity
        )
    {
        beforeHook(msg.sender);
        DFI.safeTransferFrom(msg.sender, address(this), amountDFIDesired);
        secondToken.safeTransferFrom(
            msg.sender,
            address(this),
            amountsecondTokenDesired
        );
        // amountDFI: actual amount of DFI sent to the pair
        // amountsecondToken: actual amount of secondToken sent to the pair
        (amountDFI, amountsecondToken, liquidity) = router.addLiquidity(
            address(DFI),
            address(secondToken),
            amountDFIDesired,
            amountsecondTokenDesired,
            amountDFIMin,
            amountsecondTokenMin,
            address(this),
            deadline
        );
        _addLiquidity(msg.sender, liquidity);
        uint256 returnDFI = amountDFIDesired - amountDFI;
        uint256 returnsecondToken = amountsecondTokenDesired -
            amountsecondToken;
        if (returnDFI > 0) DFI.safeTransfer(msg.sender, returnDFI);
        if (returnsecondToken > 0)
            secondToken.safeTransfer(msg.sender, returnsecondToken);
        emit LIQUIDITY_ADDED(msg.sender, liquidity);
    }

    /**
     * @notice remove liquidity from the pool, user is going to receive
     * their share of DFI + secondToken from the DFI-secondToken  pool and DFI rewards thanks to liquidity mining
     * @param liquidity the amount of LP tokens that is going to be unstaked
     * @param amountDFIMin the minimum DFI tokens that is going to be returned to staker (from the Uniswap DFI-secondToken pool)
     * @param amountsecondTokenMin minimum secondToken tokens that is going to be returned to staker (from the Uniswap DFI-secondToken pool)
     * @param deadline the deadline for this action to be performed
     */
    function removeLiquidity(
        uint256 liquidity,
        uint256 amountDFIMin,
        uint256 amountsecondTokenMin,
        uint256 deadline
    )
        external
        nonReentrant
        returns (uint256 amountDFI, uint256 amountsecondToken)
    {
        require(
            stakingMap[msg.sender] >= liquidity,
            "User does not have enough liquidity"
        );
        beforeHook(msg.sender);
        _removeLiquidity(msg.sender, liquidity);
        _claimRewards(msg.sender);
        // router will send "liquidity" LP tokens back to the pool
        // for burning
        (amountDFI, amountsecondToken) = router.removeLiquidity(
            address(DFI),
            address(secondToken),
            liquidity,
            amountDFIMin,
            amountsecondTokenMin,
            msg.sender,
            deadline
        );
        emit LIQUIDITY_REMOVED(msg.sender, liquidity);
    }

    /**
     * @notice remove liquidity from the pool without claiming rewards
     */
    function removeLiquidityWithoutClaimingRewards(
        uint256 liquidity,
        uint256 amountDFIMin,
        uint256 amountsecondTokenMin,
        uint256 deadline
    )
        external
        nonReentrant
        returns (uint256 amountDFI, uint256 amountsecondToken)
    {
        require(
            stakingMap[msg.sender] >= liquidity,
            "User does not have enough liquidity"
        );
        beforeHook(msg.sender);
        _removeLiquidity(msg.sender, liquidity);
        // router will send "liquidity" LP tokens back to the pool
        // for burning
        (amountDFI, amountsecondToken) = router.removeLiquidity(
            address(DFI),
            address(secondToken),
            liquidity,
            amountDFIMin,
            amountsecondTokenMin,
            msg.sender,
            deadline
        );
        emit LIQUIDITY_REMOVED(msg.sender, liquidity);
    }


    /**
     * @notice remove liquidity from the pool in case of emergency
     */
    function removeLiquidityInEmergency(
        uint256 liquidity,
        uint256 amountDFIMin,
        uint256 amountsecondTokenMin,
        uint256 deadline
    )
        external
        nonReentrant
        returns (uint256 amountDFI, uint256 amountsecondToken)
    {
        require(emergency, "Not be in emergency mode yet");
        require(
            stakingMap[msg.sender] >= liquidity,
            "User does not have enough liquidity"
        );
        _removeLiquidity(msg.sender, liquidity);
        // router will send "liquidity" LP tokens back to the pool
        // for burning
        (amountDFI, amountsecondToken) = router.removeLiquidity(
            address(DFI),
            address(secondToken),
            liquidity,
            amountDFIMin,
            amountsecondTokenMin,
            msg.sender,
            deadline
        );
        emit LIQUIDITY_REMOVED(msg.sender, liquidity);
    }

    /**
     * @notice reset the allowance for the router by this contract, 
     * in case the allowances are too low
     */
    function resetAllowances() external {
        address routerAddr = address(router);
        DFI.safeApprove(routerAddr, 0);
        DFI.safeApprove(routerAddr, MAX_INT);
        secondToken.safeApprove(routerAddr, 0);
        secondToken.safeApprove(routerAddr, MAX_INT);
        pair.safeApprove(routerAddr, 0);
        pair.safeApprove(routerAddr, MAX_INT);
    }
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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.15;
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract LiquidityMiningLogic is AccessControl {
    struct MarketState {
        uint256 index; // sum of reward_at_block_i / total_stake_at_block_i (i is the block number) before the current block
        uint256 lastBlockNum;
        uint256 epoch;
    }
    using SafeERC20 for IERC20;
    enum STAGE { NO_REWARD_PERIOD, COLD_START, AFTER_COLD_START, END_REWARD_PERIOD}


    uint256 constant MAX_INT = type(uint256).max;
    // every week, the reward per block will be decreased by 4 percent, so we need this constant
    uint256 constant BLOCKS_PER_WEEK = 6000 * 7;
    uint256 public rewardSpeed;
    uint256 public totalStake;
    uint256 public endColdStartBlockNum;
    uint256 public admin_speed;
    uint256 public totalRewardAccrued;
    bool public emergency;

    STAGE public contract_stage;
    MarketState public marketState;
    IERC20 public immutable DFI;

    mapping(address => uint256) public stakingMap;
    mapping(address => uint256) public rewardAccrueds;
    mapping(address => uint256) public recipientIndexes;

    event REWARD_CLAIMED(
        address indexed recipient,
        uint256 amount,
        bool hasDFILeft
    );
    event LIQUIDITY_ADDED(address indexed user, uint256 liquidityAdded);
    event LIQUIDITY_REMOVED(address indexed user, uint256 liquidityRemoved);

    constructor(address _DFI, uint256 _admin_speed) {
        DFI = IERC20(_DFI);
        marketState = MarketState({
            index: 0,
            lastBlockNum: block.number,
            epoch: 0
        });
        admin_speed = _admin_speed;
        contract_stage = STAGE.NO_REWARD_PERIOD;
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    }

    /**
     * @notice Update the sum of reward per stake up to before the current block
     * (by leveraging the periods of constant total stake)
     * State vars to be updated: 
     * - rewardSpeed
     * - marketState.index 
     * - marketState.epoch
     * - marketState.lastBlockNum
     * - totalRewardAccrued
     */
    function _updateRewardIndex() internal {
        uint256 blockNumber = block.number;
        uint256 rewardAccrued;
        if (contract_stage == STAGE.COLD_START) {
            rewardAccrued =
                rewardSpeed *
                (blockNumber - marketState.lastBlockNum);
        } else if (contract_stage == STAGE.AFTER_COLD_START) {
            uint256 updateEpoch = (blockNumber - endColdStartBlockNum) /
                BLOCKS_PER_WEEK;
            if (updateEpoch > marketState.epoch) {
                uint256 checkPoint = (marketState.epoch + 1) *
                    BLOCKS_PER_WEEK +
                    endColdStartBlockNum;
                uint256 rewardAccruedBeforeFirstEpochEnds = rewardSpeed *
                    (checkPoint - marketState.lastBlockNum);
                checkPoint += BLOCKS_PER_WEEK;
                uint256 _rewardSpeed = rewardSpeed;
                while (checkPoint <= blockNumber) {
                    _rewardSpeed = (_rewardSpeed * 96) / 100;
                    rewardAccrued += _rewardSpeed * BLOCKS_PER_WEEK;
                    checkPoint += BLOCKS_PER_WEEK;
                }
                _rewardSpeed = (_rewardSpeed * 96) / 100;
                uint256 rewardAccruedInTheFinalEpoch = _rewardSpeed *
                    (blockNumber + BLOCKS_PER_WEEK - checkPoint);
                rewardAccrued +=
                    rewardAccruedBeforeFirstEpochEnds +
                    rewardAccruedInTheFinalEpoch;
                marketState.epoch = updateEpoch;
                rewardSpeed = _rewardSpeed;
            } else
                rewardAccrued =
                    rewardSpeed *
                    (blockNumber - marketState.lastBlockNum);
        }
        
        marketState.lastBlockNum = blockNumber;
        if (totalStake != 0) {
            marketState.index += (rewardAccrued * 1e18) / totalStake;
            totalRewardAccrued += rewardAccrued;
        }
    }

    /**
     * @notice Update the accrued reward of a recipient
     * @param recipient The recipient of the reward
     */
    function _distributeRewards(address recipient) internal {
        uint256 marketIndex = marketState.index;
        uint256 deltaIndex = marketIndex - recipientIndexes[recipient];
        recipientIndexes[recipient] = marketIndex;

        uint256 recipientDelta = (stakingMap[recipient] * deltaIndex) / 1e18;
        rewardAccrueds[recipient] += recipientDelta;
    }

    /**
     * @notice used to update the reward index and
     * and update the reward accrued of the recipient
     * @param recipient the recipient of the reward
     */
    function beforeHook(address recipient) public notInEmergency {
        // if beforeHook fails, addliquidity/ removeliquidity functions will fail (except for removeLiquidity that is enabled in emergency mode)
        // and claimRewards will also fail
        // calculate the index up to before the current block
        _updateRewardIndex();
        // distribute reward to the recipient (reward is calculated up to before the current block)
        _distributeRewards(recipient);
    }

    /**
     * @notice Claim rewards and transfer these DFI rewards to recipient
     * anyone can call this function
     * @param recipient the recipient of the reward
     */
    function claimRewards(address recipient) external {
        beforeHook(recipient);
        _claimRewards(recipient);
    }

    /**
     * @notice internal function to claim rewards
     * @param recipient the recipient of the DFI rewards
     */
    function _claimRewards(address recipient) internal {
        if (rewardAccrueds[recipient] == 0) return;
        uint256 proxyBalance = DFI.balanceOf(address(this));
        if (proxyBalance == 0) return;
        if (proxyBalance > rewardAccrueds[recipient]) {
            uint256 rewardToTransfer = rewardAccrueds[recipient];
            rewardAccrueds[recipient] = 0;
            DFI.safeTransfer(recipient, rewardToTransfer);
            emit REWARD_CLAIMED(recipient, rewardToTransfer, true);
        } else {
            rewardAccrueds[recipient] -= proxyBalance;
            DFI.safeTransfer(recipient, proxyBalance);
            emit REWARD_CLAIMED(recipient, proxyBalance, false);
        }
    }

    /**
     * @notice internal function to add liquidity
     * @param requester requester of the addition of liquidity
     * @param liquidity the LP tokens added to the smart contract
     */
    function _addLiquidity(address requester, uint256 liquidity) internal {
        stakingMap[requester] += liquidity;
        totalStake += liquidity;
    }

    /**
     * @notice internal function to remove liquidity
     * @param requester requester of the removal of liquidity
     * @param liquidity the LP tokens to be removed from the smart contract
     */
    function _removeLiquidity(address requester, uint256 liquidity) internal {
        stakingMap[requester] -= liquidity;
        totalStake -= liquidity;
    }

    /**
     * @notice Enter Emergency mode, in case our rewardMechanism fails
     */
    function enterEmergencyMode() external onlyRole(DEFAULT_ADMIN_ROLE) {
        emergency = true;
        DFI.safeTransfer(msg.sender, DFI.balanceOf(address(this)));
    }

    /**
     * @notice For the contract to enter the next stage 
     * 1. enter stage COLD_START when we want to start accruing liquidity mining rewards to users (1%)
     * 2. enter stage AFTER_COLD_START when we want to start normal liquidity mining campaign
     * 3. enter stage END_REWARD_PERIOD when we want to end the accrual of Liquidity Mining rewards to users,
     */
    function enterNextStage() external notInEmergency onlyRole(DEFAULT_ADMIN_ROLE) {
        _updateRewardIndex();
        if (contract_stage == STAGE.NO_REWARD_PERIOD) { 
            rewardSpeed = admin_speed/100;
            contract_stage = STAGE.COLD_START;
        }
        else if (contract_stage == STAGE.COLD_START) {
            rewardSpeed = admin_speed;
            endColdStartBlockNum = block.number;
            contract_stage = STAGE.AFTER_COLD_START;            
        }
        else if (contract_stage == STAGE.AFTER_COLD_START) {
            rewardSpeed = 0;
            contract_stage = STAGE.END_REWARD_PERIOD;
        }
    }

    /**
     * @notice modifier in case of emergency
     */
    modifier notInEmergency() {
        require(!emergency, "In emergency mode now");
        _;
    }

    /**
    * @notice a function to check reward related matters of the contract
    * @param recipient the address we want to check the reward on
    * @return _rewardForRecipient an estimate of reward claimable by a recipient up till now
    * @return _totalRewardAccrued an estimate of totalReward that the contract accrue to all of its users (including the tokens that have been claimed by users)
    */ 
    function checkReward(address recipient) external view returns(uint256 _rewardForRecipient, uint256 _totalRewardAccrued) {
        uint256 blockNumber = block.number;
        uint256 rewardAccrued;
        uint256 _rewardSpeed = rewardSpeed;
        uint256 _marketIndex = marketState.index;
        _totalRewardAccrued = totalRewardAccrued;

        if (contract_stage == STAGE.COLD_START) {
            rewardAccrued =
                _rewardSpeed *
                (blockNumber - marketState.lastBlockNum);
        } else if (contract_stage == STAGE.AFTER_COLD_START) {
            uint256 updateEpoch = (blockNumber - endColdStartBlockNum) /
                BLOCKS_PER_WEEK;
            if (updateEpoch > marketState.epoch) {
                uint256 checkPoint = (marketState.epoch + 1) *
                    BLOCKS_PER_WEEK +
                    endColdStartBlockNum;
                uint256 rewardAccruedBeforeFirstEpochEnds = _rewardSpeed *
                    (checkPoint - marketState.lastBlockNum);
                checkPoint += BLOCKS_PER_WEEK;
                while (checkPoint <= blockNumber) {
                    _rewardSpeed = (_rewardSpeed * 96) / 100;
                    rewardAccrued += _rewardSpeed * BLOCKS_PER_WEEK;
                    checkPoint += BLOCKS_PER_WEEK;
                }
                _rewardSpeed = (_rewardSpeed * 96) / 100;
                uint256 rewardAccruedInTheFinalEpoch = _rewardSpeed *
                    (blockNumber + BLOCKS_PER_WEEK - checkPoint);
                rewardAccrued +=
                    rewardAccruedBeforeFirstEpochEnds +
                    rewardAccruedInTheFinalEpoch;
            } else
                rewardAccrued =
                    _rewardSpeed *
                    (blockNumber - marketState.lastBlockNum);
        }
        if (totalStake != 0) {
            _marketIndex += (rewardAccrued * 1e18) / totalStake;
            _totalRewardAccrued += rewardAccrued;
        }

        uint256 deltaIndex = _marketIndex - recipientIndexes[recipient];

        uint256 recipientDelta = (stakingMap[recipient] * deltaIndex) / 1e18;
        _rewardForRecipient = rewardAccrueds[recipient] + recipientDelta;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
                /// @solidity memory-safe-assembly
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