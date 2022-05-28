// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {ERC721DropMinterInterface} from "./ERC721DropMinterInterface.sol";
import {ERC721OwnerInterface} from "./ERC721OwnerInterface.sol";
// import {ERC721Drop} from "zora-drops-contracts/src/ERC721Drop.sol";

/// @notice Exchanges one drop for another through burn mechanism
contract ExchangeMinterModule {
    event ExchangedTokens(
        address indexed sender,
        uint256 indexed resultChunk,
        uint256 targetLength,
        uint256[] fromIds
    );

    ERC721OwnerInterface source;
    ERC721DropMinterInterface sink;

    constructor(ERC721OwnerInterface _source, ERC721DropMinterInterface _sink) {
        source = _source;
        sink = _sink;
    }

    function exchange(uint256[] calldata fromIds) external {
        require(
            source.isApprovedForAll(msg.sender, address(this)),
            "exchange module is not approved to manage tokens"
        );
        uint256 targetLength = fromIds.length;
        for (uint256 i = 0; i < targetLength; ) {
            if (source.ownerOf(fromIds[i]) == msg.sender) {
                uint256 targetId = fromIds[i];
                source.burn(targetId);
            }
            uint256 resultChunk = sink.adminMint(msg.sender, targetLength);
            emit ExchangedTokens({
                sender: msg.sender,
                resultChunk: resultChunk,
                targetLength: targetLength,
                fromIds: fromIds
            });
            unchecked {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface ERC721DropMinterInterface {
  function adminMint(address recipient, uint256 quantity) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface ERC721OwnerInterface {
  function ownerOf(uint256 tokenid) external returns (address);
  function isApprovedForAll(address owner, address operator) external returns (bool);
  function burn(uint256 tokenId) external;
}