/**
 *Submitted for verification at Etherscan.io on 2022-10-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract Donation_Contract{
    string _own_contract;
    string _own_contract_name;
    string _donor;
    string _donation_title;
    string _description;

    uint _donate;
    uint _balance;
    uint _goal;
    string _personal_information;

    struct Donation{
        string _donorAdress; 
        string _donorName;
        uint _donation_amount;
    } 

    Donation[] private donations;

    constructor(string memory donation_title, string memory own_contract_name, string memory description, 
                string memory own_contract, uint balance, uint goal, string memory personal_information){
        // require(balance>0, "Donate greater zero");
        _donation_title = donation_title;
        _description = description;
        _own_contract = own_contract;
        _own_contract_name = own_contract_name;
        _personal_information = personal_information;
        _balance = balance;
        _goal = goal;
        
    }

    function getBalance() public view returns(uint balance){
        return _balance;
    }

    function history_donations() public view returns(Donation[] memory){  
        return donations;  
    }  

    function donate(string memory donor_address, string memory donorName, uint amount) public{
        _donor = donor_address;
        _balance += amount;
        
        donations.push(Donation({
            _donorAdress: donor_address,
            _donorName: donorName,
            _donation_amount: amount
            })
        );

    }
}