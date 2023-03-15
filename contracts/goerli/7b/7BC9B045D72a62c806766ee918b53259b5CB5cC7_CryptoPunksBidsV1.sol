// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/*

CryptoPunksBids.sol

Written by: mousedev.eth

Concept by: mousedev.eth & kilo

*/

import "./interfaces/ICryptoPunksMarket.sol";

struct GlobalBid {
    //96 bits
    uint96 bidWei;

    //96 bits
    uint96 settlementWei;

    //160 bits
    address bidder;

    //160 bits optional receiver (if u want to send to cold wallet.)
    address receiver;

    //   /\
    //  /  \
    //   ||
    //   ||
    // two slots

    //an amount of bits
    uint16[] punkIds;
}

contract CryptoPunksBidsV1 {
    mapping(uint256 => GlobalBid) public globalBids;

    bytes32 public signature = 0x45f542cfc742a52831b47ba8656d214083b07269bfdb7cbc455a8fbca649c19a;

    uint256 public currentBidId = 1;

    address public cryptoPunksAddress;

    event BidPlaced(uint256 _thisBidId,uint256 _bidWei);
    event BidRemoved(uint256 _bidId);
    event BidAdjusted(uint256 _bidId, uint256 _newBidWei);
    event BidSettlementAdjusted(uint256 _bidId, uint256 _newBidSettlementWei);

    constructor(address _cryptoPunksAddress)
    {
        cryptoPunksAddress = _cryptoPunksAddress;
    }

    /**
     * @dev Places a global or trait bid.
     * @param _bidWei wei to bid.
     * @param _settlementWei wei as a bribe to a bot for settlement.
     */
    function placeBid(
        uint96 _bidWei,
        uint96 _settlementWei,
        address _receiver,
        uint16[] memory _punkIds
    ) public payable returns(uint256){
        //Require they sent exact ether with tx.
        require(
            msg.value == _bidWei + _settlementWei,
            "Ether sent did not match ether in bid"
        );

        uint256 _thisBidId = currentBidId;

        globalBids[_thisBidId] = GlobalBid(
            _bidWei,
            _settlementWei,
            msg.sender,
            _receiver,
            _punkIds
        );

        currentBidId++;

        emit BidPlaced( _thisBidId, _bidWei);

        return _thisBidId;
    }

    /**
     * @dev Cancels a bid.
     * @param _bidId Bid to cancel.
     */
    function cancelBid(uint256 _bidId) public {
        GlobalBid memory _globalBid = globalBids[_bidId];

        //Require they made this bid.
        require(_globalBid.bidder == msg.sender, "You did not make this bid.");

        //Remove struct from storage.
        delete globalBids[_bidId];

        //Send eth back to bidder
        (bool succ1, ) = payable(msg.sender).call{value: _globalBid.bidWei + _globalBid.settlementWei}("");
        require(succ1, "transfer failed");

        emit BidRemoved( _bidId);
    }

    function adjustBidPrice(uint256 _bidId, uint96 _weiToAdjust, bool _direction) public payable {
        GlobalBid memory _globalBid = globalBids[_bidId];

        //Require they made this bid.
        require(_globalBid.bidder == msg.sender, "You did not make this bid.");

        if(_direction){
            //increase bid
            require(msg.value >= _weiToAdjust, "Did not send enough wei for adjustment");

            uint96 _oldBidWei = globalBids[_bidId].bidWei;

            globalBids[_bidId].bidWei = _oldBidWei + _weiToAdjust;

            emit BidAdjusted(_bidId, _oldBidWei + _weiToAdjust);
        } else {
            //reduce bid
            require(_globalBid.bidWei >= _weiToAdjust, "Adjustment is higher than current bid");

            uint96 _oldBidWei = globalBids[_bidId].bidWei;

            globalBids[_bidId].bidWei = _oldBidWei - _weiToAdjust;

            //Send settlement incentive to settler
            (bool succ1, ) = payable(msg.sender).call{
                value: _weiToAdjust
            }("");
            require(succ1, "transfer failed");

            emit BidAdjusted(_bidId, _oldBidWei - _weiToAdjust);
        }
    }

    function adjustBidSettlementPrice(uint256 _bidId, uint96 _weiToAdjust, bool _direction) public payable {
        GlobalBid memory _globalBid = globalBids[_bidId];

        //Require they made this bid.
        require(_globalBid.bidder == msg.sender, "You did not make this bid!");

        if(_direction){
            //increase bid
            //Require the message value is greater than or equal to what they inputted for wei to adjust.
            require(msg.value >= _weiToAdjust, "Did not send enough wei for adjustment");

            //Store the old settlement price
            uint96 _oldSettlementWei = globalBids[_bidId].settlementWei;

            //Set the new settlement price to old + adjustment
            globalBids[_bidId].settlementWei = _oldSettlementWei + _weiToAdjust;

            //Emit event for listeners
            emit BidAdjusted(_bidId, _oldSettlementWei + _weiToAdjust);
        } else {
            //reduce bid
            //Require their current settlement cost is higher than what they are reducing by.
            require(_globalBid.settlementWei >= _weiToAdjust, "Adjustment is higher than current bid");

            //Store the old settlement price
            uint96 _oldSettlementWei = globalBids[_bidId].settlementWei;

            //Set the new settlement price to the old price minus the adjustment
            globalBids[_bidId].settlementWei = _oldSettlementWei - _weiToAdjust;

            //Send the adjustment back to the bidder.
            (bool succ1, ) = payable(msg.sender).call{
                value: _weiToAdjust
            }("");
            require(succ1, "transfer failed");

            //Emit event for listeners
            emit BidSettlementAdjusted(_bidId, _oldSettlementWei - _weiToAdjust);
        }
    }


    function acceptBid(uint256 _bidId, uint16 _punkId) public {
        //Pull this bid into memory
        GlobalBid memory _globalBid = globalBids[_bidId];

        require(globalBids[_bidId].bidder != address(0x0), "Bid not active.");

        if(_globalBid.punkIds.length > 0){
            //They wanted to target specific punkIds.
            for(uint256 i = 0; i < _globalBid.punkIds.length; ++i){
                //If this provided punk matches the punk in their list, break out of for loop and continue.
                if(_globalBid.punkIds[i] == _punkId) break;

                //If we are on the last iteration and we haven't broken out, revert.
                if(i == _globalBid.punkIds.length - 1) revert("Punk not found in array.");
            }
        }

        //Remove their bid from storage (slight refund)
        delete globalBids[_bidId];


        //Pull the offer into memory
        Offer memory _offer = ICryptoPunksMarket(cryptoPunksAddress)
            .punksOfferedForSale(_punkId);

        //Require the bid is greater or equal to the offer
        //If you bid 80e, a 70e offer is valid for matching.
        require(_offer.minValue <= _globalBid.bidWei, "Offer not valid.");

        //Buy the punk from the marketplace
        //Costs approx: 87085 gas
        ICryptoPunksMarket(cryptoPunksAddress).buyPunk{value: _offer.minValue}(
            _punkId
        );

        //Send the punk to the bidder
        //Costs approx: 10522 gas
        ICryptoPunksMarket(cryptoPunksAddress).transferPunk(
            _globalBid.receiver == address(0x0) ? _globalBid.bidder: _globalBid.receiver,
            _punkId
        );

        //Settle ETH details
        //Costs approx: 20517 gas (with settlement and excess, excess is likely.)

        //Send settlement incentive to settler
        (bool succ1, ) = payable(msg.sender).call{
            value: _globalBid.settlementWei
        }("");
        require(succ1, "settlement transfer failed.");

        //Send excess back to bidder
        if (_globalBid.bidWei > _offer.minValue) {
            (bool succ2, ) = payable(_globalBid.bidder).call{
                value: _globalBid.bidWei - _offer.minValue
            }("");
            require(succ2, "bidder excess transfer failed.");
        }
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

    struct Offer {
        bool isForSale;
        uint punkIndex;
        address seller;
        uint minValue;          // in ether
        address onlySellTo;     // specify to sell only to a specific person
    }

interface ICryptoPunksMarket {
    //0x088f11f3
    function punksOfferedForSale(uint)
        external
        view
        returns (Offer memory);

    function punkIndexToAddress(uint256 _punkIndex)
        external
        view
        returns (address);

    function buyPunk(uint256 _punkIndex) external payable;

    function transferPunk(address to, uint256 punkIndex) external;

    function allInitialOwnersAssigned() external;

    function offerPunkForSale(uint, uint) external;

    function getPunk(uint) external;
}