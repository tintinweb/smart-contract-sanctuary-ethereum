// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// import "hardhat/console.sol";

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    function totalSupply() external view returns(uint256);

    function balanceOf(address account) external view returns(uint256);

    function transfer(address to, uint256 amount) external returns(bool);

    function allownace(address owner, address spender) external view returns(uint256);

    function approve(address spender, uint256 amount) external returns(bool);

    function transferFrom(address from, address to, uint256 amount) external returns(bool);
}

contract NonFungibleToken {
    
    address public owner;
    string public name;
    string public symbol;
    uint256 public totalSupply; // totalSupply is also tokenId

    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    mapping(address => uint256) private balances;
    mapping(uint256 => address) private ownerOfNft;
    mapping(address => mapping(address => mapping(uint256 => bool))) private allowances;

    struct Metadata {
        string description;
        string name;
        string imageURL;
    }

    Metadata[] public metadatas;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        totalSupply = 0;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function balanceOf(address _owner) public view returns(uint256) {
        return balances[_owner];
    }

    function ownerOf(uint256 _tokenId) external view returns(address) {
        return ownerOfNft[_tokenId];
    }   

    function allowance(address _owner, address _approved, uint256 _tokenId) public view returns(bool) {
        return allowances[_owner][_approved][_tokenId];
    }

    function tokenURI(uint256 _tokenId) external view returns(Metadata memory) {
        return metadatas[_tokenId];
    }

    function mint(string memory _imageURL) external payable {
        require(msg.value == 0.001 ether, "NFT price is 0.001 ether!");
        ownerOfNft[totalSupply] = msg.sender;
        balances[msg.sender] += 1;
        metadatas.push(Metadata({description: "Unique NFT!", name: name, imageURL: _imageURL}));
        emit Transfer(address(0), msg.sender, totalSupply);
        totalSupply += 1;
    }

    function transfer(address _to, uint256 _tokenId) external {
        require(ownerOfNft[_tokenId] == msg.sender, "Not your NFT!");
        ownerOfNft[_tokenId] = _to;
        balances[msg.sender] -= 1;
        balances[_to] += 1;
        emit Transfer(msg.sender, _to, _tokenId);
    }

    function approve(address _approved, uint256 _tokenId) external {
        require(ownerOfNft[_tokenId] == msg.sender, "Not your NFT!");
        if (allowances[msg.sender][_approved][_tokenId] == true) {
            allowances[msg.sender][_approved][_tokenId] = false;       //calling approve on an already approved token disapproves it
        } else {
            allowances[msg.sender][_approved][_tokenId] = true;
            emit Approval(msg.sender, _approved, _tokenId);
        }
    }


    function transferFrom(address _owner, address _recepient, uint256 _tokenId) external {
        require(allowances[_owner][msg.sender][_tokenId] == true, "NFT not not approved!");
        ownerOfNft[_tokenId] = _recepient;
        balances[_owner] -= 1;
        balances[_recepient] += 1;
        emit Transfer(_owner, _recepient, _tokenId);
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    function selfDestruct(address _to) external onlyOwner {
        selfdestruct(payable(_to));
    }

    function withdraw(address _tokenAddress) external onlyOwner {
        if(_tokenAddress == address(0)) {
            payable(owner).transfer(address(this).balance);
        } else {
            uint256 tokenBalance = IERC20(_tokenAddress).balanceOf(address(this));
            IERC20(_tokenAddress).transfer(msg.sender, tokenBalance);
        }
    }

    function updateMetadata(uint256 _tokenId, string memory _description, string memory _name, string memory _imageURL) public onlyOwner {
        Metadata storage updatableMetadata;
        updatableMetadata = metadatas[_tokenId];
        updatableMetadata.description = _description;
        updatableMetadata.name = _name;
        updatableMetadata.imageURL = _imageURL;
    }

}