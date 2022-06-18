/**
 *Submitted for verification at Etherscan.io on 2022-06-17
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;


contract ClassicDAO {
    uint256 public TokenCap;
    uint256 public totalSupply;
    string public name;
    string public symbol;
    uint8 public decimals;
    address private ownerAddy;
    address private ZeroAddress;
    //variable Declarations
    
      
    event Transfer(address indexed from, address indexed to, uint256 value);    
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event BurnEvent(address indexed burner, uint256 indexed buramount);
    event ManageMinterEvent(address indexed newminter);
    //Event Declarations 
    
    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;
    
    mapping(address => uint)minter;
    
    constructor(uint256 _TokenCap, string memory _name, string memory _symbol, uint8 _decimals){
    TokenCap = _TokenCap;
    totalSupply = 0;
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
    ownerAddy = msg.sender;
    //Deployment Constructors
    }
    
    

    
    function balanceOf(address Address) public view returns (uint256 balance){
        return balances[Address];

    }

    function approve(address delegate, uint _amount) public returns (bool) {
        allowed[msg.sender][delegate] = _amount;
        emit Approval(msg.sender, delegate, _amount);
        return true;
    }
    //Approves an address to spend your coins

    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool) {
        require(_amount <= balances[_from]);    
        require(_amount <= allowed[_from][msg.sender]);
    
        balances[_from] = balances[_from]-(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender]-(_amount);
        balances[_to] = balances[_to]+(_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }
    //Transfer From an other address


    function transfer(address _to, uint256 _amount) public returns (bool) {
        require(_amount <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender]-(_amount);
        balances[_to] = balances[_to]+(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }


    function Mint(address _MintTo, uint256 _MintAmount) public {
        require (minter[msg.sender] == 1);
        require (totalSupply+(_MintAmount) <= TokenCap);
        balances[_MintTo] = balances[_MintTo]+(_MintAmount);
        totalSupply = totalSupply+(_MintAmount);
        ZeroAddress = 0x0000000000000000000000000000000000000000;
        emit Transfer(ZeroAddress ,_MintTo, _MintAmount);
    }
    //Mints tokens to your address 


    function Burn(uint256 _BurnAmount) public {
        require (balances[msg.sender] >= _BurnAmount);
        balances[msg.sender] = balances[msg.sender]-(_BurnAmount);
        totalSupply = totalSupply-(_BurnAmount);
        ZeroAddress = 0x0000000000000000000000000000000000000000;
        emit Transfer(msg.sender, ZeroAddress, _BurnAmount);
        emit BurnEvent(msg.sender, _BurnAmount);
        
    }

    function ManageMinter(uint _addremove, address _address) public returns(address){
        require(msg.sender == SigAddress1 || msg.sender == SigAddress2 || msg.sender == SigAddress3);
        if (Signatures == 0){
            NewMinter = _address;
        }
        if (Signatures == 1){
            if (_addremove == 1){
            minter[NewMinter] = 1;
            }
            if (_addremove == 2){
            minter[NewMinter] = 0;
            }
        }

        MultiSignature();

        emit ManageMinterEvent(_address);
        return (_address);
    }


      function allowance(address owner, address delegate) public view returns (uint256) {
        return allowed[owner][delegate];
    
    }
    
      function CheckMinter(address AddytoCheck) public view returns(uint Minter){
          return(minter[AddytoCheck]);
          
      }




     //Multi-Sig Requirement for ManageMinter Function
    uint8 public Signatures;
    address public SigAddress1;
    address public SigAddress2;
    address public SigAddress3;
    uint8 public Setup;
    bool public Verified;
    address NewMinter;
    
    mapping(address => uint8) Signed;
    
    event MultiSigSet(bool Success);
    event MultiSigVerified(bool Success);
    

    
    function MultiSigSetup(address _1, address _2, address _3) public returns(bool success){
        require(Setup == 0);
        require(msg.sender == ownerAddy);
        
        
        SigAddress1 = _1;
        SigAddress2 = _2;
        SigAddress3 = _3;
        
        Setup = 1;
        
        emit MultiSigSet(true);
        return(success);
    }
    
    function MultiSignature() internal returns(bool AllowTransaction){
        require(msg.sender == SigAddress1 || msg.sender == SigAddress2 || msg.sender == SigAddress3);
        require(Signed[msg.sender] == 0);
        require(Setup == 1);
        Signed[msg.sender] = 1;
        
        if (Signatures == 1){
            Signatures = 0;
            Signed[SigAddress1] = 0;
            Signed[SigAddress2] = 0;
            Signed[SigAddress3] = 0;
            return(true);
        }
        
        if (Signatures == 0){
            Signatures = (Signatures + 1);
            return(false);
        }

    }
    
    function SweepSignatures() public returns(bool success){
        require(msg.sender == ownerAddy);
        require(Setup == 1);
        
        Signed[SigAddress1] = 0;
        Signed[SigAddress2] = 0;
        Signed[SigAddress3] = 0;
        
        Signatures = 0;
        
        return(success);
        
    }
    
    
    function MultiSigVerification() public returns(bool success){
        require(Verified == false);
        bool Verify;
        Verify = MultiSignature();
        
        if (Verify == true){
            Verified = true;
            emit MultiSigVerified(true);
        }
        
        return(Verify);
    }




}