/**
 *Submitted for verification at Etherscan.io on 2022-08-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

struct Lolz {
    string lol;
    uint256 confirmationId;
}

contract SimpleStorage {
    mapping(address => uint256) _balances;
    mapping(address => Lolz) public _lols;
    uint256 _confirmationId;

    function addBalance (uint256 balance) public {
        _balances[msg.sender] = balance;
    }

    function retrieveUserBalance (address _user) public view returns(uint256){
        return _balances[_user];
    }

    function addALol(string memory _lol) public returns(uint256) {
        if(bytes(_lols[msg.sender].lol).length == 0){ //still learning but here we gooo
            _lols[msg.sender] = Lolz(_lol, _confirmationId++);
        }
        _lols[msg.sender].lol = _lol;
        return _lols[msg.sender].confirmationId;
    }

}