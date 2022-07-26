// SPDX-License-Identifier: UNLICENSED
// © 2022 The Collectors. All rights reserved.
pragma solidity ^0.8.13;

import "./facets/TheCollectorsNFTVaultBaseFacet.sol";
import "./facets/TheCollectorsNFTVaultLogicFacet.sol";
import "./facets/TheCollectorsNFTVaultAssetsManagerFacet.sol";
import "./facets/TheCollectorsNFTVaultSeaportManagerFacet.sol";
import "./facets/TheCollectorsNFTVaultTokenManagerFacet.sol";
import "./facets/TheCollectorsNFTVaultDiamondCutAndLoupeFacet.sol";
import "./LibDiamond.sol";

/*
    ████████╗██╗  ██╗███████╗
    ╚══██╔══╝██║  ██║██╔════╝
       ██║   ███████║█████╗
       ██║   ██╔══██║██╔══╝
       ██║   ██║  ██║███████╗
       ╚═╝   ╚═╝  ╚═╝╚══════╝
     ██████╗ ██████╗ ██╗     ██╗     ███████╗ ██████╗████████╗ ██████╗ ██████╗ ███████╗
    ██╔════╝██╔═══██╗██║     ██║     ██╔════╝██╔════╝╚══██╔══╝██╔═══██╗██╔══██╗██╔════╝
    ██║     ██║   ██║██║     ██║     █████╗  ██║        ██║   ██║   ██║██████╔╝███████╗
    ██║     ██║   ██║██║     ██║     ██╔══╝  ██║        ██║   ██║   ██║██╔══██╗╚════██║
    ╚██████╗╚██████╔╝███████╗███████╗███████╗╚██████╗   ██║   ╚██████╔╝██║  ██║███████║
     ╚═════╝ ╚═════╝ ╚══════╝╚══════╝╚══════╝ ╚═════╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚══════╝
    ███╗   ██╗███████╗████████╗    ██╗   ██╗ █████╗ ██╗   ██╗██╗  ████████╗
    ████╗  ██║██╔════╝╚══██╔══╝    ██║   ██║██╔══██╗██║   ██║██║  ╚══██╔══╝
    ██╔██╗ ██║█████╗     ██║       ██║   ██║███████║██║   ██║██║     ██║
    ██║╚██╗██║██╔══╝     ██║       ╚██╗ ██╔╝██╔══██║██║   ██║██║     ██║
    ██║ ╚████║██║        ██║        ╚████╔╝ ██║  ██║╚██████╔╝███████╗██║
    ╚═╝  ╚═══╝╚═╝        ╚═╝         ╚═══╝  ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝
    @title
    The collectors NFT Vault is the first fully decentralized product that allows a group of people to handle
    together the lifecycle of an NFT and all while using any marketplace (including Opensea).
    The big different between this protocol and others is it was built for NFT people by NFT people.
    @dev
    This contract is using the very robust and innovative EIP 2535 (https://eips.ethereum.org/EIPS/eip-2535) which
    allows a contract to be organized in the most efficient way
*/
contract TheCollectorsNFTVaultDiamond is Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    constructor(
        string memory __baseTokenURI,
        address _logicFacetAddress,
        address _assetsManagerFacetAddress,
        address _seaportManagerFacetAddress,
        address _vaultTokenManagerFacetAddress,
        address _diamondCutAndLoupeFacetAddress,
        address __nftVaultAssetHolderImpl,
        address[3] memory addresses
    ) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        // Moving tracker to 1 so we can use 0 to indicate that user doesn't have any tokens
        _as.tokenIdTracker.increment();
        // The base uri of the tokens
        _as.baseTokenURI = __baseTokenURI;
        // The implementation for asset holder. Is used to significantly reduce the creation cost of a new vault
        // Everytime a new marketplace will be added, the implementation will change
        _as.nftVaultAssetHolderImpl = __nftVaultAssetHolderImpl;
        _as.liquidityWallet = addresses[0];
        _as.stakingWallet = addresses[1];
        _as.royaltiesRecipient = addresses[2];
        _as.royaltiesBasisPoints = 250;
        _as.nftVaultTokenHandler = _vaultTokenManagerFacetAddress;
        _as.seaportAddress = 0x00000000006c3852cbEf3e08E8dF289169EdE581;
        _as.openseaFeeRecipients = [
            0x5b3256965e7C3cF26E11FCAf296DfC8807C01073,
            0x8De9C5A032463C561423387a9648c5C7BCC5BC90
        ];

        // Adding all logic functions
        LibDiamond.addFunctions(_logicFacetAddress, _getLogicFacetSelectors());
        // Adding all assets manager functions
        LibDiamond.addFunctions(_assetsManagerFacetAddress, _getAssetsManagerFacetSelectors());
        // Adding all Seaport manager functions
        // In the future more marketplaces will be added
        LibDiamond.addFunctions(_seaportManagerFacetAddress, _getSeaportManagerFacetSelectors());
        // Adding all NFT vault token functions
        LibDiamond.addFunctions(_vaultTokenManagerFacetAddress, _getNFTVaultTokenManagerFacetSelectors());
        // Adding all diamond cut and loupe functions
        LibDiamond.addFunctions(_diamondCutAndLoupeFacetAddress, _getDiamondCutAndLoupeFacetSelectors());
    }

    // =========== Diamond ===========

    /*
        @dev
        Adding all functions of logic facet
    */
    function _getLogicFacetSelectors() internal pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](21);
        selectors[0] = TheCollectorsNFTVaultLogicFacet.setLiquidityWallet.selector;
        selectors[1] = TheCollectorsNFTVaultLogicFacet.setStakingWallet.selector;
        selectors[2] = TheCollectorsNFTVaultLogicFacet.createVault.selector;
        selectors[3] = TheCollectorsNFTVaultLogicFacet.joinPublicVault.selector;
        selectors[4] = TheCollectorsNFTVaultLogicFacet.addParticipant.selector;
        selectors[5] = TheCollectorsNFTVaultLogicFacet.setTokenInfoAndMaxBuyPrice.selector;
        selectors[6] = TheCollectorsNFTVaultLogicFacet.setListingPrice.selector;
        selectors[7] = TheCollectorsNFTVaultLogicFacet.vote.selector;
        selectors[8] = TheCollectorsNFTVaultLogicFacet.fundVault.selector;
        selectors[9] = TheCollectorsNFTVaultLogicFacet.withdrawFunds.selector;
        selectors[10] = TheCollectorsNFTVaultLogicFacet.assetsHolders.selector;
        selectors[11] = TheCollectorsNFTVaultLogicFacet.vaults.selector;
        selectors[12] = TheCollectorsNFTVaultLogicFacet.vaultTokens.selector;
        selectors[13] = TheCollectorsNFTVaultLogicFacet.vaultsExtensions.selector;
        selectors[14] = TheCollectorsNFTVaultLogicFacet.liquidityWallet.selector;
        selectors[15] = TheCollectorsNFTVaultLogicFacet.stakingWallet.selector;
        selectors[16] = TheCollectorsNFTVaultLogicFacet.getVaultParticipants.selector;
        selectors[17] = TheCollectorsNFTVaultLogicFacet.getParticipantPercentage.selector;
        selectors[18] = TheCollectorsNFTVaultLogicFacet.getTokenPercentage.selector;
        selectors[19] = TheCollectorsNFTVaultLogicFacet.salvageERC721Token.selector;
        selectors[20] = TheCollectorsNFTVaultLogicFacet.salvageETH.selector;
        return selectors;
    }

    /*
        @dev
        Adding all functions of assets manager facet
    */
    function _getAssetsManagerFacetSelectors() internal pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](7);
        selectors[0] = TheCollectorsNFTVaultAssetsManagerFacet.migrate.selector;
        selectors[1] = TheCollectorsNFTVaultAssetsManagerFacet.buyNFTFromVault.selector;
        selectors[2] = TheCollectorsNFTVaultAssetsManagerFacet.sellNFTToVault.selector;
        selectors[3] = TheCollectorsNFTVaultAssetsManagerFacet.unstakeCollector.selector;
        selectors[4] = TheCollectorsNFTVaultAssetsManagerFacet.stakeCollector.selector;
        selectors[5] = TheCollectorsNFTVaultAssetsManagerFacet.withdrawNFTToOwner.selector;
        selectors[6] = TheCollectorsNFTVaultAssetsManagerFacet.validateSale.selector;
        return selectors;
    }

    /*
        @dev
        Adding all functions of opensea manager facet
    */
    function _getSeaportManagerFacetSelectors() internal pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](8);
        selectors[0] = TheCollectorsNFTVaultSeaportManagerFacet.buyNFTOnSeaport.selector;
        selectors[1] = TheCollectorsNFTVaultSeaportManagerFacet.buyAdvancedNFTOnSeaport.selector;
        selectors[2] = TheCollectorsNFTVaultSeaportManagerFacet.buyMatchedNFTOnSeaport.selector;
        selectors[3] = TheCollectorsNFTVaultSeaportManagerFacet.listNFTOnSeaport.selector;
        selectors[4] = TheCollectorsNFTVaultSeaportManagerFacet.cancelNFTListingOnSeaport.selector;
        selectors[5] = TheCollectorsNFTVaultSeaportManagerFacet.setOpenseaFeeRecipients.selector;
        selectors[6] = TheCollectorsNFTVaultSeaportManagerFacet.setSeaportAddress.selector;
        selectors[7] = TheCollectorsNFTVaultBaseFacet.isVaultPassedSellOrCancelSellOrderConsensus.selector;
        return selectors;
    }

    /*
        @dev
        Adding all functions of opensea manager facet
    */
    function _getNFTVaultTokenManagerFacetSelectors() internal pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](22);
        selectors[0] = TheCollectorsNFTVaultTokenManagerFacet.claimVaultTokenAndGetLeftovers.selector;
        selectors[1] = TheCollectorsNFTVaultTokenManagerFacet.redeemToken.selector;
        selectors[2] = TheCollectorsNFTVaultTokenManagerFacet.setRoyaltiesRecipient.selector;
        selectors[3] = TheCollectorsNFTVaultTokenManagerFacet.royaltiesRecipient.selector;
        selectors[4] = TheCollectorsNFTVaultTokenManagerFacet.setRoyaltiesBasisPoints.selector;
        selectors[5] = TheCollectorsNFTVaultTokenManagerFacet.royaltiesBasisPoints.selector;
        selectors[6] = TheCollectorsNFTVaultTokenManagerFacet.royaltyInfo.selector;
        selectors[7] = TheCollectorsNFTVaultTokenManagerFacet.getCollectionOwnership.selector;
        selectors[8] = TheCollectorsNFTVaultTokenManagerFacet.setBaseTokenURI.selector;
        selectors[9] = IERC721.balanceOf.selector;
        selectors[10] = IERC721.ownerOf.selector;
        selectors[11] = bytes4(keccak256("safeTransferFrom(address,address,uint256,bytes)"));
        selectors[12] = bytes4(keccak256("safeTransferFrom(address,address,uint256)"));
        selectors[13] = IERC721.transferFrom.selector;
        selectors[14] = IERC721.approve.selector;
        selectors[15] = IERC721.setApprovalForAll.selector;
        selectors[16] = IERC721.getApproved.selector;
        selectors[17] = IERC721.isApprovedForAll.selector;
        selectors[18] = TheCollectorsNFTVaultTokenManagerFacet.supportsInterface.selector;
        selectors[19] = TheCollectorsNFTVaultTokenManagerFacet.tokenURI.selector;
        selectors[20] = TheCollectorsNFTVaultTokenManagerFacet.getCollectionVaults.selector;
        selectors[21] = TheCollectorsNFTVaultBaseFacet.isVaultSoldNFT.selector;
        return selectors;
    }

    /*
        @dev
        Adding all functions of opensea manager facet
    */
    function _getDiamondCutAndLoupeFacetSelectors() internal pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](5);
        selectors[0] = TheCollectorsNFTVaultDiamondCutAndLoupeFacet.diamondCut.selector;
        selectors[1] = TheCollectorsNFTVaultDiamondCutAndLoupeFacet.facets.selector;
        selectors[2] = TheCollectorsNFTVaultDiamondCutAndLoupeFacet.facetFunctionSelectors.selector;
        selectors[3] = TheCollectorsNFTVaultDiamondCutAndLoupeFacet.facetAddresses.selector;
        selectors[4] = TheCollectorsNFTVaultDiamondCutAndLoupeFacet.facetAddress.selector;
        return selectors;
    }

    // =========== Lifecycle ===========

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    // To learn more about this implementation read EIP 2535
    fallback() external payable {
        address facet = LibDiamond.diamondStorage().selectorToFacetAndPosition[msg.sig].facetAddress;
        require(facet != address(0), "Diamond: Function does not exist");
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return (0, returndatasize())
            }
        }
    }

    /*
        @dev
        To enable receiving ETH
    */
    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED
// © 2022 The Collectors. All rights reserved.
pragma solidity ^0.8.13;

import "../Imports.sol";
import "../Interfaces.sol";
import "../LibDiamond.sol";
import {Order} from "../SeaportStructs.sol";

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
    @dev
    This is the base contract that the main contract and the assets manager are inheriting from
*/
abstract contract TheCollectorsNFTVaultBaseFacet is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

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
    event NFTListedForSale(uint256 indexed vaultId, address indexed collection, uint256 indexed tokenId, uint256 price, Order order);
    event NFTSellOrderCanceled(uint256 indexed vaultId, address indexed collection, uint256 indexed tokenId);
    event VotedForBuy(uint256 indexed vaultId, address indexed participant, bool indexed vote, address collection, uint256 tokenId);
    event VotedForSell(uint256 indexed vaultId, address indexed participant, bool indexed vote, address collection, uint256 tokenId, uint256 price);
    event VotedForCancel(uint256 indexed vaultId, address indexed participant, bool indexed vote, address collection, uint256 tokenId, uint256 price);
    event NFTSold(uint256 indexed vaultId, address indexed collection, uint256 indexed tokenId, uint256 price);
    event NFTWithdrawnToOwner(uint256 indexed vaultId, address indexed collection, uint256 indexed tokenId, address owner);

    // ==================== Views ====================

    /*
        @dev
        A helper function to make sure there is a selling/cancelling consensus
    */
    function isVaultPassedSellOrCancelSellOrderConsensus(uint64 vaultId) public view returns (bool) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        LibDiamond.Vault storage vault = _as.vaults[vaultId];
        uint256 votesPercentage;
        uint24 numberOfParticipants = _as.vaultsExtensions[vaultId].numberOfParticipants;
        for (uint256 i; i < numberOfParticipants;) {
            LibDiamond.Participant storage participant = _as.vaultParticipants[vault.id][i];
            // Either the participate voted yes for selling or the participate didn't vote at all
            // and the grace period was passed
            votesPercentage += _getParticipantSellOrCancelSellOrderVote(vault, participant)
            ? participant.ownership : 0;
            unchecked {
                ++i;
            }
        }
        // Need to check if equals too in case the sell consensus is 100%
        // Adding 1 wei since votesPercentage cannot be exactly 100%
        // Dividing by 1e6 to soften the threshold (but still very precise)
        return votesPercentage / 1e6 + 1 wei >= vault.sellOrCancelSellOrderConsensus / 1e6;
    }

    function isVaultSoldNFT(uint64 vaultId) public view returns (bool) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        // Only vaults that already bought the NFT can sell it
        if (_as.vaults[vaultId].votingFor != LibDiamond.VoteFor.CancellingSellOrder
            && _as.vaults[vaultId].votingFor != LibDiamond.VoteFor.Selling) {
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
    function _requireVotingForBuyingOrWaitingForSettingTokenInfo(uint64 vaultId) internal view {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        require(_as.vaults[vaultId].votingFor == LibDiamond.VoteFor.Buying || _as.vaults[vaultId].votingFor == LibDiamond.VoteFor.WaitingToSetTokenInfo, "E1");
    }

    /*
        @dev
        A helper function to determine if a participant voted for selling or cancelling order
        or haven't voted yet but the grace period passed
    */
    function _getParticipantSellOrCancelSellOrderVote(
        LibDiamond.Vault storage vault,
        LibDiamond.Participant storage participant
    ) internal view returns (bool) {
        if (participant.voteDate >= vault.lastVoteDate) {
            return participant.vote;
        } else {
            return vault.endGracePeriodForSellingOrCancellingSellOrder != 0
            && block.timestamp > vault.endGracePeriodForSellingOrCancellingSellOrder;
        }
    }

    /*
        @dev
        A helper function to find out if a participant is part of a vault
    */
    function _isParticipantExists(uint64 vaultId, address participant) internal view returns (bool) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        uint24 numberOfParticipants = _as.vaultsExtensions[vaultId].numberOfParticipants;
        for (uint256 i; i < numberOfParticipants;) {
            if (_as.vaultParticipants[vaultId][i].participant == participant) {
                return true;
            }
            unchecked {
                ++i;
            }
        }
        return false;
    }

    /*
        @dev
        A helper function to reset votes and grace period after listing for sale or cancelling a sell order
    */
    function _resetVotesAndGracePeriod(uint64 vaultId) internal {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        LibDiamond.Vault storage vault = _as.vaults[vaultId];
        vault.endGracePeriodForSellingOrCancellingSellOrder = 0;
        vault.lastVoteDate = uint48(block.timestamp);
    }

    /*
        @dev
        A helper function to calculate a participate or token id % in the vault.
        This function can be called before/after buying/selling the NFT
        Since tokenId cannot be 0 (as we are starting it from 1) it is ok to assume that if tokenId 0 was sent
        the method should return the participant %.
        In case address 0 was sent, the method will calculate the tokenId %.
    */
    function _getPercentage(uint64 vaultId, uint256 participantIndex, uint256 tokenId) internal view returns (uint256) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        LibDiamond.VaultExtension storage vaultExtension = _as.vaultsExtensions[vaultId];
        uint256 totalPaid;
        uint256 participantsPaid;
        for (uint256 i; i < vaultExtension.numberOfParticipants; i++) {
            LibDiamond.Participant storage participant = _as.vaultParticipants[vaultId][i];
            totalPaid += participant.paid;
            if ((tokenId == 0 && i == participantIndex)
                || (tokenId != 0 && participant.partialNFTVaultTokenId == tokenId)) {
                // Found participant or token
                if (_as.vaults[vaultId].votingFor == LibDiamond.VoteFor.Selling || _as.vaults[vaultId].votingFor == LibDiamond.VoteFor.CancellingSellOrder) {
                    // Vault purchased the NFT
                    return participant.ownership;
                }
                participantsPaid = participant.paid;
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
            return 1e18 * 100 / vaultExtension.numberOfParticipants;
        }
    }

    /*
        @dev
        A helper function to make sure there is a buying consensus and that the purchase price is
        lower than the total ETH paid and the max price to buy
    */
    function _requireBuyConsensusAndValidatePurchasePrice(uint64 vaultId, uint256 purchasePrice) internal view returns (uint256) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        LibDiamond.VaultExtension storage vaultExtension = _as.vaultsExtensions[vaultId];
        LibDiamond.Vault storage vault = _as.vaults[vaultId];
        require(vault.votingFor == LibDiamond.VoteFor.Buying, "E1");
        uint256 totalPaid;
        uint256 votedPaid;
        for (uint256 i; i < vaultExtension.numberOfParticipants;) {
            LibDiamond.Participant storage participant = _as.vaultParticipants[vaultId][i];
            totalPaid += participant.paid;
            if (participant.voteDate >= vault.lastVoteDate && participant.vote) {
                votedPaid += participant.paid;
            }
            unchecked {
                ++i;
            }
        }
        require(purchasePrice <= totalPaid && purchasePrice <= vaultExtension.maxPriceToBuy, "E2");
        if (totalPaid == 0) {
            // Probably the vault is buying an NFT for 0
            return totalPaid;
        }
        // Need to check if equals too in case the buying consensus is 100%
        // Adding 1 wei since votesPercentage cannot be exactly 100%
        // Dividing by 1e6 to soften the threshold (but still very precise)
        uint256 votesPercentage = votedPaid * 1e18 * 100 / totalPaid;
        require(votesPercentage / 1e6 + 1 wei >= vault.buyConsensus / 1e6, "E3");
        return totalPaid;
    }

    /*
        @dev
        A helper function to validate whatever the vault is actually purchased the token and to calculate the final
        ownership of each participant
    */
    function _afterPurchaseNFT(uint64 vaultId, uint256 purchasePrice, bool withEvent, uint256 prevERC1155Amount, uint256 totalPaid) internal {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        LibDiamond.Vault storage vault = _as.vaults[vaultId];
        LibDiamond.VaultExtension storage vaultExtension = _as.vaultsExtensions[vaultId];
        // Cannot be below zero because otherwise the buying would have failed
        uint256 leftovers = totalPaid - purchasePrice;
        for (uint256 i; i < vaultExtension.numberOfParticipants;) {
            LibDiamond.Participant storage participant = _as.vaultParticipants[vaultId][i];
            if (totalPaid > 0) {
                participant.leftovers = uint128(leftovers * uint256(participant.paid) / totalPaid);
            } else {
                // If totalPaid = 0 then returning all what the participant paid
                // This can happen if everyone withdraws their funds after voting yes
                participant.leftovers = participant.paid;
            }
            if (totalPaid > 0) {
                // Calculating % based on total paid
                participant.ownership = uint128(uint256(participant.paid) * 1e18 * 100 / totalPaid);
            } else {
                // No one paid, splitting equally
                // This can happen if everyone withdraws their funds after voting yes
                participant.ownership = uint128(1e18 * 100 / vaultExtension.numberOfParticipants);
            }
            participant.paid = participant.paid - participant.leftovers;

            unchecked {
                ++i;
            }
        }

        if (vaultExtension.isERC1155) {
            // If it was == 1, then it was open to attacks
            require(IERC1155(vault.collection).balanceOf(_as.assetsHolders[vaultId], vault.tokenId) > prevERC1155Amount, "E4");
        } else {
            require(IERC721(vault.collection).ownerOf(vault.tokenId) == _as.assetsHolders[vaultId], "E4");
        }
        // Resetting vote so the participate will be able to vote for setListingPrice
        vault.lastVoteDate = uint48(block.timestamp);
        // Next vote will be for selling
        vault.votingFor = LibDiamond.VoteFor.Selling;
        // Since participate.paid is updating and re-calculated after buying the NFT the sum of all participants paid
        // can be a little different from the actual purchase price, however, it should never be more than purchasedFor
        // in order to not get insufficient funds exception
        vault.purchasedFor = uint128(purchasePrice);
        // Adding vault to collection's list
        _as.collectionsVaults[vault.collection].push(vaultId);
        if (withEvent) {
            emit NFTPurchased(vault.id, vault.collection, vault.tokenId, purchasePrice);
        }
    }

}

// SPDX-License-Identifier: UNLICENSED
// © 2022 The Collectors. All rights reserved.
pragma solidity ^0.8.13;

import "./TheCollectorsNFTVaultBaseFacet.sol";
import "../TheCollectorsNFTVaultSeaportAssetsHolderProxy.sol";

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
    @dev
    The facet that handling all vaults logic and can be called only by @TheCollectorsNFTVaultDiamond
    This contract is part of a diamond / facets implementation as described
    in EIP 2535 (https://eips.ethereum.org/EIPS/eip-2535)
*/
contract TheCollectorsNFTVaultLogicFacet is TheCollectorsNFTVaultBaseFacet {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // ==================== Protocol management ====================

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
        bytes32 vaultName,
        address collection,
        uint128 sellOrCancelSellOrderConsensus,
        uint128 buyConsensus,
        uint32 gracePeriodForSellingOrCancellingSellOrder,
        address[] memory _participants,
        bool privateVault,
        uint24 maxParticipants,
        uint128 minimumFunding
    ) external {
        // At least one participant
        require(_participants.length > 0 && _participants.length <= maxParticipants, "E1");
        require(vaultName != 0x0000000000000000000000000000000000000000000000000000000000000000, "E2");
        require(collection != address(0), "E3");
        require(sellOrCancelSellOrderConsensus >= 51 ether && sellOrCancelSellOrderConsensus <= 100 ether, "E4");
        require(buyConsensus >= 51 ether && buyConsensus <= 100 ether, "E5");
        // Min 30 days, max 6 months
        // The amount of time to wait before undecided votes for selling/canceling sell order are considered as yes
        require(gracePeriodForSellingOrCancellingSellOrder >= 30 days
            && gracePeriodForSellingOrCancellingSellOrder <= 180 days, "E6");
        // Private vaults don't need to have a minimumFunding
        require(privateVault || minimumFunding > 0, "E7");

        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        uint64 currentVaultId = uint64(_as.vaultIdTracker.current());
        emit VaultCreated(currentVaultId, collection, privateVault);

        for (uint256 i; i < _participants.length;) {
            _as.vaultParticipants[currentVaultId][i].participant = _participants[i];
            // Not going to check if the participant already exists (avoid duplicated) when creating a vault,
            // because it is the creator responsibility and does not have any bad affect over the vault
            emit ParticipantJoinedVault(currentVaultId, _participants[i]);
            unchecked {
                ++i;
            }
        }

        // Vault
        LibDiamond.Vault storage vault = _as.vaults[currentVaultId];
        vault.id = currentVaultId;
        vault.name = vaultName;
        vault.collection = collection;
        vault.sellOrCancelSellOrderConsensus = sellOrCancelSellOrderConsensus;
        vault.buyConsensus = buyConsensus;
        vault.gracePeriodForSellingOrCancellingSellOrder = gracePeriodForSellingOrCancellingSellOrder;
        vault.maxParticipants = maxParticipants;

        // Vault extension
        LibDiamond.VaultExtension storage vaultExtension = _as.vaultsExtensions[currentVaultId];
        if (!privateVault) {
            vaultExtension.publicVault = true;
            vaultExtension.minimumFunding = minimumFunding;
        }
        vaultExtension.isERC1155 = !IERC165(collection).supportsInterface(type(IERC721).interfaceId);
        vaultExtension.numberOfParticipants = uint24(_participants.length);

        _createNFTVaultAssetsHolder(currentVaultId);
        _as.vaultIdTracker.increment();
    }

    /*
        @dev
        Allow people to join a public vault but only if it hasn't bought the NFT yet
        The person who wants to join needs to send more than the minimum amount of ETH to join the vault
    */
    function joinPublicVault(uint64 vaultId) external payable {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        LibDiamond.VaultExtension storage vaultExtension = _as.vaultsExtensions[vaultId];
        // NFT wasn't bought yet
        _requireVotingForBuyingOrWaitingForSettingTokenInfo(vaultId);
        // Vault exists and it is public
        require(vaultExtension.publicVault, "E2");
        // There is room
        require(vaultExtension.numberOfParticipants < _as.vaults[vaultId].maxParticipants, "E3");
        // The sender is a not a participant of the vault yet
        require(!_isParticipantExists(vaultId, msg.sender), "E4");
        // The sender sent enough ETH
        require(msg.value >= vaultExtension.minimumFunding, "E5");
        _as.vaultParticipants[vaultId][(++vaultExtension.numberOfParticipants) - 1].participant = msg.sender;
        _as.vaultParticipants[vaultId][vaultExtension.numberOfParticipants - 1].paid += uint128(msg.value);
        emit ParticipantJoinedVault(vaultId, msg.sender);
        // The asset holder is the contract that is holding the ETH and tokens
        Address.sendValue(_as.assetsHolders[vaultId], msg.value);
        emit VaultWasFunded(vaultId, msg.sender, msg.value);
    }

    /*
        @dev
        Adding a person to a private vault by another participant of the vault
    */
    function addParticipant(uint64 vaultId, address participant) external {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        LibDiamond.VaultExtension storage vaultExtension = _as.vaultsExtensions[vaultId];
        // NFT wasn't bought yet
        _requireVotingForBuyingOrWaitingForSettingTokenInfo(vaultId);
        // Private vault
        require(!vaultExtension.publicVault, "E2");
        // There is room
        require(vaultExtension.numberOfParticipants < _as.vaults[vaultId].maxParticipants, "E3");
        require(!_isParticipantExists(vaultId, participant), "E5");
        bool isParticipant;
        for (uint256 i; i < vaultExtension.numberOfParticipants;) {
            LibDiamond.Participant storage participantStruct = _as.vaultParticipants[vaultId][i];
            if (participantStruct.participant == msg.sender) {
                // Only participant that paid can add others to a private vault
                // Can check paid > 0 and not ownership > 0 because this method can be used only before purchasing
                // Using paid > 0 will save gas
                // Also using @_getPercentage can return > 0 if no one paid
                require(participantStruct.paid > 0, "E6");
                isParticipant = true;
                break;
            }
            unchecked {
                ++i;
            }
        }
        // The sender is a participant of the vault
        require(isParticipant, "E4");
        _as.vaultParticipants[vaultId][(++vaultExtension.numberOfParticipants) - 1].participant = participant;
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
        If the vault is being kept hostage by a participant by always resetting the votes, the other participants can always withdraw
        their ETH as long as the vault didn't buy the NFT and just open a new vault without the bad actors.
    */
    function setTokenInfoAndMaxBuyPrice(uint64 vaultId, address collection, uint256 tokenId, uint128 maxBuyPrice) external {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        // Can call this method only if haven't set a token before or already set but haven't bought the token yet
        _requireVotingForBuyingOrWaitingForSettingTokenInfo(vaultId);
        LibDiamond.Vault storage vault = _as.vaults[vaultId];
        LibDiamond.VaultExtension storage vaultExtension = _as.vaultsExtensions[vaultId];
        /*
            @dev
            Checking if vaults[vaultId].votingFor == VoteFor.WaitingToSetTokenInfo because tokenId-to-buy can be 0
            Only private vaults can change collections
        */
        if (!vaultExtension.publicVault) {
            require(collection != address(0), "E2");
            if (vault.collection != collection) {
                // Re setting the isERC1155 property because there is a new collection
                vaultExtension.isERC1155 = !IERC165(collection).supportsInterface(type(IERC721).interfaceId);
                vault.collection = collection;
            }
        }
        vault.tokenId = tokenId;
        if (vault.votingFor == LibDiamond.VoteFor.WaitingToSetTokenInfo) {
            vault.votingFor = LibDiamond.VoteFor.Buying;
        }
        vaultExtension.maxPriceToBuy = maxBuyPrice;
        bool isParticipant;
        for (uint256 i; i < vaultExtension.numberOfParticipants;) {
            LibDiamond.Participant storage participant = _as.vaultParticipants[vaultId][i];
            if (participant.participant == msg.sender) {
                // Only participants who paid can be part of the decisions making
                // Can check paid > 0 and not ownership > 0 because this method can be used only before purchasing
                // Using paid > 0 will save gas
                // Also using @_getPercentage can return > 0 if no one paid
                require(participant.paid > 0, "E3");
                isParticipant = true;
                vault.lastVoteDate = uint48(block.timestamp);
                emit NFTTokenWasSet(vault.id, vault.collection, tokenId, maxBuyPrice);
                _vote(vaultId, participant, true, vault.votingFor);
                break;
            }
            unchecked {
                ++i;
            }
        }
        require(isParticipant, "E4");
    }

    /*
        @dev
        Setting a listing price for the NFT sell order.
        Later, participants can vote for or against selling it at this price.
        Participants can call this method again in order to change the listing price.
    */
    function setListingPrice(uint64 vaultId, uint128 listFor) external {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        LibDiamond.Vault storage vault = _as.vaults[vaultId];
        require(vault.votingFor == LibDiamond.VoteFor.Selling, "E1");
        vault.listFor = listFor;
        bool isParticipant;
        uint24 numberOfParticipants = _as.vaultsExtensions[vaultId].numberOfParticipants;
        for (uint256 i; i < numberOfParticipants; i++) {
            LibDiamond.Participant storage participant = _as.vaultParticipants[vaultId][i];
            if (participant.participant == msg.sender) {
                // Only participants who has ownership can be part of the decision making
                // Can check ownership > 0 and not call @_getPercentage because this method can be
                // called only after purchasing
                // Using ownership > 0 will save gas
                require(participant.ownership > 0, "E2");
                isParticipant = true;
                _resetVotesAndGracePeriod(vaultId);
                emit ListingPriceWasSet(vault.id, vault.collection, vault.tokenId, listFor);
                _vote(vaultId, participant, true, vault.votingFor);
                break;
            }
        }
        require(isParticipant, "E3");
    }

    /*
        @dev
        Voting for either buy the token, listing it for sale or cancel the sell order
    */
    function vote(uint64 vaultId, bool yes) external {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        require(_as.vaults[vaultId].votingFor != LibDiamond.VoteFor.WaitingToSetTokenInfo, "E1");
        bool isParticipant;
        uint24 numberOfParticipants = _as.vaultsExtensions[vaultId].numberOfParticipants;
        for (uint256 i; i < numberOfParticipants;) {
            LibDiamond.Participant storage participant = _as.vaultParticipants[vaultId][i];
            if (participant.participant == msg.sender) {
                isParticipant = true;
                _vote(vaultId, participant, yes, _as.vaults[vaultId].votingFor);
                /*
                    @dev
                    Not using a break here since participants can hold more than 1 seat if they bought the vault NFT
                    from the other participants after the vault bought the original NFT.
                    If we would have a break here, the vault could get to a limbo state where it
                    would not able to pass the consensus to sell the NFT and it would be stuck forever
                */
            }
            unchecked {
                i++;
            }
        }
        require(isParticipant, "E3");
    }

    /*
        @dev
        Sending ETH to vault. The funds that will not be used for purchasing the
        NFT will be returned to the participate when calling the @claimVaultTokenAndGetLeftovers method
    */
    function fundVault(uint64 vaultId) public payable {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        LibDiamond.VaultExtension storage vaultExtension = _as.vaultsExtensions[vaultId];
        // Can only fund the vault if the token was not purchased yet
        _requireVotingForBuyingOrWaitingForSettingTokenInfo(vaultId);
        bool isParticipant;
        for (uint256 i; i < vaultExtension.numberOfParticipants;) {
            LibDiamond.Participant storage participant = _as.vaultParticipants[vaultId][i];
            if (participant.participant == msg.sender) {
                isParticipant = true;
                participant.paid += uint128(msg.value);
                if (vaultExtension.publicVault) {
                    require(participant.paid >= vaultExtension.minimumFunding, "E2");
                }
                // The asset holder is the contract that is holding the ETH and tokens
                Address.sendValue(_as.assetsHolders[vaultId], msg.value);
                emit VaultWasFunded(vaultId, msg.sender, msg.value);
                break;
            }
            unchecked {
                ++i;
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
    function withdrawFunds(uint64 vaultId, uint128 amount) external nonReentrant {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        LibDiamond.VaultExtension storage vaultExtension = _as.vaultsExtensions[vaultId];
        _requireVotingForBuyingOrWaitingForSettingTokenInfo(vaultId);
        for (uint256 i; i < vaultExtension.numberOfParticipants;) {
            LibDiamond.Participant storage participant = _as.vaultParticipants[vaultId][i];
            if (participant.participant == msg.sender) {
                require(amount <= participant.paid, "E2");
                if (vaultExtension.publicVault && (participant.paid - amount) < vaultExtension.minimumFunding) {
                    // This is a public vault and there is minimum funding
                    // The participant is asking to withdraw amount that will cause their total funding
                    // to be less than the minimum amount. Returning all funds and removing from vault
                    amount = participant.paid;
                }
                participant.paid -= amount;
                IAssetsHolderImpl(_as.assetsHolders[vaultId]).sendValue(payable(participant.participant), amount);
                if (participant.paid == 0 && vaultExtension.publicVault) {
                    // Removing participant from public vault
                    if (participant.collectorOwner == msg.sender) {
                        participant.collectorOwner = address(0);
                        uint16 stakedCollectorTokenId = participant.stakedCollectorTokenId;
                        participant.stakedCollectorTokenId = 0;
                        IAssetsHolderImpl(_as.assetsHolders[vaultId]).transferToken(false, msg.sender, address(LibDiamond.THE_COLLECTORS), stakedCollectorTokenId);
                        emit CollectorUnstaked(vaultId, msg.sender, stakedCollectorTokenId);
                    }
                    _removeParticipant(vaultId, i);
                }
                emit FundsWithdrawn(vaultId, msg.sender, amount);
                break;
            }
            unchecked {
                ++i;
            }
        }
    }

    // ==================== views ====================

    function assetsHolders(uint64 vaultId) external view returns (address) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return _as.assetsHolders[vaultId];
    }

    function vaults(uint64 vaultId) external view returns (LibDiamond.Vault memory) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return _as.vaults[vaultId];
    }

    function vaultTokens(uint256 tokenId) external view returns (uint64) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return _as.vaultTokens[tokenId];
    }

    function vaultsExtensions(uint64 vaultId) external view returns (LibDiamond.VaultExtension memory) {
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

    function getVaultParticipants(uint64 vaultId) external view returns (LibDiamond.Participant[] memory) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        LibDiamond.Participant[] memory participants = new LibDiamond.Participant[](_as.vaultsExtensions[vaultId].numberOfParticipants);
        for (uint256 i; i < participants.length; i++) {
            participants[i] = _as.vaultParticipants[vaultId][i];
        }
        return participants;
    }

    function getParticipantPercentage(uint64 vaultId, uint256 participantIndex) external view returns (uint256) {
        return _getPercentage(vaultId, participantIndex, 0);
    }

    function getTokenPercentage(uint256 tokenId) external view returns (uint256) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return _getPercentage(_as.vaultTokens[tokenId], 0, tokenId);
    }

    // ==================== Internals ====================

    /*
    @dev
        Creating a new class to hold and operate one asset on seaport
    */
    function _createNFTVaultAssetsHolder(uint64 vaultId) internal {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        require(_as.assetsHolders[vaultId] == address(0), "E1");
        _as.assetsHolders[vaultId] = payable(
            new TheCollectorsNFTVaultSeaportAssetsHolderProxy(_as.nftVaultAssetHolderImpl, vaultId)
        );
    }

    /*
        @dev
        A helper function to remove element from array and reduce array size
    */
    function _removeParticipant(uint64 vaultId, uint256 index) internal {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        uint256 numberOfParticipants = _as.vaultsExtensions[vaultId].numberOfParticipants - 1;
        _as.vaultParticipants[vaultId][index] = _as.vaultParticipants[vaultId][numberOfParticipants];
        delete _as.vaultParticipants[vaultId][numberOfParticipants];
        _as.vaultsExtensions[vaultId].numberOfParticipants--;
    }

    /*
        @dev
        Internal vote method to update participant vote, reset grace period if needed and emit an event
    */
    function _vote(uint64 vaultId, LibDiamond.Participant storage participant, bool yes, LibDiamond.VoteFor voteFor) internal {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        LibDiamond.Vault storage vault = _as.vaults[vaultId];
        participant.vote = yes;
        if (voteFor == LibDiamond.VoteFor.Buying) {
            emit VotedForBuy(vaultId, participant.participant, yes, vault.collection, vault.tokenId);
        } else {
            // Resetting the grace period but only if this is the first vote
            // First time setting a listing price, voting to cancel a sell order or voting on a listing price
            // after the sell order was cancelled, the grace period will be reset
            bool firstProposalVote = true;
            uint24 numberOfParticipants = _as.vaultsExtensions[vaultId].numberOfParticipants;
            for (uint256 i; i < numberOfParticipants;) {
                if (_as.vaultParticipants[vaultId][i].voteDate >= vault.lastVoteDate) {
                    firstProposalVote = false;
                    break;
                }
                unchecked {
                    ++i;
                }
            }
            if (firstProposalVote) {
                // Resetting the end of grace period, after that date all undecided (un-voted) votes are considered as yes
                vault.endGracePeriodForSellingOrCancellingSellOrder = uint32(block.timestamp + vault.gracePeriodForSellingOrCancellingSellOrder);
            }
            if (voteFor == LibDiamond.VoteFor.Selling) {
                emit VotedForSell(vaultId, participant.participant, yes, vault.collection, vault.tokenId, vault.listFor);
            } else if (voteFor == LibDiamond.VoteFor.CancellingSellOrder) {
                emit VotedForCancel(vaultId, participant.participant, yes, vault.collection, vault.tokenId, vault.listFor);
            }
        }
        participant.voteDate = uint48(block.timestamp);
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

// SPDX-License-Identifier: UNLICENSED
// © 2022 The Collectors. All rights reserved.
pragma solidity ^0.8.13;

import "./TheCollectorsNFTVaultBaseFacet.sol";
import "./TheCollectorsNFTVaultTokenManagerFacet.sol";

/*
    ████████╗██╗  ██╗███████╗     ██████╗ ██████╗ ██╗     ██╗     ███████╗ ██████╗████████╗ ██████╗ ██████╗ ███████╗
    ╚══██╔══╝██║  ██║██╔════╝    ██╔════╝██╔═══██╗██║     ██║     ██╔════╝██╔════╝╚══██╔══╝██╔═══██╗██╔══██╗██╔════╝
       ██║   ███████║█████╗      ██║     ██║   ██║██║     ██║     █████╗  ██║        ██║   ██║   ██║██████╔╝███████╗
       ██║   ██╔══██║██╔══╝      ██║     ██║   ██║██║     ██║     ██╔══╝  ██║        ██║   ██║   ██║██╔══██╗╚════██║
       ██║   ██║  ██║███████╗    ╚██████╗╚██████╔╝███████╗███████╗███████╗╚██████╗   ██║   ╚██████╔╝██║  ██║███████║
       ╚═╝   ╚═╝  ╚═╝╚══════╝     ╚═════╝ ╚═════╝ ╚══════╝╚══════╝╚══════╝ ╚═════╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚══════╝

    ███╗   ██╗███████╗████████╗    ██╗   ██╗ █████╗ ██╗   ██╗██╗  ████████╗     █████╗ ███████╗███████╗███████╗████████╗███████╗
    ████╗  ██║██╔════╝╚══██╔══╝    ██║   ██║██╔══██╗██║   ██║██║  ╚══██╔══╝    ██╔══██╗██╔════╝██╔════╝██╔════╝╚══██╔══╝██╔════╝
    ██╔██╗ ██║█████╗     ██║       ██║   ██║███████║██║   ██║██║     ██║       ███████║███████╗███████╗█████╗     ██║   ███████╗
    ██║╚██╗██║██╔══╝     ██║       ╚██╗ ██╔╝██╔══██║██║   ██║██║     ██║       ██╔══██║╚════██║╚════██║██╔══╝     ██║   ╚════██║
    ██║ ╚████║██║        ██║        ╚████╔╝ ██║  ██║╚██████╔╝███████╗██║       ██║  ██║███████║███████║███████╗   ██║   ███████║
    ╚═╝  ╚═══╝╚═╝        ╚═╝         ╚═══╝  ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝       ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝   ╚═╝   ╚══════╝

    ███╗   ███╗ █████╗ ███╗   ██╗ █████╗  ██████╗ ███████╗██████╗     ███████╗ █████╗  ██████╗███████╗████████╗
    ████╗ ████║██╔══██╗████╗  ██║██╔══██╗██╔════╝ ██╔════╝██╔══██╗    ██╔════╝██╔══██╗██╔════╝██╔════╝╚══██╔══╝
    ██╔████╔██║███████║██╔██╗ ██║███████║██║  ███╗█████╗  ██████╔╝    █████╗  ███████║██║     █████╗     ██║
    ██║╚██╔╝██║██╔══██║██║╚██╗██║██╔══██║██║   ██║██╔══╝  ██╔══██╗    ██╔══╝  ██╔══██║██║     ██╔══╝     ██║
    ██║ ╚═╝ ██║██║  ██║██║ ╚████║██║  ██║╚██████╔╝███████╗██║  ██║    ██║     ██║  ██║╚██████╗███████╗   ██║
    ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝    ╚═╝     ╚═╝  ╚═╝ ╚═════╝╚══════╝   ╚═╝
    @dev
    The facet that handling all assets logic and can be called only by @TheCollectorsNFTVaultDiamond
    This contract is part of a diamond / facets implementation as described
    in EIP 2535 (https://eips.ethereum.org/EIPS/eip-2535)
*/
contract TheCollectorsNFTVaultAssetsManagerFacet is TheCollectorsNFTVaultBaseFacet {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // ==================== Asset sale, buy & list ====================

    /*
        @dev
        Migrating a group of people who bought together an NFT to a vault.
        It is under the sender responsibility to send the right details.
        This is the use case. Bob, Mary and Jim are friends and bought together a BAYC for 60 ETH. Jim and Mary
        sent 20 ETH each to Bob, Bob added another 20 ETH and bought the BAYC on a marketplace.
        Now, Bob is holding the BAYC in his private wallet and has the responsibility to make sure it stay safe.
        In order to migrate, first Bob (or Jim or Mary) will need to create a vault with the BAYC collection, 3
        participants and enter Bob's, Mary's and Jim's addresses. After that, ONLY Bob can migrate by sending the right
        properties.
        @vaultId the vault's id
        @tokenId the tokens id of the collection (e.g BAYC's id)
        @_participants list of participants (e.g with Bob's, Mary's and Jim's addresses [in that order])
        @payments how much each participant paid
    */
    function migrate(uint64 vaultId, uint256 tokenId, address[] memory _participants, uint128[] memory payments) external {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        LibDiamond.VaultExtension storage vaultExtension = _as.vaultsExtensions[vaultId];
        LibDiamond.Vault storage vault = _as.vaults[vaultId];
        address payable assetsHolder = _as.assetsHolders[vaultId];

        // Must be immediately after creating vault
        require(vault.votingFor == LibDiamond.VoteFor.WaitingToSetTokenInfo, "E1");
        vault.tokenId = tokenId;
        vaultExtension.isMigrated = true;

        uint256 totalPaid;
        for (uint256 i; i < vaultExtension.numberOfParticipants;) {
            LibDiamond.Participant storage participant = _as.vaultParticipants[vaultId][i];
            // No one paid yet
            require(participant.paid == 0, "E2");
            // Making sure participants sent in the same order
            require(participant.participant == _participants[i], "E3");
            participant.paid = payments[i];
            if (vaultExtension.publicVault) {
                // Public vault
                require(payments[i] >= vaultExtension.minimumFunding, "E4");
            } else {
                require(payments[i] > 0, "E4");
            }
            totalPaid += payments[i];
            unchecked {
                ++i;
            }
        }

        if (!vaultExtension.isERC1155) {
            IERC721(vault.collection).safeTransferFrom(msg.sender, assetsHolder, tokenId);
        } else {
            IERC1155(vault.collection).safeTransferFrom(msg.sender, assetsHolder, tokenId, 1, "");
        }

        // totalPaid = purchasePrice
        _afterPurchaseNFT(vaultId, totalPaid, false, 0, totalPaid);
        emit NFTMigrated(vault.id, vault.collection, vault.tokenId, totalPaid);
    }

    /*
        @dev
        A method to allow anyone to purchase the token from the vault in the required price and the
        seller won't pay any fees. It is basically an OTC buy deal.
        The buyer can call this method only if the NFT is already for sale.
        This method can also be used as a failsafe in case marketplace sale is failing.
        No need to cancel previous order since the vault will not be used again
    */
    function buyNFTFromVault(uint64 vaultId) external nonReentrant payable {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        LibDiamond.Vault storage vault = _as.vaults[vaultId];
        address payable assetsHolder = _as.assetsHolders[vaultId];
        // No marketplace and royalties fees
        vault.netSalePrice = vault.listFor;
        // Making sure vault already bought the token, the token is for sale and has a list price
        require(vault.votingFor == LibDiamond.VoteFor.CancellingSellOrder && vault.listFor > 0, "E1");
        // Not checking that the vault is the owner of the token to save gas
        // Sender sent enough ETH to purchase the NFT
        require(msg.value == vault.listFor, "E3");
        // Transferring the token to the new owner
        IAssetsHolderImpl(assetsHolder).transferToken(
            _as.vaultsExtensions[vaultId].isERC1155, msg.sender, vault.collection, vault.tokenId
        );
        // Transferring the ETH to the asset holder which is in charge of distributing the profits
        Address.sendValue(assetsHolder, msg.value);
        emit NFTSold(vaultId, vault.collection, vault.tokenId, vault.listFor);
    }

    /*
        @dev
        A method to allow anyone to sell the token that the vault is about to purchase to the vault
        without going through a marketplace. It is basically an OTC sell deal.
        The seller can call this method only if the vault is in buying state and there is a buy consensus.
        The sale price will be the lower between the total paid amount and the vault maxPriceToBuy.
        The user is sending the sellPrice to prevent a frontrun attacks where a participant is withdrawing
        ETH just before the transaction to sell the NFT thus making the sellers to get less than what they
        were expecting to get. The sellPrice will be calculated in the FE by taking the minimum
        between the total paid and max price to buy
    */
    function sellNFTToVault(uint64 vaultId, uint256 sellPrice) external nonReentrant {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        LibDiamond.Vault storage vault = _as.vaults[vaultId];
        LibDiamond.VaultExtension storage vaultExtension = _as.vaultsExtensions[vaultId];
        address payable assetsHolder = _as.assetsHolders[vaultId];

        _requireBuyConsensusAndValidatePurchasePrice(vaultId, sellPrice);

        uint256 prevERC1155Amount;

        if (!vaultExtension.isERC1155) {
            IERC721(vault.collection).safeTransferFrom(msg.sender, assetsHolder, vault.tokenId);
        } else {
            prevERC1155Amount = IERC1155(vault.collection).balanceOf(assetsHolder, vault.tokenId);
            IERC1155(vault.collection).safeTransferFrom(msg.sender, assetsHolder, vault.tokenId, 1, "");
        }

        IAssetsHolderImpl(assetsHolder).sendValue(payable(msg.sender), sellPrice);

        uint256 totalPaid;
        for (uint256 i; i < vaultExtension.numberOfParticipants;) {
            totalPaid += _as.vaultParticipants[vaultId][i].paid;
            unchecked {
                ++i;
            }
        }

        _afterPurchaseNFT(vaultId, sellPrice, true, prevERC1155Amount, totalPaid);
    }

    /*
        @dev
        Withdraw the vault's NFT to the address that holding 100% of the shares
        Only applicable for vaults where one address holding 100% of the shares
    */
    function withdrawNFTToOwner(uint64 vaultId) external nonReentrant {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        LibDiamond.Vault storage vault = _as.vaults[vaultId];
        LibDiamond.VaultExtension storage vaultExtension = _as.vaultsExtensions[vaultId];
        address payable assetsHolder = _as.assetsHolders[vaultId];

        require(vault.votingFor == LibDiamond.VoteFor.Selling || vault.votingFor == LibDiamond.VoteFor.CancellingSellOrder, "E1");
        for (uint256 i; i < vaultExtension.numberOfParticipants;) {
            LibDiamond.Participant storage participant = _as.vaultParticipants[vaultId][i];
            if (participant.ownership > 0) {
                require(participant.participant == msg.sender, "E2");
                if (participant.partialNFTVaultTokenId != 0) {
                    require(IERC721(address(this)).ownerOf(participant.partialNFTVaultTokenId) == msg.sender, "E3");
                    Address.functionDelegateCall(
                        _as.nftVaultTokenHandler,
                        abi.encodeWithSelector(
                            TheCollectorsNFTVaultTokenManagerFacet.burnFractionalToken.selector,
                            participant.partialNFTVaultTokenId
                        )
                    );
                    // Removing partial NFT from storage
                    delete _as.vaultTokens[participant.partialNFTVaultTokenId];
                }
                participant.leftovers = 0;
            }
            if (participant.collectorOwner != address(0)) {
                // In case the partial NFT was sold to someone else, the original collector owner still
                // going to get their token back
                IAssetsHolderImpl(assetsHolder).transferToken(false, participant.collectorOwner,
                    address(LibDiamond.THE_COLLECTORS), participant.stakedCollectorTokenId
                );
            }
            unchecked {
                ++i;
            }
        }
        // Not checking if asset holder holds the asses to save gas
        IAssetsHolderImpl(assetsHolder).transferToken(
            vaultExtension.isERC1155, msg.sender, vault.collection, vault.tokenId
        );
        if (assetsHolder.balance > 0) {
            IAssetsHolderImpl(assetsHolder).sendValue(
                payable(msg.sender), assetsHolder.balance
            );
        }
        vaultExtension.isWithdrawnToOwner = true;
        emit NFTWithdrawnToOwner(vaultId, vault.collection, vault.tokenId, msg.sender);
    }

    // ==================== The Collectors ====================

    /*
        @dev
        Unstaking a Collector NFT from the vault. Can be done only be the original owner of the collector and only
        if the participant already staked a collector and the vault haven't bought the token yet
    */
    function unstakeCollector(uint64 vaultId, uint16 stakedCollectorTokenId) external {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        _requireVotingForBuyingOrWaitingForSettingTokenInfo(vaultId);
        require(LibDiamond.THE_COLLECTORS.ownerOf(stakedCollectorTokenId) == _as.assetsHolders[vaultId], "E2");
        uint24 numberOfParticipants = _as.vaultsExtensions[vaultId].numberOfParticipants;
        for (uint256 i; i < numberOfParticipants;) {
            LibDiamond.Participant storage participant = _as.vaultParticipants[vaultId][i];
            if (participant.participant == msg.sender) {
                require(participant.collectorOwner == msg.sender, "E3");
                participant.collectorOwner = address(0);
                participant.stakedCollectorTokenId = 0;
                IAssetsHolderImpl(_as.assetsHolders[vaultId]).transferToken(false, msg.sender, address(LibDiamond.THE_COLLECTORS), stakedCollectorTokenId);
                emit CollectorUnstaked(vaultId, msg.sender, stakedCollectorTokenId);
                break;
            }
            unchecked {
                ++i;
            }
        }
    }

    /*
        @dev
        Staking a Collector NFT in the vault to avoid paying the protocol fee.
        A participate can stake a Collector for the lifecycle of the vault (buying and selling) in order to
        not pay the protocol fee when selling the token.
        The Collector NFT will return to the original owner when redeeming the partial NFT of the vault
    */
    function stakeCollector(uint64 vaultId, uint16 collectorTokenId) external {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        _requireVotingForBuyingOrWaitingForSettingTokenInfo(vaultId);
        require(LibDiamond.THE_COLLECTORS.ownerOf(collectorTokenId) == msg.sender, "E2");
        LibDiamond.THE_COLLECTORS.safeTransferFrom(msg.sender, _as.assetsHolders[vaultId], collectorTokenId);
        uint24 numberOfParticipants = _as.vaultsExtensions[vaultId].numberOfParticipants;
        for (uint256 i; i < numberOfParticipants;) {
            LibDiamond.Participant storage participant = _as.vaultParticipants[vaultId][i];
            if (participant.participant == msg.sender) {
                // Only participants who paid can be part of the decisions making
                // Can check paid > 0 and not ownership > 0 because this method can be used only before purchasing
                // Using paid > 0 will save gas
                // Also using @_getPercentage can return > 0 if no one paid
                require(participant.paid > 0, "E3");
                // Can only stake 1 collector
                require(participant.collectorOwner == address(0), "E4");
                // Saving a reference for the original collector owner because a participate can sell his seat
                participant.collectorOwner = msg.sender;
                participant.stakedCollectorTokenId = collectorTokenId;
                emit CollectorStaked(vaultId, msg.sender, collectorTokenId);
                break;
            }
            unchecked {
                ++i;
            }
        }
    }

    // ==================== Views ====================

    /*
        @dev
        A function that verifies there is a 4 blocks difference between listing and buying to mitigate the attack
        that a majority holder can sell the underlying NFT to themselves
    */
    function validateSale(uint64 vaultId) public view returns (bool) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return block.number - _as.vaultsExtensions[vaultId].listingBlockNumber > 3;
    }
}

// SPDX-License-Identifier: UNLICENSED
// © 2022 The Collectors. All rights reserved.
pragma solidity ^0.8.13;

import "./TheCollectorsNFTVaultBaseFacet.sol";
import "../TheCollectorsNFTVaultSeaportAssetsHolderImpl.sol";
import {BasicOrderParameters, OrderComponents, Order, Fulfillment} from "../SeaportStructs.sol";
import {ItemType} from "../SeaportEnums.sol";

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
    ███████╗███████╗ █████╗ ██████╗  ██████╗ ██████╗ ████████╗
    ██╔════╝██╔════╝██╔══██╗██╔══██╗██╔═══██╗██╔══██╗╚══██╔══╝
    ███████╗█████╗  ███████║██████╔╝██║   ██║██████╔╝   ██║
    ╚════██║██╔══╝  ██╔══██║██╔═══╝ ██║   ██║██╔══██╗   ██║
    ███████║███████╗██║  ██║██║     ╚██████╔╝██║  ██║   ██║
    ╚══════╝╚══════╝╚═╝  ╚═╝╚═╝      ╚═════╝ ╚═╝  ╚═╝   ╚═╝
    ███╗   ███╗ █████╗ ███╗   ██╗ █████╗  ██████╗ ███████╗██████╗     ███████╗ █████╗  ██████╗███████╗████████╗
    ████╗ ████║██╔══██╗████╗  ██║██╔══██╗██╔════╝ ██╔════╝██╔══██╗    ██╔════╝██╔══██╗██╔════╝██╔════╝╚══██╔══╝
    ██╔████╔██║███████║██╔██╗ ██║███████║██║  ███╗█████╗  ██████╔╝    █████╗  ███████║██║     █████╗     ██║
    ██║╚██╔╝██║██╔══██║██║╚██╗██║██╔══██║██║   ██║██╔══╝  ██╔══██╗    ██╔══╝  ██╔══██║██║     ██╔══╝     ██║
    ██║ ╚═╝ ██║██║  ██║██║ ╚████║██║  ██║╚██████╔╝███████╗██║  ██║    ██║     ██║  ██║╚██████╗███████╗   ██║
    ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝    ╚═╝     ╚═╝  ╚═╝ ╚═════╝╚══════╝   ╚═╝
    @dev
    The facet that handling all opensea Seaport protocol logic and can be called only by @TheCollectorsNFTVaultDiamond
    This contract is part of a diamond / facets implementation as described
    in EIP 2535 (https://eips.ethereum.org/EIPS/eip-2535)
*/
contract TheCollectorsNFTVaultSeaportManagerFacet is TheCollectorsNFTVaultBaseFacet {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // ==================== Seaport ====================

    /*
        @dev
        Buying the agreed upon token from Seaport using advanced order
        Not checking if msg.sender is a participant since a buy consensus must be met
    */
    function buyAdvancedNFTOnSeaport(
        uint64 vaultId,
        AdvancedOrder calldata advancedOrder,
        CriteriaResolver[] calldata criteriaResolvers,
        bytes32 fulfillerConduitKey
    ) external nonReentrant {

        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();

        uint256 prevERC1155Amount;

        if (_as.vaultsExtensions[vaultId].isERC1155) {
            prevERC1155Amount = IERC1155(_as.vaults[vaultId].collection).balanceOf(_as.assetsHolders[vaultId], _as.vaults[vaultId].tokenId);
        }

        uint256 purchasePrice;
        for (uint256 i; i < advancedOrder.parameters.consideration.length;) {
            if (advancedOrder.parameters.consideration[i].itemType == ItemType.NATIVE) {
                purchasePrice += advancedOrder.parameters.consideration[i].endAmount;
            }
            unchecked {
                ++i;
            }
        }

        uint256 totalPaid = _requireBuyConsensusAndValidatePurchasePrice(vaultId, purchasePrice);

        require(
            _as.vaults[vaultId].collection == advancedOrder.parameters.offer[0].token
            && _as.vaults[vaultId].tokenId == advancedOrder.parameters.offer[0].identifierOrCriteria
            && advancedOrder.parameters.offer[0].endAmount == 1, "CE");

        purchasePrice = TheCollectorsNFTVaultSeaportAssetsHolderImpl(_as.assetsHolders[vaultId]).buyAdvancedNFTOnSeaport(
            advancedOrder, criteriaResolvers, fulfillerConduitKey, purchasePrice, _as.seaportAddress
        );

        _afterPurchaseNFT(vaultId, purchasePrice, true, prevERC1155Amount, totalPaid);
    }

    /*
        @dev
        Buying the agreed upon token from Seaport using matched order
        Not checking if msg.sender is a participant since a buy consensus must be met
    */
    function buyMatchedNFTOnSeaport(
        uint64 vaultId,
        Order[] calldata orders,
        Fulfillment[] calldata fulfillments
    ) external nonReentrant {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();

        uint256 prevERC1155Amount;

        if (_as.vaultsExtensions[vaultId].isERC1155) {
            prevERC1155Amount = IERC1155(_as.vaults[vaultId].collection).balanceOf(_as.assetsHolders[vaultId], _as.vaults[vaultId].tokenId);
        }

        uint256 purchasePrice;
        for (uint256 i; i < orders[0].parameters.consideration.length;) {
            if (orders[0].parameters.consideration[i].itemType == ItemType.NATIVE) {
                purchasePrice += orders[0].parameters.consideration[i].endAmount;
            }
            unchecked {
                ++i;
            }
        }

        uint256 totalPaid = _requireBuyConsensusAndValidatePurchasePrice(vaultId, purchasePrice);

        for (uint256 i; i < orders.length;) {
            if (orders[i].parameters.offer[0].itemType != ItemType.NATIVE) {
                require(
                    _as.vaults[vaultId].collection == orders[i].parameters.offer[0].token
                    && _as.vaults[vaultId].tokenId == orders[i].parameters.offer[0].identifierOrCriteria
                    && orders[i].parameters.offer[0].endAmount == 1, "CE");
            }
            unchecked {
                ++i;
            }
        }

        purchasePrice = TheCollectorsNFTVaultSeaportAssetsHolderImpl(_as.assetsHolders[vaultId]).buyMatchedNFTOnSeaport(
            orders, fulfillments, purchasePrice, _as.seaportAddress
        );

        _afterPurchaseNFT(vaultId, purchasePrice, true, prevERC1155Amount, totalPaid);
    }

    /*
        @dev
        Buying the agreed upon token from Seaport using basic order
        Not checking if msg.sender is a participant since a buy consensus must be met
    */
    function buyNFTOnSeaport(uint64 vaultId, BasicOrderParameters calldata parameters) external nonReentrant {

        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        LibDiamond.Vault storage vault = _as.vaults[vaultId];

        uint256 prevERC1155Amount;

        if (_as.vaultsExtensions[vaultId].isERC1155) {
            prevERC1155Amount = IERC1155(vault.collection).balanceOf(_as.assetsHolders[vaultId], vault.tokenId);
        }

        uint256 purchasePrice = parameters.considerationAmount;
        for (uint256 i; i < parameters.additionalRecipients.length;) {
            purchasePrice += parameters.additionalRecipients[i].amount;
            unchecked {
                ++i;
            }
        }

        uint256 totalPaid = _requireBuyConsensusAndValidatePurchasePrice(vaultId, purchasePrice);

        require(
            vault.collection == parameters.offerToken && vault.tokenId == parameters.offerIdentifier
            && parameters.offerAmount == 1, "CE");

        purchasePrice = TheCollectorsNFTVaultSeaportAssetsHolderImpl(_as.assetsHolders[vaultId]).buyNFTOnSeaport(
            parameters, purchasePrice, _as.seaportAddress
        );

        _afterPurchaseNFT(vaultId, purchasePrice, true, prevERC1155Amount, totalPaid);
    }

    /*
        @dev
        Approving the sale order in Seaport protocol.
        Please be aware that a client will still need to call opensea API to show the listing on opensea website.
        Need to check if msg.sender is a participant since after grace period is over, all undecided votes
        are considered as yes which might make the sell consensus pass
        This method verifies that this order that was sent will pass the verification done by Opensea API and it will
        be published on Opensea website
    */
    function listNFTOnSeaport(uint64 vaultId, Order memory order) external {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        LibDiamond.Vault storage vault = _as.vaults[vaultId];
        LibDiamond.VaultExtension storage vaultExtension = _as.vaultsExtensions[vaultId];
        address payable assetsHolder = _as.assetsHolders[vaultId];

        uint256 royaltiesOnChain;
        try LibDiamond.MANIFOLD_ROYALTY_REGISTRY.getRoyaltyView(vault.collection, vault.tokenId, vault.listFor)
        returns (address payable[] memory, uint256[] memory amounts) {
            for (uint256 i; i < amounts.length;) {
                royaltiesOnChain += amounts[i];
                unchecked {
                    ++i;
                }
            }
        } catch {}

        uint256 netSalePrice;
        {
            uint256 listPrice;
            uint256 openseaFees;
            uint256 creatorRoyalties;
            for (uint256 i; i < order.parameters.consideration.length;) {
                listPrice += order.parameters.consideration[i].endAmount;
                if (order.parameters.consideration[i].recipient == assetsHolder) {
                    netSalePrice = order.parameters.consideration[i].endAmount;
                } else if (_isOpenseaRecipient(order.parameters.consideration[i].recipient)) {
                    openseaFees = order.parameters.consideration[i].endAmount;
                } else {
                    creatorRoyalties = order.parameters.consideration[i].endAmount;
                }
                // No private sales
                require(order.parameters.consideration[i].itemType == ItemType.NATIVE, "E0");
                unchecked {
                    ++i;
                }
            }
            require(vault.votingFor == LibDiamond.VoteFor.Selling, "E1");

            // Making sure that list for was set and the sell price is the agreed upon price
            require(vault.listFor > 0 && vault.listFor == listPrice, "E2");

            require(isVaultPassedSellOrCancelSellOrderConsensus(vaultId), "E3");
            // Not checking if the sender is a participant to save gas.

            require(openseaFees == listPrice * 250 / LibDiamond.PERCENTAGE_DENOMINATOR, "E5");
            if (royaltiesOnChain > 0) {
                require(creatorRoyalties == royaltiesOnChain, "E5");
                uint256 royaltiesPercentage = royaltiesOnChain * LibDiamond.PERCENTAGE_DENOMINATOR / listPrice;
                require(netSalePrice == listPrice * (LibDiamond.PERCENTAGE_DENOMINATOR - 250 - royaltiesPercentage) / LibDiamond.PERCENTAGE_DENOMINATOR, "E5");
            } else {
                // There isn't any royalties on chain info, using 10% as it is the maximum royalty on Opensea
                // netSalePrice should be at least 87.5% of the listing price
                // This can open a weird attack where one of the vault participants will send their address as the royalties receiver
                // however, this will prevent Opensea from publish the order on the website. So this would be worth while only if
                // the "attacker" will buy the NFT directly from the vault but using Seaport contracts
                require(netSalePrice >= listPrice * (LibDiamond.PERCENTAGE_DENOMINATOR - 250 - 1000) / LibDiamond.PERCENTAGE_DENOMINATOR, "E5");
            }

            // Not checking if the asset holder is actually holding the asset to save gas.

            require(
                vault.collection == order.parameters.offer[0].token
                && vault.tokenId == order.parameters.offer[0].identifierOrCriteria
                && order.parameters.offer[0].endAmount == 1, "CE");
        }

        vault.netSalePrice = uint128(netSalePrice);

        (address conduitAddress,bool exists) = LibDiamond.OPENSEA_SEAPORT_CONDUIT_CONTROLLER.getConduit(order.parameters.conduitKey);
        require(exists, "Conduit does not exist");

        TheCollectorsNFTVaultSeaportAssetsHolderImpl(assetsHolder).listNFTOnSeaport(
            order, _as.seaportAddress, conduitAddress
        );

        _resetVotesAndGracePeriod(vaultId);

        vault.votingFor = LibDiamond.VoteFor.CancellingSellOrder;
        vaultExtension.listingBlockNumber = uint64(block.number);

        emit NFTListedForSale(vault.id, vault.collection, vault.tokenId, vault.listFor, order);
    }

    /*
        @dev
        Canceling a previous sale order in Seaport protocol.
        This function must be called before re-listing with another price.
    */
    function cancelNFTListingOnSeaport(uint64 vaultId, OrderComponents[] memory order) external {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        LibDiamond.Vault storage vault = _as.vaults[vaultId];
        address payable assetsHolder = _as.assetsHolders[vaultId];

        require(vault.votingFor == LibDiamond.VoteFor.CancellingSellOrder, "E1");
        // Not checking if the sender is a participant to save gas.
        require(isVaultPassedSellOrCancelSellOrderConsensus(vaultId), "E3");
        // Not checking if the asset holder is actually holding the asset to save gas.

        require(
            vault.collection == order[0].offer[0].token
            && vault.tokenId == order[0].offer[0].identifierOrCriteria
            && order[0].offer[0].endAmount == 1, "CE");

        TheCollectorsNFTVaultSeaportAssetsHolderImpl(assetsHolder).cancelNFTListingOnSeaport(
            order, _as.seaportAddress
        );

        _resetVotesAndGracePeriod(vaultId);

        vault.votingFor = LibDiamond.VoteFor.Selling;

        emit NFTSellOrderCanceled(vaultId, vault.collection, vault.tokenId);
    }

    // ==================== Seaport Management ====================

    /*
        @dev
        Set seaport address as it can change from time to time
    */
    function setSeaportAddress(address _seaportAddress) external onlyOwner {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        _as.seaportAddress = _seaportAddress;
    }

    /*
        @dev
        Set opensea fee recipients to verify 2.5% fee
    */
    function setOpenseaFeeRecipients(address[] calldata _openseaFeeRecipients) external onlyOwner {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        _as.openseaFeeRecipients = _openseaFeeRecipients;
    }

    function _isOpenseaRecipient(address recipient) internal view returns (bool) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        address[] memory openseaFeeRecipients = _as.openseaFeeRecipients;
        for (uint256 i; i < openseaFeeRecipients.length;) {
            if (recipient == openseaFeeRecipients[i]) {
                return true;
            }
            unchecked {
                ++i;
            }
        }
        return false;
    }
}

// SPDX-License-Identifier: UNLICENSED
// © 2022 The Collectors. All rights reserved.
pragma solidity ^0.8.13;

import "./TheCollectorsNFTVaultBaseFacet.sol";

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

    ████████╗ ██████╗ ██╗  ██╗███████╗███╗   ██╗    ███╗   ███╗ █████╗ ███╗   ██╗ █████╗  ██████╗ ███████╗██████╗
    ╚══██╔══╝██╔═══██╗██║ ██╔╝██╔════╝████╗  ██║    ████╗ ████║██╔══██╗████╗  ██║██╔══██╗██╔════╝ ██╔════╝██╔══██╗
       ██║   ██║   ██║█████╔╝ █████╗  ██╔██╗ ██║    ██╔████╔██║███████║██╔██╗ ██║███████║██║  ███╗█████╗  ██████╔╝
       ██║   ██║   ██║██╔═██╗ ██╔══╝  ██║╚██╗██║    ██║╚██╔╝██║██╔══██║██║╚██╗██║██╔══██║██║   ██║██╔══╝  ██╔══██╗
       ██║   ╚██████╔╝██║  ██╗███████╗██║ ╚████║    ██║ ╚═╝ ██║██║  ██║██║ ╚████║██║  ██║╚██████╔╝███████╗██║  ██║
       ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝    ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝

    ███████╗ █████╗  ██████╗███████╗████████╗
    ██╔════╝██╔══██╗██╔════╝██╔════╝╚══██╔══╝
    █████╗  ███████║██║     █████╗     ██║
    ██╔══╝  ██╔══██║██║     ██╔══╝     ██║
    ██║     ██║  ██║╚██████╗███████╗   ██║
    ╚═╝     ╚═╝  ╚═╝ ╚═════╝╚══════╝   ╚═╝
    @dev
    The facet that handling all NFT vault token logic and can be called only by @TheCollectorsNFTVaultDiamond
    This contract is part of a diamond / facets implementation as described
    in EIP 2535 (https://eips.ethereum.org/EIPS/eip-2535)
*/
contract TheCollectorsNFTVaultTokenManagerFacet is TheCollectorsNFTVaultBaseFacet, ERC721, IERC2981 {
    using Counters for Counters.Counter;
    using Strings for uint256;
    using Strings for uint64;
    using EnumerableSet for EnumerableSet.UintSet;

    constructor() ERC721("The Collectors NFT Vault", "TheCollectorsNFTVault") {}

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return
        interfaceId == type(IERC2981).interfaceId ||
        interfaceId == type(IDiamondLoupe).interfaceId ||
        interfaceId == type(IDiamondCut).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    // =========== EIP2981 ===========

    function royaltyInfo(uint256, uint256 _salePrice)
    external
    view
    override
    returns (address receiver, uint256 royaltyAmount) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return (_as.royaltiesRecipient, (_salePrice * _as.royaltiesBasisPoints) / LibDiamond.PERCENTAGE_DENOMINATOR);
    }

    // ==================== Token management ====================

    /*
        @dev
        Claiming the partial vault NFT that represents the participate share of the original token the vault bought.
        Additionally, sending back any leftovers the participate is eligible to get in case the purchase amount
        was lower than the total amount that the vault was funded for
    */
    function claimVaultTokenAndGetLeftovers(uint64 vaultId) external nonReentrant {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        require(_as.vaults[vaultId].votingFor == LibDiamond.VoteFor.Selling
            || _as.vaults[vaultId].votingFor == LibDiamond.VoteFor.CancellingSellOrder, "E1");
        uint256 currentTokenId = _as.tokenIdTracker.current();
        uint24 numberOfParticipants = _as.vaultsExtensions[vaultId].numberOfParticipants;
        for (uint256 i; i < numberOfParticipants;) {
            LibDiamond.Participant storage participant = _as.vaultParticipants[vaultId][i];
            if (participant.participant == msg.sender && participant.partialNFTVaultTokenId == 0) {
                // Only participants who has ownership can claim vault token
                // Can check ownership > 0 and not call @_getPercentage because
                // this method can be called only after purchasing
                // Using ownership > 0 will save gas
                require(participant.ownership > 0, "E3");
                participant.partialNFTVaultTokenId = uint48(currentTokenId);
                _as.vaultTokens[currentTokenId] = vaultId;
                _mint(msg.sender, currentTokenId);
                if (participant.leftovers > 0) {
                    // No need to update the participant object before because we use nonReentrant
                    // By not using another variable the contract size is smaller
                    IAssetsHolderImpl(_as.assetsHolders[vaultId]).sendValue(payable(participant.participant), participant.leftovers);
                    participant.leftovers = 0;
                }
                emit VaultTokenClaimed(vaultId, msg.sender, currentTokenId);
                _as.tokenIdTracker.increment();
                currentTokenId = _as.tokenIdTracker.current();
                // Not having a break here as one address can hold multiple seats
            }
            unchecked {
                ++i;
            }
        }
    }

    /*
        @dev
        Burning the partial vault NFT in order to get the proceeds from the NFT sale.
        Additionally, sending back the staked Collector to the original owner in case a collector was staked.
        Sending the protocol fee in case the participate did not stake a Collector
    */
    function redeemToken(uint256 tokenId, bool searchAndRemoveVaultId) external nonReentrant {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        uint64 vaultId = _as.vaultTokens[tokenId];

        // Making sure the sender is the owner of the token
        // No need to send it to the vault (avoiding an approve request)
        // Cannot call twice to this function because after first redeem the owner of tokenId is address(0)
        require(ownerOf(tokenId) == msg.sender, "E1");
        // Making sure the asset holder is not the owner of the token to know that it was sold
        require(isVaultSoldNFT(vaultId), "E2");

        address payable assetsHolder = _as.assetsHolders[vaultId];
        LibDiamond.Vault storage vault = _as.vaults[vaultId];
        uint24 numberOfParticipants = _as.vaultsExtensions[vaultId].numberOfParticipants;
        for (uint256 i; i < numberOfParticipants;) {
            LibDiamond.Participant storage participant = _as.vaultParticipants[vaultId][i];
            if (participant.partialNFTVaultTokenId == tokenId) {
                _burn(tokenId);
                uint256 percentage = participant.ownership;
                // The actual ETH the vault got from the sale deducting marketplace fees and collection royalties
                uint256 salePriceDeductingFees = vault.netSalePrice / 100;
                // The participate share from the proceeds
                uint256 profits = salePriceDeductingFees * percentage / 1e18;
                // Protocol fee, will be zero if a Collector was staked
                uint256 stakingFee = participant.collectorOwner != address(0) ? 0 : profits * LibDiamond.STAKING_FEE / LibDiamond.PERCENTAGE_DENOMINATOR;
                // Liquidity fee, will be zero if a Collector was staked
                uint256 liquidityFee = participant.collectorOwner != address(0) ? 0 : profits * LibDiamond.LIQUIDITY_FEE / LibDiamond.PERCENTAGE_DENOMINATOR;
                // Sending proceeds
                IAssetsHolderImpl(assetsHolder).sendValue(
                    payable(participant.participant),
                    profits - stakingFee - liquidityFee
                );
                if (stakingFee > 0) {
                    IAssetsHolderImpl(assetsHolder).sendValue(payable(_as.stakingWallet), stakingFee);
                }
                if (liquidityFee > 0) {
                    IAssetsHolderImpl(assetsHolder).sendValue(payable(_as.liquidityWallet), liquidityFee);
                }
                if (participant.collectorOwner != address(0)) {
                    // In case the partial NFT was sold to someone else, the original collector owner still
                    // going to get their token back
                    IAssetsHolderImpl(assetsHolder).transferToken(
                        false,
                        participant.collectorOwner,
                        address(LibDiamond.THE_COLLECTORS),
                        participant.stakedCollectorTokenId
                    );
                }
                if (searchAndRemoveVaultId) {
                    // Removing this vault from the collection's list
                    uint64[] storage vaults = _as.collectionsVaults[vault.collection];
                    for (uint256 j; j < vaults.length; j++) {
                        if (vaults[j] == vaultId) {
                            vaults[j] = vaults[vaults.length - 1];
                            vaults.pop();
                            break;
                        }
                    }
                }
                emit VaultTokenRedeemed(vaultId, participant.participant, tokenId);
                // In previous version the participant was removed from the vault but after
                // adding the executeTransaction functionality it was decided to keep the participant in case
                // the vault will need to execute a transaction after selling the NFT
                // i.e a previous owner of an NFT collection is eligible for whitelisting in new collection

                // Removing partial NFT from storage
                delete _as.vaultTokens[tokenId];
                // Keeping the break here although participants can hold more than 1 seat if they would buy the
                // vault NFT after the vault bought the original NFT
                // If needed, the participant can just call this method again
                break;
            }
            unchecked {
                ++i;
            }
        }
    }

    // =========== ERC721 ===========

    /*
        @dev
        Burn fractional token, can only be called by the owner
    */
    function burnFractionalToken(uint256 partialNFTVaultTokenId) external {
        require(IERC721(address(this)).ownerOf(partialNFTVaultTokenId) == msg.sender, "E1");
        _burn(partialNFTVaultTokenId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(_as.baseTokenURI, _as.vaultTokens[tokenId].toString(), "/", tokenId.toString(), ".json"));
    }

    /*
        @dev
        Overriding transfer as the partial NFT can be sold or transfer to another address
        Check out the implementation to learn more
    */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        _transferNFTVaultToken(from, to, tokenId);
    }

    // ==================== Views ====================

    function royaltiesRecipient() external view returns (address) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return _as.royaltiesRecipient;
    }

    function royaltiesBasisPoints() external view returns (uint256) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return _as.royaltiesBasisPoints;
    }

    /*
        @dev
        Allowlist Seaport's conduit contract to enable gas-less listings.
    */
    function isApprovedForAll(address owner, address operator) public virtual override view returns (bool) {
        try LibDiamond.OPENSEA_SEAPORT_CONDUIT_CONTROLLER.getChannelStatus(
            operator, LibDiamond.appStorage().seaportAddress
        ) returns (bool isOpen) {
            if (isOpen) {
                return true;
            }
        } catch {}

        return super.isApprovedForAll(owner, operator);
    }

    /*
        @dev
        This method will return the total percentage owned by an address of a given collection
        meaning one address can have more than 100% of a collection ownership
    */
    function getCollectionOwnership(address collection, address collector) public view returns (uint256) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        uint64[] memory vaults = _as.collectionsVaults[collection];
        uint256 ownership;
        for (uint256 i; i < vaults.length; i++) {
            uint64 vaultId = vaults[i];
            if (!isVaultSoldNFT(vaultId)) {
                for (uint256 j; j < _as.vaultsExtensions[vaultId].numberOfParticipants; j++) {
                    if (_as.vaultParticipants[vaultId][j].participant == collector) {
                        ownership += _as.vaultParticipants[vaultId][j].ownership;
                    }
                }
            }
        }
        return ownership;
    }

    /*
        @dev
        Return the vaults of a specific collection
    */
    function getCollectionVaults(address collection) public view returns (uint64[] memory vaultIds) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        vaultIds = _as.collectionsVaults[collection];
    }

    // ==================== Management ====================

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
        The wallet to receive royalties base on EIP 2981
    */
    function setRoyaltiesRecipient(address _royaltiesRecipient) external onlyOwner {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        _as.royaltiesRecipient = _royaltiesRecipient;
    }

    /*
        @dev
        The wallet to receive royalties base on EIP 2981
    */
    function setRoyaltiesBasisPoints(uint256 _royaltiesBasisPoints) external onlyOwner {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        _as.royaltiesBasisPoints = _royaltiesBasisPoints;
    }

    // ==================== Internals ====================

    /*
        @dev
        Overriding transfer as the partial NFT can be sold or transfer to another address
        In case that happens, the new owner is becomes a participate in the vault
        This is the reason why @vote method does not have a break inside the for loop
    */
    function _transferNFTVaultToken(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        // Checking the sender, if it is seaport conduit than this is an opensea sale of the vault token
        try LibDiamond.OPENSEA_SEAPORT_CONDUIT_CONTROLLER.getChannelStatus(msg.sender, _as.seaportAddress) returns (bool isOpen) {
            if (isOpen) {
                // Buyer / Seller protection
                // In order to make sure no side is getting rekt, a token of a sold vault cannot be traded
                // but just redeemed so there won't be a situation where a token that only worth 10 ETH
                // is sold for more, or the other way around
                require(!isVaultSoldNFT(_as.vaultTokens[tokenId]), "Cannot sell, only redeem");
            }
        } catch {}
        super._transfer(from, to, tokenId);
        if (from != address(0) && to != address(0)) {
            uint64 vaultId = _as.vaultTokens[tokenId];
            uint24 numberOfParticipants = _as.vaultsExtensions[vaultId].numberOfParticipants;
            for (uint256 i; i < numberOfParticipants;) {
                LibDiamond.Participant storage participant = _as.vaultParticipants[vaultId][i];
                if (participant.partialNFTVaultTokenId == tokenId) {
                    // Replacing owner
                    // Leftovers will be 0 because when claiming vault NFT the contract sends back the leftovers
                    participant.participant = to;
                    // Resetting votes
                    participant.vote = false;
                    participant.voteDate = 0;
                    // Resetting grace period to prevent a situation where 1 participant started a sell process and
                    // other participants sold their share but immediately get into a vault where the first participant
                    // can sell the underlying NFT
                    if (_as.vaults[vaultId].endGracePeriodForSellingOrCancellingSellOrder > 0) {
                        _as.vaults[vaultId].endGracePeriodForSellingOrCancellingSellOrder = uint32(block.timestamp + _as.vaults[vaultId].gracePeriodForSellingOrCancellingSellOrder);
                    }
                    break;
                }
                unchecked {
                    ++i;
                }
            }
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamond Standard: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import "../Imports.sol";
import "../Interfaces.sol";
import "../LibDiamond.sol";

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

    ██████╗ ██╗ █████╗ ███╗   ███╗ ██████╗ ███╗   ██╗██████╗      ██████╗██╗   ██╗████████╗
    ██╔══██╗██║██╔══██╗████╗ ████║██╔═══██╗████╗  ██║██╔══██╗    ██╔════╝██║   ██║╚══██╔══╝
    ██║  ██║██║███████║██╔████╔██║██║   ██║██╔██╗ ██║██║  ██║    ██║     ██║   ██║   ██║
    ██║  ██║██║██╔══██║██║╚██╔╝██║██║   ██║██║╚██╗██║██║  ██║    ██║     ██║   ██║   ██║
    ██████╔╝██║██║  ██║██║ ╚═╝ ██║╚██████╔╝██║ ╚████║██████╔╝    ╚██████╗╚██████╔╝   ██║
    ╚═════╝ ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═════╝      ╚═════╝ ╚═════╝    ╚═╝

     █████╗ ███╗   ██╗██████╗     ██╗      ██████╗ ██╗   ██╗██████╗ ███████╗    ███████╗ █████╗  ██████╗███████╗████████╗
    ██╔══██╗████╗  ██║██╔══██╗    ██║     ██╔═══██╗██║   ██║██╔══██╗██╔════╝    ██╔════╝██╔══██╗██╔════╝██╔════╝╚══██╔══╝
    ███████║██╔██╗ ██║██║  ██║    ██║     ██║   ██║██║   ██║██████╔╝█████╗      █████╗  ███████║██║     █████╗     ██║
    ██╔══██║██║╚██╗██║██║  ██║    ██║     ██║   ██║██║   ██║██╔═══╝ ██╔══╝      ██╔══╝  ██╔══██║██║     ██╔══╝     ██║
    ██║  ██║██║ ╚████║██████╔╝    ███████╗╚██████╔╝╚██████╔╝██║     ███████╗    ██║     ██║  ██║╚██████╗███████╗   ██║
    ╚═╝  ╚═╝╚═╝  ╚═══╝╚═════╝     ╚══════╝ ╚═════╝  ╚═════╝ ╚═╝     ╚══════╝    ╚═╝     ╚═╝  ╚═╝ ╚═════╝╚══════╝   ╚═╝
    @dev
    The facet that handling all diamond related logic and can be called only by @TheCollectorsNFTVaultDiamond
    This contract is part of a diamond / facets implementation as described
    in EIP 2535 (https://eips.ethereum.org/EIPS/eip-2535)
*/
contract TheCollectorsNFTVaultDiamondCutAndLoupeFacet is Ownable, IDiamondCut, IDiamondLoupe {

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        IDiamondCut.FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external onlyOwner {
        LibDiamond.diamondCut(_diamondCut, _init, _calldata);
    }

    /// These functions are expected to be called frequently by tools.

    /// @notice Gets all facets and their selectors.
    /// @return facets_ Facet
    function facets() external override view returns (Facet[] memory facets_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 numFacets = ds.facetAddresses.length;
        facets_ = new Facet[](numFacets);
        for (uint256 i; i < numFacets; i++) {
            address facetAddress_ = ds.facetAddresses[i];
            facets_[i].facetAddress = facetAddress_;
            facets_[i].functionSelectors = ds.facetFunctionSelectors[facetAddress_].functionSelectors;
        }
    }

    /// @notice Gets all the function selectors provided by a facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet) external override view returns (bytes4[] memory facetFunctionSelectors_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        facetFunctionSelectors_ = ds.facetFunctionSelectors[_facet].functionSelectors;
    }

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external override view returns (address[] memory facetAddresses_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        facetAddresses_ = ds.facetAddresses;
    }

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external override view returns (address facetAddress_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        facetAddress_ = ds.selectorToFacetAndPosition[_functionSelector].facetAddress;
    }
}

// SPDX-License-Identifier: UNLICENSED
// © 2022 The Collectors. All rights reserved.
pragma solidity ^0.8.13;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamond Standard: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import "./Interfaces.sol";
import "./Imports.sol";

library LibDiamond {
    using EnumerableSet for EnumerableSet.Set;

    // ==================== Diamond Constants ====================

    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");
    bytes32 constant APP_STORAGE_POSITION = keccak256("diamond.standard.app.storage");
    bytes32 public constant ASSETS_HOLDER_STORAGE_POSITION = keccak256("collectors.assets.holder.storage");

    // ==================== Constants ====================

    uint256 public constant LIQUIDITY_FEE = 50; // 0.5%
    uint256 public constant STAKING_FEE = 200; // 2%
    uint256 public constant PERCENTAGE_DENOMINATOR = 10000;
    // Participant can stake a collector to not pay protocol fee
    IERC721 public constant THE_COLLECTORS = IERC721(0x4f35a6D8423fADD1BFb30aaE589AF136eCF91e77);

    IOpenseaSeaportConduitController public constant OPENSEA_SEAPORT_CONDUIT_CONTROLLER = IOpenseaSeaportConduitController(0x00000000F9490004C11Cef243f5400493c00Ad63);
    IManifoldRoyaltyRegistry public constant MANIFOLD_ROYALTY_REGISTRY = IManifoldRoyaltyRegistry(0x0385603ab55642cb4Dd5De3aE9e306809991804f);

    // ==================== Structs ====================

    struct AssetsHolderStorage {
        address target;
        bytes data;
        uint256 value;
        mapping(address => bool) consensus;
        bool listed;
        uint64 vaultId;
        address implementation;
        address owner;
    }

    // Represents 1 participant of an NFT vault
    struct Participant {
        // How much the participant funded the vault
        // This number will be reduced after buying the NFT in case total paid was higher than purchase price
        uint128 paid;
        // In case total paid was higher than purchase price, how much the participant will get back
        uint128 leftovers;
        // The token id of the partial NFT
        // In case a vault with 4 participants bought BAYC, 4 partials NFTs will be minted respectively
        uint48 partialNFTVaultTokenId;
        // The participant of the vault
        address participant;
        // The staked collector token id
        // Can use uint16 because the collectors will only have 10K tokens
        uint16 stakedCollectorTokenId;
        // Who is the owner of the staked collector. In a situation where the participant sold his seat in the vault,
        // the collector will be staked until the token the vault bought is sold and the participant redeemed
        // the partial NFT
        address collectorOwner;
        // The ownership percentage of this participant in the vault
        // This property will be calculated only after purchasing
        uint128 ownership;
        // Whatever the participant voted for or against buying/selling/cancelling order
        // Depends on vault.votingFor
        // Waiting (can't vote), Buying (voting to buy), Selling (voting to sell), Cancelling (voting to cancel order)
        bool vote;
        // The participant last vote date
        // If the vault's last vote date is higher than this, then the participant didn't vote
        // on the current voting process
        uint48 voteDate;
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
        // The name of the vault
        bytes32 name;
        // The token id that the vault is planning to buy, or already bought, or listing for sale
        // This variable can be changed while the DAO is considering which token id to buy,
        // however, after purchasing, this value will not change
        uint256 tokenId;
        // How much % of ownership needed to decide if to sell or cancel a sell order
        // Please notice that in case a participant did not vote and the
        // endGracePeriodForSellingOrCancellingSellOrder is over their vote will be considered as yes
        uint128 sellOrCancelSellOrderConsensus;
        // How much % of ownership needed to decide if to buy or not
        uint128 buyConsensus;
        // Whatever the voting (stage of the vault is) for buying the NFT, selling it
        // or cancelling the sell order (to relist it again with a different price)
        VoteFor votingFor;
        // From which collection this NFT vault can buy/sell, this cannot be changed after creating the vault
        address collection;
        // How much time to give participants to vote for selling before considering their votes as yes
        uint32 gracePeriodForSellingOrCancellingSellOrder;
        // The end date of the grace period given for participates to vote on selling before considering their votes as yes
        uint32 endGracePeriodForSellingOrCancellingSellOrder;
        // The maximum amount of participant that can join the vault
        uint24 maxParticipants;
        // The unique identifier of the vault
        uint64 id;
        // The sale price after deducting fees (marketplace & royalties)
        uint128 netSalePrice;
        // The cost of the NFT bought by the vault
        uint128 purchasedFor;
        // The amount of ETH to list the token for sale
        // After this is set, the participates are voting for or against list the NFT for sale in this price
        uint128 listFor;
        // The last vote date of the current voting process
        // Everytime there is a new process (buying, selling, resetting price, cancelling
        // the last vote date will change
        uint48 lastVoteDate;
    }

     // To avoid stack too deep
    struct VaultExtension {
        // The minimum amount that a participant should fund the vault
        uint128 minimumFunding;
        // The absolute max price the vault can pay to buy the asset
        uint128 maxPriceToBuy;
        // This property is used to provide a small spacing between listing and buying to prevent attacks such as
        // one participant gets enough ownership to list the NFT for 0 and immediately buy it
        uint64 listingBlockNumber;
        // The number of participants in the vault
        uint24 numberOfParticipants;
        // Indicates if this vault's NFT was withdrawn to the participant who held 100% of the shares
        bool isWithdrawnToOwner;
        // Whatever the vault is public or not
        // There are specific limitations for public vault like minimum funding must
        // be above 0 and cannot change collection
        bool publicVault;
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
        address seaportAddress;
        address[] openseaFeeRecipients;
        mapping(uint64 => Vault) vaults;
        mapping(uint256 => uint64) vaultTokens;
        mapping(uint64 => address payable) assetsHolders;
        mapping(uint64 => VaultExtension) vaultsExtensions;
        mapping(uint64 => mapping(uint256 => Participant)) vaultParticipants;
        address nftVaultAssetHolderImpl;
        address nftVaultTokenHandler;
        Counters.Counter tokenIdTracker;
        Counters.Counter vaultIdTracker;
        string baseTokenURI;
        // Collection => VaultIds
        mapping(address => uint64[]) collectionsVaults;
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

// SPDX-License-Identifier: UNLICENSED
// © 2022 The Collectors. All rights reserved.
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/proxy/Proxy.sol";

// SPDX-License-Identifier: UNLICENSED
// © 2022 The Collectors. All rights reserved.
pragma solidity ^0.8.13;

import {BasicOrderParameters, OrderComponents, Order, AdvancedOrder, CriteriaResolver, Fulfillment, Execution} from "./SeaportStructs.sol";

interface IOpenseaSeaport {
    function fulfillBasicOrder(BasicOrderParameters calldata parameters) external payable returns (bool fulfilled);

    function fulfillAdvancedOrder(
        AdvancedOrder calldata advancedOrder,
        CriteriaResolver[] calldata criteriaResolvers,
        bytes32 fulfillerConduitKey,
        address recipient
    ) external payable returns (bool fulfilled);

    function matchOrders(
        Order[] calldata orders,
        Fulfillment[] calldata fulfillments
    ) external payable returns (Execution[] memory executions);

    function validate(Order[] memory orders) external returns (bool validated);

    function cancel(OrderComponents[] memory orders) external returns (bool cancelled);

    function getOrderHash(OrderComponents calldata order) external view returns (bytes32 orderHash);

    function getCounter(address offerer) external view returns (uint256 counter);
}

interface IOpenseaSeaportConduitController {
    function getConduit(bytes32 conduitKey) external view returns (address conduit, bool exists);

    function getChannelStatus(address conduit, address channel) external view returns (bool isOpen);
}

interface IManifoldRoyaltyRegistry {
    function getRoyaltyView(address tokenAddress, uint256 tokenId, uint256 value) external view returns (address payable[] memory recipients, uint256[] memory amounts);
}

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

interface IAssetsHolderImpl {
    function transferToken(bool isERC1155, address recipient, address collection, uint256 tokenId) external;

    function sendValue(address payable to, uint256 amount) external;
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
pragma solidity ^0.8.13;

import {ItemType, OrderType, BasicOrderType, Side} from "./SeaportEnums.sol";

    struct AdditionalRecipient {
        uint256 amount;
        address payable recipient;
    }

    struct OfferItem {
        ItemType itemType;
        address token;
        uint256 identifierOrCriteria;
        uint256 startAmount;
        uint256 endAmount;
    }

    struct ConsiderationItem {
        ItemType itemType;
        address token;
        uint256 identifierOrCriteria;
        uint256 startAmount;
        uint256 endAmount;
        address payable recipient;
    }

    struct OrderParameters {
        address offerer; // 0x00
        address zone; // 0x20
        OfferItem[] offer; // 0x40
        ConsiderationItem[] consideration; // 0x60
        OrderType orderType; // 0x80
        uint256 startTime; // 0xa0
        uint256 endTime; // 0xc0
        bytes32 zoneHash; // 0xe0
        uint256 salt; // 0x100
        bytes32 conduitKey; // 0x120
        uint256 totalOriginalConsiderationItems; // 0x140
        // offer.length                          // 0x160
    }

    struct Order {
        OrderParameters parameters;
        bytes signature;
    }

    struct OrderComponents {
        address offerer;
        address zone;
        OfferItem[] offer;
        ConsiderationItem[] consideration;
        OrderType orderType;
        uint256 startTime;
        uint256 endTime;
        bytes32 zoneHash;
        uint256 salt;
        bytes32 conduitKey;
        uint256 counter;
    }

    struct BasicOrderParameters {
        // calldata offset
        address considerationToken; // 0x24
        uint256 considerationIdentifier; // 0x44
        uint256 considerationAmount; // 0x64
        address payable offerer; // 0x84
        address zone; // 0xa4
        address offerToken; // 0xc4
        uint256 offerIdentifier; // 0xe4
        uint256 offerAmount; // 0x104
        BasicOrderType basicOrderType; // 0x124
        uint256 startTime; // 0x144
        uint256 endTime; // 0x164
        bytes32 zoneHash; // 0x184
        uint256 salt; // 0x1a4
        bytes32 offererConduitKey; // 0x1c4
        bytes32 fulfillerConduitKey; // 0x1e4
        uint256 totalOriginalAdditionalRecipients; // 0x204
        AdditionalRecipient[] additionalRecipients; // 0x224
        bytes signature; // 0x244
        // Total length, excluding dynamic array data: 0x264 (580)
    }

    struct AdvancedOrder {
        OrderParameters parameters;
        uint120 numerator;
        uint120 denominator;
        bytes signature;
        bytes extraData;
    }

    struct CriteriaResolver {
        uint256 orderIndex;
        Side side;
        uint256 index;
        uint256 identifier;
        bytes32[] criteriaProof;
    }

    struct Fulfillment {
        FulfillmentComponent[] offerComponents;
        FulfillmentComponent[] considerationComponents;
    }

    struct FulfillmentComponent {
        uint256 orderIndex;
        uint256 itemIndex;
    }

    struct Execution {
        ReceivedItem item;
        address offerer;
        bytes32 conduitKey;
    }

    struct ReceivedItem {
        ItemType itemType;
        address token;
        uint256 identifier;
        uint256 amount;
        address payable recipient;
    }

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

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
     * by default, can be overridden in child contracts.
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
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

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
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
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
     * If overridden should call `super._beforeFallback()`.
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

    enum BasicOrderType {
        // 0: no partial fills, anyone can execute
        ETH_TO_ERC721_FULL_OPEN,

        // 1: partial fills supported, anyone can execute
        ETH_TO_ERC721_PARTIAL_OPEN,

        // 2: no partial fills, only offerer or zone can execute
        ETH_TO_ERC721_FULL_RESTRICTED,

        // 3: partial fills supported, only offerer or zone can execute
        ETH_TO_ERC721_PARTIAL_RESTRICTED,

        // 4: no partial fills, anyone can execute
        ETH_TO_ERC1155_FULL_OPEN,

        // 5: partial fills supported, anyone can execute
        ETH_TO_ERC1155_PARTIAL_OPEN,

        // 6: no partial fills, only offerer or zone can execute
        ETH_TO_ERC1155_FULL_RESTRICTED,

        // 7: partial fills supported, only offerer or zone can execute
        ETH_TO_ERC1155_PARTIAL_RESTRICTED,

        // 8: no partial fills, anyone can execute
        ERC20_TO_ERC721_FULL_OPEN,

        // 9: partial fills supported, anyone can execute
        ERC20_TO_ERC721_PARTIAL_OPEN,

        // 10: no partial fills, only offerer or zone can execute
        ERC20_TO_ERC721_FULL_RESTRICTED,

        // 11: partial fills supported, only offerer or zone can execute
        ERC20_TO_ERC721_PARTIAL_RESTRICTED,

        // 12: no partial fills, anyone can execute
        ERC20_TO_ERC1155_FULL_OPEN,

        // 13: partial fills supported, anyone can execute
        ERC20_TO_ERC1155_PARTIAL_OPEN,

        // 14: no partial fills, only offerer or zone can execute
        ERC20_TO_ERC1155_FULL_RESTRICTED,

        // 15: partial fills supported, only offerer or zone can execute
        ERC20_TO_ERC1155_PARTIAL_RESTRICTED,

        // 16: no partial fills, anyone can execute
        ERC721_TO_ERC20_FULL_OPEN,

        // 17: partial fills supported, anyone can execute
        ERC721_TO_ERC20_PARTIAL_OPEN,

        // 18: no partial fills, only offerer or zone can execute
        ERC721_TO_ERC20_FULL_RESTRICTED,

        // 19: partial fills supported, only offerer or zone can execute
        ERC721_TO_ERC20_PARTIAL_RESTRICTED,

        // 20: no partial fills, anyone can execute
        ERC1155_TO_ERC20_FULL_OPEN,

        // 21: partial fills supported, anyone can execute
        ERC1155_TO_ERC20_PARTIAL_OPEN,

        // 22: no partial fills, only offerer or zone can execute
        ERC1155_TO_ERC20_FULL_RESTRICTED,

        // 23: partial fills supported, only offerer or zone can execute
        ERC1155_TO_ERC20_PARTIAL_RESTRICTED
    }

    enum ItemType {
        // 0: ETH on mainnet, MATIC on polygon, etc.
        NATIVE,

        // 1: ERC20 items (ERC777 and ERC20 analogues could also technically work)
        ERC20,

        // 2: ERC721 items
        ERC721,

        // 3: ERC1155 items
        ERC1155,

        // 4: ERC721 items where a number of tokenIds are supported
        ERC721_WITH_CRITERIA,

        // 5: ERC1155 items where a number of ids are supported
        ERC1155_WITH_CRITERIA
    }

    enum OrderType {
        // 0: no partial fills, anyone can execute
        FULL_OPEN,

        // 1: partial fills supported, anyone can execute
        PARTIAL_OPEN,

        // 2: no partial fills, only offerer or zone can execute
        FULL_RESTRICTED,

        // 3: partial fills supported, only offerer or zone can execute
        PARTIAL_RESTRICTED
    }

    enum Side {
        // 0: Items that can be spent
        OFFER,

        // 1: Items that must be received
        CONSIDERATION
    }

// SPDX-License-Identifier: UNLICENSED
// © 2022 The Collectors. All rights reserved.
pragma solidity ^0.8.13;

import "./Imports.sol";
import "./LibDiamond.sol";
import "./TheCollectorsNFTVaultSeaportAssetsHolderImpl.sol";

/*
    -----_______.-_______------___------.______-----______---.______-----.___________.
    ----/-------||---____|----/---\-----|---_--\---/--__--\--|---_--\----|-----------|
    ---|---(----`|--|__------/--^--\----|--|_)--|-|--|--|--|-|--|_)--|---`---|--|----`
    ----\---\----|---__|----/--/_\--\---|---___/--|--|--|--|-|------/--------|--|-----
    .----)---|---|--|____--/--_____--\--|--|------|--`--'--|-|--|\--\----.---|--|-----
    |_______/----|_______|/__/-----\__\-|-_|-------\______/--|-_|-`._____|---|__|-----
    -----___-----------_______.-----_______.-_______-.___________.----_______.--------
    ----/---\---------/-------|----/-------||---____||-----------|---/-------|--------
    ---/--^--\-------|---(----`---|---(----`|--|__---`---|--|----`--|---(----`--------
    --/--/_\--\-------\---\--------\---\----|---__|------|--|--------\---\------------
    -/--_____--\--.----)---|---.----)---|---|--|____-----|--|----.----)---|-----------
    /__/-----\__\-|_______/----|_______/----|_______|----|__|----|_______/------------
    -__----__----______----__-------_______---_______-.______-------------------------
    |--|--|--|--/--__--\--|--|-----|-------\-|---____||---_--\------------------------
    |--|__|--|-|--|--|--|-|--|-----|--.--.--||--|__---|--|_)--|-----------------------
    |---__---|-|--|--|--|-|--|-----|--|--|--||---__|--|------/------------------------
    |--|--|--|-|--`--'--|-|--`----.|--'--'--||--|____-|--|\--\----.-------------------
    |__|--|__|--\______/--|_______||_______/-|_______||-_|-`._____|-------------------
    .______---.______--------______---___---___-____----____--------------------------
    |---_--\--|---_--\------/--__--\--\--\-/--/-\---\--/---/--------------------------
    |--|_)--|-|--|_)--|----|--|--|--|--\--V--/---\---\/---/---------------------------
    |---___/--|------/-----|--|--|--|--->---<-----\_----_/----------------------------
    |--|------|--|\--\----.|--`--'--|--/--.--\------|--|------------------------------
    |-_|------|-_|-`._____|-\______/--/__/-\__\-----|__|------------------------------
    ----------------------------------------------------------------------------------
    @dev
    The contract that will hold the assets and ETH for each vault.
    Working together with @TheCollectorsNFTVaultSeaportAssetsHolderImpl in a proxy/implementation design pattern.
    The reason why it is separated to proxy and implementation is to save gas when creating vaults
*/
contract TheCollectorsNFTVaultSeaportAssetsHolderProxy {

    constructor(address impl, uint64 _vaultId) {
        LibDiamond.AssetsHolderStorage storage ahs = _getAssetsHolderStorage();
        ahs.implementation = impl;
        ahs.vaultId = _vaultId;
        ahs.owner = msg.sender;
    }

    // ==================== Proxy ====================

    fallback() external payable virtual {
        address implementation = _getAssetsHolderStorage().implementation;
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
                return (0, returndatasize())
            }
        }
    }

    // ==================== Internals ====================

    function _getAssetsHolderStorage() internal pure returns (LibDiamond.AssetsHolderStorage storage ahs) {
        bytes32 position = LibDiamond.ASSETS_HOLDER_STORAGE_POSITION;
        assembly {
            ahs.slot := position
        }
    }

}

// SPDX-License-Identifier: UNLICENSED
// © 2022 The Collectors. All rights reserved.
pragma solidity ^0.8.13;

import "./Imports.sol";
import "./Interfaces.sol";
import "./LibDiamond.sol";
import {BasicOrderParameters, OrderComponents, Order, AdvancedOrder, CriteriaResolver} from "./SeaportStructs.sol";

interface INFTVault {
    function getVaultParticipants(uint64 vaultId) external view returns (LibDiamond.Participant[] memory);

    function validateSale(uint64 vaultId) external view returns (bool);
}

/*
    -______---______---______---______--______---______--______--
    /\--___\-/\--___\-/\--__-\-/\--==-\/\--__-\-/\--==-\/\__--_\-
    \-\___--\\-\--__\-\-\--__-\\-\--_-/\-\-\/\-\\-\--__<\/_/\-\/-
    -\/\_____\\-\_____\\-\_\-\_\\-\_\---\-\_____\\-\_\-\_\-\-\_\-
    --\/_____/-\/_____/-\/_/\/_/-\/_/----\/_____/-\/_/-/_/--\/_/-
    -______---______---______---______--______--______-----------
    /\--__-\-/\--___\-/\--___\-/\--___\/\__--_\/\--___\----------
    \-\--__-\\-\___--\\-\___--\\-\--__\\/_/\-\/\-\___--\---------
    -\-\_\-\_\\/\_____\\/\_____\\-\_____\-\-\_\-\/\_____\--------
    --\/_/\/_/-\/_____/-\/_____/-\/_____/--\/_/--\/_____/--------
    -__--__---______---__-------_____----______---______---------
    /\-\_\-\-/\--__-\-/\-\-----/\--__-.-/\--___\-/\--==-\--------
    \-\--__-\\-\-\/\-\\-\-\____\-\-\/\-\\-\--__\-\-\--__<--------
    -\-\_\-\_\\-\_____\\-\_____\\-\____--\-\_____\\-\_\-\_\------
    --\/_/\/_/-\/_____/-\/_____/-\/____/--\/_____/-\/_/-/_/------
    -------------------------------------------------------------
    @dev
    The business logic code of the asset holder.
    Working together with @TheCollectorsNFTVaultSeaportAssetsHolderProxy in a proxy/implementation design pattern.
    The reason why it is separated to proxy and implementation is to save gas when creating vaults.
    This contract is able to purchase and list NFTs on Opensea's new protocol Seaport
*/
contract TheCollectorsNFTVaultSeaportAssetsHolderImpl is ERC721Holder, ERC1155Holder {

    /**
 * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_getAssetsHolderStorage().owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /*
        @dev
        Buying the requested NFT on Seaport using an AdvancedOrder
    */
    function buyAdvancedNFTOnSeaport(
        AdvancedOrder calldata advancedOrder,
        CriteriaResolver[] calldata criteriaResolvers,
        bytes32 fulfillerConduitKey,
        uint256 price,
        address seaport
    ) external onlyOwner returns (uint256) {
        uint256 balanceBefore = address(this).balance;
        require(IOpenseaSeaport(seaport).fulfillAdvancedOrder{value : price}(
                advancedOrder,
                criteriaResolvers,
                fulfillerConduitKey,
                address(0)
            ), "Order not fulfilled");
        return balanceBefore - address(this).balance;
    }

    /*
        @dev
        Buying the requested NFT on Seaport using an BasicOrder
    */
    function buyNFTOnSeaport(
        BasicOrderParameters calldata parameters,
        uint256 price,
        address seaport
    ) external onlyOwner returns (uint256) {
        uint256 balanceBefore = address(this).balance;
        require(IOpenseaSeaport(seaport).fulfillBasicOrder{value : price}(parameters), "Order not fulfilled");
        return balanceBefore - address(this).balance;
    }

    /*
        @dev
        Buying the requested NFT on Seaport
    */
    function buyMatchedNFTOnSeaport(
        Order[] calldata orders,
        Fulfillment[] calldata fulfillments,
        uint256 price,
        address seaport
    ) external onlyOwner returns (uint256) {
        uint256 balanceBefore = address(this).balance;
        Execution[] memory executions = IOpenseaSeaport(seaport).matchOrders{value : price}(
            orders, fulfillments
        );
        require(executions.length > 0, "Order not fulfilled");
        return balanceBefore - address(this).balance;
    }

    /*
        @dev
        Making sure the collection is approved and then validating the order
        The FE will need to call Opensea's API to make sure the NFT listed on the website
        Using the @receive function to prevent buying in the next 4 blocks
    */
    function listNFTOnSeaport(
        Order memory order,
        address seaport,
        address conduitAddress
    ) external onlyOwner {
        if (!IApproveableNFT(order.parameters.offer[0].token).isApprovedForAll(address(this), conduitAddress)) {
            IApproveableNFT(order.parameters.offer[0].token).setApprovalForAll(conduitAddress, true);
        }
        require(IOpenseaSeaport(seaport).validate(_toOrders(order)), "Order not validated");
        _getAssetsHolderStorage().listed = true;
    }

    /*
        @dev
        Cancelling sell order of the requested NFT on Seaport
    */
    function cancelNFTListingOnSeaport(
        OrderComponents[] memory order,
        address seaport
    ) external onlyOwner {
        _getAssetsHolderStorage().listed = false;
        require(IOpenseaSeaport(seaport).cancel(order), "Order not cancelled");
    }

    /*
        @dev
        Transferring the assets to someone else, can only be called by the owner
    */
    function transferToken(bool isERC1155, address recipient, address collection, uint256 tokenId) external onlyOwner {
        if (isERC1155) {
            IERC1155(collection).safeTransferFrom(address(this), recipient, tokenId, 1, "");
        } else {
            IERC721(collection).safeTransferFrom(address(this), recipient, tokenId);
        }
    }

    /*
        @dev
        Transferring ETH to someone else, can only be called by the owner
    */
    function sendValue(address payable to, uint256 amount) external onlyOwner {
        Address.sendValue(to, amount);
    }

    /*
        @dev
        Confirming or executing a transaction just like a multisig contract
        Initially the contract did not contain this functionality, however, after reconsidering claiming and airdrop
        scenarios it was decided to add it.
        Please notice that a 100% consensus is needed to run a transaction and without any grace period.
    */
    function executeTransaction(address _target, bytes memory _data, uint256 _value) external {
        LibDiamond.AssetsHolderStorage storage ahs = _getAssetsHolderStorage();
        LibDiamond.Participant[] memory participants = INFTVault(ahs.owner).getVaultParticipants(
            ahs.vaultId
        );
        // Only a participant with ownership can confirm or execute transactions
        // Only after the nft vault has purchased the NFT the participants getting the ownership property filled
        require(_isParticipantExistsWithOwnership(participants, msg.sender), "E1");

        if (ahs.target == _target && keccak256(_data) == keccak256(ahs.data)
            && _value == ahs.value) {
            // Approving current transaction
            ahs.consensus[msg.sender] = true;
        } else {
            // New transaction and overriding previous transaction
            ahs.target = _target;
            ahs.data = _data;
            ahs.value = _value;
            for (uint256 i; i < participants.length;) {
                // Resetting all votes expect the sender
                ahs.consensus[participants[i].participant] = participants[i].participant == msg.sender;
                unchecked {
                    ++i;
                }
            }
        }

        bool passedConsensus = true;
        for (uint256 i; i < participants.length;) {
            // We need to check ownership > 0 because some participants can be in the vault but did not contribute
            // any funds (i.e were added by the vault creator)
            if (participants[i].ownership > 0 && !ahs.consensus[participants[i].participant]) {
                passedConsensus = false;
                break;
            }
            unchecked {
                ++i;
            }
        }

        if (passedConsensus) {
            if (Address.isContract(ahs.target)) {
                Address.functionCallWithValue(
                    ahs.target, ahs.data, ahs.value
                );
            } else {
                Address.sendValue(payable(ahs.target), ahs.value);
            }

            // Resetting votes and transaction
            for (uint256 i; i < participants.length;) {
                ahs.consensus[participants[i].participant] = false;
                unchecked {
                    ++i;
                }
            }
            ahs.target = address(0);
            ahs.data = "";
            ahs.value = 0;
        }
    }

    // ==================== Internals ====================

    function _toOrders(Order memory order) internal pure returns (Order[] memory) {
        Order[] memory orders = new Order[](1);
        orders[0] = order;
        return orders;
    }

    /*
        @dev
        A helper function to find out if a participant is part of a vault with ownership
    */
    function _isParticipantExistsWithOwnership(LibDiamond.Participant[] memory participants, address participant) internal pure returns (bool) {
        for (uint256 i; i < participants.length; i++) {
            if (participants[i].ownership > 0 && participants[i].participant == participant) {
                return true;
            }
        }
        return false;
    }

    function _getAssetsHolderStorage() internal pure returns (LibDiamond.AssetsHolderStorage storage ahs) {
        bytes32 position = LibDiamond.ASSETS_HOLDER_STORAGE_POSITION;
        assembly {
            ahs.slot := position
        }
    }

    /*
        @dev
        Since in current Seaport protocol there isn't any way to set up a static call to verify the sale after
        it happen, we are using the receive function to verify the sale.
        Since the vault is always selling only in ETH this will always work
    */
    receive() external payable {
        if (_getAssetsHolderStorage().listed) {
            require(INFTVault(_getAssetsHolderStorage().owner).validateSale(_getAssetsHolderStorage().vaultId), "Wait ~1 minute between list and sale");
        }
    }

}