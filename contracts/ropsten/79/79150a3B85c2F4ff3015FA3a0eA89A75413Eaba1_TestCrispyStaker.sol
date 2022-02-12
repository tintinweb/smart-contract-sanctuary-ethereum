// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.9;

import {CrispyStaker} from "../products/CrispyStaker.sol";
import {console} from "hardhat/console.sol";

/**
 * @author Dumonet Distributed Technologies
 */
contract TestCrispyStaker is CrispyStaker {
    event EmptyFunctionEvent();

    mapping(uint256 => uint256) public tokenIdToStakeId;
    mapping(uint256 => bool) public tokenIdAssigned;

    constructor(
        string memory _name,
        string memory _symbol,
        address _hexToken,
        uint256 _startMaxFee,
        uint256 _startCreateFee,
        uint256 _startRolloverFee,
        string memory _contractURI
    )
        CrispyStaker(
            _name,
            _symbol,
            _hexToken,
            _startMaxFee,
            _startCreateFee,
            _startRolloverFee,
            _contractURI
        )
    {}

    function depositFees(uint256 _feeAmount) external {
        _deposit(_feeAmount);
    }

    function emptyFunction() external {
        emit EmptyFunctionEvent();
    }

    function getDelta() external view returns (uint256) {
        return _getFreeBalance();
    }

    function checkCreateFeeEquals(uint256 _expectedCreateFee) external view {
        require(_expectedCreateFee == createFee, "TestCrSt: Unexpected fee");
    }

    function checkRolloverFeeEquals(uint256 _expectedRolloverFee) external view {
        require(_expectedRolloverFee == rolloverFee, "TestCrSt: Unexpected fee");
    }

    function _registerOpenStake(uint256 _tokenId, uint256 _stakeIndex) internal override {
        require(!tokenIdAssigned[_tokenId], "TCH: Token already assigned");
        require(
            _stakeIndex == hexToken().stakeCount(address(this)) - 1,
            "TCH: Invalid stake index"
        );
        tokenIdToStakeId[_tokenId] = _getStakeId(_stakeIndex);
        tokenIdAssigned[_tokenId] = true;
    }

    function _closeStakeCheck(
        uint256 _tokenId,
        uint256 _stakeIndex,
        uint256 _stakeId
    ) internal override {
        if (tokenIdToStakeId[_tokenId] != _stakeId) {
            console.log("_tokenId: ", _tokenId);
            console.log("_stakeId: ", _stakeId);
            revert("TCH: Stake misalignment");
        }
        require(tokenIdAssigned[_tokenId], "TCH: Token not assigned (I)");
        uint256 realStakeId = _getStakeId(_stakeIndex);
        require(realStakeId == _stakeId, "TCH: Invalid stake index");
        tokenIdAssigned[_tokenId] = false;
    }

    function _verifyStakeConnection(uint256 _tokenId, uint256 _stakeIndex) internal view override {
        require(tokenIdAssigned[_tokenId], "TCH: Token not assigned (II)");
        if (tokenIdToStakeId[_tokenId] != _getStakeId(_stakeIndex)) {
            console.log("_tokenId: ", _tokenId);
            console.log("_stakeIndex: ", _stakeIndex);
            console.log("tokenIdToStakeId[_tokenId]: ", tokenIdToStakeId[_tokenId]);
            console.log("_getStakeId(_stakeIndex): ", _getStakeId(_stakeIndex));
            revert("TCH: Wrong stake id");
        }
    }

    function _getStakeId(uint256 _stakeIndex) internal view returns (uint256) {
        (uint256 stakeId, , , , , , ) = hexToken().stakeLists(address(this), _stakeIndex);
        return stakeId;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.9;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {DualFeeTaker} from "./DualFeeTaker.sol";
import {IHex} from "../lib/interfaces/IHex.sol";
import {TwoWayMapping} from "../lib/TwoWayMapping.sol";
import {ICrispyStaker} from "./interfaces/ICrispyStaker.sol";

/**
 * @author Dumonet Distributed Technologies
 *
 * @dev
 *
 * Contract that allows the creation of Hex stakes wrapped as non-fungible
 * ERC721 tokens. Each stake is under the full, trustless control of the
 * owner. Ownership is represented using the ERC721 standard. Transferring
 * and/or selling a stake's related token is equivalent to transferring the stake
 * itself.
 *
 * The contract may take a fee upon stake creation and rollover. No fee is
 * charged upon the ending of a stake. Parameters that determine stake principal
 * are always fixed, fees are charged on top of the set stake principal /
 * rollover amount.
 *
 * Any tokens that need to be used for any operation like paying fees, creating
 * stakes and rolling over stakes must be part of the free balance i.e. transferred
 * to the contract in advance. For contract addresses this can simply be done by
 * transferring tokens prior to the desired call. For EOAs (common non-smart
 * user wallets) safe stake creation is achieved by prefixing the desired call
 * with a call to the `pull` method. Calls can be batched via the `multicall`,
 * `feeCappedMulticall`, 'expiringMulticall' or `feeCappedExpiringMulticall`
 * methods
 *
 * Similarly after a stake is ended for example, the stake proceeds are returned
 * to this contract and added to its free balance. To withdraw this contract's
 * free balance any "push" method may be utilized (`pushAll`, `pushAllTo`,
 * `push` or `pushTo`). For EOAs this can be done atomically (in a single
 * transaction) by batching calls through a multicall method.
 */
contract CrispyStaker is ERC721, DualFeeTaker, ICrispyStaker {
    using TwoWayMapping for TwoWayMapping.UintToUint;

    // timestamp when hex day 0 started (0-indexed) = 3rd December 2019, 0:00 UTC+0
    uint256 internal constant HEX_DAY0_START = 1575331200;

    // offset for first token id, used to skip `0` to better detect unset key value pairs
    uint256 internal constant FIRST_TOKEN_ID = 1;

    // view {ICrispyStaker-nextTokenId}
    uint256 public nextTokenId;

    // view {ICrispyStaker-currentBaseURI}
    string public currentBaseURI;

    // view {ICrispyStaker-contractURI}
    string public contractURI;

    /**
     * Hex keeps track of stakes by owner address and stake index. When a stake
     * gets closed the last stake is used to replace the removed stake:
     * [1, 2, 3, 4, 5] (close 2) => [1, 5, 3, 4]
     *
     * this is why `_tokenIdToStakeIndex` needs to be a two way mapping because
     * without a reverse map there'd be no way of efficiently getting the "last"
     * token ID by stake index
     *
     * The Hex contract does have a unique `stakeId` for every stake which could
     * be tied to the token and the `stakeIndex` could just be querried client
     * side and passed as a parameter to save on required storage slots updates.
     * This approach was however not chosen as it could lead to transactions
     * reverting if a previous transaction rearanges stake indices by the time a
     * user's transaction gets mined.
     *
     * By tracking the stake indices contract-side it is ensured that a user
     * can always end their stakes without worrying about transaction order
     * dependence
     */
    TwoWayMapping.UintToUint internal _tokenIdToStakeIndex;

    constructor(
        string memory _name,
        string memory _symbol,
        address _hexToken,
        uint256 _startMaxFee,
        uint256 _startCreateFee,
        uint256 _startRolloverFee,
        string memory _contractURI
    )
        ERC721(_name, _symbol)
        DualFeeTaker(_hexToken, _startMaxFee, _startCreateFee, _startRolloverFee)
    {
        // skips token `0` so that it's easy to detect not-set keys in two-way
        // mapping
        nextTokenId = FIRST_TOKEN_ID;
        contractURI = _contractURI;
    }

    /**
     * @dev see {ICrispyStaker-setBaseURI}
     */
    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        currentBaseURI = _newBaseURI;
    }

    /**
     * @dev see {ICrispyStaker-setContractURI}
     */
    function setContractURI(string calldata _contractURI) external onlyOwner {
        contractURI = _contractURI;
    }

    /**
     * @dev see {ICrispyStaker-createStakes}
     */
    function createStakes(
        uint256 _referenceTimestamp,
        uint256[] calldata _stakeAmounts,
        uint256[] calldata _stakeDays
    ) external returns (uint256, uint256) {
        return
            _createStakesFor(
                msg.sender,
                _stakeAmounts,
                _stakeDays,
                _getDaysSince(_referenceTimestamp)
            );
    }

    /**
     * @dev see {ICrispyStaker-createStakesFor}
     */
    function createStakesFor(
        address _recipient,
        uint256 _referenceTimestamp,
        uint256[] calldata _stakeAmounts,
        uint256[] calldata _stakeDays
    ) external returns (uint256, uint256) {
        return
            _createStakesFor(
                _recipient,
                _stakeAmounts,
                _stakeDays,
                _getDaysSince(_referenceTimestamp)
            );
    }

    /**
     * @dev see {ICrispyStaker-createStake}
     */
    function createStake(
        uint256 _referenceTimestamp,
        uint256 _amount,
        uint256 _stakeDays
    ) external returns (uint256) {
        return
            _createStakeFor(msg.sender, _amount, _stakeDays - _getDaysSince(_referenceTimestamp));
    }

    /**
     * @dev see {ICrispyStaker-createStakeFor}
     */
    function createStakeFor(
        address _recipient,
        uint256 _referenceTimestamp,
        uint256 _amount,
        uint256 _stakeDays
    ) external returns (uint256) {
        return
            _createStakeFor(_recipient, _amount, _stakeDays - _getDaysSince(_referenceTimestamp));
    }

    /**
     * @dev see {ICrispyStaker-unstakeMany}
     */
    function unstakeMany(uint256[] calldata _tokenIds) external {
        uint256 lastStakeIndex = hexToken().stakeCount(address(this)) - 1;
        for (uint256 i; i < _tokenIds.length; i++) {
            _redeemToken(_tokenIds[i], lastStakeIndex - i);
        }
    }

    function unstake(uint256 _tokenId) external {
        _redeemToken(_tokenId, hexToken().stakeCount(address(this)) - 1);
    }

    /**
     * @dev see {ICrispyStaker-rolloverStake}
     */
    function rolloverStake(
        uint256 _tokenId,
        uint256 _referenceTimestamp,
        uint256 _newStakeAmount,
        uint256 _newStakeDays
    ) external {
        _rolloverStake(
            _tokenId,
            _newStakeAmount,
            _newStakeDays - _getDaysSince(_referenceTimestamp)
        );
    }

    /**
     * @dev see {ICrispyStaker-hexToken}
     */
    function hexToken() public view returns (IHex) {
        return IHex(address(mainSkimmable));
    }

    /**
     * @dev see {ICrispyStaker-getTotalIssuedTokens}
     */
    function getTotalIssuedTokens() public view returns (uint256) {
        return nextTokenId - FIRST_TOKEN_ID;
    }

    /**
     * @dev see {ICrispyStaker-getStakeFromToken}
     */
    function getStakeFromToken(uint256 _tokenId)
        public
        view
        returns (
            uint256 stakeIndex,
            uint40 stakeId,
            uint72 stakedHearts,
            uint72 stakeShares,
            uint16 lockedDay,
            uint16 stakedDays,
            uint16 unlockedDay
        )
    {
        require(_exists(_tokenId), "CrSt: Nonexistent token");
        return _getStakeFromToken(_tokenId);
    }

    /**
     * @dev see {ICrispyStaker-getTokenId}
     */
    function getTokenId(uint256 _stakeIndex) public view returns (uint256) {
        uint256 tokenId = _tokenIdToStakeIndex.rget(_stakeIndex);
        require(tokenId >= FIRST_TOKEN_ID, "CrSt: Nonexistent stake");
        return tokenId;
    }

    /**
     * @dev efficiently creates multiple stakes within a single call, added
     * despite multicall as additional optimizations can be added when batching
     * stake creation
     * @param _recipient the recipient of the new crispy stakes
     * @param _stakeAmounts array of underlying stake principals after fees
     * @param _stakeDays array of stake durations in days
     * @param _dayOffset offset by which to decrease all the stake durations
     * @return first token ID in the list of newly created stake tokens
     * @return amount of newly created tokens, equal to the length of the two
     * array parameters
     */
    function _createStakesFor(
        address _recipient,
        uint256[] memory _stakeAmounts,
        uint256[] memory _stakeDays,
        uint256 _dayOffset
    ) internal returns (uint256, uint256) {
        uint256 stakeAmountsLength = _stakeAmounts.length;
        require(stakeAmountsLength == _stakeDays.length, "CrSt: Input length mismatch");
        // store running total of principal used to determine fee to be paid
        uint256 realTotal;
        // cache the `nextTokenId` and `nextStakeIndex` values to minimize
        // necessary SSTORE and CALL operations
        uint256 nextTokenId_ = nextTokenId;
        uint256 firstStakeIndex = hexToken().stakeCount(address(this));
        for (uint256 i; i < stakeAmountsLength; i++) {
            uint256 stakeAmount = _stakeAmounts[i];
            realTotal += stakeAmount;
            _issueNewTokenFor(
                _recipient,
                stakeAmount,
                _stakeDays[i] - _dayOffset,
                nextTokenId_ + i,
                firstStakeIndex + i
            );
        }
        nextTokenId = nextTokenId_ + stakeAmountsLength;
        _taxCheckUsedAmount(createFee, realTotal);
        return (nextTokenId_, stakeAmountsLength);
    }

    /**
     * @dev creates a single crispy stake for the `_recipient`
     * @param _amount principal of the new underlying stake after fees
     * @param _stakeDays the duration of the underlying stake
     * @return the ID of the new stake token
     */
    function _createStakeFor(
        address _recipient,
        uint256 _amount,
        uint256 _stakeDays
    ) internal returns (uint256) {
        uint256 newTokenId = nextTokenId++;
        _issueNewTokenFor(
            _recipient,
            _amount,
            _stakeDays,
            newTokenId,
            hexToken().stakeCount(address(this))
        );
        _taxCheckUsedAmount(createFee, _amount);
        return newTokenId;
    }

    /**
     * @dev rolls over an existing stake, essentially ending and starting an
     * underlying stake while retaining the crispy stake token ID
     * @param _tokenId stake to be rolled over
     * @param _newStakeAmount principal of the new underlying stake after fees
     * @param _newStakeDays the duration of the new underlying stake
     */
    function _rolloverStake(
        uint256 _tokenId,
        uint256 _newStakeAmount,
        uint256 _newStakeDays
    ) internal {
        uint256 lastStakeIndex = hexToken().stakeCount(address(this)) - 1;
        _closeStake(_tokenId, lastStakeIndex, true);
        _openStake(_newStakeAmount, _newStakeDays, _tokenId, lastStakeIndex);
        _taxCheckUsedAmount(rolloverFee, _newStakeAmount);
        emit StakeRollover(_tokenId);
    }

    /**
     * @dev responsible for creating the underlying stake and issuing the
     * connected token
     * @param _recipient the address to receive the new stake token
     * @param _stakeAmount the principal of the underlying stake
     * @param _stakeDays the duration in the days of the underlying stake
     * @param _newTokenId the token ID to be assigned to the stake token
     * @param _newStakeIndex the index the underlying stake will receive in the
     * hex contract
     */
    function _issueNewTokenFor(
        address _recipient,
        uint256 _stakeAmount,
        uint256 _stakeDays,
        uint256 _newTokenId,
        uint256 _newStakeIndex
    ) internal {
        _openStake(_stakeAmount, _stakeDays, _newTokenId, _newStakeIndex);
        _mint(_recipient, _newTokenId);
    }

    /**
     * @dev creates the underlying stake and connects the token ID to the
     * underlying stake index of the new stake
     * @param _stakeAmount the principal of the underlying stake
     * @param _stakeDays the duration in the days of the underlying stake
     * @param _tokenId the token ID to be assigned to the stake token
     * @param _newStakeIndex the index the underlying stake will receive in the
     */
    function _openStake(
        uint256 _stakeAmount,
        uint256 _stakeDays,
        uint256 _tokenId,
        uint256 _newStakeIndex
    ) internal {
        // couple token ID to its underlying stake index for future reference
        _tokenIdToStakeIndex.set(_tokenId, _newStakeIndex);
        hexToken().stakeStart(_stakeAmount, _stakeDays);
        // extra hook for testing purposes
        _registerOpenStake(_tokenId, _newStakeIndex);
    }

    /**
     * @dev ends a stake, burning the associated stake token
     * @param _tokenId ID of the token to be burnt
     * @param _lastStakeIndex the last stake index of the contract's underlying
     * hex stakes
     */
    function _redeemToken(uint256 _tokenId, uint256 _lastStakeIndex) internal {
        _closeStake(_tokenId, _lastStakeIndex, false);
        _burn(_tokenId);
    }

    /**
     * @dev closes an underlying stake rearranging the tokenID <-> stake index
     * map, reverts if being closed for a rollover and stake is not mature, also
     * verifies the `msg.sender` is authorized to use the specified token
     * @param _tokenId the ID of the token for which the stake is being closed
     * @param _lastStakeIndex the last stake index of the contract's underlying
     * hex stakes
     * @param _isRollover whether the underlying stake is being closed for the
     * purpose of a rollover
     */
    function _closeStake(
        uint256 _tokenId,
        uint256 _lastStakeIndex,
        bool _isRollover
    ) internal {
        _authenticateToken(_tokenId);
        (
            uint256 stakeIndex,
            uint40 stakeId,
            ,
            ,
            uint256 lockedDay,
            uint256 stakedDays,

        ) = _getStakeFromToken(_tokenId);
        // TESTING: additional consistency checks, not added in production due
        // to gas usage
        _closeStakeCheck(_tokenId, stakeIndex, stakeId);
        if (_isRollover) {
            // check whether the stake is mature i.e. ready to be unstaked
            require(
                lockedDay + stakedDays <= _getDaysSince(HEX_DAY0_START),
                "CrSt: Early rollover disallowed"
            );
        }
        hexToken().stakeEnd(stakeIndex, stakeId);
        if (stakeIndex != _lastStakeIndex) {
            // get last stake token as it will receive the stake index of the
            // stake that is being closed
            uint256 topTokenId = _tokenIdToStakeIndex.rget(_lastStakeIndex);
            // update mapping and zero out unused keys for gas refund
            _tokenIdToStakeIndex.replace(topTokenId, stakeIndex, _tokenId, _lastStakeIndex);
            // TESTING: verify rearange is correct
            _verifyStakeConnection(topTokenId, stakeIndex);
        }
    }

    /**
     * @dev retrieves the information of the underlying stake belonging to the
     * stake with an ID of `_tokenId`
     * @param _tokenId ID of the token for which to query the underlying stake
     */
    function _getStakeFromToken(uint256 _tokenId)
        internal
        view
        returns (
            uint256 stakeIndex,
            uint40 stakeId,
            uint72 stakedHearts,
            uint72 stakeShares,
            uint16 lockedDay,
            uint16 stakedDays,
            uint16 unlockedDay
        )
    {
        stakeIndex = _tokenIdToStakeIndex.get(_tokenId);
        (stakeId, stakedHearts, stakeShares, lockedDay, stakedDays, unlockedDay, ) = hexToken()
            .stakeLists(address(this), stakeIndex);
    }

    /**
     * @dev get the amount of days past a certain reference timestamp, returns
     * `0` if the `_referenceTimestamp` is `0`
     * @param _referenceTimestamp the reference timestamp
     */
    function _getDaysSince(uint256 _referenceTimestamp) internal view returns (uint256) {
        if (_referenceTimestamp == 0) return 0;
        return (block.timestamp - _referenceTimestamp) / 1 days;
    }

    /**
     * @dev checks whether the `msg.sender` is approved or the owner of
     * `_tokenId`
     * @param _tokenId ID of the stake token to be authenticated
     */
    function _authenticateToken(uint256 _tokenId) internal view {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "CrSt: Caller not approved");
    }

    /**
     * @dev return the baseURI for the `ERC721.tokenURI` method
     */
    function _baseURI() internal view override returns (string memory) {
        return currentBaseURI;
    }

    // stake hooks, only implemented in test child contract `TestCrispyStaker`

    function _registerOpenStake(uint256, uint256) internal virtual {}

    function _closeStakeCheck(
        uint256,
        uint256,
        uint256
    ) internal virtual {}

    function _verifyStakeConnection(uint256, uint256) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.9;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {FixedMath} from "../lib/maths/FixedMath.sol";
import {FeeMath} from "../lib/maths/FeeMath.sol";
import {SimpleSkimmableERC20} from "../lib/SimpleSkimmableERC20.sol";
import {IDualFeeTaker} from "./interfaces/IDualFeeTaker.sol";

/**
 * @author Dumonet Distributed Technologies
 * @dev free balance accounting based fee taking contract. Uses the held balance
 * as the fee reservoir. Tracks a creation and rollover fee to be able to tax
 * the two actions differently.
 *
 * Fees are fixed point decimal numbers where a 100% fee is represented by the
 * `FixedMath.ONE` constant
 */
abstract contract DualFeeTaker is SimpleSkimmableERC20, Ownable, IDualFeeTaker {
    using FeeMath for uint256;

    bool internal inNoFeeContext;
    uint256 internal maxFee;
    uint128 internal createFee;
    uint128 internal rolloverFee;

    constructor(
        address _mainToken,
        uint256 _startMaxFee,
        uint256 _startCreateFee,
        uint256 _startRolloverFee
    ) SimpleSkimmableERC20(_mainToken) Ownable() {
        require(_startMaxFee <= FixedMath.ONE, "DFeeTaker: Max fee above 100%");
        require(_startCreateFee <= _startMaxFee, "DFeeTaker: Stake fee above max");
        require(_startRolloverFee <= _startMaxFee, "DFeeTaker: Roll. fee above max");
        _setMaxFee(_startMaxFee);
        _setCreateFee(_startCreateFee);
        _setRolloverFee(_startRolloverFee);
    }

    /**
     * @dev check whether a certain fee value (`_fee`) exceeds the contract's
     * current maximum fee `maxFee` and whether a fee is being changed within a
     * `noFeeCall`
     * @param _fee the fee that should be atmost the maximum fee `maxFee`
     */
    modifier changesAFeeTo(uint256 _fee) {
        require(_fee <= maxFee, "DFeeTaker: Fee above max");
        require(!inNoFeeContext, "DFeeTaker: Fee change in no fee");
        _;
    }

    /**
     * @dev check whether the create and rollover fee are within the expected
     * range of `0` up to the `_max{Create/Rollover}Fee`
     * @param _maxCreateFee the maximum create fee that the contract should have
     * @param _maxRolloverFee the maximum rollover fee that the contract should have
     */
    modifier feesAtMost(uint256 _maxCreateFee, uint256 _maxRolloverFee) {
        (uint256 currentCreateFee, uint256 currentRolloverFee) = getFees();
        require(_maxCreateFee >= currentCreateFee, "DFeeTaker: Create fee too high");
        require(_maxRolloverFee >= currentRolloverFee, "DFeeTaker: Rollover fee too high");
        _;
    }

    /**
     * @dev see {IDualFeeTaker-feeCappedMulticall}
     */
    function feeCappedMulticall(
        uint256 _maxCreateFee,
        uint256 _maxRolloverFee,
        bytes[] calldata _data
    ) external feesAtMost(_maxCreateFee, _maxRolloverFee) returns (bytes[] memory) {
        return multicall(_data);
    }

    /**
     * @dev see {IDualFeeTaker-feeCappedExpiringMulticall}
     */
    function feeCappedExpiringMulticall(
        uint256 _expireAfter,
        uint256 _maxCreateFee,
        uint256 _maxRolloverFee,
        bytes[] calldata _data
    )
        external
        expireAfter(_expireAfter)
        feesAtMost(_maxCreateFee, _maxRolloverFee)
        returns (bytes[] memory)
    {
        return multicall(_data);
    }

    /**
     * @dev see {IDualFeeTaker-noFeeCall}
     */
    function noFeeCall(bytes calldata _data) external onlyOwner returns (bytes memory result) {
        (uint256 createFeeBefore, uint256 rolloverFeeBefore) = getFees();
        createFee = 0;
        rolloverFee = 0;
        inNoFeeContext = true;
        result = _selfCall(_data);
        inNoFeeContext = false;
        createFee = uint128(createFeeBefore);
        rolloverFee = uint128(rolloverFeeBefore);
    }

    /**
     * @dev see {IDualFeeTaker-setMaxFee}
     */
    function setMaxFee(uint256 _newMaxFee) external onlyOwner changesAFeeTo(_newMaxFee) {
        if (maxFee == _newMaxFee) return;
        _setMaxFee(_newMaxFee);
        (uint256 currentCreateFee, uint256 currentRolloverFee) = getFees();
        if (currentCreateFee > _newMaxFee) _setCreateFee(_newMaxFee);
        if (currentRolloverFee > _newMaxFee) _setRolloverFee(_newMaxFee);
    }

    /**
     * @dev see {IDualFeeTaker-setCreateFee}
     */
    function setCreateFee(uint256 _newCreateFee) external onlyOwner changesAFeeTo(_newCreateFee) {
        if (createFee == _newCreateFee) return;
        _setCreateFee(_newCreateFee);
    }

    /**
     * @dev see {IDualFeeTaker-setRolloverFee}
     */
    function setRolloverFee(uint256 _newRolloverFee)
        external
        onlyOwner
        changesAFeeTo(_newRolloverFee)
    {
        if (rolloverFee == _newRolloverFee) return;
        _setRolloverFee(_newRolloverFee);
    }

    /**
     * @dev see {IDualFeeTaker-withdrawFees}
     */
    function withdrawFees(uint256 _feeAmount) external onlyOwner {
        _withdraw(_feeAmount);
    }

    /**
     * @dev see {IDualFeeTaker-withdrawAllFees}
     */
    function withdrawAllFees() external onlyOwner {
        _withdrawAll();
    }

    /**
     * @dev see {IDualFeeTaker-getFees}
     */
    function getFees() public view returns (uint256 currentCreateFee, uint256 currentRolloverFee) {
        currentCreateFee = createFee;
        currentRolloverFee = rolloverFee;
    }

    function getMaxFee() external view returns (uint256) {
        return maxFee;
    }

    function getAccruedFees() external view returns (uint256) {
        return _getHeldBalance();
    }

    /**
     * @dev takes fee required to cover use of `_amount` in some taxed
     * transaction. Reverts if there's insufficient free balance to cover the
     * fee or if the free balance has become negative
     * @param _fee fee to be used for taxation of amount
     * @param _amount amount used by some address for a transaction the contract
     * wants to tax (stake creation or rollover)
     */
    function _taxCheckUsedAmount(uint256 _fee, uint256 _amount) internal {
        if (_fee == 0) {
            _checkHeldBalance();
            return;
        }
        uint256 feeAmount = _fee.getCutToAdd(_amount);
        _deposit(feeAmount);
        emit FeeTaken(feeAmount);
    }

    function _setMaxFee(uint256 _maxFee) private {
        maxFee = _maxFee;
        emit MaxFeeSet(_maxFee);
    }

    function _setCreateFee(uint256 _newStartFee) private {
        createFee = uint128(_newStartFee);
        emit CreateFeeSet(_newStartFee);
    }

    function _setRolloverFee(uint256 _newRolloverFee) private {
        rolloverFee = uint128(_newRolloverFee);
        emit RolloverFeeSet(_newRolloverFee);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity =0.8.9;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

// Hex interface

/*
// actual structs as a reference
struct StakeStore {
    uint40 stakeId;
    uint72 stakedHearts;
    uint72 stakeShares;
    uint16 lockedDay;
    uint16 stakedDays;
    uint16 unlockedDay;
    bool isAutoStake;
}

struct GlobalsStore {
    // 1
    uint72 lockedHeartsTotal;
    uint72 nextStakeSharesTotal;
    uint40 shareRate;
    uint72 stakePenaltyTotal;
    // 2
    uint16 dailyDataCount;
    uint72 stakeSharesTotal;
    uint40 latestStakeId;
    uint128 claimStats;
}
*/

/**
 * @dev recreated interface of main Hex token contract methods
 * @author Dumonet Distributed Technologies
 */
interface IHex is IERC20Metadata {
    event StakeStart(uint256 data0, address indexed stakerAddr, uint40 indexed stakeId);

    event StakeGoodAccounting(
        uint256 data0,
        uint256 data1,
        address indexed stakerAddr,
        uint40 indexed stakeId,
        address indexed senderAddr
    );

    event StakeEnd(
        uint256 data0,
        uint256 data1,
        address indexed stakerAddr,
        uint40 indexed stakeId
    );

    function stakeStart(uint256 newStakedHearts, uint256 newStakedDays) external;

    function stakeEnd(uint256 stakeIndex, uint40 stakeIdParam) external;

    function stakeGoodAccounting(
        address stakerAddr,
        uint256 stakeIndex,
        uint40 stakeIdParam
    ) external;

    // mapping(address => StakeStore[]) public stakeLists;
    function stakeLists(address owner, uint256 index)
        external
        view
        returns (
            uint40 stakeId,
            uint72 stakedHearts,
            uint72 stakeShares,
            uint16 lockedDay,
            uint16 stakedDays,
            uint16 unlockedDay,
            bool isAutoStake
        );

    // GlobalsStore public globals;
    function globals()
        external
        view
        returns (
            uint72 lockedHeartsTotal,
            uint72 nextStakeSharesTotal,
            uint40 shareRate,
            uint72 stakePenaltyTotal,
            uint16 dailyDataCount,
            uint72 stakeSharesTotal,
            uint40 latestStakeId,
            uint128 claimStats
        );

    function stakeCount(address stakerAddr) external view returns (uint256);

    function currentDay() external view returns (uint256);

    function dailyData(uint256 day)
        external
        view
        returns (
            uint72 dayPayoutTotal,
            uint72 dayStakeSharesTotal,
            uint56 dayUnclaimedSatoshisTotal
        );

    function dailyDataRange(uint256 beginDay, uint256 endDay)
        external
        view
        returns (uint256[] memory list);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.9;

/**
 * @author Dumonet Distributed Technologies
 * @dev library for a simple two-way mapping, a mapping where each key
 * retrieves a unique value but every value is also linked to a unique key
 */
library TwoWayMapping {
    struct UintToUint {
        mapping(uint256 => uint256) fromTo;
        mapping(uint256 => uint256) toFrom;
    }

    /**
     * @dev link 2 values as a pair in the two way mapping
     * @param _map two way map for which to store pair
     * @param _key the main key, used to access `_value` via the `get()` method
     * @param _value the main value, can be used to access the `_key` via the
     * `rget()` method
     */
    function set(
        UintToUint storage _map,
        uint256 _key,
        uint256 _value
    ) internal {
        _map.fromTo[_key] = _value;
        _map.toFrom[_value] = _key;
    }

    /**
     * @dev links a key and value similar to `set` but attempts to leverage
     * SSTORE gas refunds by resetting unused keys. Also keeps two way mapping
     * consistent:
     *
     * ## Before set / replace:
     *
     * fromTo map         toFrom map
     *  k1 -> v1           v1 -> k1
     *  k2 -> v2           v2 -> k2
     *  k3 -> v3           v3 -> k3
     *
     * ## After `set(k1, v3)` (<changed>, [inconsistent])
     *
     * fromTo map         toFrom map
     * <k1 -> v3>         [v1 -> k1]
     *  k2 -> v2           v2 -> k2
     * [k3 -> v3]         <v3 -> k1>
     *
     * Note that since k1 and v3 were already in the mapping simply setting is
     * straightforward but leaves inconsistent entries marked with "[]"
     *
     * ## After `replace(k1, v3, k3, v1)`
     *
     * fromTo map         toFrom map
     * <k1 -> v3>          v1 ->  0
     *  k2 -> v2           v2 -> k2
     *  k3 ->  0          <v3 -> k1>
     *
     * relation restored to default
     *
     * @param _map map to be affected
     * @param _key key to be connected to value
     * @param _value value to be connected to value
     * @param _oldKey key which used to pointed to `_value`
     * @param _oldValue value which used to be pointed to by `_key`
     */
    function replace(
        UintToUint storage _map,
        uint256 _key,
        uint256 _value,
        uint256 _oldKey,
        uint256 _oldValue
    ) internal {
        set(_map, _key, _value);
        delete _map.fromTo[_oldKey];
        delete _map.toFrom[_oldValue];
    }

    /**
     * @dev do a forward get on the mapping, fetches value using key
     * @param _map two way map from which to retrieve value
     * @param _key forward key to access value
     * @return value defaults to 0 if not set
     */
    function get(UintToUint storage _map, uint256 _key) internal view returns (uint256) {
        return _map.fromTo[_key];
    }

    /**
     * @dev do a backwards get on the mapping or reverse get ("rget"), find
     * which key maps to a specific value.
     * NOTE: Being mapped to from the `0` key is indistinguishable from not
     * being mapped to at all.
     * @param _map two way map from which to retrieve key
     * @param _value backwards key for reverse get
     * @return key defaults to 0 if not set
     */
    function rget(UintToUint storage _map, uint256 _value) internal view returns (uint256) {
        return _map.toFrom[_value];
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity =0.8.9;

import {IDualFeeTaker} from "./IDualFeeTaker.sol";
import {IHex} from "../../lib/interfaces/IHex.sol";

/**
 * @author Dumonet Distributed Technologies
 */
interface ICrispyStaker is IDualFeeTaker {
    /**
     * announce when stake is rolled over, stake creation and ending can be
     * tracked via the `ERC721.Transfer` events from and to the zero address
     */
    event StakeRollover(uint256 indexed tokenId);

    // token ID to be assinged to next minted stake token
    function nextTokenId() external view returns (uint256);

    // metadata URI for tokens
    function currentBaseURI() external view returns (string memory);

    /**
     * @dev contract URI to display contract wide metadata and royalty
     * information for opensea
     */
    function contractURI() external view returns (string memory);

    /**
     * @dev allows owner to update the metadata base URI. Only used to display
     * metadata so it's ok for the owner to be able to arbitrarily change as
     * the underlying value remains unchanged
     */
    function setBaseURI(string calldata _newBaseURI) external;

    /**
     * @dev allows owner to update the contract URI
     */
    function setContractURI(string calldata _contractURI) external;

    /**
     * @dev
     *
     * create a batch of stakes for the `msg.sender`, reducing the stake
     * duration by the amount of days that have passed since the
     * `_referenceTimestamp`. Useful for creating stakes that end at a
     * particular date regardless when the transaction is mined.
     *
     * The shift is rounded down to the nearest day e.g. if mined 23h and
     * 59mins after the reference timestamp the lengths are not adjusted.
     * Reverts if the `_referenceTimestamp` is in the future upon submission. If
     * the `_referenceTimestamp` is set to `0` the stake lengths are not
     * adjusted regardless of when the transaction gets minted.
     *
     * Uses the free balance to cover the stake amount and fee. Any fees are
     * added to the stake amounts e.g. 3 stakes are being created totaling 98k
     * HEX and the fee is 2% then the fee will total 2k HEX and the transaction
     * will require 100k HEX of free balance to not revert
     *
     * NOTE: The stake tokens are issued directly the `msg.sender` **without**
     * doing a `onERC721Received` check on contract recipients, if calling
     * from a contract be sure that your contract can transfer ERC721 tokens
     *
     * @param _referenceTimestamp the reference timestamp
     * @param _stakeAmounts stake principals array of the individual stakes
     * @param _stakeDays array of original stake durations in days
     * @return first token ID in the list of newly created stake tokens
     * @return amount of newly created tokens, equals the length of the two
     * array parameters
     */
    function createStakes(
        uint256 _referenceTimestamp,
        uint256[] calldata _stakeAmounts,
        uint256[] calldata _stakeDays
    ) external returns (uint256, uint256);

    /**
     * @dev creates a batch of stakes with the exact same mechanics as
     * `createRelativeStakes` except that the stake tokens get issued to the
     * `_recipient` instead of `msg.sender`
     * @param _recipient adress to receive the stake tokens
     * @param _referenceTimestamp the reference timestamp
     * @param _stakeAmounts stake principals array of the individual stakes
     * @param _stakeDays array of original stake durations in days
     * @return first token ID in the list of newly created stake tokens
     * @return amount of newly created tokens, equals the length of the two
     * array parameters
     */
    function createStakesFor(
        address _recipient,
        uint256 _referenceTimestamp,
        uint256[] calldata _stakeAmounts,
        uint256[] calldata _stakeDays
    ) external returns (uint256, uint256);

    /**
     * @dev creates a single stake for the `msg.sender` shifting the stake
     * duration like in `createStakeFor` and `createStakes` based on the
     * provided `_referenceTimestamp`.
     * @param _referenceTimestamp the reference timestamp
     * @param _amount the stake principal, same fee rules apply as with the
     * batch stake creation methods
     * @param _stakeDays the base stake duration in days
     * @return created stake token ID
     */
    function createStake(
        uint256 _referenceTimestamp,
        uint256 _amount,
        uint256 _stakeDays
    ) external returns (uint256);

    /**
     * @dev similar to `createRelativeStake` except that the stake is minted to
     * the `_recipient` instead of `msg.sender`
     * @param _recipient address to receive the stake
     * @param _referenceTimestamp reference timestamp
     * @param _amount the stake principal
     * @param _stakeDays the base stake duration in days
     * @return created stake token ID
     */
    function createStakeFor(
        address _recipient,
        uint256 _referenceTimestamp,
        uint256 _amount,
        uint256 _stakeDays
    ) external returns (uint256);

    /**
     * @dev ends a list of stakes, adds proceeds to the contract's free balance,
     * requires the `msg.sender` to either be the owner or an approved operator
     * for each of the tokens
     * @param _tokenIds a list of stake token IDs the `msg.sender` wants to end
     */
    function unstakeMany(uint256[] calldata _tokenIds) external;

    /**
     * @dev ends a single stake, similar to `unstakeMany` adds stake proceeds to
     * free balance and requires `msg.sender` to be an approved operator or the
     * owner of the stake token
     * @param _tokenId stake token ID of stake to be ended
     */
    function unstake(uint256 _tokenId) external;

    /**
     * @dev allows a stake to be "extended" or "rolled over"
     *
     * Crispy stakes are rolled over by ending and starting underlying Hex
     * Stakes. While this is technically equivalent to simply ending and
     * starting stakes the `tokenId` of the Crispy stake is not changed.
     *
     * Such a rollover may not only saves gas but **may** also make the earned
     * interest exempt from taxation in certain jurisdictions and
     * interpretations of tax codes as the interest never directly goes to the
     * user but is instead kept as a stake. Note that this comment should by
     * no means be interpreted as a guarantee of any kind but merely a
     * suggestion at a possibility, please consult a tax advisor or regulator
     * in your jurisdiction for binding advise.
     *
     * By batching and combining rollovers with other rollovers or other create
     * operations stakes can also be rebalanced, forked or coalesced.
     *
     * The rollover fee is charged upon rollover, this is done similarly to how
     * the fee is charged for stake creation, on top of the rolled over amount
     *
     * @param _tokenId stake to be rolled over
     * @param _referenceTimestamp the timestamp relative to which the new
     * remaining stake duration should be shifted. Set to `0` for no shifting
     * @param _newStakeAmount principal of new underlying stake
     * @param _newStakeDays the remaining duration of the stake after being
     * rolled over
     */
    function rolloverStake(
        uint256 _tokenId,
        uint256 _referenceTimestamp,
        uint256 _newStakeAmount,
        uint256 _newStakeDays
    ) external;

    /**
     * @dev cast the stored token to the `IHex` interface
     * @return address of Hex contract this contract interacts with
     */
    function hexToken() external view returns (IHex);

    /**
     * @dev returns amount of stake tokens that have historically ever been
     * issued
     * @return total amount issued
     */
    function getTotalIssuedTokens() external view returns (uint256);

    /**
     * @dev returns the full stake data for a given stake token, should revert
     * if the token does not exist. Hex's `isAutoStake` property is omitted as
     * all crispy stakes will not be auto stakes
     * @param _tokenId the token ID of the stake token
     * @return stakeIndex the current stake index of the token, subject to change
     * throughout the life of the stake
     * @return stakeId the current universal stake id of the underlying stake,
     * will change on stake rollover
     * @return stakedHearts the current stake principal, will include some
     * interest if the stake has been rolled over
     * @return stakeShares the current shares that the stake holds
     * @return lockedDay the hex day (0-indexed) where the stake began
     * @return stakedDays the duration of the stake in days
     * @return unlockedDay the day at which the stake was unlocked using good
     * accounting, 0 if not accounted yet
     */
    function getStakeFromToken(uint256 _tokenId)
        external
        view
        returns (
            uint256 stakeIndex,
            uint40 stakeId,
            uint72 stakedHearts,
            uint72 stakeShares,
            uint16 lockedDay,
            uint16 stakedDays,
            uint16 unlockedDay
        );

    /**
     * @dev returns the token ID to which the `_stakeIndex` is linked in the
     * contract's stake list
     * @param _stakeIndex index of the stake
     * @return the token ID of the stake token
     */
    function getTokenId(uint256 _stakeIndex) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.9;

/**
 * @title A library for doing fixed point maths in solidity
 * @author Dumonet Distributed Technologies
 */
library FixedMath {
    uint256 internal constant ONE = 1e18;

    /**
     * @dev divide a number by a decimal fixed point number
     */
    function fdiv(uint256 _x, uint256 _y) internal pure returns (uint256) {
        return (_x * ONE) / _y;
    }

    /**
     * @dev multiply a number by a decimal fixed point number
     */
    function fmul(uint256 _x, uint256 _y) internal pure returns (uint256) {
        return (_x * _y) / ONE;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.9;

import "./FixedMath.sol";

/**
 * @title A library for doing fee and cut related math
 * @author Dumonet Distributed Technologies
 */
library FeeMath {
    using FixedMath for uint256;

    /**
     * @dev calculate the fee to take such that the (taken fee) / (taken fee +
     * total) = (fee); expressed algebraically: k / (k + x) = f => k = (x * f) / (1 - f)
     * @param _fee (f) the fee percentage as fixed point number
     * @param _total (x) amount on which fee is to be added
     * @return fee amount (k) to be taken
     */
    function getCutToAdd(uint256 _fee, uint256 _total) internal pure returns (uint256) {
        if (_fee == 0) return 0;
        uint256 feeToAdd = (_total * _fee) / (FixedMath.ONE - _fee);
        return feeToAdd;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeMulticall} from "./SafeMulticall.sol";

/**

# Free Balance Accounting

* methods which want to use tokens do not directly pull them from wallets
* methods which want to return tokens do not directly transfer them
* methods may use tokens by depleting the contract's free balance
* methods may return tokens by increasing the contract's free balance
* the contract's "free balance" is defined as the difference between the
 contract's direct ERC20 balance and the "held balance"
* tokens transferred directly to the contract become part of the "free balance"
* tokens can be held in the contract by increasing the "held balance"
* tokens can be freed from the contract by decreasing the "held balance"

*/

/**
 * @author Dumonet Distributed Technologies
 * @title Base implementation of "free balance accounting"
 * @notice Only to be used with standard ERC20 tokens which also revert on
 * failed transfers
 * @dev Implements basic logic to support "free balance accounting" of a single
 * ERC20 token. Can be used by an EOA directly by using the `multicall` method
 * to combine a call of `pull` method with a call to the target method.
 *
 * NOTE: What is meant by "free balance accounting" is explained in an above
 * comment
 */
abstract contract SimpleSkimmableERC20 is SafeMulticall {
    // main token that is being accounted
    IERC20 internal immutable mainSkimmable;
    uint256 private heldBalance;

    constructor(address _mainSkimmable) {
        mainSkimmable = IERC20(_mainSkimmable);
    }

    /**
     * @dev transfers the entire free balance to the `msg.sender`
     */
    function pushAll() external {
        _pushAllTo(msg.sender);
    }

    /**
     * @dev transfers the entire free balance to the `_recipient`
     */
    function pushAllTo(address _recipient) external {
        _pushAllTo(_recipient);
    }

    /**
     * @dev transfers `_amount` to the `msg.sender`. Reverts if `_amount` is
     * larger than the free balance
     */
    function push(uint256 _amount) external {
        _pushTo(msg.sender, _amount);
    }

    /**
     * @dev transfers `_amount` to the `_recipient`. Reverts if `_amount` is
     * larger than the free balance
     */
    function pushTo(address _recipient, uint256 _amount) external {
        _pushTo(_recipient, _amount);
    }

    /**
     * @dev transfers `_amount` from the `msg.sender` to the contract,
     * effectively adding it to the free balance
     */
    function pull(uint256 _amount) external {
        _pullTo(address(this), _amount);
    }

    /**
     * @dev transfers `_amount` from the `msg.sender` to the `_recipient`
     */
    function pullTo(address _recipient, uint256 _amount) external {
        _pullTo(_recipient, _amount);
    }

    function _pushAllTo(address _recipient) internal {
        uint256 freeBalance = _getFreeBalance();
        if (freeBalance > 0) mainSkimmable.transfer(_recipient, freeBalance);
    }

    function _pushTo(address _recipient, uint256 _amount) internal {
        require(_amount <= _getFreeBalance(), "SSkimmable: Insufficient freebal");
        mainSkimmable.transfer(_recipient, _amount);
    }

    function _pullTo(address _recipient, uint256 _amount) internal {
        mainSkimmable.transferFrom(msg.sender, _recipient, _amount);
    }

    /**
     * @dev increases the held balance by `_amount`, reverts if `_amount` is
     * larger than the free balance
     */
    function _deposit(uint256 _amount) internal {
        uint256 newlyHeldBalance = heldBalance + _amount;
        _checkHeldBalance(newlyHeldBalance);
        heldBalance = newlyHeldBalance;
    }

    /**
     * @dev adds the entirety of the held balance to the free balance, reduces
     * the held balance to 0
     */
    function _withdrawAll() internal {
        heldBalance = 0;
    }

    /**
     * @dev adds `_amount` to the free balance, reduces the held balance by
     * `_amount`. Reverts if the held amount is less than `_amount`
     */
    function _withdraw(uint256 _amount) internal {
        uint256 initialHeldBalance = heldBalance;
        require(initialHeldBalance >= _amount, "SSkimmable: Insufficient held");
        unchecked {
            heldBalance = initialHeldBalance - _amount;
        }
    }

    function _getHeldBalance() internal view returns (uint256) {
        return heldBalance;
    }

    /**
     * @dev reverts if the ERC20 balance does not atleast cover the held
     * balance i.e. reverts if the free balance is negative
     */
    function _checkHeldBalance() internal view {
        _checkHeldBalance(heldBalance);
    }

    /**
     * @dev identical to `_checkHeldBalance()` except that it accepts an
     * arbitrary held balance and checks whether it would cause the free balance
     * to be negative
     */
    function _checkHeldBalance(uint256 _heldBalance) private view {
        require(
            _heldBalance <= mainSkimmable.balanceOf(address(this)),
            "SSkimmable: Insufficient balance"
        );
    }

    function _getFreeBalance() internal view returns (uint256) {
        return mainSkimmable.balanceOf(address(this)) - heldBalance;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity =0.8.9;

import {ISafeMulticall} from "../../lib/interfaces/ISafeMulticall.sol";

/**
 * @author Dumonet Distributed Technologies
 */
interface IDualFeeTaker is ISafeMulticall {
    event MaxFeeSet(uint256 newMaxFee);
    event CreateFeeSet(uint256 createFee);
    event RolloverFeeSet(uint256 rolloverFee);
    event FeeTaken(uint256 takenFee);

    /**
     * @dev similar to `SafeMulticall.multicall` except reverts if certain
     * fee limits are exceeded. Fee maxes can be set to 100% or above to place
     * no cap on a specific fee type
     * @param _maxCreateFee the max create fee above which the call is to be
     * reverted
     * @param _maxRolloverFee the max rollover fee above which the call is to be
     * reverted be for the call to not revert. Can be 100% to "ignore"
     * @param _data see {SafeMulticall-multicall}
     */
    function feeCappedMulticall(
        uint256 _maxCreateFee,
        uint256 _maxRolloverFee,
        bytes[] calldata _data
    ) external returns (bytes[] memory);

    /**
     * @dev similar to `SafeMulticall.multicall` except reverts if either a
     * certain timestamp is exceeded or the fee exceeds an expected maximum
     * @param _expireAfter timestamp at which the call is to be reverted
     * @param _maxCreateFee the max create fee above which the call is to be
     * reverted
     * @param _maxRolloverFee the max rollover fee above which the call is to be
     * reverted be for the call to not revert. Can be 100% to "ignore"
     * @param _data array of calldata for individual calls
     * @return array of raw return data from the individual calls
     */
    function feeCappedExpiringMulticall(
        uint256 _expireAfter,
        uint256 _maxCreateFee,
        uint256 _maxRolloverFee,
        bytes[] calldata _data
    ) external returns (bytes[] memory);

    /**
     * @dev allows owner to use contract without fees, reverts if any fee
     * (create, rollover or max) is changed within the no fee context
     */
    function noFeeCall(bytes calldata _data) external returns (bytes memory);

    /**
     * @dev sets a new maximum for the fees, can't exceed previous maximum
     * @param _newMaxFee the new maximum that fees will no longer be allowed to
     * exceed
     */
    function setMaxFee(uint256 _newMaxFee) external;

    /**
     * @dev sets the create fee, can't exceed fee maximum `maxFee`
     * @param _newCreateFee new fee to be charged upon stake creation
     */
    function setCreateFee(uint256 _newCreateFee) external;

    /**
     * @dev sets the create fee; cannot exceed fee maximum `maxFee`
     * @param _newRolloverFee new fee to be charged upon stake rollover
     */
    function setRolloverFee(uint256 _newRolloverFee) external;

    /**
     * @dev releases collected fees up to `_feeAmount` into the contract's free
     * balance
     * @param _feeAmount fee amount to release
     */
    function withdrawFees(uint256 _feeAmount) external;

    /**
     * @dev similar to `withdrawFees` except that all available fees are released
     */
    function withdrawAllFees() external;

    /**
     * @dev returns the contract's `createFee` and `rolloverFee`
     * @return createFee fee charged for the creation of stakes
     * @return rolloverFee fee charged for the rollover of stakes
     */
    function getFees() external view returns (uint256, uint256);

    function getMaxFee() external view returns (uint256);

    function getAccruedFees() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity =0.8.9;

import {ISafeMulticall} from "./interfaces/ISafeMulticall.sol";

/**
 modified copy of Uniswap's Multicall
 - repo: github.com/Uniswap/v3-periphery
 - commit: 7431d30d8007049a4c9a3027c2e082464cd977e9
 - path: contracts/base/Multicall.sol

 changes:
 - payable removed to prevent accidental use of unsafe `msg.value`
 - process of self calling extracted into isolated `_selfCall` method for reuse
*/

abstract contract SafeMulticall is ISafeMulticall {
    /**
     * @dev reverts method if a certain timestamp has been reached
     */
    modifier expireAfter(uint256 _expireAfter) {
        require(_expireAfter >= block.timestamp, "CrSt: Timestamp passed");
        _;
    }

    /**
     * @dev allows safe batching of any non-payable external calls to the
     * contract
     * @param _data array of encoded calls
     * @return results array of raw functions results, each element
     * corresponds to the result of the call at the same index
     */
    function multicall(bytes[] calldata _data) public returns (bytes[] memory results) {
        results = new bytes[](_data.length);
        for (uint256 i = 0; i < _data.length; i++) {
            results[i] = _selfCall(_data[i]);
        }
    }

    /**
     * @dev similar to `multicall` except reverts if certain timestamp is passed
     * @param _expireAfter timestamp at which the call is to be reverted
     * @param _data array of calldata for individual calls
     * @return array of raw return data from the individual calls
     */
    function expiringMulticall(uint256 _expireAfter, bytes[] calldata _data)
        external
        expireAfter(_expireAfter)
        returns (bytes[] memory)
    {
        return multicall(_data);
    }

    /**
     * @dev trigger a fresh call to the current contract, useful for methods who
     * want to implement some wrapping or context around specific calls
     * @param _data entire calldata to call the contract with, including
     * function selector
     * @return call result
     */
    function _selfCall(bytes memory _data) internal returns (bytes memory) {
        (bool success, bytes memory result) = address(this).delegatecall(_data);
        if (!success) {
            if (result.length < 68) revert("");
            assembly {
                result := add(result, 0x04)
            }
            revert(abi.decode(result, (string)));
        }
        return result;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.9;

interface ISafeMulticall {
    function multicall(bytes[] calldata _data) external returns (bytes[] memory);

    function expiringMulticall(uint256 _expireAfter, bytes[] calldata _data)
        external
        returns (bytes[] memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/IERC20Metadata.sol)

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