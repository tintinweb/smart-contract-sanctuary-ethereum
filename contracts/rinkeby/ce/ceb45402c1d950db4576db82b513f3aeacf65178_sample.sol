/**
 *Submitted for verification at Etherscan.io on 2022-05-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract sample {

    uint orderId;
    uint offerId;

     event OrderCreated(
        uint256 _orderId,
        address borrower,
        address NFTAddress,
        uint256 tokenID,
        uint256 principal,
        uint256 interst,
        uint256 NoofInstallment,
        uint256 RepayUnixTimeStamp
    );
    event OfferPlaced(
        uint256 _orderId,
        uint256 _offerId,
        address userOffered,
        uint256 principal,
        uint256 _totalInterestAmount,
        uint256 _loanFinalRepaytime,
        uint32 _NoInstallment
    );

    event OfferWithdrawn(uint256,uint256, address, address, uint256);

    event OrderWithdrawn(uint256, address, address, uint256);

    event OfferClaimBack(uint256, uint256, uint256, address);

    event loanStarted(uint256 _orderId, uint256 _offerId);

    event EMIPaid(uint256, address, uint256, bool, uint256, uint256);

    event ClaimedDefaultedNFT(uint256, address, address, uint256);

    event ClaimedRepaidNFT(uint256, address, address, uint256);

function createOrder(
        uint256 _tokenId,
        uint256 _principalAmount,
        uint256 _totalInterest,
        uint32 _noInstallment,
        uint256 _loanFinalRepaytime,
        uint256 _maxApprovalAmount,
        address _nftToken
    ) public {
        uint currorderId = orderId;
        orderId = orderId+1;
         emit OrderCreated(
            currorderId,
            msg.sender,
            _nftToken,
            _tokenId,
            _principalAmount,
            _totalInterest,
            _noInstallment,
            _loanFinalRepaytime
        );
    }
 function placeOffer(
        uint256 _orderId,
        uint256 _totalInterestAmount,
        uint256 _loanFinalRepaytime,
        uint32 _noInstallment
    ) public {
        uint currofferId = offerId + 1;
         emit OfferPlaced(
            _orderId,
            currofferId,
            msg.sender,
            0,
            _totalInterestAmount,
            _loanFinalRepaytime,
            _noInstallment
        );
    }
    function withdrawActiveOfferFunc(uint256 _orderId, uint256 _offerId, uint tokenId) public {

        emit OfferWithdrawn(_orderId,_offerId, msg.sender, address(0x0), tokenId);
    }

    function OfferWithdrawnFunc(uint orderId, uint offerId, address sender, address nftAddress, uint tokenId) public {
        emit OfferWithdrawn(orderId, offerId, sender, nftAddress, tokenId);
    }

    function OrderWithdrawnFunc(uint orderId, address sender, address nftAddress, uint tokenId) public {
        emit OrderWithdrawn(orderId, sender, nftAddress, tokenId);
    }

    function loanStartedFunc(uint256 _orderId, uint256 _offerId) public {
        emit loanStarted(_orderId, _offerId);
    }
}