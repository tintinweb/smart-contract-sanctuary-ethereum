// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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
pragma solidity ^0.8.16;

// Imports
// import "hardhat/console.sol"; // Used for console logging during development // console.log("HERE1");
import "./PriceConverter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Error codes
error FundMe__RefundFailed();
error FundMe__RefundNoFunds();
error FundMe__IndexNotFound();
error FundMe__WithdrawFailed();
error FundMe__WithdrawNoFunds();
error FundMe__NotEnoughEthSent();
error FundMe__WithdrawSelfDestructFailed();

/** @title FundMe
 *  @author EridianAlpha
 *  @notice A template contract for funding and withdrawals.
 *  @dev Chainlink is used to implement price feeds.
 */
contract FundMe is Ownable, ReentrancyGuard {
    // Type declarations
    using PriceConverter for uint256; // Extends uint256 (used from msg.value) to enable direct price conversion

    // State variables
    address[] internal s_funders;
    address internal immutable i_creator; // Set in constructor
    AggregatorV3Interface internal s_priceFeed; // Set in constructor
    mapping(address => uint256) internal s_addressToAmountFunded;
    uint256 public constant MINIMUM_USD = 100 * 10 ** 18; // Constant, never changes ($100)
    uint256 internal s_balance; // Stores the funded balance to avoid selfdestruct attacks using address(this).balance

    /**
     * Functions order:
     * - constructor
     * - receive
     * - fallback
     * - external
     * - public
     * - internal
     * - private
     * - view / pure
     */

    constructor(address priceFeedAddress) {
        i_creator = msg.sender;

        // Set the address of the priceFeed contract
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    /**
     * Explainer from: https://solidity-by-example.org/fallback
     * Ether is sent to contract
     *      is msg.data empty?
     *           /    \
     *         yes    no
     *         /       \
     *    receive()?  fallback()
     *      /     \
     *    yes     no
     *    /        \
     * receive()  fallback()
     */
    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    /** @notice Function for sending funds to the contract.
     *  @dev This implements price feeds as a library.
     */
    function fund() public payable virtual {
        // msg.value is handled as the first input parameter of getConversionRate()
        // as it is being used as a Library
        // with s_priceFeed used as the second input parameter
        if (msg.value.getConversionRate(s_priceFeed) <= MINIMUM_USD)
            revert FundMe__NotEnoughEthSent();

        /**
         *  The s_balance variable isn't needed for this function
         *  as it withdraws 100% of the funds in the contract anyway.
         *  It actually creates a problem if someone does perform a selfdestruct
         *  attack, since those funds are then not counted, and get stuck.
         *  So use another function withdrawSelfdestructFunds() to completely
         *  drain the contract. This is better as it allows the owner to fix the
         *  problem, without being accused of draining the main funds/prize.
         *  It is an example to show how to avoid selfdestruct attacks:
         *  https://solidity-by-example.org/hacks/self-destruct/
         */
        s_balance += msg.value;

        s_addressToAmountFunded[msg.sender] += msg.value;

        // If funder does not already exist, add to s_funders array
        address[] memory funders = s_funders;
        for (uint256 i = 0; i < funders.length; i++) {
            if (funders[i] == msg.sender) {
                return;
            }
        }
        s_funders.push(msg.sender);
    }

    /** @notice Function for allowing owner to withdraw all funds from the contract.
     *  @dev Does not require a reentrancy check as only the owner can call it and it withdraws all funds anyway.
     */
    function withdraw() external payable onlyOwner {
        // Check to make sure that the contract is not empty before attempting withdrawal
        if (s_balance == 0) revert FundMe__WithdrawNoFunds();

        address[] memory funders = s_funders;

        // Loop through all funders in s_addressToAmountFunded mapping and reset the funded value to 0
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }

        // Reset the s_funders array to an empty array
        s_funders = new address[](0);

        // ***********
        // SEND FUNDS
        // ***********
        (bool callSuccess, ) = owner().call{ value: s_balance }("");
        if (!callSuccess) revert FundMe__WithdrawFailed();
    }

    /** @notice Function for allowing owner to withdraw any selfdestruct funds from the contract.
     *  @dev // TODO
     */
    function withdrawSelfdestructFunds() external payable onlyOwner {
        if (address(this).balance > s_balance) {
            uint256 selfdestructBalance = address(this).balance - s_balance;

            // ***********
            // SEND FUNDS
            // ***********
            (bool callSuccess, ) = owner().call{ value: selfdestructBalance }(
                ""
            );
            if (!callSuccess) revert FundMe__WithdrawSelfDestructFailed();
        } else {
            revert FundMe__WithdrawSelfDestructFailed();
        }
    }

    /** @notice Function for refunding deposits to funders on request.
     *  @dev Does not require nonReentrant modifier as s_addressToAmountFunded
     * is reset before sending funds, but retained here for completeness of this template.
     */
    function refund() external payable nonReentrant {
        uint256 refundAmount = s_addressToAmountFunded[msg.sender];
        if (refundAmount == 0) revert FundMe__RefundNoFunds();

        address[] memory funders = s_funders;

        // Resetting the funded amount before the refund is
        // sent stops reentrancy attacks on this function
        s_addressToAmountFunded[msg.sender] = 0;

        // Reduce s_balance by the refund amount
        s_balance -= refundAmount;

        // Remove specific funder from the s_funders array
        for (uint256 i = 0; i < funders.length; i++) {
            if (funders[i] == msg.sender) {
                // Move the last element into the place to delete
                s_funders[i] = s_funders[s_funders.length - 1];
                // Remove the last element
                s_funders.pop();
            }
        }

        // ***********
        // SEND FUNDS
        // ***********
        (bool callSuccess, ) = msg.sender.call{ value: refundAmount }("");
        if (!callSuccess) revert FundMe__RefundFailed();
    }

    /** @notice Getter function to get the i_creator address.
     *  @dev Public function to allow anyone to view the contract creator.
     *  @return address of the creator.
     */
    function getCreator() public view returns (address) {
        return i_creator;
    }

    /** @notice Getter function for a specific funder address based on their index in the s_funders array.
     *  @dev Allow public users to get list of all funders by iterating through the array.
     *  @param funderAddress The address of the funder to be found in s_funders array.
     *  @return uint256 index position of funderAddress.
     */
    function getFunderIndex(
        address funderAddress
    ) public view returns (uint256) {
        address[] memory funders = s_funders;
        uint256 index;

        for (uint256 i = 0; i < funders.length; i++) {
            if (funders[i] == funderAddress) {
                index = i;
                return index;
            }
        }
        revert FundMe__IndexNotFound();
    }

    /** @notice Getter function for a specific funder based on their index in the s_funders array.
     *  @dev // TODO
     */
    function getFunderAddress(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    /** @notice Getter function to convert an address to the total amount funded.
     *  @dev Public function to allow anyone to easily check the balance funded by any address.
     */
    function getAddressToAmountFunded(
        address funder
    ) public view returns (uint256) {
        return s_addressToAmountFunded[funder];
    }

    /** @notice Getter function to get the current price feed value.
     *  @dev Public function to allow anyone to check the current price feed value.
     */
    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }

    /** @notice Getter function to get the current balance of the contract.
     *  @dev Public function to allow anyone to check the current balance of the contract.
     */
    function getBalance() public view returns (uint256) {
        return s_balance;
    }

    /** @notice Getter function to get the s_funders array.
     *  @dev Public function to allow anyone to view the s_funders array.
     */
    function getFunders() public view returns (address[] memory) {
        return s_funders;
    }

    /** @notice Function for getting priceFeed version.
     *  @dev Public function to allow anyone to view the AggregatorV3Interface version.
     */
    function getPriceFeedVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// This is a library and not an abstract as all of the functions are fully implemented
library PriceConverter {
    // Must be internal as it is a library function
    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        // (
        //     uint80 roundID,
        //     int256 price,
        //     uint startedAt,
        //     uint timeStamp,
        //     uint80 answeredInRound
        // )
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price * 10000000000); // ETH/USD rate in 18 digit
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / (10 ** 18);
        return ethAmountInUsd; // ETH/USD conversion rate, after adjusting the extra 0s.
    }
}