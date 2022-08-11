/**
 *Submitted for verification at Etherscan.io on 2022-08-11
*/

//SPDX-License-Identifier:MIT

pragma solidity ^0.8.13;

interface Implementation{
    function initialize(address _owner) external;
    function setX(uint _X) external;
    function getX() external;
    }

contract CloneFactory{
    //The base contract (Implementation.sol)
    address public implementation;

    //mapping to have a track of all the deployments
    mapping(address => address[]) public allClones;

    event NewClone(address _newClone, address _owner);

    constructor(address _implementation){
        implementation = _implementation;
    }

    /* Deploys and returns the address of clone that mimics the behaviour of 'Implementation.sol'.
    This function uses the create opcodes, which should never revert.
    */

    function _clone(address _implementation) internal returns(address instance){
        assembly{
            let ptr :=mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), _implementation)
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERROR: clone failed");
    }

    function clone() external{
        address identicalChild = _clone(implementation);
        allClones[msg.sender].push(identicalChild);
        Implementation(identicalChild).initialize(msg.sender);
        Implementation(identicalChild).setX(10);
        Implementation(implementation).getX();
        emit NewClone(identicalChild,msg.sender);
    }

    function setXImplementation(uint _x) external{
        Implementation(implementation).setX(_x);
    }
    function setXIdenticalChild(uint _x) external{
        Implementation(_clone(implementation)).setX(_x);
    }


    function returnClones(address _owner) external view returns(address[] memory){
        return allClones[_owner];
    }


}