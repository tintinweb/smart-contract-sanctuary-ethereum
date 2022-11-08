/**
 *Submitted for verification at Etherscan.io on 2022-11-07
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

error NoClaim();
error ClaimOver();
error AlreadyClaimed();

interface ERC721Transfer {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

interface IERC1155Balance {
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);
}

contract StarsClaim {

    address private immutable _owner;
    address private immutable _manager;

    ERC721Transfer immutable nftToken;
    IERC1155Balance immutable pitboss;

    uint256 private immutable startTokenId = 100;

    uint256 private _tokenId;

    mapping(address => bool) private claims;

    bool private claimActive = true;

    constructor(address manager) {
        _owner = msg.sender;
        _manager = manager;

        nftToken = ERC721Transfer(0x5E36F2C564b16697cd6354FD9CA19E707E923a1a);
        pitboss = IERC1155Balance(0x8E19Be131d16Afd9c00CfFF6A8a60B098E6ab24f);
    }

    function toogleSale() public  {
        require(msg.sender == _owner, "Only the owner can toggle the claim");
        claimActive = !claimActive;
    }

    function getAmountToClaim(address account)
        public
        view
        returns (uint256 amount)
    {
        if (_tokenId > 3000){
            revert ClaimOver();
        }

        if (claims[account] == true) {
            revert AlreadyClaimed();
        }
        
        amount = pitboss.balanceOf(account, 0);

        return amount;
    }

    function claim() public {
        if (claimActive == false){
            revert ClaimOver();
        }
        
        if (_tokenId > 3000){
            revert ClaimOver();
        }

        address account = msg.sender;

        uint256 amount = pitboss.balanceOf(account, 0);

        if (amount == 0) {
            revert NoClaim();
        }

        if (claims[account] == true) {
            revert AlreadyClaimed();
        }

        for (uint256 i = 0; i < amount; ) {
            nftToken.safeTransferFrom(_manager, account, startTokenId + _tokenId);
            
            unchecked {
                ++i;
                ++_tokenId;
            }  
        }

        claims[account] = true;
    }
}