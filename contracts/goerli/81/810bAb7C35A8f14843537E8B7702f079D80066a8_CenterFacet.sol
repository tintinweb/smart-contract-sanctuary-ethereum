// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**************************************************************\
 * CenterFacet authored by Sibling Labs
 * Version 0.4.0
 * 
 * This facet contract has been written specifically for
 * ERC721A-DIAMOND-TEMPLATE by Sibling Labs
/**************************************************************/

import { GlobalState } from "../libraries/GlobalState.sol";
import { CenterFacetLib } from "../libraries/CenterFacetLib.sol";
import { SaleHandlerLib } from "../libraries/SaleHandlerLib.sol";
import { AllowlistLib } from "../libraries/AllowlistLib.sol";

import "../interfaces/ICenterFacet.sol";

contract CenterFacet is ICenterFacet {
    // VARIABLE GETTERS //

    function maxSupply() external view override returns (uint256) {
        return CenterFacetLib.getState().maxSupply;
    }

    function reservedRemaining() external view override returns (uint256) {
        return CenterFacetLib.getState().reservedRemaining;
    }

    function walletCap() external view override returns (uint256) {
        return CenterFacetLib.getState().walletCap;
    }

    function priceAL() external view override returns (uint256) {
        return CenterFacetLib.getState().price[0];
    }

    function price() external view override returns (uint256) {
        return CenterFacetLib.getState().price[1];
    }

    function burnStatus() external view override returns (bool) {
        return CenterFacetLib.getState().burnStatus;
    }

    function ERC721AFacet() external view override returns (address) {
        return CenterFacetLib.getState().ERC721AFacet;
    }

    function level(uint256 tokenId) external view override returns (uint256) {
        require(CenterFacetLib._exists(tokenId), "Given tokenId doesn't exist");
        return CenterFacetLib.getState().levels[tokenId];
    }

    // SETUP & ADMIN FUNCTIONS //

    function setPrices(uint256 _priceAL, uint256 _price) external override {
        GlobalState.requireCallerIsAdmin();
        CenterFacetLib.getState().price[0] = _priceAL;
        CenterFacetLib.getState().price[1] = _price;
    }

    function setWalletCap(uint256 _walletCap) external override {
        GlobalState.requireCallerIsAdmin();
        CenterFacetLib.getState().walletCap = _walletCap;
    }

    function toggleBurnStatus() external override {
        GlobalState.requireCallerIsAdmin();
        CenterFacetLib.getState().burnStatus = !CenterFacetLib.getState().burnStatus;
    }

    function setBaseURI(string memory URI) external {
        GlobalState.requireCallerIsAdmin();
        CenterFacetLib.getState().baseURI = URI;
    }

    function setERC721AFacet(address _ERC721AFacet) external override {
        GlobalState.requireCallerIsAdmin();
        CenterFacetLib.getState().ERC721AFacet = _ERC721AFacet;
    }

    function reserve(uint256 amount) external override {
        GlobalState.requireCallerIsAdmin();
        int256 check = int256(CenterFacetLib.getState().reservedRemaining) - int256(amount);
        require(check >= 0, "Not enough reserved mint remaining");
        CenterFacetLib.getState().reservedRemaining -= amount;
        CenterFacetLib.safeMint(amount);
    }

    // PUBLIC FUNCTIONS //

    function mint(uint256 amount, bytes32[] calldata _merkleProof) external override payable {
        GlobalState.requireContractIsNotPaused();
        uint256 phase;
        if(SaleHandlerLib.isPrivSaleActive()) {
            phase = 1;
        }
        else if(SaleHandlerLib.isPublicSaleActive()) {
            phase = 2;
        }
        require(phase == 1 || phase == 2, "CenterFacet: Sale is not active");
        if (phase == 1) AllowlistLib.requireValidProof(_merkleProof);

        CenterFacetLib.state storage s = CenterFacetLib.getState();
        uint256 _price = s.price[phase - 1];
        require(msg.value == _price * amount, "CenterFacet: incorrect amount of ether sent");

        uint256 numberMinted = CenterFacetLib._numberMinted(msg.sender);
        require(
            amount + numberMinted <=  s.walletCap,
            string(
                abi.encodePacked(
                    "CenterFacet: maximum tokens per wallet during the sale is ",
                    CenterFacetLib._toString(s.walletCap)
                )
            )
        );
        CenterFacetLib.safeMint(amount);
    }

    function burn(uint256 tokenId) external override {
        GlobalState.requireContractIsNotPaused();
        require(CenterFacetLib.getState().burnStatus, "CenterFacet: token burning is not available now");
        CenterFacetLib._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(CenterFacetLib._exists(tokenId), "CenterFacet: token does not exist");

        string memory baseURI = CenterFacetLib.getState().baseURI;
        return string(abi.encodePacked(baseURI, CenterFacetLib._toString(tokenId)));
    }

    function transferFrom(address from, address to, uint256 tokenId) external override payable {
        CenterFacetLib._beforeTokenTransfer(from, to, tokenId, abi.encodeWithSignature(
            "_transferFrom(address,address,uint256)", from, to, tokenId
        ));
    }
    function safeTransferFrom(address from, address to, uint256 tokenId) external override payable {
        CenterFacetLib._beforeTokenTransfer(from, to, tokenId, abi.encodeWithSignature(
            "_safeTransferFrom(address,address,uint256)", from, to, tokenId
        ));
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) external override payable {
        CenterFacetLib._beforeTokenTransfer(from, to, tokenId, abi.encodeWithSignature(
            "_safeTransferFrom(address,address,uint256,bytes)", from, to, tokenId, _data
        ));
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**************************************************************\
 * Global Storage Library for NFT Smart Contracts
 * Authored by Sibling Labs
 * Version 0.2.1
 * 
 * This library is designed to provide diamond storage and
 * shared functionality to all facets of a diamond used for an
 * NFT collection.
/**************************************************************/

library GlobalState {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("globalstate.storage");

    struct state {
        address owner;
        mapping(address => bool) admins;

        bool paused;
    }

    /**
    * @dev Return stored state struct.
    */
    function getState() internal pure returns (state storage _state) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            _state.slot := position
        }
    }

    // GLOBAL FUNCTIONS //

    /**
    * @dev Returns true if provided address is an admin or the
    *      contract owner.
    */
    function isAdmin(address _addr) internal view returns (bool) {
        state storage s = getState();
        return s.owner == _addr || s.admins[_addr];
    }

    /**
    * @dev Reverts if caller is not an admin or contract owner.
    */
    function requireCallerIsAdmin() internal view {
        require(isAdmin(msg.sender), "GlobalState: caller is not admin or owner");
    }

    /**
    * @dev Reverts if contract is paused.
    */
    function requireContractIsNotPaused() internal view {
        require(!getState().paused || isAdmin(msg.sender), "GlobalState: contract is paused");
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**************************************************************\
 * CenterFacetLib authored by Sibling Labs
 * Version 0.2.0
 * 
 * This library is designed to work in conjunction with
 * CenterFacet - it facilitates diamond storage and shared
 * functionality associated with CenterFacet.
/**************************************************************/

import "erc721a-upgradeable/contracts/ERC721AStorage.sol";

import { GlobalState } from "../libraries/GlobalState.sol";

library CenterFacetLib {

    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("tokenfacet.storage");

    event merge(uint256 tokenId, uint256 level, address sender);

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

    struct state {

        uint256 maxSupply;
        uint256 reservedRemaining;
        uint256 walletCap;
        uint256[] price;
        string baseURI;
        bool burnStatus;

        mapping(uint256 => uint256) levels;

        address ERC721AFacet;

    }

    /**
    * @dev Return stored state struct.
    */
    function getState() internal pure returns (state storage _state) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            _state.slot := position
        }
    }

    // Imported Functions from ERC721A //

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        uint256 _BITPOS_NUMBER_MINTED = 64;
        uint256 _BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;

        return
            (ERC721AStorage.layout()._packedAddressData[owner] >> _BITPOS_NUMBER_MINTED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * @dev Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view returns (uint256) {
        uint256 startTokenId = 0;

        // Counter underflow is impossible as `_currentIndex` does not decrement,
        // and it is initialized to `_startTokenId()`.
        unchecked {
            return ERC721AStorage.layout()._currentIndex - startTokenId;
        }
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted. See {_mint}.
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        uint256 _BITMASK_BURNED = 1 << 224;
        uint256 startTokenId = 0;
        
        return
            startTokenId <= tokenId &&
            tokenId < ERC721AStorage.layout()._currentIndex && // If within bounds,
            ERC721AStorage.layout()._packedOwnerships[tokenId] & _BITMASK_BURNED == 0; // and not burned.
    }

    /**
     * @dev Converts a uint256 to its ASCII string decimal representation.
     */
    function _toString(uint256 value) internal pure returns (string memory str) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit),
            // but we allocate 0x80 bytes to keep the free memory pointer 32-byte word aligned.
            // We will need 1 32-byte word to store the length,
            // and 3 32-byte words to store a maximum of 78 digits. Total: 0x20 + 3 * 0x20 = 0x80.
            str := add(mload(0x40), 0x80)
            // Update the free memory pointer to allocate.
            mstore(0x40, str)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
    }

    // Delegatecall to ERC721AFacet //

    function tokensOfOwner(address owner) internal returns (uint256[] memory) {
         return abi.decode(
            callTokenFacet(
                abi.encodeWithSignature(
                    "_tokensOfOwner(address)", 
                    owner)),
            (uint256[])
        );
    }

    function balanceOf(address owner) internal returns (uint256) {
        return abi.decode(
            callTokenFacet(
                abi.encodeWithSignature(
                    "_balanceOf(address)", 
                    owner)),
            (uint256)
        );
    }

    // Internal Functionality //

    function callTokenFacet(bytes memory callData) internal returns (bytes memory) {
        (bool success, bytes memory data) = getState().ERC721AFacet.delegatecall(callData);
        require(success, "CenterFacet: delegate call from CenterFacet to ERC721AFacet failed");
        return data;
    }

    function safeMint(uint256 amount) internal {
        uint256[] memory three;
        uint256[] memory four;
        require(_totalMinted() + amount <= getState().maxSupply, "Too few tokens remaining");
        callTokenFacet(abi.encodeWithSignature("__safeMint(address,uint256)", msg.sender, amount));
        uint256 balance = balanceOf(msg.sender);
        for(uint256 i = 0; i < balance/2; i++) {
            (three, four) = getSeparateByLevel(msg.sender);
            if(three.length > 1) {
                _burn(three[0]);
                getState().levels[three[1]]++;
                emit merge(three[1], 4, msg.sender);
                if(four.length > 0){
                    _burn(three[1]);
                    getState().levels[four[0]]++;
                    emit merge(four[0], 5, msg.sender);
                }
            }
            if(four.length > 1) {
                _burn(four[0]);
                getState().levels[four[1]]++;
                emit merge(four[1], 5, msg.sender);
            }
        }
    }

    function _burn(uint256 tokenId) internal {
        callTokenFacet(abi.encodeWithSignature("__burn(uint256,bool)", tokenId, true));
    }

    function __burn(uint256 tokenId) internal {
        callTokenFacet(abi.encodeWithSignature("__burn(uint256)", tokenId));
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, bytes memory _delegateCall) internal {
        require(_exists(tokenId), "Given tokenId does not exist");
        GlobalState.requireContractIsNotPaused();
        uint256 level = getState().levels[tokenId];
        if(level == 2){
            getState().ERC721AFacet.delegatecall(_delegateCall);
        }
        if (level == 1) {
            _mergeFour(from, to, tokenId, _delegateCall);
        }
        if (level == 0) {
            _mergeThree(from, to, tokenId, _delegateCall);
        }
    }

    function _mergeFour(address from, address to, uint256 tokenId, bytes memory _delegateCall) internal {
        (uint256[] memory three, uint256[] memory four) = getSeparateByLevel(to);
        if(four.length > 0) {
            _burn(tokenId);
            getState().levels[four[0]]++;
            emit merge(four[0], 5,from);
        }
        else {
            getState().ERC721AFacet.delegatecall(_delegateCall);
        }
    }

    function _mergeThree(address from, address to, uint256 tokenId, bytes memory _delegateCall) internal {
        (uint256[] memory three, uint256[] memory four) = getSeparateByLevel(to);
        if(three.length > 0) {
            _burn(tokenId);
            getState().levels[three[0]]++;
            emit merge(three[0], 4, from);
            if(four.length > 0){
                __burn(three[0]);
                getState().levels[four[0]]++;
                emit merge(four[0], 5, from);
            }
        }
        else {
            getState().ERC721AFacet.delegatecall(_delegateCall);
        }
    }

    // SPECIAL FUNCTIONALITY FOR MERGE //

    function getSeparateByLevel(address owner) internal returns (uint256[] memory threeLevel, uint256[] memory fourLevel) {
        uint256[] memory tokenIds = tokensOfOwner(owner);
        bytes memory three;
        bytes memory four;
        for(uint256 i = 0; i < tokenIds.length; i++) {
            uint256 level = getState().levels[tokenIds[i]];
            if (level == 0) {
                three = abi.encodePacked(three, tokenIds[i]);
            }
            else if (level == 1) {
                four = abi.encodePacked(four, tokenIds[i]);
            }
        }
        threeLevel = new uint256[](three.length/32);
        fourLevel = new uint256[](four.length/32);
        for(uint256 i = 0; i < threeLevel.length; i++) {
            uint256 tokenId;
            uint256 currentStartingIndex = 0x20*(i+1);
            assembly {
                tokenId := mload(add(three, currentStartingIndex))
            }
            threeLevel[i] = tokenId;
        }
        for(uint256 i = 0; i < fourLevel.length; i++) {
            uint256 tokenId;
            uint256 currentStartingIndex = 0x20*(i+1);
            assembly {
                tokenId := mload(add(four, currentStartingIndex))
            }
            fourLevel[i] = tokenId;
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**************************************************************\
 * SaleHandlerLib authored by Sibling Labs
 * Version 0.2.0
 * 
 * This library is designed to work in conjunction with
 * SaleHandlerFacet - it facilitates diamond storage and shared
 * functionality associated with SaleHandlerFacet.
/**************************************************************/

library SaleHandlerLib {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("salehandlerlibrary.storage");

    struct state {
        uint256 privSaleLength;
        uint256 publicSaleLength;
        uint256 saleTimestamp;
    }

    /**
    * @dev Return stored state struct.
    */
    function getState() internal pure returns (state storage _state) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            _state.slot := position
        }
    }

    /**
    * @dev Returns a boolean indicating whether the private sale
    *      phase is currently active.
    */
    function isPrivSaleActive() internal view returns (bool) {
        state storage s = getState();
        return
            s.saleTimestamp != 0 &&
            block.timestamp >= s.saleTimestamp &&
            block.timestamp < s.saleTimestamp + s.privSaleLength;
    }

    /**
    * @dev Returns whether the public sale is currently
    *      active. If the publicSaleLength variable is
    *      set to 0, the public sale will continue
    *      forever.
    */
    function isPublicSaleActive() internal view returns (bool) {
        state storage s = getState();
        return
            s.saleTimestamp != 0 &&
            block.timestamp >= s.saleTimestamp + s.privSaleLength &&
            (
                block.timestamp < s.saleTimestamp + s.privSaleLength + s.publicSaleLength ||
                s.publicSaleLength == 0
            );
    }

    /**
    * @dev Reverts if the private sale is not active. Use this
    *      function as needed in other facets to ensure that
    *      particular functions may only be called during the
    *      private sale.
    */
    function requirePrivSaleIsActive() internal view {
        require(isPrivSaleActive(), "SaleHandlerFacet: private sale is not active now");
    }

    /**
    * @dev Reverts if the public sale is not active. Use this
    *      function as needed in other facets to ensure that
    *      particular functions may only be called during the
    *      public sale.
    */
    function requirePublicSaleIsActive() internal view {
        require(isPublicSaleActive(), "SaleHandlerFacet: public sale is not active now");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ICenterFacet {

    event merge(uint256 tokenId, uint256 level, address sender);

    function maxSupply() external view returns (uint256 _maxSuppy);

    function reservedRemaining() external view returns (uint256 _reservedRemaining);

    function walletCap() external view returns (uint256 _walletCap);

    function priceAL() external view returns (uint256 _priceAL);

    function price() external view returns (uint256 _price);

    function burnStatus() external view returns (bool _burnStatus);

    function ERC721AFacet() external view returns (address _ERC721AFacet);

    function level(uint256 tokenId) external view returns (uint256 level);

    function setPrices(uint256 _price, uint256 _priceAL) external;

    function setWalletCap(uint256 _walletCap) external;

    function toggleBurnStatus() external;

    function setERC721AFacet(address _ERC721AFacet) external;

    function reserve(uint256 amount) external;

    function mint(uint256 amount, bytes32[] memory _merkleProof) external payable;

    function burn(uint256 tokenId) external;

    function transferFrom(address from, address to, uint256 tokenId) external payable;

    function safeTransferFrom(address from, address to, uint256 tokenId) external payable;

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) external payable;
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**************************************************************\
 * AllowlistLib authored by Sibling Labs
 * Version 0.1.0
 * 
 * This library is designed to work in conjunction with
 * AllowlistFacet - it facilitates diamond storage and shared
 * functionality associated with AllowlistFacet.
/**************************************************************/

import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

library AllowlistLib {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("allowlistlibrary.storage");

    struct state {
        bytes32 merkleRoot;
    }

    /**
    * @dev Return stored state struct.
    */
    function getState() internal pure returns (state storage _state) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            _state.slot := position
        }
    }

    /**
    * @dev Verify that provided merkle proof & leaf node
    *      combination belong to the stored merkle root.
    */
    function validateProof(bytes32[] calldata proof, address leaf) internal view returns (bool) {
        return MerkleProof.verify(
            proof,
            getState().merkleRoot,
            keccak256(abi.encodePacked(leaf))
        );
    }

    /**
    * @dev Require that the caller and the provided merkle proof
    *      belong to the stored merkle root.
    */
    function requireValidProof(bytes32[] calldata proof) internal view {
        require(validateProof(proof, msg.sender), "AllowlistFacet: invalid merkle proof");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library ERC721AStorage {
    // Reference type for token approval.
    struct TokenApprovalRef {
        address value;
    }

    struct Layout {
        // =============================================================
        //                            STORAGE
        // =============================================================

        // The next token ID to be minted.
        uint256 _currentIndex;
        // The number of tokens burned.
        uint256 _burnCounter;
        // Token name
        string _name;
        // Token symbol
        string _symbol;
        // Mapping from token ID to ownership details
        // An empty struct value does not necessarily mean the token is unowned.
        // See {_packedOwnershipOf} implementation for details.
        //
        // Bits Layout:
        // - [0..159]   `addr`
        // - [160..223] `startTimestamp`
        // - [224]      `burned`
        // - [225]      `nextInitialized`
        // - [232..255] `extraData`
        mapping(uint256 => uint256) _packedOwnerships;
        // Mapping owner address to address data.
        //
        // Bits Layout:
        // - [0..63]    `balance`
        // - [64..127]  `numberMinted`
        // - [128..191] `numberBurned`
        // - [192..255] `aux`
        mapping(address => uint256) _packedAddressData;
        // Mapping from token ID to approved address.
        mapping(uint256 => ERC721AStorage.TokenApprovalRef) _tokenApprovals;
        // Mapping from owner to operator approvals
        mapping(address => mapping(address => bool)) _operatorApprovals;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256('ERC721A.contracts.storage.ERC721A');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be proved to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and the sibling nodes in `proof`,
     * consuming from one or the other at each step according to the instructions given by
     * `proofFlags`.
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}