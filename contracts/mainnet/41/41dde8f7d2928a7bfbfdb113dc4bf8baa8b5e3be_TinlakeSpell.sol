pragma solidity >=0.7.0;

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
    function deny(address) external;
}

interface PoolAdminLike {
    function setAdminLevel(address, uint) external;
    function admin_level(address) external view returns (uint256);
}

interface FeedLike {
    function file(bytes32, uint256, uint256, uint256, uint256) external;
}

contract TinlakeSpell {

    bool public done;
    string constant public description = "Tinlake BlockTower spell to rely feed on proxy and file riskgroups";

    address public BT1_ROOT = 0x4597f91cC06687Bdb74147C80C097A79358Ed29b;
    address public BT2_ROOT = 0xB5c08534d1E73582FBd79e7C45694CAD6A5C5aB2;
    address public BT3_ROOT = 0x90040F96aB8f291b6d43A8972806e977631aFFdE;
    address public BT4_ROOT = 0x55d86d51Ac3bcAB7ab7d2124931FbA106c8b60c7;

    address public BT1_POOL_ADMIN = 0x242B369dee1B298Bb7103F03d0E54974b37Cc1D0;
    address public BT2_POOL_ADMIN = 0xc5ffE22a7Fb1610b6Af48F30e0D8978407CD36DD;
    address public BT3_POOL_ADMIN = 0x9B7932c89a3fe5b310480D5154C94eF1C2E92202;
    address public BT4_POOL_ADMIN = 0xfB6eBe7599baEd480f44F3F7933F16be5737B4A2;

    address public BT1_FEED = 0x479506bFF98b18D62E62862a02A55047Ca6583Fa;
    address public BT2_FEED = 0xeFf42b6d4527A6a2Fb429082386b34f5d4050b2c;
    address public BT3_FEED = 0xeA5E577Df382889497534A0258345E78BbD4e31d;
    address public BT4_FEED = 0x60eebA86cE045d54cE625D71A5c2bAebfB2e46E9;

    address public BT1_BORROWER = 0xa9253DBe03e86af3a9CEcEf109cbd7A55952EEEe;
    address public BT2_BORROWER = 0xc2dDf93c0f2f1e3637EDBA956de2ad67C7c6033c;
    address public BT3_BORROWER = 0x09C1D389141013a08dD67D495D168Bd067Bc0817;
    address public BT4_BORROWER = 0xdD218a603Bb217B7597b2BAAEa0A271499e3B877;

    address public BT1_PROXY = 0xe8407F4695f7403A1B60A84949500297535CbC03;
    address public BT2_PROXY = 0xeA5579247a8ACC40804B768e942905257f9F8133;
    address public BT3_PROXY = 0xa165bEB919D1e02D9A95B1C513D78a2152e8B764;
    address public BT4_PROXY = 0x26f4998464013A97Fb2adF3B095041dD5860f6d8;

    uint constant ONE = 10**27;
    
    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        execute();
    }

    function execute() internal {
        // Rely proxies on feeds
        RootLike(BT1_ROOT).relyContract(BT1_FEED, BT1_PROXY);
        RootLike(BT2_ROOT).relyContract(BT2_FEED, BT2_PROXY);
        RootLike(BT3_ROOT).relyContract(BT3_FEED, BT3_PROXY);
        RootLike(BT4_ROOT).relyContract(BT4_FEED, BT4_PROXY);

        // Rely spell on pool admins so it can add level 1 admins
        RootLike(BT1_ROOT).relyContract(BT1_POOL_ADMIN, address(this));
        RootLike(BT2_ROOT).relyContract(BT2_POOL_ADMIN, address(this));
        RootLike(BT3_ROOT).relyContract(BT3_POOL_ADMIN, address(this));
        RootLike(BT4_ROOT).relyContract(BT4_POOL_ADMIN, address(this));

        // Rely borrowers as level 1 admins
        PoolAdminLike(BT1_POOL_ADMIN).setAdminLevel(BT1_BORROWER, 1);
        PoolAdminLike(BT2_POOL_ADMIN).setAdminLevel(BT2_BORROWER, 1);
        PoolAdminLike(BT3_POOL_ADMIN).setAdminLevel(BT3_BORROWER, 1);
        PoolAdminLike(BT4_POOL_ADMIN).setAdminLevel(BT4_BORROWER, 1);

        // Deny spell on pool admins
        RootLike(BT1_ROOT).denyContract(BT1_POOL_ADMIN, address(this));
        RootLike(BT2_ROOT).denyContract(BT2_POOL_ADMIN, address(this));
        RootLike(BT3_ROOT).denyContract(BT3_POOL_ADMIN, address(this));
        RootLike(BT4_ROOT).denyContract(BT4_POOL_ADMIN, address(this));

        // Rely spell on feeds so it can file risk groups
        RootLike(BT1_ROOT).relyContract(BT1_FEED, address(this));
        RootLike(BT2_ROOT).relyContract(BT2_FEED, address(this));
        RootLike(BT3_ROOT).relyContract(BT3_FEED, address(this));
        RootLike(BT4_ROOT).relyContract(BT4_FEED, address(this));

        // File risk groups
        fileRiskGroups(FeedLike(BT1_FEED));
        fileRiskGroups(FeedLike(BT2_FEED));
        fileRiskGroups(FeedLike(BT3_FEED));
        fileRiskGroups(FeedLike(BT4_FEED));

        // Deny spell on feeds
        RootLike(BT1_ROOT).denyContract(BT1_FEED, address(this));
        RootLike(BT2_ROOT).denyContract(BT2_FEED, address(this));
        RootLike(BT3_ROOT).denyContract(BT3_FEED, address(this));
        RootLike(BT4_ROOT).denyContract(BT4_FEED, address(this));

        // Deny spell on root contracts
        RootLike(BT1_ROOT).deny(address(this));
        RootLike(BT2_ROOT).deny(address(this));
        RootLike(BT3_ROOT).deny(address(this));
        RootLike(BT4_ROOT).deny(address(this));
     } 

     function fileRiskGroups(FeedLike feed) internal {
        // rate = 1 + (0.04879016/31536000) * 10^27 = 1000000001547120750887874175
        feed.file("riskGroup", 0, ONE, ONE, 1000000001547125824454591578);
        // rate = 1 + (0.05116828/31536000) * 10^27 = 1000000001622590055809233891
        feed.file("riskGroup", 1, ONE, ONE, 1000000001622535514967021816);
        // rate = 1 + (0.05354077/31536000) * 10^27 = 1000000001697742262810755961
        feed.file("riskGroup", 2, ONE, ONE, 1000000001697766679350583460);
        // rate = 1 + (0.05590763/31536000) * 10^27 = 1000000001772819317605276509
        feed.file("riskGroup", 3, ONE, ONE, 1000000001772819317605276509);
        // rate = 1 + (0.05826891/31536000) * 10^27 = 1000000001847695015220700152
        feed.file("riskGroup", 4, ONE, ONE, 1000000001847695015220700152);
        // rate = 1 + (0.06062462/31536000) * 10^27 = 1000000001922394089294774226
        feed.file("riskGroup", 5, ONE, ONE, 1000000001922394089294774226);
        // rate = 1 + (0.06297480/31536000) * 10^27 = 1000000001996917808219178082
        feed.file("riskGroup", 6, ONE, ONE, 1000000001996917808219178082);
        // rate = 1 + (0.06531947/31536000) * 10^27 = 1000000002071266806189751395
        feed.file("riskGroup", 7, ONE, ONE, 1000000002071266806189751395);
        // rate = 1 + (0.06765865/31536000) * 10^27 = 1000000002145441717402333841
        feed.file("riskGroup", 8, ONE, ONE, 1000000002145441717402333841);
        // rate = 1 + (0.06999237/31536000) * 10^27 = 1000000002219443493150684932
        feed.file("riskGroup", 9, ONE, ONE, 1000000002219443493150684932);
        // rate = 1 + (0.07232066/31536000) * 10^27 = 1000000002293273084728564181
        feed.file("riskGroup", 10, ONE, ONE, 1000000002293273084728564181);
        // rate = 1 + (0.07464355/31536000) * 10^27 = 1000000002366931443429731101
        feed.file("riskGroup", 11, ONE, ONE, 1000000002366931443429731101);
        // rate = 1 + (0.07696104/31536000) * 10^27 = 1000000002440418569254185693
        feed.file("riskGroup", 12, ONE, ONE, 1000000002440418569254185693);
        // rate = 1 + (0.07927318/31536000) * 10^27 = 1000000002513736047691527144
        feed.file("riskGroup", 13, ONE, ONE, 1000000002513736047691527144);
        // rate = 1 + (0.08157999/31536000) * 10^27 = 1000000002586884512937595129
        feed.file("riskGroup", 14, ONE, ONE, 1000000002586884512937595129);
        // rate = 1 + (0.08388148/31536000) * 10^27 = 1000000002659864282090309488
        feed.file("riskGroup", 15, ONE, ONE, 1000000002659864282090309488);
        // rate = 1 + (0.08617769/31536000) * 10^27 = 1000000002732676623541349569
        feed.file("riskGroup", 16, ONE, ONE, 1000000002732676623541349569);
        // rate = 1 + (0.08846865/31536000) * 10^27 = 1000000002805322488584474886
        feed.file("riskGroup", 17, ONE, ONE, 1000000002805322488584474886);
        // rate = 1 + (0.09075436/31536000) * 10^27 = 1000000002877801877219685439
        feed.file("riskGroup", 18, ONE, ONE, 1000000002877801877219685439);
        // rate = 1 + (0.09303486/31536000) * 10^27 = 1000000002950116057838660578
        feed.file("riskGroup", 19, ONE, ONE, 1000000002950116057838660578);
        // rate = 1 + (0.09531018/31536000) * 10^27 = 1000000003022265981735159817
        feed.file("riskGroup", 20, ONE, ONE, 1000000003022265981735159817);
        // rate = 1 + (0.09758033/31536000) * 10^27 = 1000000003094251966007102993
        feed.file("riskGroup", 21, ONE, ONE, 1000000003094251966007102993);
        // rate = 1 + (0.09984533/31536000) * 10^27 = 1000000003166074644850329782
        feed.file("riskGroup", 22, ONE, ONE, 1000000003166074644850329782);
        // rate = 1 + (0.10210522/31536000) * 10^27 = 1000000003237735286656519533
        feed.file("riskGroup", 23, ONE, ONE, 1000000003237735286656519533);
        // rate = 1 + (0.10436002/31536000) * 10^27 = 1000000003309234525621511923
        feed.file("riskGroup", 24, ONE, ONE, 1000000003309234525621511923);
        // rate = 1 + (0.10660973/31536000) * 10^27 = 1000000003380572361745306951
        feed.file("riskGroup", 25, ONE, ONE, 1000000003380572361745306951);
        // rate = 1 + (0.10885440/31536000) * 10^27 = 1000000003451750380517503805
        feed.file("riskGroup", 26, ONE, ONE, 1000000003451750380517503805);
        // rate = 1 + (0.11109405/31536000) * 10^27 = 1000000003522769216133942161
        feed.file("riskGroup", 27, ONE, ONE, 1000000003522769216133942161);
        // rate = 1 + (0.11332868/31536000) * 10^27 = 1000000003593628868594622019
        feed.file("riskGroup", 28, ONE, ONE, 1000000003593628868594622019);
        // rate = 1 + (0.11555834/31536000) * 10^27 = 1000000003664330923389142567
        feed.file("riskGroup", 29, ONE, ONE, 1000000003664330923389142567);
        // rate = 1 + (0.11778303/31536000) * 10^27 = 1000000003734875380517503805
        feed.file("riskGroup", 30, ONE, ONE, 1000000003734875380517503805);
     }
}