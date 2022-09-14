// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../UniqOperator/IUniqOperator.sol";

contract UniqRedeemV3 is Ownable {
    modifier ownerOrOperator() {
        require(
            owner() == msg.sender ||
                operator.isOperator(accessLevel, msg.sender),
            "Only owner or proxy allowed"
        );
        _;
    }

    event Redeemed(
        address indexed _contractAddress,
        uint256 indexed _tokenId,
        address indexed _redeemerAddress,
        uint256 _networkId,
        string _redeemerName,
        uint256[] _purposes
    );

    /// ----- VARIABLES ----- ///
    IUniqOperator public operator;
    uint256 public accessLevel;

    /// @dev Returns true if token was redeemed
    mapping(uint256 => mapping(address => mapping(uint256 => mapping(uint256 => bool))))
        internal _isTokenRedeemedForPurpose;

    /// ----- VIEWS ----- ///
    /// @notice Returns true if token was claimed
    function isTokenRedeemedForPurpose(
        address _address,
        uint256 _tokenId,
        uint256 _purpose,
        uint256 _network
    ) external view returns (bool) {
        return
            _isTokenRedeemedForPurpose[_network][_address][_tokenId][_purpose];
    }

    /// ----- OWNER METHODS ----- ///
    constructor(IUniqOperator operatorAddress) {
        operator = operatorAddress;
        accessLevel = 1;
    }

    function redeemTokensAsAdmin(
        address[] memory _tokenContracts,
        uint256[] memory _tokenIds,
        uint256[] memory _purposes,
        string[] memory _redeemerName
    ) external ownerOrOperator {
        uint256[] memory networks = new uint256[](_tokenContracts.length);
        address[] memory owners = new address[](_tokenContracts.length);
        for (uint256 i = 0; i < _tokenContracts.length; i++) {
            networks[i] = 137;
            owners[i] = IERC721(_tokenContracts[i]).ownerOf(_tokenIds[i]);
        }
        redeemTokensAsAdmin(
            _tokenContracts,
            _tokenIds,
            _purposes,
            owners,
            _redeemerName,
            networks
        );
    }

    function redeemTokensAsAdmin(
        address[] memory _tokenContracts,
        uint256[] memory _tokenIds,
        uint256[] memory _purposes,
        address[] memory _owners,
        string[] memory _redeemerName,
        uint256[] memory _networks
    ) public ownerOrOperator {
        require(
            _tokenContracts.length == _tokenIds.length &&
                _tokenIds.length == _purposes.length,
            "Array length mismatch"
        );
        uint256 len = _tokenContracts.length;
        for (uint256 i = 0; i < len; i++) {
            require(
                !_isTokenRedeemedForPurpose[_networks[i]][_tokenContracts[i]][
                    _tokenIds[i]
                ][_purposes[i]],
                "Can't be redeemed again"
            );
            _isTokenRedeemedForPurpose[_networks[i]][_tokenContracts[i]][
                _tokenIds[i]
            ][_purposes[i]] = true;
            uint256[] memory purpose = new uint256[](1);
            purpose[0] = _purposes[i];
            emit Redeemed(
                _tokenContracts[i],
                _tokenIds[i],
                _owners[i],
                _networks[i],
                _redeemerName[i],
                purpose
            );
        }
    }

    function redeemTokenForPurposesAsAdmin(
        address _tokenContract,
        uint256 _tokenId,
        uint256 _network,
        uint256[] memory _purposes,
        address _tokenOwner,
        string memory _redeemerName
    ) external ownerOrOperator {
        uint256 len = _purposes.length;
        address[] memory _tokenContracts = new address[](len);
        uint256[] memory _tokenIds = new uint256[](len);
        for (uint256 i = 0; i < len; i++) {
            _tokenContracts[i] = _tokenContract;
            _tokenIds[i] = _tokenId;
            require(
                !_isTokenRedeemedForPurpose[_network][_tokenContract][_tokenId][
                    _purposes[i]
                ],
                "Can't be claimed again"
            );
            _isTokenRedeemedForPurpose[_network][_tokenContract][_tokenId][
                _purposes[i]
            ] = true;
        }
        emit Redeemed(
            _tokenContract,
            _tokenId,
            _tokenOwner,
            _network,
            _redeemerName,
            _purposes
        );
    }

    function setStatusesForTokens(
        address[] memory _tokenAddresses,
        uint256[] memory _tokenIds,
        uint256[] memory _purposes,
        uint256[] memory _networks,
        bool[] memory isRedeemed
    ) external ownerOrOperator {
        uint256 len = _tokenAddresses.length;
        require(
            len == _tokenIds.length &&
                len == _purposes.length &&
                len == isRedeemed.length,
            "Arrays lengths mismatch"
        );
        for (uint256 i = 0; i < len; i++) {
            _isTokenRedeemedForPurpose[_networks[i]][_tokenAddresses[i]][
                _tokenIds[i]
            ][_purposes[i]] = isRedeemed[i];
        }
    }

    function editOperatorAddress(IUniqOperator newAddress) external onlyOwner {
        operator = newAddress;
    }

    function editAccessLevel(uint256 newLevel) external onlyOwner {
        accessLevel = newLevel;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface IUniqOperator {
    function isOperator(uint256 operatorType, address operatorAddress)
        external
        view
        returns (bool);

    function uniqAddresses(uint256 index) external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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