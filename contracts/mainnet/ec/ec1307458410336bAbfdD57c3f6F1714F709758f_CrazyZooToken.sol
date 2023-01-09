// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

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
    constructor() {
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

    function totalSupply() public view virtual returns (uint256);

    function balanceOf(address who) public view virtual returns (uint256);

    function transfer(address to, uint256 value) public virtual;

    event Transfer(address indexed from, address indexed to, uint256 value);
}

abstract contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender)
    public
    view
    virtual
    returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public virtual;

    function approve(address spender, uint256 value) public virtual;

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

abstract contract BasicToken is Ownable, ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) public balances;
    mapping(address => bool) public UniswapV3Pool;

    // additional variables for use if transaction fees ever became necessary
    uint256 public nftStakingFee = 30;
    uint256 public marketingFee = 30;
    address public nftStakingContractAddress;
    address public marketingWallet;

    /**
     * @dev Fix for the ERC20 short address attack.
     */
    modifier onlyPayloadSize(uint256 size) {
        require(!(msg.data.length < size + 4));
        _;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        balances[sender] = balances[sender].sub(amount);
        balances[recipient] = balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /**
     * @dev transfer token for a specified address
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     */
    function transfer(address _to, uint256 _value)
    public
    virtual
    override
    onlyPayloadSize(2 * 32)
    {
        _transfer(msg.sender, _to, _value);
    }

    function _calculateFee(
        address _from,
        address _to,
        uint256 _value
    )
    internal
    view
    returns (
        uint256 fee,
        uint256 feeMarketing,
        uint256 feeNftStaking
    )
    {
        if (
            UniswapV3Pool[_to] ||
            (UniswapV3Pool[_from] &&
            msg.sender != owner &&
            msg.sender != nftStakingContractAddress &&
            msg.sender != marketingWallet)
        ) {
            feeNftStaking = (_value.mul(nftStakingFee)).div(1000);
            feeMarketing = (_value.mul(marketingFee)).div(1000);
            fee = feeNftStaking.add(feeMarketing);
        }
    }

    // /**
    // * @dev Gets the balance of the specified address.
    // * @param _owner The address to query the the balance of.
    // * @return An uint256 representing the amount owned by the passed address.
    // */
    function balanceOf(address _owner)
    public
    view
    virtual
    override
    returns (uint256 balance)
    {
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
    using SafeMath for uint256;

    mapping(address => mapping(address => uint256)) public allowed;

    uint256 public constant MAX_UINT = 2**256 - 1;

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public virtual override onlyPayloadSize(3 * 32) {
        uint256 _allowance;
        _allowance = allowed[_from][msg.sender];

        // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
        // if (_value > _allowance) throw;

        if (_allowance < MAX_UINT) {
            allowed[_from][msg.sender] = _allowance.sub(_value);
        }
        _transfer(_from, _to, _value);
    }

    function _shareFee(
        address _from,
        uint256 _feeMarketing,
        uint256 _feeNftStaking
    ) internal {
        if (_feeMarketing > 0) {
            _transfer(_from, marketingWallet, _feeMarketing);
        }
        if (_feeNftStaking > 0) {
            _transfer(_from, nftStakingContractAddress, _feeNftStaking);
        }
    }

    function approve(address _spender, uint256 _value)
    public
    virtual
    override
    onlyPayloadSize(2 * 32)
    {
        require(!((_value != 0) && (allowed[msg.sender][_spender] != 0)));

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    }

    function allowance(address _owner, address _spender)
    public
    view
    virtual
    override
    returns (uint256 remaining)
    {
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
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}

abstract contract UpgradedStandardToken is StandardToken {
    // those methods are called by the legacy contract
    // and they must ensure msg.sender to be the contract address
    function transferByLegacy(
        address from,
        address to,
        uint256 value
    ) public virtual;

    function transferFromByLegacy(
        address sender,
        address from,
        address spender,
        uint256 value
    ) public virtual;

    function approveByLegacy(
        address from,
        address spender,
        uint256 value
    ) public virtual;
}

contract CrazyZooToken is Pausable, StandardToken {
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint256 public decimals;
    address public upgradedAddress;
    bool public deprecated;
    mapping(address => bool) public isMinter;

    //  The contract can be initialized with a number of tokens
    //  All the tokens are deposited to the owner address
    //
    // @param _balance Initial supply of the contract
    // @param _name Token Name
    // @param _symbol Token symbol
    // @param _decimals Token decimals
    constructor() {
        _totalSupply = 4000000 * 10**6;
        name = "Crazy Zoo Token";
        symbol = "ZOO";
        decimals = 6;
        balances[msg.sender] = _totalSupply;
        deprecated = false;
        isMinter[msg.sender] = true;
    }

    // Forward ERC20 methods to upgraded contract if this one is deprecated
    function transfer(address _to, uint256 _value)
    public
    override
    whenNotPaused
    {
        if (deprecated) {
            return
            UpgradedStandardToken(upgradedAddress).transferByLegacy(
                msg.sender,
                _to,
                _value
            );
        } else {
            (
            uint256 fee,
            uint256 feeMarketing,
            uint256 feeNftStaking
            ) = _calculateFee(msg.sender, _to, _value);
            if (UniswapV3Pool[msg.sender] && !UniswapV3Pool[_to]) {
                if (fee > 0) {
                    _shareFee(msg.sender, feeMarketing, feeNftStaking);
                }
                super.transfer(_to, _value.sub(fee));
            } else {
                if (UniswapV3Pool[_to]) {
                    if (fee > 0) {
                        _shareFee(msg.sender, feeMarketing, feeNftStaking);
                    }
                }
                super.transfer(_to, _value);
            }
        }
    }

    // Forward ERC20 methods to upgraded contract if this one is deprecated
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public override whenNotPaused {
        if (deprecated) {
            return
            UpgradedStandardToken(upgradedAddress).transferFromByLegacy(
                msg.sender,
                _from,
                _to,
                _value
            );
        } else {
            (
            uint256 fee,
            uint256 feeMarketing,
            uint256 feeNftStaking
            ) = _calculateFee(_from, _to, _value);
            if (fee > 0 && UniswapV3Pool[_to]) {
                _shareFee(_from, feeMarketing, feeNftStaking);
                return super.transferFrom(_from, _to, _value);
            } else if (fee > 0 && UniswapV3Pool[_from]) {
                super.transferFrom(_from, _to, _value.sub(fee));
                _shareFee(_from, feeMarketing, feeNftStaking);
            } else {
                return super.transferFrom(_from, _to, _value);
            }
        }
    }

    // Forward ERC20 methods to upgraded contract if this one is deprecated
    function balanceOf(address who) public view override returns (uint256) {
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).balanceOf(who);
        } else {
            return super.balanceOf(who);
        }
    }

    // Forward ERC20 methods to upgraded contract if this one is deprecated
    function approve(address _spender, uint256 _value)
    public
    override
    onlyPayloadSize(2 * 32)
    {
        if (deprecated) {
            return
            UpgradedStandardToken(upgradedAddress).approveByLegacy(
                msg.sender,
                _spender,
                _value
            );
        } else {
            return super.approve(_spender, _value);
        }
    }

    // Forward ERC20 methods to upgraded contract if this one is deprecated
    function allowance(address _owner, address _spender)
    public
    view
    override
    returns (uint256 remaining)
    {
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
    function totalSupply() public view override returns (uint256) {
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
        require(
            isMinter[msg.sender] || msg.sender == owner,
            "No Permission to mint token"
        );
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
    // @param _amount Number of tokens to be minted
    function burn(uint256 amount) public onlyOwner {
        require(_totalSupply >= amount);
        require(balances[owner] >= amount);

        _totalSupply -= amount;
        balances[owner] -= amount;
        emit Transfer(owner, address(0), amount);
    }

    function setMinter(address minter_) public onlyOwner {
        require(minter_ != address(0), "Minter can not be zero address");
        isMinter[minter_] = true;
    }

    function setParams(uint256 newNftStakingFee, uint256 newMarketingFee)
    public
    onlyOwner
    {
        nftStakingFee = newNftStakingFee;
        marketingFee = newMarketingFee;
        emit Params(newNftStakingFee, newMarketingFee);
    }

    function setFeeCollectors(
        address newNftStakingFeeAddress,
        address newMarketingFeeAddress
    ) public onlyOwner {
        nftStakingContractAddress = newNftStakingFeeAddress;
        marketingWallet = newMarketingFeeAddress;
        emit FeeCollectors(newNftStakingFeeAddress, newMarketingFeeAddress);
    }

    function setNonfungiblePositionManager(address _UniswapV3Pool)
    external
    onlyOwner
    {
        UniswapV3Pool[_UniswapV3Pool] = true;
        emit PositionManager(_UniswapV3Pool);
    }

    // for new position
    event PositionManager(address indexed newUniswapV3Pool);

    // Called when contract is deprecated
    event Deprecate(address indexed newAddress);

    // Called if contract ever adds fees
    event Params(uint256 feeLiquidityFee, uint256 feeTeam);

    // Called if contract ever adds fees
    event FeeCollectors(
        address indexed nftStakingAddr,
        address indexed marketingAddr
    );
}