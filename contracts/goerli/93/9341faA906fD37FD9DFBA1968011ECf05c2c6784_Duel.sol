// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnerUpdated(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function setOwner(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Safe unsigned integer casting library that reverts on overflow.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeCastLib.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeCast.sol)
library SafeCastLib {
    function safeCastTo248(uint256 x) internal pure returns (uint248 y) {
        require(x < 1 << 248);

        y = uint248(x);
    }

    function safeCastTo224(uint256 x) internal pure returns (uint224 y) {
        require(x < 1 << 224);

        y = uint224(x);
    }

    function safeCastTo192(uint256 x) internal pure returns (uint192 y) {
        require(x < 1 << 192);

        y = uint192(x);
    }

    function safeCastTo160(uint256 x) internal pure returns (uint160 y) {
        require(x < 1 << 160);

        y = uint160(x);
    }

    function safeCastTo128(uint256 x) internal pure returns (uint128 y) {
        require(x < 1 << 128);

        y = uint128(x);
    }

    function safeCastTo96(uint256 x) internal pure returns (uint96 y) {
        require(x < 1 << 96);

        y = uint96(x);
    }

    function safeCastTo64(uint256 x) internal pure returns (uint64 y) {
        require(x < 1 << 64);

        y = uint64(x);
    }

    function safeCastTo32(uint256 x) internal pure returns (uint32 y) {
        require(x < 1 << 32);

        y = uint32(x);
    }

    function safeCastTo8(uint256 x) internal pure returns (uint8 y) {
        require(x < 1 << 8);

        y = uint8(x);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@rari-capital/solmate/src/auth/Owned.sol";
import "@rari-capital/solmate/src/tokens/ERC721.sol";
import "@rari-capital/solmate/src/utils/ReentrancyGuard.sol";
import "@rari-capital/solmate/src/utils/SafeCastLib.sol";
import "./interfaces/IDuelist.sol";
import "./interfaces/ILuck.sol";
import "./interfaces/INFTXVault.sol";
import "./interfaces/INFTXZap.sol";
import "./interfaces/IRandom.sol";

/// @title Duel
/// @notice Duel Management Contract
contract Duel is Owned, ReentrancyGuard, ERC721TokenReceiver {
    using SafeCastLib for uint256;

    struct Challenge {
        address challenger; // address of the challenger
        address recipient; // address of the challenge recipient
        uint256 wager; // additional ETH to wager on the challenge
        bytes32 requestId; // id of the randomness request
        uint64 maxLevel; // max level of recipient duelist
        uint64 challengerId; // id of the challenger
        uint64 recipientId; // id of the recipient
    }

    /// @notice Address of WETH
    address public immutable weth;

    /// @notice The Duelist NFT Contract
    IDuelist public immutable duelist;

    /// @notice The LUCK Token Contract
    ILuck public immutable luck;

    /// @notice Chainlink Random Number Generator Contract
    IRandom public random;

    /// @notice NFTX Vault Contract
    INFTXVault public vault;

    /// @notice NFTX Marketplace Zap Contract
    INFTXZap public zap;

    mapping(uint256 => Challenge) public challenges;

    /// @notice number of currently active challenges
    uint256 public activeChallenges;

    /// @notice number of total challenges created
    uint256 public challengeCounter;

    /// @notice NFTX Vault ID
    uint256 public vaultId;

    event ChallengeAccepted(uint256 indexed challengeId, address indexed recipient, uint256 indexed recipientId, bytes32 requestId);
    event ChallengeCancelled(uint256 indexed challengeId, address indexed challenger);
    event ChallengeFinalized(
        uint256 indexed challengeId,
        address indexed challenger,
        address indexed recipient,
        address winner,
        uint256 winnerId,
        uint256 loserId
    );
    event ChallengeSent(uint256 indexed challengeId, address indexed challenger, uint256 indexed challengerId);
    event RandomUpdated(address indexed newRandom, address indexed oldRandom);
    event VaultUpdated(address indexed newVault, address indexed oldVault);
    event ZapUpdated(address indexed newZap, address indexed oldZap);

    /// @notice Duel constructor function
    /// @param _duelist The Duelist Contract
    /// @param _luck The Luck Contract
    /// @param _random The Random Number Contract
    /// @param _weth The address of the WETH Contract
    constructor(
        IDuelist _duelist,
        ILuck _luck,
        IRandom _random,
        address _weth
    ) Owned(msg.sender) {
        require(address(_duelist) != address(0), "Duel:Init::InvalidDuelist");
        require(address(_luck) != address(0), "Duel:Init::InvalidLuck");
        require(address(_random) != address(0), "Duel:Init::InvalidRandom");
        require(address(_weth) != address(0), "Duel:Init::InvalidWETH");
        duelist = _duelist;
        luck = _luck;
        random = _random;
        weth = _weth;
    }

    receive() external payable {}

    /// @notice Send a challenge request with an optional payable wager
    /// @param challengerId id of the challenger's duelist
    /// @param recipient address of the recipient, address(0) if anyone can accept
    /// @param recipientId id of the recipient's duelist, 0 if any duelist id
    /// @param maxLevel the maximum level of the recipient duelist
    function sendChallenge(
        uint256 challengerId,
        address recipient,
        uint256 recipientId,
        uint256 maxLevel
    ) external payable nonReentrant {
        _send(msg.sender, recipient, msg.value, challengerId, recipientId, maxLevel);
    }

    /// @notice Accept a challenge request without finalizing it
    /// @dev payable msg.value must match the accepted challenge wager
    /// @param challengeId id of the challenge to accept
    /// @param recipientId id of the duelist to accept the challenge with
    function acceptChallenge(uint256 challengeId, uint256 recipientId) external payable nonReentrant {
        _accept(challengeId, msg.sender, recipientId, msg.value);
    }

    /// @notice Finalize a challenge that has been accepted
    /// @param challengeId id of the challenge to accept
    /// @param minEthOut The minimum amount of ETH to accept for the loser's duelist via NFTX Zap
    function finalizeChallenge(uint256 challengeId, uint256 minEthOut) external nonReentrant {
        _finalize(challengeId, msg.sender, minEthOut);
    }

    /// @notice Cancel a given outstanding challenge
    /// @param challengeId id of the challenge to accept
    function cancelChallenge(uint256 challengeId) external nonReentrant {
        _cancel(challengeId, msg.sender);
    }

    /// @notice Set the Chainlink Random Number Consumer Contract
    /// @param _random The new Random contract
    function setRandom(IRandom _random) external onlyOwner {
        require(address(_random) != address(0), "Duel:SetRandom:InvalidRandom");
        emit RandomUpdated(address(_random), address(random));
        random = _random;
    }

    /// @notice Set the NFTX Vault Contract
    /// @param _vault The new NFTX Vault contract
    function setVault(INFTXVault _vault) external onlyOwner {
        require(address(_vault) != address(0), "Duel:SetVault::InvalidVault");
        require(_vault.assetAddress() == address(duelist), "Duel:SetVault::InvalidAsset");
        emit VaultUpdated(address(_vault), address(vault));
        vault = _vault;
        vaultId = _vault.vaultId();
    }

    /// @notice Set the NFTX Marketplace Zap Contract
    /// @dev Set to address(0) to enable Exchange mode - Transfer losing duelist to winner
    /// @dev Set to contract address to enable Zap mode - Sell losing duelist to NFTX
    /// @param _zap The new NFTX Zap contract, or address(0)
    function setZap(INFTXZap _zap) external onlyOwner {
        if (address(zap) != address(0)) {
            // remove old approval
            duelist.setApprovalForAll(address(zap), false);
        }

        emit ZapUpdated(address(_zap), address(zap));
        zap = _zap;

        if (address(_zap) != address(0)) {
            // approve zap to transfer NFTs
            duelist.setApprovalForAll(address(_zap), true);
        }
    }

    /// @notice View function to display all active challenges on frontend
    /// @return ids Array of active challenge ids
    function getActiveChallengeIds() external view returns (uint256[] memory) {
        uint256[] memory ids = new uint256[](activeChallenges);
        uint256 counter = challengeCounter;

        // iterate through challenges, push active ids
        uint256 index;
        for (uint256 i; i < counter; i++) {
            if (challenges[i].challenger != address(0)) {
                ids[index++] = i;
            }
        }

        return ids;
    }

    /// @notice View function to display all active challenges for a given user on frontend
    /// @param user The address of the user to get challenge ids for
    /// @return ids Array of active challenge ids for the user
    function getActiveChallengeIdsByUser(address user) external view returns (uint256[] memory) {
        uint256 counter = challengeCounter;

        // count active user challenges
        uint256 userChallenges;
        for (uint256 i; i < counter; i++) {
            if (challenges[i].challenger == user || challenges[i].recipient == user) {
                userChallenges++;
            }
        }

        uint256[] memory ids = new uint256[](userChallenges);

        // add active user challenge ids to array
        uint256 index;
        for (uint256 i; i < counter; i++) {
            if (challenges[i].challenger == user || challenges[i].recipient == user) {
                ids[index++] = i;
            }
        }

        return ids;
    }

    /// @notice View function to display Duel winner on frontend
    /// @param challengeId id of the challenge to check
    /// @return winner address of the winner
    function winnerOf(uint256 challengeId) external view returns (address winner) {
        uint256 challengerId = challenges[challengeId].challengerId;
        uint256 recipientId = challenges[challengeId].recipientId;

        bytes32 requestId = challenges[challengeId].requestId;
        uint256 randomness = random.requests(requestId);
        if (randomness == 0) {
            return address(0);
        } else {
            (uint256 winnerId, ) = _determineWinner(randomness, challengerId, recipientId);
            if (winnerId == challengerId) {
                return challenges[challengeId].challenger;
            } else {
                return challenges[challengeId].recipient;
            }
        }
    }

    /// @notice Accept challenge internal function
    function _accept(
        uint256 challengeId,
        address recipient,
        uint256 recipientId,
        uint256 wager
    ) internal {
        Challenge storage challenge = challenges[challengeId];

        address challenger = challenge.challenger;
        address challengeRecipient = challenge.recipient;
        uint256 challengeRecipientId = challenge.recipientId;
        uint256 challengeWager = challenge.wager;

        // Do basic sanity checks
        require(challenge.requestId == 0, "Duel:Accept::InvalidChallengeState");
        require(challenger != address(0), "Duel:Accept::NoChallenger");
        require(recipient != challenger, "Duel:Accept::DuplicateChallenger");
        require(duelist.levelOf(recipientId) <= challenge.maxLevel, "Duel:Accept::LevelTooHigh");

        // Require challenge recipient (recipient) is valid, update value if not set
        if (challengeRecipient != address(0)) {
            require(recipient == challengeRecipient, "Duel:Accept::InvalidRecipient");
        } else {
            challenge.recipient = recipient;
        }

        // Require challenge recipient Id is valid, update value if not set
        if (challengeRecipientId != 0) {
            require(recipientId == challengeRecipientId, "Duel:Accept::InvalidRecipientId");
        } else {
            challenge.recipientId = recipientId.safeCastTo64();
        }

        // Validate challenge wager
        require(wager == challengeWager, "Duel:Accept::InvalidWager");

        // Transfer duelist from user
        duelist.transferFrom(recipient, address(this), recipientId);

        // Request randomness and update challenge
        bytes32 requestId = IRandom(random).requestRandomness();
        challenge.requestId = requestId;
        emit ChallengeAccepted(challengeId, recipient, recipientId, requestId);
    }

    /// @notice Cancel challenge internal function
    function _cancel(uint256 challengeId, address challenger) internal {
        Challenge storage challenge = challenges[challengeId];
        require(challenge.challenger == challenger, "Duel:Cancel::OnlyChallenger");
        require(challenge.requestId == 0, "Duel:Cancel::InvalidChallengeState");

        // transfer back the duelist
        duelist.transferFrom(address(this), challenger, challenge.challengerId);

        // pay back the wager
        uint256 wager = challenge.wager;
        if (wager > 0) {
            payable(challenger).transfer(wager);
        }

        // cleanup challenge state, decrement, and emit
        delete challenges[challengeId];
        activeChallenges--;
        emit ChallengeCancelled(challengeId, challenger);
    }

    /// @notice Finalize challenge internal function
    function _finalize(
        uint256 challengeId,
        address caller,
        uint256 minEthOut
    ) internal {
        Challenge storage challenge = challenges[challengeId];

        // require challenge has been accepted
        bytes32 requestId = challenge.requestId;
        require(requestId != 0, "Duel:Finalize::InvalidChallengeState");

        // require random number has been generated for the duel
        uint256 randomness = IRandom(random).requests(requestId);
        require(randomness != 0, "Duel:Finalize::InvalidRandomness");

        // get values
        address challenger = challenge.challenger;
        address recipient = challenge.recipient;
        uint256 challengerId = challenge.challengerId;

        // determine winner and loser
        (uint256 winnerId, uint256 loserId) = _determineWinner(randomness, challengerId, challenge.recipientId);
        address winner = winnerId == challengerId ? challenger : recipient;

        // only allow winner to call
        require(caller == winner, "Duel:Finalize::OnlyWinner");

        // reset loser level
        duelist.levelDown(loserId);

        // Zap Mode
        if (address(zap) != address(0)) {
            // sell losing duelist via nftx zap, pay proceeds directly to winner
            uint256[] memory ids = new uint256[](1);
            ids[0] = loserId; // get loser id
            address[] memory path = new address[](2);
            path[0] = address(vault);
            path[1] = weth;
            zap.mintAndSell721(vaultId, ids, minEthOut, path, winner);
        }
        // Exchange Mode
        else {
            duelist.transferFrom(address(this), winner, loserId);
        }

        // transfer winning duelist back to winner
        duelist.transferFrom(address(this), winner, winnerId);

        // accrue protocol fees and transfer winnings, if any
        uint256 winnings = challenge.wager * 2;
        if (winnings > 0) {
            payable(winner).transfer(winnings);
        }

        // cleanup challenge state, decrement, and emit
        delete challenges[challengeId];
        activeChallenges--;
        emit ChallengeFinalized(challengeId, challenger, recipient, winner, winnerId, loserId);
    }

    /// @notice Send challenge internal function
    function _send(
        address challenger,
        address recipient,
        uint256 wager,
        uint256 challengerId,
        uint256 recipientId,
        uint256 maxLevel
    ) internal {
        require(challenger != recipient, "Duel:Send::InvalidRecipient");
        require(challengerId != recipientId, "Duel:Send::InvalidRecipientId");

        // get counter and create challenge
        uint256 counter = challengeCounter;
        challenges[counter] = Challenge({
            challenger: challenger,
            recipient: recipient,
            wager: wager,
            requestId: 0,
            maxLevel: maxLevel.safeCastTo64(),
            challengerId: challengerId.safeCastTo64(),
            recipientId: recipientId.safeCastTo64()
        });

        // Transfer duelist from sender
        duelist.transferFrom(challenger, address(this), challengerId);

        // increment counters and emit
        activeChallenges++;
        challengeCounter++;
        emit ChallengeSent(counter, challenger, challengerId);
    }

    /// @notice Determine the winner of the duel given randomness
    /// @dev Duel Outcome = randomness % (100 + challengerId + recipientId)
    /// @dev Challenger wins if Duel Outcome is strictly less than (50 + challegerLevel)
    /// @dev Else, the Recipient wins
    /// @dev Default chances of winning a duel with no levels are 50/50
    function _determineWinner(
        uint256 randomness,
        uint256 challengerId,
        uint256 recipientId
    ) internal view returns (uint256 winnerId, uint256 loserId) {
        // get challenger/recipient levels
        uint256 challengerLevel = duelist.levelOf(challengerId);
        uint256 recipientLevel = duelist.levelOf(recipientId);

        // find range and compute outcome based on randomness
        uint256 range = 100 + challengerLevel + recipientLevel;
        uint256 outcome = randomness % range;

        // determine winner
        if (outcome < 50 + challengerLevel) {
            winnerId = challengerId;
            loserId = recipientId;
        } else {
            winnerId = recipientId;
            loserId = challengerId;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IERC721.sol";

/// @title Duelist Interface
interface IDuelist is IERC721 {
    function duel() external view returns (address);

    function luck() external view returns (address);

    function baseURI() external view returns (string calldata);

    function totalSupply() external view returns (uint256);

    function levelOf(uint256 id) external view returns (uint256);

    function tokenRequiredForLevel(uint256 id, uint256 level) external view returns (uint256);

    function levelUp(uint256 id, uint256 levels) external;

    function levelDown(uint256 id) external;

    function mint(address recipient, uint256 quantity) external;

    function setBaseURI(string calldata baseURI) external;

    function setDuel(address duel) external;

    function setLuck(address luck) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IERC2612 {
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

/// @notice IERC20 with Metadata + Permit
interface IERC20 is IERC2612 {
    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function decimals() external view returns (uint8);

    function name() external view returns (string calldata);

    function symbol() external view returns (string calldata);

    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    function approve(address to, uint256 tokenId) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function setApprovalForAll(address operator, bool _approved) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function balanceOf(address owner) external view returns (uint256 balance);

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function name() external view returns (string calldata);

    function symbol() external view returns (string calldata);

    function tokenURI(uint256 id) external view returns (string calldata);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IERC20.sol";

interface ILuck is IERC20 {
    function burn(address holder, uint256 amount) external;

    function mint(address recipient, uint256 amount) external;

    function setBurner(address burner, bool approved) external;

    function setMinter(address minter, bool approved) external;

    function burners(address burner) external view returns (bool);

    function minters(address minter) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IERC20.sol";

/// @notice NFTX Vault
interface INFTXVault is IERC20 {
    function manager() external view returns (address);

    function assetAddress() external view returns (address);

    function vaultFactory() external view returns (address);

    function eligibilityStorage() external view returns (address);

    function is1155() external view returns (bool);

    function allowAllItems() external view returns (bool);

    function enableMint() external view returns (bool);

    function enableRandomRedeem() external view returns (bool);

    function enableTargetRedeem() external view returns (bool);

    function enableRandomSwap() external view returns (bool);

    function enableTargetSwap() external view returns (bool);

    function vaultId() external view returns (uint256);

    function nftIdAt(uint256 holdingsIndex) external view returns (uint256);

    function allHoldings() external view returns (uint256[] memory);

    function totalHoldings() external view returns (uint256);

    function mintFee() external view returns (uint256);

    function randomRedeemFee() external view returns (uint256);

    function targetRedeemFee() external view returns (uint256);

    function randomSwapFee() external view returns (uint256);

    function targetSwapFee() external view returns (uint256);

    function vaultFees()
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    function setVaultMetadata(string memory name_, string memory symbol_) external;

    function setVaultFeatures(
        bool _enableMint,
        bool _enableRandomRedeem,
        bool _enableTargetRedeem,
        bool _enableRandomSwap,
        bool _enableTargetSwap
    ) external;

    function setFees(
        uint256 _mintFee,
        uint256 _randomRedeemFee,
        uint256 _targetRedeemFee,
        uint256 _randomSwapFee,
        uint256 _targetSwapFee
    ) external;

    function disableVaultFees() external;

    function mint(
        uint256[] calldata tokenIds,
        uint256[] calldata amounts /* ignored for ERC721 vaults */
    ) external returns (uint256);

    function mintTo(
        uint256[] calldata tokenIds,
        uint256[] calldata amounts, /* ignored for ERC721 vaults */
        address to
    ) external returns (uint256);

    function redeem(uint256 amount, uint256[] calldata specificIds) external returns (uint256[] calldata);

    function redeemTo(
        uint256 amount,
        uint256[] calldata specificIds,
        address to
    ) external returns (uint256[] calldata);

    function swap(
        uint256[] calldata tokenIds,
        uint256[] calldata amounts, /* ignored for ERC721 vaults */
        uint256[] calldata specificIds
    ) external returns (uint256[] calldata);

    function swapTo(
        uint256[] calldata tokenIds,
        uint256[] calldata amounts, /* ignored for ERC721 vaults */
        uint256[] calldata specificIds,
        address to
    ) external returns (uint256[] calldata);

    function allValidNFTs(uint256[] calldata tokenIds) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/// @notice NFTXMarketplaceZap Contract Interface
interface INFTXZap {
    function mintAndSell721(
        uint256 vaultId,
        uint256[] calldata ids,
        uint256 minEthOut,
        address[] calldata path,
        address to
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IRandom {
    function requestRandomness() external returns (bytes32 requestId);

    function requests(bytes32 requestId) external view returns (uint256 randomness);
}