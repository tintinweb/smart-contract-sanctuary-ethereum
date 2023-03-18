//SPDX-License-Identifier: None
pragma solidity =0.7.6;
pragma abicoder v2;

import "./utils/Ownable.sol";

contract Owner is Ownable {
    function sweepTokenFromRouter(address router, address token, uint amount, address receiver) onlyOwner external {
        (bool success, ) = router.call(abi.encode(uint(0), token, amount, receiver));
        require(success);
    }

    function setPool(address router, uint id, address pool) onlyOwner external {
        (bool success, ) = router.call(abi.encode(uint(1), id, pool));
        require(success);
    }
}

//SPDX-License-Identifier: None
pragma solidity =0.7.6;

contract Ownable {
    address public owner;

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "!owner");
        _;
    }

    function setOwner(address newOwner) onlyOwner external {
        owner = newOwner;
    }
}