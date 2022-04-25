pragma solidity 0.8.12;

//*********************************************************************//
// --------------------------- custom errors ------------------------- //
//*********************************************************************//
error ETH_TRANSFER_FAILED();

/**
@title Royalty Splitter Contract
*/
contract RoyaltySplitter {
    address constant operator = 0x8ba7E0BE0460035699BAddD1fD1aCCb178702348;
    address constant secondRecipient = 0x1f1c38790323E2e2941Eddd2bDEaf2abfE6e42dF;
    address constant thirdRecipient = 0x509Bed05fA643cc4023620652b5c03d15d7E911a;

    // Fallback Functions for calldata and reciever for handling only ether transfer
    receive() external payable {
        uint256 operatorShare = (msg.value * 82) / 100;
        uint256 secondRecipientShare = (msg.value * 15) / 100;
        uint256 thirdRecipientShare = msg.value - (operatorShare + secondRecipientShare);

        (bool success, ) = operator.call{value: operatorShare}("");
        if (!success) {
            revert ETH_TRANSFER_FAILED();
        }
        (success, ) = secondRecipient.call{value: secondRecipientShare}("");
        if (!success) {
            revert ETH_TRANSFER_FAILED();
        }
        (success, ) = thirdRecipient.call{value: thirdRecipientShare}("");
        if (!success) {
            revert ETH_TRANSFER_FAILED();
        }
    }
}