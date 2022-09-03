pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Escrow {
    IERC20 public _token;
    address private _owner;

    constructor(address ERC20Address) {
        _token = IERC20(ERC20Address);
        _owner = msg.sender;
    }

    uint256 deposit_count;
    mapping(bytes32 => uint256) balances;

    function depositEscrow(bytes32 trx_hash, uint256 amount) external {
        // Transaction hash cannot be empty
        require(trx_hash[0] != 0, "Transaction hash cannot be empty!");
        // Escrow amount cannot be equal to 0
        require(amount != 0, "Escrow amount cannot be equal to 0.");
        // Transaction hash is already in use
        require(
            balances[trx_hash] == 0,
            "Unique hash conflict, hash is already in use."
        );
        // Transfer ERC20 token from sender to this contract
        require(
            _token.transferFrom(msg.sender, address(this), amount),
            "Transfer to escrow failed!"
        );
        balances[trx_hash] = amount;
        deposit_count++;
    }

    function getHash(uint256 amount) public view returns (bytes32 result) {
        return keccak256(abi.encodePacked(msg.sender, deposit_count, amount));
    }

    function withdrawalEscrow(bytes32 trx_hash) external {
        // Transaction hash cannot be empty
        require(trx_hash[0] != 0, "Transaction hash cannot be empty!");
        // Check if trx_hash exists in balances
        require(
            balances[trx_hash] != 0,
            "Escrow with transaction hash doesn't exist."
        );
        // Transfer escrow to sender
        require(
            _token.transfer(msg.sender, balances[trx_hash]),
            "Escrow retrieval failed!"
        );
        // If all is done, status is amounted to 0
        balances[trx_hash] = 0;
    }
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