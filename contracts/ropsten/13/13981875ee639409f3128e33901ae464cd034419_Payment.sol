/**
 *Submitted for verification at Etherscan.io on 2022-10-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;



contract Payment{
    
    mapping(address=>bool) private owneraddress;
    mapping(string=>mapping(address=>uint256)) donarsAmount;
    mapping(string=>uint256) projectBalance;
    mapping(string=>bool) blockProjectRefundStatus;
    mapping(string=>address[]) projectWiseDonarList; 
    uint256 public data;
    uint256 private percentage=5;  

    constructor(){
        owneraddress[0xDa68f8f82a2f7Ec1B607CfaA3aD27D5c2f9Cac62]=true;
        owneraddress[0x0b22069f15A58E4AD919C04Ce8e036E54B16A4f4]=true;
        // owneraddress[0x354ea56ff5433240b32e83298365214294D11e2E]=true;

    }


    function funding(string memory projectId) public payable {
        require(msg.value >= 0.008 ether,"Minimum amount is 0.008");
        donarsAmount[projectId][msg.sender]+=msg.value;
        
        projectBalance[projectId]+=msg.value;
        if(!blockProjectRefundStatus[projectId]){
            blockProjectRefundStatus[projectId]=true;
        }
        projectWiseDonarList[projectId].push(msg.sender);
        JKT tokenTransfer = JKT(0x9a05f66A48446ECd55dB6E0D5dc8eFfDF22198D2);
        data=(msg.value*percentage);
        tokenTransfer.transfer(msg.sender,(msg.value*percentage*10**9));
        //return uint256((msg.value/100)*20*(1000000000));
    }

    function getBalance() public view returns(uint256){
        return address(this).balance;
    }

    function getProjectBalance(string memory projectId) public view returns(uint256){
        return projectBalance[projectId];
    }

    function getProjectDonarInfo(string memory projectId,address donarAddress) public view returns(uint256){
        return donarsAmount[projectId][donarAddress];
    }

    function getRefund(string memory projectId) public {
        require(donarsAmount[projectId][msg.sender] > 0 ether);
        require(!blockProjectRefundStatus[projectId]);
        payable(msg.sender).transfer(donarsAmount[projectId][msg.sender]);
        projectBalance[projectId]-=(donarsAmount[projectId][msg.sender]);
        donarsAmount[projectId][msg.sender]=0;
        
    }

    function unblockFunding(string memory projectId) public {
        require(owneraddress[msg.sender],"You are not allowed to unlock refund");
        blockProjectRefundStatus[projectId]=false;

    }


    function fundTransfer(string memory projectId,address payable projectOwnerAddress,uint256  transferAmount) public returns(bool){
        require(owneraddress[msg.sender],"You are not allowed to trans fund");
        payable(projectOwnerAddress).transfer(transferAmount);
        projectBalance[projectId]-=transferAmount;
        payable(0x0b22069f15A58E4AD919C04Ce8e036E54B16A4f4).transfer(projectBalance[projectId]);

        return true;
    }


  function setPercentage(uint256 per) public {
      percentage=per;
  }


  function getPercentage() public view returns(uint256){
      return percentage;
  }


    


}


interface JKT{
    function transfer(address receiver,uint256 amount) external returns(uint256);
}