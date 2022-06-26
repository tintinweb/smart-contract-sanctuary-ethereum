/**
 *Submitted for verification at Etherscan.io on 2022-06-26
*/

pragma solidity >0.4.23 <0.9.0;

interface Wriggler{
    function yeet(address target) external;
    function yoink() external;
}

contract EphemeralWrigglerVault {
    address constant wriggler = 0xCA5d26fda442bbF604f20CC88289Ea1661863C44;

    function pull() public {
        Wriggler(wriggler).yoink();
    }

    function push(address target) public {
        Wriggler(wriggler).yeet(target);
    }

    function onERC721Received(address, address, uint256, bytes calldata) pure external returns(bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
}

contract CloneFactory {

  function createClone(address target) internal returns (address result) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(clone, 0x14), targetBytes)
      mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
      result := create(0, clone, 0x37)
    }
  }

  function isClone(address target, address query) internal view returns (bool result) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000)
      mstore(add(clone, 0xa), targetBytes)
      mstore(add(clone, 0x1e), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)

      let other := add(clone, 0x40)
      extcodecopy(query, other, 0, 0x2d)
      result := and(
        eq(mload(clone), mload(other)),
        eq(mload(add(clone, 0xd)), mload(add(other, 0xd)))
      )
    }
  }
}

contract YoinkFactory is CloneFactory {
    address private lib;

    constructor(address _lib) {
        lib = _lib;
    }
    
    function yeetChain(address target) public {
        address clone1 = createClone(lib);
        address clone2 = createClone(lib);
        address clone3 = createClone(lib);
        address clone4 = createClone(lib);
        EphemeralWrigglerVault(clone1).pull();
        EphemeralWrigglerVault(clone1).push(clone2);
        EphemeralWrigglerVault(clone2).push(clone3);
        EphemeralWrigglerVault(clone3).push(clone4);
        EphemeralWrigglerVault(clone4).push(target);
    }
}