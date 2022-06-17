/**
 *Submitted for verification at Etherscan.io on 2022-06-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    function miner() external view returns(address);
    function balanceOf(address _owner) external view returns(uint256);
    function transfer(address receiver, uint256 amount) external returns(bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint256);
    function mint(address receiver ,uint256 amount) external returns(bool);
    function burn(uint256 amount) external returns(bool);
    function approve(address _owner, address _spender, uint256 _value) external;

}

interface IERC721 {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    function isApprovedOrOwner (address _spender, uint256 _tokenId) external view returns (bool);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
    function setApprovalForAll(address _operator, bool _approved) external;
    function approve(address _approved, uint256 _tokenId) external;
    function getApproved(uint256 _tokenId) external view returns (address);
    function mint(address _to, uint256 _tokenId) external;
    function burn(uint256 _tokenId) external;
}

contract marketNft {
    uint256 totalSupply_;
    uint256 private _totalItems = 0;
    mapping (uint256 => bool) _existTokenInList;
    mapping (uint256 => uint256) private _priceOfToken;
    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) allowed;
    address public erc20Token;
    address public erc721Token;

    struct infoListItem {
        uint256 itemId;
        uint256 tokenId;
        address seller;
        address spender;
        uint256 price;
        string time;
        bool status;
    }

    infoListItem[] _listItems;

    constructor(address _erc20Token, address _erc721Token) {
        erc20Token = _erc20Token;
        erc721Token = _erc721Token;
    }
    
    //-----------------------------Market
    function addToMarket(uint256 _tokenId, uint256 _price) public {
        require(_price > 0);
        IERC721(erc721Token).approve(address(this), _tokenId);
        IERC721(erc721Token).transferFrom(msg.sender, address(this), _tokenId);
        _totalItems += 1;
        infoListItem memory tokenInfo;
        tokenInfo.tokenId = _tokenId;
        tokenInfo.seller = msg.sender;
        tokenInfo.price = _price;
        tokenInfo.itemId = _listItems.length + 1;
        tokenInfo.status = true;
        _listItems.push(tokenInfo);
    }

    function listItems() public view returns(infoListItem[] memory) {
        return _listItems;
    }

    function buyNft(uint256 itemId) public {
        require(_listItems[itemId - 1].status == true, "The product is not in the store.");
        uint256 _tokenId = _listItems[itemId - 1].tokenId;
        IERC20(erc20Token).approve(msg.sender, address(this), _listItems[itemId - 1].price);
        IERC20(erc20Token).transferFrom(msg.sender, _listItems[itemId - 1].seller , _listItems[itemId - 1].price);      
        IERC721(erc721Token).approve(msg.sender, _tokenId);
        IERC721(erc721Token).transferFrom(address(this), msg.sender, _listItems[itemId - 1].tokenId);
        _listItems[itemId - 1].status = false;
    }
}