//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ChainScoutsExtension.sol";
import "./IUtilityERC20.sol";
import "./Rarities.sol";
import "./Rng.sol";

contract Reroller is ChainScoutsExtension {
    using RngLibrary for Rng;

    Rng internal staticRng;
    IUtilityERC20 public token;
    bool public enabled;
    uint256 public accessoryCost = 80 ether;
    uint256 public backAccessoryCost = type(uint256).max;
    uint256 public backgroundCost = 80 ether;
    uint256 public clothingCost = 80 ether;

    constructor(IUtilityERC20 _token) {
        token = _token;
        enabled = false;
    }

    function extensionKey() public pure override returns (string memory) {
        return "reroller";
    }

    function adminSetEnabled(bool e) external onlyAdmin {
        enabled = e;
    }

    function adminSetAccessoryCostWei(uint256 _wei) external onlyAdmin {
        accessoryCost = _wei;
    }

    function adminSetBackAccessoryCostWei(uint256 _wei) external onlyAdmin {
        backAccessoryCost = _wei;
    }

    function adminSetBackgroundCostWei(uint256 _wei) external onlyAdmin {
        backgroundCost = _wei;
    }

    function adminSetClothingCostWei(uint256 _wei) external onlyAdmin {
        clothingCost = _wei;
    }

    modifier whenEnabled() {
        require(enabled == true, "Rerolling is not enabled atm");
        _;
    }

    function getRandom(
        Rng memory rng,
        uint256 raritySum,
        uint16[] memory rarities
    ) internal view returns (uint256) {
        uint256 rn = rng.generate(0, raritySum - 1);

        for (uint256 i = 0; i < rarities.length; ++i) {
            if (rarities[i] > rn) {
                return i;
            }
            rn -= rarities[i];
        }
        revert("rn not selected");
    }

    function rerollAccessory(uint256 tokenId)
        external
        canAccessToken(tokenId)
        whenEnabled
    {
        token.burn(msg.sender, accessoryCost);

        ChainScoutMetadata memory md = chainScouts.getChainScoutMetadata(
            tokenId
        );
        Rng memory rng = staticRng;

        uint16[] memory rarities = Rarities.accessory();
        uint256 total = 10000;

        total -= rarities[uint256(md.accessory)];
        rarities[uint256(md.accessory)] = 0;

        if (md.backaccessory == BackAccessory.MINER) {
            total -= rarities[uint256(Accessory.CUBAN_LINK_GOLD_CHAIN)];
            rarities[uint256(Accessory.CUBAN_LINK_GOLD_CHAIN)] = 0;
        }

        if (
            md.clothing == Clothing.FLEET_UNIFORM__BLUE ||
            md.clothing == Clothing.FLEET_UNIFORM__RED
        ) {
            Accessory[4] memory xs = [
                Accessory.AMULET,
                Accessory.CUBAN_LINK_GOLD_CHAIN,
                Accessory.FANNY_PACK,
                Accessory.GOLDEN_CHAIN
            ];
            for (uint256 i = 0; i < xs.length; ++i) {
                total -= rarities[uint256(xs[i])];
                rarities[uint256(xs[i])] = 0;
            }
        } else if (
            md.head == Head.CYBER_HELMET__BLUE ||
            md.head == Head.CYBER_HELMET__RED ||
            md.head == Head.SPACESUIT_HELMET
        ) {
            total -= rarities[uint256(Accessory.GOLD_EARRINGS)];
            rarities[uint256(Accessory.GOLD_EARRINGS)] = 0;
        }

        md.accessory = Accessory(getRandom(rng, total, rarities));

        staticRng = rng;
        chainScouts.adminSetChainScoutMetadata(tokenId, md);
    }

    function rerollBackAccessory(uint256 tokenId)
        external
        canAccessToken(tokenId)
        whenEnabled
    {
        token.burn(msg.sender, backAccessoryCost);

        ChainScoutMetadata memory md = chainScouts.getChainScoutMetadata(
            tokenId
        );
        Rng memory rng = staticRng;

        uint16[] memory rarities = Rarities.backaccessory();
        uint256 total = 10000;

        total -= rarities[uint256(md.backaccessory)];
        rarities[uint256(md.backaccessory)] = 0;

        if (md.accessory == Accessory.CUBAN_LINK_GOLD_CHAIN) {
            total -= rarities[uint256(BackAccessory.MINER)];
            rarities[uint256(BackAccessory.MINER)] = 0;
        }

        if (md.head == Head.ENERGY_FIELD) {
            total -= rarities[uint256(BackAccessory.PATHFINDER)];
            rarities[uint256(BackAccessory.PATHFINDER)] = 0;
        }

        md.backaccessory = BackAccessory(getRandom(rng, total, rarities));

        staticRng = rng;
        chainScouts.adminSetChainScoutMetadata(tokenId, md);
    }

    function rerollBackground(uint256 tokenId)
        external
        canAccessToken(tokenId)
        whenEnabled
    {
        token.burn(msg.sender, backgroundCost);

        ChainScoutMetadata memory md = chainScouts.getChainScoutMetadata(
            tokenId
        );
        Rng memory rng = staticRng;

        uint16[] memory rarities = Rarities.background();
        uint256 total = 10000;

        total -= rarities[uint256(md.background)];
        rarities[uint256(md.background)] = 0;

        if (
            md.clothing == Clothing.FLEET_UNIFORM__BLUE ||
            md.clothing == Clothing.MARTIAL_SUIT ||
            md.clothing == Clothing.THUNDERDOME_ARMOR ||
            md.head == Head.ENERGY_FIELD
        ) {
            total -= rarities[uint256(Background.CITY__PURPLE)];
            rarities[uint256(Background.CITY__PURPLE)] = 0;
        }

        if (md.head == Head.ENERGY_FIELD) {
            total -= rarities[uint256(Background.CITY__RED)];
            rarities[uint256(Background.CITY__RED)] = 0;
        }

        md.background = Background(getRandom(rng, total, rarities));

        staticRng = rng;
        chainScouts.adminSetChainScoutMetadata(tokenId, md);
    }

    function rerollClothing(uint256 tokenId)
        external
        canAccessToken(tokenId)
        whenEnabled
    {
        token.burn(msg.sender, clothingCost);

        ChainScoutMetadata memory md = chainScouts.getChainScoutMetadata(
            tokenId
        );
        Rng memory rng = staticRng;

        uint16[] memory rarities = Rarities.clothing();
        uint256 total = 10000;

        total -= rarities[uint256(md.clothing)];
        rarities[uint256(md.clothing)] = 0;

        if (
            md.accessory == Accessory.AMULET ||
            md.accessory == Accessory.CUBAN_LINK_GOLD_CHAIN ||
            md.accessory == Accessory.FANNY_PACK ||
            md.accessory == Accessory.GOLDEN_CHAIN ||
            md.mouth == Mouth.CHROME_RESPIRATOR ||
            md.mouth == Mouth.GREEN_RESPIRATOR ||
            md.mouth == Mouth.MAGENTA_RESPIRATOR ||
            md.mouth == Mouth.NAVY_RESPIRATOR ||
            md.mouth == Mouth.RED_RESPIRATOR
        ) {
            Clothing[2] memory c = [
                Clothing.FLEET_UNIFORM__BLUE,
                Clothing.FLEET_UNIFORM__RED
            ];

            for (uint256 i = 0; i < c.length; ++i) {
                uint256 cdx = uint256(c[i]);
                total -= rarities[cdx];
                rarities[cdx] = 0;
            }
        }

        if (md.background == Background.CITY__PURPLE) {
            Clothing[3] memory c = [
                Clothing.FLEET_UNIFORM__BLUE,
                Clothing.MARTIAL_SUIT,
                Clothing.THUNDERDOME_ARMOR
            ];

            for (uint256 i = 0; i < c.length; ++i) {
                uint256 cdx = uint256(c[i]);
                total -= rarities[cdx];
                rarities[cdx] = 0;
            }
        }

        if (uint256(md.background) == 10 || uint256(md.background) == 19) {
            total -= rarities[uint256(Clothing.MARTIAL_SUIT)];
            rarities[uint256(Clothing.MARTIAL_SUIT)] = 0;
        }

        if (uint256(md.background) == 10) {
            total -= rarities[uint256(Clothing.THUNDERDOME_ARMOR)];
            rarities[uint256(Clothing.THUNDERDOME_ARMOR)] = 0;
        }

        md.clothing = Clothing(getRandom(rng, total, rarities));

        staticRng = rng;
        chainScouts.adminSetChainScoutMetadata(tokenId, md);
    }
}

contract Reroller2 is ChainScoutsExtension {
    using RngLibrary for Rng;

    Rng internal staticRng;
    IUtilityERC20 public token;
    bool public enabled;
    uint256 public eyesCost = 80 ether;
    uint256 public furCost = 80 ether;
    uint256 public headCost = 80 ether;
    uint256 public mouthCost = 80 ether;

    constructor(IUtilityERC20 _token) {
        token = _token;
        enabled = false;
    }

    function extensionKey() public pure override returns (string memory) {
        return "reroller2";
    }

    function adminSetEyesCostWei(uint256 _wei) external onlyAdmin {
        eyesCost = _wei;
    }

    function adminSetFurCostWei(uint256 _wei) external onlyAdmin {
        furCost = _wei;
    }

    function adminSetHeadCostWei(uint256 _wei) external onlyAdmin {
        headCost = _wei;
    }

    function adminSetMouthCostWei(uint256 _wei) external onlyAdmin {
        mouthCost = _wei;
    }

    function adminSetEnabled(bool e) external onlyAdmin {
        enabled = e;
    }

    modifier whenEnabled() {
        require(enabled == true, "Rerolling is not enabled atm");
        _;
    }

    function getRandom(
        Rng memory rng,
        uint256 raritySum,
        uint16[] memory rarities
    ) internal view returns (uint256) {
        uint256 rn = rng.generate(0, raritySum - 1);

        for (uint256 i = 0; i < rarities.length; ++i) {
            if (rarities[i] > rn) {
                return i;
            }
            rn -= rarities[i];
        }
        revert("rn not selected");
    }

    function rerollEyes(uint256 tokenId)
        external
        canAccessToken(tokenId)
        whenEnabled
    {
        token.burn(msg.sender, eyesCost);

        ChainScoutMetadata memory md = chainScouts.getChainScoutMetadata(
            tokenId
        );
        Rng memory rng = staticRng;

        uint16[] memory rarities = Rarities.eyes();
        uint256 total = 10000;

        total -= rarities[uint256(md.eyes)];
        rarities[uint256(md.eyes)] = 0;

        if (
            md.head == Head.BANDANA ||
            md.head == Head.CYBER_HELMET__BLUE ||
            md.head == Head.CYBER_HELMET__RED ||
            md.head == Head.DORAG ||
            md.head == Head.SPACESUIT_HELMET ||
            md.mouth == Mouth.BANANA ||
            md.mouth == Mouth.CHROME_RESPIRATOR ||
            md.mouth == Mouth.GREEN_RESPIRATOR ||
            md.mouth == Mouth.MAGENTA_RESPIRATOR ||
            md.mouth == Mouth.MASK ||
            md.mouth == Mouth.MEMPO ||
            md.mouth == Mouth.NAVY_RESPIRATOR ||
            md.mouth == Mouth.PILOT_OXYGEN_MASK ||
            md.mouth == Mouth.RED_RESPIRATOR
        ) {
            Eyes[2] memory xs = [Eyes.BLUE_LASER, Eyes.RED_LASER];
            for (uint256 i = 0; i < xs.length; ++i) {
                total -= rarities[uint256(xs[i])];
                rarities[uint256(xs[i])] = 0;
            }
        }

        if (
            md.head == Head.SPACESUIT_HELMET ||
            md.mouth == Mouth.CHROME_RESPIRATOR ||
            md.mouth == Mouth.GREEN_RESPIRATOR ||
            md.mouth == Mouth.MAGENTA_RESPIRATOR ||
            md.mouth == Mouth.MASK ||
            md.mouth == Mouth.NAVY_RESPIRATOR ||
            md.mouth == Mouth.RED_RESPIRATOR
        ) {
            Eyes[3] memory xs = [
                Eyes.BLUE_SHADES,
                Eyes.DARK_SUNGLASSES,
                Eyes.GOLDEN_SHADES
            ];
            for (uint256 i = 0; i < xs.length; ++i) {
                total -= rarities[uint256(xs[i])];
                rarities[uint256(xs[i])] = 0;
            }
        }

        if (
            md.head == Head.DORAG ||
            md.head == Head.HEADBAND ||
            md.head == Head.SPACESUIT_HELMET
        ) {
            Eyes[3] memory xs = [
                Eyes.HUD_GLASSES,
                Eyes.HIVE_GOGGLES,
                Eyes.WHITE_SUNGLASSES
            ];
            for (uint256 i = 0; i < xs.length; ++i) {
                total -= rarities[uint256(xs[i])];
                rarities[uint256(xs[i])] = 0;
            }
        }

        if (
            md.head == Head.CAP ||
            md.head == Head.LEATHER_COWBOY_HAT ||
            md.head == Head.PURPLE_COWBOY_HAT
        ) {
            total -= rarities[uint256(Eyes.HAPPY)];
            rarities[uint256(Eyes.HAPPY)] = 0;
        }

        if (
            md.head == Head.BANDANA ||
            md.head == Head.CYBER_HELMET__BLUE ||
            md.head == Head.CYBER_HELMET__RED ||
            md.head == Head.DORAG ||
            md.head == Head.HEADBAND ||
            md.head == Head.SPACESUIT_HELMET ||
            md.mouth == Mouth.CHROME_RESPIRATOR ||
            md.mouth == Mouth.GREEN_RESPIRATOR ||
            md.mouth == Mouth.MAGENTA_RESPIRATOR ||
            md.mouth == Mouth.MASK ||
            md.mouth == Mouth.MEMPO ||
            md.mouth == Mouth.NAVY_RESPIRATOR ||
            md.mouth == Mouth.RED_RESPIRATOR
        ) {
            total -= rarities[uint256(Eyes.HIPSTER_GLASSES)];
            rarities[uint256(Eyes.HIPSTER_GLASSES)] = 0;
        }

        if (md.head == Head.SPACESUIT_HELMET) {
            Eyes[2] memory xs = [
                Eyes.MATRIX_GLASSES,
                Eyes.NIGHT_VISION_GOGGLES
            ];
            for (uint256 i = 0; i < xs.length; ++i) {
                total -= rarities[uint256(xs[i])];
                rarities[uint256(xs[i])] = 0;
            }
        }

        if (
            md.head == Head.BANDANA ||
            md.head == Head.DORAG ||
            md.head == Head.HEADBAND ||
            md.head == Head.SPACESUIT_HELMET ||
            md.mouth == Mouth.CHROME_RESPIRATOR ||
            md.mouth == Mouth.GREEN_RESPIRATOR ||
            md.mouth == Mouth.MAGENTA_RESPIRATOR ||
            md.mouth == Mouth.MASK ||
            md.mouth == Mouth.MEMPO ||
            md.mouth == Mouth.NAVY_RESPIRATOR ||
            md.mouth == Mouth.PILOT_OXYGEN_MASK ||
            md.mouth == Mouth.RED_RESPIRATOR
        ) {
            total -= rarities[uint256(Eyes.NOUNS_GLASSES)];
            rarities[uint256(Eyes.NOUNS_GLASSES)] = 0;
        }

        if (
            md.head == Head.SPACESUIT_HELMET ||
            md.mouth == Mouth.MASK ||
            md.mouth == Mouth.MEMPO
        ) {
            total -= rarities[uint256(Eyes.PINCENEZ)];
            rarities[uint256(Eyes.PINCENEZ)] = 0;
        }

        if (
            md.head == Head.DORAG ||
            md.head == Head.HEADBAND ||
            md.mouth == Mouth.CHROME_RESPIRATOR ||
            md.mouth == Mouth.GREEN_RESPIRATOR ||
            md.mouth == Mouth.MAGENTA_RESPIRATOR ||
            md.mouth == Mouth.MEMPO ||
            md.mouth == Mouth.NAVY_RESPIRATOR ||
            md.mouth == Mouth.RED_RESPIRATOR
        ) {
            total -= rarities[uint256(Eyes.SPACE_VISOR)];
            rarities[uint256(Eyes.SPACE_VISOR)] = 0;
        }

        if (md.head == Head.SPACESUIT_HELMET || md.mouth == Mouth.MASK) {
            total -= rarities[uint256(Eyes.SUNGLASSES)];
            rarities[uint256(Eyes.SUNGLASSES)] = 0;
        }

        md.eyes = Eyes(getRandom(rng, total, rarities));

        staticRng = rng;
        chainScouts.adminSetChainScoutMetadata(tokenId, md);
    }

    function rerollFur(uint256 tokenId)
        external
        canAccessToken(tokenId)
        whenEnabled
    {
        token.burn(msg.sender, furCost);

        ChainScoutMetadata memory md = chainScouts.getChainScoutMetadata(
            tokenId
        );
        Rng memory rng = staticRng;

        uint16[] memory rarities = Rarities.fur();
        uint256 total = 10000;

        md.fur = Fur(getRandom(rng, total, rarities));

        staticRng = rng;
        chainScouts.adminSetChainScoutMetadata(tokenId, md);
    }

    function rerollHead(uint256 tokenId)
        external
        canAccessToken(tokenId)
        whenEnabled
    {
        token.burn(msg.sender, headCost);

        ChainScoutMetadata memory md = chainScouts.getChainScoutMetadata(
            tokenId
        );
        Rng memory rng = staticRng;

        uint16[] memory rarities = Rarities.head();
        uint256 total = 10000;

        total -= rarities[uint256(md.head)];
        rarities[uint256(md.head)] = 0;

        if (
            md.eyes == Eyes.BLUE_LASER ||
            md.eyes == Eyes.HIPSTER_GLASSES ||
            md.eyes == Eyes.NOUNS_GLASSES ||
            md.eyes == Eyes.RED_LASER ||
            md.mouth == Mouth.CHROME_RESPIRATOR ||
            md.mouth == Mouth.GREEN_RESPIRATOR ||
            md.mouth == Mouth.MAGENTA_RESPIRATOR ||
            md.mouth == Mouth.NAVY_RESPIRATOR ||
            md.mouth == Mouth.RED_RESPIRATOR
        ) {
            total -= rarities[uint256(Head.BANDANA)];
            rarities[uint256(Head.BANDANA)] = 0;
        }

        if (md.eyes == Eyes.HAPPY) {
            total -= rarities[uint256(Head.CAP)];
            rarities[uint256(Head.CAP)] = 0;
        }

        if (
            md.accessory == Accessory.GOLD_EARRINGS ||
            md.eyes == Eyes.BLUE_LASER ||
            md.eyes == Eyes.HIPSTER_GLASSES ||
            md.eyes == Eyes.RED_LASER ||
            md.mouth == Mouth.CHROME_RESPIRATOR ||
            md.mouth == Mouth.CIGAR ||
            md.mouth == Mouth.GREEN_RESPIRATOR ||
            md.mouth == Mouth.MAGENTA_RESPIRATOR ||
            md.mouth == Mouth.MEMPO ||
            md.mouth == Mouth.NAVY_RESPIRATOR ||
            md.mouth == Mouth.PILOT_OXYGEN_MASK ||
            md.mouth == Mouth.PIPE ||
            md.mouth == Mouth.RED_RESPIRATOR ||
            md.mouth == Mouth.VAPE
        ) {
            Head[2] memory xs = [
                Head.CYBER_HELMET__BLUE,
                Head.CYBER_HELMET__RED
            ];
            for (uint256 i = 0; i < xs.length; ++i) {
                total -= rarities[uint256(xs[i])];
                rarities[uint256(xs[i])] = 0;
            }
        }

        if (
            md.eyes == Eyes.BLUE_LASER ||
            md.eyes == Eyes.HUD_GLASSES ||
            md.eyes == Eyes.HIPSTER_GLASSES ||
            md.eyes == Eyes.HIVE_GOGGLES ||
            md.eyes == Eyes.NOUNS_GLASSES ||
            md.eyes == Eyes.RED_LASER ||
            md.eyes == Eyes.SPACE_VISOR ||
            md.eyes == Eyes.WHITE_SUNGLASSES ||
            md.mouth == Mouth.CHROME_RESPIRATOR ||
            md.mouth == Mouth.GREEN_RESPIRATOR ||
            md.mouth == Mouth.MAGENTA_RESPIRATOR ||
            md.mouth == Mouth.NAVY_RESPIRATOR ||
            md.mouth == Mouth.RED_RESPIRATOR
        ) {
            total -= rarities[uint256(Head.DORAG)];
            rarities[uint256(Head.DORAG)] = 0;
        }

        if (
            md.backaccessory == BackAccessory.PATHFINDER ||
            md.background == Background.CITY__PURPLE ||
            md.background == Background.CITY__RED
        ) {
            total -= rarities[uint256(Head.ENERGY_FIELD)];
            rarities[uint256(Head.ENERGY_FIELD)] = 0;
        }

        if (
            md.eyes == Eyes.HUD_GLASSES ||
            md.eyes == Eyes.HIPSTER_GLASSES ||
            md.eyes == Eyes.HIVE_GOGGLES ||
            md.eyes == Eyes.NOUNS_GLASSES ||
            md.eyes == Eyes.SPACE_VISOR ||
            md.eyes == Eyes.WHITE_SUNGLASSES
        ) {
            total -= rarities[uint256(Head.HEADBAND)];
            rarities[uint256(Head.HEADBAND)] = 0;
        }

        if (md.eyes == Eyes.HAPPY) {
            Head[2] memory xs = [
                Head.LEATHER_COWBOY_HAT,
                Head.PURPLE_COWBOY_HAT
            ];
            for (uint256 i = 0; i < xs.length; ++i) {
                total -= rarities[uint256(xs[i])];
                rarities[uint256(xs[i])] = 0;
            }
        }

        if (
            md.accessory == Accessory.GOLD_EARRINGS ||
            md.eyes == Eyes.BLUE_LASER ||
            md.eyes == Eyes.BLUE_SHADES ||
            md.eyes == Eyes.DARK_SUNGLASSES ||
            md.eyes == Eyes.GOLDEN_SHADES ||
            md.eyes == Eyes.HUD_GLASSES ||
            md.eyes == Eyes.HIPSTER_GLASSES ||
            md.eyes == Eyes.HIVE_GOGGLES ||
            md.eyes == Eyes.MATRIX_GLASSES ||
            md.eyes == Eyes.NIGHT_VISION_GOGGLES ||
            md.eyes == Eyes.NOUNS_GLASSES ||
            md.eyes == Eyes.PINCENEZ ||
            md.eyes == Eyes.RED_LASER ||
            md.eyes == Eyes.SUNGLASSES ||
            md.eyes == Eyes.WHITE_SUNGLASSES ||
            md.mouth == Mouth.BANANA ||
            md.mouth == Mouth.CHROME_RESPIRATOR ||
            md.mouth == Mouth.CIGAR ||
            md.mouth == Mouth.GREEN_RESPIRATOR ||
            md.mouth == Mouth.MAGENTA_RESPIRATOR ||
            md.mouth == Mouth.MASK ||
            md.mouth == Mouth.MEMPO ||
            md.mouth == Mouth.NAVY_RESPIRATOR ||
            md.mouth == Mouth.PILOT_OXYGEN_MASK ||
            md.mouth == Mouth.PIPE ||
            md.mouth == Mouth.RED_RESPIRATOR ||
            md.mouth == Mouth.VAPE
        ) {
            total -= rarities[uint256(Head.SPACESUIT_HELMET)];
            rarities[uint256(Head.SPACESUIT_HELMET)] = 0;
        }

        md.head = Head(getRandom(rng, total, rarities));

        staticRng = rng;
        chainScouts.adminSetChainScoutMetadata(tokenId, md);
    }

    function rerollMouth(uint256 tokenId)
        external
        canAccessToken(tokenId)
        whenEnabled
    {
        token.burn(msg.sender, mouthCost);

        ChainScoutMetadata memory md = chainScouts.getChainScoutMetadata(
            tokenId
        );
        Rng memory rng = staticRng;

        uint16[] memory rarities = Rarities.mouth();
        uint256 total = 10000;

        total -= rarities[uint256(md.mouth)];
        rarities[uint256(md.mouth)] = 0;

        if (
            md.eyes == Eyes.BLUE_LASER ||
            md.eyes == Eyes.RED_LASER ||
            md.head == Head.CYBER_HELMET__BLUE ||
            md.head == Head.CYBER_HELMET__RED ||
            md.head == Head.SPACESUIT_HELMET
        ) {
            total -= rarities[uint256(Mouth.BANANA)];
            rarities[uint256(Mouth.BANANA)] = 0;
        }

        if (
            md.clothing == Clothing.FLEET_UNIFORM__BLUE ||
            md.clothing == Clothing.FLEET_UNIFORM__RED ||
            md.eyes == Eyes.BLUE_LASER ||
            md.eyes == Eyes.BLUE_SHADES ||
            md.eyes == Eyes.DARK_SUNGLASSES ||
            md.eyes == Eyes.GOLDEN_SHADES ||
            md.eyes == Eyes.HIPSTER_GLASSES ||
            md.eyes == Eyes.NOUNS_GLASSES ||
            md.eyes == Eyes.RED_LASER ||
            md.eyes == Eyes.SPACE_VISOR ||
            md.head == Head.BANDANA ||
            md.head == Head.CYBER_HELMET__BLUE ||
            md.head == Head.CYBER_HELMET__RED ||
            md.head == Head.DORAG ||
            md.head == Head.SPACESUIT_HELMET
        ) {
            Mouth[5] memory xs = [
                Mouth.CHROME_RESPIRATOR,
                Mouth.GREEN_RESPIRATOR,
                Mouth.MAGENTA_RESPIRATOR,
                Mouth.NAVY_RESPIRATOR,
                Mouth.RED_RESPIRATOR
            ];
            for (uint256 i = 0; i < xs.length; ++i) {
                total -= rarities[uint256(xs[i])];
                rarities[uint256(xs[i])] = 0;
            }
        }

        if (
            md.head == Head.CYBER_HELMET__BLUE ||
            md.head == Head.CYBER_HELMET__RED ||
            md.head == Head.SPACESUIT_HELMET
        ) {
            Mouth[3] memory xs = [Mouth.CIGAR, Mouth.PIPE, Mouth.VAPE];
            for (uint256 i = 0; i < xs.length; ++i) {
                total -= rarities[uint256(xs[i])];
                rarities[uint256(xs[i])] = 0;
            }
        }

        if (
            uint256(md.eyes) == 0 ||
            uint256(md.eyes) == 13 ||
            uint256(md.eyes) == 25 ||
            uint256(md.eyes) == 26 ||
            uint256(md.eyes) == 27 ||
            uint256(md.eyes) == 28 ||
            uint256(md.eyes) == 30 ||
            uint256(md.eyes) == 32 ||
            uint256(md.head) == 14 ||
            uint256(md.head) == 18 ||
            uint256(md.head) == 19
        ) {
            Mouth[5] memory xs = [
                Mouth.CHROME_RESPIRATOR,
                Mouth.GREEN_RESPIRATOR,
                Mouth.MAGENTA_RESPIRATOR,
                Mouth.NAVY_RESPIRATOR,
                Mouth.RED_RESPIRATOR
            ];
            for (uint256 i = 0; i < xs.length; ++i) {
                total -= rarities[uint256(xs[i])];
                rarities[uint256(xs[i])] = 0;
            }
        }

        if (
            md.eyes == Eyes.BLUE_LASER ||
            md.eyes == Eyes.BLUE_SHADES ||
            md.eyes == Eyes.DARK_SUNGLASSES ||
            md.eyes == Eyes.GOLDEN_SHADES ||
            md.eyes == Eyes.HIPSTER_GLASSES ||
            md.eyes == Eyes.NOUNS_GLASSES ||
            md.eyes == Eyes.PINCENEZ ||
            md.eyes == Eyes.RED_LASER ||
            md.eyes == Eyes.SUNGLASSES ||
            md.head == Head.SPACESUIT_HELMET
        ) {
            total -= rarities[uint256(Mouth.MASK)];
            rarities[uint256(Mouth.MASK)] = 0;
        }

        if (
            md.eyes == Eyes.BLUE_LASER ||
            md.eyes == Eyes.HIPSTER_GLASSES ||
            md.eyes == Eyes.NOUNS_GLASSES ||
            md.eyes == Eyes.PINCENEZ ||
            md.eyes == Eyes.RED_LASER ||
            md.eyes == Eyes.SPACE_VISOR ||
            md.head == Head.CYBER_HELMET__BLUE ||
            md.head == Head.CYBER_HELMET__RED ||
            md.head == Head.SPACESUIT_HELMET
        ) {
            total -= rarities[uint256(Mouth.MEMPO)];
            rarities[uint256(Mouth.MEMPO)] = 0;
        }

        if (
            md.eyes == Eyes.BLUE_LASER ||
            md.eyes == Eyes.NOUNS_GLASSES ||
            md.eyes == Eyes.RED_LASER ||
            md.head == Head.CYBER_HELMET__BLUE ||
            md.head == Head.CYBER_HELMET__RED ||
            md.head == Head.SPACESUIT_HELMET
        ) {
            total -= rarities[uint256(Mouth.PILOT_OXYGEN_MASK)];
            rarities[uint256(Mouth.PILOT_OXYGEN_MASK)] = 0;
        }

        md.mouth = Mouth(getRandom(rng, total, rarities));

        staticRng = rng;
        chainScouts.adminSetChainScoutMetadata(tokenId, md);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IChainScouts.sol";

abstract contract ChainScoutsExtension {
    IChainScouts internal chainScouts;

    modifier onlyAdmin() {
        require(chainScouts.isAdmin(msg.sender), "ChainScoutsExtension: admins only");
        _;
    }

    modifier canAccessToken(uint tokenId) {
        require(chainScouts.canAccessToken(msg.sender, tokenId), "ChainScoutsExtension: you don't own the token");
        _;
    }

    function extensionKey() public virtual view returns (string memory);

    function setChainScouts(IChainScouts _contract) external {
        require(address(0) == address(chainScouts) || chainScouts.isAdmin(msg.sender), "ChainScoutsExtension: The Chain Scouts contract must not be set or you must be an admin");
        chainScouts = _contract;
        chainScouts.adminSetExtension(extensionKey(), this);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IUtilityERC20 is IERC20 {
    function adminMint(address owner, uint amountWei) external;

    function adminSetTokenTimestamp(uint tokenId, uint timestamp) external;

    function burn(address owner, uint amountWei) external;

    function claimRewards() external;

    function stake(uint[] calldata tokenId) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Enums.sol";

library Rarities {
    function accessory() internal pure returns (uint16[] memory ret) {
        ret = new uint16[](7);
        ret[0] = 1200;
        ret[1] = 800;
        ret[2] = 800;
        ret[3] = 400;
        ret[4] = 400;
        ret[5] = 400;
        ret[6] = 6000;
    }

    function backaccessory() internal pure returns (uint16[] memory ret) {
        ret = new uint16[](8);
        ret[0] = 200;
        ret[1] = 1300;
        ret[2] = 800;
        ret[3] = 400;
        ret[4] = 1100;
        ret[5] = 700;
        ret[6] = 500;
        ret[7] = 5000;
    }

    function background() internal pure returns (uint16[] memory ret) {
        ret = new uint16[](23);
        ret[0] = 600;
        ret[1] = 600;
        ret[2] = 600;
        ret[3] = 600;
        ret[4] = 500;
        ret[5] = 500;
        ret[6] = 500;
        ret[7] = 500;
        ret[8] = 500;
        ret[9] = 500;
        ret[10] = 100;
        ret[11] = 100;
        ret[12] = 100;
        ret[13] = 600;
        ret[14] = 600;
        ret[15] = 600;
        ret[16] = 100;
        ret[17] = 100;
        ret[18] = 400;
        ret[19] = 400;
        ret[20] = 500;
        ret[21] = 500;
        ret[22] = 500;
    }

    function clothing() internal pure returns (uint16[] memory ret) {
        ret = new uint16[](24);
        ret[0] = 500;
        ret[1] = 500;
        ret[2] = 300;
        ret[3] = 300;
        ret[4] = 500;
        ret[5] = 400;
        ret[6] = 300;
        ret[7] = 250;
        ret[8] = 250;
        ret[9] = 500;
        ret[10] = 100;
        ret[11] = 500;
        ret[12] = 300;
        ret[13] = 500;
        ret[14] = 500;
        ret[15] = 500;
        ret[16] = 100;
        ret[17] = 400;
        ret[18] = 400;
        ret[19] = 250;
        ret[20] = 250;
        ret[21] = 250;
        ret[22] = 150;
        ret[23] = 2000;
    }

    function eyes() internal pure returns (uint16[] memory ret) {
        ret = new uint16[](32);
        ret[0] = 250;
        ret[1] = 700;
        ret[2] = 225;
        ret[3] = 350;
        ret[4] = 125;
        ret[5] = 450;
        ret[6] = 700;
        ret[7] = 700;
        ret[8] = 350;
        ret[9] = 350;
        ret[10] = 600;
        ret[11] = 450;
        ret[12] = 250;
        ret[13] = 350;
        ret[14] = 350;
        ret[15] = 225;
        ret[16] = 125;
        ret[17] = 350;
        ret[18] = 200;
        ret[19] = 200;
        ret[20] = 200;
        ret[21] = 200;
        ret[22] = 200;
        ret[23] = 200;
        ret[24] = 50;
        ret[25] = 50;
        ret[26] = 450;
        ret[27] = 450;
        ret[28] = 400;
        ret[29] = 450;
        ret[30] = 25;
        ret[31] = 25;
    }

    function fur() internal pure returns (uint16[] memory ret) {
        ret = new uint16[](16);
        ret[0] = 1100;
        ret[1] = 1100;
        ret[2] = 1100;
        ret[3] = 525;
        ret[4] = 350;
        ret[5] = 1100;
        ret[6] = 350;
        ret[7] = 1100;
        ret[8] = 1000;
        ret[9] = 525;
        ret[10] = 525;
        ret[11] = 500;
        ret[12] = 525;
        ret[13] = 100;
        ret[14] = 50;
        ret[15] = 50;
    }

    function head() internal pure returns (uint16[] memory ret) {
        ret = new uint16[](21);
        ret[0] = 200;
        ret[1] = 200;
        ret[2] = 350;
        ret[3] = 350;
        ret[4] = 350;
        ret[5] = 150;
        ret[6] = 600;
        ret[7] = 350;
        ret[8] = 350;
        ret[9] = 350;
        ret[10] = 600;
        ret[11] = 600;
        ret[12] = 600;
        ret[13] = 200;
        ret[14] = 350;
        ret[15] = 600;
        ret[16] = 600;
        ret[17] = 50;
        ret[18] = 50;
        ret[19] = 100;
        ret[20] = 3000;
    }

    function mouth() internal pure returns (uint16[] memory ret) {
        ret = new uint16[](21);
        ret[0] = 1000;
        ret[1] = 1000;
        ret[2] = 1000;
        ret[3] = 650;
        ret[4] = 1000;
        ret[5] = 900;
        ret[6] = 750;
        ret[7] = 650;
        ret[8] = 100;
        ret[9] = 50;
        ret[10] = 100;
        ret[11] = 100;
        ret[12] = 100;
        ret[13] = 100;
        ret[14] = 50;
        ret[15] = 100;
        ret[16] = 100;
        ret[17] = 600;
        ret[18] = 600;
        ret[19] = 50;
        ret[20] = 1000;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title A pseudo random number generator
 *
 * @dev This is not a true random number generator because smart contracts must be deterministic (every node a transaction goes to must produce the same result).
 *      True randomness requires an oracle which is both expensive in terms of gas and would take a critical part of the project off the chain.
 */
struct Rng {
    bytes32 state;
}

/**
 * @title A library for working with the Rng struct.
 *
 * @dev Rng cannot be a contract because then anyone could manipulate it by generating random numbers.
 */
library RngLibrary {
    /**
     * Creates a new Rng.
     */
    function newRng() internal view returns (Rng memory) {
        return Rng(getEntropy());
    }

    /**
     * Creates a pseudo-random value from the current block miner's address and sender.
     */
    function getEntropy() internal view returns (bytes32) {
        return keccak256(abi.encodePacked(block.coinbase, msg.sender));
    }

    /**
     * Generates a random uint256.
     */
    function generate(Rng memory self) internal view returns (uint256) {
        self.state = keccak256(abi.encodePacked(getEntropy(), self.state));
        return uint256(self.state);
    }

    /**
     * Generates a random uint256 from min to max inclusive.
     *
     * @dev This function is not subject to modulo bias.
     *      The chance that this function has to reroll is astronomically unlikely, but it can theoretically reroll forever.
     */
    function generate(Rng memory self, uint min, uint max) internal view returns (uint256) {
        require(min <= max, "min > max");

        uint delta = max - min;

        if (delta == 0) {
            return min;
        }

        return generate(self) % (delta + 1) + min;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IExtensibleERC721Enumerable.sol";
import "./ChainScoutsExtension.sol";
import "./ChainScoutMetadata.sol";

interface IChainScouts is IExtensibleERC721Enumerable {
    function adminCreateChainScout(
        ChainScoutMetadata calldata tbd,
        address owner
    ) external;

    function adminRemoveExtension(string calldata key) external;

    function adminSetExtension(
        string calldata key,
        ChainScoutsExtension extension
    ) external;

    function adminSetChainScoutMetadata(
        uint256 tokenId,
        ChainScoutMetadata calldata tbd
    ) external;

    function getChainScoutMetadata(uint256 tokenId)
        external
        view
        returns (ChainScoutMetadata memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IExtensibleERC721Enumerable is IERC721Enumerable {
    function isAdmin(address addr) external view returns (bool);

    function addAdmin(address addr) external;

    function removeAdmin(address addr) external;

    function canAccessToken(address addr, uint tokenId) external view returns (bool);

    function adminBurn(uint tokenId) external;

    function adminTransfer(address from, address to, uint tokenId) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Enums.sol";

struct KeyValuePair {
    string key;
    string value;
}

struct ChainScoutMetadata {
    Accessory accessory;
    BackAccessory backaccessory;
    Background background;
    Clothing clothing;
    Eyes eyes;
    Fur fur;
    Head head;
    Mouth mouth;
    uint24 attack;
    uint24 defense;
    uint24 luck;
    uint24 speed;
    uint24 strength;
    uint24 intelligence;
    uint16 level;
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

enum Accessory {
    GOLD_EARRINGS,
    SCARS,
    GOLDEN_CHAIN,
    AMULET,
    CUBAN_LINK_GOLD_CHAIN,
    FANNY_PACK,
    NONE
}

enum BackAccessory {
    NETRUNNER,
    MERCENARY,
    RONIN,
    ENCHANTER,
    VANGUARD,
    MINER,
    PATHFINDER,
    SCOUT
}

enum Background {
    STARRY_PINK,
    STARRY_YELLOW,
    STARRY_PURPLE,
    STARRY_GREEN,
    NEBULA,
    STARRY_RED,
    STARRY_BLUE,
    SUNSET,
    MORNING,
    INDIGO,
    CITY__PURPLE,
    CONTROL_ROOM,
    LAB,
    GREEN,
    ORANGE,
    PURPLE,
    CITY__GREEN,
    CITY__RED,
    STATION,
    BOUNTY,
    BLUE_SKY,
    RED_SKY,
    GREEN_SKY
}

enum Clothing {
    MARTIAL_SUIT,
    AMETHYST_ARMOR,
    SHIRT_AND_TIE,
    THUNDERDOME_ARMOR,
    FLEET_UNIFORM__BLUE,
    BANANITE_SHIRT,
    EXPLORER,
    COSMIC_GHILLIE_SUIT__BLUE,
    COSMIC_GHILLIE_SUIT__GOLD,
    CYBER_JUMPSUIT,
    ENCHANTER_ROBES,
    HOODIE,
    SPACESUIT,
    MECHA_ARMOR,
    LAB_COAT,
    FLEET_UNIFORM__RED,
    GOLD_ARMOR,
    ENERGY_ARMOR__BLUE,
    ENERGY_ARMOR__RED,
    MISSION_SUIT__BLACK,
    MISSION_SUIT__PURPLE,
    COWBOY,
    GLITCH_ARMOR,
    NONE
}

enum Eyes {
    SPACE_VISOR,
    ADORABLE,
    VETERAN,
    SUNGLASSES,
    WHITE_SUNGLASSES,
    RED_EYES,
    WINK,
    CASUAL,
    CLOSED,
    DOWNCAST,
    HAPPY,
    BLUE_EYES,
    HUD_GLASSES,
    DARK_SUNGLASSES,
    NIGHT_VISION_GOGGLES,
    BIONIC,
    HIVE_GOGGLES,
    MATRIX_GLASSES,
    GREEN_GLOW,
    ORANGE_GLOW,
    RED_GLOW,
    PURPLE_GLOW,
    BLUE_GLOW,
    SKY_GLOW,
    RED_LASER,
    BLUE_LASER,
    GOLDEN_SHADES,
    HIPSTER_GLASSES,
    PINCENEZ,
    BLUE_SHADES,
    BLIT_GLASSES,
    NOUNS_GLASSES
}

enum Fur {
    MAGENTA,
    BLUE,
    GREEN,
    RED,
    BLACK,
    BROWN,
    SILVER,
    PURPLE,
    PINK,
    SEANCE,
    TURQUOISE,
    CRIMSON,
    GREENYELLOW,
    GOLD,
    DIAMOND,
    METALLIC
}

enum Head {
    HALO,
    ENERGY_FIELD,
    BLUE_TOP_HAT,
    RED_TOP_HAT,
    ENERGY_CRYSTAL,
    CROWN,
    BANDANA,
    BUCKET_HAT,
    HOMBURG_HAT,
    PROPELLER_HAT,
    HEADBAND,
    DORAG,
    PURPLE_COWBOY_HAT,
    SPACESUIT_HELMET,
    PARTY_HAT,
    CAP,
    LEATHER_COWBOY_HAT,
    CYBER_HELMET__BLUE,
    CYBER_HELMET__RED,
    SAMURAI_HAT,
    NONE
}

enum Mouth {
    SMIRK,
    SURPRISED,
    SMILE,
    PIPE,
    OPEN_SMILE,
    NEUTRAL,
    MASK,
    TONGUE_OUT,
    GOLD_GRILL,
    DIAMOND_GRILL,
    NAVY_RESPIRATOR,
    RED_RESPIRATOR,
    MAGENTA_RESPIRATOR,
    GREEN_RESPIRATOR,
    MEMPO,
    VAPE,
    PILOT_OXYGEN_MASK,
    CIGAR,
    BANANA,
    CHROME_RESPIRATOR,
    STOIC
}

library Enums {
    function toString(Accessory v) external pure returns (string memory) {
        if (v == Accessory.GOLD_EARRINGS) {
            return "Gold Earrings";
        }

        if (v == Accessory.SCARS) {
            return "Scars";
        }

        if (v == Accessory.GOLDEN_CHAIN) {
            return "Golden Chain";
        }

        if (v == Accessory.AMULET) {
            return "Amulet";
        }

        if (v == Accessory.CUBAN_LINK_GOLD_CHAIN) {
            return "Cuban Link Gold Chain";
        }

        if (v == Accessory.FANNY_PACK) {
            return "Fanny Pack";
        }

        if (v == Accessory.NONE) {
            return "None";
        }
        revert("invalid accessory");
    }

    function toString(BackAccessory v) external pure returns (string memory) {
        if (v == BackAccessory.NETRUNNER) {
            return "Netrunner";
        }

        if (v == BackAccessory.MERCENARY) {
            return "Mercenary";
        }

        if (v == BackAccessory.RONIN) {
            return "Ronin";
        }

        if (v == BackAccessory.ENCHANTER) {
            return "Enchanter";
        }

        if (v == BackAccessory.VANGUARD) {
            return "Vanguard";
        }

        if (v == BackAccessory.MINER) {
            return "Miner";
        }

        if (v == BackAccessory.PATHFINDER) {
            return "Pathfinder";
        }

        if (v == BackAccessory.SCOUT) {
            return "Scout";
        }
        revert("invalid back accessory");
    }

    function toString(Background v) external pure returns (string memory) {
        if (v == Background.STARRY_PINK) {
            return "Starry Pink";
        }

        if (v == Background.STARRY_YELLOW) {
            return "Starry Yellow";
        }

        if (v == Background.STARRY_PURPLE) {
            return "Starry Purple";
        }

        if (v == Background.STARRY_GREEN) {
            return "Starry Green";
        }

        if (v == Background.NEBULA) {
            return "Nebula";
        }

        if (v == Background.STARRY_RED) {
            return "Starry Red";
        }

        if (v == Background.STARRY_BLUE) {
            return "Starry Blue";
        }

        if (v == Background.SUNSET) {
            return "Sunset";
        }

        if (v == Background.MORNING) {
            return "Morning";
        }

        if (v == Background.INDIGO) {
            return "Indigo";
        }

        if (v == Background.CITY__PURPLE) {
            return "City - Purple";
        }

        if (v == Background.CONTROL_ROOM) {
            return "Control Room";
        }

        if (v == Background.LAB) {
            return "Lab";
        }

        if (v == Background.GREEN) {
            return "Green";
        }

        if (v == Background.ORANGE) {
            return "Orange";
        }

        if (v == Background.PURPLE) {
            return "Purple";
        }

        if (v == Background.CITY__GREEN) {
            return "City - Green";
        }

        if (v == Background.CITY__RED) {
            return "City - Red";
        }

        if (v == Background.STATION) {
            return "Station";
        }

        if (v == Background.BOUNTY) {
            return "Bounty";
        }

        if (v == Background.BLUE_SKY) {
            return "Blue Sky";
        }

        if (v == Background.RED_SKY) {
            return "Red Sky";
        }

        if (v == Background.GREEN_SKY) {
            return "Green Sky";
        }
        revert("invalid background");
    }

    function toString(Clothing v) external pure returns (string memory) {
        if (v == Clothing.MARTIAL_SUIT) {
            return "Martial Suit";
        }

        if (v == Clothing.AMETHYST_ARMOR) {
            return "Amethyst Armor";
        }

        if (v == Clothing.SHIRT_AND_TIE) {
            return "Shirt and Tie";
        }

        if (v == Clothing.THUNDERDOME_ARMOR) {
            return "Thunderdome Armor";
        }

        if (v == Clothing.FLEET_UNIFORM__BLUE) {
            return "Fleet Uniform - Blue";
        }

        if (v == Clothing.BANANITE_SHIRT) {
            return "Bananite Shirt";
        }

        if (v == Clothing.EXPLORER) {
            return "Explorer";
        }

        if (v == Clothing.COSMIC_GHILLIE_SUIT__BLUE) {
            return "Cosmic Ghillie Suit - Blue";
        }

        if (v == Clothing.COSMIC_GHILLIE_SUIT__GOLD) {
            return "Cosmic Ghillie Suit - Gold";
        }

        if (v == Clothing.CYBER_JUMPSUIT) {
            return "Cyber Jumpsuit";
        }

        if (v == Clothing.ENCHANTER_ROBES) {
            return "Enchanter Robes";
        }

        if (v == Clothing.HOODIE) {
            return "Hoodie";
        }

        if (v == Clothing.SPACESUIT) {
            return "Spacesuit";
        }

        if (v == Clothing.MECHA_ARMOR) {
            return "Mecha Armor";
        }

        if (v == Clothing.LAB_COAT) {
            return "Lab Coat";
        }

        if (v == Clothing.FLEET_UNIFORM__RED) {
            return "Fleet Uniform - Red";
        }

        if (v == Clothing.GOLD_ARMOR) {
            return "Gold Armor";
        }

        if (v == Clothing.ENERGY_ARMOR__BLUE) {
            return "Energy Armor - Blue";
        }

        if (v == Clothing.ENERGY_ARMOR__RED) {
            return "Energy Armor - Red";
        }

        if (v == Clothing.MISSION_SUIT__BLACK) {
            return "Mission Suit - Black";
        }

        if (v == Clothing.MISSION_SUIT__PURPLE) {
            return "Mission Suit - Purple";
        }

        if (v == Clothing.COWBOY) {
            return "Cowboy";
        }

        if (v == Clothing.GLITCH_ARMOR) {
            return "Glitch Armor";
        }

        if (v == Clothing.NONE) {
            return "None";
        }
        revert("invalid clothing");
    }

    function toString(Eyes v) external pure returns (string memory) {
        if (v == Eyes.SPACE_VISOR) {
            return "Space Visor";
        }

        if (v == Eyes.ADORABLE) {
            return "Adorable";
        }

        if (v == Eyes.VETERAN) {
            return "Veteran";
        }

        if (v == Eyes.SUNGLASSES) {
            return "Sunglasses";
        }

        if (v == Eyes.WHITE_SUNGLASSES) {
            return "White Sunglasses";
        }

        if (v == Eyes.RED_EYES) {
            return "Red Eyes";
        }

        if (v == Eyes.WINK) {
            return "Wink";
        }

        if (v == Eyes.CASUAL) {
            return "Casual";
        }

        if (v == Eyes.CLOSED) {
            return "Closed";
        }

        if (v == Eyes.DOWNCAST) {
            return "Downcast";
        }

        if (v == Eyes.HAPPY) {
            return "Happy";
        }

        if (v == Eyes.BLUE_EYES) {
            return "Blue Eyes";
        }

        if (v == Eyes.HUD_GLASSES) {
            return "HUD Glasses";
        }

        if (v == Eyes.DARK_SUNGLASSES) {
            return "Dark Sunglasses";
        }

        if (v == Eyes.NIGHT_VISION_GOGGLES) {
            return "Night Vision Goggles";
        }

        if (v == Eyes.BIONIC) {
            return "Bionic";
        }

        if (v == Eyes.HIVE_GOGGLES) {
            return "Hive Goggles";
        }

        if (v == Eyes.MATRIX_GLASSES) {
            return "Matrix Glasses";
        }

        if (v == Eyes.GREEN_GLOW) {
            return "Green Glow";
        }

        if (v == Eyes.ORANGE_GLOW) {
            return "Orange Glow";
        }

        if (v == Eyes.RED_GLOW) {
            return "Red Glow";
        }

        if (v == Eyes.PURPLE_GLOW) {
            return "Purple Glow";
        }

        if (v == Eyes.BLUE_GLOW) {
            return "Blue Glow";
        }

        if (v == Eyes.SKY_GLOW) {
            return "Sky Glow";
        }

        if (v == Eyes.RED_LASER) {
            return "Red Laser";
        }

        if (v == Eyes.BLUE_LASER) {
            return "Blue Laser";
        }

        if (v == Eyes.GOLDEN_SHADES) {
            return "Golden Shades";
        }

        if (v == Eyes.HIPSTER_GLASSES) {
            return "Hipster Glasses";
        }

        if (v == Eyes.PINCENEZ) {
            return "Pince-nez";
        }

        if (v == Eyes.BLUE_SHADES) {
            return "Blue Shades";
        }

        if (v == Eyes.BLIT_GLASSES) {
            return "Blit GLasses";
        }

        if (v == Eyes.NOUNS_GLASSES) {
            return "Nouns Glasses";
        }
        revert("invalid eyes");
    }

    function toString(Fur v) external pure returns (string memory) {
        if (v == Fur.MAGENTA) {
            return "Magenta";
        }

        if (v == Fur.BLUE) {
            return "Blue";
        }

        if (v == Fur.GREEN) {
            return "Green";
        }

        if (v == Fur.RED) {
            return "Red";
        }

        if (v == Fur.BLACK) {
            return "Black";
        }

        if (v == Fur.BROWN) {
            return "Brown";
        }

        if (v == Fur.SILVER) {
            return "Silver";
        }

        if (v == Fur.PURPLE) {
            return "Purple";
        }

        if (v == Fur.PINK) {
            return "Pink";
        }

        if (v == Fur.SEANCE) {
            return "Seance";
        }

        if (v == Fur.TURQUOISE) {
            return "Turquoise";
        }

        if (v == Fur.CRIMSON) {
            return "Crimson";
        }

        if (v == Fur.GREENYELLOW) {
            return "Green-Yellow";
        }

        if (v == Fur.GOLD) {
            return "Gold";
        }

        if (v == Fur.DIAMOND) {
            return "Diamond";
        }

        if (v == Fur.METALLIC) {
            return "Metallic";
        }
        revert("invalid fur");
    }

    function toString(Head v) external pure returns (string memory) {
        if (v == Head.HALO) {
            return "Halo";
        }

        if (v == Head.ENERGY_FIELD) {
            return "Energy Field";
        }

        if (v == Head.BLUE_TOP_HAT) {
            return "Blue Top Hat";
        }

        if (v == Head.RED_TOP_HAT) {
            return "Red Top Hat";
        }

        if (v == Head.ENERGY_CRYSTAL) {
            return "Energy Crystal";
        }

        if (v == Head.CROWN) {
            return "Crown";
        }

        if (v == Head.BANDANA) {
            return "Bandana";
        }

        if (v == Head.BUCKET_HAT) {
            return "Bucket Hat";
        }

        if (v == Head.HOMBURG_HAT) {
            return "Homburg Hat";
        }

        if (v == Head.PROPELLER_HAT) {
            return "Propeller Hat";
        }

        if (v == Head.HEADBAND) {
            return "Headband";
        }

        if (v == Head.DORAG) {
            return "Do-rag";
        }

        if (v == Head.PURPLE_COWBOY_HAT) {
            return "Purple Cowboy Hat";
        }

        if (v == Head.SPACESUIT_HELMET) {
            return "Spacesuit Helmet";
        }

        if (v == Head.PARTY_HAT) {
            return "Party Hat";
        }

        if (v == Head.CAP) {
            return "Cap";
        }

        if (v == Head.LEATHER_COWBOY_HAT) {
            return "Leather Cowboy Hat";
        }

        if (v == Head.CYBER_HELMET__BLUE) {
            return "Cyber Helmet - Blue";
        }

        if (v == Head.CYBER_HELMET__RED) {
            return "Cyber Helmet - Red";
        }

        if (v == Head.SAMURAI_HAT) {
            return "Samurai Hat";
        }

        if (v == Head.NONE) {
            return "None";
        }
        revert("invalid head");
    }

    function toString(Mouth v) external pure returns (string memory) {
        if (v == Mouth.SMIRK) {
            return "Smirk";
        }

        if (v == Mouth.SURPRISED) {
            return "Surprised";
        }

        if (v == Mouth.SMILE) {
            return "Smile";
        }

        if (v == Mouth.PIPE) {
            return "Pipe";
        }

        if (v == Mouth.OPEN_SMILE) {
            return "Open Smile";
        }

        if (v == Mouth.NEUTRAL) {
            return "Neutral";
        }

        if (v == Mouth.MASK) {
            return "Mask";
        }

        if (v == Mouth.TONGUE_OUT) {
            return "Tongue Out";
        }

        if (v == Mouth.GOLD_GRILL) {
            return "Gold Grill";
        }

        if (v == Mouth.DIAMOND_GRILL) {
            return "Diamond Grill";
        }

        if (v == Mouth.NAVY_RESPIRATOR) {
            return "Navy Respirator";
        }

        if (v == Mouth.RED_RESPIRATOR) {
            return "Red Respirator";
        }

        if (v == Mouth.MAGENTA_RESPIRATOR) {
            return "Magenta Respirator";
        }

        if (v == Mouth.GREEN_RESPIRATOR) {
            return "Green Respirator";
        }

        if (v == Mouth.MEMPO) {
            return "Mempo";
        }

        if (v == Mouth.VAPE) {
            return "Vape";
        }

        if (v == Mouth.PILOT_OXYGEN_MASK) {
            return "Pilot Oxygen Mask";
        }

        if (v == Mouth.CIGAR) {
            return "Cigar";
        }

        if (v == Mouth.BANANA) {
            return "Banana";
        }

        if (v == Mouth.CHROME_RESPIRATOR) {
            return "Chrome Respirator";
        }

        if (v == Mouth.STOIC) {
            return "Stoic";
        }
        revert("invalid mouth");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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