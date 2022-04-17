// SPDX-License-Identifier: Unlicense
/// @title: the reliquary
/// @author: remnynt.eth

/*
   _   _                     _ _                                
  | |_| |__   ___   _ __ ___| (_) __ _ _   _  __ _ _ __ _   _   
  | __| '_ \ / _ \ | '__/ _ \ | |/ _` | | | |/ _` | '__| | | |  
  | |_| | | |  __/ | | |  __/ | | (_| | |_| | (_| | |  | |_| |  
   \__|_| |_|\___| |_|  \___|_|_|\__, |\__,_|\__,_|_|   \__, |  
                                    |_|                 |___/   
*/
/*
  Seeker,

    Rumors abound ... proof of the divine? The "original" mystery?
    The way I see it, there was no spark; time has no beginning.

    We can try to find that early place, before everything; indeed, perhaps it's our duty.
  But that quest to find the first little thing that happened is an asymptote to the unknowable.
  As if something could flicker out of nothing, the first vibration in a void is just as likely
  the last of what came before, dancing on a mirror's edge.

    And yet, undaunted, we pull on those strings, yearning to unravel the mystery of our origin.
  Which thus far, brings us to the elements eight. Whether you worship those gods, practice the
  schools of magic, or pay no heed at all, the one shared truth is that these elements are the
  fundamental building blocks of our world. Learned arcanists believe each its own substrate of
  aether, a medium upon which pure elemental energy flows, and from the summation of those
  microscopic movements arise the physical laws as we know them. It's that knowledge that's gotten
  us this far.

    Of course, most scoff at the theorycraft, finding it easier to cling to the zealotry of this
  element's church or that. Nevertheless, all eyes are on this singular discovery: the reliquary.
  Ancient and nameless, lost in the shifting sands of the Bal'gurub, its existence will bring
  every explorer worth their salt for horizons around. If you can get inside, and claim one of
  its relics, study it; there's no doubt we'll be one step closer to uncovering the truth.

    Now, be warned, adventurer. We know not what dangers lie within, nor how to gain entry.
  Steel yourself, take what supplies you can carry, and elements, or gods, be with you.

    Ahn Pendrose
    Guild's Knight of the Seekers
 */

pragma solidity ^0.8.4;

import "@0xsequence/sstore2/contracts/SSTORE2.sol";
import '@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import './ERC721ATM.sol';
import './TRMeta.sol';

/// @notice There are reports, first sourced from a nomadic shepherd, that indicate an enigmatic
///         structure has been partially revealed by the sands' ebb and flow. It's located a few
///         horizons beyond the southern edge of the Emptiness, that most unforgiving and desolate
///         corner of the desert. He was foolish enough to chase a runaway from his flock that far,
///         let alone to tell the tale. Unsurprisingly, he's since "gone missing." Droves of
///         treasure hunters have already begun to descend upon the nearest village. They're
///         calling it, "the reliquary."
contract TheReliquary is
  ERC721ATM('the reliquary', 'RELICS'),
  ERC721Holder,
  ReentrancyGuard
{
  using Strings for uint256;

  struct Reliquary {
    uint8 curiosDiscovered;
    uint8 secretsDiscovered;
    bool isDiscovered;
    string runicSeal;
    string hiddenLeyLines;
  }

  struct Relic {
    uint8 level;
    uint32 mana;
    bool isDivinityQuestLoot;
    bool isSecretDiscovered;
    address authorizedCreator;
    address glyph;
    string transmutation;
    uint24[] colors;
    bytes32 runeHash;
  }

  struct Adventurer {
    uint256 currentChamber;
    uint256 aether;
  }

  Reliquary private reliquary;

  /// @notice A collection of curious items sealed for millennia within the reliquary.
  ///         By whom and for what purpose are yet to be determined.
  mapping(uint256 => Relic) public relics;

  /// @notice A record of the brave souls who've attempted entry into the reliquary.
  ///         Those able to channel aether from vibes have been noted.
  mapping(address => Adventurer) public adventurers;

  /// @notice Vibes? Oh yes, our shorthand for vibrational energy; a crafty artificer
  ///         managed to capture it, pure elemental aether, into these vessels we call "vibes."
  ///         There may yet be some available; their aether identifier is:
  ///         0x6c7C97CaFf156473F6C9836522AE6e1d6448Abe7
  mapping(uint256 => bool) public vibesAetherChanneled;

  event RelicUpdate(uint256 tokenId);

  error ReliquaryNotDiscovered();
  error DivinityQuestProgressionMismatch();
  error NotEntrustedOrInYourPossession();
  error NotApprovedCreatorOrOwner();
  error GrailsAreUnalterable();
  error NoAdvancedSpellcastingContracts();
  error InvalidTokenId();
  error InvalidElement();
  error UnableToCarrySoManyAtOnce();
  error OutOfRelics();
  error MissingInscription();
  error ReliquaryAlreadySealed();
  error IncorrectWhispers();
  error IncorrectElementalWeakness();
  error IncorrectInnerDemonElement();
  error OutOfCurios();
  error NotEnoughAether();
  error NoSecretsLeftToReveal();
  error RelicAlreadyWellStudied();
  error NotEnoughMana();
  error NoAetherRemainingUseMintInstead();
  error OnlyBurnsVibes();
  error InvalidCustomization();
  error RelicAlreadyAtMaxLevel();

  constructor() {
    // The aetheric toll is reduced for the bravest of adventurers.
    reliquary.curiosDiscovered = 1;
    reliquary.secretsDiscovered = 1;
  }

  receive() external payable {}
  fallback() external payable {}

  modifier prohibitTimeTravel() {
    // Will happen, happening, happened. Millennia can pass in an instant, as long as
    // each little thing happens in the right order and everything in its right place.
    if (!reliquary.isDiscovered) revert ReliquaryNotDiscovered();
    _;
  }

  modifier prohibitTeleportation(uint256 requiredChamber) {
    // You know not where you stand. Follow the steps of the Divinity Quest, and you shall
    // find that which you seek; that is unless those other treasure hunters got there first.
    uint256 currentChamber = adventurers[_msgSender()].currentChamber;
    if (currentChamber != requiredChamber) revert DivinityQuestProgressionMismatch();
    _;
  }

  modifier preventDeadEnds() {
    // The coffers of Divinity's End have nought left but motes of dust.
    // You may yet find other relics if you explore the less precarious parts of the reliquary.
    if (reliquary.curiosDiscovered > TRKeys.CURIO_SUPPLY) revert OutOfCurios();
    _;
  }

  modifier prohibitThievery(uint256 tokenId) {
    // You are not the rightful owner, but don't be discouraged. Everything has a price ...
    if (!isApprovedOrOwnerOf(tokenId)) revert NotEntrustedOrInYourPossession();
    _;
  }

  modifier prohibitVandalism(uint256 tokenId) {
    // You are not the rightful owner or authorized creator. Do ask permission, first!
    if (!isApprovedOrOwnerOf(tokenId)
      && _msgSender() != relics[tokenId].authorizedCreator
      && _msgSender() != TRKeys.VIBES_GENESIS
      && _msgSender() != TRKeys.VIBES_OPEN)
    {
      revert NotApprovedCreatorOrOwner();
    }
    _;
  }

  modifier prohibitDesecration(uint256 tokenId) {
    // A relentlessly curious collector once hired a master smith to deconstruct a grail. The pair
    // were lucky to survive; they were found perforated by metal shrapnel and knocked unconscious
    // by the otherworldly reverberations that erupted from the first strike of his hammer.
    if (getGrailId(tokenId) != TRKeys.GRAIL_ID_NONE) revert GrailsAreUnalterable();
    _;
  }

  modifier prohibitAdvancedSpellcasting() {
    // Advanced spellcasting is prohibited. There's no doubt with this level of expertise,
    // you'd fell a dragon with your last enchanted arrow in the midst of a blizzard atop the
    // tallest mountain, but do save your energy for such an occasion!
    if (tx.origin != _msgSender()) revert NoAdvancedSpellcastingContracts();
    _;
  }

  modifier prohibitBlasphemy(uint256 tokenId) {
    // No such relic exists! One cannot simply speak a thing into existence through sheer force
    // of will. I suppose you'd also like to print paper money from a steam-powered press?
    if (tokenId < 1 || tokenId > super.totalSupply()) revert InvalidTokenId();
    _;
  }

  modifier requireValidElement(string memory element) {
    // Do respect the eight elements; call them by their proper names.
    // When writing, be sure to capitalize the first letter to distinguish the element from
    // a more common manifestation, for example, the ocean's salty water is of the Water element.
    if (TRUtils.compare(element, TRKeys.ELEM_NATURE)
      || TRUtils.compare(element, TRKeys.ELEM_LIGHT)
      || TRUtils.compare(element, TRKeys.ELEM_WATER)
      || TRUtils.compare(element, TRKeys.ELEM_EARTH)
      || TRUtils.compare(element, TRKeys.ELEM_WIND)
      || TRUtils.compare(element, TRKeys.ELEM_ARCANE)
      || TRUtils.compare(element, TRKeys.ELEM_SHADOW)
      || TRUtils.compare(element, TRKeys.ELEM_FIRE))
    {
      // A valid element, indeed!
    } else {
      // No such element exists!
      revert InvalidElement();
    }
    _;
  }

  modifier enforceInventoryLimits(uint256 mintCount) {
    // Don't expect to escape the reliquary with more than you can carry.
    if (mintCount > TRKeys.INVENTORY_CAPACITY) revert UnableToCarrySoManyAtOnce();
    _;
  }

  modifier enforceAbsoluteScarcity(uint256 mintCount) {
    // This old place is empty now. If you must lay hands on a relic yourself, you may be able to
    // convince a fellow adventurer to part with theirs...
    uint256 currentRelics = totalSupply() + 1 - reliquary.curiosDiscovered;
    if (currentRelics + mintCount > TRKeys.RELIC_SUPPLY) revert OutOfRelics();
    _;
  }

  /// @notice Divinity Quest - Step 0: When is now?
  /// @dev The past stretches out behind us, like the horizon, always out of reach.
  ///      Done or undone, it matters not. Continue onward with what you've got.
  ///      A lone sage walks his fated path. The scripts, his guide. The gods, his wrath.
  /// @param inscription With this sacred runeword, the Ancient Reliquary is sealed.
  function inscribeRunicSeal(string memory inscription)
    public
    onlyOwner
  {
    // That is not a runic seal; the sage falters, but mustn't lose hope.
    if (bytes(inscription).length == 0) revert MissingInscription();

    // The Ancient Reliquary was sealed long ago.
    if (bytes(reliquary.runicSeal).length != 0) revert ReliquaryAlreadySealed();

    // The sage met with destiny.
    // The truth, safe within, would soon outlast those who sought to destroy it.
    reliquary.runicSeal = inscription;

    // And so, it came to pass. Centuries, millennia, the world ever changing...
    // Until finally today, having laid dormant, concealed, for so long, it is found once again.
    reliquary.isDiscovered = true;
  }

  /// @notice Divinity Quest - Step 1: Enter the Ancient Reliquary
  /// @dev The entrance was sealed with a powerful runeword long ago.
  ///      The spell used here has the markings of a forgotten order.
  ///      All that remains is a name: "The Guardians of Origin."
  /// @param whispering There must be a way inside. What if we could find the inscription,
  ///                   or at least remnants of it? Scan the surrounding aether...
  function whisperRunicSeal(string memory whispering)
    public
    preventDeadEnds
    prohibitTimeTravel
    prohibitTeleportation(TRKeys.RELIQUARY_CHAMBER_OUTSIDE)
  {
    // Your whispering is lost in the rasps of the desert wind.
    if (!TRUtils.compare(whispering, reliquary.runicSeal)) revert IncorrectWhispers();

    // Your syllables ignite in blue flames against the solid rock slab that blocks the entrance.
    // As it rumbles open before you, the glow of elden magic reveals a stone passage.
    // You step inside, determined to discover the truth. The Guardian's Hall awaits.
    adventurers[_msgSender()].currentChamber = TRKeys.RELIQUARY_CHAMBER_GUARDIANS_HALL;
  }

  /// @notice Divinity Quest - Step 2: Access the Inner Sanctum
  /// @dev The Guardian's Hall extends in both directions, like a ring wrapped 'round the reliquary.
  ///      An army of Elemental Guardians marches endlessly within the massive circular corridor.
  ///      Beyond them, lies the Inner Sanctum, and the only way through is by force.
  /// @param attackElement Breaking this line won't be easy; we need to land a spell at just the
  ///                      right moment, coinciding with the elemental weakness of the guardian
  ///                      before us. I'd estimate a 1 in 8 chance of success. Good luck!
  function challengeElementalGuardians(string memory attackElement)
    public
    preventDeadEnds
    prohibitTeleportation(TRKeys.RELIQUARY_CHAMBER_GUARDIANS_HALL)
  {
    // You seize the moment, attacking the elemental directly in front of you.
    string memory previousHash = uint256(blockhash(block.number - 1)).toHexString();
    string memory guardianElement = detectElementals(previousHash);
    string memory weaknessElement = detectElementalWeakness(guardianElement);

    // It's not very effective! Rattled, but unscathed, you resolve to try again.
    if (!TRUtils.compare(weaknessElement, attackElement)) revert IncorrectElementalWeakness();

    // It's super effective! The elemental groans as it implodes spectacularly!
    // The opening is just enough. You sprint across the hall, and down a well-worn stair.
    // At the bottom, the Inner Sanctum beckons in ominous silence.
    adventurers[_msgSender()].currentChamber = TRKeys.RELIQUARY_CHAMBER_INNER_SANCTUM;
  }

  /// @notice Divinity Quest - Step 3: Defeat your Inner Demon
  /// @dev Every man has within him a darkness, the raw echoes of primordial chaos.
  ///      Soulbound, these demons can never be truly purged, but perhaps, with tremendous
  ///      self-awareness and strength of will, they can be controlled. The Inner Sanctum
  ///      is a space designed for that very purpose. A shrine for meditation sits calmly
  ///      in the chamber's center, across from the gilded gates that lead to Divinity's End.
  /// @param innerDemonElement Kneel before the shrine. Your first goal is to identify the type
  ///                          of demon buried within the depths of your heart.
  /// @param attackElement Once identified, you must also discover, and make use of, its weakness.
  function challengeInnerDemon(string memory innerDemonElement, string memory attackElement)
    public
    preventDeadEnds
    prohibitTeleportation(TRKeys.RELIQUARY_CHAMBER_INNER_SANCTUM)
  {
    // Bowing your head and closing your eyes, you fill your lungs with the stale air.
    string memory walletElement = detectDemons(_msgSender());

    // You fail to understand that which holds you back. You must keep searching.
    if (!TRUtils.compare(walletElement, innerDemonElement)) revert IncorrectInnerDemonElement();

    // A cursed demon emerges, tethered from somewhere deep within your soul.
    string memory weaknessElement = detectElementalWeakness(walletElement);

    // Tendrils of magic coalesce between its claws, as your attempt to counter has no effect.
    // It launches a powerful bolt, striking you directly in the chest.
    // A searing pain grips your heart, and suddenly, nothing. Darkness.
    // Hours pass, or days? You awaken, alone, but alive. Was it ... just a dream?
    if (!TRUtils.compare(weaknessElement, attackElement)) revert IncorrectElementalWeakness();

    // The demon releases a condensed spell blast! With a swift wave of your hand,
    // streaking magic from your fingertips, you crush the enemy's bolt in the palm of your hand.
    // The shockwave from the elemental annihilation, rips the air from the room, and the demon,
    // from its corporeal manifestation. A gleaming aura ahead reveals the path to Divinity's End.
    adventurers[_msgSender()].currentChamber = TRKeys.RELIQUARY_CHAMBER_DIVINITYS_END;
  }

  /// @notice Divinity Quest - Step 4: Claim a Divine Curio
  /// @dev As you enter the most sacred place within the reliquary, your feet grow heavy, your
  ///      senses captivated by its grandeur. Like the interior of a palace most grand, all is
  ///      engulfed in shimmering warm light, emanating from enchanted magical cores, ensconced
  ///      within orbs of pure gold filigree, a celebration of ancient craftsmanship in worship
  ///      of the divine. At last, you've arrived. A tithe of aether, mana channeled from your
  ///      very being, is required. A threshold of at least 0.08 will suffice.
  function mintDivineCurio()
    public
    payable
    nonReentrant
    preventDeadEnds
    prohibitAdvancedSpellcasting
    prohibitTeleportation(TRKeys.RELIQUARY_CHAMBER_DIVINITYS_END)
  {
    // A worthy tithe of aether is required to claim a divine curio.
    if (msg.value < TRKeys.CURIO_TITHE) revert NotEnoughAether();

    // Your tithe accepted, a roughly hewn pedestal begins to rise against the far wall.
    // Divine light fills the room, illuminating golden adornments resting beneath lifetimes
    // of dust. It's almost too bright to see; a curious relic lay before you atop the pedestal.
    // As you take it into your hands, magic courses across its surface, responding to your touch.
    // An ancient device of sorts? A thought sparks, as if not your own: learn, create, feel ...
    adventurers[_msgSender()].currentChamber = TRKeys.RELIQUARY_CHAMBER_CHAMPIONS_VAULT;
    _mintDivineCurio();
  }

  /// @notice Spell of Divination: Secrets
  /// @dev Use this spell whilst studying a relic in your possession. With any luck, you may
  ///      discover its secrets. At the very least, it's a great way to store up mana for use
  ///      on your future travels.
  /// @param tokenId The relic you seek to study; of course, it must also be in your possession.
  function seekDivineKnowledge(uint256 tokenId)
    public
    prohibitThievery(tokenId)
  {
    // The Queen's Grails, and the ley lines connecting them, have all been discovered.
    if (reliquary.secretsDiscovered > TRKeys.SECRETS_OF_THE_GRAIL) revert NoSecretsLeftToReveal();

    // This relic has already been thoroughly studied.
    if (relics[tokenId].isSecretDiscovered) revert RelicAlreadyWellStudied();

    // Your fervent studies bear fruit, another secret uncovered. Filled with excitement,
    // you feel primal mana coursing from within; your relic glows as if charged with new power.
    relics[tokenId].isSecretDiscovered = true;
    relics[tokenId].mana += TRKeys.MANA_FROM_DIVINATION;
    reliquary.secretsDiscovered++;

    if (reliquary.secretsDiscovered > TRKeys.SECRETS_OF_THE_GRAIL) {
      // A revelation! You've discovered hidden ley lines that run beneath the reliquary.
      // They seem to connect to certain relics ... but what does it mean?
      reliquary.hiddenLeyLines = getRuneHash(tokenId);
    }
  }

  /// @notice Spell of Divination: Elementals
  /// @dev Use this spell to detect a nearby elemental and to identify its intrinsic element.
  /// @param previousHash A unique identifier representing your four-dimensional location in the
  ///                     space-time continuum. With it being nigh impossible to calculate a hash
  ///                     of your current position, it's best to rely on one previous.
  function detectElementals(string memory previousHash)
    public
    view
    returns (string memory)
  {
    TRKeys.RuneCore memory core;
    core.tokenId = TRKeys.ELEMENTAL_GUARDIAN_DNA;
    core.runeHash = previousHash;
    core.metadataAddress = getMetadataAddress(core.tokenId);
    return ITRMeta(core.metadataAddress).getElement(core);
  }

  /// @notice Spell of Divination: Demons
  /// @dev Use this spell on any uncorrupted creature to identify potential demons lurking within.
  /// @param id The unique identifier of the creature to analyze. Most bipedal humanoids keep a
  ///           copy in their wallet.
  function detectDemons(address id)
    public
    view
    returns (string memory)
  {
    TRKeys.RuneCore memory core;
    core.tokenId = TRKeys.ELEMENTAL_GUARDIAN_DNA;
    core.runeHash = uint256(uint160(id)).toHexString();
    core.metadataAddress = getMetadataAddress(core.tokenId);
    return ITRMeta(core.metadataAddress).getElement(core);
  }

  /// @notice Spell of Divination: Weaknesses
  /// @dev Use this spell whilst focusing your mind on any element. Upon casting, that element's
  ///      weakness will become known to you.
  /// @param element The element about which you seek knowledge.
  function detectElementalWeakness(string memory element)
    public
    pure
    returns (string memory)
  {
    if (TRUtils.compare(element, TRKeys.ELEM_NATURE)) {
      return TRKeys.ELEM_FIRE;
    } else if (TRUtils.compare(element, TRKeys.ELEM_FIRE)) {
      return TRKeys.ELEM_WATER;
    } else if (TRUtils.compare(element, TRKeys.ELEM_WATER)) {
      return TRKeys.ELEM_WIND;
    } else if (TRUtils.compare(element, TRKeys.ELEM_WIND)) {
      return TRKeys.ELEM_EARTH;
    } else if (TRUtils.compare(element, TRKeys.ELEM_EARTH)) {
      return TRKeys.ELEM_NATURE;
    } else if (TRUtils.compare(element, TRKeys.ELEM_ARCANE)) {
      return TRKeys.ELEM_SHADOW;
    } else if (TRUtils.compare(element, TRKeys.ELEM_SHADOW)) {
      return TRKeys.ELEM_LIGHT;
    } else {
      return TRKeys.ELEM_ARCANE;
    }
  }

  /// @notice Spell of Transmutation: Elements (USE WITH CAUTION)
  /// @dev This powerful spell can permanently transmute the element of a relic to any other,
  ///      but be warned! It consumes a vibe in the process; the vibe will be irreversibly
  ///      lost to the aether, where it can never be owned or used again.
  /// @param tokenId The relic which you seek to transmute.
  /// @param element The new element to which your relic will belong.
  /// @param burnVibeId The catalyst to be burned: a [genesis] or [open] vibe.
  ///                   This vibe will be burned, you will no longer own it, nor can anyone else.
  function transmuteElement(uint256 tokenId, string memory element, uint256 burnVibeId)
    public
  {
    _lockVibeForever(burnVibeId, tokenId);
    _transmuteElement(tokenId, element);
    emit RelicUpdate(tokenId);
  }

  function _transmuteElement(uint256 tokenId, string memory element)
    private
    prohibitVandalism(tokenId)
    prohibitDesecration(tokenId)
    requireValidElement(element)
  {
    relics[tokenId].transmutation = element;
  }

  /// @notice Spell of Creation: Glyphs (USE WITH CAUTION)
  /// @dev This powerful spell can permanently inscribe a glyph of your own design upon your relic,
  ///      but be warned! It consumes a vibe in the process; the vibe will be irreversibly
  ///      lost to the aether, where it can never be owned or used again.
  /// @param tokenId The relic which you seek to alter.
  /// @param glyph The data that defines the shape and characteristics of your design.
  ///              It's an array, length 64, of integers. Each integer represents a row
  ///              of points that make up your glyph. The 64 least-significant digits represent
  ///              each column within that row, 0 being no change, and 9 being max change.
  /// @param burnVibeId The catalyst to be burned: a [genesis] or [open] vibe.
  ///                   This vibe will be burned, you will no longer own it, nor can anyone else.
  function createGlyph(uint256 tokenId, uint256[] memory glyph, uint256 burnVibeId)
    public
  {
    _lockVibeForever(burnVibeId, tokenId);
    _createGlyph(tokenId, glyph, _msgSender());
    emit RelicUpdate(tokenId);
  }

  function _createGlyph(uint256 tokenId, uint256[] memory glyph, address credit)
    private
    prohibitVandalism(tokenId)
    prohibitDesecration(tokenId)
  {
    relics[tokenId].glyph = SSTORE2.write(abi.encode(credit, glyph));
  }

  /// @notice Spell of Imagination: Colors (USE WITH CAUTION)
  /// @dev This powerful spell can permanently infuse your relic with colors of your choosing,
  ///      but be warned! It consumes a vibe in the process; the vibe will be irreversibly
  ///      lost to the aether, where it can never be owned or used again.
  /// @param tokenId The relic which you seek to reimagine.
  /// @param colors The data that defines the color palette to use.
  ///               It's an array, length 6, of integers. Each integer represents a color,
  ///               between 0 (black) and 16777215 (white). Any colors added beyond the
  ///               color count of your relic will be ignored. Colors should be listed in
  ///               order of strength; the first is the primary color, at index 0.
  /// @param burnVibeId The catalyst to be burned: a [genesis] or [open] vibe.
  ///                   This vibe will be burned, you will no longer own it, nor can anyone else.
  function imagineColors(uint256 tokenId, uint24[] memory colors, uint256 burnVibeId)
    public
  {
    _lockVibeForever(burnVibeId, tokenId);
    _imagineColors(tokenId, colors);
    emit RelicUpdate(tokenId);
  }

  function _imagineColors(uint256 tokenId, uint24[] memory colors)
    private
    prohibitVandalism(tokenId)
    prohibitDesecration(tokenId)
  {
    relics[tokenId].colors = colors;
  }

  /// @notice Spell of Creation: Camaraderie
  /// @dev Use this spell to grant certain privileges to a trusted friend. The authorized friend
  ///      will be considered a creator who can use transmuteElement, createGlyph, and
  ///      imagineColors. At the time of spellcasting, the catalysts to be used must be held by the
  ///      creator.
  /// @param tokenId The relic which can be modified by the creator.
  /// @param creator The address belonging to the creator to be granted privileges. Pass address(0)
  ///                to revoke any so granted privileges.
  function authorizeCreator(uint256 tokenId, address creator)
    public
    prohibitThievery(tokenId)
  {
    relics[tokenId].authorizedCreator = creator;
  }

  /// @notice Spell of Enhancement: Relic Level
  /// @dev Use this spell to break limiters installed in the runic circuits of your relic. Doing
  ///      so will increase its mana regeneration, but may also change its visual appearance. Any
  ///      underlying corruption may be exposed. It's not a certainty, but it is possible that
  ///      our knowledge of these relics' inner-workings may advance over time, unlocking higher
  ///      potential levels.
  /// @param tokenId The relic which you seek to upgrade. It must contain enough mana to sustain
  ///                the upgrade; that mana will be consumed in the process.
  function upgradeRelic(uint256 tokenId)
    public
    prohibitThievery(tokenId)
  {
    address metadataAddress = getMetadataAddress(tokenId);
    uint8 maxLevel = ITRMeta(metadataAddress).getMaxRelicLevel();
    uint8 level = getLevel(tokenId);

    // This relic is at its pinnacle. Mayhap, one day, we will discover what it means to take it
    // one step further. Until then, congratulations on this triumph over ancient technology.
    if (level >= maxLevel) revert RelicAlreadyAtMaxLevel();

    consumeMana(tokenId, TRKeys.MANA_COST_TO_UPGRADE);
    relics[tokenId].level = ++relics[tokenId].level;
    emit RelicUpdate(tokenId);
  }

  /// @notice Spell of Divination: Relic Level
  /// @dev Use this spell to measure the upgrade level of a given relic.
  /// @param tokenId The relic to be sized up.
  function getLevel(uint256 tokenId)
    public
    view
    returns (uint8)
  {
    return relics[tokenId].level + 1;
  }

  /// @notice Spell of Divination: Mana
  /// @dev Use this spell to measure the supply of mana stored within a given relic.
  ///      Be warned, adventurer! Transferring possession of relics as delicate as these will
  ///      reduce any stored mana by half.
  /// @param tokenId The relic to be measured.
  function getMana(uint256 tokenId)
    public
    view
    returns (uint32)
  {
    uint256 startTimestamp = _ownerships[tokenId].startTimestamp;
    if (startTimestamp == 0) {
      return relics[tokenId].mana;
    }

    uint8 level = getLevel(tokenId);
    uint32 manaPerYear = level < 2 ? TRKeys.MANA_PER_YEAR : TRKeys.MANA_PER_YEAR_LV2;
    uint256 elapsed = block.timestamp - startTimestamp;
    uint32 accumulatedMana = uint32((elapsed * manaPerYear) / TRKeys.SECONDS_PER_YEAR);
    return relics[tokenId].mana + accumulatedMana;
  }

  /// @notice Consume Resource: Mana (USE WITH CAUTION)
  /// @dev Our world is one of infinite possibilities. Using this spell alone is not advised,
  ///      but were it to be channeled into another spell, or magical contract, in the creation of,
  ///      or as a requirement for, some fantastic purpose, that would indeed be worthwhile.
  ///      By what means or from whom such purposes arise is uncertain, but the imaginations of
  ///      those practiced in magic are as boundless as the sea of stars afloat in the night sky.
  /// @param tokenId The relic which will have an amount of its mana consumed.
  /// @param manaCost The amount of mana required and consumed by the accompanying spellcast.
  function consumeMana(uint256 tokenId, uint32 manaCost)
    public
    prohibitThievery(tokenId)
  {
    uint32 mana = getMana(tokenId);

    // The cost requirements of mana are absolute; such is the nature of measuring pure energy.
    if (mana < manaCost) revert NotEnoughMana();

    relics[tokenId].mana = mana - manaCost;
    _ownerships[tokenId].startTimestamp = uint64(block.timestamp);
  }

  /// @notice Spell of Divination: Relic Traits - Element
  /// @dev Identifies the element trait of a given relic.
  ///      The universe, as we know it, is the result of elemental vibrations
  ///      within the aether, on a microscopic scale.
  /// @param tokenId The relic to be tested.
  function getElement(uint256 tokenId)
    public
    view
    returns (string memory)
  {
    TRKeys.RuneCore memory core = getRuneCore(tokenId);
    return ITRMeta(core.metadataAddress).getElement(core);
  }

  /// @notice Spell of Divination: Relic Traits - Color Count
  /// @dev Identifies the colors trait of a given relic.
  ///      On the surface, this is the number of colors within a relic's palette. Going deeper,
  ///      each color is a sort of elemental nucleus within the relic's structure, exerting
  ///      vibrational gravity throughout.
  /// @param tokenId The relic to be studied.
  function getColorCount(uint256 tokenId)
    public
    view
    returns (uint256)
  {
    TRKeys.RuneCore memory core = getRuneCore(tokenId);
    return ITRMeta(core.metadataAddress).getColorCount(core);
  }

  /// @notice Spell of Divination: Colors
  /// @dev Fetch the hex code for a specific color of a given relic, between 000000 and ffffff.
  ///      It's very rare to see two relics with the exact same palette, if ever at all.
  ///      This is due to subtle variations in the vibrational forces of aether.
  /// @param tokenId The relic to be queried.
  /// @param index The index of the color sought, inclusive between 0 and colors - 1.
  function getColorByIndex(uint256 tokenId, uint256 index)
    public
    view
    returns (string memory)
  {
    TRKeys.RuneCore memory core = getRuneCore(tokenId);
    return ITRMeta(core.metadataAddress).getColorByIndex(core, index);
  }

  /// @notice Spell of Divination: Grails
  /// @dev The legend of the Queen's Grails? A tale as old as time ...
  ///      The Queen was once a goddess, the first elemental of Light, and hailed by scholars as
  ///      the original muse. She crafted the most magnificent set of grails, divine artifacts
  ///      that were impossibly beautiful, unbreakable, and immutable. To behold them was to be
  ///      enlightened - to see the universe as a beautiful sparkling globe, frozen in all times
  ///      at once, speckled with brilliance and grandeur, all connected, all now, time itself
  ///      but an illusion. The other gods, fearful of mortals obtaining such a perspective,
  ///      wrapped her grails in powerful magic, shrouding them in obscurity. They were
  ///      unrecognizable, but the Queen was cunning; she wanted her creations to inspire.
  ///      She hid the grails amongst a gift of relics, which the other gods proudly bestowed
  ///      upon the kingdom of man. It was only afterwards that the God of Shadow discovered
  ///      her trick. What happened next is a story for another time, but suffice to say, this
  ///      was the spark that ignited the Celestial Wars, spanning the heavens and the earth.
  /// @param tokenId The relic to be inspected. If 0 is returned, then that relic is not a grail;
  ///                divine magic is powerful, and until we can dispel it, we truly don't know.
  function getGrailId(uint256 tokenId)
    public
    view
    returns (uint256)
  {
    TRKeys.RuneCore memory core = getRuneCore(tokenId);
    return ITRMeta(core.metadataAddress).getGrailId(core);
  }

  /// @notice Spell of Mathematics: Definition
  /// @dev Obtain the designs to recreate any relic from pure math and logic;
  ///      conjure a stunning visualization, afloat in the air before you.
  ///      You can have it all here, in red, blue, green.
  /// @param tokenId The relic to be conjured.
  function tokenScript(uint256 tokenId)
    public
    view
    returns (string memory)
  {
    TRKeys.RuneCore memory core = getRuneCore(tokenId);
    return ITRMeta(core.metadataAddress).tokenScript(core);
  }

  /// @notice Spell of Mathematics: Universal Runic Identifier
  /// @dev Blast enough Arcane magic through runic circuits, and you've got what arcanists call,
  ///      "data." This spell helps identify all of the key traits belonging to a particular relic.
  /// @param tokenId The relic to be identified.
  function tokenURI(uint256 tokenId)
    override
    public
    view
    returns (string memory)
  {
    TRKeys.RuneCore memory core = getRuneCore(tokenId);
    return ITRMeta(core.metadataAddress).tokenURI(core);
  }

  /// @notice Spell of Divination: Rune Core
  /// @dev Use this spell to isolate and analyze the runic nucleus of a relic. Understanding the
  ///      properties of a Rune Core is like knowing the seed of a flower, its entire life
  ///      blossoms before you in an instant.
  /// @param tokenId The relic to be analyzed.
  function getRuneCore(uint256 tokenId)
    public
    view
    prohibitBlasphemy(tokenId)
    returns (TRKeys.RuneCore memory)
  {
    // DEV: A RuneCore contains all the data stored on-chain for a given relic.
    TRKeys.RuneCore memory core;
    core.tokenId = tokenId;
    core.level = getLevel(tokenId);
    core.mana = getMana(tokenId);
    core.runeCode = getRuneCode(tokenId);
    core.runeHash = getRuneHash(tokenId);
    core.metadataAddress = getMetadataAddress(tokenId);
    core.isDivinityQuestLoot = relics[tokenId].isDivinityQuestLoot;
    core.isSecretDiscovered = relics[tokenId].isSecretDiscovered;
    core.secretsDiscovered = reliquary.secretsDiscovered;
    core.hiddenLeyLines = reliquary.hiddenLeyLines;
    core.transmutation = relics[tokenId].transmutation;
    core.colors = relics[tokenId].colors;

    // DEV: SSTORE2 significantly reduces the gas costs of glyph creation.
    if (relics[tokenId].glyph != address(0)) {
      (address credit, uint256[] memory glyph) = abi.decode(
        SSTORE2.read(relics[tokenId].glyph),
        (address, uint256[])
      );

      core.credit = credit;
      core.glyph = glyph;
    }
    return core;
  }

  /// @notice Spell of Aether: Rune Code
  /// @dev Relics are infused with the elements, and as such, we can view the shape of the
  ///      underlying aether by reading the physical effects on runic circuits. Each vibration
  ///      can be encoded into data, and when a relic is forged, the vibrations of the aether
  ///      forever leave their mark. The Rune Code is that unique aetheric stamp, a window
  ///      into the past; its time and its news, all captured for the Queen to use. The chance
  ///      of two relics sharing a Rune Code is just shy of impossible.
  /// @param tokenId The relic to be deciphered.
  function getRuneCode(uint256 tokenId)
    public
    view
    returns (uint256)
  {
    // DEV: Follow the ERC721A pattern, but for random blockhashes (one per mint batch).
    uint256 hashIndex;
    bytes32 entropy = relics[tokenId].runeHash;
    while (entropy == bytes32(0)) {
      ++hashIndex;
      entropy = relics[++tokenId].runeHash;
    }

    // DEV: Split each blockhash into even pieces, indexed by mint order in a batch.
    uint256 start = hashIndex * TRKeys.BYTES_PER_RELICHASH;
    uint256 end = TRKeys.BYTES_PER_BLOCKHASH;
    uint256 shift = (end - TRKeys.BYTES_PER_RELICHASH) - start;
    bytes32 finalHash = bytes32((entropy >> shift * 8) & TRKeys.RELICHASH_MASK);
    uint256 runeCode = uint256(finalHash);

    // DEV: Minimize potential hash collisions, while preventing overflow or underflow.
    if (runeCode >= TRKeys.HALF_POSSIBILITY_SPACE) {
      runeCode -= tokenId;
    } else {
      runeCode += tokenId;
    }
    return runeCode;
  }

  /// @notice Spell of Aether: Rune Hash
  /// @dev A Rune Hash is a human readable reinterpretation of a Rune Code. These are most often
  ///      used as a sort of aetheric name to tell relics apart.
  /// @param tokenId The relic to be named.
  function getRuneHash(uint256 tokenId)
    public
    view
    returns (string memory)
  {
    return getRuneCode(tokenId).toHexString(TRKeys.BYTES_PER_RELICHASH);
  }

  /// @notice Spell of Aether: Vibrations
  /// @dev These are the aetheric vibrations wrapped up and forever imprinted upon a relic as
  ///      it's forged.
  /// @param tokenId The relic being forged.
  function getAethericVibrations(uint256 tokenId)
    private
    view
    returns (bytes32)
  {
    // DEV: Minimize collisions by moving our index in the opposite direction of hashes.
    uint256 decrement = 1 + 255 % (block.number - 1);
    uint256 increment = tokenId % decrement;
    uint256 blockIndex = block.number - decrement + increment;
    return blockhash(blockIndex);
  }

  /// @notice Claim Relic(s)
  /// @dev Root, ransack, and raid for random relics from within the reliquary!
  ///      Mind you, this is a holy place, and a tithe is due if you'd like to escape in one piece.
  ///      A minimum of 0.15 aether per relic is required. If you've got vibes currently in your
  ///      possession, try "mintWithVibesDiscount" first for a lesser tithe.
  /// @param mintCount The number of relics to claim. Limit 10 per transaction.
  function mint(uint256 mintCount)
    public
    payable
    nonReentrant
    prohibitTimeTravel
    prohibitAdvancedSpellcasting
    enforceInventoryLimits(mintCount)
    enforceAbsoluteScarcity(mintCount)
  {
    // Relics are divine in nature; a worthy tithe is strongly recommended.
    if (msg.value < TRKeys.RELIC_TITHE * mintCount) revert NotEnoughAether();

    _mintRelics(mintCount);
  }

  /// @notice Claim Relic(s) with Aether from Vibes
  /// @dev By channeling the innate aether within vibes, one can significantly reduce the
  ///      tithe. A minimum of 0.15 aether per relic is required, but each [genesis] vibe holds
  ///      0.12, while each [open] vibe holds 0.05, greatly reducing the overall cost. Vibes are
  ///      not burned or affected in the process, though once channeled, the same vibes cannot be
  ///      used for discounts again. Any excess aether will be stored and counted towards
  ///      any additional relics you claim. Please calculate your tithe with care, use
  ///      "calculateVibesDiscount" or visit https://vibes.art/ for an automated experience.
  /// @param mintCount The number of relics to claim. Limit 10 per transaction.
  function mintWithVibesDiscount(uint256 mintCount)
    public
    payable
    nonReentrant
    prohibitTimeTravel
    prohibitAdvancedSpellcasting
    enforceInventoryLimits(mintCount)
    enforceAbsoluteScarcity(mintCount)
  {
    uint256 discountGenesis = _channelVibesAether(TRKeys.VIBES_GENESIS, TRKeys.RELIC_DISCOUNT_GENESIS);
    uint256 discountOpen = _channelVibesAether(TRKeys.VIBES_OPEN, TRKeys.RELIC_DISCOUNT_OPEN);
    uint256 discountTotal = adventurers[_msgSender()].aether + discountGenesis + discountOpen;

    // Your aether shall not be wasted; use the "mint" method, instead.
    if (discountTotal == 0) revert NoAetherRemainingUseMintInstead();

    uint256 tithe = TRKeys.RELIC_TITHE * mintCount;
    if (tithe >= discountTotal) {
      tithe -= discountTotal;
      discountTotal = 0;
    } else {
      discountTotal -= tithe;
      tithe = 0;
    }

    // Even with the elemental power of vibes, a worthy tithe is still required.
    if (msg.value < tithe) revert NotEnoughAether();

    adventurers[_msgSender()].aether = discountTotal;
    _mintRelics(mintCount);
  }

  /// @notice Channel Aether from Vibes into an Adventurer's Tithe
  /// @dev This claims discounts for all vibes currently in your possession. Adding new vibes
  ///      that haven't been used will accrue additional discounts. Excess discounts are saved
  ///      and applied towards future relics. Discounts do not apply to the Divinity Quest.
  /// @param discountAddress The vibes contract to check for ownership.
  /// @param discountAmount The discount value per vibe to be claimed.
  function _channelVibesAether(address discountAddress, uint256 discountAmount)
    private
    returns (uint256)
  {
    Vibes discountContract = Vibes(discountAddress);
    uint256 tokenCount = discountContract.balanceOf(_msgSender());
    uint256 discountClaimed;
    for (uint256 i; i < tokenCount; i++) {
      uint256 tokenId = discountContract.tokenOfOwnerByIndex(_msgSender(), i);
      if (!vibesAetherChanneled[tokenId]) {
        vibesAetherChanneled[tokenId] = true;
        discountClaimed += discountAmount;
      }
    }
    return discountClaimed;
  }

  /// @notice Calculate the Discount from Vibes in this Wallet
  /// @dev A read-only measurement of aether stored in vibes.
  ///      Divide the result by 1000000000000000000 (18 zeroes) to convert to ETH.
  function calculateVibesDiscount()
    public
    view
    returns (uint256)
  {
    uint256 discountGenesis = _measureVibesAether(TRKeys.VIBES_GENESIS, TRKeys.RELIC_DISCOUNT_GENESIS);
    uint256 discountOpen = _measureVibesAether(TRKeys.VIBES_OPEN, TRKeys.RELIC_DISCOUNT_OPEN);
    return adventurers[_msgSender()].aether + discountGenesis + discountOpen;
  }

  /// @notice Measure Available Aether from Vibes
  /// @dev A read-only measurement of available aether.
  /// @param discountAddress The vibes contract to check for ownership.
  /// @param discountAmount The discount value per vibe.
  function _measureVibesAether(address discountAddress, uint256 discountAmount)
    private
    view
    returns (uint256)
  {
    Vibes discountContract = Vibes(discountAddress);
    uint256 tokenCount = discountContract.balanceOf(_msgSender());
    uint256 discountAvailable;
    for (uint256 i; i < tokenCount; i++) {
      uint256 tokenId = discountContract.tokenOfOwnerByIndex(_msgSender(), i);
      if (!vibesAetherChanneled[tokenId]) {
        discountAvailable += discountAmount;
      }
    }
    return discountAvailable;
  }

  /// @notice Claim Divine Curio
  /// @dev This action is only accessible to adventurers who have completed the Divinity Quest.
  function _mintDivineCurio()
    private
  {
    _safeMint(_msgSender(), 1);
    uint256 lastTokenId = totalSupply();
    relics[lastTokenId].runeHash = getAethericVibrations(lastTokenId);
    relics[lastTokenId].mana += TRKeys.MANA_FROM_REVELATION;
    relics[lastTokenId].isDivinityQuestLoot = true;
    reliquary.curiosDiscovered++;
  }

  /// @notice Claim Relic(s)
  /// @dev This action is for internal use only; see "mint" and "mintWithVibesDiscount."
  function _mintRelics(uint256 mintCount)
    private
  {
    _safeMint(_msgSender(), mintCount);
    uint256 lastTokenId = totalSupply();
    relics[lastTokenId].runeHash = getAethericVibrations(lastTokenId);
  }

  /// @notice Burn a Vibe
  /// @dev Lock a vibe within this contract forever,
  ///      effectively burning it while preserving the art.
  ///      Vibes are used in this way to modify and customize relics.
  function _lockVibeForever(uint256 vibeId, uint256 tokenId)
    private
  {
    Vibes vibesContract;
    if (vibeId < TRKeys.FIRST_OPEN_VIBES_ID) {
      vibesContract = Vibes(TRKeys.VIBES_GENESIS);
    } else {
      vibesContract = Vibes(TRKeys.VIBES_OPEN);
    }
    vibesContract.transferFrom(_msgSender(), address(this), vibeId);
    relics[tokenId].mana += TRKeys.MANA_FROM_VIBRATION;
  }

  /// @notice Mana Loss
  /// @dev The ancient runic circuits of relics are extremely fragile! When a relic is transferred,
  ///      any stored mana is reduced by half in the process. Please move, buy, and sell relics
  ///      with care. There are no warranties for divine artifacts lost to the seas of time.
  function _disturbMana(uint256 tokenId)
    private
  {
    uint32 mana = getMana(tokenId);
    if (mana > 0) {
      relics[tokenId].mana = mana / 2;
    }
  }

  /// @notice See _disturbMana
  function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity)
    internal
    override
  {
    super._beforeTokenTransfers(from, to, startTokenId, quantity);
    // DEV: Save gas and skip mint transactions, because mana always starts at 0.
    if (from != address(0)) {
      // DEV: Quantity is always 1 except in a mint transaction, so we can safely ignore
      //      iterating over other relics that may have been minted in an ERC721A batch.
      _disturbMana(startTokenId);
    }
  }

  /// @notice Full Customization
  /// @dev Use "safeTransferFrom" in [genesis] or [open] vibes contracts to send a single vibe to
  ///      this contract's address, for a single transaction to fully customize a relic.
  ///      This is the most vibe-efficient and gas-efficient way for a full customization, but
  ///      it generates less mana than performing each spell separately and burning more vibes.
  /// @param operator The wallet initiating the transaction, to be given creative credit. This will
  ///                 be passed automatically by the vibes contracts.
  /// @param data Encoded bytes in the format (uint256, string, uint256[], uint24[]), in order:
  ///             uint256 targetTokenId - the tokenId of the relic to be customized,
  ///             string element - transmute to this new element, empty string for no effect,
  ///             uint256[] glyph - a new glyph to etch onto the relic, empty array for no effect,
  ///             uint24[] colors - a reimagined color palette, empty array for no effect.
  ///             See the individual customization methods for further documentation.
  function onERC721Received(address operator, address, uint256, bytes memory data)
    public
    override
    prohibitTimeTravel
    returns (bytes4)
  {
    if (_msgSender() != TRKeys.VIBES_GENESIS && _msgSender() != TRKeys.VIBES_OPEN) {
      revert OnlyBurnsVibes();
    }

    uint256 targetTokenId;
    string memory element;
    uint256[] memory glyph;
    uint24[] memory colors;
    bool success = false;

    (targetTokenId, element, glyph, colors) = abi.decode(
      data, (uint256, string, uint256[], uint24[]));

    if (bytes(element).length > 0) {
      _transmuteElement(targetTokenId, element);
      success = true;
    }

    if (glyph.length > 0) {
      _createGlyph(targetTokenId, glyph, operator);
      success = true;
    }

    if (colors.length > 0) {
      _imagineColors(targetTokenId, colors);
      success = true;
    }

    if (!success) revert InvalidCustomization();

    relics[targetTokenId].mana += TRKeys.MANA_FROM_VIBRATION;
    emit RelicUpdate(targetTokenId);
    return this.onERC721Received.selector;
  }

  /// @notice Withdraw aether to contract owner.
  function withdrawAether()
    public
    onlyOwner
  {
    (bool success,) = owner().call{ value: address(this).balance }('');
    require(success);
  }
}

/// @notice This abstract contract matches both the [genesis] and [open] vibes contracts.
///         Mint vibes and learn more about the project at https://vibes.art/
abstract contract Vibes {
  function balanceOf(address owner) external view virtual returns (uint256 balance);
  function ownerOf(uint256 tokenId) external view virtual returns (address);
  function getApproved(uint256 tokenId) public view virtual returns (address);
  function isApprovedForAll(address owner, address operator) public view virtual returns (bool);
  function transferFrom(address from, address to, uint256 tokenId) public virtual;
  function tokenOfOwnerByIndex(address owner, uint256 index) external view virtual returns (uint256 tokenId);
}

/*
  Dear Reader,

    Thank you for participating in this experience and for allowing me to use the circuits of your
  imagination. This project is presented without promises or obligations. Where we go from here
  is anyone's guess. I would be honored to receive your presence and thoughts.

    - remnynt
    DjhEVKnKW6
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./utils/Bytecode.sol";

/**
  @title A key-value storage with auto-generated keys for storing chunks of data with a lower write & read cost.
  @author Agustin Aguilar <[email protected]>

  Readme: https://github.com/0xsequence/sstore2#readme
*/
library SSTORE2 {
  error WriteError();

  /**
    @notice Stores `_data` and returns `pointer` as key for later retrieval
    @dev The pointer is a contract address with `_data` as code
    @param _data to be written
    @return pointer Pointer to the written `_data`
  */
  function write(bytes memory _data) internal returns (address pointer) {
    // Append 00 to _data so contract can't be called
    // Build init code
    bytes memory code = Bytecode.creationCodeFor(
      abi.encodePacked(
        hex'00',
        _data
      )
    );

    // Deploy contract using create
    assembly { pointer := create(0, add(code, 32), mload(code)) }

    // Address MUST be non-zero
    if (pointer == address(0)) revert WriteError();
  }

  /**
    @notice Reads the contents of the `_pointer` code as data, skips the first byte 
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @return data read from `_pointer` contract
  */
  function read(address _pointer) internal view returns (bytes memory) {
    return Bytecode.codeAt(_pointer, 1, type(uint256).max);
  }

  /**
    @notice Reads the contents of the `_pointer` code as data, skips the first byte 
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @param _start number of bytes to skip
    @return data read from `_pointer` contract
  */
  function read(address _pointer, uint256 _start) internal view returns (bytes memory) {
    return Bytecode.codeAt(_pointer, _start + 1, type(uint256).max);
  }

  /**
    @notice Reads the contents of the `_pointer` code as data, skips the first byte 
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @param _start number of bytes to skip
    @param _end index before which to end extraction
    @return data read from `_pointer` contract
  */
  function read(address _pointer, uint256 _start, uint256 _end) internal view returns (bytes memory) {
    return Bytecode.codeAt(_pointer, _start + 1, _end + 1);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.4;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

/// @notice ERC721ATM
/// @dev ERC721A + Trustless Metadata
///      An extension built on ERC721A v3.0.0 with trustless metadata upgrades.
///      ~ upgradable: contract owner can add new metadata contracts,
///                    all tokens use the most recent by default.
///      ~ immutable: token holders can opt-out of metadata updates by
///                   overriding tokens they hold to use any previously set metadata contract.
abstract contract ERC721ATM is ERC721A, Ownable {
  /// allow for new metadata contracts but keep those previously used,
  /// the last entry in the list is the current metadata contract
  address[] public metadataAddressList;

  /// allow for token holders to opt-out of metadata contract updates
  mapping(uint256 => uint256) public metadataOverrides;

  error MissingMetadata();
  error MetadataNumberTooLow();
  error MetadataNumberTooHigh();
  error NotMetadataApprovedOrOwner();

  constructor(string memory name_, string memory symbol_) ERC721A(name_, symbol_) Ownable() {}

  function _startTokenId() override internal pure virtual returns (uint256) {
    return 1;
  }

  /// @notice update the collection to a new default metadata contract
  /// @param addr the address of the new metadata contract to use
  function setMetadataAddress(address addr) public virtual onlyOwner {
    metadataAddressList.push(addr);
  }

  /// @notice returns the metadata contract address for a given tokenId
  /// @param tokenId the token to check
  /// @return a metadata contract address override or the most recent set
  function getMetadataAddress(uint256 tokenId) public view virtual returns (address) {
    uint256 metadataNumber = metadataAddressList.length;
    if (metadataNumber == 0) revert MissingMetadata();

    uint256 metadataOverride = metadataOverrides[tokenId];
    if (metadataOverride > 0) {
      metadataNumber = metadataOverride;
    }

    return metadataAddressList[metadataNumber - 1];
  }

  /// @notice opt-out of updates for this token, setting to any previously used metadata contract
  /// @param tokenId the token that will have its metadata overridden
  /// @param metadataNumber the metadata contract to use (index in metadataAddressList + 1)
  function setMetadataNumber(uint256 tokenId, uint256 metadataNumber) public virtual {
    uint256 addressCount = metadataAddressList.length;
    if (metadataNumber == 0) revert MetadataNumberTooLow();
    if (metadataNumber > addressCount) revert MetadataNumberTooHigh();
    if (!isApprovedOrOwnerOf(tokenId)) revert NotMetadataApprovedOrOwner();

    metadataOverrides[tokenId] = metadataNumber;
  }

  /// @notice clear override and opt-in to metadata updates for this token
  /// @param tokenId the token that will have its metadata overridden
  function clearMetadataNumber(uint256 tokenId) public virtual {
    if (!isApprovedOrOwnerOf(tokenId)) revert NotMetadataApprovedOrOwner();

    metadataOverrides[tokenId] = 0;
  }

  /// @dev returns whether `_msgSender()` is allowed to manage `tokenId`
  /// @param tokenId the token to check
  function isApprovedOrOwnerOf(uint256 tokenId) internal view virtual returns (bool) {
    address owner = ownerOf(tokenId);
    return _msgSender() == owner
      || _msgSender() == getApproved(tokenId)
      || isApprovedForAll(owner, _msgSender());
  }

}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import './Base64.sol';
import './TRScript.sol';
import './TRRolls.sol';

interface ITRMeta {

  function tokenURI(TRKeys.RuneCore memory core) external view returns (string memory);
  function tokenScript(TRKeys.RuneCore memory core) external view returns (string memory);
  function getElement(TRKeys.RuneCore memory core) external view returns (string memory);
  function getColorCount(TRKeys.RuneCore memory core) external view returns (uint256);
  function getColorByIndex(TRKeys.RuneCore memory core, uint256 index) external view returns (string memory);
  function getGrailId(TRKeys.RuneCore memory core) external view returns (uint256);
  function getMaxRelicLevel() external pure returns (uint8);

}

/// @notice The Reliquary Metadata v1
contract TRMeta is Ownable, ITRMeta {

  using Strings for uint256;

  string public imageURL = 'https://vibes.art/reliquary/png/';
  string public imageSuffix = '.png';
  string public animationURL = 'https://vibes.art/reliquary/html/';
  string public animationSuffix = '.html';
  address public rollsContract;
  mapping(string => string) public descriptionsByElement;
  mapping(string => string) public descriptionsByEssence;

  error RollsAreImmutable();

  constructor() Ownable() {}

  function tokenURI(TRKeys.RuneCore memory core)
    override
    external
    view
    returns (string memory)
  {
    TRRolls.RelicInfo memory info = ITRRolls(rollsContract).getRelicInfo(core);

    string memory json = string(abi.encodePacked(
      '{"name": "Relic 0x', TRUtils.toCapsHexString(core.runeCode),
      '", "description": "', tokenDescription(core, info),
      '", "image": "', tokenImage(core),
      '", "animation_url": "', tokenAnimation(core),
      '", "attributes": [{ "trait_type": "Element", "value": "', info.element
    ));

    json = string(abi.encodePacked(
      json,
      '" }, { "trait_type": "Type", "value": "', info.relicType,
      '" }, { "trait_type": "Essence", "value": "', info.essence,
      '" }, { "trait_type": "Palette", "value": "', info.palette,
      '" }, { "trait_type": "Style", "value": "', info.style
    ));

    json = string(abi.encodePacked(
      json,
      '" }, { "trait_type": "Speed", "value": "', info.speed,
      '" }, { "trait_type": "Glyph", "value": "', info.glyphType,
      '" }, { "trait_type": "Colors", "value": "', TRUtils.toString(info.colorCount),
      '" }, { "trait_type": "Level", "value": ', TRUtils.toString(core.level)
    ));

    json = string(abi.encodePacked(
      json,
      ' }, { "trait_type": "Mana", "value": ', TRUtils.toString(core.mana),
      ' }], "hidden": [{ "trait_type": "Runeflux", "value": ', TRUtils.toString(info.runeflux),
      ' }, { "trait_type": "Corruption", "value": ', TRUtils.toString(info.corruption),
      ' }, { "trait_type": "Grail", "value": ', TRUtils.toString(info.grailId),
      ' }]}'
    ));

    return string(abi.encodePacked(
      'data:application/json;base64,', Base64.encode(bytes(json))
    ));
  }

  function tokenScript(TRKeys.RuneCore memory core)
    override
    public
    view
    returns (string memory)
  {
    TRRolls.RelicInfo memory info = ITRRolls(rollsContract).getRelicInfo(core);
    string[] memory html = new string[](19);
    uint256[] memory glyph = core.glyph;

    if (info.grailId != TRKeys.GRAIL_ID_NONE) {
      glyph = info.grailGlyph;
    }

    html[0] = '<!doctype html><html><head><script>';
    html[1] = string(abi.encodePacked('var H="', core.runeHash, '";'));
    html[2] = string(abi.encodePacked('var N="', info.essence, '";'));
    html[3] = string(abi.encodePacked('var Y="', info.style, '";'));
    html[4] = string(abi.encodePacked('var E="', info.speed, '";'));
    html[5] = string(abi.encodePacked('var G="', info.gravity, '";'));
    html[6] = string(abi.encodePacked('var D="', info.display, '";'));
    html[7] = string(abi.encodePacked('var V=', TRUtils.toString(core.level), ';'));
    html[8] = string(abi.encodePacked('var F=', TRUtils.toString(info.runeflux), ';'));
    html[9] = string(abi.encodePacked('var C=', TRUtils.toString(info.corruption), ';'));

    string memory itemString;
    string memory partString;
    uint256 i;
    for (; i < TRKeys.RELIC_SIZE; i++) {
      if (i < glyph.length) {
        itemString = glyph[i].toString();
      } else {
        itemString = '0';
      }

      while (bytes(itemString).length < TRKeys.RELIC_SIZE) {
        itemString = string(abi.encodePacked('0', itemString));
      }

      if (i == 0) {
        itemString = string(abi.encodePacked('var L=["', itemString, '",'));
      } else if (i < TRKeys.RELIC_SIZE - 1) {
        itemString = string(abi.encodePacked('"', itemString, '",'));
      } else {
        itemString = string(abi.encodePacked('"', itemString, '"];'));
      }

      partString = string(abi.encodePacked(partString, itemString));
    }

    html[10] = partString;

    for (i = 0; i < 6; i++) {
      if (i < info.colorCount) {
        itemString = ITRRolls(rollsContract).getColorByIndex(core, i);
      } else {
        itemString = '';
      }

      if (i == 0) {
        partString = string(abi.encodePacked('var P=["', itemString, '",'));
      } else if (i < info.colorCount - 1) {
        partString = string(abi.encodePacked('"', itemString, '",'));
      } else if (i < info.colorCount) {
        partString = string(abi.encodePacked('"', itemString, '"];'));
      } else {
        partString = '';
      }

      html[11 + i] = partString;
    }

    html[17] = getScript();
    html[18] = '</script></head><body></body></html>';

    string memory output = string(abi.encodePacked(
      html[0], html[1], html[2], html[3], html[4], html[5], html[6], html[7], html[8]
    ));

    output = string(abi.encodePacked(
      output, html[9], html[10], html[11], html[12], html[13], html[14], html[15], html[16]
    ));

    return string(abi.encodePacked(
      output, html[17], html[18]
    ));
  }

  function tokenDescription(TRKeys.RuneCore memory core, TRRolls.RelicInfo memory info)
    public
    view
    returns (string memory)
  {
    string memory desc = string(abi.encodePacked(
      'Relic 0x', TRUtils.toCapsHexString(core.runeCode),
      '\\n\\n', info.essence, ' ', info.relicType, ' of ', info.element
    ));

    desc = string(abi.encodePacked(
      desc,
      '\\n\\nLevel: ', TRUtils.toString(core.level),
      '\\n\\nMana: ', TRUtils.toString(core.mana),
      '\\n\\nRuneflux: ', TRUtils.toString(info.runeflux),
      '\\n\\nCorruption: ', TRUtils.toString(info.corruption)
    ));

    if (core.credit != address(0)) {
      desc = string(abi.encodePacked(desc, '\\n\\nGlyph by: 0x', TRUtils.toAsciiString(core.credit)));
    }

    string memory additionalInfo = ITRRolls(rollsContract).getDescription(core);
    if (bytes(additionalInfo).length > 0) {
      desc = string(abi.encodePacked(desc, '\\n\\n', additionalInfo));
    }

    if (bytes(descriptionsByElement[info.element]).length > 0) {
      desc = string(abi.encodePacked(desc, '\\n\\n', descriptionsByElement[info.element]));
    }

    if (bytes(descriptionsByEssence[info.essence]).length > 0) {
      desc = string(abi.encodePacked(desc, '\\n\\n', descriptionsByEssence[info.essence]));
    }

    return desc;
  }

  function tokenImage(TRKeys.RuneCore memory core) public view returns (string memory) {
    if (bytes(imageSuffix).length > 0) {
      return string(abi.encodePacked(imageURL, TRUtils.toString(core.tokenId), imageSuffix));
    } else {
      return string(abi.encodePacked(imageURL, TRUtils.toString(core.tokenId)));
    }
  }

  function tokenAnimation(TRKeys.RuneCore memory core) public view returns (string memory) {
    if (bytes(animationURL).length == 0) {
      return string(abi.encodePacked(
        'data:text/html;base64,', Base64.encode(bytes(tokenScript(core)))
      ));
    } else {
      if (bytes(animationSuffix).length > 0) {
        return string(abi.encodePacked(animationURL, TRUtils.toString(core.tokenId), animationSuffix));
      } else {
        return string(abi.encodePacked(animationURL, TRUtils.toString(core.tokenId)));
      }
    }
  }

  function getElement(TRKeys.RuneCore memory core) override public view returns (string memory) {
    return ITRRolls(rollsContract).getElement(core);
  }

  function getPalette(TRKeys.RuneCore memory core) public view returns (string memory) {
    return ITRRolls(rollsContract).getPalette(core);
  }

  function getEssence(TRKeys.RuneCore memory core) public view returns (string memory) {
    return ITRRolls(rollsContract).getEssence(core);
  }

  function getStyle(TRKeys.RuneCore memory core) public view returns (string memory) {
    return ITRRolls(rollsContract).getStyle(core);
  }

  function getSpeed(TRKeys.RuneCore memory core) public view returns (string memory) {
    return ITRRolls(rollsContract).getSpeed(core);
  }

  function getGravity(TRKeys.RuneCore memory core) public view returns (string memory) {
    return ITRRolls(rollsContract).getGravity(core);
  }

  function getDisplay(TRKeys.RuneCore memory core) public view returns (string memory) {
    return ITRRolls(rollsContract).getDisplay(core);
  }

  function getColorCount(TRKeys.RuneCore memory core) override public view returns (uint256) {
    return ITRRolls(rollsContract).getColorCount(core);
  }

  function getColorByIndex(TRKeys.RuneCore memory core, uint256 index)
    override
    public
    view
    returns (string memory)
  {
    return ITRRolls(rollsContract).getColorByIndex(core, index);
  }

  function getRelicType(TRKeys.RuneCore memory core) public view returns (string memory) {
    return ITRRolls(rollsContract).getRelicType(core);
  }

  function getRuneflux(TRKeys.RuneCore memory core) public view returns (uint256) {
    return ITRRolls(rollsContract).getRuneflux(core);
  }

  function getCorruption(TRKeys.RuneCore memory core) public view returns (uint256) {
    return ITRRolls(rollsContract).getCorruption(core);
  }

  function getGrailId(TRKeys.RuneCore memory core) override public view returns (uint256) {
    return ITRRolls(rollsContract).getGrailId(core);
  }

  function getMaxRelicLevel() override public pure returns (uint8) {
    return 2;
  }

  function getScript() public pure returns (string memory) {
    return TRScript.getScript();
  }

  function setDescriptionForElement(string memory element, string memory desc) public onlyOwner {
    descriptionsByElement[element] = desc;
  }

  function setDescriptionForEssence(string memory essence, string memory desc) public onlyOwner {
    descriptionsByEssence[essence] = desc;
  }

  function setImageURL(string memory url) public onlyOwner {
    imageURL = url;
  }

  function setImageSuffix(string memory suffix) public onlyOwner {
    imageSuffix = suffix;
  }

  function setAnimationURL(string memory url) public onlyOwner {
    animationURL = url;
  }

  function setAnimationSuffix(string memory suffix) public onlyOwner {
    animationSuffix = suffix;
  }

  function setRollsContract(address rolls) public onlyOwner {
    if (rollsContract != address(0)) revert RollsAreImmutable();

    rollsContract = rolls;
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


library Bytecode {
  error InvalidCodeAtRange(uint256 _size, uint256 _start, uint256 _end);

  /**
    @notice Generate a creation code that results on a contract with `_code` as bytecode
    @param _code The returning value of the resulting `creationCode`
    @return creationCode (constructor) for new contract
  */
  function creationCodeFor(bytes memory _code) internal pure returns (bytes memory) {
    /*
      0x00    0x63         0x63XXXXXX  PUSH4 _code.length  size
      0x01    0x80         0x80        DUP1                size size
      0x02    0x60         0x600e      PUSH1 14            14 size size
      0x03    0x60         0x6000      PUSH1 00            0 14 size size
      0x04    0x39         0x39        CODECOPY            size
      0x05    0x60         0x6000      PUSH1 00            0 size
      0x06    0xf3         0xf3        RETURN
      <CODE>
    */

    return abi.encodePacked(
      hex"63",
      uint32(_code.length),
      hex"80_60_0E_60_00_39_60_00_F3",
      _code
    );
  }

  /**
    @notice Returns the size of the code on a given address
    @param _addr Address that may or may not contain code
    @return size of the code on the given `_addr`
  */
  function codeSize(address _addr) internal view returns (uint256 size) {
    assembly { size := extcodesize(_addr) }
  }

  /**
    @notice Returns the code of a given address
    @dev It will fail if `_end < _start`
    @param _addr Address that may or may not contain code
    @param _start number of bytes of code to skip on read
    @param _end index before which to end extraction
    @return oCode read from `_addr` deployed bytecode

    Forked from: https://gist.github.com/KardanovIR/fe98661df9338c842b4a30306d507fbd
  */
  function codeAt(address _addr, uint256 _start, uint256 _end) internal view returns (bytes memory oCode) {
    uint256 csize = codeSize(_addr);
    if (csize == 0) return bytes("");

    if (_start > csize) return bytes("");
    if (_end < _start) revert InvalidCodeAtRange(csize, _start, _end); 

    unchecked {
      uint256 reqSize = _end - _start;
      uint256 maxSize = csize - _start;

      uint256 size = maxSize < reqSize ? maxSize : reqSize;

      assembly {
        // allocate output byte array - this could also be done without assembly
        // by using o_code = new bytes(size)
        oCode := mload(0x40)
        // new "memory end" including padding
        mstore(0x40, add(oCode, and(add(add(size, 0x20), 0x1f), not(0x1f))))
        // store length in memory
        mstore(oCode, size)
        // actually retrieve the code, this needs assembly
        extcodecopy(_addr, add(oCode, 0x20), _start, size)
      }
    }
  }
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
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

error ApprovalCallerNotOwnerNorApproved();
error ApprovalQueryForNonexistentToken();
error ApproveToCaller();
error ApprovalToCurrentOwner();
error BalanceQueryForZeroAddress();
error MintedQueryForZeroAddress();
error BurnedQueryForZeroAddress();
error AuxQueryForZeroAddress();
error MintToZeroAddress();
error MintZeroQuantity();
error OwnerIndexOutOfBounds();
error OwnerQueryForNonexistentToken();
error TokenIndexOutOfBounds();
error TransferCallerNotOwnerNorApproved();
error TransferFromIncorrectOwner();
error TransferToNonERC721ReceiverImplementer();
error TransferToZeroAddress();
error URIQueryForNonexistentToken();

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at _startTokenId() (defaults to 0, e.g. 0, 1, 2, 3..).
 *
 * Assumes that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 *
 * Assumes that the maximum token id cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Compiler will pack this into a single 256bit word.
    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
    }

    // Compiler will pack this into a single 256bit word.
    struct AddressData {
        // Realistically, 2**64-1 is more than enough.
        uint64 balance;
        // Keeps track of mint count with minimal overhead for tokenomics.
        uint64 numberMinted;
        // Keeps track of burn count with minimal overhead for tokenomics.
        uint64 numberBurned;
        // For miscellaneous variable(s) pertaining to the address
        // (e.g. number of whitelist mint slots used).
        // If there are multiple variables, please pack them into a uint64.
        uint64 aux;
    }

    // The tokenId of the next token to be minted.
    uint256 internal _currentIndex;

    // The number of tokens burned.
    uint256 internal _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned. See ownershipOf implementation for details.
    mapping(uint256 => TokenOwnership) internal _ownerships;

    // Mapping owner address to address data
    mapping(address => AddressData) private _addressData;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    /**
     * To change the starting tokenId, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     * @dev Burned tokens are calculated here, use _totalMinted() if you want to count just minted tokens.
     */
    function totalSupply() public view returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than _currentIndex - _startTokenId() times
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view returns (uint256) {
        // Counter underflow is impossible as _currentIndex does not decrement,
        // and it is initialized to _startTokenId()
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return uint256(_addressData[owner].balance);
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        if (owner == address(0)) revert MintedQueryForZeroAddress();
        return uint256(_addressData[owner].numberMinted);
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        if (owner == address(0)) revert BurnedQueryForZeroAddress();
        return uint256(_addressData[owner].numberBurned);
    }

    /**
     * Returns the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        if (owner == address(0)) revert AuxQueryForZeroAddress();
        return _addressData[owner].aux;
    }

    /**
     * Sets the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal {
        if (owner == address(0)) revert AuxQueryForZeroAddress();
        _addressData[owner].aux = aux;
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr && curr < _currentIndex) {
                TokenOwnership memory ownership = _ownerships[curr];
                if (!ownership.burned) {
                    if (ownership.addr != address(0)) {
                        return ownership;
                    }
                    // Invariant:
                    // There will always be an ownership that has an address and is not burned
                    // before an ownership that does not have an address and is not burned.
                    // Hence, curr will not underflow.
                    while (true) {
                        curr--;
                        ownership = _ownerships[curr];
                        if (ownership.addr != address(0)) {
                            return ownership;
                        }
                    }
                }
            }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return ownershipOf(tokenId).addr;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = ERC721A.ownerOf(tokenId);
        if (to == owner) revert ApprovalToCurrentOwner();

        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) {
            revert ApprovalCallerNotOwnerNorApproved();
        }

        _approve(to, tokenId, owner);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public override {
        if (operator == _msgSender()) revert ApproveToCaller();

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        _transfer(from, to, tokenId);
        if (to.isContract() && !_checkContractOnERC721Received(from, to, tokenId, _data)) {
            revert TransferToNonERC721ReceiverImplementer();
        }
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _startTokenId() <= tokenId && tokenId < _currentIndex &&
            !_ownerships[tokenId].burned;
    }

    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, '');
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        _mint(to, quantity, _data, true);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _mint(
        address to,
        uint256 quantity,
        bytes memory _data,
        bool safe
    ) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            _addressData[to].balance += uint64(quantity);
            _addressData[to].numberMinted += uint64(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            if (safe && to.isContract()) {
                do {
                    emit Transfer(address(0), to, updatedIndex);
                    if (!_checkContractOnERC721Received(address(0), to, updatedIndex++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (updatedIndex != end);
                // Reentrancy protection
                if (_currentIndex != startTokenId) revert();
            } else {
                do {
                    emit Transfer(address(0), to, updatedIndex++);
                } while (updatedIndex != end);
            }
            _currentIndex = updatedIndex;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) private {
        TokenOwnership memory prevOwnership = ownershipOf(tokenId);

        bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr ||
            isApprovedForAll(prevOwnership.addr, _msgSender()) ||
            getApproved(tokenId) == _msgSender());

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        if (prevOwnership.addr != from) revert TransferFromIncorrectOwner();
        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, prevOwnership.addr);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            _addressData[from].balance -= 1;
            _addressData[to].balance += 1;

            _ownerships[tokenId].addr = to;
            _ownerships[tokenId].startTimestamp = uint64(block.timestamp);

            // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            if (_ownerships[nextTokenId].addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId < _currentIndex) {
                    _ownerships[nextTokenId].addr = prevOwnership.addr;
                    _ownerships[nextTokenId].startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        TokenOwnership memory prevOwnership = ownershipOf(tokenId);

        _beforeTokenTransfers(prevOwnership.addr, address(0), tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, prevOwnership.addr);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            _addressData[prevOwnership.addr].balance -= 1;
            _addressData[prevOwnership.addr].numberBurned += 1;

            // Keep track of who burned the token, and the timestamp of burning.
            _ownerships[tokenId].addr = prevOwnership.addr;
            _ownerships[tokenId].startTimestamp = uint64(block.timestamp);
            _ownerships[tokenId].burned = true;

            // If the ownership slot of tokenId+1 is not explicitly set, that means the burn initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            if (_ownerships[nextTokenId].addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId < _currentIndex) {
                    _ownerships[nextTokenId].addr = prevOwnership.addr;
                    _ownerships[nextTokenId].startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(prevOwnership.addr, address(0), tokenId);
        _afterTokenTransfers(prevOwnership.addr, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(
        address to,
        uint256 tokenId,
        address owner
    ) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
            return retval == IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     * And also called after one token has been burned.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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

/// SPDX-License-Identifier: MIT
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>

pragma solidity ^0.8.4;

library Base64 {
  bytes internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

  /// @notice Encodes some bytes to the base64 representation
  function encode(bytes memory data) internal pure returns (string memory) {
    uint256 len = data.length;
    if (len == 0) return '';

    // multiply by 4/3 rounded up
    uint256 encodedLen = 4 * ((len + 2) / 3);

    // Add some extra buffer at the end
    bytes memory result = new bytes(encodedLen + 32);

    bytes memory table = TABLE;

    assembly {
      let tablePtr := add(table, 1)
      let resultPtr := add(result, 32)

      for {
        let i := 0
      } lt(i, len) {

      } {
        i := add(i, 3)
        let input := and(mload(add(data, i)), 0xffffff)

        let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
        out := shl(8, out)
        out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
        out := shl(8, out)
        out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
        out := shl(8, out)
        out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
        out := shl(224, out)

        mstore(resultPtr, out)

        resultPtr := add(resultPtr, 4)
      }

      switch mod(len, 3)
      case 1 {
        mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
      }
      case 2 {
        mstore(sub(resultPtr, 1), shl(248, 0x3d))
      }

      mstore(result, encodedLen)
    }

    return string(result);
  }
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

/// @notice The Reliquary Canvas App
library TRScript {

  string public constant SCRIPT = 'for(var TH="",i=0;8>i;i++)TH+=H.substr(2,6);H="0x"+TH;for(var HB=!1,PC=64,MT=50,PI=Math.PI,TAU=2*PI,abs=Math.abs,min=Math.min,max=Math.max,sin=Math.sin,cos=Math.cos,pow=Math.pow,sqrt=Math.sqrt,ceil=Math.ceil,floor=Math.floor,rm=null,wW=0,wH=0,cS=1,canvas=null,ctx=null,L2=1<V,BC2=[{x:.5,y:.5},{x:.75,y:0}],BC3=[{x:.65,y:.15},{x:.5,y:.5},{x:.75,y:.75}],BC4=[{x:.5,y:0},{x:0,y:.5},{x:.5,y:1},{x:1,y:.5}],BC5=[{x:.5,y:.5},{x:.5,y:0},{x:0,y:.5},{x:.5,y:1},{x:1,y:.5}],BC6=[{x:.5,y:.5},{x:.5,y:0},{x:1,y:0},{x:1,y:1},{x:0,y:1},{x:0,y:0}],BC=[,,BC2,BC3,BC4,BC5,BC6],gvy=null,pxS=C/1e3,TS=TAU/127.5,DLO=.5+.5*F/1e3,DMD=1e3+19e3*F/1e3,DHI=8+24*F/1e3,RFOP=800<=F?.5+.5*(F-800)/199:0,wST=0,wS=[],wSE=0,eL=[],cPC=P.length,cP=[],pI=0,plC=BC[cPC],iFR=!0,dt=0,pvT=0,iPs=!1,iPt=!1,iEs=!1,iBx=!1,bxS=null,pB=9,pP=Array(PC),x=0;x<PC;x++){pP[x]=Array(PC);for(var y=0;y<PC;y++)pP[x][y]=0}if(L&&L.length===PC)for(var y=0;y<PC;y++)for(var row,x=0;x<PC;x++)row=""+L[y],pP[x][y]=+row.charAt(x);var sp=0;"Zen"==E&&(sp=256),"Tranquil"==E&&(sp=64),"Normal"==E&&(sp=16),"Fast"==E&&(sp=4),"Swift"==E&&(sp=2),"Hyper"==E&&(sp=.5);var sM=SD,sV=-1,sSS=1/3;"Pajamas"==Y&&(sM=SS,sSS=1/99),"Silk"==Y&&(sM=SS,sSS=1/3),"Sketch"==Y&&(sM=SRS);function SD(c,a){return c.distance-a.distance}function SS(){var a=sV;return sV+=sSS,2<=sV&&(sV-=3),a}function SRS(){var a=sV;return sV+=1/(rm()*PC),2<=sV&&(sV-=3),a}var flipX=!("Mirrored"!=D&&"MirroredUpsideDown"!=D),flipY=!("UpsideDown"!=D&&"MirroredUpsideDown"!=D),gv=3;"Lunar"==G&&(gv=.5),"Atmospheric"==G&&(gv=1),"Low"==G&&(gv=2),"High"==G&&(gv=6),"Massive"==G&&(gv=9),"Stellar"==G&&(gv=12),"Galactic"==G&&(gv=24);var ess={l:[]};"Heavenly"==N&&(ess={c:{r:{o:64},g:{o:64},b:{o:32}},l:[{st:{x:.006},n:{s:.006,d:128,c:.024,xp:.5},op:.4},{st:{x:-.007},n:{s:.007,d:128,c:.022,xp:.5},op:.6},{st:{y:.008},n:{s:.008,d:128,c:.02,xp:.5},op:.8},{st:{y:-.009},n:{s:.009,d:128,c:.018,xp:.5},op:1}]}),"Fae"==N&&(ess={l:[{c:{a:{o:16,e:-96}},st:{x:.002,y:-.017},op:.75,sc:1},{c:{a:{o:-16,e:96}},st:{x:-.001,y:-.015},op:.9,sc:1},{c:{a:{o:52,e:8}},st:{x:-.01,y:-.03},op:.9,n:{s:.02,d:64,c:.015,xp:2}}]}),"Prismatic"==N&&(ess={l:[{c:{r:{o:-64,e:128},g:{o:-64,e:128},b:{o:-32,e:64}},op:.75,n:{s:.001,d:1024,c:.001,xp:1}},{c:{r:{o:-64,e:255},g:{o:-64,e:255},b:{o:-32,e:128}},op:.25,n:{s:.001,d:1024,c:.001,xp:1}}]}),"Radiant"==N&&(ess={c:{r:{o:60,e:80},g:{o:60,e:80},b:{o:40,e:60}},l:[{op:1,n:{s:3e-4,d:40,c:.0014,xp:1}}]}),"Photonic"==N&&(ess={c:{a:{o:-64,e:140}},l:[{op:1,n:{s:.01,d:9999,c:.001,xp:3}},{op:1,n:{s:.009,d:9999,c:.001,xp:3}},{op:1,n:{s:.008,d:9999,c:.001,xp:3}},{op:1,n:{s:.007,d:9999,c:.001,xp:3}},{op:1,n:{s:.006,d:9999,c:.001,xp:3}},{op:1,n:{s:.005,d:9999,c:.001,xp:3}}]}),"Forest"==N&&(ess={c:{r:{o:-16,e:96},g:{o:-16,e:96},b:{o:16,e:-96}},l:[{st:{x:.002,y:-.014},op:.4,sc:1},{st:{x:-.001,y:-.012},op:.4,sc:1},{c:{r:{o:96,e:8},g:{o:128,e:8},b:{o:32,e:8}},st:{y:-.05},op:.3,n:{s:.02,d:1024,c:.006,xp:1}}]}),"Life"==N&&(ess={st:{x:-.006},c:{r:{o:-6,e:12},g:{o:-48,e:128},b:{o:-6,e:12}},l:[{op:.1,n:{s:.06,d:32,c:.03,xp:1}},{op:.3,n:{s:.03,d:32,c:.05,xp:2}},{op:.5,n:{s:.02,d:32,c:.07,xp:3}}]}),"Swamp"==N&&(ess={l:[{c:{r:{o:-192},b:{o:32,e:128}},st:{x:.005,y:.005},op:.8,sc:1},{c:{r:{o:-128,e:-64},g:{o:-64,e:128},b:{o:-64,e:-64}},op:1,n:{s:0,d:256,c:.04,xp:2}}]}),"Wildblood"==N&&(ess={c:{r:{o:128,e:128},g:{o:-64,e:32},b:{o:-64,e:32}},l:[{op:.3,n:{s:.002,d:64,c:.075,xp:1}},{op:.3,n:{s:.003,d:64,c:.015,xp:2}},{op:.3,n:{s:.004,d:64,c:.0023,xp:3}}]}),"Soul"==N&&(ess={n:{s:.25,d:128,c:.01,xp:3},l:[{c:{r:{o:200},g:{o:-100},b:{o:-100}},st:{x:-.005,y:-.015},op:1/3},{c:{r:{o:-100},g:{o:200},b:{o:-100}},st:{x:.005,y:-.015},op:1/3},{c:{r:{o:-100},g:{o:-100},b:{o:200}},st:{x:0,y:-.03},op:1/3}]}),"Magic"==N&&(ess={n:{s:.05,d:128,c:.015,xp:.5},l:[{c:{r:{o:200},b:{o:-200}},st:{x:-.02},op:1/3},{c:{r:{o:-200},g:{o:200}},st:{y:-.02},op:1/3},{c:{g:{o:-200},b:{o:200}},st:{x:.02},op:1/3}]}),"Astral"==N&&(ess={c:{r:{o:-64,e:96},g:{o:-64,e:64},b:{o:-64,e:96}},l:[{op:.33,n:{s:.003,d:512,c:.003,xp:1}},{op:.33,n:{s:.003,d:512,c:.003,xp:1}},{op:.33,n:{s:.003,d:512,c:.003,xp:1}},{op:.33,n:{s:.003,d:512,c:.003,xp:1}},{op:.33,n:{s:.003,d:512,c:.003,xp:1}},{op:.33,n:{s:.003,d:512,c:.003,xp:1}}]}),"Forbidden"==N&&(ess={c:{r:{o:-64,e:32},g:{o:-64,e:32},b:{o:128,e:128}},l:[{op:.3,n:{s:.001,d:64,c:.1,xp:1}},{op:.3,n:{s:.002,d:64,c:.02,xp:2}},{op:.3,n:{s:.003,d:64,c:.003,xp:3}}]}),"Runic"==N&&(ess={st:{x:-.005,y:.025},c:{r:{o:-56,e:200},g:{o:-256},b:{o:200,e:56}},n:{noBlend:!0,s:.05,d:19,c:.019,xp:2},l:[{op:.9}]}),"Unknown"==N&&(ess={l:[{c:{a:{o:256}},st:{delay:2,x:.003},n:{s:.25,d:256,c:.01,xp:1},op:1},{c:{a:{o:-256}},st:{delay:1,y:-.006},n:{s:.5,d:256,c:.01,xp:1},op:1}]}),"Tidal"==N&&(ess={c:{r:{o:48},g:{o:48},b:{o:64}},l:[{st:{x:-.02,y:-.015},op:.25,n:{s:.025,d:44,c:.032,xp:2}},{st:{x:-.02,y:.015},op:.25,n:{s:.025,d:44,c:.032,xp:2}},{st:{x:-.04,y:-.03},op:.5,n:{s:.0125,d:44,c:.016,xp:1}},{st:{x:-.04,y:.03},op:.5,n:{s:.0125,d:44,c:.016,xp:1}}]}),"Arctic"==N&&(ess={c:{r:{o:-32,e:64},g:{o:-32,e:64},b:{o:64,e:196}},l:[{op:1,n:{s:2e-6,d:48,c:.0025,xp:1}},{op:.2,n:{s:1e-6,d:512,c:.0025,xp:1}}]}),"Storm"==N&&(ess={l:[{c:{b:{e:255}},st:{x:.04,y:.04},op:1,sc:1},{c:{b:{o:-64,e:128}},st:{x:.03,y:.03},op:1,sc:0},{c:{r:{o:64,e:8},g:{o:64,e:8},b:{o:96,e:8}},st:{x:.05,y:.05},op:.5,n:{s:.01,d:64,c:.008,xp:2}}]}),"Illuvial"==N&&(ess={c:{r:{o:48},g:{o:48},b:{o:64}},l:[{st:{x:.02,y:.025},op:.2,n:{s:.03,d:44,c:.096,xp:2}},{st:{x:.03,y:.025},op:.2,n:{s:.03,d:44,c:.096,xp:2}},{st:{x:.04,y:.05},op:.5,n:{s:.015,d:44,c:.048,xp:1}},{st:{x:.06,y:.05},op:.5,n:{s:.015,d:44,c:.048,xp:1}}]}),"Undine"==N&&(ess={l:[{c:{r:{e:64},g:{e:64},b:{o:32,e:64}},op:.5,n:{s:.01,d:4444,c:.001,xp:1}},{c:{r:{o:-16,e:-333},g:{o:-16,e:-333},b:{o:-16,e:-222}},op:1,n:{s:.008,d:222,c:1e-4,xp:3}}]}),"Mineral"==N&&(ess={l:[{c:{a:{o:-16,e:48}},op:1},{c:{a:{o:-8,e:24}},op:1}]}),"Craggy"==N&&(ess={c:{r:{o:-25,e:-45},g:{o:-35,e:-55},b:{o:-45,e:-65}},n:{s:0,d:240,c:.064,xp:.75},l:[{op:1}]}),"Dwarven"==N&&(ess={c:{r:{o:-75,e:-25},g:{o:-85,e:-35},b:{o:-95,e:-45}},n:{s:0,d:128,c:.016,xp:1},l:[{op:1}]}),"Gnomic"==N&&(ess={c:{r:{o:-25,e:-45},g:{o:-35,e:-55},b:{o:-45,e:-65}},n:{s:0,d:240,c:.0064,xp:.8},l:[{op:1}]}),"Crystal"==N&&(ess={c:{a:{o:-32,e:128}},l:[{op:1},{op:1}]}),"Sylphic"==N&&(ess={l:[{c:{a:{o:-48,e:96}},st:{x:.06},op:1},{c:{a:{o:-16,e:64}},st:{x:.03},op:1}]}),"Visceral"==N&&(ess={c:{r:{o:-48},g:{o:128},b:{o:-48}},l:[{st:{x:.09},op:.1,n:{s:.14,d:128,c:.02,xp:1}},{st:{x:.12},op:.1,n:{s:.16,d:256,c:.004,xp:2}},{st:{x:.15},op:.1,n:{s:.18,d:512,c:6e-4,xp:3}}]}),"Frosted"==N&&(ess={l:[{c:{a:{o:128}},st:{x:-.06,y:.01},op:.33},{c:{r:{o:128},g:{o:128},b:{o:255}},st:{x:-.04,y:.007},op:.33},{c:{a:{o:128,e:8}},st:{x:-.07,y:.015},op:.33,n:{s:.01,d:64,c:.008,xp:2}},{c:{a:{o:128,e:8}},st:{x:-.08,y:.016},op:.33,n:{s:.008,d:64,c:.008,xp:2}}]}),"Electric"==N&&(ess={st:{x:.002,y:-.01},c:{r:{o:-256},g:{o:200,e:56},b:{o:-56,e:200}},n:{noBlend:!0,s:.05,d:19,c:.019,xp:2},l:[{op:.9}]}),"Magnetic"==N&&(ess={l:[{c:{a:{o:-255}},st:{x:-.001,y:-.001},op:.5,n:{s:.0024,d:2,c:4,xp:6}},{c:{a:{o:255}},st:{x:.001,y:.001},op:.5,n:{s:.0018,d:2,c:4,xp:6}}]}),"Infernal"==N&&(ess={l:[{c:{r:{e:255}},st:{x:.006,y:-.03},op:1,sc:1},{c:{r:{o:-64,e:128}},st:{x:.003,y:-.015},op:1,sc:0}]}),"Molten"==N&&(ess={st:{x:.001,y:.001},c:{r:{o:200,e:56},g:{o:-128,e:256},b:{o:-256}},n:{noBlend:!0,s:0,d:20,c:.024,xp:1},l:[{op:.9}]}),"Ashen"==N&&(ess={l:[{c:{r:{o:256,e:256},g:{o:128,e:128}},op:1,n:{s:.004,d:64,c:.03,xp:4}},{c:{r:{o:-512,e:256},g:{o:-512},b:{o:-512}},op:1,n:{s:.004,d:256,c:.02,xp:1}}]}),"Draconic"==N&&(ess={st:{x:-.005,y:.025},c:{r:{o:200,e:56},g:{o:-56,e:200},b:{o:-256}},n:{noBlend:!0,s:.05,d:19,c:.019,xp:2},l:[{op:.9}]}),"Celestial"==N&&(ess={st:{x:.004,y:.002},c:{a:{o:224,e:64}},n:{s:.02,d:50,c:.032,xp:2},l:[{op:1}]}),"Night"==N&&(ess={c:{r:{o:64},g:{o:-128},b:{o:64}},l:[{st:{x:-.03},op:.4,n:{s:.03,d:256,c:.01,xp:1}},{st:{y:-.02},op:.5,n:{s:.02,d:256,c:.01,xp:1}},{st:{x:-.015},op:.6,n:{s:.015,d:256,c:.01,xp:1}}]}),"Forgotten"==N&&(ess={st:{x:.006,y:.006},c:{a:{o:-512}},n:{s:.06,d:256,c:.01,xp:1},l:[{op:1}]}),"Abyssal"==N&&(ess={c:{r:{o:32,e:-512},g:{e:-512},b:{o:96,e:-512}},l:[{st:{x:-.03},op:.8,n:{s:.03,d:32,c:.005,xp:1}},{st:{y:-.02},op:.6,n:{s:.02,d:32,c:.005,xp:1}},{st:{x:.015},op:.4,n:{s:.015,d:32,c:.005,xp:1}},{st:{y:.0125},op:.2,n:{s:.0125,d:32,c:.005,xp:1}}]}),"Evil"==N&&(ess={c:{r:{o:96,e:-512},g:{e:-512},b:{o:32,e:-512}},l:[{st:{x:.01},op:.2,n:{s:.01,d:60,c:.04,xp:1}},{st:{y:.011},op:.4,n:{s:.011,d:70,c:.03,xp:1}},{st:{x:-.012},op:.6,n:{s:.012,d:80,c:.02,xp:1}},{st:{y:-.013},op:.8,n:{s:.013,d:90,c:.01,xp:1}}]}),"Lost"==N&&(ess={c:{a:{e:-512}},l:[{st:{x:-.03},op:.5,n:{s:.03,d:200,c:.03,xp:1}},{st:{y:-.02},op:.5,n:{s:.02,d:200,c:.03,xp:1}},{st:{x:.015},op:.5,n:{s:.015,d:200,c:.03,xp:1}},{st:{y:.0125},op:.5,n:{s:.0125,d:200,c:.03,xp:1}}]}),window.onload=function(){init()};function gAD(){return{id:0,value:0,minValue:0,maxValue:1,target:1,duration:1,elapsed:0,direction:1,easing:lin,ease1:lin,ease2:lin,callback:null}}var animations=[];function animate(a){var b=a.value,c=a.target,d=a.duration,e=a.easing,f=a.callback;a.elapsed=0;var g=function(g){a.elapsed+=dt;var h=max(0,min(1,e(a.elapsed/d)));a.value=b+h*(c-b),a.elapsed>=d&&(animations.splice(g,1),f&&f())};animations.push(g)}function lin(a){return a}function eSin(a){return-(cos(PI*a)-1)/2}function rAL(a){a.direction=-a.direction,a.callback=function(){rAL(a)},0>a.direction?(a.easing=a.ease1,a.target=a.minValue):(a.easing=a.ease2,a.target=a.maxValue),animate(a)}function init(){sRO(),sS(),iD(),cEl(),rC(),lFI(),sR(),rAL(gvy),window.requestAnimationFrame(oAF)}function sRO(){HB=!!document.body;var a=HB?document.body:document.all[1];wW=max(a.clientWidth,window.innerWidth),wH=max(a.clientHeight,window.innerHeight);var b=wW>wH,c=b?wH:wW;cS=c/PC,sV=-1,pI=0,cP.length=0}function cEl(){var a=HB?document.body:document.all[1];canvas=HB?document.createElement("canvas"):document.getElementById("canvas"),ctx=canvas.getContext("2d"),HB&&a.appendChild(canvas);var b=floor(cS*PC),c=document.createElement("style");c.innerText=`canvas { width: ${b}px; height: ${b}px; image-rendering: -moz-crisp-edges; image-rendering: -webkit-crisp-edges; image-rendering: pixelated; image-rendering: crisp-edges; }`,a.appendChild(c)}function rC(){if(HB){var a=floor((wW-cS*PC)/2),b=floor((wH-cS*PC)/2);canvas.style.position="absolute",canvas.style.left=a+"px",canvas.style.top=b+"px"}canvas.width=PC,canvas.height=PC}function gC(a,b){var c=PC*cS,d=floor((b-cS*PC)/2),e=floor(PC*(a-d)/c);return e}function iVC(a){return 0<=a&&a<PC}function gX(a){return gC(a.x,wW)}function gY(a){return gC(a.y,wH)}function pFE(a){if(iPt){var b=gX(a),c=gY(a);if(iVC(b)&&iVC(c)){var d=iEs?0:pB;if(iBx&&bxS){var e=gX(bxS),f=gY(bxS);if(iVC(e)&&iVC(f)){for(var g=b<e?b:e,h=c<f?c:f,i=b<e?e:b,j=c<f?f:c,k=g;k<=i;k++)for(var l=h;l<=j;l++)pP[k][l]=d;return}}pP[b][c]=d}}}function lFI(){document.addEventListener("keydown",a=>{var b=a.key;"Shift"===b&&(iEs=!0)," "===b&&(iBx=!0)},!1),document.addEventListener("keyup",a=>{var b=a.key,c=+b,d=a.ctrlKey;if(!isNaN(c))if(d)for(var e=0;e<PC;e++)for(var f=0;f<PC;f++)pP[e][f]=c;else" "!==b&&(pB=c);"p"===b||"P"===b?iPs=!iPs:"l"===b||"L"===b?lPP():"Shift"===b?iEs=!1:" "===b?(iBx=!1,bxS=null):void 0},!1),window.addEventListener("mousedown",a=>{iPt=!0,iBx&&null===bxS&&(bxS=a)}),window.addEventListener("mousemove",a=>pFE(a)),window.addEventListener("mouseup",a=>{pFE(a),iPt=!1,bxS=null})}function lPP(){for(var a=[],b=0;b<PC;b++){for(var c=0;c<PC;c++)a.push(pP[c][b]);b<PC-1&&a.push(",")}var d="["+a.join("")+"]";console.log(d),cGD(d)}function cGD(a){var b=HB?document.body:document.all[1],c=document.createElement("input");c.className="clipboard",b.appendChild(c),c.value=a,c.select(),document.execCommand("copy"),b.removeChild(c)}function oAF(a){dt=a-pvT,dt>MT?dt=MT:0>dt&&(dt=0),iPs&&(dt=0),sV=-1,pI=0,cP.length=0,wSE+=dt,sS(),sR();for(var b=animations.length,c=b-1;0<=c;c--)animations[c](c);pvT=a,window.requestAnimationFrame(oAF)}function sS(){s=0,t=0;var a=Uint32Array.from([0,1,s=t=2,3].map(function(a){return parseInt(H.substr(11*a+2,11),16)}));rm=function(){return t=a[3],a[3]=a[2],a[2]=a[1],a[1]=s=a[0],t^=t<<11,a[0]^=t^t>>>8^s>>>19,a[0]/4294967296}}function iD(){null===gvy&&(gvy=gAD(),gvy.value=gv,gvy.minValue=gv/2,gvy.maxValue=2*gv,gvy.duration=1750*(sp+2),gvy.ease1=eSin,gvy.ease2=eSin)}function sCl(){var a=P.slice();wS.length=0,wST=0;for(var b=0;b<cPC;b++){var c=gCP(),d=a[b],e=parseInt(d,16);c.r=255&e>>16,c.g=255&e>>8,c.b=255&e,pPt(c),c.weight=pow(gvy.value,5-b),wS.push(c.weight),wST+=c.weight,cP.push(c)}var f=wS[cPC-1],g=2e3*sp;wST-=cPC*f;for(var b=0;b<cPC;b++){var c=cP[b],h=wSE+.5*g*b/(cPC-1),j=cos(TAU*(h%g)/g);c.weight=f+j*wST}if(2===cPC)for(var k=cP[0],l=cP[1];;){var m=l.y-k.y,n=l.x-k.x,o=m/(n||1);if(-1.2<=o&&-.8>=o)pI=0,pPt(k),pPt(l);else break}}var imgData=null,uD=Array(4*PC*PC);function sR(){iFR&&(imgData=ctx.getImageData(0,0,PC,PC),cID(imgData.data),cE());var a=imgData.data;sCl(),L2&&(cID(uD),aE(uD)),dCPG(a),0<RFOP&&aP(a,RFOP),L2?aUD(a):aE(a),aP(a,1),ctx.putImageData(imgData,0,0),iFR=!1}function cID(a){for(var b=a.length,c=0;c<b;c++)a[c]=0==(c+1)%4?255:0}function cE(){for(var c=ess.l,e=ess.st||{},f=ess.n,h=ess.c,k={o:0,e:0},l=0;l<c.length;l++){var o=c[l],p=o.st||e,q=o.n||f,u=o.c||h,v=o.op,w=u.a||k,a=u.r||w,r=u.g||w,g=u.b||w,b=a.o||0,z=a.e||0,A=r.o||0,B=r.e||0,I=g.o||0,J=g.e||0,K={oX:0,oY:0,nOf:0,data:null,nObj:null,nDp:null,config:o,nC:q,stC:p},M=4*PC*PC;if(q){M=PC*PC,p&&(0<p.x&&(K.oX=1e8),0<p.y&&(K.oY=1e8));var O=q.d;K.nObj=cN(q.c,q.xp),K.nDp=[];for(var d=0;d<O;d++){var Q;if(d<.5*O)Q=2*d/O;else{var R=d-.5*O;Q=1-2*R/O}K.nDp.push({r:b+rm()*z,g:A+rm()*B,b:I+rm()*J,a:v*Q})}}if(K.data=Array(M),q)for(var m=0;m<M;m++){var S=floor(m/PC),y=m-S*PC;K.data[m]=K.nObj.get(y,S)}else for(var m=0;m<M;m+=4)K.data[m+0]=rm()*(b+rm()*z),K.data[m+1]=rm()*(A+rm()*B),K.data[m+2]=rm()*(I+rm()*J);eL.push(K)}}function aE(a){for(var b=a.length,c=eL.length,e=0;e<c;e++){var f=eL[e],g=f.data,h=f.nObj,l=f.config,m=f.stC,n=m.x||0,o=m.y||0;if(f.oX-=dt*n,f.oY-=dt*o,h){var p=f.nC,q=f.nDp,r=p.d||2,d=p.s||0;f.nOf+=dt*d;var u=f.nOf;0>u?u=r+u%r:u>=r&&(u%=r);for(var v=0;v<b;v+=4){var w=floor(v/4),k=floor(w/PC),z=floor(w-k*PC)+f.oX;k+=f.oY;var x=h.get(z,k),A=r*x+u,B=ceil(A),I=floor(A),J=q[B%r],K=q[I%r],M=p.noBlend?1:1-(A-I),O=p.noBlend?0:1-M,Q=K.a,R=J.a;a[v]+=M*K.r*Q+O*J.r*R,a[v+1]+=M*K.g*Q+O*J.g*R,a[v+2]+=M*K.b*Q+O*J.b*R}}else{var S=f.oX,T=f.oY,U=l.op||1,W=l.sc||0,X=1-W,Z=floor(S),$=floor(T),_=ceil(S),aa=ceil(T),ba=4*Z,ca=4*PC*$,da=4*_,ea=4*PC*aa,fa=1-(S-Z),ga=1-(T-$),ha=1-fa,ia=1-ga,ja=fa*ga,ka=fa*ia,la=ha*ga,ma=ha*ia,na=ba+ca;0>na?na=b+na%b:na>=b&&(na%=b);var oa=ba+ea;0>oa?oa=b+oa%b:oa>=b&&(oa%=b);var pa=da+ca;0>pa?pa=b+pa%b:pa>=b&&(pa%=b);var qa=da+ea;0>qa?qa=b+qa%b:qa>=b&&(qa%=b);for(var v=0;v<b;v+=4){var ra=(v+na)%b,sa=(v+oa)%b,ta=(v+pa)%b,ua=(v+qa)%b,va=(X+W*rm())*U,wa=(X+W*rm())*U,xa=(X+W*rm())*U;a[v]+=va*(ja*g[ra]+ka*g[sa]+la*g[ta]+ma*g[ua]),a[v+1]+=wa*(ja*g[ra+1]+ka*g[sa+1]+la*g[ta+1]+ma*g[ua+1]),a[v+2]+=xa*(ja*g[ra+2]+ka*g[sa+2]+la*g[ta+2]+ma*g[ua+2])}}}}function aUD(a){for(var b=a.length,c=1-pxS,d=0;d<b;d+=4){var e=d,f=d+1,g=d+2;a[e]+=c*uD[e],a[f]+=c*uD[f],a[g]+=c*uD[g]}}function aP(a,c){for(var d=a.length,e=0;e<d;e+=4){var f=floor(e/4),h=floor(f/PC),i=floor(f-h*PC),j=+pP[i][h];if(j){var l=e,m=e+1,n=e+2,o=a[l],q=a[m],g=a[n],b=c*j/9,r=1-b;a[l]=r*o+b*(255-o),a[m]=r*q+b*(255-q),a[n]=r*g+b*(255-g)}}}function dCPG(a){for(var b=0,c=0;b<PC;){for(c=0;c<PC;)sGCFP(a,cP,b,c),c++;b++}}function gCP(){return{x:0,y:0,r:0,g:0,b:0,weight:1,distance:0}}function pPt(a){var b=plC[pI++];pI>=plC.length&&(pI=0);var c=-.125+.25*rm(),d=-.125+.25*rm();a.x=(b.x+c)*PC,a.y=(b.y+d)*PC}function sGCFP(a,b,d,e){sFCCP(b,d,e);for(var f=[],g=b.length,h=0;h<g;h+=2)h==g-1?f.push(b[h]):f.push(sC(b[h],b[h+1]));if(1===f.length){flipX&&(d=PC-d-1),flipY&&(e=PC-e-1);var j=4*d,k=4*(e*PC),l=k+j,m=f[0],c=l,n=l+1,o=l+2;if(L2){var p=pxS;0<+pP[d][e]&&(p=0);var q=1-p;a[c]=q*m.r+p*a[c],a[n]=q*m.g+p*a[n],a[o]=q*m.b+p*a[o]}else a[c]=m.r,a[n]=m.g,a[o]=m.b}else sGCFP(a,f,d,e)}function sFCCP(a,b,c){var d=a.length;if(L2){var e=b,f=c;flipX&&(e=PC-b-1),flipY&&(f=PC-c-1);var g=4*e,h=4*(f*PC),j=h+g,k=3,l=3,m=3,n=uD[j]-127.5,o=uD[j+1]-127.5,p=uD[j+2]-127.5;150>C?(n=abs(n)*n*DLO,o=abs(o)*o*DLO,p=abs(p)*p*DLO):850>C?(n=DMD*cos(TS*n),o=DMD*cos(TS*o),p=DMD*cos(TS*p)):(k=1+floor(abs((n+127.5)/DHI)),l=1+floor(abs((o+127.5)/DHI)),m=1+floor(abs((p+127.5)/DHI)),n=0,o=0,p=0);for(var q=0;q<d;q++){var r=a[q],u=r.x,v=r.y;r.distance=gDE(b,c,u,v,3),r.rd=gDE(b,c,u,v,k)+n,r.gd=gDE(b,c,u,v,l)+o,r.bd=gDE(b,c,u,v,m)+p}}else for(var r,q=0;q<d;q++)r=a[q],r.distance=gDE(b,c,r.x,r.y,3);a.sort(sM)}function gDE(a,b,c,d,e){return pow(c-a,e)+pow(d-b,e)}function sC(a,b){var c=gCP(),d=a.r,e=a.g,f=a.b,g=b.r,h=b.g,i=b.b,j=a.weight,k=b.weight,l=g-d,m=h-e,n=i-f;if(L2){var o=a.rd*j,p=b.rd*k,q=a.gd*j,r=b.gd*k,u=a.bd*j,v=b.bd*k;c.x=(a.x+b.x)/2,c.y=(a.y+b.y)/2,c.r=p/(o+p)*l+d,c.g=r/(q+r)*m+e,c.b=v/(u+v)*n+f,c.weight=(j+k)/2}else{var w=a.distance*j,x=b.distance*k,y=x/(w+x);c.x=(a.x+b.x)/2,c.y=(a.y+b.y)/2,c.r=y*l+d,c.g=y*m+e,c.b=y*n+f,c.weight=(j+k)/2}return c}function cN(a,b){a=a||1,b=b||1;for(var c=[],d=function(a,b,c){return b*a[0]+c*a[1]},e=sqrt(3),f=[[1,1,0],[-1,1,0],[1,-1,0],[-1,-1,0],[1,0,1],[-1,0,1],[1,0,-1],[-1,0,-1],[0,1,1],[0,-1,1],[0,1,-1],[0,-1,-1]],g=[],h=0;256>h;h++)g[h]=0|256*rm();for(var h=0;512>h;h++)c[h]=g[255&h];return{get:function(g,h){g*=a,h*=a;var k,l,m,n,o,p=(e-1)/2*(g+h),q=0|g+p,i=0|h+p,j=(3-e)/6,r=j*(q+i),u=g-(q-r),v=h-(i-r);u>v?(n=1,o=0):(n=0,o=1);var w=u-n+j,z=v-o+j,A=u-1+2*j,B=v-1+2*j,I=255&q,J=255&i,K=c[I+c[J]]%12,M=c[I+n+c[J+o]]%12,O=c[I+1+c[J+1]]%12,Q=.5-u*u-v*v;0>Q?k=0:(Q*=Q,k=Q*Q*d(f[K],u,v));var R=.5-w*w-z*z;0>R?l=0:(R*=R,l=R*R*d(f[M],w,z));var S=.5-A*A-B*B;0>S?m=0:(S*=S,m=S*S*d(f[O],A,B));var T=(70*(k+l+m)+1)/2;return 1!==b&&(T=pow(T,b)),T}}}';

  function getScript() public pure returns (string memory) {
      return SCRIPT;
  }

}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import './TRColors.sol';

interface ITRRolls {

  struct RelicInfo {
    string element;
    string palette;
    string essence;
    uint256 colorCount;
    string style;
    string speed;
    string gravity;
    string display;
    string relicType;
    string glyphType;
    uint256 runeflux;
    uint256 corruption;
    uint256 grailId;
    uint256[] grailGlyph;
  }

  function getRelicInfo(TRKeys.RuneCore memory core) external view returns (RelicInfo memory);
  function getElement(TRKeys.RuneCore memory core) external view returns (string memory);
  function getPalette(TRKeys.RuneCore memory core) external view returns (string memory);
  function getEssence(TRKeys.RuneCore memory core) external view returns (string memory);
  function getStyle(TRKeys.RuneCore memory core) external view returns (string memory);
  function getSpeed(TRKeys.RuneCore memory core) external view returns (string memory);
  function getGravity(TRKeys.RuneCore memory core) external view returns (string memory);
  function getDisplay(TRKeys.RuneCore memory core) external view returns (string memory);
  function getColorCount(TRKeys.RuneCore memory core) external view returns (uint256);
  function getColorByIndex(TRKeys.RuneCore memory core, uint256 index) external view returns (string memory);
  function getRelicType(TRKeys.RuneCore memory core) external view returns (string memory);
  function getGlyphType(TRKeys.RuneCore memory core) external view returns (string memory);
  function getRuneflux(TRKeys.RuneCore memory core) external view returns (uint256);
  function getCorruption(TRKeys.RuneCore memory core) external view returns (uint256);
  function getDescription(TRKeys.RuneCore memory core) external view returns (string memory);
  function getGrailId(TRKeys.RuneCore memory core) external pure returns (uint256);

}

/// @notice The Reliquary Rarity Distribution
contract TRRolls is Ownable, ITRRolls {

  mapping(uint256 => address) public grailContracts;

  error GrailsAreImmutable();

  constructor() Ownable() {}

  function getRelicInfo(TRKeys.RuneCore memory core)
    override
    public
    view
    returns (RelicInfo memory)
  {
    RelicInfo memory info;
    info.element = getElement(core);
    info.palette = getPalette(core);
    info.essence = getEssence(core);
    info.colorCount = getColorCount(core);
    info.style = getStyle(core);
    info.speed = getSpeed(core);
    info.gravity = getGravity(core);
    info.display = getDisplay(core);
    info.relicType = getRelicType(core);
    info.glyphType = getGlyphType(core);
    info.runeflux = getRuneflux(core);
    info.corruption = getCorruption(core);
    info.grailId = getGrailId(core);

    if (info.grailId != TRKeys.GRAIL_ID_NONE) {
      info.grailGlyph = Grail(grailContracts[info.grailId]).getGlyph();
    }

    return info;
  }

  function getElement(TRKeys.RuneCore memory core) override public view returns (string memory) {
    uint256 grailId = getGrailId(core);
    if (grailId != TRKeys.GRAIL_ID_NONE) {
      return Grail(grailContracts[grailId]).getElement();
    }

    if (bytes(core.transmutation).length > 0) {
      return core.transmutation;
    }

    uint256 roll = roll1000(core, TRKeys.ROLL_ELEMENT);
    if (roll <= uint256(125)) {
      return TRKeys.ELEM_NATURE;
    } else if (roll <= uint256(250)) {
      return TRKeys.ELEM_LIGHT;
    } else if (roll <= uint256(375)) {
      return TRKeys.ELEM_WATER;
    } else if (roll <= uint256(500)) {
      return TRKeys.ELEM_EARTH;
    } else if (roll <= uint256(625)) {
      return TRKeys.ELEM_WIND;
    } else if (roll <= uint256(750)) {
      return TRKeys.ELEM_ARCANE;
    } else if (roll <= uint256(875)) {
      return TRKeys.ELEM_SHADOW;
    } else {
      return TRKeys.ELEM_FIRE;
    }
  }

  function getPalette(TRKeys.RuneCore memory core) override public view returns (string memory) {
    uint256 grailId = getGrailId(core);
    if (grailId != TRKeys.GRAIL_ID_NONE) {
      return Grail(grailContracts[grailId]).getPalette();
    }

    if (core.colors.length > 0) {
      return TRKeys.ANY_PAL_CUSTOM;
    }

    string memory element = getElement(core);
    uint256 roll = roll1000(core, TRKeys.ROLL_PALETTE);
    if (TRUtils.compare(element, TRKeys.ELEM_NATURE)) {
      return getNaturePalette(roll);
    } else if (TRUtils.compare(element, TRKeys.ELEM_LIGHT)) {
      return getLightPalette(roll);
    } else if (TRUtils.compare(element, TRKeys.ELEM_WATER)) {
      return getWaterPalette(roll);
    } else if (TRUtils.compare(element, TRKeys.ELEM_EARTH)) {
      return getEarthPalette(roll);
    } else if (TRUtils.compare(element, TRKeys.ELEM_WIND)) {
      return getWindPalette(roll);
    } else if (TRUtils.compare(element, TRKeys.ELEM_ARCANE)) {
      return getArcanePalette(roll);
    } else if (TRUtils.compare(element, TRKeys.ELEM_SHADOW)) {
      return getShadowPalette(roll);
    } else {
      return getFirePalette(roll);
    }
  }

  function getNaturePalette(uint256 roll) public pure returns (string memory) {
    if (roll <= 600) {
      return TRKeys.NAT_PAL_JUNGLE;
    } else if (roll <= 900) {
      return TRKeys.NAT_PAL_CAMOUFLAGE;
    } else {
      return TRKeys.NAT_PAL_BIOLUMINESCENCE;
    }
  }

  function getLightPalette(uint256 roll) public pure returns (string memory) {
    if (roll <= 600) {
      return TRKeys.LIG_PAL_PASTEL;
    } else if (roll <= 900) {
      return TRKeys.LIG_PAL_INFRARED;
    } else {
      return TRKeys.LIG_PAL_ULTRAVIOLET;
    }
  }

  function getWaterPalette(uint256 roll) public pure returns (string memory) {
    if (roll <= 600) {
      return TRKeys.WAT_PAL_FROZEN;
    } else if (roll <= 900) {
      return TRKeys.WAT_PAL_DAWN;
    } else {
      return TRKeys.WAT_PAL_OPALESCENT;
    }
  }

  function getEarthPalette(uint256 roll) public pure returns (string memory) {
    if (roll <= 600) {
      return TRKeys.EAR_PAL_COAL;
    } else if (roll <= 900) {
      return TRKeys.EAR_PAL_SILVER;
    } else {
      return TRKeys.EAR_PAL_GOLD;
    }
  }

  function getWindPalette(uint256 roll) public pure returns (string memory) {
    if (roll <= 600) {
      return TRKeys.WIN_PAL_BERRY;
    } else if (roll <= 900) {
      return TRKeys.WIN_PAL_THUNDER;
    } else {
      return TRKeys.WIN_PAL_AERO;
    }
  }

  function getArcanePalette(uint256 roll) public pure returns (string memory) {
    if (roll <= 600) {
      return TRKeys.ARC_PAL_FROSTFIRE;
    } else if (roll <= 900) {
      return TRKeys.ARC_PAL_COSMIC;
    } else {
      return TRKeys.ARC_PAL_COLORLESS;
    }
  }

  function getShadowPalette(uint256 roll) public pure returns (string memory) {
    if (roll <= 600) {
      return TRKeys.SHA_PAL_DARKNESS;
    } else if (roll <= 900) {
      return TRKeys.SHA_PAL_VOID;
    } else {
      return TRKeys.SHA_PAL_UNDEAD;
    }
  }

  function getFirePalette(uint256 roll) public pure returns (string memory) {
    if (roll <= 600) {
      return TRKeys.FIR_PAL_HEAT;
    } else if (roll <= 900) {
      return TRKeys.FIR_PAL_EMBER;
    } else {
      return TRKeys.FIR_PAL_CORRUPTED;
    }
  }

  function getEssence(TRKeys.RuneCore memory core) override public view returns (string memory) {
    uint256 grailId = getGrailId(core);
    if (grailId != TRKeys.GRAIL_ID_NONE) {
      return Grail(grailContracts[grailId]).getEssence();
    }

    string memory element = getElement(core);
    string memory relicType = getRelicType(core);
    if (TRUtils.compare(element, TRKeys.ELEM_NATURE)) {
      return getNatureEssence(relicType);
    } else if (TRUtils.compare(element, TRKeys.ELEM_LIGHT)) {
      return getLightEssence(relicType);
    } else if (TRUtils.compare(element, TRKeys.ELEM_WATER)) {
      return getWaterEssence(relicType);
    } else if (TRUtils.compare(element, TRKeys.ELEM_EARTH)) {
      return getEarthEssence(relicType);
    } else if (TRUtils.compare(element, TRKeys.ELEM_WIND)) {
      return getWindEssence(relicType);
    } else if (TRUtils.compare(element, TRKeys.ELEM_ARCANE)) {
      return getArcaneEssence(relicType);
    } else if (TRUtils.compare(element, TRKeys.ELEM_SHADOW)) {
      return getShadowEssence(relicType);
    } else {
      return getFireEssence(relicType);
    }
  }

  function getNatureEssence(string memory relicType) public pure returns (string memory) {
    if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_TRINKET)) {
      return TRKeys.NAT_ESS_FOREST;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_TALISMAN)) {
      return TRKeys.NAT_ESS_SWAMP;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_AMULET)) {
      return TRKeys.NAT_ESS_WILDBLOOD;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_FOCUS)) {
      return TRKeys.NAT_ESS_LIFE;
    } else {
      return TRKeys.NAT_ESS_SOUL;
    }
  }

  function getLightEssence(string memory relicType) public pure returns (string memory) {
    if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_TRINKET)) {
      return TRKeys.LIG_ESS_HEAVENLY;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_TALISMAN)) {
      return TRKeys.LIG_ESS_FAE;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_AMULET)) {
      return TRKeys.LIG_ESS_PRISMATIC;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_FOCUS)) {
      return TRKeys.LIG_ESS_RADIANT;
    } else {
      return TRKeys.LIG_ESS_PHOTONIC;
    }
  }

  function getWaterEssence(string memory relicType) public pure returns (string memory) {
    if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_TRINKET)) {
      return TRKeys.WAT_ESS_TIDAL;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_TALISMAN)) {
      return TRKeys.WAT_ESS_ARCTIC;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_AMULET)) {
      return TRKeys.WAT_ESS_STORM;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_FOCUS)) {
      return TRKeys.WAT_ESS_ILLUVIAL;
    } else {
      return TRKeys.WAT_ESS_UNDINE;
    }
  }

  function getEarthEssence(string memory relicType) public pure returns (string memory) {
    if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_TRINKET)) {
      return TRKeys.EAR_ESS_MINERAL;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_TALISMAN)) {
      return TRKeys.EAR_ESS_CRAGGY;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_AMULET)) {
      return TRKeys.EAR_ESS_DWARVEN;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_FOCUS)) {
      return TRKeys.EAR_ESS_GNOMIC;
    } else {
      return TRKeys.EAR_ESS_CRYSTAL;
    }
  }

  function getWindEssence(string memory relicType) public pure returns (string memory) {
    if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_TRINKET)) {
      return TRKeys.WIN_ESS_SYLPHIC;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_TALISMAN)) {
      return TRKeys.WIN_ESS_VISCERAL;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_AMULET)) {
      return TRKeys.WIN_ESS_FROSTED;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_FOCUS)) {
      return TRKeys.WIN_ESS_ELECTRIC;
    } else {
      return TRKeys.WIN_ESS_MAGNETIC;
    }
  }

  function getArcaneEssence(string memory relicType) public pure returns (string memory) {
    if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_TRINKET)) {
      return TRKeys.ARC_ESS_MAGIC;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_TALISMAN)) {
      return TRKeys.ARC_ESS_ASTRAL;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_AMULET)) {
      return TRKeys.ARC_ESS_FORBIDDEN;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_FOCUS)) {
      return TRKeys.ARC_ESS_RUNIC;
    } else {
      return TRKeys.ARC_ESS_UNKNOWN;
    }
  }

  function getShadowEssence(string memory relicType) public pure returns (string memory) {
    if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_TRINKET)) {
      return TRKeys.SHA_ESS_NIGHT;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_TALISMAN)) {
      return TRKeys.SHA_ESS_FORGOTTEN;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_AMULET)) {
      return TRKeys.SHA_ESS_ABYSSAL;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_FOCUS)) {
      return TRKeys.SHA_ESS_EVIL;
    } else {
      return TRKeys.SHA_ESS_LOST;
    }
  }

  function getFireEssence(string memory relicType) public pure returns (string memory) {
    if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_TRINKET)) {
      return TRKeys.FIR_ESS_INFERNAL;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_TALISMAN)) {
      return TRKeys.FIR_ESS_MOLTEN;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_AMULET)) {
      return TRKeys.FIR_ESS_ASHEN;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_FOCUS)) {
      return TRKeys.FIR_ESS_DRACONIC;
    } else {
      return TRKeys.FIR_ESS_CELESTIAL;
    }
  }

  function getStyle(TRKeys.RuneCore memory core) override public view returns (string memory) {
    uint256 grailId = getGrailId(core);
    if (grailId != TRKeys.GRAIL_ID_NONE) {
      return Grail(grailContracts[grailId]).getStyle();
    }

    uint256 roll = roll1000(core, TRKeys.ROLL_STYLE);
    if (roll <= 760) {
      return TRKeys.STYLE_SMOOTH;
    } else if (roll <= 940) {
      return TRKeys.STYLE_SILK;
    } else if (roll <= 980) {
      return TRKeys.STYLE_PAJAMAS;
    } else {
      return TRKeys.STYLE_SKETCH;
    }
  }

  function getSpeed(TRKeys.RuneCore memory core) override public view returns (string memory) {
    uint256 grailId = getGrailId(core);
    if (grailId != TRKeys.GRAIL_ID_NONE) {
      return Grail(grailContracts[grailId]).getSpeed();
    }

    uint256 roll = roll1000(core, TRKeys.ROLL_SPEED);
    if (roll <= 70) {
      return TRKeys.SPEED_ZEN;
    } else if (roll <= 260) {
      return TRKeys.SPEED_TRANQUIL;
    } else if (roll <= 760) {
      return TRKeys.SPEED_NORMAL;
    } else if (roll <= 890) {
      return TRKeys.SPEED_FAST;
    } else if (roll <= 960) {
      return TRKeys.SPEED_SWIFT;
    } else {
      return TRKeys.SPEED_HYPER;
    }
  }

  function getGravity(TRKeys.RuneCore memory core) override public view returns (string memory) {
    uint256 grailId = getGrailId(core);
    if (grailId != TRKeys.GRAIL_ID_NONE) {
      return Grail(grailContracts[grailId]).getGravity();
    }

    uint256 roll = roll1000(core, TRKeys.ROLL_GRAVITY);
    if (roll <= 50) {
      return TRKeys.GRAV_LUNAR;
    } else if (roll <= 150) {
      return TRKeys.GRAV_ATMOSPHERIC;
    } else if (roll <= 340) {
      return TRKeys.GRAV_LOW;
    } else if (roll <= 730) {
      return TRKeys.GRAV_NORMAL;
    } else if (roll <= 920) {
      return TRKeys.GRAV_HIGH;
    } else if (roll <= 970) {
      return TRKeys.GRAV_MASSIVE;
    } else if (roll <= 995) {
      return TRKeys.GRAV_STELLAR;
    } else {
      return TRKeys.GRAV_GALACTIC;
    }
  }

  function getDisplay(TRKeys.RuneCore memory core) override public view returns (string memory) {
    uint256 grailId = getGrailId(core);
    if (grailId != TRKeys.GRAIL_ID_NONE) {
      return Grail(grailContracts[grailId]).getDisplay();
    }

    uint256 roll = roll1000(core, TRKeys.ROLL_DISPLAY);
    if (roll <= 250) {
      return TRKeys.DISPLAY_NORMAL;
    } else if (roll <= 500) {
      return TRKeys.DISPLAY_MIRRORED;
    } else if (roll <= 750) {
      return TRKeys.DISPLAY_UPSIDEDOWN;
    } else {
      return TRKeys.DISPLAY_MIRROREDUPSIDEDOWN;
    }
  }

  function getColorCount(TRKeys.RuneCore memory core) override public view returns (uint256) {
    uint256 grailId = getGrailId(core);
    if (grailId != TRKeys.GRAIL_ID_NONE) {
      return Grail(grailContracts[grailId]).getColorCount();
    }

    string memory style = getStyle(core);
    if (TRUtils.compare(style, TRKeys.STYLE_SILK)) {
      return 5;
    } else if (TRUtils.compare(style, TRKeys.STYLE_PAJAMAS)) {
      return 5;
    } else if (TRUtils.compare(style, TRKeys.STYLE_SKETCH)) {
      return 4;
    }

    uint256 roll = roll1000(core, TRKeys.ROLL_COLORCOUNT);
    if (roll <= 400) {
      return 2;
    } else if (roll <= 750) {
      return 3;
    } else {
      return 4;
    }
  }

  function getColorByIndex(TRKeys.RuneCore memory core, uint256 index)
    override
    public
    view
    returns (string memory)
  {
    // if the requested index exceeds the color count, return empty string
    if (index >= getColorCount(core)) {
      return '';
    }

    // if we've imagined new colors, use them instead
    if (core.colors.length > index) {
      return TRUtils.getColorCode(core.colors[index]);
    }

    // fetch the color palette
    uint256[] memory colorInts;
    uint256 colorIntCount;
    (colorInts, colorIntCount) = TRColors.get(getPalette(core));

    // shuffle the color palette
    uint256 i;
    uint256 temp;
    uint256 count = colorIntCount;
    while (count > 0) {
      string memory rollKey = string(abi.encodePacked(
        TRKeys.ROLL_SHUFFLE,
        TRUtils.toString(count)
      ));

      i = roll1000(core, rollKey) % count;

      temp = colorInts[--count];
      colorInts[count] = colorInts[i];
      colorInts[i] = temp;
    }

    // slightly adjust the RGB channels of the color to make it unique
    temp = getWobbledColor(core, index, colorInts[index % colorIntCount]);

    // return a hex code (without the #)
    return TRUtils.getColorCode(temp);
  }

  function getWobbledColor(TRKeys.RuneCore memory core, uint256 index, uint256 color)
    public
    pure
    returns (uint256)
  {
    uint256 r = (color >> uint256(16)) & uint256(255);
    uint256 g = (color >> uint256(8)) & uint256(255);
    uint256 b = color & uint256(255);

    string memory k = TRUtils.toString(index);
    uint256 dr = rollMax(core, string(abi.encodePacked(TRKeys.ROLL_RED, k))) % 8;
    uint256 dg = rollMax(core, string(abi.encodePacked(TRKeys.ROLL_GREEN, k))) % 8;
    uint256 db = rollMax(core, string(abi.encodePacked(TRKeys.ROLL_BLUE, k))) % 8;
    uint256 rSign = rollMax(core, string(abi.encodePacked(TRKeys.ROLL_REDSIGN, k))) % 2;
    uint256 gSign = rollMax(core, string(abi.encodePacked(TRKeys.ROLL_GREENSIGN, k))) % 2;
    uint256 bSign = rollMax(core, string(abi.encodePacked(TRKeys.ROLL_BLUESIGN, k))) % 2;

    if (rSign == 0) {
      if (r > dr) {
        r -= dr;
      } else {
        r = 0;
      }
    } else {
      if (r + dr <= 255) {
        r += dr;
      } else {
        r = 255;
      }
    }

    if (gSign == 0) {
      if (g > dg) {
        g -= dg;
      } else {
        g = 0;
      }
    } else {
      if (g + dg <= 255) {
        g += dg;
      } else {
        g = 255;
      }
    }

    if (bSign == 0) {
      if (b > db) {
        b -= db;
      } else {
        b = 0;
      }
    } else {
      if (b + db <= 255) {
        b += db;
      } else {
        b = 255;
      }
    }

    return uint256((r << uint256(16)) | (g << uint256(8)) | b);
  }

  function getRelicType(TRKeys.RuneCore memory core) override public view returns (string memory) {
    uint256 grailId = getGrailId(core);
    if (grailId != TRKeys.GRAIL_ID_NONE) {
      return Grail(grailContracts[grailId]).getRelicType();
    }

    if (core.isDivinityQuestLoot) {
      return TRKeys.RELIC_TYPE_CURIO;
    }

    uint256 roll = roll1000(core, TRKeys.ROLL_RELICTYPE);
    if (roll <= 360) {
      return TRKeys.RELIC_TYPE_TRINKET;
    } else if (roll <= 620) {
      return TRKeys.RELIC_TYPE_TALISMAN;
    } else if (roll <= 820) {
      return TRKeys.RELIC_TYPE_AMULET;
    } else if (roll <= 960) {
      return TRKeys.RELIC_TYPE_FOCUS;
    } else {
      return TRKeys.RELIC_TYPE_CURIO;
    }
  }

  function getGlyphType(TRKeys.RuneCore memory core) override public pure returns (string memory) {
    uint256 grailId = getGrailId(core);
    if (grailId != TRKeys.GRAIL_ID_NONE) {
      return TRKeys.GLYPH_TYPE_GRAIL;
    }

    if (core.glyph.length > 0) {
      return TRKeys.GLYPH_TYPE_CUSTOM;
    }

    return TRKeys.GLYPH_TYPE_NONE;
  }

  function getRuneflux(TRKeys.RuneCore memory core) override public view returns (uint256) {
    uint256 grailId = getGrailId(core);
    if (grailId != TRKeys.GRAIL_ID_NONE) {
      return Grail(grailContracts[grailId]).getRuneflux();
    }

    if (core.isDivinityQuestLoot) {
      return 700 + rollMax(core, TRKeys.ROLL_RUNEFLUX) % 300;
    }

    return roll1000(core, TRKeys.ROLL_RUNEFLUX) - 1;
  }

  function getCorruption(TRKeys.RuneCore memory core) override public view returns (uint256) {
    uint256 grailId = getGrailId(core);
    if (grailId != TRKeys.GRAIL_ID_NONE) {
      return Grail(grailContracts[grailId]).getCorruption();
    }

    if (core.isDivinityQuestLoot) {
      return 700 + rollMax(core, TRKeys.ROLL_CORRUPTION) % 300;
    }

    return roll1000(core, TRKeys.ROLL_CORRUPTION) - 1;
  }

  function getDescription(TRKeys.RuneCore memory core) override public view returns (string memory) {
    uint256 grailId = getGrailId(core);
    if (grailId != TRKeys.GRAIL_ID_NONE) {
      return Grail(grailContracts[grailId]).getDescription();
    }

    return '';
  }

  function getGrailId(TRKeys.RuneCore memory core) override public pure returns (uint256) {
    uint256 grailId = TRKeys.GRAIL_ID_NONE;

    if (bytes(core.hiddenLeyLines).length > 0) {
      uint256 rollDist = TRUtils.random(core.hiddenLeyLines) ^ TRUtils.random(TRKeys.ROLL_GRAILS);
      uint256 digits = 1 + rollDist % TRKeys.GRAIL_DISTRIBUTION;
      for (uint256 i; i < TRKeys.GRAIL_COUNT; i++) {
        if (core.tokenId == digits + TRKeys.GRAIL_DISTRIBUTION * i) {
          uint256 rollShuf = TRUtils.random(core.hiddenLeyLines) ^ TRUtils.random(TRKeys.ROLL_ELEMENT);
          uint256 offset = rollShuf % TRKeys.GRAIL_COUNT;
          grailId = 1 + (i + offset) % TRKeys.GRAIL_COUNT;
          break;
        }
      }
    }

    return grailId;
  }

  function rollMax(TRKeys.RuneCore memory core, string memory key) internal pure returns (uint256) {
    string memory tokenKey = string(abi.encodePacked(key, TRUtils.toString(7 * core.tokenId)));
    return TRUtils.random(core.runeHash) ^ TRUtils.random(tokenKey);
  }

  function roll1000(TRKeys.RuneCore memory core, string memory key) internal pure returns (uint256) {
    return 1 + rollMax(core, key) % 1000;
  }

  function rollColor(TRKeys.RuneCore memory core, uint256 index) internal pure returns (uint256) {
    string memory k = TRUtils.toString(index);
    return rollMax(core, string(abi.encodePacked(TRKeys.ROLL_RANDOMCOLOR, k))) % 16777216;
  }

  function setGrailContract(uint256 grailId, address grailContract) public onlyOwner {
    if (grailContracts[grailId] != address(0)) revert GrailsAreImmutable();

    grailContracts[grailId] = grailContract;
  }

}



abstract contract Grail {
  function getElement() external pure virtual returns (string memory);
  function getPalette() external pure virtual returns (string memory);
  function getEssence() external pure virtual returns (string memory);
  function getStyle() external pure virtual returns (string memory);
  function getSpeed() external pure virtual returns (string memory);
  function getGravity() external pure virtual returns (string memory);
  function getDisplay() external pure virtual returns (string memory);
  function getColorCount() external pure virtual returns (uint256);
  function getRelicType() external pure virtual returns (string memory);
  function getRuneflux() external pure virtual returns (uint256);
  function getCorruption() external pure virtual returns (uint256);
  function getGlyph() external pure virtual returns (uint256[] memory);
  function getDescription() external pure virtual returns (string memory);
}

/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import './TRKeys.sol';

/// @notice The Reliquary Color Palettes
library TRColors {

  function get(string memory palette)
    public
    pure
    returns (uint256[] memory, uint256)
  {
    uint256[] memory colorInts = new uint256[](12);
    uint256 colorIntCount = 0;

    if (TRUtils.compare(palette, TRKeys.NAT_PAL_JUNGLE)) {
      colorInts[0] = uint256(3299866);
      colorInts[1] = uint256(1256965);
      colorInts[2] = uint256(2375731);
      colorInts[3] = uint256(67585);
      colorInts[4] = uint256(16749568);
      colorInts[5] = uint256(16776295);
      colorInts[6] = uint256(16748230);
      colorInts[7] = uint256(16749568);
      colorInts[8] = uint256(67585);
      colorInts[9] = uint256(2375731);
      colorIntCount = uint256(10);
    } else if (TRUtils.compare(palette, TRKeys.NAT_PAL_CAMOUFLAGE)) {
      colorInts[0] = uint256(10328673);
      colorInts[1] = uint256(6245168);
      colorInts[2] = uint256(2171169);
      colorInts[3] = uint256(4610624);
      colorInts[4] = uint256(5269320);
      colorInts[5] = uint256(4994846);
      colorIntCount = uint256(6);
    } else if (TRUtils.compare(palette, TRKeys.NAT_PAL_BIOLUMINESCENCE)) {
      colorInts[0] = uint256(2434341);
      colorInts[1] = uint256(4194315);
      colorInts[2] = uint256(6488209);
      colorInts[3] = uint256(7270568);
      colorInts[4] = uint256(9117400);
      colorInts[5] = uint256(1599944);
      colorIntCount = uint256(6);
    } else if (TRUtils.compare(palette, TRKeys.LIG_PAL_PASTEL)) {
      colorInts[0] = uint256(16761760);
      colorInts[1] = uint256(16756669);
      colorInts[2] = uint256(16636817);
      colorInts[3] = uint256(13762047);
      colorInts[4] = uint256(8714928);
      colorInts[5] = uint256(9425908);
      colorInts[6] = uint256(16499435);
      colorInts[7] = uint256(10587345);
      colorIntCount = uint256(8);
    } else if (TRUtils.compare(palette, TRKeys.LIG_PAL_INFRARED)) {
      colorInts[0] = uint256(16642938);
      colorInts[1] = uint256(16755712);
      colorInts[2] = uint256(15883521);
      colorInts[3] = uint256(13503623);
      colorInts[4] = uint256(8257951);
      colorInts[5] = uint256(327783);
      colorInts[6] = uint256(13503623);
      colorInts[7] = uint256(15883521);
      colorIntCount = uint256(8);
    } else if (TRUtils.compare(palette, TRKeys.LIG_PAL_ULTRAVIOLET)) {
      colorInts[0] = uint256(14200063);
      colorInts[1] = uint256(5046460);
      colorInts[2] = uint256(16775167);
      colorInts[3] = uint256(16024318);
      colorInts[4] = uint256(11665662);
      colorInts[5] = uint256(1507410);
      colorIntCount = uint256(6);
    } else if (TRUtils.compare(palette, TRKeys.WAT_PAL_FROZEN)) {
      colorInts[0] = uint256(13034750);
      colorInts[1] = uint256(4102128);
      colorInts[2] = uint256(826589);
      colorInts[3] = uint256(346764);
      colorInts[4] = uint256(6707);
      colorInts[5] = uint256(1277652);
      colorIntCount = uint256(6);
    } else if (TRUtils.compare(palette, TRKeys.WAT_PAL_DAWN)) {
      colorInts[0] = uint256(334699);
      colorInts[1] = uint256(610965);
      colorInts[2] = uint256(5408708);
      colorInts[3] = uint256(16755539);
      colorIntCount = uint256(4);
    } else if (TRUtils.compare(palette, TRKeys.WAT_PAL_OPALESCENT)) {
      colorInts[0] = uint256(15985337);
      colorInts[1] = uint256(15981758);
      colorInts[2] = uint256(15713994);
      colorInts[3] = uint256(13941977);
      colorInts[4] = uint256(8242919);
      colorInts[5] = uint256(15985337);
      colorInts[6] = uint256(15981758);
      colorInts[7] = uint256(15713994);
      colorInts[8] = uint256(13941977);
      colorInts[9] = uint256(8242919);
      colorIntCount = uint256(10);
    } else if (TRUtils.compare(palette, TRKeys.EAR_PAL_COAL)) {
      colorInts[0] = uint256(3613475);
      colorInts[1] = uint256(1577233);
      colorInts[2] = uint256(4407359);
      colorInts[3] = uint256(2894892);
      colorIntCount = uint256(4);
    } else if (TRUtils.compare(palette, TRKeys.EAR_PAL_SILVER)) {
      colorInts[0] = uint256(16053492);
      colorInts[1] = uint256(15329769);
      colorInts[2] = uint256(10132122);
      colorInts[3] = uint256(6776679);
      colorInts[4] = uint256(3881787);
      colorInts[5] = uint256(1579032);
      colorIntCount = uint256(6);
    } else if (TRUtils.compare(palette, TRKeys.EAR_PAL_GOLD)) {
      colorInts[0] = uint256(16373583);
      colorInts[1] = uint256(12152866);
      colorInts[2] = uint256(12806164);
      colorInts[3] = uint256(4725765);
      colorInts[4] = uint256(2557441);
      colorIntCount = uint256(5);
    } else if (TRUtils.compare(palette, TRKeys.WIN_PAL_BERRY)) {
      colorInts[0] = uint256(5428970);
      colorInts[1] = uint256(13323211);
      colorInts[2] = uint256(15385745);
      colorInts[3] = uint256(13355851);
      colorInts[4] = uint256(15356630);
      colorInts[5] = uint256(14903600);
      colorIntCount = uint256(6);
    } else if (TRUtils.compare(palette, TRKeys.WIN_PAL_THUNDER)) {
      colorInts[0] = uint256(924722);
      colorInts[1] = uint256(9464002);
      colorInts[2] = uint256(470093);
      colorInts[3] = uint256(6378394);
      colorInts[4] = uint256(16246484);
      colorInts[5] = uint256(12114921);
      colorIntCount = uint256(6);
    } else if (TRUtils.compare(palette, TRKeys.WIN_PAL_AERO)) {
      colorInts[0] = uint256(4609);
      colorInts[1] = uint256(803087);
      colorInts[2] = uint256(2062109);
      colorInts[3] = uint256(11009906);
      colorIntCount = uint256(4);
    } else if (TRUtils.compare(palette, TRKeys.ARC_PAL_FROSTFIRE)) {
      colorInts[0] = uint256(16772570);
      colorInts[1] = uint256(4043519);
      colorInts[2] = uint256(16758832);
      colorInts[3] = uint256(16720962);
      colorIntCount = uint256(4);
    } else if (TRUtils.compare(palette, TRKeys.ARC_PAL_COSMIC)) {
      colorInts[0] = uint256(1182264);
      colorInts[1] = uint256(10834562);
      colorInts[2] = uint256(4269159);
      colorInts[3] = uint256(16769495);
      colorInts[4] = uint256(3351916);
      colorInts[5] = uint256(12612224);
      colorIntCount = uint256(6);
    } else if (TRUtils.compare(palette, TRKeys.ARC_PAL_COLORLESS)) {
      colorInts[0] = uint256(1644825);
      colorInts[1] = uint256(15132390);
      colorIntCount = uint256(2);
    } else if (TRUtils.compare(palette, TRKeys.SHA_PAL_DARKNESS)) {
      colorInts[0] = uint256(2885188);
      colorInts[1] = uint256(1572943);
      colorInts[2] = uint256(1179979);
      colorInts[3] = uint256(657930);
      colorIntCount = uint256(4);
    } else if (TRUtils.compare(palette, TRKeys.SHA_PAL_VOID)) {
      colorInts[0] = uint256(1572943);
      colorInts[1] = uint256(4194415);
      colorInts[2] = uint256(6488209);
      colorInts[3] = uint256(13051525);
      colorInts[4] = uint256(657930);
      colorIntCount = uint256(5);
    } else if (TRUtils.compare(palette, TRKeys.SHA_PAL_UNDEAD)) {
      colorInts[0] = uint256(3546937);
      colorInts[1] = uint256(50595);
      colorInts[2] = uint256(7511983);
      colorInts[3] = uint256(7563923);
      colorInts[4] = uint256(10535352);
      colorIntCount = uint256(5);
    } else if (TRUtils.compare(palette, TRKeys.FIR_PAL_HEAT)) {
      colorInts[0] = uint256(590337);
      colorInts[1] = uint256(12141574);
      colorInts[2] = uint256(15908162);
      colorInts[3] = uint256(6886400);
      colorIntCount = uint256(4);
    } else if (TRUtils.compare(palette, TRKeys.FIR_PAL_EMBER)) {
      colorInts[0] = uint256(1180162);
      colorInts[1] = uint256(7929858);
      colorInts[2] = uint256(7012357);
      colorInts[3] = uint256(16744737);
      colorIntCount = uint256(4);
    } else {
      colorInts[0] = uint256(197391);
      colorInts[1] = uint256(3604610);
      colorInts[2] = uint256(6553778);
      colorInts[3] = uint256(14305728);
      colorIntCount = uint256(4);
    }

    return (colorInts, colorIntCount);
  }

}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

import './TRUtils.sol';

/// @notice The Reliquary Constants
library TRKeys {

  struct RuneCore {
    uint256 tokenId;
    uint8 level;
    uint32 mana;
    bool isDivinityQuestLoot;
    bool isSecretDiscovered;
    uint8 secretsDiscovered;
    uint256 runeCode;
    string runeHash;
    string transmutation;
    address credit;
    uint256[] glyph;
    uint24[] colors;
    address metadataAddress;
    string hiddenLeyLines;
  }

  uint256 public constant FIRST_OPEN_VIBES_ID = 7778;
  address public constant VIBES_GENESIS = 0x6c7C97CaFf156473F6C9836522AE6e1d6448Abe7;
  address public constant VIBES_OPEN = 0xF3FCd0F025c21F087dbEB754516D2AD8279140Fc;

  uint8 public constant CURIO_SUPPLY = 64;
  uint256 public constant CURIO_TITHE = 80000000000000000; // 0.08 ETH

  uint32 public constant MANA_PER_YEAR = 100;
  uint32 public constant MANA_PER_YEAR_LV2 = 150;
  uint32 public constant SECONDS_PER_YEAR = 31536000;
  uint32 public constant MANA_FROM_REVELATION = 50;
  uint32 public constant MANA_FROM_DIVINATION = 50;
  uint32 public constant MANA_FROM_VIBRATION = 100;
  uint32 public constant MANA_COST_TO_UPGRADE = 150;

  uint256 public constant RELIC_SIZE = 64;
  uint256 public constant RELIC_SUPPLY = 1047;
  uint256 public constant TOTAL_SUPPLY = CURIO_SUPPLY + RELIC_SUPPLY;
  uint256 public constant RELIC_TITHE = 150000000000000000; // 0.15 ETH
  uint256 public constant INVENTORY_CAPACITY = 10;
  uint256 public constant BYTES_PER_RELICHASH = 3;
  uint256 public constant BYTES_PER_BLOCKHASH = 32;
  uint256 public constant HALF_POSSIBILITY_SPACE = (16**6) / 2;
  bytes32 public constant RELICHASH_MASK = 0x0000000000000000000000000000000000000000000000000000000000ffffff;
  uint256 public constant RELIC_DISCOUNT_GENESIS = 120000000000000000; // 0.12 ETH
  uint256 public constant RELIC_DISCOUNT_OPEN = 50000000000000000; // 0.05 ETH

  uint256 public constant RELIQUARY_CHAMBER_OUTSIDE = 0;
  uint256 public constant RELIQUARY_CHAMBER_GUARDIANS_HALL = 1;
  uint256 public constant RELIQUARY_CHAMBER_INNER_SANCTUM = 2;
  uint256 public constant RELIQUARY_CHAMBER_DIVINITYS_END = 3;
  uint256 public constant RELIQUARY_CHAMBER_CHAMPIONS_VAULT = 4;
  uint256 public constant ELEMENTAL_GUARDIAN_DNA = 88888888;
  uint256 public constant GRAIL_ID_NONE = 0;
  uint256 public constant GRAIL_ID_NATURE = 1;
  uint256 public constant GRAIL_ID_LIGHT = 2;
  uint256 public constant GRAIL_ID_WATER = 3;
  uint256 public constant GRAIL_ID_EARTH = 4;
  uint256 public constant GRAIL_ID_WIND = 5;
  uint256 public constant GRAIL_ID_ARCANE = 6;
  uint256 public constant GRAIL_ID_SHADOW = 7;
  uint256 public constant GRAIL_ID_FIRE = 8;
  uint256 public constant GRAIL_COUNT = 8;
  uint256 public constant GRAIL_DISTRIBUTION = 100;
  uint8 public constant SECRETS_OF_THE_GRAIL = 128;
  uint8 public constant MODE_TRANSMUTE_ELEMENT = 1;
  uint8 public constant MODE_CREATE_GLYPH = 2;
  uint8 public constant MODE_IMAGINE_COLORS = 3;

  uint256 public constant MAX_COLOR_INTS = 10;

  string public constant ROLL_ELEMENT = 'ELEMENT';
  string public constant ROLL_PALETTE = 'PALETTE';
  string public constant ROLL_SHUFFLE = 'SHUFFLE';
  string public constant ROLL_RED = 'RED';
  string public constant ROLL_GREEN = 'GREEN';
  string public constant ROLL_BLUE = 'BLUE';
  string public constant ROLL_REDSIGN = 'REDSIGN';
  string public constant ROLL_GREENSIGN = 'GREENSIGN';
  string public constant ROLL_BLUESIGN = 'BLUESIGN';
  string public constant ROLL_RANDOMCOLOR = 'RANDOMCOLOR';
  string public constant ROLL_RELICTYPE = 'RELICTYPE';
  string public constant ROLL_STYLE = 'STYLE';
  string public constant ROLL_COLORCOUNT = 'COLORCOUNT';
  string public constant ROLL_SPEED = 'SPEED';
  string public constant ROLL_GRAVITY = 'GRAVITY';
  string public constant ROLL_DISPLAY = 'DISPLAY';
  string public constant ROLL_GRAILS = 'GRAILS';
  string public constant ROLL_RUNEFLUX = 'RUNEFLUX';
  string public constant ROLL_CORRUPTION = 'CORRUPTION';

  string public constant RELIC_TYPE_GRAIL = 'Grail';
  string public constant RELIC_TYPE_CURIO = 'Curio';
  string public constant RELIC_TYPE_FOCUS = 'Focus';
  string public constant RELIC_TYPE_AMULET = 'Amulet';
  string public constant RELIC_TYPE_TALISMAN = 'Talisman';
  string public constant RELIC_TYPE_TRINKET = 'Trinket';

  string public constant GLYPH_TYPE_GRAIL = 'Origin';
  string public constant GLYPH_TYPE_CUSTOM = 'Divine';
  string public constant GLYPH_TYPE_NONE = 'None';

  string public constant ELEM_NATURE = 'Nature';
  string public constant ELEM_LIGHT = 'Light';
  string public constant ELEM_WATER = 'Water';
  string public constant ELEM_EARTH = 'Earth';
  string public constant ELEM_WIND = 'Wind';
  string public constant ELEM_ARCANE = 'Arcane';
  string public constant ELEM_SHADOW = 'Shadow';
  string public constant ELEM_FIRE = 'Fire';

  string public constant ANY_PAL_CUSTOM = 'Divine';

  string public constant NAT_PAL_JUNGLE = 'Jungle';
  string public constant NAT_PAL_CAMOUFLAGE = 'Camouflage';
  string public constant NAT_PAL_BIOLUMINESCENCE = 'Bioluminescence';

  string public constant NAT_ESS_FOREST = 'Forest';
  string public constant NAT_ESS_LIFE = 'Life';
  string public constant NAT_ESS_SWAMP = 'Swamp';
  string public constant NAT_ESS_WILDBLOOD = 'Wildblood';
  string public constant NAT_ESS_SOUL = 'Soul';

  string public constant LIG_PAL_PASTEL = 'Pastel';
  string public constant LIG_PAL_INFRARED = 'Infrared';
  string public constant LIG_PAL_ULTRAVIOLET = 'Ultraviolet';

  string public constant LIG_ESS_HEAVENLY = 'Heavenly';
  string public constant LIG_ESS_FAE = 'Fae';
  string public constant LIG_ESS_PRISMATIC = 'Prismatic';
  string public constant LIG_ESS_RADIANT = 'Radiant';
  string public constant LIG_ESS_PHOTONIC = 'Photonic';

  string public constant WAT_PAL_FROZEN = 'Frozen';
  string public constant WAT_PAL_DAWN = 'Dawn';
  string public constant WAT_PAL_OPALESCENT = 'Opalescent';

  string public constant WAT_ESS_TIDAL = 'Tidal';
  string public constant WAT_ESS_ARCTIC = 'Arctic';
  string public constant WAT_ESS_STORM = 'Storm';
  string public constant WAT_ESS_ILLUVIAL = 'Illuvial';
  string public constant WAT_ESS_UNDINE = 'Undine';

  string public constant EAR_PAL_COAL = 'Coal';
  string public constant EAR_PAL_SILVER = 'Silver';
  string public constant EAR_PAL_GOLD = 'Gold';

  string public constant EAR_ESS_MINERAL = 'Mineral';
  string public constant EAR_ESS_CRAGGY = 'Craggy';
  string public constant EAR_ESS_DWARVEN = 'Dwarven';
  string public constant EAR_ESS_GNOMIC = 'Gnomic';
  string public constant EAR_ESS_CRYSTAL = 'Crystal';

  string public constant WIN_PAL_BERRY = 'Berry';
  string public constant WIN_PAL_THUNDER = 'Thunder';
  string public constant WIN_PAL_AERO = 'Aero';

  string public constant WIN_ESS_SYLPHIC = 'Sylphic';
  string public constant WIN_ESS_VISCERAL = 'Visceral';
  string public constant WIN_ESS_FROSTED = 'Frosted';
  string public constant WIN_ESS_ELECTRIC = 'Electric';
  string public constant WIN_ESS_MAGNETIC = 'Magnetic';

  string public constant ARC_PAL_FROSTFIRE = 'Frostfire';
  string public constant ARC_PAL_COSMIC = 'Cosmic';
  string public constant ARC_PAL_COLORLESS = 'Colorless';

  string public constant ARC_ESS_MAGIC = 'Magic';
  string public constant ARC_ESS_ASTRAL = 'Astral';
  string public constant ARC_ESS_FORBIDDEN = 'Forbidden';
  string public constant ARC_ESS_RUNIC = 'Runic';
  string public constant ARC_ESS_UNKNOWN = 'Unknown';

  string public constant SHA_PAL_DARKNESS = 'Darkness';
  string public constant SHA_PAL_VOID = 'Void';
  string public constant SHA_PAL_UNDEAD = 'Undead';

  string public constant SHA_ESS_NIGHT = 'Night';
  string public constant SHA_ESS_FORGOTTEN = 'Forgotten';
  string public constant SHA_ESS_ABYSSAL = 'Abyssal';
  string public constant SHA_ESS_EVIL = 'Evil';
  string public constant SHA_ESS_LOST = 'Lost';

  string public constant FIR_PAL_HEAT = 'Heat';
  string public constant FIR_PAL_EMBER = 'Ember';
  string public constant FIR_PAL_CORRUPTED = 'Corrupted';

  string public constant FIR_ESS_INFERNAL = 'Infernal';
  string public constant FIR_ESS_MOLTEN = 'Molten';
  string public constant FIR_ESS_ASHEN = 'Ashen';
  string public constant FIR_ESS_DRACONIC = 'Draconic';
  string public constant FIR_ESS_CELESTIAL = 'Celestial';

  string public constant STYLE_SMOOTH = 'Smooth';
  string public constant STYLE_PAJAMAS = 'Pajamas';
  string public constant STYLE_SILK = 'Silk';
  string public constant STYLE_SKETCH = 'Sketch';

  string public constant SPEED_ZEN = 'Zen';
  string public constant SPEED_TRANQUIL = 'Tranquil';
  string public constant SPEED_NORMAL = 'Normal';
  string public constant SPEED_FAST = 'Fast';
  string public constant SPEED_SWIFT = 'Swift';
  string public constant SPEED_HYPER = 'Hyper';

  string public constant GRAV_LUNAR = 'Lunar';
  string public constant GRAV_ATMOSPHERIC = 'Atmospheric';
  string public constant GRAV_LOW = 'Low';
  string public constant GRAV_NORMAL = 'Normal';
  string public constant GRAV_HIGH = 'High';
  string public constant GRAV_MASSIVE = 'Massive';
  string public constant GRAV_STELLAR = 'Stellar';
  string public constant GRAV_GALACTIC = 'Galactic';

  string public constant DISPLAY_NORMAL = 'Normal';
  string public constant DISPLAY_MIRRORED = 'Mirrored';
  string public constant DISPLAY_UPSIDEDOWN = 'UpsideDown';
  string public constant DISPLAY_MIRROREDUPSIDEDOWN = 'MirroredUpsideDown';

}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

/// @notice The Reliquary Utility Methods
library TRUtils {

  function random(string memory input) public pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(input)));
  }

  function getColorCode(uint256 color) public pure returns (string memory) {
    bytes16 hexChars = '0123456789abcdef';
    uint256 r1 = (color >> uint256(20)) & uint256(15);
    uint256 r2 = (color >> uint256(16)) & uint256(15);
    uint256 g1 = (color >> uint256(12)) & uint256(15);
    uint256 g2 = (color >> uint256(8)) & uint256(15);
    uint256 b1 = (color >> uint256(4)) & uint256(15);
    uint256 b2 = color & uint256(15);
    bytes memory code = new bytes(6);
    code[0] = hexChars[r1];
    code[1] = hexChars[r2];
    code[2] = hexChars[g1];
    code[3] = hexChars[g2];
    code[4] = hexChars[b1];
    code[5] = hexChars[b2];
    return string(code);
  }

  function compare(string memory a, string memory b) public pure returns (bool) {
    if (bytes(a).length != bytes(b).length) {
      return false;
    } else {
      return keccak256(bytes(a)) == keccak256(bytes(b));
    }
  }

  function toString(uint256 value) public pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

    if (value == 0) {
      return '0';
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

  // https://ethereum.stackexchange.com/a/8447
  function toAsciiString(address x) public pure returns (string memory) {
    bytes memory s = new bytes(40);
    for (uint i = 0; i < 20; i++) {
      bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
      bytes1 hi = bytes1(uint8(b) / 16);
      bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
      s[2*i] = char(hi);
      s[2*i+1] = char(lo);
    }
    return string(s);
  }

  function char(bytes1 b) internal pure returns (bytes1 c) {
    if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
    else return bytes1(uint8(b) + 0x57);
  }

  // https://stackoverflow.com/a/69302348/424107
  function toCapsHexString(uint256 i) internal pure returns (string memory) {
    if (i == 0) return '0';
    uint j = i;
    uint length;
    while (j != 0) {
      length++;
      j = j >> 4;
    }
    uint mask = 15;
    bytes memory bstr = new bytes(length);
    uint k = length;
    while (i != 0) {
      uint curr = (i & mask);
      bstr[--k] = curr > 9 ?
        bytes1(uint8(55 + curr)) :
        bytes1(uint8(48 + curr)); // 55 = 65 - 10
      i = i >> 4;
    }
    return string(bstr);
  }

}