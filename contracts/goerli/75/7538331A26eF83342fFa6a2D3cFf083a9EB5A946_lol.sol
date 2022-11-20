/**
 *Submitted for verification at Etherscan.io on 2022-11-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IVault {
    function initialize(address owner, bytes memory input) external;
    function transferOwnership(address owner) external;

    function deploy(address owner, bytes calldata optional, bytes32 salt) external returns (address proxy, bytes memory returnData);
}

contract lol {

    string public message;
    address public owner;

    IVault public vault;

    address public proxy;
    bytes public returnData;

    constructor () {
        owner = msg.sender;
    }

    function setVault(address _vault) public onlyOwner {
        vault = IVault(_vault);
    }

    function setMessage(string memory _message) public onlyOwner {
        message = _message;
    }

    function callDeploy() public onlyOwner {
        (address _proxy, bytes memory _returnData) = vault.deploy(address(this),"","");
        proxy = _proxy;
        returnData = _returnData;
    }

    modifier onlyOwner () {
        msg.sender == owner;
        _;
    }

}