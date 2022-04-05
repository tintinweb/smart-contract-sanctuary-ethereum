// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import '@openzeppelin/contracts/access/Ownable.sol';

/**
* @dev simple erc20 contract that allows anyone to mint any amount, used for testing
*/
contract TestOwnable is Ownable {

    uint public number = 0;

    string public testString;

    ///@notice This is a struct to test if we can get the ownerMultisig to call and update this
    struct EmmisionRate {
        uint customMultiplier;
        uint[] rates;
        uint[] ranges;
        uint timeSet;
    }

    ///@notice this is a list that holds the information on the rewards rates
    EmmisionRate[] emissionRates;

    constructor()  {

    }


    //owner functions
    function incrementNumber() public onlyOwner {

        number += 1;

    }

     /**
    * @dev Changes the token generation rate of the nfts
    * Requires the sender to be the owner of this address
    */
    function setEmissionRates(uint[] calldata _ranges, uint[] calldata _rates, uint _customMultiplier) onlyOwner external {

        require(_ranges.length == _rates.length, "rates and ranges should be the same length");

        emissionRates.push(EmmisionRate(_customMultiplier, _rates, _ranges, block.timestamp));

    }

    function setEmissionRateAsStruct(EmmisionRate memory _emissionRate) onlyOwner external {

        emissionRates.push(_emissionRate);

    }

    function getEmissionRate(uint index) public view returns(EmmisionRate memory) {

        require(index < emissionRates.length, "Index out of range");

        return emissionRates[index];

    }

    function setTestString(string memory _string) onlyOwner external {

        testString = _string;

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