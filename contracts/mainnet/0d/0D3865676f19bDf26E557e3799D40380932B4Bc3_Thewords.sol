pragma solidity >=0.5.16 <0.6.0;

import "./Admin.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./ERC721Enumerable.sol";

contract ERC20Token {
    function balanceOf(address account) external view returns (uint256){
        account;
    }
    
    function approve(address spender, uint256 amount) external returns (bool){
        spender;
        amount;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool){
        sender;
        recipient;
        amount;
    }
}

contract UpgradeToken {

    function upTokenApprovals(address to, uint256 tokenId) public{
        to;
        tokenId;
    }

    function upRoyalty(uint256 tokenId, address receiver, uint96 royaltyFraction) public{
        tokenId;
        receiver;
        royaltyFraction;
    }
    
    function upTokenURI(uint256 tokenId, address owner, string memory uri) public{
        tokenId;
        uri;
    }
    
}

contract Thewords is Admin, ERC721Enumerable {
    
    using SafeMath for uint256;
    using Strings for uint256;

    event NewWord(uint256 id, address owner);

    //0=Eth;50=USDT;51=USDC
    mapping(uint8=>address) private tokenAddrsConfig;           //type->tokenaddr
    mapping(uint8=>uint256) private pricesConfig;               //priceType-->min

    constructor() ERC721('thewords.cc', 'WORDS') public {
        _baseURI = "https://user-nft.s3.ap-southeast-1.amazonaws.com/thewords/";
        // set royalty of all NFTs to 1%
        _setDefaultRoyalty(address(this), 100);
        pricesConfig[0] = 0.1 ether;
    }
    
    function createByPay(string memory tokenURI) public payable whenNotPaused{
        uint256 price = pricesConfig[0];
        require(msg.value >= price,'No enough money');
        createNft(msg.sender, tokenURI);
    }

    function createByToken(uint8 _type, string memory tokenURI) public whenNotPaused{
        uint256 price = pricesConfig[_type];

        address moneyAddr = tokenAddrsConfig[_type];
        require(moneyAddr != address(0),'money token no exist!');
        
        ERC20Token ercToken = ERC20Token(moneyAddr);
        uint256 tokenCount = ercToken.balanceOf(msg.sender);
        require(tokenCount >= price,'No enough token');
        
        ercToken.transferFrom(msg.sender, address(this), price);

        createNft(msg.sender, tokenURI);
    }

    function createByAdmin(address creator, string memory tokenURI) public whenNotPaused onlyAdmin{
        createNft(creator, tokenURI);
    }

    function createNft(address creator, string memory tokenURI) internal{
         uint256 _id = totalSupply().add(1);
        _mint(creator, _id);
        _tokenURIs[_id] = tokenURI;

        _setTokenRoyalty(_id, creator, 500);
        emit NewWord(_id, creator);
    }


    function() external payable {
    }
    function withdraw() external onlyOwner {
        msg.sender.transfer(address(this).balance);
    }
    function withdraw(uint256 amount) external onlyOwner {
        msg.sender.transfer(amount);
    }
    function withdraw(address ercAddr, uint256 amount) external onlyOwner {
        ERC20Token ercToken = ERC20Token(ercAddr);
        ercToken.approve(address(this), amount);
        ercToken.transferFrom(address(this), msg.sender, amount);
    }

    function checkBalance() external view onlyOwner returns(uint256) {
        return address(this).balance;
    }
    function checkBalance(address ercAddr) external view onlyOwner returns(uint256) {
        ERC20Token ercToken = ERC20Token(ercAddr);
        uint256 tokenCount = ercToken.balanceOf(address(this));
        return tokenCount;
    }


    function setTokenAddrs(uint8 _type, address _value) external onlyAdmin{
        tokenAddrsConfig[_type] = _value;
    }
    function getTokenAddr(uint8 _type) external view returns(address){
        return tokenAddrsConfig[_type];
    }

    function setPrice(uint8 _type, uint256 _value) external onlyAdmin{
        pricesConfig[_type] = _value;
    }
    function getPrice(uint8 _type) external view returns(uint256){
        return pricesConfig[_type];
    }

    function setBaseURI(string memory _uri) public onlyAdmin{
        _baseURI = _uri;
    }
    function getTokenURI(uint256 _tokenId) external view returns(string memory){
        return _tokenURIs[_tokenId];
    }

    function upgrade(address newAddr) external onlyAdmin {
        
        //_allowanceToAdmin
        //_tokenURIs
        
        UpgradeToken upgradeToken = UpgradeToken(newAddr);
        //all tokens
        for (uint256 index = 0; index < _allTokens.length; index++) {
            uint256 tokenId = _allTokens[index];
            if(!_exists(tokenId))
                continue;
            
            address owner = ownerOf(tokenId);
            
            RoyaltyInfo memory _royalty = _tokenRoyaltyInfo[tokenId];
            if(_royalty.receiver != address(0) && _royalty.royaltyFraction>0)
            {
                upgradeToken.upRoyalty(tokenId, _royalty.receiver, _royalty.royaltyFraction);
            }
            
            address approval = getApproved(tokenId);
            if (approval != address(0))
            {
                upgradeToken.upTokenApprovals(approval, tokenId);
            }
            
            string memory uri = _tokenURIs[tokenId];
            if (bytes(uri).length > 0)
            {
                upgradeToken.upTokenURI(tokenId, owner, uri);
            }
        }
        
    }

    function upTokenApprovals(address to, uint256 tokenId) public onlyAdmin{
        _approve(to, tokenId);
    }
            
    function upRoyalty(uint256 tokenId, address receiver, uint96 royaltyFraction) public onlyAdmin{
        //royalty
        if(receiver != address(0) && royaltyFraction>0)
        {
            _setTokenRoyalty(tokenId, receiver, royaltyFraction);
        }
    }
    
    function upTokenURI(uint256 tokenId, address owner, string memory uri) public onlyAdmin{
        _mint(owner, tokenId);
        _tokenURIs[tokenId] = uri;
    }

}