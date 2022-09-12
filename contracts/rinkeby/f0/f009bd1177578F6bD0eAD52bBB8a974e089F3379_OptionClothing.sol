// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "../../lib_constants/TraitDefs.sol";
import "../../lib_constants/trait_options/TraitOptionsClothing.sol";
import "../../lib_constants/trait_options/TraitOptionsSpecies.sol";
import "../Gene.sol";
import "./OptionSpecies.sol";

/**
 * TRs are set on 5 Species, 2 Locales
 * 5 Species
 *  - Black Bear
 *    - Exc
 *      - Clothing
 *        - All Red assets, Black Tuxedo
 *      - Hat
 *        - All Red Assets
 *        - All Black (only) Assets
 *      - Accessories
 *        - All red
 *        - Basked of used Graphics cards
 *        - Burned out graphics card
 *        - Proof of Ribeye Steak
*       - Face accessory
          - All Reds
        - Jewelry
          - All reds
          - RPL medallion
*   - White Bear
      - Exc
        - Clothing
          - (similar )

    - Pandas
      - Exc
        - Clothing
          - POW Shirts (2)
          - Miners Garbs (2)
          - 
        - Accessories
          - Pickaxe
     Locales
      - NA
        - Face Accessory
          - Blk Ninja Mask
          - Blue Ninja
          - Red Ninja
          - White Ninja
      - Asian
        - Hat
          - Pink Sunhat
          - Tan Sunhat
 * X Clothing
 * - B&W Striped Jail Uniform (excludes some Jewelry)
 * - Black Tuxedo (ex Accessory Dumbbells)
 * - Ghost (incl only "NONE" for Accessory, FaceAccessory)
 * X Hat
 * - Blue Astronaut Helmet (exc some face Accessories)
 * - Red Astronaut Helmet (exc some face Accessories)
 * 
 * 
 *  - Will need rules on Clothing, Hat, Accessories, Face Accessory, Jewelry
 * 
 *  - Clothing rules from: Species
 *  - Hat rules from: Species, Locales
 *  - Jewelry rules from: Species, Clothing
 *  - Footwear rules from: Species
 *  - Accessories rules from: Species, Clothing
 *  - Face Accessory rules from: Species, Locales, Clothing, Hat
 */

/**
 * TR deps from Species,
 */
library OptionClothing {
  function getOption(uint256 dna) public pure returns (uint8) {
    uint16 clothes = Gene.getGene(TraitDefs.CLOTHING, dna);
    uint16 variant = clothes % 2078; // multiplier configured from weights
    // trait dependencies
    uint8 species = OptionSpecies.getOption(dna); //Gene.getGene(TraitDefs.SPECIES, dna);

    // BLUE CLOTHES
    if (species == TraitOptionsSpecies.BLACK) {
      if (variant >= 0 && variant < 80) {
        return TraitOptionsClothing.BLUE_ERC20_SHIRT;
      } else if (variant >= 80 && variant < 160) {
        return TraitOptionsClothing.BLUE_FOX_WALLET_TANKTOP;
      } else if (variant >= 160 && variant < 240) {
        return TraitOptionsClothing.BLUE_GRADIENT_DIAMOND_SHIRT;
      } else if (variant >= 240 && variant < 320) {
        return TraitOptionsClothing.BLUE_LINK_SHIRT;
      } else if (variant >= 320 && variant < 400) {
        return TraitOptionsClothing.BLUE_WEB3_SAFE_SHIRT;
      } else if (variant >= 400 && variant < 420) {
        return TraitOptionsClothing.BLACK_AND_BLUE_STRIPED_BIB;
      } else if (variant >= 420 && variant < 430) {
        return TraitOptionsClothing.BLACK_AND_WHITE_STRIPED_JAIL_UNIFORM;
      } else if (variant >= 430 && variant < 470) {
        return TraitOptionsClothing.BLACK_WITH_BLUE_DRESS;
      } else if (variant >= 470 && variant < 510) {
        return TraitOptionsClothing.BLACK_WITH_BLUE_STRIPES_TANKTOP;
      } else if (variant >= 510 && variant < 550) {
        return TraitOptionsClothing.BLUE_BEAR_LOVE_SHIRT;
      } else if (variant >= 550 && variant < 590) {
        return TraitOptionsClothing.BLUE_BEAR_MARKET_SHIRT;
      } else if (variant >= 590 && variant < 630) {
        return TraitOptionsClothing.BLUE_BULL_MARKET_SHIRT;
      } else if (variant >= 630 && variant < 670) {
        return TraitOptionsClothing.BLUE_DRESS_WITH_WHITE_DOTS;
      } else if (variant >= 670 && variant < 710) {
        return TraitOptionsClothing.BLUE_DRESS_WITH_WHITE_LACE;
      } else if (variant >= 710 && variant < 750) {
        return TraitOptionsClothing.BLUE_DRESS;
      } else if (variant >= 750 && variant < 790) {
        return TraitOptionsClothing.BLUE_ETH_SHIRT;
      } else if (variant >= 790 && variant < 830) {
        return TraitOptionsClothing.BLUE_FANNY_PACK;
      } else if (variant >= 830 && variant < 840) {
        return TraitOptionsClothing.BLUE_HOOLA_HOOP;
      } else if (variant >= 840 && variant < 880) {
        return TraitOptionsClothing.BLUE_HOOT_SHIRT;
      } else if (variant >= 880 && variant < 890) {
        return TraitOptionsClothing.BLUE_JESTERS_COLLAR;
      } else if (variant >= 890 && variant < 910) {
        return TraitOptionsClothing.BLUE_KNIT_SWEATER;
      } else if (variant >= 910 && variant < 914) {
        return TraitOptionsClothing.BLUE_LEG_WARMERS;
      } else if (variant >= 914 && variant < 954) {
        return TraitOptionsClothing.BLUE_OVERALLS;
      } else if (variant >= 954 && variant < 1034) {
        return TraitOptionsClothing.BLUE_PINK_UNICORN_DEX_TANKTOP;
      } else if (variant >= 1034 && variant < 1054) {
        return TraitOptionsClothing.BLUE_PONCHO;
      } else if (variant >= 1054 && variant < 1094) {
        return TraitOptionsClothing.BLUE_PORTAL_SHIRT;
      } else if (variant >= 1094 && variant < 1134) {
        return TraitOptionsClothing.DUSTY_NAVY_MINERS_GARB;
      } else if (variant >= 1134 && variant < 1174) {
        return TraitOptionsClothing.BLUE_PROOF_OF_WORK_SHIRT;
      } else if (variant >= 1174 && variant < 1214) {
        return TraitOptionsClothing.BLUE_PUFFY_VEST;
      } else if (variant >= 1214 && variant < 1254) {
        return TraitOptionsClothing.BLUE_REKT_SHIRT;
      } else if (variant >= 1254 && variant < 1334) {
        return TraitOptionsClothing.BLUE_RASPBERRY_PI_NODE_TANKTOP;
      } else if (variant >= 1334 && variant < 1374) {
        return TraitOptionsClothing.BLUE_SKIRT_WITH_BLACK_AND_WHITE_DOTS;
      } else if (variant >= 1374 && variant < 1414) {
        return TraitOptionsClothing.BLUE_SKIRT;
      } else if (variant >= 1414 && variant < 1454) {
        return TraitOptionsClothing.BLUE_STRIPED_NECKTIE;
      } else if (variant >= 1454 && variant < 1464) {
        return TraitOptionsClothing.BLUE_SUIT_JACKET_WITH_GOLD_TIE;
      } else if (variant >= 1464 && variant < 1504) {
        return TraitOptionsClothing.BLUE_TANKTOP;
      } else if (variant >= 1504 && variant < 1524) {
        return TraitOptionsClothing.BLUE_TOGA;
      } else if (variant >= 1524 && variant < 1564) {
        return TraitOptionsClothing.BLUE_TUBE_TOP;
      } else if (variant >= 1564 && variant < 1604) {
        return TraitOptionsClothing.BLUE_VEST;
      } else if (variant >= 1604 && variant < 1644) {
        return TraitOptionsClothing.BLUE_WAGMI_SHIRT;
      } else if (variant >= 1644 && variant < 1664) {
        return TraitOptionsClothing.BLUE_WITH_BLACK_STRIPES_SOCCER_JERSEY;
      } else if (variant >= 1664 && variant < 1674) {
        return TraitOptionsClothing.BLUE_WITH_PINK_AND_GREEN_DRESS;
      } else if (variant >= 1674 && variant < 1694) {
        return TraitOptionsClothing.BLUE_WITH_WHITE_APRON;
      } else if (variant >= 1694 && variant < 1704) {
        return TraitOptionsClothing.MAGICIAN_UNIFORM_WITH_BLUE_CAPE;
      } // END BLACK BEAR BLUE ASSETS
    } else if (species == TraitOptionsSpecies.POLAR) {
      // RED CLOTHES
      if (variant >= 0 && variant < 80) {
        return TraitOptionsClothing.RED_ERC20_SHIRT;
      } else if (variant >= 80 && variant < 160) {
        return TraitOptionsClothing.RED_FOX_WALLET_TANKTOP;
      } else if (variant >= 160 && variant < 240) {
        return TraitOptionsClothing.RED_GRADIENT_DIAMOND_SHIRT;
      } else if (variant >= 240 && variant < 320) {
        return TraitOptionsClothing.RED_LINK_SHIRT;
      } else if (variant >= 320 && variant < 400) {
        return TraitOptionsClothing.RED_WEB3_SAFE_SHIRT;
      } else if (variant >= 400 && variant < 420) {
        return TraitOptionsClothing.MAGICIAN_UNIFORM_WITH_RED_CAPE;
      } else if (variant >= 420 && variant < 430) {
        return TraitOptionsClothing.RED_BEAR_LOVE_SHIRT;
      } else if (variant >= 430 && variant < 470) {
        return TraitOptionsClothing.RED_BEAR_MARKET_SHIRT;
      } else if (variant >= 470 && variant < 510) {
        return TraitOptionsClothing.RED_BULL_MARKET_SHIRT;
      } else if (variant >= 510 && variant < 550) {
        return TraitOptionsClothing.RED_DRESS_WITH_WHITE_DOTS;
      } else if (variant >= 550 && variant < 590) {
        return TraitOptionsClothing.RED_DRESS_WITH_WHITE_LACE;
      } else if (variant >= 590 && variant < 630) {
        return TraitOptionsClothing.RED_DRESS;
      } else if (variant >= 630 && variant < 670) {
        return TraitOptionsClothing.RED_ETH_SHIRT;
      } else if (variant >= 670 && variant < 710) {
        return TraitOptionsClothing.RED_FANNY_PACK;
      } else if (variant >= 710 && variant < 750) {
        return TraitOptionsClothing.RED_HOOLA_HOOP;
      } else if (variant >= 750 && variant < 790) {
        return TraitOptionsClothing.RED_HOOT_SHIRT;
      } else if (variant >= 790 && variant < 830) {
        return TraitOptionsClothing.RED_JESTERS_COLLAR;
      } else if (variant >= 830 && variant < 840) {
        return TraitOptionsClothing.RED_KNIT_SWEATER;
      } else if (variant >= 840 && variant < 880) {
        return TraitOptionsClothing.RED_LEG_WARMERS;
      } else if (variant >= 880 && variant < 890) {
        return TraitOptionsClothing.RED_OVERALLS;
      } else if (variant >= 890 && variant < 910) {
        return TraitOptionsClothing.RED_PINK_UNICORN_DEX_TANKTOP;
      } else if (variant >= 910 && variant < 914) {
        return TraitOptionsClothing.RED_PONCHO;
      } else if (variant >= 914 && variant < 954) {
        return TraitOptionsClothing.RED_PORTAL_SHIRT;
      } else if (variant >= 954 && variant < 1034) {
        return TraitOptionsClothing.RED_PROOF_OF_WORK_SHIRT;
      } else if (variant >= 1034 && variant < 1054) {
        return TraitOptionsClothing.RED_PUFFY_VEST;
      } else if (variant >= 1054 && variant < 1094) {
        return TraitOptionsClothing.RED_REKT_SHIRT;
      }
      // gap between 1094 and 1134
      else if (variant >= 1134 && variant < 1174) {
        return TraitOptionsClothing.RED_RASPBERRY_PI_NODE_TANKTOP;
      } else if (variant >= 1174 && variant < 1214) {
        return TraitOptionsClothing.RED_SKIRT_WITH_BLACK_AND_WHITE_DOTS;
      } else if (variant >= 1214 && variant < 1254) {
        return TraitOptionsClothing.RED_SKIRT;
      } else if (variant >= 1254 && variant < 1334) {
        return TraitOptionsClothing.RED_STRIPED_NECKTIE;
      } else if (variant >= 1334 && variant < 1374) {
        return TraitOptionsClothing.RED_SUIT_JACKET_WITH_GOLD_TIE;
      } else if (variant >= 1374 && variant < 1414) {
        return TraitOptionsClothing.RED_TANKTOP;
      } else if (variant >= 1414 && variant < 1454) {
        return TraitOptionsClothing.RED_TOGA;
      } else if (variant >= 1454 && variant < 1464) {
        return TraitOptionsClothing.RED_TUBE_TOP;
      } else if (variant >= 1464 && variant < 1504) {
        return TraitOptionsClothing.RED_VEST;
      } else if (variant >= 1504 && variant < 1524) {
        return TraitOptionsClothing.RED_WAGMI_SHIRT;
      } else if (variant >= 1524 && variant < 1564) {
        return TraitOptionsClothing.RED_WITH_PINK_AND_GREEN_DRESS;
      } else if (variant >= 1564 && variant < 1604) {
        return TraitOptionsClothing.RED_WITH_WHITE_APRON;
      } else if (variant >= 1604 && variant < 1644) {
        return TraitOptionsClothing.RED_WITH_WHITE_STRIPES_SOCCER_JERSEY;
      } else if (variant >= 1644 && variant < 1664) {
        return TraitOptionsClothing.WHITE_AND_RED_STRIPED_BIB;
      } else if (variant >= 1664 && variant < 1674) {
        return TraitOptionsClothing.WHITE_WITH_RED_DRESS;
      } else if (variant >= 1674 && variant < 1694) {
        return TraitOptionsClothing.WHITE_WITH_RED_STRIPES_TANKTOP;
      } else if (variant >= 1694 && variant < 1704) {
        return TraitOptionsClothing.DUSTY_MAROON_MINERS_GARB;
      }
    }
    // END POLAR RED ASSETS
    else {
      // BEGIN PANDA COLORED ASSET CHECK
      // BLUES (remove POW stuff)
      if (variant >= 0 && variant < 40) {
        return TraitOptionsClothing.BLUE_ERC20_SHIRT;
      } else if (variant >= 40 && variant < 80) {
        return TraitOptionsClothing.BLUE_FOX_WALLET_TANKTOP;
      } else if (variant >= 80 && variant < 120) {
        return TraitOptionsClothing.BLUE_GRADIENT_DIAMOND_SHIRT;
      } else if (variant >= 120 && variant < 160) {
        return TraitOptionsClothing.BLUE_LINK_SHIRT;
      } else if (variant >= 160 && variant < 200) {
        return TraitOptionsClothing.BLUE_WEB3_SAFE_SHIRT;
      } else if (variant >= 200 && variant < 210) {
        return TraitOptionsClothing.BLACK_AND_BLUE_STRIPED_BIB;
      } else if (variant >= 210 && variant < 215) {
        return TraitOptionsClothing.BLACK_AND_WHITE_STRIPED_JAIL_UNIFORM;
      } else if (variant >= 215 && variant < 235) {
        return TraitOptionsClothing.BLACK_WITH_BLUE_DRESS;
      } else if (variant >= 235 && variant < 255) {
        return TraitOptionsClothing.BLACK_WITH_BLUE_STRIPES_TANKTOP;
      } else if (variant >= 255 && variant < 275) {
        return TraitOptionsClothing.BLUE_BEAR_LOVE_SHIRT;
      } else if (variant >= 275 && variant < 295) {
        return TraitOptionsClothing.BLUE_BEAR_MARKET_SHIRT;
      } else if (variant >= 295 && variant < 315) {
        return TraitOptionsClothing.BLUE_BULL_MARKET_SHIRT;
      } else if (variant >= 315 && variant < 335) {
        return TraitOptionsClothing.BLUE_DRESS_WITH_WHITE_DOTS;
      } else if (variant >= 335 && variant < 355) {
        return TraitOptionsClothing.BLUE_DRESS_WITH_WHITE_LACE;
      } else if (variant >= 355 && variant < 375) {
        return TraitOptionsClothing.BLUE_DRESS;
      } else if (variant >= 375 && variant < 395) {
        return TraitOptionsClothing.BLUE_ETH_SHIRT;
      } else if (variant >= 395 && variant < 415) {
        return TraitOptionsClothing.BLUE_FANNY_PACK;
      } else if (variant >= 415 && variant < 420) {
        return TraitOptionsClothing.BLUE_HOOLA_HOOP;
      } else if (variant >= 420 && variant < 440) {
        return TraitOptionsClothing.BLUE_HOOT_SHIRT;
      } else if (variant >= 440 && variant < 445) {
        return TraitOptionsClothing.BLUE_JESTERS_COLLAR;
      } else if (variant >= 445 && variant < 455) {
        return TraitOptionsClothing.BLUE_KNIT_SWEATER;
      } else if (variant >= 455 && variant < 457) {
        return TraitOptionsClothing.BLUE_LEG_WARMERS;
      } else if (variant >= 457 && variant < 477) {
        return TraitOptionsClothing.BLUE_OVERALLS;
      } else if (variant >= 477 && variant < 517) {
        return TraitOptionsClothing.BLUE_PINK_UNICORN_DEX_TANKTOP;
      } else if (variant >= 517 && variant < 527) {
        return TraitOptionsClothing.BLUE_PONCHO;
      } else if (variant >= 527 && variant < 547) {
        return TraitOptionsClothing.BLUE_PORTAL_SHIRT;
      }
      // gap between 547 and 567
      else if (variant >= 567 && variant < 587) {
        return TraitOptionsClothing.BLUE_PROOF_OF_WORK_SHIRT;
      } else if (variant >= 587 && variant < 607) {
        return TraitOptionsClothing.BLUE_PUFFY_VEST;
      } else if (variant >= 607 && variant < 627) {
        return TraitOptionsClothing.BLUE_REKT_SHIRT;
      } else if (variant >= 627 && variant < 667) {
        return TraitOptionsClothing.BLUE_RASPBERRY_PI_NODE_TANKTOP;
      } else if (variant >= 667 && variant < 687) {
        return TraitOptionsClothing.BLUE_SKIRT_WITH_BLACK_AND_WHITE_DOTS;
      } else if (variant >= 687 && variant < 707) {
        return TraitOptionsClothing.BLUE_SKIRT;
      } else if (variant >= 707 && variant < 727) {
        return TraitOptionsClothing.BLUE_STRIPED_NECKTIE;
      } else if (variant >= 727 && variant < 732) {
        return TraitOptionsClothing.BLUE_SUIT_JACKET_WITH_GOLD_TIE;
      } else if (variant >= 732 && variant < 752) {
        return TraitOptionsClothing.BLUE_TANKTOP;
      } else if (variant >= 752 && variant < 762) {
        return TraitOptionsClothing.BLUE_TOGA;
      } else if (variant >= 762 && variant < 782) {
        return TraitOptionsClothing.BLUE_TUBE_TOP;
      } else if (variant >= 782 && variant < 802) {
        return TraitOptionsClothing.BLUE_VEST;
      } else if (variant >= 802 && variant < 822) {
        return TraitOptionsClothing.BLUE_WAGMI_SHIRT;
      } else if (variant >= 822 && variant < 832) {
        return TraitOptionsClothing.BLUE_WITH_BLACK_STRIPES_SOCCER_JERSEY;
      } else if (variant >= 832 && variant < 837) {
        return TraitOptionsClothing.BLUE_WITH_PINK_AND_GREEN_DRESS;
      } else if (variant >= 837 && variant < 847) {
        return TraitOptionsClothing.BLUE_WITH_WHITE_APRON;
      } else if (variant >= 847 && variant < 852) {
        return TraitOptionsClothing.MAGICIAN_UNIFORM_WITH_BLUE_CAPE;
      }

      // BEGIN RED PANDA ASSETS
      if (variant >= 852 && variant < 892) {
        return TraitOptionsClothing.RED_ERC20_SHIRT;
      } else if (variant >= 892 && variant < 932) {
        return TraitOptionsClothing.RED_FOX_WALLET_TANKTOP;
      } else if (variant >= 932 && variant < 972) {
        return TraitOptionsClothing.RED_GRADIENT_DIAMOND_SHIRT;
      } else if (variant >= 972 && variant < 1012) {
        return TraitOptionsClothing.RED_LINK_SHIRT;
      } else if (variant >= 1012 && variant < 1052) {
        return TraitOptionsClothing.RED_WEB3_SAFE_SHIRT;
      } else if (variant >= 1052 && variant < 1062) {
        return TraitOptionsClothing.MAGICIAN_UNIFORM_WITH_RED_CAPE;
      } else if (variant >= 1062 && variant < 1067) {
        return TraitOptionsClothing.RED_BEAR_LOVE_SHIRT;
      } else if (variant >= 1067 && variant < 1087) {
        return TraitOptionsClothing.RED_BEAR_MARKET_SHIRT;
      } else if (variant >= 1087 && variant < 1107) {
        return TraitOptionsClothing.RED_BULL_MARKET_SHIRT;
      } else if (variant >= 1107 && variant < 1127) {
        return TraitOptionsClothing.RED_DRESS_WITH_WHITE_DOTS;
      } else if (variant >= 1127 && variant < 1147) {
        return TraitOptionsClothing.RED_DRESS_WITH_WHITE_LACE;
      } else if (variant >= 1147 && variant < 1167) {
        return TraitOptionsClothing.RED_DRESS;
      } else if (variant >= 1167 && variant < 1187) {
        return TraitOptionsClothing.RED_ETH_SHIRT;
      } else if (variant >= 1187 && variant < 1207) {
        return TraitOptionsClothing.RED_FANNY_PACK;
      } else if (variant >= 1207 && variant < 1227) {
        return TraitOptionsClothing.RED_HOOLA_HOOP;
      } else if (variant >= 1227 && variant < 1247) {
        return TraitOptionsClothing.RED_HOOT_SHIRT;
      } else if (variant >= 1247 && variant < 1267) {
        return TraitOptionsClothing.RED_JESTERS_COLLAR;
      } else if (variant >= 1267 && variant < 1272) {
        return TraitOptionsClothing.RED_KNIT_SWEATER;
      } else if (variant >= 1272 && variant < 1292) {
        return TraitOptionsClothing.RED_LEG_WARMERS;
      } else if (variant >= 1292 && variant < 1297) {
        return TraitOptionsClothing.RED_OVERALLS;
      } else if (variant >= 1297 && variant < 1307) {
        return TraitOptionsClothing.RED_PINK_UNICORN_DEX_TANKTOP;
      } else if (variant >= 1307 && variant < 1309) {
        return TraitOptionsClothing.RED_PONCHO;
      } else if (variant >= 1309 && variant < 1329) {
        return TraitOptionsClothing.RED_PORTAL_SHIRT;
      } else if (variant >= 1329 && variant < 1369) {
        // PANDA ONLY
        return TraitOptionsClothing.BLUE_PROOF_OF_STAKE_SHIRT;
      } else if (variant >= 1369 && variant < 1399) {
        return TraitOptionsClothing.RED_PUFFY_VEST;
      } else if (variant >= 1399 && variant < 1409) {
        return TraitOptionsClothing.RED_REKT_SHIRT;
      }
      // Pandas Only
      else if (variant >= 1409 && variant < 1419) {
        return TraitOptionsClothing.NODE_OPERATORS_VEST;
      } else if (variant >= 1419 && variant < 1439) {
        return TraitOptionsClothing.RED_PROOF_OF_STAKE_SHIRT;
      } else if (variant >= 1439 && variant < 1459) {
        return TraitOptionsClothing.RED_RASPBERRY_PI_NODE_TANKTOP;
      } else if (variant >= 1459 && variant < 1479) {
        return TraitOptionsClothing.RED_SKIRT_WITH_BLACK_AND_WHITE_DOTS;
      } else if (variant >= 1479 && variant < 1519) {
        return TraitOptionsClothing.RED_SKIRT;
      } else if (variant >= 1519 && variant < 1539) {
        return TraitOptionsClothing.RED_STRIPED_NECKTIE;
      } else if (variant >= 1539 && variant < 1559) {
        return TraitOptionsClothing.RED_SUIT_JACKET_WITH_GOLD_TIE;
      } else if (variant >= 1559 && variant < 1579) {
        return TraitOptionsClothing.RED_TANKTOP;
      } else if (variant >= 1579 && variant < 1584) {
        return TraitOptionsClothing.RED_TOGA;
      } else if (variant >= 1584 && variant < 1604) {
        return TraitOptionsClothing.RED_TUBE_TOP;
      } else if (variant >= 1604 && variant < 1614) {
        return TraitOptionsClothing.RED_VEST;
      } else if (variant >= 1614 && variant < 1634) {
        return TraitOptionsClothing.RED_WAGMI_SHIRT;
      } else if (variant >= 1634 && variant < 1654) {
        return TraitOptionsClothing.RED_WITH_PINK_AND_GREEN_DRESS;
      } else if (variant >= 1654 && variant < 1674) {
        return TraitOptionsClothing.RED_WITH_WHITE_APRON;
      } else if (variant >= 1674 && variant < 1684) {
        return TraitOptionsClothing.RED_WITH_WHITE_STRIPES_SOCCER_JERSEY;
      } else if (variant >= 1684 && variant < 1689) {
        return TraitOptionsClothing.WHITE_AND_RED_STRIPED_BIB;
      } else if (variant >= 1689 && variant < 1699) {
        return TraitOptionsClothing.WHITE_WITH_RED_DRESS;
      } else if (variant >= 1699 && variant < 1704) {
        return TraitOptionsClothing.WHITE_WITH_RED_STRIPES_TANKTOP;
      }
    } // end panda

    // 1704 - 2078
    if (variant >= 1704 && variant < 1714) {
      return TraitOptionsClothing.ADAMS_LEAF;
    } else if (variant >= 1714 && variant < 1724) {
      return TraitOptionsClothing.BLACK_BELT;
    } else if (variant >= 1724 && variant < 1744) {
      return TraitOptionsClothing.BLACK_LEATHER_JACKET;
    } else if (variant >= 1744 && variant < 1784) {
      return TraitOptionsClothing.BLACK_TUXEDO;
    } else if (variant >= 1784 && variant < 1804) {
      return TraitOptionsClothing.BORAT_SWIMSUIT;
    } else if (variant >= 1804 && variant < 1810) {
      return TraitOptionsClothing.BUTTERFLY_WINGS;
    } else if (variant >= 1810 && variant < 1830) {
      return TraitOptionsClothing.GRASS_SKIRT;
    } else if (variant >= 1830 && variant < 1850) {
      return TraitOptionsClothing.LEDERHOSEN;
    } else if (variant >= 1850 && variant < 1855) {
      return TraitOptionsClothing.ORANGE_INFLATABLE_WATER_WINGS;
    } else if (variant >= 1855 && variant < 1865) {
      return TraitOptionsClothing.ORANGE_PRISON_UNIFORM;
    } else if (variant >= 1865 && variant < 1870) {
      return TraitOptionsClothing.PINK_TUTU;
    } else if (variant >= 1870 && variant < 1890) {
      return TraitOptionsClothing.PINK_AND_TEAL_DEFI_LENDING_TANKTOP;
    } else if (variant >= 1890 && variant < 1900) {
      return TraitOptionsClothing.TAN_CARGO_SHORTS;
    } else if (variant >= 1900 && variant < 1904) {
      return TraitOptionsClothing.VAMPIRE_BAT_WINGS;
    } else if (variant >= 1904 && variant < 1944) {
      return TraitOptionsClothing.WHITE_TUXEDO;
    } else if (variant >= 1944 && variant < 2078) {
      return TraitOptionsClothing.NAKEY;
    }

    return TraitOptionsClothing.NAKEY;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library TraitDefs {
  uint8 constant SPECIES = 0;
  uint8 constant LOCALE = 1;
  uint8 constant BELLY = 2;
  uint8 constant ARMS = 3;
  uint8 constant EYES = 4;
  uint8 constant MOUTH = 5;
  uint8 constant NOSE = 6;
  uint8 constant CLOTHING = 7;
  uint8 constant HAT = 8;
  uint8 constant JEWELRY = 9;
  uint8 constant FOOTWEAR = 10;
  uint8 constant ACCESSORIES = 11;
  uint8 constant FACE_ACCESSORY = 12;
  uint8 constant BACKGROUND = 13;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library TraitOptionsClothing {
  uint8 constant BLUE_ERC20_SHIRT = 0;
  uint8 constant BLUE_FOX_WALLET_TANKTOP = 1;
  uint8 constant BLUE_GRADIENT_DIAMOND_SHIRT = 2;
  uint8 constant BLUE_LINK_SHIRT = 3;
  uint8 constant BLUE_WEB3_SAFE_SHIRT = 4;
  uint8 constant RED_ERC20_SHIRT = 5;
  uint8 constant RED_FOX_WALLET_TANKTOP = 6;
  uint8 constant RED_GRADIENT_DIAMOND_SHIRT = 7;
  uint8 constant RED_LINK_SHIRT = 8;
  uint8 constant RED_WEB3_SAFE_SHIRT = 9;
  uint8 constant ADAMS_LEAF = 10;
  uint8 constant BLACK_BELT = 11;
  uint8 constant BLACK_LEATHER_JACKET = 12;
  uint8 constant BLACK_TUXEDO = 13;
  uint8 constant BLACK_AND_BLUE_STRIPED_BIB = 14;
  uint8 constant BLACK_AND_WHITE_STRIPED_JAIL_UNIFORM = 15;
  uint8 constant BLACK_WITH_BLUE_DRESS = 16;
  uint8 constant BLACK_WITH_BLUE_STRIPES_TANKTOP = 17;
  uint8 constant BLUE_BEAR_LOVE_SHIRT = 18;
  uint8 constant BLUE_BEAR_MARKET_SHIRT = 19;
  uint8 constant BLUE_BULL_MARKET_SHIRT = 20;
  uint8 constant BLUE_DRESS_WITH_WHITE_DOTS = 21;
  uint8 constant BLUE_DRESS_WITH_WHITE_LACE = 22;
  uint8 constant BLUE_DRESS = 23;
  uint8 constant BLUE_ETH_SHIRT = 24;
  uint8 constant BLUE_FANNY_PACK = 25;
  uint8 constant BLUE_HOOLA_HOOP = 26;
  uint8 constant BLUE_HOOT_SHIRT = 27;
  uint8 constant BLUE_JESTERS_COLLAR = 28;
  uint8 constant BLUE_KNIT_SWEATER = 29;
  uint8 constant BLUE_LEG_WARMERS = 30;
  uint8 constant BLUE_OVERALLS = 31;
  uint8 constant BLUE_PINK_UNICORN_DEX_TANKTOP = 32;
  uint8 constant BLUE_PONCHO = 33;
  uint8 constant BLUE_PORTAL_SHIRT = 34;
  uint8 constant BLUE_PROOF_OF_STAKE_SHIRT = 35;
  uint8 constant BLUE_PROOF_OF_WORK_SHIRT = 36;
  uint8 constant BLUE_PUFFY_VEST = 37;
  uint8 constant BLUE_REKT_SHIRT = 38;
  uint8 constant BLUE_RASPBERRY_PI_NODE_TANKTOP = 39;
  uint8 constant BLUE_SKIRT_WITH_BLACK_AND_WHITE_DOTS = 40;
  uint8 constant BLUE_SKIRT = 41;
  uint8 constant BLUE_STRIPED_NECKTIE = 42;
  uint8 constant BLUE_SUIT_JACKET_WITH_GOLD_TIE = 43;
  uint8 constant BLUE_TANKTOP = 44;
  uint8 constant BLUE_TOGA = 45;
  uint8 constant BLUE_TUBE_TOP = 46;
  uint8 constant BLUE_VEST = 47;
  uint8 constant BLUE_WAGMI_SHIRT = 48;
  uint8 constant BLUE_WITH_BLACK_STRIPES_SOCCER_JERSEY = 49;
  uint8 constant BLUE_WITH_PINK_AND_GREEN_DRESS = 50;
  uint8 constant BLUE_WITH_WHITE_APRON = 51;
  uint8 constant BORAT_SWIMSUIT = 52;
  uint8 constant BUTTERFLY_WINGS = 53;
  uint8 constant DUSTY_MAROON_MINERS_GARB = 54;
  uint8 constant DUSTY_NAVY_MINERS_GARB = 55;
  uint8 constant GRASS_SKIRT = 56;
  uint8 constant LEDERHOSEN = 57;
  uint8 constant MAGICIAN_UNIFORM_WITH_BLUE_CAPE = 58;
  uint8 constant MAGICIAN_UNIFORM_WITH_RED_CAPE = 59;
  uint8 constant NAKEY = 60;
  uint8 constant NODE_OPERATORS_VEST = 61;
  uint8 constant ORANGE_INFLATABLE_WATER_WINGS = 62;
  uint8 constant ORANGE_PRISON_UNIFORM = 63;
  uint8 constant PINK_TUTU = 64;
  uint8 constant PINK_AND_TEAL_DEFI_LENDING_TANKTOP = 65;
  uint8 constant RED_BEAR_LOVE_SHIRT = 66;
  uint8 constant RED_BEAR_MARKET_SHIRT = 67;
  uint8 constant RED_BULL_MARKET_SHIRT = 68;
  uint8 constant RED_DRESS_WITH_WHITE_DOTS = 69;
  uint8 constant RED_DRESS_WITH_WHITE_LACE = 70;
  uint8 constant RED_DRESS = 71;
  uint8 constant RED_ETH_SHIRT = 72;
  uint8 constant RED_FANNY_PACK = 73;
  uint8 constant RED_HOOLA_HOOP = 74;
  uint8 constant RED_HOOT_SHIRT = 75;
  uint8 constant RED_JESTERS_COLLAR = 76;
  uint8 constant RED_KNIT_SWEATER = 77;
  uint8 constant RED_LEG_WARMERS = 78;
  uint8 constant RED_OVERALLS = 79;
  uint8 constant RED_PINK_UNICORN_DEX_TANKTOP = 80;
  uint8 constant RED_PONCHO = 81;
  uint8 constant RED_PORTAL_SHIRT = 82;
  uint8 constant RED_PROOF_OF_STAKE_SHIRT = 83;
  uint8 constant RED_PROOF_OF_WORK_SHIRT = 84;
  uint8 constant RED_PUFFY_VEST = 85;
  uint8 constant RED_REKT_SHIRT = 86;
  uint8 constant RED_RASPBERRY_PI_NODE_TANKTOP = 87;
  uint8 constant RED_SKIRT_WITH_BLACK_AND_WHITE_DOTS = 88;
  uint8 constant RED_SKIRT = 89;
  uint8 constant RED_STRIPED_NECKTIE = 90;
  uint8 constant RED_SUIT_JACKET_WITH_GOLD_TIE = 91;
  uint8 constant RED_TANKTOP = 92;
  uint8 constant RED_TOGA = 93;
  uint8 constant RED_TUBE_TOP = 94;
  uint8 constant RED_VEST = 95;
  uint8 constant RED_WAGMI_SHIRT = 96;
  uint8 constant RED_WITH_PINK_AND_GREEN_DRESS = 97;
  uint8 constant RED_WITH_WHITE_APRON = 98;
  uint8 constant RED_WITH_WHITE_STRIPES_SOCCER_JERSEY = 99;
  uint8 constant TAN_CARGO_SHORTS = 100;
  uint8 constant VAMPIRE_BAT_WINGS = 101;
  uint8 constant WHITE_TUXEDO = 102;
  uint8 constant WHITE_AND_RED_STRIPED_BIB = 103;
  uint8 constant WHITE_WITH_RED_DRESS = 104;
  uint8 constant WHITE_WITH_RED_STRIPES_TANKTOP = 105;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library TraitOptionsSpecies {
  uint8 constant BLACK = 1;
  uint8 constant POLAR = 2;
  uint8 constant PANDA = 3;
  uint8 constant REVERSE_PANDA = 4;
  uint8 constant GOLD_PANDA = 5;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

library Gene {
  function getGene(uint8 traitDef, uint256 dna) internal pure returns (uint16) {
    // type(uint16).max
    // right shift traitDef * 16, then bitwise & with the max 16 bit number
    return uint16((dna >> (traitDef * 16)) & uint256(type(uint16).max));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "../../lib_constants/TraitDefs.sol";
import "../../lib_constants/trait_options/TraitOptionsSpecies.sol";
import "../Gene.sol";

library OptionSpecies {
  function getOption(uint256 dna) public pure returns (uint8) {
    uint16 species = Gene.getGene(TraitDefs.SPECIES, dna);
    // this gene is hard-coded at "mint" or at "merge"
    // 1 is black
    // 2 is polar
    // 3 is panda
    // 4 is reverse panda
    // 5 is gold panda

    if (species == 1) {
      return TraitOptionsSpecies.BLACK;
    } else if (species == 2) {
      return TraitOptionsSpecies.POLAR;
    } else if (species == 3) {
      return TraitOptionsSpecies.PANDA;
    } else if (species == 4) {
      return TraitOptionsSpecies.REVERSE_PANDA;
    } else if (species == 5) {
      return TraitOptionsSpecies.GOLD_PANDA;
    }
    return TraitOptionsSpecies.BLACK;
  }
}