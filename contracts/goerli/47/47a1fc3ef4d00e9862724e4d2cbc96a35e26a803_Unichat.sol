/**
 *Submitted for verification at Etherscan.io on 2022-06-25
*/

// SPDX-License-Identifier: no
pragma solidity ^0.8.14; 

contract Unichat {
    // variables
    uint256 FixedPaymentAmount = 1000000000000000; // .001 eth in wei
    mapping(string => address) public submitters; 
    mapping(address => uint256) public balances;

    // events
    event NewEntry(string _hash);  

    // this needs to be executed before AddData() can be called
    function FundContract() payable public returns(bool) {
        require(msg.value == FixedPaymentAmount); 
        submitters['initial'] = msg.sender;
        return true;
    }
        

    function AddData(string memory _oldHash, string memory _newHash) payable public returns(bool) {         
        require((msg.value) >= FixedPaymentAmount, "Not enough ETH sent to stake.");
        require(bytes20(submitters[_oldHash]) != 0, "Another hash has been submitted by another node.");
        
        
        // receive ETH to be staked 
        (bool storeSuccess,) = msg.sender.call{value: FixedPaymentAmount}("");
        require(storeSuccess, "Transfer IN failed.");

        
        // update submitters with _newHash to msg.sender 
        submitters[_newHash] = msg.sender;


        // add the freed up balance to the balances map 
        balances[submitters[_oldHash]] += FixedPaymentAmount;

        // clean up submitters[_oldHash]]
        delete submitters[_oldHash];

        emit NewEntry(_newHash);

        return true; 
    }


    function WithdrawFunds(address payable _address) external returns(bool) {
        // sends back ETH to anyone whose funds have been freed up after another address submits hashes
        uint256 currentBalance;
        currentBalance = balances[_address];
        balances[_address] = 0;
       (bool success,) =    
        _address.call{value: currentBalance}('');
        
        require(success, "Transfer OUT failed.");
    
        return true;
    }
}