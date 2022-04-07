pragma solidity ^0.8.0;

import "@openzeppelin/contracts-4.4.1/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-4.4.1/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "../utils/proxy/solidity-0.8.0/ProxyReentrancyGuard.sol";
import "../utils/proxy/solidity-0.8.0/ProxyOwned.sol";
import "../interfaces/IExoticPositionalMarket.sol";
import "../interfaces/IExoticPositionalMarketManager.sol";
import "../interfaces/IThalesBonds.sol";

contract ThalesOracleCouncil is Initializable, ProxyOwned, PausableUpgradeable, ProxyReentrancyGuard {
    using SafeMath for uint;
    uint private constant COUNCIL_MAX_MEMBERS = 5;
    uint private constant VOTING_OPTIONS = 7;

    uint private constant ACCEPT_SLASH = 1;
    uint private constant ACCEPT_NO_SLASH = 2;
    uint private constant REFUSE_ON_POSITIONING = 3;
    uint private constant ACCEPT_RESULT = 4;
    uint private constant ACCEPT_RESET = 5;
    uint private constant REFUSE_MATURE = 6;

    uint private constant TEN_SUSD = 10 * 1e18;

    mapping(uint => address) public councilMemberAddress;
    mapping(address => uint) public councilMemberIndex;
    uint public councilMemberCount;
    IExoticPositionalMarketManager public marketManager;

    struct Dispute {
        address disputorAddress;
        string disputeString;
        uint disputeCode;
        uint disputeTimestamp;
        bool disputeInPositioningPhase;
    }

    mapping(address => mapping(uint => Dispute)) public dispute;
    mapping(address => uint) public marketTotalDisputes;
    mapping(address => uint) public marketLastClosedDispute;
    mapping(address => bool) public marketClosedForDisputes;

    mapping(address => mapping(uint => uint[])) public disputeVote;
    mapping(address => mapping(uint => uint[VOTING_OPTIONS])) public disputeVotesCount;
    mapping(address => mapping(uint => uint)) public disputeWinningPositionChoosen;
    mapping(address => address) public firstMemberThatChoseWinningPosition;
    mapping(address => uint) public allOpenDisputesCancelledToIndexForMarket;
    mapping(address => mapping(uint => mapping(address => uint))) public disputeWinningPositionChoosenByMember;
    mapping(address => mapping(uint => mapping(uint => uint))) public disputeWinningPositionVotes;

    uint private constant CREATOR_BOND = 101;
    uint private constant RESOLVER_BOND = 102;
    uint private constant DISPUTOR_BOND = 103;
    uint private constant CREATOR_AND_DISPUTOR = 104;
    uint private constant RESOLVER_AND_DISPUTOR = 105;

    mapping(address => uint) public marketOpenDisputesCount;

    function initialize(address _owner, address _marketManager) public initializer {
        setOwner(_owner);
        initNonReentrant();
        marketManager = IExoticPositionalMarketManager(_marketManager);
    }

    /* ========== VIEWS ========== */

    function canMarketBeDisputed(address _market) public view returns (bool) {
        return !marketClosedForDisputes[_market] && IExoticPositionalMarket(_market).isMarketCreated();
    }

    function getMarketOpenDisputes(address _market) external view returns (uint) {
        return marketOpenDisputesCount[_market];
    }

    function getMarketLastClosedDispute(address _market) external view returns (uint) {
        return marketLastClosedDispute[_market];
    }

    function getNumberOfCouncilMembersForMarketDispute(address _market, uint _index) external view returns (uint) {
        // zero index does not count
        return disputeVote[_market][_index].length.sub(1);
    }

    function getVotesCountForMarketDispute(address _market, uint _index) public view returns (uint) {
        uint count = 0;
        // council members index starts from 1
        for (uint i = 1; i < disputeVote[_market][_index].length; i++) {
            count += disputeVote[_market][_index][i] > 0 ? 1 : 0;
        }
        return count;
    }

    function getVotesMissingForMarketDispute(address _market, uint _index) external view returns (uint) {
        return disputeVote[_market][_index].length.sub(1).sub(getVotesCountForMarketDispute(_market, _index));
    }

    function getDispute(address _market, uint _index) external view returns (Dispute memory) {
        return dispute[_market][_index];
    }

    function getDisputeTimestamp(address _market, uint _index) external view returns (uint) {
        return dispute[_market][_index].disputeTimestamp;
    }

    function getDisputeAddressOfDisputor(address _market, uint _index) external view returns (address) {
        return dispute[_market][_index].disputorAddress;
    }

    function getDisputeString(address _market, uint _index) external view returns (string memory) {
        return dispute[_market][_index].disputeString;
    }

    function getDisputeCode(address _market, uint _index) external view returns (uint) {
        return dispute[_market][_index].disputeCode;
    }

    function getDisputeVotes(address _market, uint _index) external view returns (uint[] memory) {
        return disputeVote[_market][_index];
    }

    function getDisputeVoteOfCouncilMember(
        address _market,
        uint _index,
        address _councilMember
    ) external view returns (uint) {
        if (isOracleCouncilMember(_councilMember)) {
            return disputeVote[_market][_index][councilMemberIndex[_councilMember]];
        } else {
            require(isOracleCouncilMember(_councilMember), "Not a council member");
            return 1e18;
        }
    }

    function isDisputeOpen(address _market, uint _index) external view returns (bool) {
        return dispute[_market][_index].disputeCode == 0;
    }

    function isDisputeCancelled(address _market, uint _index) external view returns (bool) {
        return
            dispute[_market][_index].disputeCode == REFUSE_ON_POSITIONING ||
            dispute[_market][_index].disputeCode == REFUSE_MATURE;
    }

    function isOpenDisputeCancelled(address _market, uint _disputeIndex) external view returns (bool) {
        return
            (marketClosedForDisputes[_market] || _disputeIndex <= allOpenDisputesCancelledToIndexForMarket[_market]) &&
            dispute[_market][_disputeIndex].disputeCode == 0 &&
            marketLastClosedDispute[_market] != _disputeIndex;
    }

    function canDisputorClaimbackBondFromUnclosedDispute(
        address _market,
        uint _disputeIndex,
        address _disputorAddress
    ) public view returns (bool) {
        if (
            _disputeIndex <= marketTotalDisputes[_market] &&
            (marketClosedForDisputes[_market] || _disputeIndex <= allOpenDisputesCancelledToIndexForMarket[_market]) &&
            dispute[_market][_disputeIndex].disputorAddress == _disputorAddress &&
            dispute[_market][_disputeIndex].disputeCode == 0 &&
            marketLastClosedDispute[_market] != _disputeIndex &&
            IThalesBonds(marketManager.thalesBonds()).getDisputorBondForMarket(_market, _disputorAddress) > 0
        ) {
            return true;
        } else {
            return false;
        }
    }

    function isOracleCouncilMember(address _councilMember) public view returns (bool) {
        return (councilMemberIndex[_councilMember] > 0);
    }

    function isMarketClosedForDisputes(address _market) public view returns (bool) {
        return marketClosedForDisputes[_market] || IExoticPositionalMarket(_market).canUsersClaim();
    }

    function setMarketManager(address _marketManager) external onlyOwner {
        require(_marketManager != address(0), "Invalid manager address");
        marketManager = IExoticPositionalMarketManager(_marketManager);
        emit NewMarketManager(_marketManager);
    }

    function addOracleCouncilMember(address _councilMember) external onlyOwner {
        require(_councilMember != address(0), "Invalid address. Add valid address");
        require(councilMemberCount <= marketManager.maxOracleCouncilMembers(), "Number of Oracle Council members exceeded");
        require(!isOracleCouncilMember(_councilMember), "Already Oracle Council member");
        councilMemberCount = councilMemberCount.add(1);
        councilMemberAddress[councilMemberCount] = _councilMember;
        councilMemberIndex[_councilMember] = councilMemberCount;
        marketManager.addPauserAddress(_councilMember);
        emit NewOracleCouncilMember(_councilMember, councilMemberCount);
    }

    function removeOracleCouncilMember(address _councilMember) external onlyOwner {
        require(isOracleCouncilMember(_councilMember), "Not an Oracle Council member");
        councilMemberAddress[councilMemberIndex[_councilMember]] = councilMemberAddress[councilMemberCount];
        councilMemberIndex[councilMemberAddress[councilMemberCount]] = councilMemberIndex[_councilMember];
        councilMemberCount = councilMemberCount.sub(1);
        councilMemberIndex[_councilMember] = 0;
        marketManager.removePauserAddress(_councilMember);
        emit OracleCouncilMemberRemoved(_councilMember, councilMemberCount);
    }

    function openDispute(address _market, string memory _disputeString) external whenNotPaused {
        require(IExoticPositionalMarket(_market).isMarketCreated(), "Market not created");
        require(!isMarketClosedForDisputes(_market), "Market is closed for disputes");
        require(marketManager.creatorAddress(_market) != msg.sender, "Creator can not dispute market");
        require(!isOracleCouncilMember(msg.sender), "Oracle Council member can not open dispute.");
        require(
            IERC20(marketManager.paymentToken()).balanceOf(msg.sender) >= IExoticPositionalMarket(_market).disputePrice(),
            "Low token amount for disputing market"
        );
        require(
            IERC20(marketManager.paymentToken()).allowance(msg.sender, marketManager.thalesBonds()) >=
                IExoticPositionalMarket(_market).disputePrice(),
            "No allowance. Please approve ticket price allowance"
        );
        require(
            keccak256(abi.encode(_disputeString)) != keccak256(abi.encode("")),
            "Invalid market question (empty string)"
        );
        require(
            bytes(_disputeString).length < marketManager.disputeStringLengthLimit() || bytes(_disputeString).length < 110,
            "String exceeds length"
        );

        marketTotalDisputes[_market] = marketTotalDisputes[_market].add(1);
        marketOpenDisputesCount[_market] = marketOpenDisputesCount[_market].add(1);
        dispute[_market][marketTotalDisputes[_market]].disputorAddress = msg.sender;
        dispute[_market][marketTotalDisputes[_market]].disputeString = _disputeString;
        dispute[_market][marketTotalDisputes[_market]].disputeTimestamp = block.timestamp;
        disputeVote[_market][marketTotalDisputes[_market]] = new uint[](councilMemberCount + 1);
        if (!IExoticPositionalMarket(_market).resolved()) {
            dispute[_market][marketTotalDisputes[_market]].disputeInPositioningPhase = true;
        }
        marketManager.disputeMarket(_market, msg.sender);
        emit NewDispute(
            _market,
            _disputeString,
            dispute[_market][marketTotalDisputes[_market]].disputeInPositioningPhase,
            msg.sender
        );
    }

    function voteForDispute(
        address _market,
        uint _disputeIndex,
        uint _disputeCodeVote,
        uint _winningPosition
    ) external onlyCouncilMembers {
        require(!isMarketClosedForDisputes(_market), "Market is closed for disputes. No reason for voting");
        require(_disputeIndex > 0, "Dispute non existent");
        require(dispute[_market][_disputeIndex].disputeCode == 0, "Dispute already closed.");
        require(_disputeCodeVote <= VOTING_OPTIONS && _disputeCodeVote > 0, "Invalid dispute code.");
        if (dispute[_market][_disputeIndex].disputeInPositioningPhase) {
            require(_disputeCodeVote < ACCEPT_RESULT, "Invalid voting code for dispute in positioning phase");
        } else {
            require(_disputeCodeVote >= ACCEPT_RESULT, "Invalid voting code for dispute in maturity phase");
            require(
                _disputeIndex > allOpenDisputesCancelledToIndexForMarket[_market],
                "Dispute is already cancelled previously"
            );
        }
        if (_winningPosition > 0 && _disputeCodeVote == ACCEPT_RESULT) {
            require(
                _winningPosition != IExoticPositionalMarket(_market).winningPosition(),
                "OC member can not vote for the resolved position"
            );
            require(
                disputeWinningPositionChoosenByMember[_market][_disputeIndex][msg.sender] != _winningPosition,
                "Voting for same winning position"
            );
            if (disputeWinningPositionChoosenByMember[_market][_disputeIndex][msg.sender] == 0) {
                disputeWinningPositionChoosenByMember[_market][_disputeIndex][msg.sender] = _winningPosition;
                disputeWinningPositionVotes[_market][_disputeIndex][_winningPosition] = disputeWinningPositionVotes[_market][
                    _disputeIndex
                ][_winningPosition]
                    .add(1);
            } else {
                disputeWinningPositionVotes[_market][_disputeIndex][
                    disputeWinningPositionChoosenByMember[_market][_disputeIndex][msg.sender]
                ] = disputeWinningPositionVotes[_market][_disputeIndex][
                    disputeWinningPositionChoosenByMember[_market][_disputeIndex][msg.sender]
                ]
                    .sub(1);
                disputeWinningPositionChoosenByMember[_market][_disputeIndex][msg.sender] = _winningPosition;
                disputeWinningPositionVotes[_market][_disputeIndex][_winningPosition] = disputeWinningPositionVotes[_market][
                    _disputeIndex
                ][_winningPosition]
                    .add(1);
            }
        }

        // check if already has voted for another option, and revert the vote
        if (disputeVote[_market][_disputeIndex][councilMemberIndex[msg.sender]] > 0) {
            disputeVotesCount[_market][_disputeIndex][
                disputeVote[_market][_disputeIndex][councilMemberIndex[msg.sender]]
            ] = disputeVotesCount[_market][_disputeIndex][
                disputeVote[_market][_disputeIndex][councilMemberIndex[msg.sender]]
            ]
                .sub(1);
        }

        // record the voting option
        disputeVote[_market][_disputeIndex][councilMemberIndex[msg.sender]] = _disputeCodeVote;
        disputeVotesCount[_market][_disputeIndex][_disputeCodeVote] = disputeVotesCount[_market][_disputeIndex][
            _disputeCodeVote
        ]
            .add(1);

        emit VotedAddedForDispute(_market, _disputeIndex, _disputeCodeVote, _winningPosition, msg.sender);

        if (disputeVotesCount[_market][_disputeIndex][_disputeCodeVote] > (councilMemberCount.div(2))) {
            if (_disputeCodeVote == ACCEPT_RESULT) {
                (uint maxVotesForPosition, uint chosenPosition) =
                    calculateWinningPositionBasedOnVotes(_market, _disputeIndex);
                if (maxVotesForPosition > (councilMemberCount.div(2))) {
                    disputeWinningPositionChoosen[_market][_disputeIndex] = chosenPosition;
                    closeDispute(_market, _disputeIndex, _disputeCodeVote);
                }
            } else {
                closeDispute(_market, _disputeIndex, _disputeCodeVote);
            }
        }
    }

    function closeDispute(
        address _market,
        uint _disputeIndex,
        uint _decidedOption
    ) internal nonReentrant {
        require(dispute[_market][_disputeIndex].disputeCode == 0, "Dispute already closed");
        require(_decidedOption > 0, "Invalid decided option");
        dispute[_market][_disputeIndex].disputeCode = _decidedOption;
        marketOpenDisputesCount[_market] = marketOpenDisputesCount[_market] > 0
            ? marketOpenDisputesCount[_market].sub(1)
            : 0;
        if (_decidedOption == REFUSE_ON_POSITIONING || _decidedOption == REFUSE_MATURE) {
            // set dispute to false
            // send disputor BOND to SafeBox
            // marketManager.getMarketBondAmount(_market);
            IThalesBonds(marketManager.thalesBonds()).sendBondFromMarketToUser(
                _market,
                marketManager.safeBoxAddress(),
                IExoticPositionalMarket(_market).disputePrice(),
                DISPUTOR_BOND,
                dispute[_market][_disputeIndex].disputorAddress
            );
            marketLastClosedDispute[_market] = _disputeIndex;
            //if it is the last dispute
            if (_decidedOption == REFUSE_MATURE) {
                marketManager.setBackstopTimeout(_market);
            }
            if (marketOpenDisputesCount[_market] == 0) {
                marketManager.closeDispute(_market);
            }
            emit DisputeClosed(_market, _disputeIndex, _decidedOption);
        } else if (_decidedOption == ACCEPT_SLASH) {
            // 4 hours
            marketManager.setBackstopTimeout(_market);
            // close dispute flag
            marketManager.closeDispute(_market);
            // cancel market
            marketManager.cancelMarket(_market);
            marketClosedForDisputes[_market] = true;
            // send bond to disputor and safeBox
            IThalesBonds(marketManager.thalesBonds()).sendBondFromMarketToUser(
                _market,
                marketManager.safeBoxAddress(),
                IExoticPositionalMarket(_market).safeBoxLowAmount(),
                CREATOR_BOND,
                dispute[_market][_disputeIndex].disputorAddress
            );
            IThalesBonds(marketManager.thalesBonds()).sendBondFromMarketToUser(
                _market,
                dispute[_market][_disputeIndex].disputorAddress,
                (IExoticPositionalMarket(_market).fixedBondAmount().add(IExoticPositionalMarket(_market).disputePrice()))
                    .sub(IExoticPositionalMarket(_market).safeBoxLowAmount()),
                CREATOR_AND_DISPUTOR,
                dispute[_market][_disputeIndex].disputorAddress
            );

            marketLastClosedDispute[_market] = _disputeIndex;
            emit MarketClosedForDisputes(_market, _decidedOption);
            emit DisputeClosed(_market, _disputeIndex, _decidedOption);
        } else if (_decidedOption == ACCEPT_NO_SLASH) {
            // 4 hours
            marketManager.setBackstopTimeout(_market);
            // close dispute flag
            marketManager.closeDispute(_market);
            // close market(cancel market)
            marketManager.cancelMarket(_market);
            marketClosedForDisputes[_market] = true;
            // send bond to disputor and safeBox
            // IThalesBonds(marketManager.thalesBonds()).sendBondFromMarketToUser(_market, marketManager.safeBoxAddress(), marketManager.safeBoxLowAmount());
            IThalesBonds(marketManager.thalesBonds()).sendBondFromMarketToUser(
                _market,
                marketManager.creatorAddress(_market),
                IExoticPositionalMarket(_market).fixedBondAmount(),
                CREATOR_BOND,
                dispute[_market][_disputeIndex].disputorAddress
            );
            IThalesBonds(marketManager.thalesBonds()).sendBondFromMarketToUser(
                _market,
                dispute[_market][_disputeIndex].disputorAddress,
                IExoticPositionalMarket(_market).disputePrice(),
                DISPUTOR_BOND,
                dispute[_market][_disputeIndex].disputorAddress
            );
            marketManager.sendRewardToDisputor(
                _market,
                dispute[_market][_disputeIndex].disputorAddress,
                IExoticPositionalMarket(_market).arbitraryRewardForDisputor()
            );

            marketLastClosedDispute[_market] = _disputeIndex;
            emit MarketClosedForDisputes(_market, _decidedOption);
            emit DisputeClosed(_market, _disputeIndex, _decidedOption);
        } else if (_decidedOption == ACCEPT_RESULT) {
            // close market
            // timer backstop
            marketManager.setBackstopTimeout(_market);
            // close dispute flag
            marketManager.closeDispute(_market);
            // set result
            marketManager.resolveMarket(_market, disputeWinningPositionChoosen[_market][_disputeIndex]);
            IThalesBonds(marketManager.thalesBonds()).sendBondFromMarketToUser(
                _market,
                marketManager.safeBoxAddress(),
                IExoticPositionalMarket(_market).fixedBondAmount(),
                RESOLVER_BOND,
                dispute[_market][_disputeIndex].disputorAddress
            );
            IThalesBonds(marketManager.thalesBonds()).sendBondFromMarketToUser(
                _market,
                dispute[_market][_disputeIndex].disputorAddress,
                IExoticPositionalMarket(_market).disputePrice(),
                DISPUTOR_BOND,
                dispute[_market][_disputeIndex].disputorAddress
            );

            marketClosedForDisputes[_market] = true;
            marketLastClosedDispute[_market] = _disputeIndex;
            emit MarketClosedForDisputes(_market, _decidedOption);
            emit DisputeClosed(_market, _disputeIndex, _decidedOption);
        } else if (_decidedOption == ACCEPT_RESET) {
            // close dispute flag
            marketManager.closeDispute(_market);
            // reset result
            marketManager.resetMarket(_market);
            IThalesBonds(marketManager.thalesBonds()).sendBondFromMarketToUser(
                _market,
                marketManager.safeBoxAddress(),
                IExoticPositionalMarket(_market).safeBoxLowAmount(),
                RESOLVER_BOND,
                dispute[_market][_disputeIndex].disputorAddress
            );
            IThalesBonds(marketManager.thalesBonds()).sendBondFromMarketToUser(
                _market,
                dispute[_market][_disputeIndex].disputorAddress,
                IExoticPositionalMarket(_market).fixedBondAmount().add(IExoticPositionalMarket(_market).disputePrice()).sub(
                    IExoticPositionalMarket(_market).safeBoxLowAmount()
                ),
                RESOLVER_AND_DISPUTOR,
                dispute[_market][_disputeIndex].disputorAddress
            );
            allOpenDisputesCancelledToIndexForMarket[_market] = marketTotalDisputes[_market];
            marketOpenDisputesCount[_market] = 0;
            marketLastClosedDispute[_market] = _disputeIndex;
            emit DisputeClosed(_market, _disputeIndex, _decidedOption);
        } else {
            // (CANCEL)
        }
    }

    function claimUnclosedDisputeBonds(address _market, uint _disputeIndex) external whenNotPaused {
        require(
            canDisputorClaimbackBondFromUnclosedDispute(_market, _disputeIndex, msg.sender),
            "Unable to claim bonds. Check if market is closed for disputes, disputor index, and dispute address"
        );
        IThalesBonds(marketManager.thalesBonds()).sendOpenDisputeBondFromMarketToDisputor(
            _market,
            msg.sender,
            IThalesBonds(marketManager.thalesBonds()).getDisputorBondForMarket(_market, msg.sender)
        );
    }

    function calculateWinningPositionBasedOnVotes(address _market, uint _disputeIndex) internal view returns (uint, uint) {
        uint maxVotes;
        uint position;
        for (uint i = 0; i <= IExoticPositionalMarket(_market).positionCount(); i++) {
            if (disputeWinningPositionVotes[_market][_disputeIndex][i] > maxVotes) {
                maxVotes = disputeWinningPositionVotes[_market][_disputeIndex][i];
                position = i;
            }
        }

        return (maxVotes, position);
    }

    function closeMarketForDisputes(address _market) external onlyOwner {
        require(!marketClosedForDisputes[_market], "Market already closed for disputes");
        marketClosedForDisputes[_market] = true;
        emit MarketClosedForDisputes(_market, 0);
    }

    function reopenMarketForDisputes(address _market) external onlyOwner {
        require(marketClosedForDisputes[_market], "Market already open for disputes");
        marketClosedForDisputes[_market] = false;
        emit MarketReopenedForDisputes(_market);
    }

    modifier onlyCouncilMembers() {
        require(isOracleCouncilMember(msg.sender), "Issuer not a council member");
        _;
    }
    event NewOracleCouncilMember(address councilMember, uint councilMemberCount);
    event OracleCouncilMemberRemoved(address councilMember, uint councilMemberCount);
    event NewMarketManager(address marketManager);
    event NewDispute(address market, string disputeString, bool disputeInPositioningPhase, address disputorAccount);
    event VotedAddedForDispute(address market, uint disputeIndex, uint disputeCodeVote, uint winningPosition, address voter);
    event MarketClosedForDisputes(address market, uint disputeFinalCode);
    event MarketReopenedForDisputes(address market);
    event DisputeClosed(address market, uint disputeIndex, uint decidedOption);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the `nonReentrant` modifier
 * available, which can be aplied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 */
contract ProxyReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;
    bool private _initialized;

    function initNonReentrant() public {
        require(!_initialized, "Already initialized");
        _initialized = true;
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Clone of syntetix contract without constructor
contract ProxyOwned {
    address public owner;
    address public nominatedOwner;
    bool private _initialized;
    bool private _transferredAtInit;

    function setOwner(address _owner) public {
        require(_owner != address(0), "Owner address cannot be 0");
        require(!_initialized, "Already initialized, use nominateNewOwner");
        _initialized = true;
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    function transferOwnershipAtInit(address proxyAddress) external onlyOwner {
        require(proxyAddress != address(0), "Invalid address");
        require(!_transferredAtInit, "Already transferred");
        owner = proxyAddress;
        _transferredAtInit = true;
        emit OwnerChanged(owner, proxyAddress);
    }

    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    function _onlyOwner() private view {
        require(msg.sender == owner, "Only the contract owner may perform this action");
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}

pragma solidity ^0.8.0;

interface IExoticPositionalMarket {
    /* ========== VIEWS / VARIABLES ========== */
    function isMarketCreated() external view returns (bool);
    function creatorAddress() external view returns (address);
    function resolverAddress() external view returns (address);
    function totalBondAmount() external view returns(uint);

    function marketQuestion() external view returns(string memory);
    function marketSource() external view returns(string memory);
    function positionPhrase(uint index) external view returns(string memory);

    function getTicketType() external view returns(uint);
    function positionCount() external view returns(uint);
    function endOfPositioning() external view returns(uint);
    function resolvedTime() external view returns(uint);
    function fixedTicketPrice() external view returns(uint);
    function creationTime() external view returns(uint);
    function winningPosition() external view returns(uint);
    function getTags() external view returns(uint[] memory);
    function getTotalPlacedAmount() external view returns(uint);
    function getTotalClaimableAmount() external view returns(uint);
    function getPlacedAmountPerPosition(uint index) external view returns(uint);
    function fixedBondAmount() external view returns(uint);
    function disputePrice() external view returns(uint);
    function safeBoxLowAmount() external view returns(uint);
    function arbitraryRewardForDisputor() external view returns(uint);
    function backstopTimeout() external view returns(uint);
    function disputeClosedTime() external view returns(uint);
    
    function withdrawalAllowed() external view returns(bool);
    function disputed() external view returns(bool);
    function resolved() external view returns(bool);
    function canUsersPlacePosition() external view returns (bool);
    function canMarketBeResolvedByPDAO() external view returns(bool);
    function canMarketBeResolved() external view returns (bool);
    function canUsersClaim() external view returns (bool);
    function isMarketCancelled() external view returns (bool);
    function paused() external view returns (bool);
    function canCreatorCancelMarket() external view returns (bool);
    function getAllFees() external view returns (uint, uint, uint, uint);


    function transferBondToMarket(address _sender, uint _amount) external;
    function resolveMarket(uint _outcomePosition, address _resolverAddress) external;
    function cancelMarket() external;
    function resetMarket() external;
    function claimWinningTicketOnBehalf(address _user) external;
    function openDispute() external;
    function closeDispute() external;
    function setBackstopTimeout(uint _timeoutPeriod) external;


}

pragma solidity ^0.8.0;

interface IExoticPositionalMarketManager {
    /* ========== VIEWS / VARIABLES ========== */
    function getActiveMarketAddress(uint _index) external view returns(address);
    function getActiveMarketIndex(address _marketAddress) external view returns(uint);
    function isActiveMarket(address _marketAddress) external view returns(bool);
    function numOfActiveMarkets() external view returns(uint);
    function getMarketBondAmount(address _market) external view returns (uint);
    function maximumPositionsAllowed() external view returns(uint);
    function paymentToken() external view returns(address);
    function owner() external view returns(address);
    function thalesBonds() external view returns(address);
    function oracleCouncilAddress() external view returns(address);
    function safeBoxAddress() external view returns(address);
    function creatorAddress(address _market) external view returns(address);
    function resolverAddress(address _market) external view returns(address);
    function isPauserAddress(address _pauserAddress) external view returns(bool);
    function safeBoxPercentage() external view returns(uint);
    function creatorPercentage() external view returns(uint);
    function resolverPercentage() external view returns(uint);
    function withdrawalPercentage() external view returns(uint);
    function pDAOResolveTimePeriod() external view returns(uint);
    function claimTimeoutDefaultPeriod() external view returns(uint);
    function maxOracleCouncilMembers() external view returns(uint);
    function fixedBondAmount() external view returns(uint);
    function disputePrice() external view returns(uint);
    function safeBoxLowAmount() external view returns(uint);
    function arbitraryRewardForDisputor() external view returns(uint);
    function disputeStringLengthLimit() external view returns(uint);
    function cancelledByCreator(address _market) external view returns(bool);

    function createExoticMarket(
        string memory _marketQuestion,
        string memory _marketSource,
        uint _endOfPositioning,
        uint _fixedTicketPrice,
        bool _withdrawalAllowed,
        uint[] memory _tags,
        uint _positionCount,
        string[] memory _positionPhrases
    ) external;
    
    function createCLMarket(
        string memory _marketQuestion,
        string memory _marketSource,
        uint _endOfPositioning,
        uint _fixedTicketPrice,
        bool _withdrawalAllowed,
        uint[] memory _tags,
        uint _positionCount,
        string[] memory _positionPhrases
    ) external;
    
    function disputeMarket(address _marketAddress, address disputor) external;
    function resolveMarket(address _marketAddress, uint _outcomePosition) external;
    function resetMarket(address _marketAddress) external;
    function cancelMarket(address _market) external ;
    function closeDispute(address _market) external ;
    function setBackstopTimeout(address _market) external; 
    function sendMarketBondAmountTo(address _market, address _recepient, uint _amount) external;
    function addPauserAddress(address _pauserAddress) external;
    function removePauserAddress(address _pauserAddress) external;
    function sendRewardToDisputor(address _market, address _disputorAddress, uint amount) external;
    function issueBondsBackToCreatorAndResolver(address _marketAddress) external ;


}

pragma solidity ^0.8.0;

interface IThalesBonds {
    /* ========== VIEWS / VARIABLES ========== */
    function getTotalDepositedBondAmountForMarket(address _market) external view returns(uint);
    function getClaimedBondAmountForMarket(address _market) external view returns(uint);
    function getClaimableBondAmountForMarket(address _market) external view returns(uint);
    function getDisputorBondForMarket(address _market, address _disputorAddress) external view returns (uint);
    function getCreatorBondForMarket(address _market) external view returns (uint);
    function getResolverBondForMarket(address _market) external view returns (uint);

    function sendCreatorBondToMarket(address _market, address _creatorAddress, uint _amount) external;
    function sendResolverBondToMarket(address _market, address _resolverAddress, uint _amount) external;
    function sendDisputorBondToMarket(address _market, address _disputorAddress, uint _amount) external;
    function sendBondFromMarketToUser(address _market, address _account, uint _amount, uint _bondToReduce, address _disputorAddress) external;
    function sendOpenDisputeBondFromMarketToDisputor(address _market, address _account, uint _amount) external;
    function setOracleCouncilAddress(address _oracleCouncilAddress) external;
    function setManagerAddress(address _managerAddress) external;
    function issueBondsBackToCreatorAndResolver(address _market) external;
    function transferToMarket(address _account, uint _amount) external;    
    function transferFromMarket(address _account, uint _amount) external;
    function transferCreatorToResolverBonds(address _market) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}