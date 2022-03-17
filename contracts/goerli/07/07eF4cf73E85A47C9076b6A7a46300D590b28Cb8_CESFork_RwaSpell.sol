/**
 *Submitted for verification at Etherscan.io on 2022-03-16
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/spells/CESFork_GoerliRwaSpell.sol
// SPDX-License-Identifier: AGPL-3.0-or-later AND GPL-3.0-or-later
pragma solidity >=0.5.12 >=0.6.12 <0.7.0;

////// lib/dss-interfaces/src/dapp/DSPauseAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/dapphub/ds-pause
interface DSPauseAbstract {
    function owner() external view returns (address);
    function authority() external view returns (address);
    function setOwner(address) external;
    function setAuthority(address) external;
    function setDelay(uint256) external;
    function plans(bytes32) external view returns (bool);
    function proxy() external view returns (address);
    function delay() external view returns (uint256);
    function plot(address, bytes32, bytes calldata, uint256) external;
    function drop(address, bytes32, bytes calldata, uint256) external;
    function exec(address, bytes32, bytes calldata, uint256) external returns (bytes memory);
}

////// lib/dss-interfaces/src/dapp/DSTokenAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/dapphub/ds-token/blob/master/src/token.sol
interface DSTokenAbstract {
    function name() external view returns (bytes32);
    function symbol() external view returns (bytes32);
    function decimals() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function allowance(address, address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function approve(address) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function push(address, uint256) external;
    function pull(address, uint256) external;
    function move(address, address, uint256) external;
    function mint(uint256) external;
    function mint(address,uint) external;
    function burn(uint256) external;
    function burn(address,uint) external;
    function setName(bytes32) external;
    function authority() external view returns (address);
    function owner() external view returns (address);
    function setOwner(address) external;
    function setAuthority(address) external;
}

////// lib/dss-interfaces/src/dss/ChainlogAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss-chain-log
interface ChainlogAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function keys() external view returns (bytes32[] memory);
    function version() external view returns (string memory);
    function ipfs() external view returns (string memory);
    function setVersion(string calldata) external;
    function setSha256sum(string calldata) external;
    function setIPFS(string calldata) external;
    function setAddress(bytes32,address) external;
    function removeAddress(bytes32) external;
    function count() external view returns (uint256);
    function get(uint256) external view returns (bytes32,address);
    function list() external view returns (bytes32[] memory);
    function getAddress(bytes32) external view returns (address);
}

// Helper function for returning address or abstract of Chainlog
//  Valid on Mainnet, Kovan, Rinkeby, Ropsten, and Goerli
contract ChainlogHelper {
    address          public constant ADDRESS  = 0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F;
    ChainlogAbstract public constant ABSTRACT = ChainlogAbstract(ADDRESS);
}

////// lib/dss-interfaces/src/dss/GemJoinAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss/blob/master/src/join.sol
interface GemJoinAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function vat() external view returns (address);
    function ilk() external view returns (bytes32);
    function gem() external view returns (address);
    function dec() external view returns (uint256);
    function live() external view returns (uint256);
    function cage() external;
    function join(address, uint256) external;
    function exit(address, uint256) external;
}

////// lib/dss-interfaces/src/dss/JugAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss/blob/master/src/jug.sol
interface JugAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function ilks(bytes32) external view returns (uint256, uint256);
    function vat() external view returns (address);
    function vow() external view returns (address);
    function base() external view returns (uint256);
    function init(bytes32) external;
    function file(bytes32, bytes32, uint256) external;
    function file(bytes32, uint256) external;
    function file(bytes32, address) external;
    function drip(bytes32) external returns (uint256);
}

////// lib/dss-interfaces/src/dss/SpotAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss/blob/master/src/spot.sol
interface SpotAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function ilks(bytes32) external view returns (address, uint256);
    function vat() external view returns (address);
    function par() external view returns (uint256);
    function live() external view returns (uint256);
    function file(bytes32, bytes32, address) external;
    function file(bytes32, uint256) external;
    function file(bytes32, bytes32, uint256) external;
    function poke(bytes32) external;
    function cage() external;
}

////// lib/dss-interfaces/src/dss/VatAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss/blob/master/src/vat.sol
interface VatAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function can(address, address) external view returns (uint256);
    function hope(address) external;
    function nope(address) external;
    function ilks(bytes32) external view returns (uint256, uint256, uint256, uint256, uint256);
    function urns(bytes32, address) external view returns (uint256, uint256);
    function gem(bytes32, address) external view returns (uint256);
    function dai(address) external view returns (uint256);
    function sin(address) external view returns (uint256);
    function debt() external view returns (uint256);
    function vice() external view returns (uint256);
    function Line() external view returns (uint256);
    function live() external view returns (uint256);
    function init(bytes32) external;
    function file(bytes32, uint256) external;
    function file(bytes32, bytes32, uint256) external;
    function cage() external;
    function slip(bytes32, address, int256) external;
    function flux(bytes32, address, address, uint256) external;
    function move(address, address, uint256) external;
    function frob(bytes32, address, address, address, int256, int256) external;
    function fork(bytes32, address, address, int256, int256) external;
    function grab(bytes32, address, address, address, int256, int256) external;
    function heal(uint256) external;
    function suck(address, address, uint256) external;
    function fold(bytes32, address, int256) external;
}

////// src/spells/CESFork_GoerliRwaSpell.sol
/* pragma solidity ^0.6.12; */

/* import "dss-interfaces/dss/VatAbstract.sol"; */
/* import "dss-interfaces/dapp/DSPauseAbstract.sol"; */
/* import "dss-interfaces/dss/JugAbstract.sol"; */
/* import "dss-interfaces/dss/SpotAbstract.sol"; */
/* import "dss-interfaces/dss/GemJoinAbstract.sol"; */
/* import "dss-interfaces/dapp/DSTokenAbstract.sol"; */
/* import "dss-interfaces/dss/ChainlogAbstract.sol"; */

interface RwaLiquidationLike_1 {
    function wards(address) external returns (uint256);

    function ilks(bytes32)
        external
        returns (
            string memory,
            address,
            uint48,
            uint48
        );

    function rely(address) external;

    function deny(address) external;

    function init(
        bytes32,
        uint256,
        string calldata,
        uint48
    ) external;

    function tell(bytes32) external;

    function cure(bytes32) external;

    function cull(bytes32) external;

    function good(bytes32) external view;
}

interface RwaOutputConduitLike_1 {
    function wards(address) external returns (uint256);

    function can(address) external returns (uint256);

    function rely(address) external;

    function deny(address) external;

    function hope(address) external;

    function mate(address) external;

    function nope(address) external;

    function bud(address) external returns (uint256);

    function pick(address) external;

    function push() external;
}

interface RwaInputConduitLike_2 {
    function rely(address usr) external;

    function deny(address usr) external;

    function mate(address usr) external;

    function hate(address usr) external;

    function push() external;
}

interface RwaUrnLike_2 {
    function hope(address) external;
}

contract SpellAction_1 {
    // GOERLI ADDRESSES

    // The contracts in this list should correspond to MCD core contracts, verify
    // against the current release list at:
    //     https://github.com/clio-finance/ces-goerli/blob/master/contracts.json
    ChainlogAbstract constant CHANGELOG = ChainlogAbstract(0x7EafEEa64bF6F79A79853F4A660e0960c821BA50);

    address constant MIP21_LIQUIDATION_ORACLE = 0x493A7F7E6f44D3bd476bc1bfBBe191164269C0Cc;
    address constant RWA008AT1 = 0xd40D6073D905d5978a211bA64F74C77E8e683a54;
    address constant MCD_JOIN_RWA008AT1_A = 0x95191eB3Ab5bEB48a3C0b1cd0E6d918931448a1E;
    address constant RWA008AT1_A_URN = 0xcc5b51BaCc1855ed99771D703Fd8Ac4555300b3f;
    address constant RWA008AT1_A_INPUT_CONDUIT = 0xd73442694733019A976559a03C8ea5dFb052fB89;
    address constant RWA008AT1_A_OUTPUT_CONDUIT = 0x08DAA71311F2EB974C35424BCc2af239378c7E61;
    address constant RWA008AT1_A_OPERATOR = 0x50b8C31E88eE19c480Cc60c780c77051D3aFE775;
    address constant RWA008AT1_A_MATE = 0x62431c4563C8C24fE0756D541c72D2A51B635b96;

    uint256 constant THREE_PCT_RATE = 1000000000937303470807876289; // TODO RWA team should provide this one

    /// @notice precision
    uint256 public constant THOUSAND = 10**3;
    uint256 public constant MILLION = 10**6;
    uint256 public constant WAD = 10**18;
    uint256 public constant RAY = 10**27;
    uint256 public constant RAD = 10**45;

    uint256 constant RWA008AT1_A_INITIAL_DC = 80000000 * RAD; // TODO RWA team should provide
    uint256 constant RWA008AT1_A_INITIAL_PRICE = 115000 * WAD; // TODO RWA team should provide
    uint48 constant RWA008AT1_A_TAU = 1 weeks; // TODO RWA team should provide

    /**
     * @notice MIP13c3-SP4 Declaration of Intent & Commercial Points -
     *   Off-Chain Asset Backed Lender to onboard Real World Assets
     *   as Collateral for a DAI loan
     *
     * https://ipfs.io/ipfs/QmdmAUTU3sd9VkdfTZNQM6krc9jsKgF2pz7W1qvvfJo1xk
     */
    string constant DOC = "QmdmAUTU3sd9VkdfTZNQM6krc9jsKgF2pz7W1qvvfJo1xk"; // TODO Reference to a documents which describe deal (should be uploaded to IPFS)

    function execute() external {
        address MCD_VAT = ChainlogAbstract(CHANGELOG).getAddress("MCD_VAT");
        address MCD_JUG = ChainlogAbstract(CHANGELOG).getAddress("MCD_JUG");
        address MCD_SPOT = ChainlogAbstract(CHANGELOG).getAddress("MCD_SPOT");

        // RWA008AT1-A collateral deploy

        // Set ilk bytes32 variable
        bytes32 ilk = "RWA008AT1-A";

        CHANGELOG.setAddress("MIP21_LIQUIDATION_ORACLE", MIP21_LIQUIDATION_ORACLE);
        // Add RWA008AT1 contract to the changelog
        CHANGELOG.setAddress("RWA008AT1", RWA008AT1);
        CHANGELOG.setAddress("MCD_JOIN_RWA008AT1_A", MCD_JOIN_RWA008AT1_A);
        CHANGELOG.setAddress("RWA008AT1_A_URN", RWA008AT1_A_URN);
        CHANGELOG.setAddress("RWA008AT1_A_INPUT_CONDUIT", RWA008AT1_A_INPUT_CONDUIT);
        CHANGELOG.setAddress("RWA008AT1_A_OUTPUT_CONDUIT", RWA008AT1_A_OUTPUT_CONDUIT);

        // bump changelog version
        // TODO make sure to update this version on mainnet
        CHANGELOG.setVersion("1.1.0");

        // Sanity checks
        require(GemJoinAbstract(MCD_JOIN_RWA008AT1_A).vat() == MCD_VAT, "join-vat-not-match");
        require(GemJoinAbstract(MCD_JOIN_RWA008AT1_A).ilk() == ilk, "join-ilk-not-match");
        require(GemJoinAbstract(MCD_JOIN_RWA008AT1_A).gem() == RWA008AT1, "join-gem-not-match");
        require(
            GemJoinAbstract(MCD_JOIN_RWA008AT1_A).dec() == DSTokenAbstract(RWA008AT1).decimals(),
            "join-dec-not-match"
        );

        /*
         * init the RwaLiquidationOracle2
         */
        // TODO: this should be verified with RWA Team (5 min for testing is good)
        RwaLiquidationLike_1(MIP21_LIQUIDATION_ORACLE).init(ilk, RWA008AT1_A_INITIAL_PRICE, DOC, RWA008AT1_A_TAU);
        (, address pip, , ) = RwaLiquidationLike_1(MIP21_LIQUIDATION_ORACLE).ilks(ilk);
        CHANGELOG.setAddress("PIP_RWA008AT1", pip);

        // Set price feed for RWA008AT1
        SpotAbstract(MCD_SPOT).file(ilk, "pip", pip);

        // Init RWA008AT1 in Vat
        VatAbstract(MCD_VAT).init(ilk);
        // Init RWA008AT1 in Jug
        JugAbstract(MCD_JUG).init(ilk);

        // Allow RWA008AT1 Join to modify Vat registry
        VatAbstract(MCD_VAT).rely(MCD_JOIN_RWA008AT1_A);

        // Allow RwaLiquidationOracle2 to modify Vat registry
        VatAbstract(MCD_VAT).rely(MIP21_LIQUIDATION_ORACLE);

        // 1000 debt ceiling
        VatAbstract(MCD_VAT).file(ilk, "line", RWA008AT1_A_INITIAL_DC);
        VatAbstract(MCD_VAT).file("Line", VatAbstract(MCD_VAT).Line() + RWA008AT1_A_INITIAL_DC);

        // No dust
        // VatAbstract(MCD_VAT).file(ilk, "dust", 0)

        // 3% stability fee // TODO get from RWA
        JugAbstract(MCD_JUG).file(ilk, "duty", THREE_PCT_RATE);

        // collateralization ratio 100%
        SpotAbstract(MCD_SPOT).file(ilk, "mat", RAY); // TODO Should get from RWA team

        // poke the spotter to pull in a price
        SpotAbstract(MCD_SPOT).poke(ilk);

        // give the urn permissions on the join adapter
        GemJoinAbstract(MCD_JOIN_RWA008AT1_A).rely(RWA008AT1_A_URN);

        // set up the urn
        RwaUrnLike_2(RWA008AT1_A_URN).hope(RWA008AT1_A_OPERATOR);

        // set up output conduit
        RwaOutputConduitLike_1(RWA008AT1_A_OUTPUT_CONDUIT).hope(RWA008AT1_A_OPERATOR);

        // whitelist DIIS Group in the conduits
        RwaOutputConduitLike_1(RWA008AT1_A_OUTPUT_CONDUIT).mate(RWA008AT1_A_MATE);
        RwaInputConduitLike_2(RWA008AT1_A_INPUT_CONDUIT).mate(RWA008AT1_A_MATE);
    }
}

contract CESFork_RwaSpell {
    ChainlogAbstract constant CHANGELOG = ChainlogAbstract(0x7EafEEa64bF6F79A79853F4A660e0960c821BA50);

    DSPauseAbstract public pause = DSPauseAbstract(CHANGELOG.getAddress("MCD_PAUSE"));
    address public action;
    bytes32 public tag;
    uint256 public eta;
    bytes public sig;
    uint256 public expiration;
    bool public done;

    string public constant description = "CESFork Goerli Spell Deploy";

    constructor() public {
        sig = abi.encodeWithSignature("execute()");
        action = address(new SpellAction_1());
        bytes32 _tag;
        address _action = action;
        assembly {
            _tag := extcodehash(_action)
        }
        tag = _tag;
        expiration = block.timestamp + 30 days;
    }

    function schedule() public {
        require(block.timestamp <= expiration, "This contract has expired");
        require(eta == 0, "This spell has already been scheduled");
        eta = block.timestamp + DSPauseAbstract(pause).delay();
        pause.plot(action, tag, sig, eta);
    }

    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}