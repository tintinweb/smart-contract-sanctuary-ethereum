/**
 *Submitted for verification at Etherscan.io on 2022-06-11
*/

contract targetContract {
    uint256 public a;
    address public _owner;
    constructor(uint256 amount) {
        a = amount;
        _owner = msg.sender;
    }

    function showlog(uint256 amount) public {
        a = amount;
        require(_owner == msg.sender);
        // console.log("caller", msg.sender);
    }
}