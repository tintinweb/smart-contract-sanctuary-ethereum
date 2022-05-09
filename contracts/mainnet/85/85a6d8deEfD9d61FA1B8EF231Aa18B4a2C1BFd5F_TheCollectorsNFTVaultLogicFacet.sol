// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/*

████████╗██╗  ██╗███████╗     ██████╗ ██████╗ ██╗     ██╗     ███████╗ ██████╗████████╗ ██████╗ ██████╗ ███████╗
╚══██╔══╝██║  ██║██╔════╝    ██╔════╝██╔═══██╗██║     ██║     ██╔════╝██╔════╝╚══██╔══╝██╔═══██╗██╔══██╗██╔════╝
   ██║   ███████║█████╗      ██║     ██║   ██║██║     ██║     █████╗  ██║        ██║   ██║   ██║██████╔╝███████╗
   ██║   ██╔══██║██╔══╝      ██║     ██║   ██║██║     ██║     ██╔══╝  ██║        ██║   ██║   ██║██╔══██╗╚════██║
   ██║   ██║  ██║███████╗    ╚██████╗╚██████╔╝███████╗███████╗███████╗╚██████╗   ██║   ╚██████╔╝██║  ██║███████║
   ╚═╝   ╚═╝  ╚═╝╚══════╝     ╚═════╝ ╚═════╝ ╚══════╝╚══════╝╚══════╝ ╚═════╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚══════╝

███╗   ██╗███████╗████████╗    ██╗   ██╗ █████╗ ██╗   ██╗██╗  ████████╗
████╗  ██║██╔════╝╚══██╔══╝    ██║   ██║██╔══██╗██║   ██║██║  ╚══██╔══╝
██╔██╗ ██║█████╗     ██║       ██║   ██║███████║██║   ██║██║     ██║
██║╚██╗██║██╔══╝     ██║       ╚██╗ ██╔╝██╔══██║██║   ██║██║     ██║
██║ ╚████║██║        ██║        ╚████╔╝ ██║  ██║╚██████╔╝███████╗██║
╚═╝  ╚═══╝╚═╝        ╚═╝         ╚═══╝  ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝

██╗      ██████╗  ██████╗ ██╗ ██████╗    ███████╗ █████╗  ██████╗███████╗████████╗
██║     ██╔═══██╗██╔════╝ ██║██╔════╝    ██╔════╝██╔══██╗██╔════╝██╔════╝╚══██╔══╝
██║     ██║   ██║██║  ███╗██║██║         █████╗  ███████║██║     █████╗     ██║
██║     ██║   ██║██║   ██║██║██║         ██╔══╝  ██╔══██║██║     ██╔══╝     ██║
███████╗╚██████╔╝╚██████╔╝██║╚██████╗    ██║     ██║  ██║╚██████╗███████╗   ██║
╚══════╝ ╚═════╝  ╚═════╝ ╚═╝ ╚═════╝    ╚═╝     ╚═╝  ╚═╝ ╚═════╝╚══════╝   ╚═╝

*/

import "./TheCollectorsNFTVaultBaseFacet.sol";

/*
    @dev
    The facet that handling all vaults logic and can be called only by @TheCollectorsNFTVaultDiamond
    This contract is part of a diamond / facets implementation as described
    in EIP 2535 (https://eips.ethereum.org/EIPS/eip-2535)
*/
contract TheCollectorsNFTVaultLogicFacet is TheCollectorsNFTVaultBaseFacet {
    using Counters for Counters.Counter;
    using Strings for uint256;

    constructor() ERC721("", "") {}

    // ==================== Protocol management ====================

    /*
        @dev
        Is used to fetch the JSON file of the vault token
    */
    function setBaseTokenURI(string memory __baseTokenURI) external onlyOwner {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        _as.baseTokenURI = __baseTokenURI;
    }

    /*
        @dev
        The wallet to hold ETH for liquidity
    */
    function setLiquidityWallet(address _liquidityWallet) external onlyOwner {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        _as.liquidityWallet = _liquidityWallet;
    }

    /*
        @dev
        The wallet to hold ETH for staking
    */
    function setStakingWallet(address _stakingWallet) external onlyOwner {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        _as.stakingWallet = _stakingWallet;
    }

    // ==================== Vault management ====================

    /*
        @dev
        Creates a new vault, can be called by anyone.
        The msg.sender doesn't have to be part of the vault.
    */
    function createVault(
        string memory vaultName,
        address collection,
        uint256 sellOrCancelSellOrderConsensus,
        uint256 buyConsensus,
        uint256 gracePeriodForSellingOrCancellingSellOrder,
        address[] memory _participants,
        bool privateVault,
        uint256 maxParticipants,
        uint256 minimumFunding
    ) external {
        // At least one participant
        require(_participants.length > 0 && _participants.length <= maxParticipants, "E1");
        require(bytes(vaultName).length > 0, "E2");
        require(collection != address(0), "E3");
        require(sellOrCancelSellOrderConsensus >= 51 ether && sellOrCancelSellOrderConsensus <= 100 ether, "E4");
        require(buyConsensus >= 51 ether && buyConsensus <= 100 ether, "E5");
        // Min 7 days, max 6 months
        // The amount of time to wait before undecided votes for selling/canceling sell order are considered as yes
        require(gracePeriodForSellingOrCancellingSellOrder >= 7 * 24 * 60 * 60
            && gracePeriodForSellingOrCancellingSellOrder <= 6 * 30 * 24 * 60 * 60, "E6");
        // Private vaults don't need to have a minimumFunding
        require(privateVault || minimumFunding > 0, "E7");
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        emit VaultCreated(_as.vaultIdTracker.current(), collection, privateVault);
        for (uint256 i; i < _participants.length; i++) {
            _as.vaultParticipants[_as.vaultIdTracker.current()][i] = LibDiamond.Participant(_participants[i], 0, 0, false, address(0), 0, 0, false, 0);
            // Not going to check if the participant already exists (avoid duplicated) when creating a vault,
            // because it is the creator responsibility and does not have any bad affect over the vault
            emit ParticipantJoinedVault(_as.vaultIdTracker.current(), _participants[i]);
        }
        _as.vaults[_as.vaultIdTracker.current()] = LibDiamond.Vault(_as.vaultIdTracker.current(), vaultName, collection, 0, LibDiamond.VoteFor.WaitingToSetTokenInfo, 0, 0,
            sellOrCancelSellOrderConsensus, 0, buyConsensus, gracePeriodForSellingOrCancellingSellOrder, 0, maxParticipants);
        _as.vaultsExtensions[_as.vaultIdTracker.current()] = LibDiamond.VaultExtension(
            !privateVault, privateVault ? 0 : minimumFunding, 0, !IERC165(collection).supportsInterface(type(IERC721).interfaceId), false
        );
        Address.functionDelegateCall(
            _as.nftVaultAssetsHolderCreator,
            abi.encodeWithSelector(IAssetsHolderCreator.createNFTVaultAssetsHolder.selector, _as.vaultIdTracker.current())
        );
        _as.vaultParticipantsAddresses[_as.vaultIdTracker.current()] = _participants;
        _as.vaultIdTracker.increment();
    }

    /*
        @dev
        Allow people to join a public vault but only if it hasn't bought the NFT yet
        The person who wants to join needs to send more than the minimum amount of ETH to join the vault
    */
    function joinPublicVault(uint256 vaultId) external payable {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        // NFT wasn't bought yet
        _requireVotingForBuyingOrWaitingForSettingTokenInfo(vaultId);
        // Vault exists and it is public
        require(_as.vaultsExtensions[vaultId].publicVault, "E2");
        // There is room
        require(_as.vaultParticipantsAddresses[vaultId].length < _as.vaults[vaultId].maxParticipants, "E3");
        // The sender is a not a participant of the vault yet
        require(!_isParticipantExists(vaultId, msg.sender), "E4");
        // The sender sent enough ETH
        require(msg.value >= _as.vaultsExtensions[vaultId].minimumFunding, "E5");
        address[] storage participants = _as.vaultParticipantsAddresses[vaultId];
        participants.push(msg.sender);
        _as.vaultParticipants[vaultId][participants.length - 1] = LibDiamond.Participant(msg.sender, 0, 0, false, address(0), 0, 0, false, 0);
        emit ParticipantJoinedVault(vaultId, msg.sender);
        fundVault(vaultId);
    }

    /*
        @dev
        Adding a person to a private vault by another participant of the vault
    */
    function addParticipant(uint256 vaultId, address participant) external {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        // NFT wasn't bought yet
        _requireVotingForBuyingOrWaitingForSettingTokenInfo(vaultId);
        // Private vault
        require(!_as.vaultsExtensions[vaultId].publicVault, "E2");
        // There is room
        require(_as.vaultParticipantsAddresses[vaultId].length < _as.vaults[vaultId].maxParticipants, "E3");
        // The sender is a participant of the vault
        require(_isParticipantExists(vaultId, msg.sender), "E4");
        require(!_isParticipantExists(vaultId, participant), "E5");
        address[] storage participants = _as.vaultParticipantsAddresses[vaultId];
        for (uint256 i; i < participants.length; i++) {
            if (_as.vaultParticipants[vaultId][i].participant == msg.sender) {
                // Only participant that paid can add others to a private vault
                // Can check paid > 0 and not ownership > 0 because this method can be used only before purchasing
                // Using paid > 0 will save gas
                // Also using @_getPercentage can return > 0 if no one paid
                require(_as.vaultParticipants[vaultId][i].paid > 0, "E6");
                break;
            }
        }
        participants.push(participant);
        _as.vaultParticipants[vaultId][participants.length - 1] = LibDiamond.Participant(participant, 0, 0, false, address(0), 0, 0, false, 0);
        emit ParticipantJoinedVault(vaultId, participant);
    }

    /*
        @dev
        Setting the token id to purchase and max buying price. After setting token info,
        participants can vote for or against buying it.
        In case the vault is private, the vault's collection can also be changed. The reasoning behind it is that
        a private vault's participants know each other so less likely to be surprised if the collection has changed.
        Participants can call this method again in order to change the token info and max buying price. Everytime
        this function is called all the votes are reset and the voting starts again.
        In case the % of ownership for buying is higher than the buying consensus (DAO decided to buy),
        only a participant who voted yes can change the token info and max buying price and reset the process.
        The logic behind that is that the vault consist of people who know each other so less likely to be
        attacked by two participants who need to work together. In any case, the participants can always withdraw
        their ETH as long as the vault didn't buy the NFT and just open a new vault without the bad actors.
    */
    function setTokenInfoAndMaxBuyPrice(uint256 vaultId, address collection, uint256 tokenId, uint256 maxBuyPrice) external {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        // Can call this method only if haven't set a token before or already set but haven't bought the token yet
        _requireVotingForBuyingOrWaitingForSettingTokenInfo(vaultId);
        LibDiamond.Vault storage vault = _as.vaults[vaultId];
        /*
            @dev
            Checking if vaults[vaultId].votingFor == VoteFor.WaitingToSetTokenInfo because tokenId-to-buy can be 0
            Only private vaults can change collections
        */
        if (!_as.vaultsExtensions[vaultId].publicVault) {
            require(collection != address(0), "E2");
            if (vault.collection != collection) {
                // Re setting the isERC1155 property because there is a new collection
                _as.vaultsExtensions[vaultId].isERC1155 = !IERC165(collection).supportsInterface(type(IERC721).interfaceId);
            }
            vault.collection = collection;
        }
        vault.tokenId = tokenId;
        vault.votingFor = LibDiamond.VoteFor.Buying;
        _as.vaultsExtensions[vaultId].maxPriceToBuy = maxBuyPrice;
        address[] memory participants = _as.vaultParticipantsAddresses[vaultId];
        bool isParticipant;
        bool participantVoteYes;
        uint256 votesPercentage;
        for (uint256 i; i < participants.length; i++) {
            votesPercentage += _as.vaultParticipants[vaultId][i].vote ? _getPercentage(vaultId, i, 0) : 0;
            if (_as.vaultParticipants[vaultId][i].participant == msg.sender) {
                // Only participants who paid can be part of the decisions making
                // Can check paid > 0 and not ownership > 0 because this method can be used only before purchasing
                // Using paid > 0 will save gas
                // Also using @_getPercentage can return > 0 if no one paid
                require(_as.vaultParticipants[vaultId][i].paid > 0, "E3");
                isParticipant = true;
                participantVoteYes = _as.vaultParticipants[vaultId][i].vote;
                emit NFTTokenWasSet(vault.id, vault.collection, tokenId, maxBuyPrice);
                _vote(vaultId, _as.vaultParticipants[vaultId][i], true, vault.votingFor);
            } else {
                // Resetting the vote so a previous vote won't be considers for the new token id
                _as.vaultParticipants[vaultId][i].vote = false;
                _as.vaultParticipants[vaultId][i].voted = false;
            }
        }
        require(isParticipant, "E4");
        // As written in the method documentation, even if the votesPercentage is higher than the buy consensus
        // a participant who voted yes can still reset the process
        require(votesPercentage < vault.buyConsensus || participantVoteYes, "E5");
    }

    /*
        @dev
        Setting a listing price for the NFT sell order.
        Later, participants can vote for or against selling it at this price.
        Participants can call this method again in order to change the listing price.
        In case the % of ownership for selling is higher than selling consensus (DAO decided to sell),
        only a participant who voted yes can change the listing price and reset the process.
    */
    function setListingPrice(uint256 vaultId, uint256 listFor) external {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        LibDiamond.Vault storage vault = _as.vaults[vaultId];
        require(vault.votingFor == LibDiamond.VoteFor.Selling, "E1");
        vault.listFor = listFor;
        bool isVaultPassedConsensus = isVaultPassedSellOrCancelSellOrderConsensus(vaultId);
        address[] memory participants = _as.vaultParticipantsAddresses[vaultId];
        bool isParticipant;
        bool participantVoteYes;
        for (uint256 i; i < participants.length; i++) {
            if (_as.vaultParticipants[vaultId][i].participant == msg.sender) {
                // Only participants who has ownership can be part of the decision making
                // Can check ownership > 0 and not call @_getPercentage because this method can be
                // called only after purchasing
                // Using ownership > 0 will save gas
                require(_as.vaultParticipants[vaultId][i].ownership > 0, "E2");
                participantVoteYes = _getParticipantSellOrCancelSellOrderVote(vaultId, i);
                isParticipant = true;
                _resetVotesAndGracePeriod(vaultId);
                emit ListingPriceWasSet(vault.id, vault.collection, vault.tokenId, listFor);
                _vote(vaultId, _as.vaultParticipants[vaultId][i], true, vault.votingFor);
                break;
            }
        }
        require(isParticipant, "E3");
        // As written in the method documentation, even if the votesPercentage is higher than the sell consensus
        // a participant who voted yes can still reset the process
        require(!isVaultPassedConsensus || participantVoteYes, "E4");
    }

    /*
        @dev
        Voting for either buy the token, listing it for sale or cancel the sell order
    */
    function vote(uint256 vaultId, bool yes) external {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        require(_as.vaults[vaultId].votingFor != LibDiamond.VoteFor.WaitingToSetTokenInfo, "E1");
        address[] memory participants = _as.vaultParticipantsAddresses[vaultId];
        bool isParticipant;
        for (uint256 i; i < participants.length; i++) {
            if (_as.vaultParticipants[vaultId][i].participant == msg.sender) {
                isParticipant = true;
                // Only participants with ownership can be part of the decision making
                // Calling @_getPercentage because this method can be called before and after purchasing
                if (_getPercentage(vaultId, i, 0) > 0) {
                    _vote(vaultId, _as.vaultParticipants[vaultId][i], yes, _as.vaults[vaultId].votingFor);
                }
                /*
                    @dev
                    Not using a break here since participants can hold more than 1 seat if they bought the vault NFT
                    from the other participants after the vault bought the original NFT.
                    If we would have a break here, the vault could get to a limbo state where it
                    would not able to pass the consensus to sell the NFT and it would be stuck forever
                */
            }
        }
        require(isParticipant, "E3");
    }

    /*
        @dev
        Sending ETH to vault. The funds that will not be used for purchasing the
        NFT will be returned to the participate when calling the @claimVaultTokenAndGetLeftovers method
    */
    function fundVault(uint256 vaultId) public payable {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        // Can only fund the vault if the token was not purchased yet
        _requireVotingForBuyingOrWaitingForSettingTokenInfo(vaultId);
        address[] memory participants = _as.vaultParticipantsAddresses[vaultId];
        bool isParticipant;
        for (uint256 i; i < participants.length; i++) {
            if (_as.vaultParticipants[vaultId][i].participant == msg.sender) {
                isParticipant = true;
                _as.vaultParticipants[vaultId][i].paid += msg.value;
                if (_as.vaultsExtensions[vaultId].publicVault) {
                    require(_as.vaultParticipants[vaultId][i].paid >= _as.vaultsExtensions[vaultId].minimumFunding, "E2");
                }
                // The asset holder is the contract that is holding the ETH and tokens
                Address.sendValue(_as.assetsHolders[vaultId], msg.value);
                emit VaultWasFunded(vaultId, msg.sender, msg.value);
                break;
            }
        }
        // Keeping this here, just for a situation where someone sends ETH using this function
        // and he is not a participant of the vault
        require(isParticipant, "E3");
    }

    /*
        @dev
        Withdrawing ETH from the vault, can only be called before purchasing the NFT.
        In case of a public vault, if the withdrawing make the participant to fund the vault less than the
        minimum amount, the participant will be removed from the vault and all of their investment will be returned
    */
    function withdrawFunds(uint256 vaultId, uint256 amount) external nonReentrant {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        _requireVotingForBuyingOrWaitingForSettingTokenInfo(vaultId);
        address[] memory participants = _as.vaultParticipantsAddresses[vaultId];
        for (uint256 i; i < participants.length; i++) {
            if (_as.vaultParticipants[vaultId][i].participant == msg.sender) {
                require(amount <= _as.vaultParticipants[vaultId][i].paid, "E2");
                if (_as.vaultsExtensions[vaultId].publicVault && (_as.vaultParticipants[vaultId][i].paid - amount) < _as.vaultsExtensions[vaultId].minimumFunding) {
                    // This is a public vault and there is minimum funding
                    // The participant is asking to withdraw amount that will cause their total funding
                    // to be less than the minimum amount. Returning all funds and removing from vault
                    amount = _as.vaultParticipants[vaultId][i].paid;
                }
                _as.vaultParticipants[vaultId][i].paid -= amount;
                IAssetsHolderImpl(_as.assetsHolders[vaultId]).sendValue(payable(_as.vaultParticipants[vaultId][i].participant), amount);
                if (_as.vaultParticipants[vaultId][i].paid == 0 && _as.vaultsExtensions[vaultId].publicVault) {
                    // Removing participant from public vault
                    _removeParticipant(vaultId, i);
                }
                emit FundsWithdrawn(vaultId, msg.sender, amount);
                break;
            }
        }
    }

    // ==================== views ====================

    function assetsHolders(uint256 vaultId) external view returns (address) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return _as.assetsHolders[vaultId];
    }

    function vaults(uint256 vaultId) external view returns (LibDiamond.Vault memory) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return _as.vaults[vaultId];
    }

    function vaultTokens(uint256 vaultId) external view returns (uint256) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return _as.vaultTokens[vaultId];
    }

    function vaultsExtensions(uint256 vaultId) external view returns (LibDiamond.VaultExtension memory) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return _as.vaultsExtensions[vaultId];
    }

    function liquidityWallet() external view returns (address) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return _as.liquidityWallet;
    }

    function stakingWallet() external view returns (address) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return _as.stakingWallet;
    }

    function getVaultParticipants(uint256 vaultId) external view returns (LibDiamond.Participant[] memory) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        LibDiamond.Participant[] memory participants = new LibDiamond.Participant[](_as.vaultParticipantsAddresses[vaultId].length);
        for (uint256 i; i < participants.length; i++) {
            participants[i] = _as.vaultParticipants[vaultId][i];
        }
        return participants;
    }

    function getParticipantPercentage(uint256 vaultId, uint256 participantIndex) external view returns (uint256) {
        return _getPercentage(vaultId, participantIndex, 0);
    }

    function getTokenPercentage(uint256 tokenId) external view returns (uint256) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return _getPercentage(_as.vaultTokens[tokenId], 0, tokenId);
    }

    // ==================== Internals ====================

    /*
        @dev
        A helper function to remove element from array and reduce array size
    */
    function _removeParticipant(uint256 vaultId, uint256 index) internal {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        address[] storage participants = _as.vaultParticipantsAddresses[vaultId];
        _as.vaultParticipants[vaultId][index] = _as.vaultParticipants[vaultId][participants.length - 1];
        delete _as.vaultParticipants[vaultId][participants.length - 1];
        participants[index] = participants[participants.length - 1];
        participants.pop();
    }

    /*
        @dev
        Internal vote method to update participant vote, reset grace period if needed and emit an event
    */
    function _vote(uint256 vaultId, LibDiamond.Participant storage participant, bool yes, LibDiamond.VoteFor voteFor) internal {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        participant.vote = yes;
        if (voteFor == LibDiamond.VoteFor.Buying) {
            emit VotedForBuy(vaultId, participant.participant, yes, _as.vaults[vaultId].collection, _as.vaults[vaultId].tokenId);
        } else {
            // Resetting the grace period but only if this is the first vote
            // First time setting a listing price, voting to cancel a sell order or voting on a listing price
            // after the sell order was cancelled, the grace period will be reset
            bool firstProposalVote = true;
            address[] memory participants = _as.vaultParticipantsAddresses[vaultId];
            for (uint256 i; i < participants.length; i++) {
                if (_as.vaultParticipants[vaultId][i].voted) {
                    firstProposalVote = false;
                    break;
                }
            }
            if (firstProposalVote) {
                // Resetting the end of grace period, after that date all undecided (un-voted) votes are considered as yes
                _as.vaults[vaultId].endGracePeriodForSellingOrCancellingSellOrder = block.timestamp + _as.vaults[vaultId].gracePeriodForSellingOrCancellingSellOrder;
            }
            if (voteFor == LibDiamond.VoteFor.Selling) {
                emit VotedForSell(vaultId, participant.participant, yes, _as.vaults[vaultId].collection, _as.vaults[vaultId].tokenId, _as.vaults[vaultId].listFor);
            } else if (voteFor == LibDiamond.VoteFor.CancellingSellOrder) {
                emit VotedForCancel(vaultId, participant.participant, yes, _as.vaults[vaultId].collection, _as.vaults[vaultId].tokenId, _as.vaults[vaultId].listFor);
            }
        }
        participant.voted = true;
    }

    // =========== Salvage ===========

    /*
        @dev
        Sends stuck ERC721 tokens to the owner.
        This is just in case someone sends in mistake tokens to this contract.
        Reminder, the asset holder contract is the one that holds the ETH and tokens
    */
    function salvageERC721Token(address collection, uint256 tokenId) external onlyOwner {
        IERC721(collection).safeTransferFrom(address(this), owner(), tokenId);
    }

    /*
        @dev
        Sends stuck ETH to the owner.
        This is just in case someone sends in mistake ETH to this contract.
        Reminder, the asset holder contract is the one that holds the ETH and tokens
    */
    function salvageETH() external onlyOwner {
        if (address(this).balance > 0) {
            Address.sendValue(payable(owner()), address(this).balance);
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/*

████████╗██╗  ██╗███████╗     ██████╗ ██████╗ ██╗     ██╗     ███████╗ ██████╗████████╗ ██████╗ ██████╗ ███████╗
╚══██╔══╝██║  ██║██╔════╝    ██╔════╝██╔═══██╗██║     ██║     ██╔════╝██╔════╝╚══██╔══╝██╔═══██╗██╔══██╗██╔════╝
   ██║   ███████║█████╗      ██║     ██║   ██║██║     ██║     █████╗  ██║        ██║   ██║   ██║██████╔╝███████╗
   ██║   ██╔══██║██╔══╝      ██║     ██║   ██║██║     ██║     ██╔══╝  ██║        ██║   ██║   ██║██╔══██╗╚════██║
   ██║   ██║  ██║███████╗    ╚██████╗╚██████╔╝███████╗███████╗███████╗╚██████╗   ██║   ╚██████╔╝██║  ██║███████║
   ╚═╝   ╚═╝  ╚═╝╚══════╝     ╚═════╝ ╚═════╝ ╚══════╝╚══════╝╚══════╝ ╚═════╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚══════╝

███╗   ██╗███████╗████████╗    ██╗   ██╗ █████╗ ██╗   ██╗██╗  ████████╗
████╗  ██║██╔════╝╚══██╔══╝    ██║   ██║██╔══██╗██║   ██║██║  ╚══██╔══╝
██╔██╗ ██║█████╗     ██║       ██║   ██║███████║██║   ██║██║     ██║
██║╚██╗██║██╔══╝     ██║       ╚██╗ ██╔╝██╔══██║██║   ██║██║     ██║
██║ ╚████║██║        ██║        ╚████╔╝ ██║  ██║╚██████╔╝███████╗██║
╚═╝  ╚═══╝╚═╝        ╚═╝         ╚═══╝  ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝

██████╗  █████╗ ███████╗███████╗    ███████╗ █████╗  ██████╗███████╗████████╗
██╔══██╗██╔══██╗██╔════╝██╔════╝    ██╔════╝██╔══██╗██╔════╝██╔════╝╚══██╔══╝
██████╔╝███████║███████╗█████╗      █████╗  ███████║██║     █████╗     ██║
██╔══██╗██╔══██║╚════██║██╔══╝      ██╔══╝  ██╔══██║██║     ██╔══╝     ██║
██████╔╝██║  ██║███████║███████╗    ██║     ██║  ██║╚██████╗███████╗   ██║
╚═════╝ ╚═╝  ╚═╝╚══════╝╚══════╝    ╚═╝     ╚═╝  ╚═╝ ╚═════╝╚══════╝   ╚═╝

*/

import "../Imports.sol";
import "../Interfaces.sol";
import "../LibDiamond.sol";

/*
    @dev
    This is the base contract that the main contract and the assets manager are inheriting from
*/
abstract contract TheCollectorsNFTVaultBaseFacet is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // ==================== Events ====================

    event VaultCreated(uint256 indexed vaultId, address indexed collection, bool indexed privateVault);
    event ParticipantJoinedVault(uint256 indexed vaultId, address indexed participant);
    event NFTTokenWasSet(uint256 indexed vaultId, address indexed collection, uint256 indexed tokenId, uint256 maxPrice);
    event ListingPriceWasSet(uint256 indexed vaultId, address indexed collection, uint256 indexed tokenId, uint256 price);
    event VaultWasFunded(uint256 indexed vaultId, address indexed participant, uint256 indexed amount);
    event FundsWithdrawn(uint256 indexed vaultId, address indexed participant, uint256 indexed amount);
    event VaultTokenRedeemed(uint256 indexed vaultId, address indexed participant, uint256 indexed tokenId);
    event CollectorStaked(uint256 indexed vaultId, address indexed participant, uint256 indexed stakedCollectorTokenId);
    event CollectorUnstaked(uint256 indexed vaultId, address indexed participant, uint256 indexed stakedCollectorTokenId);
    event VaultTokenClaimed(uint256 indexed vaultId, address indexed participant, uint256 indexed tokenId);
    event NFTPurchased(uint256 indexed vaultId, address indexed collection, uint256 indexed tokenId, uint256 price);
    event NFTMigrated(uint256 indexed vaultId, address indexed collection, uint256 indexed tokenId, uint256 price);
    event NFTListedForSale(uint256 indexed vaultId, address indexed collection, uint256 indexed tokenId, uint256 price);
    event NFTSellOrderCanceled(uint256 indexed vaultId, address indexed collection, uint256 indexed tokenId);
    event VotedForBuy(uint256 indexed vaultId, address indexed participant, bool indexed vote, address collection, uint256 tokenId);
    event VotedForSell(uint256 indexed vaultId, address indexed participant, bool indexed vote, address collection, uint256 tokenId, uint256 price);
    event VotedForCancel(uint256 indexed vaultId, address indexed participant, bool indexed vote, address collection, uint256 tokenId, uint256 price);
    event NFTSold(uint256 indexed vaultId, address indexed collection, uint256 indexed tokenId, uint256 price);

    // ==================== Views ====================

    /*
        @dev
        A helper function to make sure there is a selling/cancelling consensus
    */
    function isVaultPassedSellOrCancelSellOrderConsensus(uint256 vaultId) public view returns (bool) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        address[] memory participants = _as.vaultParticipantsAddresses[vaultId];
        uint256 votesPercentage;
        for (uint256 i; i < participants.length; i++) {
            // Either the participate voted yes for selling or the participate didn't vote at all
            // and the grace period was passed
            votesPercentage += _getParticipantSellOrCancelSellOrderVote(vaultId, i)
            ? _getPercentage(vaultId, i, 0) : 0;
        }

        // Need to check if equals too in case the sell consensus is 100%
        // Adding 1 wei since votesPercentage cannot be exactly 100%
        // Dividing by 1e6 to soften the threshold (but still very precise)
        return votesPercentage / 1e6 + 1 wei >= _as.vaults[vaultId].sellOrCancelSellOrderConsensus / 1e6;
    }

    function isVaultSoldNFT(uint256 vaultId) public view returns (bool) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        // Only vaults that are in "asset was listed" stage can sell their asset
        if (_as.vaults[vaultId].votingFor != LibDiamond.VoteFor.CancellingSellOrder) {
            return false;
        }
        if (_as.vaultsExtensions[vaultId].isERC1155) {
            return IERC1155(_as.vaults[vaultId].collection).balanceOf(_as.assetsHolders[vaultId], _as.vaults[vaultId].tokenId) == 0;
        } else {
            return IERC721(_as.vaults[vaultId].collection).ownerOf(_as.vaults[vaultId].tokenId) != _as.assetsHolders[vaultId];
        }
    }

    // ==================== Internals ====================

    /*
        @dev
        A helper function to verify that the vault is in buying state
    */
    function _requireVotingForBuyingOrWaitingForSettingTokenInfo(uint256 vaultId) internal view {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        require(_as.vaults[vaultId].votingFor == LibDiamond.VoteFor.Buying || _as.vaults[vaultId].votingFor == LibDiamond.VoteFor.WaitingToSetTokenInfo, "E1");
    }

    /*
        @dev
        A helper function to determine if a participant voted for selling or cancelling order
        or haven't voted yet but the grace period passed
    */
    function _getParticipantSellOrCancelSellOrderVote(uint256 vaultId, uint256 participantIndex) internal view returns (bool) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return _as.vaultParticipants[vaultId][participantIndex].vote
        || (!_as.vaultParticipants[vaultId][participantIndex].voted
        && _as.vaults[vaultId].endGracePeriodForSellingOrCancellingSellOrder != 0
        && block.timestamp > _as.vaults[vaultId].endGracePeriodForSellingOrCancellingSellOrder);
    }

    /*
        @dev
        A helper function to find out if a participant is part of a vault
    */
    function _isParticipantExists(uint256 vaultId, address participant) internal view returns (bool) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        address[] memory participants = _as.vaultParticipantsAddresses[vaultId];
        for (uint256 i; i < participants.length; i++) {
            if (_as.vaultParticipants[vaultId][i].participant == participant) {
                return true;
            }
        }
        return false;
    }

    /*
        @dev
        A helper function to reset votes and grace period after listing for sale or cancelling a sell order
    */
    function _resetVotesAndGracePeriod(uint256 vaultId) internal {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        _as.vaults[vaultId].endGracePeriodForSellingOrCancellingSellOrder = 0;
        address[] memory participants = _as.vaultParticipantsAddresses[vaultId];
        for (uint256 i; i < participants.length; i++) {
            // Resetting votes
            _as.vaultParticipants[vaultId][i].vote = false;
            _as.vaultParticipants[vaultId][i].voted = false;
        }
    }

    /*
        @dev
        A helper function to calculate a participate or token id % in the vault.
        This function can be called before/after buying/selling the NFT
        Since tokenId cannot be 0 (as we are starting it from 1) it is ok to assume that if tokenId 0 was sent
        the method should return the participant %.
        In case address 0 was sent, the method will calculate the tokenId %.
    */
    function _getPercentage(uint256 vaultId, uint256 participantIndex, uint256 tokenId) internal view returns (uint256) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        uint256 totalPaid;
        uint256 participantsPaid;
        address[] memory participants = _as.vaultParticipantsAddresses[vaultId];
        for (uint256 i; i < participants.length; i++) {
            totalPaid += _as.vaultParticipants[vaultId][i].paid;
            if ((tokenId == 0 && i == participantIndex)
                || (tokenId != 0 && _as.vaultParticipants[vaultId][i].partialNFTVaultTokenId == tokenId)) {
                // Found participant or token
                if (_as.vaults[vaultId].votingFor == LibDiamond.VoteFor.Selling || _as.vaults[vaultId].votingFor == LibDiamond.VoteFor.CancellingSellOrder) {
                    // Vault purchased the NFT
                    return _as.vaultParticipants[vaultId][i].ownership;
                }
                participantsPaid = _as.vaultParticipants[vaultId][i].paid;
            }
        }

        if (_as.vaults[vaultId].votingFor == LibDiamond.VoteFor.Selling || _as.vaults[vaultId].votingFor == LibDiamond.VoteFor.CancellingSellOrder) {
            // Vault purchased the NFT but participant or token that does not exist
            return 0;
        }

        // NFT wasn't purchased yet

        if (totalPaid > 0) {
            // Calculating % based on total paid
            return participantsPaid * 1e18 * 100 / totalPaid;
        } else {
            // No one paid, splitting equally
            return 1e18 * 100 / participants.length;
        }
    }

    /*
        @dev
        A helper function to make sure there is a buying consensus and that the purchase price is
        lower than the total ETH paid and the max price to buy
    */
    function _requireBuyConsensusAndValidatePurchasePrice(uint256 vaultId, uint256 purchasePrice) internal view {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        require(_as.vaults[vaultId].votingFor == LibDiamond.VoteFor.Buying, "E1");
        address[] memory participants = _as.vaultParticipantsAddresses[vaultId];
        uint256 totalPaid;
        for (uint256 i; i < participants.length; i++) {
            totalPaid += _as.vaultParticipants[vaultId][i].paid;
        }
        require(purchasePrice <= totalPaid && purchasePrice <= _as.vaultsExtensions[vaultId].maxPriceToBuy, "E2");
        uint256 votesPercentage;
        for (uint256 i; i < participants.length; i++) {
            votesPercentage += _as.vaultParticipants[vaultId][i].vote ? _getPercentage(vaultId, i, 0) : 0;
        }
        // Need to check if equals too in case the buying consensus is 100%
        // Adding 1 wei since votesPercentage cannot be exactly 100%
        // Dividing by 1e6 to soften the threshold (but still very precise)
        require(votesPercentage / 1e6 + 1 wei >= _as.vaults[vaultId].buyConsensus / 1e6, "E3");
    }

    /*
        @dev
        A helper function to validate whatever the vault is actually purchased the token and to calculate the final
        ownership of each participant
    */
    function _afterPurchaseNFT(uint256 vaultId, uint256 purchasePrice, bool withEvent) internal {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        address[] memory participants = _as.vaultParticipantsAddresses[vaultId];
        uint256 totalPaid;
        for (uint256 i; i < participants.length; i++) {
            totalPaid += _as.vaultParticipants[vaultId][i].paid;
        }
        // Cannot be below zero because otherwise the buying would have failed
        uint256 leftovers = totalPaid - purchasePrice;
        for (uint256 i; i < participants.length; i++) {
            if (totalPaid > 0) {
                _as.vaultParticipants[vaultId][i].leftovers = leftovers * _as.vaultParticipants[vaultId][i].paid / totalPaid;
            } else {
                // If totalPaid = 0 then returning all what the participant paid
                // This can happen if everyone withdraws their funds after voting yes
                _as.vaultParticipants[vaultId][i].leftovers = _as.vaultParticipants[vaultId][i].paid;
            }
            if (totalPaid > 0) {
                // Calculating % based on total paid
                _as.vaultParticipants[vaultId][i].ownership = _as.vaultParticipants[vaultId][i].paid * 1e18 * 100 / totalPaid;
            } else {
                // No one paid, splitting equally
                // This can happen if everyone withdraws their funds after voting yes
                _as.vaultParticipants[vaultId][i].ownership = 1e18 * 100 / participants.length;
            }
            _as.vaultParticipants[vaultId][i].paid = _as.vaultParticipants[vaultId][i].paid - _as.vaultParticipants[vaultId][i].leftovers;
            // Resetting vote so the participate will be able to vote for setListingPrice
            _as.vaultParticipants[vaultId][i].vote = false;
            _as.vaultParticipants[vaultId][i].voted = false;
        }

        LibDiamond.Vault storage vault = _as.vaults[vaultId];
        if (_as.vaultsExtensions[vaultId].isERC1155) {
            // If it was == 1, then it was open to attacks
            require(IERC1155(vault.collection).balanceOf(_as.assetsHolders[vaultId], vault.tokenId) > 0, "E4");
        } else {
            require(IERC721(vault.collection).ownerOf(vault.tokenId) == _as.assetsHolders[vaultId], "E4");
        }
        vault.votingFor = LibDiamond.VoteFor.Selling;
        // Since participate.paid is updating and re-calculated after buying the NFT the sum of all participants paid
        // can be a little different from the actual purchase price, however, it should never be more than purchasedFor
        // in order to not get insufficient funds exception
        vault.purchasedFor = purchasePrice;
        if (withEvent) {
            emit NFTPurchased(vault.id, vault.collection, vault.tokenId, purchasePrice);
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/proxy/Proxy.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IOpenseaExchange {
    function atomicMatch_(
        address[14] memory addrs,
        uint[18] memory uints,
        uint8[8] memory feeMethodsSidesKindsHowToCalls,
        bytes memory calldataBuy,
        bytes memory calldataSell,
        bytes memory replacementPatternBuy,
        bytes memory replacementPatternSell,
        bytes memory staticExtradataBuy,
        bytes memory staticExtradataSell,
        uint8[2] memory vs,
        bytes32[5] memory rssMetadata
    ) external payable;

    function approveOrder_(
        address[7] memory addrs,
        uint[9] memory uints,
        uint8 feeMethod,
        uint8 side,
        uint8 saleKind,
        uint8 howToCall,
        bytes memory _calldata,
        bytes memory replacementPattern,
        bytes memory staticExtradata,
        bool orderbookInclusionDesired
    ) external;

    function cancelOrder_(
        address[7] memory addrs,
        uint[9] memory uints,
        uint8 feeMethod,
        uint8 side,
        uint8 saleKind,
        uint8 howToCall,
        bytes memory _calldata,
        bytes memory replacementPattern,
        bytes memory staticExtradata,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function validateOrder_(
        address[7] memory addrs,
        uint[9] memory uints,
        uint8 feeMethod,
        uint8 side,
        uint8 saleKind,
        uint8 howToCall,
        bytes memory _calldata,
        bytes memory replacementPattern,
        bytes memory staticExtradata,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (bool);
}

interface IApproveableNFT {
    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface IProxyRegistry {
    function registerProxy() external returns (address);

    function proxies(address seller) external view returns (address);
}

interface IAssetsHolderCreator {
    function createNFTVaultAssetsHolder(uint256 vaultId) external;
}

interface IAssetsHolderImpl {
    function transferToken(bool isERC1155, address recipient, address collection, uint256 tokenId) external;

    function sendValue(address payable to, uint256 amount) external;
}

interface INFTTokenTransferHandler {
    function transferNFTVaultToken(address from, address to, uint256 tokenId) external;

    function isNFTApprovedForAll(address owner, address operator) external returns (bool);
}

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamond Standard: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamond Standard: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

// A loupe is a small magnifying glass used to look at diamonds.
// These functions look at diamonds
interface IDiamondLoupe {
    /// These functions are expected to be called frequently
    /// by tools.

    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return facets_ Facet
    function facets() external view returns (Facet[] memory facets_);

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external view returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamond Standard: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import "./Interfaces.sol";
import "./Imports.sol";

library LibDiamond {

    // ==================== Diamond Constants ====================

    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");
    bytes32 constant APP_STORAGE_POSITION = keccak256("diamond.standard.app.storage");

    // ==================== Constants ====================

    uint256 public constant LIQUIDITY_FEE = 50; // 0.5%
    uint256 public constant STAKING_FEE = 200; // 2%
    uint256 public constant PERCENTAGE_DENOMINATOR = 10000;
    // Participant can stake a collector to not pay protocol fee
    IERC721 public constant THE_COLLECTORS = IERC721(0x4f35a6D8423fADD1BFb30aaE589AF136eCF91e77);
    IOpenseaExchange public constant OPENSEA_EXCHANGE = IOpenseaExchange(0x7f268357A8c2552623316e2562D90e642bB538E5);
    IProxyRegistry public constant OPENSEA_PROXY_REGISTRY = IProxyRegistry(0xa5409ec958C83C3f309868babACA7c86DCB077c1);

    // ==================== Structs ====================

    // Represents 1 participant of an NFT vault
    struct Participant {
        address participant;
        // How much the participant funded the vault
        // This number will be reduced after buying the NFT in case total paid was higher than purchase price
        uint256 paid;
        // In case total paid was higher than purchase price, how much the participant will get back
        uint256 leftovers;
        // Whatever the participant voted for or against buying/selling/cancelling order
        // Depends on vault.votingFor
        // Waiting (can't vote), Buying (voting to buy), Selling (voting to sell), Cancelling (voting to cancel order)
        bool vote;
        // Who is the owner of the staked collector. In a situation where the participant sold his seat in the vault,
        // the collector will be staked until the token the vault bought is sold and the participant redeemed
        // the partial NFT
        address collectorOwner;
        // The staked collector token id
        uint256 stakedCollectorTokenId;
        // The token id of the partial NFT
        // In case a vault with 4 participants bought BAYC, 4 partials NFTs will be minted respectively
        uint256 partialNFTVaultTokenId;
        // Indicates whatever this participant voted
        // This will be used to determine if to count their vote, if the grace period for voting has ended
        bool voted;
        // The ownership percentage of this participant in the vault
        // This property will be calculated only after purchasing
        uint256 ownership;
    }

    // Represents whatever the voting is for buying, selling or cancelling sell order
    enum VoteFor {
        WaitingToSetTokenInfo,
        Buying,
        Selling,
        CancellingSellOrder
    }

    // Represents 1 NFT vault that acts as a small DAO and can buy and sell NFTs on any marketplace
    struct Vault {
        // The unique identifier of the vault
        uint256 id;
        // The name of the vault
        string name;
        // From which collection this NFT vault can buy/sell, this cannot be changed after creating the vault
        address collection;
        // The token id that the vault is planning to buy, or already bought, or listing for sale
        // This variable can be changed while the DAO is considering which token id to buy,
        // however, after purchasing, this value will not change
        uint256 tokenId;
        // Whatever the voting (stage of the vault is) for buying the NFT, selling it
        // or cancelling the sell order (to relist it again with a different price)
        VoteFor votingFor;
        // The cost of the NFT bought by the vault
        uint256 purchasedFor;
        // The amount of ETH to list the token for sale
        // After this is set, the participates are voting for or against list the NFT for sale in this price
        uint256 listFor;
        // How much % of ownership needed to decide if to sell or cancel a sell order
        // Please notice that in case a participant did not vote and the
        // endGracePeriodForSellingOrCancellingSellOrder is over their vote will be considered as yes
        uint256 sellOrCancelSellOrderConsensus;
        // How much % fees goes to the marketplace and collection owner
        // We need this in order to know how much ETH we can split among the participants
        // i.e ETH was sold for 20 ETH and the fees for the marketplace and collection owner are 5%
        // then the split amount is 19 ETH
        uint256 marketplaceAndRoyaltiesFees;
        // How much % of ownership needed to decide if to buy or not
        uint256 buyConsensus;
        // How much time to give participants to vote for selling before considering their votes as yes
        uint256 gracePeriodForSellingOrCancellingSellOrder;
        // The end date of the grace period given for participates to vote on selling before considering their votes as yes
        uint256 endGracePeriodForSellingOrCancellingSellOrder;
        // The maximum amount of participant that can join the vault
        uint256 maxParticipants;
    }

    // To avoid stack too deep
    struct VaultExtension {
        // Whatever the vault is public or not
        // There are specific limitations for public vault like minimum funding must
        // be above 0 and cannot change collection
        bool publicVault;
        // The minimum amount that a participant should fund the vault
        uint256 minimumFunding;
        // The absolute max price the vault can pay to buy the asset
        uint256 maxPriceToBuy;
        // Whatever the collection is ERC721 or ERC1155
        bool isERC1155;
        // Whatever the collection was migrated
        bool isMigrated;
    }

    struct FacetAddressAndPosition {
        address facetAddress;
        uint16 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint16 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
    }

    struct AppStorage {
        address liquidityWallet;
        address stakingWallet;
        address royaltiesRecipient;
        uint256 royaltiesBasisPoints;
        mapping(uint256 => Vault) vaults;
        mapping(uint256 => uint256) vaultTokens;
        mapping(uint256 => address payable) assetsHolders;
        mapping(uint256 => VaultExtension) vaultsExtensions;
        mapping(uint256 => address[]) vaultParticipantsAddresses;
        mapping(uint256 => mapping(uint256 => Participant)) vaultParticipants;
        address nftVaultAssetHolderImpl;
        address nftVaultAssetsHolderCreator;
        address nftVaultTokenTransferHandler;
        Counters.Counter tokenIdTracker;
        Counters.Counter vaultIdTracker;
        string baseTokenURI;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function appStorage() internal pure returns (AppStorage storage _as) {
        bytes32 position = APP_STORAGE_POSITION;
        assembly {
            _as.slot := position
        }
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        // uint16 selectorCount = uint16(diamondStorage().selectors.length);
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint16 selectorPosition = uint16(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
            ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = uint16(ds.facetAddresses.length);
            ds.facetAddresses.push(_facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(selector);
            ds.selectorToFacetAndPosition[selector].facetAddress = _facetAddress;
            ds.selectorToFacetAndPosition[selector].functionSelectorPosition = selectorPosition;
            selectorPosition++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint16 selectorPosition = uint16(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
            ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = uint16(ds.facetAddresses.length);
            ds.facetAddresses.push(_facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
            removeFunction(oldFacetAddress, selector);
            // add function
            ds.selectorToFacetAndPosition[selector].functionSelectorPosition = selectorPosition;
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(selector);
            ds.selectorToFacetAndPosition[selector].facetAddress = _facetAddress;
            selectorPosition++;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(oldFacetAddress, selector);
        }
    }

    function removeFunction(address _facetAddress, bytes4 _selector) internal {
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
        // an immutable function is a function defined directly in a diamond
        require(_facetAddress != address(this), "LibDiamondCut: Can't remove immutable function");
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint16(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = uint16(facetAddressPosition);
            }
            ds.facetAddresses.pop();
            delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

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
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
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
        address owner = ERC721.ownerOf(tokenId);
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
        address owner = ERC721.ownerOf(tokenId);
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

        _afterTokenTransfer(address(0), to, tokenId);
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
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
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
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
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

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
     * exchange. The royalty amount is denominated and should be payed in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}