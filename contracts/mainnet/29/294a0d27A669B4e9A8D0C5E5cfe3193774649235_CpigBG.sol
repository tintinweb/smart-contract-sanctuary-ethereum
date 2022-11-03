//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./CpigColor.sol";

contract CpigBG {
    address addrColor;

    constructor(address _addrColor) {
        addrColor = _addrColor;
    }

    string private bst =
        string(
            abi.encodePacked(
                '<defs><pattern id="star" viewBox="0,0,10,10" width="6%" height="6%"><circle cx="2" cy="2" r="1" fill="#9df6f6"/></pattern></defs><path d="M30,30 L250,285 50,235 250,10 350,250 600,20 400,50 550,240 850,30 980,300 700,80 970,500 880,560 960,700 880,950 700,990 850,800 500,970 400,860 300,965 200,840 30,980 150,600 20,760 160,400 10,360" style="fill:none;stroke:url(#star);stroke-width:20"/>'
            )
        );

    // Generate Background
    function genBG(uint8 idx, uint8 bidx)
        external
        view
        returns (string memory)
    {
        CpigColor cc = CpigColor(addrColor);

        // Ballons
        if (idx == 0) {
            return (
                string(
                    abi.encodePacked(
                        '<rect height="1000" width="1000" fill="#',
                        cc.bgcols(2),
                        '"/>',
                        cc.genBln(bidx)
                    )
                )
            );
        }
        // Clouds
        else if (idx == 1) {
            return (
                string(
                    abi.encodePacked(
                        '<rect height="1000" width="1000" fill="#',
                        cc.bgcols(2),
                        '"/><path id="cld1" d="M0,0 l200,0 a50,50 0,0,0 0,-100 a80,60 0,0,0 -160,-20 a60,60 0,0,0 -20,120 z" fill="#fef9ee"/><use href="#cld1" x="0"><animateMotion dur="50s" repeatCount="indefinite" path="M-300,200 l1500,0"/></use><use href="#cld1" x="0" transform="scale(0.6,0.6)"><animateMotion dur="60s" repeatCount="indefinite" path="M-300,300 l1500,0"/></use><use href="#cld1" x="0" transform="scale(0.6,0.6)"><animateMotion dur="70s" repeatCount="indefinite" path="M-200,150 l1500,0"/></use>'
                    )
                )
            );
        }
        // Starry Sky
        else if (idx == 2) {
            return (
                string(
                    abi.encodePacked(
                        '<rect height="1000" width="1000" fill="#',
                        cc.bgcols(3),
                        '"/>',
                        bst,
                        '<defs><symbol id="bss" width="100" height="100" viewBox="0 0 100 100"><circle cx="50" cy="50" r="15" fill="#',
                        cc.bgcols(5),
                        '" opacity="0.5"/><circle cx="50" cy="50" r="8" fill="#',
                        cc.bgcols(5),
                        '"/><path d="M0,50 h100 M50,0 v100" style="fill:none;stroke:#',
                        cc.bgcols(5),
                        ';stroke-width:5;opacity:0.6"/></symbol><symbol id="bird" width="200" height="200" viewBox="0 0 200 200"><g><path d="M50,100 l40,-5 50,-30 50,-10 -30,-5 -20,8 -18,0 -48,18 z"/><polygon points="125,58 70,130 75,78 125,58 140,110 75,78"><animate attributeName="points" values="125,58 70,130 75,78 125,58 140,110 75,78;125,58 50,40 75,78 125,58 120,40 75,78;125,58 70,130 75,78 125,58 140,110 75,78" dur="2s" repeatCount="indefinite"/></polygon><animateTransform attributeName="transform" attributeType="XML" type="translate" values="0,-10;0,10;0,-10" dur="2s" repeatCount="indefinite"/></g></symbol></defs><circle cx="720" cy="160" r="80" style="fill:#',
                        cc.bgcols(1),
                        ';stroke:none"/><use href="#bss" x="100" y="80"><animate attributeName="opacity" values="0.3;1;0.3" dur="7s" repeatCount="indefinite"/></use><g><use href="#bird" fill="#',
                        cc.bgcols(0),
                        '"/><animateTransform attributeName="transform" attributeType="XML" type="translate" values="-300,200;1050,30" dur="30s" repeatCount="indefinite"/></g>'
                    )
                )
            );
        }
        // Star Trails
        else if (idx == 3) {
            return (
                string(
                    abi.encodePacked(
                        '<rect height="1000" width="1000" fill="#',
                        cc.bgcols(6),
                        '"/><defs><g id="b3"><circle r="150" style="fill:none;stroke:#',
                        cc.bgcols(1),
                        ';stroke-width:5;stroke-dasharray:30,70"/><circle r="200" style="fill:none;stroke:#',
                        cc.bgcols(7),
                        ';stroke-width:5;stroke-dasharray:50,80"/><circle r="300" style="fill:none;stroke:#',
                        cc.bgcols(1),
                        ';stroke-width:5;stroke-dasharray:60,120"/><circle r="380" style="fill:none;stroke:#',
                        cc.bgcols(1),
                        ';stroke-width:5;stroke-dasharray:70,100"/><circle r="450" style="fill:none;stroke:#',
                        cc.bgcols(7),
                        ';stroke-width:5;stroke-dasharray:75,160"/><circle r="560" style="fill:none;stroke:#',
                        cc.bgcols(7),
                        ';stroke-width:5;stroke-dasharray:80,190"/><circle r="620" style="fill:none;stroke:#',
                        cc.bgcols(1),
                        ';stroke-width:5;stroke-dasharray:80,190"/><circle r="680" style="fill:none;stroke:#',
                        cc.bgcols(1),
                        ';stroke-width:5;stroke-dasharray:87,185"/><circle r="750" style="fill:none;stroke:#',
                        cc.bgcols(7),
                        ';stroke-width:5;stroke-dasharray:120,200"/><circle r="800" style="fill:none;stroke:#',
                        cc.bgcols(1),
                        ';stroke-width:5;stroke-dasharray:100,220"/><circle r="900" style="fill:none;stroke:#',
                        cc.bgcols(7),
                        ';stroke-width:5;stroke-dasharray:100,220"/><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0,0,0" to="360,0,0" dur="100s" repeatCount="indefinite"/></g></defs><use x="800" y="500" href="#b3"/>'
                    )
                )
            );
        }
        // Radar
        else if (idx == 4) {
            return (
                string(
                    abi.encodePacked(
                        '<defs><linearGradient id="bl4" gradientTransform="rotate(-45)"><stop offset="0%" stop-color="#',
                        cc.bgcols(6),
                        '"/><stop offset="50%" stop-color="#',
                        cc.pwcols(7),
                        '"/></linearGradient></defs><rect height="1000" width="1000" fill="#',
                        cc.bgcols(6),
                        '"/><path d="M500,500 l0,-560 a560,560 0,0,0 -560,560 l560,0 z" fill="url(#bl4)" opacity="0.8" stroke="none"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 500 500" to="360 500 500" dur="3s" repeatCount="indefinite"/></path><circle cx="500" cy="500" r="560" style="fill:#',
                        cc.pwcols(7),
                        ';opacity:0.3"/><g style="fill:none;stroke:#',
                        cc.pwcols(7),
                        ';stroke-width:5"><circle cx="500" cy="500" r="380"/><circle cx="500" cy="500" r="440"/><circle cx="500" cy="500" r="500"/><circle cx="500" cy="500" r="560"/><path d="M500,0 l0,1000 M0,500 l1000,0"/></g><circle cx="500" cy="500" r="550" style="fill:none;stroke:#',
                        cc.pwcols(7),
                        ';stroke-width:20;stroke-dasharray:4,20"/><g><circle cx="0" cy="0" r="20" style="fill:none;stroke:#',
                        cc.blc1(1),
                        ';stroke-width:10;opacity:0.5"><animate attributeName="r" dur="1s" values="20;60" repeatCount="indefinite"/></circle><circle cx="0" cy="0" r="10" style="fill:#',
                        cc.blc1(1),
                        '"><animate attributeName="opacity" dur="0.4s" values="0;1;0" repeatCount="indefinite"/></circle><animateMotion dur="60s" repeatCount="indefinite" path="M150,100 q130,150 350,100 q30,-50 200,-150 q150,0 130,180 q-50,80 -380,-140 q-150,-80 -300,10"></animateMotion></g>'
                    )
                )
            );
        }
        // Staturn
        else if (idx == 5) {
            return (
                string(
                    abi.encodePacked(
                        '<rect height="1000" width="1000" fill="#',
                        cc.bgcols(6),
                        '"/><defs><mask id="b5m"><circle cx="0" cy="0" r="250" fill="#fff"/><path d="M-86.6,50 a99,99 0,0,1 173,-100 z" fill="black"/></mask><g id="b5s" transform="scale(1,1)"><circle cx="0" cy="0" r="100" fill="#',
                        cc.prcols(0),
                        '"></circle><mask id="b5c"><circle cx="0" cy="0" r="100" fill="#fff"/></mask><g mask="url(#b5c)" style="fill:none;stroke:#',
                        cc.prcols(2),
                        ';stroke-width:20"><path d="M-120,30 a250,100 -30,0,0 250,-120"/><path d="M-120,-20 a250,100 -30,0,0 250,-120"/></g><g mask="url(#b5c)" style="fill:none;stroke:#',
                        cc.prcols(3),
                        ';stroke-width:20"><path d="M-120,120 a250,100 -30,0,0 250,-120"/></g><g mask="url(#b5m)"><circle cx="0" cy="0" r="70" style="fill:none;stroke:#',
                        cc.prcols(1),
                        ';stroke-width:20" transform="skewX(-60)"/><circle cx="0" cy="0" r="90" style="fill:none;stroke:#',
                        cc.prcols(1),
                        ';stroke-width:10" transform="skewX(-60)"/></g><circle cx="300" cy="500" r="30" fill="#',
                        cc.prcols(3),
                        '"/><circle cx="-100" cy="750" r="25" fill="#',
                        cc.prcols(2),
                        '"/><circle cx="-700" cy="450" r="20" fill="#',
                        cc.prcols(3),
                        '"/><circle cx="-600" cy="50" r="28" fill="#',
                        cc.prcols(1),
                        '"/></g></defs><use href="#b5s"><animateMotion dur="60s" repeatCount="indefinite" path="M150,200 C200,150 650,20 800,200 C800,300 100,300 150,200 z"/></use>'
                    )
                )
            );
        }
        // Meteor shower
        else if (idx == 6) {
            return (
                string(
                    abi.encodePacked(
                        '<rect height="1000" width="1000" fill="#',
                        cc.bgcols(3),
                        '"/><defs><linearGradient id="b6g"><stop offset="0%" stop-color="#',
                        cc.bgcols(5),
                        '"/><stop offset="95%" stop-color="#',
                        cc.bgcols(3),
                        '" /></linearGradient></defs>',
                        bst,
                        '<defs><path id="b6s" d="M0,0 a8,8 0,1,0 0,8 l400,-2 v-4 l-400,-2 z" fill="url(#b6g)" transform="rotate(-30)"/></defs><use href="#b6s"><animateMotion dur="3s" repeatCount="indefinite" path="M500,-50 l-900,519"></animateMotion></use><use href="#b6s"><animateMotion dur="3.2s" repeatCount="indefinite" path="M800,-50 l-1200,692"></animateMotion></use><use href="#b6s"><animateMotion dur="3.4s" repeatCount="indefinite" path="M1050,100 l-1400,808"></animateMotion></use><use href="#b6s"><animateMotion dur="3.15s" repeatCount="indefinite" path="M1050,600 l-1400,808"></animateMotion></use><use href="#b6s"><animateMotion dur="2.8s" repeatCount="indefinite" path="M1050,400 l-1400,808"></animateMotion></use>'
                    )
                )
            );
        }
        // DNA
        else if (idx == 7) {
            return (
                string(
                    abi.encodePacked(
                        '<rect height="1000" width="1000" fill="#',
                        cc.bgcols(4),
                        '"/><defs><pattern id="b7g" viewBox="0,0,200,400" width="20%" height="20%"><path d="M0,20 h100 M16,60 h70 M16,140 h70 M0,180 h100 M0,220 h100 M16,260 h70 M16,340 h70 M0,380 h100" style="fill:none;stroke:grey;stroke-width:5"/><path d="M0,0 c0,100 100,100 100,200" style="fill:none;stroke:#',
                        cc.blc0(0),
                        ';stroke-width:10"/><path d="M100,0 c0,100 -100,100 -100,200 c0,100 100,100 100,200" style="fill:none;stroke:#',
                        cc.blc0(2),
                        ';stroke-width:10"/><path d="M100,200 c0,100 -100,100 -100,200" style="fill:none;stroke:#',
                        cc.blc0(0),
                        ';stroke-width:10"/></pattern></defs><g><rect width="1400" height="1400" fill="url(#b7g)"/><animateTransform attributeName="transform" attributeType="XML" type="translate" from="0,0" to="0,-280" dur="5s" repeatCount="indefinite"/></g>'
                    )
                )
            );
        }
        // ECG
        else if (idx == 8) {
            return (
                string(
                    abi.encodePacked(
                        '<rect height="1000" width="1000" fill="#',
                        cc.bgcols(4),
                        '"/><defs><pattern id="b8p" viewBox="0,0,40,80" width="10%" height="25%"><path d="M0,60 l2,0 3,-10 3,15 q5,-10 6,20 l2,-60 2,45 2-5 q10,0 10,2 l2,-7 12,0" style="fill:none;stroke:#',
                        cc.blc1(1),
                        ';stroke-width:2"/></pattern><pattern id="b8a" viewBox="0,0,50,50" width="4%" height="4%"><path d="M50,0 l0,50 -50,0" style="fill:none;stroke:#',
                        cc.blc0(1),
                        ';stroke-width:2"/></pattern><pattern id="b8b" viewBox="0,0,50,50" width="8%" height="8%"><path d="M50,0 l0,50 -50,0" style="fill:none;stroke:#',
                        cc.blc0(1),
                        ';stroke-width:2"/></pattern></defs><rect width="1000" height="1000" style="fill:url(#b8a)"/><rect width="1000" height="1000" style="fill:url(#b8b)"/><rect y="-30" width="1200" height="1000" style="fill:url(#b8p)"><animateTransform attributeName="transform" attributeType="XML" type="translate" values="0,0;-120,0" dur="3s" repeatCount="indefinite"/></rect>'
                    )
                )
            );
        } else return "";
    }
}