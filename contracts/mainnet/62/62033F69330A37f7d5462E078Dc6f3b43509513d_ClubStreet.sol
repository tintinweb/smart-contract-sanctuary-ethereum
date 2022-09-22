// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./libraries/DancerQueue.sol";

interface ICustomRules {
    function isAllowedJoin(address _account, uint256 _targetClubNum, bytes memory _condition) external view returns(bool, string memory);
    function isAllowedBounty(address _account, uint256 _targetClubNum) external view returns(bool, string memory);
}


interface IPartyHeatPointCenter {
    function claim(address _account, uint256 _targetClubNum, string memory actionType) external;
}


interface IClubStreet {
    function getBountyForBatch(address _account, IERC20 _token, uint256 _index, uint256 _targetClubNum) external;
}


contract ClubStreet is Ownable {
    using DancerQueue for DancerQueue.DancerDeque;
    
    enum BountyType { AVERAGE, RANDOM }

    struct ClubInfo {
        bool isInOperation;
        IERC20 feeToken;
        uint256 feeAmount;
        uint256 bountyFeeRatio;
        uint256 interval;
        uint256 maxDancers;
        string metadata;
        ICustomRules customRules;
        IPartyHeatPointCenter partyHeatPointCenter;
        DancerQueue.DancerDeque dancers;
        mapping(address => uint256) dancerMap;
        mapping(IERC20 => bool) transferWhitelist;
    }

    struct BountyDatas{
        uint256 totalAmount;
        uint256 bountyNum;
        mapping(uint256 => BountyData) bountyMap;
    }

    struct BountyData{
        uint256 totalAmount;
        uint256 totalNumber;
        uint256 remainNumber;
        uint256 remainAmount;
        uint256 starttime;
        uint256 duration;
        BountyType bountyType;
        mapping(address => uint256) userMap;
    }

    address public feeTo;
    address public bountyFeeTo;
    uint256 public clubNum;
    uint256 public bountyLifeCycle;

    mapping(uint256 => ClubInfo) private clubs;
    mapping(uint256 => mapping(IERC20 => BountyDatas)) private bounties;
    
    event NewFeeTo(address oldAddr, address newAddr);
    event NewBountyFeeTo(address oldAddr, address newAddr);
    event NewBountyLifeCycle(uint256 oldBountyLifeCycle, uint256 newBountyLifeCycle);
    event NewMetadata(string newMetadata, uint256 targetClubNum);
    event NewTransferWhitelist(address token, bool status, uint256 targetClubNum);
    event NewCustomRules(address customRules, uint256 targetClubNum);
    event NewPartyHeatPointCenter(address partyHeatPointCenter, uint256 targetClubNum);
    event NewClubInfo(
        uint256 targetClubNum, 
        IERC20 feeToken, 
        uint256 bountyFeeRatio, 
        uint256 feeAmount, 
        uint256 interval, 
        uint256 maxDancer, 
        bool isOperation
    );
    event OpenClub(uint256 amount, uint256 clubNum);
    event Join(address account, uint256 timestamp, uint256 targetClubNum);
    event SendBounty(
        address token, 
        uint256 amount, 
        uint256 number,
        BountyType bountyType, 
        uint256 starttime,
        uint256 duration,
        uint256 bountyFee, 
        uint256 index, 
        uint256 targetClubNum
    );
    event GetBounty(address token, address account, uint256 amount, uint256 targetClubNum, uint256 index);
    event GetBackExpiredFund(address token, address account, uint256 amount, uint256 targetClubNum);
    event GetBountyFailure(uint256 index, bytes error);

    modifier onlyEOA() {
        require(msg.sender == tx.origin, "ClubStreet: Must use EOA");
        _;
    }

    function setFeeTo(address _feeTo) public onlyOwner {
        address oldFeeTo = feeTo;
        feeTo = _feeTo;
        emit NewFeeTo(oldFeeTo, _feeTo);
    }

    function setBountyFeeTo(address _bountyFeeTo) public onlyOwner {
        address oldBountyFeeTo = bountyFeeTo;
        bountyFeeTo = _bountyFeeTo;
        emit NewBountyFeeTo(oldBountyFeeTo, _bountyFeeTo);
    }

    function setBountyLifeCycle(uint256 _bountyLifeCycle) public onlyOwner {
        require(_bountyLifeCycle > 0, "ClubStreet: Not Allow Zero");
        uint256 oldBountyLifeCycle = bountyLifeCycle;
        bountyLifeCycle = _bountyLifeCycle;
        emit NewBountyLifeCycle(oldBountyLifeCycle, _bountyLifeCycle);
    }

    function changeClubInfo(
        uint256 _targetClubNum,
        IERC20 _feeToken,
        uint256 _bountyFeeRatio,
        uint256 _feeAmount,
        uint256 _interval,
        uint256 _maxDancers,
        bool _isInOperation
    ) 
        public 
        onlyOwner 
    {
        clubs[_targetClubNum].feeToken = _feeToken;
        clubs[_targetClubNum].bountyFeeRatio = _bountyFeeRatio;
        clubs[_targetClubNum].feeAmount = _feeAmount;
        clubs[_targetClubNum].interval = _interval;
        clubs[_targetClubNum].maxDancers = _maxDancers;
        clubs[_targetClubNum].isInOperation = _isInOperation;
        emit NewClubInfo(_targetClubNum, _feeToken, _bountyFeeRatio, _feeAmount, _interval, _maxDancers, _isInOperation);
    }

    function setNewMetadata(string[] memory _metadatas, uint256[] memory _targetClubNums) public onlyOwner {
        for (uint256 i; i < _metadatas.length; i++) {
            // require(clubs[_targetClubNums[i]].isInOperation, "ClubStreet: Not in operation");
            clubs[_targetClubNums[i]].metadata = _metadatas[i];
            emit NewMetadata(_metadatas[i], _targetClubNums[i]);
        }
    }

    function setTransferWhitelist(IERC20[][] memory _tokens, bool[][] memory _alloweds, uint256[] memory _targetClubNums) public onlyOwner {
        for (uint256 i; i < _tokens.length; i++) {
            // require(clubs[_targetClubNums[i]].isInOperation, "ClubStreet: Not in operation");
            for (uint256 j; j < _tokens[i].length; j++) {
                clubs[_targetClubNums[i]].transferWhitelist[_tokens[i][j]] = _alloweds[i][j];
                emit NewTransferWhitelist(address(_tokens[i][j]), _alloweds[i][j], _targetClubNums[i]);
            }
        }
    }

    function setCustomRules(ICustomRules[] memory _customRules, uint256[] memory _targetClubNums) public onlyOwner {
        for (uint256 i; i < _customRules.length; i++) {
            // require(clubs[_targetClubNums[i]].isInOperation, "ClubStreet: Not in operation");
            clubs[_targetClubNums[i]].customRules = _customRules[i];
            emit NewCustomRules(address(_customRules[i]), _targetClubNums[i]);
        }
    }

    function setPartyHeatPointCenter(IPartyHeatPointCenter[] memory _partyHeatPointCenters, uint256[] memory _targetClubNums) public onlyOwner {
        for (uint256 i; i < _partyHeatPointCenters.length; i++) {
            // require(clubs[_targetClubNums[i]].isInOperation, "ClubStreet: Not in operation");
            clubs[_targetClubNums[i]].partyHeatPointCenter = _partyHeatPointCenters[i];
            emit NewPartyHeatPointCenter(address(_partyHeatPointCenters[i]), _targetClubNums[i]);
        }
    }

    function openClubs(
        string[] memory _metadatas,
        IERC20[] memory _feeTokens,
        uint256[] memory _feeAmounts,
        uint256[] memory _bountyFeeRatios,
        uint256[] memory _intervals,
        uint256[] memory _maxDancers,
        ICustomRules[] memory _customRules,
        IPartyHeatPointCenter[] memory _partyHeatPointCenter
    ) 
        external 
        onlyOwner 
    {
        for (uint256 i; i < _feeTokens.length; i++) {
            ClubInfo storage club = clubs[clubNum++];
            club.isInOperation = true;
            club.metadata = _metadatas[i];
            club.feeToken = _feeTokens[i];
            club.feeAmount = _feeAmounts[i];
            club.bountyFeeRatio = _bountyFeeRatios[i];
            club.interval = _intervals[i];
            club.maxDancers = _maxDancers[i];
            club.customRules = _customRules[i];
            club.partyHeatPointCenter = _partyHeatPointCenter[i];
        }
        emit OpenClub(_feeTokens.length, clubNum);
    }

    function join(uint256 _targetClubNum, bytes memory _conditions) external onlyEOA {
        _join(msg.sender, _targetClubNum, _conditions);
    }

    function sendBounty(
        IERC20 _token, 
        uint256 _amount, 
        uint256 _number, 
        BountyType _bountyType,
        uint256 _starttime, 
        uint256 _duration, 
        uint256 _targetClubNum
    )
        external 
        onlyEOA 
    {
        ClubInfo storage targetClub = clubs[_targetClubNum];
        require(targetClub.isInOperation, "ClubStreet: Not in operation");

        uint256 nowTime = block.timestamp;
        uint256 _bountyFee;

        if (msg.sender == owner()) {
            _token.transferFrom(msg.sender, address(this), _amount);
            
        } else {
            if (targetClub.customRules != ICustomRules(address(0))) {
                (bool _isAllowed, string memory _desc) = targetClub.customRules.isAllowedBounty(msg.sender, _targetClubNum);
                require(_isAllowed, _desc);
            }

            uint256 startTime = targetClub.dancerMap[msg.sender];
            require(startTime > 0 && nowTime < startTime + targetClub.interval, "ClubStreet: Not in the club");
            require(targetClub.transferWhitelist[_token], "ClubStreet: Not in the whitelist");

            _token.transferFrom(msg.sender, address(this), _amount);
            
            if (targetClub.bountyFeeRatio > 0 && bountyFeeTo != address(0)) {
                _bountyFee = _amount * targetClub.bountyFeeRatio / 1e18;
                _token.transfer(bountyFeeTo, _bountyFee);
            }
        }

        uint256 _finalAmount = _amount - _bountyFee;
        BountyDatas storage last = bounties[_targetClubNum][_token];
        last.totalAmount += _finalAmount;

        BountyData storage newBounty = last.bountyMap[last.bountyNum];
        newBounty.totalAmount = _finalAmount;
        newBounty.totalNumber = _number;
        newBounty.remainNumber = _number;
        newBounty.remainAmount = _finalAmount;
        newBounty.bountyType = _bountyType;
        newBounty.starttime = _starttime > nowTime ? _starttime : nowTime;
        newBounty.duration = _duration;

        last.bountyNum++;

        if (targetClub.partyHeatPointCenter != IPartyHeatPointCenter(address(0)) && msg.sender != owner()) {
           targetClub.partyHeatPointCenter.claim(msg.sender, _targetClubNum, "sendBounty");
        }

        emit SendBounty(
            address(_token), 
            _finalAmount, 
            _number,
            _bountyType,
            _starttime,
            _duration, 
            _bountyFee, 
            last.bountyNum, 
            _targetClubNum
        );
    }

    function getBounty(IERC20 _token, uint256 _index, uint256 _targetClubNum) external onlyEOA {
        _getBounty(msg.sender, _token, _index, _targetClubNum);
    }

    function getBountyForBatch(address _account, IERC20 _token, uint256 _index, uint256 _targetClubNum) external {
        require(msg.sender == address(this), "ClubStreet: Must be address(this)");
        _getBounty(_account, _token, _index, _targetClubNum);
    }

    function batchGetBounty(IERC20[] memory _tokens, uint256[] memory _indexs, uint256[] memory _targetClubNums) public onlyEOA {
        for (uint256 i; i < _tokens.length; i++) {
            try IClubStreet(address(this)).getBountyForBatch(msg.sender, _tokens[i], _indexs[i], _targetClubNums[i]) {
                // success
            }
            catch Error(string memory reason) {
                // catch failing revert() and require()
                emit GetBountyFailure(i, bytes(reason));
            } catch (bytes memory reason) {
                // catch failing assert()
                emit GetBountyFailure(i, reason);
            }
        }
    }

    function getBackExpiredFund(IERC20 _token, uint256 _index, uint256 _targetClubNum) public onlyOwner {
        BountyDatas storage last = bounties[_targetClubNum][_token];
        BountyData storage bounty = last.bountyMap[_index];
        if (bounty.duration != 0) {
            require(block.timestamp - bounty.starttime > bounty.duration, "ClubStreet: Not Expired");
        } else {
            require(block.timestamp - bounty.starttime > bountyLifeCycle, "ClubStreet: Not Expired");
        }
        
        uint256 _reward = last.bountyMap[_index].remainAmount;
        last.bountyMap[_index].remainAmount = 0;

        _token.transfer(bountyFeeTo, _reward);
        emit GetBackExpiredFund(address(_token), bountyFeeTo, _reward, _targetClubNum);
    }

    function getBackExpiredFunds(IERC20[] memory _tokens, uint256[] memory _indexs, uint256[] memory _targetClubNums) public onlyOwner {
        for (uint256 i; i < _tokens.length; i++) {
            getBackExpiredFund(_tokens[i], _indexs[i], _targetClubNums[i]);
        }
    }

    function _join(address _account, uint256 _targetClubNum, bytes memory _conditions) internal {
        ClubInfo storage targetClub = clubs[_targetClubNum];
        require(targetClub.isInOperation, "ClubStreet: Not in operation");
        uint256 nowTime = block.timestamp;
        if (targetClub.dancers.length() == targetClub.maxDancers) {
            uint256 joinTime = targetClub.dancers.front().joinTime;
            require(nowTime - joinTime > targetClub.interval, "ClubStreet: The club is full");
            targetClub.dancers.popFront();
        }

        require(nowTime - targetClub.dancerMap[_account] > targetClub.interval, "ClubStreet: Already in the club");

        if (targetClub.customRules != ICustomRules(address(0))) {
           (bool _isAllowed, string memory _desc) = targetClub.customRules.isAllowedJoin(_account, _targetClubNum, _conditions);
           require(_isAllowed, _desc);
        }

        if (targetClub.feeAmount > 0 && feeTo != address(0)) {
            targetClub.feeToken.transferFrom(_account, feeTo, targetClub.feeAmount);
        }

        targetClub.dancerMap[_account] = nowTime;
        targetClub.dancers.pushBack(DancerQueue.Dancer(_account, nowTime));

        if (targetClub.partyHeatPointCenter != IPartyHeatPointCenter(address(0))) {
           targetClub.partyHeatPointCenter.claim(_account, _targetClubNum, "join");
        }

        emit Join(_account, nowTime, _targetClubNum);
    }

    function _getBounty(address _account, IERC20 _token, uint256 _index, uint256 _targetClubNum) internal {
        ClubInfo storage targetClub = clubs[_targetClubNum];
        require(targetClub.isInOperation, "ClubStreet: Not in operation");

        if (targetClub.customRules != ICustomRules(address(0))) {
            (bool _isAllowed, string memory _desc) = targetClub.customRules.isAllowedBounty(_account, _targetClubNum);
            require(_isAllowed, _desc);
        }

        uint256 nowTime = block.timestamp;
        uint256 startTime = targetClub.dancerMap[_account];
        require(startTime > 0 && nowTime < startTime + targetClub.interval, "ClubStreet: Not in the club");

        BountyDatas storage last = bounties[_targetClubNum][_token];
        require(last.bountyMap[_index].remainNumber > 0, "ClubStreet: Not Init or Finished");

        require(last.bountyMap[_index].userMap[_account] == 0, "ClubStreet: Already Claimed");

        require(nowTime >= last.bountyMap[_index].starttime, "ClubStreet: Not Start");

        require(last.bountyMap[_index].duration == 0 || nowTime < last.bountyMap[_index].starttime + last.bountyMap[_index].duration, "ClubStreet: Expired");

        uint256 _reward;
        if (last.bountyMap[_index].bountyType == BountyType.AVERAGE) {
            if (last.bountyMap[_index].remainNumber == 1) {
                _reward = last.bountyMap[_index].remainAmount;
            } else {
                _reward = last.bountyMap[_index].totalAmount / last.bountyMap[_index].totalNumber;
            }
        } else {
            if (last.bountyMap[_index].remainNumber == 1) {
                _reward = last.bountyMap[_index].remainAmount;
            } else {
                while (_reward == 0) {
                    _reward = uint256(keccak256(abi.encodePacked(_index, _account, block.difficulty, block.timestamp))) %
                            (2 * last.bountyMap[_index].remainAmount / last.bountyMap[_index].remainNumber);
                }
            }
        }

        last.bountyMap[_index].remainAmount -= _reward;
        last.bountyMap[_index].userMap[_account] = _reward;
        last.bountyMap[_index].remainNumber--;

        _token.transfer(_account, _reward);

        if (targetClub.partyHeatPointCenter != IPartyHeatPointCenter(address(0))) {
           targetClub.partyHeatPointCenter.claim(_account, _targetClubNum, "getBounty");
        }

        emit GetBounty(address(_token), _account, _reward, _targetClubNum, _index);
    }
    
    function getInClubDancer(uint256 _targetClubNum) external view returns(address[] memory) {
        ClubInfo storage targetClub = clubs[_targetClubNum];
        uint256 index;
        uint256 nowTime = block.timestamp;
        for(uint256 i; i < targetClub.dancers.length(); i++) {
            uint256 joinTime = targetClub.dancers.at(i).joinTime;
            if (nowTime - joinTime < targetClub.interval) {
                break;
            }
            index++;
        }
        uint256 amount = targetClub.dancers.length() - index;
        address[] memory inClubDancerList = new address[](amount);

        for(uint256 i; i < amount; i++) {
            inClubDancerList[i] = targetClub.dancers.at(index+i).addr;
        }
        return inClubDancerList;
    }

    function getClubInfo(uint256 _targetClubNum) 
        external 
        view 
        returns(
            bool isInOperation,
            IERC20 feeToken,
            uint256 feeAmout,
            uint256 bountyFeeRatio,
            uint256 interval,
            uint256 maxDancers,
            string memory metadata,
            ICustomRules customRules
        ) 
    {

        ClubInfo storage targetClub = clubs[_targetClubNum];
        isInOperation = targetClub.isInOperation;
        feeToken = targetClub.feeToken;
        feeAmout = targetClub.feeAmount;
        bountyFeeRatio = targetClub.bountyFeeRatio ;
        interval = targetClub.interval;
        maxDancers = targetClub.maxDancers;
        customRules = targetClub.customRules;
        metadata = targetClub.metadata;
    }
}

// SPDX-License-Identifier: MIT
// Forked from OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/DoubleEndedQueue.sol)
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";

/**
 * @dev A sequence of items with the ability to efficiently push and pop items (i.e. insert and remove) on both ends of
 * the sequence (called front and back). Among other access patterns, it can be used to implement efficient LIFO and
 * FIFO queues. Storage use is optimized, and all operations are O(1) constant time. This includes {clear}, given that
 * the existing queue contents are left in storage.
 */
library DancerQueue {
    /**
     * @dev An operation (e.g. {front}) couldn't be completed due to the queue being empty.
     */
    error Empty();

    /**
     * @dev An operation (e.g. {at}) couldn't be completed due to an index being out of bounds.
     */
    error OutOfBounds();

    struct Dancer {
        address addr;
        uint256 joinTime;
    }

    /**
     * @dev Indices are signed integers because the queue can grow in any direction. They are 128 bits so begin and end
     * are packed in a single storage slot for efficient access. Since the items are added one at a time we can safely
     * assume that these 128-bit indices will not overflow, and use unchecked arithmetic.
     *
     * Struct members have an underscore prefix indicating that they are "private" and should not be read or written to
     * directly. Use the functions provided below instead. Modifying the struct manually may violate assumptions and
     * lead to unexpected behavior.
     *
     * Indices are in the range [begin, end) which means the first item is at data[begin] and the last item is at
     * data[end - 1].
     */
    struct DancerDeque {
        int128 _begin;
        int128 _end;
        mapping(int128 => Dancer) _data;
    }

    /**
     * @dev Inserts an item at the end of the queue.
     */
    function pushBack(DancerDeque storage deque, Dancer memory value) internal {
        int128 backIndex = deque._end;
        deque._data[backIndex] = value;
        unchecked {
            deque._end = backIndex + 1;
        }
    }

    /**
     * @dev Removes the item at the end of the queue and returns it.
     *
     * Reverts with `Empty` if the queue is empty.
     */
    function popBack(DancerDeque storage deque) internal returns (Dancer memory value) {
        if (empty(deque)) revert Empty();
        int128 backIndex;
        unchecked {
            backIndex = deque._end - 1;
        }
        value = deque._data[backIndex];
        delete deque._data[backIndex];
        deque._end = backIndex;
    }

    /**
     * @dev Inserts an item at the beginning of the queue.
     */
    function pushFront(DancerDeque storage deque, Dancer memory value) internal {
        int128 frontIndex;
        unchecked {
            frontIndex = deque._begin - 1;
        }
        deque._data[frontIndex] = value;
        deque._begin = frontIndex;
    }

    /**
     * @dev Removes the item at the beginning of the queue and returns it.
     *
     * Reverts with `Empty` if the queue is empty.
     */
    function popFront(DancerDeque storage deque) internal returns (Dancer memory value) {
        if (empty(deque)) revert Empty();
        int128 frontIndex = deque._begin;
        value = deque._data[frontIndex];
        delete deque._data[frontIndex];
        unchecked {
            deque._begin = frontIndex + 1;
        }
    }

    /**
     * @dev Returns the item at the beginning of the queue.
     *
     * Reverts with `Empty` if the queue is empty.
     */
    function front(DancerDeque storage deque) internal view returns (Dancer memory value) {
        if (empty(deque)) revert Empty();
        int128 frontIndex = deque._begin;
        return deque._data[frontIndex];
    }

    /**
     * @dev Returns the item at the end of the queue.
     *
     * Reverts with `Empty` if the queue is empty.
     */
    function back(DancerDeque storage deque) internal view returns (Dancer memory value) {
        if (empty(deque)) revert Empty();
        int128 backIndex;
        unchecked {
            backIndex = deque._end - 1;
        }
        return deque._data[backIndex];
    }

    /**
     * @dev Return the item at a position in the queue given by `index`, with the first item at 0 and last item at
     * `length(deque) - 1`.
     *
     * Reverts with `OutOfBounds` if the index is out of bounds.
     */
    function at(DancerDeque storage deque, uint256 index) internal view returns (Dancer memory value) {
        // int256(deque._begin) is a safe upcast
        int128 idx = SafeCast.toInt128(int256(deque._begin) + SafeCast.toInt256(index));
        if (idx >= deque._end) revert OutOfBounds();
        return deque._data[idx];
    }

    /**
     * @dev Resets the queue back to being empty.
     *
     * NOTE: The current items are left behind in storage. This does not affect the functioning of the queue, but misses
     * out on potential gas refunds.
     */
    function clear(DancerDeque storage deque) internal {
        deque._begin = 0;
        deque._end = 0;
    }

    /**
     * @dev Returns the number of items in the queue.
     */
    function length(DancerDeque storage deque) internal view returns (uint256) {
        // The interface preserves the invariant that begin <= end so we assume this will not overflow.
        // We also assume there are at most int256.max items in the queue.
        unchecked {
            return uint256(int256(deque._end) - int256(deque._begin));
        }
    }

    /**
     * @dev Returns true if the queue is empty.
     */
    function empty(DancerDeque storage deque) internal view returns (bool) {
        return deque._end <= deque._begin;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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