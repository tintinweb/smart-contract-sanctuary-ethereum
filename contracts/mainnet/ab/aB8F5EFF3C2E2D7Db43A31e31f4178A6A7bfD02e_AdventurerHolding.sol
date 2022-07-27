// SPDX-License-Identifier: MIT
/**

 ________  ___    ___ ________  ___  ___  _______   ________  _________   
|\   __  \|\  \  /  /|\   __  \|\  \|\  \|\  ___ \ |\   ____\|\___   ___\ 
\ \  \|\  \ \  \/  / | \  \|\  \ \  \\\  \ \   __/|\ \  \___|\|___ \  \_| 
 \ \   ____\ \    / / \ \  \\\  \ \  \\\  \ \  \_|/_\ \_____  \   \ \  \  
  \ \  \___|/     \/   \ \  \\\  \ \  \\\  \ \  \_|\ \|____|\  \   \ \  \ 
   \ \__\  /  /\   \    \ \_____  \ \_______\ \_______\____\_\  \   \ \__\
    \|__| /__/ /\ __\    \|___| \__\|_______|\|_______|\_________\   \|__|
          |__|/ \|__|          \|__|                  \|_________|        
                                                                                                                                                    


 * @title AdventurerHolding
 * AdventurerHolding - a multi-purpose contract for staked PX Quest Adventurers
 */

pragma solidity ^0.8.11;

import "./IAdventurer.sol";
import "./IChronos.sol";
import "./IAdventurerHolding.sol";
import "./IAdventurerStaking.sol";
import "./utils/BitMap.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract AdventurerHolding is
    Initializable,
    IAdventurerHolding,
    AccessControlUpgradeable,
    ERC721HolderUpgradeable
{
    using SafeERC20 for IChronos;
    IAdventurer public adventurerContract;
    IChronos public chronosContract;

    bytes32 public constant LOCK_IN_ROLE = keccak256("LOCK_IN_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // NFT tokenId to time staked and owner's address
    mapping(uint256 => StakedToken) public stakes;

    // Address to number of tokens they have staked
    mapping(address => uint256) public _userStakes;

    // Last update for claimed chronos
    mapping(address => uint256) public lastUpdated;

    // Add store of current claimable chronos
    mapping(address => uint256) public _chronosReward;

    // Store of BitMap representing token statuses
    mapping(uint256 => uint256) public _status;

    // Store of timestamp for token lock-in expiry.
    mapping(uint256 => uint256) _lockIn;

    uint256 public SHARED_SUMMON_REWARD = 150 ether; // 150 CHRONOS
    uint256 public constant SINGLE_SUMMON_COST = 750 ether; // 750 CHRONOS

    uint8 private constant SUMMON_BIT = 1;

    address private constant DEAD_ADDRESS = address(0xdead);
    uint256 public LOCK_IN = 0;
    bool grantChronos = true;

    uint256 private MAX_GEN_COUNT;

    function initialize(
        IAdventurer _adventurerContract,
        IChronos _chronosContract,
        address _adminAddress
    ) external payable initializer {
        if (
            (_adventurerContract == IAdventurer(address(0))) ||
            (_chronosContract == IChronos(address(0))) ||
            (_adminAddress == address(0))
        ) revert CannotBeZeroAddress();
        _grantRole(ADMIN_ROLE, _adminAddress);
        chronosContract = _chronosContract;
        adventurerContract = _adventurerContract;
        MAX_GEN_COUNT = adventurerContract.maxGenCount();
    }

    // VIEW FUNCTIONS

    // Considering an individual array of tokens staked per user/status isn't stored,
    // when we want to access this information externally, we are forced to use these
    // extremely gas expensive view functions which are made free by them being simply
    // calculated by the RPC instead of being an actual gas-ful transaction.

    function viewStakes(address _address)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory _tokens = new uint256[](7500);
        uint256 tookCount = 0;
        for (uint64 i = 0; i < 7500; i++) {
            if (stakes[i].user == _address) {
                _tokens[tookCount] = i;
                tookCount++;
            }
        }
        uint256[] memory trimmedResult = new uint256[](tookCount);
        for (uint256 j = 0; j < trimmedResult.length; j++) {
            trimmedResult[j] = _tokens[j];
        }
        return trimmedResult;
    }

    function viewStakesByStatus(uint8[] memory status)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory _tokens = new uint256[](7500);
        uint256 bitmap = BitMap.setBits(0, status);
        uint256 tookCount = 0;
        for (uint64 i = 0; i < 7500; i++) {
            if (_status[i] & bitmap == bitmap) {
                _tokens[tookCount] = i;
                tookCount++;
            }
        }
        uint256[] memory trimmedResult = new uint256[](tookCount);
        for (uint256 j = 0; j < trimmedResult.length; j++) {
            trimmedResult[j] = _tokens[j];
        }
        return trimmedResult;
    }

    function viewSharedSummoners() public view returns (uint256[] memory) {
        uint256[] memory _tokens = new uint256[](MAX_GEN_COUNT);
        uint256 tookCount = 0;
        for (uint64 i = 0; i <= MAX_GEN_COUNT; i++) {
            if (BitMap.checkBit(_status[i], SUMMON_BIT)) {
                _tokens[tookCount] = i;
                tookCount++;
            }
        }
        uint256[] memory trimmedResult = new uint256[](tookCount);
        for (uint256 j = 0; j < trimmedResult.length; j++) {
            trimmedResult[j] = _tokens[j];
        }
        return trimmedResult;
    }

    function getAccruedChronos(address _address)
        public
        view
        returns (uint256 amount)
    {
        amount =
            (_userStakes[_address] *
                5 ether *
                (block.timestamp - lastUpdated[_address])) /
            86400;
    }

    function updateRewardAndTimestamp(address _address) internal {
        _chronosReward[_address] += getAccruedChronos(_address);
        lastUpdated[_address] = block.timestamp;
    }

    function getSummonCost(bool _shared) public view returns (uint256 cost) {
        cost = SINGLE_SUMMON_COST + (_shared ? SHARED_SUMMON_REWARD : 0);
    }

    function claimChronos() public {
        uint256 unclaimed = chronosContract.getTotalUnclaimed(msg.sender);
        uint256 accrued = unclaimed;
        updateRewardAndTimestamp(msg.sender);
        if (grantChronos == true) {
            accrued += _chronosReward[msg.sender];
            _chronosReward[msg.sender] = 0;
        }
        chronosContract.burnUnclaimed(msg.sender, unclaimed);
        chronosContract.grantChronos(msg.sender, accrued);
    }

    function _stake(uint256 token) internal {
        stakes[token] = StakedToken(
            msg.sender,
            uint64(block.timestamp),
            uint64(_userStakes[msg.sender]) + 1
        );
        _userStakes[msg.sender] += 1;
        emit StartStake(msg.sender, token);
        adventurerContract.safeTransferFrom(
            msg.sender,
            address(this),
            uint256(token)
        );
    }

    function stake(uint256 token) public override {
        updateRewardAndTimestamp(msg.sender);
        _stake(token);
    }

    function groupStake(uint256[] memory tokens) external override {
        updateRewardAndTimestamp(msg.sender);
        for (uint64 i = 0; i < tokens.length; ++i) {
            _stake(tokens[i]);
        }
    }

    function _unstake(uint256 token, uint256 stakeLength) private {
        emit Unstake(msg.sender, token, stakeLength > 90 days, stakeLength);
        delete stakes[token];
        delete _status[token];
        _userStakes[msg.sender] -= 1;
        adventurerContract.safeTransferFrom(
            address(this),
            msg.sender,
            uint256(token)
        );
    }

    function unstake(uint256 token) public override {
        if (stakes[token].user != msg.sender) revert UserNotStaker();
        if (block.timestamp < _lockIn[token]) revert TokenLocked();
        uint64 stakeLength = uint64(block.timestamp) - stakes[token].timeStaked;
        if (stakeLength < LOCK_IN) revert TokenLocked();
        updateRewardAndTimestamp(msg.sender);
        _unstake(token, stakeLength);
    }

    function groupUnstake(uint256[] memory tokens) external override {
        updateRewardAndTimestamp(msg.sender);
        for (uint256 i = 0; i < tokens.length; ++i) {
            if (stakes[tokens[i]].user != msg.sender) revert UserNotStaker();
            if (block.timestamp < _lockIn[tokens[i]]) revert TokenLocked();
            uint64 stakeLength = uint64(block.timestamp) -
                stakes[tokens[i]].timeStaked;
            if (stakeLength < LOCK_IN) revert TokenLocked();
            _unstake(tokens[i], stakeLength);
        }
    }

    function burnToken(uint256 token) public onlyRole(BURNER_ROLE) {
        if (stakes[token].user == address(0)) revert TokenNotStaked();
        emit Burn(stakes[token].user, token);
        delete stakes[token];
        adventurerContract.safeTransferFrom(address(this), DEAD_ADDRESS, token);
    }

    function batchBurnTokens(uint256[] memory tokens)
        external
        onlyRole(BURNER_ROLE)
    {
        for (uint256 i = 0; i < tokens.length; ++i) {
            burnToken(tokens[i]);
        }
    }

    function lockToken(uint256 token, uint256 period)
        public
        onlyRole(LOCK_IN_ROLE)
    {
        if (stakes[token].user == address(0)) revert TokenNotStaked();
        _lockIn[token] = block.timestamp + period;
    }

    function groupLockTokens(uint256[] memory tokens, uint256 period)
        external
        onlyRole(LOCK_IN_ROLE)
    {
        for (uint256 i = 0; i < tokens.length; ++i) {
            lockToken(tokens[i], period);
        }
    }

    function _summon(
        uint256 _token1,
        uint256 _token2,
        uint8 option,
        bool shared,
        bool swapped
    ) private {
        if (option > uint8(type(SummonOption).max))
            revert InvalidSummonOption();
        if (
            (SummonOption(option) == SummonOption.HoldingUnclaimed) &&
            (getAccruedChronos(msg.sender) + _chronosReward[msg.sender] <
                getSummonCost(shared))
        ) revert InsufficientChronos();
        uint256 cost = getSummonCost(shared);
        SummonOption selectedOption = SummonOption(option);
        uint256 advId = MAX_GEN_COUNT + adventurerContract.gen2Count() + 1;
        if (shared) {
            _chronosReward[stakes[_token2].user] += SHARED_SUMMON_REWARD;
        }

        uint256 token1;
        uint256 token2;

        (token1, token2) = swapped ? (_token2, _token1) : (_token1, _token2);

        if (selectedOption == SummonOption.HoldingUnclaimed) {
            updateRewardAndTimestamp(msg.sender);
            _chronosReward[msg.sender] -= cost;
            chronosContract.grantChronos(address(this), cost);
            adventurerContract.summon(token1, token2, true);
        } else if (selectedOption == SummonOption.NFTUnclaimed) {
            chronosContract.burnUnclaimed(msg.sender, cost);
            chronosContract.grantChronos(address(this), cost);
            adventurerContract.summon(token1, token2, true);
        } else {
            chronosContract.safeTransferFrom(
                msg.sender,
                address(this),
                SHARED_SUMMON_REWARD + SINGLE_SUMMON_COST
            );
            adventurerContract.summon(token1, token2, true);
        }

        adventurerContract.safeTransferFrom(address(this), msg.sender, advId);
    }

    function sharedSummon(
        uint256 token,
        uint256 summoner,
        uint8 option,
        bool swapped
    ) external {
        if (stakes[token].user != msg.sender) revert UserNotStaker();
        if (!(BitMap.checkBit(_status[summoner], SUMMON_BIT)))
            revert TokenCannotBeUsedToSummon();
        _summon(token, summoner, option, true, swapped);
    }

    function summon(
        uint256 token1,
        uint256 token2,
        uint8 option
    ) external {
        if (
            stakes[token1].user != msg.sender ||
            stakes[token2].user != msg.sender
        ) revert UserNotStaker();
        _summon(token1, token2, option, false, false);
    }

    function setSummoning(uint256 token, bool status) public {
        if (stakes[token].user != msg.sender) revert UserNotStaker();
        if (status && token > MAX_GEN_COUNT) revert TokenCannotBeUsedToSummon();
        _status[token] = BitMap.setBit(_status[token], SUMMON_BIT, status);
    }

    function batchSetSummoning(uint256[] memory tokens, bool status) external {
        for (uint256 i = 0; i < tokens.length; ++i) {
            setSummoning(tokens[i], status);
        }
    }

    function setStatus(uint256 token, uint8[] memory bits) public {
        if (stakes[token].user != msg.sender) revert UserNotStaker();
        _status[token] = BitMap.setBits(0, bits);
    }

    function batchSetStatus(uint256[] memory tokens, uint8[] memory bits)
        external
    {
        uint256 bitmap = BitMap.setBits(0, bits);
        for (uint256 i = 0; i < tokens.length; ++i) {
            if (stakes[tokens[i]].user != msg.sender) revert UserNotStaker();
            _status[tokens[i]] = bitmap;
        }
    }

    function setGrantChronos(bool _grant) external onlyRole(ADMIN_ROLE) {
        grantChronos = _grant;
    }

    function setLockIn(uint256 lockin) external onlyRole(ADMIN_ROLE) {
        LOCK_IN = lockin;
    }

    function updateSummonReward(uint256 amount) external onlyRole(ADMIN_ROLE) {
        SHARED_SUMMON_REWARD = amount;
    }

    function addLockInRole(address user) external onlyRole(ADMIN_ROLE) {
        if (user == address(0)) revert CannotBeZeroAddress();
        _grantRole(LOCK_IN_ROLE, user);
    }

    function addBurnerRole(address user) external onlyRole(ADMIN_ROLE) {
        if (user == address(0)) revert CannotBeZeroAddress();
        _grantRole(BURNER_ROLE, user);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IAdventurer is IERC721 {
  function summon(
    uint256 parent1,
    uint256 parent2,
    bool withdrawn
  ) external;

  function gen2Count() external returns (uint256 gen2count);

  function maxGenCount() external returns (uint256 maxGenCount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * This interface is for the CHRONOS ERC20 Utility Token for PxQuest
 * As the Chronos contract was deployed before Labrys was employed on the project,
 * this is a retrospectively created interface so that Chronos functionality 
 * can be user elsewhere.
 */
interface IChronos is IERC20 {
    /// @notice Update current reward status
    function updateReward(address from, address to) external;

    /// @notice Withdraw/Claim chronos avaialable to the sender
    function withdrawChronos() external;

    /// @notice Grant chronos to a user
    /// @param _address the address to grant chronos to
    /// @param _amount the amount of chronos to grant
    function grantChronos(address _address, uint256 _amount) external;

    /// @notice Burn unclaimed chronos tokens
    /// @param user the address to burn unclaimed tokens from
    /// @param amount the amount of unclaimed tokens to burn
    function burnUnclaimed(address user, uint256 amount) external;

    /// @notice Burn chronos tokens
    /// @param user address to burn tokens from
    /// @param amount the amount of tokens to burn
    function burn(address user, uint256 amount) external;

    /// @notice get the total amount of unclaimed chronos available to a user
    /// @param user address of the user to check for
    function getTotalUnclaimed(address user)
        external
        view
        returns (uint256 unclaimed);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";

interface IAdventurerHolding is IERC721ReceiverUpgradeable {
    struct StakedToken {
        address user;
        uint64 timeStaked;
        uint64 index;
    }

    enum SummonOption {
        Claimed,
        NFTUnclaimed,
        HoldingUnclaimed
    }

    /// ERRORS

    /// @notice reverts when a user tries to do an operation on a token they didn't stake
    error UserNotStaker();
    /// @notice reverts when an operation is attempted on a token that is not in the smart contract
    error TokenNotStaked();
    /// @notice reverts when a token is attempted to be withdrawn before its lock in period is over
    error TokenLocked();
    /// @notice reverts when a user attempts a summon option that doesn't exist
    error InvalidSummonOption();
    /// @notice reverts when a user attempts an operation which requires more chronos than they possess
    error InsufficientChronos();
    /// @notice reverts when a zero address is passed in as a potential admin or smart contract location
    error CannotBeZeroAddress();
    /// @notice reverts when a token cannot be used to summon, either because it's Gen 2 or not made available
    error TokenCannotBeUsedToSummon();

    /// EVENTS

    /// @notice Emits when a user stakes their NFT.
    /// @param owner the wallet address of the owner of the NFT being staked.
    /// @param token the tokenId of the Adventurer NFT being staked.
    event StartStake(address indexed owner, uint256 token);

    /// @notice Emits when a user unstakes their NFT.
    /// @param owner the wallet address of the owner of the NFT being unstaked.
    /// @param token the tokenId of the Adventurer NFT being unstaked.
    /// @param success whether or not the user staked the NFT for more than 90 days.
    /// @param duration the duration the NFT was staked for.
    event Unstake(
        address indexed owner,
        uint256 token,
        bool success,
        uint256 duration
    );

    /// @notice Emits when a user burns an NFT.
    /// @param owner the wallet address of the owner of the NFT being burned.
    /// @param token the tokenId of the NFT being burned
    event Burn(address indexed owner, uint256 token);

    /// VIEW FUNCTIONS

    /// @notice returns a list of currently staked tokens by a given address
    /// @param _address the address whose tokens are being queried
    /// @return the list of tokenIds as uint256[] memory
    /// @dev because stakes are not stored per user, we are forced to iterate through all possible tokenIds
    function viewStakes(address _address)
        external
        view
        returns (uint256[] memory);

    /// @notice returns a list of currently staked tokens by a given list of active status bits
    /// @param status the list of bits that are being queried for
    /// @return the list of tokenIds as uint256[] memory
    function viewStakesByStatus(uint8[] memory status)
        external
        view
        returns (uint256[] memory);

    /// @notice returns a list of currently available shared summoners
    /// @return the list of tokenIds as uint256[] memory
    /// @dev because someone could hardcode a non-summonable token to be available for summoning, this function filters only by tokenIds that can be used to summon in order to prevent users wasting gas attempting summon with an non-summonable token.
    function viewSharedSummoners() external view returns (uint256[] memory);

    /// @notice calculates the amount of Chronos accrued by a given user through staked NFTs
    /// @param _address the user whose accrued Chronos is being calculated
    /// @return amount of chronos accrued by user
    function getAccruedChronos(address _address)
        external
        view
        returns (uint256);

    /// @notice calculates the cost of summoning depending on whether its a shared summon
    /// @param _shared whether the summon is a shared summon
    /// @return amount of chronos it will cost to summon
    function getSummonCost(bool _shared) external view returns (uint256);

    /// FUNCTIONS

    /// @notice Stakes a user's NFT
    /// @param token the tokenId of the NFT to be staked
    function stake(uint256 token) external;

    /// @notice Stakes serveral of a user's NFTs
    /// @param tokens the tokenId of the NFT to be staked
    function groupStake(uint256[] memory tokens) external;

    /// @notice Retrieves a user's NFT from the staking contract
    /// @param token the tokenId of the staked NFT
    function unstake(uint256 token) external;

    /// @notice Unstakes serveral of a user's NFTs
    /// @param token the tokenId of the NFT to be staked
    function groupUnstake(uint256[] memory token) external;

    /// @notice Sets whether an NFT is available for Summoning
    /// @param token the tokenId that's being set
    /// @param status whether the token is available for summoning
    function setSummoning(uint256 token, bool status) external;

    /// @notice Sets whether several NFTS are available for Summoning
    /// @param tokens a list of tokenId's that are being set
    /// @param status whether the tokens will be availabe for summoning
    function batchSetSummoning(uint256[] memory tokens, bool status) external;

    /// @notice Sets several status bits at once
    /// @param token the tokenId being set
    /// @param bits which bits will be set
    function setStatus(uint256 token, uint8[] memory bits) external;

    /// @notice Sets several status bits of several NFTs at once
    /// @param tokens the tokenIds being set
    /// @param bits which bits will be set
    function batchSetStatus(uint256[] memory tokens, uint8[] memory bits)
        external;

    /// @notice Uses a token available for summoning to summon a new adventurer
    /// @param token the user's token that they want to use for summoning
    /// @param summoner the token they wish to summon with
    /// @param option where to use the chronos from
    /// @param swapped whether the summoner should instead come first in the summon call
    function sharedSummon(
        uint256 token,
        uint256 summoner,
        uint8 option,
        bool swapped
    ) external;

    /// @notice Uses a token available for summoning to summon a new adventurer
    /// @param token1 the user's first token that they want to use for summoning
    /// @param token2 the user's second token that they want to use for summoning
    /// @param option where to use the chronos from
    function summon(
        uint256 token1,
        uint256 token2,
        uint8 option
    ) external;

    /// @notice Prevents a token being unstaked until the period has passed
    /// @param token the tokenId being locked in
    /// @param period the period that the token is locked in
    function lockToken(uint256 token, uint256 period) external;

    /// @notice Sends a staked token to the zero address
    /// @param token the tokenId that's being burned
    function burnToken(uint256 token) external;

    /// @notice Sends several staked tokens to the zero address
    /// @param tokens the tokens that will be sent to the zero address
    function batchBurnTokens(uint256[] memory tokens) external;

    /// @notice Prevents multiple tokens being unstaked until the period has passed
    /// @param tokens the tokenIds being locked in
    /// @param period the period that the tokens are locked in
    function groupLockTokens(uint256[] memory tokens, uint256 period) external;

    /// @notice Updates whether or not Chronos is granted on unstake
    /// @param _grant the new status of Chronos granting
    function setGrantChronos(bool _grant) external;

    /// @notice Sets the Lock-In time for all tokens after stake
    /// @param lockin the
    function setLockIn(uint256 lockin) external;

    /// @notice Claims all chronos due to msg.sender
    function claimChronos() external;

    /// @notice Gives an address the ability to lock in tokens for a set duration
    /// @param user the address that is being given the permission
    function addLockInRole(address user) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

interface IAdventurerStaking is IERC721Receiver {
    struct StakedToken {
        address user;
        uint64 timeStaked;
    }

    /// @notice Emits when a user stakes their NFT.
    /// @param owner the wallet address of the owner of the NFT being staked.
    /// @param tokenId the tokenId of the Adventurer NFT being staked.
    event StartStake(address indexed owner, uint64 tokenId);

    /// @notice Emits when a user unstakes their NFT.
    /// @param owner the wallet address of the owner of the NFT being unstaked.
    /// @param tokenId the tokenId of the Adventurer NFT being unstaked.
    /// @param success whether or not the user staked the NFT for more than 90 days.
    /// @param duration the duration the NFT was staked for.
    event Unstake(
        address indexed owner,
        uint64 tokenId,
        bool success,
        uint64 duration
    );

    /// @notice Stakes a user's NFT
    /// @param tokenId the tokenId of the NFT to be staked
    function stake(uint64 tokenId) external;

    /// @notice Stakes serveral of a user's NFTs
    /// @param tokenIds the tokenId of the NFT to be staked
    function groupStake(uint64[] memory tokenIds) external;

    /// @notice Retrieves a user's NFT from the staking contract
    /// @param tokenId the tokenId of the staked NFT
    function unstake(uint64 tokenId) external;

    /// @notice Unstakes serveral of a user's NFTs
    /// @param tokenIds the tokenId of the NFT to be staked
    function groupUnstake(uint64[] memory tokenIds) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/**
 * @dev Library for using a uint256 as a bitmap, effectively an extremely gas efficient uint8 to bool mapping.
 */
library BitMap {
  /// @notice Either sets a bit in a bitmap to on or off
  /// @param bitmap the bitmap being set
  /// @param bit which bit is being set
  /// @param status whether the bit is being set to on or off
  function setBit(
    uint256 bitmap,
    uint8 bit,
    bool status
  ) internal pure returns (uint256 updatedBitmap) {
    if (status) {
      return bitmap | (1 << bit);
    } else {
      return bitmap & (~(1 << bit));
    }
  }


  /// @notice Sets several bits at once
  /// @param bitmap the bitmap being set
  /// @param bits which bets are being set
  function setBits(
    uint256 bitmap,
    uint8[] memory bits
  ) internal pure returns (uint256 updatedBitmap) {
    uint256 _bitmap = bitmap;
    for (uint256 i = 0; i < bits.length; i++) {
      _bitmap = setBit(_bitmap, bits[i], true);
    }
    updatedBitmap = _bitmap;
  }

  /// @notice Checks whether a bit in a bitmap is on or off
  /// @param bitmap the bitmap being checked
  /// @param bit which bit is being checked
  function checkBit(uint256 bitmap, uint8 bit)
    internal
    pure
    returns (bool status)
  {
    return (bitmap & (1 << bit)) != 0;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal onlyInitializing {
    }

    function __ERC721Holder_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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