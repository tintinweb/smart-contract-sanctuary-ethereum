/**
 *Submitted for verification at Etherscan.io on 2022-10-03
*/

// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.8.0;

contract AirdropNativeCurrency {

    event EthAirDrop(address indexed by,uint256 totalTransfers, uint256 ethValue);
    
    function airdropNativeCurrency(address[] memory _recipients,uint256[] memory _values, uint256 _totalToSend) public payable returns(bool success)
    {
        require(_recipients.length == _values.length, "Total Number of recipients and values are not equal");
        uint256 totalEthValue = _totalToSend;
        require(msg.value >=totalEthValue, "Not Enouth funds sent with transaction!");
        for(uint i = 0; i < _recipients.length; i++){
            payable(_recipients[i]).transfer(_values[i]);
        }
        emit EthAirDrop(msg.sender, _recipients.length, totalEthValue);
        return true;
    }

}