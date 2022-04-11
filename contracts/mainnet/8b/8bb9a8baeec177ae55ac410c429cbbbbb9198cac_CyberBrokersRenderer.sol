/**
 *Submitted for verification at Etherscan.io on 2022-04-11
*/

pragma solidity ^0.8.0;

interface Renderer {
    function renderBroker(uint256, uint256) external view returns (string memory, uint256);
}

contract CyberBrokersRenderer {
    Renderer renderer = Renderer(0xEC3e38e536AD4fA55a378B14B257976148b618aC);

    function renderBroker(uint256 tokenId) public view returns (string memory) {
        uint256 idx = 0;
        string memory svg = '';
        while (true) {
            (string memory svg0, uint256 nidx) = renderer.renderBroker(tokenId, idx);

            svg = string.concat(svg, svg0);

            idx = nidx;
            if (idx == 0) {
                break;
            }
        }

        return svg;
    }

    function renderBroker(uint256 tokenId, uint256 iterations) public view returns (string memory) {
        uint256 idx = 0;
        string memory svg = '';
        uint256 iter = 0;
        while (true) {
            (string memory svg0, uint256 nidx) = renderer.renderBroker(tokenId, idx);

            svg = string.concat(svg, svg0);

            idx = nidx;
            if (idx == 0) {
                break;
            }
            iter ++;
            if (iter == iterations) {
                break;
            }
        }

        return svg;
    }
}