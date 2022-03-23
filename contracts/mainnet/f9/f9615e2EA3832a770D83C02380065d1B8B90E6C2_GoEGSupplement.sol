/**
 *Submitted for verification at Etherscan.io on 2022-03-22
*/

/*
                d888b        .d88b.       d88888b                                     
               88' Y8b      .8P  Y8.      88'                                         
               88           88    88      88ooooo                                     
               88  ooo      88    88      88~~~~~                                     
               88. ~8~      `8b  d8'      88.                                         
                Y888P        `Y88P'       Y88888P                                     
                                                                                      
                                                                                      
.d8888. db    db d8888b. d8888b. db      d88888b .88b  d88. d88888b d8b   db d888888b 
88'  YP 88    88 88  `8D 88  `8D 88      88'     88'YbdP`88 88'     888o  88 `~~88~~' 
`8bo.   88    88 88oodD' 88oodD' 88      88ooooo 88  88  88 88ooooo 88V8o 88    88    
  `Y8b. 88    88 88~~~   88~~~   88      88~~~~~ 88  88  88 88~~~~~ 88 V8o88    88    
db   8D 88b  d88 88      88      88booo. 88.     88  88  88 88.     88  V888    88    
`8888Y' ~Y8888P' 88      88      Y88888P Y88888P YP  YP  YP Y88888P VP   V8P    YP    
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0;


interface IGoE721 {
    function walletOfOwner(address wallet) external view returns(uint256[] memory);
    function balanceOf(address) external view returns(uint256);
    function transferFrom(address ,address ,uint256 ) external;
    
}

contract GoEGSupplement {
    uint256 _NFTprice = 0.15 ether;
    uint256 _NFTavailable;
    address _dev;
    address _owner1 = 0xd928775286848A0624342252167c3FFc459bADed;
    address _owner2 = 0xe5c4e12A479ed9023088556366606F758B0de20D;
    address GOE_GENESIS = 0x586dAE24dd99ac8a240Cc475b052a9F737808073;

    modifier ownerAllowed() {
        require((msg.sender == _owner1) || (msg.sender == _owner2), "GoEGSupplement: Only owners can withdraw");
        _;
    }

    modifier keyAllowed() {
        require((msg.sender == _owner1) || (msg.sender == _owner2) || (msg.sender == _dev), "GoEGSupplement: Only keys can transfer");
        _;
    }

    constructor(){
        _dev = msg.sender;
    }

    function _getSHTokenId() internal view returns(uint256, uint256){
        uint256[] memory _NFTIds = IGoE721(GOE_GENESIS).walletOfOwner(address(this));
        return (_NFTIds[0], _NFTIds.length);
    }

  
    function _shMint(address _to, uint256 tokenId) internal {
        IGoE721(GOE_GENESIS).transferFrom(address(this), _to, tokenId);
    }


    function shMint(address _to) public payable {
        require(msg.value >= _NFTprice, "GoEGSupplement: A payment of 0.15 eth is required");
        require(IGoE721(GOE_GENESIS).balanceOf(msg.sender) > 0, "GoEGSupplement: Only Holders are able to mint");
        (uint256 tokenId, uint256 tokensLeft) = _getSHTokenId();
        require(tokensLeft > 0, "GoEGSupplement: No more mints avaliable");
        _shMint(_to, tokenId);
    }


    function changeAttr(address _nGG, uint256 _nPrice) external keyAllowed {
        GOE_GENESIS = _nGG;
        _NFTprice = _nPrice;
    }

    function policyTransfer(address to, uint256 tokenId, bool cBalance) external keyAllowed {
        if(cBalance){
            uint256[] memory _NFTIds = IGoE721(GOE_GENESIS).walletOfOwner(address(this));
            for(uint256 i=0; i<_NFTIds.length; i++){
                _shMint(to, _NFTIds[i]);
            }
        }else{
            _shMint(to, tokenId);
        }
    }


    function withdraw(address to, uint256 amount) external ownerAllowed {
        require(payable(to).send(amount));
    }
}