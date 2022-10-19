// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface WPEInterFace {
    function ownerOf(uint256 tokenId) external view returns (address);
    function balanceOf(address owner) external view returns (uint256);
}

contract WPEToken {
    uint256 private constant max_WPE = 2999;
    WPEInterFace WPE_Contract;
    constructor(address WPE_Address) {
        WPE_Contract = WPEInterFace(WPE_Address);
    }

    function getEvolved(address address_) public view returns (uint256 [] memory) {
        uint256 balance = WPE_Contract.balanceOf(address_);
        uint256 cnt = 0;
        uint256 [] memory ownedtokens = new uint256 [](balance);
        for(uint256 i = 0; i < max_WPE && cnt < balance; i++){
           try WPE_Contract.ownerOf(i){
                if(WPE_Contract.ownerOf(i) == address_){
                    ownedtokens[cnt++] = i;
                }
            }
            catch {
                continue;
            }
        }
    return ownedtokens;
    }
}