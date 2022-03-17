/**
 *Submitted for verification at Etherscan.io on 2022-03-17
*/

pragma solidity ^0.5.15;

contract MultiSend {
    
    function sendETH(address payable[] memory recipients, uint256[] memory amounts) public payable {
        require(recipients.length > 0, "MultiTransfer: recipients length is zero");
        require(recipients.length == amounts.length, "MultiTransfer: size of recipients and amounts is not the same");
        for (uint256 i = 0; i < recipients.length; i++) {
            recipients[i].transfer(amounts[i]);
        }
    }
}