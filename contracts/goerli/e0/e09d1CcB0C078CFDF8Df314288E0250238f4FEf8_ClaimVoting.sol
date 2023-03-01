// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "./libraries/DecimalsConverter.sol";
import "./libraries/SafeMath.sol";

import "./interfaces/IContractsRegistry.sol";
import "./interfaces/IClaimVoting.sol";
import "./interfaces/IReputationSystem.sol";
import "./interfaces/IDEINStaking.sol";
import "./interfaces/IDEINNFTStaking.sol";
import "./interfaces/IStaking.sol";
import "./interfaces/IClaimingRegistry.sol";

import "./abstract/AbstractDependant.sol";

import "./Globals.sol";

contract ClaimVoting is IClaimVoting, Initializable, AbstractDependant {
    using SafeMath for uint256;
    using Math for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

    uint256 public constant MAX_CLAIMS_ANONYMOUS = 10;
    uint256 public constant MAX_CLAIMS_EXPOSE = 20;
    uint256 public constant MAX_CLAIMS_RECEIVE = 30;

    address public priceFeed;
    address public deinStaking;

    IERC20Metadata public deinToken;
    IDEINNFTStaking public deinNFTStaking;
    IClaimingRegistry public claimingRegistry;
    IReputationSystem public reputationSystem;

    // claim management
    mapping(uint256 => Voting) internal _votings; // claimIndex -> VotingInstance

    // vote management
    uint256 internal _voteIndex;
    mapping(uint256 => VoteInfo) internal _voteInfo; // voteIndex -> VoteInfo

    mapping(address => EnumerableSet.UintSet) internal _myVotes; // voter -> claimIndexes
    mapping(address => EnumerableSet.UintSet) internal _myAwaitingVotes; // voter -> claimIndexes

    mapping(uint256 => mapping(address => uint256)) internal _votesToIndex; // claimIndex -> voter -> voteIndex

    event VotedAnonymously(uint256 indexed voteIndex, address indexed voter);
    event VoteExposed(
        uint256 indexed voteIndex,
        address indexed voter,
        uint256 suggestedClaimAmount
    );
    event VoteReceived(uint256 indexed voteIndex, address indexed voter);

    modifier onlyClaimingRegistry() {
        require(msg.sender == address(claimingRegistry), "CV: Not ClaimingRegistry");
        _;
    }

    function __ClaimVoting_init() external initializer {
        _voteIndex = 1;
    }

    function setDependencies(IContractsRegistry _contractsRegistry)
        external
        override
        onlyInjectorOrZero
    {
        claimingRegistry = IClaimingRegistry(_contractsRegistry.getClaimingRegistryContract());
        reputationSystem = IReputationSystem(_contractsRegistry.getReputationSystemContract());
        deinToken = IERC20Metadata(_contractsRegistry.getDEINContract());
        deinStaking = _contractsRegistry.getDEINStakingContract();
        deinNFTStaking = IDEINNFTStaking(_contractsRegistry.getDEINNFTStakingContract());
    }

    // ********** GETTERS STORAGE ********** //
    function getVoteIndex(uint256 claimIndex, address voter) external view returns (uint256) {
        return _votesToIndex[claimIndex][voter];
    }

    function getVotesCount(uint256 claimIndex)
        external
        view
        override
        returns (uint256 votesCount)
    {
        votesCount = _votings[claimIndex].voteCount;
    }

    function getVoteStatus(uint256 voteIndex) external view returns (VoteStatus) {
        return _voteInfo[voteIndex].voteStatus;
    }

    function _getVotePublicStatus(uint256 voteIndex)
        internal
        view
        returns (VotePublicStatus votePublicStatus)
    {
        if (_voteInfo[voteIndex].voteStatus == VoteStatus.ANONYMOUS) {
            return VotePublicStatus.ANONYMOUS;
        } else if (_voteInfo[voteIndex].voteStatus == VoteStatus.EXPOSED) {
            if (claimingRegistry.isClaimResolved(_voteInfo[voteIndex].claimIndex)) {
                return VotePublicStatus.TO_RECEIVE;
            } else {
                return VotePublicStatus.EXPOSED;
            }
        } else if (_voteInfo[voteIndex].voteStatus == VoteStatus.CLOSED) {
            return VotePublicStatus.CLOSED;
        }
    }

    /// @dev return yes and no percentage with 10**25 precision
    function getRepartition(uint256 claimIndex)
        external
        view
        override
        returns (uint256 yesPercentage, uint256 noPercentage)
    {
        yesPercentage = _votings[claimIndex].votedYesPercentage;
        noPercentage = (PERCENTAGE_100.trySub(yesPercentage));
    }

    function getVotingPower(uint256 voteIndex) public view returns (uint256) {
        uint256 sum = IDEINStaking(deinStaking).getVotingPower(_convertEnumToArray(voteIndex));
        return Math.sqrt(sum.mul(_voteInfo[voteIndex].votingReputation));
    }

    function getAmountVoted(uint256 voteIndex) public view returns (uint256) {
        return IStaking(deinStaking).getFullStakedAmounts(_convertEnumToArray(voteIndex));
    }

    function _convertEnumToArray(uint256 voteIndex) internal view returns (uint256[] memory) {
        uint256 length = _voteInfo[voteIndex].tokenIDs.length();
        uint256[] memory list = new uint256[](length);

        for (uint256 i = 0; i < _voteInfo[voteIndex].tokenIDs.length(); i = uncheckedInc(i)) {
            uint256 tokenID = _voteInfo[voteIndex].tokenIDs.at(i);
            list[i] = tokenID;
        }
        return list;
    }

    // ********** GETTERS PROCESS ********** //
    function hasAwaitingReceptionVotes(address user) public view returns (bool hasAwaitingVotes) {
        for (uint256 i = 0; i < _myAwaitingVotes[user].length(); i = uncheckedInc(i)) {
            uint256 claimIndex = _myAwaitingVotes[user].at(i);
            if (
                canReceive(claimIndex, user) &&
                claimingRegistry.getClaimStatus(claimIndex) !=
                IClaimingRegistry.ClaimStatus.EXPIRED
            ) {
                hasAwaitingVotes = true;
            }
        }
    }

    function canUnlock(uint256 tokenID, address user) external view override returns (bool) {
        for (uint256 i = 0; i < _myAwaitingVotes[user].length(); i = uncheckedInc(i)) {
            uint256 claimIndex = _myAwaitingVotes[user].at(i);
            uint256 voteIndex = _votesToIndex[claimIndex][user];
            if (_voteInfo[voteIndex].tokenIDs.contains(tokenID)) {
                return false;
            }
        }
        return true;
    }

    function canVote(uint256 claimIndex, address voter) public view override returns (bool) {
        return
            claimingRegistry.getClaimProvenance(claimIndex).claimer != voter &&
            claimingRegistry.isClaimAnonymouslyVotable(claimIndex) &&
            _votesToIndex[claimIndex][voter] == 0 &&
            (!claimingRegistry.isClaimAppeal(claimIndex) ||
                reputationSystem.isTrustedVoter(msg.sender));
    }

    function canExpose(uint256 claimIndex, address voter) public view override returns (bool) {
        uint256 voteIndex = _votesToIndex[claimIndex][voter];
        return
            _votesToIndex[claimIndex][voter] != 0 &&
            _voteInfo[voteIndex].voteStatus == VoteStatus.ANONYMOUS &&
            claimingRegistry.isClaimExposablyVotable(claimIndex);
    }

    function canReceive(uint256 claimIndex, address voter) public view override returns (bool) {
        return
            _votesToIndex[claimIndex][voter] != 0 &&
            _myAwaitingVotes[voter].contains(claimIndex) &&
            claimingRegistry.isClaimResolved(claimIndex);
    }

    // ********** GETTERS COUNT ********** //
    function myVotesCount(address voter) public view returns (uint256) {
        return _myVotes[voter].length();
    }

    function myAwaitingVotesCount(address voter) public view returns (uint256) {
        return _myAwaitingVotes[voter].length();
    }

    // ********** GETTERS LIST ********** //
    /// @dev use with myVotesCount() if listOption == VOTED
    /// @dev use with myAwaitingVotesCount() if listOption == AWAITING
    function getListClaims(
        uint256 offset,
        uint256 limit,
        ListOption listOption
    ) external view returns (VotePublicInfo[] memory publicVoteInfo) {
        uint256 count;
        if (listOption == ListOption.VOTED) {
            count = myVotesCount(msg.sender);
        } else if (listOption == ListOption.AWAITING) {
            count = myAwaitingVotesCount(msg.sender);
        }

        uint256 to = (offset.add(limit)).min(count).max(offset);

        publicVoteInfo = new VotePublicInfo[](to.uncheckedSub(offset));

        for (uint256 i = offset; i < to; i = uncheckedInc(i)) {
            uint256 voteIndex;
            if (listOption == ListOption.VOTED) {
                voteIndex = _myVotes[msg.sender].at(i);
            } else if (listOption == ListOption.AWAITING) {
                voteIndex = _myAwaitingVotes[msg.sender].at(i);
            }

            uint256 newIndex = i.uncheckedSub(offset);
            VoteInfo storage info = _voteInfo[voteIndex];

            uint256 claimIndex = info.claimIndex;
            (uint256 claimAmount, , ) = claimingRegistry.getClaimAmounts(claimIndex);

            publicVoteInfo[newIndex].voteIndex = voteIndex;
            publicVoteInfo[newIndex].claimIndex = claimIndex;
            publicVoteInfo[newIndex].votingReputation = info.votingReputation;
            publicVoteInfo[newIndex].claimAmount = claimAmount;
            VotePublicStatus votePublicStatus = _getVotePublicStatus(voteIndex);
            publicVoteInfo[newIndex].votePublicStatus = votePublicStatus;

            if (votePublicStatus == VotePublicStatus.ANONYMOUS) {
                publicVoteInfo[newIndex].timeRemaining = claimingRegistry
                    .getClaimDateStart(claimIndex)
                    .add(claimingRegistry.anonymousVotingDuration())
                    .sub(block.timestamp);
            } else if (votePublicStatus == VotePublicStatus.EXPOSED) {
                publicVoteInfo[newIndex].suggestedAmount = info.suggestedAmount;
                publicVoteInfo[newIndex].timeRemaining = claimingRegistry
                    .getClaimDateStart(claimIndex)
                    .add(claimingRegistry.votingDuration())
                    .sub(block.timestamp);
            } else if (votePublicStatus == VotePublicStatus.TO_RECEIVE) {
                publicVoteInfo[newIndex].suggestedAmount = info.suggestedAmount;
                (uint256 deinReward, uint256 deinPenalty, uint256 newReputation) =
                    _getReward(
                        claimIndex,
                        voteIndex,
                        msg.sender,
                        reputationSystem.reputation(msg.sender)
                    );
                publicVoteInfo[newIndex].deinReward = deinReward;
                publicVoteInfo[newIndex].deinPenalty = deinPenalty;
                publicVoteInfo[newIndex].newReputation = newReputation;
            }
        }
    }

    // ********** VOTE PROCESS ********** //

    function anonymouslyVoteBatch(
        uint256[] calldata claimIndexes,
        bytes32[] calldata finalHashes,
        string[] calldata encryptedVotes,
        uint256[] calldata tokenIDs
    ) external override {
        require(!hasAwaitingReceptionVotes(msg.sender), "CV: Awaiting votes");
        require(
            claimIndexes.length == finalHashes.length &&
                claimIndexes.length == encryptedVotes.length,
            "CV: Length mismatches"
        );
        require(claimIndexes.length <= MAX_CLAIMS_ANONYMOUS, "CV: Too many claims");
        require(tokenIDs.length > 0, "CV: No NFT locked");
        require(deinNFTStaking.isLocked(tokenIDs, msg.sender), "CV: Token not locked");

        for (uint256 i = 0; i < claimIndexes.length; i = uncheckedInc(i)) {
            uint256 claimIndex = claimIndexes[i];
            require(canVote(claimIndex, msg.sender), "CV: Cannot vote");

            _voteInfo[_voteIndex].claimIndex = claimIndex;
            _voteInfo[_voteIndex].voter = msg.sender;
            _voteInfo[_voteIndex].encryptedVote = encryptedVotes[i];
            _voteInfo[_voteIndex].finalHash = finalHashes[i];
            _voteInfo[_voteIndex].votingReputation = reputationSystem.reputation(msg.sender);
            for (uint256 j = 0; j < tokenIDs.length; j = uncheckedInc(j)) {
                _voteInfo[_voteIndex].tokenIDs.add(tokenIDs[j]);
            }

            _myVotes[msg.sender].add(claimIndex);
            _myAwaitingVotes[msg.sender].add(claimIndex);
            _votesToIndex[claimIndex][msg.sender] = _voteIndex;

            _votings[claimIndex].voteCount = _votings[claimIndex].voteCount.tryAdd(1);

            _voteIndex = _voteIndex.add(1);

            emit VotedAnonymously(_voteIndex, msg.sender);
        }
    }

    function exposeVoteBatch(
        uint256[] calldata claimIndexes,
        uint256[] calldata suggestedAmounts,
        bytes32[] calldata hashedSignaturesOfClaims,
        bool[] calldata isConfirmed
    ) external override {
        require(
            claimIndexes.length == suggestedAmounts.length &&
                claimIndexes.length == hashedSignaturesOfClaims.length &&
                claimIndexes.length == isConfirmed.length,
            "CV: Length mismatches"
        );
        require(claimIndexes.length <= MAX_CLAIMS_EXPOSE, "CV: Too many claims");

        for (uint256 i = 0; i < claimIndexes.length; i = uncheckedInc(i)) {
            uint256 claimIndex = claimIndexes[i];
            uint256 suggestedAmount = suggestedAmounts[i];
            uint256 voteIndex = _votesToIndex[claimIndex][msg.sender];
            require(canExpose(claimIndex, msg.sender), "CV: Cannot expose");

            bytes32 finalHash =
                keccak256(
                    abi.encodePacked(
                        hashedSignaturesOfClaims[i],
                        _voteInfo[voteIndex].encryptedVote,
                        suggestedAmount
                    )
                );

            require(_voteInfo[voteIndex].finalHash == finalHash, "CV: Data mismatches");
            (uint256 claimAmount, , ) = claimingRegistry.getClaimAmounts(claimIndex);
            require(claimAmount >= suggestedAmount, "CV: Amount exceeds coverage");

            if (isConfirmed[i]) {
                _calculateAverages(claimIndex, voteIndex, suggestedAmount);
                _voteInfo[voteIndex].suggestedAmount = suggestedAmount;
                _voteInfo[voteIndex].voteStatus = VoteStatus.EXPOSED;
                _votings[claimIndex].totalStakedVoted = _votings[claimIndex].totalStakedVoted.add(
                    getAmountVoted(voteIndex)
                );
            } else {
                _myAwaitingVotes[msg.sender].remove(claimIndex);
                _votings[claimIndex].voteCount = _votings[claimIndex].voteCount.trySub(1);
                _voteInfo[voteIndex].voteStatus = VoteStatus.CLOSED;
            }

            emit VoteExposed(voteIndex, msg.sender, suggestedAmount);
        }
    }

    function _calculateAverages(
        uint256 claimIndex,
        uint256 voteIndex,
        uint256 suggestedAmount
    ) internal {
        uint256 voterPower = getVotingPower(voteIndex);

        if (suggestedAmount > 0) {
            uint256 votedPower = _votings[claimIndex].votedYesTotalPower;
            uint256 totalPower = votedPower.add(voterPower);

            uint256 votedSuggestedPrice =
                _votings[claimIndex].votedAverageWithdrawalAmount.mul(votedPower);
            uint256 voterSuggestedPrice = suggestedAmount.mul(voterPower);

            _votings[claimIndex].votedAverageWithdrawalAmount = votedSuggestedPrice
                .add(voterSuggestedPrice)
                .tryDiv(totalPower);

            _votings[claimIndex].votedYesTotalPower = totalPower;
        } else {
            _votings[claimIndex].votedNoTotalPower = _votings[claimIndex].votedNoTotalPower.add(
                voterPower
            );
        }
    }

    // ********** REVEAL PROCESS ********** //
    function resolveVoting(uint256 claimIndex)
        external
        override
        onlyClaimingRegistry
        returns (
            uint256 totalStakedVoted,
            uint256 votedYesPercentage,
            uint256 claimRefund
        )
    {
        uint256 votedYesPower = _votings[claimIndex].votedYesTotalPower;
        uint256 votedNoPower = _votings[claimIndex].votedNoTotalPower;
        uint256 votedTotalPower = votedYesPower.add(votedNoPower);
        _votings[claimIndex].votedYesPercentage = votedYesPower.mul(PERCENTAGE_100).tryDiv(
            votedTotalPower
        );
        totalStakedVoted = _votings[claimIndex].totalStakedVoted;
        votedYesPercentage = _votings[claimIndex].votedYesPercentage;
        claimRefund = _votings[claimIndex].votedAverageWithdrawalAmount;
    }

    // ********** RECEIVE PROCESS ********** //
    function receiveVoteResultBatch(uint256[] calldata claimIndexes) external override {
        require(claimIndexes.length <= MAX_CLAIMS_RECEIVE, "CV: Too many claims");

        uint256 reward;
        uint256 penalty;
        uint256 reputation = reputationSystem.reputation(msg.sender);

        for (uint256 i = 0; i < claimIndexes.length; i = uncheckedInc(i)) {
            uint256 claimIndex = claimIndexes[i];
            uint256 voteIndex = _votesToIndex[claimIndex][msg.sender];
            require(canReceive(claimIndex, msg.sender), "CV: Cannot receive");

            if (
                claimingRegistry.getClaimStatus(claimIndex) !=
                IClaimingRegistry.ClaimStatus.EXPIRED
            ) {
                (uint256 deinReward, uint256 deinPenalty, uint256 newReputation) =
                    _getReward(claimIndex, voteIndex, msg.sender, reputation);

                reward = reward.add(deinReward);
                penalty = penalty.add(deinPenalty);
                reputation = newReputation;
            }

            _voteInfo[voteIndex].voteStatus = VoteStatus.CLOSED;
            _myAwaitingVotes[msg.sender].remove(claimIndex);

            emit VoteReceived(voteIndex, msg.sender);
        }

        if (reward > 0) {
            claimingRegistry.rewardForVoting(msg.sender, reward);
        }
        if (penalty > 0) {
            deinNFTStaking.applyPenalty(msg.sender, penalty);
        }
        if (reputation != reputationSystem.reputation(msg.sender)) {
            reputationSystem.setNewReputation(msg.sender, reputation);
        }
    }

    function _calculateMajorityYesVote(
        uint256 claimIndex,
        address voter,
        uint256 oldReputation
    ) internal view returns (uint256 _deinReward, uint256 _newReputation) {
        uint256 voterRatio =
            _getRewardRatio(claimIndex, voter, _votings[claimIndex].votedYesTotalPower);

        (, , uint256 rewardAmount) = claimingRegistry.getClaimAmounts(claimIndex);
        _deinReward = rewardAmount.mul(voterRatio).uncheckedDiv(PERCENTAGE_100);

        _newReputation = reputationSystem.getNewReputation(
            oldReputation,
            _votings[claimIndex].votedYesPercentage
        );
    }

    function _calculateMajorityNoVote(
        uint256 claimIndex,
        address voter,
        uint256 oldReputation
    ) internal view returns (uint256 _deinReward, uint256 _newReputation) {
        uint256 voterRatio =
            _getRewardRatio(claimIndex, voter, _votings[claimIndex].votedNoTotalPower);

        (, , uint256 rewardAmount) = claimingRegistry.getClaimAmounts(claimIndex);
        _deinReward = rewardAmount.mul(voterRatio).uncheckedDiv(PERCENTAGE_100);

        _newReputation = reputationSystem.getNewReputation(
            oldReputation,
            PERCENTAGE_100.trySub(_votings[claimIndex].votedYesPercentage)
        );
    }

    function _calculateMinorityVote(
        uint256 claimIndex,
        address voter,
        uint256 oldReputation
    ) internal view returns (uint256 _deinPenalty, uint256 _newReputation) {
        uint256 voteIndex = _votesToIndex[claimIndex][voter];
        _newReputation = reputationSystem.reputation(voter);
        uint256 minorityPercentageWithPrecision =
            Math.min(
                _votings[claimIndex].votedYesPercentage,
                PERCENTAGE_100.trySub(_votings[claimIndex].votedYesPercentage)
            );
        if (minorityPercentageWithPrecision < PENALTY_THRESHOLD) {
            _deinPenalty = getAmountVoted(voteIndex).mul(PENALTY_PERCENTAGE).div(PERCENTAGE_100);
            _newReputation = reputationSystem.getNewReputation(
                oldReputation,
                minorityPercentageWithPrecision
            );
        }
    }

    function _calculateUnexposedVote(uint256 claimIndex, address voter)
        internal
        view
        returns (uint256 _deinPenalty)
    {
        uint256 voteIndex = _votesToIndex[claimIndex][voter];
        _deinPenalty = getAmountVoted(voteIndex).mul(UNEXPOSED_PERCENTAGE).div(PERCENTAGE_100);
    }

    function _getRewardRatio(
        uint256 claimIndex,
        address voter,
        uint256 votedPower
    ) internal view returns (uint256) {
        uint256 voteIndex = _votesToIndex[claimIndex][voter];

        uint256 voterPower = getVotingPower(voteIndex);

        return voterPower.mul(PERCENTAGE_100).tryDiv(votedPower);
    }

    function _getReward(
        uint256 claimIndex,
        uint256 voteIndex,
        address voter,
        uint256 reputation
    )
        internal
        view
        returns (
            uint256 deinReward,
            uint256 deinPenalty,
            uint256 newReputation
        )
    {
        if (claimingRegistry.getClaimStatus(claimIndex) != IClaimingRegistry.ClaimStatus.EXPIRED) {
            if (_voteInfo[voteIndex].voteStatus == VoteStatus.ANONYMOUS) {
                deinPenalty = _calculateUnexposedVote(claimIndex, voter);
                newReputation = reputation;
            } else if (_voteInfo[voteIndex].voteStatus == VoteStatus.EXPOSED) {
                uint256 votedYesPercentage = _votings[claimIndex].votedYesPercentage;
                uint256 suggestedAmount = _voteInfo[voteIndex].suggestedAmount;

                if (votedYesPercentage >= PERCENTAGE_50 && suggestedAmount > 0) {
                    (deinReward, newReputation) = _calculateMajorityYesVote(
                        claimIndex,
                        voter,
                        reputation
                    );
                } else if (votedYesPercentage < PERCENTAGE_50 && suggestedAmount == 0) {
                    (deinReward, newReputation) = _calculateMajorityNoVote(
                        claimIndex,
                        voter,
                        reputation
                    );
                } else {
                    (deinPenalty, newReputation) = _calculateMinorityVote(
                        claimIndex,
                        voter,
                        reputation
                    );
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../Globals.sol";

interface IContractsRegistry {
    function currentNetwork() external view returns (Networks);

    function getAMMRouterContract() external view returns (address);

    function getAMMDEINToETHPairContract() external view returns (address);

    function getPriceFeedContract() external view returns (address);

    function getWETHContract() external view returns (address);

    function getUSDTContract() external view returns (address);

    function getBMIContract() external view returns (address);

    function getDEINContract() external view returns (address);

    function getPolicyBookRegistryContract() external view returns (address);

    function getPolicyBookFabricContract() external view returns (address);

    function getBMICoverStakingContract() external view returns (address);

    function getBMICoverStakingViewContract() external view returns (address);

    function getBMITreasury() external view returns (address);

    function getDEINTreasuryContract() external view returns (address);

    function getRewardsGeneratorContract() external view returns (address);

    function getLiquidityBridgeContract() external view returns (address);

    function getClaimingRegistryContract() external view returns (address);

    function getPolicyRegistryContract() external view returns (address);

    function getLiquidityRegistryContract() external view returns (address);

    function getClaimVotingContract() external view returns (address);

    function getRewardPoolContract() external view returns (address);

    function getCompoundPoolContract() external view returns (address);

    function getLeveragePortfolioViewContract() external view returns (address);

    function getCapitalPoolContract() external view returns (address);

    function getPolicyBookAdminContract() external view returns (address);

    function getPolicyQuoteContract() external view returns (address);

    function getBMIStakingContract() external view returns (address);

    function getDEINStakingContract() external view returns (address);

    function getDEINNFTStakingContract() external view returns (address);

    function getSTKBMIContract() external view returns (address);

    function getStkBMIStakingContract() external view returns (address);

    function getLiquidityMiningStakingETHContract() external view returns (address);

    function getLiquidityMiningStakingUSDTContract() external view returns (address);

    function getReputationSystemContract() external view returns (address);

    function getDefiProtocol1Contract() external view returns (address);

    function getAaveLendPoolAddressProvdierContract() external view returns (address);

    function getAaveATokenContract() external view returns (address);

    function getDefiProtocol2Contract() external view returns (address);

    function getCompoundCTokenContract() external view returns (address);

    function getCompoundComptrollerContract() external view returns (address);

    function getDefiProtocol3Contract() external view returns (address);

    function getYearnVaultContract() external view returns (address);

    function getYieldGeneratorContract() external view returns (address);

    function getShieldMiningContract() external view returns (address);

    function getDemandBookContract() external view returns (address);

    function getDemandBookLiquidityContract() external view returns (address);

    function getSwapEventContract() external view returns (address);

    function getVestingContract() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

uint256 constant SECONDS_IN_THE_YEAR = 365 * 24 * 60 * 60; // 365 days * 24 hours * 60 minutes * 60 seconds
uint256 constant SECONDS_IN_THE_MONTH = 30 * 24 * 60 * 60; // 30 days * 24 hours * 60 minutes * 60 seconds
uint256 constant DAYS_IN_THE_YEAR = 365;
uint256 constant MAX_INT = type(uint256).max;

uint256 constant DECIMALS18 = 10**18;

uint256 constant PRECISION = 10**25;
uint256 constant PERCENTAGE_100 = 100 * PRECISION;

uint256 constant BLOCKS_PER_DAY = 7200;
uint256 constant BLOCKS_PER_YEAR = BLOCKS_PER_DAY * 365;

uint256 constant BLOCKS_PER_DAY_BSC = 28800;
uint256 constant BLOCKS_PER_DAY_POLYGON = 43200;

uint256 constant APY_TOKENS = DECIMALS18;

uint256 constant ACTIVE_REWARD_PERCENTAGE = 80 * PRECISION;
uint256 constant CLOSED_REWARD_PERCENTAGE = 1 * PRECISION;

uint256 constant DEFAULT_REBALANCING_THRESHOLD = 10**23;

uint256 constant EPOCH_DAYS_AMOUNT = 7;

// ClaimVoting ClaimingRegistry
uint256 constant APPROVAL_PERCENTAGE = 66 * PRECISION;
uint256 constant PENALTY_THRESHOLD = 11 * PRECISION;
uint256 constant QUORUM = 10 * PRECISION;
uint256 constant CALCULATION_REWARD_PER_DAY = PRECISION;
uint256 constant PERCENTAGE_50 = 50 * PRECISION;
uint256 constant PENALTY_PERCENTAGE = 10 * PRECISION;
uint256 constant UNEXPOSED_PERCENTAGE = 1 * PRECISION;

// PolicyBook
uint256 constant MINUMUM_COVERAGE = 100 * DECIMALS18; // 100 STBL
uint256 constant ANNUAL_COVERAGE_TOKENS = MINUMUM_COVERAGE * 10; // 1000 STBL

uint256 constant PREMIUM_DISTRIBUTION_EPOCH = 1 days;
uint256 constant MAX_PREMIUM_DISTRIBUTION_EPOCHS = 90;
// policy
uint256 constant EPOCH_DURATION = 1 weeks;
uint256 constant MAXIMUM_EPOCHS = SECONDS_IN_THE_YEAR / EPOCH_DURATION;
uint256 constant MAXIMUM_EPOCHS_FOR_COMPOUND_LIQUIDITY = 5; //5 epoch
uint256 constant VIRTUAL_EPOCHS = 1;
// demand
uint256 constant DEMAND_EPOCH_DURATION = 1 days;
uint256 constant DEMAND_MAXIMUM_EPOCHS = SECONDS_IN_THE_YEAR / DEMAND_EPOCH_DURATION;
uint256 constant MINIMUM_EPOCHS = SECONDS_IN_THE_MONTH / DEMAND_EPOCH_DURATION;

uint256 constant PERIOD_DURATION = 30 days;

enum Networks {ETH, BSC, POL}

/// @dev unchecked increment
function uncheckedInc(uint256 i) pure returns (uint256) {
    unchecked {return i + 1;}
}

/// @dev unchecked decrement
function uncheckedDec(uint256 i) pure returns (uint256) {
    unchecked {return i - 1;}
}

function getBlocksPerDay(Networks _currentNetwork) pure returns (uint256 _blockPerDays) {
    if (_currentNetwork == Networks.ETH) {
        _blockPerDays = BLOCKS_PER_DAY;
    } else if (_currentNetwork == Networks.BSC) {
        _blockPerDays = BLOCKS_PER_DAY_BSC;
    } else if (_currentNetwork == Networks.POL) {
        _blockPerDays = BLOCKS_PER_DAY_POLYGON;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../libraries/SafeMath.sol";

/// @notice the intention of this library is to be able to easily convert
///     one amount of tokens with N decimal places
///     to another amount with M decimal places
library DecimalsConverter {
    using SafeMath for uint256;

    function convert(
        uint256 amount,
        uint256 baseDecimals,
        uint256 destinationDecimals
    ) internal pure returns (uint256) {
        if (baseDecimals > destinationDecimals) {
            amount = amount.uncheckedDiv(10**(baseDecimals.uncheckedSub(destinationDecimals)));
        } else if (baseDecimals < destinationDecimals) {
            amount = amount.mul(10**(destinationDecimals.uncheckedSub(baseDecimals)));
        }

        return amount;
    }

    function convertTo18(uint256 amount, uint256 baseDecimals) internal pure returns (uint256) {
        if (baseDecimals == 18) return amount;
        return convert(amount, baseDecimals, 18);
    }

    function convertFrom18(uint256 amount, uint256 destinationDecimals)
        internal
        pure
        returns (uint256)
    {
        if (destinationDecimals == 18) return amount;
        return convert(amount, 18, destinationDecimals);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

interface IClaimVoting {
    enum VoteStatus {ANONYMOUS, EXPOSED, CLOSED}
    enum VotePublicStatus {ANONYMOUS, EXPOSED, TO_RECEIVE, CLOSED}
    enum ListOption {VOTED, AWAITING}

    struct Voting {
        uint256 voteCount;
        uint256 votedAverageWithdrawalAmount;
        uint256 totalStakedVoted;
        uint256 votedYesTotalPower;
        uint256 votedNoTotalPower;
        uint256 votedYesPercentage;
    }

    struct VoteInfo {
        uint256 claimIndex;
        address voter;
        string encryptedVote;
        bytes32 finalHash;
        uint256 votingReputation;
        EnumerableSet.UintSet tokenIDs;
        VoteStatus voteStatus;
        uint256 suggestedAmount;
    }

    struct VotePublicInfo {
        uint256 voteIndex;
        uint256 claimIndex;
        uint256 votingReputation;
        uint256 claimAmount;
        VotePublicStatus votePublicStatus;
        uint256 suggestedAmount;
        uint256 timeRemaining;
        uint256 deinReward;
        uint256 deinPenalty;
        uint256 newReputation;
    }

    function getVotesCount(uint256 claimIndex) external view returns (uint256 countVoteOnClaim);

    function getRepartition(uint256 claimIndex)
        external
        view
        returns (uint256 yesPercentage, uint256 noPercentage);

    function canUnlock(uint256 tokenID, address user) external view returns (bool);

    function canVote(uint256 claimIndex, address voter) external view returns (bool);

    function canExpose(uint256 claimIndex, address voter) external view returns (bool);

    function canReceive(uint256 claimIndex, address voter) external view returns (bool);

    function anonymouslyVoteBatch(
        uint256[] calldata claimIndexes,
        bytes32[] calldata finalHashes,
        string[] calldata encryptedVotes,
        uint256[] calldata tokenIDs
    ) external;

    function exposeVoteBatch(
        uint256[] calldata claimIndexes,
        uint256[] calldata suggestedAmounts,
        bytes32[] calldata hashedSignaturesOfClaims,
        bool[] calldata isConfirmed
    ) external;

    function resolveVoting(uint256 claimIndex)
        external
        returns (
            uint256 totalStakedVoted,
            uint256 votedYesPercentage,
            uint256 claimRefund
        );

    // TO TEST
    function receiveVoteResultBatch(uint256[] calldata claimIndexes) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.7;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * COPIED FROM https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.5/contracts/utils/math/SafeMath.sol
 * customize try functions to return one value which is uint256 instead of return tupple
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return 0;
            return c;
        }
    }

    function uncheckedAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {return a + b;}
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            if (b > a) return 0;
            return a - b;
        }
    }

    function uncheckedSub(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {return a - b;}
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return 0;
            uint256 c = a * b;
            if (c / a != b) return 0;
            return c;
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            if (b == 0) return 0;
            return a / b;
        }
    }

    function uncheckedDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {return a / b;}
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            if (b == 0) return 0;
            return a % b;
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./IStaking.sol";

interface IDEINStaking {
    event StakedNFTMinted(uint256 nftMintId, address indexed recipient);
    event StakedNFTBurned(uint256 tokenId, address indexed recipient);
    event CLAIMED(uint256 claimedDEIN, uint256 tokenId, address indexed recipient);
    event VoterPenaltyApplied(uint256 penaltyAmount, uint256 tokenId);

    struct VestingInfo {
        uint256 locked;
        uint256 claimed;
    }

    /// return voting multiplier
    function voterMultipliers(uint256 _stakeDuration) external view returns (uint256);

    function stakeFor(
        address _user,
        uint256 _amountDEIN,
        uint256 _stakingPositionInput,
        IStaking.StakingPosition _stakingPosition,
        bool _isVesting
    ) external;

    function claim(uint256 _tokenId, uint256 _amount) external;

    function applyVoterPenalty(
        uint256[] calldata _tokenIds,
        uint256[] calldata _penaltyAmounts,
        address user
    ) external;

    function getVotingPower(uint256[] calldata _tokenIds)
        external
        view
        returns (uint256 _votingPower);

    function getUserStakingPower(address _user) external view returns (uint256 _totalStakingPower);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IReputationSystem {
    /// @notice sets new reputation for the voter
    function setNewReputation(address voter, uint256 newReputation) external;

    /// @notice returns voter's new reputation
    function getNewReputation(address voter, uint256 percentageWithPrecision)
        external
        view
        returns (uint256);

    /// @notice alternative way of knowing new reputation
    function getNewReputation(uint256 voterReputation, uint256 percentageWithPrecision)
        external
        pure
        returns (uint256);

    /// @notice returns true if the user voted at least once
    function hasVotedOnce(address user) external view returns (bool);

    /// @notice returns true if user's reputation is grater than or equal to trusted voter threshold
    function isTrustedVoter(address user) external view returns (bool);

    /// @notice this function returns reputation threshold multiplied by 10**25
    function getTrustedVoterReputationThreshold() external view returns (uint256);

    /// @notice this function returns reputation multiplied by 10**25
    function reputation(address user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../interfaces/IContractsRegistry.sol";

abstract contract AbstractDependant {
    /// @dev keccak256(AbstractDependant.setInjector(address)) - 1
    bytes32 private constant _INJECTOR_SLOT =
        0xd6b8f2e074594ceb05d47c27386969754b6ad0c15e5eb8f691399cd0be980e76;

    modifier onlyInjectorOrZero() {
        address _injector = injector();

        require(_injector == address(0) || _injector == msg.sender, "Dependant: Not an injector");
        _;
    }

    function setInjector(address _injector) external onlyInjectorOrZero {
        bytes32 slot = _INJECTOR_SLOT;

        assembly {
            sstore(slot, _injector)
        }
    }

    /// @dev has to apply onlyInjectorOrZero() modifier
    function setDependencies(IContractsRegistry) external virtual;

    function injector() public view returns (address _injector) {
        bytes32 slot = _INJECTOR_SLOT;

        assembly {
            _injector := sload(slot)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

interface IDEINNFTStaking {
    function isLocked(uint256[] calldata tokenIDs, address user) external view returns (bool);

    function totalLocked() external view returns (uint256);

    function lockNFT(uint256 tokenID) external;

    function unlockNFT(uint256 tokenID) external;

    function applyPenalty(address user, uint256 penalty) external;

    function removeLockedNFT(address user, uint256 tokenID) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IPolicyBookFabric.sol";

interface IClaimingRegistry {
    enum Provenance {POLICY, DEMAND}
    enum BookStatus {UNCLAIMABLE, CAN_CLAIM, CAN_APPEAL}

    enum ClaimStatus {PENDING, ACCEPTED, DENIED, REJECTED, EXPIRED}
    enum ClaimPublicStatus {VOTING, EXPOSURE, REVEAL, ACCEPTED, DENIED, REJECTED, EXPIRED}

    enum WithdrawalStatus {NONE, PENDING, READY}

    enum ListOption {ALL, MINE}

    struct ClaimInfo {
        ClaimProvenance claimProvenance;
        string evidenceURI;
        uint256 dateStart;
        uint256 dateEnd;
        bool appeal;
        ClaimStatus claimStatus;
        uint256 claimAmount;
        uint256 claimRefund;
        uint256 lockedAmount;
        uint256 rewardAmount;
    }

    struct PublicClaimInfo {
        uint256 claimIndex;
        ClaimProvenance claimProvenance;
        string evidenceURI;
        uint256 dateStart;
        bool appeal;
        ClaimPublicStatus claimPublicStatus;
        uint256 claimAmount;
        uint256 claimRefund;
        uint256 timeRemaining;
        bool canVote;
        bool canExpose;
        bool canCalculate;
        uint256 calculationReward;
        uint256 votesCount;
        uint256 repartitionYES;
        uint256 repartitionNO;
    }

    struct ClaimProvenance {
        Provenance provenance;
        address claimer;
        address bookAddress; // policy address or DemandBook address
        uint256 demandIndex; // in case it's a demand
    }

    struct ClaimWithdrawalInfo {
        uint256 readyToWithdrawDate;
        bool committed;
    }

    function claimInfo(uint256 claimIndex)
        external
        view
        returns (
            ClaimProvenance memory claimProvenance,
            string memory evidenceURI,
            uint256 dateStart,
            uint256 dateEnd,
            bool appeal,
            ClaimStatus claimStatus,
            uint256 claimAmount,
            uint256 lockedAmount,
            uint256 claimRefund,
            uint256 rewardAmount
        );

    /// @notice returns anonymous voting duration
    function anonymousVotingDuration() external view returns (uint256);

    /// @notice returns the whole voting duration
    function votingDuration() external view returns (uint256);

    function getClaimIndex(ClaimProvenance calldata claimProvenance)
        external
        view
        returns (uint256);

    /// @notice returns current status of a claim
    function getClaimStatus(uint256 claimIndex) external view returns (ClaimStatus claimStatus);

    function getClaimProvenance(uint256 claimIndex) external view returns (ClaimProvenance memory);

    function getClaimDateStart(uint256 claimIndex) external view returns (uint256 dateStart);

    function getClaimDateEnd(uint256 claimIndex) external view returns (uint256 dateEnd);

    function getClaimAmounts(uint256 claimIndex)
        external
        view
        returns (
            uint256 claimAmount,
            uint256 lockedAmount,
            uint256 rewardAmount
        );

    function isClaimAppeal(uint256 claimIndex) external view returns (bool);

    function isClaimAnonymouslyVotable(uint256 claimIndex) external view returns (bool);

    function isClaimExposablyVotable(uint256 claimIndex) external view returns (bool);

    function isClaimResolved(uint256 claimIndex) external view returns (bool);

    function claimsToRefundCount() external view returns (uint256);

    function updateImageUriOfClaim(uint256 claimIndex, string calldata newEvidenceURI) external;

    function canClaim(ClaimProvenance calldata claimProvenance) external view returns (bool);

    function canAppeal(ClaimProvenance calldata claimProvenance) external view returns (bool);

    function submitClaim(
        ClaimProvenance calldata claimProvenance,
        string calldata evidenceURI,
        uint256 cover,
        bool isAppeal
    ) external;

    function calculateResult(uint256 claimIndex) external;

    function getAllPendingClaimsAmount(
        bool isRebalancing,
        uint256 limit,
        address bookAddress
    ) external view returns (uint256 totalClaimsAmount);

    function withdrawClaim(uint256 claimIndex) external;

    function canBuyNewBook(ClaimProvenance calldata claimProvenance) external;

    function getBookStatus(ClaimProvenance memory claimProvenance)
        external
        view
        returns (BookStatus);

    function hasProcedureOngoing(address bookAddress, uint256 demandIndex)
        external
        view
        returns (bool);

    function withdrawLockedAmount(uint256 claimIndex) external;

    function rewardForVoting(address voter, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IStaking {
    event RewardsSet(
        uint256 rewardPerBlock,
        uint256 firstBlockWithReward,
        uint256 lastBlockWithReward
    );
    event RewardTokensRecovered(uint256 amount);

    event Staked(address indexed user, uint256 stakingIndex, uint256 amount, uint256 lock);
    event Withdrawn(
        address indexed user,
        uint256 stakingIndex,
        uint256 amountByLiquidation,
        uint256 reward
    );

    event Liquidated(
        uint256 liquidationAmount,
        uint256 amountToken,
        uint256 amountETH,
        address indexed receiver
    );
    event RewardPaid(address indexed user, uint256 stakingIndex, uint256 reward);
    event AddedToStake(address indexed user, uint256 stakingIndex, uint256 amount);

    struct StakingInfo {
        address staker;
        uint256 staked;
        uint256 startTime;
        uint256 lockingPeriod;
        uint256 rewards;
        uint256 rewardPerTokenPaid;
        bool isVesting;
    }

    struct PublicStakingInfo {
        uint256 stakingId;
        uint256 staked;
        uint256 startTime;
        uint256 endTime;
        uint256 lockingPeriod;
        uint256 stakingMultiplier;
        uint256 rewards;
        bool isVesting;
    }

    enum StakingPosition {NEW, CURRENT}

    function lockingPeriods(uint256 index) external returns (uint256);

    function stakeWithPermit(
        uint256 _amount,
        uint256 _lock,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    function stake(uint256 _amount, uint256 _lock) external;

    function withdraw(uint256 _stakingIndex) external;

    function claimReward(uint256[] memory _tokenIds) external;

    function restakeReward(
        uint256[] memory _tokenIds,
        uint256 _stakingPositionInput,
        StakingPosition _stakingPosition
    ) external;

    function liquidate(
        uint256 _liquidationAmount,
        uint256 _amountTokenMin,
        uint256 _amountETHMin,
        address _receiver
    ) external;

    function getPoolLiquidity() external view returns (uint256);

    function setRewards(uint256 _amount, uint256 _durations) external;

    function getFullStakedAmount(uint256 _stakingIndex) external view returns (uint256);

    // staked amount stored
    function getFullStakedAmounts(uint256[] calldata _stakingIndexes)
        external
        view
        returns (uint256 totalStaked);

    function canWithdraw(uint256 _stakingIndex) external view returns (bool);

    function balanceOf(address user) external view returns (uint256);

    function ownerOf(uint256 _stakingIndex) external view returns (address);

    function tokenOfOwnerByIndex(address user, uint256 index) external view returns (uint256);

    function getStakingInfoByStaker(
        address staker,
        uint256 offset,
        uint256 limit
    ) external view returns (PublicStakingInfo[] memory _stakingInfo);

    function getStakingInfoByIndex(uint256 _stakingIndex)
        external
        view
        returns (PublicStakingInfo memory);

    function stakingHasBenefits(uint256 _stakingIndex) external view returns (bool);

    function earned(uint256 _nftId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

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
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
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
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
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
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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

        /// @solidity memory-safe-assembly
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
     * @dev Returns the number of values in the set. O(1).
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

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IPolicyBookFabric {
    /// @dev update getContractTypes() in RewardGenerator each time this enum is modified
    enum ContractType {CONTRACT, STABLECOIN, SERVICE, EXCHANGE, VARIOUS, CUSTODIAN}

    /// @notice Create new Policy Book contract, access: ANY
    /// @param _contract is Contract to create policy book for
    /// @param _contractType is Contract to create policy book for
    /// @param _description is bmiXCover token desription for this policy book
    /// @param _projectSymbol replaces x in bmiXCover token symbol
    /// @param _initialDeposit is an amount user deposits on creation (addLiquidity())
    /// @return _policyBook is address of created contract
    function create(
        address _contract,
        ContractType _contractType,
        string calldata _description,
        string calldata _projectSymbol,
        uint256 _initialDeposit,
        address _shieldMiningToken
    ) external returns (address);

    function createLeveragePools(
        address _insuranceContract,
        ContractType _contractType,
        string calldata _description,
        string calldata _projectSymbol
    ) external returns (address);
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