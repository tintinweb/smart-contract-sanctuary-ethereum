// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import {IConditionOracle} from "../interfaces/IConditionOracle.sol";

contract ERC721Holder is IConditionOracle, Ownable {
    using ERC165Checker for address;

    uint256 NO_REWARD = 119225934112114; // losser in hex
    bytes4 private constant IERC1155_INTERFACE = 0xd9b67a26;
    bytes4 private constant IERC1155_MINT_INTERFACE = 0x731133e9;
    bytes4 private constant IERC20_MINT_INTERFACE = 0x40c10f19;
    bytes4 private constant IERC20_INTERFACE = 0xffffffff;

    IERC721 public nftToken;
    bytes32 public integrityHash;

    uint256 public defaultReward;
    mapping(uint256 => uint256) rewards;
    mapping(address => bool) public canConsumeClaims;
    mapping(uint256 => bool) disqualifiedNfts;

    event SettingsChanged(
        bytes4 claimInterface,
        address indexed rewardToken,
        uint256 indexed rewardTokenId,
        bytes32 indexed integrityHash
    );

    event ConsumerAdded(
        address indexed consumer
    );

    event ConsumerRemoved(
        address indexed consumer
    );

    event RewardChanged(
        uint256 indexed nftId,
        uint256 indexed amount
    );

    event DefaultRewardChanged(
        uint256 amount
    );

    event ClaimedNftReward(
        address indexed account,
        uint256 indexed nftId,
        bytes32 indexed integrityHash,
        uint256 amount,
        bytes claim
    );
    
    constructor(
        address _nftToken,
        bytes4 _claimInterface,
        address _rewardToken,
        uint256 _rewardTokenId,
        uint256 _defaultReward,
        address _defaultConsumer
    ) {
        _changeSettings(_nftToken, _claimInterface, _rewardToken, _rewardTokenId);
        if (_defaultReward > 0) defaultReward = _defaultReward;
        if (_defaultConsumer != address(0)) {
            canConsumeClaims[_defaultConsumer] = true;
            emit ConsumerAdded(_defaultConsumer);
        }
    }

    /**
     * @dev Expose configuration API for reward engine for ERC721 holder rewards to owner address.
     * @param _nftToken ERC721 NFT contract address.
     * @param _rewardToken ERC20 or ERC1155 reward token contract address.
     * @param _rewardTokenId ERC1155 token id used for reward, pass 0 for ERC20 reward token.
     * @param _claimInterface interface used to distribute reward tokens, usually mint or transfer.
     */
    function adminChangeSettings(
      address _nftToken,
      bytes4 _claimInterface,
      address _rewardToken,
      uint256 _rewardTokenId
    ) external onlyOwner {
        _changeSettings(_nftToken, _claimInterface, _rewardToken, _rewardTokenId);
    }

    /**
     * @dev Authorize consumer contract to invalidate claims.
     * @param _consumer Reward amount in rewardToken.
     * @param _allow true to authorize, false to revoke authorization.
     */
    function adminSwitchConsumer(address _consumer, bool _allow) external onlyOwner {
        if (_allow) {
            canConsumeClaims[_consumer] = true;
            emit ConsumerAdded(_consumer);
        } else {
            canConsumeClaims[_consumer] = false;
            emit ConsumerRemoved(_consumer);
        }
    }

    /**
     * @dev Set default reward amount for NFT holding.
     * @param _amount Reward amount in rewardToken.
     */
    function adminSetDefaultReward(uint256 _amount) external onlyOwner {
        require(_amount >= 0, "invalid reward");
        defaultReward = _amount;
        emit DefaultRewardChanged(_amount);
    }

    /**
     * @dev Set reward amount for specific NFT id.
     * @param _amount Reward amount in rewardToken.
     * @param _nftIds Token ids to recieve reward.
     */
    function adminSetReward(uint256 _amount, uint256[] calldata _nftIds) external onlyOwner {
        require(_amount >= 0, "invalid reward");
        for (uint16 _i = 0; _i < _nftIds.length; _i++) {
            uint256 _nftId = _nftIds[_i];
            if (_amount == 0) {
                disqualifiedNfts[_nftId] = true;
                emit RewardChanged(_nftId, 0);
            } else {
                rewards[_nftId] = _amount;
                emit RewardChanged(_nftId, _amount);
            }
        }
    }

    /**
     * @dev Prepare claim based on NFT ids.
     * @param _claimInterface interface used to distribute reward tokens, usually mint or transfer.
     * @param _token ERC20 or ERC1155 reward token contract address.
     * @param _tokenId ERC1155 token id used for reward, pass 0 for ERC20 reward token.
     * @param _nftId NFT id ownec by account.
     * @return encoded claim.
     */
    function prepareClaim(
        bytes4 _claimInterface,
        address _token,
        uint256 _tokenId,
        uint256 _nftId
    ) public pure returns (bytes memory) {
        bytes32 _integrityHash = keccak256(abi.encodePacked(_token, _tokenId, _claimInterface));
        return abi.encode(_integrityHash, abi.encode(_nftId));
    }

    /**
     * @dev Check if there is reward for account for the claim.
     * @param _account Account which holds NFTs.
     * @param _claim ABI encoded integrity hash and NFT id to claim reward.
     * @return true if claim is valid.
     */
    function hasClaim(address _account, bytes calldata _claim) public view returns (bool) {
        (bytes32 _integrity, bytes memory _encNftId) = abi.decode(_claim, (bytes32, bytes));
        (uint256 _nftId) = abi.decode(_encNftId, (uint256));
        if (_integrity != integrityHash) return false;
        if (nftToken.ownerOf(_nftId) != _account) return false;
        uint256 _reward = getReward(_nftId);
        return _reward > 0;
    }

    /**
     * @dev Return reward amount for the claim, invalidating it in a process.
     * @param _account Account which holds NFTs.
     * @param _claim ABI encoded integrity hash and NFT id to claim reward.
     * @return amount of reward in tokens.
     */
    function consumeClaim(address _account, bytes calldata _claim) public returns (uint256) {
        require(canConsumeClaims[msg.sender], "not a consumer");
        (bytes32 _integrity, bytes memory _encNftId) = abi.decode(_claim, (bytes32, bytes));
        (uint256 _nftId) = abi.decode(_encNftId, (uint256));
        require(_integrity == integrityHash, "invalid claim");
        require(nftToken.ownerOf(_nftId) == _account, "not an owner");
        uint256 _reward = getReward(_nftId);
        if (_reward > 0) disqualifiedNfts[_nftId] = true;
        emit ConsumedClaim(_account, _claim);
        emit ClaimedNftReward(_account, _nftId, _integrity, _reward, _claim);
        return _reward;
    }

    /**
     * @dev Get reward amount for specific NFT ids. Default reward will be returned if specific reward is not set.
     * @param _nftId NFT id to recieve reward for.
     * @return reward for specific NFT.
     */
    function getReward(uint256 _nftId) public view returns (uint256) {
        if (disqualifiedNfts[_nftId]) return 0; 
        uint256 _reward = rewards[_nftId];
        if (_reward > 0) return _reward;
        return defaultReward;
    }

    /**
     * @dev Configure reward engine for ERC721 holder rewards.
     * @param _nftToken ERC721 NFT contract address.
     * @param _rewardToken ERC20 or ERC1155 reward token contract address.
     * @param _rewardTokenId ERC1155 token id used for reward, pass 0 for ERC20 reward token.
     * @param _claimInterface interface used to distribute reward tokens, usually mint or transfer.
     */
    function _changeSettings(address _nftToken, bytes4 _claimInterface, address _rewardToken, uint256 _rewardTokenId) internal {
        nftToken = IERC721(_nftToken);
        require(
            _claimInterface == IERC20_INTERFACE
            || _claimInterface == IERC20_MINT_INTERFACE
            || _claimInterface == IERC1155_MINT_INTERFACE
            || _rewardToken.supportsInterface(_claimInterface),
            "ConditionalDistributor: Invalid interface"
        );
        bytes32 _hash = keccak256(abi.encodePacked(_rewardToken, _rewardTokenId, _claimInterface));
        integrityHash = _hash;
        emit SettingsChanged(_claimInterface, _rewardToken, _rewardTokenId, _hash);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

// Allows anyone to claim a token if they exist in a merkle root.
interface IConditionOracle {
    // Returns true if provided claim is valid and more than 0.
    function hasClaim(address _account, bytes calldata _claim) external view returns (bool);
    // Returns amount of reward for specific claim.
    function consumeClaim(address _account, bytes calldata _claim) external returns (uint256);

    // This event is triggered whenever a claim is consumed
    event ConsumedClaim(
        address indexed account,
        bytes claim
    );
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