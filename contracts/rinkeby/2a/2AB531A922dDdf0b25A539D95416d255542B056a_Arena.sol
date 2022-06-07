// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./FighterEvolution.sol";

contract Arena is FighterEvolution {
    using SafeMath for uint256;
    using SafeMath32 for uint32;
    using SafeMath16 for uint16;

    event ArenaEvent(
        uint256 indexed attackerId,
        uint256 indexed targetId,
        uint16 damage,
        bool wasCritical
    );

    event WhoWon(bool youWon);

    uint32 unarmedDamage = 15;

    modifier weaponCanBeUsedLevel(uint32 fighterLevel, uint32 weaponLevel) {
        require(
            fighterLevel >= weaponLevel,
            "You cannot use this weapon, your level is too small!"
        );
        _;
    }

    modifier noFriendlyAttacks(uint256 _targetId) {
        require(
            fighter_to_owner[_targetId] != _msgSender(),
            "You cannot attack your own Fighter!"
        );
        _;
    }

    function attack(
        uint256 _myFighterId,
        bool _hasOwnerWeapon,
        uint256 _myWeaponId,
        uint256 _targetFighterId
    )
        external
        onlyOwnerOf(_myFighterId)
        notForSale(_myFighterId)
        notForSale(_targetFighterId)
        noFriendlyAttacks(_targetFighterId)
    {
        Fighter storage _myFighter = fighters[_myFighterId];
        require(
            _myFighter.readyTime <= block.timestamp,
            "Your fighter is not yet ready to fight!"
        );
        _triggerCooldown(_myFighter);

        uint32 _myDamage = unarmedDamage;
        if (_hasOwnerWeapon) {
            require(
                _msgSender() == weapon_to_owner[_myWeaponId],
                "You are not the owner of this Weapon!"
            );

            Weapon memory myWeapon = weapons[_myWeaponId];

            require(
                _myFighter.level >= myWeapon.levelReq,
                "You cannot use this weapon, your level is too small!"
            );
            if (myWeapon.weapType == WeaponType.Slash) {
                require(
                    _myFighter.agility >= myWeapon.skillReq,
                    "You cannot use this weapon, your agility skill is insufficient!"
                );
            } else {
                require(
                    _myFighter.strength >= myWeapon.skillReq,
                    "You cannot use this weapon, your strength skill is insufficient!"
                );
            }

            if (
                (_myFighter.class == FighterClass.Samurai &&
                    myWeapon.weapType == WeaponType.Slash) ||
                (_myFighter.class == FighterClass.Warrior &&
                    myWeapon.weapType == WeaponType.Blunt)
            ) {
                _myDamage = myWeapon.damage.mul(2);
            } else {
                _myDamage = myWeapon.damage;
            }
        }

        Fighter storage _targetFighter = fighters[_targetFighterId];
        uint32 _targetDamage = (2 * _myDamage) / 3;

        bool iWon = attackLogic(
            _myFighterId,
            _myFighter,
            _myDamage,
            _targetFighterId,
            _targetFighter,
            _targetDamage
        );
        if (iWon) {
            _fighterWonFight(_myFighterId);
            _fighterLostFight(_targetFighterId);
        } else {
            _fighterLostFight(_myFighterId);
            _fighterWonFight(_targetFighterId);
        }

        emit WhoWon(iWon);
    }

    function attackLogic(
        uint256 myFighterId,
        Fighter storage myFighter,
        uint32 myDamage,
        uint256 targetFighterId,
        Fighter storage targetFighter,
        uint32 targetDamage
    ) private returns (bool) {
        uint32 _myRemainingHP = uint32(myFighter.HP);
        if (myFighter.class == FighterClass.Druid) {
            _myRemainingHP = _myRemainingHP.add(15);
            uint32 bonus = myFighter.level.mul(5);
            _myRemainingHP = _myRemainingHP.add(bonus);
        }
        uint32 _targetRemainingHP = uint32(targetFighter.HP);
        if (targetFighter.class == FighterClass.Druid) {
            _targetRemainingHP = _targetRemainingHP.add(15);
            uint32 bonus = myFighter.level.mul(5);
            _targetRemainingHP = _targetRemainingHP.add(bonus);
        }
        uint16 _damageTaken;
        while (true) {
            // myFighter attacks
            _damageTaken = simulateAttack(
                myFighterId,
                myDamage,
                myFighter.luck,
                _msgSender(),
                targetFighterId,
                targetFighter.dexterity
            );

            if (_targetRemainingHP <= uint32(_damageTaken)) {
                return true;
            }

            _targetRemainingHP -= uint32(_damageTaken);

            // targetFighter attacks
            _damageTaken = simulateAttack(
                targetFighterId,
                targetDamage,
                targetFighter.luck,
                _msgSender(),
                myFighterId,
                myFighter.dexterity
            );

            if (_myRemainingHP <= uint32(_damageTaken)) {
                return false;
            }

            _myRemainingHP -= uint32(_damageTaken);
        }
        assert(_myRemainingHP <= 0 || _targetRemainingHP <= 0);
        return false; // this line of code will never be executed, it's here to shut the compiler up
    }

    function simulateAttack(
        uint256 attackerId,
        uint32 attackerDamage,
        uint16 attackerLck,
        address addressForRandomness,
        uint256 defenderId,
        uint16 defenderDex
    ) private returns (uint16) {
        if (
            _computeCriticalStrikeOrDodgeChance(
                addressForRandomness,
                defenderDex
            )
        ) {
            emit ArenaEvent(attackerId, defenderId, 0, false);
            return 0;
        } else {
            if (
                _computeCriticalStrikeOrDodgeChance(
                    addressForRandomness,
                    attackerLck
                )
            ) {
                emit ArenaEvent(
                    attackerId,
                    defenderId,
                    uint16(attackerDamage.mul(2)),
                    true
                );
                return uint16(attackerDamage.mul(2));
            } else {
                emit ArenaEvent(
                    attackerId,
                    defenderId,
                    uint16(attackerDamage),
                    false
                );
                return uint16(attackerDamage);
            }
        }
    }

    function _collectBalance() external onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./MarketGift.sol";
import "./Merchant.sol";

abstract contract FighterEvolution is MarketGift, Merchant {
    using SafeMath for uint256;
    using SafeMath32 for uint32;
    using SafeMath16 for uint16;

    uint256 randNonce = 0;

    modifier hasAvailablePupils() {
        require(
            user_available_pupils[_msgSender()] >= uint16(1),
            "You do not have any available pupils! Fight to earn more!"
        );
        _;
    }

    function fetchAvailablePupils(address _owner)
        external
        view
        returns (uint16)
    {
        return user_available_pupils[_owner];
    }

    function redeemAvailablePupil(string calldata _name, FighterClass _class)
        external
        hasAvailablePupils
    {
        _createFighter(_name, _class);
        user_available_pupils[_msgSender()] = user_available_pupils[
            _msgSender()
        ].sub(1);
    }

    function spendAvailablePoints(
        uint256 _fighterId,
        uint16 _STR,
        uint16 _AGL,
        uint16 _LCK,
        uint16 _DEX
    ) external onlyOwnerOf(_fighterId) {
        Fighter storage _myFighter = fighters[_fighterId];
        uint16 total = _STR;
        total = total.add(_AGL);
        total = total.add(_LCK);
        total = total.add(_DEX);
        require(
            total <= _myFighter.spendablePoints,
            "You do not have enough available spendable points in order to do this action!"
        );
        _myFighter.spendablePoints = _myFighter.spendablePoints.sub(total);
        _myFighter.strength = _myFighter.strength.add(_STR);
        _myFighter.agility = _myFighter.agility.add(_AGL);
        _myFighter.dexterity = _myFighter.dexterity.add(_DEX);
        _myFighter.luck = _myFighter.luck.add(_LCK);
    }

    function _fighterWonFight(uint256 _fighterId) internal {
        Fighter storage fighter = fighters[_fighterId];
        fighter.winCount = fighter.winCount.add(1);
        fighter.currentXP = fighter.currentXP.add(40);
        if (fighter.currentXP >= fighter.levelUpXP) {
            _levelUpLogic(fighter, _fighterId);
        }
    }

    function _fighterLostFight(uint256 _fighterId) internal {
        Fighter storage fighter = fighters[_fighterId];
        fighter.lossCount = fighter.lossCount.add(1);
        fighter.currentXP = fighter.currentXP.add(25);
        if (fighter.currentXP >= fighter.levelUpXP) {
            _levelUpLogic(fighter, _fighterId);
        }
    }

    function _levelUpLogic(Fighter storage fighter, uint256 _fighterId)
        private
    {
        fighter.levelUpXP = fighter.levelUpXP.add(100);
        fighter.level = fighter.level.add(1);
        fighter.HP = fighter.HP.add(10);
        fighter.spendablePoints = fighter.spendablePoints.add(1);
        if (fighter.level.mod(10) == 0) {
            address _fighter_owner = fighter_to_owner[_fighterId];
            user_available_pupils[_fighter_owner] = user_available_pupils[
                _fighter_owner
            ].add(1);
            if (_computeWeaponDropChance(_fighter_owner)) {
                _forgeWeapon(
                    _fighter_owner,
                    fighter.level,
                    _simulateWeaponType(_fighter_owner),
                    WeaponTier.B
                );
            }
        }
    }

    function _getWeaponByFighterId(uint256 id)
        external
        view
        returns (WeaponDTO[] memory)
    {
        return (_getUserWeapons(fighter_to_owner[id]));
    }

    // Not secure - but in the circumstances is worth the compromise!
    // --------- RANDOMNESS SIMULATION FUNCTIONS --------------------
    function _computeWeaponDropChance(address _owner) private returns (bool) {
        randNonce = randNonce.add(1);
        uint256 generatedNumber = uint256(
            keccak256(abi.encodePacked(block.timestamp, _owner, randNonce))
        ).mod(100);
        if (generatedNumber <= 40) {
            return true;
        }
        return false;
    }

    function _simulateWeaponType(address _owner) private returns (WeaponType) {
        randNonce = randNonce.add(1);
        uint256 generatedNumber = uint256(
            keccak256(abi.encodePacked(block.timestamp, _owner, randNonce))
        ).mod(100);
        if (generatedNumber <= 50) {
            return WeaponType.Slash;
        }
        return WeaponType.Blunt;
    }

    function _computeCriticalStrikeOrDodgeChance(address _owner, uint16 skill)
        internal
        returns (bool)
    {
        uint256 chance = uint256(skill) * 2 + 5;
        randNonce = randNonce.add(1);
        uint256 generatedNumber = uint256(
            keccak256(abi.encodePacked(block.timestamp, _owner, randNonce))
        ).mod(100);
        if (generatedNumber <= chance) {
            return true;
        }
        return false;
    }

    function _triggerCooldown(Fighter storage _myFighter) internal {
        _myFighter.readyTime = uint32(block.timestamp + cooldownTime);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./FighterFactory.sol";

abstract contract MarketGift is FighterFactory {
    using SafeMath for uint256;
    using SafeMath32 for uint32;
    using SafeMath16 for uint16;

    uint16 public immutable feePercent = 5;
    address private nftHolderAccount =
        0x308BcAe2716EAd370Abec327978528Ff21981C4F;

    mapping(uint256 => uint256) internal fighter_to_price;
    mapping(uint256 => address) internal fighter_to_seller;

    modifier hasValidPrice(uint256 price) {
        require(price > 0);
        _;
    }

    modifier hasEnoughFighters(uint256 _fighterId) {
        require(
            owner_fighters_count[fighter_to_owner[_fighterId]] >= 1, //CHANGE WHEN DEPLOYING! ONLY FOR TESTS!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
            "You cannot sell or gift your only character!"
        );
        _;
    }

    function putUpForSale(uint256 _myFighterId, uint256 price)
        external
        onlyOwnerOf(_myFighterId)
        hasEnoughFighters(_myFighterId)
        hasValidPrice(price)
        notForSale(_myFighterId)
    {
        _transfer(_msgSender(), nftHolderAccount, _myFighterId);
        fighter_to_price[_myFighterId] = computeTotalPrice(price);
        fighter_to_seller[_myFighterId] = _msgSender();
        fighters[_myFighterId].isForSale = true;
    }

    modifier fighterPrice(uint256 fighterId) {
        require(
            msg.value >= computeFeelessPrice(fighter_to_price[fighterId]),
            "You sent insufficient ETH for Fighter!"
        );
        _;
    }

    function buyFighter(uint256 _fighterId)
        external
        payable
        forSale(_fighterId)
        fighterPrice(_fighterId)
    {
        uint256 price = computeFeelessPrice(fighter_to_price[_fighterId]);
        uint256 excess = msg.value - price;
        if (excess > 0) {
            payable(_msgSender()).transfer(excess);
        }
        fighters[_fighterId].isForSale = false;
        _approve(_msgSender(), _fighterId);
        _transfer(nftHolderAccount, _msgSender(), _fighterId);
        payable(fighter_to_seller[_fighterId]).transfer(price);

        fighter_to_price[_fighterId] = 0;
        fighter_to_seller[_fighterId] = address(0);
    }

    function giftFighter(address receiver, uint256 _myFighterId)
        external
        onlyOwnerOf(_myFighterId)
        hasEnoughFighters(_myFighterId)
        notForSale(_myFighterId)
    {
        require(receiver != address(0), "Cannot gift NFT to the zero address");
        _transfer(_msgSender(), receiver, _myFighterId);
    }

    function getFighterPrice(uint256 fighterId)
        external
        view
        forSale(fighterId)
        returns (uint256)
    {
        return fighter_to_price[fighterId];
    }

    function getFighterSeller(uint256 fighterId)
        external
        view
        forSale(fighterId)
        returns (address)
    {
        return fighter_to_seller[fighterId];
    }

    function computeTotalPrice(uint256 initialPrice)
        private
        pure
        returns (uint256)
    {
        return (initialPrice + ((initialPrice * uint256(feePercent)) / 100));
    }

    function computeFeelessPrice(uint256 totalPrice)
        private
        pure
        returns (uint256)
    {
        return ((20 * totalPrice) / 21);
    }

    function changeNFTHolderAccount(address newAddr) external onlyOwner {
        require(
            newAddr != address(0),
            "Cannot set NFT holder address to the zero address"
        );
        nftHolderAccount = newAddr;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./WeaponFactory.sol";

abstract contract Merchant is WeaponFactory {
    using SafeMath for uint256;
    using SafeMath32 for uint32;
    using SafeMath16 for uint16;

    uint256 feePerLevel = 0.00075 ether;
    uint256 BTierPrice = 0.0005 ether;
    uint256 ATierPrice = 0.0015 ether;
    uint256 STierPrice = 0.003 ether;

    modifier weaponPrice(uint256 price) {
        require(
            msg.value >= price,
            "You sent insufficient ETH for forging this weapon!"
        );
        _;
    }

    function purchaseWeapon(
        uint32 _level,
        WeaponType _type,
        WeaponTier _tier
    ) external payable weaponPrice(computeWeaponPrice(_level, _tier)) {
        uint256 price = computeWeaponPrice(_level, _tier);
        uint256 excess = msg.value - price;
        if (excess > 0) {
            payable(_msgSender()).transfer(excess);
        }
        _forgeWeapon(_msgSender(), _level, _type, _tier);
    }

    function computeWeaponPrice(uint32 _level, WeaponTier _tier)
        public
        view
        returns (uint256)
    {
        uint256 basePrice = feePerLevel.mul(uint256(_level));
        if (_tier == WeaponTier.B) return basePrice.add(BTierPrice);
        if (_tier == WeaponTier.S) return basePrice.add(STierPrice);
        return basePrice.add(ATierPrice);
    }

    function setFeePerLevel(uint256 _fee) external onlyOwner {
        feePerLevel = _fee;
    }

    function setBTierPrice(uint256 _fee) external onlyOwner {
        BTierPrice = _fee;
    }

    function setATierPrice(uint256 _fee) external onlyOwner {
        ATierPrice = _fee;
    }

    function setSTierPrice(uint256 _fee) external onlyOwner {
        STierPrice = _fee;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./openzeppelin/SafeMath.sol";
import "./helpers/fighters/FighterClasses.sol";

abstract contract FighterFactory is Ownable, ERC165, IERC721, IERC721Metadata {
    using SafeMath for uint256;
    using SafeMath32 for uint32;
    using SafeMath16 for uint16;
    using Address for address;
    using Strings for uint256;

    uint256 immutable cooldownTime = 1 minutes;

    struct Fighter {
        bool isForSale;
        uint16 winCount;
        uint16 lossCount;
        uint16 HP;
        uint16 strength;
        uint16 agility;
        uint16 dexterity;
        uint16 luck;
        uint16 currentXP;
        uint16 levelUpXP;
        uint16 spendablePoints;
        uint32 level;
        uint32 readyTime;
        FighterClass class;
        string name;
    }

    struct FighterDTO {
        address owner;
        Fighter fighter;
        uint256 id;
    }

    struct FighterBarracksDTO {
        Fighter fighter;
        uint256 id;
    }

    Fighter[] internal fighters;

    mapping(uint256 => address) internal fighter_to_owner;
    mapping(address => uint256) internal owner_fighters_count;
    mapping(address => uint16) internal user_available_pupils;

    mapping(FighterClass => string) internal fighter_classes_string;
    mapping(FighterClass => string) internal fighter_classes_images_path;

    // Token name
    string private _name = "CryptoArenaFighters";

    // Token symbol
    string private _symbol = "Fighter";

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor() {
        fighter_classes_string[FighterClass.Warrior] = "Warrior";
        fighter_classes_string[FighterClass.Samurai] = "Samurai";
        fighter_classes_string[FighterClass.Druid] = "Druid";

        fighter_classes_images_path[
            FighterClass.Warrior
        ] = "https://i.imgur.com/yhJOzNT.png";
        fighter_classes_images_path[
            FighterClass.Samurai
        ] = "https://i.imgur.com/ttEuemz.png";
        fighter_classes_images_path[
            FighterClass.Druid
        ] = "https://i.imgur.com/aS92Faz.png";
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) public view override returns (uint256) {
        require(
            owner != address(0),
            "ERC721: balance query for the zero address"
        );
        return owner_fighters_count[owner];
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = fighter_to_owner[tokenId];
        require(
            owner != address(0),
            "ERC721: owner query for nonexistent token"
        );
        return owner;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function _baseURI() internal pure returns (string memory) {
        return "";
    }

    function approve(address to, uint256 tokenId) public override {
        address owner = fighter_to_owner[tokenId];
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId)
        public
        view
        override
        returns (address)
    {
        require(
            _exists(tokenId),
            "ERC721: approved query for nonexistent token"
        );

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
    {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return fighter_to_owner[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        address owner = fighter_to_owner[tokenId];
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    function _safeMint(address to, uint256 tokenId) internal {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        emit Transfer(address(0), to, tokenId);
    }

    /*function _burn(uint256 tokenId) internal {
        revert("You cannot delete/burn a Fighter!");
    }*/

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        require(
            fighter_to_owner[tokenId] == from,
            "ERC721: transfer from incorrect owner"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        owner_fighters_count[from] = owner_fighters_count[from].sub(1);
        owner_fighters_count[to] = owner_fighters_count[to].add(1);
        fighter_to_owner[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(fighter_to_owner[tokenId], to, tokenId);
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
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

    modifier onlyOwnerOf(uint256 _fighterId) {
        require(
            _msgSender() == fighter_to_owner[_fighterId],
            "You are not the owner of this Fighter!"
        );
        _;
    }

    function tokenURI(uint256 _id)
        public
        view
        override
        returns (string memory)
    {
        Fighter memory _fighter = fighters[_id];

        string memory HP_str = Strings.toString(_fighter.HP);
        string memory level_str = Strings.toString(_fighter.level);
        string memory STR_str = Strings.toString(_fighter.strength);
        string memory AGL_str = Strings.toString(_fighter.agility);
        string memory LCK_str = Strings.toString(_fighter.luck);
        string memory DEX_str = Strings.toString(_fighter.dexterity);

        string memory json = Base64.encode(
            abi.encodePacked(
                '{"name": "[Fighter #',
                Strings.toString(_id),
                "] - ",
                _fighter.name,
                " the ",
                fighter_classes_string[_fighter.class],
                '", "description": "This NFT represents a CryptoArena3.0 Fighter!", "image": "',
                fighter_classes_images_path[_fighter.class],
                '", "attributes": [{"trait_type": "level", "value": ',
                level_str,
                "},",
                '{"trait_type": "Health Points", "value": ',
                HP_str,
                "},",
                '{"trait_type": "Strength", "value": ',
                STR_str,
                "},",
                '{"trait_type": "Agility", "value": ',
                AGL_str,
                "},",
                '{"trait_type": "Luck", "value": ',
                LCK_str,
                "},",
                '{"trait_type": "Dexterity", "value": ',
                DEX_str,
                "}]}"
            )
        );

        string memory output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return output;
    }

    modifier notForSale(uint256 _fighterId) {
        require(!fighters[_fighterId].isForSale);
        _;
    }

    modifier forSale(uint256 _fighterId) {
        require(fighters[_fighterId].isForSale);
        _;
    }

    modifier emptyBarracks() {
        require(
            owner_fighters_count[_msgSender()] == 0,
            "You already have fighters in your Barracks! Enter the Arena and earn yourself more Fighters!"
        );
        _;
    }

    modifier validName(string calldata _givenName) {
        require(
            bytes(_givenName).length != 0,
            "The name you inserted for your Fighter is invalid!"
        );
        _;
    }

    modifier validClass(FighterClass _class) {
        require(
            _class == FighterClass.Warrior ||
                _class == FighterClass.Samurai ||
                _class == FighterClass.Druid,
            "The class you inserted for your Fighter is invalid!"
        );
        _;
    }

    modifier uniqueName(string memory _givenName) {
        FighterBarracksDTO[] memory userFighters = _getUserFighters(
            _msgSender()
        );
        bool nameFound = false;
        for (uint256 i = 0; i < userFighters.length; i++) {
            if (compareStrings(userFighters[i].fighter.name, _givenName)) {
                nameFound = true;
                break;
            }
        }
        require(
            !nameFound,
            "The name you inserted for your Fighter is already used!"
        );
        _;
    }

    function createFirstFighter(
        string calldata _givenName,
        FighterClass _class
    ) external emptyBarracks {
        _createFighter(_givenName, _class);
        user_available_pupils[_msgSender()] = 0;
    }

    function _createFighter(string calldata _givenName, FighterClass _class)
        internal
        validName(_givenName)
        validClass(_class)
        uniqueName(_givenName)
    {
        fighters.push(
            Fighter(
                false,
                0,
                0,
                100,
                1,
                1,
                1,
                1,
                0,
                100,
                0,
                1,
                uint32(block.timestamp.add(cooldownTime)),
                _class,
                _givenName
            )
        );
        uint256 id = fighters.length - 1;
        fighter_to_owner[id] = _msgSender();
        owner_fighters_count[_msgSender()] = owner_fighters_count[_msgSender()]
            .add(1);
        _safeMint(_msgSender(), id);
    }

    function _getUserFighters(address _owner)
        public
        view
        returns (FighterBarracksDTO[] memory)
    {
        uint256 toFetch = owner_fighters_count[_owner];
        FighterBarracksDTO[] memory myFighters = new FighterBarracksDTO[](
            toFetch
        );
        if (toFetch == 0) {
            return myFighters;
        }
        uint256 counter = 0;
        for (uint256 i = 0; i < fighters.length; i++) {
            if (fighter_to_owner[i] == _owner) {
                myFighters[counter] = FighterBarracksDTO(fighters[i], i);
                counter++;
                toFetch--;
                if (toFetch == 0) {
                    break;
                }
            }
        }
        return myFighters;
    }

    function _getLatestFighters(uint256 latest)
        external
        view
        returns (FighterDTO[] memory)
    {
        require(latest >= 0 && latest <= fighters.length);
        if (latest == 0) {
            latest = fighters.length;
        }
        FighterDTO[] memory allFightersDTOs = new FighterDTO[](latest);
        if (fighters.length == 0) {
            return allFightersDTOs;
        }
        uint256 counter = 0;
        for (
            uint256 i = fighters.length - 1;
            i >= fighters.length - latest;
            i--
        ) {
            allFightersDTOs[counter] = (
                FighterDTO(fighter_to_owner[i], fighters[i], i)
            );
            counter++;
            if (counter == latest) {
                break;
            }
        }
        return allFightersDTOs;
    }

    function _getFightersCount() external view returns (uint256) {
        return fighters.length;
    }

    function _getMyAvailablePupils() external view returns (uint256) {
        return user_available_pupils[_msgSender()];
    }

    function compareStrings(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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

library SafeMath32 {
    function tryAdd(uint32 a, uint32 b) internal pure returns (bool, uint32) {
        unchecked {
            uint32 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint32 a, uint32 b) internal pure returns (bool, uint32) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint32 a, uint32 b) internal pure returns (bool, uint32) {
        unchecked {
            if (a == 0) return (true, 0);
            uint32 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint32 a, uint32 b) internal pure returns (bool, uint32) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint32 a, uint32 b) internal pure returns (bool, uint32) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint32 a, uint32 b) internal pure returns (uint32) {
        return a + b;
    }

    function sub(uint32 a, uint32 b) internal pure returns (uint32) {
        return a - b;
    }

    function mul(uint32 a, uint32 b) internal pure returns (uint32) {
        return a * b;
    }

    function div(uint32 a, uint32 b) internal pure returns (uint32) {
        return a / b;
    }

    function mod(uint32 a, uint32 b) internal pure returns (uint32) {
        return a % b;
    }

    function sub(
        uint32 a,
        uint32 b,
        string memory errorMessage
    ) internal pure returns (uint32) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint32 a,
        uint32 b,
        string memory errorMessage
    ) internal pure returns (uint32) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint32 a,
        uint32 b,
        string memory errorMessage
    ) internal pure returns (uint32) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

library SafeMath16 {
    function tryAdd(uint16 a, uint16 b) internal pure returns (bool, uint16) {
        unchecked {
            uint16 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint16 a, uint16 b) internal pure returns (bool, uint16) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint16 a, uint16 b) internal pure returns (bool, uint16) {
        unchecked {
            if (a == 0) return (true, 0);
            uint16 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint16 a, uint16 b) internal pure returns (bool, uint16) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint16 a, uint16 b) internal pure returns (bool, uint16) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint16 a, uint16 b) internal pure returns (uint16) {
        return a + b;
    }

    function sub(uint16 a, uint16 b) internal pure returns (uint16) {
        return a - b;
    }

    function mul(uint16 a, uint16 b) internal pure returns (uint16) {
        return a * b;
    }

    function div(uint16 a, uint16 b) internal pure returns (uint16) {
        return a / b;
    }

    function mod(uint16 a, uint16 b) internal pure returns (uint16) {
        return a % b;
    }

    function sub(
        uint16 a,
        uint16 b,
        string memory errorMessage
    ) internal pure returns (uint16) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint16 a,
        uint16 b,
        string memory errorMessage
    ) internal pure returns (uint16) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint16 a,
        uint16 b,
        string memory errorMessage
    ) internal pure returns (uint16) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

enum FighterClass {
    Warrior,
    Samurai,
    Druid
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

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./openzeppelin/SafeMath.sol";
import "./helpers/weapons/WeaponTiers.sol";
import "./helpers/weapons/WeaponTypes.sol";

abstract contract WeaponFactory is Ownable {
    using SafeMath for uint256;
    using SafeMath32 for uint32;
    using SafeMath16 for uint16;

    struct Weapon {
        uint32 levelReq;
        uint32 damage;
        uint16 skillReq;
        WeaponType weapType;
        WeaponTier tier;
    }

    struct WeaponDTO {
        Weapon weapon;
        uint256 id;
    }

    Weapon[] internal weapons;

    mapping(uint256 => address) internal weapon_to_owner;
    mapping(address => uint256) internal owner_weapons_count;

    modifier validLevel(uint32 _level) {
        require(
            _level >= 1,
            "The level you inserted for your Weapon is invalid!"
        );
        _;
    }

    modifier validType(WeaponType _type) {
        require(
            _type == WeaponType.Slash || _type == WeaponType.Blunt,
            "The type you inserted for your Weapon is invalid!"
        );
        _;
    }

    modifier validTier(WeaponTier _tier) {
        require(
            _tier == WeaponTier.S ||
                _tier == WeaponTier.A ||
                _tier == WeaponTier.B,
            "The type you inserted for your Weapon is invalid!"
        );
        _;
    }

    function _forgeWeapon(
        address _owner,
        uint32 _level,
        WeaponType _type,
        WeaponTier _tier
    ) internal validLevel(_level) validType(_type) validTier(_tier) {
        uint16 currentSkillReq = 0;
        if (_tier == WeaponTier.S) {
            currentSkillReq = 8;
        }
        if (_tier == WeaponTier.A) {
            currentSkillReq = 6;
        }
        if (_tier == WeaponTier.B) {
            currentSkillReq = 3;
        }
        weapons.push(
            Weapon(
                _level,
                _computeWeaponDamage(_level, _tier),
                currentSkillReq,
                _type,
                _tier
            )
        );
        weapon_to_owner[weapons.length - 1] = _owner;
        owner_weapons_count[_owner] = owner_weapons_count[_owner].add(1);
    }

    function _computeWeaponDamage(uint32 _level, WeaponTier _tier)
        private
        pure
        returns (uint32)
    {
        if (_tier == WeaponTier.B) return _level.mul(2);
        if (_tier == WeaponTier.S) return _level.mul(4);
        return _level.mul(3);
    }

    function _getUserWeapons(address _owner)
        public
        view
        returns (WeaponDTO[] memory)
    {
        uint256 toFetch = owner_weapons_count[_owner];
        WeaponDTO[] memory myWeapons = new WeaponDTO[](toFetch);
        if (toFetch == 0) {
            return myWeapons;
        }
        uint256 counter = 0;
        for (uint256 i = 0; i < weapons.length; i++) {
            if (weapon_to_owner[i] == _owner) {
                myWeapons[counter] = WeaponDTO(weapons[i], i);
                counter++;
                toFetch--;
                if (toFetch == 0) {
                    break;
                }
            }
        }
        return myWeapons;
    }

    /*function _getWeaponsCount() external view returns (uint256) {
        return weapons.length;
    }*/
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

enum WeaponTier {
    S,
    A,
    B
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

enum WeaponType {
    Slash,
    Blunt
}