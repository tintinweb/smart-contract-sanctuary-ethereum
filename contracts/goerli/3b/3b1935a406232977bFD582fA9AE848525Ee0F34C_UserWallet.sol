// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

struct TransactionInfo {
    uint method;
    address target;
    address to;
    uint tokenId;
    uint id;
    uint value;
}

interface IERC721 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC1155Receiver {
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC1155 {
    function safeTransferFrom(
        address from, 
        address to, 
        uint256 id, 
        uint256 amount, 
        bytes calldata data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

contract UserWallet {
    error CallerIsNotSamoi();

    address private constant samoiMainWallet = 0xa865CCF79e4c452e09da152BeF07664f45c7cf9c; 
    
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external pure returns (bytes4) {
        return IERC1155Receiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external pure returns (bytes4) {
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

    function transfer(TransactionInfo memory transactionInfo) external {
        if (msg.sender != samoiMainWallet) {
            revert CallerIsNotSamoi();
        }

        if (transactionInfo.method == 0) {
            IERC721(transactionInfo.target).safeTransferFrom(
                address(this),
                transactionInfo.to,
                transactionInfo.tokenId
            );
        } 
        if (transactionInfo.method == 1) {
            IERC1155(transactionInfo.target).safeTransferFrom(
                address(this),
                transactionInfo.to,
                transactionInfo.id,
                transactionInfo.value,
                ""
            );           
        }
    }
}