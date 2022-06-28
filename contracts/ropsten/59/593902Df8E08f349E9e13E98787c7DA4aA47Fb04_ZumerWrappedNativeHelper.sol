// SPDX-License-Identifier: MIT
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
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IZBond {
    function mint(uint256 amount) external returns (uint256);

    function transfer(address receiver, uint256 amount) external;

    function repayBorrow(uint256 amount) external;
}

interface IProvisioningPool {
    function transfer(address receiver, uint256 amount) external;

    function stake(uint256 amount, uint256 time) external returns (uint256);
}

interface IWrappedNative {
    function deposit() external payable;

    function approve(address spender, uint256 amount) external;

    function transfer(address receiver, uint256 amount) external;
}

contract ZumerWrappedNativeHelper is ReentrancyGuard {
    address public wrappedNative;

    constructor(address wrappedNative_) {
        wrappedNative = wrappedNative_;
    }

    function mint(address zBond) public payable nonReentrant {
        require(msg.value > 0, "sent native token cannot be 0");
        IWrappedNative(wrappedNative).deposit{value: msg.value}();
        IWrappedNative(wrappedNative).approve(zBond, msg.value);
        uint256 mintedZToken = IZBond(zBond).mint(msg.value);
        require(mintedZToken > 0, "minted zero Ztoken");
        IZBond(zBond).transfer(msg.sender, mintedZToken);
    }

    function repayBorrow(address zBond) public payable nonReentrant {
        require(msg.value > 0, "sent native token cannot be 0");
        IWrappedNative(wrappedNative).deposit{value: msg.value}();
        IWrappedNative(wrappedNative).approve(zBond, msg.value);
        IZBond(zBond).repayBorrow(msg.value);
    }

    function stake(address provisioningPool, uint256 time)
        public
        payable
        nonReentrant
    {
        require(msg.value > 0, "sent native token cannot be 0");
        IWrappedNative(wrappedNative).deposit{value: msg.value}();
        IWrappedNative(wrappedNative).approve(provisioningPool, msg.value);
        uint256 mintedPP = IProvisioningPool(provisioningPool).stake(
            msg.value,
            time
        );
        require(mintedPP > 0, "minted zero pp token");
        IProvisioningPool(provisioningPool).transfer(msg.sender, mintedPP);
    }
}