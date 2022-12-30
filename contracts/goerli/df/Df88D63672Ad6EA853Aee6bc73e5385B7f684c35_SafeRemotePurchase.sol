//SPDX-License-Identifier:MIT
pragma solidity ^0.8.7;

error SafeRemotePurchase__EscrowValueShouldAtleast2XPrice();
error SafeRemotePurchase__NeedToSendEscrowValueEquivalentETH();
error SafeRemotePurchase__AgreementStatusShouldBeInCreated();
error SafeRemotePurchase__SenderShouldBeBuyer();
error SafeRemotePurchase__AgreementShouldBeInConfirmedStatus();
error SafeRemotePurchase__SenderShouldBeSeller();
error SafeRemotePurchase__AgreementShouldBeInReceivedStatus();
error SafeRemotePurchase__SenderShouldBeAgreementCreator();
error SafeRemotePurchase__CreatorCanNotConfirmAgreement();
error SafeRemotePurchase__TransferFailed();

contract SafeRemotePurchase {
    uint256 private agreementId;
    enum TradeType {
        BUY,
        SELL
    }
    enum AgreementStatus {
        Created,
        Confirmed,
        Received,
        Fulfilled,
        Canceled
    }
    struct Agreement {
        address payable seller;
        address payable buyer;
        uint256 price;
        uint256 escrowValue;
        AgreementStatus agreementStatus;
        address payable creatorAddress;
    }
    Agreement[] private agreements;
    mapping(address => uint256) private creatorAddressToAgreementId;

    function createAgreement(
        TradeType tradeTypeId,
        address payable with,
        uint256 agreedPrice
    ) external payable {
        if (msg.value < agreedPrice * 2) {
            revert SafeRemotePurchase__EscrowValueShouldAtleast2XPrice();
        }
        creatorAddressToAgreementId[msg.sender] = agreementId;
        agreementId += 1;
        if (tradeTypeId == TradeType.BUY) {
            agreements.push(
                Agreement(
                    with,
                    payable(msg.sender),
                    agreedPrice,
                    msg.value,
                    AgreementStatus.Created,
                    payable(msg.sender)
                )
            );
        } else {
            agreements.push(
                Agreement(
                    payable(msg.sender),
                    with,
                    agreedPrice,
                    msg.value,
                    AgreementStatus.Created,
                    payable(msg.sender)
                )
            );
        }
    }

    function confirmAgreement(uint256 _agreementId) external payable {
        Agreement storage agreement = agreements[_agreementId];
        // if (msg.sender != agreement.seller || msg.sender != agreement.buyer) {
        //     revert SafeRemotePurchase__SenderShouldBeBuyerOrSeller();
        // }

        require(
            msg.sender == agreement.buyer || msg.sender == agreement.seller,
            "sender should be buyer or seller"
        );
        if (msg.value != agreement.escrowValue) {
            revert SafeRemotePurchase__NeedToSendEscrowValueEquivalentETH();
        }
        if (agreement.agreementStatus != AgreementStatus.Created) {
            revert SafeRemotePurchase__AgreementStatusShouldBeInCreated();
        }
        if (msg.sender == agreement.creatorAddress) {
            revert SafeRemotePurchase__CreatorCanNotConfirmAgreement();
        }
        agreement.agreementStatus = AgreementStatus.Confirmed;
    }

    function confirmReception(uint256 _agreementId) external {
        Agreement storage agreement = agreements[_agreementId];
        if (msg.sender != agreement.buyer) {
            revert SafeRemotePurchase__SenderShouldBeBuyer();
        }
        if (agreement.agreementStatus != AgreementStatus.Confirmed) {
            revert SafeRemotePurchase__AgreementShouldBeInConfirmedStatus();
        }
        agreement.agreementStatus = AgreementStatus.Received;
        uint256 amount = agreement.escrowValue - agreement.price;
        (bool success, ) = msg.sender.call{value: amount}("");
        if (!success) {
            revert SafeRemotePurchase__TransferFailed();
        }
    }

    function receivePayment(uint256 _agreementId) external {
        Agreement storage agreement = agreements[_agreementId];
        if (msg.sender != agreement.seller) {
            revert SafeRemotePurchase__SenderShouldBeSeller();
        }
        if (agreement.agreementStatus != AgreementStatus.Received) {
            revert SafeRemotePurchase__AgreementShouldBeInReceivedStatus();
        }
        agreement.agreementStatus = AgreementStatus.Fulfilled;
        uint256 amount = agreement.escrowValue + agreement.price;
        (bool success, ) = msg.sender.call{value: amount}("");
        if (!success) {
            revert SafeRemotePurchase__TransferFailed();
        }
    }

    function abortAgreement(uint256 _agreementId) external {
        Agreement storage agreement = agreements[_agreementId];
        if (msg.sender != agreement.creatorAddress) {
            revert SafeRemotePurchase__SenderShouldBeAgreementCreator();
        }
        if (agreement.agreementStatus != AgreementStatus.Created) {
            revert SafeRemotePurchase__AgreementStatusShouldBeInCreated();
        }
        agreement.agreementStatus = AgreementStatus.Canceled;
        uint256 amount = agreement.escrowValue;
        (bool success, ) = agreement.creatorAddress.call{value: amount}("");
        if (!success) {
            revert SafeRemotePurchase__TransferFailed();
        }
    }

    function getAgreementId() public view returns (uint256) {
        return agreementId;
    }

    function getAgreement(uint256 index)
        public
        view
        returns (Agreement memory)
    {
        return agreements[index];
    }

    function getCreatorToAgreementId(address creator)
        public
        view
        returns (uint256)
    {
        return creatorAddressToAgreementId[creator];
    }
}