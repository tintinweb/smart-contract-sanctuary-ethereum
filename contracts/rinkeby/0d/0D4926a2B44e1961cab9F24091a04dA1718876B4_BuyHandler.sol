// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IAviumNFT.sol";

contract BuyHandler is ReentrancyGuard {
    address public immutable PROXY;
    uint256 public price;

    constructor(address proxy, uint256 _price) {
        PROXY = proxy;
        price = _price;
    }

    event BuyEvent(
        address to,
        uint256 quantity,
        uint256 currentIndex,
        uint256 price
    );

    function setPrice(uint256 _price) public {
        require(
            msg.sender == IAviumNFT(PROXY).owner(),
            "BuyHandler: only AviumNFT's owner"
        );
        price = _price;
    }

    function buy(
        address to,
        uint256 quantity,
        string[] memory tokenURIs,
        bytes memory _data
    ) public payable nonReentrant {
        require(
            msg.value == quantity * price,
            "BuyHandler: invalid amount value"
        );
        uint256 currentIndex = IAviumNFT(PROXY).getCurrentIndex();
        require(
            currentIndex < IAviumNFT(PROXY).getTotalMint(), "BuyHandler: total mint has been exeeded"
        );

        payable(IAviumNFT(PROXY).getRecipientAddress()).transfer(msg.value);
        IAviumNFT(PROXY).mint(to, quantity, tokenURIs, _data);
        emit BuyEvent(to, quantity, currentIndex, price);
    }
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAviumNFT {
    
    function setRecipientAddress(address _recipientAddress) external;

    function getRecipientAddress() external returns(address);

    function getCurrentIndex() external view returns (uint256);

    function getTotalMint() external view returns (uint256);

    function mint(
        address to,
        uint256 quantity,
        string[] calldata tokenURIs,
        bytes calldata _data
    ) external;

    function owner() external returns (address);

    
}