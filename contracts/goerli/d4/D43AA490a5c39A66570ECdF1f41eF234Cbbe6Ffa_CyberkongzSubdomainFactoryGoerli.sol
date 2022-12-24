pragma solidity ^0.8.17;

/*
 *     ,_,
 *    (',')
 *    {/"\}
 *    -"-"-
 */

import "IERC20.sol";
import "IERC721.sol";
import "Ownable.sol";

interface IDefaultReverseResolver {
	function name(bytes32) external view returns(string memory);
}

interface IEnsFallback {
	function setSubnodeRecord(bytes32 node, bytes32 label, address owner, address resolver, uint64 ttl) external;
	function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external returns(bytes32);
	function owner(bytes32 node) external view returns(address);
}

interface IResolver {
	function setAddr(bytes32 node, address a) external;
	function setAddr(bytes32 node, uint coinType, bytes memory a) external;
	function setText(bytes32 node, string calldata key, string calldata value) external;
	function setName(bytes32 node, string calldata name) external;
	function multicall(bytes[] calldata data) external;
	function setContenthash(bytes32, bytes calldata) external;
}

// apelot.kongz.eth
contract CyberkongzSubdomainFactoryGoerli is Ownable {

	IEnsFallback constant ENS_FALLBACK = IEnsFallback(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
	bytes32 constant public KONGZ_NODE = 0x5054416291f3eebb65ecc2d515aa1b601f81ef5b61541ce6481179c12852f4fa;
	
	IResolver public resolver = IResolver(0xE264d5bb84bA3b8061ADC38D3D76e6674aB91852);
	IERC20 public banana = IERC20(0x94e496474F1725f1c1824cB5BDb92d7691A4F03a); // TODO change

	bool setup;
	bool public paused;
	mapping(address => bool) public acceptedNfts;
	mapping(address => string)public nftBaseUrl;
	mapping(address => string) public nftSuffix;
	mapping(address => bool) public upForGrabs;
	mapping(bytes32 => string) public hashToStr;
	mapping(bytes32 => bytes32) public nftToHash;
	mapping(bytes32 => bytes32) public hashToNft;
	mapping(bytes32 => uint256) public nftDataToExpiryDate;
	mapping(bytes32 => bool) public reservedOrBanned;
	mapping(address => mapping(uint256 => bool)) public grabbed;

	event DomainAdded(string label, address nft, uint256 tokenId);
	event DomainDeleted(string label, address nft, uint256 tokenId);

	function init() external {
		require(!setup);
		setup = true;
		_owner = msg.sender;
	}

	modifier isPaused() {
		require(!paused);
		_;
	}

	function setPause() external onlyOwner {
		paused = !paused;
	}

	/**  
	 * @notice
	 * Used to set ban or reserve a label
	 * @param _name Name to reserve or ban
	 * @param _val set value
	 */
	function updateReserveOrBanned(string calldata _name, bool _val) external onlyOwner {
		reservedOrBanned[keccak256(abi.encodePacked(_name))] = _val;
	}

	/**  
	 * @notice
	 * Used to update the base uri of a collection
	 * @param _address Collection to update base uri from
	 * @param _url new base url
	 */
	function updateBaseUrl(address _address, string calldata _url) external onlyOwner {
		nftBaseUrl[_address] = _url;
	}

	/**  
	 * @notice
	 * Used to update the base uri of a collection
	 * @param _address Collection to update base uri from
	 * @param _suffix new base url
	 */
	function updateSuffixUrl(address _address, string calldata _suffix) external onlyOwner {
		nftSuffix[_address] = _suffix;
	}

	/**  
	 * @notice
	 * Set if eligible fro grabs
	 * @param _collec New collection
	 * @param _value Set value
	 */
	function setGrab(address _collec, bool _value) external onlyOwner {
		upForGrabs[_collec] = _value;
	}

	/**  
	 * @notice
	 * Used to validate collection in contract
	 * @param _collec New collection
	 * @param _value Set value
	 */
	function setNewCollection(address _collec, bool _value) external onlyOwner {
		acceptedNfts[_collec] = _value;
	}

	/**  
	 * @notice
	 * Used to update the ens resolver address
	 * @param _resolver New resolver address
	 */
	function updateResolver(address _resolver) external onlyOwner {
		resolver = IResolver(_resolver);
	}

	/**  
	 * @notice
	 * Used to update the banana address
	 * @param _banana New banana address
	 */
	function updateBanana(address _banana) external onlyOwner {
		banana = IERC20(_banana);
	}

   function getSelectors(bytes[] calldata _payloads) internal pure returns(bytes4[] memory){
        bytes4[] memory sels = new bytes4[](_payloads.length);
        for (uint256 i = 0 ; i < _payloads.length; i++) {
            bytes4 s;
            bytes calldata d = _payloads[i];
            assembly {
                s := calldataload(d.offset)
            }
            sels[i] = s;
        }
        return sels;
    }

	function multicall(uint256 _tokenId, address _nft, bytes[] calldata _data) external {
		(bytes32 subnode,) = _validateParamsOwner(_tokenId, _nft);
		bytes4[] memory selectors = getSelectors(_data);
		for(uint256 i = 0; i < _data.length; i++) {
			require (selectors[i] == IResolver.setText.selector ||
					selectors[i] == IResolver.setName.selector ||
					selectors[i] == IResolver.setContenthash.selector ||
					selectors[i] == bytes4(0xd5fa2b00) ||
					selectors[i] == bytes4(0x8b95dd71));
			if (selectors[i] == IResolver.setText.selector) {
				(bytes32 _subnode, string memory _key,) = abi.decode(_data[i][4:], (bytes32, string, string));
				require(_subnode == subnode);
				require(keccak256(abi.encodePacked(_key)) != keccak256(abi.encodePacked("avatar")), "No touch avatar key");
			}
		}
		resolver.multicall(_data);
	}

	function setAddr(uint256 _tokenId, address _nft, address _bind) external {
		(bytes32 subnode,) = _validateParamsOwner(_tokenId, _nft);
		resolver.setAddr(subnode, _bind);
	}

	function setAddr(uint256 _tokenId, address _nft, uint256 _coin, bytes memory _a) external {
		(bytes32 subnode,) = _validateParamsOwner(_tokenId, _nft);
		resolver.setAddr(subnode, _coin, _a);
	}

	function setManyText(uint256 _tokenId, address _nft, string[] memory _keys, string[] calldata _values) external {
		(bytes32 subnode,) = _validateParamsOwner(_tokenId, _nft);
		require(_keys.length == _values.length);
		for (uint256 i = 0 ; i < _keys.length; i++) {
			require(keccak256(abi.encodePacked(_keys[i])) != keccak256(abi.encodePacked("avatar")), "No touch avatar key");
			resolver.setText(subnode, _keys[i], _values[i]);
		}
	}

	function setText(uint256 _tokenId, address _nft, string memory _key, string calldata _value) external {
		(bytes32 subnode,) = _validateParamsOwner(_tokenId, _nft);
		require(keccak256(abi.encodePacked(_key)) != keccak256(abi.encodePacked("avatar")), "No touch avatar key");
		resolver.setText(subnode, _key, _value);
	}

	// to keep commented, reverse is done by calling reverse registrar
	// function setName(string calldata _label, uint256 _tokenId, address _nft, string calldata _name) external {
	// 	(bytes32 nameHash, bytes32 subnode, bytes32 nftData) = _validateParams(_label, _tokenId, _nft);
	// 	resolver.setName(subnode, _name);
	// }


	/**  
	 * @notice
	 * Used to gift a subdomain to an nft if not set yet
	 * @param _label Name of subdomain
	 * @param _tokenId Token Id of nft
	 * @param _nft collection address
	 * @param _bind Address to which subdomain resolves to
	 */
	function giftSubdomain(string calldata _label, uint256 _tokenId, address _nft, address _bind) external onlyOwner {
		(bytes32 nameHash, bytes32 subnode, bytes32 nftData) = _adminCheckParams(_label, _tokenId, _nft);
		require(hashToNft[nameHash] == bytes32(0), 'Label already taken');
		require(nftToHash[nftData] == bytes32(0), 'Token ID has label binded');

		// make previous attached ens avaiable for others to claim
		bytes32 attachedHash = nftToHash[nftData];
		if (attachedHash != bytes32(0)) {
			delete hashToNft[attachedHash];
			resolver.setAddr(keccak256(abi.encodePacked(KONGZ_NODE, attachedHash)), address(0));
		}

		hashToNft[nameHash] = nftData;
		nftToHash[nftData] = nameHash;
		if (bytes(hashToStr[nameHash]).length == 0) {
			ENS_FALLBACK.setSubnodeRecord(KONGZ_NODE, nameHash, address(this), address(resolver), 0);
			hashToStr[nameHash] = _label;
		}
		nftDataToExpiryDate[nftData] = block.timestamp + 365 days;
		resolver.setAddr(subnode, _bind);
		resolver.setText(subnode, "avatar", _generateUrl(_nft, _tokenId));
		emit DomainAdded(_label, _nft, _tokenId);
	}

	/**  
	 * @notice
	 * Used to remove a subdomain. Only owner can call it. To remove profanity
	 * @param _label Name of subdomain
	 * @param _tokenId Token Id of nft
	 * @param _nft collection address
	 */
	function dropSubdomain(string calldata _label, uint256 _tokenId, address _nft) external onlyOwner {
		(,, bytes32 nftData) = _adminCheckParams(_label, _tokenId, _nft);

		// make previous attached ens avaiable for others to claim
		bytes32 attachedHash = nftToHash[nftData];
		if (attachedHash != bytes32(0)) {
			delete hashToNft[attachedHash];
			delete nftToHash[nftData];
			delete nftDataToExpiryDate[nftData];
			resolver.setAddr(keccak256(abi.encodePacked(KONGZ_NODE, attachedHash)), address(0));
			resolver.setText(keccak256(abi.encodePacked(KONGZ_NODE, attachedHash)), "avatar", "");
		}
		emit DomainDeleted(_label, _nft, _tokenId);
	}

	/**  
	 * @notice
	 * Used to claim a subdomain on an nft for free. User must pay nana to get
	 * @param _label Name of subdomain
	 * @param _tokenId Token Id of nft
	 * @param _nft collection address
	 * @param _bind Address to which subdomain resolves to
	 */
	function grabSubdomain(string calldata _label, uint256 _tokenId, address _nft, address _bind) external isPaused {
		(bytes32 nameHash, bytes32 subnode, bytes32 nftData) = _checkParams(_label, _tokenId, _nft);
		bytes32 attachedNftData = hashToNft[nameHash];
		require(upForGrabs[_nft], "Not eligible for grabs");
		require(!grabbed[_nft][_tokenId], "Grabbed");
		require(nftDataToExpiryDate[attachedNftData] < block.timestamp, "Label already taken");

		grabbed[_nft][_tokenId] = true;
		// delete expiry of previously attached token
		if (nftData != attachedNftData) {
			delete nftDataToExpiryDate[attachedNftData];
			delete nftToHash[attachedNftData];
		}
		// make previous attached ens avaiable for others to claim
		bytes32 attachedHash = nftToHash[nftData];
		if (attachedHash != bytes32(0)) {
			delete hashToNft[attachedHash];
			resolver.setAddr(keccak256(abi.encodePacked(KONGZ_NODE, attachedHash)), address(0));
			resolver.setText(keccak256(abi.encodePacked(KONGZ_NODE, attachedHash)), "avatar", "");
			emit DomainDeleted(hashToStr[attachedHash], _nft, _tokenId);
		}
		hashToNft[nameHash] = nftData;
		nftToHash[nftData] = nameHash;
		if (bytes(hashToStr[nameHash]).length == 0) {
			ENS_FALLBACK.setSubnodeRecord(KONGZ_NODE, nameHash, address(this), address(resolver), 0);
			hashToStr[nameHash] = _label;
		}
		nftDataToExpiryDate[nftData] = block.timestamp + 365 days;
		resolver.setAddr(subnode, _bind);
		resolver.setText(subnode, "avatar", _generateUrl(_nft, _tokenId));
		emit DomainAdded(_label, _nft, _tokenId);
	}

	/**  
	 * @notice
	 * Used to claim a subdomain on an nft. User must pay nana to get
	 * @param _label Name of subdomain
	 * @param _tokenId Token Id of nft
	 * @param _nft collection address
	 * @param _bind Address to which subdomain resolves to
	 */
	function addSubdomain(string calldata _label, uint256 _tokenId, address _nft, address _bind) external isPaused {
		(bytes32 nameHash, bytes32 subnode, bytes32 nftData) = _checkParams(_label, _tokenId, _nft);
		bytes32 attachedNftData = hashToNft[nameHash];
		require(nftDataToExpiryDate[attachedNftData] < block.timestamp, "Label already taken");

		// delete expiry of previously attached token
		if (nftData != attachedNftData) {
			delete nftDataToExpiryDate[attachedNftData];
			delete nftToHash[attachedNftData];
		}
		// make previous attached ens avaiable for others to claim
		bytes32 attachedHash = nftToHash[nftData];
		if (attachedHash != bytes32(0)) {
			delete hashToNft[attachedHash];
			resolver.setAddr(keccak256(abi.encodePacked(KONGZ_NODE, attachedHash)), address(0));
			resolver.setText(keccak256(abi.encodePacked(KONGZ_NODE, attachedHash)), "avatar", "");
			emit DomainDeleted(hashToStr[attachedHash], _nft, _tokenId);
		}
		hashToNft[nameHash] = nftData;
		nftToHash[nftData] = nameHash;
		if (bytes(hashToStr[nameHash]).length == 0) {
			ENS_FALLBACK.setSubnodeRecord(KONGZ_NODE, nameHash, address(this), address(resolver), 0);
			hashToStr[nameHash] = _label;
		}
		nftDataToExpiryDate[nftData] = block.timestamp + 365 days;
		resolver.setAddr(subnode, _bind);
		resolver.setText(subnode, "avatar", _generateUrl(_nft, _tokenId));
		banana.transferFrom(msg.sender, owner(), getFee(bytes(_label).length));
		emit DomainAdded(_label, _nft, _tokenId);
	}

	/**  
	 * @notice
	 * Used to extend a subdomain registration.
	 * @param _tokenId Token Id of nft
	 * @param _nft collection address
	 * @param _amount Amount of nana to send to extend duration
	 */
	function extendSubdomain(uint256 _tokenId, address _nft, uint256 _amount) external {
		bytes32 nftData = _validateParamsNotOwner(_tokenId, _nft);
		uint256 expiryDate = nftDataToExpiryDate[nftData];
		require(expiryDate > 0, "Token has no label");
		uint256 fee = getFee(bytes(hashToStr[nftToHash[nftData]]).length);
		uint256 extraDuration = (365 days * _amount) / fee;

		nftDataToExpiryDate[nftData] = (expiryDate > block.timestamp ? expiryDate : block.timestamp)  + extraDuration;
		banana.transferFrom(msg.sender, address(this), _amount);
	}

	/**  
	 * @notice
	 * Used to fetch ens name of an nft
	 * @param _nft collection address
	 * @param _tokenId Token Id of nft
	 */
	function name(address _nft, uint256 _tokenId) public view returns(string memory) {
		bytes32 nameHash = nftToHash[_concatNftData(_nft, _tokenId)];
		if (nameHash == 0x0)
			return "";
		return string(abi.encodePacked(hashToStr[nameHash], ".kongz.eth"));
	}

	function validateName(string memory str) public pure returns (bool){
		bytes memory b = bytes(str);
		if(b.length < 1) return false;
		if(b.length > 32) return false; // Cannot be longer than 32 characters

		for(uint i; i<b.length; i++){
			bytes1 char = b[i];

			if (char == 0x20) return false; // Cannot contain spaces

			if(
				!(char >= 0x30 && char <= 0x39) && //9-0
				// !(char >= 0x41 && char <= 0x5A) && //A-Z
				!(char >= 0x61 && char <= 0x7A) //a-z
			)
				return false;
		}

		return true;
	}

	function _checkParams(string calldata _label, uint256 _tokenId, address _nft) internal view returns (bytes32 nameHash, bytes32 subnode, bytes32 nftData) {
		require(acceptedNfts[_nft], "wong");
		require(IERC721(_nft).ownerOf(_tokenId) == msg.sender, "!owner");
		require(validateName(_label), "!name");
		require(!reservedOrBanned[keccak256(abi.encodePacked(_label))], "!use");
		nameHash = _nameHash(_label);
		subnode = keccak256(abi.encodePacked(KONGZ_NODE, nameHash));
		nftData = _concatNftData(_nft, _tokenId);
	}

	function _adminCheckParams(string calldata _label, uint256 _tokenId, address _nft) internal view returns (bytes32 nameHash, bytes32 subnode, bytes32 nftData) {
		require(acceptedNfts[_nft]);
		require(validateName(_label));
		nameHash = _nameHash(_label);
		subnode = keccak256(abi.encodePacked(KONGZ_NODE, nameHash));
		nftData = _concatNftData(_nft, _tokenId);
	}

	function _validateParams(string calldata _label, uint256 _tokenId, address _nft) internal view returns (bytes32 nameHash, bytes32 subnode, bytes32 nftData) {
		require(acceptedNfts[_nft]);
		require(IERC721(_nft).ownerOf(_tokenId) == msg.sender, "!owner");
		require(validateName(_label));
		nameHash = _nameHash(_label);
		subnode = keccak256(abi.encodePacked(KONGZ_NODE, nameHash));
		nftData = _concatNftData(_nft, _tokenId);
		require(hashToNft[nameHash] == nftData, "domain !binded to nft");
	}

	function _validateParamsOwner(uint256 _tokenId, address _nft) internal view returns (bytes32 subnode, bytes32 nftData) {
		require(acceptedNfts[_nft]);
		require(IERC721(_nft).ownerOf(_tokenId) == msg.sender, "!owner");
		nftData = _concatNftData(_nft, _tokenId);
		require(nftDataToExpiryDate[nftData] > 0, "Token has no label");
		bytes32 nameHash = nftToHash[nftData];
		subnode = keccak256(abi.encodePacked(KONGZ_NODE, nameHash));
	}

	function _validateParamsNotOwner(uint256 _tokenId, address _nft) internal view returns (bytes32 nftData) {
		require(acceptedNfts[_nft]);
		nftData = _concatNftData(_nft, _tokenId);
	}

	function _nameHash(string calldata _label) internal view returns(bytes32) {
		return keccak256(abi.encodePacked(_label));
	}

	function _concatNftData(address _nft, uint256 _tokenId) internal pure returns(bytes32) {
		uint256 data = (uint256(uint160(_nft)) << 96) + _tokenId;
		return bytes32(data);
	}

	function _parseNftData(bytes32 _data) internal pure returns(address, uint256) {
		uint256 tokenId = uint256(_data) & 0xffffffffffff;
		address nft = address(uint160(uint256(_data) >> 96));
		return (nft, tokenId);
	}

	function getFee(uint256 _char) public pure returns(uint256 fee) {
		if (_char == 1)
			fee = 200 ether;
		else if (_char == 2)
			fee = 100 ether;
		else if (_char == 3)
			fee = 50 ether;
		else if (_char == 4)
			fee = 20 ether;
		else
			fee = 10 ether;
	}

	function _generateUrl(address _nft, uint256 _tokenId) internal view returns(string memory) {
		return string(abi.encodePacked(nftBaseUrl[_nft], _toString(_tokenId), nftSuffix[_nft]));
	}

    function _toString(uint256 value) internal pure returns (string memory) {
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
    address internal _owner;

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