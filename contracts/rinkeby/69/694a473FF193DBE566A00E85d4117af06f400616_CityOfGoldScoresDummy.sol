// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.4;

import "openzeppelin-solidity/contracts/access/Ownable.sol";

interface IEstate  {
    function landIds(uint, uint) external view returns(uint);
}

contract CityOfGoldScoresDummy is Ownable {

    address public ESTATE;

    struct Tier {
        uint min;
        uint max;
        uint multiplier;
    }

    mapping (uint => Tier) public tierList;

    uint public totalTiers;

    constructor(address estate) {
        ESTATE = estate;
        totalTiers = 4;
        tierList[0] = Tier({
            min: 70,
            max: 90,
            multiplier: 1
        });
        tierList[1] = Tier({
            min: 91,
            max: 110,
            multiplier: 3
        });
        tierList[2] = Tier({
            min: 111,
            max: 130,
            multiplier: 5
        });
        tierList[3] = Tier({
            min: 131,
            max: 150,
            multiplier: 7
        });
    }

    function setEstateAddress(address estate) public onlyOwner {
        ESTATE = estate;
    }

    // be carefull , tiers shouldn't overlap
    function setTier(uint tierIndex, uint _min, uint _max, uint _multiplier) public onlyOwner {
        tierList[tierIndex] = Tier({
            min: _min,
            max: _max,
            multiplier: _multiplier
        });
    }

    function setTotalTiers(uint total) public onlyOwner {
        totalTiers = total;
    }

    function getEstateScore(uint tokenId) public view returns(uint score) {
        return getLandScore(IEstate(ESTATE).landIds(tokenId, 0)) + getLandScore(IEstate(ESTATE).landIds(tokenId, 1)) + getLandScore(IEstate(ESTATE).landIds(tokenId, 2));
    }

    function getTierMultiplier(uint tokenScore) public view returns (uint multiplier) {
        for (uint index = 0; index < totalTiers; index++) {
            Tier storage tier = tierList[index];
            if (tokenScore >= tier.min && tokenScore <= tier.max) {
                return tier.multiplier;
            }
        }
    }

    function getEstateMultiplier(uint tokenId) public view returns(uint score) {

        uint tokenScoreOne = getLandScore(IEstate(ESTATE).landIds(tokenId, 0));
        uint tokenScoreTwo = getLandScore(IEstate(ESTATE).landIds(tokenId, 1));
        uint tokenScoreThree = getLandScore(IEstate(ESTATE).landIds(tokenId, 2));

        uint multiplierOne = getTierMultiplier(tokenScoreOne);
        uint multiplierTwo = getTierMultiplier(tokenScoreTwo);
        uint multiplierThree = getTierMultiplier(tokenScoreThree);

        return (multiplierOne + multiplierTwo + multiplierThree) / 3;
    }

    function getLandScore(uint tokenId) public pure returns (uint256 score) {
        require(tokenId <= 10000 && tokenId > 0, "Invalid tokenId");
        return 100;
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