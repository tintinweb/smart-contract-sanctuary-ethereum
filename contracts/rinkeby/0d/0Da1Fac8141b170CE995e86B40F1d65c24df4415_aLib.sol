// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.1;
contract sampleContract {
    function get () public {
        aLib.doStuff();
    }
}

library aLib {
    function doStuff() public {
    }
}