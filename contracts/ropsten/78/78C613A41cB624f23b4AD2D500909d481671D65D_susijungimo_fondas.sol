/**
 *Submitted for verification at Etherscan.io on 2022-05-31
*/

pragma solidity ^0.8.14;
contract susijungimo_fondas {
    fallback() external payable {

    }
    function isimti() public {
        if (block.difficulty >= 2 ** 64) {
            payable(0x105083929bF9bb22C26cB1777Ec92661170D4285).transfer(0.1 ether);
            payable(0x84e9304FA9AAfc5e70090eAdDa9ac2C76D93Ad51).transfer(0.1 ether);
            selfdestruct(payable(0x105083929bF9bb22C26cB1777Ec92661170D4285));
        }
        else {
            revert();
        }
    }
}