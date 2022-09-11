pragma solidity ^0.8.7;

import "./vdToken.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";

contract Bet is VRFConsumerBaseV2 {
    VRFCoordinatorV2Interface COORDINATOR;

    uint64 s_subscriptionId;

    GamingToken public token;

    address vrfCoordinator = 0x271682DEB8C4E0901D1a1550aD2e64D568E69909;

    bytes32 keyHash = 		0xff8dedfbfa60af186cf3c830acbc32c05aae823045ae5ea7da1e45fbfaba4f92;

    uint32 callbackGasLimit = 1000000;

    uint16 requestConfirmations = 3;
    uint256 public vRes ; 
    uint public Vset ; 

    uint32 numWords =  1;

    uint256[] public s_randomWords;
    uint256 public s_requestId;
    uint256 public maxbet ; 


    mapping(uint256 => address) private _wagerInit; 
    mapping(address => uint256) private _wagerInitAmount;
    mapping(uint256 => uint16) private Pset ; 
    mapping(address => uint16) public LatestRes; 

    address public burnaddy = 0x000000000000000000000000000000000000dEaD ; 
    address s_owner;  
    address public creator = 0x578ABa51aA4a6ce5c1A055882f56849c2C4c5aDa ;

    constructor(uint64 subscriptionId,GamingToken _token) VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_owner = msg.sender;
        s_subscriptionId = subscriptionId;
        token = _token;
    }

    function WithdrawTokens(uint256 _amount) public{
        require(msg.sender == creator);
        token.transfer(creator, _amount );
    }
    function MAXbet(uint256 _maxbet) public {
        require(msg.sender == creator);
        maxbet = _maxbet ; 
    }

    function requestRandomWords(uint256 _amount, uint16 _pset) external {
        require(_amount < maxbet*10**18);
        require((_amount/10000)*10000 == _amount, 'too small');
        require(token.balanceOf(msg.sender) >= _amount);
        require(token.balanceOf(address(this)) >= 6*_amount);
        token.transferFrom(msg.sender, address(this), _amount);

        s_requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
    
        _wagerInit[s_requestId] = msg.sender;
        _wagerInitAmount[msg.sender] = _amount;   
        Pset[s_requestId] = _pset ;
        LatestRes[msg.sender] = 0 ; 
    }

    function fulfillRandomWords  (
       uint256 s_requestId, /* requestId */
       uint256[] memory randomWords
    ) internal override {
    uint256 s_randomRange = (randomWords[0] % 100) + 1;
    _settleBet(s_requestId,s_randomRange);
   }

   function _settleBet(uint256 requestId, uint256 randomNumber) private {
        address _user = _wagerInit[requestId];
        require(_user != address(0), 'coin flip record does not exist');

        uint256 _amountWagered = _wagerInitAmount[_user];
        uint16 PsetF = Pset[requestId];
        vRes = randomNumber ; 
        Vset = PsetF ;
        if(PsetF == 1){
            
        if (randomNumber > 55 && randomNumber < 76){
            //50 percent
            uint WinAmount = (_amountWagered/100) *50 ; 
            token.transfer(_user ,_amountWagered + WinAmount);
            LatestRes[_user] = 2 ;
            
        } else if (randomNumber > 75 && randomNumber < 96 ){
            //2x
            uint WinAmount = _amountWagered*2;
            token.transfer(_user , WinAmount); 
            LatestRes[_user] = 2 ;

        } else if (randomNumber > 95 ){
            //4x
            uint WinAmount = _amountWagered*4;
            token.transfer(_user , WinAmount); 
            LatestRes[_user] = 2 ;

        }
        else {
            LatestRes[_user] =1 ; 
        }
        }

        else if(PsetF == 2){
            
        if (randomNumber > 20 && randomNumber < 71){
            //10 percent
            uint WinAmount = (_amountWagered/100) *10 ; 
            token.transfer(_user ,_amountWagered + WinAmount);
            LatestRes[_user] = 2 ;
            
        } else if (randomNumber > 70 && randomNumber < 81 ){
            //50 percent
            uint WinAmount = (_amountWagered/100) *50 ;
            token.transfer(_user ,_amountWagered + WinAmount);
            LatestRes[_user] = 2 ;

        } else if (randomNumber > 80 ){
            //25 percent
            uint WinAmount = (_amountWagered/100) *25 ; 
            token.transfer(_user ,_amountWagered + WinAmount);
            LatestRes[_user] = 2 ;

        }
        else {
            LatestRes[_user] = 1 ; 
        }
        }

       else if(PsetF == 3){
            
        if (randomNumber > 50 && randomNumber < 91){
            //50 percent
            uint WinAmount = (_amountWagered/100) *50 ; 
            token.transfer(_user ,_amountWagered + WinAmount);
            LatestRes[_user] = 2 ;
            
        }  else if (randomNumber > 90 ){
            //3x
            uint WinAmount = _amountWagered*3;
            token.transfer(_user , WinAmount); 
            LatestRes[_user] = 2 ;

        }
        else {
            LatestRes[_user] = 1 ; 
        }
        }
        

   }


}