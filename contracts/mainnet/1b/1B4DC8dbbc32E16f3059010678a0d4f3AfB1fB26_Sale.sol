// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

import "./types/OwnerOrAdmin.sol";
import "./interfaces/IWeedWarsERC721.sol";

contract Sale is OwnerOrAdmin {

    IWeedWarsERC721 public warriorsERC721;
    IWeedWarsERC721 public synthsERC721;

    uint8 public maxMintCountPerTx = 5;

    // private sale

    mapping(address => bool) public winners;
    uint8 public maxPrivateSaleMintCount = 3;
    mapping(address => uint8) public privateSaleMintCount;
    uint public privateSalePrice = 0.1 ether;
    bool public isPrivateSaleOpen;

    //public sale

    uint public publicSalePrice = 0.2 ether;
    bool public isPublicSaleOpen;

    // constructor

    constructor(address warriorsERC721_, address synthsERC721_, bool _isPrivateSaleOpen, bool _isPublicSaleOpen) {
        warriorsERC721 = IWeedWarsERC721(warriorsERC721_);
        synthsERC721 = IWeedWarsERC721(synthsERC721_);
        isPrivateSaleOpen = _isPrivateSaleOpen;
        isPublicSaleOpen = _isPublicSaleOpen;
    }

    // modifiers

    modifier privateMint(uint256 _claimQty) {
        (bool canMintPrivate, uint8 count) = getPrivateMintInfo();
        require(canMintPrivate, "Sale: can't mint private");
        require(_claimQty <= count, "Sale: can't mint that match");
        require(msg.value >= privateSalePrice * _claimQty, "Sale: not enough funds sent" );
        _;
        privateSaleMintCount[msg.sender] = uint8(privateSaleMintCount[msg.sender] + _claimQty);
    }

    modifier publicMint(uint256 _claimQty) {
        require(isPublicSaleOpen, "Sale: public sale is not open");
        require(_claimQty <= maxMintCountPerTx, "Sale: can't mint that match");
        require(msg.value >= publicSalePrice * _claimQty, "Sale: not enough funds sent");
        _;
    }

    // only owner

    function addWinners(address[] memory _users, bool _enabled) external onlyOwnerOrAdmin {
        for (uint256 i = 0; i < _users.length; i++) {
            winners[_users[i]] = _enabled;
        }
    }

    function setSaleOpen(bool _isPrivateSaleOpen, bool _isPublicSaleOpen) external onlyOwnerOrAdmin {
        isPrivateSaleOpen = _isPrivateSaleOpen;
        isPublicSaleOpen = _isPublicSaleOpen;
    }

    function setSalePrice(uint256 _privateSalePrice, uint256 _publicSalePrice) external onlyOwnerOrAdmin {
        privateSalePrice = _privateSalePrice;
        publicSalePrice = _publicSalePrice;
    }

    function setMintRestrictions(uint8 _maxMintCountPerTx, uint8 _maxPrivateSaleMintCount) external onlyOwnerOrAdmin {
        require(_maxPrivateSaleMintCount <= _maxMintCountPerTx);
        maxMintCountPerTx = _maxMintCountPerTx;
        maxPrivateSaleMintCount = _maxPrivateSaleMintCount;
    }

    function withdraw(address _receiver) external onlyOwner {
        payable(_receiver).transfer(address(this).balance);
    }

    // user

    function getPrivateMintInfo() public view returns (bool canMintPrivate_, uint8 count_) {
        if (winners[msg.sender] == true) {
            uint8 minted = privateSaleMintCount[msg.sender];
            if (minted >= maxPrivateSaleMintCount) {
                count_ = 0;
            } else {
                count_ =  maxPrivateSaleMintCount - privateSaleMintCount[msg.sender];
            }
        }
        if (isPrivateSaleOpen) {
            canMintPrivate_ = true;
        }
        if (count_ == 0) {
            canMintPrivate_ = false;
        }
    }

    function mintWarriorPrivate(uint256 _claimQty) external payable privateMint(_claimQty) {
        warriorsERC721.mint(_claimQty, msg.sender);
    }

    function mintSynthPrivate(uint256 _claimQty) external payable privateMint(_claimQty) {
        synthsERC721.mint(_claimQty, msg.sender);
    }

    function mintWarriorPublic(uint256 _claimQty) external payable publicMint(_claimQty) {
        warriorsERC721.mint(_claimQty, msg.sender);
    }

    function mintSynthPublic(uint256 _claimQty) external payable publicMint(_claimQty) {
        synthsERC721.mint(_claimQty, msg.sender);
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

interface IWeedWarsERC721 {
    function mint(uint256 _claimQty, address _reciever) external;
    function setLock(uint256 _tokenId, address _owner, bool _isLocked) external;
    function getMergeCount(uint256 _tokenId) external view returns (uint);
}

// SPDX-License-Identifier: AGPL-3.0

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

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

import "./Context.sol";

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: AGPL-3.0

import "../types/Ownable.sol";

pragma solidity ^0.8.0;

contract OwnerOrAdmin is Ownable {

    mapping(address => bool) public admins;

    function _isOwnerOrAdmin() private view {
        require(
            owner() == msg.sender || admins[msg.sender],
            "OwnerOrAdmin: unauthorized"
        );
    }

    modifier onlyOwnerOrAdmin() {
        _isOwnerOrAdmin();
        _;
    }

    function setAdmin(address _address, bool _hasAccess) external onlyOwner {
        admins[_address] = _hasAccess;
    }

}