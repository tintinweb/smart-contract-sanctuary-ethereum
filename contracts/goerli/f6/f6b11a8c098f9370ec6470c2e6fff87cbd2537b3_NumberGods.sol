// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {Base64} from "./Base64.sol";

// contract NumberGods is ERC721A, ERC721AQueryable, Ownable {
contract NumberGods is ERC721A, Ownable {
    uint256 public MAX_SUPPLY = 10000;
    uint256 public MAX_MINTS_PER_WALLET = 25;
    uint256 public MAX_FREE_SUPPLY = 4000;
    uint256 public MAX_FREE_MINTS_PER_WALLET = 5;
    uint256 public MINT_PRICE = 0.005 ether;

    bool public isPaused = false;

    struct TokenData {
        // Type of token. If false, it's a number
        bool isModifier;
        // The value of the number/modifier
        uint64 value;
        uint64 generation;
    }

    // Mapping from token ID to TokenData
    mapping(uint256 => TokenData) private _tokenData;

    constructor() ERC721A("number gods123h2hdb12hd", "NNMGDMNGD") {}

    function mint(uint256 quantity) external payable {
        require(!isPaused, "Sales are off");
        require(_totalMinted() + quantity <= MAX_SUPPLY, "Not enough tokens left");

        if (_totalMinted() <= MAX_FREE_SUPPLY){
            require(quantity + _numberMinted(msg.sender) <= MAX_FREE_MINTS_PER_WALLET, "Exceeded wallet limit");
        }else{
            require(quantity + _numberMinted(msg.sender) <= MAX_MINTS_PER_WALLET, "Exceeded wallet limit");
    		require(msg.value >= quantity * MINT_PRICE, "Ether value sent is not sufficient");
        }

        uint256 startingTokenId = _nextTokenId();
        for(uint256 _tokenId=startingTokenId; _tokenId<startingTokenId + quantity; _tokenId++){
            _tokenData[_tokenId] = createRandomToken(_tokenId);
        }

        _safeMint(msg.sender, quantity);
    }

    function combine(uint256 _tokenId1, uint256 _tokenId2) external payable {
        require(_exists(_tokenId1) && _exists(_tokenId2), "Invalid Token");
        require(ownerOf(_tokenId1) == msg.sender && ownerOf(_tokenId2) == msg.sender, "Invalid Owner");

        TokenData memory newTokenData = combineTokens(_tokenId1, _tokenId2);

        _burn(_tokenId1);
        _burn(_tokenId2);
        delete _tokenData[_tokenId1];
        delete _tokenData[_tokenId2];
        
        uint256 _newTokenId = _nextTokenId();
        _tokenData[_newTokenId] = newTokenData;

        _safeMint(msg.sender, 1);

        emit TokenCombined(_tokenId1, _tokenId2, _newTokenId);
    }

    event TokenCombined(uint256 tokenId1, uint256 tokenId2, uint256 newTokenId);

    function createRandomToken(uint256 _tokenId) private view returns (TokenData memory) {
        uint64 value;
        uint r = random(1000, _tokenId);
        bool isModifier = r > 955;

        if ( r <= 90 ) {
            value = 1;
        } else if ( r <= 175 ) {
            value = 2;
        } else if ( r <= 255 ) {
            value = 3;
        } else if ( r <= 355 ) {
            value = 4;
        } else if ( r <= 405 ) {
            value = 5;
        } else if ( r <= 475 ) {
            value = 6;
        } else if ( r <= 545 ) {
            value = 7;
        } else if ( r <= 605 ) {
            value = 8;
        } else if ( r <= 665 ) {
            value = 9;
        } else if ( r <= 725 ) {
            value = 10;
        } else if ( r <= 775 ) {
            value = 11;
        } else if ( r <= 825 ) {
            value = 12;
        } else if ( r <= 875 ) {
            value = 13;
        } else if ( r <= 915 ) {
            value = 14;
        } else if ( r <= 955 ) {
            value = 15;
        } else if ( r <= 985 ) {
            value = 2;
        } else if ( r <= 995 ) {
            value = 3;
        } else if ( r <= 998 ) {
            value = 4;
        } else {
            value = 5;
        }

        return TokenData(
            isModifier,
            value,
            1
        );
    }

    function tokenURI(uint256 _tokenId) public view virtual override(ERC721A) returns (string memory) {
        require(_exists(_tokenId), "Invalid Token");

        bool isModifier = _tokenData[_tokenId].isModifier;
        uint64 value = _tokenData[_tokenId].value;
        string memory tokenIdStr = Strings.toString(_tokenId);

        string memory json = Base64.encode(
            bytes(string(
                abi.encodePacked(
                    '{"name": "NUMGOD #', tokenIdStr, '",',
                    '"description": "something",',
                    '"image":"https://number-quest.vercel.app/?token=', tokenIdStr ,'&value=', isModifier ? 'x' : '', Strings.toString( value ) ,'",'
                    // '"image_data":"', generateImageURI(isModifier, value), '",',
                    //'"animation_url":"https://bafkreic6lghermh2naqz3g7vzvlupmwvsojp3wnrdtsmqpdpfkulwjvxte.ipfs.nftstorage.link/?value=',  Strings.toString( value ), '",',
                    // '"animation_url":"https://bafkreic6lghermh2naqz3g7vzvlupmwvsojp3wnrdtsmqpdpfkulwjvxte.ipfs.nftstorage.link?token=', tokenIdStr ,'&value=',  Strings.toString( value ), '",',
                    '"attributes":[',
                    formTokenAttributes(_tokenId, isModifier, value),
                    ']}'
                )
            ))
        );

        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function formTokenAttributes(uint256 _tokenId, bool isModifier, uint64 value) private view returns (string memory) {
        // bool isModifier = _tokenData[_tokenId].isModifier;
        // uint64 value = _tokenData[_tokenId].value;
        uint64 generation = _tokenData[_tokenId].generation;

        return string(
            abi.encodePacked(
                '{"trait_type":"Type","value":"', isModifier ? 'Multiplier' : 'Number', '"},',
                '{"trait_type":"', (isModifier ? 'Multiplier' : 'Number'), '","value":', getLabel( isModifier, value, false ), '},',
                '{"trait_type":"Generation","value":', Strings.toString( generation ), '}'
            )
        );
    }

    function getData(uint256 _tokenId) public view returns (TokenData memory) {
        require(_exists(_tokenId), "URI does not exist!");
        return _tokenData[_tokenId];
    }

    function setData(uint256 _tokenId, bool isModifier, uint64 value, uint64 generation) external onlyOwner {
        require(_exists(_tokenId), "URI does not exist!");
        _tokenData[_tokenId].isModifier = isModifier;
        _tokenData[_tokenId].value = value;
        _tokenData[_tokenId].generation = generation;
    }

    function combineTokens(uint256 _tokenId1, uint256 _tokenId2) public view returns (TokenData memory) {
        require(_exists(_tokenId1), "Invalid Token");
        require(_exists(_tokenId2), "Invalid Token");

        TokenData memory _token1Data = _tokenData[_tokenId1];
        TokenData memory _token2Data = _tokenData[_tokenId2];

        bool isModifier = false;
        uint64 value;
        uint64 generation = _token1Data.generation > _token2Data.generation ? _token1Data.generation + 1 : _token2Data.generation + 1;

        if ( ! _token1Data.isModifier && ! _token2Data.isModifier ) {
            value = _token1Data.value + _token2Data.value;
        } else if ( _token1Data.isModifier && _token2Data.isModifier ) {
            isModifier = true;
            value = _token1Data.value * _token2Data.value;
        } else {
            value = _token1Data.value * _token2Data.value;
        }

        // Limits
        if ( ! isModifier && value > 18446744073709551615){
            value = 18446744073709551615;
        } else if ( isModifier && value > 999 ) {
            value = 999;
        }

        return TokenData(
            isModifier,
            value,
            generation
        );
    }

    // function generateImageURI(bool isModifier, uint64 value)
    //     private
    //     pure
    //     returns (string memory)
    // {
    //     string memory fontSize = '250';

    //     return '<svg viewBox=\\\"0 0 1024 1024\\\" xmlns=\\\"http://www.w3.org/2000/svg\\\" style=\\\"background:#000;background-image:url(https://bafybeid2za57va47nskzlpzavwustyteg42s66h4xzpkcjw2bgtnso4saa.ipfs.nftstorage.link/);background-size:cover\\\"><defs><style>@font-face {font-family: \\\"a\\\";}</style></defs><style>text{font-size:250px;font-family:\\\"a\\\",sans-serif;fill:#fff;text-shadow:4px 4px 60px #000;}</style><text x=\\\"50%\\\" y=\\\"50%\\\" dominant-baseline=\\\"central\\\" text-anchor=\\\"middle\\\">5</text></svg>';
    //     // return string.concat(
    //     //     "data:image/svg+xml;base64,",
    //     //     Base64.encode(bytes(
    //     //         abi.encodePacked(
    //     //             // '<svg viewBox="0 0 1024 1024" xmlns="http://www.w3.org/2000/svg" style="background:#000;background-image:url(https://gateway.pinata.cloud/ipfs/QmT1xkgBz9Lcuhv5BCXmGBYZtQmhjYgaQLPWnLkprwi1LW/punks-375.png);background-size:cover">',
    //     //             '<svg viewBox="0 0 1024 1024" xmlns="http://www.w3.org/2000/svg" style="background:#000;background-image:url(https://bafybeid2za57va47nskzlpzavwustyteg42s66h4xzpkcjw2bgtnso4saa.ipfs.nftstorage.link/);background-size:cover">',
    //     //             '<defs><style>',
    //     //             '@font-face {',
    //     //             'font-family: "a";',
    //     //             // 'src: url("data:application/font-woff;charset=utf-8;base64,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") format("woff2");',
    //     //             '}',
    //     //             '</style></defs>',
    //     //             '<style>text{font-size:', fontSize, 'px;font-family:"a",sans-serif;fill:#fff;text-shadow:4px 4px 60px #000;}</style>',
    //     //             '<text x="50%" y="50%" dominant-baseline="central" text-anchor="middle">',
    //     //             getLabel( isModifier, value, true ),
    //     //             '</text>',
    //     //             '</svg>'
    //     //         )
    //     //     ))
    //     // );
    // }

    function formatNumber(uint64 num) public pure returns (string memory) {
        if (num >= 1000000000) {
            return formatScientificNotation(num);
        }
        else {
            return formatCommaNumeric(num);
        }
    }

    function formatCommaNumeric(uint64 num) private pure returns (string memory) {
        string memory value = Strings.toString(num);
        string memory newValue = "";
        bytes memory valueBytes = bytes(value);
        uint counter = 0;
        for (uint i = valueBytes.length; i > 0; i--) {
            counter++;
            newValue = string(abi.encodePacked(
                i - 1 != 0 && counter % 3 == 0 ? ',' : '',
                valueBytes[i - 1],
                newValue
            ));
        }
        return newValue;
    }

    function formatScientificNotation(uint64 num) private pure returns (string memory) {
        uint64 mantissa = num;
        uint64 exponent = 0;
        while(mantissa >= 10) {
            exponent++;
            mantissa /= 10;
        }
        return string(abi.encodePacked(Strings.toString(mantissa), "e", Strings.toString(exponent)));
    }

    function getLabel(bool isModifier, uint64 value, bool forDisplay) private pure returns (string memory) {
        if ( ! forDisplay ) {
            return Strings.toString(value);
        }
        if ( ! isModifier ) {
            return formatNumber(value);
        }
        return string.concat( 'x', formatNumber(value) );
    }

    function random(uint max, uint256 seed) private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, Strings.toString(seed)))) % max + 1;
    }

    function setPause(bool value) external onlyOwner {
		isPaused = value;
	}

    function withdraw() external onlyOwner {
		uint balance = address(this).balance;
		require(balance > 0, 'Nothing to Withdraw');
        payable(owner()).transfer(balance);
    }

    // function withdrawTo(address to) external onlyOwner {
	// 	uint balance = address(this).balance;
	// 	require(balance > 0, 'Nothing to Withdraw');
    //     payable(to).transfer(balance);
    // }

    function setPrice(uint256 _price) public onlyOwner {
        MINT_PRICE = _price;
    }

    function setMaxSupply(uint256 _supply) public onlyOwner {
        MAX_SUPPLY = _supply;
    }

    function setMaxFreeSupply(uint256 _supply) public onlyOwner {
        MAX_FREE_SUPPLY = _supply;
    }

    function setMaxMintPerWallet(uint256 _mint) public onlyOwner {
        MAX_MINTS_PER_WALLET = _mint;
    }

    function setMaxFreeMintPerWallet(uint256 _mint) public onlyOwner {
        MAX_FREE_MINTS_PER_WALLET = _mint;
    }

	function xGoFly(address to, uint quantity) external onlyOwner {
		require(
			_totalMinted() + quantity <= MAX_SUPPLY,
			'Exceeded the limit'
		);

        uint256 startingTokenId = _nextTokenId();
        for(uint256 _tokenId=startingTokenId; _tokenId<startingTokenId + quantity; _tokenId++){
            _tokenData[_tokenId] = createRandomToken(_tokenId);
        }

        _safeMint(to, quantity);
	}

    // function xAirdropToMulti(address[] memory airdrops, uint[] memory quantity) external onlyOwner {
    //     for(uint i=0; i<airdrops.length; i++){
    //         require(
    //             _totalMinted() + quantity[i] <= MAX_SUPPLY,
    //             'Exceeded the limit'
    //         );

    //         uint256 startingTokenId = _nextTokenId();
    //         for(uint256 _tokenId=startingTokenId; _tokenId<startingTokenId + quantity[i]; _tokenId++){
    //             _tokenData[_tokenId] = createRandomToken(_tokenId);
    //         }

    //         _safeMint(airdrops[i], quantity[i]);
    //     }
    // }
}

/**
 *Submitted for verification at Etherscan.io on 2021-09-05
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.1.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import './IERC721AQueryable.sol';
import '../ERC721A.sol';

/**
 * @title ERC721A Queryable
 * @dev ERC721A subclass with convenience query functions.
 */
abstract contract ERC721AQueryable is ERC721A, IERC721AQueryable {
    /**
     * @dev Returns the `TokenOwnership` struct at `tokenId` without reverting.
     *
     * If the `tokenId` is out of bounds:
     *   - `addr` = `address(0)`
     *   - `startTimestamp` = `0`
     *   - `burned` = `false`
     *   - `extraData` = `0`
     *
     * If the `tokenId` is burned:
     *   - `addr` = `<Address of owner before token was burned>`
     *   - `startTimestamp` = `<Timestamp when token was burned>`
     *   - `burned = `true`
     *   - `extraData` = `<Extra data when token was burned>`
     *
     * Otherwise:
     *   - `addr` = `<Address of owner>`
     *   - `startTimestamp` = `<Timestamp of start of ownership>`
     *   - `burned = `false`
     *   - `extraData` = `<Extra data at start of ownership>`
     */
    function explicitOwnershipOf(uint256 tokenId) public view override returns (TokenOwnership memory) {
        TokenOwnership memory ownership;
        if (tokenId < _startTokenId() || tokenId >= _nextTokenId()) {
            return ownership;
        }
        ownership = _ownershipAt(tokenId);
        if (ownership.burned) {
            return ownership;
        }
        return _ownershipOf(tokenId);
    }

    /**
     * @dev Returns an array of `TokenOwnership` structs at `tokenIds` in order.
     * See {ERC721AQueryable-explicitOwnershipOf}
     */
    function explicitOwnershipsOf(uint256[] memory tokenIds) external view override returns (TokenOwnership[] memory) {
        unchecked {
            uint256 tokenIdsLength = tokenIds.length;
            TokenOwnership[] memory ownerships = new TokenOwnership[](tokenIdsLength);
            for (uint256 i; i != tokenIdsLength; ++i) {
                ownerships[i] = explicitOwnershipOf(tokenIds[i]);
            }
            return ownerships;
        }
    }

    /**
     * @dev Returns an array of token IDs owned by `owner`,
     * in the range [`start`, `stop`)
     * (i.e. `start <= tokenId < stop`).
     *
     * This function allows for tokens to be queried if the collection
     * grows too big for a single call of {ERC721AQueryable-tokensOfOwner}.
     *
     * Requirements:
     *
     * - `start` < `stop`
     */
    function tokensOfOwnerIn(
        address owner,
        uint256 start,
        uint256 stop
    ) external view override returns (uint256[] memory) {
        unchecked {
            if (start >= stop) revert InvalidQueryRange();
            uint256 tokenIdsIdx;
            uint256 stopLimit = _nextTokenId();
            // Set `start = max(start, _startTokenId())`.
            if (start < _startTokenId()) {
                start = _startTokenId();
            }
            // Set `stop = min(stop, stopLimit)`.
            if (stop > stopLimit) {
                stop = stopLimit;
            }
            uint256 tokenIdsMaxLength = balanceOf(owner);
            // Set `tokenIdsMaxLength = min(balanceOf(owner), stop - start)`,
            // to cater for cases where `balanceOf(owner)` is too big.
            if (start < stop) {
                uint256 rangeLength = stop - start;
                if (rangeLength < tokenIdsMaxLength) {
                    tokenIdsMaxLength = rangeLength;
                }
            } else {
                tokenIdsMaxLength = 0;
            }
            uint256[] memory tokenIds = new uint256[](tokenIdsMaxLength);
            if (tokenIdsMaxLength == 0) {
                return tokenIds;
            }
            // We need to call `explicitOwnershipOf(start)`,
            // because the slot at `start` may not be initialized.
            TokenOwnership memory ownership = explicitOwnershipOf(start);
            address currOwnershipAddr;
            // If the starting slot exists (i.e. not burned), initialize `currOwnershipAddr`.
            // `ownership.address` will not be zero, as `start` is clamped to the valid token ID range.
            if (!ownership.burned) {
                currOwnershipAddr = ownership.addr;
            }
            for (uint256 i = start; i != stop && tokenIdsIdx != tokenIdsMaxLength; ++i) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            // Downsize the array to fit.
            assembly {
                mstore(tokenIds, tokenIdsIdx)
            }
            return tokenIds;
        }
    }

    /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(totalSupply) in complexity.
     * It is meant to be called off-chain.
     *
     * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
     * multiple smaller scans if the collection is large enough to cause
     * an out-of-gas error (10K pfp collections should be fine).
     */
    function tokensOfOwner(address owner) external view override returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            TokenOwnership memory ownership;
            for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.0.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import './IERC721A.sol';

/**
 * @dev ERC721 token receiver interface.
 */
interface ERC721A__IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at _startTokenId() (defaults to 0, e.g. 0, 1, 2, 3..).
 *
 * Assumes that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 *
 * Assumes that the maximum token id cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is IERC721A {
    // Mask of an entry in packed address data.
    uint256 private constant BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;

    // The bit position of `numberMinted` in packed address data.
    uint256 private constant BITPOS_NUMBER_MINTED = 64;

    // The bit position of `numberBurned` in packed address data.
    uint256 private constant BITPOS_NUMBER_BURNED = 128;

    // The bit position of `aux` in packed address data.
    uint256 private constant BITPOS_AUX = 192;

    // Mask of all 256 bits in packed address data except the 64 bits for `aux`.
    uint256 private constant BITMASK_AUX_COMPLEMENT = (1 << 192) - 1;

    // The bit position of `startTimestamp` in packed ownership.
    uint256 private constant BITPOS_START_TIMESTAMP = 160;

    // The bit mask of the `burned` bit in packed ownership.
    uint256 private constant BITMASK_BURNED = 1 << 224;
    
    // The bit position of the `nextInitialized` bit in packed ownership.
    uint256 private constant BITPOS_NEXT_INITIALIZED = 225;

    // The bit mask of the `nextInitialized` bit in packed ownership.
    uint256 private constant BITMASK_NEXT_INITIALIZED = 1 << 225;

    // The tokenId of the next token to be minted.
    uint256 private _currentIndex;

    // The number of tokens burned.
    uint256 private _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned.
    // See `_packedOwnershipOf` implementation for details.
    //
    // Bits Layout:
    // - [0..159]   `addr`
    // - [160..223] `startTimestamp`
    // - [224]      `burned`
    // - [225]      `nextInitialized`
    mapping(uint256 => uint256) private _packedOwnerships;

    // Mapping owner address to address data.
    //
    // Bits Layout:
    // - [0..63]    `balance`
    // - [64..127]  `numberMinted`
    // - [128..191] `numberBurned`
    // - [192..255] `aux`
    mapping(address => uint256) private _packedAddressData;

    // Mapping from token ID to approved address.
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    /**
     * @dev Returns the starting token ID. 
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Returns the next token ID to be minted.
     */
    function _nextTokenId() internal view returns (uint256) {
        return _currentIndex;
    }

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count. 
     * To get the total number of tokens minted, please see `_totalMinted`.
     */
    function totalSupply() public view override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than `_currentIndex - _startTokenId()` times.
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * @dev Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view returns (uint256) {
        // Counter underflow is impossible as _currentIndex does not decrement,
        // and it is initialized to `_startTokenId()`
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /**
     * @dev Returns the total number of tokens burned.
     */
    function _totalBurned() internal view returns (uint256) {
        return _burnCounter;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // The interface IDs are constants representing the first 4 bytes of the XOR of
        // all function selectors in the interface. See: https://eips.ethereum.org/EIPS/eip-165
        // e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return _packedAddressData[owner] & BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> BITPOS_NUMBER_MINTED) & BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> BITPOS_NUMBER_BURNED) & BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return uint64(_packedAddressData[owner] >> BITPOS_AUX);
    }

    /**
     * Sets the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal {
        uint256 packed = _packedAddressData[owner];
        uint256 auxCasted;
        assembly { // Cast aux without masking.
            auxCasted := aux
        }
        packed = (packed & BITMASK_AUX_COMPLEMENT) | (auxCasted << BITPOS_AUX);
        _packedAddressData[owner] = packed;
    }

    /**
     * Returns the packed ownership data of `tokenId`.
     */
    function _packedOwnershipOf(uint256 tokenId) private view returns (uint256) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr)
                if (curr < _currentIndex) {
                    uint256 packed = _packedOwnerships[curr];
                    // If not burned.
                    if (packed & BITMASK_BURNED == 0) {
                        // Invariant:
                        // There will always be an ownership that has an address and is not burned
                        // before an ownership that does not have an address and is not burned.
                        // Hence, curr will not underflow.
                        //
                        // We can directly compare the packed value.
                        // If the address is zero, packed is zero.
                        while (packed == 0) {
                            packed = _packedOwnerships[--curr];
                        }
                        return packed;
                    }
                }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * Returns the unpacked `TokenOwnership` struct from `packed`.
     */
    function _unpackedOwnership(uint256 packed) private pure returns (TokenOwnership memory ownership) {
        ownership.addr = address(uint160(packed));
        ownership.startTimestamp = uint64(packed >> BITPOS_START_TIMESTAMP);
        ownership.burned = packed & BITMASK_BURNED != 0;
    }

    /**
     * Returns the unpacked `TokenOwnership` struct at `index`.
     */
    function _ownershipAt(uint256 index) internal view returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnerships[index]);
    }

    /**
     * @dev Initializes the ownership slot minted at `index` for efficiency purposes.
     */
    function _initializeOwnershipAt(uint256 index) internal {
        if (_packedOwnerships[index] == 0) {
            _packedOwnerships[index] = _packedOwnershipOf(index);
        }
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function _ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnershipOf(tokenId));
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return address(uint160(_packedOwnershipOf(tokenId)));
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    /**
     * @dev Casts the address to uint256 without masking.
     */
    function _addressToUint256(address value) private pure returns (uint256 result) {
        assembly {
            result := value
        }
    }

    /**
     * @dev Casts the boolean to uint256 without branching.
     */
    function _boolToUint256(bool value) private pure returns (uint256 result) {
        assembly {
            result := value
        }
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = address(uint160(_packedOwnershipOf(tokenId)));
        if (to == owner) revert ApprovalToCurrentOwner();

        if (_msgSenderERC721A() != owner)
            if (!isApprovedForAll(owner, _msgSenderERC721A())) {
                revert ApprovalCallerNotOwnerNorApproved();
            }

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (operator == _msgSenderERC721A()) revert ApproveToCaller();

        _operatorApprovals[_msgSenderERC721A()][operator] = approved;
        emit ApprovalForAll(_msgSenderERC721A(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        _transfer(from, to, tokenId);
        if (to.code.length != 0)
            if (!_checkContractOnERC721Received(from, to, tokenId, _data)) {
                revert TransferToNonERC721ReceiverImplementer();
            }
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return
            _startTokenId() <= tokenId &&
            tokenId < _currentIndex && // If within bounds,
            _packedOwnerships[tokenId] & BITMASK_BURNED == 0; // and not burned.
    }

    /**
     * @dev Equivalent to `_safeMint(to, quantity, '')`.
     */
    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, '');
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement
     *   {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the balance and number minted.
            _packedAddressData[to] += quantity * ((1 << BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] =
                _addressToUint256(to) |
                (block.timestamp << BITPOS_START_TIMESTAMP) |
                (_boolToUint256(quantity == 1) << BITPOS_NEXT_INITIALIZED);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            if (to.code.length != 0) {
                do {
                    emit Transfer(address(0), to, updatedIndex);
                    if (!_checkContractOnERC721Received(address(0), to, updatedIndex++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (updatedIndex < end);
                // Reentrancy protection
                if (_currentIndex != startTokenId) revert();
            } else {
                do {
                    emit Transfer(address(0), to, updatedIndex++);
                } while (updatedIndex < end);
            }
            _currentIndex = updatedIndex;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 quantity) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the balance and number minted.
            _packedAddressData[to] += quantity * ((1 << BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] =
                _addressToUint256(to) |
                (block.timestamp << BITPOS_START_TIMESTAMP) |
                (_boolToUint256(quantity == 1) << BITPOS_NEXT_INITIALIZED);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            do {
                emit Transfer(address(0), to, updatedIndex++);
            } while (updatedIndex < end);

            _currentIndex = updatedIndex;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) private {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        if (address(uint160(prevOwnershipPacked)) != from) revert TransferFromIncorrectOwner();

        bool isApprovedOrOwner = (_msgSenderERC721A() == from ||
            isApprovedForAll(from, _msgSenderERC721A()) ||
            getApproved(tokenId) == _msgSenderERC721A());

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner.
        delete _tokenApprovals[tokenId];

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            // We can directly increment and decrement the balances.
            --_packedAddressData[from]; // Updates: `balance -= 1`.
            ++_packedAddressData[to]; // Updates: `balance += 1`.

            // Updates:
            // - `address` to the next owner.
            // - `startTimestamp` to the timestamp of transfering.
            // - `burned` to `false`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] =
                _addressToUint256(to) |
                (block.timestamp << BITPOS_START_TIMESTAMP) |
                BITMASK_NEXT_INITIALIZED;

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Equivalent to `_burn(tokenId, false)`.
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        address from = address(uint160(prevOwnershipPacked));

        if (approvalCheck) {
            bool isApprovedOrOwner = (_msgSenderERC721A() == from ||
                isApprovedForAll(from, _msgSenderERC721A()) ||
                getApproved(tokenId) == _msgSenderERC721A());

            if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner.
        delete _tokenApprovals[tokenId];

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            // Updates:
            // - `balance -= 1`.
            // - `numberBurned += 1`.
            //
            // We can directly decrement the balance, and increment the number burned.
            // This is equivalent to `packed -= 1; packed += 1 << BITPOS_NUMBER_BURNED;`.
            _packedAddressData[from] += (1 << BITPOS_NUMBER_BURNED) - 1;

            // Updates:
            // - `address` to the last owner.
            // - `startTimestamp` to the timestamp of burning.
            // - `burned` to `true`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] =
                _addressToUint256(from) |
                (block.timestamp << BITPOS_START_TIMESTAMP) |
                BITMASK_BURNED | 
                BITMASK_NEXT_INITIALIZED;

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try ERC721A__IERC721Receiver(to).onERC721Received(_msgSenderERC721A(), from, tokenId, _data) returns (
            bytes4 retval
        ) {
            return retval == ERC721A__IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     * And also called after one token has been burned.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Returns the message sender (defaults to `msg.sender`).
     *
     * If you are writing GSN compatible contracts, you need to override this function.
     */
    function _msgSenderERC721A() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function _toString(uint256 value) internal pure returns (string memory ptr) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), 
            // but we allocate 128 bytes to keep the free memory pointer 32-byte word aliged.
            // We will need 1 32-byte word to store the length, 
            // and 3 32-byte words to store a maximum of 78 digits. Total: 32 + 3 * 32 = 128.
            ptr := add(mload(0x40), 128)
            // Update the free memory pointer to allocate.
            mstore(0x40, ptr)

            // Cache the end of the memory to calculate the length later.
            let end := ptr

            // We write the string from the rightmost digit to the leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // Costs a bit more than early returning for the zero case,
            // but cheaper in terms of deployment and overall runtime costs.
            for { 
                // Initialize and perform the first pass without check.
                let temp := value
                // Move the pointer 1 byte leftwards to point to an empty character slot.
                ptr := sub(ptr, 1)
                // Write the character to the pointer. 48 is the ASCII index of '0'.
                mstore8(ptr, add(48, mod(temp, 10)))
                temp := div(temp, 10)
            } temp { 
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
            } { // Body of the for loop.
                ptr := sub(ptr, 1)
                mstore8(ptr, add(48, mod(temp, 10)))
            }
            
            let length := sub(end, ptr)
            // Move the pointer 32 bytes leftwards to make room for the length.
            ptr := sub(ptr, 32)
            // Store the length.
            mstore(ptr, length)
        }
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.1.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '../IERC721A.sol';

/**
 * @dev Interface of an ERC721AQueryable compliant contract.
 */
interface IERC721AQueryable is IERC721A {
    /**
     * Invalid query range (`start` >= `stop`).
     */
    error InvalidQueryRange();

    /**
     * @dev Returns the `TokenOwnership` struct at `tokenId` without reverting.
     *
     * If the `tokenId` is out of bounds:
     *   - `addr` = `address(0)`
     *   - `startTimestamp` = `0`
     *   - `burned` = `false`
     *
     * If the `tokenId` is burned:
     *   - `addr` = `<Address of owner before token was burned>`
     *   - `startTimestamp` = `<Timestamp when token was burned>`
     *   - `burned = `true`
     *
     * Otherwise:
     *   - `addr` = `<Address of owner>`
     *   - `startTimestamp` = `<Timestamp of start of ownership>`
     *   - `burned = `false`
     */
    function explicitOwnershipOf(uint256 tokenId) external view returns (TokenOwnership memory);

    /**
     * @dev Returns an array of `TokenOwnership` structs at `tokenIds` in order.
     * See {ERC721AQueryable-explicitOwnershipOf}
     */
    function explicitOwnershipsOf(uint256[] memory tokenIds) external view returns (TokenOwnership[] memory);

    /**
     * @dev Returns an array of token IDs owned by `owner`,
     * in the range [`start`, `stop`)
     * (i.e. `start <= tokenId < stop`).
     *
     * This function allows for tokens to be queried if the collection
     * grows too big for a single call of {ERC721AQueryable-tokensOfOwner}.
     *
     * Requirements:
     *
     * - `start` < `stop`
     */
    function tokensOfOwnerIn(
        address owner,
        uint256 start,
        uint256 stop
    ) external view returns (uint256[] memory);

    /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(totalSupply) in complexity.
     * It is meant to be called off-chain.
     *
     * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
     * multiple smaller scans if the collection is large enough to cause
     * an out-of-gas error (10K pfp collections should be fine).
     */
    function tokensOfOwner(address owner) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.0.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of an ERC721A compliant contract.
 */
interface IERC721A {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * The caller cannot approve to their own address.
     */
    error ApproveToCaller();

    /**
     * The caller cannot approve to the current owner.
     */
    error ApprovalToCurrentOwner();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
    }

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     *
     * Burned tokens are calculated here, use `_totalMinted()` if you want to count just minted tokens.
     */
    function totalSupply() external view returns (uint256);

    // ==============================
    //            IERC165
    // ==============================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // ==============================
    //            IERC721
    // ==============================

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

    // ==============================
    //        IERC721Metadata
    // ==============================

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