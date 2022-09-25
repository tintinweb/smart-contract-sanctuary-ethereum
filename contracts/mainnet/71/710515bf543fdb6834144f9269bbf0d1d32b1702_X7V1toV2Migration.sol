/**
 *Submitted for verification at Etherscan.io on 2022-09-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/*

 /$$   /$$ /$$$$$$$$       /$$$$$$$$ /$$
| $$  / $$|_____ $$/      | $$_____/|__/
|  $$/ $$/     /$$/       | $$       /$$ /$$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$$  /$$$$$$
 \  $$$$/     /$$/        | $$$$$   | $$| $$__  $$ |____  $$| $$__  $$ /$$_____/ /$$__  $$
  >$$  $$    /$$/         | $$__/   | $$| $$  \ $$  /$$$$$$$| $$  \ $$| $$      | $$$$$$$$
 /$$/\  $$  /$$/          | $$      | $$| $$  | $$ /$$__  $$| $$  | $$| $$      | $$_____/
| $$  \ $$ /$$/           | $$      | $$| $$  | $$|  $$$$$$$| $$  | $$|  $$$$$$$|  $$$$$$$
|__/  |__/|__/            |__/      |__/|__/  |__/ \_______/|__/  |__/ \_______/ \_______/

Contract: Smart Contract for orchestrating the X7 Finance V1 to V2 Migration

WARNING:

    DO NOT SEND YOUR TOKENS DIRECTLY TO THIS CONTRACT.
    IF YOU DO SO, IT WILL BE A DONATION TO THE PROJECT AND YOU WILL RECEIVE NOTHING IN RETURN.
    YOU MUST USE THE submitManyTokens FUNCTION VIA ETHERSCAN, A SCRIPT, OR THE dAPP.

                                YOU HAVE BEEN WARNED.

The migration from the V1 ecosystem to the V2 ecosystem will happen in time bound phases
that are encoded in the contract.

Phase 0: Review

    The contract goes live and is verified.
    The community will have some time to review the contract before it is live.

Phase 1: Migrate In

    The function goLive() will be called by the contract owner.
    This will start the clock on the migration and there is no turning back.

    The contents of the goLive function is copied here:

        function goLive() external onlyOwner {
            // This allows migration to begin
            liveTime = block.timestamp;

            // This allows the migration wallet snapshot to be submitted
            walletSnapshotAllowTime = liveTime + walletSnapshotSecondsOffset;

            // Once this time is passed, the migration steps are unlocked
            migrationFreeTime = block.timestamp + migrationFreeSecondsOffset;

            // The migration is expected to be run to completion once the migrationFreeTime has passed.
            // However, to ensure that there is no risk that tokens would be permanently locked within this contract
            // after this time is passed any one may run the migration steps.
            // This is not an expected outcome but is provided as an additional safety measure to reduce the trust needed
            // to carry out a successful migration.
            migrationNoRunAuthTimeout = block.timestamp + migrationNoRunAuthOffset;
        }

    After the migration has been live for 2 days, the function to submit the wallet
    snapshot will be enabled. Anyone that migrates their tokens will automatically
    be included in the migration. However long term holders or holders that lost track
    of this investment should not be penalized. This snapshot will ensure that those
    unengaged holders are included in the token snapshot that will happen during the
    migration phase.

    The community will then have 1 day to review that list.

    The developers will continue to update the list of active wallets as best they can,
    but after the initial list is submitted, any new wallets that buy can only guarantee
    their inclusion in the migration by migrating themselves via the migration dApp or
    contract call.

Phase 2: Migrate Out

    This phase will be accomplished via numbered, ordered functions that can only be called in that specific order

    They look like:

        function migrationStep{number}{Thing that it is doing}

    These functions can be called by the contract owner after the migrationFreeTime (3 days)
    has passed, or by anyone after the migrationNoRunAuthTimeout (6 days) has passed.

    The method for the migration has to account for a number of factors:

        1. Preserving investor value
        2. Improving the liquidity ratio for improved trading experience post migration
        3. Preventing any possibility for griefing or exploitation
        4. Ensuring it is as trustless as possible. If you cannot live by your own tenets, who else will?

    a. Prior to the migration start we will deploy ALL the uniswap pair contracts (unfunded), as this is a
        gas intensive step that cannot be accomplished later. Since all relevant v2 tokens will be locked
        in this contract, there is no external affect other than the creation of new Uniswap pairs. There
        are 17 Uniswap trading pairs (7 token/ETH pairs and 10 pairs inside the constellation). Additionally
        the v2 tokens owner will temporarily transfer ownership to this contract, so the migration contract
        can act as the v2 token owner and set the proper settings like marking which addresses are trading
        pairs and enabling trading in the final stage.

    b. In a single transaction for each V1 token, a holder balance snapshot will be taken. this snapshot
        determines how many tokens may be migrated for that wallet. The wallet will be unable to migrate
        more than that amount. This will also snapshot the liquidity and market cap of the tokens.

        All tokens that have been submitted to this contract will be swapped for ETH via the V1 token pair.
        Whatever capital is left within the V1 token pair may be recovered post migration as additional
        wallets migrate their tokens manually.

    c. Based on the harvested liquidity from step (b) we will calculate the new ETH and token reserves
        for each ETH pair. We will cap liquidity increases in X7R and X7DAO to a 2X improvement to liquidity
        and 3X improvement to liquidity for each X7100 token. Holder token positions will be modified so
        that their pre-migration and post-migration total value will be equivalent.

    d. In a single transaction we will add liquidity to all V2 token trading pairs. At this point the
        V2 tokens will be READY to go live. However, to ensure that all V1 token holders have possession
        of their new v2 tokens, the token contracts will NOT be enabled for any transfers accept from
        this migration contract until enabled at the end of the migration.

    e. In a number of additional steps, we will airdrop all the V2 tokens. These have been split up to due
        to the gas costs associated with transferring tokens to many 100s of wallets.

    f. Once all v2 tokens have been airdropped, the final migration step migrationStep14EnableTrading() will
        be called. This will enable trading and transfers on all v2 tokens.

    Any holder of v1 tokens may continue to use the dAPP or call the submitManyTokens() function on the
    contract to migrate any tokens that were included in the wallet snapshots earlier.

    The final step that will be taken is the owner of this contract will regain ownership of all the v2 tokens.
    Please see each v2 token to see the limited changes that can be made by the contract owner.

    This migration is necessary for the future success of the X7 ecosystem and product offerings. The greater
    the participation, the greater the success!

    A note on trust and safety:

        Migrations often involve, at some point, a single individual holding all the tokens and/or all the
        capital from the v1. The investors are often asked to, just momentarily, trust that single individual
        to do the right thing and use that capital for the migration.

        The developers of this project are not known to you. You have no reason to trust us. We will never ask
        for you to trust us.

        This migration contract is deterministic, and once it is live, either the developer will execute each
        step of the migration in series, or if enough time passes, any one can do so.

        The only trust that exists is the wallet snapshot to preserve the token value for inactive or inattentive
        investors. That is why there is a delay between the wallet snapshot and the migration - to allow the
        community to verify its accuracy.

        In addition to the X7 product offerings, we think X7 can represent a model for how every DeFi project
        should handle trust. Not by promising or doxxing or reputation, but by game theory and code.

        Trust no one. Trust code. Long live DeFi.

*/

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address owner_) {
        _transferOwnership(owner_);
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IX7Token is IERC20 {
    function setAMM(address, bool) external;
    function setOffRampPair(address) external;
    function enableTrading() external;
}

interface IX7LiquidityHub {
    function setOffRampPair(address) external;
}

interface IX7100LiquidityHub {
    function setOffRampPair(address, address) external;
    function setConstellationToken(address, bool) external;
}

contract X7V1toV2Migration is Ownable {
    // v1 token address => ETH
    mapping(address => uint256) public oldETHReserves;

    // v2 token address => ETH
    mapping(address => uint256) public newETHReserves;

    // v1 token address => ETH
    mapping(address => uint256) public oldTokenReserves;

    // v2 token address => ETH
    mapping(address => uint256) public newTokenReserves;

    mapping(address => mapping(address => uint256)) public X7000TokenReserves;

    // v1 token address => v2 token interface
    mapping(address => address) public v2TokenLookup;

    // v1 token address => is a constellation token
    mapping(address => bool) public isConstellation;

    // v2 token address => v1 token
    mapping(address => address) public oldConstellationTokenLookup;

    // v1 token address => total tokens in the "internal" pairs
    mapping(address => uint256) public oldConstellationNonCirculatingTokenSupply;

    // v1 token address => v1 token address => total tokens in the token-token trading pair
    mapping(address => mapping(address => uint256)) public oldConstellationNonCirculatingTokenReserve;

    // token => bool
    mapping(address => bool) public isV1Token;

    // token => list of holders
    mapping(address => address[]) public v1TokenHolders;

    // token => address => isAv1TokenHolder
    mapping(address => mapping(address => bool)) public isAv1TokenHolder;

    // v1 token => old supply
    mapping(address => uint256) public oldSupply;

    // v1 token => new supply (weighted)
    mapping(address => uint256) public newSupplyLookup;

    uint256 public totalOldETHReserves;
    uint256 public totalX7000ETHReserves;

    bool public migrationStep01Complete;
    bool public migrationStep02Complete;
    bool public migrationStep03Complete;
    bool public migrationStep04Complete;
    bool public migrationStep05Complete;
    bool public migrationStep06Complete;

    bool public migrationStep07Complete;
    bool public migrationStep08Complete;
    bool public migrationStep09Complete;
    bool public migrationStep10Complete;
    bool public migrationStep11Complete;
    bool public migrationStep12Complete;
    bool public migrationStep13Complete;
    bool public migrationStep14Complete;

    address public X7DAOv1;
    address public X7DAOv2;
    address public X7001;
    address public X7101;
    address public X7002;
    address public X7102;
    address public X7003;
    address public X7103;
    address public X7004;
    address public X7104;
    address public X7005;
    address public X7105;
    address public X7;
    address public X7m105;
    address public X7R;

    address public X7TokenTimelock;
    IX7100LiquidityHub public X7100LiquidityHub;
    IX7LiquidityHub public X7RLiquidityHub;
    IX7LiquidityHub public X7DAOLiquidityHub;

    IERC20 public WETH;
    address public X7DAOv1Pair;
    address public X7Pair;
    address public X7m105Pair;
    address public X7001Pair;
    address public X7002Pair;
    address public X7003Pair;
    address public X7004Pair;
    address public X7005Pair;

    mapping(address => mapping(address => uint256)) public balance;
    mapping(address => mapping(address => uint256)) public allowableToMigrate;
    mapping(address => mapping(address => uint256)) public migrated;

    // token => address = token amount
    mapping(address => mapping(address => uint256)) public v2Received;

    bool public postMigration;

    IUniswapV2Router02 public router;
    IUniswapV2Factory public factory;

    // See goLive() function for details on each of these times.
    uint256 public migrationNoRunAuthTimeout;
    uint256 public liveTime;
    uint256 public walletSnapshotAllowTime;
    uint256 public migrationFreeTime;

    uint256 public migrationNoRunAuthOffset;
    uint256 public migrationFreeSecondsOffset;
    uint256 public walletSnapshotSecondsOffset;

    address payable public excessETHReceiver;

    constructor (
        address router_,
        uint256 walletSnapshotSecondsOffset_,
        uint256 migrationFreeSecondsOffset_,
        uint256 migrationNoRunAuthOffset_,
        address excessETHReceiver_
    ) Ownable(address(0x7000a09c425ABf5173FF458dF1370C25d1C58105)) {
        router = IUniswapV2Router02(router_);
        excessETHReceiver = payable(excessETHReceiver_);
        X7TokenTimelock = address(0x7000F4Cddca46FB77196466C3833Be4E89ab810C);

        // TEST SHIM
        migrationFreeSecondsOffset = migrationFreeSecondsOffset_;
        walletSnapshotSecondsOffset = walletSnapshotSecondsOffset_;
        migrationNoRunAuthOffset = migrationNoRunAuthOffset_;

        X7DAOv1 = address(0x7105AA393b9cF9b2497b460837313EA3dBA67Da0);
        X7DAOv2 = address(0x7105E64bF67ECA3Ae9b123F0e5Ca2b83b2eF2dA0);
        X7m105 = address(0x06D5cA7C9accd15a87d4993A421B7e702BDBaB20);
        X7 = address(0x33DaD834eca1290A330C4C4634bC3b64a0197120);

        X7001 = address(0x7001629B8BF9A5D5F204B6d464a06f506fBFA105);
        X7101 = address(0x7101a9392EAc53B01e7c07ca3baCa945A56EE105);
        X7002 = address(0x70021e5edA64e68F035356Ea3DCe14ef87B6F105);
        X7102 = address(0x7102DC82EF61bfB0410B1b1bF8EA74575bf0A105);
        X7003 = address(0x70036Ddf2F2850f6d1B9D78D652776A0d1caB105);
        X7103 = address(0x7103eBdbF1f89be2d53EFF9B3CF996C9E775c105);
        X7004 = address(0x70041dB5aCDf2F8aa648A000FA4A87067AbAE105);
        X7104 = address(0x7104D1f179Cc9cc7fb5c79Be6Da846E3FBC4C105);
        X7005 = address(0x7005D9011F4275747D5cb38bC3deB0C46EdbD105);
        X7105 = address(0x7105FAA4a26eD1c67B8B2b41BEc98F06Ee21D105);
        X7R = address(0x70008F18Fc58928dcE982b0A69C2c21ff80Dca54);

        isV1Token[X7DAOv1] = true;
        isV1Token[X7m105] = true;
        isV1Token[X7] = true;
        isV1Token[X7001] = true;
        isV1Token[X7002] = true;
        isV1Token[X7003] = true;
        isV1Token[X7004] = true;
        isV1Token[X7005] = true;

        v2TokenLookup[X7m105] = X7R;
        v2TokenLookup[X7] = X7R;
        v2TokenLookup[X7DAOv1] = X7DAOv2;
        v2TokenLookup[X7001] = X7101;
        v2TokenLookup[X7002] = X7102;
        v2TokenLookup[X7003] = X7103;
        v2TokenLookup[X7004] = X7104;
        v2TokenLookup[X7005] = X7105;

        oldConstellationTokenLookup[X7101] = X7001;
        oldConstellationTokenLookup[X7102] = X7002;
        oldConstellationTokenLookup[X7103] = X7003;
        oldConstellationTokenLookup[X7104] = X7004;
        oldConstellationTokenLookup[X7105] = X7005;

        isConstellation[X7001] = true;
        isConstellation[X7002] = true;
        isConstellation[X7003] = true;
        isConstellation[X7004] = true;
        isConstellation[X7005] = true;

        factory = IUniswapV2Factory(router.factory());

        WETH = IERC20(router.WETH());

        X7100LiquidityHub = IX7100LiquidityHub(address(0x7102407afa5d6581AAb694FEB03fEB0e7Cf69ebb));
        X7RLiquidityHub = IX7LiquidityHub(address(0x712a166E741405fCb9815Aa5c3442f2Cd3328ebb));
        X7DAOLiquidityHub = IX7LiquidityHub(address(0x7Da0a524d323cdDaF3d465Ba617230f6b91d3ebb));
    }

    modifier migrationLive {
        require(liveTime != 0 && block.timestamp > liveTime);
        _;
    }

    modifier ownerOrAfterTime {
        require(msg.sender == owner() || (migrationNoRunAuthTimeout != 0 && block.timestamp > migrationNoRunAuthTimeout));
        _;
    }

    modifier after48Hours {
        require(migrationFreeTime != 0 && block.timestamp > walletSnapshotAllowTime);
        _;
    }

    modifier after72Hours {
        require(migrationFreeTime != 0 && block.timestamp > migrationFreeTime);
        _;
    }

    receive() external payable {}

    function goLive() external onlyOwner {
        // This allows migration to begin
        liveTime = block.timestamp;

        // This allows the migration wallet snapshot to be submitted
        walletSnapshotAllowTime = liveTime + walletSnapshotSecondsOffset;

        // Once this time is passed, the migration steps are unlocked
        migrationFreeTime = block.timestamp + migrationFreeSecondsOffset;

        // The migration is expected to be run to completion once the migrationFreeTime has passed.
        // However, to ensure that there is no risk that tokens would be permanently locked within this contract
        // after this time is passed any one may run the migration steps.
        // This is not an expected outcome but is provided as an additional safety measure to reduce the trust needed
        // to carry out a successful migration.
        migrationNoRunAuthTimeout = block.timestamp + migrationNoRunAuthOffset;
    }

    function harvestLiquidity(address tokenAddress) external ownerOrAfterTime {
        _harvestLiquidity(tokenAddress);
    }

    function sweepETH() external ownerOrAfterTime {
        require(postMigration);
        require(excessETHReceiver != address(0));
        (bool success, ) = excessETHReceiver.call{value: address(this).balance}("");
        require(success);
    }

    // A wallet must have contributed at least 1000 tokens from across the ecosystem to be considered
    // "in" the migration, for purposes of whitelists and additional perks.
    function inMigration(address holder) external view returns (bool) {
        uint256 tokensMigrated = balance[X7DAOv1][holder];
        tokensMigrated += balance[X7m105][holder];
        tokensMigrated += balance[X7][holder];
        tokensMigrated += balance[X7001][holder];
        tokensMigrated += balance[X7002][holder];
        tokensMigrated += balance[X7003][holder];
        tokensMigrated += balance[X7004][holder];
        tokensMigrated += balance[X7005][holder];

        if (tokensMigrated < 1000 * 10**18) {
            return false;
        } else {
            return true;
        }
    }

    function submitManyTokens(address[] memory tokenAddresses, uint256[] memory tokenAmount) external migrationLive {
        require(tokenAddresses.length == tokenAmount.length);

        for (uint i; i < tokenAddresses.length; i++) {
            _submitTokens(tokenAddresses[i], tokenAmount[i]);
        }
    }

    function withdrawTokens(address tokenAddress, uint256 tokenAmount) external migrationLive {
        require(isV1Token[tokenAddress]);
        if (!postMigration) {
            require(balance[tokenAddress][msg.sender] >= tokenAmount);
            balance[tokenAddress][msg.sender] -= tokenAmount;
            IERC20(tokenAddress).transfer(msg.sender, tokenAmount);
        } else {
            _airdropWalletTokens(tokenAddress, msg.sender);
        }
    }

    function setV1TokenHolderAddresses(address tokenAddress, address[] memory wallets) external after48Hours ownerOrAfterTime {
        require(!migrationStep01Complete);

        for (uint i=0; i < wallets.length; i++) {
            if (!isAv1TokenHolder[tokenAddress][wallets[i]]) {
                v1TokenHolders[tokenAddress].push(wallets[i]);
                isAv1TokenHolder[tokenAddress][wallets[i]] = true;
            }
        }
    }

    //
    //                  START MIGRATION PHASES
    //

    // This step would happen automatically within the migration, but
    // is implemented in a standalone manner to allow creation of token pair contracts
    // prior to the migration for gas cost reasons.
    function migrationStep00CreatePair(uint i) external ownerOrAfterTime {

        address weth = address(WETH);

        address[17] memory tokenAddress = [
            X7R,
            X7DAOv2,
            X7101,
            X7102,
            X7103,
            X7104,
            X7105,

            X7101,
            X7101,
            X7101,
            X7101,
            X7102,
            X7102,
            X7102,
            X7103,
            X7103,
            X7104
        ];

        address[17] memory otherTokenAddress = [
            weth,
            weth,
            weth,
            weth,
            weth,
            weth,
            weth,

            X7102,
            X7103,
            X7104,
            X7105,
            X7103,
            X7104,
            X7105,
            X7104,
            X7105,
            X7105
        ];

        _createPair(tokenAddress[i], otherTokenAddress[i]);

    }

    function migrationStep01SnapshotAndHarvestX7DAO()  external after72Hours ownerOrAfterTime {
        require(!migrationStep01Complete);

        _takeSnapshot(X7DAOv1);
        _harvestLiquidity(X7DAOv1);

        migrationStep01Complete = true;
    }

    function migrationStep02SnapshotAndHarvestX7m105()  external after72Hours ownerOrAfterTime {
        require(migrationStep01Complete);
        require(!migrationStep02Complete);

        _takeSnapshot(X7m105);
        _harvestLiquidity(X7m105);

        migrationStep02Complete = true;
    }

    function migrationStep03SnapshotAndHarvestX7()  external after72Hours ownerOrAfterTime {
        require(migrationStep02Complete);
        require(!migrationStep03Complete);

        _takeSnapshot(X7);
        _harvestLiquidity(X7);

        migrationStep03Complete = true;
    }

    function migrationStep04SnapshotAndHarvestX7000()  external after72Hours ownerOrAfterTime {
        require(migrationStep03Complete);
        require(!migrationStep04Complete);

        _takeSnapshot(X7001);
        _takeSnapshot(X7002);
        _takeSnapshot(X7003);
        _takeSnapshot(X7004);
        _takeSnapshot(X7005);
        _harvestLiquidity(X7001);
        _harvestLiquidity(X7002);
        _harvestLiquidity(X7003);
        _harvestLiquidity(X7004);
        _harvestLiquidity(X7005);

        migrationStep04Complete = true;
    }

    function migrationStep05CalculateNewLiquidity()  external after72Hours ownerOrAfterTime {
        require(migrationStep04Complete);
        require(!migrationStep05Complete);

        _calculateNewLiquidity();

        migrationStep05Complete = true;
    }

    function migrationStep06AddLiquidity()  external after72Hours ownerOrAfterTime {
        require(migrationStep05Complete);
        require(!migrationStep06Complete);

        _addLiquidity(X7DAOv2);
        _addLiquidity(X7R);
        _initiateX7100Launch();
        _setupTokens();

        migrationStep06Complete = true;
        postMigration = true;
    }

    function migrationStep07DistributeV2X7DAO(uint256 startIndex, uint256 endIndex)  external after72Hours ownerOrAfterTime {
        require(migrationStep06Complete);
        _airdropMigrationTokens(X7DAOv1, X7DAOv2, startIndex, endIndex);
        migrationStep07Complete = true;
    }

    function migrationStep08DistributeX7R(uint256 startIndex, uint256 endIndex)  external after72Hours ownerOrAfterTime {
        require(migrationStep06Complete);
        _airdropMigrationTokens(X7m105, X7R, startIndex, endIndex);
        _airdropMigrationTokens(X7, X7R, startIndex, endIndex);
        migrationStep08Complete = true;
    }

    function migrationStep09DistributeX7101(uint256 startIndex, uint256 endIndex)  external after72Hours ownerOrAfterTime {
        require(migrationStep06Complete);
        _airdropMigrationTokens(X7001, X7101, startIndex, endIndex);
        migrationStep09Complete = true;
    }

    function migrationStep10DistributeX7102(uint256 startIndex, uint256 endIndex)  external after72Hours ownerOrAfterTime {
        require(migrationStep06Complete);
        _airdropMigrationTokens(X7002, X7102, startIndex, endIndex);
        migrationStep10Complete = true;
    }

    function migrationStep11DistributeX7103(uint256 startIndex, uint256 endIndex)  external after72Hours ownerOrAfterTime {
        require(migrationStep06Complete);
        _airdropMigrationTokens(X7003, X7103, startIndex, endIndex);
        migrationStep11Complete = true;
    }

    function migrationStep12DistributeX7104(uint256 startIndex, uint256 endIndex)  external after72Hours ownerOrAfterTime {
        require(migrationStep06Complete);
        _airdropMigrationTokens(X7004, X7104, startIndex, endIndex);
        migrationStep12Complete = true;
    }

    function migrationStep13DistributeX7105(uint256 startIndex, uint256 endIndex)  external after72Hours ownerOrAfterTime {
        require(migrationStep06Complete);
        _airdropMigrationTokens(X7005, X7105, startIndex, endIndex);
        migrationStep13Complete = true;
    }

    function migrationStep14EnableTrading()  external after72Hours ownerOrAfterTime {
        require(
            migrationStep13Complete
            && migrationStep12Complete
            && migrationStep11Complete
            && migrationStep10Complete
            && migrationStep09Complete
            && migrationStep08Complete
            && migrationStep07Complete
        );

        IX7Token(X7R).enableTrading();
        IX7Token(X7DAOv2).enableTrading();
        IX7Token(X7101).enableTrading();
        IX7Token(X7102).enableTrading();
        IX7Token(X7103).enableTrading();
        IX7Token(X7104).enableTrading();
        IX7Token(X7105).enableTrading();

        _resetOwnership(X7R);
        _resetOwnership(X7DAOv2);
        _resetOwnership(X7101);
        _resetOwnership(X7102);
        _resetOwnership(X7103);
        _resetOwnership(X7104);
        _resetOwnership(X7105);

        _resetOwnership(address(X7RLiquidityHub));
        _resetOwnership(address(X7DAOLiquidityHub));
        _resetOwnership(address(X7100LiquidityHub));
    }

    //
    //                  END MIGRATION PHASES
    //

    function resetOwnership(address contractAddress) external onlyOwner {
        _resetOwnership(contractAddress);
    }

    function _submitTokens(address tokenAddress, uint256 tokenAmount) internal {
        require(isV1Token[tokenAddress], "Bad Token");
        if (tokenAmount == 0) {
            return;
        }

        IERC20(tokenAddress).transferFrom(msg.sender, address(this), tokenAmount);
        balance[tokenAddress][msg.sender] += tokenAmount;

        if (postMigration) {
            require(balance[tokenAddress][msg.sender] + migrated[tokenAddress][msg.sender] <= allowableToMigrate[tokenAddress][msg.sender]);
            _airdropWalletTokens(tokenAddress, msg.sender);
        } else {
            if (!isAv1TokenHolder[tokenAddress][msg.sender]) {
                v1TokenHolders[tokenAddress].push(msg.sender);
                isAv1TokenHolder[tokenAddress][msg.sender] = true;
            }
        }
    }

    function _airdropWalletTokens(address tokenAddress, address v1TokenHolder) internal {
        uint256 migrateBalance = balance[tokenAddress][v1TokenHolder];
        balance[tokenAddress][v1TokenHolder] = 0;
        migrated[tokenAddress][v1TokenHolder] += migrateBalance;

        IERC20 token = IERC20(v2TokenLookup[tokenAddress]);

        uint256 numerator = newTokenReserves[address(token)] * oldETHReserves[tokenAddress];
        uint256 denominator = oldTokenReserves[tokenAddress] * newETHReserves[address(token)];

        uint256 airdropAmount = migrateBalance * numerator / denominator / 10**14 * 10**14;

        if (airdropAmount == 0) {
            return;
        }

        v2Received[address(token)][v1TokenHolder] += airdropAmount;

        token.transfer(v1TokenHolder, airdropAmount);
    }

    function _createPair(address tokenAddress, address otherTokenAddress) internal {
        address pairAddress = factory.getPair(tokenAddress, otherTokenAddress);
        if (pairAddress == address(0)) {
            pairAddress = factory.createPair(tokenAddress, otherTokenAddress);
        }
    }

    function _calculateNewETHReserves() internal {
        uint256 baseETHAmount;
        uint256 extraConstellationETH;
        uint256 totalOldETHReserves_ = totalOldETHReserves;

        // We are capping ETH liquidity increase to 2X for the existing pairs and 3X for the constellation
        if (address(this).balance > 2 * totalOldETHReserves_) {
            baseETHAmount = totalOldETHReserves_ * 2;
            if (address(this).balance - baseETHAmount > totalX7000ETHReserves) {
                extraConstellationETH = totalX7000ETHReserves;
            } else {
                extraConstellationETH = address(this).balance - baseETHAmount;
            }
        } else {
            baseETHAmount = address(this).balance;
        }

        newETHReserves[X7DAOv2] = baseETHAmount * oldETHReserves[X7DAOv1] / totalOldETHReserves_;
        newETHReserves[X7R] = baseETHAmount * (oldETHReserves[X7] + oldETHReserves[X7m105]) / totalOldETHReserves_;

        // The constellation will get a greater amount of liquidity, if available
        newETHReserves[X7101] = (baseETHAmount * oldETHReserves[X7001] / totalOldETHReserves_) + (extraConstellationETH * oldETHReserves[X7001] / totalX7000ETHReserves);
        newETHReserves[X7102] = (baseETHAmount * oldETHReserves[X7002] / totalOldETHReserves_) + (extraConstellationETH * oldETHReserves[X7002] / totalX7000ETHReserves);
        newETHReserves[X7103] = (baseETHAmount * oldETHReserves[X7003] / totalOldETHReserves_) + (extraConstellationETH * oldETHReserves[X7003] / totalX7000ETHReserves);
        newETHReserves[X7104] = (baseETHAmount * oldETHReserves[X7004] / totalOldETHReserves_) + (extraConstellationETH * oldETHReserves[X7004] / totalX7000ETHReserves);
        newETHReserves[X7105] = (baseETHAmount * oldETHReserves[X7005] / totalOldETHReserves_) + (extraConstellationETH * oldETHReserves[X7005] / totalX7000ETHReserves);
    }

    function _calculateNewLiquidity() internal {
        _calculateNewETHReserves();

        address newTokenAddress;
        address oldTokenAddress;

        newTokenAddress = X7DAOv2;
        oldTokenAddress = X7DAOv1;
        newTokenReserves[newTokenAddress] = _getNewDAOReserves(
            100000000 * 10**18,
            newETHReserves[newTokenAddress],
            oldETHReserves[oldTokenAddress],
            oldTokenReserves[oldTokenAddress]
        ) / 10**14 * 10**14;

        newTokenAddress = X7R;
        newTokenReserves[newTokenAddress] = _getNewX7RReserves(
            100000000 * 10**18,
            newETHReserves[newTokenAddress]
        ) / 10**14 * 10**14;

        newTokenAddress = X7101;
        oldTokenAddress = X7001;
        newTokenReserves[newTokenAddress] = _getNewConstellationReserves(
            100000000 * 10**18,
            newETHReserves[newTokenAddress],
            oldETHReserves[oldTokenAddress],
            oldTokenReserves[oldTokenAddress],
            oldConstellationNonCirculatingTokenSupply[oldTokenAddress]
        ) / 10**14 * 10**14;

        newTokenAddress = X7102;
        oldTokenAddress = X7002;
        newTokenReserves[newTokenAddress] = _getNewConstellationReserves(
            100000000 * 10**18,
            newETHReserves[newTokenAddress],
            oldETHReserves[oldTokenAddress],
            oldTokenReserves[oldTokenAddress],
            oldConstellationNonCirculatingTokenSupply[oldTokenAddress]
        ) / 10**14 * 10**14;

        newTokenAddress = X7103;
        oldTokenAddress = X7003;
        newTokenReserves[newTokenAddress] = _getNewConstellationReserves(
            100000000 * 10**18,
            newETHReserves[newTokenAddress],
            oldETHReserves[oldTokenAddress],
            oldTokenReserves[oldTokenAddress],
            oldConstellationNonCirculatingTokenSupply[oldTokenAddress]
        ) / 10**14 * 10**14;

        newTokenAddress = X7104;
        oldTokenAddress = X7004;
        newTokenReserves[newTokenAddress] = _getNewConstellationReserves(
            100000000 * 10**18,
            newETHReserves[newTokenAddress],
            oldETHReserves[oldTokenAddress],
            oldTokenReserves[oldTokenAddress],
            oldConstellationNonCirculatingTokenSupply[oldTokenAddress]
        ) / 10**14 * 10**14;

        newTokenAddress = X7105;
        oldTokenAddress = X7005;
        newTokenReserves[newTokenAddress] = _getNewConstellationReserves(
            100000000 * 10**18,
            newETHReserves[newTokenAddress],
            oldETHReserves[oldTokenAddress],
            oldTokenReserves[oldTokenAddress],
            oldConstellationNonCirculatingTokenSupply[oldTokenAddress]
        ) / 10**14 * 10**14;
    }

    // The math here is that the goal is to find the new reserves that allows for the total holder value to remain constant.
    //      Old Held tokens                   Old Price                   New Held Tokens                 New Price
    //  (supply - old token pair) * old eth pair / old token pair == (supply - new token pair) * new eth pair / new token pair
    //
    //  This math will allow us to increase the ETH and Token reserves (and therefore create a better liquidity ratio)
    //  while fully maintaining investor value. This math works no matter how much ETH is provided for liquidity from
    //  the harvested V1 liquidity and any other source.

    function _getNewDAOReserves(uint256 supply, uint256 newWETH, uint256 oldWETH, uint256 oldReserve) internal pure returns (uint256) {
        return supply * newWETH / (
        (
        // DAOv1 Holder mcap
        (supply - oldReserve) * oldWETH / oldReserve
        ) + newWETH
        );
    }

    function _getNewX7RReserves(uint256 newSupply, uint256 newWETH) internal view returns (uint256) {
        return (newSupply * newWETH) /
        (
        // X7m105 holder mcap
        ((oldSupply[X7m105] - oldTokenReserves[X7m105]) * oldETHReserves[X7m105] / oldTokenReserves[X7m105])
        // X7 holder mcap
        + ((oldSupply[X7] - oldTokenReserves[X7]) * oldETHReserves[X7] / oldTokenReserves[X7])
        + newWETH
        );
    }

    // We are transferring over 1x1 the "internal" token-token pairs.
    // Therefore we only need to account for the supply - oldReserve - "non circulating (the token-token pairs)"
    function _getNewConstellationReserves(uint256 supply, uint256 newWETH, uint256 oldWETH, uint256 oldReserve, uint256 nonCirculating) internal pure returns (uint256) {
        return (supply * newWETH - nonCirculating * newWETH) / (
        (
        // mcap of outstanding v1 tokens
        (supply - oldReserve - nonCirculating) * oldWETH / oldReserve
        ) + newWETH
        );
    }

    function _initiateX7100Launch() internal {
        _createTokenPair(X7101, X7102);
        _createTokenPair(X7101, X7103);
        _createTokenPair(X7101, X7104);
        _createTokenPair(X7101, X7105);
        _createTokenPair(X7102, X7103);
        _createTokenPair(X7102, X7104);
        _createTokenPair(X7102, X7105);
        _createTokenPair(X7103, X7104);
        _createTokenPair(X7103, X7105);
        _createTokenPair(X7104, X7105);

        _createETHPair(X7101, newTokenReserves[X7101], newETHReserves[X7101]);
        _createETHPair(X7102, newTokenReserves[X7102], newETHReserves[X7102]);
        _createETHPair(X7103, newTokenReserves[X7103], newETHReserves[X7103]);
        _createETHPair(X7104, newTokenReserves[X7104], newETHReserves[X7104]);
        _createETHPair(X7105, newTokenReserves[X7105], newETHReserves[X7105]);
    }

    function _createETHPair(address tokenAddress, uint256 tokenAmount, uint256 ethAmount) internal {
        IX7Token token = IX7Token(tokenAddress);

        address nativePairAddress = factory.getPair(tokenAddress, address(WETH));
        if (nativePairAddress == address(0)) {
            nativePairAddress = factory.createPair(tokenAddress, address(WETH));
        }

        addLiquidityETH(tokenAddress, tokenAmount, ethAmount);
        token.setOffRampPair(nativePairAddress);
    }

    function _createTokenPair(address tokenAddress, address otherTokenAddress) internal {
        address v1TokenAddress = oldConstellationTokenLookup[tokenAddress];
        address v1OtherTokenAddress = oldConstellationTokenLookup[otherTokenAddress];

        uint256 tokenAmount = oldConstellationNonCirculatingTokenReserve[v1OtherTokenAddress][v1TokenAddress];
        uint256 otherTokenAmount = oldConstellationNonCirculatingTokenReserve[v1TokenAddress][v1OtherTokenAddress];

        address pairAddress = factory.getPair(tokenAddress, otherTokenAddress);
        if (pairAddress == address(0)) {
            pairAddress = factory.createPair(tokenAddress, otherTokenAddress);
        }

        addLiquidity(tokenAddress, tokenAmount, otherTokenAddress, otherTokenAmount);
    }

    function _takePairSnapshot(address tokenAddress) internal {
        address pair = factory.getPair(address(WETH), tokenAddress);
        uint256 wethBalance;

        wethBalance = WETH.balanceOf(pair);
        oldETHReserves[tokenAddress] = wethBalance;
        totalOldETHReserves += wethBalance;

        if (isConstellation[tokenAddress]) {
            _snapshotConstellationPair(tokenAddress);
            totalX7000ETHReserves += wethBalance;
        } else {
            oldTokenReserves[tokenAddress] = IERC20(tokenAddress).balanceOf(pair);
        }
    }

    function _takeTokenHolderSnapshot(address tokenAddress) internal {
        IERC20 token = IERC20(tokenAddress);
        address holder;

        for (uint i=0; i < v1TokenHolders[tokenAddress].length; i++) {
            holder = v1TokenHolders[tokenAddress][i];
            allowableToMigrate[tokenAddress][holder] = token.balanceOf(holder) + balance[tokenAddress][holder];
        }
    }

    function _takeSnapshot(address tokenAddress) internal {
        if (tokenAddress == X7m105) {
            // We are only accounting for burned tokens in the case of X7m105, for simplicity.
            oldSupply[X7m105] = 100000000*10**18 - IERC20(X7m105).balanceOf(address(0xdead));
        } else if (tokenAddress == X7) {
            oldSupply[X7] = 100000000*10**18;
        }

        _takeTokenHolderSnapshot(tokenAddress);
        _takePairSnapshot(tokenAddress);
    }

    function _snapshotConstellationPair(address tokenAddress) internal {
        uint256 pairBalance;

        oldTokenReserves[tokenAddress] = IERC20(tokenAddress).balanceOf(factory.getPair(tokenAddress, address(WETH)));

        if (tokenAddress != X7001) {
            pairBalance = IX7Token(X7001).balanceOf(factory.getPair(tokenAddress, X7001));
            oldConstellationNonCirculatingTokenSupply[X7001] += pairBalance;
            oldConstellationNonCirculatingTokenReserve[tokenAddress][X7001] = pairBalance;
        }

        if (tokenAddress != X7002) {
            pairBalance = IX7Token(X7002).balanceOf(factory.getPair(tokenAddress, X7002));
            oldConstellationNonCirculatingTokenSupply[X7002] += pairBalance;
            oldConstellationNonCirculatingTokenReserve[tokenAddress][X7002] = pairBalance;
        }

        if (tokenAddress != X7003) {
            pairBalance = IX7Token(X7003).balanceOf(factory.getPair(tokenAddress, X7003));
            oldConstellationNonCirculatingTokenSupply[X7003] += pairBalance;
            oldConstellationNonCirculatingTokenReserve[tokenAddress][X7003] = pairBalance;
        }

        if (tokenAddress != X7004) {
            pairBalance = IX7Token(X7004).balanceOf(factory.getPair(tokenAddress, X7004));
            oldConstellationNonCirculatingTokenSupply[X7004] += pairBalance;
            oldConstellationNonCirculatingTokenReserve[tokenAddress][X7004] = pairBalance;
        }

        if (tokenAddress != X7005) {
            pairBalance = IX7Token(X7005).balanceOf(factory.getPair(tokenAddress, X7005));
            oldConstellationNonCirculatingTokenSupply[X7005] += pairBalance;
            oldConstellationNonCirculatingTokenReserve[tokenAddress][X7005] = pairBalance;
        }
    }

    function _harvestLiquidity(address tokenAddress) internal {
        IERC20 token = IERC20(tokenAddress);
        uint256 tokenBalance = token.balanceOf(address(this));
        if (tokenBalance > 0) {
            swapTokensForEth(tokenAddress, tokenBalance);
        }
    }

    function _addLiquidity(address v2TokenAddress) internal {
        IERC20(v2TokenAddress).approve(address(router), newTokenReserves[v2TokenAddress]);
        router.addLiquidityETH{value: newETHReserves[v2TokenAddress]}(
            v2TokenAddress,
            newTokenReserves[v2TokenAddress],
            0,
            0,
            X7TokenTimelock,
            block.timestamp
        );
    }

    function _resetOwnership(address contractAddress) internal {
        require(Ownable(contractAddress).owner() == address(this));
        Ownable(contractAddress).transferOwnership(owner());
    }

    function addLiquidityETH(address tokenAddress, uint256 tokenAmount, uint256 ethAmount) internal {
        IERC20(tokenAddress).approve(address(router), tokenAmount);
        router.addLiquidityETH{value: ethAmount}(
            tokenAddress,
            tokenAmount,
            0,
            0,
            X7TokenTimelock,
            block.timestamp
        );
    }

    function addLiquidity(address tokenAAddress, uint256 tokenAAmount, address tokenBAddress, uint256 tokenBAmount) internal {
        IERC20(tokenAAddress).approve(address(router), tokenAAmount);
        IERC20(tokenBAddress).approve(address(router), tokenBAmount);
        router.addLiquidity(
            tokenAAddress,
            tokenBAddress,
            tokenAAmount,
            tokenBAmount,
            0,
            0,
            X7TokenTimelock,
            block.timestamp
        );
    }

    function swapTokensForEth(address tokenAddress, uint256 tokenAmount) internal {
        if (tokenAmount == 0) {
            return;
        }

        address[] memory path = new address[](2);
        path[0] = tokenAddress;
        path[1] = address(WETH);

        IERC20(tokenAddress).approve(address(router), tokenAmount);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function _setupTokens() internal {
        _setupToken(X7DAOv2);
        _setupToken(X7R);
        _setupToken(X7101);
        _setupToken(X7102);
        _setupToken(X7103);
        _setupToken(X7104);
        _setupToken(X7105);
    }

    function _setupToken(address tokenAddress) internal {
        address pair;
        IX7Token token = IX7Token(tokenAddress);
        pair = factory.getPair(address(WETH), tokenAddress);

        if (tokenAddress == X7DAOv2) {
            X7DAOLiquidityHub.setOffRampPair(pair);
        } else if (tokenAddress == X7R) {
            X7RLiquidityHub.setOffRampPair(pair);
        } else {
            X7100LiquidityHub.setOffRampPair(tokenAddress, pair);
            X7100LiquidityHub.setConstellationToken(tokenAddress, true);
        }

        token.setAMM(pair, true);
        token.setOffRampPair(pair);
    }

    function _airdropMigrationTokens(address v1TokenAddress, address v2TokenAddress, uint256 startIndex, uint256 endIndex) internal {
        uint256 numerator = newTokenReserves[v2TokenAddress] * oldETHReserves[v1TokenAddress];
        uint256 denominator = oldTokenReserves[v1TokenAddress] * newETHReserves[v2TokenAddress];

        uint256 airdropAmount;
        uint256 migrationBalance;
        address holder;

        IERC20 v2Token = IERC20(v2TokenAddress);

        if (startIndex >= v1TokenHolders[v1TokenAddress].length) {
            return;
        }

        uint256 stopIndex;
        if (endIndex == 0) {
            stopIndex = v1TokenHolders[v1TokenAddress].length;
        } else if (v1TokenHolders[v1TokenAddress].length <= endIndex) {
            stopIndex = v1TokenHolders[v1TokenAddress].length;
        } else {
            stopIndex = endIndex;
        }

        require(startIndex < stopIndex);

        for (uint i=startIndex; i < stopIndex; i++) {
            holder = v1TokenHolders[v1TokenAddress][i];
            migrationBalance = balance[v1TokenAddress][holder];

            // A holder must have migrated >= 1000 tokens to be airdropped their tokens.
            // Their tokens may still be migrated manually
            if (migrationBalance < 1000 * 10**18) {
                continue;
            }

            airdropAmount = migrationBalance * numerator / denominator / 10**14 * 10**14;

            // If the airdrop amount becomes 0 due to rounding/truncation then I recommend
            // a holder register a formal complaint with a community authority to be
            // compensated for their finney. We do not however decrement their balance in
            // this case in the event they have eligible tokens that can be added.
            if (airdropAmount == 0) {
                continue;
            }

            balance[v1TokenAddress][holder] = 0;
            migrated[v1TokenAddress][holder] += migrationBalance;
            v2Received[v2TokenAddress][holder] += airdropAmount;
            v2Token.transfer(holder, airdropAmount);
        }
    }

}