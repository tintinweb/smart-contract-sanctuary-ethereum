/**
 *Submitted for verification at Etherscan.io on 2022-07-20
*/

pragma solidity >=0.6.2 <0.7.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    uint256 number;

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num) public {
        number = num;
        uint a = 1;
        uint b = 2;
        a = b;
        b = 1;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256){
        return number;
    }
}