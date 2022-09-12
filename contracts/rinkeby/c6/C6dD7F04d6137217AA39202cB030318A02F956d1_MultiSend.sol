/**
 *Submitted for verification at Etherscan.io on 2022-09-12
*/

pragma solidity ^0.8.0;

contract MultiSend {
    function sendGDCC(address payable[] memory recipients, uint256[] memory amounts) public payable {
        require(recipients.length > 0, "MultiTransfer: recipients length is zero");
        require(recipients.length == amounts.length, "MultiTransfer: size of recipients and amounts is not the same");
        for (uint256 i = 0; i < recipients.length; i++) {
            recipients[i].transfer(amounts[i]);
        }
    }
}