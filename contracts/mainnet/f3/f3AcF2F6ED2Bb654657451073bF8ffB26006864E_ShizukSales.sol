/**
 *Submitted for verification at Etherscan.io on 2022-06-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// Interfaces
interface IERC721 {
  function mint(
    address _to,
    bytes12 _traitCode,
    string memory _metadataHash,
    string memory _contentHash) external returns (bool);
}

// Abstract Contracts
abstract contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(owner == msg.sender, "Ownable: caller is not the owner");
    _;
  }

  function transferOwnership(address _newOwner) public virtual onlyOwner {
    require(_newOwner != address(0), "Ownable: new owner is the zero address");
    owner = _newOwner;
  }
}

// Contract
contract ShizukSales is Ownable {
  IERC721 public nft;
  address payable public treasury;
  mapping (address => bool) public signers;
  uint256 public price;
    
  constructor() {
    treasury = payable(msg.sender);
  }

  function setNft(address _nftAddress) external onlyOwner returns (bool) {
    require(address(nft) == address(0), 'ShizukSales: NFT address is already set');
    nft = IERC721(_nftAddress);
    return true;
  }

  function setTreasury(address payable _treasury) external onlyOwner returns (bool) {
    treasury = _treasury;
    return true;
  }

  function setSigner(address _signer) external onlyOwner returns (bool) {
    require(!signers[_signer], 'ShizukSales: _signer is already a signer');
    signers[_signer] = true;
    return true;
  }

  function removeSigner(address _signer) external onlyOwner returns (bool) {
    require(signers[_signer], 'ShizukSales: _signer is not a signer');
    signers[_signer] = false;
    return true;
  }

  function setPrice(uint256 _price) external onlyOwner returns (bool) {
    price = _price;
    return true;
  }

  function purchase(
    address _to,
    bytes12 _traitCode,
    string memory _metadataHash,
    string memory _contentHash,
    bytes memory _sig) external payable returns (bool) {
    require(msg.value >= price, 'ShizukSales: insufficient msg.value');
    require(signers[getSigner(_traitCode, _metadataHash, _contentHash, _sig)], 'SizukSales: invalid signature');
    if(msg.value > 0) treasury.transfer(msg.value);
    nft.mint(_to, _traitCode, _metadataHash, _contentHash);
    return true;
  }

  function getSigner(
    bytes12 _traitCode,
    string memory _metadataHash,
    string memory _contentHash,
    bytes memory _sig) private pure returns (address) {
    bytes32 hash = keccak256(abi.encodePacked(_traitCode, _metadataHash, _contentHash));
    return recover(hash, _sig);
  }

  function recover(bytes32 _hash, bytes memory _sig) public pure returns (address) {
    bytes32 r;
    bytes32 s;
    uint8 v;

    //Check the signature length
    if (_sig.length != 65) {
      return (address(0));
    }

    // Divide the signature in r, s and v variables
    assembly {
      r := mload(add(_sig, 32))
      s := mload(add(_sig, 64))
      v := byte(0, mload(add(_sig, 96)))
    }

    // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
    if (v < 27) {
      v += 27;
    }

    // If the version is correct return the signer address
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
      return ecrecover(_hash, v, r, s);
    }
  }
}