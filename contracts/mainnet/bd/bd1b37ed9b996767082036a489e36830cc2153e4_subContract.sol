/**
 *Submitted for verification at Etherscan.io on 2022-09-08
*/

// SPDX-License-Identifier: MIT

// https://github.com/jungleninja/contract-minter

pragma solidity ^0.8.13;

interface IERC721 {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function balanceOf(address owner) external view returns (uint256 balance);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
}

contract subContract{
    address public deployer;
    address public mainContract;
    bool public isInitialized;

    modifier onlyDeployer() {
        require(tx.origin == deployer && msg.sender == mainContract, "only deployer");
        _;
    }

    function initializeC() external {
        require(!isInitialized, "already initialized");
        deployer = tx.origin;
        mainContract = msg.sender;
        isInitialized = true;
    }

    function callData(address _addr, bytes calldata _data) external payable onlyDeployer returns (bytes memory) {
        (bool success, bytes memory result) = _addr.call{value: msg.value}(_data);
        require(success, "call failed");
        return result;
    }

    function transferAllto(address _addr, address _to) external onlyDeployer {
        uint256 balance = IERC721(_addr).balanceOf(address(this));
        while(balance > 0){
            IERC721(_addr).safeTransferFrom(address(this), _to, IERC721(_addr).tokenOfOwnerByIndex(address(this), 0));
            balance--;
        }
    }

    function transferAlltoV2(address _addr, address _to, uint256[] memory _tokenIds) external onlyDeployer {
        for(uint256 i = 0; i < _tokenIds.length; i++){
            IERC721(_addr).safeTransferFrom(address(this), _to, _tokenIds[i]);
        }
    }

    function withdrawETH() external onlyDeployer {
        payable(deployer).transfer(address(this).balance);
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data) external returns (bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function onERC1155BatchReceived(address operator, address from, uint256[] calldata ids, uint256[] calldata values, bytes calldata data) external returns (bytes4) {
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }
}