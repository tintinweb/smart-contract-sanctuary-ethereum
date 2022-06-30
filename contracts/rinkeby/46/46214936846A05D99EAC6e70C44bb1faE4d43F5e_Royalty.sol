/**
 *Submitted for verification at Etherscan.io on 2022-06-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

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

    function walletOfOwner(address _owner) external view returns (uint256[] memory);
}

contract Royalty  {
    uint256 public totalRoyalties; //Total Royalty that is in Contract
    uint256 public totalPayouts; //Total Royalty that has been paid out
    IERC721 public tokenContract; //ERC721 contract

    //Mapping of tokenId and its withdrawn royalty amount
    mapping(uint256 => uint256) private payouts;

    constructor(address _tokenContract) {
        tokenContract = IERC721(_tokenContract) ;
    }

    receive() external payable {
        totalRoyalties = totalRoyalties + msg.value; //when the contract receives royalty, update total royalty
    }

    function pendingAmount() public view returns(uint256) {
        return pendingAmountForAddress(msg.sender);
    }

    function pendingAmountForAddress(address _address) public view returns(uint256) {
        uint256 pending = 0;
        uint256[] memory tokens = tokenContract.walletOfOwner(_address);
        require(tokens.length > 0, 'This wallet does not have any tokens!');

        uint256 totalSupply = tokenContract.totalSupply();

        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 tokenId = tokens[i];
            if (totalRoyalties / totalSupply > payouts[tokenId]) {
                pending += totalRoyalties / totalSupply - payouts[tokenId];
            }
        }
        return pending;
    }

    // function pendingAmountForToken(uint256 _tokenID) public view returns(uint256) {
    //     require(_tokenID > 0 && _tokenID <= tokenContract.totalSupply(), 'Enter a valid tokenID!');
    //     return payouts[_tokenID];
    // }

    function withdraw() public {
        uint256 tokenAmount = tokenContract.balanceOf(msg.sender);
        require(tokenAmount > 0, 'token amount zero!') ;
        for (uint256 i = 0; i < tokenAmount; i++) {
            uint256 tokenId = tokenContract.tokenOfOwnerByIndex(msg.sender, i);
            uint256 totalSupply = tokenContract.totalSupply();
            if (totalRoyalties / totalSupply > payouts[tokenId]) {
                uint256 pending = totalRoyalties / totalSupply - payouts[tokenId];
                payable(msg.sender).transfer(pending);
                payouts[tokenId] = totalRoyalties / totalSupply;
            }
        }
    }

    function withdrawImproved() public {
        uint256 payoutAmount = pendingAmount();
        require(payoutAmount > 0, 'There is nothing to withdraw!') ;
        
        uint256[] memory tokens = tokenContract.walletOfOwner(msg.sender);

        uint256 totalSupply = tokenContract.totalSupply();
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 tokenId = tokens[i];
            if (totalRoyalties / totalSupply > payouts[tokenId]) {
                payouts[tokenId] += totalRoyalties / totalSupply;
            }
        }        

        totalPayouts+=payoutAmount;
        payable(msg.sender).transfer(payoutAmount);
    }
}