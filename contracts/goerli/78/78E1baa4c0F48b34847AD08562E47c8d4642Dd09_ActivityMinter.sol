//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IPOAP.sol";

import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

contract ActivityMinter is Ownable, IERC1155Receiver {

    IPOAP immutable public poap;
    uint public startTokenId = 10000; 
    mapping(address => bool) public admins;    

    struct Activity {
        uint32 startTs;
        uint32 endTs;
        uint192 supply; 
        address creator;
    }

    mapping(uint => Activity) public activities;
    mapping(uint => mapping (address => bool )) claimed;


    event SetAdmin(address admin, bool enabled);
    event ActivityCreated(uint tokenId, address creator, uint32 startTs, uint32 endTs);
    event Claimed(uint tokenId, address user);

    constructor(address _poap) {
        poap = IPOAP(_poap);
        admins[msg.sender] = true;
        emit SetAdmin(msg.sender, true);
    }


    function supportsInterface(bytes4 interfaceId) external view override returns (bool) {
        return
            interfaceId == type(IERC1155Receiver).interfaceId;
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override returns (bytes4) {
        if(value == 0) return 0xf23a6e61; // bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
        return  0x0;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override returns (bytes4) {
        return 0x0;
    }

    function setAdmin(address _admin, bool enabled) external onlyOwner {
        require(_admin != address(0), "Invalid minter");
        admins[_admin] = enabled;
        emit SetAdmin(_admin, enabled);
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "Only Admin");
        _;
    }

    function setCreator(
        address _to,
        uint256[] memory _ids
    ) external onlyOwner {
        poap.setCreator(_to, _ids);
    }

    function setCustomURI(
        uint256 _tokenId,
        string memory _newURI
    ) external {
        Activity storage act = activities[_tokenId];
        require(act.creator == msg.sender, "no permission");
        poap.setCustomURI(_tokenId,_newURI );
    }

    function createAirdrop(
        uint32 _startTs,
        uint32 _endTs,
        uint192 _supply,
        string memory _uri) external onlyAdmin {
        while (poap.exists(startTokenId)) {
            startTokenId += 1;
        }

        activities[startTokenId] = Activity({
            startTs: _startTs,
            endTs: _endTs,
            supply: _supply,
            creator: msg.sender
            });

        poap.create(address(this), startTokenId, 0, _uri, "0x");
        emit ActivityCreated(startTokenId, msg.sender, _startTs, _endTs);
        startTokenId += 1;
    }

    // TODO: 签名控制权限
    function claim(uint256 _tokenId) external {
        require(!claimed[_tokenId][msg.sender], "aleady claimed");

        Activity storage act = activities[_tokenId];
        require(poap.tokenSupply(_tokenId) < act.supply, "over limit");
        require(block.timestamp <= act.endTs && block.timestamp > act.startTs, "not in time");
        
        poap.mint(msg.sender, _tokenId, 1, "0x");

        claimed[_tokenId][msg.sender] = true;
        emit Claimed(_tokenId, msg.sender);
    }

}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface IPOAP {
  function exists(uint256 _id) external view returns (bool);
  function setCreator(
    address _to,
    uint256[] memory _ids
  ) external ;

  function setCustomURI(uint256 _tokenId, string memory _newURI) external;

  function tokenSupply(uint256 _tokenId) external view returns (uint256);

  function create(
        address _initialOwner,
        uint256 _id,
        uint256 _initialSupply,
        string memory _uri,
        bytes memory _data
    ) external returns (uint256);

    function mint(
        address _to,
        uint256 _id,
        uint256 _quantity,
        bytes memory _data
    ) external;
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
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