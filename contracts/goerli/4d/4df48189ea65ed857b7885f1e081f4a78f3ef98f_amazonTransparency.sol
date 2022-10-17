/**
 *Submitted for verification at Etherscan.io on 2022-10-17
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

contract amazonTransparency{

    address owner;
    uint256 txCounter = 1;

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner{
        require (msg.sender == owner, "Only Amazon can Approve the Transaction");
        _;
    }

    struct retailer{
        address retailerAddress;
	    string retailerStoreName;
        bool isRetailer;
    }

    struct supplier{
	    string supplierName;
        address supplierAddress;
    }

    struct product{
        uint productID;
        bool isDeliveredToCustomer;
        address productOwner;
        bool paymentApprovedByAmazon;
        bool isExist;
    }

    struct productRequest{
        uint256 requestId;
        address retailerAddress;
        address supplierAddress;
        uint productID;
        uint retailerRequiredUnits;
        bool paymentTransaction;
    }

    struct transaction{
        uint256 txId;
        address from;
        address to;
        uint256 productId;
        bool approved;
    }

    mapping (address => retailer) private retailers;
    mapping (address => supplier) private suppliers;
    mapping (uint256 => product) public products;
    mapping (uint256 => transaction) private transactions;
    productRequest[1] public productRequests;

    function registeration(string memory retailerStoreName, string memory supplierName, address supplierAddress) public returns (uint256) {
        retailers[msg.sender] = retailer(msg.sender, retailerStoreName, true);
        suppliers[supplierAddress] = supplier(supplierName, supplierAddress);
        return block.timestamp;
    }

    function checkTransactionStatus() public view returns(bool){
        return (productRequests[0].paymentTransaction);
    }

    function productRequesting(address supplierAddress, uint productID, uint retailerRequiredUnits) public returns (uint256){
        products[productID] = product(productID, false, supplierAddress, false, true);
        productRequests[0] = productRequest(0, msg.sender, supplierAddress, productID, retailerRequiredUnits, false);
        return block.timestamp;
    }

    function performTransaction(uint productID) public payable returns (uint256) {
        require(msg.value >0, "Insufficient Fund");
        require(products[productID].isExist == true, "Product ID does not Exist");
        products[productID].productOwner = productRequests[0].retailerAddress;
        addTransaction(productRequests[0].supplierAddress, productRequests[0].retailerAddress, productRequests[0].productID);
        productRequests[0].paymentTransaction = true;
        return block.timestamp;
    }

    function approveRequest(uint productID) public returns (uint256){
        require(productRequests[0].paymentTransaction == true, "Transaction is not performed yet");
        products[productID].paymentApprovedByAmazon = true;
        productRequests[0].paymentTransaction = false;
        return block.timestamp;
    }

    function addTransaction(address from, address to, uint256 productId) private returns(uint256) {
        uint256 currentTx = txCounter;
        transactions[currentTx] = transaction(currentTx, from, to, productId, true);
        txCounter ++;
        return currentTx;
    }

    function getTransactionDetails(uint256 txId) public view returns(transaction memory){
        return transactions[txId];
    }

    function markAsDelivered(uint256 productId, address _customerAddress) public returns (uint256){
        products[productId].isDeliveredToCustomer = true;
        //Transferring Ownership
        products[productId].productOwner = _customerAddress;
        return block.timestamp;
    }
}