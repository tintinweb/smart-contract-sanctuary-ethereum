// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

interface ERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);
}

contract BlindAngelClaim {
    ERC20 public token;
    ERC721 public nft;

    event Claim(address from, uint256 amount);
    event Transfer(address createdBy, address dealedBy, address to, uint256 value, bool status);

    struct RequestStruct {
        bool isActive;
        bool isClosed;
        bool isSent;
        address createdBy;
        address dealedBy;
        address to;
        uint256 value;
        uint256 created_at;
    }
    
    struct ClaimStruct {
        address account;
        uint256 balance;
    }

    struct Claimable {
        bool able;
        uint256 balance;
    }

    RequestStruct public transferRequest;
    address[] public claimList;
    
    mapping(address => bool) public owners;
    mapping(address => Claimable) public reward;

    uint256 public unClaimedBalance;
    uint256 public amountOnClaim = 500 ether;

    bool public outStanding;

    modifier onlySigners() {
        require(owners[msg.sender]);
        _;
    }

    modifier onlyNFTOwner() {
        require(nft.balanceOf(msg.sender) > 0);
        _;
    }

    function setTokenAddress(address tokenAddress) private onlySigners {
        token = ERC20(tokenAddress);
    }

    constructor(
        address[] memory _owners,
        address tokenAddress,
        address _nft
    ) {
        require(_owners.length == 3, "Owners are not 3 addresses" );
        for (uint i = 0; i < _owners.length; i ++) owners[_owners[i]] = true;
        setTokenAddress(tokenAddress);
        nft = ERC721(_nft);
    }

    // start transfer part
    function newTransferRequest(address to, uint256 value) public onlySigners {
        transferRequest = RequestStruct({
            to: to,
            value: value,
            isClosed: false,
            isSent: false,
            isActive: true,
            createdBy: msg.sender,
            dealedBy: msg.sender,
            created_at: block.timestamp
        });
        
    }
            
    function declineTransferRequest() public onlySigners {
        require(transferRequest.isActive);
        closeTransferRequest(false);
    }

    function approveTransferRequest() public onlySigners {
        require(transferRequest.isActive);
        require(transferRequest.createdBy != msg.sender, "can't approve transaction you created");
        
        token.transfer(transferRequest.to, transferRequest.value);
        // transferedAmount += transferRequest.value;
        closeTransferRequest(true);
    }
    
    function closeTransferRequest(bool status) private onlySigners {
        transferRequest.dealedBy = msg.sender;
        transferRequest.isActive = false;
        transferRequest.isClosed = true;
        transferRequest.isSent = status;

        emit Transfer(transferRequest.createdBy, msg.sender, transferRequest.to, transferRequest.value, status);
    }
    // end transfer part
        
    function getClaimList() public onlySigners view returns(address[] memory list) {
        return claimList;
    }

    function claim() external onlyNFTOwner {
        require(reward[msg.sender].able, "account is not able to claim");
        require(reward[msg.sender].balance > 0, "no balance left");

        uint256 amount = amountOnClaim;
        if (reward[msg.sender].balance < amountOnClaim) {
            amount = reward[msg.sender].balance;
            reward[msg.sender].balance = 0;
        }

        else {
            reward[msg.sender].balance -= amountOnClaim;
        }

        unClaimedBalance -= amount;
        token.transfer(msg.sender, amount);
        emit Claim(msg.sender, amount);

    }

    function updateClaimList(ClaimStruct[] memory list) external onlySigners {
        uint256 restBalance = unClaimedBalance;
        for (uint i; i < claimList.length; i ++) {
            reward[claimList[i]].able = false;
        }
        
        delete claimList;
        for (uint i; i < list.length; i ++) {
            ClaimStruct memory claimItem = list[i];
            claimList[i] = claimItem.account;
            if (!reward[claimItem.account].able) reward[claimItem.account].able = true;
            reward[claimItem.account].balance += claimItem.balance;
            restBalance += claimItem.balance;
        }

        unClaimedBalance = restBalance;
    }

}