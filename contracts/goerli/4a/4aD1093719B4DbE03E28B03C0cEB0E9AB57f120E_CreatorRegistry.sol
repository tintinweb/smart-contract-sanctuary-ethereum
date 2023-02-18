// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {ICreatorRegistry} from "./interface/ICreatorRegistry.sol";
import {IFoundationNftV1TokenCreator} from "./interface/external/IFoundationNftV1TokenCreator.sol";
import {ISuperRareRegistry} from "./interface/external/ISuperRareRegistry.sol";

library SuperRareContracts {
    address public constant SUPERRARE_REGISTRY =
        0x17B0C8564E53f22364A6C8de6F7ca5CE9BEa4e5D;
    address public constant SUPERRARE_V1 =
        0x41A322b28D0fF354040e2CbC676F0320d8c8850d;
    address public constant SUPERRARE_V2 =
        0xb932a70A57673d89f4acfFBE830E8ed7f75Fb9e0;
}

library FoundationContracts {
    address public constant FOUNDATION_V1 =
        0x3B3ee1931Dc30C1957379FAc9aba94D1C48a5405;
}

contract CreatorRegistry is ICreatorRegistry, IERC165 {
    function getCreatorOf(address nftContract_, uint256 tokenId_)
        external
        view
        override
        returns (address)
    {
        // Foundation V1
        if (nftContract_ == FoundationContracts.FOUNDATION_V1) {
            try
                IFoundationNftV1TokenCreator(FoundationContracts.FOUNDATION_V1)
                    .tokenCreator(tokenId_)
            returns (address payable creator) {
                return creator;
            } catch {}
        }

        if (
            nftContract_ == SuperRareContracts.SUPERRARE_V1 ||
            nftContract_ == SuperRareContracts.SUPERRARE_V2
        ) {
            try
                ISuperRareRegistry(SuperRareContracts.SUPERRARE_REGISTRY)
                    .tokenCreator(nftContract_, tokenId_)
            returns (address payable creator) {
                return creator;
            } catch {}
        }

        // Foundation V2 (Creator-owned Collections)
        if (nftContract_.code.length > 0) {
            try
                IFoundationNftV1TokenCreator(nftContract_).tokenCreator(
                    tokenId_
                )
            returns (address payable creator) {
                return creator;
            } catch {}
        }

        revert("Cannot determine creator of NFT");
    }

    function supportsInterface(bytes4 interfaceId)
        external
        pure
        returns (bool)
    {
        return interfaceId == type(ICreatorRegistry).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface ICreatorRegistry {
    function getCreatorOf(address nftContract_, uint256 tokenId_)
        external
        view
        returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface IFoundationNftV1TokenCreator {
    /**
     * @notice Returns the creator's address for a given tokenId.
     */
    function tokenCreator(uint256 tokenId)
        external
        view
        returns (address payable);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface ISuperRareRegistry {
    /**
     * @dev Get the token creator which will receive royalties of the given token
     * @param _contractAddress address ERC721Contract address.
     * @param _tokenId uint256 token ID.
     */
    function tokenCreator(address _contractAddress, uint256 _tokenId)
        external
        view
        returns (address payable);
}