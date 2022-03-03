/**
 *Submitted for verification at Etherscan.io on 2022-03-03
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/spell.sol

pragma solidity >=0.6.12;

////// src/addresses_ns2.sol
contract Addresses {
	address constant public ROOT = 0x53b2d22d07E069a3b132BfeaaD275b10273d381E;
	address constant public TINLAKE_CURRENCY = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
	address constant public TITLE = 0x9Ab3ada106afdFAE83f13428e40da70b3A22C50C;
	address constant public PILE = 0x3eC5c16E7f2C6A80E31997C68D8Fa6ACe089807f;
	address constant public SHELF = 0x7d057A056939bb96D682336683C10EC89b78D7CE;
	address constant public COLLECTOR = 0x62f290512c690a817f47D2a4a544A5d48D1408BE;
	address constant public FEED = 0x41fAD1Eb242De19dA0206B0468763333BB6C2B3D;
	address constant public JUNIOR_OPERATOR = 0x4c4Cc6a0573db5823ECAA1d1d65EB64E5E0E5F01;
	address constant public SENIOR_OPERATOR = 0x230f2E19D6c2Dc0c441c2150D4dD9d67B563A60C;
	address constant public JUNIOR_TOKEN = 0x961e1d4c9A7C0C3e05F17285f5FA34A66b62dBb1;
	address constant public SENIOR_TOKEN = 0xE4C72b4dE5b0F9ACcEA880Ad0b1F944F85A9dAA0;
	address constant public JUNIOR_MEMBERLIST = 0x42C2483EEE8c1Fe46C398Ac296C59674F9eb88CD;
	address constant public SENIOR_MEMBERLIST = 0x5B5CFD6E45F1407ABCb4BFD9947aBea1EA6649dA;
	address constant public COORDINATOR = 0x22a1caca2EE82e9cE7Ef900FD961891b66deB7cA;
	address constant public ASSESSOR  = 0x83E2369A33104120746B589Cc90180ed776fFb91;
	address constant public RESERVE = 0x1f5Fa2E665609CE4953C65CE532Ac8B47EC97cD5;
  	address constant public SENIOR_TRANCHE = 0x3f06DB6334435fF4150e14aD69F6280BF8E8dA64;
 	address constant public JUNIOR_TRANCHE = 0x53CF3CCd97CA914F9e441B8cd9A901E69B170f27;
	address constant public POOL_ADMIN_OLD = 0xd7fb14d5C1259a47d46D156E74a9c3B69a147b4A;
	address constant public CLERK = 0xfE27bAA63592CCF1E09550fc489342b5817388B5;
}

////// src/spell.sol
/* pragma solidity >=0.6.12; */

/* import "./addresses_ns2.sol"; */

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

interface DependLike {
    function depend(bytes32, address) external;
}

interface MigrationLike {
        function migrate(address) external;
}

interface SpellMemberlistLike {
    function updateMember(address, uint) external;
}

interface PoolAdminLike {
    function setAdminLevel(address usr, uint level) external;
}

interface PoolRegistryLike {
    function file(address, bool, string memory, string memory) external;
    function find(address pool) external view returns (bool live, string memory name, string memory data);
}

// spell to swap clerk, coordinator & poolAdmin
contract TinlakeSpell is Addresses {

    bool public done;
    string constant public description = "Tinlake NS2 spell";

    // MAINNET ADDRESSES
    // The contracts in this list should correspond to a tinlake deployment
    // https://github.com/centrifuge/tinlake-pool-config/blob/master/mainnet-production.json

    address public POOL_ADMIN = 0xeaC0214e319D827565e81801DAbcA04CCc6E8986;

    address public MEMBER_ADMIN = 0xB7e70B77f6386Ffa5F55DDCb53D87A0Fb5a2f53b;
    address public LEVEL3_ADMIN1 = 0x7b74bb514A1dEA0Ec3763bBd06084e712c8bce97;
    address public LEVEL1_ADMIN1 = 0x71d9f8CFdcCEF71B59DD81AB387e523E2834F2b8;
    address public LEVEL1_ADMIN2 = 0x46a71eEf8DbcFcbAC7A0e8D5d6B634A649e61fb8;
    address public LEVEL1_ADMIN3 = 0x9eDec77dd2651Ce062ab17e941347018AD4eAEA9;
    address public LEVEL1_ADMIN4 = 0xEf270f8877Aa1875fc13e78dcA31f3235210368f;
    address public LEVEL1_ADMIN5 = 0xddEa1De10E93c15037E83b8Ab937A46cc76f7009;
    address public AO_POOL_ADMIN = 0x7Cae9bD865610750a48575aF15CAFe1e460c96a8;

    address public POOL_REGISTRY = 0xddf1C516Cf87126c6c610B52FD8d609E67Fb6033;

    string constant public IPFS_HASH = "QmcVoEqdRjNxwaQmooWjDguBr4FjQ214ZUZwhwTKjJrtoK";

    uint256 constant ONE = 10**27;
    address self;
    
    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        execute();
    }

    function execute() internal {
       TinlakeRootLike root = TinlakeRootLike(address(ROOT));
       self = address(this);
       // permissions 
       root.relyContract(CLERK, self); // required to file riskGroups & change discountRate
       root.relyContract(SENIOR_TRANCHE, self);
       root.relyContract(SENIOR_TOKEN, self);
       root.relyContract(SENIOR_TRANCHE, self);
       root.relyContract(JUNIOR_TRANCHE, self);
       root.relyContract(SENIOR_MEMBERLIST, self);
       root.relyContract(JUNIOR_MEMBERLIST, self);
       root.relyContract(POOL_ADMIN, self);
       root.relyContract(ASSESSOR, self);
       root.relyContract(COORDINATOR, self);
       root.relyContract(RESERVE, self);
       root.relyContract(FEED, self);
       
       migratePoolAdmin();
       updateRegistry();
     }  


    function migratePoolAdmin() internal {
        // setup dependencies 
        DependLike(POOL_ADMIN).depend("assessor", ASSESSOR);
        // DependLike(POOL_ADMIN).depend("lending", CLERK); // set in clerk migration
        DependLike(POOL_ADMIN).depend("seniorMemberlist", SENIOR_MEMBERLIST);
        DependLike(POOL_ADMIN).depend("juniorMemberlist", JUNIOR_MEMBERLIST);
        DependLike(POOL_ADMIN).depend("navFeed", FEED);
        DependLike(POOL_ADMIN).depend("coordinator", COORDINATOR);
        DependLike(POOL_ADMIN).depend("lending", CLERK);

        // setup permissions
        AuthLike(ASSESSOR).rely(POOL_ADMIN);
        AuthLike(ASSESSOR).deny(POOL_ADMIN_OLD);
        AuthLike(CLERK).rely(POOL_ADMIN); // set in clerk migration
        AuthLike(CLERK).deny(POOL_ADMIN_OLD);
        AuthLike(JUNIOR_MEMBERLIST).rely(POOL_ADMIN);
        AuthLike(JUNIOR_MEMBERLIST).deny(POOL_ADMIN_OLD);
        AuthLike(SENIOR_MEMBERLIST).rely(POOL_ADMIN);
        AuthLike(SENIOR_MEMBERLIST).deny(POOL_ADMIN_OLD);
        AuthLike(FEED).rely(POOL_ADMIN);
        AuthLike(FEED).deny(POOL_ADMIN_OLD);
        AuthLike(COORDINATOR).rely(POOL_ADMIN);
        AuthLike(COORDINATOR).deny(POOL_ADMIN_OLD);

        // set lvl3 admins
        AuthLike(POOL_ADMIN).rely(LEVEL3_ADMIN1);
        // set lvl1 admins
        PoolAdminLike(POOL_ADMIN).setAdminLevel(LEVEL1_ADMIN1, 1);
        PoolAdminLike(POOL_ADMIN).setAdminLevel(LEVEL1_ADMIN2, 1);
        PoolAdminLike(POOL_ADMIN).setAdminLevel(LEVEL1_ADMIN3, 1);
        PoolAdminLike(POOL_ADMIN).setAdminLevel(LEVEL1_ADMIN4, 1);
        PoolAdminLike(POOL_ADMIN).setAdminLevel(LEVEL1_ADMIN5, 1);
        PoolAdminLike(POOL_ADMIN).setAdminLevel(AO_POOL_ADMIN, 1);
        AuthLike(JUNIOR_MEMBERLIST).rely(MEMBER_ADMIN);
        AuthLike(SENIOR_MEMBERLIST).rely(MEMBER_ADMIN);
    }

    function updateRegistry() internal {
        PoolRegistryLike(POOL_REGISTRY).file(ROOT, true, "new-silver-2", IPFS_HASH);
    }
}