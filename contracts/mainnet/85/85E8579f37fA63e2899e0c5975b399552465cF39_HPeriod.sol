/**
 *Submitted for verification at Etherscan.io on 2022-04-11
*/

// File: contracts/utils/SafeMath.sol

pragma solidity >=0.4.21 <0.6.0;

library SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a, "add");
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a, "sub");
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b, "mul");
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0, "div");
        c = a / b;
    }
}

// File: contracts/utils/Ownable.sol

pragma solidity >=0.4.21 <0.6.0;

contract Ownable {
    address private _contract_owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = msg.sender;
        _contract_owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _contract_owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_contract_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_contract_owner, newOwner);
        _contract_owner = newOwner;
    }
}

// File: contracts/core/HPeriod.sol

pragma solidity >=0.4.21 <0.6.0;



contract HPeriod is Ownable{
  using SafeMath for uint;

  uint256 period_start_block;//the start block of the first round
  uint256 period_block_num;//the length in block of a round

  mapping (uint256 => uint256) public all_rounds_start_block;//the start block of all rounds
  uint256 current_round;//the index of current round

  constructor(uint256 _start_block, uint256 _period_block_num) public{
    period_start_block = _start_block;
    period_block_num = _period_block_num;

    current_round = 0;
  }

  function _end_current_and_start_new_round() internal returns(bool){
    require(block.number >= period_start_block, "1st period not start yet");
    if(current_round == 0 || block.number.safeSub(all_rounds_start_block[current_round]) >= period_block_num){
      current_round = current_round + 1;
      all_rounds_start_block[current_round] = block.number;
      return true;
    }
    return false;
  }

  function updatePeriodStatus() public onlyOwner returns(bool){
    return _end_current_and_start_new_round();
  }


  //event HPeriodChanged(uint256 old, uint256 new_period);
  //function _change_period(uint256 _period) internal{
    //uint256 old = period_block_num;
    //period_block_num = _period;
    //emit HPeriodChanged(old, period_block_num);
  //}

  function getCurrentRoundStartBlock() public view returns(uint256){
    return all_rounds_start_block[current_round];
  }

  function getParamPeriodStartBlock() public view returns(uint256){
    return period_start_block;
  }

  function getParamPeriodBlockNum() public view returns(uint256){
    return period_block_num;
  }

  function getCurrentRound() public view returns(uint256){
    return current_round;
  }

  function getRoundLength(uint256 _round) public view returns(uint256){
    require(isRoundEnd(_round), "HPeriod: round not end");
    return all_rounds_start_block[_round + 1].safeSub(all_rounds_start_block[_round]);
  }

  function isRoundEnd(uint256 _round) public view returns(bool){
    return all_rounds_start_block[_round + 1] > 0;
  }

  function isRoundStart(uint256 _round) public view returns(bool){
    return all_rounds_start_block[_round] != 0;
  }
}

contract HPeriodFactory{
  event NewHPeriod(address addr);

  function createHPeriod(uint256 _start_block, uint256 _period_block_num) public returns(address){
      HPeriod dis = new HPeriod(_start_block, _period_block_num);
      dis.transferOwnership(msg.sender);
      emit NewHPeriod(address(dis));
      return address(dis);
  }
}