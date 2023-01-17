// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

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
}

contract UserWallet {
    error CallerIsNotSamoi();
    error InvalidProtocol();

    struct TransactionInfo {
        uint256 protocol;
        address target;
        address to;
        uint256 tokenId;
        uint256 id;
        uint256 value;
    }

    address private constant samoiMainWallet = 0x1aa8DFb2127D530c7d0DA519E227F9Ad2C8EA321; 
    
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

    function transfer(TransactionInfo calldata transactionInfo) external {
        if (msg.sender != samoiMainWallet) {
            revert CallerIsNotSamoi();
        }

        if (transactionInfo.protocol == 721) {
            IERC721(transactionInfo.target).safeTransferFrom(
                address(this),
                transactionInfo.to,
                transactionInfo.tokenId
            );
        } else if (transactionInfo.protocol == 1155) {
            IERC1155(transactionInfo.target).safeTransferFrom(
                address(this),
                transactionInfo.to,
                transactionInfo.id,
                transactionInfo.value,
                ""
            );           
        } else {
            revert InvalidProtocol();
        }
    }
}