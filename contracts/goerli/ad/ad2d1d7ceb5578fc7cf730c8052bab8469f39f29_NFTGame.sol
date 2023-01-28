/**
 *Submitted for verification at Etherscan.io on 2023-01-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);

    function transfer(address to, uint amount) external returns (bool);

    function transferFrom(address from, address to, uint amount) external returns (bool);

    function approve (address spender, uint amount) external returns (bool);

    event Transfer(address from, address to, uint amount);

    event Approval(address owner, address spender, uint amount);

}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 {
    function balanceOf(address owner) external view returns (uint);

    function ownerOf(uint tokenId) external view returns (address);

    function transferFrom(address from, address to, uint tokenId) external;

    function safeTransferFrom(address from, address to, uint tokenId) external;

    function safeTransferFrom(
        address from, 
        address to, 
        uint tokenId, 
        bytes calldata data
    ) external;

    function approve(address to, uint tokenId) external;

    function getApproved(uint tokenId) external view returns (address);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface IERC721Receiver {
    function onERC721Received(
        address operator, 
        address from, 
        uint tokenId, 
        bytes calldata data
    ) external returns (bytes4);
}

contract ERC721 is IERC721 {
    event Transfer(
        address indexed from, 
        address indexed to,
        uint indexed tokenId
    );
    event Approval(
        address indexed owner, 
        address indexed spender, 
        uint indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner, 
        address indexed operator, 
        bool indexed approved
    );
        
    mapping(uint => address) internal _ownerOf;

    mapping(address => uint) internal _balanceOf;

    mapping(uint => address) internal _approvals;

    mapping(address => mapping (address => bool)) internal _isApprovedForAll;

    function supportsInterface(bytes4 interfaceId) 
        external 
        pure 
        returns (bool) 
    {
        return 
            interfaceId == type(IERC721).interfaceId || 
            interfaceId == type(IERC165).interfaceId;
    }

    function exists(uint tokenId) public view returns (bool) {
        return (_ownerOf[tokenId] != address(0)) ? true : false;
    }

    function ownerOf(uint tokenId) public view returns (address) {
        require(exists(tokenId), "token does not exist");
        return _ownerOf[tokenId];
    }

    function balanceOf(address owner) public view returns (uint) {
        require(owner != address(0), "zero address");
        return _balanceOf[owner];
    }

    function setApprovalForAll(address operator, bool approved) external {
        _isApprovedForAll[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) external view returns (bool) {
        return _isApprovedForAll[owner][operator];
    }

    function getApproved(uint tokenId) external view returns (address) {
        require(exists(tokenId), "token does not exist");
        return _approvals[tokenId];
    }

    function approve(address spender, uint tokenId) external {
        address owner = _ownerOf[tokenId];
        require(
            owner == msg.sender || _isApprovedForAll[owner][msg.sender], 
            "not authorized"
        );

        _approvals[tokenId] = spender;

        emit Approval(owner, spender, tokenId);
    }

    function transferFrom(
        address from, 
        address to, 
        uint tokenId
    ) public {
        address owner = _ownerOf[tokenId];

        require(to != address(0), "cannot transfer to 0 address");
        require(from == owner, "from != owner");
        require(_isApprovedForAll[owner][msg.sender], "Not approved");

        _balanceOf[from]--;
        _balanceOf[to]++;

        _ownerOf[tokenId] = to;
        delete _approvals[tokenId];
       
        emit Transfer(from, to, tokenId);
    }
    
    function safeTransferFrom(
        address from,
        address to,
        uint tokenId
    ) external {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from, 
        address to, 
        uint tokenId,
        bytes memory data
    ) public {
        require(
            to.code.length == 0 ||
            IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) ==
            IERC721Receiver.onERC721Received.selector, "unsafe"
        );
        
        transferFrom(from, to, tokenId);
    }

    function _mint(address to, uint tokenId) internal {
        require(!exists(tokenId), "token must be not exist");
        require(to != address(0), "to can not be zero address");

        _ownerOf[tokenId] = to;
        _balanceOf[to]++;

        emit Transfer(address(0), to, tokenId);
    }

    function burn(uint tokenId) external {
        address owner = _ownerOf[tokenId];
        
        require(exists(tokenId), "token does not exist");
        require(owner == msg.sender, "unauthorized");

        delete _ownerOf[tokenId];
        delete _approvals[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }
}

contract NFTGame is ERC721 {

    uint public constant price = 0.0001 ether;
    uint private index;
    uint private totalSupply = 100;
    IERC20 public weth = IERC20(0xEFfcB985BD5EC737017Cd188EB110DE1C7dFdC6e);
    string private uri;

    function buy(uint amount) public payable {
        uint requiredMoney = amount * price;

        require(msg.value >= requiredMoney, "did not pay enough");
        require(index + amount < totalSupply, "exceed totalSupply");
        
        payable(msg.sender).transfer(msg.value - requiredMoney);

        for (uint i; i < amount;) {
            _mint(msg.sender, index);
            index++;
            unchecked {
                ++i;
            }
        }

    }

    function wethBuy(uint amount) public {
        uint requiredMoney = amount * price;

        require(index + amount < totalSupply, "exceed totalSupply");


        bool succeed = weth.transferFrom(msg.sender, address(this), requiredMoney);
        require(succeed, "fail");

        for (uint i; i < amount;) {
            _mint(msg.sender, index);
            index++;
            unchecked {
                ++i;
            }
        }

    }

    function setTokenURI(string calldata _uri) external {
        uri = _uri;
    }

    function tokenURI(uint tokenId) public view returns (string memory) {
        return uri;
    }

}