/**
 *Submitted for verification at Etherscan.io on 2022-10-19
*/

contract Token {

    string public tokenName = "token";
    uint256 public totalSupply = 99999999;

    function setName(string memory name) public {
        tokenName = name;
    }

    function setTotal(uint256 total) public {
        totalSupply = total;
    }
}