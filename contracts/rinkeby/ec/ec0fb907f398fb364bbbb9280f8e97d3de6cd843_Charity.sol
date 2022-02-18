/**
 *Submitted for verification at Etherscan.io on 2022-02-18
*/

contract Charity {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function donate() public payable { }

    function withdraw() public {
        (bool sent,) = owner.call{value: address(this).balance}("");
        require(sent, "Failed to send ether.");
    }
}