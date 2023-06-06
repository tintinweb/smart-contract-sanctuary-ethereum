// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NFT.sol";

contract NFTFactory {
    event LogCreatedNFT(address nft);

    mapping(bytes32 => address[]) internal _userContracts;

    constructor() {}

    function createContract(
        string memory token, 
        string memory name,
        string memory symbol,
        string memory initBaseURI,
        address platform,
        uint256 platformRoyalty,
        address payout,
        uint256 payoutRoyalty,
        uint256 tokensPerMint
    ) public returns (address) {
        NFT nft = new NFT(
            name,
            symbol,
            initBaseURI,
            platform,
            platformRoyalty,
            payout,
            payoutRoyalty,
            tokensPerMint,
            msg.sender
        );

        _userContracts[stringToBytes32(token)].push(address(nft));
        emit LogCreatedNFT(address(nft));
        return address(nft);
    }

    function getUserContracts(string memory token)
        public
        view
        returns (address[] memory)
    {
        return _userContracts[stringToBytes32(token)];
    }

    function stringToBytes32(string memory source)
        internal
        pure
        returns (bytes32 result)
    {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }
}