/**
 *Submitted for verification at Etherscan.io on 2022-05-22
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

contract V_ID {

    // this will get initialise to 0! public makes it public
    uint256 vesselId;
    bool vesselBool;

    struct People {
        uint256 vesselId;
        string name;
    }

    People[] public people;
    mapping(string => uint256) public nameToVesselId;


    function store(uint256 _vesselId) public {
        vesselId = _vesselId;
    }

    //view, pure has no blochain transaction!
    function retrive() public view returns(uint256) {
        return vesselId;
    }

    //function to add persons to vessel
    function addPerson(string memory _name, uint256 _vesselId) public {
    people.push(People (_vesselId, _name));
    nameToVesselId[_name] = _vesselId;

    }


}