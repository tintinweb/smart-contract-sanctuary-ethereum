pragma solidity ^0.5.0;

import "./AbstractWrapper.sol";

contract Curio17bERC1155Wrapper is AbstractWrapper {

    function initialize() internal {
        create(172, 0x79C7D513CEe2b37edbA1F44e7C264ABBfadF31A8, "ipfs://QmfRnFY9zBGGYDPSY4GN37sTU8pgrV9joAt69ELRsZs99N");
    }

    constructor() AbstractWrapper() public {}
}