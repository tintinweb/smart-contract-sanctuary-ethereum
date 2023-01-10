// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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
pragma solidity ^0.8.9;

/*According to Alithea AI iNFT smart contract 
  link:https://etherscan.io/address/0xa189121eE045AEAA8DA80b72F7a1132e3B216237#code
*/


import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


library StringUtils {
	function atoi(string memory a, uint8 base) internal pure returns (uint256 i) {
		require(base == 2 || base == 8 || base == 10 || base == 16);

		bytes memory buf = bytes(a);

		for(uint256 p = 0; p < buf.length; p++) {
			uint8 digit = uint8(buf[p]) - 0x30;

			if(digit > 10) {
				digit -= 7;
			}
			require(digit < base);
			i *= base;
			i += digit;
		}

		return i;
	}


	function itoa(uint256 i, uint8 base) internal pure returns (string memory a) {
		require(base == 2 || base == 8 || base == 10 || base == 16);
		if(i == 0) {
			return "0";
		}

		bytes memory buf = new bytes(256);
		uint256 p = 0;

		while(i > 0) {
			uint8 digit = uint8(i % base);

			uint8 ascii = digit + 0x30;


			if(digit >= 10) {
				ascii += 7;
			}

			buf[p++] = bytes1(ascii);

			i /= base;
		}

		bytes memory result = new bytes(p);

		for(p = 0; p < result.length; p++) {
			result[result.length - p - 1] = buf[p];
		}

		return string(result);
	}

	function concat(string memory s1, string memory s2) internal pure returns (string memory s) {
		return string(abi.encodePacked(s1, s2));
	}
}



interface ItestNFTWrapper {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

	function totalSupply() external view returns (uint256);

	function tokenURI(uint256 recordId) external view returns (string memory);

}




contract testNFTWrapper is ItestNFTWrapper, IERC165, Ownable{
    using StringUtils for uint256;

    string public override name = "testNFTWrapper";
    string public override symbol = "tNW";

    struct NFTWrapper{
        address characterNFT;

        uint256 characterId;

        uint96 KDValue;
    }

    mapping(uint256 => NFTWrapper) public Wrappers;

    mapping(address => mapping(uint256 => uint256)) public characterWrappers;

    uint256 public override totalSupply;

    address public constant KDContract = 0x8bC40df20333186eDF17DF1Fe635191306C4C614;

    uint256 public KDBalance;

    string public baseURI = "";

    mapping(uint256 => string) internal _tokenURIs;

    event BaseURIupdate(address indexed _by, string _oldVal, string _newVal);

    event TokenURIUpdated(address indexed _by, uint256 indexed _tokenId, string _oldVal, string _newVal);

    event Minted(
        address indexed _by,
        address indexed _owner,
        uint256 indexed _recordId,
        uint96 _KDValue,
        address _characterNFT,
        uint256 _characterId
    );

    event Updated(
        address indexed _by,
        address indexed _owner,
        uint256 indexed _recordId,
        uint96 _oldKDValue,
        uint96 _newKDValue
    );

    event Burnt(
        address indexed _by,
        uint256 indexed _recordId,
        address indexed _recipient,
        uint96 _KDValue,
        address _characterNFT,
        uint256 _characterId
    );

    

    function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
        return interfaceId == type(ItestNFTWrapper).interfaceId;
    }

	function setBaseURI(string memory _baseURI) public virtual onlyOwner {

		emit BaseURIupdate(msg.sender, baseURI, _baseURI);

		baseURI = _baseURI;
	}

    function tokenURI(uint256 _recordId) public view override returns (string memory) {
		require(exists(_recordId), "iNFT doesn't exist");
		string memory _tokenURI = _tokenURIs[_recordId];

		if(bytes(_tokenURI).length > 0) {
			return _tokenURI;
		}

		if(bytes(baseURI).length == 0) {
			return "";
		}

		return StringUtils.concat(baseURI, StringUtils.itoa(_recordId, 10));
	}

    function exists(uint256 recordId) public view returns (bool) {
		return Wrappers[recordId].characterNFT != address(0);
	}

	function ownerOf(uint256 recordId) public view returns (address) {
		NFTWrapper storage Wrapper = Wrappers[recordId];

		require(Wrapper.characterNFT != address(0), "iNFT doesn't exist");

		return IERC721(Wrapper.characterNFT).ownerOf(Wrapper.characterId);
	}

    function setTokenURI(uint256 _tokenId, string memory _tokenURI) public virtual onlyOwner {
        emit TokenURIUpdated(msg.sender, _tokenId, _tokenURIs[_tokenId], _tokenURI);
        _tokenURIs[_tokenId] = _tokenURI;
    }

    function mint(
        uint256 recordId,
        uint96 KDValue,
        address characterNFT,
        uint256 characterId
    ) public onlyOwner{
		require(IERC165(characterNFT).supportsInterface(type(IERC721).interfaceId), "characterNFT is not ERC721");

		require(!exists(recordId), "iNFT already exists");

		require(characterWrappers[characterNFT][characterId] == 0, "NFT is already bound");

        address owner = IERC721(characterNFT).ownerOf(characterId);

        require(owner != address(0));

        if(KDValue > 0){
            require(KDBalance + KDValue <= IERC20(KDContract).balanceOf(address(this)), "KD tokens not yet transferred");
            KDBalance += KDValue;
        }

        Wrappers[recordId] = NFTWrapper({
            characterNFT : characterNFT,
            characterId : characterId,
            KDValue : KDValue
        });

        characterWrappers[characterNFT][characterId] = recordId;

        totalSupply++;
        emit Minted(
            msg.sender,
            owner,
            recordId,
            KDValue,
            characterNFT,
            characterId
        );
    }

    function mintbatch(
        uint256 recordId,
        uint96 KDValue,
        address characterNFT,
        uint256 characterId,
        uint96 n
    ) public onlyOwner{
		require(IERC165(characterNFT).supportsInterface(type(IERC721).interfaceId), "characterNFT is not ERC721");

        require(n > 1, "n is too small");

		for(uint96 i = 0; i < n; i++) {
            require(!exists(recordId + i), "iNFT already exists");
            require(characterWrappers[characterNFT][characterId + i] == 0, "NFT is already bound");
            address owner = IERC721(characterNFT).ownerOf(characterId + i);

            require(owner != address(0));
            emit Minted(
                msg.sender,
                owner,
                recordId+i,
                KDValue,
                characterNFT,
                characterId+i 
            );
        }
        
        uint256 _KDValue = uint256(KDValue) * n;

        if(_KDValue > 0){
            require(KDBalance + _KDValue <= IERC20(KDContract).balanceOf(address(this)), "KD tokens not yet transferred");
            KDBalance += _KDValue;
        }

	    for(uint96 i = 0; i < n; i++) {
            Wrappers[recordId + i] = NFTWrapper({
                characterNFT : characterNFT,
                characterId : characterId+i,
                KDValue : KDValue
            });
            characterWrappers[characterNFT][characterId + i] = recordId + i;
        }
        totalSupply += n;
    }

    function burn(uint256 recordId) public onlyOwner{
        totalSupply--;

        NFTWrapper memory Wrapper  = Wrappers[recordId];
 
        require(Wrapper.characterNFT != address(0), "not bound");
        
        delete Wrappers[recordId];

        delete characterWrappers[Wrapper.characterNFT][Wrapper.characterId];        


        address owner = IERC721(Wrapper.characterNFT).ownerOf(Wrapper.characterId);

        require(owner != address(0), "no such NFT");

        if(Wrapper.KDValue > 0){
            KDBalance -= Wrapper.KDValue;
            IERC20(KDContract).transfer(owner, Wrapper.KDValue);
        }

		emit Burnt(
			msg.sender,
			recordId,
			owner,
			Wrapper.KDValue,
			Wrapper.characterNFT,
			Wrapper.characterId
		);
        

    }


    function increaseKD(uint256 recordId, uint96 KDDelta) public onlyOwner{

		require(KDDelta != 0, "zero value");

		address owner = ownerOf(recordId);

		uint96 KDValue = Wrappers[recordId].KDValue;

		require(KDBalance + KDDelta <= IERC20(KDContract).balanceOf(address(this)), "KD tokens not yet transferred");

		KDBalance += KDDelta;

		Wrappers[recordId].KDValue = KDValue + KDDelta;

		emit Updated(msg.sender, owner, recordId, KDValue, KDValue + KDDelta);
	}


    function decreaseKD(uint256 recordId, uint96 KDDelta, address recipient) public onlyOwner{

		require(KDDelta != 0, "zero value");
		require(recipient != address(0), "zero address");

		address owner = ownerOf(recordId);
		uint96 KDValue = Wrappers[recordId].KDValue;

		require(KDValue >= KDDelta, "not enough KD");
		KDBalance -= KDDelta;

		Wrappers[recordId].KDValue = KDValue - KDDelta;

		IERC20(KDContract).transfer(recipient, KDDelta);

		emit Updated(msg.sender, owner, recordId, KDValue, KDValue - KDDelta);
	}

	function lockedValue(uint256 recordId) public view returns(uint96) {
		require(exists(recordId), "wrappedNFT doesn't exist");

		return Wrappers[recordId].KDValue;
	}

}