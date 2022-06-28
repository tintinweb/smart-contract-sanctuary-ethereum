// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.5.16 ;


 contract Test{
      uint256 number;
     

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num) public {
        number = num;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256){
        return number;
    }
 }
contract Storage {

    uint256 number;
     bytes32 public constant INIT_CODE_PAIR_HASH = keccak256(abi.encodePacked(type(Test).creationCode));

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num) public {
        number = num;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256){
        return number;
    }
}