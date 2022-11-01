//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract CheapMultiSend {
    function multiSend(address payable[] memory to, uint[] memory amount)
        public
        payable
    {
        require(
            to.length == amount.length,
            "to and amount must be the same length"
        );
        assembly {
            let len := mload(to)
            //skip past to.length
            to := add(to, 0x20)
            amount := add(amount, 0x20)
            for {
                let i := 0
            } lt(i, len) {
                i := add(i, 1)
            } {
                pop(
                    call(
                        0,
                        mload(add(to, mul(i, 0x20))),
                        mload(add(amount, mul(i, 0x20))),
                        0x0, // input
                        0x0, // input size
                        0x0, // output
                        0x0 // output size
                    )
                )
            }
        }
    }

    function getBalance(address addr) public view returns (uint) {
        return addr.balance;
    }
}