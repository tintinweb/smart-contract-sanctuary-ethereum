/**
 *Submitted for verification at Etherscan.io on 2022-04-19
*/

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title HelloWorld
 * @dev Set & get number
 */
contract HelloWorld {
    event StoreNumber(uint256 number);

    uint256 internal number;

    /**
     * @dev Store/Set the number
     * @param _number an unsigned integer 256
     */
    function storeNumber(uint256 _number) external {
        number = _number;
        emit StoreNumber(_number);
    }

    /**
     * @dev Return number
     * @return unsigned integer 256
     */
    function retrieveNumber() external view returns(uint256) {
        return number;
    }
}