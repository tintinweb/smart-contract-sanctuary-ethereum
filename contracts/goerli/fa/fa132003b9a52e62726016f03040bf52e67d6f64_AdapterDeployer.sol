// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.6;

import {ClerkFabLike, TinlakeManagerFabLike} from "../fabs/interfaces.sol";

interface LenderDeployerLike {
    function coordinator() external returns (address);
    function assessor() external returns (address);
    function reserve() external returns (address);
    function seniorOperator() external returns (address);
    function seniorTranche() external returns (address);
    function seniorToken() external returns (address);
    function currency() external returns (address);
    function poolAdmin() external returns (address);
    function seniorMemberlist() external returns (address);
}

interface PoolAdminLike {
    function rely(address) external;
    function relyAdmin(address) external;
}

interface FileLike {
    function file(bytes32 name, uint256 value) external;
}

interface MemberlistLike {
    function updateMember(address, uint256) external;
}

interface MgrLike {
    function rely(address) external;
    function file(bytes32 name, address value) external;
    function lock(uint256) external;
}

interface AuthLike {
    function rely(address) external;
    function deny(address) external;
}

interface DependLike {
    function depend(bytes32, address) external;
}

contract AdapterDeployer {
    ClerkFabLike public clerkFab;
    TinlakeManagerFabLike public mgrFab;
    address public clerk;
    address public mgr;

    address public root;
    LenderDeployerLike public lenderDeployer;

    address deployUsr;

    constructor(address root_, address clerkFabLike_, address mgrFabLike_) {
        root = root_;
        clerkFab = ClerkFabLike(clerkFabLike_);
        mgrFab = TinlakeManagerFabLike(mgrFabLike_);
        deployUsr = msg.sender;
    }

    function deployClerk(address lenderDeployer_, bool wireReserveAssessor) public {
        require(
            deployUsr == msg.sender && address(clerk) == address(0)
                && LenderDeployerLike(lenderDeployer_).seniorToken() != address(0)
        );

        lenderDeployer = LenderDeployerLike(lenderDeployer_);
        clerk = clerkFab.newClerk(lenderDeployer.currency(), lenderDeployer.seniorToken());

        address assessor = lenderDeployer.assessor();
        address reserve = lenderDeployer.reserve();
        address seniorTranche = lenderDeployer.seniorTranche();
        address seniorMemberlist = lenderDeployer.seniorMemberlist();
        address poolAdmin = lenderDeployer.poolAdmin();

        // clerk dependencies
        DependLike(clerk).depend("coordinator", lenderDeployer.coordinator());
        DependLike(clerk).depend("assessor", assessor);
        DependLike(clerk).depend("reserve", reserve);
        DependLike(clerk).depend("tranche", seniorTranche);
        DependLike(clerk).depend("collateral", lenderDeployer.seniorToken());

        // clerk as ward
        AuthLike(seniorTranche).rely(clerk);
        AuthLike(reserve).rely(clerk);
        AuthLike(assessor).rely(clerk);

        // reserve can draw and wipe on clerk
        if (wireReserveAssessor) DependLike(reserve).depend("lending", clerk);
        AuthLike(clerk).rely(reserve);

        // allow clerk to hold seniorToken
        MemberlistLike(seniorMemberlist).updateMember(clerk, type(uint256).max);

        if (wireReserveAssessor) DependLike(assessor).depend("lending", clerk);

        AuthLike(clerk).rely(poolAdmin);

        AuthLike(clerk).rely(root);
    }

    function deployClerk(address lenderDeployer_) public {
        deployClerk(lenderDeployer_, true);
    }

    function deployMgr(
        address dai,
        address daiJoin,
        address end,
        address vat,
        address vow,
        address liq,
        address spotter,
        address jug,
        uint256 matBuffer
    ) public {
        require(
            deployUsr == msg.sender && address(clerk) != address(0) && address(mgr) == address(0)
                && lenderDeployer.seniorToken() != address(0)
        );

        // deploy mgr
        mgr = mgrFab.newTinlakeManager(
            dai,
            daiJoin,
            lenderDeployer.seniorToken(),
            lenderDeployer.seniorOperator(),
            lenderDeployer.seniorTranche(),
            end,
            vat,
            vow
        );
        wireClerk(mgr, vat, spotter, jug, matBuffer);

        // setup mgr
        MgrLike mkrMgr = MgrLike(mgr);
        mkrMgr.rely(clerk);
        mkrMgr.file("liq", liq);
        mkrMgr.file("end", end);
        mkrMgr.file("owner", clerk);

        // rely root, deny adapter deployer
        AuthLike(mgr).rely(root);
        AuthLike(mgr).deny(address(this));
    }

    // This is separated as the system tests don't use deployMgr, but do need the clerk wiring
    function wireClerk(address mgr_, address vat, address spotter, address jug, uint256 matBuffer) public {
        require(deployUsr == msg.sender && address(clerk) != address(0));

        // wire clerk
        DependLike(clerk).depend("mgr", mgr_);
        DependLike(clerk).depend("spotter", spotter);
        DependLike(clerk).depend("vat", vat);
        DependLike(clerk).depend("jug", jug);

        // set the mat buffer
        FileLike(clerk).file("buffer", matBuffer);

        // rely root, deny adapter deployer
        AuthLike(clerk).deny(address(this));

        MemberlistLike(lenderDeployer.seniorMemberlist()).updateMember(mgr_, type(uint256).max);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.6;

interface ReserveFabLike {
    function newReserve(address) external returns (address);
}

interface AssessorFabLike {
    function newAssessor() external returns (address);
}

interface TrancheFabLike {
    function newTranche(address, address) external returns (address);
}

interface CoordinatorFabLike {
    function newCoordinator(uint256) external returns (address);
}

interface OperatorFabLike {
    function newOperator(address) external returns (address);
}

interface MemberlistFabLike {
    function newMemberlist() external returns (address);
}

interface RestrictedTokenFabLike {
    function newRestrictedToken(string calldata, string calldata) external returns (address);
}

interface PoolAdminFabLike {
    function newPoolAdmin() external returns (address);
}

interface ClerkFabLike {
    function newClerk(address, address) external returns (address);
}

interface TinlakeManagerFabLike {
    function newTinlakeManager(address, address, address, address, address, address, address, address)
        external
        returns (address);
}