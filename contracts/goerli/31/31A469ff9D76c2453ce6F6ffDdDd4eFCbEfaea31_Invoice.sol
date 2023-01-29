// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Invoice {
    struct InvoiceStruct {
        address payable creator;
        uint256 amount;
        string comment;
        bool paid;
    }

    mapping(uint256 => InvoiceStruct) invoices;
    uint256 nextInvoiceId;

    mapping(address => uint256[]) assignedInvoices;
    uint256 nextAssignedInvoicesId;

    function formInvoice(
        uint256 _amount,
        string calldata _comment,
        address receiver
    ) public returns (uint256 invoiceId) {
        invoiceId = nextInvoiceId;
        _createInvoice(payable(msg.sender), _amount, _comment);
        if (receiver != address(0x0)) {
            _assignInvoice(receiver, invoiceId);
        }
        nextInvoiceId++;
        return invoiceId;
    }

    function payInvoice(uint256 _invoiceId) public payable {
        InvoiceStruct storage invoice = invoices[_invoiceId];
        require(!invoice.paid, "Invoice already paid.");
        require(msg.value >= invoice.amount, "Insufficient funds.");
        invoice.creator.transfer(invoice.amount);
        invoice.paid = true;
    }

    function getInvoiceStatus(uint256 _invoiceId)
        public
        view
        returns (InvoiceStruct memory invoice)
    {
        return invoices[_invoiceId];
    }

    function getAssignedInvoices(address _address)
        public
        view
        returns (uint256[] memory invoiceIds)
    {
        return assignedInvoices[_address];
    }

    function _createInvoice(
        address _creator,
        uint256 _amount,
        string calldata _comment
    ) private {
        invoices[nextInvoiceId] = InvoiceStruct(
            payable(_creator),
            _amount,
            _comment,
            false
        );
    }

    function _assignInvoice(address receiver, uint256 invoiceId) private {
        assignedInvoices[receiver].push(invoiceId);
    }
}