// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./IRengokuSamurais.sol";

contract RengokuSamuraisBurnMultiple {
    address private immutable rengokuSamuraisContractAddress;

    constructor(address _rengokuSamuraisContractAddress) {
        rengokuSamuraisContractAddress = _rengokuSamuraisContractAddress;
    }

    function burnSamurais(uint256[] memory _ids) public {
        IRengokuSamurais RengokuSamurais = IRengokuSamurais(rengokuSamuraisContractAddress);
        require(RengokuSamurais.isApprovedForAll(msg.sender, address(this)), "Calls to Samurai contract not approved for sender");
        for (uint256 i; i < _ids.length; i++) {
            RengokuSamurais.transferFrom(msg.sender, address(this), _ids[i]);
            RengokuSamurais.burnToken(_ids[i]);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;


interface IRengokuSamurais {

    function burnToken(uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);

}