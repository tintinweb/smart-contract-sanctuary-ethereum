// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { BitMaps } from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import { IHashes } from "../../interfaces/IHashes.sol";
import { ICollectionNFTEligibilityPredicate } from "../../interfaces/ICollectionNFTEligibilityPredicate.sol";
import { ICollectionNFTMintFeePredicate } from "../../interfaces/ICollectionNFTMintFeePredicate.sol";
import { ICollectionNFTCloneableV1 } from "../../interfaces/ICollectionNFTCloneableV1.sol";

/**
 * @title  SigilManagement
 * @author Cooki.eth
 * @notice This contract defines both the mint price and mint elibility for the
 *         Sigils NFT collections. It is ownable, and active Sigil collections
 *         must be activated by the owner in order for Sigils to be minted. The 
 *         owner may also de-activate collections.
 */
contract SigilManagement is Ownable, ICollectionNFTEligibilityPredicate, ICollectionNFTMintFeePredicate {
    /// @notice The Hashes address.
    IHashes public hashes;

    /// @notice activeSigils Mapping of currently active Sigil addresses.
    mapping(ICollectionNFTCloneableV1 => bool) public activeSigils;

    /// @notice activeSigilsList Array of currently active Sigil addresses.
    ICollectionNFTCloneableV1[] public activeSigilsList;

    //The mapping (uint256 => bool) of non-DAO hashes used to mint.
    BitMaps.BitMap mintedStandardHashesTokenIds;

    /// @notice SigilActivated Emitted when a Sigil address is activated.
    event SigilActivated(ICollectionNFTCloneableV1 indexed _sigilAddress);

    /// @notice SigilDeactivated Emitted when a Sigil address is deactivated.
    event SigilDeactivated(ICollectionNFTCloneableV1 indexed _sigilAddress);

    /**
     * @notice Constructor for the Sigil Management contract. The ownership is transfered
     *         and the Hashes collection is defined.
     */
    constructor(IHashes _hashesAddress, address _sigilsManagementOwner) {
        transferOwnership(_sigilsManagementOwner);
        hashes = _hashesAddress;
    }

    /**
     * @notice  This predicate function is used to determine the mint fee of a hashes token Id for
     *          a Sigil collection. It will always returns a value of 0.
     * @param _tokenId The token Id of the associated hashes collection contract.
     * @param _hashesTokenId The Hashes token Id being used to mint.
     *
     * @return The uint256 result of the mint fee.
     */
    function getTokenMintFee(uint256 _tokenId, uint256 _hashesTokenId) external view override returns (uint256) {
        return 0;
    }

    /**
     * @notice  This predicate function is used to determine the mint eligibility of a hashes token Id for
     *          a Sigil collection. In order to do this the function first checks if the collection is an active Sigil
     *          collection. If it is not, then minting is prohibited. If it is, then it checks if the hashes token Id
     *          is a DAO hash or a non-DAO hash. All DAO hashes are eligible to mint from any active Sigil collection.
     *          Non-DAO hashes, however, are only eligible to mint a single Sigil NFT ever. Thus, if the hashes token
     *          Id represents a non-DAO hash the function then checks if it has ever been used to mint another Sigil
     *          NFT, and if it hasn't, it is eligible to mint.
     * @param _tokenId The token Id of the associated hashes collection contract.
     * @param _hashesTokenId The Hashes token Id being used to mint.
     *
     * @return The boolean result of the validation.
     */
    function isTokenEligibleToMint(uint256 _tokenId, uint256 _hashesTokenId) external view override returns (bool) {
        if (!activeSigils[ICollectionNFTCloneableV1(msg.sender)]) {
            return false;
        }

        if (_hashesTokenId < hashes.governanceCap()) {
            return true;
        }

        //If non-DAO hash has already been used then return false
        if (BitMaps.get(mintedStandardHashesTokenIds, _hashesTokenId)) {
            return false;
        }

        //Iterates over sigil list array to check if the non-DAO hash has been used before; if yes return false
        for (uint256 i = 0; i < activeSigilsList.length; i++) {
            if (getMappingExists(_hashesTokenId, activeSigilsList[i])) {
                return false;
            }
        }

        return true;
    }

    /**
     * @notice This function allows the Sigil Management contract owner to activate an array of
     *         ICollectionNFTCloneableV1 Sigil contract addresses.
     * @param _addresses An array of inactive ICollectionNFTCloneableV1 Sigil addresses.
     */
    function activateSigils(ICollectionNFTCloneableV1[] memory _addresses) public onlyOwner {
        require(_addresses.length > 0, "SigilManagement: no Sigil addresses provided.");

        for (uint256 j = 0; j < _addresses.length; j++) {
            require(!activeSigils[_addresses[j]], "SigilManagement: Sigil address already exists.");

            activeSigilsList.push(ICollectionNFTCloneableV1(_addresses[j]));

            activeSigils[_addresses[j]] = true;

            emit SigilActivated(_addresses[j]);
        }
    }

    /**
     * @notice This function allows the Sigil Management contract owner to deactivate an array of
     *         ICollectionNFTCloneableV1 Sigil contract addresses. In order to do this the Sigils
     *         Management contract owner must also provide, in addition to an array of
     *         ICollectionNFTCloneableV1 addresses, an array of arrays of hashes token Ids that have
     *         been used to mint a Sigil in the corresponding collection. The hashes token Ids must be
     *         provided in a monotonically increasing order.
     * @param _addresses An array of active ICollectionNFTCloneableV1 Sigil addresses.
     * @param _hashesIds An array of arrays of hashes token Ids that have minted Sigil NFTS. Each array
     *         of hashes token Ids must correspond to the ICollectionNFTCloneableV1 Sigil address.
     */
    function deactivateSigils(ICollectionNFTCloneableV1[] memory _addresses, uint256[][] memory _hashesIds)
        public
        onlyOwner
    {
        require(_addresses.length > 0, "SigilManagement: no Sigil addresses provided.");

        require(
            _addresses.length == _hashesIds.length,
            "SigilManagement: number of addresses not equal to the number of hashesIds arrays."
        );

        for (uint256 j = 0; j < _addresses.length; j++) {
            require(activeSigils[_addresses[j]], "SigilManagement: Sigil address doesn't exist.");

            require(
                ICollectionNFTCloneableV1(_addresses[j]).nonce() == _hashesIds[j].length,
                "SigilManagement: minted Sigils not equal to the number of hashes ids provided."
            );

            for (uint256 k = 0; k < _hashesIds[j].length; k++) {
                if (k > 0) {
                    require(
                        _hashesIds[j][k - 1] < _hashesIds[j][k],
                        "SigilManagement: hashes ids array provided is not monotonically increasing."
                    );
                }

                //Checks if the _hashes id has been used to mint a sigil and if it's a non-DAO hash
                if (
                    getMappingExists(_hashesIds[j][k], ICollectionNFTCloneableV1(_addresses[j])) &&
                    (_hashesIds[j][k] > hashes.governanceCap())
                ) {
                    //If yes, then add the mapping to mintedStandardHashesTokenIds BitMap
                    BitMaps.set(mintedStandardHashesTokenIds, _hashesIds[j][k]);
                }
            }

            //Then iterates over the activeSigilsList array and deletes the relevant entry
            for (uint256 l = 0; l < activeSigilsList.length; l++) {
                if (activeSigilsList[l] == ICollectionNFTCloneableV1(_addresses[j])) {
                    activeSigilsList[l] = activeSigilsList[(activeSigilsList.length - 1)];

                    activeSigilsList.pop();
                }
            }

            delete activeSigils[_addresses[j]];

            emit SigilDeactivated(_addresses[j]);
        }
    }

    function getMappingExists(uint256 _hashesID, ICollectionNFTCloneableV1 _address) private view returns (bool) {
        (bool exists, ) = _address.hashesIdToCollectionTokenIdMapping(_hashesID);
        return exists;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Library for managing uint256 to bool mapping in a compact and efficient way, providing the keys are sequential.
 * Largelly inspired by Uniswap's https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol[merkle-distributor].
 */
library BitMaps {
    struct BitMap {
        mapping(uint256 => uint256) _data;
    }

    /**
     * @dev Returns whether the bit at `index` is set.
     */
    function get(BitMap storage bitmap, uint256 index) internal view returns (bool) {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        return bitmap._data[bucket] & mask != 0;
    }

    /**
     * @dev Sets the bit at `index` to the boolean `value`.
     */
    function setTo(
        BitMap storage bitmap,
        uint256 index,
        bool value
    ) internal {
        if (value) {
            set(bitmap, index);
        } else {
            unset(bitmap, index);
        }
    }

    /**
     * @dev Sets the bit at `index`.
     */
    function set(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] |= mask;
    }

    /**
     * @dev Unsets the bit at `index`.
     */
    function unset(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] &= ~mask;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import { IERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IHashes is IERC721Enumerable {
    function deactivateTokens(
        address _owner,
        uint256 _proposalId,
        bytes memory _signature
    ) external returns (uint256);

    function deactivated(uint256 _tokenId) external view returns (bool);

    function activationFee() external view returns (uint256);

    function verify(
        uint256 _tokenId,
        address _minter,
        string memory _phrase
    ) external view returns (bool);

    function getHash(uint256 _tokenId) external view returns (bytes32);

    function getPriorVotes(address account, uint256 blockNumber) external view returns (uint256);

    function governanceCap() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface ICollectionNFTEligibilityPredicate {
    function isTokenEligibleToMint(uint256 _tokenId, uint256 _hashesTokenId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface ICollectionNFTMintFeePredicate {
    function getTokenMintFee(uint256 _tokenId, uint256 _hashesTokenId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface ICollectionNFTCloneableV1 {
    function mint(uint256 _hashesTokenId) external payable;

    function burn(uint256 _tokenId) external;

    function completeSignatureBlock() external;

    function setBaseTokenURI(string memory _baseTokenURI) external;

    function setRoyaltyBps(uint16 _royaltyBps) external;

    function transferCreator(address _creatorAddress) external;

    function setSignatureBlockAddress(address _signatureBlockAddress) external;

    function withdraw() external;

    function hashesIdToCollectionTokenIdMapping(uint256 _hashesTokenId)
        external
        view
        returns (bool exists, uint128 tokenId);

    function nonce() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT

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