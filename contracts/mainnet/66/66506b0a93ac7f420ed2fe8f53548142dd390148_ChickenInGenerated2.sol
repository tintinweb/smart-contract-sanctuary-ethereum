/**
 *Submitted for verification at Etherscan.io on 2022-10-18
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

contract EggTraitWeights {
    enum BorderColor {
        White,
        Black,
        Bronze,
        Silver,
        Gold,
        Rainbow
    }

    enum CardColor {
        Red,
        Green,
        Blue,
        Purple,
        Pink,
        YellowPink,
        BlueGreen,
        PinkBlue,
        RedPurple,
        Bronze,
        Silver,
        Gold,
        Rainbow
    }

    enum ShellColor {
        OffWhite,
        LightBlue,
        DarkerBlue,
        LighterOrange,
        LightOrange,
        DarkerOrange,
        LightGreen,
        DarkerGreen,
        Bronze,
        Silver,
        Gold,
        Rainbow,
        Luminous
    }

    uint256[6] public borderWeights = [30e16, 30e16, 15e16, 12e16, 8e16, 5e16];
    uint256[13] public cardWeights = [12e16, 12e16, 12e16, 11e16, 11e16, 7e16, 7e16, 7e16, 7e16, 5e16, 4e16, 3e16, 2e16];
    uint256[13] public shellWeights = [11e16, 9e16, 9e16, 10e16, 10e16, 10e16, 10e16, 10e16, 75e15, 6e16, 4e16, 25e15, 1e16];

    // Turn the pseudo-random number `rand` -- 18 digit FP in range [0,1) -- into a border color.
    function _getBorderColor(uint256 rand) internal view returns (BorderColor) {
        uint256 needle = borderWeights[uint256(BorderColor.White)];
        if (rand < needle) { return BorderColor.White; }
        needle += borderWeights[uint256(BorderColor.Black)];
        if (rand < needle) { return BorderColor.Black; }
        needle += borderWeights[uint256(BorderColor.Bronze)];
        if (rand < needle) { return BorderColor.Bronze; }
        needle += borderWeights[uint256(BorderColor.Silver)];
        if (rand < needle) { return BorderColor.Silver; }
        needle += borderWeights[uint256(BorderColor.Gold)];
        if (rand < needle) { return BorderColor.Gold; }
        return BorderColor.Rainbow;
    }

    function _getCardAffinityWeights(BorderColor borderColor) internal view returns (uint256[13] memory cardWeightsCached) {
        if (borderColor == BorderColor.Bronze ||
            borderColor == BorderColor.Silver ||
            borderColor == BorderColor.Gold   ||
            borderColor == BorderColor.Rainbow
        ) {
            uint256 selectedCardColor =
                borderColor == BorderColor.Bronze ? uint256(CardColor.Bronze) :
                borderColor == BorderColor.Silver ? uint256(CardColor.Silver) :
                borderColor == BorderColor.Gold ? uint256(CardColor.Gold) :
                uint256(CardColor.Rainbow);
            uint256 originalWeight = cardWeights[selectedCardColor];
            uint256 finalWeight = originalWeight * 2;
            // As we are going to duplicate the original weight of the selected color,
            // we reduce that extra amount from all other weights, proportionally,
            // so we keep the total of 100%
            for (uint256 i = 0; i < cardWeightsCached.length; i++) {
                cardWeightsCached[i] = cardWeights[i] * (1e18 - finalWeight) / (1e18 - originalWeight);
            }
            cardWeightsCached[selectedCardColor] = finalWeight;
        } else {
            for (uint256 i = 0; i < cardWeightsCached.length; i++) {
                cardWeightsCached[i] = cardWeights[i];
            }
        }
    }

    // Turn the pseudo-random number `rand` -- 18 digit FP in range [0,1) -- into a card color.
    function _getCardColor(uint256 rand, BorderColor borderColor) internal view returns (CardColor) {
        // first adjust weights for affinity
        uint256[13] memory cardWeightsCached = _getCardAffinityWeights(borderColor);

        // then compute color
        uint256 needle = cardWeightsCached[uint256(CardColor.Red)];
        if (rand < needle) { return CardColor.Red; }
        needle += cardWeightsCached[uint256(CardColor.Green)];
        if (rand < needle) { return CardColor.Green; }
        needle += cardWeightsCached[uint256(CardColor.Blue)];
        if (rand < needle) { return CardColor.Blue; }
        needle += cardWeightsCached[uint256(CardColor.Purple)];
        if (rand < needle) { return CardColor.Purple; }
        needle += cardWeightsCached[uint256(CardColor.Pink)];
        if (rand < needle) { return CardColor.Pink; }
        needle += cardWeightsCached[uint256(CardColor.YellowPink)];
        if (rand < needle) { return CardColor.YellowPink; }
        needle += cardWeightsCached[uint256(CardColor.BlueGreen)];
        if (rand < needle) { return CardColor.BlueGreen; }
        needle += cardWeightsCached[uint256(CardColor.PinkBlue)];
        if (rand < needle) { return CardColor.PinkBlue; }
        needle += cardWeightsCached[uint256(CardColor.RedPurple)];
        if (rand < needle) { return CardColor.RedPurple; }
        needle += cardWeightsCached[uint256(CardColor.Bronze)];
        if (rand < needle) { return CardColor.Bronze; }
        needle += cardWeightsCached[uint256(CardColor.Silver)];
        if (rand < needle) { return CardColor.Silver; }
        needle += cardWeightsCached[uint256(CardColor.Gold)];
        if (rand < needle) { return CardColor.Gold; }
        return CardColor.Rainbow;
    }

    function _getShellAffinityWeights(BorderColor borderColor) internal view returns (uint256[13] memory shellWeightsCached) {
        if (borderColor == BorderColor.Bronze ||
            borderColor == BorderColor.Silver ||
            borderColor == BorderColor.Gold   ||
            borderColor == BorderColor.Rainbow
        ) {
            uint256 selectedShellColor =
                borderColor == BorderColor.Bronze ? uint256(ShellColor.Bronze) :
                borderColor == BorderColor.Silver ? uint256(ShellColor.Silver) :
                borderColor == BorderColor.Gold ? uint256(ShellColor.Gold) :
                uint256(ShellColor.Rainbow);
            uint256 originalWeight = shellWeights[selectedShellColor];
            uint256 finalWeight = originalWeight * 2;
            // As we are going to duplicate the original weight of the selected color,
            // we reduce that extra amount from all other weights, proportionally,
            // so we keep the total of 100%
            for (uint256 i = 0; i < shellWeightsCached.length; i++) {
                shellWeightsCached[i] = shellWeights[i] * (1e18 - finalWeight) / (1e18 - originalWeight);
            }
            shellWeightsCached[selectedShellColor] = finalWeight;
        } else {
            for (uint256 i = 0; i < shellWeightsCached.length; i++) {
                shellWeightsCached[i] = shellWeights[i];
            }
        }
    }

    // Turn the pseudo-random number `rand` -- 18 digit FP in range [0,1) -- into a shell color.
    function _getShellColor(uint256 rand, BorderColor borderColor) internal view returns (ShellColor) {
        // first adjust weights for affinity
        uint256[13] memory shellWeightsCached = _getShellAffinityWeights(borderColor);

        // then compute color
        uint256 needle = shellWeightsCached[uint256(ShellColor.OffWhite)];
        if (rand < needle) { return ShellColor.OffWhite; }
        needle += shellWeightsCached[uint256(ShellColor.LightBlue)];
        if (rand < needle) { return ShellColor.LightBlue; }
        needle += shellWeightsCached[uint256(ShellColor.DarkerBlue)];
        if (rand < needle) { return ShellColor.DarkerBlue; }
        needle += shellWeightsCached[uint256(ShellColor.LighterOrange)];
        if (rand < needle) { return ShellColor.LighterOrange; }
        needle += shellWeightsCached[uint256(ShellColor.LightOrange)];
        if (rand < needle) { return ShellColor.LightOrange; }
        needle += shellWeightsCached[uint256(ShellColor.DarkerOrange)];
        if (rand < needle) { return ShellColor.DarkerOrange; }
        needle += shellWeightsCached[uint256(ShellColor.LightGreen)];
        if (rand < needle) { return ShellColor.LightGreen; }
        needle += shellWeightsCached[uint256(ShellColor.DarkerGreen)];
        if (rand < needle) { return ShellColor.DarkerGreen; }
        needle += shellWeightsCached[uint256(ShellColor.Bronze)];
        if (rand < needle) { return ShellColor.Bronze; }
        needle += shellWeightsCached[uint256(ShellColor.Silver)];
        if (rand < needle) { return ShellColor.Silver; }
        needle += shellWeightsCached[uint256(ShellColor.Gold)];
        if (rand < needle) { return ShellColor.Gold; }
        needle += shellWeightsCached[uint256(ShellColor.Rainbow)];
        if (rand < needle) { return ShellColor.Rainbow; }
        return ShellColor.Luminous;
    }
}

enum Size {
    Tiny,
    Small,
    Normal,
    Big
}

struct CommonData {
    uint256 tokenID;

    // ChickenBondManager.BondData
    uint256 lusdAmount;
    uint256 claimedBLUSD;
    uint256 startTime;
    uint256 endTime;
    uint8 status;

    // IBondNFT.BondExtraData
    uint80 initialHalfDna;
    uint80 finalHalfDna;
    uint32 troveSize;
    uint32 lqtyAmount;
    uint32 curveGaugeSlopes;

    // Attributes derived from the DNA
    EggTraitWeights.BorderColor borderColor;
    EggTraitWeights.CardColor cardColor;
    EggTraitWeights.ShellColor shellColor;
    Size size;

    // Further data derived from the attributes
    bytes borderStyle;
    bytes cardStyle;
    bool hasCardGradient;
    string[2] cardGradient;
    string tokenIDString;
}

struct ChickenInData {
    // Attributes derived from the DNA
    EggTraitWeights.ShellColor chickenColor;
    uint8 comb;
    uint8 beak;
    uint8 tail;
    uint8 wing;

    // Further data derived from the attributes
    bool darkMode;
    bool hasLQTY;
    bool hasTrove;
    bool hasLlama;
    bool isRainbow;
    bytes caruncleStyle;
    bytes beakStyle;
    bytes legStyle;
    bytes chickenStyle;
    bytes bodyShadeStyle;
    bytes cheekStyle;
    bytes wingShadeStyle;
    bytes wingTipShadeStyle;
}

contract ChickenInAnimations {
    function getSVGAnimations(CommonData calldata _commonData) external pure returns (bytes memory) {
        string[4][10] memory p = [
            ['354.8', '348', '341.3', '334.5'],
            ['2.7', '3.6', '4.5', '5.4'],
            ['1.1', '1.4', '1.8', '2.2'],
            ['2.7', '3.6', '4.5', '5.4'],
            ['2.2', '2.9', '3.6', '4.3'],
            ['2.2', '2.9', '3.6', '4.3'],
            ['2.7', '3.6', '4.5', '5.4'],
            ['2.2', '2.9', '3.6', '4.3'],
            ['2.7', '3.6', '4.5', '5.4'],
            ['2.7', '3.6', '4.5', '5.4']
        ];

        return abi.encodePacked(
            abi.encodePacked(
                '#ci-chicken-',
                _commonData.tokenIDString,
                ' .ci-breath path,#ci-chicken-',
                _commonData.tokenIDString,
                ' .ci-breath ellipse{animation:ci-breath 0.4s infinite ease-in-out alternate;}#ci-chicken-',
                _commonData.tokenIDString,
                ' .ci-wing path{animation:ci-wing 3.2s infinite ease-in-out;transform-origin:',
                p[0][uint256(_commonData.size)],
                'px;}@keyframes ci-breath{0%{transform:translateY(0);}100%{transform:translateY(',
                p[1][uint256(_commonData.size)],
                'px);}}@keyframes ci-wing{0%{transform:translateY(0);}5%{transform:translateY(',
                p[2][uint256(_commonData.size)],
                'px)rotate(-2deg);}12.5%{transform:translateY('
            ),
            abi.encodePacked(
                p[3][uint256(_commonData.size)],
                'px)rotate(1deg);}15%{transform:translateY(',
                p[4][uint256(_commonData.size)],
                'px)rotate(2deg);}25%{transform:translateY(0)rotate(-2deg);}35%{transform:translateY(',
                p[5][uint256(_commonData.size)],
                'px)rotate(2deg);}37.5%{transform:translateY(',
                p[6][uint256(_commonData.size)],
                'px)rotate(1deg);}40%{transform:translateY(',
                p[7][uint256(_commonData.size)],
                'px);}50%{transform:translateY(0);}62.5%{transform:translateY(',
                p[8][uint256(_commonData.size)],
                'px);}75%{transform:translateY(0);}87.5%{transform:translateY(',
                p[9][uint256(_commonData.size)]
            ),
            'px);}100%{transform:translateY(0);}}'
        );
    }
}

contract ChickenInShadow {
    function getSVGShadow(CommonData calldata _commonData) external pure returns (bytes memory) {
        string[4][1] memory p = [
            ['cx="373.9" cy="575.9" rx="59.4" ry="7.6"', 'cx="373.6" cy="610.4" rx="79.2" ry="10.1"', 'cx="373.2" cy="644.9" rx="99" ry="12.6"', 'cx="372.8" cy="679.3" rx="118.8" ry="15.1"']
        ];

        return abi.encodePacked(
            '<ellipse style="mix-blend-mode:soft-light" ',
            p[0][uint256(_commonData.size)],
            '/>'
        );
    }
}

contract ChickenInLegs {
    function getSVGLegs(CommonData calldata _commonData, ChickenInData calldata _chickenInData) external pure returns (bytes memory) {
        string[4][4] memory p = [
            ['x="378.3" y="540" width="5.2" height="35.8" rx="2.2"', 'x="379.4" y="562.5" width="7" height="47.8" rx="2.9"', 'x="380.5" y="584.9" width="8.7" height="59.7" rx="3.6"', 'x="381.6" y="607.4" width="10.4" height="71.7" rx="4.3"'],
            ['M388.2 573.7l-4.6-4.9a0.7 0.7 0 0 0-0.4-0.2h-3.6a8.8 8.8 0 0 0-4 1.2l-5.8 3.6c-1.2 0.7-0.6 2.4 0.9 2.4h16.3C388.8 575.8 389.3 574.8 388.2 573.7Z', 'M392.6 607.4l-6.1-6.5a0.9 0.9 0 0 0-0.6-0.2h-4.8a11.7 11.7 0 0 0-5.3 1.5l-7.7 4.9c-1.6 1-0.8 3.2 1.2 3.1h21.7C393.4 610.3 394.1 608.9 392.6 607.4Z', 'M397 641.1l-7.6-8.1a1.1 1.1 0 0 0-0.8-0.3h-6a14.6 14.6 0 0 0-6.6 1.9l-9.6 6.1c-2 1.2-1 3.9 1.5 4h27.2C398 644.7 398.9 643.1 397 641.1Z', 'M401.4 674.8l-9.1-9.7a1.3 1.3 0 0 0-0.9-0.4h-7.3a17.6 17.6 0 0 0-7.9 2.4l-11.6 7.3c-2.4 1.5-1.1 4.7 1.8 4.7h32.7C402.6 679.1 403.7 677.2 401.4 674.8Z'],
            ['x="366.6" y="540" width="5.2" height="35.8" rx="2.2"', 'x="363.8" y="562.5" width="7" height="47.8" rx="2.9"', 'x="361" y="584.9" width="8.7" height="59.7" rx="3.6"', 'x="358.2" y="607.4" width="10.4" height="71.7" rx="4.3"'],
            ['M376.5 573.7l-4.6-4.9a0.7 0.7 0 0 0-0.5-0.2h-3.6a8.8 8.8 0 0 0-3.9 1.2l-5.8 3.6c-1.2 0.7-0.6 2.4 0.9 2.4h16.3C377.1 575.8 377.6 574.8 376.5 573.7Z', 'M377 607.4l-6.1-6.5a0.9 0.9 0 0 0-0.6-0.2h-4.8a11.7 11.7 0 0 0-5.4 1.5l-7.7 4.9c-1.6 1-0.8 3.2 1.2 3.1h21.8C377.8 610.3 378.5 608.9 377 607.4Z', 'M377.5 641.1l-7.7-8.1a1.1 1.1 0 0 0-0.7-0.3h-6a14.6 14.6 0 0 0-6.7 1.9l-9.6 6.1c-2 1.2-0.9 3.9 1.5 4h27.2C378.5 644.7 379.3 643.1 377.5 641.1Z', 'M378 674.8l-9.2-9.7a1.3 1.3 0 0 0-0.9-0.4h-7.2a17.6 17.6 0 0 0-8 2.4l-11.5 7.3c-2.4 1.5-1.1 4.7 1.8 4.7h32.6C379.1 679.1 380.2 677.2 378 674.8Z']
        ];

        return abi.encodePacked(
            abi.encodePacked(
                '<rect style="',
                _chickenInData.legStyle,
                '" ',
                p[0][uint256(_commonData.size)],
                '/><path style="',
                _chickenInData.legStyle,
                '" d="',
                p[1][uint256(_commonData.size)],
                '"/><rect style="',
                _chickenInData.legStyle,
                '" ',
                p[2][uint256(_commonData.size)],
                '/><path style="'
            ),
            abi.encodePacked(
                _chickenInData.legStyle,
                '" d="',
                p[3][uint256(_commonData.size)],
                '"/>'
            )
        );
    }
}

contract ChickenInBeak {
    function getSVGBeakPath(CommonData calldata _commonData, ChickenInData calldata _chickenInData, bytes calldata _style) external pure returns (bytes memory) {
        string[4][4][1] memory p = [
            [['M338.5 389.8l-12.4 4.2a0.6 0.6 0 0 0 0 1.2l12.5 3.1a0.6 0.6 0 0 0 0.8-0.6l-0.1-7.4A0.6 0.6 0 0 0 338.5 389.8Z', 'M342.7 390.4A28.8 28.8 0 0 0 333.4 391.7c-1.9 0.6-3.8 1.6-5.1 3.4a14.3 14.3 0 0 0-1.9 4.4c-0.2 0.6 0.3 1.2 0.8 0.9 3.7-2.5 8.2-2.9 12-1.2 0.3 0.1 0.6-0.1 0.7-0.5 0.8-2.7 2.1-5.6 2.8-8.3', 'M340.3 390.4a36.4 36.4 0 0 0-9.2 1.1c-1.8 0.5-3.7 1.3-5 2.8a9.8 9.8 0 0 0-1.7 3.4c-0.2 0.5 0.2 0.7 0.7 0.7 5.1 0 10-0.1 14.4-0.1 0.5 0 0.5-1 0.4-1.3 0.2-7.2 0.3-4.6 0.4-6.6', 'M340.7 391c-3.6-1-7.8-2.3-11.6-3.5a0.5 0.5 0 0 0-0.6 0.9c1.7 1.5 3.5 3.5 5.4 4.8a0.5 0.5 0 0 1-0.1 0.9c-2.5 1.3-5 2.2-7.4 3.7a0.5 0.5 0 0 0 0.3 1l12.7-0.7a0.5 0.5 0 0 0 0.5-0.6l0.6-6.5'], ['M326.4 362.2l-16.6 5.7a0.8 0.8 0 0 0 0 1.6l16.6 4.1a0.9 0.9 0 0 0 1.1-0.9l-0.1-9.7A0.8 0.8 0 0 0 326.4 362.2Z', 'M331.9 363A38.4 38.4 0 0 0 319.6 364.7c-2.5 0.8-5 2.1-6.8 4.6a19.1 19.1 0 0 0-2.6 5.9c-0.2 0.8 0.4 1.6 1 1.1 5-3.3 10.9-3.9 16.1-1.6 0.4 0.2 0.8-0.1 0.9-0.6 1-3.6 2.8-7.5 3.7-11.1', 'M328.7 363.1a48.5 48.5 0 0 0-12.3 1.4c-2.5 0.7-4.9 1.7-6.6 3.7a13.1 13.1 0 0 0-2.3 4.6c-0.2 0.7 0.3 0.9 1 0.9 6.9 0 13.3-0.1 19.1-0.2 0.7 0 0.6-1.3 0.7-1.7 0.3-9.6 0.4-6.2 0.4-8.7', 'M329.3 363.8c-4.8-1.4-10.5-3.1-15.5-4.7a0.7 0.7 0 0 0-0.8 1.3c2.3 2.1 4.6 4.7 7.2 6.3a0.7 0.7 0 0 1-0.1 1.3c-3.4 1.7-6.7 2.9-9.9 4.9a0.7 0.7 0 0 0 0.4 1.3l16.9-0.9a0.6 0.6 0 0 0 0.7-0.7l0.8-8.8'], ['M314.2 334.6l-20.7 7.1a1 1 0 0 0 0 2l20.8 5.1a1.1 1.1 0 0 0 1.3-1l-0.1-12.2A1 1 0 0 0 314.2 334.6Z', 'M321.1 335.7A48 48 0 0 0 305.7 337.8c-3.1 1-6.3 2.6-8.5 5.7a23.9 23.9 0 0 0-3.1 7.3c-0.3 1 0.5 2 1.2 1.5 6.2-4.1 13.6-4.9 20.1-2 0.5 0.2 1-0.1 1.1-0.8 1.3-4.5 3.5-9.4 4.6-13.8', 'M317.1 335.7a60.6 60.6 0 0 0-15.3 1.8c-3.1 0.8-6.2 2.1-8.3 4.6a16.3 16.3 0 0 0-2.9 5.8c-0.3 0.8 0.4 1.1 1.3 1.1 8.6-0.1 16.7-0.1 23.9-0.2 0.9 0 0.8-1.6 0.8-2.1 0.4-12 0.6-7.7 0.5-11', 'M317.9 336.6c-5.9-1.7-13.1-3.9-19.4-5.8a0.9 0.9 0 0 0-0.9 1.5c2.8 2.6 5.8 5.8 8.9 8a0.9 0.9 0 0 1-0.1 1.5c-4.2 2.1-8.4 3.6-12.4 6.2a0.9 0.9 0 0 0 0.6 1.6l21-1.1a0.8 0.8 0 0 0 0.9-0.9l1-11'], ['M302 307.1l-24.8 8.5a1.2 1.2 0 0 0 0 2.4l24.9 6.1a1.3 1.3 0 0 0 1.6-1.2l-0.1-14.7A1.2 1.2 0 0 0 302 307.1Z', 'M310.4 308.3A57.6 57.6 0 0 0 291.8 310.8c-3.7 1.2-7.6 3.1-10.2 6.9a28.6 28.6 0 0 0-3.7 8.8c-0.4 1.3 0.6 2.4 1.4 1.8 7.5-4.9 16.4-5.8 24.1-2.4 0.6 0.3 1.2-0.2 1.4-1 1.5-5.4 4.2-11.3 5.5-16.6', 'M305.5 308.4a72.8 72.8 0 0 0-18.3 2.1c-3.7 1-7.4 2.5-10 5.5a19.6 19.6 0 0 0-3.5 6.9c-0.3 1 0.5 1.4 1.6 1.4 10.3-0.1 20-0.2 28.6-0.3 1.1 0 1-1.9 1-2.5 0.5-14.4 0.7-9.3 0.6-13.1', 'M306.4 309.4c-7.1-2.1-15.7-4.7-23.3-6.9a1.1 1.1 0 0 0-1 1.8c3.4 3.1 7 7 10.7 9.5a1.1 1.1 0 0 1-0.1 1.9c-5.1 2.5-10.1 4.3-14.9 7.3a1.1 1.1 0 0 0 0.7 2l25.2-1.3a1 1 0 0 0 1.1-1.1l1.3-13.1']]
        ];

        return abi.encodePacked(
            '<path style="',
            _style,
            '" d="',
            p[0][uint256(_commonData.size)][_chickenInData.beak - 1],
            '"/>'
        );
    }
}

contract ChickenInWattle {
    function getSVGWattlePath(CommonData calldata _commonData, bytes calldata _style) external pure returns (bytes memory) {
        string[4][1] memory p = [
            ['M338 397.9c2.9 2.8 4.4 7.1 4.2 11.1a21 21 0 0 1-0.8 4.7c-0.7 2.6-1.7 5.2-3.7 7-2.7 2.6-6.8 3.1-10.6 2.7-2.2-0.2-4.6-0.9-5.9-2.7-1.2-1.7-1.3-4-1.1-6.1s0.7-4.2 2.1-5.8c1.6-1.8 4.2-2.5 6.5-3.3 3.8-1.5 6.7-4.4 9.3-7.6', 'M325.6 373c3.8 3.7 5.9 9.5 5.7 14.8a28 28 0 0 1-1.2 6.3c-1 3.4-2.3 6.9-4.9 9.3-3.7 3.4-9.1 4.2-14.1 3.7-3-0.3-6.1-1.2-7.9-3.6-1.7-2.3-1.7-5.3-1.3-8.2s0.9-5.6 2.7-7.7c2.2-2.5 5.6-3.3 8.6-4.5 5-2 8.9-5.9 12.4-10', 'M313.3 348.2c4.8 4.6 7.3 11.9 7 18.5a35 35 0 0 1-1.4 7.8c-1.2 4.3-2.9 8.6-6.1 11.6-4.6 4.3-11.4 5.2-17.6 4.6-3.7-0.4-7.7-1.5-9.9-4.5-2.1-2.8-2.1-6.7-1.7-10.2s1.1-7 3.4-9.6c2.7-3.1 7-4.1 10.8-5.6 6.3-2.5 11.2-7.4 15.5-12.6', 'M300.9 323.3c5.7 5.5 8.8 14.2 8.5 22.2a42.1 42.1 0 0 1-1.7 9.4c-1.4 5.1-3.5 10.3-7.3 14-5.5 5.1-13.7 6.3-21.2 5.4-4.4-0.5-9.2-1.8-11.9-5.4-2.5-3.4-2.5-8-2-12.2s1.3-8.4 4.1-11.5c3.2-3.7 8.3-4.9 12.9-6.7 7.6-3 13.4-8.9 18.7-15.2']
        ];

        return abi.encodePacked(
            '<path style="',
            _style,
            '" d="',
            p[0][uint256(_commonData.size)],
            '"/>'
        );
    }
}

contract ChickenInBody {
    function getSVGBody(CommonData calldata _commonData, ChickenInData calldata _chickenInData) external pure returns (bytes memory) {
        string[4][3] memory p = [
            ['M439.3 484.6c-2.7 1.1 4.3-6.5 5-10S425.2 491.7 396.5 479.4 376.1 425.8 376.6 414.2 372.3 377.2 352.4 379.7 338.2 399.3 334 410.7c-5.4 14.6-58.9 32.4-40.2 86.1 12.4 35.6 44.1 48.9 64 53.7 2.4 4.2 6.6 7 11.4 7.1a12.2 12.2 0 0 0 5.9-1.6A12.2 12.2 0 0 0 380.9 557.6c4.2 0 7.9-2.2 10.5-5.6 37.3-6 47.6-31.8 52.9-43.7C450.5 494.8 450.1 480.9 451.7 477.1S442 483.6 439.3 484.6Z', 'M460.7 488.7c-3.6 1.4 5.8-8.6 6.7-13.4S442 498.1 403.7 481.7 376.4 410.2 377.1 394.8 371.4 345.4 344.9 348.7 325.9 374.9 320.3 390.1c-7.2 19.4-78.5 43.2-53.6 114.8 16.6 47.5 58.8 65.2 85.3 71.6 3.3 5.6 8.9 9.4 15.3 9.4a16.3 16.3 0 0 0 7.8-2A16.3 16.3 0 0 0 382.9 585.9c5.6 0 10.5-2.9 13.9-7.3 49.7-8 63.4-42.3 70.6-58.4C475.6 502.2 475.1 483.7 477.2 478.6S464.3 487.3 460.7 488.7Z', 'M482.1 492.8c-4.5 1.8 7.2-10.8 8.4-16.8S458.7 504.4 410.9 484 376.8 394.7 377.6 375.3 370.5 313.7 337.3 317.8 313.6 350.5 306.6 369.4c-9 24.3-98.1 54-66.9 143.6 20.7 59.4 73.4 81.5 106.6 89.6 4.1 7.1 11.1 11.7 19 11.7a20.4 20.4 0 0 0 9.8-2.6A20.3 20.3 0 0 0 384.9 614.3c7 0 13.2-3.6 17.4-9.2 62.1-9.9 79.3-52.9 88.3-72.9C500.8 509.6 500.1 486.4 502.8 480.2S486.6 490.9 482.1 492.8Z', 'M503.5 496.8c-5.4 2.2 8.6-13 10.2-20.1S475.4 510.8 418 486.3 377.2 379.1 378.1 355.9 369.6 281.9 329.8 286.9 301.3 326.1 292.9 348.8c-10.8 29.2-117.7 64.8-80.3 172.3 24.8 71.3 88.1 97.7 127.9 107.5 4.9 8.5 13.3 14 22.9 14a24.5 24.5 0 0 0 11.7-3A24.4 24.4 0 0 0 386.9 642.6c8.3 0 15.8-4.3 20.8-11 74.5-11.9 95.1-63.5 106-87.5C525.9 517 525.1 489.2 528.4 481.7S508.9 494.6 503.5 496.8Z'],
            ['M390.1 502.5c-30.8-5.9-61.6-16.7-74-47-3.6-8.5-4.2-18.6-0.2-27-15.8 13.6-34.3 33.3-22.1 68.3 12.4 35.6 44.1 48.9 64 53.7 2.4 4.2 6.6 7 11.4 7.1a12.2 12.2 0 0 0 5.9-1.6A12.2 12.2 0 0 0 380.9 557.6c4.2 0 7.9-2.2 10.5-5.6 37.3-6 47.6-31.8 52.9-43.7a66.3 66.3 0 0 0 4.4-13.6C431.9 504.9 410.1 505.9 390.1 502.5Z', 'M395.2 512.5c-41-7.9-82.1-22.3-98.7-62.7-4.8-11.4-5.6-24.8-0.3-36-21.1 18.1-45.7 44.4-29.5 91.1 16.6 47.5 58.8 65.2 85.3 71.6 3.3 5.6 8.9 9.4 15.3 9.4a16.3 16.3 0 0 0 7.8-2A16.3 16.3 0 0 0 382.9 585.9c5.6 0 10.5-2.9 13.9-7.3 49.7-8 63.4-42.3 70.6-58.4a88.3 88.3 0 0 0 5.8-18.1C450.9 515.7 421.8 517 395.2 512.5Z', 'M400.2 522.5c-51.3-9.9-102.6-27.9-123.3-78.3-6-14.2-7-31-0.4-45.1-26.4 22.6-57.2 55.5-36.8 113.9 20.7 59.4 73.4 81.5 106.6 89.6 4.1 7.1 11.1 11.7 19 11.7a20.4 20.4 0 0 0 9.8-2.6A20.3 20.3 0 0 0 384.9 614.3c7 0 13.2-3.6 17.4-9.2 62.1-9.9 79.3-52.9 88.3-72.9a110.4 110.4 0 0 0 7.2-22.7C469.9 526.5 433.6 528.1 400.2 522.5Z', 'M405.2 532.4c-61.6-11.9-123.1-33.5-147.9-93.9-7.2-17.1-8.4-37.2-0.5-54.1-31.7 27.1-68.6 66.6-44.2 136.7 24.8 71.3 88.1 97.7 127.9 107.5 4.9 8.5 13.3 14 22.9 14a24.5 24.5 0 0 0 11.7-3A24.4 24.4 0 0 0 386.9 642.6c8.3 0 15.8-4.3 20.8-11 74.5-11.9 95.1-63.5 106-87.5a132.5 132.5 0 0 0 8.7-27.3C488.8 537.3 445.3 539.3 405.2 532.4Z'],
            ['M394.5 540a100.3 100.3 0 0 1-38.3-2.8L355.6 537c-9.7-2.7-17.8-7-26.5-11.9-18-10-32.8-26.5-39.1-46.5a68 68 0 0 0 3.8 18.2c12.4 35.6 44.1 48.9 64 53.7 2.4 4.2 6.6 7 11.4 7.1a12.2 12.2 0 0 0 5.9-1.6A12.2 12.2 0 0 0 380.9 557.6c4.2 0 7.9-2.1 10.5-5.5 24.3-3.9 37.1-16.2 44.6-27.7A92.8 92.8 0 0 1 394.5 540Z', 'M401 562.5a133.7 133.7 0 0 1-51.1-3.8L349.1 558.5c-13-3.6-23.8-9.4-35.3-15.8-24-13.3-43.7-35.4-52.2-62a90.6 90.6 0 0 0 5.1 24.2c16.6 47.5 58.8 65.2 85.3 71.6 3.3 5.7 8.9 9.4 15.3 9.4a16.3 16.3 0 0 0 7.8-2A16.3 16.3 0 0 0 382.9 585.9c5.6 0 10.5-2.8 13.9-7.3 32.4-5.2 49.5-21.6 59.5-36.9A123.7 123.7 0 0 1 401 562.5Z', 'M407.5 585a167.2 167.2 0 0 1-63.9-4.7L342.6 580.1c-16.2-4.5-29.7-11.7-44.1-19.8-30-16.7-54.6-44.2-65.2-77.6a113.3 113.3 0 0 0 6.4 30.3c20.7 59.4 73.4 81.5 106.6 89.6 4.1 7.1 11.1 11.7 19 11.7a20.4 20.4 0 0 0 9.8-2.6A20.3 20.3 0 0 0 384.9 614.3c6.9 0 13.2-3.6 17.4-9.2 40.5-6.5 61.9-27 74.3-46.1A154.6 154.6 0 0 1 407.5 585Z', 'M414 607.5a200.6 200.6 0 0 1-76.6-5.6L336.1 601.6c-19.4-5.4-35.6-14-52.9-23.8-36-20-65.6-53-78.3-93a136 136 0 0 0 7.7 36.3c24.8 71.3 88.1 97.7 127.9 107.5 4.9 8.5 13.3 14 22.9 14a24.5 24.5 0 0 0 11.7-3A24.4 24.4 0 0 0 386.9 642.6c8.3 0 15.8-4.3 20.8-11 48.6-7.8 74.3-32.4 89.3-55.3A185.5 185.5 0 0 1 414 607.5Z']
        ];

        return abi.encodePacked(
            '<path style="',
            _chickenInData.chickenStyle,
            '" d="',
            p[0][uint256(_commonData.size)],
            '"/><path style="',
            _chickenInData.bodyShadeStyle,
            '" d="',
            p[1][uint256(_commonData.size)],
            '"/><path style="',
            _chickenInData.bodyShadeStyle,
            '" d="',
            p[2][uint256(_commonData.size)],
            '"/>'
        );
    }
}

contract ChickenInEye {
    function getSVGEye(CommonData calldata _commonData) external pure returns (bytes memory) {
        string[4][3] memory p = [
            ['M351.5 397.9a12.8 12.8 0 0 1 6.1 1.4 7.8 7.8 0 1 0-11.9-0.1A13 13 0 0 1 351.5 397.9Z', 'M343.7 373a17.1 17.1 0 0 1 8.1 1.9 10.4 10.4 0 1 0-15.9-0.2A17.3 17.3 0 0 1 343.7 373Z', 'M335.9 348.1a21.4 21.4 0 0 1 10.1 2.4 13 13 0 1 0-19.9-0.2A21.6 21.6 0 0 1 335.9 348.1Z', 'M328 323.2a25.7 25.7 0 0 1 12.2 2.9 15.6 15.6 0 1 0-23.8-0.2A25.9 25.9 0 0 1 328 323.2Z'],
            ['M348.7 398.1a13.8 13.8 0 0 1 2.8-0.2 14 14 0 0 1 3.1 0.3 5 5 0 1 0-5.9-0.1Z', 'M340 373.3a18.5 18.5 0 0 1 3.7-0.3 18.7 18.7 0 0 1 4.1 0.4 6.6 6.6 0 1 0-7.8-0.1Z', 'M331.2 348.6a23.1 23.1 0 0 1 4.6-0.5 23.3 23.3 0 0 1 5.2 0.6 8.3 8.3 0 1 0-9.8-0.1Z', 'M322.4 323.8a27.7 27.7 0 0 1 5.6-0.6 28 28 0 0 1 6.2 0.7 9.9 9.9 0 1 0-11.8-0.1Z'],
            ['cx="352.9" cy="392.3" rx="1.6" ry="1.6"', 'cx="345.5" cy="365.6" rx="2.2" ry="2.2"', 'cx="338.1" cy="338.9" rx="2.7" ry="2.7"', 'cx="330.7" cy="312.1" rx="3.2" ry="3.2"']
        ];

        return abi.encodePacked(
            '<path style="fill:#fff" d="',
            p[0][uint256(_commonData.size)],
            '"/><path style="fill:#000" d="',
            p[1][uint256(_commonData.size)],
            '"/><ellipse style="fill:#fff" ',
            p[2][uint256(_commonData.size)],
            '/>'
        );
    }
}

contract ChickenInComb {
    function getSVGCombPath(CommonData calldata _commonData, ChickenInData calldata _chickenInData, bytes calldata _style) external pure returns (bytes memory) {
        string[9][4][1] memory p = [
            [['M340.9 385a38.7 38.7 0 0 0 2.8-14.9c0-2 0-4.2 1.6-5.4 1.9-1.5 4.9 0 5.8 2.1s0.6 4.7 0.1 7L358.5 359.9a7.2 7.2 0 0 1 1.6-2.3c2.2-1.8 5.8-0.3 7.2 2.2s1 5.6 0.5 8.4q-0.6 3.6-1.3 7.1l11.1-9.1c2.4-2 5.2-4.1 8.3-3.9a5.4 5.4 0 0 1 2 0.5 5.8 5.8 0 0 1 2.1 2c2.2 3.3 1.5 7.9-0.7 11.2s-5.9 5.4-9.5 7c-7.7 3.5-16.4 5.5-24.7 4.1-4.8-0.8-9.5-2.7-14.3-1.9', 'M338.3 392.9c-1.6-4.9-2-10.1-0.4-15s5.2-9.2 10-11.2A10.6 10.6 0 0 1 354 365.9a6.3 6.3 0 0 1 4.7 3.7c2.1-2.3 5-3.8 8.1-3.8s6.1 2.1 6.9 5.1A12.3 12.3 0 0 1 381.5 368.9c2.7 0.3 5.3 1.9 6.5 4.3 1.6 3.2 0.6 7.1-0.7 10.4a10 10 0 0 1-2.2 3.8A7.7 7.7 0 0 1 381.5 389.1c-4.3 1-8.7-0.3-12.7-2.2s-7.7-4.2-11.9-5.4-9-1.4-12.6 1.2S338.8 391.8 338.3 392.9', 'M341 384.8a24.4 24.4 0 0 1-4-9.9c-0.7-3.9-0.1-8.5 3-11 1.8-1.4 4.3-1.9 6.6-1.9 4.7 0.2 9.6 3.2 10.5 7.9 2.3-5.2 9.5-7.6 14.4-4.8s6.5 10.3 3.1 14.9a9.3 9.3 0 0 1 8.8 13.1 5.8 5.8 0 0 1-2.9 3c-2 0.8-4.3 0-5.9-1.4s-2.9-3.1-4.4-4.6c-3.6-3.6-8.7-5.5-13.8-6s-10.3 0.1-15.4 0.6', 'M338 390.1a0.2 0.2 0 0 1-0.1-0.1c-1.8-3.2-1.9-7.1-1.5-10.8a23.6 23.6 0 0 1 2.2-8.1c2.2-4.3 6.3-7.3 10.8-9 3.9-1.5 8.1-2 12.4-2.3a0.5 0.5 0 0 1 0.3 1 18.7 18.7 0 0 0-3.8 4.3 0.5 0.5 0 0 0 0.7 0.7 45.4 45.4 0 0 1 14.7-4.3 0.5 0.5 0 0 1 0.4 0.8 28 28 0 0 0-3 4.4 0.5 0.5 0 0 0 0.7 0.8 38.2 38.2 0 0 1 12.4-3.6 0.5 0.5 0 0 1 0.5 1 27 27 0 0 0-3.4 4.4 0.5 0.5 0 0 0 0.5 0.8c5.9-1.2 11.2-4.5 16.4-7.8a0.5 0.5 0 0 1 0.8 0.4c0.1 2.5-0.9 5-1.9 7.4-1.8 4-3.6 8-6.5 11.3-5.4 6.1-13.6 8.6-21.6 10.2h0Z', 'M340.4 390.8a15.2 15.2 0 1 1 11.6-27.2c3.1-6.5 10.7-10.3 17.9-9.4s13.4 6.1 16 12.8 1.6 14.6-2.2 20.7c-3.2 5.2-9.6 9.3-15.1 6.9C369.1 387.5 363 380.4 355.8 379.8S341.1 383.5 340.4 390.7', 'M340.4 391.3a0.2 0.2 0 0 1-0.2 0c-2.5-2.7-3.5-6.5-3.8-10.2-0.3-2.8-0.4-5.7 0.2-8.4 1.2-4.7 4.5-8.6 8.5-11.2 3.5-2.3 7.5-3.8 11.5-5a0.5 0.5 0 0 1 0.6 0.8 18.6 18.6 0 0 0-2.7 5.1 0.5 0.5 0 0 0 0.8 0.6 45.5 45.5 0 0 1 13.3-7.6 0.5 0.5 0 0 1 0.7 0.7 27.5 27.5 0 0 0-2 5 0.5 0.5 0 0 0 0.9 0.5 38.1 38.1 0 0 1 11.2-6.2 0.5 0.5 0 0 1 0.7 0.8 27.2 27.2 0 0 0-2.3 5.1 0.5 0.5 0 0 0 0.7 0.7c5.5-2.5 9.9-6.9 14.2-11.4a0.5 0.5 0 0 1 0.9 0.2c0.7 2.4 0.2 5.1-0.3 7.7-0.8 4.3-1.6 8.6-3.7 12.4-3.8 7.1-11.3 11.5-18.7 14.9l0 0Z', 'M370.7 389.6c2.6-4.2 4.2-7.8 5.3-12.6 1.4-6.2 1.4-13.3-2.6-18.3a19.4 19.4 0 0 0-6.5-4.9c-8.9-4.5-20.8-4.2-28 2.8a1.2 1.2 0 0 0-0.4 0.7c0 0.4 0.4 0.8 0.8 1L350.7 365c-5.2-1.2-10.7 1.5-14.1 5.5s-5.2 9.2-6.6 14.4c2.1-1.8 5.2-2 7.8-1.3s5.2 1.9 7.8 2.6C354.3 388.7 363.1 384.7 370.7 389.6', 'M338.5 389.1c-9.7-6.7-15.2-20.1-11.3-31.2a0.7 0.7 0 0 1 1.1-0.3 79.9 79.9 0 0 0 13.6 8.7 0.7 0.7 0 0 0 1.1-0.8c-1.9-11.9 5-24.8 16-29.7a0.7 0.7 0 0 1 1 0.8 51.1 51.1 0 0 0 1.4 25.6 0.7 0.7 0 0 0 1.1 0.4 44.6 44.6 0 0 1 38.8-2 0.7 0.7 0 0 1-0.2 1.4c-10 1.8-20.7 4.6-26.3 12.7a0.7 0.7 0 0 0 0.5 1.2 42.3 42.3 0 0 1 28.8 20.2A0.7 0.7 0 0 1 403.5 397.2c-11.1 0.6-26.9 0.2-37.9 0.8a0.7 0.7 0 0 1-0.7-0.6c-1.3-6.2-1.1-10.5-7.3-12.5-6.4-2.1-14.1-0.3-19.1 4.2', 'M338.9 387.3c9 2.6 16.2 1.6 25.4 0.2a145.7 145.7 0 0 0 30.6-8.2c7.3-2.8 14.9-6.8 18-14a16.4 16.4 0 0 0-23.4-20.6c1.1-3.4-1.2-7.2-4.5-8.5s-7.1-0.5-10.1 1.3-5.2 4.8-7 7.8A58.3 58.3 0 0 0 360.4 363.3c2-4.8-2.7-10.4-7.9-10.5s-9.7 3.8-11.8 8.4c-2.2-5.6-10.7-6.7-15.1-2.5s-4.6 11.4-1.7 16.7 9.4 9.7 15 11.9Z'], ['M329.5 355.8a51.7 51.7 0 0 0 3.8-19.8c0-2.6 0-5.7 2-7.3 2.5-1.9 6.5-0.1 7.8 2.9s0.8 6.2 0.2 9.3L353 322.4a9.6 9.6 0 0 1 2.2-3.1c2.9-2.4 7.8-0.5 9.5 2.9s1.3 7.4 0.7 11.2q-0.8 4.8-1.8 9.5l14.9-12.2c3.2-2.6 6.9-5.4 11-5.2a7.3 7.3 0 0 1 2.7 0.7 7.7 7.7 0 0 1 2.9 2.6c3 4.4 2.1 10.6-1 15s-7.8 7.1-12.7 9.3c-10.3 4.7-21.8 7.3-33 5.5-6.4-1.1-12.7-3.5-19-2.5', 'M326 366.3c-2.1-6.5-2.7-13.4-0.5-20s7-12.2 13.3-14.9A14.2 14.2 0 0 1 347 330.3a8.4 8.4 0 0 1 6.3 4.9c2.8-3 6.7-5.1 10.8-4.9s8.2 2.8 9.2 6.7A16.4 16.4 0 0 1 383.6 334.3c3.6 0.4 7.1 2.5 8.8 5.8 2.2 4.3 0.8 9.5-1 13.9a13.4 13.4 0 0 1-3 5A10.2 10.2 0 0 1 383.6 361.3c-5.7 1.3-11.6-0.4-16.9-2.9s-10.3-5.5-15.8-7.2-12-1.8-16.8 1.5S326.8 364.9 326 366.3', 'M329.6 355.5a32.5 32.5 0 0 1-5.2-13.2c-0.9-5.2-0.2-11.3 3.9-14.6 2.4-1.9 5.7-2.6 8.8-2.5 6.3 0.3 12.7 4.3 14 10.5 3.1-7 12.7-10.1 19.3-6.4s8.6 13.7 4.1 19.9a12.3 12.3 0 0 1 11.7 17.4 7.7 7.7 0 0 1-3.8 4.1c-2.6 1.1-5.7-0.1-8-1.9s-3.8-4.2-5.8-6.2c-4.8-4.9-11.7-7.3-18.5-8s-13.7 0.1-20.5 0.9', 'M325.7 362.6a0.3 0.3 0 0 1-0.2-0.1c-2.5-4.2-2.5-9.5-2-14.4a31.4 31.4 0 0 1 2.9-10.8c2.9-5.7 8.4-9.8 14.5-12 5.2-2 10.9-2.7 16.4-3a0.7 0.7 0 0 1 0.5 1.3 25 25 0 0 0-5.1 5.7 0.7 0.7 0 0 0 1 1 60.5 60.5 0 0 1 19.5-5.9 0.7 0.7 0 0 1 0.7 1.2 37.4 37.4 0 0 0-4.1 5.8 0.7 0.7 0 0 0 0.9 1 50.9 50.9 0 0 1 16.6-4.7 0.7 0.7 0 0 1 0.6 1.3 36 36 0 0 0-4.6 5.9 0.7 0.7 0 0 0 0.8 1.1c7.9-1.6 15-6 21.8-10.4a0.7 0.7 0 0 1 1.1 0.5c0.2 3.4-1.3 6.7-2.6 9.8-2.3 5.3-4.8 10.7-8.6 15.1-7.1 8.1-18.2 11.5-28.8 13.6h0Z', 'M328.9 363.6a20.2 20.2 0 1 1 15.5-36.3c4.2-8.6 14.3-13.7 23.8-12.6s17.9 8.2 21.4 17.1 2.1 19.4-3 27.6c-4.3 6.9-12.8 12.4-20.2 9.3C367.1 359.1 359 349.7 349.4 348.9S329.9 353.8 328.9 363.4', 'M328.9 364.3a0.2 0.2 0 0 1-0.2-0.1c-3.4-3.6-4.6-8.6-5.2-13.5-0.4-3.7-0.6-7.6 0.3-11.2 1.5-6.2 6-11.4 11.3-15 4.7-3.1 10-5.1 15.4-6.7a0.7 0.7 0 0 1 0.8 1.2 24.8 24.8 0 0 0-3.7 6.7 0.7 0.7 0 0 0 1.2 0.8 60.7 60.7 0 0 1 17.7-10.2 0.7 0.7 0 0 1 0.9 1 36.7 36.7 0 0 0-2.7 6.6 0.7 0.7 0 0 0 1.2 0.8 50.8 50.8 0 0 1 15-8.3 0.7 0.7 0 0 1 0.9 1 36.2 36.2 0 0 0-3.1 6.8 0.7 0.7 0 0 0 1 0.9c7.3-3.4 13.2-9.3 18.9-15.1a0.7 0.7 0 0 1 1.2 0.3c0.9 3.2 0.3 6.8-0.3 10.1-1.1 5.7-2.2 11.5-5 16.6-5.1 9.5-15.1 15.4-24.9 19.8l-0.1 0Z', 'M369.2 362c3.4-5.7 5.5-10.4 7.1-16.8 1.9-8.3 1.9-17.8-3.5-24.4a25.8 25.8 0 0 0-8.6-6.6c-11.9-6-27.8-5.6-37.3 3.8a1.6 1.6 0 0 0-0.5 0.9c0 0.6 0.5 1 1 1.3L342.6 329.2c-6.9-1.6-14.2 2-18.8 7.3s-7 12.3-8.9 19.2c2.8-2.4 6.9-2.6 10.5-1.8s6.9 2.5 10.4 3.6C347.4 360.8 359.2 355.4 369.2 362', 'M326.3 361.3c-13-8.9-20.3-26.8-15.1-41.6a1 1 0 0 1 1.6-0.4 106.5 106.5 0 0 0 18.1 11.7 1 1 0 0 0 1.4-1.1c-2.6-15.9 6.6-33.1 21.3-39.7a1 1 0 0 1 1.4 1.1 68.1 68.1 0 0 0 1.9 34.2 1 1 0 0 0 1.4 0.5 59.5 59.5 0 0 1 51.8-2.7 1 1 0 0 1-0.3 1.9c-13.4 2.4-27.5 6.2-35.1 16.9a1 1 0 0 0 0.7 1.6 56.4 56.4 0 0 1 38.4 26.9A1 1 0 0 1 413 372.1c-14.9 0.8-35.8 0.3-50.5 1.1a1 1 0 0 1-1-0.8c-1.7-8.3-1.4-14-9.7-16.7-8.5-2.8-18.8-0.4-25.5 5.6', 'M326.9 358.9c12 3.5 21.6 2.2 33.8 0.3a194.3 194.3 0 0 0 40.9-11c9.7-3.8 19.8-9.1 23.9-18.6a21.9 21.9 0 0 0-31.2-27.5c1.4-4.5-1.6-9.6-6-11.4s-9.5-0.7-13.4 1.8-6.9 6.4-9.4 10.4A77.8 77.8 0 0 0 355.6 326.9c2.6-6.3-3.6-13.8-10.5-14s-13 5-15.9 11.2c-2.9-7.5-14.3-8.9-20.1-3.3s-6.1 15.2-2.2 22.2 12.5 13 20 15.9Z'], ['M318.1 326.6a64.6 64.6 0 0 0 4.8-24.7c0-3.3-0.1-7.1 2.5-9.1 3.1-2.4 8.1-0.1 9.7 3.5s0.9 7.8 0.3 11.7L347.5 284.9a12 12 0 0 1 2.7-3.9c3.7-3.1 9.7-0.6 11.9 3.6s1.7 9.3 0.9 14q-1 5.9-2.2 11.9l18.5-15.2c4-3.3 8.6-6.8 13.8-6.5a9.1 9.1 0 0 1 3.4 0.8 9.6 9.6 0 0 1 3.6 3.3c3.7 5.5 2.6 13.2-1.3 18.7s-9.8 8.9-15.8 11.7c-12.9 5.9-27.3 9.1-41.2 6.8-7.9-1.3-15.8-4.4-23.8-3.1', 'M313.8 339.8c-2.7-8.2-3.4-16.8-0.7-25s8.7-15.3 16.7-18.7A17.7 17.7 0 0 1 340 294.8a10.5 10.5 0 0 1 7.8 6.1c3.4-3.8 8.4-6.4 13.5-6.2s10.2 3.5 11.6 8.4A20.5 20.5 0 0 1 385.8 299.8c4.5 0.5 8.9 3.1 10.9 7.2 2.7 5.4 1 11.8-1.2 17.4a16.7 16.7 0 0 1-3.7 6.2A12.8 12.8 0 0 1 385.8 333.4c-7.1 1.6-14.5-0.5-21.1-3.5s-12.9-6.9-19.8-9-15-2.3-21 1.9S314.7 337.9 313.8 339.8', 'M318.3 326.3a40.6 40.6 0 0 1-6.6-16.5c-1.1-6.5-0.2-14.2 5-18.4 3-2.4 7.1-3.2 11-3 7.8 0.4 15.9 5.4 17.4 13 3.8-8.7 15.8-12.7 24.1-7.8s10.8 17.1 5.2 24.7a15.4 15.4 0 0 1 14.6 21.8 9.6 9.6 0 0 1-4.8 5.1c-3.3 1.3-7.1-0.1-9.9-2.3s-4.8-5.2-7.3-7.8c-6-6.1-14.6-9.1-23.1-10s-17.2 0.1-25.6 1.1', 'M313.4 335.1a0.3 0.3 0 0 1-0.3-0.1c-3.1-5.3-3.1-11.8-2.4-17.9a39.3 39.3 0 0 1 3.6-13.6c3.6-7.1 10.5-12.2 18-15 6.6-2.5 13.6-3.4 20.6-3.8a0.9 0.9 0 0 1 0.7 1.6 31.2 31.2 0 0 0-6.4 7.1 0.9 0.9 0 0 0 1.2 1.4 75.6 75.6 0 0 1 24.4-7.4 0.9 0.9 0 0 1 0.8 1.5 46.7 46.7 0 0 0-5.1 7.3 0.9 0.9 0 0 0 1.2 1.2 63.6 63.6 0 0 1 20.7-5.8 0.9 0.9 0 0 1 0.7 1.5 45 45 0 0 0-5.7 7.4 0.9 0.9 0 0 0 1 1.4c9.9-2 18.7-7.5 27.2-13.1a0.9 0.9 0 0 1 1.5 0.7c0.2 4.2-1.6 8.4-3.3 12.3-2.9 6.6-5.9 13.4-10.8 18.8-8.9 10.2-22.7 14.4-36 17h0Z', 'M317.4 336.3a25.3 25.3 0 1 1 19.3-45.3c5.2-10.8 17.9-17.1 29.8-15.7s22.4 10.2 26.7 21.3 2.6 24.3-3.7 34.5c-5.3 8.6-15.9 15.5-25.2 11.6C365.1 330.8 355 319.1 343 318S318.6 324.2 317.4 336.2', 'M317.3 337.2a0.3 0.3 0 0 1-0.2-0.1c-4.2-4.5-5.8-10.8-6.5-16.9-0.5-4.7-0.7-9.5 0.4-14 1.9-7.8 7.5-14.3 14.2-18.7 5.8-3.9 12.5-6.4 19.2-8.3a0.9 0.9 0 0 1 1 1.4 31 31 0 0 0-4.6 8.4 0.9 0.9 0 0 0 1.4 1 75.9 75.9 0 0 1 22.1-12.7 0.9 0.9 0 0 1 1.2 1.3 45.9 45.9 0 0 0-3.3 8.2 0.9 0.9 0 0 0 1.4 0.9 63.4 63.4 0 0 1 18.8-10.4 0.9 0.9 0 0 1 1.1 1.3 45.3 45.3 0 0 0-3.9 8.6 0.9 0.9 0 0 0 1.3 1.1c9.1-4.2 16.5-11.6 23.6-18.9a0.9 0.9 0 0 1 1.5 0.3c1.1 4 0.4 8.5-0.4 12.7-1.4 7.1-2.7 14.4-6.2 20.8-6.4 11.9-18.9 19.2-31.2 24.7l0 0Z', 'M367.8 334.4c4.3-7.1 6.9-12.9 8.8-21 2.4-10.4 2.4-22.2-4.3-30.5a32.3 32.3 0 0 0-10.8-8.3c-14.9-7.5-34.7-7-46.6 4.7a2 2 0 0 0-0.7 1.2c0 0.7 0.7 1.3 1.3 1.6L334.5 293.3c-8.6-2-17.8 2.5-23.6 9.3s-8.7 15.4-11 23.9c3.5-3 8.6-3.3 13.1-2.2s8.6 3.1 13 4.4C340.6 332.8 355.2 326.1 367.8 334.4', 'M314.2 333.5c-16.2-11.2-25.4-33.5-18.9-51.9a1.2 1.2 0 0 1 1.9-0.6 133.1 133.1 0 0 0 22.6 14.6 1.2 1.2 0 0 0 1.8-1.4c-3.2-19.9 8.3-41.4 26.7-49.6a1.2 1.2 0 0 1 1.7 1.4 85.2 85.2 0 0 0 2.4 42.7 1.2 1.2 0 0 0 1.8 0.7 74.4 74.4 0 0 1 64.6-3.4 1.2 1.2 0 0 1-0.3 2.3c-16.7 3-34.4 7.7-43.9 21.2a1.2 1.2 0 0 0 0.9 2 70.5 70.5 0 0 1 48 33.6A1.2 1.2 0 0 1 422.5 346.9c-18.6 1-44.8 0.4-63.1 1.5a1.2 1.2 0 0 1-1.3-1c-2.1-10.4-1.8-17.5-12.1-20.9-10.7-3.5-23.4-0.5-31.8 7', 'M314.8 330.5c14.9 4.3 27 2.7 42.3 0.4a242.8 242.8 0 0 0 51.1-13.7c12.1-4.7 24.8-11.4 29.9-23.4a27.3 27.3 0 0 0-39-34.3c1.8-5.6-2-12-7.4-14.2s-11.8-0.9-16.8 2.2-8.6 7.9-11.8 13A97.2 97.2 0 0 0 350.7 290.5c3.3-7.9-4.5-17.3-13.1-17.5s-16.2 6.3-19.8 14c-3.6-9.4-17.8-11.1-25.2-4.2s-7.6 19-2.7 27.8 15.7 16.2 25 19.9Z'], ['M306.7 297.5a77.5 77.5 0 0 0 5.8-29.7c0-3.9-0.1-8.5 3-10.9 3.8-2.9 9.7-0.1 11.7 4.2s1.1 9.4 0.2 14.1L342 247.3a14.4 14.4 0 0 1 3.3-4.6c4.4-3.7 11.6-0.7 14.3 4.4s2 11.2 1 16.8q-1.2 7.1-2.7 14.2l22.3-18.3c4.8-4 10.3-8.2 16.6-7.8a10.9 10.9 0 0 1 4 1.1 11.6 11.6 0 0 1 4.3 3.9c4.5 6.6 3.1 15.9-1.5 22.4s-11.7 10.7-19 14c-15.4 7.1-32.7 11-49.4 8.2-9.5-1.6-19-5.3-28.6-3.7', 'M301.6 313.2c-3.2-9.8-4.1-20.2-0.8-29.9s10.5-18.4 19.9-22.4A21.3 21.3 0 0 1 333 259.2a12.6 12.6 0 0 1 9.4 7.4c4.1-4.5 10-7.7 16.2-7.5s12.2 4.2 13.9 10.2A24.6 24.6 0 0 1 388 265.2c5.4 0.6 10.7 3.7 13.1 8.7 3.2 6.5 1.2 14.2-1.5 20.9a20.1 20.1 0 0 1-4.5 7.4A15.3 15.3 0 0 1 388 305.6c-8.5 2-17.4-0.6-25.4-4.2s-15.4-8.3-23.8-10.9-18-2.7-25.1 2.4S302.6 311 301.6 313.2', 'M307 297a48.7 48.7 0 0 1-7.9-19.8c-1.3-7.9-0.3-17 5.9-22 3.7-2.9 8.5-3.9 13.2-3.6 9.4 0.4 19.1 6.5 21 15.6 4.6-10.5 19-15.2 28.8-9.4s13 20.5 6.3 29.7a18.5 18.5 0 0 1 17.5 26.2 11.5 11.5 0 0 1-5.8 6.1c-4 1.6-8.6-0.1-11.8-2.8s-5.7-6.3-8.8-9.3c-7.2-7.3-17.5-11-27.7-12.1s-20.6 0.1-30.8 1.4', 'M301.1 307.7a0.4 0.4 0 0 1-0.3-0.2c-3.7-6.4-3.8-14.2-3-21.5a47.1 47.1 0 0 1 4.3-16.3c4.4-8.6 12.7-14.6 21.7-18 7.9-3 16.3-4.1 24.7-4.5a1.1 1.1 0 0 1 0.8 1.9 37.5 37.5 0 0 0-7.7 8.5 1.1 1.1 0 0 0 1.4 1.6 90.7 90.7 0 0 1 29.3-8.8 1.1 1.1 0 0 1 1 1.8 56 56 0 0 0-6.1 8.7 1.1 1.1 0 0 0 1.4 1.5 76.3 76.3 0 0 1 24.8-7 1.1 1.1 0 0 1 1 1.8 54 54 0 0 0-6.9 8.9 1.1 1.1 0 0 0 1.2 1.7c11.9-2.5 22.5-9 32.7-15.7a1.1 1.1 0 0 1 1.7 0.9c0.2 5-1.9 10-4 14.7-3.5 7.9-7.1 16-12.9 22.5-10.7 12.2-27.2 17.3-43.2 20.5h0Z', 'M305.9 309.1a30.3 30.3 0 1 1 23.2-54.4c6.3-13 21.5-20.5 35.7-18.9s26.8 12.2 32 25.7 3.2 29.2-4.4 41.3c-6.4 10.3-19.1 18.6-30.3 14C363.1 302.4 351 288.4 336.6 287.1S307.3 294.5 305.9 308.9', 'M305.8 310.2a0.3 0.3 0 0 1-0.3-0.1c-5-5.4-6.9-13-7.8-20.3-0.7-5.6-0.9-11.4 0.5-16.8 2.3-9.3 9-17.1 17-22.5 7-4.7 15-7.6 23.1-10a1.1 1.1 0 0 1 1.2 1.7 37.1 37.1 0 0 0-5.6 10.1 1.1 1.1 0 0 0 1.8 1.2 91.1 91.1 0 0 1 26.5-15.3 1.1 1.1 0 0 1 1.4 1.6 55.1 55.1 0 0 0-4 9.9 1.1 1.1 0 0 0 1.7 1.1 76.1 76.1 0 0 1 22.6-12.5 1.1 1.1 0 0 1 1.3 1.6 54.3 54.3 0 0 0-4.6 10.2 1.1 1.1 0 0 0 1.5 1.3c11-5.1 19.8-13.9 28.3-22.6a1.1 1.1 0 0 1 1.8 0.4c1.4 4.9 0.4 10.2-0.5 15.2-1.6 8.5-3.2 17.3-7.4 24.9-7.7 14.3-22.6 23-37.4 29.7l-0.1 0Z', 'M366.4 306.7c5.1-8.5 8.3-15.5 10.5-25.2 2.9-12.4 2.8-26.7-5.2-36.6a38.7 38.7 0 0 0-12.9-9.9c-17.9-9-41.6-8.4-55.9 5.7a2.4 2.4 0 0 0-0.9 1.4c0 0.9 0.8 1.5 1.6 2L326.4 257.5c-10.4-2.4-21.4 3-28.3 11.1s-10.5 18.5-13.2 28.7c4.1-3.6 10.3-3.9 15.7-2.7s10.4 3.8 15.6 5.3C333.7 304.9 351.2 296.8 366.4 306.7', 'M302 305.8c-19.4-13.4-30.4-40.2-22.7-62.4a1.5 1.5 0 0 1 2.4-0.7 159.7 159.7 0 0 0 27.1 17.5 1.5 1.5 0 0 0 2.2-1.6c-3.9-23.9 9.9-49.7 31.9-59.6a1.5 1.5 0 0 1 2.1 1.6 102.2 102.2 0 0 0 2.8 51.4 1.5 1.5 0 0 0 2.2 0.8 89.3 89.3 0 0 1 77.6-4.1 1.5 1.5 0 0 1-0.3 2.8c-20 3.6-41.3 9.3-52.7 25.5a1.5 1.5 0 0 0 1 2.3 84.6 84.6 0 0 1 57.6 40.3A1.5 1.5 0 0 1 432 321.8c-22.3 1.2-53.8 0.5-75.7 1.8a1.5 1.5 0 0 1-1.5-1.2c-2.5-12.5-2.2-21-14.7-25.1-12.8-4.1-28.1-0.6-38.1 8.5', 'M302.8 302.1c17.9 5.2 32.4 3.2 50.7 0.5a291.4 291.4 0 0 0 61.3-16.5c14.5-5.7 29.8-13.7 35.9-28a32.8 32.8 0 0 0-46.8-41.2c2.1-6.7-2.4-14.4-8.9-17s-14.2-1.1-20.2 2.6-10.4 9.5-14 15.6A116.6 116.6 0 0 0 345.8 254.1c4-9.5-5.5-20.7-15.7-21s-19.4 7.6-23.8 16.9c-4.3-11.2-21.4-13.3-30.1-5.1s-9.1 22.8-3.3 33.3 18.8 19.4 29.9 23.9Z']]
        ];

        return abi.encodePacked(
            '<path style="',
            _style,
            '" d="',
            p[0][uint256(_commonData.size)][_chickenInData.comb - 1],
            '"/>'
        );
    }
}

contract ChickenInCheek {
    function getSVGCheek(CommonData calldata _commonData, ChickenInData calldata _chickenInData) external pure returns (bytes memory) {
        string[4][1] memory p = [
            ['cx="351.5" cy="404.7" rx="10" ry="7"', 'cx="343.7" cy="382.1" rx="13.3" ry="9.4"', 'cx="335.9" cy="359.6" rx="16.7" ry="11.7"', 'cx="328" cy="337" rx="20" ry="14"']
        ];

        return abi.encodePacked(
            '<ellipse style="',
            _chickenInData.cheekStyle,
            '" ',
            p[0][uint256(_commonData.size)],
            '/>'
        );
    }
}

contract ChickenInTail {
    function getSVGTailPath(CommonData calldata _commonData, ChickenInData calldata _chickenInData, bytes calldata _style) external pure returns (bytes memory) {
        string[9][4][1] memory p = [
            [['M400.9 484.6c-3.5-3.8-5.2-6.5-6.7-11.4s-0.7-11 3.5-14a12.4 12.4 0 0 1 6.3-2.1c2.2-0.2 4.6 0.1 6.5 1.4s3 3.7 2.3 5.8c1.5-4.3 3.2-8.7 6.3-12.1s7.7-5.7 12.2-4.8 8.2 5.6 7 10c3.8-3.1 8.3-5.5 13.2-5.9s10.1 1.8 12.6 6 1.2 10.5-3.1 12.8c6.6-0.8 13.3 4.9 13.5 11.6S468.5 494.7 461.8 494.4c2.3 2.7 4.2 5.9 4.5 9.3s-1 7.3-3.9 9.2-7.5 1.3-9.3-1.7c-1.1 5.6-3.8 11.3-8.9 13.7C439.3 527.2 433.2 525.7 428.7 522.5s-7.6-7.9-10.6-12.5c-5.7-8.6-11.4-16.8-17.2-25.3', 'M365.8 474.4c10.5 4.2 40.5-8.5 50.1-14.7a36.2 36.2 0 0 0 16.1-28.1 0.6 0.6 0 0 1 0.4-0.5c1.8-0.6 3.7 2 3.8 3.9a6 6 0 0 0 0.5 2.5c2.2 4.4 6.2 1.3 6.5-1.7 0.2-2.3-0.9-4.5-1.6-6.7S440.9 423.1 442.7 422.7c3.4-0.3 5.9 3.1 7.7 6.1 10.2 17.9 16.5 39.8 9.1 59-7.6 20.2-30.7 33.3-51.9 29.4-4.4-0.8-8.8-2.3-12.3-5.1C390.4 508.1 379.3 500.9 375.5 494.9c-6.6-10.4-9.2-9.7-9.7-20.5', 'M428.2 449C413.3 455.5 404.6 463.1 401.7 478.2s10.1 27.7 17.1 33.2S436 513.3 440.3 506.8s6.7-10.6 6.8-10.6 8 2 13-5a13.6 13.6 0 0 0 1.3-14s5.2 5.8 11.5 3.1 4.5-11 4.5-11 5.9 8.2 11 5.6c3.2-1.6 3.8-10.8-1.6-17.6S469.3 443.7 457.1 443.6C441.7 443.5 428.2 449 428.2 449Z', 'M381.9 482.4a138.1 138.1 0 0 0 76.3-55.2 0.5 0.5 0 0 1 1 0.4 69.8 69.8 0 0 1-18 33.9 0.5 0.5 0 0 0 0.4 0.9A107 107 0 0 0 484.1 453.9a0.5 0.5 0 0 1 0.6 0.9 86.3 86.3 0 0 1-30.8 20.2 0.5 0.5 0 0 0-0.1 0.9 59.9 59.9 0 0 0 28.8 15.1 0.5 0.5 0 0 1 0.1 1.1c-9.3 2.6-21.7 4.9-30.8 3a0.5 0.5 0 0 0-0.7 0.7c0.8 3.9 4.1 6.8 7.2 9.7a0.5 0.5 0 0 1-0.4 0.9C430.6 504.6 406 496.2 382 482.5', 'M376.8 488.5a54.4 54.4 0 0 1 70.7-41.4c11.9 4 22.7 12.7 27.4 24.3 2.5 6.3 3.2 13.1 3.4 19.8 0.4 19.2-5.4 41-22.6 49.5 1.6-10.5-0.2-22-7-30.3s-18.8-12.5-28.7-8.2c-2.2 0.9-4.3 2.3-6.6 2.8-4.2 0.9-8.6-0.9-12.5-2.9-9.7-4.9-15.2-7-24-13.4', 'M394.1 483.3c4.5-25.6 26.3-47.2 51.9-51.5 2.4-0.4 5.9 0.2 5.7 2.7a3.7 3.7 0 0 1-1.2 2.2c-6.5 6.9-19.2 7.5-22.5 16.3 15.5-8.5 32.8-17.2 50.1-13.5 2 0.4 4 1.1 5.5 2.5s2.1 3.9 0.9 5.5c-0.8 1.1-2.2 1.7-3.5 2-6.2 1.5-12.7-0.6-19.2-0.2a25.7 25.7 0 0 0-17 7.9c6.6-0.2 14.3 0.2 18 5.6a10.1 10.1 0 0 1-1.6 12.6c-0.9 0.8-2 1.6-2.2 2.8-0.3 1.4 0.9 2.7 1.8 3.8 3 3.6 4.4 8.7 2.8 13.2s-6.5 7.7-11 6.5c1.9 5.9-1.7 12.7-7.1 15.5s-12.3 2.4-18 0-10.4-6.7-14.8-11.2C405.1 498.1 399.6 492.8 394.2 483.3', 'M400.7 497.1C395 490.6 393.5 481.3 393.9 472.6c0.3-6.7 1.6-13.5 4.8-19.4 4.3-8 11.8-14 20-18.1a68.1 68.1 0 0 1 35.4-6.9 0.4 0.4 0 0 1 0.3 0.7c-1.8 2-4.9 2.5-7.6 3.4a20.1 20.1 0 0 0-11.1 8.9 0.4 0.4 0 0 0 0.4 0.7c7.5-1.5 15.2-2.7 22.8-2.1 7.9 0.6 15.9 3.4 21.6 9a14.4 14.4 0 0 1 3.8 5.7 0.4 0.4 0 0 1-0.4 0.6l-12.4-0.8c-5.1-0.3-10.5-0.5-14.9 1.8a0.4 0.4 0 0 0 0.1 0.8c7.5 2 15 4.4 21.2 9s11.1 11.5 11.5 19.1a1.6 1.6 0 0 1-1.2 1.7 6.1 6.1 0 0 1-4.6-1.1c-1.7-1.2-3-2.9-4.5-4.3a19.3 19.3 0 0 0-12.1-5.5 0.4 0.4 0 0 0-0.4 0.7 35.4 35.4 0 0 1 7.1 28.3 0.4 0.4 0 0 1-0.9 0.1c-2.1-6.1-4.7-12.5-10.3-15.6-0.9-0.5-2-0.8-2.9-0.3a3.2 3.2 0 0 0-1.2 1.7c-3.1 7.5-2.6 17.6 4.2 22 2 1.3 4.6 2.2 5.7 4.1a0.9 0.9 0 0 1-0.5 1.3l-9.8 2.6a3.6 3.6 0 0 0-1.7 1c-1.8 2 0.2 4.5 1.4 6.6 2.6 4.2 2.2 10-0.8 13.8a1 1 0 0 1-1.5 0c-1.5-2.3-2.4-4.9-3.6-7.3-4.8-10.1-13.3-18.1-22.7-24s-18-9.5-28.5-13.5', 'M394.3 481.7c11.9-38.3 48.9-67.3 88.9-69.8 4.7-0.3 9.9-0.1 13.3 3.2 5.4 5.3 2 15.2-4.5 19s-14.5 3.3-22 2.7a43.8 43.8 0 0 1 32.1 12.9c3.4 3.5 6.4 7.8 7.1 12.6s-1.4 10.3-5.8 12.5c-8.2 4.2-17.2-4.6-26.4-5 4.5 5.7 9.1 11.8 9.9 19s-3.6 15.6-10.8 16.1c-5.7 0.4-10.5-3.9-14.6-7.8 1.3 5.8 2.5 11.9 1.6 17.8s-4.3 11.8-9.9 13.9c-6.7 2.5-14.2-1.1-19.8-5.7-15.2-12.6-22.7-30.6-39.2-41.4', 'M391.7 481.9c2.6-4.7 5.4-9.6 10.1-12.2 3.4-1.9 7.4-2.4 11.3-3.4 6.8-1.7 13.5-5.3 16.6-11.5 2-4 2.4-8.9 4.9-12.7 3.2-4.8 9.5-6.9 15.3-6.3-1.2 2-3.1 3.5-4.7 5.2a22.6 22.6 0 0 0-5.7 10.2c-1 4.2-0.2 9.6 3.8 11.4 2.1 0.9 4.5 0.5 6.5-0.6s3.7-2.6 5.4-4.1c2.7-2.5 5.4-5.2 7-8.6 2.1-4.4 1.9-9.6 2-14.4s1-10.2 4.4-13.7A11.3 11.3 0 0 1 480.8 418.9c-0.1 1.8-1.8 2.9-3 4.1-4.7 4.3-5.3 11.4-5 17.8s1 13.2-2.1 18.8c-3.8 6.9-12.8 10.4-15.2 17.9a6.4 6.4 0 0 0-0.1 4.2c0.7 1.9 2.7 3.1 4.6 3.7 4.6 1.5 10.5 0.3 12.6-4 1.3-2.7 0.9-5.8 1.1-8.7s1.5-6.3 4.4-7.1a1.3 1.3 0 0 1 0.8 0c0.7 0.3 0.5 1.3 0.4 2.1-1.1 4.4 1.1 8.9 1.7 13.4 1.2 8.8-4.4 18-12.8 21.2-2.7 1-5.6 1.4-8.2 2.4-5 1.8-9 5.6-13.8 7.8-5.4 2.5-11.7 3-17.6 2.1s-11.6-2.9-17.1-5.3c-4.7-2-9.4-4.4-12.8-8.2-5-5.7-6.1-12-7.1-19.5'], ['M409.6 488.7c-4.6-5.1-6.9-8.6-9-15.2s-0.9-14.7 4.6-18.8a16.5 16.5 0 0 1 8.5-2.8c3-0.2 6.2 0.2 8.7 1.9s4 5 3 7.8c2-5.8 4.3-11.6 8.4-16.1s10.3-7.6 16.3-6.5 11 7.5 9.3 13.3c5-4.1 11.1-7.4 17.7-7.8s13.5 2.4 16.7 8.1 1.6 14-4.1 17c8.8-1.1 17.7 6.6 18 15.5S499.6 502.1 490.7 501.7c3.1 3.5 5.5 7.8 6.1 12.4s-1.3 9.7-5.3 12.3-10 1.7-12.4-2.3c-1.4 7.4-5 15.1-11.8 18.3C460.7 545.5 452.6 543.4 446.6 539.1s-10.1-10.5-14.1-16.6c-7.7-11.5-15.3-22.4-22.9-33.8', 'M362.8 475c14 5.6 54-11.3 66.7-19.5a48.3 48.3 0 0 0 21.5-37.5 0.8 0.8 0 0 1 0.5-0.7c2.4-0.8 5 2.6 5.1 5.2a8 8 0 0 0 0.7 3.4c3 5.8 8.3 1.8 8.6-2.3 0.3-3.1-1.2-6-2.1-8.9S462.8 406.6 465.3 406.1c4.6-0.3 7.9 4.1 10.2 8.1 13.6 23.9 21.9 53.1 12.2 78.8-10.2 26.9-40.9 44.3-69.2 39.1-5.9-1.1-11.7-3.1-16.4-6.8C395.6 520 380.8 510.3 375.7 502.4c-8.8-13.9-12.2-13-12.9-27.4', 'M445.9 441.1C426.1 449.8 414.5 459.9 410.6 480.1s13.4 36.9 22.7 44.3S456.4 526.9 462.1 518.2s9-14.1 9-14.1 10.7 2.7 17.4-6.7a18.1 18.1 0 0 0 1.6-18.6s6.9 7.7 15.4 4.1 6-14.7 6-14.7 7.9 10.9 14.7 7.5c4.3-2.2 5-14.4-2.1-23.4S500.7 434.1 484.4 434C463.9 433.8 445.9 441.1 445.9 441.1Z', 'M384.3 485.7a184.1 184.1 0 0 0 101.6-73.6 0.7 0.7 0 0 1 1.4 0.6 93 93 0 0 1-24 45.1 0.7 0.7 0 0 0 0.5 1.3A142.6 142.6 0 0 0 520.5 447.7a0.7 0.7 0 0 1 0.8 1.2 115 115 0 0 1-41 27 0.7 0.7 0 0 0-0.3 1.2 79.9 79.9 0 0 0 38.5 20.1 0.7 0.7 0 0 1 0.1 1.4c-12.4 3.4-28.9 6.5-41.1 4.1a0.7 0.7 0 0 0-0.9 0.8c1.1 5.2 5.5 9.1 9.6 13a0.7 0.7 0 0 1-0.5 1.3C449.1 515.3 416.3 504.2 384.4 485.8', 'M377.4 493.8a72.5 72.5 0 0 1 94.3-55.2c15.9 5.3 30.2 16.9 36.5 32.5 3.3 8.3 4.3 17.4 4.5 26.4 0.6 25.6-7.2 54.7-30.1 66 2.2-14.1-0.3-29.4-9.4-40.4s-25.1-16.6-38.2-11c-2.9 1.3-5.7 3-8.8 3.7-5.7 1.2-11.4-1.2-16.6-3.9-13-6.5-20.3-9.3-32.1-17.8', 'M400.4 487c6-34.1 35-63 69.2-68.8 3.2-0.5 7.9 0.3 7.7 3.6a5 5 0 0 1-1.6 2.9c-8.6 9.2-25.6 10-30 21.8 20.7-11.3 43.7-22.9 66.7-18 2.7 0.6 5.4 1.4 7.4 3.3s2.8 5.2 1.2 7.4c-1.1 1.5-2.9 2.2-4.7 2.6-8.3 2-17-0.8-25.5-0.2a34.3 34.3 0 0 0-22.7 10.5c8.7-0.3 19.1 0.2 24 7.4a13.4 13.4 0 0 1-2.1 16.9c-1.2 1.1-2.7 2.1-3 3.7-0.4 1.9 1.2 3.6 2.4 5.1 3.9 4.8 5.9 11.6 3.8 17.5s-8.6 10.2-14.7 8.7c2.5 7.9-2.2 16.9-9.5 20.8s-16.4 3.2-24-0.1-13.9-8.9-19.7-14.9C415.1 506.7 407.8 499.6 400.6 486.9', 'M409.3 505.4C401.6 496.6 399.7 484.2 400.2 472.6c0.4-8.9 2.2-18 6.4-25.9 5.8-10.7 15.8-18.6 26.7-24.1a90.8 90.8 0 0 1 47.1-9.1 0.6 0.6 0 0 1 0.4 0.9c-2.4 2.7-6.5 3.3-10.1 4.5a26.8 26.8 0 0 0-14.8 11.9 0.6 0.6 0 0 0 0.6 0.8c10-2 20.2-3.5 30.4-2.6 10.6 0.9 21.2 4.5 28.8 11.9a19.2 19.2 0 0 1 5.1 7.6 0.6 0.6 0 0 1-0.6 0.7l-16.6-1c-6.8-0.4-14-0.7-19.8 2.5a0.6 0.6 0 0 0 0.1 1c10 2.6 20 5.9 28.3 12s14.8 15.3 15.4 25.5a2.2 2.2 0 0 1-1.7 2.3 8.2 8.2 0 0 1-6.1-1.5c-2.3-1.6-4-3.9-5.9-5.8a25.7 25.7 0 0 0-16.2-7.3 0.6 0.6 0 0 0-0.5 0.9 47.3 47.3 0 0 1 9.3 37.8 0.6 0.6 0 0 1-1 0c-2.7-8.2-6.3-16.7-13.8-20.7-1.2-0.6-2.6-1.1-3.8-0.4a4.3 4.3 0 0 0-1.7 2.2c-4.2 10-3.5 23.5 5.7 29.3 2.6 1.7 6.1 3 7.5 5.6a1.2 1.2 0 0 1-0.7 1.7l-13.1 3.5a4.7 4.7 0 0 0-2.2 1.3c-2.4 2.6 0.2 6 1.9 8.7 3.5 5.6 3 13.4-1.1 18.6a1.3 1.3 0 0 1-2-0.1c-2-3-3.2-6.5-4.8-9.7-6.3-13.5-17.7-24.1-30.3-32s-24-12.6-37.9-18', 'M400.7 484.8c15.9-51 65.2-89.8 118.5-93.1 6.3-0.4 13.3-0.1 17.7 4.3 7.2 7 2.7 20.2-5.9 25.3s-19.3 4.4-29.3 3.6a58.4 58.4 0 0 1 42.8 17.1c4.6 4.6 8.5 10.3 9.4 16.8s-1.8 13.7-7.7 16.7c-11 5.6-23-6.1-35.2-6.6 5.9 7.6 12.1 15.8 13.2 25.4s-4.8 20.8-14.4 21.5c-7.6 0.6-14-5.1-19.5-10.5 1.7 7.8 3.4 15.8 2.2 23.7s-5.8 15.8-13.2 18.6c-9 3.3-19-1.5-26.4-7.7-20.3-16.8-30.2-40.8-52.4-55.1', 'M397.3 485c3.5-6.3 7.3-12.8 13.5-16.3 4.6-2.6 9.9-3.2 14.9-4.5 9-2.2 18-7.1 22.2-15.4 2.7-5.4 3.2-11.8 6.6-16.8 4.3-6.4 12.7-9.2 20.4-8.4-1.6 2.7-4.2 4.6-6.4 6.9a30.1 30.1 0 0 0-7.5 13.7c-1.4 5.6-0.3 12.8 5 15.1 2.8 1.2 6.1 0.7 8.8-0.7s4.9-3.5 7.1-5.6c3.6-3.4 7.2-6.9 9.3-11.4 2.8-5.9 2.5-12.8 2.7-19.3s1.3-13.6 6-18.2A15.1 15.1 0 0 1 516.1 401.1c-0.1 2.3-2.4 3.9-4.1 5.4-6.3 5.7-7.1 15.2-6.7 23.8s1.4 17.6-2.7 24.9c-5.1 9.2-17.1 13.9-20.3 24a8.5 8.5 0 0 0-0.1 5.5c1 2.6 3.6 4.1 6.2 5 6.1 1.9 14 0.4 16.8-5.3 1.7-3.5 1.2-7.7 1.4-11.7s2-8.4 5.9-9.4a1.7 1.7 0 0 1 1.1 0c1 0.4 0.7 1.8 0.5 2.9-1.4 5.9 1.4 11.9 2.2 17.8 1.5 11.7-5.9 24-17 28.2-3.6 1.3-7.4 1.9-11 3.2-6.6 2.5-12 7.4-18.4 10.4-7.2 3.4-15.5 4-23.4 2.9s-15.5-3.9-22.8-7.1c-6.2-2.7-12.5-5.8-17-11-6.6-7.6-8.1-16-9.5-25.9'], ['M418.2 492.8c-5.8-6.4-8.6-10.8-11.3-19.1s-1.2-18.4 5.9-23.4a20.6 20.6 0 0 1 10.6-3.5c3.7-0.3 7.7 0.2 10.8 2.3s5 6.2 3.9 9.8c2.5-7.2 5.4-14.5 10.5-20.2s12.8-9.5 20.3-8.1 13.7 9.3 11.6 16.7c6.3-5.2 13.9-9.2 22.1-9.8s16.9 3 20.9 10.1 2 17.5-5.2 21.3c11-1.3 22.2 8.2 22.5 19.3S530.8 509.6 519.7 508.9c3.8 4.4 6.9 9.8 7.5 15.6s-1.6 12.2-6.5 15.4-12.5 2.1-15.5-2.9c-1.8 9.3-6.3 18.9-14.9 22.8C482.1 563.7 471.9 561.1 464.6 555.8s-12.6-13.1-17.7-20.7c-9.6-14.3-19.1-28-28.7-42.3', 'M359.7 475.7c17.5 7 67.6-14.2 83.4-24.5a60.4 60.4 0 0 0 26.9-46.8 1 1 0 0 1 0.7-0.9c3-1 6.2 3.3 6.3 6.5a10.1 10.1 0 0 0 0.9 4.2c3.7 7.3 10.4 2.2 10.8-2.8 0.3-3.8-1.5-7.5-2.7-11.2S484.8 390.2 487.9 389.5c5.7-0.4 9.9 5.1 12.7 10.1 17 29.8 27.4 66.3 15.3 98.5-12.7 33.7-51.2 55.4-86.6 48.9-7.3-1.3-14.6-3.8-20.4-8.5C400.7 531.8 382.2 519.8 375.9 509.9c-11.1-17.4-15.3-16.2-16.2-34.2', 'M463.7 433.3C438.9 444.2 424.3 456.8 419.5 481.9s16.8 46.1 28.4 55.5S476.7 540.5 483.9 529.7s11.2-17.6 11.2-17.7 13.4 3.3 21.8-8.4a22.7 22.7 0 0 0 2-23.3s8.6 9.6 19.2 5.2 7.5-18.4 7.5-18.4 9.9 13.7 18.4 9.5c5.4-2.7 6.3-18-2.6-29.4S532.1 424.5 511.8 424.4C486.2 424.1 463.7 433.3 463.7 433.3Z', 'M386.6 489a230.1 230.1 0 0 0 127.1-92 0.9 0.9 0 0 1 1.6 0.7 116.3 116.3 0 0 1-29.9 56.4 0.9 0.9 0 0 0 0.6 1.6A178.3 178.3 0 0 0 556.9 441.4a0.9 0.9 0 0 1 1 1.5 143.8 143.8 0 0 1-51.3 33.8 0.9 0.9 0 0 0-0.3 1.5 99.8 99.8 0 0 0 48.1 25.2 0.9 0.9 0 0 1 0.1 1.8c-15.5 4.3-36.1 8.2-51.3 5a0.9 0.9 0 0 0-1.2 1.1c1.4 6.6 6.8 11.3 12 16.2a0.9 0.9 0 0 1-0.7 1.6C467.6 526 426.6 512.1 386.7 489.2', 'M378.1 499.1a90.7 90.7 0 0 1 117.8-68.9c19.9 6.7 37.8 21.1 45.6 40.5 4.2 10.4 5.4 21.8 5.6 33 0.7 31.9-9 68.3-37.7 82.5 2.7-17.6-0.4-36.7-11.6-50.5s-31.4-20.8-47.8-13.7c-3.7 1.6-7.1 3.8-11 4.6-7.1 1.6-14.3-1.6-20.8-4.8-16.2-8.1-25.4-11.6-40.1-22.3', 'M406.8 490.6c7.5-42.7 43.8-78.7 86.5-85.9 4-0.7 9.8 0.4 9.6 4.4a6.2 6.2 0 0 1-2 3.7c-10.8 11.5-32 12.5-37.5 27.2 25.9-14.1 54.6-28.6 83.4-22.5 3.3 0.7 6.7 1.8 9.2 4.1s3.4 6.5 1.4 9.3c-1.3 1.9-3.6 2.8-5.8 3.3-10.4 2.4-21.2-1-31.9-0.4a42.9 42.9 0 0 0-28.3 13.1c10.9-0.3 23.8 0.3 29.9 9.4a16.8 16.8 0 0 1-2.6 21.1c-1.5 1.4-3.4 2.6-3.7 4.6-0.5 2.4 1.4 4.5 3 6.4 4.9 6 7.3 14.5 4.7 21.9s-10.8 12.8-18.3 10.8c3.2 9.8-2.8 21.1-11.9 26s-20.5 4-30-0.2-17.4-11.2-24.6-18.5C425.1 515.3 416.1 506.4 406.9 490.5', 'M417.9 513.6C408.3 502.7 405.9 487.1 406.5 472.6c0.5-11.2 2.7-22.5 8-32.3 7.2-13.4 19.7-23.3 33.3-30.1a113.5 113.5 0 0 1 59-11.5 0.7 0.7 0 0 1 0.5 1.2c-3 3.4-8.2 4.2-12.6 5.6a33.5 33.5 0 0 0-18.6 14.9 0.7 0.7 0 0 0 0.7 1c12.5-2.5 25.3-4.4 38-3.3 13.2 1.1 26.5 5.7 36 14.9a24.1 24.1 0 0 1 6.4 9.5 0.7 0.7 0 0 1-0.7 0.9l-20.7-1.2c-8.4-0.5-17.5-0.9-24.8 3a0.7 0.7 0 0 0 0.1 1.3c12.5 3.3 25 7.4 35.5 15s18.5 19.2 19.1 31.9a2.7 2.7 0 0 1-2.1 2.8 10.2 10.2 0 0 1-7.6-1.8c-2.9-2-5-4.8-7.4-7.3a32.1 32.1 0 0 0-20.3-9.1 0.7 0.7 0 0 0-0.6 1.2 59.1 59.1 0 0 1 11.7 47.1 0.7 0.7 0 0 1-1.3 0.1c-3.4-10.2-7.9-20.8-17.3-25.8-1.5-0.8-3.3-1.4-4.7-0.6a5.4 5.4 0 0 0-2.1 2.8c-5.2 12.5-4.3 29.3 7.1 36.6 3.3 2.1 7.6 3.7 9.4 6.9a1.4 1.4 0 0 1-0.9 2.2l-16.3 4.4a5.9 5.9 0 0 0-2.8 1.6c-3 3.3 0.3 7.5 2.4 10.9 4.4 7 3.7 16.7-1.4 23.2a1.6 1.6 0 0 1-2.6-0.1c-2.4-3.8-4-8.1-5.9-12.2-7.9-16.8-22.1-30.1-37.9-40s-30-15.8-47.4-22.5', 'M407.1 487.8c19.8-63.8 81.5-112.2 148.2-116.4 7.8-0.5 16.6-0.1 22.1 5.4 8.9 8.8 3.4 25.3-7.4 31.7s-24.2 5.5-36.7 4.5a73 73 0 0 1 53.6 21.4c5.7 5.8 10.6 12.9 11.7 21s-2.3 17.2-9.6 20.9c-13.7 6.9-28.7-7.7-44.1-8.3 7.4 9.5 15.1 19.7 16.6 31.7s-6 26-18 26.9c-9.5 0.7-17.6-6.4-24.4-13.1 2.1 9.7 4.2 19.8 2.8 29.6s-7.2 19.7-16.6 23.2c-11.2 4.2-23.7-1.9-32.9-9.5-25.4-21-37.8-51-65.5-69', 'M402.8 488.2c4.4-7.8 9.1-16 16.9-20.4 5.7-3.2 12.4-4 18.7-5.6 11.3-2.8 22.5-8.9 27.7-19.3 3.4-6.7 4-14.8 8.2-21 5.4-8 15.9-11.5 25.5-10.6-2 3.3-5.2 5.8-7.9 8.7a37.7 37.7 0 0 0-9.4 17.1c-1.7 7-0.4 16 6.3 18.9 3.5 1.5 7.6 0.8 10.9-0.9s6.2-4.4 9-7c4.5-4.2 9-8.6 11.6-14.2 3.5-7.4 3.1-16 3.4-24.1s1.6-17 7.4-22.8A18.8 18.8 0 0 1 551.4 383.2c-0.1 2.9-2.9 4.8-5.1 6.9-7.9 7.1-8.8 19-8.4 29.6s1.7 21.9-3.4 31.2c-6.4 11.6-21.4 17.3-25.4 30a10.7 10.7 0 0 0-0.2 6.9c1.2 3.2 4.5 5.1 7.8 6.2 7.6 2.4 17.5 0.5 21-6.7 2.2-4.4 1.5-9.6 1.8-14.5s2.5-10.6 7.3-11.7a2.2 2.2 0 0 1 1.4 0c1.2 0.5 0.9 2.2 0.6 3.5-1.8 7.4 1.8 14.8 2.8 22.3 1.9 14.7-7.3 30-21.2 35.2-4.5 1.7-9.3 2.3-13.8 4-8.3 3.1-15 9.3-22.9 13-9 4.2-19.4 5-29.3 3.6s-19.4-4.9-28.5-8.8c-7.8-3.4-15.7-7.3-21.3-13.7-8.3-9.5-10.1-20-11.9-32.5'], ['M426.8 496.8c-6.9-7.7-10.3-13-13.5-22.8s-1.4-22.1 7-28.2a24.8 24.8 0 0 1 12.8-4.2c4.5-0.3 9.2 0.3 12.9 2.9s6 7.4 4.7 11.7c3-8.6 6.5-17.4 12.6-24.2s15.4-11.5 24.3-9.7 16.5 11.2 14 20c7.6-6.2 16.7-11.1 26.5-11.8s20.3 3.6 25.2 12.1 2.4 21-6.3 25.6c13.3-1.6 26.6 9.8 27 23.2S561.9 517 548.6 516.2c4.6 5.3 8.3 11.7 9 18.7s-1.9 14.6-7.8 18.5-15 2.6-18.6-3.5c-2.2 11.1-7.6 22.7-17.8 27.4C503.5 581.9 491.3 578.9 482.5 572.4s-15.1-15.7-21.3-24.8c-11.5-17.2-22.9-33.5-34.4-50.8', 'M356.6 476.3c21 8.4 81.1-17 100.1-29.4a72.4 72.4 0 0 0 32.3-56.1 1.2 1.2 0 0 1 0.8-1.1c3.6-1.3 7.4 4 7.6 7.8a12.1 12.1 0 0 0 1.1 5.1c4.5 8.7 12.4 2.7 12.9-3.4 0.4-4.6-1.8-9-3.1-13.4S506.8 373.7 510.4 372.9c6.9-0.5 11.9 6.1 15.3 12.1 20.4 35.8 32.9 79.6 18.4 118.2-15.2 40.4-61.4 66.5-103.9 58.7-8.8-1.6-17.6-4.6-24.5-10.2C405.8 543.7 383.6 529.2 376.1 517.3c-13.3-20.8-18.4-19.4-19.5-41', 'M481.4 425.4C451.7 438.5 434.2 453.6 428.4 483.8s20.1 55.4 34.1 66.6S497 554 505.7 541.1s13.5-21.2 13.5-21.2 16.1 4 26.1-10.1a27.2 27.2 0 0 0 2.4-27.9s10.4 11.6 23.1 6.2 9-22.1 9-22.1 11.9 16.4 22 11.4c6.5-3.2 7.6-21.6-3.2-35.2S563.5 414.9 539.2 414.7C508.4 414.4 481.4 425.4 481.4 425.4Z', 'M388.9 492.3a276.1 276.1 0 0 0 152.5-110.4 1.1 1.1 0 0 1 2 0.8 139.5 139.5 0 0 1-36 67.8 1.1 1.1 0 0 0 0.8 1.8A214 214 0 0 0 593.2 435.2a1.1 1.1 0 0 1 1.3 1.8 172.5 172.5 0 0 1-61.6 40.5 1.1 1.1 0 0 0-0.4 1.9 119.8 119.8 0 0 0 57.8 30.1 1.1 1.1 0 0 1 0 2.2c-18.6 5.2-43.3 9.8-61.5 6a1.1 1.1 0 0 0-1.3 1.3c1.6 7.9 8.2 13.6 14.3 19.5a1.1 1.1 0 0 1-0.8 1.9C486.2 536.8 436.9 520 389 492.5', 'M378.7 504.4a108.8 108.8 0 0 1 141.4-82.7c23.9 8 45.4 25.3 54.7 48.7 5 12.5 6.5 26.1 6.8 39.6 0.9 38.3-10.8 82-45.3 99 3.2-21.1-0.5-44-13.9-60.6s-37.7-24.9-57.4-16.6c-4.4 1.9-8.5 4.5-13.2 5.6-8.5 1.9-17.2-1.9-24.9-5.8-19.4-9.7-30.5-13.9-48.1-26.7', 'M413.1 494.2c9-51.2 52.6-94.4 103.9-103.1 4.8-0.8 11.8 0.5 11.4 5.3a7.5 7.5 0 0 1-2.3 4.4c-13 13.8-38.4 14.9-45.1 32.7 31.1-16.9 65.5-34.4 100.2-27 4 0.8 8.1 2.1 10.9 4.9s4.1 7.8 1.8 11.1c-1.6 2.3-4.3 3.3-7 4-12.5 2.9-25.5-1.1-38.2-0.4a51.5 51.5 0 0 0-34 15.7c13.1-0.4 28.6 0.3 35.9 11.2a20.1 20.1 0 0 1-3.1 25.3c-1.8 1.6-4.1 3.2-4.5 5.6-0.6 2.9 1.7 5.4 3.6 7.6 5.9 7.3 8.8 17.4 5.7 26.3s-13 15.3-22 13c3.8 11.8-3.3 25.3-14.3 31.2s-24.6 4.8-36-0.2-20.9-13.4-29.6-22.3C435.2 523.8 424.3 513.1 413.3 494.1', 'M426.4 521.8C415 508.7 412 490 412.8 472.6c0.6-13.4 3.2-27 9.6-38.8 8.6-16.1 23.7-28 40-36.1a136.2 136.2 0 0 1 70.7-13.7 0.9 0.9 0 0 1 0.6 1.4c-3.6 4-9.8 5-15.1 6.7a40.2 40.2 0 0 0-22.3 17.9 0.8 0.8 0 0 0 0.9 1.2c15-3 30.3-5.3 45.6-4 15.9 1.3 31.8 6.8 43.2 17.9a28.9 28.9 0 0 1 7.7 11.4 0.9 0.9 0 0 1-0.9 1.1l-24.8-1.5c-10.1-0.6-21-1.1-29.8 3.7a0.8 0.8 0 0 0 0.2 1.5c15 4 30 8.8 42.5 18s22.2 23 22.9 38.2a3.3 3.3 0 0 1-2.5 3.4 12.2 12.2 0 0 1-9.1-2.1c-3.4-2.4-5.9-5.8-8.9-8.7a38.6 38.6 0 0 0-24.3-11 0.8 0.8 0 0 0-0.7 1.4 70.9 70.9 0 0 1 14 56.6 0.8 0.8 0 0 1-1.6 0.1c-4.1-12.3-9.5-25-20.7-31-1.8-1-4-1.7-5.7-0.7a6.5 6.5 0 0 0-2.5 3.4c-6.2 15-5.2 35.2 8.5 43.9 4 2.5 9.1 4.4 11.3 8.3a1.7 1.7 0 0 1-1.1 2.5l-19.6 5.4a7.1 7.1 0 0 0-3.3 1.9c-3.7 3.9 0.3 9 2.9 13.1 5.3 8.4 4.4 20-1.7 27.8a1.9 1.9 0 0 1-3.1-0.1c-2.9-4.5-4.8-9.7-7.1-14.6-9.5-20.2-26.5-36.1-45.5-48s-36-18.9-56.8-27', 'M413.5 490.9c23.8-76.5 97.8-134.6 177.8-139.7 9.4-0.6 19.9-0.1 26.6 6.5 10.7 10.5 4.1 30.3-8.9 38s-29 6.6-44 5.4a87.6 87.6 0 0 1 64.3 25.7c6.9 7 12.7 15.5 14 25.2s-2.8 20.6-11.4 25c-16.4 8.3-34.5-9.2-53-9.9 8.9 11.4 18.1 23.7 20 38s-7.2 31.1-21.8 32.3c-11.4 0.9-21.1-7.7-29.2-15.7 2.5 11.7 5 23.8 3.3 35.5s-8.6 23.7-19.8 27.9c-13.5 5-28.5-2.2-39.6-11.4-30.4-25.2-45.4-61.2-78.5-82.8', 'M408.4 491.3c5.2-9.4 10.9-19.2 20.3-24.5 6.8-3.9 14.8-4.8 22.4-6.7 13.5-3.4 27-10.6 33.3-23.1 4.1-8.1 4.8-17.7 9.8-25.2 6.5-9.6 19.1-13.8 30.6-12.7-2.4 4-6.2 7-9.5 10.4a45.2 45.2 0 0 0-11.3 20.5c-2.1 8.4-0.5 19.2 7.5 22.7 4.2 1.8 9.1 1 13.2-1.1s7.4-5.2 10.7-8.4c5.4-5.1 10.8-10.4 13.9-17 4.2-8.9 3.7-19.1 4.1-29s1.9-20.4 8.9-27.3A22.6 22.6 0 0 1 586.7 365.4c-0.1 3.5-3.5 5.8-6.2 8.2-9.5 8.5-10.6 22.8-10 35.5s2 26.3-4.1 37.5c-7.7 13.9-25.7 20.8-30.5 35.9a12.8 12.8 0 0 0-0.2 8.4c1.5 3.8 5.4 6.1 9.4 7.4 9.1 2.9 21 0.6 25.2-8 2.6-5.3 1.8-11.6 2.1-17.5s3-12.7 8.8-14a2.6 2.6 0 0 1 1.6 0c1.4 0.6 1.1 2.7 0.8 4.2-2.2 8.8 2.2 17.8 3.3 26.8 2.3 17.6-8.8 36.1-25.4 42.2-5.4 2-11.2 2.8-16.6 4.8-9.9 3.7-17.9 11.2-27.5 15.6-10.8 5.1-23.3 6-35.2 4.3s-23.2-5.8-34.2-10.5c-9.4-4.1-18.8-8.8-25.5-16.5-9.9-11.4-12.2-24-14.2-39']]
        ];

        return abi.encodePacked(
            '<path style="',
            _style,
            '" d="',
            p[0][uint256(_commonData.size)][_chickenInData.tail - 1],
            '"/>'
        );
    }
}

contract ChickenInWing1 {
    function getSVGWing1(CommonData calldata _commonData, ChickenInData calldata _chickenInData) external pure returns (bytes memory) {
        string[4][2] memory p = [
            ['M332.8 465.3c-5.8 12.8-3 26.6 2.7 39.8s16.9 23.6 29.6 27.2c3.1 0.9 6.4 1.3 9.3 0.2s5.4-4.2 5.3-7.7c10.9 8.5 25.5 9.5 37.8 4.6s22.3-14.8 30-26.4c4.2-6.4 7.8-14.7 4.8-22.1-2.1-5-6.8-8.2-11.7-9.4s-9.8-0.6-14.7-0.2c-18.7 1.6-38.4 1.1-55.1-9-8.5-5.2-17.4-12.5-26.7-10.1-1.7 0.4-8 3.5-11.3 13.1', 'M318.7 462.8c-7.8 17.1-4 35.4 3.6 53.2s22.5 31.5 39.5 36.2c4.1 1.1 8.5 1.8 12.4 0.3s7.3-5.6 7.1-10.3c14.6 11.3 34 12.6 50.4 6.2s29.8-19.7 39.9-35.3c5.6-8.5 10.4-19.6 6.4-29.4-2.7-6.7-9.1-11-15.6-12.5s-13.1-0.9-19.6-0.3c-24.9 2.1-51.2 1.4-73.4-12-11.4-6.9-23.2-16.7-35.6-13.5-2.3 0.6-10.7 4.6-15 17.4', 'M304.6 460.4c-9.7 21.3-4.9 44.3 4.5 66.5s28.2 39.4 49.4 45.2c5.1 1.4 10.6 2.2 15.5 0.4s9.1-7 8.8-12.9c18.2 14.1 42.5 15.8 63 7.8s37.2-24.7 50-44.1c6.9-10.6 13-24.5 8-36.7-3.4-8.4-11.4-13.7-19.5-15.7s-16.4-1.1-24.5-0.4c-31.1 2.6-64 1.8-91.8-15-14.2-8.6-29-20.8-44.5-16.9-2.9 0.7-13.3 5.8-18.8 21.8', 'M290.6 458c-11.7 25.6-5.9 53.1 5.3 79.7s33.8 47.2 59.3 54.3c6.2 1.7 12.7 2.6 18.6 0.5s10.9-8.4 10.6-15.4c21.8 16.9 51 18.9 75.6 9.3s44.7-29.6 59.9-53c8.3-12.7 15.5-29.4 9.6-44-4.1-10.1-13.7-16.5-23.4-18.8s-19.6-1.3-29.4-0.5c-37.3 3.1-76.8 2.2-110.1-18-17.1-10.3-34.8-25-53.4-20.3-3.5 0.9-16 6.9-22.5 26.2'],
            ['M452.2 480.9c-2.1-5-6.8-8.2-11.7-9.4a26.1 26.1 0 0 0-4.6-0.6c0.4 8.2-2.1 16.7-4.3 24.2-9 28-36.7 16.2-57.3 13-4.9-0.5-7.9 4.6-12 6.4-7.3 2.3-15.1 1.6-22.3-1 6.2 9.2 15.2 16 25.1 18.8 3.1 0.9 6.4 1.3 9.3 0.2s5.4-4.2 5.3-7.7c10.9 8.5 25.5 9.5 37.8 4.6s22.3-14.8 30-26.4C451.6 496.6 455.2 488.3 452.2 480.9Z', 'M478 483.8c-2.7-6.7-9.1-11-15.6-12.6a34.8 34.8 0 0 0-6.2-0.9c0.6 10.9-2.8 22.3-5.7 32.3-12 37.3-48.9 21.7-76.5 17.4-6.5-0.7-10.5 6.2-15.9 8.5-9.8 3.1-20.1 2.1-29.8-1.4 8.2 12.2 20.3 21.4 33.5 25.1 4.1 1.1 8.5 1.8 12.4 0.3s7.3-5.6 7-10.3c14.6 11.3 34 12.6 50.4 6.2s29.8-19.7 40-35.3C477.1 504.6 482 493.6 478 483.8Z', 'M503.7 486.6c-3.4-8.4-11.4-13.7-19.5-15.7a43.5 43.5 0 0 0-7.7-1.1c0.7 13.6-3.5 27.9-7.1 40.3-15 46.7-61.1 27.1-95.6 21.8-8.1-0.9-13.2 7.7-19.9 10.6-12.2 3.8-25.1 2.6-37.3-1.7 10.3 15.3 25.3 26.7 41.9 31.3 5.1 1.4 10.6 2.2 15.5 0.4s9.1-7 8.8-12.9c18.2 14.1 42.5 15.8 63 7.8s37.2-24.7 50-44.1C502.7 512.7 508.7 498.8 503.7 486.6Z', 'M529.4 489.4c-4.1-10.1-13.7-16.5-23.3-18.8a52.2 52.2 0 0 0-9.3-1.3c0.9 16.3-4.2 33.4-8.6 48.3-18 56-73.4 32.5-114.7 26.1-9.7-1.1-15.8 9.3-23.8 12.8-14.7 4.6-30.2 3.1-44.7-2 12.3 18.4 30.4 32.1 50.2 37.5 6.2 1.7 12.7 2.6 18.6 0.5s10.9-8.4 10.6-15.4c21.8 16.9 51 18.9 75.6 9.3s44.7-29.6 59.9-53C528.2 520.7 535.4 504.1 529.4 489.4Z']
        ];

        return abi.encodePacked(
            '<path style="',
            _chickenInData.chickenStyle,
            '" d="',
            p[0][uint256(_commonData.size)],
            '"/><path style="',
            _chickenInData.wingShadeStyle,
            '" d="',
            p[1][uint256(_commonData.size)],
            '"/>'
        );
    }
}

contract ChickenInWing2 {
    function getSVGWing2(CommonData calldata _commonData, ChickenInData calldata _chickenInData) external pure returns (bytes memory) {
        string[4][3] memory p = [
            ['M375 531.6c3.1 0.2 5.5 5.1 4.4 8s-4.2 4.6-7.3 4.6-6-1.1-8.7-2.6c-11.1-6.1-19.4-16.5-24.7-28.1s-7.7-24.2-9.1-36.7c-0.4-4-0.8-8-0.4-12a18.7 18.7 0 0 1 1.9-6.9c1.9-3.6 5.5-6.2 9.3-7.7s8-2 12.1-2.4c6.7-0.7 13.6-1.1 20.2 0.2 8.1 1.5 15.5 5.5 23.1 8.7 16.4 6.9 34.8 10.4 52 5.7 1.8-0.5 3.6-1.1 5.4-0.8 4.2 0.6 6.6 5.3 6.8 9.6 0.5 6.9-2.7 13.7-7.7 18.4s-11.5 7.6-18.2 9.1q5.4-0.8 10.9-1.2c2-0.1 4.2-0.2 5.6 1.1 1.4 1.2 1.7 3.4 1.2 5.2s-1.8 3.3-3.1 4.5c-5.8 5.7-13.7 8.9-21.7 9.8s-16.2-0.5-23.9-3l8.4 5.6a8.1 8.1 0 0 1 2.7 2.4c1.1 1.9 0.5 4.5-1.1 6.2s-3.7 2.5-5.8 3.1c-10.4 2.9-21.6 1.2-32.3-0.6', 'M375 551.3c4.1 0.3 7.3 6.7 5.9 10.6s-5.7 6.1-9.7 6.2-8-1.5-11.6-3.5c-14.8-8.1-25.9-22-33-37.4s-10.3-32.2-12.2-49c-0.6-5.3-1.1-10.6-0.5-15.9a24.9 24.9 0 0 1 2.5-9.3c2.6-4.8 7.3-8.2 12.5-10.2s10.6-2.6 16.1-3.2c9-0.9 18.1-1.4 26.9 0.3 10.8 2.1 20.7 7.3 30.9 11.6 21.8 9.2 46.4 13.8 69.2 7.6 2.4-0.6 4.8-1.4 7.2-1.1 5.6 0.8 8.7 7.1 9.1 12.7 0.6 9.1-3.7 18.2-10.2 24.6s-15.3 10.2-24.3 12.1q7.2-1.1 14.5-1.6c2.6-0.2 5.6-0.2 7.6 1.5 1.9 1.6 2.3 4.5 1.5 6.9s-2.4 4.4-4.1 6.1c-7.7 7.6-18.2 11.8-28.9 13s-21.6-0.6-31.9-4l11.1 7.4a10.8 10.8 0 0 1 3.6 3.3c1.5 2.6 0.6 6-1.4 8.2s-4.9 3.3-7.8 4.1c-13.9 3.9-28.7 1.6-43-0.8', 'M375 571.1c5.1 0.4 9.1 8.4 7.4 13.2s-7.1 7.6-12.2 7.7-10-1.9-14.5-4.4c-18.6-10.1-32.4-27.5-41.2-46.7s-12.8-40.3-15.2-61.3c-0.7-6.6-1.3-13.3-0.7-19.9a31.1 31.1 0 0 1 3.2-11.6c3.2-6 9.2-10.3 15.6-12.7s13.3-3.3 20.1-4c11.2-1.1 22.6-1.8 33.6 0.3 13.5 2.6 25.9 9.2 38.6 14.5 27.3 11.4 58 17.3 86.6 9.5 2.9-0.8 6-1.8 9-1.3 7 1 10.9 8.8 11.4 15.9 0.8 11.4-4.6 22.8-12.9 30.7s-19.1 12.7-30.3 15.1q9-1.3 18.1-2c3.3-0.2 7-0.3 9.5 1.9 2.3 2.1 2.9 5.6 1.9 8.6s-3 5.4-5.1 7.6c-9.6 9.5-22.8 14.8-36.2 16.3s-27-0.8-39.8-5l13.9 9.3a13.5 13.5 0 0 1 4.5 4.1c1.9 3.2 0.8 7.5-1.8 10.2s-6.2 4.1-9.7 5.2c-17.4 4.9-35.9 2-53.8-1', 'M375 590.8c6.1 0.4 11 10.1 8.8 15.8s-8.5 9.1-14.6 9.3-12-2.3-17.4-5.2c-22.3-12.1-38.9-33-49.4-56.1s-15.4-48.3-18.2-73.6c-0.9-7.9-1.6-15.9-0.9-23.8a37.3 37.3 0 0 1 3.9-13.9c3.9-7.3 11-12.4 18.6-15.4s15.9-4 24.2-4.7c13.4-1.3 27.1-2.1 40.3 0.4 16.2 3.1 31.1 11 46.3 17.4 32.7 13.7 69.6 20.7 103.9 11.4 3.5-1 7.2-2.1 10.8-1.6 8.4 1.2 13.1 10.6 13.7 19 0.9 13.7-5.5 27.3-15.4 36.9s-23 15.3-36.4 18.2q10.8-1.6 21.8-2.4c3.9-0.3 8.3-0.4 11.3 2.2 2.8 2.5 3.4 6.8 2.4 10.3s-3.6 6.5-6.3 9.2c-11.5 11.3-27.3 17.8-43.4 19.5s-32.4-0.9-47.7-6l16.7 11.1a16.2 16.2 0 0 1 5.4 4.9c2.3 3.8 0.9 9-2.2 12.4s-7.4 5-11.6 6.2c-20.9 5.9-43.1 2.3-64.5-1.3'],
            ['M460 471.1c-0.3-4.2-2.6-8.9-6.8-9.5-1.8-0.3-3.6 0.3-5.4 0.8a61.9 61.9 0 0 1-14.4 2.1c-8.3 17.3-23.1 31-43.3 34.7a54.5 54.5 0 0 1-60.6-36.6c-0.1 0.7-0.2 1.5-0.3 2.2-0.4 4 0 8 0.4 11.9 1.4 12.6 3.9 25.2 9.1 36.8s13.6 22 24.7 28.1c2.7 1.5 5.6 2.7 8.7 2.6s6.2-1.8 7.3-4.7c0.9-2.5-0.8-6.4-3.2-7.6l-1.2-0.2 0-0.1a3.3 3.3 0 0 1 1.2 0.3c10.3 1.7 21 3.2 31.1 0.5 2.2-0.6 4.3-1.5 5.8-3.1s2.2-4.2 1.1-6.2a8.1 8.1 0 0 0-2.7-2.4l-8.4-5.6c7.7 2.5 15.8 3.9 23.9 3s15.9-4.1 21.7-9.8c1.3-1.3 2.6-2.8 3.1-4.6s0.2-3.9-1.1-5.1c-1.5-1.3-3.7-1.3-5.7-1.1q-5.5 0.4-10.9 1.2c6.7-1.5 13.2-4.3 18.2-9.1S460.4 478 460 471.1Z', 'M488.3 470.7c-0.4-5.6-3.5-11.9-9.1-12.7-2.4-0.3-4.8 0.4-7.2 1.1a82.6 82.6 0 0 1-19.2 2.8c-11.1 23-30.8 41.3-57.6 46.2a72.7 72.7 0 0 1-80.9-48.8c-0.2 1-0.3 2-0.4 3-0.5 5.3-0.1 10.6 0.5 15.9 1.9 16.8 5.1 33.7 12.2 49s18.1 29.3 33 37.4c3.6 2 7.5 3.6 11.6 3.5s8.3-2.4 9.7-6.2c1.2-3.3-1-8.6-4.3-10.1l-1.6-0.3 0-0.2a4.4 4.4 0 0 1 1.6 0.5c13.8 2.3 28 4.3 41.5 0.5 2.9-0.8 5.8-2 7.7-4.1s2.9-5.7 1.5-8.2a10.8 10.8 0 0 0-3.6-3.3l-11.2-7.4c10.2 3.3 21.1 5.1 31.9 4s21.3-5.5 28.9-13c1.8-1.7 3.4-3.7 4.1-6.1s0.3-5.2-1.5-6.9c-2-1.7-4.9-1.7-7.6-1.5q-7.3 0.5-14.5 1.6c8.9-1.9 17.7-5.8 24.3-12.1S488.9 479.9 488.3 470.7Z', 'M516.7 470.3c-0.5-7-4.4-14.9-11.4-15.9-3-0.4-6.1 0.5-9 1.3a103.2 103.2 0 0 1-24 3.5c-13.9 28.8-38.5 51.7-72.1 57.8a90.8 90.8 0 0 1-101.1-61c-0.2 1.2-0.4 2.4-0.5 3.7-0.7 6.6-0.1 13.3 0.7 19.9 2.4 21 6.4 42.1 15.2 61.3s22.7 36.6 41.2 46.7c4.5 2.4 9.4 4.5 14.5 4.4s10.4-2.9 12.2-7.8c1.5-4.1-1.3-10.7-5.4-12.6l-2-0.4 0-0.2a5.5 5.5 0 0 1 2 0.6c17.2 2.9 35 5.4 51.8 0.7 3.6-1 7.2-2.4 9.8-5.2s3.7-7.1 1.7-10.3a13.5 13.5 0 0 0-4.5-4l-13.9-9.3c12.8 4.2 26.4 6.4 39.8 5s26.6-6.8 36.2-16.3c2.2-2.2 4.3-4.7 5.2-7.6s0.4-6.6-2-8.6c-2.5-2.2-6.1-2.1-9.4-1.9q-9.1 0.7-18.2 2c11.2-2.4 22.1-7.2 30.4-15.2S517.4 481.7 516.7 470.3Z', 'M545 469.8c-0.6-8.4-5.3-17.9-13.7-19-3.6-0.5-7.3 0.6-10.8 1.5a123.9 123.9 0 0 1-28.7 4.2c-16.6 34.6-46.3 62-86.6 69.4a109 109 0 0 1-121.2-73.2c-0.3 1.5-0.5 2.9-0.7 4.5-0.8 7.9-0.1 15.9 0.9 23.8 2.9 25.2 7.7 50.5 18.2 73.5s27.2 44 49.4 56.1c5.4 2.9 11.3 5.4 17.4 5.3s12.5-3.5 14.6-9.3c1.8-5-1.6-12.9-6.4-15.2l-2.4-0.4 0-0.3a6.6 6.6 0 0 1 2.4 0.7c20.7 3.4 42.1 6.5 62.2 0.8 4.3-1.2 8.6-2.9 11.7-6.2s4.4-8.5 2.1-12.3a16.2 16.2 0 0 0-5.4-4.9l-16.7-11.1c15.4 5 31.7 7.7 47.7 6s31.9-8.2 43.5-19.6c2.7-2.6 5.1-5.6 6.2-9.1s0.4-7.9-2.4-10.3c-3-2.6-7.4-2.5-11.3-2.3q-10.9 0.8-21.8 2.4c13.4-2.9 26.5-8.6 36.4-18.2S545.9 483.5 545 469.8Z'],
            ['M457.2 463.9C450.8 473.1 444.6 482.5 436 490.1c-17.3 14-38.3 22.1-60.5 22.1a88.4 88.4 0 0 1-41.1-10.3 89.9 89.9 0 0 0 4.3 11.6c5.3 11.5 13.6 22 24.7 28.1 2.7 1.5 5.6 2.7 8.7 2.6s6.2-1.8 7.3-4.6c0.9-2.5-0.8-6.4-3.2-7.7l-1.2-0.1 0-0.2a3.3 3.3 0 0 1 1.2 0.3c10.3 1.7 21 3.2 31.1 0.5 2.2-0.6 4.3-1.5 5.8-3.1s2.2-4.2 1.1-6.2a8.1 8.1 0 0 0-2.7-2.4l-8.3-5.6c7.7 2.5 15.8 3.9 23.8 3s15.9-4.1 21.7-9.8c1.3-1.3 2.6-2.8 3.1-4.5s0.2-3.9-1.1-5.2c-1.5-1.3-3.7-1.3-5.7-1.1q-5.5 0.4-10.9 1.2c6.7-1.5 13.2-4.3 18.2-9.1S460.4 478 460 471.1A12.5 12.5 0 0 0 457.2 463.9Z', 'M484.6 461C476.1 473.4 467.8 485.9 456.4 495.9c-23 18.7-51.1 29.5-80.7 29.5a117.9 117.9 0 0 1-54.9-13.7 119.9 119.9 0 0 0 5.8 15.5c7 15.4 18.1 29.3 33 37.4 3.6 2 7.5 3.6 11.6 3.5s8.3-2.4 9.7-6.2c1.2-3.3-1-8.6-4.3-10.1l-1.6-0.3 0-0.2a4.4 4.4 0 0 1 1.6 0.5c13.8 2.3 28 4.3 41.5 0.5 2.9-0.8 5.8-2 7.8-4.1s2.9-5.7 1.4-8.2a10.8 10.8 0 0 0-3.6-3.3l-11.2-7.4c10.2 3.3 21.1 5.1 31.9 4s21.3-5.5 28.9-13c1.8-1.7 3.4-3.7 4.2-6.1s0.3-5.2-1.6-6.9c-2-1.7-4.9-1.7-7.6-1.5q-7.3 0.5-14.5 1.6c8.9-1.9 17.7-5.8 24.3-12.1S488.9 479.9 488.3 470.7A16.6 16.6 0 0 0 484.6 461Z', 'M511.9 458.1C501.4 473.6 491 489.2 476.7 501.8c-28.8 23.4-63.9 36.9-100.8 36.8a147.4 147.4 0 0 1-68.6-17.1 149.8 149.8 0 0 0 7.2 19.4c8.8 19.2 22.7 36.6 41.2 46.7 4.5 2.4 9.4 4.5 14.5 4.4s10.4-2.9 12.2-7.7c1.5-4.1-1.3-10.7-5.4-12.7l-1.9-0.3 0-0.3a5.5 5.5 0 0 1 1.9 0.6c17.2 2.9 35 5.4 51.8 0.7 3.6-1 7.2-2.4 9.8-5.2s3.7-7.1 1.7-10.3a13.5 13.5 0 0 0-4.5-4l-13.9-9.3c12.8 4.2 26.4 6.4 39.8 5s26.6-6.8 36.2-16.3c2.2-2.2 4.3-4.7 5.2-7.6s0.4-6.6-2-8.6c-2.5-2.2-6.1-2.1-9.4-1.9q-9.1 0.7-18.2 2c11.2-2.4 22.1-7.2 30.4-15.1S517.4 481.7 516.7 470.3A20.8 20.8 0 0 0 511.9 458.1Z', 'M539.3 455.3C526.6 473.8 514.2 492.6 497 507.6c-34.6 28.1-76.7 44.3-120.9 44.3a176.9 176.9 0 0 1-82.3-20.5 179.8 179.8 0 0 0 8.6 23.2c10.5 23.1 27.2 44 49.5 56.1 5.4 2.9 11.3 5.4 17.4 5.2s12.5-3.5 14.6-9.3c1.8-5-1.6-12.9-6.5-15.2l-2.3-0.4 0-0.3a6.6 6.6 0 0 1 2.3 0.7c20.7 3.4 42.1 6.5 62.2 0.8 4.3-1.2 8.6-2.9 11.7-6.2s4.4-8.5 2.1-12.3a16.2 16.2 0 0 0-5.4-4.9l-16.7-11.1c15.4 5 31.7 7.7 47.8 6s31.9-8.2 43.4-19.5c2.7-2.6 5.1-5.6 6.2-9.2s0.4-7.9-2.4-10.3c-3-2.6-7.4-2.5-11.3-2.2q-10.9 0.8-21.7 2.4c13.4-2.9 26.5-8.6 36.4-18.2S545.9 483.5 545 469.8A25 25 0 0 0 539.3 455.3Z']
        ];

        return abi.encodePacked(
            '<path style="',
            _chickenInData.chickenStyle,
            '" d="',
            p[0][uint256(_commonData.size)],
            '"/><path style="',
            _chickenInData.wingShadeStyle,
            '" d="',
            p[1][uint256(_commonData.size)],
            '"/><path style="',
            _chickenInData.wingShadeStyle,
            '" d="',
            p[2][uint256(_commonData.size)],
            '"/>'
        );
    }
}

contract ChickenInWing3 {
    function getSVGWing3(CommonData calldata _commonData, ChickenInData calldata _chickenInData) external pure returns (bytes memory) {
        string[4][4] memory p = [
            ['M382 466.8c-18-40.2-44.8-9.2-48 0.6-5.8 17.5-1.1 73.6 65.7 72.4s45-69.9 32.2-76.2-0.9 13-5 11.2-1.8-8.4-12.4-12-1.6 5.1-4.4 5.2-7-8.1-12.6-8.8 2.2 4.4 0.2 13.2S386.8 477.5 382 466.8Z', 'M384.4 464.9c-24-53.7-59.8-12.2-64.1 0.8-7.8 23.3-1.5 98.1 87.6 96.5s60-93.2 43-101.5-1.2 17.3-6.7 14.8-2.4-11.2-16.5-16-2.1 6.8-5.8 7-9.3-10.9-16.9-11.7 2.9 5.9 0.3 17.6S390.7 479.1 384.4 464.9Z', 'M386.7 463.1c-30-67.1-74.7-15.3-80.1 0.8-9.7 29.2-1.9 122.7 109.5 120.7s75-116.5 53.8-126.9-1.5 21.6-8.4 18.6-3.1-14-20.6-20-2.7 8.5-7.3 8.8-11.6-13.6-21.1-14.8 3.6 7.4 0.3 22.1S394.6 480.8 386.7 463.1Z', 'M389 461.2c-36-80.5-89.6-18.4-96.1 1-11.7 35-2.2 147.2 131.5 144.9s90-139.8 64.5-152.3-1.9 25.9-10.1 22.3-3.7-16.8-24.7-24.1-3.2 10.2-8.8 10.6-14-16.3-25.3-17.7 4.3 8.8 0.4 26.5S398.6 482.5 389 461.2Z'],
            ['M332.3 485.1c1.6 23.2 16.4 55.6 67.4 54.7 39-0.7 47.8-24.4 45.8-45.2C432.7 503.3 416.4 506.2 401.5 507.9 376.7 510.2 350.7 502 332.3 485.1Z', 'M318 489.3c2.1 31 21.9 74.2 89.9 72.9 52-0.9 63.7-32.5 61.1-60.3C451.9 513.5 430.2 517.4 410.3 519.7 377.3 522.8 342.6 511.9 318 489.3Z', 'M303.8 493.5c2.6 38.7 27.4 92.7 112.3 91.1 65-1.2 79.7-40.6 76.4-75.3C471.1 523.8 444.1 528.7 419.1 531.5 377.8 535.3 334.5 521.7 303.8 493.5Z', 'M289.6 497.7c3.2 46.4 32.9 111.2 134.8 109.4 78-1.4 95.6-48.7 91.7-90.4C490.4 534 457.9 539.9 427.9 543.2 378.4 547.9 326.5 531.5 289.6 497.7Z'],
            ['M355.6 519.2c-6.5-2.4-13-6.4-17.7-11.9 8.1 17.4 26.1 33.1 61.8 32.5 29.5-0.5 41.7-14.2 45-29.9C421.1 530.9 384.6 529.7 355.6 519.2Z', 'M349.1 534.8c-8.6-3.2-17.3-8.5-23.5-15.9 10.8 23.2 34.8 44.1 82.3 43.3 39.3-0.7 55.6-18.9 60.1-39.8C436.4 550.4 387.8 548.8 349.1 534.8Z', 'M342.6 550.4c-10.8-4-21.6-10.6-29.4-19.8 13.6 29 43.5 55.1 102.9 54 49.1-0.9 69.5-23.6 75.1-49.7C451.8 569.9 391 567.9 342.6 550.4Z', 'M336.1 565.9c-13-4.9-25.9-12.8-35.2-23.7 16.3 34.8 52.2 66.1 123.5 64.8 58.9-1.1 83.4-28.4 90.1-59.6C467.2 589.4 394.2 587 336.1 565.9Z'],
            ['M417.1 475.5c7.2 5.6 17.8 7.9 24.4 2-2.8-7.1-6.4-12.3-9.6-13.8-12.7-6.2-0.9 13-5 11.1s-1.8-8.4-12.4-12-1.6 5.1-4.4 5.3-7-8.1-12.6-8.9 2.2 4.4 0.2 13.3c0 0.2-0.1 0.4-0.2 0.6 1.8 1.1 3.8 1.8 6.1 2.4C408.5 476.6 413.3 472.2 417.1 475.5Z', 'M431.2 476.5c9.6 7.5 23.7 10.5 32.5 2.7-3.7-9.5-8.6-16.5-12.8-18.5-17-8.3-1.2 17.3-6.7 14.9s-2.4-11.2-16.5-16-2.1 6.8-5.8 7-9.3-10.9-16.9-11.8 2.9 5.9 0.3 17.7c-0.1 0.3-0.1 0.5-0.2 0.8 2.3 1.4 5.1 2.3 8.1 3.2C419.6 477.9 426.1 472.1 431.2 476.5Z', 'M445.2 477.4c12 9.4 29.6 13.1 40.6 3.5-4.6-11.8-10.7-20.6-15.9-23.1-21.2-10.3-1.5 21.6-8.4 18.6s-3.1-14-20.6-20.1-2.7 8.5-7.3 8.8-11.6-13.6-21.1-14.7 3.6 7.4 0.3 22c-0.1 0.4-0.2 0.7-0.2 1.1 2.9 1.8 6.4 2.9 10.1 4C430.8 479.3 438.9 472.1 445.2 477.4Z', 'M459.2 478.4c14.4 11.3 35.6 15.7 48.8 4.2-5.5-14.2-12.9-24.7-19.1-27.8-25.5-12.4-1.9 25.9-10.1 22.3s-3.7-16.8-24.7-24-3.2 10.2-8.8 10.5-14-16.3-25.3-17.6 4.3 8.8 0.4 26.4c-0.1 0.4-0.2 0.8-0.3 1.2 3.5 2.2 7.6 3.5 12.1 4.8C442 480.6 451.7 472 459.2 478.4Z']
        ];

        return abi.encodePacked(
            abi.encodePacked(
                '<path style="',
                _chickenInData.chickenStyle,
                '" d="',
                p[0][uint256(_commonData.size)],
                '"/><path style="',
                _chickenInData.wingShadeStyle,
                '" d="',
                p[1][uint256(_commonData.size)],
                '"/><path style="',
                _chickenInData.wingShadeStyle,
                '" d="',
                p[2][uint256(_commonData.size)],
                '"/><path style="'
            ),
            abi.encodePacked(
                _chickenInData.wingTipShadeStyle,
                '" d="',
                p[3][uint256(_commonData.size)],
                '"/>'
            )
        );
    }
}

contract ChickenInLQTYBand {
    function getSVGLQTYBand(CommonData calldata _commonData) external pure returns (bytes memory) {
        string[4][3] memory p = [
            ['x="376.3" y="561.9" width="9.3" height="5.4" rx="1.1"', 'x="376.7" y="591.7" width="12.5" height="7.2" rx="1.4"', 'x="377.1" y="621.5" width="15.6" height="9" rx="1.8"', 'x="377.5" y="651.2" width="18.7" height="10.8" rx="2.2"'],
            ['x="376.3" y="564" width="9.3" height="3.2" rx="1.1"', 'x="376.7" y="594.5" width="12.5" height="4.3" rx="1.4"', 'x="377.1" y="625.1" width="15.6" height="5.4" rx="1.8"', 'x="377.5" y="655.6" width="18.7" height="6.5" rx="2.2"'],
            ['x="376.3" y="563.6" width="9.3" height="1.9" rx="0"', 'x="376.7" y="594" width="12.5" height="2.6" rx="0"', 'x="377.1" y="624.3" width="15.6" height="3.2" rx="0"', 'x="377.5" y="654.7" width="18.7" height="3.9" rx="0"']
        ];

        return abi.encodePacked(
            '<rect style="fill:#5bb2e4" ',
            p[0][uint256(_commonData.size)],
            '/><rect style="fill:#705ed6" ',
            p[1][uint256(_commonData.size)],
            '/><rect style="fill:#2241c4" ',
            p[2][uint256(_commonData.size)],
            '/>'
        );
    }
}

contract ChickenInGenerated1 is
  ChickenInShadow, // 0.894
  ChickenInLegs, // 3.43
  ChickenInBody, // 5.5
  ChickenInComb, // 15.06
  ChickenInCheek // 1.037
{}

contract ChickenInGenerated2 is
  ChickenInBeak, // 4.024
  ChickenInEye, // 2.052
  ChickenInTail // 19.204
{}

contract ChickenInGenerated3 is
  ChickenInAnimations, // 4.063
  ChickenInWattle, // 1.705
  ChickenInWing1, // 3.644
  ChickenInWing2, // 8.576
  ChickenInWing3, // 4.682
  ChickenInLQTYBand // 1.865
{}

contract ChickenInGenerated {
    ChickenInGenerated1 public immutable g1;
    ChickenInGenerated2 public immutable g2;
    ChickenInGenerated3 public immutable g3;

    constructor(
        ChickenInGenerated1 _g1,
        ChickenInGenerated2 _g2,
        ChickenInGenerated3 _g3
      ) {
        g1 = _g1;
        g2 = _g2;
        g3 = _g3;
    }

    //////////////////////////////////
    //////////// Slice #1 ////////////
    //////////////////////////////////

    function _getSVGShadow(CommonData memory _commonData) internal view returns (bytes memory) {
        return g1.getSVGShadow(_commonData);
    }

    function _getSVGLegs(CommonData memory _commonData, ChickenInData memory _chickenInData) internal view returns (bytes memory) {
        return g1.getSVGLegs(_commonData, _chickenInData);
    }

    function _getSVGBody(CommonData memory _commonData, ChickenInData memory _chickenInData) internal view returns (bytes memory) {
        return g1.getSVGBody(_commonData, _chickenInData);
    }

    function _getSVGCombPath(CommonData memory _commonData, ChickenInData memory _chickenInData, bytes memory _style) internal view returns (bytes memory) {
        return g1.getSVGCombPath(_commonData, _chickenInData, _style);
    }

    function _getSVGCheek(CommonData memory _commonData, ChickenInData memory _chickenInData) internal view returns (bytes memory) {
        return g1.getSVGCheek(_commonData, _chickenInData);
    }

    //////////////////////////////////
    //////////// Slice #2 ////////////
    //////////////////////////////////

    function _getSVGBeakPath(CommonData memory _commonData, ChickenInData memory _chickenInData, bytes memory _style) internal view returns (bytes memory) {
        return g2.getSVGBeakPath(_commonData, _chickenInData, _style);
    }

    function _getSVGEye(CommonData memory _commonData) internal view returns (bytes memory) {
        return g2.getSVGEye(_commonData);
    }

    function _getSVGTailPath(CommonData memory _commonData, ChickenInData memory _chickenInData, bytes memory _style) internal view returns (bytes memory) {
        return g2.getSVGTailPath(_commonData, _chickenInData, _style);
    }

    //////////////////////////////////
    //////////// Slice #3 ////////////
    //////////////////////////////////

    function _getSVGAnimations(CommonData memory _commonData) internal view returns (bytes memory) {
        return g3.getSVGAnimations(_commonData);
    }

    function _getSVGWattlePath(CommonData memory _commonData, bytes memory _style) internal view returns (bytes memory) {
        return g3.getSVGWattlePath(_commonData, _style);
    }

    function _getSVGWing1(CommonData memory _commonData, ChickenInData memory _chickenInData) internal view returns (bytes memory) {
        return g3.getSVGWing1(_commonData, _chickenInData);
    }

    function _getSVGWing2(CommonData memory _commonData, ChickenInData memory _chickenInData) internal view returns (bytes memory) {
        return g3.getSVGWing2(_commonData, _chickenInData);
    }

    function _getSVGWing3(CommonData memory _commonData, ChickenInData memory _chickenInData) internal view returns (bytes memory) {
        return g3.getSVGWing3(_commonData, _chickenInData);
    }

    function _getSVGLQTYBand(CommonData memory _commonData) internal view returns (bytes memory) {
        return g3.getSVGLQTYBand(_commonData);
    }
}