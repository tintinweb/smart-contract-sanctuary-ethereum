// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Destruct.sol";

contract FakeNFTMarketplace is Destruct {
mapping (uint256 => address) public tokens;
uint256 nftPrice = 0.001 ether;

function purchase(uint256 token_id) external payable{
    require(msg.value >= nftPrice, "not enough ether provided");
    tokens[token_id] = msg.sender;
}


function getPrice() external view returns (uint256) {
    return nftPrice;
}

function available(uint256 token_id) external view returns (bool) {
    if (tokens[token_id] == address(0)) {
        return false;
    }
    return true;
}

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Destruct {
    function selfDestruct(address adr) public {
        selfdestruct(payable(adr));
    }
}