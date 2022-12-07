// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "../governance/VCGovernance.sol";
import "../interfaces/IVCStarter.sol";
import "./VCCampaign.sol";

// import "../starter/VCStarter.sol";

enum CampaignStatus {
    ACTIVE,
    FAILED,
    DEFEATED,
    SUCCEEDED
}

struct CampaignData {
    uint256 id;
    bool closed;
    address campaign;
    uint256 target;
    uint256 maturity;
    uint256 maxTarget;
    CampaignStatus status;
    SalvagePoll salvagePoll;
}

enum SalvagePollStatus {
    INACTIVE,
    ACTIVE,
    REJECTED,
    EXTENDED,
    SETTLED
}

struct SalvagePoll {
    // bool launched;         // if already launched
    uint256 campaignDuration; // extended Campaign duration
    uint256 duration; // poll duration
    uint256 maturity; // pool maturity
    uint256 quorum;
    uint256 votersCount;
    uint256 settleCount;
    uint256 extendCount;
    uint256 rejectCount;
    SalvagePollStatus status;
}

enum SalvagePollVoteType {
    UNSET,
    REJECT,
    EXTEND,
    SETTLE
}

// struct SalvagePollVote {
//     uint256 votePower;
//     SalvagePollVoteType voteType;
// }

error ProjectCampaignAlreadyClosed();
error ProjectCampaignAlreadyFinished();
error ProjectCampaignAlreadyFailed();
error ProjectCampaignAlreadyDefeated();

// FIXME: should be renamed to Project at the beginning instead of SalvagePoll
error SalvagePollTransferToVCPoolFailed(); // not used
error SalvagePollCampaignHasOpenedSalvagePoll();
error SalvagePollCampaignStillActive();
error SalvagePollTransferLabFailed(); // not used
error SalvagePollNotActive();
error SalvagePollTransferVCPoolFailed(); // not used
error SalvagePollTransferFromMarketFailed(); // not used
error SalvagePollInvalidVoter();
error SalvagePollCanNotBeClosed();
error SalvagePollSalvagePollCreated();
error SalvagePollHasExpired();

contract VCProject is Initializable {
    address public lab;
    address public starter;
    address public admin;
    uint256 public marketplaceFunding;

    /// @notice Maps Campaign identifiers and accounts to their SalvagePollsVoteType struct
    mapping(uint256 => mapping(address => SalvagePollVoteType)) private _votes;

    /// @notice An array of all project Campaigns
    CampaignData[] private _campaigns;

    modifier onlyStarter() {
        require(msg.sender == starter, "PROJECT: Function can only be called by starter");
        _;
    }

    // NOT USED
    // modifier allowedVoter(uint256 _campaignId, address _voter) {
    //     address[] memory voters = _campaigns[_campaignId].salvagePoll.voters;
    //     bool isAllowed = false;
    //     bool hasVoted = false;
    //     for (uint256 i = 0; i < voters.length; i++) {
    //         if (voters[i] == _voter) {
    //             isAllowed = true;
    //             hasVoted = _votes[_campaignId][_voter].voteType == SalvagePollVoteType.UNSET;
    //             break;
    //         }
    //     }
    //     require(isAllowed, "STARTER: Sender has not backed this campaign");
    //     require(!hasVoted, "STARTER: Sender has already voted");
    //     _;
    // }

    modifier validVote(uint256 _campaignId, SalvagePollVoteType _voteType) {
        CampaignData memory campaignData = _campaigns[_campaignId];
        uint256 totalFunding = VCCampaign(campaignData.campaign).totalFunding();
        require(
            _voteType != SalvagePollVoteType.SETTLE || totalFunding > (campaignData.target * 70) / 100,
            "STARTER: Cannot settle if campaign has not raised >70% of target"
        );
        _;
    }

    constructor() {}

    function init(
        address _starter,
        address _admin,
        address _lab
    ) public initializer {
        starter = _starter;
        admin = _admin;
        lab = _lab;
    }

    // FIXME: how do we claim this funds?
    function increaseMarketplaceFunding(uint256 _amount) external onlyStarter {
        marketplaceFunding += _amount;
    }

    /**
     * @notice Refer to VCStarter `createCampaign` documentation.
     */
    function createCampaign(
        address _campaign,
        uint256 _target,
        uint256 _stretchInBips,
        uint256 _duration,
        uint256 _maxPollDuration,
        uint256 _pollQuorum
    ) external onlyStarter returns (uint256) {
        CampaignData memory campaignData = CampaignData({
            id: _campaigns.length,
            closed: false,
            campaign: _campaign,
            target: _target,
            maturity: block.timestamp + _duration,
            maxTarget: _target + (_target * _stretchInBips) / 10000,
            status: CampaignStatus.ACTIVE,
            salvagePoll: SalvagePoll(0, _maxPollDuration, 0, _pollQuorum, 0, 0, 0, 0, SalvagePollStatus.INACTIVE)
        });

        _campaigns.push(campaignData);

        return campaignData.id;
    }

    /**
     * @notice Computes the Campaign status based on its donated amount and
     * maturity.
     *
     * @dev ACTIVE iff maxTarget has not been reached within duration.
     * @dev SUCCEEDED iff maxTarget has been reached within duration
     * or target has been reached after maturity.
     * @dev FAILED iff target has not been reached after duration.
     * @dev A DEFEATED campaign remains DEFEATED.
     *
     * @param _campaign Campaign to update status
     */
    function _updateCampaignStatus(CampaignData memory _campaign) internal {
        if (_campaign.closed || _campaign.status == CampaignStatus.DEFEATED) {
            return;
        }

        uint256 campaignTotalFunding = VCCampaign(_campaign.campaign).totalFunding();

        if (campaignTotalFunding < _campaign.target) {
            if (block.timestamp < _campaign.maturity) {
                _campaign.status = CampaignStatus.ACTIVE;
            } else {
                _campaign.status = CampaignStatus.FAILED;
            }
        } else if (campaignTotalFunding < _campaign.maxTarget) {
            if (block.timestamp < _campaign.maturity) {
                _campaign.status = CampaignStatus.ACTIVE;
            } else {
                _campaign.status = CampaignStatus.SUCCEEDED;
            }
        } else {
            _campaign.status = CampaignStatus.SUCCEEDED;
        }

        _campaigns[_campaign.id] = _campaign;
    }

    /**
     * @notice Refer to VCStarter `fundCampaign` documentation.
     */
    function fundCampaign(
        uint256 _campaignId,
        address _donor,
        uint256 _amount
    ) external {
        CampaignData memory campaignData = _campaigns[_campaignId];

        // FIXME: here we are updating in memory and then checking in before fund something
        // that has not been updated!
        _updateCampaignStatus(campaignData);

        _checkBeforeFund(campaignData);

        VCCampaign(campaignData.campaign).fund(_donor, _amount);
    }

    // FIXME: this function should not be named closeCampaign, as it can not close a Campaign and
    // start a salvage poll instead!
    // FIXME: Once a salvage poll fails again, here we can start a new Salvage poll, we should avoid that
    /**
     * @notice Refer to VCStarter `closeCampaign` documentation.
     */
    function closeCampaign(
        uint256 _campaignId,
        bool _ifFailDefeated,
        uint256 _duration // the extended funding time period
    ) external onlyStarter {
        CampaignData memory campaignData = _checkBeforeCloseCampaign(_campaignId);
        VCCampaign campaign = VCCampaign(campaignData.campaign);

        if (campaignData.status == CampaignStatus.FAILED) {
            if (_ifFailDefeated) {
                campaignData.status = CampaignStatus.DEFEATED;
                campaign.onCampaignDefeated();
                campaignData.closed = true;
            } else {
                // NOTE: Users will be locked here, they are not able to mintNFT nor withdraw, salvage poll is available, but what happens if there is no
                // salvage poll? i propose that the salvage poll is created here automatically, the lab has the decision since the can specify `failIfDefeated`
                // for that i will make public `startSalvagePoll` but this is just to avoid compiling errors i think there is no need, it should be internal
                // and if required called automatically by this function (and delete it from Starter)
                if (campaignData.salvagePoll.status == SalvagePollStatus.ACTIVE) {
                    revert SalvagePollSalvagePollCreated();
                }

                // if (campaignData.salvagePoll.launched) {
                //     revert SalvagePollSalvagePollCreated();
                // }

                startSalvagePoll(_campaignId, _duration);
            }
        } else {
            uint256 campaignTotalFunding = campaign.totalFunding();
            campaign.onCampaignSucceeded(
                campaignTotalFunding > campaignData.target ? campaignTotalFunding - campaignData.target : 0
            );
            campaignData.closed = true;
        }
        _campaigns[_campaignId] = campaignData;
    }

    function withdrawOnCampaignDefeated(uint256 _campaignId, address _user) public onlyStarter returns (bool) {
        CampaignData memory campaignData = _campaigns[_campaignId];

        if (campaignData.status != CampaignStatus.DEFEATED) {
            revert();
        }
        VCCampaign campaign = VCCampaign(campaignData.campaign);
        if (!campaign.withdrawOnCampaignDefeated(_user)) {
            return false;
        }
        return true;
    }

    /**
     * @notice Refer to VCStarter `startSalvagePoll` documentation.
     */
    function startSalvagePoll(uint256 _campaignId, uint256 _duration) public {
        CampaignData memory campaignData = _campaigns[_campaignId];

        if (campaignData.closed) {
            revert ProjectCampaignAlreadyClosed();
        }

        _updateCampaignStatus(campaignData);

        require(
            campaignData.status == CampaignStatus.FAILED,
            "STARTER: Only failed campaigns can start a salvage poll"
        );

        // Funding[] memory fundings = Escrow(campaign.campaign).getFundings();
        // for (uint256 i = 0; i < fundings.length; i++) {
        //     campaign.salvagePoll.voters.push(fundings[i].funder);
        // }

        campaignData.salvagePoll.status = SalvagePollStatus.ACTIVE;
        campaignData.salvagePoll.campaignDuration = _duration;
        campaignData.salvagePoll.maturity = block.timestamp + campaignData.salvagePoll.duration;
        _campaigns[_campaignId] = campaignData;
    }

    /**
     * @notice Refer to VCStarter `voteSalvagePoll` documentation.
     */
    function voteSalvagePoll(
        uint256 _campaignId,
        address _voter,
        uint256 _votePower,
        SalvagePollVoteType _voteType
    ) external validVote(_campaignId, _voteType) onlyStarter {
        CampaignData memory campaignData = _campaigns[_campaignId];

        _checkBeforeVoteSalvagePoll(campaignData, _campaignId, _voter);

        campaignData.salvagePoll.votersCount++;

        // _votes[_campaignId][_voter].votePower = _votePower;
        _votes[_campaignId][_voter] = _voteType;
        if (_voteType == SalvagePollVoteType.SETTLE) {
            campaignData.salvagePoll.settleCount += _votePower;
        } else if (_voteType == SalvagePollVoteType.EXTEND) {
            campaignData.salvagePoll.extendCount += _votePower;
        } else {
            campaignData.salvagePoll.rejectCount += _votePower;
        }

        _campaigns[_campaignId] = campaignData;
    }

    // TODO: Add test cases for this function
    /**
     * @notice Refer to VCStarter `closeSalvagePoll` documentation.
     */
    function closeSalvagePoll(uint256 _campaignId, uint256 _quorum) external onlyStarter {
        CampaignData memory campaignData = _campaigns[_campaignId];

        _checkBeforeCloseSalvagePoll(campaignData, _quorum);

        (SalvagePollStatus pollStatus, CampaignStatus campaignStatus) = _getStatusFromSalvagePoll(
            campaignData.salvagePoll
        );

        campaignData.salvagePoll.status = pollStatus;
        campaignData.status = campaignStatus;

        VCCampaign campaign = VCCampaign(campaignData.campaign);
        if (pollStatus == SalvagePollStatus.EXTENDED) {
            campaignData.maturity = block.timestamp + campaignData.salvagePoll.campaignDuration;
        } else if (pollStatus == SalvagePollStatus.REJECTED) {
            // if the Poll status is REJECTED we allow the users to withdraw their USDC
            campaign.onCampaignDefeated();
            campaignData.closed = true;
        } else {
            campaign.onCampaignSucceeded(0);
            campaignData.closed = true;
        }
        _campaigns[_campaignId] = campaignData;
    }

    function _checkBeforeFund(CampaignData memory campaignData) private pure {
        if (campaignData.closed) {
            revert ProjectCampaignAlreadyClosed();
        }
        if (campaignData.status == CampaignStatus.SUCCEEDED) {
            revert ProjectCampaignAlreadyFinished();
        }
        if (campaignData.status == CampaignStatus.DEFEATED) {
            revert ProjectCampaignAlreadyDefeated();
        }
        if (campaignData.status == CampaignStatus.FAILED) {
            revert ProjectCampaignAlreadyFailed();
        }
    }

    function _checkBeforeCloseCampaign(uint256 _campaignId) private returns (CampaignData memory) {
        CampaignData memory campaignData = _campaigns[_campaignId];

        if (campaignData.closed) {
            revert ProjectCampaignAlreadyClosed();
        }
        if (campaignData.salvagePoll.status == SalvagePollStatus.ACTIVE) {
            revert SalvagePollCampaignHasOpenedSalvagePoll();
        }
        _updateCampaignStatus(campaignData);
        // get again the SCampaing since it should have changed inside _updateCampaignStatus()
        campaignData = _campaigns[_campaignId];

        if (campaignData.status == CampaignStatus.ACTIVE) {
            revert SalvagePollCampaignStillActive();
        }
        return campaignData;
    }

    function checkMintAllowed(uint256 _campaignId, address _user) public onlyStarter returns (bool, uint256) {
        CampaignData memory campaignData = _campaigns[_campaignId];
        VCCampaign campaign = VCCampaign(campaignData.campaign);
        (bool result, uint256 userAmount) = campaign.checkMintAllowed(_user);
        if (!result) {
            return (false, userAmount);
        }
        return (true, userAmount);
    }

    function _checkBeforeVoteSalvagePoll(
        CampaignData memory campaignData,
        uint256 _campaignId,
        address _voter
    ) private view {
        if (campaignData.closed) {
            revert ProjectCampaignAlreadyClosed();
        }

        if (campaignData.salvagePoll.status != SalvagePollStatus.ACTIVE) {
            revert SalvagePollNotActive();
        }

        if (block.timestamp > campaignData.salvagePoll.maturity) {
            revert SalvagePollHasExpired();
        }

        if (!_validateVoter(_campaignId, _voter)) {
            revert SalvagePollInvalidVoter();
        }
    }

    function _checkBeforeCloseSalvagePoll(CampaignData memory campaignData, uint256 _quorum) private view {
        VCCampaign campaign = VCCampaign(campaignData.campaign);

        if (campaignData.closed) {
            revert ProjectCampaignAlreadyClosed();
        }

        if (campaignData.salvagePoll.status != SalvagePollStatus.ACTIVE) {
            revert SalvagePollNotActive();
        }

        if (
            campaignData.salvagePoll.votersCount <= (campaign.totalFunders() * _quorum) / 100 ||
            block.timestamp <= campaignData.salvagePoll.maturity
        ) {
            revert SalvagePollCanNotBeClosed();
        }
    }

    /**
     * @notice Retrieves campaign data.
     *
     * @param _campaignId The campaign identifier.
     */
    function getCampaignData(uint256 _campaignId) external view returns (CampaignData memory) {
        return _campaigns[_campaignId];
    }

    /**
     * @notice Retrieves the current raised amount for a funding campaign.
     *
     * @param _campaignId The campaign identifier.
     */
    function getCampaignTotalFunding(uint256 _campaignId) public view returns (uint256) {
        CampaignData memory campaignData = _campaigns[_campaignId];
        return VCCampaign(campaignData.campaign).totalFunding();
    }

    /**
     * @notice Retrieves the current raised amount for the project itself.
     */
    function getProjectTotalFunding() external view returns (uint256) {
        uint256 projectTotalFunding = 0;
        for (uint256 i = 0; i < _campaigns.length; i++) {
            CampaignData memory campaignData = _campaigns[i];
            projectTotalFunding += VCCampaign(campaignData.campaign).totalFunding();
        }
        projectTotalFunding += marketplaceFunding;
        return projectTotalFunding;
    }

    /**
     * @notice Retrieves salvage poll data.
     *
     * @param _campaignId The campaign identifier.
     */
    function getSalvagePoll(uint256 _campaignId) external view returns (SalvagePoll memory) {
        return _campaigns[_campaignId].salvagePoll;
    }

    /**
     * @dev Calculate and returns the campaign and poll status based on the votes
     * @param _salvagePoll Salvage poll to calculate votes
     * @return A pair of objects SalvagePollStatus and CampaignStatus
     */
    function _getStatusFromSalvagePoll(SalvagePoll memory _salvagePoll)
        internal
        pure
        returns (SalvagePollStatus, CampaignStatus)
    {
        return
            _salvagePoll.settleCount > _salvagePoll.extendCount && _salvagePoll.settleCount > _salvagePoll.rejectCount
                ? (SalvagePollStatus.SETTLED, CampaignStatus.SUCCEEDED)
                : _salvagePoll.extendCount > _salvagePoll.rejectCount
                ? (SalvagePollStatus.EXTENDED, CampaignStatus.ACTIVE)
                : (SalvagePollStatus.REJECTED, CampaignStatus.DEFEATED);
    }

    function _validateVoter(uint256 _campaignId, address _voter) internal view returns (bool) {
        CampaignData memory campaignData = _campaigns[_campaignId];
        VCCampaign campaign = VCCampaign(campaignData.campaign);

        if (campaign.getFundings(_voter) == 0 || (_votes[_campaignId][_voter] != SalvagePollVoteType.UNSET)) {
            return false;
        }
        return true;

        // address[] memory voters = _campaigns[_campaignId].salvagePoll.voters;
        // bool isAllowed = false;
        // bool hasVoted = false;
        // for (uint256 i = 0; i < voters.length; i++) {
        //     if (voters[i] == _voter) {
        //         isAllowed = true;
        //         hasVoted = _votes[_campaignId][_voter].voteType != SalvagePollVoteType.UNSET;
        //         break;
        //     }
        // }
        // require(isAllowed, "STARTER: Sender has not backed this campaign");
        // require(!hasVoted, "STARTER: Sender has already voted");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IVCPool.sol";
import "../interfaces/IVCStarter.sol";
import "../interfaces/IPoCNft.sol";
import "../interfaces/IArtNft.sol";
import "../interfaces/IVCMarketplace.sol";
import "../interfaces/IVCMarketManager.sol";

contract VCGovernance {
    error GovNotWhitelistedLab();
    error GovOnlyAdmin();
    error GovInvalidAdmin();
    error GovInvalidQuorumPoll();
    error GovInvalidArtnft();

    event ProtocolSetup(
        address indexed vcPool,
        address indexed vcStarter,
        IERC20 currency,
        address marketManager,
        address artNft1155,
        address artNft721,
        address pocNft
    );

    enum MarketPlace {
        FixedPrice1155,
        FixedPrice721,
        Auction721
    }

    enum ArtNft {
        ERC1155,
        ERC721
    }

    address public admin;
    IERC20 public currency;
    IERC20 public cure;
    IVCPool public pool;
    IVCStarter public starter;
    IVCMarketManager public marketManager;
    IArtNft public artNft1155;
    IArtNft public artNft721;
    IPoCNft public pocNft;

    mapping(address => bool) public isWhitelistedLab;

    constructor(IERC20 _cure, address _admin) {
        _setAdmin(_admin);
        cure = _cure;
    }

    modifier onlyWhitelistedLab(address _lab) {
        if (!isWhitelistedLab[_lab]) {
            revert GovNotWhitelistedLab();
        }
        _;
    }

    function _onlyAdmin() private view {
        if (msg.sender != admin) {
            revert GovOnlyAdmin();
        }
    }

    function setupProtocol(
        IERC20 _currency,
        address _vcPool,
        address _vcStarter,
        address _artNft1155,
        address _artNft721,
        address _pocNft,
        address _marketplaceFixedPrice1155,
        address _marketplaceFixedPrice721,
        address _marketplaceAuction721,
        address _marketManager
    ) external {
        _onlyAdmin();

        pool = IVCPool(_vcPool);
        starter = IVCStarter(_vcStarter);
        artNft1155 = IArtNft(_artNft1155);
        artNft721 = IArtNft(_artNft721);
        pocNft = IPoCNft(_pocNft);
        marketManager = IVCMarketManager(_marketManager);

        _setMarketManagerToMarketplace(_marketplaceFixedPrice1155);
        _setMarketManagerToMarketplace(_marketplaceFixedPrice721);
        _setMarketManagerToMarketplace(_marketplaceAuction721);

        _setPoCNft(_pocNft);
        _setCurrency(_currency);

        _setMinterRoleArtNft(ArtNft.ERC1155, _marketplaceFixedPrice1155);
        _setMinterRoleArtNft(ArtNft.ERC721, _marketplaceFixedPrice721);
        _setMinterRoleArtNft(ArtNft.ERC721, _marketplaceAuction721);

        emit ProtocolSetup(_vcPool, _vcStarter, _currency, _marketManager, _artNft1155, _artNft721, _pocNft);
    }

    function setAdmin(address _newAdmin) external {
        _onlyAdmin();
        _setAdmin(_newAdmin);
    }

    function _setAdmin(address _newAdmin) private {
        if (_newAdmin == address(0) || _newAdmin == admin) {
            revert GovInvalidAdmin();
        }
        admin = _newAdmin;
    }

    function marketplaceWithdrawTo(
        MarketPlace _marketplace,
        address _token,
        address _to,
        uint256 _amount
    ) external {
        _onlyAdmin();
        marketManager.marketplaceWithdrawTo(uint256(_marketplace), _token, _to, _amount);
    }

    function _setPoCNft(address _pocNft) internal {
        _onlyAdmin();
        pool.setPoCNft(_pocNft);
        starter.setPoCNft(_pocNft);
        marketManager.setPoCNft(_pocNft);
    }

    //////////////////////////////////////////
    // MARKETPLACE SETUP THROUGH GOVERNANCE //
    //////////////////////////////////////////

    function setMaxBeneficiaryProjects(uint96 _maxBeneficiaryProjects) external {
        _onlyAdmin();
        marketManager.setMaxBeneficiaryProjects(_maxBeneficiaryProjects);
    }

    function setMinTotalFeeBps(uint96 _minTotalFeeBps) external {
        _onlyAdmin();
        marketManager.setMinTotalFeeBps(_minTotalFeeBps);
    }

    function setMarketplaceFeeBps(uint256 _marketplaceFeeBps) external {
        _onlyAdmin();
        marketManager.setMarketplaceFeeBps(_marketplaceFeeBps);
    }

    /////////////////////////////////////////
    // ART NFT SETUP THROUGH GOVERNANCE    //
    /////////////////////////////////////////

    function setMinterRoleArtNft(ArtNft _artNft, address _minter) external {
        _onlyAdmin();
        _setMinterRoleArtNft(_artNft, _minter);
    }

    function _setMinterRoleArtNft(ArtNft _artNft, address _minter) private {
        if (_artNft == ArtNft.ERC1155) {
            artNft1155.grantMinterRole(_minter);
        } else if (_artNft == ArtNft.ERC721) {
            artNft721.grantMinterRole(_minter);
        } else {
            revert GovInvalidArtnft();
        }
    }

    function setRoyaltyInfoArtNft(address _receiver, uint96 _royaltyFeeBps) external {
        _onlyAdmin();
        artNft1155.setRoyaltyInfo(_receiver, _royaltyFeeBps);
        artNft721.setRoyaltyInfo(_receiver, _royaltyFeeBps);
    }

    function setMaxRoyalty(uint256 _maxRoyaltyBps) external {
        _onlyAdmin();
        artNft1155.setMaxRoyalty(_maxRoyaltyBps);
        artNft721.setMaxRoyalty(_maxRoyaltyBps);
    }

    function setMaxBatchSize(uint256 _maxBatchSize) external {
        _onlyAdmin();
        artNft1155.setMaxBatchSize(_maxBatchSize);
        artNft721.setMaxBatchSize(_maxBatchSize);
    }

    //////////////////////////////////////
    // STARTER SETUP THROUGH GOVERNANCE //
    //////////////////////////////////////

    function setMarketplaceFixedPriceStarter(address _newMarketplaceFixedPrice) external {
        _onlyAdmin();
        starter.setMarketplaceFixedPrice(_newMarketplaceFixedPrice);
    }

    function setMarketplaceAuctionStarter(address _newMarketplaceAuction) external {
        _onlyAdmin();
        starter.setMarketplaceAuction(_newMarketplaceAuction);
    }

    // NECESITAMOS UN BLACKLIST O UN REMOVE WHITELIST??
    function whitelistLabsStarter(address[] memory _labs) external {
        _onlyAdmin();
        starter.whitelistLabs(_labs);
    }

    function setQuorumPollStarter(uint256 _quorumPoll) external {
        _onlyAdmin();
        if (_quorumPoll > 100) {
            revert GovInvalidQuorumPoll();
        }
        starter.setQuorumPoll(_quorumPoll);
    }

    function setMaxPollDurationStarter(uint256 _maxPollDuration) external {
        // should we check something here??
        _onlyAdmin();
        starter.setMaxPollDuration(_maxPollDuration);
    }

    ////////////////
    // GOVERNANCE //
    ////////////////

    function votePower(address _account) external view returns (uint256 userVotePower) {
        uint256 userCureBalance = cure.balanceOf(_account);
        uint256 boost = pocNft.getVotingPowerBoost(_account);

        userVotePower = (userCureBalance * (10000 + boost)) / 10000;
    }

    function setCurrency(IERC20 _currency) external {
        _onlyAdmin();
        _setCurrency(_currency);
    }

    function _setCurrency(IERC20 _currency) private {
        currency = _currency;
        starter.setCurrency(_currency);
        pool.setCurrency(_currency);
        marketManager.setCurrency(_currency);
    }

    function _setMarketManagerToMarketplace(address _marketPlace) private {
        IVCMarketplace(_marketPlace).setMarketManager(marketManager);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVCStarter {
    function currency() external returns (IERC20);

    function setPoCNft(address _poCNFT) external;

    function setMarketplaceAuction(address _newMarketplace) external;

    function setMarketplaceFixedPrice(address _newMarketplace) external;

    function whitelistLabs(address[] memory _labs) external;

    function setCurrency(IERC20 _currency) external;

    function setQuorumPoll(uint256 _quorumPoll) external;

    function setMaxPollDuration(uint256 _maxPollDuration) external;

    function maxPollDuration() external view returns (uint256);

    function fundProjectFromMarketplace(uint256 _projectId, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../interfaces/IPoCNft.sol";
import "../interfaces/IVCStarter.sol";

contract VCCampaign is Initializable, AccessControl {
    IVCStarter public starter;
    bool public campaignSucceeded;
    IERC20 public currency;
    bool public campaignDefeated;
    address public lab;
    uint96 public totalFunders;
    address public pool;
    mapping(address => uint256) public fundings;
    uint256 public totalFunding;

    error CampaignUnexpectedAdminAddress();
    error CampaignMintNotAllowed();
    error CampaignInvalidUser();
    error CampaignWithdrawNotAllowed();
    error CampaignAlreadySucceeded();
    error CampaignUserAlreadyWithdrew();
    error CampaignOnlyStarterAllowed();

    event UserWithdrawal(address indexed user, uint256 amount, uint256 time);
    event CampaignSucceeded(uint256 time);
    event CampaignFailed(uint256 time);

    // bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");

    constructor() {}

    function init(
        address _lab,
        address _pool,
        address _project
    ) public initializer {
        if (_project == address(this) || _project == address(0)) {
            revert CampaignUnexpectedAdminAddress();
        }
        _grantRole(DEFAULT_ADMIN_ROLE, _project);
        starter = IVCStarter(msg.sender);
        currency = IERC20(starter.currency());
        lab = _lab;
        pool = _pool;
    }

    function onCampaignSucceeded(uint256 _extraGain) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (campaignSucceeded) {
            revert CampaignAlreadySucceeded();
        }
        campaignSucceeded = true;
        (uint256 poolAmount, uint256 labAmount) = _splitFunding(totalFunding, _extraGain);

        totalFunding = 0;
        currency.transfer(lab, labAmount);
        currency.transfer(pool, poolAmount);
        // this could be moved to project
        emit CampaignSucceeded(block.timestamp);
    }

    function onCampaignDefeated() external onlyRole(DEFAULT_ADMIN_ROLE) {
        campaignDefeated = true;
        // this could be moved to project
        emit CampaignFailed(block.timestamp);
    }

    function checkMintAllowed(address _user) external onlyRole(DEFAULT_ADMIN_ROLE) returns (bool, uint256) {
        if (!campaignSucceeded || !(fundings[_user] > 0)) {
            return (false, 0);
        }
        uint256 userAmount = fundings[_user];
        fundings[_user] = 0;
        return (true, userAmount);
    }

    function withdrawOnCampaignDefeated(address _user) external onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        if (!campaignDefeated) {
            revert CampaignWithdrawNotAllowed();
        }
        if (!(fundings[_user] > 0)) {
            revert CampaignInvalidUser();
        }
        uint256 userAmount = fundings[_user];
        totalFunding -= userAmount;
        fundings[_user] = 0;
        if (!currency.transfer(_user, userAmount)) {
            return false;
        }
        emit UserWithdrawal(_user, userAmount, block.timestamp);
        return true;
    }

    function fund(address _funder, uint256 _amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (fundings[_funder] == 0) {
            totalFunders++;
        }
        fundings[_funder] += _amount;
        totalFunding += _amount;

        // bool existingDonor = false;
        // for (uint256 i = 0; i < _donations.length; i++) {
        //     if (_donations[i].donor == _donor) {
        //         _donations[i].amount += _amount;
        //         existingDonor = true;
        //         break;
        //     }
        // }
        // if (!existingDonor) {
        //     _donations.push(Donation({amount: _amount, donor: _donor}));
        // }
        // totalDonations += _amount;
        // emit event
    }

    function getFundings(address _user) public view returns (uint256) {
        return fundings[_user];
    }

    // function getDonations() external view returns (Donation[] memory) {
    //     return _donations;
    // }

    function _splitFunding(uint256 _funding, uint256 _extraFunding)
        private
        pure
        returns (uint256 poolAmount, uint256 labAmount)
    {
        uint256 target = _funding - _extraFunding;

        poolAmount = _fromBips(target, 2000);
        poolAmount += _fromBips(_extraFunding, 500);

        labAmount = _fromBips(target, 8000);
        labAmount += _fromBips(_extraFunding, 9500);
    }

    function _fromBips(uint256 _totalAmount, uint256 _bips) internal pure returns (uint256) {
        return (_totalAmount * _bips) / 10000;
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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IPoCNft {
    function mint(address _user, uint256 _amount) external;

    function getVotingPowerBoost(address _user) external view returns (uint256 votingPowerBoost);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVCPool {
    function setPoCNft(address _poolNFT) external;

    function setCurrency(IERC20 _currency) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IArtNft {
    function exists(uint256 _tokenId) external returns (bool);

    function grantMinterRole(address _address) external;

    function setMaxRoyalty(uint256 _maxRoyaltyBps) external;

    function setMaxBatchSize(uint256 _maxBatchSize) external;

    function setRoyaltyInfo(address _receiver, uint96 _royaltyFeeBps) external;

    function setApprovalForAllCustom(
        address caller,
        address operator,
        bool approved
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IArtNft.sol";
import "../interfaces/IVCMarketManager.sol";

interface IVCMarketplace {
    function whitelistTokens(address[] memory _tokens) external;

    function blacklistTokens(address[] memory _tokens) external;

    function withdrawTo(
        address _token,
        address _to,
        uint256 _amount
    ) external;

    function setMaxBeneficiaryProjects(uint96 _maxBeneficiaryProjects) external;

    function setMinTotalFeeBps(uint96 _minTotalFeeBps) external;

    function setMarketplaceFee(uint256 _marketplaceFee) external;

    function calculateMarketplaceFee(uint256 _price) external;

    function setPoCNft(address _pocNft) external;

    function setCurrency(IERC20 _currency) external;

    function setMarketManager(IVCMarketManager _marketManager) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../contracts/marketplace/VCMarketplaceBase.sol";

enum ListStatus {
    NOT_LISTED,
    FIXED_PRICE,
    AUCTION
}

interface IVCMarketManager {
    function setPoCNft(address _pocNft) external;

    function setCurrency(IERC20 _currency) external;

    function setMinterRoles() external;

    function setMinTotalFeeBps(uint96 _minTotalFeeBps) external;

    function setMarketplaceFeeBps(uint256 _marketplaceFeeBps) external;

    function setMaxBeneficiaryProjects(uint96 _maxBeneficiaryProjects) external;

    function accrueRoyalty(address _receiver, uint256 _royaltyAmount) external;

    function marketplaceWithdrawTo(
        uint256 _marketplace,
        address _token,
        address _to,
        uint256 _amount
    ) external;

    function setListStatusERC721(uint256 _tokenId, bool listed) external;

    function getListStatusERC721(uint256 _tokenId) external view returns (ListStatus);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "./FeeBeneficiary.sol";
import "../interfaces/IVCStarter.sol";
import "../interfaces/IPoCNft.sol";
import "../interfaces/IArtNft.sol";

abstract contract VCMarketplaceBase is FeeBeneficiary, Pausable {
    error MktCallerNotSeller();
    error MktTokenNotListed();
    error MktInsufficientBalance();
    error MktWithdrawFailed();
    error MktCallerNotManager();
    error MktAccrRoyaltiesFailed();
    error MktSettleFailed();
    error MktPurchaseFailed();
    error MktAlreadyListedOnAuction();
    error MktAlreadyListedOnFixedPrice();

    event PoCNftSet(address indexed oldPoCNft, address indexed newPoCNft);

    /// @notice The Viral(Cure) Proof of Collaboration Non-Fungible Token
    IPoCNft public pocNft;

    /// @notice The Viral(Cure) Art Non-Fungible Token
    IArtNft public artNft;

    /**
     * @dev Sets the whitelisted tokens to be traded at the Marketplace.
     */
    constructor(address _artNft) {
        artNft = IArtNft(_artNft);
    }

    /**
     * @dev Pauses or unpauses the Marketplace
     */
    function pause(bool _paused) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_paused) _pause();
        else _unpause();
    }

    // IDEA: we left this function just in case, there is no real use for the moment.
    /**
     * @dev Allows the withdrawal of any `ERC20` token from the Marketplace to
     * any account. Can only be called by the owner.
     *
     * Requirements:
     *
     * - Contract balance has to be equal or greater than _amount
     *
     * @param _token: ERC20 token address to withdraw
     * @param _to: Address that will receive the transfer
     * @param _amount: Amount to withdraw
     */
    function withdrawTo(
        address _token,
        address _to,
        uint256 _amount
    ) public onlyManager {
        uint256 totalBalance = IERC20(_token).balanceOf(address(this));
        uint256 _balanceWithdrawable = IERC20(_token) == currency
            ? totalBalance - _balanceNoTWithdrawable
            : totalBalance;

        if (_balanceWithdrawable < _amount) {
            revert MktInsufficientBalance();
        }
        if (!IERC20(_token).transfer(_to, _amount)) {
            revert MktWithdrawFailed();
        }
    }

    /**
     * @dev Sets the Proof of Collaboration Non-Fungible Token.
     */
    function setPoCNft(address _pocNft) external onlyManager {
        pocNft = IPoCNft(_pocNft);
        emit PoCNftSet(address(pocNft), _pocNft);
    }

    function _fundProject(uint256 _projectId, uint256 _amount) internal override {
        IVCStarter(starter).fundProjectFromMarketplace(_projectId, _amount);
    }

    /**
     * @dev Computes the royalty amount for the given tokenId and its price.
     *
     * @param _tokenId: Non-fungible token identifier
     * @param _amount: A pertinent amount used to compute the royalty.
     */
    function checkRoyalties(uint256 _tokenId, uint256 _amount)
        public
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        (receiver, royaltyAmount) = IERC2981(address(artNft)).royaltyInfo(_tokenId, _amount);
    }

    function _setFeesAndCheckRoyalty(
        uint256 _tokenId,
        uint256 _poolFeeBps,
        uint256[] calldata _projectIds,
        uint256[] calldata _projectFeesBps
    ) internal {
        uint256 totalFeeBps = _setFees(_tokenId, _poolFeeBps, _projectIds, _projectFeesBps);
        (, uint256 royaltyBps) = checkRoyalties(_tokenId, FEE_DENOMINATOR); // It should be _feeDenominator() instead of FEE_DENOMINATOR
        if (totalFeeBps + royaltyBps > FEE_DENOMINATOR) {
            revert MktTotalFeeTooHigh();
        }
    }

    function _settle(
        uint256 _tokenId,
        address _seller,
        uint256 _highestBid,
        uint256 _marketFee,
        uint256 _starterFee,
        uint256 _poolFee,
        address _royaltyReceiver,
        uint256 _royaltyAmount
    ) internal {
        _transferFee(_tokenId, _seller, _highestBid, _marketFee, _starterFee, _poolFee);
        uint256 amountToSeller = _highestBid - _starterFee - _poolFee;

        if (_royaltyReceiver != address(0) && _royaltyAmount != 0) {
            if (!currency.transfer(marketManager, _royaltyAmount)) {
                revert MktAccrRoyaltiesFailed();
            }
            IVCMarketManager(marketManager).accrueRoyalty(_royaltyReceiver, _royaltyAmount);
            amountToSeller -= _royaltyAmount;
        }
        if (!currency.transfer(_seller, amountToSeller)) {
            revert MktSettleFailed();
        }
    }

    function _purchase(
        uint256 _tokenId,
        address _seller,
        uint256 _listPrice,
        uint256 _marketFee,
        uint256 _starterFee,
        uint256 _poolFee,
        address _royaltyReceiver,
        uint256 _royaltyAmount
    ) internal {
        _chargeFee(_tokenId, _seller, _listPrice, _marketFee, _starterFee, _poolFee);
        uint256 amountToSeller = _listPrice - _starterFee - _poolFee;

        if (_royaltyReceiver != address(0) && _royaltyAmount != 0) {
            if (!currency.transferFrom(msg.sender, marketManager, _royaltyAmount)) {
                revert MktAccrRoyaltiesFailed();
            }
            IVCMarketManager(marketManager).accrueRoyalty(_royaltyReceiver, _royaltyAmount);
            amountToSeller -= _royaltyAmount;
        }
        if (!currency.transferFrom(msg.sender, _seller, amountToSeller)) {
            revert MktPurchaseFailed();
        }
    }

    function _checkAddressZero(address _address) internal pure {
        if (_address == address(0)) {
            revert MktTokenNotListed();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../utils/FeeManager.sol";
import "../interfaces/IVCMarketManager.sol";

struct TokenFeesData {
    uint256 poolFeeBps;
    uint256 starterFeeBps;
    uint256[] projectIds;
    uint256[] projectFeesBps;
}

error MktFeesDataError();
error MktAddProjectFailed();
error MktRemoveProjectFailed();
error MktTotalFeeTooLow();
error MktTotalFeeTooHigh();
error MktVCPoolTransferFailed();
error MktVCStarterTransferFailed();
error MktUnexpectedAddress();
error MktInactiveProject();
error MktInvalidMarketManager();
error MktOnlyMktManagerAllowed();

contract FeeBeneficiary is FeeManager, AccessControl {
    bytes32 public constant STARTER_ROLE = keccak256("STARTER_ROLE");
    bytes32 public constant POOL_ROLE = keccak256("POOL_ROLE");

    /// @notice The Marketplace currency
    IERC20 public currency;
    uint256 internal _balanceNoTWithdrawable;

    /// @notice The VC Pool contract address
    address public pool;

    /// @notice The VC Starter contract address
    address public starter;

    /// @notice The Marketplace marketManager
    address public marketManager;

    /// @notice The minimum fee in basis points to distribute amongst VC Pool and VC Starter Projects
    uint256 public minTotalFeeBps;

    /// @notice The VC Marketplace fee in basis points
    uint256 public marketplaceFeeBps;

    /// @notice The maximum amount of projects a token seller can support
    uint96 public maxBeneficiaryProjects;

    event ProjectAdded(uint256 indexed projectId, uint256 time);
    event ProjectRemoved(uint256 indexed projectId, uint256 time);
    event CurrencySet(address indexed oldCurrency, address indexed newCurrency);

    /**
     * @dev Maps a token and seller to its TokenFeesData struct.
     */
    mapping(uint256 => mapping(address => TokenFeesData)) _tokenFeesData;

    /**
     * @dev Maps a project id to its beneficiary status.
     */
    mapping(uint256 => bool) internal _isActiveProject;

    modifier onlyManager() {
        if (msg.sender != marketManager) {
            revert MktOnlyMktManagerAllowed();
        }
        _;
    }

    /**
     * @dev Constructor
     */
    constructor(
        address _pool,
        address _starter,
        uint256 _minTotalFeeBps,
        uint256 _marketplaceFeeBps,
        uint96 _maxBeneficiaryProjects
    ) {
        _checkAddress(_pool);
        _checkAddress(_starter);

        _setMinTotalFeeBps(_minTotalFeeBps);
        _setMarketplaceFeeBps(_marketplaceFeeBps);
        _setMaxBeneficiaryProjects(_maxBeneficiaryProjects);

        _grantRole(POOL_ROLE, _pool);
        _grantRole(STARTER_ROLE, _starter);

        pool = _pool;
        starter = _starter;
    }

    function setMarketManager(address _marketManager) external onlyRole(DEFAULT_ADMIN_ROLE) {
        marketManager = _marketManager;
    }

    function setMinTotalFeeBps(uint96 _minTotalFeeBps) external onlyManager {
        _setMinTotalFeeBps(_minTotalFeeBps);
    }

    function setMarketplaceFeeBps(uint256 _marketplaceFee) external onlyManager {
        _setMarketplaceFeeBps(_marketplaceFee);
    }

    function setMaxBeneficiaryProjects(uint96 _maxBeneficiaryProjects) public onlyManager {
        maxBeneficiaryProjects = _maxBeneficiaryProjects;
    }

    /**
     * @dev Removes a project as a beneficiary candidate.
     *
     * @param _projectId the project identifier to remove.
     *
     * NOTE: can only be called by starter or admin.
     */
    // THIS RIGHT NOW CAN BE CALLED ONLY BY STARTER
    function removeProject(uint256 _projectId) public onlyRole(STARTER_ROLE) {
        if (!_isActiveProject[_projectId]) {
            revert MktRemoveProjectFailed();
        }
        _isActiveProject[_projectId] = false;
        emit ProjectRemoved(_projectId, block.timestamp);
    }

    /**
     * @dev Adds a project as a beneficiary candidate.
     *
     * @param _projectId the project identifier.
     *
     * NOTE: can only be called by starter or admin.
     */
    // THIS RIGHT NOW CAN BE CALLED ONLY BY STARTER
    function addProject(uint256 _projectId) public onlyRole(STARTER_ROLE) {
        if (_isActiveProject[_projectId]) {
            revert MktAddProjectFailed();
        }
        _isActiveProject[_projectId] = true;
        emit ProjectAdded(_projectId, block.timestamp);
    }

    /**
     * @dev Returns True if the project is active or False if is not.
     *
     * @param _projectId the project identifier.
     */
    function isActiveProject(uint256 _projectId) public view returns (bool) {
        return _isActiveProject[_projectId];
    }

    /**
     * @dev Returns the struct TokenFeesData corresponding to the _token and _tokenId
     *
     * @param _tokenId: Non-fungible token identifier
     */
    function getFeesData(uint256 _tokenId, address _seller) public view returns (TokenFeesData memory result) {
        return _tokenFeesData[_tokenId][_seller];
    }

    /**
     * @dev Constructs a `TokenFeesData` struct which stores the total fees in
     * bips that will be transferred to both the pool and the starter smart
     * contracts.
     *
     * @param _tokenId NFT token ID
     * @param _projectIds Array of Project identifiers to support
     * @param _projectFeesBps Array of fees to support each project ID
     */
    function _setFees(
        uint256 _tokenId,
        uint256 _poolFeeBps,
        uint256[] calldata _projectIds,
        uint256[] calldata _projectFeesBps
    ) internal returns (uint256) {
        if (_projectIds.length != _projectFeesBps.length || _projectIds.length > maxBeneficiaryProjects) {
            revert MktFeesDataError();
        }

        uint256 starterFeeBps;
        for (uint256 i = 0; i < _projectFeesBps.length; i++) {
            if (!_isActiveProject[_projectIds[i]]) {
                revert MktInactiveProject();
            }
            starterFeeBps += _projectFeesBps[i];
        }

        uint256 totalFeeBps = _poolFeeBps + starterFeeBps;

        if (totalFeeBps < minTotalFeeBps) {
            revert MktTotalFeeTooLow();
        }

        if (totalFeeBps > FEE_DENOMINATOR) {
            revert MktTotalFeeTooHigh();
        }

        _tokenFeesData[_tokenId][msg.sender] = TokenFeesData(_poolFeeBps, starterFeeBps, _projectIds, _projectFeesBps);

        return totalFeeBps;
    }

    /**
     * @dev Computes and transfers fees to both the Pool and the Starter smart contracts when the token is purchased.
     *
     * @param _tokenId Non-fungible token identifier
     * @param _listPrice Token fixed price
     *
     * NOTE: Charges fee to msg.sender, i.e. buyer.
     */
    function _chargeFee(
        uint256 _tokenId,
        address _seller,
        uint256 _listPrice,
        uint256 _marketFee,
        uint256 _starterFee,
        uint256 _poolFee
    ) internal {
        if (!currency.transferFrom(msg.sender, pool, _marketFee + _poolFee)) {
            revert MktVCPoolTransferFailed();
        }
        if (_starterFee > 0) {
            if (!currency.transferFrom(msg.sender, address(this), _starterFee)) {
                revert MktVCStarterTransferFailed();
            }
            TokenFeesData memory feesData = _tokenFeesData[_tokenId][_seller];
            currency.approve(starter, _starterFee);
            _fundProjects(feesData, _listPrice);
        }
    }

    /**
     * @dev Computes and transfers fees to both the Pool and the Starter smart contracts when the token is purchased.
     *
     * @param _tokenId Non-fungible token identifier
     * @param _listPrice Token auction price
     *
     * NOTE: Transfer fee from contract (Marketplace) itself.
     */
    function _transferFee(
        uint256 _tokenId,
        address _seller,
        uint256 _listPrice,
        uint256 _marketFee,
        uint256 _starterFee,
        uint256 _poolFee
    ) internal {
        if (!currency.transfer(pool, _marketFee + _poolFee)) {
            revert MktVCPoolTransferFailed();
        }
        if (_starterFee > 0) {
            TokenFeesData memory feesData = _tokenFeesData[_tokenId][_seller];
            currency.approve(starter, _starterFee);
            _fundProjects(feesData, _listPrice);
        }
    }

    /**
     * @dev Computes individual fees for each beneficiary project and performs
     * the pertinent accounting at the Starter smart contract.
     */
    function _fundProjects(TokenFeesData memory _feesData, uint256 _listPrice) internal {
        for (uint256 i = 0; i < _feesData.projectFeesBps.length; i++) {
            uint256 amount = _toFee(_listPrice, _feesData.projectFeesBps[i]);
            if (amount > 0) {
                _fundProject(_feesData.projectIds[i], amount);
            }
        }
    }

    /**
     * @dev
     */
    function _fundProject(uint256 _projectId, uint256 _amount) internal virtual {}

    function _checkAddress(address _address) internal view {
        if (_address == address(this) || _address == address(0)) {
            revert MktUnexpectedAddress();
        }
    }

    /**
     * @dev Sets the Marketplace currency.
     */
    function setCurrency(IERC20 _currency) external onlyManager {
        currency = _currency;
        emit CurrencySet(address(currency), address(_currency));
    }

    function _setMinTotalFeeBps(uint256 _minTotalFeeBps) private {
        minTotalFeeBps = _minTotalFeeBps;
    }

    function _setMarketplaceFeeBps(uint256 _marketplaceFeeBps) private {
        marketplaceFeeBps = _marketplaceFeeBps;
    }

    function _setMaxBeneficiaryProjects(uint96 _maxBeneficiaryProjects) private {
        maxBeneficiaryProjects = _maxBeneficiaryProjects;
    }

    /**
     * @dev Splits an amount into fees for both Pool and Starter smart
     * contracts and a resulting amount to be transferred to the token
     * owner (i.e. the token seller).
     */
    function _splitListPrice(TokenFeesData memory _feesData, uint256 _listPrice)
        internal
        pure
        returns (
            uint256 starterFee,
            uint256 poolFee,
            uint256 resultingAmount
        )
    {
        starterFee = _toFee(_listPrice, _feesData.starterFeeBps);
        poolFee = _toFee(_listPrice, _feesData.poolFeeBps);
        resultingAmount = _listPrice - starterFee - poolFee;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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
}

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
pragma solidity ^0.8.9;

contract FeeManager {
    /// @notice Used to translate from basis points to amounts
    uint96 public constant FEE_DENOMINATOR = 10_000;

    /**
     * @dev Translates a fee in basis points to a fee amount.
     */
    function _toFee(uint256 _amount, uint256 _feeBps) internal pure returns (uint256) {
        return (_amount * _feeBps) / FEE_DENOMINATOR;
    }
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