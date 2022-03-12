/**
 *Submitted for verification at Etherscan.io on 2022-03-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.4.0;


contract HelloWorld {
    struct Mentors{
        int id;
        string name;
    }

    Mentors []ment;

    function addMentor(int id, string name) public{
        Mentors memory e = Mentors(
            id,
            name
        );
        ment.push(e);
    }

    function getMentors(
        int id
    ) public view returns(
        string memory
    ){
        uint i;
        for(i=0; i < ment.length; i++){
            Mentors memory e = ment[i];

            if(e.id == id){
                return (e.name);
            }
        }
        return ("Not Found");
    }
}