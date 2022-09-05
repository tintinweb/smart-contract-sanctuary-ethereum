/**
 *Submitted for verification at Etherscan.io on 2022-09-05
*/

// Sources flattened with hardhat v2.10.2 https://hardhat.org

// File contracts/PlatziSolidity.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

// import "hardhat/console.sol";

contract PlatziSolidity {
    string public name;
    string public state = "Opened";
    address payable private owner;
    uint256 public goal;
    uint256 public funded;

    constructor(string memory _name, uint256 _goal) {
        name = _name;
        owner = payable(msg.sender);
        goal = _goal;
        funded = 0;
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "You need to be thhe owner from this contract to change the goal"
        );
        _;
    }

    function compareStringsbyBytes(string memory s1, string memory s2)
        private
        pure
        returns (bool)
    {
        return
            keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
    }

    function fund() public payable {
        require(
            compareStringsbyBytes(state, "Opened") ||
                compareStringsbyBytes(state, "Paused"),
            "El proyecto no es fundable"
        );
        require(msg.value != 0, "Transferir fondos mayor a 0");

        require(
            funded + msg.value <= goal,
            "Los fondos superan el objetivo del crowdfunding"
        );
        owner.transfer(msg.value);
        funded += msg.value;
    }

    function changeProjectState(string calldata _state) public onlyOwner {
        state = _state;
    }
}