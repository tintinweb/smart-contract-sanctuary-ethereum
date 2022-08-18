/**
 *Submitted for verification at Etherscan.io on 2022-08-18
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}


pragma solidity >=0.8.0 <0.9.0;
pragma experimental ABIEncoderV2;


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    
    function mint(address addr, uint256 wormAmount) external;
    function burn(address addr, uint256 wormAmount) external;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract GameContract {
    struct PlayerInfo {
        uint seedNum;
        address playAddress;
        bytes taxaPublicKey;
        uint lockedAmount;
        uint lockedUntil;
        string gameId;
        bool isWinner;
        bool resultSubmitted;
        bool tokensClaimed;
    }

    struct GameInfo {
        string gameId;
        address[] playerAddressList;
        bytes[] playerPublicKeys;
        bool isCompleted;
    }

    mapping(string => uint) gameIdToInformationIndexMapper;
    GameInfo[] public allGameInfos;

    mapping(bytes => uint) playerToInformationIndexMapper;
    PlayerInfo[] public allPlayerInfos;

    // address -> gameId -> publickey
    mapping(address => mapping(string => bytes)) public playerAddressToPubKeys;

    mapping(address => uint256) public playerTotalTokens;
    mapping(address => uint256) public playerTotalLocked;

    uint32 gameTeamSize = 6;
    uint256 startIndex = 0;
    uint256 tokenLockDuration = 1200; // in seconds
    uint256 securityTokenAmount = 10 * 10 ** 18; // tokens in wei
    uint256 rewardTokens = 10 * 10 ** 18; // tokens in wei

    IERC20 public wormToken;


    constructor(IERC20 tokenAddress) {
        wormToken = tokenAddress;
    }

    /**
     * @dev The tokens need to be first approved to smart contract.
     * Once approved, the deposit function will be called where the tokens 
     * get deposited to the contract and added to wallet's total balance.
     *
     * @param amount The amount of tokens to deposit to contract.
     */
    function deposit(uint256 amount) external {
        require(amount <= wormToken.balanceOf(msg.sender), "Insufficient token balance.");
        
        wormToken.transferFrom(msg.sender, address(this), amount);
        playerTotalTokens[msg.sender] = playerTotalTokens[msg.sender] + amount;
    }

    /**
     * @dev Commit/Lock tokens from available tokens of user w.r.t. passed public key
     */
    function commitAndJoin(bytes memory taxaPublicKey, uint randomSeed, uint amountToLock) public {
        // check if public key already exists/joined
        require(!checkIfPubKeyExists(taxaPublicKey), "Public key already exists");

        // check available tokens for user to lock
        require(amountToLock <= playerTotalTokens[msg.sender] - playerTotalLocked[msg.sender], "Insufficient available token balance.");
        
        playerTotalLocked[msg.sender] = playerTotalLocked[msg.sender] + amountToLock;

        PlayerInfo memory newPlayInfo = PlayerInfo(
            randomSeed, 
            msg.sender, 
            taxaPublicKey, 
            amountToLock, 
            block.timestamp + tokenLockDuration, 
            '', 
            false,
            false,
            false
        );
        
        allPlayerInfos.push(newPlayInfo);
        playerToInformationIndexMapper[taxaPublicKey] = allPlayerInfos.length - 1;
    }

    function createGame(string memory gameId) internal returns (uint) {
        address[] memory defaultPlayerAddressList;
        bytes[] memory defaultPlayerPublicKeys;

        GameInfo memory gameInfo = GameInfo(gameId, defaultPlayerAddressList, defaultPlayerPublicKeys, false);
        allGameInfos.push(gameInfo);
        gameIdToInformationIndexMapper[gameId] = allGameInfos.length - 1;
        return allGameInfos.length - 1;
    }

    function getGameAddressList(string memory gameId) public view returns (address[] memory) {
        return allGameInfos[gameIdToInformationIndexMapper[gameId]].playerAddressList;
    }

    function startGame() public {
        require(allPlayerInfos.length - startIndex >= gameTeamSize, "Not enough joined players.");
        
        address[] memory currentPlayersInfo = new address[](gameTeamSize);
        bytes[] memory currentPlayersPublicKeys = new bytes[](gameTeamSize);
        uint[] memory seedNumbersInfo = new uint[](gameTeamSize);
        uint j = 0;

        for (uint i = startIndex; i < startIndex + gameTeamSize; i++) {
            currentPlayersInfo[j] = allPlayerInfos[i].playAddress;
            currentPlayersPublicKeys[j] = allPlayerInfos[i].taxaPublicKey;
            seedNumbersInfo[j] = allPlayerInfos[i].seedNum;
            j++;
        }

        // Fisher and Yates
        for (uint i = gameTeamSize - 1; i >= 1; i--) {
            uint randomHash = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, seedNumbersInfo[i], seedNumbersInfo[gameTeamSize - 1 - i]))) % i;
            if (randomHash != i) {
                address temp = currentPlayersInfo[i];
                currentPlayersInfo[i] = currentPlayersInfo[randomHash];
                currentPlayersInfo[randomHash] = temp;
            }
        }

        bytes memory contatenatedPlayerAddress;
        for (uint256 i = 0; i < currentPlayersInfo.length; i++) {
            contatenatedPlayerAddress = abi.encodePacked(contatenatedPlayerAddress, currentPlayersInfo[i]);
        }

        string memory gameId = toHex(keccak256(contatenatedPlayerAddress));
        uint gameIndex = createGame(gameId);

        for (uint i = startIndex; i < startIndex + gameTeamSize; i++) {
            allPlayerInfos[i].gameId = gameId;
            playerAddressToPubKeys[allPlayerInfos[i].playAddress][gameId] = allPlayerInfos[i].taxaPublicKey;
        }

        allGameInfos[gameIndex].playerAddressList = currentPlayersInfo;
        allGameInfos[gameIndex].playerPublicKeys = currentPlayersPublicKeys;

        startIndex = startIndex + gameTeamSize;
    }

    function toHex16(bytes16 data) internal pure returns (bytes32 result) {
        result = bytes32 (data) & 0xFFFFFFFFFFFFFFFF000000000000000000000000000000000000000000000000 |
            (bytes32 (data) & 0x0000000000000000FFFFFFFFFFFFFFFF00000000000000000000000000000000) >> 64;
        result = result & 0xFFFFFFFF000000000000000000000000FFFFFFFF000000000000000000000000 |
            (result & 0x00000000FFFFFFFF000000000000000000000000FFFFFFFF0000000000000000) >> 32;
        result = result & 0xFFFF000000000000FFFF000000000000FFFF000000000000FFFF000000000000 |
            (result & 0x0000FFFF000000000000FFFF000000000000FFFF000000000000FFFF00000000) >> 16;
        result = result & 0xFF000000FF000000FF000000FF000000FF000000FF000000FF000000FF000000 |
            (result & 0x00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000) >> 8;
        result = (result & 0xF000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000) >> 4 |
            (result & 0x0F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F00) >> 8;
        result = bytes32 (0x3030303030303030303030303030303030303030303030303030303030303030 +
            uint256 (result) +
            (uint256 (result) + 0x0606060606060606060606060606060606060606060606060606060606060606 >> 4 &
            0x0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F) * 7);
    }

    function toHex(bytes32 data) public pure returns (string memory) {
        return string(abi.encodePacked ("0x", toHex16 (bytes16 (data)), toHex16 (bytes16 (data << 128))));
    }

    function getPlayerInfo(bytes memory taxaPublicKey)
        public
        view
        returns (uint seedNumber, string memory gameId)
    {
        PlayerInfo memory currentPlayer = allPlayerInfos[playerToInformationIndexMapper[taxaPublicKey]];
        seedNumber = currentPlayer.seedNum;
        gameId = currentPlayer.gameId;
    }

    function checkIfPubKeyExists(bytes memory taxaPublicKey) public view returns(bool) {
        uint index = playerToInformationIndexMapper[taxaPublicKey];

        if(index != 0){
            return true;
        }
        else {
            if(allPlayerInfos.length > 0) {
                PlayerInfo memory currentPlayer = allPlayerInfos[0];
                
                if(keccak256(currentPlayer.taxaPublicKey) == keccak256(taxaPublicKey)) {
                    return true;
                }   
                else {
                    return false;
                }
            }
            else {
                return false;
            }
        }
    }

    function verifyPeer(bytes memory taxaPublicKey, string memory originalMessage, bytes memory signature, uint amountToLock)
        public
        view
        returns(bool)
    {
        PlayerInfo memory currentPlayer = allPlayerInfos[playerToInformationIndexMapper[taxaPublicKey]];
        
        if(convertPubKeyToETHAddress(taxaPublicKey) != getEthAddressFromSignature(originalMessage, signature)) {
            return false;
        }

        // Verify the locked tokens against this public key
        if(currentPlayer.lockedAmount >= amountToLock) {
            return true;
        }
        else {
            return false;
        }
    }
    
    // signature signed from opponent's public key
    function submitResult(bytes memory opponentPublicKey, string memory originalMessage, bytes memory signature)
        public
    {
        require(
            convertPubKeyToETHAddress(opponentPublicKey) == getEthAddressFromSignature(originalMessage, signature), 
            "Invalid signature"
        );

        PlayerInfo memory opponentPlayer = allPlayerInfos[playerToInformationIndexMapper[opponentPublicKey]];
        bytes memory userPublicKey = playerAddressToPubKeys[msg.sender][opponentPlayer.gameId];
        require(keccak256(userPublicKey) != keccak256(abi.encodePacked("")), "Public key not found for this address");

        PlayerInfo memory currentPlayer = allPlayerInfos[playerToInformationIndexMapper[userPublicKey]];
        
        // update game status 
        allGameInfos[gameIdToInformationIndexMapper[currentPlayer.gameId]].isCompleted = true;

        // update player result
        bool _result = (keccak256(abi.encodePacked(originalMessage)) == keccak256("winner"));
        allPlayerInfos[playerToInformationIndexMapper[userPublicKey]].isWinner = _result;
        allPlayerInfos[playerToInformationIndexMapper[userPublicKey]].resultSubmitted = true;
    }

    // player can claim tokens by passing public key
    function claimToken(bytes memory taxaPublicKey) public {
        PlayerInfo memory currentPlayer = allPlayerInfos[playerToInformationIndexMapper[taxaPublicKey]];
        
        require(currentPlayer.playAddress == msg.sender, "Unauthorized.");
        require(currentPlayer.resultSubmitted || block.timestamp >= currentPlayer.lockedUntil, "Result not submitted yet.");
        require(!currentPlayer.tokensClaimed, "Tokens already claimed.");

        GameInfo memory currentGame = allGameInfos[gameIdToInformationIndexMapper[currentPlayer.gameId]];
        require(currentGame.isCompleted, "Game is not completed yet.");

        allPlayerInfos[playerToInformationIndexMapper[taxaPublicKey]].tokensClaimed = true;

        // check if winner or loser (if locktime is passed and no result submitted then player will be treated as loser)
        if(currentPlayer.isWinner) {
            unlockAndWithdraw(msg.sender, currentPlayer.lockedAmount, currentPlayer.lockedAmount); // game + security tokens

            // mint reward tokens to user
            wormToken.mint(msg.sender, rewardTokens);
        }
        else {
            unlockAndWithdraw(msg.sender, currentPlayer.lockedAmount, currentPlayer.lockedAmount - rewardTokens); // less rewardTokens from withdraw amount
         
            // burn lost tokens from contract (deposited by user)
            wormToken.burn(address(this), rewardTokens);
        }
    }

    // if a player was disconnected, he/she can claim tokens by passing public key after lock time
    function claimDisconnectedUserToken(bytes memory taxaPublicKey) public {
        PlayerInfo memory currentPlayer = allPlayerInfos[playerToInformationIndexMapper[taxaPublicKey]];

        require(currentPlayer.playAddress == msg.sender, "Unauthorized.");
        require(block.timestamp >= currentPlayer.lockedUntil, "Locked time has not passed yet.");
        require(!currentPlayer.tokensClaimed, "Tokens already claimed.");

        GameInfo memory currentGame = allGameInfos[gameIdToInformationIndexMapper[currentPlayer.gameId]];
        require(!currentGame.isCompleted, "Game completed successfully.");
        
        allPlayerInfos[playerToInformationIndexMapper[taxaPublicKey]].tokensClaimed = true;

        // unlock and withdraw locked amount against this public key
        unlockAndWithdraw(msg.sender, currentPlayer.lockedAmount, currentPlayer.lockedAmount);
    }

    function getEthAddressFromSignature(string memory originalMessage, bytes memory signature)
        internal
        pure
        returns (address)
    {
        return recoverSigner(prefixed(originalMessage), signature);
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        require(sig.length == 65);

        assembly {
            // first 32 bytes, after the length prefix.
            r := mload(add(sig, 32))
            // second 32 bytes.
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes).
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    function recoverSigner(bytes32 message, bytes memory sig)
        internal
        pure
        returns (address)
    {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);

        return ecrecover(message, v, r, s);
    }

    /// builds a prefixed hash to mimic the behavior of eth_sign.
    function prefixed(string memory hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(stringLength(hash)), hash));
    }

    function stringLength(string memory s) internal pure returns (uint256) {
        return bytes(s).length;
    }

    function random() internal view returns(uint) {
      uint randomHash = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
      return randomHash % 1000;
    }

    /**
     * @dev Extracts ETH address from given public key.
     */
    function convertPubKeyToETHAddress(bytes memory publicKey) private pure returns (address) {
        bytes32 hash = keccak256(publicKey);

        return address(uint160(uint256(hash)));
    }

    function unlockAndWithdraw(address addr, uint unlockAmount, uint withdrawAmount) private {
        // deduct tokens from player's total and locked tokens
        playerTotalTokens[addr] = playerTotalTokens[addr] - unlockAmount;
        playerTotalLocked[addr] = playerTotalLocked[addr] - unlockAmount;

        // transfer tokens amount from contract to player
        wormToken.transfer(addr, withdrawAmount);
    }
}