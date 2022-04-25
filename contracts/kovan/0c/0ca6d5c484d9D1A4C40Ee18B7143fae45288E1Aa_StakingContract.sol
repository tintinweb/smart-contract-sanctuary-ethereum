pragma solidity ^0.8.3;

import "./interfaces/IMYERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract StakingContract {
    IERC20 public coinAddress;
    address public rewardToken;

    address public owner;
    struct userDetails {
        uint256 timestamp;
    }
    mapping(address => userDetails) public users;

    modifier onlyAdmin() {
        require(msg.sender == owner);
        _;
    }

    constructor(address _coinAddress, address _rewardToken) {
        coinAddress = IERC20(_coinAddress);
        rewardToken = _rewardToken;
        owner = msg.sender;
    }

    function deposit(uint256 amount) external {
        require(
            amount > 0,
            "StakingContract: Amount must be greater than zero"
        );
        coinAddress.transferFrom(msg.sender, address(this), amount);
        IMYERC20(rewardToken).mint(msg.sender, amount);
        users[msg.sender].timestamp = block.timestamp;
    }

    function withdraw(uint256 amount) external {
        require(
            amount > 0,
            "StakingContract: Amount must be greater than zero"
        );
        require(
            IERC20(rewardToken).balanceOf(msg.sender) >= amount,
            "StakingContract: You have insufficents stake amount"
        );

        require(
            users[msg.sender].timestamp + 30 days < block.timestamp,
            "StakingContract: You can withdraw after 30 days"
        );
        coinAddress.transfer(msg.sender, amount);
        IMYERC20(rewardToken).burn(msg.sender, amount);
    }
}

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMYERC20 {
    function mint(address user, uint256 amount) external;

    function burn(address user, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}