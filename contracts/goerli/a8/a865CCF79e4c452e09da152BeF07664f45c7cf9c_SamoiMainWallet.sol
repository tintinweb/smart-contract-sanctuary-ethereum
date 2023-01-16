// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

struct VerifyInfo {
    uint256 method;
    address target;
    address user;   
    uint256 tokenId;
    uint256 id;
    uint256 value;
}

struct TransactionInfo {
    uint method;
    address target;
    address to;
    uint tokenId;
    uint id;
    uint value;
}

interface IUserWalletFactory {
    function createUserWallet(uint256 amount) external returns (address[] memory);
}

interface IUserWallet {
    function transfer(TransactionInfo memory transactionInfo) external;
}

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);
}

interface IERC1155 {
    function balanceOf(address account, uint256 id) external view returns (uint256);
}

contract SamoiMainWallet {
    error CallerIsNotOwner();
    error OutOfAmount();
    event UserWalletAddress(address[]);

    address public owner;

    IUserWalletFactory public userWalletFactory;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert CallerIsNotOwner();
        }
        _;
    }
    
    function setUserWalletFactory(address _userWalletFactory) external onlyOwner {
        userWalletFactory = IUserWalletFactory(_userWalletFactory);
    }

    function createWallet(uint256 amount) 
        external 
        onlyOwner 
        returns (address[] memory) 
    {
        if (amount > 20) {
            revert OutOfAmount();
        }

        address[] memory addr = new address[](amount);
        addr = userWalletFactory.createUserWallet(amount);
        
        emit UserWalletAddress(addr);

        return addr;
    }

    function transfer(
        address walletAddress,
        TransactionInfo memory transactionInfo
    ) external onlyOwner {
        IUserWallet(walletAddress).transfer(transactionInfo);
    }

    function verifyUser(VerifyInfo memory verifyInfo) external view returns (bool) {
        if (verifyInfo.method == 0) {
            return 
                IERC721(verifyInfo.target).ownerOf(verifyInfo.tokenId) == 
                verifyInfo.user;
        }

        if (verifyInfo.method == 1) {
            return 
                IERC1155(verifyInfo.target).balanceOf(verifyInfo.user, verifyInfo.id) >= 
                verifyInfo.value;
        }
        return false;                                               
    }
}