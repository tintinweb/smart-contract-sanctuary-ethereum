// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;
import "./Ownable.sol";

contract FountainTokenInterface is Ownable {
    function mint(
        address to, 
        uint256 _mintAmount
    ) public payable  {}
}

contract EggAirDrop is Ownable {
    string public name = "JXBXAirdrop";
    uint256 private mintAmount = 5;
    FountainTokenInterface fountain = FountainTokenInterface(0x8ab93F6e98D30379606b39a849f980FdC9430938);
    
    function airDrop(
        address[] memory _addresses
    ) public payable onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            fountain.mint(_addresses[i], mintAmount);
        }
    }

    function setAmount(uint256 _amount) public onlyOwner {
        mintAmount = _amount;
    }
}