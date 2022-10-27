// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title HeyMint Launchpad Bulk ETH Transfer Contract
 * @author Mai Akiyoshi & Ben Yu (https://twitter.com/mai_on_chain & https://twitter.com/intenex) from HeyMint (https://twitter.com/heymintxyz)
 * @notice This contract handles the bulk transfer of ETH to a list of addresses.
 */
contract BulkEthTransfer is ReentrancyGuard {

    mapping (address => uint256) public balances;

    constructor() {
    }

    /**
     * @notice Deposit ETH to the contract to be spent later on transfers
     */
    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    /**
     * @notice Bulk transfer ETH to a list of addresses with a list of amounts
     */
    function bulkEthTransfer(address payable[] calldata _to, uint256[] calldata _value) external payable nonReentrant {
        if (msg.value > 0) {
            balances[msg.sender] += msg.value;
        }
        require(_to.length == _value.length, "Arrays must be of equal length");
        uint256 totalValue = 0;
        for (uint256 i = 0; i < _value.length; i++) {
            totalValue += _value[i];
        }
        require(balances[msg.sender] >= totalValue, "Insufficient balance");
        balances[msg.sender] -= totalValue;
        for (uint i = 0; i < _to.length; i++) {
            _to[i].transfer(_value[i]);
        }
    }

    /**
     * @notice Bulk transfer the same amount of ETH to a list of addresses
     */
    function bulkEthTransferSingleAmount(address payable[] calldata _to, uint256 _value) external payable nonReentrant {
        if (msg.value > 0) {
            balances[msg.sender] += msg.value;
        }
        uint256 totalValue = _value * _to.length;
        require(balances[msg.sender] >= totalValue, "Insufficient balance");
        balances[msg.sender] -= totalValue;
        for (uint i = 0; i < _to.length; i++) {
            _to[i].transfer(_value);
        }
    }

    /**
     * @notice Withdraw any outstanding ETH balance from the contract
     */
    function withdraw() external nonReentrant {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "No balance to withdraw");
        balances[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
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