// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Utils} from './Utils.sol';

import {ERC721} from './ERC721.sol';
import {ERC721Enumerable} from './ERC721Enumerable.sol';

contract SandpockPass is ERC721Enumerable {
    using Utils for *;

    uint private _currentIndex = 1;
    uint public constant MAX_SUPPLY = 3000;
    
    string public baseTokenURI;
    string public URISuffix;

    mapping(address => bool) private _refuseMint;
    
    constructor(
        string memory _baseTokenURI, 
        string memory _URISuffix
    ) ERC721("Sandpock Pass", "SP") {
        URISuffix = _URISuffix;
        baseTokenURI = _baseTokenURI;
    }
        
    modifier callerIsUser() {
        if (_msgSender() != tx.origin) {
            revert Declined();
        }
        _;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function isMinted(address account) external view returns (bool) {
        return _refuseMint[account];
    }

    function tokenURI(uint256 tokenId) 
        external 
        view 
        override 
        returns (string memory) 
    {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return 
            bytes(baseURI).length > 0 
            ? string(abi.encodePacked(baseURI, tokenId.toString(), URISuffix)) 
            : "";
    }

    function totalSupply() public view returns (uint256) {
        unchecked { 
            return _currentIndex - 1; 
        }
    }

    function mint() external callerIsUser {
        if (totalSupply() + 1 > MAX_SUPPLY) {
            revert Declined();
        }
        
        if (_refuseMint[_msgSender()]) {
            revert Declined();
        }
        _refuseMint[_msgSender()] = true;

        _mint(_msgSender(), _currentIndex);
        _currentIndex++;
    }

    function setTokenURI(string calldata _baseTokenURI) external onlyOwner {
        if (_baseTokenURI.isEmptyString()) {
            revert InvalidInput();
        }
        baseTokenURI = _baseTokenURI;
    }

    function setURISuffix(string calldata _URISuffix) external onlyOwner {
        URISuffix = _URISuffix;
    }
}