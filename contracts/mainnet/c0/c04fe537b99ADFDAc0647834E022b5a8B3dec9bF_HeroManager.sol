// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "../libraries/GameFi.sol";
import "../libraries/UnsafeMath.sol";

/** Contract handles every single Hero data */
contract HeroManager is Ownable, Multicall {
  using UnsafeMath for uint256;

  IERC20 public token;
  IERC721 public nft;

  address public lobbyManagerAddress;

  uint256 public constant HERO_MAX_LEVEL = 30;
  uint256 public constant HERO_MAX_EXP = 100 * 10**18;

  uint256 public baseLevelUpFee = 50000 * 10**18; // 50,000 $HRI
  uint256 public bonusLevelUpFee = 10000 * 10**18; // 10,000 $HRI

  uint256 public primaryPowerMultiplier = 10;
  uint256 public secondaryMultiplier = 8;
  uint256 public thirdMultiplier = 6;

  uint256 public rarityPowerBooster = 110;

  uint256 public bonusExp = 30 * 10**18; // From Level 1, every battle win will give 30 exp to the hero. And as level goes up, this will be reduced. Level 1 -> 2: 30, Lv 2 -> 3: 29, ...., Lv 29 -> 30: 2
  uint256 public expDiff = 4;

  uint256 public maxHeroEnergy = 5;
  uint256 public energyRecoveryTime = 1 hours;

  mapping(uint256 => GameFi.Hero) public heroes;

  mapping(uint256 => uint256) public heroesEnergy;
  mapping(uint256 => uint256) public heroesEnergyUsedAt;

  constructor(address tokenAddress, address nftAddress) {
    token = IERC20(tokenAddress);
    nft = IERC721(nftAddress);
  }

  function addHero(uint256 heroId, GameFi.Hero calldata hero)
    external
    onlyOwner
  {
    require(heroes[heroId].level == 0, "HeroManager: hero already added");
    heroes[heroId] = hero;
  }

  function levelUp(uint256 heroId, uint256 levels) external {
    uint256 currentLevel = heroes[heroId].level;
    require(nft.ownerOf(heroId) == msg.sender, "HeroManager: not a NFT owner");
    require(currentLevel < HERO_MAX_LEVEL, "HeroManager: hero max level");
    require(
      currentLevel + levels <= HERO_MAX_LEVEL,
      "HeroManager: too many levels up"
    );

    uint256 totalLevelUpFee = levelUpFee(heroId, levels);
    require(
      token.transferFrom(msg.sender, address(this), totalLevelUpFee),
      "HeroManager: not enough fee"
    );

    GameFi.Hero memory hero = heroes[heroId];

    heroes[heroId].level = currentLevel.add(levels);
    heroes[heroId].strength = hero.strength.add(levels.mul(hero.strengthGain));
    heroes[heroId].agility = hero.agility.add(levels.mul(hero.agilityGain));
    heroes[heroId].intelligence = hero.intelligence.add(
      levels.mul(hero.intelligenceGain)
    );
    heroes[heroId].experience = 0;
  }

  function spendHeroEnergy(uint256 heroId) external {
    require(
      msg.sender == lobbyManagerAddress,
      "HeroManager: callable by lobby battle only"
    );
    require(heroEnergy(heroId) > 0, "HeroManager: hero zero energy");

    uint256 currentEnergy = heroesEnergy[heroId];

    if (currentEnergy == maxHeroEnergy) {
      currentEnergy = 1;
    } else {
      currentEnergy = currentEnergy.add(1);

      if (currentEnergy == maxHeroEnergy) {
        heroesEnergyUsedAt[heroId] = block.timestamp;
      }
    }

    heroesEnergy[heroId] = currentEnergy;
  }

  function expUp(uint256 heroId, bool won) public {
    address caller = msg.sender;
    require(
      caller == lobbyManagerAddress || caller == address(this),
      "HeroManager: callable by lobby battle only"
    );
    uint256 hrLevel = heroes[heroId].level;

    if (hrLevel < HERO_MAX_LEVEL) {
      uint256 exp = won
        ? heroBonusExp(heroId)
        : heroBonusExp(heroId).div(expDiff);
      uint256 heroExp = heroes[heroId].experience;
      heroExp = heroExp.add(exp);
      if (heroExp >= HERO_MAX_EXP) {
        heroExp = heroExp.sub(HERO_MAX_EXP);
        hrLevel = hrLevel.add(1);
      }
      heroes[heroId].level = hrLevel;
      heroes[heroId].experience = heroExp;
    }
  }

  function bulkExpUp(uint256[] calldata heroIds, bool won) external {
    require(
      msg.sender == lobbyManagerAddress,
      "HeroManager: callable by lobby battle only"
    );

    for (uint256 i = 0; i < heroIds.length; i = i.add(1)) {
      expUp(heroIds[i], won);
    }
  }

  function levelUpFee(uint256 heroId, uint256 levels)
    public
    view
    returns (uint256)
  {
    uint256 currentLevel = heroes[heroId].level;
    uint256 bonusLvUpFee = bonusLevelUpFee;

    uint256 nextLevelUpFee = baseLevelUpFee.add(
      bonusLvUpFee.mul(currentLevel.sub(1))
    );

    uint256 levelsFee = nextLevelUpFee.mul(levels);
    uint256 totalLevelUpFee = levelsFee.add(
      bonusLvUpFee.mul((levels.mul(levels.sub(1))).div(2))
    );

    return totalLevelUpFee;
  }

  function heroEnergy(uint256 heroId) public view returns (uint256) {
    uint256 maxHE = maxHeroEnergy;
    uint256 energy = heroesEnergy[heroId];

    if (energy < maxHE) {
      return maxHE - energy;
    }

    if (block.timestamp - heroesEnergyUsedAt[heroId] > 1 days) {
      return maxHE;
    }

    return 0;
  }

  function heroPower(uint256 heroId) external view returns (uint256) {
    GameFi.Hero memory hero = heroes[heroId];

    uint256 stat1;
    uint256 stat2;
    uint256 stat3;

    if (hero.primaryAttribute == 0) {
      stat1 = hero.strength;
      stat2 = hero.intelligence;
      stat3 = hero.agility;
    }
    if (hero.primaryAttribute == 1) {
      stat1 = hero.agility;
      stat2 = hero.strength;
      stat3 = hero.intelligence;
    }
    if (hero.primaryAttribute == 2) {
      stat1 = hero.intelligence;
      stat2 = hero.agility;
      stat3 = hero.strength;
    }

    uint256 power = stat1 *
      primaryPowerMultiplier +
      stat2 *
      secondaryMultiplier +
      stat3 *
      thirdMultiplier;

    if (hero.rarity > 0) {
      power = (power * (rarityPowerBooster**hero.rarity)) / (100**hero.rarity);
    }

    return power;
  }

  function heroPrimaryAttribute(uint256 heroId)
    external
    view
    returns (uint256)
  {
    return heroes[heroId].primaryAttribute;
  }

  function heroLevel(uint256 heroId) public view returns (uint256) {
    return heroes[heroId].level;
  }

  function heroBonusExp(uint256 heroId) internal view returns (uint256) {
    uint256 level = heroLevel(heroId);
    return levelExp(level);
  }

  function levelExp(uint256 level) public view returns (uint256) {
    return bonusExp.sub(level.sub(1).mul(10**18));
  }

  function validateHeroIds(uint256[] calldata heroIds, address owner)
    external
    view
    returns (bool)
  {
    for (uint256 i = 0; i < heroIds.length; i = i.add(1)) {
      require(nft.ownerOf(heroIds[i]) == owner, "HeroManager: not hero owner");
    }
    return true;
  }

  function validateHeroEnergies(uint256[] calldata heroIds)
    external
    view
    returns (bool)
  {
    for (uint256 i = 0; i < heroIds.length; i = i.add(1)) {
      require(heroEnergy(heroIds[i]) > 0, "HeroManager: not enough energy");
    }
    return true;
  }

  function setLobbyManager(address lbAddr) external onlyOwner {
    lobbyManagerAddress = lbAddr;
  }

  function setRarityPowerBooster(uint256 value) external onlyOwner {
    rarityPowerBooster = value;
  }

  function setPrimaryPowerMultiplier(uint256 value) external onlyOwner {
    primaryPowerMultiplier = value;
  }

  function setSecondaryMultiplier(uint256 value) external onlyOwner {
    secondaryMultiplier = value;
  }

  function setThirdMultiplier(uint256 value) external onlyOwner {
    thirdMultiplier = value;
  }

  function setBaseLevelUpFee(uint256 value) external onlyOwner {
    baseLevelUpFee = value;
  }

  function setBonusLevelUpFee(uint256 value) external onlyOwner {
    bonusLevelUpFee = value;
  }

  function setBonusExp(uint256 value) external onlyOwner {
    bonusExp = value;
  }

  function setExpDiff(uint256 value) external onlyOwner {
    expDiff = value;
  }

  function setMaxHeroEnergy(uint256 value) external onlyOwner {
    maxHeroEnergy = value;
  }

  function setEnergyRecoveryTime(uint256 value) external onlyOwner {
    energyRecoveryTime = value;
  }

  function withdrawReserves(uint256 amount) external onlyOwner {
    token.transfer(msg.sender, amount);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Multicall.sol)

pragma solidity ^0.8.0;

import "./Address.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract Multicall {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        return results;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";

library GameFi {
  struct Hero {
    bytes32 name; // this is considered as hero's unique id in the ecosystem
    uint256 level;
    uint256 rarity;
    uint256 primaryAttribute; // 0: strength, 1: agility, 2: intelligence
    uint256 attackCapability; // 1: meleee, 2: ranged
    uint256 strength;
    uint256 strengthGain;
    uint256 agility;
    uint256 agilityGain;
    uint256 intelligence;
    uint256 intelligenceGain;
    uint256 experience; // (0 - 100) * 10**18
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

library UnsafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    unchecked {
      return a + b;
    }
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    unchecked {
      return a - b;
    }
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    unchecked {
      return a * b;
    }
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    unchecked {
      return a / b;
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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