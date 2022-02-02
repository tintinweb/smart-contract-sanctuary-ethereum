// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

interface ITakeUsAddressRegistry {
    function vaultManager() external view returns (address);
}

interface IVaultManager {
    function setLending(
        address,
        uint256,
        address,
        address,
        uint256
    ) external;
}

contract TakeUsMarketplace is Ownable {
    ITakeUsAddressRegistry public addressRegistry;
    IVaultManager public vaultManager;
    uint256 public lenderFee;
    uint256 public borrowerFee;

    struct Lending {
        uint256 duration;
        uint256 price;
    }
    //nftAddress => tokenId => lender
    mapping(address => mapping(uint256 => mapping(address => Lending)))
        public listing;

    event Listed(
        address nftAddress,
        uint256 tokenId,
        uint256 price,
        uint256 duration
    );
    event Updated(
        address nftAddress,
        uint256 tokenId,
        uint256 price,
        uint256 duration
    );
    event Canceled(address nftAddress, uint256 tokenId);
    event Lended(
        address nftAddress,
        uint256 tokenId,
        uint256 price,
        uint256 duration,
        address borrower
    );

    constructor(address _addressRegistry) {
        addressRegistry = ITakeUsAddressRegistry(_addressRegistry);
        vaultManager = IVaultManager(addressRegistry.vaultManager());
    }

    function updateAddressRegistry(address _addressRegistry)
        external
        onlyOwner
    {
        addressRegistry = ITakeUsAddressRegistry(_addressRegistry);
    }

    function lend(
        address _borrower,
        address _nftAddress,
        uint256 _tokenId,
        address _lender
    ) public {
        vaultManager.setLending(
            _borrower,
            listing[_nftAddress][_tokenId][_lender].duration,
            _lender,
            _nftAddress,
            _tokenId
        );

        emit Lended(
            _nftAddress,
            _tokenId,
            listing[_nftAddress][_tokenId][_lender].price,
            listing[_nftAddress][_tokenId][_lender].duration,
            _borrower
        );
    }

    function list(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _price,
        uint256 _duration
    ) public {
        listing[_nftAddress][_tokenId][msg.sender] = Lending({
            duration: _duration,
            price: _price
        });
        emit Listed(_nftAddress, _tokenId, _price, _duration);
    }

    function update(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _price,
        uint256 _duration
    ) public {
        listing[_nftAddress][_tokenId][msg.sender] = Lending({
            duration: _duration,
            price: _price
        });
        emit Listed(_nftAddress, _tokenId, _price, _duration);
    }

    function cancel(address _nftAddress, uint256 _tokenId) public {
        delete listing[_nftAddress][_tokenId][msg.sender];

        emit Canceled(_nftAddress, _tokenId);
    }

    function setFees(uint256 _newLenderFee, uint256 _newBorrowerFee) public {
        lenderFee = _newLenderFee;
        borrowerFee = _newBorrowerFee;
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