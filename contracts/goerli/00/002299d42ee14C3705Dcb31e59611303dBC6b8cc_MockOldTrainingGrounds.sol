// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../wnd/riftroot/IOldTrainingGrounds.sol";

contract MockOldTrainingGrounds is IOldTrainingGrounds {

    mapping(uint256 => address) private tokenToAtTG;

    function ownsToken(uint256 tokenId) external view override returns (bool) {
        return tx.origin == tokenToAtTG[tokenId];
    }

    function setTokenAtTG(uint256 _tokenId, address _originalOwner) external {
        tokenToAtTG[_tokenId] = _originalOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOldTrainingGrounds {
    function ownsToken(uint256 tokenId) external view returns (bool);
}