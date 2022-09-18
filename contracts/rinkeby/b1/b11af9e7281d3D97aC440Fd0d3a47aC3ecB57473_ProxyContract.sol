// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract ProxyContract is IERC721Receiver {

  address admin = msg.sender;
  address token = 0x1A2218Ba37E2E45A546a17BaAdDE58C1fa3Ba8B4;
  address[] slaveAddresses;
  address owner;

  constructor(address ownerAddress){
    owner = ownerAddress;
  }

  modifier onlyAdmin(){
    require(msg.sender==admin,"only admin");
    _;
  }

  modifier onlyOwner(){
    require(msg.sender==owner, "only owner");
    _;
  }

  modifier onlyHolder(){
    (bool success,bytes memory result) = address(token).call{gas:999999}(abi.encodeWithSignature("balanceOf(address)",msg.sender));
    require(success,"Failed calling balance of");
    uint256 balance = abi.decode(result,(uint256));
    require(balance>0, "only holder");
    _;
  }

  /*function execute(address _contractAddress, uint256 _amount, uint256 _callAmount) onlyOwner onlyHolder external payable {
    bool success;
    bytes memory result;

    (success,result) = address(_contractAddress).call{gas:999999}(abi.encodeWithSignature("totalSupply()"));
    require(success,"Failed calling total supply");

    uint256 _startTokenId = abi.decode(result,(uint256));
    _startTokenId+=1;

    for(uint256 i = 0; i < _callAmount; i++){
      (success,) = address(_contractAddress).call{value:msg.value/_amount/_callAmount,gas:999999}(abi.encodeWithSignature("mint(uint256)", _amount));
      require(success, "Error executing mint call");
      uint256 _nextTokenId = _startTokenId + _amount;

      for(uint256 x = _startTokenId; x < _nextTokenId; x++){
          (success,) = address(_contractAddress).call{gas:999999}(abi.encodeWithSignature("approve(address,uint256)",msg.sender,x));
          require(success,"Error executing approve call");
          (success,) = address(_contractAddress).call{gas:999999}(abi.encodeWithSignature("safeTransferFrom(address,address,uint256)",address(this),msg.sender,x));
          require(success,"Error executing transfer call");

          if(x+1 == _nextTokenId){
            _startTokenId = x+1;
          }
      }
    }
  }

  function executeWithId(address _contractAddress, uint256 _amount, uint256 _callAmount, uint256 startTokenId) onlyOwner onlyHolder external payable {
    bool success;
    bytes memory result;

    (success,result) = address(_contractAddress).call{gas:999999}(abi.encodeWithSignature("totalSupply()"));
    require(success,"Failed calling total supply");

    uint256 _startTokenId = abi.decode(result,(uint256));
    _startTokenId+=startTokenId;

    for(uint256 i = 0; i < _callAmount; i++){
      (success,) = address(_contractAddress).call{value:msg.value/_amount/_callAmount,gas:999999}(abi.encodeWithSignature("mint(uint256)", _amount));
      require(success, "Error executing mint call");
      uint256 _nextTokenId = _startTokenId + _amount;

      for(uint256 x = _startTokenId; x < _nextTokenId; x++){
          (success,) = address(_contractAddress).call{gas:999999}(abi.encodeWithSignature("approve(address,uint256)",msg.sender,x));
          require(success,"Error executing approve call");
          (success,) = address(_contractAddress).call{gas:999999}(abi.encodeWithSignature("safeTransferFrom(address,address,uint256)",address(this),msg.sender,x));
          require(success,"Error executing transfer call");

          if(x+1 == _nextTokenId){
            _startTokenId = x+1;
          }
      }
    }
  }

  function executeWithName(address _contractAddress, uint256 _amount, uint256 _callAmount, string calldata _mintFunction) onlyOwner onlyHolder external payable {
    bool success;
    bytes memory result;

    (success,result) = address(_contractAddress).call{gas:999999}(abi.encodeWithSignature("totalSupply()"));
    require(success,"Failed calling total supply");

    uint256 _startTokenId = abi.decode(result,(uint256));
    _startTokenId+=1;

    for(uint256 i = 0; i < _callAmount; i++){
      (success,) = address(_contractAddress).call{value:msg.value/_amount/_callAmount,gas:999999}(abi.encodeWithSignature(_mintFunction, _amount));
      require(success, "Error executing mint call");
      uint256 _nextTokenId = _startTokenId + _amount;

      for(uint256 x = _startTokenId; x < _nextTokenId; x++){
          (success,) = address(_contractAddress).call{gas:999999}(abi.encodeWithSignature("approve(address,uint256)",msg.sender,x));
          require(success,"Error executing approve call");
          (success,) = address(_contractAddress).call{gas:999999}(abi.encodeWithSignature("safeTransferFrom(address,address,uint256)",address(this),msg.sender,x));
          require(success,"Error executing transfer call");

          if(x+1 == _nextTokenId){
            _startTokenId = x+1;
          }
      }
    }
  }

  function executeWithIdAndName(address _contractAddress, uint256 _amount, uint256 _callAmount, uint256 startTokenId, string calldata _mintFunction) onlyOwner onlyHolder external payable {
    bool success;
    bytes memory result;

    (success,result) = address(_contractAddress).call{gas:999999}(abi.encodeWithSignature("totalSupply()"));
    require(success,"Failed calling total supply");

    uint256 _startTokenId = abi.decode(result,(uint256));
    _startTokenId+=startTokenId;

    for(uint256 i = 0; i < _callAmount; i++){
      (success,) = address(_contractAddress).call{value:msg.value/_amount/_callAmount,gas:999999}(abi.encodeWithSignature(_mintFunction, _amount));
      require(success, "Error executing mint call");
      uint256 _nextTokenId = _startTokenId + _amount;

      for(uint256 x = _startTokenId; x < _nextTokenId; x++){
          (success,) = address(_contractAddress).call{gas:999999}(abi.encodeWithSignature("approve(address,uint256)",msg.sender,x));
          require(success,"Error executing approve call");
          (success,) = address(_contractAddress).call{gas:999999}(abi.encodeWithSignature("safeTransferFrom(address,address,uint256)",address(this),msg.sender,x));
          require(success,"Error executing transfer call");

          if(x+1 == _nextTokenId){
            _startTokenId = x+1;
          }
      }
    }
  }
  */
  function executeWithProxy(address _contractAddress, uint256 _amount, uint256 _callAmount) onlyOwner onlyHolder external payable{
    for(uint i=0;i<_callAmount;i++){
      (bool success,) = address(slaveAddresses[i]).call{value:msg.value/_callAmount,gas:999999}(abi.encodeWithSignature("execute(address,uint256)",_contractAddress,_amount));
      require(success, "Error executing call");
    }
  }

  function executeWithProxyId(address _contractAddress, uint256 _amount, uint256 _callAmount, uint256 _tokenId) onlyOwner onlyHolder external payable {
    for(uint i=0;i<_callAmount;i++){
      (bool success,) = address(slaveAddresses[i]).call{value:msg.value/_callAmount,gas:999999}(abi.encodeWithSignature("executeWithId(address,uint256,uint256)",_contractAddress,_amount,_tokenId));
      require(success, "Error executing call");
    }
  }

  function executeWithProxyName(address _contractAddress, uint256 _amount, uint256 _callAmount, string calldata _mintFunction) onlyOwner onlyHolder external payable {
    for(uint i=0;i<_callAmount;i++){
      (bool success,) = address(slaveAddresses[i]).call{value:msg.value/_callAmount,gas:999999}(abi.encodeWithSignature("executeWithName(address,uint256,string)",_contractAddress,_amount,_mintFunction));
      require(success, "Error executing call");
    }
  }

  function executeWithProxyIdAndName(address _contractAddress, uint256 _amount, uint256 _callAmount, uint256 _tokenId, string calldata _mintFunction) onlyOwner onlyHolder external payable {
    for(uint i=0;i<_callAmount;i++){
      (bool success,) = address(slaveAddresses[i]).call{value:msg.value/_callAmount,gas:999999}(abi.encodeWithSignature("executeWithIdAndName(address,uint256,uint256,string)",_contractAddress,_amount,_tokenId,_mintFunction));
      require(success, "Error executing call");
    }
  }

  function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
    return IERC721Receiver.onERC721Received.selector;
  }

  function transferERC721(address _contractAddress, uint256 _tokenId) onlyOwner external {
    (bool success,) = address(_contractAddress).call{gas:999999}(abi.encodeWithSignature("approve(address,uint256)",msg.sender,_tokenId));
    require(success,"Error executing approve call");
    (success,) = address(_contractAddress).call{gas:999999}(abi.encodeWithSignature("safeTransferFrom(address,address,uint256)",address(this),msg.sender,_tokenId));
    require(success,"Error executing transfer call");
  }

  function withdraw() onlyOwner external {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Failed transfer");
  }

  function setSlaves(address[] calldata _slaveAddresses) onlyOwner external {
    slaveAddresses=_slaveAddresses;
  }
  
  function setOwner(address _address) onlyAdmin external {
    owner = _address;
  }

  function setToken(address _address) onlyAdmin external {
    token = _address;
  }

  function setAdmin(address _address) onlyAdmin external {
    admin = _address;
  }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}