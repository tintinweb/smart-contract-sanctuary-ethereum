/**
 *Submitted for verification at Etherscan.io on 2022-02-06
*/

// SPDX-License-Identifier: GNU LGPLv3
// File: UsePay/UsePAY/Storage/WrapAddresses.sol


pragma solidity >= 0.7.0;

contract WrapAddresses {
    // address internal iAddresses = 0x30BafbA23f24d386a39210280590B0346c0dfd92; // UePAY_eth_rinkeby
    // address internal iAddresses = 0x31716bbA4B12A52592c041ED19Dc06B5F99e20e8; //UsePAY_bsc_testnet

    // address internal iAddresses = 0xeD05ccB1f106D57bd18C6e3bD88dB70AC936de68; // UsePAY_bsc_mainnet
    address internal iAddresses = 0xeD05ccB1f106D57bd18C6e3bD88dB70AC936de68; // UsePAY_eth_mainnet

    // address internal iAddresses = ; // UsePAY_eth_mainnet
    // address internal iAddresses = ; // UsePAY_bsc_mainnet


    // address internal iAddresses = 0x48aa9c47897B50dBF8B7dc3A1bFa4b05C481EB3d; //Bridge_eth_mainnet
    // address internal iAddresses = 0x48aa9c47897B50dBF8B7dc3A1bFa4b05C481EB3d; // Bridge_bsc_mainnet
    


    modifier onlyManager(address _addr) {
        checkManager(_addr);
        _;
    }
    
    function checkManager(address _addr) internal view {
        (, bytes memory result ) = address( iAddresses ).staticcall(abi.encodeWithSignature("checkManger(address)",_addr));
        require( abi.decode(result,(bool)) , "This address is not Manager");
    } 
}

// File: UsePay/UsePAY/Commander/Commander.sol


pragma solidity >= 0.7.0;
pragma experimental ABIEncoderV2;


contract Commander is WrapAddresses {
    
    event giftEvent(address indexed pack,address fromAddr ,address[] toAddr); // 0: pack indexed, 1: from, 2: to, 3: count
    event giveEvent(address indexed pack,address fromAddr ,address[] toAddr); // 0: pack indexed, 1: from, 2: to, 3: count
    
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }
    
    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }
    
    function _transfer(uint16 tokenType, address _to , uint256 value ) internal {
        if ( tokenType == 100 ) {
            payable(_to).transfer(value);
        } else { 
            (bool success0,bytes memory tokenResult) = address(iAddresses).staticcall(abi.encodeWithSignature("viewAddress(uint16)",uint16(tokenType)));
            require(success0,"0");
            (bool success, ) = address(abi.decode(tokenResult,(address))).call(abi.encodeWithSignature("transfer(address,uint256)",_to,value));
            require(success,"TOKEN transfer Fail");
        }
    }
    
    function _getBalance(uint16 tokenType) internal view returns (uint256) {
        uint balance = 0;
        if ( tokenType ==  100  ) {
            balance = address(this).balance;
        } else {
            (,bytes memory tokenResult) = address(iAddresses).staticcall(abi.encodeWithSignature("viewAddress(uint16)",uint16(tokenType)));
            (,bytes memory result) = address(abi.decode(tokenResult,(address))).staticcall(abi.encodeWithSignature("balanceOf(address)",address(this)));
            balance = abi.decode(result,(uint256));
        }   
        return balance;
    }
    
    function _swap( address _to, uint256 amountIn ) internal returns (uint256) {
        (,bytes memory result0 ) = address(iAddresses).staticcall(abi.encodeWithSignature("viewAddress(uint16)",1200));
        (address routerAddr) = abi.decode(result0,(address));
        (,bytes memory resultDFM ) = address(iAddresses).staticcall(abi.encodeWithSignature("viewAddress(uint16)",101));
        (bool success, bytes memory result) = address( routerAddr ).call{ value: amountIn }(abi.encodeWithSignature("exactInputSingle((address,address,uint24,address,uint256,uint256,uint256,uint160))",getExactInputSigleParams( _to, amountIn, abi.decode(resultDFM,(address))) ) );
        require( success , "swap ETH->TOKEN fail" );
            (uint256 amountOut) = abi.decode(result,(uint256));
            return amountOut;

            //  ( bool success1,) = address( _fromToken ).call( abi.encodeWithSignature( "approve(address,uint256)", routerAddr, amountIn ) );
            //  require( success1 , "tokenApprove Fail" );
            //  ( bool success2, bytes memory result ) = address( routerAddr ).call( abi.encodeWithSignature( "exactInput((bytes,address,uint256,uint256,uint256))", getExactInputParams( _to, amountIn, _fromToken, _toToken ) ) );
            //  require( success2 , "swap TOKEN->TOKEN Fail" );
            //  (uint256 amountOut) = abi.decode(result,(uint256));
            // return amountOut;
        
    }
    
    
    function getExactInputSigleParams( address _to, uint256 _amountIn, address _tokenAddr ) internal view returns ( ExactInputSingleParams memory ){
        (,bytes memory result0 ) = address(iAddresses).staticcall(abi.encodeWithSignature("viewAddress(uint16)",103));
        (address WETH) = abi.decode(result0,(address));
        uint24 fee = 500;
        uint256 deadline = block.timestamp + 15;
        uint256 amountOutMin = 0;
        uint160 sqrtPriceLimitX96 = 0;
        return ExactInputSingleParams( WETH, _tokenAddr, fee, _to, deadline, _amountIn, amountOutMin, sqrtPriceLimitX96 );
    }
    
    function getExactInputParams( address _to, uint256 _amountIn ,address _fromToken, address _toToken) internal view returns ( ExactInputParams memory ) {
        (,bytes memory result0 ) = address(iAddresses).staticcall(abi.encodeWithSignature("viewAddress(uint16)",103));
        (address WETH) = abi.decode(result0,(address));
        bytes memory path = MergeBytes(MergeBytes(MergeBytes(MergeBytes(addressToBytes(_fromToken),uintToBytes(500)),addressToBytes(WETH)),uintToBytes(500)),addressToBytes(_toToken));
        address recipient = _to;
        uint256 deadline = block.timestamp + 15;
        uint256 amountIn = _amountIn;
        uint256 amountOutMin = 1;
        return ExactInputParams( path, recipient, deadline, amountIn, amountOutMin );
    }
    
    function addressToBytes(address a) private pure returns( bytes memory) {
        return abi.encodePacked(a);
    }
    
    
    function uintToBytes( uint24 a ) private pure returns( bytes memory ) {
        return abi.encodePacked(a);
    }
 
    function MergeBytes(bytes memory a, bytes memory b) internal pure returns (bytes memory c) {
        uint alen = a.length;
        uint totallen = alen + b.length;
        uint loopsa = (a.length + 31) / 32;
        uint loopsb = (b.length + 31) / 32;
        assembly {
            let m := mload(0x40)
            mstore(m, totallen)
            for {  let i := 0 } lt(i, loopsa) { i := add(1, i) } { mstore(add(m, mul(32, add(1, i))), mload(add(a, mul(32, add(1, i))))) }
            for {  let i := 0 } lt(i, loopsb) { i := add(1, i) } { mstore(add(m, add(mul(32, add(1, i)), alen)), mload(add(b, mul(32, add(1, i))))) }
            mstore(0x40, add(m, add(32, totallen)))
            c := m
        }
    }
    
    
    function checkFee(uint count) internal {
        uint8 n = 0;
        if(count>10) {
            while (count >= 10) {
                count = count/10;
                n++;
            }
            require( msg.value > getPrice() * n * 5 , "C01");
        } else {
            require( msg.value > getPrice() , "C01");
        }
        
    }

    function getPrice() internal view returns (uint)
    {
        (,bytes memory result0 ) = address(iAddresses).staticcall(abi.encodeWithSignature("viewAddress(uint16)",1201));
        (address uniswapFactory) = abi.decode(result0,(address));
        (,bytes memory result1 ) = address(iAddresses).staticcall(abi.encodeWithSignature("viewAddress(uint16)",102));
        (address USDT) = abi.decode(result1,(address));
        (,bytes memory result2 ) = address(iAddresses).staticcall(abi.encodeWithSignature("viewAddress(uint16)",103));
        (address WETH) = abi.decode(result2,(address));
        (,bytes memory result3 ) = address(uniswapFactory).staticcall(abi.encodeWithSignature("getPool(address,address,uint24)",USDT,WETH,500));    
        address poolAddr = abi.decode(result3,(address));
        (,bytes memory result4 ) = poolAddr.staticcall(abi.encodeWithSignature("slot0()"));
        uint sqrtPriceX96 = abi.decode(result4,(uint));
        return sqrtPriceX96 * sqrtPriceX96 * 1e6 >> (96 * 2);
    }
    
    function getCountFee(uint count) external view returns (uint256) {
        uint8 n = 0;
        if(count > 10) {
            while( count >= 10 ) {
                count = count/10;
                n++;
            }
            return getPrice() * n * 5;
        } else {
            return getPrice();
        }
    }
}
// File: UsePay/UsePAY/Pack/Pack.sol


pragma solidity >= 0.7.0;


contract Ticket is WrapAddresses {

    uint8 ver = 1;

    struct pack {
        uint32 hasCount;
        uint32 useCount;
    }
    
    address internal owner;
    uint256 internal quantity;
    uint256 internal refundCount = 0;
    
    struct PackInfo {
        uint32 total;
        uint32 times0;
        uint32 times1;
        uint32 times2;
        uint32 times3;
        uint256 price;
        uint16 tokenType;
        uint8 noshowValue;
        uint8 maxCount;
    }
    
    mapping(address=>pack) internal buyList;
    
    PackInfo internal packInfo;
    uint8 internal isCalculated = 0;
    uint32 internal totalUsedCount = 0;
}

contract Coupon is WrapAddresses {
    
    uint8 ver = 1;

    struct pack {
        uint32 hasCount;
        uint32 useCount;
    }
    
    uint256 internal quantity;
    
    mapping(address=>pack) internal buyList;
    
    struct PackInfo {
        uint32 total;
        uint32 maxCount;
        uint32 times0;
        uint32 times1;
        uint32 times2;
        uint32 times3;
    }
    address internal owner;
    PackInfo internal packInfo;
}

contract Subscription is WrapAddresses {

    uint8 ver = 1;

    struct pack {
        uint32 hasCount;
    }
    
    uint256 internal refundCount = 0;
    uint256 internal noshowCount = 0;
    uint256 internal noshowLimit = 0;
    uint256 internal quantity;
    uint256 internal isLive = 0;
    uint256 internal noShowTime = 0;
    address internal owner;
    
    struct PackInfo {
        uint32 total;
        uint32 times0;
        uint32 times1;
        uint32 times2;
        uint32 times3;
        uint256 price;
        uint16 tokenType;
    }
    
    mapping(address=>pack) internal buyList;
    
    PackInfo packInfo;
}
// File: UsePay/UsePAY/Pack/CouponPack.sol


pragma solidity >= 0.7.0;


contract CouponPack is Coupon {
    constructor ( PackInfo memory _packInfo , address _owner ) {
        packInfo = _packInfo;
        owner = _owner;
        quantity = _packInfo.total;
    }
    
    
    receive () external payable {}
    fallback() external payable {
        (bool success, bytes memory result0) = address( iAddresses ).staticcall(abi.encodeWithSignature("viewAddress(uint16)",10001));
        require( success, "viewCouponCommander Fail");
        (address coupon_commander) = abi.decode(result0,(address));
        //get Data 
        assembly {
            let ptr := mload( 0x40 )
            calldatacopy( ptr, 0, calldatasize() )
            let result := delegatecall( gas(), coupon_commander , ptr, calldatasize(), 0, 0 )
            returndatacopy( ptr, 0, returndatasize() )
            switch result 
                case 0 { //fail
                    revert( ptr, returndatasize() )
                } 
                default { //success
                    return( ptr, returndatasize() )
                }
        }
    }
}
// File: UsePay/UsePAY/Commander/CouponCommander.sol


pragma solidity >= 0.7.0;


contract CouponCommander is Commander,Coupon {
     
    event buyEvent(address indexed pack, uint256 buyNum, address buyer,uint256 count); // 0: pack indexed, 1: buyer, 2: count 
    event useEvent(address indexed pack, address user,uint256 count); // 0: pack indexed, 1: buyer, 2: count 
    event requestRefundEvent(address indexed pack, address buyer ,uint256 count); // 0: pack indexed, 1: buyer, 2: count
    event calculateRefundEvent(address indexed pack, address[] buyers ) ;
    event calculateEvent(address indexed); 
    event changeTotalEvent(address indexed,uint256 _before,uint256 _after);

    //-----------------------------------------
    //  modifiers
    //-----------------------------------------
    
    
    modifier onlyOwner() { require ( msg.sender == owner, "O01" ); _; }
    modifier canUse(uint256 count) { 
        require ( buyList[msg.sender].hasCount - buyList[msg.sender].useCount >= count, "U02" );
        _; 
    }
    modifier canBuy(uint256 count) { 
        require (count<=packInfo.maxCount,"");
        require ( block.timestamp >= packInfo.times0 && block.timestamp <= packInfo.times1, "B01" ); 
        require ( quantity - count >= 0 , "B04"); 
        _; 
    }


    function _buy(uint32 count, address buyer) private {
        buyList[buyer].hasCount = buyList[buyer].hasCount+( count );
        quantity = quantity - count ;
    }
    
    
    //-----------------------------------------
    //  payableFunctions
    //-----------------------------------------
    
    function buy( uint32 count , uint256 buyNum ) external payable canBuy(count) {
        _buy(count, msg.sender);
        emit buyEvent(  address( this ), buyNum, msg.sender, count );
    }
    
    function give(address[] memory toAddr) external payable canUse( toAddr.length ) {
        require(block.timestamp<packInfo.times3,"");
        buyList[msg.sender].hasCount = buyList[msg.sender].hasCount- uint32(toAddr.length);
        for(uint i=0; i<toAddr.length; i++) {
            buyList[toAddr[i]].hasCount++;
        }
        emit giveEvent( address(this), msg.sender, toAddr );
    }
    
    function gift( address[] memory toAddr ) external payable canBuy(toAddr.length) {
        for ( uint i =0; i<toAddr.length; i++) {
            buyList[toAddr[i]].hasCount++;
        }
        quantity = quantity - toAddr.length ;
        emit giftEvent( address(this), msg.sender, toAddr);
    }
    
    function use( uint32 _count ) external payable canUse( _count ) {
        require ( block.timestamp > packInfo.times2 && block.timestamp < packInfo.times1, "U01" );
        buyList[msg.sender].useCount = buyList[msg.sender].useCount+(_count);
        emit useEvent( address( this ), msg.sender, _count );
    }
    
    function changeTotal(uint32 _count) external payable onlyOwner {
        require(packInfo.total - quantity <= _count,"count too high");
        if ( _count > packInfo.total ) {
            checkFee(_count-packInfo.total);    
            _swap(msg.sender,msg.value);
            quantity = quantity + ( _count - packInfo.total );
        }else {
            quantity = quantity - ( packInfo.total - _count );
        }
        emit changeTotalEvent(address(this),packInfo.total,_count);
        packInfo.total = _count;
    }
    
    
    //-----------------------------------------
    //  viewFunctions
    //-----------------------------------------
    function viewInfo() external view returns (PackInfo memory) { return packInfo; }
    
    function viewUser(address _addr) external view returns (pack memory) { return buyList[_addr]; }
    
    function viewQuantity() external view returns (uint256) { return quantity; }
    
    function viewOwner() external view returns (address) { return owner; }

    function viewVersion() external view returns (uint8) { return ver; }
}