//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ICheckFaucet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "@openzeppelin/contracts/utils/Strings.sol";

contract CheckFaucet is ICheckFaucet, Context {
    IERC20 _token;
    uint256 _requiredDelayBetweenTransactions;
    uint256 _requiredRegularDropDelay;

    uint256 constant REGULAR_DROP_AMOUNT = 5_000 * (10**6);

    struct TokenIssue {
        uint256 issuedAmount;
        uint256 lastRequestTime;
        uint256 lastRequestDate;
    }

    mapping(address => TokenIssue) private _issues;

    constructor(
        address token,
        uint256 requiredDelayBetweenTransactions,
        uint256 requiredRegularDropDelay
    ) {
        _token = IERC20(token);
        _requiredDelayBetweenTransactions = requiredDelayBetweenTransactions;
        _requiredRegularDropDelay = requiredRegularDropDelay;
    }

    function issue(address account, uint256 amount) external override {
        if (amount > REGULAR_DROP_AMOUNT) {
            revert(
                "CheckFaucet: the issued amount can not be more than 5000 token"
            );
        }

        TokenIssue storage tokenIssue = _issues[account];
        uint256 secondsSinceLastIssue = (block.timestamp -
            tokenIssue.lastRequestTime);
        uint256 timeSinceLastIssue = (block.timestamp -
            tokenIssue.lastRequestTime);

        if (timeSinceLastIssue < _requiredDelayBetweenTransactions) {
            revert(
                "CheckFaucet: one account can make only one request per required delay between transactions"
            );
        }

        if (secondsSinceLastIssue < _requiredRegularDropDelay) {
            if (tokenIssue.issuedAmount + amount > REGULAR_DROP_AMOUNT) {
                revert(
                    "CheckFaucet: one account can receive only 5000 per required delay time"
                );
            }

            tokenIssue.issuedAmount += amount;
            tokenIssue.lastRequestTime = block.timestamp;
        } else {
            tokenIssue.issuedAmount = amount;
            tokenIssue.lastRequestTime = block.timestamp;
        }

        _token.transfer(account, amount);

        emit Issue(account, amount);
    }

    function getLastRequestDateForAddress(address account)
        public
        view
        returns (uint256)
    {
        require(
            _issues[account].issuedAmount > 0,
            "CheckFaucet: the account didn't issue any tokens yet"
        );

        return _issues[account].lastRequestTime;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICheckFaucet {
    event Issue(address account, uint256 amount);


    function issue(address account, uint256 amount) external;
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}