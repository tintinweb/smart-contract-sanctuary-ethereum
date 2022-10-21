/**
 *Submitted for verification at Etherscan.io on 2022-10-21
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract FlipTest {
    mapping(address => uint8) public mfers;
    bool public state;
    uint256 public currentId;
    address public owner;

    event Fark(uint256 id);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function addMfers(address[] memory newMfers) external payable onlyOwner {
        for (uint256 i; i < newMfers.length; i++) 
        {
            mfers[newMfers[i]] = 1;
        }
    }

    function flip() external payable {
        require(mfers[msg.sender] == 1);
        state = !state;
    }

    function fark() external payable {
        require(state);
        emit Fark(++currentId);
    }

    function withdraw() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }
}