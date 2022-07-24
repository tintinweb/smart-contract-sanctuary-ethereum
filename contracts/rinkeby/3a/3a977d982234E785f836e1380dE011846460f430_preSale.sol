// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC.sol";

contract preSale{

    address private admin;
    uint256 private bnbunit;
    uint256 private _Presale;
    uint256 public hardCap;
    
    uint256 private phaseCount;
    uint256 private phase = 1;
    uint256 private MAXCLAIM;

    bool public presaleStart;

    IERC20 public immutable token;

    constructor(address _token, uint _hardcap){
        token = IERC20(_token);
        _hardcap = hardCap;
        admin = payable(msg.sender);
    }

    mapping(address => uint) private bnbBalance;
    mapping(address => uint) private tokenBalance;
    mapping(address => uint) private totaltoken;
    mapping(uint => mapping(address => bool)) private claimed;
    mapping(address => uint) private claimedPercent;
    mapping(address => uint) private claimmable;
    mapping(uint => claimingPhases) public Vesting;


    event Bought(address indexed buyer, uint amount);
    event Deposited(address indexed depositor, uint amount);
    event PresaleSet(uint32 starttime);
    event withdrawn(address indexed reciever, uint _amount);
    event Claimed(address indexed claimer, uint amount, uint percentage, uint period);
    
//Structs

    struct claimingPhases{
        uint phaseNumber;
        uint maxClaim;
        uint32 startAt;
        bool started;
    }

    claimingPhases _claimingPhases;


//Modifiers
    modifier onlyAdmin{
        require(msg.sender == admin,"You are not the Admin");
        _;
    }

    modifier deposited{
        require(bnbBalance[msg.sender] > 0, "You didnt contribute BNB");
        _;
    }

    modifier started{
        require(presaleStart, "The presale has not yet started");
        _;
    }

    modifier notEnded{
        require(presaleStart, "Presale already ended");
        _;
    }

    modifier presaleEnded{
        require(!presaleStart, "The Presale is still Open");
        _;
    }

    modifier presaleAlreadyset{
        require(_Presale == 0, "The presale has already been set");
        _;
    }

    modifier claimCheck{
        require(phaseCount > 1, "First vesting period already set, increase instead");
        _;
    }
    
    modifier claimStarted{
        require(Vesting[phase].started, "Claiming has not yet started");
        _;
    }

    modifier hardcapReached{
        require(hardCap <= address(this).balance, "Hardcap not yet reahced");
        _;
    }



//Main Functions
    receive() external payable{
        if(presaleStart == true){
            revert("Presale Already started");
        }
        else {
          if(address(this).balance > hardCap){
            revert("Hardcap has been reached");
        }
        else {
            bnbBalance[msg.sender] += msg.value;
            emit Deposited(msg.sender, msg.value);
        }
        }
            
    }




//Setting Functions

    function setPresale() external onlyAdmin presaleAlreadyset{
        _Presale++;

        startPreasale();

    }
    
    function startPreasale() internal {
        presaleStart = true;
    }


   function openClaiming(uint32 _startAt, uint _percent) external onlyAdmin presaleEnded{

       MAXCLAIM += _percent;
        uint maxClaim_ = MAXCLAIM;
      
       bool _started;
     
        if(_startAt <= block.timestamp){
            _started = true;
        }
        else{
            _started = false;
        }

         Vesting[phase] = claimingPhases({
           phaseNumber : phase,
           maxClaim : maxClaim_,
           startAt : _startAt,
           started : _started
       });

       phaseCount++;

    }

    function increaseClaimmable(uint32 increseAt, uint percent) external onlyAdmin claimStarted{

        if(increseAt <= block.timestamp){
            require(MAXCLAIM + percent <= 100, "You cant add more than 100 percent");
            MAXCLAIM +=percent;
        }

        
    }

    function setUnit(uint basicUnit) external onlyAdmin{
        bnbunit = basicUnit;
    }

//Getter Functions 
    function getMaxClaimmable() external view returns(uint){
        return MAXCLAIM;
    }

    function getBalance() external view returns(uint){
        return address(this).balance;
    }

    function getTokenBalance() external view returns(uint){
        return token.balanceOf(address(this));
    }

    function getPersonalBNBBalance() external view returns(uint){
        return bnbBalance[msg.sender];
    }

    function getPersonaltokenBalance() external view returns(uint){
        return tokenBalance[msg.sender];
    }


//Other functions 
    function endPresale() external onlyAdmin notEnded{
        presaleStart = false;
    }

    function buy(uint amount) external deposited started{

        require(presaleStart, "Presale has nnot started yet");
        
        uint bnbValue = amount * bnbunit;
        bnbBalance[msg.sender] -= bnbValue;
        tokenBalance[msg.sender] += amount;

        totaltoken[msg.sender] = tokenBalance[msg.sender];

        emit Bought(msg.sender, amount);

    }


    function withdraw(uint amount) external{

        require(amount <= bnbBalance[msg.sender], "Insufficient Balance");

        bnbBalance[msg.sender]-= amount;

        payable(msg.sender).transfer(amount);

        emit withdrawn(msg.sender, amount);

    }

    modifier alreadyClaimed{
        if(MAXCLAIM > claimedPercent[msg.sender])
        _;
        else 
        {
            revert("You have already claimed for this period");
        }
    }


    function claim() external claimStarted alreadyClaimed{

        uint newPercent = MAXCLAIM - claimedPercent[msg.sender];
        uint _amount = newPercent * 100;

        claimmable[msg.sender] = _amount * totaltoken[msg.sender]/10000;
       

        tokenBalance[msg.sender] -= claimmable[msg.sender];

        token.transfer(msg.sender, claimmable[msg.sender]);

        claimedPercent[msg.sender] += MAXCLAIM;

        emit Claimed(msg.sender, claimmable[msg.sender], MAXCLAIM, phaseCount);
    }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.0.0/contracts/token/ERC20/IERC20.sol
interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}