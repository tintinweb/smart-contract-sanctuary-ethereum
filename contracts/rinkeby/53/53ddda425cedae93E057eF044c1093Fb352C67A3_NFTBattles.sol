/**
 *Submitted for verification at Etherscan.io on 2022-04-22
*/

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/**
 
                         ,@[email protected]@@ggg,
                        [email protected],
                      ,@[email protected],
                     [email protected],
                    @[email protected]
                  ,@$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$g,
                 g$$$$N*"'              "**%[email protected],
               ,@@*'                          "N$$$$$$$$$$$$$$$$$$$g
              /"                                  *[email protected],
                                                    "%$$$$$$$$$$$$$$$$k
                                                      '%$$$$$$$$$$$$$$$g
                                                        *$$$$$$$$$$$$$$$g
                                                       _,]$$$$$$$$$$$$$$$k
                                               ,,[email protected]@@$$$$$$$$$$$$$$$$$$$$
                                      _,,[email protected]@$$$$$$$$$$$$$$$$$$$$$$$$$$$$$F
                              ,,[email protected]@@$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
                     _,,[email protected]@$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
                   `"**N%$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
                            `"*N%$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
                                    `"**N%$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$[
                                             `"*N%$$$$$$$$$$$$$$$$$$$$$$$$
                                                     `"**%$$$$$$$$$$$$$$$F
                                                        ,@[email protected]
                                                       g$$$$$$$$$$$$$$$$
                                                     [email protected][email protected]
              ,                                   ,[email protected]$$$$$$$$$$$$$$$$F
               ]@g                             ,[email protected]$$$$$$$$$$$$$$$$$$"
                '[email protected]@g,                   ,[email protected]$$$$$$$$$$$$$$$$$$$$F
                  %[email protected]@@[email protected]@@$$$$$$$$$$$$$$$$$$$$$$$$F
                   "[email protected]"
                     %[email protected]*
                      ]$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$N"
                        $$$$[email protected]"
                         ]$$$$$$$$$$$$$$$$$$%M*"
                           `""""""""""'
    
 * NFT Battles!
 * https://nftbattles.xyz
 * https://celda.xyz
 * https://cells.land
 * https://discord.gg/cells
*/

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

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

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


interface IERC721 {
  function balanceOf(address owner) external view returns (uint256 balance);
}

interface IERC20 {
   function mint(address to, uint256 amount) external;
   function transfer(address recipient, uint256 amount) external returns (bool);
   function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
   function balanceOf(address account) external view returns (uint256);
   function allowance(address owner, address spender) external view returns (uint256);
}

interface INFTBattles {

  struct PlayerBoosts {
    uint[] attack;
    uint[] defense;
    uint[] health;
    uint[] celda;
    uint[] dust;
  }

  struct DailyBoosts {
    uint celda;
    uint dust;
    uint xp;
  }
  
  struct Player {
    address addr;
    uint wins;
		uint draws;
    uint losses;
    uint rank;
    uint level;
    uint xp;
    uint currentBattle;
		uint lastDay;
		uint playedToday;
    uint playStreak;
    PlayerBoosts boosts;
    DailyBoosts dailyBoosts;
  }

  struct Battle {
    uint battleId;
    uint state; // 0 = queue // 1 = started // 2 = finished
    uint createdDate;
    uint startedDate;
    uint finishedDate;
    address playerA;
    address playerB;
    address winner;
    int scoreA;
    int scoreB;
  }

  function getPlayer(address player) external view returns (Player memory);
  function getBattle(uint battleId) external view returns (Battle memory);
  function battlesPerDay() external view returns (uint);
  
}

interface IRewards {
  function giveLevelUpRewards(address addr, uint level) external;
  function giveBattleRewards(uint battleId, bool penalty) external;
  function getPlayerBoosts(address _player) external view returns (uint[] memory, uint[] memory, uint[] memory, uint[] memory, uint[] memory);
  function getDailyBoostsByPlayer(address _player) external view returns (INFTBattles.DailyBoosts memory);
  function importDataFromOldContract(address _player) external;
}

contract NFTBattles is Ownable {
  using ECDSA for bytes32;
  
  mapping (address => INFTBattles.Player) public players;
  mapping (address => uint[]) private battlesByPlayer;
  mapping (uint => INFTBattles.Battle) public battles;
  mapping (address => bool) public alreadyImported;
  
  address private signerAddress = 0x8E7c6DBdae809c79C9f8Aa0F9ACf05614b4EB548;
	address public cardsAddress;
  address public rewardsAddress;
  address public oldBattlesAddress;
  address[] public queue;
  uint public battleId = 0;
	uint public battlesPerDay = 20;
	uint public deckSize = 15;
  uint public startingRank = 1000;
  uint public startingXP = 0;
  uint public startingLevel = 0;
	uint private maxPlayerDiff = 1000;
  uint private claimLossWaitTime = 5 minutes;
	bool public battlesEnabled = true;

  uint[] public levels = [0, 10, 30, 60, 100, 150, 210, 280, 360, 450, 550, 662, 786, 922, 1070, 1230, 1402, 1586, 1782, 1990, 2210, 2444, 2692, 2954, 3230, 3520, 3824, 4142, 4474, 4820, 5180, 5556, 5948, 6356, 6780, 7220, 7676, 8148, 8636, 9140, 9660, 10198, 10754, 11328, 11920, 12530, 13158, 13804, 14468, 15150, 15850, 16570, 17310, 18070, 18850, 19650, 20470, 21310, 22170, 23050, 23950, 24872, 25816, 26782, 27770, 28780, 29812, 30866, 31942, 33040, 34160, 35304, 36472, 37664, 38880, 40120, 41384, 42672, 43984, 45320, 46680, 48066, 49478, 50916, 52380, 53870, 55386, 56928, 58496, 60090, 61710, 63358, 65034, 66738, 68470, 70230, 72018, 73834, 75678, 77550, 79450];
	
  event BattleCreated(INFTBattles.Battle battle, INFTBattles.Player playerA);
  event BattleStarted(INFTBattles.Battle battle, INFTBattles.Player playerA, INFTBattles.Player playerB);
  event BattleFinished(INFTBattles.Battle battle, INFTBattles.Player playerA, INFTBattles.Player playerB, int scoreA, int scoreB, address winner);
  event LevelUp(address player, uint level);

  constructor(address _cardsAddress, address _oldBattlesAddress, uint _startingBattleId) {
    cardsAddress = _cardsAddress;
    oldBattlesAddress = _oldBattlesAddress;
    battleId = _startingBattleId;
  }

  function joinBattle() public returns (uint) {
		require(battlesEnabled, "Battles aren't enabled");
    require(players[msg.sender].currentBattle == 0, "Already joined");
		require(cardsAddress == address(0) || IERC721(cardsAddress).balanceOf(msg.sender) >= deckSize, "Needs a deck to play");
    
    INFTBattles.Battle memory battle;
    INFTBattles.Player memory player;

    if (players[msg.sender].addr != address(0)) {
      player = players[msg.sender];
    } else {
      if (oldBattlesAddress != address(0) && !alreadyImported[msg.sender]) {
        player = importDataFromOldContract(msg.sender);
      }
      if (player.addr == address(0)) {
        player.addr = msg.sender;
        player.rank = startingRank;
        player.xp = startingXP;
        player.level = startingLevel;
        player.playedToday = 0;
        player.lastDay = block.timestamp;
      }
    }
    
    if (block.timestamp > player.lastDay + 24 hours) {
      if (block.timestamp < player.lastDay + 48 hours)
        player.playStreak += 1;
      else
        player.playStreak = 1;

      player.lastDay = block.timestamp;
      player.playedToday = 0;
		}
    
    uint bestMatch = findBestMatch(player.rank, 100);

    if (bestMatch != 999999) {
      INFTBattles.Player storage opponent;
      opponent = players[queue[bestMatch]];
      battle = battles[opponent.currentBattle];
      battle.playerB = msg.sender;
      battle.state = 1;
      battle.startedDate = block.timestamp;

      player.currentBattle = battle.battleId;
      battlesByPlayer[player.addr].push(battle.battleId);
      battlesByPlayer[opponent.addr].push(battle.battleId);
      player.playedToday += 1;
      opponent.playedToday += 1;
      player.boosts = getBoosts(player.addr);
      opponent.boosts = getBoosts(opponent.addr);
      player.dailyBoosts = IRewards(rewardsAddress).getDailyBoostsByPlayer(player.addr);
      opponent.dailyBoosts = IRewards(rewardsAddress).getDailyBoostsByPlayer(opponent.addr);

      removeFromQueue(bestMatch);

      emit BattleStarted(battle, opponent, player);
    } else {
      battle.battleId = nextBattleId();
      battle.playerA = msg.sender;
      battle.state = 0;
      battle.createdDate = block.timestamp;

      player.currentBattle = battle.battleId;
      player.boosts = getBoosts(player.addr);
      player.dailyBoosts = IRewards(rewardsAddress).getDailyBoostsByPlayer(player.addr);

      queue.push(msg.sender);

      emit BattleCreated(battle, player);
    }

    players[msg.sender] = player;
    battles[battle.battleId] = battle;

    return battle.battleId;
  }
  
  function claimBattle(uint id, bytes memory signature, uint result, uint expiration) public {
    INFTBattles.Battle memory battle = battles[id];
    require(battle.state == 1, "Battle not active or already claimed");
    require(battle.playerA == msg.sender || battle.playerB == msg.sender, "Not your Battle");
		require(block.timestamp < expiration, "Claim expired");
		require(result != 0 || (result == 0 && block.timestamp > battle.startedDate + claimLossWaitTime), "Can't claim yet");
   
    bytes32 _hash = keccak256(abi.encode(msg.sender, address(this), id, result, expiration)).toEthSignedMessageHash();
    address signer = _hash.recover(signature);
    require(signer == signerAddress, "Signers don't match");

		address player;
		if (result == 1) // win
			player = msg.sender;
		else if (result == 0) // loss
			player = battle.playerA == msg.sender ? battle.playerB : battle.playerA;
		else // draw
			player = address(0);

    _finishBattle(id, player, msg.sender);
  }

  function _finishBattle(uint id, address winner, address claimer) internal {
    INFTBattles.Battle storage battle = battles[id];
    INFTBattles.Player storage player;
    INFTBattles.Player storage opponent;

		if (winner == address(0)) {
			player = players[battle.playerA];
			opponent = players[battle.playerB];
			player.draws += 1;
			opponent.draws += 1;
		} else {
			if (battle.playerA == winner) {
				player = players[battle.playerA];
				opponent = players[battle.playerB];
			} else {
				player = players[battle.playerB];
				opponent = players[battle.playerA];
			}
			player.wins += 1;
			opponent.losses += 1;
		}

    battle.state = 2;
    battle.winner = winner;
		battle.finishedDate = block.timestamp;
    player.currentBattle = 0;
    opponent.currentBattle = 0;

    uint rankA = player.rank;
    uint rankB = opponent.rank;

		if (rankA < 100) rankA = 100;
		if (rankB < 100) rankB = 100;

    (int changeA, int changeB) = getScoreChange(int(rankA)-int(rankB), winner);
		
		player.rank = uint(int(rankA) + changeA);
		opponent.rank = uint(int(rankB) + changeB);

    if (changeA > changeB) {
      player.xp += uint(changeA) * (block.timestamp < IRewards(rewardsAddress).getDailyBoostsByPlayer(player.addr).xp ? 2 : 1);
      opponent.xp += uint(changeA / 5) * (block.timestamp < IRewards(rewardsAddress).getDailyBoostsByPlayer(opponent.addr).xp ? 2 : 1) + 1;
    } else {
      player.xp += uint(changeB) * (block.timestamp < IRewards(rewardsAddress).getDailyBoostsByPlayer(player.addr).xp ? 2 : 1);
      opponent.xp += uint(changeB / 5) * (block.timestamp < IRewards(rewardsAddress).getDailyBoostsByPlayer(opponent.addr).xp ? 2 : 1) + 1;
    }

    uint nextLevel = player.level + 1;
    while (nextLevel < levels.length - 1 && player.xp >= levels[nextLevel]) {
      player.level = nextLevel;
      emit LevelUp(player.addr, nextLevel);
      if (rewardsAddress != address(0))
        IRewards(rewardsAddress).giveLevelUpRewards(player.addr, nextLevel);
      nextLevel++;
    }

    nextLevel = opponent.level + 1;
    while (nextLevel < levels.length - 1 && opponent.xp >= levels[nextLevel]) {
      opponent.level = nextLevel;
      emit LevelUp(opponent.addr, nextLevel);
      if (rewardsAddress != address(0))
        IRewards(rewardsAddress).giveLevelUpRewards(opponent.addr, nextLevel);
      nextLevel++;
    }
       
    if (battle.playerA == player.addr) {
      battle.scoreA = changeA;
      battle.scoreB = changeB;
      emit BattleFinished(battle, player, opponent, changeA, changeB, winner);
    } else {
      battle.scoreA = changeB;
      battle.scoreB = changeA;
      emit BattleFinished(battle, opponent, player, changeB, changeA, winner);
    }

    if (rewardsAddress != address(0))
      IRewards(rewardsAddress).giveBattleRewards(battle.battleId, claimer != winner && claimer != address(0));
  }
  
  function getPlayer(address _player) external view returns (INFTBattles.Player memory) {
    INFTBattles.Player memory player = players[_player];

    if (player.addr == address(0) && oldBattlesAddress != address(0))
      player = INFTBattles(oldBattlesAddress).getPlayer(_player);

    player.boosts = getBoosts(_player);
    player.dailyBoosts = IRewards(rewardsAddress).getDailyBoostsByPlayer(_player);
    return player;
  }

  function getBattle(uint id) external view returns (INFTBattles.Battle memory) {
    INFTBattles.Battle memory battle = battles[id];

    if (battle.battleId == 0 && oldBattlesAddress != address(0))
      battle = INFTBattles(oldBattlesAddress).getBattle(id);
      
    return battle;
  }
  
  function importDataFromOldContract(address _player) public returns (INFTBattles.Player memory) {
    INFTBattles.Player memory player;
    if (oldBattlesAddress == address(0) || alreadyImported[_player]) {
      player = players[_player];
    } else {
      player = INFTBattles(oldBattlesAddress).getPlayer(_player);
      players[_player] = player;
      alreadyImported[_player] = true;
      if (rewardsAddress != address(0)) IRewards(rewardsAddress).importDataFromOldContract(_player);
    }
    return player;
  }

  function toggleBattlesEnabled() external onlyOwner {
    battlesEnabled = !battlesEnabled;
  }

  function setBattlesPerDay(uint num) external onlyOwner {
    battlesPerDay = num;
  }
	
  function setDeckSize(uint num) external onlyOwner {
    deckSize = num;
  }

	function setSignerAddress(address addr) external onlyOwner {
    signerAddress = addr;
  }

	function setCardsAddress(address addr) external onlyOwner {
    cardsAddress = addr;
  }

	function setRewardsAddress(address addr) external onlyOwner {
    rewardsAddress = addr;
  }

	function setOldBattlesAddress(address addr) external onlyOwner {
    oldBattlesAddress = addr;
  }

  function setMaxPlayerDiff(uint diff) external onlyOwner {
    maxPlayerDiff = diff;
  }

	function setClaimLossWaitTime(uint mins) external onlyOwner {
    claimLossWaitTime = mins * 60;
  }	

	function setStartingRank(uint rank) external onlyOwner {
    startingRank = rank;
  }	

	function setStartingXP(uint xp) external onlyOwner {
    startingXP = xp;
  }	

	function setStartingLevel(uint level) external onlyOwner {
    startingLevel = level;
  }	

	function setLevels(uint[] calldata lvls) external onlyOwner {
    levels = lvls;
  }

	function setBattleId(uint id) external onlyOwner {
    battleId = id;
  }  

	function adminFinishBattle(uint id, address winner, address claimer) external onlyOwner {
		INFTBattles.Battle memory battle = battles[id];
		require(battle.state != 2, "Already finished");
		require(battle.playerA == winner || battle.playerB == winner || address(0) == winner, "Player not found");
    require(battle.playerA == claimer || battle.playerB == claimer || address(0) == claimer, "Player not found");
    _finishBattle(id, winner, claimer);
  }	

  function nextBattleId() internal returns (uint) {
    battleId++;
    return battleId;
  }

  function removeFromQueue(uint index) internal {
    for (uint i = index; i < queue.length - 1; i++) {
        queue[i] = queue[i + 1];
    }
    queue.pop();
  }

  function findBestMatch(uint rank, uint diff) internal returns (uint bestMatch) {
    if (queue.length == 0 || diff > maxPlayerDiff) return 999999;
    for (uint i = 0; i < queue.length; i++) {
        uint playerRank = players[queue[i]].rank;
        uint min = rank - diff;
        uint max = rank + diff;
        if (playerRank >= min && playerRank <= max) {
          return i;
        }
    }
    findBestMatch(rank, diff + 100);
  }


  function getBoosts(address _player) internal view returns (INFTBattles.PlayerBoosts memory) {
     (uint[] memory attack, uint[] memory defense, uint[] memory health, uint[] memory celda, uint[] memory dust) = IRewards(rewardsAddress).getPlayerBoosts(_player);
    
    return INFTBattles.PlayerBoosts({
      attack: attack,
      defense: defense,
      health: health,
      celda: celda,
      dust: dust
    });
  }

  /**
    * Table based expectation formula
    * E = 1 / ( 1 + 10**((difference)/400))
    * Table calculated based on inverse: difference = (400*log(1/E-1))/(log(10))
    * scoreChange = Round( K * (result - E) )
    * K = 21
    * Because curve is mirrored around 0, uses only one table for positive side
    * Returns (scoreChangeA, scoreChangeB)
    */
  function getScoreChange(int difference, address winner) internal pure returns (int, int) {
    bool reverse = (difference > 0); // note if difference was positive
    uint diff = abs(difference); // take absolute to lookup in positive table
    // Score change lookup table
    int scoreChange = 10;
    if (diff > 636) scoreChange = 20;
    else if (diff > 436) scoreChange = 19;
    else if (diff > 338) scoreChange = 18;
    else if (diff > 269) scoreChange = 17;
    else if (diff > 214) scoreChange = 16;
    else if (diff > 168) scoreChange = 15;
    else if (diff > 126) scoreChange = 14;
    else if (diff > 88) scoreChange = 13;
    else if (diff > 52) scoreChange = 12;
    else if (diff > 17) scoreChange = 11;
    if (winner != address(0)) {
			return (
								(reverse ? 21-scoreChange : scoreChange ),
								(reverse ? -21+scoreChange : -scoreChange )
				 		 );
		} else {
			return (
							(reverse ? 10-scoreChange : scoreChange-10 ),
							(reverse ? -(10-scoreChange) : -(scoreChange-10))
						 );
		}
  }

  function abs(int value) internal pure returns (uint){
      if (value>=0) return uint(value);
      else return uint(-1*value);
  }

}