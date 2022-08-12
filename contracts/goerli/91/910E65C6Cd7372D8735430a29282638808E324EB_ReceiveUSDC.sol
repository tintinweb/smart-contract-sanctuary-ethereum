// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface DaiToken {
    function transfer(address dst, uint wad) external returns (bool);
    function transferFrom(address src, address dst, uint wad) external returns (bool);
    function balanceOf(address guy) external view returns (uint);

    function approve(address spender, uint256 amount) external returns (bool);
}

contract ReceiveUSDC is ReentrancyGuard {
    DaiToken private  immutable daiToken;
    address immutable owner;
    uint256 private wAmount;
    uint256 public immutable cost;

    /*
    USDC 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
    USDC Proxy 0xa2327a938Febf5FEC13baCFb16Ae10EcBc4cbDCF

    USDC GOERLI TESTNET 0x07865c6E87B9F70255377e024ace6630C1Eaa37F
    GOERLI Proxy 0xe27658a36cA8A59fE5Cc76a14Bde34a51e587ab4
    */

    constructor() ReentrancyGuard() {
        owner = msg.sender;
        daiToken = DaiToken(0x07865c6E87B9F70255377e024ace6630C1Eaa37F);
        wAmount = 50;
        cost = 10;
    }
     
    function makePayment() public payable nonReentrant{
        require(daiToken.balanceOf(msg.sender) >= cost, "You don't have enough USDC to make this payment");
        daiToken.transferFrom(msg.sender, address(this), cost);

    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    function setWithdrawalAmount(uint256 amount) onlyOwner public nonReentrant {
        wAmount = amount;
    }

    function withdraw() payable onlyOwner public nonReentrant {
        daiToken.approve(owner, wAmount);
        daiToken.transfer(owner, wAmount);
    }


    // TODO: Set Gas Limit

    // TODO: Payment split (pending payment flow discussion)
}

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