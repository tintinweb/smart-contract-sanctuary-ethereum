// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";
import {IOneWar} from "./interfaces/IOneWar.sol";
import {OneWarGold} from "./OneWarGold.sol";
import {OneWarCouncil} from "./OneWarCouncil.sol";
import {OneWarModifier} from "./OneWarModifier.sol";
import {OneWarDescriptor} from "./OneWarDescriptor.sol";
import {Seeder} from "./libs/Seeder.sol";
import {Math} from "./libs/Math.sol";

/**
 * Voyagers of the metaverse are on the lookout for land.
 * They scout for Settlements that are rich with $GOLD treasure
 * and filled with miners who will work hard to extract it,
 * one block at a time. But danger awaits them.
 * War is about to strike out. They must be weary
 * of other voyagers, thirsty for glory,
 * who desire to conquer their Settlements and
 * steal their precious $GOLD.
 *
 * Once the war begins, so does $GOLD treasure mining.
 * As soon as the voyagers have redeemed their mined $GOLD,
 * they can use it to build an army. Towers that defend
 * their Settlement's walls; catapults that destroy enemy
 * towers; and soldiers who can be used in both defense
 * and offense.
 *
 * To settle on their scouted land, voyagers pay a fee to
 * the OneWar Treasury. In return, they can become members
 * of the council that controls the Treasury, should they
 * choose to accept the honor.
 *
 * Upon settling, a voyager's new Settlement is temporarily
 * protected by a sacred sanctuary period, preventing it
 * from falling under attack. It is the duty of
 * the voyager and any appointed co-rulers to defend it,
 * thereafter.
 *
 * Let the war for glory begin!
 */

contract OneWar is IOneWar, OneWarModifier, ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter public totalSupply;
    OneWarGold public gold;
    OneWarCouncil public council;
    uint256 public warBegins;
    bool public override hasWarCountdownBegun;

    mapping(address => uint256) public scoutingEnds;
    mapping(uint256 => Settlement) public settlements;

    uint256 public constant MAX_SUPPLY = 10_000;

    uint256 public constant SCOUTING_COST = 1 * 10**17;
    uint256 public constant SCOUTING_DURATION = 4;
    uint256 public constant MAX_SCOUTING_DURATION = 255;

    uint256 public constant AVERAGE_SANCTUARY = 3000;
    uint256 public constant AVERAGE_TREASURE = 5000;
    uint256 public constant AVERAGE_MINERS = 100;

    uint256 public constant MINING_RATE = 4 * 10**14;

    uint32 public constant SOLDIER_COST = 1;
    uint32 public constant TOWER_COST = 6;
    uint32 public constant CATAPULT_COST = 4;

    uint32 public constant SOLDIER_STRENGTH = 1;
    uint32 public constant TOWER_STRENGTH = 20;
    uint32 public constant CATAPULT_STRENGTH = 5;

    uint8 public constant GOLD_DECIMALS = 18;
    uint256 public constant GOLD_DENOMINATION = 10**GOLD_DECIMALS;

    uint256 public constant MOTTO_CHANGE_COST = 10 * GOLD_DENOMINATION;
    uint8 public constant MOTTO_CHARACTER_LIMIT = 50;

    uint32 public constant PREWAR_DURATION = 20_000;

    modifier whenWarHasBegun() {
        require(block.number >= warBegins, "war has not begun yet");
        _;
    }

    modifier isCallerRulerOrCoruler(uint256 _settlement) {
        require(_isApprovedOrOwner(msg.sender, _settlement), "caller is not settlement ruler or co-ruler");
        _;
    }

    modifier isLocationSettled(uint256 _settlement) {
        require(_exists(_settlement), "location is not settled");
        _;
    }

    modifier whenWarCountdownHasBegun() {
        require(hasWarCountdownBegun, "war countdown has not begun");
        _;
    }

    constructor(address payable _treasury) ERC721("OneWar Settlement", "OWS") OneWarModifier(_treasury) {
        warBegins = 2**256 - 1;
        gold = new OneWarGold();
        descriptor = new OneWarDescriptor(this);
        council = new OneWarCouncil(this);
    }

    /**
     * Prior to settling, voyagers make an offering
     * to the Treasury. Scouts are subsequently
     * dispatched to seek out undiscovered land.
     * Scouting lasts 4 blocks and can be initiated before
     * the war has begun. If all 10,000 Settlements have been
     * occupied, voyagers will be unable to settle.
     */
    function scout() public payable override {
        require(msg.value >= SCOUTING_COST, "inadequate offering");
        scoutingEnds[msg.sender] = block.number + SCOUTING_DURATION;
        emit Scout(msg.sender, scoutingEnds[msg.sender]);
    }

    /**
     * Between 4 and 256 blocks after scouting has been initiated,
     * a voyager can settle into the land that was discovered by
     * the commissioned scouts. It is during this ritual
     * that the voyager gets crowned as the Settlement's ruler,
     * granted full authority over the new-found land.
     */
    function settle() public override {
        require(scoutingEnds[msg.sender] != 0, "location has not been scouted");
        require(block.number > scoutingEnds[msg.sender], "insufficient blocks since scouting began");
        require(
            block.number - scoutingEnds[msg.sender] <= MAX_SCOUTING_DURATION,
            "too many blocks since scouting began"
        );
        _tokenIds.increment();
        uint256 settlementId = _tokenIds.current();
        require(settlementId <= MAX_SUPPLY, "all land has been settled");

        uint256 seed = uint256(keccak256(abi.encodePacked(msg.sender, blockhash(scoutingEnds[msg.sender]))));
        settlements[settlementId].genesis = block.number;
        settlements[settlementId].seed = seed;
        settlements[settlementId].founder = msg.sender;
        settlements[settlementId].glory = 0;
        settlements[settlementId].sanctuary = Seeder.generateNumber(
            AVERAGE_SANCTUARY,
            Seeder.pluck("sanctuary", seed)
        );
        settlements[settlementId].treasure =
            Seeder.generateNumber(AVERAGE_TREASURE, Seeder.pluck("treasure", seed)) *
            GOLD_DENOMINATION;
        settlements[settlementId].miners = Seeder.generateNumber(AVERAGE_MINERS, Seeder.pluck("miners", seed));
        _mint(msg.sender, settlementId);
        totalSupply.increment();
        scoutingEnds[msg.sender] = 0;

        emit Settle(msg.sender, settlementId);
    }

    /**
     * Rulers are given the right to even burn their Settlement
     * to the ground.
     */
    function burn(uint256 _settlement) public override isCallerRulerOrCoruler(_settlement) {
        _burn(_settlement);
        totalSupply.decrement();
        emit Burn(_settlement);
    }

    /**
     * It is up to the Treasury to announce when
     * the war is about to begin.
     */
    function commenceWarCountdown() public override onlyTreasury {
        require(!hasWarCountdownBegun, "war countdown has already begun");
        hasWarCountdownBegun = true;
        warBegins = block.number + PREWAR_DURATION;
    }

    /**
     * As soon as the war begins, miners get to work.
     * As they constantly dig for more $GOLD, their
     * progress can be monitored here.
     */
    function redeemableGold(uint256 _settlement) public view override isLocationSettled(_settlement) returns (uint256) {
        uint256 miningBegins = Math.max(settlements[_settlement].genesis, warBegins);
        if (block.number < miningBegins) {
            return 0;
        }

        uint256 settlementTotal = uint256(block.number - miningBegins) * settlements[_settlement].miners * MINING_RATE;
        if (settlements[_settlement].treasure < settlementTotal) {
            settlementTotal = settlements[_settlement].treasure;
        }

        return settlementTotal - settlements[_settlement].goldRedeemed;
    }

    /**
     * Rulers can redeem their mined $GOLD at any point.
     * It is only once they have redeemed their $GOLD that
     * they can spend it on their Settlement's operations.
     */
    function redeemGold(uint256[] calldata _settlements) public override whenWarHasBegun {
        uint256 totalAmount = 0;

        for (uint16 i = 0; i < _settlements.length; ++i) {
            uint256 locAmount = redeemableGold(_settlements[i]);
            settlements[_settlements[i]].goldRedeemed += locAmount;
            totalAmount += locAmount;
            require(_isApprovedOrOwner(msg.sender, _settlements[i]), "caller is not settlement ruler or co-ruler");
        }

        gold.mint(msg.sender, totalAmount);
    }

    /**
     * $GOLD can be consumed to create army units.
     * Their costs can be calculated here.
     */
    function armyCost(
        uint32 _soldiers,
        uint32 _towers,
        uint32 _catapults
    ) public pure override returns (uint256) {
        return
            uint256(SOLDIER_COST * _soldiers + TOWER_COST * _towers + CATAPULT_COST * _catapults) * GOLD_DENOMINATION;
    }

    /**
     * Any portion of a ruler's $GOLD can be consumed
     * to build an army for their Settlement.
     */
    function buildArmy(
        uint256 _settlement,
        uint32 _soldiers,
        uint32 _towers,
        uint32 _catapults
    ) public override whenWarHasBegun {
        gold.burn(msg.sender, armyCost(_soldiers, _towers, _catapults));
        settlements[_settlement].soldiers += _soldiers;
        settlements[_settlement].towers += _towers;
        settlements[_settlement].catapults += _catapults;

        emit BuildArmy(_settlement, _soldiers, _towers, _catapults);
    }

    /**
     * Rulers can relocate army units to other Settlements that
     * they may or may not control.
     */
    function moveArmy(
        uint256 _sourceSettlement,
        uint256 _destinationSettlement,
        uint32 _soldiers,
        uint32 _catapults
    ) public override whenWarHasBegun isCallerRulerOrCoruler(_sourceSettlement) {
        require(
            settlements[_sourceSettlement].soldiers >= _soldiers &&
                settlements[_sourceSettlement].catapults >= _catapults,
            "insufficient army units"
        );

        settlements[_sourceSettlement].soldiers -= _soldiers;
        settlements[_destinationSettlement].soldiers += _soldiers;
        settlements[_sourceSettlement].catapults -= _catapults;
        settlements[_destinationSettlement].catapults += _catapults;

        emit MoveArmy(_sourceSettlement, _destinationSettlement, _soldiers, _catapults);
    }

    /**
     * Rulers can dispatch multiple army units to multiple
     * Settlements, at once.
     */
    function multiMoveArmy(ArmyMove[] calldata _moves) public override whenWarHasBegun {
        for (uint256 i = 0; i < _moves.length; ++i) {
            moveArmy(_moves[i].source, _moves[i].destination, _moves[i].soldiers, _moves[i].catapults);
        }
    }

    /**
     * A Settlement's catapults and soldiers can be used
     * to attack another Settlement. If the attacking forces
     * overwhelm the defensive forces, then the Settlement under
     * attack is successfully conquered and
     * authority is transferred to the conqueror.
     *
     * Attacking catapults first attempt to take down the
     * defending towers. Subsequently, the attacking soldiers
     * target any remaining towers and lastly any defending
     * soldiers.
     *
     * A successful offensive attack must therefore be
     * orchestrated with enough catapults and soldiers to
     * annihilate all the defensive towers and soldiers.
     */
    function attack(
        uint256 _attackingSettlement,
        uint256 _defendingSettlement,
        uint32 _soldiers,
        uint32 _catapults
    )
        public
        override
        whenWarHasBegun
        isCallerRulerOrCoruler(_attackingSettlement)
        isLocationSettled(_defendingSettlement)
    {
        require(
            settlements[_attackingSettlement].soldiers >= _soldiers &&
                settlements[_attackingSettlement].catapults >= _catapults,
            "insufficient attacking army units"
        );
        require(
            Math.max(settlements[_defendingSettlement].genesis, warBegins) +
                settlements[_defendingSettlement].sanctuary <
                block.number,
            "defending settlement is in sanctuary period"
        );

        uint256 attackingSanctuaryBegins = Math.max(settlements[_attackingSettlement].genesis, warBegins);
        if (attackingSanctuaryBegins + settlements[_attackingSettlement].sanctuary > block.number) {
            settlements[_attackingSettlement].sanctuary = block.number - attackingSanctuaryBegins;
        }

        DefenderAssets memory defenderAssets;
        AttackerAssets memory attackerAssets;

        defenderAssets.soldiers = settlements[_defendingSettlement].soldiers;
        defenderAssets.towers = settlements[_defendingSettlement].towers;

        attackerAssets.soldiers = _soldiers;
        attackerAssets.catapults = _catapults;

        settlements[_attackingSettlement].soldiers -= _soldiers;
        settlements[_attackingSettlement].catapults -= _catapults;

        if (_catapults * CATAPULT_STRENGTH > TOWER_STRENGTH * settlements[_defendingSettlement].towers) {
            _catapults -= (TOWER_STRENGTH / CATAPULT_STRENGTH) * settlements[_defendingSettlement].towers;
            settlements[_defendingSettlement].towers = 0;
        } else {
            settlements[_defendingSettlement].towers -= _catapults / (TOWER_STRENGTH / CATAPULT_STRENGTH);
            _catapults = 0;
        }

        if (_soldiers * SOLDIER_STRENGTH > TOWER_STRENGTH * settlements[_defendingSettlement].towers) {
            _soldiers -= (TOWER_STRENGTH / SOLDIER_STRENGTH) * settlements[_defendingSettlement].towers;
            settlements[_defendingSettlement].towers = 0;
        } else {
            settlements[_defendingSettlement].towers -= _soldiers / (TOWER_STRENGTH / SOLDIER_STRENGTH);
            _soldiers = 0;
        }

        if (_soldiers > settlements[_defendingSettlement].soldiers) {
            _soldiers -= settlements[_defendingSettlement].soldiers;

            settlements[_defendingSettlement].glory +=
                (attackerAssets.soldiers - _soldiers) *
                SOLDIER_COST +
                (attackerAssets.catapults - _catapults) *
                CATAPULT_COST;
            settlements[_attackingSettlement].glory +=
                defenderAssets.soldiers *
                SOLDIER_COST +
                defenderAssets.towers *
                TOWER_COST;

            settlements[_defendingSettlement].soldiers = _soldiers;
            settlements[_defendingSettlement].catapults = _catapults;
            emit SuccessfulAttack(_attackingSettlement, _defendingSettlement);
            _transfer(ownerOf(_defendingSettlement), msg.sender, _defendingSettlement);
        } else {
            settlements[_defendingSettlement].soldiers -= _soldiers;
            settlements[_defendingSettlement].catapults += _catapults;

            settlements[_defendingSettlement].glory +=
                attackerAssets.soldiers *
                SOLDIER_COST +
                (attackerAssets.catapults - _catapults) *
                CATAPULT_COST;
            settlements[_attackingSettlement].glory +=
                (defenderAssets.soldiers - settlements[_defendingSettlement].soldiers) *
                SOLDIER_COST +
                (defenderAssets.towers - settlements[_defendingSettlement].towers) *
                TOWER_COST;

            emit FailedAttack(_attackingSettlement, _defendingSettlement);
        }
    }

    /**
     * Here lies the  number of blocks remaining until
     * a Settlement's sacred sanctuary period ends.
     */
    function blocksUntilSanctuaryEnds(uint256 _settlement)
        public
        view
        override
        isLocationSettled(_settlement)
        whenWarCountdownHasBegun
        returns (uint256)
    {
        uint256 sanctuaryBegins = Math.max(settlements[_settlement].genesis, warBegins);
        if (sanctuaryBegins + settlements[_settlement].sanctuary < block.number) {
            return 0;
        }

        return sanctuaryBegins + settlements[_settlement].sanctuary - block.number;
    }

    /**
     * The number of blocks remaining until the OneWar begins
     * can be viewed here.
     */
    function blocksUntilWarBegins() public view override whenWarCountdownHasBegun returns (uint256) {
        if (warBegins < block.number) {
            return 0;
        }

        return warBegins - block.number;
    }

    /**
     * Rulers may pay $GOLD to modify their
     * Settlement's motto.
     */
    function changeMotto(uint256 _settlement, string memory _newMotto)
        public
        override
        isCallerRulerOrCoruler(_settlement)
    {
        require(bytes(_newMotto).length <= MOTTO_CHARACTER_LIMIT, "motto is too long");

        gold.burn(msg.sender, MOTTO_CHANGE_COST);
        settlements[_settlement].motto = _newMotto;

        emit ChangeMotto(_settlement, _newMotto);
    }

    /**
     * The OneWar Treasury can claim their rightful offerings
     * at any time.
     */
    function redeemFundsToOneWarTreasury() external override {
        (bool redeemed, ) = treasury.call{value: address(this).balance}("");
        require(redeemed, "failed to redeem funds");
    }

    /**
     * Each Settlement has a plaque inscribed with its traits.
     */
    function tokenURI(uint256 _settlement) public view override isLocationSettled(_settlement) returns (string memory) {
        return descriptor.tokenURI(_settlement);
    }

    /**
     * Discover a particular Settlement's traits here.
     */
    function settlementTraits(uint256 _settlement)
        external
        view
        override
        isLocationSettled(_settlement)
        returns (Settlement memory)
    {
        return settlements[_settlement];
    }

    /**
     * Discover whether a voyager is a certain Settlement's
     * ruler or co-ruler.
     */
    function isRulerOrCoruler(address _address, uint256 _settlement) public view override returns (bool) {
        return _isApprovedOrOwner(_address, _settlement);
    }

    /**
     * Discover whether a specific area has been settled or
     * remains undiscovered.
     */
    function isSettled(uint256 _settlement) public view override returns (bool) {
        return _exists(_settlement);
    }
}

/**
 * War has no winners, except in honor and glory.
 * The glory of OneWar Settlements is measured in bloodshed.
 */

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
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
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
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
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
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
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

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
        safeTransferFrom(from, to, tokenId, "");
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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
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
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
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
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface IOneWar {
    struct Settlement {
        uint32 soldiers;
        uint32 towers;
        uint32 catapults;
        uint256 goldRedeemed;
        uint256 genesis;
        uint256 seed;
        address founder;
        string motto;
        uint32 glory;
        uint256 sanctuary;
        uint256 treasure;
        uint256 miners;
    }

    struct DefenderAssets {
        uint32 soldiers;
        uint32 towers;
    }

    struct AttackerAssets {
        uint32 soldiers;
        uint32 catapults;
    }

    struct ArmyMove {
        uint256 source;
        uint256 destination;
        uint32 soldiers;
        uint32 catapults;
    }

    event Scout(address _by, uint256 indexed _blockNumber);

    event Settle(address _by, uint256 indexed _settlement);

    event Burn(uint256 indexed _settlement);

    event BuildArmy(uint256 indexed _settlement, uint32 _soldiers, uint32 _towers, uint32 _catapults);

    event MoveArmy(
        uint256 indexed _sourceSettlement,
        uint256 indexed _destinationSettlement,
        uint32 _soldiers,
        uint32 _catapults
    );

    event SuccessfulAttack(uint256 indexed _attackingSettlement, uint256 indexed _defendingSettlement);

    event FailedAttack(uint256 indexed _attackingSettlement, uint256 indexed _defendingSettlement);

    event ChangeMotto(uint256 indexed _settlement, string _motto);

    function hasWarCountdownBegun() external view returns (bool);

    function scout() external payable;

    function settle() external;

    function burn(uint256 _settlement) external;

    function commenceWarCountdown() external;

    function redeemableGold(uint256 _settlement) external view returns (uint256);

    function redeemGold(uint256[] calldata _settlements) external;

    function armyCost(uint32 _soldiers, uint32 _towers, uint32 _catapults) external pure returns (uint256);

    function buildArmy(uint256 _settlement, uint32 _soldiers, uint32 _towers, uint32 _catapults) external;

    function moveArmy(uint256 _sourceSettlement, uint256 _destinationSettlement, uint32 _soldiers, uint32 _catapults) external;

    function multiMoveArmy(ArmyMove[] calldata _moves) external;

    function attack(uint256 _attackingSettlement, uint256 _defendingSettlement, uint32 _soldiers, uint32 _catapults) external;

    function blocksUntilSanctuaryEnds(uint256 _settlement) external view returns (uint256);

    function blocksUntilWarBegins() external view returns (uint256);

    function changeMotto(uint256 _settlement, string memory _newMotto) external;

    function redeemFundsToOneWarTreasury() external;

    function settlementTraits(uint256 _settlement) external view returns (Settlement memory);

    function isRulerOrCoruler(address _address, uint256 _settlement) external view returns (bool);

    function isSettled(uint256 _settlement) external view returns (bool);
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IOneWarGold} from "./interfaces/IOneWarGold.sol";

contract OneWarGold is IOneWarGold, ERC20 {
    address public oneWar;

    constructor() ERC20("OneWar Gold", "GOLD") {
        oneWar = msg.sender;
    }

    function mint(address _to, uint256 _value) public override {
        require(msg.sender == oneWar, "unauthorized caller");
        _mint(_to, _value);
    }

    function burn(address _from, uint256 _value) public override {
        require(msg.sender == _from || msg.sender == oneWar, "unauthorized caller");
        _burn(_from, _value);
    }
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IOneWar} from "./interfaces/IOneWar.sol";
import {IOneWarCouncil} from "./interfaces/IOneWarCouncil.sol";

contract OneWarCouncil is IOneWarCouncil, ERC20 {
    IOneWar public oneWar;
    mapping(uint256 => bool) public redeemed;

    uint8 public constant GOLD_DECIMALS = 18;
    uint256 public constant GOLD_DENOMINATION = 10**GOLD_DECIMALS;

    constructor(IOneWar _oneWar) ERC20("OneWar Council", "OWC") {
        oneWar = _oneWar;
    }

    function burn(uint256 _value) public override {
        _burn(msg.sender, _value);
    }

    function redeemableCouncilTokens(uint256[] calldata _settlements) public view override returns (uint256) {
        uint256 amount = 0;
        for (uint256 i = 0; i < _settlements.length; ++i) {
            require(oneWar.isSettled(_settlements[i]), "location is not settled");
            if (!redeemed[_settlements[i]]) {
                amount += 1;
            }
        }

        return amount;
    }

    function redeemCouncilTokens(uint256[] calldata _settlements) public override {
        uint256 amount = 0;
        for (uint256 i = 0; i < _settlements.length; ++i) {
            require(oneWar.isSettled(_settlements[i]), "location is not settled");
            require(oneWar.isRulerOrCoruler(msg.sender, _settlements[i]), "caller is not settlement ruler or co-ruler");
            require(!redeemed[_settlements[i]], "council tokens have already been redeemed");
            redeemed[_settlements[i]] = true;
            amount += 1;
        }

        _mint(msg.sender, amount * GOLD_DENOMINATION);
    }
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IOneWarDescriptor} from "./interfaces/IOneWarDescriptor.sol";
import {IOneWarModifier} from "./interfaces/IOneWarModifier.sol";

contract OneWarModifier is IOneWarModifier, Ownable {
    address payable public override treasury;
    bool public isDescriptorLocked;
    IOneWarDescriptor public override descriptor;

    modifier onlyTreasury() {
        require(msg.sender == treasury, "sender is not OneWar Treasury");
        _;
    }

    modifier whenDescriptorNotLocked() {
        require(!isDescriptorLocked, "descriptor is locked");
        _;
    }

    constructor(address payable _treasury) {
        treasury = _treasury;
    }

    function setTreasury(address payable _treasury) external override onlyTreasury {
        treasury = _treasury;
        emit TreasuryUpdated(_treasury);
    }

    function setDescriptor(IOneWarDescriptor _descriptor) external override onlyTreasury whenDescriptorNotLocked {
        descriptor = _descriptor;
        emit DescriptorUpdated(_descriptor);
    }

    function lockDescriptor() external override onlyTreasury whenDescriptorNotLocked {
        isDescriptorLocked = true;
        emit DescriptorLocked();
    }
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

import {IOneWarDescriptor} from "./interfaces/IOneWarDescriptor.sol";
import {IOneWar} from "./interfaces/IOneWar.sol";
import {NFTDescriptor} from "./libs/NFTDescriptor.sol";
import {Strings} from "./libs/Strings.sol";

contract OneWarDescriptor is IOneWarDescriptor {
    IOneWar public oneWar;

    constructor(IOneWar _oneWar) {
        oneWar = _oneWar;
    }

    function tokenURI(uint256 _settlement) external view override returns (string memory) {
        bool hasWarCountdownBegun = oneWar.hasWarCountdownBegun();
        NFTDescriptor.TokenURIParams memory params = NFTDescriptor.TokenURIParams({
            name: string(abi.encodePacked("Settlement #", Strings.toString(_settlement))),
            description: string(
                abi.encodePacked("Settlement #", Strings.toString(_settlement), " is a location in OneWar.")
            ),
            attributes: oneWar.settlementTraits(_settlement),
            extraAttributes: NFTDescriptor.ExtraAttributes({
                redeemableGold: oneWar.redeemableGold(_settlement),
                hasWarCountdownBegun: hasWarCountdownBegun,
                blocksUntilSanctuaryEnds: hasWarCountdownBegun ? oneWar.blocksUntilSanctuaryEnds(_settlement) : 0
            })
        });

        return NFTDescriptor.constructTokenURI(params);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

library Seeder {
    function pluck(string memory _prefix, uint256 _seed) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(_prefix, _seed)));
    }

    function generateNumber(uint256 _average, uint256 _seed) internal pure returns (uint256) {
        uint256 c = 0;
        uint256 lower = 4;
        uint256 upper = 10;

        while (_seed > 0) {
            uint256 x = _seed & 0xffffffff;
            x = x - ((x >> 1) & 0x55555555);
            x = (x & 0x33333333) + ((x >> 2) & 0x33333333);
            x = (x + (x >> 4)) & 0x0F0F0F0F;
            x = x + (x >> 8);
            x = x + (x >> 16);
            c += x & 0x0000003F;
            _seed >>= 32;
        }

        uint256 n = (c * _average) / 128;

        if (n < _average) {
            uint256 lhs = lower * n;
            uint256 rhs = (lower - 1) * _average;
            if (lhs < rhs) {
                return 0;
            }

            return lhs - rhs;
        }

        return upper * n - (upper - 1) * _average;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

library Math {
    function max(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return _a >= _b ? _a : _b;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
contract ERC20 is Context, IERC20, IERC20Metadata {
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
    constructor(string memory name_, string memory symbol_) {
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
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface IOneWarGold {
    function mint(address _to, uint256 _value) external;

    function burn(address _from, uint256 _value) external;
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

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface IOneWarCouncil {
    function burn(uint256 _value) external;

    function redeemableCouncilTokens(uint256[] calldata _settlements) external view returns (uint256);

    function redeemCouncilTokens(uint256[] calldata _settlements) external;
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

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {IOneWar} from "./IOneWar.sol";

interface IOneWarDescriptor {
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {IOneWarDescriptor} from "./IOneWarDescriptor.sol";

interface IOneWarModifier {
    event TreasuryUpdated(address payable _treasury);

    event DescriptorUpdated(IOneWarDescriptor _descriptor);

    event DescriptorLocked();

    function treasury() external view returns (address payable);

    function setTreasury(address payable _treasury) external;

    function descriptor() external view returns (IOneWarDescriptor);

    function setDescriptor(IOneWarDescriptor _descriptor) external;

    function lockDescriptor() external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {Base64} from "base64-sol/base64.sol";
import {IOneWar} from "../interfaces/IOneWar.sol";
import {Strings} from "./Strings.sol";

library NFTDescriptor {
    uint8 public constant GOLD_DECIMALS = 18;
    uint256 public constant GOLD_DENOMINATION = 10**GOLD_DECIMALS;

    struct ExtraAttributes {
        uint256 redeemableGold;
        bool hasWarCountdownBegun;
        uint256 blocksUntilSanctuaryEnds;
    }

    struct TokenURIParams {
        string name;
        string description;
        IOneWar.Settlement attributes;
        ExtraAttributes extraAttributes;
    }

    enum AttributeType {
        PROPERTY,
        RANKING,
        STAT
    }

    struct Attribute {
        AttributeType attributeType;
        string svgHeading;
        string attributeHeading;
        string value;
        bool onSVG;
    }

    function constructTokenURI(TokenURIParams memory _params) internal pure returns (string memory) {
        Attribute[] memory formattedAttributes = formatAttributes(_params.attributes, _params.extraAttributes);
        string memory motto = _params.attributes.motto;
        string memory image = generateSVGImage(formattedAttributes, motto);
        string memory attributes = generateAttributes(formattedAttributes, motto);

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                _params.name,
                                '","description":"',
                                _params.description,
                                '","image": "',
                                "data:image/svg+xml;base64,",
                                image,
                                '","attributes":',
                                attributes,
                                "}"
                            )
                        )
                    )
                )
            );
    }

    function formatGold(uint256 _gold) internal pure returns (string memory) {
        string memory integer = string(abi.encodePacked(Strings.toString(_gold / GOLD_DENOMINATION)));
        string memory decimal;
        for (uint8 i = 0; i < GOLD_DECIMALS; i++) {
            uint256 digit = (_gold / 10**i) % 10;
            if (digit != 0 || bytes(decimal).length != 0) {
                decimal = string(abi.encodePacked(Strings.toString(digit), decimal));
            }
        }

        if (bytes(decimal).length != 0) {
            return string(abi.encodePacked(integer, ".", decimal));
        }

        return integer;
    }

    function formatAttributes(IOneWar.Settlement memory _attributes, ExtraAttributes memory _extraAttributes)
        internal
        pure
        returns (Attribute[] memory)
    {
        Attribute[] memory attributes = new Attribute[](_extraAttributes.hasWarCountdownBegun ? 12 : 11);
        attributes[0] = Attribute(
            AttributeType.STAT,
            "Soldiers",
            "Soldiers",
            Strings.toString(_attributes.soldiers),
            true
        );
        attributes[1] = Attribute(AttributeType.STAT, "Towers", "Towers", Strings.toString(_attributes.towers), true);
        attributes[2] = Attribute(
            AttributeType.STAT,
            "Catapults",
            "Catapults",
            Strings.toString(_attributes.catapults),
            true
        );
        attributes[3] = Attribute(
            AttributeType.STAT,
            "Treasure",
            "$GOLD Treasure",
            formatGold(_attributes.treasure),
            true
        );
        attributes[4] = Attribute(
            AttributeType.STAT,
            "Miners",
            "$GOLD Miners",
            Strings.toString(_attributes.miners),
            true
        );
        attributes[5] = Attribute(
            AttributeType.STAT,
            "Redeemed",
            "$GOLD Redeemed",
            formatGold(_attributes.goldRedeemed),
            false
        );
        attributes[6] = Attribute(
            AttributeType.STAT,
            "Redeemable",
            "$GOLD Redeemable",
            formatGold(_extraAttributes.redeemableGold),
            true
        );
        attributes[7] = Attribute(
            AttributeType.PROPERTY,
            "Genesis",
            "Genesis Block",
            Strings.toString(_attributes.genesis),
            true
        );
        attributes[8] = Attribute(
            AttributeType.PROPERTY,
            "Founder",
            "Founder",
            Strings.toString(_attributes.founder),
            true
        );
        attributes[9] = Attribute(AttributeType.RANKING, "Glory", "Glory", Strings.toString(_attributes.glory), true);
        attributes[10] = Attribute(
            AttributeType.STAT,
            "Sanctuary",
            "Sanctuary Duration",
            Strings.toString(_attributes.sanctuary),
            false
        );

        if (_extraAttributes.hasWarCountdownBegun) {
            attributes[11] = Attribute(
                AttributeType.STAT,
                "Sanctuary Remaining",
                "Blocks Until Sanctuary Ends",
                Strings.toString(_extraAttributes.blocksUntilSanctuaryEnds),
                false
            );
        }

        return attributes;
    }

    function generateSVGImage(Attribute[] memory _attributes, string memory _motto)
        internal
        pure
        returns (string memory)
    {
        string memory svg = '<svg xmlns="http://www.w3.org/2000/svg" '
        'preserveAspectRatio="xMinYMin meet" '
        'viewBox="0 0 300 300">'
        "<style>"
        'text { fill: #646464; font-family: "Courier New", monospace; font-size: 12px; } '
        ".motto { font-size: 8px; text-anchor: middle; font-style: italic; font-weight: bold; } "
        ".right { text-transform: uppercase; } "
        ".left > text { text-anchor: end; }"
        "</style>"
        "<rect "
        'width="100%" '
        'height="100%" '
        'fill="#eee"'
        "/>";

        if (bytes(_motto).length > 0) {
            svg = string(abi.encodePacked(svg, '<text x="150" y="22" class="motto">', _motto, "</text>"));
        }

        string memory headings = '<g class="right" transform="translate(170,55)">';
        string memory values = '<g class="left" transform="translate(130,55)">';

        uint16 _y = 0;
        for (uint8 i = 0; i < _attributes.length; i++) {
            Attribute memory attribute = _attributes[i];
            if (!attribute.onSVG) {
                continue;
            }

            string memory textOpen = string(abi.encodePacked('<text y="', Strings.toString(_y), '">'));

            headings = string(abi.encodePacked(headings, textOpen, attribute.svgHeading, "</text>"));

            string memory value = Strings.equal(attribute.svgHeading, "Founder")
                ? Strings.truncateAddressString(attribute.value)
                : attribute.value;

            values = string(abi.encodePacked(values, textOpen, value, "</text>"));

            _y += 25;
        }

        headings = string(abi.encodePacked(headings, "</g>"));
        values = string(abi.encodePacked(values, "</g>"));

        svg = string(
            abi.encodePacked(
                svg,
                "<path "
                'stroke="#696969" '
                'stroke-width="1.337" '
                'stroke-dasharray="10,15" '
                'stroke-linecap="round" '
                'd="M150 46 L150 256"'
                "/>",
                headings,
                values,
                "</svg>"
            )
        );

        return Base64.encode(bytes(svg));
    }

    /**
     * @notice Parse Settlement attributes into a string.
     */
    function generateAttributes(Attribute[] memory _attributes, string memory _motto)
        internal
        pure
        returns (string memory)
    {
        string memory attributes = "[";
        for (uint8 i = 0; i < _attributes.length; i++) {
            Attribute memory attribute = _attributes[i];
            attributes = string(
                abi.encodePacked(
                    attributes,
                    "{",
                    AttributeType.STAT == attribute.attributeType ? '"display_type":"number",' : "",
                    '"trait_type":"',
                    attribute.attributeHeading,
                    '","value":',
                    AttributeType.STAT == attribute.attributeType || AttributeType.RANKING == attribute.attributeType
                        ? attribute.value
                        : string(abi.encodePacked('"', attribute.value, '"')),
                    "},"
                )
            );
        }

        attributes = string(abi.encodePacked(attributes, '{"trait_type":"Motto","value":"', _motto, '"}]'));

        return attributes;
    }
}

// SPDX-License-Identifier: Unlicense
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol) - MODIFIED
pragma solidity ^0.8.0;

library Strings {
    function toString(uint256 _value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
        if (_value == 0) {
            return "0";
        }

        uint256 temp = _value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }

        bytes memory buffer = new bytes(digits);
        while (_value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(_value % 10)));
            _value /= 10;
        }

        return string(buffer);
    }

    // Source: https://ethereum.stackexchange.com/questions/8346/convert-address-to-string (MODIFIED)
    function toString(address _addr) internal pure returns (string memory) {
        bytes memory buffer = new bytes(40);
        for (uint8 i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint256(uint160(_addr)) / (2**(8 * (19 - i)))));
            bytes1 high = bytes1(uint8(b) / 16);
            bytes1 low = bytes1(uint8(b) - 16 * uint8(high));
            buffer[2 * i] = char(high);
            buffer[2 * i + 1] = char(low);
        }

        return string(abi.encodePacked("0x", string(buffer)));
    }

    function char(bytes1 _byte) internal pure returns (bytes1) {
        if (uint8(_byte) < 10) {
            return bytes1(uint8(_byte) + 0x30);
        } else {
            return bytes1(uint8(_byte) + 0x57);
        }
    }

    function truncateAddressString(string memory _str) internal pure returns (string memory) {
        bytes memory b = bytes(_str);
        return
            string(
                abi.encodePacked(
                    string(abi.encodePacked(b[0], b[1], b[2], b[3], b[4], b[5])),
                    "...",
                    string(abi.encodePacked(b[36], b[37], b[38], b[39], b[40], b[41]))
                )
            );
    }

    function equal(string memory _a, string memory _b) internal pure returns (bool) {
        return keccak256(abi.encodePacked(_a)) == keccak256(abi.encodePacked(_b));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}