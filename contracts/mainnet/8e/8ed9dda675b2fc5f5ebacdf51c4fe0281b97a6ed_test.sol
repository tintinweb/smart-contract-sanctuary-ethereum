/**
 *Submitted for verification at Etherscan.io on 2022-07-18
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

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

interface fly{
    function burnDirtyFlies(uint[] memory tokenIds) external;
    function balanceOf(address owner) external view returns (uint256);
    function setApprovalForAll(address operator, bool approved) external;
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

contract test is IERC721Receiver{
    

    function burn(uint[] memory id,uint256 amount) public payable  {
       fly(0x01A75Fb1A4b1A8f699fd00ad051f9100EbEcec42).burnDirtyFlies(id);
       require(fly(0x01A75Fb1A4b1A8f699fd00ad051f9100EbEcec42).balanceOf(address(this)) == amount + 1,"fail");

    }

    function withdrawNFT(uint[] memory tokenId) public{
       for(uint i = 0; i < tokenId.length; i++){
           fly(0x01A75Fb1A4b1A8f699fd00ad051f9100EbEcec42).transferFrom(address(this),msg.sender,tokenId[i]);
       }
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return 0x150b7a02;
    }

    // Used by ERC721BasicToken.sol
    function onERC721Received(
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return 0xf0b9e5ba;
    }

function setapprove() public{
    fly(0x9984bD85adFEF02Cea2C28819aF81A6D17a3Cb96).setApprovalForAll(0x01A75Fb1A4b1A8f699fd00ad051f9100EbEcec42,true);
}

}