// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC721} from "@solidstate/contracts/token/ERC721/ERC721.sol";
import {ERC721BaseStorage} from "@solidstate/contracts/token/ERC721/base/ERC721BaseStorage.sol";
import {OwnableInternal} from "@solidstate/contracts/access/OwnableInternal.sol";

import {VRFConsumerBase} from "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

import {ChonkyGenomeLib} from "./lib/ChonkyGenomeLib.sol";
import {ChonkyMetadata} from "./ChonkyMetadata.sol";
import {ChonkyNFTStorage} from "./ChonkyNFTStorage.sol";
import {IChonkyNFT} from "./interface/IChonkyNFT.sol";

contract ChonkyNFT is IChonkyNFT, ERC721, VRFConsumerBase, OwnableInternal {
    using ERC721BaseStorage for ERC721BaseStorage.Layout;

    uint256 internal constant MAX_ELEMENTS = 7777;

    // Price per unit if buying < AMOUNT_DISCOUNT_ONE
    uint256 internal constant PRICE = 70 * 10**15;
    // Price per unit if buying >= AMOUNT_DISCOUNT_ONE
    uint256 internal constant PRICE_DISCOUNT_ONE = 65 * 10**15;
    // Price per unit if buying MAX_AMOUNT
    uint256 internal constant PRICE_DISCOUNT_MAX = 60 * 10**15;

    uint256 internal constant AMOUNT_DISCOUNT_ONE = 10;
    uint256 internal constant MAX_AMOUNT = 20;

    uint256 internal constant RESERVED_AMOUNT = 16;

    uint256 internal constant BITS_PER_GENOME = 58;

    string internal constant CID =
        "QmdafmnRuwqdnYGpVstF6raAqW64AD4i4maDAyvbeVDTGe";

    // Chainlink VRF
    bytes32 private immutable VRF_KEY_HASH;
    uint256 private immutable VRF_FEE;

    event CreateChonky(uint256 indexed id);
    event RevealInitiated(bytes32 indexed requestId);
    event Reveal(uint256 offset);

    constructor(
        address _vrfCoordinator,
        address _link,
        bytes32 _vrfKeyHash,
        uint256 _vrfFee
    ) VRFConsumerBase(_vrfCoordinator, _link) {
        VRF_KEY_HASH = _vrfKeyHash;
        VRF_FEE = _vrfFee;
    }

    function mintReserved(uint256 amount) external onlyOwner {
        // Mint reserved chonky
        for (uint256 i = 0; i < amount; i++) {
            _mintChonky(msg.sender);
        }
    }

    function setStartTimestamp(uint256 timestamp) external onlyOwner {
        ChonkyNFTStorage.layout().startTimestamp = timestamp;
    }

    function reveal() external onlyOwner returns (bytes32 requestId) {
        ChonkyNFTStorage.Layout storage l = ChonkyNFTStorage.layout();

        require(l.offset == 0, "Already revealed");

        requestId = requestRandomness(VRF_KEY_HASH, VRF_FEE);

        emit RevealInitiated(requestId);
    }

    function fulfillRandomness(bytes32, uint256 randomness) internal override {
        ChonkyNFTStorage.Layout storage l = ChonkyNFTStorage.layout();

        // Set  offset, which reveals the NFTs
        l.offset = (randomness % (MAX_ELEMENTS - RESERVED_AMOUNT)) + 1; // We add 1 to ensure offset is not 0 (unrevealed)

        emit Reveal(l.offset);
    }

    function mint() external payable {
        ChonkyNFTStorage.Layout storage l = ChonkyNFTStorage.layout();

        require(
            l.startTimestamp > 0 && block.timestamp > l.startTimestamp,
            "Minting not started"
        );
        require(l.currentId < MAX_ELEMENTS, "Sale ended");
        require(msg.value <= MAX_AMOUNT * PRICE_DISCOUNT_MAX, "> Max amount");

        uint256 count;
        if (msg.value >= MAX_AMOUNT * PRICE_DISCOUNT_MAX) {
            count = MAX_AMOUNT;
        } else if (msg.value >= PRICE_DISCOUNT_ONE * AMOUNT_DISCOUNT_ONE) {
            count = msg.value / PRICE_DISCOUNT_ONE;
        } else {
            count = msg.value / PRICE;
        }

        require(l.currentId + count <= MAX_ELEMENTS, "Max limit");

        for (uint256 i = 0; i < count; i++) {
            _mintChonky(msg.sender);
        }
    }

    function _mintChonky(address _to) private {
        ChonkyNFTStorage.Layout storage l = ChonkyNFTStorage.layout();

        uint256 id = l.currentId;
        _safeMint(_to, id);
        l.currentId += 1;
        emit CreateChonky(id);
    }

    function withdraw(address[] memory _addresses, uint256[] memory _amounts)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _addresses.length; i++) {
            _withdraw(_addresses[i], _amounts[i]);
        }
    }

    function parseGenome(uint256 _genome)
        external
        pure
        returns (uint256[12] memory result)
    {
        return ChonkyGenomeLib.parseGenome(_genome);
    }

    function formatGenome(uint256[12] memory _attributes)
        external
        pure
        returns (uint256 genome)
    {
        return ChonkyGenomeLib.formatGenome(_attributes);
    }

    function getGenome(uint256 _id) external view returns (uint256) {
        return _getGenome(_id);
    }

    function _getGenome(uint256 _id) internal view returns (uint256) {
        ChonkyNFTStorage.Layout storage l = ChonkyNFTStorage.layout();

        uint256 startBit = BITS_PER_GENOME * _id;
        uint256 genomeIndex = startBit / 256;

        uint256 genome = l.genomes[genomeIndex] >> (startBit % 256);

        if ((startBit % 256) + BITS_PER_GENOME <= 256) {
            uint256 mask = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff >>
                    (256 - BITS_PER_GENOME);
            genome &= mask;
        } else {
            uint256 remainingBits = 256 - (startBit % 256);
            uint256 missingBits = BITS_PER_GENOME - remainingBits;
            uint256 genomeNext = (l.genomes[genomeIndex + 1] <<
                (256 - missingBits)) >> (256 - missingBits - remainingBits);

            genome += genomeNext;
        }

        return genome;
    }

    function addPackedGenomes(uint256[] memory _genomes) external onlyOwner {
        ChonkyNFTStorage.Layout storage l = ChonkyNFTStorage.layout();

        for (uint256 i = 0; i < _genomes.length; i++) {
            l.genomes.push(_genomes[i]);
        }
    }

    function _getGenomeId(uint256 _tokenId) internal view returns (uint256) {
        ChonkyNFTStorage.Layout storage l = ChonkyNFTStorage.layout();

        // 10000 = Unrevealed
        uint256 finalId = 10000;

        if (_tokenId < RESERVED_AMOUNT) {
            finalId = _tokenId;
        } else if (l.offset > 0) {
            finalId =
                ((_tokenId + l.offset) % (MAX_ELEMENTS - RESERVED_AMOUNT)) +
                RESERVED_AMOUNT;
        }

        return finalId;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            ERC721BaseStorage.layout().exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        ChonkyNFTStorage.Layout storage l = ChonkyNFTStorage.layout();

        uint256 genomeId = _getGenomeId(_tokenId);
        return
            ChonkyMetadata(l.chonkyMetadata).buildTokenURI(
                _tokenId,
                genomeId,
                genomeId == 10000 ? 0 : _getGenome(genomeId),
                CID,
                l.chonkyAttributes,
                l.chonkySet
            );
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function getChonkyAttributesAddress() external view returns (address) {
        return ChonkyNFTStorage.layout().chonkyAttributes;
    }

    function getChonkyMetadataAddress() external view returns (address) {
        return ChonkyNFTStorage.layout().chonkyMetadata;
    }

    function getChonkySetAddress() external view returns (address) {
        return ChonkyNFTStorage.layout().chonkySet;
    }

    function getCID() external pure returns (string memory) {
        return CID;
    }

    function getStartTimestamp() external view returns (uint256) {
        return ChonkyNFTStorage.layout().startTimestamp;
    }

    function getOffset() external view returns (uint256) {
        return ChonkyNFTStorage.layout().offset;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ERC721Base, ERC721BaseInternal } from './base/ERC721Base.sol';
import { ERC721Enumerable } from './enumerable/ERC721Enumerable.sol';
import { ERC721Metadata } from './metadata/ERC721Metadata.sol';
import { ERC165 } from '../../introspection/ERC165.sol';

/**
 * @notice SolidState ERC721 implementation, including recommended extensions
 */
abstract contract ERC721 is
    ERC721Base,
    ERC721Enumerable,
    ERC721Metadata,
    ERC165
{
    /**
     * @notice ERC721 hook: revert if value is included in external approve function call
     * @inheritdoc ERC721BaseInternal
     */
    function _handleApproveMessageValue(
        address operator,
        uint256 tokenId,
        uint256 value
    ) internal virtual override {
        require(value == 0, 'ERC721: payable approve calls not supported');
        super._handleApproveMessageValue(operator, tokenId, value);
    }

    /**
     * @notice ERC721 hook: revert if value is included in external transfer function call
     * @inheritdoc ERC721BaseInternal
     */
    function _handleTransferMessageValue(
        address from,
        address to,
        uint256 tokenId,
        uint256 value
    ) internal virtual override {
        require(value == 0, 'ERC721: payable transfer calls not supported');
        super._handleTransferMessageValue(from, to, tokenId, value);
    }

    /**
     * @inheritdoc ERC721BaseInternal
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721BaseInternal, ERC721Metadata) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { EnumerableMap } from '../../../utils/EnumerableMap.sol';
import { EnumerableSet } from '../../../utils/EnumerableSet.sol';

library ERC721BaseStorage {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC721Base');

    struct Layout {
        EnumerableMap.UintToAddressMap tokenOwners;
        mapping(address => EnumerableSet.UintSet) holderTokens;
        mapping(uint256 => address) tokenApprovals;
        mapping(address => mapping(address => bool)) operatorApprovals;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function exists(Layout storage l, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        return l.tokenOwners.contains(tokenId);
    }

    function totalSupply(Layout storage l) internal view returns (uint256) {
        return l.tokenOwners.length();
    }

    function tokenOfOwnerByIndex(
        Layout storage l,
        address owner,
        uint256 index
    ) internal view returns (uint256) {
        return l.holderTokens[owner].at(index);
    }

    function tokenByIndex(Layout storage l, uint256 index)
        internal
        view
        returns (uint256)
    {
        (uint256 tokenId, ) = l.tokenOwners.at(index);
        return tokenId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { OwnableStorage } from './OwnableStorage.sol';

abstract contract OwnableInternal {
    using OwnableStorage for OwnableStorage.Layout;

    modifier onlyOwner() {
        require(
            msg.sender == OwnableStorage.layout().owner,
            'Ownable: sender must be owner'
        );
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/LinkTokenInterface.sol";

import "./VRFRequestIDBase.sol";

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {
  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 private constant USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(bytes32 _keyHash, uint256 _fee) internal returns (bytes32 requestId) {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface internal immutable LINK;
  address private immutable vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 => uint256) /* keyHash */ /* nonce */
    private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(address _vrfCoordinator, address _link) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library ChonkyGenomeLib {
    function parseGenome(uint256 _genome)
        internal
        pure
        returns (uint256[12] memory result)
    {
        assembly {
            mstore(result, sub(_genome, shl(5, shr(5, _genome))))

            mstore(
                add(result, 0x20),
                sub(shr(5, _genome), shl(3, shr(8, _genome)))
            )

            mstore(
                add(result, 0x40),
                sub(shr(8, _genome), shl(4, shr(12, _genome)))
            )

            mstore(
                add(result, 0x60),
                sub(shr(12, _genome), shl(5, shr(17, _genome)))
            )

            mstore(
                add(result, 0x80),
                sub(shr(17, _genome), shl(4, shr(21, _genome)))
            )

            mstore(
                add(result, 0xA0),
                sub(shr(21, _genome), shl(4, shr(25, _genome)))
            )

            mstore(
                add(result, 0xC0),
                sub(shr(25, _genome), shl(7, shr(32, _genome)))
            )

            mstore(
                add(result, 0xE0),
                sub(shr(32, _genome), shl(6, shr(38, _genome)))
            )

            mstore(
                add(result, 0x100),
                sub(shr(38, _genome), shl(6, shr(44, _genome)))
            )

            mstore(
                add(result, 0x120),
                sub(shr(44, _genome), shl(7, shr(51, _genome)))
            )

            mstore(
                add(result, 0x140),
                sub(shr(51, _genome), shl(3, shr(54, _genome)))
            )

            mstore(add(result, 0x160), shr(54, _genome))
        }
    }

    function formatGenome(uint256[12] memory _attributes)
        internal
        pure
        returns (uint256 genome)
    {
        genome =
            (_attributes[0]) +
            (_attributes[1] << 5) +
            (_attributes[2] << 8) +
            (_attributes[3] << 12) +
            (_attributes[4] << 17) +
            (_attributes[5] << 21) +
            (_attributes[6] << 25) +
            (_attributes[7] << 32) +
            (_attributes[8] << 38) +
            (_attributes[9] << 44) +
            (_attributes[10] << 51) +
            (_attributes[11] << 54);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {UintUtils} from "@solidstate/contracts/utils/UintUtils.sol";
import {Base64} from "base64-sol/base64.sol";
import {ChonkyGenomeLib} from "./lib/ChonkyGenomeLib.sol";
import {ChonkyAttributes} from "./ChonkyAttributes.sol";
import {ChonkySet} from "./ChonkySet.sol";

import {IChonkyMetadata} from "./interface/IChonkyMetadata.sol";
import {IChonkySet} from "./interface/IChonkySet.sol";

contract ChonkyMetadata is IChonkyMetadata {
    using UintUtils for uint256;

    function buildTokenURI(
        uint256 id,
        uint256 genomeId,
        uint256 genome,
        string memory CID,
        address chonkyAttributes,
        address chonkySet
    ) public pure returns (string memory) {
        string
            memory description = "A collection of 7777 mischievous Chonky's ready to wreak havoc on the ETH blockchain.";
        string memory attributes = _buildAttributes(
            genome,
            chonkyAttributes,
            chonkySet
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                "{",
                                '"image":"ipfs://',
                                CID,
                                "/",
                                _buildPaddedID(genomeId),
                                '.png",',
                                '"description":"',
                                description,
                                '",',
                                '"name":"Chonky',
                                "'s #",
                                _buildPaddedID(id),
                                '",',
                                attributes,
                                "}"
                            )
                        )
                    )
                )
            );
    }

    function _buildPaddedID(uint256 id) internal pure returns (string memory) {
        if (id == 0) return "0000";
        if (id < 10) return string(abi.encodePacked("000", id.toString()));
        if (id < 100) return string(abi.encodePacked("00", id.toString()));
        if (id < 1000) return string(abi.encodePacked("0", id.toString()));

        return id.toString();
    }

    ////

    function _getBGBase(uint256 id) internal pure returns (string memory) {
        if (id == 1) return "Aqua";
        if (id == 2) return "Black";
        if (id == 3) return "Brown";
        if (id == 4) return "Dark Purple";
        if (id == 5) return "Dark Red";
        if (id == 6) return "Gold";
        if (id == 7) return "Green";
        if (id == 8) return "Green Apple";
        if (id == 9) return "Grey";
        if (id == 10) return "Ice Blue";
        if (id == 11) return "Kaki";
        if (id == 12) return "Orange";
        if (id == 13) return "Pink";
        if (id == 14) return "Purple";
        if (id == 15) return "Rainbow";
        if (id == 16) return "Red";
        if (id == 17) return "Sky Blue";
        if (id == 18) return "Yellow";

        return "";
    }

    function _getBGRare(uint256 id) internal pure returns (string memory) {
        if (id == 1) return "HamHam";
        if (id == 2) return "Japan";
        if (id == 3) return "Skulls";
        if (id == 4) return "Stars";

        return "";
    }

    function _getWings(uint256 id) internal pure returns (string memory) {
        if (id == 1) return "Angel";
        if (id == 2) return "Bat";
        if (id == 3) return "Bee";
        if (id == 4) return "Crystal";
        if (id == 5) return "Devil";
        if (id == 6) return "Dragon";
        if (id == 7) return "Fairy";
        if (id == 8) return "Plant";
        if (id == 9) return "Robot";

        return "";
    }

    function _getSkin(uint256 id) internal pure returns (string memory) {
        if (id == 1) return "Almond";
        if (id == 2) return "Aqua";
        if (id == 3) return "Blue";
        if (id == 4) return "Brown";
        if (id == 5) return "Cream";
        if (id == 6) return "Dark";
        if (id == 7) return "Dark Blue";
        if (id == 8) return "Gold";
        if (id == 9) return "Green";
        if (id == 10) return "Grey";
        if (id == 11) return "Ice";
        if (id == 12) return "Indigo";
        if (id == 13) return "Light Brown";
        if (id == 14) return "Light Purple";
        if (id == 15) return "Neon Blue";
        if (id == 16) return "Orange";
        if (id == 17) return "Pink";
        if (id == 18) return "Purple";
        if (id == 19) return "Rose White";
        if (id == 20) return "Salmon";
        if (id == 21) return "Skye Blue";
        if (id == 22) return "Special Red";
        if (id == 23) return "White";
        if (id == 24) return "Yellow";

        return "";
    }

    function _getPattern(uint256 id) internal pure returns (string memory) {
        if (id == 1) return "3 Dots";
        if (id == 2) return "3 Triangles";
        if (id == 3) return "Corner";
        if (id == 4) return "Dalmatian";
        if (id == 5) return "Half";
        if (id == 6) return "Tiger Stripes";
        if (id == 7) return "Triangle";
        if (id == 8) return "White Reversed V";
        if (id == 9) return "Zombie";

        return "";
    }

    function _getPaint(uint256 id) internal pure returns (string memory) {
        if (id == 1) return "Beard";
        if (id == 2) return "Board";
        if (id == 3) return "Earrings";
        if (id == 4) return "Face Tattoo";
        if (id == 5) return "Happy Cheeks";
        if (id == 6) return "Pink Star";
        if (id == 7) return "Purple Star";
        if (id == 8) return "Scar";

        return "";
    }

    function _getBody(uint256 id) internal pure returns (string memory) {
        if (id == 1) return "Retro Shirt";
        if (id == 2) return "Angel Wings";
        if (id == 3) return "Aqua Monster";
        if (id == 4) return "Astronaut";
        if (id == 5) return "Bag";
        if (id == 6) return "Baron Samedi";
        if (id == 7) return "Bee";
        if (id == 8) return "Black Samurai";
        if (id == 9) return "Black Wizard";
        if (id == 10) return "Blue Football";
        if (id == 11) return "Blue Parka";
        if (id == 12) return "Blue Kimono";
        if (id == 13) return "Blue Hoodie";
        if (id == 14) return "Blue Wizard";
        if (id == 15) return "Jester";
        if (id == 16) return "Bubble Tea";
        if (id == 17) return "Captain";
        if (id == 18) return "Caveman";
        if (id == 19) return "Chef";
        if (id == 20) return "Chinese Shirt";
        if (id == 21) return "Cloth Monster";
        if (id == 22) return "Color Shirt";
        if (id == 23) return "Cowboy Shirt";
        if (id == 24) return "Cyber Assassin";
        if (id == 25) return "Devil Wings";
        if (id == 26) return "Scuba";
        if (id == 27) return "Doreamon";
        if (id == 28) return "Dracula";
        if (id == 29) return "Gold Chain";
        if (id == 30) return "Green Cyber";
        if (id == 31) return "Green Parka";
        if (id == 32) return "Green Kimono";
        if (id == 33) return "Green Hoodie";
        if (id == 34) return "Hamsterdam Shirt";
        if (id == 35) return "Hazard";
        if (id == 36) return "Hiding Hamster";
        if (id == 37) return "Pink Punk Girl";
        if (id == 38) return "Japanese Worker";
        if (id == 39) return "King";
        if (id == 40) return "Leather Jacket";
        if (id == 41) return "Leaves";
        if (id == 42) return "Lobster";
        if (id == 43) return "Luffy";
        if (id == 44) return "Magenta Cyber";
        if (id == 45) return "Sailor";
        if (id == 46) return "Mario Pipe";
        if (id == 47) return "Mommy";
        if (id == 48) return "Ninja";
        if (id == 49) return "Old Grandma";
        if (id == 50) return "Orange Jumpsuit";
        if (id == 51) return "Chili";
        if (id == 52) return "Chili Fire";
        if (id == 53) return "Pharaoh";
        if (id == 54) return "Pink Football";
        if (id == 55) return "Pink Ruff";
        if (id == 56) return "Pink Jumpsuit";
        if (id == 57) return "Pink Kimono";
        if (id == 58) return "Pink Polo";
        if (id == 59) return "Pirate";
        if (id == 60) return "Plague Doctor";
        if (id == 61) return "Poncho";
        if (id == 62) return "Purple Cyber";
        if (id == 63) return "Purple Polo";
        if (id == 64) return "Mystery Hoodie";
        if (id == 65) return "Rainbow Snake";
        if (id == 66) return "Red Ruff";
        if (id == 67) return "Red Punk Girl";
        if (id == 68) return "Red Samurai";
        if (id == 69) return "Referee";
        if (id == 70) return "Robotbod";
        if (id == 71) return "Robot Cyber";
        if (id == 72) return "Rocker";
        if (id == 73) return "Roman Legionary";
        if (id == 74) return "Safari";
        if (id == 75) return "Scout";
        if (id == 76) return "Sherlock";
        if (id == 77) return "Shirt";
        if (id == 78) return "Snow Coat";
        if (id == 79) return "Sparta";
        if (id == 80) return "Steampunk";
        if (id == 81) return "Suit";
        if (id == 82) return "Tie";
        if (id == 83) return "Tire";
        if (id == 84) return "Toga";
        if (id == 85) return "Tron";
        if (id == 86) return "Valkyrie";
        if (id == 87) return "Viking";
        if (id == 88) return "Wereham";
        if (id == 89) return "White Cloak";
        if (id == 90) return "Yellow Jumpsuit";
        if (id == 91) return "Zombie";

        return "";
    }

    function _getMouth(uint256 id) internal pure returns (string memory) {
        if (id == 1) return "Black Gas Mask Ninja";
        if (id == 2) return "Black Ninja Mask";
        if (id == 3) return "Shocked";
        if (id == 4) return "Creepy";
        if (id == 5) return "=D";
        if (id == 6) return "Drawing";
        if (id == 7) return "Duck";
        if (id == 8) return "Elegant Moustache";
        if (id == 9) return "Fire";
        if (id == 10) return "Gold Teeth";
        if (id == 11) return "Grey Futuristic Gas Mask";
        if (id == 12) return "Happy Open";
        if (id == 13) return "Goatee";
        if (id == 14) return "Honey";
        if (id == 15) return "Jack-O-Lantern";
        if (id == 16) return "Lipstick";
        if (id == 17) return "Little Moustache";
        if (id == 18) return "Luffy Smile";
        if (id == 19) return "Sanitary Mask";
        if (id == 20) return "Robot Mask";
        if (id == 21) return "Mega Happy";
        if (id == 22) return "Mega Tongue Out";
        if (id == 23) return "Meh";
        if (id == 24) return "Mexican Moustache";
        if (id == 25) return "Monster";
        if (id == 26) return "Moustache";
        if (id == 27) return "Drunk";
        if (id == 28) return "Fake Moustache";
        if (id == 29) return "Full";
        if (id == 30) return "Piece";
        if (id == 31) return "Stretch";
        if (id == 32) return "Ninja";
        if (id == 33) return "Normal";
        if (id == 34) return "Ohhhh";
        if (id == 35) return "Chili";
        if (id == 36) return "Purple Futuristic Gas Mask";
        if (id == 37) return "Red Gas Mask Ninja";
        if (id == 38) return "Red Ninja Mask";
        if (id == 39) return "Robot Mouth";
        if (id == 40) return "Scream";
        if (id == 41) return "Cigarette";
        if (id == 42) return "Smoking Pipe";
        if (id == 43) return "Square";
        if (id == 44) return "Steampunk";
        if (id == 45) return "Stitch";
        if (id == 46) return "Super Sad";
        if (id == 47) return "Thick Moustache";
        if (id == 48) return "Tongue";
        if (id == 49) return "Tongue Out";
        if (id == 50) return "Triangle";
        if (id == 51) return "Vampire";
        if (id == 52) return "Wave";
        if (id == 53) return "What";
        if (id == 54) return "YKWIM";

        return "";
    }

    function _getEyes(uint256 id) internal pure returns (string memory) {
        if (id == 1) return "^_^";
        if (id == 2) return ">_<";
        if (id == 3) return "=_=";
        if (id == 4) return "3D";
        if (id == 5) return "Angry";
        if (id == 6) return "Button";
        if (id == 7) return "Confused";
        if (id == 8) return "Crazy";
        if (id == 9) return "Cute";
        if (id == 10) return "Cyber Glasses";
        if (id == 11) return "Cyclops";
        if (id == 12) return "Depressed";
        if (id == 13) return "Determined";
        if (id == 14) return "Diving Mask";
        if (id == 15) return "Drawing";
        if (id == 16) return "Morty";
        if (id == 17) return "Eyepatch";
        if (id == 18) return "Fake Moustache";
        if (id == 19) return "Flower Glasses";
        if (id == 20) return "Frozen";
        if (id == 21) return "Furious";
        if (id == 22) return "Gengar";
        if (id == 23) return "Glasses Depressed";
        if (id == 24) return "Goku";
        if (id == 25) return "Green Underwear";
        if (id == 26) return "Hippie";
        if (id == 27) return "Kawaii";
        if (id == 28) return "Line Glasses";
        if (id == 29) return "Looking Up";
        if (id == 30) return "Looking Up Happy";
        if (id == 31) return "Mini Sunglasses";
        if (id == 32) return "Monocle";
        if (id == 33) return "Monster";
        if (id == 34) return "Ninja";
        if (id == 35) return "Normal";
        if (id == 36) return "Not Impressed";
        if (id == 37) return "o_o";
        if (id == 38) return "Orange Underwear";
        if (id == 39) return "Pink Star Sunglasses";
        if (id == 40) return "Pissed";
        if (id == 41) return "Pixel Glasses";
        if (id == 42) return "Plague Doctor Mask";
        if (id == 43) return "Proud";
        if (id == 44) return "Raccoon";
        if (id == 45) return "Red Dot";
        if (id == 46) return "Red Star Sunglasses";
        if (id == 47) return "Robot Eyes";
        if (id == 48) return "Scared Eyes";
        if (id == 49) return "Snorkel";
        if (id == 50) return "Serious Japan";
        if (id == 51) return "Seriously";
        if (id == 52) return "Star";
        if (id == 53) return "Steampunk Glasses";
        if (id == 54) return "Sunglasses";
        if (id == 55) return "Sunglasses Triangle";
        if (id == 56) return "Surprised";
        if (id == 57) return "Thick Eyebrows";
        if (id == 58) return "Troubled";
        if (id == 59) return "UniBrow";
        if (id == 60) return "Weird";
        if (id == 61) return "X_X";

        return "";
    }

    function _getLostKing(uint256 _id) internal pure returns (string memory) {
        if (_id == 1) return "The Glitch King";
        if (_id == 2) return "The Gummy King";
        if (_id == 3) return "King Diamond";
        if (_id == 4) return "The King of Gold";
        if (_id == 5) return "King Unicorn";
        if (_id == 6) return "The Last King";
        if (_id == 7) return "The Monkey King";

        return "";
    }

    function _getHonorary(uint256 id) internal pure returns (string memory) {
        if (id == 1) return "Crunchies";
        if (id == 2) return "Chuckle";
        if (id == 3) return "ChainLinkGod";
        if (id == 4) return "Crypt0n1c";
        if (id == 5) return "Bigdham";
        if (id == 6) return "Cyclopeape";
        if (id == 7) return "Elmo";
        if (id == 8) return "Caustik";
        if (id == 9) return "Churby";
        if (id == 10) return "Chonko";
        if (id == 11) return "Hamham";
        if (id == 12) return "Icebergy";
        if (id == 13) return "IronHam";
        if (id == 14) return "RatWell";
        if (id == 15) return "VangogHam";
        if (id == 16) return "Boneham";

        return "";
    }

    function _getHat(uint256 id) internal pure returns (string memory) {
        if (id == 1) return "Retro";
        if (id == 2) return "Aqua Monster";
        if (id == 3) return "Astronaut";
        if (id == 4) return "Baby Hamster";
        if (id == 5) return "Baron Samedi";
        if (id == 6) return "Bear Skin";
        if (id == 7) return "Bee";
        if (id == 8) return "Beanie";
        if (id == 9) return "Beret";
        if (id == 10) return "Biker Helmet";
        if (id == 11) return "Black Afro";
        if (id == 12) return "Black Hair JB";
        if (id == 13) return "Black Kabuki Mask";
        if (id == 14) return "Black Kabuto";
        if (id == 15) return "Black Magician";
        if (id == 16) return "Black Toupee";
        if (id == 17) return "Bolts";
        if (id == 18) return "Jester";
        if (id == 19) return "Brain";
        if (id == 20) return "Brown Hair JB";
        if (id == 21) return "Candle";
        if (id == 22) return "Captain";
        if (id == 23) return "Cheese";
        if (id == 24) return "Chef";
        if (id == 25) return "Cloth Monster";
        if (id == 26) return "Cone";
        if (id == 27) return "Cowboy";
        if (id == 28) return "Crown";
        if (id == 29) return "Devil Horns";
        if (id == 30) return "Dracula";
        if (id == 31) return "Duck";
        if (id == 32) return "Elvis";
        if (id == 33) return "Fish";
        if (id == 34) return "Fan";
        if (id == 35) return "Fire";
        if (id == 36) return "Fluffy Beanie";
        if (id == 37) return "Pigskin";
        if (id == 38) return "Futuristic Crown";
        if (id == 39) return "Golden Horns";
        if (id == 40) return "Green Fire";
        if (id == 41) return "Green Knot";
        if (id == 42) return "Green Punk";
        if (id == 43) return "Green Visor";
        if (id == 44) return "Halo";
        if (id == 45) return "Headband";
        if (id == 46) return "Ice";
        if (id == 47) return "Injury";
        if (id == 48) return "Kabuto";
        if (id == 49) return "Leaf";
        if (id == 50) return "Lion Head";
        if (id == 51) return "Long Hair Front";
        if (id == 52) return "Magician";
        if (id == 53) return "Mario Flower";
        if (id == 54) return "Mini Cap";
        if (id == 55) return "Ninja Band";
        if (id == 56) return "Mushroom";
        if (id == 57) return "Ninja";
        if (id == 58) return "Noodle Cup";
        if (id == 59) return "Octopus";
        if (id == 60) return "Old Lady";
        if (id == 61) return "Pancakes";
        if (id == 62) return "Paper Hat";
        if (id == 63) return "Pharaoh";
        if (id == 64) return "Pink Exploding Hair";
        if (id == 65) return "Pink Hair Girl";
        if (id == 66) return "Pink Mini Cap";
        if (id == 67) return "Pink Punk";
        if (id == 68) return "Pink Visor";
        if (id == 69) return "Pirate";
        if (id == 70) return "Plague Doctor";
        if (id == 71) return "Plant";
        if (id == 72) return "Punk Helmet";
        if (id == 73) return "Purple Mini Cap";
        if (id == 74) return "Purple Top Hat";
        if (id == 75) return "Rainbow Afro";
        if (id == 76) return "Rainbow Ice Cream";
        if (id == 77) return "Red Black Hair Girl";
        if (id == 78) return "Red Knot";
        if (id == 79) return "Red Punk";
        if (id == 80) return "Red Top Hat";
        if (id == 81) return "Robot Head";
        if (id == 82) return "Roman Legionary";
        if (id == 83) return "Safari";
        if (id == 84) return "Sherlock";
        if (id == 85) return "Sombrero";
        if (id == 86) return "Sparta";
        if (id == 87) return "Steampunk";
        if (id == 88) return "Straw";
        if (id == 89) return "Straw Hat";
        if (id == 90) return "Teapot";
        if (id == 91) return "Tin Hat";
        if (id == 92) return "Toupee";
        if (id == 93) return "Valkyrie";
        if (id == 94) return "Viking";
        if (id == 95) return "White Kabuki Mask";
        if (id == 96) return "Yellow Exploding Hair";

        return "";
    }

    ////

    function _buildAttributes(
        uint256 genome,
        address chonkyAttributes,
        address chonkySet
    ) internal pure returns (string memory result) {
        uint256[12] memory attributes = ChonkyGenomeLib.parseGenome(genome);

        bytes memory buffer = abi.encodePacked(
            '"attributes":[',
            '{"trait_type":"Background",',
            '"value":"',
            _getBGBase(attributes[0]),
            '"}'
        );

        if (attributes[1] > 0) {
            buffer = abi.encodePacked(
                buffer,
                ', {"trait_type":"Rare Background",',
                '"value":"',
                _getBGRare(attributes[1]),
                '"}'
            );
        }

        if (attributes[2] > 0) {
            buffer = abi.encodePacked(
                buffer,
                ',{"trait_type":"Wings",',
                '"value":"',
                _getWings(attributes[2]),
                '"}'
            );
        }

        if (attributes[3] > 0) {
            buffer = abi.encodePacked(
                buffer,
                ',{"trait_type":"Skin",',
                '"value":"',
                _getSkin(attributes[3]),
                '"}'
            );
        }

        if (attributes[4] > 0) {
            buffer = abi.encodePacked(
                buffer,
                ',{"trait_type":"Pattern",',
                '"value":"',
                _getPattern(attributes[4]),
                '"}'
            );
        }

        if (attributes[5] > 0) {
            buffer = abi.encodePacked(
                buffer,
                ',{"trait_type":"Paint",',
                '"value":"',
                _getPaint(attributes[5]),
                '"}'
            );
        }

        if (attributes[6] > 0) {
            buffer = abi.encodePacked(
                buffer,
                ',{"trait_type":"Body",',
                '"value":"',
                _getBody(attributes[6]),
                '"}'
            );
        }

        if (attributes[7] > 0) {
            buffer = abi.encodePacked(
                buffer,
                ',{"trait_type":"Mouth",',
                '"value":"',
                _getMouth(attributes[7]),
                '"}'
            );
        }

        if (attributes[8] > 0) {
            buffer = abi.encodePacked(
                buffer,
                ',{"trait_type":"Eyes",',
                '"value":"',
                _getEyes(attributes[8]),
                '"}'
            );
        }

        if (attributes[9] > 0) {
            buffer = abi.encodePacked(
                buffer,
                ',{"trait_type":"Hat",',
                '"value":"',
                _getHat(attributes[9]),
                '"}'
            );
        }

        if (attributes[10] > 0) {
            buffer = abi.encodePacked(
                buffer,
                ',{"trait_type":"Lost King",',
                '"value":"',
                _getLostKing(attributes[10]),
                '"}'
            );
        }

        if (attributes[11] > 0) {
            buffer = abi.encodePacked(
                buffer,
                ',{"trait_type":"Honorary",',
                '"value":"',
                _getHonorary(attributes[11]),
                '"}'
            );
        }

        uint256 setId = IChonkySet(chonkySet).getSetId(genome);

        if (setId > 0) {
            buffer = abi.encodePacked(
                buffer,
                ',{"trait_type":"Full Set",',
                '"value":"',
                IChonkySet(chonkySet).getSetFromId(setId),
                '"}'
            );
        }

        uint256[4] memory attributeValues = ChonkyAttributes(chonkyAttributes)
            .getAttributeValues(attributes, setId);

        buffer = abi.encodePacked(
            buffer,
            ',{"trait_type":"Brain",',
            '"value":',
            attributeValues[0].toString(),
            "}"
        );

        buffer = abi.encodePacked(
            buffer,
            ',{"trait_type":"Cute",',
            '"value":',
            attributeValues[1].toString(),
            "}"
        );

        buffer = abi.encodePacked(
            buffer,
            ',{"trait_type":"Power",',
            '"value":',
            attributeValues[2].toString(),
            "}"
        );

        buffer = abi.encodePacked(
            buffer,
            ',{"trait_type":"Wicked",',
            '"value":',
            attributeValues[3].toString(),
            "}"
        );

        return string(abi.encodePacked(buffer, "]"));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {EnumerableSet} from "@solidstate/contracts/utils/EnumerableSet.sol";

library ChonkyNFTStorage {
    bytes32 internal constant STORAGE_SLOT =
        keccak256("chonky.contracts.storage.ChonkyNFT");

    struct Layout {
        address implementation;
        uint256 currentId;
        uint256[] genomes;
        // Offset IDs to randomize distribution when revealing
        uint256 offset;
        // Address of chonkyAttributes contract
        address chonkyAttributes;
        // Address of chonkyMetadata contract
        address chonkyMetadata;
        // Address of chonkySet contract
        address chonkySet;
        // Timestamp at which minting starts
        uint256 startTimestamp;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC721} from "@solidstate/contracts/token/ERC721/IERC721.sol";
import {IERC721Enumerable} from "@solidstate/contracts/token/ERC721/enumerable/IERC721Enumerable.sol";

interface IChonkyNFT is IERC721, IERC721Enumerable {
    function mint() external payable;

    function parseGenome(uint256 _genome)
        external
        pure
        returns (uint256[12] memory result);

    function formatGenome(uint256[12] memory _attributes)
        external
        pure
        returns (uint256 genome);

    function getGenome(uint256 _id) external view returns (uint256);

    function getChonkyAttributesAddress() external view returns (address);

    function getChonkyMetadataAddress() external view returns (address);

    function getChonkySetAddress() external view returns (address);

    function getCID() external pure returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { AddressUtils } from '../../../utils/AddressUtils.sol';
import { EnumerableMap } from '../../../utils/EnumerableMap.sol';
import { EnumerableSet } from '../../../utils/EnumerableSet.sol';
import { IERC721 } from '../IERC721.sol';
import { IERC721Receiver } from '../IERC721Receiver.sol';
import { ERC721BaseStorage } from './ERC721BaseStorage.sol';
import { ERC721BaseInternal } from './ERC721BaseInternal.sol';

/**
 * @notice Base ERC721 implementation, excluding optional extensions
 */
abstract contract ERC721Base is IERC721, ERC721BaseInternal {
    using AddressUtils for address;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using EnumerableSet for EnumerableSet.UintSet;

    /**
     * @inheritdoc IERC721
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balanceOf(account);
    }

    /**
     * @inheritdoc IERC721
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _ownerOf(tokenId);
    }

    /**
     * @inheritdoc IERC721
     */
    function getApproved(uint256 tokenId)
        public
        view
        override
        returns (address)
    {
        return _getApproved(tokenId);
    }

    /**
     * @inheritdoc IERC721
     */
    function isApprovedForAll(address account, address operator)
        public
        view
        override
        returns (bool)
    {
        return _isApprovedForAll(account, operator);
    }

    /**
     * @inheritdoc IERC721
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override {
        _handleTransferMessageValue(from, to, tokenId, msg.value);
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            'ERC721: transfer caller is not owner or approved'
        );
        _transfer(from, to, tokenId);
    }

    /**
     * @inheritdoc IERC721
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @inheritdoc IERC721
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override {
        _handleTransferMessageValue(from, to, tokenId, msg.value);
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            'ERC721: transfer caller is not owner or approved'
        );
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @inheritdoc IERC721
     */
    function approve(address operator, uint256 tokenId)
        public
        payable
        override
    {
        _handleApproveMessageValue(operator, tokenId, msg.value);
        address owner = ownerOf(tokenId);
        require(operator != owner, 'ERC721: approval to current owner');
        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            'ERC721: approve caller is not owner nor approved for all'
        );
        _approve(operator, tokenId);
    }

    /**
     * @inheritdoc IERC721
     */
    function setApprovalForAll(address operator, bool status) public override {
        require(operator != msg.sender, 'ERC721: approve to caller');
        ERC721BaseStorage.layout().operatorApprovals[msg.sender][
            operator
        ] = status;
        emit ApprovalForAll(msg.sender, operator, status);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { EnumerableMap } from '../../../utils/EnumerableMap.sol';
import { EnumerableSet } from '../../../utils/EnumerableSet.sol';
import { ERC721BaseStorage } from '../base/ERC721BaseStorage.sol';
import { IERC721Enumerable } from './IERC721Enumerable.sol';
import { ERC721EnumerableInternal } from './ERC721EnumerableInternal.sol';

abstract contract ERC721Enumerable is
    IERC721Enumerable,
    ERC721EnumerableInternal
{
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using EnumerableSet for EnumerableSet.UintSet;

    /**
     * @inheritdoc IERC721Enumerable
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply();
    }

    /**
     * @inheritdoc IERC721Enumerable
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        override
        returns (uint256)
    {
        return _tokenOfOwnerByIndex(owner, index);
    }

    /**
     * @inheritdoc IERC721Enumerable
     */
    function tokenByIndex(uint256 index)
        public
        view
        override
        returns (uint256)
    {
        return _tokenByIndex(index);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { UintUtils } from '../../../utils/UintUtils.sol';
import { ERC721BaseInternal, ERC721BaseStorage } from '../base/ERC721Base.sol';
import { ERC721MetadataStorage } from './ERC721MetadataStorage.sol';
import { ERC721MetadataInternal } from './ERC721MetadataInternal.sol';
import { IERC721Metadata } from './IERC721Metadata.sol';

/**
 * @notice ERC721 metadata extensions
 */
abstract contract ERC721Metadata is IERC721Metadata, ERC721MetadataInternal {
    using ERC721BaseStorage for ERC721BaseStorage.Layout;
    using UintUtils for uint256;

    /**
     * @notice inheritdoc IERC721Metadata
     */
    function name() public view virtual override returns (string memory) {
        return ERC721MetadataStorage.layout().name;
    }

    /**
     * @notice inheritdoc IERC721Metadata
     */
    function symbol() public view virtual override returns (string memory) {
        return ERC721MetadataStorage.layout().symbol;
    }

    /**
     * @notice inheritdoc IERC721Metadata
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            ERC721BaseStorage.layout().exists(tokenId),
            'ERC721Metadata: URI query for nonexistent token'
        );

        ERC721MetadataStorage.Layout storage l = ERC721MetadataStorage.layout();

        string memory tokenIdURI = l.tokenURIs[tokenId];
        string memory baseURI = l.baseURI;

        if (bytes(baseURI).length == 0) {
            return tokenIdURI;
        } else if (bytes(tokenIdURI).length > 0) {
            return string(abi.encodePacked(baseURI, tokenIdURI));
        } else {
            return string(abi.encodePacked(baseURI, tokenId.toString()));
        }
    }

    /**
     * @inheritdoc ERC721MetadataInternal
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC165 } from './IERC165.sol';
import { ERC165Storage } from './ERC165Storage.sol';

/**
 * @title ERC165 implementation
 */
abstract contract ERC165 is IERC165 {
    using ERC165Storage for ERC165Storage.Layout;

    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override
        returns (bool)
    {
        return ERC165Storage.layout().isSupportedInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library AddressUtils {
    function toString(address account) internal pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(account)));
        bytes memory alphabet = '0123456789abcdef';
        bytes memory chars = new bytes(42);

        chars[0] = '0';
        chars[1] = 'x';

        for (uint256 i = 0; i < 20; i++) {
            chars[2 + i * 2] = alphabet[uint8(value[i + 12] >> 4)];
            chars[3 + i * 2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }

        return string(chars);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable account, uint256 amount) internal {
        (bool success, ) = account.call{ value: amount }('');
        require(success, 'AddressUtils: failed to send value');
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionCall(target, data, 'AddressUtils: failed low-level call');
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory error
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, error);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                'AddressUtils: failed low-level call with value'
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            'AddressUtils: insufficient balance for call'
        );
        return _functionCallWithValue(target, data, value, error);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) private returns (bytes memory) {
        require(
            isContract(target),
            'AddressUtils: function call to non-contract'
        );

        (bool success, bytes memory returnData) = target.call{ value: value }(
            data
        );

        if (success) {
            return returnData;
        } else if (returnData.length > 0) {
            assembly {
                let returnData_size := mload(returnData)
                revert(add(32, returnData), returnData_size)
            }
        } else {
            revert(error);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Map implementation with enumeration functions
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
library EnumerableMap {
    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        MapEntry[] _entries;
        // 1-indexed to allow 0 to signify nonexistence
        mapping(bytes32 => uint256) _indexes;
    }

    struct AddressToAddressMap {
        Map _inner;
    }

    struct UintToAddressMap {
        Map _inner;
    }

    function at(AddressToAddressMap storage map, uint256 index)
        internal
        view
        returns (address, address)
    {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        address addressKey;
        assembly {
            addressKey := mload(add(key, 20))
        }
        return (addressKey, address(uint160(uint256(value))));
    }

    function at(UintToAddressMap storage map, uint256 index)
        internal
        view
        returns (uint256, address)
    {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    function contains(AddressToAddressMap storage map, address key)
        internal
        view
        returns (bool)
    {
        return _contains(map._inner, bytes32(uint256(uint160(key))));
    }

    function contains(UintToAddressMap storage map, uint256 key)
        internal
        view
        returns (bool)
    {
        return _contains(map._inner, bytes32(key));
    }

    function length(AddressToAddressMap storage map)
        internal
        view
        returns (uint256)
    {
        return _length(map._inner);
    }

    function length(UintToAddressMap storage map)
        internal
        view
        returns (uint256)
    {
        return _length(map._inner);
    }

    function get(AddressToAddressMap storage map, address key)
        internal
        view
        returns (address)
    {
        return
            address(
                uint160(
                    uint256(_get(map._inner, bytes32(uint256(uint160(key)))))
                )
            );
    }

    function get(UintToAddressMap storage map, uint256 key)
        internal
        view
        returns (address)
    {
        return address(uint160(uint256(_get(map._inner, bytes32(key)))));
    }

    function set(
        AddressToAddressMap storage map,
        address key,
        address value
    ) internal returns (bool) {
        return
            _set(
                map._inner,
                bytes32(uint256(uint160(key))),
                bytes32(uint256(uint160(value)))
            );
    }

    function set(
        UintToAddressMap storage map,
        uint256 key,
        address value
    ) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    function remove(AddressToAddressMap storage map, address key)
        internal
        returns (bool)
    {
        return _remove(map._inner, bytes32(uint256(uint160(key))));
    }

    function remove(UintToAddressMap storage map, uint256 key)
        internal
        returns (bool)
    {
        return _remove(map._inner, bytes32(key));
    }

    function _at(Map storage map, uint256 index)
        private
        view
        returns (bytes32, bytes32)
    {
        require(
            map._entries.length > index,
            'EnumerableMap: index out of bounds'
        );

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    function _contains(Map storage map, bytes32 key)
        private
        view
        returns (bool)
    {
        return map._indexes[key] != 0;
    }

    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, 'EnumerableMap: nonexistent key');
        return map._entries[keyIndex - 1]._value;
    }

    function _set(
        Map storage map,
        bytes32 key,
        bytes32 value
    ) private returns (bool) {
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) {
            map._entries.push(MapEntry({ _key: key, _value: value }));
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    function _remove(Map storage map, bytes32 key) private returns (bool) {
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) {
            uint256 index = keyIndex - 1;
            MapEntry storage last = map._entries[map._entries.length - 1];

            // move last entry to now-vacant index

            map._entries[index] = last;
            map._indexes[last._key] = index + 1;

            // clear last index

            map._entries.pop();
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Set implementation with enumeration functions
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
library EnumerableSet {
    struct Set {
        bytes32[] _values;
        // 1-indexed to allow 0 to signify nonexistence
        mapping(bytes32 => uint256) _indexes;
    }

    struct Bytes32Set {
        Set _inner;
    }

    struct AddressSet {
        Set _inner;
    }

    struct UintSet {
        Set _inner;
    }

    function at(Bytes32Set storage set, uint256 index)
        internal
        view
        returns (bytes32)
    {
        return _at(set._inner, index);
    }

    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function at(UintSet storage set, uint256 index)
        internal
        view
        returns (uint256)
    {
        return uint256(_at(set._inner, index));
    }

    function contains(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, value);
    }

    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(UintSet storage set, uint256 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(value));
    }

    function indexOf(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (uint256)
    {
        return _indexOf(set._inner, value);
    }

    function indexOf(AddressSet storage set, address value)
        internal
        view
        returns (uint256)
    {
        return _indexOf(set._inner, bytes32(uint256(uint160(value))));
    }

    function indexOf(UintSet storage set, uint256 value)
        internal
        view
        returns (uint256)
    {
        return _indexOf(set._inner, bytes32(value));
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function add(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _add(set._inner, value);
    }

    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, value);
    }

    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(UintSet storage set, uint256 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(value));
    }

    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
        require(
            set._values.length > index,
            'EnumerableSet: index out of bounds'
        );
        return set._values[index];
    }

    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
        return set._indexes[value] != 0;
    }

    function _indexOf(Set storage set, bytes32 value)
        private
        view
        returns (uint256)
    {
        unchecked {
            return set._indexes[value] - 1;
        }
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            uint256 index = valueIndex - 1;
            bytes32 last = set._values[set._values.length - 1];

            // move last value to now-vacant index

            set._values[index] = last;
            set._indexes[last] = index + 1;

            // clear last index

            set._values.pop();
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC165 } from '../../introspection/IERC165.sol';
import { IERC721Internal } from './IERC721Internal.sol';

/**
 * @notice ERC721 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721 is IERC721Internal, IERC165 {
    /**
     * @notice query the balance of given address
     * @return balance quantity of tokens held
     */
    function balanceOf(address account) external view returns (uint256 balance);

    /**
     * @notice query the owner of given token
     * @param tokenId token to query
     * @return owner token owner
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @notice transfer token between given addresses, checking for ERC721Receiver implementation if applicable
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId token id
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @notice transfer token between given addresses, checking for ERC721Receiver implementation if applicable
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId token id
     * @param data data payload
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external payable;

    /**
     * @notice transfer token between given addresses, without checking for ERC721Receiver implementation if applicable
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId token id
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @notice grant approval to given account to spend token
     * @param operator address to be approved
     * @param tokenId token to approve
     */
    function approve(address operator, uint256 tokenId) external payable;

    /**
     * @notice get approval status for given token
     * @param tokenId token to query
     * @return operator address approved to spend token
     */
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    /**
     * @notice grant approval to or revoke approval from given account to spend all tokens held by sender
     * @param operator address to be approved
     * @param status approval status
     */
    function setApprovalForAll(address operator, bool status) external;

    /**
     * @notice query approval status of given operator with respect to given address
     * @param account address to query for approval granted
     * @param operator address to query for approval received
     * @return status whether operator is approved to spend tokens held by account
     */
    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool status);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { AddressUtils } from '../../../utils/AddressUtils.sol';
import { EnumerableMap } from '../../../utils/EnumerableMap.sol';
import { EnumerableSet } from '../../../utils/EnumerableSet.sol';
import { IERC721Internal } from '../IERC721Internal.sol';
import { IERC721Receiver } from '../IERC721Receiver.sol';
import { ERC721BaseStorage } from './ERC721BaseStorage.sol';

/**
 * @notice Base ERC721 internal functions
 */
abstract contract ERC721BaseInternal is IERC721Internal {
    using ERC721BaseStorage for ERC721BaseStorage.Layout;
    using AddressUtils for address;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using EnumerableSet for EnumerableSet.UintSet;

    function _balanceOf(address account) internal view returns (uint256) {
        require(
            account != address(0),
            'ERC721: balance query for the zero address'
        );
        return ERC721BaseStorage.layout().holderTokens[account].length();
    }

    function _ownerOf(uint256 tokenId) internal view returns (address) {
        address owner = ERC721BaseStorage.layout().tokenOwners.get(tokenId);
        require(owner != address(0), 'ERC721: invalid owner');
        return owner;
    }

    function _getApproved(uint256 tokenId) internal view returns (address) {
        ERC721BaseStorage.Layout storage l = ERC721BaseStorage.layout();

        require(
            l.exists(tokenId),
            'ERC721: approved query for nonexistent token'
        );

        return l.tokenApprovals[tokenId];
    }

    function _isApprovedForAll(address account, address operator)
        internal
        view
        returns (bool)
    {
        return ERC721BaseStorage.layout().operatorApprovals[account][operator];
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        require(
            ERC721BaseStorage.layout().exists(tokenId),
            'ERC721: query for nonexistent token'
        );

        address owner = _ownerOf(tokenId);

        return (spender == owner ||
            _getApproved(tokenId) == spender ||
            _isApprovedForAll(owner, spender));
    }

    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), 'ERC721: mint to the zero address');

        ERC721BaseStorage.Layout storage l = ERC721BaseStorage.layout();

        require(!l.exists(tokenId), 'ERC721: token already minted');

        _beforeTokenTransfer(address(0), to, tokenId);

        l.holderTokens[to].add(tokenId);
        l.tokenOwners.set(tokenId, to);

        emit Transfer(address(0), to, tokenId);
    }

    function _safeMint(address to, uint256 tokenId) internal {
        _safeMint(to, tokenId, '');
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            'ERC721: transfer to non ERC721Receiver implementer'
        );
    }

    function _burn(uint256 tokenId) internal {
        address owner = _ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        _approve(address(0), tokenId);

        ERC721BaseStorage.Layout storage l = ERC721BaseStorage.layout();
        l.holderTokens[owner].remove(tokenId);
        l.tokenOwners.remove(tokenId);

        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        require(
            _ownerOf(tokenId) == from,
            'ERC721: transfer of token that is not own'
        );
        require(to != address(0), 'ERC721: transfer to the zero address');

        _beforeTokenTransfer(from, to, tokenId);

        _approve(address(0), tokenId);

        ERC721BaseStorage.Layout storage l = ERC721BaseStorage.layout();
        l.holderTokens[from].remove(tokenId);
        l.holderTokens[to].add(tokenId);
        l.tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, data),
            'ERC721: transfer to non ERC721Receiver implementer'
        );
    }

    function _approve(address operator, uint256 tokenId) internal {
        ERC721BaseStorage.layout().tokenApprovals[tokenId] = operator;
        emit Approval(_ownerOf(tokenId), operator, tokenId);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal returns (bool) {
        if (!to.isContract()) {
            return true;
        }

        bytes memory returnData = to.functionCall(
            abi.encodeWithSelector(
                IERC721Receiver(to).onERC721Received.selector,
                msg.sender,
                from,
                tokenId,
                data
            ),
            'ERC721: transfer to non ERC721Receiver implementer'
        );

        bytes4 returnValue = abi.decode(returnData, (bytes4));
        return returnValue == type(IERC721Receiver).interfaceId;
    }

    /**
     * @notice ERC721 hook, called before externally called approvals for processing of included message value
     * @param operator beneficiary of approval
     * @param tokenId id of transferred token
     * @param value message value
     */
    function _handleApproveMessageValue(
        address operator,
        uint256 tokenId,
        uint256 value
    ) internal virtual {}

    /**
     * @notice ERC721 hook, called before externally called transfers for processing of included message value
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId id of transferred token
     * @param value message value
     */
    function _handleTransferMessageValue(
        address from,
        address to,
        uint256 tokenId,
        uint256 value
    ) internal virtual {}

    /**
     * @notice ERC721 hook, called before all transfers including mint and burn
     * @dev function should be overridden and new implementation must call super
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId id of transferred token
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC165 interface registration interface
 * @dev see https://eips.ethereum.org/EIPS/eip-165
 */
interface IERC165 {
    /**
     * @notice query whether contract has registered support for given interface
     * @param interfaceId interface id
     * @return bool whether interface is supported
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @notice Partial ERC721 interface needed by internal functions
 */
interface IERC721Internal {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    event Approval(
        address indexed owner,
        address indexed operator,
        uint256 indexed tokenId
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC721Enumerable {
    /**
     * @notice get total token supply
     * @return total supply
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice get token of given owner at given internal storage index
     * @param owner token holder to query
     * @param index position in owner's token list to query
     * @return tokenId id of retrieved token
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256 tokenId);

    /**
     * @notice get token at given internal storage index
     * @param index position in global token list to query
     * @return tokenId id of retrieved token
     */
    function tokenByIndex(uint256 index)
        external
        view
        returns (uint256 tokenId);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ERC721BaseStorage } from '../base/ERC721BaseStorage.sol';

abstract contract ERC721EnumerableInternal {
    using ERC721BaseStorage for ERC721BaseStorage.Layout;

    /**
     * @notice TODO
     */
    function _totalSupply() internal view returns (uint256) {
        return ERC721BaseStorage.layout().totalSupply();
    }

    /**
     * @notice TODO
     */
    function _tokenOfOwnerByIndex(address owner, uint256 index)
        internal
        view
        returns (uint256)
    {
        return ERC721BaseStorage.layout().tokenOfOwnerByIndex(owner, index);
    }

    /**
     * @notice TODO
     */
    function _tokenByIndex(uint256 index) internal view returns (uint256) {
        return ERC721BaseStorage.layout().tokenByIndex(index);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library UintUtils {
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0';
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library ERC721MetadataStorage {
    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC721Metadata');

    struct Layout {
        string name;
        string symbol;
        string baseURI;
        mapping(uint256 => string) tokenURIs;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ERC721BaseInternal } from '../base/ERC721Base.sol';
import { ERC721MetadataStorage } from './ERC721MetadataStorage.sol';

/**
 * @notice ERC721Metadata internal functions
 */
abstract contract ERC721MetadataInternal is ERC721BaseInternal {
    /**
     * @notice ERC721 hook: clear per-token URI data on burn
     * @inheritdoc ERC721BaseInternal
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (to == address(0)) {
            delete ERC721MetadataStorage.layout().tokenURIs[tokenId];
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721Metadata interface
 */
interface IERC721Metadata {
    /**
     * @notice get token name
     * @return token name
     */
    function name() external view returns (string memory);

    /**
     * @notice get token symbol
     * @return token symbol
     */
    function symbol() external view returns (string memory);

    /**
     * @notice get generated URI for given token
     * @return token URI
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library ERC165Storage {
    struct Layout {
        mapping(bytes4 => bool) supportedInterfaces;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC165');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function isSupportedInterface(Layout storage l, bytes4 interfaceId)
        internal
        view
        returns (bool)
    {
        return l.supportedInterfaces[interfaceId];
    }

    function setSupportedInterface(
        Layout storage l,
        bytes4 interfaceId,
        bool status
    ) internal {
        require(interfaceId != 0xffffffff, 'ERC165: invalid interface id');
        l.supportedInterfaces[interfaceId] = status;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library OwnableStorage {
    struct Layout {
        address owner;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.Ownable');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function setOwner(Layout storage l, address owner) internal {
        l.owner = owner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VRFRequestIDBase {
  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  ) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

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
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IChonkyAttributes} from "./interface/IChonkyAttributes.sol";

contract ChonkyAttributes is IChonkyAttributes {
    function _getBodyAttribute(uint256 _id)
        internal
        pure
        returns (IChonkyAttributes.AttributeType, uint256)
    {
        if (_id == 0) return (IChonkyAttributes.AttributeType.NONE, 0);

        if (_id == 1) return (IChonkyAttributes.AttributeType.CUTE, 7);
        if (_id == 2) return (IChonkyAttributes.AttributeType.CUTE, 6);
        if (_id == 3) return (IChonkyAttributes.AttributeType.WICKED, 8);
        if (_id == 4) return (IChonkyAttributes.AttributeType.BRAIN, 9);
        if (_id == 5) return (IChonkyAttributes.AttributeType.POWER, 3);
        if (_id == 6) return (IChonkyAttributes.AttributeType.WICKED, 10);
        if (_id == 7) return (IChonkyAttributes.AttributeType.CUTE, 9);
        if (_id == 8) return (IChonkyAttributes.AttributeType.POWER, 10);
        if (_id == 9) return (IChonkyAttributes.AttributeType.WICKED, 2);
        if (_id == 10) return (IChonkyAttributes.AttributeType.POWER, 2);
        if (_id == 11) return (IChonkyAttributes.AttributeType.CUTE, 6);
        if (_id == 12) return (IChonkyAttributes.AttributeType.CUTE, 4);
        if (_id == 13) return (IChonkyAttributes.AttributeType.POWER, 1);
        if (_id == 14) return (IChonkyAttributes.AttributeType.BRAIN, 2);
        if (_id == 15) return (IChonkyAttributes.AttributeType.BRAIN, 6);
        if (_id == 16) return (IChonkyAttributes.AttributeType.CUTE, 5);
        if (_id == 17) return (IChonkyAttributes.AttributeType.POWER, 3);
        if (_id == 18) return (IChonkyAttributes.AttributeType.POWER, 2);
        if (_id == 19) return (IChonkyAttributes.AttributeType.BRAIN, 1);
        if (_id == 20) return (IChonkyAttributes.AttributeType.CUTE, 2);
        if (_id == 21) return (IChonkyAttributes.AttributeType.WICKED, 3);
        if (_id == 22) return (IChonkyAttributes.AttributeType.WICKED, 4);
        if (_id == 23) return (IChonkyAttributes.AttributeType.POWER, 5);
        if (_id == 24) return (IChonkyAttributes.AttributeType.POWER, 8);
        if (_id == 25) return (IChonkyAttributes.AttributeType.WICKED, 6);
        if (_id == 26) return (IChonkyAttributes.AttributeType.POWER, 8);
        if (_id == 27) return (IChonkyAttributes.AttributeType.CUTE, 1);
        if (_id == 28) return (IChonkyAttributes.AttributeType.WICKED, 8);
        if (_id == 29) return (IChonkyAttributes.AttributeType.POWER, 2);
        if (_id == 30) return (IChonkyAttributes.AttributeType.BRAIN, 8);
        if (_id == 31) return (IChonkyAttributes.AttributeType.POWER, 6);
        if (_id == 32) return (IChonkyAttributes.AttributeType.CUTE, 4);
        if (_id == 33) return (IChonkyAttributes.AttributeType.POWER, 1);
        if (_id == 34) return (IChonkyAttributes.AttributeType.POWER, 2);
        if (_id == 35) return (IChonkyAttributes.AttributeType.WICKED, 5);
        if (_id == 36) return (IChonkyAttributes.AttributeType.CUTE, 7);
        if (_id == 37) return (IChonkyAttributes.AttributeType.CUTE, 5);
        if (_id == 38) return (IChonkyAttributes.AttributeType.POWER, 5);
        if (_id == 39) return (IChonkyAttributes.AttributeType.POWER, 10);
        if (_id == 40) return (IChonkyAttributes.AttributeType.POWER, 4);
        if (_id == 41) return (IChonkyAttributes.AttributeType.WICKED, 7);
        if (_id == 42) return (IChonkyAttributes.AttributeType.WICKED, 8);
        if (_id == 43) return (IChonkyAttributes.AttributeType.POWER, 9);
        if (_id == 44) return (IChonkyAttributes.AttributeType.BRAIN, 8);
        if (_id == 45) return (IChonkyAttributes.AttributeType.CUTE, 1);
        if (_id == 46) return (IChonkyAttributes.AttributeType.WICKED, 8);
        if (_id == 47) return (IChonkyAttributes.AttributeType.CUTE, 6);
        if (_id == 48) return (IChonkyAttributes.AttributeType.POWER, 7);
        if (_id == 49) return (IChonkyAttributes.AttributeType.CUTE, 1);
        if (_id == 50) return (IChonkyAttributes.AttributeType.POWER, 1);
        if (_id == 51) return (IChonkyAttributes.AttributeType.POWER, 6);
        if (_id == 52) return (IChonkyAttributes.AttributeType.WICKED, 7);
        if (_id == 53) return (IChonkyAttributes.AttributeType.POWER, 9);
        if (_id == 54) return (IChonkyAttributes.AttributeType.POWER, 3);
        if (_id == 55) return (IChonkyAttributes.AttributeType.CUTE, 2);
        if (_id == 56) return (IChonkyAttributes.AttributeType.POWER, 2);
        if (_id == 57) return (IChonkyAttributes.AttributeType.CUTE, 3);
        if (_id == 58) return (IChonkyAttributes.AttributeType.BRAIN, 1);
        if (_id == 59) return (IChonkyAttributes.AttributeType.POWER, 8);
        if (_id == 60) return (IChonkyAttributes.AttributeType.WICKED, 9);
        if (_id == 61) return (IChonkyAttributes.AttributeType.POWER, 5);
        if (_id == 62) return (IChonkyAttributes.AttributeType.BRAIN, 8);
        if (_id == 63) return (IChonkyAttributes.AttributeType.BRAIN, 2);
        if (_id == 64) return (IChonkyAttributes.AttributeType.BRAIN, 3);
        if (_id == 65) return (IChonkyAttributes.AttributeType.CUTE, 10);
        if (_id == 66) return (IChonkyAttributes.AttributeType.CUTE, 1);
        if (_id == 67) return (IChonkyAttributes.AttributeType.CUTE, 3);
        if (_id == 68) return (IChonkyAttributes.AttributeType.BRAIN, 8);
        if (_id == 69) return (IChonkyAttributes.AttributeType.POWER, 1);
        if (_id == 70) return (IChonkyAttributes.AttributeType.BRAIN, 10);
        if (_id == 71) return (IChonkyAttributes.AttributeType.BRAIN, 7);
        if (_id == 72) return (IChonkyAttributes.AttributeType.POWER, 6);
        if (_id == 73) return (IChonkyAttributes.AttributeType.POWER, 7);
        if (_id == 74) return (IChonkyAttributes.AttributeType.POWER, 7);
        if (_id == 75) return (IChonkyAttributes.AttributeType.POWER, 5);
        if (_id == 76) return (IChonkyAttributes.AttributeType.BRAIN, 9);
        if (_id == 77) return (IChonkyAttributes.AttributeType.BRAIN, 1);
        if (_id == 78) return (IChonkyAttributes.AttributeType.CUTE, 2);
        if (_id == 79) return (IChonkyAttributes.AttributeType.POWER, 9);
        if (_id == 80) return (IChonkyAttributes.AttributeType.BRAIN, 9);
        if (_id == 81) return (IChonkyAttributes.AttributeType.POWER, 2);
        if (_id == 82) return (IChonkyAttributes.AttributeType.BRAIN, 3);
        if (_id == 83) return (IChonkyAttributes.AttributeType.CUTE, 8);
        if (_id == 84) return (IChonkyAttributes.AttributeType.CUTE, 7);
        if (_id == 85) return (IChonkyAttributes.AttributeType.BRAIN, 7);
        if (_id == 86) return (IChonkyAttributes.AttributeType.POWER, 9);
        if (_id == 87) return (IChonkyAttributes.AttributeType.POWER, 4);
        if (_id == 88) return (IChonkyAttributes.AttributeType.WICKED, 5);
        if (_id == 89) return (IChonkyAttributes.AttributeType.BRAIN, 4);
        if (_id == 90) return (IChonkyAttributes.AttributeType.POWER, 1);
        if (_id == 91) return (IChonkyAttributes.AttributeType.WICKED, 8);

        return (IChonkyAttributes.AttributeType.NONE, 0);
    }

    function _getEyesAttribute(uint256 _id)
        internal
        pure
        returns (IChonkyAttributes.AttributeType, uint256)
    {
        if (_id == 0) return (IChonkyAttributes.AttributeType.NONE, 0);

        if (_id == 1) return (IChonkyAttributes.AttributeType.CUTE, 2);
        if (_id == 2) return (IChonkyAttributes.AttributeType.CUTE, 1);
        if (_id == 3) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 4) return (IChonkyAttributes.AttributeType.POWER, 6);
        if (_id == 5) return (IChonkyAttributes.AttributeType.POWER, 5);
        if (_id == 6) return (IChonkyAttributes.AttributeType.WICKED, 7);
        if (_id == 7) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 8) return (IChonkyAttributes.AttributeType.WICKED, 2);
        if (_id == 9) return (IChonkyAttributes.AttributeType.CUTE, 7);
        if (_id == 10) return (IChonkyAttributes.AttributeType.BRAIN, 8);
        if (_id == 11) return (IChonkyAttributes.AttributeType.WICKED, 10);
        if (_id == 12) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 13) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 14) return (IChonkyAttributes.AttributeType.CUTE, 8);
        if (_id == 15) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 16) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 17) return (IChonkyAttributes.AttributeType.WICKED, 8);
        if (_id == 18) return (IChonkyAttributes.AttributeType.BRAIN, 6);
        if (_id == 19) return (IChonkyAttributes.AttributeType.CUTE, 5);
        if (_id == 20) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 21) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 22) return (IChonkyAttributes.AttributeType.WICKED, 4);
        if (_id == 23) return (IChonkyAttributes.AttributeType.BRAIN, 3);
        if (_id == 24) return (IChonkyAttributes.AttributeType.POWER, 3);
        if (_id == 25) return (IChonkyAttributes.AttributeType.POWER, 6);
        if (_id == 26) return (IChonkyAttributes.AttributeType.CUTE, 7);
        if (_id == 27) return (IChonkyAttributes.AttributeType.CUTE, 6);
        if (_id == 28) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 29) return (IChonkyAttributes.AttributeType.BRAIN, 1);
        if (_id == 30) return (IChonkyAttributes.AttributeType.CUTE, 4);
        if (_id == 31) return (IChonkyAttributes.AttributeType.POWER, 3);
        if (_id == 32) return (IChonkyAttributes.AttributeType.BRAIN, 8);
        if (_id == 33) return (IChonkyAttributes.AttributeType.WICKED, 6);
        if (_id == 34) return (IChonkyAttributes.AttributeType.POWER, 9);
        if (_id == 35) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 36) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 37) return (IChonkyAttributes.AttributeType.WICKED, 2);
        if (_id == 38) return (IChonkyAttributes.AttributeType.POWER, 5);
        if (_id == 39) return (IChonkyAttributes.AttributeType.CUTE, 5);
        if (_id == 40) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 41) return (IChonkyAttributes.AttributeType.BRAIN, 7);
        if (_id == 42) return (IChonkyAttributes.AttributeType.WICKED, 10);
        if (_id == 43) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 44) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 45) return (IChonkyAttributes.AttributeType.WICKED, 9);
        if (_id == 46) return (IChonkyAttributes.AttributeType.CUTE, 4);
        if (_id == 47) return (IChonkyAttributes.AttributeType.BRAIN, 8);
        if (_id == 48) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 49) return (IChonkyAttributes.AttributeType.CUTE, 6);
        if (_id == 50) return (IChonkyAttributes.AttributeType.POWER, 5);
        if (_id == 51) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 52) return (IChonkyAttributes.AttributeType.BRAIN, 4);
        if (_id == 53) return (IChonkyAttributes.AttributeType.BRAIN, 9);
        if (_id == 54) return (IChonkyAttributes.AttributeType.POWER, 4);
        if (_id == 55) return (IChonkyAttributes.AttributeType.CUTE, 2);
        if (_id == 56) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 57) return (IChonkyAttributes.AttributeType.POWER, 3);
        if (_id == 58) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 59) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 60) return (IChonkyAttributes.AttributeType.WICKED, 1);
        if (_id == 61) return (IChonkyAttributes.AttributeType.WICKED, 3);

        return (IChonkyAttributes.AttributeType.NONE, 0);
    }

    function _getMouthAttribute(uint256 _id)
        internal
        pure
        returns (IChonkyAttributes.AttributeType, uint256)
    {
        if (_id == 0) return (IChonkyAttributes.AttributeType.NONE, 0);

        if (_id == 1) return (IChonkyAttributes.AttributeType.POWER, 7);
        if (_id == 2) return (IChonkyAttributes.AttributeType.WICKED, 6);
        if (_id == 3) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 4) return (IChonkyAttributes.AttributeType.WICKED, 4);
        if (_id == 5) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 6) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 7) return (IChonkyAttributes.AttributeType.CUTE, 8);
        if (_id == 8) return (IChonkyAttributes.AttributeType.BRAIN, 5);
        if (_id == 9) return (IChonkyAttributes.AttributeType.WICKED, 8);
        if (_id == 10) return (IChonkyAttributes.AttributeType.POWER, 4);
        if (_id == 11) return (IChonkyAttributes.AttributeType.BRAIN, 8);
        if (_id == 12) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 13) return (IChonkyAttributes.AttributeType.POWER, 8);
        if (_id == 14) return (IChonkyAttributes.AttributeType.CUTE, 5);
        if (_id == 15) return (IChonkyAttributes.AttributeType.WICKED, 5);
        if (_id == 16) return (IChonkyAttributes.AttributeType.CUTE, 3);
        if (_id == 17) return (IChonkyAttributes.AttributeType.BRAIN, 1);
        if (_id == 18) return (IChonkyAttributes.AttributeType.POWER, 6);
        if (_id == 19) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 20) return (IChonkyAttributes.AttributeType.BRAIN, 9);
        if (_id == 21) return (IChonkyAttributes.AttributeType.CUTE, 3);
        if (_id == 22) return (IChonkyAttributes.AttributeType.CUTE, 4);
        if (_id == 23) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 24) return (IChonkyAttributes.AttributeType.POWER, 5);
        if (_id == 25) return (IChonkyAttributes.AttributeType.WICKED, 4);
        if (_id == 26) return (IChonkyAttributes.AttributeType.BRAIN, 6);
        if (_id == 27) return (IChonkyAttributes.AttributeType.BRAIN, 3);
        if (_id == 28) return (IChonkyAttributes.AttributeType.BRAIN, 4);
        if (_id == 29) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 30) return (IChonkyAttributes.AttributeType.POWER, 6);
        if (_id == 31) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 32) return (IChonkyAttributes.AttributeType.POWER, 9);
        if (_id == 33) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 34) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 35) return (IChonkyAttributes.AttributeType.WICKED, 3);
        if (_id == 36) return (IChonkyAttributes.AttributeType.BRAIN, 8);
        if (_id == 37) return (IChonkyAttributes.AttributeType.POWER, 9);
        if (_id == 38) return (IChonkyAttributes.AttributeType.WICKED, 7);
        if (_id == 39) return (IChonkyAttributes.AttributeType.BRAIN, 6);
        if (_id == 40) return (IChonkyAttributes.AttributeType.CUTE, 4);
        if (_id == 41) return (IChonkyAttributes.AttributeType.POWER, 4);
        if (_id == 42) return (IChonkyAttributes.AttributeType.BRAIN, 5);
        if (_id == 43) return (IChonkyAttributes.AttributeType.CUTE, 3);
        if (_id == 44) return (IChonkyAttributes.AttributeType.BRAIN, 9);
        if (_id == 45) return (IChonkyAttributes.AttributeType.WICKED, 8);
        if (_id == 46) return (IChonkyAttributes.AttributeType.CUTE, 2);
        if (_id == 47) return (IChonkyAttributes.AttributeType.BRAIN, 2);
        if (_id == 48) return (IChonkyAttributes.AttributeType.CUTE, 1);
        if (_id == 49) return (IChonkyAttributes.AttributeType.CUTE, 1);
        if (_id == 50) return (IChonkyAttributes.AttributeType.WICKED, 1);
        if (_id == 51) return (IChonkyAttributes.AttributeType.WICKED, 5);
        if (_id == 52) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 53) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 54) return (IChonkyAttributes.AttributeType.NONE, 0);

        return (IChonkyAttributes.AttributeType.NONE, 0);
    }

    function _getHatAttribute(uint256 _id)
        internal
        pure
        returns (IChonkyAttributes.AttributeType, uint256)
    {
        if (_id == 0) return (IChonkyAttributes.AttributeType.NONE, 0);

        if (_id == 1) return (IChonkyAttributes.AttributeType.CUTE, 8);
        if (_id == 2) return (IChonkyAttributes.AttributeType.WICKED, 8);
        if (_id == 3) return (IChonkyAttributes.AttributeType.BRAIN, 9);
        if (_id == 4) return (IChonkyAttributes.AttributeType.CUTE, 4);
        if (_id == 5) return (IChonkyAttributes.AttributeType.WICKED, 9);
        if (_id == 6) return (IChonkyAttributes.AttributeType.WICKED, 3);
        if (_id == 7) return (IChonkyAttributes.AttributeType.CUTE, 7);
        if (_id == 8) return (IChonkyAttributes.AttributeType.POWER, 2);
        if (_id == 9) return (IChonkyAttributes.AttributeType.CUTE, 1);
        if (_id == 10) return (IChonkyAttributes.AttributeType.POWER, 4);
        if (_id == 11) return (IChonkyAttributes.AttributeType.POWER, 6);
        if (_id == 12) return (IChonkyAttributes.AttributeType.POWER, 2);
        if (_id == 13) return (IChonkyAttributes.AttributeType.WICKED, 10);
        if (_id == 14) return (IChonkyAttributes.AttributeType.POWER, 10);
        if (_id == 15) return (IChonkyAttributes.AttributeType.WICKED, 3);
        if (_id == 16) return (IChonkyAttributes.AttributeType.BRAIN, 2);
        if (_id == 17) return (IChonkyAttributes.AttributeType.WICKED, 6);
        if (_id == 18) return (IChonkyAttributes.AttributeType.WICKED, 5);
        if (_id == 19) return (IChonkyAttributes.AttributeType.BRAIN, 9);
        if (_id == 20) return (IChonkyAttributes.AttributeType.POWER, 2);
        if (_id == 21) return (IChonkyAttributes.AttributeType.WICKED, 3);
        if (_id == 22) return (IChonkyAttributes.AttributeType.POWER, 6);
        if (_id == 23) return (IChonkyAttributes.AttributeType.WICKED, 4);
        if (_id == 24) return (IChonkyAttributes.AttributeType.BRAIN, 2);
        if (_id == 25) return (IChonkyAttributes.AttributeType.WICKED, 7);
        if (_id == 26) return (IChonkyAttributes.AttributeType.WICKED, 4);
        if (_id == 27) return (IChonkyAttributes.AttributeType.POWER, 5);
        if (_id == 28) return (IChonkyAttributes.AttributeType.POWER, 10);
        if (_id == 29) return (IChonkyAttributes.AttributeType.WICKED, 6);
        if (_id == 30) return (IChonkyAttributes.AttributeType.WICKED, 6);
        if (_id == 31) return (IChonkyAttributes.AttributeType.CUTE, 6);
        if (_id == 32) return (IChonkyAttributes.AttributeType.POWER, 1);
        if (_id == 33) return (IChonkyAttributes.AttributeType.CUTE, 9);
        if (_id == 34) return (IChonkyAttributes.AttributeType.BRAIN, 7);
        if (_id == 35) return (IChonkyAttributes.AttributeType.WICKED, 5);
        if (_id == 36) return (IChonkyAttributes.AttributeType.CUTE, 3);
        if (_id == 37) return (IChonkyAttributes.AttributeType.POWER, 3);
        if (_id == 38) return (IChonkyAttributes.AttributeType.BRAIN, 5);
        if (_id == 39) return (IChonkyAttributes.AttributeType.WICKED, 5);
        if (_id == 40) return (IChonkyAttributes.AttributeType.WICKED, 8);
        if (_id == 41) return (IChonkyAttributes.AttributeType.CUTE, 1);
        if (_id == 42) return (IChonkyAttributes.AttributeType.WICKED, 4);
        if (_id == 43) return (IChonkyAttributes.AttributeType.BRAIN, 7);
        if (_id == 44) return (IChonkyAttributes.AttributeType.CUTE, 9);
        if (_id == 45) return (IChonkyAttributes.AttributeType.BRAIN, 4);
        if (_id == 46) return (IChonkyAttributes.AttributeType.POWER, 6);
        if (_id == 47) return (IChonkyAttributes.AttributeType.BRAIN, 5);
        if (_id == 48) return (IChonkyAttributes.AttributeType.POWER, 9);
        if (_id == 49) return (IChonkyAttributes.AttributeType.CUTE, 3);
        if (_id == 50) return (IChonkyAttributes.AttributeType.CUTE, 4);
        if (_id == 51) return (IChonkyAttributes.AttributeType.WICKED, 1);
        if (_id == 52) return (IChonkyAttributes.AttributeType.BRAIN, 3);
        if (_id == 53) return (IChonkyAttributes.AttributeType.WICKED, 8);
        if (_id == 54) return (IChonkyAttributes.AttributeType.CUTE, 2);
        if (_id == 55) return (IChonkyAttributes.AttributeType.POWER, 4);
        if (_id == 56) return (IChonkyAttributes.AttributeType.WICKED, 3);
        if (_id == 57) return (IChonkyAttributes.AttributeType.POWER, 8);
        if (_id == 58) return (IChonkyAttributes.AttributeType.CUTE, 8);
        if (_id == 59) return (IChonkyAttributes.AttributeType.CUTE, 7);
        if (_id == 60) return (IChonkyAttributes.AttributeType.POWER, 2);
        if (_id == 61) return (IChonkyAttributes.AttributeType.CUTE, 4);
        if (_id == 62) return (IChonkyAttributes.AttributeType.BRAIN, 1);
        if (_id == 63) return (IChonkyAttributes.AttributeType.POWER, 8);
        if (_id == 64) return (IChonkyAttributes.AttributeType.CUTE, 2);
        if (_id == 65) return (IChonkyAttributes.AttributeType.CUTE, 4);
        if (_id == 66) return (IChonkyAttributes.AttributeType.CUTE, 3);
        if (_id == 67) return (IChonkyAttributes.AttributeType.WICKED, 3);
        if (_id == 68) return (IChonkyAttributes.AttributeType.BRAIN, 6);
        if (_id == 69) return (IChonkyAttributes.AttributeType.POWER, 8);
        if (_id == 70) return (IChonkyAttributes.AttributeType.WICKED, 8);
        if (_id == 71) return (IChonkyAttributes.AttributeType.WICKED, 2);
        if (_id == 72) return (IChonkyAttributes.AttributeType.POWER, 3);
        if (_id == 73) return (IChonkyAttributes.AttributeType.CUTE, 1);
        if (_id == 74) return (IChonkyAttributes.AttributeType.BRAIN, 2);
        if (_id == 75) return (IChonkyAttributes.AttributeType.CUTE, 10);
        if (_id == 76) return (IChonkyAttributes.AttributeType.CUTE, 9);
        if (_id == 77) return (IChonkyAttributes.AttributeType.CUTE, 1);
        if (_id == 78) return (IChonkyAttributes.AttributeType.CUTE, 2);
        if (_id == 79) return (IChonkyAttributes.AttributeType.WICKED, 3);
        if (_id == 80) return (IChonkyAttributes.AttributeType.BRAIN, 3);
        if (_id == 81) return (IChonkyAttributes.AttributeType.BRAIN, 10);
        if (_id == 82) return (IChonkyAttributes.AttributeType.POWER, 9);
        if (_id == 83) return (IChonkyAttributes.AttributeType.POWER, 8);
        if (_id == 84) return (IChonkyAttributes.AttributeType.BRAIN, 8);
        if (_id == 85) return (IChonkyAttributes.AttributeType.POWER, 6);
        if (_id == 86) return (IChonkyAttributes.AttributeType.POWER, 7);
        if (_id == 87) return (IChonkyAttributes.AttributeType.BRAIN, 9);
        if (_id == 88) return (IChonkyAttributes.AttributeType.CUTE, 6);
        if (_id == 89) return (IChonkyAttributes.AttributeType.POWER, 7);
        if (_id == 90) return (IChonkyAttributes.AttributeType.CUTE, 4);
        if (_id == 91) return (IChonkyAttributes.AttributeType.BRAIN, 3);
        if (_id == 92) return (IChonkyAttributes.AttributeType.BRAIN, 2);
        if (_id == 93) return (IChonkyAttributes.AttributeType.POWER, 9);
        if (_id == 94) return (IChonkyAttributes.AttributeType.POWER, 4);
        if (_id == 95) return (IChonkyAttributes.AttributeType.CUTE, 10);
        if (_id == 96) return (IChonkyAttributes.AttributeType.POWER, 2);

        return (IChonkyAttributes.AttributeType.NONE, 0);
    }

    function _getWingsAttribute(uint256 _id)
        internal
        pure
        returns (IChonkyAttributes.AttributeType, uint256)
    {
        if (_id == 0) return (IChonkyAttributes.AttributeType.NONE, 0);

        if (_id == 1) return (IChonkyAttributes.AttributeType.CUTE, 6);
        if (_id == 2) return (IChonkyAttributes.AttributeType.WICKED, 8);
        if (_id == 3) return (IChonkyAttributes.AttributeType.CUTE, 4);
        if (_id == 4) return (IChonkyAttributes.AttributeType.POWER, 9);
        if (_id == 5) return (IChonkyAttributes.AttributeType.WICKED, 4);
        if (_id == 6) return (IChonkyAttributes.AttributeType.POWER, 4);
        if (_id == 7) return (IChonkyAttributes.AttributeType.CUTE, 7);
        if (_id == 8) return (IChonkyAttributes.AttributeType.BRAIN, 5);
        if (_id == 9) return (IChonkyAttributes.AttributeType.BRAIN, 9);

        return (IChonkyAttributes.AttributeType.NONE, 0);
    }

    function _getSetAttribute(uint256 _id)
        internal
        pure
        returns (IChonkyAttributes.AttributeType, uint256)
    {
        if (_id == 0) return (IChonkyAttributes.AttributeType.NONE, 0);

        if (_id == 1) return (IChonkyAttributes.AttributeType.POWER, 1);
        if (_id == 2) return (IChonkyAttributes.AttributeType.CUTE, 3);
        if (_id == 3) return (IChonkyAttributes.AttributeType.BRAIN, 5);
        if (_id == 4) return (IChonkyAttributes.AttributeType.WICKED, 5);
        if (_id == 5) return (IChonkyAttributes.AttributeType.CUTE, 5);
        if (_id == 6) return (IChonkyAttributes.AttributeType.POWER, 5);
        if (_id == 7) return (IChonkyAttributes.AttributeType.POWER, 3);
        if (_id == 8) return (IChonkyAttributes.AttributeType.CUTE, 2);
        if (_id == 9) return (IChonkyAttributes.AttributeType.BRAIN, 2);
        if (_id == 10) return (IChonkyAttributes.AttributeType.POWER, 1);
        if (_id == 11) return (IChonkyAttributes.AttributeType.BRAIN, 1);
        if (_id == 12) return (IChonkyAttributes.AttributeType.WICKED, 5);
        if (_id == 13) return (IChonkyAttributes.AttributeType.WICKED, 2);
        if (_id == 14) return (IChonkyAttributes.AttributeType.POWER, 2);
        if (_id == 15) return (IChonkyAttributes.AttributeType.BRAIN, 2);
        if (_id == 16) return (IChonkyAttributes.AttributeType.BRAIN, 5);
        if (_id == 17) return (IChonkyAttributes.AttributeType.BRAIN, 3);
        if (_id == 18) return (IChonkyAttributes.AttributeType.BRAIN, 5);
        if (_id == 19) return (IChonkyAttributes.AttributeType.WICKED, 1);
        if (_id == 20) return (IChonkyAttributes.AttributeType.WICKED, 3);
        if (_id == 21) return (IChonkyAttributes.AttributeType.CUTE, 5);
        if (_id == 22) return (IChonkyAttributes.AttributeType.CUTE, 1);
        if (_id == 23) return (IChonkyAttributes.AttributeType.WICKED, 3);
        if (_id == 24) return (IChonkyAttributes.AttributeType.POWER, 2);
        if (_id == 25) return (IChonkyAttributes.AttributeType.POWER, 2);
        if (_id == 26) return (IChonkyAttributes.AttributeType.POWER, 1);
        if (_id == 27) return (IChonkyAttributes.AttributeType.WICKED, 2);
        if (_id == 28) return (IChonkyAttributes.AttributeType.CUTE, 2);
        if (_id == 29) return (IChonkyAttributes.AttributeType.CUTE, 3);
        if (_id == 30) return (IChonkyAttributes.AttributeType.POWER, 5);
        if (_id == 31) return (IChonkyAttributes.AttributeType.WICKED, 3);
        if (_id == 32) return (IChonkyAttributes.AttributeType.POWER, 2);
        if (_id == 33) return (IChonkyAttributes.AttributeType.BRAIN, 5);
        if (_id == 34) return (IChonkyAttributes.AttributeType.WICKED, 3);
        if (_id == 35) return (IChonkyAttributes.AttributeType.CUTE, 1);
        if (_id == 36) return (IChonkyAttributes.AttributeType.POWER, 1);
        if (_id == 37) return (IChonkyAttributes.AttributeType.POWER, 5);
        if (_id == 38) return (IChonkyAttributes.AttributeType.POWER, 5);
        if (_id == 39) return (IChonkyAttributes.AttributeType.WICKED, 5);
        if (_id == 40) return (IChonkyAttributes.AttributeType.CUTE, 5);
        if (_id == 41) return (IChonkyAttributes.AttributeType.POWER, 3);
        if (_id == 42) return (IChonkyAttributes.AttributeType.CUTE, 3);
        if (_id == 43) return (IChonkyAttributes.AttributeType.POWER, 3);
        if (_id == 44) return (IChonkyAttributes.AttributeType.POWER, 3);
        if (_id == 45) return (IChonkyAttributes.AttributeType.BRAIN, 5);
        if (_id == 46) return (IChonkyAttributes.AttributeType.CUTE, 3);
        if (_id == 47) return (IChonkyAttributes.AttributeType.POWER, 5);
        if (_id == 48) return (IChonkyAttributes.AttributeType.POWER, 2);
        if (_id == 49) return (IChonkyAttributes.AttributeType.BRAIN, 5);
        if (_id == 50) return (IChonkyAttributes.AttributeType.CUTE, 3);
        if (_id == 51) return (IChonkyAttributes.AttributeType.CUTE, 1);
        if (_id == 52) return (IChonkyAttributes.AttributeType.POWER, 3);
        if (_id == 53) return (IChonkyAttributes.AttributeType.CUTE, 1);
        if (_id == 54) return (IChonkyAttributes.AttributeType.BRAIN, 3);
        if (_id == 55) return (IChonkyAttributes.AttributeType.POWER, 3);
        if (_id == 56) return (IChonkyAttributes.AttributeType.POWER, 2);
        if (_id == 57) return (IChonkyAttributes.AttributeType.WICKED, 3);
        if (_id == 58) return (IChonkyAttributes.AttributeType.CUTE, 0);

        return (IChonkyAttributes.AttributeType.NONE, 0);
    }

    function _addAttributeValue(
        uint256[4] memory _array,
        uint256 _value,
        IChonkyAttributes.AttributeType _valueType
    ) internal pure returns (uint256[4] memory) {
        if (_valueType != IChonkyAttributes.AttributeType.NONE) {
            _array[uint256(_valueType) - 1] += _value;
        }

        return _array;
    }

    function getAttributeValues(uint256[12] memory _attributes, uint256 _setId)
        public
        pure
        returns (uint256[4] memory result)
    {
        uint256 value;
        IChonkyAttributes.AttributeType valueType;

        (valueType, value) = _getWingsAttribute(_attributes[2]);
        result = _addAttributeValue(result, value, valueType);

        (valueType, value) = _getBodyAttribute(_attributes[6]);
        result = _addAttributeValue(result, value, valueType);

        (valueType, value) = _getMouthAttribute(_attributes[7]);
        result = _addAttributeValue(result, value, valueType);

        (valueType, value) = _getEyesAttribute(_attributes[8]);
        result = _addAttributeValue(result, value, valueType);

        (valueType, value) = _getHatAttribute(_attributes[9]);
        result = _addAttributeValue(result, value, valueType);

        (valueType, value) = _getSetAttribute(_setId);
        result = _addAttributeValue(result, value, valueType);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IChonkySet} from "./interface/IChonkySet.sol";

contract ChonkySet is IChonkySet {
    function getSetId(uint256 _genome) external pure returns (uint256) {
        return _getSetId(_genome);
    }

    function getSetFromGenome(uint256 _genome)
        external
        pure
        returns (string memory)
    {
        return _getSetFromId(_getSetId(_genome));
    }

    function getSetFromId(uint256 _setId)
        external
        pure
        returns (string memory)
    {
        return _getSetFromId(_setId);
    }

    function _getSetId(uint256 _genome) internal pure returns (uint256) {
        if (_genome == 0x025e716c06d02c) return 1;
        if (_genome == 0x02c8cca802518f) return 2;
        if (_genome == 0x38e108027089) return 3;
        if (_genome == 0x51ad0c0d7065) return 4;
        if (_genome == 0x704e0ea50332) return 5;
        if (_genome == 0xec821004d052) return 6;
        if (_genome == 0x0398a060045048) return 7;
        if (_genome == 0x05836b2008d04c) return 8;
        if (_genome == 0x016daf22043029) return 9;
        if (_genome == 0x635b242d4063) return 10;
        if (_genome == 0x018ac826022089) return 11;
        if (_genome == 0x035edd5c064089) return 12;
        if (_genome == 0x0190002a000049) return 13;
        if (_genome == 0x01bcda2e0e8083) return 14;
        if (_genome == 0x028e4d4608d068) return 15;
        if (_genome == 0x0402a45842e02c) return 16;
        if (_genome == 0x04f16530657022) return 17;
        if (_genome == 0x013bd48e40f02e) return 18;
        if (_genome == 0xf15712212084) return 19;
        if (_genome == 0x01de0966016582) return 20;
        if (_genome == 0x03b39e3407208f) return 21;
        if (_genome == 0x0228cc3608304a) return 22;
        if (_genome == 0x01eb7338017065) return 23;
        if (_genome == 0x055e587a084032) return 24;
        if (_genome == 0x04a81aa20e3029) return 25;
        if (_genome == 0x8dca3a044022) return 26;
        if (_genome == 0x01504f2c07006c) return 27;
        if (_genome == 0x02d6224c10304a) return 28;
        if (_genome == 0x012d101e0b2084) return 29;
        if (_genome == 0x01c7954e028086) return 30;
        if (_genome == 0x251906042067) return 31;
        if (_genome == 0x059e125704d065) return 32;
        if (_genome == 0x0510008c000049) return 33;
        if (_genome == 0x038974520c408b) return 34;
        if (_genome == 0x0326df280cd086) return 35;
        if (_genome == 0x03ca296204d050) return 36;
        if (_genome == 0x03ff216a058092) return 37;
        if (_genome == 0x04545a76104062) return 38;
        if (_genome == 0x046a8078041067) return 39;
        if (_genome == 0x04b6d18200508f) return 40;
        if (_genome == 0x030ca68808d042) return 41;
        if (_genome == 0x168502c5802f) return 42;
        if (_genome == 0x052e28920ea089) return 43;
        if (_genome == 0x05380894022085) return 44;
        if (_genome == 0x054cea9808d023) return 45;
        if (_genome == 0x02ea56160eb08a) return 46;
        if (_genome == 0x0560009e02a082) return 47;
        if (_genome == 0x023f63680b0090) return 48;
        if (_genome == 0x057d6ca0044983) return 49;
        if (_genome == 0x01fc6ba6aa502d) return 50;
        if (_genome == 0x031b320a00104b) return 51;
        if (_genome == 0x05bd27480ea089) return 52;
        if (_genome == 0x40db5e110028) return 53;
        if (_genome == 0x02b157aa0eb021) return 54;
        if (_genome == 0x05dae8aca25192) return 55;
        if (_genome == 0x05e568ae048023) return 56;
        if (_genome == 0x011875b6129067) return 57;

        return 0;
    }

    function _getSetFromId(uint256 _id) internal pure returns (string memory) {
        if (_id == 1) return "American Football";
        if (_id == 2) return "Angel";
        if (_id == 3) return "Astronaut";
        if (_id == 4) return "Baron Samedi";
        if (_id == 5) return "Bee";
        if (_id == 6) return "Black Kabuto";
        if (_id == 7) return "Blue Ninja";
        if (_id == 8) return "Bubble Tea";
        if (_id == 9) return "Captain";
        if (_id == 10) return "Caveman";
        if (_id == 11) return "Chef";
        if (_id == 12) return "Chonky Plant";
        if (_id == 13) return "Cloth Monster";
        if (_id == 14) return "Cowboy";
        if (_id == 15) return "Crazy Scientist";
        if (_id == 16) return "Cyber Hacker";
        if (_id == 17) return "Cyberpunk";
        if (_id == 18) return "Cyborg";
        if (_id == 19) return "Dark Magician";
        if (_id == 20) return "Devil";
        if (_id == 21) return "Diver";
        if (_id == 22) return "Doraemon";
        if (_id == 23) return "Dracula";
        if (_id == 24) return "Ese Sombrero";
        if (_id == 25) return "Gentleman";
        if (_id == 26) return "Golden Tooth";
        if (_id == 27) return "Jack-O-Lantern";
        if (_id == 28) return "Japanese Drummer";
        if (_id == 29) return "Jester";
        if (_id == 30) return "King";
        if (_id == 31) return "Lake Monster";
        if (_id == 32) return "Luffy";
        if (_id == 33) return "Mr Roboto";
        if (_id == 34) return "Mushroom Guy";
        if (_id == 35) return "New Year Outfit";
        if (_id == 36) return "Old Lady";
        if (_id == 37) return "Pharaoh";
        if (_id == 38) return "Pirate";
        if (_id == 39) return "Plague Doctor";
        if (_id == 40) return "Rainbow Love";
        if (_id == 41) return "Red Samurai";
        if (_id == 42) return "Retro";
        if (_id == 43) return "Roman";
        if (_id == 44) return "Safari Hunter";
        if (_id == 45) return "Sherlock";
        if (_id == 46) return "Snow Dude";
        if (_id == 47) return "Sparta";
        if (_id == 48) return "Spicy Man";
        if (_id == 49) return "Steampunk";
        if (_id == 50) return "Swimmer";
        if (_id == 51) return "Tanuki";
        if (_id == 52) return "Tin Man";
        if (_id == 53) return "Tired Dad";
        if (_id == 54) return "Tron Boy";
        if (_id == 55) return "Valkyrie";
        if (_id == 56) return "Viking";
        if (_id == 57) return "Zombie";

        return "";
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IChonkyMetadata {
    function buildTokenURI(
        uint256 id,
        uint256 genomeId,
        uint256 genome,
        string memory CID,
        address chonkySet,
        address chonkyAttributes
    ) external pure returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IChonkySet {
    function getSetId(uint256 _genome) external pure returns (uint256);

    function getSetFromGenome(uint256 _genome)
        external
        pure
        returns (string memory);

    function getSetFromId(uint256 _setId) external pure returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IChonkyAttributes {
    enum AttributeType {
        NONE,
        BRAIN,
        CUTE,
        POWER,
        WICKED
    }

    function getAttributeValues(uint256[12] memory _attributes, uint256 _setId)
        external
        pure
        returns (uint256[4] memory result);
}