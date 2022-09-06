// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

// import {ERC721} from "solmate/tokens/ERC721.sol";
// import {Owned} from "solmate/auth/Owned.sol";
// import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";
// import {Base64} from "Base64.sol";

contract NFT {
// contract NFT is ERC721, Owned {
    // using Strings for uint256;
    
    // uint256 public constant MAX_SUPPLY = 100;
    // uint256 public constant MAX_POWER = 100;
    // uint256 public constant COOLDOWN = 1 hours;

    // bool public mintingClosed = false;
    // bool public hogwild = false;
    // uint256 public totalSupply = 0;
    // uint256 public shift = 0;

    // /// @notice tokenId -> power, power in the [1, MAX_POWER] range inclusive
    // mapping(uint256 => uint256) internal unshiftedPower;

    // mapping(uint256 => int256) internal powerDelta;

    // /// @notice tokenId -> shield expiration timestamp
    // mapping(uint256 => uint256) internal shieldCooldown;

    // mapping(uint256 => uint256) internal health;

    // mapping(uint256 => uint256) internal attackerCooldown;


    // constructor() ERC721("FooFightersBeta", "FOO") Owned(tx.origin) {}

    // function attack(uint256 attackerId, uint256 defenderId) external {
    //     require(mintingClosed, "minting ongoing");
    //     require(hogwild || msg.sender == _ownerOf[attackerId], "not your token");
    //     require(block.timestamp > attackerCooldown[attackerId], "attacker in cooldown mode");
    //     require(block.timestamp > shieldCooldown[defenderId], "defender in shielded mode");

    //     uint256 attackerPower = uint256(power(attackerId));
    //     uint256 defenderHealth = health[defenderId];
    //     if (attackerPower >= defenderHealth) {
    //         _burn(defenderId);
    //         totalSupply--;
    //         powerDelta[attackerId] += powerDelta[defenderId]; // Protect the weak, make the strong eat their own
    //     } else {
    //         defenderHealth -= attackerPower;
    //     }
    //     powerDelta[attackerId]++; // Reward the courageous
    //     attackerCooldown[attackerId] = block.timestamp + COOLDOWN;
    //     if (power(attackerId) < 0) {
    //         _burn(attackerId);
    //         totalSupply--;
    //     }
    // }

    // function shield(uint256 tokenId) external {
    //     require(mintingClosed, "minting ongoing");
    //     require(hogwild || msg.sender == _ownerOf[tokenId], "not your token");
    //     require(block.timestamp > attackerCooldown[tokenId], "can't shield until attacker cooldown over");

    //     attackerCooldown[tokenId] = block.timestamp + COOLDOWN;
    //     shieldCooldown[tokenId] = block.timestamp + COOLDOWN;
    //     powerDelta[tokenId]--; // Punish the cowards
    //     if (power(tokenId) < 0) {
    //         _burn(tokenId);
    //         totalSupply--;
    //     }
    // }

    // function mint() external {
    //     require(!mintingClosed, "minting closed");
    //     unshiftedPower[totalSupply] = unsafeRandom(MAX_POWER, totalSupply);
    //     health[totalSupply] = 255;
    //     _mint(msg.sender, totalSupply++);
    // }

    // /// @dev Returns a random value in [0, max-1]
    // function unsafeRandom(uint256 max, uint256 seed) internal view returns (uint256) {
    //     return uint256(keccak256(abi.encode(blockhash(block.number - 1), block.timestamp, msg.sender, seed))) % max;
    // }

    // function finalizeMinting() external onlyOwner {
    //     mintingClosed = true;
    //     if (shift == 0) {
    //         shift = unsafeRandom(MAX_POWER, MAX_SUPPLY) + 1;
    //     }
    // }

    // function setHogwild(bool value) external onlyOwner {
    //     hogwild = value;
    // }

    // function power(uint256 tokenId) public view returns (int256) {
    //     require(_ownerOf[tokenId] != address(0), "token does not exist");
    //     return int256((unshiftedPower[tokenId] + shift) % MAX_POWER) + powerDelta[tokenId];
    // }

    // function getColor(uint256 r, uint256 g, uint256 b) internal view returns (string memory) {
    //     if (r > 255) r = 255;
    //     if (g > 255) g = 255;
    //     if (b > 255) b = 255;
    //     return string.concat("rgb(", r.toString(), ",", g.toString(), ",", b.toString(), ")");
    // }

    // function tokenURI(uint256 tokenId) override public view returns (string memory) {
    //     uint256 tokenPower = uint256(power(tokenId));
    //     uint256 tokenHealth = health[tokenId];
        
    //     string[7] memory parts;
    //     parts[0] = string.concat('<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>path {fill: "', getColor(0, tokenPower, 0), '"}</style><rect width="100%" height="100%" fill="', getColor(255, 255-tokenHealth, 255-tokenHealth), '" />');
    //     parts[1] = '<g transform="translate(0.000000,350.000000) scale(0.112903,-0.112903)" fill="#000000" stroke="none"> <path d="M498 3093 c0 -5 -2 -48 -3 -98 -1 -49 -6 -99 -10 -109 -5 -11 -5 -17 1 -14 5 4 9 -49 9 -128 0 -74 -3 -134 -8 -134 -4 0 -3 -9 3 -19 11 -21 6 -314 -6 -345 -4 -11 -4 -17 2 -13 6 3 10 -48 10 -129 0 -74 -4 -134 -8 -134 -5 0 -4 -9 2 -19 11 -21 6 -314 -6 -345 -4 -11 -4 -17 2 -13 6 3 9 -47 9 -129 1 -74 -3 -134 -8 -134 -4 0 -3 -8 2 -19 12 -21 7 -315 -5 -345 -4 -11 -4 -17 2 -13 6 3 10 -48 10 -129 0 -74 -4 -134 -8 -134 -5 0 -4 -9 2 -19 11 -22 7 -314 -6 -345 -4 -11 -4 -17 2 -14 7 5 9 -101 5 -264 -2 -48 3 -55 28 -39 8 5 10 14 5 22 -10 16 -12 271 -3 316 4 18 5 34 2 36 -10 10 -12 267 -2 267 5 0 7 5 3 11 -9 15 -12 285 -3 326 4 18 5 34 2 36 -10 10 -12 267 -2 267 5 0 7 5 3 11 -9 15 -12 285 -3 326 4 18 5 34 2 36 -10 10 -12 267 -2 267 5 0 7 5 3 11 -9 15 -12 285 -3 326 4 18 5 34 2 36 -10 10 -12 267 -2 267 5 0 7 5 3 11 -9 15 -12 285 -3 326 4 18 4 35 1 38 -4 3 -5 40 -3 81 2 48 -1 74 -8 74 -6 0 -12 -3 -13 -7z"/> <path d="M1137 3093 c-3 -5 -5 -48 -4 -98 0 -49 -4 -99 -8 -109 -5 -11 -5 -17 1 -14 5 4 9 -49 9 -128 0 -74 -3 -134 -8 -134 -4 0 -3 -9 3 -21 12 -22 10 -209 -2 -209 -5 0 -8 -31 -8 -70 l0 -70 -70 0 -70 0 0 -71 0 -71 -72 4 -73 3 2 -212 2 -213 -69 0 -70 0 0 -210 0 -210 70 0 70 0 0 -280 0 -280 70 0 70 0 0 280 0 280 560 0 560 0 0 -280 0 -280 -70 0 -70 0 0 -70 0 -70 -70 0 -70 0 0 -70 0 -70 -210 0 -210 0 0 70 0 70 -70 0 -70 0 0 -70 0 -70 70 0 70 0 0 -70 0 -70 70 0 70 0 0 -140 0 -140 70 0 70 0 1 98 c0 53 0 116 -1 140 l-2 42 50 0 49 0 -4 -112 c-5 -182 -6 -179 26 -159 8 5 10 14 6 22 -14 22 -12 231 2 245 8 8 13 39 13 78 l0 66 70 0 70 0 0 70 0 70 70 0 70 0 0 70 0 70 70 0 70 0 0 303 c1 641 -1 1091 -3 1093 -1 1 -31 4 -67 5 l-65 3 -3 -142 -3 -142 -209 0 -210 0 0 70 0 70 -70 0 -70 0 0 -70 0 -70 -280 0 -280 0 0 140 0 140 70 0 70 0 0 70 0 70 420 0 420 0 0 -70 0 -70 70 0 70 0 0 70 0 70 -70 0 -70 0 0 70 0 70 -79 0 -78 0 -7 61 c-9 89 -8 129 5 129 5 0 7 5 3 11 -9 15 -12 285 -3 326 4 18 4 35 1 38 -4 3 -5 40 -3 82 2 60 0 74 -11 71 -9 -3 -13 -30 -14 -99 0 -52 -5 -103 -9 -113 -5 -11 -5 -17 1 -14 5 4 9 -49 9 -128 0 -74 -3 -134 -8 -134 -4 0 -3 -9 3 -21 7 -12 10 -59 8 -114 l-3 -95 -306 0 -306 0 -7 62 c-9 88 -8 128 5 128 5 0 7 5 3 11 -9 15 -12 285 -3 326 4 18 4 35 1 38 -4 3 -5 40 -3 81 2 46 -1 74 -8 74 -5 0 -12 -3 -14 -7z m263 -1623 l0 -70 -140 0 -140 0 0 70 0 70 140 0 140 0 0 -70z m700 0 l0 -70 -140 0 -140 0 0 70 0 70 140 0 140 0 0 -70z"/> <path d="M2418 3093 c-1 -5 -2 -48 -3 -98 -1 -49 -6 -99 -10 -109 -5 -11 -5 -17 1 -14 5 4 9 -49 9 -128 0 -74 -3 -134 -8 -134 -4 0 -3 -9 3 -19 11 -21 6 -314 -6 -345 -4 -11 -4 -17 2 -13 6 3 10 -48 10 -129 0 -74 -4 -134 -8 -134 -5 0 -4 -9 2 -19 11 -21 6 -314 -6 -345 -4 -11 -4 -17 2 -13 6 3 10 -48 10 -129 0 -74 -4 -134 -8 -134 -5 0 -4 -8 1 -19 12 -21 7 -315 -5 -345 -4 -11 -4 -17 2 -13 6 3 10 -48 10 -129 0 -74 -4 -134 -8 -134 -5 0 -4 -8 1 -19 12 -21 7 -315 -5 -345 -4 -11 -4 -17 2 -14 7 5 9 -100 4 -269 -1 -43 5 -49 29 -34 8 5 10 14 5 22 -10 16 -12 271 -3 316 4 18 5 34 2 36 -10 10 -12 267 -2 267 5 0 7 5 3 11 -9 15 -12 286 -3 326 4 18 5 34 2 36 -10 10 -12 267 -2 267 5 0 7 5 3 11 -9 15 -12 285 -3 326 4 18 5 34 2 36 -10 10 -12 267 -2 267 5 0 7 5 3 11 -9 15 -12 285 -3 326 4 18 5 34 2 36 -10 10 -12 267 -2 267 5 0 7 5 3 11 -9 15 -12 286 -3 326 4 18 4 35 1 38 -4 3 -5 40 -3 81 2 48 -1 74 -8 74 -6 0 -12 -3 -13 -7z"/> <path d="M3059 3093 c-1 -5 -2 -48 -3 -98 -1 -49 -5 -99 -10 -109 -6 -12 -6 -17 0 -14 5 4 9 -49 10 -128 0 -74 -4 -134 -8 -134 -5 0 -4 -8 1 -19 12 -22 8 -316 -4 -345 -5 -11 -5 -17 1 -14 5 4 9 -49 10 -128 0 -74 -4 -134 -8 -134 -5 0 -4 -8 1 -18 12 -22 8 -318 -4 -346 -5 -12 -5 -17 1 -14 5 4 10 -49 10 -128 1 -76 -2 -134 -7 -134 -6 0 -6 -8 0 -18 12 -22 8 -318 -4 -346 -5 -12 -5 -17 1 -14 5 4 10 -49 10 -128 1 -76 -2 -134 -7 -134 -6 0 -5 -8 0 -19 12 -22 8 -316 -4 -345 -5 -11 -5 -17 1 -14 5 4 10 -49 10 -128 1 -74 -2 -134 -7 -134 -5 0 -4 -11 2 -24 14 -31 43 -24 33 8 -10 28 -12 272 -3 313 4 18 4 34 1 37 -9 10 -11 266 -1 266 5 0 5 10 1 23 -7 19 -9 303 -2 332 1 6 1 12 0 15 -7 18 -6 270 1 270 5 0 5 10 1 23 -7 19 -9 303 -2 332 1 6 1 12 0 15 -7 18 -6 270 1 270 5 0 5 10 0 23 -7 19 -8 303 -1 332 1 6 2 12 1 15 -9 22 -9 270 -1 270 6 0 6 9 1 23 -9 26 -7 319 3 335 3 6 3 13 -2 16 -4 2 -7 39 -6 80 0 42 -3 76 -8 76 -4 0 -9 -3 -9 -7z"/> <path d="M1540 1050 l0 -70 70 0 70 0 0 70 0 70 -70 0 -70 0 0 -70z"/> <path d="M1400 770 l0 -70 210 0 210 0 0 70 0 70 -210 0 -210 0 0 -70z"/> <path d="M980 350 l0 -350 70 0 70 0 0 350 0 350 -70 0 -70 0 0 -350z"/> </g>';
    //     parts[2] = '<text x="10" y="20" class="base">';
    //     parts[3] = string.concat('power: ', tokenPower.toString());
    //     parts[4] = '</text><text x="10" y="40" class="base">';
    //     parts[5] = string.concat('health: ', tokenHealth.toString());
    //     parts[6] = '</text></svg>';

    //     bytes memory svg = abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6]);
    //     string memory svgEncoded = string(abi.encodePacked('data:image/svg+xml;base64,', Base64.encode(bytes(svg))));
    //     string memory attributes = string.concat('"attributes":[{"trait_type": "Power","value": ', tokenPower.toString(), '}, {"trait_type": "Health","value": ', tokenHealth.toString(), '}]');
    //     string memory metadataString = string.concat('{"name": "FooFighter #', tokenId.toString(), '", "description": "FooFighters are a fun onchain experiment", ', attributes, ', "image": "', svgEncoded, '"}');
    //     string memory output = string.concat('data:application/json;base64,', Base64.encode(bytes(metadataString)));

    //     return output;
    // }
}