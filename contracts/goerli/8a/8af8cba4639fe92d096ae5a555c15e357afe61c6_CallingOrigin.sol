/**
 *Submitted for verification at Etherscan.io on 2022-03-11
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface IOrigin {
    function getMsgSender() external view returns(address);
}

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract CallingOrigin {

    IOrigin contractAddress = IOrigin(0xc82999Cb1b4a8559B7621c9f6bfa07E5e12ef8d9);

    function getCaller() public view returns(address) {
        return contractAddress.getMsgSender();
    }

}