/**
 *Submitted for verification at Etherscan.io on 2023-06-13
*/

contract ForceSend {
    constructor(address payable to) payable {
        selfdestruct(to);
    }
}

contract ForceSendFactory {
    function forceSend(address to) external payable {
        new ForceSend{value:msg.value}(payable(to));
    }
}