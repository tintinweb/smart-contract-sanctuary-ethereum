// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
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

pragma solidity 0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IMonsuta} from "./interfaces/IMonsuta.sol";

contract MonsutaRegistry is Ownable {
    struct Trait {
        string scene;
        string species;
        string skin;
        string eyes;
        string mouth;
        string markings;
        string ritual;
    }

    // Public variables

    bytes4[] public traitBytes;

    // Public constants
    uint256 public constant MAX_MONSUTA_SUPPLY = 8888;

    address public immutable monsutaAddress;
    uint256 public startingIndexFromMonsutaContract;

    /**
     * @dev Initializes the contract
     */
    constructor(address monsuta) {
        require(Address.isContract(monsuta), "!contract");
        monsutaAddress = monsuta;
    }

    /*
     * Store Metadata comprising of IPFS Hashes (In Hexadecimal minus the first two fixed bytes) and explicit traits
     * Ordered according to original hashed sequence pertaining to the Hashmonsutas provenance
     * Ownership is intended to be burned (Renounced) after storage is completed
     */
    function storeMetadata(bytes4[] memory traitsHex) public onlyOwner {
        storeMetadataStartingAtIndex(traitBytes.length, traitsHex);
    }

    /*
     * Store metadata starting at a particular index. In case any corrections are required before completion
     */
    function storeMetadataStartingAtIndex(
        uint256 startIndex,
        bytes4[] memory traitsHex
    ) public onlyOwner {
        require(startIndex <= traitBytes.length, "bad length");

        for (uint256 i; i < traitsHex.length; ) {
            if ((i + startIndex) >= traitBytes.length) {
                traitBytes.push(traitsHex[i]);
            } else {
                traitBytes[i + startIndex] = traitsHex[i];
            }

            unchecked {
                ++i;
            }
        }

        // Post-assertions
        require(traitBytes.length <= MAX_MONSUTA_SUPPLY, ">max");
    }

    function reveal() external onlyOwner {
        require(startingIndexFromMonsutaContract == 0, "already did");

        IMonsuta monsuta = IMonsuta(monsutaAddress);
        uint256 startingIndex = monsuta.startingIndex();

        require(startingIndex != 0, "not revealed yet");

        startingIndexFromMonsutaContract = startingIndex;
    }

    /*
     * Returns the trait bytes for the Hashmonsuta image at specified position in the original hashed sequence
     */
    function getTraitBytesAtIndex(uint256 index) public view returns (bytes4) {
        require(
            index < traitBytes.length,
            "Metadata does not exist for the specified index"
        );
        return traitBytes[index];
    }

    function getTraitsOfMonsutaId(uint256 monsutaId)
        public
        view
        returns (Trait memory trait)
    {
        require(
            monsutaId < MAX_MONSUTA_SUPPLY,
            "Monsuta ID must be less than max"
        );

        // Derives the index of the image in the original sequence assigned to the Monsuta ID
        uint256 correspondingOriginalSequenceIndex = (monsutaId +
            startingIndexFromMonsutaContract) % MAX_MONSUTA_SUPPLY;

        bytes4 _traitBytes = getTraitBytesAtIndex(
            correspondingOriginalSequenceIndex
        );

        return
            Trait(
                _extractSceneTrait(_traitBytes),
                _extractSpeciesTrait(_traitBytes),
                _extractSkinTrait(_traitBytes),
                _extractEyesTrait(_traitBytes),
                _extractMouthTrait(_traitBytes),
                _extractMarkingsTrait(_traitBytes),
                _extractRitualTrait(_traitBytes)
            );
    }

    function getEncodedTraitsOfMonsutaId(uint256 monsutaId, uint256 state)
        public
        view
        returns (bytes memory traits)
    {
        Trait memory trait = getTraitsOfMonsutaId(monsutaId);

        return
            bytes.concat(
                abi.encodePacked(
                    '"attributes": [{ "trait_type": "Scene", "value": "',
                    trait.scene,
                    '"}, { "trait_type": "Species", "value": "',
                    trait.species,
                    '"}, { "trait_type": "Skin", "value": "',
                    trait.skin,
                    '"}, { "trait_type": "Eyes", "value": "',
                    trait.eyes
                ),
                abi.encodePacked(
                    '"}, { "trait_type": "Mouth", "value": "',
                    trait.mouth,
                    '"}, { "trait_type": "Markings", "value": "',
                    trait.markings,
                    '"}, { "trait_type": "Ritual", "value": "',
                    trait.ritual,
                    '"}, { "trait_type": "Version", "value": "',
                    state == 2
                        ? "Soul Monsuta"
                        : (state == 1 ? "Evolved Monsuta" : "Monsuta"),
                    '"}]'
                )
            );
    }

    function _extractSceneTrait(bytes4 _traitBytes)
        internal
        pure
        returns (string memory scene)
    {
        bytes1 sceneBits = _traitBytes[0] & 0x0F;

        if (sceneBits == 0x00) {
            scene = "Lonely";
        } else if (sceneBits == 0x01) {
            scene = "Somber Thoughts";
        } else if (sceneBits == 0x02) {
            scene = "Vertigo";
        } else if (sceneBits == 0x03) {
            scene = "Phantasm";
        } else if (sceneBits == 0x04) {
            scene = "Hell 666";
        } else if (sceneBits == 0x05) {
            scene = "Forsaken Fields";
        } else if (sceneBits == 0x06) {
            scene = "Empty Fields";
        } else if (sceneBits == 0x07) {
            scene = "Silent Hill";
        } else if (sceneBits == 0x08) {
            scene = "Limbo";
        } else if (sceneBits == 0x09) {
            scene = "Fallen";
        } else if (sceneBits == 0x0A) {
            scene = "Empty Within";
        } else if (sceneBits == 0x0B) {
            scene = "Forbidden Forest";
        } else if (sceneBits == 0x0C) {
            scene = "Desolate Souls";
        } else if (sceneBits == 0x0D) {
            scene = "Dante's Rest";
        } else if (sceneBits == 0x0E) {
            scene = "Cold Rest";
        } else if (sceneBits == 0x0F) {
            scene = "Forbidden City";
        }
    }

    function _extractSpeciesTrait(bytes4 _traitBytes)
        internal
        pure
        returns (string memory species)
    {
        bytes1 speciesBits = _traitBytes[0] >> 4;

        if (speciesBits == 0x00) {
            species = "Chaos";
        } else if (speciesBits == 0x01) {
            species = "Shadow";
        } else if (speciesBits == 0x02) {
            species = "Dread";
        } else if (speciesBits == 0x03) {
            species = "Ghost";
        } else if (speciesBits == 0x04) {
            species = "Sinner";
        } else if (speciesBits == 0x05) {
            species = "Wraith";
        } else if (speciesBits == 0x06) {
            species = "Ghoul";
        } else {
            species = "None";
        }
    }

    function _extractSkinTrait(bytes4 _traitBytes)
        internal
        pure
        returns (string memory skin)
    {
        bytes1 skinBits = _traitBytes[1] & 0x0F;

        if (skinBits == 0x00) {
            skin = "Darkness";
        } else if (skinBits == 0x01) {
            skin = "Toxic";
        } else if (skinBits == 0x02) {
            skin = "Heartless";
        } else if (skinBits == 0x03) {
            skin = "Dead Stars";
        } else if (skinBits == 0x04) {
            skin = "Inferno";
        } else if (skinBits == 0x05) {
            skin = "Serpent";
        } else if (skinBits == 0x06) {
            skin = "Prism";
        } else if (skinBits == 0x07) {
            skin = "Firestorm";
        } else if (skinBits == 0x08) {
            skin = "Cursed";
        } else if (skinBits == 0x09) {
            skin = "Galactic";
        } else if (skinBits == 0x0A) {
            skin = "Spark";
        } else if (skinBits == 0x0B) {
            skin = "Dreamcast";
        } else if (skinBits == 0x0C) {
            skin = "Blazed";
        } else if (skinBits == 0x0D) {
            skin = "Cyanide";
        } else if (skinBits == 0x0E) {
            skin = "Bones";
        } else if (skinBits == 0x0F) {
            skin = "Resin";
        }
    }

    function _extractEyesTrait(bytes4 _traitBytes)
        internal
        pure
        returns (string memory eyes)
    {
        bytes1 eyesBits = _traitBytes[1] >> 4;

        if (eyesBits == 0x00) {
            eyes = "Grief";
        } else if (eyesBits == 0x01) {
            eyes = "Depraved";
        } else if (eyesBits == 0x02) {
            eyes = "Terror";
        } else if (eyesBits == 0x03) {
            eyes = "Shadowy";
        } else if (eyesBits == 0x04) {
            eyes = "Joyless";
        } else if (eyesBits == 0x05) {
            eyes = "Grim";
        } else if (eyesBits == 0x06) {
            eyes = "Wicked";
        } else if (eyesBits == 0x07) {
            eyes = "Omen";
        } else if (eyesBits == 0x08) {
            eyes = "Funeral";
        } else if (eyesBits == 0x09) {
            eyes = "Deep";
        } else if (eyesBits == 0x0A) {
            eyes = "Panic";
        } else if (eyesBits == 0x0B) {
            eyes = "Doomy";
        } else if (eyesBits == 0x0C) {
            eyes = "Chilled";
        } else if (eyesBits == 0x0D) {
            eyes = "Dimension";
        } else if (eyesBits == 0x0E) {
            eyes = "Spooky";
        } else if (eyesBits == 0x0F) {
            eyes = "Stormy";
        }
    }

    function _extractMouthTrait(bytes4 _traitBytes)
        internal
        pure
        returns (string memory mouth)
    {
        bytes1 mouthBits = _traitBytes[2] & 0x0F;

        if (mouthBits == 0x00) {
            mouth = "Chomper";
        } else if (mouthBits == 0x01) {
            mouth = "Insidious";
        } else if (mouthBits == 0x02) {
            mouth = "Chainsaw";
        } else if (mouthBits == 0x03) {
            mouth = "Stitches";
        } else if (mouthBits == 0x04) {
            mouth = "Thing";
        } else if (mouthBits == 0x05) {
            mouth = "Stranger";
        } else if (mouthBits == 0x06) {
            mouth = "Slasher";
        } else if (mouthBits == 0x07) {
            mouth = "Psycho";
        } else if (mouthBits == 0x08) {
            mouth = "Prodigy";
        } else if (mouthBits == 0x09) {
            mouth = "Myth";
        } else if (mouthBits == 0x0A) {
            mouth = "Maniac";
        } else if (mouthBits == 0x0B) {
            mouth = "Awakened";
        } else if (mouthBits == 0x0C) {
            mouth = "Hunter";
        } else if (mouthBits == 0x0D) {
            mouth = "Lost";
        } else if (mouthBits == 0x0E) {
            mouth = "Horror";
        } else if (mouthBits == 0x0F) {
            mouth = "Morgue";
        }
    }

    function _extractMarkingsTrait(bytes4 _traitBytes)
        internal
        pure
        returns (string memory markings)
    {
        bytes1 markingsBits = _traitBytes[2] >> 4;

        if (markingsBits == 0x00) {
            markings = "Spider";
        } else if (markingsBits == 0x01) {
            markings = "Monkey";
        } else if (markingsBits == 0x02) {
            markings = "Lizard";
        } else if (markingsBits == 0x03) {
            markings = "Wolf";
        } else if (markingsBits == 0x04) {
            markings = "Rat";
        } else if (markingsBits == 0x05) {
            markings = "Owl";
        } else if (markingsBits == 0x06) {
            markings = "Koi";
        } else if (markingsBits == 0x07) {
            markings = "Frog";
        } else if (markingsBits == 0x08) {
            markings = "Cat";
        } else if (markingsBits == 0x09) {
            markings = "Moth";
        } else if (markingsBits == 0x0A) {
            markings = "Demon";
        } else if (markingsBits == 0x0B) {
            markings = "Butterfly";
        } else if (markingsBits == 0x0C) {
            markings = "Scorpion";
        } else if (markingsBits == 0x0D) {
            markings = "Monster";
        } else if (markingsBits == 0x0E) {
            markings = "Bat";
        } else if (markingsBits == 0x0F) {
            markings = "Rabbit";
        }
    }

    function _extractRitualTrait(bytes4 _traitBytes)
        internal
        pure
        returns (string memory ritual)
    {
        bytes1 ritualBits = _traitBytes[3] & 0x0F;

        if (ritualBits == 0x00) {
            ritual = "Untrue";
        } else if (ritualBits == 0x01) {
            ritual = "Unrest";
        } else if (ritualBits == 0x02) {
            ritual = "Grimoire";
        } else if (ritualBits == 0x03) {
            ritual = "Blind";
        } else if (ritualBits == 0x04) {
            ritual = "Secrets";
        } else if (ritualBits == 0x05) {
            ritual = "Hypnosis";
        } else if (ritualBits == 0x06) {
            ritual = "Memory";
        } else if (ritualBits == 0x07) {
            ritual = "Rouge";
        } else if (ritualBits == 0x08) {
            ritual = "Mana";
        } else if (ritualBits == 0x09) {
            ritual = "Trespass";
        } else if (ritualBits == 0x0A) {
            ritual = "Shaman";
        } else if (ritualBits == 0x0B) {
            ritual = "Evoke";
        } else if (ritualBits == 0x0C) {
            ritual = "Emotion";
        } else if (ritualBits == 0x0D) {
            ritual = "Le Dragon";
        } else if (ritualBits == 0x0E) {
            ritual = "Demonic";
        } else if (ritualBits == 0x0F) {
            ritual = "Neo";
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IMonsuta {
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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);

    function startingIndex() external view returns (uint256);

    function startingIndexBlock() external view returns (uint256);

    function MAX_NFT_SUPPLY() external view returns (uint256);

    function getTokenState(uint256 tokenId) external view returns (uint256);

    function changeName(uint256 tokenId, string memory newName) external;

    function ascent(uint256 tokenId, address owner) external;

    function descent(uint256 tokenId, address owner) external;

    function evolve(
        uint256 tokenId,
        uint256 potionId,
        address owner
    ) external;

    function retract(uint256 tokenId, address owner) external;

    function resurrection(
        uint256 evolvedTokenId,
        uint256 soulTokenId,
        address owner
    ) external;
}