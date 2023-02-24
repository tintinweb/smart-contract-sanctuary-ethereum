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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

/*
    address 查询这个列表
    id 查询这条数据
    id 取回
    {"address":"0xxxxxx","id":"1","tokenIdList":["#123","#124"],"stactStart": uint256}
 */

interface IMai {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

contract PledgeContract is Ownable, ReentrancyGuard {
    struct OrderBook {
        address player;
        uint256[] tokenIdList;
        uint256 startTime;
        uint256 status; // 1 already pledged 2 remove pledge
    }

    uint256 public stackMin = 21 days;

    uint256 public orderIndex = 1;

    mapping(uint256 => OrderBook) orderBooks;

    IMai public Mai;

    event Pledge(uint256 id);
    event RemovePledge(uint256 id);

    modifier preCheck(uint256[] memory _tokenIdList) {
        bool isC = isContract(msg.sender);
        require(!isC, "contract err");
        uint256 idsLength = _tokenIdList.length;
        require(idsLength <= 10, "illegal length");
        require(idsLength == 1 || idsLength == 3 || idsLength == 5 || idsLength == 10, "stacking wrong number");
        // unique tokenId
        for (uint256 i = 0; i < idsLength - 1; i++) {
            for (uint256 j = i + 1; j < idsLength; j++) {
                require(_tokenIdList[i] != _tokenIdList[j], "tokenId non-uniqueness");
            }
        }
        // check owner
        for (uint256 i = 0; i < idsLength; i++) {
            address owner = Mai.ownerOf(_tokenIdList[i]);
            require(owner == msg.sender, "illegal owner");
        }
        _;
    }

    function setStackMin(uint256 _stackMin) external onlyOwner {
        stackMin = _stackMin;
    }

    function setMai(IMai _mai) external onlyOwner {
        Mai = _mai;
    }

    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(addr) }
        return size > 0; // true means contract
    }

    function getTotalOb() external view returns(uint256) {
        return orderIndex - 1;
    }
    // get pledge info by orderBook id
    function getPledge(uint256 _obId) external view returns (uint256, uint256, address, uint256, uint256[] memory) {
        address player = orderBooks[_obId].player;
        uint256 startTime = orderBooks[_obId].startTime;
        uint256[] memory tokenIdList = orderBooks[_obId].tokenIdList;
        uint256 status = orderBooks[_obId].status;
        return (_obId, status, player, startTime, tokenIdList);
    }

    function pledge(uint256[] memory _tokenIdList) external preCheck(_tokenIdList) nonReentrant {
        uint256 obIndex = orderIndex;
        orderIndex++;
        for (uint256 i = 0; i < _tokenIdList.length; i++) {
            // TODO
            Mai.transferFrom(msg.sender, address(this), _tokenIdList[i]);
        }

        OrderBook storage ob = orderBooks[obIndex];
        ob.status = 1;
        ob.player = msg.sender;
        ob.tokenIdList = _tokenIdList;
        ob.startTime = block.timestamp;
        emit Pledge(obIndex); 
    }
    // 取出
    function removePledge(uint256 _obId) external nonReentrant {
        require(_obId <= orderIndex, "order err");
        require(orderBooks[_obId].player == msg.sender, "auth err");
        require(block.timestamp - orderBooks[_obId].startTime > stackMin, "withdraw err");
        uint256[] memory list = orderBooks[_obId].tokenIdList;
        for (uint256 i = 0; i < list.length; i++) {
            Mai.safeTransferFrom(address(this), msg.sender, list[i]);
        }
        orderBooks[_obId].status = 2;
        emit RemovePledge(_obId);
    }
}