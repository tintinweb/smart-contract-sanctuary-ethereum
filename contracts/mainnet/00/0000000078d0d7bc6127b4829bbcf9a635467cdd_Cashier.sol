/**
 *Submitted for verification at Etherscan.io on 2022-09-20
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
contract Cashier {
    address payable public coldWallet;
    
    constructor(address multiSigWallet) payable
    {
        coldWallet = payable(multiSigWallet);
    }

    function execute(address protocalAddress, bytes calldata data, uint256 sumPrice) public payable
    {
        require(protocalAddress != address(0) && protocalAddress != address(this), "invalid protocol address");
        require(msg.value >= sumPrice * 1001 / 1000, "platform fee required");

        coldWallet.transfer(sumPrice * 1 / 1000);

        (bool success, bytes memory result) = protocalAddress.call{value: sumPrice}(data);
        if(!success)
           _revertWithData(result); 
        _returnWithData(result);
    }

    receive() external payable {}

    function _revertWithData(bytes memory data) private pure {
        assembly { revert(add(data, 32), mload(data)) }
    }

    function _returnWithData(bytes memory data) private pure {
        assembly { return(add(data, 32), mload(data)) }
    }
}