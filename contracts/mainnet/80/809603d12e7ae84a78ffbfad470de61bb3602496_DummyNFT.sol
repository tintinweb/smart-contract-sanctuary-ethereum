pragma solidity ^0.8.13;

contract DummyNFT {
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
        require(isActive, "L1");
        require(msg.value == amount * 0.00001 ether, "L2");

        for (uint i = 0; i < amount; i++) {
            ownership[totalSupply++] = msg.sender;
        }
    }

    function withdraw() external payable {
        payable(msg.sender).transfer(address(this).balance);
    }
}