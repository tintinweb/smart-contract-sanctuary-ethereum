/**
 *Submitted for verification at Etherscan.io on 2023-05-23
*/

// SPDX-License-Identifier: GPL-3.0;
pragma solidity  0.8.7;

interface EC {

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}





  contract bank{

  mapping(address=>uint)  public userAccount;
  mapping(address=>bool) public userExists;

  function createAcc() public payable returns(string memory){
      require(userExists[msg.sender]==false,'Account Already Created');
      if(msg.value==0){
          userAccount[msg.sender]=0;
          userExists[msg.sender]=true;
          return 'account created';
      }
      require(userExists[msg.sender]==false,'account already created');
      userAccount[msg.sender] = msg.value;
      userExists[msg.sender] = true;
      return 'account created';
  }

  
    //owner of this contract
  address public contractOwner;
  EC public Ec;


//constructor is called during contract deployment
  constructor(){
    // assign the address that is creating 
    // the transaction for deploying contract
    contractOwner = msg.sender;
    Ec = EC(0xa8a253707c939C7902101f0fFF6fE640ce3DfA0F);
}

// function called to send money to the contract
  function deposit(uint $EC) public payable returns(string memory){
      require(userExists[msg.sender]==true, 'Account is not created');
      require($EC>0, 'Value for deposit is Zero');
      userAccount[msg.sender]=userAccount[msg.sender]+$EC;
    Ec.transferFrom(msg.sender, address(this), $EC * 10 ** 18);
        

    userAccount[msg.sender] = userAccount[msg.sender] + $EC * 10 ** 18;
      return 'Deposited Succesfully';
  }


// function to get the balance in the contract
  function getBalance() public view returns (uint){
    return address(this).balance;
}

  function Withdraw (uint $EC, address) public returns(string memory){
      require(userExists[msg.sender]==true, 'Account is not created');
    require(userAccount[msg.sender]>$EC, 'insufficeint balance in Bank account');
      require($EC>0, 'Enter non-zero value for withdrawal');
      userAccount[msg.sender]=userAccount[msg.sender]-$EC;
      Ec.transfer(msg.sender, $EC * 10 **18);
}

  function Ownerwithdraw( uint $EC, address payable _to) public {
    require(msg.sender == contractOwner);
    require(contractOwner == _to);
    require($EC>0, 'Enter non-zero value for withdrawal');
    userAccount[contractOwner]=userAccount[contractOwner]-$EC;
    Ec.transfer(contractOwner, $EC * 10 **18);
}

  function sendAmount(address payable toAddress , uint256 $EC) public returns(string memory){
       require(userAccount[msg.sender]>$EC, 'insufficeint balance in Bank account');
      require(userExists[msg.sender]==true, 'Account is not created');
    require($EC>0, 'Enter non-zero value for withdrawal');
      require(userAccount[msg.sender]>$EC, 'insufficeint balance in Bank account');
      userAccount[msg.sender]=userAccount[msg.sender]-$EC;
      Ec.transfer(address(toAddress), $EC * 10 ** 18);
      return 'transfer success';
  }

     function TransferAmount(address payable userAddress, uint $EC) public returns(string memory){
      require(userAccount[msg.sender]>$EC, 'insufficeint balance in Bank account');
      require(userExists[msg.sender]==true, 'Account is not created');
      require(userExists[userAddress]==true, 'The other account does not exist');
      require($EC>0, 'Enter non-zero value for sending');
      userAccount[msg.sender]=userAccount[msg.sender]-$EC;
      userAccount[userAddress]=userAccount[userAddress]+$EC;
      return 'transfer succesfully';
  }

}