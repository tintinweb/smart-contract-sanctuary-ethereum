pragma solidity >=0.6.12;

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

interface RootLike {
    function relyContract(address, address) external;
    function denyContract(address, address) external;
    function rely(address) external;
    function wards(address) external returns(uint);
}

interface PoolAdminLike {
    function rely(address) external;
    function deny(address) external;
    function admin_level(address) external returns(uint);
    function depend(bytes32, address) external;
    function lending() external returns(address);
}

// spell description
contract TinlakeSpell {

    bool public done;
    string constant public description = "Tinlake spell";

    // MAINNET ADDRESSES
    // The contracts in this list should correspond to a tinlake deployment
    // https://github.com/centrifuge/tinlake-pool-config/blob/master/mainnet-production.json

    address public BT1_ROOT = 0x4597f91cC06687Bdb74147C80C097A79358Ed29b;
    address public BT2_ROOT = 0xB5c08534d1E73582FBd79e7C45694CAD6A5C5aB2;
    address public BT3_ROOT = 0x90040F96aB8f291b6d43A8972806e977631aFFdE;
    address public BT4_ROOT = 0x55d86d51Ac3bcAB7ab7d2124931FbA106c8b60c7;

    address public BT1_POOL_ADMIN = 0x242B369dee1B298Bb7103F03d0E54974b37Cc1D0;
    address public BT2_POOL_ADMIN = 0xc5ffE22a7Fb1610b6Af48F30e0D8978407CD36DD;
    address public BT3_POOL_ADMIN = 0x9B7932c89a3fe5b310480D5154C94eF1C2E92202;
    address public BT4_POOL_ADMIN = 0xfB6eBe7599baEd480f44F3F7933F16be5737B4A2;

    address public BT1_CLERK = 0x58C2fdCa82B7C564777E3547eA13bf8113A015cC;
    address public BT2_CLERK = 0x0411179607F426A001B948C1Be8F25A2522bE9D7;
    address public BT3_CLERK = 0x17dF3e3722Fc39A6318A0a70127aAceB86b96Da0;
    address public BT4_CLERK = 0xe015FF153fa731f0399E65f08736ae71B6fD1a9F;

    
    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        execute();
    }

    function execute() internal {
        RootLike(BT1_ROOT).relyContract(BT1_POOL_ADMIN, address(this));
        RootLike(BT2_ROOT).relyContract(BT2_POOL_ADMIN, address(this));
        RootLike(BT3_ROOT).relyContract(BT3_POOL_ADMIN, address(this));
        RootLike(BT4_ROOT).relyContract(BT4_POOL_ADMIN, address(this));

        PoolAdminLike(BT1_POOL_ADMIN).depend("lending", BT1_CLERK);
        PoolAdminLike(BT2_POOL_ADMIN).depend("lending", BT2_CLERK);
        PoolAdminLike(BT3_POOL_ADMIN).depend("lending", BT3_CLERK);
        PoolAdminLike(BT4_POOL_ADMIN).depend("lending", BT4_CLERK);

        RootLike(BT1_ROOT).denyContract(BT1_POOL_ADMIN, address(this));
        RootLike(BT2_ROOT).denyContract(BT2_POOL_ADMIN, address(this));
        RootLike(BT3_ROOT).denyContract(BT3_POOL_ADMIN, address(this));
        RootLike(BT4_ROOT).denyContract(BT4_POOL_ADMIN, address(this));
     }  
}