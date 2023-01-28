/**
 *Submitted for verification at Etherscan.io on 2023-01-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library SafeMath {

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {

            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }


    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }


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

library Address {

    function isContract(address account) internal view returns (bool) {


        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }


    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

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

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

contract CoinFlip is Ownable {
    using Address for address;
    using SafeMath for uint256;

    event GameStarted(
        address indexed better,
        address token,
        uint256 wager,
        uint8 predictedOutcome,
        uint32 id
    );

    event GameFinished(
        address indexed better,
        address token,
        bool winner,
        uint256 wager,
        uint32 id
    );

    event PayoutComplete(
        address indexed winner,
        address token,
        uint256 winnings
    );

    event DevFeeReceiverChanged(
        address oldReceiver,
        address newReceiver
    );

    event HouseFeeReceiverChanged(
        address oldReceiver,
        address newReceiver
    );

    event DevFeePercentageChanged(
        uint8 oldPercentage,
        uint8 newPercentage
    );

    event HouseFeePercentageChanged(
        uint8 oldPercentage,
        uint8 newPercentage
    );

    event ReferrerFeePercentageChanged(
        uint8 oldPercentage,
        uint8 newPercentage
    );

    struct Game {
        address better;
        address token;
        uint32 id;
        uint8 predictedOutcome;
        bool finished;
        bool winner;
        uint256 wager;
        uint256 startBlock;
    }

    struct Queue {
        uint32 start;
        uint32 end;
    }

    address public _houseFeeReceiver = address(0x5BAa2Ff2696258ad36727dE8254B7d505600d333);
    uint8 public _houseFeePercentage = 30; //3%

    address public _devFeeReceiver = address(0x5BAa2Ff2696258ad36727dE8254B7d505600d333);
    uint8 public _devFeePercentage = 3; //0.3%

    uint8 public _referrerFeePercentage = 5; // 0.5%

    mapping (address => bool) public _team;
    mapping (address => bool) public _isBlacklisted;

    // Game Details
    mapping (uint256 => Game) public _games; // Game ID -> Game
    Queue private _queuedGames;
    bool _gameEnabled = true; // If we want to pause the flip game
    uint32 public _queueResetSize = 1; // How many games we want to queue before finalizing a game
    uint256 public _blockWaitTime = 2; // How many blocks we want to wait before finalizing a game
    uint256 private _globalQueueSize;
    mapping (address => mapping (address => uint256)) public _winnings;
    mapping (address => uint256) public _minBetForToken;
    mapping (address => uint256) public _maxBetForToken;
    mapping (address => address) public _referrer;

    modifier onlyTeam {
        _onlyTeam();
        _;
    }

    function _onlyTeam() private view {
        require(_team[_msgSender()], "Only a team member may perform this action");
    }

    constructor() 
    {
        _team[owner()] = true;
    }

    // To recieve BNB from anyone, including the router when swapping
    receive() external payable {}

    function withdrawBNB(uint256 amount) external onlyOwner {
        (bool sent, bytes memory data) = _msgSender().call{value: amount}("");
        require(sent, "Failed to send BNB");
    }

    function enterGame(uint256 wager, uint8 outcome, address token, address referrer) external payable {
        require(_gameEnabled, "Game is currently paused");
        require(!_isBlacklisted[_msgSender()], "This user is blacklisted");
        require(!(_msgSender().isContract()), "Contracts are not allowed to play the game");
        require(msg.sender == tx.origin, "Sender must be the same as the address that started the tx");

        IERC20 gameToken = IERC20(token);
        if (_minBetForToken[token] != 0) {
            require(wager >= _minBetForToken[token], "This wager is lower than the minimum bet for this token");
        }
        if (_maxBetForToken[token] != 0) {
            require(wager <= _maxBetForToken[token], "This wager is larger than the maximum bet for this token");
        }
        require(outcome < 2, "Must choose heads or tails (0 or 1)");

        if (token != address(0x0)) {
            require(wager <= gameToken.balanceOf(address(this)).div(2), "Can't bet more than the amount available in the contract to pay you");
            gameToken.transferFrom(_msgSender(), address(this), wager);
        } else {
            require(wager <= address(this).balance.div(2), "Can't bet more than the amount available in the contract to pay you");
            require(msg.value == wager, "Must send same amount as specified in wager");
        }

        if (referrer != address(0x0) && referrer != _msgSender() && (_referrer[_msgSender()] == address(0x0))) {
            _referrer[_msgSender()] = referrer;
        }

        emit GameStarted(_msgSender(), token, wager, outcome, _queuedGames.end);
        _games[_queuedGames.end++] = Game({better: _msgSender(), token: token, id: _queuedGames.end, predictedOutcome: outcome, finished: false, winner: false, wager: wager, startBlock: block.number});
        _globalQueueSize++;

        completeQueuedGames();
    }

    function completeQueuedGames() internal {
        while (_globalQueueSize > _queueResetSize) {
            Game storage game = _games[_queuedGames.start];
            if (block.number < game.startBlock.add(_blockWaitTime) ||
                game.better == _msgSender()) {
                // Wait _blockWaitTime before completing this game, to avoid exploits.
                // Don't allow someone to complete their own game
                break;
            }
            _queuedGames.start++;
            _globalQueueSize--;

            game.winner = (rand() % 2) == game.predictedOutcome;

            if (game.winner) {
                _winnings[game.better][game.token] += (game.wager * 2);
            }

            game.finished = true;

            emit GameFinished(game.better, game.token, game.winner, game.wager, game.id);
        }
    }

    function rand() public view returns(uint256)
    {
        uint256 seed = uint256(keccak256(abi.encodePacked(
            block.timestamp + block.difficulty +
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
            block.gaslimit + 
            ((uint256(keccak256(abi.encodePacked(_msgSender())))) / (block.timestamp)) +
            block.number + _globalQueueSize
        )));

        return seed;
    }

    // If you need to withdraw BNB, tokens, or anything else that's been sent to the contract
    function withdrawToken(address _tokenContract, uint256 _amount) external onlyOwner {
        IERC20 tokenContract = IERC20(_tokenContract);
        
        // transfer the token from address of this contract
        // to address of the user (executing the withdrawToken() function)
        tokenContract.transfer(msg.sender, _amount);
    }

    function setTeamMember(address member, bool isTeamMember) external onlyOwner {
        _team[member] = isTeamMember;
    }

    function setHouseFeeReceiver(address newReceiver) external onlyOwner {
        require(newReceiver != address(0x0), "Can't set the zero address as the receiver");
        require(newReceiver != _houseFeeReceiver, "This is already the house fee receiver");

        emit HouseFeeReceiverChanged(_houseFeeReceiver, newReceiver);

        _houseFeeReceiver = newReceiver;
    }

    function setHouseFeePercentage(uint8 newPercentage) external onlyOwner {
        require(newPercentage != _houseFeePercentage, "This is already the house fee percentage");
        require(newPercentage <= 40, "Cannot set house fee percentage higher than 4 percent");

        emit HouseFeePercentageChanged(_houseFeePercentage, newPercentage);

        _houseFeePercentage = newPercentage;
    }

    function setDevFeeReceiver(address newReceiver) external onlyOwner {
        require(newReceiver != address(0x0), "Can't set the zero address as the receiver");
        require(newReceiver != _devFeeReceiver, "This is already the dev fee receiver");

        emit DevFeeReceiverChanged(_devFeeReceiver, newReceiver);

        _devFeeReceiver = newReceiver;
    }

    function setDevFeePercentage(uint8 newPercentage) external onlyOwner {
        require(newPercentage != _devFeePercentage, "This is already the dev fee percentage");
        require(newPercentage <= 5, "Cannot set dev fee percentage higher than 0.5 percent");

        emit DevFeePercentageChanged(_devFeePercentage, newPercentage);

        _devFeePercentage = newPercentage;
    }

    function setReferrerFeePercentage(uint8 newPercentage) external onlyOwner {
        require(newPercentage != _referrerFeePercentage, "This is already the referrer fee percentage");
        require(newPercentage <= 20, "Cannot set dev fee percentage higher than 2 percent");

        emit ReferrerFeePercentageChanged(_referrerFeePercentage, newPercentage);

        _referrerFeePercentage = newPercentage;
    }

    function setQueueSize(uint32 newSize) external onlyTeam {
        require(newSize != _queueResetSize, "This is already the queue size");

        _queueResetSize = newSize;
    }

    function setGameEnabled(bool enabled) external onlyTeam {
        require(enabled != _gameEnabled, "Must set a new value for gameEnabled");

        _gameEnabled = enabled;
    }

    function setMinBetForToken(address token, uint256 minBet) external onlyTeam {
        _minBetForToken[token] = minBet;
    }

    function setMaxBetForToken(address token, uint256 maxBet) external onlyTeam {
        _maxBetForToken[token] = maxBet;
    }

    function setBlacklist(address wallet, bool isBlacklisted) external onlyTeam {
        _isBlacklisted[wallet] = isBlacklisted;
    }

    function forceCompleteQueuedGames() external onlyTeam {
        completeQueuedGames();
    }

    function claimWinnings(address token) external {
        require(!_isBlacklisted[_msgSender()], "This user is blacklisted");
        uint256 winnings = _winnings[_msgSender()][token];
        require(winnings > 0, "This user has no winnings to claim");
        IERC20 gameToken = IERC20(token);

        if (token != address(0x0)) {
            require(winnings <= gameToken.balanceOf(address(this)), "Not enough tokens in the contract to distribute winnings");
        } else {
            require(winnings <= address(this).balance, "Not enough BNB in the contract to distribute winnings");
        }

        delete _winnings[_msgSender()][token];

        uint256 feeToHouse = winnings.mul(_houseFeePercentage).div(1000);
        uint256 feeToDev = winnings.mul(_devFeePercentage).div(1000);
        uint256 feeToReferrer = 0;

        address referrer = _referrer[_msgSender()];
        if (referrer != address(0x0)) {
            feeToReferrer = winnings.mul(_referrerFeePercentage).div(1000);
        }

        uint256 winningsToUser = winnings.sub(feeToHouse).sub(feeToDev).sub(feeToReferrer);

        if (token != address(0x0)) {
            gameToken.transfer(_houseFeeReceiver, feeToHouse);
            gameToken.transfer(_devFeeReceiver, feeToDev);

            if (feeToReferrer > 0) {
                gameToken.transfer(referrer, feeToReferrer);
            }

            gameToken.transfer(_msgSender(), winningsToUser);
        } else {
            _devFeeReceiver.call{value: feeToDev}("");
            _houseFeeReceiver.call{value: feeToHouse}("");

            if (feeToReferrer > 0) {
                referrer.call{value: feeToReferrer}("");
            }

            _msgSender().call{value: winningsToUser}("");
        }

        completeQueuedGames();

        emit PayoutComplete(_msgSender(), token, winningsToUser);
    }
}