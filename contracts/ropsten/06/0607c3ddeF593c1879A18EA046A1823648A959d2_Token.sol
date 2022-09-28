// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
// network avalanche
//token deployed to 0xEaA8Df0496B7B11229F6Ba98e0Ee24B2cb528ecC
//pre ico deployed to 0x25Ce9bA5aE6147471987B107CDA18a2cB2B4273a
//distribute deployed to 0xFC347fd6D85AcCd900D2671ce1245018dCB26b75

import './Extras/access/Ownable.sol';
contract Token is Ownable {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    uint256 decimalfactor;
    uint256 public Max_Token;
    bool mintAllowed=true;


    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    
    // address public ICO=0x03D2434Ef06Ca621aeB961F399cFEAE1A2134D7F;
    // address public Marketing=0x8005Bd2698fD7dd63B92132530D961915fbD1B4C;
    // address public founderCommunity=0x718148ff5E44254ac51a9D2D544fdd168c1a85D4;
    // address public Advisor=0x6C763a8E16266c05e796f5798C88FF1305c4878d;
    // address public Reserves=0x02E839EF8a2e3812eCcf7ad6119f48aB2560228a;
    // address public Staking=0xfE30c9B5495EfD5fC81D8969483acfE6Efe08d61;
    // address public futures=0x6203F881127C9F4f1DdE0e7de9C23c8C9289c34D;
    
    // uint256 public ICOToken=2500000000;
    // uint256 public MarketingToken=1700000000;
    // uint256 public founderCommunityToken=1000000000;
    // uint256 public AdvisorToken=500000000;
    // uint256 public ReservesToken=1500000000;
    // uint256 public StakingToken=1000000000;
    // uint256 public futuresToken=500000000;
    
    // address public PrivateICO= 0xf8e81D47203A594245E36C48e151709F0C19fBe8;
    
    // uint256 public privateICOToken=900000000;
    

    constructor (string memory SYMBOL, 
                string memory NAME,
                uint8 DECIMALS) public{
        symbol=SYMBOL;
        name=NAME;
        decimals=DECIMALS;
        decimalfactor = 10 ** uint256(decimals);
        Max_Token = 10000000000 * decimalfactor;
        // mint(ICO,ICOToken * decimalfactor);
        // mint(Marketing,MarketingToken * decimalfactor);
        // mint(founderCommunity,founderCommunityToken * decimalfactor);
        // mint(Advisor,AdvisorToken * decimalfactor);
        // mint(Reserves,ReservesToken * decimalfactor);
        // mint(Staking,StakingToken * decimalfactor);
        // mint(futures,futuresToken * decimalfactor);
    }
    
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != address(0),"zero address");
        require(balanceOf[_from] >= _value,"Not enough balance");
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        // require(_value <= allowance[_from][msg.sender], "Allowance error");
        // allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public
        returns (bool success) {
       allowance[msg.sender][_spender] = _value;
       return true;
    }
    
   function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;            
        Max_Token -= _value;
        totalSupply -=_value;                      
        emit Burn(msg.sender, _value);
        return true;
    }
    
    function mint(address _to, uint256 _value) public returns (bool success) {
        require(Max_Token>=(totalSupply+_value));
        require(mintAllowed,"Max supply reached");
        if(Max_Token==(totalSupply+_value)){
            mintAllowed=false;
        }
        //require(msg.sender == owner,"Only Owner Can Mint");
        balanceOf[_to] += _value;
        totalSupply +=_value;
        require(balanceOf[_to] >= _value);
        emit Transfer(address(0), _to, _value); 
        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../utils/context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () public {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity 0.6.12;

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

    function _msgData() internal pure virtual returns (bytes calldata) {
        return msg.data;
    }
}