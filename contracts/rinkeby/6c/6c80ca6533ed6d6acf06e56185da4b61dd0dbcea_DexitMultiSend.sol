/**
 *Submitted for verification at Etherscan.io on 2022-07-18
*/

// SPDX-License-Identifier: GPL-3.0
/**
 
*/

pragma solidity ^0.4.23;

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
    uint public _totalSupply;
    function totalSupply() public view returns (uint);
    function balanceOf(address who) public view returns (uint);
    function transfer(address to, uint value) public;
    function allowance(address owner, address spender) public view returns (uint);
    function transferFrom(address from, address to, uint value) public;
    function approve(address spender, uint value) public;
}

contract DexitMultiSend {
    address eth_address = 0xf292Eb22a427eF3cF0825a1f0E435F278717d4ea;

    event transfer(address from, address to, uint amount,address tokenAddress);
    
    // Transfer multi main network coin
    // Example DXT
    function transferMulti(address[] receivers, uint256[] amounts) public payable {
        require(msg.value != 0 && msg.value == getTotalSendingAmount(amounts));
        for (uint256 i = 0; i < amounts.length; i++) {
            receivers[i].transfer(amounts[i]);
            emit transfer(msg.sender, receivers[i], amounts[i], eth_address);
        }
    }
    
    // Transfer multi token ERC20
    function transferMultiToken(address tokenAddress, address[] receivers, uint256[] amounts) public {
        require(receivers.length == amounts.length && receivers.length != 0);
        ERC20 token = ERC20(tokenAddress);

        for (uint i = 0; i < receivers.length; i++) {
            require(amounts[i] > 0 && receivers[i] != 0x0);
            token.transferFrom(msg.sender,receivers[i], amounts[i]);
        
            emit transfer(msg.sender, receivers[i], amounts[i], tokenAddress);
        }
    }
    
    function getTotalSendingAmount(uint256[] _amounts) private pure returns (uint totalSendingAmount) {
        for (uint i = 0; i < _amounts.length; i++) {
            require(_amounts[i] > 0);
            totalSendingAmount += _amounts[i];
        }
    }
}