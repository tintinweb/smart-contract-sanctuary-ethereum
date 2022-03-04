// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

interface IReverseResolver {
    function claim(address owner) external returns (bytes32);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

/**
 * @dev Utility library for managing a Set of items that also can be iterated over
 * Based on the OpenZeppelin library: https://docs.openzeppelin.com/contracts/3.x/api/utils#EnumerableSet
 * Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/structs/EnumerableSet.sol
 * Commit: b0cf6fbb7a70f31527f36579ad644e1cf12fdf4e
 */
library EnumerableSet {
    struct Set {
        uint256[] _values;
        mapping (uint256 => uint256) _indexes;
    }

    function at(Set storage set, uint256 index) internal view returns (uint256) {
        return set._values[index];
    }

    function contains(Set storage set, uint256 value) internal view returns (bool) {
        return set._indexes[value] != 0;
    }

    function length(Set storage set) internal view returns (uint256) {
        return set._values.length;
    }

    function add(Set storage set, uint256 value) internal returns (bool) {
        if (!contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function remove(Set storage set, uint256 value) internal returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];
        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;
            if (lastIndex != toDeleteIndex) {
                uint256 lastvalue = set._values[lastIndex];
                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();
            // Delete the index for the deleted slot
            delete set._indexes[value];
            return true;
        } else {
            return false;
        }
    }
}

/**
 * @dev Compact representation of an access list for MoonCat assets
 * If needing to store an access list of "does token X have access?" state, doing it as a mapping(uint256 => bool)
 * needs one 'storage' action for each token ID stored (inefficient for a list with thousands of entries).
 * This structure densly-packs "booleans" as individual bits in a 32-byte word, making it a maximum of 100 'storage' actions
 * to set an access list for all 25,440 MoonCats.
 */
library MoonCatBitSet {

    bytes32 constant Mask =  0x0000000000000000000000000000000000000000000000000000000000000001;

    function setBit(bytes32[100] storage set, uint16 index)
        internal
    {
        uint16 wordIndex = index / 256;
        uint16 bitIndex = index % 256;
        bytes32 mask = Mask << (255 - bitIndex);
        set[wordIndex] |= mask;
    }

    function clearBit(bytes32[100] storage set, uint16 index)
        internal
    {
        uint16 wordIndex = index / 256;
        uint16 bitIndex = index % 256;
        bytes32 mask = ~(Mask << (255 - bitIndex));
        set[wordIndex] &= mask;
    }

    function checkBit(bytes32[100] memory set, uint256 index)
        internal
        pure
        returns (bool)
    {
        uint256 wordIndex = index / 256;
        uint256 bitIndex = index % 256;
        bytes32 mask = Mask << (255 - bitIndex);
        return (mask & set[wordIndex]) != 0;
    }

}

/**
 * @title MoonCat​Moments
 * @notice NFTs of group photos MoonCats take together, commemorating special events
 * @dev ERC721-compliant tokens, minted into existence as owned by the MoonCats themselves (ERC998 functionality)
 */
contract MoonCatMoments is IERC721Enumerable, IERC721Metadata {

    // Acclimated MoonCats Address
    address public constant moonCatAcclimatorContract = 0xc3f733ca98E0daD0386979Eb96fb1722A1A05E69;


    address public contractOwner;

    bool public paused = true;

    string public name = "MoonCatMoments";
    string public symbol = unicode"🖼";

    // Mapping from token ID to owner address
    mapping(uint256 => address) private Owners;

    using EnumerableSet for EnumerableSet.Set;
    // Mapping of owner address to owned token set
    mapping (address => EnumerableSet.Set) internal TokensByOwner;
    uint256 public acclimatorBalance = 0;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private TokenApprovals;
    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private OperatorApprovals;

    uint16 public totalMoments = 0;

    struct Moment {
        uint16 momentId;
        uint16 startingTokenId;
        uint16 issuance;
        uint16 unclaimed;
        string tokenURI;
        bytes32[100] claimable;
    }

    mapping(uint256 => Moment) public Moments;

    uint256 public totalSupply = 0;

    constructor() {
        contractOwner = msg.sender;

        // https://docs.ens.domains/contract-api-reference/reverseregistrar#claim-address
        IReverseResolver(0x084b1c3C81545d370f3634392De611CaaBFf8148).claim(msg.sender);
    }

    /* Enumerable */

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 tokenId) public pure returns (uint256) {
        return tokenId;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(owner != moonCatAcclimatorContract, "Cannot Enumerate Acclimator");
        require(index < balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return TokensByOwner[owner].at(index);
    }

    /* Owner Functions */

    /**
     * @dev Allow current `owner` to transfer ownership to another address
     */
    function transferOwnership(address newOwner) public onlyOwner {
        contractOwner = newOwner;
    }

    /**
     * @dev Create a new Moment, and deliver the tokens directly to the indicated MoonCats
     */
    function mint(string calldata URI, uint16[] calldata rescueOrders) public onlyOwner {
        require(rescueOrders.length > 0, "Empty rescueOrders");

        uint16 startingId = 0;

        if (totalMoments > 0) {
            Moment memory previousMoment = Moments[totalMoments - 1];
            startingId = previousMoment.startingTokenId + previousMoment.issuance;
        }

        bytes32[100] memory claimable;

        Moments[totalMoments] = Moment(
            totalMoments,
            startingId,
            uint16(rescueOrders.length),
            0,
            URI,
            claimable
        );
        totalMoments++;
        totalSupply += rescueOrders.length;

        for (uint i = 0; i < rescueOrders.length; i++) {
            uint256 tokenId = startingId + i;
            IERC721Receiver(moonCatAcclimatorContract).onERC721Received(
                address(this),
                address(this),
                tokenId,
                abi.encodePacked(uint256(rescueOrders[i]))
            );
            emit Transfer(address(0), moonCatAcclimatorContract, tokenId);
        }
        acclimatorBalance += rescueOrders.length;
    }

    /**
     * @dev Create a new Moment, to be made available to MoonCat owners to claim
     */
    function mintClaimable(string calldata URI, uint16[] calldata rescueOrders) public onlyOwner {
        require(rescueOrders.length > 0, "Empty rescueOrders");

        uint16 startingId = 0;

        if (totalMoments > 0) {
            Moment memory previousMoment = Moments[totalMoments - 1];
            startingId = previousMoment.startingTokenId + previousMoment.issuance;
        }

        bytes32[100] memory claimable;

        Moments[totalMoments] = Moment(
            totalMoments,
            startingId,
            uint16(rescueOrders.length),
            uint16(rescueOrders.length),
            URI,
            claimable
        );

        for (uint i = 0; i < rescueOrders.length; i++) {
            uint16 rescueOrder = rescueOrders[i];
            require(rescueOrder < 25440, "Invalid rescueOrder");
            require(!MoonCatBitSet.checkBit(Moments[totalMoments].claimable, rescueOrder), "Duplicate RescueOrder");
            MoonCatBitSet.setBit(Moments[totalMoments].claimable, rescueOrder);
        }
        totalMoments++;
        totalSupply += rescueOrders.length;
    }

    /**
     * @dev Check and see if a given MoonCat is able to claim a given Moment
     */
    function isClaimable (uint256 momentId, uint256 rescueOrder) public view returns (bool) {
        return MoonCatBitSet.checkBit(Moments[momentId].claimable, rescueOrder);
    }

    /**
     * @dev Given a list of MoonCat rescue orders, check a single Moment identifier and return a list of which of those MoonCats can claim it
     */
    function isClaimable (uint256 momentId, uint256[] calldata rescueOrders) public view returns (bool[] memory) {
        bool[] memory results = new bool[](rescueOrders.length);
        for (uint i = 0; i < rescueOrders.length; i++) {
            results[i] = isClaimable(momentId, rescueOrders[i]);
        }
        return results;
    }

    /**
     * @dev Claim a Moment token that a given MoonCat is eligible for
     */
    function claim (uint256 momentId, uint256 rescueOrder) public whenNotPaused returns (uint256){
        require(isClaimable(momentId, rescueOrder), "No Pending Claim");
        MoonCatBitSet.clearBit(Moments[momentId].claimable, uint16(rescueOrder));

        uint256 tokenId = Moments[momentId].startingTokenId + (Moments[momentId].issuance - Moments[momentId].unclaimed);
        Moments[momentId].unclaimed--;
        acclimatorBalance++;
        IERC721Receiver(moonCatAcclimatorContract).onERC721Received(
            address(this),
            address(this),
            tokenId,
            abi.encodePacked(rescueOrder)
        );

        emit Transfer(address(0), moonCatAcclimatorContract, tokenId);
        return tokenId;
    }

    /**
     * @dev Claim several Moments that multiple MoonCats are eligible for
     */
    function batchClaim (uint256[] calldata momentIds, uint256[] calldata rescueOrders) public {
        require(momentIds.length == rescueOrders.length, "Array length mismatch");
        for (uint i = 0; i < momentIds.length; i++) {
            claim(momentIds[i], rescueOrders[i]);
        }
    }

    /**
     * @dev Claim a Moment that multiple MoonCats are eligible for
     */
    function batchClaim (uint256 momentId, uint256[] calldata rescueOrders) public {
        for (uint i = 0; i < rescueOrders.length; i++) {
            claim(momentId, rescueOrders[i]);
        }
    }

    /**
     * @dev Claim several Moments that a MoonCat is eligible for
     */
    function batchClaim (uint256[] calldata momentIds, uint256 rescueOrder) public {
        for (uint i = 0; i < momentIds.length; i++) {
            claim(momentIds[i], rescueOrder);
        }
    }

    /**
     * @dev For a given MoonCat, claim any pending Moment they're eligible for
     */
    function batchClaim (uint256 rescueOrder) public {
        for (uint momentId = 0; momentId < totalMoments; momentId++) {
            if (isClaimable(momentId, rescueOrder)) {
                claim(momentId, rescueOrder);
            }
        }
    }

    /**
     * @dev For multiple MoonCats, claim any pending Moments they're eligible for
     */
    function batchClaim (uint256[] calldata rescueOrders) public {
        for (uint i = 0; i < rescueOrders.length; i++) {
            batchClaim(rescueOrders[i]);
        }
    }

    /**
     * @dev For a given MoonCat, fetch a list of Moment IDs that MoonCat is eligible to claim
     */
    function listClaimableMoments (uint256 rescueOrder) public view returns (uint16[] memory) {
        uint16[] memory claimableMoments = new uint16[](totalMoments);
        uint totalClaimable = 0;
        for (uint momentId = 0; momentId < totalMoments; momentId++) {
            if (isClaimable(momentId, rescueOrder)) {
                claimableMoments[totalClaimable] = uint16(momentId);
                totalClaimable++;
            }
        }
        uint16[] memory finalClaimable = new uint16[](totalClaimable);
        for (uint i = 0; i < totalClaimable; i++) {
            finalClaimable[i] = claimableMoments[i];
        }
        return finalClaimable;
    }

    /**
     * @dev Update the metadata location for a given Moment
     */
    function setMomentURI(uint256 momentId, string calldata URI) public onlyOwner {
        require(momentId < totalMoments, "Moment not Found");
        Moments[momentId].tokenURI = URI;
    }

    /**
     * @dev Prevent claiming of Moments
     */
    function paws () public onlyOwner {
        paused = true;
    }

    /**
     * @dev Enable claiming of Moments
     */
    function unpaws () public onlyOwner {
        paused = false;
    }

    /* Metadata */

    /**
     * @dev For a given Moment token identifier, determine which Moment group it is a part of
     */
    function getMomentId(uint256 tokenId) public view returns (uint256) {
        require(tokenId < totalSupply, "Nonexistent token");
        uint256 count = 0;
        for (uint group = 0; group < totalMoments; group++) {
            count += Moments[group].issuance;
            if (tokenId < count) {
                return group;
            }
        }
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(tokenId < totalSupply, "ERC721Metadata: URI query for nonexistent token");
        return Moments[getMomentId(tokenId)].tokenURI;
    }

    /**
     * @dev For a given Moment ID, fetch the metadata URI for that moment
     */
    function tokenURIByMomentId (uint256 momentId) public view returns (string memory) {
        require(momentId < totalMoments, "Nonexistent Moment");
        return Moments[momentId].tokenURI;
    }

    /**
     * @dev Does a Moment token with the specified identifier exist?
     * Because some Moments are claimable, and don't come into existence until claimed, there will be gaps in the ID sequence.
     * This function gives a way to determine easily if a given identifier exists at all, before attempting further actions on it
     */
    function tokenExists(uint256 tokenId) public view returns (bool) {
        if (tokenId >= totalSupply) return false; // Out of bounds
        uint256 momentId = getMomentId(tokenId);
        if (tokenId - Moments[momentId].startingTokenId >= Moments[momentId].issuance - Moments[momentId].unclaimed) return false; // Unclaimed token
        return true;
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        require(tokenExists(tokenId), "Nonexistent token");
        if (Owners[tokenId] == address(0)) {
            return moonCatAcclimatorContract;
        } else {
            return Owners[tokenId];
        }
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view returns (uint256) {
        return (owner == moonCatAcclimatorContract) ? acclimatorBalance : TokensByOwner[owner].length();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId;
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal {
        TokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public  {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
                msg.sender == owner || isApprovedForAll(owner, msg.sender),
                "ERC721: approve caller is not owner nor approved for all"
                );
        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view returns (address) {
        require(tokenId < totalSupply, "ERC721: approved query for nonexistent token");
        return TokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view  returns (bool) {
        return OperatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(
                               address operator,
                               bool approved
                               ) external virtual {
        require(msg.sender != operator, "ERC721: approve to caller");
        OperatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev Returns true if `account` is a contract.
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
        size := extcodesize(account)
                }
        return size > 0;
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (isContract(to)) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                            }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal whenNotPaused {
        require(ownerOf(tokenId) == from , "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        // Remove tokenId from sender's registry
        if (from == moonCatAcclimatorContract) {
            acclimatorBalance--;
        } else {
            TokensByOwner[from].remove(tokenId);
        }

        // Add tokenId to receiver's registry
        if (to == moonCatAcclimatorContract) {
            acclimatorBalance++;
        } else {
            TokensByOwner[to].add(tokenId);
        }

        Owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(tokenId < totalSupply, "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /* Modifiers */

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Not Owner");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(paused == false, "Paused");
        _;
    }

    /* Rescuers */

    /**
     * @dev Rescue ERC20 assets sent directly to this contract.
     */
    function withdrawForeignERC20(address tokenContract) public onlyOwner {
        IERC20 token = IERC20(tokenContract);
        token.transfer(contractOwner, token.balanceOf(address(this)));
        }

    /**
     * @dev Rescue ERC721 assets sent directly to this contract.
     */
    function withdrawForeignERC721(address tokenContract, uint256 tokenId) public onlyOwner {
        IERC721(tokenContract).safeTransferFrom(address(this), contractOwner, tokenId);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Enumerable.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
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
}