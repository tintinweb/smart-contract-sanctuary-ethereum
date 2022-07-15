// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC1155.sol";

contract Dapp is Ownable, ERC1155 {

    using SafeMath for uint;

    mapping(uint256 => string) token_id_uri;

    mapping(uint256 => address) token_id_recipient;
    mapping(uint256 => uint256) token_id_balance;
    
    mapping(uint256 => uint) token_id_stock;
    mapping(uint256 => bool) token_id_available;

    constructor() ERC1155(""){
        setTokenURI(113, "https://bafkreiffjgtkemsma75qw2bla6d4s647oht6qamrcd35fdeadqkx2xmnd4.ipfs.nftstorage.link/");
        setStock(113, 111);
        setRecipient(113, 0x959D3dBDEc126ee0A28aA2086991AA94Fe7Dcc73);
        flip(113);
        setTokenURI(114, "https://bafkreifbwjcdv52ojckbo4td5zd27bnd5r4vx7vrvndumbxg5qfdz7uvzm.ipfs.nftstorage.link/");
        setStock(114, 111);
        setRecipient(114, 0x09d75cde1cdbbE58aBac96f59ee319E8DB4cf9b1);
        flip(114);
    }

    /**
    * @dev Sets the recipient address of a token ID
    */
    function setRecipient(uint256 _tokenId, address _recipient) public onlyOwner {
        token_id_recipient[_tokenId] = _recipient;
    }

    /**
    * @dev Returns the balance of a token ID
    */
    function getBalance(uint256 _tokenId) public view onlyOwner returns(uint256) {
        return token_id_balance[_tokenId];
    }

    /**
    * @dev Sets the stock of a token ID
    */
    function setStock(uint256 _tokenId, uint _stock) public onlyOwner {
        token_id_stock[_tokenId] = _stock;
    }

    /**
    * @dev Returns the stock of a token ID
    */
    function getStock(uint256 _tokenId) public view onlyOwner returns(uint256) {
        return token_id_stock[_tokenId];
    }

    /**
    * @dev Flips the availability of a token ID
    */
    function flip(uint256 _tokenId) public onlyOwner {
        token_id_available[_tokenId] = !token_id_available[_tokenId];
    }

    function donate(uint256 _tokenId) external payable {
        // Check the recipient address of a token ID
        require(token_id_recipient[_tokenId] != address(0), "token does not have a recipient");
        
        // Check token ID available for donation
        require(token_id_available[_tokenId], "token isn't available for donation");
        
        // Check proper amount sent
        require(msg.value > 0, "Send proper ETH amount");
        token_id_balance[_tokenId] += msg.value;
        
        if(token_id_stock[_tokenId] > 0 && balanceOf(msg.sender, _tokenId) == 0){
            token_id_stock[_tokenId] -= 1;
            _mint(msg.sender, _tokenId, 1, "");
        }
    }

    /**
    * @dev Withdraw the token ID's balance to the recipient address
    */
    function withdraw(uint256 _tokenId) external {
        uint amount = token_id_balance[_tokenId];
        (bool success,) = token_id_recipient[_tokenId].call{value: amount}("");
        token_id_balance[_tokenId] -= amount;
        require(success, "Failed to send ether");
    }

    /**
     * @dev Sets a URI for a given token ID's metadata
     */
    function setTokenURI(uint256 _tokenId, string memory _tokenURI) public onlyOwner {
        token_id_uri[_tokenId] = _tokenURI;
    }

    /**
     * @dev Returns a URI for a given token ID's metadata
     */
    function uri(uint256 _tokenId) public view override returns (string memory) {
        return token_id_uri[_tokenId];
    }

}