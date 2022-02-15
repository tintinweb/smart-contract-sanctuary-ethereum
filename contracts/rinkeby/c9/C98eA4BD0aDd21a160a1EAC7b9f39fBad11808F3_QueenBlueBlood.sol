// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {Address} from "Address.sol";
import {Strings} from "Strings.sol";

import {RoyalLibrary} from "RoyalLibrary.sol";
import {IQueenBlueBlood} from "IQueenBlueBlood.sol";
import {IQueenTraits} from "IQueenTraits.sol";
import {BaseContractController} from "BaseContractController.sol";

contract QueenBlueBlood is IQueenBlueBlood, BaseContractController {
    /************************** vCONSTRUCTOR REGION *************************************************** */

    constructor() {
        //set ERC165 pattern
        supportedInterfaces[type(IQueenBlueBlood).interfaceId] = true;

        onImplementation = true;
    }

    /**
     *IN
     *_traitsContract: Traits storage contract to use
     *OUT
     *returns: New QueenE's dna
     */
    function BuildDna(uint256 _queeneId, IQueenTraits _traitsContract)
        public
        view
        onlyEcosystemOrOwner
        returns (RoyalLibrary.sDNA[] memory)
    {
        require(
            _traitsContract.supportsInterface(type(IQueenTraits).interfaceId),
            "Contract does not implement IQueenTraits!"
        );

        uint256[] memory traitsList = _traitsContract.getEnabledTraitsIdList();

        RoyalLibrary.sDNA[] memory dna = new RoyalLibrary.sDNA[](
            traitsList.length
        );
        uint256 number = 0;
        for (uint256 idx = 0; idx < traitsList.length; idx++) {
            uint256 rarityWinner = RarityLottery(
                _queeneId,
                traitsList[idx],
                _traitsContract
            );

            uint256 pseudoRandomNumber = uint256(
                keccak256(
                    abi.encodePacked(
                        blockhash(block.number - 1),
                        _queeneId,
                        traitsList[idx] * number,
                        blockhash(block.difficulty),
                        blockhash(block.timestamp)
                    )
                )
            );

            //uint256 qtty = 10;
            uint256 qtty = _traitsContract.GetArtCount(
                traitsList[idx],
                rarityWinner
            );

            dna[idx] = RoyalLibrary.sDNA({
                traitId: traitsList[idx],
                rarityId: rarityWinner,
                trace: pseudoRandomNumber % qtty
            });

            number += 256;
        }

        return dna;
    }

    /**
     *IN
     *_traitId: trait id pooling from the lottery
     *_traitsContract: Traits storage contract
     *OUT
     *winner: Winner rarity
     */
    function RarityLottery(
        uint256 _queeneId,
        uint256 _traitId,
        IQueenTraits _traitsContract
    ) private view returns (uint256) {
        require(
            _traitsContract.supportsInterface(type(IQueenTraits).interfaceId),
            "Contract does not implement IQueenTraits!"
        );

        uint256 pseudoRandomNumber = uint256(
            keccak256(
                abi.encodePacked(
                    blockhash(block.number - 1),
                    _queeneId,
                    _traitId * 256,
                    blockhash(block.difficulty),
                    blockhash(block.timestamp)
                )
            )
        );

        RoyalLibrary.sRARITY[] memory raritiesList = _traitsContract
            .getRarities(true, _traitId);

        uint256[] memory rarityPool = new uint256[](100);
        uint256 poolIdx = 0;
        uint256 percentageSum = 0;

        for (uint256 idx = 0; idx < raritiesList.length; idx++) {
            percentageSum += raritiesList[idx].percentage;
        }

        for (uint256 idx = 0; idx < raritiesList.length; idx++) {
            for (
                uint256 counter = 1;
                counter <=
                raritiesList[idx].percentage +
                    (idx == 0 ? (100 - percentageSum) : 0);
                counter++
            ) {
                rarityPool[poolIdx++] = raritiesList[idx].id;
            }
        }

        uint256 winner = rarityPool[pseudoRandomNumber % rarityPool.length];
        return winner;
    }

    //TODO: cast dna to blood
    /**
     *IN
     *_dna: dna to produce blood
     *_traitsContract: Traits storage contract
     *OUT
     *returns: QueenE's blood produced from dna
     */
    function ProduceBlueBlood(
        RoyalLibrary.sDNA[] memory _dna,
        IQueenTraits _traitsContract
    ) public view onlyEcosystemOrOwner returns (RoyalLibrary.sBLOOD[] memory) {
        require(
            _traitsContract.supportsInterface(type(IQueenTraits).interfaceId),
            "Contract does not implement IQueenTraits!"
        );

        require(_dna.length > 0, "Can't produce blood without dna!");
        RoyalLibrary.sBLOOD[] memory blood = new RoyalLibrary.sBLOOD[](
            _dna.length
        );

        for (uint256 idx = 0; idx < _dna.length; idx++) {
            RoyalLibrary.sDNA memory gene = _dna[idx];
            RoyalLibrary.sTRAIT memory _trait = _traitsContract.getTrait(
                gene.traitId
            );
            RoyalLibrary.sART memory _art = _traitsContract.GetArt(
                gene.traitId,
                gene.rarityId,
                gene.trace
            );
            RoyalLibrary.sRARITY memory _rarity = _traitsContract.getRarityById(
                gene.rarityId
            );

            blood[idx] = RoyalLibrary.sBLOOD({
                traitId: gene.traitId,
                traitName: _trait.traitName,
                artUri: _art.uri,
                rarityId: gene.rarityId,
                rarityName: _rarity.rarityName
            });
        }

        return blood;
    }

    //TODO: Generate Seed for a new queen
    /**
     *IN
     *_queenId: id da nova queen que receberÃ¡ o seed
     *_traitsContract: Traits storage contract
     *OUT
     *return: QueenE's new seed
     */
    function GenerateSeed(uint256 _queeneId, IQueenTraits _traitsContract)
        external
        view
        onlyEcosystemOrOwner
        returns (RoyalLibrary.sSEED memory)
    {
        require(
            _traitsContract.supportsInterface(type(IQueenTraits).interfaceId),
            "Contract does not implement IQueenTraits!"
        );
        require(_queeneId > 0, "Invalid QueenE id!");

        RoyalLibrary.sDNA[] memory _dna = BuildDna(_queeneId, _traitsContract);
        RoyalLibrary.sBLOOD[] memory _blood = ProduceBlueBlood(
            _dna,
            _traitsContract
        );

        return
            RoyalLibrary.sSEED({
                queeneId: _queeneId,
                blueBlood: _blood,
                dna: _dna
            });
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
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

/// @title A library to hold our Queen's Royal Knowledge

pragma solidity 0.8.11;

library RoyalLibrary {
    struct sTRAIT {
        uint256 id;
        string traitName;
        uint8 enabled; //0 - disabled; 1 - enabled;
    }

    struct sRARITY {
        uint256 id;
        string rarityName;
        uint256 percentage; //1 ~ 100
    }

    struct sART {
        uint256 traitId;
        uint256 rarityId;
        string uri;
    }

    struct sDNA {
        uint256 traitId;
        uint256 rarityId;
        uint256 trace;
    }

    struct sBLOOD {
        uint256 traitId;
        string traitName;
        string artUri;
        uint256 rarityId;
        string rarityName;
    }

    struct sSEED {
        uint256 queeneId;
        sBLOOD[] blueBlood;
        sDNA[] dna;
    }

    address constant burnAddress = 0x0000000000000000000000000000000000000000;
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for Noun Auction Houses

pragma solidity ^0.8.11;

import {IBaseContractController} from "IBaseContractController.sol";
import {RoyalLibrary} from "RoyalLibrary.sol";
import {IQueenTraits} from "IQueenTraits.sol";

interface IQueenBlueBlood is IBaseContractController {
    function BuildDna(uint256 queeneId, IQueenTraits _traitsContract)
        external
        view
        returns (RoyalLibrary.sDNA[] memory dna);

    function ProduceBlueBlood(
        RoyalLibrary.sDNA[] memory dna,
        IQueenTraits _traitsContract
    ) external view returns (RoyalLibrary.sBLOOD[] memory);

    function GenerateSeed(uint256 _queenId, IQueenTraits _traitsContract)
        external
        view
        returns (RoyalLibrary.sSEED memory);
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for Base Contract Controller

pragma solidity ^0.8.11;

interface IBaseContractController {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);

    function implementationEnded() external;

    function getImplementationStatus() external view returns (bool status);

    function getArtist() external view returns (address currentArtist);

    function setArtist(address _newArtist) external returns (address newArtist);
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for QueenE Traits contract

pragma solidity ^0.8.11;

//import {IERC165} from "IERC165.sol";

import {IBaseContractController} from "IBaseContractController.sol";
import {RoyalLibrary} from "RoyalLibrary.sol";

interface IQueenTraits is IBaseContractController {
    event RarityCreated(uint256 indexed rarityId, string rarityName);

    function getRarityById(uint256 _rarityId)
        external
        view
        returns (RoyalLibrary.sRARITY memory rarity);

    function getRarityByName(string memory _rarityName)
        external
        returns (RoyalLibrary.sRARITY memory rarity);

    function getRarities(bool onlyWithArt, uint256 _traitId)
        external
        view
        returns (RoyalLibrary.sRARITY[] memory raritiesList);

    function setRarity(string memory _rarityName, uint256 _percentage)
        external
        returns (RoyalLibrary.sRARITY memory rarity);

    function updateRarity(
        uint256 _rarityId,
        uint256 _newPercentage,
        string memory _rarityNewName
    ) external returns (RoyalLibrary.sRARITY memory rarity);

    function getTrait(uint256 _id)
        external
        view
        returns (RoyalLibrary.sTRAIT memory trait);

    function getTraitByName(string memory _traitName)
        external
        returns (RoyalLibrary.sTRAIT memory trait);

    function getTraits(bool _onlyEnabled)
        external
        view
        returns (RoyalLibrary.sTRAIT[] memory _traits);

    function getEnabledTraitsIdList() external view returns (uint256[] memory);

    function setTrait(string memory _traitName, uint8 _enabled)
        external
        returns (RoyalLibrary.sTRAIT memory trait);

    function GetArtByUri(
        uint256 _traitId,
        uint256 _rarityId,
        string memory _artUri
    ) external returns (RoyalLibrary.sART memory art);

    function GetArtCount(uint256 _traitId, uint256 _rarityId)
        external
        view
        returns (uint256 quantity);

    function GetArt(
        uint256 _traitId,
        uint256 _rarityId,
        uint256 _artIdx
    ) external view returns (RoyalLibrary.sART memory art);

    function GetArts(uint256 _traitId, uint256 _rarityId)
        external
        returns (RoyalLibrary.sART[] memory artsList);

    function GetRemovedArts(uint256 _traitId, uint256 _rarityId)
        external
        returns (RoyalLibrary.sART[] memory artsList);

    function SetArt(
        uint256 _traitId,
        uint256 _rarityId,
        string memory _artUri
    ) external returns (RoyalLibrary.sART memory art);

    function RemoveArt(
        uint256 _traitId,
        uint256 _rarityId,
        string memory _artUri
    ) external returns (bool result);

    //function setArtist(address _newArtist) external returns (address newArtist);
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

/// @title A base contract with implementation control

pragma solidity 0.8.11;

//import {ERC165} from "ERC165.sol";
import {Pausable} from "Pausable.sol";
import {ReentrancyGuard} from "ReentrancyGuard.sol";
import {Ownable} from "Ownable.sol";
import {Address} from "Address.sol";
import {Strings} from "Strings.sol";

import {RoyalLibrary} from "RoyalLibrary.sol";
import {IBaseContractController} from "IBaseContractController.sol";

contract BaseContractController is
    IBaseContractController,
    Pausable,
    ReentrancyGuard,
    Ownable
{
    event ArtistSet(address indexed artistAddress);

    address internal artist;

    bool internal onImplementation;

    /// @dev You must not set element 0xffffffff to true
    mapping(bytes4 => bool) internal supportedInterfaces;
    mapping(address => bool) internal allowedEcosystem;

    /************************** vCONTROLLER REGION *************************************************** */

    function supportsInterface(bytes4 interfaceID)
        public
        view
        override
        returns (bool)
    {
        return supportedInterfaces[interfaceID];
    }

    /**
     *IN
     *OUT
     */
    function implementationEnded() public onlyOwner {
        onImplementation = false;
    }

    /**
     *IN
     *OUT
     *status: current implementation status
     */
    function getImplementationStatus()
        public
        view
        onlyOwner
        returns (bool status)
    {
        return onImplementation;
    }

    /**
     *IN
     *_allowee: address of contract to be allowed to use this contract
     *OUT
     *status: allow final result on mapping
     */
    function allowOnEcosystem(address _allowee)
        public
        onlyOwner
        returns (bool status)
    {
        require(Address.isContract(_allowee), "Invalid address!");

        allowedEcosystem[_allowee] = true;
        return allowedEcosystem[_allowee];
    }

    /**
     *IN
     *_disallowee: address of contract to be disallowed to use this contract
     *OUT
     *status: allow final result on mapping
     */
    function disallowOnEcosystem(address _disallowee)
        public
        onlyOwner
        returns (bool status)
    {
        require(Address.isContract(_disallowee), "Invalid address!");

        allowedEcosystem[_disallowee] = false;
        return allowedEcosystem[_disallowee];
    }

    /**
     *IN
     *_allowee: address to verify allowance
     *OUT
     *status: allow current status for contract
     */
    function isAllowedOnEconsystem(address _allowee)
        public
        view
        returns (bool status)
    {
        require(Address.isContract(_allowee), "Invalid address!");

        return allowedEcosystem[_allowee];
    }

    /************************** ^vCONTROLLER REGION *************************************************** */

    /************************** vMODIFIERS REGION ***************************************************** */

    /**
     * @notice Require that message sender is either owner or artist.
     */
    modifier onlyOwnerOrArtist() {
        require(
            msg.sender == owner() || msg.sender == artist,
            "Not Owner nor Artist"
        );
        _;
    }

    /**
     * @notice Require that message sender is either owner or contract allowed on ecosystem.
     */
    modifier onlyEcosystemOrOwner() {
        require(
            msg.sender == owner() || isAllowedOnEconsystem(msg.sender),
            "Not Owner nor ecosystem allowed"
        );
        _;
    }

    /**
     * @notice Require that message sender is either owner or artist or contract allowed on ecosystem.
     */
    modifier onlyEcosystemOrOwnerOrArtist() {
        require(
            msg.sender == owner() ||
                msg.sender == artist ||
                isAllowedOnEconsystem(msg.sender),
            "Not Owner nor Artist nor ecosystem allowed"
        );
        _;
    }

    modifier onlyOnImplementationOrVoted(uint256 requestId) {
        if (onImplementation) {
            require(onImplementation, "Not On Implementation");
            _;
        } else {
            //TODO: verify DAO permission
            require(onImplementation, "Not On Implementation");
            _;
        }
    }

    modifier onlyOnImplementationOrPaused() {
        require(
            onImplementation || paused(),
            "Not On Implementation nor Paused"
        );
        _;
    }

    /************************** ^MODIFIERS REGION ***************************************************** */

    /************************** vARTIST REGION ******************************************************** */

    /**
     *IN
     *OUT
     *currentArtit: current artist address allowed on contract
     */
    function getArtist()
        external
        view
        onlyOwner
        returns (address currentArtist)
    {
        return artist;
    }

    /**
     *IN
     *_newArtist: address of artist tha will upload arts to contract
     *OUT
     */
    function setArtist(address _newArtist)
        external
        nonReentrant
        whenNotPaused
        onlyOwner
        onlyOnImplementationOrVoted(0)
        returns (address newArtist)
    {
        require(
            _newArtist != RoyalLibrary.burnAddress,
            "Invalid artist address! Burn address!"
        );

        require(!Address.isContract(_newArtist), "Must be a wallet address!");

        artist = _newArtist;
        return _newArtist;
    }

    /**
     *IN
     *_newArtist: address of artist tha will upload arts to contract
     *OUT
     */
    function _setArtist(address _newArtist)
        internal
        returns (address newArtist)
    {
        require(
            _newArtist != RoyalLibrary.burnAddress,
            "Invalid artist address! Burn address!"
        );

        require(!Address.isContract(_newArtist), "Must be a wallet address!");

        artist = _newArtist;
        newArtist = _newArtist;

        emit ArtistSet(_newArtist);
    }

    /************************** ^ARTIST REGION ******************************************************** */
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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