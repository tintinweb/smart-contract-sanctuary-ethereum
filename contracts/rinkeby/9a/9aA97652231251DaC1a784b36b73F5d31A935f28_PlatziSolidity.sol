/**
 *Submitted for verification at Etherscan.io on 2022-09-05
*/

// Sources flattened with hardhat v2.10.2 https://hardhat.org

// File contracts/PlatziSolidity.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

// import "hardhat/console.sol";

contract PlatziSolidity {
    address private owner;
    uint256 private goal;
    uint256 private funded;
    bool private isFundable;

    constructor() {
        owner = msg.sender;
        goal = 10000;
        funded = 0;
        isFundable = true;
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "You need to be thhe owner from this contract to change the goal"
        );
        _;
    }

    function fund() public payable {
        require(isFundable, "El proyecto no es fundable");
        require(msg.value != 0, "Transferir fondos mayor a 0");

        require(
            funded + msg.value <= goal,
            "Los fondos superan el objetivo del crowdfunding"
        );
        funded += msg.value;
    }

    function changeProjectState(bool change) public onlyOwner {
        isFundable = change;
    }

    function getIsFundable() public view returns (bool) {
        return isFundable;
    }

    function getFundsAmount() public view returns (uint256) {
        return funded;
    }

    function getGoal() public view returns (uint256) {
        return goal;
    }
}