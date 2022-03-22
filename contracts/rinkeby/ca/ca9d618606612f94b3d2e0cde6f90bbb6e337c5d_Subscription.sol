/**
 *Submitted for verification at Etherscan.io on 2022-03-22
*/

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _msgValue() internal view virtual returns (uint) {
        return msg.value;
    }
}

abstract contract Ownable is Context {
    
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract Referrable is Ownable {
  uint[] public referral = [300, 200, 100]; // 5%, 3%, 2%
  uint256 public constant PERCENTS_DIVIDER = 1000;

  function updateReferral(uint index, uint value) public onlyOwner {
    require(index < referral.length, "Referral index out of bound");
    require(value <= 100, "Percentages must be less than 10%");
    referral[index] = value;
  }
}

contract Subscription is Referrable {

  struct Plan {
    uint price;
    uint duration;
    bool expired;
  }
  
  struct User {
    uint validUntil;
    address referrer;
    uint[3] levels;
    uint bonus;
    uint withdrawn;
  }

  Plan[] internal plans;
  mapping(address => User) internal users;

  constructor() {
    plans.push(Plan(60000000000000000, 30, false)); // 1 month
    plans.push(Plan(150000000000000000, 90, false)); // 3 months
    plans.push(Plan(300000000000000000, 3650, false)); // 10 years
  }

  function subscribe(uint planId, address referrer) public payable {
    require(planId < plans.length);
    require( _msgValue() >= plans[planId].price);
    require(plans[planId].expired == false, "Plan is expired");

    User storage user = users[_msgSender()];
    uint payment = _msgValue();

    if (user.referrer == address(0)) {
      if (isSubscribed(referrer) && referrer != msg.sender) {
        user.referrer = referrer;
      } 

      address upline = user.referrer;
      for (uint8 i = 0; i < 3; ++i) {
        if (upline != address(0)) {
          users[upline].levels[i] += 1;
          upline = users[upline].referrer;
        } else break;
      }
    }

    if (user.referrer != address(0)) {
      address upline = user.referrer;
      for (uint256 i = 0; i < 3; i++) {
        if (upline != address(0)) {
          uint256 amount = (_msgValue() * referral[i])/PERCENTS_DIVIDER;
          users[upline].bonus += amount;
          payment -= amount;
          upline = users[upline].referrer;
        } else break;
      }
    }

    if (user.validUntil == 0) {
      user.validUntil = block.timestamp;
    }

    user.validUntil += plans[planId].duration * 1 days;

    payable(owner()).transfer(payment);
  }

  function withdraw() public {
    User storage user = users[_msgSender()];
    uint amount = users[_msgSender()].bonus;
    
    require(amount > 0, "User has no referral bonus");
    user.bonus = 0;
    user.withdrawn += amount;
    
    payable(_msgSender()).transfer(amount);
  }

  function isSubscribed(address owner) public view returns (bool) {
    User storage user = users[owner];
    return user.validUntil > block.timestamp;
  }

  function isContract(address addr) internal view returns (bool) {
    uint256 size;
    assembly {
      size := extcodesize(addr)
    }
    return size > 0;
  }

  function addPlan(uint price, uint duration) public onlyOwner {
    require(price > plans[plans.length - 1].price, "Price must be greater than previous plan");
    require(duration > plans[plans.length - 1].duration, "Duration must be greater than previous plan");

    plans.push(Plan(price, duration, false));
  }

  function expirePlan(uint i) public onlyOwner {
    require(i < plans.length, "Index out of bound");
    plans[i].expired = true;
  }

  function revivePlan(uint i) public onlyOwner {
    require(i < plans.length, "Index out of bound");
    plans[i].expired = false;
  }

  function updatePlan(uint i, uint price, uint duration) public onlyOwner {
    require(i < plans.length, "Plan index out of bounds");
    plans[i].price = price;
    plans[i].duration = duration;
  }

  function getPlan(uint i) public view returns (Plan memory) {
    return plans[i];    
  }

  function getUser(address owner) public view returns (User memory) {
    return users[owner];
  }
}