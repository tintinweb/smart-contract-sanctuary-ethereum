pragma solidity ^0.5.0;

import "./ERC20.sol";
import "./ERC20Detailed.sol";
import "./ERC20Pausable.sol";
import "./ERC20Burnable.sol";

/**
 *  @title The Adappter Token contract complies with the ERC20 standard 
 *  (see https://github.com/ethereum/EIPs/issues/20).
 */
contract AdappterToken is ERC20Pausable, ERC20Detailed, ERC20Burnable {


    string constant private _name = "Adappter Token";
    string constant private _symbol = "ADP";
    uint8 constant private _decimals = 18;
    
    uint constant private TOKENS_ECO        = 4000000000e18; // 40%
    uint constant private TOKENS_SALE       = 2000000000e18; // 20%
    uint constant private TOKENS_MARKETING  = 1500000000e18; // 15%
    uint constant private TOKENS_FOUNDATION = 1000000000e18; // 10%
    uint constant private TOKENS_PARTNER    = 1000000000e18; // 10%
    uint constant private TOKENS_TEAM       =  500000000e18; // 5%
    uint constant private _initialSupply    = 10000000000e18; // Initial supply of 10 billion Adappter Tokens

    
    /**
     * @dev Constructor that gives _msgSender() all of existing tokens.
     */
    constructor () public ERC20Detailed(_name, _symbol, _decimals) {
        _mint( msg.sender, _initialSupply);
    }
}