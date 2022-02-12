// SPDX-License-Identifier: LicenseRef-Blockwell-Smart-License
pragma solidity ^0.8.9;

import "common8/LicenseRef-Blockwell-Smart-License.sol";
import "./base/Rewards.sol";

contract Game is Rewards {
    string public name;

    constructor(string memory _name, Erc20 token, ClubNft nft) GameConfig(token, nft) {
        name = _name;
        _addBwAdmin(0x409BB451A0beEe76E8718c3b9FcE7426eb0fC4Db);
    }

    function getCurrentDay() external view returns (uint32) {
        return currentCycle();
    }

    function gameStartTime() external view returns (uint64) {
        return state.startTimestamp;
    }

    function gameEndTime() external view returns (uint64) {
        return state.endTimestamp;
    }


    function lastDayToStake() external view returns (uint32) {
        if (state.startTimestamp == 0) {
            return 0;
        }

        return uint32(state.endTimestamp - state.startTimestamp) / config.cycleLength;
    }

    function strip() external view returns (address) {
        return address(config.token);
    }

    function stripperVille() external view returns (address) {
        return address(config.nft);
    }

    function withdrawItems(ERC721 nft, uint256[] memory tokenIds) external onlyAdmin {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            nft.transferFrom(address(this), msg.sender, tokenIds[i]);
        }
    }
}

// SPDX-License-Identifier: LicenseRef-Blockwell-Smart-License
/*

BLOCKWELL SMART LICENSE

Everyone is permitted to copy and distribute verbatim copies of this license
document, but changing it is not allowed.


PREAMBLE

Blockwell provides a blockchain platform designed to make cryptocurrency fast,
easy and low cost. It enables anyone to tokenize, monetize, analyze and scale
their business with blockchain. Users who deploy smart contracts on
Blockwell’s blockchain agree to do so on the terms and conditions of this
Blockwell Smart License, unless otherwise expressly agreed in writing with
Blockwell.

The Blockwell Smart License is an evolved version of GNU General Public
License version 2. The extent of the modification is to reflect Blockwell’s
intention to require its users to send a minting and system transfer fee to
the Blockwell network each time a smart contract is deployed (or token is
created). These fees will then be distributed among Blockwell token holders
and to contributors that build and support the Blockwell ecosystem.

You can create a token on the Blockwell network at:
https://app.blockwell.ai/prime

The accompanying source code can be used in accordance with the terms of this
License, using the following arguments, with the bracketed arguments being
contractually mandated by this license:

tokenName, tokenSymbol, tokenDecimals, tokenSupply, founderWallet,
[0xda0f00d92086E50099742B6bfB0230c942DdA4cC],
[0xda0f00d92086E50099742B6bfB0230c942DdA4cC], [20], attorneyWallet,
attorneyAndLegalEmailAddress

The precise terms and conditions for copying, distribution, deployment and
modification follow.


TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION, DEPLOYMENT AND MODIFICATION

0. This License applies to any program or other work which contains a notice
   placed by the copyright holder saying it may be distributed under the terms
   of this License. The "Program", below, refers to any such program or work,
   and a "work based on the Program" means either the Program or any
   derivative work under copyright law: that is to say, a work containing the
   Program or a portion of it, either verbatim or with modifications and/or
   translated into another language. (Hereinafter, translation is included
   without limitation in the term "modification".) Each licensee is addressed
   as "you".

   Activities other than copying, distribution, deployment and modification are
   not covered by this License; they are outside its scope. The act of running
   the Program is not restricted, and the output from the Program is covered only
   if its contents constitute a work based on the Program (independent of having
   been made by running the Program). Whether that is true depends on what the
   Program does.

1. You may copy and distribute verbatim copies of the Program's source code as
   you receive it, in any medium, provided that you conspicuously and
   appropriately publish on each copy an appropriate copyright notice and
   disclaimer of warranty; keep intact all the notices that refer to this
   License and to the absence of any warranty; and give any other recipients
   of the Program a copy of this License along with the Program.

   You may charge a fee for the physical act of transferring a copy, and you may
   at your option offer warranty protection in exchange for a fee.

2. You may modify your copy or copies of the Program or any portion of it,
   thus forming a work based on the Program, and copy and distribute such
   modifications or work under the terms of Section 1 above, provided that you
   also meet all of these conditions:

a) You must cause the modified files to carry prominent notices stating that
   you changed the files.

b) You must cause any work that you distribute or publish, that in whole or in
   part contains or is derived from the Program or any part thereof, to be
   licensed as a whole to all third parties under the terms of this License.

c) You must cause Blockwell Fee Wallet
   “0xda0f00d92086E50099742B6bfB0230c942DdA4cC” to receive 2% of the total
   supply of tokens each and every any time tokens are created on the
   Blockchain network. This can be achieved using the current version of the
   source code to which this License attaches by setting the “feeAccount”
   parameter to Blockwell Fee Wallet
   “0xda0f00d92086E50099742B6bfB0230c942DdA4cC”, and the “feePercentageTenths”
   parameter to “20” when deploying.

d) You must add Blockwell’s wallet
   “0xda0f00d92086E50099742B6bfB0230c942DdA4cC” as a BW Admin, and you must
   not restrict the abilities of a BW Admin in any derivative works. This can
   be achieved using the current version of the source code to which this
   License attaches by setting the “bwAdmin” parameter to Blockwell’s wallet
   “0xda0f00d92086E50099742B6bfB0230c942DdA4cC” when deploying.

   These requirements apply to the modified work as a whole. If identifiable
   sections of that work are not derived from the Program, and can be reasonably
   considered independent and separate works in themselves, then this License,
   and its terms, do not apply to those sections when you distribute them as
   separate works. But when you distribute the same sections as part of a whole
   which is a work based on the Program, the distribution of the whole must be on
   the terms of this License, whose permissions for other licensees extend to the
   entire whole, and thus to each and every part regardless of who wrote it.

   Thus, it is not the intent of this section to claim rights or contest your
   rights to work written entirely by you; rather, the intent is to exercise the
   right to control the distribution of derivative or collective works based on
   the Program.

   In addition, mere aggregation of another work not based on the Program with
   the Program (or with a work based on the Program) on a volume of a storage or
   distribution medium does not bring the other work under the scope of this
   License.

3. You may copy and distribute the Program (or a work based on it, under
   Section 2) in object code or executable form under the terms of Sections 1
   and 2 above provided that you also make good faith and reasonable attempts
   to make available the complete corresponding machine-readable source code,
   which must be distributed under the terms of Sections 1 and 2 above.

   The source code for a work means the preferred form of the work for making
   modifications to it. For an executable work, complete source code means all
   the source code for all modules it contains, plus any associated interface
   definition files, plus the scripts used to control compilation and
   installation of the executable. However, as a special exception, the source
   code distributed need not include anything that is normally distributed (in
   either source or binary form) with the major components (compiler, kernel, and
   so on) of the operating system on which the executable runs, unless that
   component itself accompanies the executable.

   If distribution of executable or object code is made by offering access to
   copy from a designated place, then offering equivalent access to copy the
   source code from the same place counts as distribution of the source code,
   even though third parties are not compelled to copy the source along with the
   object code.

   Distribution and execution of executable or object code as part of existing
   smart contracts on the blockchain in the normal operation of the blockchain
   network (miners, node hosts, infrastructure providers and so on) is excepted
   from the requirement to make available the source code as set out in this
   clause.

4. You may not copy, modify, sublicense, or distribute the Program except as
   expressly provided under this License. Any attempt otherwise to copy,
   modify, sublicense or distribute the Program is void, and will
   automatically terminate your rights under this License. However, parties
   who have received copies, or rights, from you under this License will not
   have their licenses terminated so long as such parties remain in full
   compliance.

5. You are not required to accept this License, since you have not signed it.
   However, nothing else grants you permission to modify or distribute the
   Program or its derivative works. These actions are prohibited by law if you
   do not accept this License. Therefore, by modifying or distributing the
   Program (or any work based on the Program), you indicate your acceptance of
   this License to do so, and all its terms and conditions for copying,
   distributing or modifying the Program or works based on it.

6. Each time you redistribute the Program (or any work based on the Program),
   the recipient automatically receives a license from the original licensor
   to copy, distribute or modify the Program subject to these terms and
   conditions. You may not impose any further restrictions on the recipients'
   exercise of the rights granted herein. You are not responsible for
   enforcing compliance by third parties to this License.

7. If, as a consequence of a court judgment or allegation of patent
   infringement or for any other reason (not limited to patent issues),
   conditions are imposed on you (whether by court order, agreement or
   otherwise) that contradict the conditions of this License, they do not
   excuse you from the conditions of this License. If you cannot distribute so
   as to satisfy simultaneously your obligations under this License and any
   other pertinent obligations, then as a consequence you may not distribute
   the Program at all. For example, if a patent license would not permit
   royalty-free redistribution of the Program by all those who receive copies
   directly or indirectly through you, then the only way you could satisfy
   both it and this License would be to refrain entirely from distribution of
   the Program.

   If any portion of this section is held invalid or unenforceable under any
   particular circumstance, the balance of the section is intended to apply and
   the section as a whole is intended to apply in other circumstances.

   It is not the purpose of this section to induce you to infringe any patents or
   other property right claims or to contest validity of any such claims; this
   section has the sole purpose of protecting the integrity of the free software
   distribution system, which is implemented by public license practices. Many
   people have made generous contributions to the wide range of software
   distributed through that system in reliance on consistent application of that
   system; it is up to the author/donor to decide if he or she is willing to
   distribute software through any other system and a licensee cannot impose that
   choice.

   This section is intended to make thoroughly clear what is believed to be a
   consequence of the rest of this License.

8. Blockwell may publish revised and/or new versions of the Blockwell Smart
   License from time to time. Such new versions will be similar in spirit to
   the present version, but may differ in detail to address new problems or
   concerns.


NO WARRANTY

9. THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY APPLICABLE
   LAW. EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR
   OTHER PARTIES PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY OF ANY KIND,
   EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
   WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
   ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM AND YOUR USE
   OF THE SOURCE CODE INCLUDING AS TO ITS COMPLIANCE WITH ANY APPLICABLE LAW
   IS WITH YOU. SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
   NECESSARY SERVICING, REPAIR OR CORRECTION.

10. IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL
    ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
    REDISTRIBUTE THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES,
    INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES
    ARISING OUT OF THE USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT
    LIMITED TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES
    SUSTAINED BY YOU OR THIRD PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE
    WITH ANY OTHER PROGRAMS), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN
    ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.

END OF TERMS AND CONDITIONS

*/

pragma solidity >=0.8.0;

contract NoContract {

}

// SPDX-License-Identifier: LicenseRef-Blockwell-Smart-License
pragma solidity ^0.8.9;

import "common8/BadErc20.sol";
import "./GamePlay.sol";

error RewardAlreadyClaimed(uint256 tokenId);
error TooManyRanks();
error InvalidShares();

abstract contract Rewards is GamePlay {
    using BadErc20 for Erc20;

    uint8[] public rankToPercentOfPool;
    uint256[] internal rewardShares;
    uint8 public clubOwnerShare;

    event RewardClaimed(uint256 indexed tokenId, uint256 value);

    function addToPrizePool(uint256 value) external onlyAdmin {
        if (state.startTimestamp > 0 && block.timestamp > state.endTimestamp) {
            revert GameNotActive();
        }

        if (value > availableBalance()) {
            revert NotEnoughTokens();
        }

        pool.prizePool += value;
    }

    function configureRewards(uint8[] calldata rankShares, uint8 clubOwnerPercent) external onlyAdmin {
        if (state.startTimestamp > 0 && block.timestamp > state.endTimestamp) {
            revert GameNotActive();
        }

        if (rankShares.length > config.nft.clubsCount()) {
            revert TooManyRanks();
        }

        uint8 total = 0;

        for (uint256 i = 0; i < rankShares.length; i++) {
            total += rankShares[i];
        }

        if (total != 100) {
            revert InvalidShares();
        }
        if (clubOwnerPercent > 100) {
            revert InvalidShares();
        }

        rewardShares = rankShares;
        clubOwnerShare = clubOwnerPercent;
    }

    function claimRewardClub(uint256 clubId) external {
        calculateClubRankings();
        ClubData storage club = checkClubOwner(msg.sender, clubId);

        if (club.rewardClaimed) {
            revert RewardAlreadyClaimed(clubId);
        }
        uint256 value = (clubReward(clubId) * clubOwnerShare) / 100;
        rewardClub(clubId, msg.sender, value);
    }

    function distributeClubRewards() external {
        calculateClubRankings();
        uint256[] storage rankings = state.clubRankings;

        for (uint256 i = 0; i < rankings.length; i++) {
            uint256 clubId = rankings[i];
            uint256 value = (((rankToPercentOfPool[i] * pool.prizePool) / 100) * clubOwnerShare) / 100;
            rewardClub(clubId, config.nft.ownerOf(clubId), value);
        }
    }

    function rewardClub(
        uint256 clubId,
        address recipient,
        uint256 value
    ) internal {
        Erc20 token = config.token;
        if (!token.performTransfer(recipient, value)) {
            revert TransferFailed();
        }
        state.clubs[clubId].rewardClaimed = true;
        emit RewardClaimed(clubId, value);
    }

    function claimRewardStrippers(uint256[] calldata tokenIds) external {
        calculateClubRankings();
        uint256 total = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 id = tokenIds[i];
            StripperData storage stripper = checkStripperOwner(msg.sender, id);
            if (!stripper.staked) {
                revert InvalidStripper(id);
            }

            uint256 value = (clubReward(stripper.clubId) * (100 - clubOwnerShare)) /
                (100 * state.clubs[stripper.clubId].strippers);

            total += value;

            delete state.strippers[id];
            emit RewardClaimed(id, value);
        }
        Erc20 token = config.token;
        if (!token.performTransfer(msg.sender, total)) {
            revert TransferFailed();
        }
    }

    function distributeStripperRewards(uint256 count) external {
        calculateClubRankings();
        uint256[] memory clubs = getClubIds();
        uint256 clubCount = clubs.length;
        uint256[] memory clubStripperRewards = new uint256[](clubCount);

        // Calculate the stripper rewards for each club first, since there's many more strippers
        // than clubs. This is more efficient.
        for (uint256 i = 0; i < clubCount; i++) {
            uint256 clubId = clubs[i];
            uint256 rank = clubIdToFinishedRank(clubId);
            uint64 strippers = state.clubs[clubId].strippers;
            if (strippers > 0) {
                clubStripperRewards[i] =
                    (((rankToPercentOfPool[rank] * pool.prizePool) / 100) * (100 - clubOwnerShare)) /
                    (100 * strippers);
            }
        }

        Erc20 token = config.token;
        uint256 num = 0;
        for (uint256 i = state.stripperIds.length; i > 0; i--) {
            if (num == count) {
                return;
            }
            uint256 stripperId = state.stripperIds[i - 1];
            StripperData storage stripper = state.strippers[stripperId];

            if (stripper.staked) {
                uint256 value;
                for (uint256 j = 0; j < clubCount; j++) {
                    if (clubs[j] == stripper.clubId) {
                        value = clubStripperRewards[j];
                    }
                }

                if (value > 0 && !token.performTransfer(msg.sender, value)) {
                    revert TransferFailed();
                }
            }

            state.stripperIds.pop();
            ++num;
        }
    }

    function getRewardShares() public view returns (uint8[] memory) {
        return rankToPercentOfPool;
    }

    function clubIdToFinishedRank(uint256 clubId) public view returns (uint256) {
        uint256[] memory rankings;
        if (state.clubRankings.length > 0) {
            rankings = state.clubRankings;
        } else {
            rankings = getClubRankings();
        }

        for (uint256 i = 0; i < rankings.length; i++) {
            if (rankings[i] == clubId) {
                return i;
            }
        }
        revert InvalidClubId(clubId);
    }

    function clubReward(uint256 clubId) internal view returns (uint256) {
        return (rankToPercentOfPool[clubIdToFinishedRank(clubId)] * pool.prizePool) / 100;
    }
}

// SPDX-License-Identifier: LicenseRef-Blockwell-Smart-License
pragma solidity >=0.8.9;

import "./Erc20.sol";

library BadErc20 {
    bytes4 internal constant TRANSFER_SELECTOR = bytes4(keccak256(bytes("transfer(address,uint256)")));
    bytes4 internal constant APPROVE_SELECTOR = bytes4(keccak256(bytes("approve(address,uint256)")));
    bytes4 internal constant TRANSFER_FROM_SELECTOR = bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));

    function performTransfer(Erc20 token, address to, uint256 value) internal returns (bool) {
        return callWithData(token, abi.encodeWithSelector(TRANSFER_SELECTOR, to, value));
    }
    function performApprove(Erc20 token, address spender, uint256 value) internal returns (bool) {
        return callWithData(token, abi.encodeWithSelector(APPROVE_SELECTOR, spender, value));
    }
    function performTransferFrom(Erc20 token, address from, address to, uint256 value) internal returns (bool) {
        return callWithData(token, abi.encodeWithSelector(TRANSFER_FROM_SELECTOR, from, to, value));
    }

    function callWithData(Erc20 token, bytes memory data) internal returns (bool) {
        (, bytes memory returnData) = address(token).call(data);

        if (returnData.length == 0) {
            return true;
        }
        return abi.decode(returnData, (bool));
    }
}

// SPDX-License-Identifier: LicenseRef-Blockwell-Smart-License
pragma solidity ^0.8.9;

import "./Payment.sol";

abstract contract GamePlay is Payment {
    event StripperStaked(address indexed staker, uint256 indexed stripperId);
    event AddedCustomers(uint256 indexed clubId, uint64 customers);
    event AddedThieves(uint256 indexed fromClubId, uint256 indexed toClubId, uint64 thieves);
    event PoachedCustomers(uint256 indexed fromClubId, uint256 indexed toClubId, uint64 customers);

    function stakeStrippers(uint256[] calldata tokenIds, uint256 clubId) external {
        checkGameActive();
        ClubData storage club = checkValidClub(clubId);

        if (tokenIds.length > 0) {
            stakingPayment(clubId, tokenIds.length);
            updateActionPoints(clubId);

            for (uint256 i = 0; i < tokenIds.length; i++) {
                uint256 id = tokenIds[i];
                StripperData storage stripper = state.strippers[id];
                if (stripper.staked) {
                    revert StripperAlreadyStaked(id);
                }
                if (config.nft.ownerOf(id) != msg.sender) {
                    revert StripperNotOwned(id);
                }

                stripper.staked = true;
                stripper.totalInfluence = config.influenceOnStake;
                stripper.clubId = clubId;
                state.stripperIds.push(id);

                club.strippers += 1;
                club.totalActionPoints += config.apOnStake;

                emit StripperStaked(msg.sender, id);
            }
        }
    }

    function availableInfluence(uint256 stripperId) public view returns (uint64) {
        checkGameActive();
        StripperData storage stripper = state.strippers[stripperId];
        if (!stripper.staked) {
            revert InvalidStripper(stripperId);
        }

        (uint32 cycles, ) = missingCycles(stripper.influenceCalculationTimestamp);

        return stripper.totalInfluence + cycles * config.influencePerCycle - stripper.usedInfluence;
    }

    function addCustomers(uint256 clubId, uint64 numberOfCustomers) external {
        checkGameActive();
        ClubData storage club = checkClubOwner(msg.sender, clubId);
        updateActionPoints(clubId);

        uint64 cost = numberOfCustomers * config.customerApCost;

        if (club.totalActionPoints - club.usedActionPoints < cost) {
            revert NotEnoughActionPoints();
        }

        club.customers += numberOfCustomers;
        club.usedActionPoints += cost;

        emit AddedCustomers(clubId, numberOfCustomers);
    }

    function addThieves(
        uint256 fromClubId,
        uint256 toClubId,
        uint64 numberOfThieves
    ) external {
        checkGameActive();
        ClubData storage club = checkClubOwner(msg.sender, fromClubId);
        ClubData storage toClub = checkValidClub(toClubId);

        if (toClub.strippers < config.thiefStripperMinimum) {
            revert NotEnoughStrippers();
        }

        updateActionPoints(fromClubId);

        uint64 cost = numberOfThieves * config.thiefApCost;

        if (club.totalActionPoints - club.usedActionPoints < cost) {
            revert NotEnoughActionPoints();
        }

        toClub.thieves += numberOfThieves;
        club.usedActionPoints += cost;

        emit AddedThieves(fromClubId, toClubId, numberOfThieves);
    }

    function poachCustomers(uint256 stripperId, uint256 fromClubId, uint64 numberOfCustomers) external {
        checkGameActive();
        ClubData storage fromClub = checkValidClub(fromClubId);
        StripperData storage stripper = checkStripperOwner(msg.sender, stripperId);
        ClubData storage toClub = state.clubs[stripper.clubId];

        if (fromClub.strippers < config.thiefStripperMinimum) {
            revert NotEnoughStrippers();
        }

        updateInfluence(stripperId);

        uint64 cost = numberOfCustomers * config.poachInfluenceCost;

        if (stripper.totalInfluence - stripper.usedInfluence < cost) {
            revert NotEnoughActionPoints();
        }

        fromClub.customers -= numberOfCustomers;
        toClub.customers += numberOfCustomers;
        stripper.usedInfluence += cost;

        emit PoachedCustomers(fromClubId, stripper.clubId, numberOfCustomers);
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity >=0.8.0;

interface Erc20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: LicenseRef-Blockwell-Smart-License
pragma solidity ^0.8.9;

import "common8/BadErc20.sol";
import "./GameState.sol";

error TransferFailed();

abstract contract Payment is GameState {
    using BadErc20 for Erc20;

    uint256 internal networkSharePercentageTenths = 50;
    uint256 internal poolSharePercentageTenths = 20;

    function stakingPayment(uint256 clubId, uint256 multiplier) internal {
        uint256 cost = stakingCost(clubId) * multiplier;
        if (cost > 0) {
            if (!config.token.performTransferFrom(msg.sender, address(this), cost)) {
                revert TransferFailed();
            }

            uint256 networkShare = (networkSharePercentageTenths * cost) / 1000;
            uint256 poolShare = (poolSharePercentageTenths * cost) / 1000;

            pool.networkShare += networkShare;
            pool.prizePool += poolShare;
        }
    }

    function stakingCost(uint256 clubId) public view returns (uint256) {
        return config.stakeCost + config.popularityStakeCost * clubPopularity(clubId);
    }
}

// SPDX-License-Identifier: LicenseRef-Blockwell-Smart-License
pragma solidity ^0.8.9;

import "./PrizePool.sol";

error InvalidClubId(uint256 clubId);
error ClubNotOwned(uint256 clubId);
error GameNotActive();
error StripperAlreadyStaked(uint256 stripperId);
error StripperNotOwned(uint256 stripperId);
error InvalidStripper(uint256 stripperId);
error NotEnoughActionPoints();
error NotEnoughStrippers();
error GameNotEnded();
error GameActive();
error UnclaimedRewards();

abstract contract GameState is PrizePool {
    uint256 public constant CLUB_STARTING_ID = 1000000;

    struct ClubData {
        uint64 strippers;
        uint64 customers;
        uint64 thieves;
        uint64 usedActionPoints;
        uint64 totalActionPoints;
        uint64 apCalculationTimestamp;
        bool rewardClaimed;
    }

    struct StripperData {
        bool staked;
        uint64 usedInfluence;
        uint64 totalInfluence;
        uint64 influenceCalculationTimestamp;
        uint256 clubId;
    }

    struct State {
        uint64 startTimestamp;
        uint64 endTimestamp;
        mapping(uint256 => ClubData) clubs;
        mapping(uint256 => StripperData) strippers;
        uint256[] stripperIds;
        uint256[] clubRankings;
    }

    event GameStart(uint64 startTimestamp, uint64 endTimestamp);
    event GameEnd(uint64 endTimestamp);

    State internal state;

    function startGame(uint64 endTimestamp) public onlyAdmin {
        if (state.startTimestamp > 0 && block.timestamp < state.endTimestamp) {
            revert GameActive();
        }

        if (state.startTimestamp > 0) {
            resetState();
        }

        state.startTimestamp = uint64(block.timestamp);
        state.endTimestamp = endTimestamp;

        emit GameStart(state.startTimestamp, state.endTimestamp);
    }

    function endGame() public onlyAdmin {
        checkGameActive();

        state.endTimestamp = uint64(block.timestamp);
        emit GameEnd(state.endTimestamp);
    }

    function currentCycle() public view returns (uint32) {
        if (state.startTimestamp == 0) {
            return 0;
        }

        return 1 + uint32(block.timestamp - state.startTimestamp) / config.cycleLength;
    }

    function stripperData(uint256 stripperId) external view returns (StripperData memory) {
        StripperData storage stripper = state.strippers[stripperId];
        if (!stripper.staked) {
            revert InvalidStripper(stripperId);
        }
        return stripper;
    }

    function clubData(uint256 clubId) external view returns (ClubData memory) {
        return checkValidClub(clubId);
    }

    function availableActionPoints(uint256 clubId) public view returns (uint64) {
        checkGameActive();
        ClubData storage club = checkValidClub(clubId);
        (uint32 cycles, ) = missingCycles(club.apCalculationTimestamp);

        return club.totalActionPoints + cycles * club.strippers * config.apPerCycle - club.usedActionPoints;
    }

    function scoreForClubId(uint256 clubId) public view returns (int128) {
        return scoreForClub(checkValidClub(clubId));
    }

    function scoreForClub(ClubData storage club) internal view returns (int128) {
        return
            int128(int64(club.customers)) *
            int128(int16(config.scorePerCustomer)) -
            int64(club.thieves * config.penaltyPerThief);
    }

    function clubPopularity(uint256 clubId) public view returns (uint256) {
        ClubData storage club = checkValidClub(clubId);
        uint256 popularity = (uint256(config.popularityStrippersWeight) * uint256(club.strippers)) +
            (uint256(config.popularityApWeight) * uint256(availableActionPoints(clubId)));

        int128 score = scoreForClubId(clubId);

        if (score > 0) {
            popularity += uint128(score * int128(uint128(config.popularityScoreWeight)));
        }

        return popularity;
    }

    function getClubIds() public view returns (uint256[] memory) {
        uint256[] memory ids = new uint256[](config.nft.clubsCount());
        for (uint256 i = 0; i < ids.length; i++) {
            ids[i] = i + CLUB_STARTING_ID;
        }
        return ids;
    }

    function getClubScores() public view returns (int128[] memory) {
        int128[] memory scores = new int128[](config.nft.clubsCount());
        for (uint256 i = 0; i < scores.length; i++) {
            scores[i] = scoreForClub(state.clubs[i + CLUB_STARTING_ID]);
        }
        return scores;
    }

    function getClubRankings() public view returns (uint256[] memory) {
        uint256[] memory clubs = getClubIds();
        int128[] memory scores = getClubScores();
        uint256 length = clubs.length;
        uint256[] memory rankings = new uint256[](length);
        uint256 cap = length;

        uint256 pos;
        int128 score;
        for (uint256 i = 0; i < length; i++) {
            uint256 j = 0;
            // Find the highest remaining score
            for (; j < cap; j++) {
                if (j == 0 || score < scores[j]) {
                    pos = j;
                    score = scores[j];
                }
            }
            // Record the club ID
            rankings[i] = clubs[j];
            if (cap > 0) {
                // Move the club at the cap to the position we used and
                // reduce the cap to take the club we ranked just now out of
                // the calculations
                --cap;
                clubs[j] = clubs[cap];
                scores[j] = scores[cap];
            }
        }

        return rankings;
    }

    function calculateClubRankings() internal {
        checkGameEnded();
        if (state.clubRankings.length == 0) {
            state.clubRankings = getClubRankings();
        }
    }

    function isValidClubId(uint256 clubId) public view returns (bool) {
        return clubId >= CLUB_STARTING_ID && clubId < CLUB_STARTING_ID + config.nft.clubsCount();
    }

    function updateActionPoints(uint256 clubId) internal {
        ClubData storage club = state.clubs[clubId];

        (uint32 cycles, uint64 timestamp) = missingCycles(club.apCalculationTimestamp);

        if (cycles > 0) {
            club.totalActionPoints += cycles * club.strippers * config.apPerCycle;
            club.apCalculationTimestamp = timestamp;
        }
    }

    function updateInfluence(uint256 stripperId) internal {
        StripperData storage stripper = state.strippers[stripperId];

        (uint32 cycles, uint64 timestamp) = missingCycles(stripper.influenceCalculationTimestamp);

        if (cycles > 0) {
            stripper.totalInfluence += cycles * config.influencePerCycle;
            stripper.influenceCalculationTimestamp = timestamp;
        }
    }

    function missingCycles(uint64 timestamp) internal view returns (uint32, uint64) {
        uint64 startFrom;
        if (timestamp == 0) {
            startFrom = state.startTimestamp;
        } else {
            startFrom = timestamp;
        }

        uint32 cycles = uint32((block.timestamp - startFrom) / config.cycleLength);

        return (cycles, startFrom + cycles * config.cycleLength);
    }

    function checkValidClub(uint256 clubId) internal view returns (ClubData storage) {
        if (!isValidClubId(clubId)) {
            revert InvalidClubId(clubId);
        }
        return state.clubs[clubId];
    }

    function checkGameActive() internal view {
        if (state.startTimestamp == 0 || block.timestamp > state.endTimestamp || paused()) {
            revert GameNotActive();
        }
    }

    function checkClubOwner(address account, uint256 clubId) internal view returns (ClubData storage) {
        if (config.nft.ownerOf(clubId) != account) {
            revert ClubNotOwned(clubId);
        }
        return checkValidClub(clubId);
    }

    function checkStripperOwner(address account, uint256 stripperId)
        internal
        view
        returns (StripperData storage)
    {
        if (config.nft.ownerOf(stripperId) != account) {
            revert StripperNotOwned(stripperId);
        }
        return state.strippers[stripperId];
    }

    function checkGameEnded() internal view {
        if (state.startTimestamp == 0 || block.timestamp < state.endTimestamp) {
            revert GameNotEnded();
        }
    }

    function resetState() internal {
        uint256[] memory clubs = getClubIds();
        for (uint256 i = 0; i < clubs.length; i++) {
            uint256 clubId = clubs[i];
            if (!state.clubs[clubId].rewardClaimed) {
                revert UnclaimedRewards();
            }
            delete state.clubs[clubId];
        }
        if (state.stripperIds.length > 0) {
            revert UnclaimedRewards();
        }
        delete state.clubRankings;
        delete state;
    }
}

// SPDX-License-Identifier: LicenseRef-Blockwell-Smart-License
pragma solidity ^0.8.9;

import "./GameConfig.sol";
import "common8/BadErc20.sol";

error NotEnoughTokens();

abstract contract PrizePool is GameConfig {
    using BadErc20 for Erc20;

    struct PoolData {
        uint256 prizePool;
        uint256 networkShare;
    }

    PoolData internal pool;

    function prizePool() public view returns (uint256) {
        return pool.prizePool;
    }

    function availableBalance() public view returns (uint256) {
        return config.token.balanceOf(address(this)) - pool.prizePool - pool.networkShare;
    }

    function networkShareBalance() external view returns (uint256) {
        return pool.networkShare;
    }

    function withdrawNetworkShare() external onlyBwAdmin {
        Erc20 token = config.token;
        token.performTransfer(msg.sender, pool.networkShare);
        pool.networkShare = 0;
    }

    function withdrawTokens(Erc20 token, uint256 value) public onlyAdmin {
        if (token == config.token && value > availableBalance()) {
            revert NotEnoughTokens();
        }

        token.performTransfer(msg.sender, value);
    }

    function withdraw() public onlyAdmin {
        payable(msg.sender).transfer(address(this).balance);
    }
}

// SPDX-License-Identifier: LicenseRef-Blockwell-Smart-License
pragma solidity ^0.8.9;

import "./ContractGroups.sol";
import "common8/Erc20.sol";
import "./ClubNft.sol";

abstract contract GameConfig is ContractGroups {
    struct Config {
        Erc20 token;
        ClubNft nft;
        uint32 cycleLength; // Cycle/day length in seconds
        uint16 apOnStake; // AP given to club when stripper is staked
        uint16 apPerCycle; // AP per stripper given each cycle
        uint16 customerApCost; // AP cost of adding a customer
        uint16 thiefApCost; // AP cost of adding a thief
        uint16 scorePerCustomer; // Score value of a customer
        uint16 penaltyPerThief; // Score penalty of a thief
        uint16 thiefStripperMinimum; // Clubs with less than this number of strippers can't be thieved
        uint16 influenceOnStake; // Influence given to stripper on stake
        uint16 influencePerCycle; // Influence given per cycle
        uint16 poachInfluenceCost; // Steal customers influence cost
        uint16 popularityApWeight; // Weight of AP for calculating popularity
        uint16 popularityScoreWeight; // Weight of score for calculating popularity
        uint16 popularityStrippersWeight; // Weight of stripper count for calculating popularity
        uint256 stakeCost; // Cost to stake a stripper
        uint256 popularityStakeCost; // Added cost to stake a stripper for popularity
    }

    Config internal config;

    constructor(Erc20 token, ClubNft nft) {
        _addAdmin(msg.sender);
        configureTokens(token, nft);
        configureClubs(1, 1, 1, 1, 1, 2, 2);
        configureStrippers(2, 1, 2, 1, 0, 0);
    }

    function getConfig() external view returns (Config memory) {
        return config;
    }

    function configureTokens(Erc20 token, ClubNft nft) public onlyAdmin {
        config.token = token;
        config.nft = nft;
    }

    function setCycleLength(uint32 length) public onlyDelegate {
        config.cycleLength = length;
    }

    function configureClubs(
        uint16 apOnStake,
        uint16 apPerCycle,
        uint16 customerApCost,
        uint16 thiefApCost,
        uint16 scorePerCustomer,
        uint16 penaltyPerThief,
        uint16 thiefStripperMinimum
    ) public onlyDelegate {
        config.apOnStake = apOnStake;
        config.apPerCycle = apPerCycle;
        config.customerApCost = customerApCost;
        config.thiefApCost = thiefApCost;
        config.scorePerCustomer = scorePerCustomer;
        config.penaltyPerThief = penaltyPerThief;
        config.thiefStripperMinimum = thiefStripperMinimum;
    }

    function configureStrippers(
        uint16 influenceOnStake,
        uint16 influencePerCycle,
        uint16 poachInfluenceCost,
        uint16 popularityApWeight,
        uint16 popularityScoreWeight,
        uint16 popularityStrippersWeight
    ) public onlyDelegate {
        config.influenceOnStake = influenceOnStake;
        config.influencePerCycle = influencePerCycle;
        config.poachInfluenceCost = poachInfluenceCost;
        config.popularityApWeight = popularityApWeight;
        config.popularityScoreWeight = popularityScoreWeight;
        config.popularityStrippersWeight = popularityStrippersWeight;
    }

    function configureStaking(uint256 stakeCost, uint256 popularityStakeCost) public onlyDelegate {
        config.stakeCost = stakeCost;
        config.popularityStakeCost = popularityStakeCost;
    }
}

// SPDX-License-Identifier: LicenseRef-Blockwell-Smart-License
pragma solidity ^0.8.9;

import "common8/Groups.sol";
import "common8/BasicPausable.sol";

contract ContractGroups is BasicPausable {
    uint8 public constant ADMIN = 1;
    uint8 public constant BW_ADMIN = 6;
    uint8 public constant DELEGATE = 8;
    uint8 public constant AUTOMATOR = 11;

    using Groups for Groups.GroupMap;

    Groups.GroupMap groups;

    event AddedToGroup(uint8 indexed groupId, address indexed account);
    event RemovedFromGroup(uint8 indexed groupId, address indexed account);

    modifier onlyAdmin() {
        //e Only an admin can use this.
        if (!isAdmin(msg.sender)) {
            revert Unauthorized(ADMIN);
        }
        _;
    }

    modifier onlyAdminOrAutomator() {
        //e Only an admin can use this.
        if (!isAdmin(msg.sender) && !isAutomator(msg.sender)) {
            revert Unauthorized(AUTOMATOR);
        }
        _;
    }

    function pause() public whenNotPaused onlyAdmin {
        _pause();
    }

    function unpause() public whenPaused onlyAdmin {
        _unpause();
    }

    // ADMIN

    function _addAdmin(address account) internal {
        _add(ADMIN, account);
    }

    function addAdmin(address account) public onlyAdmin {
        _addAdmin(account);
    }

    function removeAdmin(address account) public onlyAdmin {
        _remove(ADMIN, account);
    }

    function isAdmin(address account) public view returns (bool) {
        return _contains(ADMIN, account);
    }

    // DELEGATE

    function addDelegate(address account) public onlyAdmin {
        _add(DELEGATE, account);
    }

    function removeDelegate(address account) public onlyAdmin {
        _remove(DELEGATE, account);
    }

    function isDelegate(address account) public view returns (bool) {
        return _contains(DELEGATE, account);
    }

    modifier onlyDelegate() {
        //e Only an admin can use this.
        if (!isAdmin(msg.sender) && !isDelegate(msg.sender)) {
            revert Unauthorized(DELEGATE);
        }
        _;
    }

    // AUTOMATOR

    function addAutomator(address account) public onlyAdmin {
        _add(AUTOMATOR, account);
    }

    function removeAutomator(address account) public onlyAdmin {
        _remove(AUTOMATOR, account);
    }

    function isAutomator(address account) public view returns (bool) {
        return _contains(AUTOMATOR, account);
    }

    modifier onlyAutomator() {
        if (!isAutomator(msg.sender)) {
            revert Unauthorized(AUTOMATOR);
        }
        _;
    }

    // BW_ADMIN

    function _addBwAdmin(address account) internal {
        _add(BW_ADMIN, account);
    }

    function addBwAdmin(address account) public onlyBwAdmin {
        _addBwAdmin(account);
    }

    function renounceBwAdmin() public {
        _remove(BW_ADMIN, msg.sender);
    }

    function isBwAdmin(address account) public view returns (bool) {
        return _contains(BW_ADMIN, account);
    }

    modifier onlyBwAdmin() {
        if (!isBwAdmin(msg.sender)) {
            revert Unauthorized(BW_ADMIN);
        }
        _;
    }

    /**
     * @dev Allows BW admins to add an admin to the contract in emergency cases.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function bwAddAdmin(address account) public onlyBwAdmin {
        _add(ADMIN, account);
    }

    /**
     * @dev Allows BW admins to remove an admin from the contract in emergency cases.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function bwRemoveAdmin(address account) public onlyBwAdmin {
        _remove(ADMIN, account);
    }

    // Internal functions

    function _add(uint8 groupId, address account) internal {
        groups.add(groupId, account);
        emit AddedToGroup(groupId, account);
    }

    function _remove(uint8 groupId, address account) internal {
        groups.remove(groupId, account);
        emit RemovedFromGroup(groupId, account);
    }

    function _contains(uint8 groupId, address account) internal view returns (bool) {
        return groups.contains(groupId, account);
    }
}

// SPDX-License-Identifier: LicenseRef-Blockwell-Smart-License
pragma solidity ^0.8.9;

import "common8/ERC721.sol";

interface ClubNft is ERC721 {
    function clubsCount() external view returns (uint256);
}

// SPDX-License-Identifier: LicenseRef-Blockwell-Smart-License
pragma solidity >=0.8.9;

error Unauthorized(uint8 group);

/**
 * @dev Unified system for arbitrary user groups.
 *
 * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
 */
library Groups {
    struct MemberMap {
        mapping(address => bool) members;
    }

    struct GroupMap {
        mapping(uint8 => MemberMap) groups;
    }

    /**
     * @dev Add an account to a group
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function add(
        GroupMap storage map,
        uint8 groupId,
        address account
    ) internal {
        MemberMap storage group = map.groups[groupId];
        require(account != address(0));
        require(!groupContains(group, account));

        group.members[account] = true;
    }

    /**
     * @dev Remove an account from a group
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function remove(
        GroupMap storage map,
        uint8 groupId,
        address account
    ) internal {
        MemberMap storage group = map.groups[groupId];
        require(account != address(0));
        require(groupContains(group, account));

        group.members[account] = false;
    }

    /**
     * @dev Returns true if the account is in the group
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     * @return bool
     */
    function contains(
        GroupMap storage map,
        uint8 groupId,
        address account
    ) internal view returns (bool) {
        MemberMap storage group = map.groups[groupId];
        return groupContains(group, account);
    }

    function groupContains(MemberMap storage group, address account) internal view returns (bool) {
        require(account != address(0));
        return group.members[account];
    }
}

// SPDX-License-Identifier: LicenseRef-Blockwell-Smart-License
pragma solidity >=0.8.9;

/**
 * @dev Pausing logic
 */
contract BasicPausable {
    event Paused(address account);
    event Unpaused(address account);

    bool internal _paused = false;

    function paused() public view returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!_paused);
        _;
    }

    modifier whenPaused() {
        require(_paused);
        _;
    }

    function _pause() internal {
        _paused = true;
        emit Paused(msg.sender);
    }

    function _unpause() internal {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x80ac58cd.
interface ERC721 /* is ERC165 */ {
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external payable;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external payable;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}