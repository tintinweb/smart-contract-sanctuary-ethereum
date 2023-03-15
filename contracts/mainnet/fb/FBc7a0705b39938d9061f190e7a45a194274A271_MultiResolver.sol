/**
 *Submitted for verification at Etherscan.io on 2023-03-15
*/

/***
 * 
 * ███████╗███████╗ ██████╗ ██████╗ ███╗   ██╗██████╗ ██╗     ██╗██╗   ██╗███████╗
 * ██╔════╝██╔════╝██╔════╝██╔═══██╗████╗  ██║██╔══██╗██║     ██║██║   ██║██╔════╝
 * ███████╗█████╗  ██║     ██║   ██║██╔██╗ ██║██║  ██║██║     ██║██║   ██║█████╗  
 * ╚════██║██╔══╝  ██║     ██║   ██║██║╚██╗██║██║  ██║██║     ██║╚██╗ ██╔╝██╔══╝  
 * ███████║███████╗╚██████╗╚██████╔╝██║ ╚████║██████╔╝███████╗██║ ╚████╔╝ ███████╗
 * ╚══════╝╚══════╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝╚═════╝ ╚══════╝╚═╝  ╚═══╝  ╚══════╝
 *    
 * https://secondlive.world
                               
* MIT License
* ===========
*
* Copyright (c) 2023 secondlive
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/ // File: contracts/multiresolver/sid.sol

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

interface SID {
    function resolver(bytes32 node) external view returns (address);
}

// File: contracts/multiresolver/resolver.sol

pragma solidity ^0.8.0;

interface Resolver {
    function name(bytes32 namehash) external view returns (string memory);
}

// File: contracts/multiresolver/MultiResolver.sol

pragma solidity ^0.8.0;

contract MultiResolver {
    address public sid;

    constructor(address _sid) {
        sid = _sid;
    }

    function resolve(bytes32 namehash) public view returns (string memory) {
        address resolver = SID(sid).resolver(namehash);
        if (resolver == address(0)) {
            return "";
        } else {
            string memory targetName = Resolver(resolver).name(namehash);
            return targetName;
        }
    }

    function resolveAll(
        bytes32[] calldata namehashs
    ) public view returns (string[] memory) {
        uint256 length = namehashs.length;
        string[] memory results = new string[](length);
        for (uint256 i = 0; i < length; i++) {
            results[i] = resolve(namehashs[i]);
        }
        return results;
    }
}