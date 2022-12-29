// SPDX-License-Identifier: MIT License
pragma solidity >=0.8.0 <0.9.0;

contract EventTester {
    enum OfferStatus {
        NEW_RECORD,
        PRICE_ESTIMATE_REQUESTED,
        ORACLE_REQUEST_FULFILLED,
        ORACLE_REQUEST_CANCELLED,
        SIGNATURE_REQUEST_FULFILLED
    }
    
    enum OfferCancellationReason {
        NONE,
        WRONG_PRICE,
        PHUNK_TRANSFER_FAILURE,
        FLYWHEEL_OUT_OF_ETH,
        INCORRECT_OFFER_STATUS,
        OFFER_EXPIRED
    }

    struct Offer {
        OfferStatus status;
        OfferCancellationReason cancellationReason;
        uint16 phunkId;
        uint64 offerValidUntil;
        bool enoughPhunkInSushiPoolForValidSpotPrice;
        address seller;
        uint minSalePrice;
        uint oraclePriceEstimate;
        bytes32 appraisalRequestId;
        uint minAppraisalConsideredValid;
        uint priceFlywheelIsWillingToPay;
    }

    event PhunkSoldViaSignature(
        Offer offer,
        uint indexed phunkId,
        uint minSalePrice,
        address indexed seller
    );

    constructor() {}

    function testEvent(
        uint16 phunkId,
        uint phunkPrice,
        uint offerValidUntil
    ) public {
        Offer memory newOffer = Offer({
            status: OfferStatus.SIGNATURE_REQUEST_FULFILLED,
            cancellationReason: OfferCancellationReason.NONE,
            seller: msg.sender,
            phunkId: phunkId,
            offerValidUntil: uint64(offerValidUntil),
            minSalePrice: phunkPrice,
            oraclePriceEstimate: 0,
            appraisalRequestId: bytes32(0),
            minAppraisalConsideredValid: 0,
            enoughPhunkInSushiPoolForValidSpotPrice: false,
            priceFlywheelIsWillingToPay: 0
        });

        emit PhunkSoldViaSignature(newOffer, phunkId, phunkPrice, msg.sender);
    }
}