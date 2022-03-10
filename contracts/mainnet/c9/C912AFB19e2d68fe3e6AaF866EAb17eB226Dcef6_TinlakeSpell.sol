/**
 *Submitted for verification at Etherscan.io on 2022-03-09
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/spell.sol

pragma solidity >=0.6.12;

////// src/addresses_gig.sol
contract Addresses {
	address public ROOT = 0x3d167bd08f762FD391694c67B5e6aF0868c45538;
	address public TINLAKE_CURRENCY = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
	address public TITLE = 0x4AC844d4B76A1E17a1EA0CED8582eAa49253e807;
	address public PILE = 0x9E39e0130558cd9A01C1e3c7b2c3803baCb59616;
	address public SHELF = 0x661f03AcE6Bd3087201503541ac7b0Cb1185d673;
	address public COLLECTOR = 0x5C90e483f32C3FE88261fba02E66D1E6C2f5DBcC;
	address public FEED = 0x468eb2408c6F24662a291892550952eb0d70b707;
	address public JUNIOR_OPERATOR = 0x2540A03ba843eEC2c15B1c317117F3c2e2514e5D;
	address public SENIOR_OPERATOR = 0x429B14613A804F8212052C6AeA0939229C819647;
	address public JUNIOR_TOKEN = 0x6408E86B8F80F6c265a5ECDa0c3a9f654f9Cc80F;
	address public SENIOR_TOKEN = 0xA08399989e77B8Ce8Dd68374cC7b4345304b3161;
	address public JUNIOR_MEMBERLIST = 0x7D28C732B7B8498665Df973f52059C51476DB4E1;
	address public SENIOR_MEMBERLIST = 0xEcc423aB19AFdae990a7afaD0616Bd02E9809495;
	address public COORDINATOR = 0x12688FffCbebf876dC22E024C21c0AA02902e559;
	address public ASSESSOR  = 0x87C67534d9aF78d678101f2dE0F796F4d911697a;
	address public RESERVE = 0x1794A4B29fF2eCdC044Ad5d4972Fa118D4C121b9;
  	address public SENIOR_TRANCHE = 0x408A885c2fc354b70e737565cae86b4c10A92Ac7;
 	address public JUNIOR_TRANCHE = 0xb46A80A5337c70a80b1003826DE1D9796Ee69E8f;
	address public CLERK = 0x8Fd59d6869b313eF4aeA5d979D4f97fa5fF4c07E;
	address public POOL_ADMIN_OLD = 0xD8BF797E416ac564db24143c96A850a9AcAb10C3;
    address public SPOTTER = 0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3;
    address public VAT = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
    address public JUG = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;
}

////// src/spell.sol
/* pragma solidity >=0.6.12; */

/* import "./addresses_gig.sol"; */

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
    string constant public description = "Tinlake GigPool spell";

    // MAINNET ADDRESSES
    // The contracts in this list should correspond to a tinlake deployment
    // https://github.com/centrifuge/tinlake-pool-config/blob/master/mainnet-production.json

    address public POOL_ADMIN = 0xb84447f0d1aC8F6c5A99FD41814b966A2BBCD922;

    address public MEMBER_ADMIN = 0xB7e70B77f6386Ffa5F55DDCb53D87A0Fb5a2f53b;
    address public LEVEL3_ADMIN1 = 0x7b74bb514A1dEA0Ec3763bBd06084e712c8bce97;
    address public LEVEL1_ADMIN1 = 0x71d9f8CFdcCEF71B59DD81AB387e523E2834F2b8;
    address public LEVEL1_ADMIN2 = 0x46a71eEf8DbcFcbAC7A0e8D5d6B634A649e61fb8;
    address public LEVEL1_ADMIN3 = 0x9eDec77dd2651Ce062ab17e941347018AD4eAEA9;
    address public LEVEL1_ADMIN4 = 0xEf270f8877Aa1875fc13e78dcA31f3235210368f;
    address public LEVEL1_ADMIN5 = 0xddEa1De10E93c15037E83b8Ab937A46cc76f7009;
    address public AO_POOL_ADMIN = 0x7122139DA943Aba4423c0C22Ed68d7bD54CcD8f6;

    address public POOL_REGISTRY = 0xddf1C516Cf87126c6c610B52FD8d609E67Fb6033;

    string constant public IPFS_HASH = "QmR4NMhUEDoHBe5XP3w8kszpRtEHfugoKDDvgFMNNcV2Cm";

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
        PoolRegistryLike(POOL_REGISTRY).file(ROOT, true, "gig-pool", IPFS_HASH);
    }
}