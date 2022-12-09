/**
 *Submitted for verification at Etherscan.io on 2022-12-09
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.0 <0.9.0;
contract Will {
     event PayeeAdded(address account, uint256 shares);
address owner;
    address payable [] public recipients;
      mapping(address => uint256) public _shares;
      mapping(address => uint256) public age;
      uint  contractTime = block.timestamp;


    
    uint fortune;
    bool deceased;
    uint256 _totalShares ;
     event TransferReceived(address _from, uint _amount);
    
    constructor(address payable [] memory _addrs, uint256[] memory _share, uint[] memory _age) payable  {
         require(_addrs.length == _share.length, "PaymentSplitter: payees and shares length mismatch");
        require(_addrs.length > 0, "PaymentSplitter: no payees");
        require(_addrs.length == _age.length, "length mismatch");
        
        owner = msg.sender;
        fortune = msg.value;
        deceased = false;
        for (uint256 i = 0; i < _addrs.length; i++) {
            recipients.push(_addrs[i]);
            _shares[_addrs[i]] = _share[i];
            require(_age[i] > contractTime,"age is not reached to claim");
        age[_addrs[i]] = _age[i];

        }
       
     
  }
   
       receive() payable external mustBeDeceased{
           
        uint256 share = fortune; 
        

        for(uint i=0; i < recipients.length; i++){
            uint amount = share *_shares[recipients[i]]/100;
             recipients[i].transfer(amount);
        
        }    
        emit TransferReceived(msg.sender, msg.value);
    }      
 
   
   
   
    function hasDeceased() public onlyOwner {
        deceased = true;
    }
    function getTimeStamp() public view returns(uint256){
        return block.timestamp +100;
    }


function checkShares( address payable account) public view returns (uint256){
    return _shares[account];
}
function checkAge( address payable account) public view returns (uint256){
    return age[account];

}
  modifier onlyOwner{
        require(msg.sender == owner);
        _;
    }
     modifier mustBeDeceased{
        require(deceased == true);
        _;
    }


}