/**
 *Submitted for verification at Etherscan.io on 2022-09-01
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract ContractRegistry {

    struct ContractMetadata {
        string name;
        //0 -> staking
        //1 -> swapping
        //2 -> minting
        uint32[] tags;
        bytes customdata;
    }

    address private _owner;
    mapping(address => ContractMetadata) registry;

    modifier onlyOwner() {
        require(msg.sender == _owner, "caller is not owner");
        _;
    }

    constructor() {
        _owner = msg.sender;
    }

    function insert(address _contract, string calldata name, uint32[] calldata tags, bytes calldata custom) external onlyOwner {
        ContractMetadata memory contractMetadata = ContractMetadata(
            name,
            tags,
            custom
        );
        registry[_contract] = contractMetadata;
    }

    function updateName(address _contract, string calldata name) external onlyOwner {
        ContractMetadata storage metadata = registry[_contract];
        metadata.name = name;
    }

    function updateTags(address _contract, uint32[] calldata tags) external onlyOwner {
        ContractMetadata storage metadata = registry[_contract];
        metadata.tags = tags;
    }

    function updateCustom(address _contract, bytes calldata custom) external onlyOwner {
        ContractMetadata storage metadata = registry[_contract];
        metadata.customdata = custom;
    }

    function getContractMetadata(address _contract) public view returns (string memory, uint32[] memory, bytes memory) {
        ContractMetadata storage metadata = registry[_contract];
        return (metadata.name, metadata.tags, metadata.customdata);
    }

    function getContractName(address _contract) public view returns (string memory) {
        ContractMetadata storage metadata = registry[_contract];
        return metadata.name;
    }
}