/**
 *Submitted for verification at Etherscan.io on 2022-03-24
*/

/*
              ,ad8888ba,                88888888888             
             d8"'    `"8b               88                      
            d8'                         88                      
            88              ,adPPYba,   88aaaaa                 
            88      88888  a8"     "8a  88"""""                 
            Y8,        88  8b       d8  88                      
             Y8a.    .a88  "8a,   ,a8"  88                      
              `"Y88888P"    `"YbbdP"'   88888888888             
                                                                
                                                                
                                                                
88888888ba,                                                     
88      `"8b                                                    
88        `8b                                                   
88         88  8b,dPPYba,   ,adPPYba,   8b,dPPYba,   ,adPPYba,  
88         88  88P'   "Y8  a8"     "8a  88P'    "8a  I8[    ""  
88         8P  88          8b       d8  88       d8   `"Y8ba,   
88      .a8P   88          "8a,   ,a8"  88b,   ,a8"  aa    ]8I  
88888888Y"'    88           `"YbbdP"'   88`YbbdP"'   `"YbbdP"'  
                                        88                      
                                        88                      
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0;


interface IGoE721Genesis {
    function policyMint(address _to, uint256 _amount) external;
}

interface IGoE721 {
    function walletOfOwner(address wallet) external view returns(uint256[] memory);
    function balanceOf(address) external view returns(uint256);
    function transferFrom(address ,address ,uint256 ) external;
}

contract GoEDrops {
    uint256 _NFTprice = 0.15 ether;
    uint256 _NFTavailable = 40;
    address _dev;
    address _owner1 = 0xd928775286848A0624342252167c3FFc459bADed;
    address _owner2 = 0xe5c4e12A479ed9023088556366606F758B0de20D;
    address GOE_GENESIS = 0x586dAE24dd99ac8a240Cc475b052a9F737808073;
    bool _paused = true;


    function _isOwner(address _addr) internal view returns(bool){
        if((_addr == _owner1) || (_addr == _owner2)){
            return true;
        }
        return false;
    }

    modifier ownerAllowed() {
        require(_isOwner(msg.sender), "GoEGSupplement: Only owners can withdraw");
        _;
    }

    modifier keyAllowed() {
        require((msg.sender == _owner1) || (msg.sender == _owner2) || (msg.sender == _dev), "GoEGSupplement: Only keys can transfer");
        _;
    }

    constructor(){
        _dev = msg.sender;
    }


    function togglePaused() external keyAllowed {
        _paused = !_paused;
    }

    function changeAttr(address _nGG, uint256 _nPrice, uint256 _nAmount) external keyAllowed {
        GOE_GENESIS = _nGG;
        _NFTprice = _nPrice;
        _NFTavailable = _nAmount;
    }

    function secondaryMint(address _to) external payable {
        require(msg.value >= _NFTprice, "GoEGSupplement: Need to pay atleast 0.15 eth");
        require(IGoE721(GOE_GENESIS).balanceOf(msg.sender) > 0, "GoEGSupplement: Only Genesis NFT Holders can mint");
        if(!_isOwner(msg.sender)){
            require(!_paused, "GoEGSupplement: Supplementary minting is paused");
            require(_NFTavailable > 0, "GoEGSupplement: No more avaliable secondary mints");
            _NFTavailable -= 1;
        }
        IGoE721Genesis(GOE_GENESIS).policyMint(_to, 1);
    }


    function withdraw(address to, uint256 amount) external ownerAllowed {
        require(payable(to).send(amount));
    }
}