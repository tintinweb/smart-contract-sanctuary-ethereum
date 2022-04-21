// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./strcutContract.sol";

contract MintContract is StructContract{
    vData public cur;
    function mint(vData memory info, uint256 mintAmount,uint16 otherAmount) external returns(uint256, uint16){
        cur = info;

        return (mintAmount, otherAmount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract StructContract {
    address youraddr;

    struct vData {
        bool mint_free;
        uint256 max_mint;
    }
}