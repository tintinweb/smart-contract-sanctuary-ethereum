/**
 *Submitted for verification at Etherscan.io on 2022-07-05
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

library Counters {
    struct Counter {
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

contract SubscriptionToken {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    address public owner = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    mapping(address => bool) public isSubsribed;
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function subscribe() public payable {
        require(msg.value == 1);
        
        isSubsribed[msg.sender] = true;
    }
    
    function subscribeByOwner(address account) public onlyOwner {
        isSubsribed[account] = true;
    }
}

contract SBTFactory{
    event Deployed(address contractAddress);

    function deployNew(uint256 _salt) external returns(address newContract){
        bytes memory bytecode = type(SubscriptionToken).creationCode;
        bytes32 salt = bytes32(_salt);
        assembly {
            newContract := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        emit Deployed (newContract);
    }

    function getAddress(bytes memory bytecode, uint256 _salt)
        public
        view
        returns (address)
    {
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff), address(this), _salt, keccak256(bytecode)
            )
        );

        return address(uint160(uint256(hash)));
    }

    function getBytecode(address _owner) public pure returns (bytes memory) {
        bytes memory bytecode = type(SubscriptionToken).creationCode;
        return abi.encodePacked(bytecode, abi.encode(_owner));
    }
}