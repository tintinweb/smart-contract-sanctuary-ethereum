pragma solidity >=0.4.22 <0.8.0;

import "./Context.sol";
import "./ERC20.sol";
import "./ERC20Detailed.sol";

/**
 * @title SimpleToken
 * @dev Very simple ERC20 Token example, where all tokens are pre-assigned to the creator.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `ERC20` functions.
 */
contract GLFDtoken is Context, ERC20, ERC20Detailed {
    
    uint256 public totalSupplyofToken;
    address private owner;
    
    mapping(address => lockToken[]) public locked;
    
    struct lockToken {
        uint256 amount;
        uint256 validity;
    }
    
    modifier onlyOwner () {
        require(_msgSender() == owner);
        _;
    }
    
    event OwnershipTransferred(address indexed preOwner, address indexed nextOwner);
    
    /**
     * @dev Constructor that gives _msgSender() all of existing tokens.
     */
    constructor () public ERC20Detailed("GLFD", "glfd", 18) ERC20(_msgSender()) {
        
        owner = _msgSender();
        totalSupplyofToken = 2880000000 * (10 ** uint256(decimals()));
        _mint(_msgSender(), totalSupplyofToken);
    }
    
    function mint(uint256 _amount) public onlyOwner {
        uint256 mint_amount = _amount * (10 ** uint256(decimals()));
        _mint(_msgSender(), mint_amount);
    } 
    
    function burn(uint256 _amount) public onlyOwner {
        uint256 burn_amount = _amount * (10 ** uint256(decimals()));
        _burn(_msgSender(), burn_amount);
    }
    
    function transferLock(address _recipient, uint256 _amount, uint256 _time) onlyOwner public returns (bool){
        _transferToken(_recipient, _amount);
        
        lock(_recipient, _amount, _time);    
        return true;
    } 
    
    function transfer(address _recipient, uint256 _amount) public returns (bool) {
        
        uint256 transferableToken = transferableBalanceOf(_msgSender());
        
        require(transferableToken.sub(_amount) >= 0);
        
        _transferToken(_recipient, _amount);
        return true;
    }
    
    /**
     * @dev Locks a specified amount of tokens against an address.
     */
    
    function lock(address _user, uint256 _amount, uint256 _time) onlyOwner internal returns (bool){
        
        uint256 validUntil = block.timestamp.add(_time);
        
        require(_amount <= transferableBalanceOf(_user));      
        
        locked[_user].push(lockToken(_amount, validUntil));    
        
        return true;
    }
    
    /**
     * @dev Returns tokens locked for a specified address for a
     *      specified order count at a current time
     *
     * @param _user The address whose tokens are locked
     * @param _lockCount The array index of locked amount
     */
    function tokensLocked(address _user, uint256 _lockCount) public view returns (uint256 amount){
        if (locked[_user][_lockCount].validity > now)
            amount = locked[_user][_lockCount].amount;
    }
    
    function transferableBalanceOf(address _user) public view returns (uint256){
        uint256 totalBalance;
        uint256 lockedAmount;
        uint256 amount;
        
        for (uint256 i=0; i<locked[_user].length; i++) {
            lockedAmount += tokensLocked(_user, i);
        }
        
        totalBalance = balanceOf(_user); 
        amount = totalBalance.sub(lockedAmount);
        return amount;
    }
    
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != owner);
        require(_newOwner != address(0));
        address preOwner = owner;
        owner = _newOwner;
        emit OwnershipTransferred(preOwner, _newOwner);
    }

    function getOwner() public view returns(address){
        return owner;
    }
}