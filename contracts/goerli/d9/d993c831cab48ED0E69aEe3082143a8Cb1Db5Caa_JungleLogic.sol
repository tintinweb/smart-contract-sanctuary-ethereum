pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
 *     ,_,
 *    (',')
 *    {/"\}
 *    -"-"-
 */

import "IERC20.sol";
import "SafeMath.sol";
import "IERC721.sol";
import "IERC1155.sol";
import "Ownable.sol";

interface IJungleLogic {
	function run(uint256 _charm, uint256 _seed, uint256 _team, uint256[5] calldata _levels )
		external
		view
		returns(uint256 gameData, address[3] memory rewardAddress, uint256[3] memory tokenId, uint256[3] memory amounts, uint256[3] memory tokenTypes);
	function getReqForLvl(uint256 _currentLevel) external view returns(uint256 exp, uint256 kongium);
}

contract JungleLogic is IJungleLogic, Ownable {

	// struct GameEvent {
	// 	uint256 eventType; // 2 bits
	// 	uint256 charmRequirement; // 2 bits
	// 	uint256 teamSizeRequirement; // 3 bits
	// 	uint256 singleLevelRequirement; // 5 bits
	// 	uint256 totalLevelRequirement; // 7 bits
	// 	uint256 tokenType; // 11 bits
	// 	uint256 chance; // 17 bits
	// 	address tokenReward; // 160 bits
	// 	uint256 reward; // 128 bits
	// 	uint256 amount; // 128 bits
	// }


	struct GameEventInfo {
		bool hasIndex;
		uint8 eventType; // 2 bits
		uint8 charmRequirement; // 2 bits
		uint8 teamSizeRequirement; // 3 bits
		uint8 singleLevelRequirement; // 5 bits
		uint8 totalLevelRequirement; // 7 bits
		uint16 tokenType; // 11 bits
		uint24 chance; // 17 bits
		address tokenReward; // 160 bits
		uint128 reward; // 128 bits
		uint128 amount; // 128 bits
	}

	struct GameEvent {
		uint256 l1;
		uint256 l2;
	}

	uint256 constant MAX_CHANCE = 100000;

	mapping(address => bool) public authorised;

	uint256 public eventCounter;
	uint256 public enabledEventCounter;
	uint256 public maxChanceCounter;
	mapping(uint256 => GameEvent) public gameEvents;
	mapping(uint256 => uint256) public gameEventQueue;
	mapping(uint256 => uint256) public gameEventIdToIndex;

	uint256 public charmEventCounter;
	uint256 public enabledCharmEventCounter;
	uint256 public charmMaxChanceCounter;
	mapping(uint256 => GameEvent) public charmGameEvents;
	mapping(uint256 => uint256) public charmGameEventQueue;
	mapping(uint256 => uint256) public charmGameEventIdToIndex;

	uint256 public rodEventCounter;
	uint256 public enabledRodEventCounter;
	uint256 public rodMaxChanceCounter;
	mapping(uint256 => GameEvent) public rodGameEvents;
	mapping(uint256 => uint256) public rodGameEventQueue;
	mapping(uint256 => uint256) public rodGameEventIdToIndex;


	modifier isAuthorised(address _user) {
		require(authorised[_user] || _user == owner(), "Not authorised");
		_;
	}

	function setAuthorised(address _user, bool _val) external onlyOwner {
		authorised[_user] = _val;
	}

	function getEventInfo(uint256 _start, uint256 _end) external view returns(GameEventInfo[] memory) {
		_end = _end > eventCounter ? eventCounter: _end;
		if (_start > _end) return new GameEventInfo[](0);
		uint256 i;
		GameEventInfo[] memory infos = new GameEventInfo[](_end - _start);
		for(_start; _start < _end; _start++) {
			GameEvent memory gameEvent = gameEvents[_start];
			uint256 l1 = gameEvent.l1;
			uint256 l2 = gameEvent.l2;
			infos[i++] = GameEventInfo(
				gameEventIdToIndex[_start] > 0 ? true: false,
				uint8(_eventType(l1)),
				uint8(_charmRequirement(l1)),
				uint8(_teamSize(l1)),
				uint8(_singleLevel(l1)),
				uint8(_totalLevel(l1)),
				uint16(_tokenType(l1)),
				uint24(_chance(l1)),
				_token(l1),
				uint128(_reward(l2)),
				uint128(_amount(l2))
			);
		}
		return infos;
	}

	function getCharmEventInfo(uint256 _start, uint256 _end) external view returns(GameEventInfo[] memory) {
		_end = _end > charmEventCounter ? charmEventCounter: _end;
		if (_start > _end) return new GameEventInfo[](0);
		uint256 i;
		GameEventInfo[] memory infos = new GameEventInfo[](_end - _start);
		for(_start; _start < _end; _start++) {
			GameEvent memory gameEvent = charmGameEvents[_start];
			uint256 l1 = gameEvent.l1;
			uint256 l2 = gameEvent.l2;
			infos[i++] = GameEventInfo(
				charmGameEventIdToIndex[_start] > 0 ? true: false,
				uint8(_eventType(l1)),
				uint8(_charmRequirement(l1)),
				uint8(_teamSize(l1)),
				uint8(_singleLevel(l1)),
				uint8(_totalLevel(l1)),
				uint16(_tokenType(l1)),
				uint24(_chance(l1)),
				_token(l1),
				uint128(_reward(l2)),
				uint128(_amount(l2))
			);
		}
		return infos;
	}

	function getRodEventInfo(uint256 _start, uint256 _end) external view returns(GameEventInfo[] memory) {
		_end = _end > rodEventCounter ? rodEventCounter: _end;
		if (_start > _end) return new GameEventInfo[](0);
		uint256 i;
		GameEventInfo[] memory infos = new GameEventInfo[](_end - _start);
		for(_start; _start < _end; _start++) {
			GameEvent memory gameEvent = rodGameEvents[_start];
			uint256 l1 = gameEvent.l1;
			uint256 l2 = gameEvent.l2;
			infos[i++] = GameEventInfo(
				rodGameEventIdToIndex[_start] > 0 ? true: false,
				uint8(_eventType(l1)),
				uint8(_charmRequirement(l1)),
				uint8(_teamSize(l1)),
				uint8(_singleLevel(l1)),
				uint8(_totalLevel(l1)),
				uint16(_tokenType(l1)),
				uint24(_chance(l1)),
				_token(l1),
				uint128(_reward(l2)),
				uint128(_amount(l2))
			);
		}
		return infos;
	}

	function addEvent(
		uint256 _chance,
		uint256 _eventType,
		uint256 _tokenType,
		address _token,
		uint256 _reward,
		uint256  _amount,
		uint256 _singleLevel,
		uint256 _totalLevel,
		uint256 _teamSize,
		uint256 _charm,
		bool	_enable
	) external isAuthorised(msg.sender) {
		require(_chance <= MAX_CHANCE);
		uint256 l1 = _eventType << 2;
		l1 = (l1 + _charm) << 3;
		l1 = (l1 + _teamSize) << 5;
		l1 = (l1 + _singleLevel) << 7;
		l1 = (l1 + _totalLevel) << 11;
		l1 = (l1 + _tokenType) << 17;
		l1 = (l1 + _chance) << 160;
		l1 = l1 + uint256(uint160(_token));
		uint l2 = (_reward << 128) + _amount;
		gameEvents[eventCounter++] = GameEvent(l1, l2);
		if (_enable)
			enableEvent(eventCounter - 1);
	}

	function enableEvent(uint256 _eventId) public isAuthorised(msg.sender) {
		require(_eventId < eventCounter, "Outside of range");
		GameEvent memory _event = gameEvents[_eventId];
		require(maxChanceCounter + _chance(_event.l1) <= MAX_CHANCE, "chance");
		gameEventIdToIndex[_eventId] = enabledEventCounter + 1;
		gameEventQueue[enabledEventCounter++] = _eventId;
		maxChanceCounter += _chance(_event.l1);
	}

	function editEventParams(
		uint256 _eventId,
		uint256 __chance,
		uint256 _eventType,
		uint256 _tokenType,
		address _token,
		uint256 _reward,
		uint256  _amount,
		uint256 _singleLevel,
		uint256 _totalLevel,
		uint256 _teamSize,
		uint256 _charm) external isAuthorised(msg.sender) {
		require(_eventId < eventCounter, "Outside of range");
		uint256 l1 = _eventType << 2;
		l1 = (l1 + _charm) << 3;
		l1 = (l1 + _teamSize) << 5;
		l1 = (l1 + _singleLevel) << 7;
		l1 = (l1 + _totalLevel) << 11;
		l1 = (l1 + _tokenType) << 17;
		l1 = (l1 + __chance) << 160;
		l1 = l1 + uint256(uint160(_token));
		gameEvents[_eventId] = GameEvent(l1, (_reward << 128) + _amount);
	}

	function editEvent(uint256 _eventId, uint256 __chance) external isAuthorised(msg.sender) {
		require(_eventId < eventCounter, "Outside of range");
		GameEvent storage _event = gameEvents[_eventId];
		uint256 currentChance = _chance(_event.l1);
		require(maxChanceCounter - currentChance + __chance <= MAX_CHANCE, "chance");
		_event.l1 = (_event.l1 & ~(uint256(131071) << 160)) | (__chance << 160);
		if (gameEventIdToIndex[_eventId] > 0)
			maxChanceCounter = maxChanceCounter - currentChance + __chance;
	}

	function disableEvent(uint256 _eventId) external isAuthorised(msg.sender) {
		require(_eventId < eventCounter, "Outside of range");
		require(gameEventIdToIndex[_eventId] > 0, "Event not enabled");
		uint256 index = gameEventIdToIndex[_eventId] - 1;
		GameEvent memory _event = gameEvents[_eventId];

		gameEventQueue[index] = gameEventQueue[enabledEventCounter - 1];
		gameEventIdToIndex[gameEventQueue[enabledEventCounter - 1]] = index + 1;
		delete gameEventIdToIndex[_eventId];
		delete gameEventQueue[enabledEventCounter - 1];
		enabledEventCounter--;
		maxChanceCounter -= _chance(_event.l1);
	}
	
	function charmAddEvent(
		uint256 _chance,
		uint256 _eventType,
		uint256 _tokenType,
		address _token,
		uint256 _reward,
		uint256  _amount,
		uint256 _singleLevel,
		uint256 _totalLevel,
		uint256 _teamSize,
		uint256 _charm,
		bool	_enable
	) external isAuthorised(msg.sender) {
		require(_chance <= MAX_CHANCE);
		uint256 l1 = _eventType << 2;
		l1 = (l1 + _charm) << 3;
		l1 = (l1 + _teamSize) << 5;
		l1 = (l1 + _singleLevel) << 7;
		l1 = (l1 + _totalLevel) << 11;
		l1 = (l1 + _tokenType) << 17;
		l1 = (l1 + _chance) << 160;
		l1 = l1 + uint256(uint160(_token));
		uint l2 = (_reward << 128) + _amount;
		charmGameEvents[charmEventCounter++] = GameEvent(l1, l2);
		if (_enable)
			charmEnableEvent(charmEventCounter - 1);
	}

	function charmDisableEvent(uint256 _eventId) external isAuthorised(msg.sender) {
		require(_eventId < charmEventCounter, "Outside of range");
		require(charmGameEventIdToIndex[_eventId] > 0, "Event not enabled");
		uint256 index = charmGameEventIdToIndex[_eventId] - 1;
		GameEvent memory _event = charmGameEvents[_eventId];

		charmGameEventQueue[index] = charmGameEventQueue[enabledCharmEventCounter - 1];
		charmGameEventIdToIndex[charmGameEventQueue[enabledCharmEventCounter - 1]] = index + 1;
		delete charmGameEventIdToIndex[_eventId];
		delete charmGameEventQueue[enabledCharmEventCounter - 1];
		enabledCharmEventCounter--;
		charmMaxChanceCounter -= _chance(_event.l1);
	}

	function charmEditEventParams(
		uint256 _eventId,
		uint256 __chance,
		uint256 _eventType,
		uint256 _tokenType,
		address _token,
		uint256 _reward,
		uint256  _amount,
		uint256 _singleLevel,
		uint256 _totalLevel,
		uint256 _teamSize,
		uint256 _charm) external isAuthorised(msg.sender) {
		require(_eventId < charmEventCounter, "Outside of range");
		uint256 l1 = _eventType << 2;
		l1 = (l1 + _charm) << 3;
		l1 = (l1 + _teamSize) << 5;
		l1 = (l1 + _singleLevel) << 7;
		l1 = (l1 + _totalLevel) << 11;
		l1 = (l1 + _tokenType) << 17;
		l1 = (l1 + __chance) << 160;
		l1 = l1 + uint256(uint160(_token));
		charmGameEvents[_eventId] = GameEvent(l1, (_reward << 128) + _amount);
	}

	function charmEditEvent(uint256 _eventId, uint256 __chance) external isAuthorised(msg.sender) {
		require(_eventId < charmEventCounter, "Outside of range");
		GameEvent storage _event = charmGameEvents[_eventId];
		uint256 currentChance = _chance(_event.l1);
		require(charmMaxChanceCounter - currentChance + __chance <= MAX_CHANCE, "chance");
		_event.l1 = (_event.l1 & ~(uint256(131071) << 160)) | (__chance << 160);
		if (charmGameEventIdToIndex[_eventId] > 0)
			charmMaxChanceCounter = charmMaxChanceCounter - currentChance + __chance;
	}

	function charmEnableEvent(uint256 _eventId) public isAuthorised(msg.sender) {
		require(_eventId < charmEventCounter, "Outside of range");
		GameEvent storage _event = charmGameEvents[_eventId];
		require(charmMaxChanceCounter + _chance(_event.l1) <= MAX_CHANCE, "chance");
		charmGameEventIdToIndex[_eventId] = enabledCharmEventCounter + 1;
		charmGameEventQueue[enabledCharmEventCounter++] = _eventId;
		charmMaxChanceCounter += _chance(_event.l1);
	}

	function rodAddAndEnableEvent(
		uint256 _chance,
		uint256 _eventType,
		uint256 _tokenType,
		address _token,
		uint256 _reward,
		uint256  _amount,
		uint256 _singleLevel,
		uint256 _totalLevel,
		uint256 _teamSize,
		uint256 _charm,
		bool	_enable
	) external isAuthorised(msg.sender) {
		require(_chance <= MAX_CHANCE);
		uint256 l1 = _eventType << 2;
		l1 = (l1 + _charm) << 3;
		l1 = (l1 + _teamSize) << 5;
		l1 = (l1 + _singleLevel) << 7;
		l1 = (l1 + _totalLevel) << 11;
		l1 = (l1 + _tokenType) << 17;
		l1 = (l1 + _chance) << 160;
		l1 = l1 + uint256(uint160(_token));
		uint l2 = (_reward << 128) + _amount;
		rodGameEvents[rodEventCounter++] = GameEvent(l1, l2);
		if (_enable)
			rodEnableEvent(rodEventCounter - 1);
	}

	function rodDisableEvent(uint256 _eventId) external isAuthorised(msg.sender) {
		require(_eventId < rodEventCounter, "Outside of range");
		require(rodGameEventIdToIndex[_eventId] > 0, "Event not enabled");
		uint256 index = rodGameEventIdToIndex[_eventId] - 1;
		GameEvent memory _event = rodGameEvents[_eventId];

		rodGameEventQueue[index] = rodGameEventQueue[enabledRodEventCounter - 1];
		rodGameEventIdToIndex[rodGameEventQueue[enabledRodEventCounter - 1]] = index + 1;
		delete rodGameEventIdToIndex[_eventId];
		delete rodGameEventQueue[enabledRodEventCounter - 1];
		enabledRodEventCounter--;
		rodMaxChanceCounter -= _chance(_event.l1);
	}

	function rodEditEventParams(
		uint256 _eventId,
		uint256 __chance,
		uint256 _eventType,
		uint256 _tokenType,
		address _token,
		uint256 _reward,
		uint256 _amount,
		uint256 _singleLevel,
		uint256 _totalLevel,
		uint256 _teamSize,
		uint256 _charm) external isAuthorised(msg.sender) {
		require(_eventId < rodEventCounter, "Outside of range");
		uint256 l1 = _eventType << 2;
		l1 = (l1 + _charm) << 3;
		l1 = (l1 + _teamSize) << 5;
		l1 = (l1 + _singleLevel) << 7;
		l1 = (l1 + _totalLevel) << 11;
		l1 = (l1 + _tokenType) << 17;
		l1 = (l1 + __chance) << 160;
		l1 = l1 + uint256(uint160(_token));
		rodGameEvents[_eventId] = GameEvent(l1, (_reward << 128) + _amount);
	}

	function rodEditEvent(uint256 _eventId, uint256 __chance) external isAuthorised(msg.sender) {
		require(_eventId < rodEventCounter, "Outside of range");
		GameEvent storage _event = rodGameEvents[_eventId];
		uint256 currentChance = _chance(_event.l1);
		require(rodMaxChanceCounter - currentChance + __chance <= MAX_CHANCE, "chance");
		_event.l1 = (_event.l1 & ~(uint256(131071) << 160)) | (__chance << 160);
		if (rodGameEventIdToIndex[_eventId] > 0)
			rodMaxChanceCounter = rodMaxChanceCounter - currentChance + __chance;
	}

	function rodEnableEvent(uint256 _eventId) public isAuthorised(msg.sender) {
		require(_eventId < rodEventCounter, "Outside of range");
		GameEvent storage _event = rodGameEvents[_eventId];
		require(rodMaxChanceCounter + _chance(_event.l1) <= MAX_CHANCE, "chance");
		rodGameEventIdToIndex[_eventId] = enabledRodEventCounter + 1;
		rodGameEventQueue[enabledRodEventCounter++] = _eventId;
		rodMaxChanceCounter += _chance(_event.l1);
	}

	function _getRange(uint256 _level) internal pure returns(uint256 min, uint256 max) {
		if (_level == 1) {
			min = 1;
			max = 5;
		}
		else if (_level == 2) {
			min = 1;
			max = 6;
		}
		else if (_level == 3) {
			min = 1;
			max = 7;
		}
		else if (_level == 4) {
			min = 1;
			max = 8;
		}
		else if (_level == 5) {
			min = 1;
			max = 9;
		}
		else if (_level == 6) {
			min = 1;
			max = 10;
		}
		else if (_level == 7) {
			min = 2;
			max = 10;
		}
		else if (_level == 8) {
			min = 3;
			max = 10;
		}
		else if (_level == 9) {
			min = 4;
			max = 10;
		}
		else if (_level == 10) {
			min = 5;
			max = 10;
		}
		else if (_level == 11) {
			min = 5;
			max = 11;
		}
		else if (_level == 12) {
			min = 5;
			max = 12;
		}
		else if (_level == 13) {
			min = 5;
			max = 13;
		}
		else if (_level == 14) {
			min = 5;
			max = 14;
		}
		else if (_level == 15) {
			min = 5;
			max = 15;
		}
		else if (_level == 16) {
			min = 6;
			max = 15;
		}
		else if (_level == 17) {
			min = 7;
			max = 15;
		}
		else if (_level == 18) {
			min = 8;
			max = 15;
		}
		else if (_level == 19) {
			min = 9;
			max = 15;
		}
		else if (_level == 20) {
			min = 10;
			max = 15;
		}	
	}

	function _rollDoubleKongium(uint256 _seed, uint256 _charm) internal pure returns(bool) {
		uint256 rand = _seed % 100;
		if (_charm == 1 && rand < 20)
			return true;
		else if (_charm == 2 && rand < 40)
			return true;
		else if (_charm == 3 && rand < 100)
			return true;
		return false;
	}

	function _rollDoubleExp(uint256 _seed, uint256 _charm) internal pure returns(uint256) {
		uint256 rand = _seed % 100;
		if (_charm == 1 && rand < 10)
			return 2;
		else if (_charm == 2 && rand < 20)
			return 2;
		else if (_charm == 3 && rand < 50)
			return 2;
		return 1;
	}

	function _rollRandomRodEvent(uint256 _seed, uint256 _team, uint256[5] calldata _levels, uint256 _charm) internal view returns(uint256, uint256) {
		_seed = _seed % MAX_CHANCE;
		uint256 len = enabledRodEventCounter;
		uint256 counter;
		uint256 eventData;

		for (uint256 i = 0; i < len; i++) {
			uint256 eventId = rodGameEventQueue[i];
			uint256 l1 = rodGameEvents[eventId].l1;
			counter += _chance(l1);
			if (_seed < counter) {
				eventData = ((eventId + 1) << 4) + (_eventType(l1) << 2);
				if (_totalLevel(l1) <= _sumOfLevels(_levels) &&
					_singleLevel(l1) <= _maxLevel(_levels) &&
					_teamSize(l1)<= _vxInTeam(_team) &&
					_charmRequirement(l1)<= _charm)
					return (eventId + 1, eventData + 2);
				else
					return (0, eventData);
			}
		}
		return (0, 0);
	}

	function _rollRandomEvent(uint256 _seed, uint256 _team, uint256[5] calldata _levels, uint256 _charm) internal view returns(uint256, uint256) {
		_seed = _seed % MAX_CHANCE;
		uint256 len = enabledEventCounter;
		uint256 counter;
		uint256 eventData;

		for (uint256 i = 0; i < len; i++) {
			uint256 eventId = gameEventQueue[i];
			uint256 l1 = gameEvents[eventId].l1;
			counter += _chance(l1);
			if (_seed < counter) {
				eventData = ((eventId + 1) << 4) + (_eventType(l1) << 2);
				if (_totalLevel(l1) <= _sumOfLevels(_levels) &&
					_singleLevel(l1) <= _maxLevel(_levels) &&
					_teamSize(l1)<= _vxInTeam(_team) &&
					_charmRequirement(l1) <= _charm)
					return (eventId + 1, eventData + 2);
				else
					return (0, eventData);
			}
		}
		return (0, 0);
	}

	function _rollRandomCharmEvent(uint256 _seed, uint256 _team, uint256[5] calldata _levels, uint256 _charm) internal view returns(uint256, uint256) {
		_seed= _seed % MAX_CHANCE;
		uint256 len = enabledCharmEventCounter;
		uint256 counter;
		uint256 eventData;
		for (uint256 i = 0; i < len; i++) {
			uint256 eventId = charmGameEventQueue[i];
			uint256 l1 = charmGameEvents[eventId].l1;
			counter += _chance(l1);
			if (_seed < counter) {
				eventData = ((eventId + 1) << 4) + (_eventType(l1) << 2);
				if (_totalLevel(l1) <= _sumOfLevels(_levels) &&
					_singleLevel(l1) <= _maxLevel(_levels) &&
					_teamSize(l1)<= _vxInTeam(_team) &&
					_charmRequirement(l1)<= _charm)
					return (eventId + 1, eventData + 2);
				else
					return (0, eventData);
			}
		}
		return (0, 0);
	}

	// starting from left
	// gameData: 1-30 -> kongium earned per vx | 31 : double kongium | 32 : double exp
	//           33-40 : charm event id - 1 (0 is no event) 41-42: event type |  43: if eligible | 44: if succeeded (applicable for event type 3))
	//           45-76: event ID data (exp/kongium/exp+kongium)
	// 			 77-88: repeat with bit 88 for success of type 3
	// 			 89-120 : event Id data
	// 			 121-127: [1 bit less than other queue] rod eventId - 1 (0 not event) 128-129: event type | 130 if eligle | 131 : if succeeded (applicable for event type 3))
	//           132-159: event Id data (28 bits instead of 32 as others)
	// 
	// starting from right
	// 			1-32 : kongium earned | 33-64: bonusExp
	// 			65-69: exp flag
	// 			70: nana or rod run
	// 			71-95: lvls per vx
	// 			96-97: charm type 

	function run(uint256 _charm, uint256 _seed, uint256 _team, uint256[5] calldata _levels)
		external
		view
		override
		returns(uint256 gameData, address[3] memory rewardAddress, uint256[3] memory tokenId, uint256[3] memory amounts, uint256[3] memory tokenTypes) {
		uint256 counter;
		{
			uint256 min;
			uint256 max;
			for (uint256 i = 0; i < _levels.length; i++) {
				if (_levels[i] > 0) {
					(min, max) = _getRange(_levels[i]);
					counter += min + (_seed % (max + 1 - min));
					gameData = gameData + (min + _seed % (max + 1 - min));
					_seed = generateSeed(_seed);
				}
				gameData <<= 6;
			}
		}
		gameData >>= 5;
		_seed = generateSeed(_seed);
		if (_rollDoubleKongium(_seed, _charm & 3)) {
			gameData++;
			counter *= 2;
		}
		gameData <<= 1;
		_seed = generateSeed(_seed);
		if (_rollDoubleExp(_seed, _charm & 3) == 2)
			gameData++;
		_seed = generateSeed(_seed);
		{
			uint256 l1;
			uint256 l2;
			gameData <<= 12;
			if (_charm & 3 > 0) {
				(l1, l2) = _rollRandomCharmEvent(_seed, _team, _levels, _charm & 3);
				gameData = (gameData + l2) << 32;
				if (l1 > 0) {
					GameEvent memory _event = charmGameEvents[l1 - 1];
					l1 = _event.l1;
					l2 = _event.l2;
					// extra kongium
					if (_eventType(l1) == 0) {
						gameData += _reward(l2);
						counter += _reward(l2);
					}
					// extra exp
					else if (_eventType(l1) == 1) {
						gameData += _reward(l2);
						counter += _reward(l2) << 32;
					}
					// extra exp and kongium
					else if (_eventType(l1) == 2) {
						gameData += ((_reward(l2) & (2 ** 64 - 1)) << 16) + ((_reward(l2) >> 64));
						counter += _reward(l2) & (2 ** 64 - 1);
						counter += (_reward(l2) >> 64) << 32;
					}
					// nft
					else if (_eventType(l1) == 3) {
						if (_tokenType(l1) == 1155) {
							if (IERC1155(_token(l1)).balanceOf(msg.sender, _reward(l2)) >= _amount(l2)) {
								gameData |= (1 << 32);
								rewardAddress[0] = _token(l1);
								tokenId[0] = _reward(l2);
								amounts[0] = _amount(l2);
								tokenTypes[0] = 1155;
							}
						}
						else if (_tokenType(l1) == 20) {
							if (IERC20(_token(l1)).balanceOf(msg.sender) >= _amount(l2)) {
								gameData |= (1 << 32);
								rewardAddress[0] = _token(l1);
								amounts[0] = _amount(l2);
								tokenTypes[0] = 20;
							}
						}
					}
				}
			}
			else
				gameData <<= 32;
			_seed = generateSeed(_seed);
			gameData <<= 12;
			(l1, l2) = _rollRandomEvent(_seed, _team, _levels, _charm & 3);
			gameData = (gameData + l2) << 32;
			if (l1 > 0) {
				GameEvent memory _event = gameEvents[l1 - 1];
				l1 = _event.l1;
				l2 = _event.l2;
				// extra kongium
				if (_eventType(l1) == 0) {
					gameData += _reward(l2);
					counter += _reward(l2);
				}
				// extra exp
				else if (_eventType(l1) == 1) {
					gameData += _reward(l2);
					counter += _reward(l2) << 32;
				}
				// extra exp and kongium
				else if (_eventType(l1) == 2) {
					gameData += ((_reward(l2) & (2 ** 64 - 1)) << 16) + ((_reward(l2) >> 64));
					counter += _reward(l2) & (2 ** 64 - 1);
					counter += (_reward(l2) >> 64) << 32;
				}
				// nft
				else if (_eventType(l1) == 3) {
					if (_tokenType(l1) == 1155) {
						if (IERC1155(_token(l1)).balanceOf(msg.sender, _reward(l2)) >= _amount(l2)) {
							gameData += 1 << 32;
							rewardAddress[1] = _token(l1);
							tokenId[1] = _reward(l2);
							amounts[1] = _amount(l2);
							tokenTypes[1] = 1155;
						}
					}
					else if (_tokenType(l1) == 20) {
						if (IERC20(_token(l1)).balanceOf(msg.sender) >= _amount(l2)) {
							gameData += 1 << 32;
							rewardAddress[1] = _token(l1);
							amounts[1] = _amount(l2);
							tokenTypes[1] = 20;
						}
					}
				}
			}
			if (_charm & 128 == 128) {
				_seed = generateSeed(_seed);
				gameData <<= 11;
				(l1, l2) = _rollRandomRodEvent(_seed, _team, _levels, _charm & 3);
				gameData = (gameData + l2) << 28;
				if (l1 > 0) {
					GameEvent memory _event = rodGameEvents[l1 - 1];
					l1 = _event.l1;
					l2 = _event.l2;
					// extra kongium
					if (_eventType(l1) == 0) {
						gameData += _reward(l2);
						counter += _reward(l2);
					}
					// extra exp
					else if (_eventType(l1) == 1) {
						gameData += _reward(l2);
						counter += _reward(l2) << 32;
					}
					// extra exp and kongium
					else if (_eventType(l1) == 2) {
						gameData += ((_reward(l2) & (2 ** 64 - 1)) << 14) + ((_reward(l2) >> 64));
						counter += _reward(l2) & (2 ** 64 - 1);
						counter += (_reward(l2) >> 64) << 32;
					}
					// nft
					else if (_eventType(l1) == 3) {
						if (_tokenType(l1) == 1155) {
							if (IERC1155(_token(l1)).balanceOf(msg.sender, _reward(l2)) >= _amount(l2)) {
								gameData |= (1 << 28);
								rewardAddress[2] = _token(l1);
								tokenId[2] = _reward(l2);
								amounts[2] = _amount(l2);
								tokenTypes[2] = 1155;
							}
						}
						else if (_tokenType(l1) == 20) {
							if (IERC20(_token(l1)).balanceOf(msg.sender) >= _amount(l2)) {
								gameData |= (1 << 28);
								rewardAddress[2] = _token(l1);
								amounts[2] = _amount(l2);
								tokenTypes[2] = 20;
							}
						}
					}
				}
				gameData <<= 97;
			}
			else
				gameData <<= 136;
			gameData += counter;
		}
	}

	function _vxInTeam(uint256 _team) internal pure returns(uint256) {
		uint _teamCount = 0;
		for (uint256 i = 0; i < 5; i++) {
			uint256 vxId = (_team >> (32 * i)) & 0xffffffff;
			_teamCount += vxId > 0 ? 1 : 0;
		}
		return _teamCount;
	}

	function _sumOfLevels(uint256[5] calldata _levels) internal pure returns(uint256 sum) {
		for(uint256 i = 0; i < 5; i++)
			sum += _levels[i];
	}

	function _maxLevel(uint256[5] calldata _levels) internal pure returns(uint256 max) {
		for(uint256 i = 0; i < 5; i++)
			if (_levels[i] > max)
				max = _levels[i];
	}

	function getReqForLvl(uint256 _currentLevel) external view override returns(uint256 exp, uint256 kongium) {
		if (_currentLevel == 1) {
			exp = 10;
			kongium = 10;
		}
		else if (_currentLevel == 2) {
			exp = 20;
			kongium = 40;
		}
		else if (_currentLevel == 3) {
			exp = 40;
			kongium = 60;
		}
		else if (_currentLevel == 4) {
			exp = 60;
			kongium = 100;
		}
		else if (_currentLevel == 5) {
			exp = 80;
			kongium = 150;
		}
		else if (_currentLevel == 6) {
			exp = 100;
			kongium = 200;
		}
		else if (_currentLevel == 7) {
			exp = 125;
			kongium = 250;
		}
		else if (_currentLevel == 8) {
			exp = 150;
			kongium = 400;
		}
		else if (_currentLevel == 9) {
			exp = 175;
			kongium = 500;
		}
		else if (_currentLevel == 10) {
			exp = 200;
			kongium = 600;
		}
		else if (_currentLevel == 11) {
			exp = 225;
			kongium = 700;
		}
		else if (_currentLevel == 12) {
			exp = 250;
			kongium = 800;
		}
		else if (_currentLevel == 13) {
			exp = 275;
			kongium = 900;
		}
		else if (_currentLevel == 14) {
			exp = 300;
			kongium = 1000;
		}
		else if (_currentLevel == 15) {
			exp = 325;
			kongium = 1200;
		}
		else if (_currentLevel == 16) {
			exp = 350;
			kongium = 1400;
		}
		else if (_currentLevel == 17) {
			exp = 400;
			kongium = 1600;
		}
		else if (_currentLevel == 18) {
			exp = 450;
			kongium = 1800;
		}
		else if (_currentLevel == 19) {
			exp = 500;
			kongium = 2000;
		}
		else{
			exp = uint256(-1);
			kongium = uint256(-1);
		}
	}

	function generateSeed(uint256 _seed) internal view returns(uint256 rand) {
		rand = uint256(keccak256(abi.encodePacked(_seed)));
	}

	function _eventType(uint256 _blob) internal pure returns(uint256) {
		return _blob >> 205;
	}

	function _charmRequirement(uint256 _blob) internal pure returns(uint256) {
		return (_blob >> 203) & 3; // 0b11
	}

	function _teamSize(uint256 _blob) internal pure returns(uint256) {
		return (_blob >> 200) & 7; // 0b111
	}

	function _singleLevel(uint256 _blob) internal pure returns(uint256) {
		return (_blob >> 195) & 31; // 0b11111
	}

	function _totalLevel(uint256 _blob) internal pure returns(uint256) {
		return (_blob >> 188) & 127; // 0b1111111
	}

	function _tokenType(uint256 _blob) internal pure returns(uint256) {
		return (_blob >> 177) & 2047; // 0b11111111111
	}

	function _chance(uint256 _blob) internal pure returns(uint256) {
		return (_blob >> 160) & 131071; // 0b11111111111111111
	}

	function _token(uint256 _blob) internal pure returns(address) {
		return address(uint160(_blob & 1461501637330902918203684832716283019655932542975));
	}

	function _reward(uint256 _blob) internal pure returns(uint256) {
		return _blob >> 128;
	}

	function _amount(uint256 _blob) internal pure returns(uint256) {
		return _blob & 0xffffffffffffffffffffffffffffffff;
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "IERC165.sol";

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.2;

import "IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "Context.sol";
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
contract Ownable is Context {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}