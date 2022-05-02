// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "./interface/ILP.sol";
import "./interface/ICore.sol";
import "./interface/IAzuroBet.sol";
import "./utils/LiquidityTree.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";

/// @title Azuro liquidity pool
contract LP is
    LiquidityTree,
    OwnableUpgradeable,
    ERC721EnumerableUpgradeable,
    ILP
{
    uint128 public lockedLiquidity; // liquidity reserved by conditions (initial reinforcement)
    uint128 public totalDaoRewards;

    uint128 public oracleFee;
    uint128 public daoFee;

    uint128 public reinforcementAbility; // should be 50%
    uint64 public multiplier;
    address public token;
    ICore public core;
    IAzuroBet public azuroBet;

    uint128 public minDepo; // minimum deposit amount
    uint64 public withdrawTimeout; // Deposit - Withdraw Timeout

    mapping(uint48 => uint64) public withdrawals; // withdrawals[depNum] = withdrawal time

    /**
     * @notice Only permits calls if the deadline is not yet due.
     * @param  deadline time after which the call is not allowed
     */
    modifier ensure(uint256 deadline) {
        if (block.timestamp >= deadline) revert ConditionStarted();
        _;
    }

    /**
     * @notice Only permits calls by Core.
     */
    modifier onlyCore() {
        if (msg.sender != address(core)) revert OnlyCore();
        _;
    }

    /**
     * @notice Owner: Set `newCore` as Core address.
     * @param  newCore new Core contract address
     */
    function changeCore(address newCore) external override onlyOwner {
        if (address(core) != address(0) && core.getLockedPayout() != 0)
            revert PaymentLocked();

        core = ICore(newCore);
    }

    /**
     * @notice Owner: Set `newOracleFee` as oracles fee.
     */
    function changeOracleReward(uint128 newOracleFee) external onlyOwner {
        oracleFee = newOracleFee;
        emit OracleRewardChanged(newOracleFee);
    }

    /**
     * @notice Owner: Set `newDaoFee` as DAO fee.
     */
    function changeDaoReward(uint128 newDaoFee) external onlyOwner {
        daoFee = newDaoFee;
        emit DaoRewardChanged(newDaoFee);
    }

    /**
     * @notice Owner: Set `newAzuroBet` as AzuroBet address.
     * @param  newAzuroBet new AzuroBet contract address
     */
    function changeAzuroBet(address newAzuroBet) external onlyOwner {
        azuroBet = IAzuroBet(newAzuroBet);
        emit AzuroBetChanged(newAzuroBet);
    }

    /**
     * @notice Owner: Set `minDepo` as newMinDepo value.
     * @param  newMinDepo new minDepo value
     */
    function changeMinDepo(uint128 newMinDepo) external onlyOwner {
        minDepo = newMinDepo;
        emit MinDepoChanged(newMinDepo);
    }

    /**
     * @notice Owner: Set `withdrawTimeout` as newWithdrawTimeout value.
     * @param  newWithdrawTimeout new withdrawTimeout value
     */
    function changeWithdrawTimeout(uint64 newWithdrawTimeout)
        external
        onlyOwner
    {
        withdrawTimeout = newWithdrawTimeout;
        emit WithdrawTimeoutChanged(newWithdrawTimeout);
    }

    function initialize(address token_, address azuroBetAddress)
        external
        virtual
        initializer
    {
        if (token_ == address(0)) revert WrongToken();
        __Ownable_init_unchained();
        __ERC721_init("Azuro LP NFT token", "LP-AZR");
        __liquidityTree_init();
        token = token_;
        azuroBet = IAzuroBet(azuroBetAddress);
        multiplier = 1e9;
        oracleFee = 1e7; // 1%
        daoFee = 9 * 1e7; // 9%
        reinforcementAbility = multiplier / 2; // 50%
    }

    /**
     * @notice Add some liquidity in pool in exchange for LPNFT tokens
     * @param  amount token's amount to swap
     */
    function addLiquidity(uint128 amount) external override {
        if (amount < minDepo) revert AmountNotSufficient();

        uint48 leaf = nodeAddLiquidity(amount);

        // make NFT
        _mint(msg.sender, leaf);
        TransferHelper.safeTransferFrom(
            token,
            msg.sender,
            address(this),
            amount
        );
        withdrawals[leaf] = uint64(block.timestamp);
        emit LiquidityAdded(msg.sender, amount, leaf);
    }

    /**
     * @notice Withdraw liquidity for some NFT deposite #.
     * @param depNum - NFT with deposite number
     * @param percent - percent of leaf amount 1*10^12 is 100%, 5*10^11 is 50%
     */
    function withdrawLiquidity(uint48 depNum, uint40 percent)
        external
        override
    {
        uint64 _time = uint64(block.timestamp);
        uint64 _withdrawTime = withdrawals[depNum] + withdrawTimeout;
        if (_time < _withdrawTime)
            revert WithdrawalTimeout(_withdrawTime - _time);
        if (msg.sender != ownerOf(depNum)) revert LiquidityNotOwned();

        withdrawals[depNum] = _time;
        uint128 topNodeAmount = treeNode[1].amount;
        uint128 withdrawValue = nodeWithdrawPercent(depNum, percent);

        if (withdrawValue == 0) revert NoLiquidity();

        // check withdrawValue allowed in ("node #1" - "active condition reinforcements")
        if (withdrawValue > (topNodeAmount - lockedLiquidity))
            revert LiquidityIsLocked();
        TransferHelper.safeTransfer(token, msg.sender, withdrawValue);

        emit LiquidityRemoved(msg.sender, withdrawValue);
    }

    /**
     * @notice Call Core to get AzuroBet token `tokenId` payout.
     * @param  tokenId AzuroBet token ID
     * @return if the payout is successfully resolved
     * @return the amount of winnings of the owner of the token
     */
    function viewPayout(uint256 tokenId)
        external
        view
        override
        returns (bool, uint128)
    {
        return (ICore(azuroBet.getCoreByToken(tokenId)).viewPayout(tokenId));
    }

    /**
     * @notice Withdraw payout based on bet with AzuroBet token `tokenId` in finished or cancelled condition.
     * @param  tokenId AzuroBet token ID withdraw payout to
     */
    function withdrawPayout(uint256 tokenId) external override {
        if (azuroBet.ownerOf(tokenId) != msg.sender) revert OnlyBetOwner();

        (bool success, uint128 amount) = ICore(azuroBet.getCoreByToken(tokenId))
            .resolvePayout(tokenId);

        if (!success) revert NoWinNoPrize();

        TransferHelper.safeTransfer(token, msg.sender, amount);
        emit BetterWin(msg.sender, tokenId, amount);
    }

    /**
     * @notice Reward contract owner (DAO) with total amount of charged fees.
     */
    function claimDaoReward() external override {
        if (totalDaoRewards == 0) revert NoDaoReward();

        uint128 rewards = totalDaoRewards;
        totalDaoRewards = 0;
        TransferHelper.safeTransfer(token, owner(), rewards);
    }

    /**
     * @notice Send oracle `oracle` `amount` of tokens.
     * @param  oracle address of oracle send to.
     * @param  amount amount of tokens send to.
     */
    function sendOracleReward(address oracle, uint128 amount)
        external
        override
        onlyCore
    {
        TransferHelper.safeTransfer(token, oracle, amount);
    }

    /**
     * @notice Make new bet in exchange of AzuroBet token.
     * @param  conditionId the match or game ID
     * @param  amount amount of tokens to bet
     * @param  outcomeId ID of predicted outcome
     * @param  deadline the time before which bet should be made
     * @param  minOdds minimum allowed bet odds
     * @return ID of bet's AzuroBet token.
     */
    function bet(
        uint256 conditionId,
        uint128 amount,
        uint64 outcomeId,
        uint64 deadline,
        uint64 minOdds
    ) external override ensure(deadline) returns (uint256) {
        if (amount == 0) revert AmountMustNotBeZero();

        azuroBet.mint(msg.sender, address(core));
        uint256 tokenId = azuroBet.totalSupply();

        TransferHelper.safeTransferFrom(
            token,
            msg.sender,
            address(this),
            amount
        );
        (uint256 odds, uint128 fund1, uint128 fund2) = core.putBet(
            conditionId,
            tokenId,
            amount,
            outcomeId,
            minOdds
        );
        emit NewBet(
            msg.sender,
            tokenId,
            conditionId,
            outcomeId,
            amount,
            odds,
            fund1,
            fund2
        );
        return tokenId;
    }

    /**
     * @notice Core: Change amount of reserved by conditions funds.
     * @param  initReserve reinforcement of the condition.
     * @param  profitReserve amount of reserves that was not demand according to the condition results
     */
    function addReserve(
        uint128 initReserve,
        uint128 profitReserve,
        uint48 leaf
    ) external override onlyCore {
        if (profitReserve >= initReserve) {
            // pool win
            uint128 profit = profitReserve - initReserve;

            // calc oracle rewards
            uint128 oracleRewards = (profit * oracleFee) / multiplier;

            // calc DAO rewards
            uint128 daoRewards = (profit * daoFee) / multiplier;
            totalDaoRewards += daoRewards;

            // add profit to segmentTree
            addLimit(profit - (oracleRewards + daoRewards), leaf);
        } else {
            // remove loss from segmentTree excluding canceled conditions (when profitReserve = 0)
            if (profitReserve > 0) {
                removeLimit(initReserve - profitReserve, leaf);
            }
        }
        // send back locked reinforcement
        lockedLiquidity = lockedLiquidity - initReserve;
    }

    /**
     * @notice Core: Indicate `amount` of reserve as locked.
     * @param  amount reserves to lock
     */
    function lockReserve(uint128 amount) external override onlyCore {
        lockedLiquidity += amount;
        if (lockedLiquidity > treeNode[1].amount) revert NotEnoughReserves();
    }

    /**
     * @notice Get total reserved funds.
     */
    function getReserve() external view override returns (uint128 reserve) {
        return treeNode[1].amount;
    }

    /**
     * @notice Check if it is possible to use `reinforcementAmount` of tokens as condition reinforcement.
     * @param  reinforcementAmount amount of tokens intended to be used as condition reinforcement.
     * @return status if now it is possible
     */
    function getPossibilityOfReinforcement(uint128 reinforcementAmount)
        external
        view
        override
        returns (bool status)
    {
        return (lockedLiquidity + reinforcementAmount <=
            (reinforcementAbility * treeNode[1].amount) / multiplier);
    }

    /**
     * @notice Get current oracle fee where `multiplier` equals 100% of bettor winnings.
     */
    function getOracleFee() external view override returns (uint128 fee) {
        return oracleFee;
    }

    /**
     * @notice Get fee multiplier.
     */
    function getFeeMultiplier()
        external
        view
        override
        returns (uint128 feeMultiplier)
    {
        return multiplier;
    }

    /**
     * @dev get segment tree last added leaf
     */
    function getLeaf() external view override returns (uint48 leaf) {
        return (nextNode - 1);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

interface ILP {
    event NewBet(
        address indexed owner,
        uint256 indexed betId,
        uint256 indexed conditionId,
        uint64 outcomeId,
        uint128 amount,
        uint256 odds,
        uint128 fund1,
        uint128 fund2
    );

    event BetterWin(address indexed better, uint256 tokenId, uint256 amount);
    event LiquidityAdded(address indexed account, uint256 amount, uint48 leaf);
    event LiquidityRemoved(address indexed account, uint256 amount);
    event LiquidityRequested(
        address indexed requestWallet,
        uint256 requestedValueLp
    );

    event OracleRewardChanged(uint128 newOracleFee);
    event DaoRewardChanged(uint128 newDaoFee);
    event AzuroBetChanged(address newAzuroBet);
    event PeriodChanged(uint64 newPeriod);
    event MinDepoChanged(uint128 newMinDepo);
    event WithdrawTimeoutChanged(uint64 newWithdrawTimeout);

    error OnlyBetOwner();
    error OnlyCore();

    error AmountMustNotBeZero();
    error AmountNotSufficient();
    error NoDaoReward();
    error NoWinNoPrize();
    error LiquidityNotOwned();
    error LiquidityIsLocked();
    error NoLiquidity();
    error PaymentLocked();
    error WrongToken();
    error ConditionStarted();
    error NotEnoughReserves();
    error WithdrawalTimeout(uint64 waitTime);

    function changeCore(address newCore) external;

    function addLiquidity(uint128 amount) external;

    function withdrawLiquidity(uint48 depNum, uint40 percent) external;

    function viewPayout(uint256 tokenId) external view returns (bool, uint128);

    function bet(
        uint256 conditionId,
        uint128 amount,
        uint64 outcomeId,
        uint64 deadline,
        uint64 minOdds
    ) external returns (uint256);

    function getReserve() external view returns (uint128);

    function lockReserve(uint128 amount) external;

    function addReserve(
        uint128 initReserve,
        uint128 profitReserve,
        uint48 leaf
    ) external;

    function withdrawPayout(uint256 tokenId) external;

    function sendOracleReward(address oracle, uint128 amount) external;

    function claimDaoReward() external;

    function getPossibilityOfReinforcement(uint128 reinforcementAmount)
        external
        view
        returns (bool);

    function getOracleFee() external view returns (uint128 fee);

    function getFeeMultiplier() external view returns (uint128 feeDecimals);

    function getLeaf() external view returns (uint48 leaf);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

interface ICore {
    enum ConditionState {
        CREATED,
        RESOLVED,
        CANCELED
    }

    struct Bet {
        uint256 conditionId;
        uint128 amount;
        uint64 outcome;
        uint64 createdAt;
        uint64 odds;
        bool payed;
    }

    struct Condition {
        uint128[2] fundBank;
        uint128[2] payouts;
        uint128[2] totalNetBets;
        uint128 reinforcement;
        uint128 margin;
        bytes32 ipfsHash;
        uint64[2] outcomes; // unique outcomes for the condition
        uint128 scopeId;
        uint64 outcomeWin;
        uint64 timestamp; // after this time user cant put bet on condition
        ConditionState state;
        uint48 leaf;
    }

    event ConditionCreated(
        uint256 indexed oracleConditionId,
        uint256 indexed conditionId,
        uint64 timestamp
    );
    event ConditionResolved(
        uint256 indexed oracleConditionId,
        uint256 indexed conditionId,
        uint64 outcomeWin,
        uint8 state,
        uint256 amountForLp
    );
    event LpChanged(address indexed newLp);
    event MaxBanksRatioChanged(uint64 newRatio);
    event MaintainerUpdated(address indexed maintainer, bool active);
    event OracleAdded(address indexed newOracle);
    event OracleRenounced(address indexed oracle);
    event AllConditionsStopped(bool flag);
    event ConditionStopped(uint256 indexed conditionId, bool flag);
    event ConditionShifted(uint256 conditionId, uint64 newTimestamp);

    error OnlyLp();
    error OnlyMaintainer();
    error OnlyOracle();

    error FlagAlreadySet();
    error IncorrectTimestamp();
    error SameOutcomes();
    error SmallBet();
    error SmallOdds();
    error WrongDataFormat();
    error WrongOutcome();
    error ZeroOdds();

    error ConditionNotExists();
    error ConditionNotStarted();
    error ConditionStarted();
    error ConditionAlreadyCreated();
    error ConditionAlreadyResolved();
    error ConditionStopped_();

    error BigDifference();
    error CantAcceptBet();
    error NotEnoughLiquidity();

    function getLockedPayout() external view returns (uint256);

    function createCondition(
        uint256 oracleConditionId,
        uint128 scopeId,
        uint64[2] memory odds,
        uint64[2] memory outcomes,
        uint64 timestamp,
        bytes32 ipfsHash
    ) external;

    function resolveCondition(uint256 conditionId, uint64 outcomeWin) external;

    function viewPayout(uint256 tokenId) external view returns (bool, uint128);

    function resolvePayout(uint256 tokenId) external returns (bool, uint128);

    function setLp(address lp) external;

    function putBet(
        uint256 conditionId,
        uint256 tokenId,
        uint128 amount,
        uint64 outcome,
        uint64 minOdds
    )
        external
        returns (
            uint64,
            uint128,
            uint128
        );

    function getBetInfo(uint256 betId)
        external
        view
        returns (
            uint128 amount,
            uint64 odds,
            uint64 createdAt
        );

    function isOracle(address oracle) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

interface IAzuroBet is IERC721EnumerableUpgradeable {
    function ownerOf(uint256 tokenId) external view override returns (address);

    function burn(uint256 id) external;

    function mint(address account, address core) external;

    function setLp(address lp) external;

    function getCoreByToken(uint256 tokenId)
        external
        view
        returns (address core);

    event LpChanged(address lp);

    error OnlyLp();
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

contract LiquidityTree {
    struct Node {
        uint64 updateId; // last update number
        uint128 amount; // node amount
    }

    uint40 constant DECIMALS = 10**12;
    uint48 constant LIQUIDITYNODES = 1_099_511_627_776; // begining of data nodes (top at node #1)
    uint48 constant LIQUIDITYLASTNODE = LIQUIDITYNODES * 2 - 1;

    uint48 public nextNode; // next unused node number for adding liquidity

    uint64 public updateId; // update number, used instead of timestamp for splitting changes time on the same nodes

    // liquidity (segment) tree
    mapping(uint48 => Node) public treeNode;

    error LeafNotExist();
    error IncorrectPercent();

    /**
     * @dev initializing LIQUIDITYNODES and nextNode. 
     * @dev LIQUIDITYNODES is count of liquidity (segment) tree leaves contains single liquidity addings
     * @dev liquidity (segment) tree build as array of 2*LIQUIDITYNODES count, top node has id #1 (id #0 not used)
     * @dev liquidity (segment) tree leaves is array [LIQUIDITYNODES, 2*LIQUIDITYNODES-1]
     * @dev liquidity (segment) tree node index N has left child index 2*N and right child index 2N+1
     * @dev +--------------------------------------------+
            |                  1 (top node)              |
            +------------------------+-------------------+
            |             2          |         3         |
            +-------------+----------+---------+---------+
            | 4 (nextNode)|     5    |    6    |    7    |
            +-------------+----------+---------+---------+
     */
    function __liquidityTree_init() internal {
        nextNode = LIQUIDITYNODES;
        updateId++; // start from non zero
    }

    /**
     * @dev add liquidity amount from the leaf up to top node
     * @param amount - adding amount
     */
    function nodeAddLiquidity(uint128 amount)
        internal
        returns (uint48 resNode)
    {
        updateUp(nextNode, amount, false, ++updateId);
        resNode = nextNode;
        nextNode++;
    }

    /**
     * @dev leaf withdraw preview, emulates push value from updated node to leaf
     * @param leaf - withdrawing leaf
     */
    function nodeWithdrawView(uint48 leaf)
        public
        view
        returns (uint128 withdrawAmount)
    {
        if (leaf < LIQUIDITYNODES || leaf > LIQUIDITYLASTNODE) return 0;
        if (treeNode[leaf].updateId == 0) return 0;

        // get last-updated top node
        (uint48 updatedNode, uint48 begin, uint48 end) = getUpdatedNode(
            1,
            treeNode[1].updateId,
            LIQUIDITYNODES,
            LIQUIDITYLASTNODE,
            1,
            LIQUIDITYNODES,
            LIQUIDITYLASTNODE,
            leaf
        );

        return
            pushView(
                updatedNode,
                begin,
                end,
                leaf,
                treeNode[updatedNode].amount
            );
    }

    /**
     * @dev withdraw part of liquidity from the leaf, due possible many changes in leafe's parent nodes
     * @dev it is needed firstly to update its amount and then withdraw
     * @dev used steps:
     * @dev 1 - get last updated parent most near to the leaf
     * @dev 2 - push all changes from found parent doen to the leaf - that updates leaf's amount
     * @dev 3 - execute withdraw of leaf amount and update amount changing up to top parents
     * @param leaf -
     * @param percent - percent of leaf amount 1*10^12 is 100%, 5*10^11 is 50%
     */
    function nodeWithdrawPercent(uint48 leaf, uint40 percent)
        internal
        returns (uint128 withdrawAmount)
    {
        if (treeNode[leaf].updateId == 0) revert LeafNotExist();
        if (percent > DECIMALS) revert IncorrectPercent();

        // get last-updated top node
        (uint48 updatedNode, uint48 begin, uint48 end) = getUpdatedNode(
            1,
            treeNode[1].updateId,
            LIQUIDITYNODES,
            LIQUIDITYLASTNODE,
            1,
            LIQUIDITYNODES,
            LIQUIDITYLASTNODE,
            leaf
        );
        // push changes from last-updated node down to the leaf, if leaf is not up to date
        push(updatedNode, begin, end, leaf, ++updateId);

        // remove amount (percent of amount) from leaf to it's parents
        withdrawAmount = (treeNode[leaf].amount * percent) / DECIMALS;

        updateUp(leaf, withdrawAmount, true, ++updateId);
    }

    /**
     * @dev top node is ever most updated, trying to find lower node not older then top node
     * @dev get nearest to leaf (lowest) last-updated node from the parents, runing down from top to leaf
     * @param parent top node
     * @param parentUpdate top node update
     * @param parentBegin top node most left leaf
     * @param parentEnd top node most right leaf
     * @param node node parent for the leaf
     * @param begin node most left leaf
     * @param end node most right leaf
     * @param leaf target leaf
     * @return resParent found most updated leaf parent
     * @return resBegin found parent most left leaf
     * @return resEnd found parent most right leaf
     */
    function getUpdatedNode(
        uint48 parent,
        uint64 parentUpdate,
        uint48 parentBegin,
        uint48 parentEnd,
        uint48 node,
        uint48 begin,
        uint48 end,
        uint48 leaf
    )
        internal
        view
        returns (
            uint48 resParent,
            uint48 resBegin,
            uint48 resEnd
        )
    {
        // if node is older than it's parent, stop and return parent
        if (treeNode[node].updateId < parentUpdate) {
            return (parent, parentBegin, parentEnd);
        }
        if (node == leaf) {
            return (leaf, begin, end);
        }

        uint48 mid = (begin + end) / 2;

        if (begin <= leaf && leaf <= mid) {
            // work on left child
            (resParent, resBegin, resEnd) = getUpdatedNode(
                node,
                parentUpdate,
                begin,
                end,
                node * 2,
                begin,
                mid,
                leaf
            );
        } else {
            // work on right child
            (resParent, resBegin, resEnd) = getUpdatedNode(
                node,
                parentUpdate,
                begin,
                end,
                node * 2 + 1,
                mid + 1,
                end,
                leaf
            );
        }
    }

    /**
     * @dev update up amounts from leaf up to top node #1, used in adding/removing values on leaves
     * @param child node for update
     * @param amount value for update
     * @param isSub true - reduce, false - add
     * @param updateId_ update number
     */
    function updateUp(
        uint48 child,
        uint128 amount,
        bool isSub,
        uint64 updateId_
    ) internal {
        changeAmount(child, amount, isSub, updateId_);
        // if not top parent
        if (child != 1) {
            updateUp(getParent(child), amount, isSub, updateId_);
        }
    }

    /**
     * @dev add amount only for limited leaves in tree [first_leaf, leaf]
     * @param amount value to add
     */
    function addLimit(uint128 amount, uint48 leaf) internal {
        // get last-updated top node
        (uint48 updatedNode, uint48 begin, uint48 end) = getUpdatedNode(
            1,
            treeNode[1].updateId,
            LIQUIDITYNODES,
            LIQUIDITYLASTNODE,
            1,
            LIQUIDITYNODES,
            LIQUIDITYLASTNODE,
            leaf
        );

        // push changes from last-updated node down to the leaf, if leaf is not up to date
        push(updatedNode, begin, end, leaf, ++updateId);

        pushLazy(
            1,
            LIQUIDITYNODES,
            LIQUIDITYLASTNODE,
            LIQUIDITYNODES,
            leaf,
            amount,
            false,
            ++updateId
        );
    }

    /**
     * @dev remove amount only for limited leaves in tree [first_leaf, leaf]
     * @param amount value to remove
     */
    function removeLimit(uint128 amount, uint48 leaf) internal {
        if (treeNode[1].amount >= amount) {
            // get last-updated top node
            (uint48 updatedNode, uint48 begin, uint48 end) = getUpdatedNode(
                1,
                treeNode[1].updateId,
                LIQUIDITYNODES,
                LIQUIDITYLASTNODE,
                1,
                LIQUIDITYNODES,
                LIQUIDITYLASTNODE,
                leaf
            );

            // push changes from last-updated node down to the leaf, if leaf is not up to date
            push(updatedNode, begin, end, leaf, ++updateId);

            pushLazy(
                1,
                LIQUIDITYNODES,
                LIQUIDITYLASTNODE,
                LIQUIDITYNODES,
                leaf,
                amount,
                true,
                ++updateId
            );
        }
    }

    /**
     * @dev push changes from last "lazy update" down to leaf
     * @param node - last node from lazy update
     * @param begin - leaf search start
     * @param end - leaf search end
     * @param leaf - last node to update
     * @param updateId_ update number
     */
    function push(
        uint48 node,
        uint48 begin,
        uint48 end,
        uint48 leaf,
        uint64 updateId_
    ) internal {
        // if node is leaf, stop
        if (node == leaf) {
            return;
        }
        uint48 lChild = node * 2;
        uint48 rChild = node * 2 + 1;
        uint128 amount = treeNode[node].amount;
        uint256 lAmount = treeNode[lChild].amount;
        uint256 rAmount = treeNode[rChild].amount;
        uint256 sumAmounts = lAmount + rAmount;
        if (sumAmounts == 0) return;
        uint128 setLAmount = uint128((amount * lAmount) / sumAmounts);

        // update left and right child
        setAmount(lChild, setLAmount, updateId_);
        setAmount(rChild, amount - setLAmount, updateId_);

        uint48 mid = (begin + end) / 2;

        if (begin <= leaf && leaf <= mid) {
            push(lChild, begin, mid, leaf, updateId_);
        } else {
            push(rChild, mid + 1, end, leaf, updateId_);
        }
    }

    /**
     * @dev push changes from last "lazy update" down to leaf
     * @param node - last node from lazy update
     * @param begin - leaf search start
     * @param end - leaf search end
     * @param leaf - last node to update
     * @param amount - pushed (calced) amount for the node
     */
    function pushView(
        uint48 node,
        uint48 begin,
        uint48 end,
        uint48 leaf,
        uint128 amount
    ) internal view returns (uint128 withdrawAmount) {
        // if node is leaf, stop
        if (node == leaf) {
            return amount;
        }

        uint48 lChild = node * 2;
        uint48 rChild = node * 2 + 1;
        uint256 lAmount = treeNode[lChild].amount;
        uint256 sumAmounts = lAmount + treeNode[rChild].amount;
        if (sumAmounts == 0) return 0;
        uint128 setLAmount = uint128((amount * lAmount) / sumAmounts);

        uint48 mid = (begin + end) / 2;

        if (begin <= leaf && leaf <= mid) {
            return pushView(lChild, begin, mid, leaf, setLAmount);
        } else {
            return pushView(rChild, mid + 1, end, leaf, amount - setLAmount);
        }
    }

    /**
     * @dev push lazy (lazy propagation) amount value from top node to child nodes contained leafs from 0 to r
     * @param node - start from node
     * @param begin - node left element
     * @param end - node right element
     * @param l - left leaf child
     * @param r - right leaf child
     * @param amount - amount to add/reduce stored amounts
     * @param isSub - true means negative to reduce
     * @param updateId_ update number
     */
    function pushLazy(
        uint48 node,
        uint48 begin,
        uint48 end,
        uint48 l,
        uint48 r,
        uint128 amount,
        bool isSub,
        uint64 updateId_
    ) internal {
        if ((begin == l && end == r) || (begin == end)) {
            // if node leafs equal to leaf interval then stop
            changeAmount(node, amount, isSub, updateId_);
            return;
        }

        uint48 mid = (begin + end) / 2;

        if (begin <= l && l <= mid) {
            if (begin <= r && r <= mid) {
                // [l,r] in [begin,mid] - all leafs in left child
                pushLazy(node * 2, begin, mid, l, r, amount, isSub, updateId_);
            } else {
                uint128 lAmount = treeNode[node * 2].amount;
                // get right amount excluding unused leaves when adding amounts
                uint128 rAmount = treeNode[node * 2 + 1].amount -
                    (
                        !isSub
                            ? getLeavesAmount(
                                node * 2 + 1,
                                mid + 1,
                                end,
                                r + 1,
                                end
                            )
                            : 0
                    );
                uint128 sumAmounts = lAmount + rAmount;
                if (sumAmounts == 0) return;
                uint128 forLeftAmount = (amount *
                    ((lAmount * DECIMALS) / sumAmounts)) / DECIMALS;

                // l in [begin,mid] - part in left child
                pushLazy(
                    node * 2,
                    begin,
                    mid,
                    l,
                    mid,
                    forLeftAmount,
                    isSub,
                    updateId_
                );

                // r in [mid+1,end] - part in right child
                pushLazy(
                    node * 2 + 1,
                    mid + 1,
                    end,
                    mid + 1,
                    r,
                    amount - forLeftAmount,
                    isSub,
                    updateId_
                );
            }
        } else {
            // [l,r] in [mid+1,end] - all leafs in right child
            pushLazy(
                node * 2 + 1,
                mid + 1,
                end,
                l,
                r,
                amount,
                isSub,
                updateId_
            );
        }
        changeAmount(node, amount, isSub, updateId_);
    }

    /**
     * @dev change amount by adding value or reducing value
     * @param node - node for changing
     * @param amount - amount value for changing
     * @param isSub - true - reduce by amount, true - add by amount
     * @param updateId_ - update number
     */
    function changeAmount(
        uint48 node,
        uint128 amount,
        bool isSub,
        uint64 updateId_
    ) internal {
        treeNode[node].updateId = updateId_;
        if (isSub) {
            treeNode[node].amount -= amount;
        } else {
            treeNode[node].amount += amount;
        }
    }

    /**
     * @dev reset node amount, used in push
     * @param node for set
     * @param amount value
     * @param updateId_ update number
     */
    function setAmount(
        uint48 node,
        uint128 amount,
        uint64 updateId_
    ) internal {
        if (treeNode[node].amount != amount) {
            treeNode[node].updateId = updateId_;
            treeNode[node].amount = amount;
        }
    }

    /**
     * @dev parent N has left child 2N and right child 2N+1getLeavesAmount
     * @param fromNumber - get parent from some child
     * @return parentNumber - found parent
     */
    function getParent(uint48 fromNumber)
        public
        pure
        returns (uint48 parentNumber)
    {
        // if requested from top
        if (fromNumber == 1) {
            return 1;
        }
        return fromNumber / 2;
    }

    /**
     * @dev for current node get sum amount of exact leaves list
     * @param node node to get sum amount
     * @param begin - node left element
     * @param end - node right element
     * @param l - left leaf of the list
     * @param r - right leaf of the list
     * @return amount sum of leaves list
     */
    function getLeavesAmount(
        uint48 node,
        uint48 begin,
        uint48 end,
        uint48 l,
        uint48 r
    ) public view returns (uint128 amount) {
        if ((begin == l && end == r) || (begin == end)) {
            // if node leafs equal to leaf interval then stop and return amount value
            return (treeNode[node].amount);
        }

        uint48 mid = (begin + end) / 2;

        if (begin <= l && l <= mid) {
            if (begin <= r && r <= mid) {
                amount += getLeavesAmount(node * 2, begin, mid, l, r);
            } else {
                amount += getLeavesAmount(node * 2, begin, mid, l, mid);
                amount += getLeavesAmount(
                    node * 2 + 1,
                    mid + 1,
                    end,
                    mid + 1,
                    r
                );
            }
        } else {
            amount += getLeavesAmount(node * 2 + 1, mid + 1, end, l, r);
        }

        return amount;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721EnumerableUpgradeable is Initializable, ERC721Upgradeable, IERC721EnumerableUpgradeable {
    function __ERC721Enumerable_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721Enumerable_init_unchained();
    }

    function __ERC721Enumerable_init_unchained() internal initializer {
    }
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC721Upgradeable) returns (bool) {
        return interfaceId == type(IERC721EnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Upgradeable.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721EnumerableUpgradeable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721Upgradeable.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721Upgradeable.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
    uint256[46] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
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
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}