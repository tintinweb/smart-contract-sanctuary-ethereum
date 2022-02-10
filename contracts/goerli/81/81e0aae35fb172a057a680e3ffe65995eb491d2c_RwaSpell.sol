/**
 *Submitted for verification at Etherscan.io on 2022-02-10
*/

pragma solidity 0.5.12;

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

interface JugAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function ilks(bytes32) external view returns (uint256, uint256);
    function vat() external view returns (address);
    function vow() external view returns (address);
    function base() external view returns (address);
    function init(bytes32) external;
    function file(bytes32, bytes32, uint256) external;
    function file(bytes32, uint256) external;
    function file(bytes32, address) external;
    function drip(bytes32) external returns (uint256);
}

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

interface RwaLiquidationLike {
    function wards(address) external returns (uint256);
    function ilks(bytes32) external returns (string memory,address,uint48,uint48);
    function rely(address) external;
    function deny(address) external;
    function init(bytes32, uint256, string calldata, uint48) external;
    function tell(bytes32) external;
    function cure(bytes32) external;
    function cull(bytes32) external;
    function good(bytes32) external view;
}

interface RwaOutputConduitLike {
    function wards(address) external returns (uint256);
    function can(address) external returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function hope(address) external;
    function nope(address) external;
    function bud(address) external returns (uint256);
    function kiss(address) external;
    function diss(address) external;
    function pick(address) external;
    function push() external;
}

interface RwaUrnLike {
    function hope(address) external;
}

contract SpellAction {
    // KOVAN ADDRESSES
    //
    // The contracts in this list should correspond to MCD core contracts, verify
    // against the current release list at:
    //     https://changelog.makerdao.com/releases/kovan/latest/contracts.json
    ChainlogAbstract constant CHANGELOG =
        ChainlogAbstract(0x7368c1a7E459ab0b53A54867B289F45ceE519550);

    /*
        OPERATOR: 0xD23beB204328D7337e3d2Fb9F150501fDC633B0e
        TRUST1: 0xda0fab060e6cc7b1C0AA105d29Bd50D71f036711
        TRUST2: 0xDA0111100cb6080b43926253AB88bE719C60Be13
        ILK: RWA001-A
        RWA001: 0x8F9A8cbBdfb93b72d646c8DEd6B4Fe4D86B315cB
        MCD_JOIN_RWA001_A: 0x029A554f252373e146f76Fa1a7455f73aBF4d38e
        RWA001_A_URN: 0x3Ba90D86f7E3218C48b7E0FCa959EcF43d9A30F4
        RWA001_A_INPUT_CONDUIT: 0xe37673730F03060922a2Bd8eC5987AfE3eA16a05
        RWA001_A_OUTPUT_CONDUIT: 0xc54fEee07421EAB8000AC8c921c0De9DbfbE780B
        MIP21_LIQUIDATION_ORACLE: 0x2881c5dF65A8D81e38f7636122aFb456514804CC
    */
    address constant RWA999_OPERATOR           = 0x8519cd7e0CF6E757a1Df45c906d640DcEfb2869e;
    address constant RWA999_GEM                = 0xCf6d93E8Da96654771f76f90165B39Ae6647611A;
    address constant MCD_JOIN_RWA999_A         = 0x6605Bf7168223574A5F9AbcaaBf718cF6c674705;
    
    address constant RWA999_A_URN              = 0xc9f6b85b362a338BE0De500AD262f0203942e7eE;
    address constant RWA999_A_INPUT_CONDUIT    = 0x917D49182D46D88f6EC39D2d542d491629A32c5E; //to do
    address constant RWA999_A_OUTPUT_CONDUIT   = 0xe024543da5D4876C234fc70eC4fc6Bc936C43831;
    address constant MIP21_LIQUIDATION_ORACLE  = 0x2881c5dF65A8D81e38f7636122aFb456514804CC; //to do

    uint256 constant THREE_PCT_RATE  = 1000000000937303470807876289;

    // precision
    uint256 constant public THOUSAND = 10 ** 3;
    uint256 constant public MILLION  = 10 ** 6;
    uint256 constant public WAD      = 10 ** 18;
    uint256 constant public RAY      = 10 ** 27;
    uint256 constant public RAD      = 10 ** 45;

    uint256 constant RWA999_A_INITIAL_DC    = 1000 * RAD;
    uint256 constant RWA999_A_INITIAL_PRICE = 1060 * WAD;

    // MIP13c3-SP4 Declaration of Intent & Commercial Points -
    //   Off-Chain Asset Backed Lender to onboard Real World Assets
    //   as Collateral for a DAI loan
    //
    // https://ipfs.io/ipfs/QmdmAUTU3sd9VkdfTZNQM6krc9jsKgF2pz7W1qvvfJo1xk
    string constant DOC = "Testing Purposes"; //change this?

    function execute() external {
        address MCD_VAT  = ChainlogAbstract(CHANGELOG).getAddress("MCD_VAT");
        address MCD_JUG  = ChainlogAbstract(CHANGELOG).getAddress("MCD_JUG");
        address MCD_SPOT = ChainlogAbstract(CHANGELOG).getAddress("MCD_SPOT");

        // RWA999-A collateral deploy

        // Set ilk bytes32 variable
        bytes32 ilk = "RWA999-A";

        // add RWA-999 contract to the changelog
        CHANGELOG.setAddress("RWA999", RWA999_GEM);
        CHANGELOG.setAddress("MCD_JOIN_RWA999_A", MCD_JOIN_RWA999_A);
        CHANGELOG.setAddress("MIP21_LIQUIDATION_ORACLE", MIP21_LIQUIDATION_ORACLE);
        CHANGELOG.setAddress("RWA999_A_URN", RWA999_A_URN);
        CHANGELOG.setAddress("RWA999_A_INPUT_CONDUIT", RWA999_A_INPUT_CONDUIT);
        CHANGELOG.setAddress("RWA999_A_OUTPUT_CONDUIT", RWA999_A_OUTPUT_CONDUIT);

        // bump changelog version
        // TODO make sure to update this version on mainnet
        // CHANGELOG.setVersion("1.2.9");

        // Sanity checks
        require(GemJoinAbstract(MCD_JOIN_RWA999_A).vat() == MCD_VAT, "join-vat-not-match");
        require(GemJoinAbstract(MCD_JOIN_RWA999_A).ilk() == ilk, "join-ilk-not-match");
        require(GemJoinAbstract(MCD_JOIN_RWA999_A).gem() == RWA999_GEM, "join-gem-not-match");
        require(GemJoinAbstract(MCD_JOIN_RWA999_A).dec() == DSTokenAbstract(RWA999_GEM).decimals(), "join-dec-not-match");

        // init the RwaLiquidationOracle
        // doc: "doc"
        // tau: 5 minutes
        RwaLiquidationLike(MIP21_LIQUIDATION_ORACLE).init(
            ilk, RWA999_A_INITIAL_PRICE, DOC, 300
        );
        (,address pip,,) = RwaLiquidationLike(MIP21_LIQUIDATION_ORACLE).ilks(ilk);
        CHANGELOG.setAddress("PIP_RWA999", pip);

        // Set price feed for RWA999
        SpotAbstract(MCD_SPOT).file(ilk, "pip", pip);

        // Init RWA-999 in Vat
        VatAbstract(MCD_VAT).init(ilk);
        // Init RWA-999 in Jug
        JugAbstract(MCD_JUG).init(ilk);

        // Allow RWA-999 Join to modify Vat registry
        VatAbstract(MCD_VAT).rely(MCD_JOIN_RWA999_A);

        // Allow RwaLiquidationOracle to modify Vat registry
        VatAbstract(MCD_VAT).rely(MIP21_LIQUIDATION_ORACLE);

        // 1000 debt ceiling
        VatAbstract(MCD_VAT).file(ilk, "line", RWA999_A_INITIAL_DC);
        VatAbstract(MCD_VAT).file("Line", VatAbstract(MCD_VAT).Line() + RWA999_A_INITIAL_DC);

        // No dust
        // VatAbstract(MCD_VAT).file(ilk, "dust", 0)

        // 3% stability fee
        JugAbstract(MCD_JUG).file(ilk, "duty", THREE_PCT_RATE);

        // collateralization ratio 100%
        SpotAbstract(MCD_SPOT).file(ilk, "mat", RAY);

        // poke the spotter to pull in a price
        SpotAbstract(MCD_SPOT).poke(ilk);

        // give the urn permissions on the join adapter
        GemJoinAbstract(MCD_JOIN_RWA999_A).rely(RWA999_A_URN);

        // set up the urn
        RwaUrnLike(RWA999_A_URN).hope(RWA999_OPERATOR);

        // set up output conduit
        RwaOutputConduitLike(RWA999_A_OUTPUT_CONDUIT).hope(RWA999_OPERATOR);
        // could potentially kiss some BD addresses if they are available
    }
}

contract RwaSpell {

    ChainlogAbstract constant CHANGELOG =
        ChainlogAbstract(0x7368c1a7E459ab0b53A54867B289F45ceE519550);

    DSPauseAbstract public pause =
        DSPauseAbstract(CHANGELOG.getAddress("MCD_PAUSE"));
    address         public action;
    bytes32         public tag;
    uint256         public eta;
    bytes           public sig;
    uint256         public expiration;
    bool            public done;

    string constant public description = "Test Goerli Spell Deploy";

    constructor() public {
        sig = abi.encodeWithSignature("execute()");
        action = address(new SpellAction());
        bytes32 _tag;
        address _action = action;
        assembly { _tag := extcodehash(_action) }
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