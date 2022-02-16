/**
 *Submitted for verification at Etherscan.io on 2022-02-16
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/spell.sol

pragma solidity >=0.6.12;

////// src/addresses_cf4.sol
contract Addresses {
	address constant public ROOT = 0xdB3bC9fB1893222d266762e9fF857EB74D75c7D6;
	address constant public TINLAKE_CURRENCY = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
	address constant public TITLE = 0x9Ab3ada106afdFAE83f13428e40da70b3A22C50C;
	address constant public PILE = 0x3fC72dA5545E2AB6202D81fbEb1C8273Be95068C;
	address constant public SHELF = 0xA0B0d8394ADC79f5d1563a892abFc6186E519644;
	address constant public COLLECTOR = 0x026AA71fCB79684639d2f0F11ad74569Fbd5d590;
	address constant public FEED = 0x69504da6B2Cd8320B9a62F3AeD410a298d3E7Ac6;
	address constant public JUNIOR_OPERATOR = 0x9b68611127275b3B5f04161884f2c5C308CCE0Dd;
	address constant public SENIOR_OPERATOR = 0x21335b1b19964Ef33787138122fD1CDc6deD8186;
	address constant public JUNIOR_TOKEN = 0x05DD145AA26dBDcc7774E4118E34Bb67C64661c6;
	address constant public SENIOR_TOKEN = 0x5b2F0521875B188C0afc925B1598e1FF246F9306;
	address constant public JUNIOR_MEMBERLIST = 0x4CA09F24f3342327da42d2b6035af741fC1AeB4A;
	address constant public SENIOR_MEMBERLIST = 0x26129802A858F3C28553f793E1008b8338e6aEd2;
	address constant public COORDINATOR_OLD = 0x585c080f36042bA2CD4C310660386cA3d95FdfAD;
	address constant public ASSESSOR  = 0x989e5F083cF5B2065C60032d7Bafd176237f8E09;
	address constant public RESERVE = 0xFAec38fFEe969cf18e88097EC62E30b70494e234;
	address constant public SENIOR_TRANCHE = 0x675f5A545Fd57eC8Fe0916Fb61a2D9F19e2Da926;
	address constant public JUNIOR_TRANCHE = 0xC90fE5884C1c2f2913fFee5440ce4dd34f4B279D;
	address constant public POOL_ADMIN_OLD = 0x7A5f9AE1d4c81B5ea0Ab318ae24055898Bfb0abC;
	address constant public CLERK_OLD = 0x43b3f07667906026336C92bFade718a3430A845d;
	address constant public MGR = 0x2A9798c6F165B6D60Cfb923Fe5BFD6f338695D9B;
    address constant public SPOTTER = 0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3;
    address constant public VAT = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
    address constant public JUG = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;
}

////// src/spell.sol
/* pragma solidity >=0.6.12; */

/* import "./addresses_cf4.sol"; */

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
    string constant public description = "Tinlake CF4 spell";

    // MAINNET ADDRESSES
    // The contracts in this list should correspond to a tinlake deployment
    // https://github.com/centrifuge/tinlake-pool-config/blob/master/mainnet-production.json

    address public CLERK = 0x3f18128FECeFFB959092dC643AD230D3f4706eC2;
    address public COORDINATOR = 0xB5F8921B5Ac74d0cCD28427a6304bdBfeb211d72;
    address public POOL_ADMIN = 0xa0768C6Dbf011A731AB3Fa425b1EBbE695dCD364;

    address public MEMBER_ADMIN = 0xB7e70B77f6386Ffa5F55DDCb53D87A0Fb5a2f53b;
    address public LEVEL3_ADMIN1 = 0x7b74bb514A1dEA0Ec3763bBd06084e712c8bce97;
    address public LEVEL1_ADMIN1 = 0x71d9f8CFdcCEF71B59DD81AB387e523E2834F2b8;
    address public LEVEL1_ADMIN2 = 0x46a71eEf8DbcFcbAC7A0e8D5d6B634A649e61fb8;
    address public LEVEL1_ADMIN3 = 0x9eDec77dd2651Ce062ab17e941347018AD4eAEA9;
    address public LEVEL1_ADMIN4 = 0xEf270f8877Aa1875fc13e78dcA31f3235210368f;
    address public LEVEL1_ADMIN5 = 0xddEa1De10E93c15037E83b8Ab937A46cc76f7009;
    address public AO_POOL_ADMIN = 0x8CE8fC2e297F1688385Fc115A3cB104393FE3659;

    address public POOL_REGISTRY = 0xddf1C516Cf87126c6c610B52FD8d609E67Fb6033;

    string constant public IPFS_HASH = "QmS3D3EAySc9b2CVrNnPV2ueo6tBvTFi49kewttQq4vQLw";

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
       root.relyContract(COORDINATOR_OLD, self);
       root.relyContract(RESERVE, self);
       root.relyContract(MGR, self);
       root.relyContract(FEED, self);
       
       migrateClerk();
       migrateCoordinator();
       migratePoolAdmin();
       updateRegistry();
     }  

    function migrateCoordinator() internal {
        // migrate state
        MigrationLike(COORDINATOR).migrate(COORDINATOR_OLD);

        // migrate dependencies
        DependLike(COORDINATOR).depend("assessor", ASSESSOR);
        DependLike(COORDINATOR).depend("juniorTranche", JUNIOR_TRANCHE);
        DependLike(COORDINATOR).depend("seniorTranche", SENIOR_TRANCHE);

        DependLike(CLERK).depend("coordinator", COORDINATOR);

        DependLike(SENIOR_TRANCHE).depend("coordinator", COORDINATOR);
        DependLike(JUNIOR_TRANCHE).depend("coordinator", COORDINATOR);

        // migrate permissions
        AuthLike(ASSESSOR).rely(COORDINATOR); 
        AuthLike(ASSESSOR).deny(COORDINATOR_OLD);
        AuthLike(JUNIOR_TRANCHE).rely(COORDINATOR); 
        AuthLike(JUNIOR_TRANCHE).deny(COORDINATOR_OLD); 
        AuthLike(SENIOR_TRANCHE).rely(COORDINATOR);
        AuthLike(SENIOR_TRANCHE).deny(COORDINATOR_OLD);
     }

    function migratePoolAdmin() internal {
        // setup dependencies 
        DependLike(POOL_ADMIN).depend("assessor", ASSESSOR);
        // DependLike(POOL_ADMIN).depend("lending", CLERK); // set in clerk migration
        DependLike(POOL_ADMIN).depend("seniorMemberlist", SENIOR_MEMBERLIST);
        DependLike(POOL_ADMIN).depend("juniorMemberlist", JUNIOR_MEMBERLIST);
        DependLike(POOL_ADMIN).depend("navFeed", FEED);
        DependLike(POOL_ADMIN).depend("coordinator", COORDINATOR);

        // setup permissions
        AuthLike(ASSESSOR).rely(POOL_ADMIN);
        AuthLike(ASSESSOR).deny(POOL_ADMIN_OLD);
        // AuthLike(CLERK).rely(POOL_ADMIN); // set in clerk migration
        // AuthLike(CLERK).deny(POOL_ADMIN_OLD);
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

    function migrateClerk() internal {
        // migrate state
        MigrationLike(CLERK).migrate(CLERK_OLD);
    
        // dependencies
        DependLike(CLERK).depend("assessor", ASSESSOR);
        DependLike(CLERK).depend("mgr", MGR);
        DependLike(CLERK).depend("coordinator", COORDINATOR);
        DependLike(CLERK).depend("reserve", RESERVE); 
        DependLike(CLERK).depend("tranche", SENIOR_TRANCHE);
        DependLike(CLERK).depend("collateral", SENIOR_TOKEN);
        DependLike(CLERK).depend("spotter", SPOTTER);
        DependLike(CLERK).depend("vat", VAT);
        DependLike(CLERK).depend("jug", JUG);

        // permissions
        AuthLike(CLERK).rely(RESERVE);
        AuthLike(CLERK).rely(POOL_ADMIN);
        AuthLike(SENIOR_TRANCHE).rely(CLERK);
        AuthLike(RESERVE).rely(CLERK);
        AuthLike(ASSESSOR).rely(CLERK);
        AuthLike(MGR).rely(CLERK);

        FileLike(MGR).file("owner", CLERK);

        DependLike(ASSESSOR).depend("lending", CLERK);
        DependLike(RESERVE).depend("lending", CLERK);
        DependLike(POOL_ADMIN).depend("lending", CLERK);
       
        // restricted token setup
        SpellMemberlistLike(SENIOR_MEMBERLIST).updateMember(CLERK, uint(-1));

        // remove old clerk
        AuthLike(SENIOR_TRANCHE).deny(CLERK_OLD);
        AuthLike(RESERVE).deny(CLERK_OLD);
        AuthLike(ASSESSOR).deny(CLERK_OLD);
        AuthLike(MGR).deny(CLERK_OLD);
    }

    function updateRegistry() internal {
        PoolRegistryLike(POOL_REGISTRY).file(ROOT, true, "consolfreight-4", IPFS_HASH);
    }
}