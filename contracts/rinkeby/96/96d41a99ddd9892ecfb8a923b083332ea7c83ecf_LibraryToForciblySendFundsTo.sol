/**
 *Submitted for verification at Etherscan.io on 2022-08-30
*/

library LibraryToForciblySendFundsTo {
    function balance() public view returns(uint256) {
        return address(this).balance;
    }
    function send(address payable recipient) public {
        recipient.transfer(address(this).balance);
    }
}