/**
 *Submitted for verification at Etherscan.io on 2022-06-13
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface cETH {
    function mint() external payable;
    function redeem(uint redeemTokens) external returns (uint);

    function exchangeRateStored() external view returns (uint);
    function balanceOf(address owner) external view returns (uint256 balance);
}

contract smartBank {

    uint public totalBalance = 0;

    address COMPOUND_CETH_ADDRESS = 0xd6801a1DfFCd0a410336Ef88DeF4320D6DF1883e;
    cETH ceth = cETH(COMPOUND_CETH_ADDRESS);

    function getTotalBalance() public view returns(uint){
        return totalBalance;
    }

    mapping(address => uint) balances;
    mapping(address => uint) depositTimestamps;

    function addBalance() public payable {
        balances[msg.sender] = msg.value;
        totalBalance = totalBalance + msg.value;
        depositTimestamps[msg.sender] = block.timestamp;
        ceth.mint{value: msg.value}();
    }

    function getBalance(address userAddress) public view returns(uint256){      
        return ceth.balanceOf(userAddress) * ceth.exchangeRateStored() / 1e18;
    }

    function withdraw() public payable {
        address payable withdrawTo = payable(msg.sender);
        uint amountToTransfer = getBalance(msg.sender);
        withdrawTo.transfer(amountToTransfer);
        totalBalance = totalBalance - amountToTransfer;
        balances[msg.sender] = 0;
    }

    function addMoneyToContract() public payable {
        totalBalance += msg.value;
    }
}