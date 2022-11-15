/**
 *Submitted for verification at Etherscan.io on 2022-11-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract Storage {

    uint256 numero;

    /**
     * @dev Store value in variable
     * @param _num value to store
     */
    function store(uint256 _num) public {
        numero = _num;
    }

    /**
     * @dev Return value 
     * @return value of 'numero'
     */
    function retrieve() public view returns (uint256){
        return numero;
    }
}