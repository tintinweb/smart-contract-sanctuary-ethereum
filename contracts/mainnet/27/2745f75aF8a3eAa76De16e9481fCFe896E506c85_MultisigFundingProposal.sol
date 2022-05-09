// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ISablier } from "./interfaces/ISablier.sol";

contract MultisigFundingProposal {
    address public constant TORN = 0x77777FeDdddFfC19Ff86DB637967013e6C6A116C;
    address public constant MULTISIG = 0xb04E030140b30C27bcdfaafFFA98C57d80eDa7B4;
    address public constant SABLIER = 0xCD18eAa163733Da39c232722cBC4E8940b1D8888;
    uint256 public constant AMOUNT = 35_000 ether; // 35,000 TORN
    uint256 public constant VESTING_AMOUNT = 65_000 ether; // 65,000 TORN
    uint256 public constant VESTING_PERIOD = 31_536_000; // 365 days

    event StreamCreated(uint256 streamId);

    function executeProposal() external {
        // send TORN to multisig
        require(IERC20(TORN).transfer(MULTISIG, AMOUNT), "Transfer failed");

        // init Sablier stream for multisig funding
        IERC20(TORN).approve(SABLIER, VESTING_AMOUNT);
        uint256 streamId = ISablier(SABLIER).createStream(
            MULTISIG,
            VESTING_AMOUNT - (VESTING_AMOUNT % VESTING_PERIOD),
            TORN,
            block.timestamp + 3600, // 1 hour from now
            block.timestamp + VESTING_PERIOD + 3600 // VESTING_PERIOD and 1 hour from now
        );
        emit StreamCreated(streamId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface ISablier {
    function createStream(
        address recipient,
        uint256 deposit,
        address tokenAddress,
        uint256 startTime,
        uint256 stopTime
    ) external returns (uint256 streamId);

    function withdrawFromStream(uint256 streamId, uint256 funds) external returns (bool);
}