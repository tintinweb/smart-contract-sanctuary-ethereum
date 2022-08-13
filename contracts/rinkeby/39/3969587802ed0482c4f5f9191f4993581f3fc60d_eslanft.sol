/**
 *Submitted for verification at Etherscan.io on 2022-08-12
*/

pragma solidity ^0.8.7;

contract eslanft {
    address owner;

    mapping(uint => address) public ownership;
    uint totalSupply;

    bool isActive;

    constructor () payable {
        owner = msg.sender;
        isActive = true;
    }

    function toggleSale () external {
        isActive = !isActive;
    }

    function mint(uint amount) external payable {
        require(isActive, "Sale not active");

        for (uint i = 0; i < amount; i++) {
            ownership[totalSupply++] = msg.sender;
        }
    }
}