// SPDX-License-Identifier: GPL-3.0
// solhint-disable-next-line
pragma solidity 0.8.12;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Interfaces/BAPGenesisInterface.sol";
import "./Interfaces/BAPMethaneInterface.sol";
import "./Interfaces/BAPUtilitiesInterface.sol";
import "./Interfaces/BAPTeenBullsInterface.sol";
import "./Interfaces/BAPOrchestratorInterfaceV2.sol";

/**
 * A number of codes are defined as error messages.
 * Codes are resembling HTTP statuses. This is the structure
 * CODE:SHORT
 * Where CODE is a number and SHORT is a short word or prase
 * describing the condition
 * CODES:
 * 100  contract status: open/closed, depleted. In general for any flag
 *     causing the mint to not to happen.
 * 200  parameters validation errors, like zero address or wrong values
 * 300  User payment amount errors like not enough funds.
 * 400  Contract amount/availability errors like not enough tokens or empty vault.
 * 500  permission errors, like not whitelisted, wrong address, not the owner.
 */
contract BAPOrchestratorV2 is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    string public project;
    address public bapGenesisAddr;
    address public bapMethAddr;
    address public bapUtilitiesAddr;
    address public bapTeenBullsAddr;
    address public originalOrchestratorAddr;
    address public orchestratorV1Addr;
    address public treasuryWallet;
    BAPGenesisInterface bapGenesis;
    BAPMethaneInterface bapMeth;
    BAPUtilitiesInterface bapUtilities;
    BAPTeenBullsInterface bapTeenBulls;
    BAPOrchestratorInterfaceV2 originalOrchestrator;
    BAPOrchestratorInterfaceV2 orchestratorV1;
    address public secret;
    uint256 public timeCounter = 1 days;
    uint256 public grazingPeriodTime = 31 days;
    mapping(uint256 => uint256) public claimedMeth;
    mapping(uint256 => bool) public mintingRefunded;
    mapping(uint256 => uint256) public godsMintingDate;
    mapping(uint256 => uint256) public bullLastClaim;
    mapping(uint256 => bool) public godBulls;
    bool private refundFlag = false;
    bool private claimFlag = false;
    uint256 godBullIndex = 10010;

    struct SignatureTeenBullStruct {
        address sender;
    }

    struct SignatureGodBullStruct {
        address sender;
        uint256 teen1;
        uint256 teen2;
        uint256 teen3;
        uint256 teen4;
    }

    constructor(
        address _bapGenesis,
        address _bapMethane,
        address _bapUtilities,
        address _bapTeenBulls,
        address _originalOrchestrator,
        address _orchestratorV1
    ) {
        require(_bapGenesis != address(0), "200:ZERO_ADDRESS");
        require(_bapMethane != address(0), "200:ZERO_ADDRESS");
        require(_originalOrchestrator != address(0), "200:ZERO_ADDRESS");

        project = "Bulls & Apes Project";
        bapGenesisAddr = _bapGenesis;
        bapMethAddr = _bapMethane;
        originalOrchestratorAddr = _originalOrchestrator;
        orchestratorV1Addr = _orchestratorV1;
        bapUtilitiesAddr = _bapUtilities;
        bapTeenBullsAddr = _bapTeenBulls;

        bapGenesis = BAPGenesisInterface(bapGenesisAddr);
        bapMeth = BAPMethaneInterface(bapMethAddr);
        originalOrchestrator = BAPOrchestratorInterfaceV2(
            _originalOrchestrator
        );
        orchestratorV1 = BAPOrchestratorInterfaceV2(_orchestratorV1);
        bapUtilities = BAPUtilitiesInterface(bapUtilitiesAddr);
        bapTeenBulls = BAPTeenBullsInterface(bapTeenBullsAddr);
    }

    function setGenesisContract(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "200:ZERO_ADDRESS");
        bapGenesisAddr = _newAddress;
        bapGenesis = BAPGenesisInterface(bapGenesisAddr);
    }

    function setMethaneContract(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "200:ZERO_ADDRESS");
        bapMethAddr = _newAddress;
        bapMeth = BAPMethaneInterface(bapMethAddr);
    }

    function setUtilitiesContract(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "200:ZERO_ADDRESS");
        bapUtilitiesAddr = _newAddress;
        bapUtilities = BAPUtilitiesInterface(bapUtilitiesAddr);
    }

    function setTeenBullsContract(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "200:ZERO_ADDRESS");
        bapTeenBullsAddr = _newAddress;
        bapTeenBulls = BAPTeenBullsInterface(bapTeenBullsAddr);
    }

    function initializeGodBulls(uint256[] memory gods, bool godBullFlag)
        external
        onlyOwner
    {
        uint256 bullsCount = gods.length;
        for (uint256 index = 0; index < bullsCount; index++) {
            godBulls[gods[index]] = godBullFlag;
        }
    }

    function claimMeth(
        bytes memory signature,
        uint256[] memory bulls,
        uint256[] memory gods
    ) external nonReentrant {
        uint256 bullsCount = bulls.length;
        uint256 godsCount = gods.length;

        require(
            _verifyClaimMeth(signature, bullsCount, godsCount),
            "Invalid Signature"
        );
        uint256 amount = 0;
        for (uint256 index = 0; index < godsCount; index++) {
            require(
                godBulls[gods[index]] == true || gods[index] > godBullIndex,
                "Not a God Bull"
            );
        }
        for (uint256 index = 0; index < bullsCount; index++) {
            require(godBulls[bulls[index]] == false, "Not a OG Bull");
        }
        for (uint256 index = 0; index < bullsCount; index++) {
            amount += _claimRewardsFromToken(bulls[index], false);
        }
        for (uint256 index = 0; index < godsCount; index++) {
            amount += _claimRewardsFromToken(gods[index], true);
        }
        bapMeth.claim(_msgSender(), amount);
    }

    function setTreasuryWallet(address _newTreasuryWallet) external onlyOwner {
        require(_newTreasuryWallet != address(0), "200:ZERO_ADDRESS");
        treasuryWallet = _newTreasuryWallet;
    }

    function setWhitelistedAddress(address _secret) external onlyOwner {
        require(_secret != address(0), "200:ZERO_ADDRESS");
        secret = _secret;
    }

    function setGrazingPeriodTime(uint256 _grazingPeriod) external onlyOwner {
        grazingPeriodTime = _grazingPeriod;
    }

    function setTimeCounter(uint256 _timeCounter) external onlyOwner {
        timeCounter = _timeCounter;
    }

    function totalClaimed(uint256 tokenId) public view returns (uint256) {
        return
            claimedMeth[tokenId] +
            orchestratorV1.claimedMeth(tokenId) +
            originalOrchestrator.claimedMeth(tokenId);
    }

    function getClaimableMeth(uint256 tokenId, bool isGodBull)
        external
        view
        returns (uint256 methAmount)
    {
        require(bapGenesis.tokenExist(tokenId), "Token does exist");

        uint256 startTime = bullLastClaim[tokenId];
        uint256 claimed = 0;

        // AFTER THE FIRST CLAIM THIS BLOCK GETS OMITTED
        if (startTime == 0) {
            if (godBulls[tokenId] == true || tokenId > godBullIndex) {
                if (godsMintingDate[tokenId] == 0) {
                    return 0;
                }
                startTime = godsMintingDate[tokenId];
            } else {
                startTime = bapGenesis.mintingDatetime(tokenId);
            }

            claimed = totalClaimed(tokenId);
        }

        uint256 timeFromCreation = (block.timestamp - startTime).div(
            timeCounter
        );

        methAmount =
            _dailyRewards(isGodBull, tokenId) *
            timeFromCreation -
            claimed;
    }

    function initializeGodMintingDate(
        uint256[] memory gods,
        uint256[] memory mintingDates
    ) external onlyOwner {
        uint256 bullsCount = gods.length;
        uint256 mintingDatesCount = mintingDates.length;
        require(bullsCount == mintingDatesCount, "Arrays are incorrect");
        for (uint256 index = 0; index < bullsCount; index++) {
            godsMintingDate[gods[index]] = mintingDates[index];
        }
    }

    function generateTeenBull(bytes memory signature) external nonReentrant {
        require(_verifyGenerateTeenBull(signature), "Signature is invalid");
        bapMeth.pay(600, 300);
        bapTeenBulls.generateTeenBull();
        bapUtilities.burn(1, 1);
    }

    function generateGodBull(
        bytes memory signature,
        uint256 bull1,
        uint256 bull2,
        uint256 bull3,
        uint256 bull4
    ) external nonReentrant {
        require(
            _verifyGenerateGodBull(signature, bull1, bull2, bull3, bull4),
            "Invalid Signature"
        );
        require(
            bapUtilities.balanceOf(msg.sender, 2) > 0,
            "Not enough Merger Orbs"
        );
        bapMeth.pay(4800, 2400);
        bapGenesis.generateGodBull();
        bapTeenBulls.burnTeenBull(bull1);
        bapTeenBulls.burnTeenBull(bull2);
        bapTeenBulls.burnTeenBull(bull3);
        bapTeenBulls.burnTeenBull(bull4);
        bapUtilities.burn(2, 1);
        godsMintingDate[bapGenesis.minted()] = block.timestamp;
    }

    function buyIncubator(
        bytes memory signature,
        uint256 bull1,
        uint256 bull2
    ) external nonReentrant {
        require(
            _verifyBuyIncubator(signature, bull1, bull2),
            "Invalid Signature"
        );
        bapGenesis.breedBulls(bull1, bull2);
        bapMeth.pay(600, 300);
        bapUtilities.purchaseIncubator();
    }

    function buyMergeOrb(bytes memory signature, uint256 teen)
        external
        nonReentrant
    {
        require(
            _verifyBuyMergeOrb(signature, teen),
            "Buy Merge Orb Signature is not valid"
        );
        bapMeth.pay(2400, 1200);
        bapTeenBulls.burnTeenBull(teen);
        bapUtilities.purchaseMergerOrb();
    }

    function setRefundFlag(bool _refundFlag) external onlyOwner {
        refundFlag = _refundFlag;
    }

    function setClaimFlag(bool _claimFlag) external onlyOwner {
        claimFlag = _claimFlag;
    }

    function refund(uint256 tokenId) external nonReentrant {
        require(treasuryWallet != address(0), "200:ZERO_ADDRESS");
        require(
            _refundPeriodAllowed() || refundFlag,
            "The Refund is not allowed"
        );
        require(
            mintingRefunded[tokenId] == false &&
                originalOrchestrator.mintingRefunded(tokenId) == false,
            "The token was already refunded"
        );
        require(
            bapGenesis.breedings(tokenId) == bapGenesis.maxBreedings(),
            "The bull breed"
        );

        require(totalClaimed(tokenId) == 0, "Tokens claimed for this Bull");

        require(
            bapGenesis.notAvailableForRefund(tokenId) == false,
            "The token was transfered at an invalid time"
        );

        bapGenesis.refund(msg.sender, tokenId);
        bapGenesis.safeTransferFrom(msg.sender, treasuryWallet, tokenId);
        mintingRefunded[tokenId] = true;
    }

    function _verifyBuyIncubator(
        bytes memory signature,
        uint256 token1,
        uint256 token2
    ) internal view returns (bool) {
        // Pack the payload
        bytes32 freshHash = keccak256(abi.encode(msg.sender, token1, token2));
        // Get the packed payload hash
        bytes32 candidateHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", freshHash)
        );

        // Verify if the fresh hash is signed with the provided signature
        return _verifyHashSignature(candidateHash, signature);
    }

    function _verifyBuyMergeOrb(bytes memory signature, uint256 teen)
        internal
        view
        returns (bool)
    {
        // Pack the payload
        bytes32 freshHash = keccak256(abi.encode(msg.sender, teen));
        // Get the packed payload hash
        bytes32 candidateHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", freshHash)
        );
        // Verify if the fresh hash is signed with the provided signature
        return _verifyHashSignature(candidateHash, signature);
    }

    function _verifyClaimMeth(
        bytes memory signature,
        uint256 bullsCount,
        uint256 godsCount
    ) internal view returns (bool) {
        // Pack the payload
        bytes32 freshHash = keccak256(
            abi.encode(msg.sender, bullsCount, godsCount)
        );
        // Get the packed payload hash
        bytes32 candidateHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", freshHash)
        );
        // Verify if the fresh hash is signed with the provided signature
        return _verifyHashSignature(candidateHash, signature);
    }

    function _verifyGenerateGodBull(
        bytes memory signature,
        uint256 bull1,
        uint256 bull2,
        uint256 bull3,
        uint256 bull4
    ) internal view returns (bool) {
        // Pack the payload
        bytes32 freshHash = keccak256(
            abi.encode(msg.sender, bull1, bull2, bull3, bull4)
        );
        // Get the packed payload hash
        bytes32 candidateHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", freshHash)
        );
        // Verify if the fresh hash is signed with the provided signature
        return _verifyHashSignature(candidateHash, signature);
    }

    function _verifyGenerateTeenBull(bytes memory signature)
        internal
        view
        returns (bool)
    {
        // Pack the payload
        bytes32 freshHash = keccak256(abi.encode(msg.sender));
        // Get the packed payload hash
        bytes32 candidateHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", freshHash)
        );
        // Verify if the fresh hash is signed with the provided signature
        return _verifyHashSignature(candidateHash, signature);
    }

    function _verifyHashSignature(bytes32 hash, bytes memory signature)
        internal
        view
        returns (bool)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (signature.length != 65) {
            return false;
        }
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        if (v < 27) {
            v += 27;
        }

        address signer = address(0);
        if (v == 27 || v == 28) {
            // solium-disable-next-line arg-overflow
            signer = ecrecover(hash, v, r, s);
        }
        return secret == signer;
    }

    function _dailyRewards(bool godBull, uint256 tokenId)
        internal
        view
        returns (uint256)
    {
        if (godBull) return 20;
        if (bapGenesis.breedings(tokenId) == 0 && bullLastClaim[tokenId] != 0)
            return 15;
        return 10;
    }

    function _refundPeriodAllowed() internal view returns (bool) {
        return
            block.timestamp >= bapGenesis.genesisTimestamp() + 31 days &&
            block.timestamp <= bapGenesis.genesisTimestamp() + 180 days;
    }

    function _claimRewardsFromToken(uint256 tokenId, bool isGodBull)
        internal
        returns (uint256)
    {
        require(
            bapGenesis.genesisTimestamp() + grazingPeriodTime <=
                block.timestamp ||
                claimFlag,
            "Grazing Period is not Finished"
        );
        require(bapGenesis.tokenExist(tokenId), "Token does exist");
        require(
            bapGenesis.ownerOf(tokenId) == _msgSender(),
            "Sender is not the owner"
        );

        uint256 startTime = bullLastClaim[tokenId];
        uint256 claimed = 0;

        // AFTER THE FIRST CLAIM THIS BLOCK GETS OMITTED
        if (startTime == 0) {
            if (godBulls[tokenId] == true || tokenId > godBullIndex) {
                if (godsMintingDate[tokenId] == 0) {
                    return 0;
                }
                startTime = godsMintingDate[tokenId];
            } else {
                startTime = bapGenesis.mintingDatetime(tokenId);
            }

            claimed = totalClaimed(tokenId);
        }

        uint256 timeFromCreation = (block.timestamp - startTime).div(
            timeCounter
        );

        uint256 methAmount = _dailyRewards(isGodBull, tokenId) *
            timeFromCreation -
            claimed;

        claimedMeth[tokenId] += methAmount;
        bullLastClaim[tokenId] = block.timestamp;

        return methAmount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface BAPUtilitiesInterface {
    function purchaseIncubator() external;

    function purchaseMergerOrb() external;

    function transferOwnership(address) external;

    function balanceOf(address, uint256) external returns (uint256);

    function burn(uint256, uint256) external;

    function airdrop(
        address,
        uint256,
        uint256
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface BAPTeenBullsInterface {
    function generateTeenBull() external;

    function generateMergerOrb() external;

    function ownerOf(uint256) external view returns (address);

    function burnTeenBull(uint256) external;

    function airdrop(address, uint256) external;

    function safeTransferFrom(
        address,
        address,
        uint256
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
interface BAPOrchestratorInterfaceV2 {
  function mintingRefunded(uint256) external returns (bool); 
  function claimedMeth(uint256) external view returns (uint256); 
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface BAPMethaneInterface {
  function name() external view returns (string memory);
  function maxSupply() external view returns (uint256);
  function claims(address) external view returns (uint256);
  function claim(address, uint256) external;
  function pay(uint256,uint256) external;
  function treasuryWallet() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
interface BAPGenesisInterface {
  function mintingDatetime(uint256) external view returns (uint256);
  function tokenExist(uint256) external view returns (bool);
  function ownerOf(uint256) external view returns (address);
  function dailyRewards(bool) external view returns (uint256);
  function initialMintingTimestamp() external view returns (uint256);
  function originalMintingPrice(uint256) external view returns (uint256);
  function breedings(uint256) external view returns (uint256);
  function maxBreedings() external view returns (uint256);
  function breedBulls(uint256,uint256) external;
  function _orchestrator() external view returns (address);
  function approve(address, uint256) external;
  function refund(address, uint256) external payable;
  function safeTransferFrom(address,address,uint256) external;
  function refundPeriodAllowed(uint256) external view returns(bool);
  function notAvailableForRefund(uint256) external returns(bool);
  function generateGodBull() external;
  function genesisTimestamp() external view returns(uint256);
  function setGrazingPeriodTime(uint256) external;
  function setTimeCounter(uint256) external; 
  function secret() external view returns(address);
  function minted() external view returns(uint256);
  function updateBullBreedings(uint256) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
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

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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