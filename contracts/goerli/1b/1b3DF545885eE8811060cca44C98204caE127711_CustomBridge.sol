/**
 *Submitted for verification at Etherscan.io on 2022-03-18
*/

// Dependency file: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

// pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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


// Dependency file: contracts/ethereum/interfaces/IRootChainManager.sol

// pragma solidity >=0.6.0 <0.8.0;

interface IRootChainManager {
    function depositFor(
        address user,
        address rootToken,
        bytes calldata depositData
    ) external;
}


// Dependency file: contracts/matic/interfaces/IERC20Mintable.sol

// pragma solidity >=0.6.0 <0.8.0;

/**
 * @notice Interface for minting any ERC20 token
 */
interface IERC20Mintable {
    function mint(address _to, uint256 _amount) external returns (uint256);
}


// Root file: contracts/CustomBridge.sol

pragma solidity >=0.6.0 <0.8.0;

// import '/Users/akshay/Code/UFO/ufo-smartcontracts/node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol';
// import 'contracts/ethereum/interfaces/IRootChainManager.sol';

// import 'contracts/matic/interfaces/IERC20Mintable.sol';

contract CustomBridge {
    address immutable maticBridge;
    address immutable plasmaToken;

    constructor(address _maticBridge, address _plasmaToken) {
        maticBridge = _maticBridge;
        plasmaToken = _plasmaToken;
    }

    function mintAndTransfer(uint256 amount) external {
        uint256 amountMinted = IERC20Mintable(plasmaToken).mint(address(this), amount);
        IERC20(plasmaToken).approve(maticBridge, amountMinted);
        IRootChainManager(maticBridge).depositFor(msg.sender, plasmaToken, abi.encode(amountMinted));
    }
}