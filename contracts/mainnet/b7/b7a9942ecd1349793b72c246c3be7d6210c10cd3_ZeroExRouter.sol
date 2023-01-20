/**
 *Submitted for verification at Etherscan.io on 2023-01-20
*/

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

// A partial ERC20 interface.
interface IERC20 {
    function balanceOf(address owner) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);
}

// Minimal setup for curve error codes
contract CurveErrorCodes {
    enum Error {
        OK, // No error
        INVALID_NUMITEMS, // The numItem value is 0
        SPOT_PRICE_OVERFLOW // The updated spot price doesn't fit into 128 bits
    }
}

// Minimal interface for LSSVMPair
interface ILSSVMPair {
    function swapTokenForSpecificNFTs(
        uint256[] calldata nftIds,
        uint256 maxExpectedTokenInput,
        address nftRecipient,
        bool isRouter,
        address routerCaller
    ) external payable returns (uint256 inputAmount);

    function getBuyNFTQuote(uint256 numNFTs)
        external
        view
        returns (
            CurveErrorCodes.Error error,
            uint256 newSpotPrice,
            uint256 newDelta,
            uint256 inputAmount,
            uint256 protocolFee
        );
}

contract ZeroExRouter {
    function swapETHForTokensThenTokensForNFT(
        IERC20 toToken, 
        address payable swapTarget,  // The `to` field from the 0x API response.
        bytes calldata swapCallData, // The `data` field from the 0x API response.
        address pairAddress,
        uint256[] calldata idsToBuy
    ) external payable {

        // Do the 0x API swap
        {
            // Swap ETH for tokens
            (bool success, ) = swapTarget.call{value: msg.value}(swapCallData);
            require(success, "Swap failed");

            // Refund any unspent protocol fees to the caller
            payable(msg.sender).transfer(address(this).balance);
        }
        
        // Do the swap on sudo
        {
            // Get buy quote
            (, , , uint256 amountToSend, ) = ILSSVMPair(pairAddress)
                .getBuyNFTQuote(idsToBuy.length);

            // Get current balance
            uint256 tokenBalance = toToken.balanceOf(address(this));

            // Check we have at least amount needed (will revert if this underflows)
            uint256 difference = tokenBalance - amountToSend;

            // Send excess tokens back to caller
            if (difference > 0) {
              toToken.transfer(msg.sender, difference);
            }

            // Set approval for just the amount to send to the pair
            toToken.approve(pairAddress, amountToSend);

            // Do the swap
            ILSSVMPair(pairAddress).swapTokenForSpecificNFTs(idsToBuy, amountToSend, msg.sender, false, msg.sender);
        }
    }

    receive() external payable {}
}