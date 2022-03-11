// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.5;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./IReserve.sol";
import "./whitelist.sol";
import "./safari-erc20.sol";
import "./isafari-erc721.sol";
import "./token-metadata.sol";
import "./safari-token-meta.sol";

uint256 constant GEN0 = 0;
uint256 constant GEN1 = 1;

contract SafariMint is Ownable, Pausable {
    using SafariToken for SafariToken.Metadata;

    struct WhitelistInfo {
        uint8 origAmount;
        uint8 amountRemaining;
        uint240 cost;
    }

    // mint price
    uint256 public constant MINT_PRICE = .07 ether;
    uint256 public constant WHITELIST_MINT_PRICE = .04 ether;

    uint256 public MAX_GEN0_TOKENS = 7777;
    uint256 public MAX_GEN1_TOKENS = 6667;

    uint256 public constant GEN1_MINT_PRICE = 40000 ether;

    mapping(uint256 => SafariToken.Metadata[]) internal special;

    uint256 public MAX_MINTS_PER_TX = 10;

    // For Whitelist winners
    mapping(address => WhitelistInfo) public whiteList;

    // For lions/zebras holders
    SafariOGWhitelist ogWhitelist;

    // reference to the Reserve for staking and choosing random Poachers
    IReserve public reserve;

    // reference to $RUBY for burning on mint
    SafariErc20 public ruby;

    // reference to the rhino metadata generator
    SafariTokenMeta public rhinoMeta;

    // reference to the poacher metadata generator
    SafariTokenMeta public poacherMeta;

    // reference to the main NFT contract
    ISafariErc721 public safari_erc721;

    // is public mint enabled
    bool public publicMint;

    // is gen1 mint enabled
    bool public gen1MintEnabled;

    constructor(address _ruby, address _ogWhitelist) {
        ogWhitelist = SafariOGWhitelist(_ogWhitelist);
	ruby = SafariErc20(_ruby);
    }

    function setReserve(address _reserve) external onlyOwner {
        reserve = IReserve(_reserve);
    }

    function setRhinoMeta(address _rhino) external onlyOwner {
        rhinoMeta = SafariTokenMeta(_rhino);
    }

    function setPoacherMeta(address _poacher) external onlyOwner {
        poacherMeta = SafariTokenMeta(_poacher);
    }

    function setErc721(address _safariErc721) external onlyOwner {
        safari_erc721 = ISafariErc721(_safariErc721);
    }

    function addSpecial(bytes32[] calldata value) external onlyOwner {
        for (uint256 i=0; i<value.length; i++) {
            SafariToken.Metadata memory v = SafariToken.create(value[i]);
	    v.setSpecial(true);
            uint8 kind = v.getCharacterType();
            special[kind].push(v);
	}
    }

    /**
    * allows owner to withdraw funds from minting
    */
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /**
    * public mint tokens
    * @param amount the number of tokens that are being paid for
    * @param boostPercent increase the odds of minting poachers to this percent
    * @param stake stake the tokens if true
    */
    function mintGen0(uint256 amount, uint256 boostPercent, bool stake) external payable whenNotPaused whenPublicMint {
        require(amount * MINT_PRICE == msg.value, "Invalid payment amount");

        _mintGen0(amount, boostPercent, stake);
    }

    /**
    * public mint tokens
    * @param amount the number of tokens that are being paid for
    * @param boostPercent increase the odds of minting poachers to this percent
    * @param stake stake the tokens if true
    */
    function mintGen1(uint256 amount, uint256 boostPercent, bool stake) external payable whenNotPaused whenGen1Mint {
        _mintGen1(amount, boostPercent, stake);
    }

    /**
    * mint tokens using the whitelist
    * @param amount the number of tokens that are being paid for or claimed
    * @param boostPercent increase the odds of minting poachers to this percent
    * @param stake stake the tokens if true
    */
    function mintWhitelist(uint8 amount, uint256 boostPercent, bool stake) external payable whenNotPaused whenWhitelistMint {
        WhitelistInfo memory wlInfo = whiteList[_msgSender()];

	require(wlInfo.origAmount > 0, "you are not on the whitelist");

	uint256 amountAtCustomPrice = min(amount, wlInfo.amountRemaining);
	uint256 amountAtWhitelistPrice = amount - amountAtCustomPrice;
	uint256 totalPrice = amountAtCustomPrice * wlInfo.cost + amountAtWhitelistPrice * WHITELIST_MINT_PRICE;

        require(totalPrice == msg.value, "wrong payment amount");

        wlInfo.amountRemaining -= uint8(amountAtCustomPrice);
        whiteList[_msgSender()] = wlInfo;

        _mintGen0(amount, boostPercent, stake);
    }

    /**
    * mint tokens using the OG Whitelist
    * @param amountPaid the number of tokens that are being paid for
    * @param amountFree the number of free tokens being claimed
    * @param boostPercent increase the odds of minting poachers to this percent
    * @param stake stake the tokens if true
    */
    function mintOGWhitelist(uint256 amountPaid, uint256 amountFree, uint256 boostPercent, bool stake) external payable whenNotPaused whenWhitelistMint {
        require(amountPaid * WHITELIST_MINT_PRICE == msg.value, "wrong payment amount");

        uint16 offset;
        uint8 bought;
        uint8 claimed;
        uint8 lions;
        uint8 zebras;

	uint256 packedInfo = ogWhitelist.getInfoPacked(_msgSender());
        offset = uint16(packedInfo >> 32);
        bought = uint8(packedInfo >> 24);
        claimed = uint8(packedInfo >> 16);
        lions = uint8(packedInfo >> 8);
        zebras = uint8(packedInfo);

        uint256 totalBought = amountPaid + bought;
        uint256 totalClaimed = amountFree + claimed;

        uint256 totalCredits = freeCredits(totalBought, lions, zebras);

        require(totalClaimed <= totalCredits, 'not enough free credits');

        if (totalBought > 255) {
            totalBought = 255;
        }

        uint16 boughtAndClaimed = uint16((totalBought << 8) + totalClaimed);
        ogWhitelist.setBoughtAndClaimed(offset, boughtAndClaimed);

        uint256 amount = amountPaid + amountFree;

        _mintGen0(amount, boostPercent, stake);
    }

    /** 
    * calculate how many RUBIES are needed to increase the
    * odds of minting a Poacher or APR
    * @param boostPercent the number of zebras owned by the user
    * @return the amount of RUBY that is needed
    */
    function boostPercentToCost(uint256 boostPercent, uint256 gen) internal pure returns(uint256) {
        if (boostPercent == 0) {
	    return 0;
	}
	uint256 boostCost;

        if (gen == GEN0) {
            assembly {
	        switch boostPercent
	        case 20 {
	            boostCost := 50000
	        }
	        case 25 {
	            boostCost := 60000
	        }
	        case 30 {
	            boostCost := 100000
	        }
	        case 100 {
	            boostCost := 500000
	        }
	    }
	} else {
            assembly {
	        switch boostPercent
	        case 20 {
	            boostCost := 50000
	        }
	        case 25 {
	            boostCost := 60000
	        }
	        case 30 {
	            boostCost := 100000
	        }
	        case 100 {
	            boostCost := 1000000
	        }
	    }
	}
        require(boostCost > 0, 'Invalid boost amount');
	return boostCost * 1 ether;
    }

    function getStakedPoacherBoost() internal view returns(uint256) {
        uint256 numStakedPoachers = reserve.numDepositedPoachersOf(tx.origin);
	if (numStakedPoachers >= 5) {
	    return 15;
	} else if (numStakedPoachers >= 4) {
	    return 10;
	} else if (numStakedPoachers >= 2) {
	    return 5;
	}
	return 0;
    }

    function _mintGen0(uint256 amount, uint256 boostPercent, bool stake) internal {
        require(tx.origin == _msgSender(), "Only EOA");
        require(amount > 0 && amount <= MAX_MINTS_PER_TX, "Invalid mint amount");
        uint256 m = safari_erc721.totalSupply();
        require(m < MAX_GEN0_TOKENS, "All Gen 0 tokens minted");

        uint256 totalRubyCost = boostPercentToCost(boostPercent, GEN0) * amount;
	require(ruby.balanceOf(_msgSender()) >= totalRubyCost, 'not enough RUBY for boost');

	uint256 poacherChance = boostPercent == 0 ? 10 : boostPercent;

        SafariToken.Metadata[] memory tokenMetadata = new SafariToken.Metadata[](amount);
        uint16[] memory tokenIds = new uint16[](amount);
        uint256 randomVal;

	address recipient = stake ? address(reserve) : _msgSender();

        for (uint i = 0; i < amount; i++) {
            m++;
            randomVal = random(m);
            tokenMetadata[i] = generate0(randomVal, poacherChance, m);
            tokenIds[i] = uint16(m);
        }

        if (totalRubyCost > 0) {
	    ruby.burn(_msgSender(), totalRubyCost);
	}

	safari_erc721.batchMint(recipient, tokenMetadata, tokenIds);

        if (stake) {
	    reserve.stakeMany(_msgSender(), tokenIds);
	}
    }

    function selectRecipient(uint256 seed, address origRecipient) internal view returns (address) {
        if (((seed >> 245) % 10) != 0) return origRecipient;
        address thief = reserve.randomPoacherOwner(seed >> 144);
        if (thief == address(0x0)) return origRecipient;
        return thief;
    }

    function _mintGen1(uint256 amount, uint256 boostPercent, bool stake) internal {
        require(tx.origin == _msgSender(), "Only EOA");
        require(amount > 0 && amount <= MAX_MINTS_PER_TX, "Invalid mint amount");
        uint256 m = safari_erc721.totalSupply();
        require(m < MAX_GEN0_TOKENS + MAX_GEN1_TOKENS, "All Gen 1 tokens minted");

        uint256 totalRubyCost = boostPercentToCost(boostPercent, GEN1) * amount;
	totalRubyCost += amount * GEN1_MINT_PRICE;
	require(ruby.balanceOf(_msgSender()) >= totalRubyCost, 'not enough RUBY owned');

	uint256 aprChance = boostPercent == 0 ? 10 : boostPercent;
	if (aprChance != 100) {
	    aprChance += getStakedPoacherBoost();
	}

        SafariToken.Metadata[] memory tokenMetadata = new SafariToken.Metadata[](amount);
        SafariToken.Metadata[] memory singleTokenMetadata = new SafariToken.Metadata[](1);
        uint16[] memory tokenIds = new uint16[](amount);
        uint16[] memory singleTokenId = new uint16[](1);
        uint256 randomVal;

	address recipient = stake ? address(reserve) : _msgSender();
	address thief;

        for (uint i = 0; i < amount; i++) {
            m++;
            randomVal = random(m);

            singleTokenMetadata[0] = generate1(randomVal, aprChance, m);
	    if (!singleTokenMetadata[0].isAPR() && (thief = selectRecipient(randomVal, recipient)) != recipient) {
	        singleTokenId[0] = uint16(m);
	        safari_erc721.batchMint(thief, singleTokenMetadata, singleTokenId);
	    } else {
	        tokenMetadata[i] = singleTokenMetadata[0];
                tokenIds[i] = uint16(m);
	    }
        }

        if (totalRubyCost > 0) {
	    ruby.burn(_msgSender(), totalRubyCost);
	}

	safari_erc721.batchMint(recipient, tokenMetadata, tokenIds);

        if (stake) {
	    reserve.stakeMany(_msgSender(), tokenIds);
	}
    }

    /**
    * generates traits for a specific token, checking to make sure it's unique
    * @param randomVal a pseudorandom 256 bit number to derive traits from
    * @return t - a struct of traits for the given token ID
    */
    function generate0(uint256 randomVal, uint256 poacherChance, uint256 tokenId) internal returns(SafariToken.Metadata memory) {
        SafariToken.Metadata memory newData;

        uint8 characterType = (randomVal % 100 < poacherChance) ? POACHER : ANIMAL;

        if (characterType == POACHER) {
            SafariToken.Metadata[] storage specials = special[POACHER];
            if (randomVal % (MAX_GEN0_TOKENS/10 - min(tokenId, MAX_GEN0_TOKENS/10) + 1) < specials.length) {
                newData.setSpecial(specials);
            } else {
                newData = poacherMeta.generateProperties(randomVal, tokenId);
                newData.setAlpha(uint8(((randomVal >> 7) % (MAX_ALPHA - MIN_ALPHA + 1)) + MIN_ALPHA));
                newData.setCharacterType(characterType);
            }
        } else {
            SafariToken.Metadata[] storage specials = special[ANIMAL];
            if (randomVal % (MAX_GEN0_TOKENS - min(tokenId, MAX_GEN0_TOKENS) + 1) < specials.length) {
                newData.setSpecial(specials);
            } else {
                newData = rhinoMeta.generateProperties(randomVal, tokenId);
                newData.setCharacterType(characterType);
            }
        }

        return newData;
    }

    /**
    * generates traits for a specific token, checking to make sure it's unique
    * @param randomVal a pseudorandom 256 bit number to derive traits from
    * @return t - a struct of traits for the given token ID
    */
    function generate1(uint256 randomVal, uint256 aprChance, uint256 tokenId) internal returns(SafariToken.Metadata memory) {
        SafariToken.Metadata memory newData;

        newData.setCharacterType((randomVal % 100 < aprChance) ? APR : ANIMAL);

        if (newData.isAPR()) {
	    SafariToken.Metadata[] storage specials = special[APR];
	    if (randomVal % (MAX_GEN0_TOKENS + MAX_GEN1_TOKENS - min(tokenId, MAX_GEN0_TOKENS + MAX_GEN1_TOKENS) + 1) < specials.length) {
	        newData.setSpecial(specials);
	    } else {
                newData.setAlpha(uint8(((randomVal >> 7) % (MAX_ALPHA - MIN_ALPHA + 1)) + MIN_ALPHA));
            }
        } else {
	    SafariToken.Metadata[] storage specials = special[CHEETAH];
	    if (randomVal % (MAX_GEN0_TOKENS + MAX_GEN1_TOKENS - min(tokenId, MAX_GEN0_TOKENS + MAX_GEN1_TOKENS) + 1) < specials.length) {
	        newData.setSpecial(specials);
	    } else {
	        newData.setCharacterSubtype(CHEETAH);
            }
	}

        return newData;
    }

    /**
    * updates the number of tokens for primary mint
    */
    function setGen0Max(uint256 _gen0Tokens) external onlyOwner {
        MAX_GEN0_TOKENS = _gen0Tokens;
    }

    /**
    * generates a pseudorandom number
    * @param seed a value ensure different outcomes for different sources in the same block
    * @return a pseudorandom value
    */
    function random(uint256 seed) internal view returns (uint256) {
        return uint256(
	  keccak256(
	    abi.encodePacked(
              blockhash(block.number - 1),
              seed
            )
	  )
	);
    }

    /** ADMIN */

    function setPublicMint(bool allowPublicMint) external onlyOwner {
        publicMint = allowPublicMint;
    }

    function setGen1Mint(bool allowGen1Mint) external onlyOwner {
        gen1MintEnabled = allowGen1Mint;
    }

    function addToWhitelist(address[] calldata toWhitelist, uint8[] calldata amount, uint240[] calldata cost) external onlyOwner {
        require(toWhitelist.length == amount.length && toWhitelist.length == cost.length, 'all arguments were not the same length');

	WhitelistInfo storage wlInfo;
        for(uint256 i = 0; i < toWhitelist.length; i++){
            address idToWhitelist = toWhitelist[i];
	    wlInfo = whiteList[idToWhitelist];
	    wlInfo.origAmount += amount[i];
	    wlInfo.amountRemaining += amount[i];
	    wlInfo.cost = cost[i];
        }
    }

    /** 
    * calculate how many free tokens can be redeemed by a user
    * based on how many tokens the user has bought
    * @param bought the number of tokens bought
    * @param lions the number of lions owned by the user
    * @param zebras the number of zebras owned by the user
    * @return the number of free tokens that the user can claim
    */
    function freeCredits(uint256 bought, uint256 lions, uint256 zebras) internal pure returns(uint256) {
        uint256 used_lions = min(bought, lions);
        lions -= used_lions;
        bought -= used_lions;
        uint256 used_zebras = min(bought, zebras);
        return used_lions * 2 + used_zebras;
    }

    function min(uint256 a, uint256 b) internal pure returns(uint256) {
        return a <= b ? a : b;
    }

    modifier whenPublicMint() {
        require(publicMint == true, 'public mint is not activated');
	_;
    }

    modifier whenWhitelistMint() {
        require(publicMint == false, 'whitelist mint is over');
	_;
    }

    modifier whenGen1Mint() {
        require(gen1MintEnabled == true, 'gen1 mint is not activated');
	_;
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT LICENSE 

pragma solidity ^0.8.0;

interface IReserve {
  function stakeMany(address account, uint16[] calldata tokenIds) external;
  function randomPoacherOwner(uint256 seed) external view returns (address);
  function numDepositedPoachersOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

contract SafariOGWhitelist {
  bytes internal offsets = hex"0000001800300048005a006600780084009600ae00f001080108010e01500168019201b001c801ec01f8020402100228025e027c0294029a02b202d002e202e803000306030c032a034203540366037e039003b403de04140432044a047a049204b004ce04f205280546056a058e05ac05ca05f4061e0630067206a206ba06cc06de06fc0714072c073e0756075c076e0780079e07c807ec080a08160828085208700882088e08a008b808e208e808fa090c09240942095a0978098a09ae09ea09f00a080a1a0a260a380a3e0a560a680a7a0a9e0abc0ae00aec0b040b220b4c0b640b8e0bac0bc40bdc0bf40c120c360c420c540c600c720c900ca20cb40ccc0cde0cf60d200d2c0d3e0d5c0d620d9e0daa0dce0df20dfe0e1c0e280e400e580e6a0e7c0ea60ec40edc0efa0f060f1e0f3c0f600f900fc00fde1002101a1038104a10621080109810a410c210d410e010ec10fe111611461164118e11b211d611f4121212301254128412ae12cc12f0132c133e135c136e1386139813aa13bc13da1404141c143a14521464147c148814a614b814d014f414fa1506151815361560158a15ba15cc15e416021632164a166e1680169e16b616c216ce16ec170a17161740174017461764178e17ac17ca17fa18181824183c1860189018a818ba18e4190e192c193e19501974198c19b019da19fe1a281a461a641a761a9a1aac1abe";

  bytes internal items = hex"0000000000041b26000000018ca400000003fcdd00000007337300000002353c000001009e5c00000104caaf00000100045b0000000128850000050f35ba00000001736d00000102004900000001893300000005d0f900000001cd3800000001ebe800000001005000000001235500000001379b00000001737000000109cd18000000023f0d00000005538a00000628d7d70000000215910000010535bf000000063ff900000001b071000000030deb000000012700000002082dfe000000015647000000075f330000000460ca0000000373c2000000068f5c00000100bde20000020be3b50000000ce4800000000107bd00000001465700000003848400000003fb20000006190ac7000000014640000000025eeb0000000273aa0000010b77c6000000017c7100000005804e000001038b3a00000001cf5700000006d18200000004da9900000200df260000010968ec00000002815c00000102916100000001b50c000000015e9900000100600500000001817600000003932500000014e82600000202e8590000060eeb6e000000040825000000010f5b00000002a78700000101c89f00000001d353000000012b3200000001a54d00000001e46500000002ef200000010843d00000000454f4000000015e5100000001adc000000003b11500000002c782000000025d02000001026db700000002246f00000004a74800000002093000000001e8750000010927990000010539490000000549e200000002f2ba0000000221e40000000350ca0000000267350000000370c6000000017a6800000007b64c00000004c6e900000001c73800000205d41100000003494f0000010454fe00000001996200000005bd7c00000003e25a0000000422dd00000002391d00000004b0cc00000201b446000000057bd900000001293700000d85a90d0000073aabe300000003f3a7000001081f6b000000012943000000032b72000000053c3600000100c3190000000aa5b800000001c30100000b32cc7e000000042316000000051041000000018c3d000000018cef0000010392c00000010ae4b2000000048d560000010f62b7000000027b68000000038f9f00000001d82900000001fc3100000101851700000001a17f00000001b2db00000007c1e1000000079a49000000029f9300000003e5ed00000002044000000001b90700000001cd0c00000001631e00000103b02000000002deb000000004f640000001019ea000000003b75500000007c5930000000505dc0000020208f000000101a69f00000001b4d600000009dcf600000001e76a000000010ded0000000232b300000001480300000105c9e000000001e76a00000307e9b200000003fdb00000000400f6000000050e4e00000001140600000001193c000000034040000000025ba60000000c849a00000003c93e00000009ebaa0000010411300000000136100000010367200000010277fb0000000a83ae0000000519bc0000000196e400000002c41100000103f00e0000020332f0000000014eb9000000026cea000000017e60000002048e6c00000003a65e00000100bacd00000001f65f000000052673000000023c4100000003c20600000003ea47000000010e040000000216040000000350f500000001c06600000101f0260000000155b4000002307e7900000005904600000002a21e00000002fcc80000000106f400000102171d000003066a8e000000019e9200000001c4eb00000111ddf4000000010562000000020beb0000010913f50000000114550000000138bf000000016696000000016c500000010a707400000001e37a0000000100ce0000000239c20000000662c90000000ca10700000205e2a8000000044e2a000000015f2d00000005996600000003a08200000002b5f300000003f3600000010a34b200000004721500000102bd1700000003bd320000020bbe2700000104e94d000001047fc700000001852d00000104961500000106b73f00000003be2b000000011b4b00000208294500000001a8f800000001c9eb00000200e22900000001439f0000020344d4000000074ca5000000035ce10000000283550000000286c500000109abad00000100168900000204206000000002486100000002542e000000016b8e00000002970c000000019b6700000001136400000003693500000306f7f80000000221d700000005639b0000000269be0000010090c900000003977a000000029f2f00000100af3400000412b62700000002bd8d00000001c44100000002eff80000000105e60000010013c2000000012b07000000062c57000001004cad0000050b5c9700000002702500000105dd9b0000000177f9000001017fa0000000029f18000000019f92000000018f0b00000007e98d00000002fa38000000032ca7000000026e0800000003aaa60000000331490000000146d3000000014c5e00000001711b0000072fee01000000011c4b000000062be8000000013c0a00000001bba8000000011ab90000010521e200000102bdb500000002f34400000212547b00000002691300000001db5d000000031029000000012dcc00000109c5db00000003cabd00000108ce930000010405d80000000289a800000004f41d00000004326e0000010143e50000000167d4000000012f9b000000023b610000000b920e000000029a0f00000228e148000001123b360000000349d40000010c7dfb00000001819300000002918d000000049b9100000001cfba00000003124c000001027e8d00000109915e00000208b6c000000206eb5000000102feff0000010032f80000000539cd0000000169be000000029a1600000002aa9200000002618d00000101888e0000010442d600000003c67500000311ce05000002001e7f000001012cb200000205613500000002743600000003a01d00000001a11100000009e83c000000032404000000016b8200000006aff700000109b8b700000001f33d000000040e4300000313368600000107f92a00000100c2bc00000004ef2b000000041a19000000035a52000000056f78000000032ff6000000018d4d00000003cfa100000002da6f00000100349c0000000138f00000000855760000000159f0000000016a110000000192ac00000001f2eb00000102e1740000000710f1000000021b5500000100543700000002021800000005145000000001e259000000011a9c000000011bd400000207a49d00000001d70b0000000305e9000000021f8a0000020f8e1600000002b27200000002e0d00000000117fb000000039b6400000002cba600000001f75200000002049c0000031b17d1000000044f870000010374c300000203b054000000043311000000024dda000000017a9f0000010f17c2000000012c6e0000001e7a4b00000001b60200000001e37d00000001ec6e00000004067900000001070c000000010c3d000001115c8100000004ae8500000002b27c00000001b2b000000003b5dc00000006e2c700000002e83200000104d8dc0000000430a0000000044cb80000000150270000000173b70000020175cc000000017ea900000002933d00000001222900000103a15000000004035f0000000938e800000001c8e10000010444ff000000053bcd000000025d5200000001dcf700000003ea52000000028e960000000e9035000000039e2500000001159a000001019be800000101c30900000002372a000001123cb40000000c419f000000018ad500000001ae4400000102b53a000000023285000000013969000001013a0f000001026f11000002098ce70000000103fd000000010d47000001003bf1000003123c1c00000001c5d10000000dcb80000000020dd3000000012b43000000010811000000013da3000000015cbf00000100712f0000000384ab00000102877a000000038e51000001029b0000000207a248000000014dcb000001035349000000018a5b0000040898af00000102d11800000001db820000010aef09000001004f7a00000005b9a800000104e19a00000205e97d0000000407d3000001070a4d000000031ab500000002a5e000000002a85100000004cdc500000001e4d7000000085766000000056031000001027bb9000000029aec00000001ab7a000000015062000000027f2500000006c33100000001d6930000090a3f4d000000034cab00000104854c0000000b91970000000635a000000001a26800000104e6ce00000002f0e6000000011aac00000002594b00000002915e0000020693f900000002eb44000002012f37000002034abe000000019beb00000001c69400000117daf100000002f2bf0000000129a500000002e276000000020fa60000011559c700000003eae40000000101cc0000000214cf000001031ded00000004a76500000629eaf4000000015b24000000016be90000020c8e5000000001adca00000001ea5800000205689e00000005982c000001059a70000000023fbf00000001737400000003a8dd00000001b20800000001c68a00000100f0f100000001f61c000004151c1e00000001648e0000000a915c000000036b0e000000037d370000000295d700000001eb13000001062763000000032efa000000013d9a00000104665900000200729700000001c48700000005cd1b000003000da40000020be8e9000001051dcd000000024b4700000001c1ba00000002314400000001451d00000002571400000200e0f900000002ecbe00000001ccac0000000300b4000000012007000000015d1f0000010260fc00000004649d00000001688000000101781d000002107d2f000000017ec3000000028c8100000001483200000003d96700000002004a0000010418d0000000028d740000000292c8000000019bfc00000001b9520000000102820000000118f0000001004c43000000025a37000000039caf00000008aa0d00000005362700000003fb3a0000010231ce00000001732c00000002d98300000001ea6700000002ec84000000018d2c00000002aa11000000032b7900000001d98800000202e16b00000001fe9c00000003182f00000101a3dc00000001aaf800000002e76e000001006da000000002913600000001c622000000021df200000003477d00000002c400000000011ff20000000340e3000000038e940000000193f300000002b08500000004cda40000010cf34a000002021c0b0000020620ae00000001756200000004b1bd00000002e9b9000000011318000000022dc50000000384f200000002e11c000001013a4800000101446f00000003979700000001c1cd00000001f04100000001012c00000003896d000000010aea00000002233400000002a3420000040bf91e0000000160f40000000174bf00000001916e00000216b10f00000001bf8d000000012e09000004114b18000000019ed400000103b9cf00000102fdf300000002ff0800000001010a000000046e1d0000023e834100000108881c0000000a9e5800000001aa2f00000001c46100000002ec060000000127b8000000012d3e000000074dbc0000000175a600000001796000000201a98500000002d3c000000001e94700000001330c0000000a5932000000015aec000000016a4000000007e550000001024ca7000000054f9b00000103530500000003621000000001cfae0000000ee7a9000000014f7d000000016f7900000002c73c00000009e120000002028d7a00000001b3350000000fbb0500000001d81900000001d915000000012909000000012f310000020971b100000001196b00000205593d00000001ee1d00000104efdc00000b0006130000000153dc000000019ecd00000101cff300000007ee0b00000100449b00000004cc9f00000001d06f00000103ea5500000005285600000102e567000000011e460000000132b0000001019b0700000100adc800000002b4910000010e622200000102887100000100890f0000000a45b4000000038e15000000039e1000000009f034000000010935000001090d78000000041feb000000034db100000001525900000002c86c00000002f9c00000000106e20000010051300000000454fa000006076ea50000000196a5000005009d3900000003a3a500000003e3090000000101110000000525750000000730340000000134d60000000187090000040c159c000000014b880000000167720000010282170000000194e000000108a57300000001ca38000000013904000000014cc90000000177d500000001b04000000003c35400000006c3c100000101926000000005c29d00000001da870000000ade7500000001ef6700000001f605000000021cc50000000551720000030c84b600000001c4cb00000002fc8b0000010300dd000000012ac8000000019dc800000001a2cf00000001acf00000020410c300000100bd9400000307c75400000103e0f700000001f9640000010105be0000020440220000000254d500000001b8fb00000008c7ff00000106f40e00000200557b000000025bba0000000161b500000001918000000003ab080000000ac95400000005d6db00000002e0240000000372d5000000017678000000018ef900000001b12400000005cf3c00000001e8bb00000104f5d800000005243a0000000134f600000003800700000006915000000005bc660000000104f30000000143c9000000048a8e000000029e3800000103cae000000001d5af0000000303110000010107c600000004132300000006358f000000028f0f00000204a41700000101af430000020bbc1400000002dc1c00000007ff76000000014580000000107ac300000112e6a30000000143670000020555ee000000057d1300000003bc870000020df43e00000002264100000001b64500000009c708000000014c5800000106a39e00000005aac900000009d171000000022f380000010095d600000002be9b00000005743000000104c10200000001d37e000000022e3d000000065bea000001039bc3000004011dac0000000175f300000002c7e300000004f7c200000002fc3d000001032bdb0000000136c0000000015c2500000001a97700000001add300000002e8cd00000001fac60000000444800000001a65960000000869ef000000018d5000000105390800000002889700000003978400000008d10900000009e7c3000004110840000002082f1200000109342400000103fd9500000001cac600000105dcdc00000200e85a0000000181c0000001019c0300000203a97700000003b43a000009120b17000000017cfd000000010f53000000015d32000000037c5800000003c50100000002d1b40000000acb1800000101cec700000001e69d000000012eff000000036f3d000000018a850000010d8b1f0000040938d00000000340d8000005029d8100000002a7e600000100c47a00000003cb7200000001eb3c0000021220a600000108b4bd00000001134f00000015bf8300000001f46e0000000320ae0000010951aa00000005a4e300000103cb7200000002f7aa000000013b55000000033b89000000015e8200000305988200000105baf000000006c75900000001e5cb0000020226eb0000041939e200000001ceca00000008d99300000001e1f300000003fb2a0000000efcc8000000015600000000025cf0000001018f0100000205a2d300000200a56f00000001b39700000001be4300000003d9160000010168b5000001007b140000000185f1000000026b92000000036f800000000aeb6400000001f5ff000001081a54000001042c2d0000030933fb00000001932200000208d14a0000000108ab000000011e9700000003258c000000014a310000020ea7710000000bbb8d00000005ce0e00000001f07f0000000312ed00000001a35a00000100ced700000004df88000001081920000000093ef80000000143490000000167700000000197aa000000019b6c0000000206c4000000059b8300000002abba0000000123d100000002602d00000104d72700000002e0f500000004f685000000011de1000000012a6200000005bc0f00000210fac2000000013506000000016b63000000022dc600000001a9c90000000108d0000000011e160000040c797c00000001b47b00000007dd690000000209ba0000010622410000000358c700000003798d0000000dd94d000000044bbf00000005e7b30000000106c300000001191700000005513500000004754500000001d4c600000003f93f00000003ff740000000213f80000010311e00000000155170000000157160000010ab42e00000008cf56000000010f0c0000000128bf000000023300000001107db000000001a5a900000002ac2d00000001b52e000002064c9800000106906d00000101a81700000001c3a30000000ec8ca0000010216a8000002193bd90000031a40fc00000001714900000001750c000000010101000003090d1600000006125f00000002551e00000101bb8300000001c76500000001e0fa00000300fa960000000107f600000001417f000000025041000001075dbd00000002b28c000000013ed900000103a5f4000000010b0500000107b13200000103cf6c00000001fe5500000002077b000001010c4e00000001950200000003c8a600000001e7e200000001f43800000021393f000010794a27000000039ea300000001a03300000001b28500000005d68c00000001e47600000001feb90000020c1dbb00000001223b00000001cf5d00000003d27c00000001589900000002d28900000002e96300000001109800000105263b000000052d22000000014da10000010475290000000490dd00000005c19d0000000439c3000001033d32000000019d2e00000001aa9e00000116f17800000001f23800000001fa530000000158e90000000f88ea00000003943100000004a9f500000103c9b00000000107b3000000010e7c00000003aec60000010a1fc100000001307d00000002fbb2000000014eab0000000550870000000266bf00000002676e000000016e530000020fbdc10000000100c900000001102500000105e19f00000317fd65000001031f90000000014386000000017e7900000002aee100000002cc0500000001edbb000000010a18000000012601000001002b15000000014ac000000001c79600000001ce6b00000107d4810000000124ae000000043def0000010545e6000000044cf600000002d0a400000119fc5b0000000116710000021542f30000000a5d7b000001068c2c00000002b0b300000004cdd300000001f3280000000124480000000173950000000189ec000000029f2000000004a6140000000a112600000001273a000000017c4c000000018c6500000001c393000000037bc9000000019e0d00000100d51c0000010522670000000270330000010271500000000395c4000000059bf800000001cd5000000002aa5c00000001dbe300000003dca5000000045ec300000001e14600000005fd3200000001";

  address public owner;
  address public minting_contract;

  constructor() {
    owner = msg.sender;
  }

  function setOwner(address addr) external {
    require(msg.sender == owner, 'you are not the owner');
    owner = addr;
  }

  function setMintingContract(address addr) external {
    require(msg.sender == owner, 'you are not the owner');
    minting_contract = addr;
  }

  function balanceOf(address holder) external view returns(uint256) {
    uint8 bought;
    uint8 claimed;
    uint8 lions;
    uint8 zebras;
    (bought, claimed, lions, zebras) = this.getInfo(holder);
    return uint256(lions) + uint256(zebras);
  }

  function getInfo(address holder) external view returns(uint8 number_bought, uint8 number_free_claimed, uint8 lions_owned, uint8 zebras_owned) {
    uint16 first = uint16(uint160(holder) >> 152 & 0xff) * 2;
    uint16 addr_part = uint16(uint160(holder) >> 136);

    uint256 slot0 = 0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e563;
    uint16 offset;
    uint16 end;

    assembly {
	offset := and(shr(mul(sub(30,mod(       first,32)),8),sload(add(slot0,div(       first,32)))),0xffff)
	end :=    and(shr(mul(sub(30,mod(add(first,2),32)),8),sload(add(slot0,div(add(first,2),32)))),0xffff)
    }

    for (; offset < end; offset += 6) {
      if (uint16(uint8(items[offset]) *256 + uint8(items[offset+1])) == addr_part) {
        return (uint8(items[offset+2]),uint8(items[offset+3]),uint8(items[offset+4]),uint8(items[offset+5]));
      }
    }
    return (uint8(0),uint8(0),uint8(0),uint8(0));
  }

  function getInfoPacked(address holder) external view returns(uint256) {
    uint256 first = uint16(uint160(holder) >> 152 & 0xff) * 2;
    uint256 addr_part = uint16(uint160(holder) >> 136);

    uint256 slot0 = 0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e563;
    uint256 slot1 = 0xb10e2d527612073b26eecdfd717e6a320cf44b4afac2b0732d9fcbe2b7fa0cf6;
    uint256 offset;
    uint256 end;

    assembly {
	offset := and(shr(mul(sub(30,mod(       first,32)),8),sload(add(slot0,div(       first,32)))),0xffff)
	end :=    and(shr(mul(sub(30,mod(add(first,2),32)),8),sload(add(slot0,div(add(first,2),32)))),0xffff)
    }

    uint256 result;

    assembly {
      let i := and(offset, 0xffff)
      let e := and(end, 0xffff)

      let slot_index := add(slot1, div(i, 32))
      let slot_val := sload(slot_index)
      let shift_amount := mul(sub(30, mod(i, 32)), 8)
      let this_addr_part

      for { } lt(i, e) { } {
        this_addr_part := and(shr(shift_amount, slot_val), 0xffff)

        switch eq(this_addr_part, addr_part)
	case true {  // found the address
	  result := shl(32, i)

	  switch shift_amount
	  case 0 {
	    slot_val := sload(add(slot_index, 1))
	    result := add(result, shr(224, slot_val))
	  }
	  case 16 {
	    result := add(result, shl(16, and(slot_val, 0xffff)))
	    slot_val := sload(add(slot_index, 1))
	    result := add(result, shr(240, slot_val))
	  }
	  default {
	    result := add(result, and(shr(sub(shift_amount, 32), slot_val), 0xffffffff))
	  }
	  let p := mload(0x40)
	  mstore(0x40, add(mload(0x40), 0x20))
	  mstore(p, result)
	  return(p, 32)
	}

	case false {  // this_addr_part != addr_part
	  i := add(i, 6)

	  switch gt(shift_amount, 32)
	  case true {
	    shift_amount := sub(shift_amount, 48)
	  }
	  case false {
	    slot_index := add(slot_index, 1)
            slot_val := sload(slot_index)
	    shift_amount := add(208, shift_amount)
	  }
	}
      }
    }

    revert('you are not in the whitelist');
  }

  function setBoughtAndClaimed(uint16 offset, uint16 bought_and_claimed) external {
    require(msg.sender == minting_contract, 'you are not the minting contract');

    items[offset+2] = bytes1(uint8(bought_and_claimed >> 8));
    items[offset+3] = bytes1(uint8(bought_and_claimed));
  }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract SafariErc20 is UUPSUpgradeable, ERC20Upgradeable, OwnableUpgradeable {

  // a mapping from an address to whether or not it can mint / burn
  mapping(address => bool) controllers;
  address public stripesAddress;
  bool public stripesBurning;

  function initialize(string memory name, string memory symbol, address stripes) public initializer {
    __ERC20_init(name, symbol);
    __Ownable_init();
    stripesAddress = stripes;
    stripesBurning = false;
  }

  function upgrade(address stripes) public onlyOwner {
    stripesAddress = stripes;
  }

  function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

  function mint(address to, uint256 amount) external {
    require(controllers[msg.sender], "Only controllers can mint");
    _mint(to, amount);
  }

  function burn(address from, uint256 amount) external {
    require(controllers[msg.sender], "Only controllers can burn");
    _burn(from, amount);
  }

  function burnStripes(uint256 amount) external {
    require(stripesBurning, 'burning stripes is not currently allowed');

    IERC20(stripesAddress).transferFrom(_msgSender(), address(this), amount);
    _mint(_msgSender(), amount);
  }

  function setStripesBurning(bool val) external onlyOwner {
    stripesBurning = val;
  }

  /**
   * enables an address to mint / burn
   * @param controller the address to enable
   */
  function addController(address controller) external onlyOwner {
    controllers[controller] = true;
  }

  /**
   * disables an address from minting / burning
   * @param controller the address to disbale
   */
  function removeController(address controller) external onlyOwner {
    controllers[controller] = false;
  }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./token-metadata.sol";

interface ISafariErc721 {
    function totalSupply() external view returns(uint256);
    function batchMint(address recipient, SafariToken.Metadata[] memory _tokenMetadata, uint16[] memory tokenIds) external;
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

uint8 constant MIN_ALPHA = 5;
uint8 constant MAX_ALPHA = 8;

uint8 constant POACHER = 1;
uint8 constant ANIMAL = 2;
uint8 constant APR = 3;

uint8 constant RHINO = 0;
uint8 constant CHEETAH = 1;

uint8 constant propertiesStart = 128;
uint8 constant propertiesSize = 128;

library SafariToken {
    // struct to store each token's traits
    struct Metadata {
        bytes32 _value;
    }

    function create(bytes32 raw) internal pure returns(Metadata memory) {
        Metadata memory meta = Metadata(raw);
	return meta;
    }

    function getCharacterType(Metadata memory meta) internal pure returns(uint8) {
        return uint8(bytes1(meta._value));
    }

    function setCharacterType(Metadata memory meta, uint8 characterType) internal pure {
        meta._value = (meta._value & 0x00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) | (bytes32(bytes1(characterType)));
    }

    function getAlpha(Metadata memory meta) internal pure returns(uint8) {
        return uint8(bytes1(meta._value << (8*1)));
    }

    function setAlpha(Metadata memory meta, uint8 alpha) internal pure {
        meta._value = (meta._value & 0xff00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) | (bytes32(bytes1(alpha)) >> (8*1));
    }

    function getCharacterSubtype(Metadata memory meta) internal pure returns(uint8) {
        return uint8(bytes1(meta._value << (8*2)));
    }

    function setCharacterSubtype(Metadata memory meta, uint8 subType) internal pure {
        meta._value = (meta._value & 0xffff00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) | (bytes32(bytes1(subType)) >> (8*2));
    }

    function isSpecial(Metadata memory meta) internal pure returns(bool) {
        return bool(uint8(bytes1(meta._value << (8*3) & bytes1(0x01))) == 0x01);
    }

    function setSpecial(Metadata memory meta, bool _isSpecial) internal pure {
        bytes1 specialVal = bytes1(_isSpecial ? 0x01 : 0x00);
        meta._value = (meta._value & 0xfffffffeffffffffffffffffffffffffffffffffffffffffffffffffffffffff) | (bytes32(specialVal) >> (8*3));
    }

    function getReserved(Metadata memory meta) internal pure returns(bytes29) {
        return bytes29(meta._value << (8*3));
    }

    function isPoacher(Metadata memory meta) internal pure returns(bool) {
        return getCharacterType(meta) == POACHER;
    }

    function isAnimal(Metadata memory meta) internal pure returns(bool) {
        return getCharacterType(meta) == ANIMAL;
    }

    function isRhino(Metadata memory meta) internal pure returns(bool) {
        return getCharacterType(meta) == ANIMAL && getCharacterSubtype(meta) == RHINO;
    }

    function isAPR(Metadata memory meta) internal pure returns(bool) {
        return getCharacterType(meta) == APR;
    }

    function setSpecial(Metadata memory meta, Metadata[] storage specials) internal {
	Metadata memory special = specials[specials.length-1];
	meta._value = special._value;
	specials.pop();
    }

    function setProperty(Metadata memory meta, uint256 fieldStart, uint256 fieldSize, uint256 value) internal view {
        setField(meta, fieldStart + propertiesStart, fieldSize, value);
    }

    function getProperty(Metadata memory meta, uint256 fieldStart, uint256 fieldSize) internal pure returns(uint256) {
        return getField(meta, fieldStart + propertiesStart, fieldSize);
    }

    function setField(Metadata memory meta, uint256 fieldStart, uint256 fieldSize, uint256 value) internal view {
        require(value < (1 << fieldSize), 'attempted to set a field to a value that exceeds the field size');
	uint256 shiftAmount = 256 - (fieldStart + fieldSize);
        bytes32 mask = ~bytes32(((1 << fieldSize) - 1) << shiftAmount);
	bytes32 fieldVal = bytes32(value << shiftAmount);
        meta._value = (meta._value & mask) | fieldVal;
    }

    function getField(Metadata memory meta, uint256 fieldStart, uint256 fieldSize) internal pure returns(uint256) {
	uint256 shiftAmount = 256 - (fieldStart + fieldSize);
        bytes32 mask = bytes32(((1 << fieldSize) - 1) << shiftAmount);
	bytes32 fieldVal = meta._value & mask;
	return uint256(fieldVal >> shiftAmount);
    }

    function getRaw(Metadata memory meta) internal pure returns(bytes32) {
        return meta._value;
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.5;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

import "./token-metadata.sol";

contract SafariTokenMeta is UUPSUpgradeable, OwnableUpgradeable {
    using SafariToken for SafariToken.Metadata;
    using Strings for uint256;

    struct TraitInfo {
        uint16 weight;
        uint16 end;
	bytes28 name;
    }

    struct PartInfo {
        uint8 fieldSize;
        uint8 fieldOffset;
        bytes28 name;
    }

    PartInfo[] public partInfo;

    mapping(uint256 => TraitInfo[]) public partTraitInfo;

    struct PartCombo {
        uint8 part1;
        uint8 trait1;
        uint8 part2;
	uint8 traits2Len;
        uint8[28] traits2;
    }

    PartCombo[] public mandatoryCombos;
    PartCombo[] public forbiddenCombos;

    function initialize() public initializer {
      __Ownable_init_unchained();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}


    function buildSpecial(uint256[] calldata traits) external view returns(bytes32) {
        require(traits.length == partInfo.length, string(abi.encodePacked('need ', partInfo.length.toString(), ' elements')));
        SafariToken.Metadata memory newData;
	PartInfo storage _partInfo;
        uint256 i;
        for (i=0; i<partInfo.length; i++) {
            _partInfo = partInfo[i];
            newData.setProperty(_partInfo.fieldOffset, _partInfo.fieldSize, traits[i]);
        }
	return newData._value;
    }

    function setMandatoryCombos(uint256[] calldata parts1, uint256[] calldata traits1, uint256[] calldata parts2, uint256[][] calldata traits2) external onlyOwner {
        require(parts1.length == traits1.length && parts1.length == parts2.length && parts1.length == traits2.length, 'all arguments must be arrays of the same length');

        delete mandatoryCombos;

        uint256 i;
        for (i=0; i<parts1.length; i++) {
            addMandatoryCombo(parts1[i], traits1[i], parts2[i], traits2[i][0]);
        }
    }

    function addMandatoryCombo(uint256 part1, uint256 trait1, uint256 part2, uint256 trait2) internal {
        mandatoryCombos.push();
        PartCombo storage combo = mandatoryCombos[mandatoryCombos.length-1];
        combo.part1 = uint8(part1);
        combo.trait1 = uint8(trait1);
        combo.part2 = uint8(part2);
	combo.traits2Len = uint8(1);
        combo.traits2[0] = uint8(trait2);
    }

    // this should only be used to correct errors in trait names
    function setPartTraitNames(uint256[] calldata parts, uint256[] calldata traits, string[] memory names) external onlyOwner {
        require(parts.length == traits.length && parts.length == names.length, 'all arguments must be arrays of the same length');
        uint256 i;
        for (i=0; i<parts.length; i++) {
            require(partTraitInfo[parts[i]].length > traits[i], 'you tried to set the name of a property that does not exist');
            partTraitInfo[parts[i]][traits[i]].name = stringToBytes28(names[i]);
        }
    }

    // set the odds of getting a trait. dividing the weight of a trait by the sum of all trait weights yields the odds of minting that trait
    function setPartTraitWeights(uint256[] calldata parts, uint256[] calldata traits, uint256[] calldata weights) external onlyOwner {
        require(parts.length == traits.length && parts.length == weights.length, 'all arguments must be arrays of the same length');
        uint256 i;
        for (i=0; i<parts.length; i++) {
            require(partTraitInfo[parts[i]].length < traits[i], 'you tried to set the odds of a property that does not exist');
            partTraitInfo[parts[i]][traits[i]].weight = uint16(weights[i]);
        }
	_updatePartTraitWeightRanges();
    }

    // after trait weights are changed this runs to update the ranges
    function _updatePartTraitWeightRanges() internal {
        uint256 offset;
        TraitInfo storage traitInfo;

        uint256 i;
        uint256 j;
        for (i=0; i<partInfo.length; i++) {
            offset = 0;
            for (j=0; j<partTraitInfo[i].length; j++) {
                traitInfo = partTraitInfo[i][j];
                offset += traitInfo.weight;
		traitInfo.end = uint16(offset);
            }
        }
    }

    function addPartTraits(uint256[] calldata parts, uint256[] calldata weights, string[] calldata names) external onlyOwner {
        require(parts.length == weights.length && parts.length == names.length, 'all arguments must be arrays of the same length');
        uint256 i;
        for (i=0; i<parts.length; i++) {
            _addPartTrait(parts[i], weights[i], names[i]);
        }
	_updatePartTraitWeightRanges();
    }

    function _addPartTrait(uint256 part, uint256 weight, string calldata name) internal {
	TraitInfo memory traitInfo;

	traitInfo.weight = uint16(weight);
	traitInfo.name = stringToBytes28(name);

	partTraitInfo[part].push(traitInfo);
    }

    function addParts(uint256[] calldata fieldSizes, string[] calldata names) external onlyOwner {
        require(fieldSizes.length == names.length, 'all arguments must be arrays of the same length');

        PartInfo memory _partInfo;
        uint256 fieldOffset;
        if (partInfo.length > 0) {
            _partInfo = partInfo[partInfo.length-1];
            fieldOffset = _partInfo.fieldOffset + _partInfo.fieldSize;
        }

        uint256 i;
        for (i=0; i<fieldSizes.length; i++) {
            _partInfo.name = stringToBytes28(names[i]);   
	    _partInfo.fieldOffset = uint8(fieldOffset);
            _partInfo.fieldSize = uint8(fieldSizes[i]);
            partInfo.push(_partInfo);
            fieldOffset += fieldSizes[i];
        }
    }

    function getMeta(SafariToken.Metadata memory tokenMeta, uint256 tokenId, string memory baseURL) external view returns(string memory) {
        bytes memory metaStr = abi.encodePacked(
            '{',
                '"name":"SafariBattle #', tokenId.toString(), '",',
		'"image":"', baseURL, _getSpecificURLPart(tokenMeta), '",',
		'"attributes":[', _getAttributes(tokenMeta), ']'
            '}'
        );
	return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(metaStr)
            )
        );
    }

    function _getSpecificURLPart(SafariToken.Metadata memory tokenMeta) internal view returns(string memory) {
        bytes memory result = abi.encodePacked('?');
	PartInfo storage _partInfo;

        bool isFirst = true;

        uint256 i;
        for (i=0; i<partInfo.length; i++) {
	    if (!isFirst) {
                result = abi.encodePacked(result, '&');
            }
	    isFirst = false;

            _partInfo = partInfo[i];

            result = abi.encodePacked(
                result, bytes28ToString(_partInfo.name),
                '=',
                bytes28ToString(partTraitInfo[i][tokenMeta.getProperty(_partInfo.fieldOffset, _partInfo.fieldSize)].name)
            );
        }

	return string(result);
    }

    function _getAttributes(SafariToken.Metadata memory tokenMeta) internal view returns(string memory) {
        bytes memory result;

	PartInfo storage _partInfo;

        bool isFirst = true;
        string memory traitValue;

        uint256 i;
        for (i=0; i<partInfo.length; i++) {
            _partInfo = partInfo[i];
            traitValue = bytes28ToString(partTraitInfo[i][tokenMeta.getProperty(_partInfo.fieldOffset, _partInfo.fieldSize)].name);

            if (bytes(traitValue).length == 0) {
                continue;
            }

            if (!isFirst) {
                result = abi.encodePacked(result, ',');
            }
	    isFirst = false;

            result = abi.encodePacked(
                result,
		'{',
		    '"trait_type":"', bytes28ToString(_partInfo.name), '",',
                    '"value":"', traitValue, '"',
                '}'
            );
        }
	return string(result);
    }

    function generateProperties(uint256 randomVal, uint256 tokenId) external view returns(SafariToken.Metadata memory) {
        SafariToken.Metadata memory newData;
	PartInfo storage _partInfo;

        uint256 trait;

        uint256 i;
        for (i=0; i<partInfo.length; i++) {
            _partInfo = partInfo[i];
            trait = genPart(i, randomVal);
            newData.setProperty(_partInfo.fieldOffset, _partInfo.fieldSize, trait);
            randomVal >>= 8;
        }

        PartCombo storage combo;

        for (i=0; i<mandatoryCombos.length; i++) {
            combo = mandatoryCombos[i];
            _partInfo = partInfo[combo.part1];
            if (newData.getProperty(_partInfo.fieldOffset, _partInfo.fieldSize) != combo.trait1) {
                continue;
            }
            _partInfo = partInfo[combo.part2];
            if (newData.getProperty(_partInfo.fieldOffset, _partInfo.fieldSize) != combo.traits2[0]) {
                newData.setProperty(_partInfo.fieldOffset, _partInfo.fieldSize, combo.traits2[0]);
            }
        }

        uint256 j;
        bool bad;

        for (i=0; i<forbiddenCombos.length; i++) {
            combo = forbiddenCombos[i];

            _partInfo = partInfo[combo.part1];
            if (newData.getProperty(_partInfo.fieldOffset, _partInfo.fieldSize) != combo.trait1) {
                continue;
            }

            _partInfo = partInfo[combo.part2];

            trait = newData.getProperty(_partInfo.fieldOffset, _partInfo.fieldSize);

	    // generate a new trait until one is found that doesn't conflict
            while (true) {
                bad = false;
                for (j=0; j<combo.traits2.length; j++) {
                    if (trait == combo.traits2[i]) {
                        bad = true;
                        break;
                    }
                }
                if (!bad) {
                    break;
                }
                trait = genPart(combo.part2, randomVal);
                newData.setProperty(_partInfo.fieldOffset, _partInfo.fieldSize, trait);
                randomVal >>= 8;
            }
        }

        return newData;
    }

    function genPart(uint256 part, uint256 randomVal) internal view returns(uint256) {
        TraitInfo storage traitInfo;

	traitInfo = partTraitInfo[part][partTraitInfo[part].length-1];
	uint256 partTotalWeight = traitInfo.end;

        uint256 selected = randomVal % partTotalWeight;

	uint256 start = 0;
        uint256 i;
	for (i=0; i<partTraitInfo[part].length; i++) {
            traitInfo = partTraitInfo[part][i];
	    if (selected >= start && selected < traitInfo.end) {
                return i;
            }
	    start = traitInfo.end;
        }
	require(false, string(abi.encodePacked('did not find a trait: part: ', part.toString(), ', total weight: ', partTotalWeight.toString(), ', selected: ', selected.toString())));
    }

    function min(uint256 a, uint256 b) internal pure returns(uint256) {
        return a <= b ? a : b;
    }

    function bytes28ToString(bytes28 _bytes28) public pure returns (string memory) {
        uint256 i = 0;
        // find the end of the string
        while(i < 28 && _bytes28[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 28 && _bytes28[i] != 0; i++) {
            bytesArray[i] = _bytes28[i];
        }
        return string(bytesArray);
    }

    function stringToBytes28(string memory _string) public pure returns (bytes28) {
        bytes28 _bytes28;
        bytes memory bytesArray = bytes(_string);
	
        require(bytesArray.length <= 28, 'string is longer than 28 bytes');

        uint256 i = 0;
        for (i = 0; i<bytesArray.length; i++) {
            _bytes28 |= bytes28(bytesArray[i]) >> (i*8);
        }
        return _bytes28;
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}