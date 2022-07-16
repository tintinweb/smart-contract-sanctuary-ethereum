// SPDX-License-Identifier: MIT 
// @author: @TigerWorldsTeam
// Purpose: Tiger Rader is a swiss army knife for integrations & querying of external NFTs and Tokens by polyfilling existing contracts
// Reduces EVM node calls e.g to Infura/Moralis to speed up front & backend functions & lower on-going costs
// Feel free to use this contract for any of your own project's purposes #OpenRoar!
pragma solidity ^0.8.11;


//Interfaces are present here for reference

//-------ERC721/ERC721A:
interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function balanceOf(address owner) external view returns (uint256 balance);
}

//-------ERC721/ERC721A Enumerable:
interface IERC721Enum {
    function totalSupply() external view returns (uint256);
    function tokensOfOwner(address owner) external view returns (uint256[] memory);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}

//-------ERC721A Queryable:
interface ERC721AQueryable {
    function tokensOfOwnerIn(address owner,  uint256 start, uint256 stop) external view returns (uint256[] memory);
}

//-------ERC20:
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
}

//-------ERC1155:
interface IERC1155 {
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);
}

//REMINDER: Functions are not designed to be called on-chain and that if done so they may cost huge amounts of gas!
contract TigerRadar {

    //Detects presence of total supply function
    function detectTotalSupplyFunction(address contractAddress) public view returns (bool) {
        (bool success, bytes memory returnData) = contractAddress.staticcall(abi.encodeWithSelector(IERC721Enum.totalSupply.selector));
        return success;
    }

    //Detects start of collection index 
    function detectStartIndex(address contractAddress) public view returns (uint256) {
        bool success = false;
        uint tokenId = 0;
        while (!success) {
            require(tokenId <= 1000, "Could not find start!");
            (bool _success, bytes memory returnData) = contractAddress.staticcall(abi.encodeWithSelector(IERC721.ownerOf.selector, tokenId));
            success = _success;
            tokenId += 1;
        }
        return tokenId -1;
    }

    //Iterates through common sizes to find size of collections that are not enumerable, not necessarily accurate
    function detectEndIndex(address contractAddress) public view returns (uint256 found) {
        uint[8] memory vals = [100000, 50000, 20000, 10000, 5000, 2500, 1000, uint(100)];
        bool success1 = false;
        found = detectStartIndex(contractAddress);
        for (uint i = 0; (i < vals.length) && (!success1); ++i) {
            (bool _success1,) = contractAddress.staticcall(abi.encodeWithSelector(IERC721.ownerOf.selector, vals[i] + found - 1));
            success1 = _success1;
            if (success1) {
                found = vals[i] + found - 1;
            }
        }
        bool success2 = true;
        while (success2) {
            found += 1;
            (bool _success2,) = contractAddress.staticcall(abi.encodeWithSelector(IERC721.ownerOf.selector, uint256(found)));
            success2 = _success2;
        }
        found -= 1;
    }

    //Detection functions assume linear ascending IDs suitable for most collections
    function detectTotalSupply(address contractAddress) public view returns (uint256) {
        return detectEndIndex(contractAddress) - detectStartIndex(contractAddress);
    }

    //Returns array of tokenOwners inclusive of both start and end index
    function arrayOfOwnersIndexed(address contractAddress, uint startIndex, uint endIndex) public view returns (address[] memory ownerAddresses) {
        require(endIndex >= startIndex, "End Index must be larger than Start Index!");
        uint count = endIndex - startIndex + 1;
        ownerAddresses = new address[](count);
        uint index = 0;
        for (uint i = startIndex; i < endIndex + 1; ++i) {
            ownerAddresses[index] = IERC721(contractAddress).ownerOf(i);
            index += 1;
        }
    }

    //Returns array of tokenOwners by attempting to autodetect start and stop 
    function arrayOfOwnersAuto(address contractAddress) public view returns (address[] memory ownerAddresses) {
        uint startIndex = detectStartIndex(contractAddress);
        uint endIndex = detectEndIndex(contractAddress);
        require(endIndex >= startIndex, "End Index must be larger than Start Index!");
        uint count = endIndex - startIndex + 1;
        ownerAddresses = new address[](count);
        uint index = 0;
        for (uint i = startIndex; i < endIndex + 1; ++i) {
            ownerAddresses[index] = IERC721(contractAddress).ownerOf(i);
            index += 1;
        }
    }

    //Returns an array of token IDs owned by `tokenOwner` inclusive of both start and end index
    function tokensOfOwnerIndexed(address contractAddress, address tokenOwner, uint startIndex, uint endIndex) public view returns (uint[] memory tokens) {
        uint balance = IERC721(contractAddress).balanceOf(tokenOwner);
        address[] memory allTokens = arrayOfOwnersIndexed(contractAddress, startIndex, endIndex);
        tokens = new uint[](balance);
        uint index = 0;
        for (uint i = 0; (i < (allTokens.length + 1)) && (index != balance); ++i) {
            if (allTokens[i] == tokenOwner) {
                tokens[index] = i + startIndex;
                index += 1;
            }
        }
    } 

    //Returns an array of token IDs owned by `tokenOwner` by attempting to autodetect start and stop
    function tokensOfOwnerAuto(address contractAddress, address tokenOwner) public view returns (uint[] memory tokens) {
        uint balance = IERC721(contractAddress).balanceOf(tokenOwner);
        uint startIndex = detectStartIndex(contractAddress);
        address[] memory allTokens = arrayOfOwnersAuto(contractAddress);
        tokens = new uint[](balance);
        uint index = 0;
        for (uint i = 0; (i < (allTokens.length + 1)) && (index != balance); ++i) {
            if (allTokens[i] == tokenOwner) {
                tokens[index] = i + startIndex;
                index += 1;
            }
        }
    } 

}