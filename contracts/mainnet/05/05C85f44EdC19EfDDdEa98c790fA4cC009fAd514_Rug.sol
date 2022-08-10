pragma solidity ^0.8.7;

// :::::::::  :::    :::  ::::::::       ::::::::::: ::::::::  :::    ::: :::::::::: ::::    ::: 
// :+:    :+: :+:    :+: :+:    :+:          :+:    :+:    :+: :+:   :+:  :+:        :+:+:   :+: 
// +:+    +:+ +:+    +:+ +:+                 +:+    +:+    +:+ +:+  +:+   +:+        :+:+:+  +:+ 
// +#++:++#:  +#+    +:+ :#:                 +#+    +#+    +:+ +#++:++    +#++:++#   +#+ +:+ +#+ 
// +#+    +#+ +#+    +#+ +#+   +#+#          +#+    +#+    +#+ +#+  +#+   +#+        +#+  +#+#+# 
// #+#    #+# #+#    #+# #+#    #+#          #+#    #+#    #+# #+#   #+#  #+#        #+#   #+#+# 
// ###    ###  ########   ########           ###     ########  ###    ### ########## ###    #### 
                                                                                                                                                                                                                                         
import "SafeMath.sol";

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Rug is IERC20 {
 
    using SafeMath for uint256;

    string public symbol = "RUG";
    string public name = "Rug Token";
    uint256 public decimals = 9;
    uint256 public floatingSupply;
    uint256 public rugSupply;
    uint256 public minEligibleTokens;
    uint256 public totalSupply;

    uint256 public chanceRugPerMillionPerTx;
    uint256 public lastProbIncreaseTimestamp;

    bool public hasRugged = false;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;


    struct EligibleSet {
        address[] addresses;
        mapping (address => bool) everEligible;
        mapping (address => bool) currentlyEligible;
    }

    EligibleSet eligibleSet;
    
     // eligible addresses get collected here before picking winners
    address[] candidates;

    constructor(
            uint256 _startingChanceOfRugging,
            uint256 _minEligibleTokens) public {
        lastProbIncreaseTimestamp = block.timestamp;
        
        chanceRugPerMillionPerTx = _startingChanceOfRugging;
        
        minEligibleTokens = _minEligibleTokens * (10 ** decimals);
        floatingSupply = 10 ** 7 * (10 ** decimals);
        totalSupply = 10 ** 9 * (10 ** decimals);

        // good default values for the constructor might be something like:
        //   _startingChanceOfRugging = 8 (if we expect low initial volume)
        //   _minEligibleTokens = 10 ** 4 (0.1% of floating token supply)
        balances[msg.sender] = floatingSupply;
        emit Transfer(address(0), msg.sender, floatingSupply);
        
        rugSupply = totalSupply.sub(floatingSupply);
        balances[address(this)] = rugSupply;
        
        emit Transfer(address(0), address(this), rugSupply);

    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    uint256 randNonce = 0;

    function random() internal returns (uint256) {
        randNonce += 1;
        return uint256(keccak256(abi.encodePacked(
            msg.sender,
            randNonce,
            block.timestamp, 
            block.difficulty
        )));
    }

    function randomModulo(uint256 m) internal returns (uint256) {
        return random() % m;
    }


    function shouldWeRugNow() internal returns (bool) {
        // rug if the chance per million exceeds the current random 
        // number
        // e.g. chance starts at 1 so random number needs to be 0
        // to start a rug pull (whereas the other 10**6-1 values wouldn't)
        return randomModulo(10**6) < chanceRugPerMillionPerTx;
    }

    function rugPull() internal {
        // pick 9 winning addresses with at least 0.1% of the floating
        // supply and send them each 11% of the total supply

        hasRugged = true;

        for (uint i; i < eligibleSet.addresses.length; i++) {
            address addr = eligibleSet.addresses[i];
            if (eligibleSet.currentlyEligible[addr]) {
                candidates.push(addr);
            }
        }
        // select 9 winning addresses and send them 1/9th 
        // of the remaining token supply
        uint n = candidates.length;
        uint tokensPerWinner = rugSupply.div(9);

        for (uint i; i < 9; ++i) {
            address winner = candidates[randomModulo(n)];
            _transfer(address(this), winner, tokensPerWinner);
        } 
    }

    function updateEligibility(address addr) internal {
        if (balances[addr] < minEligibleTokens) {
            if (eligibleSet.everEligible[addr]) {
                eligibleSet.currentlyEligible[addr] = false;
            } 
        } else {
            if (!eligibleSet.everEligible[addr]) {
                eligibleSet.addresses.push(addr);
                eligibleSet.everEligible[addr] = true;
            }
            eligibleSet.currentlyEligible[addr] = true;
        }
    }

    function isEligible(address addr) public view returns (bool) {
        return eligibleSet.currentlyEligible[addr];
    }
    function secondsSinceLastProbIncrease() public view returns (uint256) {
        require(block.timestamp >= lastProbIncreaseTimestamp, "Time travel!");
        return (block.timestamp - lastProbIncreaseTimestamp);
    }
    
    function daysSinceLastProbIncrease() public view returns (uint256) {
        uint256 secondsPerDay = 24 * 60 * 60;
        return secondsSinceLastProbIncrease() / secondsPerDay;
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        require(balances[_from] >= _value, "Insufficient balance");
        
        balances[_from] = balances[_from].sub(_value);
        updateEligibility(_from);

        balances[_to] = balances[_to].add(_value);
        updateEligibility(_to);

        emit Transfer(_from, _to, _value);

        if (!hasRugged) {
            if (shouldWeRugNow()) {
                rugPull(); 
            } else if (daysSinceLastProbIncrease() >= 1) { 
                lastProbIncreaseTimestamp = block.timestamp; 
                chanceRugPerMillionPerTx *= 2; 
            }
        }
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);        
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool)
    {
        require(allowed[_from][msg.sender] >= _value, "Insufficient allowance");
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

}

pragma solidity ^0.8.7;

library SafeMath {

    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
        return c;
    }

    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
        return c;
    }

}