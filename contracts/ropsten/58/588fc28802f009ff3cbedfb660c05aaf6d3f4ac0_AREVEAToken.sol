// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

// import "./IERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ERC20.sol";
/// @title AREVEA token is a special contract for crypto related services 
/// @author Tapas Mahanandia
/// @notice It does crypto related mint, burn, transfer services 
/// @dev its a special token
contract AREVEAToken is ERC20,Ownable{
    
    using SafeMath for uint256;
    
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;
    
    address private _owner;
    uint256 private _totalSupply;
    uint8 public constant _decimals = 18;
    uint256 public constant _initialSupply = 1000000 * (10 ** uint256(_decimals));
    uint256 private _maximusupply = 1000000000000 * (10 ** uint256(_decimals));
    
    /**
       @dev ERC20 token name and symbol 
       @dev minted with initial supply is total initial supply in circulation 
       @dev balance to check owners initial and total supply balance 
       @dev constructer sender can mint initial supply 
     */

    
    constructor() ERC20("AREVEA","AVA") {
         mint(msg.sender,_initialSupply);
        _balances[msg.sender]=_initialSupply;
        _totalSupply ==  _initialSupply +_totalSupply * (10 ** uint256(_decimals));
        _balances[msg.sender]=_totalSupply;
        
   }
    
   /**
     * @dev See {ERC20-totalSupply,maximumsuppy initial supply returns views only means we can view output}.
     */
    function maximusupply() public view virtual returns (uint256) {
    return _maximusupply;
    }
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    function initialSupply() public view virtual returns (uint256) {
        return _initialSupply;
    }

     /**
       @dev Mint function to mint token , only owner can mint 
       @dev total supply is the circulating amount  cannot go beyond maximum supply in circulation
       @dev in mint funcion when amount is minted is added to the total supply and with the owner balance 
     */
     
    function mint(address account, uint256 amount) public  onlyOwner  {
        require(account != address(0), "ERC20: mint to the zero address");
        require(totalSupply().add(amount) <= _maximusupply,"Maximum supply reached");
        _mint(account, amount);
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
        _afterTokenTransfer(address(0), account, amount);
    }
    /**
       @dev Burn function to reduce excess supply in circulation 
       
     */
       function burnFrom(address account, uint256 amount) public  onlyOwner  {
        require(account != address(0), "ERC20: mint to the zero address");
        _burn(account, amount);
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply -= amount;
        _balances[account] -= amount;
        emit Transfer(address(0), account, amount);
        _afterTokenTransfer(address(0), account, amount);
     }


}