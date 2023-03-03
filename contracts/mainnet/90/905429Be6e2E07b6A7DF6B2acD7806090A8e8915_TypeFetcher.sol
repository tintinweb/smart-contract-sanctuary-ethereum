/**
 *Submitted for verification at Etherscan.io on 2023-03-02
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface ERC20Like {
    function totalSupply() external view returns (uint256);
}

contract TypeFetcher {
    function getType(address addr) external view returns (string memory) {
        if (addr.code.length == 0) {
            return 'EOA';
        }
        try IERC165(addr).supportsInterface(0x80ac58cd) returns (bool isERC721) {
            if (isERC721) {
                return 'ERC721';
            }
            if (IERC165(addr).supportsInterface(0xd9b67a26)) {
                return 'ERC1155';
            }
        } catch {}

        try ERC20Like(addr).totalSupply() {
            return 'ERC20';
        } catch {
            return 'UNKNOWN';
        }
    }
}