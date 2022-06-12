/**
 *Submitted for verification at Etherscan.io on 2022-06-12
*/

contract Message {
    string text;

    function set(string memory _text) public {
        text = _text;
    }

    function get() public view returns (string memory) {
        return text;
    }
}