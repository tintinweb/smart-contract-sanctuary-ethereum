// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Counters.sol";

contract Mock {
    int256 public testID;    
    using Counters for Counters.Counter;
    // Unique Ids for each entity
    Counters.Counter public MockIds;
    
    constructor(int256 tt){
        MockIds.increment(); 
        testID=tt;
    }
    function getTT() public view returns(int256){      
        return testID;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Counters.sol";

contract Mock2 {
    uint256 public testID;    
    using Counters for Counters.Counter;
    // Unique Ids for each entity
    Counters.Counter public MockIds;
    
    constructor(uint256 tt){
        MockIds.increment(); 
        testID=tt;
    }
    function getTT() public view returns(uint256){      
        return testID;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;
import "./Mock.sol";
import "./Mock2.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract MockFactory {
    int256 public ids;    
    address[] public allMocks;
    address[] public allMocks2;
    using Counters for Counters.Counter;
    // Unique Ids for each entity
    Counters.Counter public MockFactoryIds;
    Counters.Counter public Mock2FactoryIds;

    constructor(int256 tt){
        MockFactoryIds.increment();
        Mock2FactoryIds.increment();
        ids=tt;
    }
    function getResult() public view returns(int256){      
        return ids;
    }
    function createMock( 
        int256 _entityId
    ) external returns (address mock) {

        bytes memory bytecode = abi.encodePacked(
                                    type(Mock).creationCode, 
                                    abi.encode(
                                        _entityId
                                    )
                                );

        bytes32 salt = keccak256(abi.encodePacked(msg.sender));

        assembly {
            mock := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }        
        allMocks.push(mock);
    }

    function createMock2() external returns (address mock) {
        
        uint256 entity =Mock2FactoryIds.current();
        Mock2FactoryIds.increment();
        bytes memory bytecode = abi.encodePacked(
                                    type(Mock2).creationCode, 
                                    abi.encode(
                                        entity
                                    )
                                );

        bytes32 salt = keccak256(abi.encodePacked(entity));

        assembly {
            mock := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }        
        allMocks2.push(mock);
    }
}