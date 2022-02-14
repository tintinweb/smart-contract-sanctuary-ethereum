// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./IHeroes.sol";
import "./Traits.sol";

contract Cave is Ownable, IERC721Receiver, Pausable {

  // struct to store a stake's token, owner, and earning values
  struct Stake {
    uint16 tokenId;
    uint80 value;
    address owner;
  }

  event TokenStaked(address owner, uint256 tokenId, uint256 value);
  event HeroClaimed(uint256 tokenId, uint256 earned, bool unstaked);

  // reference to the Woolf NFT contract
  IHeroes heroes;

  // maps tokenId to stake

  mapping(uint256 => Stake) public theCave; 

  mapping(address => Stake[]) public theCaveV2; 

  uint256 public constant MINIMUM_TO_EXIT = 0 days;

  // number of Sheep staked in the theCave
  uint256 public totalExplorers;

  // emergency rescue to allow unstaking without any checks
  bool public rescueEnabled = false;

  /**
   * @param _heroes reference to the Heroes NFT contract
   */
  constructor(address _heroes) { 
    heroes = IHeroes(_heroes);
  }

  /** STAKING */

  /**
   * adds exploring NFT Heroes to the theCave
   * @param account the address of the staker
   * @param tokenIds the IDs of the NFT Heroes
   */
  function addManyToTheCave(address account, uint16[] calldata tokenIds) external {
    require(account == _msgSender() || _msgSender() == address(heroes), "DONT GIVE YOUR TOKENS AWAY");
    for (uint i = 0; i < tokenIds.length; i++) {
      if (_msgSender() != address(heroes)) { // dont do this step if its a mint + stake
        require(heroes.ownerOf(tokenIds[i]) == _msgSender(), "AINT YO TOKEN");
        heroes.transferFrom(_msgSender(), address(this), tokenIds[i]);
      } else if (tokenIds[i] == 0) {
        continue; // there may be gaps in the array for stolen tokens
      }

     _addExplorersTotheCave(account, tokenIds[i]);
    }
  }

  /**
   * adds a single Sheep to the theCave
   * @param account the address of the staker
   * @param tokenId the ID of the Sheep to add to the theCave
   */
  function _addExplorersTotheCave(address account, uint256 tokenId) internal whenNotPaused {
    theCave[tokenId] = Stake({
      owner: account,
      tokenId: uint16(tokenId),
      value: uint80(block.timestamp)
    });

    theCaveV2[account].push(Stake({
      owner: account,
      tokenId: uint16(tokenId),
      value: uint80(block.timestamp)
    }));

    totalExplorers += 1;
    emit TokenStaked(account, tokenId, block.timestamp);
  }

  
  /** CLAIMING / UNSTAKING */

  /**
   * realize $WOOL earnings and optionally unstake tokens from the theCave / Pack
   * to unstake a Sheep it will require it has 2 days worth of $WOOL unclaimed
   * @param tokenIds the IDs of the tokens to claim earnings from
   * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
   */
  function claimManyFromtheCaveAndPack(uint16[] calldata tokenIds, bool unstake) external whenNotPaused {
    uint256 owed = 0;
    for (uint i = 0; i < tokenIds.length; i++) {
        owed += _claimExplorersFromTheCave(tokenIds[i], unstake);
    }
    if (owed == 0) return;
        // gold.mint(_msgSender(), owed);
  }

  /**
   * realize $WOOL earnings for a single Sheep and optionally unstake it
   * if not unstaking, pay a 20% tax to the staked Wolves
   * if unstaking, there is a 50% chance all $WOOL is stolen
   * @param tokenId the ID of the Sheep to claim earnings from
   * @param unstake whether or not to unstake the Sheep
   * @return owed - the amount of $WOOL earned
   */
  function _claimExplorersFromTheCave(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
    Stake memory stake = theCave[tokenId];
    require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
    // require(!(unstake && block.timestamp - stake.value < MINIMUM_TO_EXIT), "GONNA BE COLD WITHOUT TWO DAY'S WOOL");
    if (unstake) {
      heroes.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // send back Sheep
      delete theCave[tokenId];
      totalExplorers -= 1;
    } else {
      theCave[tokenId] = Stake({
        owner: _msgSender(),
        tokenId: uint16(tokenId),
        value: uint80(block.timestamp)
      }); // reset stake
    }
    emit HeroClaimed(tokenId, owed, unstake);
  }

 
  /**
   * emergency unstake tokens
   * @param tokenIds the IDs of the tokens to claim earnings from
   */
  function rescue(uint256[] calldata tokenIds) external {
    require(rescueEnabled, "RESCUE DISABLED");
    uint256 tokenId;
    Stake memory stake;
    for (uint i = 0; i < tokenIds.length; i++) {
        tokenId = tokenIds[i];
        stake = theCave[tokenId];
        require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
        heroes.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // send back Sheep
        delete theCave[tokenId];
        totalExplorers -= 1;
        emit HeroClaimed(tokenId, 0, true);
      
    }
  }

  /** ADMIN */

  /**
   * allows owner to enable "rescue mode"
   * simplifies accounting, prioritizes tokens out in emergency
   */
  function setRescueEnabled(bool _enabled) external onlyOwner {
    rescueEnabled = _enabled;
  }

  /**
   * enables owner to pause / unpause minting
   */
  function setPaused(bool _paused) external onlyOwner {
    if (_paused) _pause();
    else _unpause();
  }

  /** READ ONLY */

  /**
   * generates a pseudorandom number
   * @param seed a value ensure different outcomes for different sources in the same block
   * @return a pseudorandom value
   */
  function random(uint256 seed) internal view returns (uint256) {
    return uint256(keccak256(abi.encodePacked(
      tx.origin,
      blockhash(block.number - 1),
      block.timestamp,
      seed
    )));
  }

  function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
      require(from == address(0x0), "Cannot send tokens to theCave directly");
      return IERC721Receiver.onERC721Received.selector;
    }

  
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

struct Traits {
    uint256 race;
    uint256 pants;
    uint256 weapon;
    uint256 shield;
    uint256 clothes;
    uint256 head;
    uint256 shoes;
    uint256 hair;
    uint256 bg;
    uint256 magic;
    uint256 strength;
    uint256 intelligence;
    uint256 stamina;
    uint256 dexterity;
    uint256 creativity;
  }

interface IHeroes {
  function CDN_ENABLED (  ) external view returns ( bool );
  function CDN_PREFIX (  ) external view returns ( string memory);
  function approve ( address to, uint256 tokenId ) external;
  function balanceOf ( address owner ) external view returns ( uint256 );
  function enableCdn ( bool value, string memory prefix ) external;
  function genSvg ( uint256 tokenId ) external view returns ( string memory);
  function genTraits ( uint256 tokenId ) external view returns ( Traits memory );
  function getApproved ( uint256 tokenId ) external view returns ( address );
  function getJsonString ( uint256 tokenId ) external view returns ( string memory);
  function getSeed ( uint256 tokenId ) external view returns ( uint256 );
  function getSeedPart ( uint256 tokenId, uint256 num ) external view returns ( uint16 );
  function isApprovedForAll ( address owner, address operator ) external view returns ( bool );
  function merlinMint ( uint256 amount ) external;
  function mint ( uint256 amount ) external;
  function mintCustom ( string memory tokenUriHash, address to ) external;
  function name (  ) external view returns ( string memory);
  function owner (  ) external view returns ( address );
  function ownerOf ( uint256 tokenId ) external view returns ( address );
  function renounceOwnership (  ) external;
  function safeTransferFrom ( address from, address to, uint256 tokenId ) external;
  function safeTransferFrom ( address from, address to, uint256 tokenId, bytes memory _data ) external;
  function setApprovalForAll ( address operator, bool approved ) external;
  function setBaseUri ( string memory baseUri ) external;
  function supportsInterface ( bytes4 interfaceId ) external view returns ( bool );
  function symbol (  ) external view returns ( string memory );
  function tokenByIndex ( uint256 index ) external view returns ( uint256 );
  function tokenIdToSeed ( uint256 ) external view returns ( uint256 );
  function tokenOfOwnerByIndex ( address owner, uint256 index ) external view returns ( uint256 );
  function tokenURI ( uint256 tokenId ) external view returns ( string memory);
  function totalSupply (  ) external view returns ( uint256 );
  function transferFrom ( address from, address to, uint256 tokenId ) external;
  function transferOwnership ( address newOwner ) external;
  function updateDescription ( string memory d ) external;
  function updateSigner ( address signer ) external;
  function withdraw ( address sendTo ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract HeroTraits {
  function getPantsLength() public pure returns (uint256) {
    return getPants().length;
  }

  function getPants() public pure returns (string[2][5] memory) {
    return [
      ["White Pants", "QmS1ugwVyGemvvcu8xhvYPLJcM9XiCzev19hL5S4118mvY"],
      ["Red Pants", "QmQRw479rzessc1ms2kcnKQCvCs2aQ1Ep25vK7xgo9cEJt"],
      ["Blue Pants", "QmePEJz87mRjQt9BmYib14Fcxn8j13Xkdj6MfYoUZbQi79"],
      ["Green Pants", "QmZ6sjTg936aJCM67NPsPcCjMphAYEWoyQXHNHduKzLyf7"],
      ["Purple Pants", "QmPP9edeKhcJAM2YKxVfJhLaFHmLxJLm3WGcwWBvNvGXkZ"]
    ];
  }

  function getWeaponsLength() public pure returns (uint256) {
    return getWeapons().length;
  }

  function getWeapons() public pure returns (string[2][19] memory) {
    return [
      ["", ""],
      ["Boomerang of Wood", "QmeZpiK4w2G4nQnEsm9m83h1oZXSaxX5P9tg1ai7cEzCvc"],
      ["Bow of Focus", "QmNSq5KzbDhRJNuFkUmLc3MZBe5fcVKbvQcNSfThsG4KXw"],
      ["Mythal Short Sword", "Qmbbz8kkycoEK4r3oMUyw3aqrTQbCfdTno9i9eCKfFTCmz"],
      ["Bow of Honor", "QmNMApPhGawYMQtCsVNbkD2tSsyA7wfHeNuspw8jSrFaBL"],
      ["Axe of Honor", "QmeLEVz3Jy2FhWRBrQqN8szyUhYtjFxDPGVHxnTJY1xd2h"],
      ["Wood Long Sword", "QmXnwjgest5CZVz5ZhUyNnLo1diWFhkKhBck98xY4cpvRP"],
      ["Boomerang of Flight", "QmPeNnTj25uXJz67mFrJr4ro1zxENYXAGX6kfSxAC9GBxs"],
      ["Axe of Wonder", "QmT32TRmyg1xJCA9n7oFBRcuRW5vbb5TboXh5LygyLTXbi"],
      ["Bow of Mystery", "QmbQLEKE1QbGnqNjKeBLLVwcDEoQNB98fsoEQgUbVgrPJk"],
      ["Axe of Strength", "QmRfhpxsSQHCmsxGPbSDAD7rTKAjVfqgHVBfdoVZBALWFC"],
      [
        "Elvish Staff of the Forest",
        "QmZTTFEmaGu54yj9kUwH3xL4mZrfXJXp8RtzqYMHMYww6p"
      ],
      ["Staff of the Sea", "QmUsxTdawFhmWPEbBwqRUi9SGpNBeUN8RwxUUQczxVP8TX"],
      ["Universe Staff", "Qmab3zQ2n1ZPYpTEgkivDHuryM6A5P1sTjCQoWN5N9ADWE"],
      ["Mythal Long Sword", "QmSx6MiY29hFoYV2pnehEdbmuFipwupz2y2DJZyCN54jdZ"],
      ["Wood Short Sword", "QmWFFLygzSa9UXNJAtthRAurazVXjhfZ1ZsDAAsFrKWSQm"],
      ["Boomerang of Focus", "QmXPDw8pxgnsFsGoz4bw7cWA2G1ZK1MDXArNKHr1VPv3GQ"],
      ["Iron Short Sword", "QmTqDh8schE195bh6HSsoPfYLVYZLRrXaRen92nJfZcFDC"],
      ["Iron Long Sword", "QmfYEHBEReGSDKWZuRUBMRiHGhiBo1jTFwpWnVaAG11saw"]
    ];
  }

  function getBgLength() public pure returns (uint256) {
    return getBg().length;
  }

  function getBg() public pure returns (string[26] memory) {
    return [
      "#FEDD00",
      "#74D1EA",
      "#9DE7D7",
      "#9E978E",
      "#84754E",
      "#00B08B",
      "#222223",
      "#6B4C4C",
      "#ff2424",
      "#FF808B",
      "#DF1995",
      "#C1A7E2",
      "#685BC7",
      "#DDDAE8",
      "#1B365D",
      "#A4BCC2",
      "#407EC9",
      "#009CDE",
      "#003865",
      "#40C1AC",
      "#279989",
      "#00BFB3",
      "#006F62",
      "#ADDC91",
      "#007041",
      "#58eb34"
    ];
  }

  function getRaceLength() public pure returns (uint256) {
    return getRace().length;
  }

  function getRace() public pure returns (string[2][22] memory) {
    return [
      ["Human", "QmbVrpTTEciNQPxb8TjntcmpQMDLrzgEsJxYrpGanCmH88"],
      ["Human", "QmWTzCYevtrCY9Yu9HZ1RudJ5DZ3ySMbbb6V8j1GMoFd2W"],
      ["Human", "QmYhchiEeh4iJPYSksxoUAoy9SZCCEU21UQzEyeFxWBcBj"],
      ["Undead", "QmTtNfnd3HZ7moKrzaJaYyUM5idGbKy2sgHE14fpeyU9UL"],
      ["Skeleton", "QmcMDNnc8SNjwvPBpcb6hXG3yjz9WSiQ5qzbJTZre7N2uB"],
      ["Wizard", "QmYotarEMJ98MHfZGDKhsgCcZU54EzTRPCuS88vG9PBUtd"],
      ["Ghost", "QmTuv44nHYMAix3L36HuBkPV5sQ6NPiGhxSFGSTnAHipJk"],
      ["Frogling", "QmPXTBPcjrxrjwAaH9VaLzV8uZVpHuy2VnytHT1LWsYWuX"],
      ["Pizza", "QmaJFAM6iV473UUcEQUPP7hCtP1Zh5jspvMHb9sJYiyutJ"],
      ["Slate Monkey", "QmNZezfUXKEQZkrXfobHsudcqqAECt97yYZQRUV12jkNbj"],
      ["Emerald Monkey", "Qmdy1tBPBa85TeDMYb9KVPHanU7Wor39yLEpAJwEUDfgK8"],
      ["Red Monkey", "Qmb23Pp17Xg5nBQJnfkzQ4rMWPKYnNNWqJcYDaDoJJnwSN"],
      ["Gold Slate Monkey", "QmNn3agjVqz4WFNvcm3Srzg2EuKJoJi2W2t32E1aDVhAwg"],
      ["White Monkey", "QmTH9fLyHLzbP6KXUFdJKCKYZqPUHEv7vrYeP95s8AZ57B"],
      ["Emerald Red Monkey", "QmZJQQE2QS9kMHhUe1PbCNnG1QvGH7hiW6sPETZtqpeEZK"],
      ["Yellow Monkey", "QmRdNLRMzuTmEuQZVtJAXj9ydxs3Ztb1EdCcF8eqRFQBBe"],
      ["Honey Monkey", "QmbgrRnunnkJSS9L945bvbP9gd54nRJ8D6YMi1jECvHhei"],
      ["Red Furred Monkey", "QmdHwSAhmthUbTUfSTqD7EMFWcZ13LLZbvoNTYgKjJb5Vj"],
      ["Snow Monkey", "QmYvjKEGeSZH2dMhSvgooPt5AatSZzQm2UvMBNhoKvUvER"],
      ["Brown Monkey", "QmehwhevsQdDyAoG2maHFA7Pip4x6KLVRU1KVfmV4pfDmu"],
      ["Gold Monkey", "QmTsvwBm7MTRgZBhLmV2GFtC7FzBggwcNNWDmk5iNyk2oP"],
      ["Tree Monkey", "QmYJBTHYE8WjNFV2udVre3yXTy9Y5xwScBW4bgHvaoPL5r"]
    ];
  }

  function getClothesLength() public pure returns (uint256) {
    return getClothes().length;
  }

  function getClothes() public pure returns (string[2][25] memory) {
    return [
      ["", ""],
      ["Robe of Fire", "QmUH91Yysb2SsDNKZSrkUMevUcoSU3dmcvpcozWAuEvr18"],
      ["Shirt of Mystery", "QmXRYw9yfgDYAU27KMQafT41hKQFVGJZBqwjs3nkWEUpAp"],
      ["Vest of Fire", "QmZDeqtzajKwxV9YgfzcZ8Wfap1zARUicUWjTJmJBMdQdw"],
      ["Tunic of Wonder", "QmaS95LAjXoF3EWxPowwbybBvhG7NtqAA6KeWLYpAzKUVZ"],
      ["Tunic of Mystery", "QmYJ1xzvptgSVakpUGQgaXjF4w8nnZyNCoDz9v9TJKEcpz"],
      ["Shirt of Fire", "QmQc1ThSSgbdC6z5nwLDyMyPYqrUC6JBDhfu7WWkyyx9QP"],
      ["Vest of White", "QmYXx2ihhkFWbjHGkyyfSsQf5jnHPojmo1cWBS9RNjLo8R"],
      ["Tunic of Fire", "QmcfVUUiFDNoJnZP8W8eSHPq11WRj99oeK4LLaJQtQ1fb8"],
      ["Robe of Mystery", "QmW9xSXtHfikeScmhpB56kWHdNSDPJaA2F4DRiRdS1gt96"],
      ["Robe of White", "QmRdTAV3jspvFCdWuTL1wYvz34BS1BXhUY9ctsouy11vfR"],
      ["Shirt of Emerald", "QmU3i6M3JgPUSFMzfwCjgAkcFtwtmEvwgdSvTEN9gBQ2Ld"],
      ["Vest of Mystery", "Qme5ZavY4PMvt5bSmrLJErrnDyUckaNH9FrgT5aYqdnnBf"],
      ["Robe of Emerald", "QmZynRUwPjL6Du9LsGyPA3u1fYabmKuefjRnyTgAm99S8D"],
      ["Vest of Wishing", "QmUWNR2XF8dAgPXyakxUmpbr5SWz3kytzu49dAhRBo3gLZ"],
      ["Gown of Magic", "QmQBvcfZ1tsue32nerkpRCsYzDJfNpy466zAhwZ7jWENLw"],
      ["Robe of Wonder", "Qmbidcgmae5LJqcQKoVwF1832maJ7nMdScNr79hkvMtkkd"],
      [
        "Gown of the Universe",
        "Qmehwi2m5aqrZcqUxBjeJbXRcfWjErxywu3HbwXKPZXa2p"
      ],
      ["Tunic of Light", "QmQvhTVqSFRo4zm8uye1f6tYUSUoNvksdgrDzKychyDTKR"],
      ["Snow Gown", "QmZRoMDJFGr7umyFhH6KBporsrqG7mS1d65xMtzcTHipLj"],
      ["Blue Vest", "QmXnYYxyexqF7qcYkPDhzrrzbLkwSTeHEDfwobQLvwMd75"],
      ["Gown of Flowers", "QmaG7srwBaMSUBsExqhUuAUtQbKG12qjcmT1KKoihk7n34"],
      ["White Shirt", "Qmb7iqzgFA3NcJJQutWYFgT946bcy5JwfGHevzc9TFFXt1"],
      ["Blue Shirt", "QmQosecPGEQ8qhP1AvPNrphzrga8f3jkpNvB7HPku49cej"],
      ["Tunic of Emerald", "Qmb6yH7Ss23kL75LfrJTGZXb4oNTXx8A9Uhdr18txKFbqQ"]
    ];
  }

  function getHeadLength() public pure returns (uint256) {
    return getHead().length;
  }

  function getHead() public pure returns (string[2][24] memory) {
    return [
      ["", ""],
      ["Dark Hood", "QmecUFzdxqbhzQGQzpoxqWViFXybMA4amKC9vcwddEzj3y"],
      ["Emerald Hood", "QmQR7CLWNY66kicK51cPjzpf7tcZVEVjZm8PhMtHjBJthi"],
      ["Blue Hood", "QmUEhNvJQ5PmPWvJfABNJ5mwZg9s9uANgeFh8wBfwnftk1"],
      ["White Hood", "QmSNTEq8GsBkzRq19T3Rh9jdULr46KCtKJxVEKTgUQajAo"],
      ["Red Hood", "Qmc4VPaLnV1JPUvpzsYxsKaYofaCbrhgKK3TaDcnf6tW3L"],
      ["Helmet 1", "QmcuWWeEsqWMh6ESKEi4BpbicnoqpQt5WQcLhqC9kggj2M"],
      ["Phrygian Cap", "QmRYZTTanct9LqJw6Mr4EjuTN5iGvySnbgB3GAviy9QAaX"],
      ["Reddish Hat", "QmemYuaZ6ti3f9hZB6sMnCZ9CyHnPRsBCTsSBrTGp7jgFS"],
      ["Hat of Luck", "Qmed5Ebw2HqfeDBn845Sb6UJdSFeedZvwcF2eDeDVTt5Q8"],
      ["Purple Hat", "QmTaet5S2Q8tRa6fa4REPQ3USdn7G6Ptemm4nMb3BpLhZ5"],
      ["Wizard Hat", "QmTAoe4qpfHsER7swyzbGj1zSR6GuRTsMfBaWdWQtsVUAu"],
      ["Helmet 2", "QmQd9zjzVbCEG3HTsnLSjfj4D8g2YbVAwJD9jLnf6x3SqH"],
      ["Helmet of Nebulous", "QmWEvHZyBXuezBcAFKvM55MdVWDnqQCXQXL4xDUzPCVYY6"],
      ["Helmet of Valoria", "QmZX3jJVEhJNTtQM5mTJNkfCSZxqfULsZ88bHg1ekELiGT"],
      ["Hat of White", "Qma6pcKWCwCbLdQfbLqYA8vNr8jr74uTM2dNiK5Ga6GSQL"],
      ["Helmet of Thulium", "QmWWFXsfSuSNRTN4qVdjPH9cf6bccZ3mUbJz8MXXY7Ky8n"],
      ["Helmet of Wonder", "QmNQQ9rZUscy6fLHdhqndmDm43dSe1xo45JBqkiKNN95qz"],
      ["Helmet of Valoria 2", "Qmd1Xza7bLMXNdHmpCP2Dt2Fo7YkyECnQxnsbNgPPEkipK"],
      ["Beep Bop", "QmaPxQGtBVHp7HWDmc7hjnHXCWbubNHFb3dctqetfT5S8S"],
      ["Helmet of Power", "Qmaqi98rt2oFwzjwJxbWmVgdbrjQshCPt5cCpmLUHsM9Cn"],
      ["Beep Bop 2", "QmTNiTTa7BZdAHNni9AgVdcQ86GNkDrDcmreLRRCVHnE4V"],
      ["Beep Bop 3", "QmXnP7hifqudavHmH92o9eDATz8qvpZef7CtGZDdgi5Hoz"],
      ["Helmet of the Sea", "QmXQBQtsdaM5CNC84r3LvjqsQPcBWnmsKvP2U1SdnGdHph"]
    ];
  }

  function getShoesLength() public pure returns (uint256) {
    return getShoes().length;
  }

  function getShoes() public pure returns (string[2][5] memory) {
    return [
      ["", ""],
      ["Shoes", "QmZuWKcMRRRP28eCFq7oZ19VHp5fKsHfKeLPvRh9AhQw3G"],
      ["Golden Runners", "QmSBkmnuG4N8GXMRhAMyYEqoajApFwHymt1aPcDaQXoiX8"],
      ["Blue Shoes", "QmXrspeWB4J3kSYovtuGCz6FqAs5KgxpZs13obSUoSBW3D"],
      ["Blue Boots", "QmZVtB16f6Z8MgEzkv2XCE9ayFe34tTRwouRPKbVZiNjF1"]
    ];
  }

  function getShieldsLength() public pure returns (uint256) {
    return getShields().length;
  }

  function getShadow() public pure returns (string memory) {
    return "QmcRNVeYU1CeMe2yD1HKpg5bvBQCfcW5xZp67HYSstAzSZ";
  }

  function getShields() public pure returns (string[2][11] memory) {
    return [
      ["", ""],
      [
        "Shield of the Forest 1",
        "QmVSwjgTzn7w9jYFvmzadBmFYDaTFi5H9JK8hUW5EJ6Uq3"
      ],
      ["Shield of Iron 1", "QmZWnaVywirur14yBBGfBJdQiqit6rQwB5NUAzkdJzqnPS"],
      ["Mythal Shield 2", "QmebyDHQq24xgLEjoN33aSSQUCFX3vTpf9koRo62GCB6bM"],
      ["Mythal Shield 3", "QmbVKssPYZS1V9bZmkDfpU1EqKyFSKkVLunqQasiipQCkD"],
      ["Shield of Iron 2", "QmYpmqDQZvPPQoNsiH4jDUksozTgWiK13KfWT24YorFsY7"],
      ["Mythal Shield 1", "QmT21FSftCYKcSvjK262vyw79zqQpzxuPCvPNKY23CbNzn"],
      ["Shield of Absolute", "QmPGtk89gzqK93hV8v1noqJthoB3QAccxZGVw9TZUKrKmZ"],
      [
        "Shield of the Forest 2",
        "QmcDwGHTrcdFusDAagX3632cDjAczawoWL6uChv4Y68gF2"
      ],
      ["Shield of Iron 3", "QmPvccz4cMBh3589fht4hCdwRJYyNAHMRggy4YUwKzGKv4"],
      [
        "Shield of the Forest 3",
        "QmRPvKjbSQafzLcxwU4CFBKuemNRxGBS8U3ra8rGFJRRGy"
      ]
    ];
  }
}

// SPDX-License-Identifier: MIT

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