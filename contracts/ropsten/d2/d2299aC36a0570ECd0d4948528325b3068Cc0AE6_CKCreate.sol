// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface IKey {
    function burn(uint256 tokenId)  external;
}

interface ICK{
    function safeMint(address to,string memory _id,uint _lifecycle) external;
}

contract CKCreate is Pausable{
    using Strings for string;
    mapping(address=>uint256) public seeds;
    mapping(uint256=>uint256) private baseSeeds;
    // address public keyAddress;
    // address public ckAddress;
    ICK public _ck;
    IKey public _iKey;
    address public  admin;
   
    constructor(){
       admin=msg.sender;
    }
    modifier onlyAdmin{
         require(msg.sender==admin,"not admin");
         _;
    }
    function setKeyAddress(address _keyAddress) public onlyAdmin{
        _ck=ICK(_keyAddress);
    } 
    function setCkAddress(address _ckAddress) public onlyAdmin{
        _iKey=IKey(_ckAddress);
    } 

    modifier seedInit() {
         require(seeds[msg.sender]!=0,"the seed is init");
         _;
    }

    function setSeeds() public {
        baseSeeds[0]=12312312312312312312;
        baseSeeds[1]=12312412312312312312;
        baseSeeds[2]=12312512312312312312;
        baseSeeds[3]=1232212312312312312;
        baseSeeds[4]=32312612312312312312;
        baseSeeds[5]=42312312312312312312;
        baseSeeds[6]=52312312312312312312;
        baseSeeds[7]=62312312312312312312;
        baseSeeds[8]=72312312312312312312;
        baseSeeds[9]=82312312312312312312;    
    }

    function getSeeds(uint256 _mod,string memory _extSeeds) private  returns(uint256){
              //获取下标
            uint256 index=uint256(keccak256(abi.encode(_extSeeds,block.number, block.timestamp,msg.sender)))%10;

            uint256 value= baseSeeds[index];

            uint256 rand=uint256(keccak256(abi.encode(_extSeeds,block.number, block.timestamp,value)));
             
            //筛选新的下标置换值
            baseSeeds[rand%10]=rand;
            return rand%_mod;
    }


    function getRandomNumber() public  returns(uint256,address){
       seeds[msg.sender]=uint256(keccak256(abi.encode("rand",block.number, block.timestamp)));
       return (seeds[msg.sender],msg.sender);
    }

    //创造
    function mintCK( uint256 tokenId) public  seedInit whenNotPaused{
        _iKey.burn(tokenId);
        string memory qarity=getQarity();
        string memory blood=getBlood();
        string memory career= getCareer();
        string memory special=getSpecial(qarity,blood,career);
        //    uint STR;//力量
        //    uint INT;//智力
        //    uint AGL;//敏捷
        //    uint CON;//体质
        //    uint MEN;//精神
        //    uint LUK;//幸运
        uint str=getProperty(qarity,"str");
        uint inte=getProperty(qarity,"inte");
        uint agl=getProperty(qarity,"agl");
        uint con=getProperty(qarity,"con");
        uint men=getProperty(qarity,"men");
        uint luk=getProperty(qarity,"luk");
        string memory id= string(abi.encodePacked(
        "C01",
        qarity,
        blood,
        fillZero(str,10),
        fillZero(inte,10),
        fillZero(agl,10),
        fillZero(con,10),
        fillZero(men,10),
        fillZero(luk,10),
        "001"  
        ));
        id=string(abi.encodePacked(id, career,special));
        uint lifecycle= getLifecycle(qarity);   
        _ck.safeMint(msg.sender,id,lifecycle);
    }
    //填0
    function  fillZero(uint _uint,uint _max) private pure returns(string memory){
           if(_uint<_max){
              return  string(abi.encodePacked("0",Strings.toString(_uint)));
           }else{
               return string(abi.encodePacked(Strings.toString(_uint)));
           }
    }
    //获取品质
    function getQarity() private   returns(string memory){
      //01批次
       uint256 tmepRand=getSeeds(10000,"Qarity");
        if(tmepRand<3000){
            return "02";
        } else if(3000<=tmepRand&&tmepRand<9300){     
            return "03";
        }else{     
            return "04";
        }
    }

    //获取血统
    function getBlood() private    returns (string memory){
        uint256 tmepRand=getSeeds(10000,"boold");    
        if(tmepRand<3000){
            return "001";
        }
        else if(3000<=tmepRand&&tmepRand<6000){
            return "002";
        }
        else if(6000<=tmepRand&&tmepRand<9000){
            return "003";
        }
        else{
            return "004";
        }    
    }
    //获取属性值
    function getProperty(string memory _qarity,string memory extraSeed)  private   returns(uint){
        //品质加值
        uint256 tmepRandQarity=getSeeds(10000,extraSeed);
        //批次随机数(批次加值)
        uint256 tmepRandBatch=getSeeds(10000,extraSeed);
        //基础值
        //品质
        //稀有
        if(keccak256(bytes(_qarity))==keccak256("02")){
             //批次加值
             if(tmepRandQarity<2000){  
                return 8+(tmepRandBatch<5000?0:1);
             }else if(2000<=tmepRandQarity&&tmepRandQarity<7000){
                 return 9+(tmepRandBatch<5000?0:1);
             }else{
                 return 10+(tmepRandBatch<5000?0:1);
             }
             
        }
        //史诗
        else if(keccak256(bytes(_qarity))==keccak256("03")){
             //批次加值
             if(tmepRandQarity<3000){  
                return 9+(tmepRandBatch<3000?0:1);
             }else if(3000<=tmepRandQarity&&tmepRandQarity<7000){
                 return 10+(tmepRandBatch<3000?0:1);
             }else{
                 return 11+(tmepRandBatch<3000?0:1);
             }


        }
        //传说
        else{
             //批次加值
             if(tmepRandQarity<3000){  
                return 10+(tmepRandBatch<9500?1:tmepRandBatch<9950?2:3);
             }else if(3000<=tmepRandQarity&&tmepRandQarity<8000){
                 return 11+(tmepRandBatch<9500?1:tmepRandBatch<9950?2:3);
             }else{
                 return 12+(tmepRandBatch<9500?1:tmepRandBatch<9950?2:3);
             }
        }
    }
    //获取职业
    function getCareer() private  returns(string memory){         
        uint256 tmepRand=getSeeds(10000,"career");
        if(tmepRand<3333){
            return "$001$";
        }else if(3333<=tmepRand&&tmepRand<6666){
            return "$002$";
        }else{
            return "$003$";
        }
    }
    //生命周期
    function getLifecycle(string memory _qarity) private   returns(uint){
       
        //稀有
         if(keccak256(bytes(_qarity))==keccak256("02")){
               uint256 tmepRandQarity=getSeeds(50,"Lifecycle");
               return 350+ tmepRandQarity;   
         }
         //史诗
         else if(keccak256(bytes(_qarity))==keccak256("03")){
               uint256 tmepRandQarity=getSeeds(70,"Lifecycle");
               return 460+ tmepRandQarity;   
         }
         //传说
         else{
               uint256 tmepRandQarity=getSeeds(100,"Lifecycle");
               return 580+ tmepRandQarity;   
         }
    }
    function getSpecial(string memory _qarity,string memory _blood,string memory _career) private  returns(string memory){
        uint[] memory code= getSpecialCode(_qarity,_blood,_career);
        uint[] memory weight= getSpecialWeight(_qarity,_blood,_career);

        uint temp = getSeeds(weight[weight.length-1],"Special");
        uint current=0;
        for(uint i=0;i<weight.length;i++){
            if(temp<=weight[i]){
                current=i;
                break;
            }
        }
        return fillZeroSpecial(code[current],10,100);  
    }
    function  fillZeroSpecial(uint _uint,uint _min,uint _max) private pure returns(string memory){
           string memory temp;
           if(_uint<_min){
              temp= string(abi.encodePacked("00",Strings.toString(_uint)));
           }else if(_min<=_uint&&_uint<_max){
             temp=  string(abi.encodePacked("0",Strings.toString(_uint)));
           }
           else{
              temp= string(abi.encodePacked(Strings.toString(_uint)));
           }
           return string(abi.encodePacked("%",temp,"%"));
    }
    //获取code
    function getSpecialCode(string memory _qarity,string memory _blood,string memory _career) private pure returns(uint[] memory){
          uint8[21] memory qarityCode=[1, 2, 3, 4,5,6,7, 8,9,10,11,12,13,14,15,16,17,18,19,20,21];
          uint16[5] memory bloodCode=[101,102,201,301,401];
          uint16[6] memory careerCode=[501,502,601,602,701,702];
          uint qarityLen=0;


          int bloodIndex=-1;
          int bloodIndex2=-1;
          int careerIndex=-1;
          int careerIndex2=-1;

          uint newLen=0;
          //品质
          if(keccak256(bytes(_qarity))==keccak256("02")){
             qarityLen=13;
          }else if(keccak256(bytes(_qarity))==keccak256("03")){
             qarityLen=19;
          }else{
             qarityLen=21;
          }
          //血统
          if(keccak256(bytes(_blood))==keccak256("001")){
            bloodIndex=0;
            bloodIndex2=1;
          }else if(keccak256(bytes(_blood))==keccak256("002")){
            bloodIndex=2;
          }else if(keccak256(bytes(_blood))==keccak256("003")){
            bloodIndex=3;
          }else{
            bloodIndex=4;
          }

          //职业
          if(keccak256(bytes(_career))==keccak256("001")){
            careerIndex=0;
            careerIndex2=1;

          }else if(keccak256(bytes(_career))==keccak256("002")){
            careerIndex=2;
            careerIndex2=3;
          }else{
            careerIndex=4;
            careerIndex2=5;            
          } 
          //计算新数组长度
          newLen=qarityLen+2+(bloodIndex2==-1?1:2);
          uint[] memory newArr=new uint[](newLen);
          //添加元素
          for(uint i=0;i<qarityLen;i++){
              newArr[i]=qarityCode[i];
          }
          newArr[qarityLen+0]=careerCode[uint(careerIndex)];
          newArr[qarityLen+1]=careerCode[uint(careerIndex2)];
          newArr[qarityLen+2]=bloodCode[uint(bloodIndex)];
          if(bloodIndex2!=-1){
             newArr[qarityLen+3]=bloodCode[uint(bloodIndex2)];
          }
          return newArr;
                       
    }
    //获取权重
    function getSpecialWeight(string memory _qarity,string memory _blood,string memory _career) private pure returns(uint[] memory){
          uint8[21] memory qarityWeight=[50,50,50,50,50,50,75,75,75,75,75,75,70, 150,150,150,150,150,130,250,250];
          uint8[5] memory bloodWeight=[250,250,150,150,150];


          uint8[6] memory careerWeight=[150,150,150,150,150,150];
          uint qarityLen=0;

          int bloodIndex=-1;
          int bloodIndex2=-1;
          int careerIndex=-1;
          int careerIndex2=-1;

          uint newLen=0;
          //品质
          if(keccak256(bytes(_qarity))==keccak256("02")){
             qarityLen=13;
          }else if(keccak256(bytes(_qarity))==keccak256("03")){
             qarityLen=19;
          }else{
             qarityLen=21;
          }
          //血统
          if(keccak256(bytes(_blood))==keccak256("001")){
            bloodIndex=0;
            bloodIndex2=1;
          }else if(keccak256(bytes(_blood))==keccak256("002")){
            bloodIndex=2;
          }else if(keccak256(bytes(_blood))==keccak256("003")){
            bloodIndex=3;
          }else{
            bloodIndex=4;
          }

          //职业
          if(keccak256(bytes(_career))==keccak256("001")){
            careerIndex=0;
            careerIndex2=1;

          }else if(keccak256(bytes(_career))==keccak256("002")){
            careerIndex=2;
            careerIndex2=3;
          }else{
            careerIndex=4;
            careerIndex2=5;            
          } 
          //计算新数组长度
          newLen=qarityLen+2+(bloodIndex2==-1?1:2);
          uint[] memory newArr=new uint[](newLen);
          //添加元素
          for(uint i=0;i<qarityLen;i++){
              if(i==0){
                newArr[i]=qarityWeight[i];
              }else{
                newArr[i]=qarityWeight[i]+newArr[i-1];
              }
              
          }
          newArr[qarityLen+0]=careerWeight[uint(careerIndex)]+newArr[qarityLen-1];
          newArr[qarityLen+1]=careerWeight[uint(careerIndex2)]+newArr[qarityLen];
          newArr[qarityLen+2]=bloodWeight[uint(bloodIndex)]+newArr[qarityLen+1];
          if(bloodIndex2!=-1){
             newArr[qarityLen+3]=bloodWeight[uint(bloodIndex2)]+newArr[qarityLen+2];
          }
          return newArr;                     
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}