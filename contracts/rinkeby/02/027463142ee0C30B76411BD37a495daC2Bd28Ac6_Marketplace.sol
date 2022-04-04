/**
 *Submitted for verification at Etherscan.io on 2022-04-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface Raccoin {
    function burn(address _account, uint256 _amount) external;
    function balance(address _account) external view returns(uint256);
}

interface Raccools {
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
}

contract Marketplace {
    function buy(uint256[] memory _tokenIds) external {
        address raccoolsAddress = 0xBC8f4aC4234029AD279d0C76097275dC75c186F4;
        address raccoinAddress = 0x07cB25967a8601EBa2d28B3bf448AAD11b1E9f39;
        address owner = 0xE282f83e89D14eaeBc3a681D7D82cF743028b178;
        uint256 cost = 2;
        uint256 amount = _tokenIds.length;
        
        require(Raccoin(raccoinAddress).balance(msg.sender) >= amount * cost);

        Raccoin(raccoinAddress).burn(msg.sender, amount * cost);
        
        for(uint i=0; i < amount; i++){
            Raccools(raccoolsAddress).safeTransferFrom(owner, msg.sender, _tokenIds[i]);
        }
    }
}