// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/** 
 * @title Account
 * @dev Implements Account data  querys from it
 */

contract Account {
    string name;
    string publicKey;
    string asset;
    uint256 assetAmount;

    function account(string memory accountname, string memory publickey) public {
        name = accountname;
        publicKey = publickey;
    }

    function retrieveName() public view returns(string memory){
        return name;
    }

    function retrievePublicKey() public view returns(string memory){
        return publicKey;
    }

}