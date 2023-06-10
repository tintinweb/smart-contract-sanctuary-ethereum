// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Modified from Gnosis (https://github.com/gnosis/gp-v2-contracts/blob/main/src/contracts/libraries/GPv2SafeERC20.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
library SafeTransferLib {
    /*///////////////////////////////////////////////////////////////
                            ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool callStatus;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(callStatus, "ETH_TRANSFER_FAILED");
    }
}

// A partial ERC20 interface.
interface IERC20 {
    function balanceOf(address owner) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
}

interface IERC721 {
    function approve(address to, uint256 tokenId) external;
}

interface IERC1155 {
    function setApprovalForAll(address operator, bool approved) external;
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
    function swapNFTsForToken(
        uint256[] calldata nftIds,
        uint256 minExpectedTokenOutput,
        address payable tokenRecipient,
        bool isRouter,
        address routerCaller
    ) external returns (uint256 outputAmount);

    function swapTokenForSpecificNFTs(
        uint256[] calldata nftIds,
        uint256 maxExpectedTokenInput,
        address nftRecipient,
        bool isRouter,
        address routerCaller
    ) external payable returns (uint256 inputAmount);

    function getBuyNFTQuote(uint256 assetId, uint256 numNFTs)
        external
        view
        returns (
            CurveErrorCodes.Error error,
            uint256 newSpotPrice,
            uint256 newDelta,
            uint256 inputAmount,
            uint256 protocolFee,
            uint256 royaltyAmount
        );
}

contract ZeroExRouter {
    using SafeTransferLib for address payable;

    error InsufficientETH();

    function onERC721Received(address , address from, uint256 id, bytes memory data) public returns (bytes4) {
        (
            address pairAddress,
            uint256 minTokenOutput,
            address outputToken,
            address swapTarget,
            uint256 minETHOutput,
            bytes memory swapTargetData
        ) = abi.decode(data, (address, uint256, address, address, uint256, bytes));

        // // Approve the pair for the specific NFT ID
        IERC721(msg.sender).approve(pairAddress, id);

        // Swap the pair for tokens
        uint256[] memory ids = new uint256[](1);
        ids[0] = id;
        uint256 outputAmount =
            ILSSVMPair(pairAddress).swapNFTsForToken(ids, minTokenOutput, payable(address(this)), false, address(0));

        require(outputAmount >= minTokenOutput, ":(");

        // Approve the tokens for the 0x target
        IERC20(outputToken).approve(swapTarget, outputAmount);

        // Swap tokens for ETH
        swapTarget.call(swapTargetData);

        // Send ETH to the original caller if it's enough
        if (address(this).balance >= minETHOutput) {
            payable(from).safeTransferETH(address(this).balance);
        }
        // Otherwise, revert
        else {
            revert InsufficientETH();
        }

        // Send any excess tokens to the original caller
        uint256 tokenBalance = IERC20(outputToken).balanceOf(address(this));
        if (tokenBalance > 0) {
            IERC20(outputToken).transfer(from, tokenBalance);
        }

        // Return selector
        return this.onERC721Received.selector;
    }

    function onERC1155Received(address , address from, uint256 , uint256 amount, bytes memory data)
        public
        returns (bytes4)
    {
        (
            address pairAddress,
            uint256 minTokenOutput,
            address outputToken,
            address swapTarget,
            uint256 minETHOutput,
            bytes memory swapTargetData
        ) = abi.decode(data, (address, uint256, address, address, uint256, bytes));

        // Approve the pair for the specific NFT ID
        IERC1155(msg.sender).setApprovalForAll(pairAddress, true);

        // Swap the pair for tokens
        uint256[] memory swapInfo = new uint256[](1);
        swapInfo[0] = amount;
        uint256 outputAmount = ILSSVMPair(pairAddress).swapNFTsForToken(
            swapInfo, minTokenOutput, payable(address(this)), false, address(0)
        );
        require(outputAmount >= minTokenOutput, ":(");

        // Approve the tokens for the 0x target
        IERC20(outputToken).approve(swapTarget, outputAmount);

        // Swap tokens for ETH
        swapTarget.call(swapTargetData);

        // Send ETH to the original caller if it's enough
        if (address(this).balance >= minETHOutput) {
            payable(from).safeTransferETH(address(this).balance);
        }
        // Otherwise, revert
        else {
            revert InsufficientETH();
        }

        // Send any excess tokens to the original caller
        uint256 tokenBalance = IERC20(outputToken).balanceOf(address(this));
        if (tokenBalance > 0) {
            IERC20(outputToken).transfer(from, tokenBalance);
        }
        return this.onERC1155Received.selector;
    }

    function swapETHForTokensThenTokensForNFT(
        address toTokenAddress, // The `to` field from the 0x API response.
        address payable swapTarget, // The `data` field from the 0x API response.
        bytes calldata swapCallData,
        address pairAddress,
        uint256[] calldata swapInfo,
        uint256 nftId,
        uint256 numItems
    ) external payable {
        // Do the 0x API swap
        {
            // Swap ETH for tokens
            swapTarget.call{value: msg.value}(swapCallData);

            // Refund any unspent protocol fees to the caller
            payable(msg.sender).transfer(address(this).balance);
        }

        // Do the swap on sudo
        {
            // Get buy quote
            (,,, uint256 amountToSend,,) = ILSSVMPair(pairAddress).getBuyNFTQuote(nftId, numItems);

            // Set approval for just the amount to send
            IERC20(toTokenAddress).approve(pairAddress, amountToSend);

            // Do the swap
            ILSSVMPair(pairAddress).swapTokenForSpecificNFTs(swapInfo, amountToSend, msg.sender, false, msg.sender);

            // Get current balance
            uint256 tokenBalance = IERC20(toTokenAddress).balanceOf(address(this));

            // Send excess tokens back to caller
            if (tokenBalance > 0) {
                IERC20(toTokenAddress).transfer(msg.sender, tokenBalance);
            }
        }
    }

    receive() external payable {}
}