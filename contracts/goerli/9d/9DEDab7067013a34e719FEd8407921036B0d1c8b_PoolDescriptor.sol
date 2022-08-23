pragma solidity 0.8.6;

/// @title Pool NFT descriptor
/// @dev From the The Nouns NFT descriptor


import { Ownable } from "Ownable.sol";
import { Strings } from "Strings.sol";
import { NFTDescriptor } from "NFTDescriptor.sol";
import { IJellyPool } from "IJellyPool.sol";
import { IJellyPoolHelper } from "IJellyPoolHelper.sol";

interface IJellyPoolWrapper {
    function rewardsContract() external view returns(address);
}

interface IJellyRewarderWrapper {
    function rewardsToken() external view returns(address);
}



contract PoolDescriptor is Ownable, NFTDescriptor {
    using Strings for uint256;
    using Strings for address;

    IJellyPool public poolAddress;
    IJellyPoolHelper public poolHelper;

    uint256 public constant TEMPLATE_TYPE = 8;
    bytes32 public constant TEMPLATE_ID = keccak256("POOL_DESCRIPTOR");

    // Whether or not `tokenURI` should be returned as a data URI (Default: true)
    bool public isDataURIEnabled = true;

    // Base URI
    string public baseURI;
    string public imageURL;
    string public tokenName;
    string public tokenDescription;

    event DataURIToggled(bool enabled);
    event BaseURIUpdated(string baseURI);
    event PoolSet(address poolAddress);
    event ImageSet(string imageURL);
    event TokenNameSet(string tokenName);
    event TokenDescriptionSet(string tokenName);

    /**
     * @notice Toggle a boolean value which determines if `tokenURI` returns a data URI
     * or an HTTP URL.
     * @dev This can only be called by the owner.
     */
    function toggleDataURIEnabled() external onlyOwner  {
        bool enabled = !isDataURIEnabled;

        isDataURIEnabled = enabled;
        emit DataURIToggled(enabled);
    }

    /**
     * @notice Set the base URI for all token IDs. It is automatically
     * added as a prefix to the value returned in {tokenURI}, or to the
     * token ID if {tokenURI} is empty.
     * @dev This can only be called by the owner.
     */
    function setBaseURI(string calldata _baseURI) external  onlyOwner  {
        baseURI = _baseURI;

        emit BaseURIUpdated(_baseURI);
    }

    /**
     * @notice Set the base URI for all token IDs. It is automatically
     * added as a prefix to the value returned in {tokenURI}, or to the
     * token ID if {tokenURI} is empty.
     * @dev This can only be called by the owner.
     */
    function setPool(address _poolAddress) external  onlyOwner  {
        poolAddress = IJellyPool(_poolAddress);
        emit PoolSet(_poolAddress);
    }

    function setPoolHelper(address _poolHelper) external  onlyOwner  {
        poolHelper = IJellyPoolHelper(_poolHelper);
        // emit PoolHelperSet(_poolHelper);
    }

    function setImage(string calldata _imageURL) external  onlyOwner  {
        imageURL = _imageURL;
        emit ImageSet(_imageURL);
    }

    function setTokenName(string calldata _tokenName) external  onlyOwner  {
        tokenName = _tokenName;
        emit TokenNameSet(_tokenName);
    }

    function setTokenDescription(string calldata _tokenDescription) external  onlyOwner  {
        tokenDescription = _tokenDescription;
        emit TokenDescriptionSet(_tokenDescription);
    }

    /**
     * @notice Given a token ID and seed, construct a token URI for an NFT.
     * @dev The returned value may be a base64 encoded data URI or an API URL.
     */
    function tokenURI(uint256 tokenId) external view  returns (string memory) {
        if (isDataURIEnabled) {
            return dataURI(tokenId);
        }
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    function stakedAmountStr(uint256 tokenId) internal view returns (string memory) {
        uint256 amount = poolAddress.stakedBalance(tokenId);
        string memory amountStr = (amount / 10 ** 18).toString();
        uint256 remainder = (amount / 10 ** 14) % 10000;
        string memory remainderStr;
        if (remainder > 999) {
            remainderStr = string(abi.encodePacked((remainder).toString()));
        } else if (remainder > 99) {
            remainderStr = string(abi.encodePacked('0', (remainder).toString()));
        } else if (remainder > 9) {
            remainderStr = string(abi.encodePacked('00', (remainder).toString()));
        } else  {
            remainderStr = string(abi.encodePacked('000', (remainder).toString()));
        }
        return string(abi.encodePacked(amountStr, '.', remainderStr)); 
    }

    function generateAttributesList(uint256 tokenId) public view returns (string memory) {
        string memory editionStr = "Open";
        return string(
            abi.encodePacked(
                '{"trait_type":"Staked Amount","value":', stakedAmountStr(tokenId),'},',
                '{"trait_type":"Token ID","value":', tokenId.toString(), '},',
                '{"trait_type":"Edition","value":"', editionStr, '"}'
            )
        );
    }


    /**
     * @notice Given a token ID and seed, construct a base64 encoded data URI for an NFT.
     */
    function dataURI(uint256 tokenId) public view returns (string memory) {
        string memory name = string(abi.encodePacked(stakedAmountStr(tokenId), tokenName));
        string memory unclaimedStr = (unclaimed(tokenId) / 10 ** 18).toString();
        // ', address(poolAddress),'
        string memory description = string(abi.encodePacked('WARNING: Staking NFTs are a new type of Defi NFT and Opensea does not update staked position information in real time. \\n\\n##AMOUNTS (refresh Metadata to update)\\n\\n'
            , ' Staked JELLY/USDC SLP on last refresh was ', stakedAmountStr(tokenId)
            , '\\n\\nUnclaimed $JELLY rewards on last refresh was ', unclaimedStr
            , '\\n\\n'
            , tokenDescription));
        string memory attributes = generateAttributesList(tokenId);

        return genericDataURI(name, description, imageURL, attributes);
    }

    function unclaimed(uint256 tokenId) public view returns (uint256) {
        return poolHelper.unclaimedRewards(address(poolAddress), rewardsToken(),tokenId);
    }

    function rewardsToken() public view returns (address) {
        return IJellyRewarderWrapper(IJellyPoolWrapper(address(poolAddress)).rewardsContract()).rewardsToken();
    }


    /**
     * @notice Given a name, description, and seed, construct a base64 encoded data URI.
     */
    function genericDataURI(
        string memory _name,
        string memory _description,
        string memory _image,
        string memory _attributes
    ) public view returns (string memory) {
        TokenURIParams memory params = TokenURIParams({
            name: _name,
            description: _description,
            image: _image,
            attributes: _attributes
        });
        return constructTokenURI(params);
    }

}

pragma solidity ^0.8.0;

import "Context.sol";

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

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

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0);
        return string(buffer);
    }
}

/// @title A library used to construct ERC721 token URIs and SVG images
/// @dev From the Nouns NFT descriptor

pragma solidity 0.8.6;

import { Base64 } from "Base64.sol";

contract NFTDescriptor {
    struct TokenURIParams {
        string name;
        string description;
        string image;
        string attributes;
    }

    /**
     * @notice Construct an ERC721 token URI.
     */
    function constructTokenURI(TokenURIParams memory params)
        public
        view
        returns (string memory)
    {
        // prettier-ignore
        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked('{"name":"', params.name, '", "description":"', params.description, '", "image": "', params.image,'", "attributes": [', params.attributes, ']}')
                    )
                )
            )
        );
    }

}

pragma solidity 0.8.6;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)
            
            // prepare the lookup table
            let tablePtr := add(table, 1)
            
            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            
            // result ptr, jump over length
            let resultPtr := add(result, 32)
            
            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
}

pragma solidity 0.8.6;

interface IJellyPool {

    function setRewardsContract(address _addr) external;
    function setTokensClaimable(bool _enabled) external;

    function stakedTokenTotal() external view returns(uint256);
    function stakedBalance(uint256 _tokenId) external view returns(uint256);
    function tokensClaimable() external view returns(bool);
    function poolToken() external view returns(address);

}

pragma solidity 0.8.6;

interface IJellyPoolHelper {

    function unclaimedRewards(address _pool, address _rewardToken, uint256 _tokenId) external view returns(uint256);


}