/**
 *Submitted for verification at Etherscan.io on 2022-06-14
*/

// File @openzeppelin/contracts/security/[email protected]

// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

/**
 * @title Drengr payment
 * @notice This contract receive payments on behalf of users. Users that have received payments can withdraw them.
 * Payments are verified by an API that acts like a payment processor, for payments on the blockchain.
 */
contract DrengrPayment is ReentrancyGuard {

    //Maps funds available for every address to withdraw
    mapping(address => uint256) public funds;

    //Emitted when a payment has been received
    event Payment(address indexed from, address indexed to, uint256 amount);
    //Emitted when a withdraw have been performed
    event Withdraw(address indexed from, uint256 amount);

    /**
     * @dev We can't receive funds via the fallback function because we could not track for whom the payment is sent.
     */
    fallback() external{
        revert();
    }

    /**
     * @dev Performs a payment for the 'from' address to the 'to' address. Enables other adress to pay on 'from' behalf.
     * @param from the address that will be considered as having paid
     * @param to the address that will receive the funds
     * @return bool true
     */
    function pay(address from, address to) public payable nonReentrant returns(bool){

        require(msg.value > 0, "An amount is required");

        funds[to] += msg.value;

        emit Payment(from, to, msg.value);

        return true;

    }

    /**
     * @dev Withdraw all the funds that msg.sender has acquired
     * @return bool true
     */
    function withdraw() public nonReentrant returns(bool) {

        uint256 amount = funds[msg.sender];

        funds[msg.sender] = 0;

        emit Withdraw(msg.sender, amount);

        payable(msg.sender).transfer(amount);

        return true;

    }

}