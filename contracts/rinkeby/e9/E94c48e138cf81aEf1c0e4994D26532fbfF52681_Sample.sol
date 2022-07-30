// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.9.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Sample is ReentrancyGuard {
    
    event DepositReceived(bytes32 indexed escrowID, address indexed depositor, address beneficiary, address approver, uint amount );
    event Approved(bytes32 indexed escrowID, uint timestamp);
    event Terminated(bytes32 indexed escrowID, uint timestamp);
    event ContractEmptied(uint indexed timestamp, uint balance);

    uint nonce;

    address owner; //to make it ownable:

    struct escrow {
        uint amount;
        address depositor;
        address beneficiary;
        address approver;
        bool approved;
        bool active;
    }

    mapping (bytes32 => escrow) escrowRegistry;

    constructor() { //only to record deployer to make it ownable.
        owner = msg.sender;
    }
    
    function  deposit(address _beneficiary, address _approver) external nonReentrant payable {
        address _depositor = msg.sender;
        uint _amount = msg.value;
        bytes32 _escrowID = keccak256(abi.encodePacked(nonce,_depositor));
        escrowRegistry[_escrowID].amount = _amount;
        escrowRegistry[_escrowID].depositor = _depositor;
        escrowRegistry[_escrowID].beneficiary = _beneficiary;
        escrowRegistry[_escrowID].approver = _approver;
        escrowRegistry[_escrowID].active = true;
        nonce += 1;
        emit DepositReceived(_escrowID, _depositor, _beneficiary, _approver, _amount);
    }

    function approve(bytes32 _escrowID) external {
        require (msg.sender == escrowRegistry[_escrowID].approver, "Only approver can call");
        require (escrowRegistry[_escrowID].active, "Only active escrows can be approved");
        escrowRegistry[_escrowID].approved = true;
        emit Approved(_escrowID, block.timestamp);
    }
    
    function withdrawFunds(bytes32 _escrowID) external nonReentrant {
        address caller = msg.sender;
        require (caller == escrowRegistry[_escrowID].beneficiary, "Only beneficiary can withdraw");
        require (escrowRegistry[_escrowID].active, "Only active escrows can be withdrawn, this is already inactive");
        require (escrowRegistry[_escrowID].approved, "Only approved escrows can be withdrawn");
        (bool result,) = caller.call{value: escrowRegistry[_escrowID].amount}("");
        escrowRegistry[_escrowID].amount = 0;
        escrowRegistry[_escrowID].active = false;
        require (result, "transfer failed");
        emit Terminated(_escrowID, block.timestamp);
    }

    function cancelEscrow(bytes32 _escrowID) external {
        address caller = msg.sender;
        require (caller == escrowRegistry[_escrowID].depositor);
        require (escrowRegistry[_escrowID].active, "Only active escrows can be cancelled, this is already inactive");
        require (!escrowRegistry[_escrowID].approved, "Only not approved escrows can be cancelled");
        (bool result,) = caller.call{value: escrowRegistry[_escrowID].amount}("");
        escrowRegistry[_escrowID].amount = 0;
        escrowRegistry[_escrowID].active = false;
        require (result, "transfer failed");
        emit Terminated(_escrowID, block.timestamp);
    }

    function transferBalance() external {
        require (msg.sender == owner, "only owner function");
        address payable _owner = payable(msg.sender);
        _owner.transfer(address(this).balance);
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