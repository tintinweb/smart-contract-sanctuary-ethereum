/**
 *Submitted for verification at Etherscan.io on 2022-08-05
*/

//SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;
library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}
interface IERC20 {
   
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

   
    function allowance(address owner, address spender) external view returns (uint256);


    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}
interface IERC165 {

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool _approved) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function isApprovedForAll(address owner, address operator) external view returns (bool);
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address ) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; 
        return msg.data;
    }
}
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
    constructor ()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

  
    function owner() public view virtual returns (address) {
        return _owner;
    }

 
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

   
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }


    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
contract GossamerStaking is Ownable
{
   using SafeMath for uint256;
    IERC20 public token;
    IERC721 public moth;
    IERC721 public warrior;
    IERC721 public serum;
 constructor(IERC721 _moth,IERC721 _warrior,IERC721 _serum,IERC20 _token)
 {
     moth=_moth;
     warrior=_warrior;
     serum=_serum;
     token=_token;

 }
 uint256 private  stakeCount = 1 ;
 uint256 public totalNfts;
 uint256 private ONE_WEEK_SEC= 3600 ;//604800;  
   struct staking {
        address owner;
        uint256 startTime;
        uint256 week;
        uint256 [] mothCount;
        uint256 [] warriorCount;
        uint256 [] serumCount;
        bool collected;
        uint256 claimed;
        uint256 lastclaime;
    }

 mapping(uint256=> staking) public stakeDetail;
 mapping(address=>uint256 []) public Stakes;
 mapping(uint256=>uint256) public APY;

    function stakeNft(uint256 [] memory _warrior,uint256  [] memory _moth,uint256 [] memory _serum,uint256 week ) public 
    {
        require(week == 2 || week == 4 || week == 12 || week == 48 , "ENTER VALID week");
        require(_warrior.length !=0 || _moth.length !=0 || _serum.length !=0,"Arrays cant be empty");
        _stake(_warrior,_moth,_serum,week);
    }
    function _stake(uint256 [] memory _warrior,uint256 [] memory _moth,uint256 [] memory _serum,uint256 week) private 
    {
        if(_warrior.length>0)
        {
            for (uint256 i=0;i<_warrior.length;i++)
            {
              stakeDetail[stakeCount].warriorCount.push(_warrior[i]);
              warrior.transferFrom(msg.sender,address(this),_warrior[i]);
              totalNfts +=1 ;
            }
        }
          if(_moth.length>0)
        {
            for (uint256 i=0;i<_moth.length;i++)
            {
              stakeDetail[stakeCount].mothCount.push(_moth[i]);
              moth.transferFrom(msg.sender,address(this),_moth[i]);
               totalNfts +=1 ;
            }
        }
         if(_serum.length>0)
        {
            for (uint256 i=0;i<_serum.length;i++)
            {
              stakeDetail[stakeCount].serumCount.push(_serum[i]);
              serum.transferFrom(msg.sender,address(this),_serum[i]);
               totalNfts +=1 ;
            }
        }
        stakeDetail[stakeCount].owner = msg.sender;
        stakeDetail[stakeCount].week += week;
        stakeDetail[stakeCount].startTime = block.timestamp;
        stakeDetail[stakeCount].lastclaime = block.timestamp;
        Stakes[msg.sender].push(stakeCount);
        stakeCount +=1;
    }

    function _getreward(uint256  _stakeid) public view returns (uint256)
    {
      require(stakeDetail[_stakeid].week !=0 ,"invalid stake id");
      require(stakeDetail[_stakeid].collected ==false,"USER ALREADY UNSTAKE");
      uint256 totalstaketime = stakeDetail[_stakeid].week.mul( ONE_WEEK_SEC);
      uint256 times = block.timestamp.sub(stakeDetail[_stakeid].lastclaime);
      uint256 getvalue = _bonusCalculations( _stakeid,  times,totalstaketime);
    if (totalNfts >= 6000)
    {
      getvalue = getvalue + (times.mul(200 ether )).div(ONE_WEEK_SEC);
    }
      return getvalue ;
      

    }
    function _bonusCalculations(uint256  _stakeid, uint256 times,uint256 totalstaketime ) internal view returns (uint256)
    {
      uint256 _moth = (((10 ether * APY[stakeDetail[_stakeid].week]).mul(times)).div(totalstaketime)).mul(stakeDetail[_stakeid].mothCount.length);
      uint256 _warrior = (((10 ether * APY[stakeDetail[_stakeid].week]).mul(times)).div(totalstaketime)).mul(stakeDetail[_stakeid].warriorCount.length);
      uint256 id = _stakeid;
      uint256 _serum = (((5 ether * APY[stakeDetail[id].week]).mul(times)).div(totalstaketime)).mul(stakeDetail[id].serumCount.length);
      uint256 sum = (_moth.add(_warrior)).add(_serum);
      if (stakeDetail[id].mothCount.length>0 && stakeDetail[id].warriorCount.length > 0 )
      {
          sum =( sum.div(1 ether)).mul(1.1 ether);
      }
       if (stakeDetail[id].mothCount.length>0 && stakeDetail[id].serumCount.length > 0 && stakeDetail[id].warriorCount.length > 0  )
      {
          sum = sum.mul(2);
      }
      return sum ;
    }
    function claim (uint256  _stakeid) public 
    {
      require(stakeDetail[_stakeid].owner ==msg.sender ,"invalid stake id");
      require(stakeDetail[_stakeid].collected ==false ,"already unstake");
      require(stakeDetail[_stakeid].lastclaime + ONE_WEEK_SEC <= block.timestamp ,"time not reached yet");
      uint256 amount = _getreward( _stakeid);
     if (stakeDetail[_stakeid].mothCount.length>0 && stakeDetail[_stakeid].serumCount.length > 0 && stakeDetail[_stakeid].warriorCount.length > 0  )
      {
          transferAmount(amount);
      }
      else {
           require(stakeDetail[_stakeid].lastclaime + ONE_WEEK_SEC.mul(2) <= block.timestamp ,"time not reached yet");
            transferAmount(amount);
      }
      stakeDetail[_stakeid].lastclaime=block.timestamp;

    }

    function transferAmount(uint256 _amount ) private {
      
      token.transfer(msg.sender, _amount);

    }

    function unstake ( uint256 _stakeid) public  {
     require(stakeDetail[_stakeid].owner ==msg.sender ,"invalid stake id");
     require(stakeDetail[_stakeid].collected ==false ,"already unstake");
     require(ONE_WEEK_SEC.mul(stakeDetail[_stakeid].week) + stakeDetail[_stakeid].startTime <= block.timestamp   ,"lock period not end yet");
      uint256 amount = _getreward( _stakeid);
       if (stakeDetail[_stakeid].mothCount.length>0 && stakeDetail[_stakeid].serumCount.length > 0 && stakeDetail[_stakeid].warriorCount.length > 0  )
      {
          transferAmount(amount);
          transferNfts( _stakeid);
      }
      else {
           require(stakeDetail[_stakeid].lastclaime + ONE_WEEK_SEC.mul(2) <= block.timestamp ,"time not reached yet");
            transferAmount(amount);
            transferNfts( _stakeid);
      }

    }
    function transferNfts(uint256 _stakeid) private
    {

          if(stakeDetail[_stakeid].warriorCount.length >0)
        {
            for (uint256 i=0;i<stakeDetail[_stakeid].warriorCount.length;i++)
            {
      
              warrior.transferFrom(address(this),msg.sender,stakeDetail[_stakeid].warriorCount[i]);
             
            }
        }
          if(stakeDetail[_stakeid].mothCount.length>0)
        {
            for (uint256 i=0;i<stakeDetail[_stakeid].mothCount.length;i++)
            {
            
              moth.transferFrom(address(this),msg.sender,stakeDetail[_stakeid].mothCount[i]);
            }   
        }
         if(stakeDetail[_stakeid].serumCount.length>0)
        {
            for (uint256 i=0;i<stakeDetail[_stakeid].serumCount.length;i++)
            {
            
              serum.transferFrom(address(this),msg.sender,stakeDetail[_stakeid].serumCount[i]);
          
            }
        }
        stakeDetail[_stakeid].collected=true;
    }
    

     function setAPYs(uint256[] memory apys) external onlyOwner {
       require(apys.length == 4,"4 INDEXED ARRAY ALLOWED");
        APY[2] = apys[0];
        APY[4] = apys[1];
        APY[12] = apys[2];
        APY[48] = apys[3];
     
    }
    




}