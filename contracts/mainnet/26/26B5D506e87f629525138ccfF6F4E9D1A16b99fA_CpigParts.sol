//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./CpigColor.sol";

contract CpigParts {
    address addrColor;

    constructor(address _addrColor) {
        addrColor = _addrColor;
    }

    // Eyes
    function genEyes(
        string memory tokenId,
        uint8 idx,
        uint8 sidx
    ) external view returns (string memory) {
        CpigColor cc = CpigColor(addrColor);

        string memory bmsk = string(
            abi.encodePacked(
                '<mask id="esk"><ellipse cx="320" cy="500" rx="70" ry="80" fill="#',
                cc.bgcols(1),
                '"><animate attributeName="ry" dur="5s" values="80;1;80;80" keyTimes="0;0.02;0.03;1" repeatCount="indefinite"/></ellipse><ellipse cx="680" cy="500" rx="70" ry="80" fill="#',
                cc.bgcols(1),
                '"><animate attributeName="ry" dur="5s" values="80;1;80;80" keyTimes="0;0.02;0.04;1" repeatCount="indefinite"/></ellipse></mask>'
            )
        );

        // Galaxy
        if (idx == 0) {
            string memory e0id = string(abi.encodePacked("e0", tokenId));
            return (
                string(
                    abi.encodePacked(
                        bmsk,
                        '<defs><path id="e0" d="M0,0 a15,15 0,0,0 -15,15 a20,-20 0,0,0 20,20 a30,30 0,0,0 30,-30 a40,40 0,0,0 -40,-40 a60,60 0,0,0 -60,60 v-15 a60,60 0,0,1 60,-60 a50,50 0,0,1 50,50 a40,40 0,0,1 -40,40 a25,25 0,0,1 -25,-25 a20,20 0,0,1 20,-20 z" /><g id="e0a" transform="scale(0.6,0.6)"><g><use href="#e0"/><use href="#e0" x="0" y="-20" transform="rotate(180)"/><animateTransform attributeName="transform" attributeType="XML" type="rotate" values="0,0,10;360,0,10" dur="20s" repeatCount="indefinite"/></g></g></defs><g mask="url(#esk)"><g id="',
                        e0id,
                        '"><ellipse cx="320" cy="500" rx="70" ry="80" fill="#',
                        cc.bgcols(0),
                        '"/><use x="320" y="495" href="#e0a" fill="#',
                        cc.pwcols(sidx),
                        '"/><circle cx="320" cy="500" r="8" fill="#',
                        cc.bgcols(1),
                        '"/></g><use x="360" href="#',
                        e0id,
                        '"/></g>'
                    )
                )
            );
        }
        // Blink
        else if (idx == 1) {
            return (
                string(
                    abi.encodePacked(
                        bmsk,
                        '<g mask="url(#esk)"><g id="e0l"><ellipse cx="320" cy="500" rx="70" ry="80" fill="#',
                        cc.bgcols(0),
                        '"/><ellipse cx="330" cy="490" rx="20" ry="20" fill="#',
                        cc.bgcols(1),
                        '"/></g><use href="#e0l" x="360"/></g>'
                    )
                )
            );
        }
        // Rolling
        else if (idx == 2) {
            return (
                string(
                    abi.encodePacked(
                        '<g id="e1l"><ellipse cx="320" cy="500" rx="70" ry="80" fill="#',
                        cc.bgcols(0),
                        '"/><ellipse cx="310" cy="490" rx="20" ry="20" fill="#',
                        cc.bgcols(1),
                        '"><animateTransform attributeName="transform" attributeType="XML" type="rotate" values="0,320,500;360,320,500" dur="5s" repeatCount="indefinite"/></ellipse></g><use href="#e1l" x="360"/>'
                    )
                )
            );
        }
        // Cute
        else if (idx == 3) {
            return (
                string(
                    abi.encodePacked(
                        bmsk,
                        '<g mask="url(#esk)"><g id="e2l"><ellipse cx="320" cy="500" rx="70" ry="80" fill="#',
                        cc.bgcols(0),
                        '"/><circle cx="300" cy="470" r="26" fill="#',
                        cc.bgcols(1),
                        '"/><circle cx="340" cy="530" r="15" fill="#',
                        cc.bgcols(1),
                        '"/></g><use href="#e2l" x="360"/></g>'
                    )
                )
            );
        }
        // Red Heart
        else if (idx == 4) {
            return (
                string(
                    abi.encodePacked(
                        '<defs><g id="e3h"><animateTransform attributeName="transform" attributeType="XML" type="scale" values="1,1;1.5,1.5;1,1;1.5,1.5;1,1;1,1" keyTimes="0;0.02;0.04;0.06;0.08;1" dur="5s" repeatCount="indefinite"/><path d="M-60,0 a30,30 0,0,1 60,0 a30,30 0,0,1 60,0 q0,45 -60,90 q-60,-45 -60,-90 z" fill="#',
                        cc.blc1(0),
                        '"/></g></defs><use href="#e3h" x="320" y="470"/><use href="#e3h" x="680" y="470"/>'
                    )
                )
            );
        }
        // Star
        else if (idx == 5) {
            return (
                string(
                    abi.encodePacked(
                        bmsk,
                        '<g mask="url(#esk)"><g id="e5l"><ellipse cx="320" cy="500" rx="70" ry="80" fill="#',
                        cc.bgcols(0),
                        '"/><path d="M300,500 q20,-20 20,-40 q0,20 20,40 q-20,20 -20,40 q0,-20 -20,-40 z" fill="#',
                        cc.bgcols(1),
                        '"/></g><use href="#e5l" x="360"/></g>'
                    )
                )
            );
        }
        //Wink
        else if (idx == 6) {
            return (
                string(
                    abi.encodePacked(
                        '<mask id="e8m0"><ellipse cx="320" cy="500" rx="70" ry="80" fill="#fff"/></mask><mask id="e8m1"><ellipse cx="320" cy="500" rx="70" ry="80" fill="#fff"><animate attributeName="ry" dur="5s" values="80;1;1;80;80" keyTimes="0;0.02;0.22;0.24;1" repeatCount="indefinite"/></ellipse></mask><path mask="url(#e8m0)" d="M240,520 a50,25 0,0,1 160,0 a50,10 0,0,0 -160,0" fill="#',
                        cc.bgcols(0),
                        '"/><g mask="url(#e8m1)"><ellipse cx="320" cy="500" rx="70" ry="80" fill="#',
                        cc.bgcols(0),
                        '" opacity="1"/><ellipse id="e8l" cx="330" cy="500" rx="20" ry="20" fill="#',
                        cc.bgcols(1),
                        '"><animateTransform attributeName="transform" attributeType="XML" type="translate" values="0,0;0,-25;0,-25;0,0;0,0" keyTimes="0;0.02;0.22;0.24;1" dur="5s" repeatCount="indefinite"/></ellipse></g><ellipse cx="680" cy="500" rx="70" ry="80" fill="#',
                        cc.bgcols(0),
                        '"/><use href="#e8l" x="360"/>'
                    )
                )
            );
        }
        // Cyborg
        else if (idx == 7) {
            return (
                string(
                    abi.encodePacked(
                        bmsk,
                        '<g mask="url(#esk)"><g id="e6l"><circle cx="320" cy="500" r="60" style="fill:#',
                        cc.blc0(2),
                        '"/><circle cx="320" cy="500" r="50" style="fill:none;stroke:#',
                        cc.bgcols(4),
                        ';stroke-width:10;stroke-dasharray:4,18"><animateTransform attributeName="transform" attributeType="XML" type="rotate" values="0,320,500;360,320,500" dur="30s" repeatCount="indefinite"/></circle><circle cx="320" cy="500" r="40" style="fill:none;stroke:#',
                        cc.blc1(2),
                        ';stroke-width:6;"/><circle cx="320" cy="500" r="30" style="fill:none;stroke:#',
                        cc.bats(0),
                        ';stroke-width:6;stroke-dasharray:10,10"><animateTransform attributeName="transform" attributeType="XML" type="rotate" values="0,320,500;-360,320,500" dur="30s" repeatCount="indefinite"/></circle><circle cx="320" cy="500" r="20" style="fill:#',
                        cc.bgcols(1),
                        '"/></g><use href="#e6l" x="360"/></g>'
                    )
                )
            );
        }
        // Lazer
        else return "";
    }

    // Hat
    function genHat(
        string memory tokenId,
        uint8 idx,
        uint8 sidx
    ) external view returns (string memory) {
        CpigColor cc = CpigColor(addrColor);

        // Pinwheels
        if (idx == 0) {
            return (
                string(
                    abi.encodePacked(
                        '<line x1="500" y1="260" x2="500" y2="120" stroke="#',
                        cc.bgcols(0),
                        '" stroke-width="10"/><g><path d="M500,130 l0,-100 q80,30 0,100 l0,100 q-80,-30 0,-100 l100,0 q-30,80 -100,0 l-100,0 q30,-80 100,0 z" style="fill:#',
                        cc.pwcols(sidx),
                        ";stroke:#",
                        cc.bgcols(0),
                        ';stroke-width:10;"/><animateTransform attributeName="transform" attributeType="XML" type="rotate" values="0,500,130;360,500,130" dur="3s" repeatCount="indefinite"/></g>'
                    )
                )
            );
        }
        // Party Hat
        else if (idx == 1) {
            return (
                string(
                    abi.encodePacked(
                        '<defs><pattern id="h4',
                        tokenId,
                        '" viewBox="-20,-20,40,40" width="28%" height="28%"><rect x="-12" y="-12" width="5" height="24" fill="#',
                        cc.bhc1(sidx),
                        '"/><ellipse cx="10" rx="6" ry="10" style="fill:none;stroke:#',
                        cc.bhc1(sidx),
                        ';stroke-width:5"/></pattern></defs><path d="M400,260 l200,0 -100,-200 -100,200 z" style="fill:#',
                        cc.bhc0(sidx),
                        '"/><path d="M400,260 l200,0 -100,-200 -100,200 z" fill="url(#h4',
                        tokenId,
                        ')"/><path d="M400,260 l200,0 -100,-200 -100,200 z" style="fill:none;stroke:#',
                        cc.bgcols(0),
                        ';stroke-width:10"/><circle cx="500" cy="60" r="20" style="fill:#',
                        cc.bhc0(sidx),
                        ";stroke:#",
                        cc.bgcols(0),
                        ';stroke-width:10"/>'
                    )
                )
            );
        }
        // Black Standing Hair
        else if (idx == 2) {
            return (
                string(
                    abi.encodePacked(
                        '<path d="M450,260 a20,40 -20,0,1 -10,-120 a10,10 0,1,1 -20,30 M500,260 a30,60 0,0,1 0,-160 a20,20 0,0,1 -20,40 M530,260 a20,40 0,0,1 10,-120 a10,10 0,1,1 -20,30" style="fill:none;stroke:#',
                        cc.bgcols(0),
                        ';stroke-width:10;stroke-linecap:round"/>'
                    )
                )
            );
        }
        // Black Side Parting
        else if (idx == 3) {
            return (
                string(
                    abi.encodePacked(
                        '<path d="M470,260 a12,30 -10,0,1 60,80 M500,260 a10,30 -10,0,1 60,80 M530,260 a12,30 -10,0,1 60,80" style="fill:none;stroke:#',
                        cc.bgcols(0),
                        ';stroke-width:10;stroke-linecap:round"/>'
                    )
                )
            );
        }
        // Antenna
        else if (idx == 4) {
            return (
                string(
                    abi.encodePacked(
                        '<polyline points="340,90 500,250 660,90" style="fill:none;stroke:#',
                        cc.bgcols(0),
                        ';stroke-width:10;stroke-linecap:round"/><polyline points="410,160 500,250 590,160" style="fill:none;stroke:#',
                        cc.bgcols(0),
                        ';stroke-width:20;stroke-linecap:round"/>'
                    )
                )
            );
        }
        //Green Lollipop
        else if (idx == 5) {
            return (cc.genLlp(0));
        }
        //Blue Lollipop
        else if (idx == 6) {
            return (cc.genLlp(1));
        }
        // Gold Standing Hair
        else if (idx == 7) {
            return (
                string(
                    abi.encodePacked(
                        '<path d="M450,255 a20,40 -20,0,1 -10,-120 a10,10 0,1,1 -20,30 M500,255 a30,60 0,0,1 0,-160 a20,20 0,0,1 -20,40 M530,255 a20,40 0,0,1 10,-120 a10,10 0,1,1 -20,30" style="fill:none;stroke:gold;stroke-width:10;stroke-linecap:round"/>'
                    )
                )
            );
        }
        // Gold Side Parting
        else if (idx == 8) {
            return (
                string(
                    abi.encodePacked(
                        '<path d="M470,255 a12,30 -10,0,1 60,80 M500,255 a10,30 -10,0,1 60,80 M530,255 a12,30 -10,0,1 60,80" style="fill:none;stroke:gold;stroke-width:10;stroke-linecap:round"/>'
                    )
                )
            );
        }
        //Red Lollipop
        else if (idx == 9) {
            return (cc.genLlp(2));
        }
        // Crown
        else if (idx == 10) {
            return (
                string(
                    abi.encodePacked(
                        '<path d="M400,230 l200,0 0,30 -200,0 0,-30 -50,-120 q110,140 150,-40 q40,180 150,40 l-50,120 z" style="fill:gold;stroke:#',
                        cc.bgcols(0),
                        ';stroke-width:10"/><circle id="crn1" cx="350" cy="110" r="12" style="fill:gold;stroke:#',
                        cc.bgcols(0),
                        ';stroke-width:10"/><use href="#crn1" x="150" y="-45"/><use href="#crn1" x="300"/>'
                    )
                )
            );
        }

        return "";
    }
}