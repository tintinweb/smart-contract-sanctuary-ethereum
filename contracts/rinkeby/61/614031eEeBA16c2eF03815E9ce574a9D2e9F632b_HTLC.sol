/**
 *Submitted for verification at Etherscan.io on 2022-09-19
*/

pragma solidity 0.8.17;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool _approved) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract HTLC {
    struct TokenInfo{
        address tokenAddress;
        uint256 tokenAmount;    
    }
    
    struct NFTInfo {
        address contractAddress;    
        uint256 tokenId;
    }

    uint256 public etherAmount; // for ether
    TokenInfo public tokenInfo; // for token
    NFTInfo public nftInfo; // for nft
    
    bool public locking = false;
    uint256 public lockUntil;
    bytes32 public hash;
    address public sender;
    address public reciever;
    

    function lockETH(uint256 _lockUntil, uint256 _etherAmount, address _reciever, bytes32 _hash) payable public {
        require(!locking); 
        require(msg.value == _etherAmount); 
        lockUntil = _lockUntil;
        etherAmount = _etherAmount;
        sender = msg.sender;
        reciever = _reciever;
        hash = _hash;
        locking = true;
    }
    
    function withdrawETH(bytes calldata r) public{
        require(locking); 
        require(keccak256(r) == hash);
        payable(reciever).transfer(etherAmount);
        locking = false;
    }
    
    function refundETH() public{
        require(locking); 
        require(block.timestamp > lockUntil);
        payable(sender).transfer(etherAmount);
        locking = false;
    }

    function lockToken(uint256 _lockUntil, TokenInfo calldata _tokenInfo, address _reciever, bytes32 _hash) public{
        require(!locking);
        IERC20(_tokenInfo.tokenAddress).transferFrom(msg.sender, address(this), _tokenInfo.tokenAmount);
        lockUntil = _lockUntil;
        tokenInfo = _tokenInfo;
        sender = msg.sender;
        reciever = _reciever;
        hash = _hash;
        locking = true;
    }
    
    function withdrawToken(bytes calldata r) public{
        require(locking);
        require(keccak256(r) == hash);
        IERC20(tokenInfo.tokenAddress).transfer(reciever, tokenInfo.tokenAmount);
        locking = false;
    }
    
    function refundToken() public{
        require(locking);
        require(block.timestamp > lockUntil);
        IERC20(tokenInfo.tokenAddress).transfer(sender, tokenInfo.tokenAmount);
        locking = false;
    }

    
    function lockNFT(uint256 _lockUntil, NFTInfo calldata _nftInfo, address _reciever, bytes32 _hash) payable public {
        require(!locking);
        IERC721(_nftInfo.contractAddress).transferFrom(msg.sender, address(this), _nftInfo.tokenId);
        lockUntil = _lockUntil;
        nftInfo = _nftInfo;
        sender = msg.sender;
        reciever = _reciever;
        hash = _hash;
        locking = true;
    }
    
    function withdrawNFT(bytes calldata r) public{
        require(locking);
        require(keccak256(r) == hash);
        IERC721(nftInfo.contractAddress).transferFrom(address(this), reciever, nftInfo.tokenId);
        locking = false;
    }
    
    function refundNFT() public{
        require(locking);
        require(block.timestamp > lockUntil);
        IERC721(nftInfo.contractAddress).transferFrom(address(this), sender, nftInfo.tokenId);
        locking = false;
    }
    
}