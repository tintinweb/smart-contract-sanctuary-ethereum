// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./staking/interfaces/IERC721Staking.sol";

contract DCCConnect {
    uint256 constant MAX_INT = 2**256 - 1;
    IERC721 public immutable dccContract;
    IERC721Staking public immutable stakingContract;

    //dccUser => ncAddress
    mapping(address => address) private dccUserToNCAddress;
    //ncAddress => dccUserss
    mapping(address => address[]) private ncAddressToDCCUser;
    //dccUser => avatarAddress => dcc id
    mapping(address => mapping(address => uint256)) private ncAvatarToDCC;

    /* ====== EVENTS ======= */

    event CONNECTED(address ncAddress);
    event DISCONNECTED(address ncAddress);
    event ASSIGN_AVATAR(address avatarAddress, uint256 dccId);
    event CLEAR_AVATAR(address avatarAddress);

    /* ====== CONSTRUCTOR ====== */

    constructor(IERC721 _dccContract, IERC721Staking _stakingContract) {
        dccContract = _dccContract;
        stakingContract = _stakingContract;
    }

    /* ====== PUBLIC FUNCTIONS ====== */

    function connect9CAddress(address _ncAddress) external {
        require(dccUserToNCAddress[msg.sender] == address(0), "Already Connected");

        dccUserToNCAddress[msg.sender] = _ncAddress;
        ncAddressToDCCUser[_ncAddress].push(msg.sender);

        emit CONNECTED(_ncAddress);
    }

    function disconnect9CAddress() external {
        require(dccUserToNCAddress[msg.sender] != address(0), "Not Connected");

        address _ncAddress = dccUserToNCAddress[msg.sender];
        uint256 _len = ncAddressToDCCUser[_ncAddress].length;
        uint256 _removeIdx = MAX_INT;
        for (uint i = 0; i < _len; i++) {
            if (ncAddressToDCCUser[_ncAddress][i] == msg.sender) {
                _removeIdx = i;
            }
        }
        require(_removeIdx < _len);

        delete dccUserToNCAddress[msg.sender];
        ncAddressToDCCUser[_ncAddress][_removeIdx] = ncAddressToDCCUser[_ncAddress][_len - 1];
        ncAddressToDCCUser[_ncAddress].pop();

        emit DISCONNECTED(_ncAddress);
    }

    function assignAvatarDCC(uint256 _dccId, address _avatarAddress) external {
        require(dccUserToNCAddress[msg.sender] != address(0), "Not Connected 9C Address");
        ncAvatarToDCC[msg.sender][_avatarAddress] = _dccId;

        emit ASSIGN_AVATAR(_avatarAddress, _dccId);
    }

    function clearAvatarDCC(address _avatarAddress) external {
        delete ncAvatarToDCC[msg.sender][_avatarAddress];

        emit CLEAR_AVATAR(_avatarAddress);
    }

    /* ====== VIEW FUNCTIONS ====== */

    function getConnectedDCCUsers(address _ncAddress) external view returns (address[] memory) {
        return ncAddressToDCCUser[_ncAddress];
    }

    function getDCCForAvatar(address _dccUser, address _ncAddress, address _avatarAddress) external view returns (uint256) {
        uint256 _dccId = ncAvatarToDCC[_dccUser][_avatarAddress];
        if (_dccId > 0) {
            if (dccUserToNCAddress[_dccUser] != _ncAddress) return 0;
            if (!_isValidDCCOwner(_dccId, _dccUser)) return 0;
        }

        return _dccId;
    }

    /* ====== INTERNAL FUNCTIONS ====== */

    function _isValidDCCOwner(uint256 _dccId, address _dccOwner) internal view returns (bool) {
        if (dccContract.ownerOf(_dccId) == _dccOwner) return true;

        uint256[] memory _tokenIds = stakingContract.getStaking(_dccOwner);
        for (uint i = 0; i < _tokenIds.length; i++) {
            if (_tokenIds[i] == _dccId) return true;
        }

        return false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IERC721Staking {
    error NoTokenID();
    error ExceedMaxTokenLimit();
    error NotStaking();

    function stake(address _user, uint256[] memory _tokenIds) external;
    function unstake(address _user, uint256[] memory _tokenIds, uint256[] memory _tokenIndexes) external;
    function claim(address _user) external;

    function getStakeToken() external view returns (address);
    function countStaking(address _user) external view returns (uint256);
    function getStaking(address _user) external view returns (uint256[] memory);
    function isStaking(address _user, uint256[] memory _tokenIds, uint256[] memory _tokenIndexes) external view returns (bool);
    function getRewardsToClaim(address _user) external view returns (uint256);
}

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