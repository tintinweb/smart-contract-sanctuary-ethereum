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

    /**
     * @dev Returns the token IDs owned by `owner`.
     */
    function walletOfOwner(address _owner) external view returns (uint256[] memory);
}

contract KrakenlandersRoyalty  {
    uint256 public totalRoyalties; // Total royalties that have been received by the contract
    uint256 public totalPayouts;   // Total royalties that have been paid out to holders
    IERC721 public tokenContract;  // Contract of the token holders

    mapping(uint256 => uint256) private payouts; // Mapping of tokenId and the royalties that have been paid out to its holders
    mapping(uint256 => uint256) private reservedShares; // Mapping of tokenId and the permille of the total royalties that are being reserved for it

    constructor(address _tokenContract) {
        tokenContract = IERC721(_tokenContract);
    }

    receive() external payable {
        totalRoyalties = totalRoyalties + msg.value;
    }

    function funds() public view returns(uint256) {
        return fundsOfAddress(msg.sender);
    }

    // Returns the sum of the value of all tokens
    function fundsOfAddress(address _address) public view returns(uint256) {
        uint256 pending = 0;
        uint256[] memory tokens = tokenContract.walletOfOwner(_address);
        require(tokens.length > 0, 'This wallet does not have any tokens!');

        for (uint256 i = 0; i < tokens.length; i++) {
            pending+=fundsOfToken(tokens[i]);
        }
        
        return pending;
    }

    function fundsOfToken(uint256 _tokenId) public view returns(uint256) {
        uint256 totalSupply = tokenContract.totalSupply();        
        require(_tokenId <= totalSupply, 'Enter a valid tokenId!');
        return totalRoyalties / totalSupply - payouts[_tokenId];
    }

    function payOut() public {
        payOutForAddress(msg.sender);
    }

    function payOutForAddress(address _address) public{
        uint256 payoutAmount = 0;        
        uint256[] memory tokens = tokenContract.walletOfOwner(_address);

        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 tokenId = tokens[i];
            uint256 payout = fundsOfToken(tokenId);
            if (payout > 0) {
                payouts[tokenId] += payout;
                payoutAmount+=payout;
            }
        }        

        require(payoutAmount > 0, 'There is nothing to withdraw!') ;

        totalPayouts+=payoutAmount;
        payable(_address).transfer(payoutAmount);
    }
}