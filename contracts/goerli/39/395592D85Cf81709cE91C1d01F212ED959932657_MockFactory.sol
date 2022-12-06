// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

contract Mock {
    int256 public testID;    

    constructor(int256 tt){
        testID=tt;
    }
    function getTT() public view returns(int256){      
        return testID;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;
import "./Mock.sol";

contract MockFactory {
    int256 public ids;    

    constructor(int256 tt){
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

        bytes32 salt = keccak256(abi.encodePacked(_entityId));

        assembly {
            mock := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }        
    }
}