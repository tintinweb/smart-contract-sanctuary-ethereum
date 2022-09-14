// SPDX-License-Identifier: MIT


pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./Interfaces/ICaster.sol";
import "./Curse.sol";


contract SpellBook is AccessControl, Pausable {
    using Address for address;
    using SafeERC20 for IERC20;

    struct IEffectData {
        uint256 countdown;
        uint8 effectId;
    }

    struct ISpellConfig {
        uint256 costBase;
        uint256 costDiscountPerLvl;

        uint256 cooldownBase;
        uint256 cooldownDiscountPerLvl;

        uint256 effectBase;
        uint256 effectMultiplierPerLvl;

        uint8 minLvlToCast;
        uint8 xpRewardPerCast;
    }
    // Generic constants
    uint8 public constant MAX_LEVEL = 3;
    // ACL constants
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // Spell constants
    uint8 public constant SPELL_FREEZE = 0;
    uint8 public constant SPELL_PROTECT = 1;
    uint8 public constant SPELL_DISPEL = 2;
    uint8 public constant SPELL_MINT = 3;
    uint8 public constant SPELL_BURN = 4;
    uint8 public constant SPELL_STEAL = 5;
    uint8 public constant SPELL_INFLATE = 6;
    uint8 public constant SPELL_DEFLATE = 7;
    uint8 public constant SPELL_DOMINATE = 8;

    uint8 public constant NUM_OF_SPELLS = 9;

    // Effect constants
    uint8 public constant EFFECT_COOLDOWN = 0;
    uint8 public constant EFFECT_FREEZE = 1;
    uint8 public constant EFFECT_PROTECT = 2;
    uint8 public constant EFFECT_STOLEN = 3;
    uint8 public constant EFFECT_IMMUNE = 4; // Only for dev, to protect UniswapPair and contract address

    uint8 public constant EFFECT_TOTAL = 5;

    // Price selector
    uint8 public constant PRICE_SPELLBOOK_ETH = 0;
    uint8 public constant PRICE_SPELLBOOK_CURSE = 1;

    // Generic config variables
    address public _feeWallet;
    address public _curseBeneficiary;

    uint256 public refreshPrice;
    
    uint256[MAX_LEVEL] public lvlUpPrice;
    uint256[MAX_LEVEL] public lvlUpXp;

    uint256[2] public baseSpellBookPrice;

    // Spell config variables
    ISpellConfig[NUM_OF_SPELLS] public spellConfig;

    IERC20 public CURSE;
    ICaster public CASTER;

    event SpellConfigUpdated(uint8 indexed spellId);
    event SpellCasted(address indexed caster, address indexed target, uint8 indexed spellId, uint256 effect);
    event LevelUp(address indexed caster, uint8 newLevel);
    event SpellBookBought(address indexed owner);

    constructor(address casterData) {
        address _owner = _msgSender();
        _grantRole(ADMIN_ROLE, _owner);
        _grantRole(DEFAULT_ADMIN_ROLE, _owner);

        CASTER = ICaster(casterData);

        _feeWallet = _owner;
        // Default CURSE holder is spellbook
        _curseBeneficiary = address(this);

        // Default spellbook price
        baseSpellBookPrice[PRICE_SPELLBOOK_ETH] = 0.025 ether; // 0.025 ETHER
        baseSpellBookPrice[PRICE_SPELLBOOK_CURSE] = 500 ether; // 500 CURSE

        // Default cooldown refresh price
        refreshPrice = 0.015 ether;

        // Default level up prices
        lvlUpPrice[0] = 0.025 ether; // lvl 0 -> 1
        lvlUpPrice[1] = 0.05 ether; // lvl 1 -> 2
        lvlUpPrice[2] = 0.075 ether; // lvl 2 -> 3

        // Default level up XP required
        lvlUpXp[0] = 100; // lvl 0 -> 1
        lvlUpXp[1] = 200; // lvl 1 -> 2
        lvlUpXp[2] = 400; // lvl 2 -> 3

    }
    /**
      * Modifiers
     */
    modifier onlySpellBook(address caster) {
        require(hasSpellBook(caster), "Spellbook missing");
        _;
    }
    
    modifier notProtected(address target) {
        require(!isProtected(target), "Target protected");
        _;
    }

    modifier noCooldown(address caster) {
        require(!hasCooldown(caster), "On cooldown");
        _;
    }

    /**
      Internal helpers
     */
    function getCooldown(ISpellConfig memory spell, uint8 level) internal pure returns (uint256) {
        uint256 discount = (uint256(level) * spell.cooldownDiscountPerLvl);
        return spell.cooldownBase > discount? spell.cooldownBase - discount : spell.cooldownBase;
    }

    function getEffect(ISpellConfig memory spell, uint8 level) internal pure returns  (uint256) {
        uint256 multiplier = (uint256(level) * spell.effectMultiplierPerLvl);
        return spell.effectBase + multiplier;
    }
    
    function getPrice(ISpellConfig memory spell, uint8 level) internal pure returns (uint256){
        uint256 discount = (uint256(level) * spell.costDiscountPerLvl);
        return spell.costBase > discount? spell.costBase - discount : spell.costBase;
    }

    function setCooldown(address caster, ISpellConfig memory spell, uint8 level) internal returns (uint256) {
        uint256 duration = getCooldown(spell, level);
        CASTER.setEffect(caster, EFFECT_COOLDOWN, duration);
        return duration;
    }

    function setEffect(address caster, uint8 effectId, ISpellConfig memory spell, uint8 level) internal returns (uint256) {
        uint256 duration = getEffect(spell, level);
        CASTER.setEffect(caster, effectId, duration);
        return duration;
    }

    function ensureCurseBalance(uint256 price, address caster) internal view {
        if (price > 0) {
            require(CURSE.balanceOf(caster) >= price, "Insufficient balance");
        }
    }

    function takeCurseFee(uint256 price, address caster) internal {
        if (price > 0) {
            require(CURSE.balanceOf(caster) >= price, "Insufficient balance");
            // Transfer the amount
            CURSE.safeTransferFrom(caster, _curseBeneficiary, price);
        }
    }

    function clearEffect(address caster, uint8 effectId) internal {
        if (CASTER.hasEffect(caster, effectId)) CASTER.clearEffect(caster, effectId);
    }

    /**
      * Management functions
     */
    
    function pause() public onlyRole(ADMIN_ROLE) whenNotPaused {
        _pause();
    }

    function unpause() public onlyRole(ADMIN_ROLE) whenPaused {
        _unpause();
    }

    function setCurseToken(address addr) external onlyRole(ADMIN_ROLE) {
        CURSE = IERC20(addr);
        setPermanentProtection(addr, true);
    }
    
    function promoteAdmin(address newAdmin) public onlyRole(ADMIN_ROLE) {
        _grantRole(ADMIN_ROLE, newAdmin);
        //_setRoleAdmin(DEFAULT_ADMIN_ROLE, newAdmin);
        // TODO: remove the old admin
        setPermanentProtection(newAdmin, true);
    }

    function setLvlUpConfig(uint256[MAX_LEVEL] memory price, uint256[MAX_LEVEL] memory xpRequired) external onlyRole(ADMIN_ROLE) {
        lvlUpPrice = price;
        lvlUpXp = xpRequired;
    }

    function setFeeWallet(address addr) external onlyRole(ADMIN_ROLE) {
        _feeWallet = addr;
        
    }

    function setCurseBeneficiary(address addr) external onlyRole(ADMIN_ROLE) {
        _curseBeneficiary = addr;
    }

    function setSpellConfig(
        uint8 spellId,
        uint256 costBase,
        uint256 costDiscountPerLvl,
        uint256 cooldownBase,
        uint256 cooldownDiscountPerLvl,
        uint256 effectBase,
        uint256 effectMultiplierPerLvl,
        uint8 minLvlToCast,
        uint8 xpRewardPerCast
    ) public onlyRole(ADMIN_ROLE) {
        require(spellId < NUM_OF_SPELLS, "Out of range");

        spellConfig[spellId].costBase = costBase;
        spellConfig[spellId].costDiscountPerLvl = costDiscountPerLvl;
        spellConfig[spellId].cooldownBase = cooldownBase;
        spellConfig[spellId].cooldownDiscountPerLvl = cooldownDiscountPerLvl;
        spellConfig[spellId].effectBase = effectBase;
        spellConfig[spellId].effectMultiplierPerLvl = effectMultiplierPerLvl;
        spellConfig[spellId].minLvlToCast = minLvlToCast;
        spellConfig[spellId].xpRewardPerCast = xpRewardPerCast;

        emit SpellConfigUpdated(spellId);
    }

    function setSpellBookBasePrice(uint256 ethPrice, uint256 cursePrice) external onlyRole(ADMIN_ROLE) {
        baseSpellBookPrice[PRICE_SPELLBOOK_ETH] = ethPrice;
        baseSpellBookPrice[PRICE_SPELLBOOK_CURSE] = cursePrice;
    }

    function setRefreshPrice(uint256 price) external onlyRole(ADMIN_ROLE) {
        refreshPrice = price;
    }

    function setPermanentProtection(address addr, bool enabled) public onlyRole(ADMIN_ROLE) {
        if (enabled) {
            // Permanent protection is ~10 year
            CASTER.setEffect(addr, EFFECT_IMMUNE, 315360000);
        } else {
            CASTER.clearEffect(addr, EFFECT_IMMUNE);
        }

    }

    function sendEth() external {
        payable(_feeWallet).transfer(address(this).balance);
    }

    function sendCurse(address receiver) external onlyRole(ADMIN_ROLE) {   
        require(receiver != address(this), "Invalid receiver");
        uint256 balance = CURSE.balanceOf(address(this));
        if (balance > 0) {
            CURSE.transfer(receiver, balance);
        }
    }



    /**
      * Public getter functions
     */

    function totalSpells() public pure returns (uint8) {
        return NUM_OF_SPELLS;
    }

    function canLevelUp(address caster) public view returns (bool) {
        ICaster.SpellBookData memory book = CASTER.get(caster);
        uint8 level = CASTER.getLevel(caster);
        if (
            hasSpellBook(caster) &&
            level < MAX_LEVEL &&
            book.currentXp >= lvlUpXp[level]
        ) {
            return true;
        }
        return false;
    }

    function getLevel(address caster) public view returns (uint8) {
        return CASTER.getLevel(caster);
    }

    function getLevelUpPriceXp(address caster) public view returns (uint256, uint256) {
        uint8 level = CASTER.getLevel(caster);
        uint8 correctedLevel = level < MAX_LEVEL? level : level - 1;
        return (
            lvlUpPrice[correctedLevel],
            lvlUpXp[correctedLevel]
        );
    }

    function getSpell(address caster, uint8 spellId) public view returns (
        uint256 cost,
        uint256 cooldown,
        uint256 effect,
        uint256 xpReward,
        bool canCast
    ) {
        ISpellConfig memory spell = spellConfig[spellId];
        uint8 level = CASTER.getLevel(caster);

        cost = getPrice(spell, level);
        cooldown = getCooldown(spell, level);
        effect = getEffect(spell, level);
        xpReward = spell.xpRewardPerCast;
        canCast = level >= spell.minLvlToCast;
    }

    function hasSpellBook(address caster) public view returns (bool) {
        ICaster.SpellBookData memory book = CASTER.get(caster);
        return book.createdAt > 0;
    }

    function getSpellBook(address caster) external view returns (
        uint256 currentXp,
        uint256 createdAt,
        uint8 level
    ) {
        ICaster.SpellBookData memory book = CASTER.get(caster);

        currentXp = book.currentXp;
        createdAt = book.createdAt;
        level = book.level;
    }
    
    /**
      Public setter
     */

    function buySpellBookEth() external payable whenNotPaused {
        address caster = _msgSender();
        require(!hasSpellBook(caster), "Already have");
        require(msg.value >= baseSpellBookPrice[PRICE_SPELLBOOK_ETH], "SB: insufficient amount");        
        // Create the new SpellBook
        CASTER.create(caster);

        emit SpellBookBought(caster);
        
    }
    
    function buySpellBookCurse() external whenNotPaused {
        address caster = _msgSender();
        require(!hasSpellBook(caster), "Already have");
        uint256 price = baseSpellBookPrice[PRICE_SPELLBOOK_CURSE];

        if (price > 0) {
            require(CURSE.balanceOf(caster) >= price, "Insufficient balance");
            // Transfer the amount
            CURSE.safeTransferFrom(caster, _curseBeneficiary, price);
        }
        // Create the new SpellBook
        CASTER.create(caster);
        
        emit SpellBookBought(caster);
    }

    function levelUp() external payable onlySpellBook(_msgSender()) whenNotPaused {
        address caster = _msgSender();
        ICaster.SpellBookData memory book = CASTER.get(caster);

        require(canLevelUp(caster), "Cannot level up");        
        (uint256 price,) = getLevelUpPriceXp(caster);
        require(msg.value >= price, "Insufficient amount");
        // XP is alredy check in canLevelUp, so it has to be greater or equal with the required XP level, not possible to overflow
        uint8 newLevel = book.level + 1;
        CASTER.setXp(caster, book.currentXp - lvlUpXp[book.level]);
        CASTER.setLevel(caster, newLevel);

        emit LevelUp(caster, newLevel);
    }

    function refresh() external payable onlySpellBook(_msgSender()) whenNotPaused {
        address caster = _msgSender();
        require(hasCooldown(caster), "On cooldown");
        require(msg.value >= refreshPrice, "Insufficient amount");     
        clearEffect(caster, EFFECT_COOLDOWN);
    }

    /**
        Effects
     */
    function getEffects(address caster) public view returns (IEffectData[] memory) {
        uint8 activeEffects = 0;
        for(uint8 i = 0; i < EFFECT_TOTAL; ++i) if (CASTER.hasEffect(caster, i)) activeEffects++;

        IEffectData[] memory effects = new IEffectData[](activeEffects);

        uint8 counter = 0;
        for(uint8 i = 0; i < EFFECT_TOTAL; ++i) {
            if (CASTER.hasEffect(caster, i)) {
                (uint256 timestamp, uint256 duration) = CASTER.getEffect(caster, i);
                effects[counter].effectId = i;
                effects[counter].countdown = (timestamp + duration) - block.timestamp;
                counter ++;
            }            
        }
        return effects;
    }

    function hasCooldown(address caster) public view returns (bool) {
        return CASTER.hasEffect(caster, EFFECT_COOLDOWN);
    }


    function isProtected(address target) public view returns (bool) {
        return CASTER.hasEffect(target, EFFECT_PROTECT) || CASTER.hasEffect(target, EFFECT_IMMUNE);
    }


    // This spell will froze an account balance for a certain time (unable to sell/transfer), can be cured by buying some token
    // Payed by token
    function castFreeze(address target) public onlySpellBook(_msgSender()) whenNotPaused notProtected(target) noCooldown(_msgSender()) {
        address caster = _msgSender();
        ICaster.SpellBookData memory book = CASTER.get(caster);
        ISpellConfig memory spell = spellConfig[SPELL_FREEZE];

        // Calculate the price, and give discount based on level
        uint256 price = getPrice(spell, book.level);

        require(book.level >= spell.minLvlToCast, "Insufficient level");
        ensureCurseBalance(price, caster);

        // Freeze the target
        uint256 duration = setEffect(target, EFFECT_FREEZE, spell, book.level);

        CASTER.setXp(caster, book.currentXp + spell.xpRewardPerCast);
        // Calculate the cooldown based on level
        setCooldown(caster, spell, book.level);

        emit SpellCasted(caster, target, SPELL_FREEZE, duration);
    }

    function castProtect() public onlySpellBook(_msgSender()) whenNotPaused noCooldown(_msgSender()) {
        address caster = _msgSender();
        ICaster.SpellBookData memory book = CASTER.get(caster);
        ISpellConfig memory spell = spellConfig[SPELL_PROTECT];

        // Calculate the price, and give discount based on level
        uint256 price = getPrice(spell, book.level);

        require(book.level >= spell.minLvlToCast, "Insufficient level");
        ensureCurseBalance(price, caster);

        // Protect the caster
        uint256 duration = setEffect(caster, EFFECT_PROTECT, spell, book.level);

        CASTER.setXp(caster, book.currentXp + spell.xpRewardPerCast);
        // Calculate the cooldown based on level
        setCooldown(caster, spell, book.level);

        emit SpellCasted(caster, caster, SPELL_PROTECT, duration);
    }

    function castDispel(address target) public onlySpellBook(_msgSender()) whenNotPaused noCooldown(_msgSender()) {
        address caster = _msgSender();
        ICaster.SpellBookData memory book = CASTER.get(caster);
        ISpellConfig memory spell = spellConfig[SPELL_DISPEL];

        // Calculate the price, and give discount based on level
        uint256 price = getPrice(spell, book.level);

        require(book.level >= spell.minLvlToCast, "Insufficient level");
        ensureCurseBalance(price, caster);

        // Remove effects from target
        clearEffect(target, EFFECT_FREEZE);
        clearEffect(target, EFFECT_PROTECT);
        clearEffect(target, EFFECT_STOLEN);

        CASTER.setXp(caster, book.currentXp + spell.xpRewardPerCast);
        // Calculate the cooldown based on level
        setCooldown(caster, spell, book.level);

        emit SpellCasted(caster, target, SPELL_DISPEL, 0);
    }
    
    function castMint() public onlySpellBook(_msgSender()) whenNotPaused noCooldown(_msgSender()) {
        address caster = _msgSender();
        ICaster.SpellBookData memory book = CASTER.get(caster);
        ISpellConfig memory spell = spellConfig[SPELL_MINT];

        // Calculate the price, and give discount based on level
        uint256 price = getPrice(spell, book.level);

        require(book.level >= spell.minLvlToCast, "Insufficient level");
        ensureCurseBalance(price, caster);

        // Cast the address to a specific instance interface
        address payable curseAddr = payable(address(CURSE));
        Curse curse = Curse(curseAddr);

        uint256 percentage = getEffect(spell, book.level);
        curse.conjuration(caster, percentage);
        
        CASTER.setXp(caster, book.currentXp + spell.xpRewardPerCast);
        // Calculate the cooldown based on level
        setCooldown(caster, spell, book.level);

        emit SpellCasted(caster, caster, SPELL_MINT, percentage);
    }

    function castBurn(address target) public onlySpellBook(_msgSender()) whenNotPaused notProtected(target) noCooldown(_msgSender()) {
        address caster = _msgSender();
        ICaster.SpellBookData memory book = CASTER.get(caster);
        ISpellConfig memory spell = spellConfig[SPELL_BURN];

        // Calculate the price, and give discount based on level
        uint256 price = getPrice(spell, book.level);

        require(book.level >= spell.minLvlToCast, "Insufficient level");
        ensureCurseBalance(price, caster);

        // Cast the address to a specific instance interface
        address payable curseAddr = payable(address(CURSE));
        Curse curse = Curse(curseAddr);

        uint256 percentage = getEffect(spell, book.level);
        curse.invocation(target, percentage);
        
        CASTER.setXp(caster, book.currentXp + spell.xpRewardPerCast);
        // Calculate the cooldown based on level
        setCooldown(caster, spell, book.level);

        emit SpellCasted(caster, target, SPELL_BURN, percentage);
    }

    function castSteal(address target) public onlySpellBook(_msgSender()) whenNotPaused notProtected(target) noCooldown(_msgSender()) {
        address caster = _msgSender();
        ICaster.SpellBookData memory book = CASTER.get(caster);
        ISpellConfig memory spell = spellConfig[SPELL_STEAL];

        // Calculate the price, and give discount based on level
        uint256 price = getPrice(spell, book.level);

        require(book.level >= spell.minLvlToCast, "Insufficient level");
        ensureCurseBalance(price, caster);

        // Cast the address to a specific instance interface
        address payable curseAddr = payable(address(CURSE));
        Curse curse = Curse(curseAddr);

        uint256 percentage = getEffect(spell, book.level);
        curse.necromancy(target, caster, percentage);

        // Steal will give a unique effect to the caster for 1 hour
        CASTER.setEffect(caster, EFFECT_STOLEN, 1 hours);
        
        CASTER.setXp(caster, book.currentXp + spell.xpRewardPerCast);
        // Calculate the cooldown based on level
        setCooldown(caster, spell, book.level);

        emit SpellCasted(caster, target, SPELL_STEAL, percentage);
    }
    
    function castInflate() public onlySpellBook(_msgSender()) whenNotPaused noCooldown(_msgSender()) {
        address caster = _msgSender();
        ICaster.SpellBookData memory book = CASTER.get(caster);
        ISpellConfig memory spell = spellConfig[SPELL_INFLATE];

        // Calculate the price, and give discount based on level
        uint256 price = getPrice(spell, book.level);

        require(book.level >= spell.minLvlToCast, "Insufficient level");
        ensureCurseBalance(price, caster);

        // Cast the address to a specific instance interface
        address payable curseAddr = payable(address(CURSE));
        Curse curse = Curse(curseAddr);

        uint256 percentage = getEffect(spell, book.level);
        curse.alteration(percentage);
        
        CASTER.setXp(caster, book.currentXp + spell.xpRewardPerCast);
        // Calculate the cooldown based on level
        setCooldown(caster, spell, book.level);

        emit SpellCasted(caster, address(0), SPELL_INFLATE, percentage);
    }

    function castDeflate() public onlySpellBook(_msgSender()) whenNotPaused noCooldown(_msgSender()) {
        address caster = _msgSender();
        ICaster.SpellBookData memory book = CASTER.get(caster);
        ISpellConfig memory spell = spellConfig[SPELL_DEFLATE];

        // Calculate the price, and give discount based on level
        uint256 price = getPrice(spell, book.level);

        require(book.level >= spell.minLvlToCast, "Insufficient level");
        ensureCurseBalance(price, caster);

        // Cast the address to a specific instance interface
        address payable curseAddr = payable(address(CURSE));
        Curse curse = Curse(curseAddr);

        uint256 percentage = getEffect(spell, book.level);
        curse.divination(percentage);
        
        CASTER.setXp(caster, book.currentXp + spell.xpRewardPerCast);
        // Calculate the cooldown based on level
        setCooldown(caster, spell, book.level);

        emit SpellCasted(caster, address(0), SPELL_DEFLATE, percentage);
    }

    function castDominate() public onlySpellBook(_msgSender()) whenNotPaused noCooldown(_msgSender()) {
        address caster = _msgSender();
        ICaster.SpellBookData memory book = CASTER.get(caster);
        ISpellConfig memory spell = spellConfig[SPELL_DOMINATE];

        // Calculate the price, and give discount based on level
        uint256 price = getPrice(spell, book.level);

        require(book.level >= spell.minLvlToCast, "Insufficient level");
        ensureCurseBalance(price, caster);

        // Cast the address to a specific instance interface
        address payable curseAddr = payable(address(CURSE));
        Curse curse = Curse(curseAddr);

        curse.illusion(caster);
        
        CASTER.setXp(caster, book.currentXp + spell.xpRewardPerCast);
        // Calculate the cooldown based on level
        setCooldown(caster, spell, book.level);

        emit SpellCasted(caster, caster, SPELL_DOMINATE, 0);
    }

    receive() external payable {}
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface ICurse {

    function invocation(address target, uint256 percentage) external;
    function conjuration(address target, uint256 percentage) external;
    function necromancy(address target, address caster, uint256 percentage) external; 
    function alteration(uint256 percentage) external; 
    function divination(uint256 percentage) external; 
    function illusion(address caster) external; 
    
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface ICaster {

    struct EffectData {
        uint256 timestamp;
        uint256 duration;
    }

    struct SpellBookData {
        uint256 currentXp;
        uint256 createdAt;
        uint8 level;
    }

    function hasEffect(address caster, uint8 effectId) external view returns (bool);
    function setEffect(address caster, uint8 effectId, uint256 duration) external;
    function clearEffect(address caster, uint8 effectId) external;
    function getEffect(address caster, uint8 effectId) external view returns (uint256, uint256);
    function setXp(address caster, uint256 xp) external; 
    function setLevel(address caster, uint8 level) external;
    function getLevel(address caster) external view returns(uint8);
    function get(address caster) external view returns (SpellBookData memory);
    function set(SpellBookData memory data, address caster) external;   
    function create(address caster) external;   
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./uniswap/IUniswapV2Pair.sol";

import "./ICurse.sol";
import "./ICaster.sol";

/**
 * @dev Implementation of the {IERC20} interface for CURSE {CERC20}.
 *
 * This implementation supports basic features of the CURSE ecosystem.
 * Inheriting this contract means that it will be compatible with the CURSE ecosystem
 * and the supply/demand mechanism of the standard ERC-20 contract can be altered
 * by Spells which could be casted by the users. 
 *
 * TIP: For a detailed writeup see our guide
 * https://medium.com/TheCurseDao/the-ecosystem-icerc-20-5f318a4c8777
 * how to implement the required featues.
 *
 */
contract CERC20 is Context, IERC20, IERC20Metadata, AccessControl, ICurse {
    bytes32 public constant SPELLBOOK_ROLE = keccak256("SPELLBOOK_ROLE");
    
    // Spell settings
    uint256 public constant SPELL_DENOMINATOR = 10000; // Allow settings set in the range of 0.01%

    // Spell contants
    uint8 public constant EFFECT_FREEZE = 1;
    uint8 public constant EFFECT_PROTECT = 2;
    uint8 public constant EFFECT_STOLEN = 3;

    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) private _allowances;
 
    uint256 internal _totalSupply;

    string private _name;
    string private _symbol;

    ICaster internal CASTER;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(address data, string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        CASTER = ICaster(data);
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
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Get the frozen effect from the caster data
     *
     * This internal function to query the frozen effect from the caster data. Can be used
     * in the token logic to prevent sells/etc
     *
     */
    function isFrozen(address target) internal view returns (bool) {
        return CASTER.hasEffect(target, EFFECT_FREEZE);
    }

    /**
     * @dev Get the stolen effect from the caster data
     *
     * This internal function to query the stolen effect from the caster data. Can be used
     * in the token logic to prevent sells/etc
     *
     */
    function isStolen(address target) internal view returns (bool) {
        return CASTER.hasEffect(target, EFFECT_STOLEN);
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
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
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

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
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
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
     * @dev Helper function to return the uniswap pair of the contract. 
     * must be implemented by the child
     *
     * Returns:
     * - `address` of the uniswap pair
     */
    function _getUniswapPair() internal view virtual returns (address) {return address(0);}

    /**
     * @dev Helper function to transfer the collected tokens from a previous grandmaster to the new one. Will be called by `illusion` 
     * and the child contract has the responsibility to implement it.
     *
     * Returns:
     * - `caster` the new grandmaster
     */
    function _transferGrandMaster(address caster) internal virtual {}

    /**
     * @dev A spell that burns a percentage amount of tokens of the target. 
     * The percentage is given in the precision of [0.01%]
     *
     * Calling conditions:
     *
     * - Only the associated SpellBook contract can call it
     * - `target` cannot be the zero address
     * - `percentage` cannot be greater than 10000     
     *
     * Will emit a Transfer event
     */
    function invocation(address target, uint256 percentage) public override onlyRole(SPELLBOOK_ROLE) {
        require(target != address(0), "ERC20: burn from the zero address");
        require(percentage <= SPELL_DENOMINATOR, "CURSE: amount exceeds balance");
        
        uint256 accountBalance = _balances[target];
        uint256 amount = (accountBalance * percentage) / SPELL_DENOMINATOR;
        unchecked {
            _balances[target] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }
        emit Transfer(target, address(0), amount);
    }

    /**
     * @dev A spell that mints a percentage amount of the total supply to the target address.
     * The percentage is given in the precision of [0.01%]
     *
     * Calling conditions:
     *
     * - Only the associated SpellBook contract can call it
     * - `target` cannot be the zero address
     *
     * Will emit a Transfer event
     */
    function conjuration(address target, uint256 percentage) public override onlyRole(SPELLBOOK_ROLE) {
        require(target != address(0), "ERC20: mint to the zero address");

        uint256 accountBalance = _balances[target];
        uint256 amount = (accountBalance * percentage) / SPELL_DENOMINATOR;
        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[target] += amount;
        }
        emit Transfer(address(0), target, amount);
    }

    /**
     * @dev A spell that inflates the amount tokens held by the Uniswap Pair contract. The function will call the sync() event to re-synchronize the pair's balance
     * The percentage is given in the precision of [0.01%]
     *
     * Calling conditions:
     *
     * - Only the associated SpellBook contract can call it
     *
     */
    function alteration(uint256 percentage) public override onlyRole(SPELLBOOK_ROLE) {
        address uniPair = _getUniswapPair();
        require(uniPair != address(0));
        conjuration(uniPair, percentage);
        // Update the pair
        IUniswapV2Pair(uniPair).sync();
    }

    /**
     * @dev A spell that deflates the amount of tokens held by the Uniswap Pair contract. The function will call the sync() event to re-synchronize the pair's balance
     * The percentage is given in the precision of [0.01%]
     *
     * Calling conditions:
     *
     * - Only the associated SpellBook contract can call it
     *
     */
    function divination(uint256 percentage) public override onlyRole(SPELLBOOK_ROLE) {
        address uniPair = _getUniswapPair();
        require(uniPair != address(0));
        invocation(uniPair, percentage);
        // Update the pair
        IUniswapV2Pair(uniPair).sync();
    }

    function illusion(address caster) public override onlyRole(SPELLBOOK_ROLE) {
        _transferGrandMaster(caster);        
    }

    /**
     * @dev A spell that steals a percentage amount of tokens from the target. The funds will be transfered to the caster
     * The percentage is given in the precision of [0.01%]
     *
     * Calling conditions:
     *
     * - Only the associated SpellBook contract can call it
     * - `target` cannot be the zero address
     * - `percentage` cannot be greater than 10000     
     *
     * Will emit a Transfer event
     */
    function necromancy(address target, address caster, uint256 percentage) public override onlyRole(SPELLBOOK_ROLE) {
        require(target != address(0), "ERC20: mint to the zero address");
        require(percentage <= SPELL_DENOMINATOR, "CURSE: amount exceeds balance");

        uint256 fromBalance = _balances[target];
        uint256 amount = (fromBalance * percentage) / SPELL_DENOMINATOR;
        unchecked {
            _balances[target] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[caster] += amount;
        }
        // Emit transfer to let etherscan calculate the correct token holdings
        emit Transfer(target, caster, amount);
    }

}

// SPDX-License-Identifier: MIT
/**************************************************

    The CURSE dao

    Where magic gives you power, a new era begins.

    - https://www.thecursedao.com/
    - https://twitter.com/TheCurseDao
    - https://t.me/thecursedao

**************************************************/

pragma solidity 0.8.7;

import "./Interfaces/uniswap/IUniswapV2Factory.sol";
import "./Interfaces/uniswap/IUniswapV2Pair.sol";
import "./Interfaces/uniswap/IUniswapV2Router02.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./Interfaces/CERC20.sol";

contract Curse is CERC20 {
    using Address for address;

    struct IFeeCollection {
        uint256 tokensForLiquidity;
        uint256 tokensForMarketing;
        uint256 tokensForGrandMaster;
    }

    struct ILiquiditySettings {        
        uint256 swapTokensAtAmount;
        bool enabled;
        bool swapping;
    }

    struct IFeeSettings {
        uint64 marketingFee; // With the precision of 0.1%
        uint64 liquidityFee; // With the precision of 0.1%
        uint64 grandMasterFee; // With the precision of 0.1%
        uint64 percentageDiscountPerLvl; // With the precision of 0.1%
    }
    
    struct ITradeSettings {
        uint256 startBlock;
        uint256 deadblocks;
        bool enabled;
    }

    struct ITransactionSettings {
        uint256 maxTxLimit;
        uint256 maxWalletLimit;
        bool enabled;
    }

    // ACL constants
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    // Fee constants
    uint256 public constant FEE_DENOMINATOR = 10000; // Allow fees set in the range of 0.01%
    uint256 public constant FEE_OVERDRIVE_BLOCK_LIMIT = 22; // Max block height until fees can be set higher
    uint8 public constant FEE_BUY = 0;
    uint8 public constant FEE_SELL = 1;

    // Liquidity settings
    uint256 public constant SWAP_AT_DENOMINATOR = 10000; // Allow settings set in the range of 0.01%
    uint256 public constant TX_DENOMINATOR = 1000; // Allow settings set in the range of 0.1%

    uint256 public maxTxLimit;
    uint256 public maxWalletLimit;
    bool public limitsEnabled;

    address private immutable _uniswapRouter;    
    address public uniswapPair;
    address private _feeWallet;
    address public grandMasterBeneficiary;

    // exlcude from fees and max transaction amount
    mapping(address => bool) private _feeExempt;
    mapping(address => bool) private _maxTxExempt;
    mapping(address => bool) private _maxWalletExempt;
    mapping(address => bool) private _bots;
    mapping(address => bool) private _pairs;

    IFeeSettings[2] private _fees;

    ILiquiditySettings private _liquiditySettings;
    ITransactionSettings private _txSettings;
    IFeeCollection private _feeCollection;
    ITradeSettings private _tradeSettings;

    constructor(address casterData) CERC20(casterData, "The Curse", "CURSE") {
        // Total supply 100,000
        uint256 totalSupply = 100_000 * 1e18;

        address _owner = _msgSender();

        // ACL configs
        _grantRole(ADMIN_ROLE, _owner);
        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
        _grantRole(OPERATOR_ROLE, _owner);

        // Set default fee wallet and grandMaster
        _feeWallet = address(_owner);
        grandMasterBeneficiary = _feeWallet;

        // Default exempts
        _maxWalletExempt[address(_feeWallet)] = true;
        _maxWalletExempt[address(this)] = true;
        _maxWalletExempt[address(0xdead)] = true;

        _maxTxExempt[address(_feeWallet)] = true;
        _maxTxExempt[address(this)] = true;
        _maxTxExempt[address(0xdead)] = true;

        _feeExempt[address(_feeWallet)] = true;
        _feeExempt[address(this)] = true;
        _feeExempt[address(0xdead)] = true;

        // Default tx limits
        limitsEnabled = true;
        maxTxLimit = (totalSupply * 20) / TX_DENOMINATOR;
        maxWalletLimit = (totalSupply * 30) / TX_DENOMINATOR;

        // Default fee settings
        _fees[FEE_BUY].marketingFee = 300; // 3.0%
        _fees[FEE_BUY].liquidityFee = 200; // 2.0%
        _fees[FEE_BUY].grandMasterFee = 100; // 1.0%
        _fees[FEE_BUY].percentageDiscountPerLvl = 100; // Lvl1: 1.0% | Lvl2: 2.0% | Lvl3: 3.0%

        _fees[FEE_SELL].marketingFee = 300; // 3.0%
        _fees[FEE_SELL].liquidityFee = 200; // 2.0%
        _fees[FEE_SELL].grandMasterFee = 100; // 1.0%
        _fees[FEE_SELL].percentageDiscountPerLvl = 100; // Lvl1: 1.0% | Lvl2: 2.0% | Lvl3: 3.0%

        // Default liquidty settings
        _liquiditySettings.enabled = true;
        _liquiditySettings.swapTokensAtAmount = (totalSupply * 15) / SWAP_AT_DENOMINATOR;

        // Default trade settings
        _tradeSettings.startBlock = 0;
        _tradeSettings.enabled = false;
        _tradeSettings.deadblocks = 2;

        _uniswapRouter = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
               
        _mint(_owner, totalSupply);
    }

    modifier lockSwap() {
        _liquiditySettings.swapping = true;
        _;
        _liquiditySettings.swapping = false;
    }

    /**
     * Internal and private functions
     */

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        IUniswapV2Router02 router = IUniswapV2Router02(_uniswapRouter);
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(router), tokenAmount);

        // add the liquidity
        router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            _feeWallet,
            block.timestamp
        );
    }

    function _swapForEth(uint256 tokenAmount) private {
        IUniswapV2Router02 router = IUniswapV2Router02(_uniswapRouter);
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function _autoSwapBack() private lockSwap {
        uint256 tokenBalance = balanceOf(address(this)) - _feeCollection.tokensForGrandMaster;
        //uint256 tokenBalance = _feeCollection.tokensForLiquidity + _feeCollection.tokensForMarketing;
        uint256 tokens = _feeCollection.tokensForLiquidity + _feeCollection.tokensForMarketing;  

        if ( tokenBalance == 0 || tokens == 0) return ;
        // Enforce limit
        tokenBalance = tokenBalance > _liquiditySettings.swapTokensAtAmount? _liquiditySettings.swapTokensAtAmount : tokenBalance;

        uint256 tokensForLiquidity = (tokenBalance * _feeCollection.tokensForLiquidity) / tokens / 2;
        uint256 amountToEth = tokenBalance - tokensForLiquidity;

        uint256 initialEthBalance = address(this).balance;
        
        _swapForEth(amountToEth);

        uint256 ethBalance = address(this).balance - initialEthBalance;

        // Distribute ETH fees
        uint256 ethForMarketing = (ethBalance * _feeCollection.tokensForMarketing) / tokens;
        uint256 ethForLiquidity = ethBalance - ethForMarketing;

        _feeCollection.tokensForLiquidity = 0;
        _feeCollection.tokensForMarketing = 0;

        payable(_feeWallet).transfer(ethForMarketing);

        if (tokensForLiquidity > 0 && ethForLiquidity > 0) _addLiquidity(tokensForLiquidity, ethForLiquidity);
    }
    
    function _autoSwap(address from, address to) private {
        uint256 tokens = _feeCollection.tokensForLiquidity +
            _feeCollection.tokensForMarketing;

        if(tokens >= _liquiditySettings.swapTokensAtAmount &&
           !_liquiditySettings.swapping &&
           !_pairs[from] &&
           !_feeExempt[from] &&
           !_feeExempt[to] &&
           _liquiditySettings.enabled)
        {
            _autoSwapBack();
        }
    }
    
    function _isLaunched(address from, address to) private view {
        require(
            _feeExempt[from] || _feeExempt[to] || _tradeSettings.enabled,
            "CURSE: not launched yet"
        );
    }


    function _collectFee(uint256 amount, uint8 selector, uint8 level) private returns (uint256) {
        uint256 totalFeeWithoutDiscount = _fees[selector].marketingFee + 
                _fees[selector].liquidityFee + 
                _fees[selector].grandMasterFee;
        uint256 totalFee = totalFeeWithoutDiscount - ( uint256(level) * _fees[selector].percentageDiscountPerLvl );
                
        uint256 fees = (amount * totalFee) / FEE_DENOMINATOR;

        _feeCollection.tokensForLiquidity += (fees * _fees[selector].liquidityFee) / totalFeeWithoutDiscount;
        _feeCollection.tokensForMarketing += (fees * _fees[selector].marketingFee) / totalFeeWithoutDiscount;
        _feeCollection.tokensForGrandMaster += (fees * _fees[selector].grandMasterFee) / totalFeeWithoutDiscount;

        return fees;
    }

    function _ensureLimits(address from, address to, uint256 amount, bool isBuy) private view {
        if (
            from != _feeWallet &&
            to != _feeWallet &&
            !_maxTxExempt[from] &&
            !_maxTxExempt[to] &&
            !_maxTxExempt[tx.origin] &&
            !_maxWalletExempt[from] &&
            !_maxWalletExempt[to] &&
            !_maxWalletExempt[tx.origin] &&
            limitsEnabled &&
            from != address(this) &&
            to != address(this)
        ) 
        {
            require(amount <= maxTxLimit, "CURSE: tx over limit");
            if (isBuy) {
                require(
                    (amount + balanceOf(to)) <= maxWalletLimit,
                    "CURSE: wallet over limit"
                );
            }
        }
        
    }

    function _isTakeFee(address from, address to) private view returns (bool) {
        bool takeFee = !_liquiditySettings.swapping;
        if (_feeExempt[from] || _feeExempt[to]) {
            takeFee = false;
        }
        return takeFee;
    }

    /**
     * @dev Helper function to return the uniswap pair of the contract. 
     * must be implemented by the child
     *
     * Returns:
     * - `address` of the uniswap pair
     */
    function _getUniswapPair() internal override view returns (address) {
        return uniswapPair;
    }

    /**
     * @dev Helper function to transfer the collected tokens from a previous grandmaster to the new one. Will be called by `illusion` 
     * and the child contract has the responsibility to implement it.
     *
     * Returns:
     * - `caster` the new grandmaster
     */
    function _transferGrandMaster(address caster) internal override {
        uint256 amount = _feeCollection.tokensForGrandMaster;
        // Reset the fee collection
        _feeCollection.tokensForGrandMaster = 0;
        
        if (amount > 0) 
            _transfer(address(this), grandMasterBeneficiary, amount);
        
        // Set the new grandMaster
        grandMasterBeneficiary = caster;
    }
    
    /**
     * Standard trade functions
     */

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "CURSE: transfer from the zero address");
        require(to != address(0), "CURSE: transfer to the zero address");       
        require(!_bots[from], "CURSE: bot detected");

        // Check if launched
        _isLaunched(from, to);

        // Perform the autoswap if possible
        _autoSwap(from, to);

        bool isBuy = _pairs[from];
        bool isSell = _pairs[to];

        // Ensure the limits if applicable
        _ensureLimits(from, to, amount, isBuy);
            
        uint256 fees = 0;
        if (_isTakeFee(from, to)) {
            if (isBuy) {
                if ((block.number < _tradeSettings.startBlock + _tradeSettings.deadblocks)) {
                    _bots[to] = true;
                }
                fees = _collectFee(amount, FEE_BUY, CASTER.getLevel(to));

            } else if (isSell) {
                require(!isFrozen(from), "CURSE: you are frozen");
                require(!isStolen(from), "CURSE: you are a thief");

                fees = _collectFee(amount, FEE_SELL, CASTER.getLevel(from));                
            } else { 
                // This is a wallet < - > wallet transfer. The frozen curse could be broken here, but hey ... you cannot be smarter than TheKeeper
                require(!isFrozen(from), "CURSE: you are frozen");
                require(!isStolen(from), "CURSE: you are a thief");
            }

            if (fees > 0) {

                super._transfer(from, address(this), fees);
            }
            amount = amount - fees;
        }

        super._transfer(from, to, amount);
    }

    receive() external payable {}


    /**
     * Config/Management section
     */
    function setSpellBook(address spellBook) external onlyRole(ADMIN_ROLE) {
        _grantRole(SPELLBOOK_ROLE, spellBook);
        setEnableExempt(spellBook, true, true, true);
    }

    function promoteAdmin(address newAdmin) public onlyRole(ADMIN_ROLE) {
        _grantRole(ADMIN_ROLE, newAdmin);
    }

    function updateFeeWallet(address wallet) public onlyRole(ADMIN_ROLE) {
        _feeExempt[wallet] = true;
        _maxTxExempt[wallet] = true;
        _maxWalletExempt[wallet] = true;

        _feeWallet = wallet;
    }

    function promoteOperator(address operator) public onlyRole(OPERATOR_ROLE) {
        _grantRole(OPERATOR_ROLE, operator);
    }

    function setEnablePair(address pair, bool value) external onlyRole(OPERATOR_ROLE) {
        _pairs[pair] = value;
    }

    function updateTxLimit(uint256 percentage, uint256 divisor) external onlyRole(OPERATOR_ROLE)
    {
        maxTxLimit = (totalSupply() * percentage) / divisor;
        require(maxTxLimit >= (totalSupply() * 1000) / 100000, "CURSE: too low"); // Max TX must be more than 1,000
    }

    function updateMaxWallet(uint256 percentage, uint256 divisor) external onlyRole(OPERATOR_ROLE)
    {
        maxWalletLimit = (totalSupply() * percentage) / divisor;
        require(maxWalletLimit >= (totalSupply() * 1000) / 100000, "CURSE: too low"); // Max TX must be more than 1,000
    }

    function updateSwapTokensAt(uint256 percentage, uint256 divisor) external onlyRole(OPERATOR_ROLE)
    {
        _liquiditySettings.swapTokensAtAmount =
            (totalSupply() * percentage) /
            divisor;
    }

    function setEnableExempt(address addr, bool fee, bool maxTx, bool maxWallet) public onlyRole(OPERATOR_ROLE) {
        _feeExempt[addr] = fee;
        _maxTxExempt[addr] = maxTx;
        _maxWalletExempt[addr] = maxWallet;
    }

    function updateBuyFee(uint64 marketing, uint64 liquidity, uint64 grandMaster, uint64 discountPerLvl) external onlyRole(OPERATOR_ROLE)
    {
        uint64 sum = marketing + liquidity + grandMaster;
        
        if (block.number > (_tradeSettings.startBlock + FEE_OVERDRIVE_BLOCK_LIMIT) && _tradeSettings.enabled) {
            require(sum <= 1100, "CURSE: Fee too high"); // Max fee is 11%
        }
        
        require((discountPerLvl * 3) <= sum, "CURSE: discount must less than fees");

        _fees[FEE_BUY].marketingFee = marketing; 
        _fees[FEE_BUY].liquidityFee = liquidity; 
        _fees[FEE_BUY].grandMasterFee = grandMaster;
        _fees[FEE_BUY].percentageDiscountPerLvl = discountPerLvl;
    }

    function updateSellFee(uint64 marketing, uint64 liquidity, uint64 grandMaster, uint64 discountPerLvl) external onlyRole(OPERATOR_ROLE)
    {
        uint64 sum = marketing + liquidity + grandMaster;
        
        if (block.number > (_tradeSettings.startBlock + FEE_OVERDRIVE_BLOCK_LIMIT) && _tradeSettings.enabled) {
            require(sum <= 1100, "CURSE: Fee too high"); // Max fee is 11%
        }
        
        require((discountPerLvl * 3) <= sum, "CURSE: discount must less than fees");

        _fees[FEE_SELL].marketingFee = marketing; 
        _fees[FEE_SELL].liquidityFee = liquidity; 
        _fees[FEE_SELL].grandMasterFee = grandMaster;
        _fees[FEE_SELL].percentageDiscountPerLvl = discountPerLvl;
    }
    
    function removeLimits() external onlyRole(OPERATOR_ROLE) {
        limitsEnabled = false;
    }

    function sendEth() external onlyRole(OPERATOR_ROLE) {
        payable(_feeWallet).transfer(address(this).balance);
    }

    function swap() external onlyRole(OPERATOR_ROLE) {
        _autoSwapBack();
    }

    function removeBot(address bot) external onlyRole(OPERATOR_ROLE) {
        _bots[bot] = false;
    }

    function enableTrading(uint256 deadblock) external onlyRole(OPERATOR_ROLE) {
        require(!_tradeSettings.enabled, "CURSE: already enabled");
        _tradeSettings.enabled = true;
        _tradeSettings.startBlock = block.number;
        _tradeSettings.deadblocks = deadblock;
    }


    function releaseTheCurse() external onlyRole(OPERATOR_ROLE) {
        IUniswapV2Router02 router = IUniswapV2Router02(_uniswapRouter);
        address pair = IUniswapV2Factory(router.factory()).createPair(
            address(this),
            router.WETH()
        );
        // Store the pair
        _pairs[pair] = true;
        // Shorthand for uniswap pair
        uniswapPair = pair;
    }

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
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
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
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
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
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
}