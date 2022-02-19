pragma solidity 0.8.10;

import "./ERC721.sol";

contract AirdropHelper{
    address constant Owner = 0x5F13c058a660631558De911acd1b3B216B7f7f2A;
    ERC721 constant Pixelmon = ERC721(0x32973908FaeE0Bf825A343000fE412ebE56F802A);

    constructor() {}

    function bulkTransfer(address[] calldata receivers, uint[] calldata tokenIds) public {
        require(msg.sender == Owner);
        require(receivers.length == tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            Pixelmon.transferFrom(Owner, receivers[i], tokenIds[i]); 
        }
    }
}