// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**************************************************************\
 * Initialiser contract authored by Sibling Labs
 * Version 0.4.0
 * 
 * This initialiser contract has been written specifically for
 * ERC721A-DIAMOND-TEMPLATE by Sibling Labs
/**************************************************************/

import { GlobalState } from "./libraries/GlobalState.sol";
import { AllowlistLib } from "./libraries/AllowlistLib.sol";
import { CenterFacetLib } from "./libraries/CenterFacetLib.sol";
import { ERC165Lib } from "./libraries/ERC165Lib.sol";
import "erc721a-upgradeable/contracts/ERC721AStorage.sol";
import { PaymentSplitterLib } from "./libraries/PaymentSplitterLib.sol";
import { SaleHandlerLib } from "./libraries/SaleHandlerLib.sol";
import { RoyaltiesConfigLib } from "./libraries/RoyaltiesConfigLib.sol";

contract DiamondInit {

    function initAll() public {
        initAdminPrivilegesFacet();
        initAllowlistFacet();
        initCenterFacet();
        initERC165Facet();
        initERC721AFacet();
        initPaymentSplitterFacet();
        initSaleHandlerFacet();
        initRoyaltiesConfigFacet();
    }

    // AdminPrivilegesFacet //

    function initAdminPrivilegesFacet() public {
        // List of admins must be placed inside this function,
        // as arrays cannot be constant and
        // therefore will not be accessible by the
        // delegatecall from the diamond contract.
        address[] memory admins = new address[](1);
        admins[0] = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

        for (uint256 i; i < admins.length; i++) {
            GlobalState.getState().admins[admins[i]] = true;
        }
    }

    // AllowlistFacet //

    // merkleRoot based on ethers.getSigners first 3 accounts
    bytes32 private constant merkleRoot = 0x55e8063f883b9381398d8fef6fbae371817e8e4808a33a4145b8e3cdd65e3926;

    function initAllowlistFacet() public {
        AllowlistLib.getState().merkleRoot = merkleRoot;
    }

    // CenterFacet //

    address private constant ERC721AFacet = 0x67b85b3564d4a1FD29d82dDd99f96761c25A4949; // rinkeby

    function initCenterFacet() public {
        CenterFacetLib.state storage s = CenterFacetLib.getState();

        s.ERC721AFacet = ERC721AFacet;
        s.maxSupply = 22;
        s.walletCap = 4;
        s.price = [0.001 ether, 0.0015 ether];
        s.baseURI = "https://gateway.pinata.cloud/ipfs/.../?";
        s.reservedRemaining = 7;
    }

    // ERC165Facet //

    bytes4 private constant ID_IERC165 = 0x01ffc9a7;
    bytes4 private constant ID_IERC173 = 0x7f5828d0;
    bytes4 private constant ID_IERC2981 = 0x2a55205a;
    bytes4 private constant ID_IERC721 = 0x80ac58cd;
    bytes4 private constant ID_IERC721METADATA = 0x5b5e139f;
    bytes4 private constant ID_IDIAMONDLOUPE = 0x48e2b093;
    bytes4 private constant ID_IDIAMONDCUT = 0x1f931c1c;

    function initERC165Facet() public {
        ERC165Lib.state storage s = ERC165Lib.getState();

        s.supportedInterfaces[ID_IERC165] = true;
        s.supportedInterfaces[ID_IERC173] = true;
        s.supportedInterfaces[ID_IERC2981] = true;
        s.supportedInterfaces[ID_IERC721] = true;
        s.supportedInterfaces[ID_IERC721METADATA] = true;

        s.supportedInterfaces[ID_IDIAMONDLOUPE] = true;
        s.supportedInterfaces[ID_IDIAMONDCUT] = true;
    }

    // ERC721AFacet //

    string private constant name = "MyToken";
    string private constant symbol = "MTK";
    uint256 private constant startTokenId = 0;

    function initERC721AFacet() public {
        ERC721AStorage.layout()._name = name;
        ERC721AStorage.layout()._symbol = symbol;
        ERC721AStorage.layout()._currentIndex = startTokenId;
    }

    // PaymentSplitterFacet //

    function initPaymentSplitterFacet() public {
        // Lists of payees and shares must be placed inside this
        // function, as arrays cannot be constant and therefore
        // will not be accessible by the delegatecall from the
        // diamond contract.
        address[] memory payees = new address[](1);
        payees[0] = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

        uint256[] memory shares = new uint256[](1);
        shares[0] = 1;

        require(payees.length == shares.length, "PaymentSplitter: payees and shares length mismatch");
        require(payees.length > 0, "PaymentSplitter: no payees");

        for (uint256 i = 0; i < payees.length; i++) {
            PaymentSplitterLib._addPayee(payees[i], shares[i]);
        }
    }

    // SaleHandlerFacet //

    uint256 private constant privSaleTimestamp = 2663532308;  //1663286400
    uint256 private constant privSaleLength = 86400;
    uint256 private constant publicSaleLength = 86400;

    function initSaleHandlerFacet() public {
        SaleHandlerLib.state storage s = SaleHandlerLib.getState();

        s.saleTimestamp = privSaleTimestamp;
        s.privSaleLength = privSaleLength;
        s.publicSaleLength = publicSaleLength;
    }

    // RoyaltiesConfigFacet //

    address payable private constant royaltyRecipient = payable(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
    uint256 private constant royaltyBps = 10000;

    function initRoyaltiesConfigFacet() public {
        RoyaltiesConfigLib.state storage s = RoyaltiesConfigLib.getState();

        s.royaltyRecipient = royaltyRecipient;
        s.royaltyBps = royaltyBps;
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

/**************************************************************\
 * PaymentSplitterLib authored by Sibling Labs
 * Version 0.2.0
 * 
 * This library is designed to work in conjunction with
 * PaymentSplitterFacet - it facilitates diamond storage and shared
 * functionality associated with PaymentSplitterFacet.
/**************************************************************/

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

library PaymentSplitterLib {
    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event ERC20PaymentReleased(IERC20Upgradeable indexed token, address to, uint256 amount);

    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("paymentsplitter.storage");

    struct state {
        uint256 _totalShares;
        uint256 _totalReleased;

        mapping(address => uint256) _shares;
        mapping(address => uint256) _released;
        address[] _payees;

        mapping(IERC20Upgradeable => uint256) _erc20TotalReleased;
        mapping(IERC20Upgradeable => mapping(address => uint256)) _erc20Released;
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
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     * @param shares_ The number of shares owned by the payee.
     */
    function _addPayee(address account, uint256 shares_) internal {
        PaymentSplitterLib.state storage s = PaymentSplitterLib.getState();

        require(account != address(0), "PaymentSplitter: account is the zero address");
        require(shares_ > 0, "PaymentSplitter: shares are 0");
        require(s._shares[account] == 0, "PaymentSplitter: account already has shares");

        s._payees.push(account);
        s._shares[account] = shares_;
        s._totalShares = s._totalShares + shares_;
        emit PayeeAdded(account, shares_);
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
 * ERC165Lib authored by Sibling Labs
 * Version 0.1.0
 * 
 * This library is designed to work in conjunction with
 * ERC165Facet - it facilitates diamond storage and shared
 * functionality associated with ERC165Facet.
/**************************************************************/

library ERC165Lib {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("erc165.storage");

    struct state {
        mapping(bytes4 => bool) supportedInterfaces;
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
 * RoyaltiesConfigLib authored by Sibling Labs
 * Version 0.1.0
 * 
 * This library is designed to work in conjunction with
 * RoyaltiesConfigFacet - it facilitates diamond storage and shared
 * functionality associated with RoyaltiesConfigFacet.
/**************************************************************/

library RoyaltiesConfigLib {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("royaltiesconfiglibrary.storage");

    struct state {
        uint256 royaltyBps;
        address payable royaltyRecipient;
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
     * @dev Returns royalty payee and amount for tokens in this
     *      collection. Adheres to EIP-2981.
     */
    function royaltyInfo(uint256, uint256 value) internal view returns (address, uint256) {
        state storage s = getState();
        return (s.royaltyRecipient, value * s.royaltyBps / 10000);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
}