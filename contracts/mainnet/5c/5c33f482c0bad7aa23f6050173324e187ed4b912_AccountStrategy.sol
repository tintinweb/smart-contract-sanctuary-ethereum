/**
 *Submitted for verification at Etherscan.io on 2023-01-05
*/

/**
 *Submitted for verification at Etherscan.io on 2022-12-14
*/

/**
 *Submitted for verification at Etherscan.io on 2022-12-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom( address sender, address recipient,uint256 amount ) external returns (bool);
}

interface IERC721 {
    function totalSupply() external view returns (uint256);
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool _approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}

contract AccountStrategy {
 
    function sweepToken(address token) external {
        IERC20(token).transfer(payable(msg.sender), IERC20(token).balanceOf(address(this)));

    }

    

    function sweepTokenNFT(address token, uint256 startTokenId, uint256 endTokenId) external {
        uint256 _num;
        _num = endTokenId - startTokenId;
        for (uint256 i = 0; i <= _num; i++){
            if (_checkTokenId(token,startTokenId+i) == true){
                IERC721(token).transferFrom(address(this),payable(msg.sender), startTokenId+i);
            }        
        }  

    }


    function _getTotalSupplyNFT (address token) internal view returns (uint256)  {
        uint256 _totalSupply;
        _totalSupply = IERC721(token).totalSupply();
        return _totalSupply;
    }

    function _checkTokenId (address token, uint256 _tokenId) internal  view returns (bool sucess) {

        if (address(IERC721(token).ownerOf(_tokenId)) == address(this)) {

            sucess = true;

            return  sucess;
        }
        
    }


    function _getBalanceNFT (address token) internal view returns (uint256)  {
        uint256 _balance;
        _balance = IERC721(token).balanceOf(address(this));
        return _balance;
    } 

    function withdrawETH() external {
        payable(msg.sender).transfer(address(this).balance);
    }

}