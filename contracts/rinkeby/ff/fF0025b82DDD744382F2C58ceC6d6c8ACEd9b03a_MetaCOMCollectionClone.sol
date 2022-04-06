// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./IMetaCOMCollection.sol";

contract MetaCOMCollectionClone {
  address public cloneImplementation;

  event NewCollection(address indexed collection);

  constructor(address _cloneImplementation) {
    cloneImplementation = _cloneImplementation;
  }

  function doClone(
    IMetaCOMCollection.CollectionConfig memory _collectioinConfig,
    IMetaCOMCollection.AuctionConfig memory _auctionConfig,
    bytes32 whitelistMerkleRoot,
    bytes32 claimMerkleRoot,
    IMetaCOMCollection.RoyaltiesConfig memory _royaltiesConfig
  ) external {
    address collection = Clones.clone(cloneImplementation);

    IMetaCOMCollection.DropConfig memory _whitelistDropConfig;
    IMetaCOMCollection.DropConfig memory _claimDropConfig;

    if(whitelistMerkleRoot > 0){
      _whitelistDropConfig.active = true;
      _whitelistDropConfig.free = false;
      _whitelistDropConfig.startTime = _auctionConfig.startTime;
      _whitelistDropConfig.merkleRoot = whitelistMerkleRoot;
    }

    if(claimMerkleRoot > 0){
      _claimDropConfig.active = true;
      _claimDropConfig.free = true;
      _claimDropConfig.startTime = _auctionConfig.startTime - 86400;//24h before launch datae
      _claimDropConfig.merkleRoot = whitelistMerkleRoot;
    }

    IMetaCOMCollection(collection).initialize(
      _collectioinConfig, 
      _auctionConfig,
      _whitelistDropConfig, 
      _claimDropConfig, 
      _royaltiesConfig
    );

    emit NewCollection(collection);

  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IMetaCOMCollection {

  enum AuctionType{ Fixed, Dutch }//, English
  enum DropType{ Whitelist, Claim }//, Basic

  struct CollectionConfig {
    string name;
    string symbol;
    string baseURI;
    uint256 size;
  }

  struct AuctionConfig {
    AuctionType auctionType;
    uint256 startTime;
    uint256 startPrice;
    uint256 endTime;
    uint256 endPrice;
    uint256 maxPerAddressDuringMint;
  }

  struct DropConfig {
    bool active;
    bool free;
    uint256 startTime;
    bytes32 merkleRoot;
  }

  struct RoyaltiesConfig {
    address receiver;
    uint96 feeNumerator;
  }

  function initialize(
    CollectionConfig memory _collectioinConfig, 
    AuctionConfig memory _auctionConfig,
    DropConfig memory _whitelistDropConfig,
    DropConfig memory _claimDropConfig,
    RoyaltiesConfig memory _royaltiesConfig
  ) external;


  function owner() external view returns (address);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}