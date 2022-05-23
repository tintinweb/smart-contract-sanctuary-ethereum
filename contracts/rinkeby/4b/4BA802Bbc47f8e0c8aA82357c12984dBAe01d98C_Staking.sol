// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./IERC721.sol";

struct Token {
    address collection;
    uint256 tokenId;
}

struct Stake {
    uint256 deposit;
    uint256 reward;
    uint256 startTime;
    uint256 lastUpdateTime;
    Token[] tokens;
}

contract Staking is Ownable, ReentrancyGuard {

    // ----- STATE VARIABLES ----- //
    mapping(address => Stake) _stakes;
    mapping(address => uint256) _tokenMultipliers;
    mapping(address => mapping(uint256 => address)) _tokenOwners;
    mapping(address => uint256) _lastIndexes;

    IERC20 _token;
    uint256 _totalStake;
    uint256 _monthReward;
    uint256 _denominator = 100;


    // ----- CONSTRUCTOR -----//
    constructor(address token) {
        _token = IERC20(token);
    }


    // ----- EVENTS ----- //
    event Deposit(address indexed account, uint256 amount);
    event Deposit(address indexed account, address[] collections, uint256[] tokenIds);
    event Staked(address indexed account, uint256 timestamp);
    event Unstaked(address indexed account, uint256 timestamp);
    event Withdraw(address indexed account, uint256 amount);
    event Withdraw(address indexed account, address[] collections, uint256[] tokenIds);
    event Claim(address indexed account, uint256 amount);


    // ----- VIEWS ----- //
    function isStakeholder(address account) external view returns (bool) {
        return _stakes[account].deposit > 0;
    }

    function stakeOf(address account) external view returns (uint256) {
        return _stakes[account].deposit;
    }


    // ----- MUTATION FUNCTIONS ----- //
    function deposit(uint256 amount) external {
        require(amount > 0, "Deposit: amount is zero");
        require(_token.transferFrom(_msgSender(), address(this), amount), "Deposit: failed to transfer tokens");

        _stakes[_msgSender()].deposit += amount;
        _totalStake += amount;

        emit Deposit(_msgSender(), amount);
    }

    function deposit(address[] memory collections, uint256[] memory tokenIds) external {
        require(collections.length == tokenIds.length, "Deposit: array length mismatch");
        require(collections.length > 0, "Deposit: array length is zero");

        for(uint256 i; i < collections.length; i++) {
                        
            IERC721(collections[i]).safeTransferFrom(_msgSender(), address(this), tokenIds[i]);
            _tokenOwners[collections[i]][tokenIds[i]] = _msgSender();
            _stakes[_msgSender()].tokens.push(Token(collections[i], tokenIds[i]));
        }

        emit Deposit(_msgSender(), collections, tokenIds);
    }

    function stake() external {
        require(_stakes[_msgSender()].startTime == 0, "Stake: it has already started");
        require(_stakes[_msgSender()].deposit > 0, "Stake: deposit is zero");

        _stakes[_msgSender()].startTime = block.timestamp;
        _stakes[_msgSender()].lastUpdateTime = block.timestamp;

        emit Staked(_msgSender(), block.timestamp);
    }

    function unstake() external {
        require(_stakes[_msgSender()].startTime > 0, "Unstake: it has already ended");

        _stakes[_msgSender()].startTime = 0;
        _lastIndexes[_msgSender()] = 0;

        emit Unstaked(_msgSender(), block.timestamp);
    }

    function withdraw() external nonReentrant {
        require(_stakes[_msgSender()].startTime == 0, "Withdraw: now in staking");
        require(_stakes[_msgSender()].deposit > 0, "Withdraw: no deposit");
        require(_token.transfer(_msgSender(), _stakes[_msgSender()].deposit), "Withdraw: failed to transfer tokens");

        _claimReward(_msgSender());

        _totalStake -= _stakes[_msgSender()].deposit;
        emit Withdraw(_msgSender(), _stakes[_msgSender()].deposit);
        _stakes[_msgSender()].deposit = 0;

        uint256 tokenCount = _stakes[_msgSender()].tokens.length;
        if(tokenCount < 1) {
            return;
        }

        address[] memory collections = new address[](tokenCount);
        uint256[] memory tokenIds = new uint256[](tokenCount);

        for(uint256 i; i < tokenCount; i++) {
            Token storage token = _stakes[_msgSender()].tokens[i];
            IERC721(token.collection).safeTransferFrom(address(this), _msgSender(), token.tokenId);
            collections[i] = token.collection;
            tokenIds[i] = token.tokenId;
        }
        delete _stakes[_msgSender()].tokens;

        emit Withdraw(_msgSender(), collections, tokenIds);
    }

    function claimReward() external nonReentrant {
        _claimReward(_msgSender());
    }

    function _claimReward(address account) internal {
        _updateReward(account);
        if(_stakes[account].reward > 0) {
            require(_token.transfer(account, _stakes[account].reward), "Claim: failed to transfer tokens");
            emit Claim(account, _stakes[account].reward);
            _stakes[account].reward = 0;
        }
    }

    function _updateReward(address account) internal {
        uint256 monthCount = (block.timestamp - _stakes[account].startTime) / 30 days;
        if(monthCount <= _lastIndexes[account]) {
            return;
        }

        for(uint256 idx = _lastIndexes[account] + 1; idx <= monthCount; idx++) {
            _stakes[account].reward += _calculateReward(account, idx);
        }
        _lastIndexes[account] = monthCount;
    }

    function _calculateReward(address account, uint256 index) internal view returns (uint256) {
        uint256 bonus;
        uint256 tokenMultiplier;

        for(uint256 i; i < _stakes[account].tokens.length; i++) {
            address collection = _stakes[account].tokens[i].collection;
            tokenMultiplier += _tokenMultipliers[collection];
        }
        
        if(index == 1) {
            bonus = _stakes[account].deposit * tokenMultiplier / _denominator;
        } else if(index > 1 && index < 4) {
            bonus = _stakes[account].deposit * (tokenMultiplier + 25) / _denominator;
        } else if(index > 3 && index < 7) {
            bonus = _stakes[account].deposit * (tokenMultiplier + 50) / _denominator;
        } else if(index > 6 && index < 13) {
            bonus = _stakes[account].deposit * (tokenMultiplier + 75) / _denominator;
        } else if(index > 12) {
            bonus = _stakes[account].deposit * (tokenMultiplier + 100) / _denominator;
        }

        return _monthReward * (_stakes[account].deposit + bonus) / (_totalStake + bonus);
    }


    // ----- RESTRICTED FUNCTIONS -----//
    function setMonthReward(uint256 value) external onlyOwner {
        _monthReward = value;
    }

    function setTokenMultiplier(address collection, uint256 value) external onlyOwner {
        _tokenMultipliers[collection] = value;
    }

    function setPrecision(uint256 value) external onlyOwner {
        _denominator = value;
    }

    function setTokenAddress(address token) external onlyOwner {
        _token = IERC20(token);
    }
}