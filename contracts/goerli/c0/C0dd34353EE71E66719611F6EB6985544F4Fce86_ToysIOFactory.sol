// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ToysProxy.sol";

/// @title Toys IO Factory
/// @author saarbrooklynkid
/// @notice IO Factory

contract ToysIOFactory {

  address owner;
  address token;
  address delegate;
  uint16 maxContractAmount = 101;
  uint16 maxAmountPerCall = 11;

  mapping(address => address[]) ownerToContracts;

  constructor(address _owner, address _token, address _delegate){
    owner = _owner;
    token = _token;
    delegate = _delegate;
  }

  modifier onlyOwner(){
    require(msg.sender==owner,"only owner");
    _;
  }

  modifier onlyHolder(){
    (bool success,bytes memory result) = address(token).call{gas:999999}(abi.encodeWithSignature("checkAccess(address)",msg.sender));
    require(success,"Error calling access check");
    bool isHolder = abi.decode(result,(bool));
    require(isHolder, "only holder");
    _;
  }

  function createContracts(uint16 amount) onlyHolder external {
    require(amount < maxAmountPerCall,"Max contract amount per call reached");
    require(ownerToContracts[msg.sender].length+amount < maxContractAmount,"Max Contract amount reached");

    for(uint16 x=0;x<amount;x++){
      ToysProxy proxyContract = new ToysProxy(delegate,msg.sender,address(this));
      ownerToContracts[msg.sender].push(address(proxyContract));
    }
  }

  function execute(address _address, uint16 _amount, bytes calldata data) onlyHolder external payable {
    bool success;
    address[] memory contracts = ownerToContracts[msg.sender];
    uint256 amountPerCall = msg.value/_amount;

   /* require(contracts.length>0,"No saved mint contracts");

    if(contracts.length<_amount){
      _amount=uint16(contracts.length);
    }

    if(_amount>maxContractAmount){
      _amount=maxContractAmount;
    }*/

    for(uint16 x=0;x<_amount;x++){
      (success,) = address(contracts[x]).call{value:amountPerCall,gas:999999}(abi.encodeWithSignature("execute(address,bytes)",_address,data));
      require(success,"Error executing call to proxy");
    }
  }

  function transferContracts(address to) onlyHolder external {
    for(uint16 x=0;x<ownerToContracts[msg.sender].length;x++){
      ownerToContracts[to].push(ownerToContracts[msg.sender][x]);
      (bool success,) = address(ownerToContracts[msg.sender][x]).call{gas:999999}(abi.encodeWithSignature("setOwner(address)",to));
      require(success,"Error setting owner");
    }
    delete ownerToContracts[msg.sender];
  }

  function transferContracts(address from, address to) onlyOwner external {
    for(uint16 x=0;x<ownerToContracts[from].length;x++){
      ownerToContracts[to].push(ownerToContracts[from][x]);
      (bool success,) = address(ownerToContracts[from][x]).call{gas:999999}(abi.encodeWithSignature("setOwner(address)",to));
      require(success, "Error setting owner");
    }
    delete ownerToContracts[from];
  }

  function addContracts(address to, address[] calldata _mintContracts) onlyOwner external {
    for(uint16 x=0;x<_mintContracts.length;x++){
      ownerToContracts[to].push(_mintContracts[x]);
    }
  }

  function destroyContracts() onlyHolder external {
    for(uint16 x=0;x<ownerToContracts[msg.sender].length;x++){
      (bool success,) = address(ownerToContracts[msg.sender][x]).call{gas:999999}(abi.encodeWithSignature("destroy(address)",msg.sender));
      require(success, "Error destroying contract");
    }
    delete ownerToContracts[msg.sender];
  }

  function destroyContracts(address _address) onlyOwner external {
    for(uint16 x=0;x<ownerToContracts[_address].length;x++){
      (bool success,) = address(ownerToContracts[_address][x]).call{gas:999999}(abi.encodeWithSignature("destroy(address)",_address));
      require(success, "Error destroying contract");
    }
    delete ownerToContracts[_address];
  }

  function getOwnedContracts(address _address) external view returns (address[] memory) {
    return ownerToContracts[_address];
  }
  
  function setToken(address _token) onlyOwner external {
    token = _token;
  }

  function setDelegate(address _delegate) onlyOwner external {
    delegate = _delegate;
  }

  function setOwner(address _owner) onlyOwner external {
    owner = _owner;
  }

  function withdraw() onlyOwner external {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Error transfer");
  }

  function destroy(address payable _to) onlyOwner external {
    selfdestruct(_to);
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract ToysProxy is IERC721Receiver{
    address delegate;
    address owner;
    address factory;

    constructor(address _delegate, address _owner, address _factory){
        delegate = _delegate;
        owner = _owner;
        factory = _factory;
    }

    modifier onlyFactory(){
        require(msg.sender==factory);
        _;
    }

    fallback() external payable {
        require(tx.origin==owner,"Can not call fallback");
        assembly {
            let _target := sload(0)
            calldatacopy(0x0, 0x0, calldatasize())
            let result := delegatecall(gas(), _target, 0x0, calldatasize(), 0x0, 0)
            returndatacopy(0x0, 0x0, returndatasize())
            switch result case 0 {revert(0, 0)} default {return (0, returndatasize())}
        }
    }

    function setDelegate(address _delegate) public onlyFactory {
        delegate = _delegate;
    }

    function setOwner(address _owner) public onlyFactory {
        owner = _owner;
    }

    function setFactory(address _factory) public onlyFactory {
        factory = _factory;
    }

    function destroy(address payable _to) external onlyFactory {
        selfdestruct(_to);
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
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