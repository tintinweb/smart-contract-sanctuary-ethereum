// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.6;

/// @notice abstract contract for FixedPoint math operations
/// defining ONE with 10^27 precision
abstract contract FixedPoint {
    struct Fixed27 {
        uint256 value;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.6;

import {
    ReserveFabLike,
    AssessorFabLike,
    TrancheFabLike,
    CoordinatorFabLike,
    OperatorFabLike,
    MemberlistFabLike,
    RestrictedTokenFabLike,
    PoolAdminFabLike,
    ClerkFabLike
} from "./fabs/interfaces.sol";

import {FixedPoint} from "./../fixed_point.sol";

interface DependLike {
    function depend(bytes32, address) external;
}

interface AuthLike {
    function rely(address) external;
    function deny(address) external;
}

interface MemberlistLike {
    function updateMember(address, uint256) external;
}

interface FileLike {
    function file(bytes32 name, uint256 value) external;
}

interface PoolAdminLike {
    function rely(address) external;
}

/// @notice contract for deploying a Tinlake lender contracts
contract LenderDeployer is FixedPoint {
    address public immutable root;
    address public immutable currency;
    address public immutable memberAdmin;

    // factory contracts
    TrancheFabLike public immutable trancheFab;
    ReserveFabLike public immutable reserveFab;
    AssessorFabLike public immutable assessorFab;
    CoordinatorFabLike public immutable coordinatorFab;
    OperatorFabLike public immutable operatorFab;
    MemberlistFabLike public immutable memberlistFab;
    RestrictedTokenFabLike public immutable restrictedTokenFab;
    PoolAdminFabLike public immutable poolAdminFab;

    // lender state variables
    Fixed27 public minSeniorRatio;
    Fixed27 public maxSeniorRatio;
    uint256 public maxReserve;
    uint256 public challengeTime;
    Fixed27 public seniorInterestRate;

    // contract addresses
    address public adapterDeployer;
    address public assessor;
    address public poolAdmin;
    address public seniorTranche;
    address public juniorTranche;
    address public seniorOperator;
    address public juniorOperator;
    address public reserve;
    address public coordinator;

    address public seniorToken;
    address public juniorToken;

    // token names
    string public seniorName;
    string public seniorSymbol;
    string public juniorName;
    string public juniorSymbol;
    // restricted token member list
    address public seniorMemberlist;
    address public juniorMemberlist;

    address public deployer;
    bool public wired;

    constructor(
        address root_,
        address currency_,
        address trancheFab_,
        address memberlistFab_,
        address restrictedtokenFab_,
        address reserveFab_,
        address assessorFab_,
        address coordinatorFab_,
        address operatorFab_,
        address poolAdminFab_,
        address memberAdmin_,
        address adapterDeployer_
    ) {
        deployer = msg.sender;
        root = root_;
        currency = currency_;
        memberAdmin = memberAdmin_;
        adapterDeployer = adapterDeployer_;

        trancheFab = TrancheFabLike(trancheFab_);
        memberlistFab = MemberlistFabLike(memberlistFab_);
        restrictedTokenFab = RestrictedTokenFabLike(restrictedtokenFab_);
        reserveFab = ReserveFabLike(reserveFab_);
        assessorFab = AssessorFabLike(assessorFab_);
        poolAdminFab = PoolAdminFabLike(poolAdminFab_);
        coordinatorFab = CoordinatorFabLike(coordinatorFab_);
        operatorFab = OperatorFabLike(operatorFab_);
    }

    /// @dev init function for the lender deployer can only be called once
    /// @param minSeniorRatio_ min senior ratio for the pool
    /// @param maxSeniorRatio_ max senior ratio for the pool
    /// @param maxReserve_ max reserve for the pool
    /// @param challengeTime_ challenge time for the pool, time to challenge a valid epoch
    /// coordinator submission. After the challenge time, the epoch can be executed
    /// @param seniorInterestRate_ interest rate per second for the senior tranche (in RAY)
    /// @param seniorName_ name of the senior token
    /// @param seniorSymbol_ symbol of the senior token
    /// @param juniorName_ name of the junior token
    /// @param juniorSymbol_ symbol of the junior token
    function init(
        uint256 minSeniorRatio_,
        uint256 maxSeniorRatio_,
        uint256 maxReserve_,
        uint256 challengeTime_,
        uint256 seniorInterestRate_,
        string memory seniorName_,
        string memory seniorSymbol_,
        string memory juniorName_,
        string memory juniorSymbol_
    ) public {
        require(msg.sender == deployer);
        challengeTime = challengeTime_;
        minSeniorRatio = Fixed27(minSeniorRatio_);
        maxSeniorRatio = Fixed27(maxSeniorRatio_);
        maxReserve = maxReserve_;
        seniorInterestRate = Fixed27(seniorInterestRate_);

        // token names
        seniorName = seniorName_;
        seniorSymbol = seniorSymbol_;
        juniorName = juniorName_;
        juniorSymbol = juniorSymbol_;

        deployer = address(1);
    }
    /// @notice deploys the junior tranche related contracts

    function deployJunior() public {
        require(juniorTranche == address(0) && deployer == address(1));
        juniorToken = restrictedTokenFab.newRestrictedToken(juniorSymbol, juniorName);
        juniorTranche = trancheFab.newTranche(currency, juniorToken);
        juniorMemberlist = memberlistFab.newMemberlist();
        juniorOperator = operatorFab.newOperator(juniorTranche);
        AuthLike(juniorMemberlist).rely(root);
        AuthLike(juniorToken).rely(root);
        AuthLike(juniorToken).rely(juniorTranche);
        AuthLike(juniorOperator).rely(root);
        AuthLike(juniorTranche).rely(root);
    }

    /// @notice deploys the senior tranche related contracts
    function deploySenior() public {
        require(seniorTranche == address(0) && deployer == address(1));
        seniorToken = restrictedTokenFab.newRestrictedToken(seniorSymbol, seniorName);
        seniorTranche = trancheFab.newTranche(currency, seniorToken);
        seniorMemberlist = memberlistFab.newMemberlist();
        seniorOperator = operatorFab.newOperator(seniorTranche);
        AuthLike(seniorMemberlist).rely(root);
        AuthLike(seniorToken).rely(root);
        AuthLike(seniorToken).rely(seniorTranche);
        AuthLike(seniorOperator).rely(root);
        AuthLike(seniorTranche).rely(root);

        if (adapterDeployer != address(0)) {
            AuthLike(seniorTranche).rely(adapterDeployer);
            AuthLike(seniorMemberlist).rely(adapterDeployer);
        }
    }

    /// @notice deploys the reserve contract
    function deployReserve() public {
        require(reserve == address(0) && deployer == address(1));
        reserve = reserveFab.newReserve(currency);
        AuthLike(reserve).rely(root);
        if (adapterDeployer != address(0)) AuthLike(reserve).rely(adapterDeployer);
    }

    /// @notice deploys the assessor contract
    function deployAssessor() public {
        require(assessor == address(0) && deployer == address(1));
        assessor = assessorFab.newAssessor();
        AuthLike(assessor).rely(root);
        if (adapterDeployer != address(0)) AuthLike(assessor).rely(adapterDeployer);
    }

    /// @notice deploys the pool admin contract
    function deployPoolAdmin() public {
        require(poolAdmin == address(0) && deployer == address(1));
        poolAdmin = poolAdminFab.newPoolAdmin();
        PoolAdminLike(poolAdmin).rely(root);
        if (adapterDeployer != address(0)) PoolAdminLike(poolAdmin).rely(adapterDeployer);
    }

    /// @notice deploys the coordinator contract
    function deployCoordinator() public {
        require(coordinator == address(0) && deployer == address(1));
        coordinator = coordinatorFab.newCoordinator(challengeTime);
        AuthLike(coordinator).rely(root);
    }

    /// @notice wires the deployed lender contracts together
    function deploy() public virtual {
        require(
            coordinator != address(0) && assessor != address(0) && reserve != address(0) && seniorTranche != address(0)
        );

        require(!wired, "lender contracts already wired"); // make sure lender contracts only wired once
        wired = true;

        // required depends
        // reserve
        AuthLike(reserve).rely(seniorTranche);
        AuthLike(reserve).rely(juniorTranche);
        AuthLike(reserve).rely(coordinator);
        AuthLike(reserve).rely(assessor);

        // tranches
        DependLike(seniorTranche).depend("reserve", reserve);
        DependLike(juniorTranche).depend("reserve", reserve);
        AuthLike(seniorTranche).rely(coordinator);
        AuthLike(juniorTranche).rely(coordinator);
        AuthLike(seniorTranche).rely(seniorOperator);
        AuthLike(juniorTranche).rely(juniorOperator);

        // coordinator implements epoch ticker interface
        DependLike(seniorTranche).depend("coordinator", coordinator);
        DependLike(juniorTranche).depend("coordinator", coordinator);

        //restricted token
        DependLike(seniorToken).depend("memberlist", seniorMemberlist);
        DependLike(juniorToken).depend("memberlist", juniorMemberlist);

        //allow tinlake contracts to hold drop/tin tokens
        MemberlistLike(juniorMemberlist).updateMember(juniorTranche, type(uint256).max);
        MemberlistLike(seniorMemberlist).updateMember(seniorTranche, type(uint256).max);

        // operator
        DependLike(seniorOperator).depend("tranche", seniorTranche);
        DependLike(juniorOperator).depend("tranche", juniorTranche);
        DependLike(seniorOperator).depend("token", seniorToken);
        DependLike(juniorOperator).depend("token", juniorToken);

        // coordinator
        DependLike(coordinator).depend("seniorTranche", seniorTranche);
        DependLike(coordinator).depend("juniorTranche", juniorTranche);
        DependLike(coordinator).depend("assessor", assessor);

        AuthLike(coordinator).rely(poolAdmin);

        // assessor
        DependLike(assessor).depend("seniorTranche", seniorTranche);
        DependLike(assessor).depend("juniorTranche", juniorTranche);
        DependLike(assessor).depend("reserve", reserve);

        AuthLike(assessor).rely(coordinator);
        AuthLike(assessor).rely(reserve);
        AuthLike(assessor).rely(poolAdmin);

        // poolAdmin
        DependLike(poolAdmin).depend("assessor", assessor);
        DependLike(poolAdmin).depend("juniorMemberlist", juniorMemberlist);
        DependLike(poolAdmin).depend("seniorMemberlist", seniorMemberlist);
        DependLike(poolAdmin).depend("coordinator", coordinator);

        AuthLike(juniorMemberlist).rely(poolAdmin);
        AuthLike(seniorMemberlist).rely(poolAdmin);

        if (memberAdmin != address(0)) AuthLike(juniorMemberlist).rely(memberAdmin);
        if (memberAdmin != address(0)) AuthLike(seniorMemberlist).rely(memberAdmin);

        FileLike(assessor).file("seniorInterestRate", seniorInterestRate.value);
        FileLike(assessor).file("maxReserve", maxReserve);
        FileLike(assessor).file("maxSeniorRatio", maxSeniorRatio.value);
        FileLike(assessor).file("minSeniorRatio", minSeniorRatio.value);
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