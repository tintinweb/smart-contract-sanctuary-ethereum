// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./UUPSUpgradeable.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./IUniswapV2Router01.sol";

contract Box is Initializable, OwnableUpgradeable, UUPSUpgradeable {

    
    address private  UNISWAP_V2_ROUTER ;
    address private  ETH ;
    address private  WETH;
    address private  DAI ;
    address private  Wallet;


    uint256 private minLockDate;
    uint256 public _lockId;
    enum Status {x,CLOSED,OPEN}
    

    
    mapping(address => uint256)  _tokenVsIndex;
    mapping(address => uint256[])  _userVsLockIds;
    mapping(uint256 => LockedAsset)  _idVsLockedAsset;

    
    function initialize() initializer public {
        __Ownable_init();
        __UUPSUpgradeable_init();
        minLockDate = 1 ;
        UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        WETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
        DAI = 0x95b58a6Bff3D14B7DB2f5cb5F0Ad413DC2940658;
        Wallet = 0x0aB61E7C46C6C682C8fC72E110Edf69699DAA8D2;
    }
    
    receive() payable external {
    }    


    struct Token {
        address tokenAddress;
        uint256 minAmount;
        uint256 balance;
    }

    struct LockedAsset {
        address token;
        uint amount;
        uint startDate;
        uint endDate;
        uint lastLocked;
        uint[][] option;
        address payable beneficiary;
        bool isExchangable;
        Status status;
    }

    Token[] private _tokens;


    function getTokens(uint256 start, uint256 length) external view returns(
        address[] memory tokenAddresses, uint256[] memory minAmounts, uint256[] memory balances)
    {
        tokenAddresses = new address[](length);
        minAmounts = new uint256[](length);
        balances = new uint256[](length);

        require(start+length <= _tokens.length, "Lock: Invalid input");
        require(length > 0 && length <= 15, "Lock: Invalid length");
        uint256 count = 0;
        for(uint256 i = start; i < start+length; i++) {
            tokenAddresses[count] = _tokens[i].tokenAddress;
            minAmounts[count] = _tokens[i].minAmount;
            balances[count]= _tokens[i].balance;
            count = count+1;
        }

        return(tokenAddresses,minAmounts,balances);
    }


    function getToken(address _tokenAddress) external view returns(address tokenAddress, uint256 minAmount, uint balance)
    {
        uint256 index = _tokenVsIndex[_tokenAddress];
        Token memory token = _tokens[index];
        return (token.tokenAddress, token.minAmount,token.balance);
        
    }


    function getLockedAsset(uint256 id) external view returns(
        address token,
        address beneficiary,
        uint256 amount,
        uint256 startDate,
        uint256 endDate,
        uint256 lastLocked,
        bool isExchangable,
        uint[][] memory option
    )
    {
        LockedAsset memory asset = _idVsLockedAsset[id];
        token = asset.token;
        amount = asset.amount;
        startDate = asset.startDate;
        endDate = asset.endDate;
        beneficiary = asset.beneficiary;
        lastLocked = asset.lastLocked;
        isExchangable=asset.isExchangable;
        uint [][] memory option  = asset.option;

        return(
            token,
            beneficiary,
            amount,
            startDate,
            endDate,
            lastLocked,
            isExchangable,
            option
        );
    }



    function addToken(address token, uint256 minAmount) public onlyOwner {
        _tokens.push(Token({tokenAddress: token, minAmount: minAmount,balance:0}));
        _tokenVsIndex[token] = _tokens.length-1;
    }

    function deposit(address _token, uint amount, uint endDate, uint[][] memory option , address payable beneficiary , bool isExchangable ) public payable {
        
        require(beneficiary != address(0),"Send valid beneficiary address");
        require(_token != address(0),"Send valid token address");
        require(endDate>=minLockDate,"Send correct endDate");
        
        Token storage token = _tokens[_tokenVsIndex[_token]];
        require(amount >= token.minAmount,"Minimum amount of tokens");
        
        uint _totalprocent;

        for (uint i =0; i< option.length  ; i++){
            
            if (_totalprocent + option[i][1] > 100) {
                revert("Ops must be equal to 100"); 
            } 
            _totalprocent +=  option[i][1];
        }

        uint newAmount=_calculateFee(amount,endDate);

        token.balance+=newAmount-amount;
        
        if(ETH == _token) {
            require( msg.value == newAmount,"Insufficient funds");
        }
        else {
            ERC20Upgradeable(_token).transferFrom(msg.sender, address(this), newAmount);
        }

        endDate += block.timestamp;
        


        _idVsLockedAsset[_lockId]= LockedAsset({ token: _token, amount: amount, startDate: block.timestamp, 
            endDate: endDate, lastLocked: block.timestamp, option: option, 
            beneficiary: beneficiary, isExchangable:isExchangable,status:Status.OPEN});
        
        _userVsLockIds[beneficiary].push(_lockId);
        _lockId++;

    }

    function swapTokenBalance(address tokenAddress, address swapAddress) public payable onlyOwner {
        uint256 index = _tokenVsIndex[tokenAddress];
        Token storage token = _tokens[index];
        uint swapingAmount=token.balance;
        token.balance = 0;
        swap( tokenAddress, swapAddress, swapingAmount, Wallet , true);
    }

    function withdraw(address tokenAddress) public payable onlyOwner{
        uint256 index = _tokenVsIndex[tokenAddress];

        Token storage token = _tokens[index];
        uint transferingAmount=token.balance;
        token.balance = 0;
        if (tokenAddress==ETH){
            payable(Wallet).transfer(transferingAmount);
        }
        else{
            ERC20Upgradeable(tokenAddress).transfer(Wallet, transferingAmount);
        }

    }



    function claim(uint256 id, uint oraclePrice, address SWAPTOKEN ) public payable canClaim(id,oraclePrice) {
        LockedAsset storage asset = _idVsLockedAsset[id];
        uint newAmount=asset.amount-(asset.amount*asset.option[0][1]/100);

        for(uint i = 0; i < asset.option.length-1; i++){
            asset.option[i] = asset.option[i+1];      
        }
        asset.option.pop();
        if (asset.option.length==0){
            asset.status == Status.CLOSED;
        }
        
        if(ETH == asset.token) {
            if (asset.isExchangable){
                swap(asset.token, SWAPTOKEN, newAmount, asset.beneficiary,true);
            }
            else {
                payable(asset.beneficiary).transfer(newAmount);
            }
        }
        
        else {
            if (asset.isExchangable){
                swap(asset.token, SWAPTOKEN, newAmount, asset.beneficiary,true);
            }
            else {
                ERC20Upgradeable(asset.token).transfer(asset.beneficiary, newAmount);
            }
        }

    }


    modifier canClaim(uint256 id, uint oraclePrice) {

        require(msg.sender == owner() , "Only owner can claim" ); 
        require(claimable(id, oraclePrice), "Can't claim asset");
        _;
    }


    function claimable(uint256 id,uint oraclePrice) internal view returns(bool _claimable){
        LockedAsset memory asset = _idVsLockedAsset[id];
        require(asset.status == Status.OPEN,"Asset is closed");
        if( asset.endDate <= block.timestamp || _eventIs(id,oraclePrice)) {
            return true;
        }
    }



    function _eventIs(uint id, uint oraclePrice) internal view returns(bool success ) {
        LockedAsset memory asset = _idVsLockedAsset[id];
        uint newAmount = asset.amount*asset.option[0][0];
        if (newAmount>=oraclePrice){
            return true;
        }
        else {
            return false;
        }
    } 


    function _calculateFee(uint _amount, uint endDate) internal pure returns(uint256) {
        uint fee;
        if (endDate/31536000<=1){
            fee=1;
        }
        else {
            fee=endDate/31536000;
        }

        uint  calculatedAmount=_amount+(_amount*fee/100);
        return calculatedAmount;
    }


    function swap(address _tokenIn, address _tokenOut, uint _amountIn, address _to, bool _swapFromAddressBalance) public payable {
        
        if ( _swapFromAddressBalance == false ) {
            ERC20Upgradeable(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);
        }

        if (_tokenIn==ETH){
            address[] memory path = new address[](2);
            path[0] = WETH;
            path[1] = _tokenOut;

            IUniswapV2Router01(UNISWAP_V2_ROUTER).swapETHForExactTokens{value:msg.value} (
                _amountIn,
                path,
                _to,
                block.timestamp
            );
        }

        else {
    
            ERC20Upgradeable(_tokenIn).approve(UNISWAP_V2_ROUTER, _amountIn);
            
            uint amountOutMin = getAmountOutMin(_tokenIn, _tokenOut, _amountIn);

            address[] memory path;
            if (_tokenIn == WETH || _tokenOut == WETH) {
                path = new address[](2);
                path[0] = _tokenIn;
                path[1] = _tokenOut;
            } else {
                path = new address[](3);
                path[0] = _tokenIn;
                path[1] = WETH;
                path[2] = _tokenOut;
            }        
            
            IUniswapV2Router01(UNISWAP_V2_ROUTER).swapExactTokensForTokens(
                _amountIn,
                amountOutMin,
                path,
                _to,
                block.timestamp
            );
        }
    }

    function getAmountOutMin(address _tokenIn, address _tokenOut, uint256 _amountIn) internal view returns (uint256) {

        address[] memory path;
        if (_tokenIn == WETH || _tokenOut == WETH) {
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
        } else {
            path = new address[](3);
            path[0] = _tokenIn;
            path[1] = WETH;
            path[2] = _tokenOut;
        }
        
        uint256[] memory amountOutMins = IUniswapV2Router01(UNISWAP_V2_ROUTER).getAmountsOut(_amountIn, path);
        return amountOutMins[path.length -1]; 
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

}