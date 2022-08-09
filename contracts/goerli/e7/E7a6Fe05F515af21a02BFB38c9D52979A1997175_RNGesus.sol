// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "Ownable.sol";

contract RNGesus is Ownable{

    uint256 public nextRequestId;

    event RequestId(uint256);
    event RandomNumberGenerated(uint256, uint256);

    struct Random {
        uint256 gweiToUse;
        uint256 randomNumber;
    }

    mapping(uint256 => Random) public randomNumbers;

    constructor() {

        // set nextRequestId to 1
        nextRequestId = 1;
    }

    // function to get a requestId, wait a few minutes and check if your prayer is fulfilled
    function prayToRngesus(uint256 _gweiForFulfillPrayer) public payable returns (uint256) {

        uint256 _fulfillmentPrice = calculateFulfillmentPrice(_gweiForFulfillPrayer);
        require(msg.value == _fulfillmentPrice);

        // send _fulfillmentPrice to contract owner
        payable(owner()).transfer(msg.value);

        // get the current request id
        uint256 _requestId = nextRequestId;

        randomNumbers[_requestId].gweiToUse = _gweiForFulfillPrayer;

        // add 1 to nextRequestId
        nextRequestId += 1;

        emit RequestId(_requestId);

        return _requestId;

    }

    function fulfillPrayer(uint256 _requestId, uint256 _randomNumber) external onlyOwner {

        randomNumbers[_requestId].randomNumber = _randomNumber;

        emit RandomNumberGenerated(_requestId, _randomNumber);

    }

    function calculateFulfillmentPrice(uint256 _gweiForFulfillPrayer) public pure returns (uint256) {

        // fixed fee of 0.0001 ETH
        uint256 _fixedFee = 0.0001 * 10 ** 18;

        // fulfillment cost 44,262 gas
        uint256 _fulfillmentTransactionCosts = 44262 * _gweiForFulfillPrayer * 10 ** 9;

        uint256 _totalFulfillmentPrice = _fixedFee + _fulfillmentTransactionCosts;

        return _totalFulfillmentPrice;

    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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