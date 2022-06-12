// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AkriptERC721{
    //We will call it immediately once the clone contract is created.
    function initialize (address _owner, string memory name, string memory symbol) external;
}

contract AkriptERC721Factory{
    //The address of AkriptERC721.sol
    address public implementation;
    
    //Keeps track of all deployed clones. The first address is the msg.sender or the owner of the clone.
    mapping(address=>address[])public allClones;
    event NewClone(address _newClone, address _owner);

    constructor(address _implementation){
        implementation = _implementation;
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `AkriptERC721`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address _implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, _implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }


    /**
      * @dev This is the function that users will call. Once someone calls this function, the first * thing that is going to happen is create a new clone and save it under address 
      * identicalChild.This address will hold the same logic as AkriptERC721.sol, but with its 
      * own storage state.
     */
    function _clone(string memory name, string memory symbol) external {
        address identicalChild = clone(implementation);
        allClones[msg.sender].push(identicalChild);
        AkriptERC721(identicalChild).initialize(msg.sender, name, symbol);
        emit NewClone(identicalChild, msg.sender);
    }

    function returnClones(address _owner) external view returns (address[] memory){
        return allClones[_owner];
    }
}