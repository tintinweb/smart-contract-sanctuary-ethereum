/**
 *Submitted for verification at Etherscan.io on 2022-02-23
*/

interface ITransferNFTV2 {
    function transferFrom(address from, address to, uint256 tokenId) external;
}

interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface ISimpleWallet is IERC721Receiver {
   function onERC721Received(address a1, address a2, uint256 t1, bytes memory b) external returns(bytes4);

   function doAction(address contractAddress, string memory functionSignature, bytes memory parameters) external payable;
   
   function withdrawAll() external;
}

contract SimpleWallet is ISimpleWallet {
  function onERC721Received(address a1, address a2, uint256 t1, bytes memory b) public returns(bytes4) {
    return this.onERC721Received.selector;
  }

   function doAction(address contractAddress, string memory functionSignature, bytes memory parameters) external payable {
       	(bool success, bytes memory data) = contractAddress.call{value: msg.value}(
			abi.encodePacked(
				abi.encodeWithSelector(bytes4(keccak256(abi.encodePacked(functionSignature)))),
            	parameters
			)
        );
   }

   function transferTokens(address nftAddress, address to, uint256[] memory tokensIds) external {
   		for (uint256 i = 0; i < tokensIds.length; i++) {
            ITransferNFTV2(nftAddress).transferFrom(address(this), to, tokensIds[i]);
        }
   }
   
   function withdrawAll() external {
    	payable(msg.sender).transfer(address(this).balance);
   }

   fallback() external payable {
   }
}