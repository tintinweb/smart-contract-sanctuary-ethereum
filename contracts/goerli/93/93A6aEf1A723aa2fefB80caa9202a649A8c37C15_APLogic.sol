// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./invoices.sol";
import "./vendors.sol";
import "./approvers.sol";

contract APLogic {


    APInvoices invoicesContract;
    address invoicesContractAddress;
    APApprovers approversContract;
    address approversContractAddress;
    APVendors vendorsContract;
    address vendorsContractAddress;

    //make a function that does nothing but return true
    function contructorFunction() public pure returns (bool) {
        return true;
    }

    // Update the address of the vendors contract instance
    function updateVendorsContractAddress(
        address _vendorsContractAddress
    ) public returns (bool) {
        vendorsContractAddress = _vendorsContractAddress;
        vendorsContract = APVendors(vendorsContractAddress);
        return true;
    }

    // Update the address of the invoices contract instance
    function updateInvoicesContractAddress(
        address _invoicesContractAddress
    ) public returns (bool) {
        invoicesContractAddress = _invoicesContractAddress;
        invoicesContract = APInvoices(invoicesContractAddress);
        return true;
    }

    // Update the address of the approvers contract instance
    function updateApproversContractAddress(
        address _approversContractAddress
    ) public returns (bool) {
        approversContractAddress = _approversContractAddress;
        approversContract = APApprovers(approversContractAddress);
        return true;
    }

    //create a function that adds a new invoice to the invoices contract
    function addInvoice(
        string memory _invoiceVendor,
        string memory _invoiceNumber,
        uint _invoiceAmount,
        uint _invoiceDate,
        uint _invoiceDueDate
    ) public returns (string memory) {
        // use checkVendorExists to check if the vendor exists. If it does not, return "Vendor does not exist"
        if (vendorsContract.checkVendorExists(_invoiceVendor) == false) {
            return "Vendor does not exist";
        }

        uint256 vendorId = vendorsContract.getVendorIdByName(_invoiceVendor);
        // use addInvoice to add the invoice to the invoices contract. the addInvoice function should return a bool and a string. If the bool is false, return the string. If the bool is true, return "Invoice added successfully"
        bool result;
        string memory message;

        // get the vendor's variance level using getVarianceLevel and store it in a variable called varianceLevel
        uint varianceLevel = vendorsContract.getVarianceLevelById(vendorId);
        // get the vendor's invoices using getInvoicesByVendor and store it in a variable called vendorInvoices
        uint[] memory vendorInvoices = invoicesContract
            .getAllInvoiceAmountsForVendor(_invoiceVendor);
        // use isAboveVarianceLevel to check if the invoice amount is above the variance level. If it is, return "Invoice amount is above variance level"
        if (
            isAboveVarianceLevel(
                vendorInvoices,
                _invoiceAmount,
                varianceLevel
            ) == true
        ) {
            return "Invoice amount is above variance level";
        }

        (result, message) = invoicesContract.addInvoice(
            vendorId,
            _invoiceVendor,
            _invoiceNumber,
            _invoiceAmount,
            _invoiceDate,
            _invoiceDueDate
        );
        if (result == false) {
            return message;
        }

        return (message);
    }

    function isAboveVarianceLevel(
        uint[] memory invoices,
        uint invoiceAmount,
        uint acceptableVarianceLevel
    ) public pure returns (bool) {
        // Calculate the mean of the numbers in the array
        uint sum = 0;
        for (uint i = 0; i < invoices.length; i++) {
            sum += invoices[i];
        }
        uint mean = sum / invoices.length;

        // Calculate the variance of the numbers in the array
        uint variance = 0;
        for (uint i = 0; i < invoices.length; i++) {
            variance += (invoices[i] - mean) ** 2;
        }
        variance /= invoices.length;

        // Check if the input number is greater than the acceptable variance level and the variance
        return
            invoiceAmount > acceptableVarianceLevel && invoiceAmount > variance;
    }



    //create a function that adds a new vendor to the vendors contract
    function addVendor(string memory _vendorName, uint varianceLevel) public {
        // use checkVendorExists to check if the vendor exists. If it does, return "Vendor already exists"
        if (vendorsContract.checkVendorExists(_vendorName) == true) {
            return;
        }

        vendorsContract.addVendor(_vendorName, varianceLevel);
    }

    //create a function that adds a new approver to the approvers contract
    function addApprover(
        string memory _apprroverName,
        uint _approvalLevel
    ) public {
        // use checkApproverExists to check if the approver exists. If it does, return "Approver already exists"
        if (approversContract.checkApproverExists(_apprroverName) == true) {
            return;
        }
        // use addApprover to add the approver to the approvers contract. the addApprover function should return a bool and a string. If the bool is false, return the string. If the bool is true, return "Approver added successfully"
        // the addApprover function should take the approver name, the approval level, and an empty array of vendor ids as parameters
        bool result;
        string memory message;
        (result, message) = approversContract.addApprover(
            _apprroverName,
            _approvalLevel,
            new uint256[](0)
        );
        if (result == true) {
            return;
        } else {
            return;
        }
    }

    //create a function that enables or disables an approver in the approvers contract based on the boolean value passed to the function as a parameter
    function enableApprover(string memory _approverName, bool _enable) public {
        // use checkApproverExists to check if the approver exists. If it does not, return "Approver does not exist"
        if (approversContract.checkApproverExists(_approverName) == false) {
            return;
        }
        //use the setApproverStatus function to enable or disable the approver. The setApproverStatus function should return a bool and a string. If the bool is false, return the string. If the bool is true, return "Approver status updated successfully"
        bool result;
        string memory message;
        (result, message) = approversContract.setApproverStatus(
            _approverName,
            _enable
        );
        if (result == true) {
            return;
        } else {
            return;
        }
    }

    //create a function that adds a vendor to an approver's list of vendors
    function addVendorToApprover(
        string memory _approverName,
        string memory _vendorName
    ) public returns (string memory) {
        // use checkApproverExists to check if the approver exists. If it does not, return "Approver does not exist"
        if (approversContract.checkApproverExists(_approverName) == false) {
            return "Approver does not exist";
        }
        // use checkVendorExists to check if the vendor exists. If it does not, return "Vendor does not exist"
        if (vendorsContract.checkVendorExists(_vendorName) == false) {
            return "Vendor does not exist";
        }
        // use getVendorIdByName to get the vendor id of the vendor
        uint256 vendorId = vendorsContract.getVendorIdByName(_vendorName);
        // use addVendorToApprover to add the vendor to the approver's list of vendors. The addVendorToApprover function should return a bool and a string. If the bool is false, return the string. If the bool is true, return "Vendor added to approver successfully"
        bool result;
        string memory message;
        (result, message) = approversContract.addVendorToApprover(
            _approverName,
            vendorId
        );
        if (result == true) {
            return "Vendor added to approver successfully";
        } else {
            return message;
        }
    }

    // create a function that removes a vendor from an approver's list of vendors
    // returns a bool and a string. If the bool is false, return the string. If the bool is true, return "Vendor removed from approver successfully"
    function removeVendorFromApprover(
        string memory _approverName,
        string memory _vendorName
    ) public returns (bool, string memory) {
        // use checkApproverExists to check if the approver exists. If it does not, return false and "Approver does not exist"
        if (approversContract.checkApproverExists(_approverName) == false) {
            return (false, "Approver does not exist");
        }
        // use checkVendorExists to check if the vendor exists. If it does not, return false and "Vendor does not exist"
        if (vendorsContract.checkVendorExists(_vendorName) == false) {
            return (false, "Vendor does not exist");
        }
        // use getVendorIdByName to get the vendor id of the vendor
        uint256 vendorId = vendorsContract.getVendorIdByName(_vendorName);
        // use removeVendorFromApprover to remove the vendor from the approver's list of vendors. The removeVendorFromApprover function should return a bool and a string. If the bool is false, return the string. If the bool is true, return "Vendor removed from approver successfully"
        bool result;
        string memory message;
        (result, message) = approversContract.removeVendorFromApprover(
            _approverName,
            vendorId
        );
        if (result == true) {
            return (true, "Vendor removed from approver successfully");
        } else {
            return (false, message);
        }
    }

    //create a function that takes an
}