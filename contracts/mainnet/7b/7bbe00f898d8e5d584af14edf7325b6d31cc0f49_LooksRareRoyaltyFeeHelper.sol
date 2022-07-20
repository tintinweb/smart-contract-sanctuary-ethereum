/**
 *Submitted for verification at Etherscan.io on 2022-07-20
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IRoyaltyFeeRegistry {
    function royaltyFeeInfoCollection(address collection) external view returns (address, address, uint256);
}

contract LooksRareRoyaltyFeeHelper {

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    address private _owner;
    IRoyaltyFeeRegistry public royaltyFeeRegistry;

    constructor(IRoyaltyFeeRegistry _royaltyFeeRegistry) {
        _transferOwnership(msg.sender);
        royaltyFeeRegistry = _royaltyFeeRegistry;
    }

    function updateRoyaltyFeeRegistry(IRoyaltyFeeRegistry _royaltyFeeRegistry) external onlyOwner {
        royaltyFeeRegistry = _royaltyFeeRegistry;
    }

    function royaltyFeeInfos(address[] calldata collections) external view returns (
        address[] memory setters,
        address[] memory receivers,
        uint256[] memory fees
    ) {
        setters = new address[](collections.length);
        receivers = new address[](collections.length);
        fees = new uint256[](collections.length);
        for (uint256 i = 0; i < collections.length; i++) {
            (setters[i], receivers[i], fees[i]) = royaltyFeeRegistry.royaltyFeeInfoCollection(collections[i]);
        }
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}