/**
 *Submitted for verification at Etherscan.io on 2022-05-17
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/spell.sol
// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.5.15 >=0.6.12;

////// lib/tinlake-rpc-tests/lib/tinlake-title/lib/tinlake-auth/src/auth.sol
// Copyright (C) Centrifuge 2020, based on MakerDAO dss https://github.com/makerdao/dss
/* pragma solidity >=0.5.15; */

contract Auth {
    mapping (address => uint256) public wards;
    
    event Rely(address indexed usr);
    event Deny(address indexed usr);

    function rely(address usr) external auth {
        wards[usr] = 1;
        emit Rely(usr);
    }
    function deny(address usr) external auth {
        wards[usr] = 0;
        emit Deny(usr);
    }

    modifier auth {
        require(wards[msg.sender] == 1, "not-authorized");
        _;
    }

}

////// src/spell.sol
/* pragma solidity >=0.6.12; */
/* import "tinlake-auth/auth.sol"; */
// Copyright (C) 2020 Centrifuge
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

interface AuthLike {
    function rely(address) external;
    function deny(address) external;
    function wards(address) external returns(uint);
}

interface TinlakeRootLike {
    function relyContract(address, address) external;
    function denyContract(address, address) external;
}

interface FileLike {
    function file(bytes32, uint) external;
    function file(bytes32, address) external;
}

interface LogLike {
    function getAddress(bytes32) external returns(address);
}

// spell to keep the mkr end contract updated
contract TinlakeSpell is Auth {

    // spell can be executed anytime as long as it is active
    bool public active;
    string constant public description = "Tinlake MGR spell";

    // MAINNET ADDRESSES
    // The contracts in this list should correspond to a tinlake deployment
    // https://github.com/centrifuge/tinlake-pool-config/blob/master/mainnet-production.json

    address public NS2_MGR = 0x2474F297214E5d96Ba4C81986A9F0e5C260f445D;
    address public HTC2_MGR = 0xe1ed3F588A98bF8a3744f4BF74Fd8540e81AdE3f;
    address public CF4_MGR = 0x2A9798c6F165B6D60Cfb923Fe5BFD6f338695D9B;
    address public FF1_MGR = 0x5b702e1fEF3F556cbe219eE697D7f170A236cc66;

    address public NS2_ROOT = 0x53b2d22d07E069a3b132BfeaaD275b10273d381E;
    address public HTC2_ROOT = 0x4cA805cE8EcE2E63FfC1F9f8F2731D3F48DF89Df;
    address public CF4_ROOT = 0xdB3bC9fB1893222d266762e9fF857EB74D75c7D6;
    address public FF1_ROOT = 0x4B6CA198d257D755A5275648D471FE09931b764A;

    address public ADMIN = 0xf3BceA7494D8f3ac21585CA4b0E52aa175c24C25; // multisig 
    address public CHAINLOG = 0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F;
    address self;
    

    constructor() public {
        wards[ADMIN] = 1; // rely ADMIN
        wards[msg.sender]= 0; // deny deployer
        active = true;
    }

     function file(bytes32 name, bool value) public auth {
        if (name == "active") {
            active = value;
        } else { revert("unknown-name"); }
     }

    function cast() public {
        require(active, "spell-not-active");
        execute();
    }

    function execute() internal {
       self = address(this);

       // permissions 
       TinlakeRootLike(address(NS2_ROOT)).relyContract(NS2_MGR, self);
       TinlakeRootLike(address(HTC2_ROOT)).relyContract(HTC2_MGR, self);
       TinlakeRootLike(address(CF4_ROOT)).relyContract(CF4_MGR, self);
       TinlakeRootLike(address(FF1_ROOT)).relyContract(FF1_MGR, self);
    
       address END = LogLike(CHAINLOG).getAddress("MCD_END");
    
       FileLike(NS2_MGR).file("end", END);
       FileLike(HTC2_MGR).file("end", END);
       FileLike(CF4_MGR).file("end", END);
       FileLike(FF1_MGR).file("end", END);
     } 
}