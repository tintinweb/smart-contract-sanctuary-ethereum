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
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract IERC721 {
    function mint(address to) external virtual;

    function ownerOf(uint tokenId) external view virtual returns (address);
}

contract ERC721MinterSimple is Ownable {
    IERC721 public erc721;
    IERC721 public krewPass;

    //used to verify whitelist user
    uint public mintQuantity;
    bool public publicMintStart;
    uint public price;
    address public devPayoutAddress;
    mapping(address => uint) public claimed;
    mapping(uint => bool) krewPassClaimed;
    mapping(address => bool) public whitelisted;

    constructor(IERC721 erc721_, IERC721 krewPass_, uint price_, uint mintQuantity_) {
        erc721 = erc721_;
        krewPass = krewPass_;
        mintQuantity = mintQuantity_;
        price = price_;
        devPayoutAddress = address(0xc891a8B00b0Ea012eD2B56767896CCf83C4A61DD);
        publicMintStart = false;
    }

    function setNFT(IERC721 erc721_) public onlyOwner {
        erc721 = erc721_;
    }

    function setQuantity(uint newQ_) public onlyOwner {
        mintQuantity = newQ_;
    }

    function setPrice(uint newPrice_) public onlyOwner {
        price = newPrice_;
    }

    function setPublicMintStart(bool start_) public onlyOwner {
        publicMintStart = start_;
    }

    function mint(uint quantity_) public payable {
        //require payment
        require(msg.value >= price * quantity_, "Insufficient funds provided.");

        //check mint quantity
        require(claimed[msg.sender] + quantity_ <= mintQuantity, "Already claimed.");

        //requires that user is in whitelsit
        require(whitelisted[msg.sender], "Address not whitelisted.");

        //increase quantity that user has claimed
        claimed[msg.sender] = claimed[msg.sender] + quantity_;

        //mint quantity times
        for (uint i = 0; i < quantity_; i++) {
            erc721.mint(msg.sender);
        }
    }

    function mintKrewPass(uint tokenId) public payable {
        require(msg.value >= price, "Insufficient funds provided.");

        //requires that user is in whitelsit
        require(krewPass.ownerOf(tokenId) == msg.sender, "Address not whitelisted.");

        require(!krewPassClaimed[tokenId], "Already claimed.");
        //increase quantity that user has claimed
        krewPassClaimed[tokenId] = true;

        erc721.mint(msg.sender);
    }

    function mintPublic(uint quantity_) public payable {
        require(publicMintStart, "Public mint has not started.");

        require(msg.value >= price * quantity_, "Insufficient funds provided.");
        //check mint quantity
        require(claimed[msg.sender] + quantity_ <= mintQuantity, "Already claimed.");

        //increase quantity that user has claimed
        claimed[msg.sender] = claimed[msg.sender] + quantity_;

        //mint quantity times
        for (uint i = 0; i < quantity_; i++) {
            erc721.mint(msg.sender);
        }
    }

    function addToWhitelist(address[] memory _whitelist) public onlyOwner {
        for (uint i = 0; i < _whitelist.length; i++) {
            whitelisted[_whitelist[i]] = true;
        }
    }

    function withdraw(address to) public onlyOwner {
        uint devAmount = (address(this).balance * 25) / 1000;
        bool success;
        (success, ) = devPayoutAddress.call{value: devAmount}("");
        require(success, "dev withdraw failed");
        (success, ) = to.call{value: address(this).balance}("");
        require(success, "withdraw failed");
    }
}