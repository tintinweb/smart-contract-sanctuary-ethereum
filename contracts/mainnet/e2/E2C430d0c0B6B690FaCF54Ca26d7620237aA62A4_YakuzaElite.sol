// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

/**
 * Yakuza Inc - ELITE
 * ERC-721A Migration  with Token Locking.
 * S/O to owl of moistness for locking inspiration, @ChiruLabs for ERC721A.
 */

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721A.sol";

interface ITempura {
    function startDripping(address addr, uint128 multiplier) external;

    function stopDripping(address addr, uint128 multiplier) external;
}

contract YakuzaElite is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    string public baseURI;

    uint256 public constant MAX_SUPPLY = 333;

    ITempura public Tempura;

    mapping(uint256 => uint256) public tierByToken;
    mapping(uint256 => bool) public lockStatus;
    mapping(uint256 => uint256) public lockData;

    bool public lockingAllowed;

    event Lock(uint256 token, uint256 timeStamp, address user);
    event Unlock(uint256 token, uint256 timeStamp, address user);

    /*
    ================================================
                    CONSTRUCTION        
    ================================================
*/

    constructor() ERC721A("Yakuza Elite", "YKELITE") {
        migrateTokens();
        initializeLock();
        initializeTiers();
        Tempura = ITempura(0xf52ae754AE9aaAC2f3A6C8730871d980389a424d);
        baseURI = "https://yakuza-api.vercel.app/api/";
    }

    /*
    ================================================
            Public/External Write Functions         
    ================================================
*/

    function lockTokens(uint256[] calldata tokenIds) external nonReentrant {
        require(lockingAllowed, "Locking is not currently allowed.");
        uint128 value;
        for (uint256 i; i < tokenIds.length; i++) {
            _lockToken(tokenIds[i]);
            if (tierByToken[tokenIds[i]] != 0) {
                unchecked {
                    value += 20;
                }
            } else {
                unchecked {
                    value += 10;
                }
            }
        }
        Tempura.startDripping(msg.sender, value);
    }

    function unlockTokens(uint256[] calldata tokenIds) external {
        uint128 value;
        for (uint256 i; i < tokenIds.length; i++) {
            if (tierByToken[tokenIds[i]] != 0) {
                unchecked {
                    value += 20;
                }
            } else {
                unchecked {
                    value += 10;
                }
            }
            _unlockToken(tokenIds[i]);
        }
        Tempura.stopDripping(msg.sender, value);
    }

    /*
    ================================================
               ACCESS RESTRICTED FUNCTIONS        
    ================================================
*/

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setTier(uint256[] calldata tokenIds, uint128 tier) external onlyOwner {
        for (uint256 i; i < tokenIds.length; i++) {
            tierByToken[tokenIds[i]] = tier;
        }
    }

    function unlockTokensOwner(uint256[] calldata tokens) external onlyOwner {
        for (uint256 i; i < tokens.length; i++) {
            uint128 value;
            if (tierByToken[tokens[i]] != 0) value += 20;
            else value += 10;
            Tempura.stopDripping(ownerOf(tokens[i]), value);
            _unlockToken(tokens[i]);
        }
    }

    function lockTokensOwner(uint256[] calldata tokens) external onlyOwner {
        for (uint256 i; i < tokens.length; i++) {
            _lockToken(tokens[i]);
            uint128 value;
            if (tierByToken[tokens[i]] != 0) value += 20;
            else value += 10;
            Tempura.startDripping(ownerOf(tokens[i]), value);
        }
    }

    function setTempura(address tempura) external onlyOwner {
        Tempura = ITempura(tempura);
    }

    function toggleLocking() external onlyOwner {
        lockingAllowed = !lockingAllowed;
    }


    /*
    ================================================
                Migration/Initialization       
    ================================================
*/

    function initializeLock() internal {
        lockStatus[1] = true;
        lockStatus[5] = true;
        lockStatus[6] = true;
        lockStatus[7] = true;
        lockStatus[9] = true;
        lockStatus[10] = true;
        lockStatus[11] = true;
        lockStatus[12] = true;
        lockStatus[13] = true;
        lockStatus[15] = true;
        lockStatus[16] = true;
        lockStatus[17] = true;
        lockStatus[18] = true;
        lockStatus[19] = true;
        lockStatus[20] = true;
        lockStatus[21] = true;
        lockStatus[22] = true;
        lockStatus[23] = true;
        lockStatus[24] = true;
        lockStatus[25] = true;
        lockStatus[26] = true;
        lockStatus[27] = true;
        lockStatus[28] = true;
        lockStatus[29] = true;
        lockStatus[30] = true;
        lockStatus[31] = true;
        lockStatus[32] = true;
        lockStatus[33] = true;
        lockStatus[35] = true;
        lockStatus[36] = true;
        lockStatus[37] = true;
        lockStatus[38] = true;
        lockStatus[40] = true;
        lockStatus[41] = true;
        lockStatus[42] = true;
        lockStatus[43] = true;
        lockStatus[44] = true;
        lockStatus[46] = true;
        lockStatus[47] = true;
        lockStatus[48] = true;
        lockStatus[49] = true;
        lockStatus[50] = true;
        lockStatus[51] = true;
        lockStatus[52] = true;
        lockStatus[53] = true;
        lockStatus[54] = true;
        lockStatus[55] = true;
        lockStatus[56] = true;
        lockStatus[57] = true;
        lockStatus[58] = true;
        lockStatus[59] = true;
        lockStatus[60] = true;
        lockStatus[61] = true;
        lockStatus[62] = true;
        lockStatus[63] = true;
        lockStatus[64] = true;
        lockStatus[65] = true;
        lockStatus[66] = true;
        lockStatus[67] = true;
        lockStatus[68] = true;
        lockStatus[69] = true;
        lockStatus[70] = true;
        lockStatus[71] = true;
        lockStatus[72] = true;
        lockStatus[73] = true;
        lockStatus[74] = true;
        lockStatus[75] = true;
        lockStatus[77] = true;
        lockStatus[78] = true;
        lockStatus[79] = true;
        lockStatus[80] = true;
        lockStatus[81] = true;
        lockStatus[82] = true;
        lockStatus[83] = true;
        lockStatus[84] = true;
        lockStatus[86] = true;
        lockStatus[87] = true;
        lockStatus[88] = true;
        lockStatus[89] = true;
        lockStatus[90] = true;
        lockStatus[91] = true;
        lockStatus[92] = true;
        lockStatus[93] = true;
        lockStatus[94] = true;
        lockStatus[95] = true;
        lockStatus[96] = true;
        lockStatus[98] = true;
        lockStatus[100] = true;
        lockStatus[101] = true;
        lockStatus[103] = true;
        lockStatus[104] = true;
        lockStatus[105] = true;
        lockStatus[107] = true;
        lockStatus[109] = true;
        lockStatus[110] = true;
        lockStatus[111] = true;
        lockStatus[115] = true;
        lockStatus[117] = true;
        lockStatus[118] = true;
        lockStatus[119] = true;
        lockStatus[122] = true;
        lockStatus[123] = true;
        lockStatus[125] = true;
        lockStatus[126] = true;
        lockStatus[127] = true;
        lockStatus[128] = true;
        lockStatus[129] = true;
        lockStatus[130] = true;
        lockStatus[132] = true;
        lockStatus[133] = true;
        lockStatus[134] = true;
        lockStatus[135] = true;
        lockStatus[136] = true;
        lockStatus[137] = true;
        lockStatus[139] = true;
        lockStatus[140] = true;
        lockStatus[141] = true;
        lockStatus[142] = true;
        lockStatus[143] = true;
        lockStatus[144] = true;
        lockStatus[145] = true;
        lockStatus[147] = true;
        lockStatus[149] = true;
        lockStatus[150] = true;
        lockStatus[152] = true;
        lockStatus[153] = true;
        lockStatus[155] = true;
        lockStatus[157] = true;
        lockStatus[158] = true;
        lockStatus[159] = true;
        lockStatus[161] = true;
        lockStatus[165] = true;
        lockStatus[166] = true;
        lockStatus[168] = true;
        lockStatus[169] = true;
        lockStatus[170] = true;
        lockStatus[171] = true;
        lockStatus[173] = true;
        lockStatus[175] = true;
        lockStatus[177] = true;
        lockStatus[178] = true;
        lockStatus[181] = true;
        lockStatus[182] = true;
        lockStatus[183] = true;
        lockStatus[184] = true;
        lockStatus[185] = true;
        lockStatus[187] = true;
        lockStatus[190] = true;
        lockStatus[192] = true;
        lockStatus[193] = true;
        lockStatus[194] = true;
        lockStatus[195] = true;
        lockStatus[196] = true;
        lockStatus[197] = true;
        lockStatus[198] = true;
        lockStatus[200] = true;
        lockStatus[201] = true;
        lockStatus[203] = true;
        lockStatus[204] = true;
        lockStatus[205] = true;
        lockStatus[207] = true;
        lockStatus[208] = true;
        lockStatus[209] = true;
        lockStatus[211] = true;
        lockStatus[213] = true;
        lockStatus[215] = true;
        lockStatus[217] = true;
        lockStatus[218] = true;
        lockStatus[219] = true;
        lockStatus[220] = true;
        lockStatus[222] = true;
        lockStatus[226] = true;
        lockStatus[227] = true;
        lockStatus[228] = true;
        lockStatus[232] = true;
        lockStatus[233] = true;
        lockStatus[234] = true;
        lockStatus[236] = true;
        lockStatus[237] = true;
        lockStatus[238] = true;
        lockStatus[239] = true;
        lockStatus[240] = true;
        lockStatus[241] = true;
        lockStatus[242] = true;
        lockStatus[244] = true;
        lockStatus[246] = true;
        lockStatus[251] = true;
        lockStatus[252] = true;
        lockStatus[258] = true;
        lockStatus[259] = true;
        lockStatus[261] = true;
        lockStatus[262] = true;
        lockStatus[264] = true;
        lockStatus[266] = true;
        lockStatus[267] = true;
        lockStatus[268] = true;
        lockStatus[269] = true;
        lockStatus[273] = true;
        lockStatus[274] = true;
        lockStatus[276] = true;
        lockStatus[277] = true;
        lockStatus[278] = true;
        lockStatus[280] = true;
        lockStatus[281] = true;
        lockStatus[287] = true;
        lockStatus[289] = true;
        lockStatus[292] = true;
        lockStatus[294] = true;
        lockStatus[295] = true;
        lockStatus[297] = true;
        lockStatus[298] = true;
        lockStatus[299] = true;
        lockStatus[300] = true;
        lockStatus[301] = true;
        lockStatus[302] = true;
        lockStatus[303] = true;
        lockStatus[306] = true;
        lockStatus[307] = true;
    }

    function migrateTokens() internal {
        _mintERC2309(0x3B36Cb2c6826349eEC1F717417f47C06cB70b7Ea, 1);
        _mintERC2309(0xdF66301bb229dAFB491e68faF9b895b9CdFe5EBc, 1);
        _mintERC2309(0x76D75605C770d6B17eFE12C17C001626D371710a, 1);
        _mintERC2309(0x984b6d329d3aa1D6d5A14B134FB1Fb8BcC66D60C, 1);
        _mintERC2309(0xa724F5c322c6c281ABa5d49DcFD69dF1CE11511F, 1);
        _mintERC2309(0xc2445F027e5e3E0d9ED0EB9fFE20fbB5C580C847, 1);
        _mintERC2309(0xb8410f47e152E6ec0E7578f8e0D79d10FB90e09b, 1);
        _mintERC2309(0xc4a6d14d083ca6e6893EA0059195616FDd61F655, 1);
        _mintERC2309(0x2FF6B407D0baC20a27E80D6BAbe8a5149852f4BF, 1);
        _mintERC2309(0x4AB59d6caC15920b2f2909C0529995e12C509b80, 1);
        _mintERC2309(0x2520D890B24AA71E9200183a8B53Af87bB6eBeeE, 1);
        _mintERC2309(0x590f4faFe1966803c79a038c462C8F28B06668d8, 1);
        _mintERC2309(0x552e366f9D3c4f4C1f9F2bebC493715F866Fe9D9, 1);
        _mintERC2309(0x3c9A29649EBf0270a3214916A8A76e0844Cf8DB9, 1);
        _mintERC2309(0x02B004114503F5E75121EF528eac3C08f0D19305, 1);
        _mintERC2309(0x346affc5c5E7bF14Ebbc33530B6e0488Fb8b265e, 1);
        _mintERC2309(0xEeBa29bc63c008B39a432B17382d5441CBA5Fc31, 1);
        _mintERC2309(0x0A90B83884870046B73441AF03b76c35C1d21763, 1);
        _mintERC2309(0x87E974Eea31c0B5bed051bd7569dE8176b447e53, 1);
        _mintERC2309(0xE1EF400f64240bBB30033818980A6b9c6f57D871, 1);
        _mintERC2309(0x6635675C439f545BC9FAD80d40c3C6b054EBc402, 1);
        _mintERC2309(0x6249cd17AaEEF4CdD467785780c669b03b2ACf86, 1);
        _mintERC2309(0xc1692cD69493436b01cddcbE5FeDbC911746A7C1, 1);
        _mintERC2309(0xAcE7858A2514075f5Ab8dD7B947143C0A82a5813, 1);
        _mintERC2309(0x17ff38F48f36bd691B5322DDb68792000440fdd6, 1);
        _mintERC2309(0xe905d18Bd971ce7A1976e0241DB396fAab8A5A32, 1);
        _mintERC2309(0x2e24A856D65Be4319a883E0489f1CAFBB0F3c468, 1);
        _mintERC2309(0xAeA4C6c95D927172bD42aAcA170Aa3E92A29921C, 1);
        _mintERC2309(0x8423753fe03a4f0ACf792E00426BF6f758aE645D, 1);
        _mintERC2309(0x02F60fEF631AC1691fe3d38191b8E3430930d2f4, 1);
        _mintERC2309(0x5B85b432317bc8E16b4895555c2F822271400d6b, 1);
        _mintERC2309(0xdEF769bcf57dF5a2400ab5f9DD3AaD5981079689, 1);
        _mintERC2309(0x4AB59d6caC15920b2f2909C0529995e12C509b80, 1);
        _mintERC2309(0x0064f54f2084758afA4E013B606A9fdD718Ec53c, 1);
        _mintERC2309(0xdac5B25AD77C0a726B95D6A448483cEdc5284fAB, 1);
        _mintERC2309(0x18A01e6c1159d606fcc3148A2b9836669611c0A0, 1);
        _mintERC2309(0xcED0ed8Cb5E884aE4e2A5E8aa9eCe1fD3404330e, 1);
        _mintERC2309(0xC502b4E8346524cD679FBbAdA962317c8f0e1291, 1);
        _mintERC2309(0x6d9ed472Da62B604eD479026185995889ae8f80e, 1);
        _mintERC2309(0x5587C8C50F189b79E93cCeFC62a00669A0D181dc, 1);
        _mintERC2309(0x2C72bc035Ba6242B7f7B7C1bdf0ed171A7c2b945, 1);
        _mintERC2309(0xE1EF400f64240bBB30033818980A6b9c6f57D871, 1);
        _mintERC2309(0x2cB2e57a922893c5a843399C42793BdCC6FC844C, 1);
        _mintERC2309(0x011e2747F5E393E67CE0372cB9cfBd0B9a4C8F12, 1);
        _mintERC2309(0x2741C7A3159F2a01a19F53Cff8972a7812CF6418, 1);
        _mintERC2309(0xd6081A2823F9Ce4e78fB441a693F91f0bcbEd328, 1);
        _mintERC2309(0x87E974Eea31c0B5bed051bd7569dE8176b447e53, 1);
        _mintERC2309(0xe905d18Bd971ce7A1976e0241DB396fAab8A5A32, 1);
        _mintERC2309(0xEeBa29bc63c008B39a432B17382d5441CBA5Fc31, 1);
        _mintERC2309(0x6eB6a8f7F6d071af1311B194893c12796515CC54, 1);
        _mintERC2309(0x6249cd17AaEEF4CdD467785780c669b03b2ACf86, 1);
        _mintERC2309(0x8423753fe03a4f0ACf792E00426BF6f758aE645D, 1);
        _mintERC2309(0x5587C8C50F189b79E93cCeFC62a00669A0D181dc, 1);
        _mintERC2309(0x0A90B83884870046B73441AF03b76c35C1d21763, 1);
        _mintERC2309(0xE1EF400f64240bBB30033818980A6b9c6f57D871, 1);
        _mintERC2309(0x6635675C439f545BC9FAD80d40c3C6b054EBc402, 1);
        _mintERC2309(0x4AB59d6caC15920b2f2909C0529995e12C509b80, 1);
        _mintERC2309(0xAeA4C6c95D927172bD42aAcA170Aa3E92A29921C, 1);
        _mintERC2309(0x2C72bc035Ba6242B7f7B7C1bdf0ed171A7c2b945, 1);
        _mintERC2309(0xb73c6dD54f3d1723d7d76Cf230175B9100c36915, 1);
        _mintERC2309(0x462eA027f18B85e550225E3A767cbc8c0833d973, 1);
        _mintERC2309(0xf52e3f7625B56A59F6CaA0aeAd91A1646C983bE8, 1);
        _mintERC2309(0xE1EF400f64240bBB30033818980A6b9c6f57D871, 1);
        _mintERC2309(0x298c30F70bdc0d035bCE76D261E758240cFaD93A, 1);
        _mintERC2309(0xd71514E903F1E3cABa8b92f8B980a16F0A3a413d, 1);
        _mintERC2309(0x8423753fe03a4f0ACf792E00426BF6f758aE645D, 1);
        _mintERC2309(0xDbAAD435aC3a81858123b9b6ddFcd1851021e826, 1);
        _mintERC2309(0xAeA4C6c95D927172bD42aAcA170Aa3E92A29921C, 1);
        _mintERC2309(0x2cB2e57a922893c5a843399C42793BdCC6FC844C, 1);
        _mintERC2309(0xe905d18Bd971ce7A1976e0241DB396fAab8A5A32, 1);
        _mintERC2309(0xb73c6dD54f3d1723d7d76Cf230175B9100c36915, 1);
        _mintERC2309(0x2C72bc035Ba6242B7f7B7C1bdf0ed171A7c2b945, 1);
        _mintERC2309(0xe905d18Bd971ce7A1976e0241DB396fAab8A5A32, 1);
        _mintERC2309(0xd71514E903F1E3cABa8b92f8B980a16F0A3a413d, 1);
        _mintERC2309(0x6635675C439f545BC9FAD80d40c3C6b054EBc402, 1);
        _mintERC2309(0xCdA87A974DA84D23920071B5d71cF8ad76AEDF9f, 1);
        _mintERC2309(0x298c30F70bdc0d035bCE76D261E758240cFaD93A, 1);
        _mintERC2309(0xDe308A5F7EAE545e5dc312A5bC4689Ae82CdD9eE, 1);
        _mintERC2309(0xeCBD1663D744e9f08a381D32B18EA88aeB5b8D39, 1);
        _mintERC2309(0x2cB2e57a922893c5a843399C42793BdCC6FC844C, 1);
        _mintERC2309(0x68f0FAA81837D10aaF23974fa0CEb40220717f4e, 1);
        _mintERC2309(0xba7533A972bDaC8925A811aD456C95B220fE00f7, 1);
        _mintERC2309(0x6eB6a8f7F6d071af1311B194893c12796515CC54, 1);
        _mintERC2309(0xAeA4C6c95D927172bD42aAcA170Aa3E92A29921C, 1);
        _mintERC2309(0x653473A7b0BF45eee566d732FdEB8dc845EF6512, 1);
        _mintERC2309(0xba7533A972bDaC8925A811aD456C95B220fE00f7, 1);
        _mintERC2309(0x49f7989010Fe2751d60b6f239b6C61a497227Aef, 1);
        _mintERC2309(0xdEF769bcf57dF5a2400ab5f9DD3AaD5981079689, 1);
        _mintERC2309(0x6635675C439f545BC9FAD80d40c3C6b054EBc402, 1);
        _mintERC2309(0x5A70ec52E977B50c9fc12Ca0aA6d5e26E7C62291, 1);
        _mintERC2309(0x49f7989010Fe2751d60b6f239b6C61a497227Aef, 1);
        _mintERC2309(0xfE13A69994743AE68053CCC7A4d601d2B63c9318, 1);
        _mintERC2309(0x1790B08c57400Fe9b28Aa7c6C18272078cBEba25, 1);
        _mintERC2309(0x221AF81adDFaef129AD9a5e1aaE643fd00689b4E, 1);
        _mintERC2309(0x6eB6a8f7F6d071af1311B194893c12796515CC54, 1);
        _mintERC2309(0x51EC173342aEfd977A9481Cf0Ff474195b63E0b0, 1);
        _mintERC2309(0xe5E689114D80aBFB955a06B7b27d3226b65De421, 1);
        _mintERC2309(0xE1EF400f64240bBB30033818980A6b9c6f57D871, 1);
        _mintERC2309(0x4349Ad665636d65CEb89e415dC0d250Cb7b1D693, 1);
        _mintERC2309(0x68f0FAA81837D10aaF23974fa0CEb40220717f4e, 1);
        _mintERC2309(0x5A70ec52E977B50c9fc12Ca0aA6d5e26E7C62291, 1);
        _mintERC2309(0x475205225dBf2A2E4115574DA89b8F806af418b8, 1);
        _mintERC2309(0x298c30F70bdc0d035bCE76D261E758240cFaD93A, 1);
        _mintERC2309(0x221AF81adDFaef129AD9a5e1aaE643fd00689b4E, 1);
        _mintERC2309(0x69012192E2886D311a2FA6b6e0C8ea153dcccB7B, 1);
        _mintERC2309(0x27889b0CaCC1705b0E61780B16DF21C81dDB03F8, 1);
        _mintERC2309(0x9997E502d002506541Dd05264d717d0D6aFbB673, 1);
        _mintERC2309(0xB573D55bB681b091cA01ef0E78D519ED26238C38, 1);
        _mintERC2309(0xce3A505702d1f374B9CB277c7aCc4396944Fd238, 1);
        _mintERC2309(0xba7533A972bDaC8925A811aD456C95B220fE00f7, 1);
        _mintERC2309(0x216222ec646E764dA7995Ed3c02848568072cb58, 1);
        _mintERC2309(0x69Cd3080236750F7A006FdDdf86797A7Efc813a4, 1);
        _mintERC2309(0x2806cA13d7dA9a2EC03101D9dAa0A011E2b21c04, 2);
        _mintERC2309(0x5A70ec52E977B50c9fc12Ca0aA6d5e26E7C62291, 1);
        _mintERC2309(0x69Cd3080236750F7A006FdDdf86797A7Efc813a4, 1);
        _mintERC2309(0xAC844941f038ff6493B1eec17D4ec775DeC210DD, 2);
        _mintERC2309(0xce3A505702d1f374B9CB277c7aCc4396944Fd238, 1);
        _mintERC2309(0x69Cd3080236750F7A006FdDdf86797A7Efc813a4, 1);
        _mintERC2309(0x699a4Fbf7f094cff9e894a83b9a599B03b2723A1, 1);
        _mintERC2309(0xdE302714639124bce12389bb026484a2B07C43Ea, 1);
        _mintERC2309(0x8A4565Fb0C2862f85265af4794ffBED4Cf3e441D, 1);
        _mintERC2309(0x18AaC583c5782F4A7494A304c5F721ce4F02B471, 1);
        _mintERC2309(0xf44324E28bB9ce5C2a8B843377E92cb7f4Fdf376, 1);
        _mintERC2309(0x42d6B53B205CC931a93b845ac3A58B99c88437eD, 1);
        _mintERC2309(0x76b2F8C6DA7BFFB5A63eA41f794481E5C7D81e44, 1);
        _mintERC2309(0xE10820407810935e2d321E0641Bf4DABeeD61E12, 1);
        _mintERC2309(0xa724F5c322c6c281ABa5d49DcFD69dF1CE11511F, 1);
        _mintERC2309(0xcaf0624d4Ab1b0B45Aeee977a6008832e5860C93, 1);
        _mintERC2309(0x7185538FC7FA1220C9FCB6758D4AB60238Eaac5b, 1);
        _mintERC2309(0x87ac0553e62Fc074BcBAF9D348cC12D41A4c041e, 1);
        _mintERC2309(0xeCBD1663D744e9f08a381D32B18EA88aeB5b8D39, 1);
        _mintERC2309(0xba7533A972bDaC8925A811aD456C95B220fE00f7, 1);
        _mintERC2309(0x42d6B53B205CC931a93b845ac3A58B99c88437eD, 1);
        _mintERC2309(0x289C4dCB0B69BA183f0519C0D4191479327Cb06B, 1);
        _mintERC2309(0xeCBD1663D744e9f08a381D32B18EA88aeB5b8D39, 1);
        _mintERC2309(0x69Cd3080236750F7A006FdDdf86797A7Efc813a4, 1);
        _mintERC2309(0xc821eE063C0aBe2be67D0621b676C2Bcaa63cf4b, 1);
        _mintERC2309(0xE1EF400f64240bBB30033818980A6b9c6f57D871, 1);
        _mintERC2309(0x499Ad4e017E0aA45a2D32c54a7c7C3eAcDd72a33, 1);
        _mintERC2309(0x35fEC93300ce629707218950B88f071e2F2f437f, 1);
        _mintERC2309(0x499Ad4e017E0aA45a2D32c54a7c7C3eAcDd72a33, 1);
        _mintERC2309(0xba7533A972bDaC8925A811aD456C95B220fE00f7, 1);
        _mintERC2309(0xc821eE063C0aBe2be67D0621b676C2Bcaa63cf4b, 1);
        _mintERC2309(0x653473A7b0BF45eee566d732FdEB8dc845EF6512, 1);
        _mintERC2309(0x62b4618af958aBF3a4F803dFED365FD37618095c, 1);
        _mintERC2309(0xE4DEa04fa6FA74f0d62D7e987738a83E606C92a1, 1);
        _mintERC2309(0xdE302714639124bce12389bb026484a2B07C43Ea, 1);
        _mintERC2309(0x779A8A5a7d253Ea612Ca5fAdF589b16094952b66, 1);
        _mintERC2309(0x023f5B749860964393ae1217BB5d9bB56fe5dF23, 1);
        _mintERC2309(0x779A8A5a7d253Ea612Ca5fAdF589b16094952b66, 2);
        _mintERC2309(0x838450e58a9Ba982BB1866fcc2396Db8b307B9C9, 1);
        _mintERC2309(0xAA7c21fCe545fc47c80636127E408168e88c1a60, 1);
        _mintERC2309(0x896aE45164b0EB741074A1cDb3Df170f5ed8F664, 1);
        _mintERC2309(0x779A8A5a7d253Ea612Ca5fAdF589b16094952b66, 2);
        _mintERC2309(0x00386637CF48eB0341B3fcFE80edab62b78C866e, 1);
        _mintERC2309(0x8Dd982D63183E42dE34CeE77079CCACAEbe8B14F, 1);
        _mintERC2309(0x00386637CF48eB0341B3fcFE80edab62b78C866e, 1);
        _mintERC2309(0xa7f879Eee9C76b4b7Cf7c067e3CBf43A5E28ef33, 1);
        _mintERC2309(0x023f5B749860964393ae1217BB5d9bB56fe5dF23, 1);
        _mintERC2309(0x653473A7b0BF45eee566d732FdEB8dc845EF6512, 1);
        _mintERC2309(0x2cC71CffB7eBeE2596e60b70088fa195397494b2, 1);
        _mintERC2309(0xD87ad6e7D350CE4D568AE7b04558B8b6041d1DA3, 1);
        _mintERC2309(0xa7f879Eee9C76b4b7Cf7c067e3CBf43A5E28ef33, 1);
        _mintERC2309(0x8830516fDA3821fc0e805E9A982B143E8792d5DC, 2);
        _mintERC2309(0xbe85F5aDf3aFfFEa08a2529Bf992Ee96525Cfd2f, 1);
        _mintERC2309(0x2cC71CffB7eBeE2596e60b70088fa195397494b2, 1);
        _mintERC2309(0x789d757EB17a56eC7fAbcFaaa13f48BdcA651C18, 1);
        _mintERC2309(0xcED0ed8Cb5E884aE4e2A5E8aa9eCe1fD3404330e, 1);
        _mintERC2309(0xA90e35c6BE67920AdaB21F1a207eB3A736E06649, 1);
        _mintERC2309(0x3181955d2646998f7150065E2A48823D78123928, 1);
        _mintERC2309(0x679eB39CC05CE43B9b813dF8abc4f66da896bcD6, 1);
        _mintERC2309(0x8CF6B98F59487ed43f64c7a94516dCA2f010ACC8, 1);
        _mintERC2309(0x4fa0e8318DFBb42233eCb5330661691fa802c458, 1);
        _mintERC2309(0x838450e58a9Ba982BB1866fcc2396Db8b307B9C9, 1);
        _mintERC2309(0x2b0A63c55F5926699Be551C968A1EA3B22B08691, 1);
        _mintERC2309(0x99b096CE65C4A273dfdE3E7F14d792C2F76BCc98, 1);
        _mintERC2309(0x042CFA58735B52790E3F25eDc99Aca32677b3b50, 1);
        _mintERC2309(0xdEF769bcf57dF5a2400ab5f9DD3AaD5981079689, 1);
        _mintERC2309(0x515d1a7b1982826D53194E03fbBAcDf392034b83, 2);
        _mintERC2309(0x71Ef3244fDac9168Ee3382aF5aD99dA09632649a, 1);
        _mintERC2309(0x515d1a7b1982826D53194E03fbBAcDf392034b83, 1);
        _mintERC2309(0x499Ad4e017E0aA45a2D32c54a7c7C3eAcDd72a33, 1);
        _mintERC2309(0x4DBE8b56E3D2a481bbdC4cF4Be98Fc5cBb888FbF, 1);
        _mintERC2309(0x7ADEE4C1Ec5427519A0cb78E354828E6dA58e871, 1);
        _mintERC2309(0xbb1fF00e5Af0f3b81e2F464a329ae4EE7C1DfbA5, 1);
        _mintERC2309(0xdE302714639124bce12389bb026484a2B07C43Ea, 1);
        _mintERC2309(0xCEA44512698Fce6D380683d69C3C551Da4EBc6eD, 2);
        _mintERC2309(0xCDD094642F5fB2445f108758929770257C9DA8e6, 1);
        _mintERC2309(0xCEA44512698Fce6D380683d69C3C551Da4EBc6eD, 3);
        _mintERC2309(0x0Cb2ECEfAb110966a117358abf5Dd3a635F9c3A1, 1);
        _mintERC2309(0x042CFA58735B52790E3F25eDc99Aca32677b3b50, 1);
        _mintERC2309(0x81134166c117ae6C8366C36BE9e886B0F7147faE, 1);
        _mintERC2309(0x1ff69103A094eFDc748A35ee0A6c193fF7f4728f, 1);
        _mintERC2309(0x1C96E40DA3eF76039D3cadD7892bF8209E5a8C99, 1);
        _mintERC2309(0x8423753fe03a4f0ACf792E00426BF6f758aE645D, 1);
        _mintERC2309(0x67c4E74Eaa79b6F7114B56D17B5BEd2F60c69fB5, 1);
        _mintERC2309(0xCA0E051598cbE53057ed34AAAFC32a3310f4aEe7, 1);
        _mintERC2309(0x3076dD2c4f6797034Ffb11cedFca352b579b120E, 2);
        _mintERC2309(0x5bB4E468d79Dce3C878F76535BeC388CcBCc4031, 1);
        _mintERC2309(0x9eD81f00b587781D7ee4473A878a07560944427b, 1);
        _mintERC2309(0xc181f3828fE39bbE39e78354795a676304a825A3, 1);
        _mintERC2309(0xB1d3A4c1907AD74f35dBBb5F1478dD456a9d81dF, 1);
        _mintERC2309(0x76D75605C770d6B17eFE12C17C001626D371710a, 1);
        _mintERC2309(0x010298F5dDE499b371A86d6ce7ee454b68B62780, 1);
        _mintERC2309(0x52bE0A4F75DF6fD45770f5A6E71ac269185D48e0, 1);
        _mintERC2309(0x9e86cC88D072e1c0259ee96cFBc457fEFfCC1Fee, 1);
        _mintERC2309(0xb9fA7689bDfE2f3718f3b101af60936D6f993324, 2);
        _mintERC2309(0xa7b065AB08a41609b508aFCd87473cb22af3a08A, 2);
        _mintERC2309(0x499Ad4e017E0aA45a2D32c54a7c7C3eAcDd72a33, 1);
        _mintERC2309(0x9d79F12e677822C2d3F9745e422Cb1CdBc5A41AA, 1);
        _mintERC2309(0xbC9bB672d0732165535C49eD8bBa7c9e9BA988Cc, 1);
        _mintERC2309(0x8a1635C39C53DeEdf9fD8a1A28B0f0f4d2fF5a78, 1);
        _mintERC2309(0x826EC552A86b20302a3f01B6980b662Eb1Ba7a44, 1);
        _mintERC2309(0x58E6a5cD87d38Ae2C35007B1bD7b25026be9b0b1, 1);
        _mintERC2309(0x462eA027f18B85e550225E3A767cbc8c0833d973, 1);
        _mintERC2309(0x58E6a5cD87d38Ae2C35007B1bD7b25026be9b0b1, 1);
        _mintERC2309(0x8a1635C39C53DeEdf9fD8a1A28B0f0f4d2fF5a78, 1);
        _mintERC2309(0x187D8e97ffb6a92Ad0Ca25F80d97ada595513C88, 1);
        _mintERC2309(0xCa5334CE5a579C72413B58411F3E0Fb4CD4c345c, 1);
        _mintERC2309(0x95a00FFb2EaE9420287BF374F08dE040e7637D3A, 1);
        _mintERC2309(0x84Df49B1D4FdceE1e3B410669B7e5087412B411B, 1);
        _mintERC2309(0xb34b19f30D0E72c407ccF136aA6ac9E71B7B0684, 1);
        _mintERC2309(0x5f3fEa69BfC3fe51E9E43e3BE05dD5794AC50AB6, 1);
        _mintERC2309(0x865901C6bB1dD7842975f66E2B5Db494735F3655, 1);
        _mintERC2309(0x200cA9451C7d1fD027b3b04B1A08Bce257e21888, 2);
        _mintERC2309(0x408fdb9063b25542e95b171aE53046a6950E50Cd, 1);
        _mintERC2309(0x552e366f9D3c4f4C1f9F2bebC493715F866Fe9D9, 1);
        _mintERC2309(0x408fdb9063b25542e95b171aE53046a6950E50Cd, 1);
        _mintERC2309(0x6aE5bf41457D9f938F4f2588b9200f4390B23f9c, 1);
        _mintERC2309(0xB609d966A45ec87AfB84BF4a3F3DD29DE2deeD83, 1);
        _mintERC2309(0x413Cf568d0aA5aE64C9A0161b207e165Cb8D35C4, 1);
        _mintERC2309(0xB609d966A45ec87AfB84BF4a3F3DD29DE2deeD83, 1);
        _mintERC2309(0x289C4dCB0B69BA183f0519C0D4191479327Cb06B, 1);
        _mintERC2309(0x0C375dA33507197f318E0F92aCAc6f45B53f2629, 1);
        _mintERC2309(0xf932755165312e18b62484B9A23B517Cc07a7ba2, 1);
        _mintERC2309(0x6dBBa020D28DDEc7A8859Cc10F7641b7F8c11419, 1);
        _mintERC2309(0xFeEC85c46f99a9722636044D5EA0B5DFDD5C5CD7, 1);
        _mintERC2309(0xcaf0624d4Ab1b0B45Aeee977a6008832e5860C93, 1);
        _mintERC2309(0xAeA4C6c95D927172bD42aAcA170Aa3E92A29921C, 1);
        _mintERC2309(0x385fd77f7B5A1e67222c94304D342ff4752ce92c, 2);
        _mintERC2309(0x997708fe9e316F6E6b3Ef91a53374148795f0e5C, 2);
        _mintERC2309(0xfcF8a7B49539154CCf149Ca2FF4Fdf12E39A1DB7, 1);
        _mintERC2309(0xfAd606Fe2181966C8703C84125BfdAd2A541BE2b, 1);
        _mintERC2309(0x308a4Fa5D38Ff273eD2E4618f66bDD864a3dDA7E, 1);
        _mintERC2309(0x18AaC583c5782F4A7494A304c5F721ce4F02B471, 1);
        _mintERC2309(0x7e2aA3047eb37eBAeF3438A1becC0c1FdF14B383, 1);
        _mintERC2309(0x0CDD65d3e6e80dA2e5A11F7C1cEdaCE730372D7E, 1);
        _mintERC2309(0xAbb9190C87955BdabDfd3DF0D4E0D415ec18dfB1, 1);
        _mintERC2309(0x4AB59d6caC15920b2f2909C0529995e12C509b80, 1);
        _mintERC2309(0x8f5FBdc4a08d48cACC468B30b55705529944bC8c, 1);
        _mintERC2309(0xAA7c21fCe545fc47c80636127E408168e88c1a60, 1);
        _mintERC2309(0x67c4E74Eaa79b6F7114B56D17B5BEd2F60c69fB5, 2);
        _mintERC2309(0x9DE9b25139df40e04202E42e4F53e52c9Ef6e949, 1);
        _mintERC2309(0x3E0d3071DA4Fc3139E11cb92a49460748712051a, 1);
        _mintERC2309(0xbf2C8b554a1D227F41EAc0e6F50fe5700e9EAc8D, 2);
        _mintERC2309(0x6d557322D7a8f399d6dD61DA819592AcE36E556c, 1);
        _mintERC2309(0x590f4faFe1966803c79a038c462C8F28B06668d8, 1);
        _mintERC2309(0xfbcD2a7Fa20c267b8d9363098399BFD307c7748b, 1);
        _mintERC2309(0xCEA44512698Fce6D380683d69C3C551Da4EBc6eD, 1);
        _mintERC2309(0x252aD4c147630634170971fE0BEe72FeaF7DfCb3, 1);
        _mintERC2309(0xe35932989927AF1Ce78F54af6578FD22dB3ce675, 1);
        _mintERC2309(0xe2B0cEb92Ee82D48d06c5c41bb307DCb367EA94A, 1);
        _mintERC2309(0x499Ad4e017E0aA45a2D32c54a7c7C3eAcDd72a33, 1);
        _mintERC2309(0x5A70ec52E977B50c9fc12Ca0aA6d5e26E7C62291, 1);
        _mintERC2309(0x6619032e9fb486d738CF6db6ba39F18e59C38B10, 1);
        _mintERC2309(0x62c912f6B8727Af47DC0bcB6862E5E4804b26f24, 1);
        _mintERC2309(0xb50260f2076D744A6a87d4Ba0102fA8770c08e34, 2);
        _mintERC2309(0xfcf7cF49aB34E43EFDeEaD51eEDc0f1D25E43cC5, 1);
        _mintERC2309(0xD0010f430E836137bCCB778C5e9886E0c58B4b6C, 1);
        _mintERC2309(0x8eb80a451c61116395CF7BDA5B641a4569A11e63, 1);
        _mintERC2309(0xB94664acC7c7750B92f028b1e7139e19BF4922e9, 1);
        _mintERC2309(0x340ee74B7257C6b11b7Bf47fD279558Ea9E143f8, 1);
        _mintERC2309(0x46acF7AaF70e7dFC2AAA4c176E05fBa9F5c0A009, 1);
        _mintERC2309(0x744e14680b3C9693442e8526e22E1d5F60101846, 1);
        _mintERC2309(0x5EAe85C3dc16032878a579a39C85Ad7eCa3e7dc5, 1);
        _mintERC2309(0xb8410f47e152E6ec0E7578f8e0D79d10FB90e09b, 1);
        _mintERC2309(0x6bade65A3C3CB9E81cF8316c76a799947bA87d32, 1);
        _mintERC2309(0x3CFd1a2CF9585AfB5c0B18C15b174BAAae58ac21, 1);
        _mintERC2309(0x99b096CE65C4A273dfdE3E7F14d792C2F76BCc98, 1);
        _mintERC2309(0x778c1694994C24D701accb42F48c1BD10d10EE4C, 1);
        _mintERC2309(0x85150706937Ec68194677131A1F1F94c3dD38664, 1);
        _mintERC2309(0x415bd9A5e2fDcB8310ceE3F785F25B5E4D4564E3, 2);
        _mintERC2309(0x216222ec646E764dA7995Ed3c02848568072cb58, 1);
        _mintERC2309(0x7B056DcF6551f96d54AC2040ae89f8b30e0D77cb, 1);
        _mintERC2309(0x8165a12EE90d17278d30D8442c64AF767a05E12C, 2);
        _mintERC2309(0x7B056DcF6551f96d54AC2040ae89f8b30e0D77cb, 2);
        _mintERC2309(0x8165a12EE90d17278d30D8442c64AF767a05E12C, 3);
        _mintERC2309(0x26349cC1373c1e8A834815e930aD05632C375B27, 1);
        _mintERC2309(0x8165a12EE90d17278d30D8442c64AF767a05E12C, 22);
    }

    function initializeTiers() internal {
        tierByToken[1] = 2;
        tierByToken[3] = 2;
        tierByToken[4] = 2;
        tierByToken[5] = 1;
        tierByToken[6] = 1;
        tierByToken[7] = 1;
        tierByToken[9] = 1;
        tierByToken[10] = 1;
        tierByToken[11] = 2;
        tierByToken[13] = 1;
        tierByToken[17] = 1;
        tierByToken[20] = 1;
        tierByToken[21] = 1;
        tierByToken[22] = 1;
        tierByToken[25] = 1;
        tierByToken[26] = 1;
        tierByToken[27] = 1;
        tierByToken[28] = 1;
        tierByToken[29] = 1;
        tierByToken[31] = 1;
        tierByToken[32] = 1;
        tierByToken[33] = 1;
        tierByToken[35] = 1;
        tierByToken[37] = 1;
        tierByToken[39] = 1;
        tierByToken[40] = 1;
        tierByToken[41] = 1;
        tierByToken[42] = 1;
        tierByToken[43] = 1;
        tierByToken[44] = 1;
        tierByToken[48] = 1;
        tierByToken[49] = 1;
        tierByToken[50] = 1;
        tierByToken[51] = 1;
        tierByToken[52] = 1;
        tierByToken[53] = 1;
        tierByToken[55] = 1;
        tierByToken[56] = 1;
        tierByToken[57] = 1;
        tierByToken[58] = 1;
        tierByToken[59] = 1;
        tierByToken[60] = 1;
        tierByToken[61] = 1;
        tierByToken[62] = 1;
        tierByToken[63] = 1;
        tierByToken[64] = 1;
        tierByToken[65] = 1;
        tierByToken[66] = 1;
        tierByToken[67] = 1;
        tierByToken[68] = 1;
        tierByToken[70] = 1;
        tierByToken[72] = 1;
        tierByToken[74] = 1;
        tierByToken[75] = 1;
        tierByToken[79] = 1;
        tierByToken[81] = 1;
        tierByToken[82] = 1;
        tierByToken[83] = 1;
        tierByToken[84] = 2;
        tierByToken[85] = 2;
        tierByToken[86] = 1;
        tierByToken[87] = 2;
        tierByToken[90] = 1;
        tierByToken[91] = 1;
        tierByToken[92] = 1;
        tierByToken[94] = 1;
        tierByToken[96] = 1;
        tierByToken[97] = 1;
        tierByToken[98] = 2;
        tierByToken[99] = 1;
        tierByToken[100] = 1;
        tierByToken[101] = 1;
        tierByToken[103] = 1;
        tierByToken[105] = 1;
        tierByToken[107] = 1;
        tierByToken[109] = 1;
        tierByToken[110] = 2;
        tierByToken[111] = 1;
        tierByToken[112] = 1;
        tierByToken[113] = 1;
        tierByToken[115] = 1;
        tierByToken[116] = 1;
        tierByToken[117] = 1;
        tierByToken[118] = 1;
        tierByToken[120] = 1;
        tierByToken[122] = 1;
        tierByToken[124] = 1;
        tierByToken[125] = 1;
        tierByToken[126] = 1;
        tierByToken[128] = 1;
        tierByToken[130] = 1;
        tierByToken[132] = 1;
        tierByToken[136] = 2;
        tierByToken[140] = 2;
        tierByToken[143] = 1;
        tierByToken[146] = 1;
        tierByToken[149] = 1;
        tierByToken[150] = 1;
        tierByToken[151] = 1;
        tierByToken[153] = 1;
        tierByToken[154] = 2;
        tierByToken[155] = 1;
        tierByToken[156] = 1;
        tierByToken[157] = 2;
        tierByToken[159] = 1;
        tierByToken[161] = 1;
        tierByToken[162] = 1;
        tierByToken[164] = 1;
        tierByToken[167] = 1;
        tierByToken[168] = 1;
        tierByToken[169] = 1;
        tierByToken[174] = 1;
        tierByToken[175] = 1;
        tierByToken[177] = 1;
        tierByToken[179] = 2;
        tierByToken[180] = 1;
        tierByToken[181] = 1;
        tierByToken[182] = 1;
        tierByToken[183] = 1;
        tierByToken[184] = 1;
        tierByToken[188] = 1;
        tierByToken[193] = 2;
        tierByToken[194] = 1;
        tierByToken[195] = 1;
        tierByToken[196] = 1;
        tierByToken[197] = 1;
        tierByToken[198] = 1;
        tierByToken[199] = 1;
        tierByToken[205] = 1;
        tierByToken[207] = 1;
        tierByToken[210] = 1;
        tierByToken[211] = 2;
        tierByToken[214] = 1;
        tierByToken[217] = 1;
        tierByToken[219] = 1;
        tierByToken[222] = 1;
        tierByToken[224] = 1;
        tierByToken[226] = 2;
        tierByToken[228] = 2;
        tierByToken[231] = 1;
        tierByToken[232] = 1;
        tierByToken[237] = 1;
        tierByToken[238] = 1;
        tierByToken[241] = 1;
        tierByToken[244] = 1;
        tierByToken[248] = 1;
        tierByToken[250] = 2;
        tierByToken[252] = 1;
        tierByToken[257] = 1;
        tierByToken[266] = 1;
        tierByToken[267] = 1;
        tierByToken[270] = 1;
        tierByToken[271] = 1;
        tierByToken[277] = 1;
        tierByToken[284] = 2;
        tierByToken[300] = 2;
        tierByToken[331] = 2;
        tierByToken[332] = 2;
        tierByToken[333] = 2;
    }

    /*
    ================================================
                Internal Write Functions         
    ================================================
*/

    function _lockToken(uint256 tokenId) internal {
        require(
            ownerOf(tokenId) == msg.sender || owner() == msg.sender,
            "You must own a token in order to unlock it"
        );
        require(lockStatus[tokenId] == false, "token already locked");
        lockStatus[tokenId] = true;
        lockData[tokenId] = block.timestamp;
        emit Lock(tokenId, block.timestamp, ownerOf(tokenId));
    }

    function _unlockToken(uint256 tokenId) internal {
        require(
            ownerOf(tokenId) == msg.sender || owner() == msg.sender,
            "You must own a token in order to unlock it"
        );
        require(lockStatus[tokenId] == true, "token not locked");
        lockStatus[tokenId] = false;
        lockData[tokenId] = 0;
        emit Unlock(tokenId, block.timestamp, ownerOf(tokenId));
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        bool lock = false;
        for (uint256 i; i < quantity; i++) {
            if (lockStatus[startTokenId + i] == true) {
                lock = true;
            }
        }
        require(lock == false, "Token Locked");
    }

    /*
    ================================================
                    VIEW FUNCTIONS        
    ================================================
*/

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }

    function getBaseURI() external view returns (string memory) {
        return baseURI;
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
// ERC721A Contracts v4.1.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import './IERC721A.sol';

/**
 * @dev ERC721 token receiver interface.
 */
interface ERC721A__IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard,
 * including the Metadata extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at `_startTokenId()`
 * (defaults to 0, e.g. 0, 1, 2, 3..).
 *
 * Assumes that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 *
 * Assumes that the maximum token id cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is IERC721A {
    // Mask of an entry in packed address data.
    uint256 private constant BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;

    // The bit position of `numberMinted` in packed address data.
    uint256 private constant BITPOS_NUMBER_MINTED = 64;

    // The bit position of `numberBurned` in packed address data.
    uint256 private constant BITPOS_NUMBER_BURNED = 128;

    // The bit position of `aux` in packed address data.
    uint256 private constant BITPOS_AUX = 192;

    // Mask of all 256 bits in packed address data except the 64 bits for `aux`.
    uint256 private constant BITMASK_AUX_COMPLEMENT = (1 << 192) - 1;

    // The bit position of `startTimestamp` in packed ownership.
    uint256 private constant BITPOS_START_TIMESTAMP = 160;

    // The bit mask of the `burned` bit in packed ownership.
    uint256 private constant BITMASK_BURNED = 1 << 224;

    // The bit position of the `nextInitialized` bit in packed ownership.
    uint256 private constant BITPOS_NEXT_INITIALIZED = 225;

    // The bit mask of the `nextInitialized` bit in packed ownership.
    uint256 private constant BITMASK_NEXT_INITIALIZED = 1 << 225;

    // The bit position of `extraData` in packed ownership.
    uint256 private constant BITPOS_EXTRA_DATA = 232;

    // Mask of all 256 bits in a packed ownership except the 24 bits for `extraData`.
    uint256 private constant BITMASK_EXTRA_DATA_COMPLEMENT = (1 << 232) - 1;

    // The mask of the lower 160 bits for addresses.
    uint256 private constant BITMASK_ADDRESS = (1 << 160) - 1;

    // The maximum `quantity` that can be minted with `_mintERC2309`.
    // This limit is to prevent overflows on the address data entries.
    // For a limit of 5000, a total of 3.689e15 calls to `_mintERC2309`
    // is required to cause an overflow, which is unrealistic.
    uint256 private constant MAX_MINT_ERC2309_QUANTITY_LIMIT = 5000;

    // The tokenId of the next token to be minted.
    uint256 public _currentIndex;

    // The number of tokens burned.
    uint256 private _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned.
    // See `_packedOwnershipOf` implementation for details.
    //
    // Bits Layout:
    // - [0..159]   `addr`
    // - [160..223] `startTimestamp`
    // - [224]      `burned`
    // - [225]      `nextInitialized`
    // - [232..255] `extraData`
    mapping(uint256 => uint256) private _packedOwnerships;

    // Mapping owner address to address data.
    //
    // Bits Layout:
    // - [0..63]    `balance`
    // - [64..127]  `numberMinted`
    // - [128..191] `numberBurned`
    // - [192..255] `aux`
    mapping(address => uint256) private _packedAddressData;

    // Mapping from token ID to approved address.
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    /**
     * @dev Returns the starting token ID.
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 1;
    }

    /**
     * @dev Returns the next token ID to be minted.
     */
    function _nextTokenId() internal view returns (uint256) {
        return _currentIndex;
    }

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see `_totalMinted`.
     */
    function totalSupply() public view override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than `_currentIndex - _startTokenId()` times.
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * @dev Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view returns (uint256) {
        // Counter underflow is impossible as _currentIndex does not decrement,
        // and it is initialized to `_startTokenId()`
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /**
     * @dev Returns the total number of tokens burned.
     */
    function _totalBurned() internal view returns (uint256) {
        return _burnCounter;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // The interface IDs are constants representing the first 4 bytes of the XOR of
        // all function selectors in the interface. See: https://eips.ethereum.org/EIPS/eip-165
        // e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return _packedAddressData[owner] & BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> BITPOS_NUMBER_MINTED) & BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> BITPOS_NUMBER_BURNED) & BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return uint64(_packedAddressData[owner] >> BITPOS_AUX);
    }

    /**
     * Sets the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal {
        uint256 packed = _packedAddressData[owner];
        uint256 auxCasted;
        // Cast `aux` with assembly to avoid redundant masking.
        assembly {
            auxCasted := aux
        }
        packed = (packed & BITMASK_AUX_COMPLEMENT) | (auxCasted << BITPOS_AUX);
        _packedAddressData[owner] = packed;
    }

    /**
     * Returns the packed ownership data of `tokenId`.
     */
    function _packedOwnershipOf(uint256 tokenId) private view returns (uint256) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr)
                if (curr < _currentIndex) {
                    uint256 packed = _packedOwnerships[curr];
                    // If not burned.
                    if (packed & BITMASK_BURNED == 0) {
                        // Invariant:
                        // There will always be an ownership that has an address and is not burned
                        // before an ownership that does not have an address and is not burned.
                        // Hence, curr will not underflow.
                        //
                        // We can directly compare the packed value.
                        // If the address is zero, packed is zero.
                        while (packed == 0) {
                            packed = _packedOwnerships[--curr];
                        }
                        return packed;
                    }
                }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * Returns the unpacked `TokenOwnership` struct from `packed`.
     */
    function _unpackedOwnership(uint256 packed) private pure returns (TokenOwnership memory ownership) {
        ownership.addr = address(uint160(packed));
        ownership.startTimestamp = uint64(packed >> BITPOS_START_TIMESTAMP);
        ownership.burned = packed & BITMASK_BURNED != 0;
        ownership.extraData = uint24(packed >> BITPOS_EXTRA_DATA);
    }

    /**
     * Returns the unpacked `TokenOwnership` struct at `index`.
     */
    function _ownershipAt(uint256 index) internal view returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnerships[index]);
    }

    /**
     * @dev Initializes the ownership slot minted at `index` for efficiency purposes.
     */
    function _initializeOwnershipAt(uint256 index) internal {
        if (_packedOwnerships[index] == 0) {
            _packedOwnerships[index] = _packedOwnershipOf(index);
        }
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function _ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnershipOf(tokenId));
    }

    /**
     * @dev Packs ownership data into a single uint256.
     */
    function _packOwnershipData(address owner, uint256 flags) private view returns (uint256 result) {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, BITMASK_ADDRESS)
            // `owner | (block.timestamp << BITPOS_START_TIMESTAMP) | flags`.
            result := or(owner, or(shl(BITPOS_START_TIMESTAMP, timestamp()), flags))
        }
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return address(uint160(_packedOwnershipOf(tokenId)));
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
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, it can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    /**
     * @dev Returns the `nextInitialized` flag set if `quantity` equals 1.
     */
    function _nextInitializedFlag(uint256 quantity) private pure returns (uint256 result) {
        // For branchless setting of the `nextInitialized` flag.
        assembly {
            // `(quantity == 1) << BITPOS_NEXT_INITIALIZED`.
            result := shl(BITPOS_NEXT_INITIALIZED, eq(quantity, 1))
        }
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = ownerOf(tokenId);

        if (_msgSenderERC721A() != owner)
            if (!isApprovedForAll(owner, _msgSenderERC721A())) {
                revert ApprovalCallerNotOwnerNorApproved();
            }

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
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
    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (operator == _msgSenderERC721A()) revert ApproveToCaller();

        _operatorApprovals[_msgSenderERC721A()][operator] = approved;
        emit ApprovalForAll(_msgSenderERC721A(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
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
        transferFrom(from, to, tokenId);
        if (to.code.length != 0)
            if (!_checkContractOnERC721Received(from, to, tokenId, _data)) {
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
        return
            _startTokenId() <= tokenId &&
            tokenId < _currentIndex && // If within bounds,
            _packedOwnerships[tokenId] & BITMASK_BURNED == 0; // and not burned.
    }

    /**
     * @dev Equivalent to `_safeMint(to, quantity, '')`.
     */
    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, '');
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement
     *   {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * See {_mint}.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        _mint(to, quantity);

        unchecked {
            if (to.code.length != 0) {
                uint256 end = _currentIndex;
                uint256 index = end - quantity;
                do {
                    if (!_checkContractOnERC721Received(address(0), to, index++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (index < end);
                // Reentrancy protection.
                if (_currentIndex != end) revert();
            }
        }
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _mint(address to, uint256 quantity) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // `balance` and `numberMinted` have a maximum limit of 2**64.
        // `tokenId` has a maximum limit of 2**256.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            _packedAddressData[to] += quantity * ((1 << BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            uint256 tokenId = startTokenId;
            uint256 end = startTokenId + quantity;
            do {
                emit Transfer(address(0), to, tokenId++);
            } while (tokenId < end);

            _currentIndex = end;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * This function is intended for efficient minting only during contract creation.
     *
     * It emits only one {ConsecutiveTransfer} as defined in
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309),
     * instead of a sequence of {Transfer} event(s).
     *
     * Calling this function outside of contract creation WILL make your contract
     * non-compliant with the ERC721 standard.
     * For full ERC721 compliance, substituting ERC721 {Transfer} event(s) with the ERC2309
     * {ConsecutiveTransfer} event is only permissible during contract creation.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {ConsecutiveTransfer} event.
     */
    function _mintERC2309(address to, uint256 quantity) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();
        if (quantity > MAX_MINT_ERC2309_QUANTITY_LIMIT) revert MintERC2309QuantityExceedsLimit();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are unrealistic due to the above check for `quantity` to be below the limit.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            _packedAddressData[to] += quantity * ((1 << BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            emit ConsecutiveTransfer(startTokenId, startTokenId + quantity - 1, address(0), to);

            _currentIndex = startTokenId + quantity;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Returns the storage slot and value for the approved address of `tokenId`.
     */
    function _getApprovedAddress(uint256 tokenId)
        private
        view
        returns (uint256 approvedAddressSlot, address approvedAddress)
    {
        mapping(uint256 => address) storage tokenApprovalsPtr = _tokenApprovals;
        // The following is equivalent to `approvedAddress = _tokenApprovals[tokenId]`.
        assembly {
            // Compute the slot.
            mstore(0x00, tokenId)
            mstore(0x20, tokenApprovalsPtr.slot)
            approvedAddressSlot := keccak256(0x00, 0x40)
            // Load the slot's value from storage.
            approvedAddress := sload(approvedAddressSlot)
        }
    }

    /**
     * @dev Returns whether the `approvedAddress` is equals to `from` or `msgSender`.
     */
    function _isOwnerOrApproved(
        address approvedAddress,
        address from,
        address msgSender
    ) private pure returns (bool result) {
        assembly {
            // Mask `from` to the lower 160 bits, in case the upper bits somehow aren't clean.
            from := and(from, BITMASK_ADDRESS)
            // Mask `msgSender` to the lower 160 bits, in case the upper bits somehow aren't clean.
            msgSender := and(msgSender, BITMASK_ADDRESS)
            // `msgSender == from || msgSender == approvedAddress`.
            result := or(eq(msgSender, from), eq(msgSender, approvedAddress))
        }
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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        if (address(uint160(prevOwnershipPacked)) != from) revert TransferFromIncorrectOwner();

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedAddress(tokenId);

        // The nested ifs save around 20+ gas over a compound boolean condition.
        if (!_isOwnerOrApproved(approvedAddress, from, _msgSenderERC721A()))
            if (!isApprovedForAll(from, _msgSenderERC721A())) revert TransferCallerNotOwnerNorApproved();

        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            // We can directly increment and decrement the balances.
            --_packedAddressData[from]; // Updates: `balance -= 1`.
            ++_packedAddressData[to]; // Updates: `balance += 1`.

            // Updates:
            // - `address` to the next owner.
            // - `startTimestamp` to the timestamp of transfering.
            // - `burned` to `false`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                to,
                BITMASK_NEXT_INITIALIZED | _nextExtraData(from, to, prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Equivalent to `_burn(tokenId, false)`.
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
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
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        address from = address(uint160(prevOwnershipPacked));

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedAddress(tokenId);

        if (approvalCheck) {
            // The nested ifs save around 20+ gas over a compound boolean condition.
            if (!_isOwnerOrApproved(approvedAddress, from, _msgSenderERC721A()))
                if (!isApprovedForAll(from, _msgSenderERC721A())) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // Updates:
            // - `balance -= 1`.
            // - `numberBurned += 1`.
            //
            // We can directly decrement the balance, and increment the number burned.
            // This is equivalent to `packed -= 1; packed += 1 << BITPOS_NUMBER_BURNED;`.
            _packedAddressData[from] += (1 << BITPOS_NUMBER_BURNED) - 1;

            // Updates:
            // - `address` to the last owner.
            // - `startTimestamp` to the timestamp of burning.
            // - `burned` to `true`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                from,
                (BITMASK_BURNED | BITMASK_NEXT_INITIALIZED) | _nextExtraData(from, address(0), prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
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
        try ERC721A__IERC721Receiver(to).onERC721Received(_msgSenderERC721A(), from, tokenId, _data) returns (
            bytes4 retval
        ) {
            return retval == ERC721A__IERC721Receiver(to).onERC721Received.selector;
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
     * @dev Directly sets the extra data for the ownership data `index`.
     */
    function _setExtraDataAt(uint256 index, uint24 extraData) internal {
        uint256 packed = _packedOwnerships[index];
        if (packed == 0) revert OwnershipNotInitializedForExtraData();
        uint256 extraDataCasted;
        // Cast `extraData` with assembly to avoid redundant masking.
        assembly {
            extraDataCasted := extraData
        }
        packed = (packed & BITMASK_EXTRA_DATA_COMPLEMENT) | (extraDataCasted << BITPOS_EXTRA_DATA);
        _packedOwnerships[index] = packed;
    }

    /**
     * @dev Returns the next extra data for the packed ownership data.
     * The returned result is shifted into position.
     */
    function _nextExtraData(
        address from,
        address to,
        uint256 prevOwnershipPacked
    ) private view returns (uint256) {
        uint24 extraData = uint24(prevOwnershipPacked >> BITPOS_EXTRA_DATA);
        return uint256(_extraData(from, to, extraData)) << BITPOS_EXTRA_DATA;
    }

    /**
     * @dev Called during each token transfer to set the 24bit `extraData` field.
     * Intended to be overridden by the cosumer contract.
     *
     * `previousExtraData` - the value of `extraData` before transfer.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _extraData(
        address from,
        address to,
        uint24 previousExtraData
    ) internal view virtual returns (uint24) {}

    /**
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred.
     * This includes minting.
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
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred.
     * This includes minting.
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

    /**
     * @dev Returns the message sender (defaults to `msg.sender`).
     *
     * If you are writing GSN compatible contracts, you need to override this function.
     */
    function _msgSenderERC721A() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function _toString(uint256 value) internal pure returns (string memory ptr) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit),
            // but we allocate 128 bytes to keep the free memory pointer 32-byte word aliged.
            // We will need 1 32-byte word to store the length,
            // and 3 32-byte words to store a maximum of 78 digits. Total: 32 + 3 * 32 = 128.
            ptr := add(mload(0x40), 128)
            // Update the free memory pointer to allocate.
            mstore(0x40, ptr)

            // Cache the end of the memory to calculate the length later.
            let end := ptr

            // We write the string from the rightmost digit to the leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // Costs a bit more than early returning for the zero case,
            // but cheaper in terms of deployment and overall runtime costs.
            for {
                // Initialize and perform the first pass without check.
                let temp := value
                // Move the pointer 1 byte leftwards to point to an empty character slot.
                ptr := sub(ptr, 1)
                // Write the character to the pointer. 48 is the ASCII index of '0'.
                mstore8(ptr, add(48, mod(temp, 10)))
                temp := div(temp, 10)
            } temp {
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
            } {
                // Body of the for loop.
                ptr := sub(ptr, 1)
                mstore8(ptr, add(48, mod(temp, 10)))
            }

            let length := sub(end, ptr)
            // Move the pointer 32 bytes leftwards to make room for the length.
            ptr := sub(ptr, 32)
            // Store the length.
            mstore(ptr, length)
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
// ERC721A Contracts v4.1.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of an ERC721A compliant contract.
 */
interface IERC721A {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * The caller cannot approve to their own address.
     */
    error ApproveToCaller();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set through `_extraData`.
        uint24 extraData;
    }

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     *
     * Burned tokens are calculated here, use `_totalMinted()` if you want to count just minted tokens.
     */
    function totalSupply() external view returns (uint256);

    // ==============================
    //            IERC165
    // ==============================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // ==============================
    //            IERC721
    // ==============================

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

    // ==============================
    //        IERC721Metadata
    // ==============================

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

    // ==============================
    //            IERC2309
    // ==============================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId` (inclusive) is transferred from `from` to `to`,
     * as defined in the ERC2309 standard. See `_mintERC2309` for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}