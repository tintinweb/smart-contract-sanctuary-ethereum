pragma solidity ^0.5.0;

import "./ERC20.sol";
import "./ERC20Detailed.sol";
import "./Pausable.sol";
/**
 * @title ERC721MetadataMintable
 * @dev ERC721 minting logic with metadata.
 */
contract ERC20Full is ERC20, ERC20Detailed, PauserRole  {
    
    constructor (string memory name, string memory symbol, uint8 decimals,
                uint256 totalSupply, uint256 totalICO1, uint256 totalICO2, uint256 totalICO3,
                uint256 priceICO1, uint256 priceICO2, uint256 priceICO3,
                address payable wallet) 
    public ERC20Detailed(name, symbol, decimals) ERC20(totalSupply, totalICO1, totalICO2, totalICO3, priceICO1, priceICO2, priceICO3, wallet) {
        // solhint-disable-previous-line no-empty-blocks
    }
}