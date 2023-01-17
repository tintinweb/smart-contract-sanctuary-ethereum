// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

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

interface IUserWallet {
    function transfer(TransactionInfo calldata transactionInfo) external;
}

interface IERC721 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    
    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);
}

interface IERC1155 {
    function balanceOf(address account, uint256 id) external view returns (uint256);

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

struct VerifyInfo {
    uint256 protocol;
    address target;
    address wallet;   
    uint256 tokenId;
    uint256 id;
    uint256 value;
}

struct TransactionInfo {
    uint256 protocol;
    address target;
    address to;
    uint256 tokenId;
    uint256 id;
    uint256 value;
}

contract SamoiMainWallet {
    error CallerIsNotSamoi();
    error InvalidProtocol();

    event UserWalletAddress(address[]);

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) {
            revert CallerIsNotSamoi();
        }
        _;
    }
    
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

    function transfer(
        address walletAddress,
        TransactionInfo calldata transactionInfo
    ) external onlyOwner {
        IUserWallet(walletAddress).transfer(transactionInfo);
    }

    function transfer(TransactionInfo calldata transactionInfo) public {
        if (msg.sender != address(this)) {
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

    function verify(VerifyInfo calldata verifyInfo) external view returns (bool) {
        if (verifyInfo.protocol == 721) {
            return 
                IERC721(verifyInfo.target).ownerOf(verifyInfo.tokenId) == 
                verifyInfo.wallet;
        } else if (verifyInfo.protocol == 1155) {
            return 
                IERC1155(verifyInfo.target).balanceOf(verifyInfo.wallet, verifyInfo.id) >= 
                verifyInfo.value;
        } else {
            return false;
        }
    }
}