/**
 *Submitted for verification at Etherscan.io on 2022-06-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


// contract ExampleToken {
//     function walletOfOwner(address _owner) public view returns(uint256[] memory) ;
// }
contract ExampleToken  {
    function walletOfOwner(address _owner) public view returns (uint256[] memory) {}
}

interface IERC721 {
     /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

       /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
}

contract Royalty  {
    uint256 public totalRoyalty; //Total Royalty that is in Contract
    IERC721 public nft; //ERC721 contract

    //Mapping from tokenId to withrawed royalty amount
    mapping(uint256 => uint256) private withrawedAmount;
    address nftAddr ;

    constructor(address nftContractAddr) {
        // nft = nftContractAddr;
        nftAddr = nftContractAddr;
        nft = IERC721(nftContractAddr) ;
    }

    receive() external payable {
        totalRoyalty = totalRoyalty + msg.value; //when the contract receives royalty, update total royalty
    }

    // function pendingAmount() public view returns(uint256) {
    //     uint256 pending = 0;
    //     for (uint256 i = 0; i < nft.balanceOf(msg.sender); i++) {
    //         uint256 tokenId = nft.tokenOfOwnerByIndex(msg.sender, i);
    //         uint256 totalSupply = nft.totalSupply();
    //         if (totalRoyalty / totalSupply > withrawedAmount[tokenId]) {
    //             pending = pending + totalRoyalty / totalSupply - withrawedAmount[tokenId];
    //         }
    //     }
    //     return pending;
    // }
    function pendingAmount() public view returns(uint256) {
        return pendingAmountForAddress(msg.sender);
    }

    function pendingAmountForAddress(address _address) public view returns(uint256) {
        uint256 pending = 0;
        uint256[] memory tokens = ExampleToken(nftAddr).walletOfOwner(_address);
        // uint256[] memory tokens = nft.walletOfOwner(_address);
        require(tokens.length > 0, 'This wallet does not have any tokens!');

        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 tokenId = tokens[i];
            uint256 totalSupply = nft.totalSupply();
            if (totalRoyalty / totalSupply > withrawedAmount[tokenId]) {
                pending = pending + totalRoyalty / totalSupply - withrawedAmount[tokenId];
            }
        }
        return pending;
    }
    function withdraw() public {
        uint256 tokenAmount = nft.balanceOf(msg.sender);
        require(tokenAmount > 0, 'token amount zero!') ;
        for (uint256 i = 0; i < tokenAmount; i++) {
            uint256 tokenId = nft.tokenOfOwnerByIndex(msg.sender, i);
            uint256 totalSupply = nft.totalSupply();
            if (totalRoyalty / totalSupply > withrawedAmount[tokenId]) {
                uint256 pending = totalRoyalty / totalSupply - withrawedAmount[tokenId];
                payable(msg.sender).transfer(pending);
                withrawedAmount[tokenId] = totalRoyalty / totalSupply;
            }
        }
    }
}