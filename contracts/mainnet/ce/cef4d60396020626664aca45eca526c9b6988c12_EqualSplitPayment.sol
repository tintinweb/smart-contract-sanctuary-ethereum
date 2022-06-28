/**
 *Submitted for verification at Etherscan.io on 2022-06-28
*/

pragma solidity >=0.7.0 <0.9.0;

contract EqualSplitPayment {

  function splitPayment(address[] memory payees) public payable {

    uint256 payout = msg.value / payees.length;

    for (uint i=0; i<payees.length; i++) {
        payable(payees[i]).transfer(payout);
    }

    uint256 remainder = msg.value - (payout * payees.length);

    if( remainder != 0 ){
        payable(msg.sender).transfer( remainder );
    }

  }
}