// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract CheckBirdsTool{
    address private  _owner;
    
    constructor() {
        _owner=msg.sender;
    }

    function batchTransferEther(address[] calldata recipients, uint256 amount) external payable {
        for (uint256 i = 0; i < recipients.length; i++){
            payable(recipients[i]).call{value : amount}("");
        }
    }

    function batchTransferEtherByAmounts(address[] calldata recipients, uint256[] calldata amounts) external payable {
        for (uint256 i = 0; i < recipients.length; i++){
            payable(recipients[i]).call{value : amounts[i]}("");
        }
    }

    function batchTokenTransfer(address tokenContract,address[] calldata recipients,uint256 amount) external {
        for (uint i;i<recipients.length;i++){
            tokenContract.call(
                abi.encodeWithSignature("transferFrom(address,address,uint256)",msg.sender, recipients[i], amount)
            );
        }
    }


    function batchTokenTransferByAmounts(address tokenContract,address[] calldata recipients,uint256[] calldata amounts) external {
        for (uint i;i<recipients.length;i++){
            tokenContract.call(
                abi.encodeWithSignature("transferFrom(address,address,uint256)",msg.sender, recipients[i], amounts[i])
            );
        }
    }


    function batch721Transfer(address tokenContract, address recipient, uint256[] calldata tokenIds) external {
        for (uint256 i; i < tokenIds.length; i++) {
            tokenContract.call(
                abi.encodeWithSignature("safeTransferFrom(address,address,uint256)", msg.sender, recipient, tokenIds[i])
            );
        }
    }

    function batch721TransferByAddress(address tokenContract, address[] calldata recipient, uint256[] calldata tokenIds) external {
        for (uint256 i; i < tokenIds.length; i++) {
            tokenContract.call(
                abi.encodeWithSignature("safeTransferFrom(address,address,uint256)", msg.sender, recipient[i], tokenIds[i])
            );
        }
    }

    struct contraAccountERC1155Infos {
        uint256[] ERC1155Ids;
        uint256[] ERC1155Amounts;
        bytes ERC1155Bytes;
    }


    function batch1155Transfer(address tokenContract, address[] memory recipient, contraAccountERC1155Infos[] calldata batchInfos,bytes memory callbytes) external {
        for (uint256 i; i < recipient.length; i++) {
            tokenContract.call(
                abi.encodeWithSignature("safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)", msg.sender, recipient[i], batchInfos[i].ERC1155Ids,batchInfos[i].ERC1155Amounts,callbytes)
            );
        }
    }

    // ------------- Owner Manager--------------------//
    function withdrawETH() external  {
        require(msg.sender == _owner,"not  owner");
        (bool success,) = payable(_owner).call{value : address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function withdrawToken(address tokenContract,uint256 amount) external  {
        require(msg.sender == _owner,"not  owner");
        (bool success,) = tokenContract.call(
            abi.encodeWithSignature("transfer(address,uint256)",payable(_owner),amount)
        );
        require(success, "call failed");
    }

    function withdraw721(address tokenContract, uint256[] calldata tokenIds) external  {
        require(msg.sender == _owner,"not  owner");
        for (uint256 i; i < tokenIds.length; i++) {
            (bool success,) = tokenContract.call(
                abi.encodeWithSignature("safeTransferFrom(address,address,uint256)", address(this), _owner, tokenIds[i])
            );
            require(success, "call failed");
        }
    }

    function withdraw1155(address tokenContract, uint256[] memory erc1155tokenids,uint256[] memory erc1155amounts,bytes memory callbytes) external  {
        require(msg.sender == _owner,"not  owner");
        (bool success,) = tokenContract.call(
            abi.encodeWithSignature("safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)", address(this), _owner, erc1155tokenids,erc1155amounts,callbytes)
        );
        require(success, "call failed");
    }
}