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

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

abstract contract NFT {
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        returns (address owner);
    function totalSupply()
        public
        view
        virtual
        returns (uint256);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual;
}


contract ERC721AVault is Ownable, IERC721Receiver {

    struct Token {
        bool claimed;
    }

    bool public claimIsActive = true;
    mapping(uint256 => Token) public tokens;
    uint256 public totalClaimed;
    NFT genesis;
    NFT companion;

    constructor(address _genesisAddress, address _companionAddress) {
        genesis = NFT(_genesisAddress);
        companion = NFT(_companionAddress);
    }

    function setGenesisContract(address _address) public onlyOwner {
        genesis = NFT(_address);
    }

    function setCompanionContract(address _address) public onlyOwner {
        companion = NFT(_address);
    }

    function getClaimable(address _address) public view returns (uint256[] memory) {
        uint256 _currentSupply = genesis.totalSupply();
        uint256 claimable;
        for (uint256 i = 0; i < _currentSupply; i++) {
            if (genesis.ownerOf(i) == _address && !tokens[i].claimed) {
                claimable++;
            }
        }
        uint256 index;
        uint256[] memory tokenIds = new uint256[](claimable);
        for (uint256 i = 0; i < _currentSupply; i++) {
            if (genesis.ownerOf(i) == _address && !tokens[i].claimed) {
                tokenIds[index++] = i;
            }
        }
        return tokenIds;
    }

    function setClaimState(bool _claimIsActive) public onlyOwner {
        claimIsActive = _claimIsActive;
    }

    function claim(uint256[] memory _tokenIds) public {
        require(claimIsActive, "Claim inactive");
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(genesis.ownerOf(_tokenIds[i]) == msg.sender, "Not owner");
            require(!tokens[_tokenIds[i]].claimed, "Already claimed");
            tokens[_tokenIds[i]].claimed = true;
            totalClaimed++;
            companion.safeTransferFrom(
                address(this),
                msg.sender,
                _tokenIds[i]
            );
        }
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}