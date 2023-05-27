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
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MultiSig {
    address[3] public owners;
    uint constant public REQUIRED_CONFIRMATIONS = 3;

    mapping (bytes32 => uint8) public confirmations;

    event Submission(address indexed sender, bytes32 indexed transactionId);
    event Confirmation(address indexed sender, bytes32 indexed transactionId);
    event Execution(bytes32 indexed transactionId);

    constructor(address[3] memory _owners) {
        owners = _owners;
    }

    function submitTransaction(address payable destination, uint256 value, bytes memory data) public returns(bytes32) {
        bytes32 transactionId = keccak256(abi.encodePacked(destination, value, data, block.timestamp));
        require(isOwner(msg.sender), "Only owners can submit transaction");
        confirmations[transactionId] += 1;
        emit Submission(msg.sender, transactionId);
        return transactionId;
    }

    function confirmTransaction(bytes32 transactionId) public {
        require(isOwner(msg.sender), "Only owners can confirm transaction");
        confirmations[transactionId] += 1;
        if(confirmations[transactionId] >= REQUIRED_CONFIRMATIONS) {
            executeTransaction(transactionId);
        }
    }

    function executeTransaction(bytes32 transactionId) public {
        require(confirmations[transactionId] >= REQUIRED_CONFIRMATIONS, "Transaction requires more confirmations");
        (address payable destination, uint256 value, bytes memory data) = decodeTransactionId(transactionId);
        (bool success, ) = destination.call{ value: value }(data);
        require(success, "Failed to execute transaction");
        emit Execution(transactionId);
    }

    function withdrawTokens(bytes32 transactionId, address tokenAddress, uint256 amount, address to) public {
    require(confirmations[transactionId] >= REQUIRED_CONFIRMATIONS, "Transaction requires more confirmations");
    require(isOwner(msg.sender), "Only owners can withdraw tokens");

    IERC20 token = IERC20(tokenAddress);
    token.transfer(to, amount);

    emit Execution(transactionId);
}

    function isOwner(address addr) public view returns(bool) {
        for(uint i = 0; i < owners.length; i++) {
            if(owners[i] == addr) {
                return true;
            }
        }
        return false;
    }

    function decodeTransactionId(bytes32 transactionId) private pure returns(address payable, uint256, bytes memory) {
        // decode the transactionId here
        // this function will vary depending on how your `submitTransaction` encodes these values.
    }
}