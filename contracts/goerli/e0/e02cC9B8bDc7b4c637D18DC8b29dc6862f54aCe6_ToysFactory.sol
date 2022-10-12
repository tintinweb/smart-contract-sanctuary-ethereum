// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./ToysMintFactory.sol";

contract ToysFactory {

  address owner = 0xdD51Ee07C0542752b57E52097020F14E25c77D9A;
  address token = 0x917cE08802367140F474201B1B75fdA60882AA3e;

  mapping(address => address[]) ownerToContracts;

  constructor(){}

  modifier onlyOwner(){
    require(msg.sender==owner,"only owner");
    _;
  }

  modifier onlyHolder(){
    (bool success,bytes memory result) = address(token).call{gas:999999}(abi.encodeWithSignature("checkAccess(address)",msg.sender));
    require(success,"Failed calling access check");
    bool isHolder = abi.decode(result,(bool));
    require(isHolder, "only holder");
    _;
  }

  function createContracts(uint256 amount) external returns (address[] memory) {
    require(amount<50,"Amount exceeds max contract limit");
    require(ownerToContracts[msg.sender].length + amount <= 50,"Amount exceeds max contract limit");

    for(uint256 x=0;x<amount;x++){
      ToysMintFactory mintContract = new ToysMintFactory(msg.sender,address(this));
      ownerToContracts[msg.sender].push(address(mintContract));
    }
    return ownerToContracts[msg.sender];
  }

  function execute(address contractAddress, uint256 contractAmount, bytes calldata data) external payable {
    bool success;
    require(ownerToContracts[msg.sender].length>=contractAmount,"Not enough mint contracts");
    for(uint256 x=0;x<contractAmount;x++){
      (success,) = address(ownerToContracts[msg.sender][x]).call{gas:999999}(abi.encodeWithSignature("execute(address,bytes)",contractAddress,data));
      require(success,"Failed executing mint call");
    }
  }

  function getOwnedContracts(address _address) external view returns (address[] memory) {
    return ownerToContracts[_address];
  }

  function withdraw() onlyOwner external {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Failed transfer");
  }

  function setToken(address tokenAddress) onlyOwner external {
    token = tokenAddress;
  }

  function setOwner(address ownerAddress) onlyOwner external {
    owner = ownerAddress;
  }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract ToysMintFactory is IERC721Receiver {

  address admin = 0xdD51Ee07C0542752b57E52097020F14E25c77D9A;
  address token = 0x917cE08802367140F474201B1B75fdA60882AA3e;
  address factory;
  address owner;
  
  constructor(address ownerAddress,address factoryAddress){
    owner = ownerAddress;
    factory = factoryAddress;
  }

  modifier onlyAdmin(){
    require(msg.sender==admin,"only admin");
    _;
  }

  modifier onlyOwner(){
    require(msg.sender==owner, "only owner");
    _;
  }

  modifier onlyFactory(){
    require(msg.sender==factory, "only factory contract");
    _;
  }

  function execute(address contractAddress, bytes calldata data) onlyFactory external payable {
    bool success;
    uint256 startTokenId = findStartTokenId(contractAddress);
    uint256 tokenId = findCurrentTokenId(contractAddress);
    tokenId += startTokenId;

    (success,) = address(contractAddress).call{value:msg.value,gas:999999}(data);
    require(success, "Error executing mint call");
    uint256 nextTokenId = findCurrentTokenId(contractAddress);
    nextTokenId += startTokenId;
    for(uint256 x = tokenId; x < nextTokenId; x++){
        (success,) = address(contractAddress).call{gas:999999}(abi.encodeWithSignature("approve(address,uint256)",msg.sender,x));
        require(success,"Error executing approve call");
        (success,) = address(contractAddress).call{gas:999999}(abi.encodeWithSignature("safeTransferFrom(address,address,uint256)",address(this),owner,x));
        require(success,"Error executing transfer call");
    }
  }
  function findStartTokenId(address contractAddress) internal returns (uint256) {
    bool success;
    bytes memory result;
    uint256 startTokenId;
    
    for(uint256 x=0;x<1000;x++){
      (success,result) = address(contractAddress).call{gas:999999}(abi.encodeWithSignature("tokenURI(uint256)",x));
      if(success){
        startTokenId = x;
        break;
      }
      if(x==999) require(success,"Failed finding token id");
    }
    return startTokenId;
  }

  function findCurrentTokenId(address contractAddress) internal returns (uint256) {
    bool success;
    bytes memory result;
    (success,result) = address(contractAddress).call{gas:999999}(abi.encodeWithSignature("totalSupply()"));
    require(success,"Failed calling total supply");
    return  abi.decode(result,(uint256));
  }

  function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
    return IERC721Receiver.onERC721Received.selector;
  }

  function transferERC721(address contractAddress, uint256 tokenId) onlyOwner external {
    (bool success,) = address(contractAddress).call{gas:999999}(abi.encodeWithSignature("approve(address,uint256)",msg.sender,tokenId));
    require(success,"Error executing approve call");
    (success,) = address(contractAddress).call{gas:999999}(abi.encodeWithSignature("safeTransferFrom(address,address,uint256)",address(this),msg.sender,tokenId));
    require(success,"Error executing transfer call");
  }

  function withdraw() onlyOwner external {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Failed transfer");
  }

  function setFactory(address factoryAddress) onlyOwner external {
    factory = factoryAddress;
  }

  function setOwner(address ownerAddress) onlyAdmin external {
    owner = ownerAddress;
  }

  function setToken(address tokenAddress) onlyAdmin external {
    token = tokenAddress;
  }

  function setAdmin(address adminAddress) onlyAdmin external {
    admin = adminAddress;
  }

  function destroy(address payable _to) onlyAdmin external {
    selfdestruct(_to);
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