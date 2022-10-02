// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SyntheticData} from "../ERC3664/utils/SyntheticData.sol";
import {PetData} from "./PetData.sol";
import {IComponentBase} from "../Component/IComponentBase.sol";

library SyntheticLogic {
    function combine(
        uint256 tokenId,
        uint256[] calldata subIds,
        address[] calldata subAddress,
        bytes memory primaryAttrText,
        mapping(uint256 => SyntheticData.SynthesizedToken[])
            storage synthesizedTokens
    ) public {
        for (uint256 i = 0; i < subIds.length; i++) {
            // require(
            //     IComponentBase(subAddress[i]).ownerOf(subIds[i]) == msg.sender,
            //     "caller is not sub token owner"
            // );
            uint256 nft_attr = IComponentBase(subAddress[i]).primaryAttributeOf(
                subIds[i]
            );
            bytes memory text = IComponentBase(subAddress[i]).textOf(
                subIds[i],
                nft_attr
            );
            address owner = IComponentBase(subAddress[i]).ownerOf(subIds[i]);
            require(
                keccak256(text) != keccak256(primaryAttrText),
                "not support combine between primary token"
            );
            for (uint256 j = 0; j < synthesizedTokens[tokenId].length; j++) {
                uint256 id = synthesizedTokens[tokenId][j].id;
                address token = synthesizedTokens[tokenId][j].token;

                bytes memory _text = IComponentBase(token).textOf(id, nft_attr);

                require(
                    keccak256(text) != keccak256(_text),
                    "duplicate sub token type"
                );
            }
            IComponentBase(subAddress[i]).transferFrom(
                owner,
                address(this),
                subIds[i]
            );

            synthesizedTokens[tokenId].push(
                SyntheticData.SynthesizedToken(
                    subAddress[i],
                    msg.sender,
                    subIds[i]
                )
            );
        }
    }

    // function separate(uint256 tokenId, string memory _uri) public {
    //     require(
    //         _isApprovedOrOwner(_msgSender(), tokenId),
    //         "caller is not token owner nor approved"
    //     );
    //     require(
    //         primaryAttributeOf(tokenId) == PET_NFT,
    //         "only support primary token separate"
    //     );
    //     SynthesizedToken[] storage subs = synthesizedTokens[tokenId];
    //     require(subs.length > 0, "not synthesized token");
    //     for (uint256 i = 0; i < subs.length; i++) {
    //         _transfer(address(this), subs[i].owner, subs[i].id);
    //     }
    //     delete synthesizedTokens[tokenId];
    //     _setTokenURI(tokenId, _uri);
    // }

    function separateOne(
        uint256 tokenId,
        uint256 subId,
        uint256 idx,
        mapping(uint256 => SyntheticData.SynthesizedToken[])
            storage synthesizedTokens
    ) public {
        address owner = synthesizedTokens[tokenId][idx].owner;
        address token = synthesizedTokens[tokenId][idx].token;
        IComponentBase(token).transferFrom(address(this), owner, subId);
        removeAtIndex(synthesizedTokens[tokenId], idx);
    }

    function findByValue(
        SyntheticData.SynthesizedToken[] storage values,
        uint256 value,
        address _addr
    ) internal view returns (uint256) {
        uint256 i = 0;
        while (values[i].id != value || values[i].token != _addr) {
            i++;
        }
        return i;
    }

    function removeAtIndex(
        SyntheticData.SynthesizedToken[] storage values,
        uint256 index
    ) internal {
        uint256 max = values.length;
        if (index >= max) return;

        if (index == max - 1) {
            values.pop();
            return;
        }

        for (uint256 i = index; i < max - 1; i++) {
            values[i] = values[i + 1];
        }
        values.pop();
    }

    function setSubOwner(
        SyntheticData.SynthesizedToken[] storage values,
        address to
    ) internal {
        for (uint256 i = 0; i < values.length; i++) {
            values[i].owner = to;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SyntheticData {
    struct SynthesizedToken {
        address token;
        address owner;
        uint256 id;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library PetData {
    bytes32 public constant GOVERNORS = keccak256("GOVERNORS");
    bytes32 public constant URI_SETTER = keccak256("URI_SETTER");

    // immutable attributes
    uint256 public constant PET_NFT = 1;

    // variable attributes
    uint256 public constant Level = 2;
    uint256 public constant Species = 3;
    uint256 public constant Characteristic = 4;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../ERC3664/IERC3664.sol";
import {IERC3664TextBased} from "../ERC3664/extensions/IERC3664TextBased.sol";

interface IComponentBase is IERC721, IERC3664TextBased {
    function mint() external;

    function recordSubTokens(
        uint256 tokenId,
        address primaryToken,
        uint256 primaryTokenId
    ) external;

    function getCurrentTokenId() external returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC3664 compliant contract.
 */
interface IERC3664 is IERC165 {
    /**
     * @dev Emitted when new attribute type `attrId` are minted.
     */
    event AttributeCreated(
        uint256 indexed attrId,
        string name,
        string symbol,
        string uri
    );

    /**
     * @dev Emitted when `value` of attribute type `attrId` are attached to "to"
     * or removed from `from` by `operator`.
     */
    event TransferSingle(
        address indexed operator,
        uint256 from,
        uint256 to,
        uint256 indexed attrId,
        uint256 value
    );

    /**
     * @dev Equivalent to multiple {TransferSingle} events.
     */
    event TransferBatch(
        address indexed operator,
        uint256 from,
        uint256 to,
        uint256[] indexed attrIds,
        uint256[] values
    );

    /**
     * @dev Returns primary attribute type of owned by `tokenId`.
     */
    function primaryAttributeOf(uint256 tokenId)
        external
        view
        returns (uint256);

    /**
     * @dev Returns all attribute types of owned by `tokenId`.
     */
    function attributesOf(uint256 tokenId)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Returns the attribute type `attrId` value owned by `tokenId`.
     */
    function balanceOf(uint256 tokenId, uint256 attrId)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the batch of attribute type `attrIds` values owned by `tokenId`.
     */
    function balanceOfBatch(uint256 tokenId, uint256[] calldata attrIds)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Set primary attribute type of owned by `tokenId`.
     */
    // function setPrimaryAttribute(uint256 tokenId, uint256 attrId) external;

    /**
     * @dev Attaches `amount` value of attribute type `attrId` to `tokenId`.
     */
    function attach(
        uint256 tokenId,
        uint256 attrId,
        uint256 amount
    ) external;

    /**
     * @dev [Batched] version of {attach}.
     */
    function batchAttach(
        uint256 tokenId,
        uint256[] calldata attrIds,
        uint256[] calldata amounts
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC3664Metadata.sol";

interface IERC3664TextBased is IERC3664Metadata {
    function textOf(uint256 tokenId, uint256 attrId)
        external
        view
        returns (bytes memory);

    function attachWithText(
        uint256 tokenId,
        uint256 attrId,
        uint256 amount,
        bytes memory text
    ) external;

    function batchAttachWithTexts(
        uint256 tokenId,
        uint256[] calldata attrIds,
        uint256[] calldata amounts,
        bytes[] calldata texts
    ) external;
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

pragma solidity ^0.8.0;

import "../IERC3664.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC3664 standard.
 */
interface IERC3664Metadata is IERC3664 {
    /**
     * @dev Returns the name of the attribute.
     */
    function name(uint256 attrId) external view returns (string memory);

    /**
     * @dev Returns the symbol of the attribute.
     */
    function symbol(uint256 attrId) external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `attrId` attribute.
     */
    function attrURI(uint256 attrId) external view returns (string memory);
}