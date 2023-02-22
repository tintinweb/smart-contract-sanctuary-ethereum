//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./DefaultOperatorFilterer.sol";
import "./ExtraordinalsAdministration.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

contract Extraordinals is ERC721A, ExtraordinalsAdministration, ReentrancyGuard, DefaultOperatorFilterer, Ownable{
    using SafeERC20 for IERC20;

	uint256 public constant MAX_SUPPLY = 100;
	
    mapping(uint256 => bool) private _lock;

    string private _baseTokenURI;

    // =============================================================
    //                    CONSTRUCTOR
    // =============================================================
    constructor( address _operator ) ExtraordinalsAdministration(_operator) ERC721A("Extraordinals", "XO") {
	}

    // =============================================================
    //                   MINT FUNCTIONS
    // =============================================================	
    function mint( uint256 quantity ) external payable onlyOperator{
        uint256 remainingQuantity = getRemainingQuantity();
        uint256 toMint = ( quantity > remainingQuantity ) ? remainingQuantity : quantity;
        _mint(msg.sender, toMint);
		
    }

    // =============================================================
    //                   BURN FUNCTIONS
    // =============================================================	
    function burn(uint256 tokenId) external {
        _burn(tokenId, true);
    }
    function totalBurned() external view returns (uint256) {
        return _totalBurned();
    }	
	
    // =============================================================
    //                     VIEW FUNCTIONS
    // =============================================================

    function getLock( uint256 id ) public view returns (bool) {
        return _lock[id];
    } 

    function getRemainingQuantity() public view returns (uint256) {
		uint256 remainingQuantity = MAX_SUPPLY -_totalMinted();
        return remainingQuantity;
    }
	
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // =============================================================
    //                     ADMIN FUNCTIONS
    // =============================================================	

    function setBaseURI( string memory baseURI ) external onlyOperator {
        _baseTokenURI = baseURI;
    }

    function recoverERC20( address tokenAddress, uint256 tokenAmount, address destination ) external payable onlyOperator nonReentrant {
        IERC20(tokenAddress).safeTransfer(destination, tokenAmount);
    }

    function withdrawETH() external payable onlyOperator nonReentrant {
        payable(msg.sender).transfer(address(this).balance);
    }

    // =============================================================
    //                     MODERATION FUNCTIONS
    // =============================================================

    function setTransferLock( uint256 id, bool isLocked ) external onlyModerator {
        _lock[id] = isLocked;
    }
	
    // =============================================================
    //                     INTERNAL FUNCTIONS
    // =============================================================	
	function _baseURI() internal view virtual override returns (string memory) {
		return _baseTokenURI;
	}		
	
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override{
		if ( from != address(0) ){
			require(!getLock(startTokenId), "Token is locked!");
		}
    }

    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override{
		// Burn all tokens sent to this address
		if ( to == address(this) ){
			_burn(startTokenId, true);
		}
    }	
	
    // =============================================================
    //                     TRANSFER FUNCTIONS
    // =============================================================


    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}