// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "NFTcontract.sol";

contract Factory {
    event ContractDeployed(address owner, address clone);
    function genesis(
        address _collectAddress,
        string calldata _tokenName,
        string calldata _tokenSymbol,
        uint256 _maxPublicMint
    ) external returns (address) {
        NFTcontract newNFT = new NFTcontract(
            _collectAddress,
            _tokenName,
            _tokenSymbol,
            _maxPublicMint
        );
        emit ContractDeployed(msg.sender, address(newNFT));
        return address(newNFT);
    }
}