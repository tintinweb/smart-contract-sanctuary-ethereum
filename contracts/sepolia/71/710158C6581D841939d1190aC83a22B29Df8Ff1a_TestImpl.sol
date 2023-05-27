pragma solidity ^0.8.6;

error TestError(string arg);
error Test3Error();

contract TestImpl {
    
    function test1(string memory arg1, address impl) public returns(string memory) {
        if (bytes(arg1).length == 3) {
            revert TestError(arg1);
        }

        return "ok";
    }

    function test2() public {
        revert("blaboa");
    }

    function test3() public {
        revert Test3Error();
    }
}

contract Test {
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    function test1(string memory arg1, address impl) public returns(string memory) {
        _delegate(impl);
    }
}