// SPDX-License-Identifier: GPL-3.0

pragma solidity^0.8.0;

import "./ERC721A.sol";
import "./ERC721ABurnable.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./Strings.sol";
import "./SafeMath.sol";

contract Reef is ERC721A, ERC721ABurnable, Ownable {
    using ECDSA for bytes32; // allows us to convert bytes32 through series of casting to signature
    using Strings for uint256; // casting uint256 -> string
    using SafeMath for uint256;

    address private _signerAddress; // signer for the ECDSA addresses
    uint256 public maxSupply = 1111; // supply
    string private baseURI; // place our metadata is stored
    bool private mintAllowed = true; // in case wanting to stop mints 
    string private baseExtension = ".json"; // metadata file extension
    uint256 MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    // our config for sales
    struct Config {
        uint256 cost;
        uint256 maxPerTX;
        uint256 maxPerWallet;
        uint256 startTime;
    }
    // public sale config
    Config saleConfig = Config({ 
        cost: 0.08 ether,
        maxPerTX: 1,
        maxPerWallet: 1111, // unlimited (max size is 1111)
        startTime: MAX_INT // change on deploy
    });
    // whitelist sale config
    Config presaleConfig = Config({ 
        cost: 0.065 ether,
        maxPerTX: 1,
        maxPerWallet: 1,
        startTime: MAX_INT // change on deploy
    });

    // just a simple constructor
    constructor(string memory _name, string memory _symbol, address wlSigner) ERC721A(_name, _symbol){ 
        _signerAddress = wlSigner;
    }

    // This function should never be run
    // Only under the circumstance of inital signer being compromised 
    function changeSigner(address _newSigner) public onlyOwner {
        _signerAddress = _newSigner;
    }

    // other setters 
    function changeMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function changeBaseExtension(string memory _baseExtension) public onlyOwner {
        baseExtension = _baseExtension;
    }

    function changeBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    // config setters
    function changeFullConfig(uint256 _cost, uint256 _maxTx, uint256 _maxWallet, uint256 _startTime, bool editingSale) public onlyOwner {
        if (editingSale) {
            saleConfig = Config({
                cost: _cost,
                maxPerTX: _maxTx,
                maxPerWallet: _maxWallet,
                startTime: _startTime
            });
        } else {
            presaleConfig = Config({
                cost: _cost,
                maxPerTX: _maxTx,
                maxPerWallet: _maxWallet,
                startTime: _startTime
            });
        }

    }
    
    function changeSaleCost(uint256 _cost) public onlyOwner {
        saleConfig.cost = _cost;
    }

    function changeSaleMaxPerTx(uint256 _max) public onlyOwner {
        saleConfig.maxPerTX = _max;
    }

    function changeSaleMaxPerWallet(uint256 _max) public onlyOwner {
        saleConfig.maxPerWallet = _max;
    }

    function changeSaleStartTime(uint256 _start) public onlyOwner {
        saleConfig.startTime = _start;
    }


    function changePresaleCost(uint256 _cost) public onlyOwner {
        presaleConfig.cost = _cost;
    }

    function changePresaleMaxPerTx(uint256 _max) public onlyOwner {
        presaleConfig.maxPerTX = _max;
    }

    function changePresaleMaxPerWallet(uint256 _max) public onlyOwner {
        presaleConfig.maxPerWallet = _max;
    }

    function changePresaleStartTime(uint256 _start) public onlyOwner {
        presaleConfig.startTime = _start;
    }


    // config viewers 
    function viewPresaleCost() public view returns(uint256) {
        return presaleConfig.cost;
    }

    function viewPresaleMaxPerTx() public view returns(uint256){
        return presaleConfig.maxPerTX;
    }

    function viewPresaleMaxPerWallet() public view returns(uint256) {
        return presaleConfig.maxPerWallet;
    }

    function viewPresaleStartTime() public view returns(uint256) {
        return presaleConfig.startTime;
    }

    function viewSaleStart() public view returns(uint256) {
        return saleConfig.startTime;
    }
    
    function viewSaleCost() public view returns(uint256) {
        return saleConfig.cost;
    }

    function viewSaleMaxPerTx() public view returns(uint256){
        return saleConfig.maxPerTX;
    }

    function viewSaleMaxPerWallet() public view returns(uint256) {
        return saleConfig.maxPerWallet;
    }

    function whitelistMint(uint256 _quantity, bytes calldata signature) external payable{
        require(_quantity <= presaleConfig.maxPerTX, "This exceeds max per transaction");
        require(_quantity > 0, "You must mint more than 0");
        require(mintAllowed, "Mints are not currently allowed."); // in case admins want to close sale for any reason
        require(block.timestamp >= presaleConfig.startTime, "The sale is not live");
        require(msg.value * _quantity >= presaleConfig.cost, "User did not send enough ETH with transaction");
        require(totalSupply() +_quantity <= maxSupply, "We do not have enough supply for this"); // check we have enough supply for this
        require(_numberMinted(msg.sender) + _quantity <= presaleConfig.maxPerWallet, "This exceeds the amount you can mint in WL sale");
        // ECDSA magic :o
        require(_signerAddress == keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                bytes32(uint256(uint160(msg.sender)))
            )
        ).recover(signature), "Signer address mismatch.");
        // use erc721a for useful methods
        _safeMint(msg.sender, _quantity);
    }

    // simple mint function
    function mint(uint256 _quantity) external payable {
        require(_quantity <= saleConfig.maxPerTX, "This exceeds max per transaction");
        require(_quantity > 0, "You must mint more than 0");
        require(mintAllowed, "Mints are not currently allowed.");
        require(block.timestamp >= saleConfig.startTime, "The sale is not live");
        require(msg.value * _quantity >= saleConfig.cost, "User did not send enough ETH with transaction");
        require(totalSupply() +_quantity <= maxSupply);
        _safeMint(msg.sender, _quantity);
    }

    // check if user is on whitelist
    function testOnWl(bytes calldata signature) external view returns(bool) {
        require(_signerAddress == keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                bytes32(uint256(uint160(msg.sender)))
            )
        ).recover(signature), "Signer address mismatch.");
        return true;
    }

    // if this ever fails ill cry
    function _widthdraw(address _address, uint256 _amount) internal {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }
    // a user can check if they have already claimed there WL NFT
    function userUsedWl(address user) public view returns(bool) {
        return _numberMinted(user) >= presaleConfig.maxPerWallet;
    }
    // locator

    function _baseURI() internal override virtual view returns(string memory) {
        return baseURI; // retrieve our baseURI
    }

    function tokenURI(uint256 tokenID) public view virtual override returns(string memory) {
        require(_exists(tokenID), "This token does not exist");
        string memory currBaseURI = _baseURI();
        return bytes(currBaseURI).length > 0 ? string(abi.encodePacked(currBaseURI, tokenID.toString(), baseExtension)):""; // for opensea and other places to find the data of our nft
    }
    // money money must be funny in a rich mans world
    function withdrawAll() public onlyOwner{
        uint256 balance = address(this).balance;
        require(balance >0, "There is nothing to transfer");
        _widthdraw(0xe2f35Fa533066723Fd94Af3cE7C34B30b84105B9, balance.mul(5).div(100)); // change upon recieving team addresses
        _widthdraw(0xd56112A001E80033a3BC1e1Fa2BF4519de0E9694, address(this).balance);
    }
}