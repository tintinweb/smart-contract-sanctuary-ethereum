/**
 *Submitted for verification at Etherscan.io on 2022-02-09
*/

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/access/Ownable.sol

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/NexxxtRoyaltiesProvider.sol


pragma solidity ^0.8.0;
pragma abicoder v2;


contract NexxxtRoyaltiesProvider is Ownable {
    struct Part {
        address payable account;
        uint96 value;
    }

    /// @dev struct to store royalties in royaltiesByToken
    struct RoyaltiesSet {
        bool initialized;
        Part[] royalties;
    }

    address internal tokenAddress;
    address payable internal protocolFeeAddress;
    uint96 internal protocolFee;

    mapping(uint => RoyaltiesSet) internal _royalties;

    constructor(address token, address payable protocolFeeAddress_, uint96 protocolFee_) {
        require(token != address(0), "Zero address");
        require(protocolFeeAddress_ != address(0), "Zero address");
        require(protocolFee_ <= 5000, "Protocol fee are too high (>50%)");
        tokenAddress = token;
        protocolFeeAddress = protocolFeeAddress_;
        protocolFee = protocolFee_;
    }

    function getRoyalties(address token, uint tokenId) external view returns (Part[] memory) {
        if (token != tokenAddress) return new Part[](0);

        Part[] memory royaltiesByTokenId = _royalties[tokenId].royalties;

        Part[] memory returnRoyalties = new Part[](royaltiesByTokenId.length + 1);
        // add protocol fee
        returnRoyalties[0] = Part(protocolFeeAddress, protocolFee);

        if (royaltiesByTokenId.length != 0) {
            for (uint i = 0; i < royaltiesByTokenId.length; i++) {
                returnRoyalties[i + 1] = royaltiesByTokenId[i];
            }
        }

        return returnRoyalties;
    }

    function setRoyalties(uint tokenId, Part[] memory royalties) external {
        uint totalRoyalties = protocolFee;
        delete _royalties[tokenId];
        for (uint i = 0; i < royalties.length; i++) {
            totalRoyalties += royalties[i].value;
            _royalties[tokenId].royalties.push(royalties[i]);
        }
        require(totalRoyalties <= 5000, "Royalties are too high (>50%)");
        _royalties[tokenId].initialized = true;
    }

    function setProtocolFee(uint96 fee) external {
        require(fee <= 5000, "Protocol fee are too high (>50%)");
        protocolFee = fee;
    }

    function setProtocolFeeAddress(address payable newAddress) external {
        require(newAddress != address(0), "Zero address");
        protocolFeeAddress = newAddress;
    }

    function setTokenAddress(address newAddress) external {
        require(newAddress != address(0), "Zero address");
        tokenAddress = newAddress;
    }
}