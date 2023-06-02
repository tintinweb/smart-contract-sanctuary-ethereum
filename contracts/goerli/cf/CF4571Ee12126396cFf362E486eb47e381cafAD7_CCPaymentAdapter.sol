// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface ICre8orsCollective {
    function purchase(
        address _targetContract,
        bytes calldata _data
    ) external payable returns (uint256);

    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract CCPaymentAdapter {
    ICre8orsCollective public deployedContract;
    address public deployedContractAddress;

    constructor(address _deployedContractAddress) {
        deployedContractAddress = _deployedContractAddress;
        deployedContract = ICre8orsCollective(_deployedContractAddress);
    }

    function purchase(
        address _targetContract,
        address _to,
        bytes calldata _data
    ) external payable returns (uint256) {
        uint256 tokenId = deployedContract.purchase{value: msg.value}(
            _targetContract,
            _data
        );
        deployedContract.transferFrom(address(this), _to, tokenId);

        return tokenId;
    }
}