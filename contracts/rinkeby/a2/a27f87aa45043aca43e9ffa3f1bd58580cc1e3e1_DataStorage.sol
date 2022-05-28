/**
 *Submitted for verification at Etherscan.io on 2022-05-28
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;

// for more information look: https://www.youtube.com/watch?v=ZkWaAKl8npU&list=PLw6C5Nl3UrgglYcxXa48eH5Ny68oyTLRJ&index=8&t=294s

// start with keyword contract and the name of the contract
contract DataStorage {
    string _vorname;
    string _nachname;
    uint256 age;
    bool donateRestriction;

    function SetUserInfo(
        string memory vorname,
        string memory nachname,
        uint256 _age
    ) public {
        vorname = _vorname;
        nachname = _nachname;
        age = _age;
        if (age >= 16) {
            donateRestriction = true;
        } else donateRestriction = false;
    }

    // this function will display the information of the user
    function GetUserInfo()
        public
        view
        returns (
            string memory,
            string memory,
            uint256,
            bool
        )
    {
        return (_vorname, _nachname, age, donateRestriction);
    }
}