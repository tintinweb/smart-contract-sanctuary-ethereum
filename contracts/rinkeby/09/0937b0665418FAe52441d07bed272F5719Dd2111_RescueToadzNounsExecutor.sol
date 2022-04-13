/* SPDX-License-Identifier: MIT */

/**
 *   @title Rescue Toadz Nouns Executor
 *   @author Vladimir Haltakov (@haltakov)
 *   @notice A special contract to be used by Nouns DAO to capture Rescue Toadz
 *   @notice The Nouns DAO contract used to execute accepted proposals cannot receive ERC-1155 tokens so it cannot be used to capture Rescue Toadz to donate to Ukraine.
 *   @notice This is a specialized contract that will call the capture function on the Rescue Toadz contract and hold the received ERC-1155 tokens.
 *   @notice The contract implements a withdrawal function that allows Nouns DAO to later transfer the tokens to an arbitrary wallet
 */

pragma solidity ^0.8.12;

/**
 * @dev Interface of the Rescue Toadz contract
 */
interface RescueToadz {
    function lastPrice(uint256 tokenId) external view returns (uint256);

    function capture(uint256 tokenId) external payable;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;
}

contract RescueToadzNounsExecutor {
    // Address of the Rescue Toadz contract
    address internal constant RESCUE_TOADZ_CONTRACT =
        0x03115Dafa9c3F23BEB8ECDA7F099fD4C09981E82;

    // Address of the Nouns DAO contract that is allowed to withdraw ERC-1155 tokens
    address internal constant NOUNS_DAO =
        0x9fecC154ABa86dB310cC3A81bb65f81155d6Bf98;

    constructor() {}

    /**
     * @dev Call the capture function of the Rescue Toad contract passing all the funds
     * @notice If the Rescue Toad specified by the token ID is already captures, this function will not fail, but do nothing instead
     * @param tokenId The id of the Rescue Toadz to capture
     */
    function captureRescueToad(uint256 tokenId) external payable {
        // Get the last price of the specified Rescue Toad
        uint256 lastTokenPrice = RescueToadz(RESCUE_TOADZ_CONTRACT).lastPrice(
            tokenId
        );

        // Capture the Rescue Toad only if the last price is <= the amount of the transaction
        if (lastTokenPrice <= msg.value) {
            RescueToadz(RESCUE_TOADZ_CONTRACT).capture{value: msg.value}(
                tokenId
            );
        } else {
            // If the toad will not be captured, return the funds to the sender
            (bool sent, ) = payable(msg.sender).call{value: msg.value}("");
            require(sent, "Failed to send Ether");
        }
    }

    /**
     * @dev Withdraw a Rescue Toad ERC-1155 token to another wallet
     * @notice Only allowed for the Nouns DAO wallet
     * @param tokenId The id of the Rescue Toad to transfer
     * @param to Address where the Rescue Toad will be transferred
     */
    function withdrawRescueToad(uint256 tokenId, address to) external {
        require(msg.sender == NOUNS_DAO, "Only Nouns DAO can withdraw");

        RescueToadz(RESCUE_TOADZ_CONTRACT).safeTransferFrom(
            address(this),
            to,
            tokenId,
            1,
            ""
        );
    }

    /**
     * @notice Needed so that the contract can receive ERC-1155 tokens
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external view returns (bytes4) {
        return
            bytes4(
                keccak256(
                    "onERC1155Received(address,address,uint256,uint256,bytes)"
                )
            );
    }
}