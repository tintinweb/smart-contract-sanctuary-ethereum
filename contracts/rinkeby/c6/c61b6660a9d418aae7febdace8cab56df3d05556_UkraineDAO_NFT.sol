/**
 *Submitted for verification at Etherscan.io on 2022-02-26
*/

// SPDX-License-Identifier: OSL-3.0

pragma solidity 0.8.11;

/*

 __  __     __  __     ______     ______     __     __   __     ______
/\ \/\ \   /\ \/ /    /\  == \   /\  __ \   /\ \   /\ "-.\ \   /\  ___\
\ \ \_\ \  \ \  _"-.  \ \  __<   \ \  __ \  \ \ \  \ \ \-.  \  \ \  __\
 \ \_____\  \ \_\ \_\  \ \_\ \_\  \ \_\ \_\  \ \_\  \ \_\\"\_\  \ \_____\
  \/_____/   \/_/\/_/   \/_/ /_/   \/_/\/_/   \/_/   \/_/ \/_/   \/_____/


|########################################################################|
|########################################################################|
|########################################################################|
|########################################################################|
|########################################################################|
|::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::|
|::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::|
|::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::|
|::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::|
|::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::|

  // PLEASE PROVIDE THE TAGS TO SIGN OFF WITH FOR THIS CONTRACT !!! ALL PARTICIPANTS SHOULD SIGN THIS !!!
  @cxiplabs

 ---------------------------------------------------

*/
contract UkraineDAO_NFT {

  address private _owner;

  string private _name = "UKRAINE";

  string private _symbol = unicode"🇺🇦";

  string private _domain = "UkraineDAO.love";

  address private _tokenOwner;

  address private _tokenApproval;

  string private _flag = "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"1200\" height=\"800\"><rect width=\"1200\" height=\"800\" fill=\"#005BBB\"/><rect width=\"1200\" height=\"400\" y=\"400\" fill=\"#FFD500\"/></svg>";

  string private _flagSafe = "<svg xmlns=\\\"http://www.w3.org/2000/svg\\\" width=\\\"1200\\\" height=\\\"800\\\"><rect width=\\\"1200\\\" height=\\\"800\\\" fill=\\\"#005BBB\\\"/><rect width=\\\"1200\\\" height=\\\"400\\\" y=\\\"400\\\" fill=\\\"#FFD500\\\"/></svg>";

  mapping(address => mapping(address => bool)) private _operatorApprovals;

  event Approval (address indexed wallet, address indexed operator, uint256 indexed tokenId);

  event ApprovalForAll (address indexed wallet, address indexed operator, bool approved);

  event Transfer (address indexed from, address indexed to, uint256 indexed tokenId);

  event OwnershipTransferred (address indexed previousOwner, address indexed newOwner);

  /*
   * @dev Only one NFT is ever created.
   */
  constructor() {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
    _mint(_owner, 1);
  }

  /*
   * @dev Left empty to not block any smart contract transfers from running out of gas.
   */
  receive() external payable {}

  /*
   * @dev Left empty to not allow any other functions to be called.
   */
  fallback() external {}

  /*
   * @dev Allows to limit certain function calls to only the contract owner.
   */
  modifier onlyOwner() {
    require(isOwner(), "you are not the owner");
    _;
  }

  /*
   * @dev Can transfer smart contract ownership to another wallet/smart contract.
   */
  function changeOwner (address newOwner) public onlyOwner {
    require(newOwner != address(0), "empty address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }

  /*
   * @dev Provisional functionality to allow the removal of any spammy NFTs.
   */
  function withdrawERC1155 (address token, uint256 tokenId, uint256 amount) public onlyOwner {
    ERCTransferable(token).safeTransferFrom(address(this), _owner, tokenId, amount, "");
  }

  /*
   * @dev Provisional functionality to allow the withdrawal of accidentally received ERC20 tokens.
   */
  function withdrawERC20 (address token, uint256 amount) public onlyOwner {
    ERCTransferable(token).transfer(_owner, amount);
  }

  /*
   * @dev Provisional functionality to allow the removal of any spammy NFTs.
   */
  function withdrawERC721 (address token, uint256 tokenId) public onlyOwner {
    ERCTransferable(token).safeTransferFrom(address(this), _owner, tokenId);
  }

  /*
   * @dev Provisional functionality to allow the withdrawal of accidentally received ETH.
   */
  function withdrawETH () public onlyOwner {
    payable(address(msg.sender)).transfer(address(this).balance);
  }

  /*
   * @dev Approve a third-party wallet/contract to manage the token on behalf of a token owner.
   */
  function approve (address operator, uint256 tokenId) public {
    require(operator != _tokenOwner, "one cannot approve one self");
    require(_isApproved(msg.sender, tokenId), "the sender is not approved");
    _tokenApproval = operator;
    emit Approval(_tokenOwner, operator, tokenId);
  }

  /*
   * @dev Safely transfer a token to another wallet/contract.
   */
  function safeTransferFrom (address from, address to, uint256 tokenId) public payable {
    safeTransferFrom(from, to, tokenId, "");
  }

  /*
   * @dev Safely transfer a token to another wallet/contract.
   */
  function safeTransferFrom (address from, address to, uint256 tokenId, bytes memory data) public payable {
    require(_isApproved(msg.sender, tokenId), "sender is not approved");
    _transferFrom(from, to, tokenId);
    if (isContract(to)) {
      require(ERCTransferable(to).onERC721Received(address(this), from, tokenId, data) == 0x150b7a02, "onERC721Received has failed");
    }
  }

  /*
   * @dev Approve a third-party wallet/contract to manage all tokens on behalf of a token owner.
   */
  function setApprovalForAll (address operator, bool approved) public {
    require(operator != msg.sender, "one cannot approve one self");
    _operatorApprovals[msg.sender][operator] = approved;
    emit ApprovalForAll(msg.sender, operator, approved);
  }

  /*
   * @dev Transfer a token to anther wallet/contract.
   */
  function transfer (address to, uint256 tokenId) public payable {
    transferFrom(msg.sender, to, tokenId, "");
  }

  /*
   * @dev Transfer a token to another wallet/contract.
   */
  function transferFrom (address from, address to, uint256 tokenId) public payable {
    transferFrom(from, to, tokenId, "");
  }

  /*
   * @dev Transfer a token to another wallet/contract.
   */
  function transferFrom (address from, address to, uint256 tokenId, bytes memory) public payable {
    require(_isApproved(msg.sender, tokenId), "the sender is not approved");
    _transferFrom(from, to, tokenId);
  }

  /*
   * @dev Gets the token balance of a wallet/contract.
   */
  function balanceOf (address wallet) public view returns (uint256) {
    require(wallet != address(0), "empty address");
    return wallet == _tokenOwner ? 1 : 0;
  }

  /*
   * @dev Gets the base64 encoded JSON data stream of contract descriptors.
   */
  function contractURI () public view returns (string memory) {
    return string(
      abi.encodePacked(
        "data:application/json;base64,",
        Base64.encode(
          abi.encodePacked(
            "{",
              "\"name\":\"", _name, "\",",
              unicode"\"description\":\"This is the Ukranian flag 🇺🇦 1/1\",",
              "\"external_link\":\"https://", _domain, "/\",",
              "\"image\":\"data:image/svg+xml;base64,", Base64.encode(_flag), "\"",
            "}"
          )
        )
      )
    );
  }

  /*
   * @dev Check if a token exists.
   */
  function exists (uint256 tokenId) public pure returns (bool) {
    return (tokenId == 1);
  }

  /*
   * @dev Check if an approved wallet/address was added for a particular token.
   */
  function getApproved (uint256) public view returns (address) {
    return _tokenApproval;
  }

  /*
   * @dev Check if an operator was approved for a particular wallet/contract.
   */
  function isApprovedForAll (address wallet, address operator) public view returns (bool) {
    return _operatorApprovals[wallet][operator];
  }

  /*
   * @dev Check if current wallet/caller is the owner of the smart contract.
   */
  function isOwner () public view returns (bool) {
    return (msg.sender == _owner);
  }

  /*
   * @dev Get the name of the collection.
   */
  function name () public view returns (string memory) {
    return _name;
  }

  /*
   * @dev Get the owner of the smart contract.
   */
  function owner () public view returns (address) {
    return _owner;
  }

  /*
   * @dev Get the owner of a particular token.
   */
  function ownerOf (uint256 tokenId) public view returns (address) {
    require(tokenId == 1, "token does not exist");
    return _tokenOwner;
  }

  /*
   * @dev Check if the smart contract supports a particular interface.
   */
  function supportsInterface (bytes4 interfaceId) public pure returns (bool) {
        if (
            interfaceId == 0x01ffc9a7 || // ERC165
            interfaceId == 0x80ac58cd || // ERC721
            interfaceId == 0x780e9d63 || // ERC721Enumerable
            interfaceId == 0x5b5e139f || // ERC721Metadata
            interfaceId == 0x150b7a02 || // ERC721TokenReceiver
            interfaceId == 0xe8a3d485    // contractURI()
        ) {
            return true;
        } else {
            return false;
        }
  }

  /*
   * @dev Get the collection's symbol.
   */
  function symbol () public view returns (string memory) {
    return _symbol;
  }

  /*
   * @dev Get token by index.
   */
  function tokenByIndex (uint256 index) public pure returns (uint256) {
    require(index == 0, "index out of bounds");
    return 1;
  }

  /*
   * @dev Get wallet/contract token by index.
   */
  function tokenOfOwnerByIndex (address wallet, uint256 index) public view returns (uint256) {
    require(wallet == _tokenOwner && index == 0, "index out of bounds");
    return 1;
  }

  /*
   * @dev Gets the base64 encoded data stream of token.
   */
  function tokenURI (uint256 tokenId) public view returns (string memory) {
    require(_exists(tokenId), "token does not exist");
    return string(
      abi.encodePacked(
        "data:application/json;base64,",
        Base64.encode(
          abi.encodePacked(
            "{",
              "\"name\":\"Ukrainian Flag\",",
              unicode"\"description\":\"This is the Ukranian flag 🇺🇦 1/1.\\n\\n",
              "Funds raised from this sale go towards Ukrainian civilians who help those suffering from the war initiated by Putin, \\\"Come Back Alive\\\", one of the most effective and transparent Ukrainian charitable and volunteer initiatives: https://savelife.in.ua\\n\\n",
              "This project is put together for you by Pussy Riot, Trippy Labs, PleasrDAO, CXIP and Ukranian humanitarian activists working tirelessly on the ground and consulting us generously.\\n\\n",
              unicode"Much support and love to Ukraine 🇺🇦\",",
              "\"external_url\":\"https://", _domain, "/\",",
              "\"background_color\":\"ffffff\",",
              "\"image\":\"data:image/svg+xml;base64,", Base64.encode(_flag), "\",",
              "\"image_data\":\"", _flagSafe, "\"",
            "}"
          )
        )
      )
    );
  }

  /*
   * @dev Get list of all tokens of an owner.
   */
  function tokensOfOwner (address wallet) public view returns (uint256[] memory tokens) {
    if (wallet == _tokenOwner) {
        tokens = new uint256[](1);
        tokens[0] = 1;
    }
    return tokens;
  }

  /*
   * @dev Get the total supply of tokens in the collection.
   */
  function totalSupply () public pure returns (uint256) {
    return 1;
  }

  /*
   * @dev Signal to sending contract that a token was received.
   */
  function onERC721Received (address operator, address, uint256 tokenId, bytes calldata) public returns (bytes4) {
    ERCTransferable(operator).safeTransferFrom(address(this), _owner, tokenId);
    return 0x150b7a02;
  }

  function _clearApproval () internal {
    delete _tokenApproval;
  }

  function _mint (address to, uint256 tokenId) internal {
    require(to != address(0));
    _tokenOwner = to;
    emit Transfer(address(0), to, tokenId);
  }

  function _transferFrom (address from, address to, uint256 tokenId) internal {
    require(_tokenOwner == from, "you are not token owner");
    require(to != address(0), "you cannot burn this");
    _clearApproval();
    _tokenOwner = to;
    emit Transfer(from, to, tokenId);
  }

  function _exists (uint256 tokenId) internal pure returns (bool) {
    return (tokenId == 1);
  }

  function _isApproved (address spender, uint256 tokenId) internal view returns (bool) {
    require(_exists(tokenId));
    return (spender == _tokenOwner || getApproved(tokenId) == spender || isApprovedForAll(_tokenOwner, spender));
  }

  function isContract (address account) internal view returns (bool) {
    bytes32 codehash;
    assembly {
      codehash := extcodehash(account)
    }
    return (codehash != 0x0 && codehash != 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470);
  }

}

interface ERCTransferable {

    // ERC155
    function safeTransferFrom (address from, address to, uint256 tokenid, uint256 amount, bytes calldata data) external;

    // ERC20
    function transfer (address recipient, uint256 amount) external returns (bool);

    // ERC721
    function safeTransferFrom (address from, address to, uint256 tokenId) external payable;

    // ERC721
    function onERC721Received (address operator, address from, uint256 tokenId, bytes calldata data) external pure returns (bytes4);

}

library Base64 {

    function encode(string memory _str) internal pure returns (string memory) {
        bytes memory data = bytes(_str);
        return encode(data);
    }

    function encode(bytes memory data) internal pure returns (string memory) {
        string memory table = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
        uint256 encodedLen = 4 * ((data.length + 2) / 3);
        string memory result = new string(encodedLen + 32);
        assembly {
            mstore(result, encodedLen)
            let tablePtr := add(table, 1)
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            let resultPtr := add(result, 32)
            for {} lt(dataPtr, endPtr) {}
            {
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1)
            }
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        return result;
    }

}