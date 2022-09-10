// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";

/* 
/**


 .----------------.  .----------------.  .----------------.  .----------------.  .----------------.  .----------------. 
| .--------------. || .--------------. || .--------------. || .--------------. || .--------------. || .--------------. |
| |   ______     | || | _____  _____ | || |   _____      | || |   _____      | || |  _________   | || |  ____  ____  | |
| |  |_   _ \    | || ||_   _||_   _|| || |  |_   _|     | || |  |_   _|     | || | |_   ___  |  | || | |_  _||_  _| | |
| |    | |_) |   | || |  | |    | |  | || |    | |       | || |    | |       | || |   | |_  \_|  | || |   \ \  / /   | |
| |    |  __'.   | || |  | '    ' |  | || |    | |   _   | || |    | |   _   | || |   |  _|      | || |    \ \/ /    | |
| |   _| |__) |  | || |   \ `--' /   | || |   _| |__/ |  | || |   _| |__/ |  | || |  _| |_       | || |    _|  |_    | |
| |  |_______/   | || |    `.__.'    | || |  |________|  | || |  |________|  | || | |_____|      | || |   |______|   | |
| |              | || |              | || |              | || |              | || |              | || |              | |
| '--------------' || '--------------' || '--------------' || '--------------' || '--------------' || '--------------' |
 '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  '----------------'                                      


@title ERC-721 token for Bullfy
@author drew10.eth

*/

contract Bullfy is Ownable, ERC721Enumerable {
   using Strings for uint;
    using Counters for Counters.Counter;

    string private _tokenURI;
    string private _contractURI;
    Counters.Counter private _tokenIdCounter;
    
    uint public maxSupply = 350;
    uint public tokenPrice = 0.088 ether;
    bool public saleStarted = false;
    bool public transfersEnabled = false;

    mapping(uint => uint) public expiryTime;

    constructor(
        string memory tokenURI_,
        string memory contractURI_
    ) ERC721("Bullfy", "Bullfy") {
        _tokenURI = tokenURI_;
        _contractURI = contractURI_;
    }

    /**
    * @notice Function modifier that is used to determine if the caller is
    * the owner. If not, run additional checks before proceeding.
    */
    modifier nonOwner(address to) {
        if (msg.sender != owner()) {
            require(transfersEnabled, "Token transfers are currently disabled.");
            require(balanceOf(to) == 0, "User already holds a token.");
        }
        _;
    }

    /**
    * @notice Function that is used to mint a token.
    */
    function mint() public payable {

        uint tokenIndex = _tokenIdCounter.current() + 1;

        require(tx.origin == msg.sender, "Caller must not be a contract.");
        require(saleStarted, "Sale has not started.");
        require(balanceOf(msg.sender) == 0, "User already holds a token.");
        require(msg.value == tokenPrice, "Incorrect Ether amount sent.");
        require(tokenIndex <= maxSupply, "Minted token would exceed total supply.");

        _tokenIdCounter.increment();

        _safeMint(msg.sender, tokenIndex);
        expiryTime[tokenIndex] = block.timestamp + 30 days;
    }


    /**
    * @notice Function that is used to extend/renew a tokens expiry date.
    *
    * @param _tokenId The token ID to extend/renew.
    */
    function renewToken(uint _tokenId) public payable {
        require(tx.origin == msg.sender, "Caller must not be a contract.");
        require(msg.value == tokenPrice, "Incorrect Ether amount.");
        require(_exists(_tokenId), "Token does not exist.");

        uint _currentexpiryTime = expiryTime[_tokenId];

        if (block.timestamp > _currentexpiryTime) {
            expiryTime[_tokenId] = block.timestamp + 30 days;
        } else {
            expiryTime[_tokenId] += 30 days;
        }
    }

    /**


    /**
    * @notice Function that is used to extend/renew a tokens expiry date.
    *
    * @param _tokenId The token ID to extend/renew.
    */
    function renewTokenForUser(uint _tokenId) public onlyOwner {
        require(_exists(_tokenId), "Token does not exist.");

        uint _currentexpiryTime = expiryTime[_tokenId];

        if (block.timestamp > _currentexpiryTime) {
            expiryTime[_tokenId] = block.timestamp + 60 days;
        } else {
            expiryTime[_tokenId] += 60 days;
        }
    }

    /**

    /**
    * @notice Function that is used to mint a token free of charge, only
    * callable by the owner.
    *
    * @param _receiver The receiving address of the newly minted token.
    */
    function ownerMint(address _receiver) public onlyOwner {

        uint tokenIndex = _tokenIdCounter.current() + 1;

        require(_receiver != address(0), "Receiver cannot be zero address.");
        require(tokenIndex <= maxSupply, "Minted token would exceed total supply.");

        if (msg.sender != _receiver) {
            require(balanceOf(_receiver) == 0, "User already holds a token.");
        }

        _tokenIdCounter.increment();

        _safeMint(_receiver, tokenIndex);
        expiryTime[tokenIndex] = block.timestamp + 30 days;
    }

    /**
    * @notice Function that is used to extend/renew a tokens expiry date.
    *
    * @param _tokenId The token ID to extend/renew.
    */

    /**
    * @notice Function that is used to extend/renew a tokens expiry date for
    * 30 days free of charge, only callable by the owner.
    *
    * @param _tokenId The token ID to extend/renew.
    */

    /**
    * @notice Function that is used to extend/renew multiple tokens expiry date for
    * 365 days free of charge, only callable by the owner.
    *
    * @param _tokenIds The token IDs to extend/renew.
    */

    /**
    * @notice Function that is used to update the 'tokenPrice' variable,
    * only callable by the owner.
    *
    * @param _updatedTokenPrice The new token price in units of wei. E.g.
    * 500000000000000000 is 0.50 Ether.
    */
    function updateTokenPrice(uint _updatedTokenPrice) external onlyOwner {
        require(tokenPrice != _updatedTokenPrice, "Price has not changed.");
        tokenPrice = _updatedTokenPrice;
    }

    /**
    * @notice Function that is used to authenticate a user.
    *
    * @param _tokenId The desired token owned by a user.
    *
    * @return Returns a bool value determining if authentication was
    * was successful. 'true' is successful, 'false' if otherwise.
    */
    function authenticateUser(uint _tokenId, address owner) public view returns (bool) {
        require(_exists(_tokenId), "Token does not exist.");
        require(expiryTime[_tokenId] > block.timestamp, "Token has expired. Please renew!");

        return owner == ownerOf(_tokenId) ? true : false;
    }

    /**
    * @notice Function that is used to increase the `maxSupply` value. Used
    * to emulate restocks once the maximum supply of tokens has been minted.
    *
    * @param _newTokens The amount of tokens to add to `maxSupply` value.
    */
    function addTokens(uint _newTokens) external onlyOwner {
        maxSupply += _newTokens;
    }

    /**
    * @notice Function that is used to decrease the `maxSupply` value. Used
    * to reduce the maximum supply in the event too many tokens have been added.
    *
    * @param _numTokens The amount of tokens to add to `maxSupply` value.
    */
    function removeTokens(uint _numTokens) external onlyOwner {
        require(maxSupply - _numTokens >= totalSupply(), "Supply cannot fall below minted tokens.");
        maxSupply -= _numTokens;
    }

    /**
    * @notice Function that is used to get the token URI for a specific token.
    *
    * @param _tokenId The token ID to fetch the token URI for.
    *
    * @return Returns a string value representing the token URI for the
    * specified token.
    */
    function tokenURI(uint _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return string(abi.encodePacked(_tokenURI, _tokenId.toString()));
    }

    /**
    * @notice Function that is used to update the token URI for the contract,
    * only callable by the owner.
    * 
    * @param tokenURI_ A string value to replace the current '_tokenURI' value.
    */
    function setTokenURI(string calldata tokenURI_) external onlyOwner {
        _tokenURI = tokenURI_;
    }

    /**
    * @notice Function that is used to get the contract URI.
    *
    * @return Returns a string value representing the contract URI.
    */
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /**
    * @notice Function that is used to update the contract URI, only callable
    * by the owner.
    * 
    * @param contractURI_ A string value to replace the current 'contractURI_'.
    */
    function setContractURI(string calldata contractURI_) external onlyOwner {
        _contractURI = contractURI_;
    }

    /**
    * @notice Function that is used to withdraw the balance of the contract,
    * only callable by the owner.
    */
    function withdrawBalance() public onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}

    /**
    * @notice Function that is used to flip the sale state of the contract,
    * only callable by the owner.
    */
    function toggleSale() public onlyOwner {
        saleStarted = !saleStarted;
    }

    /**
    * @notice Function that is used to flip the transfer state of the contract,
    * only callable by the owner.
    */
    function toggleTransfers() public onlyOwner {
        transfersEnabled = !transfersEnabled;
    }

    /**
    * @notice Function that is used to get the total tokens minted.
    *
    * @return Returns a uint which indicates the total supply.
    */
    /**
    * @notice Function that is used to safely transfer a token from one owner to another,
    * this function has been overriden so that transfers can be disabled.
    */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override nonOwner(to) {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Transfer caller is not owner nor approved.");
        require(expiryTime[tokenId] > block.timestamp, "Token has expired.");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
    * @notice Function that is used to transfer a token from one owner to another,
    * this function has been overriden so that transfers can be disabled.
    */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override nonOwner(to) {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Transfer caller is not owner nor approved.");
        require(expiryTime[tokenId] > block.timestamp, "Token has expired.");
        _transfer(from, to, tokenId);
    }

}