// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ISingleToken} from "../token/ISingleToken.sol";
import {IMetaUnit} from "../../MetaUnit/interfaces/IMetaUnit.sol";
import {Pausable} from "../../../Pausable.sol";

/**
 * @author MetaPlayerOne
 * @title MakeAnOffer
 * @notice Manages the make an offer logic. 
 */
contract MakeAnOffer is Pausable {
    struct Offer { uint256 uid; address token_address; uint256 token_id; uint256 price; address seller; address buyer; bool canceled; bool finished; }

    Offer[] private _offers;

    address private _meta_unit_address;

    /**
     * @dev setup Metaunit address and owner of customer.
     */
    constructor(address owner_of_, address meta_unit_address_) Pausable(owner_of_) {
        _meta_unit_address = meta_unit_address_;
    }

    /**
     * @dev emits when offer creates.
     */
    event offerCreated(uint256 uid, address token_address, uint256 token_id, uint256 price, address seller, address buyer, bool canceled, bool finished);

    /**
     * @dev emits when offer cancels.
     */
    event offerCanceled(uint256 uid, address initiator);

    /**
     * @dev emits when offer resolves.
     */
    event offerResolved(uint256 uid);

    /**
     * @dev allows you to create an offer for a token.
     * @param token_address address of the token for which you want to make an offer.
     * @param token_id id of the token for which you want to make an offer.
     * @param price price you offer.
     * @param buyer the offeror's address.
     */
    function create(address token_address, uint256 token_id, uint256 price, address buyer) public notPaused {
        uint256 newOfferUid = _offers.length;
        _offers.push(Offer(newOfferUid, token_address, token_id, price, msg.sender, buyer, false, false));
        IERC721(token_address).transferFrom(msg.sender, address(this), token_id);
        emit offerCreated(newOfferUid, token_address, token_id, price, msg.sender, buyer, false, false);
    }

    /**
     * @dev allows you to cancel offers.
     * @param uid offer unique id you want to cancel.
     */
    function cancel(uint256 uid) public {
        Offer memory offer = _offers[uid];
        require(msg.sender == offer.buyer || msg.sender == offer.seller, "Permission denied");
        IERC721(offer.token_address).transferFrom(address(this), offer.seller, offer.token_id);
        _offers[uid].canceled = true;
        emit offerCanceled(uid, msg.sender);
    }

    /**
     * @dev allows you to cancel an offer
     * @param uid offer unique id you want to accept.
     */
    function resolve(uint256 uid) public payable {
        Offer memory offer = _offers[uid];
        require(msg.sender == offer.buyer, "Permission denied");
        require(msg.value >= offer.price, "Not enough funds sent");
        require(!offer.canceled, "Offer has been canceled");
        require(!offer.finished, "Offer has been already resolved");
        payable(offer.seller).transfer((msg.value * 975) / 1000);
        payable(_owner_of).transfer((msg.value * 25) / 1000);
        IERC721(offer.token_address).transferFrom(address(this), msg.sender, offer.token_id);
        IMetaUnit(_meta_unit_address).increaseLimit(offer.seller, offer.price);
        _offers[uid].finished = true;
        emit offerResolved(uid);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMetaUnit {
    function increaseLimit(address userAddress, uint256 value) external;
    function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISingleToken {
    function getRoyalty(uint256 token_id) external returns (uint256);

    function getCreator(uint256 token_id) external returns (address);

    function mint(string memory token_uri, uint256 royalty) external;

    function burn(uint256 token_id) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @author MetaPlayerOne
 * @title Pausable
 * @notice Contract which manages allocations in MetaPlayerOne.
 */
contract Pausable {
    address internal _owner_of;
    bool internal _paused = false;

    /**
    * @dev setup owner of this contract with paused off state.
    */
    constructor(address owner_of_) {
        _owner_of = owner_of_;
        _paused = false;
    }

    /**
    * @dev modifier which can be used on child contract for checking if contract services are paused.
    */
    modifier notPaused() {
        require(!_paused, "Contract is paused");
        _;
    }

    /**
    * @dev function which setup paused variable.
    * @param paused_ new boolean value of paused condition.
    */
    function setPaused(bool paused_) external {
        require(_paused == paused_, "Param has been asigned already");
        require(_owner_of == msg.sender, "Permission address");
        _paused = paused_;
    }

    /**
    * @dev function which setup owner variable.
    * @param owner_of_ new owner of contract.
    */
    function setOwner(address owner_of_) external {
        require(_owner_of == msg.sender, "Permission address");
        _owner_of = owner_of_;
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