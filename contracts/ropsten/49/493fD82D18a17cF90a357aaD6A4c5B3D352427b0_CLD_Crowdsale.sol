/**
 *Submitted for verification at Etherscan.io on 2022-06-17
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

//CLD1 current test: 
//CLDsale current test: 

contract CLD_Crowdsale {
    address payable CLD;
    uint256 public CLD_Sale_Allocation;
    uint256 public Total_ETC_Deposited; 
    uint256 public Allocation_Exchange_Rate = 0;
    uint256 public Total_CLD_Distributed;
    address public CrowdSale_Operator;
    uint256 public Crowdsale_End_Unix;
    
    //DEV WALLETS (MAKE SURE TO CHANGE THESE)
    
    address payable LiquidityAddress = payable(0x3B11de92122E54183c278E1713f80215d2401ae5); //This address will be used to add the 35% of crowdsale funds as liquidity for wETC-CLD
    address payable TreasuryFund = payable(0xC61A70Fb5F8A967C71c1E9A42374FbE460D0a341); //This address will be used to add the 35% of crowdsale funds as for the Treasury Fund
    
    address payable Dev_1 = payable(0xc932b3a342658A2d3dF79E4661f29DfF6D7e93Ce); //Payout Wallet to a party who worked on ClassicDAO (CryptoGaralo) 15% of the Crowdsale Funds
    address payable Dev_2 = payable(0xc932b3a342658A2d3dF79E4661f29DfF6D7e93Ce); //Payout Wallet to a party who worked on ClassicDAO (Soteria-Smart-Contracts) 15% of the Crowdsale Funds   

    
    //Crowdsale Mode struct 
    struct Mode {
        string Sale_Mode_Text;
        uint8 Sale_Mode;
    }
    
    Mode Crowdsale_Mode;
    //Crowdsale Modes
    //1: Before sale preperation Mode
    //2: Sale is Open to buy CLD
    //3: Sale is over, CLD buyer withdrawal period
    //99 Emergency Shutdown mode, in case any issues or bugs need to be dealt with, Safe for buyers, and ETC withdrawls will be available
    
    
    //Crowdsale Contract constructor
    constructor(uint256 Sale_Allocation, address payable _CLD){
        CLD_Sale_Allocation = Sale_Allocation;
        CLD = _CLD;
        Crowdsale_Mode = Mode("Before sale preperation", 1);
        CrowdSale_Operator = msg.sender;
    }
    
    //Event Declarations
    event CrowdsaleStarted(address Operator, uint256 Crowdsale_Allocation, uint256 Unix_End);
    event CrowdsaleEnded(address Operator, uint256 wETCraised, uint256 BlockTimestamp);
    event ETCdeposited(address Depositor, uint256 Amount);
    event ETCwithdrawn(address Withdrawee, uint256 Amount);
    event CLDwithdrawn(address Withdrawee, uint256 Amount);
    event VariableChange(string Change);
    
    
    
    //Deposit Tracker
    mapping(address => uint256) ETC_Deposited;
    
    
    //Buyer Functions
    
    function DepositETC() public payable returns(bool success){ //TESTED - WORKS
        require(Crowdsale_Mode.Sale_Mode == 2);
        require(block.timestamp < Crowdsale_End_Unix);
        require(msg.value >= 100000000000000000);
        
        ETC_Deposited[msg.sender] = (ETC_Deposited[msg.sender] + msg.value);
        
        Total_ETC_Deposited = (Total_ETC_Deposited + msg.value);
        emit ETCdeposited(msg.sender, msg.value);
        return(success);
    } 
    
    //There is a 5% fee for withdrawing deposited wETC (Unless the contract is in emergency mode, allowing those who have deposited to withdraw their entire deposit withought a fee in the case of a contract error.)
    function WithdrawETC(uint256 amount) public returns(bool success){ //UNTESTED
        require(amount <= ETC_Deposited[msg.sender]);
        require(Crowdsale_Mode.Sale_Mode != 3 && Crowdsale_Mode.Sale_Mode != 1);
        require(amount >= 100000000000000000);
        uint256 amount_wFee = ((amount * 95) / 100);

        if (Crowdsale_Mode.Sale_Mode == 99){
            //No Fee Implemetantion for 99 Mode (Only allows you to withdraw everything at once)
            amount_wFee = (ETC_Deposited[msg.sender]);
            ETC_Deposited[msg.sender] = 0;
            (payable(msg.sender)).transfer(amount_wFee);
        }
        else{
            ETC_Deposited[msg.sender] = (ETC_Deposited[msg.sender] - amount);
            (payable(msg.sender)).transfer(amount_wFee);
        }

        Total_ETC_Deposited = (Total_ETC_Deposited - amount_wFee);
        emit ETCwithdrawn(msg.sender, amount);
        return(success);
    }
    
    function WithdrawCLD() public returns(uint256 _CLDwithdrawn){ //TESTED - WORKS
        require(Crowdsale_Mode.Sale_Mode == 3);
        require(block.timestamp > Crowdsale_End_Unix);
        require(ETC_Deposited[msg.sender] >= 1000000000000000);
        
        
        uint256 CLDtoMintandSend = (((ETC_Deposited[msg.sender] / 100000000) * Allocation_Exchange_Rate) / 100000000);
        require((Total_CLD_Distributed + CLDtoMintandSend) <= CLD_Sale_Allocation);
        
        ETC_Deposited[msg.sender] = 0;
        
        ERC20(CLD).Mint(msg.sender, CLDtoMintandSend);
        
        Total_CLD_Distributed = (Total_CLD_Distributed + CLDtoMintandSend);
        emit CLDwithdrawn(msg.sender, CLDtoMintandSend);
        return(CLDtoMintandSend);
    }
    
    
    
    //Operator Functions
    function StartCrowdsale() public returns(bool success){ //TESTED - WORKS
        require(msg.sender == CrowdSale_Operator);
        require(ERC20(CLD).CheckMinter(address(this)) == 1);
        require(Crowdsale_Mode.Sale_Mode == 1);
        require(Setup == 1);
        
        Crowdsale_End_Unix = (block.timestamp + 432000); //EDIT!!!! - This is the time until the Crowdsale ends
        Crowdsale_Mode.Sale_Mode_Text = ("Sale is Open to buy CLD");
        Crowdsale_Mode.Sale_Mode = 2;
        
        emit CrowdsaleStarted(msg.sender, CLD_Sale_Allocation, Crowdsale_End_Unix);
        return success;
        
    }
    
    function EndCrowdsale() public returns(bool success){   //TESTED - WORKS
        require(msg.sender == CrowdSale_Operator);
        require(ERC20(CLD).CheckMinter(address(this)) == 1);
        require(Crowdsale_Mode.Sale_Mode == 2);
        require(block.timestamp > Crowdsale_End_Unix);
        
        Crowdsale_Mode.Sale_Mode_Text = ("Sale is over, Time to withdraw CLD!");
        Crowdsale_Mode.Sale_Mode = 3;
        
        
        Allocation_Exchange_Rate = (((CLD_Sale_Allocation * 100000000) / (Total_ETC_Deposited / 100000000)));
        
        emit CrowdsaleEnded(msg.sender, Total_ETC_Deposited, block.timestamp);
        return(success);
        
    }

    //This function only works when the crowdsale is in the post-sale mode(3), or in the Emergency mode(99)
    function PullETC() public returns(bool success){ //TESTED - Works
        require(Crowdsale_Mode.Sale_Mode == 3 || Crowdsale_Mode.Sale_Mode == 99);
        require(block.timestamp > Crowdsale_End_Unix);
        
        bool Multisig;
        Multisig = MultiSignature();
        
        uint256 Contract_ETC_Balance = (address(this).balance);
        
        if (Multisig == true){
            (LiquidityAddress).transfer((Contract_ETC_Balance * 350) / 1000);
            (TreasuryFund).transfer((Contract_ETC_Balance * 350) / 1000);
            (Dev_1).transfer((Contract_ETC_Balance * 150) / 1000);
            (Dev_2).transfer((Contract_ETC_Balance * 150) / 1000);
        }

        return success;
    }
    
    function Emergency_Mode_Activate() public returns(bool success){ //TESTED - WORKS
        require(Crowdsale_Mode.Sale_Mode != 1);
        bool Multisig;
        Multisig = MultiSignature();
        
        if (Multisig == true){
            
        Crowdsale_Mode.Sale_Mode_Text = ("The Developers have multisigned to activate emergencymode on this smart contract");
        Crowdsale_Mode.Sale_Mode = 99;
        
        return(success);
        }
    }

    function Resume_Sale() public returns(bool success){ //TESTED - WORKS
        bool Multisig;
        Multisig = MultiSignature();
        require(Crowdsale_Mode.Sale_Mode == 99);
        
        if (Multisig == true){
            
        Crowdsale_Mode.Sale_Mode_Text = ("Sale is Open to buy CLD");
        Crowdsale_Mode.Sale_Mode = 2;
        
        return(success);
        }
    }
    
    //Redundancy
    function ChangeCLDaddy(address payable NewAddy)public returns(bool success, address CLDaddy){ //TESTED - WORKS
        require(msg.sender == CrowdSale_Operator);
        require(Crowdsale_Mode.Sale_Mode != 3);
        CLD = NewAddy;
        emit VariableChange("Changed CLD Address");
        return(true, CLD);
    }
    
    //Call Functions
    function GetContractMode() public view returns(uint256, string memory){ //TESTED - WORKS
        return (Crowdsale_Mode.Sale_Mode, Crowdsale_Mode.Sale_Mode_Text);
        
    }
    
    function GetETCdeposited(address _address) public view returns(uint256){ //TESTED - WORKS
        return (ETC_Deposited[_address]);
    }

    function GetCurrentExchangeRate() public view returns(uint256){ //Untested 
        return(((CLD_Sale_Allocation * 100000000) / (Total_ETC_Deposited / 100000000)));
    }



    //_______________________________________________________________________________________________________________________________________________________________            
    //_______________________________________________________________________________________________________________________________________________________________
    
    
    //Multi-Sig Requirement for Fund Extraction post crowsale by Dev Team to reduce attack likelyness aswell as remove central point of authority
    uint8 public Signatures;
    address public SigAddress1;
    address public SigAddress2;
    address public SigAddress3;
    uint8 public Setup;
    bool public Verified;
    
    mapping(address => uint8) Signed;
    
    event MultiSigSet(bool Success);
    event MultiSigVerified(bool Success);
    

    
    function MultiSigSetup(address _1, address _2, address _3) public returns(bool success){ //TESTED - WORKS
        require(Setup == 0);
        require(msg.sender == CrowdSale_Operator);
        require(Crowdsale_Mode.Sale_Mode == 1);
        
        SigAddress1 = _1;
        SigAddress2 = _2;
        SigAddress3 = _3;
        
        Setup = 1;
        
        emit MultiSigSet(true);
        return(success);
    }
    
    function MultiSignature() internal returns(bool AllowTransaction){ //TESTED - WORKS
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
    
    function SweepSignatures() public returns(bool success){ //TESTED - WORKS
        require(msg.sender == CrowdSale_Operator);
        require(Setup == 1);
        
        Signed[SigAddress1] = 0;
        Signed[SigAddress2] = 0;
        Signed[SigAddress3] = 0;
        
        Signatures = 0;
        
        return(success);
        
    }
    
    
    function MultiSigVerification() public returns(bool success){ //TESTED - WORKS
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


interface ERC20 {
  function balanceOf(address owner) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint value) external returns (bool);
  function Mint(address _MintTo, uint256 _MintAmount) external;
  function transfer(address to, uint value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool); 
  function totalSupply() external view returns (uint);
  function CheckMinter(address AddytoCheck) external view returns(uint);
}

//      $$$$$$                     /$$                                /$$           /$$                      /$$      /$$               /$$                                               /$$                      
//    /$$__  $$                   | $$                               | $$          | $$                     | $$  /$ | $$              | $$                                              | $$                      
//   | $$  \__/ /$$$$$$ /$$$$$$$ /$$$$$$   /$$$$$$ /$$$$$$  /$$$$$$$/$$$$$$        | $$$$$$$ /$$   /$$      | $$ /$$$| $$ /$$$$$$  /$$$$$$$ /$$$$$$  /$$$$$$  /$$$$$$  /$$$$$$  /$$$$$$ /$$$$$$   /$$$$$$ /$$$$$$$ 
//   | $$      /$$__  $| $$__  $|_  $$_/  /$$__  $|____  $$/$$_____|_  $$_/        | $$__  $| $$  | $$      | $$/$$ $$ $$/$$__  $$/$$__  $$/$$__  $$/$$__  $$/$$__  $$|____  $$/$$__  $|_  $$_/  /$$__  $| $$__  $$
//   | $$     | $$  \ $| $$  \ $$ | $$   | $$  \__//$$$$$$| $$       | $$          | $$  \ $| $$  | $$      | $$$$_  $$$| $$$$$$$| $$  | $| $$$$$$$| $$  \__| $$  \ $$ /$$$$$$| $$  \__/ | $$   | $$$$$$$| $$  \ $$
//   | $$    $| $$  | $| $$  | $$ | $$ /$| $$     /$$__  $| $$       | $$ /$$      | $$  | $| $$  | $$      | $$$/ \  $$| $$_____| $$  | $| $$_____| $$     | $$  | $$/$$__  $| $$       | $$ /$| $$_____| $$  | $$
//   |  $$$$$$|  $$$$$$| $$  | $$ |  $$$$| $$    |  $$$$$$|  $$$$$$$ |  $$$$/      | $$$$$$$|  $$$$$$$      | $$/   \  $|  $$$$$$|  $$$$$$|  $$$$$$| $$     |  $$$$$$|  $$$$$$| $$       |  $$$$|  $$$$$$| $$  | $$
//   \______/ \______/|__/  |__/  \___/ |__/     \_______/\_______/  \___/        |_______/ \____  $$      |__/     \__/\_______/\_______/\_______|__/      \____  $$\_______|__/        \___/  \_______|__/  |__/
//                                                                                         /$$  | $$                                                       /$$  \ $$                                             
//