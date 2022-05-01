// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.11;

import "./IERC721Receiver.sol";
import "./SafeMath.sol";
import "./NFTX.sol";
import "./Land.sol";

interface INFT {
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external returns (address);
    function setApprovalForAll(address operator, bool _approved) external;
}

contract Landooor is Ownable, IERC721Receiver {
    using SafeMath for uint256;

    NFTXMarketplaceZap NFTX;
    Land LAND;

    address public landAddress = 0x34d85c9CDeB23FA97cb08333b511ac86E1C4E258;
    address simplenftxAddress = 0x0fc584529a2AEfA997697FAfAcbA5831faC0c22d;
    address payable nftxAddress = payable(0x0fc584529a2AEfA997697FAfAcbA5831faC0c22d);

    //testing nftx
    address public apeAddress = 0xd5af737470e963F40f9E681b2e9D12ACDBbB5492;
    uint256 public vaultId = 391;
    address[] public path = [0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, 0x0B211CdE9e2420b97AbdF1eCD5B063be97543FE6];
    uint256 estimatedSwapCost = 2000000000000000;

    //bayc NFTX deets
    // address public apeAddress = 0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D;
    // uint256 public vaultId = 2;
    // address[] public path = [0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, 0xEA47B64e1BFCCb773A0420247C0aa0a3C1D2E5C5];
    // uint256 estimatedSwapCost = 9000000000000000000;

    function setLandAddress(address contractAddress) public onlyOwner {
        landAddress = contractAddress;
        LAND = Land(contractAddress);
    }

    function setNFTXAddress(address contractAddress) public onlyOwner {
        nftxAddress = payable(contractAddress);
        NFTX = NFTXMarketplaceZap(payable(contractAddress));
    }

    function setApeAddress(address contractAddress) public onlyOwner {
        apeAddress = contractAddress;
    }

    function approveNFTSpend(address nftAddress, address spender, bool status) public onlyOwner {
        INFT(nftAddress).setApprovalForAll(spender, status);
    }

    constructor() {
        LAND = Land(landAddress);
        NFTX = NFTXMarketplaceZap(nftxAddress);
        INFT(apeAddress).setApprovalForAll(simplenftxAddress, true);
    }

    function claimLand(uint256 apeTokenId) private {
        uint256[] memory tokenID;
        tokenID[0] = apeTokenId;
        uint256[] memory empty;
        LAND.nftOwnerClaimLand(tokenID, empty);
    }

    //perform batch swap
    function batchSwap(uint256 swapCost, uint256 myApe, uint256[] calldata swapApeTokenIds) public onlyOwner {
        uint256[] memory idsIn;
        uint256[] memory specificIds;

        idsIn[0] = myApe;

        for (uint i = 0; i < swapApeTokenIds.length; i++) {

            uint256 currApe = swapApeTokenIds[i];
            // bool claimed = LAND.alphaClaimed(currApe);
            bool claimed = false; //remove this!!

            if (!claimed) {

                specificIds[0] = swapApeTokenIds[i];

                NFTX.buyAndSwap721{value: swapCost}(
                    vaultId, 
                    idsIn, 
                    specificIds, 
                    path,
                    address(this)
                );

                //Since land is safe minted recieved
                // claimLand(swapApeTokenIds[i]);

                idsIn[0] = swapApeTokenIds[i];

            }

        }


        
        //retrieve original back
        idsIn[0] = myApe;
        NFTX.buyAndSwap721{value: swapCost}(
                vaultId, 
                specificIds, 
                idsIn, 
                path,
                address(this)
        );

        //revert if can't get original back
        if (INFT(apeAddress).ownerOf(myApe) != address(this)) {
            revert("Ape lost!");
        }

    }

    //transfer nfts
    function transferAll(address account, uint256[] calldata apeTokenIds, uint256[] calldata landTokenIds) public onlyOwner {
        for (uint i = 0; i < apeTokenIds.length; i++) {
            INFT(apeAddress).safeTransferFrom(address(this), account, apeTokenIds[i], "");
        }
        for (uint i = 0; i < landTokenIds.length; i++) {
            INFT(landAddress).safeTransferFrom(address(this), account, landTokenIds[i], "");
        }
    }

    //withdraw remaining eth balance
    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "No balance to withdraw");
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Withdraw transfer failiure");
    }

    //enable being safe minted to
    function onERC721Received(address, address from, uint256, bytes calldata) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    //make contract payable to receive funds
    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

}