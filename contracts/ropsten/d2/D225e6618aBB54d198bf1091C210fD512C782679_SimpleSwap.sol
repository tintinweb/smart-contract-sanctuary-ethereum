//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// A partial ERC20 interface.
import "./IERC20.sol";

contract SimpleSwap {
    // Creator of this contract.
    address public owner;

    event Swapped(IERC20 buyToken, uint256 buyAmount);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "ONLY_OWNER");
        _;
    }

    // Payable fallback to allow this contract to receive protocol fee refunds.
    /* solhint-disable no-empty-blocks */
    receive() external payable {}

    // Swaps ETH -> ERC20 token
    /* solhint-disable avoid-low-level-calls */
    function swapEthToToken(
        // The `buyTokenAddress` field from the API response.
        IERC20 buyToken,
        // The `to` field from the API response.
        address payable swapTarget,
        // The `data` field from the API response.
        bytes calldata swapCallData
    )
        external
        payable
        onlyOwner // Must attach ETH equal to the `value` field from the API response.
    {
        // Track our balance of the buyToken to determine how much we've bought.
        uint256 buyAmount = buyToken.balanceOf(address(this));

        // Call the encoded swap function call on the contract at `swapTarget`,
        // passing along any ETH attached to this function call to cover protocol fees.
        (bool success, ) = swapTarget.call{value: msg.value}(swapCallData);
        require(success, "SWAP_CALL_FAILED");

        // Use our current buyToken balance to determine how much we've bought.
        buyAmount = buyToken.balanceOf(address(this)) - buyAmount;
        emit Swapped(buyToken, buyAmount);

        // Transfer tokens back
        require(buyToken.transfer(msg.sender, buyAmount), "TOKEN_TRANSFER_FAILED");
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// A partial ERC20 interface.
interface IERC20 {
    function balanceOf(address owner) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);
}