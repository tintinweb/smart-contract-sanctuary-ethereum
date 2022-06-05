// SPDX-License-Identifier: MIT
/* solhint-disable quotes */
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Interfaces.sol";
import "./AnonymiceLibrary.sol";
import "./RedactedLibrary.sol";
import "./IAnonymiceBreeding.sol";

contract DNAChipDescriptor is Ownable {
    address public dnaChipAddress;
    address public evolutionTraitsAddress;
    address public breedingAddress;

    uint8 public constant BASE_INDEX = 0;
    uint8 public constant EARRINGS_INDEX = 1;
    uint8 public constant EYES_INDEX = 2;
    uint8 public constant HATS_INDEX = 3;
    uint8 public constant MOUTHS_INDEX = 4;
    uint8 public constant NECKS_INDEX = 5;
    uint8 public constant NOSES_INDEX = 6;
    uint8 public constant WHISKERS_INDEX = 7;

    constructor() {}

    function setAddresses(
        address _dnaChipAddress,
        address _evolutionTraitsAddress,
        address _breedingAddress
    ) external onlyOwner {
        dnaChipAddress = _dnaChipAddress;
        evolutionTraitsAddress = _evolutionTraitsAddress;
        breedingAddress = _breedingAddress;
    }

    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        uint8[8] memory traits = RedactedLibrary.representationToTraitsArray(
            IDNAChip(dnaChipAddress).tokenIdToTraits(_tokenId)
        );
        bool isEvolutionPod = IDNAChip(dnaChipAddress).isEvolutionPod(_tokenId);
        string memory name;
        string memory image;
        if (!isEvolutionPod) {
            name = string(abi.encodePacked('{"name": "DNA Chip #', AnonymiceLibrary.toString(_tokenId)));
            image = AnonymiceLibrary.encode(bytes(getChipSVG(traits)));
        } else {
            name = string(abi.encodePacked('{"name": "Evolution Pod #', AnonymiceLibrary.toString(_tokenId)));
            image = AnonymiceLibrary.encode(bytes(getEvolutionPodSVG(traits)));
        }

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    AnonymiceLibrary.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    name,
                                    '", "image": "data:image/svg+xml;base64,',
                                    image,
                                    '","attributes": [',
                                    IEvolutionTraits(evolutionTraitsAddress).getMetadata(traits),
                                    ', {"trait_type" :"Assembled", "value" : "',
                                    isEvolutionPod ? "Yes" : "No",
                                    '"}',
                                    "]",
                                    ', "description": "DNA Chips is a collection of 3,550 DNA Chips. All the metadata and images are generated and stored 100% on-chain. No IPFS, no API. Just the Ethereum blockchain."',
                                    "}"
                                )
                            )
                        )
                    )
                )
            );
    }

    function tokenBreedingURI(uint256 _tokenId, uint256 _breedingId) public view returns (string memory) {
        uint256 traitsRepresentation = IDNAChip(dnaChipAddress).tokenIdToTraits(_tokenId);
        uint8[8] memory traits = RedactedLibrary.representationToTraitsArray(traitsRepresentation);
        string memory name = string(abi.encodePacked('{"name": "Baby Mouse #', AnonymiceLibrary.toString(_breedingId)));
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    AnonymiceLibrary.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    name,
                                    '", "image": "data:image/svg+xml;base64,',
                                    AnonymiceLibrary.encode(bytes(getBreedingSVG(traits))),
                                    '","attributes": [',
                                    IEvolutionTraits(evolutionTraitsAddress).getMetadata(traits),
                                    "]",
                                    ', "description": "Anonymice Breeding is a collection of 3,550 baby mice. All the metadata and images are generated and stored 100% on-chain. No IPFS, no API. Just the Ethereum blockchain."',
                                    "}"
                                )
                            )
                        )
                    )
                )
            );
    }

    function tokenIncubatorURI(uint256 _breedingId) public view returns (string memory) {
        string memory name = string(
            abi.encodePacked('{"name": "Evolved Incubator #', AnonymiceLibrary.toString(_breedingId))
        );
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    AnonymiceLibrary.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    name,
                                    '", "image": "data:image/svg+xml;base64,',
                                    AnonymiceLibrary.encode(bytes(getEvolvedIncubatorSVG())),
                                    '","attributes":',
                                    evolvedIncubatorIdToAttributes(_breedingId),
                                    ', "description": "Anonymice Breeding is a collection of 3,550 baby mice. All the metadata and images are generated and stored 100% on-chain. No IPFS, no API. Just the Ethereum blockchain."',
                                    "}"
                                )
                            )
                        )
                    )
                )
            );
    }

    function evolvedIncubatorIdToAttributes(uint256 _breedingId) public view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '[{"trait_type": "Parent #1 ID", "value": "',
                    AnonymiceLibrary.toString(
                        IAnonymiceBreeding(breedingAddress)._tokenToIncubator(_breedingId).parentId1
                    ),
                    '"},{"trait_type": "Parent #2 ID", "value": "',
                    AnonymiceLibrary.toString(
                        IAnonymiceBreeding(breedingAddress)._tokenToIncubator(_breedingId).parentId2
                    ),
                    '"}, {"trait_type" :"revealed","value" : "Not Revealed Evolution"}]'
                )
            );
    }

    function getChipSVG(uint8[8] memory traits) internal view returns (string memory) {
        string memory imageTag = IEvolutionTraits(evolutionTraitsAddress).getDNAChipSVG(traits[0]);
        return
            string(
                abi.encodePacked(
                    '<svg id="dna-chip" width="100%" height="100%" version="1.1" viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
                    imageTag,
                    '<g transform="translate(43, 33) scale(1.5)">',
                    IEvolutionTraits(evolutionTraitsAddress).getTraitsImageTagsByOrder(
                        traits,
                        [
                            BASE_INDEX,
                            NECKS_INDEX,
                            MOUTHS_INDEX,
                            NOSES_INDEX,
                            WHISKERS_INDEX,
                            EYES_INDEX,
                            EARRINGS_INDEX,
                            HATS_INDEX
                        ]
                    ),
                    "</g>",
                    "</svg>"
                )
            );
    }

    function getEvolutionPodSVG(uint8[8] memory traits) public view returns (string memory) {
        uint8 base = traits[0];
        string memory preview;
        if (base == 0) {
            // FREAK
            preview = '<g transform="translate(75,69)">';
        } else if (base == 1) {
            // ROBOT
            preview = '<g transform="translate(85,74)">';
        } else if (base == 2) {
            // DRUID
            preview = '<g transform="translate(70,80)">';
        } else if (base == 3) {
            // SKELE
            preview = '<g transform="translate(19,56)">';
        } else if (base == 4) {
            // ALIEN
            preview = '<g transform="translate(75,58)">';
        }
        preview = string(
            abi.encodePacked(
                preview,
                IEvolutionTraits(evolutionTraitsAddress).getTraitsImageTagsByOrder(
                    traits,
                    [
                        BASE_INDEX,
                        NECKS_INDEX,
                        MOUTHS_INDEX,
                        NOSES_INDEX,
                        WHISKERS_INDEX,
                        EYES_INDEX,
                        EARRINGS_INDEX,
                        HATS_INDEX
                    ]
                ),
                "</g>"
            )
        );

        string
            memory result = '<svg id="evolution-pod" width="100%" height="100%" version="1.1" viewBox="0 0 125 125" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">';

        result = string(
            abi.encodePacked(
                result,
                IEvolutionTraits(evolutionTraitsAddress).getEvolutionPodImageTag(base),
                preview,
                "</svg>"
            )
        );
        return result;
    }

    function getBreedingSVG(uint8[8] memory traits) public view returns (string memory) {
        string
            memory result = '<svg id="ebaby" width="100%" height="100%" version="1.1" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">';

        result = string(
            abi.encodePacked(
                result,
                IEvolutionTraits(evolutionTraitsAddress).getTraitsImageTagsByOrder(
                    traits,
                    [
                        BASE_INDEX,
                        NECKS_INDEX,
                        MOUTHS_INDEX,
                        NOSES_INDEX,
                        WHISKERS_INDEX,
                        EYES_INDEX,
                        EARRINGS_INDEX,
                        HATS_INDEX
                    ]
                ),
                "</svg>"
            )
        );
        return result;
    }

    function getEvolvedIncubatorSVG() public view returns (string memory) {
        string
            memory result = '<svg id="eincubator" width="100%" height="100%" version="1.1" viewBox="0 0 52 52" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">';

        result = string(
            abi.encodePacked(result, IEvolutionTraits(evolutionTraitsAddress).evolvedIncubatorImage(), "</svg>")
        );
        return result;
    }
}

/* solhint-enable quotes */

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface RewardLike {
    function mintMany(address to, uint256 amount) external;
}

interface IDNAChip is RewardLike {
    function tokenIdToTraits(uint256 tokenId) external view returns (uint256);

    function isEvolutionPod(uint256 tokenId) external view returns (bool);

    function breedingIdToEvolutionPod(uint256 tokenId) external view returns (uint256);
}

interface IDescriptor {
    function tokenURI(uint256 _tokenId) external view returns (string memory);

    function tokenBreedingURI(uint256 _tokenId, uint256 _breedingId) external view returns (string memory);

    function tokenIncubatorURI(uint256 _breedingId) external view returns (string memory);
}

interface IEvolutionTraits {
    function getDNAChipSVG(uint256 base) external view returns (string memory);

    function getEvolutionPodImageTag(uint256 base) external view returns (string memory);

    function getTraitsImageTags(uint8[8] memory traits) external view returns (string memory);

    function getTraitsImageTagsByOrder(uint8[8] memory traits, uint8[8] memory traitsOrder)
        external
        view
        returns (string memory);

    function getMetadata(uint8[8] memory traits) external view returns (string memory);

    function evolvedIncubatorImage() external view returns (string memory);
}

interface IERC721Like {
    function transferFrom(
        address from,
        address to,
        uint256 id
    ) external;

    function transfer(address to, uint256 id) external;

    function ownerOf(uint256 id) external returns (address owner);

    function mint(address to, uint256 tokenid) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library AnonymiceLibrary {
    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function parseInt(string memory _a)
        internal
        pure
        returns (uint8 _parsedInt)
    {
        bytes memory bresult = bytes(_a);
        uint8 mint = 0;
        for (uint8 i = 0; i < bresult.length; i++) {
            if (
                (uint8(uint8(bresult[i])) >= 48) &&
                (uint8(uint8(bresult[i])) <= 57)
            ) {
                mint *= 10;
                mint += uint8(bresult[i]) - 48;
            }
        }
        return mint;
    }

    function substring(
        string memory str,
        uint256 startIndex,
        uint256 endIndex
    ) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

library RedactedLibrary {
    struct Traits {
        uint256 base;
        uint256 earrings;
        uint256 eyes;
        uint256 hats;
        uint256 mouths;
        uint256 necks;
        uint256 noses;
        uint256 whiskers;
    }

    struct TightTraits {
        uint8 base;
        uint8 earrings;
        uint8 eyes;
        uint8 hats;
        uint8 mouths;
        uint8 necks;
        uint8 noses;
        uint8 whiskers;
    }

    function traitsToRepresentation(Traits memory traits) internal pure returns (uint256) {
        uint256 representation = uint256(traits.base);
        representation |= traits.earrings << 8;
        representation |= traits.eyes << 16;
        representation |= traits.hats << 24;
        representation |= traits.mouths << 32;
        representation |= traits.necks << 40;
        representation |= traits.noses << 48;
        representation |= traits.whiskers << 56;

        return representation;
    }

    function representationToTraits(uint256 representation) internal pure returns (Traits memory traits) {
        traits.base = uint8(representation);
        traits.earrings = uint8(representation >> 8);
        traits.eyes = uint8(representation >> 16);
        traits.hats = uint8(representation >> 24);
        traits.mouths = uint8(representation >> 32);
        traits.necks = uint8(representation >> 40);
        traits.noses = uint8(representation >> 48);
        traits.whiskers = uint8(representation >> 56);
    }

    function representationToTraitsArray(uint256 representation) internal pure returns (uint8[8] memory traitsArray) {
        traitsArray[0] = uint8(representation); // base
        traitsArray[1] = uint8(representation >> 8); // earrings
        traitsArray[2] = uint8(representation >> 16); // eyes
        traitsArray[3] = uint8(representation >> 24); // hats
        traitsArray[4] = uint8(representation >> 32); // mouths
        traitsArray[5] = uint8(representation >> 40); // necks
        traitsArray[6] = uint8(representation >> 48); // noses
        traitsArray[7] = uint8(representation >> 56); // whiskers
    }
}

// SPDX-License-Identifier: MIT

/*
Copyright 2021 Anonymice

Licensed under the Anonymice License, Version 1.0 (the “License”); you may not use this code except in compliance with the License.
You may obtain a copy of the License at https://doz7mjeufimufl7fa576j6kq5aijrwezk7tvdgvzrfr3d6njqwea.arweave.net/G7P2JJQqGUKv5Qd_5PlQ6BCY2JlX51GauYljsfmphYg

Unless required by applicable law or agreed to in writing, code distributed under the License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and limitations under the License.
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IAnonymiceBreeding is IERC721Enumerable {
    struct Incubator {
        uint256 parentId1;
        uint256 parentId2;
        uint256 childId;
        uint256 revealBlock;
    }

    function _tokenIdToLegendary(uint256 _tokenId) external view returns (bool);

    function _tokenIdToLegendaryNumber(uint256 _tokenId)
        external
        view
        returns (uint8);

    function _tokenToRevealed(uint256 _tokenId) external view returns (bool);

    function _tokenIdToHash(uint256 _tokenId)
        external
        view
        returns (string memory);

    function _tokenToIncubator(uint256 _tokenId)
        external
        view
        returns (Incubator memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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