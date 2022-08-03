/**
 *Submitted for verification at Etherscan.io on 2022-08-03
*/

pragma solidity >=0.7.0 <0.9.0;

contract ransom{
    // string kunci = "ZGRjZmNlZjJlYmJiZWNmZWViZTVkYWVlZGZkZmNlZmRkMmJgYmhkY2RoZGZiZGU2ZGhkZ2RhZWVkZGNmY2VmZGVgZTVjZWZkZDJmZmI1YjU="

    function toBase64(string memory input) private returns(string memory) {
        // base64 function here - do it yourself
        return input;
    }
    function toHex(string memory input) private returns(string memory) {
        // to hex function here - do it yourself
        return input;
    }
    function rot47(string memory input) private returns(string memory) {
        // rot47 here - do it yourself
        return input;
    }

    function encrypt(string memory flag) private returns(string memory){
        string memory kunci = toBase64(rot47(toHex(toBase64(flag))));
        return kunci;
    }
    function getRansom() public view returns(string memory){
        return "Thanks for the ETH but I am not gonna give you the key :)";
    }
}