/**
 *Submitted for verification at Etherscan.io on 2022-08-20
*/

// File: Interfaces/BAPOrchestratorInterface.sol


pragma solidity ^0.8.12;

interface BAPOrchestratorInterface {
    function mintingRefunded(uint256) external returns (bool);

    function claimedMeth(uint256) external view returns (uint256);

    function godsMintingDate(uint256) external view returns (uint256);
}

// File: Interfaces/BAPTeenBullsInterface.sol


pragma solidity ^0.8.12;

interface BAPTeenBullsInterface {
  function generateTeenBull() external;
  function generateMergerOrb() external;  
  function ownerOf(uint256) external view returns (address);
  function burnTeenBull(uint) external;
}
// File: Interfaces/BAPUtilitiesInterface.sol


pragma solidity ^0.8.12;

interface BAPUtilitiesInterface {
    function purchaseIncubator() external;
    function purchaseMergerOrb() external;
    function balanceOf(address, uint256) external returns(uint256);
    function burn(uint256, uint256) external;
}

// File: Interfaces/BAPMethaneInterface.sol


pragma solidity ^0.8.12;

interface BAPMethaneInterface {
  function name() external view returns (string memory);
  function maxSupply() external view returns (uint256);
  function claims(address) external view returns (uint256);
  function claim(address, uint256) external;
  function pay(uint256,uint256) external;
  function treasuryWallet() external view returns (address);
}
// File: Interfaces/BAPGenesisInterface.sol


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


// File: @openzeppelin/contracts/utils/math/SafeMath.sol


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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: BAPOrchestrator.sol


// solhint-disable-next-line
pragma solidity 0.8.12;









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

contract BAPOrchestrator is ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    string public project = "Bulls & Apes Project";
    // CONTRACTS ADDRESSES
    address public bapGenesisAddr;
    address public bapMethAddr;
    address public bapUtilitiesAddr;
    address public bapTeenBullsAddr;
    address public treasuryWallet;
    address public orchestratorV1;
    address public orchestratorV2;
    // SIGNER
    address public secret;
    // VARIABLES
    // uint256 public timeCounter = 1 days; // MAINNET
    uint256 public timeCounter = 1 hours; // TESTNET
    uint256 public grazingPeriodTime = 31 days;
    uint256 public powerStartTime;
    uint256 godBullIndex = 10010;

    bool private refundFlag = false;
    bool private claimFlag = false;

    mapping(uint256 => uint256) public claimedMeth;
    mapping(uint256 => uint256) public breedingsLeft;
    mapping(uint256 => uint256) public godsMintingDate;
    mapping(uint256 => uint256) public godBullPower;
    mapping(uint256 => uint256) public godBullLastClaim;
    mapping(uint256 => bool) public mintingRefunded;
    mapping(uint256 => bool) public extraBreedClaimed;
    mapping(uint256 => bool) public isTokenUpdated;

    // CONTRACTS INTERFACES
    BAPGenesisInterface bapGenesis;
    BAPMethaneInterface bapMeth;
    BAPUtilitiesInterface bapUtilities;
    BAPTeenBullsInterface bapTeenBulls;

    constructor(
        address _bapGenesis,
        address _bapMethane,
        address _bapUtilities,
        address _bapTeenBulls,
        address _orchestratorV1,
        address _orchestratorV2
    ) {
        bapGenesisAddr = _bapGenesis;
        bapMethAddr = _bapMethane;
        bapUtilitiesAddr = _bapUtilities;
        bapTeenBullsAddr = _bapTeenBulls;
        orchestratorV1 = _orchestratorV1;
        orchestratorV2 = _orchestratorV2;

        bapGenesis = BAPGenesisInterface(_bapGenesis);
        bapMeth = BAPMethaneInterface(_bapMethane);
        bapUtilities = BAPUtilitiesInterface(_bapUtilities);
        bapTeenBulls = BAPTeenBullsInterface(_bapTeenBulls);

        powerStartTime = block.timestamp;
    }

    modifier noZeroAddress(address _address) {
        require(_address != address(0), "200:ZERO_ADDRESS");
        _;
    }

    modifier checkUpdate(uint256 tokenId) {
        _updateToken(tokenId);
        _;
    }

    function claimMeth(
        bytes memory signature,
        uint256[] memory bulls,
        uint256[] memory gods
    ) external nonReentrant {
        uint256 bullsCount = bulls.length;
        uint256 godsCount = gods.length;

        require(
            _verifyHashSignature(
                keccak256(abi.encode(msg.sender, bullsCount, godsCount)),
                signature
            ),
            "Signature is invalid"
        );
        require(
            bapGenesis.genesisTimestamp() + grazingPeriodTime <=
                block.timestamp ||
                claimFlag,
            "Grazing Period is not Finished"
        );

        uint256 claimableMeth;

        for (uint256 i; i < godsCount; i++) {
            claimableMeth += _claimMeth(gods[i]);
        }

        for (uint256 i; i < bullsCount; i++) {
            claimableMeth += _claimMeth(bulls[i]);
        }

        bapMeth.claim(_msgSender(), claimableMeth);
    }

    function generateTeenBull(bytes memory signature) external nonReentrant {
        require(
            _verifyHashSignature(keccak256(abi.encode(msg.sender)), signature),
            "Signature is invalid"
        );
        bapMeth.pay(600, 300);
        bapUtilities.burn(1, 1);
        bapTeenBulls.generateTeenBull();
    }

    function generateGodBull(
        bytes memory signature,
        uint256 bull1,
        uint256 bull2,
        uint256 bull3,
        uint256 bull4
    ) external nonReentrant {
        require(
            _verifyHashSignature(
                keccak256(abi.encode(msg.sender, bull1, bull2, bull3, bull4)),
                signature
            ),
            "Signature is invalid"
        );
        bapMeth.pay(4800, 2400);
        _burnTeen(bull1);
        _burnTeen(bull2);
        _burnTeen(bull3);
        _burnTeen(bull4);
        bapUtilities.burn(2, 1);
        bapGenesis.generateGodBull();
        godsMintingDate[bapGenesis.minted()] = block.timestamp;
        isTokenUpdated[bapGenesis.minted()] = true;
    }

    function buyIncubator(
        bytes memory signature,
        uint256 bull1,
        uint256 bull2
    ) external nonReentrant {
        require(
            _verifyHashSignature(
                keccak256(abi.encode(msg.sender, bull1, bull2)),
                signature
            ),
            "Signature is invalid"
        );
        _breedToken(bull1);
        _breedToken(bull2);
        bapMeth.pay(600, 300);
        bapUtilities.purchaseIncubator();
    }

    function claimExtraBreeding(uint256 tokenId, uint256 godBull)
        external
        checkUpdate(godBull)
    {
        require(
            bapGenesis.ownerOf(tokenId) == msg.sender,
            "Only the owner can claim"
        );
        require(bapGenesis.ownerOf(godBull) == msg.sender, "Not your god bull");
        require(
            !extraBreedClaimed[tokenId],
            "This bull already got and extra breed"
        );
        require(
            godsMintingDate[godBull] > 0 || godBull > godBullIndex,
            "Not a god bull"
        );
        require(
            getBullPower(godBull) == 100,
            "This bull doesn't have enough power"
        );

        uint256 currentBreeds = bapGenesis.breedings(tokenId);
        require(currentBreeds == 0, "This bull has breeds available");

        bapMeth.pay(2000, 500);

        godBullPower[godBull] = 0;
        godBullLastClaim[godBull] = block.timestamp;

        extraBreedClaimed[tokenId] = true;
        breedingsLeft[tokenId] = 1;
    }

    function buyMergeOrb(bytes memory signature, uint256 teen)
        external
        nonReentrant
    {
        require(
            _verifyHashSignature(
                keccak256(abi.encode(msg.sender, teen)),
                signature
            ),
            "Signature is invalid"
        );
        bapMeth.pay(2400, 1200);
        _burnTeen(teen);
        bapUtilities.purchaseMergerOrb();
    }

    function refund(uint256 tokenId)
        external
        nonReentrant
        noZeroAddress(treasuryWallet)
        checkUpdate(tokenId)
    {
        require(
            _refundPeriodAllowed() || refundFlag,
            "The Refund is not allowed"
        );
        require(
            mintingRefunded[tokenId] == false,
            "The token was already refunded"
        );
        require(
            bapGenesis.breedings(tokenId) == bapGenesis.maxBreedings(),
            "The bull breed"
        );

        require(claimedMeth[tokenId] == 0, "Tokens claimed for this Bull");

        require(
            bapGenesis.notAvailableForRefund(tokenId) == false,
            "The token was transfered at an invalid time"
        );

        bapGenesis.refund(msg.sender, tokenId);
        bapGenesis.safeTransferFrom(msg.sender, treasuryWallet, tokenId);
        mintingRefunded[tokenId] = true;
    }

    // INTERNAL FUNCTIONS

    function _claimMeth(uint256 tokenId)
        internal
        checkUpdate(tokenId)
        returns (uint256 amount)
    {
        require(
            bapGenesis.ownerOf(tokenId) == _msgSender(),
            "Sender is not the owner"
        );

        if (godsMintingDate[tokenId] > 0 || tokenId > godBullIndex) {
            amount = getClaimableMeth(tokenId, true);
        } else {
            amount = getClaimableMeth(tokenId, false);
        }

        claimedMeth[tokenId] += amount;
    }

    function _breedToken(uint256 tokenId) internal {
        require(
            bapGenesis.ownerOf(tokenId) == msg.sender,
            "Only the owner can breed"
        );

        uint256 currentBreeds = bapGenesis.breedings(tokenId);

        if (currentBreeds > 0) {
            bapGenesis.updateBullBreedings(tokenId);
        } else {
            require(breedingsLeft[tokenId] > 0, "No more breadings left");
            breedingsLeft[tokenId] = 0;
        }
    }

    function _burnTeen(uint256 tokenId) internal {
        require(
            bapTeenBulls.ownerOf(tokenId) == msg.sender,
            "Only the owner can burn"
        );

        bapTeenBulls.burnTeenBull(tokenId);
    }

    function _updateToken(uint256 tokenId) internal {
        if (isTokenUpdated[tokenId]) {
            return;
        }
        BAPOrchestratorInterface v1 = BAPOrchestratorInterface(orchestratorV1);
        BAPOrchestratorInterface v2 = BAPOrchestratorInterface(orchestratorV2);

        claimedMeth[tokenId] =
            v1.claimedMeth(tokenId) +
            v2.claimedMeth(tokenId);
        godsMintingDate[tokenId] = v2.godsMintingDate(tokenId);
        mintingRefunded[tokenId] =
            v1.mintingRefunded(tokenId) ||
            v2.mintingRefunded(tokenId);

        isTokenUpdated[tokenId] = true;
    }

    function _godMintingDate(uint256 tokenId) public view returns (uint256) {
        if (isTokenUpdated[tokenId]) {
            return godsMintingDate[tokenId];
        }

        BAPOrchestratorInterface v2 = BAPOrchestratorInterface(orchestratorV2);
        return v2.godsMintingDate(tokenId);
    }

    function _claimedMeth(uint256 tokenId) public view returns (uint256) {
        if (isTokenUpdated[tokenId]) {
            return claimedMeth[tokenId];
        }

        BAPOrchestratorInterface v1 = BAPOrchestratorInterface(orchestratorV1);
        BAPOrchestratorInterface v2 = BAPOrchestratorInterface(orchestratorV2);

        return v1.claimedMeth(tokenId) + v2.claimedMeth(tokenId);
    }

    // VIEW FUNCTIONS

    function getClaimableMeth(uint256 tokenId, bool isGodBull)
        public
        view
        returns (uint256 methAmount)
    {
        uint256 timeFromCreation;

        if (isGodBull) {
            timeFromCreation = (block.timestamp - _godMintingDate(tokenId)).div(
                    timeCounter
                );
        } else {
            timeFromCreation = (block.timestamp -
                bapGenesis.mintingDatetime(tokenId)).div(timeCounter);
        }

        methAmount =
            (_dailyRewards(isGodBull) * timeFromCreation) -
            _claimedMeth(tokenId);
    }

    function getBullPower(uint256 tokenId) public view returns (uint256) {
        uint256 currentPower = godBullPower[tokenId];

        if (currentPower == 100) {
            return currentPower;
        } else {
            uint256 startTime = godBullLastClaim[tokenId] == 0
                ? powerStartTime
                : godBullLastClaim[tokenId];
            uint256 timeWithoutClaiming = block.timestamp - startTime;

            // uint256 unclaimedPower = (timeWithoutClaiming * 100) / 30 days; // 30 days on MAINNET
            uint256 unclaimedPower = (timeWithoutClaiming * 100) / 30 minutes; // 30 minutes on TESTNET

            currentPower += unclaimedPower;

            return currentPower > 100 ? 100 : currentPower;
        }
    }

    function _dailyRewards(bool godBull) internal pure returns (uint256) {
        if (godBull) return 20;
        return 10;
    }

    function _refundPeriodAllowed() internal view returns (bool) {
        return
            block.timestamp >= bapGenesis.genesisTimestamp() + 31 days &&
            block.timestamp <= bapGenesis.genesisTimestamp() + 180 days;
    }

    function _verifyHashSignature(bytes32 freshHash, bytes memory signature)
        internal
        view
        returns (bool)
    {
        bytes32 hash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", freshHash)
        );

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

    // OWNER FUNCTIONS

    function setGenesisContract(address _newAddress)
        external
        onlyOwner
        noZeroAddress(_newAddress)
    {
        bapGenesisAddr = _newAddress;
        bapGenesis = BAPGenesisInterface(bapGenesisAddr);
    }

    function setMethaneContract(address _newAddress)
        external
        onlyOwner
        noZeroAddress(_newAddress)
    {
        bapMethAddr = _newAddress;
        bapMeth = BAPMethaneInterface(bapMethAddr);
    }

    function setUtilitiesContract(address _newAddress)
        external
        onlyOwner
        noZeroAddress(_newAddress)
    {
        bapUtilitiesAddr = _newAddress;
        bapUtilities = BAPUtilitiesInterface(bapUtilitiesAddr);
    }

    function setTeenBullsContract(address _newAddress)
        external
        onlyOwner
        noZeroAddress(_newAddress)
    {
        bapTeenBullsAddr = _newAddress;
        bapTeenBulls = BAPTeenBullsInterface(bapTeenBullsAddr);
    }

    function setTreasuryWallet(address _newTreasuryWallet)
        external
        onlyOwner
        noZeroAddress(_newTreasuryWallet)
    {
        treasuryWallet = _newTreasuryWallet;
    }

    function setPrevOrchestrators(
        address _orchestratorV1,
        address _orchestratorV2
    )
        external
        onlyOwner
        noZeroAddress(_orchestratorV1)
        noZeroAddress(_orchestratorV2)
    {
        orchestratorV1 = _orchestratorV1;
        orchestratorV2 = _orchestratorV2;
    }

    function setWhitelistedAddress(address _secret)
        external
        onlyOwner
        noZeroAddress(_secret)
    {
        secret = _secret;
    }

    function setGrazingPeriodTime(uint256 _grazingPeriod) external onlyOwner {
        grazingPeriodTime = _grazingPeriod;
    }

    function setTimeCounter(uint256 _timeCounter) external onlyOwner {
        timeCounter = _timeCounter;
    }

    function setRefundFlag(bool _refundFlag) external onlyOwner {
        refundFlag = _refundFlag;
    }

    function setClaimFlag(bool _claimFlag) external onlyOwner {
        claimFlag = _claimFlag;
    }
}