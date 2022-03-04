//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Settings is Ownable {
    event RoyaltyInfoUpdated(address indexed receiver, uint256 royaltyPercentBips);
    event ProtocolFeeUpdated(address indexed receiver, uint256 protocolFeeBips);
    event MarketplaceAdminUpdated(address indexed marketplaceAdmin);

    // royalties on LP tokens
    uint256 public royaltyPercentBips; // ie 250 = 2.5%
    address public royaltyReceiver; 

    // protocol fee on flashmints
    uint256 public protocolFeeBips; 
    address public protocolFeeReceiver;

    // some NFT marketplaces want NFTs to have an `owner()` function
    address public marketplaceAdmin;

    string public baseURI;

    // royalties, protocol fee are 0 unless turned on
    constructor() {
        baseURI = "http://flashmint.ooo/api/tokenURI/";
    }

    function setRoyaltyPercentBips(uint256 _royaltyPercentBips) external onlyOwner {
        require(_royaltyPercentBips < 1000, "royalties: cmon"); // force prevent high royalties
        royaltyPercentBips = _royaltyPercentBips;
        
        emit RoyaltyInfoUpdated(royaltyReceiver, _royaltyPercentBips);
    }

    function setRoyaltyReceiver(address _royaltyReceiver) external onlyOwner {
        royaltyReceiver = _royaltyReceiver;
        emit RoyaltyInfoUpdated(_royaltyReceiver, royaltyPercentBips);
    }

    function setProtocolFee(uint256 _protocolFeeBips) external onlyOwner {
        require(_protocolFeeBips < 5000, "fee: cmon");
        protocolFeeBips = _protocolFeeBips;
        emit ProtocolFeeUpdated(protocolFeeReceiver, _protocolFeeBips);
    }

    function setProtocolFeeReceiver(address _protocolFeeReceiver) external onlyOwner {
        protocolFeeReceiver = _protocolFeeReceiver;
        emit ProtocolFeeUpdated(_protocolFeeReceiver, protocolFeeBips);
    }

    function setMarketplaceAdmin(address _marketplaceAdmin) external onlyOwner {
        marketplaceAdmin = _marketplaceAdmin;
        emit MarketplaceAdminUpdated(_marketplaceAdmin);
    }

    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
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