/**
 *Submitted for verification at Etherscan.io on 2022-08-03
*/

pragma solidity >=0.7.0 <0.9.0;

contract ransom_test{
    // string kunci = "dGVzdA=="

    function toBase64(string memory input) private {
        // malas ku buat
    }

    function encrypt(string memory flag) private{
        toBase64(flag);
    }
    function getRansom() public view returns(string memory){
        return "Thanks for the ETH but I am not gonna give you the key :)";
    }
}