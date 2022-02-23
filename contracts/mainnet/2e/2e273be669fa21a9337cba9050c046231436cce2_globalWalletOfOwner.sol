/**
 *Submitted for verification at Etherscan.io on 2022-02-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721 {
    function balanceOf(address address_) external view returns (uint256);
    function ownerOf(uint256 tokenId_) external view returns (address);
}

contract globalWalletOfOwner {
    function walletOfOwner(address contractAddress_, address wallet_, uint256 start_) 
    external view returns (uint256[] memory) {
        uint256[] memory _balance = new uint256[] (
            IERC721(contractAddress_).balanceOf(wallet_));
        uint256 _index;
        uint256 _iterateId = start_;
        bool _isOwnerOfZeroAtLastIndex;

        if (_balance.length > 0) {
            while (_balance[_balance.length - 1] == 0 
                && !_isOwnerOfZeroAtLastIndex 
                && _iterateId < 65536 // A limit of iterations to prevent out of gas error
                ){
                if (wallet_ == IERC721(contractAddress_).ownerOf(_iterateId)) {
                    
                    // Check if 0 is owned and at last index
                    if (_iterateId == 0 && _index == _balance.length - 1) {
                        _isOwnerOfZeroAtLastIndex = true;
                    }

                    _balance[_index] = _iterateId;
                    _index++;
                }
                _iterateId++;
            }
        }
        return _balance;
    }
}