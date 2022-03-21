/**
 *Submitted for verification at Etherscan.io on 2022-03-21
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    string public digitalSign;
    string public ipfsCid;

    event Upload(string digitalSign, string ipfsCid);

    /**
     * @dev Store value in variable
     */

    function store(string calldata _digitalSign, string calldata _ipfsCid) external {
        digitalSign = _digitalSign;
        ipfsCid = _ipfsCid;

        emit Upload(_digitalSign, _ipfsCid);
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieveDigitalSign() external view returns (string memory){
        return digitalSign;
    }

    function retrieveIpfs() external view returns (string memory){
        return ipfsCid;
    }
}