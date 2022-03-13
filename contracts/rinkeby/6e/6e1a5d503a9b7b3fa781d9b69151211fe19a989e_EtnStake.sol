/**
 *Submitted for verification at Etherscan.io on 2022-03-13
*/

pragma solidity =0.6.6;
pragma experimental ABIEncoderV2;

/**
 * Math operations with safety checks
 */
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }


    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

interface ERC20 {
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
}

contract EtnStake is Ownable{
    using SafeMath for uint;

    struct Record {
        address staker;
        uint nftId;
        uint stake;
        uint stakeAt;
    }

    mapping (uint => Record) public records;
    mapping (uint => uint) public nftMap;

    uint public count;
    uint public expireTime = 2592000;
    ERC20 public etncoins;

    uint constant private minInvestmentLimit = 10 finney;

    event GovWithdrawToken( address indexed to, uint256 value);
    event Stake(address indexed from, uint nftId , uint256 amount);

    constructor(address _etncoins)public {
        etncoins = ERC20(_etncoins);
    }

    function stake(uint _nftId,uint _value) public{
        require(_value >= minInvestmentLimit,"!stake limit");
        uint allowed = etncoins.allowance(msg.sender,address(this));
        uint balanced = etncoins.balanceOf(msg.sender);
        require(allowed >= _value, "!allowed");
        require(balanced >= _value, "!balanced");
        etncoins.transferFrom(msg.sender,address(this), _value);

        records[count] = Record(msg.sender,_nftId, _value,block.timestamp);
        count++;
        nftMap[_nftId] = nftMap[_nftId] + _value;
        emit Stake( msg.sender,_nftId, _value);
    }



    function getNftStake(uint _nftId, bool _canExpire) public view returns (uint){
        if(_canExpire){
            uint rs = 0;
            for (uint i = 0; i < count; i++) {
                if(records[i].nftId != _nftId){
                    continue;
                }
                if(records[i].stakeAt + expireTime < now){
                    continue;
                }
                rs = rs + records[i].stake;
            }
            return rs;
        }else{
            return nftMap[_nftId];
        }

    }

    function getUserStake(address _addr, uint _nftId, bool _canExpire) public view returns (uint){
        uint rs = 0;
        for (uint i = 0; i < count; i++) {
            if(records[i].staker != _addr || records[i].nftId != _nftId){
                continue;
            }
            if(_canExpire && records[i].stakeAt + expireTime < now){
                continue;
            }
            rs = rs + records[i].stake;
        }
        return rs;
    }


    function setExpireTime(uint _expireTime) public onlyOwner {
        expireTime = _expireTime;
    }

    function setToken(address _etncoins) public onlyOwner {
        etncoins = ERC20(_etncoins);
    }

    function withdrawToken(address _to,uint256 _amount) public onlyOwner {
        require(_amount > 0, "!zero input");
        etncoins.transfer( _to, _amount);
        emit GovWithdrawToken( _to, _amount);
    }
}