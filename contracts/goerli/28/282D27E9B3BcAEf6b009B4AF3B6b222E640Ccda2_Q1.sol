/**
 *Submitted for verification at Etherscan.io on 2023-06-07
*/

contract Q1 {
    function equal(string memory _a, string memory _b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked(_a)) == keccak256(abi.encodePacked(_b)));
    }

    function compare(string memory _word) public view returns(uint) {
        if(equal(_word, "hello")) {
            return 1;
        } else if (equal(_word, "hi")) {
            return 2;
        } else if (equal(_word, "move")) {
            return 3;
        } else {
            return 4;
        }
    }
}