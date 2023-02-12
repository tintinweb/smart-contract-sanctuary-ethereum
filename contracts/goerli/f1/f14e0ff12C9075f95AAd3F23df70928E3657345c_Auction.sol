// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

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
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
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
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
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
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/* imports */
import "@openzeppelin/contracts/proxy/Clones.sol";
import "../interfaces/IEvent.sol";

/* errors */
error Auction__TokenIdsDoNotMatchTokenSupplies(
  uint256 idsLength,
  uint256 suppliesLength
);
error Auction__OnlyEventOwnerCanCall(address caller);
error Auction__BidTooLow();
error Auction__NotEnoughFunds();
error Auction__UnauthorizedCaller();

contract Auction {
  /* structs and enums */
  struct Event {
    string name;
    address organizer;
    string baseMetadataURI;
    uint[] tokenIds;
    uint[] tokenSupplies;
    uint[] tokenStatus;
    uint[] minBids;
  }

  /*  state variables */
  address immutable eventImplementation;
  mapping(address => Event) addrToEvent;
  mapping(address => address) addrToOrg;
  mapping(address => uint) addrToNoOfTokenTypes;
  mapping(address => mapping(uint => address[])) addrToIdToQueue;
  mapping(address => mapping(uint => uint)) addrToIdToMinBid;

  /* events */
  event EventListed(
    address indexed eventAddress,
    string indexed baseMetaDataURI,
    Event event0
  );

  /* constructor */
  constructor(address _eventImplementation) {
    eventImplementation = _eventImplementation;
  }

  /* external functions */
  function createEvent(
    string memory _name,
    string memory _baseMetadataURI,
    uint256[] memory _tokenIds,
    uint256[] memory _tokenSupplies,
    uint256[] memory _tokenStatus,
    uint256[] memory _minBids
  ) external {
    if (_tokenIds.length != _tokenSupplies.length) {
      revert Auction__TokenIdsDoNotMatchTokenSupplies(
        _tokenIds.length,
        _tokenSupplies.length
      );
    }
    address eventAddress = Clones.clone(eventImplementation);
    IEvent(eventAddress).initialize(
      msg.sender,
      address(this),
      _baseMetadataURI
    );
    Event memory newEvent = Event(
      _name,
      address(this),
      _baseMetadataURI,
      _tokenIds,
      _tokenSupplies,
      _tokenStatus,
      _minBids
    );
    addrToNoOfTokenTypes[eventAddress] = _tokenIds.length;
    addrToEvent[eventAddress] = newEvent;
    addrToOrg[eventAddress] = msg.sender;

    for (uint i = 0; i < _tokenIds.length; i++) {
      addrToIdToMinBid[eventAddress][i] = _minBids[i];
    }
    emit EventListed(eventAddress, _baseMetadataURI, newEvent);
  }

  function updateMinBid(
    address _eventAddress,
    uint _tokenId,
    uint _newBid
  ) external {
    addrToIdToMinBid[_eventAddress][_tokenId] = _newBid;
  }

  function placeBid(
    address _eventAddress,
    uint _tokenId,
    uint _amount
  ) external {
    if (_amount < addrToIdToMinBid[_eventAddress][_tokenId]) {
      revert Auction__BidTooLow();
    }
    if (msg.sender.balance < addrToIdToMinBid[_eventAddress][_tokenId]) {
      revert Auction__NotEnoughFunds();
    }
    addrToIdToQueue[_eventAddress][_tokenId].push(msg.sender);
  }

  function settleAuction(address _eventAddress) external {
    if (msg.sender != addrToOrg[_eventAddress]) {
      revert Auction__UnauthorizedCaller();
    }
    for (uint i = 0; i < addrToNoOfTokenTypes[_eventAddress]; i++) {
        delete addrToIdToQueue[_eventAddress][i];
    delete addrToIdToMinBid[_eventAddress][i];
      for (uint j = 0; j < addrToIdToQueue[_eventAddress][i].length; j++) {
        IEvent(_eventAddress).mint(addrToIdToQueue[_eventAddress][i][j], i, 1);
      }
    }

    delete addrToEvent[_eventAddress];
    delete addrToOrg[_eventAddress];
    delete addrToNoOfTokenTypes[_eventAddress];
  }

  //   function buyNow(
  //     address _eventAddress,
  //     uint _tokenId,
  //     uint _amountOfTokens
  //   ) external {}

  // function transferBalance() external {}
  // function deleteAuction() external {}
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/* COLLECTION INTERFACE */
interface IEvent {
  function initialize(address _organizer, address _auctionContract, string memory _baseMetadataURI) external;

  function mint(
    address _to,
    uint256 _id,
    uint256 _amount
  ) external;
}