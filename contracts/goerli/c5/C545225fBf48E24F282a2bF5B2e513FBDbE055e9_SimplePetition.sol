// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract SimplePetition {

    /**
    * 1. User click on submit petition
    * 2. User sign a petition - create a contract
    * 3. User can remove himself from the petition
    * 4. User can add a comment
    * 
    */

    event NewSign(string name, string comment);

    mapping (address => ISignee) addressToSignee;
     struct ISignee {
        string name;
        string comment;
        bool active;
        address _address;
    }

    ISignee[] public signers;


    function signPetition(string memory _name, string memory _comment) public {
        // require(addressToSignee[msg.sender]);
        ISignee memory signee = ISignee(_name, _comment, true, msg.sender);
        signers.push(signee);
        emit NewSign(_name, _comment);
    }

    function unSign() public  {
        for(uint i = 0; i < signers.length; i++) {
            if(signers[i]._address == msg.sender) {
                signers[i].active = false;
            }
        }

    }
}