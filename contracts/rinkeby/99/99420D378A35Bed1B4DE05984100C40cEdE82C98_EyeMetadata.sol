/* --------------------------------- ******* ----------------------------------- 
                                       THE

                            ███████╗██╗   ██╗███████╗
                            ██╔════╝╚██╗ ██╔╝██╔════╝
                            █████╗   ╚████╔╝ █████╗  
                            ██╔══╝    ╚██╔╝  ██╔══╝  
                            ███████╗   ██║   ███████╗
                            ╚══════╝   ╚═╝   ╚══════╝
                                 FOR ADVENTURERS
                                                                                   
                             .-=++=-.........-=++=-                  
                        .:..:++++++=---------=++++++:.:::            
                     .=++++----=++-------------===----++++=.         
                    .+++++=---------------------------=+++++.
                 .:-----==------------------------------------:.     
                =+++=---------------------------------------=+++=    
               +++++=---------------------------------------=++++=   
               ====-------------=================-------------===-   
              -=-------------=======================-------------=-. 
            :+++=----------============ A ============----------=+++:
            ++++++--------======= MAGICAL DEVICE =======---------++++=
            -++=----------============ THAT ============----------=++:
             ------------=========== CONTAINS ==========------------ 
            :++=---------============== AN =============----------=++-
            ++++++--------========== ON-CHAIN =========--------++++++
            :+++=----------========== WORLD ==========----------=+++:
              .==-------------=======================-------------=-  
                -=====----------===================----------======   
               =+++++---------------------------------------++++++   
                =+++-----------------------------------------+++=    
                  .-=----===---------------------------===-----:.     
                      .+++++=---------------------------=+++++.        
                       .=++++----=++-------------++=----++++=:         
                         :::.:++++++=----------++++++:.:::            
                                -=+++-.........-=++=-.                 

                            HTTPS://EYEFORADVENTURERS.COM
   ----------------------------------- ******* ---------------------------------- */

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.8;

import {Base64} from "./lib/Base64.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IEye} from "./interfaces/IEye.sol";
import {IEyeMetadata} from "./interfaces/IEyeMetadata.sol";
import {IEyeDescriptions} from "./interfaces/IEyeDescriptions.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract EyeMetadata is IEyeMetadata, Ownable {
    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                                   CONFIG                                   */
    /* -------------------------------------------------------------------------- */

    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                                   STORAGE                                  */
    /* -------------------------------------------------------------------------- */
    IEye private _eye;
    string public svgURIBase;
    string public animationURIBase;
    address public powerupAddress;
    address public eyeDescriptionsAddress;

    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                               INITIALIZATION                               */
    /* -------------------------------------------------------------------------- */
    constructor(
        address eyeAddress_,
        address eyeDescriptionAddress_,
        address powerupAddress_
    ) {
        _eye = IEye(eyeAddress_);
        eyeDescriptionsAddress = eyeDescriptionAddress_;
        powerupAddress = powerupAddress_;
    }

    /* --------------------------------- ****** --------------------------------- */
    /* -------------------------------------------------------------------------- */
    /*                                    ADMIN                                   */
    /* -------------------------------------------------------------------------- */
    /// @notice Sets the base URI for the token JSON
    /// @param svgBaseURI_ The SVG base URI to set.
    function setSvgBaseURI(string calldata svgBaseURI_) external onlyOwner {
        svgURIBase = svgBaseURI_;
    }

    /// @notice Sets the base URI for the token JSON
    /// @param animationBaseURI_ The animation base URI to set.
    function setAnimationBaseURI(string calldata animationBaseURI_)
        external
        onlyOwner
    {
        animationURIBase = animationBaseURI_;
    }

    /// @notice Sets the descriptions' address
    /// @param newAddress The new descriptions' contract address
    function setDescriptionsAddress(address newAddress) external onlyOwner {
        eyeDescriptionsAddress = newAddress;
    }

    /// @notice Sets the contract address to trigger the powerup
    /// @param newAddress The powerup contract address
    function setPowerupAddress(address newAddress) external onlyOwner {
        powerupAddress = newAddress;
    }

    /* --------------------------------- ****** --------------------------------- */
    /* -------------------------------------------------------------------------- */
    /*                                   PUBLIC                                   */
    /* -------------------------------------------------------------------------- */
    /* solhint-disable quotes */
    /// @notice Gets the TokenURI for a specified Eye given params
    /// @param tokenId The tokenId of the Eye
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    _getMetadataJSON(tokenId)
                )
            );
    }

    /* --------------------------------- ****** --------------------------------- */
    /* -------------------------------------------------------------------------- */
    /*                                  INTERNAL                                  */
    /* -------------------------------------------------------------------------- */

    function _getMetadataJSON(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        return
            Base64.encode(
                abi.encodePacked(
                    _getMetadataHeader(tokenId),
                    _getSvgURL(tokenId),
                    '", "attributes": ',
                    _getAttributes(tokenId),
                    ', "animation_url": "',
                    _getAnimationURL(tokenId),
                    '"}'
                )
            );
    }

    /// @notice Gets the animation URL for a specific tokenID
    function _getAnimationURL(uint256 tokenId)
        internal
        view
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                animationURIBase,
                "/",
                _getFilename(tokenId),
                ".html?",
                _getTraitsParams(tokenId),
                _getCustomCollectionParams(tokenId)
            );
    }

    /// @notice Gets the SVG URL for a specific tokenID
    function _getSvgURL(uint256 tokenId) internal view returns (bytes memory) {
        return abi.encodePacked(svgURIBase, "/", _getFilename(tokenId), ".svg");
    }

    /// @notice Get the NFTs description
    function _getDescription(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        return
            IEyeDescriptions(eyeDescriptionsAddress).getDescription(
                _eye.getGreatness(tokenId),
                _eye.getOrder(tokenId),
                _eye.getAttunement(tokenId),
                _eye.getNamePrefix(tokenId),
                _eye.getNameSuffix(tokenId),
                string(_getAnimationURL(tokenId))
            );
    }

    function _getAttributes(uint256 tokenId)
        internal
        view
        returns (bytes memory)
    {
        bytes memory attributes = abi.encodePacked(
            '[{"trait_type":"Attunement", "value": "',
            _eye.getAttunement(tokenId),
            '"}, {"trait_type":"Order", "value": "',
            _eye.getOrder(tokenId),
            '"}, {"trait_type":"Greatness", "value": ',
            Strings.toString(_eye.getGreatness(tokenId)),
            '}, {"trait_type":"My Collection", "value": ',
            Strings.toString(_eye.getIndividualCuration(tokenId).length),
            '}, {"trait_type":"Curated Collection", "value": ',
            Strings.toString(_eye.getCollectionCuration().length),
            '}, {"trait_type":"Enchantment Prefix", "value": "',
            _eye.getNamePrefix(tokenId),
            '"}'
        );
        attributes = abi.encodePacked(
            attributes,
            ', {"trait_type":"Enchantment Suffix", "value": "',
            _eye.getNameSuffix(tokenId),
            '"}, {"trait_type":"Artifact", "value": "',
            _eye.getArtifactName(),
            '"}, {"trait_type":"Vision", "value": "',
            _eye.getVision(tokenId),
            '"}',
            _confirmERC721Balance(_eye.ownerOf(tokenId), powerupAddress)
                ? ',{"trait_type": "Lootbound", "value": "True"}'
                : "",
            "]"
        );
        return attributes;
    }

    function _getTraitsParams(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "g=",
                    Strings.toString(_eye.getGreatness(tokenId)),
                    "&p=",
                    _eye.getNamePrefix(tokenId),
                    "%20",
                    _eye.getNameSuffix(tokenId),
                    "&s=",
                    _eye.getOrder(tokenId)
                )
            );
    }

    function _getCustomCollectionParams(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        string memory collection = "";
        bytes32[] memory stories = _eye.getIndividualCuration(tokenId);
        for (uint256 i = 0; i < stories.length; i++) {
            collection = string(
                abi.encodePacked(
                    collection,
                    "&e=",
                    Strings.toHexString(uint256(stories[i]))
                )
            );
        }
        return collection;
    }

    /// @notice Returns file name based on tokenId traits: '[powered on]_[light vs dark]_[order]'
    function _getFilename(uint256 tokenId)
        internal
        view
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                _confirmERC721Balance(_eye.ownerOf(tokenId), powerupAddress)
                    ? "1"
                    : "0",
                "_",
                Strings.toString(_eye.getAttunementIndex(tokenId)),
                "_",
                Strings.toString(_eye.getOrderIndex(tokenId)),
                "_",
                Strings.toString(_eye.getConditionIndex(tokenId)),
                "_",
                Strings.toString(_eye.getVisionIndex(tokenId))
            );
    }

    /// @notice confirms the msg.sender is the owner of an ERC721 from another contract
    /// @param owner The owner of the tokenId
    /// @param contractAddress The address of the contract
    function _confirmERC721Balance(address owner, address contractAddress)
        internal
        view
        returns (bool)
    {
        IERC721 token = IERC721(contractAddress);
        return token.balanceOf(owner) > 0;
    }

    /// @notice confirms the msg.sender is the owner of an ERC20 from another contract
    /// @param owner The owner of the tokenId
    /// @param contractAddress The address of the contract
    function _confirmERC20Balance(address owner, address contractAddress)
        internal
        view
        returns (bool)
    {
        IERC20 token = IERC20(contractAddress);
        return token.balanceOf(owner) > 0;
    }

    /* solhint-disable quotes */
    function _getMetadataHeader(uint256 tokenId)
        internal
        view
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                '{"name": "',
                _eye.getName(tokenId),
                '", "description": "',
                _getDescription(tokenId),
                '", "image": "'
            );
    }

    /* solhint-enable */

    // function _toHexString(uint256 value) internal pure returns (string memory) {
    //     if (value == 0) {
    //         return "0x00";
    //     }
    //     uint256 temp = value;
    //     uint256 length = 0;
    //     while (temp != 0) {
    //         length++;
    //         temp >>= 8;
    //     }
    //     return _toHexString(value, length);
    // }

    // function _toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
    //     bytes memory buffer = new bytes(2 * length + 2);
    //     buffer[0] = "0";
    //     buffer[1] = "x";
    //     for (uint256 i = 2 * length + 1; i > 1; --i) {
    //         buffer[i] = _HEX_SYMBOLS[value & 0xf];
    //         value >>= 4;
    //     }
    //     require(value == 0, "Strings: hex length insufficient");
    //     return string(buffer);
    // }
    // function _toString(uint256 value) internal pure returns (string memory) {
    //     // Inspired by OraclizeAPI's implementation - MIT licence
    //     // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

    //     if (value == 0) {
    //         return "0";
    //     }
    //     uint256 temp = value;
    //     uint256 digits;
    //     while (temp != 0) {
    //         digits++;
    //         temp /= 10;
    //     }
    //     bytes memory buffer = new bytes(digits);
    //     while (value != 0) {
    //         digits -= 1;
    //         buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
    //         value /= 10;
    //     }
    //     return string(buffer);
    // }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.8;

import {IERC721AUpgradeable} from "erc721a-upgradeable/contracts/IERC721AUpgradeable.sol";

interface IEye is IERC721AUpgradeable {
    enum Phase {
        INIT,
        ADMIN,
        PREMINT,
        PUBLIC
    }

    struct Story {
        uint16 id;
        bytes32 librariumId;
    }

    function getArtifactName() external view returns (string memory);

    function getCollectionCuration()
        external
        view
        returns (Story[] memory storiesList);

    function getIndividualCuration(uint256 tokenId)
        external
        view
        returns (bytes32[] memory);

    function getAttunement(uint256 tokenId)
        external
        view
        returns (string memory);

    function getOrder(uint256 tokenId) external view returns (string memory);

    function getNamePrefix(uint256 tokenId)
        external
        view
        returns (string memory);

    function getNameSuffix(uint256 tokenId)
        external
        view
        returns (string memory);

    function getVision(uint256 tokenId) external view returns (string memory);

    function getName(uint256 tokenId) external view returns (string memory);

    function getVisionIndex(uint256 tokenId) external view returns (uint256);

    function getConditionIndex(uint256 tokenId) external view returns (uint256);

    function getOrderIndex(uint256 tokenId) external view returns (uint256);

    function getAttunementIndex(uint256 tokenId)
        external
        view
        returns (uint256);

    function getGreatness(uint256 tokenId) external pure returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.8;

import {IEye} from "./IEye.sol";

interface IEyeMetadata {
    error InvalidTokenID();
    error NotEnoughPixelData();

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.8;

interface IEyeDescriptions {
    function getDescription(
        uint256,
        string memory,
        string memory,
        string memory,
        string memory,
        string memory
    ) external pure returns (string memory);
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
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
// ERC721A Contracts v4.2.2
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of ERC721A.
 */
interface IERC721AUpgradeable {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * The caller cannot approve to their own address.
     */
    error ApproveToCaller();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the
     * ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
        uint24 extraData;
    }

    // =============================================================
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in `owner`'s account.
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
     * @dev Safely transfers `tokenId` token from `from` to `to`,
     * checking first that contract recipients are aware of the ERC721 protocol
     * to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move
     * this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
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
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
     * whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
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
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
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
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
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
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);

    // =============================================================
    //                           IERC2309
    // =============================================================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId`
     * (inclusive) is transferred from `from` to `to`, as defined in the
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
     *
     * See {_mintERC2309} for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
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