pragma solidity 0.8.12;

import "./ERC721.sol";

contract AirdropHelper{
    address constant Owner = 0xcc5cDaB325689Bcd654aB8611c528e60CC8CBe6A;
    ERC721 constant LV = ERC721(0x9df8Aa7C681f33E442A0d57B838555da863504f3);

    mapping(address => uint) wl;

    constructor(address[] memory _wl, uint[] memory tokenIds) {
        require(_wl.length == tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            wl[_wl[i]] = tokenIds[i];
        }
    }

    function mint() public payable {
        require(msg.value == 0.44 ether, "Minting requires 0.44 ETH");
        require(wl[msg.sender] != 0, "You are not on the whitelist");

        // Remove from whitelist
        wl[msg.sender] = 0;


        // Transfer the tokenId they were assigned
        LV.transferFrom(Owner, msg.sender, wl[msg.sender]);
    }

    function withdraw() public {
        require(msg.sender == Owner);
        (bool success, ) = Owner.call{value: address(this).balance}("");
        require(success);
    }
}