/**
 *Submitted for verification at Etherscan.io on 2023-06-11
*/

contract AA {
    function equal(string memory _word) public pure returns(uint) {
        if(keccak256(bytes(_word)) == keccak256(bytes("hello"))) {
            return 1;
        } else if(keccak256(bytes(_word)) == keccak256(bytes("hi"))) {
            return 2;
        } else if(keccak256(bytes(_word)) == keccak256(bytes("move"))) {
            return 3;
        } else {
            return 4;
        }
    }
}