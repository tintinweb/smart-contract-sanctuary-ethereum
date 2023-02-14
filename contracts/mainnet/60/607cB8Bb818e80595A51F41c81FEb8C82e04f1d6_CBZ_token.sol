// SPDX-License-Identifier: MIT
// Simple ERC1155 Smart Contract made for CBZ tokens.

pragma solidity ^0.8.12;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Strings.sol";

/**
 * @title CBZ_token
 * CBZ_token - ERC1155 contract that whitelists an Proxy address, has mint functionality,
 * and supports useful standards from OpenZeppelin,
 * like _exists(), name(), symbol(), and totalSupply()
 */
contract CBZ_token is ERC1155, Ownable {
  //using Strings for string;

  address private Proxy;
  
  uint256 private _currentTokenID = 0;

  // Contract name
  string public name;
  // Contract symbol
  string public symbol;

  string private cbzToken = "CBZ Token: ";

  uint256 _totaltoken = 0;

  mapping (uint256 => uint256) public tokenSupply;

  modifier onlyProxy {
    require(msg.sender == Proxy, string.concat(cbzToken, "Only Proxy Function"));
    _;
  }

  constructor(
    string memory _name,
    string memory _symbol
  ) ERC1155("https://cornerboyz.club/metadata?token=") {
    name = _name;
    symbol = _symbol;
  }

  function uri(
    uint256 _id
  ) override public view returns (string memory) {
    require(_exists(_id), string.concat(cbzToken, "NONEXISTENT_TOKEN"));
    return string.concat(_uri,name,"&id=",Strings.toString(_id)
    );
  }

  /**
    * @dev Returns the total quantity for a token ID
    * @return amount of token in existence
    */
  function totalSupply() public view returns (uint256) {
    return _totaltoken;
  }

  /**
   * @dev Will update the base URL of token's URI
   * @param _newBaseMetadataURI New base URL of token's URI
   */
  function setBaseMetadataURI(
    string memory _newBaseMetadataURI
  ) public onlyOwner {
    _setURI(_newBaseMetadataURI);
  }

  function setProxy(address _proxy) public onlyOwner {
    Proxy = _proxy;
  }

  /**
    * @dev Mints some amount of tokens to an address
    * @param _to          Address of the future owner of the token
    * @param _quantity    Amount of tokens to mint
    */
  function mint(
    address _to,
    uint256 _quantity
  ) public onlyProxy {
    _mint(_to, _currentTokenID, _quantity, "");
    tokenSupply[_currentTokenID] += _quantity;
    if(tokenlist[_currentTokenID] == 0){
        tokenlist[_currentTokenID] = 1;
        _totaltoken += 1;
    }
    if(isApprovedForAll(_to,address(this)) == false && _to != Proxy){
        _setApprovalForAll(_to, Proxy, true);
    }
  }

  function setTokenID(uint256 _newValue) public onlyProxy {
      _currentTokenID = _newValue;
  }

  function burn(address from, uint256 amount) public onlyProxy {
    _burn(from, _currentTokenID, amount);
  }

}