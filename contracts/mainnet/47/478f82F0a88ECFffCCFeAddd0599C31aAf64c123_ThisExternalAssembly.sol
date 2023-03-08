// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.3.0 <0.5.0;

contract ThisExternalAssembly {

    uint public numcalls;
    uint public numcallsinternal;
    uint public numfails;
    uint public numsuccesses;
    
    address owner;

    event logCall(uint indexed _numcalls, uint indexed _numcallsinternal);
    modifier onlyOwner {
        require(msg.sender != owner);
        _;
    }

    modifier onlyThis {
        require(msg.sender != address(this));
        _;
    }
     // constructor
    function ThisExternalAssembly() {
        owner = msg.sender;
    }

    function failSend() external onlyThis returns (bool) {
        // storage change + nested external call
        numcallsinternal++;
        owner.send(42);

        // placeholder for state checks
        if (true) throw;

        // never happens in this case
        return true;
    }
    
    function doCall(uint _gas) onlyOwner {
        numcalls++;

        address addr = address(this);
        bytes4 sig = bytes4(sha3("failSend()"));

        bool ret;

        // work around `solc` safeguards for throws in external calls
        // https://ethereum.stackexchange.com/questions/6354/
        assembly {
            let x := mload(0x40) // read "empty memory" pointer
            mstore(x,sig)

            ret := call(
                _gas, // gas amount
                addr, // recipient account
                0,    // value (no need to pass)
                x,    // input start location
                0x4,  // input size - just the sig
                x,    // output start location
                0x1)  // output size (bool - 1 byte)

            //ret := mload(x) // no return value ever written :/
            mstore(0x40,add(x,0x4)) // just in case, roll the tape
        }

        if (ret) { numsuccesses++; }
        else { numfails++; }

        // mostly helps with function identification if disassembled
        logCall(numcalls, numcallsinternal);
    }

    // will clean-up :)

    function selfDestruct() onlyOwner { selfdestruct(owner); }
    
    function() { throw; }
}