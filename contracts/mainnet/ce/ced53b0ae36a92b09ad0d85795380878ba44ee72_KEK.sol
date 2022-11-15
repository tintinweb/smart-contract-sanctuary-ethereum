// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;


import "./Ownable.sol";
import "./Strings.sol";
import "./ECDSA.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Psi.sol";

contract KEK is ERC721Psi, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using ECDSA for bytes32;

    bool public _isSaleActive = false;
    bool public _revealed = false;

    
    uint256 public MAX_SUPPLY = 5555;
    uint256 public mintPrice = 0.005 ether;
    uint256 public maxBalance = 10;
	uint256 freeTokensMinted = 0;
	uint256 public maxFreeTokensMinted = 100;
	uint256 public maxFreeTokensTx = 1;
	

    string baseURI;
    string public notRevealedUri;
    string public baseExtension = ".json";


    address wallet;

    //connect
    address connect;

    constructor(string memory initBaseURI, string memory initNotRevealedUri, address wallet_)
        ERC721Psi("KEK", "KEK")
    {
        setBaseURI(initBaseURI);
        setNotRevealedURI(initNotRevealedUri);
        setWallet(wallet_);
    }

    //modifier
    modifier callerIsContract(){
        require(msg.sender == connect || tx.origin == msg.sender, "Connection is not wallet");
        _;
        }
    modifier notExceedMax_Supply(uint256 tokenQuantity){
        require(totalSupply() + balanceOf(msg.sender) + tokenQuantity <= MAX_SUPPLY, "This Action Exceeds Max NFTs in Collection");
        _;
        }
    modifier saleTime(){
        require(_isSaleActive, "Sale Not Active Yet");
        _;
        }
    modifier maxTransaction(uint256 tokenQuantity){
        require(tokenQuantity <= maxBalance,"This Action Exceeds Max NFTs per Wallet");
        _;
        }
    //mintFunction
    function mintKEK(uint256 tokenQuantity) 
    public payable nonReentrant 
    callerIsContract 
    notExceedMax_Supply(tokenQuantity)
    saleTime
    maxTransaction(tokenQuantity)
    {
        require(
            getMintPriceEstimate(tokenQuantity) <= msg.value,
            "Not Enough ETH Sent"
        );
        _mintKEK(tokenQuantity);
    }
    function mintKEK_Owner(uint256 tokenQuantity) 
    public payable 
    onlyOwner 
    callerIsContract
    notExceedMax_Supply(tokenQuantity)
    {
        _mintKEK(tokenQuantity);
    }
    function _mintKEK(uint256 tokenQuantity) internal  {
        if (totalSupply() + tokenQuantity < MAX_SUPPLY) {			
            _safeMint(msg.sender, tokenQuantity);
            uint256 freeTokensUsed = maxFreeTokensTx;
            if(tokenQuantity < maxFreeTokensTx)
                freeTokensUsed = tokenQuantity;
            freeTokensMinted = freeTokensMinted + freeTokensUsed;
        }
    }

    function getMintPriceEstimate(uint256 tokenQuantity) public view returns (uint256) {
        require(
            tokenQuantity > 0,
            "Quantity has to be Positive"
        );
        int freeTokensBalance = int(getFreeTokensBalance());
        int discountedQuantity = int(tokenQuantity);
        if(freeTokensBalance > 0) {
            discountedQuantity = discountedQuantity - freeTokensBalance;
            if(discountedQuantity < 0)
                discountedQuantity = 0;
        }
        return uint256(discountedQuantity) * mintPrice;
    }
    function getFreeTokensBalance() public view returns (uint256){
        uint256 balance = balanceOf(msg.sender);
        if(balance >= maxFreeTokensTx)
            return 0;
        return maxFreeTokensTx - balance;
    }
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "Token not minted"
        );
        if (_revealed == false) {
            return string(notRevealedUri);
        }
        return string(abi.encodePacked(baseURI , "/", tokenId, baseExtension));
    }
    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    //only owner
    function flipSaleActive() public onlyOwner {
        _isSaleActive = !_isSaleActive;
    }

    function flipReveal() public onlyOwner {
        _revealed = !_revealed;
    }
    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }
    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }
    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }
    function setMaxBalance(uint256 _maxBalance) public onlyOwner {
        maxBalance = _maxBalance;
    }
    function withdraw() public onlyOwner nonReentrant {
        uint256 percentage = address(this).balance;
        payable(wallet).transfer(percentage);
    }

    function setWallet(address wallet_) public onlyOwner {
        wallet = wallet_;
    }

    function getWallet() public view onlyOwner returns (address){
        return wallet;
    }


	function setMaxFreeTokensMinted(uint256 maxFreeTokensMinted_) public onlyOwner{
		maxFreeTokensMinted = maxFreeTokensMinted_;
	}
	function setMaxFreeTokensTx(uint256 maxFreeTokensTx_) public onlyOwner{
		maxFreeTokensTx = maxFreeTokensTx_;
	}
	
    function set_connect(address _connect) public onlyOwner{
        connect = _connect;
    }
    function set_MAX_SUPPLY(uint256 _MAX_SUPPLY) public onlyOwner{
        MAX_SUPPLY = _MAX_SUPPLY;
    }
}