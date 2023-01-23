/**
 *Submitted for verification at Etherscan.io on 2023-01-23
*/

contract A{
    address public owner;
    constructor(
        string memory widowUrl,
        string memory name,
        string memory symbol
    ) {
                owner=msg.sender;
    }
 }