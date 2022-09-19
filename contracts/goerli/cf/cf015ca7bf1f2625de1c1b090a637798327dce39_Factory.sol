/**
 *Submitted for verification at Etherscan.io on 2022-09-19
*/

// File: contracts/Create2.sol


pragma solidity 0.8.17;

contract Factory {
    mapping (address => address) _implementations;

    event Deployed(address _add);

    function deploy(uint salt, bytes calldata bytecode) public {
        bytes memory implInitCode = bytecode;
        
        // assign the initialization code for the metamorphic contract
        bytes memory metamorphicCode  = (
          hex"5860208158601c335a63aaf10f428752fa158151803b80938091923cf3"
        );


        // determine the address of the metamorphic contract
        address metamorphicContractAddress = _getMetamorphicContractAddress(salt, metamorphicCode);

        // declare a variable for the address of the implementation contract.
        address implementationContract;

        // load implementation init code and length, then deploy via CREATE2.
        /*solhint-disable no-inline-assembly*/
        assembly {
          let encoded_data := add(0x20, implInitCode) // load initialization code.
          let encoded_size := mload(implInitCode)     // load init code's length.
          implementationContract := create(       // call CREATE with 3 arguments.
            0,                                    // do not forward any endowment.
            encoded_data,                         // pass in initialization code.
            encoded_size                          // pass in init code's length.
          )
        } /* solhint-enable no-inline-assembly */

        // First we deploy the code we want to deploy on a separate address
        // store the implementation to be retrieved by the metamorphic contract
        _implementations[metamorphicContractAddress] = implementationContract;

        address addr;
        assembly {
            let encoded_data := add(0x20, metamorphicCode) // loat the init code.
            let encoded_size := mload(metamorphicCode) // load code's length.
            addr := create2(0, encoded_data, encoded_size, salt)
        }

        require(
            addr == metamorphicContractAddress,
            "Failed to deploy the new metamorphic contract"
        );

        emit Deployed(addr);
    }

    /**
    * @dev Internal view func for calculating a metamorphic contract address
    * given a particulart salt.
    */
    function _getMetamorphicContractAddress(
        uint256 salt,
        bytes memory metamorphicCode
    ) internal view returns (address) {
        // determine the address of the metamorphic contract.
        return address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            address(this),
                            salt,
                            keccak256(
                                abi.encodePacked(
                                    metamorphicCode
                                )
                            ) // the init code hash
                        )
                    )
                )
            )
        );
    }

    // those two functions are getting called by the metamorphic Contract
    function getImplementation() external view returns (address implementation) {
        return _implementations[msg.sender];
    }
}

contract Test1 {
    uint public myUint;

    function setUint(uint _myUint) public {
        myUint = _myUint;
    }

    function killContract() public {
        selfdestruct(payable(msg.sender));
    }
}

contract Test2 {
    uint public myUint;
    
    function setUint(uint _myUint) public {
        myUint = 2 * _myUint;
    }

    function killContract() public {
        selfdestruct(payable(msg.sender));
    }
}