//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./CpigColor.sol";

contract CpigParts2 {
    address addrColor;

    constructor(address _addrColor) {
        addrColor = _addrColor;
    }

    // Neck
    function genNeck(uint8 idx, uint8 sidx)
        external
        view
        returns (string memory)
    {
        CpigColor cc = CpigColor(addrColor);

        // Bowtie
        if (idx == 0) {
            return
                string(
                    abi.encodePacked(
                        '<path d="M360,830 a100,50 20,0,1 140,40 a100,50 20,0,0 140,40 a20,50 0,0,0 0,-80 a100,50 -20,0,0 -140,40 a100,50 -20,0,1 -140,40 a20,50 0,0,1 0,-80 z" style="fill:#',
                        cc.pwcols(sidx),
                        ";stroke:#",
                        cc.bgcols(0),
                        ';stroke-width:10"/><rect x="480" y="850" rx="10" ry="10" width="40" height="40" style="fill:#',
                        cc.pwcols(sidx),
                        ";stroke:#",
                        cc.bgcols(0),
                        ';stroke-width:10"/>'
                    )
                );
        }

        // Bowknot
        if (idx == 1) {
            return
                string(
                    abi.encodePacked(
                        '<path d="M500,870 q-10,-40 -80,-60 q-30,40 0,80 l80,-20 q-80,30 -100,80 q20,20 60,40 q30,-50 40,-120 q10,-40 80,-60 q30,40 0,80 l-80,-20 q80,30 100,80 q-20,20 -60,40 q-30,-50 -40,-120 z" style="fill:#',
                        cc.pwcols(sidx),
                        ";stroke:#",
                        cc.bgcols(0),
                        ';stroke-width:10"/><rect x="480" y="850" rx="10" ry="10" width="40" height="40" style="fill:#',
                        cc.pwcols(sidx),
                        ";stroke:#",
                        cc.bgcols(0),
                        ';stroke-width:10"/>'
                    )
                );
        }

        // Tie
        if (idx == 2) {
            return
                string(
                    abi.encodePacked(
                        '<path d="M450,860 l100,0 -30,40 -40,0 -30,-40z" style="fill:#',
                        cc.pwcols(sidx),
                        ";stroke:#",
                        cc.bgcols(0),
                        ';stroke-width:10"/><path d="M480,900 l40,0 20,80 -40,20 -40,-20 20,-80z" style="fill:#',
                        cc.pwcols(sidx),
                        ";stroke:#",
                        cc.bgcols(0),
                        ';stroke-width:10"/><path d="M340,860 l100,50 40,-50z M660,860 l-100,50 -40,-50z" style="fill:#',
                        cc.bgcols(1),
                        ";stroke:#",
                        cc.bgcols(0),
                        ';stroke-width:10"/>'
                    )
                );
        }

        //  Scarf
        if (idx == 3) {
            return
                string(
                    abi.encodePacked(
                        '<defs><rect id="nas" x="0" y="0" rx="15" width="60" height="150"/><mask id="nam"><rect x="250" y="820" width="500" height="160" fill="#fff"/><rect x="250" y="800" rx="0" ry="0" width="500" height="43" fill="#000"/></mask></defs><g mask="url(#nam)" style="fill:#',
                        cc.pwcols(sidx),
                        ";stroke:#",
                        cc.bgcols(0),
                        ';stroke-width:10"><g transform="translate(540,830)"><use transform="rotate(-8)" href="#nas"/></g><rect style="fill:#',
                        cc.pwcols(sidx),
                        ";stroke:#",
                        cc.bgcols(0),
                        ';stroke-width:10" x="300" y="855" rx="10" width="400" height="55"/><g transform="translate(550,780)"><use transform="rotate(8)" href="#nas"/></g></g>'
                    )
                );
        }

        // Bat
        if (idx == 4) {
            return
                string(
                    abi.encodePacked(
                        '<path d="M500,880 q-50,-60 -200,-100 q100,60 60,120 q50,-30 80,30 q10,-30 60,-50 q50,-60 200,-100 q-100,60 -60,120 q-50,-30 -80,30 q-10,-30 -60,-50 z" style="fill:#',
                        cc.bats(sidx),
                        ';stroke:none"/><path d="M480,890 l10,20 10,-15 10,15 10,-20 v-40 h-40 v40" style="fill:#',
                        cc.bats(sidx),
                        ';stroke:none"/>'
                    )
                );
        }

        return "";
    }

    // Glasses
    function genGls(uint8 idx) external view returns (string memory) {
        CpigColor cc = CpigColor(addrColor);

        // Circle
        if (idx == 1) {
            return (
                string(
                    abi.encodePacked(
                        '<path d="M435,500 a100,80 0,0,1 130,0 M240,420 a80,80 0,0,1 160,160 a80,80 0,0,1 -160,-160 M600,420 a80,80 0,0,1 160,160 a80,80 0,0,1 -160,-160" style="fill:none;stroke:#',
                        cc.bgcols(0),
                        ';stroke-width:10"/>'
                    )
                )
            );
        }
        // 3D
        else if (idx == 2) {
            return (
                string(
                    abi.encodePacked(
                        '<path d="M450,400 l0,160 -40,40 -210,0 0,-200 z" style="fill:blue;opacity:0.35"/><path d="M550,400 l250,0 0,200 -210,0 -40,-40 z" style="fill:red;opacity:0.35"/><path d="M450,400 l0,160 -40,40 -210,0 0,-200 600,0 0,200 -210,0 -40,-40 0,-160" style="fill:none;stroke:#',
                        cc.bgcols(0),
                        ';stroke-width:10;"/>'
                    )
                )
            );
        }
        // Polygon
        else if (idx == 3) {
            return (
                string(
                    abi.encodePacked(
                        '<defs><mask id="g3m"><path d="M470,440 L530,440 860,390 880,490 660,610 560,550 530,450 470,450 440,550 340,610 120,490 140,390 470,440 z" fill="#',
                        cc.bgcols(1),
                        '"/></mask><mask id="g3c"><circle r="20" fill="#',
                        cc.bgcols(1),
                        '"><animateMotion dur="3s" repeatCount="indefinite" path="M470,440 L530,440 860,390 880,490 660,610 560,550 530,450 470,450 440,550 340,610 120,490 140,390 470,440 z"/></circle></mask><g id="g3n"><path d="M10,650 l200,-450 M430,650 l200,-450" style="stroke:#',
                        cc.bgcols(1),
                        ';stroke-width:20;opacity:0.5"></path></g></defs><g mask="url(#g3m)"><use href="#g3n"><animate attributeName="x" values="0;410;0;410;410" keyTimes="0;0.2;0.2;0.4;1" dur="8s" repeatCount="indefinite"/></use></g><path d="M470,440 L530,440 860,390 880,490 660,610 560,550 530,450 470,450 440,550 340,610 120,490 140,390 470,440 z" style="fill:none;stroke:#',
                        cc.bgcols(0),
                        ';stroke-width:10;opacity:1"/>'
                    )
                )
            );
        }
        //Smart
        else if (idx == 4) {
            return (
                string(
                    abi.encodePacked(
                        '<defs><symbol id="ufo" width="200" height="200" viewBox="0 0 200 200"><g><ellipse cx="50" cy="50" rx="45" ry="10" style="fill:#',
                        cc.blc1(1),
                        ';opacity:0.6;"/><ellipse cx="50" cy="55" rx="25" ry="6" style="fill:#',
                        cc.blc1(1),
                        ';opacity:0.4;"/><path d="M30,40 a30,50 0,0,1 40,0 z" style="fill:#',
                        cc.blc1(1),
                        ';opacity:0.7;"/></g></symbol><path id="g4p" d="M140,380 L860,380 C860,620 750,620 700,620 C560,620 560,520 500,520 C440,520 440,620 300,620 C250,620 140,620 140,400 z"/><mask id="g4m"><path id="g4p" d="M140,380 L860,380 C860,620 750,620 700,620 C560,620 560,520 500,520 C440,520 440,620 300,620 C250,620 140,620 140,400 z" fill="#fff"/></mask></defs><use href="#g4p" style="fill:#',
                        cc.blc1(2),
                        ';opacity:0.3;"/><use href="#g4p" style="fill:none;stroke:#',
                        cc.blc1(2),
                        ';stroke-width:10"/><g mask="url(#g4m)"><g><g transform="rotate(-18)"><use href="#ufo"/></g><animateTransform attributeName="transform" attributeType="XML" type="translate" values="350,600;350,600;150,300" keyTimes="0;0.5;1"  dur="5.2s" repeatCount="indefinite"/></g><g><g transform="rotate(5)"><use href="#ufo"/></g><animateTransform attributeName="transform" attributeType="XML" type="translate" values="400,620;400,620;510,300" keyTimes="0;0.56;1" dur="5.5s" repeatCount="indefinite"/></g><g><g transform="rotate(22)"><use href="#ufo"/></g><animateTransform attributeName="transform" attributeType="XML" type="translate" values="600,600;600,600;780,300" keyTimes="0;0.58;1" dur="7s" repeatCount="indefinite"/></g></g>'
                    )
                )
            );
        }
        //LED
        else if (idx == 5) {
            return (
                string(
                    abi.encodePacked(
                        '<defs><pattern id="g7p1" viewBox="0,0,10,10" width="1.5%" height="5.4%"><circle cx="5" cy="5" r="5" style="fill:#',
                        cc.bgcols(0),
                        '"/></pattern><pattern id="g7p2" viewBox="0,0,10,10" width="1.5%" height="5.4%"><circle cx="5" cy="5" r="5" style="fill:#',
                        cc.blc1(1),
                        '"/></pattern><rect id="g7r" x="120" y="390" rx="40" ry="40" width="760" height="200"/><mask id="g7msk"><g><path d="M340,430 h-100 v120 h100 M390,560 v-130 h100 v50 h-100 M550,420 v140 M720,430 h-110 v120 h100 v-60 h-60" style="fill:none;stroke:#fff;stroke-width:20"/><animateTransform attributeName="transform" attributeType="XML" type="translate" values="900,0;900,0;0,0;-20,0;-700,0" keyTimes="0;0.2;0.4;0.6;1" dur="8s" repeatCount="indefinite"/></g></mask></defs><use href="#g7r" style="fill:',
                        cc.bgcols(0),
                        ';opacity:0.3"/><use href="#g7r" style="fill:url(#g7p1);opacity:0.3"/><g mask="url(#g7msk)"><use href="#g7r" fill="url(#g7p2)"/></g><use href="#g7r" style="fill:none;stroke:#',
                        cc.bgcols(0),
                        ';stroke-width:10"/>'
                    )
                )
            );
        }

        //None
        return "";
    }

    // Earring
    function genErs(uint8 idx) external view returns (string memory) {
        CpigColor cc = CpigColor(addrColor);

        //Silver
        if (idx == 1) {
            return (
                string(
                    abi.encodePacked(
                        '<circle cx="120" cy="380" r="5" fill="#',
                        cc.bgcols(0),
                        '"/><path d="M120,380 a10,30 30,1,0 -10,25" style="fill:none;stroke:#ccd;stroke-width:10"/>'
                    )
                )
            );
        }

        //Gold
        if (idx == 2) {
            return (
                string(
                    abi.encodePacked(
                        '<circle cx="120" cy="380" r="5" fill="#',
                        cc.bgcols(0),
                        '"/><path d="M120,380 a10,30 30,1,0 -10,25" style="fill:none;stroke:gold;stroke-width:10"/>'
                    )
                )
            );
        }

        //Diamond
        if (idx == 3) {
            return (
                string(
                    abi.encodePacked(
                        '<defs><path id="d" d="M0,-13 l12,-7 -24,0z M12,-7 l12,7 -12,7z M0,13 l12,7 -24,0z M-12,7 l-12,-7,12,-7z"/></defs><g transform="scale(1.2,1.2),translate(-20,-60)"><path d="M150,348 l12,7 0,15 -12,7 -12,-6 0,-15 12,-7 z" fill="#eef"/><use href="#d" x="150" y="363" fill="#dde"/><g transform="translate(150,363)"><use href="#d" fill="#ccd" transform="rotate(120)"/></g><g transform="translate(150,363)"><use href="#d" fill="#aab" transform="rotate(-120)"/></g></g>'
                    )
                )
            );
        }

        //Spiral
        if (idx == 4) {
            return (
                string(
                    abi.encodePacked(
                        '<defs><g id="r4s" transform="rotate(160)"><path d="M0,0 a5,5 0,0,1 -5,5 a5,5 0,0,1 -5,-5 a10,10 0,0,1 10,-10 a15,15 0,0,1 15,15 a25,25 0,0,1 -25,25 a40,40 0,0,1 -40,-40 a65,65 0,0,1 65,-65 a105,105 0,0,1 105,105 a170,170 0,0,1 -170,170" style="fill:none;stroke:#',
                        cc.bats(1),
                        ';stroke-width:8;stroke-linecap:round"/></g><mask id="r4m"><rect x="0" y="300" width="250" height="400" fill="#fff"/><path d="M90,380 l20,25 20,-15 -20,-15z" fill="#000"/></mask></defs><circle cx="120" cy="380" r="8" fill="#a5a990"/><g mask="url(#r4m)"><use href="#r4s" x="180" y="565"/></g>'
                    )
                )
            );
        }

        //Neon
        if (idx == 5) {
            return (
                string(
                    abi.encodePacked(
                        '<circle cx="120" cy="380" r="8" fill="#',
                        cc.bgcols(0),
                        '"/><defs><linearGradient id="r6g" gradientTransform="rotate(90)"><stop offset="0%" stop-color="#',
                        cc.blc1(0),
                        '"/><stop offset="25%" stop-color="#',
                        cc.blc1(1),
                        '"/><stop offset="75%" stop-color="#',
                        cc.blc1(2),
                        '"/><stop offset="100%" stop-color="#',
                        cc.blc1(0),
                        '"/></linearGradient><mask id="r6m"><g style="fill:none;stroke:#fff;stroke-width:8"><path d="M120,460 l-26,15 v30 l-26,15 v30 l26,15 l26,-15 v-30 l-26,-15 M120,460 l26,15 v30 l26,15 v30 l-26,15 l-26,-15 v-30 l26,-15"/><path d="M120,380 l34.6,20 v40 l-34.6,20 -34.6,-20 v-40 l14,-8"/></g></mask></defs><g mask="url(#r6m)"><g><rect id="r6r" x="40" y="0" width="150" height="300" fill="url(#r6g)" opacity="1"/><use href="#r6r" y="300"/><animateTransform attributeName="transform" attributeType="XML" type="translate" values="0,0;0,300" keyTimes="0;1" dur="5s" repeatCount="indefinite"/></g></g>'
                    )
                )
            );
        }

        //Alien
        if (idx == 6) {
            return (
                string(
                    abi.encodePacked(
                        '<mask id="r5m"><path d="M103,570 c-30,-20 -50,-70 0,-80 c50,10 30,60 0,80z" style="fill:#fff"/><path d="M80,510 a15,13 60,0,1 13,23 a15,13 60,0,1 -13,-23 M125,510 a15,13 -60,0,1 -13,23 a15,13 -60,0,1 13,-23z" style="fill:#000"/><circle cx="103" cy="500" r="5" fill="#000"/></mask><g fill="#',
                        cc.bgcols(0),
                        '"><rect mask="url(#r5m)" x="70" y="480" width="80" height="100" /><path d="M88,450 a25,60 0,0,1 28,0 M80,454 a20,5 0,0,1 46,0 a20,5 0,0,1 -46,0"/></g><circle cx="103" cy="360" r="5" fill="#',
                        cc.bgcols(0),
                        '"/><g style="fill:none;stroke:#',
                        cc.bgcols(0),
                        ';stroke-width:6"><path d="M103,500 v-40 M103,440 v-45"/><path d="M103,360 a8,8 0,0,1 10,10 l10,13"/></g>'
                    )
                )
            );
        }

        //None
        return "";
    }
}