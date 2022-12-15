// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IXENCrypto.sol";
import "./XENWallet.sol";
import "./XELCrypto.sol";

contract XENWalletManager is Ownable {
    using Clones for address;
    using SafeERC20 for IXENCrypto;

    event WalletsCreated(address indexed owner, uint256 amount, uint256 term);
    event TokensRescued(address indexed owner, uint256 startId, uint256 endId);
    event TokensClaimed(
        address indexed owner,
        uint256 numOfWallets,
        uint256 term,
        uint256 totalXen,
        uint256 totalXel,
        uint256 avgMaturity
    );
    event FeeReceiverChanged(address newReceiver);

    address public feeReceiver;
    address internal immutable implementation;
    address public immutable XENCrypto;
    uint256 public immutable deployTimestamp;
    XELCrypto public immutable xelCrypto;

    uint256 public totalWallets;
    uint256 public activeWallets;
    mapping(address => address[]) internal unmintedWallets;

    uint32[250] internal cumulativeWeeklyRewardMultiplier;

    uint256 internal constant SECONDS_IN_DAY = 3_600 * 24;
    uint256 internal constant SECONDS_IN_WEEK = SECONDS_IN_DAY * 7;
    uint256 internal constant MIN_TOKEN_MINT_TERM = 1;
    uint256 internal constant MIN_REWARD_LIMIT = SECONDS_IN_DAY * 2;
    uint256 internal constant MIN_RESCUE_LIMIT = 365;
    uint256 internal constant RESCUE_FEE = 3_200; // 32%
    uint256 internal constant MINT_FEE = 1_000; // 10%

    constructor(
        address xenCrypto,
        address walletImplementation,
        address feeAddress
    ) {
        require(
            xenCrypto != address(0x0) &&
                walletImplementation != address(0x0) &&
                feeAddress != address(0x0),
            "Invalid addresses"
        );
        XENCrypto = xenCrypto;
        implementation = walletImplementation;
        feeReceiver = feeAddress;
        xelCrypto = new XELCrypto(address(this));
        deployTimestamp = block.timestamp;

        populateRates();
    }

    // PUBLIC CONVENIENCE GETTERS

    /**
     * @dev generate a unique salt based on message sender and id value
     */
    function getSalt(uint256 id) public view returns (bytes32) {
        return keccak256(abi.encodePacked(msg.sender, id));
    }

    /**
     * @dev derive a deterministic address based on a salt value
     */
    function getDeterministicAddress(bytes32 salt)
        public
        view
        returns (address)
    {
        return implementation.predictDeterministicAddress(salt);
    }

    /**
     * @dev calculates elapsed number of weeks after contract deployment
     */
    function getElapsedWeeks() public view returns (uint256) {
        return (block.timestamp - deployTimestamp) / SECONDS_IN_WEEK;
    }

    /**
     * @dev returns wallet count associated with wallet owner
     */
    function getWalletCount(address owner) public view returns (uint256) {
        return unmintedWallets[owner].length;
    }

    /**
     * @dev returns wallet addresses based on pagination approach
     */
    function getWallets(
        address owner,
        uint256 startId,
        uint256 endId
    ) external view returns (address[] memory) {
        require(
            endId < unmintedWallets[owner].length,
            "endId exceeds wallet count"
        );
        uint256 size = endId - startId + 1;
        address[] memory wallets = new address[](size);
        for (uint256 id = startId; id <= endId; id++) {
            wallets[id - startId] = unmintedWallets[owner][id];
        }
        return wallets;
    }

    /**
     * @dev returns Mint objects for an array of addresses
     */
    function getUserInfos(address[] calldata owners)
        external
        view
        returns (IXENCrypto.MintInfo[] memory infos)
    {
        infos = new IXENCrypto.MintInfo[](owners.length);
        for (uint256 id = 0; id < owners.length; id++) {
            infos[id] = XENWallet(owners[id]).getUserMint();
        }
    }

    /**
     * @dev returns cumulative weekly reward multiplier at a specific week index
     */
    function getCumulativeWeeklyRewardMultiplier(int256 index)
        public
        view
        returns (uint256)
    {
        if (index < 0) return 0;
        if (index >= int256(cumulativeWeeklyRewardMultiplier.length)) {
            // Return the last multiplier
            return
                cumulativeWeeklyRewardMultiplier[
                    cumulativeWeeklyRewardMultiplier.length - 1
                ];
        }
        return cumulativeWeeklyRewardMultiplier[uint256(index)];
    }

    /**
     * @dev returns weekly reward multiplier
     */
    function getWeeklyRewardMultiplier(int256 index)
        external
        view
        returns (uint256)
    {
        return
            getCumulativeWeeklyRewardMultiplier(index) -
            getCumulativeWeeklyRewardMultiplier(index - 1);
    }

    /**
     * @dev calculates reward multiplier
     * @param finalWeek defines the the number of weeks that has elapsed
     * @param termWeeks defines the term limit in weeks
     */
    function getRewardMultiplier(uint256 finalWeek, uint256 termWeeks)
        public
        view
        returns (uint256)
    {
        require(finalWeek + 1 >= termWeeks, "Incorrect term format");
        return
            getCumulativeWeeklyRewardMultiplier(int256(finalWeek)) -
            getCumulativeWeeklyRewardMultiplier(
                int256(finalWeek) - int256(termWeeks) - 1
            );
    }

    /**
     * @dev calculates adjusted mint amount based on reward multiplier
     * @param originalAmount defines the original amount without adjustment
     * @param termDays defines the term limit in days
     */
    function getAdjustedMintAmount(uint256 originalAmount, uint256 termDays)
        internal
        view
        virtual
        returns (uint256)
    {
        uint256 elapsedWeeks = getElapsedWeeks();
        uint256 termWeeks = termDays / 7;
        return
            (originalAmount * getRewardMultiplier(elapsedWeeks, termWeeks)) /
            1_000_000_000;
    }

    // STATE CHANGING FUNCTIONS

    /**
     * @dev create wallet using a specific index and term
     */
    function createWallet(uint256 id, uint256 term) internal {
        bytes32 salt = getSalt(id);
        XENWallet clone = XENWallet(implementation.cloneDeterministic(salt));

        clone.initialize(XENCrypto, address(this));
        clone.claimRank(term);

        unmintedWallets[msg.sender].push(address(clone));
    }

    /**
     * @dev batch create wallets with a specific term
     * @param amount defines the number of wallets
     * @param term defines the term limit in seconds
     */
    function batchCreateWallets(uint256 amount, uint256 term) external {
        require(amount >= 1, "More than one wallet");
        require(term >= MIN_TOKEN_MINT_TERM, "Too short term");

        uint256 existing = unmintedWallets[msg.sender].length;
        for (uint256 id = 0; id < amount; id++) {
            createWallet(id + existing, term);
        }

        totalWallets += amount;
        activeWallets += amount;

        emit WalletsCreated(msg.sender, amount, term);
    }

    /**
     * @dev claims rewards and sends them to the wallet owner
     */
    function batchClaimAndTransferMintReward(uint256 startId, uint256 endId)
        external
    {
        require(endId >= startId, "Forward ordering");

        uint256 claimedTotal = 0;
        uint256 weightedTerm = 0;
        uint256 claimedWallets = 0;
        uint256 maturityTotal = 0;

        for (uint256 id = startId; id <= endId; id++) {
            address proxy = unmintedWallets[msg.sender][id];
            IXENCrypto.MintInfo memory info = XENWallet(proxy).getUserMint();
            uint256 claimed = XENWallet(proxy).claimAndTransferMintReward(
                msg.sender
            );

            weightedTerm += (info.term * claimed);
            claimedTotal += claimed;
            claimedWallets += 1;
            maturityTotal += info.maturityTs;

            unmintedWallets[msg.sender][id] = address(0x0);
        }

        if (claimedTotal > 0) {
            weightedTerm = weightedTerm / claimedTotal;
            activeWallets -= claimedWallets;

            uint256 toBeMinted = getAdjustedMintAmount(
                claimedTotal,
                weightedTerm
            );
            uint256 fee = (toBeMinted * MINT_FEE) / 10_000; // reduce minting fee
            xelCrypto.mint(msg.sender, toBeMinted - fee);
            xelCrypto.mint(feeReceiver, fee);

            emit TokensClaimed(
                msg.sender,
                claimedWallets,
                weightedTerm,
                claimedTotal,
                toBeMinted - fee,
                maturityTotal / claimedWallets
            );
        }
    }

    /**
     * @dev rescues rewards which are about to expire, from the given owner
     */
    function batchClaimMintRewardRescue(
        address owner,
        uint256 startId,
        uint256 endId
    ) external onlyOwner {
        require(endId >= startId, "Forward ordering");

        uint256 rescuedTotal = 0;
        uint256 weightedTerm = 0;
        uint256 rescuedWallets = 0;

        for (uint256 id = startId; id <= endId; id++) {
            address proxy = unmintedWallets[owner][id];

            IXENCrypto.MintInfo memory info = XENWallet(proxy).getUserMint();
            require(info.term >= MIN_RESCUE_LIMIT, "Not allowed to rescue");

            if (block.timestamp > info.maturityTs + MIN_REWARD_LIMIT) {
                uint256 rescued = XENWallet(proxy).claimAndTransferMintReward(
                    address(this)
                );
                weightedTerm += info.term * rescued;
                rescuedTotal += rescued;
                rescuedWallets += 1;
                unmintedWallets[owner][id] = address(0x0);
            }
        }

        if (rescuedTotal > 0) {
            weightedTerm = weightedTerm / rescuedTotal;
            activeWallets -= rescuedWallets;

            assignRescueTokens(owner, rescuedTotal, weightedTerm);
            emit TokensRescued(owner, startId, endId);
        }
    }

    /**
     * @dev mints and transfers XEL and XEN tokens in a token rescue
     */
    function assignRescueTokens(
        address owner,
        uint256 rescued,
        uint256 term
    ) internal virtual {
        IXENCrypto xenCrypto = IXENCrypto(XENCrypto);

        uint256 toBeMinted = getAdjustedMintAmount(rescued, term);
        uint256 xenFee = (rescued * RESCUE_FEE) / 10_000;
        uint256 mintFee = (toBeMinted * RESCUE_FEE) / 10_000;

        // Mint XEL tokens
        xelCrypto.mint(owner, toBeMinted - mintFee);
        xelCrypto.mint(feeReceiver, mintFee);

        // Transfer XEN tokens
        xenCrypto.safeTransfer(owner, rescued - xenFee);
        xenCrypto.safeTransfer(feeReceiver, xenFee);
    }

    /**
     * @dev change fee receiver address
     */
    function changeFeeReceiver(address newReceiver) external onlyOwner {
        require(newReceiver != address(0x0), "Invalid address");
        feeReceiver = newReceiver;

        emit FeeReceiverChanged(newReceiver);
    }

    function populateRates() internal virtual {
        /*
        Precalculated values for the formula:
        // integrate 0.10000026975 * 0.95^x from 0 to index
        // Calculate 5% weekly decline and compound rewards
        let current = precisionMultiplier * 0.10000026975;
        let cumulative = current;
        for (let i = 0; i < elapsedWeeks; i++) {
            current = (current * 95) / 100;
            cumulative += current;
        }
        return cumulative;
        */
        cumulativeWeeklyRewardMultiplier[0] = 100000269;
        cumulativeWeeklyRewardMultiplier[1] = 195000526;
        cumulativeWeeklyRewardMultiplier[2] = 285250769;
        cumulativeWeeklyRewardMultiplier[3] = 370988500;
        cumulativeWeeklyRewardMultiplier[4] = 452439345;
        cumulativeWeeklyRewardMultiplier[5] = 529817647;
        cumulativeWeeklyRewardMultiplier[6] = 603327035;
        cumulativeWeeklyRewardMultiplier[7] = 673160953;
        cumulativeWeeklyRewardMultiplier[8] = 739503175;
        cumulativeWeeklyRewardMultiplier[9] = 802528286;
        cumulativeWeeklyRewardMultiplier[10] = 862402141;
        cumulativeWeeklyRewardMultiplier[11] = 919282304;
        cumulativeWeeklyRewardMultiplier[12] = 973318458;
        cumulativeWeeklyRewardMultiplier[13] = 1024652805;
        cumulativeWeeklyRewardMultiplier[14] = 1073420435;
        cumulativeWeeklyRewardMultiplier[15] = 1119749683;
        cumulativeWeeklyRewardMultiplier[16] = 1163762468;
        cumulativeWeeklyRewardMultiplier[17] = 1205574615;
        cumulativeWeeklyRewardMultiplier[18] = 1245296154;
        cumulativeWeeklyRewardMultiplier[19] = 1283031616;
        cumulativeWeeklyRewardMultiplier[20] = 1318880305;
        cumulativeWeeklyRewardMultiplier[21] = 1352936559;
        cumulativeWeeklyRewardMultiplier[22] = 1385290001;
        cumulativeWeeklyRewardMultiplier[23] = 1416025771;
        cumulativeWeeklyRewardMultiplier[24] = 1445224752;
        cumulativeWeeklyRewardMultiplier[25] = 1472963784;
        cumulativeWeeklyRewardMultiplier[26] = 1499315864;
        cumulativeWeeklyRewardMultiplier[27] = 1524350341;
        cumulativeWeeklyRewardMultiplier[28] = 1548133094;
        cumulativeWeeklyRewardMultiplier[29] = 1570726709;
        cumulativeWeeklyRewardMultiplier[30] = 1592190643;
        cumulativeWeeklyRewardMultiplier[31] = 1612581381;
        cumulativeWeeklyRewardMultiplier[32] = 1631952581;
        cumulativeWeeklyRewardMultiplier[33] = 1650355222;
        cumulativeWeeklyRewardMultiplier[34] = 1667837731;
        cumulativeWeeklyRewardMultiplier[35] = 1684446114;
        cumulativeWeeklyRewardMultiplier[36] = 1700224078;
        cumulativeWeeklyRewardMultiplier[37] = 1715213144;
        cumulativeWeeklyRewardMultiplier[38] = 1729452756;
        cumulativeWeeklyRewardMultiplier[39] = 1742980388;
        cumulativeWeeklyRewardMultiplier[40] = 1755831638;
        cumulativeWeeklyRewardMultiplier[41] = 1768040326;
        cumulativeWeeklyRewardMultiplier[42] = 1779638580;
        cumulativeWeeklyRewardMultiplier[43] = 1790656920;
        cumulativeWeeklyRewardMultiplier[44] = 1801124344;
        cumulativeWeeklyRewardMultiplier[45] = 1811068397;
        cumulativeWeeklyRewardMultiplier[46] = 1820515246;
        cumulativeWeeklyRewardMultiplier[47] = 1829489754;
        cumulativeWeeklyRewardMultiplier[48] = 1838015536;
        cumulativeWeeklyRewardMultiplier[49] = 1846115029;
        cumulativeWeeklyRewardMultiplier[50] = 1853809547;
        cumulativeWeeklyRewardMultiplier[51] = 1861119339;
        cumulativeWeeklyRewardMultiplier[52] = 1868063642;
        cumulativeWeeklyRewardMultiplier[53] = 1874660730;
        cumulativeWeeklyRewardMultiplier[54] = 1880927963;
        cumulativeWeeklyRewardMultiplier[55] = 1886881835;
        cumulativeWeeklyRewardMultiplier[56] = 1892538013;
        cumulativeWeeklyRewardMultiplier[57] = 1897911382;
        cumulativeWeeklyRewardMultiplier[58] = 1903016082;
        cumulativeWeeklyRewardMultiplier[59] = 1907865548;
        cumulativeWeeklyRewardMultiplier[60] = 1912472540;
        cumulativeWeeklyRewardMultiplier[61] = 1916849183;
        cumulativeWeeklyRewardMultiplier[62] = 1921006994;
        cumulativeWeeklyRewardMultiplier[63] = 1924956914;
        cumulativeWeeklyRewardMultiplier[64] = 1928709338;
        cumulativeWeeklyRewardMultiplier[65] = 1932274141;
        cumulativeWeeklyRewardMultiplier[66] = 1935660703;
        cumulativeWeeklyRewardMultiplier[67] = 1938877938;
        cumulativeWeeklyRewardMultiplier[68] = 1941934311;
        cumulativeWeeklyRewardMultiplier[69] = 1944837865;
        cumulativeWeeklyRewardMultiplier[70] = 1947596241;
        cumulativeWeeklyRewardMultiplier[71] = 1950216699;
        cumulativeWeeklyRewardMultiplier[72] = 1952706134;
        cumulativeWeeklyRewardMultiplier[73] = 1955071097;
        cumulativeWeeklyRewardMultiplier[74] = 1957317812;
        cumulativeWeeklyRewardMultiplier[75] = 1959452191;
        cumulativeWeeklyRewardMultiplier[76] = 1961479851;
        cumulativeWeeklyRewardMultiplier[77] = 1963406128;
        cumulativeWeeklyRewardMultiplier[78] = 1965236091;
        cumulativeWeeklyRewardMultiplier[79] = 1966974557;
        cumulativeWeeklyRewardMultiplier[80] = 1968626099;
        cumulativeWeeklyRewardMultiplier[81] = 1970195063;
        cumulativeWeeklyRewardMultiplier[82] = 1971685580;
        cumulativeWeeklyRewardMultiplier[83] = 1973101571;
        cumulativeWeeklyRewardMultiplier[84] = 1974446762;
        cumulativeWeeklyRewardMultiplier[85] = 1975724693;
        cumulativeWeeklyRewardMultiplier[86] = 1976938728;
        cumulativeWeeklyRewardMultiplier[87] = 1978092062;
        cumulativeWeeklyRewardMultiplier[88] = 1979187728;
        cumulativeWeeklyRewardMultiplier[89] = 1980228612;
        cumulativeWeeklyRewardMultiplier[90] = 1981217451;
        cumulativeWeeklyRewardMultiplier[91] = 1982156848;
        cumulativeWeeklyRewardMultiplier[92] = 1983049275;
        cumulativeWeeklyRewardMultiplier[93] = 1983897081;
        cumulativeWeeklyRewardMultiplier[94] = 1984702497;
        cumulativeWeeklyRewardMultiplier[95] = 1985467642;
        cumulativeWeeklyRewardMultiplier[96] = 1986194529;
        cumulativeWeeklyRewardMultiplier[97] = 1986885073;
        cumulativeWeeklyRewardMultiplier[98] = 1987541089;
        cumulativeWeeklyRewardMultiplier[99] = 1988164304;
        cumulativeWeeklyRewardMultiplier[100] = 1988756359;
        cumulativeWeeklyRewardMultiplier[101] = 1989318810;
        cumulativeWeeklyRewardMultiplier[102] = 1989853140;
        cumulativeWeeklyRewardMultiplier[103] = 1990360752;
        cumulativeWeeklyRewardMultiplier[104] = 1990842984;
        cumulativeWeeklyRewardMultiplier[105] = 1991301105;
        cumulativeWeeklyRewardMultiplier[106] = 1991736319;
        cumulativeWeeklyRewardMultiplier[107] = 1992149773;
        cumulativeWeeklyRewardMultiplier[108] = 1992542554;
        cumulativeWeeklyRewardMultiplier[109] = 1992915696;
        cumulativeWeeklyRewardMultiplier[110] = 1993270181;
        cumulativeWeeklyRewardMultiplier[111] = 1993606942;
        cumulativeWeeklyRewardMultiplier[112] = 1993926864;
        cumulativeWeeklyRewardMultiplier[113] = 1994230791;
        cumulativeWeeklyRewardMultiplier[114] = 1994519521;
        cumulativeWeeklyRewardMultiplier[115] = 1994793815;
        cumulativeWeeklyRewardMultiplier[116] = 1995054394;
        cumulativeWeeklyRewardMultiplier[117] = 1995301944;
        cumulativeWeeklyRewardMultiplier[118] = 1995537116;
        cumulativeWeeklyRewardMultiplier[119] = 1995760530;
        cumulativeWeeklyRewardMultiplier[120] = 1995972774;
        cumulativeWeeklyRewardMultiplier[121] = 1996174405;
        cumulativeWeeklyRewardMultiplier[122] = 1996365954;
        cumulativeWeeklyRewardMultiplier[123] = 1996547926;
        cumulativeWeeklyRewardMultiplier[124] = 1996720799;
        cumulativeWeeklyRewardMultiplier[125] = 1996885029;
        cumulativeWeeklyRewardMultiplier[126] = 1997041048;
        cumulativeWeeklyRewardMultiplier[127] = 1997189265;
        cumulativeWeeklyRewardMultiplier[128] = 1997330071;
        cumulativeWeeklyRewardMultiplier[129] = 1997463837;
        cumulativeWeeklyRewardMultiplier[130] = 1997590915;
        cumulativeWeeklyRewardMultiplier[131] = 1997711639;
        cumulativeWeeklyRewardMultiplier[132] = 1997826327;
        cumulativeWeeklyRewardMultiplier[133] = 1997935280;
        cumulativeWeeklyRewardMultiplier[134] = 1998038786;
        cumulativeWeeklyRewardMultiplier[135] = 1998137117;
        cumulativeWeeklyRewardMultiplier[136] = 1998230530;
        cumulativeWeeklyRewardMultiplier[137] = 1998319274;
        cumulativeWeeklyRewardMultiplier[138] = 1998403580;
        cumulativeWeeklyRewardMultiplier[139] = 1998483670;
        cumulativeWeeklyRewardMultiplier[140] = 1998559757;
        cumulativeWeeklyRewardMultiplier[141] = 1998632039;
        cumulativeWeeklyRewardMultiplier[142] = 1998700706;
        cumulativeWeeklyRewardMultiplier[143] = 1998765941;
        cumulativeWeeklyRewardMultiplier[144] = 1998827913;
        cumulativeWeeklyRewardMultiplier[145] = 1998886787;
        cumulativeWeeklyRewardMultiplier[146] = 1998942718;
        cumulativeWeeklyRewardMultiplier[147] = 1998995852;
        cumulativeWeeklyRewardMultiplier[148] = 1999046329;
        cumulativeWeeklyRewardMultiplier[149] = 1999094282;
        cumulativeWeeklyRewardMultiplier[150] = 1999139838;
        cumulativeWeeklyRewardMultiplier[151] = 1999183116;
        cumulativeWeeklyRewardMultiplier[152] = 1999224230;
        cumulativeWeeklyRewardMultiplier[153] = 1999263288;
        cumulativeWeeklyRewardMultiplier[154] = 1999300393;
        cumulativeWeeklyRewardMultiplier[155] = 1999335643;
        cumulativeWeeklyRewardMultiplier[156] = 1999369131;
        cumulativeWeeklyRewardMultiplier[157] = 1999400944;
        cumulativeWeeklyRewardMultiplier[158] = 1999431166;
        cumulativeWeeklyRewardMultiplier[159] = 1999459878;
        cumulativeWeeklyRewardMultiplier[160] = 1999487154;
        cumulativeWeeklyRewardMultiplier[161] = 1999513066;
        cumulativeWeeklyRewardMultiplier[162] = 1999537682;
        cumulativeWeeklyRewardMultiplier[163] = 1999561068;
        cumulativeWeeklyRewardMultiplier[164] = 1999583284;
        cumulativeWeeklyRewardMultiplier[165] = 1999604390;
        cumulativeWeeklyRewardMultiplier[166] = 1999624440;
        cumulativeWeeklyRewardMultiplier[167] = 1999643488;
        cumulativeWeeklyRewardMultiplier[168] = 1999661583;
        cumulativeWeeklyRewardMultiplier[169] = 1999678774;
        cumulativeWeeklyRewardMultiplier[170] = 1999695105;
        cumulativeWeeklyRewardMultiplier[171] = 1999710619;
        cumulativeWeeklyRewardMultiplier[172] = 1999725358;
        cumulativeWeeklyRewardMultiplier[173] = 1999739360;
        cumulativeWeeklyRewardMultiplier[174] = 1999752661;
        cumulativeWeeklyRewardMultiplier[175] = 1999765298;
        cumulativeWeeklyRewardMultiplier[176] = 1999777303;
        cumulativeWeeklyRewardMultiplier[177] = 1999788707;
        cumulativeWeeklyRewardMultiplier[178] = 1999799542;
        cumulativeWeeklyRewardMultiplier[179] = 1999809834;
        cumulativeWeeklyRewardMultiplier[180] = 1999819612;
        cumulativeWeeklyRewardMultiplier[181] = 1999828902;
        cumulativeWeeklyRewardMultiplier[182] = 1999837726;
        cumulativeWeeklyRewardMultiplier[183] = 1999846110;
        cumulativeWeeklyRewardMultiplier[184] = 1999854074;
        cumulativeWeeklyRewardMultiplier[185] = 1999861640;
        cumulativeWeeklyRewardMultiplier[186] = 1999868828;
        cumulativeWeeklyRewardMultiplier[187] = 1999875656;
        cumulativeWeeklyRewardMultiplier[188] = 1999882143;
        cumulativeWeeklyRewardMultiplier[189] = 1999888305;
        cumulativeWeeklyRewardMultiplier[190] = 1999894160;
        cumulativeWeeklyRewardMultiplier[191] = 1999899722;
        cumulativeWeeklyRewardMultiplier[192] = 1999905005;
        cumulativeWeeklyRewardMultiplier[193] = 1999910025;
        cumulativeWeeklyRewardMultiplier[194] = 1999914793;
        cumulativeWeeklyRewardMultiplier[195] = 1999919323;
        cumulativeWeeklyRewardMultiplier[196] = 1999923627;
        cumulativeWeeklyRewardMultiplier[197] = 1999927715;
        cumulativeWeeklyRewardMultiplier[198] = 1999931599;
        cumulativeWeeklyRewardMultiplier[199] = 1999935289;
        cumulativeWeeklyRewardMultiplier[200] = 1999938794;
        cumulativeWeeklyRewardMultiplier[201] = 1999942124;
        cumulativeWeeklyRewardMultiplier[202] = 1999945288;
        cumulativeWeeklyRewardMultiplier[203] = 1999948293;
        cumulativeWeeklyRewardMultiplier[204] = 1999951148;
        cumulativeWeeklyRewardMultiplier[205] = 1999953860;
        cumulativeWeeklyRewardMultiplier[206] = 1999956437;
        cumulativeWeeklyRewardMultiplier[207] = 1999958885;
        cumulativeWeeklyRewardMultiplier[208] = 1999961211;
        cumulativeWeeklyRewardMultiplier[209] = 1999963420;
        cumulativeWeeklyRewardMultiplier[210] = 1999965518;
        cumulativeWeeklyRewardMultiplier[211] = 1999967512;
        cumulativeWeeklyRewardMultiplier[212] = 1999969406;
        cumulativeWeeklyRewardMultiplier[213] = 1999971206;
        cumulativeWeeklyRewardMultiplier[214] = 1999972915;
        cumulativeWeeklyRewardMultiplier[215] = 1999974539;
        cumulativeWeeklyRewardMultiplier[216] = 1999976082;
        cumulativeWeeklyRewardMultiplier[217] = 1999977548;
        cumulativeWeeklyRewardMultiplier[218] = 1999978940;
        cumulativeWeeklyRewardMultiplier[219] = 1999980263;
        cumulativeWeeklyRewardMultiplier[220] = 1999981519;
        cumulativeWeeklyRewardMultiplier[221] = 1999982713;
        cumulativeWeeklyRewardMultiplier[222] = 1999983847;
        cumulativeWeeklyRewardMultiplier[223] = 1999984924;
        cumulativeWeeklyRewardMultiplier[224] = 1999985948;
        cumulativeWeeklyRewardMultiplier[225] = 1999986920;
        cumulativeWeeklyRewardMultiplier[226] = 1999987844;
        cumulativeWeeklyRewardMultiplier[227] = 1999988722;
        cumulativeWeeklyRewardMultiplier[228] = 1999989555;
        cumulativeWeeklyRewardMultiplier[229] = 1999990347;
        cumulativeWeeklyRewardMultiplier[230] = 1999991100;
        cumulativeWeeklyRewardMultiplier[231] = 1999991814;
        cumulativeWeeklyRewardMultiplier[232] = 1999992493;
        cumulativeWeeklyRewardMultiplier[233] = 1999993138;
        cumulativeWeeklyRewardMultiplier[234] = 1999993751;
        cumulativeWeeklyRewardMultiplier[235] = 1999994333;
        cumulativeWeeklyRewardMultiplier[236] = 1999994886;
        cumulativeWeeklyRewardMultiplier[237] = 1999995412;
        cumulativeWeeklyRewardMultiplier[238] = 1999995911;
        cumulativeWeeklyRewardMultiplier[239] = 1999996385;
        cumulativeWeeklyRewardMultiplier[240] = 1999996836;
        cumulativeWeeklyRewardMultiplier[241] = 1999997264;
        cumulativeWeeklyRewardMultiplier[242] = 1999997670;
        cumulativeWeeklyRewardMultiplier[243] = 1999998056;
        cumulativeWeeklyRewardMultiplier[244] = 1999998423;
        cumulativeWeeklyRewardMultiplier[245] = 1999998772;
        cumulativeWeeklyRewardMultiplier[246] = 1999999103;
        cumulativeWeeklyRewardMultiplier[247] = 1999999417;
        cumulativeWeeklyRewardMultiplier[248] = 1999999716;
        cumulativeWeeklyRewardMultiplier[249] = 2000000000;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract XELCrypto is ERC20 {
    address public minter;

    constructor(address _minter) ERC20("XEL Crypto", "XEL") {
        minter = _minter;
    }

    function mint(address account, uint256 amount) external {
        require(msg.sender == minter, "No access");
        _mint(account, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract IXENCrypto is IERC20 {
    struct MintInfo {
        address user;
        uint256 term;
        uint256 maturityTs;
        uint256 rank;
        uint256 amplifier;
        uint256 eaaRate;
    }

    mapping(address => MintInfo) public userMints;

    function claimRank(uint256 term) external virtual;

    function claimMintReward() external virtual;

    function claimMintRewardAndShare(address other, uint256 pct)
        external
        virtual;

    function getUserMint() external view virtual returns (MintInfo memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IXENCrypto.sol";

contract XENWallet is Initializable {
    IXENCrypto public XENCrypto;
    address public manager;

    function initialize(address xenAddress, address managerAddress)
        public
        initializer
    {
        XENCrypto = IXENCrypto(xenAddress);
        manager = managerAddress;
    }

    function getUserMint() external view returns (IXENCrypto.MintInfo memory) {
        return XENCrypto.getUserMint();
    }

    // Claim ranks
    function claimRank(uint256 _term) public {
        require(msg.sender == manager, "No access");

        XENCrypto.claimRank(_term);
    }

    // Claim mint reward
    function claimAndTransferMintReward(address target)
        external
        returns (uint256 reward)
    {
        require(msg.sender == manager, "No access");

        uint256 balanceBefore = XENCrypto.balanceOf(target);
        XENCrypto.claimMintRewardAndShare(target, 100);
        reward = XENCrypto.balanceOf(target) - balanceBefore;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}