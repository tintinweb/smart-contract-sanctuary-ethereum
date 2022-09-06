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
        uint256 amount;
        uint256 price;
        bool open;
        uint8 playerNumber;
        address[6] players;
    }
    // token > tokenId > GameInfo
    mapping(address => mapping(uint256 => GameInfo)) public gameInfos;

    constructor() {}

    receive() payable external {}

    event OperationalInfo(address indexed token, uint256 indexed tokenId, address indexed user, uint operation);

    function pledgeNFT(address token, uint256 tokenId, uint256 amount) public {
        require(tokenId > 0, "TokenId error");

        GameInfo storage _gameInfo = gameInfos[token][tokenId];
        require(_gameInfo.playerNumber == 0, "Player not redeemed");
        _gameInfo.owner = msg.sender;
        _gameInfo.amount = amount;
        _gameInfo.price = amount / 6;
        _gameInfo.open = true;

        ERC721(token).safeTransferFrom(msg.sender, address(this), tokenId);

        userPledgeNFTInfos[msg.sender][token][tokenId] = true;

        emit OperationalInfo(token, tokenId, msg.sender, uint(Operation.PledgeNFT));
    }

    function redeemNFT(address token, uint256 tokenId) public {
        require(userPledgeNFTInfos[msg.sender][token][tokenId], "TokenId error");
        GameInfo storage _gameInfo = gameInfos[token][tokenId];
        require(_gameInfo.owner == msg.sender, "TokenId error");
        if (_gameInfo.amount > 0) {
            require(_gameInfo.playerNumber == 0, "Cannot be redeemed");
        }

        delete userPledgeNFTInfos[msg.sender][token][tokenId];
        ERC721(token).safeTransferFrom(address(this), _gameInfo.owner, tokenId);

        if (_gameInfo.amount > 0) {
            _gameInfo.open = false;
        } else {
            delete gameInfos[token][tokenId];
        }

        emit OperationalInfo(token, tokenId, msg.sender, uint(Operation.RedeemNFT));
    }

    function pledgeETH(address token, uint256 tokenId) public payable {
        GameInfo storage _gameInfo = gameInfos[token][tokenId];
        require(_gameInfo.open, "The token is closed");
        require(_gameInfo.price <= msg.value, "Lack of balance");
        require(_gameInfo.playerNumber < 6, "The room is full");
        require(userPledgeETHInfos[msg.sender][token][tokenId] == 0, "Repeat pledge");
        
        userPledgeETHInfos[msg.sender][token][tokenId] = msg.value;
        _gameInfo.players[_gameInfo.playerNumber] = msg.sender;
        _gameInfo.playerNumber ++;

        emit OperationalInfo(token, tokenId, msg.sender, uint(Operation.PledgeETH));
    }

    function redeemETH(address token, uint256 tokenId, uint256 location) public {
        GameInfo storage _gameInfo = gameInfos[token][tokenId];
        require(_gameInfo.playerNumber < 6, "Cannot be redeemed");
        require(_gameInfo.players[location] == msg.sender, "Location error");

        _gameInfo.players[location] = address(0);
        _gameInfo.playerNumber --;

        uint256 _pledgeETH = userPledgeETHInfos[msg.sender][token][tokenId];
        if (_pledgeETH > 0) {
            delete userPledgeETHInfos[msg.sender][token][tokenId];
            safeTransferETH(msg.sender, _pledgeETH);
        }

        emit OperationalInfo(token, tokenId, msg.sender, uint(Operation.RedeemETH));
    }

    function settlement(address token, uint256 tokenId, uint8 winnerLocation) public onlyOwner {
        GameInfo storage _gameInfo = gameInfos[token][tokenId];
        require(_gameInfo.owner != address(0), "The token is closed");
        require(_gameInfo.open, "The token is closed");
        require(_gameInfo.playerNumber == 6, "The player number error");

        if (_gameInfo.amount > 0) {
            uint256 settleAmount = getSettleAmount(_gameInfo.amount);
            uint256 totalAmount = getTotalAmount(token, tokenId, _gameInfo.players);
            withdrawAmount += totalAmount - settleAmount;

            delete userPledgeETHInfos[_gameInfo.players[0]][token][tokenId];
            delete userPledgeETHInfos[_gameInfo.players[1]][token][tokenId];
            delete userPledgeETHInfos[_gameInfo.players[2]][token][tokenId];
            delete userPledgeETHInfos[_gameInfo.players[3]][token][tokenId];
            delete userPledgeETHInfos[_gameInfo.players[4]][token][tokenId];
            delete userPledgeETHInfos[_gameInfo.players[5]][token][tokenId];
            safeTransferETH(_gameInfo.owner, settleAmount);
        }

        address winner = _gameInfo.players[winnerLocation];
        delete userPledgeNFTInfos[_gameInfo.owner][token][tokenId];
        ERC721(token).safeTransferFrom(address(this), winner, tokenId);

        delete gameInfos[token][tokenId];
        
        emit OperationalInfo(token, tokenId, winner, uint(Operation.Settlement));
    }

    function withdraw(address to, uint256 amount) public onlyOwner {
        require(to != address(0), "address cannot empty");
        require(amount <= withdrawAmount, "Lack of balance");
        withdrawAmount -= amount;
        safeTransferETH(to, amount);
    }

    function setRate(uint8 newRate) public onlyOwner {
        require(newRate < 10000, "newRate error");
        rate = newRate;
    }

    function getSettleAmount(uint256 amount) internal view returns (uint256) {
        return amount - amount * rate / 10000;
    }

    function getTotalAmount(address token, uint256 tokenId, address[6] storage players) internal view returns (uint256) {
        uint256 amount;
        amount += userPledgeETHInfos[players[0]][token][tokenId];
        amount += userPledgeETHInfos[players[1]][token][tokenId];
        amount += userPledgeETHInfos[players[2]][token][tokenId];
        amount += userPledgeETHInfos[players[3]][token][tokenId];
        amount += userPledgeETHInfos[players[4]][token][tokenId];
        amount += userPledgeETHInfos[players[5]][token][tokenId];
        return amount;
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