// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC.sol";
import "./PancakeSwapRouter.sol";
import "./IICO.sol";

interface ILock{
    function lock(
        address token_,
        address beneficiary_,
        uint256 releaseTime_,
        uint256 amount_

    ) external;
}

contract Presale{

    //Main Variables

    address private creator; //@dev the address of the account deploying the contract
    address private stakingAddress;
    address immutable public LOCKER = 0xBF6cc8087327BCf80cAF3633B0315bdf397C3657;

    IERC20 public token;//@dev the address of the token used in the presale
    address private tokenAddress; 


    uint256 public tokenDecimals;

    bool public PresaleCancelled;
    bool public isKYC;
    bool public isAudit;

    event KYCUpdated(address reciever);


    //Presale Variables

    uint256 public softCap; //@dev the soft cap to be reached, if it is not the reached the presale will resukt to a fail
    uint256 public hardCap; //@dev this is the the hardcap of the 
    uint256 public raisedBNB;
    uint256 public minimBuy;
    uint256 public maximBuy;
    uint256 public startTime;//@dev The time the presale will start and end
    uint256 public endTime; 
    uint256 public coinUnit; //The unit for exchnage of the token e.g 1 BNB = 10000 tokens. this is set in tokens


    //Mappings of personal accounts to other values
    mapping(address => uint) public tokenBalance; //Personal token balance bought during the presale 
    mapping(address => uint) public maximumBought;
    mapping(address => uint) public spentBNB;

    //Whitelist variales

    bool WhitelistON;

    mapping(address => bool) public whitelistAddress;

    //Vesting Variables

    bool Vesting;
    uint MAXCLAIM;
    uint VestinStart;
    
    mapping(address => uint) private claimedPercent;
    mapping(address => uint) private claimmable;
    mapping(uint => uint) private timetoPercent;
    mapping(address => uint) private tokenPersonalBalance;


    //NormalClaim
    //this  is when the vesting was not set
    bool private finalised;
    uint256 private claimTime;

    mapping(address => bool) private Claimed;

    //Errors
    error PresalenotEnded(uint endtime);
    error softCapReached();

    //Liquidity 

    address immutable public pancakeRouterAddress = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
    IPancakeRouter02 pancakeSwapRouter;
    address public pancakeSwapPair;
    address public ADMIN;

    uint256 private coinExcUnit;
    uint256 private liquidityPercent;
    uint256 private coinBalance;
    uint256 private _coinliquidityCut;
    uint256 private CoinLiquidityCut;
    uint256 private percentConLiq  = liquidityPercent * 100;
    uint256 private liquidityCut;
    uint256 public liquidityLockTime;

    bool private burn;
    bool private Lock;

    uint256 AdminFee;
    uint256 inPresaleFee;
    uint256 ExchangeUnit;


    
    event Transfer(address indexed from, address indexed to, uint value);

    
    
    constructor(address _creator, address _Admin, address stakingPool, address _token, uint256 _hardcap, uint256 _softCap, uint256 _liquidity, uint256 buyunit, uint exchangeUnit, uint _AdminFee, uint _inpresaleFee){

        token = IERC20(_token);
        tokenAddress = _token;
        stakingAddress = stakingPool;
        creator = payable(_creator);
        ADMIN = _Admin;
         hardCap = _hardcap;
        softCap = _softCap;
        liquidityPercent = _liquidity;
       
        coinUnit = buyunit;
      
        AdminFee = _AdminFee  * 100;
        inPresaleFee = _inpresaleFee * 100;
        ExchangeUnit = exchangeUnit;

    }

    //checking if the msg.sender os the creator of the presale 
    modifier onlyAdmin{
        require(msg.sender == creator);
        _;
    }
    
    function setLimit(uint min, uint max) external onlyAdmin{
        maximBuy = max;
        minimBuy = min;
    }


//Whitelist
//this is only valid if the creator sets whitelist to true 

    function Whitelist() external onlyAdmin{
        WhitelistON = true;
    }

    //adding addresses to the whiteleist
    function setWhitelist(address reciever) external onlyAdmin{
        require(WhitelistON);

        whitelistAddress[reciever] = true;
    }
    
    //removing addresses from the whitelist

    function removeWhitelist(address reciever) external onlyAdmin{
         require(WhitelistON);

        delete whitelistAddress[reciever];
  
    }
    //completely turns off the whitelist

    function cancelWhitelist() external onlyAdmin{
         require(WhitelistON);
        WhitelistON = false;
    }

    //checks if whitelsit is activated, if yes, then it checks if the sender existsv in the mapping else it reverts or if whitelist is off then it executes the function

    modifier checkWhitelist{
        if(WhitelistON == true){
            require(whitelistAddress[msg.sender]);
            _;
        }
        else if(WhitelistON == false){
            _;
        }
        else 
        {
            revert();
        }
    }



    //Presale 

    function startPresale(uint _startTime, uint _endTime) external onlyAdmin{
        uint liqp = percentConLiq * hardCap/10000;
        uint excliq = ( ExchangeUnit * liqp) + (coinUnit * hardCap);

        require(token.balanceOf(address(this)) >= excliq, "NB");
       
        require(_startTime > block.timestamp);
        require(_endTime > _startTime);

        PresaleCancelled = false;

        startTime =  _startTime;
        endTime = _endTime;
    
    }

    function setTokenDecimals()external onlyAdmin{
        tokenDecimals = token.decimals();
    }

    function emergencyWithdrawal(uint amount) external{
        require(block.timestamp < endTime);
        require(spentBNB[msg.sender]>= amount);

        spentBNB[msg.sender]-= amount;
        tokenBalance[msg.sender] -= (amount * coinUnit);

        
        (bool sent,) = msg.sender.call{value: amount}("");
        require(sent, "Fail");

        emit Transfer(address(this), msg.sender, amount);


    }
    //this is used by the creator to end the presale at any poinit in case of a change of mind
    function cancelPresale() external onlyAdmin{
        require(startTime > 0);
        PresaleCancelled = true;

       uint256  debit = token.balanceOf(address(this));

        token.transfer(creator, debit);

    }

    receive() external payable{
      buy(msg.value);
    }



    //used for purchasing the token
    function buy(uint amount_) public payable checkWhitelist{
         require(startTime <= block.timestamp, "PO");
        require(endTime > block.timestamp, "PE");
        require(amount_ >= minimBuy);
        require(maximumBought[msg.sender]+amount_ <= maximBuy);

        uint tokenValue = amount_ * coinUnit;

    tokenBalance[msg.sender] += tokenValue;

    maximumBought[msg.sender] += amount_;
 
    spentBNB[msg.sender]+= amount_;
    raisedBNB+=amount_;


    tokenPersonalBalance[msg.sender] = tokenBalance[msg.sender];


    }

    //thios function sets the presale to either successful or not, interaction is mainly done my the script and not anybody else

    function openVesting(uint32 _startAt, uint _percent) external onlyAdmin{
      require(block.timestamp > endTime);
      require(softCap<= address(this).balance);
         require(!Vesting, "Vesting on");

        Vesting = true;

       MAXCLAIM += _percent;
       VestinStart = _startAt;

    
    }
    

    function increaseClaimmable(uint32 increaseAt, uint percent) external onlyAdmin {
            require(Vesting, "VO");

        if(increaseAt <= block.timestamp){
            require(MAXCLAIM + percent <= 100, "TM");
            timetoPercent[increaseAt] = percent;
            MAXCLAIM +=percent;

        }

        
    }


    function Vestingclaim() external{
        require(MAXCLAIM > claimedPercent[msg.sender]);
        require(MAXCLAIM >0);
        require(finalised);

        uint256 _amount = (MAXCLAIM - claimedPercent[msg.sender]) * 100;

        claimmable[msg.sender] = _amount * tokenPersonalBalance[msg.sender]/10000;
       
        tokenBalance[msg.sender] -= claimmable[msg.sender];

        claimedPercent[msg.sender] += MAXCLAIM;

        token.transfer(msg.sender, claimmable[msg.sender]);

        emit Transfer(address(this), msg.sender, claimmable[msg.sender]);
        
    }



    //Nomrmal Claiming without Vesting

    function Normalclaim() external{
        require(finalised);
        require(tokenBalance[msg.sender] > 0);

        uint256 debit = tokenBalance[msg.sender];

        require(!Claimed[msg.sender], "CL");

        delete tokenBalance[msg.sender];


        token.transfer(msg.sender, debit);

        emit Transfer(address(this), msg.sender, debit);


    }

    //Liquidity

    //Thiu is called if the presale was not successfull, it involves actions to be taken on the tokens 
    function unsuccessfulFinalise(uint choice) external onlyAdmin{
        if(raisedBNB < hardCap || raisedBNB < softCap || PresaleCancelled == true){
        remainingTokens(choice);
        }
    }

    function remainingTokens(uint choice) public onlyAdmin{
        require(raisedBNB < hardCap);
        require(token.balanceOf(address(this) ) > 0);
         if(choice == 1){ 

        token.transfer(creator, token.balanceOf(address(this)));
        
    emit Transfer(address(this), creator, token.balanceOf(address(this)));
        
        }
        else {
            burn = true;

        token.transfer(address(0), token.balanceOf(address(this)));

        emit Transfer(address(this), address(0), token.balanceOf(address(this)));

        }
            finalised = true;

    }

  function refund() external {
    require(raisedBNB < softCap);
    require(spentBNB[msg.sender] > 0);

    uint debit = spentBNB[msg.sender];
    delete spentBNB[msg.sender];
    delete tokenBalance[msg.sender];
     
        (bool sent,) = msg.sender.call{value: debit}("");
        require(sent, "F");

        emit Transfer(address(this), msg.sender, debit);

  }
   
    //If the presale was successfull
    function Finalise() external onlyAdmin{
        require(endTime < block.timestamp, "PN");
        require(raisedBNB >= softCap, "F");

        uint TOKENBALANCE = token.balanceOf(address(this));

        uint256 _liquidityCut = percentConLiq  * TOKENBALANCE/10000;
        uint presaleFeeCut = inPresaleFee * TOKENBALANCE/10000;
        
        uint256 tokenAdminCut = 5000 * presaleFeeCut/10000;
        uint256 tokenStakingCut = 5000 * presaleFeeCut/10000;

        _liquidityCut  -= presaleFeeCut;

        // if(Lock = true){
        //     _lockLPTokens(tokenAddress, liquidityCut, creator, liquidityLockTime);
        // }

       
        uint256 coinAdminCut = AdminFee * raisedBNB/10000;

        _coinliquidityCut -= coinAdminCut;

        //Payment distribution
        _addLiquidity(_liquidityCut);

     raisedBNB -= _coinliquidityCut;
        
        // (bool sent,) = ADMIN.call{value: coinAdminCut}("");
        // require(sent, "F");

        distribute(coinAdminCut, tokenAdminCut, tokenStakingCut);
      
        finalised = true;

    }

    function _addLiquidity(uint tokenAmount) internal{
        
        token.approve(pancakeRouterAddress, tokenAmount);

      pancakeSwapRouter.addLiquidityETH{value: _coinliquidityCut}(

            tokenAddress,
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            creator, // Liquidity Locker or Creator Wallet
            block.timestamp
        );
    }

    function distribute(uint coinAdminCut, uint tokenAdminCut, uint tokenStakingCut) internal{

        
        token.transfer(ADMIN, tokenAdminCut);
        emit Transfer(address(this), ADMIN, tokenAdminCut);

        token.transfer(stakingAddress, tokenStakingCut);
        emit Transfer(address(this), stakingAddress, tokenStakingCut);


          payable(ADMIN).transfer(coinAdminCut);

        emit Transfer(address(this), ADMIN, coinAdminCut);

        // (bool sentCoin,) = creator.call{value: debit}("");
        // require(sentCoin, "F");

        payable(creator).transfer(raisedBNB);

        emit Transfer(address(this), creator, raisedBNB);

    }


    function requestKYC() public view returns(bool, address){
        require(msg.sender == creator);
        return (true, address(this)); 
    }
      // Lock LP token
    function _lockLPTokens( address _token, uint256 _amount,address _owner,uint256 _liquidityLockTime) internal virtual{
        //  Check Balance

        require(token.balanceOf(address(this)) >= _amount,"IB");
        ILock locker = ILock(LOCKER);
        locker.lock(_token, _owner , _liquidityLockTime, _amount);
    }
    function lockLiq() external onlyAdmin{
        Lock = true;
    }
    function setLiquidityLocktime(uint256 time) external{
        liquidityLockTime = time;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IICO{
    function cancelPresale() external;
    function setIsKYCAndAudit(bool kyc,bool audit) external;
    function requestKYCandAudit() external view returns(bool, address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}


interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.0.0/contracts/token/ERC20/IERC20.sol


interface IERC20Metadata {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

interface IERC20 is IERC20Metadata{
    function totalSupply() external view returns (uint);
    

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}