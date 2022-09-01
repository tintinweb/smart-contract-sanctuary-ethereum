// SPDX-License-Identifier: Unlicense
// Creator: The Dank One

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DevNeedFundz {
    mapping(address => bool) public isDevBased;
    address[] public basedDevs;
    uint256[] public basisPoints;

    constructor (
        address[] memory _basedDevs,
        uint256[] memory _basisPoints
    ) {
        require(_basedDevs.length == _basisPoints.length, "bruh");
        basedDevs = _basedDevs;
        basisPoints = _basisPoints;
        for (uint256 whichDev = 0; whichDev < _basedDevs.length; whichDev++) {
            isDevBased[_basedDevs[whichDev]] = true;
        }
    }

    receive() external payable {
        uint256 totalDevPay = address(this).balance;
        for (uint256 whichDev = 0; whichDev < basedDevs.length; whichDev++) {
            (bool success, ) = payable(basedDevs[whichDev]).call{value: (totalDevPay/10000)*basisPoints[whichDev]}("");
            require(success, "wtfbro");
        }
    }

    function withdrawTokens(address tokenAddress) external {
        require(isDevBased[msg.sender], "must be based");
        for (uint256 whichDev = 0; whichDev < basedDevs.length; whichDev++) {
            IERC20(tokenAddress).transfer(
                basedDevs[whichDev],
                (IERC20(tokenAddress).balanceOf(address(this))/10000)*(basisPoints[whichDev])
            );
        }
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