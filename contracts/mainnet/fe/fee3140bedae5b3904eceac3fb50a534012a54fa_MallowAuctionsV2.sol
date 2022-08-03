// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ECDSA.sol";
import "./LOVE.sol";
import "./Strings.sol";

contract MallowAuctionsV2 is Ownable{

    event buy(address indexed _wallet, uint256 indexed _auctionId, uint256 indexed _price);
    address signer = 0xeFB45a786C8A9fE6D53DdE0E3A4DB6aF54C73DA7;

    LOVE public loveContract;   

    function setDependencies(address _loveAddress) external onlyOwner{
        loveContract = LOVE(_loveAddress);
    }
  
    function updateSigner(address _newSigner) external onlyOwner{
        signer = _newSigner;
    }
    
    function spendLove(uint256 _auctionId, uint256 _price, bytes calldata _signature) external {
        require(ECDSA.recover(keccak256(abi.encodePacked(_auctionId, msg.sender, _price)), _signature) == signer, "INVALID SIGNATURE");
        loveContract.burn(msg.sender, _price * 1 ether);
        emit buy(msg.sender, _auctionId, _price);
    }
    
    

}