// SPDX-Lincense-Identifier: MIT

pragma solidity ^0.8.0;

contract EtherSplit {

    address[] private receivers;
    address deployer;

    constructor () {
        deployer = msg.sender;
    }

    modifier onlyDeployer() {
        require(msg.sender == deployer, "only deployer can do this operation");
        _;
    }

    function addReceiver (address _receiver) public onlyDeployer {
        receivers.push(_receiver);
    }

    function addReceivers (address[] memory _receivers) public {
        for (uint i = 0; i < _receivers.length; ++i) {
            addReceiver(_receivers[i]);
        }
    }

    receive () external payable {
        uint share = msg.value / receivers.length;
        for (uint i = 0; i < receivers.length; ++i) {
            payable(receivers[i]).transfer(share);
        }

        uint leftover = address(this).balance;
        payable(msg.sender).transfer(leftover);
    }




}