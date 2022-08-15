// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721.sol";
import "./IERC721Receiver.sol";

contract TexasPoker is Ownable, IERC721Receiver {

    enum Operation {
        PledgeNFT, RedeemNFT, PledgeETH, RedeemETH, Settlement
    }

    uint8 public rate = 250;
    uint256 public withdrawAmount;

    // user > token > tokenId > true/false
    mapping(address => mapping(address => mapping(uint256 => bool))) public userPledgeNFTInfos;

    // user > token > tokenId > eth
    mapping(address => mapping(address => mapping(uint256 => uint256))) public userPledgeETHInfos;

    struct GameInfo {
        address owner;
        uint256 price;
        bool open;
        uint256 unlockTime;
        uint8 playerNumber;
        address[6] players;
    }
    // token > tokenId > GameInfo
    mapping(address => mapping(uint256 => GameInfo)) public gameInfos;

    constructor() {}

    receive() payable external {}

    event OperationalInfo(address indexed token, uint256 indexed tokenId, address indexed user, uint operation);

    function pledgeNFT(address token, uint256 tokenId, uint256 amount, uint256 unlockTime) public {
        require(tokenId > 0, "TokenId error");
        require(amount > 0, "Amount error");
        require(unlockTime > block.timestamp, "UnlockTime error");

        GameInfo storage _gameInfo = gameInfos[token][tokenId];
        require(_gameInfo.playerNumber == 0, "Player not redeemed");
        _gameInfo.owner = msg.sender;
        _gameInfo.price = amount / 6;
        _gameInfo.open = true;
        _gameInfo.unlockTime = unlockTime;

        ERC721(token).safeTransferFrom(msg.sender, address(this), tokenId);

        userPledgeNFTInfos[msg.sender][token][tokenId] = true;

        emit OperationalInfo(token, tokenId, msg.sender, uint(Operation.PledgeNFT));
    }

    function redeemNFT(address token, uint256 tokenId) public {
        require(userPledgeNFTInfos[msg.sender][token][tokenId], "TokenId error");

        GameInfo storage _gameInfo = gameInfos[token][tokenId];
        require(_gameInfo.owner == msg.sender, "TokenId error");
        require(_gameInfo.playerNumber == 6, "Cannot be redeemed");
        require(_gameInfo.unlockTime < block.timestamp || _gameInfo.playerNumber == 0, "Cannot be redeemed");

        ERC721(token).safeTransferFrom(address(this), msg.sender, tokenId);

        userPledgeNFTInfos[msg.sender][token][tokenId] = false;

        _gameInfo.open = false;

        emit OperationalInfo(token, tokenId, msg.sender, uint(Operation.RedeemNFT));
    }


    function pledgeETH(address token, uint256 tokenId, uint256 location) public payable {
        GameInfo storage _gameInfo = gameInfos[token][tokenId];
        require(_gameInfo.owner != address(0), "The token does not exist");
        require(_gameInfo.price <= msg.value, "Lack of balance");
        require(_gameInfo.open, "The token is closed");
        require(_gameInfo.unlockTime > block.timestamp, "The token is closed");
        require(_gameInfo.playerNumber < 6, "The room is full");
        require(_gameInfo.players[location] == address(0), "The location is occupied");

        require(userPledgeETHInfos[msg.sender][token][tokenId] == 0, "Repeat pledge");
        
        userPledgeETHInfos[msg.sender][token][tokenId] = msg.value;

        _gameInfo.players[location] = msg.sender;
        _gameInfo.playerNumber ++;

        emit OperationalInfo(token, tokenId, msg.sender, uint(Operation.PledgeETH));
    }

    function redeemETH(address token, uint256 tokenId, uint256 location) public {
        GameInfo storage _gameInfo = gameInfos[token][tokenId];
        require(_gameInfo.playerNumber < 6, "Cannot be redeemed");
        require(_gameInfo.players[location] == msg.sender, "Location error");
        uint256 _pledgeETH = userPledgeETHInfos[msg.sender][token][tokenId];
        require(_pledgeETH == _gameInfo.price, "Eth error");
        
        safeTransferETH(msg.sender, _pledgeETH);

        userPledgeETHInfos[msg.sender][token][tokenId] = 0;

        _gameInfo.players[location] = address(0);
        _gameInfo.playerNumber --;

        emit OperationalInfo(token, tokenId, msg.sender, uint(Operation.RedeemNFT));
    }

    function settlement(address token, uint256 tokenId, uint8 winnerLocation) public onlyOwner {
        GameInfo storage _gameInfo = gameInfos[token][tokenId];
        require(_gameInfo.owner != address(0), "The token is closed");
        require(_gameInfo.open, "The token is closed");
        require(_gameInfo.unlockTime > block.timestamp, "The token is closed");
        require(_gameInfo.playerNumber == 6, "The player number error");

        (uint256 amount, uint256 fee) = getAmount(_gameInfo.price);
        address owner = _gameInfo.owner;
        safeTransferETH(owner, amount);
        withdrawAmount = withdrawAmount + fee;
        userPledgeNFTInfos[_gameInfo.owner][token][tokenId] = false;
        
        address winner = _gameInfo.players[winnerLocation];
        ERC721(token).safeTransferFrom(address(this), winner, tokenId);
        userPledgeETHInfos[_gameInfo.players[0]][token][tokenId] = 0;
        userPledgeETHInfos[_gameInfo.players[1]][token][tokenId] = 0;
        userPledgeETHInfos[_gameInfo.players[2]][token][tokenId] = 0;
        userPledgeETHInfos[_gameInfo.players[3]][token][tokenId] = 0;
        userPledgeETHInfos[_gameInfo.players[4]][token][tokenId] = 0;
        userPledgeETHInfos[_gameInfo.players[5]][token][tokenId] = 0;

        _gameInfo.owner = address(0);
        _gameInfo.open = false;
        _gameInfo.playerNumber = 0;
        _gameInfo.players[0] = address(0);
        _gameInfo.players[1] = address(0);
        _gameInfo.players[2] = address(0);
        _gameInfo.players[3] = address(0);
        _gameInfo.players[4] = address(0);
        _gameInfo.players[5] = address(0);
        
        emit OperationalInfo(token, tokenId, owner, uint(Operation.Settlement));
    }

    function withdraw(address to, uint256 amount) public onlyOwner {
        require(to != address(0), "address cannot empty");
        require(amount <= withdrawAmount, "Lack of balance");
        safeTransferETH(to, amount);
    }

    function setRate(uint8 _rate) public onlyOwner {
        rate = _rate;
    }

    function getAmount(uint256 price) public view returns (uint256 settleAmount, uint256 fee) {
        uint256 _amount = price * 6;
        uint256 _fee = _amount * rate / 10000;
        return (_amount - _fee, _fee);
    }

    function getPlayers(address token, uint256 tokenId) public view returns (address[6] memory players) {
        return gameInfos[token][tokenId].players;
    }

    function getBlockTime() public view returns (uint256) {
        return block.timestamp;
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value : value}(new bytes(0));
        require(success, 'ETH_TRANSFER_FAILED');
    }
}