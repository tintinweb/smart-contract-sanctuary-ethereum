// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
pragma solidity ^0.8.17;

//  ==========  EXTERNAL IMPORTS    ==========

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

//  ==========  INTERNAL IMPORTS    ==========

import {IGuildRouter} from "../interfaces/IGuildRouter.sol";
import {IGuild} from "../interfaces/IGuild.sol";
import {IGuildBank} from "../interfaces/IGuildBank.sol";
import {ILiquidDelegate} from "../interfaces/ILiquidDelegate.sol";

contract GuildRouter_LiquidDelegate is IGuildRouter {
    /*///////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error OnlyGuildBankContract();

    /*///////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    struct GuildRouterLiquidDelegateStorage {
        mapping(uint256 => uint256) rentalIdToRightsId;
    }

    /*///////////////////////////////////////////////////////////////
                               STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    address public immutable guildContract;
    address public immutable liquidDelegateContract;

    bool public immutable requireAssetTransferFromApproval;

    GuildRouterLiquidDelegateStorage private s;

    /*///////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyGuildBankContract() {
        if (msg.sender != IGuild(guildContract).getContracts().guildBank) revert OnlyGuildBankContract();
        _;
    }

    /*///////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _guild, address _liquidDelegateContract, bool _requireAssetTransferFromApproval) {
        guildContract = _guild;
        liquidDelegateContract = _liquidDelegateContract;
        requireAssetTransferFromApproval = _requireAssetTransferFromApproval;
    }

    /*///////////////////////////////////////////////////////////////
                               EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function invokeRental(uint256 _rentalId) external onlyGuildBankContract {
        // get GuildBank contract
        address guildBankContract = IGuild(guildContract).getContracts().guildBank;

        // get rental info
        IGuildBank.Rental memory rental = IGuildBank(guildBankContract).getRentalById(_rentalId);
        address collection = rental.collection;
        uint256 tokenId = rental.tokenId;
        uint96 expiry = uint96(rental.expiry);
        address user = rental.user;

        // delegate the ownership rights and receive the wrapped ERC721 token
        IERC721(collection).transferFrom(guildBankContract, address(this), tokenId);
        uint256 rightsId = ILiquidDelegate(liquidDelegateContract).nextRightsId();
        IERC721(collection).approve(liquidDelegateContract, tokenId);
        ILiquidDelegate(liquidDelegateContract).create(collection, tokenId, expiry, payable(address(0)));
        s.rentalIdToRightsId[_rentalId] = rightsId;

        // transfer the received wrapped ERC721 token to the renter so that he/she can get the ownership rights for the rented assets
        IERC721(liquidDelegateContract).transferFrom(address(this), user, rightsId);
    }

    function revokeRental(uint256 _rentalId) external onlyGuildBankContract {
        // get GuildBank contract
        address guildBankContract = IGuild(guildContract).getContracts().guildBank;

        // revoke the delegation rights and burn the wrapped ERC721 token unless the wrapped ERC721 token owner already revoked the rights
        uint256 rightsId = s.rentalIdToRightsId[_rentalId];
        if (ILiquidDelegate(liquidDelegateContract).idsToRights(rightsId).depositor != address(0)) {
            ILiquidDelegate(liquidDelegateContract).burn(rightsId);
        }
        delete s.rentalIdToRightsId[_rentalId];

        // transfer the received actual ERC721 token to GuildBank contract so that the owner can withdraw the asset
        IGuildBank.Rental memory rental = IGuildBank(guildBankContract).getRentalById(_rentalId);
        address collection = rental.collection;
        uint256 tokenId = rental.tokenId;
        IERC721(collection).transferFrom(address(this), guildBankContract, tokenId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/*///////////////////////////////////////
─────────────────────────────────────────
──┌───┐───────────────────┌───┬───┬───┐──
──│┌─┐│───────────────────└┐┌┐│┌─┐│┌─┐│──
──│└─┘├──┬─┬──┬──┬──┬─┐┌──┐│││││─│││─││──
──│┌──┤┌┐│┌┤┌┐│┌┐│┌┐│┌┐┤──┤││││└─┘││─││──
──││──│┌┐│││┌┐│└┘│└┘│││├──├┘└┘│┌─┐│└─┘│──
──└┘──└┘└┴┘└┘└┴─┐├──┴┘└┴──┴───┴┘─└┴───┘──
──────────────┌─┘│───────────────────────
──────────────└──┘───────────────────────
─────────────────────────────────────────
///////////////////////////////////////*/

interface IGuild {
    struct GuildContracts {
        address guildID;
        address guildXP;
        address guildBank;
        address guildRental;
        address guildOracle;
    }

    struct GuildFees {
        uint256 mintETH;
        uint256 nameETH;
        uint256 rankETH;
        uint256 avatarETH;
        uint256 mintGuildToken;
        uint256 nameGuildToken;
        uint256 rankGuildToken;
        uint256 avatarGuildToken;
        uint256 mintUSD;
        uint256 nameUSD;
        uint256 rankUSD;
        uint256 avatarUSD;
    }

    function getContracts() external view returns (GuildContracts memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/*///////////////////////////////////////
─────────────────────────────────────────
──┌───┐───────────────────┌───┬───┬───┐──
──│┌─┐│───────────────────└┐┌┐│┌─┐│┌─┐│──
──│└─┘├──┬─┬──┬──┬──┬─┐┌──┐│││││─│││─││──
──│┌──┤┌┐│┌┤┌┐│┌┐│┌┐│┌┐┤──┤││││└─┘││─││──
──││──│┌┐│││┌┐│└┘│└┘│││├──├┘└┘│┌─┐│└─┘│──
──└┘──└┘└┴┘└┘└┴─┐├──┴┘└┴──┴───┴┘─└┴───┘──
──────────────┌─┘│───────────────────────
──────────────└──┘───────────────────────
─────────────────────────────────────────
///////////////////////////////////////*/

interface IGuildBank {
    struct Rental {
        address collection;
        uint256 tokenId;
        address owner;
        address user;
        uint32 share;
        uint64 duration;
        uint64 expiry;
        uint32 amount;
        bool isActive;
    }

    function deposit(
        address _depositor,
        address _collection,
        uint256 _tokenId,
        uint32 _share,
        uint64 _duration,
        uint32 _amount
    ) external returns (uint256 rentalId_);

    function rent(address _renter, uint256 _rentalId, uint32 _amountToRent) external returns (uint256);

    function withdraw(address _depositor, uint256 _rentalId) external;

    function getRentalById(uint256 _id) external view returns (Rental memory);

    function getDepositCount(uint256 _rentalId) external view returns (uint256);

    function getRentalCount(uint256 _rentalId) external view returns (uint256);

    function addCollectionRouter(address _collection, address _router) external;

    function removeCollectionRouter(address collection) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/*///////////////////////////////////////
─────────────────────────────────────────
──┌───┐───────────────────┌───┬───┬───┐──
──│┌─┐│───────────────────└┐┌┐│┌─┐│┌─┐│──
──│└─┘├──┬─┬──┬──┬──┬─┐┌──┐│││││─│││─││──
──│┌──┤┌┐│┌┤┌┐│┌┐│┌┐│┌┐┤──┤││││└─┘││─││──
──││──│┌┐│││┌┐│└┘│└┘│││├──├┘└┘│┌─┐│└─┘│──
──└┘──└┘└┴┘└┘└┴─┐├──┴┘└┴──┴───┴┘─└┴───┘──
──────────────┌─┘│───────────────────────
──────────────└──┘───────────────────────
─────────────────────────────────────────
///////////////////////////////////////*/

interface IGuildRouter {
    function requireAssetTransferFromApproval() external view returns (bool);

    function invokeRental(uint256 _rentalId) external;

    function revokeRental(uint256 _rentalId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

//  ==========  EXTERNAL IMPORTS    ==========

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ILiquidDelegate is IERC721 {
    struct Rights {
        address depositor;
        uint96 expiration;
        address contract_;
        uint256 tokenId;
        address referrer;
    }

    function nextRightsId() external view returns (uint256 rightsId);

    function idsToRights(uint256 rightsId) external view returns (Rights memory);

    function create(address contract_, uint256 tokenId, uint96 expiration, address payable referrer) external;

    function burn(uint256 rightsId) external;
}