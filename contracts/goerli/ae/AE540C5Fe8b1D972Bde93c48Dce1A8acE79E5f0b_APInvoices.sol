/**
 *Submitted for verification at Etherscan.io on 2022-12-16
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract APInvoices {
    struct Invoicesstruct {
        uint invoiceId;
        uint vendorID;
        string invoiceVendor;
        string invoiceNumber;
        uint invoiceAmount;
        uint invoiceDate;
        uint invoiceDueDate;
        uint invoiceImportedDate;
        uint invoiceApporovedBy;
        uint invoiceApprovalDate;
        bool isActive;
    }

    mapping(uint => Invoicesstruct) private invoicesById;
    uint private totalEntries = 0;

    

    function addInvoice(
        uint _vendorID,
        string memory _invoiceVendor,
        string memory _invoiceNumber,
        uint _invoiceAmount,
        uint _invoiceDate,
        uint _invoiceDueDate
    ) public returns (bool, string memory) {
        //Check that the invoice number does not already exist in the system for the vendor
        for (uint i = 0; i < totalEntries; i++) {
            if (
                keccak256(abi.encodePacked(invoicesById[i].invoiceNumber)) ==
                keccak256(abi.encodePacked(_invoiceNumber)) &&
                invoicesById[i].vendorID == _vendorID
            ) {
                return (false, "Invoice number already exists for vendor");
            }
        }
        // Create the new invoice struct
        Invoicesstruct memory invoice = Invoicesstruct(
            totalEntries,
            _vendorID,
            _invoiceVendor,
            _invoiceNumber,
            _invoiceAmount,
            _invoiceDate,
            _invoiceDueDate,
            block.timestamp,
            0,
            0,
            true
        );

        // Save the new invoice in both mappings
        invoicesById[totalEntries] = invoice;

        totalEntries++;
        return (true, "Invoice added successfully");
    }

    //create a function that will disable an invoice
    //this will only be used in the scenario were a large bill is paid and will cause a discrepancy in the system
    function disableInvoice(uint _invoiceId) public returns (bool) {
        // Check that the invoice exists
        require(invoicesById[_invoiceId].invoiceId == _invoiceId);

        // Disable the invoice
        invoicesById[_invoiceId].isActive = false;

        return true;
    }

    //create a function that will return all invoices
    function getAllInvoices() public view returns (Invoicesstruct[] memory) {
        Invoicesstruct[] memory allInvoices = new Invoicesstruct[](
            totalEntries
        );

        for (uint i = 0; i < totalEntries; i++) {
            allInvoices[i] = invoicesById[i];
        }

        return allInvoices;
    }


    //create a function that will approve all invoices for a specific vendor
    function approveAllInvoicesForVendor(string memory _vendorName)
        public
        returns (bool)
    {
        for (uint i = 0; i < totalEntries; i++) {
            if (
                keccak256(abi.encodePacked(invoicesById[i].invoiceVendor)) ==
                keccak256(abi.encodePacked(_vendorName)) &&
                invoicesById[i].isActive
            ) {
                invoicesById[i].invoiceApporovedBy = 1;
                invoicesById[i].invoiceApprovalDate = block.timestamp;
            }
        }

        return true;
    }
    //create a function that will return all active invoices
    function getAllActiveInvoices()
        public
        view
        returns (Invoicesstruct[] memory)
    {
        Invoicesstruct[] memory allActiveInvoices = new Invoicesstruct[](
            totalEntries
        );

        uint activeInvoicesCount = 0;

        for (uint i = 0; i < totalEntries; i++) {
            if (invoicesById[i].isActive) {
                allActiveInvoices[activeInvoicesCount] = invoicesById[i];
                activeInvoicesCount++;
            }
        }

        return allActiveInvoices;
    }

    //create a function that will return all invoice amounts for a specific vendor that are active and have been approved
    function getAllInvoiceAmountsForVendor(
        string memory _vendorName
    ) public view returns (uint[] memory) {
        uint[] memory allInvoiceAmountsForVendor = new uint[](totalEntries);

        uint invoiceAmountsForVendorCount = 0;

        for (uint i = 0; i < totalEntries; i++) {
            if (
                keccak256(abi.encodePacked(invoicesById[i].invoiceVendor)) ==
                keccak256(abi.encodePacked(_vendorName)) &&
                invoicesById[i].isActive &&
                invoicesById[i].invoiceApporovedBy != 0
            ) {
                allInvoiceAmountsForVendor[
                    invoiceAmountsForVendorCount
                ] = invoicesById[i].invoiceAmount;
                invoiceAmountsForVendorCount++;
            }
        }

        return allInvoiceAmountsForVendor;
    }

    //create a function that will return all inactive invoices
    function getAllInactiveInvoices()
        public
        view
        returns (Invoicesstruct[] memory)
    {
        Invoicesstruct[] memory allInactiveInvoices = new Invoicesstruct[](
            totalEntries
        );

        uint inactiveInvoicesCount = 0;

        for (uint i = 0; i < totalEntries; i++) {
            if (!invoicesById[i].isActive) {
                allInactiveInvoices[inactiveInvoicesCount] = invoicesById[i];
                inactiveInvoicesCount++;
            }
        }

        return allInactiveInvoices;
    }

    //create a function that will return all invoices for a specific vendor
    function getAllInvoicesForVendor(
        string memory _vendorName
    ) public view returns (Invoicesstruct[] memory) {
        Invoicesstruct[] memory allInvoicesForVendor = new Invoicesstruct[](
            totalEntries
        );

        uint invoicesForVendorCount = 0;

        for (uint i = 0; i < totalEntries; i++) {
            if (
                keccak256(abi.encodePacked(invoicesById[i].invoiceVendor)) ==
                keccak256(abi.encodePacked(_vendorName))
            ) {
                allInvoicesForVendor[invoicesForVendorCount] = invoicesById[i];
                invoicesForVendorCount++;
            }
        }

        return allInvoicesForVendor;
    }

    //create a function that will return who and when an invoice was approved
    function getInvoiceApproval(
        uint _invoiceId
    ) public view returns (string memory, uint) {
        // Check that the invoice exists
        require(invoicesById[_invoiceId].invoiceId == _invoiceId);

        // Return the invoice approval
        return (
            invoicesById[_invoiceId].invoiceVendor,
            invoicesById[_invoiceId].invoiceImportedDate
        );
    }

    //create a function that will take in an invoice id and approver id. This will be used to approve an invoice
    function approveInvoice(
        uint _invoiceId,
        uint _approverId
    ) public returns (bool) {
        // Check that the invoice exists
        require(invoicesById[_invoiceId].invoiceId == _invoiceId);

        // Approve the invoice
        invoicesById[_invoiceId].invoiceApporovedBy = _approverId;
        invoicesById[_invoiceId].invoiceApprovalDate = block.timestamp;

        return true;
    }

    //create a function that will return who and when an invoice was approved
}