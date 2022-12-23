// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

contract Ledger {
    uint256 private invoiceId = 0;

    struct Invoice {
        string sellerPan;
        string invoiceAmount;
        string invoiceDate;
        string status; // false for unpaid, true for paid
    }

    // BuyerPAN => Array of invoiceIds
    mapping(string => uint256[]) private buyerToInvoiceId;
    // invoiceId => Invoice
    mapping(uint256 => Invoice) private invoiceIdToInvoice;

    // Function to save Invoice data to smartcontract
    function saveInvoice(
        string memory _buyerPan,
        string memory _sellerPan,
        string memory _invoiceAmount,
        string memory _invoiceDate,
        string memory _status
    ) public {
        buyerToInvoiceId[_buyerPan].push(invoiceId);
        invoiceIdToInvoice[invoiceId] = Invoice(
            _sellerPan,
            _invoiceAmount,
            _invoiceDate,
            _status
        );
        invoiceId++;
    }

    function getInvoiceIds(
        string memory _buyerPan
    ) public view returns (uint256[] memory) {
        return buyerToInvoiceId[_buyerPan];
    }

    function getInvoiceById(
        uint256 _invoiceId
    ) public view returns (Invoice memory) {
        return invoiceIdToInvoice[_invoiceId];
    }
}