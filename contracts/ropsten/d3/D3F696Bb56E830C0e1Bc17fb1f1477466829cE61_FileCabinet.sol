pragma solidity ^0.8.0;

import "./Will.sol";

contract FileCabinet {
    mapping(address => address[]) public cabinet;

    event NewWill(address will, address benefactor);

    function newWill(address benefactor, address beneficiary, uint256 sealedTime) external {
        Will will = new Will(benefactor, beneficiary, sealedTime);
        cabinet[benefactor].push(address(will));
        emit NewWill(address(will), benefactor);
    }

    function getWills(address benefactor) public view returns (address[] memory) {
        return cabinet[benefactor];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "../node_modules/openzeppelin-solidity/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract Will {
    string public document;
    address public benefactor;
    address public beneficiary;
    uint256 public sealedTime;

    constructor(address _benefactor, address _beneficiary, uint256 _sealedTime) public {
        benefactor = _benefactor;
        beneficiary = _beneficiary;
        sealedTime = _sealedTime + block.timestamp;
    }

    modifier isBenefactor() {
        require(msg.sender == benefactor, "Not the benefactor.");
        _;
    }

    modifier isBeneficiary() {
        require(msg.sender == beneficiary, "Not the beneficiary.");
        _;
    }

    event Claimed(address token, address from, address to, uint256 amount);
    event Withdrew(address from, address to, uint256 amount);

    modifier valid() {
        require(
            msg.sender == benefactor || (msg.sender == beneficiary && block.timestamp >= sealedTime), "Invalid.");
        _;
    }
    function claim(address tokenAddress, address to, uint256 amount) external valid {
        IERC20Metadata token = IERC20Metadata(tokenAddress);
        require(token.balanceOf(address(this)) >= amount, "Error: Insufficient Balance.");
        token.transfer(to, amount);
        emit Claimed(tokenAddress, msg.sender, to, amount);
    }

    function withdraw(address payable to, uint256 amount) external valid {
        require(address(this).balance >= amount, "Error: Insufficient Balance.");
        to.transfer(amount);
        emit Withdrew(msg.sender, to, amount);
    }
}