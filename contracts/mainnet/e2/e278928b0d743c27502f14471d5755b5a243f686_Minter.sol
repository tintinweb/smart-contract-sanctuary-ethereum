/**
 *Submitted for verification at Etherscan.io on 2022-04-21
*/

pragma solidity >=0.4.22 <0.6.0;

interface ToMint {
    function claim() external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}

contract Receiver {
    constructor(address payable to) public {
        ToMint erc721 = ToMint(0x4D13D387E34D412088a6428Cd360a06B533E8A8f);
        erc721.claim();
        uint256 id = erc721.tokenOfOwnerByIndex(address(this), 0);
        erc721.transferFrom(address(this), to, id);
        selfdestruct(to);
    }
}

contract Minter {
    function batchClaim(uint256 amount, address payable beneficiary) public {
        for (uint256 i = 0; i < amount; i++) {
            new Receiver(beneficiary);
        }
    }
}