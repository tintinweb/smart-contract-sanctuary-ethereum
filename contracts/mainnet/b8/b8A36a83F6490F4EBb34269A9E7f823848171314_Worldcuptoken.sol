pragma solidity ^0.4.24;

import "./Context.sol";
import "./ERC20.sol";
import "./ERC20Detailed.sol";

/**
 * @title SimpleToken
 * @dev Very simple ERC20 Token example, where all tokens are pre-assigned to the creator.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `ERC20` functions.
 */
contract Worldcuptoken is Context, ERC20, ERC20Detailed {
    
    uint256 public totalSupplyofToken;
    address private owner;
    
    modifier onlyOwner () {
        require(_msgSender() == owner);
        _;
    }

    event OwnershipTransferred(address indexed preOwner, address indexed nextOwner);
    
    /**
     * @dev Constructor that gives _msgSender() all of existing tokens.
     */
    constructor () public ERC20Detailed("worldcup", "worldcup", 18) {
        
        owner = _msgSender();
        totalSupplyofToken = 1000000000 * (10 ** uint256(decimals()));
        _mint(_msgSender(), totalSupplyofToken);
    }
    
    function burn(uint256 _amount) public onlyOwner {
        uint256 burn_amount = _amount * (10 ** uint256(decimals()));
        _burn(_msgSender(), burn_amount);
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