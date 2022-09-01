/**
 *Submitted for verification at Etherscan.io on 2022-09-01
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

library TransferHelper {
    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }
}

contract ICO {
    address public immutable USDT=0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public  fomobfc=0x0000000000000000000000000000000000000000;
    address payable public owner;
    address public DAO=0x315d04F9B9e62A6f5B9746159185CB8Db754D3A2;
    uint256 public buy1=0;
    mapping(address => bool) public hasbuy;
    

     constructor() {
        owner = payable(msg.sender);
       
    }
     function buy1num()public view returns (uint256 buy){
         buy=buy1;
         return buy;
     }
     function setfomobfc(address add)public {
         require(msg.sender == owner);
         fomobfc=add;
     }
     function buy20() public{
        require(!_isContract(msg.sender), "cannot be a contract");
        require (buy1<=1000);
        require(hasbuy[msg.sender]==false);
        TransferHelper.safeTransferFrom(USDT, msg.sender, DAO,20*1e6);
        TransferHelper.safeTransfer(fomobfc,msg.sender,0*1e6);
        buy1+=1;
       hasbuy[msg.sender]=true;
    }
    
    function withdraw(uint amount) public {
        require(msg.sender == owner);
        owner.transfer(amount);
    }
    function withdrawToken(address token,uint256 amount) public {
        require(msg.sender == owner);
        TransferHelper.safeTransfer(token,msg.sender,amount);
    }
     receive() payable external {
    }
        // 是否合约地址
    function _isContract(address _addr) private view returns (bool ok) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }
    function setOwner(address payable new_owner) public {
        require(msg.sender == owner);
        owner = new_owner;
    }
    
    function setDAO(address new_DAO) public {
        require(msg.sender == owner);
        DAO= new_DAO ;
    }
  
    
}