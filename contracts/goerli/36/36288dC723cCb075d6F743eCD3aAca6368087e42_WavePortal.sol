// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "console.sol";

contract WavePortal {
    struct Link {
        string link;
        uint256 timestamp;
        uint256 waveCount;
    }

    Link[] links;

    struct Wave {
        address waver;
        Link link;
        uint256 timestamp;
    }

    Wave[] waves;

    constructor() {
        console.log("I am a contract and I am smart!");
    }

    function wave() public {
        waves.push(Wave(msg.sender, Link("", block.timestamp, 0), block.timestamp));
        console.log("%s has waved!", msg.sender);
    }

    function getTotalWaves() view public returns (uint256) {
        console.log("We have %d total waves!", waves.length);
        return waves.length;
    }

    function getWaves() view public returns (Wave[] memory) {
        return waves;
    }

    function resetWaves() public {
        console.log("Resetting waves to 0!");
        delete waves;
    }

    function addLink(string memory _link) public {
        links.push(Link(_link, block.timestamp, 0));
        console.log("%s has added a link : %s", msg.sender, _link);
    }

    function getLinks() view public returns (Link[] memory) {
        console.log("Getting links");
        return links;
    }

    function getLink(string memory _link) view public returns (Link memory) {
        console.log("Getting link");
        for (uint i = 0; i < links.length; i++) {
            if (keccak256(abi.encodePacked(links[i].link)) == keccak256(abi.encodePacked(_link))) {
                return links[i];
            }
        }
        return Link("", 0, 0);
    }

    function getNumberOfWaveByLink(string memory _link) view public returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < waves.length; i++) {
            if (keccak256(abi.encodePacked(waves[i].link.link)) == keccak256(abi.encodePacked(_link))) {
                count++;
            }
        }
        return count;
    }

    function waveLink(string memory _link) public {
        Link memory link = getLink(_link);
        if (link.timestamp != 0) {
            waves.push(Wave(msg.sender, link, block.timestamp));
            link.waveCount++;
            console.log("%s has waved!", msg.sender);
        } else {
            console.log("Link not found");
        }
    }
}