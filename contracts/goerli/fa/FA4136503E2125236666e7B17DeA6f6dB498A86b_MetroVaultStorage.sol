// SPDX-License-Identifier: MIT LICENSE

pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "../../lib/Controllable.sol";
import "./structs/MetroVaultStorageStructs.sol";
import "./interfaces/IMetroVaultStorage.sol";
import "../../nfts/interfaces/IMetroNFTLookup.sol";

contract MetroVaultStorage is Controllable, IMetroVaultStorage {

    address public nftLookupAddress;
    
    mapping(uint256 => Stake) vault;
    mapping(address => Account) accounts;

    event BlockStaked(address indexed owner, uint256 indexed tokenId, uint256 timestamp, uint16 indexed cityId, uint40 extra);
    event BlockUnstaked(address indexed owner, uint256 indexed tokenId, uint256 timestamp, uint16 indexed cityId, uint40 extra);
    event BlockTransfer(address indexed owner, uint256 indexed tokenId,  address indexed to);

    constructor(address _nftLookupAddress) {
      nftLookupAddress = _nftLookupAddress;
    }

    function setNFTLookup(address _nftLookupAddress) external onlyOwner {
        nftLookupAddress = _nftLookupAddress;
    }

    function getNFTContractAddress(uint256 tokenId) public view returns (address) {
        return IMetroNFTLookup(nftLookupAddress).getNFTContractAddress(tokenId);
    }

    function balanceOf(address owner) public view returns (uint256){
      return accounts[owner].balance;
    }

    function ownerOf(uint256 tokenId) public view returns (address){
      address owner = vault[tokenId].owner;
      require(owner != address(0x0), 'Token not in vault');
      return owner;
    }

    function getAccount(address owner) external view returns (Account memory) {
        return accounts[owner];
    }

    function getStake(uint256 tokenId) external view returns (Stake memory) {
        return vault[tokenId];
    }

    function stakeBlocks(address owner, uint256[] calldata tokenIds, uint16 cityId, uint40 extra) external onlyController {
        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            Stake storage s = vault[tokenId];
            require(s.owner == address(0), "Token is already staked");

            IERC721 nft = IERC721(getNFTContractAddress(tokenId));
            nft.transferFrom(owner, address(this), tokenId);

            s.owner = owner;
            s.timestamp = uint40(block.timestamp);
            s.cityId = cityId;
            s.extra = extra;

            emit BlockStaked(owner, tokenId, uint40(block.timestamp), cityId, extra);
        }

        accounts[owner].balance += uint24(tokenIds.length);
    }

    function stakeBlocks(
      address owner,
      uint256[] calldata tokenIds,
      uint16[] calldata cityIds,
      uint40[] calldata extras,
      uint40[] calldata timestamps
    ) external onlyController {

        require(tokenIds.length == cityIds.length && tokenIds.length == extras.length && tokenIds.length == timestamps.length);

        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            Stake storage s = vault[tokenId];
            require(s.owner == address(0), "Token is already staked");

            IERC721 nft = IERC721(getNFTContractAddress(tokenId));
            nft.transferFrom(owner, address(this), tokenId);

            s.owner = owner;
            s.timestamp = timestamps[i];
            s.cityId = cityIds[i];
            s.extra = extras[i];

            emit BlockStaked(owner, tokenId, timestamps[i], cityIds[i], extras[i]);
        }

        accounts[owner].balance += uint24(tokenIds.length);
    }

    function stakeFromMint(address owner, uint256[] calldata tokenIds, uint16 cityId, uint40 extra) public onlyController {
        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];

            Stake storage s = vault[tokenId];
            s.owner = owner;
            s.timestamp = uint40(block.timestamp);
            s.cityId = cityId;
            s.extra = extra;

            emit BlockStaked(owner, tokenId, block.timestamp, cityId, extra);
        }

        accounts[owner].balance += uint24(tokenIds.length);
    }

    function stakeFromMint(address owner, uint256[] calldata tokenIds, uint16 cityId, uint32 extra) external onlyController {
        stakeFromMint(owner, tokenIds, cityId, uint40(extra));
    }

    function unstakeBlocks(address owner, uint256[] calldata tokenIds) external onlyController {
      _unstakeBlocks(owner, owner, tokenIds);
    }

    function unstakeBlocksTo(address owner, address to, uint256[] calldata tokenIds) external onlyController {
      _unstakeBlocks(owner, to, tokenIds);
    }

    function _unstakeBlocks(address owner, address to, uint256[] calldata tokenIds) private {
        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];      
            Stake memory staked = vault[tokenId];
            require(owner == staked.owner, "Not an owner");

            delete vault[tokenId];
            IERC721 nft = IERC721(getNFTContractAddress(tokenId));
            nft.transferFrom(address(this), to, tokenId);
            emit BlockUnstaked(staked.owner, tokenId, block.timestamp, staked.cityId, staked.extra);
        }

        accounts[owner].balance -= uint24(tokenIds.length);
    }

    function setStake(uint256 tokenId, Stake calldata newStake) external onlyController {
        require(newStake.owner != address(0), "Owner cannot be nil");

        if (vault[tokenId].owner != newStake.owner) {
          accounts[vault[tokenId].owner].balance -= 1;
          accounts[newStake.owner].balance += 1;
          emit BlockTransfer(vault[tokenId].owner, tokenId, newStake.owner);
        }

        vault[tokenId] = newStake;
    }

    function setStakeTimestamp(uint256[] calldata tokenIds, uint40 timestamp) external onlyController {
        for (uint i = 0; i < tokenIds.length; i++) {
          uint256 tokenId = tokenIds[i];
          Stake storage staked = vault[tokenId];
          staked.timestamp = timestamp;
        }
    }

    function setStakeCity(uint256[] calldata tokenIds, uint16 cityId, bool resetTimestamp) external onlyController {
        for (uint i = 0; i < tokenIds.length; i++) {
          uint256 tokenId = tokenIds[i];
          Stake storage staked = vault[tokenId];
          staked.cityId = cityId;
          if (resetTimestamp) {
            staked.timestamp = uint40(block.timestamp);
          }
        }
    }

    function setStakeExtra(uint256[] calldata tokenIds, uint40 extra, bool resetTimestamp) external onlyController {
        for (uint i = 0; i < tokenIds.length; i++) {
          uint256 tokenId = tokenIds[i];
          Stake storage staked = vault[tokenId];
          staked.extra = extra;
          if (resetTimestamp) {
            staked.timestamp = uint40(block.timestamp);
          }
        }
    }

    function changeStakeOwner(uint256 tokenId, address newOwner, bool resetTimestamp) external onlyController {
        require(newOwner != address(0x0), "Owner cannot be nil");

        Stake storage s = vault[tokenId];

        require(s.owner != address(0x0), "No stake found");

        emit BlockTransfer(s.owner, tokenId, newOwner);

        accounts[s.owner].balance -= 1;
        accounts[newOwner].balance += 1;

        s.owner = newOwner;

        if (resetTimestamp) {
          s.timestamp = uint40(block.timestamp);
        }
    }

    function setStakeOwner(uint256[] calldata tokenIds, address newOwner, bool resetTimestamp) external onlyController {
        require(newOwner != address(0), "Owner cannot be nil");

        address[] memory owners = new address[](tokenIds.length);
        uint256[] memory amounts = new uint256[](tokenIds.length);

        for (uint i = 0; i < tokenIds.length; i++) {
          uint256 tokenId = tokenIds[i];
          Stake storage staked = vault[tokenId];

          for (uint256 j; j < owners.length; j++) {
            if (owners[j] == address(0x0)) {
              owners[j] = staked.owner; 
              amounts[j] = 1;
              break;
            } else if (owners[j] == staked.owner) {
              amounts[j] += 1;
              break;
            }
          }

          emit BlockTransfer(staked.owner, tokenId, newOwner);

          staked.owner = newOwner;
          if (resetTimestamp) {
            staked.timestamp = uint40(block.timestamp);
          }
        }

        for (uint256 j; j < owners.length; j++) {
          if (owners[j] != address(0x0)) {
            accounts[owners[j]].balance -= uint24(amounts[j]); 
          } else {
            break;
          }
        }

        accounts[newOwner].balance += uint24(tokenIds.length);
    }

    function setAccountExtra(address owner, uint232 extra) external onlyController {
        accounts[owner].extra = extra;
    }

    function setAccountsExtra(address[] calldata owners, uint232[] calldata extras) external onlyController {
        require(owners.length == extras.length, "Incorrect input");

        for (uint i; i < owners.length; i++) {
          address owner = owners[i];
          uint232 extra = extras[i];
          accounts[owner].extra = extra;
        }
    }

    function deleteStake(uint256[] calldata tokenIds) public onlyController {
        address[] memory owners = new address[](tokenIds.length);
        uint256[] memory amounts = new uint256[](tokenIds.length);

        for (uint i = 0; i < tokenIds.length; i++) {
          uint256 tokenId = tokenIds[i];

          Stake memory staked = vault[tokenId];
          delete vault[tokenId];

          for (uint256 j; j < owners.length; j++) {
            if (owners[j] == address(0x0)) {
              owners[j] = staked.owner; 
              amounts[j] = 1;
              break;
            } else if (owners[j] == staked.owner) {
              amounts[j] += 1;
              break;
            }
          }

        }

        for (uint256 j; j < owners.length; j++) {
          if (owners[j] != address(0x0)) {
            accounts[owners[j]].balance -= uint24(amounts[j]); 
          } else {
            break;
          }
        }

    }

    // should never be used inside of transaction because of gas fee
    function tokensOfOwner(address owner, uint256 start, uint256 stop) public view returns (uint256[] memory) {
        uint256 balance = accounts[owner].balance;
        if (balance == 0) {
            return new uint256[](0);
        }

        uint256 index = 0;
        uint256[] memory tmp = new uint256[](balance);

        for(uint tokenId = start; tokenId <= stop; tokenId++) {
            if (vault[tokenId].owner == owner) {
                    tmp[index] = tokenId;
                    index += 1;
                    if (index == balance) {
                        break;
                }
            }
        }

        uint256[] memory tokens = new uint256[](index);
        for(uint i = 0; i < index; i++) {
            tokens[i] = tmp[i];
        }

        return tokens;
    }
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

pragma solidity 0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Controllable is Ownable {

    mapping(address => bool) private controllers;

    function addController(address controller) external onlyOwner {
      controllers[controller] = true;
    }

    function removeController(address controller) external onlyOwner {
      controllers[controller] = false;
    }

    function isController(address account) public view returns (bool) {
        return controllers[account];
    }

    modifier onlyController() {
        require(controllers[_msgSender()], "Controllable: caller is not the controller");
        _;
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity 0.8.12;

struct Stake {
    address owner;
    uint40 timestamp;
    uint16 cityId;
    uint40 extra;
}

struct Account {
    uint24 balance;
    uint232 extra;
}

// SPDX-License-Identifier: MIT LICENSE

import "../structs/MetroVaultStorageStructs.sol";
import "../../../nfts/interfaces/IMetroNFTLookup.sol";


pragma solidity 0.8.12;


interface IMetroVaultStorage is IMetroNFTLookup {

    function getStake(uint256 tokenId) external view returns (Stake memory);
    function getAccount(address owner) external view returns (Account memory);

    function setStake(uint256 tokenId, Stake calldata newStake) external;
    function setStakeTimestamp(uint256[] calldata tokenIds, uint40 timestamp) external;
    function setStakeCity(uint256[] calldata tokenIds, uint16 cityId, bool resetTimestamp) external;
    function setStakeExtra(uint256[] calldata tokenIds, uint40 extra, bool resetTimestamp) external;
    function setStakeOwner(uint256[] calldata tokenIds, address owner, bool resetTimestamp) external;
    function changeStakeOwner(uint256 tokenId, address newOwner, bool resetTimestamp) external;

    function setAccountsExtra(address[] calldata owners, uint232[] calldata extras) external;
    function setAccountExtra(address owner, uint232 extra) external;

    function deleteStake(uint256[] calldata tokenIds) external;
    
    function stakeBlocks(address owner, uint256[] calldata tokenIds, uint16 cityId, uint40 extra) external;
    function stakeFromMint(address owner, uint256[] calldata tokenIds, uint16 cityId, uint40 extra) external;
    function unstakeBlocks(address owner, uint256[] calldata tokenIds) external;
    function unstakeBlocksTo(address owner, address to, uint256[] calldata tokenIds) external;
    
    function tokensOfOwner(address account, uint256 start, uint256 stop) external view returns (uint256[] memory);

    function stakeBlocks(
      address owner,
      uint256[] calldata tokenIds,
      uint16[] calldata cityIds,
      uint40[] calldata extras,
      uint40[] calldata timestamps
    ) external;
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity 0.8.12;

interface IMetroNFTLookup {

    function getNFTContractAddress(uint256 tokenId) external view returns (address);
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
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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