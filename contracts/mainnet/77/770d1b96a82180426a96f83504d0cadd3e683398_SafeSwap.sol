// SPDX-License-Identifier: MIT

/*
created by:
 ██████╗ ██████╗       ██╗      █████╗ ██████╗ ███████╗
██╔════╝██╔═══██╗      ██║     ██╔══██╗██╔══██╗██╔════╝
██║     ██║   ██║█████╗██║     ███████║██████╔╝███████╗
██║     ██║   ██║╚════╝██║     ██╔══██║██╔══██╗╚════██║
╚██████╗╚██████╔╝      ███████╗██║  ██║██████╔╝███████║
 ╚═════╝ ╚═════╝       ╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝
                                                       
authored by @nyoungdumb.

 */

pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./Ownable.sol";


contract SafeSwap is IERC721Receiver, Ownable {
    IERC721 private offerNFT;
    IERC721 private reqNFT;
    address payable public feeReceiver = payable(0xfD74E361244a2E4eb807583969943EEc01b60FFC);
    uint public tradeCounter = 0;
    uint public createOfferFee = 0.005 ether; 
    uint public revokeOfferFee = 0.005 ether; 
    uint public fulfillOfferFee = 0.005 ether; 
    struct TradeOffer {
        address offeror;
        address offerSmartContract;
        uint[] offerTokenIds;
        uint offerEth;
        address reqSmartContract;
        uint[] reqTokenIds;
        uint reqEth;
        uint tradeIndex;
        bool fulfilled;
        bool revoked;
    }

    TradeOffer[] public offer_record;

    mapping(address => uint[]) public IndexOfOwner;
    mapping(uint => uint) public TradeIndexOfOwnerIndex;

    //Once you create an offer, escrows the NFTs inside the swap contract. anyone can come and fulfill it unless you revoke it. 
    function createOffer(address _offerSmartContract, uint[] memory _offerTokenIds, uint _offerEth, address _reqSmartContract, uint[] memory _reqTokenIds, uint _reqEth ) public payable {
        offerNFT = ERC721(_offerSmartContract);
        require(msg.value >= _offerEth + createOfferFee, "insufficient funds");
        uint length = _offerTokenIds.length;
        for (uint i=0; i<length; i++) {
            uint _tokenId = _offerTokenIds[i];
            require(offerNFT.ownerOf(_tokenId)==msg.sender, "You don't own the NFT you are trying to offer, or you have already created an offer including it.");
            offerNFT.safeTransferFrom(msg.sender, address(this), _tokenId, "0x00");
        }
        TradeOffer memory new_offer = TradeOffer(msg.sender, _offerSmartContract, _offerTokenIds, _offerEth, _reqSmartContract,  _reqTokenIds, _reqEth, tradeCounter, false, false);
        offer_record.push(new_offer);
        TradeIndexOfOwnerIndex[tradeCounter] = IndexOfOwner[msg.sender].length;
        IndexOfOwner[msg.sender].push(tradeCounter);
        feeReceiver.transfer(createOfferFee);
        tradeCounter++;
    }
    //revokes an offer and transfers NFTs back to original offeror Only callable by the original offeror.
    function revokeOffer(uint _index) public payable {
        require(offer_record[_index].fulfilled != true, "Offer has already been fulfilled.");
        require(offer_record[_index].revoked != true, "Offer has already been revoked.");
        require(msg.value >= revokeOfferFee, "insufficient funds");
        address _offerSmartContract =  offer_record[_index].offerSmartContract;
        address payable offeror = payable(offer_record[_index].offeror);
        uint[] memory _offerTokenIds = offer_record[_index].offerTokenIds;
        uint length = _offerTokenIds.length;
        offerNFT = ERC721(_offerSmartContract);
        require(msg.sender == offer_record[_index].offeror, "You did not create this offer.");
        for (uint i=0; i<length; i++) {
            uint _tokenId = _offerTokenIds[i];
            offerNFT.safeTransferFrom(address(this), msg.sender, _tokenId, "0x00");
        }
        offer_record[_index].revoked = true;
        IndexOfOwner[msg.sender];
        offeror.transfer(offer_record[_index].offerEth);
        feeReceiver.transfer(revokeOfferFee);

    }

    //fulfills an offer and transfers NFTs according to offer data.
    function fulfillOffer(uint _index) public payable {
            require(offer_record[_index].fulfilled != true, "Offer has already been fulfilled.");
            require(offer_record[_index].revoked != true, "Offer has been revoked.");
            require(msg.value >= offer_record[_index].reqEth + fulfillOfferFee, "insufficient funds");
            address payable fulfiller = payable(msg.sender);
            address payable offeror = payable(offer_record[_index].offeror);
            offerNFT = ERC721(offer_record[_index].offerSmartContract);
            reqNFT = ERC721(offer_record[_index].reqSmartContract);
            uint[] memory offerTokenIds = getTradeOfferTokenIdsByIndex(_index);
            uint[] memory reqTokenIds = getTradeOfferReqTokenIdsByIndex(_index);
            uint offerTokensLength = offerTokenIds.length;
            uint reqTokensLength = reqTokenIds.length;
            for (uint i=0; i<offerTokensLength; i++) {
                uint _tokenId = offerTokenIds[i];
                offerNFT.safeTransferFrom(address(this), fulfiller, _tokenId, "0x00");
            }
            for (uint j=0; j<reqTokensLength; j++) {
                uint _tokenId = reqTokenIds[j];
                reqNFT.safeTransferFrom(fulfiller, offeror, _tokenId, "0x00");
            } 
            offer_record[_index].fulfilled = true;
            offeror.transfer(offer_record[_index].reqEth);
            fulfiller.transfer(offer_record[_index].offerEth);
            feeReceiver.transfer(fulfillOfferFee);
        }

    //returns offered token IDs of input index number
    function getTradeOfferTokenIdsByIndex(uint _index) public view returns (uint[] memory) { 
        return offer_record[_index].offerTokenIds;
    }

    //returns requested token IDs of input index number
    function getTradeOfferReqTokenIdsByIndex(uint _index) public view returns (uint[] memory) { 
        return offer_record[_index].reqTokenIds;
    }


    function getIndexesOfOffersCreatedByAddress(address _address) public view returns (uint[] memory) {
        uint length = IndexOfOwner[_address].length;
        uint[] memory offersByAddress = new uint[](length);
        for (uint i=0; i<length; i++) {
            offersByAddress[i] = (IndexOfOwner[_address][i]);
        }
        return offersByAddress;
    }

    function updateCreateOfferFee(uint _newFee) public onlyOwner {
        createOfferFee = _newFee;
    }

    function updateRevokeOfferFee(uint _newFee) public onlyOwner {
        revokeOfferFee = _newFee;
    }

    function updateFulfillOfferFee(uint _newFee) public onlyOwner {
        fulfillOfferFee = _newFee;
    }

    function updateFeeReceiver(address _feeReceiver) public onlyOwner {
        feeReceiver = payable(_feeReceiver);
    }

    //necessary to interact with ERC721 tokens
    function onERC721Received(address, address, uint, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }


}