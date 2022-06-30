// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./Moneypipe.sol";

contract MoneypipeFactory {
  event ContractDeployed(address indexed owner, address indexed group, string title);
  
  address public immutable implementation;
  
  constructor() {
    implementation = address(new Stream());
  }
  
  function genesis(string calldata title, Stream.Member[] calldata members) external returns (address) {
    address payable clone = payable(Clones.clone(implementation));
    
    Stream stream = Stream(clone);
    stream.initialize(members);

    emit ContractDeployed(msg.sender, clone, title);

    return clone;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

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
        /// @solidity memory-safe-assembly
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
        /// @solidity memory-safe-assembly
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Stream {

  bool private _initializing;
  bool private _entered;

  mapping(address => uint256) private _pendingWithdrawals;

  uint32 private _total;
  struct Member {
    address account;
    uint32 value;
  }
  
  Member[] private _members;

  modifier initializer() {
    require(!_initializing, "Initializable: contract is not initializing");
    _;
  }
  modifier nonReentrant() {
    require(!_entered, "reentrant call");
    _entered = true;
    _;
    _entered = false;
    }

  function initialize(Member[] calldata memberData) initializer public {
    require(memberData.length > 0, "Initializable: must have at least one member");
    
    for(uint16 i = 0; i < memberData.length; i++) {
      _members.push(memberData[i]);
      _total += memberData[i].value;
    }

    _initializing = true;
  }

  receive () external payable {
    require(_members.length > 0, "Stream: contract is not initialized");
    
    for(uint i=0; i<_members.length; i++) {
      Member memory member = _members[i];
      _transfer(member.account, msg.value * member.value / _total);
    }
  }

  function members() external view returns (Member[] memory) {
    return _members;
  }

  function _transfer(address to, uint256 amount) internal {
    (bool success, ) = to.call{ value: amount, gas: 20000 }("");
    
    if (!success) {
      _pendingWithdrawals[to] += amount;
    }
  }

  function getPendingWithdrawal(address user) external view returns (uint256 balance) {
    return _pendingWithdrawals[user];
  }

  function withdrawFor(address payable user) public nonReentrant {
    uint256 amount = _pendingWithdrawals[user];
    require(amount != 0, "No Funds Available"); 
    
    _pendingWithdrawals[user] = 0;
    (bool success, ) = user.call{ value: amount, gas: 20000 }("");
    if (!success) {
      revert("withdrawFor failed");
    }
  }
}