// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface SanctionsList {
    function isSanctioned(address addr) external view returns (bool);
}

contract ForwardPayment {
    address payable public recipient;
    address public SANCTIONS_CONTRACT;

    constructor(address payable _recipient, address _sanctionsContract) {
        require(_recipient != address(0), "Invalid recipient address");
        recipient = _recipient;
        SANCTIONS_CONTRACT = _sanctionsContract;
    }
    function sendPayment(string calldata a, string calldata b, string calldata c) external payable {
        require(!isSanctioned(msg.sender), "Sender is sanctioned");
        require(msg.value > 0, "Amount must be greater than zero");
        (bool success, ) = recipient.call{value: msg.value}("");
        require(success, "Payment forwarding failed");
    }

    function isSanctioned(address _operatorAddress) public view returns (bool) {
        SanctionsList sanctionsList = SanctionsList(SANCTIONS_CONTRACT);
        bool isToSanctioned = sanctionsList.isSanctioned(_operatorAddress);
        return isToSanctioned;
    }
}