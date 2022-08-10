// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

contract BlindAngelTreasury {
    ERC20 public token;

    event Transfer(address indexed createdBy, address indexed dealedBy, address to, uint256 value, bool indexed status);

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

    RequestStruct public transferRequest;
    
    mapping(address => bool) public owners;

    modifier onlySigners() {
        require(owners[msg.sender]);
        _;
    }

    function setTokenAddress(address tokenAddress) private onlySigners {
        token = ERC20(tokenAddress);
    }

    constructor(
        address[] memory _owners,
        address tokenAddress
    ) {
        require(_owners.length == 3, "Owners are not 3 addresses" );
        for (uint i = 0; i < _owners.length; i ++) owners[_owners[i]] = true;
        setTokenAddress(tokenAddress);
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
    
}