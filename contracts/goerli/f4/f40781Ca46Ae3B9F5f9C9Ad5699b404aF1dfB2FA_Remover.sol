/**
 *Submitted for verification at Etherscan.io on 2023-02-16
*/

contract Remover {
    address public addr;

    constructor(address _addr) public {
        addr = _addr;
    }

    function Remove() public {
        selfdestruct(payable(addr));
    }
}