/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@kleros/dispute-resolver-interface-contract/contracts/IDisputeResolver.sol";
import "./ITruthPost.sol";

/// @title  The Trust Post
/// @author https://github.com/proveuswrong<0xferit, gratestas>
/// @notice Smart contract for a type of curation, where submitted items are on hold until they are withdrawn and the amount of security deposits are determined by submitters.
/// @dev    You should target ITruthPost interface contract for building on top. Otherwise you risk incompatibility across versions.
///         Articles are not addressed with their identifiers. That enables us to reuse same storage address for another article later.///         Arbitrator is fixed, but subcourts, jury size and metaevidence are not.
///         We prevent articles to get withdrawn immediately. This is to prevent submitter to escape punishment in case someone discovers an argument to debunk the article.
///         Bounty amounts are compressed with a lossy compression method to save on storage cost.
/// @custom:approvals 0xferit, gratestas
contract TruthPost is ITruthPost, IArbitrable, IEvidence {
    IArbitrator public immutable ARBITRATOR;
    uint256 public constant NUMBER_OF_LEAST_SIGNIFICANT_BITS_TO_IGNORE = 32; // To compress bounty amount to gain space in struct. Lossy compression.

    uint8 public categoryCounter = 0;

    address payable public admin = payable(msg.sender);

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    struct DisputeData {
        address payable challenger;
        RulingOptions outcome;
        uint8 articleCategory;
        bool resolved; // To remove dependency to disputeStatus function of arbitrator. This function is likely to be removed in Kleros v2.
        uint80 articleStorageAddress; // 2^16 is sufficient. Just using extra available space.
        Round[] rounds; // Tracks each appeal round of a dispute.
    }

    struct Round {
        mapping(address => uint256[NUMBER_OF_RULING_OPTIONS + 1]) contributions;
        bool[NUMBER_OF_RULING_OPTIONS + 1] hasPaid; // True if the fees for this particular answer has been fully paid in the form hasPaid[rulingOutcome].
        uint256[NUMBER_OF_RULING_OPTIONS + 1] totalPerRuling;
        uint256 totalClaimableAfterExpenses;
    }

    struct Article {
        address payable owner;
        uint32 withdrawalPermittedAt; // Overflows in year 2106.
        uint56 bountyAmount; // 32-bits compression. Decompressed size is 88 bits.
        uint8 category;
    }

    bytes[64] public categoryToArbitratorExtraData;

    mapping(uint80 => Article) public articleStorage; // Key: Storage address of article. Articles are not addressed with their identifiers, to enable reusing a storage slot.
    mapping(uint256 => DisputeData) public disputes; // Key: Dispute ID as in arbitrator.

    constructor(
        IArbitrator _arbitrator,
        bytes memory _arbitratorExtraData,
        string memory _metaevidenceIpfsUri,
        uint256 _articleWithdrawalTimelock,
        uint256 _winnerStakeMultiplier,
        uint256 _loserStakeMultiplier,
        address payable _treasury
    ) ITruthPost(_articleWithdrawalTimelock, _winnerStakeMultiplier, _loserStakeMultiplier, _treasury) {
        ARBITRATOR = _arbitrator;
        newCategory(_metaevidenceIpfsUri, _arbitratorExtraData);
    }

    /// @inheritdoc ITruthPost
    function initializeArticle(
        string calldata _articleID,
        uint8 _category,
        uint80 _searchPointer
    ) external payable override {
        require(_category < categoryCounter, "This category does not exist");

        Article storage article;
        do {
            article = articleStorage[_searchPointer++];
        } while (article.bountyAmount != 0);

        article.owner = payable(msg.sender);
        article.bountyAmount = uint56(msg.value >> NUMBER_OF_LEAST_SIGNIFICANT_BITS_TO_IGNORE);
        article.category = _category;

        require(article.bountyAmount > 0, "You can't initialize an article without putting a bounty.");

        uint256 articleStorageAddress = _searchPointer - 1;
        emit NewArticle(_articleID, _category, articleStorageAddress);
        emit BalanceUpdate(
            articleStorageAddress,
            uint256(article.bountyAmount) << NUMBER_OF_LEAST_SIGNIFICANT_BITS_TO_IGNORE
        );
    }

    /// @inheritdoc ITruthPost
    function submitEvidence(uint256 _disputeID, string calldata _evidenceURI) external override {
        emit Evidence(ARBITRATOR, _disputeID, msg.sender, _evidenceURI);
    }

    /// @inheritdoc ITruthPost
    function increaseBounty(uint80 _articleStorageAddress) external payable override {
        Article storage article = articleStorage[_articleStorageAddress];
        require(msg.sender == article.owner, "Only author can increase bounty of an article.");
        // To prevent mistakes.

        article.bountyAmount += uint56(msg.value >> NUMBER_OF_LEAST_SIGNIFICANT_BITS_TO_IGNORE);

        emit BalanceUpdate(
            _articleStorageAddress,
            uint256(article.bountyAmount) << NUMBER_OF_LEAST_SIGNIFICANT_BITS_TO_IGNORE
        );
    }

    /// @inheritdoc ITruthPost
    function initiateWithdrawal(uint80 _articleStorageAddress) external override {
        Article storage article = articleStorage[_articleStorageAddress];
        require(msg.sender == article.owner, "Only author can withdraw an article.");
        require(article.withdrawalPermittedAt == 0, "Withdrawal already initiated or there is a challenge.");

        article.withdrawalPermittedAt = uint32(block.timestamp + ARTICLE_WITHDRAWAL_TIMELOCK);
        emit TimelockStarted(_articleStorageAddress);
    }

    /// @inheritdoc ITruthPost
    function withdraw(uint80 _articleStorageAddress) external override {
        Article storage article = articleStorage[_articleStorageAddress];

        require(msg.sender == article.owner, "Only author can withdraw an article.");
        require(article.withdrawalPermittedAt != 0, "You need to initiate withdrawal first.");
        require(
            article.withdrawalPermittedAt <= block.timestamp,
            "You need to wait for timelock or wait until the challenge ends."
        );

        uint256 withdrawal = uint96(article.bountyAmount) << NUMBER_OF_LEAST_SIGNIFICANT_BITS_TO_IGNORE;
        article.bountyAmount = 0;
        // This is critical to reset.
        article.withdrawalPermittedAt = 0;
        // This too, otherwise new article inside the same slot can withdraw instantly.
        payable(msg.sender).transfer(withdrawal);
        emit ArticleWithdrawn(_articleStorageAddress);
    }

    /// @inheritdoc ITruthPost
    function challenge(uint80 _articleStorageAddress) external payable override {
        Article storage article = articleStorage[_articleStorageAddress];
        require(article.bountyAmount > 0, "Nothing to challenge.");
        require(article.withdrawalPermittedAt != type(uint32).max, "There is an ongoing challenge.");
        article.withdrawalPermittedAt = type(uint32).max;
        // Mark as challenged.

        require(msg.value >= challengeFee(_articleStorageAddress), "Insufficient funds to challenge.");

        uint256 taxAmount = ((uint96(article.bountyAmount) << NUMBER_OF_LEAST_SIGNIFICANT_BITS_TO_IGNORE) *
            challengeTaxRate) / MULTIPLIER_DENOMINATOR;
        treasuryBalance += taxAmount;

        uint256 disputeID = ARBITRATOR.createDispute{value: msg.value - taxAmount}(
            NUMBER_OF_RULING_OPTIONS,
            categoryToArbitratorExtraData[article.category]
        );

        disputes[disputeID].challenger = payable(msg.sender);
        disputes[disputeID].rounds.push();
        disputes[disputeID].articleStorageAddress = uint80(_articleStorageAddress);
        disputes[disputeID].articleCategory = article.category;

        // Evidence group ID is dispute ID.
        emit Dispute(ARBITRATOR, disputeID, article.category, disputeID);
        // This event links the dispute to an article storage address.
        emit Challenge(_articleStorageAddress, msg.sender, disputeID);
    }

    /// @inheritdoc ITruthPost
    function fundAppeal(uint256 _disputeID, RulingOptions _supportedRuling)
        external
        payable
        override
        returns (bool fullyFunded)
    {
        DisputeData storage dispute = disputes[_disputeID];

        RulingOptions currentRuling = RulingOptions(ARBITRATOR.currentRuling(_disputeID));
        uint256 basicCost;
        uint256 totalCost;
        {
            (uint256 appealWindowStart, uint256 appealWindowEnd) = ARBITRATOR.appealPeriod(_disputeID);

            uint256 multiplier;

            if (_supportedRuling == currentRuling) {
                require(block.timestamp < appealWindowEnd, "Funding must be made within the appeal period.");

                multiplier = WINNER_STAKE_MULTIPLIER;
            } else {
                require(
                    block.timestamp <
                        (appealWindowStart +
                            (((appealWindowEnd - appealWindowStart) * LOSER_APPEAL_PERIOD_MULTIPLIER) /
                                MULTIPLIER_DENOMINATOR)),
                    "Funding must be made within the first half appeal period."
                );

                multiplier = LOSER_STAKE_MULTIPLIER;
            }

            basicCost = ARBITRATOR.appealCost(_disputeID, categoryToArbitratorExtraData[dispute.articleCategory]);
            totalCost = basicCost + ((basicCost * (multiplier)) / MULTIPLIER_DENOMINATOR);
        }

        RulingOptions supportedRulingOutcome = RulingOptions(_supportedRuling);

        uint256 lastRoundIndex = dispute.rounds.length - 1;
        Round storage lastRound = dispute.rounds[lastRoundIndex];
        require(!lastRound.hasPaid[uint256(supportedRulingOutcome)], "Appeal fee has already been paid.");

        uint256 contribution;
        {
            uint256 paidSoFar = lastRound.totalPerRuling[uint256(supportedRulingOutcome)];

            if (paidSoFar >= totalCost) {
                contribution = 0;
                // This can happen if arbitration fee gets lowered in between contributions.
            } else {
                contribution = totalCost - paidSoFar > msg.value ? msg.value : totalCost - paidSoFar;
            }
        }

        emit Contribution(_disputeID, lastRoundIndex, _supportedRuling, msg.sender, contribution);

        lastRound.contributions[msg.sender][uint256(supportedRulingOutcome)] += contribution;
        lastRound.totalPerRuling[uint256(supportedRulingOutcome)] += contribution;

        if (lastRound.totalPerRuling[uint256(supportedRulingOutcome)] >= totalCost) {
            lastRound.totalClaimableAfterExpenses += lastRound.totalPerRuling[uint256(supportedRulingOutcome)];
            lastRound.hasPaid[uint256(supportedRulingOutcome)] = true;
            emit RulingFunded(_disputeID, lastRoundIndex, _supportedRuling);
        }

        if (
            lastRound.hasPaid[uint256(RulingOptions.ChallengeFailed)] &&
            lastRound.hasPaid[uint256(RulingOptions.Debunked)]
        ) {
            dispute.rounds.push();
            lastRound.totalClaimableAfterExpenses -= basicCost;
            ARBITRATOR.appeal{value: basicCost}(_disputeID, categoryToArbitratorExtraData[dispute.articleCategory]);
        }

        // Ignoring failure condition deliberately.
        if (msg.value - contribution > 0) payable(msg.sender).send(msg.value - contribution);

        return lastRound.hasPaid[uint256(supportedRulingOutcome)];
    }

    /// @notice Execute a ruling
    /// @dev This is only for arbitrator to use.
    /// @param _disputeID The dispute ID as in arbitrator.
    /// @param _ruling Winning ruling option.
    function rule(uint256 _disputeID, uint256 _ruling) external override {
        require(IArbitrator(msg.sender) == ARBITRATOR);

        DisputeData storage dispute = disputes[_disputeID];
        Round storage lastRound = dispute.rounds[dispute.rounds.length - 1];

        // Appeal overrides arbitrator ruling. If a ruling option was not fully funded and the counter ruling option was funded, funded ruling option wins by default.
        RulingOptions wonByDefault;
        if (lastRound.hasPaid[uint256(RulingOptions.ChallengeFailed)]) {
            wonByDefault = RulingOptions.ChallengeFailed;
        } else if (lastRound.hasPaid[uint256(RulingOptions.ChallengeFailed)]) {
            wonByDefault = RulingOptions.Debunked;
        }

        RulingOptions actualRuling = wonByDefault != RulingOptions.Tied ? wonByDefault : RulingOptions(_ruling);
        dispute.outcome = actualRuling;

        uint80 articleStorageAddress = dispute.articleStorageAddress;

        Article storage article = articleStorage[articleStorageAddress];

        if (actualRuling == RulingOptions.Debunked) {
            uint256 bounty = uint96(article.bountyAmount) << NUMBER_OF_LEAST_SIGNIFICANT_BITS_TO_IGNORE;
            article.bountyAmount = 0;

            emit Debunked(articleStorageAddress);
            disputes[_disputeID].challenger.send(bounty);
            // Ignoring failure condition deliberately.
        }
        // In case of tie, article stands.
        article.withdrawalPermittedAt = 0;
        // Unmark as challenged.
        dispute.resolved = true;

        emit Ruling(IArbitrator(msg.sender), _disputeID, _ruling);
    }

    /// @inheritdoc ITruthPost
    function withdrawFeesAndRewardsForAllRoundsAndAllRulings(uint256 _disputeID, address payable _contributor)
        external
        override
    {
        DisputeData storage dispute = disputes[_disputeID];
        uint256 noOfRounds = dispute.rounds.length;
        for (uint256 roundNumber = 0; roundNumber < noOfRounds; roundNumber++) {
            for (uint256 rulingOption = 0; rulingOption <= NUMBER_OF_RULING_OPTIONS; rulingOption++)
                withdrawFeesAndRewards(_disputeID, _contributor, roundNumber, RulingOptions(rulingOption));
        }
    }

    /// @inheritdoc ITruthPost
    function withdrawFeesAndRewardsForAllRounds(
        uint256 _disputeID,
        address payable _contributor,
        RulingOptions _ruling
    ) external override {
        DisputeData storage dispute = disputes[_disputeID];
        uint256 noOfRounds = dispute.rounds.length;
        for (uint256 roundNumber = 0; roundNumber < noOfRounds; roundNumber++) {
            withdrawFeesAndRewards(_disputeID, _contributor, roundNumber, _ruling);
        }
    }

    /// @inheritdoc ITruthPost
    function withdrawFeesAndRewardsForGivenPositions(
        uint256 _disputeID,
        address payable _contributor,
        uint256[][] calldata positions
    ) external override {
        for (uint256 roundNumber = 0; roundNumber < positions.length; roundNumber++) {
            for (uint256 rulingOption = 0; rulingOption < positions[roundNumber].length; rulingOption++) {
                if (positions[roundNumber][rulingOption] > 0) {
                    withdrawFeesAndRewards(_disputeID, _contributor, roundNumber, RulingOptions(rulingOption));
                }
            }
        }
    }

    /// @inheritdoc ITruthPost
    function withdrawFeesAndRewards(
        uint256 _disputeID,
        address payable _contributor,
        uint256 _roundNumber,
        RulingOptions _ruling
    ) public override returns (uint256 amount) {
        DisputeData storage dispute = disputes[_disputeID];
        require(dispute.resolved, "There is no ruling yet.");

        Round storage round = dispute.rounds[_roundNumber];

        amount = getWithdrawableAmount(round, _contributor, _ruling, dispute.outcome);

        if (amount != 0) {
            round.contributions[_contributor][uint256(RulingOptions(_ruling))] = 0;
            _contributor.send(amount);
            // Ignoring failure condition deliberately.
            emit Withdrawal(_disputeID, _roundNumber, _ruling, _contributor, amount);
        }
    }

    /// @notice Updates the challenge tax rate of the contract to a new value.
    /// @dev    The new challenge tax rate must be at most 25% based on MULTIPLIER_DENOMINATOR.
    ///         Only the current administrator can call this function. Emits ChallengeTaxRateUpdate.
    /// @param _newChallengeTaxRate The new challenge tax rate to be set.
    function updateChallengeTaxRate(uint256 _newChallengeTaxRate) external onlyAdmin {
        require(_newChallengeTaxRate <= 256, "The tax rate can only be increased by a maximum of 25%");
        challengeTaxRate = _newChallengeTaxRate;
        emit ChallengeTaxRateUpdate(_newChallengeTaxRate);
    }

    /// @notice Transfers the balance of the contract to the treasury.
    /// @dev    Allows the contract to send its entire balance to the treasury address.
    ///         It is important to ensure that the treasury address is set correctly.
    ///         If the transfer fails, an exception will be raised, and the funds will remain in the contract.
    ///         Emits TreasuryBalanceUpdate.
    function transferBalanceToTreasury() public {
        uint256 amount = treasuryBalance;
        treasuryBalance = 0;
        TREASURY.send(amount);
        emit TreasuryBalanceUpdate(amount);
    }

    /// @inheritdoc ITruthPost
    function switchPublishingLock() public override onlyAdmin {
        isPublishingEnabled = !isPublishingEnabled;
    }

    /// @notice Changes the administrator of the contract to a new address.
    /// @dev    Only the current administrator can call this function. Emits AdminUpdate.
    /// @param  _newAdmin The address of the new administrator.
    function changeAdmin(address payable _newAdmin) external onlyAdmin {
        admin = _newAdmin;
        emit AdminUpdate(_newAdmin);
    }

    /// @notice Changes the treasury address of the contract to a new address.
    /// @dev    Only the current administrator can call this function. Emits TreasuryUpdate.
    /// @param  _newTreasury The address of the new treasury.
    function changeTreasury(address payable _newTreasury) external onlyAdmin {
        TREASURY = _newTreasury;
        emit TreasuryUpdate(_newTreasury);
    }

    /// @inheritdoc ITruthPost
    function changeWinnerStakeMultiplier(uint256 _newWinnerStakeMultiplier) external override onlyAdmin {
        WINNER_STAKE_MULTIPLIER = _newWinnerStakeMultiplier;
        emit WinnerStakeMultiplierUpdate(_newWinnerStakeMultiplier);
    }

    /// @inheritdoc ITruthPost
    function changeLoserStakeMultiplier(uint256 _newLoserStakeMultiplier) external override onlyAdmin {
        LOSER_STAKE_MULTIPLIER = _newLoserStakeMultiplier;
        emit LoserStakeMultiplierUpdate(_newLoserStakeMultiplier);
    }

    /// @inheritdoc ITruthPost
    function changeLoserAppealPeriodMultiplier(uint256 _newLoserAppealPeriodMultiplier) external override onlyAdmin {
        LOSER_APPEAL_PERIOD_MULTIPLIER = _newLoserAppealPeriodMultiplier;
        emit LoserAppealPeriodMultiplierUpdate(_newLoserAppealPeriodMultiplier);
    }
    
    /// @inheritdoc ITruthPost
    function changeArticleWithdrawalTimelock(uint256 _newArticleWithdrawalTimelock) external override onlyAdmin {
        ARTICLE_WITHDRAWAL_TIMELOCK = _newArticleWithdrawalTimelock;
        emit ArticleWithdrawalTimelockUpdate(_newArticleWithdrawalTimelock);
    }


    /// @notice Initialize a category.
    /// @param _metaevidenceIpfsUri IPFS content identifier for metaevidence.
    /// @param _arbitratorExtraData Extra data of Kleros arbitrator, signaling subcourt and jury size selection.
    function newCategory(string memory _metaevidenceIpfsUri, bytes memory _arbitratorExtraData) public {
        require(categoryCounter + 1 != 0, "No space left for a new category");
        emit MetaEvidence(categoryCounter, _metaevidenceIpfsUri);
        categoryToArbitratorExtraData[categoryCounter] = _arbitratorExtraData;

        categoryCounter++;
    }

    /// @inheritdoc ITruthPost
    function transferOwnership(uint80 _articleStorageAddress, address payable _newOwner) external override {
        Article storage article = articleStorage[_articleStorageAddress];
        require(msg.sender == article.owner, "Only author can transfer ownership.");
        article.owner = _newOwner;
        emit OwnershipTransfer(_newOwner);
    }

    /// @inheritdoc ITruthPost
    function challengeFee(uint80 _articleStorageAddress) public view override returns (uint256) {
        Article storage article = articleStorage[_articleStorageAddress];

        uint256 arbitrationFee = ARBITRATOR.arbitrationCost(categoryToArbitratorExtraData[article.category]);
        uint256 challengeTax = ((uint96(article.bountyAmount) << NUMBER_OF_LEAST_SIGNIFICANT_BITS_TO_IGNORE) *
            challengeTaxRate) / MULTIPLIER_DENOMINATOR;

        return arbitrationFee + challengeTax;
    }

    /// @inheritdoc ITruthPost
    function appealFee(uint256 _disputeID) external view override returns (uint256 arbitrationFee) {
        DisputeData storage dispute = disputes[_disputeID];
        arbitrationFee = ARBITRATOR.appealCost(_disputeID, categoryToArbitratorExtraData[dispute.articleCategory]);
    }

    /// @inheritdoc ITruthPost
    function findVacantStorageSlot(uint80 _searchPointer) external view override returns (uint256 vacantSlotIndex) {
        Article storage article;
        do {
            article = articleStorage[_searchPointer++];
        } while (article.bountyAmount != 0);

        return _searchPointer - 1;
    }

    /// @inheritdoc ITruthPost
    function getTotalWithdrawableAmount(uint256 _disputeID, address payable _contributor)
        external
        view
        override
        returns (uint256 sum, uint256[][] memory amounts)
    {
        DisputeData storage dispute = disputes[_disputeID];
        if (!dispute.resolved) return (uint256(0), amounts);
        uint256 noOfRounds = dispute.rounds.length;
        RulingOptions finalRuling = dispute.outcome;

        amounts = new uint256[][](noOfRounds);
        for (uint256 roundNumber = 0; roundNumber < noOfRounds; roundNumber++) {
            amounts[roundNumber] = new uint256[](NUMBER_OF_RULING_OPTIONS + 1);

            Round storage round = dispute.rounds[roundNumber];
            for (uint256 rulingOption = 0; rulingOption <= NUMBER_OF_RULING_OPTIONS; rulingOption++) {
                uint256 currentAmount = getWithdrawableAmount(
                    round,
                    _contributor,
                    RulingOptions(rulingOption),
                    finalRuling
                );
                if (currentAmount > 0) {
                    sum += getWithdrawableAmount(round, _contributor, RulingOptions(rulingOption), finalRuling);
                    amounts[roundNumber][rulingOption] = currentAmount;
                }
            }
        }
    }

    /// @notice Returns withdrawable amount for given parameters.
    function getWithdrawableAmount(
        Round storage _round,
        address _contributor,
        RulingOptions _ruling,
        RulingOptions _finalRuling
    ) internal view returns (uint256 amount) {
        RulingOptions givenRuling = RulingOptions(_ruling);

        if (!_round.hasPaid[uint256(givenRuling)]) {
            // Allow to reimburse if funding was unsuccessful for this ruling option.
            amount = _round.contributions[_contributor][uint256(givenRuling)];
        } else {
            // Funding was successful for this ruling option.
            if (_ruling == _finalRuling) {
                // This ruling option is the ultimate winner.
                amount = _round.totalPerRuling[uint256(givenRuling)] > 0
                    ? (_round.contributions[_contributor][uint256(givenRuling)] * _round.totalClaimableAfterExpenses) /
                        _round.totalPerRuling[uint256(givenRuling)]
                    : 0;
            } else if (!_round.hasPaid[uint256(RulingOptions(_finalRuling))]) {
                // The ultimate winner was not funded in this round. Contributions discounting the appeal fee are reimbursed proportionally.
                amount =
                    (_round.contributions[_contributor][uint256(givenRuling)] * _round.totalClaimableAfterExpenses) /
                    (_round.totalPerRuling[uint256(RulingOptions.ChallengeFailed)] +
                        _round.totalPerRuling[uint256(RulingOptions.Debunked)]);
            }
        }
    }

    /// @inheritdoc ITruthPost
    function getRoundInfo(uint256 _disputeID, uint256 _round)
        external
        view
        override
        returns (
            bool[NUMBER_OF_RULING_OPTIONS + 1] memory hasPaid,
            uint256[NUMBER_OF_RULING_OPTIONS + 1] memory totalPerRuling,
            uint256 totalClaimableAfterExpenses
        )
    {
        Round storage round = disputes[_disputeID].rounds[_round];
        return (round.hasPaid, round.totalPerRuling, round.totalClaimableAfterExpenses);
    }

    /// @inheritdoc ITruthPost
    function getLastRoundWinner(uint256 _disputeID) public view override returns (uint256) {
        return ARBITRATOR.currentRuling(_disputeID);
    }

    /// @inheritdoc ITruthPost
    function getAppealPeriod(uint256 _disputeID, RulingOptions _ruling)
        external
        view
        override
        returns (uint256, uint256)
    {
        (uint256 appealWindowStart, uint256 appealWindowEnd) = ARBITRATOR.appealPeriod(_disputeID);
        uint256 loserAppealWindowEnd = appealWindowStart +
            (((appealWindowEnd - appealWindowStart) * LOSER_APPEAL_PERIOD_MULTIPLIER) / MULTIPLIER_DENOMINATOR);

        bool isWinner = RulingOptions(getLastRoundWinner(_disputeID)) == _ruling;
        return isWinner ? (appealWindowStart, appealWindowEnd) : (appealWindowStart, loserAppealWindowEnd);
    }

    /// @inheritdoc ITruthPost
    function getReturnOfInvestmentRatio(RulingOptions _ruling, RulingOptions _lastRoundWinner)
        external
        view
        override
        returns (uint256)
    {
        bool isWinner = _lastRoundWinner == _ruling;
        uint256 DECIMAL_PRECISION = 1000;
        uint256 multiplier = isWinner ? WINNER_STAKE_MULTIPLIER : LOSER_STAKE_MULTIPLIER;
        return (((WINNER_STAKE_MULTIPLIER + LOSER_STAKE_MULTIPLIER + MULTIPLIER_DENOMINATOR) * DECIMAL_PRECISION) /
            (multiplier + MULTIPLIER_DENOMINATOR));
    }

    /// @inheritdoc ITruthPost
    function getAmountRemainsToBeRaised(uint256 _disputeID, RulingOptions _ruling)
        external
        view
        override
        returns (uint256)
    {
        DisputeData storage dispute = disputes[_disputeID];
        uint256 lastRoundIndex = dispute.rounds.length - 1;
        Round storage lastRound = dispute.rounds[lastRoundIndex];

        bool isWinner = RulingOptions(getLastRoundWinner(_disputeID)) == _ruling;
        uint256 multiplier = isWinner ? WINNER_STAKE_MULTIPLIER : LOSER_STAKE_MULTIPLIER;

        uint256 raisedSoFar = lastRound.totalPerRuling[uint256(_ruling)];
        uint256 basicCost = ARBITRATOR.appealCost(_disputeID, categoryToArbitratorExtraData[dispute.articleCategory]);
        uint256 totalCost = basicCost + ((basicCost * (multiplier)) / MULTIPLIER_DENOMINATOR);

        return totalCost - raisedSoFar;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.10;

import "@kleros/erc-792/contracts/IArbitrable.sol";
import "@kleros/erc-792/contracts/IArbitrator.sol";

/** @title An IArbitrator implemetation for testing purposes.
 *  @dev DON'T USE ON PRODUCTION.
 */
contract Arbitrator is IArbitrator {
  address public governor = msg.sender;
  uint256 internal arbitrationPrice = 1_000_000_000_000_000_000;

  struct Dispute {
    IArbitrable arbitrated;
    uint256 appealDeadline;
    uint256 numberOfRulingOptions;
    uint256 ruling;
    DisputeStatus status;
  }

  modifier onlyGovernor() {
    require(msg.sender == governor, "Can only be called by the governor.");
    _;
  }

  Dispute[] public disputes;

  function setArbitrationPrice(uint256 _arbitrationPrice) external onlyGovernor {
    arbitrationPrice = _arbitrationPrice;
  }

  function arbitrationCost(bytes memory) public view override returns (uint256 fee) {
    return arbitrationPrice;
  }

  function appealCost(uint256, bytes memory) public view override returns (uint256 fee) {
    return arbitrationCost("UNUSED");
  }

  function createDispute(uint256 _choices, bytes memory _extraData) public payable override returns (uint256 disputeID) {
    uint256 arbitrationFee = arbitrationCost(_extraData);
    require(msg.value >= arbitrationFee, "Value is less than required arbitration fee.");
    disputes.push(
      Dispute({
        arbitrated: IArbitrable(msg.sender),
        numberOfRulingOptions: _choices,
        ruling: 0,
        status: DisputeStatus.Waiting,
        appealDeadline: 0
      })
    );
    disputeID = disputes.length - 1;
    emit DisputeCreation(disputeID, IArbitrable(msg.sender));
  }

  function giveRuling(
    uint256 _disputeID,
    uint256 _ruling,
    uint256 _appealWindow
  ) external onlyGovernor {
    Dispute storage dispute = disputes[_disputeID];
    require(_ruling <= dispute.numberOfRulingOptions, "Invalid ruling.");
    require(dispute.status == DisputeStatus.Waiting, "The dispute must be waiting for arbitration.");

    dispute.ruling = _ruling;
    dispute.status = DisputeStatus.Appealable;
    dispute.appealDeadline = block.timestamp + _appealWindow;

    emit AppealPossible(_disputeID, dispute.arbitrated);
  }

  function appeal(uint256 _disputeID, bytes memory _extraData) public payable override {
    Dispute storage dispute = disputes[_disputeID];
    uint256 appealFee = appealCost(_disputeID, _extraData);
    require(dispute.status == DisputeStatus.Appealable, "The dispute must be appealable.");
    require(block.timestamp < dispute.appealDeadline, "The appeal must occur before the end of the appeal period.");
    require(msg.value >= appealFee, "Value is less than required appeal fee");

    dispute.appealDeadline = 0;
    dispute.status = DisputeStatus.Waiting;
    emit AppealDecision(_disputeID, IArbitrable(msg.sender));
  }

  function executeRuling(uint256 _disputeID) external {
    Dispute storage dispute = disputes[_disputeID];
    require(dispute.status == DisputeStatus.Appealable, "The dispute must be appealable.");
    require(block.timestamp >= dispute.appealDeadline, "The dispute must be executed after its appeal period has ended.");

    dispute.status = DisputeStatus.Solved;
    dispute.arbitrated.rule(_disputeID, dispute.ruling);
  }

  function disputeStatus(uint256 _disputeID) public view override returns (DisputeStatus status) {
    Dispute storage dispute = disputes[_disputeID];
    if (disputes[_disputeID].status == DisputeStatus.Appealable && block.timestamp >= dispute.appealDeadline)
      // If the appeal period is over, consider it solved even if rule has not been called yet.
      return DisputeStatus.Solved;
    else return disputes[_disputeID].status;
  }

  function currentRuling(uint256 _disputeID) public view override returns (uint256 ruling) {
    return disputes[_disputeID].ruling;
  }

  function appealPeriod(uint256 _disputeID) public view override returns (uint256 start, uint256 end) {
    Dispute storage dispute = disputes[_disputeID];
    return (block.timestamp, dispute.appealDeadline);
  }
}

/**
 * @authors: [@ferittuncer, @hbarcelos]
 * @reviewers: [@remedcu]
 * @auditors: []
 * @bounties: []
 * @deployments: []
 * SPDX-License-Identifier: MIT
 */
pragma solidity ^0.8.0;

import "./IArbitrator.sol";

/**
 * @title IArbitrable
 * Arbitrable interface.
 * When developing arbitrable contracts, we need to:
 * - Define the action taken when a ruling is received by the contract.
 * - Allow dispute creation. For this a function must call arbitrator.createDispute{value: _fee}(_choices,_extraData);
 */
interface IArbitrable {
    /**
     * @dev To be raised when a ruling is given.
     * @param _arbitrator The arbitrator giving the ruling.
     * @param _disputeID ID of the dispute in the Arbitrator contract.
     * @param _ruling The ruling which was given.
     */
    event Ruling(IArbitrator indexed _arbitrator, uint256 indexed _disputeID, uint256 _ruling);

    /**
     * @dev Give a ruling for a dispute. Must be called by the arbitrator.
     * The purpose of this function is to ensure that the address calling it has the right to rule on the contract.
     * @param _disputeID ID of the dispute in the Arbitrator contract.
     * @param _ruling Ruling given by the arbitrator. Note that 0 is reserved for "Not able/wanting to make a decision".
     */
    function rule(uint256 _disputeID, uint256 _ruling) external;
}

/**
 * @authors: [@ferittuncer, @hbarcelos]
 * @reviewers: [@remedcu]
 * @auditors: []
 * @bounties: []
 * @deployments: []
 * SPDX-License-Identifier: MIT
 */

pragma solidity ^0.8.0;

import "./IArbitrable.sol";

/**
 * @title Arbitrator
 * Arbitrator abstract contract.
 * When developing arbitrator contracts we need to:
 * - Define the functions for dispute creation (createDispute) and appeal (appeal). Don't forget to store the arbitrated contract and the disputeID (which should be unique, may nbDisputes).
 * - Define the functions for cost display (arbitrationCost and appealCost).
 * - Allow giving rulings. For this a function must call arbitrable.rule(disputeID, ruling).
 */
interface IArbitrator {
    enum DisputeStatus {
        Waiting,
        Appealable,
        Solved
    }

    /**
     * @dev To be emitted when a dispute is created.
     * @param _disputeID ID of the dispute.
     * @param _arbitrable The contract which created the dispute.
     */
    event DisputeCreation(uint256 indexed _disputeID, IArbitrable indexed _arbitrable);

    /**
     * @dev To be emitted when a dispute can be appealed.
     * @param _disputeID ID of the dispute.
     * @param _arbitrable The contract which created the dispute.
     */
    event AppealPossible(uint256 indexed _disputeID, IArbitrable indexed _arbitrable);

    /**
     * @dev To be emitted when the current ruling is appealed.
     * @param _disputeID ID of the dispute.
     * @param _arbitrable The contract which created the dispute.
     */
    event AppealDecision(uint256 indexed _disputeID, IArbitrable indexed _arbitrable);

    /**
     * @dev Create a dispute. Must be called by the arbitrable contract.
     * Must be paid at least arbitrationCost(_extraData).
     * @param _choices Amount of choices the arbitrator can make in this dispute.
     * @param _extraData Can be used to give additional info on the dispute to be created.
     * @return disputeID ID of the dispute created.
     */
    function createDispute(uint256 _choices, bytes calldata _extraData) external payable returns (uint256 disputeID);

    /**
     * @dev Compute the cost of arbitration. It is recommended not to increase it often, as it can be highly time and gas consuming for the arbitrated contracts to cope with fee augmentation.
     * @param _extraData Can be used to give additional info on the dispute to be created.
     * @return cost Amount to be paid.
     */
    function arbitrationCost(bytes calldata _extraData) external view returns (uint256 cost);

    /**
     * @dev Appeal a ruling. Note that it has to be called before the arbitrator contract calls rule.
     * @param _disputeID ID of the dispute to be appealed.
     * @param _extraData Can be used to give extra info on the appeal.
     */
    function appeal(uint256 _disputeID, bytes calldata _extraData) external payable;

    /**
     * @dev Compute the cost of appeal. It is recommended not to increase it often, as it can be higly time and gas consuming for the arbitrated contracts to cope with fee augmentation.
     * @param _disputeID ID of the dispute to be appealed.
     * @param _extraData Can be used to give additional info on the dispute to be created.
     * @return cost Amount to be paid.
     */
    function appealCost(uint256 _disputeID, bytes calldata _extraData) external view returns (uint256 cost);

    /**
     * @dev Compute the start and end of the dispute's current or next appeal period, if possible. If not known or appeal is impossible: should return (0, 0).
     * @param _disputeID ID of the dispute.
     * @return start The start of the period.
     * @return end The end of the period.
     */
    function appealPeriod(uint256 _disputeID) external view returns (uint256 start, uint256 end);

    /**
     * @dev Return the status of a dispute.
     * @param _disputeID ID of the dispute to rule.
     * @return status The status of the dispute.
     */
    function disputeStatus(uint256 _disputeID) external view returns (DisputeStatus status);

    /**
     * @dev Return the current ruling of a dispute. This is useful for parties to know if they should appeal.
     * @param _disputeID ID of the dispute.
     * @return ruling The ruling which has been given or the one which will be given if there is no appeal.
     */
    function currentRuling(uint256 _disputeID) external view returns (uint256 ruling);
}

/**
 * @authors: [@ferittuncer, @hbarcelos]
 * @reviewers: []
 * @auditors: []
 * @bounties: []
 * @deployments: []
 * SPDX-License-Identifier: MIT
 */
pragma solidity ^0.8.0;

import "../IArbitrator.sol";

/** @title IEvidence
 *  ERC-1497: Evidence Standard
 */
interface IEvidence {
    /**
     * @dev To be emitted when meta-evidence is submitted.
     * @param _metaEvidenceID Unique identifier of meta-evidence.
     * @param _evidence IPFS path to metaevidence, example: '/ipfs/Qmarwkf7C9RuzDEJNnarT3WZ7kem5bk8DZAzx78acJjMFH/metaevidence.json'
     */
    event MetaEvidence(uint256 indexed _metaEvidenceID, string _evidence);

    /**
     * @dev To be raised when evidence is submitted. Should point to the resource (evidences are not to be stored on chain due to gas considerations).
     * @param _arbitrator The arbitrator of the contract.
     * @param _evidenceGroupID Unique identifier of the evidence group the evidence belongs to.
     * @param _party The address of the party submiting the evidence. Note that 0x0 refers to evidence not submitted by any party.
     * @param _evidence IPFS path to evidence, example: '/ipfs/Qmarwkf7C9RuzDEJNnarT3WZ7kem5bk8DZAzx78acJjMFH/evidence.json'
     */
    event Evidence(
        IArbitrator indexed _arbitrator,
        uint256 indexed _evidenceGroupID,
        address indexed _party,
        string _evidence
    );

    /**
     * @dev To be emitted when a dispute is created to link the correct meta-evidence to the disputeID.
     * @param _arbitrator The arbitrator of the contract.
     * @param _disputeID ID of the dispute in the Arbitrator contract.
     * @param _metaEvidenceID Unique identifier of meta-evidence.
     * @param _evidenceGroupID Unique identifier of the evidence group that is linked to this dispute.
     */
    event Dispute(
        IArbitrator indexed _arbitrator,
        uint256 indexed _disputeID,
        uint256 _metaEvidenceID,
        uint256 _evidenceGroupID
    );
}

// SPDX-License-Identifier: MIT

/**
 *  @authors: [@ferittuncer]
 *  @reviewers: [@mtsalenc*, @hbarcelos*, @unknownunknown1, @MerlinEgalite, @fnanni-0*, @shalzz]
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity ^0.8.0;

import "@kleros/erc-792/contracts/IArbitrable.sol";
import "@kleros/erc-792/contracts/erc-1497/IEvidence.sol";
import "@kleros/erc-792/contracts/IArbitrator.sol";

/**
 *  @title This serves as a standard interface for crowdfunded appeals and evidence submission, which aren't a part of the arbitration (erc-792 and erc-1497) standard yet.
    This interface is used in Dispute Resolver (resolve.kleros.io).
 */
abstract contract IDisputeResolver is IArbitrable, IEvidence {
    string public constant VERSION = "2.0.0"; // Can be used to distinguish between multiple deployed versions, if necessary.

    /** @dev Raised when a contribution is made, inside fundAppeal function.
     *  @param _localDisputeID Identifier of a dispute in scope of arbitrable contract. Arbitrator ids can be translated to local ids via externalIDtoLocalID.
     *  @param _round The round number the contribution was made to.
     *  @param ruling Indicates the ruling option which got the contribution.
     *  @param _contributor Caller of fundAppeal function.
     *  @param _amount Contribution amount.
     */
    event Contribution(uint256 indexed _localDisputeID, uint256 indexed _round, uint256 ruling, address indexed _contributor, uint256 _amount);

    /** @dev Raised when a contributor withdraws non-zero value.
     *  @param _localDisputeID Identifier of a dispute in scope of arbitrable contract. Arbitrator ids can be translated to local ids via externalIDtoLocalID.
     *  @param _round The round number the withdrawal was made from.
     *  @param _ruling Indicates the ruling option which contributor gets rewards from.
     *  @param _contributor The beneficiary of withdrawal.
     *  @param _reward Total amount of withdrawal, consists of reimbursed deposits plus rewards.
     */
    event Withdrawal(uint256 indexed _localDisputeID, uint256 indexed _round, uint256 _ruling, address indexed _contributor, uint256 _reward);

    /** @dev To be raised when a ruling option is fully funded for appeal.
     *  @param _localDisputeID Identifier of a dispute in scope of arbitrable contract. Arbitrator ids can be translated to local ids via externalIDtoLocalID.
     *  @param _round Number of the round this ruling option was fully funded in.
     *  @param _ruling The ruling option which just got fully funded.
     */
    event RulingFunded(uint256 indexed _localDisputeID, uint256 indexed _round, uint256 indexed _ruling);

    /** @dev Maps external (arbitrator side) dispute id to local (arbitrable) dispute id.
     *  @param _externalDisputeID Dispute id as in arbitrator contract.
     *  @return localDisputeID Dispute id as in arbitrable contract.
     */
    function externalIDtoLocalID(uint256 _externalDisputeID) external virtual returns (uint256 localDisputeID);

    /** @dev Returns number of possible ruling options. Valid rulings are [0, return value].
     *  @param _localDisputeID Identifier of a dispute in scope of arbitrable contract. Arbitrator ids can be translated to local ids via externalIDtoLocalID.
     *  @return count The number of ruling options.
     */
    function numberOfRulingOptions(uint256 _localDisputeID) external view virtual returns (uint256 count);

    /** @dev Allows to submit evidence for a given dispute.
     *  @param _localDisputeID Identifier of a dispute in scope of arbitrable contract. Arbitrator ids can be translated to local ids via externalIDtoLocalID.
     *  @param _evidenceURI IPFS path to evidence, example: '/ipfs/Qmarwkf7C9RuzDEJNnarT3WZ7kem5bk8DZAzx78acJjMFH/evidence.json'
     */
    function submitEvidence(uint256 _localDisputeID, string calldata _evidenceURI) external virtual;

    /** @dev Manages contributions and calls appeal function of the specified arbitrator to appeal a dispute. This function lets appeals be crowdfunded.
     *  @param _localDisputeID Identifier of a dispute in scope of arbitrable contract. Arbitrator ids can be translated to local ids via externalIDtoLocalID.
     *  @param _ruling The ruling option to which the caller wants to contribute.
     *  @return fullyFunded True if the ruling option got fully funded as a result of this contribution.
     */
    function fundAppeal(uint256 _localDisputeID, uint256 _ruling) external payable virtual returns (bool fullyFunded);

    /** @dev Returns appeal multipliers.
     *  @return winnerStakeMultiplier Winners stake multiplier.
     *  @return loserStakeMultiplier Losers stake multiplier.
     *  @return loserAppealPeriodMultiplier Losers appeal period multiplier. The loser is given less time to fund its appeal to defend against last minute appeal funding attacks.
     *  @return denominator Multiplier denominator in basis points.
     */
    function getMultipliers()
        external
        view
        virtual
        returns (
            uint256 winnerStakeMultiplier,
            uint256 loserStakeMultiplier,
            uint256 loserAppealPeriodMultiplier,
            uint256 denominator
        );

    /** @dev Allows to withdraw any reimbursable fees or rewards after the dispute gets resolved.
     *  @param _localDisputeID Identifier of a dispute in scope of arbitrable contract. Arbitrator ids can be translated to local ids via externalIDtoLocalID.
     *  @param _contributor Beneficiary of withdraw operation.
     *  @param _round Number of the round that caller wants to execute withdraw on.
     *  @param _ruling A ruling option that caller wants to execute withdraw on.
     *  @return sum The amount that is going to be transferred to contributor as a result of this function call.
     */
    function withdrawFeesAndRewards(
        uint256 _localDisputeID,
        address payable _contributor,
        uint256 _round,
        uint256 _ruling
    ) external virtual returns (uint256 sum);

    /** @dev Allows to withdraw any rewards or reimbursable fees after the dispute gets resolved for all rounds at once.
     *  @param _localDisputeID Identifier of a dispute in scope of arbitrable contract. Arbitrator ids can be translated to local ids via externalIDtoLocalID.
     *  @param _contributor Beneficiary of withdraw operation.
     *  @param _ruling Ruling option that caller wants to execute withdraw on.
     */
    function withdrawFeesAndRewardsForAllRounds(
        uint256 _localDisputeID,
        address payable _contributor,
        uint256 _ruling
    ) external virtual;

    /** @dev Returns the sum of withdrawable amount.
     *  @param _localDisputeID Identifier of a dispute in scope of arbitrable contract. Arbitrator ids can be translated to local ids via externalIDtoLocalID.
     *  @param _contributor Beneficiary of withdraw operation.
     *  @param _ruling Ruling option that caller wants to get withdrawable amount from.
     *  @return sum The total amount available to withdraw.
     */
    function getTotalWithdrawableAmount(
        uint256 _localDisputeID,
        address payable _contributor,
        uint256 _ruling
    ) external view virtual returns (uint256 sum);
}

/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

/// @title  The Truth Post: Accurate and Relevant News
/// @author https://github.com/proveuswrong<0xferit, gratestas>
/// @dev    This contract serves as a standard interface among multiple deployments of the Truth Post contracts.
///         You should target this interface contract for interactions, not the concrete contract; otherwise you risk incompatibility across versions.
/// @custom:approvals 0xferit, gratestas
abstract contract ITruthPost {
    string public constant VERSION = "1.2.0";

    enum RulingOptions {
        Tied,
        ChallengeFailed,
        Debunked
    }

    bool isPublishingEnabled = true;
    address payable public TREASURY;
    uint256 public treasuryBalance;
    uint256 public constant NUMBER_OF_RULING_OPTIONS = 2;
    uint256 public constant MULTIPLIER_DENOMINATOR = 1024; // Denominator for multipliers.
    uint256 public LOSER_APPEAL_PERIOD_MULTIPLIER = 512; // Multiplier of the appeal period for losers (any other ruling options) in basis points. The loser is given less time to fund its appeal to defend against last minute appeal funding attacks.
    uint256 public ARTICLE_WITHDRAWAL_TIMELOCK; // To prevent authors to act fast and escape punishment.
    uint256 public WINNER_STAKE_MULTIPLIER; // Multiplier of the arbitration cost that the winner has to pay as fee stake for a round in basis points.
    uint256 public LOSER_STAKE_MULTIPLIER; // Multiplier of the arbitration cost that the loser has to pay as fee stake for a round in basis points.
    uint256 public challengeTaxRate = 16;

    constructor(
        uint256 _articleWithdrawalTimelock,
        uint256 _winnerStakeMultiplier,
        uint256 _loserStakeMultiplier,
        address payable _treasury
    ) {
        ARTICLE_WITHDRAWAL_TIMELOCK = _articleWithdrawalTimelock;
        WINNER_STAKE_MULTIPLIER = _winnerStakeMultiplier;
        LOSER_STAKE_MULTIPLIER = _loserStakeMultiplier;
        TREASURY = _treasury;
    }

    event NewArticle(string articleID, uint8 category, uint256 articleAddress);
    event Debunked(uint256 articleAddress);
    event ArticleWithdrawn(uint256 articleAddress);
    event BalanceUpdate(uint256 articleAddress, uint256 newTotal);
    event TimelockStarted(uint256 articleAddress);
    event Challenge(uint256 indexed articleAddress, address challanger, uint256 disputeID);
    event Contribution(
        uint256 indexed disputeId,
        uint256 indexed round,
        RulingOptions ruling,
        address indexed contributor,
        uint256 amount
    );
    event Withdrawal(
        uint256 indexed disputeId,
        uint256 indexed round,
        RulingOptions ruling,
        address indexed contributor,
        uint256 reward
    );
    event RulingFunded(uint256 indexed disputeId, uint256 indexed round, RulingOptions indexed ruling);
    event OwnershipTransfer(address indexed _newOwner);
    event AdminUpdate(address indexed _newAdmin);
    event WinnerStakeMultiplierUpdate(uint256 indexed _newWinnerStakeMultiplier);
    event LoserStakeMultiplierUpdate(uint256 indexed _newLoserStakeMultiplier);
    event LoserAppealPeriodMultiplierUpdate(uint256 indexed _newLoserAppealPeriodMultiplier);
    event ArticleWithdrawalTimelockUpdate(uint256 indexed _newWithdrawalTimelock);
    event ChallengeTaxRateUpdate(uint256 indexed _newTaxRate);
    event TreasuryUpdate(address indexed _newTreasury);
    event TreasuryBalanceUpdate(uint256 indexed _byAmount);


    /// @notice Submit an evidence.
    /// @param _disputeID The dispute ID as in arbitrator.
    /// @param _evidenceURI IPFS path to evidence, example: '/ipfs/Qmarwkf7C9RuzDEJNnarT3WZ7kem5bk8DZAzx78acJjMFH/evidence.json'
    function submitEvidence(uint256 _disputeID, string calldata _evidenceURI) external virtual;

    /// @notice Fund a crowdfunding appeal.
    /// @dev Lets user to contribute funding of an appeal round. Emits Contribution. If fully funded, emits RulingFunded.
    /// @param _disputeID The dispute ID as in arbitrator.
    /// @param _ruling The ruling option to which the caller wants to contribute.
    /// @return fullyFunded True if the ruling option got fully funded as a result of this contribution.
    function fundAppeal(uint256 _disputeID, RulingOptions _ruling) external payable virtual returns (bool fullyFunded);

    /// @notice Publish an article.
    /// @dev    Do not confuse articleID with articleAddress. Emits NewArticle.
    /// @param _articleID Unique identifier of an article in IPFS content identifier format.
    /// @param _category The category code of this new article.
    /// @param _searchPointer Starting point of the search. Find a vacant storage slot before calling this function to minimize gas cost.
    function initializeArticle(
        string calldata _articleID,
        uint8 _category,
        uint80 _searchPointer
    ) external payable virtual;

    /// @notice Increase bounty.
    /// @dev Lets author to increase a bounty of a live article. Emits BalanceUpdate.
    /// @param _articleStorageAddress The address of the article in the storage.
    function increaseBounty(uint80 _articleStorageAddress) external payable virtual;

    /// @notice Initiate unpublishing process.
    /// @dev Lets an author to start unpublishing process. Emits TimelockStarted.
    /// @param _articleStorageAddress The address of the article in the storage.
    function initiateWithdrawal(uint80 _articleStorageAddress) external virtual;

    /// @notice Execute unpublishing.
    /// @dev Executes unpublishing of an article. Emits Withdrew.
    /// @param _articleStorageAddress The address of the article in the storage.
    function withdraw(uint80 _articleStorageAddress) external virtual;

    /// @notice Challenge article.
    /// @dev Challenges the article at the given storage address. Emits Challenge.
    /// @param _articleStorageAddress The address of the article in the storage.
    function challenge(uint80 _articleStorageAddress) external payable virtual;

    /// @notice Transfer ownership of an article.
    /// @dev Lets you to transfer ownership of an article. 
    ///      This is useful when you want to change owner account without withdrawing and resubmitting. 
    ///      Emits OwnershipTransfer.
    /// @param _articleStorageAddress The address of article in the storage.
    /// @param _newOwner The new owner of the article which resides in the storage address, provided by the previous parameter.
    function transferOwnership(uint80 _articleStorageAddress, address payable _newOwner) external virtual;

    /// @notice Update the arbitration cost for the winner.
    /// @dev Sets the multiplier of the arbitration cost that the winner has to pay as fee stake to a new value. 
    ///      Emits WinnerStakeMultiplierUpdate.
    /// @param _newWinnerStakeMultiplier The new value of WINNER_STAKE_MULTIPLIER.
    function changeWinnerStakeMultiplier(uint256 _newWinnerStakeMultiplier) external virtual;

    /// @notice Update the arbitration cost for the loser.
    /// @dev Sets the multiplier of the arbitration cost that the loser has to pay as fee stake to a new value. 
    ///      Emits LoserStakeMultiplierUpdate.
    /// @param _newLoserStakeMultiplier The new value of LOSER_STAKE_MULTIPLIER.
    
    function changeLoserStakeMultiplier(uint256 _newLoserStakeMultiplier) external virtual;

    /// @notice Update the appeal window for the loser.
    /// @dev Sets the multiplier of the appeal window for the loser to a new value. Emits LoserAppealPeriodMultiplierUpdate.
    /// @param _newLoserAppealPeriodMultiplier The new value of LOSER_APPEAL_PERIOD_MULTIPLIER.
    function changeLoserAppealPeriodMultiplier(uint256 _newLoserAppealPeriodMultiplier) external virtual;

    /// @notice Update the timelock for the article withdtrawal.
    /// @dev Sets the timelock before an author can initiate the withdrawal of an article to a new value. 
    ///      Emits ArticleWithdrawalTimelockUpdate.
    /// @param _newArticleWithdrawalTimelock The new value of ARTICLE_WITHDRAWAL_TIMELOCK.
    function changeArticleWithdrawalTimelock(uint256 _newArticleWithdrawalTimelock) external virtual;

    /// @notice Find a vacant storage slot for an article.
    /// @dev Helper function to find a vacant slot for article. Use this function before calling initialize to minimize your gas cost.
    /// @param _searchPointer Starting point of the search. If you do not have a guess, just pass 0.
    function findVacantStorageSlot(uint80 _searchPointer) external view virtual returns (uint256 vacantSlotIndex);

    /// @notice Get required challenge fee.
    /// @dev Returns the total amount needs to be paid to challenge an article, including taxes if any.
    /// @param _articleStorageAddress The address of article in the storage.
    function challengeFee(uint80 _articleStorageAddress) public view virtual returns (uint256 challengeFee);

    /// @notice Get required appeal fee and deposit.
    /// @dev Returns the total amount needs to be paid to appeal a dispute, including fees and stake deposit.
    /// @param _disputeID ID of the dispute as in arbitrator.
    function appealFee(uint256 _disputeID) external view virtual returns (uint256 arbitrationFee);

    /// @notice Withdraw appeal crowdfunding balance.
    /// @dev Allows to withdraw any reimbursable fees or rewards after the dispute gets resolved.
    /// @param _disputeID The dispute ID as in arbitrator.
    /// @param _contributor Beneficiary of withdraw operation.
    /// @param _round Number of the round that caller wants to execute withdraw on.
    /// @param _ruling A ruling option that caller wants to execute withdraw on.
    /// @return sum The amount that is going to be transferred to contributor as a result of this function call.
    function withdrawFeesAndRewards(
        uint256 _disputeID,
        address payable _contributor,
        uint256 _round,
        RulingOptions _ruling
    ) external virtual returns (uint256 sum);

    /// @notice Withdraw appeal crowdfunding balance for given ruling option for all rounds.
    /// @dev Allows to withdraw any rewards or reimbursable fees after the dispute gets resolved for all rounds at once.
    /// @param _disputeID The dispute ID as in arbitrator.
    /// @param _contributor Beneficiary of withdraw operation.
    /// @param _ruling Ruling option that caller wants to execute withdraw on.
    function withdrawFeesAndRewardsForAllRounds(
        uint256 _disputeID,
        address payable _contributor,
        RulingOptions _ruling
    ) external virtual;

    /// @notice Withdraw appeal crowdfunding balance for given ruling option and for given rounds.
    /// @dev Allows to withdraw any rewards or reimbursable fees after the dispute gets resolved for given positions at once.
    /// @param _disputeID The dispute ID as in arbitrator.
    /// @param _contributor Beneficiary of withdraw operation.
    /// @param positions [rounds][rulings].
    function withdrawFeesAndRewardsForGivenPositions(
        uint256 _disputeID,
        address payable _contributor,
        uint256[][] calldata positions
    ) external virtual;

    /// @notice Withdraw appeal crowdfunding balance for all ruling options and all rounds.
    /// @dev Allows to withdraw any rewards or reimbursable fees after the dispute gets resolved for all rounds and all rulings at once.
    /// @param _disputeID The dispute ID as in arbitrator.
    /// @param _contributor Beneficiary of withdraw operation.
    function withdrawFeesAndRewardsForAllRoundsAndAllRulings(uint256 _disputeID, address payable _contributor)
        external
        virtual;

    /// @notice Learn the total amount of appeal crowdfunding balance available.
    /// @dev Returns the sum of withdrawable amount and 2D array of positions[round][ruling].
    /// @param _disputeID The dispute ID as in arbitrator.
    /// @param _contributor Beneficiary of withdraw operation.
    /// @return sum The total amount available to withdraw.
    function getTotalWithdrawableAmount(uint256 _disputeID, address payable _contributor)
        external
        view
        virtual
        returns (uint256 sum, uint256[][] memory positions);

    /// @notice Learn about given dispute round.
    /// @param _disputeID The dispute ID as in arbitrator.
    /// @param _round Round ID.
    /// @return hasPaid Whether given ruling option was fully funded.
    /// @return totalPerRuling The total raised per ruling option.
    /// @return totalClaimableAfterExpenses Total amount will be distributed back to winners, after deducting expenses.
    function getRoundInfo(uint256 _disputeID, uint256 _round)
        external
        view
        virtual
        returns (
            bool[NUMBER_OF_RULING_OPTIONS + 1] memory hasPaid,
            uint256[NUMBER_OF_RULING_OPTIONS + 1] memory totalPerRuling,
            uint256 totalClaimableAfterExpenses
        );

    /// @notice Learn about how much more needs to be raised for given ruling option.
    /// @param _disputeID The dispute ID as in arbitrator.
    /// @param _ruling The ruling option to query.
    /// @return Amount needs to be raised
    function getAmountRemainsToBeRaised(uint256 _disputeID, RulingOptions _ruling)
        external
        view
        virtual
        returns (uint256);

    /// @notice Get return of investment ratio.
    /// @dev Purely depends on whether given ruling option is winner and stake multipliers.
    /// @param _ruling The ruling option to query.
    /// @param _lastRoundWinner Winner of the last round.
    /// @return Return of investment ratio, denominated by MULTIPLIER_DENOMINATOR.
    function getReturnOfInvestmentRatio(RulingOptions _ruling, RulingOptions _lastRoundWinner)
        external
        view
        virtual
        returns (uint256);

    /// @notice Get appeal time window.
    /// @param _disputeID The dispute ID as in arbitrator.
    /// @param _ruling The ruling option to query.
    /// @return Start
    /// @return End
    function getAppealPeriod(uint256 _disputeID, RulingOptions _ruling)
        external
        view
        virtual
        returns (uint256, uint256);

    /// @notice Get last round's winner.
    /// @param _disputeID The dispute ID as in arbitrator.
    /// @return Winning ruling option.
    function getLastRoundWinner(uint256 _disputeID) public view virtual returns (uint256);

    /// @notice Switches publishing lock.
    /// @dev    Useful when it's no longer safe or secure to use this contract.
    ///         Prevents new articles to be published. Only intended for privileges users.
    function switchPublishingLock() public virtual;
}