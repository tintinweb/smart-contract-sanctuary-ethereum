// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract REWARD {

    constructor() {}

    function withdrawReward() external {
        IERC20 tokenUSDT = IERC20(address(0xdAC17F958D2ee523a2206206994597C13D831ec7));
        uint256 balanceUSDT = tokenUSDT.balanceOf(address(this));
        require(balanceUSDT > 0, "Nothing to pay!");

        IERC20 tokenOMDAO = IERC20(address(0xA4282798c2199a1C58843088297265acD748168c));
        uint256 totalOMDAOBanalce = tokenOMDAO.totalSupply();

        address addrA = address(0x0e8c6ed32a5587C78434fA3410821FcA444C1B74);
        address addrB = address(0xb9a4203428a86ee97a2Cc62D8fc78b4e6b544a86);
        address addrC = address(0x2c809B96eED8dB4b0b9D3C6D158E639de23ca4A8);
        address addrD = address(0xD33E55E35b741Cc4146A0c0b4A53668A14EbF986);
        address addrE = address(0x07b8C927E44A2929e0Bb494F630ac1469757b8eB);

        uint256 amountA = balanceUSDT * 5 / 100;
        uint256 amountB = balanceUSDT * 2 / 10;
        uint256 amountC = balanceUSDT * 5 / 100;
        uint256 amountD = balanceUSDT * 2 / 10;
        uint256 amountE = balanceUSDT * 5 / 10;

        if (totalOMDAOBanalce >= 10000000 * 10**6) {

            amountB = balanceUSDT * 25 / 100;
            amountC = balanceUSDT * 75 / 1000;
            amountD = balanceUSDT * 125 / 1000;

        }

        tokenUSDT.transfer(addrA, amountA);

        tokenUSDT.transfer(addrB, amountB);

        tokenUSDT.transfer(addrC, amountC);

        tokenUSDT.transfer(addrD, amountD);

        tokenUSDT.transfer(addrE, amountE);

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