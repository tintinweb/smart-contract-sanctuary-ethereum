// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IEvent.sol";

contract Event is IEvent, Ownable {
    address shopFactoryAddress;
    mapping(address => bool) validContractAddress;

    /**
     * @dev emit the update factory contract address
     */
    event UpdateShopFactoryAddress(
        address indexed oldAddress,
        address indexed newAddress
    );

    /**
     * @dev emit the purchase design transaction
     */
    event PurchaseDesign(
        address indexed shopAddress,
        uint256 indexed tokenId,
        address indexed mintAddress,
        uint256 amount
    );

    event SafeTranferFrom(
        address _shopAddress,
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount
    );

    event UpdateShopInfo(
        address _shopAddress,
        string name,
        string symbol,
        string metadataURI,
        string _name,
        string _symbol,
        string _metadataURI
    );

    constructor() {}

    modifier onlyValidShop_shopAddress(address _shopAddress) {
        require(validContractAddress[_shopAddress] == true, "NOT VALID SHOP");
        _;
    }

    /**
     * @dev emit purchase design event call from valid shop
     */
    function emitPurchaseDesign(
        address _shopAddress,
        uint256 _tokenId,
        address _mintAddress,
        uint256 _amount
    ) external onlyValidShop_shopAddress(_shopAddress) {
        emit PurchaseDesign(_shopAddress, _tokenId, _mintAddress, _amount);
    }

    /**
     * @dev emit trasfer token with amount
     */
    function emitSafeTranferFrom(
        address _shopAddress,
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount
    ) external onlyValidShop_shopAddress(_shopAddress) {
        emit SafeTranferFrom(_shopAddress, _from, _to, _id, _amount);
    }

    /**
     * @dev emit update shop info 
     */
    function emitUpdateShopInfo(
        address _shopAddress,
        string memory name,
        string memory symbol,
        string memory metadataURI,
        string memory _name,
        string memory _symbol,
        string memory _metadataURI
    ) external onlyValidShop_shopAddress(_shopAddress) {
        emit UpdateShopInfo(
            _shopAddress,
            name,
            symbol,
            metadataURI,
            _name,
            _symbol,
            _metadataURI
        );
    }

    /**
     * @dev add valid shop proxy address
     */
    function addValidAddress(address _shopAddr) external {
        require(msg.sender == shopFactoryAddress, "NOT FACTORY");
        validContractAddress[_shopAddr] = true;
    }

    /**
     * @dev update shop factory address
     */
    function updateShopFactoryAddress(address _newShopFactoryAddress)
        external
        onlyOwner
    {
        emit UpdateShopFactoryAddress(
            shopFactoryAddress,
            _newShopFactoryAddress
        );

        shopFactoryAddress = _newShopFactoryAddress;
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
pragma solidity ^0.8.9;

interface IEvent {
    function emitPurchaseDesign(
        address _shopAddress,
        uint256 _tokenId,
        address _mintAddress,
        uint256 _amount
    ) external;

    function emitSafeTranferFrom(
        address _shopAddress,
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount
    ) external;

    function emitUpdateShopInfo(
        address _shopAddress,
        string memory name,
        string memory symbol,
        string memory metadataURI,
        string memory _name,
        string memory _symbol,
        string memory _metadataURI
    ) external;

    function addValidAddress(address _shopAddr) external;

    function updateShopFactoryAddress(address _newShopFactoryAddress) external;
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