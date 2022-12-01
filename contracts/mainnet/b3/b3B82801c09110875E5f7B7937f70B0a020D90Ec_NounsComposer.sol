// SPDX-License-Identifier: GPL-3.0

/// @title The Nouns composer

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

import { ReentrancyGuardUpgradeable } from '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import { OwnableUpgradeable } from '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import { ERC1155HolderUpgradeable } from '@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol';

import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import { INounsToken } from '../../interfaces/INounsToken.sol';
import { ISVGRenderer } from '../../interfaces/ISVGRenderer.sol';

import { INounsComposer } from './interfaces/INounsComposer.sol';
import { IComposablePart } from '../items/interfaces/IComposablePart.sol';

contract NounsComposer is INounsComposer, ERC1155HolderUpgradeable, ReentrancyGuardUpgradeable, OwnableUpgradeable {
    // The Nouns ERC721 token contract
    INounsToken public nouns;

	// Composed Child Tokens, token_id, position1
    mapping(uint256 => mapping(uint16 => ChildToken)) public composedChildTokens;    

    // tokenId => array of child contract
    mapping(uint256 => address[]) public childContracts;

    // tokenId => (child address => array of child tokens)
    mapping(uint256 => mapping(address => uint256[])) public childTokens;

    // tokenId => (child address => contract index)
    mapping(uint256 => mapping(address => uint256)) public childContractIndex;

    // tokenId => (child address => (child token => ChildTokenState(index, balance, position1))
    mapping(uint256 => mapping(address => mapping(uint256 => ChildTokenState))) public childTokenState;
        
    /**
     * @notice Initialize the composer and base contracts, and populate configuration values.
     * @dev This function can only be called once.
     */
    function initialize(
        INounsToken _nouns
    ) external initializer {
        __ReentrancyGuard_init();
        __Ownable_init();

        nouns = _nouns;
    }

    function getChildContracts(uint256 _tokenId) external view returns (address[] memory) {
    	return childContracts[_tokenId];
    }

    function getChildTokens(uint256 _tokenId, address _childTokenAddress) external view returns (uint256[] memory) {
    	return childTokens[_tokenId][_childTokenAddress];
    }

    function getChildContractCount(uint256 _tokenId) external view returns (uint256) {
    	return childContracts[_tokenId].length;
    }
    
    function getChildTokenCount(uint256 _tokenId, address _childTokenAddress) external view returns (uint256) {
    	return childTokens[_tokenId][_childTokenAddress].length;
    }

    function getChildTokenState(uint256 _tokenId, address _childTokenAddress, uint256 _childTokenId) external view returns (ChildTokenState memory) {
    	return childTokenState[_tokenId][_childTokenAddress][_childTokenId];
    }

    function getChildTokenStateBatch(uint256 _tokenId, address[] calldata _childTokenAddresses, uint256[] calldata _childTokenIds) external view returns (ChildTokenState[] memory) {
		uint256 len = _childTokenAddresses.length;
        ChildTokenState[] memory batchTokenStates = new ChildTokenState[](len);
		
        for (uint256 i = 0; i < len;) {
            batchTokenStates[i] = childTokenState[_tokenId][_childTokenAddresses[i]][_childTokenIds[i]];

			unchecked {
            	i++;
        	}
        }

    	return batchTokenStates;
    }

    function getComposedChild(uint256 _tokenId, uint16 _position1) external view returns (ChildToken memory) {
    	return composedChildTokens[_tokenId][_position1];
    }

    function getComposedChildBatch(uint256 _tokenId, uint16 _position1Start, uint16 _position1End) external view returns (ChildToken[] memory) {
    	require(_position1End > _position1Start, "NounsComposer: invalid position range");
    	
    	uint16 len = _position1End - _position1Start + 1;
        ChildToken[] memory batchTokens = new ChildToken[](len);

        for (uint16 i = 0; i < len;) {
            batchTokens[i] = composedChildTokens[_tokenId][_position1Start + i];

			unchecked {
            	i++;
        	}
        }

        return batchTokens;
    }

    function childExists(uint256 _tokenId, address _childTokenAddress, uint256 _childTokenId) external view returns (bool) {
    	return _childExists(_tokenId, _childTokenAddress, _childTokenId);
    }

    /*
     * Receive and Transfer Child Tokens
     * 
     */

    function receiveChild(uint256 _tokenId, TokenTransferParams calldata _child) external nonReentrant {    	
		require(_isApprovedOrOwner(_msgSender(), _tokenId), "NounsComposer: caller is not token owner nor approved");
				
		_receiveChild(_tokenId, _child.tokenAddress, _child.tokenId, _child.amount);
    }
    
    function receiveChildBatch(uint256 _tokenId, TokenTransferParams[] calldata _children) external nonReentrant {    	
		require(_isApprovedOrOwner(_msgSender(), _tokenId), "NounsComposer: caller is not token owner nor approved");		

		_receiveChildBatch(_tokenId, _children);
    }
    
    function receiveAndComposeChild(uint256 _tokenId, TokenFullParams calldata _child) external nonReentrant {    	
		require(_isApprovedOrOwner(_msgSender(), _tokenId), "NounsComposer: caller is not token owner nor approved");

		_receiveChild(_tokenId, _child.tokenAddress, _child.tokenId, _child.amount);
    	_composeChild(_tokenId, _child.tokenAddress, _child.tokenId, _child.position1, _child.boundTop1, _child.boundLeft1);
    }
    
    function receiveAndComposeChildBatch(uint256 _tokenId, TokenFullParams[] calldata _children) external nonReentrant {    	
		require(_isApprovedOrOwner(_msgSender(), _tokenId), "NounsComposer: caller is not token owner nor approved");

		_receiveChildBatch(_tokenId, _children);
		_composeChildBatch(_tokenId, _children);        
    }    

    function receiveAndComposeChildBatchMixed(uint256 _tokenId, TokenTransferParams[] calldata _childrenReceive, TokenPositionParams[] calldata _childrenCompose) external nonReentrant {    	
		require(_isApprovedOrOwner(_msgSender(), _tokenId), "NounsComposer: caller is not token owner nor approved");

		_receiveChildBatch(_tokenId, _childrenReceive);
		_composeChildBatch(_tokenId, _childrenCompose);
    }    


    function _receiveChildBatch(uint256 _tokenId, TokenTransferParams[] calldata _children) internal {    	
		uint256 len = _children.length;
		
        for (uint256 i = 0; i < len;) {
			_receiveChild(_tokenId, _children[i].tokenAddress, _children[i].tokenId, _children[i].amount);
			unchecked {
            	i++;
        	}
        }
    }

    function _receiveChildBatch(uint256 _tokenId, TokenFullParams[] calldata _children) internal {    	
		uint256 len = _children.length;
		
        for (uint256 i = 0; i < len;) {
			_receiveChild(_tokenId, _children[i].tokenAddress, _children[i].tokenId, _children[i].amount);
			unchecked {
            	i++;
        	}
        }
    }
    
    function _receiveChild(uint256 _tokenId, address _childTokenAddress, uint256 _childTokenId, uint256 _childAmount) internal {        
        uint256 childTokensLength = childTokens[_tokenId][_childTokenAddress].length;
        if (childTokensLength == 0) {
            childContractIndex[_tokenId][_childTokenAddress] = childContracts[_tokenId].length;
            childContracts[_tokenId].push(_childTokenAddress);
        }
        
        uint256 childTokenBalance = childTokenState[_tokenId][_childTokenAddress][_childTokenId].balance;
        if (childTokenBalance == 0) {        	
	        childTokenState[_tokenId][_childTokenAddress][_childTokenId] = ChildTokenState(_childAmount, uint64(childTokensLength), 0, 0, 0);
	        childTokens[_tokenId][_childTokenAddress].push(_childTokenId);
        } else {
	        childTokenState[_tokenId][_childTokenAddress][_childTokenId].balance += _childAmount;
	    }

        _callTransferFrom(_msgSender(), address(this), _childTokenAddress, _childTokenId, _childAmount);
    	emit ChildReceived(_tokenId, _msgSender(), _childTokenAddress, _childTokenId, _childAmount);
    }    
    
    function transferChild(uint256 _tokenId, address _to, TokenTransferParams calldata _child) external nonReentrant {
		require(_isApprovedOrOwner(_msgSender(), _tokenId), "NounsComposer: caller is not token owner nor approved");
        require(_to != address(0), "NounsComposer: transfer to the zero address");

        _transferChild(_tokenId, _to, _child.tokenAddress, _child.tokenId, _child.amount);
    }

    function transferChildBatch(uint256 _tokenId, address _to, TokenTransferParams[] calldata _children) external nonReentrant {
		require(_isApprovedOrOwner(_msgSender(), _tokenId), "NounsComposer: caller is not token owner nor approved");
        require(_to != address(0), "NounsComposer: transfer to the zero address");

		uint256 len = _children.length;
		
        for (uint256 i = 0; i < len;) {
			_transferChild(_tokenId, _to, _children[i].tokenAddress, _children[i].tokenId, _children[i].amount);
			unchecked {
            	i++;
        	}
        }        
    }
    
    function _transferChild(uint256 _tokenId, address _to, address _childTokenAddress, uint256 _childTokenId, uint256 _childAmount) internal {

		ChildTokenState memory childState = childTokenState[_tokenId][_childTokenAddress][_childTokenId];		
        uint256 tokenIndex = childState.index;
        
        require(childState.balance >= _childAmount, "NounsComposer: insufficient balance for transfer");
        
		if (childState.position1 > 0) {
			_removeComposedChild(_tokenId, (childState.position1));
		}

		uint256 newChildBalance;
        unchecked {
        	newChildBalance = childState.balance - _childAmount;
        }

        childTokenState[_tokenId][_childTokenAddress][_childTokenId].balance = newChildBalance;

		if (newChildBalance == 0) {
			// remove token
	        uint256 lastTokenIndex = childTokens[_tokenId][_childTokenAddress].length - 1;
	        uint256 lastToken = childTokens[_tokenId][_childTokenAddress][lastTokenIndex];
	        if (_childTokenId != lastToken) {
	            childTokens[_tokenId][_childTokenAddress][tokenIndex] = lastToken;
	            childTokenState[_tokenId][_childTokenAddress][lastToken].index = uint64(tokenIndex);
	        }

	        childTokens[_tokenId][_childTokenAddress].pop();
	        delete childTokenState[_tokenId][_childTokenAddress][_childTokenId];
	
	        if (lastTokenIndex == 0) {
	        	// remove contract
	            uint256 lastContractIndex = childContracts[_tokenId].length - 1;
	            address lastContract = childContracts[_tokenId][lastContractIndex];
	            if (_childTokenAddress != lastContract) {
	                uint256 contractIndex = childContractIndex[_tokenId][_childTokenAddress];
	                childContracts[_tokenId][contractIndex] = lastContract;
	                childContractIndex[_tokenId][lastContract] = contractIndex;
	            }
	            childContracts[_tokenId].pop();
	            delete childContractIndex[_tokenId][_childTokenAddress];
	        }
		}
				
		_callTransferFrom(address(this), _to, _childTokenAddress, _childTokenId, _childAmount);
    	emit ChildTransferred(_tokenId, _to, _childTokenAddress, _childTokenId, _childAmount);
    }

    function _callTransferFrom(address _from, address _to, address _childTokenAddress, uint256 _childTokenId, uint256 _childAmount) internal {    	
    	IERC165 introContract = IERC165(_childTokenAddress);
    	
        if (introContract.supportsInterface(type(IERC1155).interfaceId)) {
			IERC1155(_childTokenAddress).safeTransferFrom(_from, _to, _childTokenId, _childAmount, "0x0");
		} else if (introContract.supportsInterface(type(IERC20).interfaceId)) {
			IERC20(_childTokenAddress).transferFrom(_from, _to, _childAmount);
		} else if (introContract.supportsInterface(type(IERC721).interfaceId)) {
    		IERC721(_childTokenAddress).transferFrom(_from, _to, _childTokenId);
       	} else {
			revert("NounsComposer: unsupported token type");
       	}    	
    }
    
    /*
     * Child Part Composition
     * 
     */
    
    function composeChild(uint256 _tokenId, TokenPositionParams calldata _child) external {    	
		require(_isApprovedOrOwner(_msgSender(), _tokenId), "NounsComposer: caller is not token owner nor approved");
		require(_childExists(_tokenId, _child.tokenAddress, _child.tokenId), "NounsComposer: compose query for nonexistent child");

    	_composeChild(_tokenId, _child.tokenAddress, _child.tokenId, _child.position1, _child.boundTop1, _child.boundLeft1);
    }

    function composeChildBatch(uint256 _tokenId, TokenPositionParams[] calldata _children) external {
		require(_isApprovedOrOwner(_msgSender(), _tokenId), "NounsComposer: caller is not token owner nor approved");

		_composeChildBatch(_tokenId, _children);
    }

    function removeComposedChild(uint256 _tokenId, uint16 _position1) external {
		require(_isApprovedOrOwner(_msgSender(), _tokenId), "NounsComposer: caller is not token owner nor approved");
		require(composedChildTokens[_tokenId][_position1].tokenAddress != address(0), "NounsComposer: compose query for nonexistent child");		

		_removeComposedChild(_tokenId, _position1);
    }

    function removeComposedChildBatch(uint256 _tokenId, uint16[] calldata _position1s) external {    	
		require(_isApprovedOrOwner(_msgSender(), _tokenId), "NounsComposer: caller is not token owner nor approved");

		uint256 len = _position1s.length;
		
        for (uint256 i = 0; i < len;) {
			require(composedChildTokens[_tokenId][_position1s[i]].tokenAddress != address(0), "NounsComposer: compose query for nonexistent child");		
    		_removeComposedChild(_tokenId, _position1s[i]);
        	
			unchecked {
            	i++;
        	}
        }
    }
    
    function _composeChild(uint256 _tokenId, address _childTokenAddress, uint256 _childTokenId, uint16 _position1, uint8 _boundTop1, uint8 _boundLeft1) internal {
        ChildTokenState memory childState = childTokenState[_tokenId][_childTokenAddress][_childTokenId];

		//first, check if source child token is being moved from an existing position
		if (childState.position1 != 0 && childState.position1 != _position1) {
			_removeComposedChild(_tokenId, childState.position1);
		}

		//this allows for parts to be removed via batch compose calls
    	if (_position1 == 0) {
			return;
    	}
    	
    	//then, check to see if the target position has a child token, if so, clear it
		if (composedChildTokens[_tokenId][_position1].tokenAddress != address(0)) {
			_removeComposedChild(_tokenId, _position1);
		}
		
        composedChildTokens[_tokenId][_position1] = ChildToken(_childTokenAddress, _childTokenId);

		childState.position1 = _position1;
		childState.boundTop1 = _boundTop1;
		childState.boundLeft1 = _boundLeft1;
		
		childTokenState[_tokenId][_childTokenAddress][_childTokenId] = childState;

        emit CompositionAdded(_tokenId, _childTokenAddress, _childTokenId, _position1, _boundTop1, _boundLeft1);
    }

    function _composeChildBatch(uint256 _tokenId, TokenPositionParams[] calldata _children) internal {
		uint256 len = _children.length;
		
        for (uint256 i = 0; i < len;) {
        	require(_childExists(_tokenId, _children[i].tokenAddress, _children[i].tokenId), "NounsComposer: compose query for nonexistent child");
    		_composeChild(_tokenId, _children[i].tokenAddress, _children[i].tokenId, _children[i].position1, _children[i].boundTop1, _children[i].boundLeft1);
        	
			unchecked {
            	i++;
        	}
        }
    }

    function _composeChildBatch(uint256 _tokenId, TokenFullParams[] calldata _children) internal {
		uint256 len = _children.length;
		
        for (uint256 i = 0; i < len;) {
        	require(_childExists(_tokenId, _children[i].tokenAddress, _children[i].tokenId), "NounsComposer: compose query for nonexistent child");
    		_composeChild(_tokenId, _children[i].tokenAddress, _children[i].tokenId, _children[i].position1, _children[i].boundTop1, _children[i].boundLeft1);
        	
			unchecked {
            	i++;
        	}
        }
    }

    function _removeComposedChild(uint256 _tokenId, uint16 _position1) internal {
		ChildToken memory child = composedChildTokens[_tokenId][_position1];
    	
        delete composedChildTokens[_tokenId][_position1];

		ChildTokenState memory childState = childTokenState[_tokenId][child.tokenAddress][child.tokenId];

		childState.position1 = 0;
		childState.boundTop1 = 0;
		childState.boundLeft1 = 0;

		childTokenState[_tokenId][child.tokenAddress][child.tokenId] = childState;

        emit CompositionRemoved(_tokenId, child.tokenAddress, child.tokenId, _position1);
    }

    /*
     * Called by NounsComposableDescriptor
     * 
     */

    function getParts(uint256 _tokenId) external view returns (ISVGRenderer.Part[] memory) {
		//current configuration supports 16 composed items
        uint16 maxParts = 16;
        ISVGRenderer.Part[] memory parts = new ISVGRenderer.Part[](maxParts);

        for (uint16 i = 0; i < maxParts;) {
        	ChildToken memory child = composedChildTokens[_tokenId][i + 1]; //position is a 1-based index
        	
        	if (child.tokenAddress != address(0)) {        	
	        	ISVGRenderer.Part memory part = IComposablePart(child.tokenAddress).getPart(child.tokenId);	        	
	        	ChildTokenState memory childState = childTokenState[_tokenId][child.tokenAddress][child.tokenId];
	        	
	        	if (childState.boundTop1 > 0) {
	        		uint8 boundTop1 = childState.boundTop1 - 1; //top is a 1-based index
	        		
		        	//shift the part's bounding box
		        	uint8 top = uint8(part.image[1]);
	            	uint8 bottom = uint8(part.image[3]);

	            	if (boundTop1 < top) {
	            		top -= (top - boundTop1);
	            		bottom -= (top - boundTop1);
	            	} else if (boundTop1 > top) {
	            		top += (boundTop1 - top);
	            		bottom += (boundTop1 - top);
	            	}

		        	part.image[1] = bytes1(top);
		        	part.image[3] = bytes1(bottom);
		        }

	        	if (childState.boundLeft1 > 0) {
	        		uint8 boundLeft1 = childState.boundLeft1 - 1; //left is a 1-based index

		        	//shift the part's bounding box
	            	uint8 right = uint8(part.image[2]);
	            	uint8 left = uint8(part.image[4]);

	            	if (boundLeft1 < left) {
	            		right -= (left - boundLeft1);
	            		left -= (left - boundLeft1);
	            	} else if (boundLeft1 > left) {
	            		right += (boundLeft1 - left);
	            		left += (boundLeft1 - left);
	            	}
	            	
		        	part.image[2] = bytes1(right);
		        	part.image[4] = bytes1(left);
		        }
		        
	        	parts[i] = part;
	        }

			unchecked {
            	i++;
        	}
        }
        
        return parts;
    }

    function hasParts(uint256 _tokenId) external view returns (bool) {
		//current configuration supports 16 composed items
        uint16 maxParts = 16;

        for (uint16 i = 0; i < maxParts;) {
        	if (composedChildTokens[_tokenId][i + 1].tokenAddress != address(0)) {
        		return true;
	        }

			unchecked {
            	i++;
        	}
        }

        return false;
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = nouns.ownerOf(tokenId);
        return (spender == owner || nouns.getApproved(tokenId) == spender || nouns.isApprovedForAll(owner, spender));
    }

    function _childExists(uint256 _tokenId, address _childTokenAddress, uint256 _childTokenId) internal view returns (bool) {        
        return childTokenState[_tokenId][_childTokenAddress][_childTokenId].balance > 0;
    }    
    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155HolderUpgradeable is Initializable, ERC1155ReceiverUpgradeable {
    function __ERC1155Holder_init() internal initializer {
        __ERC165_init_unchained();
        __ERC1155Receiver_init_unchained();
        __ERC1155Holder_init_unchained();
    }

    function __ERC1155Holder_init_unchained() internal initializer {
    }
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for NounsToken

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

import { IERC721 } from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import { INounsDescriptorMinimal } from './INounsDescriptorMinimal.sol';
import { INounsSeeder } from './INounsSeeder.sol';

interface INounsToken is IERC721 {
    event NounCreated(uint256 indexed tokenId, INounsSeeder.Seed seed);

    event NounBurned(uint256 indexed tokenId);

    event NoundersDAOUpdated(address noundersDAO);

    event MinterUpdated(address minter);

    event MinterLocked();

    event DescriptorUpdated(INounsDescriptorMinimal descriptor);

    event DescriptorLocked();

    event SeederUpdated(INounsSeeder seeder);

    event SeederLocked();

    function mint() external returns (uint256);

    function burn(uint256 tokenId) external;

    function dataURI(uint256 tokenId) external returns (string memory);

    function setNoundersDAO(address noundersDAO) external;

    function setMinter(address minter) external;

    function lockMinter() external;

    function setDescriptor(INounsDescriptorMinimal descriptor) external;

    function lockDescriptor() external;

    function setSeeder(INounsSeeder seeder) external;

    function lockSeeder() external;
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for SVGRenderer

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

interface ISVGRenderer {
    struct Part {
        bytes image;
        bytes palette;
    }

    struct SVGParams {
        Part[] parts;
        string background;
    }

    function generateSVG(SVGParams memory params) external view returns (string memory svg);

    function generateSVGPart(Part memory part) external view returns (string memory partialSVG);

    function generateSVGParts(Part[] memory parts) external view returns (string memory partialSVG);
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for Nouns Composer

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

import { ISVGRenderer } from '../../../interfaces/ISVGRenderer.sol';

interface INounsComposer {

    struct ChildToken {
        address tokenAddress;
        uint256 tokenId;
    }

    struct ChildTokenState {
        uint256 balance;
        uint64 index;
        uint16 position1; //position is a 1-based index
        uint8 boundTop1; //top is a 1-based index
        uint8 boundLeft1; //left is a 1-based index
    }

    struct TokenTransferParams {
        address tokenAddress;
        uint256 tokenId;
        uint256 amount;
    }

    struct TokenPositionParams {
        address tokenAddress;
        uint256 tokenId;
        uint16 position1; //position is a 1-based index
        uint8 boundTop1; //top is a 1-based index
        uint8 boundLeft1; //left is a 1-based index
    }

    struct TokenFullParams {
        address tokenAddress;
        uint256 tokenId;
        uint256 amount;
        uint16 position1; //position is a 1-based index
        uint8 boundTop1; //top is a 1-based index
        uint8 boundLeft1; //left is a 1-based index
    }

    event ChildReceived(uint256 indexed tokenId, address indexed from, address indexed childTokenAddress, uint256 childTokenId, uint256 amount);
    event ChildTransferred(uint256 indexed tokenId, address indexed to, address indexed childTokenAddress, uint256 childTokenId, uint256 amount);
	
	event CompositionAdded(uint256 indexed tokenId, address indexed childTokenAddress, uint256 indexed childTokenId, uint16 position1, uint8 boundTop1, uint8 boundLeft1);
	event CompositionRemoved(uint256 indexed tokenId, address indexed childTokenAddress, uint256 indexed childTokenId, uint16 position1);

    function getChildContracts(uint256 _tokenId) external view returns (address[] memory);

    function getChildTokens(uint256 _tokenId, address _childTokenAddress) external view returns (uint256[] memory);

    function getChildContractCount(uint256 _tokenId) external view returns (uint256);    

    function getChildTokenCount(uint256 _tokenId, address _childTokenAddress) external view returns (uint256);

    function getChildTokenState(uint256 _tokenId, address _childTokenAddress, uint256 _childTokenId) external view returns (ChildTokenState memory);

    function getChildTokenStateBatch(uint256 _tokenId, address[] calldata _childTokenAddresses, uint256[] calldata _childTokenIds) external view returns (ChildTokenState[] memory);

    function getComposedChild(uint256 tokenId, uint16 position1) external view returns (ChildToken memory);

	function getComposedChildBatch(uint256 _tokenId, uint16 _position1Start, uint16 _position1End) external view returns (ChildToken[] memory);
    
    function childExists(uint256 _tokenId, address _childTokenAddress, uint256 _childTokenId) external view returns (bool);

    function receiveChild(uint256 _tokenId, TokenTransferParams calldata _child) external;
        
    function receiveChildBatch(uint256 _tokenId, TokenTransferParams[] calldata _children) external;
    
    function receiveAndComposeChild(uint256 _tokenId, TokenFullParams calldata _child) external;
        
    function receiveAndComposeChildBatch(uint256 _tokenId, TokenFullParams[] calldata _children) external;

    function receiveAndComposeChildBatchMixed(uint256 _tokenId, TokenTransferParams[] calldata _childrenReceive, TokenPositionParams[] calldata _childrenCompose) external;
    
    function transferChild(uint256 _tokenId, address _to, TokenTransferParams calldata _child) external;
    
    function transferChildBatch(uint256 _tokenId, address _to, TokenTransferParams[] calldata _children) external;

    function composeChild(uint256 _tokenId, TokenPositionParams calldata _child) external;

    function composeChildBatch(uint256 _tokenId, TokenPositionParams[] calldata _children) external;

    function removeComposedChild(uint256 _tokenId, uint16 _position1) external;

    function removeComposedChildBatch(uint256 _tokenId, uint16[] calldata _position1s) external;

    function getParts(uint256 _tokenId) external view returns (ISVGRenderer.Part[] memory);

    function hasParts(uint256 _tokenId) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for a Composable Part

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

import { ISVGRenderer } from '../../../interfaces/ISVGRenderer.sol';

interface IComposablePart {	
    function getPart(uint256 tokenId) external view returns (ISVGRenderer.Part memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155ReceiverUpgradeable.sol";
import "../../../utils/introspection/ERC165Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155ReceiverUpgradeable is Initializable, ERC165Upgradeable, IERC1155ReceiverUpgradeable {
    function __ERC1155Receiver_init() internal initializer {
        __ERC165_init_unchained();
        __ERC1155Receiver_init_unchained();
    }

    function __ERC1155Receiver_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

/// @title Common interface for NounsDescriptor versions, as used by NounsToken and NounsSeeder.

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

import { INounsSeeder } from './INounsSeeder.sol';

interface INounsDescriptorMinimal {
    ///
    /// USED BY TOKEN
    ///

    function tokenURI(uint256 tokenId, INounsSeeder.Seed memory seed) external view returns (string memory);

    function dataURI(uint256 tokenId, INounsSeeder.Seed memory seed) external view returns (string memory);

    ///
    /// USED BY SEEDER
    ///

    function backgroundCount() external view returns (uint256);

    function bodyCount() external view returns (uint256);

    function accessoryCount() external view returns (uint256);

    function headCount() external view returns (uint256);

    function glassesCount() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for NounsSeeder

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

import { INounsDescriptorMinimal } from './INounsDescriptorMinimal.sol';

interface INounsSeeder {
    struct Seed {
        uint48 background;
        uint48 body;
        uint48 accessory;
        uint48 head;
        uint48 glasses;
    }

    function generateSeed(uint256 nounId, INounsDescriptorMinimal descriptor) external view returns (Seed memory);
}