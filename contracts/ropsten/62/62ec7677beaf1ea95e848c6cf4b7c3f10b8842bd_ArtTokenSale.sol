/**
 *Submitted for verification at Etherscan.io on 2022-08-01
*/

// SPDX-License-Identifier: unlicensed
pragma solidity ^0.8.7;

interface IArtTokenSale {
    function mint(address _to, uint256 _value) external;
}

contract ArtTokenSale {

    address ArtTokenAddr;
    address _owner;

    constructor() {
        _owner = msg.sender;
    }

    function setArtTokenAddr(address arttoken) public {
       ArtTokenAddr = arttoken;
    }

    receive() external payable {
        (bool sent, bytes memory data) = _owner.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
        IArtTokenSale(ArtTokenAddr).mint(msg.sender, msg.value/100);
    }

}