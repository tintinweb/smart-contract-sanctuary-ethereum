/**
 *Submitted for verification at Etherscan.io on 2022-08-15
*/

pragma solidity ^0.8.16;

contract DummyFreeNFT {
    mapping(uint => address) ownership;
    uint public totalSupply;

    bool isActive;

    constructor () payable {
        isActive = true;
    }

    function toggleSale () external {
        isActive = !isActive;
    }

    function mint(uint amount) external payable {
        require(isActive, "L");

        for (uint i = 0; i < amount; i++) {
            ownership[totalSupply++] = msg.sender;
        }
    }

    function withdraw() external payable {
        payable(msg.sender).transfer(address(this).balance);
    }
}