/**
 *Submitted for verification at Etherscan.io on 2022-07-28
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;
contract SimplePayout {  
    
    uint256 payThreshold = 10; 
    uint256 safeFund = 0;
 
    struct Supplier {
        string  accountName;
        address accountAddress;
        uint256 rate;
        uint256 totalNumberOfPlaybacks;
    } 

    Supplier[] suppliers;
    uint256[]  numberOfUnpaidPlayback;
    uint256 supplierCount; // solidity default initializer is 0
    mapping (string => uint256) supplierMap;
    
 
    constructor() {
        suppliers.push(Supplier("_placeholder", address(0), 0, 0)); // this is done so I can check if an account exist using value>0
        numberOfUnpaidPlayback.push();
        supplierMap["_placeholder"] = 0;
    }

    function addAccount(string calldata _account, uint256 _rate, address _address) public returns (bool) {
        //If already exist, do nothing
        require (supplierMap[_account] == 0 ,  "Account already exist");
 
        uint256 index = suppliers.length; 
        suppliers.push(Supplier(_account, _address, _rate, 0));
        numberOfUnpaidPlayback.push(0);
        supplierMap[_account] = index;

        supplierCount += 1;

        return true;
    }
    
    function played (string calldata _account) public returns ( bool) {

        require (supplierMap[_account] > 0, "Account does not exist!");
 
        bool isPaid = false;
         // only add when the supplier exists
        uint256 index = supplierMap[_account];

        // update counts
        numberOfUnpaidPlayback[index] += 1;
        suppliers[index].totalNumberOfPlaybacks += 1;
         
        //pay if reach threshold
        if (isReadyToPay(numberOfUnpaidPlayback[index])){
            payout(_account, suppliers[index].accountAddress, getPayment(suppliers[index].rate));
            numberOfUnpaidPlayback[index] = 0;
            isPaid =true;
        }

        return (isPaid); 
    }

    // utilitiy functions 
    function isReadyToPay(uint256 number) private view returns (bool) {
        return   number >= payThreshold ;
    }

    function getPayment(uint256 rate) private view returns (uint256) {
        return payThreshold * rate;
    }

    // public functions
    function getTotalNumberOfPlaybacks(string calldata accountName) public view returns (uint256){
        return suppliers[supplierMap[accountName]].totalNumberOfPlaybacks;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    // add fund to the contract (this will increase the address(this).balance )
    function fund() public payable { 
    }

    // payout 
    function payout(string calldata accountName, address receiveAccount, uint256 amount) public payable { 

        //payable function cannot be private, therefore I verify the request all the time.
        //
        // TODO: check if smart contract and solidity already stops illegal pay 
        // request. Is there a protection in the smart contract concept already? 
        //
        require (suppliers[supplierMap[accountName]].accountAddress == receiveAccount, "Illegal reqeust!");
        require (isReadyToPay(numberOfUnpaidPlayback[supplierMap[accountName]]), "Not ready to pay out!");
        require (getPayment(suppliers[supplierMap[accountName]].rate) == amount, "Illegal request amount!" );

        address payable receiver = payable(receiveAccount);
        //only pay when the contract has enough funding.
        require (address(this).balance > safeFund, "Not enough fund in the contract");
        
        receiver.transfer(amount);
    }

}