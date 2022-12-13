pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IWalletFactory.sol";

contract Wallet is ReentrancyGuard {
    uint256 public nonce;
    address public owner;
    address public factory;
    bytes public lastInstructions;
    bytes[] public lastReturnsData;

    struct Delegator {
        address target;
        uint256 value;
        bytes payload;
        bool isInternalValue;
        bool isDelegate;
    }

    event ChainExecuted (
        uint256 indexed nonce,
        bytes payload,
        bytes[] returnsData
    );

    receive() external payable {}

    constructor(address _owner) {
        factory = msg.sender;
        owner = _owner;
    }

    function execute(bytes calldata _instructions, bytes calldata _signature)
        external
        nonReentrant
        payable
    {
        require(msg.sender == owner, "Wallet: Only owner allowed to execute this func");
        require(
            IWalletFactory(factory).verify(_instructions, _signature),
            "Wallet: Invalid signature"
        );
        (uint256 trxNonce, address user, Delegator[] memory delegator) = abi.decode(
            _instructions,
            (uint256, address, Delegator[])
        );
        require(trxNonce == nonce, "Wallet: Invalid nonce");
        require(user == owner, "Wallet: Invalid user");
        require(delegator.length > 0, "Wallet: No delegators");
        nonce++;

        uint256 valueCheck;
        for (uint256 i = 0; i < delegator.length; i++) {
            if (!delegator[i].isInternalValue) {
                valueCheck += delegator[i].value;
            }
        }
        require(msg.value >= valueCheck, "Wallet: Value is not enough");
        lastInstructions = _instructions;
        delete lastReturnsData;

        for (uint256 i = 0; i < delegator.length; i++) {
            if (delegator[i].isDelegate) {
                (bool success, bytes memory returnsData) = address(
                    delegator[i].target
                ).delegatecall(delegator[i].payload);
                require(success, "Wallet: Trxs chain error");
                lastReturnsData.push(returnsData);
            } else {
                (bool success, bytes memory returnsData) = address(
                    delegator[i].target
                ).call{value: delegator[i].value}(delegator[i].payload);
                require(success, "Wallet: Trxs chain error");
                lastReturnsData.push(returnsData);
            }
        }

        emit ChainExecuted(nonce - 1, _instructions, lastReturnsData);
    }

    function getTokenAmount(address _token) external view returns (uint256) {
        require(_token != address(0), "Wallet: Invalid token address");
        return IERC20(_token).balanceOf(address(this));
    }

    function getETHAmount() external view returns (uint256) {
        return address(this).balance;
    }
    
}

pragma solidity ^0.8.0;

interface IWalletFactory {
  function verify(bytes calldata, bytes calldata) external view returns (bool);
  function comissionsAddress() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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