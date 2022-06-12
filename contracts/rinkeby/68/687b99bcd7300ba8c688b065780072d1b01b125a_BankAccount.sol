/**
 *Submitted for verification at Etherscan.io on 2022-06-12
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface cETH {
    function mint() external payable;

    function redeem(uint redeemTokens) external returns (uint);

    function exchangeRateStored() external view returns (uint);

    function balanceOf(address owner) external view returns (uint balance);
}

contract BankAccount {
    uint totalContractBalance = 0;

    address COMPOUND_CETH_ADDRESS = 0xd6801a1DfFCd0a410336Ef88DeF4320D6DF1883e;
    cETH ceth = cETH(COMPOUND_CETH_ADDRESS);

    mapping(address => uint) balances;
    mapping(address => uint) depositTimestamps;

    function getContractBalance() public view returns (uint) {
        return totalContractBalance;
    }

    function addBalance() external payable {
        balances[msg.sender] += msg.value;
        totalContractBalance += msg.value;
        depositTimestamps[msg.sender] += block.timestamp;

        ceth.mint{value: msg.value}();
    }

    function getBalance(address userAddress) public view returns (uint) {
        return (ceth.balanceOf(userAddress) * ceth.exchangeRateStored()) / 1e18;
    }

    function withdraw() public {
        uint amountToTransfer = getBalance(msg.sender);
        totalContractBalance -= amountToTransfer;
        balances[msg.sender] = 0;
        ceth.redeem(getBalance(msg.sender));
    }

    function addMoneyToContract() public payable {
        totalContractBalance += msg.value;
    }
}