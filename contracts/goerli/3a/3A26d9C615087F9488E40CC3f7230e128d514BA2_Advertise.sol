// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./SVGRenderer.sol";
import "./DecimalStrings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract Advertise is ERC721, Ownable {
	event update(address indexed from, uint256 timestamp, uint256 tokenId);

	SVGRenderer private renderer;
	uint256 private id = 0;
	uint256 private constant INIT_PRICE = 0.00001 ether;
	uint256 private constant INCREASE_PERCENTAGE = 103;

	mapping(uint256 => string) txtByTokenId;
	mapping(uint256 => uint256) payerByTokenId;
	mapping(uint256 => uint256) priceByTokenId;
	mapping(uint256 => uint256) timeByTokenId;

	constructor() ERC721("Advertise", "ADV") {
		renderer = new SVGRenderer();
		priceByTokenId[id] = INIT_PRICE;
	}

	function getPrice() public view returns (uint256) {
		return (priceByTokenId[id] * INCREASE_PERCENTAGE) / 100;
	}

	function mint(string memory txt) public payable {
		require(msg.value >= getPrice(), "Incorrect payable amount");
		uint256 len = bytes(txt).length;
		require(len > 0 && len <= 10000, "Invalid text");

		uint256 tokenId = ++id;
		txtByTokenId[tokenId] = txt;
		payerByTokenId[tokenId] = uint256(uint160(msg.sender));
		timeByTokenId[tokenId] = block.timestamp;
		priceByTokenId[tokenId] = msg.value;
		_safeMint(_msgSender(), tokenId);

		emit update(msg.sender, block.timestamp, tokenId);
	}

	function tokenURI(uint256 tokenId) public view override returns (string memory) {
		require(_exists(tokenId), "nonexistent token");

		uint256 time = timeByTokenId[tokenId];
		string memory txt = txtByTokenId[tokenId];
		string memory payerAddress = Strings.toHexString(payerByTokenId[tokenId], 20);
		string memory priceStr = DecimalStrings.decimalString(
			(priceByTokenId[tokenId] / 10000000000000) * 10000000000000,
			18,
			false
		);
		(string memory svg, string memory mainColor, string memory subColor) = renderer.render(
			tokenId,
			payerAddress,
			address(this),
			time,
			priceStr
		);

		bytes memory json = abi.encodePacked(
			'{"name": "',
			string(abi.encodePacked("Certificate #", Strings.toString(tokenId))),
			'", "description": "',
			txt,
			'", "image": "data:text/svg;base64,',
			Base64.encode(abi.encodePacked(svg)),
			'", "attributes": [',
			'{"trait_type":"Price","value":"',
			priceStr,
			' ETH"}],"metadata": {"payer":"',
			payerAddress,
			'","timestamp":"',
			Strings.toString(time),
			'","mainColor":"',
			mainColor,
			'","subColor":"',
			subColor,
			'","price":',
			priceStr,
			"}}"
		);

		return string(abi.encodePacked("data:application/json;base64,", Base64.encode(json)));
	}

	function totalSupply() public view returns (uint256) {
		return id;
	}

	function withdraw() public onlyOwner {
		payable(owner()).transfer(address(this).balance);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./solidity-datetime/DateTime.sol";
import "./DecimalStrings.sol";
import "./Font.sol";

contract SVGRenderer {
	Font private font;

	constructor() {
		font = new Font();
	}

	function render(
		uint256 tokenId,
		string memory payerAddress,
		address parent,
		uint256 timestamp,
		string memory priceStr
	)
		public
		view
		returns (
			string memory,
			string memory,
			string memory
		)
	{
		string memory mainColor;
		string memory subColor;
		{
			uint256 seed = timestamp + tokenId;
			uint256 count = 0;

			uint256 mainHue = randomRange(seed, ++count, 130, 450);
			uint256 mainSat = randomRange(seed, ++count, 80, 100);
			uint256 mainLum = randomRange(seed, ++count, 40, 60);
			uint256 subSat = randomRange(seed, ++count, 80, 100);
			uint256 subLum = randomRange(seed, ++count, 40, 60);
			uint256 offsetHue = randomRange(seed, count, 160, 200);

			mainColor = string(
				abi.encodePacked(
					Strings.toString(mainHue),
					",",
					Strings.toString(mainSat),
					"%,",
					Strings.toString(mainLum),
					"%"
				)
			);
			subColor = string(
				abi.encodePacked(
					Strings.toString(mainHue + offsetHue),
					",",
					Strings.toString(subSat),
					"%,",
					Strings.toString(subLum),
					"%"
				)
			);
		}

		string memory dateStr;
		{
			(uint256 y, uint256 m, uint256 d, uint256 h, uint256 min, uint256 sec) = DateTime.timestampToDateTime(
				timestamp + 9 * 3600
			);
			dateStr = string(
				abi.encodePacked(
					Strings.toString(y),
					".",
					plusZero(m),
					".",
					plusZero(d),
					" ",
					plusZero(h),
					":",
					plusZero(min),
					":",
					plusZero(sec)
				)
			);
		}

		return (
			string(
				abi.encodePacked(
					'<svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 1080 1080"><style type="text/css">*{--main:hsl(',
					mainColor,
					");--sub:hsl(",
					subColor,
					');}svg{font-family:"f";font-size:45px;letter-spacing:-0.04em;fill:var(--sub);}.l{stroke:var(--sub);}.b{stroke-width:14;}.s{stroke-width:2;}@font-face{font-family:"f";src:url("',
					font.base64(),
					'")format("woff2")};</style><rect width="1080" height="1080" fill="var(--main)"/><clipPath id="m"><rect width="1080" height="1080"/></clipPath><g clip-path="url(#m)"><text x="33" y="67">CERTIFICATE #',
					plusZero(tokenId),
					'</text><text x="1046" y="67" text-anchor="end">ADVERTISE</text><text x="15" y="431" font-size="320px" letter-spacing="-0.075em">',
					priceStr,
					'</text><text x="27" y="556" font-size="110px">ETH + GAS</text><text x="33" y="731">PAYER ADDRESS:</text><text x="33" y="785">',
					payerAddress,
					'</text><text x="33" y="887">CONTRACT ADDRESS:</text><text x="33" y="941">',
					Strings.toHexString(uint256(uint160(parent)), 20),
					'</text><text x="33" y="1044">',
					dateStr,
					'</text><line class="l b" x1="36" y1="110" x2="1044" y2="110"/><line class="l b" x1="36" y1="657" x2="1044" y2="657"/><line class="l s" x1="36" y1="821" x2="1044" y2="821"/><line class="l s" x1="36" y1="978" x2="1044" y2="978"/></g></svg>'
				)
			),
			mainColor,
			subColor
		);
	}

	function plusZero(uint256 num) private pure returns (string memory) {
		return (num < 10) ? string(abi.encodePacked("0", Strings.toString(num))) : Strings.toString(num);
	}

	function randomRange(
		uint256 seed0,
		uint256 seed1,
		uint256 min,
		uint256 max
	) private pure returns (uint256) {
		return min + (uint256(keccak256(abi.encodePacked(seed0, seed1))) % (max - min));
	}
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

//ref: https://gist.github.com/wilsoncusack/d2e680e0f961e36393d1bf0b6faafba7

library DecimalStrings {
	function decimalString(
		uint256 number,
		uint8 decimals,
		bool isPercent
	) internal pure returns (string memory) {
		uint8 percentBufferOffset = isPercent ? 1 : 0;
		uint256 tenPowDecimals = 10**decimals;

		uint256 temp = number;
		uint8 digits;
		uint8 numSigfigs;
		while (temp != 0) {
			if (numSigfigs > 0) {
				// count all digits preceding least significant figure
				numSigfigs++;
			} else if (temp % 10 != 0) {
				numSigfigs++;
			}
			digits++;
			temp /= 10;
		}

		DecimalStringParams memory params;
		params.isPercent = isPercent;
		if ((digits - numSigfigs) >= decimals) {
			// no decimals, ensure we preserve all trailing zeros
			params.sigfigs = number / tenPowDecimals;
			params.sigfigIndex = digits - decimals;
			params.bufferLength = params.sigfigIndex + percentBufferOffset;
		} else {
			// chop all trailing zeros for numbers with decimals
			params.sigfigs = number / (10**(digits - numSigfigs));
			if (tenPowDecimals > number) {
				// number is less tahn one
				// in this case, there may be leading zeros after the decimal place
				// that need to be added

				// offset leading zeros by two to account for leading '0.'
				params.zerosStartIndex = 2;
				params.zerosEndIndex = decimals - digits + 2;
				params.sigfigIndex = numSigfigs + params.zerosEndIndex;
				params.bufferLength = params.sigfigIndex + percentBufferOffset;
				params.isLessThanOne = true;
			} else {
				// In this case, there are digits before and
				// after the decimal place
				params.sigfigIndex = numSigfigs + 1;
				params.decimalIndex = digits - decimals + 1;
			}
		}
		params.bufferLength = params.sigfigIndex + percentBufferOffset;
		return generateDecimalString(params);
	}

	// With modifications, the below taken
	// from https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/libraries/NFTDescriptor.sol#L189-L231

	struct DecimalStringParams {
		// significant figures of decimal
		uint256 sigfigs;
		// length of decimal string
		uint8 bufferLength;
		// ending index for significant figures (funtion works backwards when copying sigfigs)
		uint8 sigfigIndex;
		// index of decimal place (0 if no decimal)
		uint8 decimalIndex;
		// start index for trailing/leading 0's for very small/large numbers
		uint8 zerosStartIndex;
		// end index for trailing/leading 0's for very small/large numbers
		uint8 zerosEndIndex;
		// true if decimal number is less than one
		bool isLessThanOne;
		// true if string should include "%"
		bool isPercent;
	}

	function generateDecimalString(DecimalStringParams memory params) private pure returns (string memory) {
		bytes memory buffer = new bytes(params.bufferLength);
		if (params.isPercent) {
			buffer[buffer.length - 1] = "%";
		}
		if (params.isLessThanOne) {
			buffer[0] = "0";
			buffer[1] = ".";
		}

		// add leading/trailing 0's
		for (uint256 zerosCursor = params.zerosStartIndex; zerosCursor < params.zerosEndIndex; zerosCursor++) {
			buffer[zerosCursor] = bytes1(uint8(48));
		}
		// add sigfigs
		while (params.sigfigs > 0) {
			if (params.decimalIndex > 0 && params.sigfigIndex == params.decimalIndex) {
				buffer[--params.sigfigIndex] = ".";
			}
			buffer[--params.sigfigIndex] = bytes1(uint8(uint256(48) + (params.sigfigs % 10)));
			params.sigfigs /= 10;
		}
		return string(buffer);
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
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
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
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
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

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
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
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
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
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
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Font {
	function base64() public pure returns (string memory) {
		return
			"data:application/font-woff;charset=utf-8;base64,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";
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ----------------------------------------------------------------------------
// DateTime Library v2.0
//
// A gas-efficient Solidity date and time library
//
// https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
//
// Tested date range 1970/01/01 to 2345/12/31
//
// Conventions:
// Unit      | Range         | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year      | 1970 ... 2345 |
// month     | 1 ... 12      |
// day       | 1 ... 31      |
// hour      | 0 ... 23      |
// minute    | 0 ... 59      |
// second    | 0 ... 59      |
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018-2019. The MIT Licence.
// ----------------------------------------------------------------------------

library DateTime {
    uint256 constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint256 constant SECONDS_PER_HOUR = 60 * 60;
    uint256 constant SECONDS_PER_MINUTE = 60;
    int256 constant OFFSET19700101 = 2440588;

    uint256 constant DOW_MON = 1;
    uint256 constant DOW_TUE = 2;
    uint256 constant DOW_WED = 3;
    uint256 constant DOW_THU = 4;
    uint256 constant DOW_FRI = 5;
    uint256 constant DOW_SAT = 6;
    uint256 constant DOW_SUN = 7;

    // ------------------------------------------------------------------------
    // Calculate the number of days from 1970/01/01 to year/month/day using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and subtracting the offset 2440588 so that 1970/01/01 is day 0
    //
    // days = day
    //      - 32075
    //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
    //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
    //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
    //      - offset
    // ------------------------------------------------------------------------
    function _daysFromDate(uint256 year, uint256 month, uint256 day) internal pure returns (uint256 _days) {
        require(year >= 1970);
        int256 _year = int256(year);
        int256 _month = int256(month);
        int256 _day = int256(day);

        int256 __days = _day - 32075 + (1461 * (_year + 4800 + (_month - 14) / 12)) / 4
            + (367 * (_month - 2 - ((_month - 14) / 12) * 12)) / 12
            - (3 * ((_year + 4900 + (_month - 14) / 12) / 100)) / 4 - OFFSET19700101;

        _days = uint256(__days);
    }

    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _daysToDate(uint256 _days) internal pure returns (uint256 year, uint256 month, uint256 day) {
        unchecked {
            int256 __days = int256(_days);

            int256 L = __days + 68569 + OFFSET19700101;
            int256 N = (4 * L) / 146097;
            L = L - (146097 * N + 3) / 4;
            int256 _year = (4000 * (L + 1)) / 1461001;
            L = L - (1461 * _year) / 4 + 31;
            int256 _month = (80 * L) / 2447;
            int256 _day = L - (2447 * _month) / 80;
            L = _month / 11;
            _month = _month + 2 - 12 * L;
            _year = 100 * (N - 49) + _year + L;

            year = uint256(_year);
            month = uint256(_month);
            day = uint256(_day);
        }
    }

    function timestampFromDate(uint256 year, uint256 month, uint256 day) internal pure returns (uint256 timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }

    function timestampFromDateTime(
        uint256 year,
        uint256 month,
        uint256 day,
        uint256 hour,
        uint256 minute,
        uint256 second
    )
        internal
        pure
        returns (uint256 timestamp)
    {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + hour * SECONDS_PER_HOUR
            + minute * SECONDS_PER_MINUTE + second;
    }

    function timestampToDate(uint256 timestamp) internal pure returns (uint256 year, uint256 month, uint256 day) {
        unchecked {
            (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        }
    }

    function timestampToDateTime(uint256 timestamp)
        internal
        pure
        returns (uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second)
    {
        unchecked {
            (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
            uint256 secs = timestamp % SECONDS_PER_DAY;
            hour = secs / SECONDS_PER_HOUR;
            secs = secs % SECONDS_PER_HOUR;
            minute = secs / SECONDS_PER_MINUTE;
            second = secs % SECONDS_PER_MINUTE;
        }
    }

    function isValidDate(uint256 year, uint256 month, uint256 day) internal pure returns (bool valid) {
        if (year >= 1970 && month > 0 && month <= 12) {
            uint256 daysInMonth = _getDaysInMonth(year, month);
            if (day > 0 && day <= daysInMonth) {
                valid = true;
            }
        }
    }

    function isValidDateTime(uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second)
        internal
        pure
        returns (bool valid)
    {
        if (isValidDate(year, month, day)) {
            if (hour < 24 && minute < 60 && second < 60) {
                valid = true;
            }
        }
    }

    function isLeapYear(uint256 timestamp) internal pure returns (bool leapYear) {
        (uint256 year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }

    function _isLeapYear(uint256 year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }

    function isWeekDay(uint256 timestamp) internal pure returns (bool weekDay) {
        weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
    }

    function isWeekEnd(uint256 timestamp) internal pure returns (bool weekEnd) {
        weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
    }

    function getDaysInMonth(uint256 timestamp) internal pure returns (uint256 daysInMonth) {
        (uint256 year, uint256 month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        daysInMonth = _getDaysInMonth(year, month);
    }

    function _getDaysInMonth(uint256 year, uint256 month) internal pure returns (uint256 daysInMonth) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }

    // 1 = Monday, 7 = Sunday
    function getDayOfWeek(uint256 timestamp) internal pure returns (uint256 dayOfWeek) {
        uint256 _days = timestamp / SECONDS_PER_DAY;
        dayOfWeek = ((_days + 3) % 7) + 1;
    }

    function getYear(uint256 timestamp) internal pure returns (uint256 year) {
        (year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getMonth(uint256 timestamp) internal pure returns (uint256 month) {
        (, month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getDay(uint256 timestamp) internal pure returns (uint256 day) {
        (,, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getHour(uint256 timestamp) internal pure returns (uint256 hour) {
        uint256 secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }

    function getMinute(uint256 timestamp) internal pure returns (uint256 minute) {
        uint256 secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }

    function getSecond(uint256 timestamp) internal pure returns (uint256 second) {
        second = timestamp % SECONDS_PER_MINUTE;
    }

    function addYears(uint256 timestamp, uint256 _years) internal pure returns (uint256 newTimestamp) {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year += _years;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
        require(newTimestamp >= timestamp);
    }

    function addMonths(uint256 timestamp, uint256 _months) internal pure returns (uint256 newTimestamp) {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        month += _months;
        year += (month - 1) / 12;
        month = ((month - 1) % 12) + 1;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
        require(newTimestamp >= timestamp);
    }

    function addDays(uint256 timestamp, uint256 _days) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }

    function addHours(uint256 timestamp, uint256 _hours) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
        require(newTimestamp >= timestamp);
    }

    function addMinutes(uint256 timestamp, uint256 _minutes) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp >= timestamp);
    }

    function addSeconds(uint256 timestamp, uint256 _seconds) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp + _seconds;
        require(newTimestamp >= timestamp);
    }

    function subYears(uint256 timestamp, uint256 _years) internal pure returns (uint256 newTimestamp) {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year -= _years;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
        require(newTimestamp <= timestamp);
    }

    function subMonths(uint256 timestamp, uint256 _months) internal pure returns (uint256 newTimestamp) {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint256 yearMonth = year * 12 + (month - 1) - _months;
        year = yearMonth / 12;
        month = (yearMonth % 12) + 1;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
        require(newTimestamp <= timestamp);
    }

    function subDays(uint256 timestamp, uint256 _days) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp - _days * SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }

    function subHours(uint256 timestamp, uint256 _hours) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
        require(newTimestamp <= timestamp);
    }

    function subMinutes(uint256 timestamp, uint256 _minutes) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp <= timestamp);
    }

    function subSeconds(uint256 timestamp, uint256 _seconds) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp - _seconds;
        require(newTimestamp <= timestamp);
    }

    function diffYears(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _years) {
        require(fromTimestamp <= toTimestamp);
        (uint256 fromYear,,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint256 toYear,,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _years = toYear - fromYear;
    }

    function diffMonths(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _months) {
        require(fromTimestamp <= toTimestamp);
        (uint256 fromYear, uint256 fromMonth,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint256 toYear, uint256 toMonth,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    }

    function diffDays(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _days) {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }

    function diffHours(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _hours) {
        require(fromTimestamp <= toTimestamp);
        _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
    }

    function diffMinutes(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _minutes) {
        require(fromTimestamp <= toTimestamp);
        _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
    }

    function diffSeconds(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _seconds) {
        require(fromTimestamp <= toTimestamp);
        _seconds = toTimestamp - fromTimestamp;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
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