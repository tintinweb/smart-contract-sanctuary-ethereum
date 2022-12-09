/**
 *Submitted for verification at Etherscan.io on 2022-12-09
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

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
     * by making the `nonReentrant` function external, and make it call a
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

/**
 * @title Represents an ownable resource.
 */
contract CustomOwnable {
    // The current owner of this resource.
    address internal _owner;

    /**
     * @notice This event is triggered when the current owner transfers ownership of the contract.
     * @param previousOwner The previous owner
     * @param newOwner The new owner
     */
    event OnOwnershipTransferred (address previousOwner, address newOwner);

    /**
     * @notice This modifier indicates that the function can only be called by the owner.
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Only owner");
        _;
    }

    /**
     * @notice Transfers ownership to the address specified.
     * @param addr Specifies the address of the new owner.
     * @dev Throws if called by any account other than the owner.
     */
    function transferOwnership (address addr) external virtual onlyOwner {
        require(addr != address(0), "non-zero address required");
        emit OnOwnershipTransferred(_owner, addr);
        _owner = addr;
    }

    /**
     * @notice Gets the owner of this contract.
     * @return Returns the address of the owner.
     */
    function owner () external virtual view returns (address) {
        return _owner;
    }
}

interface IBasicAsset {
    function transfer(address to, uint256 value) external;
    function approve(address spender, uint256 value) external;
    function balanceOf(address addr) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}

interface IParaSwapAugustus {
  function getTokenTransferProxy() external view returns (address);
}

contract Twap is CustomOwnable, ReentrancyGuard {
    address private constant AUGUSTUS_SWAPPER_ADDR = 0xDEF171Fe48CF0115B1d80b88dc8eAB59176FEe57;
    address public operator;

    constructor () {
        _owner = msg.sender;
    }

    modifier onlyOperator() {
        require(operator == msg.sender, "Only operator");
        _;
    }

    function setOperator (address operatorAddr) external onlyOwner {
        require(operatorAddr != address(0) && operatorAddr != address(this), "Invalid operator");
        operator = operatorAddr;
    }

    function swap (bytes memory payload) external onlyOperator nonReentrant {
        (bool success,) = AUGUSTUS_SWAPPER_ADDR.call(payload); // solhint-disable-line avoid-low-level-calls
        require(success, "Swap failed");
    }

    function approveSpenderProxy (IBasicAsset token, uint256 amount) external onlyOperator nonReentrant {
        address proxyAddr = IParaSwapAugustus(AUGUSTUS_SWAPPER_ADDR).getTokenTransferProxy();
        require(token.allowance(address(this), proxyAddr) < amount, "Allowance not needed");
        token.approve(proxyAddr, amount);
    }

    function revokeSpenderProxy (IBasicAsset token) external onlyOperator nonReentrant {
        address proxyAddr = IParaSwapAugustus(AUGUSTUS_SWAPPER_ADDR).getTokenTransferProxy();
        require(token.allowance(address(this), proxyAddr) > 0, "Revoke not needed");

        token.approve(proxyAddr, 0);
    }
}