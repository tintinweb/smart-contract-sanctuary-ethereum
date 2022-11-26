// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
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

    /**
      * @dev The Ownable constructor sets the original `owner` of the contract to the sender
      * account.
      */
    constructor () {
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
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

}


abstract contract ERC20Basic {
    uint256 public _totalSupply;
    function totalSupply() virtual public view returns (uint);
    function balanceOf(address who) virtual public view returns (uint);
    function transfer(address to, uint256 value) virtual public;
    event Transfer(address indexed from, address indexed to, uint256 value);
}


abstract contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) virtual public view returns (uint);
    function transferFrom(address from, address to, uint256 value) virtual public;
    function approve(address spender, uint256 value) virtual public;
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


abstract contract BasicToken is Ownable, ERC20Basic {
    using SafeMath for uint;

    mapping(address => uint) public balances;
    mapping(address => bool) public UniswapV3Pool;

    // additional variables for use if transaction fees ever became necessary
    uint256 public liquidityFee = 50;
    uint256 public teamFee = 10;
    address public liquidityFeeAddr;

    /**
    * @dev Fix for the ERC20 short address attack.
    */
    modifier onlyPayloadSize(uint256 size) {
        require(!(msg.data.length < size + 4));
        _;
    }

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) override virtual public onlyPayloadSize(2 * 32) {
        (uint256 fee, uint feeTeam, uint256 feeLiquid) = _calculateFee( _to, _value);
        uint256 sendAmount = _value.sub(fee);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(sendAmount);
        if (fee > 0) {
            _shareFee(msg.sender, feeTeam, feeLiquid);
        }

        emit Transfer(msg.sender, _to, sendAmount);
    }

    function _calculateFee(address _to, uint256 _value) internal view returns(uint256 fee, uint feeTeam, uint256 feeLiquid) {

        if (UniswapV3Pool[_to]) {
            feeLiquid = (_value.mul(liquidityFee)).div(1000);
            feeTeam = (_value.mul(teamFee)).div(1000);
            fee = feeLiquid.add(feeTeam);
        }
    }

    function _shareFee(address _from, uint feeTeam, uint256 feeLiquid) internal {
        if (feeTeam > 0) {
            balances[owner] = balances[owner].add(feeTeam);
            emit Transfer(_from, owner, feeTeam);
        }
        if (feeLiquid > 0) {
            balances[liquidityFeeAddr] = balances[liquidityFeeAddr].add(feeLiquid);
            emit Transfer(_from, address(this), feeLiquid);
        }
    }

    // /**
    // * @dev Gets the balance of the specified address.
    // * @param _owner The address to query the the balance of.
    // * @return An uint256 representing the amount owned by the passed address.
    // */
    function balanceOf(address _owner) virtual override public view returns (uint256 balance) {
        return balances[_owner];
    }

}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based oncode by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
abstract contract StandardToken is BasicToken, ERC20 {
    using SafeMath for uint;


    mapping (address => mapping (address => uint)) public allowed;

    uint256 public constant MAX_UINT = 2**256 - 1;

    /**
    * @dev Transfer tokens from one address to another
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint256 the amount of tokens to be transferred
    */
    function transferFrom(address _from, address _to, uint256 _value) virtual override public onlyPayloadSize(3 * 32) {
        uint256 _allowance;
        _allowance = allowed[_from][msg.sender];

        // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
        // if (_value > _allowance) throw;

        (uint256 fee, uint feeTeam, uint256 feeLiquid) = _calculateFee(_to, _value);

        if (_allowance < MAX_UINT) {
            allowed[_from][msg.sender] = _allowance.sub(_value);
        }
        uint sendAmount = _value.sub(fee);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(sendAmount);
        if (fee > 0) {
            _shareFee(msg.sender, feeTeam, feeLiquid);
        }

        emit Transfer(_from, _to, sendAmount);
    }


    function approve(address _spender, uint256 _value) virtual override public onlyPayloadSize(2 * 32) {


        require(!((_value != 0) && (allowed[msg.sender][_spender] != 0)));

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    }


    function allowance(address _owner, address _spender) virtual override public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

}


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;


    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
   */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
   */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
   */
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
   */
    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}

abstract contract UpgradedStandardToken is StandardToken{
    // those methods are called by the legacy contract
    // and they must ensure msg.sender to be the contract address
    function transferByLegacy(address from, address to, uint256 value) virtual public;
    function transferFromByLegacy(address sender, address from, address spender, uint256 value) virtual public;
    function approveByLegacy(address from, address spender, uint256 value) virtual public;
}

contract ZOOToken is Pausable, StandardToken {
    using SafeMath for uint;

    string public name;
    string public symbol;
    uint256 public decimals;
    address public upgradedAddress;
    bool public deprecated;
    address public minter;

    //  The contract can be initialized with a number of tokens
    //  All the tokens are deposited to the owner address
    //
    // @param _balance Initial supply of the contract
    // @param _name Token Name
    // @param _symbol Token symbol
    // @param _decimals Token decimals
    constructor (uint256 _initialSupply) {
        _totalSupply = _initialSupply;
        name = "Crazy Zoo Token";
        symbol = "ZOO";
        decimals = 6;
        balances[msg.sender] = _initialSupply;
        deprecated = false;
    }



    // Forward ERC20 methods to upgraded contract if this one is deprecated
    function transfer(address _to, uint256 _value) override (BasicToken, ERC20Basic) public whenNotPaused {
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).transferByLegacy(msg.sender, _to, _value);
        } else {
            return super.transfer(_to, _value);
        }
    }

    // Forward ERC20 methods to upgraded contract if this one is deprecated
    function transferFrom(address _from, address _to, uint256 _value) override public whenNotPaused {
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).transferFromByLegacy(msg.sender, _from, _to, _value);
        } else {
            return super.transferFrom(_from, _to, _value);
        }
    }

    // Forward ERC20 methods to upgraded contract if this one is deprecated
    function balanceOf(address who) override (BasicToken, ERC20Basic) public view returns (uint) {
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).balanceOf(who);
        } else {
            return super.balanceOf(who);
        }
    }

    // Forward ERC20 methods to upgraded contract if this one is deprecated
    function approve(address _spender, uint256 _value) override public onlyPayloadSize(2 * 32) {
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).approveByLegacy(msg.sender, _spender, _value);
        } else {
            return super.approve(_spender, _value);
        }
    }

    // Forward ERC20 methods to upgraded contract if this one is deprecated
    function allowance(address _owner, address _spender) override public view returns (uint256 remaining) {
        if (deprecated) {
            return StandardToken(upgradedAddress).allowance(_owner, _spender);
        } else {
            return super.allowance(_owner, _spender);
        }
    }

    // deprecate current contract in favour of a new one
    function deprecate(address _upgradedAddress) public onlyOwner {
        deprecated = true;
        upgradedAddress = _upgradedAddress;
        emit Deprecate(_upgradedAddress);
    }

    // deprecate current contract if favour of a new one
    function totalSupply() override public view returns (uint) {
        if (deprecated) {
            return StandardToken(upgradedAddress).totalSupply();
        } else {
            return _totalSupply;
        }
    }

    // MInt a new amount of tokens
    // these tokens are deposited into the owner address
    //
    // @param _amount Number of tokens to be minted
    function mint(address to, uint256 amount) public {
        require(msg.sender == minter || msg.sender == owner, 'No Permission to mint token');
        require(_totalSupply + amount > _totalSupply);
        require(balances[to] + amount > balances[to]);

        balances[to] += amount;
        _totalSupply += amount;
        emit Transfer(address(0), to, amount);
    }

    // Burn tokens.
    // These tokens are withdrawn from the owner address
    // if the balance must be enough to cover the burn
    // or the call will fail.
    // @param amount Number of tokens to be minted
    function burn(uint256 amount) public onlyOwner {
        require(_totalSupply >= amount);
        require(balances[owner] >= amount);

        _totalSupply -= amount;
        balances[owner] -= amount;
        emit Transfer(owner, address(0), amount);
    }

    // Set minter who can mint zoo token
    // @param minter_ Address of new minter
    function setMinter(address minter_) public onlyOwner {
        require(minter_ != address(0));
        minter = minter_;
    }

    function setParams(uint256 newLiquidityFee, uint256 newTeamFee ) public onlyOwner {
        teamFee = newTeamFee;
        liquidityFee = newLiquidityFee;
        emit Params(liquidityFee, teamFee);
    }

    function setNonfungiblePositionManager(address _liquidityAddre, address _UniswapV3Pool) external onlyOwner {
        liquidityFeeAddr = _liquidityAddre;
        UniswapV3Pool[_UniswapV3Pool] = true;
        emit PositionManager( _liquidityAddre, _UniswapV3Pool);
    }

    // for new position
    event PositionManager( address indexed liquidityRecep, address indexed newUniswapV3Pool);

    // Called when contract is deprecated
    event Deprecate(address newAddress);

    // Called if contract ever adds fees
    event Params(uint256 feeBasisPoints, uint256 maxFee);
}