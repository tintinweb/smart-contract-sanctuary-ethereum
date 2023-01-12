// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract EthicalReturn is ReentrancyGuard {
    error InvalidDistribution();
    error BountyPayoutFailed();
    error TipPayoutFailed();
    error OnlyBeneficiary();
    error OnlyHacker();
    error NotMinimumAmount();
    error InvalidHacker();
    error AlreadyDeposited();
    error MustDepositMinimumAmount();
    error MustHaveHackerBeforeDeposit();

    uint256 public constant HUNDRED_PERCENT = 10_000;

    address public hacker;
    address public immutable beneficiary;
    address public immutable tipAddress;
    uint256 public immutable bountyPercentage;
    uint256 public immutable tipPercentage;
    uint256 public immutable minimumAmount;

    constructor(
        address _hacker,
        address _beneficiary,
        address _tipAddress,
        uint256 _bountyPercentage,
        uint256 _tipPercentage,
        uint256 _minimumAmount
    ) {
        if (_bountyPercentage + _tipPercentage > HUNDRED_PERCENT) {
            revert InvalidDistribution();
        }

        hacker = _hacker;
        beneficiary = _beneficiary;
        tipAddress = _tipAddress;
        bountyPercentage = _bountyPercentage;
        tipPercentage = _tipPercentage;
        minimumAmount = _minimumAmount;
    }
    
    receive() external payable {
        if (hacker == address(0)) {
            revert MustHaveHackerBeforeDeposit();
        } 
    }

    function deposit(address _hacker) external payable {
        if (_hacker == address(0)) {
            revert InvalidHacker();
        }
        if (hacker != address(0)) {
            if (_hacker == hacker) {
                return;
            }
            revert AlreadyDeposited();
        }
        if (msg.value < minimumAmount) {
            revert MustDepositMinimumAmount();
        }
        hacker = _hacker;
    }

    function sendPayouts() external nonReentrant {
        if (address(this).balance < minimumAmount) {
            revert NotMinimumAmount();
        }

        if (msg.sender != beneficiary) {
            revert OnlyBeneficiary();
        }

        uint256 payout = address(this).balance * bountyPercentage / HUNDRED_PERCENT;
        uint256 tip = address(this).balance * tipPercentage / HUNDRED_PERCENT;

        (bool sent,) = hacker.call{value: payout}("");
        if (!sent) {
            revert BountyPayoutFailed();
        }

        (sent,) = tipAddress.call{value: tip}("");
        if (!sent) {
            revert TipPayoutFailed();
        }
        
        selfdestruct(payable(beneficiary));
    }

    function cancelAgreement() external nonReentrant {
        if (msg.sender != hacker) {
            revert OnlyHacker();
        }
        selfdestruct(payable(hacker));
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