// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC721Enumerable.sol";
import "./utils.sol";

struct GameInfo {
    address[] ERC721;
    address[] ERC20;
    uint256 commissionRate;
}

contract GameController is Ownable {
    GameInfo[] private _games;

    modifier checkGameId(uint256 gameId) {
        require(0 <= gameId && gameId < _games.length, "Game id incorrect");
        _;
    }

    event TransferedERC721(
        uint256 indexed gameId, 
        address indexed ERC721,
        uint256 tokenId, 
        address owner,
        address indexed recipient
    );

    event TransferedERC20(
        uint256 indexed gameId, 
        address indexed ERC20,
        uint256 amount, 
        address owner,
        address indexed recipient
    );

    constructor() {
    }

    function AddGame(
        address[] calldata ERC721,
        address[] calldata ERC20,
        uint256 commissionRate
    ) public onlyOwner {
        _games.push(GameInfo(
            ERC721,
            ERC20,
            commissionRate
        ));
    }

    function AddERC721ToGame(uint256 gameId, address ERC721) public onlyOwner checkGameId(gameId) {
        _games[gameId].ERC721.push(ERC721);
    }

    function AddERC20ToGame(uint256 gameId, address ERC20) public onlyOwner checkGameId(gameId) {
        _games[gameId].ERC20.push(ERC20);
    }
    
    function SetCommissionRate(uint256 gameId, uint256 commissionRate) public onlyOwner checkGameId(gameId) {
        _games[gameId].commissionRate = commissionRate;
    }

    function SetGame(
        uint256 gameId, 
        address[] calldata ERC721,
        address[] calldata ERC20,
        uint256 commissionRate
    ) public onlyOwner checkGameId(gameId) {
        _games[gameId] = GameInfo(
            ERC721,
            ERC20,
            commissionRate
        );
    }

    function TransferERC721(
        uint256 gameId, 
        address ERC721,
        uint256 tokenId, 
        address owner,
        address recipient
    ) public onlyOwner checkGameId(gameId) {
        IERC721Enumerable(ERC721).safeTransferFrom(owner, recipient, tokenId);

        emit TransferedERC721(gameId, ERC721, tokenId, owner, recipient);
    }

    function TransferERC721Batch(
        uint256 gameId, 
        address[] calldata ERC721, 
        uint256[] calldata tokenId,
        address[] calldata owner, 
        address recipient
    ) public onlyOwner {
        require(
            ERC721.length == tokenId.length &&
            tokenId.length == owner.length
        , "All arrays must be have the same length");
        require(ERC721.length <= 20, "Length must be less or equal 20");

        for (uint256 i = 0; i < ERC721.length; i++) {
            TransferERC721(gameId, ERC721[i], tokenId[i], owner[i], recipient);
        }
    }

    function TransferERC20(
        uint256 gameId, 
        address ERC20,
        uint256 amount, 
        address owner,
        address recipient
    ) public onlyOwner checkGameId(gameId) {
        IERC20(ERC20).transferFrom(owner, recipient, amount);

        emit TransferedERC20(gameId, ERC20, amount, owner, recipient);
    }

    function TransferERC20Batch(
        uint256 gameId, 
        address[] calldata ERC20, 
        uint256[] calldata amount, 
        address[] calldata owner,
        address recipient
    ) public onlyOwner {
        require(
            ERC20.length == amount.length &&
            amount.length == owner.length
        , "All arrays must be have the same length");
        require(ERC20.length <= 20, "Length must be less or equal 20");

        for (uint256 i = 0; i < ERC20.length; i++) {
            TransferERC20(gameId, ERC20[i], amount[i], owner[i], recipient);
        }
    }                                                                         

    function MultiTransfer(
        uint256 gameId, 
        address ERC721, 
        uint256 tokenId, 
        address ERC20, 
        uint256 amount, 
        address owner,
        address recipient
    ) public onlyOwner checkGameId(gameId) {
        TransferERC721(gameId, ERC721, tokenId, owner, recipient);
        TransferERC20(gameId, ERC20, amount, owner, recipient);
    }

    function MultiTransferBatch(
        uint256 gameId, 
        address[] calldata ERC721, 
        uint256[] calldata tokenId, 
        address[] calldata ERC20, 
        uint256[] calldata amount,
        address[] memory owner,
        address recipient
    ) public onlyOwner {
        require(
            ERC721.length == tokenId.length &&
            tokenId.length == ERC20.length &&
            ERC20.length == amount.length &&
            amount.length == owner.length
        , "All arrays must be have the same length");
        require(ERC20.length <= 20, "Length must be less or equal 20");

        for (uint256 i = 0; i < ERC20.length; i++) {
            MultiTransfer(gameId, ERC20[i], tokenId[i], ERC20[i], amount[i], owner[i], recipient);
        }
    }

    function GetLength() view public returns (uint256) {
        return _games.length;
    }

    function GetGameInfo(uint256 gameId) view public checkGameId(gameId) returns (GameInfo memory) {
        return _games[gameId];
    }

    struct ERC721BalanceResponse {
        address ERC721;
        uint256 balance;
    }

    function GetERC721BalanceByOwner(
        uint256 gameId,
        address owner
    ) view public checkGameId(gameId) returns (ERC721BalanceResponse[] memory) {
        uint256 ERC721_length = _games[gameId].ERC721.length;
        ERC721BalanceResponse[] memory result = new ERC721BalanceResponse[](ERC721_length);

        for (uint256 i = 0; i < ERC721_length; i++) {
            address ERC721 = _games[gameId].ERC721[i];
            result[i].ERC721 = ERC721;

            result[i].balance = IERC721Enumerable(ERC721).balanceOf(owner);
        }

        return result;
    }

    function GetERC721TokenByOwner(
        address ERC721,
        uint256 startIndex,
        uint256 finishIndex,
        address owner
    ) view public returns (uint256[] memory) {
        uint256[] memory result = new uint256[](finishIndex - startIndex);

        for (uint256 i = startIndex; i < finishIndex; i++) {
            result[i] = IERC721Enumerable(ERC721).tokenOfOwnerByIndex(owner, i);
        }

        return result;
    }

    struct ERC20Response {
        address ERC20;
        uint256 amount;
    }

    function GetERC20AllowedByOwner(
        uint256 gameId, 
        address owner
    ) view public checkGameId(gameId) returns (ERC20Response[] memory) {
        uint256 ERC20_length = _games[gameId].ERC20.length;
        ERC20Response[] memory result = new ERC20Response[](ERC20_length);

        for (uint256 i = 0; i < ERC20_length; i++) {
            address ERC20 = _games[gameId].ERC20[i];
            result[i].ERC20 = ERC20;
            result[i].amount = IERC20(ERC20).allowance(owner, address(this));
        }

        return result;
    }

    function GetERC20BalanceByOwner(
        uint256 gameId, 
        address owner
    ) view public checkGameId(gameId) returns (ERC20Response[] memory) {
        uint256 ERC20_length = _games[gameId].ERC20.length;
        ERC20Response[] memory result = new ERC20Response[](ERC20_length);

        for (uint256 i = 0; i < ERC20_length; i++) {
            address ERC20 = _games[gameId].ERC20[i];
            result[i].ERC20 = ERC20;
            result[i].amount = IERC20(ERC20).balanceOf(owner);
        }

        return result;
    }
}