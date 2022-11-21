/**
 *Submitted for verification at Etherscan.io on 2022-11-21
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

contract RSW {
    enum Material {A, B}

    address owner;
    uint256 number;



    constructor()
    {
         owner = msg.sender;
    }

    modifier onlyOwner()
    {
        require(msg.sender == owner, "not an owner");
        _;
    }




    function predict(RSW.Material m, uint current) public view onlyOwner returns (uint) 
    {
        if(m == Material.A){
            if (current >= 845) return 23;
            else return 34;
        }

        if(m == Material.B){
            if(current >= 347) return 35;
            else return 57;
        }
    }

}