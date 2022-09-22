pragma solidity ^0.5.0;

import "./AbstractWrapper.sol";

contract Curio17bERC1155Wrapper is AbstractWrapper {

    function initialize() internal {
        // TODO change to 0xE0B5E6F32d657e0e18d4B3E801EBC76a5959e123
        // TODO replace with new image
        create(172, 0x6cdD2Af7A81A438E684B16d2f7E6881c1d99EB17, "ipfs://QmY2qTLrNmUvwVyKQF1JFqxSyZPtDH9cBo4CteLY3mtUYb");
    }

    constructor() AbstractWrapper() public {}
}