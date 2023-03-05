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
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
//Pay and keep tract of donators
// a balance that keeps track of our balance
//only owner should be able to withdraw
error Donate_enterAFee(string);
error Donate_notAccessToWithdraw(string);
error Donate_withdrawalNotSuccessFul(string);
error Donate_lowContractBalance(string);
error Donate_InsufficientBalance(string);

contract Donate is ReentrancyGuard {
    address[] private donatorList;

    address private owner;
    uint private MINIMUM_VALUE = 1e8;
    //mappings
    mapping(address => uint) public balanceOf;
    //Events
    event feeDonated(uint indexed amountDonated, address indexed donator);

    //modifiers
    modifier isOwner() {
        if (owner != msg.sender)
            revert Donate_notAccessToWithdraw("You are not the owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function payFee() public payable {
        if (msg.value <= MINIMUM_VALUE)
            revert Donate_enterAFee("Enter a value greater than zero");
        balanceOf[msg.sender] = address(msg.sender).balance;
        if (balanceOf[msg.sender] <= MINIMUM_VALUE)
            revert Donate_InsufficientBalance("Low Balance");
        donatorList.push(msg.sender);
        emit feeDonated(msg.value, msg.sender);
    }

    function withdrawFunds() public isOwner nonReentrant {
        uint balance = address(this).balance;
        if (balance <= 0) revert Donate_lowContractBalance("Low Balance");
        (bool success, ) = payable(msg.sender).call{value: balance}("");
        if (!success)
            revert Donate_withdrawalNotSuccessFul(
                "your withdrawal was not successful. try again"
            );
    }

    function getADonator(uint index) public view returns (address) {
        return donatorList[index];
    }

    function getDonatorList() public view returns (address[] memory) {
        return donatorList;
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    receive() external payable {
        payFee();
    }

    fallback() external payable {
        payFee();
    }
}