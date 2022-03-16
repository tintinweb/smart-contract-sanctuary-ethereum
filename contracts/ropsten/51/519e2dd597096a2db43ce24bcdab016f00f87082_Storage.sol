/**
 *Submitted for verification at Etherscan.io on 2022-03-16
*/

pragma solidity >=0.7.0 <0.9.0;

contract Storage {

    uint256 number;

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num) public {
        uint a = 0x6e2c8a666e2c8a66;
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