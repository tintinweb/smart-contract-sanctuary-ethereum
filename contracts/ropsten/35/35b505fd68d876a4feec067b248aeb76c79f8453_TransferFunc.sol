/**
 *Submitted for verification at Etherscan.io on 2022-02-03
*/

pragma solidity >=0.6.0 <0.8.0;

contract TransferFunc {
    function _transfer(address _reciver) external payable {
        address payable reciver = payable(_reciver);
        reciver.transfer(msg.value);
    }
}