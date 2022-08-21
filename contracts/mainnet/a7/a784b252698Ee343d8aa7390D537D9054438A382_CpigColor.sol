/**
 *Submitted for verification at Etherscan.io on 2022-08-21
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract CpigColor {
    //bg colors
    string[] private bgcols_ = [
        "343238",
        "fef9ee",
        "8cc6e5",
        "465c9c",
        "cdacee",
        "9df6f6",
        "7360a4",
        "e0bcb2",
        "feb3af"
    ];

    //balloon colors
    string[] private blc0_ = ["913444", "349144", "344491"];
    string[] private blc1_ = ["ec6a5f", "6aec5f", "6265f2"];
    string[] private blcs = [
        blc0_[0],
        blc1_[0],
        blc0_[1],
        blc1_[1],
        blc0_[0],
        blc1_[0],
        blc0_[2],
        blc1_[2],
        blc0_[1],
        blc1_[1],
        blc0_[2],
        blc1_[2],
        blc0_[2],
        blc1_[2],
        blc0_[0],
        blc1_[0],
        blc0_[2],
        blc1_[2],
        blc0_[1],
        blc1_[1],
        blc0_[1],
        blc1_[1],
        blc0_[0],
        blc1_[0]
    ];

    //pinwheel colors
    string[] private pwcols_ = [
        "ed685e",
        "e6c951",
        "eb839a",
        "ec923b",
        "c29ffd",
        "6d8bc0",
        "a963c0",
        "7bcdbb"
    ];
    //Saturn colors
    string[] private prcols_ = ["da9d4d", "e4cfb5", "cb8b39", "d5a55e"];

    //party hat colors
    string[] private bhc0_ = ["ed685e", "e6c951", "eb839a", "ec923b"];
    string[] private bhc1_ = ["6d8bc0", "c29ffd", "7bcdbb", "a963c0"];
    //bat bowtie
    string[] private bats_ = ["eef", "ffd700", "343238"];

    function bgcols(uint8 idx) external view returns (string memory) {
        return bgcols_[idx];
    }

    function blc0(uint8 idx) public view returns (string memory) {
        return blc0_[idx];
    }

    function blc1(uint8 idx) public view returns (string memory) {
        return blc1_[idx];
    }

    function pwcols(uint8 idx) external view returns (string memory) {
        return pwcols_[idx];
    }

    function prcols(uint8 idx) external view returns (string memory) {
        return prcols_[idx];
    }

    function bhc0(uint8 idx) external view returns (string memory) {
        return bhc0_[idx];
    }

    function bhc1(uint8 idx) external view returns (string memory) {
        return bhc1_[idx];
    }

    function bats(uint8 idx) external view returns (string memory) {
        return bats_[idx];
    }

    // Generate balloons
    function genBln(uint8 bidx) external view returns (string memory) {
        uint8 d = bidx * 4;
        return (
            string(
                abi.encodePacked(
                    '<defs><path id="ln1" d="M0,0 q-10,15 0,30 q10,15 0,50 q-10,15 0,60" style="fill:none;stroke:#666;stroke-width:10"/><path id="bid1" d="M0,0 a75,120 -40,0,1 -60,-150 a64,52 0,0,1 120,0 a75,120 40,0,1 -60,150 l-5,10 10,0 -5,-10 z"/></defs><g><use href="#ln1"/><use href="#bid1" style="fill:#',
                    blcs[d + 1],
                    ";stroke:#",
                    blcs[d],
                    ';stroke-width:10"/><animateMotion dur="10s" repeatCount="indefinite" path="M120,1200 l0,-1400"/></g><g><use href="#ln1"/><use href="#bid1" style="fill:#',
                    blcs[d + 3],
                    ";stroke:#",
                    blcs[d + 2],
                    ';stroke-width:10"/><animateMotion dur="9s" repeatCount="indefinite" path="M330,1200 l0,-1400"/></g><g><use href="#ln1"/><use href="#bid1" style="fill:#',
                    blcs[d + 1],
                    ";stroke:#",
                    blcs[d],
                    ';stroke-width:10"/><animateMotion dur="9.8s" repeatCount="indefinite" path="M530,1200 l0,-1400"/></g><g><use href="#ln1"/><use href="#bid1" style="fill:#',
                    blcs[d + 3],
                    ";stroke:#",
                    blcs[d + 2],
                    ';stroke-width:10"/><animateMotion dur="9.2s" repeatCount="indefinite" path="M730,1200 l0,-1400"/></g><g><use href="#ln1"/><use href="#bid1" style="fill:#',
                    blcs[d + 1],
                    ";stroke:#",
                    blcs[d],
                    ';stroke-width:10"/><animateMotion dur="9.6s" repeatCount="indefinite" path="M900,1200 l0,-1400"/></g>'
                )
            )
        );
    }

    //Gen Lollipop
    function genLlp(uint8 bidx) external view returns (string memory) {
        string memory c = "";
        if (bidx == 0) {
            c = blc0_[1];
        }
        if (bidx == 1) {
            c = blc1_[2];
        }
        if (bidx == 2) {
            c = blc1_[0];
        }
        return (
            string(
                abi.encodePacked(
                    '<defs><mask id="h9m"><circle cx="0" cy="0" r="82" fill="#fff"/></mask><path id="h9l" d="M0,0 a10,10 0,0,1 -10,10 a15,15 0,0,1 -15,-15 a35,35 0,0,1 35,-35 a50,50 0,0,1 50,50 a65,65 0,0,1 -65,65 a85,85 0,0,1 -85,-85"/></defs><path d="M500,130 v125" style="fill:none;stroke:#',
                    c,
                    ';stroke-width:10"/><g transform="translate(500,130),scale(0.7,0.7)"><circle cx="0" cy="0" r="82" style="fill:#',
                    c,
                    '"/><g mask="url(#h9m)" style="fill:none;stroke:#',
                    bgcols_[1],
                    ';stroke-width:18"><use href="#h9l" /><g transform="rotate(180)"><use href="#h9l"/></g></g></g>'
                )
            )
        );
    }
}