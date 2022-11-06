/**
 *Submitted for verification at Etherscan.io on 2022-11-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface ERC721TokenReceiver {
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes memory _data) external returns(bytes4);
}

contract ERC721 {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    uint256 private totalSupply = 200;
    string private tokenName;
    string private tokenSymbol;
    mapping (address => uint256[]) private nftsOf;
    mapping (uint256 => string) internal tokenURIs;
    mapping (uint256 => address) private owners;
    mapping (address => uint256) private balances;
    mapping (uint256 => address) private tokenApprovals;
    mapping (address => mapping (address => bool)) private operatorApprovals;
    string private baseURI;

    constructor() {
        tokenName = "ERC721";
        tokenSymbol = "NFT";
        baseURI = "https://ipfs.io/ipfs/QmRecHKLztVGo7hJS69ACychf3i435AVDMnSmFu5FQ9MA7/";
    }

        modifier notNull(address addr) {
        require(addr != address(0), "Address null");
        _;
    }

    modifier onlyValidCall(uint256 _tokenId) {

        require(msg.sender == owners[_tokenId] || msg.sender == tokenApprovals[_tokenId] 
        || operatorApprovals[owners[_tokenId]][msg.sender], "Not owner/authorised/allowed");
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

    function balanceOf(address _owner) external view returns (uint256) {
        return balances[_owner];
    }

    function getNftsOf(address _owner) external view  returns (uint256[] memory) {
        return (nftsOf[_owner]);
    }

    function ownerOf(uint256 _tokenId) external view returns (address) {
        return owners[_tokenId];
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) public 
        notNull(_to) onlyValidCall(_tokenId) isTokenValid(_tokenId) onlyOwner(_tokenId, _from) {

        balances[_from] -= 1;
        balances[_to] += 1;
        owners[_tokenId] = _to;
        delete tokenApprovals[_tokenId];
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

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public {
        safeTransferFrom(_from,_to,_tokenId,"");
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public
        notNull(_to) onlyValidCall(_tokenId) isTokenValid(_tokenId) onlyOwner(_tokenId, _from) {

        balances[_from] -= 1;
        balances[_to] += 1;
        owners[_tokenId] = _to;
        delete tokenApprovals[_tokenId];

        emit Transfer(_from, _to, _tokenId);
    }

    function approve(address _approved, uint256 _tokenId) external notNull(_approved) isTokenValid(_tokenId) {
        require(msg.sender == owners[_tokenId] || operatorApprovals[owners[_tokenId]][msg.sender], "Not owner/authorised");
        tokenApprovals[_tokenId] = _approved;

        emit Approval(owners[_tokenId],_approved,_tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved) external notNull(_operator) {
        operatorApprovals[msg.sender][_operator] = _approved;

        emit ApprovalForAll(msg.sender,_operator,_approved);
    }

    function getApproved(uint256 _tokenId) external view isTokenValid(_tokenId) returns (address) {
        return (tokenApprovals[_tokenId]);
    }

    function isApprovedForAll(address _owner, address _operator) external 
        notNull(_owner) notNull(_operator) view returns (bool) {
        
        return (operatorApprovals[_owner][_operator]);
    }

    function name() external view returns (string memory) {
        return tokenName;
    }

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external view returns (string memory) {
        return tokenSymbol;
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

    function _setBaseURI(string memory _baseUri) public {
        baseURI = _baseUri;
    }

    function _setTokenURI(uint256 _tokenId) isTokenValid(_tokenId) internal {
        string memory uri = string(abi.encodePacked(baseURI, toString(_tokenId)));
        tokenURIs[_tokenId] = string(abi.encodePacked(uri, ".json"));
    }

    function tokenURI(uint256 _tokenId) external view isTokenValid(_tokenId) returns (string memory) {
        return tokenURIs[_tokenId];
    }

    function mint(address _to, uint256 _tokenId) public {
        owners[_tokenId] = _to;
        nftsOf[_to].push(_tokenId);
        balances[_to] += 1;
        _setTokenURI(_tokenId);
    }

}