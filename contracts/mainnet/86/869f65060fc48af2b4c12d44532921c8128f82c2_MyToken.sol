/**
 *Submitted for verification at Etherscan.io on 2022-07-13
*/

contract MyToken {
    string public constant version = "0.1";
    string public name = "404 NOT FOUND";
    string public symbol = "404";
    uint256 public constant decimals = 0;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function totalSupply() public view returns (uint256) {
        return 100000;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return block.number;
    }

    function transfer(address payable _to, uint256 _value) public returns (bool) {
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
}