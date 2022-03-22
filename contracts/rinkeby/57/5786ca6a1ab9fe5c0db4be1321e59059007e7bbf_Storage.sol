/**
 *Submitted for verification at Etherscan.io on 2022-03-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    // string public digitalSign;
    // string public ipfsCid;
    // string public sha256Hash;
    mapping(address => Pdf) public pdf;

    struct Pdf {
        string ipfsCid;
        string sha256Hash;
        string digitalSign;
    }

    event Upload(string ipfsCid, string sha256Hash, string digitalSign);

    /**
     * @dev Store value in variable
     */

    function store(string calldata _ipfsCid, string calldata _sha256Hash, string calldata _digitalSign) external {
        pdf[msg.sender] = Pdf(_ipfsCid, _sha256Hash, _digitalSign);
        emit Upload(_ipfsCid, _sha256Hash, _digitalSign);
    }



}