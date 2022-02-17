/**
 *Submitted for verification at Etherscan.io on 2022-02-17
*/

// SPDX-License-Identifier: UNLISCENSED
pragma solidity ^0.6.0;

contract Context {
    constructor() internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; 
        return msg.data;
    }
}
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

   
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

   
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
    




interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract GVOToken is IERC20 {

    event Bought(uint256 amount);
    event Sold(uint256 amount);
    event TransferSent(address _from, address _destAddr, uint _amount);
    
    IERC20 public token;

    string public constant name = "Good Vibes Only Token";
    string public constant symbol = "GVO";
    uint8 public constant decimals = 0;
    uint256 public _decimalFactor =10**7;

    uint256 tokenBalance;

    
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);


    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;

    // uint256 totalSupply_ = 20383846;

    uint256 totalSupply_ = 20383846 * _decimalFactor;

    using SafeMath for uint256;
    // uint public minPurchase;
    // uint public maxPurchase = 4; // 4 ether
    uint public minPurchase =250;
    uint public maxPurchase = 4; // 4 ether

    uint public availableTokensICO;
    uint256 public endICO;
    uint256 public softCap;
    uint256 public hardCap;
    uint256 public numbersofslot = 100; // Slot 100
    uint256 public PresellPercent = 500; //5.0

    uint256 public founderNFT = 11041250;
    uint256 public incubatorToken = 2853738;
    uint256 public DefiToken = 2038385;
    uint256 public project = 2038385;
    uint256 public founderDiamondHand = 203838;

    uint256 constant public BASE_RATE = 0.216442 ether;  //5.30
	uint256 constant public INITIAL_ISSUANCE = 13249500; 
	uint256 constant public END = 1931622407;

    uint256 public poolPercent;

    uint256 private _price;
    uint256 private _weiRaised;
   constructor() public {
        balances[msg.sender] = totalSupply_;
        
        
    }

    function totalSupply() public override view returns (uint256) {
    return totalSupply_;
    }

    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return balances[tokenOwner];
    }

    function decimalFactor() external view returns (uint256) {
        return _decimalFactor;
    }

    function transfer(address receiver, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
        
    }

    function approve(address delegate, uint256 numTokens) public override returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public override view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);

        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
    
    
    function transferToken(address owner, uint256 amount,uint256 numTokens) public payable returns(string memory,uint256) {
        balances[owner] = balances[owner].sub(numTokens);

        balances[msg.sender] = balances[msg.sender].add(numTokens);
        emit Transfer(msg.sender, owner, numTokens);
        payable(owner).transfer(amount);
        return("Token Transfer Done",numTokens);
    }   
    function _burn(address account, uint256 amount) internal returns (bool) {
        require(account != address(0), "ERC2020: burn from the zero address");
        emit Transfer(account, address(0), amount);
        return true;
    }
    function _mint(address account, uint256 amount) internal returns (bool) {
        require(account != address(0), "ERC2020: mint to the zero address");
        emit Transfer(address(0), account, amount);
        return true;
    }


 function startICO(uint endDate, uint _minPurchase, uint _maxPurchase, uint _availableTokens, uint256 _softCap, uint256 _hardCap, uint256 _poolPercent) external  {

        require(endDate > block.timestamp, 'Pre-Sale: duration should be > 0');
        require(_availableTokens > 0 && _availableTokens <= totalSupply(), 'Pre-Sale: availableTokens should be > 0 and <= totalSupply');
        require(_poolPercent >= 0 && _poolPercent <totalSupply(), 'Pre-Sale: poolPercent should be >= 0 and < totalSupply');
        require(_minPurchase > 0, 'Pre-Sale: _minPurchase should > 0');

        endICO = endDate;
        poolPercent = _poolPercent;
        availableTokensICO = _availableTokens.div(_availableTokens.mul(_poolPercent).div(10**2));

        minPurchase = _minPurchase;
        maxPurchase = _maxPurchase;

        softCap = _softCap;
        hardCap = _hardCap;
    }

}
contract Staking is Context, Ownable, GVOToken {
    using SafeMath for uint256;

    address[] internal stakeholders;

    GVOToken public GVO;

    struct stakeHolder {
        uint256 amount;
        uint256 stakeTime;
    }
 

    uint256 public tokenPrice = 10000000000000; //1.0;

    uint256 public APY = 2500; // 25.0%

    mapping(address => stakeHolder) public stakes;

    mapping(address => uint256) internal rewards;

    uint256 public totalTokenStaked;

    constructor(GVOToken _address) public payable {
        GVO = _address;
    }

    //create stake
    function createStake(uint256 _numberOfTokens) public payable returns (bool)
    {
        require(
            msg.value == _numberOfTokens.mul(tokenPrice),
            "Price value mismatch"
        );
        require(
            GVO.totalSupply() >=(_numberOfTokens.mul(GVO.decimalFactor().add(totalTokenStaked))),
            "addition error"
        );
        require(
            _mint(_msgSender(), _numberOfTokens.mul(GVO.decimalFactor())),
            "mint error"
        );
        stakeholders.push(_msgSender());
        totalTokenStaked = totalTokenStaked.add(
        _numberOfTokens.mul(GVO.decimalFactor())
        );
        uint256 previousStaked = stakes[_msgSender()].amount;
        uint256 finalStaked = previousStaked.add(msg.value);
        stakes[_msgSender()] = stakeHolder(finalStaked, block.timestamp);
        return true;
    }

    //remove stake
    function removeStake(uint256 _numberOfTokens)
        public
        payable
        returns (bool)
    {
        require(
            (stakes[_msgSender()].stakeTime + 7 seconds) <= block.timestamp,
            "You have to stake for minimum 7 seconds."
        );

        require(
            stakes[_msgSender()].amount == _numberOfTokens.mul(tokenPrice),
            "You have to unstake all your tokens"
        );
        uint256 stake = stakes[_msgSender()].amount;

        //calculate reward
        uint256 rew = calculateReward(_msgSender());
        uint256 totalAmount = stake.add(rew);
        _msgSender().transfer(totalAmount);
        totalTokenStaked = totalTokenStaked.sub(
            _numberOfTokens.mul(GVO.decimalFactor())
        );
        stakes[_msgSender()] = stakeHolder(0, 0);
        removeStakeholder(_msgSender());
        _burn(_msgSender(), _numberOfTokens.mul(GVO.decimalFactor()));
        return true;
    }

    //get stake
    function stakeOf(address _stakeholder) public view returns (uint256) {
        return stakes[_stakeholder].amount;
    }

    function isStakeholder(address _address)
        public
        view
        returns (bool, uint256)
    {
        for (uint256 s = 0; s < stakeholders.length; s += 1) {
            if (_address == stakeholders[s]) return (true, s);
        }
        return (false, 0);
    }

    function removeStakeholder(address _stakeholder) internal {
        (bool _isStakeholder, uint256 s) = isStakeholder(_stakeholder);
        if (_isStakeholder) {
            stakeholders[s] = stakeholders[stakeholders.length - 1];
            stakeholders.pop();
        }
    }

    //reward of
    function rewardOf(address _stakeholder) public view returns (uint256) {
        return rewards[_stakeholder];
    }

    // calculate stake
    function calculateReward(address _stakeholder)
        public
        view
        returns (uint256)
    {
        uint256 reward;
        if ((stakes[_stakeholder].stakeTime + 7 seconds) <= block.timestamp) {
            reward = ((stakes[_stakeholder].amount).mul(APY)).div(
                uint256(10000)
            );
        } else {
            reward = 0;
        }
        return reward;
    }

    function viewReward(address _stakeholder) public view returns (uint256) {
        uint256 reward;

        reward = ((stakes[_stakeholder].amount).mul(APY)).div(uint256(10000));
        return reward;
    }

    // distribute rewards
    function distributeRewards() public onlyOwner {
        for (uint256 s = 0; s < stakeholders.length; s += 1) {
            address stakeholder = stakeholders[s];
            uint256 reward = calculateReward(stakeholder);
            rewards[stakeholder] = rewards[stakeholder].add(reward);
        }
    }

    //   withdraw rewards
    function withdrawReward() public {
        uint256 reward = calculateReward(_msgSender());
        rewards[msg.sender] = 0;
        _msgSender().transfer(reward);
    }
}