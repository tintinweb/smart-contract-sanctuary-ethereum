/**
 *Submitted for verification at Etherscan.io on 2022-07-05
*/

// SPDX-License-Identifier: MIT
// File: NowLoading/lib/Interfaces.sol

pragma solidity ^0.8.0;

// Interfaces
interface IERC20 {
  function approve(address _spender, uint256 _amount) external returns (bool);
  function transfer(address _to, uint256 _amount) external returns (bool);
  function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);
}

interface IERC165 {
  function supportsInterface(bytes4 _interfaceId) external view returns (bool);
}

interface IERC721 {
  function balanceOf(address _owner) external view returns (uint256 balance);
  function ownerOf(uint256 _tokenId) external view returns (address owner);
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) external payable;
  function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
  function approve(address _to, uint256 _tokenId) external payable;
  function setApprovalForAll(address _operator, bool _approved) external;
  function getApproved(uint256 _tokenId) external view returns (address operator);
  function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

interface IERC721Metadata {
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function tokenURI(uint256 _tokenId) external view returns (string memory);
}

interface IERC721Receiver {
  function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns (bytes4);
}
// File: NowLoading/RedeemPool.sol



pragma solidity ^0.8.0;


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

contract RedeemPool is Ownable, IERC721Receiver {
  mapping(uint256 => bytes) private signatures;
  address private nft;
  address private signer;

  constructor() {}

  // External Functions
  function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external override returns (bytes4) {
    return bytes4(keccak256("onERC721Received(address,uint256,bytes)"));
  }

  function redeem(string memory _redeemCode, address _to) external returns (bool) {
    uint256 tokenId = validateRedeemCode(_redeemCode);
    require(tokenId > 0, "RedeemPool: invalid redeemCode");
    IERC721(nft).transferFrom(address(this), _to, tokenId);
    return true;
  }

  // Admin Functions
  function setNft(address _nft) external onlyOwner returns (bool) {
    nft = _nft;
    return true;
  }

  function setSigner(address _signer) external onlyOwner returns (bool) {
    signer = _signer;
    return true;
  }

  function setSignature(uint256 _tokenId, bytes memory _sig) external onlyOwner returns (bool) {
    signatures[_tokenId] = _sig;
    return true;
  }

  function bulkSetSignature(uint256[] memory _ids, bytes[] memory _sigs) external onlyOwner returns (bool) {
    require(_ids.length == _sigs.length, "RedeemPool: element counts not matched");
    for(uint256 i = 0; i < _ids.length; i++) {
      signatures[_ids[i]] = _sigs[i];
    }
    return true;
  }

  // Private Functions
  function validateRedeemCode(string memory _redeemCode) private view returns (uint256) {
    uint256 tokenId = toUint(substr(_redeemCode, 0, 4));
    bytes32 hash = keccak256(abi.encodePacked(_redeemCode));
    return (recover(hash, signatures[tokenId]) == signer) ? tokenId : 0;
  }

  function substr(string memory str, uint startIndex, uint endIndex) private pure returns (string memory ) {
    bytes memory strBytes = bytes(str);
    bytes memory result = new bytes(endIndex-startIndex);
    for(uint i = startIndex; i < endIndex; i++) {
      result[i-startIndex] = strBytes[i];
    }
    return string(result);
  }

  function toUint(string memory str) private pure returns (uint256 result) {
    bytes memory b = bytes(str);
    uint i;
    result = 0;
    for (i = 0; i < b.length; i++) {
      uint8 c = uint8(b[i]);
      if (c >= 48 && c <= 57) {
        result = result * 10 + (c - 48);
      }
    }
  }

 function recover(bytes32 _hash, bytes memory _sig) private pure returns (address) {
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