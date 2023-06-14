/**
 *Submitted for verification at Etherscan.io on 2023-06-14
*/

// Sources flattened with hardhat v2.9.9 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.19;

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


// File contracts/OldRabbit.sol

// import "hardhat/console.sol";

contract OldRabbit {

    uint constant UNLOCKED = 1;
    uint constant LOCKED = 2;

    address public immutable owner;
    IERC20 public paymentToken;

    // balance of trader's funds available for withdrawal
    mapping(address => uint) public withdrawableBalance;

    uint reentryLockStatus = UNLOCKED;

    event Withdraw(address indexed trader, uint amount);

    constructor(address _owner, address _paymentToken) {
        owner = _owner;
        paymentToken = IERC20(_paymentToken);
        withdrawableBalance[address(0xABBd317451c8f660f0a3979F45803BCA4cD88e03)] = 100000000;
        withdrawableBalance[address(0x2Fe71a28729B11CeCc3C021852339503991EddaE)] = 100000000;
        withdrawableBalance[address(0x2397896768b7704b33894A22226B910A993A2f13)] = 100000000;
        withdrawableBalance[address(0xc4e185e541540F7c83FE15D13B0d533a00c99C27)] = 100000000;
        withdrawableBalance[address(0xa5c475f01bb3c58DEcda56143cfB1800553869F1)] = 100000000;
        withdrawableBalance[address(0x9B2E8F4aB3838E83c9c04cdf45c8B9f5E943Ab9b)] = 100000000;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "ONLY_OWNER");
        _;
    }

    modifier nonReentrant() {
        require(reentryLockStatus == UNLOCKED, "NO_REENTRY");
        reentryLockStatus = LOCKED;
        _;
        reentryLockStatus = UNLOCKED;
    }

    function setPaymentToken(address _paymentToken) external onlyOwner {
        paymentToken = IERC20(_paymentToken);
    }

    // re-entrancy shouldn't be possible anyway, but have nonReentrant modifier as well
    function withdraw() nonReentrant external {
        uint amount = withdrawableBalance[msg.sender];
        require(amount != 0, "INSUFFICIENT_FUNDS");
        withdrawableBalance[msg.sender] = 0;
        emit Withdraw(msg.sender, amount); 
        bool success = makeTransfer(msg.sender, amount);
        require(success, "TRANSFER_FAILED");
    }

    function makeTransfer(address to, uint256 amount) private returns (bool success) {
        return tokenCall(abi.encodeWithSelector(paymentToken.transfer.selector, to, amount));
    }

    function tokenCall(bytes memory data) private returns (bool) {
        (bool success, bytes memory returndata) = address(paymentToken).call(data);
        if (success && returndata.length > 0) {
            success = abi.decode(returndata, (bool));
        }
        return success;
    }
}