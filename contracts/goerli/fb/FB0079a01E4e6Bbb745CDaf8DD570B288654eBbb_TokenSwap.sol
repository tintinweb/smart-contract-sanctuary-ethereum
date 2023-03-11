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
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

//  USDT/BTC/ETH or similar




contract TokenSwap {
    uint256[] public mins;
    address payable owner;
    uint256 public amountOut;

    int128 public constant N_COINS = 3;
    // uint256 public constant PRECISION = 10**18; probably not needed
    address[N_COINS] tokens = [
        0x65aFADD39029741B3b8f0756952C74678c9cEC93, // USDC
        0x75Ab5AB1Eef154C0352Fc31D2428Cef80C7F8B33, // DAI
        0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6 // WETH
    ];

    constructor() {
        owner = payable(msg.sender);
    }

    uint256 RATE = 100e6;

    // An event to log the result of the swap
    event SwapResult(uint256 amountIn, uint256 amountOut);

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy,
        bool use_eth
    ) external {
        require(i < N_COINS, "Token out of bounds");
        require(j < N_COINS, "Token out of bounds");
        assert(i != j);

        // push  min to test what it looks like
        mins.push(min_dy);

        IERC20 token0;
        IERC20 token1;

        if (i == 0) {
            token0 = IERC20(tokens[0]); // ifs might be burning to much gas?
        }
        if (i == 1) {
            token0 = IERC20(tokens[1]);
        }
        if (i == 2) {
            token0 = IERC20(tokens[2]);
        }

        if (j == 0) {
            token1 = IERC20(tokens[0]);
        }
        if (j == 1) {
            token1 = IERC20(tokens[1]);
        }
        if (j == 2) {
            token1 = IERC20(tokens[2]);
        }

        // Approve spending

        require(token0.approve(address(this), dx), "Not approved");

        // Transfer token A from msg.sender to this contract
        require(token0.transferFrom(msg.sender, address(this), dx), "Transfer failed");

        // Calculate the amount of token B to send back
        amountOut = dx * RATE;

        // Transfer token B from this contract to msg.sender
        require(token1.transfer(msg.sender, amountOut), "Transfer failed");

        // Emit an event with the result
        emit SwapResult(dx, amountOut);
    }

    function getRate() external view returns (uint256) {
        return RATE;
    }

    function withdraw(address _tokenAddress) external onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    function changeRate(uint256 _RATE) external {
        RATE = _RATE;
    }

    function getMin(uint256 i) external view returns (uint256) {
        return mins[i];
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }
}