/**
 *Submitted for verification at Etherscan.io on 2022-10-07
*/

pragma solidity ^0.8.0;

// ----------------------------------------------------------------------------
// ERC-721 Helper v0.9.4
//
// https://github.com/bokkypoobah/TokenToolz
//
// Deployed to Mainnet 0xe160152d8721784377f65E26d9bdc02edED7798e
//
// SPDX-License-Identifier: MIT
//
// Enjoy.
//
// (c) BokkyPooBah / Bok Consulting Pty Ltd 2022. The MIT Licence.
// ----------------------------------------------------------------------------

interface ERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

interface ERC20 {
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function decimals() external view returns (uint8);
}

interface ERC721 is ERC165 {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) external payable;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function approve(address _approved, uint256 _tokenId) external payable;
    function setApprovalForAll(address _operator, bool _approved) external;
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

interface ERC721Metadata is ERC721 {
    function name() external view returns (string memory _name);
    function symbol() external view returns (string memory _symbol);
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

interface ERC721Enumerable is ERC721 {
    function totalSupply() external view returns (uint256);
    function tokenByIndex(uint256 _index) external view returns (uint256);
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}


contract ERC721Helper {

    bytes4 private constant ERC721_INTERFACE = 0x80ac58cd;
    bytes4 private constant ERC721METADATA_INTERFACE = 0x5b5e139f;
    bytes4 private constant ERC721ENUMERABLE_INTERFACE = 0x780e9d63;

    uint public constant ISEOA = 2**1;
    uint public constant ISCONTRACT = 2**2;
    uint public constant ISERC20 = 2**3;
    uint public constant ISERC721 = 2**4;
    uint public constant ISERC721METADATA = 2**5;
    uint public constant ISERC721ENUMERABLE = 2**6;


    function isERC721(address token) internal view returns (bool b) {
        try ERC165(token).supportsInterface(ERC721_INTERFACE) returns (bool _b) {
            b = _b;
        } catch {
        }
    }

    function isERC721Metadata(address token) internal view returns (bool b) {
        try ERC165(token).supportsInterface(ERC721METADATA_INTERFACE) returns (bool _b) {
            b = _b;
        } catch {
        }
    }

    function isERC721Enumerable(address token) internal view returns (bool b) {
        try ERC165(token).supportsInterface(ERC721ENUMERABLE_INTERFACE) returns (bool _b) {
            b = _b;
        } catch {
        }
    }

    function getERC721MetadataSymbol(address token) internal view returns (string memory _s) {
        try ERC721Metadata(token).symbol() returns (string memory s) {
            _s = s;
        } catch {
        }
    }

    function getERC721MetadataName(address token) internal view returns (string memory _n) {
        try ERC721Metadata(token).name() returns (string memory n) {
            _n = n;
        } catch {
        }
    }

    function getERC721EnumerableTotalSupply(address token) internal view returns (uint256 _ts) {
        try ERC721Enumerable(token).totalSupply() returns (uint256 ts) {
            _ts = ts;
        } catch {
        }
    }

    function isERC20(address token) internal view returns (bool b) {
        try ERC20(token).totalSupply() returns (uint _ts) {
            try ERC20(token).balanceOf(msg.sender) returns (uint _balanceOf) {
                b = true;
            } catch {
            }
        } catch {
        }
    }

    function getERC20Symbol(address token) internal view returns (string memory _s) {
        try ERC20(token).symbol() returns (string memory s) {
            _s = s;
        } catch {
        }
    }

    function getERC20Name(address token) internal view returns (string memory _n) {
        try ERC20(token).name() returns (string memory n) {
            _n = n;
        } catch {
        }
    }

    function getERC20TotalSupply(address token) internal view returns (uint256 _ts) {
        try ERC20(token).totalSupply() returns (uint256 ts) {
            _ts = ts;
        } catch {
        }
    }


    function tokenInfo(address[] memory tokens) external view returns(uint[] memory statuses, string[] memory symbols, string[] memory names, uint[] memory totalSupplys) {
        statuses = new uint[](tokens.length);
        symbols = new string[](tokens.length);
        names = new string[](tokens.length);
        totalSupplys = new uint[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            uint status = 0;
            if (token.code.length == 0) {
                status |= ISEOA;
            } else {
                status |= ISCONTRACT;
                if (isERC721(token)) {
                    status |= ISERC721;
                    if (isERC721Metadata(token)) {
                        status |= ISERC721METADATA;
                        symbols[i] = getERC721MetadataSymbol(token);
                        names[i] = getERC721MetadataName(token);
                    }
                    if (isERC721Enumerable(token)) {
                        status |= ISERC721ENUMERABLE;
                        totalSupplys[i] = getERC721EnumerableTotalSupply(token);
                    }
                } else if (isERC20(token)) {
                    status |= ISERC20;
                    symbols[i] = getERC20Symbol(token);
                    names[i] = getERC20Name(token);
                    totalSupplys[i] = getERC20TotalSupply(token);
                }

            }
            statuses[i] = status;
        }
    }

    function tokenURIsByTokenIds(address token, uint[] memory tokenIds) external view returns(bool[] memory successes, string[] memory tokenURIs) {
        tokenURIs = new string[](tokenIds.length);
        successes = new bool[](tokenIds.length);
        for (uint i = 0; i < tokenIds.length; i++) {
            try ERC721Metadata(token).tokenURI(tokenIds[i]) returns (string memory s) {
                tokenURIs[i] = s;
                successes[i] = true;
            } catch {
            }
        }
    }

    function ownersByTokenIds(address token, uint[] memory tokenIds) external view returns(bool[] memory successes, address[] memory owners) {
        owners = new address[](tokenIds.length);
        successes = new bool[](tokenIds.length);
        for (uint i = 0; i < tokenIds.length; i++) {
            try ERC721(token).ownerOf(tokenIds[i]) returns (address a) {
                owners[i] = a;
                successes[i] = true;
            } catch {
            }
        }
    }

    function tokenURIsByEnumerableIndex(address token, uint from, uint to) external view returns(uint[] memory tokenIds, string[] memory tokenURIs) {
        require(from < to);
        tokenIds = new uint[](to - from);
        tokenURIs = new string[](to - from);
        uint i = 0;
        for (uint index = from; index < to; index++) {
            try ERC721Enumerable(token).tokenByIndex(index) returns (uint256 tokenId) {
                tokenIds[i] = tokenId;
                try ERC721Metadata(token).tokenURI(tokenId) returns (string memory s) {
                    tokenURIs[i] = s;
                } catch {
                }
            } catch {
            }
            i++;
        }
    }

    function ownersByEnumerableIndex(address token, uint from, uint to) external view returns(uint[] memory tokenIds, address[] memory owners) {
        require(from < to);
        tokenIds = new uint[](to - from);
        owners = new address[](to - from);
        uint i = 0;
        for (uint index = from; index < to; index++) {
            try ERC721Enumerable(token).tokenByIndex(index) returns (uint256 tokenId) {
                tokenIds[i] = tokenId;
                try ERC721(token).ownerOf(tokenId) returns (address a) {
                    owners[i] = a;
                } catch {
                }
            } catch {
            }
            i++;
        }
    }

    function getERC20Info(ERC20[] memory tokens, address[] memory tokenOwners, address[] memory spenders) public view returns (uint[] memory balances, uint[] memory allowances) {
        require(tokens.length == tokenOwners.length && tokens.length == spenders.length);
        balances = new uint[](tokenOwners.length);
        allowances = new uint[](tokenOwners.length);
        for (uint i = 0; i < tokenOwners.length; i++) {
            try tokens[i].balanceOf(tokenOwners[i]) returns (uint b) {
                balances[i] = b;
            } catch {
            }
            try tokens[i].allowance(tokenOwners[i], spenders[i]) returns (uint a) {
                allowances[i] = a;
            } catch {
            }
        }
    }
}