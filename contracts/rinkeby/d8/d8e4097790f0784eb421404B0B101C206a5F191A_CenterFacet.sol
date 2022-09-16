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

contract CenterFacet {
    // VARIABLE GETTERS //

    function maxSupply() external view returns (uint256) {
        return CenterFacetLib.getState().maxSupply;
    }

    function reservedRemaining() external view returns (uint256) {
        return CenterFacetLib.getState().reservedRemaining;
    }

    function walletCap() external view returns (uint256) {
        return CenterFacetLib.getState().walletCap;
    }

    function priceAL() external view returns (uint256) {
        return CenterFacetLib.getState().price[0];
    }

    function price() external view returns (uint256) {
        return CenterFacetLib.getState().price[1];
    }

    function burnStatus() external view returns (bool) {
        return CenterFacetLib.getState().burnStatus;
    }

    function ERC721AFacet() external view returns (address) {
        return CenterFacetLib.getState().ERC721AFacet;
    }

    function level(uint256 tokenId) external view returns (uint256) {
        return CenterFacetLib.getState().levels[tokenId];
    }

    // SETUP & ADMIN FUNCTIONS //

    function setPrices(uint256 _price, uint256 _priceAL) external {
        GlobalState.requireCallerIsAdmin();
        CenterFacetLib.getState().price[0] = _priceAL;
        CenterFacetLib.getState().price[1] = _price;
    }

    function setWalletCap(uint256 _walletCap) external {
        GlobalState.requireCallerIsAdmin();
        CenterFacetLib.getState().walletCap = _walletCap;
    }

    function toggleBurnStatus() external {
        GlobalState.requireCallerIsAdmin();
        CenterFacetLib.getState().burnStatus = !CenterFacetLib.getState().burnStatus;
    }

    function setBaseURI(string memory URI) external {
        GlobalState.requireCallerIsAdmin();
        CenterFacetLib.getState().baseURI = URI;
    }

    function setERC721FacetAddress(address addr) external {
        GlobalState.requireCallerIsAdmin();
        CenterFacetLib.getState().ERC721AFacet = addr;
    }

    function reserve(uint256 amount) external {
        GlobalState.requireCallerIsAdmin();
        require(CenterFacetLib.getState().reservedRemaining > 0, "No reserved token remaining");
        CenterFacetLib.getState().reservedRemaining -= amount;
        CenterFacetLib.callTokenFacet(abi.encodeWithSignature("_safeMint(address,uint256)", msg.sender, amount));
    }

    // PUBLIC FUNCTIONS //

    function mint(uint256 amount, bytes32[] calldata _merkleProof) external payable {
        GlobalState.requireContractIsNotPaused();
        require(SaleHandlerLib.getState().saleTimestamp > 0, "CenterFacet: sale has not begun");

        bool al = SaleHandlerLib.isPrivSaleActive();
        if (al) AllowlistLib.requireValidProof(_merkleProof);

        CenterFacetLib.state storage s = CenterFacetLib.getState();

        uint256 _price = al ? s.price[0] : s.price[1];
        require(msg.value == _price * amount, "CenterFacet: incorrect amount of ether sent");

        uint256 _walletCap = s.walletCap;
        uint256 numberMinted = CenterFacetLib._numberMinted(msg.sender);
        require(
            amount + numberMinted <= _walletCap,
            string(
                abi.encodePacked(
                    "CenterFacet: maximum tokens per wallet during ",
                    al ? "private" : "public",
                    " sale is ",
                    CenterFacetLib._toString(_walletCap)
                )
            )
        );

        CenterFacetLib.safeMint(msg.sender, amount);
    }

    function burn(uint256 tokenId) external {
        GlobalState.requireContractIsNotPaused();
        require(CenterFacetLib.getState().burnStatus, "CenterFacet: token burning is not available now");
        CenterFacetLib._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(CenterFacetLib._exists(tokenId), "CenterFacet: token does not exist");

        string memory baseURI = CenterFacetLib.getState().baseURI;
        return string(abi.encodePacked(baseURI, CenterFacetLib._toString(tokenId)));
    }

    function transferFrom(address from, address to, uint256 tokenId) external payable {
        CenterFacetLib._beforeTokenTransfer(from, to, tokenId, "transferFrom(address,address,uint256)");
    }
    function safeTransferFrom(address from, address to, uint256 tokenId) external payable {
        CenterFacetLib._beforeTokenTransfer(from, to, tokenId, "safeTransferFrom(address,address,uint256)");
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

library CenterFacetLib {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("tokenfacet.storage");

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

    function tokensOfOwner(address owner) internal returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            TokenOwnership memory ownership;
            for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }

    // Delegatecall to ERC721AFacet //

    function callTokenFacet(bytes memory callData) internal {
        (bool success, ) = CenterFacetLib.getState().ERC721AFacet.delegatecall(callData);
        require(success, "CenterFacet: delegate call from CenterFacet to ERC721AFacet failed");
    }

    function _burn(uint256 tokenId) internal {
        CenterFacetLib.callTokenFacet(abi.encodeWithSignature("_burn(uint256,bool)", tokenId, true));
    }

    function balanceOf(address owner) internal returns (uint256) {
        address facet = CenterFacetLib.getState().ERC721AFacet;
        bytes memory sig = abi.encodeWithSignature("balanceOf(address)", owner);

        assembly {

            let result := delegatecall(gas(), facet, add(sig, 0x20), mload(sig), 0, 0)
            let size := returndatasize()
            let ptr := mload(0x40)
            returndatacopy(ptr, 0, size)
            switch result case 0 { revert(ptr, size) }
            default { return(ptr, size) }

        }

    }

    function _startTokenId() internal returns (uint256) {

        address facet = CenterFacetLib.getState().ERC721AFacet;
        bytes memory sig = abi.encodeWithSignature("_startTokenId()");

        assembly {

            let result := delegatecall(gas(), facet, add(sig, 0x20), mload(sig), 0, 0)
            let size := returndatasize()
            let ptr := mload(0x40)
            returndatacopy(ptr, 0, size)
            switch result case 0 { revert(ptr, size) }
            default { return(ptr, size) }

        }

    }

    function _ownershipAt(uint256 index) internal returns (TokenOwnership memory) {
        address facet = CenterFacetLib.getState().ERC721AFacet;
        bytes memory sig = abi.encodeWithSignature("_ownershipAt(uint256)", index);

        assembly {

            let result := delegatecall(gas(), facet, add(sig, 0x20), mload(sig), 0, 0)
            let size := returndatasize()
            let ptr := mload(0x40)
            returndatacopy(ptr, 0, size)
            switch result case 0 { revert(ptr, size) }
            default { return(ptr, size) }

        }

    }

    // SPECIAL FUNCTIONALITY FOR MERGE //

    function safeMint(address to, uint256 amount) internal {
        callTokenFacet(abi.encodeWithSignature("_safeMint(address,uint256)", to, amount));
        for(uint256 i = 0; i < amount/2; i++) {
            (uint256[] memory three, uint256[] memory four) = getSeparateByLevel(msg.sender);
            if(three.length > 1) {
                _burn(three[0]);
                getState().levels[three[1]]++;
                if(four.length > 0){
                    _burn(three[1]);
                    getState().levels[four[0]]++;
                }
            }
            if(four.length > 1) {
                _burn(four[0]);
                getState().levels[four[1]]++;
            }
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, string memory func) internal {
        require(_exists(tokenId), "Given tokenId doens't exist");
        uint256 level = getState().levels[tokenId];
        if(level == 2){
            getState().ERC721AFacet.delegatecall(
                abi.encodeWithSignature(func, from, to, tokenId)
            );
        }
        if (level == 1) {
            _mergeFour();
        }
        if (level == 2) {
            _mergeThree();
        }
    }

    function _mergeFour() internal {
        (,uint256[] memory four) = getSeparateByLevel(msg.sender);
        if(four.length > 1) {
            _burn(four[0]);
            getState().levels[four[1]]++;
        }
    }

    function _mergeThree() internal {
        (uint256[] memory three, uint256[] memory four) = getSeparateByLevel(msg.sender);
        if(three.length > 1) {
            _burn(three[0]);
            getState().levels[three[1]]++;
            if(four.length > 0){
                _burn(three[1]);
                getState().levels[four[0]]++;
            }
        }
    }

    function getSeparateByLevel(address owner) internal returns (uint256[] storage three, uint256[] storage  four) {
        uint256[] memory tokenIds = tokensOfOwner(owner);
        for(uint256 i = 0; i < tokenIds.length; i++) {
            uint256 level = CenterFacetLib.getState().levels[tokenIds[i]];
            if (level == 0) three.push(tokenIds[i]);
            else if (level == 1) four.push(tokenIds[i]);
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
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
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}