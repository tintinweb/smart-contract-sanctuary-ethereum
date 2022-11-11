// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./ISkeletonKeyDB.sol";
import "./Asset/IAsset.sol";

/**
 * @title SkeletonKeyDB
 * @dev A free and publicly reusable, enterprise-grade access credential database.
 * To make sure your contract is compatible, see IAsset.sol.
 *
 * Instead of having a rigid definition of ownership, this contract allows you to
 * tie ownership and access to `OnlyOwner` functions to the ownership of an NFT.
 * By extension, you are able to trustlessly sell ownership of a profitable contract
 * by simply transferring the `master asset` (called the skeleton key) to another
 * interested party; without any possibility of revocation. Due to the sensitive
 * nature of these newly designated skeleton keys, this contract contains a fallback
 * system of ownership to keep hackers at bay while simultaneously making it easier
 * to operate these smart contracts at scale.
 *
 * Authority over an asset is divided into three roles:
 * - Tier 1 || Administrative Key Holders
 * - Tier 2 || the Executive Key Holder
 * - Tier 3 || the Skeleton Key Holder (Master Asset)
 *
 * Administrative Key (Employee Use)
 * Holders of these keys are given basic contract access; which includes small value
 * updates or data entry. Tier 1 access is not meant to include potentially destructive
 * permissions; which is more appropriate for Tier 2 permissions. Due to limitations
 * in Solidity (i.e. cannot write structures to storage mappings), all administrative
 * keys for an asset are bound to a single token contract to account for team expansion.
 * It would be best to deploy this contract yourself, with or without customizations.
 *
 * For non-contract assets, deploy a standard ERC721 contract that extends the provided
 * Asset.sol for compatibility.
 *
 * Executive Key (Day-to-Day Use)
 * In addition to posessing all of the same rights and privileges of administrative key
 * holders, Executive key holders can grant or revoke administrative access to contracts
 * via bulk actions. This key is meant to be owned and operated by the owner or fiduciary
 * of the skeleton key. While the executive key can be used to cause mayhem, there is
 * a fallback.
 *
 * Skeleton Key (Emergency Use)
 * The holder of this key has supreme authority in this database contract; meaning that
 * you can effectively delete or overwrite other keys, including itself. If your intention
 * is to sell this level of authority as an asset, this is the token to put into escrow.
 * It is meant to be held in a cold wallet, where it will be the safest; never connected
 * to the internet or put into a browser except for transfer or to redesignate the
 * executive key.
 *
 * @author CyAaron Tai Nava || hemlockStreet.x
 */
contract SkeletonKeyDB is ISkeletonKeyDB {
    string public constant name = "SkeletonKeyDB";

    constructor() {}

    struct Credentials {
        address token;
        uint id;
    }

    mapping(address => Credentials) public skeletonKeys;
    mapping(address => Credentials) public executiveKeys;

    mapping(address => address) public adminKeyTokens;
    mapping(address => uint[]) public adminKeyIds;

    function skeletonKeyHolder(address asset)
        public
        view
        override
        returns (address)
    {
        Credentials memory cred = skeletonKeys[asset];
        IERC721 nft = IERC721(cred.token);
        return nft.ownerOf(cred.id);
    }

    function executiveKeyHolder(address asset)
        public
        view
        override
        returns (address)
    {
        Credentials memory cred = executiveKeys[asset];
        IERC721 nft = IERC721(cred.token);
        return nft.ownerOf(cred.id);
    }

    function adminKeyHolders(address asset)
        public
        view
        override
        returns (address[] memory)
    {
        IERC721 nft = IERC721(adminKeyTokens[asset]);
        uint[] memory ids = adminKeyIds[asset];
        address[] memory result = new address[](ids.length);
        for (uint i = 0; i < ids.length; i++) {
            result[i] = nft.ownerOf(ids[i]);
        }
        return result;
    }

    function akIds(address asset)
        public
        view
        override
        returns (uint[] memory ids)
    {
        uint[] memory result = adminKeyIds[asset];
        ids = result;
    }

    function diag(address asset)
        public
        view
        override
        returns (
            address skHolder,
            address skToken,
            uint skId,
            address ekHolder,
            address ekToken,
            uint ekId,
            address[] memory akHolders,
            address akToken,
            uint[] memory akId
        )
    {
        skHolder = skeletonKeyHolder(asset);
        Credentials memory skCred = skeletonKeys[asset];
        skToken = skCred.token;
        skId = skCred.id;

        ekHolder = executiveKeyHolder(asset);
        Credentials memory ekCred = executiveKeys[asset];
        ekToken = ekCred.token;
        ekId = ekCred.id;

        akHolders = adminKeyHolders(asset);
        akToken = adminKeyTokens[asset];
        akId = adminKeyIds[asset];
    }

    function isAdminKeyHolder(address asset, address user)
        public
        view
        override
        returns (bool)
    {
        address[] memory authorized = adminKeyHolders(asset);
        for (uint i = 0; i < authorized.length; i++) {
            if (user == authorized[i]) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Easy way to verify asset authority on-chain. If this is too convenient, you can
     * use 3 different calls and bloat your contract with unnecessary code.
     *
     * @param asset the address of an asset you want to validate authority for
     * @param holder the address of a wallet you want to check
     *
     * output 0 ==> no authority
     * output 1 ==> admin authority (basic access)
     * output 2 ==> executive authority (greater authority - to manage administrators)
     * output 3 ==> skeleton key authority (supreme authority - to manage the executive)
     */
    function accessTier(address asset, address holder)
        public
        view
        override
        returns (uint)
    {
        if (skeletonKeyHolder(asset) == holder) return 3;
        else if (executiveKeyHolder(asset) == holder) return 2;
        else if (isAdminKeyHolder(asset, holder)) return 1;
        else return 0;
    }

    modifier RequiredTier(address asset, uint tier) {
        require(accessTier(asset, msg.sender) >= tier, "!Authorized");
        _;
    }

    /**
     * @dev Register your asset and skeleton key (backup) simultaneously.
     * Keep this in a secure location (preferably a cold wallet).
     *
     * @param asset the address of your asset to manage
     * @param token the address of the NFT you want to act as the authority token
     * @param id the token id mapped to the skeleton key holder
     */
    function defineSkeletonKey(
        address asset,
        address token,
        uint id
    ) public override {
        if (skeletonKeys[asset].token == address(0)) {
            address deployer;
            (, , deployer) = IAsset(asset)._skdbMetadata();
            require(msg.sender == deployer, "!Authorized");
            skeletonKeys[asset] = Credentials(token, id);
        } else {
            require(msg.sender == skeletonKeyHolder(asset), "!Authorized");
            address newKeyHolder = IERC721(token).ownerOf(id);
            require(msg.sender == newKeyHolder, "!newKeyHolder");
            skeletonKeys[asset].token = token;
            skeletonKeys[asset].id = id;
        }
    }

    /**
     * @dev Register your "day-to-day" access token.
     * This is fine to leave in your metamask.
     *
     * @param asset the address of your asset to manage
     * @param token the address of the NFT you want to act as the authority token
     * @param id the token id mapped to the executive key holder
     */
    function defineExecutiveKey(
        address asset,
        address token,
        uint id
    ) public override RequiredTier(asset, 3) {
        executiveKeys[asset].token = token;
        executiveKeys[asset].id = id;
    }

    /**
     * @dev Register a series for the admin team.
     * They will need NFTs from this collection if they want to do their jobs.
     * This is fine to leave in your metamask.
     *
     * @param asset the address of your asset to manage
     * @param token the address of the NFT you want to act as the authority token
     * @param ids the token ids mapped to the admins
     */
    function defineAdminKey(
        address asset,
        address token,
        uint[] memory ids
    ) public override RequiredTier(asset, 2) {
        adminKeyTokens[asset] = token;
        if (adminKeyIds[asset].length > 0) {
            if (ids.length == 0) delete adminKeyIds[asset];
            else adminKeyIds[asset] = ids;
        } else adminKeyIds[asset] = ids;
    }

    function uintPresent(uint target, uint[] memory arr)
        internal
        pure
        returns (bool)
    {
        for (uint i = 0; i < arr.length; i++) {
            if (target == arr[i]) return true;
        }
        return false;
    }

    /**
     * @dev Manage your admin team with bulk actions as the skeleton or executive.
     *
     * @param asset the address of your asset to manage
     * @param ids the ids you want to manage
     * @param grant setting this to true will add the ids to the admin team, false will do the opposite.
     */
    function manageAdmins(
        address asset,
        uint[] memory ids,
        bool grant
    ) public override RequiredTier(asset, 2) {
        uint[] memory current = adminKeyIds[asset];

        if (grant) {
            for (uint i = 0; i < ids.length; i++) {
                uint thisId = ids[i];
                if (!uintPresent(thisId, current))
                    adminKeyIds[asset].push(thisId);
            }
        } else {
            uint newLength;
            for (uint i = 0; i < current.length; i++) {
                if (!uintPresent(current[i], ids)) newLength++;
            }
            uint[] memory newIds = new uint[](newLength);
            uint idx;
            for (uint i = 0; i < current.length; i++) {
                uint thisId = current[i];
                if (!uintPresent(thisId, ids)) {
                    newIds[idx] = thisId;
                    idx++;
                }
            }
            adminKeyIds[asset] = newIds;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

/**
 * @title ISkeletonKeyDB
 * @dev SkeletonKeyDB Interface
 *
 * @author CyAaron Tai Nava || hemlockStreet.x
 */
interface ISkeletonKeyDB {
    function skeletonKeyHolder(address asset) external view returns (address);

    function executiveKeyHolder(address asset) external view returns (address);

    function adminKeyHolders(address asset)
        external
        view
        returns (address[] memory);

    function akIds(address asset) external view returns (uint[] memory ids);

    function diag(address asset)
        external
        view
        returns (
            address skHolder,
            address skToken,
            uint skId,
            address ekHolder,
            address ekToken,
            uint ekId,
            address[] memory akHolders,
            address akToken,
            uint[] memory akId
        );

    function isAdminKeyHolder(address asset, address user)
        external
        view
        returns (bool);

    function accessTier(address asset, address holder)
        external
        view
        returns (uint);

    function defineSkeletonKey(
        address asset,
        address token,
        uint id
    ) external;

    function defineExecutiveKey(
        address asset,
        address token,
        uint id
    ) external;

    function defineAdminKey(
        address asset,
        address token,
        uint[] memory ids
    ) external;

    function manageAdmins(
        address asset,
        uint[] memory ids,
        bool grant
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

/**
 * @title IAsset
 * @dev Standard Asset Interface for SkeletonKeyDB
 *
 * @author CyAaron Tai Nava || hemlockStreet.x
 */
interface IAsset {
    function _skdbMetadata()
        external
        view
        returns (
            address asset,
            address skdb,
            address deployer
        );

    function _setSkdb(address newDb) external;

    function _setAsset(address newAst) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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