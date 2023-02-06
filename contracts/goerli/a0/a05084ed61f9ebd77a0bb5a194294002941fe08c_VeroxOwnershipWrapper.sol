/**
 *Submitted for verification at Etherscan.io on 2023-02-06
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface AnyToken {
    function transferFrom(address, address, uint) external returns (bool);
    function transfer(address, uint) external returns (bool);
}

interface IVEROX_MAKER {
    function transferAnyERC20Tokens(address _tokenAddr, address _to, uint _amount) external;
}

contract VeroxOwnershipWrapper {
    
    address public owner;
    AnyToken public veroxToken = AnyToken(0x1799d4371fd80B7ECEf7e895a8cFD3bBD3351d7E);
    IVEROX_MAKER public maker = IVEROX_MAKER(0x40Bc3225D5C72C698801e136D991f1CE2d2cBbBc);
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
  constructor() {
    owner = msg.sender;
  }
  
  function transferOwnership(address newOwner) public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
  
    function transferAnyTokensFromMaker(address _tokenAddr, address _to, uint _amount) public {
        require(msg.sender == owner);
        require(_tokenAddr != address(veroxToken), "Not allowed for Verox token");
        maker.transferAnyERC20Tokens(_tokenAddr, _to, _amount);
    }

    // function to allow admin to claim *any* ERC20 tokens sent to this contract
    function transferAnyTokensFromThis(address _tokenAddr, address _to, uint _amount) public {
        require(msg.sender == owner);
        AnyToken(_tokenAddr).transfer(_to, _amount);
    }
}