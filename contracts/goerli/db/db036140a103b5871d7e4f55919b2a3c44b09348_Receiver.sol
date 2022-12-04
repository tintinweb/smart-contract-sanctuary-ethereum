/**
 *Submitted for verification at Etherscan.io on 2022-12-04
*/

pragma solidity >=0.7.0 <0.9.0;
contract Receiver {
    function send() payable public {
        uint256  amount = msg.value;
        if(amount >= 0.0001 ether) {
            revert("transfer amount is too big");
        }

    }
    function balance() public returns(uint256) {
        return address(this).balance;
    }
}