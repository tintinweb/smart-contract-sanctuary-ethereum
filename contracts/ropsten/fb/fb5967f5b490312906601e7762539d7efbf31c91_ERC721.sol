/**
 *Submitted for verification at Etherscan.io on 2022-09-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface ERC721TokenReceiver {
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes memory _data) external returns(bytes4);
}

contract ERC721 {
    event Debug(uint _tokenId, address _addr);
    
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event Minted(address indexed _owner, uint256 indexed _tokenId);

    address creator;
    uint256 public totalTokens;
    mapping (address => uint256) internal balances;
    address[] public addrArray;
    mapping (uint256 => address) public owners;
    mapping (uint256 => address) internal allowance;
    mapping (address => mapping (address => bool)) internal authorised;

    modifier notNull(address addr) {
        require(addr != address(0), "Address null");
        _;
    }

    modifier onlyValidCall(uint256 _tokenId) {
        emit Debug(_tokenId, msg.sender);
        require(msg.sender == owners[_tokenId] || msg.sender == allowance[_tokenId] 
        || authorised[owners[_tokenId]][msg.sender], "Not owner/authorised/allowed");
        _;
    }

    modifier onlyOwner(uint256 _tokenId, address _from) {
        require(_from == owners[_tokenId], "from is not the current owner");
        _;
    }

    modifier isTokenValid(uint256 _tokenId) {
        require (owners[_tokenId] != address(0), "Invalid token");
        _;
    }

    constructor() {
        creator = msg.sender;
    }

    function getAddresses(uint256 i) public view returns (address) {
        return addrArray[i];
    }

    function getTotalSupply() public view returns (uint256) {
        return totalTokens;
    }
    
    function balanceOf(address _owner) external view notNull(_owner) returns (uint256) {
        return balances[_owner];
    }

    function ownerOf(uint256 _tokenId) external view isTokenValid(_tokenId) returns (address) {
        return owners[_tokenId];
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) public
        notNull(_to) onlyValidCall(_tokenId) isTokenValid(_tokenId) onlyOwner(_tokenId, _from) {

        balances[_from] -= 1;
        balances[_to] += 1;
        owners[_tokenId] = _to;
        delete allowance[_tokenId];
        uint32 size;
        assembly {
            size := extcodesize(_to)
        }
        if (size > 0) {
            ERC721TokenReceiver receiver = ERC721TokenReceiver(_to);
            require(receiver.onERC721Received(msg.sender,_from,_tokenId,data)
                == bytes4(keccak256("onERC721Received(address,address,uint256,bytes)")));
        }

        emit Transfer(_from, _to, _tokenId);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external {
        safeTransferFrom(_from,_to,_tokenId,"");
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) external 
        notNull(_to) onlyValidCall(_tokenId) isTokenValid(_tokenId) onlyOwner(_tokenId, _from) {

        balances[_from] -= 1;
        balances[_to] += 1;
        owners[_tokenId] = _to;
        delete allowance[_tokenId];

        emit Transfer(_from, _to, _tokenId);
    }

    function approve(address _approved, uint256 _tokenId) external notNull(_approved) isTokenValid(_tokenId) {
        require(msg.sender == owners[_tokenId] || authorised[owners[_tokenId]][msg.sender], "Not owner/authorised");
        allowance[_tokenId] = _approved;

        emit Approval(owners[_tokenId],_approved,_tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved) external notNull(_operator) {
        authorised[msg.sender][_operator] = _approved;

        emit ApprovalForAll(msg.sender,_operator,_approved);
    }

    function getApproved(uint256 _tokenId) external view isTokenValid(_tokenId) returns (address) {
        return (allowance[_tokenId]);
    }

    function isApprovedForAll(address _owner, address _operator) external 
        notNull(_owner) notNull(_operator) view returns (bool) {
        
        return (authorised[_owner][_operator]);
    }

    function mint(uint256 _tokenId) external {
        require (owners[_tokenId] == address(0), "Token already minted");
        balances[msg.sender] += 1;
        owners[_tokenId] = msg.sender;
        totalTokens += 1;
        addrArray.push(msg.sender);

        emit Minted(msg.sender,_tokenId);
    }

    function name() external pure returns (string memory) {
        return "MY ERC721";
    }

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external pure returns (string memory) {
        return "Test NFTs";
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function tokenURI(uint256 _tokenId) external view isTokenValid(_tokenId) returns (string memory) {
        string memory _baseURI = "mytoken.com/";
        return string(abi.encodePacked(_baseURI, toString(_tokenId)));
    }
}