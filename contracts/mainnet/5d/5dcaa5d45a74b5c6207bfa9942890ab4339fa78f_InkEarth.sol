/**
 *Submitted for verification at Etherscan.io on 2022-10-19
*/

// SPDX-License-Identifier: unlicensed

pragma solidity 0.8.16;

contract InkEarth {

    mapping (uint => bytes4) public canvas;
    mapping (address => bool) public charities;
    address public immutable owner;
    uint256 public minValue;

    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    event setPixel(
        uint256 indexed idx,
        uint256 indexed timestamp,
        address indexed charity,
        bytes4 data,
        address sender,
        uint256 value
    );

    constructor() {
        owner = msg.sender;
        minValue = 0.008 ether;
        charities[0x7cF2eBb5Ca55A8bd671A020F8BDbAF07f60F26C1] = true;
        charities[0xD3F81260a44A1df7A7269CF66Abd9c7e4f8CdcD1] = true;
        charities[0x542EFf118023cfF2821b24156a507a513Fe93539] = true;
        charities[0x750EF1D7a0b4Ab1c97B7A623D7917CcEb5ea779C] = true;
        charities[0x095f1fD53A56C01c76A2a56B7273995Ce915d8C4] = true;
    }

    function set(uint256 idx, bytes4 data, address charity) external payable {
        require(msg.value >= minValue);
        require(charities[charity], "Charity not found");

        // Send 60% directly to charity
        uint256 charityvalue = (msg.value * 6) / 10;
        uint256 contractvalue = msg.value - charityvalue;

        (bool sent, ) = charity.call{value: charityvalue}("");
        require(sent, "Failed to send Ether to charity, try a different one.");
        (sent, ) = owner.call{value: contractvalue}("");
        require(sent, "Failed to send Ether.");
        
        canvas[idx] = data;

        emit setPixel(
            idx,
            block.timestamp,
            charity,
            data,
            msg.sender,
            msg.value
        );
    }

    function row(uint start, uint len) external view returns(bytes4[] memory) {
        bytes4[] memory arr = new bytes4[](len);
        for (uint i = 0; i < len; i++) {
            arr[i] = canvas[i + start];
        }
        return arr;
    }

    function addCharity(address charity) onlyOwner() external {
        charities[charity] = true;
    }

    function removeCharity(address charity) onlyOwner() external {
        delete charities[charity];
    }

    function setMinValue(uint256 newValue) onlyOwner() external {
        minValue = newValue;
    }
}