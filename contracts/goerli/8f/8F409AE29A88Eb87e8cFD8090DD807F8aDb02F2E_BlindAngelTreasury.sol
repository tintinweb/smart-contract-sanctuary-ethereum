// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract BlindAngelTreasury {
    event Transfer(address indexed createdBy, address indexed dealedBy, address to, uint256 value);

    struct RequestStruct {
        bool isActive;
        address createdBy;
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
    
    constructor(
        address[] memory _owners
    ) {
        require(_owners.length == 3, "Owners are not 3 addresses" );
        for (uint i = 0; i < _owners.length; i ++) owners[_owners[i]] = true;
    }

    // start transfer part
    function newTransferRequest(address to, uint256 value) public onlySigners {
        transferRequest = RequestStruct({
            to: to,
            value: value,
            isActive: true,
            createdBy: msg.sender,
            created_at: block.timestamp
        });
        
    }
    
    function declineTransferRequest() public onlySigners {
        require(transferRequest.isActive);
        
        transferRequest.isActive = false;
    }

    function approveTransferRequest() public onlySigners {
        require(transferRequest.isActive);
        require(transferRequest.createdBy != msg.sender, "can't approve transaction you created");
        
        (bool sent, ) = payable(transferRequest.to).call{value: transferRequest.value}("");

        require(sent, "Failure! Not withdraw");

        transferRequest.isActive = false;
        emit Transfer(transferRequest.createdBy, msg.sender, transferRequest.to, transferRequest.value);
    }
    
    // end transfer part
    receive() external payable {}
    
}